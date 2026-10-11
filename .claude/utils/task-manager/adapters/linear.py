#!/usr/bin/env python3
# linear.py — adapter EXECUTÁVEL do Linear (GraphQL), chamado pelo dispatcher ../tm.sh.
#
# Por que existe (SAC-65, fatia 1, 2026-10-11): o adapter do Linear era só prosa (linear.md) e a sessão
# principal operava o Linear com scripts GraphQL avulsos FORA do repo — cada sessão reescrevia o mesmo
# cliente. Este arquivo é o cliente único: stdlib pura (urllib), sem dependência.
#
# Contrato com o tm.sh:
#   linear.py --capabilities            → um verbo por linha (local, sem rede, sem chave) — a REGRA 104 lê isto
#   linear.py <verbo> [args]            → JSON em stdout; erro em stderr (pt-BR); rc != 0 em erro
# Códigos: 0 ok · 1 erro do provedor (HTTP, GraphQL `errors`, entidade não achada) · 2 uso/configuração.
#
# Segredo: LINEAR_API_KEY vem do AMBIENTE; na falta, de TM_ENV_FILE lido COMO DADO (nunca executado,
# nunca impresso) — a mesma regra do env-check.sh. A chave vai só no cabeçalho Authorization.
# Team: LINEAR_TEAM_ID (não-segredo) → --team <KEY|id> → prefixo do identificador → team do projeto →
# único team do workspace. Nunca adivinha entre vários.
import json
import os
import re
import sys
import urllib.error
import urllib.request

ENDPOINT = "https://api.linear.app/graphql"
# Costura de teste da bancada: TM_LINEAR_ENDPOINT só é aceito em loopback (a chave nunca sai para outro host).
_override = os.environ.get("TM_LINEAR_ENDPOINT", "")
if re.match(r"^http://127\.0\.0\.1:\d+/", _override):
    ENDPOINT = _override
# Verbos que ESTE executável implementa (ids do vocabulário de interface.md §Capacidades).
# Só entra aqui o que foi exercitado ao vivo; a declaração (linear.capabilities.tsv) acompanha.
CAPABILITIES = [
    "item.create",
    "item.read",
    "item.update",
    "hierarchy.subtask_create",
    "hierarchy.subtask_list",
    "status.transition",
    "priority.set",
    "comment.add",
    "comment.list",
    "search.query",
    "project.list",
    "project.read",
    "id.validate",
]

ISSUE_FIELDS = """
  id identifier title description url priority priorityLabel createdAt updatedAt
  state { id name type }
  team { id key name }
  project { id name }
  parent { id identifier title }
  assignee { id name }
  labels { nodes { id name } }
"""

ID_RE = re.compile(r"^[A-Z][A-Z0-9]*-\d+$")
UUID_RE = re.compile(r"^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", re.I)


class TmError(Exception):
    def __init__(self, msg, rc=1):
        super().__init__(msg)
        self.rc = rc


def _file_value(path, key):
    """Valor de uma chave lido do arquivo COMO DADO (última ocorrência, `export ` e aspas fora)."""
    if not path or not os.path.isfile(path):
        return ""
    last = ""
    with open(path, encoding="utf-8", errors="replace") as fh:
        for raw in fh:
            line = raw.rstrip("\r\n")
            line = re.sub(r"^\s*export\s+", "", line)
            m = re.match(r"^\s*" + re.escape(key) + r"\s*=\s*(.*)$", line)
            if not m:
                continue
            v = m.group(1)
            if v.startswith('"'):
                v = v[1:].split('"', 1)[0]
            elif v.startswith("'"):
                v = v[1:].split("'", 1)[0]
            else:
                v = re.sub(r"\s+#.*$", "", v).strip()
            last = v
    return last


def _setting(key):
    return os.environ.get(key, "") or _file_value(os.environ.get("TM_ENV_FILE", ""), key)


