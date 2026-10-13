#!/usr/bin/env bash
# =============================================================================
# selection-replay.sh — REPLAY do seletor da bancada sobre PRs já mergeados (core-only)
#
# POR QUE EXISTE (decisão do maestro de 2026-10-13, «1+2 juntos, medido»): a hipótese era que quase
# todo PR cai em ~100 famílias porque o mapa família→caminho casa por DIRETÓRIO e todo PR carrega o
# resíduo `docs/evolution/review/<slug>.md` e algum `.kg.yaml`. Hipótese não é medição: este script
# roda o seletor ATUAL da árvore (o `lint-selftest.sh --affected-range` e a política do nível PR,
# `selftest-pr-selection.sh`) sobre o diff de cada PR mergeado e imprime a distribuição.
#
# O mapa usado é o da ÁRVORE ATUAL (o seletor que vai julgar o próximo PR), não o da época do PR:
# a pergunta é "o que o seletor de hoje escolheria para aquele diff", e é a única que compara antes e
# depois de uma mudança no seletor com os mesmos 50 diffs.
#
# Uso  : bash ops/testing/selection-replay.sh [--limit N] [--ranges <arquivo>] [--tsv <ABS.tsv>]
#                                             [--startup] [--startup-runs K]
#          --limit N     últimos N PRs mergeados (gh pr list; default 50)
#          --ranges F    lê "pr<TAB>base<TAB>head" de F em vez do gh (replay offline e bancada)
#          --tsv F       grava uma linha por PR: pr⇥arquivos⇥familias⇥nivel⇥sem_infra⇥motivo_sem_infra⇥motivo⇥segundos_cpu (soma de selftest-family-times.tsv)
#                        (sem_infra = o mesmo diff sem a bancada, os workflows e ops/testing: o peso do MAPA)
#          --startup     mede também o ARRANQUE de um worker (cabeçalho da bancada até a 1ª família)
# Saída: tabela por PR + `#REPLAY n=… p50=… p90=… max=… completa_ci=… …` (o nível PR do CI) e
#        `#REPLAY_SEM_INFRA …` (a parte do diff que o mapa decide), e, com --startup,
#        `#STARTUP runs=… mediana=…s` (segundos de parede).
# Exit : 0 medido · 1 algum PR sem resposta do seletor (contado, nunca omitido) · 2 uso inválido.
# =============================================================================
set -uo pipefail
export LC_ALL=C

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SUT="${ROOT}/.claude/validation/lint-selftest.sh"
POLICY="${ROOT}/ops/testing/selftest-pr-selection.sh"
TIMES="${ROOT}/ops/testing/selftest-family-times.tsv"
LIMIT=50; RANGES=""; TSV=""; STARTUP=0; STARTUP_RUNS=3
while [ $# -gt 0 ]; do
  case "$1" in
    --limit) shift; LIMIT="${1:-}" ;;
    --ranges) shift; RANGES="${1:-}" ;;
    --tsv) shift; TSV="${1:-}" ;;
    --startup) STARTUP=1 ;;
    --startup-runs) shift; STARTUP_RUNS="${1:-}" ;;
    -h|--help) sed -n '/^# Uso  :/,/^# Exit :/p' "${BASH_SOURCE[0]}"; exit 0 ;;
    *) echo "selection-replay: argumento desconhecido '$1'" >&2; exit 2 ;;
  esac
  shift
done
case "${LIMIT}" in ''|*[!0-9]*) echo "selection-replay: --limit exige inteiro" >&2; exit 2 ;; esac
case "${STARTUP_RUNS}" in ''|*[!0-9]*|0) echo "selection-replay: --startup-runs exige inteiro >0" >&2; exit 2 ;; esac

_work="$(mktemp -d)"; trap 'rm -rf "${_work}"' EXIT
if [ -n "${RANGES}" ]; then
  [ -f "${RANGES}" ] || { echo "selection-replay: --ranges ${RANGES} não existe" >&2; exit 2; }
  cp "${RANGES}" "${_work}/ranges"
