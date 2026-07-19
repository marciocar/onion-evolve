---
title: "Fonte de discussão — Visualização, dashboards e gestão de Knowledge Graphs (.kg.yaml): desktop-full + mobile/chat, landscape 2026"
category: discussion
status: fonte-de-discussao-isolada
date: 2026-07-19
branch: discuss/kg-visualization-dashboards
# ── bloco Tier-0 (o mapa da constelação lê SÓ isto — metadados, nunca o corpo) ──
phase: CONVERGE       # SEED | EXPLORE | DEEP | CONVERGE | PROMOTE | PARK
index: NOTE-00-sintese.md   # ← entrada da frente: tese + matriz comparativa + recomendação gated
next_action: "PESQUISA COMPLETA + write(KG) FECHADO. Fan-out orquestrado (7 dimensões, 44 agentes, 37 verdicts adversariais contra fonte primária) sintetizado em NOTE-00..06 + kg-visualization-dashboards.kg.yaml (radar exit 0, 32 nós/37 arestas). TESE: a camada de consumo do .kg.yaml DIVERGE por fator de forma — desktop-full quer motor node-link tipado (Cytoscape.js); mobile/chat quer o OPOSTO (degradar node-link→texto: boletim determinístico + node-focus por DOI). ACHADO DURO: nenhuma ferramenta de prateleira 2026 tem mobile/chat-native p/ KG — kg-radar (texto) + kg-console (SVG) já ocupam nicho vago; o --triples já é o formato nativo ideal p/ LLM. 4 decisões GATED (D_DESKTOP_CYTOSCAPE, D_CHAT_TEXT_FIRST, D_TRANSFORM_NETWORKX, D_EVOLVE_NOT_ADOPT). Prior da irmã interface-state-of-art (teto ~50 nós) CONFIRMADO e apertado (mobile ~15). Próximo passo é do maestro: promover algo a feat/* (ex.: edge-bundling no kg-console, ou boletim-textual/node-focus como projeção chat do radar), aprofundar uma nota, ou parkear. Nada foi pro core — design-only isolado."
scope_globs: ["docs/discussions/kg-visualization-dashboards/", "docs/knowledge-base/"]
objective_tags: ["kg-viz", "dashboards", "mobile-first", "chat-native", "NS1"]
---

## A conexão estratégica (o gap real)

O `.kg.yaml` (Knowledge Graph SDAAL) é a **SSOT viva** do core — identidade, evolução, domínio, o overlay
da constelação. Mas hoje ele só tem **superfícies de texto**: o `kg-radar.sh` (radar determinístico), o
`kg-console`, o Mapa da Constelação. À medida que o grafo cresce (nós tipados, arestas ponderadas,
`REFUTES`/`SUPERSEDES`, planes `DEV/PROD`, camadas `audit|domain`, migalhas `TRACES_TO`, overlays
cross-graph), **falta uma camada de VISUALIZAÇÃO e GESTÃO rica** — e, principalmente, **uma forma de
consumir/gerir o KG pelo celular e dentro de chats**, que é onde o maestro cada vez mais opera (Onion-Bridge,
app pessoal, sessões móveis).

Este estudo **pesquisa o estado da arte 2026** (o que é popular consolidado **e** o que está emergindo) de
como transformar um KG tipado como o `.kg.yaml` — e suas variações, ligações e relações — em:
- **visualização** (node-link, matriz, hierárquica, temporal, camadas, foco+contexto);
- **gestão** (navegar, filtrar, editar, reconciliar, versionar);
- **dashboards** (métricas do grafo: atenção, frescor, integridade, colisão/convergência);
- **transformação** (pipelines `.kg.yaml` → formatos de viz: GraphML, JSON-LD, RDF, Mermaid, etc.).

Em **dois fatores de forma de primeira classe**:
1. **🖥️ Desktop-full** — a visão completa numa tela de notebook (densidade alta, exploração profunda).
2. **📱 Mobile / 💬 chat-native** — responsivo moderno para celular, **com ênfase em chats** (a restrição
   mais dura e o diferencial: como representar/resumir/navegar um grafo dentro de uma conversa e numa tela
   pequena — progressive disclosure, resumo por LLM, o padrão "boletim", node-focus, gestos).

## Fronteiras (o que este estudo NÃO é)

- **Pesquisa, não entrega** (estrela `discuss/*` isolada — pensa, não constrói). O deliverable é uma
  **síntese comparativa + recomendação gated**, não código.
- **A gramática soberana do `.kg.yaml` + o `kg-radar.sh` NÃO mudam** — este estudo é sobre camadas de
  **consumo/visualização/gestão POR CIMA** da SSOT, não sobre alterar a SSOT.
- **Verificação adversarial obrigatória** para claims de "ferramenta X faz Y" (fonte primária, não hype de
  landing page) — `declarado ≠ verificado`.

## Relações (a constelação)

- **Irmã de `interface-state-of-art`** (ambas sobre consumo/observação do loop) — checar colisão de escopo.
- **Alimenta `onion-pessoal-app`** (a superfície chat+mobile onde o KG mais precisa ser consumível).
- **Ancora em** [knowledge-graph-sdaal.md](../../knowledge-base/concepts/knowledge-graph-sdaal.md) +
  `kg-radar.sh` + `kg-console.sh` (o que já existe em texto — o ponto de partida a superar).
