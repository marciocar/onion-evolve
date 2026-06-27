# 🧪 Comandos `test/` — geração e execução de testes

Comandos da camada de **testes automatizados** do Onion: geram e executam suites com **detecção automática de framework**, organizados pela pirâmide de testes (unit → integration → e2e). Use durante o desenvolvimento de uma feature para criar e rodar testes seguindo os padrões do projeto.

## Comandos

| Comando | Finalidade |
|---------|-----------|
| [`/test:unit`](unit.md) | Gera e executa testes unitários com detecção de framework (jest/vitest/pytest/junit) e relatório de coverage. Delega a `@test-engineer` / `@test-planner`. |
| [`/test:integration`](integration.md) | Gera e executa testes de integração (Grey-box): contract testing, boundary testing e fuzzing de API. Delega a `@test-engineer` / `@test-planner` / `@test-agent`. |
| [`/test:e2e`](e2e.md) | Gera e executa testes end-to-end (cypress/playwright/selenium) com gravação opcional de vídeo/screenshots. Delega a `@test-engineer` / `@test-planner`. |

## 🔗 Referências
- Agentes delegados: [`@test-engineer`](../../agents/testing/test-engineer.md), [`@test-planner`](../../agents/testing/test-planner.md), [`@test-agent`](../../agents/testing/test-agent.md)
- Comandos irmãos — estratégia de testes: [`/validate:test-strategy:create`](../validate/test-strategy/create.md), [`/validate:test-strategy:analyze`](../validate/test-strategy/analyze.md), [`/validate:qa-points:estimate`](../validate/qa-points/estimate.md)
- Fluxo de desenvolvimento: [`/engineer:work`](../engineer/work.md), [`/git:code-review`](../git/code-review.md)
