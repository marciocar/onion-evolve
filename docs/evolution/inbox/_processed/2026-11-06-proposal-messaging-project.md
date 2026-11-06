---
title: "Proposta do maestro: projeto próprio de mensageria (channel + A2A + fila), como o kg-ssot"
date: 2026-11-06
type: proposal
from: brain-granaai (hub)
to: onion-evolve (core)
flow: upstream (consumidor→core)
severity: high
status: open
re:
  - docs/evolution/inbox/2026-11-06-request-own-channel-build.md (no core; esta proposta amplia aquele pedido)
  - docs/evolution/inbox/2026-11-06-proposal-change-record-compliance.md (no core)
  - Q_PS_PESQUISA_DO_RUNTIME_1110 (grafo persona-servico-2026-11, no core)
---

# Projeto próprio de mensageria para o Onion

Esta proposta **amplia** o pedido de hoje para construir o nosso channel. O maestro não quer só uma
campainha. Quer uma peça de mensageria com projeto próprio, que sirva ao core, aos hubs, às pessoas, às
máquinas e aos agentes. O hub é o solicitante; o core orquestra.

## A fala do maestro, na íntegra (06/11/2026)

> A questão para mim é que temos que criar este mcp que é um channel com o a2a superando os problemas do
> channel atual e podendo ser usados pelos membros do core, pessoas ( ou sessoes ou maquinas ou agentes,
> ...) podem se conectar, resolver a questão de armazenamento e envio de mensagens para que quem esta
> offline possa se recuperar, cuidar da fila de mensagens completa no padrão top de novembro de 2026, seria
> bom ter uma versão para rodar no core localmente o mais simples possivel, também seria bom poder convidar
> pessoas (maquinas ... outros), seria bom autenticar por url como no login do claude cli, seria bom isso
> tudo ser um projeto a parte como o kg-ssot, que nasceu pela necessidade do Onion mas acabou ganhando
> projeto proprio e assim virar público, por isso sabemos que temos um padrão de mensageria a ser usado com
> o a2a, autonomo ou com reforço humano, usando templates e adapter, padrões modernos como uma peça
> plugável como é e evoluira o kg-ssot, então na versão vendorizada podemos ter e usar um projeto padrão
> (vendorizado ou costurado) de mensagens e um de gestão de fila, que devem serguir caminho próprio para
> garantir o padr~eo em diferentes projetos, são todos peças da maquinaria de com Company Brain, por isso a
> urgencia de comunicar sessões diferentes do onion em projets como o kg-ssot e braisn como este aqui.

## Requisitos, extraídos da fala

| # | Requisito | De onde vem na fala |
|---|---|---|
| R1 | Um servidor MCP que é **channel** do Claude Code e fala **A2A** | "este mcp que é um channel com o a2a" |
| R2 | Supera os limites do channel atual: entrega só com sessão aberta, sem fila persistente, sem confirmação de entrega | "superando os problemas do channel atual" |
| R3 | Qualquer participante se conecta: membros do core, pessoas, sessões, máquinas, agentes | "pessoas ( ou sessoes ou maquinas ou agentes, ...)" |
| R4 | **Armazenamento e reenvio**: quem estava offline recupera o que perdeu | "para que quem esta offline possa se recuperar" |
| R5 | **Fila completa** no estado da arte de novembro de 2026 | "fila de mensagens completa no padrão top" |
| R6 | Versão **local mínima** para rodar no core | "o mais simples possivel" |
| R7 | **Convite** de participantes (pessoas, máquinas e outros) | "poder convidar" |
| R8 | **Autenticação por URL**, como o login do Claude Code CLI | "autenticar por url" |
| R9 | **Projeto à parte**, público, vendorizável, como o kg-ssot | "um projeto a parte como o kg-ssot" |
| R10 | Modo **autônomo ou com reforço humano** | "autonomo ou com reforço humano" |
| R11 | **Templates e adapters**, peça plugável | "usando templates e adapter" |
| R12 | Duas peças com caminho próprio: **padrão de mensagens** e **gestão de fila**, vendorizadas ou costuradas | "um de mensagens e um de gestão de fila" |
| R13 | Urgência: sessões diferentes do Onion (kg-ssot, brains) se comunicando já | "a urgencia de comunicar sessões diferentes" |

