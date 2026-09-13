#!/usr/bin/env bash
# =============================================================================
# claude-md-fuse.sh — CLAUDE.md pré-existente na adoção: classificar e FUNDIR (D_ADOPT_ENTREGA_CLAUDE_MD_FUNDIDO)
#
# Sinal do 1º adotante greenfield (2026-09-03): o /meta:adopt deixava CLAUDE.onion.md ao lado do CLAUDE.md
# gerado pelo template (Astro/Next/Vite) e quem abria o repo pelo CLAUDE.md — o arquivo que o harness
# carrega — não via o Onion. Opção (1) selada: FUNDIR quando o existente é BOILERPLATE (só comandos,
# estrutura e links, sem regra de projeto); never-clobber segue valendo para CLAUDE.md com regras reais.
#
# Uso:
#   claude-md-fuse.sh --classify <CLAUDE.md>                 → imprime boilerplate | rules ; exit 0
#   claude-md-fuse.sh --fuse <CLAUDE.md> <skeleton.md> [out] → escreve o fundido (stdout ou out); exit 0
#                                                              exit 3 se o existente NÃO é boilerplate (não funde)
# Critério de BOILERPLATE (mecânico, declarado): fora de blocos de código, tabelas, links e títulos, NÃO há
# nenhum parágrafo de prosa com >= 25 palavras nem linha começando por marcador de regra (MUST/NUNCA/SEMPRE/
# OBRIGATÓRIO/never/always/do not/don't). Um "não sei" classifica como rules (recusa no incerto).
# =============================================================================
set -euo pipefail
mode="${1:-}"; src="${2:-}"
[ -n "${mode}" ] && [ -f "${src}" ] || { echo "uso: $0 --classify <CLAUDE.md> | --fuse <CLAUDE.md> <skeleton.md> [out]" >&2; exit 2; }

classify() {
  local f="$1" infence=0 line words
  while IFS= read -r line || [ -n "${line}" ]; do
    case "${line}" in '```'*) infence=$(( 1 - infence )); continue ;; esac
    [ "${infence}" -eq 1 ] && continue
    case "${line}" in
      ''|'#'*|'|'*|'>'*|'<!--'*) continue ;;                           # vazio, título, tabela, citação, comentário
    esac
    if printf '%s' "${line}" | grep -qiE '\b(MUST|NUNCA|SEMPRE|obrigat(ó|Ó|o|O)ri[oa]|never|always|do not|don'\''t|proibido|forbidden)\b'; then
      echo rules; return 0
    fi
    # linha só de link/comando (bullet com backticks ou URL) não é prosa
    if printf '%s' "${line}" | grep -qE '^\s*[-*]\s*(`[^`]+`|\[[^]]+\]\([^)]+\)|https?://)\S*\s*$'; then continue; fi
    words="$(printf '%s' "${line}" | wc -w)"
    [ "${words}" -ge 25 ] && { echo rules; return 0; }
  done < "${f}"
  echo boilerplate
}

case "${mode}" in
  --classify) classify "${src}" ;;
  --fuse)
    skel="${3:-}"; out="${4:-/dev/stdout}"
    [ -f "${skel}" ] || { echo "skeleton ausente: ${skel}" >&2; exit 2; }
    [ "$(classify "${src}")" = "boilerplate" ] || { echo "CLAUDE.md existente tem REGRAS de projeto — não fundo (never-clobber; use CLAUDE.onion.md)" >&2; exit 3; }
    title="$(grep -m1 -E '^# ' "${src}" | sed 's/^# *//' || true)"
    {
      cat "${skel}"
      printf '\n## 🛠️ Desenvolvimento — conteúdo original do template%s\n\n' "${title:+ (${title})}"
      printf '> Preservado integralmente na adoção (%s). Diff visível no commit da adoção.\n\n' "$(date -u +%Y-%m-%d)"
      grep -vE '^# ' "${src}"
    } > "${out}"
    ;;
  *) echo "modo desconhecido: ${mode}" >&2; exit 2 ;;
esac
