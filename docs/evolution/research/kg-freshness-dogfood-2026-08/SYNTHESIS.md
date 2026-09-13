---
title: "O /meta:kg-freshness reprovou o próprio instrumento — e só o juiz adversarial, depois de calibrado, pega a subcontagem dos workers"
date: 2026-08-29
kg: docs/evolution/research/kg-freshness-dogfood-2026-08/kg-freshness-dogfood-2026-08.kg.yaml
run_id: wf_86d657c4-3d9
runs: [wf_5261e050-96d, wf_3790d38b-6a8, wf_6aa135ec-1e2, wf_86d657c4-3d9, wf_cac2ae81-4a2, wf_56959265-e4e, wf_742e3a39-e7f, wf_26433f93-c5d, wf_86dccc06-a90, wf_832e0a15-0bf]
tokens: 3374860
agents: 60
duration_min: 45
genre: validation
mode: decision
review_after: 2026-09-28
---

# kg-freshness-dogfood · o 3º uso do comando, contra ele mesmo

> **Projeção** do grafo (33 nós, 38 arestas, radar exit 0 em `--integrity --schema`). A data vem de `meta.baseline: 2026-08-29` (o grafo não tem `meta.date`/`created`), que também é o `verified_at` dominante: dos 29 nós com carimbo, 26 têm 2026-08-29 e só os 3 selos do maestro têm 2026-08-30. Insumo lado a lado: [`calibration-gold-standard-2026-08-29.md`](calibration-gold-standard-2026-08-29.md), o padrão-ouro de 40 afirmações em 8 nós, carimbado antes do fan-out do piloto.

**Gênero e modo.** `genre: validation`, porque é o dogfood de um comando do core sobre corpus real. `mode: decision`, porque o grafo fecha em duas decisões seladas pelo maestro (B e C). A pesquisa **não** rodou pelo workflow `/onion-research`: o grafo nasceu do próprio `/meta:kg-freshness` e das passadas de revisão que vieram depois.

## Custo declarado

**Escopo do frontmatter.** `tokens`, `agents` e `duration_min` somam **só os 10 runs listados em `runs:`**. Cada um passou por dois testes: o diário de workflow (`~/.claude/projects/-home-marcio-onion-evolve/72998cdc…/workflows/wf_*.json`, campos `workflowName`, `totalTokens`, `agentCount` e `durationMs`, lidos um a um) nomeia trabalho deste grafo, e o grafo cita o run. O `run_id` aponta o run de medição.

A duração é a soma do tempo dos runs (45,3 min), **não** a parede da sessão. `agents: 60` conta os agentes que as 3 tentativas falhas dispararam (0+8+8, que morreram sem gastar token). Nos runs que gastaram tokens foram 44.

| Passada | Run | `workflowName` no diário | Tokens | Agentes | Duração do run |
|---|---|---|---|---|---|
| 1ª tentativa, falhou (`bash is not defined`) | `wf_5261e050-96d` | kg-freshness-m2-bridge-logto | 0 | 0 | 0,06 s |
| 2ª tentativa, falhou (`parallel()` com promises) | `wf_3790d38b-6a8` | kg-freshness-m2-bridge-logto | 0 | 8 | 0,19 s |
| 3ª tentativa, 400 `allOf` 8× (status `completed`, 0 tok) | `wf_6aa135ec-1e2` | kg-freshness-m2-bridge-logto | 0 | 8 | 1,2 s |
| Medição (fan-out) | `wf_86d657c4-3d9` | kg-freshness-m2-bridge-logto | 548.677 | 8 | 4,86 min |
| Juízo adversarial dos workers | `wf_cac2ae81-4a2` | kg-freshness-judge-adversarial | 283.808 | 4 | 3,70 min |
| Revisão da REGRA 56 (PR aberto carrega RESÍDUO da passada adversarial) sobre este grafo | `wf_56959265-e4e` | adversarial-kg-freshness-dogfood | 436.488 | 3 | 12,29 min |
| Sonda "a API aceita a cura?" | `wf_742e3a39-e7f` | probe-schema-if-then-topo | 35.842 | 1 | 4,7 s |
| Elenxo sobre a cura | `wf_26433f93-c5d` | elenxo-kg-freshness-cura | 451.837 | 5 | 11,88 min |
| Piloto calibrado (workers) | `wf_86dccc06-a90` | kg-freshness-calibration-pilot | 1.144.042 | 16 | 7,66 min |
| Piloto calibrado (juízes) | `wf_832e0a15-0bf` | judge-calibration-pilot | 474.166 | 7 | 4,79 min |
| **Soma dos runs provados** | 10 runs | — | **3.374.860** | **60** | **45,3 min** |

