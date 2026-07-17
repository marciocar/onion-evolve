---
date: 2026-07-17
instance: onion-evolve
type: learning
classification: public
tags: [git-discipline, pr-workflow, two-homes, coexistence, co-evolve, concurrency]
affects: [meta, engineering]
breadcrumb_for: [catch-up, meta:co-evolve, onion-working-method]
share_with: [collective]
next_recommended: ""
review_after: 2026-10-15
conflict_class: static
---

## Signal
"Caminho pra `main` é SEMPRE por PR" não tem exceção pra commit administrativo/housekeeping do
próprio core — nem pra mover 2 arquivos pra `_processed/`. Obedecer essa regra sem exceção é o que
tornou uma colisão-sem-colisão real (two-homes sob pressão) **observável e segura**, em vez de
escondida atrás de um fast-forward local.

## Evidence
- PR #400 (triagem do sinal `metagamify-kg-first` + entrega via `co-deliver`): commitei direto em
  `main` local por inércia da sessão. O maestro corrigiu — sem exceção, mesmo pra housekeeping.
- Rebobinado: `git branch` a partir do commit → `git reset --hard origin/main` → push da branch → PR.
  CI (`lint-onion-artifacts` + `onion-review`) rodou e passou; squash-merge só depois de checado.
- **Enquanto o PR #400 estava aberto/em CI**, a sessão-irmã (VPS) mergeou o PR #399
  (`kg-radar-fail-open-fix`) direto no mesmo `main` — exatamente o cenário two-homes descrito em
  `docs/onion/graph/coexistence-two-homes-2026-07.kg.yaml`. O squash-merge do #400 não conflitou.
- Se eu tivesse ficado em commit direto na `main` local (sem branch+PR), o fast-forward subsequente
  teria mascarado a origem da colisão — não daria pra distinguir "meu commit" de "commit alheio que
  chegou no meio". O branch+PR é o que deixa a concorrência **visível e auditável**, não só segura.

## Next crumb
`docs/knowledge-base/concepts/onion-working-method.md` cita PR pra features, mas não afirma
explicitamente "todo commit em `main`, incluindo housekeeping/triagem do próprio core, vai por PR,
sem exceção" — considerar adicionar essa frase lá, ancorada nesta entrada como evidência de campo.
