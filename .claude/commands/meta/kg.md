---
name: kg
description: |
  Modela uma investigação/auditoria longa como Knowledge Graph SDAAL (.kg.yaml):
  claims/evidência/decisões tipados, arestas SUPPORTS/REFUTES/SUPERSEDES, planes DEV/PROD —
  e, na camada `layer: domain`, o SSOT de domínio (entity/state/event/rule/policy) que o audit TRACES_TO.
  Roda o radar determinístico (kg-radar.sh) para atenção, reconciliação, integridade e radar-de-domínio.
  Modo `map <área>`: PFR de mapeamento completo (inventário → atom-map/fatias → .kg.yaml → radar).
  Nascido do 1º dogfood do core (auditoria /meta:evolve 2026-07-04) — F2 da vertical onion-investigation.
model: sonnet
category: meta
tags: [kg, knowledge-graph, investigation, sdaal, radar, reconciliation, domain-layer]
version: "1.3.0"
updated: "2026-07-16"
allowed-tools: Read Write Edit Grep Glob Bash(bash .claude/validation/kg-radar.sh*) Bash(ls docs/*)
argument-hint: "[<arquivo.kg.yaml> | novo <slug> | map <área>]  (vazio = localizar .kg.yaml existente e rodar radar)"
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
- **`map <área>`**: mapear uma área do sistema (UI ou backend) como SSOT de domínio **antes** de
  redesenhar/refatorar — o contrato primeiro, o pixel/refactor depois (ver Modo map abaixo).

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
  schema_version: "1"        # versão da gramática — o radar RECUSA (--schema) se divergir da que entende
  baseline: AAAA-MM-DD       # opcional: nó PROD com verified_at anterior a esta data = STALE-OLD (--freshness)
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
    verified_against: branch # opt-in: nomeia o artefato MÓVEL rastreado (branch|commit|deploy|config|dump:) — torna o nó rastreado por frescor mesmo em DEV
    verified_at: AAAA-MM-DD  # quando a claim foi cruzada com o vivo (nó PROD ou com verified_against; ausente = ⚠ STALE-MISSING)
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
eventos, regras). O audit **`TRACES_TO`** o domain — mesma convenção de um adotante (dogfood
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
bash .claude/validation/kg-radar.sh docs/onion/graph/<slug>.kg.yaml            # todas as saídas (radar+reconcile+integrity+domain+freshness+schema)
bash .claude/validation/kg-radar.sh <arquivo> --integrity                      # só o gate estrutural (exit 1 se problema)
bash .claude/validation/kg-radar.sh <arquivo> --schema                         # só o gate de schema (exit 1 se schema_version divergir)
bash .claude/validation/kg-radar.sh <arquivo> --freshness                      # só o frescor da SSOT (⚠ STALE-MISSING/STALE-OLD, não reprova)
bash .claude/validation/kg-radar.sh <arquivo> --domain                         # só completude da camada domain
bash .claude/validation/kg-radar.sh <arquivo> --triples                        # triplas p/ consumo por LLM
bash .claude/validation/kg-console.sh <arquivo> > grafo.html                    # VER o grafo (projeção HTML self-contained)
```
- **RADAR** = onde olhar primeiro (top atenção).
- **RECONCILIAÇÃO** = as auto-correções registradas (REFUTES/SUPERSEDES).
- **RADAR-DE-DOMÍNIO** = completude da camada `domain` (⚠ atenção, **não reprova**): estado-absorvente ·
  EVENT-sem-efeito · STATE-sem-dona · RULE-sem-trace · fonte-única (>1 READS — átomo lendo de 2 fontes).
  *Foi esta checagem que fez o SLOT-limbo emergir do modelo no dogfood de campo.*
- **INTEGRIDADE** = órfãos, arestas para nós inexistentes, contradições (REFUTES entrando em nó
  ainda `confirmed`), enums inválidos (incl. `layer`, `on:` para evento inexistente).
  **Exit 1 = reconciliar antes de commitar.**
- **FRESCOR** (⚠ **não reprova**) = a SSOT foi re-verificada contra o vivo? **STALE-MISSING** (nó rastreado —
  `plane:PROD` **ou** com `verified_against:` — sem `verified_at:`) · **STALE-OLD** (`verified_at` anterior à
  `meta.baseline`). Cobre nós DEV que rastreiam artefato móvel (branch/commit), não só PROD. Um nó stale
  **mente**, não corrompe — o veredito é "re-verifique". *Nasceu da lição-mestra do dogfood de campo.*
- **SCHEMA** (✗ **reprova**, exit 1) = `meta.schema_version` bate com o que o radar entende? Divergência
  = recusa (o radar não sabe ler o arquivo); ausência = ⚠ retrocompat. *Teria pego o fork de ferramenta
  no dia 1.*

### Passo 4 — Agir dirigido pelo veredito
- Claims `confirmed` de alta atenção → PRs/atuadores (citar o nó no commit).
- `question` de alta atenção → próximo trabalho a propor ao maestro.
- Conflito DEV×PROD resolvido → **só então** a camada de código muda, na direção que o grafo deu.

## 🗺️ Modo map — mapeamento completo de uma área (PFR)

`map <área>` mapeia uma área do sistema como **SSOT de domínio** antes de qualquer redesign/refactor.
Destilado dos 2 dogfoods de campo (fatias de domínio de produção + atomização do
command-center — exemplares em `docs/evolution/inbox/_processed/2026-07-09-artefato-command-center-atom-map.md`
e `2026-07-08-kg-dogfood-completo-promover.md`). Workflow faseado retomável; cada fase fecha com commit.

### F0 — Inventário exaustivo
Enumerar **tudo** da área antes de decidir qualquer coisa. UI: telas/abas/componentes e cada **dado
exibido** (~100 elementos no dogfood). Backend: entidades, estados, eventos, regras, integrações.
*"Antes de qualquer pixel"* — o inventário é o insumo, não o contrato.

### F1 — O contrato: atom-map (UI) / fatias de domínio (backend)
**UI → produzir o `atom-map.md`** (doc-contrato que as fases de implementação obedecem):
- Tabela por átomo: **`Átomo | Endpoint dono | Conceito (nó do KG) | Dono de EXIBIÇÃO (1) | Dono de ESCRITA (1)`**.
- **Invariante de fonte-única**: 1 átomo = 1 fonte + 1 dono-de-exibição + 1 dono-de-escrita.
  Réplicas viram link ("ver em X") ou `SourceTag` apontando ao dono — **nunca 2ª busca do mesmo
  número por outro endpoint**.
- **`SourceTag`** (rastreabilidade como componente, no stack do adotante): todo elemento que exibe
  dado carrega `endpoint` (fonte) + `concept` (nó do KG) + `formula` (se há transform no front).
- **Ledger de de-duplicação**: cada átomo que hoje aparece N× → decisão registrada de quem fica
  dono e o que as outras exibições viram (corte, link, SourceTag). Átomos parecidos-mas-distintos
  (ex.: configurado ≠ efetivo ≠ override) **separam com rótulo**, nunca se misturam sem rótulo.
- **Pergunta atômica**: cada aba/tela responde **1 pergunta**; os átomos donos listados. Aba que
  não tem pergunta própria funde ou morre.
- **Decisões difíceis registradas** no próprio doc (rótulo honesto: REAL ≠ SIMULAÇÃO; métrica
  sintética que não mede o que promete → funde/renomeia; PII contida e mascarada por padrão).

**Backend/API/funcionalidade → fatias de domínio**: por fatia (ex.: ciclo do SLOT, máquina de SLA),
entidades, estados, transições (com evento gatilho), regras/invariantes — **ancoradas no código**
(arquivo:linha). Endpoint de API = `entity` fonte; funcionalidade = a fatia (cluster de
regras+estados+eventos) que ela toca.

**Jornadas/fluxos → máquina de estados** (por identidade, não analogia): passos da jornada = `state`
do progresso do ator (ou do processo, se fluxo de sistema); avanço = `TRANSITIONS` com `on:` no
evento (ação do usuário ou do sistema); cada passo `TRACES_TO` a tela/endpoint que toca. O radar
paga na hora: **estado-absorvente = ponto de drop-off/limbo do funil** — o mesmo motor que achou o
SLOT-limbo acha onde a jornada morre. Sem tipos novos até um dogfood pedir (gated-until-trigger).

### F2 — Materializar no `.kg.yaml` (o join, per ADR design-extends-kg)
Átomos e fatias viram nós `layer: domain` (`entity/state/event/rule/invariant/policy`); arestas
`HAS_STATE/TRANSITIONS(on)/EMITS/CONSTRAINS/READS/WRITES`; átomo `READS` sua fonte única e
`TRACES_TO` o dono; o atom-map doc e o grafo se referenciam mutuamente (doc = contrato humano;
grafo = camada máquina).

### F3 — Radar + invariante verificável
`kg-radar.sh <arquivo> --domain` (estado-absorvente, EVENT-sem-efeito, STATE-sem-dona,
RULE-sem-trace, fonte-única) + `--integrity` (gate). Lacuna vira **decisão explícita** no grafo
(limbo real ou terminal legítimo?). **Invariante grep-verificável no repo do adotante**: cada
endpoint-dono aparece como fonte de exibição em **1** componente (o "cara-crachá" do front).

### F4 — Adaptador do adotante (fora do core)
Implementar o `SourceTag` no stack local (React/Vue/CLI — soberania: o core dá o schema e o método,
nunca o componente). Redesign/refactor só começa aqui — **dirigido pelo contrato**.

## 💡 Exemplos

```bash
/meta:kg novo auditoria-seguranca          # cria docs/onion/graph/auditoria-seguranca.kg.yaml
/meta:kg docs/onion/graph/onion-evolution-2026-07.kg.yaml   # modela/atualiza e roda radar
/meta:kg                                    # localiza o mais recente e roda o radar
/meta:kg map command-center                 # PFR F0-F4: inventário → atom-map → .kg.yaml → radar
```

## ⚠️ Notas

- **Append-mostly**: corrigir = adicionar nó/aresta ou mudar `status`; **nunca** deletar nós
  (auditoria da investigação é o próprio grafo).
- O radar é **gate**: integridade **ou schema** com exit 1 bloqueia o commit do `.kg.yaml` (mesmo
  espírito dos demais scripts de `.claude/validation/`). O radar-de-domínio e o **frescor** **não** são
  gate — são atenção (um estado-absorvente pode ser terminal legítimo; um nó stale mente mas não
  corrompe — o juízo é seu). Carimbe `verified_at:` nos nós `plane:PROD` quando cruzar a claim com o
  vivo — é o que aposenta o ⚠ STALE-MISSING e deixa o próximo leitor (humano ou IA) confiar sem re-checar.
- **Átomos de UI** (design) são nós `layer: domain`: átomo `READS` sua fonte (1 só — fonte-única),
  `TRACES_TO` o componente dono; o `SourceTag` do adotante é a aresta *renderizada*, não motor do core.
  Doutrina: [ADR design-extends-kg](../../../docs/analysis/onion-adr-design-extends-kg-2026-07.md).
- **Fase-2 semântica** (método, não código do core): embeddings + cosseno para flag de redundância
  entre nós — cada instância implementa com seu stack (soberania); o core fica no determinístico.
- 1º dogfood real (56 nós/81 arestas em um adotante; 37 nós/33 arestas no core): ver
  [onion-evolution-2026-07-04.md](../../../docs/analysis/onion-evolution-2026-07-04.md) e o sinal
  [2026-07-04-kg-primeiro-dogfood-federacao.md](../../../docs/evolution/inbox/_processed/2026-07-04-kg-primeiro-dogfood-federacao.md).

## 🔗 Referências

- Doutrina: [knowledge-graph-sdaal.md](../../../docs/knowledge-base/concepts/knowledge-graph-sdaal.md)
- Motor: `.claude/validation/kg-radar.sh` (soberano; awk determinístico)
- Vertical: [onion-adr-verticals-investigation-cartography-2026-07.md](../../../docs/analysis/onion-adr-verticals-investigation-cartography-2026-07.md)
- Lente irmã (estrutura do framework): `/meta:graph`
