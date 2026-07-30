#!/usr/bin/env bash
# =============================================================================
# scaffold-diagnose-store.sh — Scaffolda o STORE de um diagnóstico de engajamento
# (/meta:kg diagnose). Cria, para um <slug>:
#   docs/<área>/graph/<slug>.kg.yaml            — skeleton KG de 2 camadas (audit/domain)
#   docs/<área>/diagnose/<slug>/sources/        — material bruto (transcrições, docs)
#   docs/<área>/diagnose/<slug>/extracts/       — EXTRACT por fonte
#   docs/<área>/diagnose/<slug>/consolidated/   — fusão multi-fonte
#   docs/<área>/diagnose/<slug>/STATE.md        — ponteiro NEXT retomável (worklog-protocol)
#   docs/<área>/diagnose/<slug>/notes.md        — log append-only das PAUSAs
#
# É o gap MECÂNICO do modo diagnose: hoje o store é 100% manual (o LLM escreve o
# skeleton à mão). Automatiza SÓ o mecânico — a PAUSA (construir→pausar→perguntar→
# responder) segue gate humano DURO, fora deste helper. Não há modo que a pule.
#
# Uso  : scaffold-diagnose-store.sh <slug> [--title "Título"] [--area <área>] [--dir <repo>] [--dry-run]
#        --area default: onion (store em docs/onion/…); o adotante passa a própria área.
#
# Contrato de Segurança (herdado dos F1 do create-vertical): NEVER-CLOBBER (por
# arquivo), --dry-run (mostra o que criaria), idempotente. Determinístico,
# dependency-free. Coberto por lint-selftest.sh (run_scaffold_diagnose_selftests).
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TPL_DIR="${SCRIPT_DIR}/templates"

SLUG=""; TITLE=""; AREA="onion"; REPO_DIR="."; DRY=0
while [ $# -gt 0 ]; do
  case "$1" in
    --title) TITLE="${2:-}"; shift 2 ;;
    --area)  AREA="${2:-onion}"; shift 2 ;;
    --dir)   REPO_DIR="${2:-.}"; shift 2 ;;
    --dry-run) DRY=1; shift ;;
    -*) echo "flag desconhecida: $1" >&2; exit 2 ;;
    *) [ -z "${SLUG}" ] && SLUG="$1" || { echo "argumento extra: $1" >&2; exit 2; }; shift ;;
  esac
done

[ -n "${SLUG}" ] || { echo "uso: scaffold-diagnose-store.sh <slug> [--title T] [--area A] [--dir R] [--dry-run]" >&2; exit 2; }
case "${SLUG}" in
  *[!a-z0-9-]*|-*|*-|"") echo "erro: <slug> deve ser kebab-case: '${SLUG}'" >&2; exit 2 ;;
esac
case "${AREA}" in
  *[!a-z0-9-]*|-*|*-|"") echo "erro: --area deve ser kebab-case: '${AREA}'" >&2; exit 2 ;;
esac
for t in kg-2layer diagnose-state notes-stub; do
  [ -f "${TPL_DIR}/${t}.tpl" ] || { echo "erro: template ausente: ${TPL_DIR}/${t}.tpl" >&2; exit 2; }
done
if [ -z "${TITLE}" ]; then
  TITLE="$(printf '%s' "${SLUG}" | tr '-' ' ' | awk '{for(i=1;i<=NF;i++)$i=toupper(substr($i,1,1)) substr($i,2)}1')"
fi

# Data determinística: NÃO usar `date` no corpo testável — o selftest fixa via env.
DATE="${DIAGNOSE_SCAFFOLD_DATE:-$(date +%F)}"

GRAPH="${REPO_DIR}/docs/${AREA}/graph/${SLUG}.kg.yaml"
STORE="${REPO_DIR}/docs/${AREA}/diagnose/${SLUG}"

echo "=== scaffold diagnose store '${SLUG}' (área: ${AREA} · título: ${TITLE})$( [ "${DRY}" -eq 1 ] && echo ' [DRY-RUN]' ) em ${REPO_DIR} ==="

# render <template> <destino> — substitui {{SLUG}}/{{TITLE}}/{{DATE}}; never-clobber por-arquivo.
render() {
  local tpl="$1" dest="$2" rel; rel="${dest#${REPO_DIR}/}"
  if [ -e "${dest}" ]; then echo "  ⏭️  never-clobber: já existe → ${rel}"; return 0; fi
  local content; content="$(cat "${TPL_DIR}/${tpl}.tpl")"
  content="${content//\{\{SLUG\}\}/${SLUG}}"
  content="${content//\{\{TITLE\}\}/${TITLE}}"
  content="${content//\{\{DATE\}\}/${DATE}}"
  if [ "${DRY}" -eq 1 ]; then echo "  📝 [dry-run] escreveria → ${rel}"; return 0; fi
  mkdir -p "$(dirname "${dest}")"
  printf '%s\n' "${content}" > "${dest}"
  echo "  ✅ ${rel}"
}

# dirs do pipeline de ingestão (com .gitkeep p/ o git rastrear a estrutura vazia)
for sub in sources extracts consolidated; do
  d="${STORE}/${sub}"; keep="${d}/.gitkeep"
  if [ -e "${keep}" ]; then echo "  ⏭️  never-clobber: já existe → docs/${AREA}/diagnose/${SLUG}/${sub}/"; continue; fi
  if [ "${DRY}" -eq 1 ]; then echo "  📝 [dry-run] criaria dir → docs/${AREA}/diagnose/${SLUG}/${sub}/"; continue; fi
  mkdir -p "${d}"; : > "${keep}"
  echo "  ✅ docs/${AREA}/diagnose/${SLUG}/${sub}/"
done

render kg-2layer      "${GRAPH}"
render diagnose-state "${STORE}/STATE.md"
render notes-stub     "${STORE}/notes.md"

echo "  → PAUSA 1: preencha sources/ e confirme o escopo antes de extrair. STATE.md.NEXT = F0."
