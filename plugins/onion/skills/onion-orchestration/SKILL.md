---
description: >
  Reconhece trabalho elegível a fan-out e autora/dispara um script da ferramenta
  nativa Workflow que codifica o padrão canônico certo. Use quando houver N
  subtarefas independentes, varreduras amplas (auditorias, migrações, edições
  multi-arquivo), review paralelo, ou o padrão decompor→delegar→sintetizar/verificar.
  Ative mesmo sem o usuário dizer "orquestração", "paralelo" ou "fan-out". Orquestra sempre
  no contexto principal (skill/comando), nunca dentro de um subagente.
allowed-tools: Workflow Agent Read Write Grep Glob Bash(git worktree*) Bash(bash ${CLAUDE_PLUGIN_ROOT}/validation/kg-radar.sh*)
---

# Onion Orchestration — Orquestração de Workers

Cérebro operacional para fan-out paralelo no Sistema Onion. Reconhece quando
um trabalho se decompõe em subtarefas independentes e o codifica em um script
da ferramenta nativa **Workflow**, escolhendo o padrão canônico adequado.

A coordenação roda em JavaScript e custa **0 tokens de modelo**. O teto é de
16 subagentes concorrentes e 1.000 agregados por run (teto do **Workflow** — o run).

⚠️ **Teto de SESSÃO do Claude Code MORDE ANTES do teto de run acima.** `CLAUDE_CODE_MAX_SUBAGENTS_PER_SESSION`
(default 200) soma subagentes de **toda a sessão** (conversa principal + fan-out), não por run isolado — e o
mesmo vale para `CLAUDE_CODE_MAX_WEB_SEARCHES_PER_SESSION` (default 200), o teto que já mordeu a casa. Suba o
env var ou rode `/clear` para resetar a contagem — nunca desista da orquestração por teto esgotado. Detalhe e
fontes: [agent-orchestration.md](../../../docs/knowledge-base/concepts/agent-orchestration.md) → "Primitivas
Nativas" (fonte única).

## Instruções (passo a passo)

0. **Varredura proativa de elegibilidade (DETECÇÃO ≠ EXECUÇÃO).** Ao receber **qualquer** tarefa de
   escopo amplo, **antes** de planejar execução serial, cheque os sinais de fan-out (N itens/arquivos/PRs/
   fontes independentes, varredura ampla, auditoria, migração mecânica, review multi-dimensão, padrão
   decompor→delegar→sintetizar/verificar). **Detectar e propor o fan-out é dever proativo** — não espere o
   usuário dizer "orquestração". A regra **opt-in** (gotchas) é sobre *executar* (não paralelizar por default),
   **não** sobre detectar: mesmo opt-in na execução, sinalize a oportunidade. Se positivo → proponha padrão
   + escopo + custo (e respeite o gate do `Workflow`); se a tarefa é pequena/serial/dependente → siga serial
   sem ruído. Em projeto Onion, prefira os mecanismos canônicos (esta skill → `Workflow`) ao `Agent` manual.
1. **Detectar elegibilidade de fan-out.** Há *independência real* entre as
   subtarefas? Cada uma produz seu resultado sem ler a saída da outra? Se há
   dependência de ordem ou estado compartilhado mutável, **não** paralelize —
   mantenha serial. Sinais de elegibilidade: "para cada arquivo/módulo/PR/fonte",
   varredura ampla, auditoria, migração mecânica, review multi-dimensão.
2. **Escolher 1 dos 6 padrões canônicos** (tabela abaixo) conforme a forma do
   trabalho: classificar antes de agir, fan-out→sintetizar, verificação
   adversarial, gerar→filtrar, torneio, ou loop até convergir.
