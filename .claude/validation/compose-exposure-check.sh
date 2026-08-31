#!/usr/bin/env bash
# compose-exposure-check.sh — emissor/verificador do baseline da REGRA 64 (compose-exposure).
#
# A REGRA 64 (lint-artifacts.sh) reprova compose RASTREADO com porta sem prefixo de bind ou
# segredo em fallback literal — com CATRACA: chave em compose-exposure-baseline.txt é dívida
# LEGADA tolerada (SOFT agregado); chave nova é HARD. Este script é o EMISSOR que o
# regen-baselines.sh resolve por convenção (--emit-baseline + nome do arquivo aqui:
# compose-exposure-baseline.txt).
#
# ⚠️ A RECEITA DA CHAVE (path::sha1(linha-sem-espaços)[:12]) TEM DE SER IDÊNTICA à da função
# check_compose_exposure do lint — a paridade é provada POR EXECUÇÃO na bancada
# (run_compose_exposure_selftests: o que este emissor emite, o lint tolera). Mudou uma, a
# bancada acusa a outra.
#
# Uso:  bash compose-exposure-check.sh --emit-baseline   # chaves do estado atual (dívida do dia)
set -euo pipefail
REPO_ROOT="${REPO_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
[ "${1:-}" = "--emit-baseline" ] || { echo "uso: compose-exposure-check.sh --emit-baseline" >&2; exit 2; }

printf '# Baseline da REGRA 64 — exposições de compose LEGADAS toleradas (PASSIVO; só encolhe).\n'
printf '# Chave: <arquivo>::sha1(linha-sem-espaços)[:12]. Cure a linha e a chave sai junto.\n'
_key() { printf '%s::%s\n' "$1" "$(printf '%s' "$2" | sed 's/[[:space:]]//g' | sha1sum | cut -c1-12)"; }
while IFS= read -r f; do
  [ -f "${REPO_ROOT}/${f}" ] || continue
  while IFS= read -r line; do _key "${f}" "${line#*:}"; done \
    < <(grep -nE '^[[:space:]]*-[[:space:]]*"?[0-9]+:[0-9]+"?[[:space:]]*(#.*)?$' "${REPO_ROOT}/${f}" || true)
  while IFS= read -r line; do _key "${f}" "${line#*:}"; done \
    < <(grep -inE '(PASSWORD|SECRET|TOKEN|_KEY)[A-Z_]*[=:][^#]*\$\{[A-Z_]+:-[^}]+\}' "${REPO_ROOT}/${f}" || true)
done < <(git -C "${REPO_ROOT}" ls-files 'docker-compose*.yml' '*/docker-compose*.yml' 2>/dev/null)
