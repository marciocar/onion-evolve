---
branch: chore/kg-ssot-4.19.1
pr: pendente
date: 2026-10-22
reviewed_diff_sha256: f32e0f7bb06c3fad84d3aa0354173dce886ab48d1dc7881a7c45be2d7932f251
reviewed_code_sha256: 5971c36bcfbef968ff73007a5f9683b3a782b4fc9edd05604034b8d014410c6c
findings_total: 0
findings_real: 0
tokens: 0
duration_min: 8
findings_fixed: 0
verdict: SEM_ACHADOS
elenxo: nao
reviewer: "sessão principal (claude-opus-5-5), passada própria"
nota: "tokens não medidos (passada na própria sessão); só vendor e carimbo da base"
---

# Passada adversarial: `chore/kg-ssot-4.19.1`

## O que muda

- `vendor/kg-ssot` sobe de 4.19.0 para 4.19.1 (`0f093aef603c`) pelo `kg_vendor.py update`; `kg_vendor.py check` rc 0.
- `.kg-ssot/gate/contract.json` regravado pelo `ops/kg-gate-ci.sh --update`; nenhum registro de grafo mudou.

## Achados

Nenhum. O aviso da sessão par era que o gate da 4.19.0 contava o grafo de exemplo do vendor
(`spec/vocab-examples/cmed-dictionary.kg.yaml`) em alguns adotantes. No core ele nunca entrou: a base tem 184
grafos antes e depois, `git grep cmed-dictionary` em `.kg-ssot/` dá rc 1, e o `--update` não mexeu em nenhum
`.kg-ssot/gate/graphs/*.json`.

## Mutantes

- Não se aplica: atualização de vendor; o gate (`ops/kg-gate-ci.sh`) saiu rc 0 antes do `--update`.

## Limites declarados

- A bancada completa fica com o CI; o pré-voo do pr-finalize roda as famílias do contrato.
