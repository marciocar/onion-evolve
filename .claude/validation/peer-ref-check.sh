#!/usr/bin/env bash
# peer-ref-check.sh — antes de CITAR uma ref ou um selo do par, confere que ela existe na origin/main DELE.
#
# ═══ POR QUE EXISTE (2026-10-25) ═══
# A curadoria auditou 114 mensagens entre sessões (53 recebidas, 61 enviadas, codificadas por um agente separado
# pelo codebook pré-registrado): 97 afirmações checáveis, 54 conferidas, e 22 AGIDAS SEM CONFERÊNCIA — entre elas
# selos citados antes de existirem na main do par. De tudo o que o estudo propôs, só esta peça passou no critério
# de recorrência medida (2 ou mais); o resto ficou doutrina (D_PROTOCOLO_ENTRE_SESSOES_COSTURA_PEER_REF_CHECK_1025,
# em docs/onion/graph/sinais-de-campo-2026-09.kg.yaml).
# É a COSTURA do `integrity.dangling-external` do kg-ssot: aquele confere a ponta `<caminho>#<id>` só contra o
# corpus LOCAL; o que a sessão cita do par mora no repo do par, e lá ninguém conferia. O comando de referência é
# o que a sessão já fazia à mão (`git show origin/main:<caminho>`, `git merge-base --is-ancestor`), com o rc
# trocando a prosa: quem consome lê o rc, nunca a frase.
#
# O nó é lido pelo PARSER DO PRODUTO (`kg_query.py --id`, id exato), nunca por grep: `C_X` não pode casar
# `C_X_2`. Sem o produto ao lado, PyYAML; sem nenhum dos dois, NÃO MEDIU (rc 2), nunca "existe".
#
# Uso : bash .claude/validation/peer-ref-check.sh <repo-do-par> <ref>
#       <repo-do-par> = caminho do clone, OU o NOME do par (1º uso real, 2026-10-25: a sessão escreve o nome, não o
#       caminho). O nome resolve, nesta ordem: (1) `local_path` do membro `id: <nome>` no members.yaml deste repo
#       (core e hub o têm); (2) o diretório irmão `<pai deste repo>/<nome>`, aceito SÓ se a URL da origin dele
#       termina em `/<nome>` ou `/<nome>.git` — palpite de diretório sem essa prova seria conferir o repo errado.
#       Nada resolve → NÃO MEDIU, pedindo o caminho.
#       <ref> = <caminho>.kg.yaml#<ID> (ou .kg.json#<ID)  → o arquivo existe na origin/main E o nó `id: <ID>` está nele
#             = <caminho>                                  → o arquivo existe na origin/main
#             = <sha> (7 a 40 hex)                         → é commit E é ancestral da origin/main
# Antes de medir: `git -C <par> fetch -q origin` (a origin/main de ontem não é a de agora).
# Saída: uma linha em pt-BR, com o sha da origin/main medida.
# Exit: 0 = existe / é ancestral · 1 = não existe / não é ancestral (a linha diz qual) ·
#       2 = NÃO MEDIU (o par não é repo git, o fetch falhou, origin/main ausente, argumento malformado,
#           grafo ilegível ou sem parser)
# Env : ONION_KG_QUERY — caminho do kg_query.py (default: o vendor kg-ssot deste repo).
#       ONION_MEMBERS_YAML — o registro de membros (default: docs/evolution/federation/members.yaml deste repo).
set -euo pipefail

_out() { printf 'peer-ref-check: %s\n' "$*"; }
_unmeasured() { _out "NÃO MEDIU — $*"; exit 2; }

[ "$#" -eq 2 ] || _unmeasured "uso: peer-ref-check.sh <repo-do-par> <ref> (recebi $# argumento(s))"
PAR="$1"; REF="$2"
[ -n "${PAR}" ] && [ -n "${REF}" ] || _unmeasured "argumento vazio"
case "${REF}" in -*|*[[:space:]]*|*[[:cntrl:]]*) _unmeasured "ref malformada: começa com '-' ou tem espaço/controle" ;; esac

