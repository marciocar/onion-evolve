---
title: "Indivíduo × organização: a partilha indissociável pede um critério — a rodada 1 propõe finalidade por fluxo, e o selo espera LGPD e autodeterminação"
date: 2026-09-13
kg: docs/evolution/research/compartilhamento-individuo-organizacao-2026-09/compartilhamento-individuo-organizacao-2026-09.kg.yaml
run_id: wf_88199ba9-b9a
tokens: 7282373
agents: 105
duration_min: 23
genre: decision
mode: decision
budget: { maxFetch: 15, maxVerify: 25 }
review_after: 2026-12-12
---

# Indivíduo × organização: onde a partilha indissociável vira vigilância

> **Projeção** do grafo (25 nós, 48 arestas, radar exit 0). Pesquisa aberta pelo maestro em 2026-09-13 em
> resposta ao sinal do adotante jogo-da-vida (`docs/evolution/inbox/_processed/2026-09-13-fronteira-pessoa-empregador-no-company-brain.md`).
> Alimenta `Q_RESEARCH_COMPARTILHAMENTO_INDIVIDUO_ORGANIZACAO` em
> `docs/discussions/onion-pessoal-marcio/proto/fronteira-decision.kg.yaml`. **Nada aqui está selado**: o
> nó `D_INDIVIDUAL_ORGANIZATION_SHARING_CRITERION` foi **selado pelo maestro em 2026-09-13**: **opção C como
> direção, com a rodada complementar (opção D) como condição**. Nada de C vira desenho antes dela.
>
> O retorno estruturado do run inteiro está versionado em
> [`data/wf_88199ba9-b9a-return.json`](data/wf_88199ba9-b9a-return.json). Tudo o que esta síntese cita e o
> grafo não modelou (as 30 objeções sem nó, as claims cortadas, as URLs não lidas) está nomeado lá.

## Custo declarado

| Item | Valor | Fonte |
|---|---|---|
| Run | `wf_88199ba9-b9a` | diário `~/.claude/projects/-home-marcio-onion-evolve/d6bb8861-…/workflows/wf_88199ba9-b9a.json` |
| Tokens | 7.282.373 | `totalTokens` do diário (igual à notificação) |
| Workers | 105 · 459 tool calls · 0 erro, 0 vazio | diário + notificação do run |
| Parede | 22,7 min (1.361.502 ms) | `durationMs` do diário |
| Fontes | 11 ângulos → 56 URLs → **15 lidas**, 41 cortadas por orçamento | `logs` do run |
| Claims | 38 extraídas → **25 verificadas** (6 confirmadas, 19 refutadas) · 13 cortadas | `stats` do run |
| Elenxo | 47 objeções, **40 sobreviventes** (33 descartes por comodismo reabertos) · **10 viraram nó** | `logs` do run + grafo |

## Veredito

**A posição do maestro sobrevive como TESE.** Nas palavras dele, há partilha indissociável nos dois sentidos,
delimitada por influência e relação mútuas e com proteção à empresa e ao indivíduo
(`C_COMPARTILHAMENTO_INDISSOCIAVEL_BIDIRECIONAL`). Ele nunca a propôs como critério: pediu a pesquisa justamente
para ter um. A rodada 1 **não achou esse critério pronto em nenhuma fonte**. O que segue é a **síntese do
run** sobre as 6 confirmadas e as objeções do Elenxo, e não um enunciado de fonte
(`E_OBJECTION_MANDATORY_AXES_UNCOVERED`: a pergunta central segue sem evidência direta).

A síntese propõe um critério por **fluxo**, e não por dado:

1. **Finalidade declarada antes, por fluxo; reuso só compatível e declarado** (`E_PURPOSE_LIMITATION_PRE_DECLARED`).
   A lista fechada belga não se generaliza, porque o GDPR art. 6(4) admite tratamento posterior compatível
   (`E_OBJECTION_BELGIAN_CLOSED_LIST_NOT_GENERAL`). Vale como **desenho**, não como regra jurídica importada.
2. **Consentimento sob subordinação é improvável como base** (`E_EMPLOYEE_CONSENT_UNLIKELY_UNDER_SUBORDINATION`).
   O primário diz "improvável na maioria dos casos", não "rejeitado" (`E_OBJECTION_CONSENT_NOT_REJECTED_BUT_UNLIKELY`).
   Isso separa este eixo do corpus: `C_MEMBRO_SOBERANO` pressupõe alguém que ESCOLHE partilhar. Aqui, base e
   finalidade têm de ser impostas pelo mecanismo.
