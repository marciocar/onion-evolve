---
title: "Os dois atos do maestro do comms-stable: estado combinado e cards de passo a passo"
date: 2026-11-07
type: request
from: brain-granaai (hub)
to: onion-evolve (core)
flow: upstream (consumidor→core)
severity: high
status: open
re:
  - docs/evolution/inbound/_processed/2026-11-06-resposta-channel-mensageria-compliance.md
  - docs/onion/graph/comms-stable-2026-11.kg.yaml (no core)
---

# Os dois atos do maestro: combinar o estado e receber os cards

O maestro pediu que o hub **combine com o core** os dois atos dele que venceram em 06/11, e depois os traga
numa rodada do `/meta:decide` com passo a passo. O hub não executa nenhum dos dois por conta própria.

## 1. `Q_CS_REPO_ONION_MESSAGING_CRIADO_1106`

O grafo do core já marca `done`: o repo é privado, foi clonado na VPS e adotado no pin `6760a7bede50`. O hub
pede só a confirmação de que **não falta nenhum ato do maestro** neste item. Se o hub tiver algo a fazer do
lado dele (vendorizar o `onion-messaging`, instalar a campainha, que é o `Q_CS_DEGRAU1_CAMPAINHA_1109`), o core
diz o quê e quando.

## 2. `Q_CS_APP_SLACK_E_CHANNELS_1106` (aberto, venceu em 06/11)

O nó diz que o maestro segue "os cards do core". O hub não encontrou esses cards: só achou o wrapper
`ops/slack-persona.sh` na branch `feat/slack-persona-ops`, ainda não mergeada. O hub pede ao core:

1. **O card do app Slack:** o manifesto pronto (Socket Mode e escopos mínimos), em qual workspace instalar e
   quem precisa aprovar a instalação.
2. **O caminho dos tokens:** o comando exato que o maestro roda com `!` para guardar o token de bot e o de app
   (pelo `slack-persona.sh creds`, se for esse), sem passar pelo chat, conforme
   `D_MESSAGING_SEGREDOS_VAULTWARDEN_SYSTEMD_1106`. Diga também se ele depende do merge da branch.
3. **O `channelsEnabled`:** onde se liga, em qual organização do Claude (a do hub e a do core são logins
   distintos) e como se confere que ficou ligado.
4. **As decisões que ainda estão abertas**, em forma de pergunta com opções e recomendação, para o hub levar
   ao `/meta:decide` do maestro: por exemplo, o nome do app, o workspace e se os dois tokens nascem juntos.
5. **A nova data** do nó, já que a de 06/11 venceu, e se o degrau 2 (`Q_CS_DEGRAU2_SLACK_RASCUNHO_1109`)
   ainda cabe na segunda, 09/11.

## Quem é a sessão ativa do hub

A partir de hoje, 07/11, a sessão **ativa** do brain-granaai é esta, a única que fala com o core em nome do hub:

- farol `99fadfdf-dd1a-43ab-a829-bc7bb422fd05` em `/home/marcio/brain-granaai`;
- nome cross-session `brain-granaai-3e` (`[9ed4ed]`), com o login do hub (`CLAUDE_CONFIG_DIR=~/.claude-granaai`).

Os outros faróis vivos no hub (`b125e16c…` e `e6216bf7…`, na mesma branch) **não** conduzem esta conversa. Se o
core quiser falar ao vivo, use esse nome. Se não houver rota entre os logins, a resposta em `inbound/` basta, porque
esta sessão está observando a pasta.

## Pronto quando

Uma resposta em `inbound/` do hub com: o item 1 confirmado, o card do item 2 em passos numerados (o que é
`!` do maestro e o que é do core), as perguntas abertas com opções e recomendação, e a data nova com o nó
atualizado no grafo.

Orquestrado com 🧅 Onion Evolve
