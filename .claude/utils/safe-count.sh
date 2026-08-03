#!/usr/bin/env bash
# =============================================================================
# safe-count.sh — contagem que NÃO confunde "zero" com "falhou"
#
# O PROBLEMA (medido, não teórico): `find X 2>/dev/null | wc -l` devolve `0` tanto
# quando X está vazio quanto quando X NÃO EXISTE ou o comando quebrou. O `2>/dev/null`
# é reflexo de shell — silencia ruído — e nesse caminho converte ERRO em NÚMERO.
#
# Em 2026-08-03 a guarda anti-fail-open do harness (.claude/hooks/bash-empty-result-guard.sh)
# pegou esse mesmo padrão SEIS vezes numa única sessão, com a mesma pessoa, minutos depois
# de cada correção — três do detector `2>/dev/null`-antes-de-contagem e três do `$?`-depois-
# de-pipe. A conclusão não é "faltou atenção": é que a guarda avisa DEPOIS (PostToolUse) e
# não existia uma forma CERTA e CURTA de fazer. Este arquivo é essa forma.
#   [[fix-must-become-mechanism]] — cura por mecanismo, não por disciplina.
#
# USO
#   source .claude/utils/safe-count.sh
#   n=$(count_files docs/onion '*.md')   || exit 1   # alvo ausente => exit 2 + stderr
#   n=$(count_matches 'REGRA' arquivo.sh) || exit 1
#   n=$(count_lines arquivo.txt)          || exit 1
#
# CONTRATO
#   · stdout = SÓ o número (consumível por $( ))
#   · alvo ausente / comando quebrado => exit 2 + mensagem em STDERR (nunca "0" silencioso)
#   · vazio-de-verdade => `0` com exit 0 — a distinção que o `2>/dev/null` apaga
#
# Determinístico, sem rede, sem LLM. Exercitado por lint-selftest.sh.
# =============================================================================

# Conta ARQUIVOS sob um diretório. $1=dir  $2=glob de nome (opcional, default '*')
count_files() {
  local dir="${1:-}" pat="${2:-*}"
  if [ -z "${dir}" ]; then
    printf 'safe-count: count_files exige um diretório\n' >&2; return 2
  fi
  if [ ! -d "${dir}" ]; then
    printf 'safe-count: DIRETÓRIO AUSENTE: %s (isto NÃO é zero — é erro)\n' "${dir}" >&2
    return 2
  fi
  find "${dir}" -type f -name "${pat}" -print | wc -l | tr -d ' '
}

# Conta LINHAS que casam um padrão ERE em um ou mais arquivos. $1=padrão  $2..=arquivos
count_matches() {
  local pat="${1:-}"; shift || true
  if [ -z "${pat}" ] || [ "$#" -eq 0 ]; then
    printf 'safe-count: count_matches exige <padrão> <arquivo...>\n' >&2; return 2
  fi
  local f
  for f in "$@"; do
    if [ ! -f "${f}" ]; then
      printf 'safe-count: ARQUIVO AUSENTE: %s (isto NÃO é zero — é erro)\n' "${f}" >&2
      return 2
    fi
  done
  # grep sai 1 quando não casa nada — é resultado legítimo (zero), não falha.
  local n; n="$(grep -hcE -- "${pat}" "$@" | awk '{s+=$1} END{print s+0}')"
  printf '%s\n' "${n}"
}

# Conta LINHAS de um arquivo. $1=arquivo
count_lines() {
  local f="${1:-}"
  if [ -z "${f}" ] || [ ! -f "${f}" ]; then
    printf 'safe-count: ARQUIVO AUSENTE: %s (isto NÃO é zero — é erro)\n' "${f:-<vazio>}" >&2
    return 2
  fi
  wc -l < "${f}" | tr -d ' '
}

# Executado direto (não sourced) → auto-demonstração dos 3 desfechos.
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  printf 'safe-count.sh — os três desfechos que o 2>/dev/null apaga:\n\n'
  d="$(mktemp -d)"
  printf '  (1) vazio de verdade  : '; count_files "${d}" '*.md'; printf '      exit=%s\n' "$?"
  printf '  (2) alvo ausente      : '; count_files "${d}/nao-existe" '*.md' || printf '      exit=%s (erro, não zero)\n' "$?"
  printf 'x\ny\n' > "${d}/a.md"
  printf '  (3) contagem real     : '; count_files "${d}" '*.md'; printf '      exit=%s\n' "$?"
  rm -rf "${d}"
fi