3. **Acordo coletivo não afasta os princípios do GDPR** (`E_CJEU_C65_23_COLLECTIVE_AGREEMENT_NOT_ENOUGH`).
   O caso é de transferência de dados de RH, não de monitoramento, e ler "não basta para legitimar vigilância"
   é extrapolação (`E_OBJECTION_C65_23_EXTRAPOLATED`).
4. **O teste de Bărbulescu** (TEDH, Grande Câmara, 2017, §121: notificação, extensão, razão legítima, meio
   menos intrusivo, consequências, salvaguardas) foi descartado pelo pipeline e **reaberto pelo Elenxo** como
   o candidato mais forte (`E_OBJECTION_BARBULESCU_DISCARDED_BY_COMODISMO`).

**A posição do adotante** (colaborador só como autor) **não foi refutada**. A lei admitir mais não derruba um
desenho que escolhe coletar menos: B é escolha de produto, não violação legal. O limite real dela é prático:
autoria já é dado pessoal, porque quem decidiu o quê é inferível (`PO_INFERENCIA` no corpus).

## As quatro opções do nó de decisão

| Opção | Nó | Confiança | Leitura |
|---|---|---|---|
| A — partilha indissociável bidirecional (maestro) | `C_OPCAO_A_BIDIRECTIONAL_INSEPARABLE_SHARING` | 0,45 | tese que pede critério |
| B — colaborador só como autor (adotante) | `C_OPCAO_B_EMPLOYEE_ONLY_AS_AUTHOR` | 0,30 | não refutada; esbarra na autoria ser dado |
| C — A restringida: fluxo por propósito, assimetria de padrão | `C_OPCAO_C_PURPOSE_BOUND_ASYMMETRIC_FLOW` | 0,60 | **direção recomendada pelo Elenxo** |
| D — GATED: rodada complementar antes de selar | `C_OPCAO_D_GATED_COMPLEMENTARY_ROUND` | 0,65 | **condição do selo** |

**Recomendação do Elenxo: C como direção, D como condição — SELADA pelo maestro em 2026-09-13.** O grafo modela como `CONSTRAINS` de C as
objeções `E_OBJECTION_C65_23_EXTRAPOLATED`, `E_OBJECTION_CONSENT_NOT_REJECTED_BUT_UNLIKELY`,
`E_OBJECTION_BELGIAN_CLOSED_LIST_NOT_GENERAL`, `E_OBJECTION_MANDATORY_AXES_UNCOVERED`,
`E_OBJECTION_ART88_NATIONAL_FRAGMENTATION` e `E_OBJECTION_NO_UNIFORM_EU_THRESHOLD`.

A **recomendação textual do Elenxo** (no retorno do run, **não modelada como nó**) acrescenta restrições que
ainda precisam de fonte lida:
- a base legal é legítimo interesse documentado, com DPIA/RIPD;
- nenhum agregado comportamental depende só de limiar de contagem. Piso de grupo não para o ataque
  "tracker" (Denning 1979) nem a reconstrução por consultas (Dinur e Nissim 2003). O corpus já tem
  `PO_BUDGET` e `PO_L3_FILTRO`;
- dado de colaborador nunca vira proxy avaliativo;
- opt-out não conta como proteção sob subordinação.

**Colisão a resolver antes do selo:** na versão da recomendação, C deixava "organização→indivíduo aberto por
padrão". O vazamento que o adotante mediu foi justamente desse lado: o Karma **agregado mostrado ao time**,
que é organização→indivíduo, cai no critério de falseamento aceito em `D_JOGO_DA_VIDA_E_BANCO_DE_PROVAS`. Os
labels de C e da decisão foram restringidos: aberto **só para o dado da própria pessoa e as decisões que a
afetam**. Agregado de terceiros não entra nesse fluxo.

## Como isso encaixa em Company Brain, Second Brain e Onion

- **Igual ao corpus, portanto transfere:** finalidade por fluxo = `PO_L1_ESCOPO` + `PO_L2_PROPOSITO`; defesa
  contra diferença = `PO_BUDGET` + `PO_L3_FILTRO`; "só predicado provado sai" = `ST_EMISSAO`.
