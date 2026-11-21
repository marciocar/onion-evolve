---
branch: docs/seal-chat-channel-contract-1121
pr: pendente
date: 2026-11-21
reviewed_diff_sha256: pendente
findings_total: 2
findings_real: 2
findings_blocking: 0
tokens: 0
duration_min: 5
findings_fixed: 0
verdict: APPROVED
elenxo: false
reviewer: self
nota: "passada da própria sessão sobre um diff de 2 nós e 2 arestas escritos pelo selador (kg-decide-seal.sh, radar exit 0); tokens não medidos"
---

# Passada adversarial: `docs/seal-chat-channel-contract-1121`

## O que muda

Dois nós `decision` `done` no grafo de selos de coordenação, escritos pelo selador com o testemunho do maestro em
2026-11-21: o contrato SDAAL de canal de conversa (síntese do Delphi de 4 sessões, unânime) e o uso do WAHA só em
canais internos e com sócios, com o cliente final depois pela Cloud API oficial. Duas arestas `TRACES_TO`.

## Achados

1. **A síntese inteira do Delphi não está no grafo.** O label resume (5 campos, 1º adapter WAHA, sem Synapse), mas as
   regras do núcleo (guarda de vazamento, dedupe pelo id do provedor, retenção, auditoria, campo de latência e
   «serviu?») vivem só no estado do Delphi, fora do git. Real, não bloqueia: o PR do contrato (`.claude/utils/chat/`)
   escreve a síntese no repo e cita estes nós.
2. **A aresta para `D_HUB_AWS_SHADOW_5_BUSINESS_DAYS_1120` é de proximidade, não de causa.** O contrato nasceu do
   pedido do maestro no canal com os sócios, não da sombra AWS. Real, não bloqueia: o PR do contrato liga o nó à
   origem certa.

## Mutantes

Não se aplica: o diff não muda guarda nem script.

## Limites declarados

- Achados 1 e 2 ficam para o PR do contrato, que é o próximo da fila do core.
- Revisão da própria sessão, sem revisor isolado: o diff é só testemunho gravado pelo selador.
