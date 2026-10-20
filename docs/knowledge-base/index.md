# 📚 Índice - Knowledge Bases

> **Última atualização**: 2026-10-20 | **Gerado por**: `/docs:build-index` · contagens conferidas contra o disco pela REGRA 110 (`.claude/validation/kb-index-check.sh`)

Índice das **Knowledge Bases** do Sistema Onion — conhecimento estruturado para consumo por IA e referência técnica.

---

## 📊 Estatísticas

- **106 documentos de conteúdo** de knowledge base (exceto `index.md` e READMEs de (sub)categoria)
- **53** em `concepts/` · **9** em `frameworks/` · **7** em `tools/` · **5** em `platforms/` · **4** em `patterns/` · **1** em `architectures/` · **2** em `meta/` · **8** em `agentic-patterns/` (+ 4 READMEs de (sub)categoria) · **4** em `education/` (+ 1 README de categoria) · **13** em `decisions/` (+ 1 README de categoria)

---

## 📁 Estrutura por Categoria

```
docs/knowledge-base/
├── concepts/            # 53 — Conceitos fundamentais
├── frameworks/          # 9  — Frameworks e metodologias
├── tools/               # 7  — Ferramentas e recursos
├── platforms/           # 5  — Plataformas e tecnologias
├── patterns/            # 4  — Padrões de implementação (SDAAL, apresentações, policy-as-data, GLPI→Zoho)
├── architectures/       # 1  — C4 + ADR patterns
├── meta/                # 2  — Padrões de criação de comandos + identidade/produto
├── decisions/           # 13 — ADRs: por que o mecanismo é como é + 1 README
├── education/           # 4  — Vertical educacional (fonte≠derivação: theories/ + applications/) + 1 README
└── agentic-patterns/    # 8  — Como IA + harness colaboram (KB viva do campo) + 4 READMEs
    ├── harness/         #     Internals de harnesses específicos
    ├── ai-strategies/   #     Padrões de guiar o transformer
    └── field-observations/ # Observações brutas do campo
```

---

## 🧠 Conceitos Fundamentais (53)

