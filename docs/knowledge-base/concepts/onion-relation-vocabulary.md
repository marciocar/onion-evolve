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
| **Channel** | conversa+plan-gate · doc-bridge (inbox/inbound) · federation-ledger · frota | `actors.yaml` |

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
| `delegates` | Assistant → Specialist-agent/Frota | `actors.yaml` (canal: frota) |
| `announces` (downstream) | Core → Adopter | `actors.yaml` (canal: doc-bridge inbound) |
| `signals` (upstream) | Adopter → Core | `actors.yaml` (canal: doc-bridge inbox) |
| `via` | Ato de comunicação → Channel | `actors.yaml` |

> **Fronteira:** modela-se a **estrutura** da comunicação (quem fala com quem, por qual canal) — **não** o
> conteúdo/transcript (seria "store everything"; fica para o rever-ao-final).

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
