# O3 onda 2: veredito do juiz independente (2026-10-09)

Este é o veredito do juiz sobre `o3-wave2-proposta.csv` (276 nós em 38 grafos) e
`o3-wave2-anexo-testimony-in-prod.csv` (30 nós), sob `D_POLITICAS_DA_MIGRACAO_DE_PROVENANCE` e os
selos do maestro de 2026-10-09. O mandato era refutar, com REPROVADO como default na dúvida.
**Nada foi aplicado nos grafos.** Todo flip de status e toda mudança de plano de nó `done` passam
pelo selo do maestro.

A planilha completa está em `o3-wave2-juiz.csv`: uma linha por nó, com a coluna `origem`
(`onda2` | `anexo-tip`) e o motivo de cada decisão.

## Concordância

| recorte | APROVADO | CORRIGIDO | REPROVADO | concordância |
|---|---|---|---|---|
| onda 2 | 189 | 87 | 0 | 68,5% |
| anexo testimony-in-prod | 16 | 14 | 0 | 53,3% |
| **total** | **205** | **101** | **0** | **67,0%** |

Dos 101 CORRIGIDOS, 58 mantêm a proposta e trocam fonte, locator, method ou o texto do label. Os
outros 43 mudam a proposta.

Nenhum nó ficou REPROVADO. Toda divergência encontrou desfecho com fonte aberta: um label
restrito, uma fonte achada ou uma troca de classe. Isso é diferente da onda 1, que teve 12 REPROVADOS.
O teto 3 trata do risco que isso traz.

## Matriz proposta original × final (306 nós)

| original \ final | corrigir | corrigir-label | testemunho | dev-óbvio | rebaixar | refutar | total |
|---|---|---|---|---|---|---|---|
| corrigir | 172 | 10 | 6 | — | — | — | 188 |
| corrigir-label | — | 49 | — | — | — | — | 49 |
| testemunho | — | 6 | 23 | — | — | — | 29 |
| dev-óbvio | 1 | 5 | 11 | 16 | — | — | 33 |
| rebaixar | 1 | 3 | — | — | 2 | — | 6 |
| refutar | — | — | — | — | — | 1 | 1 |
| **total** | **174** | **73** | **40** | **16** | **2** | **1** | **306** |

Separado por recorte, o resultado final é este:
- **Onda 2:** corrigir 164, corrigir-label 68, testemunho 35, dev-óbvio 6, rebaixar 2, refutar 1.
- **Anexo:** corrigir 10, dev-óbvio 10, testemunho 5, corrigir-label 5.

Classes de `method` finais: leitura 201, testemunho 70, medição 18, derivado 11, juízes 3.

## Os casos que o proponente apontou

- **`E_EXPERIMENT`: refutar APROVADO.** O juiz-mestre conferiu ao vivo e sobrescreveu o worker, que
  tinha proposto corrigir-label.
  - No #414 a action nem rodou: "Action skipped due to workflow validation", run 29624922938.
  - Em #415 e #416 (runs 29644692142 e 29645267201), o log mostra `is_error: true`,
    `num_turns: 1` e `total_cost_usd: 0`. Os dois PRs têm 0 reviews e 0 comments.
  - "RECUPEROU" e "refez review real" caem. O "review success, retry skipped" é o sintoma do
    silenciamento, não uma cláusula que sobrevive. Reescrever o label inverteria o nó e deixaria
    erradas as arestas REFUTES `C_MODEL_CAUSE` e SUPPORTS `C_ACTION_CAUSE`.
  - A fonte final passa a ser a medição dos runs (`gh run view … --log`).
