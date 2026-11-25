---
title: "Second Brain pessoal × Company Brain — vertical do Onion? (decisão aberta, recomendação C com limites)"
date: 2026-11-25
kg: docs/evolution/research/second-brain-company-brain-2026-11/second-brain-company-brain-2026-11.kg.yaml
run_id: wf_4dcf9417-edc
tokens: 7762046
agents: 106
duration_min: 23.9
genre: decision
mode: decision
budget: { maxFetch: 15, maxVerify: 25 }
review_after: 2027-02-23
---

# Second Brain pessoal × Company Brain — decisão aberta

> **Projeção** do grafo `second-brain-company-brain-2026-11.kg.yaml` (72 nós; radar `--integrity --schema` exit 0; contrato exit 0).
> Se esta prosa divergir do grafo, vale o grafo. Nó de decisão: **`D_SECOND_BRAIN_VERTICAL_2026_11`**, **selada pelo maestro em 2026-11-25** (ver «Selos de 25/11» abaixo). O run em si não selou nada: nasceu `open`.
> Retorno íntegro do run em `data/wf_4dcf9417-edc-return.json`.

## Custo declarado

| Item | Valor |
|---|---|
| Tokens | 7.762.046 |
| Workers do run | 106 · 15 fontes · 58 claims · 25 verificadas (19 confirmadas, 6 refutadas) |
| Parede | ≈ 23,9 min (1.432.945 ms) |
| Orçamento | `maxFetch` 15 · `maxVerify` 25 |
| Elenxo | sim (modo decisão): 37 objeções sobreviventes, todas modeladas como `E_OBJECAO_` |

## Selos de 25/11 (depois do run, pelo `/meta:decide`, destino desenho)

- **`D_SECOND_BRAIN_VERTICAL_2026_11`:** escolhida **C (central de decisão do company-brain) primeiro, depois B (vertical irmã federada) usando o aprendizado de A (ADR-003)**. Descartadas: A como caminho principal agora; D antes de decidir. Pedido junto: Delphi com os envolvidos, trazido ao `/meta:decide`, e jornadas certificadas fim a fim de forma ordenada e progressiva.
- **`D_SECOND_BRAIN_ORDER_1125`** (Delphi `second-brain-order-1125`, 3 rodadas, 4 participantes, 0 objeções; síntese em `data/delphi-second-brain-order-1125.md`): **Selar e começar (MVP 0 primeiro)**. Ordem Lean: MVP 0, MVP 1 (5 dias, N=1, fila única), incremento 1 só se uso ≥ 3 de 5 dias e ação ≥ 50% em 24 h, incremento 2, depois B. O ambiente de teste do Slack fica, e o aviso do MVP 1 sai também pelo WhatsApp via WAHA.
- **`E_MVP0_MEDIDA_1125`:** o MVP 0 já rodou: 3 de 3 decisões reais seladas, laço fechado, ≈ 2 min 39 s de resposta e ≈ 4 min até o último selo, 2 recusas do selador por flag nova (relato da sessão que o executou).

## Resumo

Em novembro de 2026 o segundo cérebro pessoal com IA vive mais como camada de memória para desenvolvedores do que como app de consumo. A Mem0 captou US$ 24M e chegou a 186M de chamadas por trimestre em 2025, enquanto apps de consumo morrem: o Mem encerra em 15/01/2027 depois de cerca de US$ 29M investidos, e a Ollie fechou em 06/11/2026. A ponte pessoal-empresa está em construção. O Solid tem grupo de trabalho no W3C, e a Inrupt pede consentimento revogável com auditoria. O Stanford trata a memória como portátil e governada pelo usuário, mas a fronteira é jurídica e de trilha, não criptográfica: revogar não apaga a cópia. A lei sobre quem é dono do gêmeo digital do empregado segue em aberto. Recomendo a vertical Second Brain como irmã do Company Brain. O cérebro pessoal fica do lado do indivíduo, no modelo do ADR-003 (o KG cifrado no celular). A interconexão com a empresa passa pelo kg-ssot e pelo A2A, com fluxo assimétrico por finalidade (a opção C já selada em D_INDIVIDUAL_ORGANIZATION_SHARING_CRITERION). A porta de entrada é o app da central de decisão. Não recomendo abrir agora o mercado de vender ou alugar habilidades e contatos: a pesquisa não confirmou nenhum caso que funcione.

## A decisão e as opções (antes do selo)

