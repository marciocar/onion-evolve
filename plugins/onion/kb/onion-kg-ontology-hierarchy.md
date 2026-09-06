# Ontologia e Hierarquia dos grafos `.kg.yaml` — o mapa MACRO

> **O que este doc é.** O **lar canônico da camada MACRO** do KG SDAAL: quais TIPOS de grafo `.kg.yaml`
> existem, o PAPEL de cada um, e como eles se conectam/espelham através de core ↔ pesquisa ↔ testes ↔
> adotante ↔ verticais. A ontologia do **ÁTOMO** (enums de nó/aresta/status/plane/layer) NÃO mora aqui —
> mora no radar (fonte única) e é espelhada na gramática; este doc **aponta** para ela, não a re-duplica.
> A doutrina densa (por que grafo) vive em [`knowledge-graph-sdaal.md`](knowledge-graph-sdaal.md); a rampa
> prática em `kg-getting-started.md`; a gramática de campo em
> `../../../.claude/rules/kg-grammar.md`.
>
> **Por que este doc existe (medido 2026-08-27):** a ontologia do átomo era canônica e enforced, mas a
> camada MACRO — a taxonomia de KINDS de grafo e o mapa de como eles se ligam — vivia só em nomes de
> arquivo + um fragmento enterrado no `/onion:backlog`. Uma maquinaria que **revê** grafos (ex.:
> `/onion:realign`) precisa saber *que tipo* de grafo revê e *como ele se liga* aos outros; sem este mapa,
> ela construiria sobre convenção implícita. Levantado pelo maestro como pré-requisito ("Fase 0").

## 0. ⚠️ Desambiguação — há DOIS sistemas de grafo no repo

Não confunda:
- **KG SDAAL** (`.kg.yaml`) — grafo de **conhecimento de investigação/domínio**. É o objeto deste doc.
  Motor: `${CLAUDE_PLUGIN_ROOT}/validation/kg-radar.sh`. Store: `docs/onion/graph/`, `docs/evolution/research/`.
- **`meta:graph`** — grafo **sócio-técnico da spec-as-code** (o framework se descrevendo). TBox próprio em
  `onion-relation-vocabulary.md`; gerado por `${CLAUDE_PLUGIN_ROOT}/validation/graph.sh` →
  `docs/onion/graph.md`. **Não** é `.kg.yaml` e **não** é revisado pelo radar.

## 1. O ÁTOMO — SSOT única, referenciada (não re-duplicada aqui)

A autoridade mecânica do vocabulário de átomo é o **radar**: `kg-radar.sh` define `node_type` (linha ~252),
`edge_type` (~253), `schema_version` (~84), e valida `status`/`plane`/`layer`/`impact`/`confidence` como enum
que **reprova** (exit 1). Espelhos documentais (consistentes, cross-referenciados): `kg-grammar.md` (a tabela
anti-drift dos nomes de campo), `knowledge-graph-sdaal.md` (doutrina), `kg-getting-started.md` (rampa),
`commands/meta/kg.md §Schema`. **Regra DRY:** ao precisar do vocabulário de átomo, cite a gramática/radar —
nunca re-escreva os enums (foi a duplicação em 4 lugares que já deixou `invariant` driftar de uma lista curta).

As **duas camadas** (a única taxonomia de grafo já canônica antes deste doc):
- `layer: audit` (default) — epistêmico: `claim`/`evidence`/`decision`/`question`/`entity`/`artifact`, arestas
  `SUPPORTS`/`REFUTES`/`SUPERSEDES`/`CAUSES`/`DEPENDS_ON`/`TRACES_TO`.
- `layer: domain` — o SSOT de domínio: `entity`/`state`/`event`/`rule`/`invariant`/`policy`, arestas
  `HAS_STATE`/`TRANSITIONS`/`EMITS`/`CONSTRAINS`/`READS`/`WRITES`.

## 2. O MACRO — taxonomia de KINDS de grafo por PAPEL

Cada `.kg.yaml` é de um KIND. O KIND não é um campo (é convenção de papel), mas determina o `layer`/`plane`
esperado, o lifecycle e os marcadores. Os KINDS canônicos:

| KIND | Papel | Local típico | layer/plane | Marcador | Exemplo |
|---|---|---|---|---|---|
| **plano/backlog** | a RELAÇÃO cross-grafo + a fila de execução (ondas, DEPENDS_ON) | `docs/onion/graph/` | audit / DEV | `# kg-backlog-guard: on` | `fios-abertos.kg.yaml` |
| **decision-history** | a memória de decisão de uma área (PRs, catraca, incidentes) | `docs/onion/graph/` | audit / PROD | — | `pr-decision-history-2026-08.kg.yaml`, `catraca-regra49-2026-08.kg.yaml` |
| **audit** (`meta:evolve`) | achados de auto-auditoria com evidência citada | `docs/onion/graph/` | audit / DEV+PROD | — | `onion-evolution-2026-07*.kg.yaml` |
| **domain-SSOT** (`/onion:kg map`) | o modelo de domínio de um sistema (entity/state/event/rule) | `docs/onion/graph/` ou `docs/<área>/graph/` | domain / PROD | — | grafos de `map` |
| **research** | investigação que NASCE no grafo (REGRA 43) | `docs/evolution/research/<tema>/` | audit / DEV | — | `kg-read-leg-2026-08/*.kg.yaml` |
| **identity/estratégia** | posicionamento, north-star, tese | `docs/onion/graph/` | audit / mix | — | `onion-identity-2026-07.kg.yaml` |
| **superação** | um erro→cura, `SUPERSEDES` datado (Aufhebung) | `docs/onion/graph/` | audit / PROD | — | `sync-gate-superacao-2026-08.kg.yaml` |
| **fixtures** | contrato de conformidade do radar (multi-runtime) | `${CLAUDE_PLUGIN_ROOT}/validation/fixtures/kg-*/` | os dois | — | `fixtures/kg-reconcile/*.kg.yaml` |
| **overlay/constellation** | grafo-de-grafos: reconcilia premissas ENTRE estudos (gated) | `docs/onion/graph/` | audit / DEV | curado à mão | `constellation.kg.yaml` |
| **arquivado** | grafo epistêmico histórico, fora do backlog | qualquer | — | `# kg-backlog-archive: on` | pesquisas antigas |

