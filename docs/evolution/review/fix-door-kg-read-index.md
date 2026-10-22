---
branch: fix/door-kg-read-index
pr: pendente
date: 2026-10-22
reviewed_diff_sha256: 0aa45af438432577756437091ad97466115b5a971b676405b8ffe2e6caa9b2f8
reviewed_code_sha256: 7069e6144a546c8b8e9774f4678ac5728a191ddb291857a1161e5391cebf21f7
findings_total: 1
findings_real: 1
tokens: 0
duration_min: 25
findings_fixed: 1
verdict: CORRIGIDO
elenxo: nao
reviewer: "sessão principal (claude-opus-5-5), passada própria"
nota: "tokens não medidos (passada na própria sessão)"
---

# Passada adversarial: `fix/door-kg-read-index`

## O que muda

- `.claude/validation/kg-fixture-paths.sh`: `vendor/kg-ssot/` entra na classe que não é corpus, com casos no
  `--selftest` (isenta o grafo de exemplo do vendor; não isenta `docs/vendor-kg-ssot-notes/`).

## Achados

1. A `main` reprova a família `door` desde a adoção da kg-ssot 4.19.0 (`2926ee24`; último verde `9f5a79bd`).
   Medido: o vendor trouxe `spec/vocab-examples/cmed-dictionary.kg.yaml` fora de `fixtures/`; numa porta sem grafo
   próprio com trace ele vira o corpus inteiro, o `kg-trace-resolve.sh --emit-index` sai rc 3 com índice vazio, e o
   `materialize-door.sh` aborta ("a porta ficaria SEM projeção SSOT: docs/onion/kg-read-index.tsv"). Curado no
   predicado único (a mesma regra que a kg-ssot 4.19.1 aplicou no gate dela).

## Mutantes

- O próprio `origin/main` é o mutante: sem a linha nova, `materialize-door.sh <dir> --role hub --from origin/main`
  sai rc 3; com ela, `--from HEAD` sai rc 0 e gera o índice.
- `kg-fixture-paths.sh --selftest`: OK, com o caso positivo e o negativo novos.

## Limites declarados

- A família `door` da bancada materializa de `origin/main` por desenho (nunca do HEAD local), então ela só fica
  verde depois do merge desta cura. O lint completo deu 0 HARD na árvore com a cura.
