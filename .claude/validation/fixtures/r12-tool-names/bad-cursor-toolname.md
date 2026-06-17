---
name: selftest-fixture-probe
description: Fixture de auto-teste do lint — agente com tool name estilo-Cursor (Regra 12). Deve flagrar.
tools: [read_file, Grep]
---

# Fixture de auto-teste — caso BAD (Regra 12, dialeto Cursor)

`read_file` não existe no Claude Code; deixa o subagente sem ferramenta. O nome
nativo correto seria `Read`.
