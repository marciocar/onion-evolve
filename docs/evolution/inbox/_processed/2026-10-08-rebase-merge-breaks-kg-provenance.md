---
title: 'Merge por rebase (padrão do pr-merge-verified) quebra provenance caminho@commit do contrato v3'
date: 2026-10-08
from: onion-curation (consumidor)
to: core (onion-evolve)
type: signal
flow: upstream (consumidor→core)
---

# O rebase reescreve o SHA que o `.kg.yaml` cita como fonte

## O que aconteceu (medido)

- O PR #3 do onion-curation criou um registro de decisão (`e1a087e`) e, num commit seguinte da mesma
  branch, o `.kg.yaml` passou a citá-lo como `provenance.source: "<caminho>@e1a087e"`, como a gramática v3
  pede (`kg-grammar.md`: source = caminho@commit).
- O merge foi feito por `ops/pr-merge-verified.sh 3 --repo ... --sync`, sem `--merge-commit`, então no
  modo padrão, que é rebase. Os 3 commits foram reescritos (`e1a087e`→`8c32dd2`, `cea76a7`→`9119817`,
  `6908840`→`78bae38`), com conteúdo idêntico (`git diff` vazio).
- Resultado: 6 `provenance` na `main` apontavam para commits **fora da main**
  (`git merge-base --is-ancestor <sha> origin/main` ≠ 0). **Nenhum gate acusou**: o radar saiu com exit 0,
  o lint com 0 HARD, o CI verde. Achei relendo o próprio merge.

## Por que importa ao core

O contrato v3 pede `caminho@commit`, e o caminho de merge canônico usa rebase por padrão. As duas
coisas juntas produzem fonte quebrada **silenciosamente**, sempre que um grafo cita um commit da própria
branch. É o mesmo defeito, um nível acima, do `onion/vendor` sair da ancestralidade: o rebase reescreve
o que outra coisa referencia por hash.

## Correção local (já feita)

As referências foram trocadas para os SHAs da `main`, e o CLAUDE.md daqui passou a exigir `--merge-commit`
em PR cujo `.kg.yaml` cita commit da própria branch.

## Pedido (decisão do core)

Uma destas, ou as duas:
1. **Guarda:** checar que todo `@<sha>` em `provenance.source` é ancestral da base. Pode ser no
   `kg-radar --provenance` ou num lint de PR, rodado depois do merge, ou antes, simulando o merge.
2. **Script:** o `pr-merge-verified.sh` detecta, no diff do PR, `provenance` citando commit da própria
   branch e exige `--merge-commit` (ou recusa o rebase), como já faz o `--assert-ancestor` para o vendor.
