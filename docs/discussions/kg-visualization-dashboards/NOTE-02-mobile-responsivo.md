---
title: "Nota 02 — Mobile responsivo: o teto duro de ~15 nós e o gesto que já é resolvido"
category: discussion
status: fonte-de-discussao-isolada
date: 2026-07-19
branch: discuss/kg-visualization-dashboards
amarra: SEED dimensão 2 · nós C_MOBILE_CEILING, C_CYTOSCAPE_TOUCH, C_DEGRADE_TEXT
nota_de_processo: "dimensão re-rodada fresh — o worker da 1ª rodada retornou placeholder 'test' (bug); pego pela guarda de fase-vazia, não mascarado"
---

# 📱 Nota 02 — Grafo responsivo em mobile (estado 2026)

> Isolada. Pensa, não entrega. Ver NOTE-00 para a síntese e a recomendação gated.

## Estado 2026

Node-link **funciona** em celular para grafos pequenos: as libs maduras (Cytoscape, Sigma, G6, react-flow)
já entregam pan/pinch/tap por toque **out-of-the-box** — o gargalo **não é mais o gesto**, é **densidade
e legibilidade de rótulo**. Vetor emergente: **GPU no cliente** (Cytoscape WebGL opt-in v3.31, G6 v5
WebGPU/WASM) — mas **WebGPU ainda não roda em mobile**, então WebGL é o teto de aceleração no celular hoje.
Tensão: as libs otimizaram *escala* (milhares de nós via GPU) enquanto o problema real do celular é
*cognição em pouco espaço* — que se resolve por semantic zoom + LOD + clustering, que são **técnicas, não
features prontas**.

## Itens-chave (com mobile_fit verificado)

| Lib/técnica | mobile_fit | evidência |
|---|---|---|
| **Cytoscape.js** | **bom** | único que documenta gestos touch explícitos (pinch/pan/tap/box-3-dedos) |
| Sigma.js v4 | médio | WebGL bom p/ densidade, mas docs quase não tratam touch (menção única) |
| AntV G6 v5 | médio | v5 unificou mouse+touch sob **pointer events**; `@antv/g6-mobile` era pacote v4 legado |
| react-flow | médio | `zoomOnPinch` + exemplo Touch Device, MAS pinch pode zoomar o *browser* (issue #5066) |
| Reagraph | **ruim (achado)** | **nenhuma menção** a mobile/touch/responsivo na doc ou README; 3D piora tela pequena |
| vis-network (wrapper React) | ruim/médio | core tem touch, wrapper estagnado (~6 anos) |
| **Semantic zoom + LOD** | **essencial** | a representação muda com a escala; reduz carga cognitiva |
| **Degradar → lista/matriz/texto** | **o padrão-chave** | abandonar node-link é *feature*, não falha |

## Claims verificados (adversarial → fonte primária)

- **Cytoscape.js touch — CONFIRMED.** Doc: "Pinch to zoom: touch & desktop", "Box selection: touch (three
  finger swipe)", "Builtin support for standard gestures on both desktop and touch".
- **Cytoscape WebGL default — PARTIAL.** WebGL é **opt-in** (`webgl:true`, v3.31), não default; escolha de
  WebGL sobre WebGPU justamente porque "WebGPU… not yet available for mobile devices". Mobile é intenção
  declarada, não benchmark (FPS medidos em desktop).
- **Sigma.js touch — PARTIAL/REFUTED.** A doc menciona touch **uma vez en passant**; sem seção de mobile/
  multi-touch. Cético → não CONFIRMED.
- **G6 v5 pointer events — CONFIRMED.** "The `mouse` and `touch` events… unified under the `pointer` event."
- **react-flow touch — CONFIRMED (com ressalva).** "connect nodes on a touch device by tapping two handles";
  handles maiores p/ dedo. Ressalva: conflito pinch↔zoom-do-browser é issue aberto.
- **Reagraph mobile — UNVERIFIABLE/REFUTED-por-ausência.** Nem site nem README citam mobile/touch/responsivo.
- **Mermaid mobile — REFUTED.** "rendered as static SVGs — no click handlers, tooltips, or zoom";
  "200-node diagram may lag on mobile" (issues #1134/#2162).

## kg_fit (mobile)

Regra: **degradar por design, não portar o node-link.** Três camadas: (1) grafo pequeno filtrado
(≤~15-20 nós, um plane, um foco) em **Cytoscape.js** (único touch CONFIRMED) com semantic zoom; (2) denso
ou leitura de rótulo → **abandonar node-link** por lista/tabela (preserva tipos/peso/plane como campos,
perde só topologia); (3) **evitar Mermaid** como visualizador principal (SVG estático, perde peso/plane).
**Achado transversal:** nenhuma lib "resolve" tela pequena — as que investiram resolveram *gesto e escala
GPU*; a legibilidade em celular é trabalho de *produto* (filtro agressivo + LOD + fallback textual).
