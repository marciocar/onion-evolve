---
name: kg
description: |
  Modela uma investigação/auditoria longa como Knowledge Graph SDAAL (.kg.yaml):
  claims/evidência/decisões tipados, arestas SUPPORTS/REFUTES/SUPERSEDES, planes DEV/PROD —
  e, na camada `layer: domain`, o SSOT de domínio (entity/state/event/rule/policy) que o audit TRACES_TO.
  Roda o radar determinístico (kg-radar.sh) para atenção, reconciliação, integridade e radar-de-domínio.
  Nascido do 1º dogfood do core (auditoria /meta:evolve 2026-07-04) — F2 da vertical onion-investigation.
model: sonnet
category: meta
tags: [kg, knowledge-graph, investigation, sdaal, radar, reconciliation, domain-layer]
version: "1.1.0"
updated: "2026-07-10"
allowed-tools: Read Write Edit Grep Glob Bash(bash .claude/validation/kg-radar.sh*) Bash(ls docs/*)
argument-hint: "[<arquivo.kg.yaml> | novo <slug>]  (vazio = localizar .kg.yaml existente e rodar radar)"
related_commands:
  - /meta:evolve
  - /meta:graph
  - /meta:co-evolve
related_agents:
  - research-agent
  - onion
---

# /meta:kg — Investigação como Knowledge Graph SDAAL

Investigações longas degradam para **log cronológico**: auto-correções ficam enterradas em prosa,
verdade×verdade não se confronta, conclusões de branch se misturam com o artefato vivo. Este
comando modela a investigação como **grafo tipado num `.kg.yaml`** e usa o **radar determinístico**
para produzir o veredito — a atenção, as reconciliações e a integridade saem do motor, não da
impressão do modelo.

> Doutrina: [knowledge-graph-sdaal.md](../../../docs/knowledge-base/concepts/knowledge-graph-sdaal.md)
> (inclui a nota *"git merge não reconcilia verdades"*, confirmada em campo).
> Rampa da vertical: [ADR verticals](../../../docs/analysis/onion-adr-verticals-investigation-cartography-2026-07.md).

## 🟢 Quando usar

- Auditoria/investigação com **muitos achados que se relacionam** (ex.: rodada de `/meta:evolve`,
  auditoria de produção, reconciliação entre linhagens/branches).
- Quando houver **refutações**: achados plausíveis que caíram sob verificação merecem aresta
  `REFUTES` explícita, não deleção (história reconcilia, não apaga).
- Quando o conflito é **epistêmico** (o que cada lado acredita), não textual — `git merge` não
  resolve; o grafo resolve na camada de conhecimento e o PR sai **dirigido pelo veredito**.

**NÃO** usar para: lista simples de tarefas (use o task manager) · estrutura do próprio framework
(use `/meta:graph`, que é outra lente — derivada da spec-as-code, sem store).

## 📁 Store (eixo SDAAL)

| Provider | O que é | Estado |
|---|---|---|
| **`kg-yaml`** | arquivo local `*.kg.yaml`, determinístico, append-mostly | ✅ default (este comando) |
| **`none`** | investigação sem persistência de grafo | ✅ trivial (não criar arquivo) |

Local canônico no core: `docs/onion/graph/<slug>.kg.yaml`. Em projeto adotado:
`docs/<área>/graph/`. A interface SDAAL formal (`.claude/utils/investigation/`) gradua quando
existir um **2º provider real** — mesma doutrina "costura pronta" do forge GitLab.
**Soberania:** cada instância implementa seu motor; o que viaja na federação é **schema + método**,
nunca o código do radar.

## 📐 Schema do `.kg.yaml` (o que o radar parseia)

```yaml
meta:
  id: <slug>
  date: AAAA-MM-DD
nodes:
  - id: C_MEU_CLAIM          # prefixos por convenção: C_ claim · E_ evidence · D_ decision · Q_ question · A_ artifact
    node_type: claim         # AUDIT: entity | claim | decision | question | evidence | artifact
                             # DOMAIN: entity | state | event | rule | invariant | policy
    layer: audit             # audit (default, epistêmico) | domain (SSOT durável) — omitir = audit
    plane: DEV               # DEV = fonte/branch · PROD = artefato vivo (deploy+config+dados)
    impact: 4                # 1-5
    confidence: 0.9          # 0-1
    status: open             # open | confirmed | refuted | superseded | done
    label: "afirmacao verificavel em uma frase"
    trace: "arquivo:linha"   # migalha inline (o radar ignora; humanos e LLMs seguem)
edges:
  - from: E_EVIDENCIA
    to: C_MEU_CLAIM
    edge_type: SUPPORTS      # AUDIT: SUPPORTS | REFUTES | SUPERSEDES | CAUSES | DEPENDS_ON | TRACES_TO
                             # DOMAIN: HAS_STATE | TRANSITIONS | EMITS | CONSTRAINS | READS | WRITES
    on: EV_GATILHO           # só TRANSITIONS: o evento que dispara (conta como conexão do evento)
```

Peso do nó = `impact × confidence × fator de status` (open/confirmed = 1.0 · refuted = 0 ·
superseded = 0.2 · done = 0.1). Atenção = peso × (1 + grau). **Formato estrito**: uma chave por
linha, listas com `- id:`/`- from:` — o radar é awk, não parser YAML completo.

**As duas camadas (distinção epistêmico×domínio):** `audit` = o que a investigação *acredita*
(efêmero, append-mostly); `domain` = o que o sistema *é* (durável, SSOT: entidades, estados,
eventos, regras). O audit **`TRACES_TO`** o domain — mesma convenção do metagamify (dogfood
2026-07-08), promovida como schema+método. Mesmo arquivo, campo `layer` (separar só se a escala pedir).

## ⚡ Etapas

### Passo 1 — Abrir ou criar o store
- `$ARGUMENTS` com caminho → usar aquele `.kg.yaml`.
- `novo <slug>` → criar `docs/onion/graph/<slug>.kg.yaml` com o esqueleto do schema acima.
- Vazio → `ls docs/onion/graph/*.kg.yaml` e propor o existente mais recente.

### Passo 2 — Modelar (o juízo é seu; a estrutura é do schema)
- Cada **achado** vira `claim` com `plane` honesto (conclusão tirada de branch = DEV; medição do
  artefato vivo = PROD) e `trace` para a fonte.
- Cada **verificação** vira `evidence` + aresta `SUPPORTS` ou `REFUTES`. Refutou? O claim **fica**
  com `status: refuted` — a aresta é a auto-correção explícita.
- Correção que substitui verdade anterior = novo nó + `SUPERSEDES` (nunca editar o antigo além do status).
- Perguntas em aberto viram `question`; decisões tomadas viram `decision` com `TRACES_TO` ao que as gerou.
- **Todo nó precisa de pelo menos 1 aresta** — nó que não se liga a nada não pertence ao grafo
  (ou a ligação existe e você ainda não a nomeou). *Lição do 1º dogfood: a primeira modelagem do
  core deixou 7 órfãos; o radar pegou; a reconciliação revelou 2 questões sistêmicas que a prosa
  escondia.*

### Passo 3 — Rodar o radar (determinístico — o veredito é dele)
```bash
bash .claude/validation/kg-radar.sh docs/onion/graph/<slug>.kg.yaml            # 4 saídas
bash .claude/validation/kg-radar.sh <arquivo> --integrity                      # só o gate (exit 1 se problema)
bash .claude/validation/kg-radar.sh <arquivo> --domain                         # só completude da camada domain
bash .claude/validation/kg-radar.sh <arquivo> --triples                        # triplas p/ consumo por LLM
```
- **RADAR** = onde olhar primeiro (top atenção).
- **RECONCILIAÇÃO** = as auto-correções registradas (REFUTES/SUPERSEDES).
- **RADAR-DE-DOMÍNIO** = completude da camada `domain` (⚠ atenção, **não reprova**): estado-absorvente ·
  EVENT-sem-efeito · STATE-sem-dona · RULE-sem-trace · fonte-única (>1 READS — átomo lendo de 2 fontes).
  *Foi esta checagem que fez o SLOT-limbo emergir do modelo no dogfood do metagamify.*
- **INTEGRIDADE** = órfãos, arestas para nós inexistentes, contradições (REFUTES entrando em nó
  ainda `confirmed`), enums inválidos (incl. `layer`, `on:` para evento inexistente).
  **Exit 1 = reconciliar antes de commitar.**

### Passo 4 — Agir dirigido pelo veredito
- Claims `confirmed` de alta atenção → PRs/atuadores (citar o nó no commit).
- `question` de alta atenção → próximo trabalho a propor ao maestro.
- Conflito DEV×PROD resolvido → **só então** a camada de código muda, na direção que o grafo deu.

## 💡 Exemplos

```bash
/meta:kg novo auditoria-seguranca          # cria docs/onion/graph/auditoria-seguranca.kg.yaml
/meta:kg docs/onion/graph/onion-evolution-2026-07.kg.yaml   # modela/atualiza e roda radar
/meta:kg                                    # localiza o mais recente e roda o radar
```

## ⚠️ Notas

- **Append-mostly**: corrigir = adicionar nó/aresta ou mudar `status`; **nunca** deletar nós
  (auditoria da investigação é o próprio grafo).
- O radar é **gate**: integridade com exit 1 bloqueia o commit do `.kg.yaml` (mesmo espírito dos
  demais scripts de `.claude/validation/`). O radar-de-domínio **não** é gate — lacuna de completude
  é atenção (um estado-absorvente pode ser terminal legítimo; o juízo é seu).
- **Átomos de UI** (design) são nós `layer: domain`: átomo `READS` sua fonte (1 só — fonte-única),
  `TRACES_TO` o componente dono; o `SourceTag` do adotante é a aresta *renderizada*, não motor do core.
  Doutrina: [ADR design-extends-kg](../../../docs/analysis/onion-adr-design-extends-kg-2026-07.md).
- **Fase-2 semântica** (método, não código do core): embeddings + cosseno para flag de redundância
  entre nós — cada instância implementa com seu stack (soberania); o core fica no determinístico.
- 1º dogfood real (56 nós/81 arestas no rhilo; 37 nós/33 arestas no core): ver
  [onion-evolution-2026-07-04.md](../../../docs/analysis/onion-evolution-2026-07-04.md) e o sinal
  [2026-07-04-kg-primeiro-dogfood-federacao.md](../../../docs/evolution/inbox/_processed/2026-07-04-kg-primeiro-dogfood-federacao.md).

## 🔗 Referências

- Doutrina: [knowledge-graph-sdaal.md](../../../docs/knowledge-base/concepts/knowledge-graph-sdaal.md)
- Motor: `.claude/validation/kg-radar.sh` (soberano; awk determinístico)
- Vertical: [onion-adr-verticals-investigation-cartography-2026-07.md](../../../docs/analysis/onion-adr-verticals-investigation-cartography-2026-07.md)
- Lente irmã (estrutura do framework): `/meta:graph`
