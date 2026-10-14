---
date: 2026-07-01
instance: onion-evolve
type: learning
classification: public
tags: [dogfooding, orchestration, audit, deterministic-guards]
affects: [meta, engineering]
breadcrumb_for: [meta:evolve, meta:orchestrate, onion-orchestration]
share_with: [collective]
next_recommended: "2026-07-01-federation-usage-modes-decision"
review_after: 2027-01-12
conflict_class: dynamic
---

## Signal
Worker de auditoria que **executa** o artefato acha bugs que worker que só **lê** jamais acharia.
Na auditoria de federação (run `wf_48c138b0-5f6`), os 2 blockers de código só apareceram porque o
worker rodou o script contra um schema populado — a leitura do código parecia correta.

## Evidence
- `trust-topology-check.sh`: `id_in_list()` sempre-falso (indentação 4≠6 + comentário inline) — invisível
  na leitura; provado executando contra cópia do members.yaml com `can_correct_to` populado.
- `onion-version.sh`: `role: source` hardcoded anulava o guard do `/meta:adopt` — só visível rodando o
  guard numa instância adotada simulada.
- Bônus do mesmo padrão: lint morria silencioso sem `jq` (12 guardas com `|| return` sob `set -e`) — só
  visível rodando o lint num ambiente sem jq.
- Cada bug virou guarda determinística permanente no lint-selftest (81→95 casos) — fix → re-dogfood.

## Next crumb
Ao autorar prompts de worker de auditoria: exigir "RODE o artefato e reporte exit codes reais" para todo
alvo executável (scripts, guards, fixtures). Veredito de leitura é hipótese; exit code é evidência.

## Re-testada em 2026-10-14: (dynamic, rodei os artefatos) `lint-selftest.sh --families trust_topology,onion_version,lint_silent_death,…` → 138/138 ✓, incluindo `trust: can_correct_to populado autoriza (regressão FED-2-0)`, os 4 casos de `onion-version` (stamp sem role → adopted) e os 6 de `lint-morte`; `id_in_list()` segue com indentação livre e corte de comentário antes da comparação (`trust-topology-check.sh` l.96); `onion-version.sh` não tem mais `role: source` fixo (l.50-54 lê o stamp).
