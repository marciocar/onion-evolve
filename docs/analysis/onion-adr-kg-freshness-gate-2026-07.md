---
title: "ADR — Frescor como cidadão de 1ª classe no KG SDAAL: verified_at + gate STALE, schema_version + gate de drift"
date: 2026-07-16
type: adr
status: accepted
decision-scope: investigation (KG-SDAAL) — radar + schema do .kg.yaml
supersedes: none
related:
  - onion-adr-design-extends-kg-2026-07.md
  - onion-adr-verticals-investigation-cartography-2026-07.md
  - ../evolution/inbox/_processed/2026-07-16-kg-sdaal-dogfood-ouro.md
  - ../knowledge-base/concepts/knowledge-graph-sdaal.md
  - ../knowledge-base/agentic-patterns/ai-strategies/verify-read-path-first.md
---

# ADR — Frescor como cidadão de 1ª classe no KG SDAAL

| Campo | Valor |
|-------|-------|
| **Decisão** | Um KG-SSOT **apodrece silenciosamente** quando suas claims `plane: PROD` não são **re-verificadas** contra o estado vivo, e **drifta** do próprio validador quando o schema evolui sem versão. O core adota **duas guardas irmãs**, ambas da família "o radar recusa/avisa quando a SSOT driftou": **(A) frescor** — campo `verified_at:` (+ opcional `verified_against:`) obrigatório em nós `plane: PROD`, com o `kg-radar.sh` emitindo **STALE** quando ausente ou vencido; **(B) versão de schema** — campo `schema_version:` no bloco `meta:`, com o radar **recusando/sinalizando** divergência da versão que ele entende. |
| **Escopo** | Investigação (KG-SDAAL): o `.kg.yaml`, o `kg-radar.sh` e a KB `knowledge-graph-sdaal.md`. **Não** toca produto/engenharia/compliance, transporte, nem o motor de UI de adotante. |
| **Status** | ✅ **Aceito + F1/F2 IMPLEMENTADAS** — 2026-07-16. **F1** (helper + selftests): `kg-radar.sh` ganhou `--freshness`/`--schema` (STALE-MISSING, STALE-OLD, schema-drift) + 5 selftests que reagem; Q1/Q2 resolvidas (baseline in-file, sem "agora"). **F2** (fiação + KB): `/meta:kg` expõe os modos (v1.3.0), doutrina promovida a seção na `knowledge-graph-sdaal.md`, `schema_version` semeado nos 5 grafos reais do core. Resta **F3** (campo: contra o grafo real do rhilo). |
| **Origem** | Propostas **#2 (⭐ a maior alavanca)** e **#1** do sinal de campo [`2026-07-16-kg-sdaal-dogfood-ouro`](../evolution/inbox/_processed/2026-07-16-kg-sdaal-dogfood-ouro.md) (adotante rhilo-metagamify) — o uso mais intenso do KG SDAAL até hoje (165 nós/288 arestas: reconciliou o SSOT do WRR/Modo Equilíbrio, decidiu arquitetura pelo grafo, gerou código, validou A/B ao vivo). Costuradas num ADR só porque são o **mesmo problema**: a SSOT diverge do real (no tempo) ou do validador (no formato). |

---

## Status
✅ **Aceito + F1 implementada** — 2026-07-16. Decide a **postura**: frescor e versão-de-schema viram guardas
do radar, não convenções torcidas para dar certo. **F1 (helper + selftests) executada** reusando o gate
determinístico existente (`kg-radar.sh` + `lint-selftest.sh`): 5 selftests que reagem (fresh/stale-missing/
stale-old/schema-divergente/retrocompat), dogfoodados contra as fixtures **e** contra um grafo real do core
(`onion-identity-2026-07.kg.yaml` → exit 0, só avisos — degradê confirmado). Restam **F2** (fiação `/meta:kg`
+ promoção da doutrina na KB) e **F3** (campo: rodar contra o grafo real do rhilo). Q1/Q2 resolvidas abaixo.

## Contexto
O sinal do rhilo-metagamify nomeou a **lição-mestra** com evidência de campo:

> **Um KG-SSOT que não é RE-EXECUTADO contra o estado vivo apodrece silenciosamente.**

Duas falhas concretas, ambas verificadas contra o código do core na triagem:

