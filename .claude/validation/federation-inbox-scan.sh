#!/usr/bin/env bash
# =============================================================================
# federation-inbox-scan.sh — scan determinístico do inbox (CHANGELOG) do ledger
#
# Propósito : Lado consumer da Onion Federation (Fase 2). Lê o CHANGELOG.md
#             append-only do ledger e extrai as entradas PUBLISH endereçadas a
#             UM membro (consumer), retornando a versão/classe mais recente por
#             contrato. É a peça DETERMINÍSTICA do par
#             /meta:federation-check (orquestra) ↔ este script (lê/filtra) —
#             ajuste 6a: a regra vive aqui, NUNCA num agente.
#
# Formato de entrada esperado no CHANGELOG (escrito por /meta:federation-publish):
#   ## <data> · <id> · <version> · <producer> · PUBLISH · <BREAKING|COMPATIBLE|INITIAL>
#   - consumers: [<id>, <id>, ...]
#   - resumo: <texto>
#
# Uso : bash .claude/validation/federation-inbox-scan.sh --ledger <path> --member <id> [--json]
#         --ledger <path> : caminho do ledger (PASSADO COMO ARGUMENTO — ajuste 2a, sem path embutido)
#         --member <id>   : id do membro consumer cujo inbox queremos ler
#         --json          : saída JSON {member, ledger, contracts[], breaking_count}
#
# Saída : exit 0 = scan ok (com ou sem itens) · exit 2 = uso incorreto / ledger ausente
# Determinístico, sem LLM.
# =============================================================================

set -euo pipefail

JSON=0
LEDGER=""
MEMBER=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) JSON=1; shift ;;
    --ledger) LEDGER="${2:-}"; shift 2 ;;
    --member) MEMBER="${2:-}"; shift 2 ;;
    *) echo "uso: $0 --ledger <path> --member <id> [--json]" >&2; exit 2 ;;
  esac
done

if [[ -z "$LEDGER" || -z "$MEMBER" ]]; then
  echo "uso: $0 --ledger <path> --member <id> [--json]" >&2
  exit 2
fi
CHANGELOG="$LEDGER/CHANGELOG.md"
if [[ ! -f "$CHANGELOG" ]]; then
  echo "erro: CHANGELOG não encontrado no ledger: $CHANGELOG" >&2
  exit 2
fi

# Parse determinístico: para cada header PUBLISH, captura campos; lê a linha
# "- consumers:" seguinte; se MEMBER estiver na lista, emite "id|version|producer|class".
# Append-only ⇒ a última ocorrência por id é a vigente (dedup mantém a última).
mapfile -t MATCHES < <(awk -v member="$MEMBER" '
  function trim(s){ gsub(/^[ \t]+|[ \t]+$/,"",s); return s }
  /^##[ \t].*·[ \t]*PUBLISH[ \t]*·/ {
    n=split($0, f, "·")
    cid=trim(f[2]); ver=trim(f[3]); prod=trim(f[4]); cls=trim(f[6])
    pending_id=cid; pending_ver=ver; pending_prod=prod; pending_cls=cls
    next
  }
  /^[ \t]*-[ \t]*consumers:/ {
    if (pending_id != "") {
      line=$0
      # casa o member como token (entre não-alfanuméricos), evitando match parcial
      if (line ~ ("[^A-Za-z0-9_-]" member "[^A-Za-z0-9_-]") || line ~ (member "[^A-Za-z0-9_-]*$")) {
        print pending_id "|" pending_ver "|" pending_prod "|" pending_cls
      }
      pending_id=""
    }
  }
' "$CHANGELOG")

# dedup → última versão por id (associativo; ordem de inserção não importa p/ o veredito)
declare -A LAST_VER LAST_PROD LAST_CLS
ORDER=()
for m in "${MATCHES[@]}"; do
  IFS='|' read -r id ver prod cls <<< "$m"
  [[ -z "$id" ]] && continue
  if [[ -z "${LAST_VER[$id]:-}" ]]; then ORDER+=("$id"); fi
  LAST_VER[$id]="$ver"; LAST_PROD[$id]="$prod"; LAST_CLS[$id]="$cls"
done

breaking_count=0
for id in "${ORDER[@]}"; do
  [[ "${LAST_CLS[$id]}" == "BREAKING" ]] && breaking_count=$((breaking_count+1))
done

if [[ "$JSON" -eq 1 ]]; then
  printf '{"member":"%s","ledger":"%s","breaking_count":%d,"contracts":[' "$MEMBER" "$LEDGER" "$breaking_count"
  first=1
  for id in "${ORDER[@]}"; do
    [[ $first -eq 0 ]] && printf ','
    first=0
    printf '{"id":"%s","version":"%s","producer":"%s","class":"%s"}' \
      "$id" "${LAST_VER[$id]}" "${LAST_PROD[$id]}" "${LAST_CLS[$id]}"
  done
  printf ']}\n'
else
  if [[ ${#ORDER[@]} -eq 0 ]]; then
    echo "inbox de '$MEMBER': nenhuma entrada PUBLISH endereçada (nada a validar)."
  else
    echo "inbox de '$MEMBER' (${#ORDER[@]} contrato(s), ${breaking_count} breaking):"
    for id in "${ORDER[@]}"; do
      echo "   ∟ $id v${LAST_VER[$id]} [${LAST_CLS[$id]}] · producer ${LAST_PROD[$id]}"
    done
  fi
fi
