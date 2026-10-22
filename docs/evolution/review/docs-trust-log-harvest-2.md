---
branch: docs/trust-log-harvest-2
pr: pendente
date: 2026-10-22
reviewed_diff_sha256: e6fb510feace914fe8a5c409ef8c855b4d18ffc7a9f0aa22083cfe6aa4156369
reviewed_code_sha256: 10e1c9882f6d8328b18173354390d90c35ac3d60cf07dfdff1cffa19d5f19d7a
findings_total: 0
findings_real: 0
tokens: 0
duration_min: 2
findings_fixed: 0
verdict: SEM_ACHADOS
elenxo: sim
reviewer: sessao-principal
nota: >-
  A última linha que o gate gravou no clone servido antes do deploy da cura (r1 do A7-C1, 02:37 UTC),
  guardada no stash pre-update-2026-10-22-031857. Conferido: é a única linha do stash, não estava no
  trust-log do core, e não casa token/segredo.
---

# Passada adversarial: `docs/trust-log-harvest-2`

## O que muda

Uma linha no `docs/evolution/trust-log.md`, colhida do último stash do clone servido.

## NÃO MEDIDO

Nada: depois do deploy do bridge #82 o gate grava em `data/a2a-trust-log.md` do bridge, e o clone
servido ficou limpo (medido na r2).