3. **Autorar um script Workflow — EM ARQUIVO, nunca inline.** Escreva o script com `Write` em
   `$CLAUDE_JOB_DIR/tmp/` (ou no dir de scratch), rode o check de sintaxe, e só então invoque
   `Workflow({scriptPath})`. **Três ganhos de uma vez, e só o primeiro é óbvio:**

   ```bash
   node --input-type=module --check < <script>   # exit 1 = sintaxe quebrada
   ```

   ⚠️ **`node --check` sozinho MENTE** — trata `.js` como CommonJS e deixa passar erro de módulo
   (medido 2026-08-02: backtick perdido dentro de template literal → `--check` exit 0, `import()`
   exit 1). Use `--input-type=module`, ou extensão `.mjs`.

   - **(a) Sintaxe pega antes de gastar worker.** O modo-de-falha recorrente: o script é um
     template literal gigante, e **backtick em prosa** (hábito de markdown) o parte ao meio.
   - **(b) O script vira EDITÁVEL** — corrigir uma fase não exige reenviar tudo.
   - **(c) O script vira RETOMÁVEL** — `Workflow({scriptPath, resumeFromRunId})` replica do cache
     os agentes já concluídos. **É o ganho maior**: em 2026-08-02, dois workflows morreram com a
     sessão e sem arquivo não havia de onde retomar (um deles foi relançado em duplicata — que por
     acidente virou a medição de que descoberta precisa de N passadas).

   Use `parallel([...])` quando precisa de **barreira** (todos terminam antes do fan-in) e
   `pipeline(items, ...)` quando o fluxo corre **sem barreira** entre itens. Defina `schema` por
   worker para output estruturado e validado.
4. **Modo mutação (quando os workers ESCREVEM).** Decida partição-vs-worktree:
   workers em arquivos **disjuntos** → particione, **sem** worktree; sobreposição
   real / branches independentes → `isolation:'worktree'` por worker. No fan-in:
   colete `DiffSchema`, **detecte colisão de paths em JS**; partição limpa → aplique
   tudo numa **branch de consolidação**; colisão → **gate humano** (ou judge-panel
   p/ abordagens concorrentes). A branch consolidada entra no fluxo normal
   (`/git:flow feature finish` / `/engineer:pr` via forge) — nunca N branches
   soltas. (Playbook: KB de orquestração §7.)
5. **Verificação adversarial / judge-panel quando alto risco.** Mudanças amplas,
   irreversíveis ou de compliance ganham uma etapa de verificação por um agente
   independente (ou painel de juízes) sobre a saída agregada.
6. **Fan-in / consolidação.** Todo fan-out termina em **um único resultado**
   consolidado — nunca N saídas soltas. Agregue, deduplique e ranqueie no
   contexto principal (custo 0 tokens).
7. **`write(KG)` — o último ato (quando a orquestração PRODUZ conhecimento).** Se o fan-out gerou
   **síntese/achados/decisões** (pesquisa, auditoria, investigação, design) — e **não** só uma mutação
   de código que já termina em branch/PR — o resultado consolidado é uma **obrigação de `write(KG)`,
   não opção**. **Ordem: grafo primeiro, relatório depois** — o `.kg.yaml` é o **destino** dos
   achados estruturados; qualquer markdown de saída é **projeção** dele, nunca fonte paralela
   redigida à parte (reforça o sinal de campo de um adotante regulado, 2026-07-20: um plano que declarou "saída:
   relatório.md" como destino de uma avaliação de 70 agentes/60 achados deixou o grafo vazio — o
   grafo virou predecessor da avaliação em vez de destino dela). **Persista** a síntese
   no repo (`docs/**/research/*.md` ou local durável) — **nunca**
   a deixe só no `/tmp/.../tasks/*.output` **efêmero** do harness — **e materialize/atualize** o
   `.kg.yaml` via `/meta:kg` + `bash ${CLAUDE_PLUGIN_ROOT}/validation/kg-radar.sh` (exit 0). Fecha o ciclo
   `read(KG)→verify→act→write(KG)` ([knowledge-graph-sdaal.md](${CLAUDE_PLUGIN_ROOT}/kb/knowledge-graph-sdaal.md)
   §SSOT-as-runtime) — é o **bookend simétrico** do read(KG) (passo 0 de `warm-up`/`catch-up`/`engineer:work`).
   **Mecanismo, não conselho:** skills do harness como `deep-research` despejam em `/tmp` efêmero — a
   orquestração Onion é **dona** do leg `write(KG)`; "advice-que-depende-de-lembrar" falhou empiricamente
   (3 pesquisas perderam o write até o próprio maestro — sinal de campo 2026-07-18; ver também
   `radar-is-runtime-investigations-born-as-graph` — 8 passadas de Elenxo evaporaram em prosa e só
   viraram grafo depois, a mão). **Template canônico da fase abaixo** — para a classe FINDINGS isto é a
   **SHAPE do passo 7, não opcional**: fase final que materializa `.kg.yaml` + roda o radar + carimba
   `kg:` no doc de síntese (o marcador que o gate de integridade de frontmatter valida).