| Opção | O quê |
|---|---|
| **A** | retomar o ADR-003 do Onion Pessoal (KG cifrado no celular, só contexto de-identificado à nuvem) |
| **B** | Second Brain como vertical irmã do Company Brain, com interconexão federada (A2A, kg-ssot) |
| **C** | começar pelo app como central de decisão (company-brain PR #29 / SAC-554), com o indivíduo como usuário dentro do Company Brain |
| **D** | rodada complementar antes de decidir: (2) mercados/falhas (GPT Store, Bloomberg, snyk ToxicSkills, Zep wallet fallacy) e eixo BR (ANPD TS-04-2026, Lei 9.609 art. 4º, CLT 483) |

**Recomendação do Elenxo (afirmação de um agente, sem votação): opção C, com limites.** Começar pela central de decisão que já existe no company-brain (PR #29, SAC-554), com o colaborador como usuário que **puxa** do company brain o que lhe cabe, sem fluxo do pessoal para a empresa salvo publicação autoral explícita. Na dúvida, não sai. Íntegra e as seis condições no `narrative` do nó `D_SECOND_BRAIN_VERTICAL_2026_11`. Nenhuma opção foi morta por evidência (0 `REFUTES`, 41 `CONSTRAINS`).

## O mercado

Capital e mercado: (1) A infraestrutura de memória para desenvolvedores atrai capital. A Mem0 captou US$ 24M no total: seed de US$ 3,9M e Série A de US$ 20M liderada pela Basis Set Ventures, com Peak XV, Y Combinator, GitHub Fund e Kindred Ventures (TechCrunch, 28/10/2025). As chamadas de API foram de 35M a 186M por trimestre em 2025. (2) O app de consumo de segundo cérebro perde dinheiro. O Mem queimou cerca de US$ 29M de capital de risco e encerra em 15/01/2027 (anúncio de 17/11/2026). A Ollie, assistente de IA para famílias, fechou em 06/11/2026 por falta de crescimento e de capital (lista "AI graveyard" do TechCrunch, 14/11/2026). (3) Padrões e infraestrutura: o Solid tem grupo de trabalho no W3C (Linked Web Storage, julho de 2026), a Inrupt lançou o ESS 3.0 com Access Grant para agentes de terceiros (27/05/2026) e a MacPaw publicou o Portable Memory (preprint, sem adoção). (4) Analistas jurídicos (Gowling WLG, 30/06/2026; Mondaq, 02/06/2026) apontam a propriedade do gêmeo digital do empregado como questão em aberto. SEM SINAL CONFIRMADO para: rodadas ou M&A de marketplaces de habilidades, conhecimento, agentes ou contatos entre pessoas e empresas (c2c, c2b, b2b2c), receita de criadores individuais, cooperativas de dados com tração, e capital de company brain em novembro de 2026. As claims sobre o Claude Marketplace (23/09/2026, sem repasse a independentes) e o Salesforce AgentExchange foram refutadas. O corpus de setembro já registrava E_MERCADO_NO_CAPITAL_SIGNAL_EMPLOYEE_DATA: nenhum capital medido em dados do empregado.

## Perguntas que ficaram abertas

- O ADR-003 (KG cifrado no celular, só contexto de-identificado à nuvem) aguenta uma terceira parte com interesse oposto, o empregador? Ou precisa de um ADR novo para a saída do pessoal para a empresa, com finalidade, mínimo necessário e trilha, sem depender de revogação?
- Na lei brasileira: o empregado é dono do que está no Second Brain dele e foi feito no expediente, ou isso é produto do trabalho do empregador (art. 4º da Lei 9.609 e art. 88 da Lei 9.279)? Acordo coletivo pelos arts. 611-A e 611-B pode legitimar a ligação entre os dois cérebros? É a mesma lacuna que a rodada D de setembro deixou aberta.
- Qual é o formato de troca entre o Second Brain e o Company Brain: o kg-ssot nativo por A2A, exportação compatível com Solid/LWS ou com o .mem da MacPaw, ou os dois? Qual deles atende à regra de não depender de serviço externo sem isolar o Onion do padrão que vencer?
- O app da central de decisão (company-brain PR #29, card SAC-554) é o lugar certo para o primeiro pedaço pessoal, ou mistura de saída os dois lados no mesmo aparelho, criando o risco de vigilância que a opção C quer evitar?
- Existe algum mercado de habilidades, agentes ou contatos entre pessoas e empresas com receita medida em novembro de 2026? É preciso uma rodada própria com primárias (Anthropic, Salesforce, MCP registry, A2A/AAIF) antes de qualquer decisão sobre o item (2).
- Por que o Mem e a Ollie morreram (retenção, custo de captura, ausência de ciclo de trabalho)? Um segundo cérebro que entra pelo trabalho, com a central de decisão como uso diário, escapa desse padrão? Falta medir com dados de retenção.
- O gêmeo digital do empregado, que o mercado já faz, deve ser uma linha vermelha explícita no desenho do Second Brain, com nó de decisão no grafo e uma guarda que barra treinar sobre o estilo e o julgamento do colaborador sem consentimento?

## O que a pesquisa não cobre

O que a pesquisa NÃO cobre: (a) Item (2) quase vazio. Nenhuma claim confirmada sobre vender, alugar ou cobrar habilidade, conhecimento, estratégia, agentes ou contatos, nem sobre MCP ou A2A como mercado ou sobre cooperativas de dados. A recomendação de não abrir esse mercado agora vem da ausência de evidência, não de evidência contrária. (b) Lei brasileira ausente nesta rodada: as fontes jurídicas são de common law (Reino Unido). O corpus de setembro (compartilhamento-individuo-organizacao-2026-09) já tem o EXEMPLO 7 do Guia de Legítimo Interesse da ANPD, a ausência medida de decisão sancionadora da ANPD sobre monitoramento e as lacunas abertas: acórdão do TST e acordo coletivo pelos arts. 611-A e 611-B da CLT. Esse corpus vale para o Second Brain sem mudança, porque o problema é o mesmo. (c) O que TRANSFERE do corpus, porque é o mesmo problema: D_INDIVIDUAL_ORGANIZATION_SHARING_CRITERION (opção C, fluxo assimétrico por finalidade, com a rodada D como condição) governa a interconexão; o INVARIANTE 0 do ADR-003 (KG no celular, a VPS nunca toca o KG cru) governa o lado pessoal; e a regra de não depender de serviço externo exclui o Solid hospedado por terceiros como dependência obrigatória. Solid e Inrupt, se usados, entram só como ponte opcional. (d) O que DIFERE e precisa ser desenhado frente ao corpus: o ADR-003 previa só envio de contexto de-identificado à nuvem do próprio usuário, não a ida para o Company Brain de um empregador. A empresa é uma contraparte com interesse oposto (vigilância, gêmeo digital). Por isso falta um contrato de saída do pessoal para a empresa com finalidade, mínimo necessário e trilha, e esse contrato não pode contar com a revogação, já que o Solid mostra que revogar não apaga. (e) Pontos fracos: os dados da Mem0 são de outubro de 2025; o fechamento do Mem vem de agregador de tier 4 (falta o anúncio primário); o SwarmVault não tem data; o artigo da Vectorize é de fornecedor sobre concorrente. (f) Não medimos o estado atual dos repos onion-pessoal, onion-pessoal-kg e onion-pessoal-app (parados desde julho) nem a maturidade do PR #29 da central de decisão. A ordem recomendada (começar pelo app da central de decisão) depende disso. (g) A pesquisa não mediu a demanda real do lado pessoal: as mortes do Mem e da Ollie apontam para retenção baixa, mas não sabemos se um segundo cérebro preso ao trabalho, entrando pela central de decisão, escapa desse padrão.

## NÃO-VERIFICADOS (declarado)

- **`unverified`:** 0.
- **`refuted`: 6 claims** (a maioria por fonte fraca ou por escopo, não por evidência contra):

  - (0-3, tier 8) A mesma fonte afirma que esse contexto pessoal deve poder ser compartilhado seletivamente por papel, consentimento e finalidade. É o único trecho sobre fronteira indivíduo×organização, e a página não trata de empresas. — <https://digitaleconomy.stanford.edu/publication/the-future-of-personal-ai-portable-and-persistent-personal-memory-through-a-unified-human-context-protocol/>
  - (0-3, tier 6) A memória de agente é lock-in e hoje é imóvel e sem formato comum entre fornecedores. ChatGPT lançou memória em fev/2024, Gemini em fev/2025 e Claude em set/2025. O paper descreve três falhas: imobilidade de conteúdo, ausência de representação compartilhada e retirada (esquecimento) não comprovável. — <https://research.macpaw.com/publications/portable-memory/portable-memory.pdf>
  - (0-3, tier 5) Grandes plataformas absorveram funções de startups independentes de agentes e automação (Relay encerrou em ago/2026; Notion Mail previsto para 22 set 2026), o que pesa contra um app pessoal sem diferencial. — <https://techcrunch.com/2026/11/14/the-ai-graveyard-a-running-list-of-projects-and-startups-that-didnt-make-it/>
  - (1-2, tier 4) O Claude Marketplace abriu em 23 de setembro de 2026 com mais de 2.000 conectores e plugins. Clientes empresariais aplicam parte do gasto comprometido com a Anthropic em software de parceiros, e não há repasse de receita a desenvolvedores independentes. — <https://www.llms.blog/posts/nobody-got-paid-what-the-gpt-store-chatgpt-apps-and-claude-marketplace-actually-built>
  - (0-3, tier 4) Os marketplaces de IA que funcionam são canais de compra B2B (ex.: Salesforce AgentExchange, lançado em março de 2025 com mais de 200 parceiros), não canais de monetização para criadores individuais. Isso sustenta o fracasso do c2b e do c2c de habilidades e agentes no item (2). — <https://www.llms.blog/posts/nobody-got-paid-what-the-gpt-store-chatgpt-apps-and-claude-marketplace-actually-built>
  - (0-3, tier 3) Um second brain e um company brain compartilham a mesma arquitetura de memória; diferem em consumidor, modelo de permissões e modos de falha, e uma camada bem arquitetada serve ambos da mesma infraestrutura com escopos user_id e org_id. — <https://vectorize.io/articles/second-brain-vs-company-brain>

- **`notVerifiedByBudget`: 33 claims lidas e não verificadas** (o teto `maxVerify` 25 as deixou de fora). Por fonte:

  - 3 × <https://research.macpaw.com/publications/portable-memory/portable-memory.pdf>
  - 2 × <https://www.mondaq.com/uk/contracts-and-commercial-law/1795628/ai-digital-twins-in-the-workplace-the-legal-and-ethical-risks>
  - 2 × <https://www.llms.blog/posts/nobody-got-paid-what-the-gpt-store-chatgpt-apps-and-claude-marketplace-actually-built>
  - 3 × <https://edmcouncil.org/wp-content/uploads/2026/08/EDMWebinar_Solid-and-ODI_Q-and-A_20260714.pdf>
  - 3 × <https://techcrunch.com/2026/11/14/the-ai-graveyard-a-running-list-of-projects-and-startups-that-didnt-make-it/>
  - 1 × <https://code.claude.com/docs/en/memory>
  - 2 × <https://techcrunch.com/2025/10/28/mem0-raises-24m-from-yc-peak-xv-and-basis-set-to-build-the-memory-layer-for-ai-apps>
  - 4 × <https://github.com/swarmclawai/swarmvault>
  - 2 × <https://vectorize.io/articles/second-brain-vs-company-brain>
  - 2 × <https://digitaleconomy.stanford.edu/publication/the-future-of-personal-ai-portable-and-persistent-personal-memory-through-a-unified-human-context-protocol/>
  - 3 × <https://gowlingwlg.com/en/insights-resources/articles/2026/emerging-employment-law-issues-for-employers>
  - 3 × <https://www.inrupt.com/blog/ess-version-3-0-making-consumer-data-ready-for-ai-assistants>
  - 3 × <https://zeli.app/story/50526537>

- **`budgetDropped`: 39 fontes** achadas e não lidas (o teto `maxFetch` 15). As de relevância alta: 
[Zep: The AI Memory Wallet Fallacy](https://blog.getzep.com/the-ai-memory-wallet-fallacy/); [Covington: works council rights in AI implementation projects (jul/2026)](https://www.cov.com/-/media/files/corporate/publications/2026/07/works-council-rights-in-ai-implementation-projects.pdf); [Snyk ToxicSkills: malicious agent skills on ClawHub](https://snyk.io/blog/toxicskills-malicious-ai-agent-skills-clawhub/); [TechCrunch: Meta adquire a Limitless (ex-Rewind)](https://techcrunch.com/2025/12/05/meta-acquires-ai-device-startup-limitless/); [Claude Code Changelog oficial](https://code.claude.com/docs/en/changelog); [TwinMind raises $5.7M for an ambient AI second brain](https://techcrunch.com/2025/09/10/ex-google-x-trio-wants-their-ai-to-be-your-second-brain-and-they-just-raised-6m-to-make-it-happen); [Ardoq acquires GraphLake to build an EA-grade context graph for enterprise AI](https://www.ardoq.com/news/ardoq-graphlake-context-graph-enterprise-ai); [Thoughtworks Radar: context engineering (Adopt)](https://www.thoughtworks.com/en-ec/radar/techniques/context-engineering); [Gartner: What the 2026 Hype Cycle for Agentic AI Reveals](https://gartner.com/en/articles/hype-cycle-for-agentic-ai); [Opal: Private Memory for Personal AI (arXiv, abr/2026)](https://arxiv.org/html/2604.02522v1). A lista integral está no retorno do run.

> ⚠️ Isto pesa sobre o item (2) da pergunta (mercados de vender ou alugar habilidades, agentes e contatos): as claims contrárias foram cortadas ou não lidas. A recomendação de não abrir esse mercado agora vem de **ausência de evidência**, não de evidência contrária. É o motivo da opção D.

## valeu-a-pena

7.762.046 tokens ÷ 70 nós do run ≈ **110.886 por nó**. Só 19 dos 70 nós são achados confirmados (≈ 408 mil por achado); os outros 51 são a pergunta, a decisão, as 4 opções, as 37 objeções do Elenxo, o mercado, as lacunas e 6 superações. O que se comprou: o Elenxo derrubou a premissa da opção A («só de-identificado à nuvem» não confere com o que o app pessoal faz hoje) e separou o que a evidência sustenta do que só a ausência de evidência sugere. O mercado de (2) segue sem prova nos dois sentidos.
