---
name: help
description: Ajuda contextual da vertical de engenharia do Onion — o ciclo faseado plan→pr + GitFlow + especialistas.
model: sonnet
allowed-tools: Read Bash(git *)
category: engineer
tags: [help, engineering, gitflow, pull-request, documentation]
version: "3.0.0"
updated: "2026-07-08"
---

# 🛠️ Engenharia — Sistema de Ajuda

Ajuda contextual da **dimensão de engenharia** do Onion: o ciclo faseado e retomável que vai de **planejamento** a **entrega de PR**, sobre o motor GitFlow e os adapters de forge e task-manager. Detecta o estado do repositório e sugere o próximo passo.

> **Prefixo conforme a instalação:** num Onion completo os comandos são `/engineer:<cmd>` e `/git:<cmd>`; instalado como **plugin** (`onion-engineering`), tudo vive num namespace plano: `/onion-engineering:<cmd>`. Abaixo os comandos aparecem pelo nome — use o prefixo do seu contexto.

## 🎯 O que esta vertical entrega

- **Fluxo faseado retomável** com sessões persistentes em `.claude/sessions/`: `plan → start → work → pre-pr → pr → pr-update`.
- **Ciclo de vida GitFlow** (dispatcher único `flow` + `init`/`sync`/`fast-commit`) sobre o motor canônico.
- **Especialistas de código**: Node, React, Postgres, NX (mono/migração), Docker, segurança Linux, Claude Code, Runflow, ZEN Engine — mais os revisores de branch e o `@gitflow-specialist`.
- **Gates pré-PR** de qualidade, review e conformidade.

> **Camada 1 só.** Os adapters de **task-manager** (`TASK_MANAGER_PROVIDER`) e **forge** (PR/CI/Release) são do consumidor, resolvidos via SDAAL. Git local (branch/merge/tag/push) é `git` direto, orientado pelo motor.

## 🚀 Fluxo principal (planejamento → entrega)

| Comando | Finalidade |
|---------|-----------|
| `plan` | Planejamento de feature: analisa e cria o `plan.md` estruturado da sessão. |
| `start` | Inicia o desenvolvimento: cria a sessão e analisa as tasks do provider ativo. |
| `work` | Continua a feature ativa: lê a sessão, identifica a próxima fase e atualiza progresso. |
| `pre-pr` | Validação completa antes do PR — padrões e qualidade. |
| `pr` | Cria o Pull Request (integração GitFlow + sync). Delega a `@gitflow-specialist`. |
| `pr-update` | Atualiza um PR existente com mudanças adicionais. |
| `validate-phase-sync` | Valida a sincronização entre as fases do `plan.md` e as subtasks do Task Manager. |

## 🌿 Ciclo GitFlow

| Comando | Finalidade |
|---------|-----------|
| `flow <tipo> <ação>` | Dispatcher único: `feature\|release\|hotfix` × `start\|publish\|finish`. |
| `init` | Configura GitFlow e convenções no repositório. |
| `sync [branch]` | Sincroniza branches após merge de PR (protege branches críticas). |
| `fast-commit` | Adiciona tudo e faz commit rápido (Conventional Commits). |
| `hotfix` | Emergency workflow: task + branch hotfix + desenvolvimento. Delega a `@gitflow-specialist`. |

> `<tipo>` = feature\|release\|hotfix · `<ação>` = start\|publish (só feature)\|finish.

## 🔧 Utilitários

| Comando | Finalidade |
|---------|-----------|
| `bump` | Bump de versão seguindo semver (major/minor/patch). |
| `docs` | Invoca o agente de documentação para a branch atual. |
| `warm-up` | Preparação de contexto técnico/de engenharia (arquitetura, padrões, frameworks). |
| `code-review` | Alias → setup de code review no CI (`/meta:setup-code-review`). |

## 📚 Fontes canônicas

- **Motor GitFlow** (git local, semver, contrato de sessão, proteção de branch): [`gitflow-patterns.md`](../../../docs/knowledge-base/frameworks/gitflow-patterns.md) — a fonte única; os comandos são orquestradores finos que a citam.
- **Mentor ad-hoc / recovery**: `@gitflow-specialist`.
- **Operações de host remoto** (PR/CI/Release): [`utils/forge/`](../../utils/forge/README.md).
- **Tasks/sprints**: [`utils/task-manager/`](../../utils/task-manager/README.md).

## 🆘 Troubleshooting rápido

- **"não sei em que fase estou"** → `work` (lê a sessão e diz a próxima ação) ou `warm-up`.
- **"PR não sobe / CI falha"** → confira o forge adapter (`FORGE_PROVIDER`/token); mentor: `@gitflow-specialist`.
- **"task não sincroniza"** → confira `TASK_MANAGER_PROVIDER` no `.env`; provider `none` opera offline.
- **"branch bagunçada"** → `sync`; para merge/release, o motor em `gitflow-patterns.md`.
