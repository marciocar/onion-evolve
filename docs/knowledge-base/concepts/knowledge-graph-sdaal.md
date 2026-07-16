# Knowledge Graph SDAAL — fonte da verdade como grafo ponderado (CANDIDATA)

> **Status: CANDIDATA** — padrão recebido via co-evolução (sinal upstream
> `docs/evolution/inbox/_processed/2026-07-02-sinal-sdaal-knowledge-graph.md`), nascido e dogfoodado
> na instância **rhilo-metagamify** durante uma auditoria real de produção (WRR/Modo Equilíbrio,
> 01-02/jul/2026). Autoria do método: instância rhilo (T1 hub). Esta KB porta o **conceito
> generalizado**; a implementação de referência vive no rhilo (`scripts/kg/radar.js` +
> `docs/rhilo/graph/wrr-audit.kg.yaml`).
>
> **Gate (comando `/meta:kg`): ✅ CUMPRIDO em 2026-07-04** — o core dogfoodou o método na rodada
> de `/meta:evolve` ([`onion-evolution-2026-07.kg.yaml`](../../onion/graph/onion-evolution-2026-07.kg.yaml),
> 37 nós/33 arestas, 7 refutações como arestas REFUTES) e o comando **`/meta:kg`** nasceu dessa
> vivência, junto com o motor soberano `.claude/validation/kg-radar.sh`. A doutrina
> gated-until-trigger foi respeitada: o comando veio DEPOIS do dogfood, não antes.
>
> **Rampa de vertical**: este padrão é a espinha da vertical `onion-investigation` — desenho, rampa
> F0-F3 e capability draft no ADR
> [onion-adr-verticals-investigation-cartography-2026-07.md](../../analysis/onion-adr-verticals-investigation-cartography-2026-07.md).
> **F1 disparou em 2026-07-04** (1º dogfood na federação, sessão rhilo — ver nota de doutrina abaixo)
> e **F2 executou no mesmo dia** (dogfood do core via `/meta:evolve` → `/meta:kg` + `kg-radar.sh`).
> Resta F3 (plugin `onion-investigation`), gated por maturidade de uso.
>
> **Camada de DOMÍNIO promovida em 2026-07-10** — 2º dogfood do metagamify (sinal
> [2026-07-08-kg-dogfood-completo-promover](../../evolution/inbox/_processed/2026-07-08-kg-dogfood-completo-promover.md):
> o grafo de auditoria evoluiu para SSOT de domínio) elevou o padrão a **duas camadas**
> (`layer: audit|domain`), com radar-de-domínio e a materialização design/atom-map — ver seções abaixo.

## Nota de doutrina — git merge não reconcilia verdades (confirmada em campo)

> **Doutrina:** conflito **epistêmico** entre linhagens (o que cada uma acredita ser verdade) se
> resolve na **camada de conhecimento** (KG SDAAL: claims por plane, arestas REFUTES/SUPERSEDES,
> radar) — e **só então** na camada de código (PR dirigido pelo veredito). `git merge` reconcilia
> texto, não verdades.
>
> **Evidência de campo (1º dogfood na federação, 2026-07-04):** a instância rhilo reconciliou
> `develop` (pesquisa da dose) × `rhilo/main` (motor deployado) num `wrr-audit.kg.yaml` — 56 nós,
> 81 arestas, zero contradições estruturais. O radar produziu veredito **por-verdade** impossível
> de derivar de merge textual: uma verdade cruza DEV→PROD (hard `cap=0`, defesa-em-profundidade),
> uma segura na develop (dose-para-meta, aguarda validação on-policy) e — o achado mais valioso —
> uma flui **ao contrário** (PROD→DEV): dados vivos refutaram a urgência do framing original da
> pesquisa (métrica inflada ~82× por contagem-fantasma). Sinal completo:
> [`2026-07-04-kg-primeiro-dogfood-federacao.md`](../../evolution/inbox/_processed/2026-07-04-kg-primeiro-dogfood-federacao.md).

## O problema que o padrão resolve

Investigações longas degradam para **log cronológico**: cada achado é datado e as auto-correções
("X era verdade → refutado") ficam enterradas em prosa. Consequências observadas em campo:

1. **Verdade×verdade não se confronta** — contradições espalhadas que o log não sabe que tem.
2. **Confusão DEV↔PROD** — conclusões tiradas do código lido (branch de trabalho) em vez do artefato
   vivo (commit deployado + flags + env + dados).
3. **Whack-a-mole** — variáveis compartilhadas alimentam gates com semânticas distintas; consertar um
   quebra outro sem aviso.

## O modelo

Um arquivo `.kg.yaml` (espírito [SDAAL](specification-driven-ai-abstraction-layer.md): spec
estruturada executável por IA) com **nós tipados** e **arestas tipadas ponderadas**, em **duas
camadas** (campo `layer`, default `audit` — retrocompatível):

