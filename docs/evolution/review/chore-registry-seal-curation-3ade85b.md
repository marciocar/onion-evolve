---
branch: chore/registry-seal-curation-3ade85b
pr: pendente
date: 2026-11-03
reviewed_diff_sha256: f826839beb3b3927b0753b117658538beb9a393d8a21ba7be8d05c314c93ace1
reviewed_code_sha256: 3f6a4877abd79a4056903f195be5ddaaa2df61da1334110d785f9ecdb986d26b
findings_total: 1
findings_real: 0
tokens: 0
duration_min: 2
findings_fixed: 0
verdict: SEM_ACHADOS
elenxo: nao
reviewer: "sessão do core (passada inline; diff de uma linha do registro)"
nota: "tokens 0 = não medido (passada inline, sem subagente)."
---

# Passada adversarial: `chore/registry-seal-curation-3ade85b`

## O que muda

O registro de membros carimba a curadoria no pin `3ade85b7e1c0` (kg-ssot 4.40.2), lido do remoto pelo
`ops/registry-pins.sh --seal --only onion-curation`.

## Achados

1. Hipótese: carimbar um pin que a curadoria não tem na main. Conferido: o `--check` leu o carimbo da main remota da
   curadoria (merge `883fbfd`, PR #183 de lá), e o `--seal` só carimba o que veio do remoto e é commit da integração do
   core. Sem achado.

## Mutantes

Nenhum: não há código.
