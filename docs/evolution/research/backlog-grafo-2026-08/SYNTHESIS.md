# Programa "gestão de backlog" — projeção do grafo ⚙️ DERIVADO

> **Este documento é DERIVAÇÃO, não fonte.** A fonte é
> [`backlog-grafo-2026-08.kg.yaml`](backlog-grafo-2026-08.kg.yaml) (25 nós). Divergiu? **O grafo
> ganha.** Foi trazido para o repo em 2026-08-28 porque vivia num arquivo de plano **fora do
> repositório** — o caso-ouro da porosidade que o nó `C_O_PROGRAMA_SO_EXISTIA_FORA_DA_SSOT` registra.

## ⚠️ O que já foi SUPERADO neste texto (leia antes)

O plano abaixo é o estado de **28/08 às 17h**. Nas horas seguintes, medições o corrigiram em quatro
pontos — e as correções vivem no grafo, não aqui:

| o que o plano abaixo diz | o que a medição depois estabeleceu | nó |
|---|---|---|
| "aging **é** derivável — sem inventar campo" (medição B) | derivável **sim**, mas **não deve virar eixo de ordenação** (é "número mágico de prioridade", proibido); vale como **diagnóstico de uma vez** | seção *Veredito*, item C1 |
| KARMA usa "utility scoring + multi-armed bandit" para priorizar | **FALSO** — não existe no paper; veio de resumo de busca alucinado | `E_KARMA2502_CITACAO_MAB_E_FALSA` |
| "a fila cheia **não tem condutor**" | exagerado: 37 de 190 (19%) já têm commit; o hardcode é **default**, não trava | `E_A_FILA_E_PARCIALMENTE_CONDUZIDA` |
| pergunta "parado de propósito **ou** abandonado?" | dicotomia **falsa**: é *trabalhado por outro caminho*; a projeção tem 6 dias | `E_O_TRABALHO_PRECEDE_A_PROJECAO` |

Além disso: os **seis gatilhos de W2/W3**, que o plano programava para a F6, foram registrados
**cedo** (28/08) — porque `gated-work-derives-fresh` diz que o gatilho é a parte que sobrevive ao
tempo, e guardá-lo para o fim o deixava exposto num arquivo fora do repo.

---

# Gestão de backlog no Onion — programa de estudo em 3 ondas

## Context

O maestro perguntou: *"não é o momento de criar um comando também para a gestão do backlog?"* — e pediu, junto, um plano de estudo sobre o estado da arte, com fontes externas, para **usar e superar** com a maquinaria do Onion.

A pergunta nasceu no fim de uma sessão em que três mecanismos entregaram **declarações** que eu quase repassei como fato: o farol dizendo "sessão viva" (eram fantasmas), uma bancada verde que estava cega, e um `grep` que devolvia vazio sobre um arquivo com byte UTF-8 inválido. Nas três, o que separou foi medir. O backlog é o próximo candidato natural a essa família: ele **projeta** 190 itens e ninguém sabe dizer se algum já morreu.

**Correção de premissa, medida:** `/meta:backlog` **já existe** (`.claude/commands/meta/backlog.md`). Mas ele é *projeção pura* — regenera `docs/backlog.md` dos nós `status: open`, com zero subcomandos e um `--check` **advisory que sai 0 sempre**. Ele próprio declara: *"não funde nem dispara workflows faseados"*. Logo a pergunta real não é "criar um comando", é: **o que falta entre projetar e gerir — e disso, o que tem gatilho disparado hoje?**

---

## Diagnóstico — o que a maquinaria tem e o que lhe falta

### O que existe e funciona

| Peça | O que entrega |
|---|---|
| `/meta:backlog` + `kg-backlog-project.sh` | projeta `docs/backlog.md` (190 abertos · 29 grafos de 45 no escopo) |
| `kg-radar.sh` | a **régua de atenção**: `impact × confidence × statusFactor × (1 + grau)` |
| `lib/status-factor.awk` | peso por estado em **sítio único** — `drifted` 1.3 (sobe!), `unverifiable` 1.0, `done` 0.1 |
| REGRA 58 (`kg-backlog-check.sh`) | 3 catracas HARD (TETO/DONE-NU/SEM-TETO) — mas em **1 grafo só** |
| `/meta:drive` · `/meta:realign` · `/meta:kg-freshness` | conduzir · realinhar · re-verificar contra o vivo |

### As nove lacunas medidas

