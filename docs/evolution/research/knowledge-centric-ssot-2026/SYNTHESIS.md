# Conhecimento reconciliado como fonte-da-verdade ALÉM DO CÓDIGO — o eixo *knowledge-centric* (mercado + comunidade, até jul/2026)

> **Pesquisa de mercado + comunidade para o maestro PENSAR sobre o eixo em que o Onion evoluiu.**
> Recorte: até julho/2026. Foco NÃO no spec-driven-development (code-centric, já pesquisado no sibling
> `spec-as-code-evolution-2026/`), mas no eixo *knowledge-centric*: **conhecimento organizacional
> multi-vertical (negócio + técnica + compliance) reconciliado como SSOT vivo, com tratamento de
> contradição/drift, onde o código é UM output — não o objetivo.**
>
> **Natureza:** insumo de evidência para a decisão do maestro — **não decide doutrina**. Cada afirmação
> material tem FONTE (URL + veículo + data). Onde não achei fonte sólida, sinalizei. Sem invenção de
> fontes. Distingo sistematicamente **HYPE/discurso vs. IMPLEMENTADO/produto** e **reconcilia-verdade vs.
> só armazena/recupera (RAG)**.

---

## Enquadramento: o eixo tem QUATRO ocupantes reconhecíveis pelo mercado

Diferente do spec-as-code (que tem taxonomia limpa — Böckeler), o eixo knowledge-centric **não tem um nome
consolidado**. Mas o mercado de 2026 já povoou quatro "vizinhanças" que tocam a tese do Onion. A pergunta
não é "existe algo nesse eixo?" (existe, e virou categoria quente em 2026), e sim: **alguém combina as
quatro propriedades do Onion ao mesmo tempo** — (a) multi-vertical PEER (negócio+técnica+compliance como
iguais), (b) reconciliação determinística de contradição/drift com um "quem reconcilia" explícito, (c)
código como byproduct, (d) SSOT vivo? Adianto o veredito: **o EIXO é habitado; a INTERSEÇÃO das quatro é rara.**

---

## 1. Enterprise/Organizational Knowledge Graphs como SSOT

**Palantir Foundry Ontology** é o exemplar mais forte e mais IMPLEMENTADO de "modelo vivo da organização":
a própria doc da Palantir chama a Ontology de *"digital twin of an organization"*, com elementos **semânticos**
(objetos, propriedades, links) e **kinéticos** (ações, funções, segurança dinâmica); ao incorporar modelos ML,
*"the Ontology becomes a single source of truth… not just in terms of data, but also in terms of logic"* — o
"golden record" do qual dashboards, agentes e workflows leem/escrevem [1][2]. Isto é produto real, com evolução
2024–2025 (Interfaces, derived properties, Ontology-Backed Objects no AIP) [1].

**Reconcilia verdade ou é catálogo estático?** No mercado de Enterprise KG a reconciliação existe, mas
**opera no nível de ENTIDADE/DADO**, não de "verdade peer" negócio/técnica/compliance: entity resolution
com merge automático a ~95% de confiança e flag para revisão humana a ~70% [3]; versionamento de ontologia
+ propagação de mudança aparece como **pergunta-chave de avaliação de fornecedor** [4] (i.e., ainda não é
resolvido — é critério de compra). A KGC 2026 relatou o problema vivo de "document reconciliation com centenas
de emendas/dia" para o grafo "sempre refletir a verdade corrente" [3][5]. Mercado: **USD 3,47 bi em 2026,
CAGR 21,3%** [3]. `data.world` se posiciona como *"o único data catalog construído sobre arquitetura de
knowledge graph"* [6].

**Honestidade:** o grafo enterprise é VIVO no sentido de dados fluindo, e RECONCILIA identidade de entidade —
mas "reconciliar contradição entre verdades de negócio vs. técnica vs. compliance" com um árbitro nomeado
**não é o que estas plataformas fazem**; elas unificam dados e resolvem identidade. Palantir é o mais próximo
de "modelo de lógica + dados vivo", mas compliance ali é *use case sobre a ontologia*, não uma vertical peer
com sua própria verdade a reconciliar.

