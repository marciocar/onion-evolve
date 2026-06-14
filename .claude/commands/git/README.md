# 🌿 Git Commands - Sistema Onion

Índice da categoria `git/` — comandos de versionamento e workflows GitFlow do Sistema Onion, com integração ao Task Manager ativo (`TASK_MANAGER_PROVIDER`) e a sessões em `.claude/sessions/`.

> **Motor GitFlow (git local)**: a referência canônica de workflow, troubleshooting, semver, contrato de sessão e proteção de branch é
> [`docs/knowledge-base/frameworks/gitflow-patterns.md`](../../../docs/knowledge-base/frameworks/gitflow-patterns.md).
> Os comandos abaixo são **orquestradores finos** que citam essa KB — não reimplementam a lógica. `@gitflow-specialist` é **mentor** para dúvidas ad-hoc.
>
> **Operações de host remoto** (PR, review, CI, Release) vivem no adapter SDAAL [`.claude/utils/forge/`](../../utils/forge/README.md). Git local (branch/merge/tag/push) é `git` direto.

## ⚡ Como usar

Todos são [Claude Code Commands](https://docs.claude.com/en/docs/claude-code/slash-commands), digitados **no chat da Claude Code** (não no terminal):

```
/git/init
/git:flow feature start "user-authentication"
/git:flow release start "minor"
```

## 📋 Comandos

O ciclo de vida GitFlow (feature/release/hotfix × start/publish/finish) vive num **dispatcher único** `/git:flow` — não há mais subpastas. Comandos atômicos distintos ficam separados.

| Comando | Finalidade |
|---------|-----------|
| `/git:flow <tipo> <ação> [nome\|versão]` | **Dispatcher do ciclo de vida GitFlow** — `feature`/`release`/`hotfix` × `start`/`publish`/`finish` |
| `/git/init` | Inicializar repositório com GitFlow e convenções padrão |
| `/git/sync [branch]` | Sincronização pós-merge (checkout + pull + cleanup de branch) |
| `/git/fast-commit` | Adicionar todas as mudanças e fazer commit rápido |
| `/git/help` | Ajuda contextual e quick reference dos workflows GitFlow |
| `/git/code-review` | ↪️ **Alias** → `/meta:setup-code-review` (setup de code review no CI; não é GitFlow) |

`/git:flow release start` aceita `"vX.Y.Z"` (versão exata) ou `patch` / `minor` / `major` (auto-bump semver). Matriz completa de combinações em [`flow.md`](flow.md).

## 🔁 Fluxos principais (resumo)

Os passos detalhados de cada fluxo estão no KB [`gitflow-patterns.md`](../../../docs/knowledge-base/frameworks/gitflow-patterns.md).

- **Feature**: `/git:flow feature start` → desenvolvimento (`/engineer/start` → `/engineer/work`) → `/git:flow feature finish` → `/git/sync develop`
- **Release**: `/git:flow release start "minor"` → testes/validação → `/git:flow release finish` → `/git/sync main`
- **Hotfix (separado)**: `/git:flow hotfix start "bug"` → fix → `/git:flow hotfix finish`
- **Hotfix (híbrido)**: `/engineer/hotfix "desc" --params` (cria task + sessão + branch) → fix → `/git:flow hotfix finish`

## 🔗 Integração e referências

- **Engineering**: `/engineer/start`, `/engineer/work`, `/engineer/pr`, `/engineer/hotfix`
- **Product / Task Manager**: `/product/task`, `/product/task-check`
- **Adapters (SDAAL)**: [`utils/forge/`](../../utils/forge/README.md) (PR/CI/Release) · [`utils/task-manager/`](../../utils/task-manager/README.md) (sync de tasks)
- **Agentes**: `@gitflow-specialist` (mentor GitFlow), especialista do provider ativo (`@jira-specialist`, `@clickup-specialist`, …) para sync de tasks
- **Referência GitFlow**: [`docs/knowledge-base/frameworks/gitflow-patterns.md`](../../../docs/knowledge-base/frameworks/gitflow-patterns.md) · skill `common:prompts:git-workflow-patterns`

**Para começar**: `/git/help` ou `/git/init`.
