---
title: "Manual do Sistema Onion — Sumário"
category: materials
tags:
  - manual
  - toc
  - onboarding
status: skeleton
date: 2026-06-15
---

# Manual do Sistema Onion — Sumário (TOC)

**Status:** Esqueleto (Fase 4 — Materiais Derivados)
**Fonte:** [Onion: Identidade e Produto](../knowledge-base/meta/onion-framework-identity.md)
**Data:** 2026-06-15

---

> Este documento é o **sumário/estrutura** do "Manual do Sistema Onion" — o manual de usuário consolidado para times adotando o framework. Cada capítulo lista título, conteúdo previsto, fonte(s) existente(s) que já cobrem o tema e status de aproveitamento. O objetivo é mapear o que já existe em `docs/onion/` e `docs/applying/` antes de redigir o manual final.

---

## 1. Introdução — O que é o Onion

Visão geral do framework: pitch, problema que resolve, identidade canônica (template em `.claude/`, plataforma única Claude Code, três dimensões peer — produto/engenharia/compliance). Serve como porta de entrada para quem nunca ouviu falar do Onion.

- **Fonte:** [onion-framework-identity.md](../knowledge-base/meta/onion-framework-identity.md) §1, §2
- **Status:** ✅ conteúdo já existe e pode ser reaproveitado (síntese pronta na KB; falta adaptar tom para manual)

---

## 2. Instalação e Setup

Pré-requisitos (Claude Code, Git, conta em task manager), passo a passo de cópia de `.claude/` para o projeto-alvo, configuração do `.env` (Task Manager + Forge) e primeiro comando (`/warm-up`).

- **Fonte:** [getting-started.md](../onion/getting-started.md)
- **Status:** ✅ conteúdo já existe e pode ser reaproveitado

---

## 3. Conceitos Fundamentais

### 3.1 Arquitetura em camadas

As 5 camadas do framework: Comandos, Agentes, Skills, Abstrações (SDAAL), Documentação constitucional. Diagrama de componentes e fluxo de uma feature típica (`/product:collect` → ... → `/git:sync`).

- **Fonte:** [onion-framework-identity.md](../knowledge-base/meta/onion-framework-identity.md) §3; [claude-code-commands-architecture.md](../onion/claude-code-commands-architecture.md)
- **Status:** ✅ conteúdo já existe e pode ser reaproveitado

### 3.2 Skills de orquestração

As 5 skills (`onion`, `onion-fleet`, `onion-patterns`, `onion-validation`, `language-standards`) — quando cada uma entra em ação e como se relacionam com comandos/agentes.

- **Fonte:** [onion-framework-identity.md](../knowledge-base/meta/onion-framework-identity.md) §3 (camada 3); [index.md](../onion/index.md)
- **Status:** 🔲 precisa ser escrito (existe menção dispersa, falta capítulo dedicado)

### 3.3 Agentes especializados

Os 49 agentes em 9 categorias — como descobrir, quando invocar, diferença entre especialistas dedicados (ex.: `@jira-specialist`) e genéricos (`@task-specialist`).

- **Fonte:** [agents-reference.md](../onion/agents-reference.md)
- **Status:** ✅ conteúdo já existe e pode ser reaproveitado

### 3.4 Comandos invocáveis

Os 82 comandos por categoria (`product`, `engineer`, `git`, `docs`, `meta`, `validate`, `test`, `development`, `quick`), convenções de nomenclatura e arquitetura interna.

- **Fonte:** [commands-guide.md](../onion/commands-guide.md); [naming-conventions.md](../onion/naming-conventions.md); [claude-code-commands-architecture.md](../onion/claude-code-commands-architecture.md)
- **Status:** ✅ conteúdo já existe e pode ser reaproveitado

---

## 4. Workflows de Produto

Ciclo `product/collect → refine → spec → task → convert-to-tasks` — discovery a backlog. Inclui transcrição de reunião (`/product:whisper`), extração de ata, análise de dor do cliente.

- **Fonte:** [commands-guide.md](../onion/commands-guide.md) (seção produto); [onion-framework-identity.md](../knowledge-base/meta/onion-framework-identity.md) §4 (Produto & Discovery); [practical-examples.md](../onion/practical-examples.md)
- **Status:** ✅ conteúdo já existe e pode ser reaproveitado (espalhado em 3 fontes — consolidar)

---

## 5. Workflows de Engenharia

Ciclo `engineer/plan → start → work → pre-pr → pr → pr-update`, sessões retomáveis (`STATE.md`), GitFlow, hotfix urgente.

- **Fonte:** [engineering-flows.md](../onion/engineering-flows.md); [onion-framework-identity.md](../knowledge-base/meta/onion-framework-identity.md) §3 (fluxo de feature típica), §4 (Engenharia & GitFlow)
- **Status:** ✅ conteúdo já existe e pode ser reaproveitado

---

## 6. Task Manager & Forge Adapters

Padrão SDAAL: detecção de provider via `.env` (`TASK_MANAGER_PROVIDER`, `FORGE_PROVIDER`), mapa provider → variáveis → agente especialista, formatação por provider (ADF no Jira, Markdown/Unicode no ClickUp, etc.) e fallback gracioso.