## 2. Context engineering FORA do SDLC

A 1ª pesquisa só achou "context layer for SDLC" (código). **Existe, sim, context engineering para conhecimento
de NEGÓCIO/ESTRATÉGIA/COMPLIANCE** — e virou tese central de 2026. Atlan: context engineering *"turns scattered
organizational knowledge — metric definitions in dbt, lineage in Snowflake, **policies in governance platforms**,
entity relationships in knowledge graphs — into governed, machine-readable context that any AI agent can use"* [7].
O arXiv 2603.09619 ("Context Engineering: From Prompts to Corporate Multi-Agent Architecture") nomeia **três
dimensões** — tecnológica, informacional e **social** [8] (ecoando as "3 dimensões peer" do Onion, mas ali são
dimensões DO CONTEXTO, não verticais organizacionais). Dado-chave de mercado (via Atlan, citando Gartner): *"83%
dos líderes concordam que IA agêntica não atinge valor em produção sem uma **context platform**"* e Gartner projeta
40% dos apps enterprise com agentes até fim de 2026 [7].

**Honestidade:** o discurso já é knowledge-centric (não só código) — mas o *produto* por trás é majoritariamente
**a camada de dados/metadados alimentando agentes**. Estratégia e compliance entram como *fontes de contexto*,
não como verticais reconciliadas entre si.

## 3. Decision Intelligence (Gartner e cia)

Gartner define DI como *"disciplina prática que avança a tomada de decisão entendendo e engenheirando
explicitamente como decisões são feitas"* [9]. **Causal AI** (modelos causa-efeito, além de correlação) é o
motor "sério" [10][11]. Plataformas de DI *"permitem desenhar e modelar decisões explicitamente, orquestrar o
fluxo de decisão em escala e monitorar/governar a qualidade da decisão"* [9][12]. Há até patentes de
*"automated empathetic reconciliation of decisions of AI models"* [13].

**Honestidade:** DI **modela a decisão** e às vezes reconcilia *saídas de modelos* — mas o coração é
decisão+orquestração+governança, mais próximo de **dashboards/simulação** do que de "reconciliação de verdades
organizacionais contraditórias". Não é o eixo do Onion; é adjacente pelo lado "decidir com o conhecimento".

## 4. Digital Twin of an Organization (DTO) — conceito Gartner

Gartner define DTO como *"modelo de software dinâmico que usa dados operacionais e contextuais para entender
como a organização operacionaliza seu modelo de negócio… simula estados futuros e entrega valor"* [14][15]. É
conceito ADOTADO e institucionalizado: **Market Guide** dedicado [16], **Magic Quadrant** para plataformas DTO
apresentado no IT Symposium/Xpo 2026 (Barcelona) [17], previsão de que *"até 2026, 25% das enterprises globais
adotarão process mining como 1º passo para um digital twin das operações"* [15]. Capacidades incluem múltiplos
esquemas de medição (operacional, financeiro, qualidade, SLA) e como interagem no modelo operacional [14].

**Honestidade:** DTO é o rótulo Gartner mais próximo de "a ontologia como modelo vivo da empresa" — porém na
prática o caminho de adoção é **process mining → operações**, não uma ontologia epistêmica que reconcilia
negócio+técnica+compliance como peers. É "twin das OPERAÇÕES", não "twin do CONHECIMENTO reconciliado".

## 5. Reconciliação/contradição de conhecimento — **o coração da tese** (e a melhor companhia real)

Aqui está o achado mais denso e mais HONESTO para o maestro: existe um **revival vigoroso, em 2026, de
truth-maintenance / belief-revision / conflito de verdade** — mas quase todo ele endereça **MEMÓRIA DE AGENTE**,
não conhecimento organizacional multi-vertical.