- **`layer: audit`** (epistêmica — o que a investigação *acredita*):
  - `node_type`: `entity` · `claim` · `decision` · `question` · `evidence` · `artifact`
  - `edge_type`: `SUPPORTS` · `REFUTES` · `SUPERSEDES` · `CAUSES` · `DEPENDS_ON` · `TRACES_TO`
- **`layer: domain`** (SSOT durável — o que o sistema *é*):
  - `node_type`: `entity` · `state` · `event` · `rule` · `invariant` · `policy`
  - `edge_type`: `HAS_STATE` · `TRANSITIONS` (com atributo `on:` = evento gatilho) · `EMITS` ·
    `CONSTRAINS` · `READS` · `WRITES`
- **`plane`**: `DEV` (código/branch/commit) ou `PROD` (artefato vivo: deploy + config + dados)
- **peso do nó**: `impact` (1–5) × `confidence` (0–1) × `status` (`open|confirmed|refuted|superseded|done`)
- **migalha unificada**: aresta `TRACES_TO` → `{file:line | task | commit | env | reason | snapshot}`

O grafo é **append-mostly**: auto-correções viram arestas `REFUTES` explícitas — a história não se
apaga, se **reconcilia** (mesmo parentesco do protocolo de re-teste do diário: `superseded: true`,
nunca deletar — `/meta:diary review`).

> **Escopo da camada `audit` — não é sobre código, é sobre investigação.** A gramática epistêmica
> (`claim`/`evidence`/`decision`/`question` + `SUPPORTS`/`REFUTES`/`SUPERSEDES`) serve **qualquer
> investigação com achados que se contradizem e se corrigem** — código e sistema (a origem: auditoria
> WRR de produção), mas também **conteúdo/documentação**: decks, currículo, contratos, specs.
> **Instância de campo** (gustavo-pulga/Tornak, `tornak.kg.yaml` Lote 10, verificada pelo `kg-radar.sh`
> soberano do core — 107 nós/172 arestas limpo): a mesma gramática auditou 2 decks de treinamento sem
> nenhuma adaptação, e o próprio mecanismo de auto-correção operou fora de código — `C_TARDE_NUM_15`
> (confidence 0.4) ficou `REFUTED` por `C_TARDE_NUM_21` (confidence 1.0, backed por correção humana):
> o erro permaneceu no grafo, refutado e rastreável, em vez de sobrescrito.

### Distinção epistêmico×domínio (por que duas camadas)

O grafo de **auditoria** é efêmero e append-mostly (a investigação de hoje); o grafo de **domínio**
é durável (a ontologia do sistema: entidades, estados, eventos, regras). O audit **`TRACES_TO`** o
domain — a investigação ancora suas verdades no modelo, e o modelo sobrevive à investigação. Foi
essa separação que **evitou o inchaço** no 2º dogfood do metagamify (2026-07-08: 111 nós/170
arestas, 4 fatias de domínio, o SLOT-limbo **emergiu do modelo** como bug estrutural — não como
achado de auditoria). Pragmatismo herdado do dogfood: **mesmo arquivo, campo `layer`** — separar em
`*.domain.kg.yaml`/`*.audit.kg.yaml` só se a escala pedir.

### Footguns ao autorar o `.kg.yaml` (armadilhas de campo)

Aprendido no dogfood intenso do adotante rhilo-metagamify (2026-07-15/16, reconciliação do SSOT
WRR/Modo Equilíbrio): a autoria do `.kg.yaml` tem armadilhas silenciosas que **corrompem o grafo
sem erro visível**. Evite:

- **`on:` vira booleano `True` (YAML 1.1).** A chave `on:` de `TRANSITIONS ... on: EVENTO` é
  interpretada como o booleano `true` pelo parser YAML 1.1 → **os gatilhos de transição somem** (no
  campo: 9 gatilhos perdidos numa migração, um estado-absorvente **falso** apareceu). **Cite o evento
  entre aspas** (`on: "EVENTO"`) ou trate a chave `True` ao ler; nunca deixe `on:` nu.
- **Colisão de keyword-substring com o radar.** O `kg-radar.sh` é awk puro (por design determinístico:
  não aluga LLM) e captura campos por substring de linha (`plane:`/`status:`/`impact:`), tomando a
  **última** ocorrência. Um campo livre — `label:`, `trace:`, `reason:` — cujo **texto** contenha
  `plane:`/`status:`/etc. **sobrescreve o campo real**. Regra: **emita os campos livres ANTES dos
  escalares** no bloco do nó (para o escalar real vencer), e evite as substrings de keyword dentro de
  texto livre. É footgun garantido — trate como convenção, não como acaso.
