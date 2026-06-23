# 📚 Índice Central de Documentação

> **Última atualização**: 2026-06-16 | **Gerado por**: `/docs:build-index` | **Revisado**: auditoria manual

Bem-vindo ao índice central de documentação do projeto. Este documento serve como hub de navegação para toda a documentação disponível.

---

## 🎯 Visão Geral

Este projeto é o **Sistema Onion** — um framework de comandos `.claude/` para uso interno com:

- 🤖 **88 comandos invocáveis** Claude Code em 10 categorias + root (+ 16 fragmentos compartilhados em `common/` e 3 READMEs)
- 🎯 **50 agentes de IA especializados** em 9 categorias
- 🧩 **5 skills** em `.claude/skills/` (`onion` — cérebro do sistema; `onion-patterns`; `onion-validation`; `language-standards`; `onion-fleet` — orquestração de frota)
- 📚 **Knowledge Bases estruturadas** para consumo por IA
- 🧅 **Skill + Comando `/onion`** — ponto de entrada inteligente com ativação automática
- 🔗 **Task Manager Abstraction** plugável (Jira, ClickUp, Asana, Linear)
- 🏗️ **Spec as Code Multi-Context** — separação entre business, technical e meta-specs

---

## 📊 Estatísticas da Documentação

### Documentação Principal
- **120 arquivos markdown** em `docs/`
- **15 arquivos** em `docs/onion/` (Sistema Onion)
- **37 arquivos** em `docs/knowledge-base/` (Knowledge Bases)
  - 19 arquivos em `concepts/` (Conceitos fundamentais)
  - 8 arquivos em `frameworks/` (Frameworks e metodologias)
  - 4 arquivos em `tools/` (Ferramentas, incl. Agent Skills)
  - 2 em `platforms/`, 1 em `patterns/`, 1 em `architectures/`, 2 em `meta/`
  - 1 `index.md`
- **6 arquivos** em `docs/meta-specs/` (Meta Especificações: 5 meta-specs L0 + `index.md`)
- **6 arquivos** em `docs/materials/` (materiais derivados externos — Fase 4): landing page, manual, case studies, artigo crítico, press kit, README
- Arquivos adicionais em `docs/analysis/`, `docs/plans/`, `docs/applying/`, `docs/sdaal/`
- **3 contextos spec-as-code** (templates no framework, populados no projeto-alvo): `docs/business-context/`, `docs/technical-context/`, `docs/compliance-context/`

### Sistema Onion (`.claude/`)
- **88 comandos invocáveis** Claude Code distribuídos em:
  - 24 em `meta/` (meta-comandos, criadores, validação, orquestração de frota, frescor de KB e de contexto, federação, adoção e co-evolução)
  - 20 em `product/` (gestão de produto e descoberta)
  - 11 em `engineer/` (engenharia e desenvolvimento)
  - 11 em `docs/` (geração e validação de documentação)
  - 6 em `validate/` (validação e testes)
  - 6 em `git/` (GitFlow e versionamento)
  - 3 em `test/` (unit, integration, e2e)
  - 1 em `development/`, 1 em `quick/`
  - 3 no root: `onion.md`, `warm-up.md`, `catch-up.md`
  - **não-invocáveis**: 16 fragmentos em `common/` (5 templates + 11 prompts) e 3 READMEs de categoria
- **5 skills** em `.claude/skills/` (`onion`, `onion-patterns`, `onion-validation`, `language-standards`, `onion-fleet`)
- **49 agentes** IA distribuídos em:
  - 18 em `development/` (frontend, backend, infra, integrações)
  - 9 em `product/` (gestão e narrativa)
  - 5 em `compliance/` (ISO 27001, ISO 22301, SOC2, PMBOK, governance)
  - 5 em `meta/` (orquestração, criação, validação, skills)
  - 5 em `git/` (review pré-PR)
  - 3 em `testing/`, 2 em `review/`
  - 1 em `research/`, 1 em `deployment/`