Ficaram **fora da soma**, cada um com o motivo:

| Item | Número | Por que não entra |
|---|---|---|
| `wf_d68dc607-bce` | 300.614 tok · 2 agentes · 14,2 min | O diário se chama `adversarial-drive-batch3` e o resumo diz *"Passada adversarial (REGRA 56) sobre o lote 3 do drive em fios-abertos"*. O script mira `docs/onion/graph/fios-abertos.kg.yaml` e cita esta pasta só como "contexto da mesma sessão (já mergeado)". **Não é passada deste grafo**: é outro PR, e o grafo o cita no `trace` de `C_JUIZ_SEM_PADRAO_OURO` como mais um run onde achados do juiz foram re-medidos |
| Resíduo `fix-kg-freshness-primeiro-dogfood.md` | `tokens: 1853000` · `duration_min: 95` | Número da **sessão** da branch, não do run de revisão. O run é o `wf_56959265-e4e` acima, com 436.488 |
| Resíduo `fix-kg-freshness-schema-cure.md` | 451.837 · 12 min | Bate com o diário do `wf_26433f93-c5d`; já está na soma |
| Resíduo `feat-kg-freshness-calibration-pilot.md` | 1.618.208 · 13 min | Bate com a soma dos dois diários do piloto (1.144.042 + 474.166); já está na soma |
| Resíduo `feat-pilot-sealing-batch.md` | 0 · 25 min | Lote de selagem sem run de workflow (commit `d761c963`) |
| Custo do contexto principal (autor) nas sessões | — | NÃO MEDIDO: nenhum diário de workflow o registra |
| Resíduo `chore-kg-freshness-m2-reseal.md` | 67.286 tok, 2026-08-23 | Passada anterior a este grafo |

## Veredito

**O comando que existe para reprovar carimbo sem medição foi usado pela 3ª vez e reprovou o próprio instrumento.** O `KgReverifySchema` foi recusado pela API 8 de 8 vezes (`allOf` no topo). As três guardas do schema nunca tinham rodado desde 2026-08-12 (`E_ALLOF_RECUSADO_PELA_API`). Enquanto isso, a guarda estrutural imprimia `OK ✓` sobre o schema inutilizável (`E_GUARDA_ESTRUTURAL_APROVA_O_INUTILIZAVEL`).

A cura foi medida pelos dois lados antes de ser selada:

- **Equivalência:** a cadeia `if`/`then`/`else` com **raiz na cobertura** equivale ao `allOf` original em 15/15 casos. A cadeia "natural", com raiz no `verdict`, diverge em 2 (`E_EQUIVALENCIA_POR_TABELA_VERDADE`).
- **No repo:** a cura entrou no repositório com uma catraca FORMATO-RECUSADO-PELA-API (`E_SCHEMA_CURADO_E_CATRACA_NO_REPO`).
- **Em produção:** a barragem foi observada, com 5/5 rejeições de um CONFIRMED sem `blocked_by` (`E_BARRAGEM_DO_SCHEMA_MEDIDA_EM_PRODUCAO`).

Sobre o corpus, **nenhum dos 8 nós de maior atenção do grafo M2 alcançou um CONFIRMED que sobrevivesse ao juiz** (`E_ZERO_DE_OITO_SOBREVIVE`). Três foram julgados falsos e cinco caíram por inverificabilidade. O modo de falha dominante do worker tem nome: **encolher o denominador**. A subcontagem foi de ~48% no M2 (`C_WORKERS_ENCOLHEM_O_DENOMINADOR`) e de 44% fora dele, contra o ouro (`E_CALIBRACAO_DO_JUIZ_MEDIDA`).

Quem pega a subcontagem é o juiz adversarial, não o schema (`C_O_JUIZ_ADVERSARIAL_E_A_CURA_DA_SUBCONTAGEM`). O juiz foi calibrado contra o ouro:

| Medida do juiz | Resultado |
|---|---|
| Falso-positivo na acusação | 20% |
| Contagem abaixo do ouro (SUB) | 0/7 |
| Contagem exata | 4/7 |
| Aprovações | 1/7 |
| Fabricação detectada | pegou um `ls` curado |

Com esses números, o maestro selou em 2026-08-30 duas decisões:

- **B:** o juiz vira etapa fixa, e o veredito continua proposta (`D_B_JUIZ_FIXO_VEREDITO_PROPOSTA`).
- **C:** censo dos ~190 itens, com juízo escopado aos CONFIRMED e execução em lotes retomáveis (`D_C_CENSO_190_JUIZ_EM_CONFIRMED`).

## Achados por tema

### 1. O instrumento: schema, guarda e cura

- `E_ALLOF_RECUSADO_PELA_API`: erro literal `400 tools.custom.input_schema: input_schema does not support oneOf, allOf, or anyOf at the top level`, 8×, no run `wf_6aa135ec-1e2`. A 1ª versão do nó apontava o run errado, e a revisão corrigiu.
- `E_GUARDA_ESTRUTURAL_APROVA_O_INUTILIZAVEL`: `kg-reverify-schema-check.sh` mede a forma, não a aceitação. O próprio cabeçalho do script declarava esse teto desde 12/08.
- `C_A_GUARDA_BLOQUEIA_A_PROPRIA_CURA`: **refutado**. Só a variante destrutiva tinha sido medida. `E_CURA_MEDIDA_NOS_DOIS_LADOS` o refuta (aresta REFUTES).
- `E_CURA_MEDIDA_NOS_DOIS_LADOS`: **superseded** por `E_EQUIVALENCIA_POR_TABELA_VERDADE`. Media aceitação e forma, nunca a barragem.
- `D_GUARDAS_MIGRAM_PARA_O_FANIN` → `D_CURA_E_RESTRUTURAR_O_SCHEMA` → `E_SCHEMA_CURADO_E_CATRACA_NO_REPO`: duas propostas seguidas, ambas superseded. A primeira foi refutada por `E_SO_A_GUARDA_1_DISPAROU`: foi uma única guarda disparando duas vezes, e a comparação `measured × total` é cega ao encolhimento do denominador. A segunda caiu porque "nada mais precisa mudar" era falso: a guarda precisou ganhar catraca.
- `E_ELENXO_REPROVOU_AS_TRES`: as três sub-decisões (A, B, C) tinham evidência colhida só pelo lado que aceita. Duas objeções caíram por medição e duas viraram nós: `C_JUIZ_SEM_PADRAO_OURO` e `C_JUIZ_E_CENSO_SAO_UMA_DECISAO`.
- `E_BARRAGEM_DO_SCHEMA_MEDIDA_EM_PRODUCAO`: a omissão de `blocked_by` foi **induzida por um comentário no próprio schema**. O comentário foi corrigido no mesmo PR.

### 2. O worker e o juiz

- `C_WORKERS_ENCOLHEM_O_DENOMINADOR`: nos 4 nós com cobertura TOTAL, os workers contaram 14 afirmações e os juízes 27. Em 3 de 4, a contagem foi julgada desonesta.
- `C_JUIZ_SEM_PADRAO_OURO`: com 4/4 reprovações e sem padrão-ouro, não dava para distinguir "o juiz está certo" de "o juiz sempre reprova". Isso barrou o juiz fixo até a calibração.
- `E_CALIBRACAO_DO_JUIZ_MEDIDA`: somas de worker 19, juiz 44 e ouro 34, com o ouro sob sha256 `c975fce6…`. Teto declarado: n=7, um único contador, e o juiz conta a mais por granularidade.
- `D_JUIZ_CALIBRACAO_GATED`: **done** em 2026-08-30, executado pela calibração acima.
- `C_JUIZ_E_CENSO_SAO_UMA_DECISAO`: B e C estão acopladas. Com o juiz opus/high fixo, o censo custaria 26,5M; sem ele, 13,0M. O próprio nó declara que o número serve para exibir o acoplamento, não para orçar.
- `E_ACHADOS_DE_CONTEUDO_DO_PILOTO`: em 4 grafos fora do M2 foram 12 CONFIRMED, 2 DRIFTED e 1 REFUTED. Os não-confirmados foram 20%, contra 100% no topo do M2. O `EN_MAESTRO` foi refutado com o juiz aprovando a refutação. Nada foi carimbado nos grafos-alvo.
- `D_B_JUIZ_FIXO_VEREDITO_PROPOSTA` e `D_C_CENSO_190_JUIZ_EM_CONFIRMED`: **done**, selados em 2026-08-30. A decisão C declara que o censo completo (~19-24M tok) não cabe numa sessão.

### 3. O corpus medido: grafo M2 (bridge + Logto)

