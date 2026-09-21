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
# ⚠️ INTERVALOS CURTOS DE PROPOSITO, e a razao e MEDIDA (2026-09-21, 1a rodada interativa real):
# 5 sessoes do maestro produziram APENAS `claude_code.session.count` — zero traces, zero
# `blocked_on_user`, zero `tool_decision`. As minhas sessoes headless, no mesmo dia e com o mesmo
# sink, trouxeram os tres sinais nos arquivos certos (`tool_decision` em logs, `blocked_on_user` em
# traces). A diferenca nao e o binario (o 2.1.278 tem TracerProvider, startSpan, BatchSpanProcessor
# e os nomes dos sinais — medido com `strings`): e o ENCERRAMENTO. Processo headless TERMINA e o SDK
# descarrega o buffer; sessao interativa FECHADA pode morrer antes do flush periodico.
# 3000/5000 ms era janela grande demais para sessao curta. 500/1000 reduz a perda; nao a elimina —
# fechar o terminal (SIGKILL) ainda mata o buffer, e por isso o README pede `/exit`.
export OTEL_METRIC_EXPORT_INTERVAL=1000 OTEL_LOGS_EXPORT_INTERVAL=1000 OTEL_BSP_SCHEDULE_DELAY=500
export OTEL_SERVICE_NAME=claude-code-leg1

# checa o sink antes de abrir
if ! curl -s -o /dev/null "$SINK/v1/metrics" -X POST -d '{}' 2>/dev/null; then
  echo "⚠️  sink não responde em $SINK — suba otlp_sink.py primeiro." >&2; exit 1
fi
echo "🟢 Leg-1: sessão INTERATIVA instrumentada (estrutura only). Faça trabalho real e variado."
exec claude "$@"
