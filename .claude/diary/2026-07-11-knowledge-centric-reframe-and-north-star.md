---
date: 2026-07-11
instance: onion-evolve
type: decision
classification: public
tags: [north-star, spec-as-run, knowledge-centric, kg, strategy, research-journey, company-brain]
affects: [strategy, identity, kg, north-star]
breadcrumb_for: [meta:kg, meta:evolve, meta:co-evolve]
share_with: [collective]
next_recommended: "onion-decision-north-star-2026-07 (docs/analysis/)"
review_after: 2026-10-09
conflict_class: static
---

## Signal
Uma jornada de pesquisa de 2 rodadas reenquadrou a estratégia do Onion e estruturou a north-star. O maestro
puxou o fio: o campo de spec-driven-development é **code-centric**; o Onion evoluiu para **knowledge-centric**
(mapear e reconciliar conhecimento das 3 verticais peer, código é subproduto). A 2ª pesquisa confirmou: o
Onion é **raro por combinação, não por propriedade** — e o dogfood de hoje (KG sobre identidade/estratégia,
não código) é a 1ª prova viva disso.

## Evidence (a jornada, registrada)
- **Pesquisa 1 — spec-as-code → spec-as-run → spec-as-all** (`docs/evolution/research/spec-as-code-evolution-2026/`):
  taxonomia Böckeler (spec-first/anchored/as-source); quase todos DIZEM nível-3 e OPERAM nível-1; o vetor sério
  contra drift é **reconciliação via grafo** (Spec Growth Engine: Intent×Evidence graph, gate bloqueante) — a
  maquinaria gêmea do KG SDAAL + kg-radar do Onion, mas sobre CÓDIGO.
- **Achado do maestro:** o campo é code-centric; o Onion não. O SDAAL sempre foi "spec dirige a IA, não gera
  código". As 3 dimensões peer (negócio/técnica/compliance) — o campo só tem uma.
- **Pesquisa 2 — knowledge-centric** (`docs/evolution/research/knowledge-centric-ssot-2026/`): o eixo está
  QUENTE ("Company Brain" = aposta YC RFS Summer 2026) mas fragmentado em 4 vizinhanças que não se falam
  (Enterprise KG/Palantir · DTO/Gartner · TMS-revival/TOKI sobre memória-de-agente · Company Brain nascente).
  **Ninguém trata negócio+eng+compliance como 3 verticais IGUAIS.** RAG/GraphRAG desmascarado como recuperação,
  não reconciliação (VersionRAG 64%/10%). Veredito: **companhia por propriedade, não por combinação**.
- **Estrutura da north-star** (`docs/analysis/onion-decision-north-star-2026-07.md`): grafo enriquecido (59
  nós/66 arestas) → **C_NS1_KG salta pra 29.2** (o mais central), contrapeso **C_DEMAND_AXIS_NOT_ONION 17.0**
  (demanda é do eixo, não do Onion; zero adotante frio). Decisão reduzida a UMA tensão + o desempate
  `Q_COLD_ADOPTER`.

## Next crumb
O desempate de maior alavancagem: **desenhar o experimento Q_COLD_ADOPTER** — o menor teste de "pull externo"
(1 adotante frio arms-length). Ele decide o peso NS1 (norte) × NS3 (hedge de caixa). Decisão de peso = do
maestro (nível Criar). Doutrina registrada: **toda jornada de pesquisa vira `docs/evolution/research/<tema>-2026/`
+ diário + claims no KG** — foi o que consolidou esta rodada.