1. **`owner:` é código morto.** O projetor lê o campo (`kg-backlog-project.sh:64`); o corpus tem **0 ocorrências**; `/meta:realign:52` *promete* escrevê-lo e não há mecanismo. "Agrupar por owner" é, de fato, agrupar por nome de arquivo.
2. **Aging é estruturalmente impossível.** `created_at`/`opened_at`/`due` = 0 ocorrências. O único eixo temporal é `verified_at`, que mede **verificação**, não idade do item aberto.
3. **`--check` sem dente** (exit 0 sempre) — a **mesma** lacuna que o nó aberto hoje `Q_INDICE_DO_DIARIO_SEM_CATRACA` nomeou para o índice do diário. Há duas catracas-irmãs prontas para copiar: `inventory.sh` e a REGRA 19 (plugins).
4. **Assimetria drive × backlog.** O backlog projeta 190 abertos em 29 grafos; `/meta:drive` e `/meta:realign` têm `fios-abertos.kg.yaml` **hardcoded** — e esse grafo está com **0 abertos**. Não há laço cross-grafo: nada pega o topo do backlog e entrega ao driver.
5. **Sem ordem de execução.** `C_ORDEM_DO_RADAR_NAO_E_ORDEM_DE_EXECUCAO` declara: grau não-direcionado ≠ precedência, e isso é *"limite a DECLARAR, não defeito a consertar"*. `DEPENDS_ON` (443 arestas) só é guarda, dentro de um arquivo.
6. **Sem métricas nem série temporal.** A projeção é reescrita pura; a história só existe no `git log`.
7. **Sem intake/triagem de nó** e **sem WIP limit** sobre o projetado. Fechamento em lote é **proibido por doutrina** (*"quem não consegue carimbar não pode declarar feito"*).
8. **Fronteira grafo × task-manager não declarada** em nenhum L0/ADR/KB, com **zero** sincronização nas duas direções e **três noções de "backlog"** sem reconciliação (grafo · provider · `business-context` no Mini). A régua que resolveria — `architecture.md §8 regra 4`: *dono distinto × ritmo distinto × decisão distinta* — nunca foi aplicada a esse par.
9. **`docs/onion/graph/` não aparece** no layout normativo de `architecture.md §1.3`: a camada canônica do backlog não está na constituição.

### A armadilha auto-referente

Pesquisar gestão de backlog **produz itens de backlog**. A tese fundadora do próprio repo avisa: *"backlog montado de DOCUMENTO, e não de ARTEFATO, ordena itens mortos"* — medida em 15 itens revalidados, **5 já mortos (33%)**. Qualquer plano aqui tem de nascer com a cura embutida, não com a boa intenção.

---

## Fontes externas — acesso VERIFICADO, não presumido

Testei os caminhos antes de nomeá-los:

| Fonte | Estado | Nota |
|---|---|---|
| **HN Algolia API** | ✅ funciona | JSON estruturado, filtro por data/pontos — é o eixo de trajetória |
| **Lobsters** | ✅ funciona | busca por relevância |
| **arXiv** | ✅ funciona | ver achados abaixo |
| **LeadDev / newsletters** | ✅ funciona | sinal de liderança de engenharia |
| **Reddit** | ❌ **bloqueado** | `www` e `old` ambos "unable to fetch"; `site:reddit.com` na busca não devolve threads |

**Decisão do maestro:** substituir o eixo Reddit por fontes verificadas, com a razão registrada — eixo que ninguém consegue executar é eixo decorativo.

**Achados que já batem nas nossas lacunas:**

- `arXiv 2604.11378` — *From Agent Loops to Structured Graphs: A Scheduler-Theoretic Framework for LLM Agent Execution*. Bate **direto** na lacuna 5 (ordem de execução).
- `arXiv 2606.22741` — **GRADE**: grafo de dependência e execução de agentes.
- `arXiv 2511.18194` — **Agent-as-a-Graph**: agentes e ferramentas como nós co-iguais.
- `arXiv 2502.06472` — **KARMA**: Central Controller Agent com *utility scoring* + *multi-armed bandit* para priorizar — a alternativa externa à nossa régua de atenção.
- **LeadDev 2026** — modelo de confiança em **3 tiers por "blast radius"**, comparável à nossa Graduated Automation Ladder.

---

## Duas medições feitas durante o planejamento (mudam o desenho)

### A. Aging **é** derivável — sem inventar campo

A lacuna 2 dizia "estruturalmente impossível". Está errada. A data de nascimento de um nó sai do próprio git:

```bash
git log --format=%H -S"  - id: <ID>" -- <grafo> | tail -1
```

Medido: **~1s para 3 nós → ~63s para os 190 abertos**, determinístico, shell puro. O topo do backlog (`D_gate_oidc_dual`) nasceu em **2026-07-26 — 33 dias aberto**.

Isso importa por doutrina: `architecture.md:333` proíbe "número mágico de prioridade" e `fios-abertos.kg.yaml:12` avisa que mexer em `impact`/`confidence` sem medição *"é o defeito fundador da REGRA 49 cometido na autoria"*. **Aging derivado do git não toca peso nenhum** — é observação, não opinião. É o caminho que a casa aceita.

### B. O próprio movimento tem gatilho para virar `/meta:*` (nota do maestro)

Medido: `docs/evolution/research/` tem **24 temas**, e **19 deles têm a forma idêntica** — `<tema>.kg.yaml` + `SYNTHESIS.md`, dois arquivos. É o mesmo movimento fiado à mão 24 vezes.

