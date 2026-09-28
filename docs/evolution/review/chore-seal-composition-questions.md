---
title: 'Três perguntas seladas, e a micro-ancoragem achou uma citação que não existe'
date: 2026-09-28
branch: chore/seal-composition-questions
reviewed_diff_sha256: 3eed3893c56778c42165e9eec2928be2becbafbeb1b08e821aad49a72e9d2edb
elenxo: sim
findings_total: 8
findings_real: 8
verdict: REPROVADO_E_CURADO
tokens: 264987
duration_min: 27
agents: 1
nota: 'Refutador opus em worktree ISOLADA, mandato REFUTAR, default REPROVADO. Veredito: REPROVADO em 2 pontos — e os dois eram claims MINHAS no grafo novo, não as selagens. 8 achados (2 BLOQUEIA, 4 corrigir, 2 informativo), TODOS curados neste PR. Ele também refutou 8 dos meus ângulos de ataque por medição, incluindo a suspeita de que `done` num nó question fosse impróprio: é a NORMA do corpus (87 de 367) e o kg-radar tem isenção TIPADA para done+question. E re-mediu a ancoragem negativa do zero, chegando mais longe que eu: 38+ variações, HTML bruto, JSON-LD, AMP, feeds e o tarball inteiro do repo (817 arquivos) — `grep -riw veto` = 0.'
---

# Resíduo — três perguntas seladas por decisão do maestro

## O que foi selado, e com que autoridade

O maestro decidiu os três nós `question` de `agent-command-composition-2026-09` por formulário, e cada
selagem carrega o que a autoriza:

| nó | status novo | o que o carimbo declara |
|---|---|---|
| `Q_AGENT_COMMAND_COMPOSITION_0928` | `done` | que **não é medição do mundo**: afere a decisão do maestro que tornou a pergunta sem valor de decisão (construir o `/meta:forge`). O nome do composto fica explícito como não-provado em nenhuma direção |
| `Q_CONTEXT_KUBERNETES_IS_NOT_THE_DESTINATION_ART` | `confirmed` | as 4 medições da leitura integral da fonte primária (88 KB) |
| `Q_CONDUCTOR_VETO_ANCHORING_PENDING` | `done` | a micro-ancoragem **executada** nos dois locators, com o resultado de cada um |

A pergunta **derivada** do segundo (destino-em-grafo é diferencial do Onion ou lacuna do campo?) **não**
foi selada: mudou de casa para `docs/onion/graph/forge-comando-framework-2026-09.kg.yaml` como
`Q_DESTINO_DIFERENCIAL_OU_LACUNA`, `open`, com os três gatilhos preservados. Separar foi deliberado — ela
decide o VALOR da peça 5 da forja, e o grafo de origem está no teto com cláusulas que não a cobrem.

## O achado que vale mais que as selagens

A micro-ancoragem do Conductor tinha duas metades. Uma ancorou; a outra **não existe na fonte**.

- **Validação de schema: ANCOROU**, e mais forte que a claim original. Verbatim de
  `docs/workflow-syntax.md` (http 200, 176.151 bytes): *"conductor enforces a strict contract: stdout
  must be a single JSON object … the **merged dict** is validated against the schema"* e *"If either
  check fails, a correction prompt is sent in the same session asking the model to fix its response"*.
  Virou `E_CONDUCTOR_SCHEMA_VALIDATION_ANCORADO`, tier 10.
- **"Roteia, não veta": a frase NÃO ESTÁ LÁ.** Post oficial baixado inteiro (http 200, 242.008 bytes),
  texto extraído 12.993 caracteres, dez termos medidos: `only routes` 0× · `cannot block` 0× ·
  `routes between` 0× · `veto` 0× · `block individual` 0× · `blocking` 0× · `deny` 0× · `reject` 0× ·
  `guardrail` 0×. No doc do repositório, `veto` 0×, e as 31 ocorrências de `block*` são bloco YAML,
  bloco de código ou bloqueio de path traversal.

**A lição é sobre a maquinaria da pesquisa, não sobre o Conductor.** A claim foi rejeitada na ancoragem
por **locator** errado, e o **conteúdo** seguiu registrado como *"confirmado pelo verificador"* — e ele
não reproduz. Quote atribuída a um `grep` que não se reproduz é fonte fabricada **uma camada acima** da
que o juiz pega: ele barrou o endereço e deixou passar a citação. Nenhuma decisão do core pode citar
"a arte externa não veta" como fundamento: não há fonte.

