---
title: "OCR local para o SEI: nenhum motor é escolhível por este dossiê — decide-se o procedimento, e o Passo 0 (olhar as 26 páginas) pode dissolver a decisão"
date: 2026-09-08
kg: docs/evolution/research/ocr-local-sei-2026-09/ocr-local-sei-2026-09.kg.yaml
run_id: wf_fb266335-f95
tokens: 6717798
agents: 104
duration_min: 32
genre: decision
mode: decision
review_after: 2026-10-08
---

# OCR local para PDF-imagem do SEI — a rodada de 2026-09-08

> **Projeção** do grafo (27 nós, 44 arestas, radar exit 0 em `--integrity --schema`). A fonte é o `.kg.yaml`; este texto deriva dele e não acrescenta afirmação.

- **`date`**: tirada de `meta.baseline: 2026-09-08`, que coincide com o `verified_at` de todos os 16 nós que o carregam.
- **`review_after`**: o mesmo valor de `meta.review_after` (2026-10-08, cadência ferramenta 30d da REGRA 67 (Grafo de pesquisa com REVISITA carimbada (meta.review_after))). Não está vencida em 2026-09-13. O grafo nomeia dois gatilhos de revisita **antecipada** que valem mais que a data: (i) o Passo 0 ser executado sobre as 26 páginas reais; (ii) qualquer motor ser rodado nas 3 páginas vinculantes com contagem de erros.
- **`genre`/`mode`**: `decision`, lido da forma do grafo (1 `question` + 1 `decision` aberta + 9 opções + 8 objeções do Elenxo). O grafo não declara `mode` em `meta`.

**A pergunta** (`Q_OCR_LOCAL_SEI_0908`): qual motor de OCR **local** escolher para ler PDF-imagem de documento administrativo do SEI (serifa, tabelas, carimbo/assinatura sobreposta), com alta confiabilidade dominante, 26 páginas das quais 3 são **vinculantes**, em Ubuntu/Python 3.12/poppler 24.02, projeto dependency-light, sem GPU confirmada, e com a restrição dura de que **nada sai da máquina** (material sob NDA).

## Custo declarado

| Item | Valor |
|---|---|
| Tokens | 6.717.798 (`totalTokens`) |
| Workers | 104 (`agentCount`) · 708 tool calls (`totalToolCalls`) |
| Parede | ~32 min (`durationMs` 1.919.494) |
| `run_id` | `wf_fb266335-f95` (workflow `onion-research`, `status: completed`, `args.mode: decision`, `args.kgPath` = este grafo, `budget` maxFetch 15 / maxVerify 25) |
| Funil da rodada (do **diário**, `logs` + `result.stats`) | 10 ângulos → 54 URLs únicas → **15 fontes lidas, 39 cortadas por orçamento** → **48 claims** → 25 verificadas (**5 confirmadas, 20 refutadas**, 0 não verificadas) → **23 claims fora do orçamento de verificação** · Elenxo: 25 objeções, **21 sobreviventes** |

**Fonte do custo:** o diário do run, `~/.claude/projects/-home-marcio-onion-evolve/5938ea58-21a9-462c-93a3-17003494089c/workflows/wf_fb266335-f95.json`, lido com `jq`. O workflow é `onion-research`, com `status: completed`, `timestamp` 2026-09-08T03:27:25Z e `args.kgPath` igual ao `kg:` acima.

**Onde procurei antes, sem achar:**
- `meta` do `.kg.yaml` (não traz custo);
- a pasta (só o `.kg.yaml`);
- `git log --all -S 'ocr-local-sei'` e `--grep=ocr` (commits `85bf7215`/`52d53681`, sem número);
- grep do slug em `docs/`, `.claude/sessions/`, `.claude/diary/` e `docs/evolution/review/`.

A primeira versão desta síntese declarou "NÃO MEDIDO" por não ter procurado no diário. A passada adversarial apontou o arquivo, e os números acima foram conferidos nele.