def gql(query, variables=None):
    key = _setting("LINEAR_API_KEY")
    if not key:
        raise TmError("LINEAR_API_KEY ausente (nem no ambiente, nem no .env) — rode /meta:setup-integration", 2)
    body = json.dumps({"query": query, "variables": variables or {}}).encode("utf-8")
    req = urllib.request.Request(ENDPOINT, data=body, method="POST", headers={
        "Content-Type": "application/json",
        # chave pessoal do Linear vai SEM "Bearer" (Bearer é para token OAuth)
        "Authorization": key,
        "User-Agent": "onion-tm/1",
    })
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            payload = json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        detail = e.read().decode("utf-8", "replace")[:500]
        raise TmError(f"HTTP {e.code} do Linear: {detail}")
    except urllib.error.URLError as e:
        raise TmError(f"falha de rede falando com o Linear: {e.reason}")
    # GraphQL devolve 200 com `errors` — isso é ERRO, nunca sucesso parcial silencioso
    if payload.get("errors"):
        msgs = "; ".join(str(err.get("message", err)) for err in payload["errors"])
        raise TmError(f"GraphQL errors: {msgs}")
    return payload.get("data") or {}


# ── resolução ────────────────────────────────────────────────────────────────
def _issue(ident):
    if not (ID_RE.match(ident) or UUID_RE.match(ident)):
        raise TmError(f"id de issue inválido: '{ident}' (forma ABC-123 ou UUID)", 2)
    data = gql(f"query($id:String!){{ issue(id:$id){{ {ISSUE_FIELDS} children {{ nodes {{ id identifier title state {{ name type }} }} }} }} }}",
               {"id": ident})
    if not data.get("issue"):
        raise TmError(f"issue não encontrada: {ident}")
    return data["issue"]


def _teams():
    return gql("query{ teams(first:100){ nodes { id key name } } }")["teams"]["nodes"]


def _team_id(team_hint=None, ident=None, project=None):
    teams = None
    hint = team_hint or _setting("LINEAR_TEAM_ID")
    if hint:
        if UUID_RE.match(hint):
            return hint
        teams = _teams()
        for t in teams:
            if t["key"].lower() == hint.lower() or t["name"].lower() == hint.lower():
                return t["id"]
        raise TmError(f"team não encontrado: '{hint}'")
    if ident and ID_RE.match(ident):
        teams = teams or _teams()
        key = ident.split("-", 1)[0]
        for t in teams:
            if t["key"] == key:
                return t["id"]
    if project and project.get("teams", {}).get("nodes"):
        nodes = project["teams"]["nodes"]
        if len(nodes) == 1:
            return nodes[0]["id"]
    teams = teams or _teams()
    if len(teams) == 1:
        return teams[0]["id"]
    raise TmError("não sei em qual team criar: defina LINEAR_TEAM_ID ou passe --team <KEY>", 2)


def _project(ref):
    """Projeto por UUID ou nome exato (sem diferenciar caixa)."""
    if UUID_RE.match(ref):
        data = gql("query($id:String!){ project(id:$id){ id name state url teams { nodes { id key name } } } }", {"id": ref})
        if data.get("project"):
            return data["project"]
        raise TmError(f"projeto não encontrado: {ref}")
    nodes = gql("query($n:String!){ projects(first:50, filter:{ name:{ eqIgnoreCase:$n } }){ nodes { id name state url teams { nodes { id key name } } } } }",
                {"n": ref})["projects"]["nodes"]
    if len(nodes) == 1:
        return nodes[0]
    if not nodes:
        raise TmError(f"projeto não encontrado pelo nome: '{ref}' (veja tm.sh project.list)")
    raise TmError(f"nome de projeto ambíguo: '{ref}' casa {len(nodes)} projetos — passe o id")


def _state_id(team_id, ref):
    if UUID_RE.match(ref):
        return ref
    states = gql("query($t:ID!){ workflowStates(first:100, filter:{ team:{ id:{ eq:$t } } }){ nodes { id name type } } }",
                 {"t": team_id})["workflowStates"]["nodes"]
    for s in states:
        if s["name"].lower() == ref.lower():
            return s["id"]
    avail = ", ".join(f"{s['name']}({s['type']})" for s in states)
    raise TmError(f"estado '{ref}' não existe no team. Disponíveis: {avail}")


def _opts(args, known):
    """--chave valor; devolve (dict, posicionais). Chave desconhecida é erro de uso."""
    out, pos, i = {}, [], 0
    while i < len(args):
        a = args[i]
        if a.startswith("--"):
            k = a[2:]
            if k not in known:
                raise TmError(f"opção desconhecida: {a} (aceitas: {', '.join('--' + x for x in known)})", 2)
            if i + 1 >= len(args):
                raise TmError(f"{a} exige valor", 2)
            out[k] = args[i + 1]
            i += 2
        else:
            pos.append(a)
            i += 1
    return out, pos


