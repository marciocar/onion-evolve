---
branch: docs/a2a-s6-live-proof
pr: pendente
date: 2026-10-15
reviewed_diff_sha256: pendente
findings_total: 1
findings_real: 1
tokens: 0
duration_min: 10
findings_fixed: 1
verdict: CORRIGIDO
elenxo: nao
reviewer: sessão principal (radar + contrato KG-SSOT)
nota: "tokens 0 = não medido: sessão principal, sem subagente; prova viva e registro"
---

# Passada adversarial: `docs/a2a-s6-live-proof`

## O que muda

Registra o S6 do configurador A2A, provado em produção em 2026-10-15: o nó `E_S6_PONTA_A_PONTA_EM_PRODUCAO` no grafo `a2a-configurator-2026-10` (teto 31→32, com motivo) e o sinal de teste aceito no inbox, já triado para `_processed/` (era sinal de teste, descartável).

## Achados

1. O contrato KG-SSOT reprovou o nó por caminho de máquina (`~/`, REGRA 99 (Nó de .kg.yaml sem caminho de máquina, julgado pela classe)). Curado: o caminho virou descrição.

## Mutantes

Não se aplica: registro de grafo e de inbox, sem código.

## Limites declarados

- As duas contas de sistema do S6 do plano não foram criadas: membro e core rodaram na mesma conta. Declarado no nó.
- O registro da fila do bridge fica até a limpeza humana (escrita na conta do serviço, sem wrapper).
