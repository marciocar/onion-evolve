# 📚 Índice Central de Documentação

> **Última atualização**: 2026-07-08 | **Gerado por**: `/docs:build-index` (contagens escaneadas do filesystem)

Bem-vindo ao índice central de documentação do projeto. Este documento serve como hub de navegação para toda a documentação disponível.

---

## 🎯 Visão Geral

Este projeto é o **Sistema Onion** — um framework de comandos `.claude/` para uso interno com:

- 🤖 **94 comandos invocáveis** Claude Code em 10 categorias + root
- 🎯 **51 agentes de IA especializados** em 9 categorias
- 🧩 **5 skills** em `.claude/skills/` (`onion` — cérebro do sistema; `onion-patterns`; `onion-validation`; `language-standards`; `onion-orchestration` — orquestração de subagentes)
- 📚 **49 Knowledge Bases** estruturadas para consumo por IA
- 🧅 **Skill + Comando `/onion`** — ponto de entrada inteligente com ativação automática
- 🔗 **Task Manager Abstraction** plugável (Jira, ClickUp, Asana, Linear) + **Forge Abstraction** (GitHub)
- 🏗️ **Spec as Code Multi-Context** — separação entre business, technical, compliance e design-context
- 🌱 **Co-evolução core↔derivados** — canais `docs/evolution/` + federação multi-repo (RFC-0001/0002/0003)

> **Contagens canônicas** vivem em [`docs/onion/inventory.md`](onion/inventory.md) — SSOT gerada do filesystem por `.claude/validation/inventory.sh` e validada no CI. Este índice deriva daquela SSOT; nunca edite números à mão.

---

## 📊 Estatísticas da Documentação

### Documentação Principal (escaneada)
- **193 arquivos markdown** em `docs/`
- **50** em `docs/analysis/` (análises datadas, ADRs duráveis, baselines)
- **50** em `docs/knowledge-base/` (49 KBs + `index.md`)
- **47** em `docs/evolution/` (co-evolução: inbox, federação, RFCs)
- **17** em `docs/onion/` (documentação operacional)
- **7** em `docs/applying/` (guias de adoção)
- **7** em `docs/materials/` (materiais externos derivados)
- **6** em `docs/meta-specs/` (constituição L0: 5 meta-specs + `index.md`)
- **4** em `docs/design-context/` (identidade visual — spec-as-code)
- **1** cada em `docs/business-context/`, `docs/technical-context/`, `docs/compliance-context/` (templates; populados no projeto-alvo)
- **1** em `docs/sdaal/`

### Knowledge Bases por categoria (49, escaneadas)
- **22** em `concepts/` (conceitos fundamentais)
- **9** em `agentic-patterns/` (padrões agênticos, observações de campo, internals do harness)
- **8** em `frameworks/` (frameworks e metodologias)
- **4** em `tools/` (ferramentas)
- **2** em `meta/`, **2** em `platforms/`, **1** em `architectures/`, **1** em `patterns/`

### Sistema Onion (`.claude/`)
- **94 comandos invocáveis** distribuídos em:
  - 29 em `meta/` · 21 em `product/` · 11 em `engineer/` · 11 em `docs/`
  - 6 em `git/` · 6 em `validate/` · 3 em `test/` · 2 em `design/`
  - 1 em `quick/` · 1 em `development/`
  - 3 no root: `onion.md`, `warm-up.md`, `catch-up.md`
  - **não-invocáveis**: fragmentos em `common/` (templates + prompts) e READMEs de categoria
- **51 agentes** IA distribuídos em:
  - 20 em `development/` · 9 em `product/` · 5 em `compliance/` · 5 em `git/` · 5 em `meta/`
  - 3 em `testing/` · 2 em `review/` · 1 em `research/` · 1 em `deployment/`
- **5 skills** em `.claude/skills/` (`onion`, `onion-patterns`, `onion-validation`, `language-standards`, `onion-orchestration`)

---

## 📁 Estrutura de Documentação

