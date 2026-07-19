---
title: "Nota 04 — Dashboards/gestão: nenhuma ferramenta modela o grafo tipado + métricas + mobile"
category: discussion
status: fonte-de-discussao-isolada
date: 2026-07-19
branch: discuss/kg-visualization-dashboards
amarra: SEED dimensão 4 · nós C_NO_TOOL_MOBILE, D_EVOLVE_NOT_ADOPT
---

# 📊 Nota 04 — Frameworks de dashboard/gestão (estado 2026)

> Isolada. Pensa, não entrega. Ver NOTE-00 para a síntese e a recomendação gated.

## Estado 2026

**Nenhuma ferramenta única** modela nativamente nós/arestas **tipados com peso**
(`impact×confidence×status`) + reconciliação `REFUTES`/`SUPERSEDES` — todas exigem adaptação. Dois eixos,
cada um resolve metade:

- **BI genérico** (Grafana, Metabase, Superset, Evidence.dev, Observable Framework, Streamlit, Retool):
  popular p/ **métricas agregadas** (atenção/frescor/integridade como séries/tabelas/KPIs), mas grafo como
  visual primário é fraco/plugin de 2ª classe. Grafana **Node Graph** é o único node-link nativo — capado
  em ~200 nós, pensado p/ topologia de infra/tracing, não semântica de KG.
- **Grafo dedicado** (Neo4j Bloom/NeoDash, Memgraph Lab, Linkurious, GraphXR, Kùzu Explorer, TerminusDB,
  Oxigraph): exploração visual rica, mas dashboard de **métricas agregadas** ausente/tosco, e a maioria
  pressupõe o **motor de grafo do vendor** — o `.kg.yaml` teria que ser importado/espelhado (ETL), não é
  a fonte viva.

Tensão: as de grafo empresarial popular (Bloom, Linkurious, GraphXR) são **fechadas/pesadas/desktop**; as
leves self-host (Kùzu, Oxigraph+YASGUI, streamlit-agraph) são genéricas, **sem noção de camada
audit/domain nem de peso**. **Nenhuma tem mobile/chat-native** — todas são web apps desktop-first.

## Itens-chave

| Ferramenta | serve p/ | licença/self-host | limite |
|---|---|---|---|
| Grafana + Node Graph | métricas + grafo pequeno | AGPLv3 / sim | cap ~200 nós; arc simula, não é tipo de aresta |
| Neo4j Bloom + NeoDash | exploração + dashboard | Bloom proprietário; NeoDash **descontinuado** (grátis) / parcial | exige import p/ Neo4j real |
| Observable Framework | dashboard custom (D3) | ISC / sim | **build-it-yourself**, sem widget de grafo pronto |
| Evidence.dev | BI-as-code (Markdown+SQL) | MIT / sim | **sem grafo nativo**; achata p/ tabelas SQL |
| Streamlit + agraph | app Python + grafo | Apache/MIT / sim | reconciliação/frescor à mão |
| Superset / Metabase | métricas SQL | Apache/AGPL / sim | **zero grafo** sem plugin custom |
| Kùzu Explorer | exploração de grafo | OSS / sim | repo **arquivado out/2025**; exige backend Kùzu |
| TerminusDB | grafo versionado (git-for-data) | Apache / parcial | viz em transição/risco |
| Oxigraph + YASGUI | SPARQL | Apache/MIT / sim | só formulário de query, sem viz |

## Claims verificados (adversarial → fonte primária)

- **Grafana Node Graph — CONFIRMED.** "up to 200 visible nodes by default… shows a warning… hides some
  nodes for performance". (Nuance: nós ocultos são expansíveis; há Force layout p/ >500.)
- **NeoDash — CONFIRMED.** README: "This project is no longer maintained, use at your own risk"; versão
  comercial licenciada existe (self-host Docker + Neo4j Enterprise).
- **Grafana core — CONFIRMED.** Relicenciado Apache 2.0 → **AGPLv3** em 2021 (Grafana/Loki/Tempo);
  open-core (Enterprise proprietário). Plugins/agents seguem Apache.
- **TerminusDB Dashboard — REFUTED.** O repo **não** carrega banner de deprecation/"use at your own risk"
  nem menção a migração de viz que o claim afirmava; não-arquivado, última release 2023-12, commits até
  abr/2024. (Nuance: atividade estagnada de fato, mas a fonte não carimba o status alegado.)
- **Evidence.dev — CONFIRMED.** Site estático de Markdown+SQL, self-hostável (AWS/Azure/GCP/IIS/Pages),
  sem runtime proprietário.
- **Kùzu Explorer — CONFIRMED.** UI web Docker oficial; node-link/tabela/JSON; read-only configurável.
  (Nuance: repo **arquivado 10-out-2025**; acoplado ao backend Kùzu — não consome `.kg.yaml` direto.)

## kg_fit (dashboards) — `D_EVOLVE_NOT_ADOPT`

Nenhuma substitui o par `kg-radar.sh` + `kg-console.sh` — todas exigem ETL do YAML p/ modelo alheio e
**nenhuma tem mobile/chat**. Para desktop-full: se o objetivo é **métricas**, Observable Framework ou
Evidence.dev (git-first, spec-as-code) são o melhor encaixe filosófico; se é **exploração visual**,
Streamlit+agraph dá melhor custo/fidelidade sem prender a banco vendor. Para **mobile/chat — a restrição
dura — nenhuma resolve**; por eliminação, o `kg-console.sh` (SVG self-contained embutível inline) já
atende esse fator de forma, e a lacuna real é **evoluir essa rota**, não adotar dashboard externo.
