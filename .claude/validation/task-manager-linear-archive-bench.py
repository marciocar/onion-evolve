#!/usr/bin/env python3
"""Bancada OFFLINE dos verbos item.archive e item.list do executável do Linear, pelo dispatcher tm.sh.

Roda pela família run_task_manager_linear_archive_selftests do lint-selftest.sh. Nenhuma chamada sai da máquina: o
Linear é trocado por um servidor GraphQL FALSO em loopback (costura TM_LINEAR_ENDPOINT, que o executável só aceita em
127.0.0.1). O que o falso reproduz:
  · `issue(id:)` acha issue arquivada, com `archivedAt` preenchido;
  · `issues(...)` esconde arquivadas sem `includeArchived`, e devolve no máximo 2 por página (o cursor tem de ser seguido);
  · chave de filtro que ele não conhece volta como `errors` (filtro de forma errada não passa por lista vazia);
  · `issueArchive` em issue já arquivada volta como `errors`, o que torna visível qualquer repetição da mutação.
O que esta bancada NÃO prova: que o Linear real se comporta como o falso. O primeiro arquivamento real relido foi em
2026-11-08 (SAC-368, registrado no linear.md) e por isso a declaração passou a `implemented`.

Três partes, no molde da bancada do ClickUp:
  1. CASOS: pelo tm.sh, um por comportamento;
  2. CÓPIA LIMPA: a árvore copiada roda os casos-alvo dos mutantes e TEM de ficar verde antes de qualquer mutante contar;
  3. MUTANTES: cada um reverte UMA cura na cópia e EXIGE que o caso dela reprove.
Saída: `ok   …` por caso verde, `FALHA (n):` no fim com `- …` por vermelho; última linha com as contagens; rc 0 ou 1.
"""
import http.server
import json
import os
import shutil
import subprocess
import sys
import tempfile
import threading

ROOT = (sys.argv[1] if len(sys.argv) > 1 else
        subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True, text=True).stdout.strip() or os.getcwd())
TM_DIR = os.path.join(ROOT, ".claude/utils/task-manager")
KEY = "lin_fake_bench"
SERVER_PAGE = 2
OLD = "2020-01-01T00:00:00.000Z"
NEW = "2099-01-01T00:00:00.000Z"
ARCHIVED_AT = "2026-11-07T00:00:00.000Z"
TEAM_A = "00000000-0000-4000-8000-00000000000a"
TEAM_B = "00000000-0000-4000-8000-00000000000b"


# ── o Linear falso ───────────────────────────────────────────────────────────
def seed():
    def issue(n, state, stype, updated=NEW, archived=None, team="SAC"):
        return {"id": f"uuid-{n}", "identifier": f"{team}-{n}", "title": f"Issue {n}", "url": f"https://app.example/{n}",
                "createdAt": OLD, "updatedAt": updated, "archivedAt": archived, "state": {"name": state, "type": stype},
                "team": {"key": team}, "project": None}
    rows = [
        issue(1, "Done", "completed", OLD),
        issue(2, "Canceled", "canceled", OLD),
        issue(3, "Done", "completed", NEW),
        issue(4, "In Progress", "started", OLD),
        issue(5, "Backlog", "backlog", NEW),
        issue(6, "Done", "completed", OLD, archived=ARCHIVED_AT),
        issue(7, "Done", "completed", NEW, team="OPS"),
    ]
    return {"issues": rows, "log": [], "force": None,
            "teams": [{"id": TEAM_A, "key": "SAC", "name": "Sac"}, {"id": TEAM_B, "key": "OPS", "name": "Ops"}]}


def find(store, ident):
    for row in store["issues"]:
        if ident in (row["id"], row["identifier"]):
            return row
    return None


