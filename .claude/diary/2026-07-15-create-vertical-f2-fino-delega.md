---
date: 2026-07-15
instance: onion-evolve
type: innovation
classification: public
tags: [create-vertical, fino-delega, scaffolding, dogfood, vertical-hub]
affects: [meta, engineering]
breadcrumb_for: [meta:create-vertical, meta:create-command, meta:adopt]
share_with: []
next_recommended: "2026-07-15-kg-audit-layer-generalizes-to-content"
review_after: 2027-01-12
conflict_class: dynamic
---

## Signal
Ao dar 1ª classe a uma capacidade nova do core, o padrão vencedor é **orquestrador
fino-delega compondo helpers JÁ testáveis** (cobertos por selftest) — nunca reimplementar —
e **dogfoodar os modos de falha**, não só o happy-path. `/meta:create-vertical` (F2) é a prova.

## Evidence
- **O comando é fiação, não código novo:** `.claude/commands/meta/create-vertical.md`
  compõe os 3 helpers F1 (`bootstrap-new-project.sh` + `scaffold-book-dir.sh` +
  `generate-marketplace.sh`) + os `create-*` + o caminho `--plugin` opcional + fecha com `/meta:inventory`.
- **Dogfood pelos modos de falha** (slug descartável, não só happy-path): dry-run→real,
  never-clobber na re-execução, slug inválido → **exit 2**, greenfield escreve em path novo,
  substituição limpa (0 `{{PROJECT}}` órfão).
- **Gate mecânico:** SSOT 96→97 comandos (`meta/` 30→31); `lint-artifacts` 0/0; `lint-selftest` 277/277; mergeado no #370.
- **Estado em 2026-10-14 (re-teste, rodei):** o comando segue fiação dos 3 helpers
  (`create-vertical.md` l.113, l.117 e l.159). As famílias `bootstrap_vertical` (4/4), `scaffold_book`
  (4/4) e `marketplace_generate` (5/5) passaram. Modo de falha re-dogfoodado:
  `bootstrap-new-project.sh 'Bad Slug!' --dry-run` → `erro: <project-slug> deve ser kebab-case`, rc=2.
  A F3 (dogfood de campo greenfield) FECHOU em 2026-07-30 (PR #505, "achado do dogfood F3"), e a F4
  (face de design B3) segue gated (`create-vertical.md` l.220).

## Next crumb
Ao criar o próximo `meta:create-*`, **reusar helpers já cobertos por selftest e dogfoodar a
falha antes do merge** — não reescrever moldes existentes. A F3 está fechada (07-30, PR #505). Falta só a F4
(face de design B3, gated). Re-teste desta migalha = re-rodar os helpers/o comando (dynamic).

## Re-testada em 2026-10-14 — PARCIAL: (dynamic, rodei os helpers e o modo de falha) o Signal vale. O Evidence e o Next crumb foram reescritos: a F3 fechou em 07-30, e só a F4 segue gated.
