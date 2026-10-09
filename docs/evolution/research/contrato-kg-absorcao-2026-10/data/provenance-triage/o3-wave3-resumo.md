# O3 onda 3: proposta do proponente, com a revisão da onda 1 (2026-10-09)

Esta é a projeção da proposta da onda 3 da O3 (SAC-73), feita sob `D_POLITICAS_DA_MIGRACAO_DE_PROVENANCE`
e os selos do maestro de 2026-10-09. **Nada foi aplicado nos grafos.** A próxima etapa é um juiz
independente refutar esta planilha. Todo flip de status ou de plano passa pelo selo do maestro.

## Escopo (`o3-wave3-proposta.csv`, 312 linhas)

| origem | o quê | nós |
|---|---|---|
| `onda3` | o universo O3 nos 38 grafos da onda 3 (`o3-waves.tsv`) | 276 |
| `onda3` | os nós PROD apoiados só em testemunho, segundo o v4.1 (`v41-testimony-in-prod.tsv`), nos mesmos grafos | 18 |
| `revisão-onda1` | os 12 REPROVADOS da onda 1, os 5 da classe "fonte contradiz o label" e `E_O_GATE_DO_ADOTANTE_ESTA_INERTE_EM_4_DE_6` | 18 |

Os 18 de testemunho em PROD **não estão** no universo O3, porque já têm provenance. Eles entraram com
`origem=onda3`, que é a onda dos grafos deles. A pergunta para cada um foi: há fonte versionada, então
sai do testemunho; é decisão, plano ou retrato datado, então vai para DEV; ou só o host confirma, e
fica como testemunho.

A planilha foi conferida mecanicamente:
- 312 linhas, sem duplicata e sem nó faltando;
- cada `method` tem a forma `<classe>: <detalhe>`, com a classe na lista;
- `dev-*` só aparece em PROD, e `rebaixar` só em `confirmed`;
- `label_novo` só aparece em `corrigir-label`.

## Contagens

| proposta | onda3 | revisão-onda1 | total |
|---|---|---|---|
| corrigir | 168 | — | 168 |
| corrigir-label | 42 | 16 | 58 |
| dev-óbvio | 47 | 1 | 48 |
| testemunho | 37 | 1 | 38 |
| rebaixar | 0 | — | 0 |
| refutar | 0 | 0 | 0 |
| dev-dúvida | 0 | — | 0 |

Por status e plano do nó hoje:

| status | plano | corrigir | corrigir-label | testemunho | dev-óbvio |
|---|---|---|---|---|---|
| confirmed | DEV | 62 | 13 | 22 | — |
| confirmed | PROD | 82 | 34 | 15 | 28 |
| done | PROD | 3 | 1 | — | 8 |
| open | PROD | 15 | 5 | 1 | 3 |
| refuted | PROD | 3 | — | — | 3 |
| superseded | PROD | 3 | — | — | 6 |
| unverifiable | DEV | — | 4 | — | — |
| unverifiable | PROD | — | 1 | — | — |

Classes de `method` nas 306 linhas que trazem método: leitura 168, testemunho 60, juízes 55,
medição 17 e derivado 6.

**Flips propostos, todos para o selo do maestro:**
- **48 `dev-óbvio` (PROD → DEV).** Destes, 28 são `confirmed`, 8 `done`, 6 `superseded`, 3 `open` e
  3 `refuted`.
- **5 `unverifiable → confirmed`.** São os 5 da classe "fonte contradiz o label", que a onda 1 rebaixou
  e que agora voltam com o label corrigido pela fonte.
- **Nenhum `confirmed → unverifiable`.**

## Por que zero rebaixamentos

A heurística previa 71 `U:vazio` e 11 `U:prosa`. Na prática, todo nó `confirmed` desta onda tinha fonte
recuperável, como já acontecera na onda 1:
- **irmãos versionados:**
  - `maestro-vivo/data/f2-confronto.json` e `f1-scan-mundo.json`;
  - `census-2026-09-01/data/rodada1.json`;
  - SYNTHESIS e `data/*.txt` dos radares;
  - `docs/analysis/company-brain-market-2026-07.md`;
  - `docs/business-context/d5-pricing-brief-2026-07.md`;
