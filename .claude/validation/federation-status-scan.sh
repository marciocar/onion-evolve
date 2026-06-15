#!/usr/bin/env bash
# =============================================================================
# federation-status-scan.sh — detecção determinística de contract-drift no ledger
#
# Propósito : Peça determinística do monitor /meta:federation-status (Fase 3).
#             Para cada contrato do ledger, compara a versão DO ARQUIVO
#             (contracts/<id>.md) com a última versão ANUNCIADA no CHANGELOG
#             (entrada PUBLISH). Divergência = DRIFT ("mudança fora do fluxo",
#             design v2 §4 / review #16): o contrato foi alterado sem publish.
#             NÃO toca forge/CI (isso é orquestração do comando). Sem LLM (6a).
#
# Uso : bash .claude/validation/federation-status-scan.sh --ledger <path> [--json]
#         --ledger <path> : caminho do ledger (ARGUMENTO — sem path embutido, 2a)
#         --json          : saída JSON {ledger, contracts[], drift_count}
#
# status por contrato: "in-sync" | "drift" | "unpublished"
#   in-sync     = versão do arquivo == última PUBLISH
#   drift       = versão do arquivo != última PUBLISH (alterado sem anunciar)
#   unpublished = registrado mas nunca publicado (pendente, não é drift)
#
# Saída : exit 0 = scan ok · exit 2 = uso incorreto / ledger ausente
# =============================================================================

set -euo pipefail

JSON=0
LEDGER=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) JSON=1; shift ;;
    --ledger) LEDGER="${2:-}"; shift 2 ;;
    *) echo "uso: $0 --ledger <path> [--json]" >&2; exit 2 ;;
  esac
done

if [[ -z "$LEDGER" ]]; then
  echo "uso: $0 --ledger <path> [--json]" >&2; exit 2
fi
if [[ ! -d "$LEDGER/contracts" ]]; then
  echo "erro: ledger sem contracts/ : $LEDGER" >&2; exit 2
fi
CHANGELOG="$LEDGER/CHANGELOG.md"

# helper: última versão ANUNCIADA de um id no CHANGELOG (PUBLISH ou ROLLBACK; vazio se nunca anunciado).
# ROLLBACK conta: após reverter, a versão vigente do contrato é a do rollback — senão um rollback
# legítimo apareceria como drift.
published_version_of() {
  local id="$1"
  [[ -f "$CHANGELOG" ]] || { echo ""; return; }
  awk -v id="$id" '
    function trim(s){ gsub(/^[ \t]+|[ \t]+$/,"",s); return s }
    /^##[ \t].*·[ \t]*(PUBLISH|ROLLBACK)[ \t]*·/ {
      n=split($0, f, "·")
      if (trim(f[2]) == id) last=trim(f[3])
    }
    END { print last }
  ' "$CHANGELOG"
}

IDS=()
declare -A FVER PVER STATUS CONS
drift_count=0

for cf in "$LEDGER"/contracts/*.md; do
  [[ -e "$cf" ]] || continue
  id="$(grep -iE '^\s*-\s*\*\*id:\*\*' "$cf" | head -1 | sed -E 's/.*\*\*id:\*\*\s*//; s/\s.*$//')"
  [[ -z "$id" ]] && id="$(basename "$cf" .md)"
  fver="$(grep -iE '^\s*-\s*\*\*version:\*\*' "$cf" | head -1 | sed -E 's/.*\*\*version:\*\*\s*//; s/\s.*$//')"
  cons="$(grep -iE '^\s*-\s*\*\*consumers:\*\*' "$cf" | head -1 | sed -E 's/.*\*\*consumers:\*\*\s*//')"
  pver="$(published_version_of "$id")"

  if [[ -z "$pver" ]]; then st="unpublished"
  elif [[ "$fver" == "$pver" ]]; then st="in-sync"
  else st="drift"; drift_count=$((drift_count+1)); fi

  IDS+=("$id"); FVER[$id]="$fver"; PVER[$id]="$pver"; STATUS[$id]="$st"; CONS[$id]="$cons"
done

if [[ "$JSON" -eq 1 ]]; then
  printf '{"ledger":"%s","drift_count":%d,"contracts":[' "$LEDGER" "$drift_count"
  first=1
  for id in "${IDS[@]}"; do
    [[ $first -eq 0 ]] && printf ','; first=0
    printf '{"id":"%s","file_version":"%s","published_version":"%s","status":"%s"}' \
      "$id" "${FVER[$id]}" "${PVER[$id]}" "${STATUS[$id]}"
  done
  printf '],"count":%d}\n' "${#IDS[@]}"
else
  if [[ ${#IDS[@]} -eq 0 ]]; then
    echo "ledger sem contratos em contracts/."
  else
    echo "status do ledger (${#IDS[@]} contrato(s), ${drift_count} em drift):"
    for id in "${IDS[@]}"; do
      mark="·"; [[ "${STATUS[$id]}" == "drift" ]] && mark="⚠️"
      echo "   $mark $id  arquivo=${FVER[$id]}  publicado=${PVER[$id]:-—}  [${STATUS[$id]}]"
    done
  fi
fi
