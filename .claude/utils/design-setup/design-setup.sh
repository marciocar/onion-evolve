#!/usr/bin/env bash
# =============================================================================
# design-setup.sh — o motor do /design:setup: planeja (dry-run, o padrão) e, com --apply, grava o
# design-context mínimo a partir do brief que JÁ existe, e TERMINA NO GATE DE TOKENS.
#
# Uso: bash .claude/utils/design-setup/design-setup.sh [--repo <dir>] [--brand '#RRGGBB'] [--audience TXT]
#        [--tone TXT] [--theme-target auto|css-vars|tailwind|shadcn|none] [--create-brief]
#        [--add-frontmatter] [--apply] [--today AAAA-MM-DD]
#   Sem --apply nada se grava: a saída é o PLANO, uma linha por ação (`AÇÃO\t<caminho>\t<porquê>`):
#   CRIAR · MANTER (existe, nunca sobrescrevo) · FALTA · SUGERIR · CONTRASTE · TEMA · LIGACAO · PRECISA.
#   As pastas vêm do resolve-context-dir.sh (design, business, technical): declaração explícita vence convenção.
# Exit: 0 plano pronto, ou aplicado com o gate verde · 1 aplicado e o gate de tokens REPROVOU · 2 uso,
#       entrada quebrada ou não pude julgar (python3 ausente, declaração de contexto inválida) · 3 falta
#       confirmação ou dado (o brief não existe e não veio --create-brief; os tokens não existem e não veio --brand).
# Idempotente: a 2ª execução com --apply só tem MANTER e não grava nada. Tudo local, sem rede.
# Exercitado por lint-selftest.sh (run_design_setup_selftests).
# =============================================================================
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$(cd "${HERE}/../.." && pwd)"
REPO=""; ARGS=(); APPLY=0
while [ "$#" -gt 0 ]; do
  case "$1" in
    --repo) [ "$#" -ge 2 ] || { echo "design-setup: --repo pede um diretório" >&2; exit 2; }; REPO="$2"; shift 2 ;;
    --brand|--audience|--tone|--theme-target|--today)
      [ "$#" -ge 2 ] || { echo "design-setup: $1 pede um valor" >&2; exit 2; }; ARGS+=("$1" "$2"); shift 2 ;;
    --create-brief|--add-frontmatter) ARGS+=("$1"); shift ;;
    --apply) APPLY=1; ARGS+=("$1"); shift ;;
    -h|--help) sed -n '2,19p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "design-setup: argumento desconhecido: $1" >&2; exit 2 ;;
  esac
done
[ -n "${REPO}" ] || REPO="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
[ -d "${REPO}" ] || { echo "design-setup: repo inexistente: ${REPO}" >&2; exit 2; }
command -v python3 >/dev/null 2>&1 || { echo "design-setup: python3 ausente — não pude planejar" >&2; exit 2; }

RESOLVER="${CLAUDE_DIR}/utils/scope/resolve-context-dir.sh"
_dir() {
  if [ -f "${RESOLVER}" ]; then
    bash "${RESOLVER}" "$1" --repo "${REPO}" || { echo "design-setup: o resolver recusou '$1' — corrija a declaração; não gravo no default em silêncio" >&2; return 2; }
  else
    printf 'docs/%s-context\n' "$1"
  fi
}
D="$(_dir design)" || exit 2
B="$(_dir business)" || exit 2
T="$(_dir technical)" || exit 2

python3 -I -B "${HERE}/design-setup.py" --root "${REPO}" --design-dir "${D}" --business-dir "${B}" --technical-dir "${T}" ${ARGS[@]+"${ARGS[@]}"}
rc=$?
[ "${rc}" -eq 0 ] && [ "${APPLY}" -eq 1 ] || exit "${rc}"

# O fim do setup é o GATE: o contraste e as referências são re-medidos por quem decide, não por quem gerou.
GATE="${CLAUDE_DIR}/validation/lint-design-tokens.sh"
if [ ! -f "${GATE}" ]; then
  echo "GATE	-	lint-design-tokens.sh ausente em ${CLAUDE_DIR}/validation — não pude julgar" >&2; exit 2
fi
[ "${D}" = "docs/design-context" ] || echo "AVISO	-	o lint-design-tokens.sh lê só docs/design-context; o design deste repo mora em ${D}" >&2
bash "${GATE}" "${REPO}"; grc=$?
CHECK="${CLAUDE_DIR}/validation/design-context-check.sh"
[ -f "${CHECK}" ] && { bash "${CHECK}" "${REPO}" || true; }   # 1º ciclo: aviso, não reprova o setup
[ "${grc}" -eq 0 ] && exit 0
[ "${grc}" -eq 2 ] && exit 2
exit 1
