---
branch: chore/decide-park-r14
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
nota: "tokens 0 = não medido; três selos do kg-decide-seal.sh e a validade de uma migalha"
---

# Passada adversarial: `chore/decide-park-r14`

## O que muda

Três decisões novas no grafo da r14 (`D_ESTACIONAR_SAC180_*`, `D_ESTACIONAR_SAC181_*`,
`D_ESTACIONAR_SAC182_*`), ligadas às perguntas que continuam abertas. Elas registram o estacionamento
escolhido no `/meta:decide`. A migalha do resume passa a vencer em 2026-11-21, e o motivo ficou escrito nela.

## Achados

Nenhum. Cada escolhida bate com a resposta: a SAC-182 foi resposta livre («colocar no estacionamento»),
selada com `--other`. As perguntas ficaram `open` de propósito, porque estacionar não é fechar.

## Mutantes

Não se aplica.

## Limites declarados

Mover a validade da migalha não a re-testa. O re-teste é a própria SAC-180.
