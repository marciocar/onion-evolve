---
title: "Revisão — REGRA 75 (link relativo morto em plugin, cura generalizada) + REGRA 76 (marketplace.json raiz == gerador, --write seguro)"
date: 2026-09-04
branch: feat/plugin-lint-dead-links-marketplace-root
reviewer: "condutor com dogfood EXECUTADO: helpers --selftest 2/2 e 3/3; famílias plugin_dead_link 3/3 e marketplace_root_sync 2/2 (com mutantes e modo consumido); 8 plugins regenerados (123→0 links mortos); marketplace.json raiz regenerado; lint 0 HARD"
reviewed_diff_sha256: 8410c3ff780f8aec1639ae11ad20d743b9fe51e1bbd1a3b5609de781af8ba778
findings_total: 3
findings_real: 3
verdict: APROVADO
tokens: 90000
duration_min: 35
---

# Resíduo — REGRA 56

## Achados

1. **"Vivo" precisa ser "dentro do plugin"** — a 1ª versão aceitava alvo que existisse no disco; `../../../docs/x.md` existia no core e o veredito dependia de onde o plugin era montado. A REGRA 19 acusou drift entre a montagem em `/tmp` e a de `plugins/`; a bancada (a) reprovou junto. Corrigido: resolve dentro da raiz do plugin.
2. **`gerador > arquivo` destrói o top-level** — o gerador lê o arquivo existente para preservar name/owner; o redirecionamento trunca antes. `--write` (temp + mv) é o único caminho seguro; caso (c) do selftest documenta a armadilha.
3. **Fixture de uma linha não é JSON para o gerador** — ele lê linha a linha (sem jq); fixtures pretty-printed, como o assembler escreve.

## Fora de escopo declarado
- READMEs que prometem comandos não entregues (onion-testing) viram texto, não somem — é assunto de manifesto (F2).
