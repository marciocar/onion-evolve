# O3 onda 3: veredito do juiz independente (2026-10-09)

Este é o veredito do juiz sobre `o3-wave3-proposta.csv`: 312 nós, sendo 294 da onda 3 e 18 da revisão da
onda 1. O julgamento seguiu `D_POLITICAS_DA_MIGRACAO_DE_PROVENANCE` e os selos do maestro de 2026-10-09.
O mandato era refutar, e na dúvida o veredito é REPROVADO.

**Nada foi aplicado nos grafos.** Todo flip de status ou de plano listado abaixo passa pelo selo do maestro.

A planilha completa está em `o3-wave3-juiz.csv`, com uma linha por nó e o motivo em uma linha. Todo
`label_final` tem 280 caracteres ou menos, o que foi conferido por script.

## Concordância

**218 de 312 APROVADO (69,9%).** Além deles, 91 foram CORRIGIDOS e 3 REPROVADOS.

| veredito | onda3 | revisão-onda1 | total |
|---|---|---|---|
| APROVADO | 213 | 5 | 218 |
| CORRIGIDO | 78 | 13 | 91 |
| REPROVADO | 3 | 0 | 3 |

Dos 91 CORRIGIDOS:
- 65 mantêm a proposta e trocam fonte, locator, method ou label. Na maioria, o que muda é o label, por
  causa do teto de 280 caracteres.
- 26 mudam a proposta.

## Matriz: proposta original × final

| original \ final | corrigir | corrigir-label | testemunho | rebaixar | refutar | dev-óbvio | dev-dúvida | REPROVADO | total |
|---|---|---|---|---|---|---|---|---|---|
| corrigir | 162 | 4 | 1 | — | — | — | — | 1 | 168 |
| corrigir-label | 10 | 46 | — | — | — | — | — | 2 | 58 |
| testemunho | — | — | 38 | — | — | — | — | — | 38 |
| dev-óbvio | 5 | — | — | — | — | 37 | 6 | — | 48 |
| **total** | **177** | **50** | **39** | **0** | **0** | **37** | **6** | **3** | **312** |

## Os casos de baixa confiança do proponente (15)