- **Rebaixar com fonte parcial: 3 dos 6 rebaixar viraram corrigir-label, 1 virou corrigir e 2
  ficaram.**
  - `E_ANTIPADRAO_MEDIDO_EM_PRODUCAO` → corrigir-label. O decrypt.co/365897 (28/04/2026) sustenta
    staging, erro de credencial, a chamada à API da Railway, o volume e os backups apagados em 9 s e o
    backup de 3 meses. Ele **contradiz** "irrecuperáveis", porque a Railway recuperou os dados.
    Ronacher/Hashimoto e "token em arquivo não relacionado" saem.
  - `D_VIAVEL_COM_EXPECTATIVA_CALIBRADA` → corrigir-label. A fonte é o README upstream do
    Vaultwarden mais o 6d82b1b do clone. Saem os números de RAM do Bitwarden e o "de graça vs
    licença".
  - `E_hybrid_pricing_trend` → corrigir-label. O juiz-mestre trocou a classe para **testemunho**
    (detalhe abaixo, no padrão 5). A URL flexprice.io não traz o número, e o 21%→15% e o BCG saem.
  - `C_OPT_DIARY_BRAIN` → corrigir, por sobrescrita do juiz-mestre. O worker tinha mandado o nó
    para dev-óbvio, mas ele já é DEV. A fonte que o worker achou (dcb29e96 + diário 07-16 l.24-28)
    sustenta o label, que só enuncia a opção A modelada.
  - `E_MEMORIA_DE_AGENTE_E_COMMODITY_PELO_DINHEIRO`: rebaixar APROVADO. Só o resíduo do #578 l.62
    repete o "0,6%", sem localizador. Não foi achada fonte, nem no repo, nem no `git log -S`, nem na
    web, para 3,4%, Interloom, Cognee, Mem0, US$60B ou Astral.
  - `E_ITEM6_VERIFY`: rebaixar APROVADO. Nenhuma fonte do raciocínio em
    `onion-evolution-2026-07-17`, 7de0056d, PRs #408-#413 ou transcripts da janela.
- **Família `E_LACUNAS_*`, conferida contra o journal:**
  - `_MOTORES_1001`, `_UNIDADE_BILHETAVEL_1001`, `_COMPANY_BRAIN_…_1001` e
    `_AGENT_COMMAND_COMPOSITION_0928`: os números do proponente batem com os `wf_*.json` do host.
    Os exemplos são 22/93/32/28/4 com Elenxo 56→50, 24/90/34/17/17 com Elenxo 60→52, 26/103/36 com
    67 cortadas e 51 objeções sobreviventes, e 15 lidas/35 cortadas/25 julgadas/31 não julgadas.
    Mas **todos os labels propostos estouravam 280 caracteres** (312, 466, 808) ou diziam "como no
    label original". Foram reescritos só com o que o journal diz.
  - `_PRIMARIES_0928`: corrigir-label APROVADO. O wf_91ae27d0-df6 confirma 18 ancoradas e 4
    rejeitadas, e a quote "roteia, não veta" não existe no post do Conductor.
  - `_DECLARADAS_PLUGIN_LANGUAGE_0904` e `_WHATSAPP_REVISITA_20260903`: os journals `wf_bde10f3f`
    e `wf_9487391f` **não existem no host**. Os labels foram restritos ao que a SYNTHESIS versionada
    diz, e a SYNTHESIS contradiz os contadores.
  - `_E3_0904`: corrigir-label. O `instructions-loaded.jsonl` contradiz as "2 cargas por sessão"
    (é 1).
- **dev-óbvio sobre nó com fonte própria: 11 viraram testemunho e ficam em PROD.**
  - Corpos de commit em 1ª pessoa no `guardas-revisao`: `E_A_GUARDA_SELAVA_A_PROPRIA_DOENCA`,
    `E_RENDER_ERA_LOCALE_DEPENDENTE`, `E_ENUMERACAO_VAZIA_ERA_DESTRUTIVA`,
    `E_FAROL_ANUNCIAVA_FANTASMA` e `E_FUROPRUNE_LINT_0804`.
  - `E_MARKET_SCAN` e `E_SITE_LIVE` (superseded): medição datada da sessão, política 2.
  - `E_ESPELHO_CADUCO_DO_SSOT_DA_FEDERACAO`: ec4c8442.
  - `Q_QUATRO_PENDENCIAS_DO_TERRENO` (done) e `E_SSO_VALIDADO_PONTA_A_PONTA`: corpo de 775569f1 com
    Claude-Session.
  - `Q_CUSTODIA_DA_CHAVE_GPG_FORA_DA_VPS`.
- **Mais 5 dev-óbvio viraram corrigir-label e 1 virou corrigir.**
  - `F_ID_3_SUPERFICIE` e `F_ID_4_MGM` (done) têm label que contradiz o próprio status. Mandar para
    DEV deixaria a mentira de pé; fica em PROD com o label do done.
  - `E_FIX_PIORA_23_REGRAS` e `C_TRES_FORMAS_DE_VERDE_SEM_OLHAR_0804`: fonte no 9c4f3082 e no
    PR #537.
  - `E_GROUNDING`: corrigir-label, como medição. O `git ls-tree dcb29e96^` reproduz 33 arquivos e
    10 KGs, e "1 sessão in-repo" é falso.
