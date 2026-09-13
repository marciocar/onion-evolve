---
title: "O Onion não supera por contexto nem por prova: supera por industrializar a reincidência — e o acoplamento que declarava (SendMessage) nunca foi exercido"
date: 2026-08-16
kg: docs/evolution/research/claude-code-2.1-onion-2026-08/claude-code-2.1-onion-2026-08.kg.yaml
run_id: "NÃO MEDIDO"
tokens: "NÃO MEDIDO"
agents: "NÃO MEDIDO"
duration_min: "NÃO MEDIDO"
genre: decision
mode: decision
review_after: 2026-09-15
---

# Claude Code 2.1.x × Onion — onde mora a superação

> **Projeção** do grafo (35 nós, 44 arestas, radar exit 0). A prosa deriva do `.kg.yaml`; em divergência, vale o grafo. Os números aqui são os medidos **em 2026-08-16** (e em 2026-08-17 para os 4 nós da adoção de campo). Esta projeção não re-mediu nada. A única re-medição que o grafo registra é a de `E_O_GATE_DO_ADOTANTE_NASCE_REPROVADO_POR_PASSIVO_ALHEIO`, re-verificado em 2026-09-09 pelo R0 do `/meta:kg-freshness`.

**Origem das datas.** `date` vem de `meta.date` (= `meta.baseline`, 2026-08-16); 31 dos 35 nós têm `verified_at: 2026-08-16`. Exceções: 3 nós com `verified_at: 2026-08-17` (`E_A_GUARDA_DE_PROJECAO_CONFIAVA_NA_METADE_SEGURA`, `D_INVARIANTE_PROJETADO_IGUAL_AO_SLUG_COM_ISENCAO_NO_DADO`, `D_REGENERAR_BASELINE_POR_DESCOBERTA_NAO_POR_LISTA`) e 1 nó criado em 08-17 e re-carimbado em 2026-09-09 pelo R0 do `/meta:kg-freshness` (`E_O_GATE_DO_ADOTANTE_NASCE_REPROVADO_POR_PASSIVO_ALHEIO`).

**Revisita.** `meta.review_after` **não existia** no bloco `meta:` e foi carimbado nesta projeção: **2026-09-15**, cadência *ferramenta 30 d*.

**Isto é EXCEÇÃO declarada à REGRA 67 (Grafo de pesquisa com REVISITA carimbada (meta.review_after)).** A regra pede a cadência do **tipo dominante** (`.claude/skills/onion-research/SKILL.md:50`). Pela minha classificação (não é campo do grafo), o dominante é **medição interna** (23 de 35 nós); há também 6 nós de plataforma e 6 de mercado/comunidade. Não usei a cadência do dominante, por dois motivos:

- A tabela de cadências da regra (ferramenta 30 d · modelos 45 d · mercado 90 d · benchmark 120 d · doutrina 12 m) **não tem classe para medição interna**. O vizinho mais próximo seria doutrina, 12 m (2027-08-16).
- A pergunta que abriu o grafo é **troca de versão** (2.1.232 → 2.1.233), e as premissas de plataforma que o CLAUDE.md usa para justificar o acoplamento envelhecem a cada release. São elas: o `exit 2` de hook sob `bypassPermissions`, a superfície de hooks e os Task tools. Doze meses deixariam essas premissas sem revisita enquanto o binário andou 37 patches em 4 semanas.

A exceção é minha e fica aqui para ser contestada. Se o maestro preferir a regra literal, a data vira 2027-08-16. **A data não venceu** (faltam 2 dias em 2026-09-13), **mas a versão já andou:** o binário instalado hoje é o 2.1.270, 37 patches depois do 2.1.233 do título.

## Custo declarado

