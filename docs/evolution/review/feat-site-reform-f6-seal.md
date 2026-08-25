---
title: "Revisao — selagem F6 da reforma do site (self-review, docs-only)"
date: 2026-08-25
branch: feat/site-reform-f6-seal
reviewer: "self-review (autor) — docs-only: carimbos de grafo validados por kg-radar exit 0, projecoes regeneradas por MECANISMO (o proprio lint cobrou o console; diary-index reprovou o conflict_class invalido e foi obedecido)"
reviewed_diff_sha256: edd6a1ec12901cd8c014d46c602973875bfe938bc26521a9a880cc21c7438494
findings_total: 2
findings_real: 2
verdict: APROVADO
tokens: 12000
duration_min: 8
---

# Residuo — REGRA 56 (selagem F6; self-review com os gates mecanicos como revisores)

Diff docs-only: graduacao de Q_PUBLICATION_AREA (done, verified_at contra o vivo por curl),
fio novo Q_RADAR_WIDGET_PARALLEL_FORMULA com gatilho nomeado + aresta (radar exit 0, 22 nos/
17 arestas sem contradicao), invencao #16 ativa na KB, migalha do diario, CHANGELOG + console.

Os 2 achados REAIS foram dos gates mecanicos, nao meus:
1. diary-index REPROVOU conflict_class 'none' (invalido; enum dynamic|static|conditional) — corrigido.
2. pre-commit REPROVOU o console da federacao desatualizado vs a SSOT que o CHANGELOG novo mudou —
   regenerado pelo comando que a propria violacao dita.

**Veredito: APROVADO** — a classe de risco de um seal docs-only e projecao dessincronizada, e as
duas dessincronizacoes possiveis foram pegas e curadas pelos gates de mecanismo.
