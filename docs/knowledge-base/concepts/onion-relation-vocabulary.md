---
title: "Vocabulário de relações do Onion (TBox)"
category: concepts
status: active
date: 2026-06-28
updated: 2026-07-04
---

# Vocabulário de relações do Onion (TBox da ontologia leve)

> **O que é:** o conjunto **controlado** de classes e predicados com que o Onion descreve a si mesmo — o
> **TBox** (esquema) da ontologia. As instâncias (ABox) vivem na spec-as-code (frontmatter, manifests,
> capability contracts, `actors.yaml`); o grafo é **composto** delas por `.claude/validation/graph.sh`
> (como `inventory.md` é gerado por `inventory.sh`). **Não há store externo** — a tese SDAAL vale: o
> Transformer é o reasoner, o Markdown é o bytecode.
>
> **Por quê:** dar nomes estáveis às relações para que (a) consultas determinísticas (impacto, órfãos,
> caminho) sejam confiáveis e (b) o Transformer navegue o grafo para achar soluções/caminhos e orquestrar —
> a serviço do **dogfood**. Decisão: [onion-adr-capability-contract-2026-06](../../analysis/onion-adr-capability-contract-2026-06.md)
> · Pesquisa/contexto: [onion-research-self-describing-components-2026-06](../../analysis/onion-research-self-describing-components-2026-06.md).

## Classes

O sistema Onion é **sócio-técnico**: atores + artefatos + canais de comunicação.

| Classe | Instâncias | Onde declarada |
|---|---|---|
| **Actor — Maestro** | o humano que decide/orquestra (você) | `docs/onion/actors.yaml` |
| **Actor — Assistant** | o agente IA que executa/propõe (Claude) | `docs/onion/actors.yaml` |
| **Actor — Framework** | o próprio Onion | `docs/onion/actors.yaml` |
| **Actor — Specialist-agent** | os 51 agentes (`@design-system-specialist`, …) | `.claude/agents/**` (frontmatter) |
| **Actor — Core / Adopter** | papéis da co-evolução (source / consumidor) | `actors.yaml` + `.claude/.onion-version` |
| **Artifact** | command · agent · skill · plugin · vertical · KB · meta-spec · context · contract | `.claude/**`, `docs/**`, manifests |
| **Channel** | conversa+plan-gate · doc-bridge (inbox/inbound) · federation-ledger · orchestration | `actors.yaml` |

## Predicados

Cada predicado: **domínio → alcance** + onde já é declarado.

### De ator / papel
| Predicado | Domínio → Alcance | Declarado em |
|---|---|---|
| `decides` `approves` `gates` `requests` `orchestrates` | Maestro → Artifact/Assistant | doutrina (dogfood, plan-gate) → `actors.yaml` |
| `executes` `proposes` `validates` `evolves` | Assistant → Artifact/Onion | doutrina → `actors.yaml` |
| `provides` `serves` `evolves-via` `has-member` | Onion → capacidade/Maestro/dogfood/artefato | `actors.yaml` + inventário |
| `performs` | Specialist-agent → tarefa | frontmatter do agente |
| `adopts` `co-evolves` | Adopter ↔ Core | `actors.yaml` + federation |

### De comunicação (a aresta entre atores, por um Channel)
| Predicado | Sentido | Declarado em |
|---|---|---|
| `requests` `approves` `gates` | Maestro → Assistant | `actors.yaml` (canal: conversa+plan-gate) |
| `proposes` `reports` `asks` | Assistant → Maestro | `actors.yaml` |
| `orchestrates-workers` | Assistant (lead) → Subagente (worker) | `actors.yaml` (canal: orchestration) — orquestração-de-workers |
| `announces` (downstream) | Core → Adopter | `actors.yaml` (canal: doc-bridge inbound) |
| `signals` (upstream) | Adopter → Core | `actors.yaml` (canal: doc-bridge inbox) |
| `via` | Ato de comunicação → Channel | `actors.yaml` |

> **Fronteira:** modela-se a **estrutura** da comunicação (quem fala com quem, por qual canal) — **não** o
> conteúdo/transcript (seria "store everything"; fica para o rever-ao-final).

## Dois domínios de orquestração (desambiguação)

"Orquestração" é **sobrecarregada** no Onion — significa duas coisas distintas. O grafo as separa por
predicado e canal; esta tabela fixa a fronteira. Diagnóstico completo: [onion-orchestration-ontology-2026-06](../../analysis/onion-orchestration-ontology-2026-06.md).

