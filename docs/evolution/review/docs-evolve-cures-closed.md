---
reviewed_diff_sha256: e9c55135fa0aec5c74c72d3bdf930f3c904abd7cc43650bf461bdcd0a6c7140c
findings_total: 0
findings_real: 0
tokens: 0
duration_min: 0
verdict: APROVADO
elenxo: nao
nota: >
  Selo de contabilidade, sem mudança de comportamento: fecha os dois nós de "próxima leva" depois
  que os quatro PRs da leva (#913, #914, #915, #916) entraram no main, cada um com o próprio Elenxo e
  resíduo. A passada adversarial deste diff é o radar (integrity + schema, exit 0) e a conferência
  dos números de PR contra o forge.
---

# Resíduo — `docs/evolve-cures-closed`

Fecha `Q_CURAS_DOS_BLOCKERS_SAO_A_PROXIMA_LEVA` (rodada) e `Q_LEVA2_CURAS_M_RESTANTES` (curas) como
`done`, com `verified_at` e `verified_against` citando os PRs mergeados. O nó da rodada tinha ficado
com `verified_at` e `verified_against` em dobro; o radar reprovou e o par antigo saiu.

## Os `confirmed` dos grafos que este PR edita

- `E_RODADA_CUSTO_E_COBERTURA` (rodada) e os quatro `E_LEVA*` (curas) — intocados; os nós fechados
  aqui são exatamente os que eles sustentam.

Fica aberto, com gatilho próprio: `Q_CYCLE_COMPLETION_MEDE_RECENCIA_PELO_STATE`.