- **`E_MARKET_SCAN`/`C_MARKET_COMMODITY`:** o primeiro virou testemunho e o segundo segue
  dev-óbvio, porque é juízo de mercado.

## Padrões de erro do proponente

1. **Label de `corrigir-label` acima de 280 caracteres ou que não se sustenta sozinho.** É o padrão
   novo e dominante da onda. Pelo menos 17 casos: os `E_LACUNAS_*`, `E_anthropic_pricing`, `I_A6`,
   `I_REPASSEI`, `E_OIDC_GENERICO_SEM_GUIA_LOGTO`, `E_MEDIDO_D_RUNTIME_CONTRACT_2026_09`,
   `Q_EMBEDDINGS_KEY_PENDENTE`, `C_DUPLICACAO_4_CLONES` e outros. Alguns eram **instrução em vez de
   texto**: "idêntico ao atual, trocando…", "(b)-(g) como no original". A consolidação conferiu que
   `label_novo` estava presente, mas não o tamanho.
2. **"Sustenta" declarado sobre label com cláusula sem fonte** (o mesmo padrão 1 da onda 1). 10
   `corrigir` e 6 `testemunho` viraram corrigir-label. Exemplos: `C_POSTURA_ACOPLAMENTO` ("slice de
   rules"), `D_ICP_EMPRESA_MAIS_N1` ("metagamify com sub-adotados" contradito pelo
   `members.yaml@e054d69c`), `C_PEER_UNIQUE`, `D_STACK_PADRAO_ONION_VPS` ("SSO obrigatório"
   contradito pelo compose do 7338dcb), `E_TETO_DA_VERSAO_E_SO_PROSA`,
   `E_MERCADO_SEM_SINAL_DE_CAPITAL_EM_I18N_DE_CATALOGO` e `C_FRAME_ALWAYS_BILL` (fala do assistente,
   não do maestro).
3. **dev-óbvio aplicado a testemunho datado com origem própria.** 17 dos 33 dev-óbvio saíram de DEV.
   A política 6 ("testemunho que descreve o passado") foi lida como regra de plano, quando o selo
   permite testemunho em PROD sempre que a sessão é a origem explícita.
4. **Rebaixar com fonte parcial** (o padrão 5 da onda 1 se repetiu). 4 dos 6 rebaixar tinham fonte.
5. **Classe de method errada.**
   - `medição` para commit em outro repo, que é `leitura` com sha (política 4): `C_TOPO_SHARED_BASE`,
     `E_GIT_MERGEBASE` e `E_GIT_LSTREE_MAIN`.
   - `leitura` onde não há comando registrado e o relato é da sessão: `E_GREP_TRACE` e
     `I_CONSOLE_DO_LOGTO_ESTA_PUBLICO`.
   - Classe misturada num campo: `D_SELO_DO_MAESTRO_REVERTEU_O_FLIP` e `Q_SENHA_CHAVE_ESTADO_2026_09`.
   - Method circular, com testemunho citando o próprio grafo: `D_ESTUDAR_FAMILIA_…`.
   - **Juiz-mestre:** os números de mercado do gtm-decisions (`E_safe_cert`,
     `E_consulting_daterate`, `E_mentoria_pricing` e `E_hybrid_pricing_trend`) só têm o brief
     21213cc6 como fonte, e o brief cita a primária por domínio, sem caminho. Citação sem localizador
     não é fonte do número de mercado. A classe passa a ser `testemunho: pesquisa de mercado da
     sessão registrada no brief…`, e não `leitura`. Os quatro nós são DEV, e os workers tinham
     aprovado como leitura com confiança 0,6.
6. **Locator errado ou com a linha de hoje.**
   - Linhas que não existem: `Q_PARECER_SOBRE_DIFF_INVERTIDO` cita l.82-135 em arquivos de 53 e 36
     linhas.
   - A REGRA 64 citada pela linha de hoje (l.4659) e não pela de `f1cb21c9` (l.3476).
   - `D_FORGE_META_COMANDO` aponta a2734a63, que não contém a decisão.
   - `C_RFC4_INTER_INSTANCE` (l.67 → l.141) e o precedente OIDC no vaultwarden.
