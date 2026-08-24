# Knowledge Graph SDAAL — fonte da verdade como grafo ponderado (CANDIDATA)

> **Status: CANDIDATA** — padrão recebido via co-evolução (sinal upstream
> `docs/evolution/inbox/_processed/2026-07-02-sinal-sdaal-knowledge-graph.md`), nascido e dogfoodado
> numa instância adotante durante uma auditoria real de produção (01-02/jul/2026).
> Autoria do método: uma instância adotante (T1 hub). Esta KB porta o **conceito
> generalizado**; a implementação de referência vive em um adotante (`scripts/kg/radar.js` +
> `docs/<adopter>/graph/audit.kg.yaml`).
>
> **Gate (comando `/meta:kg`): ✅ CUMPRIDO em 2026-07-04** — o core dogfoodou o método na rodada
> de `/meta:evolve` (`onion-evolution-2026-07.kg.yaml` — grafo interno do core; a auditoria `/meta:evolve`
> de 2026-07-04 modelada como KG, 37 nós/33 arestas, 7 refutações como arestas REFUTES) e o comando **`/meta:kg`** nasceu dessa
> vivência, junto com o motor soberano `${CLAUDE_PLUGIN_ROOT}/validation/kg-radar.sh`. A doutrina
> gated-until-trigger foi respeitada: o comando veio DEPOIS do dogfood, não antes.
>
> **Rampa de vertical**: este padrão é a espinha da vertical `onion-investigation` — desenho, rampa
> F0-F3 e capability draft no ADR `onion-adr-verticals-investigation-cartography-2026-07.md` (ADR
> interno do core, provisório F0) — **em síntese:** desenha duas verticais novas via SDAAL —
> investigação (KG + pesquisa multi-fonte juntas, acopladas fracamente pelo tipo de nó `evidence`) e
> cartografia de contextos de domínio — sob a doutrina gated-until-trigger (registra desenho e gatilhos,
> não autoriza construir) e soberania (cada instância implementa seu motor, não se porta o radar do adotante).
> **F1 disparou em 2026-07-04** (1º dogfood na federação, sessão de um adotante — ver nota de doutrina abaixo)
> e **F2 executou no mesmo dia** (dogfood do core via `/meta:evolve` → `/meta:kg` + `kg-radar.sh`).
> Resta F3 (plugin `onion-investigation`), gated por maturidade de uso.
>
> **Camada de DOMÍNIO promovida em 2026-07-10** — 2º dogfood de campo (sinal
> `2026-07-08-kg-dogfood-completo-promover.md`, sinal upstream interno do core — o grafo de auditoria,
> 111 nós/170 arestas e 4 fatias de domínio, evoluiu para SSOT de domínio e pediu des-gate do `/meta:kg`
> + promoção do **schema + método, não do código**) elevou o padrão a **duas camadas**
> (`layer: audit|domain`), com radar-de-domínio e a materialização design/atom-map — ver seções abaixo.

## Nota de doutrina — git merge não reconcilia verdades (confirmada em campo)

> **Doutrina:** conflito **epistêmico** entre linhagens (o que cada uma acredita ser verdade) se
> resolve na **camada de conhecimento** (KG SDAAL: claims por plane, arestas REFUTES/SUPERSEDES,
> radar) — e **só então** na camada de código (PR dirigido pelo veredito). `git merge` reconcilia
> texto, não verdades.
>
> **Evidência de campo (1º dogfood na federação, 2026-07-04):** uma instância adotante reconciliou
> `develop` (pesquisa de produto) × `<adopter>/main` (motor deployado) num `prod-audit.kg.yaml` — 56 nós,
> 81 arestas, zero contradições estruturais. O radar produziu veredito **por-verdade** impossível
> de derivar de merge textual: uma verdade cruza DEV→PROD (hard `cap=0`, defesa-em-profundidade),
> uma segura na develop (pesquisa-para-meta, aguarda validação on-policy) e — o achado mais valioso —
> uma flui **ao contrário** (PROD→DEV): dados vivos refutaram a urgência do framing original da
> pesquisa (métrica inflada ~82× por contagem-fantasma). Sinal completo:
> `2026-07-04-kg-primeiro-dogfood-federacao.md` (sinal upstream interno do core) — **em síntese:** o 1º
> dogfood do KG na federação, onde um adotante reconciliou `develop`×`main` num `.kg.yaml` (56 nós/81
> arestas, zero contradições) e o radar deu o veredito **por-verdade** impossível de derivar de merge textual.

## Nota de doutrina — integridade técnica ≠ completude de rastreabilidade (absorvida do campo)

> **Doutrina (S1):** um `.kg.yaml` pode selar **100% verde na integridade** (0 ciclos, 0 órfãos,
> evidence 100%) e mesmo assim ter os breadcrumbs SDAAL **órfãos** — `TRACES_TO` 0/N (nenhuma
> `decision` ligada aos nós que ela justifica). **Integridade estrutural** (o grafo não se contradiz)
> **não é rastreabilidade** (cada nó aponta para a evidência/decisão verificável que o sustenta). É a
> família *declarado≠verificado* estendida à rastreabilidade: "o grafo é consistente" ≠ "o grafo é
> auditável". A **auto-extração** de `TRACES_TO`/`CONTROLLED_BY` (parsing de ADR/compliance) é
> **soberania do adotante** (o motor de cada instância), não do core — o core carrega a **doutrina** +,
> quando materializado, um radar de completude como **aviso** (não HARD).
>
> **Doutrina (S3a) — soberania do validador:** um validador **local** de `.kg.yaml` deve **DELEGAR** ao
> `kg-radar.sh` soberano, **não reimplementar** a gramática. Um parser duplicado em gramática divergente
> é **a superfície onde o falso-verde volta** — o fix do radar soberano não o alcança. O validador local
> mantém só o **valor local** (ex.: checar que os paths de `evidence:`/`trace:` existem em disco); a
> forma/gramática é do radar. (Irmã da guarda anti-fail-open `kg-radar.sh:120-139`.)
>
> **Evidência de campo (um adotante regulado, dogfood 2026-07-17):** um `.kg.yaml` de 107 nós/154 arestas selou verde
> com `TRACES_TO` 0/10 (integridade perfeita, rastreabilidade órfã); e o fix de fail-open do radar
> soberano não alcançou o validador local `kg-validate-v2.py` (gramática MAPA divergente) — o falso-verde
> voltou pela porta do parser duplicado.
>
> **Remediação de referência (um adotante regulado, confirmada 2026-07-18):** a destilação de S1+S3a no KB foi
> verificada FIEL em campo — e a doutrina não só foi absorvida, foi **ACIONADA**: guiado por ela o
> um adotante regulado reescreveu `kg-validate-v2.py` para **delegar** ao radar soberano (S3a) e regenerou o KG em
> gramática LIST canônica, elevando os breadcrumbs de decisão de **10%→63%** (`TRACES_TO` nó→ADR, "A+");
> a rastreabilidade *comportamental* (`layer: domain`, máquina de estados ancorada) fica como **template
> gated-por-refactor**, não preventiva. Ou seja: **S1 dirigiu a remediação** — o loop adotante→core→adotante
> fechou fiel, e há um exemplo de campo de referência.
>
> **Absorvida via o ingestor de doutrina** (trust-gated: um adotante regulado tem `can_correct_to: [onion-evolve]`):
> `onion-adr-doctrine-ingestor-2026-07.md` (ADR interno do core) — **em síntese:** o elo ingestor que
> faltava na cadeia adotante→core: o core absorve doutrina de campo por **absorção curada, trust-gated
> (policy-as-data em `members.yaml`), KG-backed (vira `.kg.yaml` com radar exit 0) e human-gated** — o
> precursor CURADO da síntese coletiva da RFC-0003 F4, nunca o sintetizador automático; aterrissa por
> tipo (doutrina→KB com crédito ao adotante; feature/fix→backlog; já-feito→`superseded`) e absorve o
> princípio/método, jamais o código. Grafo da absorção:
> `docs/onion/graph/<adopter>-doctrine-absorption-2026-07.kg.yaml` (radar exit 0).