1. **Frescor (a dor #2).** Nós `plane: PROD` são **fotos**. Sem carimbo de *quando / contra o quê* foram
   verificados, envelhecem e o consumidor — humano **ou IA** — confia no stale. No campo:
   - `doseMaxByLevel` no grafo = `2/4/8/8/8`; real vivo = `2/4/12/15/20`.
   - Tabela legada (`WRRJourneyConfig`) tratada como fonte viva (o motor lê outra config).
   - "Bloqueador #1" marcado aberto — **já corrigido** no código há tempos.
   - `fairActiveCases` "aguardando push" — **já deployado e gravando** em prod.
   O agente **propagou o erro ao usuário** por confiar numa leitura só. O que salvou: **cruzar 4 fontes**
   (KG + memória + código `arquivo:linha` + dump fresco). Hoje o `kg-radar.sh` **não tem nenhuma disciplina
   de frescor** (verificado: `grep verified_at` = 0 ocorrências).

2. **Drift de schema (a dor #1).** A SSOT viva estava no schema de uma ferramenta antiga (`scripts/kg/`,
   `type:`/flow-maps) que quebrou (MODULE_NOT_FOUND) e dava **287 violações** no radar canônico
   (`kg-radar.sh`, `node_type:`/bloco). **A SSOT e o validador driftaram e ninguém percebeu** — não havia
   `schema_version:` para o radar cruzar (verificado: `grep schema_version` = 0 ocorrências). *"Uma fonte da
   verdade que nenhuma ferramenta valida não é fonte da verdade."*

Ambas são a mesma classe: **a SSOT deixou de bater com uma referência** — o estado vivo (tempo) ou o
validador (formato) — e a divergência ficou **invisível** porque nada a checava.

## Decisão (o desenho)

### A. Frescor — `verified_at:` + gate STALE
- **Campo `verified_at:`** (data ISO, ex. `2026-07-16`) **obrigatório em todo nó `plane: PROD`**. Opcional
  `verified_against:` (ex. `dump:wrr-2026-07-16` | `baseline` | `code@commit`) para nomear a fonte cruzada.
  Nós `plane: DEV` **não** exigem (DEV é código/branch/commit — o `TRACES_TO` já ancora *onde*; PROD é o
  artefato vivo — precisa do *quando*).
- **Gate no `kg-radar.sh` (duas checagens, determinísticas):**
  - **STALE-MISSING** (a mais barata e de maior alavanca): nó `plane: PROD` **sem** `verified_at:` → ⚠. Pega
    exatamente o modo-de-falha do campo (a SSOT do rhilo não tinha *nenhuma* disciplina de frescor).
  - **STALE-OLD** (horizonte): nó `plane: PROD` cujo `verified_at:` é **mais antigo** que um horizonte de
    frescor → ⚠. O horizonte vem de um dos knobs abaixo (questão aberta Q1). Paralelo direto do
    `review_after` do diário — o padrão de TTL já existe e já é testado no core (mail-hook/diary-index).
- **Semântica:** frescor é **aviso** (⚠ STALE), não erro-de-integridade (✗). Um nó stale não corrompe o
  grafo — ele **mente**; o veredito certo é "re-verifique", não "recuse o arquivo". (Contrasta com o gate de
  schema, que é recusa — ver B.)

### B. Versão de schema — `schema_version:` + gate de drift
- **Campo `schema_version:`** (ex. `"2"`) no bloco **`meta:`** do `.kg.yaml`. O `kg-radar.sh` carrega uma
  constante `RADAR_SCHEMA` da versão que entende.
- **Gate:** divergência (`schema_version` do arquivo ≠ `RADAR_SCHEMA`, ou **ausente** num grafo que usa a
  gramática atual) → **recusa** com mensagem nomeada ("schema vX esperado, encontrado vY — rode `kg migrate`
  ou atualize"). Ausência total num grafo já-canônico = aviso de retrocompat (não quebrar grafos legados
  válidos de uma vez — degradê, como o `layer` default `audit`).
- **Por que recusa (≠ frescor):** schema errado significa que o radar **não sabe ler** o arquivo — os outros
  vereditos ficam **não-confiáveis**. Falha barulhenta é o comportamento seguro; teria pego o fork
  `scripts/kg`↔`kg-radar.sh` **no dia 1**.

### Por que as duas juntas
São a **mesma máquina** com duas referências: *"o radar recusa/avisa quando a SSOT driftou"* — drift **no
tempo** (nó PROD vs estado vivo → frescor) e drift **no formato** (arquivo vs validador → schema). Um ADR,
um dogfood, duas guardas irmãs no mesmo `kg-radar.sh`. Separá-las duplicaria contexto sem ganho.

## Consequências
- **Fazer (quando destravar, faseado):** os campos na gramática do `.kg.yaml`; as 3 checagens no
  `kg-radar.sh` (STALE-MISSING, STALE-OLD, schema-drift); selftests em `lint-selftest.sh` (cada guarda com
  caso que **reage** — passa quando fresco/versionado, avisa/recusa quando stale/divergente); doutrina de
  frescor promovida na KB `knowledge-graph-sdaal.md` (hoje só há o ponteiro deixado pelo PR #373).
- **Não fazer:** parser YAML novo (fora de escopo — é a proposta #3, hardening separado); `kg migrate`
  (proposta #4, backlog — o gate de schema **aponta** para ela mas não a implementa); tornar frescor um
  erro-duro (é aviso — não corromper o fluxo de quem ainda não carimbou).
- **Alinha** com `verify-read-path-first` (verificar o caminho de leitura antes de confiar), com a doutrina
  de dogfood ("declarado ≠ verificado" — um nó PROD sem `verified_at` é *declarado*, nunca *verificado*), e
  com `onion-adr-design-extends-kg` (mesma família de guardas de integridade do radar).

## Questões abertas (resolver no dogfood faseado)
- **Q1 — o horizonte do STALE-OLD.** ✅ **RESOLVIDA na F1:** baseline por-arquivo (`meta: baseline: <data>`
  → nós PROD com `verified_at` anterior = STALE-OLD). Zero-knob por padrão (STALE-MISSING não precisa de
  baseline); TTL fixo dispensado. Simples, reusável, sem estado externo.
- **Q2 — determinismo vs "agora".** ✅ **RESOLVIDA na F1:** ao comparar `verified_at` (nó) contra `baseline`
  (meta) — **duas datas do próprio arquivo** — o gate **não usa "agora"** e permanece **100% determinístico/
  reproduzível**. As 3 checagens (STALE-MISSING, STALE-OLD, schema-drift) rodam sem `date`. Melhor que o
  precedente mail-hook (que compara vs agora) — aqui a referência é in-file.
- **Q3 — retrocompat.** Grafos legados sem `verified_at`/`schema_version` não podem quebrar de uma vez.
  Degradê: ausência → aviso (não erro) numa 1ª versão; endurecer depois de os grafos de campo migrarem.
- **Q4 — `verified_against` estruturado?** String livre (barato, footgun de keyword-substring — ver #3) ou
  sub-campos? **Hipótese:** string por ora, atenta à colisão de substring documentada nos footguns (PR #373).

## Plano faseado (dogfood: barato → caro)
- **F1 — helper + selftests (testável isolado):** ✅ **FEITA (2026-07-16).** `kg-radar.sh` ganhou
  `--freshness` e `--schema` (+ ambos no `--all`), o parse de `verified_at:`/`schema_version:`/`baseline:`,
  e a constante `RADAR_SCHEMA`. 5 fixtures em `fixtures/kg-freshness/` + `fixtures/kg-schema/` e 5 selftests
  que reagem. Gate: `lint-artifacts` 0/0, `lint-selftest` **282/0**. Q1/Q2 resolvidas na prática.
- **F2 — fiação + KB:** ✅ **FEITA (2026-07-16).** `/meta:kg` expõe `--freshness`/`--schema` (schema
  exemplo com `verified_at:`/`schema_version:`/`baseline:`, comandos do radar, vereditos FRESCOR/SCHEMA,
  nota do gate; v1.3.0). Doutrina promovida na `knowledge-graph-sdaal.md` de ponteiro a **seção**
  ("Frescor e versão de schema") + saídas do radar (4→6). `schema_version: "1"` semeado nos 5 grafos
  reais do core (as fixtures `kg-domain/*` ficam sem, de propósito — o selftest de retrocompat depende).
- **F3 — campo:** rodar o radar com as guardas contra um grafo real de adotante (o próprio rhilo, que tem os
  nós PROD stale documentados) → confirmar que **STALE dispara** onde a dor apareceu. Registrar no diário;
  fechar o loop com o sinal.

## Gatilho de materialização (gated)
Ligar quando houver **janela para o dogfood faseado** — não é doutrina-pura como o design-extends-kg (aqui há
código concreto a escrever). O breadcrumb `[[2026-07-16-kg-sdaal-dogfood-gold-backlog]]` guarda a prioridade;
este ADR é a **SSOT do desenho**. Ao executar F1, atualizar o Status deste ADR (implementado) e riscar #2/#1
do backlog.