- `E_ZERO_DE_OITO_SOBREVIVE`: vereditos brutos de 3 CONFIRMED, 3 DRIFTED e 2 UNVERIFIABLE. As guardas rebaixaram 2, e o juiz reprovou 4/4. Correção da revisão: 4 dos 8 nós **tinham** `reverify_note` de 2026-08-23.
- `E_ADMIN_STATS_NAO_EXISTE_MAIS`: a rota `/admin/stats`, citada como prova em dois nós do M2, dá 404 e não existe no código-fonte.
- `E_CONSOLE_LIGADO_DESDE_08_10`: `C_console_not_the_path` diz "desligado", mas o console está ligado desde 2026-08-10. O drift já estava em `reverify_note` e o `status` nunca mudou.
- `C_TABELA_DE_SELAGEM_SEM_CELULA_PARA_DRIFT_PARCIAL`: falta a célula "parcialmente medido, e o que se mediu DRIFTOU". Hoje o drift medido é descartado pelo rebaixamento a UNVERIFIABLE.
- `C_READONLY_CONFUNDE_POST_COM_MUTACAO`: 2 de 4 nós parciais travaram em "precisa de POST". Pedir um token por `client_credentials` é leitura semântica, não mutação.

### 4. A skill de orquestração

- `E_TEMPLATE_WRITE_KG_CHAMA_PRIMITIVA_INEXISTENTE`: `bash`, `write` e `editFrontmatter` não existem no runtime do Workflow. O defeito está em 3 arquivos: `.claude/` e duas cópias de plugin.
- `E_PARALLEL_EXEMPLOS_CANONICOS_QUEBRADOS`: dois exemplos passam promises para `parallel()`, também em 3 arquivos.
- `C_SKILL_DE_ORQUESTRACAO_E_COPY_PASTE_MORTO`: os blocos de código da skill nunca foram executados como estão escritos.

### 5. Identidade e federação

- `E_ESPELHO_CADUCO_DO_SSOT_DA_FEDERACAO`: há dois `members.yaml` na máquina, com 9 e 8 adotantes. A divergência entre dois workers da mesma rodada revelou isso.
- `C_PROJETOR_DE_IDENTIDADE_SEM_ANCORA`: `logto-provision.sh` resolve o SSOT pelo diretório de quem chama. A correção da revisão reclassificou isso: não foi a causa do 9-vs-8, é um risco **latente**, e o `--enroll` falha fechado.

## NÃO-VERIFICADOS

Derivados do grafo, sem re-medição nesta síntese. Critério: status `open`, `question`, `refuted` ou `superseded`; nó sem `verified_at`; ou `confidence` ≤ 0,8. Nenhum nó está `unverifiable`. São **9 itens**.

| # | Nó | Por que entra | Estado no grafo |
|---|---|---|---|
| 1 | `C_TAMANHO_DO_NO_PREVE_VERIFICABILIDADE` | question `open`, confidence 0,6 | Rebaixado de claim: os números originais usavam os denominadores subcontados. Sobrevive só a direção. Gatilho: recontagem por juiz nos 8 nós |
| 2 | `C_PROJETOR_DE_IDENTIDADE_SEM_ANCORA` | claim `open` | Risco latente medido (grep `BASH_SOURCE`/`SCRIPT_DIR` = 0). A cura tem gatilho nomeado e não está registrada |
| 3 | `Q_REVERIFY_NOTE_E_PROSA_GRAMPEADA` | question `open`, sem `verified_at`, confidence 0,8 | O radar deve reprovar `reverify_note` sem flip de `status`? Gatilho: decisão sobre a tabela de selagem |
| 4 | `Q_CENSO_DOS_63_CORTADOS` | question `open`, sem `verified_at`, confidence 0,8 | A taxa de 8/8 vale fora do topo? `D_C_CENSO_190_JUIZ_EM_CONFIRMED` diz que ela se responde **dentro** do censo |
| 5 | `C_A_GUARDA_BLOQUEIA_A_PROPRIA_CURA` | `refuted` | Derrubado por `E_CURA_MEDIDA_NOS_DOIS_LADOS`; a posição fica no grafo |
| 6 | `D_GUARDAS_MIGRAM_PARA_O_FANIN` | `superseded`, sem `verified_at` | Refutado por `E_SO_A_GUARDA_1_DISPAROU` |
| 7 | `E_CURA_MEDIDA_NOS_DOIS_LADOS` | `superseded` | Superado por `E_EQUIVALENCIA_POR_TABELA_VERDADE`: media aceitação, não barragem |
| 8 | `D_CURA_E_RESTRUTURAR_O_SCHEMA` | `superseded`, sem `verified_at` | Superado por `E_SCHEMA_CURADO_E_CATRACA_NO_REPO`: "nada mais precisa mudar" era falso |
| 9 | `C_JUIZ_SEM_PADRAO_OURO` | confidence 0,8 | Continua `confirmed`, mas `E_CALIBRACAO_DO_JUIZ_MEDIDA` executou a calibração que ele dizia faltar, e `D_JUIZ_CALIBRACAO_GATED` está `done`. É verdade datada, sem flip nem aresta SUPERSEDES que registre isso |

