---
title: 'Resíduo — dois nós da fila cumpridos pela adoção do contrato v3 são fechados com medição'
date: 2026-10-08
branch: chore/queue-verify-contract-nodes
reviewed_diff_sha256: pendente
findings_total: 0
findings_real: 0
findings_fixed: 0
tokens: 0
duration_min: 10
verdict: SEM_ACHADOS
elenxo: nao
nota: >-
  /meta:drive, lote de 2026-10-08 à tarde, KIND verification. O censo da fila-2026-10-06 trazia no topo
  Q_KG_SCHEMA_FORMAL (atenção 7,2), e logo depois Q_ROTULO_SEPARADO_DA_NARRATIVA, que depende dele.
  Os dois já estavam cumpridos por execução mergeada. Medido: PR #967 mergeado em
  2026-10-08T05:27:28Z (69409a84e3b5), com o contrato v3 (JSON Schema 2020-12) vendorizado e o gate por
  grafo no CI (run 37731420161, 142 de 142 no MUST); o schema vendorizado tem narrative no nó e o PR #969
  (6a6c55a4b940) ensinou os geradores a escrevê-lo. Os dois flips open→done vêm com verified_at entre
  aspas e verified_against citando PR, commit e run; o corpus antigo segue como SAC-73. Radar --integrity
  --schema exit 0 e kg-contract-check.sh rc 0 (sem piorar o SHOULD herdado). REGRA 87 (PR que EDITA um
  .kg.yaml enxergou os confirmed dele): o grafo editado é o da fila, cujos confirmed foram listados nos
  resíduos de hoje e seguem como estavam. Sem Elenxo, declarado: fechamento por medição de execução já
  mergeada. Pre-commit pulado por ordem do maestro; validação = pr-finalize + CI.
---

# Resíduo — `chore/queue-verify-contract-nodes`
