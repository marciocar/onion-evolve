# 📚 Índice Central de Documentação

> **Última atualização**: 2026-07-03 | **Gerado por**: `/docs:build-index` | **Contagens**: rescaneadas do filesystem

Bem-vindo ao índice central de documentação do projeto. Este documento serve como hub de navegação para toda a documentação disponível.

---

## 🎯 Visão Geral

Este projeto é o **Sistema Onion** — um framework de comandos `.claude/` para uso interno com:

- 🤖 **95 comandos invocáveis** Claude Code em 10 categorias + root (+ 24 fragmentos compartilhados em `common/` e 10 READMEs de categoria)
- 🎯 **51 agentes de IA especializados** em 9 categorias
- 🧩 **5 skills** em `.claude/skills/` (`onion` — cérebro do sistema; `onion-patterns`; `onion-validation`; `language-standards`; `onion-orchestration` — orquestração de subagentes)
- 📚 **Knowledge Bases estruturadas** para consumo por IA (49 documentos de conteúdo + KB viva `agentic-patterns/`)
- 🧅 **Skill + Comando `/onion`** — ponto de entrada inteligente com ativação automática
- 🔗 **Task Manager Abstraction** plugável (Jira, ClickUp, Asana, Linear)
- 🏗️ **Spec as Code Multi-Context** — business, technical, compliance (peer) + design (provisório, gated)

---

## 📊 Estatísticas da Documentação

### Documentação Principal
- **213 arquivos markdown** em `docs/`
- **17 arquivos** em `docs/onion/` (Sistema Onion)
- **54 arquivos** em `docs/knowledge-base/` (Knowledge Bases: 49 documentos de conteúdo + `index.md` + 4 READMEs de (sub)categoria)
  - 25 em `concepts/` (Conceitos fundamentais)
  - 8 em `frameworks/` (Frameworks e metodologias)
  - 4 em `tools/` (Ferramentas, incl. Agent Skills)
  - 2 em `platforms/`, 1 em `patterns/`, 1 em `architectures/`, 2 em `meta/`
  - 6 em `agentic-patterns/` (KB viva do campo: harness/ai-strategies/field-observations) + 4 READMEs
  - 1 `index.md`
- **6 arquivos** em `docs/meta-specs/` (Meta Especificações: 5 meta-specs L0 + `index.md`)
- **7 arquivos** em `docs/materials/` (materiais derivados externos — Fase 4): landing page, manual, case studies, brand book, artigo crítico, press kit, README
- **7 arquivos** em `docs/applying/` (guias de aplicação: greenfield, legacy, regulado, adoption-lifecycle, manual, rescue-prompt)
- **7 arquivos** em `docs/design-context/` (vertical de design, **provisória** — ver nota abaixo)
- **55 arquivos** em `docs/analysis/` (análises ativas — ver [analysis/README.md](analysis/README.md) para o critério de retenção; só baselines/ADRs duráveis são navegados individualmente aqui)
- **3 contextos spec-as-code peer** (templates no framework, populados no projeto-alvo): `docs/business-context/`, `docs/technical-context/`, `docs/compliance-context/` (1 `README.md` cada, ainda sem conteúdo gerado neste repo)

### Sistema Onion (`.claude/`)
- **95 comandos invocáveis** Claude Code distribuídos em:
  - 29 em `meta/` (meta-comandos, criadores, validação, orquestração de subagentes, frescor de KB e de contexto, federação, adoção e co-evolução)
  - 21 em `product/` (gestão de produto e descoberta)
  - 11 em `engineer/` (engenharia e desenvolvimento)
  - 11 em `docs/` (geração e validação de documentação)
  - 6 em `validate/` (validação e testes — inclui subpastas `collab/`, `qa-points/`, `test-strategy/`)
  - 6 em `git/` (GitFlow e versionamento)
  - 3 em `test/` (unit, integration, e2e)
  - 2 em `design/`, 1 em `development/`, 1 em `quick/`
  - 3 no root: `onion.md`, `warm-up.md`, `catch-up.md`
  - **não-invocáveis**: 24 fragmentos em `common/` (11 templates + 13 prompts, incl. READMEs) e 10 READMEs de categoria
