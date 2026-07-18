# Síntese — Sync de doutrina adotante→core: o INGESTOR que falta, com a federação-KG como substrato

> **Proveniência:** exploração orquestrada de 3 streams (fan-out read-only) na sessão 2026-07-18, para o plano
> "estado da arte de como granaai e onion-pessoal sincronizam doutrina ao core". Este arquivo é o **`write(KG)`**
> daquela orquestração (dogfood do passo 7 de `onion-orchestration` / `Passo 4.5` de `/meta:orchestrate`) — a
> síntese não podia ficar só no contexto/efêmero. Grafo audit co-locado: `./doctrine-sync-ingestor.kg.yaml`
> (radar exit 0) — a regra de lint "toda pesquisa nova nasce em KG" (doutrina 2026-07-17) já o exige.

## O achado central (1 frase)

A cadeia **doutrina adotante→core está partida no meio**: a metade **produtora + transporte** está construída e
dogfoodada; a metade **ingestora no core** está inteiramente **desenhada mas GATED** — *o adotante entrega a
doutrina na porta; ninguém do lado de dentro a absorve estruturalmente.*

## Stream 1 — O terreno do sync de doutrina (mecanismos)

| Elo da cadeia doutrina adotante→core | Existe? | Onde |
|---|---|---|
| Registrar doutrina/decisão localmente | ✅ | `/meta:diary` tipo `decision`/`innovation`, classe `collective` |
| Empacotar p/ transporte | ✅ | `diary export-sharable` → `outbox/diary/` |
| Transportar até o inbox do core (sem commit) | ✅ | `/meta:co-relay --to core`; a2a-live (F2.2 completo) |
| Política de aceitação/veto na entrada | ✅ parcial | bloco `trust:` no `members.yaml`, `trust-topology-check.sh`, `federation-check` fail-safe |
| **Core INGERIR a doutrina com política (agregador)** | ❌ **buraco central** | nomeado em `research/federation-2026/S4:88`; sem comando |
| Sintetizar doutrina de N adotantes em KB coletiva | ❌ GATED (F4) | `rfc-0003`; `/meta:synthesize-collective` inexistente |
| Personalidade emergente por instância | ❌ GATED (F2) | `rfc-0003`; `/meta:personality-sync` inexistente (seeds manuais no `members.yaml`) |
| Reconciliar doutrina conflitante (adotante supera core sem apagar) | ❌ GATED (RFC-0005 F3) | `SUPERSEDES` bitemporal no KG |

**Leitura:** RFC-0004 dá o **cano** (mesh transporta destilado), RFC-0005 dá o **reconciliador** (`SUPERSEDES`,
gated), RFC-0003 dá o **formato** (diário/personality) e o **consumidor final** (F4, gated). Os três apontam para
o mesmo objeto mas **nenhum liga produtor→ingestor→doutrina-do-core**.

## Stream 2 — Primitivas para a federação-como-KG

- **Motor pronto:** `kg-radar.sh` + gramática de 2 camadas (audit/domain) + `/meta:kg` + fixtures de domínio
  validadas. Mas **nenhum `.kg.yaml layer:domain` de produção existe** — só fixtures.
- **`members.yaml` já é proto-grafo, mas no grafo errado:** só o `graph.sh` (lente sócio-técnica, triplas TSV) o
  ingere; o motor KG (`.kg.yaml`) nunca. O `reconcile-inputs.sh` (novo) é o **molde exato** do extrator que faltaria.
- **Gap central (honesto):** as relações de federação (`adopts`, `trust-corrects`, `lineage`) são
  **relacionais-sociais** e os 6 edge-types domain (`HAS_STATE`/`TRANSITIONS`/`EMITS`/`CONSTRAINS`/`READS`/`WRITES`)
  **não têm equivalente nativo**. A doutrina do `/meta:kg` manda **não inventar tipo novo até dogfood provar a
  falta** → a federação-KG é **dogfood-first**.

## Stream 3 — As histórias vivas (o campo já constrói as peças)

- **Sinal pendente** (`inbox/2026-07-18-deep-research-no-auto-kg-persist`, da worktree `discuss/onion-pessoal-app`):
  `deep-research` (skill do harness) despeja em `/tmp` efêmero → o `write(KG)` depende de lembrar. **É a semente E o
  desbloqueio do onion-pessoal.**
- **granaai (KG de produto regulado):** 4 sinais de doutrina já entregues ao core — *integridade≠rastreabilidade*
  (`TRACES_TO`=0), *fail-open do radar* (validar forma não carimbo — já consertado 07-17), *validador-local delega
  ao radar soberano* ("primo"), *formalizar `/meta:kg map <projeto>`* — mais o `domain-layer template` + `A+`
  (cobertura `TRACES_TO` 10%→63%).
- **onion-pessoal (KG de vida N=1):** adota o **MÉTODO**, não vendoriza `.claude/`; a raiz É o KG
  (`marcio-*-f0.kg.yaml`) com planes DEV×PROD, `SUPERSEDES`/Aufhebung, e **`exit 1` honesto** (contradição viva).
- **Tema comum:** os dois pressionam **a mesma doutrina** — fechar `read(KG)→verify→act→write(KG)` de ponta a
  ponta: (1) persistência automática do `write(KG)`; (2) validar **forma, não carimbo**; (3) breadcrumbs
  `arquivo:linha`; (4) camada `domain` + frescor honesto.

## O que isto decide (o plano de 4 fases)

1. **Fase 0 — desbloquear:** triar a semente (hook já consertado `c501ff7`, relay já feito `af5351d`; `write(KG)`
   direcionado à Fase 1). **Feito.**
2. **Fase 1 — fechar o `write(KG)`:** afordância determinística na orquestração (passo 7 da skill + `Passo 4.5` do
   comando) — persistir síntese + materializar `.kg.yaml`, mecanismo não conselho. **Este PR** (e este próprio
   arquivo é o dogfood).
3. **Fase 2 — o INGESTOR:** 1º dogfood de "core absorve doutrina com política" — absorver a doutrina já entregue do
   granaai via absorção KG-backed (`SUPPORTS`/`SUPERSEDES`, trust-gated). É o elo que falta (`S4:88`), sem construir
   o F4-cron gated.
4. **Fase 3 — a FOTO:** 1ª `federation.kg.yaml` de produção (domain) do `members.yaml`+CHANGELOG+outbox (extrator =
   molde do `reconcile-inputs.sh`); radar = "core não surpreendido". Dogfood revela a ontologia.

## Confiança / gaps
- **Alta:** o diagnóstico do buraco (ingestor gated) — 3 fontes convergem com `file:line`.
- **Média:** federação-como-KG é **substrato plausível** do ingestor, mas a ontologia de federação é gap aberto
  (Fase 3 dogfooda, não decide no abstrato).
- **`declarado≠verificado`:** absorção só vale com radar exit 0 / `arquivo:linha`; nada auto-aplicado nos adotantes (I3).
