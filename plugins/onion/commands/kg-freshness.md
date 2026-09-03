---
name: kg-freshness
description: |
  RE-VERIFICA contra o vivo os nós de um .kg.yaml — o que o radar apenas DETECTA.
  Consome a fila determinística do `kg-radar.sh --freshness-tsv` (ordenada por atenção,
  NÃO pelo que o radar flagou) e roda um worker por nó, que MEDE e devolve
  CONFIRMED/DRIFTED/REFUTED/UNVERIFIABLE + o comando executado + o observado verbatim.
  O worker NUNCA escreve: propõe. O maestro sela. Irmão de /meta:kb-freshness e
  /meta:context-freshness, com uma diferença declarada — aqueles não têm onde escrever,
  o KG tem.
category: meta
tags: [kg, freshness, orchestration, validation, ssot]
version: "1.0.0"
updated: "2026-07-27"
allowed-tools: Read Write Edit Grep Glob Bash
argument-hint: "[<arquivo.kg.yaml>] [--top N] [--node <id>]  (vazio = grafo mais recente, top 16 por atenção)"
related_commands:
  - /meta:kg
  - /meta:kb-freshness
  - /meta:context-freshness
  - /meta:diary
related_agents:
  - research-agent
---

# /meta:kg-freshness — re-verificar a SSOT contra o vivo

## Objetivo

O `kg-radar.sh` **detecta** frescor (STALE-MISSING · STALE-OLD · UNANCHORED) e para aí:
re-carimbar era prosa manual. Este comando fecha a perna que faltava — ele **mede**.

**O caso que o criou.** No grafo do M2, `C_ancestor_cap_zeroes_floors` afirma `plane: PROD`
que os floors de memória têm "proteção efetiva ZERO". É **falso desde 2026-07-26**
(`/sys/fs/cgroup/system.slice/memory.min` = 402653184). Mas o nó tem `verified_against:
host-vps-medido` e `verified_at` do próprio dia — **os três vereditos passam e o radar fica
em silêncio**. Pior: o grafo já contém `E_ancestor_floor_applied` documentando o conserto,
**sem aresta** para o nó que ele derruba, então a INTEGRIDADE também é cega.

Um nó `impact: 5 / confidence: 0.95` mente com carimbo do dia e **nenhum mecanismo do repo
o vê**. É isso que este comando existe para pegar.

## A regra que não se negocia

> **Re-testar, nunca re-carimbar.** (`onion-dogfooding-doctrine.md:151-155`)

O worker **não escreve no grafo**. Ele mede e devolve uma proposta. O maestro sela.
Carimbo automático seria industrializar exatamente a falha que o `UNANCHORED` denuncia:
um `verified_at` novo que não corresponde a medição nenhuma.

**O único caminho para um `verified_at` novo passa por uma medição executada.**
Não medi ⇒ não carimbo — `UNVERIFIABLE` é desfecho de primeira classe, não fracasso.

## Quando usar

- ✅ Antes de decidir com base num `.kg.yaml` antigo (o `/catch-up` já manda ler o KG primeiro
  — este comando responde "e ele ainda é verdade?")
- ✅ Depois de uma janela de mudanças no vivo (deploy, flip, hardening) que possa ter
  envelhecido claims `plane: PROD`
- ✅ Quando o `--freshness` acusar STALE/UNANCHORED em nó de alta atenção
- ❌ Não use para *criar* grafo (isso é `/meta:kg novo`) nem para pagar passivo de
  proveniência (isso é `/meta:kg backfill`)

## Etapas de Execução

### Passo 0 — Legibilidade antes de veredito

```bash
bash ${CLAUDE_PLUGIN_ROOT}/validation/kg-radar.sh <arquivo> --integrity --schema
```

Exit ≠ 0 ⇒ **pare**. Não se re-verifica grafo que o motor não sabe ler — veredito sobre
arquivo quebrado é vacuidade (mesmo racional da guarda de LEGIBILIDADE do radar).

### Passo 1 — Escopo, do motor e não da impressão

