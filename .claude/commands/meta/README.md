# 🛠️ Comandos `meta/` — a fábrica do Onion

Comandos que **constroem, auditam, integram e co-evoluem o próprio Sistema Onion**. É a camada meta: cria os artefatos do framework (comandos, agentes, skills, abstrações, KBs), mantém a SSOT do inventário, audita o frescor do core e da documentação, configura integrações e orquestra a co-evolução core↔derivados (doc-bridge + federation). Use ao **evoluir o framework**, não ao desenvolver um produto.

## Comandos

### Criação de artefatos
| Comando | Finalidade |
|---------|-----------|
| [`/meta:create-command`](create-command.md) | Cria novos comandos Claude Code seguindo os padrões Onion. Delega a `@command-creator-specialist`. |
| [`/meta:create-agent`](create-agent.md) | Criação inteligente de agentes com análise completa do ecossistema. Delega a `@agent-creator-specialist`. |
| [`/meta:create-agent-express`](create-agent-express.md) | Caminho RÁPIDO para criar agente (mínimo de prompts, sem descoberta profunda) — vs o `create-agent` completo. |
| [`/meta:create-skill`](create-skill.md) | Cria/valida/otimiza/migra Agent Skills em `.claude/skills/`. Delega a `@agent-skills-specialist`. |
| [`/meta:create-abstraction`](create-abstraction.md) | Gera camada de abstração agnóstica de provedor seguindo o padrão SDAAL (Task Manager, Notification, Storage). |
| [`/meta:create-knowledge-base`](create-knowledge-base.md) | Gera KB estruturada em `docs/knowledge-base/<category>/`. Delega a `@research-agent`. |

### Inventário, auditoria e validação
| Comando | Finalidade |
|---------|-----------|
| [`/meta:inventory`](inventory.md) | Regenera o inventário canônico (comandos/agentes/skills/KBs) do filesystem — SSOT que o lint protege. |
| [`/meta:evolve`](evolve.md) | Auto-auditoria do core via orquestração (fan-out-and-synthesize) → backlog priorizado de modernização. Read-only. |
| [`/meta:kb-freshness`](kb-freshness.md) | Audita o frescor de cada KB contra o fluxo atual do Onion (via `onion-orchestration`); veredito CURRENT/STALE/HISTORICAL. |
| [`/meta:context-freshness`](context-freshness.md) | Audita o frescor dos contextos de domínio (business/technical/compliance) — fase *Manage* do ciclo de vida. |
| [`/meta:metaspec-validate`](metaspec-validate.md) | Valida um artefato/decisão contra as metaspecs vigentes. Aplica a constituição do `@metaspec-gate-keeper`. |
| [`/meta:analyze-complex-problem`](analyze-complex-problem.md) | Análise estruturada de problemas complexos (críticos, migrações, arquitetura, performance) com template oficial. |

### Orquestração e descoberta
| Comando | Finalidade |
|---------|-----------|
| [`/meta:orchestrate`](orchestrate.md) | Orquestra workers em paralelo (fan-out/fan-in) via a ferramenta nativa Workflow. |
| [`/meta:all-tools`](all-tools.md) | Apresenta sob demanda as ferramentas do contexto atual (nativas + MCP); defere ao inventário para artefatos Onion. |

### Adoção e integração
| Comando | Finalidade |
|---------|-----------|
| [`/meta:adopt`](adopt.md) | Adota um repo/pasta no Onion: instala o framework (durável) ou opera in-place (efêmero). Faseado e retomável. |
| [`/meta:setup-integration`](setup-integration.md) | Configura integrações (Task Managers, Gamma, etc) guiando a configuração segura de variáveis de ambiente. |
| [`/meta:setup-code-review`](setup-code-review.md) | Setup/validação/otimização de code review automático no CI (GitHub Actions). Delega a `@code-reviewer`. |

### Co-evolução (doc-bridge leve)
| Comando | Finalidade |
|---------|-----------|
| [`/meta:co-evolve`](co-evolve.md) | Orienta a sessão na co-evolução core↔derivados: detecta o papel do repo, lê o inbox, mostra a posição nos 3 fluxos. |
| [`/meta:co-announce`](co-announce.md) | **(core)** Gera anúncio downstream a partir do CHANGELOG, endereçado ao adotante; escreve na staging `outbox/`. Lado producer. |
| [`/meta:co-deliver`](co-deliver.md) | **(core)** Carteiro-local downstream: entrega anúncio do `outbox/` no `inbound/` de um adotante na mesma máquina. Entrega-sem-commit. |
| [`/meta:co-relay`](co-relay.md) | **(adotante)** Carteiro-local upstream: relaya um sinal do adotante no `inbox/` do core na mesma máquina. Entrega-sem-commit. |

### Federation (ledger de contratos)
| Comando | Finalidade |
|---------|-----------|
| [`/meta:federation-register`](federation-register.md) | Registra+valida um contrato (spec-as-code) localmente contra o ledger git. Átomo da Fase 1 (não anuncia). |
| [`/meta:federation-publish`](federation-publish.md) | Anuncia um bump de contrato aos consumers via CHANGELOG do ledger. Lado producer (Fase 2). |
| [`/meta:federation-check`](federation-check.md) | Lado consumer: valida contratos endereçados a este membro e emite o veredito `MemberExpertSchema`. Fail-safe (Fase 2). |
| [`/meta:federation-status`](federation-status.md) | Monitor read-only (Fase 3): saúde cross-repo — contract-drift + status de CI por membro via forge adapter. |
| [`/meta:federation-rollback`](federation-rollback.md) | Rollback Protocol guiado (Fase 3): pina versão anterior no ledger + guia reverts inversos consumers→producer. Human-gated. |

## 🔗 Referências
- **Skills de orquestração**: [`onion`](../../skills/onion/SKILL.md) (orquestrador mestre), [`onion-orchestration`](../../skills/onion-orchestration/SKILL.md) (orquestração), [`onion-patterns`](../../skills/onion-patterns/SKILL.md), [`onion-validation`](../../skills/onion-validation/SKILL.md)
- **Agentes que esta categoria aciona**: `@command-creator-specialist`, `@agent-creator-specialist`, `@agent-skills-specialist`, `@research-agent`, `@metaspec-gate-keeper`, `@code-reviewer`
- **Gate determinístico**: [`.claude/validation/`](../../validation/) (lint + selftest + inventory) — o dogfood mecânico que o CI roda
- **SSOT do inventário**: [`docs/onion/inventory.md`](../../../docs/onion/inventory.md) — gerada por `/meta:inventory`, nunca editada à mão
- **Padrão SDAAL**: [`docs/knowledge-base/concepts/specification-driven-ai-abstraction-layer.md`](../../../docs/knowledge-base/concepts/specification-driven-ai-abstraction-layer.md) — base do `create-abstraction` e da federation
- **Comandos irmãos**: [`/engineer:pre-pr`](../engineer/pre-pr.md) (validação pré-PR), [`/docs:build-index`](../docs/build-index.md) (índices de docs)
