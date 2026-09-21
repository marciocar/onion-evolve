#!/usr/bin/env bash
# Leg-1 launcher — abre uma sessão Claude Code INTERATIVA com telemetria de ESTRUTURA
# apontada pro sink local. Conteúdo OFF (intake=estrutura). Uma sessão = uma tarefa distinta.
# Uso: ./leg1-claude.sh            (abre claude interativo instrumentado)
#      faça trabalho REAL e variado; feche; repita em ≥4 sessões distintas.
set -euo pipefail
SINK="http://127.0.0.1:4318"

# telemetria só de estrutura — NÃO setar OTEL_LOG_USER_PROMPTS/TOOL_CONTENT (conteúdo gated)
export CLAUDE_CODE_ENABLE_TELEMETRY=1
export CLAUDE_CODE_ENHANCED_TELEMETRY_BETA=1
export OTEL_METRICS_EXPORTER=otlp OTEL_LOGS_EXPORTER=otlp OTEL_TRACES_EXPORTER=otlp
export OTEL_EXPORTER_OTLP_ENDPOINT="$SINK"
export OTEL_EXPORTER_OTLP_PROTOCOL=http/json
export OTEL_EXPORTER_OTLP_METRICS_PROTOCOL=http/json
export OTEL_EXPORTER_OTLP_LOGS_PROTOCOL=http/json
export OTEL_EXPORTER_OTLP_TRACES_PROTOCOL=http/json
export OTEL_METRIC_EXPORT_INTERVAL=5000 OTEL_LOGS_EXPORT_INTERVAL=5000 OTEL_BSP_SCHEDULE_DELAY=3000
export OTEL_SERVICE_NAME=claude-code-leg1

# checa o sink antes de abrir
if ! curl -s -o /dev/null "$SINK/v1/metrics" -X POST -d '{}' 2>/dev/null; then
  echo "⚠️  sink não responde em $SINK — suba otlp_sink.py primeiro." >&2; exit 1
fi
echo "🟢 Leg-1: sessão INTERATIVA instrumentada (estrutura only). Faça trabalho real e variado."
exec claude "$@"
