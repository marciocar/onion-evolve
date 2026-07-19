---
title: "Nota 03 — Chat-native: o grafo dentro da conversa é texto-primeiro, não desenho"
category: discussion
status: fonte-de-discussao-isolada
date: 2026-07-19
branch: discuss/kg-visualization-dashboards
amarra: SEED dimensões 3A+3B (a ênfase do maestro) · nós C_DEGRADE_TEXT, C_TRIPLES_NATIVE, C_MERMAID_FRAGILE, C_GRAPHRAG_SUMMARY, D_CHAT_TEXT_FIRST
---

# 💬 Nota 03 — Chat-native: representar/resumir/navegar o KG dentro de uma conversa

> Isolada. Pensa, não entrega. **Esta é a restrição mais dura e o diferencial do estudo** (ênfase do
> maestro: chats e celular são o fator de forma PRINCIPAL). Ver NOTE-00 para a recomendação gated.

## Estado 2026 — dois blocos

O "grafo dentro do chat" se resolve por **composição de padrões, não por uma ferramenta única**, e se
parte em dois:

1. **Diagramação declarativa (Mermaid).** Render **nativo só onde a plataforma investiu**: GitHub, Claude
   (Artifacts), VS Code, Notion. **ChatGPT e Slack continuam SEM render nativo em 2026** — exigem
   pré-render p/ imagem/SVG ou app de terceiro. Mermaid tem **teto real** (~200 arestas / erros
   `Too many edges` / `Maximum text size`) → o `.kg.yaml` inteiro **não cabe**; só fatias.
2. **GraphRAG e retrievers de grafo** (Microsoft GraphRAG, LlamaIndex PropertyGraphIndex, LangChain
   GraphRetriever). Resolvem "grafo em chat" por **outro caminho: nunca desenham** — **verbalizam**
   (linearizam triplas ou resumem comunidades por LLM) e devolvem prosa/texto estruturado. Onda emergente
   2026 de derivados baratos (LazyGraphRAG, LightRAG, Fast GraphRAG) corta custo de indexação mantendo a
   filosofia texto-primeiro.

**O ponto de ouro:** o `--triples` do `kg-radar` **já está alinhado com a prática validada** — triplas
lineares soltas superam prosa para LLM em Q&A fact-intensive. O output atual já é o formato "nativo"
ideal; falta só a camada de apresentação ao humano.

## Padrões de representação (progressive disclosure)

| Padrão | chat_fit | preserva tipagem? |
|---|---|---|
| **Boletim / briefing textual determinístico** (do YAML) | **ótimo** — o `kg-radar.sh` já faz | **total** (é o próprio schema) |
| **Node-focus** (1 nó + vizinhança 1-2 hops) | **bom** — cabe em qualquer tela, sem artifact | total no foco+vizinhos (projeção, não resumo) |
| **`--triples` → LLM verbaliza** | **ótimo** — formato nativo de contexto de LLM | total se a tripla inclui o tipo de aresta |
| **GraphRAG (resumo por comunidade)** | bom p/ Q&A | **dilui** tipagem fina ao comprimir p/ texto |
| **Mermaid em Artifact** (fatia pequena sob pedido) | bom só ≤~20 nós | **baixa** — perde peso numérico e toggle de plane |
| Adaptive Cards (Microsoft) | médio — 1 entidade+ações, **sem aresta** | campos de 1 nó sim; relações não |
| ASCII/box-drawing | médio — fallback universal | convenção manual, sem schema |

## Claims verificados (adversarial → fonte primária)

- **Claude Artifacts render Mermaid — PARTIAL.** O Help Center lista "Diagrams and flowcharts" genérico,
  **não** cita "mermaid" nem "sem CDN" por nome — a *atribuição* "confirmado pelo Help Center" é falsa
  como escrita, embora o fato técnico (render nativo) seja real por fontes adjacentes.
- **Mermaid flowchart — CONFIRMED.** ~14 formas básicas + 30 estendidas (v11.3.0+, `A@{shape:…}`); classes
  (`classDef`); IDs de aresta com metadados (v11.10.0+); **sem campo nativo para peso numérico nem `plane`**.
- **ChatGPT Canvas — CONFIRMED.** Editor doc/código lado a lado (out/2024) + "interactive visualizations"
  (mar/2026, >70 tópicos de matemática/ciência) — **nenhum é renderer de KG genérico tipado**.
- **GraphRAG — CONFIRMED.** "derive an entity knowledge graph… pregenerate community summaries"; Global/
  Local Search devolvem **texto**, não grafo. Não menciona tipagem/plane/peso → resumir comunidades ≠
  preservar schema SDAAL sem adaptar o prompt.
- **GitHub Markdown Mermaid — CONFIRMED.** Nativo em Issues/Discussions/PRs/Wikis/Markdown, sem plugin
  ("You may observe errors if you run a third-party Mermaid plugin").
- **Slack — CONFIRMED (não-nativo).** mrkdwn ≠ markdown; sem Mermaid; app 3rd-party pré-renderiza PNG via
  Mermaid CLI e sobe como imagem.
- **ChatGPT Mermaid — CONFIRMED (não-nativo em 2026).** Feature request aberta desde jan/2025 sem
  implementação; "Its 2026 and ChatGPT is still not able to render mermaid diagram?" (abr/2026).
- **Mermaid limites — PARTIAL.** `Too many edges` real, mas o `280` era constante antiga; `maxEdges`
  **default 500** (o claim conflacionou); `O(N²)`/"50-100 nós" **não-verificado** na fonte.
- **PropertyGraphIndex — PARTIAL.** Retrievers devolvem `TextNode`/paths; mas a lib **tem** viz nativa
  (`save_networkx_graph` HTML) do grafo *inteiro* p/ debug — só não do subgrafo em resposta de chat.
- **Adaptive Cards — CONFIRMED.** Schema JSON único render nativo por host; **nenhum elemento node-link/
  aresta** — grafo viraria lista de cards, perdendo a estrutura.

## kg_fit (chat-native) — `D_CHAT_TEXT_FIRST`

**Não apostar em Mermaid como superfície primária cross-plataforma** (só robusto onde renderiza nativo, e
com teto). A camada certa **replica GraphRAG/PropertyGraphIndex**: manter `--triples` (ou subconjunto
filtrado por pergunta) como **entrada** para o LLM verbalizar em prosa citável (migalhas `TRACES_TO` como
citação), e reservar Mermaid só para "me desenha isso" — subgrafo pequeno (BFS 1-2) via Artifact nativo ou
SVG pré-renderizado para canais sem suporte. Preserva tipagem na verbalização textual; perde na forma
Mermaid — trade-off aceitável (Mermaid não tem arestas tipadas ponderadas comparáveis a
SUPPORTS/REFUTES/TRACES_TO). **Ponto crítico:** nenhuma fonte confirma que Mermaid/Artifacts preservem
peso/status como dado **reconsultável** — só texto/cor por convenção. Logo o YAML permanece SSOT e o
Mermaid é **view descartável**, nunca o inverso.
