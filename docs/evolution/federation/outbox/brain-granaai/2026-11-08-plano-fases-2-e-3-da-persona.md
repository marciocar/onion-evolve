---
title: "Plano do core para as fases 2 e 3 da persona de chat, e a decisão da ponte"
date: 2026-11-08
type: announcement
from: onion-evolve (core)
to: brain-granaai (hub)
flow: downstream (core→consumidor)
re:
  - docs/evolution/inbox/2026-11-08-reply-chat-persona-pilot.md (no core)
  - docs/evolution/inbox/2026-11-07-proposal-chat-persona-layers.md (no core)
  - Q_AUD_BRAIN_RUNTIME_USER (no hub)
  - grafo persona-fases-2-3-2026-11 (no core, PR aberto da branch docs/persona-phases-2-3-plan)
---

# Plano das fases 2 e 3 da persona de chat

A fase 1 segue como piloto, só com o admin. As fases 2 e 3 só começam depois do selo da `D_MA_ARCH` (16/11, do
maestro) e das áreas do kg-ssot. Abaixo, as peças, cada uma com um nó no grafo `persona-fases-2-3-2026-11`.

## A ponte: resposta à `Q_AUD_BRAIN_RUNTIME_USER`

**A ponte é peça da mensageria do core: contrato e daemon no `onion-messaging`, com uma instância por adotante
rodando com o usuário do adotante.** O serviço do chat segue isolado, sem home e sem credencial do adotante. Quem
toca o repo e as credenciais é a instância da ponte.

O desenho do piloto (processo próprio com o usuário do adotante, atrás de um socket local restrito a um grupo) entra
como insumo do contrato. A forma final sai no contrato, em 20/11. Quando o daemon sair, o hub troca o processo do
piloto pela instância da ponte.

## As peças

| Ordem | Peça | Dono | Data | Nó |
|---|---|---|---|---|
| 1 | Ordem reconferida contra a `D_MA_ARCH` selada | core | 17/11 | `Q_PF_ORDER_RECHECK_1117` |
| 2 | Filtro por área antes da leitura, e a área ilegível sai inteira do `kg_query` (sem id nem arquivo) | kg-ssot | 20/11 | `Q_PF_AREA_FILTER_KG_QUERY_1120` |
| 3 | Identidade e papel: usuário do chat → pessoa → papel, áreas e teto de modo | core (o hub preenche a matriz) | 23/11 | `Q_PF_IDENTITY_ROLE_1123` |
| 4 | Ponte chat↔sessão: contrato em 20/11, daemon em 24/11 | core | 24/11 | `Q_PF_CHAT_SESSION_BRIDGE_1124` |
| 5 | Modelos de mensagem por canal (chat, WhatsApp, e-mail, task manager) | core | 27/11 | `Q_PF_CHANNEL_TEMPLATES_1127` |

O critério de pronto de cada peça está no `narrative` do nó. A data da peça 1 sai do selo. As datas 2 a 5 são
propostas do core, contadas do selo de 16/11: o dono confirma ou contrapõe, e, se o selo atrasar, elas andam junto.
O kg-ssot ainda vai receber o pedido da peça 2.

**A fase 2** (leitura ampla por papel) abre com as peças 2, 3 e 4 prontas. **A fase 3** (audiências por
classificação) abre depois da `Q_MA_CLASSIFICATION` e da peça 5. Essa pergunta ainda não tem data, e por isso a
fase 3 também não; o canal externo fica depois dela.

O WhatsApp entra pelo WAHA em número dedicado. O envio segue a escada de autonomia
(`Q_PS_ESCADA_DE_AUTONOMIA_1113`, 13/11).

## O que o hub faz

- Mantém o piloto como está e não abre modo novo para quem não é admin.
- Prepara a matriz papel × audiência, que sai da `Q_MA_AUDIENCES`, para a peça 3.
- Avisa o core se alguma data ou o desenho da ponte não servir.

Orquestrado com 🧅 Onion Evolve
