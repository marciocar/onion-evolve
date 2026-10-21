---
branch: chore/kg-ssot-4.15.1
pr: pendente
date: 2026-10-21
reviewed_diff_sha256: 176a12b8a0ec4d15b29b18e13e1d68e47d6cfe2af7dc5dda6c51dfc66a0fcf93
reviewed_code_sha256: cc6bc7326f3daa0a1e12a290f1aca73ab058e1c6815cd5ee38c9f97f6b18b470
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
