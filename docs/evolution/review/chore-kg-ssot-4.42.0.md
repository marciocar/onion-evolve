---
branch: chore/kg-ssot-4.42.0
pr: pendente
date: 2026-11-04
reviewed_diff_sha256: 44c8698cb4302c322de0b3aa96a59dd0f7af01db39f8982ee7514db28af3c651
reviewed_code_sha256: cc6edd51ed31245136939f30108bdcb7253796cc71bf454b56333cc0a84a6bb5
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

# Passada adversarial: `chore/kg-ssot-4.42.0`

## O que muda

- `vendor/kg-ssot` 4.41.0 → 4.42.0 pela tag `kg-ssot-v4.42.0` (`a21b2c9bfa6f`), da fonte pública. Entra o
  `kg_query --edges` (arestas internas e externas, com `--where` e `--group-by`), o `--count-distinct` e o
  `--min-count`, o `provenance.<chave>` no filtro e no agrupamento, e os mesmos parâmetros no MCP. A saída
  agrupada passa de `kg-ssot.groups/1` a `/2`. O contrato (v4.18), os vereditos e o `kg-ssot.query/1` não mudam.
- `.kg-ssot/gate/contract.json` renovado por `bash ops/kg-gate-ci.sh --update`.

## Achados

1. Hipótese: algo no core ler o `kg-ssot.groups/1` e quebrar com o `/2`. Conferido por `git grep`: nada no core
   fora do vendor lê esse schema (só o resíduo da 4.41.0 o cita como texto). O `kg_vendor.py check` dá o vendor
   íntegro, e o gate dá rc 0.

## Mutantes

Nenhum: não há código do core.
