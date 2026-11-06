#!/usr/bin/env python3
"""Bancada OFFLINE do executável do ClickUp (.claude/utils/task-manager/adapters/clickup.py), pelo dispatcher tm.sh.

Roda pela família run_task_manager_clickup_selftests do lint-selftest.sh. Nenhuma chamada sai da máquina: o ClickUp
é trocado por um servidor HTTP FALSO em loopback (costura TM_CLICKUP_ENDPOINT, que o executável só aceita em
127.0.0.1) que reproduz as armadilhas MEDIDAS AO VIVO por um adotante em 2026-10-02 (clickup.md, Notas Operacionais):
  · priority string devolve 400 Priority invalid (só inteiro 1-4);
  · data sem a flag due_date_time/start_date_time é normalizada para 07:00 do DIA ANTERIOR; data em ISO é aceita
    e NÃO aplicada (200, campo nulo);
  · tags no corpo do POST/PUT da task devolvem 200 SEM efeito; só POST/DELETE /task/{id}/tag/{nome} mudam tags;
  · GET /task/{id} só traz `subtasks` com include_subtasks=true;
  · no create, só `markdown_content` grava a descrição (o `markdown_description` é campo da RESPOSTA);
  · status é da LIST: nome que a List não tem devolve 400 Status not found;
  · comentários vêm 25 por vez (aqui 2, por TM_CLICKUP_COMMENT_PAGE), do mais novo, paginados por start/start_id;
  · GET /team/{id}/task ACEITA E IGNORA parâmetro de texto: devolve tudo, paginado por índice.
O que esta bancada NÃO prova: que o ClickUp real se comporta como o falso. O falso é a medição de 2026-10-02 posta em
código; o ao vivo do executável fica declarado como não medido (clickup-executavel.md).

Três partes, como a do dissect:
  1. CASOS: um por capacidade listada pelo executável, mais as armadilhas, todos pelo tm.sh;
  2. CÓPIA LIMPA: a árvore copiada (tm.sh + env-check.sh + clickup.py) roda os casos-alvo dos mutantes e TEM de
     ficar verde no mesmo arranjo antes de qualquer mutante contar (um mutante "morto" numa cópia quebrada não
     prova nada — a lição de 2026-11-04);
  3. MUTANTES: cada um reverte UMA cura na cópia e EXIGE que o caso dela reprove.
Saída: `ok   …` por caso verde e, no fim, `FALHA (n):` com `- …` por vermelho; última linha com as contagens; rc 0 ou 1.
"""
import http.server
import json
import os
import shutil
import subprocess
import sys
import tempfile
import threading
import urllib.parse

ROOT = (sys.argv[1] if len(sys.argv) > 1 else
        subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True, text=True).stdout.strip() or os.getcwd())
TM_DIR = os.path.join(ROOT, ".claude/utils/task-manager")
TOKEN = "pk_fake_bench"
COMMENT_PAGE = 2
SEARCH_PAGE = 2


# ── o ClickUp falso ──────────────────────────────────────────────────────────
def seed():
    lst = {"id": "L1", "name": "Sprint", "statuses": [{"status": s} for s in ("to do", "in progress", "pull request", "complete")]}
    def task(i, name, parent=None, desc="", status="to do", tags=()):
        return {"id": i, "name": name, "parent": parent, "markdown_description": desc, "text_content": desc,
                "status": {"status": status, "type": "open"}, "priority": None, "list": {"id": "L1", "name": "Sprint"},
                "tags": [{"name": t} for t in tags], "due_date": None, "start_date": None, "time_estimate": None,
                "attachments": [], "url": f"https://app.example/t/{i}"}
    tasks = {
        "p0000001": task("p0000001", "Mãe", desc="OBJETIVO DA MAE: integrar o gateway", tags=("a",)),
        "s0000001": task("s0000001", "Filha um", parent="p0000001", desc="primeira"),
        "s0000002": task("s0000002", "Filha dois", parent="p0000001", desc="segunda", status="complete"),
        "g0000001": task("g0000001", "Neta", parent="s0000001", desc="neta"),
        "x0000001": task("x0000001", "Avulsa sem nada"),
        "x0000002": task("x0000002", "Outra coisa"),
        "x0000003": task("x0000003", "Planejar a integração com o ERP"),
        "x0000004": task("x0000004", "Mais uma"),
    }
    tasks["p0000001"]["attachments"] = [{"id": "a1", "title": "print.png", "url": "https://att.example/a1", "extension": "png", "size": 100}]
    comments = {"p0000001": [
        {"id": "c1", "comment_text": "primeiro", "date": "1000", "user": {"username": "ana"}, "reply_count": 1},
        {"id": "c2", "comment_text": "segundo", "date": "2000", "user": {"username": "bia"}, "reply_count": 0},
        {"id": "c3", "comment_text": "terceiro", "date": "3000", "user": {"username": "ana"}, "reply_count": 0},
    ]}
    replies = {"c1": [{"id": "r1", "comment_text": "resposta ao primeiro", "date": "1500", "user": {"username": "bia"}}]}
    return {"lists": {"L1": lst}, "tasks": tasks, "comments": comments, "replies": replies, "log": [], "n": 0,
            "force": None}


