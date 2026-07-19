# 📚 Índice - Knowledge Bases

> **Última atualização**: 2026-07-12 | **Gerado por**: `/docs:build-index`

Índice das **Knowledge Bases** do Sistema Onion — conhecimento estruturado para consumo por IA e referência técnica.

---

## 📊 Estatísticas

- **65 documentos de conteúdo** de knowledge base (exceto `index.md` e READMEs de (sub)categoria)
- **32** em `concepts/` · **9** em `frameworks/` · **5** em `tools/` · **3** em `platforms/` · **3** em `patterns/` · **1** em `architectures/` · **2** em `meta/` · **6** em `agentic-patterns/` (+ 4 READMEs de (sub)categoria) · **4** em `education/` (+ 1 README de categoria)

---

## 📁 Estrutura por Categoria

```
docs/knowledge-base/
├── concepts/            # 32 — Conceitos fundamentais
├── frameworks/          # 9  — Frameworks e metodologias
├── tools/               # 5  — Ferramentas e recursos
├── platforms/           # 3  — Plataformas e tecnologias
├── patterns/            # 3  — Padrões de implementação (SDAAL, apresentações, policy-as-data)
├── architectures/       # 1  — C4 + ADR patterns
├── meta/                # 2  — Padrões de criação de comandos + identidade/produto
├── education/           # 4  — Vertical educacional (fonte≠derivação: theories/ + applications/) + 1 README
└── agentic-patterns/    # 6  — Como IA + harness colaboram (KB viva do campo) + 4 READMEs
    ├── harness/         #     Internals de harnesses específicos
    ├── ai-strategies/   #     Padrões de guiar o transformer
    └── field-observations/ # Observações brutas do campo
```

---

## 🧠 Conceitos Fundamentais (32)

- [Abstraction Patterns Catalog](concepts/abstraction-patterns-catalog.md) — catálogo de padrões de abstração
- [Agent Orchestration](concepts/agent-orchestration.md) — orquestração de subagentes: 6 padrões canônicos sobre as primitivas nativas (Workflow/Agent)
- [AI Agent Design Patterns](concepts/ai-agent-design-patterns.md) — padrões de design para agentes IA
- [Camadas de Liberação (intake × execução)](concepts/authorization-layers-intake-vs-execution.md) — a linha entre intake (autônomo) e execução (gated); consolida a2a-verify/I3 — pai de onion-guardrails
- [Branding e Posicionamento](concepts/branding-posicionamento-marca.md) — estratégias de marca
- [Configuration Management](concepts/configuration-management.md) — gestão de configurações e secrets
- [Consolidated to Tasks Patterns](concepts/consolidated-to-tasks-patterns.md) — transformação de conhecimento consolidado em tasks
- [Context Window Optimization](concepts/context-window-optimization.md) — otimização de contexto, prompt caching e custo multi-agente
- [Decision Snapshot Retention](concepts/decision-snapshot-retention.md) — rastreabilidade atômica sustentável: payload mínimo (decisão, não universo) + política de retenção
- [Discussion Worktrees](concepts/discussion-worktrees-pattern.md) — frentes de discussão isoladas (pensa, não entrega); estende parallel-worktrees
- [Domain Context Lifecycle](concepts/domain-context-lifecycle.md) — contexto de domínio como SSOT viva (CRUD+), não snapshot; fundamenta a regra L0 e o ciclo *Manage*
- [Federação × Tipos de Uso](concepts/federation-usage-modes.md) — matriz canônica de reconciliação: 5 eixos A-E (tiers × adoção × topologias de sessão W1-W7), 3 namespaces de papel, gatilhos de graduação
- [Identificar e Precificar Dor do Cliente](concepts/identificar-precificar-dor-cliente.md) — metodologias de produto
- [Knowledge Graph SDAAL](concepts/knowledge-graph-sdaal.md) — **CANDIDATA** (nascida em campo, dogfood real): investigação como grafo ponderado (`REFUTES`/`SUPERSEDES`, planes DEV↔PROD, radar de atenção) + camada `domain` (SSOT durável), frescor/schema como guardas, e **§SSOT-as-runtime** (`read→verify→act→write`; KG-first + drive-to-verify). Gate cumprido em 2026-07-04 — `/meta:kg` existe
- [Meeting Transcription to Knowledge Base](concepts/meeting-transcription-to-knowledge-base.md) — framework EXTRACT
- [Multi-repo Federation](concepts/multi-repo-federation.md) — contratos spec-as-code + ledger git (topologia peer)
- [Onion Abstraction Doctrine](concepts/onion-abstraction-doctrine.md) — quando algo vira SDAAL (e quando não vira): Teste do Eixo (≥2 impls reais · escolha do `.env` · consumidor cego) + Teste do Gatilho; 3ª irmã das doutrinas de decisão
- [Onion Dogfooding Doctrine](concepts/onion-dogfooding-doctrine.md) — padrão master de evolução: rodar de verdade → aprender → resolver (fix → re-dogfood); o "re-" unificado (toda verdade tem TTL) + `read(KG)`/`write(KG)` no loop
- [Onion Engine Economy](concepts/onion-engine-economy.md) — qual motor para qual tarefa: os três motores de execução e o critério explícito de escolha
- [Onion Federation and Adoption](concepts/onion-federation-and-adoption.md) — guia de síntese: processo completo de `/meta:adopt` fase-a-fase, matriz de permissão dos 4 tiers, 5 perfis reais registrados
- [Onion Guardrails](concepts/onion-guardrails.md) — **CANDIDATO** — a camada de guardrails nomeada: lente ONION-R sobre gates existentes (herda por read-path); motor determinístico + gated + estrutural, nunca classificador
- [Onion Modernization Doctrine](concepts/onion-modernization-doctrine.md) — regra de inventário/SSOT e doutrina de modernização
- [Onion Relation Vocabulary](concepts/onion-relation-vocabulary.md) — TBox da ontologia leve: classes e predicados controlados com que o Onion descreve a si mesmo
- [Onion Working Method](concepts/onion-working-method.md) — porta de entrada do método: Seleção (catálogo) + Execução (PFR + coordenação por modo) + Validação (dogfood + adversarial) + Disciplina; mapa de fontes meta-spec/KB/ADR/RFC
- [Parallel Work Worktrees](concepts/parallel-work-worktrees-pattern.md) — trabalho paralelo em worktrees independentes
- [Secret Handling (Agent)](concepts/secret-handling-agent.md) — regra dura: agente nunca pede/aceita segredo em texto claro; receituário capability-split → terminal real → efêmero → fora-de-banda → container (crédito: adotante de campo, dogfood real)
- [Session Memory Lifecycle](concepts/session-memory-lifecycle.md) — memória persistente do harness como 4º contexto auditável, irmã de domain-context-lifecycle
- [Fonte ≠ Derivação](concepts/source-vs-derivation.md) — fronteira física entre conhecimento-fonte e nossa leitura dele; família do "declarado ≠ verificado"
- [Spec-as-Code Strategy](concepts/spec-as-code-strategy.md) — hierarquia de especificações (L0-L3)
- [Spec-Driven Development](concepts/spec-driven-development.md) — metodologia emergente de desenvolvimento com IA
- [Specification-Driven AI Abstraction Layer (SDAAL)](concepts/specification-driven-ai-abstraction-layer.md) — padrão-pai das camadas de abstração
- [Task Manager Abstraction](concepts/task-manager-abstraction.md) — instância canônica do SDAAL (API-first; MCP opcional)
- [Worklog Protocol](concepts/worklog-protocol.md) — sessões retomáveis com eficácia de IA (STATE.md, leitura Tier 0→3, checkpoint)

