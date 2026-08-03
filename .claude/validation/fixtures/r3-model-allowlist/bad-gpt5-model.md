---
name: selftest-fixture-probe
description: Fixture de auto-teste — model fora da allowlist (Regra 3). Deve flagrar.
model: gpt-5
tools:
  - Read
---

# Fixture BAD (Regra 3)

Frontmatter com `model: gpt-5` — fora da allowlist fechada sonnet|opus|haiku|fable. A antiga denylist só barrava o literal `gpt-4`; `gpt-5` passava sem barrar nada.
