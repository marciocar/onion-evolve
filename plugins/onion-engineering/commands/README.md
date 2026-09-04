# 🛠️ Comandos `engineer/` — planejamento à entrega

Comandos da **dimensão de engenharia** do Onion: o ciclo faseado e retomável que vai de **planejamento** a **entrega de PR**, sobre o motor GitFlow e os adapters de forge e task-manager. Use quando for desenvolver uma feature, corrigir produção ou preparar/abrir um Pull Request.

O fluxo principal é uma cadeia retomável com sessões persistentes em `.claude/sessions/`: `plan` → `start` → `work` → `pre-pr` → `pr` → `pr-update`.

## Comandos

| Comando | Finalidade |
|---------|-----------|
| [`/onion-engineering:plan`](plan.md) | Planejamento de feature: analisa e cria plano estruturado (`plan.md` da sessão). |
| [`/onion-engineering:start`](start.md) | Inicia o desenvolvimento: cria a sessão e analisa as tasks do provider ativo (via `TASK_MANAGER_PROVIDER`). |
| [`/onion-engineering:work`](work.md) | Continua a feature ativa: lê a sessão, identifica a próxima fase e atualiza progresso via task-manager abstraction. |
| [`/onion-engineering:pre-pr`](pre-pr.md) | Validação completa antes do PR — verifica padrões e qualidade. |
| [`/onion-engineering:pr`](pr.md) | Cria o Pull Request com integração GitFlow e sync automático. Delega a `@gitflow-specialist`. |
| [`/onion-engineering:pr-update`](pr-update.md) | Atualiza um PR existente com mudanças adicionais. |
| [`/onion-engineering:hotfix`](hotfix.md) | Emergency workflow completo: task no Task Manager + branch hotfix + desenvolvimento. Delega a `@gitflow-specialist`. |
| [`/onion-engineering:validate-phase-sync`](validate-phase-sync.md) | Valida a sincronização entre as fases do `plan.md` e as subtasks do Task Manager. |
| [`/onion-engineering:bump`](bump.md) | Bump de versão seguindo semver (major, minor ou patch). |
| [`/onion-engineering:docs`](docs.md) | Invoca o agente de documentação para a branch atual. |
| [`/onion-engineering:warm-up`](warm-up.md) | Preparação de contexto técnico/de engenharia (arquitetura, padrões, estrutura, frameworks). |

## 🔗 Referências
- Agente delegado: `@gitflow-specialist` — motor GitFlow para `pr` e `hotfix`.
- KB do motor: [`gitflow-patterns.md`](${CLAUDE_PLUGIN_ROOT}/kb/gitflow-patterns.md) — branch/merge/tag locais.
- Adapters de integração: `utils/forge/` (PR/CI/Release) e `utils/task-manager/` (tasks/sprints).
- Comandos irmãos: `git/` (ciclo GitFlow), `product/` (descoberta a backlog), `test/` e `validate/` (qualidade pré-entrega).
