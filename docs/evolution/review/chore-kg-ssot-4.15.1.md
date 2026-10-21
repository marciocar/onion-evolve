---
branch: chore/kg-ssot-4.15.1
pr: pendente
date: 2026-10-21
reviewed_diff_sha256: pendente
findings_total: 0
findings_real: 0
tokens: 0
duration_min: 5
findings_fixed: 0
verdict: SEM_ACHADOS
elenxo: nao
reviewer: sessão principal
nota: "tokens 0 = não medido; vendor por kg_vendor.py com sha256 por arquivo"
---

# Passada adversarial: `chore/kg-ssot-4.15.1`

## O que muda

O vendor `vendor/kg-ssot` vai da 4.15.0 para a 4.15.1 (contrato v4.9), a base do gate foi regravada e o
comentário do pin foi alinhado.

## Achados

Nenhum. Pelo `ops/kg-gate-ci.sh`, são 181 grafos e os mesmos 16 na dívida herdada. Só a identidade
muda, como a sessão do kg-ssot avisou. O vendor está íntegro (490 arquivos).

## Mutantes

Não se aplica.

## Limites declarados

O CADENCE-UNSTAMPED do radar lê a lista `unstamped` do due/1, que a sessão do kg-ssot diz não mudar.
Não reconferi isso com um grafo de fixture nesta subida.
