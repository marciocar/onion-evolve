#!/usr/bin/env bash
# =============================================================================
# preflight-shadow.sh — o MODO-SOMBRA do pré-voo: mede a lacuna entre o que o pré-voo rodou e o que o CI vai rodar
#
# POR QUÊ (SAC-141, D_PRE_VOO_SEMPRE_E_SOMBRA, 2026-10-15): 20 das 29 reprovações do CI de 10-07 a 10-14 foram
#   de famílias que o pré-voo não seleciona (ele lê os blocos mudados da bancada, não o mapa família→arquivo).
#   Rodar o mapa inteiro no fechamento custa de 7 a 30 min, mais que o CI. Para decidir se as famílias BARATAS
#   do mapa (8 das 20 em ~40 s, na medição) se pagam, é preciso o dado de cada fechamento real, não a simulação.
#   Esta sombra grava esse dado; o `report` é o consumidor dela.
#
# record <famílias do pré-voo>  — roda o seletor do nível PR do CI (`selftest-pr-selection.sh`) sobre
#   merge-base...HEAD e grava uma linha TSV em <git-common-dir>/onion-preflight-shadow.tsv:
#     data · branch · head · nível do CI · nº famílias do CI · nº do pré-voo · famílias do CI fora do pré-voo
#   NUNCA muda o resultado de quem chama: sai sempre 0, e a falha vira "sombra indisponível" no stderr.
# report [--days N]  — resume a sombra: fechamentos, lacuna mediana, e por branch se o CI da bancada reprovou
#   (lido do forge pelo `gh`, quando há). É a entrada da decisão que ficou para depois.
#
# Bancada: run_preflight_shadow_selftests em .claude/validation/lint-selftest.sh.
# =============================================================================
set -uo pipefail

LOG="$(git rev-parse --git-common-dir 2>/dev/null)/onion-preflight-shadow.tsv"

_record() {
  local pf="${1:-}" base head sel lvl ci br gap n_ci n_pf
  base="$(git merge-base origin/main HEAD 2>/dev/null)" || { echo "sombra indisponível: sem merge-base com origin/main" >&2; return 0; }
  head="$(git rev-parse HEAD 2>/dev/null)"; br="$(git branch --show-current 2>/dev/null)"
  [ -f ops/testing/selftest-pr-selection.sh ] || { echo "sombra indisponível: seletor do CI ausente" >&2; return 0; }
  sel="$(bash ops/testing/selftest-pr-selection.sh --range "${base}...${head}" 2>/dev/null)" \
    || { echo "sombra indisponível: o seletor do CI falhou" >&2; return 0; }
  lvl="$(sed -n 's/^nivel=//p' <<< "${sel}")"; ci="$(sed -n 's/^familias=//p' <<< "${sel}")"
  [ -n "${lvl}" ] && [ -n "${ci}" ] || { echo "sombra indisponível: o seletor respondeu fora do formato" >&2; return 0; }
  n_pf="$(tr ',' '\n' <<< "${pf}" | grep -c .)"
  if [ "${ci}" = ALL ]; then
    n_ci=ALL; gap=ALL
  else
    n_ci="$(tr ',' '\n' <<< "${ci}" | grep -c .)"
    gap="$(comm -23 <(tr ',' '\n' <<< "${ci}" | grep . | sort -u) <(tr ',' '\n' <<< "${pf}" | grep . | sort -u) | paste -sd, -)"
  fi
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "${br}" "${head}" "${lvl}" "${n_ci}" "${n_pf}" "${gap:--}" >> "${LOG}" 2>/dev/null \
    || { echo "sombra indisponível: não gravei ${LOG}" >&2; return 0; }
  if [ "${gap}" = ALL ]; then echo "sombra: o CI vai rodar a bancada COMPLETA (${lvl}); o pré-voo rodou ${n_pf} família(s)"
  else echo "sombra: o CI vai rodar ${n_ci} família(s); o pré-voo rodou ${n_pf}; fora do pré-voo: $(tr ',' '\n' <<< "${gap:-}" | grep -c .)"; fi
  return 0
}

_report() {
  local days=14
  [ "${1:-}" = --days ] && days="${2:-14}"
  [ -s "${LOG}" ] || { echo "sombra: nenhum fechamento gravado ainda (${LOG})"; return 0; }
  local since; since="$(date -u -d "${days} days ago" +%Y-%m-%dT%H:%M:%SZ)"
  awk -F'\t' -v s="${since}" '$1 >= s' "${LOG}" > "${LOG}.win"
  local n; n="$(grep -c . "${LOG}.win")"
  echo "# sombra do pré-voo · últimos ${days} dia(s) · ${n} fechamento(s)"
  [ "${n}" -gt 0 ] || { rm -f "${LOG}.win"; return 0; }
  awk -F'\t' '{ if ($7=="ALL") full++; else { g=($7=="-")?0:split($7,a,","); print g > "/dev/stderr" } } END { printf "completa no CI: %d\n", full+0 }' "${LOG}.win" 2> "${LOG}.gaps"
  if [ -s "${LOG}.gaps" ]; then
    echo "lacuna (famílias do CI fora do pré-voo), mediana: $(sort -n "${LOG}.gaps" | awk '{a[NR]=$1} END {print a[int((NR+1)/2)]}')"
  fi
  echo
  echo "| branch | fechamentos | última lacuna | bancada do CI |"
  echo "|---|---|---|---|"
  local br k last ci
  for br in $(cut -f2 "${LOG}.win" | sort -u); do
    k="$(awk -F'\t' -v b="${br}" '$2==b' "${LOG}.win" | grep -c .)"
    last="$(awk -F'\t' -v b="${br}" '$2==b {g=$7} END {print g}' "${LOG}.win")"
    ci="não lido"
    if command -v gh >/dev/null 2>&1; then
      ci="$(gh run list --workflow onion-selftest.yml --branch "${br}" --limit 20 --json conclusion \
            --jq '[.[].conclusion] | (map(select(.=="failure"))|length|tostring) + " reprovado(s) de " + (length|tostring)' 2>/dev/null)" || ci="gh falhou"
    fi
    printf '| %s | %s | %s | %s |\n' "${br}" "${k}" "$(cut -c1-80 <<< "${last}")" "${ci:-gh falhou}"
  done
  rm -f "${LOG}.win" "${LOG}.gaps"
}

case "${1:-}" in
  record) shift; _record "${1:-}" ;;
  report) shift; _report "$@" ;;
  *) echo "uso: preflight-shadow.sh record <famílias> | report [--days N]" >&2; exit 2 ;;
esac
exit 0
