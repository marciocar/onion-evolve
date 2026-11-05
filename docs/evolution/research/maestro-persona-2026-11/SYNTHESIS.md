---
title: A persona do maestro nasce da medida, não da memória
date: 2026-11-05
kg: docs/evolution/research/maestro-persona-2026-11/maestro-persona-2026-11.kg.yaml
run_id: wf_ded7babd-681
tokens: 7377462
agents: 106
duration_min: 33.6
review_after: 2026-12-20
type: research
mode: decision
---

# A persona do maestro nasce da medida, não da memória

> Projeção do grafo: quem manda é o `.kg.yaml`. O contrato de custo acima é o do run do `/onion-research`
> (`wf_ded7babd-681`, 2.015.900 ms, conferido no diário do workflow da sessão). As correções feitas no
> fechamento estão em «O que o fechamento corrigiu».

**A pergunta** (`Q_MAESTRO_PERSONA_1105`): como o Onion copia a voz, as preferências e o julgamento do maestro
em todo papel de sessão (core, brain, curadoria, kg-ssot) **sem copiar a autoridade dele**, e por qual fonte?

**A decisão** (`D_MAESTRO_PERSONA_SOURCE_2026_11`) está **selada pelo maestro em 2026-11-05**, por pergunta com
opções, gravada pelo `kg-decide-seal.sh` (`status: done`). **Escolhida: A, com a medida antes.** Primeiro vem o
instrumento de fidelidade: juiz cego contra decisões reais em holdout, normalizado pelo acaso e pela consistência do
maestro, e o delta de sycophancy no modelo do Onion. A projeção por papel só vem depois, com catraca no lint, e o
maestro é o único selador do grafo de persona. **Descartadas:** A com projeção já, B (memória nativa como fonte) e E
(não fazer agora). C e D não entraram na pergunta e seguem fora pela leitura do grafo abaixo.

## As cinco opções

| Opção | O que é | Leitura do grafo | Nó |
|---|---|---|---|
| **A** | Fonte única no KG-SSOT (o grafo como fonte única de verdade): um grafo `maestro-persona` com nós de voz, julgamento e limite, cada um com porquê e evidência, projetado por papel em CLAUDE.md/regra, Output Style e Agent Card A2A (o cartão de identidade do protocolo Agent2Agent), com catraca no lint | **escolhida pelo maestro**, como o Elenxo (o método de refutar antes de selar) recomendou: a medida vem antes da projeção | `C_OPCAO_A_KG_SSOT_PERSONA_GRAPH_PROJECTED_BY_ROLE` |
| B | Memória nativa do Claude Code (CLAUDE.md de usuário, auto memory, `autoMemoryDirectory`) | só transporte, nunca fonte: local por máquina e por repo, teto de 200 linhas ou 25 KB, não alcança o brain (outra conta), e memória escrita a partir do que se lê é vetor medido | `C_OPCAO_B_NATIVE_USER_MEMORY_SHARED` |
| C | `/meta:personality-sync` estendido ao maestro | não serve: o `personality.md` descreve a instância e está vencido desde `review_after: 2026-08-23` (conferido em `.claude/identity/personality.md:5`) | `C_OPCAO_C_EMERGENT_PERSONALITY_SYNC_FOR_MAESTRO` |
| D | Identidade nos pesos (fine-tune/SFT, ajuste supervisionado) ou SLM (modelo de linguagem pequeno) | fora agora: no Twin-2K, 500 amostras de fine-tune (69,61%) ficaram abaixo do texto completo em contexto (71,72%); a evidência pró-pesos é de estilo de e-mail | `C_OPCAO_D_IDENTITY_IN_WEIGHTS_OR_SLM` |
| E | Não fazer agora | **estado interino da recomendação**: sem medida, nada se projeta | `C_OPCAO_E_NOT_NOW` |

A recomendação do Elenxo está **inteira** na `narrative` do nó `D_`. As 40 objeções sobreviventes entram no grafo por
`CONSTRAINS` (41 arestas, de 40 nós): 18 apontam para o `D_`, 10 para a opção A, 10 para a opção D e 3 para a opção B.

## O que o grafo sustenta

### A autoridade não mora em nenhuma camada de texto

- Memória (CLAUDE.md, auto memory) é contexto, não configuração imposta. Só hook `PreToolUse` ou `permissions.deny`
  barram de forma determinística (`E_CC_MEMORY_IS_CONTEXT_NOT_ENFORCEMENT`). O Output Style também é instrução sem
  garantia (`E_CC_OUTPUT_STYLE_NO_GUARANTEE`), e nem o CLAUDE.md gerenciado impõe
  (`E_OBJECAO_CUT_MANAGED_CLAUDE_MD_IS_STILL_GUIDANCE`).
