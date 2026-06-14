# 📋 Comandos .claude/

## 📑 Índice
- [Meta Commands](#meta-commands)
- [Product Workflow](#product-workflow)
- [Engineer Workflow](#engineer-workflow)
- [Git Workflow](#git-workflow)
- [Documentation](#documentation)
- [Validation](#validation)
- [Common Utilities](#common-utilities)

---

## Meta Commands

### `/meta/all-tools`
```typescript
command: '/meta/all-tools'
// Propósito: Documenta todas as ferramentas disponíveis no contexto do Claude Code
// Output: Gera docs/tools/ com mcps.md, agents.md, commands.md, rules.md
```

**Localização:** `.claude/commands/meta/all-tools.md`

**Funcionalidade:**
- 📊 Analisa todas as ferramentas no contexto
- 📁 Organiza por categoria
- 📝 Gera documentação detalhada
- 🔗 Cria índice e README

---

## Product Workflow

### `/product/feature`
```typescript
command: '/product/feature'
// Propósito: Inicia planejamento completo de nova feature
// Integração: ClickUp task creation, technical planning
```

**Localização:** `.claude/commands/product/feature.md`

### `/product/task`
```typescript
command: '/product/task'
// Propósito: Cria e gerencia task no ClickUp
// Integração: ClickUp MCP
```

**Localização:** `.claude/commands/product/task.md`

### `/product/spec`
```typescript
command: '/product/spec'
// Propósito: Cria especificação detalhada de produto
// Output: Documento de spec técnica e de negócio
```

**Localização:** `.claude/commands/product/spec.md`

### `/product/refine`
```typescript
command: '/product/refine'
// Propósito: Refina requisitos e especificações existentes
// Ação: Análise e melhoria de documentação
```

**Localização:** `.claude/commands/product/refine.md`

### `/product/collect`
```typescript
command: '/product/collect'
// Propósito: Coleta informações do usuário para feature/task
// Fluxo: Interactive questioning
```

**Localização:** `.claude/commands/product/collect.md`

### `/product/check`
```typescript
command: '/product/check'
// Propósito: Valida completude de informações de produto
// Validação: Checklists de requisitos
```

**Localização:** `.claude/commands/product/check.md`

### `/product/task-check`
```typescript
command: '/product/task-check'
// Propósito: Verifica status e qualidade de task no ClickUp
// Integração: ClickUp MCP
```

**Localização:** `.claude/commands/product/task-check.md`

### `/product/validate-task`
```typescript
command: '/product/validate-task'
// Propósito: Validação completa de task contra critérios
// Validação: Requirements, completeness, quality
```

**Localização:** `.claude/commands/product/validate-task.md`

### `/product/checklist-sync`
```typescript
command: '/product/checklist-sync'
// Propósito: Sincroniza checklists entre ClickUp e documentação
// Integração: Bidirectional sync
```

**Localização:** `.claude/commands/product/checklist-sync.md`

### `/product/light-arch`
```typescript
command: '/product/light-arch'
// Propósito: Cria visão arquitetural simplificada
// Output: Diagramas e documentação de alto nível
```

**Localização:** `.claude/commands/product/light-arch.md`

### `/product/warm-up`
```typescript
command: '/product/warm-up'
// Propósito: Carrega contexto de produto para sessão
// Ação: Pre-loads relevant documentation
```

**Localização:** `.claude/commands/product/warm-up.md`

---

## Engineer Workflow

### `/engineer/start`
```typescript
command: '/engineer/start'
// Propósito: Inicia sessão de desenvolvimento
// Ação: Setup workspace, load context, create branch
```

**Localização:** `.claude/commands/engineer/start.md`

### `/engineer/plan`
```typescript
command: '/engineer/plan'
// Propósito: Planeja implementação técnica
// Output: Task breakdown, technical approach
```

**Localização:** `.claude/commands/engineer/plan.md`

### `/engineer/work`
```typescript
command: '/engineer/work'
// Propósito: Modo de desenvolvimento ativo
// Ação: Code, test, commit cycle
```

**Localização:** `.claude/commands/engineer/work.md**

### `/engineer/pr`
```typescript
command: '/engineer/pr'
// Propósito: Prepara e cria Pull Request
// Ação: Code review, tests, documentation, PR creation
```

**Localização:** `.claude/commands/engineer/pr.md`

### `/engineer/pre-pr`
```typescript
command: '/engineer/pre-pr'
// Propósito: Validações antes de criar PR
// Validação: Linter, tests, documentation
```

**Localização:** `.claude/commands/engineer/pre-pr.md`

### `/engineer/pr-update`
```typescript
command: '/engineer/pr-update'
// Propósito: Atualiza PR com base em feedback
// Ação: Apply changes, update documentation
```

**Localização:** `.claude/commands/engineer/pr-update.md`

### `/engineer/bump`
```typescript
command: '/engineer/bump'
// Propósito: Incrementa versão do projeto
// Ação: Update version, changelog, tags
```

**Localização:** `.claude/commands/engineer/bump.md`

### `/engineer/hotfix`
```typescript
command: '/engineer/hotfix'
// Propósito: Workflow de hotfix emergencial
// Ação: Fast-track fix from production
```

**Localização:** `.claude/commands/engineer/hotfix.md`

### `/engineer/docs`
```typescript
command: '/engineer/docs'
// Propósito: Gera/atualiza documentação técnica
// Output: Technical docs, API docs, README
```

**Localização:** `.claude/commands/engineer/docs.md`

### `/engineer/validate-phase-sync`
```typescript
command: '/engineer/validate-phase-sync'
// Propósito: Valida sincronização entre fases
// Validação: Consistency checks
```

**Localização:** `.claude/commands/engineer/validate-phase-sync.md`

### `/engineer/warm-up`
```typescript
command: '/engineer/warm-up'
// Propósito: Carrega contexto técnico para sessão
// Ação: Load codebase context, recent changes
```

**Localização:** `.claude/commands/engineer/warm-up.md`

---

## Git Workflow

### `/git/init`
```typescript
command: '/git/init'
// Propósito: Inicializa repositório Git com estrutura padrão
// Ação: Git init, .gitignore, initial commit
```

**Localização:** `.claude/commands/git/init.md`

### `/git/sync`
```typescript
command: '/git/sync'
// Propósito: Sincroniza branch com remote
// Ação: Pull, rebase, push
```

**Localização:** `.claude/commands/git/sync.md`

### `/git/code-review`
```typescript
command: '/git/code-review'
// Propósito: Executa code review sistemático
// Ação: Analysis, suggestions, approval/changes requested
```

**Localização:** `.claude/commands/git/code-review.md`

### `/git/help`
```typescript
command: '/git/help'
// Propósito: Ajuda com comandos e workflows Git
// Output: Command reference, best practices
```

**Localização:** `.claude/commands/git/help.md`

### Feature Workflow

#### `/git:flow feature start`
```typescript
command: '/git:flow feature start'
// Propósito: Inicia nova feature branch
// Ação: Create branch from develop, setup tracking
```

**Localização:** `.claude/commands/git/flow.md`

#### `/git:flow feature publish`
```typescript
command: '/git:flow feature publish'
// Propósito: Publica feature branch para remote
// Ação: Push branch, setup tracking
```

**Localização:** `.claude/commands/git/flow.md`

#### `/git:flow feature finish`
```typescript
command: '/git:flow feature finish'
// Propósito: Finaliza feature branch
// Ação: Merge to develop, cleanup, close task
```

**Localização:** `.claude/commands/git/flow.md`

### Release Workflow

#### `/git:flow release start`
```typescript
command: '/git:flow release start'
// Propósito: Inicia release branch
// Ação: Create release branch, version bump
```

**Localização:** `.claude/commands/git/flow.md`

#### `/git:flow release finish`
```typescript
command: '/git:flow release finish'
// Propósito: Finaliza release
// Ação: Merge to main, tag, deploy
```

**Localização:** `.claude/commands/git/flow.md`

### Hotfix Workflow

#### `/git:flow hotfix start`
```typescript
command: '/git:flow hotfix start'
// Propósito: Inicia hotfix de produção
// Ação: Branch from main, emergency setup
```

**Localização:** `.claude/commands/git/flow.md`

#### `/git:flow hotfix finish`
```typescript
command: '/git:flow hotfix finish'
// Propósito: Finaliza hotfix
// Ação: Merge to main and develop, tag, deploy
```

**Localização:** `.claude/commands/git/flow.md`

---

## Documentation

### `/docs/build-business-docs`
```typescript
command: '/docs/build-business-docs'
// Propósito: Gera documentação de negócio
// Output: Business specs, requirements docs
```

**Localização:** `.claude/commands/docs/build-business-docs.md`

### `/docs/build-tech-docs`
```typescript
command: '/docs/build-tech-docs'
// Propósito: Gera documentação técnica
// Output: Architecture, API docs, technical specs
```

**Localização:** `.claude/commands/docs/build-tech-docs.md`

### `/docs/build-compliance-docs`
```typescript
command: '/docs/build-compliance-docs'
// Propósito: Gera documentação de compliance
// Output: Security, privacy, regulatory docs
```

**Localização:** `.claude/commands/docs/build-compliance-docs.md`

### `/docs/build-index`
```typescript
command: '/docs/build-index'
// Propósito: Cria índice de toda documentação
// Output: Central documentation index
```

**Localização:** `.claude/commands/docs/build-index.md`

### `/docs/docs-health`
```typescript
command: '/docs/docs-health'
// Propósito: Analisa saúde da documentação
// Validação: Completeness, accuracy, freshness
```

**Localização:** `.claude/commands/docs/docs-health.md`

### `/docs/reverse-consolidate`
```typescript
command: '/docs/reverse-consolidate'
// Propósito: Consolida documentação espalhada
// Ação: Merge, organize, deduplicate
```

**Localização:** `.claude/commands/docs/reverse-consolidate.md`

### `/docs/refine-vision`
```typescript
command: '/docs/refine-vision'
// Propósito: Refina documento de visão do projeto
// Ação: Update vision, goals, roadmap
```

**Localização:** `.claude/commands/docs/refine-vision.md`

### `/docs/sync-sessions`
```typescript
command: '/docs/sync-sessions'
// Propósito: Sincroniza documentação de sessões
// Ação: Update session logs, learnings
```

**Localização:** `.claude/commands/docs/sync-sessions.md`

### `/docs/validate-docs`
```typescript
command: '/docs/validate-docs'
// Propósito: Valida qualidade da documentação
// Validação: Links, formatting, completeness
```

**Localização:** `.claude/commands/docs/validate-docs.md`

### `/docs/help`
```typescript
command: '/docs/help'
// Propósito: Ajuda com comandos de documentação
// Output: Documentation command reference
```

**Localização:** `.claude/commands/docs/help.md`

---

## Validation

### `/validate/workflow`
```typescript
command: '/validate/workflow'
// Propósito: Valida conformidade com workflow
// Validação: Process compliance, gate checks
```

**Localização:** `.claude/commands/validate/workflow.md`

---

## Common Utilities

### `/warm-up`
```typescript
command: '/warm-up'
// Propósito: Carrega contexto geral para sessão
// Ação: Load project context, recent activity
```

**Localização:** `.claude/commands/warm-up.md`

### `/all-tools`
```typescript
command: '/all-tools'
// Propósito: Alias para /meta/all-tools
// Ver: /meta/all-tools
```

**Localização:** `.claude/commands/all-tools.md`

### Common Templates

#### Business Context Template
```typescript
template: 'business-context-template'
// Propósito: Template para contexto de negócio
// Uso: Base para documentação de requisitos
```

**Localização:** `.claude/commands/common/templates/business-context-template.md`

#### Technical Context Template
```typescript
template: 'technical-context-template'
// Propósito: Template para contexto técnico
// Uso: Base para documentação técnica
```

**Localização:** `.claude/commands/common/templates/technical-context-template.md`

### Common Prompts

#### Technical Prompts
```typescript
prompts: 'technical_prompts'
// Propósito: Prompts técnicos reutilizáveis
// Uso: Code analysis, architecture, reviews
```

**Localização:** `.claude/commands/common/prompts/technical.md`

---

## 🎯 Categorização por Fase

### 1️⃣ Discovery & Planning
- `/product/feature`
- `/product/spec`
- `/product/refine`
- `/product/collect`

### 2️⃣ Development
- `/engineer/start`
- `/engineer/plan`
- `/engineer/work`
- `/git:flow feature start`

### 3️⃣ Testing & Review
- `/engineer/pre-pr`
- `/git/code-review`
- `/product/validate-task`

### 4️⃣ Integration
- `/engineer/pr`
- `/git:flow feature finish`
- `/git/sync`

### 5️⃣ Release
- `/git:flow release start`
- `/engineer/bump`
- `/git:flow release finish`

### 🚨 Emergency
- `/engineer/hotfix`
- `/git:flow hotfix start`
- `/git:flow hotfix finish`

### 📚 Documentation
- `/docs/*` (todos os comandos de docs)
- `/engineer/docs`

### ✅ Validation
- `/validate/workflow`
- `/product/check`
- `/engineer/validate-phase-sync`

---

## 💡 Padrões de Uso

### Workflow Completo de Feature
```bash
1. /product/feature          # Planejar feature
2. /engineer/start           # Iniciar desenvolvimento
3. /git:flow feature start        # Criar branch
4. /engineer/work            # Desenvolver
5. /engineer/pre-pr          # Validar
6. /engineer/pr              # Criar PR
7. /git:flow feature finish       # Merge e cleanup
```

### Workflow de Hotfix
```bash
1. /git:flow hotfix start         # Criar hotfix branch
2. /engineer/work            # Fix rápido
3. /engineer/pr              # PR emergencial
4. /git:flow hotfix finish        # Deploy urgente
```

### Workflow de Documentação
```bash
1. /docs/build-tech-docs     # Docs técnicas
2. /docs/build-business-docs # Docs de negócio
3. /docs/build-index         # Índice geral
4. /docs/validate-docs       # Validar
5. /docs/docs-health         # Health check
```

---

## 📊 Estatísticas

| Categoria | Comandos | Mais Usado |
|-----------|----------|------------|
| **Product** | 10 | `/product/feature` |
| **Engineer** | 11 | `/engineer/work` |
| **Git** | 11 | `/git:flow feature start` |
| **Docs** | 9 | `/docs/build-tech-docs` |
| **Validation** | 1 | `/validate/workflow` |
| **Common** | 3 | `/warm-up` |
| **Meta** | 1 | `/meta/all-tools` |

**Total:** 46 comandos organizados

---

## 🔗 Recursos Relacionados
- [Ferramentas MCP](./mcps.md)
- [Agentes Especializados](./agents.md)
- [Workflows](./workflows.md)
- [Regras do Workspace](./rules.md)

