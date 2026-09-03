---
name: kg
description: |
  Modela uma investigação/auditoria longa como Knowledge Graph SDAAL (.kg.yaml):
  claims/evidência/decisões tipados, arestas SUPPORTS/REFUTES/SUPERSEDES, planes DEV/PROD —
  e, na camada `layer: domain`, o SSOT de domínio (entity/state/event/rule/policy) que o audit TRACES_TO.
  Roda o radar determinístico (kg-radar.sh) para atenção, reconciliação, integridade e radar-de-domínio.
  Modo `map <área>`: PFR de mapeamento completo (inventário → atom-map/fatias → .kg.yaml → radar).
  Nascido do 1º dogfood do core (auditoria /meta:evolve 2026-07-04) — F2 da vertical onion-investigation.
category: meta
tags: [kg, knowledge-graph, investigation, sdaal, radar, reconciliation, domain-layer]
version: "1.4.0"
updated: "2026-07-21"
allowed-tools: Read Write Edit Grep Glob Bash(bash ${CLAUDE_PLUGIN_ROOT}/validation/kg-radar.sh*) Bash(bash ${CLAUDE_PLUGIN_ROOT}/validation/kg-provenance-coverage.sh*) Bash(ls docs/*)
argument-hint: "[<arquivo.kg.yaml> | novo <slug> | map <área> | diagnose <slug> | backfill [<escopo>]]  (vazio = localizar .kg.yaml existente e rodar radar)"
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

> Doutrina: [knowledge-graph-sdaal.md](${CLAUDE_PLUGIN_ROOT}/kb/knowledge-graph-sdaal.md)
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
  review_after: AAAA-MM-DD   # grafos de PESQUISA: quando revisitar (cadência por tipo — ferramenta 30d · modelos 45d · mercado 90d · benchmark 120d · doutrina 12m); vencido = SOFT no lint
  date: AAAA-MM-DD
nodes:
  - id: C_MEU_CLAIM          # prefixos por convenção: C_ claim · E_ evidence · D_ decision · Q_ question · A_ artifact
    node_type: claim         # AUDIT: entity | claim | decision | question | evidence | artifact
                             # DOMAIN: entity | state | event | rule | invariant | policy
    layer: audit             # audit (default, epistêmico) | domain (SSOT durável) — omitir = audit
    plane: DEV               # DEV = fonte/branch · PROD = artefato vivo (deploy+config+dados)
    impact: 4                # 1-5
    confidence: 0.9          # 0-1
    status: open             # open | confirmed | drifted | unverifiable | refuted | superseded | done
                             # drifted/unverifiable: saída de re-verificação (/meta:kg-freshness)
    verified_against: branch # nomeia o ALVO verificado (branch|commit|deploy|config|dump:) — rastreia por frescor mesmo em DEV; obrigatório junto de verified_at EM node_type: claim (ausente = ⚠ UNANCHORED); nos demais tipos a âncora é trace:/TRACES_TO
    verified_at: AAAA-MM-DD  # quando a claim foi cruzada com o vivo (nó PROD ou com verified_against; ausente = ⚠ STALE-MISSING)
    valid_from: AAAA-MM-DD   # opcional (evidence): quando o FATO passou a valer — bi-temporal: ≠ verified_at (quando VOCÊ verificou)
    source_tier: 8           # opcional (evidence): autoridade da fonte 1-10 (escala DREAM: 9-10 definitiva · 7-8 alta · 4-6 moderada · 1-3 baixa)
    source_kind: primary     # opcional (evidence): primary | paper | engineer | analyst | forum | vendor-on-competitor | aggregator
                             # confidence ≥ 0.8 com tier ≤ 3 ou vendor-on-competitor = SOFT no lint (doutrina: common/prompts/research-doctrine.md)
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
- **Pesquisa?** Antes de modelar, a lente: [`research-doctrine.md`](../common/prompts/research-doctrine.md) (corpus primeiro via `kg-corpus-grep.sh`, mercado invariante, tier de fonte, bi-temporal, revisita).
- Cada **achado** vira `claim` com `plane` honesto (conclusão tirada de branch = DEV; medição do
  artefato vivo = PROD) e `trace` para a fonte.
- Cada **verificação** vira `evidence` + aresta `SUPPORTS` ou `REFUTES`. Refutou? O claim **fica**
  com `status: refuted` — a aresta é a auto-correção explícita.
- **Evidência de TERCEIRO carrega o interesse da fonte.** Confirmar que o documento existe e diz X não
  é ler **como X foi construído** — anote no `label`/`trace` do nó *quem produziu e o que ganha com o
  que diz*, e leia a **estrutura** (achados replicados por superfície, severidade fora da faixa usual,
  incentivo impresso no próprio texto). O que a fonte concede **contra o próprio interesse** é a parte
  de **maior** confiança; o que ela afirma **a favor** do próprio interesse pede desconto — mas
  interesse **qualifica, não anula** (achado distinto e de lógica de negócio não se relativiza).
  Doutrina: [evidence-source-interest.md](../../../docs/knowledge-base/concepts/evidence-source-interest.md).
- Correção que substitui verdade anterior = novo nó + `SUPERSEDES` (nunca editar o antigo além do status).
- Perguntas em aberto viram `question`; decisões tomadas viram `decision` com `TRACES_TO` ao que as gerou.
- **Todo nó precisa de pelo menos 1 aresta** — nó que não se liga a nada não pertence ao grafo
  (ou a ligação existe e você ainda não a nomeou). *Lição do 1º dogfood: a primeira modelagem do
  core deixou 7 órfãos; o radar pegou; a reconciliação revelou 2 questões sistêmicas que a prosa
  escondia.*

### Passo 3 — Rodar o radar (determinístico — o veredito é dele)
```bash
bash ${CLAUDE_PLUGIN_ROOT}/validation/kg-radar.sh docs/onion/graph/<slug>.kg.yaml            # todas as saídas (radar+reconcile+integrity+domain+freshness+schema)
bash ${CLAUDE_PLUGIN_ROOT}/validation/kg-radar.sh <arquivo> --integrity                      # só o gate estrutural (exit 1 se problema)
bash ${CLAUDE_PLUGIN_ROOT}/validation/kg-radar.sh <arquivo> --schema                         # só o gate de schema (exit 1 se schema_version divergir)
bash ${CLAUDE_PLUGIN_ROOT}/validation/kg-radar.sh <arquivo> --freshness                      # só o frescor da SSOT (⚠ STALE-MISSING/STALE-OLD/UNANCHORED/MISPLANED, não reprova)
bash ${CLAUDE_PLUGIN_ROOT}/validation/kg-radar.sh <arquivo> --domain                         # só completude da camada domain
bash ${CLAUDE_PLUGIN_ROOT}/validation/kg-radar.sh <arquivo> --triples                        # triplas p/ consumo por LLM
bash ${CLAUDE_PLUGIN_ROOT}/validation/kg-console.sh <arquivo> > grafo.html                    # VER o grafo (projeção HTML self-contained)
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
  `meta.baseline`) · **UNANCHORED** (`node_type: claim` com `verified_at:` mas **sem** `verified_against:` —
  carimbo sem alvo declarado; os demais tipos ancoram por `trace:`/`TRACES_TO` e entram numa linha `ℹ` contada,
  nunca suprimidos em silêncio) · **MISPLANED** (`plane: PROD` com `verified_against: branch|commit` — o nó
  afirma sobre o **vivo** e declara ter olhado a **fonte**; contradição interna, vale para **todos** os tipos). Cobre nós DEV que rastreiam artefato móvel (branch/commit), não só PROD. Um nó stale
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

## 🧾 Modo backfill — pagar passivo de proveniência invertida

`backfill [<escopo>]` responde a pergunta de **fora do grafo para dentro**: *"que documentos deste
corpus ainda não existem no grafo?"* — e paga o passivo em levas, até a catraca chegar ao piso.

Destilado do dogfood de 2026-07-20/21 no próprio core: **92 documentos, baseline 75 → 0**, grafo de
677 para 881 nós em 6 levas. Workflow faseado retomável; cada leva fecha com commit.

> **O achado que justifica o modo**: ~2/3 do passivo **já tinha morrido em código** e ninguém marcou
> — pesquisa entregue, contagem virada SSOT gerada, herança de escopo já em `compose-settings.sh`.
> O core carregava dívida quitada nos livros. Lei destilada: *backlog em prosa datada renasce todo
> dia e só morre quando vira guarda de lint ou SSOT gerada.*

### F0 — Medir (não estimar)

```bash
bash ${CLAUDE_PLUGIN_ROOT}/validation/kg-provenance-coverage.sh                       # escopo canônico (com catraca)
bash ${CLAUDE_PLUGIN_ROOT}/validation/kg-provenance-coverage.sh --scope <dir>         # outro corpus (EXPLORATÓRIO)
```

`--scope` sem `--baseline` **não arma catraca** — mede e devolve a pauta. É estrutural: escopo alheio
contra o baseline canônico produziria órfãs em massa e HARDs falsos, e gate que cospe falso é gate
desligado. Para armar catraca num escopo novo, `--baseline <arquivo>` de propósito.

### F1 — Levas: um worker por documento

Leva de **~16 documentos**, **um subagente `sonnet`/`medium` por documento** (paralelo). Contrato do
worker, cada cláusula paga por erro real da rodada de origem:

- **`doc` recebe o PATH, nunca o texto** — worker que devolve o conteúdo estoura o contexto do merge.
- **ids em inglês com prefixo de leva** (`B3_7_…`), **labels em pt-BR**, **`trace:` obrigatório**.
- **Nada de placeholder.** Um worker emitiu `id: a`, `label: x`, `trace: y` e **passou** no merge
  porque satisfazia o *schema* — quem pegou foi a consequência (um documento sem cobertura), não a
  regra. Rejeite `id`/`label` com ≤3 caracteres.
- **Nome comercial de cliente não entra — nem em label, NEM EM ID.** O vazamento real da rodada foi
  por ID, não por prosa (é o que a REGRA 30 guarda hoje).
- **Modele por gênero** (review → achados+veredito; mapa conceitual → entidades e relações;
  pesquisa → veredito e decisões, não a recontagem de hipóteses; material bruto → 3-5 nós bastam).
  **Não infle documento pobre em achados**: forçar 10 nós num doc que tem 3 é ruído com aparência
  de rigor.
- **O worker NÃO julga se ainda vale** — isso é da F2, que tem acesso ao estado atual.

### F2 — Sintetizador: as três perguntas que pagaram em todas as levas

Um subagente `opus`/`high` por leva, com acesso ao repo e ao grafo existente:

1. **Já virou realidade?** Procurar em `.claude/` (commands, skills, validation, utils, agents),
   `docs/knowledge-base/`, `docs/evolution/rfc/`, `docs/meta-specs/`. Existe → nó `evidence`
   `plane: PROD` com **trace REAL** + `SUPERSEDES` para a question/decision.
   ⚠️ **ABRIR o arquivo.** Sem prova, fica `open`. Afirmar por nome plausível é o erro que custou
   caro na rodada de origem (ver [[read-full-content-before-triage]]).
2. **Duplicata?** — do que já está no grafo, ou de outro documento da mesma leva.
3. **Cruza com o grafo existente?** — arestas para os nós que já existem, senão a leva vira ilha.

### F3 — Merge, radar, catraca

- Merge rejeitando placeholder, filtrando aresta pendurada e **reconciliando status**
  (`REFUTES`/`SUPERSEDES` exigem que o alvo saia de `open`).
- `kg-radar.sh <arquivo> --integrity --schema` — **espere exigências**; em toda leva houve. Na
  última: dois nós órfãos e uma contradição de status, mais uma aresta que eu modelara como
  `REFUTES` quando a relação honesta era `DEPENDS_ON`. **O radar é o revisor.**
- Regenerar o baseline (`--emit-baseline > <baseline>`) e **medir antes de escrever o commit**:
  contar pelo **radar**, nunca pelo andaime de merge (o script descartável da rodada reportou
  "+209 nós" por aritmética de linhas quando a verdade eram 204).

### ⚠️ O limite deste modo

O gate mede **cobertura, não verdade**: exige que cada documento tenha *um nó*. Nó raso e genérico
**passa**. Enquanto quem alimenta for orquestração com verificação adversarial, o flanco fica
fechado; virando rotina apressada, o gate fica verde sobre grafo oco — e aí mente com autoridade de
mecanismo. Ver [[inverted-provenance-ratchet]] no diário.

## 🎙️ Modo narrate — a IA que EXPLICA o grafo (narração pré-cozida)

`narrate <slug>` autora a **narração** que o `kg-console.sh` embute e toca **offline**: um tour
guiado que dirige a câmera e o foco em **ordem de atenção**, mais um resumo por nó. É o leg que
faltava do "explicado por IA" — não é live-chat (que quebraria o autocontido/CSP), é **autorado
uma vez e embutido**; o grafo se explica no cliente.

> **A narração é PROJEÇÃO dos 4 vereditos do radar, nunca fonte paralela.** Cita **ids de nó**,
> nunca re-deriva da prosa. Todo id citado **existe no grafo** — garantido por mecanismo
> (`kg-narrate-validate.sh`, **REGRA 47**), não por promessa. Ordem do tour = atenção; passos de
> Aufhebung = arestas REFUTES/SUPERSEDES; passo "o que re-verificar" = os nós STALE.

**Artefato** (irmão do `.kg.yaml`): `docs/onion/graph/<slug>.narration.json`
```json
{ "graph":"<slug>", "generated_from":"kg-radar+kg-view", "generated_at":"AAAA-MM-DD",
  "node_summaries": { "<id>": "resumo pt-BR (1 frase)" },
  "guided_tour": [ { "focus":["<id>"], "camera":"fit", "narration":"texto pt-BR" } ] }
```

### F0 — Ler o veredito (a narração projeta ISTO)
```bash
bash ${CLAUDE_PLUGIN_ROOT}/validation/kg-radar.sh <arquivo> --radar          # atenção → ordem do tour
bash ${CLAUDE_PLUGIN_ROOT}/validation/kg-radar.sh <arquivo> --reconcile      # REFUTES/SUPERSEDES → passos de Aufhebung
bash ${CLAUDE_PLUGIN_ROOT}/validation/kg-radar.sh <arquivo> --freshness-tsv  # STALE → passo "o que re-verificar"
bash ${CLAUDE_PLUGIN_ROOT}/validation/kg-radar.sh <arquivo> --open-tsv        # a FILA COMPLETA de trabalho aberto

# a fila do CORPUS INTEIRO (o radar lê um grafo por vez; o laço é de quem chama):
for f in $(git ls-files '*.kg.yaml' | grep -v /fixtures/); do
  bash ${CLAUDE_PLUGIN_ROOT}/validation/kg-radar.sh "$f" --open-tsv
done | sort -t$'\t' -k8 -rn | head -20
bash ${CLAUDE_PLUGIN_ROOT}/validation/kg-view.sh  <arquivo> --json           # os ids canônicos (paridade com o radar)
```

### F1 — Autorar (escala decide serial × orquestração)
- **≤ ~40 nós:** autore em sessão única — leia o radar e escreva o tour + resumos direto.
- **Grande:** delegue à skill **`onion-orchestration`** (fan-out): 1 worker `sonnet`/`medium` por
  lote de nós de alta atenção resume (recebe `--triples`+`--freshness-tsv`+`label` — **não
  inventa**); 1 sintetizador `opus`/`high` monta o `guided_tour`. **Arco canônico**: abertura (leia
  por atenção) → focos de maior atenção → escada de reconciliação (incl. refutação retrógrada
  PROD→DEV) → fronteira honesta (nós STALE). O último passo é sempre "o que fazer agora".

### F2 — Validar (o gate, não opcional)
```bash
bash ${CLAUDE_PLUGIN_ROOT}/validation/kg-narrate-validate.sh <arquivo.kg.yaml>   # exit 0 = todos os ids existem
```
Exit 1 = cita id que o grafo não tem → corrija antes de commitar (a REGRA 47 reprova no CI).

### F3 — Regenerar o console e ver
```bash
bash ${CLAUDE_PLUGIN_ROOT}/validation/kg-console.sh <arquivo.kg.yaml> > /tmp/console.html
```
O console detecta o `.narration.json` irmão e o embute (opt-in). Sem ele, degrada para o
**tour-esqueleto** (ordem de atenção, sem prosa). O `kg-console.sh` continua **LLM-free** — só
EMBUTE a narração; o único ponto com IA é a autoria (F1), fora do script. Na federação viaja o
**schema + método** (o arco canônico), nunca o JS do renderer.

## 🩺 Modo diagnose — o KG como DIAGNÓSTICO de engajamento

`diagnose <slug>` mapeia um **engajamento de consultoria** (descoberta de negócio) como KG SDAAL de
2 camadas, e usa o **radar como motor de diagnóstico**. É o **irmão de negócio do `map`**: o `map`
mapeia software (UI/backend, atom-map, fonte-única); o `diagnose` mapeia um cliente/processo. Nasceu
de dogfood de campo (um engajamento real, ~107 nós/172 arestas, 9 lotes — o radar **ranqueou o foco**
por atenção e a **camada de domínio flagou os gargalos**; a reconciliação é modelada pelo humano e o
radar a **torna visível**, não a inventa).

> **A tese-núcleo do Onion aplicada ao diagnóstico:** o grafo é runtime, o **radar diagnostica**.
> Cada primitiva do radar ganha leitura de consultoria (tabela abaixo). O consultor **não escolhe o
> foco a dedo** — o radar ranqueia por atenção; o humano sela.

### A releitura das primitivas (o que o `map` NÃO tem)

| Primitiva do radar | No `map` (software) | No `diagnose` (engajamento) |
|---|---|---|
| **atenção** (`--radar`) | o nó crítico do sistema | **onde focar a consultoria** (impact × confidence × conectividade) |
| **reconciliação** (`--reconcile`) | verdade × verdade no código | **a hipótese que a descoberta REFUTOU** (fontes conflitam → `claim` a reconciliar) |
| **estado-absorvente** (`--domain`) | SLOT-limbo / drop-off de dado | **o gargalo/drop-off do CLIENTE** — onde a jornada morre |
| **STATE-sem-dona** (`--domain`) | estado sem entity dona | **ator/etapa sem responsável** no processo |
| **EVENT-sem-efeito** (`--domain`) | evento que não origina aresta | **evento sem consequência** no engajamento |

**Não transfere do `map`:** `atom-map`, `SourceTag`, invariante de `fonte-única` (READS>1) e o
adaptador F4 — são conceitos de **front-end**. O que transfere é o padrão **"fatias de domínio /
máquina de estados por identidade"** (a jornada do cliente/processo como `state` + `TRANSITIONS`).

### As 2 camadas, no diagnóstico

- **`layer: domain`** = o **negócio do cliente** (SSOT durável): `entity` (stakeholders, produtos,
  ativos), `state`/`event`/`TRANSITIONS` (a jornada/processo), `rule`/`policy` (as regras do negócio).
  `plane: PROD` = fato consolidado do domínio.
- **`layer: audit`** = a **epistemologia da consultoria** (efêmero): `claim` (hipóteses/teses),
  `evidence` (o que as fontes afirmam), `question` (o que ainda cobra resposta), `decision` (o que se
  decidiu), `artifact` (os entregáveis). `plane: DEV` = hipótese/trabalho.
- **Ponte:** cada nó de audit `TRACES_TO` o nó de domínio que ele afeta — o "join" que ancora a
  crença no negócio real (a aresta dominante no dogfood: 67 `TRACES_TO`).

### O pipeline de ingestão (reusa o que já existe)

```
sources/  (transcrições, docs, deck do cliente → proxy textual .md; binário pesado no .gitignore)
   │  F0 inventário / descoberta
   ▼
extracts/  ← /product:extract-meeting (EXTRACT: decisões, gaps, contradições, deps, stakeholders, timeline)
   │  extração (um .md por fonte)
   ▼
consolidated/  ← /product:consolidate-meetings (bloco de proveniência F1..Fn + Convergências/Divergências)
   │  fusão multi-fonte — DIVERGÊNCIA entre fontes = claim a reconciliar
   ▼
docs/<área>/graph/<slug>.kg.yaml  ← ESTE modo: modela o consolidado como KG de 2 camadas
```

O `extract-meeting` e o `consolidate-meetings` **já existem** — o `diagnose` **consome** a saída
deles; não os reimplementa. A triagem de proveniência da consolidação (nada entra no grafo sem
passar pelo crivo Convergência/Divergência) é o que mantém o KG honesto.

### A cadência — construir → pausar → perguntar → responder (humano-no-loop)

Faseado retomável, **serial** (como o `map`, não orquestração). Checkpoint durável = o `.kg.yaml`
commitado por lote + um `STATE.md` com ponteiro `NEXT` retomável.

- **F0 — inventário:** varre as fontes, classifica textual vs binário (binário → proxy textual),
  levanta pendências → primeira PAUSA.
- **LOTE 1..N:** cada lote é um incremento **temático** fechado do grafo (ciclo comercial → pessoas
  → hipótese → entrega → …), com o **delta de nós/arestas anotado** e o **radar como GATE** ao
  fechar: `kg-radar.sh <arquivo> --integrity --schema` tem de sair **exit 0** (todo nó ≥1 aresta,
  enums válidos). Só passa com integridade limpa.
- **PAUSA numerada (entre lotes):** o construtor **para**, as perguntas abertas viram nós
  `question`; o maestro **responde** em texto **carimbado** (autor + data); cada resposta resolve
  uma ou mais `question` — marque `Q_… → RESOLVIDA → D_…`. Toda pergunta tem rastro de nascimento e
  de morte. Registre num `notes.md` **append-only** (nunca reescreva; só anexe).
- **Reconciliação é cidadã de 1ª classe:** hipótese que a descoberta derrubou **não se apaga** —
  `status: refuted`/`superseded` + aresta `REFUTES`/`SUPERSEDES`. O grafo guarda a história
  epistêmica: o que se achou, o que caiu, quem derrubou.

### Rodar o diagnóstico (o radar é o motor)

```bash
bash ${CLAUDE_PLUGIN_ROOT}/validation/kg-radar.sh docs/<área>/graph/<slug>.kg.yaml --radar        # o FOCO (atenção)
bash ${CLAUDE_PLUGIN_ROOT}/validation/kg-radar.sh docs/<área>/graph/<slug>.kg.yaml --domain       # o GARGALO (estado-absorvente)
bash ${CLAUDE_PLUGIN_ROOT}/validation/kg-radar.sh docs/<área>/graph/<slug>.kg.yaml --reconcile    # as hipóteses refutadas
bash ${CLAUDE_PLUGIN_ROOT}/validation/kg-radar.sh docs/<área>/graph/<slug>.kg.yaml --integrity --schema   # o GATE por lote
```

### Automação parcial — o mecânico, NUNCA o julgamento

O que dá pra automatizar sem virar caixa-preta: **o fan-out mecânico**, preservando a **PAUSA** como
gate humano duro. É `generate-and-filter` com selo humano — o pipeline gera candidatos, o radar filtra
por atenção, o **humano sela**. O precedente no core: o eixo `interactive` do `/product:transform-consolidated`
(a análise roda sozinha; a validação por bloco só com o humano) e o dry-run-como-gate do `onion-wizard`.

- **F0 — store (auto):** `bash ${CLAUDE_PLUGIN_ROOT}/utils/diagnose/scaffold-diagnose-store.sh <slug> [--area <área>]`
  cria o store inteiro (skeleton `.kg.yaml` de 2 camadas + `STATE.md` com `NEXT` retomável + `notes.md`
  append-only + `sources/ extracts/ consolidated/`). Never-clobber, `--dry-run`, idempotente. Fecha o
  "skeleton à mão". → **PAUSA:** preencha `sources/` e confirme o escopo antes de extrair.
- **Extração/consolidação (auto):** `/product:extract-meeting` por fonte → `/product:consolidate-meetings`.
  Rodam ponta-a-ponta (nenhum tem gate). Produzem o consolidado com Convergências/**Divergências**.
- **Candidatos (auto):** as **Divergências** viram nós `question`/`claim` **candidatos** no `.kg.yaml`; o
  radar ranqueia por atenção. É o fan-out mecânico — não o diagnóstico.
- **→ PAUSA (o selo — inegociável):** o humano **revisa os candidatos por bloco**, responde as
  `question`, sela as `claim`, decide as reconciliações. `Q_… → RESOLVIDA → D_…` no `notes.md`
  (carimbado autor+data). **Nenhuma reconciliação/decisão se materializa sem o selo humano.**
- **Gate por lote (auto):** ao fechar o lote, `kg-radar --integrity --schema` (exit 0) roda sozinho; o
  `STATE.md.NEXT` avança. Retoma frio pelo NEXT-pointer.

> **🚩 A linha vermelha:** a automação substitui **só o fan-out mecânico** (scaffold, extract/consolidate,
> geração de candidatos, gate-do-radar). **Nunca** o selo humano na PAUSA. **Não existe `--auto` de
> diagnóstico** de propósito — ao contrário do `transform` (onde `auto` é legítimo porque tasks não são
> diagnóstico). O diagnóstico sem a pausa vira gerador-de-conteúdo, o anti-padrão que o KG-SDAAL combate:
> o skeleton **vazio reprova o radar de propósito** (0 nós não é grafo — anti-falso-verde); o valor
> nasce do humano que preenche e sela, lote a lote.

### ⚠️ Soberania — o engajamento é do adotante, o método é do core

O **método/modo** viaja na federação (schema + a cadência + a releitura das primitivas). O **KG do
engajamento** — dado do cliente, nós confidenciais marcados — **fica no repo dev do adotante e NUNCA
sai**. O core segura o padrão, jamais o cliente (mesma partição de visibilidade do gate client-safe).
Antes de qualquer projeção cruzar fronteira (material pro cliente, sinal pro core), rode o gate:
`bash ${CLAUDE_PLUGIN_ROOT}/validation/projection-safety.sh --terms <lista-de-clientes> <artefato>` → `grep`=0.

## 💡 Exemplos

```bash
/meta:kg novo auditoria-seguranca          # cria docs/onion/graph/auditoria-seguranca.kg.yaml
/meta:kg docs/onion/graph/onion-evolution-2026-07.kg.yaml   # modela/atualiza e roda radar
/meta:kg                                    # localiza o mais recente e roda o radar
/meta:kg map command-center                 # PFR F0-F4: inventário → atom-map → .kg.yaml → radar (software)
/meta:kg diagnose cliente-acme-2026-07       # engajamento como KG 2-camadas; radar = diagnóstico (atenção/gargalo/reconciliação)
/meta:kg narrate m2-bridge-logto-2026-07     # autora a narração pré-cozida (tour + resumos) p/ o console
```

## ⚠️ Notas

- **Grafo primeiro, relatório depois** (contrato para os consumidores): `/meta:evolve`,
  `/meta:kb-freshness` e `/meta:context-freshness` — e qualquer comando que produza achados
  estruturados — materializam aqui **antes** de renderizar seu relatório final; o markdown é
  **projeção** do `.kg.yaml`, nunca fonte paralela. Senão o grafo vira predecessor da avaliação em
  vez de destino dela (sinal de campo de um adotante regulado, 2026-07-20: uma avaliação de 70 agentes com 60
  achados estruturados em JSON não deixou nó nenhum no SSOT — o plano declarara "saída:
  relatório.md").
- **Append-mostly**: corrigir = adicionar nó/aresta ou mudar `status`; **nunca** deletar nós
  (auditoria da investigação é o próprio grafo).
- O radar é **gate**: integridade **ou schema** com exit 1 bloqueia o commit do `.kg.yaml` (mesmo
  espírito dos demais scripts de `${CLAUDE_PLUGIN_ROOT}/validation/`). O radar-de-domínio e o **frescor** **não** são
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

- Doutrina: [knowledge-graph-sdaal.md](${CLAUDE_PLUGIN_ROOT}/kb/knowledge-graph-sdaal.md)
- Motor: `${CLAUDE_PLUGIN_ROOT}/validation/kg-radar.sh` (soberano; awk determinístico)
- Vertical: [onion-adr-verticals-investigation-cartography-2026-07.md](../../../docs/analysis/onion-adr-verticals-investigation-cartography-2026-07.md)
- Lente irmã (estrutura do framework): `/meta:graph`
