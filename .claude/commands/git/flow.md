---
name: flow
description: |
  Dispatcher único do ciclo de vida GitFlow: feature/release/hotfix × start/publish/finish.
  Orquestrador fino sobre o motor GitFlow (KB) + adapters forge e task-manager.
model: sonnet
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
motor GitFlow ([gitflow-patterns.md](../../../docs/knowledge-base/frameworks/gitflow-patterns.md)),
operações de host remoto no [forge adapter](../../utils/forge/interface.md) e sync
de task no [task-manager adapter](../../utils/task-manager/factory.md).

## 🚀 Como Usar

```bash
/git:flow feature start "user-auth"     # cria feature/user-auth + sessão
/git:flow feature publish               # push + review (forge)
/git:flow feature finish                # merge → develop + cleanup
/git:flow release start "minor"         # release/<versão> (semver auto-bump)
/git:flow release finish                # merge main+develop, tag, Release no host
/git:flow hotfix start "fix-pay"        # hotfix a partir de main + task urgente
/git:flow hotfix finish                 # dual-merge + tag + Release + CI
```

`<type>` = `feature` | `release` | `hotfix` · `<action>` = `start` | `publish` (só feature) | `finish`.
Sem args válidos → mostre esta ajuda e pare (não adivinhe).

## 🧭 Princípios (válidos para toda combinação)

1. **Git local** (branch/checkout/merge/tag/**push**) = `git` direto, orientado pela KB. **Não** passa por adapter.
2. **Host remoto** (PR/review/CI/Release) = sempre via [forge adapter](../../utils/forge/interface.md) — nunca `gh`/API em prosa (integrations.md §9).
3. **Task (opcional)** — se `TASK_MANAGER_PROVIDER` != `none`, via [task-manager adapter](../../utils/task-manager/factory.md); roteamento/formatação por provider são do adapter — **não reimplementar aqui**.
4. **Working directory limpo** antes de qualquer merge; em conflito → [§Template 6](../../../docs/knowledge-base/frameworks/gitflow-patterns.md#template-6-resolução-de-conflitos).

## ⚡ Matriz de Roteamento

Cada combinação `(type, action)` resolve para um Template do motor + ações de adapter:

| Combinação | Motor (KB) | Git local | Forge | Task Manager |
|---|---|---|---|---|
| `feature start <nome>` | [§Template 2](../../../docs/knowledge-base/frameworks/gitflow-patterns.md#template-2-feature-development) + [§Contrato de Sessão](../../../docs/knowledge-base/frameworks/gitflow-patterns.md#contrato-de-sessão-de-desenvolvimento) | cria `feature/<nome>` de `develop`, checkout; cria `.claude/sessions/<slug>/` | — | vincula task (opcional) |
| `feature publish` | §Template 2 | `git push -u origin feature/<nome>` | `requestReviewers` / PR draft (opcional) | `updateStatus → review` |
| `feature finish` | §Template 2 / §6 | merge `feature → develop`, cleanup, arquiva sessão | — | `updateStatus → done` |
| `release start <ver>` | [§Template 3](../../../docs/knowledge-base/frameworks/gitflow-patterns.md#template-3-release-process) + [§Semver](../../../docs/knowledge-base/frameworks/gitflow-patterns.md#algoritmo-unificado-de-auto-bump-semver) | resolve versão (explícita/auto-bump), cria `release/<ver>` de `develop` | — | cria task de release (opcional) |
| `release finish` | §Template 3 | merge `release → main`+`develop`, `git tag -a`, push `--tags` | `createRelease` (notas) + `getCIStatus(main)` | `updateStatus → done` |
| `hotfix start <nome>` | [§Template 4](../../../docs/knowledge-base/frameworks/gitflow-patterns.md#template-4-emergency-hotfix) | detecta primary branch, cria `hotfix/<nome>` da produção | — | cria task `urgent` (opcional) |
| `hotfix finish` | §Template 4 + §Semver | **dual-merge** `hotfix → main`+`develop`, tag patch, push `--tags` | `createRelease` + `getCIStatus(main)` | `updateStatus → done` |

## 📤 Saída

Reporte: combinação executada, branch resultante, ações de adapter realizadas e o próximo passo do ciclo (ex.: após `feature finish` → `/git:sync develop`).

## 🔁 Migração (caminhos antigos → dispatcher)

| Antigo (removido) | Agora |
|---|---|
| `/git:feature:start X` | `/git:flow feature start X` |
| `/git:feature:publish` | `/git:flow feature publish` |
| `/git:feature:finish` | `/git:flow feature finish` |
| `/git:release:start V` | `/git:flow release start V` |
| `/git:release:finish` | `/git:flow release finish` |
| `/git:hotfix:start X` | `/git:flow hotfix start X` |
| `/git:hotfix:finish` | `/git:flow hotfix finish` |

## 📚 Referências

- Motor GitFlow (Templates, semver, sessão, conflitos): [gitflow-patterns.md](../../../docs/knowledge-base/frameworks/gitflow-patterns.md)
- Forge (PR/CI/Release): [utils/forge/interface.md](../../utils/forge/interface.md)
- Sync de task: [utils/task-manager/factory.md](../../utils/task-manager/factory.md)
- Setup: `/git:init` · Pós-merge: `/git:sync` · Mentor: `@gitflow-specialist`
