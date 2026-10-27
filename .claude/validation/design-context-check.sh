#!/usr/bin/env bash
# ===========================================================================
# design-context-check.sh — a guarda do GRAFO do design-context: locator de token e ligação do brief.
#
# POR QUE EXISTE (defeito medido em 2026-10-27, laboratório da emenda F do estudo da curadoria
# design-setup-2026-10, um repo git por caso, saída literal em evidence/lab-graph/ de lá): o design-context
# passou a ter grafo próprio (docs/design-context/design-context.kg.yaml, o 1º contexto com grafo), ligado ao
# business-context e ao technical-context por external_edges. O gate do contrato já pega a ligação QUEBRADA
# (integrity.dangling-external, caso 2) e o arquivo de tokens que some (integrity.trace-target-missing, caso 4),
# SEM regra nova. Dois buracos sobraram, e só um checador da vertical os vê:
#   · o token que some de DENTRO do JSON, citado só pelo grafo (caso 5: kg_validate 0, kg_trace 0, lint de
#     tokens 0), e o locator que aponta um GRUPO em vez de um token (caso 9). O 1º passou ao produto na
#     kg-ssot 4.35.0 (kg_trace check segue o JSON Pointer; REGRA 55): aqui fica só o GRUPO, a forma DTCG;
#   · o brief SEM ligação nenhuma ao business-context (caso 6): qualquer aresta interna o tirava de órfão.
# E a deriva medida pelo kg-ssot nos contextos dele (disciplina sem mecanismo): 2 de 6 ids citados no
# design-context não resolviam.
#
# 1º CICLO = AVISO: os achados saem SOFT, porque os briefs dos adotantes ainda não migraram para grafo.
#   --strict os sobe para HARD (para quando os dois adotantes migrarem).
# O contraste NÃO é daqui: segue no lint-design-tokens.sh. O checador de PROJEÇÃO (o .md cita ids que existem
#   no grafo do projection_of) é do kg-ssot (kg_trace.py projection, 4.35.0) e roda na REGRA 112, kg-projection.sh.
# Toda a lógica vive em design-context-check.py, isolado (só Python + PyYAML); a parte genérica do locator já
#   migrou para o kg_trace do kg-ssot (4.35.0).
#
# Uso:  bash .claude/validation/design-context-check.sh [<raiz>] [--graph <arquivo>] [--format tsv|human] [--strict]
#   A pasta do design e a do business se resolvem por .claude/utils/scope/resolve-context-dir.sh (declaração
#   explícita vence convenção); sem o helper, os defaults docs/<dim>-context.
# Exit: 0 nada a acusar · 1 algum achado · 2 NÃO PUDE JULGAR (python3 ou PyYAML ausente, grafo ilegível,
#       declaração de contexto inválida). rc 2 nunca é verde.
# Exercitado por lint-selftest.sh (run_design_context_selftests); registrado no lint-artifacts.sh (REGRA 111).
# ===========================================================================
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT=""; PASS=()
while [ "$#" -gt 0 ]; do
  case "$1" in
    --graph)  [ "$#" -ge 2 ] || { echo "design-context-check: --graph pede um arquivo" >&2; exit 2; }; PASS+=(--graph "$2"); shift 2 ;;
    --format) [ "$#" -ge 2 ] || { echo "design-context-check: --format pede tsv|human" >&2; exit 2; }; PASS+=(--format "$2"); shift 2 ;;
    --strict) PASS+=(--strict); shift ;;
    -h|--help) sed -n '2,32p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*) echo "design-context-check: opção desconhecida: $1" >&2; exit 2 ;;
    *) [ -z "${ROOT}" ] && ROOT="$1" || { echo "design-context-check: raiz repetida: $1" >&2; exit 2; }; shift ;;
  esac
done
[ -n "${ROOT}" ] || ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
[ -d "${ROOT}" ] || { echo "design-context-check: raiz inexistente: ${ROOT} — não pude julgar" >&2; exit 2; }
command -v python3 >/dev/null 2>&1 || { echo "design-context-check: python3 ausente — não pude julgar" >&2; exit 2; }
python3 -c 'import yaml' 2>/dev/null || { echo "design-context-check: PyYAML ausente — não pude julgar" >&2; exit 2; }

RESOLVER="${HERE}/../utils/scope/resolve-context-dir.sh"
_dir() {  # <dim> — a pasta do contexto; declaração inválida (rc 3 do resolver) é "não pude julgar"
  local d rc
  if [ -f "${RESOLVER}" ]; then
    d="$(bash "${RESOLVER}" "$1" --repo "${ROOT}" 2>/dev/null)"; rc=$?
    [ "${rc}" -eq 0 ] || { echo "design-context-check: o resolver de contexto recusou '$1' (rc=${rc}) — não pude julgar" >&2; return 2; }
    printf '%s' "${d}"
  else
    printf 'docs/%s-context' "$1"
  fi
}
DESIGN_DIR="$(_dir design)" || exit 2
BUSINESS_DIR="$(_dir business)" || exit 2
# A DELEGAÇÃO DO LOCATOR só vale se o juiz da REGRA 55 julga o locator: o mesmo kg_trace.py que o kg-trace.sh
# resolve (ONION_KG_TRACE, senão o vendor do alvo) e com o código integrity.trace-locator-missing (kg-ssot >= 4.35.0).
# Sem ele (adotante com vendor anterior), a vertical segue acusando o token ausente: delegar a quem não julga é calar
# (passada adversarial da adoção da 4.35.0, achado 2).
KT="${ONION_KG_TRACE:-${ROOT}/vendor/kg-ssot/tools/kg_trace.py}"
[ -f "${KT}" ] && LC_ALL=C command grep -q 'integrity.trace-locator-missing' "${KT}" 2>/dev/null && PASS+=(--delegate-locator)
exec python3 -I -B "${HERE}/design-context-check.py" --root "${ROOT}" --design-dir "${DESIGN_DIR}" --business-dir "${BUSINESS_DIR}" ${PASS[@]+"${PASS[@]}"}
