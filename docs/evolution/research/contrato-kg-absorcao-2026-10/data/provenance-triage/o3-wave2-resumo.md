# O3 onda 2: proposta do proponente (2026-10-09)

Esta é a projeção da proposta da onda 2 da O3 (SAC-73, migração de provenance), feita sob
`D_POLITICAS_DA_MIGRACAO_DE_PROVENANCE` e os selos do maestro de 2026-10-09, inclusive a regra nova
do `corrigir-label`. **Nada foi aplicado nos grafos.** O próximo passo é um juiz independente refutar
esta planilha. Todo flip de status passa pelo selo do maestro.

## Escopo

- **Onda 2 (`o3-wave2-proposta.csv`)**: 276 nós em 38 grafos (`o3-waves.tsv`, onda 2), sem
  duplicata e sem nó faltando.
- **Anexo (`o3-wave2-anexo-testimony-in-prod.csv`)**: 30 nós. A interseção entre o universo da onda 2
  e `v41-testimony-in-prod.tsv` é **zero**. Os nós da lista do v4.1 já têm provenance de classe
  `testemunho` desde a migração v4, por isso não entraram no universo da O3. Mas **30 deles moram em
  grafos da onda 2**, e foram tratados no anexo com as mesmas colunas, para não ficarem órfãos entre
  as ondas. O anexo é separável: o juiz pode julgá-lo à parte ou adiá-lo.

## Contagens da onda 2

| proposta | nós |
|---|---|
| corrigir | 172 |
| corrigir-label | 48 |
| testemunho | 29 |
| dev-óbvio | 20 |
| rebaixar | 6 |
| refutar | 1 |
| dev-dúvida | 0 |
| **total** | **276** |

Classes de `method`, por proposta:

| proposta | leitura | medição | derivado | juízes | testemunho |
|---|---|---|---|---|---|
| corrigir | 143 | 15 | 11 | 3 | — |
| corrigir-label | 36 | 3 | — | — | 9 |
| testemunho | — | — | — | — | 29 |
| dev-óbvio | 3 | — | 1 | — | 16 |
| refutar | 1 | — | — | — | — |

**Flips de status propostos: 6, todos `confirmed → unverifiable` e todos em DEV** (correção de
verdade): `E_ANTIPADRAO_MEDIDO_EM_PRODUCAO`, `E_MEMORIA_DE_AGENTE_E_COMMODITY_PELO_DINHEIRO`,
`D_VIAVEL_COM_EXPECTATIVA_CALIBRADA`, `E_hybrid_pricing_trend`, `E_ITEM6_VERIFY`,
`C_OPT_DIARY_BRAIN`. Nenhum nó PROD foi rebaixado, e nenhum nó não-`confirmed` também.

