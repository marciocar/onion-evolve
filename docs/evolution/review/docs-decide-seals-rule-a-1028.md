---
title: "Revisão: selos do decide de 2026-10-28 e a regra da data do nó nas re-medições"
date: 2026-10-28
branch: docs/decide-seals-rule-a-1028
reviewed_diff_sha256: 7a83da603caf5d4656762748152c39540dee7dd3203f7885c26e46077fa3c9c6
reviewed_code_sha256: d1029a6d6d0ead779f346047cd359208e95b7511ebc1abf1bee665c43f3d5e7e
pr: pendente
reviewer: "passada adversarial do próprio autor sobre o diff: cada troca de status e de aresta conferida contra o nó lido, a re-medição e as arestas já existentes no grafo"
findings_total: 1
findings_real: 1
verdict: CORRIGIDO
elenxo: sim
tokens: 0
duration_min: 15
nota: "Um achado, curado antes do push: aplicar a regra (A) ao pé da letra daria um segundo SUPERSEDES a dois nós que já estavam superados por outro nó (REC_STAGING_ROT_AND_MISSING_MAILBOX e Q_BACKUP_AINDA_NAO_SAI_DA_MAQUINA). A re-medição ficaria com uma superação que não fez. As duas arestas seguem CONSTRAINS, e a re-medição diz por quê."
---

# Resíduo da REGRA 56

Quatro selos do `/meta:decide` de 2026-10-28, gravados pelo `kg-decide-seal.sh`, e a regra (A)
(`D_STATUS_POR_DATA_DO_NO_NA_REMEDICAO_1028`) aplicada aos nós que os PRs #1413, #1414 e #1415
marcaram DRIFTED.

Gates rodados antes do push: `kg-radar.sh --integrity --schema` com rc 0 nos 13 grafos tocados,
`kg-contract-check.sh` com rc 0 nos 13, `ops/kg-gate-ci.sh` com rc 0 e `radar-aufhebung-check.sh`
com a mesma lista de 5 rodadas SEM-AUFHEBUNG antes e depois (a REGRA 89 não foi contornada).

Ids (para a guarda): D_SINAL_BRAIN_SENSIVEL_FORA_DO_REPO_1028 D_STATUS_POR_DATA_DO_NO_NA_REMEDICAO_1028
D_GATE_LENTO_MEDIR_E_CORTAR_CUSTO_1028 Q_OFFSITE_PARADO_DESDE_1012_GPG_FRIO_1027
E_REMEDIDA_CAPABILITY_BY_SCOPE_1028 D_capability_by_scope