### Total
- **120 arquivos** de documentação markdown
- **88 comandos invocáveis** em 10 categorias + root (+ 16 fragmentos `common/` + 3 READMEs)
- **50 agentes** especializados em 9 categorias
- **5 skills** (`.claude/skills/`)

---

## 📁 Estrutura de Documentação

```
docs/
├── INDEX.md                    # Este arquivo (hub central)
│
├── onion/                      # Sistema Onion (15 arquivos)
│   ├── index.md                # Índice da seção
│   ├── inventory.md            # SSOT de contagens (gerado por /meta:inventory)
│   ├── commands-guide.md       # Guia completo de comandos
│   ├── agents-reference.md     # Referência de agentes
│   ├── engineering-flows.md    # Fluxos de engenharia
│   ├── practical-examples.md   # Exemplos práticos
│   ├── getting-started.md      # Configuração inicial
│   ├── naming-conventions.md   # Padrões de <feature-slug>
│   ├── maintenance-checklist.md # Guia de manutenção
│   ├── ci.md                   # CI / code-review automatizado
│   ├── testing-validation-system.md  # Sistema de testes e validação
│   ├── claude-code-commands-architecture.md  # Arquitetura de comandos
│   ├── end-to-end-validation-tests.md  # Testes de validação E2E
│   ├── ESPERANTO.md            # documento do framework
│   └── sistema-engenharia-reversa-guia-uso.md  # Engenharia reversa
│
├── knowledge-base/             # Knowledge Bases (36 arquivos, incl. index)
│   ├── concepts/               # Conceitos fundamentais (17 arquivos)
│   │   ├── abstraction-patterns-catalog.md
│   │   ├── agent-fleet-orchestration.md
│   │   ├── ai-agent-design-patterns.md
│   │   ├── branding-posicionamento-marca.md
│   │   ├── configuration-management.md
│   │   ├── consolidated-to-tasks-patterns.md
│   │   ├── context-window-optimization.md
│   │   ├── domain-context-lifecycle.md        # contexto de domínio = SSOT viva (Tijolo 1)
│   │   ├── identificar-precificar-dor-cliente.md
│   │   ├── meeting-transcription-to-knowledge-base.md
│   │   ├── multi-repo-federation.md          # federação (Fases 1-3)
│   │   ├── onion-modernization-doctrine.md   # doutrina de /meta:evolve
│   │   ├── spec-as-code-strategy.md
│   │   ├── spec-driven-development.md
│   │   ├── specification-driven-ai-abstraction-layer.md
│   │   ├── task-manager-abstraction.md
│   │   └── worklog-protocol.md                # contrato de sessão
│   ├── frameworks/             # Frameworks e metodologias (8 arquivos)
│   │   ├── agent-orchestration-landscape-2026.md
│   │   ├── framework-story-points.md
│   │   ├── framework-testes.md
│   │   ├── gitflow-patterns.md
│   │   ├── qa-story-points.md
│   │   ├── collaborative-testing-patterns.md
│   │   ├── test-strategy-scoring.md
│   │   └── spec-driven-development-tools-2025.md
│   ├── platforms/              # Plataformas e tecnologias (2 arquivos)
│   │   ├── git-ledger-as-working-dir.md  # ledger da federação (Fase 0)
│   │   └── runflow.md
│   ├── tools/                  # Ferramentas e recursos (4 arquivos)
│   │   ├── agent-skills.md
│   │   ├── claude-code-commands-best-practices-2026.md
│   │   ├── docker-deployment.md
│   │   └── whisper.md          # Knowledge base do Whisper
│   ├── patterns/               # Padrões de implementação (1 arquivo)
│   │   └── sdaal-examples.md
│   ├── architectures/          # C4 + ADR (1 arquivo)
│   │   └── c4-adr-patterns.md
│   └── meta/                   # Criação de comandos + identidade/produto (2 arquivos)
│       ├── command-creation-patterns.md
│       └── onion-framework-identity.md
│
├── meta-specs/                 # Meta Especificações (6 arquivos — constituição L0)
│   ├── index.md                # Índice de meta specs
│   ├── agents.md               # Padrões obrigatórios para agentes
│   ├── commands.md             # Padrões para comandos + workflows faseados (invariante)
│   ├── architecture.md         # Estrutura de diretórios, framework instalável
│   ├── code-standards.md       # Idioma, formatação, naming, estilo
│   └── integrations.md         # Task Manager Abstraction, padrão de adapter, MCPs
│
├── analysis/                   # Análises ativas (baselines; itens efêmeros são removidos pós-execução — ver analysis/README.md)
│   ├── onion-review-2026-05.md         # SSOT de identidade
│   ├── onion-vv-baseline-2026-06.md    # baseline de V&V (usada por /meta:evolve)
│   ├── onion-evolution-2026-06-16.md   # auditoria mais recente (backlog ativo)
│   ├── onion-evolution-2026-06-15.md   # run citado por materiais/identidade (proof-point retido)
│   ├── onion-federation-adr-a2a-format-interop-2026-06.md  # ADR durável (federação A2A)
│   ├── onion-adr-repo-adoption-2026-06.md  # ADR durável (adoção de repo / /meta:adopt)
│   └── onion-adr-domain-context-lifecycle-2026-06.md  # ADR durável (contexto de domínio = SSOT viva)
│
├── materials/                  # Materiais derivados externos (Fase 4 — 6 arquivos)
│   ├── README.md               # Índice e guia de uso dos materiais
│   ├── landing-page.md         # Esqueleto da landing page
│   ├── manual-toc.md           # Sumário do manual técnico
│   ├── case-studies.md         # 3 case studies desenvolvidos
│   ├── critical-article-outline.md  # Outline de artigo crítico
│   └── press-kit.md            # One-pager, FAQ imprensa, bio, citações
│
├── sdaal/                      # Specification-Driven AI Abstraction Layer
│   └── [documentação SDAAL]
│
└── tools/                      # Ferramentas e recursos
    └── [documentação de ferramentas]
```

