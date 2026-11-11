---
branch: docs/seal-peerbus-vm-1111
pr: pendente
date: 2026-11-11
reviewed_diff_sha256: 1d8a0d6102f9f14de8344335a713ef944c7c5595469b9ac53479e7fac9882a6c
reviewed_code_sha256: 0d6271ec08f97d86545c195fa245d3736152423a600c0b39c610adcee6efbdb9
findings_total: 1
findings_real: 1
findings_blocking: 0
tokens: 0
duration_min: 5
findings_fixed: 1
verdict: NO_FINDINGS
elenxo: false
reviewer: passada própria da sessão do core sobre o diff, sem revisor independente
nota: "tokens 0 = não medido. Um selo que faltou no PR #1591."
---

# Passada adversarial: `docs/seal-peerbus-vm-1111`

## O que muda

Grava o selo `D_SEAL_CH_PEERBUS_VM_PARK_1111` (parquear o peerbus de vitaminmoo), respondido pelo maestro no
/meta:decide de 2026-11-11 e que faltou no PR #1591.

## Achados

1, corrigido: na 1ª tentativa o lint de nomes recusou o código «E3» sem glosa no label, e o selador desfez a
escrita (rc 3). A saída foi lida cortada, e o selo foi dado por feito. A curadoria apontou o furo ao contar os
nós. O label agora diz o critério por extenso (30 dias e uma release).

## Mutantes

Não se aplica: nenhum código mudou.
