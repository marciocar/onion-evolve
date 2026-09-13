#!/usr/bin/env bash
# =============================================================================
# context-freshness-metric.sh — SINAL 2 da instrumentação valor-por-adotante:
# frescor de contexto (SSOT viva vs stale), CAMADA DETERMINÍSTICA.
#
# Varre os context-docs (business/technical/compliance) e classifica cada um por
# FRESCOR do carimbo de data: CURRENT (≤ THRESHOLD meses) · STALE (>) · NO-STAMP.
# Série temporal do --jsonl = trend de frescor por adotante. Determinístico, sem
# LLM, molde do cycle-completion.sh.
#
# ── FRONTEIRA HONESTA (declarado≠verificado sobre o spec) ─────────────────────
#   O spec pedia "rodar /meta:context-freshness e persistir a saída como JSONL".
#   Aquele comando é ORQUESTRAÇÃO LLM (veredito semântico: rastreabilidade,
#   disciplina de inferência). ESTE script é só a CAMADA DETERMINÍSTICA — o gate
#   #1 do próprio comando (carimbo ≤ threshold), que é o barato-primeiro
#   auto-suficiente. NÃO substitui o veredito semântico do comando; é o piso que
#   roda hoje, custo zero, e já dá o trend de frescor sem chamar modelo.
#   Threshold herdado de kb-freshness (18 meses).
#
# Uso:
#   context-freshness-metric.sh                 # relatório humano
#   context-freshness-metric.sh --jsonl         # uma linha JSON por doc
#   context-freshness-metric.sh --summary-json  # agregados
#   context-freshness-metric.sh --months N      # threshold de STALE (default 18)
#
# Determinístico, sem LLM. Coberto por lint-selftest.sh (run_context_freshness_metric_selftests).
# =============================================================================
set -uo pipefail

REPO="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
MODE="human"
THRESH_MONTHS=18
DIRS_DEFAULT="docs/business-context docs/technical-context docs/compliance-context"
DIRS="${ONION_CONTEXT_DIRS:-${DIRS_DEFAULT}}"

while [ $# -gt 0 ]; do
  case "$1" in
    --jsonl)        MODE="jsonl" ;;
    --summary-json) MODE="summary-json" ;;
    --months)       THRESH_MONTHS="${2:?--months precisa de um número}"; shift ;;
    -h|--help)      grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "uso: context-freshness-metric.sh [--jsonl|--summary-json] [--months N]" >&2; exit 2 ;;
  esac
  shift
done

now_epoch="$(date +%s)"
thresh_days=$(( THRESH_MONTHS * 30 ))

# Extrai o carimbo YYYY-MM-DD de um doc: `date:` (frontmatter) OU
# `Última Atualização:` (corpo). 1ª ocorrência. Vazio = sem carimbo.
extract_stamp() {
  local f="$1" s
  # ⚠️ ALTERNÂNCIA EXPLÍCITA, NUNCA CONJUNTO COM CARACTERE MULTI-BYTE. A versão anterior usava
  #    `[Úu]ltima [Aa]tualiza[çc][ãa]o`: em UTF-8 `Ú`, `ç` e `ã` valem 1 caractere e o conjunto
  #    funciona; em locale C valem 2 BYTES cada e o bracket vira indefinido. Medido 2026-09-13:
  #    o MESMO arquivo saía `stale` em C.UTF-8 e `no-stamp` em C — e o hook de git roda em C,
  #    então a métrica de frescor MENTIA no único ambiente que importa. A cura não é achar o
  #    conjunto certo: é não depender de conjunto quando o alfabeto é multi-byte.
  s="$(grep -E '^[[:space:]]*[Dd][Aa][Tt][Ee]:[[:space:]]*[0-9]{4}-[0-9]{2}-[0-9]{2}|(Última|última|Ultima|ultima|ÚLTIMA|ULTIMA) (Atualização|atualização|Atualizacao|atualizacao|ATUALIZAÇÃO|ATUALIZACAO)' "$f" 2>/dev/null \
        | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' | head -1)"
  printf '%s' "${s}"
}
date_to_epoch() { date -d "$1" +%s 2>/dev/null || echo 0; }

total=0 current=0 stale=0 nostamp=0 rows=""
while IFS= read -r f; do
  [ -f "$f" ] || continue
  total=$((total+1))
  rel="${f#${REPO}/}"; rel="${rel#./}"
  stamp="$(extract_stamp "$f")"
  if [ -z "${stamp}" ]; then
    klass="no-stamp"; age="-1"; nostamp=$((nostamp+1))
  else
    age=$(( (now_epoch - $(date_to_epoch "${stamp}")) / 86400 ))
    if [ "${age}" -le "${thresh_days}" ]; then klass="current"; current=$((current+1))
    else klass="stale"; stale=$((stale+1)); fi
  fi
  if [ "${MODE}" = "jsonl" ]; then
    esc="$(printf '%s' "${rel}" | sed 's/\\/\\\\/g; s/"/\\"/g')"
    rows="${rows}{\"doc\":\"${esc}\",\"freshness\":\"${klass}\",\"stamp\":\"${stamp:-null}\",\"age_days\":${age}}
"
  fi
done < <(for d in ${DIRS}; do case "$d" in /*) find "$d" -name '*.md' 2>/dev/null ;; *) find "${REPO}/${d}" -name '*.md' 2>/dev/null ;; esac; done | sort)

with_stamp=$(( current + stale ))
rate="n/a"
if [ "${with_stamp}" -gt 0 ]; then
  rate="$(awk -v c="${current}" -v t="${with_stamp}" 'BEGIN{printf "%.2f", c/t}')"
fi

case "${MODE}" in
  jsonl) printf '%s' "${rows}" ;;
  summary-json)
    printf '{"date":"%s","docs":%d,"current":%d,"stale":%d,"no_stamp":%d,"with_stamp":%d,"current_rate":"%s","threshold_months":%d}\n' \
      "$(date +%F)" "${total}" "${current}" "${stale}" "${nostamp}" "${with_stamp}" "${rate}" "${THRESH_MONTHS}" ;;
  human)
    echo "══ Frescor de contexto (camada determinística: carimbo ≤ ${THRESH_MONTHS}m) ══"
    echo "  context-docs   : ${total}"
    echo "  CURRENT        : ${current}"
    echo "  STALE          : ${stale}  (carimbo > ${THRESH_MONTHS} meses)"
    echo "  SEM carimbo    : ${nostamp}  ⚠ sem data — fora do denominador"
    echo "  ───────────────"
    echo "  taxa CURRENT   : ${rate}  (current / com-carimbo)"
    echo "  ⚠ Só a camada DETERMINÍSTICA (carimbo); o veredito SEMÂNTICO é do comando /meta:context-freshness (LLM)."
    ;;
esac
exit 0
