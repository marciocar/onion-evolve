---
branch: docs/stt-installed-measured
pr: pendente
date: 2026-10-20
reviewed_diff_sha256: 3ab072f2da395bf6bfe7f81305cf98baa19d903f4f07d4733946054d4b539a93
reviewed_code_sha256: 226332e9067f05f9adacdbdf7345b1a23ec1dcb47b52822b3986ecbfb57c8bcf
findings_total: 1
findings_real: 0
tokens: 0
duration_min: 10
findings_fixed: 0
verdict: SEM_ACHADOS
elenxo: sim
reviewer: passada adversarial manual da sessão, com o verify re-rodado antes de escrever; sem subagentes
nota: ""
---

# Passada adversarial: `docs/stt-installed-measured`

## O que muda

Entra o nó `E_MC_STT_INSTALADO_LOOPBACK_1020` (evidence, PROD, confirmed), com SUPPORTS para
`D_MC_STT_SOBE_EM_LOOPBACK_1019`. O label de `E_MC_STT_SERVICO_CORE_MEDIDO_1017` troca "ainda não" pelo ponteiro
para o nó novo, e o TETO vai de 13 para 14, com o gatilho declarado.

## Achados

1. **Refutado:** "o nó PROD copia a medição de ontem?" Não copia. Re-rodei o `ops/stt-service.sh verify` antes
   de escrever, e o `verified_at` e o `locator` vêm dessa leitura de hoje (verify OK, 13 propriedades, MainPID
   3533022).

## Mutantes

Nenhum: não há código. O radar `--integrity --schema` saiu 0, o teto ficou em 14/14 e o `ops/kg-gate-ci.sh` em rc 0.

## Limites declarados

A saída pelo Caddy (TLS, token, subdomínio) fica fora, como manda o selo, até o cliente de captura existir.