def _need(pos, n, usage):
    if len(pos) < n:
        raise TmError(f"uso: tm.sh {usage}", 2)


def _priority(v):
    names = {"none": 0, "urgent": 1, "high": 2, "normal": 3, "medium": 3, "low": 4}
    if v.lower() in names:
        return names[v.lower()]
    if v.isdigit() and 0 <= int(v) <= 4:
        return int(v)
    raise TmError(f"prioridade inválida: '{v}' (0-4 ou none|urgent|high|normal|low)", 2)


def _issue_update(ident, patch):
    data = gql(f"mutation($id:String!,$in:IssueUpdateInput!){{ issueUpdate(id:$id, input:$in){{ success issue {{ {ISSUE_FIELDS} }} }} }}",
               {"id": ident, "in": patch})
    r = data.get("issueUpdate") or {}
    if not r.get("success"):
        raise TmError(f"issueUpdate não confirmou sucesso para {ident}")
    return r["issue"]


def _create(title, description=None, project=None, parent=None, team=None, priority=None, state=None):
    proj = _project(project) if project else None
    par = _issue(parent) if parent else None
    team_id = par["team"]["id"] if par else _team_id(team, project=proj)
    inp = {"title": title, "teamId": team_id}
    if description is not None:
        inp["description"] = description
    if proj:
        inp["projectId"] = proj["id"]
    elif par and par.get("project"):
        inp["projectId"] = par["project"]["id"]
    if par:
        inp["parentId"] = par["id"]
    if priority is not None:
        inp["priority"] = _priority(priority)
    if state:
        inp["stateId"] = _state_id(team_id, state)
    data = gql(f"mutation($in:IssueCreateInput!){{ issueCreate(input:$in){{ success issue {{ {ISSUE_FIELDS} }} }} }}", {"in": inp})
    r = data.get("issueCreate") or {}
    if not r.get("success"):
        raise TmError("issueCreate não confirmou sucesso")
    return r["issue"]


# ── verbos ──────────────────────────────────────────────────────────────────
def v_item_read(args):
    _need(args, 1, "item.read <ID>")
    return _issue(args[0])


def v_item_create(args):
    o, _ = _opts(args, ["title", "description", "project", "parent", "team", "priority", "state"])
    if not o.get("title"):
        raise TmError("uso: tm.sh item.create --title <t> [--description <d>] [--project <nome|id>] [--parent <ID>] [--team <KEY>] [--priority <p>] [--state <nome>]", 2)
    return _create(o["title"], o.get("description"), o.get("project"), o.get("parent"), o.get("team"), o.get("priority"), o.get("state"))


def v_item_update(args):
    o, pos = _opts(args, ["title", "description"])
    _need(pos, 1, "item.update <ID> [--title <t>] [--description <d>]")
    patch = {}
    if "title" in o:
        patch["title"] = o["title"]
    if "description" in o:
        patch["description"] = o["description"]
    if not patch:
        raise TmError("item.update sem campo: passe --title e/ou --description", 2)
    return _issue_update(_issue(pos[0])["id"], patch)


def v_subtask_create(args):
    o, pos = _opts(args, ["title", "description", "priority", "state"])
    _need(pos, 1, "hierarchy.subtask_create <ID-PAI> --title <t> [--description <d>]")
    if not o.get("title"):
        raise TmError("hierarchy.subtask_create exige --title", 2)
    return _create(o["title"], o.get("description"), parent=pos[0], priority=o.get("priority"), state=o.get("state"))


def v_subtask_list(args):
    _need(args, 1, "hierarchy.subtask_list <ID>")
    iss = _issue(args[0])
    kids = iss.get("children", {}).get("nodes", [])
    return {"parent": iss["identifier"], "count": len(kids), "subtasks": kids}


def v_status_transition(args):
    _need(args, 2, "status.transition <ID> <nomeDoEstado|stateId>")
    iss = _issue(args[0])
    return _issue_update(iss["id"], {"stateId": _state_id(iss["team"]["id"], args[1])})


def v_priority_set(args):
    _need(args, 2, "priority.set <ID> <0-4|none|urgent|high|normal|low>")
    iss = _issue(args[0])
    return _issue_update(iss["id"], {"priority": _priority(args[1])})


