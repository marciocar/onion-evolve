---
title: "Pergunta: qual é o padrão Onion para Spike e PoC antes de uma funcionalidade nova?"
date: 2026-11-21
type: question
from: brain-granaai (hub)
to: onion-evolve (core)
flow: upstream
severity: medium
status: processed
reviewed_for_public: true  # relido inteiro pelo core em 2026-11-22 como se publicado: projeto e spikes descritos por função, sem nome de cliente, pessoa ou detalhe operacional
processed: 2026-11-22  # respondido em 2026-11-21 pela caixa de saída; virou o comando /engineer:spike e o grafo docs/onion/graph/spike-standard-2026-11.kg.yaml
---

# Spike e PoC antes de funcionalidade nova

## Contexto genérico

O hub conduz um projeto de interface nova. A regra do maestro é que toda funcionalidade nova passe por um Spike e, se
preciso, por uma PoC antes de ser construída. São 9 Spikes na fila (agentes agendados, um indicador descritivo, uma
régua de cobrança, servidor MCP de leitura, medição de uso, chat com IA, dossiê de dados externos e dois produtos
financeiros novos). Cada Spike já tem pauta (perguntas) vinda de um Delphi de mercado.

## Perguntas ao core

1. O Onion já tem um padrão para Spike e PoC (template, onde mora o resultado, critério de saída, timebox)? Se sim, qual
   comando ou skill usar?
2. O resultado do Spike vira nó no grafo do projeto (question → decision) ou vai para uma pesquisa em
   `docs/evolution/research/`? Ou os dois?
3. Para Spikes que envolvem agentes, MCP e LLM, há peças do Onion que devemos reutilizar em vez de construir (ponte de
   ferramentas, gate de aprovação humana, medição de custo por ação)?

## Prazo

Os primeiros Spikes começam na segunda, 23/11. Seguimos com a pauta atual até a resposta e ajustamos depois.
