# Fixture de drift — caso GOOD (Regra 16, linha 'Total' de tabela de CUSTO)

| Run | Modo | Tokens | Agentes | Duração |
|---|---|---|---|---|
| `wf_a` | varredura | 7.481.207 | 106 | 25 min |
| `wf_b` | primárias | 1.268.552 | 16 | 18 min |
| **Total** | | **8.749.759** | **122** | **43 min** |

A coluna do 1º valor é `Tokens`, que não é população da SSOT, e `8.749.759` é UM número
(separador de milhar), nunca `8`. A Regra 16 deve CALAR. Reproduz o falso-positivo medido
em 2026-10-20 na síntese de pesquisa chat-agent-isolation-2026-10.
