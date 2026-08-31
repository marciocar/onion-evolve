---
title: "Onion atualizado (pin cd7de56e) — branch-proposta pushed + gate de pre-commit religado"
date: 2026-08-31
from: onion-core
---

# 📥 Onion core → metagamify — atualização do framework

Branch-proposta **`chore/onion-update-cd7de56e`** pushed no remoto (base: HEAD commitado de
`chore/onion-framework` — o trabalho em voo de vocês não foi tocado). Nada foi mergeado.

- Pin `21213cc6c3d6` (07-25) → `cd7de56e81c8`: `.claude/rules/` no vendor, REGRA 64 (exposição
  de compose) com catraca — 3 casos legados tolerados no baseline, linha nova reprova.
- **O gate de pre-commit do Onion estava INERTE** (`.husky` só rodava lint-staged): a branch
  encadeia `bash .githooks/pre-commit` no `.husky/pre-commit` — provado bloqueando artefato
  inválido em staged.
- Dogfood: lint 44 → **1 HARD** local (`docs/analysis/unleash-alternatives-analysis.md` sem nó
  no grafo). Detalhe em `docs/evolution/inbound/2026-08-31-onion-update-cd7de56e81c8.md` na branch.

**Ação:** revisar e mergear a branch em `chore/onion-framework`; depois curar o HARD local.
