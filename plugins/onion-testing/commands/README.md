# ✅ Comandos `validate/` — qualidade e estratégia de teste

Comandos de **validação e garantia de qualidade** do Onion: estratégias de teste multi-perspectiva (White/Grey/Black-box), estimativa de QA Story Points, sessões colaborativas de validação (Three Amigos, pair testing) e checagem de completude de workflows. Use quando precisar planejar, estimar ou auditar o esforço de teste de uma feature, ou facilitar o refinement colaborativo de uma story.

## Comandos

| Comando | Finalidade |
|---------|-----------|
| [`/onion-testing:workflow`](workflow.md) | Valida a completude de workflows do Sistema Onion (sessões, fases). |
| `validate:test-strategy:create` | Cria estratégia completa de teste multi-perspectiva (White/Grey/Black-box) com cálculo automático de QA Story Points. Delega a `@test-engineer` / `@test-planner`. |
| `validate:test-strategy:analyze` | Audita estratégias de teste existentes, identifica gaps e sugere melhorias com base no Framework de Testes. Delega a `@test-engineer` / `@test-planner`. |
| `validate:qa-points:estimate` | Calcula QA Story Points pela fórmula do Framework de Testes (breakdown por perspectiva); integra ao task manager para atualizar os pontos. Delega a `@test-engineer` / `@test-planner`. |
| `validate:collab:three-amigos` | Facilita sessão Three Amigos (PO + Dev + QA) para refinement de stories: agenda, ata e checklist de outputs. Delega a `@test-engineer` / `@product-agent`. |
| `validate:collab:pair-testing` | Organiza sessão de pair testing multi-perspectiva (Dev+Dev, Dev+QA, QA+QA) para validação colaborativa de features. Delega a `@test-engineer` / `@test-planner`. |

## 🔗 Referências
- Agentes delegados: `@test-engineer`, `@test-planner`, `@product-agent`
- Comandos irmãos: `test/` (geração e execução de testes — unit/integration/e2e), `product:estimate` (story points de produto), `product:refine`
- Framework de Testes (KB): `docs/knowledge-base/`
