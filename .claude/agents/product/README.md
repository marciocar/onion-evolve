# 📋 Agentes `product/` — estratégia, descoberta e decomposição

Agentes da **dimensão de produto** do Onion: cobrem a descoberta (dor, reuniões, branding), a estratégia (gestão de produto, narrativa) e a operacionalização (decomposição de tasks, estimativa). Consumidos pelos comandos `/product:*`, que delegam a esses especialistas.

## Agentes

| Agente | Especialidade | Quando usar |
|--------|---------------|-------------|
| [`@product-agent`](product-agent.md) | Gestão estratégica de produto AI e coordenação de iniciativas | Roadmap, priorização e especificação de funcionalidades em qualquer task manager. |
| [`@task-specialist`](task-specialist.md) | Decomposição agnóstica em tasks/subtasks/action items | Quebrar requisitos em estrutura hierárquica (ClickUp, Jira, Asana, Linear). |
| [`@story-points-framework-specialist`](story-points-framework-specialist.md) | Estimativas ágeis via Framework de Story Points | Estimar tarefas, quebrar épicos e calibrar velocity do time. |
| [`@pain-price-specialist`](pain-price-specialist.md) | Análise de dor do cliente e precificação por outcome | Identificar dores, oportunidades de valor e precificação (JTBD, Value Proposition Canvas). |
| [`@branding-positioning-specialist`](branding-positioning-specialist.md) | Branding e posicionamento estratégico de marca | Brand positioning, identidade, guidelines e análise competitiva. |
| [`@storytelling-business-specialist`](storytelling-business-specialist.md) | Storytelling empresarial — dados em narrativa | Pitches, case studies e reports executivos. |
| [`@presentation-orchestrator`](presentation-orchestrator.md) | Orquestração de apresentações (storytelling + diagramas + geração) | Criar apresentações completas coordenando narrativa, Mermaid e Gamma. |
| [`@extract-meeting-specialist`](extract-meeting-specialist.md) | Framework EXTRACT — transcrição em conhecimento | Transformar transcrições e atas brutas em artefatos estruturados. |
| [`@meeting-consolidator`](meeting-consolidator.md) | Consolidação e síntese de múltiplas reuniões | Divergir/convergir várias reuniões em insights e pontos de atenção. |

## 🔗 Relacionados

- Comandos que delegam a estes agentes: [`/product:*`](../../commands/product/README.md) — ex.: `/product:task`, `/product:feature`, `/product:spec`, `/product:estimate`, `/product:analyze-pain-price`, `/product:branding`, `/product:presentation`, `/product:extract-meeting`, `/product:consolidate-meetings`
- Especialistas de task manager (operação técnica do provider): `@jira-specialist`, `@clickup-specialist` em [`agents/development/`](../development/)
- Análise de mercado / pesquisa: `@research-agent` em [`agents/research/`](../research/)
- KB de produto: [`docs/knowledge-base/`](../../../docs/knowledge-base/) — ex.: `concepts/meeting-transcription-to-knowledge-base.md`
- Contexto de negócio (base de decisão): [`docs/business-context/`](../../../docs/business-context/)