## O teto que subiu, e por quê

`agent-command-composition-2026-09`: **26 → 27 nós**, pela cláusula (d) que o próprio `meta:` já
declarava. Não é teto afrouxado; é cláusula cumprida — e a metade que voltou negativa **não gerou nó**,
só carimbo. O número canônico foi editado na linha que o guarda lê (`TETO: 27 NÓS`), porque escrever
"TETO REVISADO" numa linha nova não casa o predicado e o guarda seguiu cobrando 26 — medido, não suposto.

## Realinhamento

`/meta:realign` nos três grafos em jogo: **ALINHADO** nos três, `(c)=0 · (b)=0 · (a)=0`,
commitment e binding zerados. Importa porque três flips de status aconteceram aqui: se algum tivesse
deixado alvo de `SUPERSEDES` não-reconciliado, sairia como drift tipo-(c).

## Nada órfão (a contrapartida)

Os três fios abertos da forja estão projetados em `docs/backlog.md` com atenção medida:
`D_FORGE_META_COMANDO` 21.0 · `O_N1_NAO_E_PADRAO` 12.8 · `Q_DESTINO_DIFERENCIAL_OU_LACUNA` 7.5.

## A passada adversarial REPROVOU, e as duas bloqueantes eram minhas

### F1 — eu citei a DOENÇA como prova contra a CURA

`C_CONVENCAO_NO_DESTINO_MORRE` afirmava, com `confidence: 0.95`, que *"convenção no destino já falhou:
três pesquisas perderam o `write(KG)`"*. Medido pelo refutador e reconferido por mim:

```
$ git log --format='%h %ad %s' --date=short -S 'write(KG)' -- .claude/skills/onion-orchestration/SKILL.md
6456e06a 2026-07-18 feat(orchestration): write(KG) closing step — pesquisa persiste no KG-SSOT
```

O passo 7 — a convenção que eu indiciava — **nasceu em 2026-07-18, o mesmo dia do sinal, COMO RESPOSTA
àquelas três pesquisas**. Elas são PRÉ-convenção: provam que *ausência de mecanismo* falhou, não que
*convenção* falhou. A prova certa já estava na outra perna e agora LIDERA: as 8 passadas de Elenxo
evaporaram com o passo 7 **já em vigor** (2026-07-23). O `verified_against` passou a citar o sinal
primário datado, que existe no repo e o nó não citava:
`docs/evolution/inbox/_processed/2026-07-18-deep-research-no-auto-kg-persist.md` (os três run ids).

### F2 — acertei os números e errei a superfície; `install ≠ adopt`

`C_FACE_ADOTANTE_NASCE_MORTA_HOJE` usava os 3 SOFT da REGRA 74 (Caminho .claude/ NU dentro de plugin só
resolve no core, com catraca) para afirmar sobre a **face do adotante**. Mas
`.claude/utils/adopt/vendor-manifest.sh` põe `.claude/utils` inteiro em `_base`, e `_role_cut` corta
`utils/wizard/` **só no papel `standalone`** — no adotante o caminho RESOLVE. Três erros somados: alvo
errado (plugin/install, não adopt), causa mecânica errada (o que falta é o MOTOR ter viajado, não a linha
de permissão), e a consequência *"nasce morto"* era **cópia da mensagem da própria guarda**, citada como
se fosse medição consumer-side que não existe neste repo. O nó virou
`C_FACE_QUE_VIAJA_TEM_MOTOR_CORTADO`, com a consequência declarada **INFERIDA** e gatilho nomeado para
medi-la (rodar a skill num repo que só INSTALOU o plugin).

### Os outros seis, todos curados

