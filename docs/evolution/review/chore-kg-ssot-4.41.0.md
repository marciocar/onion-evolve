---
branch: chore/kg-ssot-4.41.0
pr: pendente
date: 2026-11-04
reviewed_diff_sha256: 60532b9851cc92fcbb94c7ff5a529c372cee9bd2ac667b2d81df20814a6f1b13
reviewed_code_sha256: 8d90e9942092b717157b00247a6c1f35591b622c62f78a297a8e70abf95228ab
findings_total: 1
findings_real: 0
tokens: 0
duration_min: 5
findings_fixed: 0
verdict: SEM_ACHADOS
elenxo: nao
reviewer: "sessão do core (passada inline)"
nota: "tokens 0 = não medido (passada inline, sem subagente)."
---

# Passada adversarial: `chore/kg-ssot-4.41.0`

## O que muda

- `vendor/kg-ssot` 4.40.2 → 4.41.0 pela tag `kg-ssot-v4.41.0` (`82bba71c9ceb`), trazida da fonte pública. Entra o
  `kg_query --group-by CAMPO` e o `group_by` na ferramenta MCP, com a saída nova `kg-ssot.groups/1`. O contrato
  (v4.18), os vereditos e o `kg-ssot.query/1` não mudam, e não há o que migrar.
- `.kg-ssot/gate/contract.json` renovado por `bash ops/kg-gate-ci.sh --update`: o `"kit"` passa a `4.41.0`, e a base
  registra três grafos que entraram na main sem registro: os spikes das portas, a pesquisa das portas e o estudo da
  orquestração de sessões.

## Achados

1. Hipótese: a contagem nova divergir do corpus do core. O kg-ssot conferiu os grupos contra uma contagem
   independente em f5d2a441 (162 decisões abertas em 51 grafos, 7131 nós). Aqui, o `kg_vendor.py check` dá o vendor
   íntegro, e o gate dá rc 0, com «novos=0». Sem achado.

## Mutantes

Nenhum: não há código do core.
