---
title: 'Convenção de worktrees codificada — ~/worktrees/<repo>/<branch-slug> (útil p/ o nx monorepo multi-time)'
date: 2026-07-10
from: onion-evolve (core / maestro principal)
to: granaai (Grana.Ai — consumidor, regulated)
re: codificação da convenção de worktrees (docs/evolution/worktree-convention-2026.md)
type: downstream-announce
classe: COMPATÍVEL
status: a transportar (rascunho na staging do core; entregar só após merge no core)
---

# 📣 Anúncio do core — layout canônico de worktrees duráveis

> Push core→derivado (downstream, doc-bridge). Nenhuma ação obrigatória.

## O que chegou ao core

Worktrees duráveis do maestro ganharam layout canônico: **`~/worktrees/<repo>/<branch-slug>/`**
(umbrella dir; branch-slug em kebab, `/`→`-`). Doc: `docs/evolution/worktree-convention-2026.md`
(chega via `--update`). Crédito: prática de campo do metagamify, validada contra o padrão de mercado
2026 (gwq) para fluxos paralelos com agentes IA e multi-repo.

## Por que interessa à Grana.Ai

- **Nx monorepo multi-time**: quando duas frentes (ex.: develop full + master docs-only, ou dois
  times) precisarem de sessões paralelas no mesmo repo, o layout dá endereço previsível a cada
  checkout — `~/worktrees/granaai/<branch-slug>` — sem poluir a home nem colidir com o clone principal.
- **Auditoria (regulado)**: um `ls ~/worktrees/` responde "que checkouts paralelos existem nesta
  máquina" — inventariável, sem vasculhar a home.
- O comportamento (um-escritor-por-escopo, handoff commitado) não muda; worktrees não entram no
  members.yaml (são estado de trabalho, não membros).

## O que fazer (quando quiser)

`/meta:adopt --update` traz o doc. Worktree novo → criar no layout canônico:
`git -C ~/granaai worktree add ~/worktrees/granaai/<branch-slug> <branch>`.

- Tratado → `git mv` deste arquivo para `inbound/_processed/`.
