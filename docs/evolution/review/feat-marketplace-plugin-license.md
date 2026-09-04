---
title: "Revisão — LICENSE por plugin (requisito do diretório oficial de plugins do Claude Code)"
branch: feat/marketplace-plugin-license
date: 2026-09-04
reviewed_diff_sha256: 92a8f35a5217021f03b06295c6d3bc8a63d00f0c712f176f516d9c091329e7e6
reviewer: "condutor com dogfood EXECUTADO: 8 plugins regenerados, 8 LICENSE idênticos ao do core (cmp); família marketplace_readmes 5/5"
findings_total: 4
findings_real: 4
verdict: APROVADO
tokens: 40000
duration_min: 15
---

# Revisão: LICENSE por plugin

**Escopo:** o diretório oficial de plugins do Claude Code exige que cada plugin traga o próprio `LICENSE` (junto de `plugin.json` e `README.md`). O assembler passa a copiar o `LICENSE` do source para a raiz de cada plugin montado; sem LICENSE no source, escreve MIT com o autor (fallback sem ano — content-stable, para não driftar em janeiro sob a REGRA 19).

## Achados

1. **Content-stable por desenho.** O fallback não carrega data: a lição do #790 (README com ref/data derrubado pela REGRA 19 no CI) vale aqui igual.
2. **README do plugin aponta o arquivo** ("texto integral em `LICENSE`"); estrutura do marketplace lista o LICENSE.
3. **Bancada:** caso (e) — LICENSE do source aparece no plugin montado com o mesmo conteúdo.
4. **Sem mudança de manifesto:** `plugin.json.license` já existia; o arquivo é o que faltava.