| nó | proposta | veredito | final | por quê |
|---|---|---|---|---|
| `E_LACUNAS_ONDA_DERIVADA_1001` | corrigir-label | **REPROVADO** | — | Journal reaberto: 19/17/0/64/16 confere, e o "11 entregues" é de fato contradito. Mas o label novo tem 1770 caracteres, afirma o que o journal não diz ("o repasse trouxe só F1-F11", fusão em pares) e tira "15 nós" por conta errada: 19 achados com 4 fusões dão exatamente 15, e o 16º contado é o `E_MERCADO`, que é síntese. |
| `E_TOPO_NASCEU_NUMA_RAJADA_E_NAO_SE_MOVEU` | corrigir | CORRIGIDO | corrigir-label | Nem o 12/15 do label nem o 15/15 do proponente. O 15/15 saiu das 15 primeiras linhas do `backlog.md`, que é agrupado por grafo. Ordenada por atenção, a projeção `84c659e9` dá **10/15**, e a própria tabela da SYNTHESIS (l.131-143) bate com isso. Re-derivado pelo juiz-mestre: os 4 empates em 20.0 nas posições 14 e 15 não mudam o resultado. |
| `E_ONION_MEDIDO_LOCAL_0904` | corrigir-label | CORRIGIDO | corrigir-label | O 531 se sustenta (`dcd1c3ee`, SYNTHESIS l.31). Mas o label novo tinha cerca de 650 caracteres e chamava de falsa a cláusula do `version` por entrada, que `ec648fce` confirma como intencional. |
| `E_LACUNAS_DECLARADAS_PLUGIN_MCP_0904` | testemunho | CORRIGIDO | testemunho | O locator SYNTHESIS l.24 **contradiz** o `verified_against` (15 fontes e 43 claims). Foi trocado por l.56, l.60 e o resíduo l.5. A origem ficou explícita. |
| `E_LACUNAS_KG_MULTI_GRAPH_0904` | testemunho | APROVADO | testemunho | A origem é explícita (`wf_bb97173d`, `a71023c6`) e a SYNTHESIS confere 10/15. O tier e as partes (A) e (C) só existem no nó. Confiança 0,55. |
| `E_LACUNAS_DECLARADAS_WEBSEARCH_CAP_0902` | testemunho | APROVADO | testemunho | O journal está ausente do host. A origem é explícita (run, data, `725fff11`) e o nó já é DEV. |
| `E_MERCADO_SEM_SINAL_WEBSEARCH_CAP` | testemunho | APROVADO | testemunho | O mesmo run da linha anterior. |
| `E_CENSO0901_D_mais_valor` | corrigir | CORRIGIDO | testemunho | `fae0b529` não sustenta "deixou de ser a promessa, virou só rótulo de SEO". O selo da home ainda é "Company Brain". É juízo do worker do censo. |
| `E_LEVA_NAO_SERVE_COMO_UNIDADE` | testemunho | APROVADO | testemunho | Os PRs #890 e #891 existem; os "24 achados" só têm origem na sessão. |
| `E_VERIFY_APPROVED` | corrigir-label | **REPROVADO** | — | A fonte (`474b194f`) **não contradiz** o label. Ela só não sustenta "mutation test provou". Não é corrigir-label nem corrigir: o maestro ou o proponente escolhem entre rebaixar e testemunho com origem. |
| `E_GRADE2606_DIAGNOSTICO_NAO_REORDENA` | corrigir | APROVADO | corrigir | — |
| `E_REDDIT_INACESSIVEL_DESTE_HARNESS` | testemunho | APROVADO | testemunho | — |
| `E_SGH2604_ESCOPO_EXCLUI_GRAFO_EPISTEMICO` | corrigir-label | CORRIGIDO | corrigir-label | O label novo mantinha "sem peso de prioridade/urgência/custo", e o paper cita "priority-based". A frase saiu, e o label foi reduzido a 280 caracteres ou menos. |
| `ENT_whatsapp` | testemunho | CORRIGIDO | testemunho | Os locators do compose estavam errados: a imagem fica na l.12 e o bind na l.16. |
| `D_HOOK_PREMODELSWITCH_GUARDA` | dev-óbvio | CORRIGIDO | corrigir | A decisão está **construída**: `1b795de2`, #770, o hook registrado em `settings.json` e a REGRA 65b (Radar de mundo com baseline DATADA por eixo, verificação de `session_models` no eixo E6). O veto foi observado em `model-switch.jsonl`. Conferido pelo juiz-mestre. |

O terceiro REPROVADO é **`E_VERIFY_RECIPIENT`** (corrigir). O conteúdo confere em `inference-mitigation.md@ac259e25`,
mas a atribuição "verify P1-P4" não tem fonte: nenhuma fonte versionada dá veredito por passada.

Os casos que o proponente pediu para olhar:
- **`C_TESE_MOAT_GATES`:** passou a corrigir-label. A objeção :343 refuta as "64 REGRAS" (são 63), e a :327
  contradiz "gate em repo SUJO".
- **`Q_GMILL_MAIN_DIVERGIU`:** o method foi de medição para leitura. O `rev-list` não se reproduz mais, mas o
  corpo de `c383df21` sustenta o nó.
- **`REC2_A2A_FORMAT_BUILT_WITHOUT_TRIGGER`:** a tese "6 camadas = 7" do proponente está **errada**. O
  `a2a-verify.sh` nasceu em `a359f3ed` com 0..6, e o mesmo commit escreve "6 camadas". O clock-trust entrou
  dentro da camada 3. A fonte não contradiz o label, então ficou `corrigir`.
- **`E_MERCADO_OCR_LOCAL_0908`:** o label foi reescrito em 280 caracteres ou menos sobre o journal reaberto,
  sob a regra do atrito.

## Padrões de erro do proponente

