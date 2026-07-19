# Knowledge Graph SDAAL — fonte da verdade como grafo ponderado (CANDIDATA)

> **Status: CANDIDATA** — padrão recebido via co-evolução (sinal upstream
> `docs/evolution/inbox/_processed/2026-07-02-sinal-sdaal-knowledge-graph.md`), nascido e dogfoodado
> numa instância adotante durante uma auditoria real de produção (01-02/jul/2026).
> Autoria do método: uma instância adotante (T1 hub). Esta KB porta o **conceito
> generalizado**; a implementação de referência vive em um adotante (`scripts/kg/radar.js` +
> `docs/<adopter>/graph/audit.kg.yaml`).
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
> **F1 disparou em 2026-07-04** (1º dogfood na federação, sessão de um adotante — ver nota de doutrina abaixo)
> e **F2 executou no mesmo dia** (dogfood do core via `/meta:evolve` → `/meta:kg` + `kg-radar.sh`).
> Resta F3 (plugin `onion-investigation`), gated por maturidade de uso.
>
> **Camada de DOMÍNIO promovida em 2026-07-10** — 2º dogfood de campo (sinal
> [2026-07-08-kg-dogfood-completo-promover](../../evolution/inbox/_processed/2026-07-08-kg-dogfood-completo-promover.md):
> o grafo de auditoria evoluiu para SSOT de domínio) elevou o padrão a **duas camadas**
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
> [`2026-07-04-kg-primeiro-dogfood-federacao.md`](../../evolution/inbox/_processed/2026-07-04-kg-primeiro-dogfood-federacao.md).

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
> [onion-adr-doctrine-ingestor-2026-07](../../analysis/onion-adr-doctrine-ingestor-2026-07.md) · grafo da
> absorção: `docs/onion/graph/<adopter>-doctrine-absorption-2026-07.kg.yaml` (radar exit 0).

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
   `meta.baseline`). Ver §[Frescor e versão de schema](#frescor-e-versão-de-schema--o-radar-recusaavisa-quando-a-ssot-driftou).
6. **SCHEMA** (`--schema`, ✗ **reprova**) — `meta.schema_version` bate com a versão que o radar entende?
   Divergência = recusa (o radar não sabe ler o arquivo); ausência = ⚠ retrocompat.

Saída extra `--triples` (`from EDGE to [on evento]`) para consumo por LLM.

## Governança DEV↔PROD (a regra dura)

> **Comportamento em produção = artefato deployado + config viva + env + dados.**
> Uma `decision` só vira `done` quando **verificada no plane PROD** — "o código deveria" não fecha nó.

Evidência de campo no próprio core (mesmo dia, direção oposta): o incidente do **pin forjado**
(anúncio "você já tem o fix" raciocinou sobre o *carimbo* em vez do *artefato vendorizado*; guard
permanente: `.claude/validation/pin-integrity-check.sh`). A regra generaliza: **carimbo/doc/branch é
plane DEV; só o artefato vivo é plane PROD.**

## Frescor e versão de schema — o radar recusa/avisa quando a SSOT driftou

Um KG-SSOT que não é **re-executado** contra o estado vivo **apodrece silenciosamente** — vira "uma
bela SSOT que mente", e um consumidor confiante (IA inclusive) *propaga* a mentira. Lição-mestra do
dogfood mais intenso do padrão até hoje (um adotante, 2026-07-15/16: `maxByLevel`
no grafo `2/4/8/8/8` × real vivo `2/4/12/15/20`; bloqueador "aberto" já corrigido; feature "aguardando
push" já deployada). O valor do KG **não** é ser escrito uma vez — é ser **re-verificável**. Duas
guardas (ADR [`kg-freshness-gate`](../../analysis/onion-adr-kg-freshness-gate-2026-07.md)), a mesma
máquina com duas referências — *o radar recusa/avisa quando a SSOT driftou*:

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

## SSOT-as-runtime — o KG é o primeiro ato (mecanismo, não conselho)

> **Origem da decisão:** ADR [`onion-adr-kg-freshness-gate-2026-07`](../../analysis/onion-adr-kg-freshness-gate-2026-07.md)
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
técnico — ver a ressalva do maestro em
[`onion-repositioning-sdaal-session-2026-06-17`](../../analysis/onion-repositioning-sdaal-session-2026-06-17.md):
*"o engenheiro sênior vai perguntar 'cadê os testes?'"*.)

**O ciclo obrigatório — `read(KG) → verify(vivo) → act → write(KG)`:**

1. **read(KG)** — localizar (`ls docs/onion/graph/*.kg.yaml docs/*/graph/*.kg.yaml *.kg.yaml`) e rodar
   `bash .claude/validation/kg-radar.sh <arquivo>` **como primeiro ato**. Citar **ids de nó**, nunca
   re-derivar da prosa: o id é a migalha que torna o raciocínio auditável.
2. **verify(vivo)** — *drive-to-verify*: claim `plane: PROD` de alto impacto se cruza contra o artefato
   vivo **antes** de virar premissa (§[Governança DEV↔PROD](#governança-devprod-a-regra-dura)). Nó
   stale **mente** — o `--freshness` avisa, o `verified_at:` é o carimbo do cruzamento.
3. **act** — só então planejar/agir, com o grafo como piso.
4. **write(KG)** — o que a ação descobriu volta como nó/aresta (`REFUTES`/`SUPERSEDES` quando corrige),
   append-mostly. Sem esta perna, o ciclo é leitura, não runtime: o grafo apodrece na próxima volta.

**KG-first + drive-to-verify são o par canônico** (ADR §SSOT como runtime): nenhum sozinho basta — o KG
stale engana; o git sozinho esquece o que a SSOT já sabia.

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
| **origem da doutrina** | [`ssot-como-runtime-para-adr`](../../evolution/inbox/_processed/2026-07-16-ssot-como-runtime-para-adr.md) | montou o KG canônico e **o ignorou 3× na mesma sessão** — reconstruiu de git/memória enquanto o grafo já tinha a resposta (`E_ABANDON_APPLY_PROOF`, `C_CONSOLIDATION_MAP`) |
| **escalada a mecanismo** | `mandar-a-doutrina-kg-first` | **depois** de escrever a doutrina, reincidiu **≥4×**: planejou um redesenho do motor sem consultar o grafo. Ao consultar, o KG **corrigiu 4 erros** que ele cometeria — janela `7d`→**`14d` medido** (`C_WINDOW_SWEEP`); morte-da-chamada só-TTL→**sinal + derivação** (`C_ABANDON_PUSHED`/`Q_RELEASE_SIGNAL`); conflito com `I_NO_AGE_RELEASE`; e **metade do redesenho já existia como nó** (`R_PARAMETA`, `R_ADR018`) |

> **A reincidência É o dado.** Não é falha de disciplina do consumidor — é falha de *design* do loop.
> Um estado que depende de um evento que nunca chega é exatamente o bug do SLOT-limbo que o mesmo
> grafo diagnosticou. Documentar o KG-first e deixar o consumidor lembrar **reproduz o bug**.

Não é anedota de um adotante: a pesquisa de migalhas do core já **mediu** o gargalo — recall passivo
quase perfeito **despenca para 40-60% no uso ativo em decisão**
([work-models-research](../../analysis/onion-work-models-research-2026-07.md)). *Escrever a migalha é
fácil; a absorção na decisão seguinte é o gargalo.* A forcing function ataca exatamente esse ponto.

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

Nos três, o `allowed-tools` libera `Bash(bash .claude/validation/kg-radar.sh*)` — a trava sem a
permissão seria conselho outra vez.

**Gated (o sinal pediu, o dogfood ainda não disparou):** hook-template de KG-first distribuível,
projeção `kg state` como irmã de 1ª classe do radar, e distribuição downstream via `inbound/`. Valem a
doutrina **gated-until-trigger** deste próprio padrão: o mecanismo vem depois do uso que o prove, não
antes.

## Anti-whack-a-mole (disciplina complementar)

- **SSOT-por-conceito**: uma variável = um significado; nomear distinto quando fluxos divergem.
- **Blast-radius**: modelar variável→consumidores (`DEPENDS_ON`/`CAUSES`) e listar consumidores
  **antes** de mexer.
- **Replay/golden-test**: snapshot→muda→replay+diff pega regressão em outro fluxo.
- **Invariantes como asserts testados**, não comentários.

## Design/atom-map — a 1ª instância da camada domain (ADR design-extends-kg)

A rastreabilidade de **átomos de UI** não ganha grafo próprio — **estende esta camada domain**
([ADR](../../analysis/onion-adr-design-extends-kg-2026-07.md), gate satisfeito pelo artefato real do
o app de um adotante em [2026-07-09](../../evolution/inbox/_processed/2026-07-09-artefato-command-center-atom-map.md)):

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
> de um adotante e se repete a cada adotante que assume uma área.

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