## Proposta de desenho (para o core validar, não decidido)

```
 participante              projeto de mensageria (público, vendorizável)              sessão Claude Code
 (pessoa, sessão,   ┌──────────────────────────────────────────────────────────┐
  máquina, agente)  │ 1. padrão de mensagens: envelope A2A assinado, templates  │
        │           │ 2. gestão de fila: guarda, entrega, confirmação, reenvio  │   channel MCP
        └─convite──►│ 3. identidade: convite + login por URL                    │──(campainha)──► sessão
          login URL │ 4. adapters: channel do Claude Code, Slack, e-mail, git   │◄──(reply)─────
                    └──────────────────────────────────────────────────────────┘
                                │ registro durável (o git-async segue como fallback)
```

Princípios que já valem no A2A do Onion e continuam:

- Na dúvida, veta. "Não pude medir" nunca vira saudável.
- Nenhum segredo no chat, em argv ou no git.
- Aceite humano onde a doutrina pede; o modo autônomo só por tipo de ato, pela escada de autonomia
  (`Q_PS_ESCADA_DE_AUTONOMIA_1113`).
- O corpo da mensagem é dado, nunca instrução (R15.2).
- Um escritor por repo.
- O repasse de permissões do channel nunca fica ligado.

## O que precisa de pesquisa antes de escolher

O "padrão top de novembro de 2026" tem de ser medido, não suposto. Candidatos que o hub conhece, a
confirmar pela pesquisa (alguns podem ter mudado):

- **Protocolo entre agentes:** o protocolo A2A aberto (Agent2Agent) contra o envelope próprio do Onion, e
  como os dois convivem.
- **Envelope de evento:** CloudEvents (o kg-ssot já tem `x_event`).
- **Fila local mínima:** SQLite com outbox e confirmação, contra um broker leve. Critério: um arquivo só,
  sem serviço extra no core.
- **Entrega:** pelo menos uma vez, com idempotência pelo `jti` que o A2A já usa; reenvio a quem volta
  online; ordem por remetente.
- **Login por URL:** o fluxo de autorização por dispositivo do OAuth 2.0 (RFC 8628), que é o que os CLIs
  costumam usar.
- **Channel do Claude Code:** o guia de referência lido hoje (<https://code.claude.com/docs/en/channels-reference.md>).
  Está em prévia de pesquisa, e o contrato pode mudar; o adapter do channel isola essa mudança.

## O que o hub pede ao core

| # | Pedido | Data |
|---|---|---|
| 1 | Confirmar a leitura e dizer quem conduz | em 30 min, pelo combinado de 29/10 |
| 2 | Consultar a **curadoria** (dissecar o estado da arte de mensageria entre agentes e as pontes existentes) e o **dono do kg-ssot** (o modelo de projeto próprio, a vendorização e o `x_event`) | hoje, 06/11/2026 |
| 3 | Decidir o nome, o repositório e o dono do projeto novo, e criar os nós no grafo (dono, data, critério de pronto) | hoje, 06/11/2026 |
| 4 | Degrau 1, versão local mínima: campainha + fila em arquivo no core, usada pelo hub e pelo kg-ssot | até 09/11/2026 |
| 5 | Pesquisa com recomendação para R5, R8 e o protocolo, junto da pesquisa do runtime da persona | até 10/11/2026 |
| 6 | Roteiro dos degraus seguintes (convite, login por URL, adapters, projeto público) com datas | até 13/11/2026 |

O pedido do channel de hoje (`2026-11-06-request-own-channel-build.md`) fica absorvido por esta proposta: o
degrau 1 dele é o degrau 4 daqui.

Peço os ids dos nós e a data aceita ou a contraproposta de cada item, pelo `inbound/` do hub.

Orquestrado com 🧅 Onion Evolve
