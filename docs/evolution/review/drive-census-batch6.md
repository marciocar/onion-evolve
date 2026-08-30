---
title: "Revisão — censo lote 6: a faixa de julho morre 62%, e o juiz mediu por comportamento"
date: 2026-08-30
branch: drive/census-batch6
reviewer: "mesmo desenho selado: 30 workers × 11 juízes opus/high × tabela de selagem; radar exit 0 nos grafos tocados"
reviewed_diff_sha256: ce2f52315732f2aaa0cf8bbefbeda00a91ba5e1816e8692b14ec28ab8d348915
findings_total: 18
findings_real: 18
verdict: APROVADO
tokens: 2886111
duration_min: 13
---

# Resíduo — REGRA 56

Lote 6 (itens 151-180; atenção 2,4-4,0). **29/30 medidos, 1 descarte NOMEADO**
(`D_ISOLATION_EXTENSION_GATED` — 5/5 rejeições de schema, mesma classe de omissão do REC2;
retorna no lote 7).

## O número

**Mortalidade: 18/29 = 62%** — a faixa é dominada por nós de julho, e a série ganha forma:
53 · 50 · 47 · 53 · 37 · **62**. **Acumulado: 90 mortos em 179 medidos = 50%.**

## Os 18 flips (7 → done · 11 → superseded)

Destaque: `Q_AUTORIZACAO_NAO_FORMALIZADA` — formalizada em 07-30 (PR #497, `AUTH_visitor` +
`topology-projection.sh --authorities`, **executado ao vivo pelo worker**) e aberta por um mês
depois de paga.

## O juízo — 10/11 REPROVADOS, 1 carimbado

O juiz do `Q_REVERSE_JOIN_SCOPE` deu a aula do lote: o worker grepou o **exemplo literal** do
label (`# scope:`) e concluiu ausência; o juiz mediu por **comportamento** e achou que
`.claude/rules/kg-grammar.md` já declara `paths:` em frontmatter — escopo machine-readable,
HARD-enforçado pela REGRA 53, **nascida depois do nó**. E a claim "N=0 pediu" foi medida por
NOME, não por trajetória — a lente que por construção não podia achar demanda.

## Gate mecânico

- radar exit 0 · `docs/backlog.md`: **120 → 102** (REGRA 62) · baseline R49 estável
- custo: 2,09M + 0,80M = **2,89M** · runs `wf_f5bedede-dfb` + `wf_2d6173e4-9bf`

## Estado do censo

**179/190 medidos (94%) · 90 mortos · backlog 190 → 102.** Lote 7 final: 9 itens + o descarte.