| Eixo | **Orquestração-de-evolução** | **Orquestração-de-workers** |
|---|---|---|
| Predicado | `orchestrates` (maestro→assistant), `evolves`/`co-evolves` | `orchestrates-workers` (assistant→subagente) |
| Escopo | cross-repo (core↔adotantes) | intra-repo (1 worktree/sessão) |
| Tempo | assíncrono (git-async, markdown commitado) | síncrono (1 run) |
| Canal | conversa-plan-gate · doc-bridge · federation-ledger | orchestration (Workflow/SendMessage) |
| Pergunta | "qual repo mexer, em que ordem, o que evoluir?" | "quantos workers, qual padrão, como sintetizar?" |

São **ortogonais**: existe evolução sem orquestração-de-workers, orquestração-de-workers sem evolução, e
ambas. O ponto onde se tocam é a **matriz caso-de-uso × forma**: a evolução é um **caso de uso** que *pode
ser implementado por* uma **forma** de orquestração-de-workers — sem que uma seja a outra.

> **Exemplo canônico:** `/meta:evolve` é um **caso de uso de evolução** (auto-auditoria do framework)
> **implementado por uma forma de orquestração-de-workers** (fan-out-and-synthesize). O caso de uso vive na
> ontologia de evolução; a forma, na de orquestração-de-workers. Confundi-las é ler "a evolução É
> paralela/federada" — não é: a evolução *escolhe* uma forma de orquestração quando a tarefa é paralelizável.

## Vocabulário canônico (alinhado à indústria, jul/2026)

O Onion **adotou o vocabulário canônico** da indústria de orquestração multi-agente — os apelidos PT/EN
**`frota`/`fleet` foram aposentados** em favor de `orquestração` / `orchestrator-worker` / `workers`.
Tabela longa + fontes + a decisão de migração:
[onion-orchestration-ontology-2026-06](../../analysis/onion-orchestration-ontology-2026-06.md) §5.

| Conceito Onion | Canônico da indústria |
|---|---|
| **orquestração (de workers)** | orchestrator-worker / supervisor |
| fan-out / fan-in · barreira | fan-out / fan-in (scatter-gather) · barrier/superstep |
| adversarial-verify / judge-panel | evaluator-optimizer / agent-as-judge |
| nó sumarizador | aggregator / sub-synthesizer |
| PFR (workflow faseado retomável) | durable/checkpointed workflow |

> **Apelidos aposentados:** `frota` (PT) / `fleet` (EN) → use **`orquestração`** (conceito) /
> **`orchestrator-worker`** (padrão) / **`workers`** (coletivo executor). A skill é `onion-orchestration`;
> o comando, `/meta:orchestrate`. O anti-pattern proibido é `worker-orchestrator` (§4.2).

**Não-termos** (não entram na ontologia de orquestração): onda/wave, squad, swarm, mesh, A2A-vivo. A maré 2026
(Gen III: semântica implícita + protocolos lightweight) **valida o SDAAL** — não há store/ontologia formal externa.

### De artefato
| Predicado | Domínio → Alcance | Declarado em |
|---|---|---|
| `requires` `provides` `loads` | Plugin/Vertical → dep/capacidade/contexto-condicional | `plugins/*/.claude-plugin/capability.json` |
| `related` | Agent → Agent/Command | frontmatter `related_agents`/`related_commands` |
| `implements` | Adapter → Interface | SDAAL (`.claude/utils/<abs>/adapters/`) |
| `produces` `consumes` | Repo → Contrato | federation ledger |
| `member_of` | Artefato → categoria | filesystem (inventário) |

## Como o grafo é usado (a serviço do dogfood)

- **Determinístico** (`graph.sh --impact/--orphans/--path`): respostas que o LLM erra — dependência
  reversa, órfãos, caminho entre necessidade e capacidade.
- **SDAAL-navegável** (`docs/onion/graph.md`): o Transformer lê o grafo para achar soluções/caminhos e
  orquestrar — Markdown = bytecode.
- **Dogfoodado**: `/meta:graph` expõe a capacidade; `@onion`/`/meta:evolve` consultam o grafo para a
  "visão-de-fora" composta.

## Fora de escopo (rever ao final)
GraphRAG (recuperar subgrafo sob demanda) · auto-routing pleno no `@onion` · arestas SDAAL/federação no
gerador · elevar este vocabulário a meta-spec L0 · store de verdade (só se a federação escalar).