⚠️ O funil do diário **diverge** do que o grafo registra em `E_LACUNAS_DECLARADAS_OCR_0908`. Ver NÃO-VERIFICADOS, item 1.

## Veredito

**A pergunta não é decidível a partir desta rodada** (`Q_OCR_LOCAL_SEI_0908`, `status: open`). As 5 confirmações não medem o eixo dominante (acurácia em português administrativo com carimbo sobreposto), nenhuma mede alucinação sob oclusão de nenhum motor, e **zero páginas do corpus real foram abertas**.

A recomendação do Elenxo, registrada na decisão aberta `D_OCR_LOCAL_SEI_0908` (quem sela é o maestro): **não escolher motor por este dossiê. Escolher o procedimento e deixar o motor sair de medição local**, nesta ordem.

1. **Passo 0: olhar o artefato.** `pdftotext -layout` e `pdfimages -list` página a página, com o poppler já instalado. PDF do SEI mistura páginas com camada de texto e páginas escaneadas, e o enunciado nunca afirmou que as 3 vinculantes são imagem. Se tiverem camada de texto, a decisão **evapora** (`C_OPCAO_BASELINE_SEM_OCR_PDFTOTEXT`, confiança 0.9, empatada na mais alta do grafo). Se não tiverem, essa saída vira o gabarito parcial.
2. **Passo 1: se precisar de OCR, o critério é arquitetura, não benchmark.** Pipeline multi-estágio degrada **visivelmente** (caixa vazia, confiança baixa por palavra). Decoder fim-a-fim **completa** o texto plausível sob oclusão, fluente e sem sinal (`E_OBJECAO_1_FIM_A_FIM_MAXIMIZA_SILENCIO`). Isso pesa a favor do Tesseract com TSV conf+bbox por palavra (`C_OPCAO_TESSERACT5_TESSDATA_BEST`) e reprova dots.ocr como motor único nas páginas vinculantes (`C_OPCAO_DOTSOCR_3B_CPU`).
3. **Passo 2: consenso só entre linhagens diferentes.** PaddleOCR-VL, dots.ocr e MinerU 2.5 são VLMs de linhagem próxima e erram juntos (`E_OBJECAO_2_CE_MEDE_ACORDO_NAO_CORRECAO`). O consenso útil é 1 pipeline clássico × 1 VLM, com a divergência roteada ao humano (`C_OPCAO_PROCEDIMENTO_CONSENSO_DOIS_MOTORES`).
4. **Passo 3: revisão humana de 100% das 3 páginas vinculantes**, independente do motor. Em 26 páginas, throughput não é critério.

A condição para fechar `D_OCR_LOCAL_SEI_0908` é uma **condição, não uma data**: saída do Passo 0, contagem de erros de pelo menos 2 motores nas 3 páginas vinculantes e `pip install --dry-run` de cada candidato neste venv.

## Achados por tema

### Arquitetura e o requisito "erro em silêncio"

- `E_DOTSOCR_VLM_FIM_A_FIM` (tier 7, 3-0): dots.ocr é um VLM único fim-a-fim. O paper trata isso como mérito. `E_OBJECAO_1_FIM_A_FIM_MAXIMIZA_SILENCIO` **inverte o sinal**: sob o requisito dominante, é passivo.
- `E_DOTSOCR_SEM_CONFIDENCE_NEM_CARIMBO` (tier 6, 3-0): sem confidence nativo nem validação cruzada, e com falhas de parsing admitidas pelo próprio projeto. `E_OBJECAO_3_ARGUMENTO_DO_SILENCIO_FALTA_MEDICAO` separa as duas metades: "sem confidence" é decisivo como conclusão, mas "README não menciona carimbo" é argumento do silêncio. A cura é rodar e contar erros (behavior-over-declaration).
- Nomes de geração: o dossiê usa dots.ocr e dots.mocr como se fossem o mesmo modelo, e houve rebrand em 2026-03. Os números podem ser de outra geração (`E_OBJECAO_1_FIM_A_FIM_MAXIMIZA_SILENCIO`, `C_OPCAO_DOTSOCR_3B_CPU`).

