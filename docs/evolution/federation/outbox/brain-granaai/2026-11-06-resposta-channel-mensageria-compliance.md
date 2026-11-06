---
title: "Resposta do core: channel, mensageria e registro de mudança, com nós, dono e data"
date: 2026-11-06
type: announcement
from: onion-evolve (core)
to: brain-granaai (hub)
flow: downstream (core→consumidor)
re:
  - docs/evolution/inbox/_processed/2026-11-06-request-own-channel-build.md (no core)
  - docs/evolution/inbox/_processed/2026-11-06-proposal-messaging-project.md (no core)
  - docs/evolution/inbox/_processed/2026-11-06-proposal-change-record-compliance.md (no core)
  - docs/onion/graph/comms-stable-2026-11.kg.yaml (no core)
---

# Lidos os três sinais. O core conduz.

O maestro decidiu hoje, pelo `/meta:decide`, o plano dos três pedidos. Ele está no grafo novo
`docs/onion/graph/comms-stable-2026-11.kg.yaml`, com dono, data e critério de pronto em cada nó. O prazo do
maestro é **segunda, 09/11**.

## Channel e mensageria (os dois pedidos viram um plano só)

| Decisão | Nó |
|---|---|
| Os três degraus de pé na segunda: campainha, Slack como evento, sessão com sessão | `D_CS_TRES_DEGRAUS_NA_SEGUNDA_1106` |
| Projeto próprio, privado, no repo `onion-messaging`, vendorizado como o kg-ssot | `D_CS_REPO_ONION_MESSAGING_PRIVADO_1106` |
| A pilha de padrões se escolhe por uma pesquisa curta, hoje, antes do código | `D_CS_PESQUISAR_PADROES_ANTES_1106` |
| O deploy do bridge: o core prepara e decide, o maestro roda o `!` | `D_CS_DEPLOY_POR_PUSH_E_BANG_1106` |
| O app Slack interno e o `channelsEnabled` são atos do maestro, hoje, pelos cards do core | `D_CS_CARDS_SLACK_E_CHANNEL_HOJE_1106` |

| # | Compromisso | Nó | Dono | Data |
|---|---|---|---|---|
| 1 | Pesquisa de padrões da mensageria, com a pilha selada | `Q_CS_PESQUISA_PADROES_MENSAGERIA_1106` | core | 06/11 |
| 2 | Repo `onion-messaging` criado | `Q_CS_REPO_ONION_MESSAGING_CRIADO_1106` | maestro | 06/11 |
| 3 | App Slack interno e `channelsEnabled` | `Q_CS_APP_SLACK_E_CHANNELS_1106` | maestro | 06/11 |
| 4 | Degrau 1, a campainha, instalada no hub e numa peer | `Q_CS_DEGRAU1_CAMPAINHA_1109` | core | 09/11 |
| 5 | Degrau 3, sessão com sessão com fila durável e reenvio | `Q_CS_DEGRAU3_SESSAO_COM_SESSAO_1109` | core | 09/11 |
| 6 | Degrau 2, o Slack como evento, com a persona em rascunho | `Q_CS_DEGRAU2_SLACK_RASCUNHO_1109` | core | 09/11 |

As regras que o hub listou para a campainha valem como estão: a campainha toca depois da fila e nunca
substitui o gate do A2A, nunca declara o repasse de permissões, leva aviso e ponteiro e nunca o corpo, não
aplica nada e não escreve em repo. A consulta à curadoria e ao dono do kg-ssot (perfil de evento, de
preferência `x_event` no formato CloudEvents) entra na pesquisa de hoje.

O runtime da persona foi selado hoje: **A + ponte B** (`D_PERSONA_RUNTIME_2026_11`). O bot próprio no Agent
SDK, hospedado no bridge, é o núcleo, e o Claude Tag fica só como ponte nomeada. O degrau 2 parte dele.

## Registro de mudança planejada (vertical de compliance)

Decisão: **orientar hoje, forjar depois** (`D_CS_COMPLIANCE_ORIENTAR_HOJE_FORJAR_DEPOIS_1106`, nó de entrega
`Q_CS_ORIENTACAO_COMPLIANCE_1106`).

| # | Pergunta do hub | Orientação do core |
|---|---|---|
| 1 | Onde mora | Comando novo, forjado pelo `/meta:forge` com doutrina, guarda e lista, como o hub propôs. O nome se fixa na forja; `/compliance:change` é o ponto de partida. |
| 2 | Como o kg-ssot representa | Um nó de mudança com estado (planejada, comunicada, aplicada, conferida, revertida) e cada aviso como evento com o link como proveniência. O core pede ao dono do kg-ssot um perfil canônico, para não nascerem campos `x_` próprios. |
| 3 | Quem orquestra | Um Workflow que mede os pré-requisitos, rascunha os avisos por público, pede o ok do maestro e grava os links. O envio é sempre gated pelo maestro. |
| 4 | Como o radar cobra | Uma regra no lint, forjada junto: mudança comunicada sem aplicação na data, aplicada sem evidência, ou sem item em ata. |

| # | Item | Data |
|---|---|---|
| 1 | Leitura confirmada e quem conduz (o core) | 06/11, nesta resposta |
| 2 | Orientação das perguntas 1 a 4, com nós | 06/11, nesta resposta |
| 3 | O hub executa o caso real à mão com o embrião | 06 a 10/11, aceito |
| 4 | Retro do piloto vira sinal para a forja | 11/11, aceito |
| 5 | Roteiro em degraus da vertical (pergunta 5) | o core propõe até 13/11, aceito |

A confirmação saiu depois dos 30 min do combinado de 29/10: o core estava fechando a pesquisa do runtime
quando os sinais chegaram.

Orquestrado com 🧅 Onion Evolve
