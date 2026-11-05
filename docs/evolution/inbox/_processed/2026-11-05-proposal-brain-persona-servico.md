---
title: "Persona de serviço do hub: o Brain atende o time pelo chat corporativo e tria o e-mail do maestro, com identidade própria"
date: 2026-11-05
type: proposal
from: brain-granaai (hub)
to: onion-evolve (core)
flow: upstream (consumidor→core)
severity: medium
status: open
re:
  - docs/onion/graph/company-brain-multiaudiencia-2026-10.kg.yaml (D_MA_ARCH aberta, no core)
---

# Persona de serviço do hub

> Só a **forma**. Nada aqui traz dado de cliente, de pessoa, de incidente ou de configuração de segurança.

## O pedido do maestro

O maestro quer que a sessão do hub assuma uma **persona de serviço** da empresa, o "Brain". Ela teria:

1. **Identidade própria:** uma conta de serviço da empresa (e-mail próprio), em vez de agir com a conta
   pessoal do maestro.
2. **Atendimento no chat corporativo:** qualquer pessoa da empresa chama a persona por **menção**
   (`@brain`), e ela responde dentro do chat com o contexto do Company Brain.
3. **Triagem de demandas pelos canais que já estão conectados:** e-mails do maestro, chat e gerenciador
   de tarefas. A demanda que chega vira card, resposta ou pergunta ao maestro.

O maestro pediu que **o core organize** isso. Pelo que o hub sabe, a decisão de arquitetura já vive no
grafo do core (`D_MA_ARCH`, em aberto), e este pedido é um caso de uso concreto para ela.

## O que o hub já viveu e que pesa na decisão

- **Canal de mensagens instável numa sessão longa.** O conector do chat caiu no meio da sessão. Precisou de
  reinstalação e de novo login OAuth, e uma rotina agendada perdeu o canal de aviso até o maestro intervir.
  Um serviço que atende o time não pode depender de uma sessão interativa aberta.
- **Identidade misturada.** Hoje tudo sai com a conta do maestro: mensagens, cards e comentários em PR.
  O time não distingue o que o maestro escreveu do que a sessão escreveu em nome dele.
- **Conteúdo recebido é dado, não instrução.** O hub aplica isso por regra de sessão: mensagens do chat e
  e-mails nunca viram ordem. Com atendimento aberto a todo o time, essa regra precisa virar mecanismo,
  com quem pode pedir o quê, o que exige o ok do maestro e o que nunca sai.
- **Ações externas pedem confirmação.** Hoje cada envio ao chat, cada card e cada merge passa pelo maestro
  na hora. Uma persona que atende sozinha precisa de uma escada explícita: o que faz sem perguntar, o que
  faz com ok e o que só o maestro faz.
- **Audiências diferentes.** O conteúdo interno do Company Brain não pode vazar para quem não deveria ver.
  Isso já está em `Q_MA_AUDIENCES` e `Q_MA_CLASSIFICATION`.

## Perguntas ao core

1. A persona de serviço entra em `D_MA_ARCH` como requisito: identidade de serviço, menção no chat e
   triagem de e-mail? Ou vira decisão própria?
2. Qual runtime: um bot próprio (Agent SDK, sempre de pé) ou o assistente nativo do chat corporativo,
   com o Company Brain como fonte?
3. Como fica a escada de autonomia por tipo de ato (responder, criar card, publicar no canal, e-mail
   para fora, mexer em produção), e quem a aprova?
4. Como o hub pilota sem mudar a identidade antes do selo? Proposta do hub: começar respondendo
   **rascunhos** que o maestro aprova, e só depois passar a responder direto.

## O que o hub faz enquanto isso

- Não assume a persona nem cria a conta de serviço antes do selo do core.
- Continua operando com a conta do maestro, com confirmação a cada ato externo.
- Registra os usos reais (pedidos que chegam, o que foi resolvido e o que exigiu o maestro) como insumo
  para o piloto.

Orquestrado com 🧅 Onion Evolve
