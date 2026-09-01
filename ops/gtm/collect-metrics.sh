#!/usr/bin/env bash
# =============================================================================
# collect-metrics.sh — persiste a instrumentação GTM (autorizada em D5, 2026-07-29)
#
# Propósito : Q_instrument_metrics (Onda 8): os 4 medidores emitem --jsonl e NADA persistia —
#             sem série histórica, a decisão de preço/valor por adotante fica sem dado.
#             Appenda 1 linha-envelope por medidor por dia em docs/onion/metrics/gtm-<medidor>.jsonl
#             (ledger versionado; o commit é do humano/rotina de PR — o cron só escreve o arquivo).
# Uso       : bash ops/gtm/collect-metrics.sh            # coleta (idempotente por dia)
#             bash ops/gtm/collect-metrics.sh --resumo   # agregador de leitura
# Cron      : 30 12 * * * (via ops/gtm/gtm-cron.sh — precedente offsite-cron: fail-loud em log)
# =============================================================================
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT="${ROOT}/docs/onion/metrics"
HOJE="$(date +%F)"
if [ "${1:-}" = "--resumo" ]; then
  for f in "${OUT}"/gtm-*.jsonl; do
    [ -f "$f" ] || continue
    n=$(grep -c "^{" "$f"); dias=$(grep -oE '"dia":"[0-9-]+"' "$f" | sort -u | wc -l)
    echo "$(basename "$f"): ${n} registros em ${dias} dia(s); último: $(tail -1 "$f" | cut -c1-100)"
  done
  exit 0
fi
mkdir -p "${OUT}"
for s in federation-engagement session-velocity context-freshness-metric cycle-completion; do
  led="${OUT}/gtm-${s}.jsonl"
  if [ -f "$led" ] && grep -q "\"dia\":\"${HOJE}\"" "$led"; then
    echo "collect: ${s} já coletado hoje (idempotente)"; continue
  fi
  linhas=$(bash "${ROOT}/.claude/validation/${s}.sh" --jsonl 2>/dev/null | grep -c "^{") || linhas=0
  payload=$(bash "${ROOT}/.claude/validation/${s}.sh" --jsonl 2>/dev/null | python3 -c 'import sys,json; print(json.dumps([json.loads(l) for l in sys.stdin if l.strip().startswith("{")]))')
  printf '{"dia":"%s","medidor":"%s","registros":%s,"dados":%s}\n' "$HOJE" "$s" "$linhas" "$payload" >> "$led"
  echo "collect: ${s} → ${linhas} registro(s)"
done
