---
branch: docs/decide-seals-1025
pr: pendente
date: 2026-10-25
reviewed_diff_sha256: 77b40cc5cef1f4da0ded3b1d171c69249c3f3c1e4cf7690bd96d4e34e83fe8ad
reviewed_code_sha256: c3b94711da7622adae1508938f7e43b6a86e2746006a76ba2cf623103bd3d605
findings_total: 1
findings_real: 1
tokens: 0
duration_min: 5
findings_fixed: 1
verdict: CORRIGIDO
elenxo: nao
reviewer: sessão principal (onion-evolve-bd), passada própria sobre o diff
nota: "tokens 0 = não medido (passada na própria sessão, sem subagente); os selos saíram do kg-decide-seal.sh, que exige radar e contrato rc 0"
---

# Passada adversarial: `docs/decide-seals-1025`

## O que muda

Três selos do maestro pelo `/meta:decide`, todos escritos pelo `kg-decide-seal.sh`:

- `Q_FECHAR_SAC_239_COM_O_REVISOR_PROVADO_1024` (radar-E3 r18): fecha com o pin declarado. A execução do revisor
  não foi medida por falta de crédito. A SAC-239 foi para Done no Linear, com comentário.
- `Q_HUB_1019_BACKLOG_COM_GATILHO`: os gatilhos de U6, C4 e C9 selados.
- `Q_DISSECT_MOTOR_PARQUEADO_OBJETO_EXTRA`: o motor segue parqueado.

## Achados

1. REAL, corrigido aqui e com mecanismo pendente: o `kg-decide-seal.sh` copia o `verified_against` e a proveniência
   anteriores para a `narrative`, que o lint de nomes lê e o `verified_against` não. O "r18" do texto antigo virou
   `vocab.code-unresolved`, e o selador saiu 0 assim mesmo, porque confere o radar e o contrato e não o lint de
   nomes. Aqui o código foi trocado pela glosa. A cura de classe é o selador rodar o lint de nomes antes de dizer
   ✅, e isso fica para o PR seguinte.

## Suspeitas descartadas

1. Fechar a SAC-239 escondendo que o revisor não rodou: descartada. O selo e o comentário no Linear dizem que a
   execução não foi medida e por quê.