## O problema que o padrão resolve

Investigações longas degradam para **log cronológico**: cada achado é datado e as auto-correções
("X era verdade → refutado") ficam enterradas em prosa. Consequências observadas em campo:

1. **Verdade×verdade não se confronta** — contradições espalhadas que o log não sabe que tem.
2. **Confusão DEV↔PROD** — conclusões tiradas do código lido (branch de trabalho) em vez do artefato
   vivo (commit deployado + flags + env + dados).
3. **Whack-a-mole** — variáveis compartilhadas alimentam gates com semânticas distintas; consertar um
   quebra outro sem aviso.

## O modelo

Um arquivo `.kg.yaml` (espírito SDAAL: spec
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
- **peso do nó**: `impact` (1–5) × `confidence` (0–1) × `status`
  (`open|confirmed|drifted|unverifiable|refuted|superseded|done`)
  - `drifted` (fator **1.3** — o único que SOBE) e `unverifiable` (1.0) entraram em 2026-08-06.
    **`status` é marcador de ESTADO, não de processo.** `drifted` significa *"este nó diverge do
    vivo AGORA e alguém precisa reconciliar"* — não *"um run devolveu veredito DRIFTED"*. Se o
    label já foi atualizado com a verdade medida, o nó **não** é `drifted`: ele é `confirmed`, e o
    veredito do run vira a **aresta** `SUPERSEDES` + o nó da posição superada. Confundir os dois é
    erro medido (Elenxo 2026-08-07): produz nó `drifted` que não diverge de nada, ocupa o topo do
    radar e — porque a guarda de reconciliação só conta superseder `confirmed` — deixa a aresta
    recém-criada **invisível**, um fail-open.
- **migalha unificada**: aresta `TRACES_TO` → `{file:line | task | commit | env | reason | snapshot}`

O grafo é **append-mostly**: auto-correções viram arestas `REFUTES` explícitas — a história não se
apaga, se **reconcilia** (mesmo parentesco do protocolo de re-teste do diário: `superseded: true`,
nunca deletar — `/meta:diary review`).

> **Normativo: `id` em INGLÊS, `label` em pt-BR.** Segue a skill `language-standards`/
> [`code-standards`](../../meta-specs/code-standards.md) — `id` é identificador (código: inglês),
> `label` é prosa lida por humano (pt-BR). **Custo real medido em campo** (sinal onion-pessoal-app,
> 2026-07-19): quando os `id` derivaram para português, o **contrato entre artefatos quebrou** — o
> `atom-map.md` nomeava `E_REPLY`/`E_PHOTO` e o `.kg.yaml` correspondente nomeava
> `E_RESPOSTA`/`E_FOTO`, dois artefatos do **mesmo contrato** discordando do nome do **mesmo átomo**
> (exatamente o que o par doc-grafo existe para evitar — ver §Design/atom-map abaixo). Seja honesto
> sobre o limite: detectar idioma em `id` é **frágil** — isto é **convenção de autoria**, não gate
> mecânico do radar.

> **Escopo da camada `audit` — não é sobre código, é sobre investigação.** A gramática epistêmica
> (`claim`/`evidence`/`decision`/`question` + `SUPPORTS`/`REFUTES`/`SUPERSEDES`) serve **qualquer
> investigação com achados que se contradizem e se corrigem** — código e sistema (a origem: auditoria
> motor de produção), mas também **conteúdo/documentação**: decks, currículo, contratos, specs, e
> **pesquisa** (streams de deep-research cujos achados se refutam/superam — o veredito por-fonte, a
> materialidade e as ressalvas `declarado≠verificado` são `status`/`confidence`/`impact`/`REFUTES`). Pesquisa
> **nasce em KG, não morre em prosa** (doutrina 2026-07-17): 1ª instância `research/whatsapp-api-2026-07/`.
> **Instância de campo** (um adotante, `<adopter>.kg.yaml` Lote 10, verificada pelo `kg-radar.sh`
> soberano do core — 107 nós/172 arestas limpo): a mesma gramática auditou 2 decks de treinamento sem
> nenhuma adaptação, e o próprio mecanismo de auto-correção operou fora de código — `C_TARDE_NUM_15`
> (confidence 0.4) ficou `REFUTED` por `C_TARDE_NUM_21` (confidence 1.0, backed por correção humana):
> o erro permaneceu no grafo, refutado e rastreável, em vez de sobrescrito.

### Distinção epistêmico×domínio (por que duas camadas)

O grafo de **auditoria** é efêmero e append-mostly (a investigação de hoje); o grafo de **domínio**
é durável (a ontologia do sistema: entidades, estados, eventos, regras). O audit **`TRACES_TO`** o
domain — a investigação ancora suas verdades no modelo, e o modelo sobrevive à investigação. Foi
essa separação que **evitou o inchaço** no 2º dogfood de campo (2026-07-08: 111 nós/170
arestas, 4 fatias de domínio, o SLOT-limbo **emergiu do modelo** como bug estrutural — não como
achado de auditoria). Pragmatismo herdado do dogfood: **mesmo arquivo, campo `layer`** — separar em
`*.domain.kg.yaml`/`*.audit.kg.yaml` só se a escala pedir.

### Footguns ao autorar o `.kg.yaml` (armadilhas de campo)

Aprendido no dogfood intenso de um adotante (2026-07-15/16, reconciliação do SSOT
auditoria de produção): a autoria do `.kg.yaml` tem armadilhas silenciosas que **corrompem o grafo
sem erro visível**. Evite:

- **`on:` vira booleano `True` (YAML 1.1).** A chave `on:` de `TRANSITIONS ... on: EVENTO` é
  interpretada como o booleano `true` pelo parser YAML 1.1 → **os gatilhos de transição somem** (no
  campo: 9 gatilhos perdidos numa migração, um estado-absorvente **falso** apareceu). **Cite o evento
  entre aspas** (`on: "EVENTO"`) ou trate a chave `True` ao ler; nunca deixe `on:` nu.
- **Colisão de keyword-substring com o radar — CORRIGIDA em 2026-07-19 (não é mais footgun).** O
  `kg-radar.sh` é awk puro (por design determinístico: não aluga LLM) e **até 2026-07-19** capturava
  campos por substring de linha, tomando a **última** ocorrência: um campo livre (`label:`, `trace:`,
  `reason:`) cujo texto contivesse `plane:`/`status:`/etc. **sobrescrevia o campo real**. O workaround
  de então — *"emita os campos livres antes dos escalares"* — **está obsoleto**: os campos passaram a
  casar em **posição de campo** (`^[[:space:]]*<campo>:`), em `nodes`, `edges` e `meta`. **Escreva
  labels livremente; a ordem dos campos não importa mais.** ⚠️ A armadilha permanece **inerente a
  qualquer porta line-based** noutro runtime — por isso virou item obrigatório do contrato de
  conformidade (ver §Multi-runtime).
- **Vírgulas finais em flow-maps.** Trailing commas em mapas inline quebram o parse silenciosamente na
  migração — revise antes de rodar o radar.

> **A lição-mestra do mesmo dogfood** (frescor): um nó `plane: PROD` é uma **foto**; sem carimbo de
> *quando/contra o quê foi verificado*, ele envelhece e o leitor (humano **ou IA**) confia no stale —
> "uma bela SSOT que mente". Essa disciplina agora é **guarda do radar** (`verified_at:` + gate STALE,
> `schema_version:` + gate de drift) — ver §[Frescor e versão de schema](#frescor-e-versão-de-schema--o-radar-recusaavisa-quando-a-ssot-driftou).

## As saídas do radar (o que a ferramenta `radar` computa)

1. **RADAR** — perguntas/decisões abertas ranqueadas por **atenção = impacto × confiança ×
   centralidade** (PageRank ponderado). Responde *o que fazer agora*.
2. **RECONCILIAÇÃO** — todas as arestas `REFUTES`/`SUPERSEDES`: verdades confrontadas, explícitas.
3. **INTEGRIDADE** — o grafo se contradiz? Reprova: nó `refuted` ainda recebendo `SUPPORTS`; `decision`
   `done` fora do plane PROD; órfãos; migalhas pendentes; ciclos `DEPENDS_ON`.
4. **RADAR-DE-DOMÍNIO** — completude da camada `domain` (⚠ atenção, **não reprova** — um
   estado-absorvente pode ser terminal legítimo; o juízo é humano). As 5 checagens (promovidas do
   dogfood de campo 2026-07-08 + ADR design):
   - **estado-absorvente**: `state` que recebe `TRANSITIONS` e não emite nenhuma (limbo?);
   - **EVENT-sem-efeito**: `event` que não origina aresta nem dispara `TRANSITIONS` via `on:`;
   - **STATE-sem-dona**: `state` que nenhuma `entity` possui via `HAS_STATE`;
   - **RULE-sem-trace**: `rule|invariant|policy` sem `TRACES_TO` (regra não ancorada em artefato);
   - **fonte-única**: nó de domínio com >1 `READS` saindo (1 átomo = 1 fonte — ver §design abaixo).
5. **FRESCOR** (`--freshness`, ⚠ atenção, **não reprova**) — a SSOT foi re-verificada contra o vivo?
   **STALE-MISSING** (nó `plane:PROD` sem `verified_at:`) · **STALE-OLD** (`verified_at` anterior à
   `meta.baseline`) · **UNANCHORED** (`node_type: claim` com `verified_at:` sem `verified_against:` — carimbo sem alvo declarado). Ver §[Frescor e versão de schema](#frescor-e-versão-de-schema--o-radar-recusaavisa-quando-a-ssot-driftou).
6. **SCHEMA** (`--schema`, ✗ **reprova**) — `meta.schema_version` bate com a versão que o radar entende?
   Divergência = recusa (o radar não sabe ler o arquivo); ausência = ⚠ retrocompat.

Saída extra `--triples` (`from EDGE to [on evento]`) para consumo por LLM.

## Governança DEV↔PROD (a regra dura)

> **Comportamento em produção = artefato deployado + config viva + env + dados.**
> Uma `decision` só vira `done` quando **verificada no plane PROD** — "o código deveria" não fecha nó.

Evidência de campo no próprio core (mesmo dia, direção oposta): o incidente do **pin forjado**
(anúncio "você já tem o fix" raciocinou sobre o *carimbo* em vez do *artefato vendorizado*; guard
permanente: `${CLAUDE_PLUGIN_ROOT}/validation/pin-integrity-check.sh`). A regra generaliza: **carimbo/doc/branch é
plane DEV; só o artefato vivo é plane PROD.**

## Frescor e versão de schema — o radar recusa/avisa quando a SSOT driftou

Um KG-SSOT que não é **re-executado** contra o estado vivo **apodrece silenciosamente** — vira "uma
bela SSOT que mente", e um consumidor confiante (IA inclusive) *propaga* a mentira. Lição-mestra do
dogfood mais intenso do padrão até hoje (um adotante, 2026-07-15/16: `maxByLevel`
no grafo `2/4/8/8/8` × real vivo `2/4/12/15/20`; bloqueador "aberto" já corrigido; feature "aguardando
push" já deployada). O valor do KG **não** é ser escrito uma vez — é ser **re-verificável**. Duas
guardas (ADR `onion-adr-kg-freshness-gate-2026-07.md`, interno do core — **em síntese:** um KG-SSOT
apodrece quando claims `plane: PROD` não são re-verificadas contra o vivo e drifta do validador quando o
schema evolui sem versão; o core adota **duas guardas irmãs** — frescor (`verified_at`/`verified_against`
+ gate STALE) e versão de schema (`schema_version` + recusa por divergência) — e promoveu a doutrina
SSOT-as-runtime à KB), a mesma máquina com duas referências — *o radar recusa/avisa quando a SSOT driftou*:

**A. Frescor (drift no tempo — `--freshness`, ⚠ aviso).** Um nó que rastreia um artefato **móvel** é uma
**foto**; sem carimbo de *quando* foi verificado, envelhece.
- **`verified_at:`** (data ISO) — *quando* a claim foi cruzada com o vivo. **Um nó é rastreado por frescor se
  `plane: PROD`** (alvo implícito: o artefato vivo) **OU se declara `verified_against:`** (opt-in — nomeia o
  artefato móvel: `branch` | `commit` | `deploy` | `config` | `dump:...`). Isso estende o frescor a **nós DEV**
  que apontam para branch/commit (também apodrecem — F1.1, pós-campo), **sem inundar** claims epistêmicos
  comuns (um `question`/`claim` DEV sem `verified_against` não é cobrado).
- **STALE-MISSING**: nó rastreado sem `verified_at:` → ⚠ (o modo-de-falha exato do campo — a SSOT de um adotante
  não tinha *nenhuma* disciplina de frescor, nem em PROD nem no nó DEV de estratégia `C_CONSOLIDATION_MAP`).
  **STALE-OLD**: `verified_at` anterior a **`meta.baseline:`** (uma data no `meta:`) → ⚠, a verdade envelheceu.
- **MISPLANED** (todos os tipos): `plane: PROD` com `verified_against: branch|commit` → ⚠. `plane: PROD` afirma
  "cruzei com o **artefato vivo**"; `branch`/`commit` declara "olhei a **fonte**". É contradição **interna ao
  próprio nó** — detectável sem rede, sem contexto, sem heurística. Crédito: sinal de campo do adotante um adotante
  (2026-07-27), que **mediu 21 nós** do próprio repo afirmando sobre produção com evidência de leitura de código,
  **com o radar verde**. Escapavam pelo filtro por tipo do UNANCHORED (quase todos eram `evidence`) — reduzir
  ruído tinha cegado o gate para outra classe, e por isso o MISPLANED **não** filtra por tipo. **Teto declarado
  pelo próprio autor do sinal:** audita a procedência *declarada*, não se a declaração é verdadeira. `pin` não é
  cobrado por ser ambíguo (ler o stamp do checkout vivo é PROD legítimo).
- **UNANCHORED** (só em `node_type: claim`): tem `verified_at:` mas **não diz `verified_against:`** → ⚠. Carimbo **sem alvo declarado**
  não distingue verificado de declarado. Modo-de-falha de campo (2026-07-25, adotante): nós `plane: PROD` com
  `verified_at` *porque um `curl` respondera* — só que o `curl` mediu o **core** e a claim era sobre o
  **adotante**. O carimbo estava no artefato errado e **nada no arquivo denunciava**. O radar não julga a
  semântica do alvo (não pode); ele **exige que o alvo seja escrito** — e é escrevendo-o que o desalinhamento
  fica legível a quem lê. Em PROD, `verified_against:` deixa de ser opt-in na prática: passa a ser o que
  separa "cruzei com o vivo" de "afirmei".

  **Escopo: só quem AFIRMA.** Medido nos 22 grafos do core (2026-07-26), sem filtro o veredito produzia
  **275 avisos — 170 deles em tipos que já ancoram por outro campo**: `evidence` **é** a âncora (101 das
  114 já traziam `trace:`), `decision` já é cobrada pelo bloco de PROVENIÊNCIA (mesma obrigação, outro
  nome), `entity` de domínio ancora por `trace:` + `READS`/`WRITES`, `artifact` **nomeia** o alvo (alvo do
  alvo é tautologia) e `question` não afirma. 275 avisos treinam o leitor a ignorar — o mesmo motivo pelo
  qual nós `superseded`/`refuted` já eram pulados. Os 170 não somem: viram **uma linha `ℹ` contada**, para
  o filtro ser auditável em vez de mágico. Lição atrás da lição: o veredito foi shipado **sem teste** e
  com alcance largo demais; a correção veio junto com a fixture e o caso `(MUT)` que faltavam.
- **Aviso, não erro** — um nó stale **mente**, não corrompe; o veredito certo é "re-verifique", não
  "recuse o arquivo". Determinístico: compara **duas datas do próprio arquivo** (`verified_at` × `baseline`),
  **sem "agora"** — reproduzível.

**B. Versão de schema (drift no formato — `--schema`, ✗ recusa).** Uma SSOT que nenhuma ferramenta
valida não é fonte da verdade (no campo: a SSOT viva estava no schema de uma ferramenta morta e dava
287 violações no radar canônico — driftaram e ninguém percebeu).
- **`schema_version:`** no bloco `meta:`. O radar carrega a versão que entende (`RADAR_SCHEMA`).
- Divergência → **recusa** (exit 1): schema errado = os outros vereditos ficam não-confiáveis; falha
  barulhenta é o seguro. Ausência → ⚠ retrocompat (degradê: não quebra grafo legado válido de uma vez).

> **Até o frescor estar carimbado, cruze fontes.** Um nó PROD sem `verified_at` é *declarado*, nunca
> *verificado* (doutrina `declarado ≠ verificado`). Re-execute a claim PROD contra o vivo — **KG +
> código `arquivo:linha` + dump fresco** — antes de confiar. O `verified_at` é o carimbo desse cruzamento.

## SSOT-as-runtime — o KG é o primeiro ato (a ESCRITA é mecanismo; a LEITURA ainda é conselho)

> ⚠️ **CORREÇÃO DE HONESTIDADE — 2026-08-16 (ratificada pelo maestro).** Esta seção se chamava
> *"mecanismo, não conselho"*. A medição derrubou a segunda metade do título, e o registro fica aqui
> porque apagá-lo transformaria a vitrine em propaganda.
>
> **O que É mecanismo (medido):** a ESCRITA. O `kg-radar.sh` reprova contradição estrutural, o schema
> é guarda, o frescor tem baseline no lint, e 63/63 PRs carregam resíduo com sha256 do diff.
>
> **O que NÃO é mecanismo (medido):** a LEITURA. `lint-artifacts.sh:832` diz, literal, que *"o radar
> sai exit 0 nesses casos porque valida o grafo contra SI MESMO, nunca contra o veredito que o run
> produziu"*. **Nenhum dos hooks lê `.kg.yaml`** — quem manda ler são arquivos `.md` de comando, isto
> é, instrução obedecida pelo modelo: exatamente a categoria que esta KB chama de conselho. A própria
> doc da Anthropic ratifica a limitação: *"Claude treats them as context, not enforced configuration.
> To block an action, use a PreToolUse hook."*
>
> **A evidência é interna e é dura:** `docs/evolution/research/kg-read-leg-2026-08/SYNTHESIS.md`
> (2026-08-02, PR #510) replayou 9 casos reais — **7 falharam por NÃO-CONSULTA**, zero por "consultei e
> não achei" — e mediu três curas candidatas cobrindo **1/9, 1/9 e 0/9**, com veredito **NÃO CONSTRUIR**.
> O que de fato disparou a consulta na realidade foi **um humano perguntando: gate social, não
> instrumento**. Em três casos o agente ignorou 3×, em minutos, um grafo que ele mesmo acabara de autorar.
>
> **Por que a doutrina FICA, mesmo assim:** ela continua certa como norte — um KG consultado *quando
> lembra* não é SSOT. O que sai é a **afirmação de capacidade entregue**. Anunciar mecanismo onde há
> conselho é `declarado ≠ verificado` aplicado a nós mesmos — e seria a terceira vez desta classe
> (`KG-first` e `drive-to-verify` já foram anunciados a adotantes antes de terem casa no core).
>
> **GATILHO de reabertura** (declarado no próprio SYNTHESIS, e NÃO é changelog): fiar o disparo à mão,
> fresco e descartável, **2–3× em sessão real, registrando se o veredito injetado MUDOU a resposta**.
> A superfície nova de hooks (2026-08: ~30 eventos, handlers `prompt`/`agent`, com `InstructionsLoaded`,
> `PermissionDenied` e `FileChanged` disparando no dano e não no relógio) tornou a cura **construível** —
> não a tornou **justificada**. Construir porque ficou fácil é acoplar por conveniência, que é a
> refutação da postura de acoplamento no ato de aplicá-la.

> **Origem da decisão:** ADR `onion-adr-kg-freshness-gate-2026-07.md` (interno do core)
> §*SSOT como runtime, não artefato* — que é a **SSOT do desenho** (frescor/schema, evidência, ciclo,
> gatilhos). Esta seção é a **doutrina durável** que o ADR moldou; ela **cita**, não reescreve. Para *por
> que* se decidiu, e para a evidência completa dos três adotantes, leia o ADR.

Um KG só é **fonte da verdade** se for **carregado e verificado antes de raciocinar**. Um grafo que o
consumidor consulta *quando lembra* não é SSOT — é documentação. A diferença não é de grau, é de
natureza: o `.kg.yaml` entra no ciclo **antes** da conversa, do git e da memória, porque essas três
reconstroem o estado **por inferência** e o grafo o **declara**.

**A formulação do maestro** (ADR §SSOT como runtime): *o `.kg.yaml` é o **bytecode**; o LLM é a **VM**
que deve **executá-lo***. A SSOT é o programa que se **executa**, não o documento que se arquiva — o
valor só aparece quando o KG é o **substrato de execução**. (A metáfora é **didática**, não argumento
técnico — ver a ressalva do maestro em `onion-repositioning-sdaal-session-2026-06-17.md` (sessão de
estratégia interna do core, handoff entre instâncias):
*"o engenheiro sênior vai perguntar 'cadê os testes?'"*.)

**O ciclo obrigatório — `read(KG) → verify(vivo) → act → write(KG)`:**

1. **read(KG)** — localizar (`ls docs/onion/graph/*.kg.yaml docs/*/graph/*.kg.yaml *.kg.yaml`) e rodar
   `bash ${CLAUDE_PLUGIN_ROOT}/validation/kg-radar.sh <arquivo>` **como primeiro ato**. Citar **ids de nó**, nunca
   re-derivar da prosa: o id é a migalha que torna o raciocínio auditável.
2. **verify(vivo)** — *drive-to-verify*: claim `plane: PROD` de alto impacto se cruza contra o artefato
   vivo **antes** de virar premissa (§[Governança DEV↔PROD](#governança-devprod-a-regra-dura)). Nó
   stale **mente** — o `--freshness` avisa, o `verified_at:` é o carimbo do cruzamento.
3. **act** — só então planejar/agir, com o grafo como piso.
4. **write(KG)** — o que a ação descobriu volta como nó/aresta (`REFUTES`/`SUPERSEDES` quando corrige),
   append-mostly. Sem esta perna, o ciclo é leitura, não runtime: o grafo apodrece na próxima volta.

**KG-first + drive-to-verify são o par canônico** (ADR §SSOT como runtime): nenhum sozinho basta — o KG
stale engana; o git sozinho esquece o que a SSOT já sabia.

### Relatório é PROJEÇÃO do grafo, não fonte paralela (a metade que faltava — achado de campo, um adotante regulado, 2026-07-20)

O ciclo `read→verify→act→write` acima estava **fechado na leitura e aberto na escrita**. Toda a doutrina
desta seção — hierarquia de forcing-function, comandos cabeados, `allowed-tools` liberando o radar —
existe para garantir que ninguém *raciocine* sem antes consultar o grafo. Mas nada, até este achado,
impedia que um comando **produzisse conhecimento estruturado e o deixasse fora do grafo**. O laço estava
fechado em "não deixe o KG mentir" e aberto em "não deixe conhecimento viver fora do KG".

**A evidência auto-incriminadora** (sinal de campo de um adotante regulado,
`2026-07-20-gate-proveniencia-invertido.md`, sinal upstream interno do core — o laço do KG-SSOT fechado
na leitura e aberto na escrita: três mecanismos protegem o grafo de *estar errado*, nenhum impede
conhecimento de *nascer fora dele*):
uma rodada de auditoria orquestrada — **70 agentes, 0 erros, 50 achados confirmados + 10 refutados**,
tudo em JSON estruturado — e **nada disso foi ingerido no `.kg.yaml`**. A raiz não estava na execução
(que rodou limpa); estava no **plano**: ele reservava uma fase para "construir o grafo" e a fase seguinte
para "avaliar", com a saída da avaliação declarada em markdown solto. O grafo virou **predecessor** da
avaliação em vez de ser o **destino** dela — exatamente o inverso da direção que o `write(KG)` do ciclo
acima exige.

**Autocrítica, sem esconder:** o core já tinha o diagnóstico e o próprio slogan certos. A seção
[Por que mecanismo, e não "lembre-se de consultar"](#por-que-mecanismo-e-não-lembre-se-de-consultar),
neste mesmo documento, já dizia — antes deste achado — que "síntese que não persistiu é síntese
perdida" e que "advice-que-depende-de-lembrar falhou empiricamente". O core diagnosticou corretamente e
escreveu a frase certa: **"mecanismo, não conselho"** — e mesmo assim deixou a perna da escrita como
**conselho**, sem uma trava equivalente à do `read`. Um adotante regulado construiu o mecanismo que faltava; o core
só tinha o texto.

**O princípio, para valer daqui em diante:** se um comando produz achados estruturados, o destino é o
`.kg.yaml`; o markdown é **vista** (projeção), nunca fonte paralela. Enquanto o relatório for redigido
**em paralelo** ao grafo — e não **a partir dele** ou **direto nele** — ele pode divergir do que o grafo
declara, recriando, dentro do próprio instrumento anti-divergência, a divergência que ele existe para
combater.

O mecanismo que fecha este furo (gate de proveniência que trata artefato novo sem nó como violação HARD,
com passivo existente tolerado em baseline decrescente) é tratado à parte, para não duplicar a
especificação aqui — ele vive em
[`${CLAUDE_PLUGIN_ROOT}/validation/kg-provenance-coverage.sh`](${CLAUDE_PLUGIN_ROOT}/validation/kg-provenance-coverage.sh)
(REGRA 29 do lint), e a **doutrina da catraca** que o torna adotável está em
`onion-guardrails.md`.

> ⚠️ **"Coberto" ≠ "verificado" — a cobertura é por CITAÇÃO, não por conteúdo.** O gate responde
> *"existe nó que cite este documento?"*, e um nó que o cite **sem sustentá-lo** satisfaz o gate. Isso é
> **deliberado**: cobertura tem de ser decidível por script (determinismo), e julgar se a citação sustenta
> a afirmação é semântico. O lado semântico já tem dono — é o **radar** (`STALE-TRACE`, decisão-sem-proveniência)
> e a **verificação adversarial**. Dito em voz alta porque "coberto" lido como "conferido" seria a mesma
> falsa-garantia que a doutrina `declarado≠verificado` existe para matar.

### Investigação NASCE no grafo — o irmão INTERNO da proveniência (marcador `kg:`)

A REGRA 29 acima olha da **borda do grafo para fora**: *"este relatório existe no grafo?"* (algum nó o
cita). Falta a pergunta virada para **dentro** da própria migalha/doc: *"o grafo que esta investigação
declara ter nascido dela é **real e são**?"*. É o mesmo eixo espacial da 29 — proveniência — mas medido
por **marcador autodeclarado** em vez de por **citação**. Por isso: **irmão INTERNO** da 29.

**Origem de campo** (memória do maestro 2026-07-23, *"radar sub-usado"*): o passo `write(KG)` (passo 7)
da skill `onion-orchestration` era **ADVICE** — e advice-que-depende-de-lembrar **falhou de novo**, o
mesmo modo de falha que esta seção inteira documenta. Uma sessão correu **8 passadas do contrato de
inferência (Elenxo)** e a saída **evaporou em prosa**; só virou grafo **depois, à mão**
(`inference-contract-audit-2026-07.kg.yaml`, grafo interno do core — a escada de refutações onde cada
passada pôs um "está fechado" que o verify REFUTOU um nível mais fundo, até a Regra de Admissão fechar o
regresso), quando o radar então reconstruiu a escada inteira + a tese-núcleo por peso. O **radar é runtime**, não
lint ocasional — e estava **sub-usado**. A correção é **em camadas, honesta**: (1) uma **FASE `write(KG)`
canônica** no template da classe FINDINGS da orquestração (default-path, caminho de menor resistência —
materializa o `.kg.yaml` + roda o radar **antes** de retornar); (2) este **gate de integridade do
marcador**; (3) a **pergunta guiada** no `/meta:diary create` (*"nasceu no grafo? path do `.kg.yaml`,
ou prosa-só + porquê"*); (4) o **limite honesto** declarado abaixo.

**O marcador `kg:`** é um campo de frontmatter — em migalha epistêmica (`type` decision/error/learning/
reflection) ou doc de achado — que aponta para o `.kg.yaml` onde a investigação nasceu. Quem **declara**
`kg:` tem de apontar para um grafo que **existe**, **é** `.kg.yaml`, e **passa no `kg-radar --integrity`
E `--schema`** (exit 0). Pendurado, não-grafo, ou radar-reprova ⇒ **HARD**. O gate vive em
[`${CLAUDE_PLUGIN_ROOT}/validation/kg-born-marker.sh`](${CLAUDE_PLUGIN_ROOT}/validation/kg-born-marker.sh) (REGRA 43 do lint),
e o **marcador `kg:` é o pressuposto — o gate o prova** (com mutation test da severidade), na regra de
admissão da casa (`inference-mitigation.md`).

> ⚠️ **Por que NÃO tem catraca/baseline — e por que isso é o CORRETO, não frouxidão.** A REGRA 29 precisa
> de catraca porque cobra **ausência** (doc sem nó = violação): sem baseline reprovaria dezenas de legados
> no 1º dia e seria desligada — o erro da catraca. Aqui é o **oposto**: a **ausência** do marcador `kg:`
> **não é violação**. As ~72 migalhas existentes não declaram `kg:` — e o gate **nasce silencioso**, sem
> retro-reprovar ninguém. Só o `kg:` **declarado-mas-inválido** reprova. `missing != violation` ⇒ não há
> passivo a tolerar ⇒ não há baseline. Pôr catraca aqui **repetiria** o erro que a 29 existe para não
> repetir. (Ver a doutrina da catraca em `onion-guardrails.md` — referenciada, não
> reescrita: a 29 é por citação **com** catraca; a 43 é por marcador **sem** catraca, e a diferença é
> exatamente `missing != violation`.)

> 🎯 **O LIMITE HONESTO — mesmo rigor do Nível B da REGRA 42.** Investigação **não-declarada** é
> **estruturalmente indetectável**: a investigação pode não deixar rastro nenhum no repo. Este gate **não
> força o nascimento** — garante a **integridade do que se declara**. O nascimento de fato fica por conta
> de **disciplina + default-path** (a FASE `write(KG)` canônica da orquestração, camada 1), **não** deste
> HARD. Não fingir que o gate força o nascimento seria a mesma desonestidade que dizer "coberto = conferido":
> ele só prova que o `.kg.yaml` **declarado** é real e são.


### Os nomes: gênero × espécie (para parar de multiplicar sinônimos)

O campo usa vários rótulos para **dois** conceitos em **dois** níveis. A régua:

| | **Gênero** — vale p/ qualquer SSOT | **Espécie** — o SSOT é um `.kg.yaml` |
|---|---|---|
| **só a perna `read`** | **SSOT-first** | **KG-first** |
| **o ciclo inteiro** | **SSOT-as-runtime** | *(usar o gênero)* |

- **`SSOT-first ⊂ SSOT-as-runtime`** — "first" é a **1ª perna**; "as-runtime" é `read→verify→act→write`.
  Dizer "SSOT-first" quando se quer o ciclo inteiro é o erro comum.
- **`KG-first` é o que está cabeado nos loops** (o SSOT do core é um `.kg.yaml`); **SSOT-first** é o que
  se leva ao adotante cujo SSOT é outro artefato.
- ⚠️ **"KG-runtime" — não usar.** Sinônimo redundante de SSOT-as-runtime; nasceu do salad, não de uma
  distinção real.
- **"Dogfood KG SDAAL" / "Dogfood KG-SSOT SDAAL" não são conceitos** — são *rodadas de dogfood* deste
  padrão (ver [dogfooding-doctrine §🚦 item 3](onion-dogfooding-doctrine.md), os dois sentidos de re-dogfood).

### Por que mecanismo, e não "lembre-se de consultar"

Porque **conselho-que-depende-de-lembrar já falhou empiricamente — inclusive com quem escreveu o
conselho**. Dois episódios distintos, do mesmo adotante (um adotante), na mesma quinzena:

| Episódio | Sinal | O que aconteceu |
|---|---|---|
| **origem da doutrina** | `2026-07-16-ssot-como-runtime-para-adr.md` (sinal upstream interno do core — a operação: *construir o SSOT ≠ operar a partir dele*; o par KG-first→drive-to-verify como ciclo canônico) | montou o KG canônico e **o ignorou 3× na mesma sessão** — reconstruiu de git/memória enquanto o grafo já tinha a resposta (`E_ABANDON_APPLY_PROOF`, `C_CONSOLIDATION_MAP`) |
| **escalada a mecanismo** | `mandar-a-doutrina-kg-first` | **depois** de escrever a doutrina, reincidiu **≥4×**: planejou um redesenho do motor sem consultar o grafo. Ao consultar, o KG **corrigiu 4 erros** que ele cometeria — janela `7d`→**`14d` medido** (`C_WINDOW_SWEEP`); morte-da-chamada só-TTL→**sinal + derivação** (`C_ABANDON_PUSHED`/`Q_RELEASE_SIGNAL`); conflito com `I_NO_AGE_RELEASE`; e **metade do redesenho já existia como nó** (`R_PARAMETA`, `R_ADR018`) |

> **A reincidência É o dado.** Não é falha de disciplina do consumidor — é falha de *design* do loop.
> Um estado que depende de um evento que nunca chega é exatamente o bug do SLOT-limbo que o mesmo
> grafo diagnosticou. Documentar o KG-first e deixar o consumidor lembrar **reproduz o bug**.

Não é anedota de um adotante: a pesquisa de migalhas do core já **mediu** o gargalo — recall passivo
quase perfeito **despenca para 40-60% no uso ativo em decisão**
(`onion-work-models-research-2026-07.md`, pesquisa interna do core — deep-research de 104 agentes/24
achados confirmados sobre coordenação assíncrona e autonomia agendada; o gargalo medido é a **absorção**,
não a escrita da migalha). *Escrever a migalha é fácil; a absorção na decisão seguinte é o gargalo.* A forcing function ataca exatamente esse ponto.

**Hierarquia de forcing-function** (do mais fraco ao que só o core entrega):

| Nível | Trava | Quem instala | Alcance |
|---|---|---|---|
| memória `feedback` | recall automático | o adotante | 1 projeto — lembra, não obriga |
| regra no `CLAUDE.md` | contexto de toda sessão | o adotante | 1 projeto |
| **hook** (`SessionStart`/`UserPromptSubmit`) | injeta/roda a consulta a cada prompt | adotante **ou core (template)** | forte, mas cada um reinventa |
| **comandos cabeados** | trava no runtime do framework | **só o CORE** | **todos os adotantes, uniforme** |

Os três primeiros o adotante improvisa. **O quarto é o único que escala** — e é por isso que a doutrina
mora aqui, mas **vive** nos loops.

### Onde a trava está cabeada (o runtime real)

O passo KG-first é o **primeiro ato** dos três loops de retomada/execução do core — não um passo
opcional no fim (ADR, proposta #5 ✅):

- [`warm-up`](../../../.claude/commands/warm-up.md) — item 0, antes do README e da prosa dos docs;
- [`catch-up`](../../../.claude/commands/catch-up.md) — passo 0, **acima do git** na reconstrução de
  "onde paramos";
- [`engineer/work`](../../../.claude/commands/engineer/work.md) — passo 0, antes do `STATE.md`/git.

Nos três, o `allowed-tools` libera `Bash(bash ${CLAUDE_PLUGIN_ROOT}/validation/kg-radar.sh*)` — a trava sem a
permissão seria conselho outra vez.

**Gated (o sinal pediu, o dogfood ainda não disparou):** hook-template de KG-first distribuível,
projeção `kg state` como irmã de 1ª classe do radar, e distribuição downstream via `inbound/`. Valem a
doutrina **gated-until-trigger** deste próprio padrão: o mecanismo vem depois do uso que o prove, não
antes.

## Multi-runtime — o motor tem UMA autoridade e portas conformance-gated (absorvida do campo: onion-pessoal-app)

O validador local de `.kg.yaml` deve **DELEGAR** ao `kg-radar.sh`, nunca reimplementar a gramática —
parser duplicado é onde o **falso-verde** volta (doutrina do local-validator, sessão 2026-07-18). Mas o
campo achou a exceção que a regra não cobria: **um runtime onde o `.sh` não roda.** O app companheiro
(`onion-pessoal-app`) precisa do gate de escrita **no device** — Hermes/React Native, sem bash. Delegar é
impossível ali. A regra generalizada:

> **O `kg-radar.sh` é a AUTORIDADE ÚNICA — o SSOT do motor.** Delegue quando o runtime permitir; quando ele
> **proíbe** delegação (on-device/Hermes/…), uma porta em outro runtime é legítima **SÓ como adapter
> conformance-gated** — e um **teste de conformidade porta↔`.sh` sobre os MESMOS fixtures É o gate
> anti-drift** que a doutrina do local-validator exige. O que torna a reimplementação segura não é a porta;
> é o conformance.

**O corte certo do que portar** (validado em campo): porte o **subset que REPROVA** — INTEGRIDADE (ids
duplicados, aresta para nó inexistente, órfão, enum inválido) + SCHEMA (versão). As camadas **analíticas
soft** — reconciliação (REFUTES/SUPERSEDES), atenção (peso × centralidade), frescor, radar-de-domínio —
**ficam no `.sh`** do nó confiável, porque não são gate: são leitura, não reprova. Um gate de escrita
on-device só precisa do que reprova.

**Invariante que o conformance protege:** a porta **não pode bifurcar a gramática**. Os **nomes de campo
permanecem canônicos** — `node_type`, não `type` (o `.sh` é normativo: linha *"node_type: <tipo> (não
`type:`)"*). Um perfil **leve** de KG (captura/pessoal) é sancionado como **subconjunto ESTRITO com nomes
canônicos** — obrigatório `{schema_version, id, node_type, edges válidas}`; opcional `{impact, confidence,
status, layer}` (alimentam a análise soft, degradam gracioso no radar completo). Leveza = **omitir
opcionais**, nunca **renomear obrigatórios**; o conformance sobre os fixtures pega a bifurcação.

**Origem de campo (2026-07-19):** `kgRadar.ts` (porta JS do subset-que-reprova) com conformance JS↔sh
**6/6** — 1 KG válido + 5 defeitos (aresta pendurada, enum, id duplicado, schema divergente, edge_type).
O sinal upstream perguntou se isto vira doutrina; vira: **kg-radar como SDAAL de múltiplos runtimes com
contrato de conformidade.** É o mesmo princípio SDAAL do resto do Onion — uma abstração/autoridade, N
implementações que provam conformidade ao contrato — aplicado ao motor de KG.

> **O contrato de conformidade DEVE incluir o caso CAMPO-CITADO-EM-TEXTO-LIVRE** (crédito: sinal de
> campo onion-pessoal-app, 2026-07-19 — descoberto errando: a estrela pushou um grafo quebrado).
> **Histórico e estado atual:** o `kg-radar.sh` é line-based e, até 2026-07-19, casava campos por
> **substring de linha**; um `label` cujo texto citasse um token (ex.: `label: "66 nós, TODOS
> layer:audit, ZERO domain"`) virava configuração e produzia falso-`B_TRAP`, reprovando um grafo
> correto. **Isso está CORRIGIDO no soberano**: todos os campos passaram a casar em **posição de
> campo** (`^[[:space:]]*<campo>:`, match *e* `sub` ancorados), estendendo a defesa que já existia
> só para `trace:` — em **todas as seções**: `nodes`, `edges` (`to`/`edge_type`/`on`) e `meta`.
> **Por que segue no contrato:** a armadilha é **inerente a parser line-based**, então **toda porta
> em outro runtime nasce com ela** — a porta JS inclusive. O fixture de conformidade porta-vs-`.sh`
> precisa cobrir o caso explicitamente, senão a porta sela verde **reproduzindo o bug que o gate
> existe para impedir** (falso-verde pela porta, não pelo `.sh`). Dois vetores reais medidos, ambos
> obrigatórios no fixture: (1) `label` citando `layer:`/`status:`/…; (2) em aresta, `to:
> D_migrate_to:v2` recortado na última ocorrência (→ nó inexistente) e `on:` lido de dentro de
> `reason:` (`reas·on:`).

## Anti-whack-a-mole (disciplina complementar)

- **SSOT-por-conceito**: uma variável = um significado; nomear distinto quando fluxos divergem.
- **Blast-radius**: modelar variável→consumidores (`DEPENDS_ON`/`CAUSES`) e listar consumidores
  **antes** de mexer.
- **Replay/golden-test**: snapshot→muda→replay+diff pega regressão em outro fluxo.
- **Invariantes como asserts testados**, não comentários.

## Design/atom-map — a 1ª instância da camada domain (ADR design-extends-kg)

A rastreabilidade de **átomos de UI** não ganha grafo próprio — **estende esta camada domain**
(`onion-adr-design-extends-kg-2026-07.md`, ADR interno do core — **em síntese:** design e KG-SDAAL são
eixos **ortogonais**: design **DIVERGE** (generativo, gate WCAG decide) e o KG **REGE** (rastreabilidade +
fonte-única, depois de decidir); o `atom-map` é **join**, não 2º grafo, e o `SourceTag` é a aresta
`TRACES_TO` renderizada — adaptador do adotante, não motor do core; gate satisfeito pelo artefato real do
app de um adotante, `2026-07-09-artefato-command-center-atom-map.md` (sinal-artefato interno do core — a
Fase 0 do redesign: ~35 átomos, cada um com 1 fonte + 1 dono-de-exibição + 1 dono-de-escrita, ledger de
de-dup e invariante de fonte-única verificável por grep)):

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
self-contained (grafo interativo Cytoscape + veredito do `kg-radar.sh` embutido), mesmo padrão do
`federation-console.sh` (zero backend, zero CDN, determinístico). Ver ≠ distribuir.

**A IA que EXPLICA o grafo — narração pré-cozida** (ratificado no ADR *console rico do KG*,
`docs/analysis/onion-adr-kg-console-rich-2026-07.md` — decisão de arquitetura core-only). O console evoluiu de
SVG estático para um grafo Cytoscape com **encoding epistêmico** (tamanho ∝ atenção, opacidade ∝
confiança, borda por status, halo âmbar = stale, aresta por SUPPORTS/REFUTES⊣/SUPERSEDES⇢) e um
**tour narrado** que conduz o leitor por atenção — a narrativa é o que torna o grafo grande legível
(vence o teto de ~50 nós). A narração é um artefato `<slug>.narration.json` **autorado por agente**
(modo `/meta:kg narrate`) e **embutido** pelo console, tocado **offline** (não live-chat, que quebraria
o CSP): o `kg-console.sh` continua **LLM-free** — o único ponto com IA é a autoria. Ela é **projeção
dos 4 vereditos do radar** (atenção→ordem; REFUTES/SUPERSEDES→Aufhebung; STALE→"o que re-verificar"),
nunca fonte paralela — e **cita só ids que existem**, garantido por mecanismo (`kg-narrate-validate.sh`,
**REGRA 47**), não promessa. Fronteira de soberania: o que viaja na federação é o **contrato JSON**
(`kg-view.sh --json`) + o método de encoding + o arco de narração — **nunca o JS do renderer** (o
Cytoscape é *uma* implementação). Ver ≠ distribuir, uma camada acima.

## Mapeamento completo — o playbook (`/meta:kg map <área>`)

> **Situação (recognition-primed):** vai redesenhar/refatorar/assumir uma área e o conhecimento dela
> vive espalhado (telas, endpoints, regras implícitas). **Playbook:** mapear a área como SSOT de
> domínio ANTES de mexer — o contrato primeiro, o pixel/refactor depois. Nasceu de 2 dogfoods reais
> de um adotante e se repete a cada adotante que assume uma área.

O PFR completo (F0 inventário → F1 contrato → F2 `.kg.yaml` → F3 radar → F4 adaptador) vive no
comando [`/meta:kg`](../../../.claude/commands/meta/kg.md) §Modo map. O essencial doutrinário:

- **F1 tem 3 variantes — todas por identidade, não analogia** (o mesmo motor, o mesmo radar):
  1. **UI → atom-map** (contrato de átomos): 1 átomo = 1 fonte + 1 dono-de-exibição + 1
     dono-de-escrita; `SourceTag` (endpoint+concept+formula) como rastreabilidade-componente;
     ledger de de-duplicação; **pergunta atômica por aba**. Exemplar:
     `2026-07-09-artefato-command-center-atom-map.md` (sinal-artefato interno do core).
  2. **Backend/API/funcionalidade → fatias de domínio**: entidades/estados/eventos/regras ancoradas
     no código; endpoint = `entity` fonte. Exemplar:
     `2026-07-08-kg-dogfood-completo-promover.md` (sinal upstream interno do core)
     (4 fatias: ciclo do SLOT, integração PULL, máquina de SLA, dicionário ubíquo).
  3. **Jornadas/fluxos → máquina de estados**: passos = `state` do progresso do ator/processo,
     avanço = `TRANSITIONS(on evento)`, cada passo `TRACES_TO` tela/endpoint. O radar entrega valor
     imediato: **estado-absorvente = drop-off/limbo do funil**. Tipos novos (`actor`, `step`) só
     quando um dogfood provar a falta — gated-until-trigger, a doutrina deste próprio comando.
- **O doc-contrato e o grafo se referenciam** (atom-map = join, per ADR): doc = contrato humano que
  as fases de implementação obedecem; `.kg.yaml` = camada máquina que o radar verifica.
- **Invariante grep-verificável no repo do adotante**: cada endpoint-dono aparece como fonte de
  exibição em 1 componente ("cara-crachá" — `verify-read-path-first` aplicado ao front).

### A 3ª aplicação — o mesmo motor como DIAGNÓSTICO de engajamento (`/meta:kg diagnose`)

O `map` mapeia **software**; a mesma máquina — 2 camadas + radar — mapeia um **engajamento de
consultoria** (descoberta de negócio). É a **tese-núcleo aplicada ao diagnóstico**: o grafo é
runtime, o **radar diagnostica**. Cada primitiva ganha leitura de negócio: **atenção** = onde focar
a consultoria (não a dedo — o radar ranqueia); **reconciliação** = a hipótese que a descoberta
refutou (fontes conflitam → `claim` a reconciliar); **estado-absorvente** (`--domain`) = **o gargalo
do cliente**, onde a jornada morre (a mesma detecção que achou o SLOT-limbo num software). As 2
camadas: `domain` = o negócio do cliente (SSOT), `audit` = a epistemologia da consultoria
(hipóteses/teses) que `TRACES_TO` o domínio. A cadência é humano-no-loop —
**construir→pausar→perguntar→responder**, radar como gate por lote. **Soberania:** o método/modo vai
ao core; o **KG do engajamento** (dado do cliente) fica no repo dev do adotante e **nunca sai** —
mesma partição do gate client-safe. Nasceu de dogfood de campo (~107 nós/172 arestas). Detalhe:
`.claude/commands/meta/kg.md` §Modo diagnose — decisão de arquitetura core-only.

## Generalização para o core — EXECUTADA (2026-07-10) + Fase 2

O gate abriu (2026-07-04) e a camada domain foi promovida (2026-07-10, sinal
`2026-07-08-kg-dogfood-completo-promover.md`, sinal upstream interno do core):
o motor soberano `${CLAUDE_PLUGIN_ROOT}/validation/kg-radar.sh` computa as 4 saídas + `--triples` do YAML puro,
zero serviço externo, com fixtures no selftest de guardas. A implementação de referência do adotante reusa o stack ML
dele (embeddings MiniLM, pgvector, grafo `ElementLink`) — **não portar dependências**: o que viaja
na federação é **schema + método**, nunca o código do motor.

**Fase 2 semântica (método promovido, implementação soberana):** embeddings + cosseno para flagar
redundância entre nós (o cluster do limbo no dogfood de campo foi detectado assim). Cada
instância implementa com seu stack; o core permanece determinístico até a escala pedir.

## Relações

- **≠ `/meta:graph`**: aquele é a lente sócio-técnica da *spec-as-code* (estrutura do framework);
  este é o grafo do *conhecimento de uma investigação* (claims/decisões/evidência). Complementares.
- **Parentesco**: protocolo de re-teste do diário (`/meta:diary review`); doutrina de dogfood
  ([onion-dogfooding-doctrine](onion-dogfooding-doctrine.md)) — "invoque o artefato e observe" é a
  regra PROD-plane em outra roupa.
- **Origem e crédito**: uma instância adotante, auditoria de produção (evidência: radar priorizou cura de
  raiz sobre paliativos; reconciliou 6 auto-correções como `REFUTES`; integridade pegou 3 órfãos).
