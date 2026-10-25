---
branch: fix/dissect-trigger-after-seal
pr: pendente
date: 2026-10-25
reviewed_diff_sha256: pendente
findings_total: 1
findings_real: 1
tokens: 0
duration_min: 20
findings_fixed: 1
verdict: CORRIGIDO
elenxo: nao
reviewer: sessão principal (onion-evolve-bd), passada própria sobre o diff; o achado de origem é da curadoria
nota: "tokens 0 = não medido (passada na própria sessão, sem subagente)"
---

# Passada adversarial: `fix/dissect-trigger-after-seal`

## O que muda

- `.claude/validation/dissect-object-check.py`: o item 7 recebe `fired`. Com o veredito `done` e um
  `x_dissect_sealed_by` válido, o gatilho disparado vira a linha `aviso item 7 gatilho-disparou-depois-do-selo`, que
  não muda o rc. Sem selo, ou com selo mal formado, segue `gatilho-ja-disparou`.
- `.claude/validation/dissect-object-bench.py`: dois casos novos e o tipo de caso `aviso:`, que exige rc 0 com a linha
  e um mutante que cala o `fired` e a faz sumir.
- `.claude/commands/common/prompts/dissect-doctrine.md`: a regra, junto da do selo.

## Achados

1. REAL, corrigido (achado da curadoria): o parque selado reprovava quando o próprio gatilho disparava, o que
   obrigava a deixar fora do grafo a aresta de superação.

## Suspeitas descartadas

1. Um selo forjado calar o gatilho: descartada. O selo mal formado mantém o HARD (caso "gatilho disparado num parque
   já selado"), e o aviso continua visível na saída; o selo é ponteiro opaco por desenho (o checador não lê outro repo).

## Mutantes

- O checador da `origin/main` reprova o caso do aviso (rc 1). O mutante que cala o `fired` faz a linha sumir.
- `dissect-object-bench.py`: 77 casos e 4 de rc 3 verdes; famílias `dissect_object` e `dissect`: 144 de 144.
