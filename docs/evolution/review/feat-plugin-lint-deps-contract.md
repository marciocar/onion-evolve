---
title: "Revisão — REGRA 77 (Contrato de dependência entre plugins): REQUIRES_PLUGINS → capability.json plugin:<x>, README 'Requer' e 'Funciona melhor com'"
date: 2026-09-04
branch: feat/plugin-lint-deps-contract
reviewer: "condutor com dogfood EXECUTADO: helper --selftest 5/5; família plugin_deps_contract 4/4 (mutantes: skill sem declaração, duplicata); 5 plugins regenerados; helper no repo = 0 HARD e 11 menções cruzadas informativas; lint 0 HARD"
reviewed_diff_sha256: 9ff0cb8a0c6d63bef3a9def87f94d7570b1a1b05a455abf80ae0431458795485
findings_total: 3
findings_real: 3
verdict: APROVADO
tokens: 60000
duration_min: 30
---

# Resíduo — REGRA 56 (PR aberto carrega RESÍDUO da passada adversarial)

## Achados
1. **Menção não é dependência** — a 1ª versão marcava HARD toda citação `/<outro>:<cmd>` (11 pares, inclusive o orquestrador `onion` citando os verticais): o grafo de dependências viraria ciclo total. Só skill/KB que só outro plugin embarca é dependência funcional (HARD); menção de comando é informativa (SOFT, 1 linha agregada) e o README a lista em "Funciona melhor com".
2. **Motor duplicado não é duplicata** — `kg-radar.sh` em `onion` e `onion-engineering` diverge por md5 porque a reescrita per-plugin (namespace) muda o conteúdo; e um plugin só alcança a própria raiz, então o motor viaja com o comando que o chama. Duplicata é só de CONHECIMENTO (skills/, kb/).
3. **Após a consolidação, 0 dependências funcionais** — nenhum manifesto precisa de `REQUIRES_PLUGINS` hoje; o contrato existe para impedir a classe de voltar (era exatamente o estado dos 8 plugins até ontem).

## Fora de escopo
- F3 (idioma, selo (i′)) começa pela emenda da L0; F5 (dogfood de instalação) depois.