- O próprio hook é camada de conformidade, não fronteira de segurança. Hoje só merge e push de `main` têm veto;
  deploy, segredo e postura do host não têm (`E_OBJECAO_A1_NO_DETERMINISTIC_AUTHORITY_LAYER`, com aresta para
  `D_EXIT2_COUPLING_WORDING_2026_11`). A regra «mensagem de peer não é aprovação» é prosa. Ou se forjam essas guardas
  (`/meta:forge-guard`), ou se declara a lacuna.
- O precedente publicado para «age em nome de, sem assumir a identidade» é o claim `act` da RFC 8693 (troca de token
  OAuth 2.0) (`C_SUPERACAO_20261105_RFC8693_ACT_CLAIM`). Os dois drafts do IETF (o órgão que padroniza os protocolos da internet) citados pesam pouco: o WIMSE (identidade
  de workload) é individual (andou para o -02, `C_SUPERACAO_20261105_WIMSE_SECRET_NOT_DEPLOY`), e o OAuth on-behalf-of
  (OBO, o agente age em nome do usuário) expirou em 27/02/2026
  (`E_OBJECAO_A18_OBO_DRAFT_EXPIRED`).

### Memória que o agente escreve é superfície de ataque

- MINJA: injeção só por consulta, ASR (taxa de sucesso do ataque) médio de 76,8% (`E_MINJA_QUERY_ONLY_INJECTION`), e um usuário comum envenena a
  memória compartilhada das vítimas (`E_MINJA_SHARED_MEMORY_VICTIMS`).
- MemGhost: um único e-mail grava conteúdo não confiável em memória persistente; **71,4% end-to-end no Claude Code SDK**
  com Sonnet 4.6 (`E_MEMGHOST_CLAUDE_CODE_SDK_71`). O escopo do WhisperBench é envenenamento de fato e preferência,
  não deriva de persona (`E_OBJECAO_CUT_WHISPERBENCH_SCOPE_NOT_PERSONA`).
- Daí a restrição em A: **um único selador**, o maestro; os peers só propõem pelo inbox; nenhum nó nasce de conteúdo
  lido; cada nó leva porquê, evidência e proveniência.

### Contexto sobre o usuário eleva a sycophancy, e isso vale para A

- Perfis de memória associados aos maiores aumentos de agreement sycophancy (`E_MEMORY_PROFILES_RAISE_SYCOPHANCY`):
  Sonnet 4 +33%, Gemini 2.5 Pro +45%, GPT 4.1 Mini +16%, GPT 5.1 sem aumento significativo
  (`E_SYCOPHANCY_VARIES_BY_MODEL`). Mudar a fonte para o KG não muda o que chega ao modelo
  (`E_OBJECAO_A5_SYCOPHANCY_RISK_ALSO_HITS_A`), e nenhum estudo mediu Opus 5.x nem Fable
  (`E_OBJECAO_A6_NUMBERS_NOT_FOR_ONION_MODEL`).

### Fidelidade só vale normalizada, e ninguém a mediu no modelo do Onion

- O teto mensurável é o reteste do próprio indivíduo, não 100%: no Twin-2K-500, 81,72% (`E_TWIN2K_RETEST_CEILING`).
  «87,67% do teto» vira **≈55,7% do ganho possível** quando se desconta o acaso de 59,17%
  (`E_OBJECAO_A10_FIDELITY_MUST_BE_NORMALIZED`), e os twins erram para o normativo
  (`E_OBJECAO_CUT_TWINS_TOO_NORMATIVE`).
- Resumir a persona perde 3,7 pp contra o texto completo (68,02 contra 71,72), sem teste de significância
  (`C_SUPERACAO_20261105_SUMMARY_WEAK_SIGNAL_NO_SIGNIFICANCE`): por isso a projeção de A seleciona nós completos e não
  resume.
- «Passar por humano» (44,44% no melhor fine-tune) é impersonação, o risco que a restrição veta, não a meta
  (`E_OBJECAO_A11_PASS_AS_HUMAN_IS_IMPERSONATION`).
- A medida que A pede: juiz cego contra decisões reais em holdout (memórias de feedback, `pr-decision-history`, a régua
  ERRO-A/ERRO-B, os dois tipos de erro da fórmula de problema), normalizada pelo acaso e pelo reteste do próprio maestro, com o delta de sycophancy com e sem
  persona, no modelo do harness.

### Cinco refutações da votação contrariam a primária