---

## 🧅 Sistema Onion

### 📖 Documentação Principal

#### Guias Essenciais
- **[Guia de Comandos](onion/commands-guide.md)** - Documentação completa de todos os comandos disponíveis
- **[Referência de Agentes](onion/agents-reference.md)** - Lista e descrição de todos os agentes especializados
- **[Fluxos de Engenharia](onion/engineering-flows.md)** - Workflows detalhados para desenvolvimento
- **[Sistema de Testes e Validação](onion/testing-validation-system.md)** - Framework completo de testes e validação

#### Integrações e Configuração
- **[Configuração Inicial](onion/getting-started.md)** - Setup completo do sistema
- **[Guias de Aplicação](applying/README.md)** - Aplicar o Onion em projetos novos, legados ou regulados
- Integração com Task Manager (Jira/ClickUp/Asana/Linear): use `/meta:setup-integration` — adapters em `.claude/utils/task-manager/adapters/`

#### Referências Técnicas
- **[Exemplos Práticos](onion/practical-examples.md)** - Casos de uso reais com exemplos
- **Referência de Ferramentas** - rode o comando `/meta:all-tools` para listar (sob demanda) as ferramentas disponíveis no contexto atual
- **[Arquitetura de Comandos](onion/claude-code-commands-architecture.md)** - Estrutura interna dos comandos

#### Documentação Avançada
- **[Testes de Validação E2E](onion/end-to-end-validation-tests.md)** - Testes end-to-end do sistema
- **[Guia de Engenharia Reversa](onion/sistema-engenharia-reversa-guia-uso.md)** - Engenharia reversa de projetos

### 🚀 Início Rápido

**Novo no sistema?** Comece aqui:

1. **[Configuração Inicial](onion/getting-started.md)** - Setup do ambiente
2. **[Guia de Comandos](onion/commands-guide.md)** - Aprenda os comandos principais
3. **[Exemplos Práticos](onion/practical-examples.md)** - Veja casos de uso reais

**Comando de entrada:**
```bash
/onion "Sou novo aqui, me ajude a começar"
```

---

## 📚 Knowledge Bases

Knowledge Bases estruturadas para consumo por IA e referência técnica:

### Conceitos Fundamentais (17 arquivos)
- **Domain Context Lifecycle** - Contexto de domínio como SSOT viva (ciclo CRUD+); pesos derivados, remover/validar como gate ✨ NOVO
- **Task Manager Abstraction** - Abstração de gerenciadores de tarefas
- **Spec-as-Code Strategy** - Estratégia de especificações como código
- **Spec-Driven Development** - Metodologia emergente de desenvolvimento com IA
- **Specification-Driven AI Abstraction Layer** - Camada de abstração orientada a especificações
- **AI Agent Design Patterns** - Padrões de design para agentes IA
- **Agent Fleet Orchestration** - Orquestração de frota: 6 padrões canônicos sobre primitivas nativas
- **Abstraction Patterns Catalog** - Catálogo de padrões de abstração
- **Context Window Optimization** - Otimização de contexto para IA
- **Configuration Management** - Gestão de configurações
- **Consolidated to Tasks Patterns** - Conversão de documentos consolidados em tasks
- **Multi-Repo Federation** - Federação multi-repo (Fases 1-3)
- **Onion Modernization Doctrine** - Doutrina de modernização (`/meta:evolve`)
- **Worklog Protocol** - Contrato de sessão de trabalho
- **Branding e Posicionamento** - Estratégias de marca
- **Identificar e Precificar Dor do Cliente** - Metodologias de produto
- **Meeting Transcription to Knowledge Base** - Processamento de reuniões

### Frameworks e Metodologias (8 arquivos)
- **Agent Orchestration Landscape 2026** - Comparativo de 5 correntes (Anthropic/coding-agents/OSS/enterprise/academia) com verificação adversarial
- **Framework de Story Points** - Estimativas ágeis
- **Framework de Testes** - White-box, Grey-box, Black-box
- **GitFlow Patterns** - Motor GitFlow (branching, releases, versionamento)
- **QA Story Points** - Estimativas de QA
- **Collaborative Testing Patterns** - Three Amigos, pair testing
- **Test Strategy Scoring** - Scoring de estratégia de teste
- **Spec-Driven Development Tools 2025** - Ferramentas e análise

### Plataformas e Tecnologias (2 arquivos)
- **Git Ledger as Working Dir** - Ledger da federação (Fase 0)
- **Runflow** - Documentação da plataforma

### Ferramentas (4 arquivos)
- **Agent Skills** - Formato aberto de skills para agentes IA
- **Claude Code Commands Best Practices 2026** - Boas práticas de comandos Claude Code
- **Docker Deployment** - Containerização e deploy
- **Whisper** - Sistema de transcrição de áudio (OpenAI)

**Localização:** `docs/knowledge-base/`

---

## 🏗️ Meta Especificações

Especificações de nível mais alto que servem como "constituição" do Sistema Onion. **As 5 meta-specs L0 foram criadas em 2026-05-18** como parte do saneamento e ativam a validação via `@metaspec-gate-keeper`:

- **[Índice de Meta Specs](meta-specs/index.md)** - Visão geral das meta especificações
- **[agents.md](meta-specs/agents.md)** ✨ NOVO - Padrões obrigatórios para agentes (YAML, categorias, naming, limites)
- **[commands.md](meta-specs/commands.md)** ✨ NOVO - Padrões para comandos + **workflows faseados como invariante**
- **[architecture.md](meta-specs/architecture.md)** ✨ NOVO - Estrutura de diretórios, framework instalável, dependências
- **[code-standards.md](meta-specs/code-standards.md)** ✨ NOVO - Idioma, formatação, naming, estilo
- **[integrations.md](meta-specs/integrations.md)** ✨ NOVO - Task Manager Abstraction como referência canônica, padrão de adapter, MCPs

**Localização:** `docs/meta-specs/`

---

## 🚀 Aplicação em Projetos-alvo

Guias de aplicação do Onion em projetos novos, legados ou regulados:

