#!/usr/bin/env bash
# =============================================================================
# bootstrap-new-project.sh — Scaffolda o esqueleto de uma VERTICAL DE PROJETO:
# hub homônimo + help contextual + resolver de SSOT/book. Generaliza o DNA do
# `onion` (skill-hub + help + context-resolver) para qualquer projeto.
#
# Propósito : Coração do NOVO da F1 do /meta:create-vertical (ADR
#             onion-adr-create-vertical-2026-07). Hoje cada adotante replica esse
#             padrão à mão (sinal de um adotante de campo A1). Este helper o torna 1ª classe.
#             Par de generate-marketplace.sh (o outro helper F1).
#
# Gera (a partir de templates/*.tpl, substituindo {{PROJECT}}/{{PROJECT_TITLE}}):
#   .claude/skills/<project>/SKILL.md            (hub-skill.tpl)      — roteador homônimo
#   .claude/commands/<project>/help.md           (help.tpl)          — ajuda contextual
#   .claude/skills/<project>-context/SKILL.md     (context-skill.tpl) — resolver de SSOT/book
#
# Uso  : bootstrap-new-project.sh <project-slug> [--title "Título"] [--dir <repo>] [--dry-run]
#        <project-slug> = kebab-case. --title default = derivado do slug.
#
# Contrato de Segurança (herdado do adopt): NEVER-CLOBBER (não sobrescreve arquivo
# existente — só avisa), --dry-run (mostra o que faria sem escrever), idempotente.
# Determinístico, dependency-free. Coberto por lint-selftest.sh.
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TPL_DIR="${SCRIPT_DIR}/templates"

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

[ -n "${SLUG}" ] || { echo "uso: bootstrap-new-project.sh <project-slug> [--title T] [--dir R] [--dry-run]" >&2; exit 2; }
case "${SLUG}" in
  *[!a-z0-9-]*|-*|*-|"") echo "erro: <project-slug> deve ser kebab-case (a-z, 0-9, hífen): '${SLUG}'" >&2; exit 2 ;;
esac
# título default: slug → "Palavras Capitalizadas"
if [ -z "${TITLE}" ]; then
  TITLE="$(printf '%s' "${SLUG}" | tr '-' ' ' | awk '{for(i=1;i<=NF;i++)$i=toupper(substr($i,1,1)) substr($i,2)}1')"
fi

# alvo de cada template
emit() {  # emit <tpl-file> <dest-rel>
  local tpl="${TPL_DIR}/$1" dest="${REPO_DIR}/$2" content
  [ -f "${tpl}" ] || { echo "erro: template ausente: ${tpl}" >&2; exit 2; }
  if [ -e "${dest}" ]; then echo "  ⏭️  never-clobber: já existe, não toco → ${2}"; return 0; fi
  content="$(cat "${tpl}")"
  content="${content//\{\{PROJECT_TITLE\}\}/${TITLE}}"
  content="${content//\{\{PROJECT\}\}/${SLUG}}"
  if [ "${DRY}" -eq 1 ]; then echo "  📝 [dry-run] escreveria → ${2}"; return 0; fi
  mkdir -p "$(dirname "${dest}")"
  printf '%s\n' "${content}" > "${dest}"
  echo "  ✅ ${2}"
}

echo "=== bootstrap vertical '${SLUG}' (título: ${TITLE})${DRY:+ }$( [ "${DRY}" -eq 1 ] && echo '[DRY-RUN]' ) em ${REPO_DIR} ==="
emit hub-skill.tpl     ".claude/skills/${SLUG}/SKILL.md"
emit help.tpl          ".claude/commands/${SLUG}/help.md"
emit context-skill.tpl ".claude/skills/${SLUG}-context/SKILL.md"
echo "=== feito. Próximo: preencher os esqueletos com o domínio real + /meta:inventory (sincroniza a SSOT). ==="
