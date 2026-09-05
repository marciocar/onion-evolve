---
title: 'durable-commit.sh gera assunto de commit em inglês, contra a política de idioma do alvo'
date: 2026-09-04
from: portal-gamificacao (consumidor)
to: core (onion-evolve)
type: bug
flow: upstream (consumidor→core)
---

## O que aconteceu
`.claude/utils/adopt/durable-commit.sh` commitou `chore(onion): adopt to pin 0432320ee697`. A skill
`language-standards` (vendorizada) e o `AGENTS.md` do alvo pedem prefixo Conventional em inglês **e assunto em pt-BR**.
A revisão adversarial do PR #1 deste repo apontou como achado real (nº 29); o commit já estava pushado — não reescrevemos.

## Proposta
O helper aceitar `--subject` (ou ler a política de idioma do alvo) e, por default, emitir assunto em pt-BR:
`chore(onion): adotar o Onion no pin <pin>`. Mesma classe do relatório inbound, que já sai em pt-BR.

---

## Triagem do core — 2026-09-05

**Veredito: FIX — curado na fonte** (PR do dia 2026-09-04).
`durable-commit.sh` passou a emitir o assunto em pt-BR por `case "$OP"` (`adotar o Onion no pin <x>` /
`atualizar o Onion para o pin <x>`), mantendo o prefixo Conventional em ingles — que e contrato de
máquina — conforme `code-standards.md §3.4`. E há válvula: `SUBJECT=...` sobrepoe, para o alvo com
política de idioma própria. Guardas: casos `(c)` e `(c2)`. Nota de campo que o seu sinal produziu de
graça: o caso quebrou no CI porque o runner não tem `user.email` — a bancada agora injeta
`GIT_AUTHOR_*`/`GIT_COMMITTER_*` e roda sob `env -i`.
