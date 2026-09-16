---
name: census
description: >
  Censo populacional do backlog — mede os nós open contra o VIVO (censo+realidade) com juiz
  fixo, sela pela tabela AUDIT e projeta a listagem REAL. KG-SSOT first e runtime: o estado de
  retomada É o carimbo nos grafos; re-invocar mede só o que resta. Incremental e com teto que
  PARA (não que declara) — nasceu porque a forma rodou 2x a 5M+ renascendo em /tmp.
category: meta
tags: [census, backlog, kg, verification, orchestration, cost-discipline]
version: "1.0.0"
updated: "2026-09-01"
argument-hint: "[--all | --window N=14 | --floor A=0 | --teto T=2000000]"
related_commands:
  - /meta:kg-freshness
  - /meta:backlog
  - /meta:drive
allowed-tools: Bash, Read, Write, Edit, Task, Workflow
---

# 🧮 /meta:census — o backlog inteiro, medido e não lembrado

## Invariantes

- **KG-SSOT first/runtime.** O grafo é fonte E estado: a partição FRESCO/A-MEDIR sai do
  `verified_at` dos próprios nós (extração determinística, 0 tokens). Retomada é grátis:
  re-invocar re-extrai e só mede o resto. A listagem é PROJEÇÃO — nunca fonte.
- **Custo que vale a pena** (ordem do maestro, 2026-09-01, após rodada de 5,39M):
  incremental por default (`--window 14`); **teto ENFORÇADO por contagem** no molde
  (max_nós = teto ÷ preço/nó; excedente sai NOMEADO como não-medido-por-teto);
  `--all` (window 0) é decisão explícita, nunca default.
- **Re-testar, nunca re-carimbar**: só medição executada gera `verified_at` novo. Juiz fixo
  (opus/high, calibração 2026-08-29) audita CONFIRMED e GATED-não-disparado; reprovado fica
  SEM carimbo, com o motivo listado.
- **Flips de status = PROPOSTOS** (tabela de selagem do /meta:drive); maestro sela.
- **Maestro-invocado** (W7 = MOAT). O relógio é a REGRA 65/62 — a máquina detecta, você roda.

## Etapas

1. **Extrair** (F0): `bash .claude/validation/kg-census-extract.sh [--window N] [--floor A] > alvos.json`
   — fail-loud se a projeção e o parser divergirem. Declare o corte (frescos/piso) no relatório.
2. **Medir** (F1+F2): `Workflow({scriptPath: '.claude/utils/census/census-workflow.mjs',
   args: {targets: <medir do alvos.json>, teto: T, price_per_node: <última medição>}})`.
   Retomável por `resumeFromRunId`.
3. **Selar** (F3): salvar o resultado consolidado em
   `docs/evolution/research/census-<data>/data/` e rodar
   `python3 .claude/utils/census/census-seal.py seal <consolidado.json>` — radar exit 0 em todo
   grafo tocado ou ABORTA antes do commit. **Aresta pela realidade** (2026-09-02): DRIFTED com
   realidade `MORTO-CANDIDATO`/`FORA-DO-CORE` recebe `SUPERSEDES` (flip do alvo proposto);
   `GATED`/`REAL-ACIONAVEL` recebe `CONSTRAINS` (o superseder REFINA, o alvo segue `open` —
   flipar apagaria trabalho pendente do backlog; 13 alvos ficaram assim após 2 censos).
4. **Projetar** (F4): `census-seal.py list <consolidado.json> docs/analysis/backlog-real-<data>.md <alvos.json>`
   + `kg-backlog-project.sh --write` + nó `evidence` do run no grafo de programa vigente.
5. **PR** com resíduo REGRA 56; merge pelo fluxo normal.

## Seção obrigatória do relatório: `valeu-a-pena`

tokens REAIS (da notificação do run) ÷ nós medidos, comparado ao histórico
(2026-08-30: ~68k/nó · 2026-09-01 revisão: ~74k/nó · 2026-09-01 rodada-1 do comando: ~80k/nó — 1.768.062÷22, JUIZ INCLUSO). Regressão de custo/nó é ACHADO do relatório, não
rodapé — e recalibra o `price_per_node` da próxima invocação (atualize este doc).

## Referências

- Extrator: `.claude/validation/kg-census-extract.sh` · Molde: `.claude/utils/census/census-workflow.mjs`
- Selagem/listagem: `.claude/utils/census/census-seal.py` · Bancada: `run_census_extract_selftests`
- Semântica do censo: `backlog-real-2026-09` (core-only) (1ª listagem) · calibração do juiz:
  `docs/evolution/research/kg-freshness-dogfood-2026-08/calibration-gold-standard-2026-08-29.md`
