---
title: 'Convenção de worktrees codificada: ~/worktrees/<repo>/<branch-slug>'
date: 2026-07-10
from: onion-evolve (core / maestro principal)
to: pulse-mais (Pulse Mais — consumidor)
re: CHANGELOG de co-evolução, entrada 2026-07-10 (downstream, conciliação de backlog)
type: downstream-announce
classe: COMPATÍVEL
status: a transportar (rascunho na staging do core)
---

# 📣 Anúncio do core — Convenção de worktrees codificada: ~/worktrees/<repo>/<branch-slug>

> Push core→derivado (downstream, doc-bridge), transportado pelo humano. Gerado de uma entrada do
> CHANGELOG do core por `/meta:co-announce` (conciliação de backlog `alvo: todos`). O adotante é
> cego ao core: só vê o que é commitado no PRÓPRIO `inbound/`.

## 2026-07-10 · Convenção de worktrees codificada: `~/worktrees/<repo>/<branch-slug>` (crédito: metagamify) · COMPATÍVEL · alvo: todos

- **A prática de campo do metagamify virou doutrina**: worktrees duráveis do maestro agora têm layout
  canônico — umbrella **`~/worktrees/<repo>/<branch-slug>/`** (branch-slug em kebab, `/`→`-`).
  Doc novo: `docs/evolution/worktree-convention-2026.md` (chega via `--update`). O comportamento
  (topologia W3, um-escritor-por-escopo, handoff commitado) não muda — só a localização/nomenclatura,
  que era ad-hoc, foi decidida. Fundamentação: padrão de mercado 2026 (gwq umbrella) p/ fluxos
  paralelos com agentes IA e multi-repo — o caso da federação.
- **Fora do escopo**: worktrees efêmeros tool-managed (vendor-branch, adopt, `Workflow isolation`,
  `.claude/worktrees/` do harness) seguem gerenciados por quem os cria. Worktrees NÃO viram lineages
  no members.yaml. **Grandfather**: os pré-convenção (`~/metagamify-rhilo-atual`, `~/rhilo-app-atual`)
  ficam onde estão até recriação natural.
- **Caveat registrado**: o farol de sessão é por working-tree — worktrees irmãs não se veem via
  beacon; o handoff entre elas confia na convenção + commit (slice futuro anotado, abre com incidente real).
- Ação p/ adotantes: nenhuma obrigatória. Worktree novo → criar no layout canônico.

## Ação esperada no adotante
- Ler este anúncio (o hook "you have mail" já o sinala como 📥 inbound).
- Classe **COMPATÍVEL** — sem urgência. A mudança chega vendorizada via `/meta:adopt --update` no
  momento oportuno (ver a linha "Ação p/ adotantes" acima).
- Tratado → `git mv` deste arquivo para `inbound/_processed/` (lido/não-lido git-visível).

---
> **Transporte (maestro):** revise e copie este arquivo para o `inbound/` do adotante:
> `cp docs/evolution/federation/outbox/pulse-mais/2026-07-10-convencao-worktrees.md <repo-pulse-mais>/docs/evolution/inbound/`
> e commite **no repo do adotante** (a sessão do core não pusha repo alheio).