- **[Guias de Aplicação — README](applying/README.md)** ✨ NOVO - Visão geral e árvore de decisão
- **[Onion em Projeto Novo (Greenfield)](applying/applying-greenfield.md)** ✨ NOVO - Passo a passo desde `git init`
- **[Onion em Projeto Legado](applying/applying-legacy.md)** ✨ NOVO - Engenharia reversa + migração gradual
- **[Onion em Projeto Regulado](applying/applying-regulated.md)** ✨ NOVO - ISO 27001, ISO 22301, SOC2, PMBOK

---

## 🌐 Materiais Externos

Esqueletos de materiais externos derivados da KB canônica de identidade ([onion-framework-identity.md](knowledge-base/meta/onion-framework-identity.md), SSOT):

- **[Materiais — README](materials/README.md)** - Índice e mapa de uso (KB → material) por perfil
- **[Landing Page](materials/landing-page.md)** - Esqueleto de 7 seções (hero → CTA)
- **[Manual — Sumário](materials/manual-toc.md)** - TOC de 11 capítulos (conteúdo existente ✅ / a escrever 🔲)
- **[Estudos de Caso](materials/case-studies.md)** - 3 casos desenvolvidos (Federation v2, /meta:evolve, Cursor→Native)
- **[Artigo Crítico — Outline](materials/critical-article-outline.md)** - Análise honesta (trade-offs, perguntas duras)
- **[Press Kit](materials/press-kit.md)** - One-pager, FAQ imprensa, bio, citações

---

## 📊 Análises

> **Ciclo de vida** (ver [analysis/README.md](analysis/README.md)): análises e planos são **efêmeros** — uma vez executados, são removidos (git é o arquivo). Permanecem apenas os **baselines ativos** abaixo. As retrospectivas P1/T2.6/T3.2, o plano de saneamento e a análise de vendor Unleash foram **executados/curados e removidos em 2026-06-14** (recuperáveis via git history).

- **[Revisão Analítica do Sistema Onion — Maio/2026](analysis/onion-review-2026-05.md)** — SSOT de identidade: documenta o abandono de `.onion/`, plano v4.0 e `packages/onion-cli/`; sintetiza as análises-fonte de 2025.
- **[Baseline de Verificação e Validação — Junho/2026](analysis/onion-vv-baseline-2026-06.md)** — baseline de V&V (tamanhos + conformidade de plataforma); usada por `/meta:evolve`.
- **[Onion Evolution — 2026-06-16](analysis/onion-evolution-2026-06-16.md)** — auditoria de evolução **mais recente** (backlog ativo: ~20 acionáveis; sistêmicos = MCP-first ainda aberto, categorias fantasma, ambiguidade de threshold de tamanho).
- **[Onion Evolution — 2026-06-15](analysis/onion-evolution-2026-06-15.md)** — run **retido como proof-point** citado por materiais/identidade (métricas §0: 28 agentes · 1.27M tokens · ~26 min · 30 achados). Não é o backlog ativo.
- **[ADR — A2A formato vs runtime — Junho/2026](analysis/onion-federation-adr-a2a-format-interop-2026-06.md)** — decisão durável: linha vermelha A2A partida (runtime proibido / formato permitido como projeção one-way).
- **[ADR — Adoção de repositório — Junho/2026](analysis/onion-adr-repo-adoption-2026-06.md)** — decisão durável: adoção = comando in-platform `/meta:adopt` (não CLI); stamp de versão; rampa da federação.
- **[ADR — Contexto de domínio: SSOT viva — Junho/2026](analysis/onion-adr-domain-context-lifecycle-2026-06.md)** — decisão durável: contexto de domínio = SSOT viva com ciclo CRUD+ (não snapshot); 3 domínios peer + critério de promoção; pesos derivados; camada *Manage* executável = Tijolo 2.
- **[Revisão da Federação — Junho/2026](analysis/onion-federation-review-2026-06.md)** — federação multi-repo do Onion vs. A2A e padrões de coordenação multi-agente (jun/2026): alinhamento mainstream + por que não A2A vivo + recomendações de nomenclatura/interop.

---

## 🧭 Navegação por Perfil

