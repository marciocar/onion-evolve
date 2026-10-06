---
title: 'Resíduo — anúncio das curas de 2026-10-06 aos dois hubs'
date: 2026-10-06
branch: chore/announce-cures-2026-10-06
reviewed_diff_sha256: d28d3ed0415b5a75a92bd66bec42f91a8288c4098366fe6a711243cd843af890
reviewed_code_sha256: a49c05e3b96ca8c079c4806f136f97a2005ee40ebef7483c2860ed4cc1a36723
findings_total: 0
findings_real: 0
findings_fixed: 0
tokens: 0
duration_min: 5
verdict: SEM_ACHADOS
elenxo: nao
nota: >-
  PR sem superfície executável: uma entrada no CHANGELOG de co-evolução, dois anúncios na staging
  (outbox/hub-operacoes-enterprise e outbox/brain-granaai) e os três sinais de 2026-10-05 movidos para
  inbox/_processed, porque as curas estão em main: #932 e #934 para o setup-integration, e #936 para o
  attribution e a branch de produção. Os anúncios citam só o que foi medido nos PRs (36 escapes fechados
  no veto e 24 adotantes medidos no resolve-production-branch). Sem Elenxo, declarado. Os três sinais
  novos do onion-slm (2026-10-06) ficam no inbox para triagem própria.
---

# Resíduo — `chore/announce-cures-2026-10-06`

O transporte ao `inbound/` de cada hub é entrega-sem-commit pelo `co-deliver.sh` (I3), depois do merge.