7. **Procura encerrada cedo e ausência afirmada que não existe.**
   - `E_whitespace_compliance`: o `personas.md` l.36 TEM "82%" e "FINRA".
   - `E_MERCADO_CAPITAL_MOTORES_1001` diz "nenhuma rodada", mas o journal tem "Cerbos raises $7.5M"
     cortada por orçamento. É o mesmo padrão do `E_MERCADO_OCR_LOCAL` da onda 1.
   - Fontes achadas pelo juiz: 4584d4c9, o PR #2 do onion-bridge, 3 resíduos do offsite,
     `logto-provision.sh@db8d9844`, 775569f1 e o README do onion-vps-logto em 617364f.
8. **Número datado não reproduzido no commit da data.** `E_CENSO_VENUE_IDIOMA_0904`: rodando o
   `langcensus.py` nos marketplace.json dos commits da data, os totais (2.282 e 291) batem, mas o
   comunitário tem pelo menos 14 descrições fora do inglês, 2 delas em chinês, e não 11.

## Itens para o maestro

**dev-dúvida: 0.**

**Flips de status: 3, contra 6 propostos.**

| nó | plano | flip | origem |
|---|---|---|---|
| `E_EXPERIMENT` | PROD | confirmed → **refuted** | proponente, confirmado ao vivo pelo juiz-mestre |
| `E_MEMORIA_DE_AGENTE_E_COMMODITY_PELO_DINHEIRO` | DEV | confirmed → unverifiable | proponente, confirmado |
| `E_ITEM6_VERIFY` | DEV | confirmed → unverifiable | proponente, confirmado |

Quatro flips propostos caíram e ficam `confirmed` com o label restrito:
`E_ANTIPADRAO_MEDIDO_EM_PRODUCAO`, `D_VIAVEL_COM_EXPECTATIVA_CALIBRADA`, `E_hybrid_pricing_trend` e
`C_OPT_DIARY_BRAIN`.

**PROD→DEV de nó `done`: 9.** Nenhum `superseded` sai de PROD, porque `E_SITE_LIVE` e
`C_TRES_FORMAS_DE_VERDE_SEM_OLHAR_0804` ficam.
- Do `bridge-produto`, todos do anexo: `F0_ALICERCE_FIACAO`, `F2_ESPINHA_THREADS`,
  `F3_ROSTO_REDESIGN`, `F4_GOVERNO_ADMIN`, `F5_PRACA_DIVULGACAO`, `F_ID_1_ADOCAO_LIMPA` e
  `F_ID_2_CONTEXTOS_ORG`. São relatos de fechamento de fase.
