---
title: Radar E3 r16 — o delta do Claude Code 2.1.308 contra o Onion
date: 2026-10-22
kg: docs/evolution/research/radar-E3-2026-10-22-r16/radar-E3-2026-10-22-r16.kg.yaml
run_id: "nenhum (rodada conduzida por um fork da sessão, sem Workflow e sem subagente juiz)"
tokens: 0
agents: 0
duration_min: 20
review_after: 2026-11-21
type: research
mode: cc-update
---

> **Projeção do grafo, nunca fonte.** Tokens 0 = não medidos: a rodada rodou dentro de um fork da sessão.

## O que mediu

A rodada mediu 1 versão, a 2.1.308, com 1 item: "Bug fixes and reliability improvements". A cópia do CHANGELOG
bate byte a byte com a fonte. Pela 1ª vez as três superfícies que rodam o Claude Code estão na mesma versão: o
host (2.1.308), o /chat do bridge (SDK 0.3.308, CLI embutido 2.1.308) e o revisor do CI (action v1.0.258, que
pede o Agent SDK ^0.3.308).

## O que toca a casa

- O item da 2.1.308 não nomeia superfície: nenhuma ligação (`E_ITEM_UNICO_SEM_SUPERFICIE_NOMEADA_1022`).
- A paridade das três superfícies (`E_TRES_SUPERFICIES_EM_PARIDADE_2_1_308_1022`) supera dois nós da r15: o
  /chat uma versão atrás e o pin do revisor em v1.0.257.
- A prova do revisor num PR com a label `review:ia` passa ao pin v1.0.258
  (`Q_REVISOR_NO_PIN_1_0_258_PROVADO_NUM_PR_COM_A_LABEL`), estacionada como a SAC-181, sem issue nova.
- Achado da própria rodada: o `cc-delta-census.sh` zera a contagem de citações de `scriptPath` numa worktree
  sob `/worktrees/`, porque filtra pelo caminho absoluto (8 no clone principal, 0 na worktree). Virou
  `Q_CENSO_FILTRA_WORKTREE_PELO_CAMINHO_RELATIVO_1022` e a issue SAC-219.
- A guarda de deriva de binário (`cited_directive`) segue verde na 2.1.308.

## Juiz

Os critérios foram pré-registrados em `data/judge-verdicts.json` (CU1 a CU4), e cada um foi re-executado no
vivo: 8 SUSTENTA, 0 negativos, 0 superações achadas; `judge-verdict-check.sh` rc 0. **O juiz não foi
independente:** a rodada rodou num fork da sessão, e a regra de fork proíbe lançar subagente. Com um item
genérico no delta, o risco de uma ligação esticada é baixo, mas fica declarado.

## NÃO-VERIFICADOS

- A versão exata do CLI no runner do CI: o pin e o `package.json` da action foram lidos, mas nenhum log de job
  com a label `review:ia` (é a própria pergunta estacionada).
