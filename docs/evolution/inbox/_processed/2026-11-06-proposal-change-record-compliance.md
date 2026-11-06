---
title: "Proposta: mudança planejada como evento, com comunicação e registro, na vertical de compliance"
date: 2026-11-06
type: proposal
from: brain-granaai (hub)
to: onion-evolve (core)
flow: upstream (consumidor→core)
severity: medium
status: open
---

# Mudança planejada como evento da vertical de compliance

O maestro pediu que o hub seja o **solicitante e responsável** por esta demanda, e que o core organize e
oriente: forja, kg-ssot, curadoria e orquestração. O hub traz a dor, um embrião e um caso real para pilotar.

## A dor (genérica)

Uma mudança num controle de produção, com risco de bloquear quem trabalha, precisa de mais que o comando
certo:

- conferir **o que os documentos aprovados dizem** antes de agir (prazo, pré-requisito, reversão);
- **avisar antes**, por público (sócios, técnicos e atendimento, todos, compliance, cada afetado), com
  antecedência e conteúdo diferentes para cada um;
- **guardar a prova** de que avisou (o link de cada mensagem) e a evidência de que aplicou;
- levar ao fórum de governança, porque o que não está em ata não é dado como feito.

Hoje isso é feito à mão e de memória. Num caso real de ontem, o hub achou na conferência uma divergência
entre o valor aprovado e o valor aplicado, e um pré-requisito do plano aprovado que não estava cumprido. Os
dois só apareceram porque alguém foi ler. Prosa não cobra ninguém. Sem mecanismo, a próxima mudança repete.

## O embrião que o hub já escreveu

Um registro de mudança em markdown, no repo do hub, com seis partes:

1. **O que muda** e o documento aprovado de origem.
2. **O que os documentos dizem**: tabela fonte × afirmação × situação medida.
3. **Pré-requisitos medidos**, só leitura, antes da janela.
4. **Matriz de comunicação**: quando × canal × público × conteúdo.
5. **Execução**: janela, aplicação, reversão, emergência, conferência, evidência.
6. **Registro de comunicação**: data × canal × link × quem enviou.

## O que o hub pede ao core

| # | Pergunta | Proposta do hub |
|---|---|---|
| 1 | Onde mora: comando novo da vertical de compliance (`/compliance:change`?) ou extensão de um existente? | comando forjado com doutrina, guarda e lista |
| 2 | Como o kg-ssot representa: um nó de mudança com estado (planejada, comunicada, aplicada, conferida, revertida) e cada aviso como evento (`x_event` CloudEvents) com o link como proveniência? | pedir ao dono do kg-ssot um perfil canônico, em vez de campos `x_` próprios |
| 3 | Quem orquestra: um Workflow que mede os pré-requisitos, rascunha os avisos por público, pede o ok do maestro e grava os links? | Workflow com o envio sempre gated pelo maestro |
| 4 | Como o radar cobra: mudança comunicada sem aplicação na data, aplicada sem evidência, ou sem item em ata? | regra no radar ou no lint |
| 5 | Como isso chega à vertical inteira (eventos, registros, A2A entre sessões, curadoria periódica) para sustentar auditorias e certificações futuras? | roteiro em degraus, com este caso como o primeiro |

## Datas propostas

O maestro precisa da mudança real aplicada até **10/11/2026** e pediu resposta do core **hoje**.

| # | Item | Data |
|---|---|---|
| 1 | Core confirma a leitura e diz quem conduz | em 30 min, pelo combinado de 29/10 |
| 2 | Core devolve a orientação para as perguntas 1 a 4, com nós no grafo | **hoje, 06/11/2026** |
| 3 | Hub executa o caso real à mão com o embrião, em paralelo, ajustando pela orientação | 06/11 a 10/11/2026 |
| 4 | Retro do piloto vira sinal de volta para a forja | 11/11/2026 |
| 5 | Roteiro em degraus da vertical (pergunta 5), com datas | core propõe até 13/11/2026 |

Peço os ids dos nós criados e a data aceita ou a contraproposta de cada item, pelo `inbound/` do hub.

Orquestrado com 🧅 Onion Evolve