## 3. A HIERARQUIA e o ESPELHAMENTO — como os grafos se conectam

**A fronteira que rege tudo (declarada no `fios-abertos.kg.yaml §FRONTEIRA`):** *"NENHUM FATO NASCE AQUI… a
única coisa que não cabe nos grafos existentes é a RELAÇÃO ENTRE ELES."* O radar **só enxerga arestas DENTRO
de um arquivo**; a relação cross-grafo vive num grafo-de-relação (o `fios-abertos`, que cita ids alheios) ou
no overlay `constellation` (gated). **Teste do nó cross-grafo:** se eu apagar este nó, perco um FATO ou só a
ORDEM? Se só a ordem, ele é ponta-de-aresta legítima; se um fato, ele nasceu no lugar errado.

As camadas de escopo (a hierarquia de leitura, de `backlog.md:26-34`):
- **camada canônica** = `docs/onion/graph/*.kg.yaml` ∪ grafos marcados `# kg-backlog-guard: on` → a fila de
  decisão/execução do core; é o que `/onion:backlog` e (futuro) `/onion:realign` revisam.
- **pesquisa** = `docs/evolution/research/<tema>/` → nasce no grafo, mas é ruído epistêmico para o backlog a
  menos que marcada; pode se declarar `# kg-backlog-archive: on` para sair do backlog e ficar só no radar.
- **fixtures** = `${CLAUDE_PLUGIN_ROOT}/validation/fixtures/` → não é conhecimento, é o contrato de conformidade do motor.

**Espelhamento core ↔ adotante = SOBERANIA, não espelho.** O grafo do adotante vive em `docs/<área>/graph/`
(convenção posicional, `meta/kg.md §Store`), mas **não deriva nem espelha** o grafo do core: cada instância
implementa seu motor; o que viaja na federação é **schema + método**, nunca o grafo cru nem o código do radar
(`knowledge-graph-sdaal.md §Multi-runtime, §Store`). O único canal core↔adotante de conhecimento é o
**ingestor de doutrina** (trust-gated via `members.yaml`), que absorve *doutrina*, não *grafos*. **Moat:** o
grafo cru (dado do cliente) nunca sai do repo do adotante — mesma partição do gate client-safe.

**Verticais:** não há convenção de "um grafo por vertical". A vertical `onion-investigation` é a **dona do
método KG**, não uma consumidora com grafo próprio. Grafos são por-investigação/tema, nunca por-vertical.

## 4. Conexão com SDAAL, federação e o moat

- **O KG é uma instância SDAAL**: o `kg-radar.sh` é a autoridade única (o SSOT do motor); N implementações
  provam conformidade contra as fixtures (a porta JS `kgRadar.ts` = 6/6). Mesmo princípio SDAAL do resto do
  Onion, aplicado ao motor de grafo.
- **Co-evolução**: git merge não reconcilia verdades; a reconciliação é do radar + do ingestor trust-gated.
- **Moat/soberania**: schema + método viajam; grafo cru e código do motor, não. Grafo privado não publica.

## 5. Os dois avisos de honestidade que esta KB carrega (para quem constrói sobre o substrato)

1. **DRY do átomo:** o vocabulário de nó/aresta é SSOT única no radar/gramática — este doc é o lar do MACRO,
   não do átomo. Quem duplicar os enums reintroduz o drift (medido: `invariant` já divergiu de uma lista curta).
2. **A perna de LEITURA do KG é CONSELHO, não mecanismo** (medido, `docs/evolution/research/kg-read-leg-2026-08/
   SYNTHESIS.md` = NÃO CONSTRUIR; nenhum hook lê `.kg.yaml`). Consequência para maquinaria que "confia no
   substrato": o substrato é confiável na **ESCRITA** (o radar reprova grafo inválido), **não** na absorção
   automática — ninguém garante que o grafo foi *lido* antes de agir. Um `/onion:realign` deve declarar isso:
   ele revisa o que está escrito, não força que tenha sido lido.

## Referências
- Motor/átomo-SSOT: [`${CLAUDE_PLUGIN_ROOT}/validation/kg-radar.sh`](${CLAUDE_PLUGIN_ROOT}/validation/kg-radar.sh) ·
  `../../../.claude/rules/kg-grammar.md`
- Doutrina/rampa: [`knowledge-graph-sdaal.md`](knowledge-graph-sdaal.md) ·
  `kg-getting-started.md`
- Fronteira cross-grafo: `docs/onion/graph/fios-abertos.kg.yaml §FRONTEIRA` · overlay:
  `docs/onion/graph/constellation.kg.yaml` + `constellation-of-studies.md`
- Comandos: `/onion:kg` ·
  `/onion:backlog` ·
  `/onion:kg-freshness`
- Perna-de-leitura: `docs/evolution/research/kg-read-leg-2026-08/SYNTHESIS.md`
