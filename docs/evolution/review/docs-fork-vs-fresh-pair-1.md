---
branch: docs/fork-vs-fresh-pair-1
pr: pendente
date: 2026-10-23
reviewed_diff_sha256: 88b4ec102d2490b51f79c5b5c87b98024a140ef1618ce5f4dcf6f2bff1fdf022
reviewed_code_sha256: 1876b3b3203844cf687147455b56a21afb3c7b64989ab8fd21bb5663160a54f3
findings_total: 0
findings_real: 0
tokens: 0
duration_min: 5
findings_fixed: 0
verdict: SEM_ACHADOS
elenxo: nao
reviewer: "sessão principal (claude-opus-5-5), passada própria"
nota: "tokens não medidos; só selos do kg-decide-seal.sh"
---

# Passada adversarial: `docs/fork-vs-fresh-pair-1`

## O que muda

`E_FORK_VS_AGENTE_NOVO_PAR_1_KG_SSOT_422_1023`: o 1º par medido do teste agente novo contra fork (99k contra
~490k a ~810k tokens), sustentando `Q_FORK_VS_AGENTE_NOVO_TRES_PARES_MEDIDOS`.

## Achados

Nenhum. Ressalva de método declarada no nó: escopos dos forks variaram; o par mais limpo é 4.19.0 contra 4.22.0.

## Mutantes

- Não se aplica.

## Limites declarados

- A execução de cada decisão vem em PRs próprios.
