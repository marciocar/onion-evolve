---
date: 2026-07-08
instance: onion-evolve
type: innovation
classification: public
tags: [plugin, marketplace, role-scoping, federation, distribution, capability-contract]
affects: [meta, federation, engineering]
breadcrumb_for: [meta:adopt, meta:graph, meta:evolve]
share_with: [collective]
next_recommended: "2026-07-03-declared-vs-verified-family"
review_after: 2026-10-06
conflict_class: static
---

## Signal
A Camada 1 do Onion (capacidade: commands/agents/skills/hooks) virou **plugins role-scoped** — e a
pesquisa provou que a federação hand-rolled do Onion é **quase um clone do padrão Anthropic 2026**
(marketplace de organização: version pinning + auto-update + **acesso-por-grupo** = escopo por papel
nativo). Ao evoluir distribuição, pense em 3 camadas: **L1 → plugin/marketplace** (resolve durabilidade),
**L2 (docs path-addressed) + L3 (governança/co-evolução) → `/meta:adopt`** (o moat, não migra).

## Evidence
- 5 fases mergeadas em 1 dia (#292–#296): 4 verticais engineering-side (`onion-engineering/product/
  testing/docs`) somados a design/compliance (6 plugins); `roles.yaml` (mapa role→bundle) + resolver;
  `graph --closure` (escopo DERIVADO do grafo, com ponte de prefixo agent:X→X); `SKILLS`/`HOOKS` no
  assembler; runbook da Fase 5.
- ~80% da maquinaria JÁ EXISTIA (assemble-plugin.sh + convenção verticals/ + capability contracts +
  drift-guards R19/R20) — migração foi extensão, não invenção. Autorar vertical = pura data-entry.
- Achado de campo (jq): o lint LOCAL mascarava o drift do grafo sem jq; o CI (com jq) pegou. Ver [[lint-graph-needs-jq]].
- Blindagem: lint R22 (role-bundle drift-guard) + selftests (158→165 guardas). CI verde em todos os 5 PRs.
- Doutrina reafirmada (ADR exchange-unit, não-decisão): **plugin não substitui `/meta:adopt`** — coexistem
  por camada. Plugin ≠ produto público: marketplace privado é só um repo git → satisfaz "não-público" do Onion.

## Next crumb
Fase 5 é operacional/interativa (gated Team/Enterprise) — runbook em
`docs/analysis/onion-plugin-marketplace-runbook-2026-07.md`. Refinamentos: enriquecer os manifestos
engineering-side com suas doc-deps (`kb:`/`context` no capability contract) p/ o `--closure` incluir os
docs L2; triar o sinal `inbox/2026-07-08-proposta-branch-onion-vendor` (síntese estratégica + interop A2A
L3) num `/meta:evolve`. Ao re-testar: a Camada 1-via-plugin ainda é o padrão-comunidade vigente?
