---
title: "Revisão — consolidação 8→5 plugins (onion←work-tools · engineering←testing · product←docs) + catraca da REGRA 74 por contagem"
date: 2026-09-04
branch: feat/plugins-consolidate-8-to-5
reviewer: "condutor com dogfood EXECUTADO: 5 plugins regenerados; marketplace.json raiz regenerado (--write); 4 helpers de plugin 0 HARD (namespace, hooks, dead-link; bare-path 119 no baseline); graph.md e registro regenerados; lint 0 HARD"
reviewed_diff_sha256: c0c8ed5aba28426c77ef4f54ea94e0f4eb77bf546d96300e592a90c74f64baaa
findings_total: 4
findings_real: 4
verdict: APROVADO
tokens: 70000
duration_min: 30
---

# Resíduo — REGRA 56 (PR aberto carrega RESÍDUO da passada adversarial)

## Achados

1. **Catraca por conjunto quebra em rename** — REGRA 74 (Caminho .claude/ NU dentro de plugin só resolve no core, com catraca) acusou 37 "NOVO" que eram os mesmos 119 caminhos sob `plugins/onion/` em vez de `plugins/onion-work-tools/`. Catraca agora por contagem (só o número encolhe); passivo real caiu 125 → 119.
2. **Ordem do `COMMANDS[]` decide colisão de `README.md`** — o absorvido entra primeiro, o dono depois (o assembler deixa o último vencer). Só `README.md` colide nas três fusões (medido com `comm`).
3. **`docs/onion/graph.md` é projeção e envelheceu** — regenerada com `graph.sh --markdown`; a guarda pegou.
4. **Dívida herdada e declarada** — os subcomandos aninhados de `validate/` (collab/, qa-points/, test-strategy/) continuam fora do plugin (o assembler achata); anotado no cabeçalho do manifesto `onion-engineering`.

## Fora de escopo
- REGRA 77 (contrato de dependência entre plugins) — próximo PR do F2.
- Materializar `~/onion-plugins` e o push do maestro só depois do F2 inteiro.
