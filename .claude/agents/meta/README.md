# 🛠️ Agentes `meta/` — a fábrica do Onion

Agentes que **constroem e governam o próprio Sistema Onion**: criam comandos, agentes e skills contextualizados, orquestram a navegação do framework e guardam a conformidade arquitetural. Acione-os ao evoluir o core ou ao precisar de orientação sobre por onde começar.

## Agentes

| Agente | Especialidade | Quando usar |
|--------|---------------|-------------|
| [`@onion`](onion.md) | Orquestrador master — navegação, recomendações e coordenação de workflows complexos | Ponto de entrada: "por onde começo?", qual comando/agente usar, coordenar fluxos multi-etapa |
| [`@agent-creator-specialist`](agent-creator-specialist.md) | Meta-arquitetura e design de agentes integrados ao ecossistema | Criar um novo agente especializado (via `/meta:create-agent` / `/meta:create-agent-express`) |
| [`@command-creator-specialist`](command-creator-specialist.md) | Criação de Claude Code Commands (.md) contextualizados | Criar um novo comando que siga os padrões do Onion (via `/meta:create-command`) |
| [`@agent-skills-specialist`](agent-skills-specialist.md) | Agent Skills (spec aberto agentskills.io + extensões nativas do Claude Code) | Criar, validar, otimizar ou avaliar skills em `.claude/skills/` ou `.agents/skills/` (via `/meta:create-skill`) |
| [`@metaspec-gate-keeper`](metaspec-gate-keeper.md) | Validação de conformidade arquitetural contra as metaspecs | Guardião do DNA: validar alinhamento com metaspecs e integridade de contexto antes do PR |

## 🔗 Relacionados
- Comandos que delegam a esta orquestração: [`/meta:create-agent`](../../commands/meta/create-agent.md), [`/meta:create-agent-express`](../../commands/meta/create-agent-express.md), [`/meta:create-command`](../../commands/meta/create-command.md), [`/meta:create-skill`](../../commands/meta/create-skill.md), [`/engineer:pre-pr`](../../commands/engineer/pre-pr.md) (aciona `@metaspec-gate-keeper`)
- Índice da categoria de comandos: [`meta/` commands](../../commands/meta/README.md)
- Skills do core: [`.claude/skills/`](../../skills/) (`onion`, `onion-patterns`, `onion-validation`, `language-standards`, `onion-orchestration`)
- Metaspecs (constituição L0): [`docs/meta-specs/`](../../../docs/meta-specs/)
- Inventário canônico: [`docs/onion/inventory.md`](../../../docs/onion/inventory.md)