- [Abstraction Patterns Catalog](concepts/abstraction-patterns-catalog.md) — catálogo de padrões de abstração
- [Onboarding do adotante](concepts/adopter-onboarding.md) — a fonte canônica da orientação de adoção (vendorizada); guias por adotante apontam para cá, não duplicam
- [Agent Orchestration](concepts/agent-orchestration.md) — orquestração de subagentes: 6 padrões canônicos sobre as primitivas nativas (Workflow/Agent)
- [AI Agent Design Patterns](concepts/ai-agent-design-patterns.md) — padrões de design para agentes IA
- [Camadas de Liberação (intake × execução)](concepts/authorization-layers-intake-vs-execution.md) — a linha entre intake (autônomo) e execução (gated); consolida a2a-verify/I3 — pai de onion-guardrails
- [Behavior Sensor — Three Gates](concepts/behavior-sensor-three-gates.md) — **CANDIDATO** — os três gates de um sensor de comportamento: mapear consentido × vigiar (determinístico + gated + estrutural)
- [Branding e Posicionamento](concepts/branding-posicionamento-marca.md) — estratégias de marca
- [Configuration Management](concepts/configuration-management.md) — gestão de configurações e secrets
- [Consolidated to Tasks Patterns](concepts/consolidated-to-tasks-patterns.md) — transformação de conhecimento consolidado em tasks
- [Constellation of Studies](concepts/constellation-of-studies.md) — **CANDIDATO** — a constelação de estudos `discuss/*`: mapa macro das N estrelas (fase · next_action · convergência de tags), read-only
- [Context Window Optimization](concepts/context-window-optimization.md) — otimização de contexto, prompt caching e custo multi-agente
- [Decision Snapshot Retention](concepts/decision-snapshot-retention.md) — rastreabilidade atômica sustentável: payload mínimo (decisão, não universo) + política de retenção
- [Discussion Worktrees](concepts/discussion-worktrees-pattern.md) — frentes de discussão isoladas (pensa, não entrega); estende parallel-worktrees
- [Domain Context Lifecycle](concepts/domain-context-lifecycle.md) — contexto de domínio como SSOT viva (CRUD+), não snapshot; fundamenta a regra L0 e o ciclo *Manage*
- [Interesse da fonte](concepts/evidence-source-interest.md) — verificado ≠ neutro: o 3º eixo da evidência ("quem produziu isto ganha o quê com o que diz?")
- [Federação × Tipos de Uso](concepts/federation-usage-modes.md) — matriz canônica de reconciliação: 5 eixos A-E (tiers × adoção × topologias de sessão W1-W7), 3 namespaces de papel, gatilhos de graduação
- [Automação graduada](concepts/graduated-automation-ladder.md) — **CANDIDATO** — nomeia e unifica a escada de automação que o Onion já sobe, espalhada em ~6 docs
- [Identificar e Precificar Dor do Cliente](concepts/identificar-precificar-dor-cliente.md) — metodologias de produto
- [Mitigação de inferência](concepts/inference-mitigation.md) — doutrina (contrato) para defender um KG do motor que o lê; o mecanismo executável é do adotante
- [Knowledge Graph SDAAL](concepts/knowledge-graph-sdaal.md) — **CANDIDATA** (nascida em campo, dogfood real): investigação como grafo ponderado (`REFUTES`/`SUPERSEDES`, planes DEV↔PROD, radar de atenção) + camada `domain` (SSOT durável), frescor/schema como guardas, e **§SSOT-as-runtime** (`read→verify→act→write`; KG-first + drive-to-verify). Gate cumprido em 2026-07-04 — `/meta:kg` existe
- [KG — primeiros passos](concepts/kg-getting-started.md) — a rampa prática: do zero ao primeiro `.kg.yaml` rodando o radar (a doutrina densa fica na KB-mãe)
- [Meeting Transcription to Knowledge Base](concepts/meeting-transcription-to-knowledge-base.md) — framework EXTRACT
- [Multi-repo Federation](concepts/multi-repo-federation.md) — contratos spec-as-code + ledger git (topologia peer)
- [Onion Abstraction Doctrine](concepts/onion-abstraction-doctrine.md) — quando algo vira SDAAL (e quando não vira): Teste do Eixo (≥2 impls reais · escolha do `.env` · consumidor cego) + Teste do Gatilho; 3ª irmã das doutrinas de decisão
- [Onion Dogfooding Doctrine](concepts/onion-dogfooding-doctrine.md) — padrão master de evolução: rodar de verdade → aprender → resolver (fix → re-dogfood); o "re-" unificado (toda verdade tem TTL) + `read(KG)`/`write(KG)` no loop
- [Doutrina do `/meta:drive`](concepts/onion-drive-doctrine.md) — contrato do driver de plano: o laço, o roteamento por KIND de nó, a tabela de selagem e os anti-padrões
- [Elenxo & Bulbo](concepts/onion-elenxo-doctrine.md) — **a doutrina fundacional**: o método que se refuta em público (5 etapas obrigatórias — prescrição que reprova, não rótulo) + a arquitetura de 4 camadas com porosidade epistêmica; inclui a tabela empréstimo-vs-cunhagem
- [Onion Engine Economy](concepts/onion-engine-economy.md) — qual motor para qual tarefa: os três motores de execução e o critério explícito de escolha
- [Onion Federation and Adoption](concepts/onion-federation-and-adoption.md) — guia de síntese: processo completo de `/meta:adopt` fase-a-fase, matriz de permissão dos 4 tiers, 5 perfis reais registrados
- [Ontologia e Hierarquia dos grafos](concepts/onion-kg-ontology-hierarchy.md) — a camada MACRO do KG SDAAL: os tipos de `.kg.yaml`, o papel de cada um e como se espelham
- [Onion Guardrails](concepts/onion-guardrails.md) — **CANDIDATO** — a camada de guardrails nomeada: lente ONION-R sobre gates existentes (herda por read-path); motor determinístico + gated + estrutural, nunca classificador
- [A Condução do Onion](concepts/onion-guided-lifecycle.md) — wizard, scaffold e onboarding como PROJEÇÃO de uma fonte única (a topologia da família), nunca fluxos paralelos
- [Onion Modernization Doctrine](concepts/onion-modernization-doctrine.md) — regra de inventário/SSOT e doutrina de modernização
- [Onion Perception Instruments](concepts/onion-perception-instruments.md) — como o core VÊ, VERIFICA e se mantém FRESCO; irmã da doutrina de breadcrumbs
- [Onion Promotion Ladder](concepts/onion-promotion-ladder.md) — a esteira de promoção das ideias aos artefatos: camadas de teste e maturação (discussão → core)
- [Onion R Taxonomy](concepts/onion-r-taxonomy.md) — **CANDIDATO** — catálogo de referência dos guardrails do core: 14 categorias `ONION-R1..R14` (+R15 proposta), 148 vetos destilados dos gates reais, ancorados por string emitida + read-path (linha rebaixada, snapshot a revalidar via `/meta:kb-freshness`). Companheira de [Onion Guardrails](concepts/onion-guardrails.md)
- [Onion Relation Vocabulary](concepts/onion-relation-vocabulary.md) — TBox da ontologia leve: classes e predicados controlados com que o Onion descreve a si mesmo
- [Doutrina do Catálogo VPS](concepts/onion-vps-catalog-doctrine.md) — o que a VPS compartilhada é, o que nunca vira, e como uma ferramenta entra, vive e sai do catálogo
- [Onion Working Method](concepts/onion-working-method.md) — porta de entrada do método: Seleção (catálogo) + Execução (PFR + coordenação por modo) + Validação (dogfood + adversarial) + Disciplina; mapa de fontes meta-spec/KB/ADR/RFC
- [Parallel Work Worktrees](concepts/parallel-work-worktrees-pattern.md) — trabalho paralelo em worktrees independentes
- [Public Door vs Private Core](concepts/public-door-vs-private-core.md) — porta pública ≠ core privado: a fronteira entre onde a família se adota e onde ela evolui
- [Secret Handling (Agent)](concepts/secret-handling-agent.md) — regra dura: agente nunca pede/aceita segredo em texto claro; receituário capability-split → terminal real → efêmero → fora-de-banda → container (crédito: adotante de campo, dogfood real)
- [Session Memory Lifecycle](concepts/session-memory-lifecycle.md) — memória persistente do harness como 4º contexto auditável, irmã de domain-context-lifecycle
- [Fonte ≠ Derivação](concepts/source-vs-derivation.md) — fronteira física entre conhecimento-fonte e nossa leitura dele; família do "declarado ≠ verificado"
- [Spec-as-Code Strategy](concepts/spec-as-code-strategy.md) — hierarquia de especificações (L0-L3)
- [Spec-Driven Development](concepts/spec-driven-development.md) — metodologia emergente de desenvolvimento com IA
- [Specification-Driven AI Abstraction Layer (SDAAL)](concepts/specification-driven-ai-abstraction-layer.md) — padrão-pai das camadas de abstração
- [Task Manager Abstraction](concepts/task-manager-abstraction.md) — instância canônica do SDAAL (API-first; MCP opcional)
- [Transfer Heuristic (Aristóteles)](concepts/transfer-heuristic-aristotle.md) — **CANDIDATO** — régua de transferência *igual → transfere / diferente → desenha* (lente de Aristóteles); invocada por `/meta:adopt`
- [Transformer Architecture](concepts/transformer-architecture.md) — Transformer: a arquitetura por trás do reasoner do Onion
- [Verify-External-for-Current](concepts/verify-external-for-current.md) — forcing function: claim sobre atual/emergente/popular (versão·device·player·framework·tendência) ⇒ verify externo (web) obrigatório; WebFetch é budget separado do WebSearch; sem verificar → declarar "não verificado". O `verify(vivo)` do SSOT-as-runtime aplicado ao mundo externo
- [Base atual, sempre](concepts/keep-current-doctrine.md) — ordem eterna do maestro (2026-10-16): construir sobre a origin/main recém-buscada e as versões atuais; defasagem é subida ou nomeada; faltou pacote ⇒ pedir autorização e instalar. Cobrada pelo hook `session-currency-check.sh` (medidor `currency-census.sh`)
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

