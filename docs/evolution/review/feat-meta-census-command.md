---
title: "Revisão — /meta:census nasce (KG-SSOT first/runtime + teto que PARA)"
date: 2026-09-01
branch: feat/meta-census-command
reviewer: "dogfood ponta-a-ponta do modo-de-falha ANTES do PR (wf_15ebe561: teto 150k → 2/8 medidos por atenção, 6 nomeados; juiz reprovou os 2 e a selagem recusou carimbo — AUDIT íntegro); bancada census-extract 3/3 no harness do runner; extrator provou a retomada KG-runtime no vivo (22 a-medir = exatamente os reprovados da revisão-total); vendor-scrub pegou nomes hardcoded na 1ª versão do seal — derivação em runtime do members.yaml; contagens 108→109 varridas"
reviewed_diff_sha256: 8f8e73b002daca8ce9d791e7262d556b5f40f8edc669d7201e91ee1bff66ed6a
findings_total: 2
findings_real: 2
verdict: APROVADO
tokens: 263197
duration_min: 30
---

# Resíduo — REGRA 56

/meta:census (comando 109): extrator determinístico fail-loud + molde versionado com teto
enforçado por contagem (preço/nó declarado e recalibrável) + selagem AUDIT com radar-aborta +
listagem-projeção. Nasceu porque a forma rodou 2× a 5M+ renascendo em /tmp. Custo/nó observado
no dogfood: ~88k vs price 74k — anotado no comando para recalibração na 1ª rodada real.