Pelo critério de `gated-until-trigger` (*"gatilho é evidência de uso: alguém tentou fazer o trabalho e faltou"*), isso é gatilho **disparado**, não vontade. Candidato: um `/meta:study` (ou `/meta:research`) que conduza o movimento *pesquisa profunda → KG → Elenxo → síntese → doutrina → mecanismo*.

⚠️ **Mas precisa passar pelo teste do §4.2 antes**: se for "fases de um fluxo faseado retomável", é comando; se for verbos da mesma intenção sem estado retomável, é dispatcher; e se `/meta:kg novo` + a skill `onion-orchestration` já compõem o movimento, pode ser que **nada novo deva nascer** — só a composição ser nomeada. Este item entra no plano como **decisão a tomar com evidência**, não como comando pré-aprovado.

### C. Quase metade do backlog não é trabalho pendente — é pergunta parada sob controle

Medido no mesmo escopo do projetor (186 itens):

| status | n | | node_type (dos `open`) | n | % |
|---|--:|---|---|--:|--:|
| `open` | 183 | | **`question`** | **83** | **45%** |
| `drifted` | 2 | | `claim` | 54 | 30% |
| `unverifiable` | 1 | | `decision` | 35 | 19% |
| | | | outros | 11 | 6% |

**45% do backlog são `question`** — e a cauda longa delas é gated com gatilho nomeado (*"parado SOB CONTROLE ≠ órfão"*). Mas a tabela projetada tem só quatro colunas — `Atenção | Nó | Grafo | O que é` — **sem tipo, sem status, sem idade**. Quem lê não distingue *"trabalho que espera alguém"* de *"pergunta que espera um gatilho"*, e essas duas coisas exigem ações opostas.

Isso é a lacuna de gestão mais barata de fechar: três colunas derivadas de dados que já existem, em shell determinístico, sem campo novo e sem tocar peso. E os 2 `drifted` merecem destaque próprio — pelo `status-factor.awk` eles **sobem** no radar (1.3), porque alguém precisa reconciliar.

### D. O topo inteiro do backlog nasceu no mesmo dia, há 33 dias, e não se moveu

Aplicando a derivação de idade aos 15 itens de maior atenção:

| Atenção | Nó | Tipo | Idade |
|--:|---|---|--:|
| 119.0 | `D_gate_oidc_dual` | decision | **33d** |
| 64.0 | `D_spec_now_build_gated` | decision | 33d |
| 51.0 | `A_flip_steps_reversible` | artifact | 33d |
| 45.0 | `D_default_deny_routes` | decision | 33d |
| 38.3 | `A_verification` | artifact | 33d |
| 36.0 | `D_fail_closed_default` | decision | 33d |
| 35.8 | `D_D5` | decision | 30d |
| 29.3 | `C_NS1_KG` | claim | **48d** |
| … | (mais 4 decisions do mesmo dia) | | 33d |

**Doze dos quinze nasceram entre 25 e 26 de julho** — uma única rajada de planejamento — e **nenhum se moveu desde então**. Nada no topo é recente.

Essa é a assinatura de um plano-grafo **escrito uma vez e nunca conduzido**, e ela casa exatamente com a lacuna 4: `/meta:drive` está hardcoded em `fios-abertos.kg.yaml`, que tem **0 abertos**, enquanto os 190 itens reais **nunca são dirigidos por ninguém**. O driver conduz o grafo vazio; a fila cheia não tem condutor.

E é também a pergunta que a tese fundadora manda fazer: com 33 dias parados, **quantos desses já morreram?** A medição de 2026-08-08 achou 33% de itens mortos numa amostra de 15. Ninguém re-mediu desde então.

**A distribuição completa** (186 de 186 medidos, cobertura 100%, ~2 min de shell determinístico):

| faixa | itens | % |
|---|--:|--:|
| > 60 dias | 0 | 0% |
| **31–60 dias** | **113** | **61%** |
| 8–30 dias | 67 | 36% |
| 0–7 dias | 6 | 3% |
| **idade média** | **31 dias** | |

**61% do backlog passou de um mês; só 3% é fresco.** Este retrato inteiro é invisível hoje — e custou dois minutos de shell para produzir, sem tocar o schema, sem LLM, sem campo novo. É a evidência mais forte de que a lacuna de *gestão* é real e barata de fechar.

---

## Veredito sobre o comando: **não criar, e não virar dispatcher**

A passada adversarial de desenho respondeu à sua pergunta assim, e eu concordo com a evidência:

**Não é comando que falta — é catraca.** "Gestão de backlog" não tem *fronteira distinta* (o critério positivo de `onion-adr-create-vertical-2026-07.md:60-67`): o território já está repartido entre quatro mecanismos vivos — projeção (`/meta:backlog`), teto+carimbo (REGRA 58), censo/condução (`/meta:drive`) e revisão de drift (`/meta:realign`). Um comando novo **substituiria** pedaços deles em vez de compô-los.