- **resíduos R56** e o inbox `_processed`;
- **corpos de commit datados e em primeira pessoa** (waha, email-logto);
- **journals no host**, que viram testemunho pela política 8.

O padrão 4 da onda 1 (busca de fonte encerrada cedo) foi o mais cobrado dos workers. Cada linha diz onde
a busca foi feita.

## O que mudou por causa dos padrões de erro da onda 1

- **"Sustenta" parcial.** Uma cláusula falsa ou sem fonte levou a `corrigir-label`, e nunca a
  `corrigir` com a divergência só anotada. São 42 casos na onda 3. Os principais:
  - **maestro-vivo (18):**
    - quatro nós dizem "sobreviveu ao Elenxo", mas o `f2-confronto.json` (l.326, 330, 334 e 372) os dá
      como derrubados. O erro veio do casamento por 40 caracteres na SYNTHESIS;
    - os números "F1 #N" estão deslocados em um, porque a lista foi contada a partir de 0 (Elenxo,
      l.407 e l.441);
    - as emendas do Elenxo derrubam cláusulas das teses;
    - os baselines da catraca contam linhas de cabeçalho.
  - **federation-reconciled (7):** "6 camadas" é na verdade 0-6, ou seja, 7; a data da última entrada do
    trust-log é 07-01, não 07-03.
  - **company-brain:** "20 ADRs promovidos" é na verdade 13 (#835); saem cláusulas sem fonte em
    `E_player_*`.
  - **m8-serial (3):** três labels não acompanharam a correção de a8b6cfb7 e 8b005f65.
  - **KARMA:** a citação MAB **não** é alucinada. Ela está na v1 do paper (§3.3); a v2 a removeu.
  - **Lacunas zoho, onda-derivada e plugin-mcp:** as contagens foram trocadas pelas do journal.
- **Número datado fixado na data.** Os workers fixaram as fontes nos commits de criação:
  - federation-reconciled, em `4e54b052^`, deu 292/42/13 (contra `4e54b052`, daria 293/14);
  - o baseline da catraca em `9b251104`;
  - o brief d5 em `9c42cfcf`;
  - o `marketplace.json` em `7fbbff80`;
  - o changelog do `E_RESPAWN` pelo deslocamento de +1550.
- **Classe de `method`.**
  - `juízes` só onde há veredito registrado: `f2-confronto.json`, `rodada1.json` (`"juiz": "APROVADO"`),
    `E_J_*` (wf_01b63531) e Elenxo `wf_fa9e6ad4`.
  - Fonte de host vira `testemunho`, mesmo em `corrigir-label` (política 8), o que dá **6 casos** (ver
    teto 2).
  - `medição` só com comando registrado e reproduzido.

## Revisão da onda 1 (18)

- **12 REPROVADOS → 11 `corrigir-label` e 1 `testemunho`.** Nenhum caiu inteiro.
  - **`E_O_MANIFESTO_QUE_FALHA_COPIAVA_TUDO`:** "curado" vira "NÃO curado". O defeito do `mapfile` no
    `adopt.md` (l.112 e l.737) foi reproduzido hoje: `mapfile -t m < <(exit 3) || echo ABORT` não aborta.
  - **`E_WIRE_IN_LIVE`:** sai "wired em lint-artifacts.sh", que tem 0 ocorrências em `96d2beae`.
  - **`E_RESPAWN_…`:** a versão é 2.1.144, não 2.1.145.
  - **`E_A_GUARDA_VETOU_…`:** o log do dogfood foi recuperado no host. A latência é de cerca de 9 h, não
    de 20 min.
  - **`C_V1`:** são 70 skills, não 71, e "tirado do versionamento" no lugar de "perdido".
  - **`ENT_KB_CORE`:** o label ganha o merge `0dcacbb1`, datado.
  - **`C_ASYNC_REPO`:** sai "escala sem chat".
  - **`E_W8_CONSOLE_AUTOOFF_VIVO`:** o `off` não para o timer, e sai o motivo sem fonte.
  - **`E_a2a_is_not_vaporware`:** sai o handshake `hs-real-1783806004`, ausente do state de replay vivo.
  - **`E_DOR_DOMINANTE_…`:** os relatos foram recuperados no HN (47400262 e 47780622), e "dor #1" vira
    "dor recorrente".
  - **`C_OBJECAO_ESTADO_…`:** o label registra a refutação de 09-19 e o escopo n=3.
  - **`E_PLANO_NASCEU_DE_TRES_MEDICOES` vai para `testemunho`.** A cláusula (c) só existe no transcript
    do host, de 2026-09-07.
- **Os 5 da classe "fonte contradiz o label" → `corrigir-label`.** As contagens foram tiradas do journal
  por script, e o comando está na evidência.
  - Só `E_LACUNAS_INFRA_VPS_1005` tem o journal versionado (`infra-vps-2026-10/data/wf_b5f60320-80d.json`)
    e fica com `leitura`.
  - O `E_MD_PICO` também fica com `leitura`: a fonte é a página do trendshift (HTTP 200 com User-Agent de
    navegador). Ela mostra #1 só em TypeScript, em 18 e 19/08, e nenhuma entrada depois de 20/08.
  - Os outros três journals só existem no host (`git ls-files` não os acha), e ficam com
    `testemunho: leitura do arquivo … no host`.
- **`E_O_GATE_DO_ADOTANTE_ESTA_INERTE_EM_4_DE_6` → `dev-óbvio`,** como já selado. O corpo de 49f12f42
  (16/08, em primeira pessoa) foi conferido.

## Casos de baixa confiança (< 0,65)

| nó | proposta | conf. | por quê |
|---|---|---|---|
| `E_LACUNAS_ONDA_DERIVADA_1001` | corrigir-label | 0,55 | lê "entregues" como o que chegou à sessão (11 de 20 objeções); a divergência 15/16 nós não fecha |
| `E_TOPO_NASCEU_NUMA_RAJADA_E_NAO_SE_MOVEU` | corrigir | 0,55 | re-derivado sobre a projeção de 08-28: 15/15, não 12/15; o escopo da tabela é outro |
| `E_ONION_MEDIDO_LOCAL_0904` | corrigir-label | 0,55 | 544 vira 531 (medição da mesma data); o escopo de 544/124 não foi reconstruído |
| `E_LACUNAS_DECLARADAS_PLUGIN_MCP_0904` | testemunho | 0,55 | a lista dos 10 refutados só está no grafo; o journal não está no host |
| `E_LACUNAS_KG_MULTI_GRAPH_0904` | testemunho | 0,55 | o tier, o "zero falhas" e a lista (C) só estão no nó; o journal não está no host |
| `E_LACUNAS_DECLARADAS_WEBSEARCH_CAP_0902` | testemunho | 0,60 | "25 fontes / 1 refutada / 0 cortadas" só no nó; o journal não está no host |
| `E_MERCADO_SEM_SINAL_WEBSEARCH_CAP` | testemunho | 0,60 | o mesmo run, sem journal |
| `E_CENSO0901_D_mais_valor` | corrigir | 0,60 | o label está truncado; o commit fae0b529 sustenta por interpretação do diff |
| `E_LEVA_NAO_SERVE_COMO_UNIDADE` | testemunho | 0,60 | os PRs #890/#891 existem, mas "24 achados" não tem fonte |
| `E_VERIFY_APPROVED` | corrigir-label | 0,60 | sai "mutation test provou", sem registro |
| `E_GRADE2606_DIAGNOSTICO_NAO_REORDENA` | corrigir | 0,60 | "explicitamente pós-hoc" é leitura do worker |
| `E_REDDIT_INACESSIVEL_DESTE_HARNESS` | testemunho | 0,60 | o WebFetch da sessão sem registro, só a síntese e o commit c5bf7fd4 |
| `E_SGH2604_ESCOPO_EXCLUI_GRAFO_EPISTEMICO` | corrigir-label | 0,60 | só a aspa é inexistente; o reparo pode ser pequeno demais |
| `ENT_whatsapp` | testemunho | 0,60 | estado vivo que só o host confirma (sudo) |
| `D_HOOK_PREMODELSWITCH_GUARDA` | dev-óbvio | 0,60 | label de proposta num nó `done` com veto vivo; `testemunho` seria defensável |

Para o juiz olhar também, mesmo acima de 0,65:
- **`C_TESE_MOAT_GATES`:** mantém "64 REGRAS", contra os 63 do Elenxo F2.
- **`Q_GMILL_MAIN_DIVERGIU`:** a medição é de comando registrado, mas o clone avançou em 10-05.
- **`REC2_A2A_FORMAT_BUILT_WITHOUT_TRIGGER`:** o repo diverge entre 6 e 7 camadas.
- **`E_MERCADO_OCR_LOCAL_0908`:** a consequência foi reescrita a partir da recomendação do journal.

## Achados laterais (fora da provenance)

- **O abort do manifesto do `/meta:adopt` segue inerte hoje.** Reconfirmado pelo worker da revisão. É o
  mesmo achado do juiz da onda 1.
- **`verified_at`/`verified_against` com contagens erradas fora do label:**
  - `E_LACUNAS_DECLARADAS_PLUGIN_MCP_0904` diz 36 fontes e 18 claims, contra 15 e 43 na SYNTHESIS l.24;
  - o Zoho diz 16 fontes colhidas, contra 18 no journal.
- **Truncagem do payload do Elenxo para o escritor do grafo.** O mesmo defeito curado depois em
  `fix/research-elenxo-not-truncated` explica as divergências de contagem de objeções em Zoho,
  onda-derivada e infra-vps (19, 20 e 27 sobreviventes, contra 6, 11 e 12 modeladas).

## Tetos

1. **O proponente não é o juiz.** As 312 linhas foram escritas por 10 workers da mesma família de modelo,
   com as mesmas instruções (7 lotes de 42 por grafo inteiro, mais 3 lotes de 6 da revisão). A confiança é
   autoavaliada. O proponente-mestre conferiu a forma das 312 linhas e uma amostra de 6 `corrigir`
   (semente 20261009) com `grep -n` nos locators. O conteúdo das demais fontes foi aberto pelos workers.
2. **`corrigir-label` com `method` de testemunho: 6 casos.** São os journals só no host, um choque entre a
   regra 2 ("`method: leitura`") e a política 8 ("fonte de host é testemunho"). O proponente seguiu a
   política 8. O juiz decide se o label novo pode se apoiar em testemunho.
3. **Os `label_novo` foram escritos pelos workers.** Na aplicação, eles mudam texto de nó, o que vai além
   de carimbar provenance. O juiz deve conferir cláusula a cláusula contra a fonte citada.
4. **48 `dev-óbvio` é bem mais que os 6 da onda 1.** A onda 3 tem grafos inteiros de doutrina gated
   (telescope, 11), decisões seladas e não implementadas (rito, distribuição) e retratos datados (waha,
   censos). O critério foi "não descreve o sistema vivo". O juiz pode preferir `testemunho` em alguns
   retratos datados.
5. **Journals ausentes do host:** `wf_9dad8645`, `wf_9ad3aba7`, `wf_bb97173d`, `wf_2944480c`, `wf_90dd73fe`,
   `wf_8a8eca55`, `wf_86dccc06`, `wf_8cf0e944` e `wf_1c9263d8`. Os nós que dependiam deles foram
   sustentados por irmãos versionados ou ficaram como testemunho de baixa confiança.
6. **URLs medidas uma vez, em 2026-10-09.** O trendshift exige User-Agent de navegador, e várias URLs do
   company-brain dão 404/403 hoje. Por isso a fonte que vale é o relatório versionado de 25/07.
