---
branch: chore/kg-ssot-4.21.1
pr: pendente
date: 2026-10-23
reviewed_diff_sha256: pendente
findings_total: 0
findings_real: 0
tokens: 0
duration_min: 20
findings_fixed: 0
verdict: SEM_ACHADOS
elenxo: nao
reviewer: "fork da sessão principal (claude-opus-5-5), passada própria"
nota: "tokens não medidos; adoção de vendor mais 3 casos de bancada"
---

# Passada adversarial: `chore/kg-ssot-4.21.1`

## O que muda

- `vendor/kg-ssot` 4.21.0 → 4.21.1 (`b1220ca490ee`), `kg_vendor.py check` rc 0; `.kg-ssot/gate/contract.json` só
  regrava `kit` (o sha do contrato é o mesmo).
- Família `kg_criterion_ci` ganha (f) sha256 numérico sem aspas, (g) `x_criterion` que não é mapa e (h) `ref` e
  `text` juntos: os três reprovam com rc 1 e `integrity.criterion-malformed`.

## Achados

Nenhum. Gate antes e depois igual: 184 grafos, 182 no MUST, 2 de dívida herdada, SHOULD idêntico;
`kg_criterion` com 0 critérios e 0 achados no core.

## Mutantes

- O vendor anterior é o mutante: com `vendor/kg-ssot` da 4.21.0, os casos (f), (g) e (h) caem (rc 0, `criterios=0`),
  que é o fail-open que a 4.21.1 cura. Com a 4.21.1, 8 de 8 passam.
- Famílias vizinhas: `mcp_onion_kg_writer`, `mcp_onion_kg`, `door` e `kg_fixture_paths` com 107 passam e 0 falham.

## Limites declarados

- A bancada completa fica com o CI.