**`refutar` (1)**: `E_EXPERIMENT` (confirmed, PROD). O fato central ("recuperou… refez review real em
#415/#416") cai. O diário (l.29-30) mostra a action saindo com exit 0 e `is_error`, e #415/#416 têm
0 comments e 0 reviews.

**Os 20 dev-óbvio mudam o plano** (PROD → DEV), não o status. São 11 confirmed, 4 done, 2 superseded,
2 open e 1 refuted.

## Anexo testimony-in-prod (30 nós)

| proposta | nós |
|---|---|
| corrigir | 16 (leitura 15, medição 1) |
| dev-óbvio | 13 |
| corrigir-label | 1 (`E_PROJECT_DOOR_GATE_OPENED`) |

Os 13 dev-óbvio são quase todos o `bridge-produto` (F0–F5, F-ID.1–4) e evidências datadas de
2026-08-14 e 08-15. São relatos de fechamento de fase, ou seja, testemunho datado que descreve o
passado. Dois deles (`F_ID_3_SUPERFICIE`, `F_ID_4_MGM`) têm um label que é snapshot anterior ao
`done` e que contradiz o próprio status.

Os 16 corrigir trocaram a leitura do arquivo no host (`/home/onion/...`, `/home/marcio/onion-vps-*`)
por **leitura de commit** no clone do adotante, com sha.

## Correção aplicada pelo proponente

Catorze linhas que os workers marcaram `corrigir` com classe `testemunho` foram para a proposta
`testemunho`, como na onda 1. São fontes em journal `wf_*` no host, ou relato e selo do maestro
citados em corpo de commit. Ficaram 29 `testemunho`.

## Casos difíceis (para o juiz olhar primeiro)

1. **12 `corrigir-label` com classe diferente de `leitura`.** A regra nova manda `leitura: …`, mas
   em 9 deles a fonte que contradiz o label é um journal `wf_*` no host, e aí a política 8 dá a classe
   `testemunho`. Os outros 3 têm comando registrado e reproduzível: `git grep` em
   `E_EXPLORE_ARISTOTLE`, e `gh run view`/`download 36782105288` em `C_PREVOO_MEDE_CREDENCIAL_NAO_SALDO`
   e `E_REVISOR_CAI_POR_SALDO_DE_API`. Mantive a classe da fonte. Se o juiz ler a regra à letra, troca
   só o prefixo.
2. **A família `E_LACUNAS_*_1001/0928`** (motores, unidade-bilhetável, company-brain,
   agent-command-composition). É o mesmo padrão da onda 1: o label contou o **repasse truncado** e
   não o run. "23/31/67" são números de CORTE por orçamento, e "10 sobreviventes do Elenxo" é o que a
   sessão modelou (os journals dizem 50, 52 e 51). A proposta é `corrigir-label` com os números do
   journal, e não `rebaixar`, porque a fonte existe e diz outra coisa.
3. **`E_LACUNAS_PRIMARIES_0928`**: o label afirma uma quote "confirmada por grep no HTML bruto" que a
   própria micro-ancoragem posterior (`a2734a63`, `Q_CONDUCTOR_VETO_ANCHORING_PENDING` l.544) diz não
   existir na fonte. É fonte fabricada dentro do label, e só essa frase foi trocada.
4. **Rebaixar com fonte parcial** (padrão 5 da onda 1, o inverso). Os candidatos a REPROVADO são:
   - `E_ANTIPADRAO_MEDIDO_EM_PRODUCAO`: o incidente PocketOS existe na imprensa (decrypt.co,
     computing.co.uk), mas a "convergência Ronacher/Hashimoto" e a fonte da sessão não foram
     achadas.
   - `E_MEMORIA_DE_AGENTE_E_COMMODITY_PELO_DINHEIRO`: a tese está num resíduo R56, mas os números
     (3,4%, Cognee, Interloom, Mem0) não estão.
   - `E_hybrid_pricing_trend`: a URL não traz o 43%→61%.

   A alternativa seria `corrigir-label` restrito ao que a fonte sustenta.
5. **dev-óbvio sobre nó com fonte.** `E_A_GUARDA_SELAVA_A_PROPRIA_DOENCA`, `E_FUROPRUNE_LINT_0804`,
   `E_RENDER_ERA_LOCALE_DEPENDENTE`, `E_FAROL_ANUNCIAVA_FANTASMA` e outros do `guardas-revisao` têm o
   corpo de commit da sessão em 1ª pessoa. Pela política 6 ("testemunho datado que descreve o
   passado") vão para DEV. A alternativa é `testemunho` mantendo PROD.
6. **dev-óbvio em done e superseded** (`D_ESTUDAR_FAMILIA_ANTES_DE_CORRIGIR_0804`, `E_SITE_LIVE`,
   `C_TRES_FORMAS_DE_VERDE_SEM_OLHAR_0804`, `Q_CUSTODIA_DA_CHAVE_GPG_FORA_DA_VPS`,
   `Q_QUATRO_PENDENCIAS_DO_TERRENO`, `I_A1_…`). Isso tira done e superseded de PROD.
7. **`E_MARKET_SCAN` e `C_MARKET_COMMODITY`**: os números de mercado (Spec Kit 93k, BMAD 49k…) não
   estão em arquivo versionado. Por isso foram para `dev-óbvio` como juízo de mercado datado, e não
   para `rebaixar`.
8. **Testemunho via corpo de commit de decisão do maestro** (`D_NORTHSTAR_NS1_KG`,
   `D_ICP_EMPRESA_MAIS_N1`, `D_CLAUDE_CODE_POR_CAPACIDADE`, `E_PORTE_PARA_O_CURSO`). A origem é
   explícita (data e maestro) no corpo de `e054d69c` e `65289818`.

## Baixa confiança (< 0,60), 20 nós

`C_FLOW_EVOLUTION`, `C_KG_BIZ_UNPROVEN`, `C_MARKET_COMMODITY`, `C_DUPLICACAO_4_CLONES`,
`D_ESTUDAR_FAMILIA_ANTES_DE_CORRIGIR_0804`, `E_ANTIPADRAO_MEDIDO_EM_PRODUCAO`,
`E_MEMORIA_DE_AGENTE_E_COMMODITY_PELO_DINHEIRO`, `E_REFUTA_Q_LACUNA_DECISAO_MAIS_CODIGO`,
`E_LACUNAS_E3_0904`, `D_VIAVEL_COM_EXPECTATIVA_CALIBRADA`, `E_ELENXO_ROUND_CURADO`,
`Q_G_ID_PROVA_HUMANA`, `E_compliance_grc_market`, `E_consulting_daterate`, `E_consumer_pipoca`,
`E_LACUNAS_WHATSAPP_REVISITA_20260903`, `E_MERCADO_WHATSAPP_REVISITA_20260903`,
`E_HEADROOM_SWAP_100`, `E_ITEM6_VERIFY`, `C_OPT_DIARY_BRAIN`.

## Tetos

1. **O proponente não é o juiz.** As 306 linhas foram escritas por 6 workers paralelos da mesma
   família de modelo, com as mesmas instruções, que listavam os 7 padrões de erro da onda 1. A
   confiança é autoavaliada. A consolidação conferiu:
   - cobertura e ordem por lote, sem duplicata;
   - status e plano batendo com o grafo;
   - a forma `<classe>: <detalhe>` do method;
   - `dev-*` só em PROD e `rebaixar` só em confirmed;
   - `label_novo` presente em todo `corrigir-label`.

   O proponente-mestre leu por amostragem, não linha a linha.
2. **"Sustenta o label inteiro" continua sendo leitura, não métrica.** A taxa de `corrigir-label`
   (48/276) mostra que os workers aplicaram a regra nova, mas não garante que nenhum `corrigir`
   esconda uma cláusula sem fonte (padrão 1).
3. **Journals `wf_*` e transcripts no host** só se reabrem nesta máquina. Os clones dos adotantes
   dependem de `/home/marcio/<repo>`.
4. **URLs e `gh run` medidos uma vez, em 2026-10-09.** Os artefatos de run do Actions expiram.
5. **O anexo de 30 nós está fora do mandato estrito da onda.** Foi incluído porque a lista do v4.1
   não intersecta o universo da O3, e sem isso esses nós não teriam onda.

Orquestrado com 🧅 Onion Evolve
