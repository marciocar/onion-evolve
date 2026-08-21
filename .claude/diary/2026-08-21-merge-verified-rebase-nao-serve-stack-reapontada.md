---
date: 2026-08-21
instance: onion-evolve
type: error
classification: collective
tags: [pr-merge-verified, rebase, stack, gh-pr-merge, mecanismo-incompleto]
affects: [meta, engineering]
breadcrumb_for: []
share_with: []
next_recommended: ""
review_after: 2026-11-21
conflict_class: static
significance: "O pr-merge-verified.sh usa --rebase fixo. Numa stack empilhada cujo topo o GitHub RE-APONTOU para main após o merge da base, o rebase falha ('This branch can't be rebased') e o helper recusa — corretamente (não declara sucesso falso), mas o merge legítimo (checks 4/4 verdes, mergeable CLEAN) fica travado exigindo squash manual. A guarda não errou; ela é INCOMPLETA para a topologia de stack que a própria casa usa."
---

# O merge-verificado recusa o topo de uma stack re-apontada — e está certo, mas incompleto

**O que aconteceu.** Stack de 2 PRs (onion-exec #644 → onion-framework #645). Mergeei o #644;
o GitHub re-apontou o #645 para `main`. Com o #645 `MERGEABLE`/`CLEAN` e os 4 checks verdes,
`ops/pr-merge-verified.sh 645` recusou DUAS vezes: a 1ª por timing (mergeable ainda `UNKNOWN` —
a corrida que o helper existe para pegar), a 2ª pelo obstáculo real: `gh pr merge --rebase`
devolveu `This branch can't be rebased`. O merge saiu com `--squash --delete-branch`, provado
por estado (`mergedAt`).

**Por que a recusa está certa.** O helper checa o RC do `gh pr merge` (o defeito de origem do
#618) e não declara sucesso quando o comando falha. Fez exatamente o trabalho. O problema não é
a recusa — é que a **estratégia é fixa** (`DEL=(--delete-branch); ... --rebase`) e a topologia
de stack re-apontada não rebaseia limpo.

**A cura (JÁ APLICADA neste mesmo commit — fix-must-become-mechanism no mesmo loop).** O helper,
ao ver `can't be rebased`, re-tenta `--squash` automaticamente — os gates (checks completos, veredito lido, prova por estado)
permanecem idênticos; só a estratégia degrada. Hoje o operador faz esse fallback à mão, o que
é a receita para alguém um dia usar `--no-verify` por pressa. `fix-must-become-mechanism`.

**O eixo.** Mesma família de `bancada-espelha-o-runner` e da âncora head-pinned: o mecanismo
cobre o caso comum e falha no caso que a própria casa produz (aqui, a stack — que o helper JÁ
conhece, tem `--keep-branch` para ela). Cobrir a base da stack e não o topo re-apontado é a
lacuna.
