---
branch: chore/kg-ssot-4-27-0
pr: pendente
date: 2026-10-25
reviewed_diff_sha256: a78858e56f928be1d6669d15f969df24c9ed85f399f24490355e8baf0fe1ae9a
reviewed_code_sha256: 2c1b0ea417f2dc31540130941a17ea97bc3c08593e3a836a2a8a178b36ebd615
findings_total: 1
findings_real: 0
tokens: 0
duration_min: 15
findings_fixed: 0
verdict: SEM_ACHADOS
elenxo: nao
reviewer: sessão principal (onion-evolve-bd), passada própria sobre o diff, depois da bancada pré-tag da ref
nota: "tokens 0 = não medido (passada na própria sessão, sem subagente)"
---

# Passada adversarial: `chore/kg-ssot-4-27-0`

## O que muda

- `vendor/kg-ssot/`: de `kg-ssot-v4.26.0` para `kg-ssot-v4.27.0` (300d5aa7510a, 638 arquivos), pelo
  `kg_vendor.py update --tag`, com o `check` intacto.
- `.kg-ssot/gate/contract.json`: a identidade do contrato v4.15 e o kit 4.27.0, regravados por
  `ops/kg-gate-ci.sh --update`, como na subida da v4.13 (4.22.0).
- `.kg-ssot/gate/graphs/radar-E3-2026-10-24-r18.json`: base nova que o `--update` gravou para um grafo já
  rastreado na main e ainda sem base.
- `docs/onion/graph/sinais-de-campo-2026-09.kg.yaml`: o nó `E_KG_SSOT_427_ADOTADA_1025` e uma aresta.
- `docs/onion/kg-read-index.tsv`: regenerado.

## Suspeitas descartadas

1. A base do r18 entrar por arrasto: verificada, não é defeito. O grafo está rastreado na main, e o `--update`
   grava base para todo grafo do corpus; deixá-lo sem base manteria um aviso permanente.

## Mutantes

- Nenhum novo: a bancada pré-tag da ref 5bf74b2c905e já mediu antes e depois os 5 pontos pedidos (relatório
  ao onion-kg-ssot), e o código da tag é o da ref mais a base da catraca e um teto de CI do produto.
