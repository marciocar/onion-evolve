---
title: 'Convenção de worktrees — adendo: worktree do harness que vira DURÁVEL vai p/ ~/worktrees/'
date: 2026-07-18
from: onion-evolve (core / maestro principal)
to: onion-mini (onion-mini (Onion Mini — a versão mini e portátil, ex-onion-portable) — consumidor)
re: CHANGELOG de co-evolução, entrada 2026-07-18 (downstream)
type: downstream-announce
classe: COMPATÍVEL
status: a transportar (rascunho na staging do core)
---

# 📣 Anúncio do core — Convenção de worktrees: adendo (harness-durável)

> Push core→derivado (downstream, doc-bridge), transportado pelo humano. Gerado de uma entrada do CHANGELOG
> do core por /meta:co-announce. O adotante é cego ao core: só vê o que é commitado no PRÓPRIO inbound/.

- **Refina a convenção de worktrees (2026-07-10).** O harness do Claude Code (`--worktree`/`EnterWorktree`)
  cria em `.claude/worktrees/<name>` **por padrão** — certo para **efêmero** (auto-cleanup ao sair limpo).
  Mas quando a sessão vira **durável** (fica `locked`, sobrevive a várias sessões, é um tópico `discuss/*` de
  dias), ela pertence a `~/worktrees/<repo>/<branch-slug>/`. Regra nova: **a durabilidade decide o local, não
  a ferramenta que criou.**
- **Ação:** efêmero fica em `.claude/worktrees/` (o lint já o ignora); **durável nascido pelo harness →
  recriar** no path da convenção **quando a sessão fechar** (`git worktree remove .claude/worktrees/<name>` +
  `git worktree add ~/worktrees/<repo>/<branch-slug> <branch>`) — nunca com a sessão viva/locked.
- **Sinal barato:** o `+` no nome de um worktree (`discuss+foo`) é carimbo do harness (a convenção usa `-`).
- **Sem breaking** — vale p/ worktree novo; existentes seguem grandfather. Doutrina: `docs/evolution/worktree-convention-2026.md` (adendo 2026-07-18).

## Ação esperada no adotante
- Ler este anúncio (o hook "you have mail" já o sinala como 📥 inbound).
- **Classe COMPATÍVEL, sem update obrigatório** — doutrina de higiene de worktree; aplique ao criar worktree novo.
- Tratado → git mv deste arquivo para inbound/_processed/ (lido/não-lido git-visível).

---
> **Transporte (maestro):** revise e copie este arquivo para o inbound/ do adotante e commite no repo DELE.
