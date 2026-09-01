# 📚 Índice Central de Documentação

> **Última atualização**: 2026-08-03 | **Gerado por**: `/docs:build-index` | **Contagens**: rescaneadas do filesystem

Bem-vindo ao índice central de documentação do projeto. Este documento serve como hub de navegação para toda a documentação disponível.

---

## 🎯 Visão Geral

Este projeto é o **Sistema Onion** — um framework de comandos `.claude/` para uso interno com:

- 🤖 **108 comandos invocáveis** Claude Code em 10 categorias + root (+ 26 fragmentos compartilhados em `common/` e 11 READMEs de categoria)
- 🎯 **51 agentes de IA especializados** em 9 categorias
- 🧩 **12 skills** em `.claude/skills/` (`onion` — cérebro do sistema; `onion-patterns`; `onion-validation`; `language-standards`; `onion-orchestration` — orquestração de subagentes; `onion-{engineering,product,compliance}-context` — resolvers de SSOT por vertical; `onion-wizard` / `onion-onboarding` — a Condução (FAZER × CONHECER); `onion-retro` — retro/feedback como spec-as-code)
- 📚 **93 Knowledge Bases** estruturadas para consumo por IA (+ KB viva `agentic-patterns/` + vertical `education/`)
- 🧅 **Skill + Comando `/onion`** — ponto de entrada inteligente com ativação automática
- 🔗 **Task Manager Abstraction** plugável (Jira, ClickUp, Asana, Linear)
- 🏗️ **Spec as Code Multi-Context** — business, technical, compliance (peer) + design (provisório, gated). Neste repo, `business-context/` **e** `technical-context/` estão **populados como dogfood** (seed real do Onion); `compliance-context/` segue template.

---

## 📊 Estatísticas da Documentação

### Documentação Principal
- **642 arquivos markdown** em `docs/`
- **21 arquivos** em `docs/onion/` (Sistema Onion)
- **92 arquivos** em `docs/knowledge-base/` (Knowledge Bases: 91 KBs — conteúdo + (sub)categoria READMEs — + `index.md`)
  - 50 em `concepts/` (Conceitos fundamentais)
  - 9 em `frameworks/` (Frameworks e metodologias)
  - 6 em `tools/` (Ferramentas, incl. Agent Skills, PostgreSQL e VPS Tool Repo Skeleton)
  - 3 em `platforms/`, 3 em `patterns/`, 1 em `architectures/`, 2 em `meta/`
  - 5 em `education/` (vertical educacional: theories/ + applications/, fonte≠derivação — 4 + 1 README)
  - 12 em `agentic-patterns/` (KB viva do campo: harness/ai-strategies/field-observations — 8 docs + 4 READMEs)
  - 1 `index.md`
- **6 arquivos** em `docs/meta-specs/` (Meta Especificações: 5 meta-specs L0 + `index.md`)
- **10 arquivos** em `docs/materials/` (materiais derivados externos — Fase 4; inclui subpasta `cold-adopter-2026-07/`)
- **7 arquivos** em `docs/applying/` (guias de aplicação: greenfield, legacy, regulado, adoption-lifecycle, manual, rescue-prompt)
- **7 arquivos** em `docs/design-context/` (vertical de design, **provisória** — 4 md + 3 `tokens.json`; ver nota abaixo)
- **125 arquivos** em `docs/analysis/` (análises ativas — ver [analysis/README.md](analysis/README.md) para o critério de retenção; só baselines/ADRs duráveis são navegados individualmente aqui)
- **294 arquivos** em `docs/evolution/` (co-evolução: inbox/inbound, federation/{members,CHANGELOG,outbox}, RFCs)
- **57 arquivos** em `docs/discussions/` (**Constelação de Estudos** — README + estudos isolados por slug; ver nota abaixo)
- **1 arquivo** em `docs/sdaal/` (KB do padrão SDAAL)
- **Contextos spec-as-code peer**: `docs/business-context/` (15 arquivos — 13 de conteúdo + README + index) e `docs/technical-context/` (9 arquivos — 6 de conteúdo + README/index) estão **populados como dogfood** (seed real do Onion); `docs/compliance-context/` segue **template** (só `README.md`), populado no projeto-alvo por `/docs:build-compliance-docs`