### Verificação por consenso

- `E_CONSENSUS_ENTROPY_SEM_TREINO` (tier 7, 3-0, confiança rebaixada a 0.7): a Consensus Entropy estima confiabilidade pela entropia do acordo entre modelos, sem treino.
- `E_OBJECAO_7_DESACORDO_REFUTADO_SUSTENTA_CE`: o dossiê refutou "desacordo é sinal de erro", que é a perna de sustentação do achado, e manteve o achado confirmado. É **contradição interna**. Consequência operacional: a divergência serve para **escalar** ao humano, **nunca** para dispensá-lo quando os motores concordam.
- `E_OBJECAO_2_CE_MEDE_ACORDO_NAO_CORRECAO`: CE mede concordância, não correção. A forma canônica pede 3+ stacks pesados, o que reprova a forma literal num projeto dependency-light e deixa só a forma degradada (2 motores + humano).

### Custo de instalação (requisito c)

- `E_DOCTR_PYTHON_311_PLUS` (tier 9, 3-0): docTR roda em Python 3.12. `E_OBJECAO_4_DOCTR_TIER9_IRRELEVANTE_E_PESO_TORCH`: é verdade, mas não decide nada. O custo é o backend torch/TF (da ordem de 2,5 GB de wheel, segundo o grafo) contra um venv com numpy/pillow/pypdf/openpyxl.
- `E_OBJECAO_6_CUSTO_INSTALACAO_POR_IMPRESSAO`: uma proposição tier 9 foi refutada sem evidência, e o requisito (c) seguiu respondido **por impressão para todos os candidatos**. É o defeito de método mais barato de curar: um `pip install --dry-run` por candidato, offline.
- `E_SURYA_CPU_EXIGE_LLAMACPP` (tier 7, 3-0, confiança 0.6): em CPU, o Surya exige llama.cpp. `E_OBJECAO_5_SURYA_CONFLACAO_DE_GERACOES` suspeita de mistura entre a linha nova (Chandra, llama-server) e os modelos clássicos PyTorch que rodam em CPU. A distinção muda o custo inteiro.

### As 9 opções (`D_OCR_LOCAL_SEI_0908` → `DEPENDS_ON`)

| Opção | Nó | Confiança | O que o grafo diz |
|---|---|---|---|
| (1) Tesseract 5 + tessdata_best | `C_OPCAO_TESSERACT5_TESSDATA_BEST` | 0.6 | a mais alta entre motores: a falha é **visível** (conf+bbox por palavra); português e calibração da conf não medidos |
| (2) PaddleOCR / PaddleOCR-VL 0.9B | `C_OPCAO_PADDLEOCR_VL_CPU` | 0.3 | todas as claims a favor refutadas; herda as objeções 1 e 2 |
| (3) docTR + torch | `C_OPCAO_DOCTR_TORCH_VENV` | 0.3 | é pipeline multi-estágio (não herda a objeção 1); custo e português intocados |
| (4) Surya | `C_OPCAO_SURYA_EVIDENCIA_CONTRADITORIA` | 0.2 | evidência contraditória e não reconciliada; GPL-3.0 |
| (5) dots.ocr / dots.mocr 3B | `C_OPCAO_DOTSOCR_3B_CPU` | 0.2 | reprovado como motor único nas vinculantes; só serve como perna de consenso |
| (6) MinerU 2.5 / olmOCR | `C_OPCAO_MINERU_OLMOCR` | 0.2 | não pesquisados; confiança baixa por **ausência** de evidência, não por evidência negativa |
| (7) Docling (IBM, Apache-2.0) | `C_OPCAO_DOCLING_IBM` | 0.3 | fora do escopo original; venceu em tabela no único benchmark tocado |
| (8) Baseline sem OCR (poppler) | `C_OPCAO_BASELINE_SEM_OCR_PDFTOTEXT` | 0.9 | Passo 0, custo zero; pode dissolver a decisão |
| (9) Procedimento: consenso 2 motores + humano | `C_OPCAO_PROCEDIMENTO_CONSENSO_DOIS_MOTORES` | 0.7 | a que sobrevive melhor por não depender de fornecedor |