```
docs/
├── INDEX.md                    # Este arquivo (hub central)
│
├── onion/                      # Sistema Onion — documentação operacional (17 arquivos)
│   ├── index.md                # Índice da seção
│   ├── inventory.md            # SSOT de contagens (gerado por /meta:inventory)
│   ├── graph.md                # Lente sócio-técnica gerada da spec-as-code (/meta:graph)
│   ├── commands-guide.md       # Guia completo de comandos
│   ├── agents-reference.md     # Referência de agentes
│   ├── co-evolution-reference.md  # Cartão de referência da família evolve/co-evolve/federation
│   ├── engineering-flows.md    # Fluxos de engenharia
│   ├── practical-examples.md   # Exemplos práticos
│   ├── getting-started.md      # Configuração inicial
│   ├── naming-conventions.md   # Padrões de <feature-slug>
│   ├── maintenance-checklist.md # Guia de manutenção
│   ├── ci.md                   # CI / code-review automatizado
│   ├── testing-validation-system.md   # Sistema de testes e validação
│   ├── claude-code-commands-architecture.md  # Arquitetura de comandos
│   ├── end-to-end-validation-tests.md  # Testes de validação E2E
│   ├── ESPERANTO.md            # documento do framework
│   └── sistema-engenharia-reversa-guia-uso.md  # Engenharia reversa
│
├── knowledge-base/             # Knowledge Bases (49 KBs + index)
│   ├── concepts/               # Conceitos fundamentais (22)
│   ├── agentic-patterns/       # Padrões agênticos + observações de campo + harness (9)
│   ├── frameworks/             # Frameworks e metodologias (8)
│   ├── tools/                  # Ferramentas (4)
│   ├── platforms/              # Plataformas (2)
│   ├── meta/                   # Criação de comandos + identidade (2)
│   ├── architectures/          # C4 + ADR (1)
│   └── patterns/               # Padrões de implementação (1)
│
├── meta-specs/                 # Meta Especificações (6 — constituição L0)
│   ├── index.md · agents.md · commands.md · architecture.md · code-standards.md · integrations.md
│
├── evolution/                  # Co-evolução core↔derivados (47 arquivos)
│   ├── README.md               # Protocolo canônico (3 fluxos: downstream/upstream/handoff)
│   ├── inbox/                  # Sinais/feedback upstream (com _processed/)
│   ├── federation/             # Ledger multi-repo (CHANGELOG, outbox, onboarding)
│   ├── rfc/                    # RFC-0001/0002/0003
│   ├── trust-log.md · trial-object-led-discovery-fitting.md
│
├── analysis/                   # Análises datadas, ADRs duráveis, baselines (50)
│
├── applying/                   # Guias de adoção (7)
│   ├── README.md · adoption-lifecycle.md · onion-adoption-manual.md
│   ├── applying-greenfield.md · applying-legacy.md · applying-regulated.md · rescue-prompt.md
│
├── materials/                  # Materiais externos derivados (7)
│   ├── README.md · landing-page.md · manual-toc.md · case-studies.md
│   ├── critical-article-outline.md · press-kit.md · brand-book.md
│
├── design-context/             # Identidade visual — spec-as-code (4)
│   ├── README.md · index.md · brief.md · decisions/onion-adr-design-peer-promotion.md
│
├── business-context/           # Contexto de negócio (template; populado no alvo)
├── technical-context/          # Contexto técnico (template; populado no alvo)
├── compliance-context/         # Contexto de compliance (template; populado no alvo)
└── sdaal/                      # Specification-Driven AI Abstraction Layer
```

---

## 🧅 Sistema Onion

### 📖 Documentação Principal

#### Guias Essenciais
- **[Guia de Comandos](onion/commands-guide.md)** — Documentação completa de todos os comandos
- **[Referência de Agentes](onion/agents-reference.md)** — Lista e descrição de todos os agentes
- **[Fluxos de Engenharia](onion/engineering-flows.md)** — Workflows detalhados para desenvolvimento
- **[Co-evolução — Cartão de Referência](onion/co-evolution-reference.md)** — Família `evolve`/`co-evolve`/`co-announce`/`co-deliver`/`federation-*` (quem-executa × direção do dado)
- **[Grafo Sócio-técnico](onion/graph.md)** — Lente gerada da spec-as-code (impacto reverso, órfãos)
- **[Sistema de Testes e Validação](onion/testing-validation-system.md)** — Framework completo