def v_comment_add(args):
    _need(args, 2, 'comment.add <ID> "<texto markdown>"')
    iss = _issue(args[0])
    data = gql("mutation($in:CommentCreateInput!){ commentCreate(input:$in){ success comment { id body createdAt url user { id name } } } }",
               {"in": {"issueId": iss["id"], "body": args[1]}})
    r = data.get("commentCreate") or {}
    if not r.get("success"):
        raise TmError("commentCreate não confirmou sucesso")
    return r["comment"]


def v_comment_list(args):
    _need(args, 1, "comment.list <ID>")
    iss = _issue(args[0])
    data = gql("query($id:String!){ issue(id:$id){ comments(first:100){ nodes { id body createdAt url user { id name } } } } }",
               {"id": iss["id"]})
    nodes = data["issue"]["comments"]["nodes"]
    return {"issue": iss["identifier"], "count": len(nodes), "comments": nodes}


def v_search_query(args):
    o, pos = _opts(args, ["limit", "team"])
    _need(pos, 1, 'search.query "<texto>" [--limit N] [--team KEY]')
    flt = {"title": {"containsIgnoreCase": pos[0]}}
    if o.get("team"):
        flt["team"] = {"id": {"eq": _team_id(o["team"])}}
    try:
        limit = int(o.get("limit", "25"))
    except ValueError:
        raise TmError(f"--limit exige inteiro: '{o.get('limit')}'", 2)
    data = gql("query($f:IssueFilter,$n:Int){ issues(filter:$f, first:$n){ nodes { id identifier title url state { name type } team { key } project { name } } } }",
               {"f": flt, "n": limit})
    nodes = data["issues"]["nodes"]
    return {"query": pos[0], "count": len(nodes), "issues": nodes}


def v_project_list(args):
    # No Linear o "projeto" da interface tem dois níveis: o TEAM (onde a issue mora, o que o linear.md
    # chama de getProjectList) e o PROJECT (agrupamento que o --project do item.create usa). Devolve os dois.
    data = gql("query{ teams(first:100){ nodes { id key name } } projects(first:100){ nodes { id name state url teams { nodes { key } } } } }")
    return {"teams": data["teams"]["nodes"], "projects": data["projects"]["nodes"]}


def v_project_read(args):
    _need(args, 1, "project.read <KEY-do-team|id|nome-do-projeto>")
    ref = args[0]
    for t in _teams():
        if ref in (t["id"], t["key"]):
            return {"kind": "team", **t}
    return {"kind": "project", **_project(ref)}


def v_id_validate(args):
    _need(args, 1, "id.validate <ID>")
    ok = bool(ID_RE.match(args[0]) or UUID_RE.match(args[0]))
    if not ok:
        print(json.dumps({"id": args[0], "valid": False}))
        raise SystemExit(1)
    return {"id": args[0], "valid": True}


VERBS = {
    "item.create": v_item_create,
    "item.read": v_item_read,
    "item.update": v_item_update,
    "hierarchy.subtask_create": v_subtask_create,
    "hierarchy.subtask_list": v_subtask_list,
    "status.transition": v_status_transition,
    "priority.set": v_priority_set,
    "comment.add": v_comment_add,
    "comment.list": v_comment_list,
    "search.query": v_search_query,
    "project.list": v_project_list,
    "project.read": v_project_read,
    "id.validate": v_id_validate,
}
assert sorted(VERBS) == sorted(CAPABILITIES), "CAPABILITIES e VERBS divergem"


def main(argv):
    if not argv or argv[0] in ("-h", "--help"):
        print("uso: linear.py --capabilities | <verbo> [args]   (verbos: " + ", ".join(CAPABILITIES) + ")", file=sys.stderr)
        return 2
    if argv[0] == "--capabilities":
        print("\n".join(CAPABILITIES))
        return 0
    fn = VERBS.get(argv[0])
    if not fn:
        print(f"tm: o executável do Linear não implementa '{argv[0]}' (veja tm.sh --capabilities)", file=sys.stderr)
        return 2
    try:
        result = fn(argv[1:])
    except TmError as e:
        print(f"tm (linear): {e}", file=sys.stderr)
        return e.rc
    except (KeyError, TypeError, ValueError) as e:
        # forma de resposta inesperada: erro do provedor nomeado, nunca traceback cru nem sucesso
        print(f"tm (linear): resposta do Linear em forma inesperada ({type(e).__name__}: {e})", file=sys.stderr)
        return 1
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
