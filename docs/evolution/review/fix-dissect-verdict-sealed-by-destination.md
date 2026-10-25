---
branch: fix/dissect-verdict-sealed-by-destination
pr: pendente
date: 2026-10-25
reviewed_diff_sha256: 7cfe3f0084abb9cdebd02ea5838cc15564e9cfb3742fd13f0a342f15cebe1242
reviewed_code_sha256: d1e852b16f3e771c860e42a83b0562485042d25b635c3572989fd39861ca02d2
findings_total: 1
findings_real: 1
tokens: 0
duration_min: 15
findings_fixed: 1
verdict: CORRIGIDO
elenxo: nao
reviewer: sessão principal (onion-evolve-bd), passada própria sobre o diff
nota: "tokens 0 = não medido (passada na própria sessão, sem subagente)"
---

# Passada adversarial: `fix/dissect-verdict-sealed-by-destination`

## O que muda

- `.claude/validation/dissect-object-check.py`: o nó do veredito pode ter `status: done` desde que traga
  `x_dissect_sealed_by: <repo>:<caminho>#<ID>`, que aponta o selo do destino. Sem esse ponteiro, o fechamento segue
  `veredito-selado`. Ponteiro fora da forma, com qualquer status, é o código novo `selo-mal-formado`.
- `.claude/validation/dissect-object-bench.py`: entram 3 casos. Um é legítimo: fechado com selo válido, rc 0. Os
  outros dois reprovam: selo mal formado sai `selo-mal-formado`; selo válido com status refuted sai
  `veredito-selado`, porque só `done` fecha.
- `dissect-doctrine.md`: a regra fica escrita na lista de marcadores por família.

## Achados

1. REAL, corrigido: a 1ª versão só julgava a forma do ponteiro quando o status era `done`. Um ponteiro mal formado
   num veredito ainda `open` passava calado. Agora a forma é julgada sempre.

## Mutantes

- A bancada roda um mutante por código. Com `selo-mal-formado` calado, o caso dele deixa de acusar. Com
  `veredito-selado` calado, os dois casos dele deixam de acusar.
- Família `dissect_object`: 81 de 81 verdes (antes, 76 casos mais os mutantes).

## Limites declarados

- O ponteiro é opaco: o checador não abre o outro repo para conferir que o nó do selo existe. Quem prova é o
  destino, no grafo dele.
