#!/usr/bin/env bash
# =============================================================================
# federation-engagement.sh — SINAL 4 da instrumentação valor-por-adotante:
# adotante ATIVO vs DORMENTE (proxy de engajamento vivo).
#
# É o FILTRO que a spec do d5-pricing-brief nomeia: só faz sentido interpretar
# os outros sinais (ciclos, velocidade, frescor) para quem OPERA. Por membro do
# `members.yaml`, acha a atividade mais recente e classifica active/dormant/never.
#
# ── FRONTEIRA HONESTA (declarado≠verificado sobre o próprio spec) ─────────────
#   O spec afirmou que `/meta:federation-status` já dá "ativo vs dormente, zero
#   código novo". FALSO, medido: o `federation-status-scan.sh --json` mede DRIFT
#   DE CONTRATO ({ledger,contracts,drift_count}), não atividade de membro. Este
#   sinal é código novo.
#
#   PROXY, não medição direta: o core NÃO vê o adotante operar (ele é soberano).
#   O que o core TEM é a atividade do doc-bridge: as datas dos anúncios entregues
#   em `outbox/<id>/_processed/*.md`. "Última entrega processada" ≈ "o adotante
#   ainda está no loop". É um piso honesto, não a verdade do uso do adotante.
#
# Uso:
#   federation-engagement.sh                 # relatório humano
#   federation-engagement.sh --jsonl         # uma linha JSON por membro
#   federation-engagement.sh --summary-json  # agregados
#   federation-engagement.sh --dormant-days N  # limiar dormente (default 30)
#
# Determinístico, sem LLM. Coberto por lint-selftest.sh (run_federation_engagement_selftests).
# =============================================================================
set -uo pipefail

REPO="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
FED="${ONION_FED_DIR:-${REPO}/docs/evolution/federation}"
MEMBERS="${FED}/members.yaml"
OUTBOX="${FED}/outbox"
MODE="human"
DORMANT_DAYS=30

while [ $# -gt 0 ]; do
  case "$1" in
    --jsonl)        MODE="jsonl" ;;
    --summary-json) MODE="summary-json" ;;
    --dormant-days) DORMANT_DAYS="${2:?--dormant-days precisa de um número}"; shift ;;
    -h|--help)      grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "uso: federation-engagement.sh [--jsonl|--summary-json] [--dormant-days N]" >&2; exit 2 ;;
  esac
  shift
done

[ -f "${MEMBERS}" ] || { echo "federation-engagement: sem ${MEMBERS} — nada a medir." >&2; exit 0; }

now_epoch="$(date +%s)"

# epoch de uma data YYYY-MM-DD (portável: usa `date -d`).
date_to_epoch() { date -d "$1" +%s 2>/dev/null || echo 0; }

# Data (YYYY-MM-DD) da atividade mais recente de um membro no doc-bridge:
# o maior YYYY-MM-DD entre os nomes de arquivo em outbox/<id>/_processed/.
last_activity_date() {
  local id="$1" dir="${OUTBOX}/${id}/_processed"
  [ -d "${dir}" ] || return 0
  ls -1 "${dir}" 2>/dev/null \
    | grep -oE '^[0-9]{4}-[0-9]{2}-[0-9]{2}' | sort | tail -1
}

# ids de membro (exclui onion-evolve = o próprio core; não é adotante).
members="$(grep -E '^[[:space:]]*- id:' "${MEMBERS}" 2>/dev/null \
           | sed -E 's/^[[:space:]]*- id:[[:space:]]*//; s/[[:space:]]*$//' | grep -v '^onion-evolve$')"

total=0 active=0 dormant=0 never=0 rows=""
while IFS= read -r id; do
  [ -n "${id}" ] || continue
  total=$((total+1))
  last="$(last_activity_date "${id}")"
  if [ -z "${last}" ]; then
    klass="never"; age="-1"; never=$((never+1))
  else
    age=$(( (now_epoch - $(date_to_epoch "${last}")) / 86400 ))
    if [ "${age}" -le "${DORMANT_DAYS}" ]; then klass="active"; active=$((active+1))
    else klass="dormant"; dormant=$((dormant+1)); fi
  fi
  if [ "${MODE}" = "jsonl" ]; then
    esc_id="$(printf '%s' "${id}" | sed 's/\\/\\\\/g; s/"/\\"/g')"
    rows="${rows}{\"member\":\"${esc_id}\",\"engagement\":\"${klass}\",\"last_activity\":\"${last:-null}\",\"age_days\":${age}}
"
  fi
done <<< "${members}"

case "${MODE}" in
  jsonl) printf '%s' "${rows}" ;;
  summary-json)
    printf '{"date":"%s","members":%d,"active":%d,"dormant":%d,"never":%d,"dormant_days":%d}\n' \
      "$(date +%F)" "${total}" "${active}" "${dormant}" "${never}" "${DORMANT_DAYS}"
    ;;
  human)
    echo "══ Engajamento de federação (proxy: última entrega em outbox/<id>/_processed) ══"
    echo "  adotantes        : ${total}  (exclui o core onion-evolve)"
    echo "  ATIVOS           : ${active}  (≤ ${DORMANT_DAYS}d desde a última entrega processada)"
    echo "  DORMENTES        : ${dormant}  (> ${DORMANT_DAYS}d)"
    echo "  SEM atividade    : ${never}  (nenhuma entrega no _processed)"
    echo "  ⚠ PROXY core-side: mede o doc-bridge, não o uso soberano do adotante."
    ;;
esac
exit 0