| # | achado | cura |
|---|---|---|
| F3 | o grafo novo era **0/7 invisível** ao índice de leitura: `kg-trace-resolve.sh` não quebra em `·`, então `trace:` multi-caminho não entra | `Q_DESTINO_DIFERENCIAL_OU_LACUNA` ganhou `trace:` de caminho ÚNICO e NU → o grafo passou a ter **2 entradas**, e quem tocar o grafo de origem agora é avisado da pergunta mudada de casa. **Responde ao ângulo 5: o `trace:` NÃO bastava** |
| F4 | unidade trocada: `176.151 bytes` é `wc -m` (caracteres); o `curl` emite **176.749** | número corrigido, unidade nomeada, contagens declaradas CASE-INSENSITIVE (sensível: 39/102/50/25) e o extrator dos 12.993 caracteres declarado |
| F5 | duas citações de teto caducas escritas por esta própria leva (`26/26` ao lado de `27/27` no mesmo bloco) | ambas corrigidas para 27 |
| F6 | os três rótulos selados **abriam afirmando o estado velho** ("PROPOSTA DE VEREDITO", "PENDÊNCIA DE ANCORAGEM") — e toda vista truncada mostra o começo | os rótulos abrem no estado selado, com o texto original preservado logo depois |
| F7 | `source_tier: 10` afirmando COMPORTAMENTO com base só na doc do fornecedor | corroborado na IMPLEMENTAÇÃO (`src/conductor/config/schema.py` l.625-626, `providers/hermes.py` l.724, `_pydantic_ai/structured_output.py` l.60) — o tier ficou honesto |
| F8 | `run_onion_research_selftests` **não existe**: são duas famílias | nomes reais no rótulo |

### Oito ângulos meus que o refutador REFUTOU por medição

O mais útil: minha suspeita de que `done` num nó `question` fosse impróprio, e que `superseded` custasse
uma aresta. **Ambas falsas** — `done` é a NORMA (87 de 367 nós `question`), o `kg-radar.sh` tem isenção
**tipada** para `done`+`question` (*"cobrá-la seria o gate punindo quem obedeceu"*), e 49 de 231 nós
`superseded` do corpus não têm aresta `SUPERSEDES` sem nada reprovar. O carimbo do Q1 também passa no
espírito do `DONE-NU`, e pelo motivo inverso do temido: a guarda existe contra *"carimbo de ar que
DECLARA medição que não houve"*, e o meu declara que medição do mundo **não** houve.

Ele ainda **re-mediu a ancoragem negativa do zero e foi mais longe**: 38+ variações de redação, HTML
bruto, JSON-LD, AMP (404), `/feed/`, `/embed/`, e o tarball inteiro do repositório (817 arquivos) —
`grep -riw veto` = **0**, e as 31 ocorrências de `veto` são substring de camelCase (`ServeToolInfo`,
`resolveTo`). As três quotes verbatim reproduzem EXATAS (`grep -F`, 1 cada), e as 4 medições do paper
reproduzem contra fetch independente e fresco do arXiv.

## Declarado aberto, FORA deste PR

- **Correção de escopo em `C_BACKTICK_EM_PROSA_DENTRO_DE_CONTEXTO_QUE_INTERPRETA`**
  (`passada-adversarial-2026-09`): o rótulo descreve crase em prosa, mas a classe medida é mais larga —
  **qualquer substituição em contexto que interpreta**, `$( )` incluído (a 5ª ocorrência foi
  `$(gh pr view` dentro de aspas duplas). Fica fora porque é reconciliação de outro grafo e este PR é de
  selagem; o nó já registra que o gatilho de mecanizar DISPAROU e está gated na decisão do maestro.
  GATILHO: a decisão dele sobre construir a guarda, ou a 6ª ocorrência.
- **Modelagem das 7 peças da forja como 7 nós**: hoje vivem num `label` único, sob o teto de 7 nós.
  GATILHO escrito no `meta:` do grafo — a SEGUNDA instância de comando-com-framework existir.
- **`kg-trace-resolve.sh` não quebra `trace:` multi-caminho em `·`** — 5 grafos em 101 são totalmente
  invisíveis ao hook de leitura por isso, e a cura é no GERADOR, não em cada grafo. Fora deste PR porque
  é outro artefato e outra frente. GATILHO: o próximo grafo que nascer invisível, ou uma decisão que
  dependa do hook avisar.
- **Peça 4 da forja não é única em `.claude/workflows/`**: `.claude/utils/census/census-workflow.mjs` é
  um segundo script de orquestração faseada — só a CONVENÇÃO DE LUGAR é única. E a peça 6 é meia-verdade:
  as REGRAS 26/67 cobram a saída em grafo, mas **nada valida `.claude/rules/*.md`** — o arquivo da lente
  está desguardado. Apontado pelo refutador (F8); registrado aqui porque muda o desenho da forja.
