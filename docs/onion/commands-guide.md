# 🎯 Guia Completo de Comandos

> **Versão**: 4.0 | **Última atualização**: 2026-06-14

Este guia documenta todos os comandos disponíveis no sistema `.claude/`, organizados por categoria e função.

## 📊 Resumo

> **Contagens canônicas por categoria e total:** [docs/onion/inventory.md](inventory.md) — **SSOT gerada do filesystem** (`/meta:inventory`), validada no CI. Este guia descreve os comandos; os números vivem na SSOT para nunca drifarem.

Categorias: `product/`, `meta/`, `docs/`, `engineer/`, `git/`, `validate/`, `test/`, `development/`, `quick/` + root (`onion`, `warm-up`, `catch-up`).

### Convenções de Nomenclatura

- **`<feature-slug>`**: Nome da feature em kebab-case (ex: `user-authentication`)
- **`[opcional]`**: Parâmetro opcional
- **`<obrigatório>`**: Parâmetro obrigatório

## 📋 Índice por Categoria

- [🔧 Comandos de Engenharia](#-comandos-de-engenharia)
- [📦 Comandos de Produto](#-comandos-de-produto)
- [📚 Comandos de Documentação](#-comandos-de-documentação)
- [⚙️ Meta Comandos](#️-meta-comandos)
- [🌲 Comandos Git](#-comandos-git)
- [✅ Comandos de Validação](#-comandos-de-validação)
- [🌟 Comandos Globais](#-comandos-globais)

---

## 🎯 Como Usar os Comandos

### ⚡ **CRÍTICO: Claude Code Commands vs Terminal**

**TODOS** os comandos deste guia são **[Claude Code Commands](https://docs.claude.com/en/docs/claude-code/slash-commands)** executados no **chat da Claude Code**:

```markdown
# ✅ CORRETO - No chat da Claude Code:
/git/init                       # GitFlow setup inteligente
/git:flow feature start "login"      # Iniciar feature branch
/engineer/start                 # Ambiente de desenvolvimento
/product/task "implementar login"

# ❌ INCORRETO - NÃO são comandos bash/terminal:
$ /git/init                    # Comando não encontrado
$ ./engineer/start             # Não é executável
```

### 🚀 **Padronização v3.0**
**Todos os comandos foram padronizados** com:
- Headers YAML obrigatórios (`name`, `description`, `version: "3.0.0"`)
- Limite de 400 linhas (otimização de tokens)
- Prompts modulares em `common/prompts/`
- Validações automatizadas nos geradores

📚 **[Leia mais sobre a arquitetura](claude-code-commands-architecture.md)**

### 📋 Sintaxe Geral
```bash
/categoria/comando "parâmetro"
```

---

## 🔧 Comandos de Engenharia

### `/engineer/start`
**Sintaxe:** `/engineer/start [feature-slug]`  
**Propósito**: Iniciar desenvolvimento de uma funcionalidade  
**Input**: Tasks do task manager para trabalhar

```bash
/engineer/start user-authentication
# → Cria/valida feature branch
# → Gera context.md, architecture.md e plan.md em .claude/sessions/
# → Atualiza status no task manager
```

**Fluxo detalhado**:
1. Verifica se está em feature branch (ou cria uma)
2. Cria pasta `.claude/sessions/<feature_slug>`
3. Solicita input de tasks do task manager ativo
4. Analisa contexto, objetivos e abordagem
5. Identifica dependências e requisitos de teste

### `/engineer/work`
**Sintaxe:** `/engineer/work [feature-slug]`  
**Propósito**: Trabalhar em uma funcionalidade específica  
**Input**: Pasta ou especificação de trabalho

```bash
/engineer/work user-authentication
# → Lê arquivos da sessão (context, architecture, plan)
# → Identifica fase atual em progresso
# → Implementa código seguindo o plano
# → Atualiza automaticamente status ao completar fase
```

**Fluxo detalhado**:
1. Lê arquivos markdown da pasta especificada
2. Revisa plan.md para identificar fase atual
3. Apresenta plano para próxima fase
4. Usa sub-agentes apropriados para desenvolvimento
5. Atualiza progresso no plan.md

### `/engineer/pr`
**Sintaxe:** `/engineer/pr`  
**Propósito**: Criar Pull Request e atualizar task manager  
**Input**: Branch com código para review

```bash
/engineer/pr
# → Executa testes automaticamente
# → Faz commit das mudanças
# → Atualiza status no task manager
# → Cria PR com detalhes
```

**Fluxo detalhado**:
1. Executa suíte de testes completa
2. Faz commit com mensagem clara
3. Move task para "in progress" + tag "under-review"
4. Cria Pull Request com detalhes da implementação
5. Aguarda e processa feedback automatizado

### `/engineer/pr-update` 🆕
**Sintaxe:** `/engineer/pr-update`  
**Propósito**: Atualizar Pull Request existente com mudanças adicionais

```bash
/engineer/pr-update
# → Detecta mudanças pendentes automaticamente
# → Commit inteligente com tipo contextual (fix/feat/docs/refactor)
# → Push para branch do PR existente
# → Atualiza task manager com detalhes
```

**Fluxo detalhado**:
1. Detecta contexto (branch feature + PR existente)
2. Analisa mudanças para categorização automática
3. Gera commit inteligente
4. Push automático para atualizar PR
5. Comentário detalhado no task manager

### `/engineer/validate-phase-sync` 🆕
**Sintaxe:** `/engineer/validate-phase-sync`  
**Propósito**: Validar sincronização entre fases e subtasks do task manager

```bash
/engineer/validate-phase-sync
# → Analisa plan.md vs status subtasks
# → Identifica discrepâncias
# → Corrige status automaticamente
# → Documenta correções aplicadas
```

**Casos de uso**:
- Verificar sincronização após interrupção de trabalho
- Validar antes de finalizar desenvolvimento
- Corrigir status desatualizados retroativamente

### `/engineer/pre-pr`
**Sintaxe:** `/engineer/pre-pr`  
**Propósito**: Validações antes do Pull Request

```bash
/engineer/pre-pr
# → Executa validações de qualidade
# → Verifica testes e cobertura
# → Valida padrões de código
```

### `/engineer/plan`
**Sintaxe:** `/engineer/plan`  
**Propósito**: Criar ou revisar plano de desenvolvimento

```bash
/engineer/plan "feature: sistema de notificações"
# → Cria plano estruturado em fases
# → Define milestones e dependências
# → Estima tempo e recursos
```

### `/engineer/hotfix`
**Sintaxe:** `/engineer/hotfix <bug-description>`  
**Propósito**: Cria hotfix urgente para correção de bugs críticos

```bash
/engineer/hotfix "memory-leak-notifications"
```

### `/engineer/docs`
**Sintaxe:** `/engineer/docs`  
**Propósito**: Gerar documentação técnica da implementação

```bash
/engineer/docs
# → Analisa código implementado
# → Gera documentação técnica
# → Atualiza arquivos README/docs
```

### `/engineer/bump`
**Sintaxe:** `/engineer/bump [major|minor|patch]`  
**Propósito**: Atualizar versão e preparar release (SemVer)

```bash
/engineer/bump patch
# → Atualiza package.json/version
# → Cria changelog
# → Prepara tags de release
```

### `/engineer/warm-up`
**Sintaxe:** `/engineer/warm-up`  
**Propósito**: Aquecimento e configuração do ambiente de engenharia

---

## 📦 Comandos de Produto

### `/product/task`
**Sintaxe:** `/product/task "<descrição-da-task>"`  
**Propósito**: Criar task estruturada no task manager com decomposição hierárquica inteligente

```bash
/product/task "Implementar sistema de autenticação OAuth2"
# → Analisa documentação do projeto (README.md, docs/)
# → Apresenta plano para confirmação
# → Cria task principal + subtasks + action items
# → Integração Git automática (/git:flow feature start)
```

**Patterns Suportados**:
- Feature Development: Backend + Frontend + Quality
- Bug Fix: Investigation + Fix + Validation
- Technical Debt: Analysis + Refactoring + Optimization
- Research/Spike: Discovery + PoC + Decision

**Fluxo detalhado**:
1. Compreende descrição da tarefa
2. Analisa documentação existente do projeto
3. Formula perguntas para esclarecer ambiguidades
4. Confirma entendimento com usuário
5. Cria task com título, descrição, critérios de aceitação, estimativa e etiquetas

### `/product/feature`
**Sintaxe:** `/product/feature "<descrição-da-feature>"`  
**Propósito**: Cria feature completa com especificação detalhada

```bash
/product/feature "Dashboard analytics interativo"
```

### `/product/collect`
**Sintaxe:** `/product/collect`  
**Propósito**: Coletar e salvar ideias/bugs no backlog

```bash
/product/collect
# → Entende a solicitação através de perguntas
# → Classifica como funcionalidade ou bug
# → Determina prioridade e urgência
# → Salva no task manager com informações estruturadas
```

### `/product/refine`
**Sintaxe:** `/product/refine`  
**Propósito**: Refinar requisitos de uma funcionalidade

```bash
/product/refine
# → Revisa especificação existente
# → Identifica gaps nos requisitos
# → Adiciona detalhes e esclarecimentos
```

### `/product/light-arch`
**Sintaxe:** `/product/light-arch`  
**Propósito**: Esboçar arquitetura inicial para features

```bash
/product/light-arch
# → Discute abordagem arquitetural
# → Define componentes principais
# → Salva decisões no task manager
```

### `/product/spec`
**Sintaxe:** `/product/spec`  
**Propósito**: Criar especificação técnica detalhada

### `/product/check`
**Sintaxe:** `/product/check`  
**Propósito**: Verificar qualidade e completude dos requisitos

### `/product/task-check`
**Sintaxe:** `/product/task-check <task-id>`  
**Propósito**: Valida task do task manager quanto a completude e qualidade

```bash
/product/task-check 86acu8pdk
```

### `/product/validate-task`
**Sintaxe:** `/product/validate-task <task-id>`  
**Propósito**: Validação completa de task incluindo critérios de aceitação

```bash
/product/validate-task 86acu8pdk
```

### `/product/checklist-sync`
**Sintaxe:** `/product/checklist-sync <task-id>`  
**Propósito**: Sincroniza checklists do task manager com documentação local

```bash
/product/checklist-sync 86acu8pdk
```

### `/product/warm-up`
**Sintaxe:** `/product/warm-up`  
**Propósito**: Aquecimento do contexto de produto

---

## 📚 Comandos de Documentação

### `/docs/build-tech-docs`
**Sintaxe:** `/docs/build-tech-docs`  
**Propósito**: Gerar documentação técnica abrangente

```bash
/docs/build-tech-docs
# → Analisa estrutura do projeto
# → Gera documentação multi-arquivo otimizada para IA
```

**Saída:**
```
docs/technical-context/
├── architecture.md
├── technology-stack.md
└── constraints.md
```

### `/docs/build-business-docs`
**Sintaxe:** `/docs/build-business-docs`  
**Propósito**: Gerar documentação de negócio

```bash
/docs/build-business-docs
```

**Saída:**
```
docs/business-context/
├── vision.md
├── stakeholders.md
└── business-model.md
```

### `/docs/build-compliance` 🆕
**Propósito**: Gerar documentação de compliance (ISO 27001, ISO 22301, PMBOK, SOC2)  
**Input**: Frameworks desejados ou checklist de due diligence  
**Integração ClickUp**: ✅ Rastreia compliance requirements  
**Agentes**: `@security-information-master`, `@iso-27001-specialist`, `@iso-22301-specialist`, `@pmbok-specialist`, `@soc2-specialist`

```bash
# Exemplo de uso - Modo Seletivo
/docs/build-compliance frameworks="iso27001,soc2"
# → Gera apenas ISO 27001 (SGSI) + SOC2 (Trust Services)
# → Output: docs/compliance-context/security/ + docs/compliance-context/soc2/

# Exemplo de uso - Modo Due Diligence
/docs/build-compliance due-diligence="docs/serasa-requirements.md"
# → Analisa checklist automaticamente
# → Detecta frameworks necessários (ISO 22301 + SOC2)
# → Gera docs/compliance-context/ com 8/8 requisitos cobertos

# Exemplo de uso - Modo Interativo
/docs/build-compliance
# → Analisa projeto (business/technical context)
# → Sugere frameworks relevantes
# → Pergunta confirmação ao usuário

# Exemplo de uso - Modo Completo
/docs/build-compliance frameworks="all"
# → Gera todos os 4 frameworks (22 documentos)
# → ISO 27001, ISO 22301, PMBOK, SOC2
```

**Fluxo detalhado**:
1. **Descoberta**: Analisa contexto do projeto (docs/business-context/, docs/technical-context/)
2. **Questionamento**: Determina frameworks aplicáveis via:
   - Argumentos explícitos (`frameworks="..."`)
   - Análise de checklist due diligence (keywords + LLM)
   - Sugestão interativa baseada no perfil do projeto
3. **Geração**: Delega para agentes especialistas conforme frameworks selecionados
4. **Consolidação**: `@security-information-master` cria index.md e COMPLIANCE_OVERVIEW.md

**Frameworks Suportados**:
- **ISO 27001:2022** (SGSI): 5 docs (security/) - Access Control, Risk Assessment, Incident Response
- **ISO 22301:2019** (BCMS): 5 docs (business-continuity/) - BCP, DRP, Crisis Management, RTOs/RPOs
- **PMBOK 7th Edition**: 5 docs (project-management/) - Governance, Change/Quality Management
- **SOC2 Type II**: 5 docs (soc2/) - Trust Services Criteria, Security/Availability Controls

**Idioma**: PT-BR (conteúdo) + EN-US (termos técnicos preservados: "Risk Assessment (Avaliação de Riscos)")

**Mapeamento Due Diligence**:
- **Serasa Experian**: 8/8 requisitos cobertos (ISO 22301: 5 reqs, SOC2: 3 reqs) ✅
- Cross-references automáticos entre frameworks (ISO 27001 ↔ SOC2: ~70% overlap)

### `/docs/build-index`
**Sintaxe:** `/docs/build-index`  
**Propósito**: Criar índice de projetos

```bash
/docs/build-index
```

**Saída:** `docs/index.md`

### `/docs/refine-vision`
**Sintaxe:** `/docs/refine-vision`  
**Propósito**: Refinar visão e estratégia do produto

```bash
/docs/refine-vision
```

### `/docs/validate-docs`
**Sintaxe:** `/docs/validate-docs`  
**Propósito**: Valida completude e qualidade da documentação

```bash
/docs/validate-docs
```

### `/docs/docs-health`
**Sintaxe:** `/docs/docs-health`  
**Propósito**: Análise de saúde da documentação (links quebrados, inconsistências)

```bash
/docs/docs-health
```

### `/docs/sync-sessions`
**Sintaxe:** `/docs/sync-sessions`  
**Propósito**: Sincroniza documentação entre sessões

```bash
/docs/sync-sessions
```

### `/docs/reverse-consolidate`
**Sintaxe:** `/docs/reverse-consolidate`  
**Propósito**: Consolida documentação fragmentada

```bash
/docs/reverse-consolidate
```

### `/docs/help`
**Sintaxe:** `/docs/help`  
**Propósito**: Ajuda contextual com comandos de documentação

```bash
/docs/help
```

---

## ⚙️ Meta Comandos

### `/meta/create-agent`
**Sintaxe:** `/meta/create-agent "<especialidade>"`  
**Propósito**: Criar novo agente especializado

```bash
/meta/create-agent "especialista em testes de performance"
# → Analisa requisitos do agente
# → Cria arquivo .md com configuração
# → Define ferramentas e modelo apropriados
```

### `/meta/create-agent-express`
**Sintaxe:** `/meta/create-agent-express`  
**Propósito**: Cria agente de forma rápida com template simplificado

```bash
/meta/create-agent-express
```

### `/meta/analyze-complex-problem`
**Sintaxe:** `/meta/analyze-complex-problem "<descrição>"`  
**Propósito**: Análise profunda de problemas complexos

```bash
/meta/analyze-complex-problem "Performance degradation in production"
```

### `/meta:evolve`
**Propósito**: Auto-auditoria do próprio Sistema Onion via orquestração (fan-out-and-synthesize) que produz um backlog priorizado de refatorações de modernização, com evidência citada (`arquivo:linha`)  
**Input**: Dimensão específica (`D1`..`D8`) ou vazio para auditoria completa (8 dimensões)  
**Natureza**: Read-only — propõe, não muta `.claude/`; a única escrita é o relatório em `docs/analysis/onion-evolution-<data>.md`

```bash
# Exemplo de uso
/meta:evolve            # auditoria completa → backlog priorizado
/meta:evolve D1         # só outliers de peso/tamanho
```

### `/meta:orchestrate`
**Propósito**: Orquestra subagentes em paralelo (fan-out/fan-in) sobre uma tarefa, via a ferramenta nativa Workflow  
**Input**: Descrição da tarefa elegível a paralelização (auditoria, migração, review ou pesquisa ampla)  
**Padrões canônicos**: classify-and-act · fan-out-and-synthesize · adversarial verification · generate-and-filter · tournament · loop-until-done (skill `onion-orchestration`)

```bash
# Exemplo de uso
/meta:orchestrate contar agentes por categoria em .claude/agents/ e retornar resumo consolidado
```

> Outros meta-comandos disponíveis: `/meta:create-command`, `/meta:create-skill`, `/meta:create-knowledge-base`, `/meta:create-abstraction`, `/meta:kb-freshness`, `/meta:metaspec-validate`, `/meta:setup-integration`, `/meta:setup-code-review`.

---

## 🌲 Comandos Git

Operações Git do Sistema Onion, orientadas pelo **motor GitFlow** ([gitflow-patterns.md](../knowledge-base/frameworks/gitflow-patterns.md)). Operações de host remoto (PR, review, CI, Release) passam pelo **forge adapter** ([utils/forge/](../../.claude/utils/forge/README.md)); git local (branch, merge, tag, push) é `git` direto.

### `/git:flow`
**Sintaxe:** `/git:flow <type> <action> [nome|versão]`  
**Propósito**: Dispatcher **único** do ciclo de vida GitFlow — `feature` | `release` | `hotfix` × `start` | `publish` | `finish`. Substitui os 7 antigos sub-comandos por um único ponto de entrada arg-driven  
**Integração**: Forge adapter (PR/CI/Release) + Task Manager adapter (sync opcional via `TASK_MANAGER_PROVIDER`)

```bash
/git:flow feature start "user-auth"   # cria feature/user-auth de develop + sessão
/git:flow feature publish             # push + review (forge)
/git:flow feature finish              # merge → develop + cleanup
/git:flow release start "minor"       # release/<versão> com auto-bump semver
/git:flow release finish              # merge main+develop, tag, Release no host
/git:flow hotfix start "fix-pay"      # hotfix a partir de main + task urgente
/git:flow hotfix finish               # dual-merge + tag + Release + CI
```

**Estrutura criada por `feature start`** (worklog ACTIVE — [SSOT](../knowledge-base/frameworks/gitflow-patterns.md#contrato-de-sessão-de-desenvolvimento)):
```
feature/user-auth ← nova branch
.claude/sessions/user-auth/
├── STATE.md      # índice Tier-0 (ponteiro NEXT)
├── context.md
├── architecture.md
├── plan.md
└── notes.md
```

> **Migração**: os caminhos antigos `/git:feature:start`, `/git:release:finish`, etc. foram consolidados — use sempre `/git:flow <type> <action>`.

### `/git:init`
**Sintaxe:** `/git:init`  
**Propósito**: Inicializar repositório com GitFlow e convenções padrão do Sistema Onion

### `/git:sync`
**Sintaxe:** `/git:sync [branch]`  
**Propósito**: Sincronizar branch atual com o remoto seguindo a estratégia GitFlow (fast-forward em branches protegidas, rebase seguro)

```bash
/git:sync
# → GitFlow analysis + cleanup inteligente
# → Session archiving automático
# → Task manager auto-update para "Done" (se aplicável)
```

### `/git:fast-commit`
**Sintaxe:** `/git:fast-commit`  
**Propósito**: Adicionar todas as mudanças e fazer commit rápido seguindo Conventional Commits

> Comandos auxiliares: `/git:help` (ajuda contextual), `/git:code-review` (alias → `/meta:setup-code-review`).

---

## ✅ Comandos de Validação

> 📚 **Documentação Completa**: Veja [Sistema de Testes e Validação](testing-validation-system.md) para guia completo de todos os comandos de teste e validação, incluindo `/test/unit`, `/test/integration`, `/test/e2e`, `/validate/test-strategy/create`, `/validate/qa-points/estimate` e mais.

### `/validate/workflow`
**Sintaxe:** `/validate/workflow`  
**Propósito**: Valida workflow completo do projeto

```bash
/validate/workflow
```

---

## 🌟 Comandos Globais

### `/all-tools`
**Propósito**: Listar todas as ferramentas e comandos disponíveis  
**Input**: Nenhum  
**Integração ClickUp**: ➖ Informacional apenas

### `/warm-up`
**Propósito**: Aquecimento geral do sistema  
**Input**: Contexto geral  
**Integração ClickUp**: ✅ Valida conectividade

### `/catch-up`
**Propósito**: Briefing de retomada — reconstrói "onde paramos" de sinais duráveis (git recente, sessão ACTIVE, memória, inbox) após queda/saída de sessão. Irmão do `/warm-up` (que carrega contexto do projeto; o catch-up reconstrói sua última atividade)  
**Input**: Nenhum  
**Integração ClickUp**: ➖ Read-only / orientação

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

## 🔄 Fluxo Típico de Desenvolvimento

```mermaid
graph TD
    A[/product/task] --> B[Task criada no task manager]
    B --> C[/engineer/start]
    C --> D[Análise e planejamento]
    D --> E[/engineer/work]
    E --> F[Desenvolvimento iterativo]
    F --> G{Pronto?}
    G -->|Não| E
    G -->|Sim| H[/engineer/pre-pr]
    H --> I[/engineer/pr]
    I --> J{Mudanças adicionais?}
    J -->|Sim| K[/engineer/pr-update]
    K --> J
    J -->|Não| L[Merge & Deploy]
    L --> M[Task marcada como concluída]
    
    style K fill:#e1f5fe
    style J fill:#fff3e0
```

## 📊 Status de Integração Task Manager

| Comando | Ação |
|---------|------|
| `/engineer/start` | Lê tasks + cria Phase-Subtask mapping |
| `/engineer/work` | Auto-sync de subtasks status |
| `/engineer/pr` | Move para "in progress" + tag "under-review" |
| `/engineer/pr-update` | Documenta updates automáticos |
| `/engineer/validate-phase-sync` | Corrige status inconsistentes |
| `/product/task` | Cria task hierárquica |
| `/product/collect` | Salva no backlog |
| `/product/refine` | Atualiza task |
| `/product/light-arch` | Adiciona comentário arquitetural |
| `/docs/build-*` | Organiza docs por contexto |

## 💡 Dicas de Uso

1. **Sempre comece com `/product/task`** para funcionalidades novas
2. **Use `/engineer/start`** para iniciar desenvolvimento organizado
3. **Execute `/engineer/pr`** quando código estiver pronto para review
4. **Aproveite a integração com o task manager** para rastreamento automático
5. **Consulte `/meta/all-tools`** quando não souber qual comando usar

---

## 🔗 Documentos Relacionados

- [Fluxos de Engenharia Detalhados →](engineering-flows.md)
- [Referência de Agentes](agents-reference.md) — catálogo dos 51 agentes especializados
- [Exemplos Práticos](practical-examples.md) — casos de uso reais
- [Sistema de Testes e Validação](testing-validation-system.md) — framework completo de testes
- [Configuração Inicial](getting-started.md) — setup do sistema
- [Inventário Canônico](inventory.md) — contagens SSOT geradas do filesystem

---

**Próximo**: [Fluxos de Engenharia Detalhados →](engineering-flows.md)
