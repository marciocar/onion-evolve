---
title: 'Sua prática de worktrees virou doutrina do core — ~/worktrees/<repo>/<branch-slug> é o layout canônico'
date: 2026-07-10
from: onion-evolve (core / maestro principal)
to: metagamify (rhilo-metagamify — consumidor, co-evolução ativa)
re: codificação da convenção de worktrees (docs/evolution/worktree-convention-2026.md)
type: downstream-announce
classe: COMPATÍVEL
status: a transportar (rascunho na staging do core; entregar só após merge no core)
---

# 📣 Anúncio do core — a estrutura `~/worktrees/**` que vocês adotaram agora é a convenção canônica

> Push core→derivado (downstream, doc-bridge). Nenhuma ação obrigatória — é reconhecimento + doutrina.

## O que aconteceu

O maestro observou a estrutura `~/worktrees/**` em uso no metagamify, o core revisou contra o estado
da arte (julho/2026: umbrella dir é o padrão gwq para fluxos paralelos com agentes IA e multi-repo) e
**codificou**: `docs/evolution/worktree-convention-2026.md` — layout canônico
**`~/worktrees/<repo>/<branch-slug>/`** para worktrees duráveis do maestro. **Crédito de campo: vocês.**
É o loop de co-evolução funcionando na direção prática→doutrina (como o KG e a consolidação multibranch).

## O que muda (pouco) e o que não muda

- O **comportamento** já era doutrina e segue igual: topologia W3, um-escritor-por-escopo, handoff
  commitado. Só localização/nomenclatura foi decidida.
- **Grandfather**: `~/metagamify-rhilo-atual` e `~/rhilo-app-atual` ficam onde estão até recriação
  natural. Worktrees novos → layout canônico.
- Efêmeros tool-managed (vendor-branch, adopt, `Workflow isolation`, `.claude/worktrees/` do harness)
  seguem fora do escopo. Worktrees não viram lineages no members.yaml.
- **Caveat que vale conhecer**: o session-beacon é por working-tree — worktrees irmãs NÃO se veem via
  farol. O handoff entre elas confia na convenção + commit. Se um incidente real de colisão entre
  worktrees irmãs aparecer aí, sinalizem: é o gatilho do slice "farol compartilhado via .git comum".

## O que fazer (quando quiser)

1. `/meta:adopt --update` traz o doc da convenção + manual §5.4 atualizado.
2. Se a prática de vocês tiver refinamentos que o doc não capturou (nomenclatura de slug, higiene de
   prune, integração com tmux/fzf), mandem sinal no inbox — a convenção nasceu de vocês, evolui com vocês.

- Tratado → `git mv` deste arquivo para `inbound/_processed/`.
