---
branch: docs/curation-seals-1108
pr: pendente
date: 2026-11-08
reviewed_diff_sha256: b4dfd270360a83f987850536c6005e87ab9d29a9ed1fece8263a974fd992872a
reviewed_code_sha256: 8a783de53ce869f94cb389eaa7b1850fc91fdf3cdeb2162cba9bd81ac92f5964
findings_total: 1
findings_real: 1
findings_blocking: 0
tokens: 0
duration_min: 10
findings_fixed: 1
verdict: FIXED
elenxo: false
elenxo_isolado: false
reviewer: passada própria sobre o próprio diff (sem subagente); gate mecânico kg-radar --integrity --schema e kg-contract-check
nota: "tokens 0 = não medido. Grafo novo de 3 nós, sem código."
---

# Passada adversarial: `docs/curation-seals-1108`

## O que muda

Grafo novo `curation-seals-2026-11`, com os nós dos selos que o anúncio da onda 2 dava só em prosa:
`D_SEAL_PIECE_CH_MECHANISM_1108` e `D_SEAL_YW_PARKS_1108`.

## Achados

1. **O anúncio afirmava selo sem nó (REAL, curado).** O checador de dissecação da curadoria exige
   `x_dissect_sealed_by` apontando o nó. Selo em prosa não é mecanismo. A cura é este grafo.

## Mutantes

Não se aplica: o diff é dado de grafo, sem lógica. O gate é o radar e o contrato.

## Limites declarados

- Os dois selos foram dados pelo core em nome do maestro, no modo autônomo, e são revogáveis por ele.