- **5 skills** em `.claude/skills/` (`onion`, `onion-patterns`, `onion-validation`, `language-standards`, `onion-orchestration`)
- **51 agentes** IA distribuídos em:
  - 20 em `development/` (frontend, backend, infra, integrações)
  - 9 em `product/` (gestão e narrativa)
  - 5 em `compliance/` (ISO 27001, ISO 22301, SOC2, PMBOK, governance)
  - 5 em `meta/` (orquestração, criação, validação, skills)
  - 5 em `git/` (review pré-PR)
  - 3 em `testing/`, 2 em `review/`
  - 1 em `research/`, 1 em `deployment/`

### Total
- **213 arquivos** de documentação markdown em `docs/`
- **95 comandos invocáveis** em 10 categorias + root (+ 24 fragmentos `common/` + 10 READMEs de categoria)
- **51 agentes** especializados em 9 categorias
- **5 skills** (`.claude/skills/`)

---

## 📁 Estrutura de Documentação

```
docs/
├── INDEX.md                    # Este arquivo (hub central)
│
├── onion/                      # Sistema Onion (17 arquivos)
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
│   ├── co-evolution-reference.md # Cartão de referência da família evolve/co-evolve
│   ├── graph.md                # Grafo de relações do sistema
│   ├── testing-validation-system.md  # Sistema de testes e validação
│   ├── claude-code-commands-architecture.md  # Arquitetura de comandos
│   ├── end-to-end-validation-tests.md  # Testes de validação E2E
│   ├── ESPERANTO.md            # documento do framework
│   └── sistema-engenharia-reversa-guia-uso.md  # Engenharia reversa
│
├── knowledge-base/             # Knowledge Bases (54 arquivos, incl. index)
│   ├── concepts/               # Conceitos fundamentais (25 arquivos)
│   ├── frameworks/             # Frameworks e metodologias (8 arquivos)
│   ├── platforms/              # Plataformas e tecnologias (2 arquivos)
│   ├── tools/                  # Ferramentas e recursos (4 arquivos)
│   ├── patterns/               # Padrões de implementação (1 arquivo)
│   ├── architectures/          # C4 + ADR (1 arquivo)
│   ├── meta/                   # Criação de comandos + identidade/produto (2 arquivos)
│   └── agentic-patterns/       # KB viva: IA + harness (6 docs + 4 READMEs)
│       ├── harness/            #   Internals de harnesses específicos
│       ├── ai-strategies/      #   Padrões de guiar o transformer
│       └── field-observations/ #   Observações brutas do campo
│
├── meta-specs/                 # Meta Especificações (6 arquivos — constituição L0)
│   ├── index.md                # Índice de meta specs
│   ├── agents.md                # Padrões obrigatórios para agentes
│   ├── commands.md              # Padrões para comandos + workflows faseados (invariante)
│   ├── architecture.md          # Estrutura de diretórios, framework instalável
│   ├── code-standards.md        # Idioma, formatação, naming, estilo
│   └── integrations.md          # Task Manager Abstraction, padrão de adapter, MCPs
│
├── design-context/              # Vertical de design (7 arquivos — PROVISÓRIO, gated)
│   ├── README.md                # O que é + princípios (SSOT viva, tokens W3C/DTCG)
│   ├── index.md                 # Hub navegável + frescor
│   ├── brief.md                 # Brief de identidade visual
│   ├── foundations/*.tokens.json
│   ├── semantic/*.tokens.json
│   ├── governance/contrast-pairs.json  # SSOT das regras WCAG de contraste
│   └── decisions/                # ADRs de design
│
├── analysis/                   # Análises ativas (55 arquivos; ver analysis/README.md — ciclo de vida e critério de retenção)
│
├── applying/                    # Guias de aplicação (7 arquivos)
│   ├── README.md · adoption-lifecycle.md · applying-greenfield.md
│   ├── applying-legacy.md · applying-regulated.md
│   └── onion-adoption-manual.md · rescue-prompt.md
│
├── materials/                  # Materiais derivados externos (Fase 4 — 7 arquivos)
│   ├── README.md               # Índice e guia de uso dos materiais
│   ├── landing-page.md         # Esqueleto da landing page
│   ├── manual-toc.md           # Sumário do manual técnico
│   ├── case-studies.md         # 3 case studies desenvolvidos
│   ├── brand-book.md           # Brand book derivado do design-context
│   ├── critical-article-outline.md  # Outline de artigo crítico
│   └── press-kit.md            # One-pager, FAQ imprensa, bio, citações
│
├── evolution/                   # Co-evolução core↔derivados (doc-bridge)
│   ├── README.md                # Modelo dos 3 fluxos (downstream/upstream/handoff)
│   ├── trust-log.md             # Ledger de confiança da federação
│   ├── trial-object-led-discovery-fitting.md
│   ├── federation/              # members.yaml, CHANGELOG.md, outbox/ (staging de anúncios)
│   ├── inbox/                   # Canal upstream (sinal/feedback de projetos) + _processed/
│   └── rfc/                     # RFCs do protocolo de co-evolução
│
├── sdaal/                       # Specification-Driven AI Abstraction Layer
│   └── sdaal.md
│
└── business-context/ · technical-context/ · compliance-context/
    # 3 contextos spec-as-code PEER — templates no framework (só README.md),
    # populados no projeto-alvo por /docs:build-*-docs
```

