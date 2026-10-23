---
branch: chore/kg-ssot-4.23.0
pr: pendente
date: 2026-10-23
reviewed_diff_sha256: fc0f3b16ba61671437b90f55871a15d946d08ad575143f6cad42c049d66c1ec9
reviewed_code_sha256: 3d1b3e7dd7793e1458b683eade7d77adccbb605b6b81d14ca3622cdea8620bcd
findings_total: 0
findings_real: 0
tokens: 0
duration_min: 30
findings_fixed: 0
verdict: SEM_ACHADOS
elenxo: nao
reviewer: "subagente da sessão principal (claude-opus-5-5), passada própria"
nota: "tokens não medidos; adoção de vendor sem mudança de código do core"
---

# Passada adversarial: `chore/kg-ssot-4.23.0`

## O que muda

- `vendor/kg-ssot` 4.22.0 → 4.23.0 (`39f4dde463ae`, 625 arquivos), `kg_vendor.py check` rc 0. Entram o contrato
  v4.14 (`x_term.scheme`, `integrity.term-notation-duplicate`), o `kg_vocab.py lint` com `--baseline`/`--external`,
  o `lookup` por notation e o `--text` expandido do `kg_query`.
- `.kg-ssot/gate/contract.json` ganha a identidade nova do contrato (`f4e01f24c03c…`) pelo `kg-gate-ci.sh --update`.
- O mesmo `--update` gravou `.kg-ssot/gate/graphs/radar-E3-2026-10-23-r17.json`: o grafo chegou à main sem a linha
  de base (185 grafos, 184 bases). Ela nasce vazia (`must: []`, `should: {}`), como o grafo mede hoje.

## Achados

Nenhum. Gate antes e depois igual: 185 grafos, 183 no MUST, 2 de dívida herdada, os SHOULD idênticos linha a linha
(diff vazio, fora a linha da identidade). `kg-criterion-ci.sh` rc 0 com 3 critérios e 0 achados. O core não tem nó
`x_term` (a única menção fora do vendor é prosa em `sinais-de-campo-2026-09.kg.yaml`), então as regras novas do
contrato não alertam em nenhum grafo.

## Medição do `kg_vocab lint` (só registro, nada ligado)

`kg_vocab.py lint --root . --format json`: rc 1, 3,2 s, 2194 códigos em prosa, 0 resolvidos, 0 externos, 2194
achados, todos `vocab.code-unresolved`, 301 tokens distintos em 146 grafos. Base e termos ficam para o passo seguinte.

## Mutantes

- `--baseline` numa base em `/tmp` gravada com `--update`: a releitura dá rc 0 (só reprova o que é novo).
- `--external 'nseries=^N[0-9]+$'`: 61 códigos passam a resolver como externos e os achados caem de 2194 para 2133.
  Esquema fora do formato slug (`N=...`) dá `BROKEN INPUT`, sem medir em silêncio.
- Antes do `--update`, o gate já dava rc 0 com o aviso de identidade: a comparação decide o veredito.

## Limites declarados

- Bancada só nas famílias do kg, do door e do decide (166 passaram, 0 falharam); a completa fica com o CI.
- O harness do kg-writer não precisou de cura: os arquivos novos do vendor não entram no corpus.
- Lint: 0 HARD, 21 SOFT pré-existentes (frescor doutrinário).