def _apply_dates(store_task, body):
    for key in ("due_date", "start_date"):
        if key not in body:
            continue
        v = body[key]
        if not isinstance(v, int):          # ISO/string: aceito e NÃO aplicado (200, campo nulo)
            store_task[key] = None
            continue
        if body.get(key + "_time") is not True:   # sem a flag: 07:00 do dia anterior (o deslocamento medido)
            day = (v // 86400000) * 86400000
            v = day - 86400000 + 7 * 3600000
        store_task[key] = str(v)


def _priority_ok(p):
    return p is None or (isinstance(p, int) and not isinstance(p, bool) and 1 <= p <= 4)


def _prio_obj(p):
    names = {1: "urgent", 2: "high", 3: "normal", 4: "low"}
    return None if p is None else {"id": str(p), "priority": names[p]}


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

    def _handle(self, method):
        st = self.store
        u = urllib.parse.urlsplit(self.path)
        q = urllib.parse.parse_qs(u.query)
        n = int(self.headers.get("Content-Length") or 0)
        body = json.loads(self.rfile.read(n).decode("utf-8")) if n else None
        path = u.path
        st["log"].append({"method": method, "path": path, "query": q, "body": body, "auth": self.headers.get("Authorization")})
        if st["force"]:
            code, obj = st["force"]
            return self._reply(code, obj)
        if self.headers.get("Authorization") != TOKEN:
            return self._reply(401, {"err": "Token invalid", "ECODE": "OAUTH_025"})
        if not path.startswith("/api/v2/"):
            return self._reply(404, {"err": "Route not found", "ECODE": "APP_001"})
        parts = [urllib.parse.unquote(p) for p in path[len("/api/v2/"):].split("/")]
        T = st["tasks"]

        def view(t):
            out = json.loads(json.dumps(t))
            out["priority"] = _prio_obj(t["priority"]) if not isinstance(t["priority"], dict) else t["priority"]
            if q.get("include_markdown_description") != ["true"]:
                out.pop("markdown_description", None)
            return out

        if parts == ["team"] and method == "GET":
            return self._reply(200, {"teams": [{"id": "W1", "name": "Workspace"}]})
        if len(parts) == 2 and parts[0] == "task" and method == "GET":
            t = T.get(parts[1])
            if not t:
                return self._reply(404, {"err": "Task not found", "ECODE": "ITEM_013"})
            out = view(t)
            if q.get("include_subtasks") == ["true"]:   # o legado `subtasks=true` devolve a task SEM o campo
                out["subtasks"] = [view(c) for c in T.values() if c["parent"] == t["id"]]
            return self._reply(200, out)
        if len(parts) == 3 and parts[0] == "list" and parts[2] == "task" and method == "POST":
            lst = st["lists"].get(parts[1])
            if not lst:
                return self._reply(404, {"err": "List not found", "ECODE": "LIST_001"})
            return self._write(lst, None, body)
        if len(parts) == 2 and parts[0] == "task" and method == "PUT":
            t = T.get(parts[1])
            if not t:
                return self._reply(404, {"err": "Task not found", "ECODE": "ITEM_013"})
            return self._write(st["lists"]["L1"], t, body)
        if len(parts) == 4 and parts[0] == "task" and parts[2] == "tag" and method in ("POST", "DELETE"):
            t = T.get(parts[1])
            if not t:
                return self._reply(404, {"err": "Task not found", "ECODE": "ITEM_013"})
            names = [g["name"] for g in t["tags"]]
            if method == "POST" and parts[3] not in names:
                t["tags"].append({"name": parts[3]})
            if method == "DELETE":
                t["tags"] = [g for g in t["tags"] if g["name"] != parts[3]]
            return self._reply(200, {})
        if len(parts) == 2 and parts[0] == "list" and method == "GET":
            lst = st["lists"].get(parts[1])
            return self._reply(200, lst) if lst else self._reply(404, {"err": "List not found", "ECODE": "LIST_001"})
        if len(parts) == 3 and parts[0] == "task" and parts[2] == "comment":
            cs = st["comments"].setdefault(parts[1], [])
            if method == "POST":
                st["n"] += 1
                c = {"id": f"n{st['n']}", "comment_text": body.get("comment_text"), "date": str(9000 + st["n"]), "user": {"username": "bot"}}
                cs.append(c)
                return self._reply(200, {"id": c["id"], "hist_id": "h", "date": int(c["date"])})
            ordered = sorted(cs, key=lambda c: int(c["date"]), reverse=True)   # mais novo primeiro
            if "start" in q:
                lim = int(q["start"][0])
                ordered = [c for c in ordered if int(c["date"]) < lim]
            return self._reply(200, {"comments": ordered[:COMMENT_PAGE]})
        if len(parts) == 3 and parts[0] == "comment" and parts[2] == "reply" and method == "GET":
            return self._reply(200, {"comments": st["replies"].get(parts[1], [])})
        if len(parts) == 3 and parts[0] == "team" and parts[2] == "task" and method == "GET":
            # ACEITA E IGNORA qualquer filtro de texto: devolve tudo, por índice de página
            allt = [view(t) for t in sorted(T.values(), key=lambda t: t["id"]) if t["id"].startswith("x")]
            page = int((q.get("page") or ["0"])[0])
            chunk = allt[page * SEARCH_PAGE:(page + 1) * SEARCH_PAGE]
            return self._reply(200, {"tasks": chunk, "last_page": (page + 1) * SEARCH_PAGE >= len(allt)})
        if len(parts) == 3 and parts[0] == "team" and parts[2] == "space":
            return self._reply(200, {"spaces": [{"id": "S1", "name": "Engenharia"}]})
        if len(parts) == 3 and parts[0] == "space" and parts[2] == "folder":
            return self._reply(200, {"folders": [{"id": "F1", "name": "Produto", "lists": [{"id": "L1", "name": "Sprint"}]}]})
        if len(parts) == 3 and parts[0] == "space" and parts[2] == "list":
            return self._reply(200, {"lists": [{"id": "L9", "name": "Solta"}]})
        return self._reply(404, {"err": "Route not found", "ECODE": "APP_001"})

    def _write(self, lst, t, body):
        st = self.store
        if "priority" in body and not _priority_ok(body["priority"]):
            return self._reply(400, {"err": "Priority invalid", "ECODE": "INPUT_005"})
        names = [s["status"] for s in lst["statuses"]]
        if "status" in body and body["status"] not in names:
            return self._reply(400, {"err": "Status not found", "ECODE": "CRTSK_001"})
        if t is None:
            st["n"] += 1
            tid = f"k{st['n']:07d}"
            t = {"id": tid, "name": body.get("name"), "parent": body.get("parent"), "markdown_description": "",
                 "text_content": "", "status": {"status": names[0], "type": "open"}, "priority": None,
                 "list": {"id": lst["id"], "name": lst["name"]}, "tags": [], "due_date": None, "start_date": None,
                 "time_estimate": None, "attachments": [], "url": f"https://app.example/t/{tid}"}
            st["tasks"][tid] = t
            if "markdown_content" in body:      # só o campo do PEDIDO grava; markdown_description é ignorado
                t["markdown_description"] = t["text_content"] = body["markdown_content"]
        else:
            if "name" in body:
                t["name"] = body["name"]
            if "markdown_content" in body:
                t["markdown_description"] = t["text_content"] = body["markdown_content"]
        # tags no corpo: 200 SEM efeito (a armadilha medida)
        if "priority" in body:
            t["priority"] = body["priority"]
        if "status" in body:
            t["status"] = {"status": body["status"], "type": "custom"}
        if "time_estimate" in body:
            t["time_estimate"] = body["time_estimate"] if isinstance(body["time_estimate"], int) else None
        _apply_dates(t, body)
        out = json.loads(json.dumps(t))
        out["priority"] = _prio_obj(t["priority"])
        return self._reply(200, out)

    def do_GET(self):
        self._handle("GET")

    def do_POST(self):
        self._handle("POST")

    def do_PUT(self):
        self._handle("PUT")

    def do_DELETE(self):
        self._handle("DELETE")


class Fake:
    def __enter__(self):
        self.store = seed()
        handler = type("H", (Handler,), {"store": self.store})
        self.srv = http.server.ThreadingHTTPServer(("127.0.0.1", 0), handler)
        self.port = self.srv.server_address[1]
        self.th = threading.Thread(target=self.srv.serve_forever, daemon=True)
        self.th.start()
        return self

    def __exit__(self, *a):
        self.srv.shutdown()
        self.srv.server_close()


# ── rodar o tm.sh como a sessão roda ─────────────────────────────────────────
def run(tm_dir, fake, *args, token=TOKEN, stdin=None, extra_env=None):
    env = {k: v for k, v in os.environ.items() if not k.startswith(("CLICKUP_", "TM_", "LINEAR_"))}
    env.update({"TASK_MANAGER_PROVIDER": "clickup", "TM_ENV_FILE": os.path.join(tm_dir, "nao-existe.env"),
                "TM_CLICKUP_COMMENT_PAGE": str(COMMENT_PAGE), "LC_ALL": "C.UTF-8"})
    if token is not None:
        env["CLICKUP_API_TOKEN"] = token
    if fake is not None:
        env["TM_CLICKUP_ENDPOINT"] = f"http://127.0.0.1:{fake.port}/api/v2"
    else:
        env["TM_CLICKUP_ENDPOINT"] = "http://127.0.0.1:1/api/v2"   # porta fechada: rede seria rc 1
    env.update(extra_env or {})
    p = subprocess.run(["bash", os.path.join(tm_dir, "tm.sh"), *args], capture_output=True, text=True,
                       env=env, input=stdin, timeout=60, cwd=tm_dir)
    try:
        out = json.loads(p.stdout) if p.stdout.strip() else None
    except ValueError:
        out = None
    return p.returncode, out, p.stderr.strip()


def reqs(fake, method=None, prefix=""):
    return [r for r in fake.store["log"] if (method is None or r["method"] == method) and r["path"].startswith("/api/v2/" + prefix)]


# ── casos: cada um devolve "" (verde) ou o motivo ────────────────────────────
def c_capabilities(d, scratch):
    p = subprocess.run(["python3", "-I", "-B", os.path.join(d, "adapters/clickup.py"), "--capabilities"], capture_output=True, text=True)
    env = {k: v for k, v in os.environ.items() if not k.startswith(("CLICKUP_", "TM_"))}
    env.update({"TASK_MANAGER_PROVIDER": "clickup", "TM_ENV_FILE": os.path.join(d, "nao-existe.env")})
    q = subprocess.run(["bash", os.path.join(d, "tm.sh"), "--capabilities"], capture_output=True, text=True, env=env)
    want = {"item.read", "search.query", "comment.add", "item.create", "status.transition"}
    if q.returncode != 0 or q.stdout != p.stdout or not want <= set(q.stdout.split()):
        return f"rc={q.returncode} lista do tm.sh ≠ clickup.py ou sem o mínimo pedido ({sorted(want - set(q.stdout.split()))})"
    return ""


def c_token_missing(d, scratch):
    rc, _, err = run(d, None, "item.read", "p0000001", token=None)
    return "" if rc == 2 and "CLICKUP_API_TOKEN ausente" in err else f"rc={rc} {err[:160]}"


def c_auth_no_bearer(d, scratch):
    with Fake() as f:
        rc, out, err = run(d, f, "item.read", "p0000001", "--lean")
        auth = {r["auth"] for r in f.store["log"]}
    return "" if rc == 0 and auth == {TOKEN} and out and out["id"] == "p0000001" else f"rc={rc} auth={auth} {err[:160]}"


def c_read_full(d, scratch):
    with Fake() as f:
        rc, out, err = run(d, f, "item.read", "p0000001")
    if rc != 0 or not out:
        return f"rc={rc} {err[:200]}"
    ids = [c["id"] for c in out["comments"]]
    h = out["hierarchy"]
    kids = {s["id"]: [g["id"] for g in s["subtasks"]] for s in h["subtasks"]}
    checks = [
        (ids == ["c1", "c2", "c3"], f"comentários (todas as páginas, cronológico): {ids}"),
        (out["comments"][0].get("replies", [{}])[0].get("id") == "r1", "a resposta do c1 não veio"),
        (kids == {"s0000001": ["g0000001"], "s0000002": []}, f"subtasks recursivas: {kids}"),
        (h["role"] == "parent", f"role {h['role']}"),
        (out["counts"]["attachments"] == 1 and out["attachments"][0]["title"] == "print.png", "anexo não listado"),
        (out["description"].startswith("OBJETIVO DA MAE"), "descrição markdown ausente"),
        (out["untrusted"]["content"] is True, "sem o marcador untrusted"),
        (out["read_mode"] == "full", "read_mode"),
    ]
    bad = [m for ok, m in checks if not ok]
    return "; ".join(bad)


def c_read_subtask(d, scratch):
    with Fake() as f:
        rc, out, err = run(d, f, "hierarchy.context", "s0000001")
    if rc != 0 or not out:
        return f"rc={rc} {err[:200]}"
    sib = [(s["id"], s["status"]["status"]) for s in out["siblings"]]
    if out["role"] != "subtask" or not out["parent"]["description"].startswith("OBJETIVO DA MAE") or sib != [("s0000002", "complete")]:
        return f"role={out['role']} parent={out['parent'] and out['parent']['description'][:20]} siblings={sib}"
    return ""


def c_subtask_list(d, scratch):
    with Fake() as f:
        rc, out, err = run(d, f, "hierarchy.subtask_list", "p0000001")
        q = [r["query"] for r in reqs(f, "GET", "task/p0000001")]
    ids = sorted(s["id"] for s in (out or {}).get("subtasks", []))
    if rc != 0 or ids != ["s0000001", "s0000002"] or not all(x.get("include_subtasks") == ["true"] for x in q):
        return f"rc={rc} subtasks={ids} query={q[:1]} {err[:120]}"
    return ""


def c_create(d, scratch):
    with Fake() as f:
        rc, out, err = run(d, f, "item.create", "--title", "Nova", "--list", "L1", "--description", "**negrito** e lista",
                           "--priority", "high", "--due", "2026-11-10T15:00:00Z", "--start", "2026-11-09",
                           "--time-estimate", "90", "--tags", "fe,be")
        posts = reqs(f, "POST", "list/L1/task")
        tag_posts = [r["path"] for r in reqs(f, "POST") if "/tag/" in r["path"]]
    if rc != 0 or not out or not posts:
        return f"rc={rc} {err[:200]}"
    b = posts[0]["body"]
    due = 1794322800000   # 2026-11-10T15:00:00Z
    checks = [
        (b.get("markdown_content") == "**negrito** e lista" and "markdown_description" not in b, f"campo da descrição: {sorted(b)}"),
        (b.get("priority") == 2 and isinstance(b.get("priority"), int), f"priority={b.get('priority')!r}"),
        (b.get("due_date") == due and b.get("due_date_time") is True, f"due_date={b.get('due_date')!r} flag={b.get('due_date_time')!r}"),
        (b.get("start_date_time") is True and isinstance(b.get("start_date"), int), "start sem ms/flag"),
        (b.get("time_estimate") == 5400000, f"time_estimate={b.get('time_estimate')}"),
        ("tags" not in b, "tags foram no corpo do POST"),
        (sorted(p.rsplit("/", 1)[1] for p in tag_posts) == ["be", "fe"], f"POST de tag: {tag_posts}"),
        (sorted(out["tags"]) == ["be", "fe"], f"tags relidas: {out['tags']}"),
        (out["due_date"] == str(due) and out["description"] == "**negrito** e lista", f"releitura: due={out['due_date']} desc={out['description']!r}"),
    ]
    return "; ".join(m for ok, m in checks if not ok)


def c_subtask_create(d, scratch):
    with Fake() as f:
        rc, out, err = run(d, f, "hierarchy.subtask_create", "p0000001", "--title", "Filha três")
        posts = reqs(f, "POST", "list/L1/task")
    if rc != 0 or not posts or posts[0]["body"].get("parent") != "p0000001" or out["parent"] != "p0000001":
        return f"rc={rc} body={posts and posts[0]['body']} {err[:120]}"
    return ""


def c_priority_string_refused(d, scratch):
    with Fake() as f:
        rc, _, err = run(d, f, "priority.set", "p0000001", "alta")
        n = len(f.store["log"])
    return "" if rc == 2 and n == 0 and "INTEIRO" in err else f"rc={rc} requisições={n} {err[:160]}"


def c_priority_set(d, scratch):
    with Fake() as f:
        rc, out, err = run(d, f, "priority.set", "p0000001", "urgent")
        puts = reqs(f, "PUT")
    if rc != 0 or not puts or puts[0]["body"] != {"priority": 1} or out["priority"]["id"] != 1:
        return f"rc={rc} put={puts and puts[0]['body']} {err[:160]}"
    return ""


def c_date_iso_not_applied(d, scratch):
    """A data volta igual ou é erro: o executável relê e compara (aqui o ms vai certo e volta certo)."""
    with Fake() as f:
        rc, out, err = run(d, f, "item.update", "p0000001", "--due", "2026-11-10")
        puts = reqs(f, "PUT")
    want = 1794312000000   # 2026-11-10T12:00:00Z (data sem hora = meio-dia UTC)
    if rc != 0 or not puts or puts[0]["body"].get("due_date") != want or puts[0]["body"].get("due_date_time") is not True:
        return f"rc={rc} put={puts and puts[0]['body']} {err[:160]}"
    if out["due_date_iso"] != "2026-11-10T12:00:00Z":
        return f"due_date_iso={out['due_date_iso']}"
    return ""


def c_estimate_time(d, scratch):
    with Fake() as f:
        rc, out, err = run(d, f, "estimate.time", "p0000001", "45")
        puts = reqs(f, "PUT")
    return "" if rc == 0 and puts and puts[0]["body"] == {"time_estimate": 2700000} else f"rc={rc} {puts and puts[0]['body']} {err[:120]}"


def c_label_set(d, scratch):
    with Fake() as f:
        rc, out, err = run(d, f, "label.set", "p0000001", "--add", "urgente", "--remove", "a")
        ops = [(r["method"], r["path"].rsplit("/", 1)[1]) for r in f.store["log"] if "/tag/" in r["path"]]
        tag_bodies = [r for r in f.store["log"] if r["method"] in ("PUT", "POST") and isinstance(r["body"], dict) and "tags" in r["body"]]
    if rc != 0 or ops != [("POST", "urgente"), ("DELETE", "a")] or tag_bodies or (out or {}).get("tags") != ["urgente"]:
        return f"rc={rc} ops={ops} tags_no_corpo={len(tag_bodies)} out={out and out.get('tags')} {err[:160]}"
    return ""


def c_update_tags_refused(d, scratch):
    with Fake() as f:
        rc, _, err = run(d, f, "item.update", "p0000001", "--title", "Novo nome", "--tags", "x")
        n = len(f.store["log"])
    return "" if rc == 2 and n == 0 and "label.set" in err else f"rc={rc} requisições={n} {err[:160]}"


def c_status_synonym(d, scratch):
    with Fake() as f:
        rc, out, err = run(d, f, "status.transition", "p0000001", "review")
        puts = reqs(f, "PUT")
    if rc != 0 or not puts or puts[0]["body"] != {"status": "pull request"} or out["status"]["status"] != "pull request":
        return f"rc={rc} put={puts and puts[0]['body']} {err[:160]}"
    return ""


def c_status_unknown(d, scratch):
    with Fake() as f:
        rc, _, err = run(d, f, "status.transition", "p0000001", "homologação")
        puts = reqs(f, "PUT")
    return "" if rc == 1 and not puts and "Disponíveis: to do | in progress | pull request | complete" in err else f"rc={rc} puts={len(puts)} {err[:200]}"


def c_comment_add_visual(d, scratch):
    bf = os.path.join(scratch, "corpo.txt")
    with open(bf, "w", encoding="utf-8") as fh:
        fh.write("◆ Feito\n  ∟ CORPO_DO_ARQUIVO_7f3 com acento: ação\n")
    with Fake() as f:
        rc, out, err = run(d, f, "comment.add", "p0000001", "--visual", "Progresso", "--body-file", bf)
        posts = reqs(f, "POST", "task/p0000001/comment")
    if rc != 0 or not posts:
        return f"rc={rc} {err[:160]}"
    b = posts[0]["body"]
    t = b.get("comment_text", "")
    ok = (t.startswith("▶ Progresso\n━") and "CORPO_DO_ARQUIVO_7f3 com acento: ação" in t and "\n🕐 " in t
          and b.get("notify_all") is False and out["id"].startswith("n"))
    return "" if ok else f"corpo={t[:120]!r} notify_all={b.get('notify_all')!r}"


def c_comment_add_plain_and_flags(d, scratch):
    with Fake() as f:
        rc1, _, err1 = run(d, f, "comment.add", "p0000001", "--corpo", "x", "texto real")
        n1 = len(f.store["log"])
        rc2, _, _ = run(d, f, "comment.add", "p0000001", "--- régua no topo")
        posts = reqs(f, "POST", "task/p0000001/comment")
    if rc1 != 2 or n1 != 0 or "opção desconhecida: --corpo" not in err1:
        return f"flag desconhecida: rc={rc1} requisições={n1} {err1[:120]}"
    if rc2 != 0 or not posts or posts[0]["body"]["comment_text"] != "--- régua no topo":
        return f"corpo com traços: rc={rc2} {posts and posts[0]['body']}"
    return ""


def c_comment_list(d, scratch):
    with Fake() as f:
        rc, out, err = run(d, f, "comment.list", "p0000001")
        gets = [r["query"] for r in reqs(f, "GET", "task/p0000001/comment")]
    ids = [c["id"] for c in (out or {}).get("comments", [])]
    if rc != 0 or ids != ["c1", "c2", "c3"] or len(gets) < 2 or gets[1].get("start_id") != ["c2"]:
        return f"rc={rc} ids={ids} páginas={gets} {err[:120]}"
    return ""


def c_search_local_filter(d, scratch):
    with Fake() as f:
        rc, out, err = run(d, f, "search.query", "INTEGRAÇÃO", "--team", "W1")
        pages = [r["query"].get("page") for r in reqs(f, "GET", "team/W1/task")]
    hits = [t["id"] for t in (out or {}).get("tasks", [])]
    if rc != 0 or hits != ["x0000003"] or pages != [["0"], ["1"]] or out["scanned"] != 4:
        return f"rc={rc} hits={hits} páginas={pages} {err[:160]}"
    return ""


def c_search_workspace_from_team(d, scratch):
    with Fake() as f:
        rc, out, err = run(d, f, "search.query", "nada-casa-isto")
    return "" if rc == 0 and out["workspace"] == "W1" and out["count"] == 0 else f"rc={rc} {err[:160]}"


def c_attachment_list(d, scratch):
    with Fake() as f:
        rc, out, err = run(d, f, "attachment.list", "p0000001")
    return "" if rc == 0 and out["count"] == 1 and out["attachments"][0]["downloadable"] is False else f"rc={rc} {err[:160]}"


def c_project(d, scratch):
    with Fake() as f:
        rc, out, err = run(d, f, "project.list", "--team", "W1")
        rc2, out2, _ = run(d, f, "project.read", "L1")
    sp = (out or {}).get("spaces", [{}])[0]
    if rc != 0 or sp.get("folders", [{}])[0].get("lists") != [{"id": "L1", "name": "Sprint"}] or sp.get("lists") != [{"id": "L9", "name": "Solta"}]:
        return f"project.list rc={rc} {sp} {err[:120]}"
    if rc2 != 0 or out2["statuses"] != ["to do", "in progress", "pull request", "complete"]:
        return f"project.read rc={rc2} {out2}"
    return ""


def c_id_validate(d, scratch):
    rc1, _, _ = run(d, None, "id.validate", "86abc1234")
    rc2, _, _ = run(d, None, "id.validate", "ABC-12")
    rc3, _, _ = run(d, None, "id.validate", "../etc")
    return "" if (rc1, rc2, rc3) == (0, 0, 1) else f"rc={(rc1, rc2, rc3)}"


def c_http_error(d, scratch):
    with Fake() as f:
        f.store["force"] = (500, {"err": "boom", "ECODE": "X"})
        rc, out, err = run(d, f, "item.read", "p0000001")
    return "" if rc == 1 and out is None and "HTTP 500" in err else f"rc={rc} {err[:160]}"


def c_err_in_200(d, scratch):
    with Fake() as f:
        # com cara de task válida: só a leitura do `err` separa erro de sucesso
        f.store["force"] = (200, {"err": "Team not authorized", "ECODE": "OAUTH_027", "id": "p0000001", "name": "x"})
        rc, out, err = run(d, f, "item.read", "p0000001", "--lean")
    return "" if rc == 1 and out is None and "Team not authorized" in err else f"rc={rc} {err[:160]}"


def c_unimplemented_verb(d, scratch):
    rc, _, err = run(d, None, "attachment.read", "p0000001", "1")
    return "" if rc == 2 and "não implementa 'attachment.read'" in err else f"rc={rc} {err[:160]}"


CASES = [
    ("capabilities", "tm.sh --capabilities local, sem chave, igual ao clickup.py, com o mínimo pedido", c_capabilities),
    ("token_missing", "CLICKUP_API_TOKEN ausente → rc 2 sem rede", c_token_missing),
    ("auth_no_bearer", "o token vai no Authorization SEM Bearer", c_auth_no_bearer),
    ("read_full", "item.read completo: comentários de todas as páginas em ordem, respostas, subtasks recursivas, anexos, untrusted", c_read_full),
    ("read_subtask", "hierarchy.context de subtask: mãe COMPLETA e irmãs com estado, sem ela mesma", c_read_subtask),
    ("subtask_list", "hierarchy.subtask_list pede include_subtasks=true (o legado devolve sem o campo)", c_subtask_list),
    ("create", "item.create: markdown_content, priority inteiro, datas em ms com a flag, tags FORA do corpo e relidas", c_create),
    ("subtask_create", "hierarchy.subtask_create manda parent e herda a List da mãe", c_subtask_create),
    ("priority_string", "priority string recusada ANTES da rede (rc 2, zero requisições)", c_priority_string_refused),
    ("priority_set", "priority.set manda INTEIRO e confere o que voltou", c_priority_set),
    ("date_ms_flag", "data sem hora vira ms de 12:00 UTC com due_date_time e volta igual", c_date_iso_not_applied),
    ("estimate_time", "estimate.time em ms (minutos × 60000)", c_estimate_time),
    ("label_set", "label.set só por POST/DELETE /task/{id}/tag/{nome}, nunca no corpo, e relê", c_label_set),
    ("update_tags", "item.update --tags recusado antes da rede, apontando o label.set", c_update_tags_refused),
    ("status_synonym", "status.transition resolve 'review' para o nome da List ('pull request')", c_status_synonym),
    ("status_unknown", "status sem equivalente na List → rc 1 com os disponíveis, sem PUT", c_status_unknown),
    ("comment_visual", "comment.add --visual: header ▶ + separador ━ + corpo do arquivo + 🕐 timestamp, notify_all false", c_comment_add_visual),
    ("comment_flags", "comment.add: flag desconhecida rc 2 antes da rede; corpo com traços é corpo", c_comment_add_plain_and_flags),
    ("comment_list", "comment.list segue start/start_id até a última página", c_comment_list),
    ("search_filter", "search.query filtra LOCAL (o endpoint ignora o texto) e percorre as páginas", c_search_local_filter),
    ("search_workspace", "search.query sem workspace resolve o único /team", c_search_workspace_from_team),
    ("attachment_list", "attachment.list lista os anexos da task, sem baixar", c_attachment_list),
    ("project", "project.list (spaces → folders → lists + soltas) e project.read com os status", c_project),
    ("id_validate", "id.validate: nativo e custom passam, lixo reprova", c_id_validate),
    ("http_error", "HTTP 500 → rc 1, nada em stdout", c_http_error),
    ("err_in_200", "corpo com `err` e status 200 → rc 1, nunca sucesso", c_err_in_200),
    ("unimplemented", "verbo fora do executável (attachment.read) → rc 2", c_unimplemented_verb),
]

# Cada mutante reverte UMA cura na CÓPIA do clickup.py e EXIGE o FAIL do caso nomeado.
MUTANTS = [
    ('headers = {"Authorization": token,', 'headers = {"Authorization": "Bearer " + token,', "auth_no_bearer"),
    ('params.update({"include_subtasks": "true",', 'params.update({"subtasks": "true",', "subtask_list"),
    ('params.update({"include_subtasks": "true",', 'params.update({"subtasks": "true",', "read_full"),
    ('        if len(page) < COMMENT_PAGE or not fresh:', '        if True:', "comment_list"),
    ('        if with_replies and v["reply_count"]:', '        if False:', "read_full"),
    ('            v["subtasks"], sub_trunc = _subtree(child, depth + 1, budget)', '            v["subtasks"], sub_trunc = [], False', "read_full"),
    ('        ctx["parent"] = _task_view(par)', '        ctx["parent"] = {"id": par["id"], "description": ""}', "read_subtask"),
    ('        body["markdown_content"] = o["description"]   # REQUEST', '        body["markdown_description"] = o["description"]   # REQUEST', "create"),
    ('        body["priority"] = _priority(o["priority"])\n    _date_fields(o, body)\n    if o.get("time-estimate"):',
     '        body["priority"] = str(o["priority"])\n    _date_fields(o, body)\n    if o.get("time-estimate"):', "create"),
    ('    p = _priority(args[1])           # string inválida', '    p = args[1]           # string inválida', "priority_string"),
    ('            body[key + "_time"] = True', '            pass', "create"),
    ('            body[key + "_time"] = True', '            pass', "date_ms_flag"),
    ('    created = api("POST", f"/list/{list_id}/task", None, body)', '    body["tags"] = tags\n    created = api("POST", f"/list/{list_id}/task", None, body)\n    tags = []', "create"),
    ('        api("POST", f"/task/{task_id}/tag/{urllib.parse.quote(name, safe=\'\')}")',
     '        api("PUT", f"/task/{task_id}", None, {"tags": [name]})', "label_set"),
    ('    if "tags" in o:\n        raise TmError(', '    if False:\n        raise TmError(', "update_tags"),
    ('    for syn in STATUS_SYNONYMS.get(ref.lower().replace(" ", "_").replace("-", "_"), []):', '    for syn in []:', "status_synonym"),
    ('    raise TmError(f"status \'{ref}\' não existe na List', '    return ref\n    raise TmError(f"status \'{ref}\' não existe na List', "status_unknown"),
    ('    if o.get("visual"):\n        body = _visual(o["visual"], body)', '    pass', "comment_visual"),
    ('            if k not in ("body-file", "visual", "notify-all"):', '            if False:', "comment_flags"),
    ('            where = "name" if needle in name else ("description" if needle in desc else None)', '            where = "name"', "search_filter"),
    ('        page += 1\n', '        break\n', "search_filter"),
    ('    if isinstance(payload, dict) and payload.get("err"):', '    if False:', "err_in_200"),
]


def copy_tree(dst):
    os.makedirs(os.path.join(dst, "adapters"))
    for n in ("tm.sh", "env-check.sh"):
        shutil.copy2(os.path.join(TM_DIR, n), os.path.join(dst, n))
    shutil.copy2(os.path.join(TM_DIR, "adapters/clickup.py"), os.path.join(dst, "adapters/clickup.py"))


def main():
    fails, oks = [], 0
    by_id = {c[0]: c for c in CASES}
    with tempfile.TemporaryDirectory(prefix="tm-clickup-bench-") as tmp:
        scratch = os.path.join(tmp, "scratch")
        os.makedirs(scratch)
        # 1. casos, contra a árvore real
        for cid, desc, fn in CASES:
            why = fn(TM_DIR, scratch)
            if why:
                fails.append(f"({cid}) {desc}: {why}")
            else:
                oks += 1
                print(f"ok   ({cid}) {desc}")
        # 2. cópia LIMPA verde no mesmo arranjo dos mutantes
        cp = os.path.join(tmp, "copy")
        copy_tree(cp)
        target_cases = sorted({m[2] for m in MUTANTS})
        clean_bad = [f"({c}) {by_id[c][2](cp, scratch)}" for c in target_cases if by_id[c][2](cp, scratch)]
        if clean_bad:
            fails.append("cópia limpa NÃO ficou verde no arranjo dos mutantes — nenhum mutante conta: " + "; ".join(clean_bad))
        else:
            print(f"ok   cópia limpa verde nos {len(target_cases)} casos-alvo dos mutantes")
        # 3. mutantes
        killed = 0
        src = open(os.path.join(TM_DIR, "adapters/clickup.py"), encoding="utf-8").read()
        for old, new, want in MUTANTS:
            if src.count(old) != 1:
                fails.append(f"mutante não aplicou (âncora {src.count(old)}×): {old[:60]!r} → ({want})")
                continue
            with open(os.path.join(cp, "adapters/clickup.py"), "w", encoding="utf-8") as fh:
                fh.write(src.replace(old, new))
            why = by_id[want][2](cp, scratch)
            if why and not clean_bad:
                killed += 1
                anchor = " ".join(old.split())[:60]
                print(f"ok   mutante morde → ({want}) reprova [{anchor}]: {' '.join(why.split())[:110]}")
            elif not clean_bad:
                fails.append(f"mutante NÃO morde: ({want}) segue verde com a cura revertida: {' '.join(old.split())[:70]}")
        with open(os.path.join(cp, "adapters/clickup.py"), "w", encoding="utf-8") as fh:
            fh.write(src)
    if fails:
        print("\nFALHA (%d):\n- %s" % (len(fails), "\n- ".join(fails)))
    print(f"\ntask-manager-clickup-bench: {oks}/{len(CASES)} caso(s) verdes; {killed}/{len(MUTANTS)} mutante(s) mordem; "
          f"cópia limpa {'verde' if not clean_bad else 'VERMELHA'}")
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
