# O3 onda 1 — veredito do juiz independente (2026-10-09)

Este é o veredito do juiz sobre `o3-wave1-proposta.csv` (276 nós em 37 grafos), sob
`D_POLITICAS_DA_MIGRACAO_DE_PROVENANCE` e o modo da O3. O mandato era refutar, com
REPROVADO como default na dúvida. **Nada foi aplicado nos grafos.** Todo flip de status listado
abaixo passa pelo selo do maestro.

A planilha completa está em `o3-wave1-juiz.csv`, com uma linha por nó e o motivo de cada decisão
em uma linha.

## Concordância

**184 / 276 APROVADO (66,7%)**, 80 CORRIGIDO e 12 REPROVADO. Os REPROVADOS voltam ao proponente.

| veredito | nós |
|---|---|
| APROVADO | 184 |
| CORRIGIDO | 80 |
| REPROVADO | 12 |

Dos 80 CORRIGIDOS, 61 mantêm a proposta e trocam fonte, locator ou method. Os outros 19 mudam a
proposta.

## Matriz proposta original × final

Os REPROVADOS aparecem numa coluna própria: o nó não tem desfecho final.

| original \ final | corrigir | testemunho | rebaixar | dev-óbvio | dev-dúvida | REPROVADO | total |
|---|---|---|---|---|---|---|---|
| corrigir | 220 | 7 | 4 | — | — | 10 | 241 |
| testemunho | 2 | 18 | 4 | — | — | 1 | 25 |
| rebaixar | — | — | 3 | — | — | 1 | 4 |
| dev-óbvio | 1 | — | — | 4 | 1 | — | 6 |
| **total** | **223** | **25** | **11** | **4** | **1** | **12** | **276** |

Os 4 nós `rebaixar` que vieram de `corrigir` são os quatro `E_R3_TST_*`.

## Os casos que o proponente apontou

- **Os 4 `E_R3_TST_*` vão para rebaixar.** O ancorador marcou ANCORADA sobre uma "ementa oficial"
  sem processo, órgão nem data. A objeção R3 que sobreviveu registra quote vazia e locator "—".
  O motor curado (`onion-research.js` l.248-256) rebaixa exatamente esse caso para
  AFIRMADA-SEM-CITACAO. O veredito de um juiz LLM sobre citação sem localizador não é fonte do que
  o TST decidiu. Recuperação possível: o RR-613/2000-013-10-00.7 é o candidato nomeado na rodada 2,
  mas o dossiê não liga a ementa a ele, e a busca externa do juiz não achou nada. **Não é fonte.**
- **`E_LACUNAS_INFRA_VPS_1005` e `E_LACUNAS_DECLARADAS_OCR_0908`: rebaixar APROVADO.** O journal
  versionado desmente os números do label.
- **`E_LACUNAS_CORPUS_DE_REGRAS_1001`: testemunho APROVADO.** O erro está só no `verified_against`.
- **`E_LACUNAS_DECK_PATTERNS_0924`: testemunho virou rebaixar.** O journal tem 14 objeções que
  sobrevivem, contra "6 sobreviventes" no label. E o "17 fontes, 10 claims" atribuído ao
  sintetizador não está no journal.
- **`E_MERCADO_OCR_LOCAL_0908`: testemunho virou rebaixar.** O próprio journal tem uma claim de
  capital em `notVerifiedByBudget`: "Datalab captou US$3,5M seed". Isso contradiz o "SEM SINAL
  ENCONTRADO".
- **`E_MD_PICO_APRESENTADO_COMO_REGUA`: testemunho virou rebaixar.** O trendshift abre com
  User-Agent de navegador; o 403 era do cliente. A página `trendshift.io/repositories/46562`
  contradiz o label: o pico durou dois dias (18 e 19/08), a linguagem é TypeScript e não
  JavaScript, e não há entrada de 25/08.
- **`E_LACUNAS_DECLARADAS_PODA_0903`: testemunho virou rebaixar.** O journal `wf_ab17f8d6-773` não
  existe no host, e a SYNTHESIS (l.46 e l.52) contradiz as contagens do label.
- **`E_FRAGMENTACAO_NAO_ABSORCAO` fica como testemunho.** A origem é datada (commit 6850818d da
  sessão), o method é `testemunho: medição da sessão 2026-08-16, comando não registrado` (política
  2), e os repos citados existem hoje.
- **`E_O_GATE_DO_ADOTANTE_…` e `E_O_CORPUS_NAO_TRANSFERE_…` ficam como testemunho válido.** Os corpos
  de 49f12f42 e 614e35b6 estão em primeira pessoa ("medi"). No primeiro, o method foi ajustado.
- **`E_ESTUDO_SO_O_SHLEX_…` fica como medição.** O comando está registrado no `verified_against`, e
  o juiz o reproduziu.
- **Os 5 nós do `m2-bridge-logto` ficam como testemunho, APROVADOS.** Os corpos de commit registram
  a observação da sessão em primeira pessoa, com data e link Claude-Session. A exceção é
  `E_timeout_is_load_bearing`: o 82da1e1a registra um experimento reproduzível, e o juiz o
  re-rodou (3,016 s). Esse nó virou medição.