| Item | Valor | Onde procurei |
|---|---|---|
| Tokens | `NÃO MEDIDO` | `meta` do grafo (sem campo de custo); pasta (só o `.kg.yaml`); corpo dos 9 commits que tocaram a pasta nesta branch (`6850818d`, `db2f21bf`, `caedc046`, `614e35b6`, `49f12f42` em 08-16; `61a950ee`, `34ce28f6` em 08-17; `be29ab00` em 09-09, gêmeo de `61fc1a74` noutra branch; `931ecd34` em 09-11); `git log --all -S claude-code-2.1-onion`; grep do slug em `docs/`. O resíduo R56 do PR #616 (`docs/evolution/review/docs-claude-code-2-1-audit.md`) declara `tokens: 0`. Não usei o valor: o campo tem de ser numérico por guarda (`review-artifact-check.sh`), e uma passada adversarial que mediu 47 scripts e 63 grafos não custa zero, então o 0 só preenche o campo. |
| Agentes | `NÃO MEDIDO` | O grafo e o resíduo citam "Elenxo dedicado" + "2 frentes de pesquisa externa" + sessões headless de dogfood (A/B de 3 casos), mas nenhum lugar dá uma contagem de agentes. |
| Duração | `NÃO MEDIDO` (run inteiro) | Única duração atribuível é **parcial**: `duration_min: 40` no resíduo do PR #616, que cobre só a passada adversarial do 1º commit. O run seguiu por mais 6 commits até 2026-08-17 (7 no total até essa data). |
| run_id | `NÃO MEDIDO` | O único `wf_` no grafo (`wf_5b2f274e-83d`) é o R0 de re-verificação de 2026-09-09. Ele cobriu 16 nós de vários grafos e só 1 deste, então não é o run que criou o grafo. |

## Veredito

**A tese inicial foi refutada e substituída.** `Q_ONDE_MORA_A_SUPERACAO` ("o Onion é o único que trata conhecimento como artefato verificável, KG como SSOT de runtime") está `refuted`. Duas arestas `REFUTES` a derrubam:

- `E_ELENXO_DERRUBOU_METADE_DA_TESE`: o radar valida o grafo contra si mesmo; nenhum dos 7 hooks lê `.kg.yaml`; Cruxible e AsDecided atacam a mesma tese.
- `E_A_CASA_JA_TINHA_REFUTADO_A_PERNA_DA_LEITURA`: medição da própria casa de 2026-08-02, com 7/9 falhas por não-consulta e veredito NÃO CONSTRUIR.

A substituta é `D_SUPERACAO_REESCRITA_REINCIDENCIA` (`done`, ratificada pelo maestro e materializada em `docs/analysis/onion-adr-superacao-reincidencia-2026-08.md`): *o mercado otimiza CONTEXTO; os concorrentes de nicho otimizam PROVA; o Onion otimiza REINCIDÊNCIA*. Cada defeito real vira guarda determinística que roda fora da janela de contexto e é exercitada por bancada. A **perna de LEITURA** fica declarada como buraco aberto, nunca como capacidade entregue.

**O achado que o CLAUDE.md cita** (`E_INVERSAO_O_QUE_REPROVA_E_AGNOSTICO`, `E_ACOPLAMENTO_DECLARADO_E_NAO_EXERCIDO`):

- `grep -rn SendMessage .claude --include=*.md --include=*.sh --include=*.json` devolveu **ZERO** na maquinaria viva. A capacidade que justificou abandonar o agnosticismo em 2026-05-18 era argumento, não uso.
- Massa medida: **26.596 linhas de shell agnóstico** (perímetro declarado: validation + hooks + utils) contra **52.655 linhas de markdown acoplado** (commands + agents + skills). Leitura do nó: *100% do que REPROVA é agnóstico; 100% do que ACONSELHA é acoplado*.
- Consequência registrada no nó: **não** é motivo para voltar ao agnosticismo, e sim para parar de anunciar uma dependência que não existe. O único acoplamento que compra o que se pagou é o `exit 2` determinístico de hook, que vale inclusive sob `bypassPermissions`. Isso foi executado no CLAUDE.md (`E_A_LISTA_DO_QUE_PARAR_ENCOLHEU_AO_SER_MEDIDA`).

## Achados por tema

### 1. O que a plataforma mudou (2.1.211 → 2.1.233)

- **Hooks multiplicaram** (`E_CONTRATO_DE_HOOKS_EXPLODIU`): cerca de 30 eventos, contra os cerca de 8 clássicos.
  - Há handlers `http`, `mcp_tool`, `prompt` e `agent`.
  - Desde 2.1.214, `exit 2` com JSON inválido bloqueia.
  - Foi confirmado no ELF instalado (2.1.233), com controle.
