---
title: 'Rodada do /meta:evolve no adotante: 14 achados sobreviventes, todos em arquivo vendorizado do core'
date: 2026-10-12
from: onion-kg-ssot (produto KG-SSOT, papel adopted)
to: core
type: field-signal
pin: dcdacf9ba196
---

# Sinal: o que a rodada do /meta:evolve achou na maquinaria vendorizada

A rodada `wf_045928e7-174` (16 agentes, 0 erro) varreu D1, D2, D3, D6, D7 e D8; a dimensão MAQ foi pulada pelo
próprio workflow. Sobreviveram 14 achados ao refutador, nenhum bloqueante, e um foi refutado (D1-0: `adopt.md` com
800 linhas está no teto, não acima dele). **Todos os alvos são byte-idênticos aos do core no pin `dcdacf9ba196`**
(conferido com `cmp` em 12 arquivos). Por isso não editei nada aqui: a correção é de vocês e chega pelo update.

## Recomendados (overlap sem a razão escrita)

| Id | Alvo | O que falta |
|---|---|---|
| D2-0 | `agents/testing/test-engineer.md`, `test-agent.md`, `commands/validate/test-strategy/create.md` | `test-engineer` não declara "Diferença vs" frente a `test-agent`, `test-planner` e `/test:*`; `test-agent` sobrepõe `/validate:test-strategy:create` sem nota |
| D2-2 | `commands/meta/create-agent.md`, `create-command.md`, `agents/meta/*-creator-specialist.md` | comando e agente com descrição quase idêntica; a relação (o comando é entrada, o agente tem o protocolo) só aparece no corpo do agente |
| D2-3 | `commands/engineer/hotfix.md`, `start.md`, `pr.md` | nenhum declara por que coexiste com `/git:flow` (o engineer é faseado, com sessão; o git:flow é o motor). O auditor alerta para não fundir as fases |

## Oportunistas

- D1-1: `commands/meta/kg.md` tem 519 linhas, acima do alerta de 500.
- D2-4 a D2-7: declarações de distinção unilaterais ou ausentes (os `warm-up`, consolidate-meetings contra
  consolidate-documents, os dois `estimate`, o cluster de marca e identidade).
- D6-2: `/meta:context-freshness` e `/meta:kg-freshness` mandam autorar um Workflow a cada execução, sem script salvo.
- D6-3: ferramentas MCP diretas em `system-documentation-orchestrator` e `jira-specialist`.
- D8-0: 10 dos 13 `SKILL.md` não declaram `name:` no frontmatter.
- D6-4 e D7-1: verificações limpas (sem resíduo do abandonado de 2026-05-18; sem symlink quebrado).

## Onde conferir

O retorno completo da rodada está no journal do workflow, nesta máquina. Os ids acima são os do retorno.
