# ⚙️ Agentes `development/` — especialistas técnicos

Agentes especialistas de execução técnica do Onion: backend, frontend, banco, monorepo, integrações de SDK/API (task managers, Gamma, Runflow, Whisper, ZEN), documentação de arquitetura (C4/Mermaid) e a vertical de design. São os "fazedores" acionados pelos comandos `/engineer:*`, `/docs:*`, `/product:*` e `/design:*` quando o trabalho exige conhecimento profundo de uma stack ou provider.

## Agentes

### Backend, frontend e dados

| Agente | Especialidade | Quando usar |
|--------|---------------|-------------|
| [`@nodejs-specialist`](nodejs-specialist.md) | Backend Node.js/TypeScript com PNPM e performance | APIs complexas, configuração backend, otimização Node.js |
| [`@react-developer`](react-developer.md) | React moderno com shadcn/ui, TypeScript, component-first | Componentes UI, estado complexo, frontend React |
| [`@postgres-specialist`](postgres-specialist.md) | PostgreSQL 17 — triggers, functions, schema, performance | Design de banco, migrations, otimização de queries |

### Monorepo NX

| Agente | Especialidade | Quando usar |
|--------|---------------|-------------|
| [`@nx-monorepo-specialist`](nx-monorepo-specialist.md) | NX Monorepo — libs/apps, estrutura enterprise | Arquitetura tier/scope/type, manutenção de monorepos NX |
| [`@nx-migration-specialist`](nx-migration-specialist.md) | Migração segura de NX (v19+ → v21+) | Resolver breaking changes, validar workspace, upgrades NX |

### Documentação de arquitetura

| Agente | Especialidade | Quando usar |
|--------|---------------|-------------|
| [`@system-documentation-orchestrator`](system-documentation-orchestrator.md) | Orquestra `@mermaid-specialist` + `@c4-architecture-specialist` | Documentação completa de arquitetura e ambiente (NX) |
| [`@c4-architecture-specialist`](c4-architecture-specialist.md) | C4 Model (Context/Containers/Components) com Mermaid | Análise e diagramas de arquitetura TS/JS |
| [`@c4-documentation-specialist`](c4-documentation-specialist.md) | Documentação textual C4 (Context/Container/Component/ADRs) | Docs estruturada complementando os diagramas C4 |
| [`@mermaid-specialist`](mermaid-specialist.md) | Diagramas Mermaid para Markdown (GitHub, IDEs, Live Editor) | Diagramas em documentação, arquitetura e Markdown renderizado |
| [`@docs-reverse-engineer`](docs-reverse-engineer.md) | Engenharia reversa — análise estrutural e docs | Detecção de stack e docs consolidada de qualquer projeto |

### Integrações de SDK / API

| Agente | Especialidade | Quando usar |
|--------|---------------|-------------|
| [`@jira-specialist`](jira-specialist.md) | Jira (Cloud e Server/DC) — REST v3/v2, JQL, ADF, transitions, bulk | Operações técnicas Jira, queries JQL complexas, integrações |
| [`@clickup-specialist`](clickup-specialist.md) | ClickUp (API-first; MCP opcional) — automações e bulk | Operações técnicas ClickUp, bulk operations, workflows |
| [`@gamma-api-specialist`](gamma-api-specialist.md) | Gamma.App API — apresentações e conteúdo com IA | Integrações técnicas e automações com Gamma |
| [`@runflow-specialist`](runflow-specialist.md) | Runflow SDK — agentes IA, workflows, RAG, integrações | Desenvolvimento via Runflow SDK |
| [`@whisper-specialist`](whisper-specialist.md) | Whisper (OpenAI) — transcrição de áudio multi-plataforma | Transcrever áudio e processar fala em projetos locais |
| [`@zen-engine-specialist`](zen-engine-specialist.md) | ZEN Engine / JDM (GoRules) — regras de negócio | Criar/validar JDM, Decision Tables, integração projeto de gamificação |

### Plataforma e segurança

| Agente | Especialidade | Quando usar |
|--------|---------------|-------------|
| [`@claude-code-specialist`](claude-code-specialist.md) | Claude Code — config, hooks, MCP, subagents, troubleshooting | Resolver problemas de ambiente/workspace e maximizar produtividade |
| [`@linux-security-specialist`](linux-security-specialist.md) | Segurança Linux — hardening, auditoria, resposta a incidentes | Firewall, SELinux/AppArmor, forense, conformidade de sistemas |

### Vertical de design

| Agente | Especialidade | Quando usar |
|--------|---------------|-------------|
| [`@design-system-specialist`](design-system-specialist.md) | Design system técnico — tokens W3C/DTCG → CSS/Tailwind/shadcn, WCAG | Materializar tokens em tema/componentes, validar contraste |
| [`@brand-generator`](brand-generator.md) | Gerador divergente de identidade visual (W3C/DTCG) | Orquestração de `/design:generate` — uma candidata por invocação |

## 🔗 Relacionados

- Comandos que delegam a estes agentes: [`/engineer:*`](../../commands/engineer/README.md), [`/docs:*`](../../commands/docs/README.md), [`/product:*`](../../commands/product/README.md), [`/design:*`](../../commands/design/README.md)
- Agentes irmãos: [`review/`](../review/) (`@code-reviewer`), [`testing/`](../testing/) (`@test-engineer`), [`product/`](../product/) (`@product-agent`, `@task-specialist`)
- Abstrações: Task Manager (`.claude/utils/task-manager/`) e Forge (`.claude/utils/forge/`) — adapters SDAAL que os specialists de provider servem
- KBs: [`docs/knowledge-base/`](../../../docs/knowledge-base/) · Inventário canônico: [`docs/onion/inventory.md`](../../../docs/onion/inventory.md)