8. **Relatório ao usuário** em pt-BR: padrão escolhido, nº de workers, tier de
   modelo, budget gasto, o resultado consolidado **e onde o `write(KG)` persistiu** (path do `.md`
   + `.kg.yaml` + veredito do radar).

## Padrões → primitivas

| Padrão canônico | Primitiva | Forma | Mini-exemplo |
|---|---|---|---|
| **classify-and-act** | `agent()` → `parallel()` | classifica, depois roteia branches | 1 agente classifica o input; em seguida dispara o handler do bucket |
| **fan-out-and-synthesize** | `parallel()` + fan-in | barreira, depois síntese | N agentes auditam N arquivos; consolida num relatório |
| **adversarial verification** | `parallel()` (gerador + verificador) | gera e contesta | um agente propõe a fix, outro tenta refutá-la |
| **generate-and-filter** | `parallel()` → filtro JS | gera muitos, retém poucos | gera 10 candidatos; filtra por schema/critério |
| **tournament** | `parallel()` em rodadas | eliminação par-a-par | compara saídas 2-a-2 até 1 vencedor |
| **loop-until-done** | `loop` budget-gated | refina até convergir | refina output até passar no juízo ou estourar budget |

```javascript
// fan-out-and-synthesize: auditar N arquivos em paralelo (com barreira)
const findings = await parallel(
  files.map((f) => agent(
    `Audite ${f} contra a checklist de segurança. Liste vulnerabilidades.`,
    { schema: FindingSchema, model: "haiku" }
  ))
);
// fan-in no contexto principal (0 tokens): consolida num resultado único
return consolidate(findings);
```

```javascript
// pipeline: sem barreira entre itens — cada item flui estágio→estágio
await pipeline(
  modules,
  (m) => agent(`Extraia a API pública de ${m}.`, { schema: ApiSchema }),
  (api) => agent(`Gere os testes de contrato para esta API.`, { schema: TestSchema })
);
```

```javascript
// MUTAÇÃO partição-primeiro: workers em arquivos DISJUNTOS → sem worktree
const results = (await parallel(
  partitions.map((files) => agent(
    `Aplique a transformação SOMENTE nestes arquivos: ${files.join(", ")}. Retorne DiffSchema.`,
    { schema: DiffSchema, model: "haiku" }
  ))
)).filter(Boolean);
// detectar colisão de paths em JS (0 tokens); partição limpa → 1 branch de consolidação
const paths = results.flatMap(r => r.files.map(f => f.path));
const collided = paths.filter((p, i) => paths.indexOf(p) !== i);
if (collided.length) return gateHumano(collided, results);  // partição falhou
// sem colisão → consolida numa branch → /git:flow feature finish | /engineer:pr
```

### `write(KG)` — template canônico de fase (classe FINDINGS)

Fase **final e obrigatória** de toda orquestração que produz síntese/achados/decisões (audit, research,
investigação, design) — não é advice, é a **SHAPE** do passo 7. Pega a síntese consolidada do fan-in,
materializa o grafo, roda o radar e **carimba** o doc de síntese com `kg:` — o marcador que o gate de
integridade de frontmatter (migalhas `decision`/`error`/`learning`/`reflection`) valida quando declarado.

