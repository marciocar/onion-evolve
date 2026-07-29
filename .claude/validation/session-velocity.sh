#!/usr/bin/env bash
# =============================================================================
# session-velocity.sh — SINAL 3 da instrumentação valor-por-adotante:
# velocidade (duração de sessão), a partir do LEDGER DE CICLO-DE-VIDA.
#
# Lê `.claude/session-lifecycle.jsonl` (tracked) — apendado pelo `session-beacon.sh`
# em `down`/`sweep` (só timestamps, nunca conteúdo). Computa a MEDIANA de duração
# de sessão. Série temporal do --jsonl = trend de velocidade. Determinístico, sem LLM.
#
# ── POR QUE UM LEDGER (e não git-history do STATE.md) ────────────────────────
#   A 1ª tentativa lia `git log -- STATE.md` — MORTA: `.claude/sessions/` é
#   gitignored por desenho ("versionamento é escolha consciente"), então os
#   STATE.md têm 0 histórico. Este ledger PROMOVE só os timestamps a tracked,
#   preservando a decisão de manter o conteúdo de sessão local. Decisão do maestro
#   (2026-07-29): promover timestamps de sessão a tracked para o sinal de velocidade.
#
# ── FRONTEIRA HONESTA ────────────────────────────────────────────────────────
#   1. PROXY: mede wall-time de SESSÃO (up→down do beacon), não "cycle-time por
#      fase" — uma sessão pode cobrir várias fases ou ficar ociosa. Sinal de
#      velocidade, não cronômetro de fase.
#   2. COLETA DAQUI PRA FRENTE: o ledger nasce vazio; popula quando sessões
#      encerram (down) ou são varridas (sweep). Precisa de BASELINE — a série é que
#      prova algo, não um número isolado. Sessões passadas (pré-ledger) não entram.
#
# Uso:
#   session-velocity.sh                 # relatório humano (mediana em horas)
#   session-velocity.sh --jsonl         # passa o ledger cru (uma linha JSON por sessão)
#   session-velocity.sh --summary-json  # agregados (mediana_s, mediana_h, n)
#
# Determinístico, sem LLM. Coberto por lint-selftest.sh (run_session_velocity_selftests).
# =============================================================================
set -uo pipefail

REPO="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
LEDGER="${ONION_LIFECYCLE_LEDGER:-${REPO}/.claude/session-lifecycle.jsonl}"
MODE="human"

while [ $# -gt 0 ]; do
  case "$1" in
    --jsonl)        MODE="jsonl" ;;
    --summary-json) MODE="summary-json" ;;
    -h|--help)      grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "uso: session-velocity.sh [--jsonl|--summary-json]" >&2; exit 2 ;;
  esac
  shift
done

if [ ! -f "${LEDGER}" ]; then
  case "${MODE}" in
    summary-json) printf '{"date":"%s","sessions":0,"median_seconds":"n/a","median_hours":"n/a"}\n' "$(date +%F)" ;;
    jsonl) : ;;
    human) echo "session-velocity: sem ledger ainda (${LEDGER}) — popula quando sessões encerram." ;;
  esac
  exit 0
fi

# durações (segundos), uma por linha do ledger.
durs="$(grep -oE '"duration_s":[0-9]+' "${LEDGER}" 2>/dev/null | grep -oE '[0-9]+')"
n="$(printf '%s\n' "${durs}" | grep -cE '^[0-9]+$' || true)"

median_s="n/a" median_h="n/a"
if [ "${n:-0}" -gt 0 ]; then
  median_s="$(printf '%s\n' "${durs}" | grep -E '^[0-9]+$' | sort -n \
    | awk '{a[NR]=$1} END{ if(NR%2){print a[(NR+1)/2]} else {print int((a[NR/2]+a[NR/2+1])/2)} }')"
  median_h="$(awk -v s="${median_s}" 'BEGIN{printf "%.1f", s/3600}')"
fi

case "${MODE}" in
  jsonl) cat "${LEDGER}" ;;
  summary-json)
    printf '{"date":"%s","sessions":%d,"median_seconds":"%s","median_hours":"%s"}\n' \
      "$(date +%F)" "${n:-0}" "${median_s}" "${median_h}" ;;
  human)
    echo "══ Velocidade — duração de sessão (ledger de ciclo-de-vida) ══"
    echo "  sessões registradas : ${n:-0}"
    echo "  mediana de duração  : ${median_h} h  (${median_s} s)"
    echo "  ⚠ PROXY (wall-time de sessão, não cycle-time de fase) + precisa de BASELINE (série temporal)."
    echo "  ⚠ Popula daqui pra frente: o beacon carimba em down/sweep; sessões pré-ledger não entram."
    ;;
esac
exit 0