---

## 🏗️ Frameworks e Metodologias (9)

- [Agent Orchestration Landscape 2026](frameworks/agent-orchestration-landscape-2026.md) — comparativo de 5 correntes (verificação adversarial)
- [Collaborative Testing Patterns](frameworks/collaborative-testing-patterns.md) — pair testing, three amigos
- [Framework de Story Points](frameworks/framework-story-points.md) — estimativas ágeis (Fibonacci)
- [Framework de Testes](frameworks/framework-testes.md) — White/Grey/Black-box, QA Story Points
- [GitFlow Patterns](frameworks/gitflow-patterns.md) — branching, releases, versionamento
- [QA Story Points](frameworks/qa-story-points.md) — matrizes de pontuação de QA
- [Safe Multi-Branch Consolidation](frameworks/safe-multibranch-consolidation.md) — 2 lanes, migração-antes-do-código, salvage, build-green (promovida do dogfood de campo)
- [Spec-Driven Development Tools 2025](frameworks/spec-driven-development-tools-2025.md) — análise comparativa de ferramentas
- [Test Strategy Scoring](frameworks/test-strategy-scoring.md) — thresholds e detecção de gaps de teste

> _As 4 KBs de visões abandonadas (onion-complete-cycle, onion-ide-integration-strategy, onion-multi-context-orchestrator-vision, onion-system-critical-analysis-2025) foram removidas na curadoria de 2026-06-14 — suas conclusões estão sintetizadas em [onion-review-2026-05.md](../analysis/onion-review-2026-05.md); o conteúdo verboso é recuperável via git history._

---

## 🛠️ Ferramentas (5)