- `D_ESTUDAR_FAMILIA_ANTES_DE_CORRIGIR_0804`: o veto citado ("não podemos ficar mudando e
  bagunçando a doutrina") e a reversão do fix não aparecem em nenhum diário, documento ou
  transcript. Só as cláusulas técnicas têm fonte (#537).
- `I_A1_A_MEDICAO_CAIU_A_CONCLUSAO_SOBREVIVEU`: só o núcleo (403 no /identification) tem fonte.

**Outros PROD→DEV (não done), para ciência:** `C_MARKET_COMMODITY`,
`A_DOCUMENTACAO_LIDA_COMO_INVOCACAO_E_CLASSE_SISTEMICA`, `Q_F3_DECISOES_DE_ACABAMENTO` (open),
`Q_G5_DOGFOOD_GO_LIVE` (open), `E_DEMO_CAMPO_2026_08_14`, `E_SONDA_ENV_CONVIDADO_LIA_PRODUCAO` e
`E_ROLE_BRIDGE_USER_CARREGAVA_ADMIN`.

**`done` que ficam em PROD com outra classe** (o proponente pedia DEV):
`Q_QUATRO_PENDENCIAS_DO_TERRENO` vai para testemunho (775569f1), e `F_ID_3_SUPERFICIE` e
`F_ID_4_MGM` vão para corrigir-label.

**Status a rever** (fora do mandato, só sinalizado):
- `E_SEGUNDO_ADOTANTE_MESMA_CLASSE_DE_EXPOSICAO` está `open`, mas o vivo já o superou: o doc diz
  ENVIADO-2026-08-31, e a REGRA 64 (Compose sem bind local ou com segredo em fallback literal) nasceu
  em `f1cb21c9`.
- `Q_G5_DOGFOOD_GO_LIVE` está `open` com a janela vencida desde ~2026-08-21.
- `F_ID_4_MGM` duplica `F_ID_4_MGM_REFERRALS`: candidato a SUPERSEDES ou fusão.
- `A_DOCUMENTACAO_LIDA_COMO_INVOCACAO_…` diz que o item (4) está "VIVO", mas ele foi curado em
  c0623904, 30 minutos depois.

## Achados fora da provenance

1. **🔒 Segredo em claro em arquivo versionado.** Conferido pelo juiz-mestre.
   - `docs/evolution/review/chore-seal-queue-maestro.md` l.48 traz o nome do diretório restic
     acidental.
   - Pelo corpo de `dd89ddd4`, esse nome **é a senha atual do restic**.
   - Só registro: a rotação está parada por ordem do maestro, e nada é proposto. Fica uma pergunta
     a medir: se esse caminho viaja para a porta pública `onion-core`.
2. **O diário `2026-08-03-o-revisor-verde-que-nunca-revisou.md` l.27-28 é falso para 07-14..07-18.**
   O run 29621079157 (07-17) mostra o retry e o soft-pass disparando e comentando no PR #413. O
   "nunca disparou" só vale depois do pin v1.0.171, que silenciou a falha (sai exit 0 com
   `is_error`). Por isso `C_SOFTPASS_GAP` foi reescrito.
3. **`E_EXPERIMENT` sustenta a aresta REFUTES `C_MODEL_CAUSE`.** A conclusão de `C_MODEL_CAUSE`
   continua certa, porque a causa real foi a chave 401, mas a aresta de suporte cai com o refutar.
4. **Labels truncados no próprio grafo**, em exatamente 340 caracteres e no meio da frase:
   `E_CENSO0901_D_NO_DISTORT` e `E_CENSO0901_C_COMPLIANCE_RARE`.
5. **Contagens erradas em `verified_against` e em corpos de commit:**
   - `E_MERCADO_COMPANY_BRAIN_E_METODO_1001` diz "7 fontes lidas", e o run leu 26;
   - `E_O_BACKLOG_ESTAVA_NO_TETO_…` diz "10 open", e o proponente contou 4;
   - o corpo de 15824241 diz "66 claims sem verificação", e o journal diz 31.
6. **`docs/analysis/elenxo-mecanismos-lint-2026-08-13.md` l.118-119 repete a "inversão da lente"**,
   que o registro do grafo em 0e087e04 l.81 contradiz.
7. **A provenance atual de `D_QUATRO_PILARES_DEFINIDOS_PELO_MAESTRO`**
   (`onion-doctrine-elenxo-bulbo`) aponta como `source` o grafo nanochat, e não o transcript. É
   herança da migração, nunca re-verificada. Candidata a uma próxima onda.

## Tetos

1. **O juiz é da mesma família de modelo.** As 306 linhas foram julgadas por 7 workers
   independentes do proponente, cada um abrindo a fonte. O juiz-mestre conferiu ao vivo:
   - os 3 runs e os 2 PRs de `E_EXPERIMENT`;
   - o brief 21213cc6 dos números de mercado do gtm;
   - o achado do restic;
   - status e plano de todo `rebaixar`/`refutar`/`dev-*` final;
   - cobertura (306/306, sem duplicata), forma `<classe>: ` do method, label ≤280 em todo
     corrigir-label e label vazio nos demais.

   Sobrescreveu 6 vereditos de worker (`E_EXPERIMENT`, `C_OPT_DIARY_BRAIN` e os 4 do gtm). Os demais
   são dos workers.
2. **Journals no host e clones em `/home/marcio/`** só se reabrem nesta máquina. Três journals
   citados não existem no host: `wf_2944480c-98f`, `wf_bde10f3f-28c` e `wf_9487391f`.
3. **0 REPROVADO é um sinal a desconfiar, não um mérito.** Os workers preferiram reescrever o label
   a devolver. Cada reescrita foi conferida contra a fonte aberta, mas os 73 corrigir-label finais
   são texto do juiz que nenhum terceiro releu. O selo do maestro sobre eles é a última barreira.
4. **Busca externa no teto.** O DuckDuckGo devolveu vazio, e a primária do 43%→61% (Bessemer) não
   foi achada. O primário de `C_AXIS_HOT` (YC RFS Summer 2026) segue não verificado, porque a página
   é montada no navegador.
5. **URLs, READMEs e `gh run` medidos uma vez, em 2026-10-09.** Os artefatos de run do Actions
   expiram.

Orquestrado com 🧅 Onion Evolve
