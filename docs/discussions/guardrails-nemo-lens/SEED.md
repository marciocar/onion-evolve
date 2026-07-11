---
title: "Fonte de discussão — Camada de guardrails (core/federação/verticais/contextos) sob a lente Onion"
category: discussion
status: fonte-de-discussao-isolada
date: 2026-07-11
branch: discuss/guardrails-nemo-lens
---

# 🧵 Guardrails Onion — tão prático quanto NVIDIA NeMo Guardrails, mas na lente Onion

> **Isolada.** Pensa, não entrega. Nada vai pro core sem o maestro pedir. Não misturar com os outros temas.

## O tema
Uma **camada de guardrails** explícita e reconhecível para o core, a federação, as verticais e os contextos —
com a praticidade/reconhecimento de mercado do **NVIDIA NeMo Guardrails** (ou Guardrails AI, Llama Guard),
mas expressa na **lente Onion** (spec-as-code, determinístico, gated).

## Por que importa pro Onion
- **O Onion JÁ tem guardrails** — mas dispersos: `a2a-verify` (7 camadas), `trust-topology-check`, lint/selftest,
  never-clobber, `metaspec-gate-keeper`, e o estudo **camadas de liberação** (intake × execução) que acabamos
  de escrever (`authorization-layers-intake-vs-execution.md`). Falta o **nome, a moldura e a superfície**.
- NeMo/Guardrails-AI têm **vocabulário e DSL reconhecidos**; o Onion tem a **doutrina determinística + gated**
  que o campo está descobrindo. Fundir os dois = guardrail Onion nomeável e vendável.

## Perguntas de partida
1. O que é um "guardrail" no Onion — uma **camada de liberação** (o estudo já mapeou) formalizada como produto?
2. Como se compara/complementa NeMo (rails de diálogo), Llama Guard (classificador), Guardrails-AI (validação de output)?
3. Guardrails por **onde**: input (prompt), execução (o gate intake×execução), output (validação), federação (a2a-verify)?
4. Isto é uma **vertical nova** (`onion-guardrails`) ou uma consolidação transversal das existentes?

## Conexões com o que já existe
- **Estudo camadas de liberação** (`docs/knowledge-base/concepts/authorization-layers-intake-vs-execution.md`) — a espinha.
- `a2a-verify`, `trust`, `metaspec-gate-keeper`, `.claude/validation/` (lint+selftest), RFC-0004 §4.
- Liga com NS4 (control-plane/governança) da north-star.

## Como abrir
`cd ~/worktrees/onion-evolve/discuss-guardrails-nemo-lens && claude`
