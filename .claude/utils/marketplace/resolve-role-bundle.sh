#!/usr/bin/env bash
# resolve-role-bundle.sh — resolve o bundle de verticais (plugins) de um papel.
# Lê o mapa role→bundle (roles.yaml) e imprime os verticais que o papel instala.
#
# Uso : resolve-role-bundle.sh <role> [--with-optional] [--tools] [--allowlist] [roles.yaml]
#         <role>          = source | hub | standalone | plugins | consumer | mini | distilled
#         --with-optional = inclui os verticais opcionais (default: só os base)
#         --tools         = emite os WORK_TOOLS do papel (comandos de commands/meta/), não os verticais
#                           (resolve roles.<role>.work_tools → a UNIÃO dos work_tool_sets nomeados; aceita
#                           um nome ou uma lista de nomes; none/tbd = vazio)
#         --allowlist     = emite a ALLOWLIST do papel (só o mini a declara): um caminho relativo a
#                           .claude/ por linha (diretório termina em `/`). Papel sem allowlist → vazio.
# Saída: um vertical (ou tool, ou caminho) por linha (ordenado). Papel desconhecido → exit 2. Vazio → ok.
#
# Determinístico. Consome roles.yaml (SSOT do escopo por papel). Não confundir com o trust model.
# ⚠️ `work_tools` virou LISTA em 2026-10-10 (F2 das portas, SAC-91): a matriz separou `full` de
# `meta_factory`, `federation` e `adoption`, e um papel recebe a união dos conjuntos que nomeia. A forma
# escalar (`work_tools: full`) segue aceita, para um roles.yaml antigo vendorizado num adotante.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROLE="${1:-}"
WITH_OPT=0
MODE="verticals"
ROLES="${SCRIPT_DIR}/roles.yaml"
shift || true
for arg in "$@"; do
  case "${arg}" in
    --with-optional) WITH_OPT=1 ;;
    --tools) MODE="tools" ;;
    --allowlist) MODE="allowlist" ;;
    *) [ -f "${arg}" ] && ROLES="${arg}" ;;
  esac
done

[ -n "${ROLE}" ] || { echo "ERRO: uso: resolve-role-bundle.sh <role> [--with-optional|--tools|--allowlist]" >&2; exit 2; }
[ -f "${ROLES}" ] || { echo "ERRO: roles.yaml não encontrado: ${ROLES}" >&2; exit 2; }
command -v python3 >/dev/null 2>&1 || { echo "ERRO: python3 necessário" >&2; exit 2; }

python3 - "${ROLES}" "${ROLE}" "${WITH_OPT}" "${MODE}" <<'PY'
import sys, yaml
roles_file, role, with_opt, mode = sys.argv[1], sys.argv[2], sys.argv[3] == "1", sys.argv[4]
d = yaml.safe_load(open(roles_file)) or {}
roles = d.get("roles") or {}
if role not in roles:
    sys.stderr.write("ERRO: papel desconhecido: %s (validos: %s)\n" % (role, ", ".join(sorted(roles))))
    sys.exit(2)
r = roles[role] or {}
if mode == "tools":
    sets = d.get("work_tool_sets") or {}
    wt = r.get("work_tools")
    names = wt if isinstance(wt, list) else ([wt] if wt not in (None, "none", "tbd") else [])
    ts = []
    for n in names:
        if n in (None, "none", "tbd"):
            continue
        if n not in sets:
            sys.stderr.write("ERRO: papel %s nomeia work_tool_set inexistente: %s\n" % (role, n))
            sys.exit(2)
        ts += list(sets.get(n) or [])
    # legado: roles.yaml anterior a 2026-10-10 somava o conjunto `downstream` quando downstream: true
    if r.get("downstream") is True and "downstream" in sets and isinstance(wt, str):
        ts += list(sets.get("downstream") or [])
    for t in sorted(set(ts)):
        print(t)
    sys.exit(0)
if mode == "allowlist":
    al = r.get("allowlist") or {}
    out = []
    for key in ("commands", "agents", "skills", "support"):
        out += list(al.get(key) or [])
    for p in sorted(set(out)):
        print(p)
    sys.exit(0)
vs = list(r.get("base") or [])
if with_opt:
    vs += list(r.get("optional") or [])
for v in sorted(set(vs)):
    print(v)
PY
