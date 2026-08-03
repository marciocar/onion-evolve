---
name: presentation-orchestrator
description: Fixture de auto-teste — agente orquestrador LEGÍTIMO (Regra 7). NÃO deve flagrar.
model: sonnet
category: product
tools:
  - Read
---

# Fixture GOOD (Regra 7)

O `name:` contém `orchestrator`, mas **não** `worker-orchestrator`. Este é o vizinho legítimo
mais próximo: o repo tem orquestradores reais (`presentation-orchestrator`,
`system-documentation-orchestrator`) e a guarda não pode confundi-los com o anti-padrão.

O que a REGRA 7 proíbe é o agente-worker-genérico (`architecture.md` §4.2), não a palavra
"orchestrator" — se a guarda casasse a substring solta, quebraria 2 agentes reais do core.

`category:` presente por causa da REGRA 23 (ver a fixture irmã da R3).