- **Os dev-óbvio:**
  - Os três `Q_RISCO_*` e `D_INDIVIDUAL_ORGANIZATION_SHARING_CRITERION` foram APROVADOS.
  - `D_TRIADE_MCP_POR_EIXO` virou corrigir, porque a decisão está construída: existem
    `ops/mcp-onion-{kg,exec,framework}` e o commit 5f610327 (#645).
  - `Q_TENANT_WRITE_DESTINATION` virou dev-dúvida.
- **Achados laterais do proponente, conferidos:**
  - `C_V1` foi REPROVADO: o arandek tem 70 SKILL.md, e o label diz 71.
  - `ENT_KB_CORE` foi REPROVADO: o label sem data diz "não mesclada", mas o 0dcacbb1 mesclou a KB 20
    minutos depois.

## Padrões de erro do proponente

1. **"Sustenta" declarado sobre fonte que cobre só parte do label.** É o padrão dominante e a
   origem dos 12 REPROVADOS. O proponente chegou a anotar a divergência e manteve `corrigir` mesmo
   assim (`E_WIRE_IN_LIVE`, `E_RESPAWN`, `E_O_MANIFESTO`). Outros casos são cláusulas sem fonte
   nenhuma (`C_ASYNC_REPO`, `E_PLANO_NASCEU_…`, `E_W8_CONSOLE_AUTOOFF_VIVO`, `E_a2a_is_not_vaporware`).
2. **Re-medição no estado de hoje tratada como fonte de um número datado.** Exemplos:
   - estrelas 8611 contra 5.2k;
   - o resolvedor com 23 contra 14;
   - `main` de hoje com 315 plugins contra 291 em 9a82e830;
   - `testing-inventory` com 1590 contra 913;
   - binário 2.1.295 contra o 2.1.289 do label;
   - o granaai "bate" hoje, mas `.githooks` não existe.

   A cura foi fixar a fonte no commit da data.
3. **Classe de method errada.**
   - medição onde não há comando registrado: resíduo em git (deveria ser leitura) ou relato da
     sessão (deveria ser testemunho);
   - juízes onde o campo é `"juiz": "N/A"` (`E_REFUTA_D_pkce`);
   - medição para commit em outro repo, que é leitura (`E_V1_COMMITS`);
   - leitura do grafo onde há veredito adversarial (`E_REFUTACAO_DA_PROPOSTA_DE_RAIO`);
   - template fixo "re-buscou a primária, confirmed", aplicado onde a própria nota diz o contrário
     (`C_H1_04`, `C_H4_F4` e os três `E_*_CORR` do scope-inheritance).
4. **Fonte recuperável perdida, procura encerrada cedo.**
   - threads HN de `E_DOR_…` e `E_CONCORRENTE_…`;
   - PoC clonada em `/home/marcio/poc-venda-direta-pdi`, que transforma testemunho em leitura;
   - `d8434efc`, `be29ab00` e o cabeçalho do radar `ff6c22a6`;
   - commit durável 611329a1 no `onion-adopt-arandek`;
   - RFC-0005 aceito, no lugar do SYNTHESIS, que se declara não-decisório, como fonte de 4 decisões.
5. **Rebaixar quando havia fonte (o inverso).** Em `E_DOR_DOMINANTE_…` a fonte parcial existia. Mesmo
   assim o nó ficou REPROVADO, porque os relatos "50k+ tokens" e "US$2→US$8" não foram localizados.
6. **Locator impreciso.** Linha errada (`C_POROSITY_STRUCTURAL` l.99→44, `C_a2a_gate_narrow` l.26→28,
   vários outros), locator descritivo em vez de lugar, e erro de cópia (19 âncoras em vez de 27).
7. **Escolher a classe pelo trecho medível, e não pelo fato central do label.** É o caso de
   `E_OBJECAO_6_CATRACA_…`: o núcleo é a sobrevivência da objeção, que só existe no journal do
   host, então o nó vira testemunho.

## Itens para o maestro

**dev-dúvida (1)**
- `Q_TENANT_WRITE_DESTINATION` (open, PROD). É questão de desenho gated, mas o label afirma um estado
  vivo ("hoje toda proposta cai no core"), e `E_KG_INBOX_ROTEIA_POR_PAPEL_0905` já fechou metade dele.

**Flips de status: 11, todos `confirmed → unverifiable`.** Nenhum rebaixamento de status diferente de
`confirmed`. São 9 nós DEV, rebaixados como correção de verdade, e 2 nós PROD.

| nó | plano | origem |
|---|---|---|
| `E_R3_TST_CIENCIA_PREVIA_AFASTA_EXPECTATIVA` | DEV | juiz (era corrigir) |
| `E_R3_TST_EMAIL_PESSOAL_VS_CORPORATIVO` | DEV | juiz (era corrigir) |
| `E_R3_TST_MONITORAR_FORMA_E_CONTEUDO_EMAIL_CORPORATIVO` | DEV | juiz (era corrigir) |
| `E_R3_TST_PROPORCIONALIDADE_PARCIMONIA_NA_ILICITUDE` | DEV | juiz (era corrigir) |
| `E_LACUNAS_DECK_PATTERNS_0924` | DEV | juiz (era testemunho) |
| `E_MERCADO_OCR_LOCAL_0908` | DEV | juiz (era testemunho) |
| `E_LACUNAS_DECLARADAS_PODA_0903` | DEV | juiz (era testemunho) |
| `E_MD_PICO_APRESENTADO_COMO_REGUA` | PROD | juiz (era testemunho) |
| `E_LAND_EXPAND` | PROD | proponente, confirmado |
| `E_LACUNAS_DECLARADAS_OCR_0908` | DEV | proponente, confirmado |
| `E_LACUNAS_INFRA_VPS_1005` | DEV | proponente, confirmado |

**dev-óbvio sobre nó não-confirmed** (muda o plano, não o status)
- `D_INDIVIDUAL_ORGANIZATION_SHARING_CRITERION` é **done** em PROD: o flip tira um done de PROD.
- Os três `Q_RISCO_*` são open em PROD. Em `Q_RISCO_PLATAFORMA_COME_O_GATE`, a issue #34556 que o
  label diz "sem resposta" já está fechada.

**12 REPROVADOS: nós confirmed com uma cláusula falsa ou sem fonte.** O que eles pedem é corrigir ou
cindir o label, não carimbar provenance.
- `E_O_MANIFESTO_QUE_FALHA_COPIAVA_TUDO`, `E_WIRE_IN_LIVE`, `E_RESPAWN_JA_EXISTIA_E_A_CASA_NAO_SABIA`
- `E_A_GUARDA_VETOU_O_PROPRIO_MAESTRO`, `C_V1`, `ENT_KB_CORE`, `C_ASYNC_REPO`
- `E_W8_CONSOLE_AUTOOFF_VIVO`, `E_a2a_is_not_vaporware`, `E_PLANO_NASCEU_DE_TRES_MEDICOES`
- `E_DOR_DOMINANTE_E_CONTEXTO_E_CUSTO`
- `C_OBJECAO_ESTADO_PODE_NAO_BASTAR_EM_TIME_MINIMO`: o dev-óbvio de um worker não se aplica a um nó
  que já é DEV, e a cláusula "quem fecha é a camada 4" foi refutada.

**Achados laterais de defeito vivo** (fora do escopo da provenance)
- **`/meta:adopt`: o abort do manifesto é inerte.** Este o juiz conferiu ao vivo. Em
  `.claude/commands/meta/adopt.md`, l.112-113 e l.737-738, o código faz
  `mapfile -t manifest < <(resolve-manifest.sh …) || ABORTADO`. Reproduzido:
  `mapfile -t m < <(echo a; exit 3) || echo ABORT` dá rc=0 e não aborta. O `mapfile` engole o rc do
  produtor, e nada conta o array antes de `git archive HEAD -- "${manifest[@]}"`. O vazamento que
  `E_O_MANIFESTO_QUE_FALHA_COPIAVA_TUDO` diz curado continua alcançável. O próprio comentário da
  l.109 diz "`mapfile` engole rc".
- **Logto com registro aberto.** É sinal de worker, não re-medido pelo juiz-mestre.
  `GET https://auth.onionevolve.com/api/.well-known/sign-in-exp` devolveu `signInMode:
  SignInAndRegister`. O `logto-provision.sh` se contradiz: a l.811 diz que é de propósito (P3.4),
  e a l.468 e o corpo de b5e5d086 dizem fechado. Confirmar se é intencional.

## Tetos

1. **O juiz também é da mesma família de modelo.** As 276 linhas foram julgadas por 7 workers
   independentes do proponente, que é outro contexto. O juiz-mestre conferiu ao vivo só uma
   amostra:
   - o defeito do `mapfile`;
   - o journal TST;
   - os nós `C_OBJECAO` e `E_DOR`, cujos vereditos sobrescreveu para REPROVADO;
   - a cobertura, a ausência de duplicata, a forma do method e o status/plano de todo
     `rebaixar`/`dev-*`.

   Os demais 270 vereditos são dos workers, com a fonte aberta por eles.
2. **A busca externa ficou no teto.** O DuckDuckGo devolveu página bloqueada. A recuperação do
   acórdão TST e dos relatos do `E_DOR` não foi esgotada, e a busca de comentários do HN (Algolia)
   falhou ao decodificar.
3. **Journals no host e clones em `/home/marcio/`** só se reabrem nesta máquina. O
   `/home/marcio/onion-bridge` não existe; o clone usado foi o `onion-bridge-dev`.
4. **URLs medidas uma vez, em 2026-10-09.** O trendshift exige User-Agent de navegador.
5. **`E_CORPUS_VAZIO_OCR_0908` foi aprovado com ressalva.** O total de 3289 nós não reproduziu: o
   parse do worker deu 3437 em 88 grafos legíveis.
6. **"Sustenta o label" continua sendo leitura, não métrica.** No scope-inheritance, o casamento
   label↔nota foi conferido por script (literal, sem formatação). Nos demais grafos, foi por leitura.
