# 🤖 Referência de Agentes

> **Versão**: 4.1 | **Última atualização**: 2026-06-14

Este guia documenta os agentes especializados disponíveis no sistema `.claude/`, suas capacidades e quando utilizá-los.

## 📊 Resumo

> **Contagens canônicas por categoria e total:** [docs/onion/inventory.md](inventory.md) — **SSOT gerada do filesystem** (`/meta:inventory`), validada no CI. Sistema Onion: **96 comandos** em 10 categorias, **51 agentes** em 9 categorias, **8 skills**, **71 knowledge bases**. Categorias de agentes: `development/`, `product/`, `compliance/`, `git/`, `meta/`, `testing/`, `review/`, `research/`, `deployment/`.

## 📋 Índice de Agentes

> Os títulos abaixo refletem as seções deste guia; alguns agentes podem aparecer agrupados por afinidade temática, não estritamente por diretório. Para a contagem oficial por diretório, ver [inventory.md](inventory.md).

- [🧅 Agente Principal](#-agente-principal)
- [🔵 Agentes de Desenvolvimento](#-agentes-de-desenvolvimento)
- [🔷 Agentes de Testes](#-agentes-de-testes)
- [🟢 Agentes de Review](#-agentes-de-review)
- [🟣 Agentes de Pesquisa](#-agentes-de-pesquisa)
- [🔴 Agentes de Arquitetura](#-agentes-de-arquitetura)
- [🟠 Agentes de Documentação](#-agentes-de-documentação)
- [🛡️ Agentes de Compliance](#️-agentes-de-compliance-)
- [🟡 Agentes de Produto](#-agentes-de-produto)
- [🔧 Agentes Meta](#-agentes-meta)
- [🌿 Agentes de Branch (Git Review)](#-agentes-de-branch-git-review)
- [⚙️ Como Escolher o Agente Certo](#️-como-escolher-o-agente-certo)
- [📊 Combinações Eficazes](#-combinações-eficazes)
- [💡 Melhores Práticas](#-melhores-práticas)

---

## 🧅 Agente Principal

### **onion**
**Modelo**: Sonnet | **Prioridade**: Alta | **Cor**: Purple

**Especialidades**: Orquestração master do Sistema Onion, navegação, recomendação de comandos/agentes, troubleshooting geral

**Quando usar**:
- Navegar e se orientar no sistema
- Dúvidas sobre qual comando ou agente usar
- Orquestração de workflows complexos (feature, hotfix, PR, compliance)
- Troubleshooting geral
- Coordenação de tarefas multi-etapas
- Qualquer dúvida sobre o Sistema Onion

**Exemplo de uso**:
```bash
@onion "Como desenvolver uma feature completa do zero?"
@onion "Qual comando usar para criar uma task no ClickUp?"
@onion "Preciso gerar documentação de compliance para Serasa"
```

**Capacidades**:
- Conhecimento completo: 96 comandos, 51 agentes, 8 skills, 71 knowledge bases
- Análise inteligente de contexto e recomendação de abordagem
- Orquestração de workflows end-to-end
- Delegação para agentes especializados
- Troubleshooting e diagnóstico de problemas no framework

**Diferencial**: O `@onion` é o **ponto de entrada inteligente** do Sistema Onion. Use-o quando não souber por onde começar ou precisar coordenar tarefas complexas envolvendo múltiplos domínios.

---

## 🔵 Agentes de Desenvolvimento

Catálogo completo da categoria `development/` (18 agentes — descrições derivadas do frontmatter de cada agente; ver [inventory.md](inventory.md) para a contagem canônica):

| Agente | Modelo | Para que serve |
|--------|--------|----------------|
| `react-developer` | Sonnet | React/Next.js moderno, shadcn/ui, TypeScript, a11y _(destaque abaixo)_ |
| `nodejs-specialist` | Sonnet | Backend Node.js/TypeScript, PNPM, performance optimization |
| `postgres-specialist` | Sonnet | PostgreSQL 17: triggers, functions, schema, performance |
| `clickup-specialist` | Sonnet | ClickUp MCP técnico: automações, bulk, webhooks _(destaque abaixo)_ |
| `jira-specialist` | Sonnet | Jira REST API v3/v2: JQL, ADF, transitions, bulk |
| `nx-monorepo-specialist` | Sonnet | NX Monorepo: libs/apps, estrutura tier/scope/type enterprise |
| `nx-migration-specialist` | Sonnet | Migração segura de NX Monorepo (v19+ → v21+) |
| `c4-architecture-specialist` | Sonnet | Diagramas C4 (Context/Container/Component) com Mermaid |
| `c4-documentation-specialist` | Sonnet | Documentação textual C4 + ADRs (complementa diagramas) |
| `mermaid-specialist` | Sonnet | Diagramas Mermaid em documentação/Markdown renderizado |
| `system-documentation-orchestrator` | Sonnet | Orquestra docs técnicas (coordena mermaid + c4) |
| `docs-reverse-engineer` | Sonnet | Engenharia reversa: detecção de stack + docs de qualquer projeto |
| `claude-code-specialist` | Sonnet | Otimização, configuração e troubleshooting do Claude Code |
| `runflow-specialist` | Sonnet | Runflow SDK: agentes IA, workflows e integrações |
| `zen-engine-specialist` | Sonnet | ZEN Engine / JDM: regras de negócio, Decision Tables |
| `gamma-api-specialist` | Sonnet | Gamma.App API: apresentações e conteúdo com IA |
| `whisper-specialist` | Sonnet | Transcrição de áudio com Whisper (OpenAI) |
| `linux-security-specialist` | Sonnet | Hardening, auditoria e resposta a incidentes Linux |
| `task-specialist` | Sonnet | Decomposição hierárquica de tasks (agnóstico de provider) _(destaque abaixo)_ |
| `docker-specialist` | Sonnet | Docker, containers, Dockerfiles otimizados, Docker Compose |

**Destaques** (perfis detalhados):

### **react-developer**
**Modelo**: Sonnet | **Prioridade**: Alta | **Cor**: Blue

**Especialidades**: React moderno, shadcn/ui, TypeScript, acessibilidade, performance

**Quando usar**:
-  Componentes React/Next.js
-  Frontend TypeScript
-  Design systems com shadcn/ui
-  Otimização de performance frontend

**Principais recursos**:
- ⚛️ React hooks e patterns modernos
- 🎨 shadcn/ui component library
- 📝 TypeScript com tipagem estrita
- ♿ Acessibilidade (a11y) built-in
- ⚡ Performance optimization
- 🧪 Testing com React Testing Library

### **clickup-specialist**
**Modelo**: Sonnet | **Prioridade**: Alta | **Cor**: Orange

**Especialidades**: ClickUp MCP técnico, automações avançadas, performance, workflows

**Quando usar**:
-  Otimizações técnicas do ClickUp
-  Automações de workflow complexas
-  Bulk operations e performance
-  Configurações avançadas (webhooks, custom fields)
-  Time tracking e análise de produtividade

**Ferramentas disponíveis**: `Read`, `Write`, `Edit`, `Bash`, `Grep`, `WebSearch`, **todas as 15+ ferramentas ClickUp MCP** (bulk operations, webhooks, time tracking, etc.)

**Exemplo de uso**:
```bash
# Para automações de workflow
@clickup-specialist "Configurar automação: task 'in progress' → start time tracking + add tag 'development'"

# Para operações em bulk
@clickup-specialist "Criar 20 tasks de feature seguindo template padrão com bulk operations"

# Para configurações avançadas
@clickup-specialist "Setup webhook para sync status ClickUp → GitHub quando PR é criado"
```

**Principais recursos**:
- 🚀 **Performance First**: Bulk operations para eficiência máxima
- 🤖 **Workflow Automation**: Automações baseadas em triggers inteligentes
- ⚡ **Rate Limit Management**: Otimização respeitando limites da API
- 🔧 **Advanced Configuration**: Custom fields, templates, webhooks
- 📊 **Time Tracking Integration**: Automação de tracking e análise de produtividade
- 🎯 **Complementa product-agent**: Foco técnico vs estratégico

**Complementaridade**:
- **product-agent**: Estratégia, coordenação, especificação (O QUE fazer)
- **clickup-specialist**: Implementação técnica, automação, performance (COMO otimizar)

### **task-specialist**
**Modelo**: Sonnet | **Prioridade**: Alta | **Cor**: Teal

**Especialidades**: Decomposição hierárquica de tasks, estimativas, critérios de aceitação — **agnóstico de provider**

**Quando usar**:
- Quebrar tasks complexas em subtasks acionáveis
- Criar estrutura hierárquica com estimativas de esforço
- Definir critérios de aceitação e action items
- Operar sem provider configurado (`TASK_MANAGER_PROVIDER=none`)

**Exemplo de uso**:
```bash
@task-specialist "Decompor feature de autenticação JWT em subtasks"
@task-specialist "Criar estrutura de tasks para migração de banco de dados"
@task-specialist "Estimar esforço para implementação de sistema de notificações"
```

**Capacidades**:
- Decomposição inteligente com patterns (Feature / Bug / Tech Debt / Research)
- Estimativas de esforço calibradas
- Critérios de aceitação claros e testáveis
- Dependency mapping entre tasks

### **docker-specialist**
**Modelo**: Sonnet | **Prioridade**: Média | **Cor**: Blue

**Especialidades**: Docker, containers, Dockerfiles otimizados, Docker Compose, CI/CD containerizado

**Quando usar**:
- Criar ou otimizar Dockerfiles
- Configurar Docker Compose para ambientes multi-serviço
- Troubleshooting de containers
- Otimizar imagens (multi-stage builds, layer caching)

**Exemplo de uso**:
```bash
@docker-specialist "Criar Dockerfile otimizado para Node.js com multi-stage build"
@docker-specialist "Configurar Docker Compose para stack Postgres + Redis + API"
@docker-specialist "Container não inicia — diagnosticar problema de permissões"
```

---

## 🔷 Agentes de Testes

### **test-engineer**
**Modelo**: Sonnet | **Prioridade**: Média | **Cor**: Cyan

**Especialidades**: Unit testing com Jest/Vitest, behavior verification, qualidade

**Quando usar**:
-  Escrever testes unitários
-  Verificar comportamento de código
-  Identificar gaps de cobertura
-  Validar funcionalidade sem modificar implementação

**Ferramentas disponíveis**: `Read`, `Write`, `Edit`, `Bash`, `Grep`, `Grep`, `Bash`, `TodoWrite`

**Exemplo de uso**:
```bash
@test-engineer "Criar testes para a função de validação de email"
@test-engineer "Verificar cobertura dos endpoints de autenticação"
```

**Características únicas**:
- 🧪 Testes práticos focados em comportamento
- 🚫 **NÃO modifica implementação** - apenas testa
- 📊 Identifica gaps e os reporta ao agente principal
- ⚡ Jest/Vitest com mocks apropriados
- 💡 Sugestões para melhorar testabilidade

### **test-planner**
**Modelo**: Sonnet | **Prioridade**: Média | **Cor**: Cyan

**Especialidades**: Planejamento de testes, análise de cobertura, estratégia de testes

**Quando usar**:
-  Planejar estratégia de testes para projeto
-  Análise de cobertura de teste existente
-  Identificar áreas críticas para teste
-  Criar planos de teste abrangentes

---

## 🟢 Agentes de Review

### **code-reviewer**
**Modelo**: Opus | **Prioridade**: Alta | **Cor**: Green

**Especialidades**: Code review, melhores práticas, detecção de bugs, manutenibilidade

**Quando usar**:
-  Review de código antes de PR
-  Análise de qualidade geral
-  Identificação de padrões problemáticos
-  Sugestões de melhoria

**Ferramentas disponíveis**: `Read`, `Grep`, `Grep`, `Bash`, `Edit`, `TodoWrite`, `Bash`

**Exemplo de uso**:
```bash
@code-reviewer "Revisar implementação do sistema de cache"
@code-reviewer "Analisar security patterns no módulo de auth"
```

**Prioridades de review**:
1. 🎯 **Correção** - Funciona para o caso de uso?
2. 🔒 **Segurança** - Vulnerabilidades óbvias?
3. ⚡ **Performance** - Gargalos evidentes?
4. 🔧 **Manutenibilidade** - Fácil de entender/modificar?
5. 📖 **Clareza** - Bem documentado?

---

## 🟣 Agentes de Pesquisa

### **research-agent**
**Modelo**: Sonnet | **Prioridade**: Alta | **Cor**: Purple

**Especialidades**: Pesquisa multi-fonte, web search, análise semântica

**Quando usar**:
-  Pesquisar tecnologias e bibliotecas
-  Investigar melhores práticas
-  Análise de concorrentes
-  Documentação de bibliotecas específicas

**Ferramentas disponíveis**: `Read`, `Grep`, `WebSearch`, `Grep`, `Glob`, `Edit`, `TodoWrite`

**Exemplo de uso**:
```bash
@research-agent "Pesquisar melhores práticas para autenticação OAuth2 em 2024"
@research-agent "Comparar React Query vs SWR para data fetching"
@research-agent "Encontrar documentação atualizada para biblioteca X"
```

**Metodologia única**:
- 🔍 **Busca multi-fonte**: Web + análise semântica
- 📊 **Insights acionáveis**: Não apenas informação, mas recomendações
- 🎯 **Evidência-baseada**: Toda claim apoiada por fontes
- 🔄 **Múltiplas perspectivas**: Considera diferentes abordagens

---

## 🔴 Agentes de Arquitetura

### **metaspec-gate-keeper**
**Modelo**: Opus | **Prioridade**: Alta | **Cor**: Red

**Especialidades**: Integridade arquitetural, metaspecs, design principles, validação

**Quando usar**:
-  Validar alinhamento com metaspecs
-  Review de decisões arquiteturais
-  Garantir consistência de design
-  Aprovação/rejeição de mudanças estruturais

**Ferramentas disponíveis**: `Read`, `Grep`, `Grep`, `Edit`, `TodoWrite`, `WebSearch`

**Exemplo de uso**:
```bash
@metaspec-gate-keeper "Validar se nova arquitetura de microsserviços alinha com metaspecs"
@metaspec-gate-keeper "Revisar decisão de usar GraphQL vs REST"
```

**Responsabilidades**:
- 📋 Interpreta metaspecs do projeto
-  Valida alinhamento de propostas
- 🚨 Identifica desvios críticos
- 💡 Orienta decisões arquiteturais
- 📝 Propõe atualizações de metaspecs

---

## 🟠 Agentes de Documentação

### **documentation-writer**
**Modelo**: Sonnet | **Prioridade**: Média | **Cor**: Orange

**Especialidades**: Documentação técnica, análise de mudanças, sincronização docs-código

**Quando usar**:
-  Atualizar docs após mudanças de código
-  Criar documentação nova
-  Sincronizar docs com estado atual
-  Análise de gaps de documentação

**Ferramentas disponíveis**: `Read`, `Write`, `Edit`, `Edit`, `Grep`, `WebSearch`, `Grep`, `Glob`

**Exemplo de uso**:
```bash
@documentation-writer "Atualizar docs após mudanças na API de usuários"
@documentation-writer "Criar guia de setup para novo desenvolvedor"
```

---

## 🛡️ Agentes de Compliance 🆕

### **security-information-master**
**Modelo**: Sonnet | **Prioridade**: Alta | **Cor**: Blue

**Especialidades**: Orquestração de compliance, detecção de frameworks, due diligence, ISO 27001, ISO 22301, PMBOK, SOC2

**Quando usar**:
-  Gerar documentação de compliance multi-framework
-  Analisar requisitos de due diligence (ex: Serasa Experian)
-  Coordenar múltiplos specialists de compliance
-  Preparar documentação para auditorias e certificações
-  Consolidar outputs de frameworks diferentes

**Ferramentas disponíveis**: `Read`, `Write`, `Grep`, `Grep`, `Glob`, `WebSearch`, `TodoWrite`

**Agentes delegados**: `@iso-27001-specialist`, `@iso-22301-specialist`, `@pmbok-specialist`, `@soc2-specialist`

**Exemplo de uso**:
```bash
# Orquestração automática baseada em checklist
@security-information-master "Analisar checklist Serasa e gerar documentação necessária"

# Due diligence completo
@security-information-master "Preparar docs para auditoria ISO 27001 + SOC2"

# Análise de requisitos
@security-information-master "Determinar quais frameworks aplicam para fintech B2B enterprise"
```

**4 Modos de Operação**:
1. **Seletivo**: frameworks="iso27001,soc2" (user-driven)
2. **Due Diligence**: due-diligence="checklist.md" (keyword + LLM detection)
3. **Padrão/Auto**: Análise de projeto + sugestão interativa
4. **Completo**: frameworks="all" (todos os 4 frameworks)

**Características únicas**:
- 🧠 **Detecção Híbrida**: Keywords (rápido) + LLM validation (preciso)
- 🎯 **Orquestração Dinâmica**: Ativa apenas specialists necessários
- 🌐 **PT-BR + EN-US**: Conteúdo em português, termos técnicos preservados
- 📊 **Consolidação**: Cria index.md e COMPLIANCE_OVERVIEW.md automaticamente
- ⚡ **Cross-References**: Detecta overlaps entre frameworks (ISO 27001 ↔ SOC2: ~70%)

---

### **iso-27001-specialist**
**Modelo**: Sonnet | **Prioridade**: Alta | **Cor**: Red

**Especialidades**: ISO/IEC 27001:2022 (ISMS), risk assessment, asset management, access control, incident response

**Quando usar**:
-  Documentação SGSI (Sistema de Gestão de Segurança da Informação)
-  Risk Assessment conforme ISO 27005
-  Statement of Applicability (SoA) - 93 controles Annex A
-  Preparação para certificação ISO 27001
-  Integração com SOC2 (cross-references)

**Ferramentas disponíveis**: `Read`, `Write`, `Edit`, `Grep`, `Grep`

**Exemplo de uso**:
```bash
# Documentação SGSI completa
@iso-27001-specialist "Gerar documentação ISO 27001 com foco em fintech"

# Risk Assessment específico
@iso-27001-specialist "Criar Risk Assessment para APIs RESTful + database PostgreSQL"

# Controles específicos
@iso-27001-specialist "Documentar Annex A 5.15-5.18 (Access Control) com MFA + RBAC"
```

**5 Documentos Gerados** (`docs/compliance-context/security/`):
1. `information-security-policy.md` - Política de Segurança (Clause 5.2)
2. `risk-assessment.md` - 10-15 riscos principais (Clause 6.1.2)
3. `asset-management.md` - Inventário e classificação (Annex A 5.9)
4. `access-control.md` - MFA, RBAC, policies (Annex A 5.15-5.18)
5. `incident-response.md` - Runbooks e playbooks (Annex A 5.24-5.28)

**Características únicas**:
- 🔒 **ISO 27001:2022 atualizado**: Versão mais recente (93 controles Annex A)
- 📋 **SoA Completo**: Statement of Applicability com 78+ controles (84%)
- 🔗 **Cross-Reference SOC2**: ~70% overlap documentado
- 🎯 **Evidence-Based**: Documentação baseada em implementação real
- 📊 **Audit-Ready**: Pronto para auditores externos

---

### **iso-22301-specialist**
**Modelo**: Sonnet | **Prioridade**: Alta | **Cor**: Green

**Especialidades**: ISO 22301:2019 (BCMS), business continuity, disaster recovery, RTOs/RPOs, crisis management

**Quando usar**:
-  Business Continuity Plan (BCP) com Business Impact Analysis
-  Disaster Recovery Plan (DRP) para ambientes tecnológicos
-  Crisis Management Plan com canais de comunicação
-  **Due Diligence Serasa Experian** (5 de 8 requisitos cobertos) 🔥
-  Documentação de RTOs/RPOs por criticidade de sistema

**Ferramentas disponíveis**: `Read`, `Write`, `Edit`, `Grep`, `Grep`

**Exemplo de uso**:
```bash
# BC/DR completo
@iso-22301-specialist "Gerar BCP + DRP para infraestrutura AWS Multi-AZ"

# Due Diligence Serasa
@iso-22301-specialist "Documentar 5 requisitos Serasa: BCP, DRP, Crisis, Testing, RTOs/RPOs"

# Testes de resiliência
@iso-22301-specialist "Documentar DR Drill 2024 com RTO 30min alcançado"
```

**5 Documentos Gerados** (`docs/compliance-context/business-continuity/`):
1. `business-continuity-plan.md` - BCP com BIA (Serasa Req #1) ✅
2. `disaster-recovery-plan.md` - DRP com runbooks (Serasa Req #2) ✅
3. `crisis-management.md` - CMT + Serasa contacts (Serasa Req #3) ✅
4. `resilience-testing.md` - Evidências 2024 (Serasa Req #4) ✅
5. `recovery-objectives.md` - RTOs/RPOs por tier (Serasa Req #5) ✅

**Características únicas**:
- 🚨 **Serasa-Ready**: 5 de 8 requisitos Serasa Experian (62.5%) ✅
- ⏱️ **RTOs/RPOs Realistas**: Baseados em BIA, não aspiracionais
- 📊 **Scenario-Based**: Planos baseados em cenários reais de desastre
- 🧪 **Testable**: Todos planos são testáveis (evidências de testes anuais)
- 🏥 **Multi-Region**: DRP com failover AWS (us-east-1 → us-west-2)

---

### **pmbok-specialist**
**Modelo**: Sonnet | **Prioridade**: Média | **Cor**: Yellow

**Especialidades**: PMBOK Guide 7th Edition, project governance, change management, quality management

**Quando usar**:
-  Framework de governança de projetos
-  Processo de Change Management formal
-  Quality Management com Definition of Done
-  Integração com NX monorepo (governança técnica)
-  Evidências de workshops e treinamentos

**Ferramentas disponíveis**: `Read`, `Write`, `Edit`, `Grep`, `Grep`

**Exemplo de uso**:
```bash
# Governança completa
@pmbok-specialist "Gerar framework de governança PMBOK 7th para NX monorepo"

# Change Management
@pmbok-specialist "Documentar processo de Change Request com CI/CD + Feature Flags"

# Quality Gates
@pmbok-specialist "Criar Quality Management com DoD, Code Review e métricas DORA"
```

**5 Documentos Gerados** (`docs/compliance-context/project-management/`):
1. `project-governance.md` - PMO, RACI, lifecycle, 12 princípios PMBOK
2. `change-management.md` - Change Request process, CI/CD, Feature Flags
3. `quality-management.md` - DoD, Code Review, Quality Gates, DORA metrics
4. `stakeholder-management.md` - Power-Interest Grid, Communication Plan
5. `risk-management.md` - Risk Register, 15 riscos, mitigation plans

**Características únicas**:
- 📘 **PMBOK 7th Edition**: Princípios (não processos prescritivos da 6th)
- 🎯 **12 Princípios Aplicados**: Stewardship, Team, Value, Quality, etc.
- 🏗️ **NX Monorepo Integration**: CODEOWNERS, dependency graph, boundaries
- 📊 **Métricas DORA + SPACE**: Deployment frequency, lead time, MTTR, etc.
- 📝 **Templates Práticos**: Project Charter, RFC, Change Request completos

---

### **soc2-specialist**
**Modelo**: Sonnet | **Prioridade**: Alta | **Cor**: Purple

**Especialidades**: SOC2 Type II (AICPA), Trust Services Criteria, evidence collection, continuous monitoring

**Quando usar**:
-  Preparação para SOC2 Type II audit
-  Trust Services Criteria (Security, Availability, Confidentiality)
-  **Due Diligence Serasa Experian** (3 de 8 requisitos cobertos) 🔥
-  Estratégia de coleta de evidências (12 meses)
-  Integração com ISO 27001 (~70% overlap)

**Ferramentas disponíveis**: `Read`, `Write`, `Edit`, `Grep`, `Grep`

**Exemplo de uso**:
```bash
# SOC2 Type II completo
@soc2-specialist "Preparar documentação SOC2 Type II para fintech SaaS"

# Due Diligence Serasa
@soc2-specialist "Documentar 3 requisitos Serasa: Relatório SOC2 + SLAs + Contratos"

# Evidence Collection
@soc2-specialist "Criar estratégia de evidências para 12 meses de audit period"
```

**5 Documentos Gerados** (`docs/compliance-context/soc2/`):
1. `trust-services-criteria.md` - 5 TSC principles, Type II overview (Serasa Req #6) ✅
2. `security-controls.md` - CC6/CC7 (auth, encryption, monitoring, incidents)
3. `availability-controls.md` - A1 (HA, SLAs, DR) (Serasa Req #7, #8) ✅
4. `confidentiality-controls.md` - C1 (classification, NDAs, DLP, disposal)
5. `evidence-collection.md` - Automation matrix, audit prep checklist

**Características únicas**:
- 🚨 **Serasa-Ready**: 3 de 8 requisitos Serasa Experian (37.5%) ✅
- 🎯 **Combined Coverage**: ISO 22301 + SOC2 = 8/8 Serasa (100%) ✅
- 🔗 **ISO 27001 Cross-Ref**: ~70% controles sobrepõem (documentado)
- 📊 **Evidence-First**: Todo controle tem evidência coletável para Type II
- 🤖 **Automation**: Scripts de coleta automática de evidências (monthly)

---

**Mapeamento Serasa Experian** (8 requisitos totais):
| Requisito | Framework | Specialist | Documento |
|-----------|-----------|------------|-----------|
| #1: BCP | ISO 22301 | `@iso-22301-specialist` | business-continuity-plan.md ✅ |
| #2: DRP | ISO 22301 | `@iso-22301-specialist` | disaster-recovery-plan.md ✅ |
| #3: Crisis Mgmt | ISO 22301 | `@iso-22301-specialist` | crisis-management.md ✅ |
| #4: Testes BC/DR | ISO 22301 | `@iso-22301-specialist` | resilience-testing.md ✅ |
| #5: RTOs/RPOs | ISO 22301 | `@iso-22301-specialist` | recovery-objectives.md ✅ |
| #6: SOC2 Report | SOC2 | `@soc2-specialist` | trust-services-criteria.md ✅ |
| #7: SLAs | SOC2 | `@soc2-specialist` | availability-controls.md ✅ |
| #8: Docs SLAs | SOC2 | `@soc2-specialist` | availability-controls.md ✅ |

**Status**: ✅ 8/8 requisitos cobertos (100%)

### **corporate-compliance-specialist**
**Modelo**: Sonnet | **Prioridade**: Média | **Cor**: Blue

**Especialidades**: Compliance corporativa, políticas e procedimentos, governança, auditoria interna

**Quando usar**:
- Review de compliance corporativo
- Políticas internas e procedimentos
- Auditoria interna de práticas
- Governance organizacional

**Exemplo de uso**:
```bash
@corporate-compliance-specialist "Review de compliance corporativo do projeto"
@corporate-compliance-specialist "Verificar aderência a políticas internas de segurança de dados"
```

---

## 🟡 Agentes de Produto

### **product-agent**
**Modelo**: Opus | **Prioridade**: Alta | **Cor**: Yellow

**Especialidades**: Gestão de produto, ClickUp integration, estratégia, coordenação

**Quando usar**:
-  Criação e refinamento de tasks
-  Coordenação com ClickUp
-  Análise de requisitos
-  Gestão de roadmap

**Ferramentas disponíveis**: `Read`, `Write`, `Grep`, `WebSearch`, `TodoWrite`, `mcp_clickup-mcp-server_create_task`, `mcp_clickup-mcp-server_update_task`, `mcp_clickup-mcp-server_get_task`, `mcp_clickup-mcp-server_create_task_comment`

**Integração ClickUp**:
-  Cria tasks estruturadas
-  Atualiza status e progresso  
-  Adiciona comentários contextuais
-  Gerencia tags e prioridades

> **clickup-specialist** está documentado na seção [Agentes de Desenvolvimento](#-agentes-de-desenvolvimento) — colabora com `@product-agent` (técnico vs. estratégico).

### **storytelling-business-specialist**
**Modelo**: Sonnet | **Prioridade**: Média | **Cor**: Yellow

**Especialidades**: Storytelling de produto, comunicação de valor de negócio, apresentações executivas

**Quando usar**:
- Criar narrativas de produto para stakeholders
- Comunicar valor de negócio de features
- Estruturar apresentações de produto
- Documentar contexto de negócio de forma persuasiva

**Exemplo de uso**:
```bash
@storytelling-business-specialist "Criar narrativa da nova feature de pagamentos para apresentação ao board"
```

### **presentation-orchestrator**
**Modelo**: Sonnet | **Prioridade**: Média | **Cor**: Orange

**Especialidades**: Orquestração de apresentações, integração de múltiplas fontes, geração automatizada

**Quando usar**:
- Coordenar criação de apresentações multi-fonte
- Estruturar e automatizar geração de slides/docs executivos
- Integrar dados técnicos com narrativa de negócio

**Exemplo de uso**:
```bash
@presentation-orchestrator "Gerar apresentação executiva do projeto com dados de sprint + roadmap"
```

### **claude-code-specialist**
**Modelo**: Sonnet | **Prioridade**: Alta | **Cor**: Light Blue

**Especialidades**: Otimização Claude Code, configuração workspace, troubleshooting, produtividade

**Quando usar**:
-  Resolver problemas de performance do Claude Code
-  Configurar ambiente para novos projetos
-  Otimizar settings para workflows específicos
-  Troubleshoot extension conflicts ou API connectivity
-  Criar `CLAUDE.md` e `.claudeignore` templates
-  Setup automation para comandos `/engineer/*`

**Ferramentas disponíveis**: `Read`, `Write`, `Edit`, `Bash`, `Grep`, `Glob`, `Glob`, `WebSearch`, `Bash`, `TodoWrite`

**Exemplo de uso**:
```bash
# Configuração de projeto novo
@claude-code-specialist "Setup otimizado para projeto React TypeScript com foco em AI development"

# Troubleshooting
@claude-code-specialist "Resolver erro 'HTTP/2 blocked by proxy' e otimizar connectivity"

# Performance Issues
@claude-code-specialist "Claude Code está lento, analisar memory usage e otimizar configurations"
```

**Características únicas**:
- 🎯 **7 especialidades técnicas**: configuration, workspace, extensions, API, performance, productivity, troubleshooting
- 🚀 **Integração automática**: Chamado automaticamente por outros agentes quando há problemas de IDE
- 🔧 **Criação de artefatos**: `CLAUDE.md`, `.claudeignore`, workspace settings otimizados
- ⚡ **Performance focus**: Memory optimization, startup time, context caching
- 🔗 **Delegation automática**: Integração com comandos `/engineer/*` para setup de ambiente

### **gitflow-specialist**
**Modelo**: Sonnet | **Prioridade**: Alta | **Cor**: Light Green

**Especialidades**: GitFlow workflows, branch management, release processes, team collaboration, semantic versioning

**Quando usar**:
-  Setup inicial de repositórios GitFlow
-  Guidance para workflows de feature development
-  Processos de release estruturados
-  Emergency hotfix workflows
-  Migração master → main em projetos GitFlow
-  Resolução de conflitos GitFlow complexos
-  Onboarding de equipes em GitFlow
-  Otimização de workflows colaborativos

**Ferramentas disponíveis**: `Read`, `Write`, `Edit`, `Bash`, `Grep`, `Grep`, `WebSearch`, `TodoWrite`

**Exemplo de uso**:
```bash
# Para setup inicial
@gitflow-specialist "Configurar GitFlow em repositório novo com detecção automática master/main"

# Para workflows
@gitflow-specialist "Orientar equipe no processo de release v2.1.0 com semantic versioning"

# Para emergências
@gitflow-specialist "Hotfix crítico em produção - orientar processo completo"

# Para migração
@gitflow-specialist "Migrar repositório de master para main mantendo GitFlow ativo"
```

**Características únicas**:
- 🌿 **Flexibilidade master/main**: Detecção automática e suporte a ambas convenções
- 🎯 **Guidance-focused**: Ensina e orienta ao invés de automatizar
- 📚 **6 Templates completos**: Setup, feature, release, hotfix, migration, conflicts
- 🧠 **Semantic versioning**: Conventional commits + análise automática de versioning
- 👥 **Team enablement**: Onboarding em 3 níveis (iniciante, intermediário, avançado)
- 📊 **Analytics integration**: Métricas de equipe e health checks
- 🔗 **Complementaridade**: Integração perfeita com @mermaid-specialist (workflows vs diagramas)

### **nodejs-specialist**
**Modelo**: Sonnet | **Prioridade**: Alta | **Cor**: Teal

**Especialidades**: Backend JavaScript/TypeScript, Node.js runtime, PNPM ecosystem, performance optimization

**Quando usar**:
-  APIs REST/GraphQL complexas com Node.js
-  Configurações TypeScript para backend
-  Performance optimization Node.js (memory, clustering, profiling)
-  Migração/configuração PNPM ecosystem
-  Implementação de security best practices
-  Testing strategies (Jest/Vitest, integration, E2E)
-  Microserviços e arquiteturas escaláveis

**Ferramentas disponíveis**: `Read`, `Write`, `Edit`, `Bash`, `Grep`, `Bash`, `TodoWrite`, `WebSearch`

**Exemplo de uso**:
```bash
# Para APIs performantes
@nodejs-specialist "Criar API Fastify com autenticação JWT, rate limiting e TypeScript strict"

# Para otimização de performance  
@nodejs-specialist "API com latência >500ms - analisar bottlenecks e otimizar com profiling"

# Para configuração PNPM
@nodejs-specialist "Migrar projeto de NPM para PNPM com workspace configuration"
```

**Características únicas**:
- 🟢 **Stack JavaScript completa**: Complementa react-developer para full-stack JS/TS
- ⚡ **Performance-first**: Fastify, clustering, caching, connection pooling  
- 📦 **PNPM expertise**: Modern package management, workspaces, overrides
- 🔒 **Security by design**: JWT, rate limiting, input validation, helmet.js
- 🧪 **Modern testing**: Vitest preferred, supertest integration, coverage thresholds
- 🔍 **Profiling tools**: clinic.js, memory leak detection, event loop monitoring
- 🏗️ **Architecture patterns**: Layered design, dependency injection, microservices

---

## 🔧 Agentes Meta

Agentes para extensão e customização do próprio Sistema Onion:

### **agent-creator-specialist**
**Modelo**: Sonnet | **Prioridade**: Média | **Cor**: Purple

**Especialidades**: Criação de novos agentes especializados, estruturação de frontmatter YAML, boas práticas de agentes

**Quando usar**:
- Criar agente customizado para domínio específico
- Definir especialidade, tools e prompts de um novo agente
- Revisar e melhorar agentes existentes

**Exemplo de uso**:
```bash
@agent-creator-specialist "Criar agente especializado em GraphQL com suporte a Federation"
```

### **command-creator-specialist**
**Modelo**: Sonnet | **Prioridade**: Média | **Cor**: Orange

**Especialidades**: Criação de novos comandos (workflows), estruturação de steps, parâmetros e integrações

**Quando usar**:
- Criar comando customizado para workflow recorrente
- Estruturar novos fluxos para o sistema `.claude/commands/`
- Definir parâmetros e integrações de um novo comando

**Exemplo de uso**:
```bash
@command-creator-specialist "Criar comando para deploy automatizado com rollback"
```

---

## 🌿 Agentes de Branch (Git Review)

Agentes especializados em review e validação ao nível de branch, usados como gates antes de merge:

### **branch-code-reviewer**
**Especialidades**: Code review completo de uma branch — analisa todas as mudanças, identifica code smells e sugere melhorias

**Exemplo**: `@branch-code-reviewer "Review da branch feature/jwt-auth"`

### **branch-documentation-writer**
**Especialidades**: Documenta mudanças de uma branch — gera changelog, release notes e atualiza docs técnicas conforme as alterações

**Exemplo**: `@branch-documentation-writer "Documentar mudanças da branch feature/payments"`

### **branch-metaspec-checker**
**Especialidades**: Valida conformidade da branch com as meta-specs arquiteturais — atua como gate keeper para merges estruturais

**Exemplo**: `@branch-metaspec-checker "Validar compliance arquitetural da branch"`

### **branch-test-planner**
**Especialidades**: Define estratégia de testes para uma branch — analisa cobertura existente e identifica gaps antes do merge

**Exemplo**: `@branch-test-planner "Planejar testes para branch feature/auth"`

---

## ⚙️ Como Escolher o Agente Certo

### **Matriz de Decisão Rápida**

| Situação | Agente Recomendado |
|----------|-------------------|
| Não sei por onde começar | `@onion` |
| Criar task estruturada | `@task-specialist` |
| Otimizar ClickUp tecnicamente | `@clickup-specialist` |
| Problemas Git / GitFlow | `@gitflow-specialist` |
| Documentar arquitetura C4 | `@c4-architecture-specialist` |
| Code review geral | `@code-reviewer` |
| Review de branch completa | `@branch-code-reviewer` |
| Testes / TDD | `@test-engineer` |
| Frontend React/Next.js | `@react-developer` |
| Backend Node.js | `@nodejs-specialist` |
| Containers / Docker | `@docker-specialist` |
| PostgreSQL / banco de dados | `@postgres-specialist` |
| Segurança / compliance | `@security-information-master` |
| ISO 27001 | `@iso-27001-specialist` |
| SOC2 | `@soc2-specialist` |
| Estratégia de produto | `@product-agent` |
| Criar novo agente | `@agent-creator-specialist` |
| Criar novo comando | `@command-creator-specialist` |

### **Fluxo de Decisão**

```mermaid
flowchart TD
    A[Preciso de ajuda] --> B{Tipo de problema?}

    B -->|Não sei qual usar| Z[onion]
    B -->|ClickUp| C[clickup-specialist]
    B -->|Git| D[gitflow-specialist]
    B -->|Arquitetura C4| E[c4-architecture-specialist]
    B -->|Code Review| F[code-reviewer]
    B -->|Review de branch| FB[branch-code-reviewer]
    B -->|Testes| G[test-engineer]
    B -->|Produto| H[product-agent]
    B -->|Tasks / decomposição| T[task-specialist]
    B -->|Compliance| I{Qual padrão?}
    B -->|Meta / criar agente| M[agent-creator-specialist]

    I -->|ISO 27001| J[iso-27001-specialist]
    I -->|SOC 2| K[soc2-specialist]
    I -->|PMBOK| L[pmbok-specialist]

    B -->|Desenvolvimento| N{Tecnologia?}
    N -->|React| R[react-developer]
    N -->|Node.js| O[nodejs-specialist]
    N -->|Docker| P[docker-specialist]
    N -->|PostgreSQL| Q[postgres-specialist]
```

### **Por Tipo de Tarefa**

#### **🔧 Desenvolvimento**
```bash
# Frontend React
@react-developer "criar componente de dashboard"

# Backend Node.js
@nodejs-specialist "implementar API REST com Fastify"

# Full-stack (coordenação automática)
/engineer/work "sistema completo de notificações"
```

#### **🧪 Testes**
```bash
# Testes específicos
@test-engineer "testar função de validação de CPF"

# Estratégia de testes
@test-planner "planejar cobertura de testes para módulo auth"
```

#### **🔍 Review**
```bash
# Code review geral
@code-reviewer "revisar implementação de cache Redis"

# Review de branch completa (pre-merge)
@branch-code-reviewer "Review da branch feature/payments"

# Validação arquitetural
@metaspec-gate-keeper "validar uso de microservices"
```

#### **📚 Pesquisa & Docs**
```bash
# Pesquisa tecnológica
@research-agent "comparar Next.js vs Remix para SSR"

# Documentação
@documentation-writer "atualizar docs da API v2"
```

#### **📋 Produto**
```bash
# Gestão de produto
@product-agent "refinar requisitos da feature de chat"

# Decomposição de tasks
@task-specialist "decompor feature de autenticação em subtasks"
```

### **Por Complexidade**

#### **🟢 Tarefa Simples** (1 agente)
```bash
@test-engineer "adicionar testes para função validateEmail"
```

#### **🟡 Tarefa Média** (2-3 agentes sequenciais)
```bash
# Sequência típica:
@research-agent "pesquisar padrões OAuth2"
→ @nodejs-specialist "implementar OAuth2"
→ @test-engineer "testar fluxo OAuth2"
```

#### **🔴 Tarefa Complexa** (múltiplos agentes paralelos)
```bash
/engineer/work "sistema completo de e-commerce"
# → Coordenação automática de múltiplos agentes
```

### **Boas Práticas de Invocação**

```bash
# Use o agente mais específico disponível
# Menos específico:
@code-reviewer "Como fazer autenticação?"
# Mais específico:
@nodejs-specialist "Como implementar JWT com refresh tokens em Node.js?"

# Forneça contexto adequado
# Vago:
@clickup-specialist "Ajuda com tasks"
# Concreto:
@clickup-specialist "Como criar hierarquia de tasks com parent/child via bulk API?"

# Combine agentes para workflows completos
@task-specialist "Decompor feature"
@c4-architecture-specialist "Documentar arquitetura"
@test-engineer "Criar estratégia de testes"

# Workflow completo com comandos
/product/task "Nova feature"
@task-specialist "Refinar decomposição"
/engineer/start feature-name
@c4-architecture-specialist "Documentar decisões"
```

### **Por Prioridade do Modelo**

#### **🚀 Sonnet (Eficiência)**
- `react-developer`, `nodejs-specialist`, `test-engineer`, `research-agent`, `task-specialist`
- Tarefas de implementação diretas
- Testes e validações
- Pesquisa e documentação

#### **🎯 Opus (Análise Complexa)**
- `code-reviewer`, `metaspec-gate-keeper`, `product-agent`
- Decisões arquiteturais críticas
- Reviews complexos
- Coordenação de produto

### **Coordenação Multi-Agente**
```mermaid
graph TD
    A[Task Complexa] --> B[Análise de Requisitos]
    B --> C{Múltiplos Domínios?}
    C -->|Sim| D[Coordenador Principal]
    C -->|Não| E[Agente Especializado]
    D --> F[nodejs-specialist]
    D --> G[react-developer]
    D --> H[test-engineer]
    F --> I[Sincronização]
    G --> I
    H --> I
    I --> J[Resultado Final]
```

---

## 📊 Combinações Eficazes

### **Workflows Recomendados**
1. **Feature Development**: `product-agent` → `task-specialist` → `nodejs-specialist` / `react-developer` → `test-engineer` → `code-reviewer`
2. **Bug Fix**: `research-agent` → `nodejs-specialist` → `test-engineer`
3. **Refactoring**: `code-reviewer` → `metaspec-gate-keeper` → `nodejs-specialist`
4. **Pre-Merge**: `branch-code-reviewer` → `branch-metaspec-checker` → `branch-test-planner`
5. **Compliance**: `security-information-master` → `iso-27001-specialist` / `soc2-specialist` → `iso-22301-specialist`

### **Especialização vs Generalização**

#### **🎯 Alta Especialização**
- `test-engineer`: Foco exclusivo em testes
- `metaspec-gate-keeper`: Validação arquitetural apenas
- `documentation-writer`: Só documentação
- `task-specialist`: Só decomposição de tasks

#### **🔄 Especialização Média**
- `nodejs-specialist`: Node.js + TypeScript backend
- `react-developer`: React + ecosistema frontend
- `research-agent`: Pesquisa + análise

#### **🌐 Mais Generalista**
- `code-reviewer`: Qualquer linguagem/framework
- `product-agent`: Gestão geral de produto
- `onion`: Orquestrador de todo o sistema

---

## 💡 Melhores Práticas

### **Para Máxima Eficiência**
1. Use agentes específicos para tarefas claras
2. Deixe o sistema coordenar tarefas complexas (`@onion` ou `/engineer/work`)
3. Combine sequencialmente para workflows de feature
4. Use `@task-specialist` antes de iniciar implementação para decompor bem o escopo

### **Para Qualidade**
1. Sempre use `@code-reviewer` antes de PRs importantes
2. Valide com `@metaspec-gate-keeper` mudanças arquiteturais
3. Inclua `@test-engineer` em features críticas
4. Use `@documentation-writer` para manter docs sincronizados
5. Use os agentes `@branch-*` como gate automático antes de merge

### **Para Produtividade**
1. Use `@onion` quando não souber qual agente ou comando escolher
2. Agentes especializados respondem mais rápido e melhor que o agente genérico
3. Reutilize padrões de combinação que funcionam (ver Combinações Eficazes acima)
4. Para compliance, deixe `@security-information-master` orquestrar — evita ativar specialists desnecessários

---

**Próximo**: [Getting Started →](getting-started.md)

---

## 🔗 Documentos Relacionados

- [inventory.md](inventory.md) — contagens canônicas SSOT por categoria
- [commands-guide.md](commands-guide.md) — comandos que invocam agentes
- [engineering-flows.md](engineering-flows.md) — workflows de desenvolvimento com agentes