- [Agent Skills](tools/agent-skills.md) — formato aberto de skills para agentes
- [Claude Code Commands Best Practices 2026](tools/claude-code-commands-best-practices-2026.md) — boas práticas, ferramenta Workflow, Skill, subagentes
- [Docker Deployment](tools/docker-deployment.md) — containerização Node.js/Next.js/NX Monorepo: Dockerfiles, Compose, segurança, troubleshooting
- [PostgreSQL 17](tools/postgresql.md) — triggers, functions, migrations (Prisma), indexing e troubleshooting; extraída do `@postgres-specialist` (shed-ceremony 2026-07-10)
- [Whisper](tools/whisper.md) — transcrição de áudio (OpenAI)

---

## 🌐 Plataformas (3)

- [Gamma.App API](platforms/gamma-app-api.md) — Generations API: especificação, padrões de integração e exemplos (extraído do agente `@gamma-api-specialist`)
- [Git Ledger as Working Dir](platforms/git-ledger-as-working-dir.md) — ledger git como additional working directory (prova da Fase 0 da federation)
- [Runflow](platforms/runflow.md) — SDK e plataforma de agentes/workflows

---

## 🧩 Patterns (3)

- [Literate Policy-as-Data](patterns/literate-policy-as-data.md) — config de três leitores: parser lê dados, humano lê história, IA lê ordens (batizadora: members.yaml)
- [Presentation Orchestration](patterns/presentation-orchestration.md) — contratos de delegação, templates e casos de uso (extraído do agente `@presentation-orchestrator`)
- [SDAAL Examples](patterns/sdaal-examples.md) — exemplos de implementação do padrão SDAAL

---

## 🏛️ Architectures (1)

- [C4 + ADR Patterns](architectures/c4-adr-patterns.md) — modelagem C4 e Architecture Decision Records

---

## 🎓 Education (4 + 1 README)

> Vertical `onion-education` (F0 aberto 2026-07-05). Duas camadas em fronteira física — doutrina
> [fonte≠derivação](concepts/source-vs-derivation.md): `theories/` é fiel à fonte (zero Onion),
> `applications/` é a nossa derivação (cita, nunca reescreve). Ver [README](education/README.md)
> para a regra completa.

**theories/**
- [PLEA — Pedro Rosário](education/theories/plea-rosario.md) — modelo de autorregulação, catálogo fiel verificado por painel adversarial
- [SRL — Zimmerman, Bandura, Winne & Hadwin](education/theories/srl-zimmerman.md) — base teórica de Autorregulação da Aprendizagem + evidência empírica recente

**applications/**
- [Diretrizes de Desenho Educacional](education/applications/educational-design-guidelines.md) — regras vinculantes derivadas da evidência, para todo artefato da vertical
- [Pontes Onion ↔ SRL/PLEA](education/applications/onion-srl-bridges.md) — analogias de engenharia (PLAUSÍVEL, nunca homologia confirmada)

---

## 🤖 Agentic Patterns (6)

> KB viva sobre como IA + harness colaboram na prática. Três trilhos: internals de harnesses,
> estratégias de guiar o transformer, e observações brutas do campo. Escopo aberto — começa em
> Claude Code mas evolui com qualquer harness que o maestro operar.

**harness/**
- [Claude Code — Internals](agentic-patterns/harness/claude-code-internals.md) — filesystem layout, task system, workflow journals, hooks, memória

**ai-strategies/**
- [Object-Led Discovery & Fitting](agentic-patterns/ai-strategies/object-led-discovery.md) — promover objeto existente a papel premium via ciclo dirigível
- [Breadcrumb Patterns](agentic-patterns/ai-strategies/breadcrumb-patterns.md) — forçar absorção vs acomodação no transformer
- [Verify-the-Read-Path-First](agentic-patterns/ai-strategies/verify-read-path-first.md) — onde o dado vive é hipótese até rastrear quem o lê no código (crédito: adotante de campo)

**field-observations/**
- [2026-06-30 — Harness Paths](agentic-patterns/field-observations/2026-06-30-harness-paths.md) — observação que originou este KB (promovida)
- [2026-07-01 — Shallow Verification Masquerading as Deep](agentic-patterns/field-observations/2026-07-01-shallow-verification-masquerading-as-deep.md) — verificação superficial que se apresenta como profunda

---

## ⚙️ Meta (2)

- [Command Creation Patterns](meta/command-creation-patterns.md) — padrões por categoria para criação de comandos
- [Onion: Identidade e Produto](meta/onion-framework-identity.md) — SSOT de identidade/posicionamento para landing page, manual, case studies e press kit

---

## 🔗 Links Rápidos

- [Índice Central](../INDEX.md) — hub de navegação do projeto
- [Sistema Onion](../onion/index.md) — documentação operacional
- [Meta Especificações](../meta-specs/index.md) — constituição L0

### Comandos relacionados

- `/docs:build-index` — reconstruir índices
- `/meta:create-knowledge-base` — criar nova KB
- `/meta:kb-freshness` — auditar frescor das KBs (vaporware, modelos extintos, padrões abandonados)

---

**Mantido por**: Sistema Onion · **Última atualização**: 2026-07-12