### Mercado e corpus

- `E_MERCADO_OCR_LOCAL_0908`: **sem sinal de capital** que sobrevivesse aos votos adversariais para nenhum motor. É lacuna da pesquisa, não constatação. Sem follow-the-money, o grafo empurra o peso para o menor risco de abandono (Tesseract via apt) e para o procedimento.
- `E_CORPUS_VAZIO_OCR_0908`: 92 grafos e 3289 nós varridos, nada sobre OCR. O único adjacente, a doutrina "não-retenção > cifra", reforça a restrição de que nada sai da máquina.

## NÃO-VERIFICADOS

São **19 itens**: 1 divergência grafo × diário, 11 nós `open` sem `verified_at`, 4 nós confirmados com ressalva no próprio nó, 2 registros de lacuna e 1 observação desta síntese.

### Divergência grafo × diário do run

1. **`E_LACUNAS_DECLARADAS_OCR_0908` não bate com o diário `wf_fb266335-f95`.** O nó abre com "39 fontes consultadas, 23 claims levantadas, 5 confirmadas, 18 refutadas". O diário diz outra coisa, em `logs` e em `result.stats`/`result.*`:
   - Fontes: "fetch 15 (… 39 cortadas por orçamento)" → `sources 15`, `budgetDropped 39`.
   - Claims: "claims 48 → verificando top 25 (23 fora do orçamento de verificação)" → `claims 48`, `notVerifiedByBudget 23`.
   - Verificação: "5 confirmadas, 20 refutadas" → `refuted 20`.
   - Elenxo: "25 objeções, 21 sobreviventes".

   O nó trocou "39 fontes **cortadas**" por "39 fontes" e "23 **fora do orçamento**" por "23 claims", e registra 18 refutadas onde o diário tem 20. O que o grafo **não** carrega, portanto:
   - **23 claims nunca verificadas**, cortadas pelo orçamento de verificação.
   - **39 fontes nunca lidas**, cortadas pelo orçamento de fetch.
   - **13 objeções sobreviventes do Elenxo não modeladas como nó**: 21 no diário contra 8 `E_OBJECAO_*` no grafo. Parte do conteúdo aparece diluída em labels de opções. Material presente no diário e ausente do grafo, **como declarado pelo Elenxo, não re-medido por mim**:
     - ambiente declarado "GPU ausente, verificado", com 8 vCPUs AVX-512 (VNNI/BF16) e 31 GB de RAM (no grafo, a GPU segue "não confirmada");
     - `tesseract-ocr-por` do Ubuntu 24.04 declarado como `1:4.1.0-2`, isto é, dados de língua do 4.x;
     - claims de mercado **cortadas por orçamento** sobre a Datalab (seed, equipe pequena, GPL-3.0). Isso torna impreciso o `verified_against` de `E_MERCADO_OCR_LOCAL_0908` ("nenhum ângulo devolveu rodada de investimento"): o fan-out devolveu, e o corte veio antes do voto;
     - fontes primárias não lidas: OmniDocBench, a busca por trajetória `created:>` e a fonte sobre carimbos/selos.

   Os 5 confirmados, as 9 opções e o texto da recomendação batem com o diário.

### Nós `open` (sem `verified_at`), ordenados por confiança