#### Integrações e Configuração
- **[Configuração Inicial](onion/getting-started.md)** — Setup completo do sistema
- **[Guias de Aplicação](applying/README.md)** — Aplicar o Onion em projetos novos, legados ou regulados
- Integração com Task Manager (Jira/ClickUp/Asana/Linear): use `/meta:setup-integration` — adapters em `.claude/utils/task-manager/adapters/`

#### Referências Técnicas
- **[Exemplos Práticos](onion/practical-examples.md)** — Casos de uso reais
- **Referência de Ferramentas** — rode `/meta:all-tools` para listar (sob demanda) as ferramentas do contexto atual
- **[Arquitetura de Comandos](onion/claude-code-commands-architecture.md)** — Estrutura interna dos comandos

#### Documentação Avançada
- **[Testes de Validação E2E](onion/end-to-end-validation-tests.md)** — Testes end-to-end do sistema
- **[Guia de Engenharia Reversa](onion/sistema-engenharia-reversa-guia-uso.md)** — Engenharia reversa de projetos

### 🚀 Início Rápido

**Novo no sistema?** Comece aqui:

1. **[Configuração Inicial](onion/getting-started.md)** — Setup do ambiente
2. **[Guia de Comandos](onion/commands-guide.md)** — Aprenda os comandos principais
3. **[Exemplos Práticos](onion/practical-examples.md)** — Veja casos de uso reais

**Comando de entrada:**
```bash
/onion "Sou novo aqui, me ajude a começar"
```

---

## 📚 Knowledge Bases

Knowledge Bases estruturadas para consumo por IA e referência técnica. **Localização:** `docs/knowledge-base/`

### Conceitos Fundamentais (22)
- **Domain Context Lifecycle** — Contexto de domínio como SSOT viva (ciclo CRUD+)
- **Task Manager Abstraction** · **Spec-as-Code Strategy** · **Spec-Driven Development**
- **Specification-Driven AI Abstraction Layer (SDAAL)** · **AI Agent Design Patterns** · **Agent Orchestration**
- **Abstraction Patterns Catalog** · **Context Window Optimization** · **Configuration Management**
- **Consolidated to Tasks Patterns** · **Multi-Repo Federation** · **Onion Modernization Doctrine**
- **Onion Dogfooding Doctrine** · **Onion Engine Economy** · **Onion Relation Vocabulary** · **Onion Working Method**
- **Decision Snapshot Retention** · **Worklog Protocol** · **Branding e Posicionamento**
- **Identificar e Precificar Dor do Cliente** · **Meeting Transcription to Knowledge Base**

### Padrões Agênticos (9)
- **AI Strategies** — [breadcrumb-patterns](knowledge-base/agentic-patterns/ai-strategies/breadcrumb-patterns.md), [object-led-discovery](knowledge-base/agentic-patterns/ai-strategies/object-led-discovery.md)
- **Field Observations** — observações de campo datadas (harness-paths, shallow-verification)
- **Harness** — [claude-code-internals](knowledge-base/agentic-patterns/harness/claude-code-internals.md)

### Frameworks e Metodologias (8)
- **Agent Orchestration Landscape 2026** · **Framework de Story Points** · **Framework de Testes**
- **GitFlow Patterns** · **QA Story Points** · **Collaborative Testing Patterns**
- **Test Strategy Scoring** · **Spec-Driven Development Tools 2025**

### Ferramentas (4)
- **Agent Skills** · **Claude Code Commands Best Practices 2026** · **Docker Deployment** · **Whisper**

### Plataformas (2) · Meta (2) · Arquiteturas (1) · Padrões (1)
- **Git Ledger as Working Dir** · **Runflow** · **onion-framework-identity** (SSOT) · **command-creation-patterns**
- **C4 + ADR Patterns** · **SDAAL Examples**

---

## 🏗️ Meta Especificações

Especificações de nível mais alto — a "constituição" do Sistema Onion. As 5 meta-specs L0 (criadas em 2026-05-18) ativam a validação via `@metaspec-gate-keeper`. **Localização:** `docs/meta-specs/`