E dispatcher também não: `commands.md:186-190` autoriza consolidar **N verbos que já existem** (o caso canônico foi 13 arquivos de GitFlow → `git/flow.md`). Aqui N=1. Inventar `intake|triage|assign|age|close|metrics` para depois "consolidá-los" **inverte a regra** — o §4.2 é critério de *subtração*, nunca licença para criar verbos. Seria a catedral do `.onion/`/v4.0 repetida por simetria.

### Das 9 lacunas: 3 com gatilho disparado, 4 gated, 2 que não devem existir

**(a) Construir agora — tudo shell determinístico, zero LLM, zero superfície nova**

| # | O quê | Por que o gatilho já disparou |
|---|---|---|
| **A1** | **REGRA nova no lint**: `docs/backlog.md` em-sync [HARD], cobrindo também `.claude/diary/index.md` | O gatilho está escrito no corpus **duas vezes**, e uma delas é um nó **aberto hoje**: `Q_INDICE_DO_DIARIO_SEM_CATRACA` prescreve literalmente *"uma checagem determinística de projeção-vs-fonte no lint, irmã da que já existe para inventário"*; e o resíduo do PR #703 classifica o backlog como *"irmão"* dessa lacuna. Não é vontade — é uso real que **já falhou** (a migalha ficou invisível e o lint passou verde). |
| **A2** | `--markdown` (stdout) + `case` de args fechado no `kg-backlog-project.sh` | **A1 é impossível sem isso**: `_gen_into` exige gerador que escreva em stdout. Confirmei: `--markdown` **ausente** aqui e presente 5–8× nos três irmãos (`inventory`, `kg-view`, `graph`). E `MODE="${1:---write}"` é **fail-open num caminho de escrita** — `--dry-run` escreveria em silêncio; o irmão `kg-drive-project.sh:31-37` já tem a cura (`*) exit 2`). É assimetria dentro de família curada, não padrão novo. |
| **A3** | Tornar a morte de `owner:` **visível** + corrigir a prosa em 3 lugares | `backlog.md:3,44` diz "agrupados por owner" e `realign.md:52` promete escrevê-lo — com **0 ocorrências no corpus**. É a mesma assinatura que originou a REGRA 58 (*"o `meta:` promete em letra grande… as três eram DISCIPLINA"*). O gatilho disparou para **honestidade**, não para o mecanismo. |

**(b) Gated — com gatilho nomeado, desenho registrado, nada construído**

| # | Lacuna | Gatilho literal |
|---|---|---|
| B1 | handoff backlog→drive (a assimetria 4) | *"a 1ª sessão em que o par grafo+nó for retipado errado da projeção para a invocação"* — e quando disparar, é **flag `--tsv` no script**, nunca subcomando, e **nunca encadeamento automático** (`drive.md:22`: auto-início é MOAT) |
| B2 | métricas / série temporal | *"uma pergunta de cadência que o `git log` não responda"*. Hoje a série seria **amostrada por atenção humana** — mediria quando alguém rodou o comando, não a fila. Métrica com viés de amostragem é pior que ausência |
| B3 | intake / triagem | **Não gatilhar**: já existe mecanismo sem comando — o teste de admissão de `fios-abertos.kg.yaml:20-22` e o radar cobrando órfão grau 0 (HARD) |
| B4 | WIP limit | **Já existe onde deve** (TETO 20 + REGRA 58). Teto sobre os 190 seria teto sobre 29 arquivos alheios, induzindo a **não abrir nós** — o oposto do que a casa quer |

**(c) Não deve existir**

- **C1 · aging como eixo** — e aqui o desenhista **derrubou a minha própria proposta**, com razão. Minha medição prova que a idade é *derivável*; não prova que deva *ordenar*. Idade como eixo de ordenação é "número mágico de prioridade", proibido por `architecture.md:333`. A casa já tem o eixo temporal com significado: `verified_at` + `--freshness-tsv`, que pergunta **"isto ainda é verdade?"** em vez de **"isto é velho?"**. Velho não é defeito; **não-verificado** é.
  → O que **fica** da minha medição é o seu papel legítimo: **diagnóstico de uma vez**, que já cumpriu sua função ao revelar que o topo do backlog não se move há 33 dias. Não vira coluna, não vira campo.
- **C2 · fechamento em lote** — MOAT, nunca. Seria *"a máquina de produzir exatamente a mentira que a REGRA 58 nasceu para impedir"*.

### Um ponto em que eu discordo do desenhista, e que a pesquisa precisa resolver

Ele gateou o B1 (handoff backlog→drive) com o argumento *"ninguém está bloqueado — o maestro lê o topo e digita"*. **A medição contradiz isso**: 61% do backlog passou de um mês e as 12 primeiras posições não se moveram em 33 dias. Ou esses itens estão parados **deliberadamente** (e então a fila precisa dizer isso, o que hoje ela não diz — não há coluna de tipo/status), ou a fila **não está sendo trabalhada por ninguém**. As duas leituras exigem ações opostas, e nenhuma é observável na superfície atual. **Esta é a primeira pergunta que a Onda 1 tem de responder.**