### 👨‍💻 Para Desenvolvedores

**Comece com:**
1. [Configuração Inicial](onion/getting-started.md)
2. [Guia de Comandos](onion/commands-guide.md) - Seção "Comandos de Engenharia"
3. [Fluxos de Engenharia](onion/engineering-flows.md)
4. [Sistema de Testes e Validação](onion/testing-validation-system.md)

**Comandos essenciais:**
- `/engineer/start` - Iniciar desenvolvimento
- `/engineer/work` - Trabalhar em feature
- `/engineer/pr` - Criar Pull Request
- `/test/unit` - Testes unitários
- `/test/integration` - Testes de integração

**Agentes especializados:**
- `@react-developer` - Desenvolvimento React
- `@nodejs-specialist` - Backend Node.js
- `@nx-monorepo-specialist` - Monorepos NX
- `@c4-architecture-specialist` - Arquitetura C4
- `@whisper-specialist` - Transcrição de áudio com Whisper

### 📋 Para Product Owners

**Comece com:**
1. [Guia de Comandos](onion/commands-guide.md) - Seção "Comandos de Produto"
2. [Exemplos Práticos](onion/practical-examples.md)
3. [Knowledge Base - Story Points](knowledge-base/frameworks/framework-story-points.md)
4. [Knowledge Base - Spec-Driven Development](knowledge-base/concepts/spec-driven-development.md) ✨ NOVO

**Comandos essenciais:**
- `/product/task` - Criar tasks estruturadas
- `/product/spec` - Especificações técnicas
- `/product/estimate` - Estimar story points
- `/product/extract-meeting` - Extrair insights de reuniões
- `/product/consolidate-meetings` - Consolidação de múltiplas reuniões
- `/product/convert-to-tasks` - Converter documentos consolidados em tasks
- `/product/whisper` - Facilitador para uso do Whisper
- `/docs/consolidate-documents` - Consolidar múltiplos documentos
- `/validate/collab/three-amigos` - Sessões colaborativas

**Agentes especializados:**
- `@product-agent` - Orquestração de produto
- `@story-points-framework-specialist` - Estimativas ágeis
- `@storytelling-business-specialist` - Narrativas de negócio
- `@branding-positioning-specialist` - Branding e posicionamento
- `@extract-meeting-specialist` - Extração de reuniões
- `@meeting-consolidator` - Consolidação de reuniões

### 🧪 Para QA/Test Engineers

**Comece com:**
1. [Sistema de Testes e Validação](onion/testing-validation-system.md)
2. [Framework de Testes](knowledge-base/frameworks/framework-testes.md)
3. [Guia de Comandos](onion/commands-guide.md) - Seção "Comandos de Validação"

**Comandos essenciais:**
- `/test/unit` - Testes unitários (White-box)
- `/test/integration` - Testes de integração (Grey-box)
- `/test/e2e` - Testes end-to-end (Black-box)
- `/validate/test-strategy/create` - Criar estratégias de teste
- `/validate/qa-points/estimate` - Estimar QA points
- `/validate/collab/pair-testing` - Teste em par

**Agentes especializados:**
- `@test-agent` - Estratégias completas de teste
- `@test-engineer` - Implementação prática
- `@test-planner` - Planejamento e cobertura

### 🏗️ Para Arquitetos

**Comece com:**
1. [Arquitetura de Comandos](onion/claude-code-commands-architecture.md)
2. [Meta Especificações](meta-specs/index.md)
3. [Revisão Analítica do Sistema Onion — Maio/2026](analysis/onion-review-2026-05.md)

**Recursos:**
- Agentes de arquitetura: `@c4-architecture-specialist`, `@mermaid-specialist`
- Comandos de documentação: `/docs/build-tech-docs`, `/docs/reverse-consolidate`
- Knowledge Bases: [SDAAL](knowledge-base/concepts/specification-driven-ai-abstraction-layer.md), [Spec-Driven Development](knowledge-base/concepts/spec-driven-development.md) ✨ NOVO

### 🔧 Para Administradores do Sistema