def matches(row, flt, teams):
    for key, cond in flt.items():
        if key == "state":
            for sub, c in cond.items():
                if sub == "type" and set(c) == {"in"}:
                    if row["state"]["type"] not in c["in"]:
                        return False
                elif sub == "name" and set(c) == {"eqIgnoreCase"}:
                    if row["state"]["name"].lower() != c["eqIgnoreCase"].lower():
                        return False
                else:
                    raise ValueError(f"filtro de estado desconhecido: {sub}")
        elif key == "updatedAt" and set(cond) == {"lt"}:
            if not row["updatedAt"] < cond["lt"]:
                return False
        elif key == "team" and set(cond) == {"id"} and set(cond["id"]) == {"eq"}:
            wanted = [t["key"] for t in teams if t["id"] == cond["id"]["eq"]]
            if row["team"]["key"] not in wanted:
                return False
        else:
            raise ValueError(f"filtro desconhecido: {key}")
    return True


class Handler(http.server.BaseHTTPRequestHandler):
    store = None

    def log_message(self, *a):
        pass

    def _reply(self, code, obj):
        raw = json.dumps(obj).encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(raw)))
        self.end_headers()
        self.wfile.write(raw)

    def _errors(self, msg):
        return self._reply(200, {"data": None, "errors": [{"message": msg}]})

    def do_POST(self):
        length = int(self.headers.get("Content-Length") or 0)
        req = json.loads(self.rfile.read(length).decode("utf-8"))
        q, v = req["query"], req.get("variables") or {}
        s = self.store
        s["log"].append({"query": q, "variables": v})
        force = s["force"]
        if force == "http500":
            return self._reply(500, {"error": "boom"})
        if "issueArchive" in q:
            if force == "archive_errors":
                return self._errors("usage limit exceeded")
            if force == "archive_false":
                return self._reply(200, {"data": {"issueArchive": {"success": False}}})
            row = find(s, v["id"])
            if row is None:
                return self._errors("Entity not found: Issue")
            if row["archivedAt"]:
                return self._errors("Issue is already archived")
            if force != "archive_noop":
                row["archivedAt"] = ARCHIVED_AT
            if force == "reread_missing":
                s["force"] = "not_found_after"
            return self._reply(200, {"data": {"issueArchive": {"success": True}}})
        if "issueDelete" in q or "issueTrash" in q:
            return self._errors("mutação inesperada")
        if "issues(" in q:
            if force == "list_errors":
                return self._errors("query too complex")
            try:
                rows = [r for r in s["issues"] if matches(r, v.get("f") or {}, s["teams"])]
            except ValueError as e:
                return self._errors(str(e))
            if not ("includeArchived:$arch" in q and v.get("arch")):
                rows = [r for r in rows if not r["archivedAt"]]
            start = int(v["after"]) if v.get("after") else 0
            size = min(v["n"], SERVER_PAGE)
            page = rows[start:start + size]
            more = start + size < len(rows)
            return self._reply(200, {"data": {"issues": {"nodes": page, "pageInfo": {"hasNextPage": more, "endCursor": str(start + size) if more else None}}}})
        if "teams(" in q:
            return self._reply(200, {"data": {"teams": {"nodes": s["teams"]}}})
        if "issue(id" in q:
            if force == "null_issue":
                return self._reply(200, {"data": {"issue": None}})
            if force == "not_found_after":
                return self._errors("Entity not found: Issue")
            row = find(s, v["id"])
            if row is None:
                return self._errors("Entity not found: Issue")
            return self._reply(200, {"data": {"issue": row}})
        return self._errors("consulta desconhecida da bancada")


class Fake:
    def __init__(self, force=None):
        self.force = force

    def __enter__(self):
        self.store = seed()
        self.store["force"] = self.force
        handler = type("H", (Handler,), {"store": self.store})
        self.srv = http.server.ThreadingHTTPServer(("127.0.0.1", 0), handler)
        self.port = self.srv.server_address[1]
        threading.Thread(target=self.srv.serve_forever, daemon=True).start()
        return self

    def __exit__(self, *a):
        self.srv.shutdown()
        self.srv.server_close()

    def mutations(self):
        return [r for r in self.store["log"] if "issueArchive" in r["query"]]


