---
title: Padrões C4, ADR e Templates de Documentação de Arquitetura
category: architectures
tags:
  - c4-model
  - adr
  - documentation
  - nx-monorepo
  - mermaid
  - templates
status: reference
date: "2026-06-02"
maintained_by: Sistema Onion
related:
  - .claude/agents/development/system-documentation-orchestrator.md
  - .claude/agents/development/c4-architecture-specialist.md
  - .claude/agents/development/mermaid-specialist.md
  - .claude/commands/docs/build-tech-docs.md
---

# Padrões C4, ADR e Templates de Documentação de Arquitetura

> Base de conhecimento de **referência** consumida pelo `@system-documentation-orchestrator`
> e agentes correlatos ao gerar documentação técnica de arquitetura. Centraliza templates,
> matrizes e padrões de delegação que antes viviam inline no agente orquestrador.

Esta KB reúne os blocos de referência reutilizáveis para produzir documentação de
arquitetura de qualidade em projetos complexos (foco em **NX Monorepos**): estrutura de
diretórios, templates narrativos, templates de delegação para sub-agentes, templates ADR
e checklists de qualidade. O agente orquestrador **lê estes templates** ao executar a
geração; o agente em si permanece enxuto, contendo apenas a lógica de orquestração.

---

## 1. Estrutura de Diretórios de Documentação

Estrutura padrão recomendada para `docs/architecture/`:

```
docs/architecture/
├── index.md                    # Navigation hub
├── README.md                   # Quick start
├── system-overview.md          # High-level overview
├── architecture/
│   ├── system-context.md       # System boundaries
│   ├── containers.md           # Major containers (apps)
│   ├── components.md           # Key components
│   └── tech-stack.md           # Technology choices
├── environment/
│   ├── development.md          # Dev environment setup
│   ├── staging.md              # Staging environment
│   ├── production.md           # Production architecture
│   └── infrastructure.md       # Infrastructure details
├── diagrams/
│   ├── c4-system-context.puml  # C4 level 1
│   ├── c4-containers.puml      # C4 level 2
│   ├── deployment-*.mmd        # Deployment diagrams
│   ├── sequence-*.mmd          # Sequence diagrams
│   └── flowchart-*.mmd         # Process flowcharts
├── guides/
│   ├── getting-started.md      # Onboarding guide
│   ├── development-workflow.md # Dev workflow
│   ├── deployment-guide.md     # How to deploy
│   └── troubleshooting.md      # Common issues
├── adrs/                       # Architecture Decision Records
│   ├── 001-nx-monorepo.md
│   ├── 002-tech-stack.md
│   └── template.md
└── references/
    ├── glossary.md             # Terms and definitions
    ├── resources.md            # External resources
    └── api-overview.md         # API catalog
```

---

## 2. Matriz de Priorização e Delegação

Mapa de qual documento delegar a qual ator, prioridade e estimativa:

| Documento | Prioridade | Delegação | Estimativa |
|-----------|------------|-----------|------------|
| System Overview | 🔴 CRÍTICO | Orquestrador (narrativo) | 30min |
| System Context Diagram | 🔴 CRÍTICO | @c4-architecture-specialist | 15min |
| Container Diagram | 🔴 CRÍTICO | @c4-architecture-specialist | 20min |
| Environment Setup | 🔴 CRÍTICO | Orquestrador (narrativo) | 45min |
| Deployment Diagrams | 🟡 ALTO | @mermaid-specialist | 30min |
| Component Diagrams | 🟡 ALTO | @c4-architecture-specialist | 30min |
| ADRs | 🟡 ALTO | Orquestrador (narrativo) | 20min/ADR |
| Sequence Diagrams | 🟢 MÉDIO | @mermaid-specialist | 15min/each |
| Troubleshooting | 🟢 MÉDIO | Orquestrador (narrativo) | 30min |

---

## 3. Templates Narrativos

### 3.1. System Overview (`system-overview.md`)