- **Vírgulas finais em flow-maps.** Trailing commas em mapas inline quebram o parse silenciosamente na
  migração — revise antes de rodar o radar.

> **A lição-mestra do mesmo dogfood** (frescor): um nó `plane: PROD` é uma **foto**; sem carimbo de
> *quando/contra o quê foi verificado*, ele envelhece e o leitor (humano **ou IA**) confia no stale —
> "uma bela SSOT que mente". A disciplina de frescor (`verified_at:` + gate STALE no radar) é feature
> em backlog derivada deste sinal; até existir, **re-execute as claims `PROD` contra o estado vivo**
> (cruzar KG + código `arquivo:linha` + dump fresco) antes de confiar nelas.

## As quatro saídas (o que uma ferramenta `radar` computa)

1. **RADAR** — perguntas/decisões abertas ranqueadas por **atenção = impacto × confiança ×
   centralidade** (PageRank ponderado). Responde *o que fazer agora*.
2. **RECONCILIAÇÃO** — todas as arestas `REFUTES`/`SUPERSEDES`: verdades confrontadas, explícitas.
3. **INTEGRIDADE** — o grafo se contradiz? Reprova: nó `refuted` ainda recebendo `SUPPORTS`; `decision`
   `done` fora do plane PROD; órfãos; migalhas pendentes; ciclos `DEPENDS_ON`.
4. **RADAR-DE-DOMÍNIO** — completude da camada `domain` (⚠ atenção, **não reprova** — um
   estado-absorvente pode ser terminal legítimo; o juízo é humano). As 5 checagens (promovidas do
   dogfood metagamify 2026-07-08 + ADR design):
   - **estado-absorvente**: `state` que recebe `TRANSITIONS` e não emite nenhuma (limbo?);
   - **EVENT-sem-efeito**: `event` que não origina aresta nem dispara `TRANSITIONS` via `on:`;
   - **STATE-sem-dona**: `state` que nenhuma `entity` possui via `HAS_STATE`;
   - **RULE-sem-trace**: `rule|invariant|policy` sem `TRACES_TO` (regra não ancorada em artefato);
   - **fonte-única**: nó de domínio com >1 `READS` saindo (1 átomo = 1 fonte — ver §design abaixo).

   Saída extra `--triples` (`from EDGE to [on evento]`) para consumo por LLM.

## Governança DEV↔PROD (a regra dura)

> **Comportamento em produção = artefato deployado + config viva + env + dados.**
> Uma `decision` só vira `done` quando **verificada no plane PROD** — "o código deveria" não fecha nó.

Evidência de campo no próprio core (mesmo dia, direção oposta): o incidente do **pin forjado**
(anúncio "você já tem o fix" raciocinou sobre o *carimbo* em vez do *artefato vendorizado*; guard
permanente: `.claude/validation/pin-integrity-check.sh`). A regra generaliza: **carimbo/doc/branch é
plane DEV; só o artefato vivo é plane PROD.**

## Anti-whack-a-mole (disciplina complementar)

- **SSOT-por-conceito**: uma variável = um significado; nomear distinto quando fluxos divergem.
- **Blast-radius**: modelar variável→consumidores (`DEPENDS_ON`/`CAUSES`) e listar consumidores
  **antes** de mexer.
- **Replay/golden-test**: snapshot→muda→replay+diff pega regressão em outro fluxo.
- **Invariantes como asserts testados**, não comentários.

## Design/atom-map — a 1ª instância da camada domain (ADR design-extends-kg)

A rastreabilidade de **átomos de UI** não ganha grafo próprio — **estende esta camada domain**
([ADR](../../analysis/onion-adr-design-extends-kg-2026-07.md), gate satisfeito pelo artefato real do
rhilo-app em [2026-07-09](../../evolution/inbox/_processed/2026-07-09-artefato-command-center-atom-map.md)):

- **átomo de informação** = nó `entity` com `layer: domain` (1 átomo = 1 fonte + 1 dono-de-exibição
  + 1 dono-de-escrita);
- átomo **`READS`** sua fonte (endpoint dono) — **uma só**: 2+ `READS` = violação de fonte-única,
  que o radar-de-domínio flagra;
- átomo **`TRACES_TO`** o componente dono da exibição; escrita = `WRITES`;
- **`SourceTag`** (tooltip/badge de linhagem no front) é a **aresta renderizada** — adaptador do
  adotante, nunca motor do core;
- o "cara-crachá" (invariante verificável por grep: cada endpoint-dono aparece como fonte em 1
  componente) é `verify-read-path-first` aplicado ao front — vira checagem de integridade do KG.

**Divergir vs reger** (a não-sobreposição do ADR): a vertical de design **diverge** (generativo,
gate WCAG decide); o KG **rege** (fonte-única + rastreabilidade, depois de decidir). Eixos
ortogonais — dois papéis, um substrato.

