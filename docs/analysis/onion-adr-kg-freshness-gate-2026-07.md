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
  - ../evolution/inbox/_processed/2026-07-16-ssot-como-runtime-para-adr.md
  - ../knowledge-base/concepts/knowledge-graph-sdaal.md
  - ../knowledge-base/agentic-patterns/ai-strategies/verify-read-path-first.md
---

# ADR — Frescor como cidadão de 1ª classe no KG SDAAL

| Campo | Valor |
|-------|-------|
| **Decisão** | Um KG-SSOT **apodrece silenciosamente** quando suas claims `plane: PROD` não são **re-verificadas** contra o estado vivo, e **drifta** do próprio validador quando o schema evolui sem versão. O core adota **duas guardas irmãs**, ambas da família "o radar recusa/avisa quando a SSOT driftou": **(A) frescor** — campo `verified_at:` (+ opcional `verified_against:`) obrigatório em nós `plane: PROD`, com o `kg-radar.sh` emitindo **STALE** quando ausente ou vencido; **(B) versão de schema** — campo `schema_version:` no bloco `meta:`, com o radar **recusando/sinalizando** divergência da versão que ele entende. |
| **Escopo** | Investigação (KG-SDAAL): o `.kg.yaml`, o `kg-radar.sh` e a KB `knowledge-graph-sdaal.md`. **Não** toca produto/engenharia/compliance, transporte, nem o motor de UI de adotante. |
| **Status** | ✅ **Aceito + F1/F1.1/F2 IMPLEMENTADAS** — 2026-07-16. **F1** (`--freshness`/`--schema` + selftests, Q1/Q2 resolvidas). **F1.1** (revisão pós-campo): frescor **estende a nós DEV** que rastreiam artefato móvel (via `verified_against:`) — **supersede** a decisão original "só PROD" (ver §A). **F2** (fiação `/meta:kg` v1.3.0 + doutrina a seção na KB + `schema_version` semeado). Resta absorver a doutrina **SSOT-as-runtime** (§SSOT como runtime) e as features derivadas (`kg state`, KG-first nos loops — backlog). |
| **Origem** | Propostas **#2 (⭐)** e **#1** do sinal [`2026-07-16-kg-sdaal-dogfood-ouro`](../evolution/inbox/_processed/2026-07-16-kg-sdaal-dogfood-ouro.md) (rhilo, "o ouro" — a técnica), **revisadas e ampliadas** pelo sinal-companheiro [`2026-07-16-ssot-como-runtime-para-adr`](../evolution/inbox/_processed/2026-07-16-ssot-como-runtime-para-adr.md) (rhilo, "a operação") + evidência convergente do omnibus do gustavo (`2026-07-16-treino-vertical-colaboracao-produtos`, Sinais 5/6/7 — KG por fronteira de confiança, grafo se autocorrigindo em campo). Dois adotantes, mesmo período, empurrando **SSOT como cidadão de 1ª classe**. |

---

