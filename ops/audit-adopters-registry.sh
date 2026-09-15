#!/usr/bin/env bash
# audit-adopters-registry.sh — adotantes NO DISCO × registro da federação.
#
# Uso: audit-adopters-registry.sh [<raiz-de-busca>=$HOME] [<members.yaml>]
#      rc=0 todos registrados · rc=3 há adotante fora do registro · rc=2 precondição
#
# ══ POR QUE É `ops/` E NÃO REGRA DO LINT ══════════════════════════════════════════════════════
# Porque ele VARRE O DISCO do operador, e uma regra HARD que depende de `$HOME` reprovaria no CI,
# onde `/home/marcio` não existe. Guarda que só passa na máquina de uma pessoa não é guarda — é
# armadilha para todo mundo. Fica aqui, core-only, como o `verify-adopter-gate.sh`, e roda por
# decisão do maestro ou ao fim de uma adoção.
#
# ══ O QUE ELE ENXERGA QUE NADA MAIS ENXERGA ═══════════════════════════════════════════════════
# A ausência. A reconciliação `outbox × inbound` do `/meta:co-evolve` compara o que o core diz ter
# transportado contra o que chegou — e para um membro que NÃO EXISTE no registro ela compara dois
# conjuntos vazios e sai limpa. Toda guarda desta casa pergunta pelo que ESTÁ; esta pergunta pelo
# que DEVERIA ESTAR, e é por isso que ela precisa de uma fonte independente: o disco.
#
# Sinal de campo de um adotante, 2026-09-15 — ele mesmo mediu que não estava no registro, depois de
# ser adotado e receber o relatório. Nenhum gate havia acusado.
set -uo pipefail

RAIZ="${1:-${HOME}}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE="$(cd "${HERE}/.." && pwd)"
MEMBERS="${2:-${CORE}/docs/evolution/federation/members.yaml}"
CHECK="${CORE}/.claude/utils/adopt/check-member-registered.sh"

[ -d "${RAIZ}" ]    || { echo "ERRO: raiz inexistente: '${RAIZ}'" >&2; exit 2; }
[ -f "${MEMBERS}" ] || { echo "ERRO: registro não encontrado: '${MEMBERS}'" >&2; exit 2; }
[ -f "${CHECK}" ]   || { echo "ERRO: helper ausente: '${CHECK}'" >&2; exit 2; }

echo "══ ADOTANTES NO DISCO × REGISTRO DA FEDERAÇÃO ══"
echo "   raiz: ${RAIZ}   registro: ${MEMBERS#"${CORE}/"}"
echo

_n=0 _unregistered=0
# O marcador de adotante é o STAMP, não o nome do diretório: `.claude/.onion-version` com papel que
# não seja `source`. Nome de pasta é declaração; o stamp é o que o transporte escreveu.
while IFS= read -r _stamp; do
  _repo="$(cd "$(dirname "$(dirname "${_stamp}")")" && pwd -P)"
  _role="$(awk '/^role:/{print $2; exit}' "${_stamp}" 2>/dev/null)"
  [ "${_role}" = "source" ] && continue          # o core não se registra como membro de si
  _n=$(( _n + 1 ))
  if bash "${CHECK}" "${_repo}" "${MEMBERS}" >/dev/null 2>&1; then
    printf '  ✓ %-46s [%s]\n' "${_repo#"${RAIZ}"/}" "${_role:-?}"
  else
    printf '  ✗ %-46s [%s]  FORA DO REGISTRO\n' "${_repo#"${RAIZ}"/}" "${_role:-?}"
    _unregistered=$(( _unregistered + 1 ))
  fi
done < <(find "${RAIZ}" -maxdepth 3 -name '.onion-version' -path '*/.claude/*' 2>/dev/null | sort)

echo
if [ "${_n}" -eq 0 ]; then
  echo "⚠️  NENHUM adotante encontrado sob '${RAIZ}' — raiz errada, ou profundidade insuficiente?" >&2
  echo "    (vazio NÃO é o mesmo que 'todos registrados': confira a raiz antes de concluir.)" >&2
  exit 3
fi
if [ "${_unregistered}" -eq 0 ]; then
  echo "✓ ${_n} adotante(s) no disco, todos no registro."
  exit 0
fi
echo "✗ ${_unregistered} de ${_n} adotante(s) FORA do registro — anúncios futuros ficam sem destinatário." >&2
echo "  Registre cada um: /meta:federation-member register --id <slug> --target <path>" >&2
exit 3