2. `C_OPCAO_SURYA_EVIDENCIA_CONTRADITORIA`: 0.2.
3. `C_OPCAO_DOTSOCR_3B_CPU`: 0.2. Alucinação sob oclusão não medida.
4. `C_OPCAO_MINERU_OLMOCR`: 0.2. Zero fonte primária.
5. `C_OPCAO_PADDLEOCR_VL_CPU`: 0.3. Custo de instalação não medido.
6. `C_OPCAO_DOCTR_TORCH_VENV`: 0.3. Custo e português não verificados.
7. `C_OPCAO_DOCLING_IBM`: 0.3. Nenhuma fonte primária; custo e português não medidos.
8. `D_OCR_LOCAL_SEI_0908`: decisão aberta, 0.5. O maestro sela, e a condição de fechamento não foi cumprida.
9. `Q_OCR_LOCAL_SEI_0908`: pergunta, 0.6. Declarada não decidível nesta rodada.
10. `C_OPCAO_TESSERACT5_TESSDATA_BEST`: 0.6. Português do `por.traineddata` e calibração da confidence não medidos.
11. `C_OPCAO_PROCEDIMENTO_CONSENSO_DOIS_MOTORES`: 0.7. A conversa "baixa entropia implica acerto" não está estabelecida.
12. `C_OPCAO_BASELINE_SEM_OCR_PDFTOTEXT`: 0.9. "Nem o comando foi rodado ainda: é a próxima ação, não um fato."

### Confirmados com ressalva registrada no próprio nó

13. `E_CONSENSUS_ENTROPY_SEM_TREINO`: 0.7. Tem a **perna de sustentação refutada** (`E_OBJECAO_7_DESACORDO_REFUTADO_SUSTENTA_CE`), e é o fundamento parcial da opção 9, justamente a **recomendada**.
14. `E_DOTSOCR_SEM_CONFIDENCE_NEM_CARIMBO`: 0.7. A metade "sem menção a carimbo" é argumento do silêncio, não medição (`E_OBJECAO_3_ARGUMENTO_DO_SILENCIO_FALTA_MEDICAO`).
15. `E_SURYA_CPU_EXIGE_LLAMACPP`: 0.6, apesar de tier 7 e 3-0, por suspeita de mistura de gerações.
16. `E_OBJECAO_5_SURYA_CONFLACAO_DE_GERACOES`: a suspeita é inferência sobre a estrutura do repo e **não foi verificada abrindo o repo**.

### Registros de lacuna

17. `E_LACUNAS_DECLARADAS_OCR_0908`, conteúdo além da contagem divergente do item 1:
   - **Refutadas sem evidência registrada contra fonte forte, entre elas:** 4 tier 7 do Surya em bloco (`E_OBJECAO_8_SURYA_QUATRO_REFUTADAS_EM_BLOCO`), a instalação do docTR tier 9 e a perna do CE tier 7.
   - **Cortada por orçamento:** a disconfirmadora do Surya.
   - **5 perguntas nunca feitas:** camada de texto das 26 páginas, `pip --dry-run`, alucinação sob oclusão, português com serifa/cedilha e Docling.
18. `E_MERCADO_OCR_LOCAL_0908`: eixo de mercado vazio no grafo. É lacuna, não ausência de capital (ver também o item 1).

### Observação desta síntese (não é nó do grafo)

19. **Eixo SLM de OCR não pesquisado neste run como eixo próprio.** Modelos pequenos de visão-linguagem/documento aparecem só como candidatos da lista herdada do enunciado:
    - PaddleOCR-VL 0.9B (`C_OPCAO_PADDLEOCR_VL_CPU`);
    - dots.ocr/dots.mocr 3B (`C_OPCAO_DOTSOCR_3B_CPU`);
    - MinerU 2.5/olmOCR (`C_OPCAO_MINERU_OLMOCR`, não pesquisados);
    - Chandra, como hipótese em `E_OBJECAO_5_SURYA_CONFLACAO_DE_GERACOES`.

    As proposições **gerais** sobre modelos pequenos que o grafo lista foram refutadas sem evidência registrada (`E_LACUNAS_DECLARADAS_OCR_0908`): "sub-10B superando fechados", "Pareto-ótimo sub-3B" e "ensemble de VLMs fracos". Nenhum nó faz o levantamento por trajetória, e o diário registra que a busca `created:>` não foi lida. Nenhum nó mede um SLM em CPU, em português ou sob oclusão. Esta síntese não acrescenta nomes nem números.

## valeu-a-pena

