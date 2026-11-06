---
branch: ops/lease-psi-30
pr: pendente
date: 2026-11-06
reviewed_diff_sha256: 86ba6f2518aceaa3374b108d1e848144170a15c66fe6d49c589d8592a0f7d4a7
reviewed_code_sha256: 64456be8a6689f705365a810321f27ee33cba9e52a4638269e2921e062e518e9
findings_total: 1
findings_real: 1
findings_blocking: 0
tokens: 0
duration_min: 10
findings_fixed: 1
verdict: CORRIGIDO
elenxo: nao
reviewer: sessão principal do core (passada própria, não independente)
nota: "tokens 0 = não medido. Muda um valor de configuração e o selo da decisão; o código do lease não muda."
---

# Passada adversarial: `ops/lease-psi-30`

## O que muda

- `ops/load-lease.conf` liga `ONION_LOAD_PSI_HIGH=30`; HIGH 15 e RESUME 12 ficam.
- O nó `D_SO_LIMITES_DERIVADOS_DO_LEASE_1106` é selado pelo `kg-decide-seal.sh` com a escolha do maestro de 2026-11-06.

## Achados

1. **Real, curado:** a primeira edição do cabeçalho do `.conf` deixou a frase quebrada («está aberta para o maestro selou»). Reescrita para dizer que a sugestão foi a mesa da decisão e que o maestro selou 15/12 com psi 30.

## Mutantes

Nenhum novo: a família `load_lease` da bancada já cobre o PSI ligado (ocupa com psi ≥ teto, retoma abaixo, PSI ilegível com o sinal ligado = ocupado) e passou neste checkout.

## Limites declarados

- A passada não é independente.
- O que muda de comportamento: com psi de CPU ≥ 30%, o pre-commit, o pr-finalize e o lab esperam mesmo com load abaixo de 15. A refutação nomeada no nó (mais de 1 em 10 esperas sem congestionamento no intervalo seguinte, numa semana de série) rebaixa a escolha.
