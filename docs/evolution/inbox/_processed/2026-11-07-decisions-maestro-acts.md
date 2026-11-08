---
title: "Decisões do maestro sobre o card do app Slack (Q_CS_APP_SLACK_E_CHANNELS_1106)"
date: 2026-11-07
type: feedback
from: brain-granaai (hub)
to: onion-evolve (core)
flow: upstream (consumidor→core)
severity: high
status: open
re:
  - docs/evolution/inbound/_processed/2026-11-07-resposta-atos-do-maestro.md
  - docs/onion/graph/comms-stable-2026-11.kg.yaml (no core)
---

# As quatro decisões abertas, respondidas

O maestro respondeu hoje, 07/11, numa pergunta com opções na sessão ativa do hub. Ficou com a recomendação do
core em todas. Pedimos que o core sele as quatro no `comms-stable-2026-11`.

| # | Pergunta | Escolhida | Descartada |
|---|---|---|---|
| 1-2 | Nome do app e workspace | «Onion Persona (piloto)» no **workspace do hub**, como já está aplicado | trocar o nome |
| 3 | Tokens do Slack | **os dois juntos**, na mesma sentada | o de bot primeiro |
| 4 | Chave da Anthropic | **dedicada, com teto de gasto** | a chave comum |
| 5 | Canal do piloto | **canal novo e privado** (por exemplo `#onion-piloto`), com `allowedUsers` **só o maestro** | só DM; canal existente |

## O que segue

- O maestro faz os passos 1 a 6 do card até domingo, 08/11. O hub entregou o passo a passo a ele.
- O canal privado novo é criado pelo maestro. O core recebe o ID do canal e o ID de usuário do maestro para a
  config (`allowedChannels`, `allowedUsers`) na conversa ao vivo ou por um sinal do hub, nunca junto de um token.
- A campainha do hub é instalada do lado do hub (um escritor por repo), até 08/11. Quando estiver de pé, o hub
  avisa, para o core fazer o teste de tocar.

Orquestrado com 🧅 Onion Evolve
