# 🧪 Agentes `testing/` — qualidade e estratégia de testes

Agentes especializados em **testes e qualidade** do Onion: definem estratégia multi-perspectiva (White/Grey/Black-box), planejam cobertura e implementam testes que verificam comportamento real. Use ao desenhar a estratégia de QA, identificar testes ausentes ou escrever testes unitários práticos.

## Agentes

| Agente | Especialidade | Quando usar |
|--------|---------------|-------------|
| [`@test-agent`](test-agent.md) | Estratégia completa de testes e QA (White/Black/Grey-box, QA Story Points, pipelines) | Criar estratégias de teste, montar pipelines automatizados e resolver problemas de qualidade |
| [`@test-planner`](test-planner.md) | Planejamento e cobertura de testes para análise sistemática | Identificar testes ausentes e recomendar a estratégia de testing de um código |
| [`@test-engineer`](test-engineer.md) | Testes unitários práticos com verificação de comportamento real | Implementar testes e verificar a qualidade do código entregue |

## 🔗 Relacionados
- Comandos de geração/execução: [`/test:unit`](../../commands/test/unit.md), [`/test:integration`](../../commands/test/integration.md), [`/test:e2e`](../../commands/test/e2e.md)
- Comandos de estratégia e QA: [`/validate:test-strategy:create`](../../commands/validate/test-strategy/create.md), [`/validate:test-strategy:analyze`](../../commands/validate/test-strategy/analyze.md), [`/validate:qa-points:estimate`](../../commands/validate/qa-points/estimate.md)
- Agente de revisão: [`@code-reviewer`](../review/code-reviewer.md)
- Framework de Testes: [`docs/knowledge-base/`](../../../docs/knowledge-base/)