> _As 4 KBs de visões abandonadas (onion-complete-cycle, onion-ide-integration-strategy, onion-multi-context-orchestrator-vision, onion-system-critical-analysis-2025) foram removidas na curadoria de 2026-06-14 — suas conclusões estão sintetizadas em `onion-review-2026-05.md` (interno do core — a revisão-snapshot que fixa a identidade canônica: framework template em `.claude/`, plataforma única Claude Code, três dimensões peer produto/engenharia/compliance, e o abandono formal de `.onion/` + v4.0/CLI standalone); o conteúdo verboso é recuperável via git history._

---

## 🛠️ Ferramentas (7)

- [Agent Skills](tools/agent-skills.md) — formato aberto de skills para agentes
- [Claude Code Commands Best Practices 2026](tools/claude-code-commands-best-practices-2026.md) — boas práticas, ferramenta Workflow, Skill, subagentes
- [Docker Deployment](tools/docker-deployment.md) — containerização Node.js/Next.js/NX Monorepo: Dockerfiles, Compose, segurança, troubleshooting
- [LibreChat — agente + MCP](tools/librechat-agent-mcp.md) — fatos medidos em produção ao servir um projeto por um agente do LibreChat ligado a um MCP próprio (decaem por versão)
- [PostgreSQL 17](tools/postgresql.md) — triggers, functions, migrations (Prisma), indexing e troubleshooting; extraída do `@postgres-specialist` (shed-ceremony 2026-07-10)
- [Esqueleto de repo-por-ferramenta VPS](tools/vps-tool-repo-skeleton.md) — a convenção existente do repo de cada serviço da VPS, registrada a partir da referência viva
- [Whisper](tools/whisper.md) — transcrição de áudio (OpenAI)

