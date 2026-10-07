---
title: 'Resíduo — a tabela de tempos medida no runner: as faixas da bancada passam a ser divididas por tempo (etapa B)'
date: 2026-10-07
branch: ci/selftest-family-times
reviewed_diff_sha256: f901c65aeec4778d2ef389ef6fda9c8f0cf805d4f182f3d37b6c321284ed68ca
reviewed_code_sha256: 974a7f326b011809bb30652b3e185a7728df81e3c13f639a8237c170c1684e4e
findings_total: 0
findings_real: 0
findings_fixed: 0
tokens: 0
duration_min: 10
verdict: SEM_ACHADOS
elenxo: nao
nota: >-
  Etapa B do item 3 priorizado pelo maestro. A etapa A (PR #945) fez o CI imprimir ⏱ por família; este PR versiona
  ops/testing/selftest-family-times.tsv, gerado pelo coletor sobre o run 37559434005 (o CI do próprio #945, runner de
  2 núcleos): 217 famílias medidas, as mais caras kg_backlog 927 s, outbox_channel 587 s, adopted_role 442 s. Com a
  tabela, o plano passa do round-robin ao LPT. Medido sobre os mesmos tempos (soma de CPU por faixa, sem fixtures, que
  roda fatiada em todas): round-robin [1159, 2423, 493, 819] → por tempo [1224, 1223, 1224, 1223]; a pior faixa cai de
  2423 s para 1224 s (−49%), sem perder família (bancada shard_plan 6/6, incluindo a cobertura exata). Sem Elenxo,
  declarado: é dado medido consumido por um plano já revisado e com mutante no #945.
---

# Resíduo — `ci/selftest-family-times`

Teto: a tabela envelhece quando famílias mudam de custo ou nascem (família nova entra com a mediana). Refrescar é rodar
`bash ops/testing/collect-family-times.sh <run-id>` sobre um run recente do Onion Selftest e versionar a saída.
