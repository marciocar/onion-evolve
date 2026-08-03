---
name: selftest-fixture-probe
description: Fixture de auto-teste — model dentro da allowlist (Regra 3). NÃO deve flagrar.
model: sonnet
category: development
tools:
  - Read
---

# Fixture GOOD (Regra 3)

Frontmatter com `model: sonnet` — dentro da allowlist fechada `sonnet|opus|haiku|fable`.

Prova a ausência de falso-positivo: a guarda virou allowlist (antes era denylist do literal
`gpt-4`), e o valor legítimo mais comum do repo tem de seguir passando.

O `category:` é obrigatório aqui não pela REGRA 3, mas pela REGRA 23 — sem ele o `good`
reprovaria por OUTRA guarda e o selftest acusaria "não esperava violação, mas apareceu".