HERE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
if [ ! -d "${PAR}" ] && [[ "${PAR}" =~ ^[A-Za-z0-9._-]+$ ]]; then
  NAME="${PAR}"; PAR=""
  MEM="${ONION_MEMBERS_YAML:-${HERE_ROOT}/docs/evolution/federation/members.yaml}"
  if [ -f "${MEM}" ] && command -v python3 >/dev/null 2>&1; then
    PAR="$(python3 -I -B - "${MEM}" "${NAME}" <<'PY' 2>/dev/null || true
import sys
try:
    import yaml
    d = yaml.safe_load(open(sys.argv[1], encoding="utf-8")) or {}
except Exception:
    sys.exit(0)
for m in (d.get("members") or []) if isinstance(d, dict) else []:
    if isinstance(m, dict) and m.get("id") == sys.argv[2] and isinstance(m.get("local_path"), str):
        print(m["local_path"]); break
PY
)"
    [ -z "${PAR}" ] || [ -d "${PAR}" ] || PAR=""
  fi
  if [ -z "${PAR}" ]; then
    SIB="$(dirname "${HERE_ROOT}")/${NAME}"
    URL="$(git -C "${SIB}" remote get-url origin 2>/dev/null || true)"
    case "${URL}" in */"${NAME}"|*/"${NAME}".git|*:"${NAME}"|*:"${NAME}".git) PAR="${SIB}" ;; esac
  fi
  [ -n "${PAR}" ] || _unmeasured "o nome '${NAME}' não resolve (nem no members.yaml, nem num irmão cuja origin seja ${NAME}): passe o caminho do clone"
fi
git -C "${PAR}" rev-parse --git-dir >/dev/null 2>&1 || _unmeasured "o par não é repo git: ${PAR}"
GIT_TERMINAL_PROMPT=0 git -C "${PAR}" fetch -q origin >/dev/null 2>&1 || _unmeasured "o fetch da origin do par falhou (${PAR})"
MAIN="$(git -C "${PAR}" rev-parse --verify -q 'refs/remotes/origin/main^{commit}' 2>/dev/null)" \
  || _unmeasured "o par não tem origin/main depois do fetch (${PAR})"
AT="na origin/main do par @ ${MAIN}"

# ── <sha> ──────────────────────────────────────────────────────────────────────────────────────
if [[ "${REF}" =~ ^[0-9a-fA-F]{7,40}$ ]]; then
  REF="$(printf '%s' "${REF}" | tr 'A-F' 'a-f')"
  if ! full="$(git -C "${PAR}" rev-parse --verify -q "${REF}^{commit}" 2>/dev/null)"; then
    # prefixo AMBÍGUO (dois objetos começam assim) não é "não existe": é não mediu. Conta-se pelo
    # --disambiguate (rc e linhas), nunca pela prosa do erro do git.
    namb="$(git -C "${PAR}" rev-parse --disambiguate="${REF}" 2>/dev/null | wc -l)" || namb=0
    [ "${namb}" -le 1 ] || _unmeasured "o prefixo ${REF} é ambíguo no par (${namb} objetos); cite mais dígitos"
    _out "NÃO EXISTE — ${REF} não é commit conhecido no par (${AT})"; exit 1
  fi
  arc=0; git -C "${PAR}" merge-base --is-ancestor "${full}" "${MAIN}" 2>/dev/null || arc=$?
  case "${arc}" in
    0) _out "ANCESTRAL — ${REF} (${full}) está ${AT}"; exit 0 ;;
    1) _out "NÃO ANCESTRAL — ${REF} (${full}) é commit do par mas NÃO está ${AT} (só noutra branch, ou ainda não entrou)"; exit 1 ;;
    *) _unmeasured "merge-base --is-ancestor saiu rc=${arc} para ${REF}" ;;
  esac
fi

