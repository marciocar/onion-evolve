---
name: radar
description: >
  Percepção externa do Onion — re-mede os 6 eixos de mundo (KG-agente, self-improving,
  ecossistema Claude Code, capital, gates determinísticos, fronteira de modelos) contra a
  baseline DATADA da última rodada, com juiz adversarial por eixo. Maestro-invocado, nunca
  agendado (MOAT W7); a REGRA 65 detecta a idade no lint e o humano dispara.
category: meta
tags: [radar, research, market, external-perception, orchestration]
version: "1.0.0"
updated: "2026-08-31"
argument-hint: "[E1..E6 | vazio = eixos vencidos pela REGRA 65 | --all]"
related_commands:
  - /meta:kg-freshness
  - /meta:evolve
  - /meta:orchestrate
related_agents:
  - research-agent
allowed-tools: Bash, Read, Write, Edit, Task, WebSearch, WebFetch
---

# 📡 /meta:radar — o mundo, re-medido contra a baseline

## 🎯 Objetivo

Fechar o buraco que o programa MAESTRO-VIVO mediu (2026-08-31): o Onion tinha 7 instrumentos de
introspecção e **zero percepção externa recorrente** (S9 parada desde 07-06). Cada rodada mede o
**DELTA** de um ou mais eixos contra a baseline datada — nunca re-deriva o que já foi selado.

## Invariantes (não negociáveis)

- **Maestro-invocado** (W7 = MOAT): nenhum cron/loop/auto-start. A detecção de idade é da
  REGRA 65 (lint, SOFT por eixo vencido — default 45 dias) — a máquina detecta, o humano roda.
- **Juiz-fixo por eixo** (`opus/high`, mandato REFUTAR, ABRE as fontes): calibrado no programa
  (13/47 findings reprovados por fonte fabricada — sem juiz, entrariam na síntese).
- **write(KG) por rodada**: grafo próprio `docs/evolution/research/radar-<eixo|all>-<data>/`,
  com `SUPERSEDES` sobre os nós da baseline anterior que a rodada derrubar (Aufhebung).
- **Lacuna declarada é desfecho de 1ª classe** (molde `E_REDDIT_INALCANCAVEL`): fonte
  inalcançável vira `lacunas_declaradas`, nunca finding.

## Etapas

1. **Escopo**: sem argumento → eixos acusados pela REGRA 65 (`bash .claude/validation/lint-artifacts.sh`
   ou leia `docs/onion/radar-baselines.yaml`); `E<N>` → só o eixo; `--all` → os 6.
   `--axis <slug>` → eixo AD-HOC (tema livre fora de E1–E6): a rodada usa a lente de
   `common/prompts/research-doctrine.md` e o workflow `/onion-research`; ao selar, o eixo entra em
   `docs/onion/radar-baselines.yaml` como `AX-<slug>` com `last_run` e `kg:` — a REGRA 65 passa a
   cobrar a idade dele como dos demais. Fontes por eixo: `docs/onion/radar-sources.yaml`.
2. **Fan-out** via skill `onion-orchestration` — molde EXECUTÁVEL: o F1 do programa
   (`data/f1-scan-mundo.json` guarda o shape; pipeline scan `sonnet/medium` → juiz `opus/high`
   por eixo, schemas com `source`+`source_date` obrigatórios, `.filter(Boolean)` + contagem de
   descarte). Método nos prompts: **search-by-trajectory** (created:> + sort=stars, HN Algolia)
   e **follow-the-money** — buscar por nome conhecido só acha incumbente.
   A lente inteira (corpus primeiro, tiers de fonte, bi-temporal, revisita) vive em
   [`common/prompts/research-doctrine.md`](../common/prompts/research-doctrine.md) — referencie, não copie.
3. **write(KG)** + radar exit 0 + SYNTHESIS com contrato de custo (run_id/tokens/agents/duration).
4. **Selar a baseline**: atualizar `last_run` e `kg:` do eixo em `docs/onion/radar-baselines.yaml`
   **no mesmo commit** do grafo — baseline sem rodada é o carimbo-sem-medição que o
   `/meta:kg-freshness` existe para impedir.
5. **PR** com resíduo REGRA 56; vereditos que derrubam decisão selada ficam PROPOSTOS (flip é humano).

## Referências

- Programa-mãe (rodada 0, 2026-08-31): `docs/evolution/research/maestro-vivo-2026-08/`
- REGRA 65: `.claude/validation/lint-artifacts.sh` · bancada `run_radar_staleness_selftests`
- Doutrina de pesquisa: memórias `search-by-trajectory-not-by-name` · `follow-the-money-e-eixo-de-pesquisa` · `verify-external-for-current`