```markdown
# System Overview - [Project Name]

## Introdução

[Nome do Projeto] é um [tipo de sistema] construído como **NX Monorepo** que [propósito principal do sistema].

## Arquitetura High-Level

### Estrutura do Monorepo

Este projeto segue uma arquitetura de **monorepo organizado** com:

- **[X] Aplicações Deployáveis** (`apps/`): [descrição]
- **[Y] Bibliotecas Compartilhadas** (`libs/`): [descrição]
- **Organização por Tiers**: server, web, common

### Principais Componentes

#### 🚀 Aplicações

[Lista organizada de aplicações com breve descrição]

**Admin Systems**
- `apps/admin/api-admin/`: [descrição]
- `apps/admin/ui-admin/`: [descrição]

#### 📚 Bibliotecas

**Server Libraries** ([N] total)
- `libs/server/shared/`: [descrição]
- `libs/server/[domain]/`: [descrição]

**Web Libraries** ([M] total)
- `libs/web/shared/`: [descrição]
- `libs/web/[domain]/`: [descrição]

### Technology Stack

**Core Technologies:**
- **Monorepo**: NX [versão]
- **Runtime**: Node.js [versão]
- **Language**: TypeScript [versão]
- **Backend**: [Framework] [versão]
- **Frontend**: [Framework] [versão]
- **Database**: [Database] [versão]

## Diagramas

### System Context

> 📊 Ver diagrama detalhado em: [diagrams/c4-system-context.puml](diagrams/c4-system-context.puml)

### Container Architecture

> 📊 Ver diagrama detalhado em: [diagrams/c4-containers.puml](diagrams/c4-containers.puml)

## Próximos Passos

- 📖 [Environment Setup](environment/development.md) - Configure seu ambiente
- 🏗️ [Architecture Details](architecture/) - Aprofunde-se na arquitetura
- 🚀 [Deployment Guide](guides/deployment-guide.md) - Como fazer deploy
- 📝 [ADRs](adrs/) - Decisões arquiteturais importantes
```

### 3.2. Development Environment Setup (`environment/development.md`)

```markdown
# Development Environment Setup

## Prerequisites

### Required Software

- **Node.js**: v[X.Y.Z] ou superior
- **pnpm**: v[X.Y] ou superior (package manager)
- **Git**: v[X.Y] ou superior

### Optional but Recommended

- **VS Code** com extensões: NX Console, TypeScript, ESLint, Prettier
- **Docker**: Para serviços locais

## Installation Steps

### 1. Clone the Repository

​```bash
git clone [repo-url]
cd [project-name]
​```

### 2. Install Dependencies

​```bash
pnpm install
​```

### 3. Environment Variables

​```bash
cp .env.example .env.local
vim .env.local
​```

**Required Variables:**
- `DATABASE_URL`: [descrição]
- `API_KEY`: [descrição]

### 4. Database Setup

​```bash
pnpm prisma:migrate
pnpm prisma:seed
​```

### 5. Start Development Servers

​```bash
pnpm dev                                                    # Todas as apps
pnpm nx serve [app-name]                                    # App específica
pnpm nx run-many --target=serve --projects=api-admin,ui-admin  # Várias apps
​```

## Verification

​```bash
pnpm nx --version
pnpm nx show projects
pnpm nx graph
​```

### Access Applications

- **Admin UI**: http://localhost:3000
- **Admin API**: http://localhost:3001

## Common Issues

### Issue 1: [Problema comum]
**Symptom**: [descrição] — **Solution**: [solução]

## Next Steps

- 📖 Development Workflow
- 🏗️ Project Structure
- 🧪 Running Tests
```

---

## 4. Templates de Delegação a Sub-Agentes

Formato genérico de delegação (sempre usar este formato ao acionar um especialista):

```markdown
---

📤 **DELEGAÇÃO PARA @[agente-nome]**

**Contexto**: [Breve contexto do projeto]
**Solicitação**: [O que você precisa]
**Especificações**:
- [Spec 1]
- [Spec 2]
**Formato de Output**: [Onde salvar, formato esperado]
**Deadline**: [Se aplicável]

---
```

### 4.1. Delegação para @c4-architecture-specialist

```markdown
📤 DELEGAÇÃO PARA @c4-architecture-specialist

Preciso de dois diagramas C4 para o projeto [Nome]:

**1. System Context Diagram (Level 1)**
- Sistema principal: [Nome do Sistema]
- Usuários externos: [Admin Users, End Users, etc]
- Sistemas externos: [Payment Gateway, Auth Provider, etc]
- Objetivo: Mostrar o sistema no contexto do mundo externo

**2. Container Diagram (Level 2)**
- Containers principais: [X] apps web (Next.js), [Y] APIs (Fastify/Express),
  [Z] Background Jobs, Database (PostgreSQL), Cache (Redis)
- Relacionamentos e comunicação entre containers
- Protocolos: REST, GraphQL, WebSocket, etc

Salvar em:
- `docs/architecture/diagrams/c4-system-context.puml`
- `docs/architecture/diagrams/c4-containers.puml`
```

### 4.2. Delegação para @mermaid-specialist

