#!/usr/bin/env bash
# =============================================================================
# lint-design-tokens.sh — Gate DETERMINÍSTICO da vertical de design (sem LLM)
#
# Valida a SSOT de design (docs/design-context/) em três eixos — o "gate
# mecânico" da doutrina de dogfooding aplicado a design (o modelo é o pior juiz
# da própria saída; contraste/refs são CALCULADOS, não "achados"):
#   (1) DTCG bem-formado  — JSON válido; todo $value sob um nó com $type herdável.
#   (2) Referências {alias} resolvem — sem alias órfão e sem ciclo.
#   (3) Contraste WCAG    — cada par em governance/contrast-pairs.json >= min.
#
# Uso     : lint-design-tokens.sh [<dir-do-projeto>]   (default: raiz deste repo)
# Saída   : sumário estilo lint-artifacts.sh; exit 1 se houver violação HARD.
# Gracioso: design-context ausente → exit 0 (adotante pode não ter). jq/awk
#           ausente → aviso + exit 0 (mesma doutrina dos worklog-*.sh / merge-hooks).
#
# Consumido por: CI (.github/workflows/onion-validate.yml — bloqueia em HARD
#                quando muda .claude/**, docs/meta-specs/** ou docs/design-context/**),
#                /design (fase converge), /meta:context-freshness.
# Exercitado por: lint-selftest.sh (run_design_tokens_selftests).
# =============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
PROJECT="${1:-$(pwd)}"
DC="${PROJECT}/docs/design-context"

HARD=0
hard() { HARD=$((HARD + 1)); echo "  ✗ HARD: $1" >&2; }
ok()   { echo "  ✓ $1"; }

echo "=== Onion Lint Design Tokens — ${DC} ==="

# --- Graciosidade: contexto ausente / ferramentas ausentes ------------------
if [ ! -d "${DC}" ]; then
  echo "design-context ausente — nada a validar (ok p/ adotante sem design)."; exit 0
fi
if ! command -v jq >/dev/null 2>&1; then
  echo "AVISO: jq ausente — validação de tokens PULADA (instale jq)." >&2; exit 0
fi
if ! command -v awk >/dev/null 2>&1; then
  echo "AVISO: awk ausente — validação de tokens PULADA." >&2; exit 0
fi

mapfile -t FILES < <(find "${DC}" -type f -name '*.tokens.json' | sort)
if [ "${#FILES[@]}" -eq 0 ]; then
  echo "Nenhum *.tokens.json em ${DC} — nada a validar."; exit 0
fi

# --- (1) DTCG bem-formado + (build do mapa flat path -> raw value) ----------
declare -A TOK
for f in "${FILES[@]}"; do
  if ! jq -e . "${f}" >/dev/null 2>&1; then
    hard "JSON inválido: ${f#${PROJECT}/}"; continue
  fi
  # Extrai "token.path<TAB>valor" para cada nó que tem $value (string).
  while IFS=$'\t' read -r path val; do
    [ -n "${path}" ] || continue
    TOK["${path}"]="${val}"
  done < <(jq -r 'paths(scalars) as $p | select($p[-1]=="$value")
                  | [($p[:-1]|join(".")), (getpath($p)|tostring)] | @tsv' "${f}" 2>/dev/null)
done
[ "${HARD}" -eq 0 ] && ok "DTCG bem-formado (${#FILES[@]} arquivo(s), ${#TOK[@]} token(s))"

# --- (2) Resolução de referências {alias} (sem órfã, sem ciclo) -------------
# resolve <path-ou-valor> → ecoa valor final em STDOUT; rc=1 órfã, rc=2 ciclo.
resolve() {
  local v="$1" depth=0 key
  while [[ "${v}" =~ ^\{(.+)\}$ ]]; do
    key="${BASH_REMATCH[1]}"
    depth=$((depth + 1)); [ "${depth}" -gt 16 ] && return 2     # ciclo
    if [ -z "${TOK[${key}]+x}" ]; then return 1; fi             # alias órfão
    v="${TOK[${key}]}"
  done
  printf '%s' "${v}"
}
ref_fail=0
for path in "${!TOK[@]}"; do
  raw="${TOK[${path}]}"
  [[ "${raw}" =~ ^\{.+\}$ ]] || continue
  resolve "${raw}" >/dev/null; rc=$?     # capturar ANTES de qualquer outro cmd (o ! zeraria $?)
  if [ "${rc}" -ne 0 ]; then
    case "${rc}" in
      1) hard "alias órfão: ${path} → ${raw}";;
      2) hard "ciclo de referência em: ${path} → ${raw}";;
    esac
    ref_fail=1
  fi
done
[ "${ref_fail}" -eq 0 ] && ok "referências {alias} resolvem (sem órfã/ciclo)"

# --- (3) Contraste WCAG dos pares declarados --------------------------------
contrast() {  # contrast <hex_fg> <hex_bg> → razão (float) via awk
  awk -v a="$1" -v b="$2" 'function chan(h,   c){c=strtonum("0x" h)/255.0;
      return (c<=0.03928)?(c/12.92):exp(2.4*log((c+0.055)/1.055))}
    function lum(hex,   r,g,b){r=chan(substr(hex,2,2));g=chan(substr(hex,4,2));b=chan(substr(hex,6,2));
      return 0.2126*r+0.7152*g+0.0722*b}
    BEGIN{la=lum(a)+0.05; lb=lum(b)+0.05; r=(la>lb)?la/lb:lb/la; printf "%.2f", r}'
}
PAIRS="${DC}/governance/contrast-pairs.json"
if [ -f "${PAIRS}" ] && jq -e . "${PAIRS}" >/dev/null 2>&1; then
  wcag_fail=0
  while IFS=$'\t' read -r fg bg min note; do
    [ -n "${fg}" ] || continue
    fgv="$(resolve "${TOK[${fg}]:-}" 2>/dev/null || true)"
    bgv="$(resolve "${TOK[${bg}]:-}" 2>/dev/null || true)"
    if [[ ! "${fgv}" =~ ^#[0-9A-Fa-f]{6}$ ]] || [[ ! "${bgv}" =~ ^#[0-9A-Fa-f]{6}$ ]]; then
      hard "par de contraste com token ausente/não-hex: ${fg} / ${bg}"; wcag_fail=1; continue
    fi
    ratio="$(contrast "${fgv}" "${bgv}")"
    if awk -v r="${ratio}" -v m="${min}" 'BEGIN{exit !(r+0 < m+0)}'; then
      hard "contraste ${ratio}:1 < ${min}:1 — ${fg} sobre ${bg} (${note})"; wcag_fail=1
    fi
  done < <(jq -r '.pairs[] | [.fg, .bg, (.min|tostring), (.note//"")] | @tsv' "${PAIRS}")
  [ "${wcag_fail}" -eq 0 ] && ok "contraste WCAG dos pares declarados OK"
else
  echo "  (sem governance/contrast-pairs.json — checagem WCAG pulada)"
fi

# --- Sumário ----------------------------------------------------------------
echo ""
echo "=== Sumário ==="
echo "  Violações HARD : ${HARD}"
if [ "${HARD}" -gt 0 ]; then echo "FALHOU — corrija as violações HARD."; exit 1; fi
echo "OK ✓ — design tokens válidos."
exit 0
