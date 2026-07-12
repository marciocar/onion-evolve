---
title: "Fonte de discussão — Mapear comportamento do usuário (multi-superfície) e catalogar com KG SDAAL"
category: discussion
status: fonte-de-discussao-isolada
date: 2026-07-11
branch: discuss/behavior-mapping-kg
# ── bloco Tier-0 (o mapa da constelação lê SÓ isto — metadados, nunca o corpo) ──
phase: EXPLORE         # SEED | EXPLORE | DEEP | CONVERGE | PROMOTE | PARK
next_action: "Desenhar o schema de coleta CHECANDO contra interface-state-of-art.kg.yaml (não reinventar a premissa de telemetria — N05 já mostrou: substrato ruidoso, filtro de prefixo é passo-0); carregar a ética junto (tema de alta sensibilidade, privacidade/vigilância)."
scope_globs: ["docs/onion/graph/", "docs/knowledge-base/concepts/"]
objective_tags: ["NS1", "intake-execucao", "kg-map"]
---

# 🧵 Sensor de comportamento → contexto: coletar, mapear e catalogar com Dogfood KG SDAAL

> **Isolada.** Pensa, não entrega. Nada vai pro core sem o maestro pedir. Não misturar com os outros temas.
> ⚠️ Tema de **alta sensibilidade** (privacidade/vigilância) — a discussão tem que carregar a ética junto.

## O tema
Algo que **coleta e mapeia** — pelo computador, celular, nuvem, ferramentas, redes sociais, **ações e telas**
do usuário — o **comportamento**, e o **cataloga com KG SDAAL**. Uso: mapear atividades de trabalho, **criar
contexto**, mapear **fluxos, telas e sistemas**, e daí **criar novos processos e produtos**.

## Por que importa pro Onion
- É o **sensor** que alimenta o `discuss/onion-pessoal-marcio` (o cérebro pessoal) e o `discuss/interface-state-of-art`
  (telemetria) — o insumo que hoje falta pra "criar contexto" automaticamente em vez de à mão.
- Casa com a tese knowledge-centric: transformar **atividade bruta → conhecimento reconciliado** (não só logs).
- Poderia mapear fluxos/telas/sistemas → **engenharia reversa de processos** → novos produtos. Liga com
  `docs-reverse-engineer` e o modo `map` do `/meta:kg` (atom-map de telas).

## Perguntas de partida
1. **Onde é a linha ética/legal?** Coletar comportamento é o dado mais sensível — consentimento, escopo,
   `de-identification`, soberania. Isto tem que ser desenhado ANTES do "como coletar".
2. O que é **intake** (observar/guardar) × **execução** (agir sobre) — o estudo de camadas de liberação aplica direto.
3. Captura: passiva (telas/ações) vs declarada (o usuário anota)? Local-first vs nuvem?
4. Do sinal bruto ao KG: o que vira `claim`/`event`/`entity`? Como o radar reconcilia "o que a pessoa faz × diz"?
5. Fronteira produto: isto é **feature do Onion pessoal** ou um **produto próprio** (process-mining pessoal)?

## Conexões com o que já existe
- **KG SDAAL** (`/meta:kg` modo `map`, atom-map de telas/sistemas), `de-identification` SDAAL, `exposes:`/soberania.
- Estudo **camadas de liberação** (a ética do intake×execução), `docs-reverse-engineer` (mapear sistemas).
- Liga com `onion-pessoal-marcio`, `interface-state-of-art`, `onion-mobile-app` (a superfície de captura).

## Como abrir
`cd ~/worktrees/onion-evolve/discuss-behavior-mapping-kg && claude`
