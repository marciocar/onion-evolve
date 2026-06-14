# 🤖 Agentes Especializados

## 📑 Índice
- [Gestão de Produto](#gestão-de-produto)
- [Desenvolvimento](#desenvolvimento)
- [Qualidade e Review](#qualidade-e-review)
- [Compliance e Meta](#compliance-e-meta)
- [Pesquisa e Dados](#pesquisa-e-dados)
- [Deployment](#deployment)

---

## Gestão de Produto

### `@product-agent`
```typescript
agent: 'product-agent'
// Propósito: Gestor estratégico de produto - planejamento, roadmap, integração ClickUp
// Especialidades: Product strategy, backlog management, stakeholder communication
// Quando usar: Planejamento de features, priorização, gestão de tasks no ClickUp
```

**Capacidades:**
- 📋 Criação e gestão de tasks no ClickUp
- 🎯 Definição de roadmap e prioridades
- 📊 Análise de métricas de produto
- 🔄 Sincronização entre desenvolvimento e negócio
- 📝 Documentação de requisitos

**Workflows:**
- `/product/plan-feature` - Planeja nova feature
- `/product/review-backlog` - Revisa backlog
- `/product/update-roadmap` - Atualiza roadmap

---

## Desenvolvimento

### `@react-developer`
```typescript
agent: 'react-developer'
// Propósito: Especialista em desenvolvimento React/Next.js
// Especialidades: React, TypeScript, Next.js, TailwindCSS, hooks, performance
// Quando usar: Desenvolvimento de componentes, features React, otimizações frontend
```

**Capacidades:**
- ⚛️ Componentes React modernos (hooks, context)
- 🎨 Estilização com TailwindCSS
- 🚀 Otimização de performance
- 📱 Responsive design
- ♿ Acessibilidade (a11y)

### `@python-developer`
```typescript
agent: 'python-developer'
// Propósito: Especialista em desenvolvimento Python
// Especialidades: Python 3.x, FastAPI, Django, async/await, data processing
// Quando usar: Backend Python, APIs, scripts, processamento de dados
```

**Capacidades:**
- 🐍 Python moderno (3.10+)
- 🚀 APIs com FastAPI/Django
- 📊 Processamento de dados
- 🔄 Programação assíncrona
- 🧪 Testes com pytest

---

## Qualidade e Review

### `@code-reviewer`
```typescript
agent: 'code-reviewer'
// Propósito: Revisor de código - qualidade, padrões, best practices
// Especialidades: Code review, refactoring, performance analysis
// Quando usar: Review de PRs, análise de qualidade, sugestões de melhorias
```

**Capacidades:**
- 🔍 Análise de qualidade de código
- 📐 Verificação de padrões
- 🎯 Sugestões de refactoring
- 🐛 Identificação de bugs potenciais
- 📊 Análise de complexidade

### `@branch-code-reviewer`
```typescript
agent: 'branch-code-reviewer'
// Propósito: Revisor especializado em mudanças de branch
// Especialidades: Git diff analysis, branch comparison, merge conflicts
// Quando usar: Review de branches antes de merge, análise de conflitos
```

**Capacidades:**
- 🌿 Análise de diff entre branches
- 🔀 Detecção de conflitos
- 📝 Sugestões de merge
- 🎯 Foco em mudanças específicas

### `@test-engineer`
```typescript
agent: 'test-engineer'
// Propósito: Engenheiro de testes - strategy, implementation, coverage
// Especialidades: Unit tests, integration tests, E2E, TDD
// Quando usar: Criação de testes, estratégia de testing, análise de cobertura
```

**Capacidades:**
- 🧪 Testes unitários e integração
- 🎭 Testes E2E (Playwright, Cypress)
- 📊 Análise de cobertura
- 🔄 TDD e BDD
- 🐛 Testes de regressão

### `@test-planner`
```typescript
agent: 'test-planner'
// Propósito: Planejador de estratégia de testes
// Especialidades: Test planning, test cases, QA strategy
// Quando usar: Planejamento de testes para features, definição de casos de teste
```

**Capacidades:**
- 📋 Planos de teste
- 🎯 Casos de teste
- 📊 Estratégia de QA
- 📝 Documentação de testes

### `@branch-test-planner`
```typescript
agent: 'branch-test-planner'
// Propósito: Planejador de testes específicos para branch
// Especialidades: Branch-specific testing, regression testing
// Quando usar: Planejamento de testes para mudanças específicas de branch
```

---

## Compliance e Meta

### `@metaspec-gate-keeper`
```typescript
agent: 'metaspec-gate-keeper'
// Propósito: Guardian da arquitetura - valida mudanças contra metaspec
// Especialidades: Architecture validation, metaspec compliance, design patterns
// Quando usar: Validação de mudanças arquiteturais, review de design decisions
```

**Capacidades:**
- 🏛️ Validação arquitetural
- 📐 Conformidade com metaspec
- 🎯 Design patterns
- 🔒 Enforcement de regras
- 📊 Análise de impacto

### `@branch-metaspec-checker`
```typescript
agent: 'branch-metaspec-checker'
// Propósito: Verificador de metaspec para branches
// Especialidades: Branch-level architecture validation
// Quando usar: Verificação de conformidade arquitetural em branches
```

---

## Pesquisa e Dados

### `@research-agent`
```typescript
agent: 'research-agent'
// Propósito: Pesquisador - busca informações, analisa documentação, web search
// Especialidades: Information retrieval, documentation analysis, web research
// Quando usar: Pesquisa de tecnologias, análise de docs, busca de soluções
```

**Capacidades:**
- 🔍 Web search
- 📚 Análise de documentação
- 🎯 Pesquisa de best practices
- 📊 Comparação de tecnologias
- 💡 Recomendações baseadas em pesquisa

### `@data-analyst`
```typescript
agent: 'data-analyst'
// Propósito: Analista de dados - análise, visualização, insights
// Especialidades: Data analysis, visualization, metrics, reporting
// Quando usar: Análise de métricas, geração de relatórios, insights de dados
```

**Capacidades:**
- 📊 Análise de dados
- 📈 Visualizações
- 🎯 KPIs e métricas
- 📝 Relatórios
- 💡 Insights e recomendações

---

## Deployment

### `@deployment-specialist`
```typescript
agent: 'deployment-specialist'
// Propósito: Especialista em deployment - CI/CD, infrastructure, releases
// Especialidades: Docker, Kubernetes, CI/CD pipelines, cloud platforms
// Quando usar: Setup de CI/CD, deployment configurations, release management
```

**Capacidades:**
- 🚀 Configuração de CI/CD
- 🐳 Containerização (Docker)
- ☸️ Orquestração (Kubernetes)
- ☁️ Cloud platforms (AWS, GCP, Azure)
- 📦 Release management

---

## Especialistas Técnicos

### `@clickup-specialist`
```typescript
agent: 'clickup-specialist'
// Propósito: Especialista técnico em ClickUp MCP - otimizações, troubleshooting
// Especialidades: ClickUp API, MCP integration, automation, optimization
// Quando usar: Problemas técnicos com ClickUp, otimizações, automações complexas
```

**Capacidades:**
- 🔌 Integração ClickUp MCP
- ⚡ Otimizações de API
- 🐛 Troubleshooting
- 🤖 Automações avançadas
- 📊 Custom fields e workflows

### `@claude-code-specialist`
```typescript
agent: 'claude-code-specialist'
// Propósito: Especialista em Claude Code - configuração, troubleshooting, otimização
// Especialidades: Claude Code configuration, rules, commands, agents setup
// Quando usar: Problemas com Claude Code, configuração de agentes/comandos
```

**Capacidades:**
- ⚙️ Configuração do Claude Code
- 📋 Criação de comandos
- 🤖 Setup de agentes
- 🔧 Troubleshooting IDE
- ⚡ Otimizações de performance

---

## Documentação

### `@branch-documentation-writer`
```typescript
agent: 'branch-documentation-writer'
// Propósito: Escritor de documentação para branches
// Especialidades: Branch documentation, changelog, migration guides
// Quando usar: Documentação de mudanças em branches, changelogs
```

**Capacidades:**
- 📝 Documentação de branches
- 📋 Changelogs
- 🔄 Guias de migração
- 📊 Documentação técnica

---

## 🎯 Como Escolher o Agente Certo

### Por Tipo de Tarefa

| Tarefa | Agente Recomendado |
|--------|-------------------|
| Planejamento de feature | `@product-agent` |
| Desenvolvimento React | `@react-developer` |
| Backend Python | `@python-developer` |
| Review de código | `@code-reviewer` |
| Criação de testes | `@test-engineer` |
| Validação arquitetural | `@metaspec-gate-keeper` |
| Problemas ClickUp | `@clickup-specialist` |
| Problemas Claude Code | `@claude-code-specialist` |
| Pesquisa técnica | `@research-agent` |
| Deployment | `@deployment-specialist` |

### Por Fase do Desenvolvimento

```mermaid
graph LR
    A[Planning] -->|@product-agent| B[Development]
    B -->|@react-developer/@python-developer| C[Testing]
    C -->|@test-engineer| D[Review]
    D -->|@code-reviewer| E[Validation]
    E -->|@metaspec-gate-keeper| F[Deploy]
    F -->|@deployment-specialist| G[Production]
```

---

## 💡 Dicas de Uso

### Invocação
```markdown
@product-agent preciso planejar uma nova feature de autenticação
```

### Combinação de Agentes
```markdown
@product-agent crie a task no ClickUp
@react-developer implemente o componente
@test-engineer crie os testes
@code-reviewer revise o código
```

### Contexto Específico
```markdown
@clickup-specialist estou tendo erro ao criar task com custom fields
```

---

## 📚 Recursos Relacionados
- [Ferramentas MCP](./mcps.md)
- [Comandos .claude/](./commands.md)

