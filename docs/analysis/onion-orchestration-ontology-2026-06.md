---
title: 'Ontologia de orquestração do Onion — frota × evolução, vocabulário canônico (jul/2026) e a fronteira desambiguada'
date: 2026-06-28
type: analysis
status: living
authority: insumo de direção (fundamenta a desambiguação no onion-relation-vocabulary.md + actors.yaml)
research: 3 frentes — Explore interno (frota) + Explore interno (evolução×frota) + WebSearch jul/2026 (pós-corte ago/2025)
related:
  - ../knowledge-base/concepts/onion-relation-vocabulary.md (TBox — recebe a desambiguação)
  - onion-orchestration-topology-adr-draft-2026-06-21.md (ADR de topologia; dívida de metadados = F3 deferido)
  - ../knowledge-base/concepts/agent-orchestration.md (doutrina das 5 camadas de frota)
  - onion-research-self-describing-components-2026-06.md (ontologia leve / capability contract)
  - ../evolution/rfc/rfc-0002-meta-strategy-verdict.md (sobreposição evolução×frota reconhecida)
---

# Ontologia de orquestração do Onion — frota × evolução

> **TL;DR.** A pergunta "qual ontologia de orquestração é mais popular/adequada para o Onion?" tem três respostas:
> (1) **nenhuma ontologia formal externa** (AgentO/RDF/OWL) — a indústria de 2026 abandonou *grand ontologies* por
> **semântica implícita + protocolos lightweight**, o que **confirma** a tese SDAAL do Onion; (2) o vocabulário
> **adequado é o consenso de padrões** (orchestrator-worker, fan-out/fan-in, pipeline, router, evaluator-optimizer),
> que o Onion **já fala em ~80%**; (3) a **confusão real não está dentro da frota** (coerente em 5 camadas) **nem é
> sobre termos da moda** — está na **fronteira embaçada entre a ontologia de evolução e a de frota**. Este doc
> consolida o diagnóstico e fixa a desambiguação. **Doutrina preservada; dívida revisada.**

## 1. A pergunta e o método

O maestro pediu para destrinchar o item GATED #3 — a **ontologia das formas de orquestração** (onda/frota/squad/
serial/barreira/pipeline) — suspeitando de **névoa terminológica** entre "ontologia de evolução" e "ontologia de
frota". O método foi triangular três ângulos em paralelo:

- **A1 — inventário interno da frota:** todos os termos de orquestração, inconsistências, modelo mental, status do ADR de topologia.
- **A2 — evolução × frota:** o que cada ontologia cobre e onde se tocam.
- **A3 — estado da arte externo (web, jul/2026):** padrões/vocabulário consagrados, ontologias formais, veredito sobre fleet/squad/wave.

## 2. Estado interno — a frota NÃO está confusa (é coerente em 5 camadas)

O inventário (A1) mostra uma ontologia de frota **estratificada e consistente**:

| Camada | Conteúdo |
|---|---|
| 1. Substrato | ferramenta nativa `Workflow` (primitivas `agent`/`parallel`/`pipeline`/`schema`/`isolation`/`budget`) |
| 2. Padrões (6) | classify-and-act · fan-out-and-synthesize · adversarial-verification · generate-and-filter · tournament · loop-until-done |
| 3. Topologia | **locus** (invariante: orquestra só no nível principal) × **forma** (plano default / árvore sob gatilho) |
| 4. Execução | PFR — workflow faseado retomável (sessão durável + `STATE.md`) |
| 5. Seleção | recognition-primed / playbooks (`onion-patterns`) |

A maior confusão histórica interna — *locus × forma* — **já foi resolvida** no ADR de topologia
(`onion-orchestration-topology-adr-draft-2026-06-21.md`, aceito 2026-06-22). Restam **dívidas**, não confusões:
metadados do ADR incoerentes (título "RASCUNHO" + `status: accepted`), homônimo "Workflow" (ferramenta) vs
"workflow faseado retomável" (PFR), e a cunhagem "nó sumarizador" sem âncora ao termo de mercado. **Essas dívidas
são o escopo F3, deferido.**

## 3. Estado da arte externo (jul/2026)

### 3.1 Padrões consagrados (cross-framework)

