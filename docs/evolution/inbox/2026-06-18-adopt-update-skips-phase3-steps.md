---
title: 'Gap: /meta:adopt --update não re-aplica os passos de Fase 3 (settings.json + starter docs/evolution)'
date: 2026-06-18
from: sessão-core (achado ao fazer o backfill do rhilo, cover-mode)
to: onion-evolve (core)
type: field-signal / framework-gap
severity: medium
flow: A (downstream / distribuição)
relates: 2026-06-18-session-start-inbox-hook-pattern.md · PR #95 (distribuição do trio)
status: aberto (fix proposto; ação = sessão-core futura)
---

# Gap: `--update` pula os passos install-only da Fase 3

## Sintoma
O `#95` fez o `/meta:adopt` **distribuir o trio**, mas só o **Procedimento de cópia segura** (manifesto +
`.env.example`) roda no caminho `--update`. Os passos de **`settings.json` (never-clobber)** e **starter
`docs/evolution/`** vivem na **Fase 3 (install-only)**. Logo:

> Um adotante **que já tem `settings.json`** e roda `/meta:adopt --update` recebe os **scripts** de hook
> (via `.claude/hooks/` no manifesto) e o **comando** `/meta:co-evolve`, mas **NÃO** ganha o hook
> **registrado** no seu `settings.json` → o "you have mail" não dispara.

(No backfill do rhilo isso não mordeu **por acaso**: o rhilo **não tinha** `settings.json`, então a regra
"ausente → copiar" resolveu. Um adotante com settings próprio teria o gap.)

## Causa-raiz
Semântica install vs update divergem e a Fase 3 não é re-executada no `--update`:
- **install:** settings.json ausente → copiar; presente → sidecar `settings.onion.json` (merge manual).
- **update:** o certo é **MERGE idempotente** — adicionar os hooks Onion que faltam ao `settings.json`
  existente (sem duplicar, sem clobbar os do alvo). Hoje não acontece.

## Fix proposto
No caminho `--update` do `adopt.md`, após o Procedimento de cópia, re-aplicar **idempotentemente**:
1. **`settings.json`:** merge dos hooks Onion ausentes (SessionStart/PreCompact) no settings do alvo
   (ex.: via `jq` — adicionar entradas cujo `command` ainda não está presente). Never-clobber das demais.
2. **starter `docs/evolution/`:** criar `inbox/_processed/` + README-ponteiro **só se ausentes** (idempotente).
3. Re-stamp `.onion-version` (já existe).

## Próximo passo
Backlog do core (severity média — afeta adotantes com settings próprio). Casa com o item de robustez de
`settings.json` merge já citado no design do trio (#92).