### Sistema Onion (`.claude/`)
- **108 comandos invocáveis** Claude Code distribuídos em:
  - 35 em `meta/` (meta-comandos, criadores, validação, orquestração de subagentes, frescor de KB e de contexto, federação, adoção e co-evolução)
  - 21 em `product/` (gestão de produto e descoberta)
  - 12 em `engineer/` (engenharia e desenvolvimento)
  - 11 em `docs/` (geração e validação de documentação)
  - 6 em `validate/` (validação e testes — inclui subpastas `collab/`, `qa-points/`, `test-strategy/`)
  - 6 em `git/` (GitFlow e versionamento)
  - 3 em `test/` (unit, integration, e2e)
  - 3 em `design/`, 1 em `development/`, 1 em `quick/`
  - 3 no root: `onion.md`, `warm-up.md`, `catch-up.md`
  - **não-invocáveis**: 26 fragmentos em `common/` (11 templates + 15 prompts, incl. READMEs) e 11 READMEs de categoria
- **12 skills** em `.claude/skills/` (`onion`, `onion-patterns`, `onion-validation`, `language-standards`, `onion-orchestration`, `onion-engineering-context`, `onion-product-context`, `onion-compliance-context`, `onion-wizard`, `onion-onboarding`, `onion-retro`)
- **51 agentes** IA distribuídos em:
  - 20 em `development/` (frontend, backend, infra, integrações)
  - 9 em `product/` (gestão e narrativa)
  - 5 em `compliance/` (ISO 27001, ISO 22301, SOC2, PMBOK, governance)
  - 5 em `meta/` (orquestração, criação, validação, skills)
  - 5 em `git/` (review pré-PR)
  - 3 em `testing/`, 2 em `review/`
  - 1 em `research/`, 1 em `deployment/`

### Total
- **642 arquivos** de documentação markdown em `docs/`
- **108 comandos invocáveis** em 10 categorias + root (+ 26 fragmentos `common/` + 11 READMEs de categoria)
- **51 agentes** especializados em 9 categorias
- **12 skills** (`.claude/skills/`) · **93 Knowledge Bases**

---

## 📁 Estrutura de Documentação

