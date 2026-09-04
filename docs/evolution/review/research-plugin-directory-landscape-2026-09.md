---
title: "Revisão — R1 landscape: plugins/marketplaces de Claude Code em destaque (2026-09) + cura do Scope do onion-research"
date: 2026-09-04
branch: research/plugin-directory-landscape-2026-09
reviewer: "condutor com run EXECUTADO: wf_611d652e-74f (103 agentes, 25 claims verificadas 3-0/2-1, 11 refutadas, radar exit 0); SYNTHESIS como projeção; caveats do próprio run preservados"
reviewed_diff_sha256: 195f262f4c9659aa7fa53613973ffb61a80fe246a05657c3825cb560600b3d34
findings_total: 5
findings_real: 5
verdict: APROVADO
tokens: 230000
duration_min: 45
---

# Resíduo — REGRA 56

## Achados

1. **Scope morria por schema (5×)** — o coletor (sonnet) devolvia `<question>…<summary>…` dentro de um único campo. Cura no script (`onion-research.js`): o prompt do Scope nomeia os campos JSON de topo. Mecanismo, não retry.
2. **Corpus injetado casou termos genéricos** ("e", "de") e devolveu nós irrelevantes; o passo 0 foi refeito com termos precisos (`plugin`, `marketplace`, `mcp`, `namespace`, `i18n`) antes de gastar o workflow.
3. **Custo declarado com lacuna**: 161k medidos no run final + 66,7k da 1ª tentativa; a 2ª tentativa morreu com o processo e NÃO foi medida — dito no frontmatter em vez de somado por chute.
4. **i18n e trajetória GitHub não responderam** — declarados como caveats do run e como entrada de R2; o eixo por trajetória precisa de `gh api` + HN Algolia (a busca por nome só achou incumbente, e ele foi refutado).

5. **O gate pegou a projeção** — REGRA 16 leu "Agentes | 103" como contagem de inventário (reescrito como workers do run); REGRA 29 exigiu que um nó do grafo cite o `SYNTHESIS.md` (trace do nó de medição local); REGRA 62 exigiu o backlog regenerado (o nó `Q_` aberto entra na projeção).

## Fora de escopo
- R2 (idioma) e R3 (MCP) em modo decision; consolidação 8→5 (F2) sustentada pelo achado de granularidade.