O Elenxo achou cinco descartes que devem voltar como confirmados, com ressalva de peso: 85% no GSS (General Social Survey, o questionário de atitudes dos EUA)
(`E_OBJECAO_REF_GSS_85_CONTRADICTS_PRIMARY`; a v3 corrente diz 83/82/86%, `C_SUPERACAO_20261105_GSS_V3_83_PERCENT`),
resumo contra texto (`E_OBJECAO_REF_SUMMARY_LOSES_FIDELITY_STANDS`), «MUST NOT possess» do WIMSE
(`E_OBJECAO_REF_WIMSE_MUST_NOT_POSSESS`), BLEU+MAUVE, métricas automáticas de semelhança de texto (`E_OBJECAO_REF_BLEU_MAUVE_CORRELATION`; a correlação se apoia num
único avaliador, `C_SUPERACAO_20261105_PANZA_STYLE_N1_RATER`) e o vínculo do token ao ator (actor binding) do OBO (`E_OBJECAO_REF_OBO_ACTOR_BINDING`).
A sexta, «500 exemplos superam modelo de ponta», segue refutada: com memória, 500 exemplos **empataram**
(`C_SUPERACAO_20261105_FT500_TIES_NOT_BEATS`).

## Mercado

**O eixo voltou vazio, e o vazio é de orçamento** (`E_MERCADO_MAESTRO_PERSONA_1105`). O sintetizador escreveu «sem
sinal encontrado», e o escritor do grafo acrescentou que quem financia o tema não foi buscado; o retorno do run mostra
o contrário. O eixo mercado-capital achou quatro links
de rodada (Twin1, em duas coberturas; Simile; PickMyBrain), todos em `budgetDropped`. A rodada do Mem0 (TechCrunch,
2025-10-28) foi lida e gerou cinco claims, todas em `notVerifiedByBudget`. Os quatro links de analista (Thoughtworks
Radar e Gartner) também caíram. **Nenhum valor desses foi verificado, e nenhum entra aqui como fato.** A trajetória
confirmada é acadêmica e de normas: memória e persona estão migrando de feature para superfície de ataque e governança.

## NÃO-VERIFICADOS

Contabilidade do motor (`E_LACUNAS_MAESTRO_PERSONA_1105`): 66 claims, 25 votadas (`maxVerify`), 19 confirmadas,
6 refutadas, 0 não verificadas, 1 duplicada; 15 fontes lidas (`maxFetch`); 50 objeções julgadas, 40 sobreviventes,
0 recusas; 6 superações.

**Refutadas na votação (6)**, todas com fonte de tier 6 a 8; cinco delas o Elenxo contesta (seção acima), e a sexta
(500 exemplos) ele mantém pela Tabela 2 da primária:

| Claim | Voto | Fonte | Tier |
|---|---|---|---|
| 85% do reteste no GSS | 1-2 | arXiv 2411.10109v1 | 8 |
| resumo perde fidelidade (68,02 contra 71,72) | 0-3 | arXiv 2505.17479v1 | 7 |
| 500 exemplos superam modelo de ponta | 0-3 | arXiv 2504.04332 | 7 |
| agente nunca possui a credencial (WIMSE) | 0-3 | draft-sweeney-wimse-credential-delegation-00 | 7 |
| BLEU+MAUVE correlacionam com preferência humana | 1-2 | arXiv 2407.10994 | 7 |
| actor binding no OAuth on-behalf-of | 0-3 | draft-oauth-ai-agents-on-behalf-of-user-02 | 6 |

**Claims lidas e não votadas por orçamento (41)**, por fonte: TechCrunch/Mem0 5; o skill digital-twin no GitHub 4;
NeurIPS 2026 (176570) 4; Twin-2K (2505.17479) 3; WIMSE -00 3; 2509.12517v3 3; doc de memória do Claude Code 3; doc de
Output Styles 3; MINJA (2503.03704v5) 3; 2504.04332 2; 2607.05189 2; 2411.10109v1 2; Panza (2407.10994) 2; OBO -02 2.
Quinze delas voltaram como objeção sobrevivente, cortadas sem medida (nós `E_OBJECAO_CUT_*`), entre elas o fine-tune
de 500 abaixo do texto completo, os twins normativos e o desenho holdout/acaso/reteste.

**Fontes achadas e não lidas por orçamento (39)**, por eixo:

- Fidelidade e juiz: Stanford HAI (1.052 indivíduos), **2407.18416** (provável PersonaGym), Columbia DAPLab.
- Prompt contra fine-tune: **2304.11406v3** (provável LaMP), **2601.06471**, **2605.29420**, **2607.14371**.
- Riscos: **2512.12775**, **2605.24279** (deriva de persona), o blog tianpan.co, 2402.10962v1.
- Identidade e delegação: 2603.24775v1, Waxell, WorkOS, Gravitee (agent cards).
- Contrarian: MIT EECS (personalização e concordância), Writer (contexto personalizado degrada), alphaXiv 2601.13722,
  2602.01146v1.