```
docs/
├── INDEX.md                    # Este arquivo (hub central)
│
├── onion/                      # Sistema Onion (21 arquivos)
│   ├── index.md                # Índice da seção
│   ├── inventory.md            # SSOT de contagens (gerado por /meta:inventory)
│   ├── commands-guide.md       # Guia completo de comandos
│   ├── agents-reference.md     # Referência de agentes
│   ├── federation-map.md       # Mapa da federação (adotantes, pins, canais)
│   ├── remote-parallel-operation.md # Operação remota & paralela (transporte × persistência)
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
├── knowledge-base/             # Knowledge Bases (91 arquivos, incl. index)
│   ├── concepts/               # Conceitos fundamentais (50 arquivos)
│   ├── frameworks/             # Frameworks e metodologias (9 arquivos)
│   ├── platforms/              # Plataformas e tecnologias (3 arquivos)
│   ├── tools/                  # Ferramentas e recursos (6 arquivos)
│   ├── patterns/               # Padrões de implementação (3 arquivos)
│   ├── architectures/          # C4 + ADR (1 arquivo)
│   ├── meta/                   # Criação de comandos + identidade/produto (2 arquivos)
│   ├── education/              # Vertical educacional — fonte≠derivação (4 arquivos + 1 README)
│   │   ├── theories/           #   Fiel à fonte, zero Onion
│   │   └── applications/       #   Nossas derivações — cita, nunca reescreve
│   └── agentic-patterns/       # KB viva: IA + harness (8 docs + 4 READMEs)
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
├── business-context/            # Contexto de negócio — POPULADO (dogfood, 15 arquivos)
│   ├── index.md · README.md · decisions.md  # hub + registro de decisões (D1–D6)
│   ├── 01-customer/             # personas · journey · voice-of-customer
│   ├── 02-product/              # strategy · metrics
│   ├── 03-market/               # competitive-landscape · industry-trends
│   └── 04-operations/           # sales-process · messaging · customer-communication
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
├── analysis/                   # Análises ativas (125 arquivos; ver analysis/README.md — ciclo de vida e critério de retenção)
│
├── discussions/                 # Constelação de Estudos (57 arquivos)
│   ├── README.md                # O padrão discussion-worktrees + modelo Constelação
│   ├── _template/SEED.md        # copie para começar uma estrela nova
│   └── <slug>/                  # cada estudo isolado (SEED.md Tier-0 + notas)
│
├── applying/                    # Guias de aplicação (7 arquivos)
│   ├── README.md · adoption-lifecycle.md · applying-greenfield.md
│   ├── applying-legacy.md · applying-regulated.md
│   └── onion-adoption-manual.md · rescue-prompt.md
│
├── materials/                  # Materiais derivados externos (Fase 4 — 10 arquivos)
│   ├── README.md               # Índice e guia de uso dos materiais
│   ├── landing-page.md         # Esqueleto da landing page
│   ├── manual-toc.md           # Sumário do manual técnico
│   ├── case-studies.md         # 3 case studies desenvolvidos
│   ├── brand-book.md           # Brand book derivado do design-context
│   ├── critical-article-outline.md  # Outline de artigo crítico
│   ├── press-kit.md            # One-pager, FAQ imprensa, bio, citações
│   └── cold-adopter-2026-07/   # Kit de adotante frio (concierge + one-pager KG)
│
├── evolution/                   # Co-evolução core↔derivados (doc-bridge — 294 arquivos)
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
├── technical-context/           # Contexto técnico — POPULADO (dogfood, 9 arquivos)
│   ├── 01-core/                 # project-charter + adr/
│   ├── 02-ai-context/           # ai-development-guide · codebase-guide
│   ├── 03-domain/               # business-logic
│   └── 04-workflow/             # architecture-challenges · contributing
│
└── compliance-context/
    # contexto spec-as-code PEER — template no framework (só README.md),
    # populado no projeto-alvo por /docs:build-compliance-docs
```

---

## 🧅 Sistema Onion

### 📖 Documentação Principal

#### Guias Essenciais
- **[Guia de Comandos](onion/commands-guide.md)** - Documentação completa de todos os comandos disponíveis
- **[Referência de Agentes](onion/agents-reference.md)** - Lista e descrição de todos os agentes especializados
- **[Fluxos de Engenharia](onion/engineering-flows.md)** - Workflows detalhados para desenvolvimento
- **[Operação Remota & Paralela](onion/remote-parallel-operation.md)** - Transporte (mosh/tmux/ssh) × persistência de sessão para operar o core à distância e em paralelo
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

