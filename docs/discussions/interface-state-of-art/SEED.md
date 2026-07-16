---
title: "Fonte de discussão — Interface no estado da arte (comunicação, padrões, coleta, telemetria)"
category: discussion
status: fonte-de-discussao-isolada
date: 2026-07-11
branch: discuss/interface-state-of-art
---

# 🧵 A interface no estado da arte — como servir melhor o que estamos construindo

> **Isolada.** Pensa, não entrega. Nada vai pro core sem o maestro pedir. Não misturar com os outros temas.

## O tema
Como fazer **esta interface** (a forma como conversamos e trabalhamos aqui) ser e atender **o estado da arte**
do que estamos construindo — incluindo: nossa **forma de comunicação**, **reconhecimento de padrões**, **coleta
de dados** e **telemetria**. Ou seja: a interface deixa de ser só chat e vira um instrumento que observa,
aprende e melhora o próprio fluxo.

## Por que importa pro Onion
- Toda a sessão de hoje foi dogfood **sem telemetria estruturada** — decisões, padrões, retrabalho, tudo ficou
  em prosa/diário. Uma interface no estado da arte **instrumentaria** isso (o que funcionou, onde travei, que
  padrão se repete) e realimentaria o KG.
- Liga com o **loop dogfood-auditável** (o diferenciador NS1) — a interface é onde o loop é observado.

## Perguntas de partida
1. Que **telemetria** seria útil e ética capturar da própria sessão (padrões de decisão, gargalos, custo)?
2. **Reconhecimento de padrões**: a interface percebe "isto já aconteceu / vira um padrão candidato" (como os
   diários viram doutrina)?
3. **Forma de comunicação**: além de chat — voz, diagramas ao vivo, o grafo projetado, gates visuais?
4. Onde a linha **intake × execução** (o estudo) governa o que a interface pode coletar sozinha vs sob gate?

## Conexões com o que já existe
- **Baseline conversacional (o que já funciona, antes da interface rica):**
  [`onion-pessoal-marcio/USAGE.md`](../onion-pessoal-marcio/USAGE.md) — o "como usar pé-no-chão" (`cd
  ~/onion-pessoal && claude` → conversar → o `.kg.yaml` mantido pela conversa → `kg-radar` é a lente). Esta
  discussão pesquisa a interface **rica** (telemetria/padrões) que vem **depois** desse baseline. *(Gap de
  campo N=1: o próprio criador precisou perguntar "como uso isso?" — o baseline estava indocumentado; sinal
  `onion-pessoal-usando-dogfood-kg-sdaal`.)*
- Estudo **camadas de liberação** (coleta é intake — pode ser autônoma de fonte permitida; execução gated).
- `kg-console.sh` (projeção HTML do grafo), o diário (padrões→doutrina), `federation-console`.
- Liga forte com `discuss/behavior-mapping-kg` (a coleta ampla) e `discuss/onion-mobile-app` (superfície).

## Como abrir
`cd ~/worktrees/onion-evolve/discuss-interface-state-of-art && claude`