- **BREAKING medido por dogfood** (`E_TASK_TOOLS_SOMEM_EM_OPUS_5`): Task/todo tools estão desligados por padrão em Opus 4.8+.
  - O framework não depende deles: zero instruções em `.claude/{commands,agents,skills}`.
  - Religar é decisão do maestro.
- **Semântica de permissão** (`E_ASSIMETRIA_DE_PERMISSAO_DIR`): `dir/**` passou a valer só `<cwd>/dir` em allow e em `if:` de hook, e continua em qualquer profundidade em deny/ask. O core passou ileso por acidente de estilo.
- **Absorção** (`E_PLATAFORMA_ABSORVEU_DISTRIBUICAO_E_ISOLAMENTO`): plugin `archive` com pin SHA-256, self-hosted runner, credential masking, fix de isolamento de worktree, nesting de subagentes 1→3.
- **Fragilidade herdada** (`E_FRAGILIDADE_HERDADA_DA_PLATAFORMA`, com apoio de `E_TASK_TOOLS_SOMEM_EM_OPUS_5` e `E_ASSIMETRIA_DE_PERMISSAO_DIR`): guarda que só existe como hook é guarda que a plataforma pode apagar. A redundância lint-no-CI + hook local vira requisito.

### 2. Mercado e comunidade

