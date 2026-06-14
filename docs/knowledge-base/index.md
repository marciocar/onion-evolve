# 📚 Índice - Knowledge Bases

> **Última atualização**: 2026-06-13 | **Gerado por**: `/docs:build-index`

Índice das **Knowledge Bases** do Sistema Onion — conhecimento estruturado para consumo por IA e referência técnica.

---

## 📊 Estatísticas

- **31 arquivos** de knowledge base (exceto `index.md`)
- **15** em `concepts/` · **8** em `frameworks/` · **4** em `tools/` · **1** em `platforms/` · **1** em `patterns/` · **1** em `architectures/` · **1** em `meta/`

---

## 📁 Estrutura por Categoria

```
docs/knowledge-base/
├── concepts/          # 14 — Conceitos fundamentais
├── frameworks/        # 8  — Frameworks e metodologias
├── tools/             # 4  — Ferramentas e recursos
├── platforms/         # 1  — Plataformas e tecnologias
├── patterns/          # 1  — Padrões de implementação (SDAAL examples)
├── architectures/     # 1  — C4 + ADR patterns
└── meta/              # 1  — Padrões de criação de comandos
```

---

## 🧠 Conceitos Fundamentais (15)

- [Abstraction Patterns Catalog](concepts/abstraction-patterns-catalog.md) — catálogo de padrões de abstração
- [Agent Fleet Orchestration](concepts/agent-fleet-orchestration.md) — orquestração de frota: 6 padrões canônicos sobre as primitivas nativas (Workflow/Agent)
- [AI Agent Design Patterns](concepts/ai-agent-design-patterns.md) — padrões de design para agentes IA
- [Branding e Posicionamento](concepts/branding-posicionamento-marca.md) — estratégias de marca
- [Configuration Management](concepts/configuration-management.md) — gestão de configurações e secrets
- [Consolidated to Tasks Patterns](concepts/consolidated-to-tasks-patterns.md) — transformação de conhecimento consolidado em tasks
- [Context Window Optimization](concepts/context-window-optimization.md) — otimização de contexto, prompt caching e custo multi-agente
- [Identificar e Precificar Dor do Cliente](concepts/identificar-precificar-dor-cliente.md) — metodologias de produto
- [Meeting Transcription to Knowledge Base](concepts/meeting-transcription-to-knowledge-base.md) — framework EXTRACT
- [Onion Modernization Doctrine](concepts/onion-modernization-doctrine.md) — regra de inventário/SSOT e doutrina de modernização
- [Spec-as-Code Strategy](concepts/spec-as-code-strategy.md) — hierarquia de especificações (L0-L3)
- [Spec-Driven Development](concepts/spec-driven-development.md) — metodologia emergente de desenvolvimento com IA
- [Specification-Driven AI Abstraction Layer (SDAAL)](concepts/specification-driven-ai-abstraction-layer.md) — padrão-pai das camadas de abstração
- [Task Manager Abstraction](concepts/task-manager-abstraction.md) — instância canônica do SDAAL (API-first; MCP opcional)
- [Worklog Protocol](concepts/worklog-protocol.md) — sessões retomáveis com eficácia de IA (STATE.md, leitura Tier 0→3, checkpoint)

---

## 🏗️ Frameworks e Metodologias (8)

- [Agent Orchestration Landscape 2026](frameworks/agent-orchestration-landscape-2026.md) — comparativo de 5 correntes (verificação adversarial)
- [Collaborative Testing Patterns](frameworks/collaborative-testing-patterns.md) — pair testing, three amigos
- [Framework de Story Points](frameworks/framework-story-points.md) — estimativas ágeis (Fibonacci)
- [Framework de Testes](frameworks/framework-testes.md) — White/Grey/Black-box, QA Story Points
- [GitFlow Patterns](frameworks/gitflow-patterns.md) — branching, releases, versionamento
- [QA Story Points](frameworks/qa-story-points.md) — matrizes de pontuação de QA
- [Spec-Driven Development Tools 2025](frameworks/spec-driven-development-tools-2025.md) — análise comparativa de ferramentas
- [Test Strategy Scoring](frameworks/test-strategy-scoring.md) — thresholds e detecção de gaps de teste

> _As 4 KBs de visões abandonadas (onion-complete-cycle, onion-ide-integration-strategy, onion-multi-context-orchestrator-vision, onion-system-critical-analysis-2025) foram removidas na curadoria de 2026-06-14 — suas conclusões estão sintetizadas em [onion-review-2026-05.md](../analysis/onion-review-2026-05.md); o conteúdo verboso é recuperável via git history._

---

## 🛠️ Ferramentas (4)

- [Agent Skills](tools/agent-skills.md) — formato aberto de skills para agentes
- [Claude Code Commands Best Practices 2026](tools/claude-code-commands-best-practices-2026.md) — boas práticas, ferramenta Workflow, Skill, subagentes
- [Docker Deployment](tools/docker-deployment.md) — containerização Node.js/Next.js/NX Monorepo: Dockerfiles, Compose, segurança, troubleshooting
- [Whisper](tools/whisper.md) — transcrição de áudio (OpenAI)

---

## 🌐 Plataformas (1)

- [Runflow](platforms/runflow.md) — SDK e plataforma de agentes/workflows

---

## 🧩 Patterns (1)

- [SDAAL Examples](patterns/sdaal-examples.md) — exemplos de implementação do padrão SDAAL

---

## 🏛️ Architectures (1)

- [C4 + ADR Patterns](architectures/c4-adr-patterns.md) — modelagem C4 e Architecture Decision Records

---

## ⚙️ Meta (1)

- [Command Creation Patterns](meta/command-creation-patterns.md) — padrões por categoria para criação de comandos

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

**Mantido por**: Sistema Onion · **Última atualização**: 2026-06-13
