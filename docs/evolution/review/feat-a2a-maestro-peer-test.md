---
branch: feat/a2a-maestro-peer-test
pr: pendente
date: 2026-10-21
reviewed_diff_sha256: pendente
findings_total: 0
findings_real: 0
tokens: 0
duration_min: 10
findings_fixed: 0
verdict: SEM_ACHADOS
elenxo: nao
reviewer: sessão principal
nota: "tokens 0 = não medido; pino de chave pública conferido pela impressão e bancadas do A2A"
---

# Passada adversarial: `feat/a2a-maestro-peer-test`

## O que muda

- O membro de teste `maestro-peer-test` entra no `members.yaml`, com a pública pinada em
  `jwks/maestro-peer-test-1.pem`.
- O A0 vira evidência PROD no grafo do spike.

## Achados

Nenhum. Conferi:
- **Impressão:** a sha256 do DER da pública colada é igual à que o `a2a-keygen.sh` imprimiu no notebook
  (`346a2bfc…35de`). A chave é RSA 3072, acima do piso de 2048 do registro.
- **Formato do kid:** `maestro-peer-test-1` está na forma fechada `<membro>-<N>`.
- **Validação:** o `members-validate.sh` acusa 30 membros e rc 0, e o doctor do receptor dá 5 ok e 0 falha.
- **Bancadas:** `a2a_verify` e `federation_a2a` passam 213/213 sob `LC_ALL=C`.

## Mutantes

Não se aplica: o diff tem dado de registro e nenhum motor muda.

## Limites declarados

- A confiança vale no clone servido só depois do `ops/update-bridge.sh` do maestro.
- O membro é de teste e deve ser revogado ao fim do degrau A.
