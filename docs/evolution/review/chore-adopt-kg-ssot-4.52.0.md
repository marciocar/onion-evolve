---
branch: chore/adopt-kg-ssot-4.52.0
pr: pendente
date: 2026-11-15
reviewed_diff_sha256: aecbb98c12b3100f9d437d8a77298a869ab7339f1659544660c0b3427979076e
findings_total: 0
findings_real: 0
findings_blocking: 0
tokens: 0
duration_min: 0
findings_fixed: 0
verdict: NO_FINDINGS
elenxo: false
reviewer: "bancada da v4.23 do kg-ssot antes da tag (D_CO_EVOLUTION_BOUNDARIES_1023): kg_vendor.py check + KG_GATE_ALLOW_UNRELEASED=1 ops/kg-gate-ci.sh = RC 0; e após a tag, kg_vendor.py check + ops/kg-gate-ci.sh (released) = RC 0. Medido: changed graphs 0, novos 0, nenhum código novo sem termo, catraca MUST/SHOULD igual à base, 835 grafos do core idênticos byte a byte."
nota: "Adoção de vendor (bump v4.51.0→v4.52.0, 810 arquivos). Sem código do core alterado; contrato v4.23 é SHOULD only (perfis x_dispose_* no meta, listas dispose no --due, flags opt-in no kg_gate, kg_policy.py extraído). Bancada provada duas vezes (pré-tag e released)."
---

# Adoção da kg-ssot 4.52.0 (contrato v4.23)

## O que muda

`vendor/kg-ssot` v4.51.0 → v4.52.0 (commit e003566e). Contrato v4.23 (só SHOULD): `x_dispose_by`/`x_dispose_basis`/`x_hold` no meta; `kg_validate --due` ganha as listas dispose/dispose_held/dispose_malformed/dispose_conflict; `kg_gate` ganha `--classification-floor`/`--area-policy` (opt-in); o leitor da política do kg-mcp extraído para `tools/kg_policy.py`.

## Achados

Nenhum. Vendor bump benchado pela bancada do core antes da tag (gate RC=0, catraca não piorou) e re-conferido released (RC=0). Nenhum grafo do core tocado; 835 saem idênticos.

## Limites declarados

- As flags novas do `kg_gate` (`--classification-floor`/`--area-policy`) ficam OFF (opt-in); não mudam nada até ligadas.