**Comece com:**
1. [Configuração Inicial](onion/getting-started.md)
2. [Guias de Aplicação](applying/README.md)
3. Referência de Ferramentas — comando `/meta:all-tools`

**Comandos essenciais:**
- `/meta:setup-integration` - Configurar Task Manager (Jira/ClickUp/Asana/Linear) e demais integrações
- `/meta:all-tools` - Listar todas as ferramentas
- `/docs:build-index` - Reconstruir índices

### 🛡️ Para Compliance/Security

**Comece com:**
1. [Agentes de Compliance](onion/agents-reference.md#️-agentes-de-compliance)
2. [Comandos de Validação](onion/commands-guide.md#-comandos-de-validação)

**Agentes especializados:**
- `@iso-27001-specialist` - ISO 27001:2022
- `@iso-22301-specialist` - ISO 22301:2019
- `@soc2-specialist` - SOC2 Type II
- `@security-information-master` - Segurança da informação
- `@corporate-compliance-specialist` - Compliance corporativo

---

## 🗺️ Mapa de Navegação Rápida

### Por Tipo de Documento

| Tipo | Localização | Descrição |
|------|-------------|-----------|
| 📖 **Guias** | `docs/onion/` | Guias de uso e referência |
| 📚 **Knowledge Bases** | `docs/knowledge-base/` | Conhecimento estruturado para IA |
| 🏗️ **Meta Specs** | `docs/meta-specs/` | Especificações de alto nível |
| 📊 **Análises** | `docs/analysis/` | Análises e estudos |
| 📋 **Planos** | `docs/plans/` | Planos de execução |
| 🔧 **SDAAL** | `docs/sdaal/` | Specification-Driven AI Abstraction Layer |
| 🌐 **Materiais Externos** | `docs/materials/` | Landing page, manual, case studies, press kit (Fase 4) |

### Por Categoria de Comando

| Categoria | Comandos | Documentação |
|-----------|---------|--------------|
| 🔧 **Engenharia** | `/engineer/*` | [Guia de Comandos](onion/commands-guide.md#-comandos-de-engenharia) |
| 📋 **Produto** | `/product/*` | [Guia de Comandos](onion/commands-guide.md#-comandos-de-produto) |
| 🧪 **Testes** | `/test/*` | [Sistema de Testes](onion/testing-validation-system.md) |
| ✅ **Validação** | `/validate/*` | [Sistema de Testes](onion/testing-validation-system.md) |
| 📚 **Documentação** | `/docs/*` | [Guia de Comandos](onion/commands-guide.md#-comandos-de-documentação) |
| 🌿 **Git** | `/git/*` | [Guia de Comandos](onion/commands-guide.md#-comandos-git) |
| ⚙️ **Meta** | `/meta/*` | [Guia de Comandos](onion/commands-guide.md#-comandos-meta) |
| 🧅 **Onion** | `/onion/*` | [Sistema Onion](onion/) |
| ⚡ **Quick** | `/quick/*` | [Guia de Comandos](onion/commands-guide.md) |

### Por Categoria de Agente

| Categoria | Agentes | Documentação |
|-----------|---------|--------------|
| 🛡️ **Compliance** | `compliance/` (5) | [Referência de Agentes](onion/agents-reference.md#️-agentes-de-compliance) |
| 🔴 **Meta** | `meta/` (4) | [Referência de Agentes](onion/agents-reference.md#-agentes-meta) |
| ⚙️ **Deployment** | `deployment/` (1) | [Referência de Agentes](onion/agents-reference.md) |
| 🟣 **Pesquisa** | `research/` (1) | [Referência de Agentes](onion/agents-reference.md#-agentes-de-pesquisa) |
| 🟢 **Review** | `review/` (1) | [Referência de Agentes](onion/agents-reference.md#-agentes-de-review) |

---

## 🔗 Links Rápidos

### Documentação Essencial
- [README Principal](../README.md) - Visão geral do Sistema Onion
- [Guia de Comandos](onion/commands-guide.md) - Todos os comandos
- [Referência de Agentes](onion/agents-reference.md) - Todos os agentes
- [Sistema de Testes e Validação](onion/testing-validation-system.md) - Framework completo
- [Guias de Aplicação](applying/README.md) - Onion em projetos novos, legados ou regulados

### Knowledge Bases
- [Task Manager Abstraction](knowledge-base/concepts/task-manager-abstraction.md)
- [Framework de Story Points](knowledge-base/frameworks/framework-story-points.md)
- [Framework de Testes](knowledge-base/frameworks/framework-testes.md)
- [AI Agent Design Patterns](knowledge-base/concepts/ai-agent-design-patterns.md)
- [Spec-as-Code Strategy](knowledge-base/concepts/spec-as-code-strategy.md)
- [Spec-Driven Development](knowledge-base/concepts/spec-driven-development.md) ✨ NOVO
- [Whisper](knowledge-base/tools/whisper.md) - Transcrição de áudio

### Configuração
- [Configuração Inicial](onion/getting-started.md)
- [Guias de Aplicação](applying/README.md)
- [Adapters de Task Manager](../.claude/utils/task-manager/adapters/) (Jira, ClickUp, Asana, Linear)

---

## 🆕 Novidades

### ✨ Documentação Adicionada Recentemente

- **[Spec-Driven Development](knowledge-base/concepts/spec-driven-development.md)** (2025-12-02)
  - Knowledge base completa sobre metodologia emergente
  - Análise de ferramentas (Kiro, Spec-Kit, Tessl)
  - Níveis de implementação (Spec-First, Spec-Anchored, Spec-as-Source)
  - Comparação com TDD, BDD, MDD
  - Benefícios e desafios

- **[Sistema de Testes e Validação](onion/testing-validation-system.md)** (2025-12-02)
  - Framework completo de testes e validação
  - 4 camadas integradas (Knowledge Base, Agentes, Comandos de Teste, Comandos de Validação)
  - Guia completo para desenvolvedores, QA e times cross-funcionais

- **Comandos de Produto Expandidos**
  - `/product/extract-meeting` - Extração inteligente de insights de reuniões
  - `/product/consolidate-meetings` - Consolidação de múltiplas reuniões
  - `/product/convert-to-tasks` - Converter documentos consolidados em tasks
  - `/product/whisper` - Facilitador para uso do Whisper
  - `/docs/consolidate-documents` - Consolidar múltiplos documentos
  - Agente `@meeting-consolidator` - Consolidação avançada de reuniões
  - Agente `@whisper-specialist` - Especialista em transcrição de áudio
  - Knowledge Base Whisper - Documentação completa do Whisper

---

## 📞 Suporte e Recursos

### 🆘 Resolução de Problemas

1. **Comandos**: Consulte [Guia de Comandos](onion/commands-guide.md)
2. **Exemplos**: Veja casos práticos em [Exemplos Práticos](onion/practical-examples.md)
3. **Configuração**: Siga [Configuração Inicial](onion/getting-started.md)
4. **Aplicação em projetos**: Consulte [Guias de Aplicação](applying/README.md)
5. **Testes**: Consulte [Sistema de Testes e Validação](onion/testing-validation-system.md)

### 🔧 Comandos de Debug

```bash
/onion "ajuda"                  # Ponto de entrada inteligente
/meta/all-tools                 # Lista todos os comandos
/docs/build-index               # Reconstruir este índice
@onion "sua pergunta"           # Agente orquestrador master
```

---

## 🔄 Manutenção

Este índice é gerado automaticamente pelo comando `/docs/build-index`.

**Para atualizar:**
```bash
/docs/build-index              # Reconstruir índice principal
/docs/build-index onion        # Reconstruir índice da seção onion
```

**Última atualização:** 2026-06-16 (`/docs:build-index` — contagens reescaneadas do filesystem: concepts 16→17, docs 81→86, frameworks 12→8, tools 2→4, platforms 1→2; remoção de entradas-fantasma do nav de KBs)
**Mantido por:** Sistema Onion

---

**Sistema Onion** - Multi-Context Development Orchestrator 🧅
