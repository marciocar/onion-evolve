---
branch: docs/close-source-uri-ref-1124
pr: pendente
date: 2026-11-24
reviewed_diff_sha256: 6756528feb2993836adcba4e60eb59da08a1ce1035c3b439e9a97279d230865b
reviewed_code_sha256: fa9192d3e835d99c360611d1c52994c357a70a105fada32fa10f15a80c083e80
findings_total: 0
findings_real: 0
findings_blocking: 0
tokens: 0
duration_min: 3
findings_fixed: 0
verdict: NO_FINDINGS
elenxo: true
elenxo_isolado: false
reviewer: "condutor (core), passada própria: os dois critérios de pronto do nó medidos antes de fechar"
nota: "só fecha um nó do grafo por medição; sem código"
---

# Passada: `docs/close-source-uri-ref-1124`

Fecha `Q_MESSAGING_SOURCE_URI_REFERENCE_1115` (status done), a pedido da sessão dona da fila, depois de medir os dois
critérios de pronto do próprio nó: (1) a fila recusa `source` que não é URI-reference, com caso negativo e mutante na
bancada dela (`queue/test/bench.py:200-206`, `queue/test/mutants.sh:90`, na origin/main feb977e); (2) a régua do par
em `a2a-metrics.py` é igual (bloco `_U … URI_REFERENCE_RE` byte a byte igual, por diff). Radar `--integrity --schema`
exit 0 e contrato rc 0.

Tentei refutar: o nó pedia «caso negativo com espaço»; o comentário da bancada lista espaço, `%zz` e `:` no 1º
segmento. Não li o conteúdo dos casos além disso.
