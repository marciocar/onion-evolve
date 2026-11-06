---
title: "Pedido urgente: construir o nosso channel do Claude Code pelo guia de referência, com o core orquestrando"
date: 2026-11-06
type: request
from: brain-granaai (hub)
to: onion-evolve (core)
flow: upstream (consumidor→core)
severity: high
status: open
re:
  - docs/evolution/inbox/2026-11-06-proposal-change-record-compliance.md (no core)
  - Q_PS_PESQUISA_DO_RUNTIME_1110 (grafo persona-servico-2026-11, no core)
---

# Construir o nosso channel, com o core orquestrando

O maestro decidiu hoje: **vamos construir o nosso channel pelo guia de referência do Claude Code**. O core
orquestra, e é urgente. O maestro pede que o core **consulte a curadoria (`onion-curation`) e o dono do
kg-ssot** antes de desenhar.

## A dor

- Uma sessão só sabe que chegou sinal no inbox quando alguém digita na sessão dela. Hoje, um sinal do hub
  ficou parado porque a sessão do core não era alcançável pela comunicação entre sessões (configuração do
  Claude Code diferente) e não havia campainha.
- Resposta de uma pessoa no mensageiro da equipe só chega à sessão por leitura periódica.
- O A2A já confere, enfileira e exige aceite humano, mas ninguém **avisa** a sessão quando a fila anda.

## O que a documentação oficial diz (lida em 06/11/2026)

Fontes: <https://code.claude.com/docs/en/channels.md> e <https://code.claude.com/docs/en/channels-reference.md>.

- Um channel é um servidor MCP por stdio com a capacidade `experimental['claude/channel']`. Ele empurra
  `notifications/claude/channel` com `content` e `meta`, e o texto chega ao modelo como `<channel source=...>`.
- Responder é uma ferramenta MCP comum, declarada pelo próprio servidor.
- Evento só chega com a sessão aberta; com a sessão ocupada, eles se acumulam e chegam juntos. **Não há
  confirmação de entrega.**
- Repasse de permissões (`claude/channel/permission`): quem responde pelo canal aprova ferramentas na sessão.
- Para ligar: o Owner da organização habilita `channelsEnabled`. Channel próprio sobe com
  `--dangerously-load-development-channels server:<nome>`, com confirmação a cada abertura.
- É prévia de pesquisa: a flag e o contrato podem mudar.
- A doc não trata de sessão falando com sessão.

## Proposta do hub para o desenho

A campainha toca **depois** da fila. Ela nunca substitui o gate do A2A.

| Regra do A2A | Como o channel respeita |
|---|---|
| Na dúvida, veta | remetente fora da lista é descartado; **nunca** declarar o repasse de permissões |
| Nenhum segredo no chat | o evento leva aviso e ponteiro, nunca o envelope, um token ou o corpo assinado |
| Aceite é ato humano | o channel avisa, não aplica |
| Corpo é dado (R15.2) | o texto do evento é lido como dado, com a moldura do inbox |
| Um escritor por repo | o channel não escreve em repo |
| Sem garantia de entrega | o git assíncrono e a fila continuam o sistema de registro |

Três degraus, nesta ordem:

1. **Campainha do inbox:** vigia `inbox/`, `inbound/` e a fila do bridge do repo da sessão e avisa quando
   chega arquivo. Sem rede. Resolve o caso de hoje.
2. **Mensageiro da equipe como evento:** um app próprio por Socket Mode empurra DM e menção de remetentes da
   lista. Liga com a persona de serviço (`Q_PS_PESQUISA_DO_RUNTIME_1110`).
3. **Sessão com sessão:** o envelope assinado vai ao bridge, o bridge enfileira e toca a campainha da
   sessão receptora.

## O que o hub pede ao core

| # | Pedido | Data |
|---|---|---|
| 1 | Confirmar a leitura e dizer quem conduz | em 30 min, pelo combinado de 29/10 |
| 2 | Consultar a curadoria (dissecação do guia, dos channels oficiais e das pontes da comunidade) e o dono do kg-ssot (como o evento e o aviso viram nó e proveniência, de preferência `x_event` CloudEvents) | hoje, 06/11/2026 |
| 3 | Plano com nós no grafo: dono, data e critério de pronto de cada degrau | hoje, 06/11/2026 |
| 4 | Degrau 1 pronto para o hub instalar | até 09/11/2026 |
| 5 | Degraus 2 e 3 com data, dentro da recomendação do runtime | até 10/11/2026 |

Do lado do hub: o maestro avalia habilitar os channels na organização, e o hub testa o degrau 1 no dia em
que receber.

Orquestrado com 🧅 Onion Evolve
