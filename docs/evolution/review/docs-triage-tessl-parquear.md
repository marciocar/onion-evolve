---
branch: docs/triage-tessl-parquear
pr: pendente
date: 2026-10-15
reviewed_diff_sha256: 154b2e4fe9584dc713642d2dd2bdfbce665068f6dd0a3596ee3078965ef522f8
reviewed_code_sha256: 05ef3492ef8715cb250a7c5db9f6e3622d23d5097567084e924ade93375e8a5c
findings_total: 1
findings_real: 1
tokens: 0
duration_min: 10
findings_fixed: 0
verdict: APROVADO
elenxo: nao
reviewer: sessão principal (conferência do selo no repo da curadoria)
nota: "tokens 0 = não medido: sessão principal, sem subagente; triagem de sinal e selo"
---

# Passada adversarial: `docs/triage-tessl-parquear`

## O que muda

Triagem da proposta da curadoria `2026-10-15-proposal-tessl-parquear` (entregue pelo co-relay, sem commit): o sinal vai para `inbox/_processed/`, e a decisão do maestro entra no core como `D_TESSL_PARQUEADA_2026_10`, pelo `kg-decide-seal.sh`, no grafo `federation-research-2026-06-reconciled` (ligada a `E_TESSL_UNICO_AS_SOURCE_REFUTADO_2026_10`).

## Achados

1. A proposta diz que o selo está em `D_TESSL_STUDY_C` (PR #22 da curadoria). Medido: no `origin/main` da curadoria o nó ainda está `open` (NAO-SELADA); o selo `done` existe só na branch do PR #22, que está aberto. O core registra a decisão do maestro citando o PR, e o selo da curadoria fecha quando o #22 dela mergear. Sem mudança no core.

## Mutantes

Não se aplica: triagem e selo de grafo.

## Limites declarados

- O core não re-mediu a Tessl: os números da proposta são DADO do adotante (R15.2), citados pelos nós dele.
- `Q_VEREDITO_TRAJETORIA_PERDEU_PREMISSA_TESSL` segue aberta: é outra pergunta.
