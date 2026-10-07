#!/usr/bin/env bash
# =============================================================================
# remeasure-hard.sh — o lint do ALVO, re-medido DEPOIS do merge, antes de qualquer relatório
#
# POR QUE EXISTE (sinal de campo de um hub, 2026-09-30, re-medido em 2026-10-07): um `--update` declarou
# "0 HARD" no relatório e o alvo chegou com 1 HARD (o inventário). O número vinha da memória da sessão,
# não de uma medição — o merge da vendor muda o que o lint vê, e ninguém o rodava de novo depois. O
# relatório downstream é a única coisa que a sessão do adotante lê do update; um número declarado ali é
# a classe "exit code não é a verificação" ([[exit-code-nao-e-a-verificacao]]).
#
# USO  : remeasure-hard.sh <TARGET>
# SAÍDA: `HARD medido: N` + uma linha por violação HARD (do ONION_LINT_HARD_FILE do lint do alvo)
# EXIT : 0 = zero HARD · 1 = há HARD (liste no relatório) · 3 = não pude medir (declare NÃO MEDIDO)
# =============================================================================
set -uo pipefail
T="${1:?uso: remeasure-hard.sh <TARGET>}"
LINT="${T}/.claude/validation/lint-artifacts.sh"
[ -f "${LINT}" ] || { echo "HARD NÃO MEDIDO: ${T} não tem o lint do Onion (${LINT})." >&2; exit 3; }
grep -q 'ONION_LINT_HARD_FILE' "${LINT}" \
  || { echo "HARD NÃO MEDIDO: o lint de ${T} é anterior ao ONION_LINT_HARD_FILE — não sabe nomear as violações." >&2; exit 3; }

hard="$(mktemp)"; trap 'rm -f "${hard}"' EXIT
( cd "${T}" && ONION_LINT_HARD_FILE="${hard}" bash "${LINT}" >/dev/null 2>&1 ); lint_rc=$?
n="$(grep -c '^VIOLATION:' "${hard}" 2>/dev/null)" || n=0
# lint reprovando sem nenhuma linha no arquivo = não foi o HARD que reprovou, foi o lint que quebrou:
# dizer "0 HARD" aqui seria exatamente o número declarado que este script existe para impedir.
if [ "${lint_rc}" -ne 0 ] && [ "${n}" -eq 0 ]; then
  echo "HARD NÃO MEDIDO: o lint de ${T} saiu rc=${lint_rc} sem nomear violação — ele quebrou, não reprovou." >&2
  exit 3
fi
echo "HARD medido: ${n}"
[ "${n}" -eq 0 ] && exit 0
sed 's/^VIOLATION: /  · /' "${hard}"
exit 1