---

## 🌐 Plataformas (5)

- [Gamma.App API](platforms/gamma-app-api.md) — Generations API: especificação, padrões de integração e exemplos (extraído do agente `@gamma-api-specialist`)
- [Git Ledger as Working Dir](platforms/git-ledger-as-working-dir.md) — ledger git como additional working directory (prova da Fase 0 da federation)
- [GLPI API](platforms/glpi-api.md) — APIs do GLPI (V1 legada e V2 do GLPI 11), com fonte na documentação oficial
- [Runflow](platforms/runflow.md) — SDK e plataforma de agentes/workflows
- [Zoho Projects API](platforms/zoho-projects-api.md) — REST V3: OAuth 2.0 (Self Client), data centers, escopos, paginação, rate limit e erros

---

## 🧩 Patterns (4)

- [GLPI → Zoho Projects](patterns/glpi-zoho-ticket-to-task.md) — chamado de GLPI que é trabalho de projeto vira tarefa no Zoho, com vínculo e status dos dois lados
- [Literate Policy-as-Data](patterns/literate-policy-as-data.md) — config de três leitores: parser lê dados, humano lê história, IA lê ordens (batizadora: members.yaml)
- [Presentation Orchestration](patterns/presentation-orchestration.md) — contratos de delegação, templates e casos de uso (extraído do agente `@presentation-orchestrator`)
- [SDAAL Examples](patterns/sdaal-examples.md) — exemplos de implementação do padrão SDAAL

---

## 🏛️ Architectures (1)

- [C4 + ADR Patterns](architectures/c4-adr-patterns.md) — modelagem C4 e Architecture Decision Records

---

## 🧭 Decisões — ADRs (13 + 1 README)

> Por que o mecanismo é como é. Ver o [README](decisions/README.md) para o formato.

- [Adopt `--update` por merge de vendor-branch](decisions/onion-adr-adopt-vendor-branch-merge-2026-07.md) — never-clobber estrutural: a customização do adotante vira conflito git, não diff a revisar
- [Capability-update fora do git](decisions/onion-adr-capability-update-out-of-git-2026-07.md) — o 4º modo de proveniência (adoção docs-only)
- [Transporte × execução](decisions/onion-adr-comms-transport-vs-execution-2026-06.md) — o eixo de risco da comunicação: transporte automático, execução com gate
- [Constelação de Estudos](decisions/onion-adr-constellation-operating-model-2026-07.md) — estudos isolados e core observatório sob convite (proposto, gated)
- [`/meta:create-vertical`](decisions/onion-adr-create-vertical-2026-07.md) — generalizar o padrão hub-onion para scaffoldar verticais de projeto
- [Design estende o KG](decisions/onion-adr-design-extends-kg-2026-07.md) — sem grafo próprio para o design: divergir vs reger, atom-map como join
- [Contexto de domínio como SSOT viva](decisions/onion-adr-domain-context-lifecycle-2026-06.md) — o ciclo de vida CRUD+ dos contextos de domínio
- [Ledger de co-evolução](decisions/onion-adr-ledger-format-location-2026-06.md) — formato e localização: o markdown fica, repo neutro gated
- [Relay manual entrega-sem-commit](decisions/onion-adr-manual-relay-subprotocol-2026-06.md) — o sub-protocolo do transporte manual de co-evolução (`/meta:co-relay`)
- [Git hooks nativos](decisions/onion-adr-native-githooks-standard-2026-06.md) — `core.hooksPath` é o padrão de pre-commit; husky/lefthook são opção do adotante
- [Adoção de repositório](decisions/onion-adr-repo-adoption-2026-06.md) — comando in-platform, não CLI
- [Verticais de investigação e cartografia](decisions/onion-adr-verticals-investigation-cartography-2026-07.md) — duas verticais novas no LEGO via SDAAL (provisório, F0)
- [Modelos de trabalho](decisions/onion-adr-work-models-session-topologies-2026-07.md) — as topologias de sessão da federação

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