Sequential/Pipeline · Parallel/**Fan-out-Fan-in** · **Orchestrator-Worker** (= Supervisor) · Handoff · Hierarchical ·
Router · **Evaluator-Optimizer** (= judge-panel) · Loop · Group-Chat. Vocabulários por framework: LangGraph
(Node/Edge/State/**DAG**/Superstep) · Anthropic (**Subagent**, **Workflows/Dynamic Workflows**, Orchestrator-Worker) ·
OpenAI (Handoff) · CrewAI (Crew/Flows) · Microsoft (Magentic) · Google ADK (Sequential/Parallel/Loop Agent).

### 3.2 Veredito sobre os termos do maestro (onda/frota/squad)

| Termo | Veredito da indústria | Decisão Onion |
|---|---|---|
| **frota / fleet** | jargão em transição; NÃO é primitivo de nenhum framework. O canônico é *orchestrator-worker / fan-out-fan-in*. | **APOSENTADO** → `orquestração`/`orchestrator-worker` (decisão 2026-06-28, ver §6). |
| **onda / wave** | NÃO é padrão de orquestração (refere-se a ciclos de release/capacidade). | Não adotar como termo. |
| **squad** | puro jargão (ex.: ferramenta "Claude Squad"); sem adoção cross-framework. | Não adotar (fica no nível organização: produto/eng). |
| **swarm / mesh / A2A** | descentralizado/P2P — **contrário ao determinismo**; desafios de observabilidade. | Rejeitar (já rejeitado internamente). |

### 3.3 O insight decisivo — Gen III valida o SDAAL

A pesquisa formal (*"From Multi-Agent Systems and the Semantic Web to Agentic AI"*, arXiv 2507.10644, 2026) mapeia
três gerações: **Gen I** (FIPA — diretórios), **Gen II** (Semantic Web — SPARQL/ontologia-driven), **Gen III** (era
LLM — **semântica implícita**: o modelo é o reasoner; coordenação por **protocolos lightweight** MCP/A2A/ANP).
**Não há "uma grande ontologia" em 2026.** Ontologias formais (AgentO/OWL/RDF; Agentic Ontology of Work) existem mas
são nicho enterprise.

