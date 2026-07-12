---
title: "Fonte de discussão — Mapear comportamento do usuário (multi-superfície) e catalogar com KG SDAAL"
category: discussion
status: fonte-de-discussao-isolada
date: 2026-07-11
branch: discuss/behavior-mapping-kg
# ── bloco Tier-0 (o mapa da constelação lê SÓ isto — metadados, nunca o corpo) ──
phase: CONVERGE       # SEED | EXPLORE | DEEP | CONVERGE | PROMOTE | PARK
index: README.md       # ← entrada da frente: as 5 notas + sínteses + protos
next_action: "[Contexto mesclado em main: a premissa telemetria compartilhada (C_TELEMETRY_VIABLE) está formalizada na pesquisa da camada dialógica + no overlay constellation.kg.yaml; a estrela interface (o loop) foi promovida #344 — checar o schema de coleta CONTRA eles, não reinventar.] As 5 perguntas do SEED estão trabalhadas (ver README.md → Q1–Q5, cada uma com nota + pesquisa citada + proto kg-radar verde). Q5 FECHADA (2026-07-12): sensor-como-capability; produto próprio deferido (gated: pull frio externo). Próximo passo é do maestro: promover algo a feat/*, aprofundar uma nota, ou parkear."
scope_globs: ["docs/onion/graph/", "docs/knowledge-base/concepts/"]
objective_tags: ["NS1", "intake-execucao", "kg-map"]
---

# 🧵 Sensor de comportamento → contexto: coletar, mapear e catalogar com Dogfood KG SDAAL

> **Isolada.** Pensa, não entrega. Nada vai pro core sem o maestro pedir. Não misturar com os outros temas.
> ⚠️ Tema de **alta sensibilidade** (privacidade/vigilância) — a discussão tem que carregar a ética junto.

> 📍 **A frente já foi trabalhada — entre pelo índice: [README.md](README.md).** Este SEED é a origem;
> o README lista as 5 notas (Q1–Q5), suas pesquisas citadas e os protos `kg-radar`.

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

## Perguntas de partida  → _(cada uma trabalhada numa nota; ver [README.md](README.md))_
1. **Onde é a linha ética/legal?** Coletar comportamento é o dado mais sensível — consentimento, escopo,
   `de-identification`, soberania. Isto tem que ser desenhado ANTES do "como coletar".  → [01 — consentimento dual](01-consentimento-dual.md)
2. O que é **intake** (observar/guardar) × **execução** (agir sobre) — o estudo de camadas de liberação aplica direto.  → [02 — intake × execução](02-intake-execucao.md)
3. Captura: passiva (telas/ações) vs declarada (o usuário anota)? Local-first vs nuvem?  → [03 — captura e localidade](03-captura-e-localidade.md)
4. Do sinal bruto ao KG: o que vira `claim`/`event`/`entity`? Como o radar reconcilia "o que a pessoa faz × diz"?  → [04 — sinal ao KG](04-sinal-ao-kg.md)
5. Fronteira produto: isto é **feature do Onion pessoal** ou um **produto próprio** (process-mining pessoal)?  → [05 — fronteira de produto](05-fronteira-produto.md) _(✅ DECIDIDO: capability; produto deferido)_

## Conexões com o que já existe
- **KG SDAAL** (`/meta:kg` modo `map`, atom-map de telas/sistemas), `de-identification` SDAAL, `exposes:`/soberania.
- Estudo **camadas de liberação** (a ética do intake×execução), `docs-reverse-engineer` (mapear sistemas).
- Liga com `onion-pessoal-marcio`, `interface-state-of-art`, `onion-mobile-app` (a superfície de captura).

## Como abrir
`cd ~/worktrees/onion-evolve/discuss-behavior-mapping-kg && claude`
