---
branch: chore/kg-ssot-4-28-0
pr: pendente
date: 2026-10-25
reviewed_diff_sha256: pendente
findings_total: 0
findings_real: 0
tokens: 0
duration_min: 10
findings_fixed: 0
verdict: SEM_ACHADOS
elenxo: nao
reviewer: sessão principal (onion-evolve-bd), passada própria sobre o diff, depois da bancada pré-tag da ref
nota: "tokens 0 = não medido (passada na própria sessão, sem subagente)"
---

# Passada adversarial: `chore/kg-ssot-4-28-0`

## O que muda

- `vendor/kg-ssot/`: de `kg-ssot-v4.27.0` para `kg-ssot-v4.28.0` (d96d807220d0), com o `check` intacto.
- `docs/onion/graph/sinais-de-campo-2026-09.kg.yaml`: `E_KG_SSOT_428_ADOTADA_1025` e uma aresta.
- `docs/onion/kg-read-index.tsv`: regenerado.

## Mutantes

- Nenhum novo: a bancada pré-tag da ref 975ec28b2ef2 mediu antes e depois os quatro pontos pedidos e a leitura
  RDF. O gate não pediu --update, porque o contrato segue v4.15.
