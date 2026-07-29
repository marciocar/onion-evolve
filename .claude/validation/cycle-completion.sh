#!/usr/bin/env bash
# =============================================================================
# cycle-completion.sh — MÉTRICA: ciclos faseados concluídos vs abandonados.
#
# O sinal "barato-primeiro" da instrumentação do KPI valor-por-adotante
# (docs/business-context/d5-pricing-brief-2026-07.md → SPEC DE INSTRUMENTAÇÃO):
# varre os STATE.md das sessões de trabalho e computa a TAXA DE CONCLUSÃO DE CICLO.
# Custo zero: nenhuma chamada de LLM, nenhum schema novo — só leitura. Molde do
# inventory.sh (determinístico, gracioso).
#
# É a PROVA (não a promessa) de que o método produz trabalho FINALIZADO — o "aha"
# do onion-mini vira número auditável, precondição de mover preço-por-camada →
# preço-por-outcome (BCG 2025; ver metrics.md).
#
# ── FRONTEIRA HONESTA (declarado≠verificado sobre o próprio spec) ─────────────
#   O spec do brief AFIRMOU que "status/phase/last_checkpoint/blocked_by existe
#   em TODO STATE.md canônico". FALSO, medido: nem todo STATE.md traz `status:`,
#   e `last_checkpoint`/`blocked_by` não existem no schema real. Este scanner NÃO
#   finge schema limpo: classifica pelo que ACHA e conta os SEM-SINAL à parte
#   (gap de schema, candidato a guard). "done" = status ∈ {done, closed} OU
#   `phase: DONE` — os três valores reais de conclusão observados.
#
#   ESCOPO = sessões do CORE (`.claude/sessions/`). O STATE.md de um ADOTANTE é
#   soberano (vive no repo dele); a agregação por-adotante-via-members.yaml é
#   extensão futura (adotante roda local + reporta). Aqui: a autoconclusão do
#   dogfood do core — o primeiro sinal, honesto sobre seu alcance.
#
# Uso:
#   cycle-completion.sh                # relatório humano (default)
#   cycle-completion.sh --jsonl        # uma linha JSON por sessão (série temporal)
#   cycle-completion.sh --summary-json # um objeto JSON com os agregados
#   cycle-completion.sh --stale-days N # limiar de "abandonada" p/ sessão OPEN (default 21)
#
# Determinístico, sem LLM. Coberto por lint-selftest.sh (run_cycle_completion_selftests).
# =============================================================================
set -uo pipefail

REPO="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
SESSIONS_DIR="${ONION_SESSIONS_DIR:-${REPO}/.claude/sessions}"
MODE="human"
STALE_DAYS=21

while [ $# -gt 0 ]; do
  case "$1" in
    --jsonl)        MODE="jsonl" ;;
    --summary-json) MODE="summary-json" ;;
    --stale-days)   STALE_DAYS="${2:?--stale-days precisa de um número}"; shift ;;
    -h|--help)      grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "uso: cycle-completion.sh [--jsonl|--summary-json] [--stale-days N]" >&2; exit 2 ;;
  esac
  shift
done

[ -d "${SESSIONS_DIR}" ] || { echo "cycle-completion: sem ${SESSIONS_DIR} — nada a varrer." >&2; exit 0; }

now_epoch="$(date +%s)"

# Extrai o campo `status:` de um STATE.md (do bloco ## NEXT ou de qualquer linha
# `status:` no corpo — o schema real não é uniforme). Vazio = sem sinal.
extract_status() {
  local f="$1"
  # 1ª ocorrência de uma linha começando com `status:` (case-insensitive).
  local s
  s="$(grep -iE '^[[:space:]]*status:[[:space:]]*' "$f" 2>/dev/null | head -1 \
        | sed -E 's/^[[:space:]]*[Ss][Tt][Aa][Tt][Uu][Ss]:[[:space:]]*//; s/[[:space:]]*$//' | tr -d '\r')"
  # fallback: `phase: DONE` conta como conclusão mesmo sem `status:`.
  if [ -z "${s}" ] && grep -qiE '^[[:space:]]*phase:[[:space:]]*DONE\b' "$f" 2>/dev/null; then
    s="done"
  fi
  printf '%s' "${s}"
}