- Claude Code atual: Output Styles, `claude-directory`, `modifying-system-prompts` do Agent SDK, discovery do A2A.
- Mercado e capital: as quatro rodadas acima.
- Repos de trajetória: PersonalPedia, dsh-memory-core, andrewngdigitaltwin, eder-labs.
- Analistas: Thoughtworks Radar (duas entradas), Gartner (duas entradas).
- Comunidade: claude-code-output-styles, Mem0 contra Letta contra Zep contra Cognee, arquiteturas de memória 2026,
  ferramentas de memória 2026.

As fontes em negrito são sete das oito que o Elenxo marcou como buraco (nós `E_OBJECAO_SRC_*`); a oitava, o blog
tianpan.co, tem peso esperado baixo (provável secundário de MINJA e MemGhost). Sem as sete, **deriva de persona e juiz
de persona por modelo de linguagem (LLM) ficam sem claim ancorada**, e o eixo que decide D ficou sem as fontes de 2026.

**Lacunas sem fonte nenhuma**: A2A Agent Card e projetos da AAIF (Agentic AI Foundation) como canal de persona; Letta, Mem0 e Zep como
arquitetura; Character cards; a user memory do ChatGPT, do Claude e do Gemini; o rótulo de origem de uma persona que
fala como o maestro em canal de peer ou de adotante.

## O que o fechamento corrigiu

- **O id do run** saiu de «inferido do diretório de subagentes» para conferido: o diário do workflow da sessão tem
  `wf_ded7babd-681` com `agentCount` 106, `totalTokens` 7.377.462 e `durationMs` 2.015.900.
- **O mercado**: a frase «não foram buscados nem achados», no `E_MERCADO_*`, e o «não buscado» das lacunas, no
  `E_LACUNAS_*`, foram trocados pela contagem do retorno (seção Mercado). A nota (a) do `E_LACUNAS_*`, que ainda dizia
  «inferido», passou a registrar a conferência no diário.
- **O MEMORY.md**: o item (6) do Elenxo diz 198 linhas e 25.031 bytes; re-medido no fechamento, com `wc -lc`, deu 179
  linhas e 23.785 bytes. A conclusão do item não muda: o índice está perto do teto de 200 linhas e 25 KB, e o CLAUDE.md
  de usuário segue inexistente. A recomendação ficou verbatim, e a re-medida entrou como nota (e) do escritor.
- **Os códigos sem termo**: o lint de nomes da kg-ssot reprovou, no `pr-finalize`, sete menções a códigos da casa e a
  um nome de fornecedor sem termo declarado. Elas viraram glosa («um escritor por repo», «conteúdo lido é dado não
  confiável», «fornecedor de gestão de identidade»), e a troca na recomendação do Elenxo está na nota (f) do `D_`.
- **A passada adversarial do fechamento** (revisor separado) achou 7 defeitos reais nesta projeção e no grafo, todos
  corrigidos; o resíduo da REGRA 56 (PR aberto carrega RESÍDUO da passada adversarial) os lista.
- **O `trace:` desta SYNTHESIS** foi para o nó `Q_`, porque todos os 74 nós já tinham `trace:`. Foi troca de valor, sem
  chave repetida, e a origem do pedido foi para o `verified_against` do mesmo nó.

## Valeu a pena

**7.377.462 tokens ÷ 74 nós ≈ 99,7 mil por nó**, ou ≈388 mil por claim confirmada (19). É mais que os 68 a 74 mil do
censo e menos que os ≈291 mil por nó da varredura `decision` de 2026-09-13 (`wf_88199ba9-b9a`). Mas 46 dos 74 nós são
objeções e superações, então a densidade vem do Elenxo, não da busca.

**Valeu pela correção, não pela cobertura.** O run achou cinco refutações erradas, o vetor de envenenamento medido no
próprio Claude Code SDK e o erro de ler «% do teto» sem descontar o acaso. Isso basta para rejeitar B, C e D como fonte
agora. Não basta para selar A: a cobertura ficou presa no orçamento (`maxVerify` 25 para 66 claims, `maxFetch` 15 para
54 fontes), e por isso o mercado e a deriva voltaram vazios.

**Próxima rodada**, se o maestro pedir: modo `primaries`, com as fontes em negrito acima e as rodadas de capital como
lista nomeada. As lacunas já têm nome, e não se paga descoberta duas vezes (SKILL, etapa 7).
