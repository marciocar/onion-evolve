---
branch: docs/diarization-installed
pr: pendente
date: 2026-10-20
reviewed_diff_sha256: 334742041322340da442bf0f95da4e7959921b9de7f5d4482bc7b9c87b8cddb4
reviewed_code_sha256: 854909052df68de6ade0282fdf862673b6cb79015fe973e3d0e2b3f691d0fd7b
findings_total: 1
findings_real: 1
tokens: 0
duration_min: 8
findings_fixed: 1
verdict: CORRIGIDO
elenxo: sim
reviewer: passada adversarial manual da sessão, com o gate pelo caminho do CI; sem subagentes
nota: ""
---

# Passada adversarial: `docs/diarization-installed`

## O que muda

O nó `E_MC_STT_INSTALADO_LOOPBACK_1020` é re-medido depois do #1230: novo label, `verified_against` e
`locator` com a invocação c41f0675 e as 14 propriedades do verify, com o label anterior verbatim na narrative.
Entra uma aresta SUPPORTS para `D_MC_DIARIZACAO_NO_SERVICO_PROXIMO_1019`. O TETO não muda, porque é o mesmo fato
(a instalação em produção) re-medido.

## Achados

1. **REAL (curado):** o 1º label tinha mais de 280 caracteres. O gate pelo caminho do CI acusou
   `debt.form.range.node.label: 2161 → 2162`. Encurtado para 227, e o gate voltou a não piorar.

## Mutantes

Nenhum: não há código. O radar `--integrity --schema` sai 0 e o `ops/kg-gate-ci.sh` sem PIOROU.

## Limites declarados

A memória do pior caso (3 h) segue como cota calculada, não pico medido, e isso está dito no nó de medição da
diarização.
