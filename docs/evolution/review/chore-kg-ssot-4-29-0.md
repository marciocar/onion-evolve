---
branch: chore/kg-ssot-4-29-0
pr: pendente
date: 2026-10-26
reviewed_diff_sha256: e0963db263c40f517a9bd9b5242d516de8f3036d852f9dcc9a033547f26a218b
reviewed_code_sha256: 4198c96906f6cd4c3e2599d8db3c75fe465fab85786e965ed7951bbe6c0c189e
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

# Passada adversarial: `chore/kg-ssot-4-29-0`

## O que muda

- `vendor/kg-ssot/`: de `kg-ssot-v4.28.0` para `kg-ssot-v4.29.0` (4c699e275995), com o `check` intacto.
- `docs/onion/graph/sinais-de-campo-2026-09.kg.yaml`: `E_KG_SSOT_429_ADOTADA_1026` e uma aresta para o
  `D_EXTRA_RDF_DO_KG_SSOT_EM_SERIE_1025`.
- `docs/onion/kg-read-index.tsv`: regenerado.

## Mutantes

- Nenhum novo. A bancada pré-tag da ref e39d26408f47 mediu os quatro pontos, e o reconstrutor do --full tem
  mutante: um label trocado deixa de casar.
