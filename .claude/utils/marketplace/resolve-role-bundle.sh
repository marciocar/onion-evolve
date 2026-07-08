#!/usr/bin/env bash
# resolve-role-bundle.sh — resolve o bundle de verticais (plugins) de um papel.
# Lê o mapa role→bundle (roles.yaml) e imprime os verticais que o papel instala.
#
# Uso : resolve-role-bundle.sh <role> [--with-optional] [roles.yaml]
#         <role>          = source | hub | standalone | consumer | distilled
#         --with-optional = inclui os verticais opcionais (default: só os base)
# Saída: um vertical por linha (ordenado). Papel desconhecido → exit 2. Sem base → saída vazia (ok).
#
# Determinístico. Consome roles.yaml (SSOT do escopo por papel). Não confundir com o trust model.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROLE="${1:-}"
WITH_OPT=0
ROLES="${SCRIPT_DIR}/roles.yaml"
shift || true
for arg in "$@"; do
  case "${arg}" in
    --with-optional) WITH_OPT=1 ;;
    *) [ -f "${arg}" ] && ROLES="${arg}" ;;
  esac
done

[ -n "${ROLE}" ] || { echo "ERRO: uso: resolve-role-bundle.sh <role> [--with-optional]" >&2; exit 2; }
[ -f "${ROLES}" ] || { echo "ERRO: roles.yaml não encontrado: ${ROLES}" >&2; exit 2; }
command -v python3 >/dev/null 2>&1 || { echo "ERRO: python3 necessário" >&2; exit 2; }

python3 - "${ROLES}" "${ROLE}" "${WITH_OPT}" <<'PY'
import sys, yaml
roles_file, role, with_opt = sys.argv[1], sys.argv[2], sys.argv[3] == "1"
d = yaml.safe_load(open(roles_file)) or {}
roles = d.get("roles") or {}
if role not in roles:
    sys.stderr.write("ERRO: papel desconhecido: %s (validos: %s)\n" % (role, ", ".join(sorted(roles))))
    sys.exit(2)
r = roles[role] or {}
vs = list(r.get("base") or [])
if with_opt:
    vs += list(r.get("optional") or [])
for v in sorted(set(vs)):
    print(v)
PY
