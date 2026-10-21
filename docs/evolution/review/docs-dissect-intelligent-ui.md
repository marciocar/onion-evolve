---
branch: docs/dissect-intelligent-ui
pr: pendente
date: 2026-10-21
reviewed_diff_sha256: 860a3e82e9fe6f30879f50ac7b70e1c6394379367f56452dd8622e9b18299975
reviewed_code_sha256: bf03f1a60365355eec30c28b7721807993732f0ef1e3ee09f9e725ec451fecae
findings_total: 1
findings_real: 1
tokens: 0
duration_min: 15
findings_fixed: 1
verdict: CORRIGIDO
elenxo: sim
reviewer: sessão principal (o Elenxo do run wf_95b7868c-c7d é a passada adversarial do conteúdo)
nota: "tokens 0 = não medido na passada da sessão"
---

# Passada adversarial: `docs/dissect-intelligent-ui`

## O que muda

A dissecação nova `intelligent-ui-2026-10`, com 31 nós, a SYNTHESIS e o retorno do run. Inclui o
veredito proposto (open) e dois planos N4 que o `dissect-plans.sh` lê como COMPLETOS.

## Achados

1. Os nós de plano nasceram com `node_type: action`, que a gramática não tem. O radar e o contrato
   reprovaram. Curado com `claim` open, como no plano do conductor.

## Mutantes

Não se aplica: o diff tem dado de dissecação e nenhuma guarda.

## Limites declarados

- O objeto (a UI do GPT-6) não foi lido. O veredito vale para o mecanismo aberto.
- O retorno do run teve o caminho de máquina trocado por caminho relativo.
