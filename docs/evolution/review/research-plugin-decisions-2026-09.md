---
title: "Revisão — R2 (política de idioma) + R3 (postura MCP) em modo decision: dois nós D_ abertos para o maestro selar"
date: 2026-09-04
branch: research/plugin-decisions-2026-09
reviewer: "condutor com runs EXECUTADOS: wf_bde10f3f-28c (105 workers, 7 confirmadas/18 refutadas) e wf_9ad3aba7-b48 (104 workers, 15/10); radar exit 0 nos dois grafos; SYNTHESIS como projeção com o veredito do ELENXO (não o resumo do run)"
reviewed_diff_sha256: b5bc41d2de74f600a51b45c0bf3532d25dd03e3ff39993b485d9eab7cf4b6be0
findings_total: 5
findings_real: 5
verdict: APROVADO
tokens: 13900000
duration_min: 80
---

# Resíduo — REGRA 56

## Achados

1. **O resumo do run e o Elenxo divergiram nos dois casos** — R2: resumo dizia "(i)"; Elenxo reprova (i)/(ii)/(iii) como formuladas (premissa "superfície gerada, corpo escrito" é falsa, medida) e propõe (i′). R3: resumo dizia "(b) com escopo estrito"; Elenxo mede o servidor real e reprova (a) e (b) como especificadas, ficando (c) como espera. A síntese projeta o **nó de decisão**, não o resumo.
2. **Custo alto e declarado**: 6,85M + 6,96M tokens (≈13,8M), 3–3,6× o custo/nó do censo — comprado com refutações que evitaram dois erros de desenho (README de camada mista; `.mcp.json` servindo o próprio plugin).
3. **Eixos cortados por orçamento** nos dois runs (venue não-anglófono; regime de plugin-embedded; tração por trajetória) — viraram constraints com gatilho barato (censo por `gh api`, duas páginas de primeira parte), não outra rodada.
4. **Nada selado**: os dois `D_` ficam `open`; a tabela de selagem do `/meta:drive` (KIND decision) é do maestro.

5. **Recorrência (2×) do gate sobre a projeção** — REGRA 29 exige que o grafo cite o `SYNTHESIS.md` e REGRA 62 exige o backlog regenerado DEPOIS do grafo tocado. Já aconteceu no R1. Gatilho nomeado: 3ª ocorrência ⇒ o passo 5 da skill `onion-research` vira mecanismo (o `write(KG)` grava o `trace` da projeção e o pós-run regenera o backlog).

## Fora de escopo
- F3 (i18n) espera o selo de R2 e ganha passo 0 (emenda L0 + censo + dogfood EN/pt-BR). F4 (MCP) fica em (c) com gatilho nomeado.