else
  command -v gh >/dev/null 2>&1 || { echo "selection-replay: sem gh — use --ranges" >&2; exit 2; }
  gh pr list --state merged --limit "${LIMIT}" --json number,mergeCommit,baseRefOid \
    -q '.[] | select(.mergeCommit != null) | "\(.number)\t\(.baseRefOid)\t\(.mergeCommit.oid)"' > "${_work}/ranges" \
    || { echo "selection-replay: gh pr list falhou" >&2; exit 2; }
fi

TOTAL="$(bash "${SUT}" --list 2>/dev/null | grep -c . || true)"
[ "${TOTAL:-0}" -gt 0 ] || { echo "selection-replay: --list da bancada vazio — não sei medir" >&2; exit 2; }

_noans=0; : > "${_work}/rows"
printf 'pr\tarquivos\tfamilias\tnivel\tsem_infra\tmotivo_sem_infra\tmotivo\tsegundos_cpu\n'
while IFS=$'\t' read -r pr base head; do
  [ -n "${pr:-}" ] || continue
  rng="${base}...${head}"
  nf="$(git -C "${ROOT}" diff --name-only "${rng}" -- 2>/dev/null | grep -c . || true)"
  # ONION_SELFTEST_REPLAY_SYNTH_BOUNDS: a bancada de um PR ANTIGO não tem os marcadores ONION-BENCH do motor
  # (2026-10-13); sem eles a regra do BLOCO recusa e devolve a completa. Para medir a regra NOVA sobre o diff
  # antigo, a fronteira é sintetizada onde os marcadores foram postos. Só aqui; no CI marcador ausente = completa.
  out="$(ONION_SELFTEST_REPLAY_SYNTH_BOUNDS=1 bash "${POLICY}" --range "${rng}" 2>/dev/null)"; rc=$?
  level="$(printf '%s\n' "${out}" | sed -n 's/^nivel=//p')"
  fams="$(printf '%s\n' "${out}" | sed -n 's/^familias=//p')"
  reason="$(printf '%s\n' "${out}" | sed -n 's/^motivo=//p' | cut -c1-140)"
  if [ "${rc}" -ne 0 ] || [ -z "${level}" ]; then
    _noans=$((_noans + 1)); level="SEM-RESPOSTA"; n="-"
  elif [ "${fams}" = "ALL" ]; then n="${TOTAL}"
  else n="$(printf '%s' "${fams}" | tr ',' '\n' | grep -c . || true)"; fi
  # SEM A INFRA: o mesmo diff sem os arquivos que compram a completa por POLÍTICA (a bancada, workflows,
  # ops/testing). Não é o que o CI roda — é o peso do RESTO do diff, a parte que o mapa decide.
  mapfile -t _rest < <(git -C "${ROOT}" -c core.quotepath=off diff --name-only "${rng}" -- 2>/dev/null \
    | grep -vE '^(\.claude/validation/lint-selftest\.sh|\.github/workflows/|ops/testing/)' || true)
  if [ "${#_rest[@]}" -eq 0 ]; then nr="0"; why_r="só infra"
  else
    _ro="$(bash "${SUT}" --dry-run --affected "${_rest[@]}" 2>&1)"
    _rl="$(printf '%s\n' "${_ro}" | sed -n 's/^dry-run: famílias=\([^ ]*\) jobs=.*/\1/p' | head -1)"
    if [ "${_rl}" = "<todas>" ]; then nr="${TOTAL}"; why_r="$(printf '%s\n' "${_ro}" | grep -m1 '^  failsafe:' | sed 's/^  failsafe: //' | cut -c1-90)"
    elif [ -n "${_rl}" ]; then nr="$(printf '%s' "${_rl}" | tr ',' '\n' | grep -c . || true)"; why_r="mapa"
    else nr="-"; why_r="sem resposta"; fi
  fi
  # CUSTO ESTIMADO: soma dos segundos por família medidos no runner (selftest-family-times.tsv) — CPU de bancada,
  # não parede (o CI fatia em faixas). Família sem tempo medido conta 0 e isso SUBestima; declarado na saída.
  if [ "${fams}" = "ALL" ]; then sec="$(awk -F'\t' '!/^#/ && $2 ~ /^[0-9]+$/ {s+=$2} END{print s+0}' "${TIMES}")"
  else sec="$(awk -F'\t' -v l=",${fams}," '!/^#/ && $2 ~ /^[0-9]+$/ && index(l, "," $1 ",") {s+=$2} END{print s+0}' "${TIMES}")"; fi
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "${pr}" "${nf}" "${n}" "${level}" "${nr}" "${why_r}" "${reason}" "${sec}" | tee -a "${_work}/rows"
done < "${_work}/ranges"