```bash
bash ${CLAUDE_PLUGIN_ROOT}/validation/kg-radar.sh <arquivo> --freshness-tsv | sort -t$'\t' -k7 -rn
```

11 colunas: `id · node_type · plane · status · impact · confidence · atenção · verified_at ·
verified_against · trace · verdict`.

**`verdict: TESTIMONY` NUNCA entra na fila.** Nó com `evidence_class: testimony` (fonte é
RELATO — intenção, fato de campo fora do repo) é não-re-verificável por construção: o worker
concluiria `UNVERIFIABLE` a 74k tokens/nó. O radar o conta em linha própria (`ℹ N nó(s) TESTEMUNHO`),
acusa `TESTIMONY-UNMARKED` quando o alvo começa por `relato-` sem o marcador, e `MISPLANED` quando
testemunho se diz `plane: PROD`. (Q_TESTEMUNHO_NAO_MEDIVEL_0804, mecanizado 2026-09-02.)

**Diga em voz alta no relatório:** nós com `verdict: OK` **permanecem na fila**. O carimbo diz
se a SSOT está bem-formada; a **atenção** diz o que custa caro estar errado. Re-verifica-se
pelo **custo do erro**, não pela ausência do carimbo — senão o fluxo nasce cego ao caso que o
criou. Corte em `--top N` (default **16**, o teto de workers da doutrina) e **declare o corte**
(silenciar truncamento é a mesma vacuidade uma camada acima).

### Passo 2 — Delegar padrão à skill

Invoque `onion-orchestration` (fan-out-and-synthesize). Não reimplemente o padrão aqui.

### Passo 3 — Fan-out: um worker por nó

Cada worker recebe **o registro TSV + o path do `.kg.yaml`** — nunca o grafo inteiro.

Contrato do worker (cada cláusula paga por um erro real desta casa):

- **READ-ONLY sempre.** Medição que exigiria mutação (`systemctl set-property`, escrever
  arquivo, chamar endpoint que muda estado) ⇒ `UNVERIFIABLE` + `blocked_by`. O maestro decide.
- **`method` verbatim** — o comando/consulta que rodou. Sem ele, o veredito é opinião.
- **`observed` verbatim, NÃO interpretado** — separe o que o kernel/arquivo/endpoint disse do
  que você concluiu. Foi confundir os dois que produziu o carimbo no artefato errado.
- **Exit code e conteúdo lido são evidência; leitura de doc é hipótese.** Um `README` que
  descreve o deploy não mede o deploy.
- **Não sabendo medir ⇒ `UNVERIFIABLE`.** Nunca `CONFIRMED` por plausibilidade. É o erro que
  este comando existe para não cometer.
