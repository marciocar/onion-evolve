---
title: "Revisão — 1ª rodada real do /meta:census (22 nós, retomada por carimbo)"
date: 2026-09-01
branch: feat/census-round-1
reviewer: "juiz fixo dentro do run (5/22 reprovados — sem carimbo, motivos na listagem; taxa caiu 29%→23% com o motivo-anterior injetado no prompt); selagem pela ferramenta com abort-por-radar exercitado DE VERDADE (o 1º seal abortou num verified_against duplicado — a 2ª mordida da classe virou dedupe-lei no census-seal.py); radar 0 em 10 grafos; preço/nó recalibrado no doc do comando (80k)"
reviewed_diff_sha256: 4d528c73ad1f2be7586837cb38781c4e418466579d6ea1ac6e85245d2b260540
findings_total: 6
findings_real: 6
verdict: APROVADO
tokens: 1768062
duration_min: 11
---

# Resíduo — REGRA 56

/meta:census rodada 1: 22/22 medidos (0 descartes), 15 CONF/6 DRIFT/1 REFUTED(proposto);
10 carimbos + 6 SUPERSEDES; A-MEDIR 22→6. valeu-a-pena: 80k/nó com juiz incluso, teto 2M
respeitado, retomada KG-runtime provada (população só encolhe). Achado de mecanismo: runtime
do Workflow não lê arquivos — targets vão inline em args (anotado; 1 run morreu no fail-loud
com 0 tokens).
