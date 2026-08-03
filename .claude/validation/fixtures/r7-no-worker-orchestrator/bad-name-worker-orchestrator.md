---
name: worker-orchestrator
description: |
  Agente que tenta reintroduzir o anti-padrão worker-orchestrator (fan-out genérico
  sem especialização de domínio) que a arquitetura do Onion proíbe explicitamente
  em §4.2 — orquestração deve ser feita pelo maestro via onion-orchestration/Workflow,
  nunca por um agente 'worker-orchestrator' dedicado.
model: sonnet
tools:
  - Read
  - Bash
---

# worker-orchestrator

Este agente delega tarefas genéricas a workers sem contexto de domínio, replicando
o padrão que a REGRA 7 existe para bloquear.