def run(tm_dir, fake, *args):
    env = {k: v for k, v in os.environ.items() if not k.startswith(("LINEAR_", "TM_", "CLICKUP_"))}
    env.update({"TASK_MANAGER_PROVIDER": "linear", "TM_ENV_FILE": os.path.join(tm_dir, "nao-existe.env"),
                "LINEAR_API_KEY": KEY, "LC_ALL": "C.UTF-8",
                "TM_LINEAR_ENDPOINT": f"http://127.0.0.1:{fake.port}/graphql" if fake else "http://127.0.0.1:1/graphql"})
    try:
        p = subprocess.run(["bash", os.path.join(tm_dir, "tm.sh"), *args], capture_output=True, text=True, env=env, timeout=15, cwd=tm_dir)
    except subprocess.TimeoutExpired:   # laço sem fim conta como reprovação do caso, não derruba a bancada
        return 124, None, "timeout: o verbo não terminou em 15 s"
    try:
        out = json.loads(p.stdout) if p.stdout.strip() else None
    except ValueError:
        out = None
    return p.returncode, out, p.stderr.strip()


def ids(out):
    return sorted(i["identifier"] for i in out["issues"])


# ── casos: cada um devolve "" (verde) ou o motivo ────────────────────────────
def c_caps(d):
    env_out = subprocess.run(["python3", "-I", "-B", os.path.join(d, "adapters/linear.py"), "--capabilities"], capture_output=True, text=True).stdout.split()
    missing = {"item.archive", "item.list"} - set(env_out)
    return "" if not missing else f"ausentes de --capabilities: {sorted(missing)}"


def c_archive_ok(d):
    with Fake() as f:
        rc, out, err = run(d, f, "item.archive", "SAC-1")
        if rc != 0 or not out:
            return f"rc={rc} {err[:160]}"
        if not (out["archived"] and out["already_archived"] is False and out["verified"] is True and out["archivedAt"] == ARCHIVED_AT):
            return f"retorno errado: {out}"
        m = f.mutations()
        if len(m) != 1 or m[0]["variables"]["id"] != "uuid-1":
            return f"mutação esperada 1× com o uuid: {m}"
    return ""


def c_archive_twice(d):
    with Fake() as f:
        first = run(d, f, "item.archive", "SAC-1")
        rc, out, err = run(d, f, "item.archive", "SAC-1")
        if first[0] != 0 or rc != 0:
            return f"rc1={first[0]} rc2={rc} {err[:160]}"
        if out["already_archived"] is not True or out["archived"] is not True:
            return f"2ª chamada não declarou já arquivada: {out}"
        if len(f.mutations()) != 1:
            return f"a mutação rodou {len(f.mutations())}×; esperado 1"
    return ""


def c_archive_preexisting(d):
    with Fake() as f:
        rc, out, err = run(d, f, "item.archive", "SAC-6")
        if rc != 0 or not out or out["already_archived"] is not True or out["archivedAt"] != ARCHIVED_AT:
            return f"rc={rc} {out} {err[:120]}"
        if f.mutations():
            return "mutação chamada em issue já arquivada"
    return ""


def c_archive_dry(d):
    with Fake() as f:
        rc, out, err = run(d, f, "item.archive", "SAC-1", "--dry-run")
        if rc != 0 or not out or out.get("would_archive") is not True or out["archived"] is not False:
            return f"rc={rc} {out} {err[:120]}"
        if f.mutations():
            return "--dry-run chamou a mutação"
    return ""


def c_archive_not_found(d):
    with Fake() as f:
        rc, out, err = run(d, f, "item.archive", "SAC-999")
        if rc != 1 or out is not None or "not found" not in err:
            return f"rc={rc} {out} {err[:160]}"
        if f.mutations():
            return "mutação chamada em issue inexistente"
    return ""


def c_archive_null_issue(d):
    # `issue` nulo sem `errors`: a resolução tem de nomear, não virar traceback nem sucesso
    with Fake("null_issue") as f:
        rc, out, err = run(d, f, "item.archive", "SAC-1")
        if rc != 1 or out is not None or "não encontrada" not in err or f.mutations():
            return f"rc={rc} {out} {err[:160]}"
    return ""