[ -z "${TSV}" ] || cp "${_work}/rows" "${TSV}"
_dist() {  # $1 = coluna medida, $2 = rótulo da linha de máquina
  awk -F'\t' -v col="$1" -v lab="$2" -v total="${TOTAL}" -v noans="${_noans}" '
    $col ~ /^[0-9]+$/ { v[n++] = $col + 0; if ($4 == "completo") c++; if ($col + 0 == total) a++ }
    END {
      if (n == 0) { printf "#%s n=0\n", lab; exit }
      for (i = 0; i < n; i++) for (j = i + 1; j < n; j++) if (v[j] < v[i]) { t = v[i]; v[i] = v[j]; v[j] = t }
      printf "#%s n=%d p50=%d p90=%d max=%d min=%d completa_ci=%d todas_as_familias=%d sem_resposta=%d total_familias=%d\n", lab, n, v[int((n - 1) * 0.5)], v[int((n - 1) * 0.9 + 0.5)], v[n-1], v[0], c + 0, a + 0, noans, total
    }' "${_work}/rows"
}
_dist 3 REPLAY
_dist 5 REPLAY_SEM_INFRA
_dist 8 REPLAY_SEGUNDOS_CPU

if [ "${STARTUP}" = "1" ]; then
  # ARRANQUE = o cabeçalho da bancada (retrato da árvore + inventário) até a 1ª família, medido rodando a
  # bancada com uma família inexistente (nenhuma roda; só cabeçalho e sumário). Duas formas:
  #   WORKER : o processo `--child` da fila dinâmica, com o retrato e o inventário que o pai lhe passa
  #            (ONION_SELFTEST_SNAPSHOT/INVENTORY_ENV). Bancada que não os lê os ignora e paga tudo — é
  #            assim que a mesma medição serve antes e depois. É o custo de cada worker ANTES da vaga.
  #   SERIAL : a bancada sem pai, com o cache do inventário VAZIO (diretório novo) — o pior caso.
  _snap="${_work}/snap.tar"; mkdir -p "${_work}/inv" "${_work}/cache"
  tar -C "${ROOT}" --warning=no-file-changed -cf "${_snap}" --exclude='__*__.*' --exclude='__*__' .claude docs CLAUDE.md 2>/dev/null || true
  tar -C "${_work}/inv" -xf "${_snap}"
  _env="$(bash "${_work}/inv/.claude/validation/inventory.sh" --env 2>/dev/null || true)"
  _time() {  # $1 = rótulo; o resto = env para a bancada
    local lab="$1" k t0 t1; shift; : > "${_work}/st"
    for (( k=0; k<STARTUP_RUNS; k++ )); do
      t0="$(date +%s.%N)"
      env "$@" ONION_SELFTEST_INVENTORY_CACHE_DIR="${_work}/cache/${lab}-${k}" ONION_SELFTEST_FAMILIES="__replay_none__" bash "${SUT}" >/dev/null 2>&1 || true
      t1="$(date +%s.%N)"
      awk -v a="${t0}" -v b="${t1}" 'BEGIN{printf "%.2f\n", b - a}' >> "${_work}/st"
    done
    sort -n "${_work}/st" | awk -v lab="${lab}" '{v[n++]=$1} END {printf "#STARTUP_%s runs=%d mediana=%.2fs min=%.2fs max=%.2fs\n", lab, n, v[int((n-1)/2)], v[0], v[n-1]}'
  }
  _time WORKER ONION_SELFTEST_CHILD=1 ONION_SELFTEST_SNAPSHOT="${_snap}" ONION_SELFTEST_INVENTORY_ENV="${_env}"
  _time SERIAL
fi
[ "${_noans}" -eq 0 ] || exit 1
exit 0
