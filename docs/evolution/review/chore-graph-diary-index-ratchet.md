---
title: "Revisão — fio aberto: índice do diário sem catraca"
date: 2026-08-28
branch: chore/graph-diary-index-ratchet
reviewer: "self-review — 1 nó de grafo, verificado por kg-radar (integridade + estado)"
reviewed_diff_sha256: 92d42214d567fb4743eabd59f0658b367a8cca6e53ff2036433b56ab23e33171
findings_total: 1
findings_real: 1
verdict: APROVADO
tokens: 2500
duration_min: 3
---

# Resíduo — REGRA 56

Um nó `status: open` + uma aresta. Sem lógica, sem guarda nova — **registro** de um fio que
seria perdido.

## O achado

O furo (migalha do PR #700 invisível no `index.md`) estava documentado **apenas** no artefato
de revisão do PR #701. Artefato de revisão **não é fonte do backlog**: `docs/backlog.md`
projeta dos nós `status: open` dos grafos. Fio fora do grafo é fio órfão.

## Verificação

- `kg-radar`: **43 nós, 46 arestas, sem contradições estruturais**.
- O nó entra na seção **ESTADO** (fila de abertos) com atenção 5.4 — visível, não afundado.
- **Gatilho nomeado**, não condição vaga: *a próxima migalha escrita nesta instância*. Sem
  gatilho, nó aberto vira item morto de backlog (`C_BACKLOG_DE_DOCUMENTO_ORDENA_ITEM_MORTO`).
- Sem `verified_at` inventado: o campo carrega a medição real (106→107 pelo gerador).
