---
title: "Nota 05 — Pipelines de transformação: NetworkX como hub, GraphML/Cytoscape JSON sem perda"
category: discussion
status: fonte-de-discussao-isolada
date: 2026-07-19
branch: discuss/kg-visualization-dashboards
amarra: SEED dimensão 5 · nós C_NETWORKX_HUB, D_TRANSFORM_NETWORKX
---

# 🔁 Nota 05 — `.kg.yaml` → formatos de viz/intercâmbio (estado 2026)

> Isolada. Pensa, não entrega. Ver NOTE-00 para a síntese e a recomendação gated.

## Estado 2026 — dois grupos de formato

- **Typed-schema** (impõem/validam tipo): **GraphML** (`<key>`/`<data>` tipados), **GEXF** (attributes +
  weight nativo), **RDF 1.2/RDF-star** (triple terms p/ propriedades de aresta — a novidade real de 2026,
  aproxima RDF de property graph, ainda pouco explorada em tooling).
- **Passthrough livre** (aceitam qualquer atributo, não validam): **NetworkX** `node_link_data` JSON,
  **Cytoscape.js JSON**, **Graphology JSON** — a fidelidade depende da disciplina do gerador, não do
  formato.

**Mermaid e DOT/Graphviz são linguagens de DIAGRAMAÇÃO/layout, não de intercâmbio** — são destino final
(viz), não formato intermediário fiel: atributos tipados (`plane`/`impact`/`status`/`on:`) têm que ser
achatados em rótulo/estilo, perdendo estrutura. **Neo4j** (Cypher/LOAD CSV) é o mais property-graph nativo,
mas exige 2 passadas e LOAD CSV entrega tudo como **string** (coerção explícita `toInteger` etc.).

## Fidelidade por formato

| Formato | preserva o modelo tipado? | papel |
|---|---|---|
| **GraphML** | **sim** (attr.type int/double/string; peso e direção nativos) | intercâmbio offline denso (yEd/Gephi) |
| GEXF | sim (attributes + weight) | intercâmbio, viz temporal (Gephi) |
| **Cytoscape.js JSON** | sim (passthrough) | app web interativo (filtro por plane/status/impact) |
| NetworkX node_link JSON | sim (passthrough dict) | **hub intermediário** |
| Graphology JSON | sim (attrs livres) | backend Sigma/Reagraph |
| RDF 1.2 / RDF-star | **sim** (triple terms) | semântica formal W3C — investigação futura |
| Mermaid / DOT | **não** (achata p/ rótulo/estilo) | destino de viz, não intercâmbio |
| Neo4j (Cypher/CSV) | parcial (tudo string, coerção) | app pesado, fora do mobile/chat |

## Claims verificados (adversarial → fonte primária)

- **GraphML — CONFIRMED** (via spec graphdrawing.org): `<key>`/`<data>` tipados (boolean/int/long/float/
  double/string — **sem enum nativo**, mapear `layer`/`plane` como string); peso e direção nativos; `on:`
  vira atributo extra de aresta (suportado, XML denso).
- **RDF 1.2 / RDF-star** — triple terms formalizados como caminho para propriedades de aresta (o que RDF
  puro não fazia bem); tooling 2026 ainda imaturo p/ triple terms → não é aposta segura imediata.
- **NetworkX / Graphology** — passthrough de atributos Python/JS dict → preservam tudo sem perda desde que
  o consumidor final saiba interpretar os campos; conversores mais baratos e diretos.

## kg_fit (transformação) — `D_TRANSFORM_NETWORKX`

**Rota mais fiel e barata (desktop-full):** `.kg.yaml` → PyYAML → **NetworkX DiGraph** (atributos tipados
nativos) → exportar **simultâneo** GraphML (offline denso) + Cytoscape.js JSON (web interativo). Nenhum
dos dois é lossy p/ os campos do Onion desde que `attr.type` do GraphML seja mapeado explicitamente. RDF
1.2/rdflib é investigação futura (mais fiel à camada audit `SUPPORTS`/`REFUTES`/`TRACES_TO`, tooling
imaturo). **Mobile/chat:** nenhum formato de intercâmbio puro é diretamente consumível — todos exigem
camada de renderização; o caminho já validado no ecossistema Onion (Artifacts self-contained, CSP estrito)
é `.kg.yaml` → JSON node-link → HTML artifact único com lib embarcada inline. DOT/Neo4j ficam fora do
fator mobile/chat mas alimentam o desktop-full como saídas adicionais do mesmo hub NetworkX.