- **TOKI: A Bitemporal Operator Algebra for Contradiction Resolution in LLM-Agent Persistent Memory** (Ziming
  Wang, HKUST, arXiv:2606.06240, **4/jun/2026**) — o cognato conceitual mais forte. Tese: *"contradiction
  resolution IS write-time concurrency control"*; tipifica as 4 heurísticas de produção (last-writer-wins,
  evidence-weighted merge, await-confirmation, per-rule policy) como **uma família de operadores bitemporais**
  sobre esquema dual-row, cada um com pré-condição de isolamento e **anotação de proveniência que preserva o
  fato perdedor numa audit row** [18]. Isto é, literalmente, "quem reconcilia e como, sem apagar a verdade
  vencida" — exatamente a doutrina "git merge não reconcilia verdades", mas aplicada a memória de agente.
- **"Don't Ask the LLM to Track Freshness: A Deterministic Recipe for Memory Conflict Resolution"**
  (arXiv:2606.01435) — reconciliação **determinística** de conflito de memória (não confie no LLM) [19]. Ecoa o
  "radar determinístico" do Onion.
- **Temporal Validity in Retrieval Memory** (arXiv:2606.26511) — elimina "stale-fact errors" sobre conhecimento
  em evolução [19]. **Zep** — temporal KG com modelagem **bi-temporal** (quando o fato é válido vs. quando foi
  registrado) [20]. **KARMA** — 9 agentes colaborativos incluindo **conflict resolution** para enriquecer KG [20].
- Literatura de memória 2026 confirma o gap: sistemas atuais *"tratam beliefs como artefatos de nível-prompt,
  assumem updates monotônicos e carecem de mecanismo explícito de belief revision diante de evidência
  contraditória"* [20] — ou seja, a comunidade **reconhece o buraco** que a tese do Onion ocupa.

**GraphRAG (Microsoft) reconcilia ou só recupera?** **Só recupera** (com sumarização de comunidade) [21].
Evidência dura: GraphRAG atinge **64% de acurácia em documentos versionados e falha catastroficamente (10%)
em detecção de mudança implícita**, custando 16× mais tokens de indexação [22]. Surgiram **VersionRAG** [22] e
CRONKGQA/TempRALM para o temporal — mas *"assumem estruturas temporais pré-existentes, não extraem relações de
versão"* [22]. **RAG ≠ reconciliação de verdade** — confirmado empiricamente.

**Honestidade:** este é o eixo onde o Onion tem PARENTES DIRETOS (bitemporal, belief revision, reconciliação
determinística de contradição preservando o perdedor) — **mas todos operam em memória de agente / KG de dados,
não em conhecimento organizacional peer negócio+técnica+compliance**. É a mesma *maquinaria epistêmica*, aplicada
a um *objeto diferente*.

## 6. Compliance/governança como conhecimento vivo

**Policy-as-code / compliance-as-code** amadureceu: políticas viram regras avaliadas automaticamente em cada
deploy/config; caso citado de telecom economizou **US$ 1,8 mi e 2.000 h/ano** ao integrar compliance-as-code no
CI/CD [23]. **Policy Knowledge Graphs (PKG)** mapeiam políticas organizacionais a artigos regulatórios (GDPR,
CCPA) com gap analysis via SPARQL/Cypher [24][25]. MetricStream defende KG em GRC para relatórios/compliance [26].
Plataformas (Vanta, Drata, Secureframe, Hyperproof, ServiceNow GRC, OneTrust) coletam evidência técnica
automaticamente de AWS/Azure/GCP/GitHub/IdP [23].