- **[Índice de Meta Specs](meta-specs/index.md)**
- **[agents.md](meta-specs/agents.md)** — Padrões obrigatórios para agentes (YAML, categorias, naming, limites)
- **[commands.md](meta-specs/commands.md)** — Padrões para comandos + **workflows faseados como invariante**
- **[architecture.md](meta-specs/architecture.md)** — Estrutura de diretórios, framework instalável, dependências
- **[code-standards.md](meta-specs/code-standards.md)** — Idioma, formatação, naming, estilo
- **[integrations.md](meta-specs/integrations.md)** — Task Manager Abstraction como referência canônica, adapters, MCPs

---

## 🌱 Co-evolução e Federação

Canais de evolução core↔derivados e federação multi-repo. **Localização:** `docs/evolution/`

- **[Protocolo de Co-evolução](evolution/README.md)** — 3 fluxos canônicos (downstream / upstream / handoff)
- **[Federation CHANGELOG](evolution/federation/CHANGELOG.md)** — Ledger de contratos multi-repo
- **[RFC-0001 — Co-evolution Comms](evolution/rfc/rfc-0001-co-evolution-comms.md)**
- **[RFC-0002 — Meta-Strategy Verdict](evolution/rfc/rfc-0002-meta-strategy-verdict.md)**
- **[RFC-0003 — Federated Identity & Collective Intelligence](evolution/rfc/rfc-0003-federated-identity-collective-intelligence.md)**
- `inbox/` (sinais upstream) · `federation/outbox/` (staging de anúncios downstream) — geridos por `/meta:co-evolve`

---

## 🎨 Contextos Spec-as-Code

Os contextos de domínio são **spec-as-code** (`architecture.md §1.3`): templates vazios no framework, populados no projeto-alvo.

| Contexto | Gerado por | Estado no framework |
|---|---|---|
| 💼 [`business-context/`](business-context/) | `/docs:build-business-docs` | template (só README) |
| ⚙️ [`technical-context/`](technical-context/) | `/docs:build-tech-docs` | template (só README) |
| 🛡️ [`compliance-context/`](compliance-context/) | `/docs:build-compliance-docs` | template (só README) |
| 🎨 [`design-context/`](design-context/) | `/design:identity`, `/design:generate` | **populado** (brief + ADR de promoção a peer) |

---

## 🚀 Aplicação em Projetos-alvo

Guias de aplicação do Onion. **Localização:** `docs/applying/`

- **[Guias de Aplicação — README](applying/README.md)** — Visão geral e árvore de decisão
- **[Ciclo de Vida da Adoção](applying/adoption-lifecycle.md)**
- **[Manual de Adoção](applying/onion-adoption-manual.md)**
- **[Projeto Novo (Greenfield)](applying/applying-greenfield.md)** — Passo a passo desde `git init`
- **[Projeto Legado](applying/applying-legacy.md)** — Engenharia reversa + migração gradual
- **[Projeto Regulado](applying/applying-regulated.md)** — ISO 27001, ISO 22301, SOC2, PMBOK
- **[Rescue Prompt](applying/rescue-prompt.md)** — Recuperação de repo sem `.claude/`

---

## 🌐 Materiais Externos

Esqueletos derivados da KB canônica de identidade ([onion-framework-identity.md](knowledge-base/meta/onion-framework-identity.md), SSOT). **Localização:** `docs/materials/`

- **[Materiais — README](materials/README.md)** — Índice e mapa de uso (KB → material)
- **[Landing Page](materials/landing-page.md)** · **[Manual — Sumário](materials/manual-toc.md)** · **[Estudos de Caso](materials/case-studies.md)**
- **[Artigo Crítico — Outline](materials/critical-article-outline.md)** · **[Press Kit](materials/press-kit.md)** · **[Brand Book](materials/brand-book.md)**

---

## 📊 Análises

> **Ciclo de vida** (ver [analysis/README.md](analysis/README.md)): análises e planos são **efêmeros** — uma vez executados, são removidos (git é o arquivo). Permanecem baselines ativos e ADRs duráveis. `docs/analysis/` contém atualmente **50 arquivos** (baselines, ADRs, auditorias de evolução, revisões de federação/orquestração).

