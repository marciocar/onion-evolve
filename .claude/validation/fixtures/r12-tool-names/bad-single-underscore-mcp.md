---
name: selftest-fixture-probe
description: Fixture de auto-teste do lint — agente com MCP em underscore único (Regra 12). Deve flagrar.
tools: [Read, mcp_ClickUp_create_task]
---

# Fixture de auto-teste — caso BAD (Regra 12, MCP underscore único)

`mcp_ClickUp_*` está em formato inválido; o Claude Code usa
`mcp__<server>__<tool>` (duplo underscore).
