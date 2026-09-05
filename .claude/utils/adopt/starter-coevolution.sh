#!/usr/bin/env bash
# =============================================================================
# starter-coevolution.sh — cria os DOIS canais do doc-bridge no alvo da adoção
#
# POR QUÊ : `inbox/` é o canal UPSTREAM (o consumidor sinaliza o core) e `inbound/` é o DOWNSTREAM
#           (relatório de adoção/update + anúncios do core). Ambos com `_processed/` para que
#           lido/não-lido seja git-visível, sem state file. O hook "you have mail" conta o 1º nível.
#           ⚠️ NUNCA escrever no `inbox/` do alvo em nome do core: lá é o outbox DELE para o core.
#
# COMO    : idempotente; nunca clobba canal em uso. Confere o próprio efeito — `exit 0` é declaração
#           do script sobre si, e verificar é contar o que ele produziu.
#
# USO     : starter-coevolution.sh <DEST>
# =============================================================================
set -u
DEST="${1:?uso: starter-coevolution.sh <DEST>}"
E="${DEST}/docs/evolution"
for ch in inbox inbound; do
  mkdir -p "${E}/${ch}/_processed"
  [ -f "${E}/${ch}/_processed/.gitkeep" ] || : > "${E}/${ch}/_processed/.gitkeep"
done
if [ ! -f "${E}/README.md" ]; then
  cat > "${E}/README.md" <<'PTR'
# Co-evolução (consumidor)

Este repo é **CONSUMIDOR** do Onion. O protocolo canônico (3 fluxos) vive no core
(`onion-evolve/docs/evolution/`). Canais: `inbox/` para sinalizar o core (upstream) e `inbound/`
para receber relatórios de update/anúncios do core (downstream). Rode `/meta:co-evolve` para ler/gerenciar.
PTR
fi
[ -d "${E}/inbox/_processed" ] && [ -d "${E}/inbound/_processed" ] && [ -f "${E}/README.md" ] && exit 0
echo "starter-coevolution: canais incompletos em ${E}" >&2; exit 1