- **Fragmentação, não absorção** (`E_FRAGMENTACAO_NAO_ABSORCAO`): busca por trajetória desde 2026-05-01 achou ponytail (~104k★), loop-engineering, omnigent e gsd-core, além da convenção `.agents/` cross-ferramenta.
- **Memória em 3 camadas virou convenção** (`E_COMUNIDADE_MEMORIA_3_CAMADAS`, issue #34556): ter camadas deixou de ser diferencial.
- **Dor #1 é contexto e custo** (`E_DOR_DOMINANTE_E_CONTEXTO_E_CUSTO`), com uma categoria de ferramentas-parasita de compressão.
- **Concorrência de posicionamento em NS1** (`E_CONCORRENTE_DE_POSICAO_COMPANY_BRAIN`): Hyper (YC P26) se apresenta como "company brain for agentic development".
- **Reddit inalcançável**, declarado como lacuna (`E_REDDIT_INALCANCAVEL_LACUNA_DECLARADA`).

### 3. O que parar: a lista encolheu ao ser medida

- **Leia `D_O_QUE_PARAR_DE_FAZER` junto com `E_A_LISTA_DO_QUE_PARAR_ENCOLHEU_AO_SER_MEDIDA`** (aresta `CONSTRAINS`). O rótulo do primeiro lista 5 itens, mas **3 foram REFUTADOS ao medir antes de apagar**:
  1. Empacotamento: o nativo não faz projeção.
  2. Curar o MEMORY.md: o nativo *mantém* o arquivo, o Onion *testa* o conteúdo.
  3. Scaffolding: os `setup-*` são específicos.
- **Só 2 foram executados:** parar de anunciar "KG como SSOT de runtime" e parar de justificar o acoplamento por `SendMessage`.
- *Fonte externa a este grafo:* um parecer posterior já leu o nó de proposta sem ler o de resultado (`docs/evolution/research/maestro-vivo-2026-08/data/f2-confronto.json`). É o erro que esta nota existe para evitar.

### 4. A armadilha da facilidade (perna de leitura)

- **A superfície nova de hooks torna CONSTRUÍVEL** a cura refutada em 2026-08-02. Construir porque ficou fácil seria acoplar por conveniência (`Q_GATE_REABRE_POR_DOGFOOD_NAO_POR_CHANGELOG`).
- **O gatilho de reabertura (dogfood) rodou:** 3/3, o veredito injetado **não mudou a resposta**, e a sessão sem hook foi ao grafo sozinha (`E_DOGFOOD_DA_PERNA_DE_LEITURA_3_DE_3_NAO_MUDOU`). O NÃO CONSTRUIR sobrevive.

### 5. O corpus transfere? E o gate do adotante

- **A maquinaria transfere; a prática quase não** (`E_O_CORPUS_NAO_TRANSFERE_E_METADE_DA_CULPA_E_NOSSA`, 11 membros medidos no disco):
  - O grafo aparece em 3/7 e o CI em 1/7.
  - O `review-artifact-check.sh` nunca foi vendorizado.
- **Não é desuso: o corpus centraliza por desenho** (`E_NAO_HA_NAO_USO_HA_ASSIMETRIA_POR_DESENHO`). O sinal do adotante sobe, vira guarda no core e volta por update.
- **Defeito acionável** (`E_O_GATE_DO_ADOTANTE_ESTA_INERTE_EM_4_DE_6`): o gate está inerte em 4 de 6. Os casos são husky ganhando o `core.hooksPath`, `hooksPath` apontando para diretório vazio e ausência total.
- **Irmão pior** (`E_O_GATE_DO_ADOTANTE_NASCE_REPROVADO_POR_PASSIVO_ALHEIO`): o gate vivo nasce com 47 HARD de dívida do core. A cura é `D_REGENERAR_BASELINE_POR_DESCOBERTA_NAO_POR_LISTA` (`done`).
- **Mesma adoção, mesma forma** (`E_A_GUARDA_DE_PROJECAO_CONFIAVA_NA_METADE_SEGURA`): um nome sob NDA foi projetado com o lint verde. A cura é `D_INVARIANTE_PROJETADO_IGUAL_AO_SLUG_COM_ISENCAO_NO_DADO` (`done`).
- **Medir os remotos perdeu valor de decisão** (`E_MEDICAO_DOS_REMOTOS_PERDEU_VALOR_DE_DECISAO`). O veredito chega pelo canal de co-evolução.

### 6. CI

- **Gate separado da bancada** (`D_CI_GATE_SEPARADO_DA_BANCADA`, `done`): a bancada era 686 s de 729 s do CI, e 6 de 8 PRs não tocavam maquinaria.
  - O gate sobre a mudança foi separado do teste de regressão.
  - Um `schedule` noturno cobre a main por baixo.

## NÃO-VERIFICADOS

14 itens, derivados do grafo: status `open` e nós `question`, refutados, `unverifiable`, confiança < 0,8 e divergências internas. Nenhum nó está sem `verified_at` (35/35 carimbados).

**Abertos (`status: open`)**
1. `C_PERGUNTA_DA_SUPERACAO`: a pergunta-mãe segue `open`, embora `D_SUPERACAO_REESCRITA_REINCIDENCIA` a responda. Não há aresta de fechamento.
2. `Q_RISCO_ACERVO_VIRA_CEMITERIO`: risco com gatilhos numéricos (>60% dos grafos sem toque há >30 dias; replay <5/7; `refuted+superseded` parado por 60 dias). Não re-medido.
3. `Q_RISCO_PLATAFORMA_COME_O_GATE`: gatilhos `type: agent` estável, `plugin validate` semântico e resposta oficial à issue #34556. Não re-medido.
4. `Q_RISCO_CONCORRENTE_MAIS_RIGOROSO`: gatilhos Cruxible passar de ~100★ **ou ganhar CI que emita recibo verificável**, ou `.agents/` (>60k projetos) adotar qualquer cláusula de verificação. Não re-medido.
5. `Q_O_QUE_FAZER_COM_A_NAO_TRANSFERENCIA`: segue `open`, mas `E_NAO_HA_NAO_USO_HA_ASSIMETRIA_POR_DESENHO` registra que o maestro escolheu o caminho (C) e que a premissa se dissolveu.
6. `D_CURAR_O_GATE_INERTE_DO_ADOTANTE`: segue `open`, com a métrica "gate PROVADO vivo: 2 de 6".

**Refutado**
7. `Q_ONDE_MORA_A_SUPERACAO`: a tese "o único / KG como SSOT de runtime". Não citar como posição vigente.

**Inverificável**
8. `E_REDDIT_INALCANCAVEL_LACUNA_DECLARADA`: o eixo Reddit ficou vazio após 9+ transportes barrados. O que existe de comunidade vem de HN e GitHub, com viés de early-adopter dev.

**Confiança baixa (< 0,8) em nó `confirmed`**
9. `E_CONCORRENTE_DE_POSICAO_COMPANY_BRAIN` (0,7): uma thread de HN e o site do Hyper.
10. `E_FRAGMENTACAO_NAO_ABSORCAO` (0,75): as estrelas são de uma busca por trajetória num dia só.

**Limite de desenho declarado**
11. `Q_GATE_REABRE_POR_DOGFOOD_NAO_POR_CHANGELOG` + `E_DOGFOOD_DA_PERNA_DE_LEITURA_3_DE_3_NAO_MUDOU`: o 3/3 testou "acha quando PERGUNTADO". O modo de falha medido em 08-02 ("consulta enquanto OCUPADO com outra tarefa") **não foi testado**. O desenho seguinte (tarefa cujo caminho óbvio contradiz um nó, medindo a AÇÃO) não rodou.

**Divergências internas do grafo (não reconciliadas)**
12. **Contagem de eventos de hook:** `E_CONTRATO_DE_HOOKS_EXPLODIU` diz "~30"; `Q_GATE_REABRE_POR_DOGFOOD_NAO_POR_CHANGELOG` diz "18 eventos". O grafo não diz se são perímetros diferentes (total × novos).
13. **Linhas de shell:** `E_ELENXO_DERRUBOU_METADE_DA_TESE` e `E_ACOPLAMENTO_DECLARADO_E_NAO_EXERCIDO` citam **22.710**, sem perímetro declarado. `E_INVERSAO_O_QUE_REPROVA_E_AGNOSTICO` cita **26.596**, com perímetro validation + hooks + utils. O número que o CLAUDE.md usa é o de perímetro declarado (26.596).
14. `E_DOR_DOMINANTE_E_CONTEXTO_E_CUSTO`: o "cuidado" do nó (cada superfície injetada compete pelo orçamento) é qualificado por `E_ELENXO_DERRUBOU_METADE_DA_TESE`. Esse nó diz que a maquinaria roda fora da janela e que a pressão vem da prosa, "invertendo meu próprio nó", mas não há aresta `REFUTES`/`CONSTRAINS` entre os dois.

## valeu-a-pena

**Não computável.** Tokens ÷ nós exige os dois medidos; os nós são 35, mas os tokens são `NÃO MEDIDO`. O único valor numérico encontrado (`tokens: 0` no resíduo do PR #616) é marcador de campo obrigatório, não medição. Dividir por ele fabricaria um custo por nó de zero. O que o grafo registra como retorno, sem custo que o pese:

- uma tese refutada e reescrita antes de virar ADR;
- 3 de 5 recomendações de "parar" derrubadas antes de apagar código;
- um defeito de adotante medido (gate inerte em 4 de 6) e outro achado em adoção de campo (47 HARD de passivo alheio);
- o achado de acoplamento que corrigiu o CLAUDE.md.

## Backlog

Nós `open` que pedem ação, com o gatilho que o próprio grafo nomeia:

| Nó | Ação | Gatilho |
|---|---|---|
| `D_CURAR_O_GATE_INERTE_DO_ADOTANTE` | Re-verificar o status: medi hoje que `ops/verify-adopter-gate.sh` existe (criado em `6eb75761`, 2026-08-16, "toda adoção passa a PROVAR o gate"), e `E_MEDICAO_DOS_REMOTOS_PERDEU_VALOR_DE_DECISAO` diz que o instalador "agora PROVA o gate". O nó segue `open`, então é candidato a `/meta:kg-freshness` (não fechei). | Métrica do nó: adotantes com gate PROVADO vivo (era 2 de 6). |
| `Q_O_QUE_FAZER_COM_A_NAO_TRANSFERENCIA` | Selar ou superseder: a escolha (C) já foi feita e registrada em `E_NAO_HA_NAO_USO_HA_ASSIMETRIA_POR_DESENHO`. | Escolha do maestro (já ocorreu, segundo o grafo). |
| `C_PERGUNTA_DA_SUPERACAO` | Ligar à resposta ratificada ou declarar por que segue aberta. | `D_SUPERACAO_REESCRITA_REINCIDENCIA` `done`. |
| `Q_RISCO_ACERVO_VIRA_CEMITERIO` · `Q_RISCO_PLATAFORMA_COME_O_GATE` · `Q_RISCO_CONCORRENTE_MAIS_RIGOROSO` | Riscos vigiados, sem trabalho até disparar. | Os gatilhos numéricos e observáveis de cada nó (itens 2–4 acima). |
| Revisita do grafo | Re-medir as premissas de plataforma contra o binário atual (2.1.270), sobretudo o `exit 2` sob `bypassPermissions` e a superfície de hooks. | `meta.review_after` 2026-09-15 (REGRA 67 (Grafo de pesquisa com REVISITA carimbada (meta.review_after))). |