1. **O teto de 280 caracteres foi ignorado em massa.** 49 dos 58 `label_novo` passavam do teto, com até
   2695 caracteres (`D_GUARDA`). O resumo do proponente afirmava a conferência mecânica da forma, mas ela não
   media o comprimento. O juiz reescreveu 44 labels. Nos reescritos, entram só as cláusulas conferidas; o
   restante pertence à `narrative`.
2. **Label novo com cláusula que a fonte não sustenta.** É o padrão 1 da onda 1, agora dentro do próprio
   label novo:
   - "único trabalho é comprimir a saída de OUTRAS ferramentas" (`E_DOR_DOMINANTE`), que o Smooth CLI
     desmente (HN 46901233);
   - "o repasse trouxe só F1-F11";
   - "limiar de 30%" (`C_DRIFT`), derrubado por `8b005f65`;
   - "rodou sem o juiz" (`E_FALLBACK`), contradito pela síntese l.38-40;
   - o nome de branch em `ENT_KB_CORE`, que só existe no reflog do host.
3. **corrigir-label onde a fonte não contradiz o label (10 casos voltaram a `corrigir`).** O caso mais
   grave é a tese F1 #N de maestro-vivo:
   - o proponente disse que os números estavam deslocados em um, por conta 0-based;
   - o `f1-scan-mundo.json` não numera nada, e todo "F1 #N" do F2 bate com a lista dos 34 aprovados
     contada a partir do zero;
   - só dois Elenxos contam a partir do um;
   - é convenção, não erro, e os 9 nós só renumerados voltaram a `corrigir`;
   - o mesmo vale para o "6 camadas = 7" da federation.

   A tese dos 4 nós que "sobreviveram ao Elenxo" e foram derrubados **se confirmou**.
4. **dev-óbvio sobre decisão já construída (5 nós foram para `corrigir`).** São `D_HOOK_PREMODELSWITCH_GUARDA`,
   `C_S3b` (`773d5e4a`), `D_SCRUB_POR_FORMA_CURADO_ANTES_DE_PUBLICAR` (`a74ff166`, REGRA 36 (Superfície VENDORIZADA sem nome comercial de cliente)),
   `D_engine_noweb_confirmed` (compose `86662e0` com NOWEB e o container vivo) e `SY5_prose_backlog_antipattern`
   (corpo de `123749e2`). É a mesma classe do `D_TRIADE_MCP_POR_EIXO` da onda 1. Outros 6 foram para
   `dev-dúvida`.
5. **corrigir aprovado com fonte que contradiz o label.** Os casos:
   - `REC2_TRUST_MACHINERY_IDLE`: o CHANGELOG `e0bf994a` l.342-346 registra os handshakes de 07-10, contra o
     "uso zero" do label;
   - `E_VERIFY_UNPROVEN_MECHANISM`: a política só foi vista na 8ª passada, contra "P2-P7";
   - `C_TESE_AUTO_EVOLUCAO` e `C_TESE_KG_VS_PLATAFORMA`: o label diz 64 REGRAS (são 63 em `9b251104`) e 13
     HARD (são 12).
6. **Classe de `method` errada.**
   - Testemunho onde o selo está versionado. As 4 decisões de distribuição têm o selo no corpo de `a74ff166`,
     então a classe certa é leitura.
   - Medição sem reprodução. Em `E_45PCT` e `E_61PCT`, o escopo de 186 não se reconstrói (o juiz deu
     190/187/86); em `Q_GMILL`, o clone avançou.
   - Medição de sessão em gitignorado, em `E_LACUNAS_E3_0903` (`model-switch.jsonl`).
7. **Fonte posterior ao nó, ou fonte circular.**
   - `REC_STAGING_ROT_2026_08_REMEASURED` citava `onion-pessoal@d0e9669` (09-03) para um nó de 08-30. Foi
     trocado por `757a6676` (08-18).
   - `D_framing_catalogo` citava uma KB que transcreve o próprio nó. Foi trocado pelo corpo de `1125dfdd`.
   - `E_RESPAWN` apontava o cache `~/.claude/cache/changelog.md`. Foi trocado pelo CHANGELOG oficial
     (HTTP 200).
