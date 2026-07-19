---
title: "Nota 00 — Síntese: a viz do .kg.yaml se resolve por DIVERGÊNCIA de fator de forma, não por uma ferramenta"
category: discussion-synthesis
status: fonte-de-discussao-isolada
date: 2026-07-19
branch: discuss/kg-visualization-dashboards
amarra: SEED.md (6 dimensões) + NOTE-01..06 + kg-visualization-dashboards.kg.yaml (radar exit 0)
metodo: fan-out orquestrado 7 dimensões (sonnet/medium) + verify adversarial por-claim contra fonte primária (opus/high) — 44 agentes, 37 verdicts
---

# 🧠 Nota 00 — Síntese da discussão "visualização, dashboards e gestão de KG"

> **Isolada.** Pensa, não entrega. Nada vai pro core sem o maestro pedir.
> Cabeça da pasta: leia isto primeiro, depois SEED → NOTE-01..06 → o `.kg.yaml`.

## A tese em uma frase

**A camada de consumo do `.kg.yaml` não converge numa ferramenta — ela DIVERGE por fator de forma:**
desktop-full quer um **motor node-link tipado** (Cytoscape.js) por cima da SSOT; mobile/chat quer o
**oposto — degradar o node-link para texto** (boletim determinístico + node-focus por DOI). Forçar um
renderizador único a servir os dois extremos é o erro. E o achado mais duro: **nenhuma ferramenta de
prateleira 2026 tem fator de forma mobile/chat-native para KG** — o `kg-radar.sh` (texto) e o
`kg-console.sh` (SVG self-contained) já ocupam um nicho real que o mercado deixou vago.

## Os achados que sobreviveram ao verify adversarial (não priors)

Cada um passou por refutação contra **fonte primária** (docs/repo/spec/paper), não landing page. Os
`declarado ≠ verificado` que o verify pegou estão marcados.

1. **Mobile tem teto duro de ~15-20 nós para node-link.** Acima disso degrada para emaranhado — e em
   celular o teto cai ainda mais (Ghoniem/Fekete 2005, CONFIRMED: >20 vértices → matriz bate node-link
   exceto path-finding). Isso **aperta** o prior da irmã `interface-state-of-art` (que estimou ~50 nós
   como teto do `kg-console`): ~50 é o teto de *inspeção desktop*; mobile é ~1/3 disso.
2. **O padrão chat-native é DEGRADAR, não portar.** A rota certa para tela pequena/chat é abandonar o
   canvas interativo em favor de **texto estruturado** (lista/tabela de nós+arestas) — preserva 100% de
   `node_type`/`edge_type`/peso/`plane` como campos e perde só a topologia visual, que é justamente o
   que trava numa tela de celular. É também o formato mais robusto: reflow de texto é trivial.
3. **O `--triples` do `kg-radar` já é o formato "nativo" ideal para LLM.** Triplas lineares soltas batem
   prosa fluida em Q&A fact-intensive (arXiv 2402.11541, CONFIRMED). O output atual já está certo — falta
   só a camada de apresentação para o humano.
4. **Cytoscape.js é o único motor com toque nativo VERIFICADO** (pinch/pan/tap documentados em
   js.cytoscape.org, CONFIRMED). Sigma.js "touch" ficou **PARTIAL/REFUTED** (a doc menciona touch uma vez
   en passant); Reagraph mobile ficou **UNVERIFIABLE/REFUTED-por-ausência** (nem README nem site citam
   mobile). Fidelidade tipada + toque nativo + MIT self-host = Cytoscape é o motor desktop canônico.
5. **Mermaid é frágil em mobile e não pode ser o visualizador primário** (REFUTED como primário): SVG
   estático sem zoom, ilegível acima de ~30-40 nós, ~200 nós travam o browser, e **perde peso numérico e
   o toggle de plane** (issues 5042/1134/2162). Serve só como fatia pequena sob pedido, via Artifact.
6. **GraphRAG/PropertyGraphIndex são camada de RESUMO, não de visualização** (CONFIRMED): verbalizam o
   grafo (comunidades → resumo por LLM), nunca o desenham, e diluem a tipagem fina sem prompt customizado.
7. **Nenhum dashboard framework externo resolve de prateleira** (REFUTED que resolve): Grafana Node Graph
   é capado em ~200 nós e pensado para topologia de infra; Neo4j Bloom/NeoDash, Kùzu Explorer, TerminusDB
   exigem ETL do YAML para um banco alheio (perde o append-mostly em texto puro) e **nenhum tem mobile**.
