---
branch: chore/kg-ssot-4.12.0
pr: pendente
date: 2026-10-20
reviewed_diff_sha256: d7e64e03f3f4803fa3810d6d45ba53fba90013d0b679218ae363ee530877d93f
reviewed_code_sha256: fc3c95e348e1da6fea5d9959376940adcdb0085ffc984df931328ff0a3c4804c
findings_total: 1
findings_real: 0
tokens: 0
duration_min: 8
findings_fixed: 0
verdict: SEM_ACHADOS
elenxo: sim
reviewer: passada adversarial manual da sessão, com o gate pelo caminho do CI; sem subagentes
nota: ""
---

# Passada adversarial: `chore/kg-ssot-4.12.0`

## O que muda

O vendor `vendor/kg-ssot` vai da 4.11.0 para a 4.12.0 (444 arquivos, `check --index` verde). A base do gate é
regravada pelo `ops/kg-gate-ci.sh --update`, e o comentário de versão do workflow é atualizado.

## Achados

1. **Refutado:** "o MUST novo (tab no espaço inicial de continuação entre aspas) reprova algum grafo do core?"
   Não reprova. Pelo caminho do CI, o gate dá 178 grafos com os mesmos 16 na dívida herdada, e o único `✗` é a
   identidade do contrato, que a base regravada resolve.

## Mutantes

Nenhum: não há código do core. Famílias `kg_contract_check`, `mcp_onion_kg_writer` e `kg_ssot_require_hashes`:
84/0.

## Limites declarados

O `kg-migrate-v3.py` do core ainda não conhece `locality: privado`. O selo D_U1_MIGRADOR_NO_KG_SSOT o torna
core-only, e o corte é feito pelo PR da U1 em curso. O onion-kg-writer de produção segue na 4.9.1.
