---
title: "Nota 06 — Metodologias de infoviz: os fundamentos clássicos decidem a representação por fatia"
category: discussion
status: fonte-de-discussao-isolada
date: 2026-07-19
branch: discuss/kg-visualization-dashboards
amarra: SEED dimensão 6 · nós C_MOBILE_CEILING, C_DOI_FILTER, C_MULTIVARIATE, C_EDGE_BUNDLING
---

# 📐 Nota 06 — Metodologias de UX/infoviz de grafo (o "como", não a ferramenta)

> Isolada. Pensa, não entrega. Ver NOTE-00 para a síntese e a recomendação gated.

## Estado 2026

Consolidado nos fundamentos clássicos — **sem mudança de paradigma emergente**. Node-link+força para
exploração geral, matriz para densidade, foco+contexto (fisheye/DOI) + zoom semântico como as técnicas de
escala mais maduras. O survey guarda-chuva ativo é **Nobre/Meyer/Streit/Lex 2019** sobre **redes
multivariadas** — a referência mais próxima do `.kg.yaml` (nós E arestas tipados/com atributos). O
genuinamente emergente é o **encaixe grafo-em-chat**: **não há literatura de infoviz dedicada a "grafo em
LLM chat"** — só *practice* emergente (Mermaid/ASCII em terminal, KG-chatbots dual-mode como AGENTiGraph),
mostrando que o padrão de facto p/ tela pequena/chat é **texto estruturado + drill-down textual**, não
canvas interativo. Tensão real: a literatura clássica (fisheye, DOI, edge bundling) **pressupõe interação
contínua num canvas grande** — inaplicável dentro de um turno de chat.

## Princípios acionáveis (quando usar cada representação)

| Método | o que decide | mobile/chat_fit |
|---|---|---|
| **Shneiderman — "overview first, zoom+filter, details-on-demand"** (1996) | sequenciamento de QUALQUER resposta | **bom** — mapeia 1:1 p/ chat (radar→comando→pergunta) |
| **DOI — van Ham & Perer** (2009) | que nós entram/saem da vista (filtro, não distorção) | **bom** — o mais portável p/ tela pequena |
| **Ghoniem/Fekete/Castagliola** (2005) | node-link (≤~20, esparso, path) × matriz (>20, denso) | médio (matriz = tabela markdown) |
| Fisheye — Sarkar & Brown (1994) | foco+contexto por distorção geométrica | **ruim** — precisa canvas manipulável |
| NodeTrix — Henry/Fekete/McGuffin (2007) | híbrido node-link + matriz p/ "esparso global, denso local" | ruim — 2 problemas de escala juntos |
| **Edge bundling — Holten** (2006) | curvar arestas ao longo de hierarquia p/ reduzir clutter | médio — melhora o SVG desktop |
| **Nobre/Lex 2019** (survey redes multivariadas) | grade de 4 eixos p/ avaliar qualquer view | médio — é mapa de decisão |

## Claims verificados (adversarial → fonte primária)

- **Ghoniem/Fekete/Castagliola — CONFIRMED.** "when graphs are bigger than twenty vertices, the
  matrix-based visualization outperforms node-link diagrams on most tasks. Only path finding is
  consistently in favor of node-link" (IV 2005). O "~20" e a exceção path-finding batem exatos.
- **NodeTrix — CONFIRMED.** node-link (global) + matriz de adjacência (comunidades densas), TVCG 2007.
  (Nuance: "globally sparse but locally dense" é o enquadramento canônico, não citação literal.)
- **Shneiderman mantra — CONFIRMED.** Introduzido como **princípio de design** ("A useful starting
  point…"), **sem estudo empírico formal** — framework prescritivo, IEEE VL 1996.
- **DOI van Ham & Perer — PARTIAL.** "Furnas' original degree of interest function… adapted from trees to
  graphs" confirmado; **o range `[0,1]` NÃO está na fonte** (a DoI é combinação linear não-normalizada) —
  ressalva `declarado≠verificado`.
- **Holten edge bundling — CONFIRMED.** B-splines curvadas ao longo do caminho da hierarquia, reduz
  clutter em grafos compostos, TVCG 2006 (método novo/seminal).
- **Nobre/Lex 2019 — CONFIRMED.** Classifica em **4 eixos** (layouts · view operations · layout operations
  · data operations) p/ redes onde estrutura E atributos importam simultaneamente.

## kg_fit (metodologias)

Separação limpa por fator de forma, não técnica única:
- **Desktop-full:** evoluir o `kg-console.sh` (SVG circular) para **edge bundling hierárquico** (Holten)
  usando `layer`/`plane` como hierarquia de base (`C_EDGE_BUNDLING`) — a melhoria mais barata e cirúrgica,
  sem trocar de paradigma. Se crescer denso: NodeTrix ou matriz por fatia (Ghoniem: >20 nós densos favorece
  matriz). Filtro de escala **DOI-based** (peso `impact×confidence×status` × 1/distância no grafo tipado —
  computável do schema atual, sem inventar modelo).
- **Mobile/chat:** **não tem correspondente direto na literatura clássica** (que pressupõe canvas grande).
  A rota realista é **abandonar canvas interativo** por texto estruturado sequenciado pelo mantra de
  Shneiderman (overview textual do radar → filtro por comando → details por pergunta). Ou seja: o
  `kg-radar.sh` (texto determinístico) **já está no caminho certo**; o próximo passo não é "portar o SVG
  para celular" mas "ensinar o radar a também emitir um Mermaid pequeno filtrável por DOI" — mantendo as
  duas superfícies (desktop SVG rico / chat texto+Mermaid leve) **deliberadamente divergentes**.
- O `.kg.yaml` **É por definição uma rede multivariada** (`C_MULTIVARIATE`) — usar a grade de 4 eixos do
  survey Nobre/Lex como checklist de avaliação de qualquer view candidata.