### Baselines e SSOTs
- **[Revisão Analítica — Maio/2026](analysis/onion-review-2026-05.md)** — SSOT de identidade
- **[Baseline V&V — Junho/2026](analysis/onion-vv-baseline-2026-06.md)** — usada por `/meta:evolve`
- **[Onion Evolution — 2026-06-25](analysis/onion-evolution-2026-06-25.md)** — auditoria de evolução mais recente
- **[Onion Evolution — 2026-06-15](analysis/onion-evolution-2026-06-15.md)** — proof-point citado por materiais/identidade

### ADRs Duráveis (seleção)
- **[A2A formato vs runtime](analysis/onion-federation-adr-a2a-format-interop-2026-06.md)** · **[Adoção de repositório](analysis/onion-adr-repo-adoption-2026-06.md)**
- **[Contexto de domínio: SSOT viva](analysis/onion-adr-domain-context-lifecycle-2026-06.md)** · **[Padrão Faseado Retomável (PFR)](analysis/onion-adr-phased-resumable-pattern-2026-06.md)**
- **[Ledger: formato e localização](analysis/onion-adr-ledger-format-location-2026-06.md)** · **[Vocabulário dos fluxos de co-evolução](analysis/onion-adr-coevolution-flow-naming-2026-06.md)**
- **[Onion adota, não impõe](analysis/onion-adr-adopt-to-not-impose-2026-06.md)** · **[Branching: base agnóstica](analysis/onion-adr-branching-base-agnostic-2026-06.md)**
- **[Object-Led Discovery](analysis/onion-adr-object-led-discovery-2026-07.md)** · **[Toolbox Lifecycle](analysis/onion-adr-toolbox-lifecycle-2026-06.md)** · **[Capability Contract](analysis/onion-adr-capability-contract-2026-06.md)**

> A lista completa (auditorias datadas, revisões de estratégia/federação/orquestração) está no diretório `docs/analysis/`.

---

## 🧭 Navegação por Perfil

### 👨‍💻 Para Desenvolvedores
1. [Configuração Inicial](onion/getting-started.md) → 2. [Guia de Comandos](onion/commands-guide.md) → 3. [Fluxos de Engenharia](onion/engineering-flows.md) → 4. [Sistema de Testes](onion/testing-validation-system.md)

**Comandos:** `/engineer:start` · `/engineer:work` · `/engineer:pr` · `/test:unit` · `/test:integration`
**Agentes:** `@react-developer` · `@nodejs-specialist` · `@nx-monorepo-specialist` · `@c4-architecture-specialist`

### 📋 Para Product Owners
1. [Guia de Comandos](onion/commands-guide.md) → 2. [Exemplos Práticos](onion/practical-examples.md) → 3. [Story Points](knowledge-base/frameworks/framework-story-points.md) → 4. [Spec-Driven Development](knowledge-base/concepts/spec-driven-development.md)

**Comandos:** `/product:task` · `/product:spec` · `/product:estimate` · `/product:extract-meeting` · `/product:consolidate-meetings`
**Agentes:** `@product-agent` · `@story-points-framework-specialist` · `@storytelling-business-specialist` · `@branding-positioning-specialist`

### 🧪 Para QA/Test Engineers
1. [Sistema de Testes](onion/testing-validation-system.md) → 2. [Framework de Testes](knowledge-base/frameworks/framework-testes.md) → 3. [Guia de Comandos](onion/commands-guide.md)

**Comandos:** `/test:unit` · `/test:integration` · `/test:e2e` · `/validate:test-strategy:create` · `/validate:qa-points:estimate`
**Agentes:** `@test-agent` · `@test-engineer` · `@test-planner`

### 🏗️ Para Arquitetos
1. [Arquitetura de Comandos](onion/claude-code-commands-architecture.md) → 2. [Meta Especificações](meta-specs/index.md) → 3. [Revisão Analítica](analysis/onion-review-2026-05.md)

**Recursos:** `@c4-architecture-specialist`, `@mermaid-specialist` · `/docs:build-tech-docs`, `/docs:reverse-consolidate` · KBs [SDAAL](knowledge-base/concepts/specification-driven-ai-abstraction-layer.md), [Spec-Driven Development](knowledge-base/concepts/spec-driven-development.md)

### 🔧 Para Administradores do Sistema
1. [Configuração Inicial](onion/getting-started.md) → 2. [Guias de Aplicação](applying/README.md) → 3. `/meta:all-tools`

