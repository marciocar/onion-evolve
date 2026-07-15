#!/usr/bin/env bash
# =============================================================================
# scaffold-book-dir.sh — Scaffolda o diretório do BOOK/SSOT de uma vertical de
# projeto: docs/<project>-context/README.md com o contrato mínimo (Estado/entidades,
# Decisões, Convenções). É o par natural do book-resolver (skill <project>-context)
# gerado por bootstrap-new-project.sh.
#
# Propósito : Helper 3 (caminho seguro) da F1 do /meta:create-vertical
#             (ADR onion-adr-create-vertical-2026-07). O ADR previa extrair o
#             scaffold da Fase 3 do adopt; a investigação mostrou a sobreposição
#             MAIS FINA que o assumido (adopt Fase 3 é majoritariamente prosa de
#             adoção-de-repo, não de criar-vertical) → refactor do adopt DEFERIDO
#             (alto-risco/baixo-retorno). Este helper entrega só o que o
#             create-vertical precisa: o dir do book, sem tocar no adopt.
#
# Uso  : scaffold-book-dir.sh <project-slug> [--title "Título"] [--dir <repo>] [--dry-run]
#
# Contrato de Segurança (herdado do adopt): NEVER-CLOBBER, --dry-run, idempotente.
# Determinístico, dependency-free. Coberto por lint-selftest.sh.
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TPL="${SCRIPT_DIR}/templates/book-stub.tpl"

SLUG=""; TITLE=""; REPO_DIR="."; DRY=0
while [ $# -gt 0 ]; do
  case "$1" in
    --title) TITLE="${2:-}"; shift 2 ;;
    --dir)   REPO_DIR="${2:-.}"; shift 2 ;;
    --dry-run) DRY=1; shift ;;
    -*) echo "flag desconhecida: $1" >&2; exit 2 ;;
    *) [ -z "${SLUG}" ] && SLUG="$1" || { echo "argumento extra: $1" >&2; exit 2; }; shift ;;
  esac
done

[ -n "${SLUG}" ] || { echo "uso: scaffold-book-dir.sh <project-slug> [--title T] [--dir R] [--dry-run]" >&2; exit 2; }
case "${SLUG}" in
  *[!a-z0-9-]*|-*|*-|"") echo "erro: <project-slug> deve ser kebab-case: '${SLUG}'" >&2; exit 2 ;;
esac
[ -f "${TPL}" ] || { echo "erro: template ausente: ${TPL}" >&2; exit 2; }
if [ -z "${TITLE}" ]; then
  TITLE="$(printf '%s' "${SLUG}" | tr '-' ' ' | awk '{for(i=1;i<=NF;i++)$i=toupper(substr($i,1,1)) substr($i,2)}1')"
fi

DEST="${REPO_DIR}/docs/${SLUG}-context/README.md"
echo "=== scaffold book '${SLUG}' (título: ${TITLE})$( [ "${DRY}" -eq 1 ] && echo ' [DRY-RUN]' ) em ${REPO_DIR} ==="
if [ -e "${DEST}" ]; then echo "  ⏭️  never-clobber: já existe, não toco → docs/${SLUG}-context/README.md"; exit 0; fi
content="$(cat "${TPL}")"
content="${content//\{\{PROJECT_TITLE\}\}/${TITLE}}"
content="${content//\{\{PROJECT\}\}/${SLUG}}"
if [ "${DRY}" -eq 1 ]; then echo "  📝 [dry-run] escreveria → docs/${SLUG}-context/README.md"; exit 0; fi
mkdir -p "$(dirname "${DEST}")"
printf '%s\n' "${content}" > "${DEST}"
echo "  ✅ docs/${SLUG}-context/README.md"