## valeu-a-pena

**Grafo inteiro: 3.374.860 tokens ÷ 33 nós ≈ 102.268 tokens por nó.** O numerador é só a soma dos 10 runs provados pelos diários. Não entra o contexto principal do autor, que não foi medido. Então a razão é um **piso**, não o custo total.

Por passada, usando os nós que eu contei a cada commit (`git show <sha>:<grafo> | grep -c '^  - id:'`) e os tokens dos diários:

| Passada | Commit | Nós acumulados | Nós novos | Runs (diário) | Tokens | Tokens ÷ nó novo |
|---|---|---|---|---|---|---|
| Tentativas + medição + juízo | `ec4c8442` | 17 | 17 | `wf_5261e050-96d`, `wf_3790d38b-6a8`, `wf_6aa135ec-1e2` (0 cada), `wf_86d657c4-3d9`, `wf_cac2ae81-4a2` | 832.485 | ≈ 48.970 |
| Revisão da REGRA 56 (PR aberto carrega RESÍDUO da passada adversarial) + sonda | `ed88dbfc` | 22 | 5 | `wf_56959265-e4e`, `wf_742e3a39-e7f` | 472.330 | ≈ 94.466 |
| Elenxo | `e5a26a3c` | 28 | 6 | `wf_26433f93-c5d` | 451.837 | ≈ 75.306 |
| Piloto calibrado | `a5b6ab6f` | 31 | 3 | `wf_86dccc06-a90`, `wf_832e0a15-0bf` | 1.618.208 | ≈ 539.403 |
| Lote de selagem | `d761c963` | 33 | 2 | nenhum | 0 | 0 |

Como atribuí a sonda: ela entra na passada de revisão porque o resíduo `fix-kg-freshness-primeiro-dogfood.md` a usa para derrubar `C_A_GUARDA_BLOQUEIA_A_PROPRIA_CURA`.

A régua por nó novo **subestima** a revisão e o piloto. A revisão também reescreveu nós existentes (36 achados). O piloto também entregou o padrão-ouro e vereditos propostos para 4 outros grafos, que ficaram fora deste arquivo.

## Backlog

Nós `open` que pedem ação:

- `C_PROJETOR_DE_IDENTIDADE_SEM_ANCORA`: ancorar `logto-provision.sh` ao próprio repo (`BASH_SOURCE` → `git rev-parse --show-toplevel`) e recusar raiz divergente.
- `Q_REVERIFY_NOTE_E_PROSA_GRAMPEADA`: aguarda a decisão sobre a célula de drift parcial. As duas se respondem juntas.
- `Q_CENSO_DOS_63_CORTADOS`: fecha dentro da execução em lotes de `D_C_CENSO_190_JUIZ_EM_CONFIRMED`.
- `C_TAMANHO_DO_NO_PREVE_VERIFICABILIDADE`: recontagem por juiz nos 8 nós para virar claim.

Claims `confirmed` que **prescrevem mudança** e para os quais o grafo não registra nó de cura. O repo não foi conferido nesta síntese:

- `C_TABELA_DE_SELAGEM_SEM_CELULA_PARA_DRIFT_PARCIAL`: a célula que faltava na tabela de selagem.
- `C_READONLY_CONFUNDE_POST_COM_MUTACAO`: a cláusula READ-ONLY deve distinguir "muda estado durável" de "usa verbo POST".
- `C_SKILL_DE_ORQUESTRACAO_E_COPY_PASTE_MORTO`: curar os exemplos da skill nos 3 arquivos.

**Revisita:** `review_after: 2026-09-28`, pela cadência "ferramenta 30d" da REGRA 67 (Grafo de pesquisa com REVISITA carimbada (meta.review_after)), contada a partir de 2026-08-29. O tipo dominante é o comportamento de uma ferramenta: o comando, o schema aceito pela API e o runtime do Workflow. A data foi gravada em `meta.review_after` do grafo. Em 2026-09-13 a revisita **não** está vencida.
