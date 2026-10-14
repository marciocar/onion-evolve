---
branch: docs/decide-sandbox-and-precompact
date: 2026-10-14
reviewed_diff_sha256: pendente
findings_total: 1
findings_real: 1
findings_fixed: 1
tokens: 0
duration_min: 10
verdict: REPROVADO_E_CURADO
reviewer: passada adversarial própria (sem subagente); os dois selos pelo kg-decide-seal.sh, radar e contrato rc 0
---

# Dois selos do maestro pelo /meta:decide: o sandbox do B1 e a SAC-117

- `D_SANDBOX_B1_APAGADO` (grafo postmerge-projection-writer): escolhida **Apagar**. Executado: `gh repo delete` e,
  depois, `gh repo view` não acha o repo.
- `Q_COMPACTACAO_OCIOSA_DISPARA_O_PRECOMPACT` (r10 do radar E3): escolhida **Retomar pelo grafo**, o PreCompact
  não é estendido. Executado: SAC-117 comentada e em Done no Linear (conferido pelo `tm.sh`).

## Passada adversarial

1. **O selo coube no grafo?** Real, curado: o 1º selo do sandbox foi recusado pelo TETO do grafo (104 contra
   103). O teto subiu +1 com a linha de motivo, como o selador pede, e o selo passou.
