# 🔍 Agentes `review/` — revisão e conformidade

Agentes de **revisão crítica** do Onion: avaliam código quanto a correção/manutenibilidade e políticas/processos quanto a conformidade corporativa. Acione-os antes de fechar um PR ou ao revisar artefatos de governança.

## Agentes

| Agente | Especialidade | Quando usar |
|--------|---------------|-------------|
| [`@code-reviewer`](code-reviewer.md) | Revisão de código focada em correção, manutenibilidade e detecção de bugs reais | Antes do PR ou em revisões práticas de código — melhorias acionáveis e caça a bugs |
| [`@corporate-compliance-specialist`](corporate-compliance-specialist.md) | Compliance corporativo: anticorrupção, PLD/KYC, ética e governança (Lei 12.846/2013) | Ao revisar políticas, analisar riscos ou produzir documentação de conformidade |

## 🔗 Relacionados
- Comando irmão: [`/engineer:pre-pr`](../../commands/engineer/pre-pr.md) — validação completa antes do PR (aciona `@code-reviewer`)
- Comando de compliance: [`/docs:build-compliance-docs`](../../commands/docs/build-compliance-docs.md) — arquitetura de compliance (aciona `@corporate-compliance-specialist`)
- Agentes correlatos de teste: [`@test-engineer`](../testing/) — par natural de `@code-reviewer` na qualidade
- Setup de review automático no CI: [`/meta:setup-code-review`](../../commands/meta/setup-code-review.md)