8. **Locator impreciso.** Os casos:
   - INPI l.200-214 em vez de l.200-220;
   - `kg.md` l.436, que só vale em `88099af3`;
   - `D_HONEST_LIMITS`, com as linhas de outro commit;
   - `C_PRECEDENTE`, que chamava a REGRA 63 (Colheita de grafo emite os ids colhidos no resíduo de revisão)
     de REGRA 56 (PR aberto carrega RESÍDUO da passada adversarial);
   - `D_whatsapp_dual` l.31 em vez de l.27.

## Decisão sobre o atrito do journal no host

**Decisão: um `corrigir-label` pode se apoiar em testemunho de journal do host. O critério proposto foi
aceito e endurecido.** As condições são quatro, e todas valem:
1. o `method` é `testemunho: leitura do journal <caminho absoluto> no host <data da leitura>`;
2. o juiz **reabriu** o journal e conferiu cada cláusula do label novo contra ele;
3. a contagem por script tem o comando na evidência, e o comando foi reproduzido;
4. o label diz só o que o journal diz. Relato da sessão e inferência do grafo ficam de fora.

O fundamento é a política 4 do nó: fonte de host vira testemunho. Isso define a **classe** do apoio; o
**conteúdo** não fica mais fraco por isso. Proibir o label novo deixaria no nó um label que a fonte desmente,
o que é pior do que um label correto apoiado em testemunho declarado.

Se o journal está **ausente** do host, não há fonte. Nesse caso o destino é `refutar`, quando outra fonte
contradiz o original, ou `rebaixar`.

**Aplicação: 6 nós finais em `corrigir-label` com method de testemunho, todos com o journal reaberto hoje.**
- `E_LACUNAS_DECLARADAS_ZOHO_GLPI_0923` (`wf_fea4633d`);
- `E_OBJECAO_F11_TRUNCADA_NO_REPASSE` (`wf_fcacd012`);
- `E_LACUNAS_DECK_PATTERNS_0924` (`wf_cd666d1e`);
- `E_LACUNAS_DECLARADAS_OCR_0908` e `E_MERCADO_OCR_LOCAL_0908` (`wf_fb266335`). No OCR, a SYNTHESIS
  versionada l.104-116 corrobora as contagens;
- `E_A_GUARDA_VETOU_O_PROPRIO_MAESTRO` (`.claude/sessions/model-switch.jsonl` no host, mais commits).

O `E_LACUNAS_ONDA_DERIVADA_1001` usava o mesmo journal do `E_OBJECAO_F11` e foi REPROVADO pela condição 4,
não pela classe.

## Itens para o maestro

**dev-dúvida (6): o maestro decide item a item.**

| nó | status | dúvida |
|---|---|---|
| `D_AGREGACAO_CROSS_REPO_E_MOAT` | confirmed | É decisão permanente **em vigor**. O corpo de `e9423265` sustenta o label inteiro, então "corrigir" também cabe. |
| `E_GIT_DIR_QUEBRA_A_RAIZ_DENTRO_DE_WORKTREE` | refuted | A refutação medida está em `fix-catraca-regra49.md` l.186-200. É afirmação refutada sobre o vivo, não plano. |
| `D_CORTE_E_TUDO_INCLUSIVE_META_FABRICA` | done | O corte por papel foi construído depois (`8b33203e`, role-cut (k) em `35958e8a`). Pode estar superado. |
| `D_VEICULO_STANDALONE_PUBLICO_MAIS_ADOPT` | done | Parcialmente construído (`/meta:adopt` vivo, portas pinadas em `3c51e24e`). A porta pública acabou sendo o onion-core. |
| `E_MEDIDO_BLOAT_DO_PROPRIO_CORE_1001` | confirmed | Contagem do repo vivo usada como argumento de decisão. O 48.944 não se reproduz (o juiz deu 48.849); a razão ~1,47 se reproduz. |
| `E_FABLE_REVIEW` | confirmed | Retrato datado, mas dá SUPPORTS a 3 claims PROD (grafo l.114-122). |