### Riscos que o desenho carrega

1. **`iconv` é o vetor mais provável de falso-positivo**: o projetor degrada para `cat` quando falta, produzindo render diferente → a catraca HARD acusaria **o ambiente**, não o diff. Tem de virar pré-requisito fail-loud **antes** de virar HARD. *Guarda que acusa o ambiente é pior que guarda nenhuma.*
2. **Fricção de merge**: todo PR que abre/fecha nó passa a exigir reprojeção — precedente aceito (REGRA 8 faz isso com o inventário) e mitigado entrando no `--fix`.
3. **"O core é o pior oráculo do que viaja"**: a guarda tem de escopar como a R58 e considerar `IS_DERIVED`, ou repete os 11 falsos-positivos do primeiro adotante.

---

## Conseguimos fazer isso? **Sim** — com três ressalvas mecânicas, nenhuma bloqueante

A maquinaria para *pesquisa → doutrina → comando entregue e dogfoodado no mesmo ciclo* **existe inteira e já foi exercitada nesta forma**: `docs/evolution/research/kg-read-leg-2026-08/` é o precedente exato — Elenxo orquestrado, e veredito **NÃO CONSTRUIR** com um bugfix derivado. O molde de pasta, o contrato de frontmatter, a fase `write(KG)` obrigatória, o radar como juiz determinístico — tudo já está pago.

**R-a. O laço cross-grafo não existe, e o programa NÃO pode consertá-lo como pré-requisito.** `/meta:drive` já é arg-driven: `/meta:drive docs/evolution/research/<slug>/<slug>.kg.yaml --max-nodes 4` funciona hoje. Consertar o hardcode *antes* de medir seria a lacuna 4 virando premissa em vez de achado — o programa perderia o objeto que estuda.

**R-b. O programa não pode se apoiar na maquinaria de backlog como gate** (ela é advisory). Os gates com dente a encadear: `kg-radar --integrity --schema` · `kg-realign-project.sh --check` · `kg-backlog-check.sh` · `lint-artifacts.sh` 0 HARD · `ladder-integrity-check.sh`.

**R-c. A perna externa roda amputada, e isso vai no grafo** — sem o nó registrando "Reddit inacessível, medido em 2026-08-28", a próxima sessão re-tenta em silêncio e paga de novo.

**A quarta ressalva, honesta: o gargalo não é a maquinaria, é o selo humano.** Todo flip de status de verdade, todo REFUTED, toda colheita e todo merge param para o senhor. Três ondas = três janelas de selo. **Isso é a garantia, não o defeito.**

### Uma pré-condição mecânica descoberta no planejamento

`fios-abertos.kg.yaml` está em **20/20 nós — teto CHEIO** (confirmado rodando a própria guarda: `OK BACKLOG 20/20`). Um nó novo estoura o TETO (HARD). Logo **"colher a onda anterior" não é boa prática — é pré-condição mecânica** para a Onda 1 conseguir registrar o próprio compromisso. A escassez é a *feature*.

---

## A visão MACRO — três ondas, cada uma com régua própria

Cada onda é **uma pergunta com uma régua de decisão**, não uma fatia de escopo.

| | Pergunta que responde | Régua que decide | Raio de explosão |
|---|---|---|---|
| **W1 — backlog-grafo do core** | *O que "gerir trabalho aberto" significa quando a FONTE é grafo e a projeção é pura?* | `gated-until-trigger` + Economy of Motors | o core, reversível por `git revert` |
| **W2 — fronteira com o task manager** | *Onde está a linha entre a fila epistêmica (grafo) e a fila de entrega (provider)?* | `architecture.md §8 regra 4` — **dono × ritmo × decisão distintos, os três juntos** | vertical de produto + SDAAL + todo adotante com Jira/ClickUp |
| **W3 — o adotante** | *O que VIAJA — e o que, se viajar, vira dívida em N repos?* | `gated-until-trigger` + I3 + escada graduada | N repos vendorizados, desfeito só por co-evolução |

### Por que W1 → W2 → W3, com três argumentos independentes

1. **Raio de explosão ascendente** — faça primeiro o reversível. É a mesma lógica dos 3 tiers por *blast radius* do LeadDev 2026.
2. **Dependência de evidência, mecânica e unidirecional.** A W2 **não pode** aplicar a §8 regra 4 hoje: *"ritmo distinto"* exige **medir o ritmo das duas filas**, e o eixo temporal do grafo não existe como campo. **A W1 é o que fabrica o instrumento de que a W2 depende.** Sem ele, a W2 produziria uma ADR de prosa afirmando ritmos que ninguém mediu — o modo de falha que `behavior-over-declaration` nomeia.
3. **Custo assimétrico na ordem inversa.** W2 antes declararia a fronteira contra um alvo móvel. W3 antes é o anti-padrão já nomeado no repo: *"autoria de guardrail se PUXA por caso concreto recorrente, nunca se EMPURRA por hipótese"*.

