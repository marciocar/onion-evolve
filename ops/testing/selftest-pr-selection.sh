#!/usr/bin/env bash
# =============================================================================
# selftest-pr-selection.sh — o NÍVEL PR da bancada em dois níveis (core-only)
#
# POR QUE EXISTE (passo D de D_MERGE_PROCESS_ONION_2026_10, selado pelo maestro em 2026-10-13):
# a decisão D_BANCADA_FAIXAS_E_MAPA (2026-09-03) já dizia "PR = famílias tocadas", e o PR seguia
# rodando a bancada INTEIRA (mediana de 14,8 min, ≥14 auto-rebases por dia, cada um pagando a bancada
# de novo). Sem fila (o repo é de dono User: sem merge_group), o desenho é o de DOIS NÍVEIS:
#   PR   → só as famílias que o diff do PR toca (este script decide);
#   main → a bancada COMPLETA no push, com alarme e PR de revert (main-bench-alarm.sh).
#
# NÃO há mapa novo aqui: a seleção é a do pre-commit (`lint-selftest.sh --affected-range`, derivada do
# corpo de cada família, com o mesmo failsafe). Este script só acrescenta a POLÍTICA do nível PR, que o
# pre-commit não tem:
#   1. label `ci:full` no PR ⇒ completa (o humano pede a garantia inteira);
#   2. o diff toca a bancada ou a infra do CI (`lint-selftest.sh`, `.github/workflows/*`, `ops/testing/*`)
#      ⇒ completa — quem muda o juiz não é julgado só por uma fatia dele;
#   3. o seletor não responde, ou responde fora do formato ⇒ completa (recusa no incerto, nunca vazio).
#
# Uso  : bash ops/testing/selftest-pr-selection.sh --range <base>...<head> [--labels "a,b,c"]
# Saída: três linhas `chave=valor` (prontas para o GITHUB_OUTPUT), e o raciocínio no stderr:
#          nivel=completo|seletivo
#          familias=ALL|f1,f2,…
#          motivo=<uma linha>
# Exit : 0 decidido (inclusive "completo") · 2 uso inválido.
# =============================================================================
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SUT="${ROOT}/.claude/validation/lint-selftest.sh"
RANGE=""; LABELS=""
while [ $# -gt 0 ]; do
  case "$1" in
    --range) shift; RANGE="${1:-}" ;;
    --labels) shift; LABELS="${1:-}" ;;
    -h|--help) sed -n '/^# Uso  :/,/^# Exit :/p' "${BASH_SOURCE[0]}"; exit 0 ;;
    *) echo "selftest-pr-selection: argumento desconhecido '$1'" >&2; exit 2 ;;
  esac
  shift
done
case "${RANGE}" in ""|-*) echo "selftest-pr-selection: --range <base>...<head> obrigatório" >&2; exit 2 ;; esac

_decide() {  # $1=nivel $2=familias $3=motivo
  printf 'nivel=%s\nfamilias=%s\nmotivo=%s\n' "$1" "$2" "$(printf '%s' "$3" | tr '\n\r' '  ')"
  echo "nível PR: $1 — $3" >&2
  exit 0
}

# (1) a label pede a garantia inteira
IFS=',' read -r -a _labels <<< "${LABELS}"
for _l in "${_labels[@]+"${_labels[@]}"}"; do
  [ "${_l}" = "ci:full" ] && _decide completo ALL "label ci:full no PR"
done

# (2) o diff toca a bancada ou a infra do CI. Lido AQUI, à parte, porque a regra do BLOCO do pre-commit
#     estreita lint-selftest.sh às famílias do bloco mudado — e no nível PR quem muda o juiz roda tudo.
if ! _diff="$(git -C "${ROOT}" -c core.quotepath=off diff --name-status -M --diff-filter=ACMRDT "${RANGE}" -- 2>&1)"; then
  _decide completo ALL "o diff do range ${RANGE} não pôde ser lido: $(printf '%s' "${_diff}" | head -c 120)"
fi
while IFS=$'\t' read -r _st _p1 _p2; do
  for _p in "${_p1:-}" "${_p2:-}"; do
    case "${_p}" in
      .claude/validation/lint-selftest.sh|.github/workflows/*|ops/testing/*)
        _decide completo ALL "${_p} é a bancada ou a infra do CI" ;;
    esac
  done
done <<< "${_diff}"

# (3) a seleção do pre-commit, pelo range. O formato lido é o `dry-run: famílias=…` da bancada.
[ -f "${SUT}" ] || _decide completo ALL "a bancada (${SUT#"${ROOT}/"}) não existe — não sei selecionar"
_out="$(LC_ALL=C bash "${SUT}" --dry-run --affected-range "${RANGE}" 2>&1)"; _rc=$?
printf '%s\n' "${_out}" | grep -E '^(faixa|  failsafe|  bloco|  empacotado)' >&2 || true
_line="$(printf '%s\n' "${_out}" | grep -m1 '^dry-run: famílias=' || true)"
_fams="$(printf '%s' "${_line}" | sed -n 's/^dry-run: famílias=\([^ ]*\) jobs=.*/\1/p')"
if [ "${_rc}" -ne 0 ] || [ -z "${_fams}" ]; then
  _decide completo ALL "o seletor não respondeu no formato esperado (rc=${_rc}) — recusa no incerto"
fi
if [ "${_fams}" = "<todas>" ]; then
  _why="$(printf '%s\n' "${_out}" | grep -m1 '^  failsafe:' | sed 's/^  failsafe: //')"
  _decide completo ALL "failsafe do mapa: ${_why:-motivo não impresso}"
fi
case "${_fams}" in *[!a-z0-9_,]*) _decide completo ALL "seleção com nome de família fora do alfabeto: ${_fams:0:80}" ;; esac
_n="$(printf '%s' "${_fams}" | tr ',' '\n' | grep -c .)"
_decide seletivo "${_fams}" "${_n} família(s) pelo mapa família→arquivo do diff ${RANGE}"
