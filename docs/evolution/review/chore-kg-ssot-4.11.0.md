---
branch: chore/kg-ssot-4.11.0
pr: pendente
date: 2026-10-20
reviewed_diff_sha256: 83f91e82b9c8a69ea256eba19e1558fe2d64c6edc82ac5810de060f09ead12a9
reviewed_code_sha256: 3212031df6c8e6291f13225dad49ba196df4e99ededbd703664107283d579d72
findings_total: 2
findings_real: 1
tokens: 0
duration_min: 20
findings_fixed: 1
verdict: CORRIGIDO
elenxo: sim
reviewer: passada adversarial manual da sessão, com o gate pelo caminho do CI nas duas versões; sem subagentes
nota: ""
---

# Passada adversarial: `chore/kg-ssot-4.11.0`

## O que muda

O vendor `vendor/kg-ssot` sai da 4.10.0 e vai para a 4.11.0, com 425 arquivos e `check --index` verde. A base do
gate (`.kg-ssot/gate.json`) é regravada pelo `ops/kg-gate-ci.sh --update` e o comentário de versão do workflow
é atualizado.

## Achados

1. **REAL (de método, curado antes do commit):** a 1ª medição usou o `kg_gate.py` direto, sem os excludes do
   `ops/kg-gate-ci.sh`, e acusou "PIOROU": 179 grafos, contra os 177 do CI, porque entravam 2 propostas antigas
   do `kg-inbox`. Rodada a 4.10.0 sobre a mesma `main` pelo instrumento errado, a reprovação era igual, então não
   vinha da versão. Pelo caminho do CI, a `main` (4.10.0) deu rc 0 e a 4.11.0 só mostrou a mudança de
   identidade do contrato. O instrumento certo é o do CI.
2. **Refutado:** "a contagem da base subir de 175 para 177 esconde algo?" Não esconde. A base estava 2 grafos
   atrás do disco, e o gate regravado conta os 177 que o CI mede, com a mesma dívida herdada (16).

## Mutantes

Nenhum: não há código do core. Famílias `kg_contract_check`, `mcp_onion_kg_writer` e `kg_ssot_require_hashes`:
84/0.

## Limites declarados

O onion-kg-writer de produção segue na 4.9.1. Subi-lo é decisão separada do maestro.
