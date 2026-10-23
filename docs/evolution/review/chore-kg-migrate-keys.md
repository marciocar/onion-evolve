---
branch: chore/kg-migrate-keys
pr: pendente
date: 2026-10-23
reviewed_diff_sha256: 76799ba61a6d35f0753f598b440d28c034acb3a916c1bd4b0f7b59330c4fbac0
reviewed_code_sha256: 01e43fa2d311781e6c9ec8b9b898003819c5a4f0d9d592853d646206582c6936
findings_total: 0
findings_real: 0
tokens: 0
duration_min: 40
findings_fixed: 0
verdict: SEM_ACHADOS
elenxo: nao
reviewer: "fork kg-migrate-keys (claude-opus-5-5), passada própria"
nota: "tokens não medidos; renomeação mecânica pelo kg_migrate.py keys da kg-ssot 4.19.1"
---

# Passada adversarial: `chore/kg-migrate-keys`

## O que muda

- `kg_migrate.py keys --apply` (com os mesmos `--exclude` do `ops/kg-gate-ci.sh`) renomeia para `x_<chave>` 76
  chaves que o contrato não conhece, em 12 grafos: `edge.provenance` (61, em pr-decision-history), `meta.label`,
  `meta.trace`, `node.resolution`, `meta.run_id`, `top.version`, `top.kind` (2 de cada), `meta.revisited`,
  `node.status_note`, `meta.source_run` (1 de cada). Resposta do maestro a `Q_KG_MIGRATE_KEYS_NO_CORPUS_1022`.
- `.kg-ssot/gate/` regravada com `--update`.

## Achados

Nenhum. Antes de aplicar, procurei leitor de cada nome antigo no código do core (`git grep` em `.sh`, `.py`, `.js`,
`.mjs`, `.yml`, fora da bancada): os três grafos citados pelo lint aparecem só em comentários; `run_id` só é lido do
JSON do censo (`census-seal.py`), nunca do `meta` de grafo; `kind` de topo não tem leitor (o `kind` lido pelo
decide-census e pelos hooks é campo de linha, não do grafo).

## Mutantes

- O próprio gate é a medida: antes 170/184 cumprem o MUST (14 na dívida herdada), depois 182/184 (2). As linhas
  SHOULD não mudam (label 2161, verified_against 141, verified_at 15, untraced-decision 35, unquoted-date 58).
- O índice de leitura (`kg-trace-resolve.sh --emit-index`) sai idêntico ao versionado: o `meta.trace` renomeado não
  alimentava o índice.

## Limites declarados

- Os 2 grafos que seguem na dívida reprovam por falta de `provenance` em nó, que nenhuma renomeação resolve.
- Bancada: 42 famílias do kg, 542 passaram, 0 falharam (LC_ALL=C); lint completo 0 HARD.