# Classe de conclusão a partir do status bruto.
classify() {
  local raw; raw="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"
  case "${raw}" in
    "")               printf 'no-signal' ;;                 # gap de schema
    done|closed|done*|closed*|merged|shipped) printf 'done' ;;
    *)                printf 'open' ;;
  esac
}

# Recência do STATE.md pelo último commit git do arquivo (mais confiável que mtime,
# que reseta em checkout). Sem git/histórico → cai no mtime.
last_change_epoch() {
  local f="$1" e
  e="$(git -C "${REPO}" log -1 --format=%ct -- "$f" 2>/dev/null)"
  [ -n "${e}" ] || e="$(stat -c %Y "$f" 2>/dev/null || echo "${now_epoch}")"
  printf '%s' "${e}"
}

# --- varredura ---------------------------------------------------------------
total=0 done_n=0 open_active=0 open_aband=0 nosignal=0
rows=""   # linhas jsonl acumuladas

# Sessões ativas (.claude/sessions/*/STATE.md) + arquivadas (.../archived/*/STATE.md).
while IFS= read -r f; do
  [ -f "$f" ] || continue
  total=$((total+1))
  local_name="$(basename "$(dirname "$f")")"
  archived="false"; case "$f" in */archived/*) archived="true" ;; esac
  raw_status="$(extract_status "$f")"
  klass="$(classify "${raw_status}")"
  changed="$(last_change_epoch "$f")"
  age_days=$(( (now_epoch - changed) / 86400 ))

  bucket="${klass}"
  case "${klass}" in
    done)      done_n=$((done_n+1)) ;;
    no-signal) nosignal=$((nosignal+1)) ;;
    open)
      if [ "${age_days}" -gt "${STALE_DAYS}" ]; then
        open_aband=$((open_aband+1)); bucket="open-abandoned"
      else
        open_active=$((open_active+1)); bucket="open-active"
      fi ;;
  esac

  if [ "${MODE}" = "jsonl" ]; then
    # escape mínimo do nome/status p/ JSON
    esc_name="$(printf '%s' "${local_name}" | sed 's/\\/\\\\/g; s/"/\\"/g')"
    esc_st="$(printf '%s' "${raw_status:-}" | sed 's/\\/\\\\/g; s/"/\\"/g')"
    rows="${rows}{\"session\":\"${esc_name}\",\"archived\":${archived},\"status\":\"${esc_st}\",\"bucket\":\"${bucket}\",\"age_days\":${age_days}}
"
  fi
done < <(find "${SESSIONS_DIR}" -name STATE.md 2>/dev/null | sort)

# denominador honesto: só sessões com sinal (exclui no-signal).
with_signal=$(( done_n + open_active + open_aband ))
rate="n/a"
if [ "${with_signal}" -gt 0 ]; then
  rate="$(awk -v d="${done_n}" -v t="${with_signal}" 'BEGIN{printf "%.2f", d/t}')"
fi

case "${MODE}" in
  jsonl)
    printf '%s' "${rows}"
    ;;
  summary-json)
    printf '{"date":"%s","total":%d,"done":%d,"open_active":%d,"open_abandoned":%d,"no_signal":%d,"with_signal":%d,"completion_rate":"%s","stale_days":%d}\n' \
      "$(date +%F)" "${total}" "${done_n}" "${open_active}" "${open_aband}" "${nosignal}" "${with_signal}" "${rate}" "${STALE_DAYS}"
    ;;
  human)
    echo "══ Ciclos faseados — taxa de conclusão (core) ══"
    echo "  sessões varridas : ${total}"
    echo "  concluídas       : ${done_n}  (done/closed/DONE)"
    echo "  abertas ativas   : ${open_active}  (≤ ${STALE_DAYS}d desde o último commit do STATE.md)"
    echo "  abertas STALE    : ${open_aband}  (> ${STALE_DAYS}d — candidata a abandonada)"
    echo "  SEM sinal        : ${nosignal}  ⚠ STATE.md sem campo status/phase — gap de schema"
    echo "  ─────────────────"
    echo "  taxa de conclusão: ${rate}  (concluídas / com-sinal; SEM-sinal fora do denominador)"
    [ "${nosignal}" -gt 0 ] && echo "  ⚠ ${nosignal} sessão(ões) sem sinal: o metric é PARCIAL até o campo status virar guard do STATE.md."
    ;;
esac
exit 0