def c_archive_bad_id(d):
    with Fake() as f:
        rc, out, err = run(d, f, "item.archive", "nao-e-id")
        if rc != 2 or "inválido" not in err:
            return f"rc={rc} {err[:160]}"
        if f.store["log"]:
            return "id inválido foi à rede"
    return ""


def c_archive_usage(d):
    with Fake() as f:
        for args in (["item.archive"], ["item.archive", "SAC-1", "SAC-2"], ["item.archive", "SAC-1", "--force"]):
            rc, out, err = run(d, f, *args)
            if rc != 2 or out is not None:
                return f"{args}: rc={rc} {out} {err[:120]}"
        if f.store["log"]:
            return "erro de uso foi à rede"
    return ""


def c_archive_api_error(d):
    with Fake("archive_errors") as f:
        rc, out, err = run(d, f, "item.archive", "SAC-1")
        if rc != 1 or out is not None or "usage limit exceeded" not in err:
            return f"rc={rc} {out} {err[:160]}"
    return ""


def c_archive_http(d):
    with Fake("http500") as f:
        rc, out, err = run(d, f, "item.archive", "SAC-1")
        if rc != 1 or out is not None or "HTTP 500" not in err:
            return f"rc={rc} {out} {err[:160]}"
    return ""


def c_archive_success_false(d):
    with Fake("archive_false") as f:
        rc, out, err = run(d, f, "item.archive", "SAC-1")
        if rc != 1 or out is not None or "success=false" not in err:
            return f"rc={rc} {out} {err[:160]}"
    return ""


def c_archive_noop(d):
    with Fake("archive_noop") as f:
        rc, out, err = run(d, f, "item.archive", "SAC-1")
        if rc != 1 or out is not None or "sem archivedAt" not in err:
            return f"rc={rc} {out} {err[:160]}"
    return ""


def c_archive_reread_fails(d):
    with Fake("reread_missing") as f:
        rc, out, err = run(d, f, "item.archive", "SAC-1")
        if rc != 0 or not out or out["verified"] is not False or "releitura falhou" not in err:
            return f"rc={rc} {out} {err[:160]}"
    return ""


def c_list_default(d):
    with Fake() as f:
        rc, out, err = run(d, f, "item.list")
        if rc != 0 or ids(out) != ["OPS-7", "SAC-1", "SAC-2", "SAC-3", "SAC-4", "SAC-5"]:
            return f"rc={rc} {out and ids(out)} {err[:120]}"
        if out["count"] != 6 or out["truncated"] is not False:
            return f"count/truncated: {out['count']} {out['truncated']}"
    return ""


def c_list_paginates(d):
    with Fake() as f:
        rc, out, err = run(d, f, "item.list")
        pages = [r for r in f.store["log"] if "issues(" in r["query"]]
        if rc != 0 or len(pages) != 3 or pages[1]["variables"]["after"] != "2":
            return f"rc={rc} páginas={len(pages)} {err[:120]}"
    return ""


def c_list_limit(d):
    with Fake() as f:
        rc, out, err = run(d, f, "item.list", "--limit", "3")
        if rc != 0 or out["count"] != 3 or out["truncated"] is not True or "truncado" not in err:
            return f"rc={rc} {out and (out['count'], out['truncated'])} {err[:120]}"
    return ""


def c_list_limit_exact(d):
    with Fake() as f:
        rc, out, err = run(d, f, "item.list", "--limit", "6")
        if rc != 0 or out["count"] != 6 or out["truncated"] is not False:
            return f"rc={rc} {out and (out['count'], out['truncated'])} {err[:120]}"
    return ""


def c_list_state_type(d):
    with Fake() as f:
        rc, out, err = run(d, f, "item.list", "--state-type", "completed,canceled")
        if rc != 0 or ids(out) != ["OPS-7", "SAC-1", "SAC-2", "SAC-3"]:
            return f"rc={rc} {out and ids(out)} {err[:120]}"
    return ""


