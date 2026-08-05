---
title: "Maestro's Aside — entrada lateral tipada (side-channel)"
date: 2026-08-04
from: onion-evolve (core / maestro principal)
to: onion-standalone (porta pública Claude — consumidor)
re: CHANGELOG de co-evolução, entrada 2026-08-04 (downstream)
type: downstream-announce
classe: COMPATÍVEL
status: a transportar (rascunho na staging do core)
---

# 📣 Anúncio do core — Maestro's Aside (entrada lateral tipada / side-channel)

> Push core→derivado (downstream, doc-bridge), transportado pelo humano. O core não roda nada no repo de
> vocês (I3). O adotante é cego ao core: só vê o que é commitado no PRÓPRIO inbound/.

- **Novo protocolo "Aparte do Maestro" / Maestro's Aside.** O maestro escreve um **marcador tipado** no
  INÍCIO da mensagem (`dúvida:` `corrige:` `reforço:` `nota:` `guarda:` `+etapa:` `-etapa:` `paralelo:`
  `guarda-regra:`) e o hook `UserPromptSubmit` (`.claude/hooks/aside-router-hook.sh` + motor
  `.claude/validation/aside-router.sh`) injeta a **ROTA canônica** como additionalContext — **recall, não
  gate**. É um DISPATCHER: roteia p/ diário/memória/STATE/orquestração que já existem (cria **zero store novo**).
- **COMPATÍVEL / regressão-zero:** SILENCIOSO quando não há marcador (custo-zero); NUNCA bloqueia (maestro é
  fonte confiável, R15.2); irreversíveis (`-etapa:`, `guarda-regra:`) injetam **propor→confirmar** (Ato 3/W6).
- **Idioma:** código em inglês (`aside` = o aparte teatral; `maestro` preservado); marcadores e nome-produto
  ("Aparte do Maestro") em pt-BR — vocabulário de interação.

## Ação esperada no adotante
- Ler este anúncio (o hook "you have mail" já o sinala como 📥 inbound).
- **OPCIONAL** — rodar `/meta:adopt --update` quando for oportuno: vendoriza o hook + o motor + a KB
  (`maestro-aside.md`) + a seção §4.6 do warm-up. **Retrocompatível** (silencioso sem marcador) — nada quebra
  se você não usar.
- Depois do update, os marcadores passam a valer na SUA sessão. Vocabulário e tabela de roteamento:
  `docs/knowledge-base/agentic-patterns/harness/maestro-aside.md`.

> **Nota de entrega tardia.** Este anúncio foi encenado em 2026-08-05, um dia depois dos demais
> destinatários: a rodada original de 2026-08-04 cobriu 4 dos 11 membros com `alvo: todos`. Nenhuma
> mudança de conteúdo — só o transporte que faltou.
