---
name: selftest-fixture-probe
description: Fixture de auto-teste do lint — agente com MCP de provider idiomático no frontmatter (Regra 12). Deve flagrar.
tools: [Read, mcp__clickup__create_task]
---

# Fixture de auto-teste — caso BAD (Regra 12, provider direto)

Declarar `mcp__clickup__*` num agente novo viola SDAAL: providers de task/forge
vão via adapter (`taskManager.*`/`forge.*`), não declarados no frontmatter.