```markdown
📤 DELEGAÇÃO PARA @mermaid-specialist

Preciso dos seguintes diagramas Mermaid:

**1. Deployment Diagram - Development Environment**
- Docker containers, services rodando (APIs, UIs, Database), portas, hot reload
- Salvar em: `docs/architecture/diagrams/deployment-development.mmd`

**2. Deployment Diagram - Production Environment**
- Cloud provider, load balancers, application servers, database (com replicas),
  CDN, monitoring
- Salvar em: `docs/architecture/diagrams/deployment-production.mmd`

**3. Sequence Diagram - Authentication Flow**
- User → Frontend → API Gateway → Auth Service (Keycloak/Auth0)
- Token generation, validation e refresh token flow
- Salvar em: `docs/architecture/diagrams/sequence-auth-flow.mmd`

Garanta 100% compatibilidade GitHub e use sintaxe moderna.
```

### 4.3. Integração de Outputs

Após receber outputs dos agentes: **valide** (completos?), **integre** (referências na
narrativa), **conecte** (links entre docs) e **contextualize** (explicações ao redor dos
diagramas). Exemplo de integração de um diagrama na narrativa:

```markdown
## Arquitetura de Containers

Nossa arquitetura segue o modelo C4, organizada em containers lógicos que podem ser
deployados independentemente.

### Diagrama Detalhado

> 📊 **Container Diagram (C4 Level 2)**
>
> ![Container Diagram](diagrams/c4-containers.png)
>
> *Criado por: @c4-architecture-specialist*
> *Formato: PlantUML C4*
> *[Ver código fonte](diagrams/c4-containers.puml)*

### Detalhamento por Container

[Explicação detalhada de cada container...]
```

---

## 5. Templates ADR (Architecture Decision Records)

### 5.1. Template ADR (`adrs/template.md`)

```markdown
# ADR-[NUMBER]: [Short Title]

## Status
[Proposed | Accepted | Deprecated | Superseded by ADR-XXX]

## Context
[Describe the context and problem statement]

## Decision
[Describe the decision that was made]

## Consequences

### Positive
- [Benefit 1]
- [Benefit 2]

### Negative
- [Trade-off 1]
- [Trade-off 2]

## Alternatives Considered
- **Alternative 1**: [Description] — Pros: [...] / Cons: [...]
- **Alternative 2**: [Description] — Pros: [...] / Cons: [...]

## References
- [Link 1]
- [Link 2]
```

### 5.2. ADR Exemplo: NX Monorepo (`adrs/001-nx-monorepo-architecture.md`)

```markdown
# ADR-001: NX Monorepo Architecture

## Status
✅ **Accepted** ([Date])

## Context

[Nome do Projeto] precisa gerenciar múltiplas aplicações ([X] apps) e bibliotecas
compartilhadas ([Y] libs) com: desenvolvimento paralelo de múltiplas equipes, code
sharing extensivo, deploy independente por aplicação e consistência de tooling.

### Problema
Arquiteturas multi-repo causavam: duplicação de código, inconsistência entre projetos,
complexidade de versionamento e overhead de configuração.

## Decision

**Adotar NX Monorepo** como arquitetura principal.

### Configuração:
- **Workspace Root**: Configuração centralizada
- **Apps**: [X] aplicações deployáveis independentemente
- **Libs**: [Y]+ bibliotecas organizadas por tier (server/web/common)
- **Build System**: NX computation caching + affected builds

### Estrutura:
​```
[project-name]/
├── apps/        # Deployable applications
├── libs/        # Shared libraries
├── tools/       # Development utilities
└── nx.json      # NX configuration
​```

## Consequences

### ✅ Positive
- **Code Reuse**: ~80% código compartilhado entre apps
- **Atomic Changes**: Cross-cutting changes em single commit
- **Type Safety**: TypeScript end-to-end com path mappings
- **Build Performance**: NX affected builds (~70% reduction)
- **Developer Experience**: Tooling consistency, graph visualization
- **Refactoring**: Refactoring seguro cross-application

### ⚠️ Negative
- **Initial Complexity**: Learning curve para NX
- **Repository Size**: Single large repo vs multiple small repos
- **CI/CD Setup**: Requer configuração NX-aware
- **Monorepo Tooling**: Dependência do NX ecosystem

## Alternatives Considered

### **Multi-Repo**
- Pros: Isolamento completo, repos independentes
- Cons: Duplicação código, versionamento complexo, overhead
- Motivo da rejeição: Não escala para [X] apps + [Y] libs

### **Yarn Workspaces / pnpm Workspaces**
- Pros: Simples, sem tooling adicional
- Cons: Sem computation caching, sem dependency graph, builds lentos
- Motivo da rejeição: Falta recursos avançados de build optimization

### **Turborepo**
- Pros: Build caching, simples
- Cons: Menos features que NX, comunidade menor
- Motivo da rejeição: NX oferece mais features out-of-the-box

## References
- [NX Documentation](https://nx.dev/)
- Internal discussion: [Link to document/meeting notes]
```

---

## 6. Index de Navegação (`index.md`)

Template do hub de navegação da documentação:

```markdown
# Architecture Documentation - [Project Name]

> 📚 Documentação completa de arquitetura, ambiente e guias de desenvolvimento

## 🚀 Quick Start

**Novo no projeto?** Comece aqui:
1. 📖 [System Overview](system-overview.md)
2. 💻 [Development Setup](environment/development.md)
3. 🏗️ [Architecture](architecture/)
4. 🚀 [Deployment Guide](guides/deployment-guide.md)

## 📊 Architecture Documentation
- **[System Overview](system-overview.md)** - Visão geral e arquitetura high-level
- **[Tech Stack](architecture/tech-stack.md)** - Technologies e frameworks

### C4 Model Diagrams
- **[System Context](architecture/system-context.md)** - Level 1
- **[Containers](architecture/containers.md)** - Level 2
- **[Components](architecture/components.md)** - Level 3

## 🌐 Environment Documentation
- **[Development](environment/development.md)**
- **[Staging](environment/staging.md)**
- **[Production](environment/production.md)**
- **[Infrastructure](environment/infrastructure.md)**

## 📝 Architecture Decision Records (ADRs)
- **[ADR-001: NX Monorepo Architecture](adrs/001-nx-monorepo-architecture.md)**
- **[ADR-002: Technology Stack Selection](adrs/002-tech-stack-selection.md)**
- [📋 Ver todas as ADRs →](adrs/)

## 📐 Diagrams
- [System Context Diagram](diagrams/c4-system-context.puml) (C4 Level 1)
- [Container Diagram](diagrams/c4-containers.puml) (C4 Level 2)
- [Development / Staging / Production Environment](diagrams/)
- [Authentication Flow](diagrams/sequence-auth-flow.mmd)

## 📚 Guides
- **[Getting Started](guides/getting-started.md)**
- **[Development Workflow](guides/development-workflow.md)**
- **[Testing Guide](guides/testing.md)**
- **[Troubleshooting](guides/troubleshooting.md)**

## 🔍 References
- **[Glossary](references/glossary.md)**
- **[API Catalog](references/api-overview.md)**
- **[External Resources](references/resources.md)**

---

**Última atualização**: [Date] | **Mantido por**: [Team] | **Versão**: [Version]
```

---

## 7. Headers, Footers e Estilo Markdown

### 7.1. Header Padrão de Documento

```markdown
# [Título do Documento]

> [Breve descrição do propósito deste documento]

**Última atualização**: [YYYY-MM-DD]
**Mantido por**: [Equipe/Pessoa]
**Status**: [Draft | Review | Published]

---
```

### 7.2. Footer Padrão de Documento

```markdown
---

**Navegação**: [← Voltar](../index.md) | [Próximo: [Nome] →](link.md)

**Relacionados**:
- [Link para doc relacionado 1]
- [Link para doc relacionado 2]

---

*Documentação gerada por `@system-documentation-orchestrator`*
*Colaboração: @mermaid-specialist, @c4-architecture-specialist*
```

### 7.3. Convenções de Markdown

- **Hierarquia**: um único `# H1`; `## H2` para seções; `### H3` subseções; `#### H4` com moderação.
- **Visual aids**: `> 📊` blockquotes para destaques; emojis `⚠️ ✅ ❌` como status indicators.
- **Code blocks** sempre com syntax highlighting (` ```typescript `, ` ```bash `).

---

## 8. Checklist de Qualidade da Documentação

```markdown
### Completude
- [ ] System Overview criado
- [ ] System Context Diagram (C4 L1) criado
- [ ] Container Diagram (C4 L2) criado
- [ ] Environment Setup Guides completos (Dev, Staging, Prod)
- [ ] Pelo menos 2 ADRs documentados
- [ ] Index de navegação funcional
- [ ] README de entrada claro

### Qualidade
- [ ] Diagramas renderizam corretamente
- [ ] Links internos funcionam
- [ ] Markdown formatado corretamente
- [ ] Code blocks com syntax highlighting
- [ ] Exemplos práticos incluídos
- [ ] Contexto de negócio presente

### Navegação
- [ ] Index com links para todas as seções
- [ ] Breadcrumbs em páginas internas
- [ ] Estrutura de diretórios clara

### Manutenibilidade
- [ ] Data de última atualização presente
- [ ] Versionamento do sistema documentado
- [ ] Responsáveis pela manutenção identificados
- [ ] Templates para ADRs e novos docs
```

---

## Referências Relacionadas

- `@c4-architecture-specialist` — geração de diagramas C4 (níveis 1-3)
- `@mermaid-specialist` — diagramas Mermaid (deployment, sequence, flowchart)
- `@nx-monorepo-specialist` — estrutura de workspace NX
- `/docs/build-tech-docs` — geração de contexto técnico complementar
