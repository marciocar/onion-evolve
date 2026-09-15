#!/usr/bin/env bash
# emit-licenses.sh — entrega as licenças do Onion no alvo, com NOME PRÓPRIO.
#
# Uso: emit-licenses.sh <DEST> [SOURCE_ROOT]
#
# ══ POR QUE `LICENSE-ONION` E NÃO `LICENSE` ═══════════════════════════════════════════════════
# Um `LICENSE` na raiz é, por convenção universal, o instrumento que rege O REPOSITÓRIO INTEIRO —
# inclusive o código que o cliente ainda vai escrever ali. Entregar o MIT do core sob esse nome
# DECLARA a titularidade do autor do core sobre o trabalho do adotante.
#
# É a imagem espelhada exata da catástrofe revertida em 2026-09-14: lá o cliente PERDIA o LICENSE
# dele por sobrescrita; aqui ele nunca teve um, e o que ganha afirma o oposto do pretendido. O
# `.env.example` não serve de analogia — arquivo de exemplo na raiz é inerte, `LICENSE` é
# dispositivo legal.
#
# O nome próprio resolve os dois lados de uma vez:
#   · não reivindica o repositório do adotante — diz pelo nome a que se refere;
#   · não colide com o `LICENSE` dele, então NÃO PRECISA de never-clobber. Não há o que clobrar,
#     e some junto o sidecar `.onion` que a 2ª adoção sobrescrevia em silêncio.
# Sobrescrever a nossa própria entrega com a nossa versão mais nova é o comportamento CERTO — é o
# que um update faz.
#
# ══ POR QUE HELPER, E NÃO DUAS CÓPIAS DO BLOCO ════════════════════════════════════════════════
# A adoção e o `--update` invocam AMBOS o «Procedimento de Configuração pós-cópia», e é de lá que
# isto é chamado. MEDIDO em 2026-09-15: a 1ª versão desta cura vivia só no Procedimento de CÓPIA
# SEGURA, que o `--update` NÃO invoca — e `grep -in 'licenç'` no adopt.md devolvia UMA ocorrência.
# A cura não alcançava NENHUM dos adotantes já existentes, que eram a justificativa dela inteira.
# Um implementador, dois chamadores: a 2ª cópia não pode driftar porque não existe.
set -euo pipefail

DEST="${1:-}"
SRC="${2:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
[ -n "${DEST}" ] && [ -d "${DEST}" ] || { echo "uso: emit-licenses.sh <DEST> [SOURCE_ROOT]" >&2; exit 2; }

# <arquivo no core>:<nome no alvo>. O sufixo `-ONION` é o que impede a reivindicação.
_emitted=0
for _pair in "LICENSE:LICENSE-ONION" "LICENSE-DOCS:LICENSE-ONION-DOCS"; do
  _src="${_pair%%:*}"; _dst="${_pair##*:}"
  # sem pipe para `grep -q`: a corrida de EPIPE já produziu HARD espúrio nesta casa (2026-09-14)
  _lt="$(git -C "${SRC}" ls-tree HEAD -- "${_src}" 2>/dev/null || true)"
  [ -n "${_lt}" ] || continue
  git -C "${SRC}" show "HEAD:${_src}" > "${DEST}/${_dst}"
  _emitted=$((_emitted + 1))
done

# FAIL-LOUD: o core TEM as duas. Zero emitidas significa que o SOURCE_ROOT está errado ou o repo
# perdeu as licenças — e silêncio aqui seria o adotante nascendo sem aviso de licença outra vez.
[ "${_emitted}" -gt 0 ] || { echo "ERRO: nenhuma licença emitida — '${SRC}' não tem LICENSE no HEAD" >&2; exit 3; }
echo "  ✓ ${_emitted} licença(s) emitida(s) no alvo (LICENSE-ONION, LICENSE-ONION-DOCS)"