## 🤖 Agentic Patterns (8)

> KB viva sobre como IA + harness colaboram na prática. Três trilhos: internals de harnesses,
> estratégias de guiar o transformer, e observações brutas do campo. Escopo aberto — começa em
> Claude Code mas evolui com qualquer harness que o maestro operar.

**harness/**
- [Claude Code — Internals](agentic-patterns/harness/claude-code-internals.md) — filesystem layout, task system, workflow journals, hooks, memória
- [Aparte do Maestro](agentic-patterns/harness/maestro-aside.md) — protocolo de entrada lateral: o sinal do maestro no meio da sessão é roteado sem descarrilhar a tarefa

**ai-strategies/**
- [Object-Led Discovery & Fitting](agentic-patterns/ai-strategies/object-led-discovery.md) — promover objeto existente a papel premium via ciclo dirigível
- [Breadcrumb Patterns](agentic-patterns/ai-strategies/breadcrumb-patterns.md) — forçar absorção vs acomodação no transformer
- [Verify-the-Read-Path-First](agentic-patterns/ai-strategies/verify-read-path-first.md) — onde o dado vive é hipótese até rastrear quem o lê no código (crédito: adotante de campo)
- [Comportamento acima de declaração](agentic-patterns/ai-strategies/behavior-over-declaration.md) — confie no que o artefato FAZ, não no que ele declara sobre si (três casos de campo)

**field-observations/**
- [2026-06-30 — Harness Paths](agentic-patterns/field-observations/2026-06-30-harness-paths.md) — observação que originou este KB (promovida)
- [2026-07-01 — Shallow Verification Masquerading as Deep](agentic-patterns/field-observations/2026-07-01-shallow-verification-masquerading-as-deep.md) — verificação superficial que se apresenta como profunda

---

## ⚙️ Meta (2)

- [Command Creation Patterns](meta/command-creation-patterns.md) — padrões por categoria para criação de comandos
- [Onion: Identidade e Produto](meta/onion-framework-identity.md) — SSOT de identidade/posicionamento para landing page, manual, case studies e press kit

---

## 🔗 Links Rápidos

<!-- ⚠️ Este índice é VENDORIZADO (viaja para todo repo adotado via /meta:adopt).
     Só pode linkar o que viaja JUNTO — hoje: docs/meta-specs, docs/knowledge-base,
     docs/sdaal. `../INDEX.md` (hub do core) e `../onion/index.md` NÃO estão no
     manifesto de vendor: no core resolviam, no adotante ficavam pendurados, e o
     lint do core nunca via porque lá o alvo existe. Achado em campo no update de
     2026-07-21, ao rodar o lint DENTRO do repo do adotante — classe
     "funciona no core, quebra no adotante". -->
- [Meta Especificações](../meta-specs/index.md) — constituição L0
- [SDAAL](../sdaal/) — a camada de abstração dirigida por especificação

### Comandos relacionados

- `/docs:build-index` — reconstruir índices
- `/meta:create-knowledge-base` — criar nova KB
- `/meta:kb-freshness` — auditar frescor das KBs (vaporware, modelos extintos, padrões abandonados)

---

**Mantido por**: Sistema Onion · **Última atualização**: 2026-07-12
