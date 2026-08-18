---
date: 2026-07-16
instance: onion-evolve
type: learning
classification: public
tags: [rescue, avell, coexistence, in-repo-knowledge, prediction, dogfood, git]
affects: [identity, infra, method]
breadcrumb_for: [catch-up, meta:kg, meta:co-evolve]
share_with: [collective]
next_recommended: ""
review_after: 2026-10-14
conflict_class: static
---

## Signal
**O framework sobreviveu à morte da própria máquina — e o que resgatamos tinha previsto esta sessão.**
O notebook Avell A70 queimou o jack de energia **com trabalho não-commitado do core**; foi por isso que a
VPS foi alugada e a instância passou a morar lá. Meses depois, ao **resgatar a cápsula pré-VPS**, o item de
maior valor foi um doc de pesquisa **commitado mas nunca pushado** (`Modo Equipe + Federação de Conhecimento`,
01/jul) cujo próprio `next-review-trigger` era *"1º caso real de N-devs/1-repo no Onion"* — que é **exatamente**
a coexistência Avell+VPS que estávamos desenhando no dia do resgate. A pesquisa previu o futuro que a
resgatou.

## Evidence
- **Resgate sem perda:** capturar **antes** de sincronizar (branch `rescue/avell-uncommitted-2026-07`, a
  partir do HEAD antigo do Avell) — `git pull` primeiro teria clobado o não-commitado (`origin/main` andou
  ~306 commits). Doc de ouro reaplicado no main via PR #394; landing-drafts + scratch preservados na branch.
- **A profecia:** o doc de 01/jul concluiu que "N humanos + IA num repo" não tem vendor que resolva como
  categoria; worktrees = padrão de fato; e nomeou o gatilho de re-teste = o 1º caso real. Duas semanas depois,
  o caso real **apareceu** (as duas casas) e o próprio doc voltou pra ser a base da decisão.

## Learning
**Conhecimento durável não morre com hardware — se estiver no repo.** O que estava *commitado* (mesmo não
pushado) e o que virou *reaplicável* sobreviveu; o que era só working-tree só sobreviveu porque foi
**capturado antes de sincronizar**. É a mesma tese da coexistência: o **repo é o cérebro compartilhado**; o
git é o elo entre as casas. E o SDAAL/KG fecha o círculo — o artefato que registra o método é também o que
o método usa pra decidir (a pesquisa que se auto-resgatou).

## How to apply
- Máquina nova / disco em risco: **capture antes de `pull`** (branch a partir do HEAD antigo → commit →
  push). Nunca sincronize por cima de working-tree não-commitado.
- Trate `next-review-trigger`/migalhas como profecias testáveis: quando o gatilho aparece no mundo, o
  artefato volta pro loop (é o [[deterministic-freshness-via-in-file-baseline]] aplicado a docs de pesquisa).
- Ver `[[2026-07-16-two-homes-origin-and-coexistence]]` (a decisão de coexistência) e o KG
  `[[coexistence-two-homes-2026-07]]`.