- **[Conceitos Fundamentais](knowledge-base/index.md)** (49) — Domain Context Lifecycle, Task Manager Abstraction, Spec-as-Code/Driven Development, SDAAL, Agent Orchestration, Onion Dogfooding Doctrine, Onion Engine Economy, Onion Relation Vocabulary, Onion Working Method, Knowledge Graph SDAAL, Secret Handling (Agent), Federation Usage Modes, Onion Federation and Adoption, Fonte≠Derivação, Session Memory Lifecycle, Decision Snapshot Retention, Discussion-Worktrees, Constellation of Studies, Authorization Layers, e mais
- **[Frameworks e Metodologias](knowledge-base/index.md)** (9) — GitFlow, Story Points, Framework de Testes, Collaborative Testing, Test Strategy Scoring
- **[Plataformas](knowledge-base/index.md)** (3) — Gamma.App API, Git Ledger as Working Dir, Runflow
- **[Ferramentas](knowledge-base/index.md)** (6) — Agent Skills, Claude Code Commands Best Practices, Docker, PostgreSQL, VPS Tool Repo Skeleton, Whisper
- **[Patterns](knowledge-base/index.md)** (3) — Literate Policy-as-Data, Presentation Orchestration, SDAAL Examples
- **[Architectures](knowledge-base/index.md)** (1) — C4 + ADR Patterns
- **[Meta](knowledge-base/index.md)** (2) — Command Creation Patterns, Onion Framework Identity
- **[Education](knowledge-base/index.md)** (4 + 1 README) — vertical `onion-education`: PLEA/SRL (theories/, fiel à fonte) + diretrizes/pontes (applications/, nossa derivação)
- **[Agentic Patterns](knowledge-base/index.md)** (8 docs + 4 READMEs, KB viva) — internals de harness, estratégias de guiar o transformer, observações brutas do campo

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

## 💼 Contexto de Negócio (dogfood)

Contexto de negócio spec-as-code do **próprio Onion** — semeado por `/docs:build-business-docs` como dogfood (as camadas 1–4 estão populadas neste repo, não só template):

- **[Índice do Business Context](business-context/index.md)** - Perfil de negócio + links das 4 camadas + pendências de validação
- **[Registro de Decisões (D1–D6)](business-context/decisions.md)** - Decisões estratégicas em aberto (modelo comercial, preço, comprador, branding) — mecanismo de rastreio spec-as-code
- Camadas: [01-customer](business-context/01-customer/personas.md) · [02-product](business-context/02-product/strategy.md) · [03-market](business-context/03-market/competitive-landscape.md) · [04-operations](business-context/04-operations/sales-process.md)

**Localização:** `docs/business-context/` · **Peers:** `docs/technical-context/` (também populado como dogfood) · `docs/compliance-context/` (template)

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
- **Kit de adotante frio** — [Concierge Customer-Dev Kit](materials/cold-adopter-2026-07/concierge-customer-dev-kit.md) · [One-pager KG Reconciliation](materials/cold-adopter-2026-07/one-pager-kg-reconciliation.md)

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

## 🌌 Discussões (Constelação de Estudos)

Estudos isolados ("estrelas") sob o padrão [discussion-worktrees](knowledge-base/concepts/discussion-worktrees-pattern.md), operados pelo modelo [Constelação de Estudos](knowledge-base/concepts/constellation-of-studies.md). Cada estudo vive numa worktree `discuss/<slug>` local; o `SEED.md` é o Tier-0 público (o core lê só o enquadramento macro).

- **[README — o padrão](discussions/README.md)** - Como as estrelas nascem, o Tier-0 público e as camadas de autorização
- **[_template/SEED.md](discussions/_template/SEED.md)** - Ponto de partida para uma estrela nova
- **Estudos ativos** (SEED.md por slug): `onion-pessoal-marcio` (Company Brain N=1) · `guardrails-nemo-lens` (taxonomia ONION-R) · `interface-state-of-art`

**Localização:** `docs/discussions/`

---

## 📊 Análises

> **Ciclo de vida** (ver [analysis/README.md](analysis/README.md)): análises e planos são **efêmeros** — uma vez executados, são removidos (git é o arquivo). Este hub navega apenas os **baselines/ADRs duráveis**; a lista completa (125 arquivos nesta pasta) e o critério de retenção vivem em `analysis/README.md` — SSOT para não duplicar uma lista que fica obsoleta a cada sessão.

