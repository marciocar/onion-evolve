# 🎯 Guia Completo de Comandos - Sistema Onion

## 📋 Índice

- [Visão Geral](#-visão-geral)
- [Comandos de Engenharia](#-comandos-de-engenharia)
- [Comandos de Produto](#-comandos-de-produto)
- [Comandos Git](#-comandos-git)
- [Comandos de Documentação](#-comandos-de-documentação)
- [Comandos Meta](#-comandos-meta)
- [Comandos de Validação](#-comandos-de-validação)
- [Referência Rápida](#-referência-rápida)

## 🎯 Visão Geral

O Sistema Onion oferece **56 comandos especializados** organizados em categorias funcionais. Todos os comandos seguem o padrão `/categoria/comando` e são executados no chat do Claude Code.

### Convenções de Nomenclatura
- **`<feature-slug>`**: Nome da feature em kebab-case (ex: `user-authentication`)
- **`[opcional]`**: Parâmetro opcional
- **`<obrigatório>`**: Parâmetro obrigatório

---

## 🔧 Comandos de Engenharia

### `/engineer/start`
**Sintaxe:** `/engineer/start [feature-slug]`

**Descrição:** Inicia o desenvolvimento de uma funcionalidade com análise completa, arquitetura e plano de implementação.

**Funcionalidades:**
- Cria/valida feature branch
- Analisa tasks do ClickUp (com suporte a checklists nativos)
- Gera `context.md`, `architecture.md` e `plan.md`
- Atualiza automaticamente status no ClickUp
- Cria mapeamento fase→subtask

**Exemplo:**
```bash
/engineer/start user-authentication
```

**Integração ClickUp:**
- ✅ Atualiza status para "In Progress"
- ✅ Adiciona comentário de início
- ✅ Cria mapeamento de fases

---

### `/engineer/work`
**Sintaxe:** `/engineer/work [feature-slug]`

**Descrição:** Trabalha na implementação de uma fase específica do plano.

**Funcionalidades:**
- Lê arquivos da sessão (context, architecture, plan)
- Identifica fase atual em progresso
- Implementa código seguindo o plano
- Atualiza automaticamente ClickUp ao completar fase
- Atualiza status de subtasks correspondentes

**Exemplo:**
```bash
/engineer/work user-authentication
```

**Auto-Update ClickUp:**
- ✅ Comentário de progresso ao completar fase
- ✅ Atualiza status da subtask para "done"
- ✅ Atualiza `plan.md` com decisões

---

### `/engineer/pr`
**Sintaxe:** `/engineer/pr`

**Descrição:** Cria Pull Request com integração GitFlow e sync automático.

**Funcionalidades:**
- Valida testes antes do PR
- Cria feature branch (se necessário)
- Atualiza task ClickUp com tag "under-review"
- Adiciona comentário formatado no ClickUp
- Integração com `/git/sync` pós-merge

**Exemplo:**
```bash
/engineer/pr
```

**Integração ClickUp:**
- ✅ Move task para "in progress"
- ✅ Adiciona tag "under-review"
- ✅ Comentário com link do PR

---

### `/engineer/pr-update`
**Sintaxe:** `/engineer/pr-update`

**Descrição:** Atualiza PR existente com novas mudanças.

**Exemplo:**
```bash
/engineer/pr-update
```

---

### `/engineer/pre-pr`
**Sintaxe:** `/engineer/pre-pr`

**Descrição:** Validações pré-PR (testes, linting, documentação).

**Exemplo:**
```bash
/engineer/pre-pr
```

---

### `/engineer/plan`
**Sintaxe:** `/engineer/plan`

**Descrição:** Cria ou atualiza plano de implementação detalhado.

**Exemplo:**
```bash
/engineer/plan
```

---

### `/engineer/docs`
**Sintaxe:** `/engineer/docs`

**Descrição:** Gera documentação técnica da implementação.

**Exemplo:**
```bash
/engineer/docs
```

---

### `/engineer/hotfix`
**Sintaxe:** `/engineer/hotfix <bug-description>`

**Descrição:** Cria hotfix urgente para correção de bugs críticos.

**Exemplo:**
```bash
/engineer/hotfix "memory-leak-notifications"
```

---

### `/engineer/bump`
**Sintaxe:** `/engineer/bump [major|minor|patch]`

**Descrição:** Atualiza versão do projeto seguindo SemVer.

**Exemplo:**
```bash
/engineer/bump minor
```

---

### `/engineer/warm-up`
**Sintaxe:** `/engineer/warm-up`

**Descrição:** Aquecimento do contexto para desenvolvimento complexo.

**Exemplo:**
```bash
/engineer/warm-up
```

---

### `/engineer/validate-phase-sync`
**Sintaxe:** `/engineer/validate-phase-sync`

**Descrição:** Valida sincronização entre fases do plan.md e subtasks do ClickUp.

**Exemplo:**
```bash
/engineer/validate-phase-sync
```

---

## 📦 Comandos de Produto

### `/product/task`
**Sintaxe:** `/product/task "<descrição-da-task>"`

**Descrição:** Cria task estruturada no ClickUp com decomposição hierárquica inteligente.

**Funcionalidades:**
- Análise profunda e compreensão da tarefa
- Decomposição hierárquica (Task → Subtasks → Action Items)
- Integração automática com Git (`/git:flow feature start` ou branch direta)
- Setup automático de sessão
- Criação de context files

**Patterns Suportados:**
- 🚀 **Feature Development**: Backend + Frontend + Quality
- 🐛 **Bug Fix**: Investigation + Fix + Validation
- 🔧 **Technical Debt**: Analysis + Refactoring + Optimization
- 📚 **Research/Spike**: Discovery + PoC + Decision

**Exemplo:**
```bash
/product/task "Implementar autenticação JWT com refresh tokens"
```

**Workflow:**
1. Análise de documentação (README.md, docs/)
2. Apresentação do plano para confirmação
3. Criação da estrutura no ClickUp
4. Integração Git automática
5. Setup de ambiente de desenvolvimento

**Integração ClickUp:**
- ✅ Cria task principal + subtasks + action items
- ✅ Adiciona tags apropriadas
- ✅ Define prioridade e estimativa
- ✅ Comentário estruturado de setup

---

### `/product/feature`
**Sintaxe:** `/product/feature "<descrição-da-feature>"`

**Descrição:** Cria feature completa com especificação detalhada.

**Exemplo:**
```bash
/product/feature "Dashboard analytics interativo"
```

---

### `/product/spec`
**Sintaxe:** `/product/spec`

**Descrição:** Gera especificação técnica detalhada da feature.

**Exemplo:**
```bash
/product/spec
```

---

### `/product/refine`
**Sintaxe:** `/product/refine`

**Descrição:** Refina especificação existente com mais detalhes.

**Exemplo:**
```bash
/product/refine
```

---

### `/product/check`
**Sintaxe:** `/product/check`

**Descrição:** Valida completude da especificação.

**Exemplo:**
```bash
/product/check
```

---

### `/product/task-check`
**Sintaxe:** `/product/task-check <task-id>`

**Descrição:** Valida task do ClickUp quanto a completude e qualidade.

**Exemplo:**
```bash
/product/task-check 86acu8pdk
```

---

### `/product/validate-task`
**Sintaxe:** `/product/validate-task <task-id>`

**Descrição:** Validação completa de task incluindo critérios de aceitação.

**Exemplo:**
```bash
/product/validate-task 86acu8pdk
```

---

### `/product/checklist-sync`
**Sintaxe:** `/product/checklist-sync <task-id>`

**Descrição:** Sincroniza checklists nativos do ClickUp com documentação local.

**Exemplo:**
```bash
/product/checklist-sync 86acu8pdk
```

---

### `/product/collect`
**Sintaxe:** `/product/collect`

**Descrição:** Coleta requisitos de múltiplas fontes.

**Exemplo:**
```bash
/product/collect
```

---

### `/product/light-arch`
**Sintaxe:** `/product/light-arch`

**Descrição:** Cria arquitetura leve para features simples.

**Exemplo:**
```bash
/product/light-arch
```

---

### `/product/warm-up`
**Sintaxe:** `/product/warm-up`

**Descrição:** Aquecimento de contexto para análise de produto.

**Exemplo:**
```bash
/product/warm-up
```

---

## 🌿 Comandos Git

### `/git/init`
**Sintaxe:** `/git/init`

**Descrição:** Inicializa repositório com GitFlow configurado.

**Exemplo:**
```bash
/git/init
```

---

### `/git:flow feature start`
**Sintaxe:** `/git:flow feature start "<feature-name>"`

**Descrição:** Cria feature branch GitFlow com setup automático de sessão.

**Funcionalidades:**
- Cria branch `feature/nome-da-funcionalidade`
- Detecta branch base (develop/main)
- Configura tracking remoto
- Cria estrutura `.claude/sessions/`
- Integração com @gitflow-specialist

**Exemplo:**
```bash
/git:flow feature start "implement-oauth-authentication"
```

**Estrutura Criada:**
```
feature/implement-oauth-authentication ← nova branch
.claude/sessions/implement-oauth-authentication/
├── context.md
├── plan.md
└── notes.md
```

---

### `/git:flow feature publish`
**Sintaxe:** `/git:flow feature publish`

**Descrição:** Publica feature branch para code review.

**Exemplo:**
```bash
/git:flow feature publish
```

---

### `/git:flow feature finish`
**Sintaxe:** `/git:flow feature finish`

**Descrição:** Finaliza feature branch e merge para develop.

**Exemplo:**
```bash
/git:flow feature finish
```

---

### `/git:flow hotfix start`
**Sintaxe:** `/git:flow hotfix start "<hotfix-name>"`

**Descrição:** Cria hotfix branch para correções urgentes.

**Exemplo:**
```bash
/git:flow hotfix start "fix-payment-timeout"
```

---

### `/git:flow hotfix finish`
**Sintaxe:** `/git:flow hotfix finish`

**Descrição:** Finaliza hotfix e merge para main e develop.

**Exemplo:**
```bash
/git:flow hotfix finish
```

---

### `/git:flow release start`
**Sintaxe:** `/git:flow release start "<version>"`

**Descrição:** Cria release branch para preparação de versão.

**Exemplo:**
```bash
/git:flow release start "v1.2.0"
```

---

### `/git:flow release finish`
**Sintaxe:** `/git:flow release finish`

**Descrição:** Finaliza release e merge para main e develop.

**Exemplo:**
```bash
/git:flow release finish
```

---

### `/git/sync`
**Sintaxe:** `/git/sync`

**Descrição:** Sincroniza branches com GitFlow analysis e cleanup inteligente.

**Funcionalidades:**
- GitFlow analysis via @gitflow-specialist
- Performance otimizada (cache + operações paralelas)
- Cleanup inteligente baseado na estratégia
- Session archiving automático
- ClickUp auto-update para "Done"

**Exemplo:**
```bash
/git/sync
```

---

### `/git/code-review`
**Sintaxe:** `/git/code-review`

**Descrição:** Inicia code review estruturado.

**Exemplo:**
```bash
/git/code-review
```

---

### `/git/help`
**Sintaxe:** `/git/help`

**Descrição:** Ajuda e troubleshooting Git/GitFlow.

**Exemplo:**
```bash
/git/help
```

---

## 📚 Comandos de Documentação

### `/docs/build-business-docs`
**Sintaxe:** `/docs/build-business-docs`

**Descrição:** Gera documentação de contexto de negócio.

**Saída:**
```
docs/business-context/
├── vision.md
├── stakeholders.md
└── business-model.md
```

**Exemplo:**
```bash
/docs/build-business-docs
```

---

### `/docs/build-tech-docs`
**Sintaxe:** `/docs/build-tech-docs`

**Descrição:** Gera documentação de contexto técnico.

**Saída:**
```
docs/technical-context/
├── architecture.md
├── technology-stack.md
└── constraints.md
```

**Exemplo:**
```bash
/docs/build-tech-docs
```

---

### `/docs/build-compliance-docs`
**Sintaxe:** `/docs/build-compliance-docs`

**Descrição:** Gera documentação de compliance (ISO, SOC2, etc).

**Exemplo:**
```bash
/docs/build-compliance-docs
```

---

### `/docs/build-index`
**Sintaxe:** `/docs/build-index`

**Descrição:** Gera índice navegável da documentação.

**Saída:** `docs/index.md`

**Exemplo:**
```bash
/docs/build-index
```

---

### `/docs/refine-vision`
**Sintaxe:** `/docs/refine-vision`

**Descrição:** Refina documento de visão do projeto.

**Exemplo:**
```bash
/docs/refine-vision
```

---

### `/docs/validate-docs`
**Sintaxe:** `/docs/validate-docs`

**Descrição:** Valida completude e qualidade da documentação.

**Exemplo:**
```bash
/docs/validate-docs
```

---

### `/docs/docs-health`
**Sintaxe:** `/docs/docs-health`

**Descrição:** Análise de saúde da documentação (links quebrados, etc).

**Exemplo:**
```bash
/docs/docs-health
```

---

### `/docs/sync-sessions`
**Sintaxe:** `/docs/sync-sessions`

**Descrição:** Sincroniza documentação entre sessões.

**Exemplo:**
```bash
/docs/sync-sessions
```

---

### `/docs/reverse-consolidate`
**Sintaxe:** `/docs/reverse-consolidate`

**Descrição:** Consolida documentação fragmentada.

**Exemplo:**
```bash
/docs/reverse-consolidate
```

---

### `/docs/help`
**Sintaxe:** `/docs/help`

**Descrição:** Ajuda com comandos de documentação.

**Exemplo:**
```bash
/docs/help
```

---

## 🔧 Comandos Meta

### `/meta/all-tools`
**Sintaxe:** `/meta/all-tools`

**Descrição:** Lista todas as ferramentas disponíveis organizadas por categoria.

**Saída:**
```
.claude/docs/tools/
├── mcps.md
├── agents.md
├── commands.md
├── rules.md
├── claude-code.md
└── README.md
```

**Exemplo:**
```bash
/meta/all-tools
```

---

### `/meta/create-command`
**Sintaxe:** `/meta/create-command`

**Descrição:** Cria novo comando customizado com template.

**Exemplo:**
```bash
/meta/create-command
```

---

### `/meta/create-agent`
**Sintaxe:** `/meta/create-agent`

**Descrição:** Cria novo agente especializado com template completo.

**Exemplo:**
```bash
/meta/create-agent
```

---

### `/meta/create-agent-express`
**Sintaxe:** `/meta/create-agent-express`

**Descrição:** Cria agente de forma rápida com template simplificado.

**Exemplo:**
```bash
/meta/create-agent-express
```

---

### `/meta/analyze-complex-problem`
**Sintaxe:** `/meta/analyze-complex-problem "<descrição>"`

**Descrição:** Análise profunda de problemas complexos.

**Exemplo:**
```bash
/meta/analyze-complex-problem "Performance degradation in production"
```

---

## ✅ Comandos de Validação

> 📚 **Documentação Completa**: Veja [Sistema de Testes e Validação](../../../docs/onion/testing-validation-system.md) para guia completo de todos os comandos de teste e validação, incluindo `/test/unit`, `/test/integration`, `/test/e2e`, `/validate/test-strategy/create`, `/validate/qa-points/estimate` e mais.

### `/validate/workflow`
**Sintaxe:** `/validate/workflow`

**Descrição:** Valida workflow completo do projeto.

**Exemplo:**
```bash
/validate/workflow
```

---

## 🚀 Referência Rápida

### Fluxo Completo de Feature
```bash
# 1. Criar task estruturada
/product/task "Nova funcionalidade X"

# 2. Iniciar desenvolvimento
/engineer/start feature-x

# 3. Trabalhar nas fases
/engineer/work feature-x

# 4. Criar Pull Request
/engineer/pr

# 5. Finalizar feature
/git:flow feature finish
```

### Fluxo de Hotfix
```bash
# 1. Criar hotfix
/git:flow hotfix start "fix-critical-bug"

# 2. Implementar correção
/engineer/hotfix "fix-critical-bug"

# 3. Criar PR
/engineer/pr

# 4. Finalizar hotfix
/git:flow hotfix finish
```

### Fluxo de Documentação
```bash
# 1. Gerar docs de negócio
/docs/build-business-docs

# 2. Gerar docs técnicos
/docs/build-tech-docs

# 3. Gerar índice
/docs/build-index

# 4. Validar documentação
/docs/validate-docs
```

---

## 🔗 Documentos Relacionados

- [Fluxos de Engenharia](./engineering-flows.md) - Workflows detalhados
- [Integração ClickUp](./clickup-integration.md) - Guia completo ClickUp MCP
- [Referência de Agentes](./agents-reference.md) - Todos os agentes disponíveis
- [Exemplos Práticos](./practical-examples.md) - Casos de uso reais
- [Sistema de Testes e Validação](../../../docs/onion/testing-validation-system.md) - Framework completo de testes e validação
- [Configuração Inicial](./getting-started.md) - Setup do sistema

---

**Última atualização:** 2025-01-27  
**Versão:** 2.0  
**Total de Comandos:** 56