**Comandos:** `/meta:setup-integration` · `/meta:all-tools` · `/docs:build-index`

### 🛡️ Para Compliance/Security
1. [Agentes de Compliance](onion/agents-reference.md) → 2. [Comandos de Validação](onion/commands-guide.md)

**Agentes:** `@iso-27001-specialist` · `@iso-22301-specialist` · `@soc2-specialist` · `@security-information-master` · `@corporate-compliance-specialist`

---

## 🗺️ Mapa de Navegação Rápida

### Por Tipo de Documento

| Tipo | Localização | Descrição |
|------|-------------|-----------|
| 📖 **Guias** | `docs/onion/` | Guias de uso e referência operacional |
| 📚 **Knowledge Bases** | `docs/knowledge-base/` | Conhecimento estruturado para IA |
| 🏗️ **Meta Specs** | `docs/meta-specs/` | Constituição L0 |
| 🌱 **Co-evolução** | `docs/evolution/` | Canais core↔derivados + federação |
| 📊 **Análises** | `docs/analysis/` | Análises datadas, ADRs, baselines |
| 🚀 **Aplicação** | `docs/applying/` | Guias de adoção |
| 🌐 **Materiais** | `docs/materials/` | Landing page, manual, case studies, press kit |
| 🎨 **Design** | `docs/design-context/` | Identidade visual (spec-as-code) |
| 🔧 **SDAAL** | `docs/sdaal/` | Abstraction Layer |

### Por Categoria de Comando

| Categoria | Comandos | Documentação |
|-----------|:-------:|--------------|
| ⚙️ **Meta** | 29 | [Guia de Comandos](onion/commands-guide.md) |
| 📋 **Produto** | 21 | [Guia de Comandos](onion/commands-guide.md) |
| 🔧 **Engenharia** | 11 | [Guia de Comandos](onion/commands-guide.md) |
| 📚 **Documentação** | 11 | [Guia de Comandos](onion/commands-guide.md) |
| 🌿 **Git** | 6 | [Guia de Comandos](onion/commands-guide.md) |
| ✅ **Validação** | 6 | [Sistema de Testes](onion/testing-validation-system.md) |
| 🧪 **Testes** | 3 | [Sistema de Testes](onion/testing-validation-system.md) |
| 🎨 **Design** | 2 | [Guia de Comandos](onion/commands-guide.md) |
| ⚡ **Quick** | 1 | [Guia de Comandos](onion/commands-guide.md) |
| 🛠️ **Development** | 1 | [Guia de Comandos](onion/commands-guide.md) |
| 🧅 **Root** | 3 | `onion` · `warm-up` · `catch-up` |

### Por Categoria de Agente

| Categoria | Agentes | Categoria | Agentes |
|-----------|:-------:|-----------|:-------:|
| **development/** | 20 | **testing/** | 3 |
| **product/** | 9 | **review/** | 2 |
| **compliance/** | 5 | **research/** | 1 |
| **git/** | 5 | **deployment/** | 1 |
| **meta/** | 5 | | |

Referência completa: [Referência de Agentes](onion/agents-reference.md)

---

## 🔄 Manutenção

Este índice é gerado pelo comando `/docs:build-index` — **contagens escaneadas do filesystem, nunca hardcoded**.

```bash
/docs:build-index                 # Reconstruir este hub
/docs:build-index knowledge-base  # Reconstruir índice de uma seção
/meta:inventory                   # Regenerar a SSOT de contagens (docs/onion/inventory.md)
```

- **Frescor de conteúdo**: `/meta:kb-freshness` · **Validação**: `/docs:validate-docs`
- **SSOT de contagens**: [`docs/onion/inventory.md`](onion/inventory.md)

**Última atualização:** 2026-07-08 (`/docs:build-index` — filesystem reescaneado: docs 120→193 md; +categoria KB `agentic-patterns` (9); concepts 17→22; +seções `evolution/` (47) e `design-context/` (4); analysis 13→50; commands `meta/` 24→29 e categoria `design/` (2) refletidas da SSOT)
**Mantido por:** Sistema Onion

---

**Sistema Onion** — Multi-Context Development Orchestrator 🧅
