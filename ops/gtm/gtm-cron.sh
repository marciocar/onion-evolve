#!/usr/bin/env bash
# gtm-cron.sh — wrapper de cron do collect-metrics (precedente: offsite-cron.sh, fail-loud em log)
set -euo pipefail
LOG=/home/marcio/.onion-gtm-cron.log
{
  echo "== $(date -Is) collect-metrics"
  bash /home/marcio/onion-evolve/ops/gtm/collect-metrics.sh
} >> "$LOG" 2>&1 || { echo "== $(date -Is) FALHOU rc=$?" >> "$LOG"; exit 1; }
