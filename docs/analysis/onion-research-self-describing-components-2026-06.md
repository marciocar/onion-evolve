---
title: 'Pesquisa — componentes auto-descritivos + injeção sob-demanda + auto/co-evolução: vocabulário, SOTA (jul/2026) e o que o Onion já tem'
date: 2026-06-27
type: analysis
status: living
authority: insumo de direção (alimenta o ADR capability-contract)
research: WebSearch (jul/2026, pós-corte ago/2025) + Explore interno do repo
related:
  - onion-adr-capability-contract-2026-06.md (a decisão que este doc fundamenta)
  - onion-distribution-strategy-2026-06.md (camadas; este aprofunda a camada 1)
  - ../sdaal/sdaal.md (SDAAL — a visão-de-dentro já existente)
  - onion-adr-exchange-unit-2026-06.md (plugins de vertical)
---

# Componentes auto-descritivos, injeção sob-demanda e auto/co-evolução

> **Pergunta do maestro:** precisamos de algo para **validar e ajustar o padrão dos plugins** maximizando
> Transformer + SDAAL, sob a visão OOP "quem sabe sobre o objeto é o próprio objeto" (visão-de-dentro) +
> a visão do orquestrador, para auto/co-evolução, com **injeção de poderes/conhecimento pesados sob demanda**.
> "Não sei se é um validador, um formatador, um lint, o cinto do Batman ou um canivete suíço."

## 1. Como se chamam essas técnicas (vocabulário)

A intuição do maestro cruza **quatro famílias** que convergiram em 2026:

| Intuição do maestro | Nome técnico | Raiz |
|---|---|---|
| "investir o componente das habilidades só quando precisa" (cinto do Batman) | **Progressive Disclosure** + **Dynamic Context Injection**, sob **Context Engineering** | nativo das Claude Skills (anuncia→carrega→recursos→scripts) |
| "o objeto sabe responder sobre si" (visão-de-dentro) | **Information Expert (GRASP)** + **reflection/introspection** → **self-describing agents / capability manifests** | OOP clássico + agentes 2026 |
| "visão-de-dentro + orquestrador p/ auto-evolução" | **self-/co-evolving agents** + **Agentic Context Engineering (ACE)** | Darwin-Gödel, ADAS, SICA, HyperAgents |
| "validar e ajustar o padrão" | **conformance profiles (Bronze/Silver/Gold)** + **agent behavioral contracts** + **policy-as-code** + **drift detection** | governança de agentes 2026 |

**Resposta direta:** não é *um* deles — é a **composição**. O "cinto/canivete" é a **injeção sob-demanda**
(progressive disclosure); o "lint/validador" é o **contrato de conformidade**; ambos sobre uma
**auto-descrição** (capability manifest). O Transformer é o runtime que interpreta a auto-descrição + os
specs (a tese SDAAL: LLM=VM, Markdown=bytecode).

## 2. Estado da arte (jul/2026)

- **Context Engineering** é a disciplina-guarda-chuva de 2026: arquitetar *o que* o modelo recebe, *como* é
  estruturado e *quando* entra na janela — não o prompt, mas memória+tools+retrieval+estado.
- **Progressive disclosure** (Agent Skills): 4 estágios — anunciar nome/descrição no system prompt → carregar
  o `SKILL.md` no match → ler recursos sob demanda → rodar scripts. "Dezenas/centenas de skills sem
  penalidade; só puxa o que precisa, quando precisa."
- **Self-/co-evolving agents:** **Darwin-Gödel Machine** (agente edita o próprio código, inclusive o código
  que propõe modificações; arquivo evolutivo de variantes), **ADAS** (meta-agente fixo — limitação que a DGM
  supera), **SICA** (colapsa meta-agente e target-agent), **HyperAgents** (o meta-nível também é editável).
  **ACE** — o contexto evolui como um *playbook que se auto-atualiza* com feedback de performance.
- **Conformance/contratos:** perfis **Bronze/Silver/Gold** (Bronze=campos mínimos; Silver=refs/deps
  resolvem; Gold=governado, registro+RBAC+telemetria), **agent behavioral contracts** (especificação formal +
  enforcement em runtime), **policy-as-code** (regra testável/versionável/rastreável), **drift detection**
  (comportamento diverge da spec), **agentic self-validation** (auto-TDD).

**Fontes:** Context Engineering 2026 (swirlai) · Darwin-Gödel Machine (arXiv 2505.22954) · ACE
(meta-intelligence) · Agent Skills architecture (arXiv 2602.12430) · Agent Behavioral Contracts (arXiv
2602.22302) · conformance Bronze/Silver/Gold (nidhivichare) · Externalization in LLM Agents (arXiv 2604.08224).

## 3. O que o Onion JÁ tem (mapeamento interno)

| Família | Onde já existe no Onion |
|---|---|
| Auto-descrição (visão-de-dentro) | frontmatter de agents (`expertise`, `related_agents/commands`, `integrations`), commands, skills; SDAAL `detector.md`/adapters (cada adapter sabe sua API) |
| Injeção sob-demanda | progressive disclosure nativo (5 skills); SDAAL factory/detector (carrega o adapter por `.env`); `none.md` (Null Object) |
| Visão-de-fora (orquestrador) | `inventory.md` **gerado** das fontes (`inventory.sh`); agente `@onion`; matriz de routing |
| Validação/conformance | `lint-artifacts.sh` (19 regras, HARD/SOFT, CI-blocking) + drift-guard (REGRA 19) + contratos de federação (tests+fixtures) |
| Auto/co-evolução | `docs/evolution/` (3 fluxos), `/meta:co-*`, `/meta:evolve` (auditoria adversarial), doutrina de dogfood |

**Princípio-chave já vivo:** `inventory.md` é **gerado** dos componentes — a visão-de-fora **composta** da
visão-de-dentro. É o precedente do padrão proposto.

## 4. Lacunas (candidatas a evolução)

- **L1/L6** grafo de dependências explícito (componente declara o que requer) — hoje descoberta manual.
- **L2** injeção **condicional** (IF provider=jira → carregar KB jira) — progressive disclosure é tudo-ou-nada por skill.
- **L5** validação do artefato **contra a própria auto-descrição** (generalizada além do task-manager).
- L3/L4/L7/L8/L9/L10 (auto-routing, loading-strategy, auto-healing, lint multi-repo herdado, runtime
  introspection, version-pinning) — substrato futuro.

## 5. O que eu penso (recomendação)

**Descentralizado, não um registry central.** Um YAML central de tudo **contradiz** a intuição do maestro
(*Information Expert*: quem sabe sobre o objeto é o objeto) e o princípio Onion de SSOT-gerada-do-filesystem.
A direção certa: **cada componente carrega seu "capability contract"** (auto-descrição:
`provides`/`requires`/`loads`-condicional/`conformance`), validado por **conformance tiers**, alimentando
**progressive disclosure condicional**; a visão-de-fora é **composta/gerada** dos contratos (como o
inventário). Decisão e mecânica: `onion-adr-capability-contract-2026-06.md`.
