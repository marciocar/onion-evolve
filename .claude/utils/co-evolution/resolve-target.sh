#!/usr/bin/env bash
# =============================================================================
# resolve-target.sh — resolve o `alvo:` de um anúncio de co-evolução para os IDs de membro que casam.
#
# F1.2 do roadmap de federação (RFC-0004): mata o RUÍDO do targeting. Hoje o `alvo:` só faz per-id OU
# broadcast-p/-todos (ignora specialization/mode/tier que o members.yaml JÁ carrega). Este resolver
# adiciona TARGETING POR SELETOR (policy-as-data), reusando as triplas de membro que o graph.sh passou a
# emitir do members.yaml (F1.1 — a semente).
#
# Uso:  resolve-target.sh <seletor>   → IDs de membro (um por linha) que casam (vazio = ninguém)
#   <seletor>:
#     nenhum | futuros [adotantes]      → vazio (entrada informativa / futuros — sem destinatário atual)
#     todos | adotantes                 → todos os membros tier hub|standalone (retrocompat)
#     <id>                              → esse membro, se existir
#     <key>:<value>[,<key>:<value>...]  → AND (interseção) sobre atributos:
#         key ∈ { mode | tier (alias role) | specialization (alias spec) }
#         ex.: mode:regulated · tier:hub · specialization:nx-monorepo · mode:regulated,tier:standalone
#
# Reusa graph.sh --triples (members.yaml). Gracioso: sem triplas de membro (sem python+yaml) → vazio.
# Determinístico. Exercitado por lint-selftest.sh (run_resolve_target_selftests).
# =============================================================================
set -uo pipefail

SEL="${1:-}"; [ -n "${SEL}" ] || { echo "uso: resolve-target.sh <seletor>" >&2; exit 2; }
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "${HERE}" rev-parse --show-toplevel 2>/dev/null || (cd "${HERE}/../../.." && pwd))"
GRAPH="${ROOT}/.claude/validation/graph.sh"

# Normaliza: descarta anotação entre parênteses, chaves {} e espaços de borda.
SEL="$(printf '%s' "${SEL}" | sed -E 's/\(.*//; s/[{}]//g; s/^[[:space:]]+//; s/[[:space:]]+$//')"

TRIPLES="$(bash "${GRAPH}" --triples 2>/dev/null || true)"
_by_pred() { printf '%s\n' "${TRIPLES}" | awk -F'\t' -v p="$1" -v v="$2" '$2==p && $3==v{print $1}' | LC_ALL=C sort -u; }

_match_one() {  # <key> <value> → ids com o atributo
  local k="$1" v="$2" pred
  case "${k}" in
    mode)                 pred=mode ;;
    tier|role)            pred=tier ;;
    specialization|spec)  pred=specialization ;;
    *) echo "ERRO: chave de seletor desconhecida: '${k}' (use mode|tier|specialization)." >&2; return 3 ;;
  esac
  _by_pred "${pred}" "${v}"
}

case "${SEL}" in
  nenhum|futuros|"futuros adotantes") exit 0 ;;                      # sem destinatário
  todos|adotantes)
    { _by_pred tier hub; _by_pred tier standalone; } | LC_ALL=C sort -u ;;
  *:*)
    # seletor key:value[,key:value] → AND (interseção)
    local_init=""; result=""
    IFS=',' read -ra _parts <<< "${SEL}"
    for part in "${_parts[@]}"; do
      part="$(printf '%s' "${part}" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')"
      [ -n "${part}" ] || continue
      k="${part%%:*}"; v="${part#*:}"; v="$(printf '%s' "${v}" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')"
      set_i="$(_match_one "${k}" "${v}")" || exit 3
      if [ -z "${local_init}" ]; then result="${set_i}"; local_init=1
      else result="$(comm -12 <(printf '%s\n' "${result}") <(printf '%s\n' "${set_i}"))"; fi
    done
    printf '%s\n' "${result}" | grep -v '^$' || true ;;
  *)
    # id nu: existe como membro (tem tripla de tier)?
    if printf '%s\n' "${TRIPLES}" | awk -F'\t' -v m="${SEL}" '$1==m && $2=="tier"{f=1} END{exit !f}'; then
      printf '%s\n' "${SEL}"
    else
      echo "AVISO: '${SEL}' não é membro no members.yaml (nem seletor key:value)." >&2
    fi ;;
esac