def c_list_state_name(d):
    with Fake() as f:
        rc, out, err = run(d, f, "item.list", "--state", "in progress")
        if rc != 0 or ids(out) != ["SAC-4"]:
            return f"rc={rc} {out and ids(out)} {err[:120]}"
    return ""


def c_list_older(d):
    with Fake() as f:
        rc, out, err = run(d, f, "item.list", "--older-than-days", "60")
        if rc != 0 or ids(out) != ["SAC-1", "SAC-2", "SAC-4"]:
            return f"rc={rc} {out and ids(out)} {err[:120]}"
        if not out["updated_before"]:
            return "corte de idade não declarado no retorno"
    return ""


def c_list_archived(d):
    with Fake() as f:
        rc, out, err = run(d, f, "item.list", "--include-archived", "--state-type", "completed")
        if rc != 0 or ids(out) != ["OPS-7", "SAC-1", "SAC-3", "SAC-6"]:
            return f"rc={rc} {out and ids(out)} {err[:120]}"
        archived = [i for i in out["issues"] if i["identifier"] == "SAC-6"][0]
        if archived["archivedAt"] != ARCHIVED_AT:
            return f"archivedAt ausente: {archived}"
    return ""


def c_list_team(d):
    with Fake() as f:
        rc, out, err = run(d, f, "item.list", "--team", "OPS")
        if rc != 0 or ids(out) != ["OPS-7"]:
            return f"rc={rc} {out and ids(out)} {err[:120]}"
    return ""


def c_list_bad_state_type(d):
    with Fake() as f:
        rc, out, err = run(d, f, "item.list", "--state-type", "done")
        if rc != 2 or "--state-type inválido" not in err or f.store["log"]:
            return f"rc={rc} log={len(f.store['log'])} {err[:120]}"
    return ""


def c_list_bad_numbers(d):
    with Fake() as f:
        for args in (["--limit", "x"], ["--limit", "0"], ["--limit", "-1"], ["--older-than-days", "x"], ["--older-than-days", "-3"]):
            rc, out, err = run(d, f, "item.list", *args)
            if rc != 2 or out is not None:
                return f"{args}: rc={rc} {err[:120]}"
        if f.store["log"]:
            return "número inválido foi à rede"
    return ""


def c_list_usage(d):
    with Fake() as f:
        for args in (["solto"], ["--nada", "x"]):
            rc, out, err = run(d, f, "item.list", *args)
            if rc != 2 or out is not None:
                return f"{args}: rc={rc} {err[:120]}"
    return ""


def c_list_api_error(d):
    with Fake("list_errors") as f:
        rc, out, err = run(d, f, "item.list")
        if rc != 1 or out is not None or "query too complex" not in err:
            return f"rc={rc} {out} {err[:160]}"
    return ""