**Motor de projeção ≠ motor de UI de adotante.** O core **não** distribui componentes de front
(identidade + soberania: o `SourceTag` é sempre implementação local do adotante). O que o core tem é
**projeção read-only dos próprios artefatos** — `kg-console.sh` renderiza o `.kg.yaml` em HTML
self-contained (grafo interativo + veredito do `kg-radar.sh` embutido), mesmo padrão do
`federation-console.sh` (zero backend, zero CDN, determinístico). Ver ≠ distribuir.

## Mapeamento completo — o playbook (`/meta:kg map <área>`)

> **Situação (recognition-primed):** vai redesenhar/refatorar/assumir uma área e o conhecimento dela
> vive espalhado (telas, endpoints, regras implícitas). **Playbook:** mapear a área como SSOT de
> domínio ANTES de mexer — o contrato primeiro, o pixel/refactor depois. Nasceu de 2 dogfoods reais
> do rhilo e se repete a cada adotante que assume uma área (metagamify → GranaAi → …).

O PFR completo (F0 inventário → F1 contrato → F2 `.kg.yaml` → F3 radar → F4 adaptador) vive no
comando [`/meta:kg`](../../../.claude/commands/meta/kg.md) §Modo map. O essencial doutrinário:

- **F1 tem 3 variantes — todas por identidade, não analogia** (o mesmo motor, o mesmo radar):
  1. **UI → atom-map** (contrato de átomos): 1 átomo = 1 fonte + 1 dono-de-exibição + 1
     dono-de-escrita; `SourceTag` (endpoint+concept+formula) como rastreabilidade-componente;
     ledger de de-duplicação; **pergunta atômica por aba**. Exemplar:
     [artefato command-center](../../evolution/inbox/_processed/2026-07-09-artefato-command-center-atom-map.md).
  2. **Backend/API/funcionalidade → fatias de domínio**: entidades/estados/eventos/regras ancoradas
     no código; endpoint = `entity` fonte. Exemplar:
     [kg-dogfood-completo](../../evolution/inbox/_processed/2026-07-08-kg-dogfood-completo-promover.md)
     (4 fatias: ciclo do SLOT, integração PULL, máquina de SLA, dicionário ubíquo).
  3. **Jornadas/fluxos → máquina de estados**: passos = `state` do progresso do ator/processo,
     avanço = `TRANSITIONS(on evento)`, cada passo `TRACES_TO` tela/endpoint. O radar entrega valor
     imediato: **estado-absorvente = drop-off/limbo do funil**. Tipos novos (`actor`, `step`) só
     quando um dogfood provar a falta — gated-until-trigger, a doutrina deste próprio comando.
- **O doc-contrato e o grafo se referenciam** (atom-map = join, per ADR): doc = contrato humano que
  as fases de implementação obedecem; `.kg.yaml` = camada máquina que o radar verifica.
- **Invariante grep-verificável no repo do adotante**: cada endpoint-dono aparece como fonte de
  exibição em 1 componente ("cara-crachá" — `verify-read-path-first` aplicado ao front).

## Generalização para o core — EXECUTADA (2026-07-10) + Fase 2

O gate abriu (2026-07-04) e a camada domain foi promovida (2026-07-10, sinal
[kg-dogfood-completo](../../evolution/inbox/_processed/2026-07-08-kg-dogfood-completo-promover.md)):
o motor soberano `.claude/validation/kg-radar.sh` computa as 4 saídas + `--triples` do YAML puro,
zero serviço externo, com fixtures no selftest de guardas. A implementação do rhilo reusa o stack ML
dele (embeddings MiniLM, pgvector, grafo `ElementLink`) — **não portar dependências**: o que viaja
na federação é **schema + método**, nunca o código do motor.

**Fase 2 semântica (método promovido, implementação soberana):** embeddings + cosseno para flagar
redundância entre nós (o cluster do limbo no dogfood do metagamify foi detectado assim). Cada
instância implementa com seu stack; o core permanece determinístico até a escala pedir.

## Relações

- **≠ `/meta:graph`**: aquele é a lente sócio-técnica da *spec-as-code* (estrutura do framework);
  este é o grafo do *conhecimento de uma investigação* (claims/decisões/evidência). Complementares.
- **Parentesco**: protocolo de re-teste do diário (`/meta:diary review`); doutrina de dogfood
  ([onion-dogfooding-doctrine](onion-dogfooding-doctrine.md)) — "invoque o artefato e observe" é a
  regra PROD-plane em outra roupa.
- **Origem e crédito**: instância rhilo-metagamify, auditoria WRR (evidência: radar priorizou cura de
  raiz sobre paliativos; reconciliou 6 auto-correções como `REFUTES`; integridade pegou 3 órfãos).
