---
title: "Fonte de discussão — Interface no estado da arte (comunicação, padrões, coleta, telemetria)"
category: discussion
status: fonte-de-discussao-isolada
date: 2026-07-11
branch: discuss/interface-state-of-art
# ── bloco Tier-0 (o mapa da constelação lê SÓ isto — metadados, nunca o corpo) ──
phase: PROMOTE         # SEED | EXPLORE | DEEP | CONVERGE | PROMOTE | PARK
next_action: "PROMOVIDA a main (#344: SEED + 6 notas). Os 3 invariantes viraram candidatos CONTESTADOS na pesquisa da camada dialógica (já em main) — refutador dobrado, radar acende a pendência. Resta o único portão real: instrumentar N≥3 sessões INTERATIVAS pra provar recorrência (N02). O .kg.yaml + a dobra do refutador vivem no worktree (não mesclados)."
scope_globs: ["docs/onion/graph/", "docs/knowledge-base/concepts/authorization-layers-intake-vs-execution.md"]
objective_tags: ["NS1", "intake-execucao", "dogfood-auditavel"]
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
- Estudo **camadas de liberação** (coleta é intake — pode ser autônoma de fonte permitida; execução gated).
- `kg-console.sh` (projeção HTML do grafo), o diário (padrões→doutrina), `federation-console`.
- Liga forte com `discuss/behavior-mapping-kg` (a coleta ampla) e `discuss/onion-mobile-app` (superfície).

## Como abrir
`cd ~/worktrees/onion-evolve/discuss-interface-state-of-art && claude`
