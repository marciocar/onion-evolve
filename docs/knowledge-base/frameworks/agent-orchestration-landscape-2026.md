# Landscape de Orquestração de Agentes (2026)

---

## 📋 Metadata

| Campo | Valor |
|-------|-------|
| **Versão** | 1.0.0 |
| **Data de Criação** | 2026-06-13 |
| **Última Atualização** | 2026-06-15 |
| **Categoria** | Frameworks |
| **Método** | Pesquisa multi-fonte via `/meta:orchestrate` (fan-out-and-synthesize) + verificação adversarial (Opus) |
| **Aplicação** | Posicionamento da camada de orquestração do Onion vs. estado da arte |

> **Nota de confiabilidade:** este documento separa **fatos estruturais** (verificados contra fonte primária, cross-source) de **números de impacto/adoção** (majoritariamente self-report de vendor — tratados como **não-verificados**). A marcação segue o veredito do verificador adversarial que acompanhou a pesquisa. Ver [agent-orchestration.md](../concepts/agent-orchestration.md) para a doutrina operacional.

### Fontes (verificadas)

- [Anthropic — Introducing Dynamic Workflows in Claude Code](https://claude.com/blog/introducing-dynamic-workflows-in-claude-code) (28/mai/2026)
- [MarkTechPost — Claude Opus 4.8 + Dynamic Workflows](https://www.marktechpost.com/2026/05/28/anthropic-ships-claude-opus-4-8-alongside-dynamic-workflows-and-cheaper-fast-mode-with-workflows-capped-at-1000-subagents/) (28/mai/2026)
- [Anthropic — Building Effective Agents](https://www.anthropic.com/engineering/building-effective-agents)
- Gartner — press release "over 40% of agentic AI projects canceled by 2027" (25/jun/2025)
- arXiv 2601.13671 — *The Orchestration of Multi-Agent Systems* (jan/2026); arXiv 2603.22386 — *From Static Templates to Dynamic Runtime Graphs*
- Cursor 3 (Agents Window, worktree isolation) — InfoQ, jun/2026; Microsoft Agent Framework (MAF) GA — devblogs.microsoft.com (abr/2026); AWS Bedrock AgentCore — docs/announcements (2026)
- [Linux Foundation — A2A Protocol Project](https://www.linuxfoundation.org/press/linux-foundation-launches-the-agent2agent-protocol-project-to-enable-secure-intelligent-communication-between-ai-agents); [Google Developers — Announcing A2A](https://developers.googleblog.com/en/a2a-a-new-era-of-agent-interoperability/) (A2A sob Linux Foundation; **150+ organizações em abr/2026**, adoção parcialmente self-report)

---

## 🎯 Visão Geral

Em 2026, "orquestração de agentes" deixou de ser pesquisa e virou **infraestrutura de produto**. Cinco correntes independentes convergem para um mesmo núcleo arquitetural — **orquestrador-worker hierárquico + isolamento + verificação** — diferindo no substrato (nativo, framework, enterprise) e no grau de autonomia. Este landscape compara as cinco e posiciona a camada de orquestração do Onion.

---

## 📊 As 5 correntes

| Corrente | Abordagem dominante | Isolamento / primitiva | Força principal | Fraqueza principal |
|---|---|---|---|---|
| **Anthropic / Claude Code** | Orchestrator-Workers nativo (Dynamic Workflows: script JS em runtime) | até 16 concorrentes / 1.000 por run; model tiering | escala real codebase-level; "controle antes de autonomia" | research preview; *delegation gap* persiste; custo cresce linear com nº de agentes |
| **Coding agents** (Cursor, Devin, Copilot, Codex) | **Planner-Worker-Judge** | git worktree + microVM (Firecracker); sandbox efêmero | isolamento elimina colisão; orquestrador exposto ao usuário | race conditions escalam ~N²; ganho só com subtarefas independentes; *idleness* |
| **Frameworks OSS** (LangGraph, AutoGen→MAF, CrewAI, Swarms) | Supervisor · grafo cíclico · swarm · pipeline | checkpointing/HITL (LangGraph); DSL role-based (CrewAI) | LangGraph maduro (time-travel debug, HITL); CrewAI baixo time-to-value | curva alta (LangGraph); ruptura AutoGen→MAF; protótipos falham em produção |
| **Enterprise** (AWS AgentCore, Agentforce, ServiceNow) | Supervisor/worker + peer-to-peer (A2A) | microVM por sessão; **budget enforcement no gateway** | runtime isolado; bloqueio de custo antes do provider; MCP em escala | vendor lock-in; baixa rastreabilidade de agentes; métricas de volume opacas (AWU) |
| **Academia / pesquisa** (arXiv, taxonomias) | taxonomia formal: orchestrator-worker · supervisor · swarm · mesh · pipeline · **dynamic runtime graphs** | budgets por ramo; trilha de auditoria | base empírica; convergência cross-source | preprints sem peer review; números de blog sem metodologia |

---

## ✅ Convergências (verificadas, cross-source)

1. **MCP + A2A como backbone** — Model Context Protocol (ferramentas) + Agent2Agent (delegação peer), sob a Linux Foundation desde dez/2025. Aparece nas **5 correntes** (confirmado: arXiv 2601.13671). Atualização abr/2026: A2A passa de ~50 (lançamento, abr/2025) para **150+ organizações** (Atlassian, Salesforce, SAP, ServiceNow, MongoDB, PayPal…), com Agent Cards para descoberta de capacidade — consolidando-se como a **camada de interop entre vendors**.
2. **Supervisor / orchestrator-worker é o padrão dominante** em produção (4 de 5 correntes); **swarm/peer-to-peer** é relegado a exploração/back-office por baixa controlabilidade.
3. **Isolamento por sandbox / worktree / microVM** é a solução de design consensual contra colisão de estado entre agentes paralelos.
4. **Risco de governança/custo é real** — Gartner: >40% dos projetos agentic cancelados até 2027 (press release primário, 25/jun/2025).
5. **Dynamic Workflows** (16 concorrentes / 1.000 por run, research preview 28/mai/2026) e o **caso Bun** (port Zig→Rust, ~750k linhas, 99,8% do test suite verde, **11 dias**) — confirmados em reporting primário.
6. **Model tiering** (orquestrador forte + workers baratos) e **budget enforcement** são práticas de custo consensuais.
7. **Nenhum** framework resolve nativamente *context-window overflow*, *rate limiting* e *tool-call failures* — limitação estrutural reconhecida.

---

## ⚔️ Divergências

- **Profundidade de nesting:** plataformas divergem (de "subagente não spawna subagente" a árvores recursivas / depth=1). Sem consenso.
- **Escala do paralelismo:** otimismo de fan-out massivo vs. limite matemático (race conditions ~N(N-1)/2; throughput efetivo cai com muitos agentes dependentes).
- **Protocolos consolidados vs. fragmentados:** narrativa "MCP+A2A já é padrão" (vendor-friendly) vs. "fragmentação persiste" (ACP/ANP/UCP em draft).
- **Métrica de valor:** disputa real sobre métricas de volume (ex.: AWU) vs. valor de negócio.

---

## ⚠️ Claims NÃO-verificados (tratar com ceticismo)

Marcados pelo verificador adversarial como self-report de vendor ou sem metodologia:

- ❌ **"Salesforce 12.000 clientes Agentforce"** — não bate com fonte primária (~18.500, 9.500 pagos no Q3 FY26). O número de **AWU** confere; a contagem de clientes não.
- ⚠️ **"McKinsey +23% bug density"** por código IA não revisado — sem fonte primária; possível conflação com o relatório CodeRabbit (17× issues, dez/2025).
- ⚠️ **Benchmarks de framework** (LangGraph 62% / CrewAI 54% / AutoGen 58%) — sem metodologia publicada.
- ⚠️ **"Outcomes +8,4%/+10,1%", "Codex 2M WAU", "Swarms 99,9% uptime", anedotas "USD 500M/mês"** — self-report.
- ⚠️ **Citation laundering:** o número da Gartner (correto) é frequentemente citado via blogs intermediários, inflando aparência de múltiplas fontes independentes.

---

## 🕳️ Gaps transversais (ninguém cobre bem)

- **Avaliação independente / peer-reviewed** de eficácia multi-agente vs. single-agent — inexistente; todos os ganhos são self-report.
- **Segurança adversarial em fan-out massivo** — prompt injection cross-agent, exfiltração de credenciais via tool-calls, OWASP-for-agents (goal hijack, memory poisoning) quase sem cobertura.
- **Modelo de break-even de custo** — quando o overhead de orquestração (idle, tokens de coordenação, review humano ampliado) supera o ganho.
- **Reprodutibilidade/auditoria** de um run de fan-out (script JS gerado em runtime) para domínios regulados.
- **Carga cognitiva** de um humano supervisionando 8-16+ agentes paralelos.

---

## 🧅 Como o Onion se posiciona

A camada de orquestração do Onion (ver [agent-orchestration.md](../concepts/agent-orchestration.md)) está **alinhada ao consenso verificado**:

- Adota **orchestrator-worker** sobre o substrato **nativo** (`Workflow`/`Agent`) — corrente #1, sem reinventar motor.
- Usa **isolamento por worktree**, **model tiering** e **verificação adversarial / judge-panel** — práticas consensuais.
- Mantém a orquestração no **nível principal** (skill/comando), respeitando `architecture.md §4.2`.

**Onde o Onion deve avançar para uma versão confiável** (gaps transversais que ninguém resolve): guardrails de **segurança adversarial** em fan-out, **verificação automatizada** (não manual) e **modelo de custo/break-even**. Estes pontos são objeto de auditoria contínua via `/meta:orchestrate`.

### Por que o Onion não adota A2A vivo (federação)

A "multi-repo federation" do Onion (ver [multi-repo-federation.md](../concepts/multi-repo-federation.md)) **não é** federação A2A — é coordenação de **repositórios soberanos** via **git assíncrono + contratos spec-as-code**, com humano-maestro. Instâncias vivas A2A / runtime distribuído são **linha vermelha abandonada** (Fase 5, 2026-05-18). A escolha é **defensável para o escopo do Onion**: A2A vivo traria exatamente os modos de falha que este landscape marca como **não resolvidos por ninguém** (segurança adversarial cross-agent, break-even de custo, reprodutibilidade regulada, baixa rastreabilidade). O git como spine entrega a **trilha de auditoria durável** que falta às plataformas A2A.

**Meio-termo ainda não explorado:** o A2A de jun/2026 padroniza também **descoberta de capacidade** (Agent Cards) — conceitualmente irmã de `members.yaml` + `contracts/`. Adotar o **formato** A2A de contrato/discovery (interop de formato, **não** de runtime) seria compatível com a filosofia git-async sem violar a linha vermelha. Candidato a ADR. Análise completa: [onion-federation-review-2026-06.md](../../analysis/onion-federation-review-2026-06.md).

---

**Próxima Atualização Planejada**: Dezembro 2026
**Responsável**: Sistema Onion