**Integra com negócio+técnica ou é silo?** GRC **coleta evidência técnica** e a liga a controles — logo integra
técnica→compliance. Mas permanece **silo de GRC**: o eixo é "regulação ↔ controle ↔ evidência", não "negócio ↔
técnica ↔ compliance como três verdades peer reconciliadas num único modelo". Collibra é citada como a âncora de
governança *"formal, policy-driven, audit-ready"* de enterprises reguladas [27] — governança profunda, mas
data-cêntrica.

## 7. O ângulo multi-vertical — **ALGUÉM unifica negócio + técnica + compliance num único modelo reconciliado?**

Este é o teste decisivo. A resposta do mercado 2026: **quase — em metadados; não — como verticais epistêmicas peer.**

- **Atlan "Active Ontology"** (2026) é o cognato de MERCADO mais próximo da arquitetura multi-grafo do Onion:
  *"machine-readable model… continuamente ligado a sinais operacionais"* com **arquitetura de quatro grafos** —
  data graph, **governance graph (ownership, policies)**, knowledge graph (termos de negócio), active ontology
  graph (regras/constraints) — todos sobre um substrato lakehouse comum *"prevenindo fork em sistemas separados"*
  [28]. Combate explicitamente **"ontology drift"** (*"static ontologies… drifting by day 30"*) e distingue
  *"semantic layers serve dashboards; active ontologies serve agents"* [28]. **Mas** as quatro dimensões são
  **facetas de metadados de dados** (data/governance/knowledge/rules), não **negócio/técnica/compliance como
  verticais organizacionais iguais** — e a "vertical" real de Atlan é governança de dados.
- **Metadata knowledge graph** unifica *"metadata técnico, de negócio, lineage, qualidade e uso num grafo
  interconectado"* [29] — de novo, unificação de **metadados**, não de verdades de três domínios peer.
- Alerta recorrente da própria indústria: *"um KG sem stewardship contínuo de ontologia degenera em silos"* [30] —
  o problema do "quem reconcilia" é **reconhecido mas não resolvido** de forma nomeada.

**Honestidade:** ninguém no material encontrado unifica **negócio + engenharia + compliance como três verticais
peer** num único modelo reconciliado. O que existe é unificação de **metadados/dados** (Atlan, data.world) ou de
**operações** (DTO) ou de **compliance** (PKG/GRC). As ferramentas continuam segregadas por domínio: produto vs.
eng vs. GRC — exatamente o silo que a tese do Onion diz atacar.

## 8. "Company as a knowledge graph" / second-brain organizacional / AI-native KM

Categoria **nascida em 2026** — e a mais próxima do Onion em AMBIÇÃO (embora não em maquinaria de reconciliação):

- **"Company Brain"** foi listado como categoria #4 nos **Y Combinator Requests for Startups (Summer 2026)**,
  liderado por Tom Blomfield: *"um sistema que puxa conhecimento de fontes fragmentadas, estrutura, mantém
  corrente, e o transforma num executable skills file para IA"* [31][32]. Startups nomeadas na corrida:
  **Falconer, Colrows, Ability.ai, Klikflo, Webair, nBrain** [31].
- Definição emergente: *"a living, governed model of what an organization knows and how it operates, structured
  so both people and AI agents can act on it safely"* — **entidades tipadas, definições de métrica governadas,
  relações provadas e políticas aplicáveis** [31]. Isto é notavelmente convergente com o Onion.
- **Vectorize "Brain Stack"** (1/jun/2026): taxonomia Second Brain (indivíduo) → Company Brain (org) → Single
  Brain (multi-agente), sobre um "learning memory substrate"; afirma que a consolidação deve *"reconcile
  contradictions"* automaticamente, sintetizando em vez de mostrar as duas — **mas não especifica QUEM decide
  nem governança de autoridade de reconciliação** [33].
- **Colrows** (produto real) é o mais honesto: assume possuir **só o pilar data-semantics**, reconhecendo que
  *"um company brain completo abrange dados, documentos, processo, política e cultura"* — e trata desacordo como
  **prevenção em compile-time** (*"the brain enforced consensus at compile time"* via definição única), **não
  como reconciliação de verdades conflitantes** [34].