## Status
✅ **Aceito + F1/F1.1/F2 implementadas** — 2026-07-16. Decide a **postura**: frescor e versão-de-schema viram
guardas do radar. **F1** (helper + selftests) + **F1.1** (frescor estende a DEV com artefato móvel, pós-campo,
supersedendo o "só PROD") + **F2** (fiação `/meta:kg` + doutrina a seção na KB + semeadura), tudo dogfoodado
(fixtures + grafo real do core + a extensão DEV que prova a não-inundação). `lint-selftest` **283/0**. **F3
subsumida** (o campo operou a SSOT e o relato substituiu o "rodar o radar lá"). A doutrina **SSOT-as-runtime**
está absorvida (§abaixo); o trabalho derivado (`kg state`, KG-first nos loops) fica no backlog. Q1/Q2 resolvidas.

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
- **Campo `verified_at:`** (data ISO, ex. `2026-07-16`). **Um nó é rastreado por frescor se `plane: PROD`
  (alvo implícito: o artefato vivo) OU se declara `verified_against:`** (opt-in — nomeia o artefato **móvel**
  que rastreia: `branch` | `commit` | `deploy` | `config` | `dump:...`). Nós rastreados sem `verified_at:` → ⚠.

  > **⟳ SUPERSEDES (F1.1, decisão-própria reconciliada em campo).** A F1 decidiu `verified_at`
  > **só em `plane: PROD`**, com o argumento *"DEV é branch/commit — o `TRACES_TO` já ancora onde; só PROD
  > precisa do quando"*. **O campo `REFUTOU` isso:** no sinal `ssot-como-runtime` §2, o nó **DEV**
  > `C_CONSOLIDATION_MAP` (estratégia de entrega) estava **stale** — apontava para branches sem os fixes,
  > refs `origin/fix/*` que **nem existiam** (locais, não pushadas). **Qualquer claim que referencie um
  > artefato móvel apodrece — não só PROD.** A decisão antiga **não se apaga** (append-mostly): fica
  > registrada aqui, `superseded`, e a regra vigente é a de cima (opt-in via `verified_against` estende a
  > DEV sem inundar claims epistêmicos comuns). *Isto é o próprio SDAAL dogfoodado sobre o core: uma decisão
  > de design virou claim, o campo emitiu `REFUTES`, a revisão emitiu `SUPERSEDES` — a história reconcilia.*
- **Gate no `kg-radar.sh` (duas checagens, determinísticas):**
  - **STALE-MISSING** (a mais barata e de maior alavanca): nó **rastreado por frescor** (`plane: PROD` ou com
    `verified_against:`) **sem** `verified_at:` → ⚠. Pega exatamente o modo-de-falha do campo (a SSOT do rhilo
    não tinha *nenhuma* disciplina de frescor — nem em PROD nem no nó DEV de estratégia).
  - **STALE-OLD** (horizonte): nó rastreado cujo `verified_at:` é **mais antigo** que a `meta.baseline` → ⚠
    (Q1 resolvida abaixo). Paralelo direto do `review_after` do diário — o padrão de TTL já é testado no core.
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

## SSOT como runtime, não artefato (a doutrina de operação)
O sinal-companheiro do rhilo (`ssot-como-runtime-para-adr`) trouxe a descoberta que **enquadra** o frescor:
não basta **construir** a SSOT — tem que **operar a partir dela**. O próprio autor montou o KG canônico e,
minutos depois, **o ignorou 3× na mesma sessão** — reconstruiu de git/memória (o jeito velho) enquanto o
grafo já tinha a resposta (`E_ABANDON_APPLY_PROOF [confirmed]`, `C_CONSOLIDATION_MAP`). *Sem uma forcing
function, o consumidor (humano OU IA) re-deriva à mão e ignora a fonte que ele mesmo montou.*

- **A SSOT é o programa que se EXECUTA, não o documento que se arquiva.** Metáfora do maestro: o `.kg.yaml`
  é o **bytecode**; o LLM é a **VM** que deve **executá-lo** — `read(KG) → verify(vivo) → act → write(KG)`
  (append-mostly) a cada passo. O valor só aparece quando o KG é o **substrato de execução**.
- **KG-first + drive-to-verify (o par canônico).** Para qualquer pergunta de estado/decisão: **consultar o
  grafo primeiro** e citar o id do nó; então **confirmar contra o vivo** (git/dump/código) **antes de agir**.
  Nenhum sozinho basta — o KG stale engana; o git sozinho esquece o que a SSOT já sabia. (Promove o #7
  "drive-to-verify" do 1º sinal de *bom* a **obrigatório**, e é o "como" do frescor: `verified_at` é o
  carimbo desse cruzamento.)
- **Frescor vale em TODAS as camadas** (não só PROD) — é o que a **F1.1** implementa (§A): qualquer claim
  com artefato móvel, DEV inclusive.

**Evidência convergente — três adotantes, mesmo período, mesmo método.** A SSOT-de-1ª-classe é **padrão
emergente**, não capricho de um adotante:
- **rhilo** (produção, WRR): SSOT-as-runtime + frescor + DEV-também — a linha-mestra deste ADR.
- **gustavo** (consultoria, omnibus Sinais 5/6/7): a SSOT vira 1ª classe por outro eixo — **confidencialidade**:
  *"um KG SDAAL por fronteira de confiança"* (engajamento confidencial × colaboração shareable, `D_KG_SEPARADO`),
  com o grafo **se autocorrigindo em campo** (deep-research `REFUTED` teses, `SUPERSEDED` no ledger). Ângulo
  ortogonal (partição × frescor); triado à parte.
