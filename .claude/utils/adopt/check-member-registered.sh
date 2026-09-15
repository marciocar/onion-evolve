#!/usr/bin/env bash
# check-member-registered.sh — o alvo recém-adotado está no registro da federação?
#
# Uso: check-member-registered.sh <TARGET> [<members.yaml>]
#      rc=0 registrado · rc=3 NÃO registrado (avisa, não aborta) · rc=2 uso/precondição
#
# ══ POR QUE EXISTE ════════════════════════════════════════════════════════════════════════════
# Sinal de campo de um adotante, 2026-09-15: ele foi adotado, recebeu o relatório no `inbound/`, e
# NENHUMA entrada do `members.yaml` apontava para o `local_path` dele. Instalar e registrar são
# passos independentes, e o segundo é ESQUECÍVEL SEM CONSEQUÊNCIA VISÍVEL — a definição de falha
# silenciosa. O adotante mediu e reportou; nenhum gate desta casa tinha acusado.
#
# E a razão de nenhum acusar é instrutiva: a reconciliação `outbox × inbound` do `/meta:co-evolve`
# cruza `outbox/<id>/_processed/` contra o `inbound/` do alvo. Sem entrada no registro não existe
# `outbox/<id>/`, então o `comm -13` compara DOIS CONJUNTOS VAZIOS e sai limpo. A guarda que existia
# detecta *entrega no checkout errado*; não detecta *membro que não existe*. Ausência não dispara
# nada — é preciso perguntar pelo que DEVERIA estar lá.
#
# Consequência prática de ficar fora: o core não tem `local_path` para resolver o `--target` do
# `/meta:co-deliver`, então todo anúncio futuro do CHANGELOG fica SEM DESTINATÁRIO. O adotante
# segue verde, porque o hook dele conta o que CHEGOU, não o que deveria ter chegado.
#
# AVISA, NÃO ABORTA (rc=3): a adoção em si está correta e completa; o que falta é um ato de
# REGISTRO, que envolve julgamento humano (nome neutro sob NDA, papel, id). Abortar a adoção por
# isso puniria o alvo por uma pendência do core.
set -uo pipefail

TARGET="${1:?uso: check-member-registered.sh <TARGET> [<members.yaml>]}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MEMBERS="${2:-$(cd "${HERE}/../../.." && pwd)/docs/evolution/federation/members.yaml}"

[ -d "${TARGET}" ] || { echo "ERRO: alvo inexistente: '${TARGET}'" >&2; exit 2; }
[ -f "${MEMBERS}" ] || { echo "ERRO: registro não encontrado: '${MEMBERS}'" >&2; exit 2; }

# Compara CAMINHO CANÔNICO, não string: `~/x`, `/home/u/x/` e `/home/u/./x` são o mesmo alvo, e um
# registro correto não pode ser lido como ausente por causa de uma barra a mais.
_target="$(cd "${TARGET}" && pwd -P)"
_found=""
while IFS= read -r _lp; do
  [ -n "${_lp}" ] || continue
  _lp="${_lp/#\~/${HOME}}"
  [ -d "${_lp}" ] || continue
  _can="$(cd "${_lp}" 2>/dev/null && pwd -P)" || continue
  [ "${_can}" = "${_target}" ] && { _found=1; break; }
done < <(sed -n 's/^[[:space:]]*local_path:[[:space:]]*"\{0,1\}\([^"]*\)"\{0,1\}[[:space:]]*$/\1/p' "${MEMBERS}")

if [ -n "${_found}" ]; then
  echo "✓ registro da federação: '${_target}' já está no members.yaml"
  exit 0
fi

echo "⚠️  NÃO REGISTRADO na federação: '${_target}' não tem entrada no members.yaml." >&2
echo "    Instalar e registrar são passos independentes, e o 2º é esquecível SEM consequência" >&2
echo "    visível: sem entrada, o core não resolve o --target do /meta:co-deliver e todo anúncio" >&2
echo "    futuro fica SEM DESTINATÁRIO — o alvo segue verde porque conta o que chegou, não o que" >&2
echo "    deveria ter chegado (sinal de campo de um adotante, 2026-09-15)." >&2
echo "    Registre: /meta:federation-member register --id <slug> --target '${_target}'" >&2
echo "    ⚠️ Se o alvo for de cliente sob NDA, avalie NOME NEUTRO no campo 'name' (há precedente)." >&2
exit 3