### A objeção que sobrevive (preservada, não dissolvida)

**A W1, desenhada sem saber a resposta da W2, pode construir coisa que a fronteira depois torna desperdício.** A cura não é pré-desenhar a W2 — é um **invariante de escopo checável**, gravado como nó na F0 e verificado na F3:

> **A W1 é proibida de construir qualquer coisa que pressuponha a resposta da fronteira.**
> Verbos **vedados**: atribuir responsável · data de entrega · sprint · estimativa · sincronizar com provider · notificar.
> Verbos **permitidos**: ordenar · medir · envelhecer · limitar · triar · projetar · reprovar — todos operações **sobre o grafo**, indiferentes a quem executa.

Repare: **`owner:` cai do lado vedado.** Isso não decide a lacuna 1 — a *enquadra*: ou `owner:` morre, ou fica gated até a W2. Construí-lo na W1 seria a W1 respondendo a W2 por antecipação.

---

## Onda 1 em detalhe — 7 fases

Pasta: `docs/evolution/research/backlog-grafo-2026-08/`, molde de `kg-read-leg-2026-08/`. Grafo marcado **`# kg-backlog-archive: on`** — visível no radar, **invisível** em `docs/backlog.md` (sem isso, ~25 nós novos contaminam a métrica que o programa está medindo).

| Fase | O que faz | Artefato | Gate de saída (com dente) |
|---|---|---|---|
| **F0** — o KG nasce **primeiro** | nenhuma prosa, nenhuma busca antes disto: os fatos medidos viram nós tipados com `trace:` em `arquivo:linha` e `verified_against` nomeando **o comando que mediu** | `backlog-grafo-2026-08.kg.yaml` (~25 nós, todos com ≥1 aresta) | `--integrity --schema` exit 0 · **0 UNANCHORED entre os `claim`** (claim sem `verified_against` é opinião fingindo de medição) |
| **F1** — censo do vivo | a fase que existe **por causa** da tese fundadora: nada vem de ler documento. Distribuição · **idade derivada do `git log -S`** · **taxa de mortalidade** (amostra re-verificada) · topologia dos 443 `DEPENDS_ON` via `tsort` · **vazão/lead time** derivados dos flips de `status:` · diff do `§1.3` | `MEASURES.tsv` + nós `evidence` com o comando literal | **(a)** toda claim tem one-liner que a reproduz — terceiro re-roda 3 sorteados e obtém idêntico; **(b) a taxa de mortalidade é um NÚMERO** — se não deu para medir, a onda **para**; **(c)** `--integrity` exit 0 |
| **F2** — prior-art externo (∥ com F1) | um worker por família de fonte verificada; toda fonte externa **liga-se por `SUPPORTS`/`REFUTES` a uma claim NOSSA** (o radar cobra: órfão grau 0 → HARD). Interesse da fonte anotado | nós `evidence` com URL + data de fetch, **sem `.md` lateral** | **≥1 fonte externa REFUTA (ou obriga a rebaixar `confidence` de) uma claim nossa** — varredura só-confirmatória **reprova** · o nó "Reddit inacessível" existe |
| **F3** — enquadrar opções | 4–6 candidatos como `decision`, **incluindo obrigatoriamente o nó "NÃO CONSTRUIR NADA" com o mesmo steelman** | nós `decision` + `TRACES_TO` para as medições | cada opção declara: **o id da medição que a justifica** · o degrau + `promoted_by` alcançável (senão `ladder-integrity-check.sh` reprova HARD) · o motor · **o que a falsificaria** · passa no invariante de escopo |
| **F4** — **Elenxo** (as 5 etapas) | 4 lentes **cegas entre si** (absorção/uso real · coerência doutrinária · prior-art · adversarial-de-forja) → steelman → **refutação com default `REPROVADO` na dúvida** → síntese que **preserva o dissent contra a própria conclusão** → `write(KG)` com `SUPERSEDES`/`REFUTES` | nós refutados/superados + o dissent + as arestas | **≥1 opção NOSSA refutada** (Elenxo que confirma tudo não foi Elenxo) · **contar arestas escritas, não ler a prosa** — o modo de falha `0/0/0/0` está nomeado na doutrina · o dissent existe · `--integrity` exit 0 |
| **F5** — entregar **UM** mecanismo + dogfood | exatamente uma opção sobrevivente, rodada contra o **corpus real** e no **modo de falha**; achado do dogfood é trabalho de agora (`fix → re-dogfood` no mesmo loop) | o mecanismo + bancada + resíduo R56 + linha na escada + KB/doutrina + `/meta:inventory` | rodou no real **e** no modo de falha · `lint` 0 HARD · `--integrity` exit 0 · `realign --check` exit 0 |
| **F6** — colher e selar | **colher** as 4 ondas fechadas (o teto está cheio) · **re-medir os candidatos contra o HEAD de AGORA** · escrever a onda nova citando ids do grafo de pesquisa · o que não é compromisso vira **`question` gated com gatilho literal** · migalha com `review_after` | a onda em `fios-abertos` + `SYNTHESIS.md` + diário + veredito (**ENTREGUE** ou **NÃO-CONSTRUIR-COM-RAZÃO**, ambos legítimos) | `kg-backlog-check` exit 0 · `/meta:backlog` regenerado · **todo nó gated tem o texto literal do gatilho no `label:`** · **o delta de mortalidade** medido e reportado |

