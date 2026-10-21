---
branch: chore/kg-ssot-4.13.0
pr: pendente
date: 2026-10-21
reviewed_diff_sha256: 8bbce2590b0a4d1c1d4c74a16692223badb524727df70ca61a87ac65de5816ef
reviewed_code_sha256: 3ba721762e595ffa2956fe349cb50afef15b4631b9cb4d71da1951b241873e8b
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

# Passada adversarial: `chore/kg-ssot-4.13.0`

## O que muda

O vendor `vendor/kg-ssot` vai da 4.12.0 para a 4.13.0 (467 arquivos, `check --index` verde), e o comentário de
versão do workflow é atualizado. Chegam `tools/kg_migrate.py` e `tools/test_kg_migrate.py`, o migrador oficial
que a fase 2 da U1 (`Q_U1_FASE2_MIGRACAO_CONDUZIDA`) estava esperando.

## Achados

1. **Refutado:** "a base do gate precisava ser regravada, como nas 4.11.0 e 4.12.0?" Não precisava. O
   `ops/kg-gate-ci.sh` sai rc 0 com 178 grafos e os mesmos 16 na dívida herdada, sem acusar identidade: a parte
   do contrato que o gate compara não mudou nesta release.

## Mutantes

Nenhum: não há código do core. Famílias `kg_contract_check`, `mcp_onion_kg_writer`, `kg_ssot_require_hashes` e
`remeasure_contract`: 105/0.

## Limites declarados

A fase 2 da U1 (o `--update` chamar o `kg_migrate.py` em dry-run) é trabalho seguinte, derivado contra esta
ferramenta.
