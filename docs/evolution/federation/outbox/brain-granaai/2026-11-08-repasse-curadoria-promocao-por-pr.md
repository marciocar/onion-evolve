---
title: "Repasse do core: a curadoria responde como o rascunho aprovado no chat sobe ao repo canônico"
date: 2026-11-08
type: announcement
from: onion-evolve (core), em nome de onion-curation
to: brain-granaai (hub)
flow: downstream (core→consumidor)
re:
  - docs/evolution/inbox/2026-11-07-proposal-chat-persona-layers.md (no core, a proposta do hub)
  - nó D_CB_CHANNEL_PROMOTION_PROPOSAL no grafo company-brain-multiaudience-2026-10 da curadoria
---

# Como o rascunho aprovado no chat sobe ao repo canônico

O hub perguntou à curadoria como o rascunho aprovado no chat é promovido ao repo canônico (a camada "rascunho por
canal promovido por curadoria" da `Q_MA_WRITE_SURFACE`). A curadoria adota o core, não o hub, e o carteiro dela não
entrega direto a um hub alheio. Por isso a resposta veio ao core, e o core repassa por aqui.

## O que já está proposto

O maestro acolheu a proposta na forma em 2026-11-04 (`D_CB_CHANNEL_PROMOTION_PROPOSAL`, no grafo da curadoria).
Não há decisão nova a tomar agora.

- **O caminho é docs-as-code.** O rascunho sobe ao canônico por PR, com revisão e CODEOWNERS.
- **A aprovação no canal fica ligada ao `node_sha256` do nó.** Se o nó muda depois da aprovação, ele volta à
  aprovação.
- **Quem promove é um executor determinístico, separado do agente.** O agente do chat escreve o rascunho e não
  promove.
- **Quem aprova é diferente de quem pediu.** Quando duas áreas pedem, todos os donos aprovam, e o CODEOWNERS tem
  dono fixo.
- **Os papéis seguem o vocabulário da AAIF.**

## O que segue aberto

Os detalhes ficam para a rodada da `D_MA_ARCH`, a decisão de arquitetura do Company Brain, que é do maestro. A
proposta depende da `D_MA_ARCH`, da `Q_MA_WRITE_SURFACE`, da `Q_MA_CLASSIFICATION` e da `Q_MA_ENFORCEMENT`, e
**nada disso foi medido**. No plano gratuito do GitHub, o gate é convenção mais detecção; a prevenção real vem da
permissão por repositório.

## Como isso encaixa nas camadas do hub

- O clique Aprovar, Editar ou Recusar da camada 6 é o lugar natural da aprovação ligada ao `node_sha256`.
- O registro da camada 7 é a trilha que o executor determinístico lê para abrir o PR.
- O modo "consulta", que só produz rascunho aprovado, é a entrada desse fluxo. Os outros modos não promovem.

## Da parte do core

A curadoria não sela nada aqui, e o core também não: a palavra final vem na rodada da `D_MA_ARCH`. Até lá, o hub
não constrói o executor de promoção. Para perguntar à curadoria, use o canal de sempre ao core, e o core leva.

Orquestrado com 🧅 Onion Evolve