**Honestidade:** a AMBIÇÃO "empresa como grafo de conhecimento vivo" agora tem selo YC e uma dúzia de startups —
mas (i) **ninguém entrega o span completo** (Colrows admite cobrir uma fatia; YC descreve o resto como aspiração),
(ii) o tratamento de contradição é ou **consolidação automática opaca** (Vectorize) ou **prevenção por definição
única** (Colrows) — **não** uma doutrina de reconciliação com árbitro nomeado e preservação do fato perdedor.

---

## (a) Mapa em um parágrafo: onde esse eixo está (jul/2026)

O eixo *knowledge-centric* — conhecimento organizacional vivo como SSOT — **deixou de ser vazio e virou território
disputado em 2026**, mas fragmentado em quatro vizinhanças que não se falam: (1) **Enterprise/Organizational
Knowledge Graphs** com Palantir Foundry Ontology na ponta implementada ("digital twin da org", golden record de
dados+lógica) e um mercado de US$3,47 bi, porém reconciliando **identidade de entidade**, não verdades peer; (2)
**Digital Twin of an Organization** como o rótulo Gartner institucional (Market Guide + Magic Quadrant 2026),
porém puxado para **operações/process mining**; (3) o **revival de truth-maintenance/belief-revision/bitemporal**
(TOKI, "Don't Ask the LLM to Track Freshness", Zep, KARMA) que é a **maquinaria epistêmica gêmea** do radar do
Onion — reconciliação determinística de contradição com proveniência do fato perdedor — mas aplicada a **memória
de agente**, não a conhecimento organizacional; e (4) a categoria **"Company Brain"** nascida em 2026 (YC RFS #4,
Blomfield; Falconer/Colrows/Atlan active-ontology) que compartilha a AMBIÇÃO "empresa como grafo de conhecimento
governado e vivo" mas cujo tratamento de contradição é imaturo (consolidação opaca ou prevenção por definição
única) e cujo span nenhum player cobre inteiro. Transversalmente, **RAG (incl. GraphRAG) foi empiricamente
desmascarado como recuperação, não reconciliação** (64%/10% em docs versionados), o que fortalece a tese de que
"reconciliar verdade" é problema distinto de "recuperar conhecimento".

## (b) VEREDITO EXPLÍCITO sobre a pergunta central

**O Onion NÃO está sozinho no EIXO, mas é RARO — possivelmente sem cognato nomeado — na INTERSEÇÃO específica.**

- No **eixo amplo** ("conhecimento organizacional vivo como SSOT"), o Onion tem **muita companhia** e chega
  depois de gigantes: Palantir Ontology, Gartner DTO, Atlan active ontology e toda a categoria Company Brain
  ocupam esse espaço. Afirmar "estamos sozinhos em usar conhecimento como fonte-da-verdade viva" seria **falso**.
- Mas a TESE do Onion é a **conjunção de quatro propriedades**, e é aqui que a companhia se dissolve:
  1. **Multi-vertical PEER** (negócio + técnica + compliance como três verdades IGUAIS num único modelo) —
     **não encontrei ninguém** que faça isto. Todos os players são ancorados numa vertical (dados em Atlan/Palantir;
     operações em DTO; regulação em GRC/PKG; data-semantics em Colrows) e tratam as outras como *fontes de contexto*,
     não como peers a reconciliar. O silo produto/eng/GRC persiste no mercado.
  2. **Reconciliação determinística de contradição/drift com "quem reconcilia" explícito e preservação do fato
     perdedor** — existe como **maquinaria** (TOKI bitemporal, reconciliação determinística de memória), mas
     **aplicada a memória de agente**, nunca a conhecimento organizacional multi-vertical. A doutrina "git merge
     não reconcilia verdades" não tem equivalente nomeado no material — o mais próximo é TOKI ("resolução de
     contradição É controle de concorrência write-time").
  3. **Código como UM output, não o objetivo** — o campo spec-as-code (sibling) é code-centric; o campo
     knowledge-centric (aqui) é data/agent-centric. **Ninguém posiciona código como byproduct de um modelo de
     conhecimento reconciliado multi-vertical.**