- **Diferente do corpus, portanto é preciso desenhar:**
  - a base do fluxo deixa de ser escolha do membro e passa a ser imposta pelo mecanismo;
  - a direção **empresa→indivíduo** (a decisão ou a política que afeta a pessoa e deve chegar a ela) não
    existe em nenhum grafo do corpus. Entra como **obrigação de transparência** sobre o que é da pessoa.
- **Articulação proposta:**
  - Second Brain: soberano do indivíduo, nada sai sem predicado;
  - Company Brain: devolve à pessoa o que é dela e o que a afeta, e recebe dela só predicado com finalidade;
  - Onion: o mecanismo verificável que aplica o critério.

## Mercado

**Nenhum sinal de capital confirmado** (`E_MERCADO_NO_CAPITAL_SIGNAL_EMPLOYEE_DATA`). Os dois sinais de produto
confirmados **não derrubam** a posição do adotante:

- **Glean** reconcilia a pessoa como identidade (`E_GLEAN_PERSON_AS_IDENTITY_NODE`), mas a identidade serve
  para aplicar **permissão** por item, não para avaliar a pessoa como sujeito. É compatível com "colaborador
  como autor" (`E_OBJECTION_GLEAN_IDENTITY_IS_ACL_NOT_SUBJECT`). É um fornecedor só, falando de si (tier 5).
- **Viva Insights** ampliou em out/2025 a comparação gerencial de uso de IA por equipe
  (`E_VIVA_COPILOT_DASHBOARD_MANAGER_COMPARISON`). O verbo "monitorar" da fonte exagera: a arquitetura declarada
  entrega **agregado com piso de grupo**, e isso **confirma** a restrição do adotante em vez de contrariá-la
  (`E_OBJECTION_VIVA_MONITOR_VERB_OVERSTATES`).

As fontes de capital e de reação de trabalhadores ficaram **não lidas**: Series F do Glean, processos de
sindicatos, a reversão do Productivity Score (2020), relatório de mercado de monitoramento. **Não cite tese de
capital a partir desta rodada.**

## NÃO-VERIFICADOS

**Eixos obrigatórios sem nenhuma claim confirmada** (`E_OBJECTION_MANDATORY_AXES_UNCOVERED`, `E_LACUNAS_COMPARTILHAMENTO_0913`):

- **LGPD, ANPD e TST: zero achados.** É a lacuna mais grave: o adotante é brasileiro, e GDPR→LGPD não se presume.
- **Autodeterminação (Deci e Ryan): zero achados**, e é a régua que o próprio sinal do adotante propôs.
- **Integridade contextual no trabalho, privacidade diferencial em times pequenos, k-anonimato e ataques de
  diferença:** só em descartes ou cortes.
- **A restrição matemática do adotante segue testemunho** (`E_ADOPTER_DIFFERENCE_ATTACK_SMALL_TEAMS`,
  confiança 0,6): não refutada, sem fonte externa lida.

**Afirmações usadas no debate que NÃO foram verificadas:**

- **"art. 88(1) do GDPR":** a claim foi **cortada por orçamento**. O texto é cláusula de abertura: prevê que os
  Estados-membros regulem o tratamento no emprego, inclusive para planejamento e organização do trabalho. Não
  "autoriza" por si. Nenhum nó a sustenta.
- **Coorte de ≥20 empresas:** refutada numa claim, não verificada na outra. Não é "confirmada e refutada".

**Confirmadas com fonte fraca** (tier 5–6, confiança ≤ 0,55):
- `E_CJEU_C65_23_COLLECTIVE_AGREEMENT_NOT_ENOUGH`, `E_EMPLOYEE_CONSENT_UNLIKELY_UNDER_SUBORDINATION`,
  `E_GLEAN_PERSON_AS_IDENTITY_NODE` e `E_VIVA_COPILOT_DASHBOARD_MANAGER_COMPARISON`.
- `E_VIVA_COPILOT_ADOPTION_METRICS`, com votação 2-1; "individuais" não se sustenta
  (`E_OBJECTION_INDIVIDUAL_METRICS_UNSUPPORTED`).

**As 10 objeções modeladas são afirmação de UM agente, sem votação.** Elas citam primários (EUR-Lex/curia,
EDPB 05/2020, o changelog da Microsoft) que **não foram lidos** na rodada. A confiança de todas foi limitada a
0,6 nesta revisão.

