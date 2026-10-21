---
branch: docs/r14-bridge-sdk-306
pr: pendente
date: 2026-10-21
reviewed_diff_sha256: pendente
findings_total: 0
findings_real: 0
tokens: 0
duration_min: 3
findings_fixed: 0
verdict: SEM_ACHADOS
elenxo: nao
reviewer: sessão principal
nota: "tokens 0 = não medido; um nó novo medido pelo censo, que supera o nó da r14 sobre o SDK atrasado"
---

# Passada adversarial: `docs/r14-bridge-sdk-306`

## O que muda

Um nó PROD no grafo da r14, `E_SDK_DO_BRIDGE_EM_0_3_306_EM_PRODUCAO_1021`, que supera o nó do SDK atrasado
(este vira `superseded`).

## Achados

Nenhum. Reconferi a versão pelo `cc-delta-census.sh`, que lê o binário: 2.1.306 (SDK 0.3.306). O estado
dos PRs veio do `gh pr view`.

## Mutantes

Não se aplica.

## Limites declarados

A saída do deploy foi colada pelo maestro. A versão, porém, eu medi por conta própria.