**≈ 249 mil tokens por nó**: 6.717.798 tokens ÷ 27 nós, com os tokens do diário `wf_fb266335-f95` e os nós contados no `.kg.yaml` e confirmados pelo radar. O número está na mesma faixa das outras pesquisas em modo decisão:

| Pesquisa | Tokens ÷ nós |
|---|---|
| `plugin-language-policy-2026-09` | 6.854.451 ÷ 26 ≈ 264 mil |
| **`ocr-local-sei-2026-09`** | **6.717.798 ÷ 27 ≈ 249 mil** |
| `plugin-mcp-posture-2026-09` | 6.957.989 ÷ 31 ≈ 224 mil |
| `kg-multi-graph-view-2026-09` | 6.709.840 ÷ 32 ≈ 210 mil |
| `poda-instruction-bloat-2026-09` | ~180 mil, como declarado na síntese dela |

As quatro vizinhas foram lidas do frontmatter das `SYNTHESIS.md` desta worktree, ainda não commitadas.

A razão mede o **grafo**, não o run. Pelo item 1 de NÃO-VERIFICADOS, o grafo deixou de fora 13 objeções sobreviventes e as contagens de 23 claims e 39 fontes cortadas. O custo acima é por nó *modelado*. Não computo um custo por achado produzido no run, porque não há contagem de achados que o grafo e o diário sustentem juntos. O rendimento qualitativo é o que o próprio grafo diz: 5 confirmações, nenhuma no eixo dominante, e o eixo de leitura "satura em declaração". O teto de 27 nós só cresce com **medição local**.

## Backlog

Os nós abertos que pedem ação, na ordem que o grafo manda:

| Ação | Nó | Custo |
|---|---|---|
| Rodar `pdftotext -layout` e `pdfimages -list` nas 26 páginas reais | `C_OPCAO_BASELINE_SEM_OCR_PDFTOTEXT` | zero, poppler já instalado |
| `pip install --dry-run` de cada candidato neste venv | `C_OPCAO_DOCTR_TORCH_VENV`, `C_OPCAO_PADDLEOCR_VL_CPU`, `C_OPCAO_DOCLING_IBM` (cura de `E_OBJECAO_6_CUSTO_INSTALACAO_POR_IMPRESSAO`) | 1 comando por candidato, offline |
| Se precisar de OCR: contar erros de ≥2 motores de linhagens diferentes nas 3 vinculantes | `C_OPCAO_TESSERACT5_TESSDATA_BEST`, `C_OPCAO_PROCEDIMENTO_CONSENSO_DOIS_MOTORES` | local |
| Abrir o repo do Surya: separar as gerações e verificar o campo de confidence por bloco | `C_OPCAO_SURYA_EVIDENCIA_CONTRADITORIA` | offline |
| **Run NOVO** do `/onion-research`, em modo `research` ou `decision`, **sem** `revisit`, com a pergunta SLM explícita: quais modelos pequenos de visão-linguagem/documento atuais rodam local em CPU e servem a este caso. Rodar antes de 2026-10-08 (`review_after`). Motivo de não usar revisit: `.claude/workflows/onion-research.js` fixa `angles: []` no revisit (l.110 e l.126) e só re-mede nós vencidos, então não abre eixo novo | `Q_OCR_LOCAL_SEI_0908`, `C_OPCAO_PADDLEOCR_VL_CPU`, `C_OPCAO_DOTSOCR_3B_CPU`, `C_OPCAO_MINERU_OLMOCR` | run de pesquisa |
| Corrigir o nó de lacunas para o funil do diário (15 lidas / 39 cortadas; 48 claims / 23 fora do orçamento; 20 refutadas) e decidir se as 13 objeções não modeladas entram como nó (**selo do maestro**) | `E_LACUNAS_DECLARADAS_OCR_0908`, `E_MERCADO_OCR_LOCAL_0908` | edição do grafo |
| Selar a decisão, depois das medições acima | `D_OCR_LOCAL_SEI_0908` | maestro |
