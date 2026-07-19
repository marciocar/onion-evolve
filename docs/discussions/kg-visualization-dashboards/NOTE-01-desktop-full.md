---
title: "Nota 01 — Desktop-full: libs de graph-viz e a fidelidade ao modelo tipado"
category: discussion
status: fonte-de-discussao-isolada
date: 2026-07-19
branch: discuss/kg-visualization-dashboards
amarra: SEED dimensão 1 · nós C_CYTOSCAPE_DESKTOP, C_SIGMA_SCALE, D_DESKTOP_CYTOSCAPE
---

# 🖥️ Nota 01 — Libs de graph-viz desktop-full (estado 2026)

> Isolada. Pensa, não entrega. Ver NOTE-00 para a síntese e a recomendação gated.

## Estado 2026 (popular vs emergente)

Três faixas: (1) **toolkits batteries-included** maduros — Cytoscape.js, Sigma.js, vis-network, AntV G6
v5; (2) **primitivas compositáveis** — D3/d3-force, Graphology (dados, não renderer), Observable Plot
(tabular, sem mark de rede dedicado); (3) **GPU/alta escala e comercial** — Cosmograph/cosmos.gl
(layout 100% GPU), Reagraph (WebGL 3D via R3F), Ogma/yFiles/KeyLines (comerciais fechados). A **tensão
central**: libs ricas em semântica tipada (Cytoscape, G6, yFiles) × libs de performance bruta (Sigma,
Cosmograph) que sacrificam expressividade de estilo-por-tipo por FPS em grafos densos.

## Itens-chave

| Lib | Fidelidade ao `.kg.yaml` | Maturidade | Licença |
|---|---|---|---|
| **Cytoscape.js** | **maior** — seletores CSS-like ≈ 1:1 p/ `node_type`/`edge_type`/`layer`; rótulo de aresta p/ `on:`; compound nodes p/ audit/domain ou plane. Não tem peso composto nativo (computar no styleFunction) | popular | **MIT** |
| Sigma.js | graphology carrega qualquer atributo tipado; estilo por reducers (imperativo, menos declarativo) | popular | MIT |
| AntV G6 v5 | options declarativa boa p/ types/layer; ecossistema doc chinês/inglês, curva maior | popular | MIT |
| react-flow/@xyflow | Node/Edge TS ≈ node_type/edge_type; `EdgeLabelRenderer` p/ `on:`; **sem layout nativo** (Dagre/ELK externos) — plane/camada exige posicionamento externo | popular | MIT |
| Cosmograph/cosmos.gl | escala bruta (centenas de milhares), mas estilo por tipo rudimentar | emergente | MIT |
| yFiles / Ogma / KeyLines | layout/toque de topo, mas **licença comercial fechada** — fora do self-host Onion | popular | comercial ✗ |

## Claims verificados (adversarial → fonte primária)

- **Cytoscape.js — PARTIAL.** MIT confirmado (js.cytoscape.org: "Permissive open source license (MIT)…");
  v3.34.0 (2026-06-02); seletores `node[weight>50]` + estilo de aresta confirmados; Dagre/ELK existem.
  **Ressalva:** o "70" é o total de extensões (badge), não 70 extensões *de layout* — o claim conflacionou.
- **Sigma.js — CONFIRMED.** "visualizing graphs of thousands of nodes and edges using WebGL" + "built on
  top of graphology"; layout é CPU (graphology-layout-forceatlas2 / d3-force), **não GPU nativo**.
- **AntV G6 v5 — CONFIRMED.** `@antv/g` (Canvas/SVG/WebGL); layouts parcial em Rust (`@antv/layout-wasm`,
  opt-in); `Graph` subsume `TreeGraph` (`treeToGraphData`).
- **react-flow — CONFIRMED.** MIT; nós/arestas custom + tipos TS; `EdgeLabelRenderer`; **"We have not
  implemented our own layouting solution yet"** → Dagre/ELK externos (todas as 4 asserções sustentadas).
- **yFiles — REFUTED.** O SLA diz **"royalty FREE"** (§2.2.2-2.2.4), o oposto de "com royalty" do claim;
  "~10 mil membros de API" UNVERIFIABLE. (É comercial/perpétuo/proprietário: isso confirma.)
- **Cosmograph — PARTIAL.** GPU-shaders + migração regl→luma.gl (v3.0) confirmados; **escala é "hundreds
  of thousands", NÃO "milhões"** como o claim escreveu.

## kg_fit (desktop-full)

**Cytoscape.js** como motor de renderização canônico (`D_DESKTOP_CYTOSCAPE`), **Sigma.js** como escape de
escala. G6 v5 é peer forte mas prova-de-conceito, não default. react-flow é para *edição nó-a-nó*, não
visão macro. Comerciais fora. Esta dimensão **não** resolve mobile/chat — ver NOTE-02/03.