**Baselines ativos (referenciados por comandos/constituição):**
- **[Revisão Analítica do Sistema Onion — Maio/2026](analysis/onion-review-2026-05.md)** — SSOT de identidade, citada por `CLAUDE.md`.
- **[Baseline de Verificação e Validação — Junho/2026](analysis/onion-vv-baseline-2026-06.md)** — usada por `/meta:evolve`.
- **[Onion Evolution — mais recente](analysis/onion-evolution-2026-07-04.md)** — última auditoria geral (ponto de comparação da próxima rodada).
- **[Onion Federation Audit — 2026-07-01](analysis/onion-federation-audit-2026-07-01.md)** — auditoria focada em federação.
- **[Parecer — Duas linhagens no rhilo — Julho/2026](analysis/onion-parecer-rhilo-lineages-2026-07.md)** — D1/D2 executados; D3 (KG dogfood) e D4 (merge total) pendentes.

**ADRs duráveis (nunca removidos, só *superseded*)** — lista completa e atualizada em [analysis/README.md](analysis/README.md): adoção de repo, A2A format-vs-runtime, domain-context-lifecycle, PFR, ledger format/location, vocabulário de fluxos de co-evolução, "adota não impõe", branching agnóstico, SLM-as-tool, object-led-discovery, e outros — `analysis/README.md` é a SSOT do veredito de quais ADRs estão ativos.

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
5. [Business Context (dogfood)](business-context/index.md) - Exemplo real das 4 camadas de negócio

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
1. [Agentes de Compliance](onion/agents-reference.md)
2. [Comandos de Validação](onion/commands-guide.md)

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
| 💼 **Business Context** | `docs/business-context/` | Contexto de negócio do Onion (dogfood, 4 camadas) |
| 🎨 **Design Context** | `docs/design-context/` | SSOT de identidade visual (provisório) |
| 📊 **Análises** | `docs/analysis/` | Análises e estudos |
| 🌌 **Discussões** | `docs/discussions/` | Estudos isolados (Constelação de Estudos) |
| 🔄 **Evolução/Federação** | `docs/evolution/` | Doc-bridge core↔derivados |
| 🔧 **SDAAL** | `docs/sdaal/` | Specification-Driven AI Abstraction Layer |
| 🌐 **Materiais Externos** | `docs/materials/` | Landing page, manual, case studies, press kit (Fase 4) |

### Por Categoria de Comando

| Categoria | Comandos | Documentação |
|-----------|---------|--------------|
| 🔧 **Engenharia** | `/engineer/*` | [Guia de Comandos](onion/commands-guide.md) |
| 📋 **Produto** | `/product/*` | [Guia de Comandos](onion/commands-guide.md) |
| 🧪 **Testes** | `/test/*` | [Sistema de Testes](onion/testing-validation-system.md) |
| ✅ **Validação** | `/validate/*` | [Sistema de Testes](onion/testing-validation-system.md) |
| 📚 **Documentação** | `/docs/*` | [Guia de Comandos](onion/commands-guide.md) |
| 🌿 **Git** | `/git/*` | [Guia de Comandos](onion/commands-guide.md) |
| ⚙️ **Meta** | `/meta/*` | [Guia de Comandos](onion/commands-guide.md) |
| 🎨 **Design** | `/design/*` | [Design Context](design-context/README.md) |
| 🧅 **Onion** | `/onion/*` | [Sistema Onion](onion/) |
| ⚡ **Quick** | `/quick/*` | [Guia de Comandos](onion/commands-guide.md) |

### Por Categoria de Agente

| Categoria | Agentes | Documentação |
|-----------|---------|--------------|
| 🛡️ **Compliance** | `compliance/` (5) | [Referência de Agentes](onion/agents-reference.md) |
| 🔴 **Meta** | `meta/` (5) | [Referência de Agentes](onion/agents-reference.md) |
| ⚙️ **Deployment** | `deployment/` (1) | [Referência de Agentes](onion/agents-reference.md) |
| 🟣 **Pesquisa** | `research/` (1) | [Referência de Agentes](onion/agents-reference.md) |
| 🟢 **Review** | `review/` (2) | [Referência de Agentes](onion/agents-reference.md) |

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

### ✨ Documentação Adicionada Recentemente (ciclo 2026-07)