- **onion-pessoal** (uma vida, N=1): F0 da vertical Trabalho reconciliou **declarado(DEV) × vivido(PROD)** numa
  vida — 2 `SUPERSEDES` + 1 `REFUTES` deixado de propósito → **`exit 1` honesto** (não grafo bonito e vazio). O
  método transfere ao domínio mais sensível (não-código/não-negócio) mantendo a régua: Aufhebung append-mostly,
  confronto DEV×PROD, radar determinístico. Sinal [`onion-pessoal-usando-dogfood-kg-sdaal`](../evolution/inbox/_processed/2026-07-16-onion-pessoal-usando-dogfood-kg-sdaal.md).

Três domínios radicalmente distintos (produção, consultoria, vida) e o **mesmo motor** — append-mostly,
soberano, reconciliável — segurou em todos. É a validação de campo mais forte que a linha KG SDAAL tem.

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
- **Q4 — `verified_against` estruturado?** ✅ **Parcialmente resolvida na F1.1:** `verified_against` deixou de
  ser anotação opcional e virou **o opt-in que estende frescor a DEV** (sua *presença* marca "este nó rastreia
  artefato móvel"). Continua **string livre** por ora (atenta ao footgun de keyword-substring — PR #373);
  sub-campos tipados (`branch:`/`commit:`/`deploy:`) só se um dogfood pedir cruzamento automático com o vivo.

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
- **F1.1 — frescor em todas as camadas (revisão pós-campo):** ✅ **FEITA (2026-07-16).** Frescor rastreia
  `plane: PROD` **OU** nó com `verified_against:` (opt-in DEV). Radar: `plane[id]!="PROD" && verifiedAgainst[id]==""`
  pula; senão exige `verified_at`. Fixture `dev-tracked-stale.kg.yaml` + selftest que **prova a extensão E a
  não-inundação** (DEV+`verified_against` dispara; DEV epistêmico puro não). `lint-selftest` **283/0**.
  Supersede a decisão "só PROD" da F1 (§A), reconciliação registrada — não apagada.
- **F3 — campo:** ✅ **SUBSUMIDA.** O dogfood de campo **aconteceu organicamente**: o adotante operou a SSOT,
  errou 3×, e o relato (`ssot-como-runtime`) é resultado mais rico que "rodar o radar lá". O loop fechou pela
  narrativa + a F1.1 que corrige o que ela expôs. Não há F3 separada a executar.

## Trabalho derivado (novo backlog deste ADR — sinal `ssot-como-runtime`)
- **`kg state` — projeção de estado-de-trabalho (proposta #4).** O radar dá atenção/integridade/reconciliação,
  mas **não** responde "o que está feito / pendente / o próximo". O adotante teve de escrever um `kg-state.py`.
  Feature nova: um `--state` (ou `kg-state.sh`) irmão do radar, projetando alavancas vivas×inertes,
  implementado×a-aplicar, questões abertas, top-atenção. **Merece desenho próprio** (ADR/fase).
- **Cabear KG-first nos loops (proposta #5).** `catch-up`/`warm-up`/`work` reconstroem de git/memória e **não
  abrem o KG** — foi o buraco que fez o adotante errar. Quando existir um `.kg.yaml`, esses comandos devem
  **consultá-lo primeiro** (é o SSOT de "onde estamos", acima do git). Fiação nova, backlog.

## Gatilho de materialização (gated)
F1/F1.1/F2 feitas. O `kg state` e o cabeamento KG-first são **trabalho derivado** (desenho próprio) — o
breadcrumb `[[2026-07-16-kg-sdaal-dogfood-gold-backlog]]` guarda a prioridade; este ADR é a **SSOT do
desenho** do frescor/schema. A doutrina **SSOT-as-runtime** (§acima) é a moldura para eles.
