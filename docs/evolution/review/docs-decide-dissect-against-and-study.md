---
branch: docs/decide-dissect-against-and-study
date: 2026-10-14
reviewed_diff_sha256: 63eac23a10e85219c91bad0037c3dad8769eb915db669e1e3806399d03116198
reviewed_code_sha256: 1be290f65e6081a7aa6432d436fdf94f3f428072e4117e477d5d60f830f9b133
findings_total: 0
findings_real: 0
findings_fixed: 0
tokens: 0
duration_min: 5
verdict: APROVADO
reviewer: passada própria; os dois selos pelo kg-decide-seal.sh, radar e contrato rc 0
---

# Dois selos do maestro sobre o /meta:dissect: régua por alvo e modo estudo

- `D_DISSECT_REGUA_POR_ALVO`: `--against <repo>`, com o Onion como padrão.
- `D_DISSECT_MODO_ESTUDO`: `--study`, que para no N2 sem veredito.

A implementação é a SAC-135 no Linear; este PR só sela as decisões.
