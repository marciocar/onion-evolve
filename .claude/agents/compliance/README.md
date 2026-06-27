# 🛡️ Agentes `compliance/` — frameworks de governança

Agentes especialistas da dimensão **compliance/governança** do Onion. Cobrem frameworks regulatórios e de gestão (ISO 27001, ISO 22301, SOC2, PMBOK) para produzir documentação de conformidade como spec-as-code. Acione-os para gerar políticas, avaliações de risco, controles e planos de continuidade — orquestrados por `@security-information-master`, que detecta o framework aplicável e delega.

## Agentes

| Agente | Especialidade | Quando usar |
|--------|---------------|-------------|
| [`@security-information-master`](security-information-master.md) | Orquestrador de compliance — detecta frameworks (ISO 27001, ISO 22301, PMBOK, SOC2) e delega | Ponto de entrada da dimensão: análise de requisitos e coordenação dos especialistas |
| [`@iso-27001-specialist`](iso-27001-specialist.md) | ISO/IEC 27001:2022 (ISMS/SGSI) | Política de segurança, risk assessment, controle de acesso, incident response |
| [`@iso-22301-specialist`](iso-22301-specialist.md) | ISO 22301:2019 (BCMS) — continuidade de negócios | Disaster recovery, crisis management, BCP/DRP, RTOs/RPOs, testes de resiliência |
| [`@soc2-specialist`](soc2-specialist.md) | SOC2 Type II (AICPA Trust Services Criteria) | Controles de segurança/disponibilidade/confidencialidade e coleta de evidências |
| [`@pmbok-specialist`](pmbok-specialist.md) | PMBOK Guide 7th Edition — governança de projetos | Change, quality, stakeholder e risk management |

## 🔗 Relacionados
- Comando que aciona estes agentes: [`/docs:build-compliance-docs`](../../commands/docs/build-compliance-docs.md) — gera a arquitetura em `docs/compliance-context/`
- Validação arquitetural: [`@metaspec-gate-keeper`](../meta/metaspec-gate-keeper.md)
- Gestão de risco no lado de produto: [`@product-agent`](../product/product-agent.md)
- Template de contexto: `common:templates:compliance-context-template`