- **Por quê o Onion parece raro:** cada propriedade isolada tem dono; **a conjunção não tem**. O mercado resolveu
  *unificação de metadados* (Atlan), *reconciliação epistêmica de memória* (TOKI/Zep), *modelo vivo da org*
  (Palantir/DTO) e *ambição company-brain* (YC) — **em silos separados**. O Onion é a hipótese de **costurar as
  quatro numa doutrina só**. Isso é diferenciação real, não vácuo — mas também significa **pouca validação externa
  do combo**; os riscos que a comunidade já aponta (stewardship de ontologia que degenera em silo [30]; contradição
  tratada de forma opaca [33]; "quem reconcilia" não resolvido [4]) são precisamente os que o Onion precisa provar
  que resolve, e não pode se apoiar em ninguém tendo resolvido antes.

**Resumo do veredito:** eixo povoado; **interseção (multi-vertical peer + reconciliação determinística com árbitro
nomeado + código-byproduct) rara a ponto de não ter cognato nomeado.** Companhia existe *por propriedade*, não *por
combinação*.

## (c) Candidatos de NOME para a categoria (hoje sem nome limpo)

O mercado ainda não nomeou o combo do Onion. Nomes existentes cobrem só fatias:

- **"Company Brain"** — nome com maior tração (YC-blessed, 2026) [31][32]; captura ambição, **não** captura
  multi-vertical peer nem reconciliação de contradição.
- **"Active Ontology"** (Atlan) [28] / **"Digital Twin of an Organization / DTO"** (Gartner) [14] — nomes
  institucionais para "modelo vivo da org", mas ancorados em dados/operações.
- Candidatos que descrevem melhor o Onion (leitura própria, **não** são termos consagrados):
  **"Reconciled Organizational Knowledge Graph"**, **"Multi-Vertical Knowledge Reconciliation (SSOT)"**,
  **"Epistemic SSOT / Camada de Reconciliação Epistêmica"**, **"Reconciled Company Brain"**,
  **"Peer-Ontology of the Organization"** (as 3 verticais peer), ou o mais fiel à doutrina do Onion:
  **"Truth-Reconciled Organizational Ontology"** (traz o TMS-revival para o objeto organizacional).
  Ressalva: nenhum destes últimos aparece na literatura — são propostas para batizar o vácuo, não citações.

---

## Ressalvas de honestidade

- **Datas de conteúdo de fornecedor** (Atlan active ontology, Colrows, Vectorio brain-stack, colrows company-brain)
  vêm das próprias páginas/marketing; tratei como discurso datado, não como fato independente.
- **Números de mercado** (US$3,47 bi Enterprise KG; US$12,89 bi active metadata; 83%/40% Gartner via Atlan) vêm de
  posts de fornecedor citando analistas — indicativos de ordem de grandeza, **não** verificados na fonte primária Gartner.
- **Relatórios Gartner primários** (DTO Market Guide, Magic Quadrant, Quick Answer) são **paywalled**; confirmei
  título/existência/data via páginas Gartner públicas e resumos de terceiros, não o conteúdo integral.
- **YC RFS Summer 2026 "Company Brain" (#4, Blomfield)** e as startups nomeadas vêm de posts secundários (colrows,
  vectorize); a página oficial YC RFS não foi fetch-verificada aqui.
- **arXiv de jun/2026** (TOKI 2606.06240; 2606.01435; 2606.26511; 2603.09619) — datas/títulos/abstracts confirmados
  via busca; **não li os PDFs integrais**. TOKI e a família bitemporal são os cognatos mais fortes e merecem leitura
  primária antes de citar em doutrina.