CASES = [
    ("caps", "--capabilities lista os dois verbos", c_caps),
    ("a-ok", "item.archive arquiva, chama a mutação 1× com o uuid e relê", c_archive_ok),
    ("a-twice", "arquivar duas vezes: a 2ª declara já arquivada e não repete a mutação", c_archive_twice),
    ("a-pre", "issue já arquivada antes: sem mutação", c_archive_preexisting),
    ("a-dry", "--dry-run não muta", c_archive_dry),
    ("a-404", "issue inexistente: rc 1, sem mutação", c_archive_not_found),
    ("a-null", "resposta sem a issue: rc 1, nada em stdout", c_archive_null_issue),
    ("a-badid", "id inválido: rc 2 antes da rede", c_archive_bad_id),
    ("a-usage", "uso errado (sem id, id extra, flag desconhecida): rc 2 antes da rede", c_archive_usage),
    ("a-err", "`errors` da API na mutação: rc 1, stderr nomeia, stdout vazio", c_archive_api_error),
    ("a-http", "HTTP 500: rc 1", c_archive_http),
    ("a-false", "success=false: rc 1", c_archive_success_false),
    ("a-noop", "success=true sem archivedAt na releitura: rc 1", c_archive_noop),
    ("a-reread", "releitura falha depois do success: rc 0, verified=false e aviso", c_archive_reread_fails),
    ("l-default", "item.list esconde arquivadas por padrão", c_list_default),
    ("l-pages", "item.list segue o cursor por todas as páginas", c_list_paginates),
    ("l-limit", "--limit corta e declara truncated", c_list_limit),
    ("l-exact", "--limit igual ao total não declara truncated", c_list_limit_exact),
    ("l-type", "--state-type aceita lista", c_list_state_type),
    ("l-name", "--state filtra por nome sem diferenciar caixa", c_list_state_name),
    ("l-old", "--older-than-days corta por updatedAt e declara o corte", c_list_older),
    ("l-arch", "--include-archived traz as arquivadas com archivedAt", c_list_archived),
    ("l-team", "--team filtra pelo team resolvido", c_list_team),
    ("l-badtype", "--state-type fora do vocabulário: rc 2 antes da rede", c_list_bad_state_type),
    ("l-badnum", "--limit e --older-than-days inválidos: rc 2 antes da rede", c_list_bad_numbers),
    ("l-usage", "posicional e flag desconhecida: rc 2", c_list_usage),
    ("l-err", "`errors` da API na listagem: rc 1, stdout vazio", c_list_api_error),
]

# (âncora no linear.py, troca, caso que tem de reprovar)
MUTANTS = [
    ('    "item.archive",\n    "item.list",\n', '    "item.list",\n', "caps"),
    ('issueArchive(id:$id){ success }', 'issueDelete(id:$id){ success }', "a-ok"),
    ('{"id": iss["id"]})\n    if not (data.get("issueArchive")', '{"id": pos[0]})\n    if not (data.get("issueArchive")', "a-ok"),
    ('    if iss.get("archivedAt"):\n        return {**base, "archived": True, "already_archived": True, "archivedAt": iss["archivedAt"]}\n', '', "a-twice"),
    ('    if iss.get("archivedAt"):\n        return {**base, "archived": True, "already_archived": True, "archivedAt": iss["archivedAt"]}\n', '', "a-pre"),
    ('    data = gql("query IssueArchiveState($id:String!){ issue(id:$id){ id identifier title archivedAt state { name type } } }", {"id": ident})\n    if not data.get("issue"):\n        raise TmError(f"issue não encontrada: {ident}")\n    return data["issue"]',
     '    data = gql("query IssueArchiveState($id:String!){ issue(id:$id){ id identifier title archivedAt state { name type } } }", {"id": ident})\n    return data["issue"] or {}', "a-null"),
    ('    if dry_run:\n        return', '    if False:\n        return', "a-dry"),
    ('    if not (ID_RE.match(pos[0]) or UUID_RE.match(pos[0])):\n        raise TmError(f"id de issue inválido: \'{pos[0]}\' (forma ABC-123 ou UUID)", 2)\n    iss = _archive_view',
     '    iss = _archive_view', "a-badid"),
    ('    if any(a.startswith("--") for a in pos) or len(pos) != 1:\n        raise TmError(f"uso: tm.sh {usage}", 2)\n    if not (ID_RE',
     '    if not (ID_RE', "a-usage"),
    ('    if payload.get("errors"):', '    if False:', "a-err"),
    ('    if not (data.get("issueArchive") or {}).get("success"):', '    if False:', "a-false"),
    ('    if not after.get("archivedAt"):', '    if False:', "a-noop"),
    ('    except TmError as e:\n        print(f"tm (linear): {iss[\'identifier\']} arquivada (success=true), mas a releitura falhou: {e}", file=sys.stderr)\n        return {**base, "archived": True, "already_archived": False, "archivedAt": None, "verified": False}\n',
     '    except ZeroDivisionError:\n        raise\n', "a-reread"),
    ('"archivedAt": None, "verified": False}', '"archivedAt": None, "verified": True}', "a-reread"),
    ('after:$after, includeArchived:$arch){', 'after:$after){', "l-arch"),
    ('"after": cursor, "arch": include_archived}', '"after": cursor, "arch": True}', "l-default"),
    ('        cursor = info["endCursor"]\n    return {"count"', '        break\n    return {"count"', "l-pages"),
    ('            truncated = True\n', '            truncated = False\n', "l-limit"),
    ('        if len(nodes) >= limit or not info.get("endCursor"):', '        if not info.get("endCursor"):', "l-limit"),
    ('        state["type"] = {"in": _state_types(o["state-type"])}', '        pass', "l-type"),
    ('        state["name"] = {"eqIgnoreCase": o["state"]}', '        pass', "l-name"),
    ('        flt["updatedAt"] = {"lt": cutoff}', '        pass', "l-old"),
    ('        flt["team"] = {"id": {"eq": _team_id(o["team"])}}\n    nodes, cursor, truncated', '        pass\n    nodes, cursor, truncated', "l-team"),
    ('    if not types or bad:', '    if False:', "l-badtype"),
    ('    if limit < 1:', '    if False:', "l-badnum"),
    ('    if not re.match(r"^\\d+$", value):', '    if False:', "l-badnum"),
    ('    if pos:\n        raise TmError("uso: tm.sh item.list', '    if False:\n        raise TmError("uso: tm.sh item.list', "l-usage"),
]