- **O worker não escreve** — devolve `proposed_write`.
- **De onde sai o comando:** derive de `label:` + `trace:` + `verified_against:`. Na prática o
  método costuma estar na própria prosa do nó (ex.: *"a verificação TEM de percorrer a cadeia
  de ancestrais"*). Se o nó não disser como se mede, isso é achado — devolva `UNVERIFIABLE`
  com `blocked_by: método não derivável do nó`.
- **Bloqueio de acesso só vale TENTADO.** Antes de declarar `permission denied`, **eleve** —
  `sudo ls`, `sudo cat`, `sudo -u <dono>`. Ler é read-only, logo elevar para LER não fere a
  cláusula READ-ONLY acima (elevar para MUTAR fere, e continua proibido). *Medido 2026-08-12:*
  um worker declarou `permission denied` em `/home/onion/onion-bridge/src/`, carimbou o nó por
  inferência indireta, e `sudo ls` lia o diretório — ele já usara `sudo` em quatro comandos da
  mesma medição. Falta de acesso é hipótese até você ter tentado ([[verify-access-before-specifying]]).
  **Distinga o bloqueio de FS do bloqueio de HARNESS** (delta Claude Code 2.1.257, radar E3
  2026-09-02): com `permissions.blockReadsOutsideWorkingDirectories` ativo, leitura fora dos
  working dirs (`/home/marcio/<adotante>`, `/home/onion/onion-bridge`) é recusada pelo *harness* —
  `sudo` **não vence**, porque a parede não é o filesystem. Nesse caso devolva `UNVERIFIABLE` com
  `blocked_by: harness bloqueia leitura fora dos working dirs (<path>)` sem gastar elevação; o
  maestro decide liberar o diretório (`--add-dir`) e re-rodar. Elevar contra a parede errada é o
  mesmo erro de 2026-08-12 com o sinal invertido.
- **Nó COMPOSTO: o veredito é do TODO, não da maioria.** Um nó que afirma N mecânicas
  independentes recebe UM `verdict`. Mediu 3 de 3 ⇒ o veredito que a medição disser. Mediu 2 de 3
  ⇒ **`UNVERIFIABLE`**, com `blocked_by` nomeando a parte não medida — nunca arredonde para cima.
  `CONFIRMED` é o desfecho que não pede justificativa, e por isso é para onde um worker escorrega.

Tiering: `sonnet`/`medium` no worker (derivar o método pede raciocínio, não é mecânico);
`opus`/`high` no **juiz adversarial — etapa FIXA** (decisão do maestro 2026-08-30, sobre
calibração com padrão-ouro: FP 20% na acusação de subcontagem, SUB 0/7 — nunca erra na direção
perigosa — e o único mecanismo que pegou um `ls` curado vendido como observed verbatim). Os
vereditos do juiz PERMANECEM PROPOSTA que o maestro sela. Em runs grandes o juízo PODE ser
escopado aos vereditos CONFIRMED (o desfecho barato de fabricar), com o corte DECLARADO no
relatório. ⚠️ A regra anterior — juiz condicional a ">30% DRIFTED" — foi REMOVIDA por furo
medido: o gatilho dependia do AUTOJULGAMENTO dos workers, exatamente o que o juiz existe para
auditar (subcontagem de 44-48% medida em dois corpora).

Schema de retorno:

O schema é **JSON Schema de verdade**, passado em `opts.schema` — não pseudocódigo ilustrativo.
A restrição do `blocked_by` mora **nele**, não na prosa acima.

> ⚠️ **O que a falha de schema faz, medido e não suposto:** o tool-layer faz o worker **retentar**;
> se as tentativas se esgotarem, `parallel()` devolve **`null`** para aquele item e a
> `onion-orchestration` manda `.filter(Boolean)` antes do fan-in. **As duas coisas são verdade, e a
> segunda é a que importa aqui:** um worker que não converge **some da fila em silêncio**. Por isso
> o fan-in **tem de reportar quantos foram descartados** — sem isso, o nó de maior atenção pode
> evaporar e o relatório sair "16/16 medidos" tendo medido 15. Guarda de schema sem contagem de
> descarte troca um fail-open por outro.

```javascript
const KgReverifySchema = {
  type: "object",
  // UMA lista só. Duas chaves `required` no mesmo objeto = a segunda SOBRESCREVE a primeira,
  // em silêncio — foi o defeito medido em 2026-08-12, na primeira versão desta própria guarda,
  // e é a MESMA classe de `verified_at` duplicado que o grafo daquele dia catalogou.
  required: ["node_id", "kg_file", "method", "observed", "verdict", "divergence", "blocked_by",
             "claims_total", "claims_measured", "coverage"],
  properties: {
    node_id: { type: "string", minLength: 1 },
    kg_file: { type: "string", minLength: 1 },
    method:   { type: "string", minLength: 1 },  // o comando EXECUTADO, verbatim — auditável
    observed: { type: "string", minLength: 1 },  // o que voltou, verbatim, não interpretado
    verdict:  { enum: ["CONFIRMED", "DRIFTED", "REFUTED", "UNVERIFIABLE"] },
    divergence: { type: "string" },  // o que o nó afirma × o que se mediu ("" se CONFIRMED)
    blocked_by: { type: "string" },  // SEMPRE PRESENTE: "" quando nada bloqueou; não-vazio SÓ em UNVERIFIABLE.
                                     // ⚠️ NUNCA OMITA (medido 2026-08-29, 1º piloto): um worker leu o antigo
                                     // "SÓ em UNVERIFIABLE", OMITIU a chave num CONFIRMED, e a barragem do schema
                                     // o rejeitou 5/5 vezes — nó inteiro descartado por um comentário ambíguo.
    proposed_write: { type: "string" },  // YAML proposto; o worker NÃO escreve
    // COBERTURA — o antídoto do nó COMPOSTO. Quantas das afirmações independentes do nó
    // a medição alcançou. Declarada ANTES do veredito, de propósito: obriga a CONTAR as
    // partes em vez de sentir o todo.
    claims_total:    { type: "integer", minimum: 1 },
    claims_measured: { type: "integer", minimum: 0 },
    coverage: { enum: ["TOTAL", "PARCIAL"] },
  },
  // ⚠️ AS 3 GUARDAS VIVEM NUMA CADEIA if/then/else ANINHADA, COM RAIZ NA COBERTURA — e a
  // raiz NÃO é escolha de estilo, é MEDIDA. Historial (2026-08-29, 1º run real do comando):
  //   (a) a forma anterior — `allOf:` no topo — foi RECUSADA pela API 8/8 vezes, erro literal
  //       `400 input_schema does not support oneOf, allOf, or anyOf at the top level`
  //       (run wf_6aa135ec-1e2). As guardas NUNCA tinham rodado.
  //   (b) esta cadeia foi provada EQUIVALENTE ao allOf por tabela-verdade: 15/15 casos idênticos
  //       (jsonschema 4.26, inclui omissões de chave). E foi provada ACEITA pela API
  //       (sonda wf_742e3a39-e7f).
  //   (c) a raiz ALTERNATIVA — encadear a partir da GUARDA 1 (verdict) — DIVERGE do allOf em
  //       2 casos medidos: `{CONFIRMED, PARCIAL, blocked_by:""}` passa nela e é rejeitado pelo
  //       allOf. Esse payload é exatamente o modo-de-falha dominante (mediu parte, declarou o
  //       todo). NÃO reordene a cadeia sem refazer a tabela-verdade.
  // Semântica: coverage=PARCIAL ⇒ (GUARDA 2) verdict=UNVERIFIABLE + blocked_by não-vazio;
  // senão, verdict=UNVERIFIABLE ⇒ (GUARDA 3) blocked_by não-vazio; senão (GUARDA 1) blocked_by="".
  if:   { required: ["coverage"], properties: { coverage: { const: "PARCIAL" } } },
  then: {
    required: ["verdict", "blocked_by"],
    properties: {
      verdict:    { const: "UNVERIFIABLE" },
      blocked_by: { type: "string", minLength: 1 },
    },
  },
  else: {
    if:   { required: ["verdict"], properties: { verdict: { const: "UNVERIFIABLE" } } },
    then: { required: ["blocked_by"], properties: { blocked_by: { type: "string", minLength: 1 } } },
    else: { required: ["blocked_by"], properties: { blocked_by: { const: "" } } },
  },
};
```

> ⚠️ **O QUE ESTE SCHEMA NÃO PODE FAZER — e a primeira redação afirmou que fazia.** JSON Schema
> puro **não compara duas propriedades entre si**. Logo `claims_measured: 2, claims_total: 3,
> coverage: "TOTAL"` **passa** — que é *exatamente* o modo de falha medido em 2026-08-12 (mediu 2
> de 3, declarou o todo). O mesmo vale para `5 de 3`. A prosa do Passo 3 promete "mediu 2 de 3 ⇒
> UNVERIFIABLE"; **o schema não entrega isso e não tem como entregar.**
>
> **Onde a promessa se cumpre: no fan-in, em JS, custo 0 tokens.** Não confie na etiqueta que o
> worker escolheu — *derive-a* e confronte:
>
> ```javascript
> for (const r of vivos) {
>   if (r.claims_measured > r.claims_total) throw new Error(`${r.node_id}: contagem impossível`)
>   const real = r.claims_measured < r.claims_total ? 'PARCIAL' : 'TOTAL'
>   if (real !== r.coverage) log(`⚠ ${r.node_id}: declarou ${r.coverage}, a contagem diz ${real}`)
>   if (real === 'PARCIAL' && r.verdict !== 'UNVERIFIABLE') {
>     r.verdict = 'UNVERIFIABLE'                 // rebaixa: cobertura parcial não confirma o todo
>     r.blocked_by ||= `cobertura ${r.claims_measured}/${r.claims_total} — partes não medidas`
>   }
> }
> ```
>
> Um comentário que afirma cobertura inexistente é pior que guarda ausente: desativa a
> desconfiança do próximo leitor. Por isso o teto está aqui, e não numa nota de rodapé.

> **`if`/`then` em JSON Schema aplica-se a chaves PRESENTES.** Sem o `required:` dentro de cada
> `if` e de cada `then`, **omitir** o campo satisfaz a guarda — a guarda nasce verde-vazia para
> quem simplesmente não escreve a chave. Foi assim que a primeira versão desta seção furou; os
> `required:` acima existem por isso e **não são redundância**.

> **Teto declarado da GUARDA 2 — e ele é menor do que a primeira redação prometia.** A guarda
> obriga *coerência* entre cobertura, contagem e veredito; não obriga *honestidade* da contagem.
> Um worker que declare `claims_total: 1` num nó que afirma três passa, porque nenhum schema conta
> as afirmações de uma prosa. **Não afirme que isso torna o arredondamento "explícito"** enquanto
> os campos não aparecerem na Saída Esperada e na tabela do gate — sem isso o maestro nunca os vê,
> e um `1/1/TOTAL` mentiroso é indistinguível de um `3/3` real. Por isso eles estão nas duas
> (Passo 4 e Saída Esperada), e é o que faz a diferença entre medida e adjetivo.

### Passo 4 — Fan-in, gate humano, e só então `write(KG)`

| Veredito | O que significa | Escrita (maestro, pós-gate, **append-mostly**) |
|---|---|---|
| **CONFIRMED** | medido e ainda verdade | **Único** edit in-place permitido: `verified_at: <hoje>` (+ `verified_against:` se faltava). Nada mais. |
| **DRIFTED** | a verdade mudou; o nó não errou | **Novo** nó com a verdade atual + `SUPERSEDES` → antigo; antigo vira `status: superseded`. Nunca reescreva o label do antigo. |
| **REFUTED** | o nó estava errado | **Novo** nó `evidence` (PROD, `verified_at`, `verified_against`, `trace`) + `REFUTES` → alvo; alvo vira `status: refuted`. |
| **UNVERIFIABLE** | não deu para medir | **NÃO TOCA `verified_at`.** Rebaixa `confidence` e/ou abre `question` + `DEPENDS_ON`. |

**Antes de aplicar a linha CONFIRMED, leia a cobertura.** A tabela chaveia por `verdict`, mas o
`verdict` de um nó **composto** é uma etiqueta sobre N afirmações. O gate humano é o único ponto
onde `claims_measured/claims_total` pode ser confrontado com o `label:` do nó — o schema garante
coerência interna, nunca honestidade da contagem. Um `1/1/TOTAL` num nó que afirma três mecânicas
é *exatamente* o que a GUARDA 2 não alcança, e é barato de ver aqui: **se a contagem parece baixa
para o tamanho do label, o carimbo não sai.** Foi um nó composto (três modelos de confiança, dois
medidos) que produziu o defeito de 2026-08-12.

> **`status: drifted` não é atalho para esta tabela.** O motor aceita `drifted` (1.3) e
> `unverifiable` (1.0) desde 2026-08-06, mas **`status` é marcador de ESTADO, não de processo**:
> `drifted` = *"diverge do vivo AGORA, alguém precisa reconciliar"*. Um veredito DRIFTED **já
> reconciliado** (label atualizado + `SUPERSEDES` + posição antiga preservada) deixa o nó
> `confirmed` — a memória do veredito vive na **aresta**, não no status. Use `drifted` só quando
> mediu a divergência e **ainda não** escreveu a reconciliação.
>
> Medido no Elenxo de 2026-08-07, sobre esta mesma tabela: marcar como `drifted` quatro nós cujos
> labels já traziam a verdade medida (a) pôs no topo do radar nós corretos, afundando drift real, e
> (b) tornou a aresta `SUPERSEDES` **invisível** à seção RECONCILIAÇÃO, que só conta superseder
> `confirmed` (`kg-radar.sh:233`) — um fail-open dentro da própria correção do fail-open.
>
> **E `superseded` sempre foi legal.** A ausência de `drifted` no schema antigo nunca impediu
> cumprir a linha do DRIFTED acima: o 1º dogfood deste comando já o fizera em 2026-07-27
> (`m2-bridge-logto-2026-07.kg.yaml`). Não use "o schema não deixava" como razão — foi medido falso.

Aufhebung, não apagamento: a posição superada **fica no grafo** — é ela que explica o
desenho novo.

**Loop fechado pelo motor:** depois da escrita,

```bash
bash ${CLAUDE_PLUGIN_ROOT}/validation/kg-radar.sh <arquivo> --integrity --schema   # tem de sair 0
```

Um `REFUTES` sem reconciliar o `status` do alvo **reprova**. O radar é o revisor da própria
reconciliação — não confie na sua escrita, prove-a.

### Passo 5 — Fallback serial

Substrato Workflow indisponível ⇒ serial, **dizendo que é serial**. Nunca finja paralelismo.

## Saída Esperada

Bloco `KG REVERIFY REPORT` no formato dos irmãos, mais:
- a **contagem por veredito** e o **corte declarado** (quantos nós ficaram de fora do `--top`)
- **quantos workers foram descartados** (`null` no `parallel()` — schema não convergiu, timeout,
  worker morto) **e quais nós ficaram sem medição por isso.** Um relatório que diz "16/16" tendo
  perdido um worker é o fail-open que a guarda de schema criou ao fechar o outro
- **a cobertura de cada nó** — `claims_measured/claims_total` — ao lado do veredito, **não só dos
  não-CONFIRMED**. É o CONFIRMED com cobertura parcial que engana; o não-CONFIRMED já se anuncia.
  Sem esta linha, os campos existem no schema e morrem antes do gate humano, e a GUARDA 2 vira
  cerimônia
- para cada não-CONFIRMED: `method`, `observed`, `divergence`
- o **path do grafo escrito** (o passo 7 da `onion-orchestration` exige nomear o artefato)

## Notas

- Composição: invocado por `/meta:evolve`, devolva o array `KgReverifySchema[]` cru —
  espelha o contrato de `/meta:kb-freshness` (D4) e `/meta:context-freshness` (D9).
- `Bash` largo no `allowed-tools` é **por desenho**: medir o vivo é o ponto. O lint já registra
  que granularidade de `allowed-tools` ficou fora por gerar falso-positivo.
- Diferença declarada vs os irmãos: `kb-freshness` e `context-freshness` **nunca mutam** — mas
  a razão honesta é que **não têm onde**. O KG tem. Por isso aqui o privilégio se parte: o
  worker mede, o maestro escreve.

## Referências

- `${CLAUDE_PLUGIN_ROOT}/kb/knowledge-graph-sdaal.md` — frescor, planes, Aufhebung
- `${CLAUDE_PLUGIN_ROOT}/kb/onion-dogfooding-doctrine.md:151-155` — re-testar, nunca re-carimbar
- `${CLAUDE_PLUGIN_ROOT}/validation/kg-radar.sh` — `--freshness` (humano) e `--freshness-tsv` (máquina)
- `.claude/commands/meta/kg.md` — criar/mapear/backfill o grafo