- **Onion não foi buscado** — não é reconhecido pelo mercado (framework interno); a conclusão "raro/solo" é sobre a
  **ausência de cognato do combo**, não sobre desconhecimento do Onion.
- **"Multi-vertical peer", "código como byproduct" e os nomes propostos em (c)** são leitura própria do padrão; onde
  não há termo de mercado, sinalizei. Nenhuma fonte foi inventada; onde não achei, disse.

---

## Sources

1. Palantir — "Models in the Ontology" (docs Foundry). https://www.palantir.com/docs/foundry/ontology/models — Overview: https://www.palantir.com/docs/foundry/ontology/overview — "digital twin of an organization".
2. Palantir Foundry Ontology (produto). https://www.palantir.com/explore/platforms/foundry/ontology/ — Core concepts: https://www.palantir.com/docs/foundry/ontology/core-concepts
3. "Enterprise Knowledge Graph: Architecture & Use Cases 2026" — Improvado. https://improvado.io/blog/enterprise-knowledge-graph (mercado US$3,47 bi; entity resolution 95%/70%; KGC 2026 doc reconciliation).
4. "Enterprise Knowledge Graph Buyer's Guide 2026 | Vendor Comparison" — Promethium. https://promethium.ai/guides/enterprise-knowledge-graph-buyers-guide-2026/ (versionamento de ontologia como pergunta de avaliação).
5. Giuseppe Futia, "Notes from KGC 2026" — Medium, mai/2026. https://medium.com/@giuseppefutia/notes-from-kgc-2026-c9b4ac8569e5
6. data.world — "Atlan vs Collibra / built on a knowledge graph". https://data.world/resources/compare/atlan-vs-collibra/
7. Atlan, "What Is Context Engineering? Complete 2026 Guide". https://atlan.com/know/what-is-context-engineering/ (policies em governance platforms como contexto; 83%/40% via Gartner).
8. "Context Engineering: From Prompts to Corporate Multi-Agent Architecture" — arXiv:2603.09619. https://arxiv.org/pdf/2603.09619 (três dimensões: tecnológica/informacional/social).
9. Gartner via "What is Decision Intelligence? From Data to Action [Gartner, 2026]" — C&F. https://candf.com/our-insights/articles/what-is-decision-intelligence-from-data-to-action/ — Gartner Peer Insights market: https://www.gartner.com/reviews/market/decision-intelligence-platforms
10. "Causal AI: Use Cases, Need, Benefits…" — LeewayHertz. https://www.leewayhertz.com/causal-ai/
11. Decision intelligence — Wikipedia. https://en.wikipedia.org/wiki/Decision_intelligence
12. Quantexa, "What is Decision Intelligence?". https://www.quantexa.com/resources/what-is-decision-intelligence-guide/
13. USPTO — "Automated empathetic reconciliation of decisions of AI models" (patente). https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/12045731
14. Gartner, "Quick Answer: What Is a Digital Twin of an Organization?". https://www.gartner.com/en/documents/4004172
15. Mavim, "Digital Twin of an Organization Market Guide from Gartner®". https://www.mavim.com/gartner/digital-twin-of-an-organization-market-guide (25% até 2026 via process mining).
16. Gartner, "Market Guide for Digital Twin of an Organization Platforms". https://www.gartner.com/en/documents/5936107 — Peer Insights: https://www.gartner.com/reviews/market/digital-twin-of-an-organization-platforms
17. Gartner, "Magic Quadrant for Digital Twin of an Organization Platform" — IT Symposium/Xpo 2026, Barcelona. https://www.gartner.com/en/conferences/emea/symposium-spain/sessions/detail/5217436-Magic-Quadrant-for-Digital-Twin-of-an-Organization-Platform
18. Ziming Wang (HKUST), "TOKI: A Bitemporal Operator Algebra for Contradiction Resolution in LLM-Agent Persistent Memory" — arXiv:2606.06240, 4/jun/2026. https://arxiv.org/abs/2606.06240
19. "Don't Ask the LLM to Track Freshness: A Deterministic Recipe for Memory Conflict Resolution" — arXiv:2606.01435. https://arxiv.org/pdf/2606.01435 — "Temporal Validity in Retrieval Memory" — arXiv:2606.26511. https://arxiv.org/pdf/2606.26511
20. "2026 Memory Literature Scan — LLM Agent Research". https://lin-guanguo.github.io/llm-memory-research/memory.literature-scan/ (Zep bi-temporal; belief revision gap) — KARMA (multi-agent KG, conflict resolution): https://openreview.net/forum?id=k0wyi4cOGy
21. Microsoft Research — Project GraphRAG. https://www.microsoft.com/en-us/research/project/graphrag/
22. "VersionRAG: Version-Aware Retrieval-Augmented Generation for Evolving Documents" — arXiv:2510.08109. https://arxiv.org/pdf/2510.08109 (GraphRAG 64%/10% em docs versionados; CRONKGQA/TempRALM assumem estrutura temporal pré-existente).
23. "What Is Compliance as Code (And Why GRC Is Falling Behind Without It)" — GRC Pros, Substack. https://grcprosblog.substack.com/p/what-is-compliance-as-code-and-why — "GRC in 2026" — UnderDefense. https://underdefense.com/blog/governance-risk-compliance/
24. "Policy Knowledge Graph for Regulatory Analysis" — Emergent Mind. https://www.emergentmind.com/topics/policy-knowledge-graph-pkg
25. "Knowledge Graphs in Governance, Risk, and Compliance" — MetricStream. https://www.metricstream.com/blog/potential-knowledge-graphs-grc.html
26. compliance-as-code — GitHub Topics. https://github.com/topics/compliance-as-code
27. Atlan, "Alation vs OpenMetadata vs Collibra vs Atlan". https://atlan.com/alation-vs-collibra-vs-openmetadata-vs-atlan/ (Collibra = governança formal/audit-ready).
28. Atlan, "Active Ontology: The 2026 Default for Enterprise AI". https://atlan.com/know/what-is-active-ontology/ (arquitetura de 4 grafos; ontology drift by day 30; ontology serve agents vs semantic serve dashboards).
29. Atlan, "What Is Metadata Knowledge Graph & Why It Matters in 2026?". https://atlan.com/know/metadata-knowledge-graph/
30. "Ontologies and Knowledge Graphs: Why They Work Better Together" — d.AP Blog. https://www.digetiers-dap.com/post/ontologies-and-knowledge-graphs (KG sem stewardship degenera em silos) — arXiv "Ontology-Compliant Knowledge Graphs": https://arxiv.org/html/2603.21188v2
31. "Company Brain for Enterprise AI: Why the Data Layer Decides Everything" — Colrows. https://colrows.com/blogs/company-brain-for-enterprise-ai/ (YC RFS Summer 2026 #4, Tom Blomfield; startups Falconer/Colrows/Ability.ai/Klikflo/Webair/nBrain; def. "living governed model").
32. "Knowledge management has outgrown note-taking" — Tejas Sharma, The AI Second Brain (Medium), mai/2026. https://medium.com/the-smart-founder/knowledge-management-ai-trends-2026-d5b64d7dd1e0
33. Vectorize, "The Brain Stack: Second, Company, and Single Brain Explained", 1/jun/2026. https://vectorize.io/articles/brain-stack-second-company-single-brain (consolidação "reconcile contradictions"; não define quem decide) — "How to Build a Company Brain": https://vectorize.io/articles/how-to-build-company-brain
34. Colrows (produto) — pilar data-semantics; consensus em compile-time. https://colrows.com/blogs/company-brain-for-enterprise-ai/
