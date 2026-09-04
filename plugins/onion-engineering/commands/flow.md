---
name: flow
description: |
  Dispatcher único do ciclo de vida GitFlow: feature/release/hotfix × start/publish/finish.
  Orquestrador fino sobre o motor GitFlow (KB) + adapters forge e task-manager.
allowed-tools: Bash(git *) Bash(gh *) Read Edit Write Bash(cat .env*)
category: git
tags: [gitflow, feature, release, hotfix, dispatcher]
version: "1.0.0"
updated: "2026-06-13"
argument-hint: "<feature|release|hotfix> <start|publish|finish> [nome|versão]"
related_commands:
  - /git/init
  - /git/sync
  - /engineer/pr
related_agents:
  - gitflow-specialist
---

# 🌿 Git Flow — Dispatcher de Ciclo de Vida

Ponto de entrada **único** para o ciclo de vida GitFlow. Substitui os antigos
`git/{feature,release,hotfix}/{start,publish,finish}` (7 shims + 3 subpastas) por
um dispatcher arg-driven. É um **orquestrador fino**: a lógica canônica mora no
motor GitFlow ([gitflow-patterns.md](${CLAUDE_PLUGIN_ROOT}/kb/gitflow-patterns.md)),
operações de host remoto no forge adapter e sync
de task no task-manager adapter.

## 🚀 Como Usar

```bash
/onion-engineering:flow feature start "user-auth"     # cria feature/user-auth + sessão
/onion-engineering:flow feature publish               # push + review (forge)
/onion-engineering:flow feature finish                # merge → develop + cleanup
/onion-engineering:flow release start "minor"         # release/<versão> (semver auto-bump)
/onion-engineering:flow release finish                # merge main+develop, tag, Release no host
/onion-engineering:flow hotfix start "fix-pay"        # hotfix a partir de main + task urgente
/onion-engineering:flow hotfix finish                 # dual-merge + tag + Release + CI
```

`<type>` = `feature` | `release` | `hotfix` · `<action>` = `start` | `publish` (só feature) | `finish`.
Sem args válidos → mostre esta ajuda e pare (não adivinhe).

## 🧭 Princípios (válidos para toda combinação)

1. **Git local** (branch/checkout/merge/tag/**push**) = `git` direto, orientado pela KB. **Não** passa por adapter.
2. **Host remoto** (PR/review/CI/Release) = sempre via forge adapter — nunca `gh`/API em prosa (integrations.md §9).
3. **Task (opcional)** — se `TASK_MANAGER_PROVIDER` != `none`, via task-manager adapter; roteamento/formatação por provider são do adapter — **não reimplementar aqui**.
4. **Working directory limpo** antes de qualquer merge; em conflito → [§Template 6](${CLAUDE_PLUGIN_ROOT}/kb/gitflow-patterns.md#template-6-resolução-de-conflitos).

## ⚡ Matriz de Roteamento

Cada combinação `(type, action)` resolve para um Template do motor + ações de adapter:

| Combinação | Motor (KB) | Git local | Forge | Task Manager |
|---|---|---|---|---|
| `feature start <nome>` | [§Template 2](${CLAUDE_PLUGIN_ROOT}/kb/gitflow-patterns.md#template-2-feature-development) + [§Contrato de Sessão](${CLAUDE_PLUGIN_ROOT}/kb/gitflow-patterns.md#contrato-de-sessão-de-desenvolvimento) | cria `feature/<nome>` de `develop`, checkout; cria `.claude/sessions/<slug>/` | — | vincula task (opcional) |
| `feature publish` | §Template 2 | `git push -u origin feature/<nome>` | `requestReviewers` / PR draft (opcional) | `updateStatus → review` |
| `feature finish` | §Template 2 / §6 | merge `feature → develop`, cleanup, arquiva sessão | — | `updateStatus → done` |
| `release start <ver>` | [§Template 3](${CLAUDE_PLUGIN_ROOT}/kb/gitflow-patterns.md#template-3-release-process) + [§Semver](${CLAUDE_PLUGIN_ROOT}/kb/gitflow-patterns.md#algoritmo-unificado-de-auto-bump-semver) | resolve versão (explícita/auto-bump), cria `release/<ver>` de `develop` | — | cria task de release (opcional) |
| `release finish` | §Template 3 | merge `release → main`+`develop`, `git tag -a`, push `--tags` | `createRelease` (notas) + `getCIStatus(main)` | `updateStatus → done` |
| `hotfix start <nome>` | [§Template 4](${CLAUDE_PLUGIN_ROOT}/kb/gitflow-patterns.md#template-4-emergency-hotfix) | detecta primary branch, cria `hotfix/<nome>` da produção | — | cria task `urgent` (opcional) |
| `hotfix finish` | §Template 4 + §Semver | **dual-merge** `hotfix → main`+`develop`, tag patch, push `--tags` | `createRelease` + `getCIStatus(main)` | `updateStatus → done` |

## 📤 Saída

Reporte: combinação executada, branch resultante, ações de adapter realizadas e o próximo passo do ciclo (ex.: após `feature finish` → `/onion-engineering:sync develop`).

## 🔁 Migração (caminhos antigos → dispatcher)

| Antigo (removido) | Agora |
|---|---|
| `git:feature:start X` | `/onion-engineering:flow feature start X` |
| `git:feature:publish` | `/onion-engineering:flow feature publish` |
| `git:feature:finish` | `/onion-engineering:flow feature finish` |
| `git:release:start V` | `/onion-engineering:flow release start V` |
| `git:release:finish` | `/onion-engineering:flow release finish` |
| `git:hotfix:start X` | `/onion-engineering:flow hotfix start X` |
| `git:hotfix:finish` | `/onion-engineering:flow hotfix finish` |

## 📚 Referências

- Motor GitFlow (Templates, semver, sessão, conflitos): [gitflow-patterns.md](${CLAUDE_PLUGIN_ROOT}/kb/gitflow-patterns.md)
- Forge (PR/CI/Release): utils/forge/interface.md
- Sync de task: utils/task-manager/factory.md
- Setup: `/onion-engineering:init` · Pós-merge: `/onion-engineering:sync` · Mentor: `@gitflow-specialist`
