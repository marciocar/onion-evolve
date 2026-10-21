---
branch: chore/kg-ssot-4.13.1
pr: pendente
date: 2026-10-21
reviewed_diff_sha256: 984f799c3fd220afd59f4a838f13b12cceb56162d03e786af4b152077cf6178f
reviewed_code_sha256: b8d5a011e99576a5f19b7ecedd2773b53e00a8f41cb440eac440e5808aeb75fa
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

# Passada adversarial: `chore/kg-ssot-4.13.1`

## O que muda

O vendor `vendor/kg-ssot` vai da 4.13.0 para a 4.13.1 (467 arquivos, `check --index` verde). A base do gate é
regravada pelo `ops/kg-gate-ci.sh --update`, e o `contract_sha256` vai de `bd3c534c…` para `62909ed9…`. O
comentário de versão do workflow também é atualizado.

## Achados

1. **Refutado:** "a identidade nova esconde veredito trocado?" Não esconde. Pelo caminho do CI, o gate dá 178
   grafos com os mesmos 16 na dívida herdada antes e depois de regravar a base. É a correção que o core pediu:
   na 4.13.0 a identidade não mudava porque as regras do v4.6 moravam só no leitor.

## Mutantes

Nenhum: não há código do core. Famílias `kg_contract_check`, `mcp_onion_kg_writer`, `kg_ssot_require_hashes` e
`remeasure_contract`: 105/0.