**Por que exatamente UM mecanismo na F5:** entregar cinco é entregar quatro não-exercitadas — a definição de item morto vestido de script.

**A catraca anti-33%** é o passo 2 da F6: re-medir no instante do **compromisso**, não da **descoberta**. A doença fundadora foi diagnosticar num snapshot de 03/08 e propor em 08/08 itens já curados.

---

## O que fica GATED — com o gatilho literal, sem desenho

`gated-work-derives-fresh`: registra-se a **pergunta e o gatilho**, nunca a solução. Estes nascem como `question` na F6.

**Onda 2**
- `Q_FRONTEIRA_GRAFO_X_TASK_MANAGER` — *"W1 entregue E existe medição do RITMO das duas filas no mesmo período. Sem os dois números lado a lado, a §8 regra 4 não é aplicável e a ADR seria prosa."*
- `Q_SINCRONIZACAO_BIDIRECIONAL` — *"um caso real em que um item do grafo precisou virar tarefa no provider (ou o inverso), feito À MÃO ≥2 vezes, com os dois casos citáveis."* **Até lá, zero sincronização é o estado correto — o que falta é declará-lo, não construí-lo.**
- `D_NAO_PRE_DESENHAR_PROVIDER_SDAAL_DE_BACKLOG` — não-compromisso explícito: SDAAL gradua com **2º provider real**.
- **Pré-requisito barato:** o `§1.3` drifted (lista `plans/` que não existe; omite `applying/`, `discussions/`, `evolution/`, `materials/`, enquanto o `§7` proíbe diretório fora da lista). Candidato natural à entrega única da F5, **se sobreviver ao Elenxo**.

**Onda 3**
- `Q_O_QUE_VIAJA_DO_BACKLOG` — *"um adotante pedir explicitamente, OU fiar à mão um equivalente e o sinal chegar por `docs/evolution/inbox/`."* (precedente: este mecanismo nasceu do gerador PoC de um adotante).
- `Q_BACKLOG_FEDERADO` — *"≥2 adotantes com backlog-grafo vivo E um pedido de visão agregada."*
- `D_AGREGACAO_CROSS_REPO_E_MOAT` — **MOAT permanente**: ler/escrever backlog através da fronteira de repo fere I3.

**Sua nota — o movimento virar `/meta:*`:** medido, tem gatilho (24 temas, 19 com forma idêntica). Mas entra como **`question` gated**, não como comando aprovado, porque falta o teste do `§4.2`: se `/meta:kg novo` + a skill `onion-orchestration` já **compõem** o movimento, o certo é **nomear a composição**, não criar superfície. Gatilho proposto: *"a 1ª vez que uma pesquisa nova custar re-derivar o molde do zero, com o custo citável"*.

---

## Eficiência — o motor por fase

| Fase | Forma | Motor |
|---|---|---|
| F0 | serial | sonnet + shell |
| **F1** | **paralela** (partição por arquivo, read-only) | **shell majoritário**; sonnet só na amostra de mortalidade |
| **F2** | **paralela** (1 worker por família de fonte) | sonnet/medium + WebFetch |
| F3 | serial (enquadrar) + paralela (steelman) | opus no principal · sonnet nos workers |
| **F4** | paralela (lentes cegas) → barreira → paralela (refutação) → serial | sonnet → **opus/high** → opus/high |
| F5 | **serial** (mutação, um escritor, I3) | **shell** para o mecanismo; opus só na chamada |
| F6 | serial + humano | shell + selo do maestro |

**F1 ∥ F2** é o único paralelismo entre fases (interno × externo), com barreira antes da F3.

Três regras que valem mais que a tabela:
- **Se um one-liner de shell responde, não se gasta worker.** O erro de motor mais caro seria fanar 29 workers para contar o que `--open-tsv | awk` conta de graça e sem alucinar.
- **O Elenxo é caro e não é para tudo.** A própria doutrina: use-o onde *"o custo de errar é doutrinário"* — varredura e escolha reversível pedem `fan-out-and-synthesize`, "mais barato e suficiente". Só a etapa 3 e a síntese pagam opus/high.
- **SLM não tem papel aqui** — não há tarefa estreita e esquematizada nesta onda. Inventar um uso seria teatro de motor.

---

## Riscos — e a catraca de cada um