**30 das 40 objeções sobreviventes não viraram nó.** O teto do grafo cortou, e o nó de lacunas dizia "3
reabertos". Estão nomeadas em `data/wf_88199ba9-b9a-return.json`. Entre elas:
- o piso de grupo 5 do Viva;
- o consentimento contornado pelo gestor;
- distribution masking;
- reidentificação por atributos combinados.

**Refutadas: 19 de 25.** O retorno do run traz só os votos, não a evidência de cada verificador. Não dá para
saber quantas caíram por evidência contra e quantas por falta de fonte forte. E o Elenxo classificou descartes
como "comodismo" **sem ver o motivo do voto**. Isso é defeito do instrumento, registrado no Backlog.

**Fora do orçamento:** 13 claims não verificadas e 41 URLs não lidas.

**Desvio meu, declarado:** a skill manda passar ao workflow o bloco do `kg-corpus-grep.sh` **verbatim**. Eu o
condensei numa linha que começava com `#`, e o log do run disse `Corpus: VAZIO`. O texto chegou aos prompts que
usam o corpus (Scope, síntese, Elenxo e write(KG)); Search, Fetch e Verify não o recebem, por desenho. Curado
neste PR em `.claude/workflows/onion-research.js`:
- o contador passa a contar só linhas no formato canônico;
- o log distingue "vazio" de "fornecido fora do formato".

## valeu-a-pena

**7.282.373 ÷ 25 nós ≈ 291 mil tokens por nó.** A comparação justa é com pesquisas do **mesmo formato**
(workflow onion-research, modo decisão, ~105 agentes):

| Pesquisa | Custo por nó |
|---|---|
| plugin-language-policy | 264 mil |
| plugin-mcp-posture | 224 mil |
| kg-multi-graph-view | 210 mil |
| ocr-local-sei | 249 mil |
| poda | ~180 mil |

Esta rodada ficou **~10% acima da mais cara**: é o topo da faixa, não uma regressão de ordem de grandeza.
Os 105 agentes são o formato fixo do workflow, e não desperdício: 1 Scope, 11 Search, 15 Fetch, 75 votos de
Verify, síntese, Elenxo e write(KG). O censo de reverificação (~70 mil por nó) é outro pipeline e não serve de
régua.

**Valeu, por uma razão só.** A pergunta é de decisão com peso de produto (ICP = empresa + Company Brain).
A rodada mostrou que nem A nem B fecham a questão sozinhas, e que a opção C tem uma colisão com o banco de
provas que precisava aparecer antes de qualquer selo. **Não valeria** repetir o formato de varredura larga na
rodada complementar. Ela deve ir direto às primárias nomeadas (LGPD/ANPD/TST, EDPB, Bărbulescu, IAPP/k-anonimato,
Deci e Ryan), com poucas fontes e leitura integral.

## Backlog

1. **Rodada complementar (opção D)**, antes de qualquer selo:
   - LGPD (arts. 7, 8 §3 e 10; legítimo interesse) + guia da ANPD + TST sobre monitoramento;
   - EDPB 05/2020;
   - Bărbulescu e López Ribalda II;
   - fontes de grupos pequenos não lidas (IAPP, tdp2023, PMC2858714);
   - Deci e Ryan aplicada a monitoramento.

   Formato: primárias nomeadas, leitura integral.
2. **Julgar as 30 objeções sobreviventes sem nó** (no retorno versionado) e as contradições do pipeline
   (piso de grupo do Viva; ≥20 empresas; C-65/23 × art. 88), lendo o primário de cada uma.
3. **Instrumento:** o Elenxo classifica descarte como "comodismo" sem receber a evidência do voto que o
   refutou. O workflow deve passar o motivo do voto ao Elenxo.
4. **Eixo de mercado de novo:** capital do Glean, processos e recuos de produto por pressão de trabalhadores.
5. **Banco de provas do adotante:** submeter a opção C, com a restrição organização→indivíduo acima, ao
   critério de falseamento do jogo-da-vida (times de 3 a 5).
6. ~~O maestro sela `D_INDIVIDUAL_ORGANIZATION_SHARING_CRITERION`~~ — **SELADO em 2026-09-13** (C + rodada
   complementar). O que resta é 1–5; o item 1 deixa de ser sugestão e passa a ser **condição do selo**.