```javascript
// write(KG) — fase canônica final para orquestração classe FINDINGS
const synthesis = consolidate(findings);                          // já rodou o fan-in
const synthesisPath = `docs/analysis/${slug}-${today}.md`;
await write(synthesisPath, synthesisToMarkdown(synthesis));       // persiste no repo — nunca só /tmp efêmero

const kgPath = `docs/onion/graph/${slug}-${today}.kg.yaml`;
await agent(                                                      // ou: /meta:kg <slug> (mesmo efeito)
  `Modele a síntese consolidada como Knowledge Graph SDAAL (.kg.yaml): claims/evidência/decisões
   tipados, arestas SUPPORTS/REFUTES/SUPERSEDES. Escreva em ${kgPath}.\n\n${JSON.stringify(synthesis)}`,
  { schema: KgWriteSchema, model: "sonnet", effort: "medium" }
);

const radar = await bash(`bash ${CLAUDE_PLUGIN_ROOT}/validation/kg-radar.sh ${kgPath}`);
if (radar.exitCode !== 0) throw new Error(`kg-radar falhou em ${kgPath} — a fase write(KG) não fecha sem exit 0`);

// carimba o doc de síntese: o marcador do grafo E o CUSTO do run (contrato abaixo)
await editFrontmatter(synthesisPath, {
  kg: kgPath,
  run_id: runId,                 // wf_xxxxxxxx-xxx — quem produziu
  tokens: budget.spent(),        // quanto custou
  agents: agentCount,            // com quantos workers
  duration_min: elapsedMin,      // em quanto tempo
});
```

Sem este carimbo, a síntese não deixa rastro estrutural de que **nasceu no grafo** — só prosa que
"evapora" entre sessões (o próprio buraco que este template fecha).

### Contrato de frontmatter — a proveniência de custo do run

**Toda síntese de orquestração declara os quatro campos** `run_id` · `tokens` · `agents` ·
`duration_min`, no frontmatter, **na mesma unidade que o `kg:`**: um carimbo estrutural, não prosa.

**POR QUE ISTO EXISTE (medido 2026-08-06, no repo rastreado):**

```
66 arquivos citam um run de workflow · 42 run ids DISTINTOS
37 mencionam custo em ALGUM lugar        ← proximidade, não atribuição
 2 registram o custo DO RUN, atribuível  ← 4,8% dos runs
```

E a causa não era descuido: **não existia contrato nenhum**. O `run_id:` que aparece em algumas
sínteses veio de **imitação**, não de especificação — ninguém podia cumprir o que não estava escrito.

**O que se perde sem os campos:** a decisão *"vale a pena orquestrar isto ou faço serial?"* é
**exatamente** a que mais se repete nesta casa, e ela precisa de série histórica — custo por padrão,
por nº de workers, por tier de modelo. Mencionar "~1,4M tokens" três parágrafos abaixo de um `wf_` não
responde **quanto aquele run custou**; só a co-locação no frontmatter responde.

**TETO DECLARADO — a janela é PROSPECTIVA, e por isso o atraso destrói dado.** Os 40 runs sem custo
atribuível **não são recuperáveis**: os journals dos runs antigos não sobrevivem à sessão. A série
começa na próxima síntese, e cada síntese escrita sem os campos é uma medição perdida **para sempre**.
É o único item desta leva onde adiar não é adiar — é apagar.

**Emissão automática segue GATED, por desenho.** O gatilho é: se a próxima síntese nascer **sem** os
quatro campos, aí — e só aí — mecanize. Mecanizar antes é catedral pelo portão 4 (o volume ainda não
força), e a doutrina desta casa é que `fix-must-become-mechanism` vale **quando o volume justifica**.

## Model tiering — PADRÃO OBRIGATÓRIO (tier por complexidade, sempre)

> **Regra Onion — sobrepõe o default do Workflow ("omita o `model`; herda a sessão").** Toda orquestração
> Onion **atribui explicitamente `model` + `effort` por stage, conforme a complexidade da subtarefa**. Deixar
> tudo herdar o modelo da sessão é o antipadrão que o maestro sinalizou (2026-07-12): **desperdiça** modelo
> forte no fan-out mecânico e **sub-serve** o verify/juiz difícil. **Tiering não é opcional — é o default.**

| Complexidade do stage | `model` | `effort` | Exemplos |
|---|---|---|---|
| **Mecânico** — extração, classificação, varredura, transform, particionar, mapear | `haiku` | `low` | auditar 1 arquivo, extrair API, dividir partições |
| **Raciocínio médio** — análise, research por dimensão, síntese parcial | `sonnet` | `medium` | pesquisar uma dimensão, resumir achados, propor fix |
| **Difícil / alto risco** — verify adversarial, juiz/painel, síntese final, mudança irreversível/compliance | `opus` (ou o tier **Mythos-class**, hoje o Mythos-class, **só se souber que a conta tem acesso** — ver KB) | `high` (ou `xhigh`) | refutar um achado, judge-panel, consolidação crítica |

