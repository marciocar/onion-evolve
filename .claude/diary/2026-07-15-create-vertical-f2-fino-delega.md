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
review_after: 2026-10-13
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

## Next crumb
Ao criar o próximo `meta:create-*`, **reusar helpers já cobertos por selftest e dogfoodar a
falha antes do merge** — não reescrever moldes existentes. Faltam F3 (campo — uso real, não
re-scaffold; ver `[[2026-07-15-projected-scaffold-step-nonexistent]]`) e F4 (face de design
B3, gated). Re-teste desta migalha = re-rodar os helpers/o comando (dynamic).