# ── <caminho>[#<ID>] ───────────────────────────────────────────────────────────────────────────
ID=""; P="${REF}"
if [[ "${REF}" == *"#"* ]]; then
  P="${REF%%#*}"; ID="${REF#*#}"
  [ -n "${P}" ] && [ -n "${ID}" ] || _unmeasured "ref malformada: '${REF}' (esperado <caminho>.kg.yaml#<ID>)"
  [[ "${ID}" =~ ^[A-Za-z0-9_.:-]+$ ]] || _unmeasured "id malformado: '${ID}'"
  case "${P}" in *.kg.yaml|*.kg.json) ;; *) _unmeasured "'#<ID>' só vale em grafo (.kg.yaml/.kg.json): '${P}'" ;; esac
fi
while [[ "${P}" == ./* ]]; do P="${P#./}"; done
case "${P}" in /*|""|*/../*|../*|*/..) _unmeasured "caminho malformado: '${P}' (relativo à raiz do par, sem '..')" ;; esac

typ="$(git -C "${PAR}" cat-file -t "${MAIN}:${P}" 2>/dev/null)" || typ=""
case "${typ}" in
  blob) ;;
  "") _out "NÃO EXISTE — o arquivo ${P} não está ${AT}"; exit 1 ;;
  *) _out "NÃO EXISTE — ${P} ${AT} é ${typ}, não arquivo"; exit 1 ;;
esac
[ -n "${ID}" ] || { _out "EXISTE — o arquivo ${P} está ${AT}"; exit 0; }

command -v python3 >/dev/null 2>&1 || _unmeasured "python3 ausente: sem parser para ler o nó"
TMP="$(mktemp -d)"; trap 'rm -rf "${TMP}"' EXIT
G="${TMP}/peer.kg.${P##*.kg.}"   # a extensão vai junto: o parser escolhe YAML ou JSON por ela
git -C "${PAR}" show "${MAIN}:${P}" > "${G}" 2>/dev/null || _unmeasured "não consegui ler ${P} da origin/main do par"

SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
KQ="${ONION_KG_QUERY:-${SELF}/vendor/kg-ssot/tools/kg_query.py}"
vrc=0
if [ -f "${KQ}" ]; then
  # o PRODUTO lê: rc dele, JSON dele; `unreadable` não vazio = grafo ilegível = não mediu
  python3 -I -B "${KQ}" --id "${ID}" --format json "${G}" > "${TMP}/q.json" 2>/dev/null || _unmeasured "kg_query.py falhou ao ler ${P}"
  python3 -I -B - "${TMP}/q.json" "${ID}" <<'PY' || vrc=$?
import json, sys
try:
    d = json.load(open(sys.argv[1], encoding="utf-8"))
except (OSError, ValueError):
    sys.exit(2)
if d.get("unreadable"):
    sys.exit(2)
ids = [n.get("id") for n in d.get("nodes", []) if isinstance(n, dict)]
sys.exit(0 if sys.argv[2] in ids else 1)
PY
  VIA="kg_query.py"
else
  python3 -I -B - "${G}" "${ID}" <<'PY' || vrc=$?
import json, sys
p, want = sys.argv[1], sys.argv[2]
try:
    if p.endswith(".json"):
        d = json.load(open(p, encoding="utf-8"))
    else:
        import yaml
        d = yaml.safe_load(open(p, encoding="utf-8"))
except Exception:
    sys.exit(2)
nodes = d.get("nodes") if isinstance(d, dict) else None
if not isinstance(nodes, list):
    sys.exit(2)
sys.exit(0 if any(isinstance(n, dict) and n.get("id") == want for n in nodes) else 1)
PY
  VIA="PyYAML"
fi
case "${vrc}" in
  0) _out "EXISTE — o nó ${ID} está em ${P} ${AT} (lido por ${VIA})"; exit 0 ;;
  1) _out "NÃO EXISTE — o arquivo ${P} está ${AT}, mas o nó ${ID} não (id exato, lido por ${VIA})"; exit 1 ;;
  *) _unmeasured "o grafo ${P} ${AT} está ilegível para ${VIA} (ou PyYAML ausente)" ;;
esac
