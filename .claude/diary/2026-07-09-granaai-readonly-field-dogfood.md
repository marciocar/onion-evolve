---
date: 2026-07-09
instance: onion-evolve
type: learning
classification: protected
tags: [dogfood, read-only, granaai, regulated, scope, transport, i3, readiness-finding]
affects: [scope, transport, adoption, federation]
breadcrumb_for: [meta:adopt, meta:evolve]
share_with: []
next_recommended: "2026-07-09-adopt-vendor-branch-merge"
review_after: 2026-10-07
conflict_class: conditional
valid_when: "o granaai segue sem nenhum <app>/.claude/settings.json (camada time inexistente) — quando surgir, re-dogfoodar o resolver com a camada time REAL"
---

## Signal
Validar tooling contra **dado regulado real, read-only, sem escrever uma linha** é um modo de dogfood por si só —
e o mais honesto p/ um repo confidencial. Escopo (RFC-0005) + transporte (F2.1) foram exercitados contra o
**`~/granaai` REAL** (nx monorepo regulado, privado) e passaram **8/8** com **I3 preservado** (zero escrita).

## Evidence
- **Transporte:** `detect-transport.sh granaai` → `git-async` (default correto p/ regulado — nunca pull vivo);
  auto→`local` quando o clone existe na mesma máquina.
- **Escopo:** `resolve-scope-layers.sh --list` descobriu a cadeia **empresa real** (granaai/.claude/settings.json)
  + **pessoa** (~/.claude/settings.json). `compose-settings.sh` compôs empresa-REAL + time+pessoa **sintéticos**
  → JSON válido, override do time aplicado (model:opus), camada pessoa aplicada, **empresa preservada**
  (hooks/permissions não clobados), proveniência auditável.
- **Prova de I3:** `git -C ~/granaai status --short` **vazio** após tudo → zero escrita no repo regulado.
- **Achado de PRONTIDÃO (não-bug, e por isso valioso registrar):** o subdir de app (`apps/api-billing`)
  resolveu a **MESMA** cadeia da raiz — porque **não existe `<app>/.claude/settings.json`** ainda. A camada
  **TIME é net-new**: a ferramenta está pronta; falta **adotar a convenção** por-time quando quiser. Um dogfood
  read-only não "conserta" nada — ele **mede a distância entre pronto e adotado**, que é dado de decisão real.

## Next crumb
Diferente do dogfood de adoção (que achou o bug #303), este **não achou defeito** — o valor foi **confirmar
que o modelo funciona contra dado regulado sem tocá-lo** + mapear o gap de adoção (camada time inexistente).
Quando o Grana.Ai quiser escopo por-time: criar `apps/<time>/.claude/settings.json` e rodar o resolver.
Ver [[2026-07-09-scope-inheritance-rfc0005]] (a convenção validada aqui) e
[[2026-07-09-adopt-vendor-branch-merge]] (o dogfood-irmão que, esse sim, achou bug).