**PROD→DEV de nó `done` mantido como dev-óbvio (3).** Cada um tira um `done` de PROD:
- `Q_MAESTRO_VIVO`: a resposta "superfície gated" foi superada no mesmo dia por `/meta:radar` (`da7a72de`);
- `Q_postmark_pending_approval`: o bloqueio de 412 foi desbloqueado em `cd550c33`;
- `D_LIMPAR_BASELINES_NO_PROXIMO_UPDATE`: o plano é adiado, mas o `--stub-baselines` do #826 já está vivo,
  e `testemunho`/`corrigir` seria defensável.

**Os demais PROD→DEV (34 dev-óbvio).** São 26 confirmed, 6 superseded, 2 refuted e 2 open:
- **telescope inteiro (11):** nada foi construído. Não existe `session-telescope.sh`, nem `/meta:telescope`,
  nem campo no `members.yaml`, e o ADR está GATED na l.5;
- **rito (3):** não existe `resolve-session-slug.sh`;
- **censos (4)**, retratos de waha e email e o gate-inerte, este já selado.

**Flips de status: 5, todos `unverifiable → confirmed`.** São os 5 da classe "fonte contradiz o label", com o
label corrigido:
- `E_LACUNAS_DECK_PATTERNS_0924`, `E_LACUNAS_INFRA_VPS_1005`, `E_LACUNAS_DECLARADAS_OCR_0908` e
  `E_MERCADO_OCR_LOCAL_0908`, todos DEV;
- `E_MD_PICO_APRESENTADO_COMO_REGUA`, PROD.

Não há `confirmed → unverifiable`: zero rebaixamentos e zero `refutar`.

**3 REPROVADOS voltam ao proponente:** `E_LACUNAS_ONDA_DERIVADA_1001`, `E_VERIFY_APPROVED` e
`E_VERIFY_RECIPIENT`. Nos dois `E_VERIFY_*`, a escolha real é entre `rebaixar` e testemunho com origem: não
há wf_* da janela de 07-19 a 07-21 no host.

## Achados fora da provenance

1. **O abort do manifesto do `/meta:adopt` segue inerte. É defeito vivo, reproduzido pelo juiz-mestre hoje.**
   `mapfile -t m < <(echo a; exit 3) || echo ABORT` dá n=1, sem ABORT. Em `.claude/commands/meta/adopt.md`, a
   l.112-113 (e a l.737) segue esse padrão, e o comentário da l.110 já diz "`mapfile` engole rc". O "curado"
   de `E_O_MANIFESTO_QUE_FALHA_COPIAVA_TUDO` nunca foi verdade. **É a 3ª onda que reporta isso. Precisa virar
   item.**
2. **O hook `worklog-precompact-breadcrumb.sh` ainda tem o filtro antigo `feature/|hotfix/|release/`
   (l.10-13).** É o defeito vivo do `E_WORKLOG`.
3. **O trust-log de produção do a2a grava fora do git.** O `trust-topology-check` do endpoint a2a-live
   escreve no trust-log da cópia da VPS (`/home/onion/onion-evolve`), que não é versionado. Há uma linha de
   10-05 que o git não tem, e as linhas dos handshakes de 07-10 não existem em lugar nenhum.
4. **`D_CURAR_O_GATE_INERTE_DO_ADOTANTE` está `open`, mas a cura existe:** `ops/verify-adopter-gate.sh`, de
   `6eb75761` (2026-08-16). É candidato ao censo.
5. **`verified_against` com contagens erradas.**
   - `E_LACUNAS_DECLARADAS_PLUGIN_MCP_0904` e `E_MERCADO_PLUGIN_MCP_0904` dizem "36 fontes / 18 claims",
     que é o que ficou **fora** do orçamento; a rodada teve 15 e 43.
   - `E_LACUNAS_KG_MULTI_GRAPH_0904` diz "21 fontes", contra 15.
   - Zoho diz 16 fontes colhidas, contra 18 no journal.
   - `E_RITO` diz 8 sítios, contra 7.
   - `D_MAPA` aponta `:71`, contra `:72`.
   - `E_FALLBACK` ainda diz "4 passos".
