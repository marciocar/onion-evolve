---
date: 2026-09-03
instance: onion-evolve
type: learning
classification: public
tags: [pesquisa, lente, onion-research, dogfood, workflow, elenxo, revisita, bancada]
affects: [meta, engineering]
breadcrumb_for: []
share_with: []
next_recommended: "selar D_PODA_INSTRUCTION_BLOAT (C→A) e D_ADOPT_ENTREGA_CLAUDE_MD_FUNDIDO; abrir D_BANCADA_FAIXAS_E_MAPA com a evidência da pesquisa da bancada + as 5 reprovações de gate medidas; rodar /meta:radar E3 (2.1.259)"
review_after: 2026-12-02
conflict_class: static
significance: "Em 24 h a diretriz de pesquisa que o maestro redigia a cada rodada virou spec carregada + workflow salvo com três modos, e o próprio workflow achou 7 defeitos meus em dogfood — o mecanismo julgou o mecanismo."
kg: "docs/evolution/research/meta-research-lens-2026-09/meta-research-lens-2026-09.kg.yaml"
---

## Signal
A onda F1–F4 da lente de pesquisa fechou com os 4 `D_F*` `done` e o `/meta:realign` ALINHADO. O que valeu mais não
foi o que ficou de pé, foi o que o dogfood derrubou: 8 defeitos de desenho meus, todos curados no mesmo loop, e
duas premissas minhas refutadas pelo próprio Elenxo do workflow.

## Evidence
- F1: fragmento + rule por path + campos bi-temporais/tier + REGRAS 67/68 + `kg-corpus-grep` (81 grafos; o glob antigo via 27).
- F2: `/onion-research` derivado do `/deep-research` embutido; rodada 1 falhou alto (0 claims) por orçamento first-come.
- F3: modo decisão — o Elenxo refutou a premissa da MINHA pergunta ("skills sempre-carregadas": corpo entra sob
  demanda; problema ~5× menor) e reabriu 12 descartes por orçamento; contrato de decisão só valeu quando exigido
  pelo schema.
- F4: revisita — placeholder de citação gerou 4 refutações falsas (1,37 M invalidados); a cura (re-buscar) reduziu o
  corpus de julho: 5 claims seladas sobre blog tier 4 caíram.
- Gate: 6 reprovações em 24 h por classes já conhecidas (contagem, vendor-scrub, registro, `lint` local, TDZ, aspas
  simples dentro de `printf` consumidas pelo shell — 4ª ocorrência de *bancada espelha o runner*) → a
  faixa rápida `pre-gate.sh` nasceu no scratchpad, com embasamento (pesquisa da bancada + medições) e fora do repo
  até virar nó.

## Next crumb
Selos pendentes do maestro (poda do CLAUDE.md; CLAUDE.md fundido na adoção); bancada em faixas como nó com
evidência; radar E3 para 2.1.259; `review_after` dos grafos novos vence entre 10-02 e 12-31 — a REGRA 67 avisa.
