#!/usr/bin/env bash
# =============================================================================
# tokens-to-css-vars.sh — sink DETERMINÍSTICO (adapter css-vars do design-sink)
#
# Lê a SSOT de design (docs/design-context/*.tokens.json, W3C/DTCG), resolve as
# referências {alias} ao valor final e emite CSS custom properties em STDOUT:
#     :root { --color-action-primary: #D97757; ... }
#
# Tradução de DADOS (sem LLM): o gate lint-design-tokens.sh já garantiu que a
# SSOT é válida (DTCG + refs + WCAG) antes deste consumo.
#
# Uso     : tokens-to-css-vars.sh [<dir-do-projeto>]   (default: raiz deste repo)
# Saída   : CSS em STDOUT (o chamador redireciona). Token "color.action.primary"
#           → custom property "--color-action-primary".
# Gracioso: design-context/ ausente → emite ":root {}" + aviso STDERR + exit 0.
#           jq ausente → aviso + exit 0 (mesma doutrina dos demais helpers).
# =============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
PROJECT="${1:-$(pwd)}"
DC="${PROJECT}/docs/design-context"

if [ ! -d "${DC}" ]; then
  echo "AVISO: design-context ausente em ${PROJECT} — nada a emitir." >&2
  echo ":root {}"; exit 0
fi
if ! command -v jq >/dev/null 2>&1; then
  echo "AVISO: jq ausente — sink css-vars PULADO." >&2
  echo ":root {}"; exit 0
fi

declare -A TOK
while IFS= read -r f; do
  while IFS=$'\t' read -r path val; do
    [ -n "${path}" ] || continue
    TOK["${path}"]="${val}"
  done < <(jq -r 'paths(scalars) as $p | select($p[-1]=="$value")
                  | [($p[:-1]|join(".")), (getpath($p)|tostring)] | @tsv' "${f}" 2>/dev/null)
done < <(find "${DC}" -type f -name '*.tokens.json' | sort)

resolve() {  # segue {alias} até valor final; guarda de ciclo
  local v="$1" depth=0 key
  while [[ "${v}" =~ ^\{(.+)\}$ ]]; do
    key="${BASH_REMATCH[1]}"; depth=$((depth + 1)); [ "${depth}" -gt 16 ] && { printf '%s' "${v}"; return; }
    [ -z "${TOK[${key}]+x}" ] && { printf '%s' "${v}"; return; }
    v="${TOK[${key}]}"
  done
  printf '%s' "${v}"
}

echo "/* Gerado de docs/design-context por design-sink/tokens-to-css-vars.sh — NÃO editar à mão. */"
echo ":root {"
# Ordena por nome do token para saída estável (diff-friendly).
for path in $(printf '%s\n' "${!TOK[@]}" | sort); do
  var="--$(printf '%s' "${path}" | tr '.' '-')"
  echo "  ${var}: $(resolve "${TOK[${path}]}");"
done
echo "}"
exit 0