8. **A rota de transformação mais fiel e barata é NetworkX-como-hub** (CONFIRMED): `.kg.yaml` → PyYAML →
   NetworkX → GraphML + Cytoscape.js JSON simultâneos, passthrough de atributos sem perda. RDF 1.2/RDF-star
   (triple terms para propriedades de aresta) é a investigação semântica futura, mas o tooling 2026 ainda
   é imaturo — não é aposta segura agora.

## A matriz comparativa (fan-in das 6 dimensões)

Critérios do SEED. Fidelidade = ao modelo tipado (nós/arestas tipados, planes DEV/PROD, camadas
audit/domain, peso). Mob/Chat = fator de forma mobile+chat. Esforço = de integração ao `.kg.yaml`.

| Ferramenta / técnica | Fidelidade tipada | Densidade×legibilidade | Mob/Chat | Esforço | Maturidade | Licença/self-host |
|---|---|---|---|---|---|---|
| **Cytoscape.js** | **alta** (seletores→type/edge, rótulo→`on:`) | boa (WebGL opt-in v3.31) | ⚠ só ≤~15 nós | médio | popular | **MIT / sim** |
| Sigma.js (+graphology) | média-alta (attrs livres) | **alta** (WebGL, milhares) | ruim (touch não-doc.) | médio-alto | popular | MIT / sim |
| AntV G6 v5 | alta (types 1ª classe) | alta (WASM/WebGPU) | médio (pointer events) | médio-alto | popular | MIT / sim |
| react-flow / @xyflow | alta (nós React custom) | média (sem layout nativo) | médio (pinch↔zoom conflita) | médio | popular | MIT / sim |
| yFiles / Ogma / KeyLines | alta | alta | ruim/médio | alto | popular | **comercial fechado** ✗ |
| Cosmograph / Reagraph | baixa-média | **altíssima** (GPU) | ruim | alto | emergente | MIT/Apache / sim |
| **Boletim textual / lista-tabela** | **total** (campos) | n/a (não é grafo) | **ótimo** | **baixo** | consolidado | — / sim |
| **--triples → LLM verbaliza** | **total** (se tripla tem tipo) | n/a | **ótimo** | **baixo** (já existe) | consolidado | — / sim |
| Node-focus + DOI (van Ham/Perer) | total no foco | boa (filtro) | **bom** | baixo-médio | consolidado | — / sim |
| Mermaid (em Artifact/GitHub) | **baixa** (perde peso/plane) | ruim (>30 nós) | ⚠ só fatia ≤~20 | baixo | popular | MIT / sim |
| Grafana Node Graph | baixa (arc simula) | ruim (cap 200) | ruim | médio | popular | AGPLv3 / sim |
| Observable Framework / Evidence.dev | alta (build-it-yourself) | métricas, não grafo | ruim | alto | popular/emerg. | ISC/MIT / sim |
| Streamlit + agraph | média-alta | média | ruim | baixo-médio | popular | Apache/MIT / sim |
| Neo4j Bloom/NeoDash · Kùzu · TerminusDB | média (via ETL) | alta | ruim | **alto (ETL)** | popular/emerg. | misto (parcial) |
| **NetworkX (hub de transformação)** | **total** (passthrough) | n/a (é pipeline) | n/a | baixo | popular | BSD / sim |
| GraphML / Cytoscape JSON | alta (tipado) | n/a (formato) | ruim | baixo | consolidado | spec aberta |
| RDF 1.2 / RDF-star | **alta** (triple terms) | n/a | ruim | alto (tooling imaturo) | emergente | W3C |
| Mermaid / DOT (destino) | baixa (achata) | ruim denso | ⚠ | baixo | consolidado | MIT/EPL |

## A recomendação GATED por fator de forma (o deliverable)

> **Tudo GATED** — design-only, isolado. Nada foi pro core; vira `feat/*` só se o maestro promover.
> Os ids são nós do `.kg.yaml` desta estrela (radar exit 0).

### 🖥️ Desktop-full — `D_DESKTOP_CYTOSCAPE`
**Cytoscape.js** como motor canônico de um dashboard interativo por cima da SSOT (seletores CSS-like
mapeiam `node_type`/`edge_type`/`layer`; rótulo de aresta cobre o `on:` de `TRANSITIONS`; peso
`impact×confidence×status` vira largura/tamanho; `plane` vira classe com toggle). **Sigma.js** como via
de escape se o grafo passar de ~1-2k nós. **Melhoria cirúrgica mais barata** do `kg-console.sh` atual
(`C_EDGE_BUNDLING`): trocar o layout circular puro por **edge bundling hierárquico** (Holten) usando
`layer`/`plane` como hierarquia — as 12 combinações de arestas tipadas ficam legíveis sem trocar de
paradigma. yFiles/Ogma/KeyLines **fora** (licença fechada, contra o self-host/spec-as-code do Onion).