- **`business-context/` populado (dogfood)** — seed real do contexto de negócio do próprio Onion nas 4 camadas (cliente/produto/mercado/operações) + registro de decisões estratégicas `D1–D6`, gerado por `/docs:build-business-docs`.
- **`discussions/` — Constelação de Estudos** — o lar do padrão discussion-worktrees: estudos isolados ("estrelas") em worktrees `discuss/<slug>`, com `SEED.md` Tier-0 público.
- **KB `education/`** — vertical `onion-education`: duas camadas em fronteira física (`theories/` fiel à fonte, `applications/` nossa derivação) — instância batizadora da doutrina [fonte≠derivação](knowledge-base/concepts/source-vs-derivation.md).
- **KB viva `agentic-patterns/`** — como IA + harness colaboram na prática (harness internals, ai-strategies, field-observations).
- **`design-context/`** — vertical de design incubada como 4º contexto candidato a peer (provisório, gated por `/meta:context-freshness`).
- **Operação remota & paralela** ([onion/remote-parallel-operation.md](onion/remote-parallel-operation.md)) — transporte × persistência para operar o core à distância.

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

**Última atualização:** 2026-08-13 (`/docs:build-index` — contagens **reescaneadas do filesystem**, nunca digitadas). Corrigido: docs/ 585→641 md · knowledge-base 89→91 (KBs 88→**90**, batendo com a SSOT `/meta:inventory`) · concepts 48→49 · agentic-patterns 11→12 · analysis 120→125 · evolution 246→293 · onion/ 20→21. Sem drift: meta-specs 6, materials 10, applying 7, discussions 57, business-context 15, technical-context 9. Links: **133 verificados, 0 mortos**. As **13 seções** reais de `docs/` estão cobertas.

> ⚠️ **Por que o drift passou — e por que a 1ª correção deste hub só pegou um quarto dele.** A REGRA 16 do lint (count-drift) vigia as frases canônicas de **inventário** (`N comandos invocáveis`, `N agentes`, `N skills`, `N Knowledge Bases`) — e essas estavam **certas** aqui. O que driftou foi a forma `N arquivos em docs/<seção>`, que nenhuma guarda cobre: o lint dá **0 HARD** com este arquivo errado em sete pontos. Mesma classe que a auditoria de 2026-08-12 registrou no `codebase-guide.md`: **a cegueira é de vocabulário, não de escopo**.
>
> ⚠️ **E o Elenxo mostrou que a cura parou em 1/4.** Este arquivo tem **quatro sítios independentes** de contagem — o bloco de estatísticas, o bloco `### Total`, a árvore ASCII e a lista de Knowledge Bases — e a 1ª passada corrigiu só o primeiro. O resultado foi o pior caso possível: `641` na linha 26 e `585` na linha 68, **contradição dentro do mesmo arquivo**, sob um rodapé que dizia "reescaneadas, nunca digitadas". Também escapou `tools/` (5→6), e a **aritmética denunciava**: os sub-bullets somavam 90 contra os 91 declarados — faltava exatamente 1. Reescanear não basta; é preciso varrer **todas as formas** em que o número aparece. Enquanto não houver feeder de lint para `N arquivos em docs/<seção>`, a única cura é rodar `/docs:build-index` **e conferir a soma**.
>
> ⚠️ **E há um efeito de segunda ordem que o revisor de CI pegou:** o resíduo de revisão exigido
> pela REGRA 56 é um `.md` **dentro de `docs/evolution/`** — ou seja, **o ato de documentar esta
> correção invalidou os números que ela acabou de corrigir** (641→642, 293→294). Contagem de um
> diretório que contém o próprio registro do trabalho é auto-referente por construção. Quem rodar
> `/docs:build-index` deve fazê-lo **por último**, depois de todos os arquivos do PR existirem —
> ou aceitar que o total nasce defasado em 1.

**Mantido por:** Sistema Onion

---

**Sistema Onion** - Multi-Context Development Orchestrator 🧅