def copy_tree(dst):
    os.makedirs(os.path.join(dst, "adapters"))
    for n in ("tm.sh", "env-check.sh"):
        shutil.copy2(os.path.join(TM_DIR, n), os.path.join(dst, n))
    shutil.copy2(os.path.join(TM_DIR, "adapters/linear.py"), os.path.join(dst, "adapters/linear.py"))


def main():
    fails, oks = [], 0
    by_id = {c[0]: c for c in CASES}
    killed = 0
    with tempfile.TemporaryDirectory(prefix="tm-linear-archive-bench-") as tmp:
        for cid, desc, fn in CASES:
            why = fn(TM_DIR)
            if why:
                fails.append(f"({cid}) {desc}: {why}")
            else:
                oks += 1
                print(f"ok   ({cid}) {desc}")
        cp = os.path.join(tmp, "copy")
        copy_tree(cp)
        target_cases = sorted({m[2] for m in MUTANTS})
        clean_bad = [f"({c}) {by_id[c][2](cp)}" for c in target_cases if by_id[c][2](cp)]
        if clean_bad:
            fails.append("cópia limpa NÃO ficou verde no arranjo dos mutantes — nenhum mutante conta: " + "; ".join(clean_bad))
        else:
            print(f"ok   cópia limpa verde nos {len(target_cases)} casos-alvo dos mutantes")
        target = os.path.join(cp, "adapters/linear.py")
        src = open(target, encoding="utf-8").read()
        for old, new, want in MUTANTS:
            if src.count(old) != 1:
                fails.append(f"mutante não aplicou (âncora {src.count(old)}×): {old[:60]!r} → ({want})")
                continue
            with open(target, "w", encoding="utf-8") as fh:
                fh.write(src.replace(old, new))
            why = by_id[want][2](cp)
            if why and not clean_bad:
                killed += 1
                print(f"ok   mutante morde → ({want}) reprova [{' '.join(old.split())[:60]}]: {' '.join(why.split())[:110]}")
            elif not clean_bad:
                fails.append(f"mutante NÃO morde: ({want}) segue verde com a cura revertida: {' '.join(old.split())[:70]}")
        with open(target, "w", encoding="utf-8") as fh:
            fh.write(src)
    if fails:
        print("\nFALHA (%d):\n- %s" % (len(fails), "\n- ".join(fails)))
    print(f"\ntask-manager-linear-archive-bench: {oks}/{len(CASES)} caso(s) verdes; {killed}/{len(MUTANTS)} mutante(s) mordem; "
          f"cópia limpa {'verde' if not clean_bad else 'VERMELHA'}")
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