| # | Risco | Catraca mecânica |
|---|---|---|
| **R1** | **auto-referência**: cada nó que a pesquisa cria é +1 na fila que ela mede | `# kg-backlog-archive: on` no grafo de pesquisa · baseline congelada num **sha nomeado** · a F6 **reporta o delta que o próprio programa causou** (se aumentou a fila líquida, é evidência contra si) |
| **R2** | **produzir itens mortos** (a tese fundadora, replicada) — o risco central | 5 catracas em série: nascimento por medição · re-medição no **compromisso** · **TETO cheio força colher e escolher** · **uma entrega só** · o resto vira gated (item aberto apodrece; `question` sem `verified_at` envelhece sozinha no `--freshness-tsv`) |
| **R3** | confirmação disfarçada de Elenxo | ≥1 opção nossa refutada · **contar arestas, não ler prosa** |
| **R4** | construir por simetria ("Jira tem aging, logo precisamos") | toda opção cita o id da medição · `ladder-integrity-check.sh` reprova HARD sem `promoted_by` |
| **R5** | forjar a métrica | números de script reprodutível; gate é terceiro re-rodar e obter idêntico |
| **R6** | **entregar mecanismo que ninguém lê** — medido: **7 de 9** falhas do SSOT-as-runtime foram por NÃO-CONSULTA, e o que disparou consulta foi *um humano perguntando* | **viés declarado antes da F3, para poder ser refutado**: prefira a opção que põe **dente num caminho já percorrido** (um `--check` com `exit 1` no lint) sobre a que cria superfície nova a ser consultada. A F4 tem plena autoridade para derrubar essa previsão |
| **R7** | a onda virar projeto | `--max-nodes 4` · budget obrigatório · `P0.5` bloqueia passada com checkpoint pendente |
| **R8** | a W1 invadir a W2 | o invariante de escopo, checado na porta da F3 |
| **R9** | meia-vida da prosa | tudo aterrissa em **gate/script** ou **KB + migalha com `review_after`**; nada aterrissa só como parágrafo |
| **R10** | **a colheita apagar a genealogia** — colher deleta nós, e a casa prega *Aufhebung*. O `meta:` resolve por decreto ("a história fica no git") e **esse decreto nunca passou por Elenxo** | entra como **lente L2 da F4**. Se cair, o TETO muda de natureza — e isso é achado maior que qualquer mecanismo que a onda ia entregar |

### Onde este plano pode estar errado (não medido)

1. **Não medi se o senhor de fato consulta `docs/backlog.md`.** A lente L1 da F4 existe por isso: se a resposta for "não", metade das opções da F3 morre antes de nascer e o programa muda de alvo para *por que a projeção não é lida*.
2. **Assumi que a mortalidade é mensurável numa amostra barata.** Se `/meta:kg-freshness` custar caro demais por nó, o gate (b) da F1 reprovaria a onda por problema de **instrumento**, não de tese — e aí é preciso um proxy mais barato antes de reprovar.

---

## Sequência de execução

**Antes da Onda 1 — o trabalho de mecanismo que já tem gatilho** (não depende da pesquisa; são as lacunas A1–A3):

1. Resolver o **`iconv`** como pré-requisito fail-loud — sem isso a catraca acusaria o ambiente, e *guarda que acusa o ambiente é pior que guarda nenhuma*.
2. `kg-backlog-project.sh`: **`--markdown` (stdout)** + **`case` de args fechado com `exit 2`** (cópia do irmão `kg-drive-project.sh:31-37`), com **paridade byte-a-byte** entre `--markdown` e `--write`.
3. Fixtures `fixtures/kg-backlog/` + `run_backlog_selftests` — **antes** da regra (§11 é obrigatório): drift · em-dia · gerador-quebrado · saída-vazia · **arg desconhecido não muta o arquivo** · paridade de render.
4. `check_backlog_projection_sync()` **HARD** no lint, cobrindo `docs/backlog.md` **e** `.claude/diary/index.md`, com escopo R58-like + `IS_DERIVED`; entrada no `--fix` e na escada (`backlog-project-regen|STRUCTURAL`).
5. **A3**: cabeçalho honesto sobre `owner:` + corrigir a prosa em `backlog.md:3,44` e `realign.md:52`.
6. Fechar `Q_INDICE_DO_DIARIO_SEM_CATRACA` **com medição executada**, não por decreto.

**Depois — a Onda 1 de pesquisa**, F0→F6 como acima, terminando na colheita do `fios-abertos` e no registro dos gated de W2/W3 com gatilho literal.

## Verificação — como saber que funcionou

- **Mecanismo (passos 1–6):** mutar `docs/backlog.md` numa sandbox → o lint acusa HARD; `bash kg-backlog-project.sh --dry-run` → `exit 2` **e o arquivo byte-idêntico depois**; `--markdown` vs `--write` → `diff` vazio; suíte completa 0 falhas; `lint` 0 HARD.
- **Onda 1:** o veredito é publicável em qualquer direção — **um "NÃO CONSTRUIR" com razão medida é sucesso**, e há precedente (`kg-read-leg-2026-08`). O número que decide não é quantos mecanismos nasceram: é **o delta da taxa de mortalidade** entre a F1 e a F6.
