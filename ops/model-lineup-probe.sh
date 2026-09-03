#!/usr/bin/env bash
# =============================================================================
# model-lineup-probe.sh — a conta TEM acesso a cada degrau da escada de modelos? (rodada E6 / REGRA 65)
#
# Mecaniza o "confirmado na conta" que a rodada E6 de 2026-09-02 fez à mão (E_FABLE_5_1_CONFIRMADO_NA_CONTA):
# para cada modelo de session_models + session_floor (docs/onion/radar-baselines.yaml) roda um turno headless
# mínimo e registra ok | denied | timeout com a 1ª linha do erro. NÃO escreve na baseline (a rodada E6 sela);
# imprime TSV e, com --jsonl <arquivo>, apende o registro datado. Custo: 1 turno curtíssimo por modelo.
# Uso: ops/model-lineup-probe.sh [--baseline <yaml>] [--jsonl <out>] [--timeout <s>=60]   (ONION_CC_BIN p/ bancada)
# =============================================================================
set -uo pipefail
root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
bl="${root}/docs/onion/radar-baselines.yaml"; out=""; tmo=60; cc="${ONION_CC_BIN:-claude}"
while [ $# -gt 0 ]; do case "$1" in --baseline) shift; bl="$1" ;; --jsonl) shift; out="$1" ;; --timeout) shift; tmo="$1" ;; *) echo "arg desconhecido: $1" >&2; exit 2 ;; esac; shift; done
[ -f "${bl}" ] || { echo "baseline ausente: ${bl}" >&2; exit 2; }
command -v "${cc}" >/dev/null 2>&1 || { echo "binário '${cc}' não encontrado" >&2; exit 2; }
models="$(awk '
  /^[[:space:]]*session_models:[[:space:]]*(#.*)?$/ {f=1; next}
  f && /^[[:space:]]*-[[:space:]]*/ { sub(/^[[:space:]]*-[[:space:]]*/,""); sub(/[[:space:]]*#.*$/,""); gsub(/"/,""); if ($0!="") print; next }
  f { f=0 }
  /^[[:space:]]*session_floor:[[:space:]]*/ { sub(/^[[:space:]]*session_floor:[[:space:]]*/,""); sub(/[[:space:]]*#.*$/,""); gsub(/"/,""); if ($0!="") print }' "${bl}")"
[ -n "${models}" ] || { echo "baseline sem session_models" >&2; exit 2; }
printf 'model\tstatus\tseconds\tnote\n'; bad=0
while IFS= read -r m; do
  t0=$(date +%s); status=ok; note=""
  if o="$(timeout "${tmo}" "${cc}" -p --model "${m}" --max-turns 1 'responda apenas: ok' 2>&1)"; then
    printf '%s' "${o}" | grep -qi 'ok' || { status=unexpected; note="$(printf '%s' "${o}" | head -1 | cut -c1-80)"; }
  else
    rc=$?; status=denied; [ "${rc}" -eq 124 ] && status=timeout; note="$(printf '%s' "${o}" | grep -vE '^\s*$' | head -1 | cut -c1-80)"; bad=$((bad+1))
  fi
  secs=$(( $(date +%s) - t0 ))
  printf '%s\t%s\t%s\t%s\n' "${m}" "${status}" "${secs}" "${note}"
  [ -n "${out}" ] && printf '{"ts":"%s","model":"%s","status":"%s","seconds":%s,"note":"%s"}\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "${m}" "${status}" "${secs}" "${note//\"/}" >> "${out}"
done <<< "${models}"
[ "${bad}" -eq 0 ]
