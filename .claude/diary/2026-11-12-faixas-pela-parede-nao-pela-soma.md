---
date: 2026-11-12
instance: onion-evolve
type: learning
classification: public
tags: [ci, selftest, lanes, scheduling]
affects: [engineering]
breadcrumb_for: []
share_with: []
next_recommended: "Conferir a pior faixa projetada contra os tempos reais dos próximos 10 runs"
review_after: 2027-02-10
conflict_class: dynamic
significance: "A régua pela soma aprovava um plano em que a família mais cara rodava sozinha no fim com três workers parados."
---

## Signal
Repartir trabalho entre faixas paralelas pela soma dos tempos esconde a ordem da fila. A medida certa é a parede
simulada da fila. E CI vermelho por tempo de runner não é causa para reverter commit.

## Evidence
- PR #1619: a família mais cara (cerca de 819 s) rodava no fim da fila com 3 de 4 workers ociosos; o plano novo de 6 faixas projeta a pior em 16,7 min, e cerca de 10 min de runner a menos por execução.
- O refutador reprovou por uma afirmação falsa de precisão e por mutantes sobreviventes (inclusive a ordem alfabética da fila); curados.
- PRs #1628 e #1633: dois reverts automáticos da main fechados sem merge, porque a causa medida era o tempo do runner.

## Next crumb
O desbalanço entre workers dentro de uma faixa não está modelado; medir antes de subir o número de faixas.
