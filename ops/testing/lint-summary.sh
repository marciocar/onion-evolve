#!/usr/bin/env bash
# =============================================================================
# lint-summary.sh — a saída do lint vira sumário legível no CI (irmão do selftest-summary.sh)
#
# Uso : bash ops/testing/lint-summary.sh --log <ABS.log> [--titulo T] [--run-url URL]
#       → markdown no stdout, para `>> "$GITHUB_STEP_SUMMARY"`
#
# POR QUE EXISTE, e é o mesmo motivo do irmão
#   A 1ª versão deste sumário era shell EMBUTIDO no `onion-validate.yml`. Shell em YAML é a única
#   peça do gate que nenhuma guarda exercita: não roda local, não entra na bancada, e só se
#   descobre quebrada no dia em que alguém precisa dela para entender uma falha.
#
# O DEFEITO QUE ELE NASCE CURANDO (achado da passada adversarial, 2026-09-09)
#   A versão embutida decidia o ícone por `grep -c VIOLATION|Violações HARD: [1-9]`. Um log
#   TRUNCADO — o lint abortou no meio, que é o caso de OOM, SIGPIPE e worker morto, os três já
#   medidos nesta casa — não tem linha de VIOLATION nem bloco de sumário. Contagem zero, ícone
#   ✅. VERDE SOBRE EXECUÇÃO ABORTADA, no artefato que existe para contar a verdade do gate.
#
#   A cura não é contar melhor: é exigir PROVA POSITIVA de que o lint terminou. O bloco
#   `=== Sumário ===` só é escrito no fim; sem ele, o desfecho é `⊘ NÃO MEDIDO`, nunca ✅.
#   Ausência de violação e ausência de execução produzem o mesmo zero — e só o marcador de
#   término as separa.
#
# ELE REPORTA, NÃO JULGA. Sai 0 sempre que conseguiu dizer a verdade, inclusive quando a verdade
#   é "não foi medido". O veredito é do passo do lint; dois juízes para o mesmo fato criam o dia
#   em que discordam e ninguém sabe qual vale.
# =============================================================================
set -euo pipefail

LOG=""; TITULO="Lint determinístico de artefatos"; RUN_URL=""
while [ $# -gt 0 ]; do
  case "$1" in
    --log)      shift; LOG="${1:-}" ;;
    --log=*)    LOG="${1#*=}" ;;
    --titulo)   shift; TITULO="${1:-}" ;;
    --titulo=*) TITULO="${1#*=}" ;;
    --run-url)  shift; RUN_URL="${1:-}" ;;
    --run-url=*) RUN_URL="${1#*=}" ;;
    *) echo "lint-summary: arg desconhecido: $1 (use --log <ABS.log> [--titulo] [--run-url])" >&2; exit 2 ;;
  esac
  shift
done

[ -n "${LOG}" ] || { echo "lint-summary: --log <ABS.log> é obrigatório" >&2; exit 2; }

_not_measured() {   # $1 = a suspeita, nomeada
  printf '## ⊘ %s — NÃO MEDIDO\n\n' "${TITULO}"
  printf '**Não há execução completa para somar.** Isto NÃO é "zero violações": é ausência de medição.\n\n'
  printf -- '- causa provável: %s\n' "$1"
  printf -- '- log esperado em: `%s`\n' "${LOG}"
  printf -- '- lint que morre no meio já foi medido aqui por OOM, SIGPIPE e worker morto\n'
  [ -n "${RUN_URL}" ] && printf -- '- run: %s\n' "${RUN_URL}"
  printf '\n> Um sumário que imprimisse ✅ aqui seria verde sobre execução abortada.\n'
}

if [ ! -f "${LOG}" ]; then
  _not_measured "o arquivo de log não existe — o passo do lint não chegou a rodar"
  exit 0
fi

# A PROVA POSITIVA DE TÉRMINO. O lint só escreve este bloco no fim; sem ele o processo morreu
# antes de somar, e nenhuma contagem sobre o log parcial significa alguma coisa.
if ! grep -q '^=== Sumário ===' "${LOG}"; then
  _not_measured "o log existe mas NÃO tem o bloco \`=== Sumário ===\` — o lint abortou antes de somar"
  exit 0
fi

HARD="$(sed -n 's/^  Violações HARD *: *\([0-9]\{1,\}\).*/\1/p' "${LOG}" | head -1)"
SOFT="$(sed -n 's/^  Violações SOFT *: *\([0-9]\{1,\}\).*/\1/p' "${LOG}" | head -1)"

# O bloco existe mas o campo não parseia: também é NÃO MEDIDO, não zero. A forma do sumário
# mudou, e inventar um número a partir de um formato que não se reconhece é o defeito de novo.
if [ -z "${HARD}" ]; then
  _not_measured "o bloco \`=== Sumário ===\` existe mas \`Violações HARD\` não parseia — o formato mudou"
  exit 0
fi

if [ "${HARD}" -gt 0 ]; then ICONE="❌"; else ICONE="✅"; fi
printf '## %s %s\n\n' "${ICONE}" "${TITULO}"
printf '| HARD | SOFT |\n|-----:|-----:|\n| **%s** | %s |\n\n' "${HARD}" "${SOFT:-0}"

if grep -q '^VIOLATION' "${LOG}"; then
  printf '<details><summary>violações nomeadas</summary>\n\n```\n'
  grep '^VIOLATION' "${LOG}" | cut -c1-300
  printf '```\n\n</details>\n\n'
fi

printf '<sub>Gerado por `ops/testing/lint-summary.sh` a partir do log do lint — o ícone exige o\n'
printf 'bloco de término, então execução abortada nunca sai verde.</sub>\n'
[ -n "${RUN_URL}" ] && printf '\n<sub>run: %s</sub>\n' "${RUN_URL}"
exit 0