### 📱💬 Mobile / chat-native — `D_CHAT_TEXT_FIRST` (o fator de forma principal, a restrição mais dura)
**Texto-primeiro, em camadas de progressive disclosure** — o mantra de Shneiderman traduzido 1:1 para o chat:
1. **Overview (default no chat):** boletim textual **determinístico** gerado direto do YAML (o
   `kg-radar.sh` já faz isso) — fidelidade total ao schema, zero LLM, zero perda.
2. **Zoom/filter:** **node-focus por DOI** — mostra 1 nó + vizinhança de 1-2 hops, score =
   `peso × 1/distância`, filtrável por tipo de aresta (só ao longo de `TRACES_TO`, p.ex.). Determinístico
   a partir do YAML, cabe em qualquer tela.
3. **Details-on-demand:** `--triples` do nó como contexto para o LLM **verbalizar** com as migalhas
   `TRACES_TO` como citação.
4. **"Me desenha isso" (opt-in explícito):** aí, e só aí, um **subgrafo pequeno** (BFS profundidade 1-2,
   ≤~15 nós) em **Mermaid** renderizado via **Claude Artifact** (nativo) ou SVG pré-renderizado
   (`kg-console.sh`) para canais sem render nativo (Slack/WhatsApp/ChatGPT — todos REFUTED para Mermaid
   nativo em 2026). **Nunca** Mermaid como superfície primária.

### 🔁 Transformação — `D_TRANSFORM_NETWORKX`
**NetworkX como hub**: `.kg.yaml` → PyYAML → NetworkX DiGraph (atributos tipados nativos) → exporta
**GraphML** (offline denso: yEd/Gephi) **e Cytoscape.js JSON** (web interativo) do mesmo dict, sem perda.
RDF 1.2/RDF-star anotado como investigação semântica futura (tooling imaturo em 2026).

### 📊 Dashboards / gestão — `D_EVOLVE_NOT_ADOPT`
**Evoluir as superfícies próprias, não adotar framework externo.** Nenhum (Grafana/Neo4j/Observable/
Evidence) tem mobile/chat e todos exigem ETL que mata o append-mostly em texto puro. Se um painel de
**métricas** desktop-full for pedido, Observable Framework ou Evidence.dev (git-first, spec-as-code) são
o melhor encaixe filosófico — mas construídos por cima do YAML como SSOT, nunca substituindo-o.

## A fronteira honesta (o que NÃO se resolveu)

- **Tudo é design-only, isolado.** Nenhuma linha foi pro core. As 4 decisões são candidatas GATED atrás
  de dogfood — a doutrina *gated-until-trigger* deste próprio ecossistema.
- **A gramática soberana do `.kg.yaml` + `kg-radar.sh` NÃO mudam** — isto é camada de consumo POR CIMA.
- **Um worker falhou** na 1ª rodada (a dimensão *mobile* retornou placeholder `"test"`); foi **re-rodada
  fresh** com verify adversarial próprio (NOTE-02) — o modo-de-falha foi pego pela guarda "fase vazia",
  não mascarado. A matriz reflete a re-rodada, não o lixo.
- **Não testado em artefato real:** as recomendações são de pesquisa; nenhum protótipo de Cytoscape/boletim
  foi construído (seria a perna `act` de um futuro `feat/*`, fora do escopo isolado).
- **Ligações vivas:** alimenta `discuss/onion-mobile-app` (a superfície onde o KG mais precisa ser
  consumível — o texto-primeiro é a resposta que aquela estrela esperava). Irmã de `interface-state-of-art`
  (cujo prior de teto ~50 nós este estudo confirmou e apertou). Sem colisão de escopo verificada.

## Método (para auditoria)

Fan-out orquestrado (ferramenta Workflow, padrão pipeline) de **7 dimensões independentes** — research
sonnet/medium (varredura web 2026, popular+emergente) → **verify adversarial por-claim** opus/high contra
fonte primária. **44 agentes, 37 verdicts, ~1.79M tokens.** Tiering explícito por fase (research média /
verify difícil). O verify pegou exageros reais (yFiles "royalty-free" não "com royalty"; Cosmograph
"milhões"→"centenas de milhares"; TerminusDB dashboard não-descontinuado; Mermaid `maxEdges` default 500
não 280). Síntese persistida em `write(KG)`: este NOTE-00 + NOTE-01..06 + `kg-visualization-dashboards.kg.yaml`
(radar exit 0). Fontes primárias completas em cada nota.
