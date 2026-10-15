---
branch: docs/a2a-ratify-decisions
pr: pendente
date: 2026-10-15
reviewed_diff_sha256: pendente
findings_total: 1
findings_real: 1
tokens: 0
duration_min: 5
findings_fixed: 1
verdict: CORRIGIDO
elenxo: nao
reviewer: sessão principal (selador kg-decide-seal.sh + radar)
nota: "tokens 0 = não medido: selos pelo /meta:decide, sem subagente; só grafo"
---

# Passada adversarial: `docs/a2a-ratify-decisions`

## O que muda

Selos do `/meta:decide` (2026-10-15) no grafo `a2a-configurator-2026-10`, pelo `kg-decide-seal.sh`: o maestro ratificou `D_PISO_2048_NO_REGISTRO_3072_NO_KEYGEN`, `D_PACOTE_DE_ENTRADA_LEVA_OS_MOTORES` e `D_TOKEN_STDIN_PARA_A_CONTA_DO_SERVICO`, e decidiu `D_POOL_LEGADO_SAI_JA` (esvaziar o pool anônimo já).

## Achados

1. O selador recusou o nó novo (rc 2) pelo TETO de 30 nós do grafo. Curado: o teto subiu para 31 no `meta:`, com o motivo na linha, como as anteriores.

## Mutantes

Não se aplica: só selos de grafo, sem código.

## Limites declarados

- O ato de esvaziar o pool no ambiente do bridge é do maestro (o update-bridge não edita o ambiente); o selo registra a decisão, não o ato.