> **Consequência para o Onion:** isto **confirma** a tese SDAAL ("o Transformer é o reasoner, o Markdown é o
> bytecode") já fixada na ontologia leve (#199/#200). **Adotar triple-store/RDF/ontologia formal externa seria remar
> contra a maré** — e contradiria a decisão já tomada de "não há store externo".

## 4. Diagnóstico — a confusão está na FRONTEIRA evolução × frota

São **duas ontologias separadas e ortogonais** (A2), não uma só, não sub/super:

| Dimensão | Evolução | Frota |
|---|---|---|
| Escopo | cross-repo (core↔adotantes) | intra-repo (1 worktree) |
| Tempo | assíncrono (git-async, markdown commitado) | síncrono (1 sessão) |
| Problema | como repos coexistem sem colisão | como paralelizar N subtarefas |
| Saída | sinal bidirecional, contratos, registros | resultado consolidado (relatório/diff/síntese) |

São ortogonais: há **evolução-sem-frota**, **frota-sem-evolução** e **ambas** (ex.: `/meta:evolve` = *caso de uso* de
evolução **implementado por** uma *forma* de frota). A névoa mora em **4 superfícies de contato**:

1. **Ator "assistant" com papel dual** — orquestra o framework (evolução) **e** dispara workers (frota); mesmo ator, sentidos distintos.
2. **`co-evolves` × estratégia de frota** — `/meta:evolve` usa frota para auditar o core, misturando *caso de uso* com *forma*.
3. **"Orquestração" sobrecarregada** — significa tanto "maestro roteia repos" (evolução) quanto "lead dispara workers" (frota).
4. **`delegates → frota` opaco** — no `actors.yaml`, o objeto da aresta (`frota`) **é o próprio canal** (`via: frota`) — redundante; a frota é por-onde, não para-quem.

## 5. Vocabulário canônico — Onion ↔ indústria

O Onion **adotou o vocabulário canônico** da indústria; os apelidos `frota` (PT) / `fleet` (EN) foram
**aposentados** em favor de `orquestração` / `orchestrator-worker` / `workers`:

| Conceito Onion | Termo canônico da indústria | Observação |
|---|---|---|
| **orquestração (de workers)** | orchestrator-worker / supervisor | aposentou os apelidos `frota`/`fleet` |
| **fan-out / fan-in** | fan-out / fan-in (scatter-gather, map-reduce) | já alinhado |
| **barreira / `parallel()`** | barrier / superstep | já alinhado |
| **sem-barreira / `pipeline()`** | streaming pipeline | já alinhado |
| **fan-out-and-synthesize** | orchestrator-worker + synthesizer | "síntese" → *synthesizer/aggregator* |
| **nó sumarizador** | aggregator / sub-synthesizer | ancorar à âncora externa (dívida F3) |
| **adversarial-verify / judge-panel** | evaluator-optimizer / agent-as-judge | já alinhado |
| **generate-and-filter** | sampling + deterministic filter | já alinhado |
| **loop-until-dry** | loop / iteration-with-evaluation | já alinhado |
| **recognition-primed / playbook** | router + pattern selection | seleção (catálogo) |
| **PFR (workflow faseado retomável)** | durable workflow / checkpointed graph | distinto da *ferramenta* Workflow |

**Invocáveis:** skill `onion-orchestration` · comando `/meta:orchestrate` · anti-pattern proibido `worker-orchestrator` (§4.2).
**Não-termos (não entram na ontologia de orquestração):** onda/wave, squad, swarm, mesh, A2A-vivo.

## 6. Decisão — migração ao canônico (executada 2026-06-28)

A orquestração-de-workers está sã; a de evolução está sã; faltavam **a fronteira nítida** entre elas **e o
alinhamento de vocabulário**. Decisão do maestro: **migração plena ao canônico**, preservando a doutrina
(5 camadas, SDAAL) e revisando apenas o rótulo.

- **Fronteira desambiguada** no TBox (`onion-relation-vocabulary.md`) e ABox (`actors.yaml`): dois domínios —
  *orquestração-de-evolução* (cross-repo) vs *orquestração-de-workers* (intra-repo); predicado `orchestrates-workers`
  (corrige o antigo `delegates → frota`, cujo objeto era o próprio canal); matriz caso-de-uso × forma (`/meta:evolve`).
- **Apelidos aposentados:** `frota`/`fleet` → `orquestração`/`orchestrator-worker`/`workers`; anti-pattern
  `fleet-orchestrator` → `worker-orchestrator`; skill → `onion-orchestration`; comando → `/meta:orchestrate`.
- **Deferido (F3):** dívida do ADR de topologia (promover draft→adr, ancorar "nó sumarizador" → synthesizer) +
  homônimo Workflow(ferramenta) vs PFR.

**Não fazer:** adotar triple-store/RDF/ontologia formal externa (contra a decisão #2 já tomada e contra a maré Gen III).

> **Nota de registro:** `frota`/`fleet` aparecem neste documento como o **termo analisado e aposentado** —
> citação meta-linguística, não uso vivo (análogo a um CHANGELOG que nomeia o que mudou).

## 7. Fontes (web, jul/2026)

- *From Multi-Agent Systems and the Semantic Web to Agentic AI: A Unified Narrative of the Web of Agents* — arXiv 2507.10644 (2026). [Gen I/II/III; semântica implícita]
- *AI Agent Orchestration Patterns* — Azure Architecture Center, Microsoft Learn (2026-02-12).
- *LangGraph: Workflows and Agents* — LangChain Docs (2026). [Node/Edge/DAG/Superstep]
- *Orchestrate subagents at scale with dynamic workflows* — Claude Code Docs (2026). [Subagent/Workflow/Orchestrator-Worker]
- *Workflow orchestrations in Agent Framework* — Microsoft Learn (2026). [Sequential/Concurrent/Magentic]
- *Developer's guide to multi-agent patterns in ADK* — Google Developers Blog (2025). [Sequential/Parallel/Loop Agent]
- *GraphBit: A Graph-based Agentic Framework for Non-Linear Agent Orchestration* — arXiv 2605.13848 (2026). [DAG determinístico]
- *Parallel Concurrency in Production AI Agents: DAG Scheduling, Fan-Out/Fan-In* — Zylos Research (2026-04-26).
- *A Survey of Agent Interoperability Protocols: MCP, ACP, A2A, ANP* — arXiv 2505.02279 (2025).
- AgentO (OWL/RDF) — Springer Nature (2024-2025); Agentic Ontology of Work — Future AGI (2026). [ontologias formais nicho]

> **Nota de método:** WebSearch é pós-corte (ago/2025); URLs/datas conforme retornadas pela pesquisa de jul/2026.
> O valor está nos *padrões e vereditos* consolidados, não em cada URL individual.