- **Fonte:** [onion-framework-identity.md](../knowledge-base/meta/onion-framework-identity.md) §3 (Padrão SDAAL); `CLAUDE.md` (Task Manager + Forge); KB [task-manager-abstraction.md](../knowledge-base/concepts/task-manager-abstraction.md); adapters em `.claude/utils/task-manager/adapters/` e `.claude/utils/forge/adapters/`
- **Status:** 🔲 precisa ser escrito (fontes técnicas existem, falta capítulo de manual orientado ao usuário final)

---

## 7. Orquestração de Frota

Quando usar fan-out paralelo (`Workflow` + skill `onion-fleet`), sessões retomáveis para features longas, Agent Teams (opt-in/experimental) e Federation multi-repo.

- **Fonte:** [onion-framework-identity.md](../knowledge-base/meta/onion-framework-identity.md) §4 (Orquestração & Frota), §5 (Caso 1 — Federation, Caso 3 — Agent Teams); KB [agent-fleet-orchestration.md](../knowledge-base/concepts/agent-fleet-orchestration.md); KB [multi-repo-federation.md](../knowledge-base/concepts/multi-repo-federation.md)
- **Status:** 🔲 precisa ser escrito (KBs técnicas existem, falta capítulo de manual com exemplos guiados)

---

## 8. Auto-Evolução do Framework

`/meta:evolve` (auto-auditoria em 8 dimensões), `/meta:kb-freshness`, `/meta:inventory` (SSOT do filesystem), criação de novos comandos/agentes/skills via `/meta:create-*`.

- **Fonte:** [onion-framework-identity.md](../knowledge-base/meta/onion-framework-identity.md) §4 (Meta — Auto-Evolução), §5 (Caso 2 — `/meta:evolve`); [maintenance-checklist.md](../onion/maintenance-checklist.md); [inventory.md](../onion/inventory.md)
- **Status:** ✅ conteúdo já existe e pode ser reaproveitado (parcial — falta amarrar narrativa de "framework se auto-auditando")

---

## 9. Aplicando em Projetos (Greenfield / Legado / Regulado)

Árvore de decisão de cenário, pré-requisitos comuns, passo a passo por cenário (projeto novo, projeto existente com engenharia reversa, projeto sujeito a compliance ISO/SOC2/PMBOK).

- **Fonte:** [docs/applying/README.md](../applying/README.md), [applying-greenfield.md](../applying/applying-greenfield.md), [applying-legacy.md](../applying/applying-legacy.md), [applying-regulated.md](../applying/applying-regulated.md); [sistema-engenharia-reversa-guia-uso.md](../onion/sistema-engenharia-reversa-guia-uso.md)
- **Status:** ✅ conteúdo já existe e pode ser reaproveitado

---

## 10. Troubleshooting e Manutenção

Checklist de manutenção (adicionar comando/agente, atualizar documentação), CI/CD nativo (workflows GitHub Actions), problemas comuns e como diagnosticá-los.

- **Fonte:** [maintenance-checklist.md](../onion/maintenance-checklist.md); [ci.md](../onion/ci.md)
- **Status:** ✅ conteúdo já existe e pode ser reaproveitado

---

## 11. Referência

### 11.1 Inventário canônico

Contagens de comandos/agentes/skills/KBs, geradas do filesystem (SSOT).

- **Fonte:** [inventory.md](../onion/inventory.md)
- **Status:** ✅ conteúdo já existe e pode ser reaproveitado

### 11.2 Exemplos práticos

Casos de uso reais, cenários completos, melhores práticas.

- **Fonte:** [practical-examples.md](../onion/practical-examples.md)
- **Status:** ✅ conteúdo já existe e pode ser reaproveitado

### 11.3 Sistema de testes e validação

4 camadas integradas (KB, agentes, comandos de teste, comandos de validação), White/Grey/Black-box, QA Story Points, testes E2E.

- **Fonte:** [testing-validation-system.md](../onion/testing-validation-system.md); [end-to-end-validation-tests.md](../onion/end-to-end-validation-tests.md)
- **Status:** ✅ conteúdo já existe e pode ser reaproveitado

### 11.4 Glossário / FAQ

Termos do framework (SDAAL, STATE.md, fan-out, peer dimensions) e perguntas frequentes de quem está adotando.

- **Fonte:** [onion-framework-identity.md](../knowledge-base/meta/onion-framework-identity.md) §8 (FAQ)
- **Status:** ✅ conteúdo já existe e pode ser reaproveitado (FAQ pronta na KB; glossário de termos ainda não existe)

---

## Apêndice — Material histórico não incorporado

- [ESPERANTO.md](../onion/ESPERANTO.md) — workflow legado pré-consolidação; avaliar se vale incorporar como exemplo histórico ou descartar do manual final.

---

## Próximos passos

1. Validar este TOC com o time antes de redigir capítulos completos.
2. Priorizar capítulos 🔲 (6 e 7) — são os que exigem mais síntese nova.
3. Para capítulos ✅, o trabalho é principalmente de **adaptação de tom** (de referência técnica para manual de onboarding) e consolidação de fontes múltiplas em texto único.