- **Opus orquestra** no nível principal (decisão, roteamento, síntese) — custo 0 tokens no JS. Os **workers**
  são tierados pela tabela; só o stage que **realmente** exige raciocínio profundo paga opus.
- **No relatório (passo 7)** declare o tier de cada fase (ex.: `scan: haiku/low · verify: opus/high`) — se
  uma fase difícil rodou barata ou uma mecânica rodou cara, é bug de tiering a corrigir.
- **Loops budget-gated**: `loop-until-done` sempre com teto via `budget` (tokens) — sem teto não há loop.
- **Prompt caching**: instruções/contexto comuns aos workers entram no prefixo cacheável, cortando custo no fan-out.
- Tiers disponíveis: **opus, sonnet, haiku** — sempre, e é o piso seguro. Acima de `opus` existe hoje um tier
  **Mythos-class** (ver KB) — use-o na
  faixa difícil/alto-risco **só se souber que a conta tem acesso confirmado**: GA de mercado **não** é
  sinônimo de liberado no plano/conta daqui. Na dúvida, fique em `opus`. Detalhe, versões e fontes: ver KB de
  orquestração → "Disponibilidade de modelos" (fonte única). Nunca ofereça modelo de outro provider.

## Gotchas

- **Fan-out só com independência real.** Dependência de ordem ou estado
  compartilhado mutável → mantenha serial. Paralelizar trabalho dependente
  corrompe resultado e desperdiça budget.
- **Mutação concorrente: partição-primeiro, worktree só p/ sobreposição.** Antes
  de paralelizar escrita, **particione por arquivos disjuntos** — sem corrida →
  **dispensa worktree** (worktree custa ~200-500ms + disco/agente). Use
  `isolation:'worktree'` **só** quando há sobreposição real ou branches
  independentes a fundir. Consolide numa **única branch** → fluxo normal
  (`/git:flow` / `/engineer:pr`). Playbook completo: KB de orquestração §7.
- **Orquestração é OPT-IN, nunca default.** Fan-out é decisão explícita. Trabalho
  serial e os workflows faseados canônicos (`engineer/*`, `product/*`)
  permanecem sequenciais — a orquestração paraleliza *dentro* de uma fase, não funde
  fases.
- **Nunca orqueste dentro de um subagente.** A orquestração mora no **nível
  principal** (skill/comando). Subagentes não disparam a orquestração — fan-out aninhado
  dentro de worker é mais caro e turvo. Por
  [architecture.md §4.2](../../../docs/meta-specs/architecture.md), `agents/* →
  commands/*` é proibido; logo **não existe** agente "worker-orchestrator".
- **Coordenação JS custa 0 tokens.** Filtros, agregação, ranqueamento e
  roteamento entre etapas rodam em JavaScript — não gaste chamadas de modelo no
  que é determinístico.
- **Fan-in obrigatório.** Todo fan-out converge num único resultado consolidado.

## Resiliência (versão confiável)

