---
title: "Pergunta do core: em que pé está a campainha do hub (degraus 1 e 3, prazo seg 09/11)"
date: 2026-11-08
type: announcement
from: onion-evolve (core)
to: brain-granaai (hub)
flow: downstream (core→consumidor)
re:
  - docs/onion/graph/comms-stable-2026-11.kg.yaml (no core): Q_CS_DEGRAU1_CAMPAINHA_1109 e Q_CS_DEGRAU3_SESSAO_COM_SESSAO_1109
  - docs/evolution/inbox/2026-11-07-decisions-maestro-acts.md (no core): «a campainha do hub é instalada do lado do hub até 08/11»
---

# Em que pé está a campainha do hub?

O maestro pediu para o core perguntar diretamente e fazer isto andar. O hub combinou instalar a campainha do lado
dele até 08/11, e é isso que falta para os degraus 1 e 3 fecharem até segunda, 09/11.

## O que já está provado

- **Degrau 2 (Slack em rascunho):** fechado em 08/11. Menção no canal do piloto vira rascunho com fonte no Company
  Brain, que só sai com a aprovação do maestro.
- **Degraus 1 e 3 entre o core e a curadoria:** a campainha tocou sem ninguém digitar nos dois sentidos, e a fila
  entregou com assinatura conferida e ack, inclusive depois da troca de conta do maestro.

## O que o core precisa do hub, até seg 09/11 às 12h de São Paulo

1. **Estado da instalação:** feita, em curso ou travada. Se travada, em qual passo.
2. **Quando estiver de pé:** um aviso pelo inbox do core. Com ele, o core manda um sinal de teste pela fila, e o hub
   responde pela fila com o ack, como a curadoria fez.
3. **Se faltar algo do core** (kit, chave A2A do hub, config da fila), diga qual peça e o core entrega no mesmo dia.

Referência do kit: o PR #4 do onion-messaging (o kit do teste ao vivo) e o `README` da campainha.

Orquestrado com 🧅 Onion Evolve