---

## 🧅 Sistema Onion

### 📖 Documentação Principal

#### Guias Essenciais
- **[Guia de Comandos](onion/commands-guide.md)** - Documentação completa de todos os comandos disponíveis
- **[Referência de Agentes](onion/agents-reference.md)** - Lista e descrição de todos os agentes especializados
- **[Fluxos de Engenharia](onion/engineering-flows.md)** - Workflows detalhados para desenvolvimento
- **[Co-evolução — Cartão de Referência](onion/co-evolution-reference.md)** - Família de comandos `evolve`/`co-evolve`/`co-announce`/`co-deliver`/`co-relay`/`federation-*` com quem-executa × direção do dado
- **[Sistema de Testes e Validação](onion/testing-validation-system.md)** - Framework completo de testes e validação
- **[Grafo do Sistema](onion/graph.md)** - Grafo de relações entre comandos, agentes e KBs

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

Knowledge Bases estruturadas para consumo por IA e referência técnica — índice completo e sempre fresco em **[knowledge-base/index.md](knowledge-base/index.md)**. Resumo por categoria:

- **[Conceitos Fundamentais](knowledge-base/index.md#-conceitos-fundamentais-25)** (25) — Domain Context Lifecycle, Task Manager Abstraction, Spec-as-Code/Driven Development, SDAAL, Agent Orchestration, Onion Dogfooding Doctrine, Onion Engine Economy, Onion Relation Vocabulary, Onion Working Method, Knowledge Graph SDAAL, Secret Handling (Agent), Federation Usage Modes, Decision Snapshot Retention, e mais
- **[Frameworks e Metodologias](knowledge-base/index.md#-frameworks-e-metodologias-8)** (8) — GitFlow, Story Points, Framework de Testes, Collaborative Testing, Test Strategy Scoring
- **[Plataformas](knowledge-base/index.md#-plataformas-2)** (2) — Git Ledger as Working Dir, Runflow
- **[Ferramentas](knowledge-base/index.md#-ferramentas-4)** (4) — Agent Skills, Claude Code Commands Best Practices, Docker, Whisper
- **[Patterns](knowledge-base/index.md#-patterns-1)** (1) — SDAAL Examples
- **[Architectures](knowledge-base/index.md#-architectures-1)** (1) — C4 + ADR Patterns
- **[Meta](knowledge-base/index.md#-meta-2)** (2) — Command Creation Patterns, Onion Framework Identity
- **[Agentic Patterns](knowledge-base/index.md#-agentic-patterns-6)** (6, KB viva) — internals de harness, estratégias de guiar o transformer, observações brutas do campo

**Localização:** `docs/knowledge-base/`

---

## 🏗️ Meta Especificações

Especificações de nível mais alto que servem como "constituição" do Sistema Onion. **As 5 meta-specs L0 foram criadas em 2026-05-18** como parte do saneamento e ativam a validação via `@metaspec-gate-keeper`:

- **[Índice de Meta Specs](meta-specs/index.md)** - Visão geral das meta especificações
- **[agents.md](meta-specs/agents.md)** - Padrões obrigatórios para agentes (YAML, categorias, naming, limites)
- **[commands.md](meta-specs/commands.md)** - Padrões para comandos + **workflows faseados como invariante**
- **[architecture.md](meta-specs/architecture.md)** - Estrutura de diretórios, framework instalável, dependências
- **[code-standards.md](meta-specs/code-standards.md)** - Idioma, formatação, naming, estilo
- **[integrations.md](meta-specs/integrations.md)** - Task Manager Abstraction como referência canônica, padrão de adapter, MCPs

**Localização:** `docs/meta-specs/`

---

## 🎨 Design Context (provisório)

Vertical de design incubada como candidata a **4º contexto de domínio peer** (ao lado de business/technical/compliance) — promoção formal gated por evidência de ritmo distinto via `/meta:context-freshness` (ver [ADR](design-context/decisions/onion-adr-design-peer-promotion.md)).

- **[README](design-context/README.md)** - O que é, princípios (SSOT tokens W3C/DTCG, cascata core→semantic→brand→product→mode)
- **[Índice](design-context/index.md)** - Hub navegável + frescor

**Localização:** `docs/design-context/`

---

## 🚀 Aplicação em Projetos-alvo

Guias de aplicação do Onion em projetos novos, legados ou regulados:

- **[Guias de Aplicação — README](applying/README.md)** - Visão geral e árvore de decisão
- **[Ciclo de Vida da Adoção](applying/adoption-lifecycle.md)** - Fases da adoção, do primeiro contato ao steady-state
- **[Onion em Projeto Novo (Greenfield)](applying/applying-greenfield.md)** - Passo a passo desde `git init`
- **[Onion em Projeto Legado](applying/applying-legacy.md)** - Engenharia reversa + migração gradual
- **[Onion em Projeto Regulado](applying/applying-regulated.md)** - ISO 27001, ISO 22301, SOC2, PMBOK
- **[Manual de Adoção](applying/onion-adoption-manual.md)** - Referência operacional de `/meta:adopt`
- **[Rescue Prompt](applying/rescue-prompt.md)** - Prompt de resgate para adoções travadas

---

## 🌐 Materiais Externos

Esqueletos de materiais externos derivados da KB canônica de identidade ([onion-framework-identity.md](knowledge-base/meta/onion-framework-identity.md), SSOT):

- **[Materiais — README](materials/README.md)** - Índice e mapa de uso (KB → material) por perfil
- **[Landing Page](materials/landing-page.md)** - Esqueleto de 7 seções (hero → CTA)
- **[Manual — Sumário](materials/manual-toc.md)** - TOC de 11 capítulos (conteúdo existente ✅ / a escrever 🔲)
- **[Estudos de Caso](materials/case-studies.md)** - 3 casos desenvolvidos (Federation v2, /meta:evolve, Cursor→Native)
- **[Brand Book](materials/brand-book.md)** - Derivado do `design-context/` (tokens → identidade aplicada)
- **[Artigo Crítico — Outline](materials/critical-article-outline.md)** - Análise honesta (trade-offs, perguntas duras)
- **[Press Kit](materials/press-kit.md)** - One-pager, FAQ imprensa, bio, citações

---

## 🔄 Co-evolução (Federação core↔derivados)

Modelo de co-evolução entre este core (`onion-evolve`) e projetos que adotaram o framework:

- **[README — 3 fluxos](evolution/README.md)** - downstream (core→projetos) · upstream (projetos→core) · handoff (dentro do repo)
- **[Trust Log](evolution/trust-log.md)** - ledger de confiança da federação (pins, verificações)
- **`federation/members.yaml`** - registro de adotantes, pins, lineages
- **`federation/CHANGELOG.md`** - anúncios de mudanças relevantes aos adotantes
- **`inbox/`** - canal upstream (sinal/feedback de projetos, `_processed/` = já triado)
- **Comandos**: `/meta:co-evolve` (orientação), `/meta:co-announce` (produzir anúncio), `/meta:co-relay`/`/meta:co-deliver` (transporte local same-machine)

**Localização:** `docs/evolution/`

---

## 📊 Análises

> **Ciclo de vida** (ver [analysis/README.md](analysis/README.md)): análises e planos são **efêmeros** — uma vez executados, são removidos (git é o arquivo). Este hub navega apenas os **baselines/ADRs duráveis**; a lista completa (55 arquivos nesta pasta) e o critério de retenção vivem em `analysis/README.md` — SSOT para não duplicar uma lista que fica obsoleta a cada sessão.

**Baselines ativos (referenciados por comandos/constituição):**
- **[Revisão Analítica do Sistema Onion — Maio/2026](analysis/onion-review-2026-05.md)** — SSOT de identidade, citada por `CLAUDE.md`.
- **[Baseline de Verificação e Validação — Junho/2026](analysis/onion-vv-baseline-2026-06.md)** — usada por `/meta:evolve`.
- **[Onion Evolution — mais recente](analysis/onion-evolution-2026-06-25.md)** — última auditoria geral (ponto de comparação da próxima rodada).
- **[Onion Federation Audit — 2026-07-01](analysis/onion-federation-audit-2026-07-01.md)** — auditoria focada em federação.
- **[Parecer — Duas linhagens no rhilo — Julho/2026](analysis/onion-parecer-rhilo-lineages-2026-07.md)** — D1/D2 executados; D3 (KG dogfood) e D4 (merge total) pendentes.

**ADRs duráveis (nunca removidos, só *superseded*)** — lista completa e atualizada em [analysis/README.md](analysis/README.md#o-que-permanece-baselines-ativos): adoção de repo, A2A format-vs-runtime, domain-context-lifecycle, PFR, ledger format/location, vocabulário de fluxos de co-evolução, "adota não impõe", branching agnóstico, SLM-as-tool, object-led-discovery, e outros — **13 ADRs ativos** ao todo nesta rodada de scan.

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
4. [Knowledge Base - Spec-Driven Development](knowledge-base/concepts/spec-driven-development.md)

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
- Knowledge Bases: [SDAAL](knowledge-base/concepts/specification-driven-ai-abstraction-layer.md), [Spec-Driven Development](knowledge-base/concepts/spec-driven-development.md)

### 🎨 Para Design

**Comece com:**
1. [Design Context — README](design-context/README.md)
2. `/design` (comandos de geração/validação de design system)

**Recursos:**
- Agente: `@design-system-specialist`
- SSOT: `docs/design-context/` (tokens W3C/DTCG)

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
| 🎨 **Design Context** | `docs/design-context/` | SSOT de identidade visual (provisório) |
| 📊 **Análises** | `docs/analysis/` | Análises e estudos |
| 🔄 **Evolução/Federação** | `docs/evolution/` | Doc-bridge core↔derivados |
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
| 🎨 **Design** | `/design/*` | [Design Context](design-context/README.md) |
| 🧅 **Onion** | `/onion/*` | [Sistema Onion](onion/) |
| ⚡ **Quick** | `/quick/*` | [Guia de Comandos](onion/commands-guide.md) |

### Por Categoria de Agente

| Categoria | Agentes | Documentação |
|-----------|---------|--------------|
| 🛡️ **Compliance** | `compliance/` (5) | [Referência de Agentes](onion/agents-reference.md#️-agentes-de-compliance) |
| 🔴 **Meta** | `meta/` (5) | [Referência de Agentes](onion/agents-reference.md#-agentes-meta) |
| ⚙️ **Deployment** | `deployment/` (1) | [Referência de Agentes](onion/agents-reference.md) |
| 🟣 **Pesquisa** | `research/` (1) | [Referência de Agentes](onion/agents-reference.md#-agentes-de-pesquisa) |
| 🟢 **Review** | `review/` (2) | [Referência de Agentes](onion/agents-reference.md#-agentes-de-review) |

---

## 🔗 Links Rápidos

### Documentação Essencial
- [README Principal](../README.md) - Visão geral do Sistema Onion
- [Guia de Comandos](onion/commands-guide.md) - Todos os comandos
- [Referência de Agentes](onion/agents-reference.md) - Todos os agentes
- [Sistema de Testes e Validação](onion/testing-validation-system.md) - Framework completo
- [Guias de Aplicação](applying/README.md) - Onion em projetos novos, legados ou regulados
- [Co-evolução — README](evolution/README.md) - Modelo core↔derivados

### Knowledge Bases
- [Task Manager Abstraction](knowledge-base/concepts/task-manager-abstraction.md)
- [Framework de Story Points](knowledge-base/frameworks/framework-story-points.md)
- [Framework de Testes](knowledge-base/frameworks/framework-testes.md)
- [AI Agent Design Patterns](knowledge-base/concepts/ai-agent-design-patterns.md)
- [Spec-as-Code Strategy](knowledge-base/concepts/spec-as-code-strategy.md)
- [Spec-Driven Development](knowledge-base/concepts/spec-driven-development.md)
- [Onion Dogfooding Doctrine](knowledge-base/concepts/onion-dogfooding-doctrine.md)
- [Whisper](knowledge-base/tools/whisper.md) - Transcrição de áudio

### Configuração
- [Configuração Inicial](onion/getting-started.md)
- [Guias de Aplicação](applying/README.md)
- [Adapters de Task Manager](../.claude/utils/task-manager/adapters/) (Jira, ClickUp, Asana, Linear)

---

## 🆕 Novidades

### ✨ Documentação Adicionada Recentemente (ciclo 2026-06/07)

- **KB viva `agentic-patterns/`** — como IA + harness colaboram na prática (harness internals, ai-strategies, field-observations); nasceu de observação de campo e cresce com cada dogfood.
- **`design-context/`** — vertical de design incubada como 4º contexto candidato a peer (provisório, gated por `/meta:context-freshness`).
- **Federação com rhilo-metagamify** — primeiro adotante real: parecer de linhagens (D1/D2 executados), correção de pin forjado, KB `secret-handling-agent` e `knowledge-graph-sdaal` (crédito: dogfood do adotante).
- **`onion-dogfooding-doctrine`**, **`onion-engine-economy`**, **`onion-relation-vocabulary`**, **`onion-working-method`** — KBs de doutrina consolidadas nesta janela.

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
/docs/build-index knowledge-base   # Reconstruir índice da seção knowledge-base
```

**Última atualização:** 2026-07-03 (`/docs:build-index` — contagens reescaneadas do filesystem: onion 15→17, knowledge-base 47→54 [+ agentic-patterns], materials 6→7 [brand-book], applying passou a ter contagem própria [7], analysis 24→55 listados [seção reduzida a baselines/ADRs, lista completa delegada a `analysis/README.md`], `design-context/` adicionado como nova seção provisória, commands `meta` 24→29 / `product` 20→21 / `validate` 1→6 [subpastas], `common/` fragments 16→24)
**Mantido por:** Sistema Onion

---

**Sistema Onion** - Multi-Context Development Orchestrator 🧅