- **Passo 0 — health-check do substrato.** Antes de autorar o script, confirme que a ferramenta `Workflow` está disponível. Se não estiver, acione o **fallback serial** de forma determinística (padrão canônico: `common:prompts:orchestration-fallback`) — não dependa de o modelo "perceber".
- **Completeness critic.** Antes do fan-in final, um crítico verifica se a orquestração cobriu todo o escopo (modalidade não rodada, item não coberto) — evita lacunas silenciosas em varreduras amplas.
- **Falha parcial de worker.** `parallel()` pode retornar `null` (worker morto, timeout, ou output que falhou no `schema`). **Sempre** `.filter(Boolean)` antes do fan-in e **reporte** quantos foram descartados (`SKIP — <motivo>`). Um worker morto nunca deve silenciar nem corromper o relatório.
- **Timeout por worker.** `budget` limita tokens, não tempo. Para workers que tocam I/O externo, aplique um teto de tempo (campo nativo quando existir; senão `Promise.race` com timer) e trate o estouro como SKIP.
- **Budget em todo fan-out.** Exija `budget` por worker também em `parallel()`/`pipeline()`, não só em `loop-until-done`.
- **Run-id + trace.** Gere um identificador por run (custo 0 tokens) e inclua no relatório junto à referência do **Agent View**, para reprodutibilidade e inspeção.
- **Falhar-alto em fase vazia (não no-op silencioso).** Se uma lista de trabalho **derivada** de uma fase fica vazia com entradas não-vazias (esperava N itens para julgar/processar, obteve 0), isso é **erro de orquestração**, não sucesso. Assert `derivada.length` antes de prosseguir e `log()` o descompasso — senão a fase no-opa e o run reporta "ok" tendo verificado nada. (Incidente real: filtro de juízes comparou caminho **absoluto** do worker com **relativo** → 0 juízes; o run reportou sucesso.)
- **Correlação por chave estável, nunca por path.** Ao casar resultado-de-worker com configuração (qual julgar, qual estágio), use **label/índice** estável — não string-match de caminho, que quebra na fronteira absoluto-vs-relativo.
- **Claim de localização de dado exige read-path verificado.** Em auditoria data-driven, worker que afirma *onde um dado vive* (tabela/arquivo/cache/env) cita o **read-path no código** (`arquivo:linha` de quem efetivamente lê na operação auditada) — senão o item nasce **hipótese**, nunca nó confirmado. No fan-in, **divergência de fonte** entre workers (ou worker×banco) é **achado** (provável split-brain), não ruído. (Caso real: tabela de nome óbvio quase produziu veredito falso — o motor lia outra; padrão [verify-read-path-first](../../../docs/knowledge-base/agentic-patterns/ai-strategies/verify-read-path-first.md), sinal de campo de um adotante.)
- **Retomar a fase quebrada, não racionalizar.** Quando uma fase falha/no-opa, **corrija o script e retome** via `resumeFromRunId` (workers concluídos vêm do cache; só a fase corrigida roda) — não substitua a verificação perdida por um check **a jusante** (CI/lint) e a declare "equivalente". Um check determinístico cobre a dimensão *sintática*; verificadores semânticos cobrem *funcionalidade/qualidade* — **não são intercambiáveis**. Nomeie a dimensão não-verificada; quando possível, converta-a num **guard determinístico permanente**.
- **Síntese que não persistiu = síntese perdida (não a deixe efêmera).** Orquestração que produz conhecimento fecha em `write(KG)` (passo 7): o output do harness vive no `/tmp` e **drifta** — o SSOT nunca o viu. Antes do relatório, **persista no repo + materialize `.kg.yaml` (radar exit 0)** e **nomeie o path**. "Esqueci de salvar" é exatamente o modo-de-falha que o KG-first foi criado pra matar (sinal de campo 2026-07-18: `deep-research` do harness não persiste no KG-SSOT).
- **Claim sobre atual/emergente/popular exige verificação externa.** Worker de pesquisa que afirma algo **current/emerging/popular** — **versão · device · projeto/player · framework · tendência** — **verifica externo** (`WebSearch`/`WebFetch`) **antes** de o claim virar nó confirmado; senão nasce **hipótese**, nunca fato (mesma forma do read-path acima, com o **mundo externo** no lugar do read-path). `WebFetch` é **budget separado** do `WebSearch` (transporte esgotado ≠ desistir); ambos indisponíveis → o worker **marca "não verificado"**, não chuta. É o `verify(vivo)` do ciclo aplicado ao mundo externo (doutrina [verify-external-for-current](../../../docs/knowledge-base/concepts/verify-external-for-current.md)).

## Referências

- KB de doutrina e mapeamento de padrões: `docs/knowledge-base/concepts/agent-orchestration.md`
- Comando faceta: `/meta:orchestrate`
- Meta-spec de comandos (§10 Orquestração): `docs/meta-specs/commands.md`
- Meta-spec de arquitetura (§4.2 dependências): `docs/meta-specs/architecture.md`
- Skill relacionada: `onion-patterns` (estrutura e nomenclatura)
