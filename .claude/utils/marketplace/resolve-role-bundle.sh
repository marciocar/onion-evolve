#!/usr/bin/env bash
# resolve-role-bundle.sh — resolve o bundle de verticais (plugins) de um papel.
# Lê o mapa role→bundle (roles.yaml) e imprime os verticais que o papel instala.
#
# Uso : resolve-role-bundle.sh <role> [--with-optional] [--tools] [roles.yaml]
#         <role>          = source | hub | standalone | consumer | distilled
#         --with-optional = inclui os verticais opcionais (default: só os base)
#         --tools         = emite os WORK_TOOLS do papel (comandos cross-cutting), não os verticais
#                           (resolve roles.<role>.work_tools → work_tool_sets.<nome>; + downstream se downstream:true)
# Saída: um vertical (ou tool, com --tools) por linha (ordenado). Papel desconhecido → exit 2. Vazio → ok.
#
# Determinístico. Consome roles.yaml (SSOT do escopo por papel). Não confundir com o trust model.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROLE="${1:-}"
WITH_OPT=0
TOOLS=0
ROLES="${SCRIPT_DIR}/roles.yaml"
shift || true
for arg in "$@"; do
  case "${arg}" in
    --with-optional) WITH_OPT=1 ;;
    --tools) TOOLS=1 ;;
    *) [ -f "${arg}" ] && ROLES="${arg}" ;;
  esac
done

[ -n "${ROLE}" ] || { echo "ERRO: uso: resolve-role-bundle.sh <role> [--with-optional]" >&2; exit 2; }
[ -f "${ROLES}" ] || { echo "ERRO: roles.yaml não encontrado: ${ROLES}" >&2; exit 2; }
command -v python3 >/dev/null 2>&1 || { echo "ERRO: python3 necessário" >&2; exit 2; }

python3 - "${ROLES}" "${ROLE}" "${WITH_OPT}" "${TOOLS}" <<'PY'
import sys, yaml
roles_file, role, with_opt, tools = sys.argv[1], sys.argv[2], sys.argv[3] == "1", sys.argv[4] == "1"
d = yaml.safe_load(open(roles_file)) or {}
roles = d.get("roles") or {}
if role not in roles:
    sys.stderr.write("ERRO: papel desconhecido: %s (validos: %s)\n" % (role, ", ".join(sorted(roles))))
    sys.exit(2)
r = roles[role] or {}
if tools:
    # WORK_TOOLS: resolve o nome do conjunto (full/minimal/...) e, se downstream:true, soma o downstream.
    sets = d.get("work_tool_sets") or {}
    setname = r.get("work_tools")
    ts = list(sets.get(setname) or []) if setname not in (None, "none", "tbd") else []
    if r.get("downstream") is True:
        ts += list(sets.get("downstream") or [])
    for t in sorted(set(ts)):
        print(t)
    sys.exit(0)
vs = list(r.get("base") or [])
if with_opt:
    vs += list(r.get("optional") or [])
for v in sorted(set(vs)):
    print(v)
PY
