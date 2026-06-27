# 🛠️ Comandos `engineer/` — planejamento à entrega

Comandos da **dimensão de engenharia** do Onion: o ciclo faseado e retomável que vai de **planejamento** a **entrega de PR**, sobre o motor GitFlow e os adapters de forge e task-manager. Use quando for desenvolver uma feature, corrigir produção ou preparar/abrir um Pull Request.

O fluxo principal é uma cadeia retomável com sessões persistentes em `.claude/sessions/`: `plan` → `start` → `work` → `pre-pr` → `pr` → `pr-update`.

## Comandos

| Comando | Finalidade |
|---------|-----------|
| [`/engineer:plan`](plan.md) | Planejamento de feature: analisa e cria plano estruturado (`plan.md` da sessão). |
| [`/engineer:start`](start.md) | Inicia o desenvolvimento: cria a sessão e analisa as tasks do provider ativo (via `TASK_MANAGER_PROVIDER`). |
| [`/engineer:work`](work.md) | Continua a feature ativa: lê a sessão, identifica a próxima fase e atualiza progresso via task-manager abstraction. |
| [`/engineer:pre-pr`](pre-pr.md) | Validação completa antes do PR — verifica padrões e qualidade. |
| [`/engineer:pr`](pr.md) | Cria o Pull Request com integração GitFlow e sync automático. Delega a `@gitflow-specialist`. |
| [`/engineer:pr-update`](pr-update.md) | Atualiza um PR existente com mudanças adicionais. |
| [`/engineer:hotfix`](hotfix.md) | Emergency workflow completo: task no Task Manager + branch hotfix + desenvolvimento. Delega a `@gitflow-specialist`. |
| [`/engineer:validate-phase-sync`](validate-phase-sync.md) | Valida a sincronização entre as fases do `plan.md` e as subtasks do Task Manager. |
| [`/engineer:bump`](bump.md) | Bump de versão seguindo semver (major, minor ou patch). |
| [`/engineer:docs`](docs.md) | Invoca o agente de documentação para a branch atual. |
| [`/engineer:warm-up`](warm-up.md) | Preparação de contexto técnico/de engenharia (arquitetura, padrões, estrutura, frameworks). |

## 🔗 Referências
- Agente delegado: [`@gitflow-specialist`](../../agents/git/gitflow-specialist.md) — motor GitFlow para `pr` e `hotfix`.
- KB do motor: [`gitflow-patterns.md`](../../../docs/knowledge-base/frameworks/gitflow-patterns.md) — branch/merge/tag locais.
- Adapters de integração: [`utils/forge/`](../../utils/forge/) (PR/CI/Release) e [`utils/task-manager/`](../../utils/task-manager/) (tasks/sprints).
- Comandos irmãos: [`git/`](../git/README.md) (ciclo GitFlow), [`product/`](../product/README.md) (descoberta a backlog), [`test/`](../test/) e [`validate/`](../validate/) (qualidade pré-entrega).