6. **A SYNTHESIS do backlog-grafo (§D, l.145) diz "doze dos quinze", e a tabela dela dá dez.** As idades
   também estão com 1 dia de diferença.
7. **`E_CENSO0901_C_p3_agg_view` tem o label vigente truncado** ("decreta que a spec in…").
8. **`D_PLUGIN_MCP_POSTURE_0904` está `confirmed`, mas o label abre com "DECISAO ABERTA".**
   `E_F3_PERMISSION_PROMPTS_NONE` afirma algo sobre `bypassPermissions` que a lacuna 4 do próprio grafo diz
   não ter sido medido.
9. **Resíduos que se contradizem.** `docs-premodelswitch-guard-live-veto.md` ainda diz "sem reiniciar"; a
   correção está em `fix-kg-premodelswitch-restart-correction.md`.
10. **O WAHA aparece com nome divergente.** O compose versionado declara `container_name: onion-waha`; o label
    e o container vivo dizem `onion-vps-waha`, criado em 08-10 e não em 08-05.
11. **Arestas e estados pendentes.**
    - Falta SUPERSEDES entre o `E_LACUNAS` do websearch-cap e o `E_BINARIO_2_1_258_TETO_200_E_CONTADOR_DE_SESSAO`.
    - `Q_GMILL_MAIN_DIVERGIU` provavelmente está resolvido (merges de 10-05).
    - O critério de plano é inconsistente no guard-forge: `E_BANCADA_VERDE` ficou PROD, enquanto os irmãos
      datados foram para DEV.

## Tetos

1. **O juiz é da mesma família de modelo.** As 312 linhas foram julgadas por 9 workers independentes do
   proponente: 8 lotes por grafo inteiro e 1 lote com os 18 da revisão. Os workers abriram as fontes, segundo
   as instruções. O juiz-mestre conferiu ao vivo só esta amostra:
   - o defeito do `mapfile`;
   - `D_HOOK_PREMODELSWITCH_GUARDA` (`1b795de2`, REGRA 65b (Radar de mundo com baseline DATADA por eixo));
   - `E_TOPO` (projeção `84c659e9` ordenada por atenção, com os empates);
   - 5 `corrigir` aprovados, por amostra com semente 20261009: `E_player_limitless_meta`,
     `SY6_ev_allowed_tools_universal` (98 reproduzido), `E_UPDATE_FILTER_REMOVIDO_COLLISION`,
     `REC_STAGING_ROT_AND_MISSING_MAILBOX` e `E_BYPASS_DE_DENY_ASK_NAO_TOCA_A_CASA`. Os quatro primeiros
     foram conferidos com a fonte aberta;
   - a forma da planilha: 312 linhas sem duplicata, `label_final` ≤ 280, `dev-*` só em PROD, classe do
     method, e `label_final` só em corrigir-label.
2. **Journals ausentes do host.** São eles: `wf_9dad8645`, `wf_9ad3aba7`, `wf_bb97173d`, `wf_2944480c`,
   `wf_8cf0e944`, `wf_1c9263d8`, `wf_6e6ef552`, `wf_6a4da33e`, `wf_e27840db`, `wf_8a8eca55`, `wf_35e1e7a2`,
   `wf_611d652e` e `wf_90dd73fe`. Os nós que dependiam deles ficaram como testemunho de baixa confiança
   (origem explícita, nada contradiz) ou foram REPROVADOS.
3. **"Sustenta o label" continua sendo leitura, não métrica.** Os labels reescritos (44) foram escritos pelos
   workers do juiz. Na aplicação, eles mudam o texto do nó, e o selo final é do maestro.
4. **URLs medidas uma vez, em 2026-10-09.** O trendshift exige User-Agent de navegador, e a geekwire deu 403.
5. **`.env` não foi lido.** O `ONION_CWD` do endpoint a2a ficou inferido, sem confirmação (achado 3).
