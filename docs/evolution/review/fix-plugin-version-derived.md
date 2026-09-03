---
title: "Revisão — versão de plugin derivada do conteúdo: o updater só lê a string, e a string não andava"
date: 2026-09-03
branch: fix/plugin-version-derived
reviewer: "condutor com dogfood EXECUTADO: família plugin_version_derived 4/4 em cópia e na bancada real; 8 plugins regenerados com versões 0.1.18…0.1.163; binário lido para a semântica do updater"
reviewed_diff_sha256: c860bd578e6f8c0d5a7de33deb90004bae1bb325f2262add5963232bfefb0adc
findings_total: 3
findings_real: 3
verdict: APROVADO
tokens: 90000
duration_min: 30
---

# Resíduo — REGRA 56 (PR aberto carrega RESÍDUO da passada adversarial)

Sinal de campo do maestro (2026-09-03, sessão no repo pessoal): `claude plugin update` = "already at the latest version (0.1.0)"
com o cache 89 arquivos atrás. Cura de mecanismo: `PLUGIN_VERSION = <major.minor>.<N>` derivada no assembler (N = commits que
tocaram as fontes canônicas, +1 com índice pendente); regenerada pela REGRA 19 (Drift de plugins gerados vs fonte) no pre-commit.

## Achados

1. **O assembler já sabia** (`tree_sha` do conteúdo em `provenance.json`) e publicava a mesma versão — declaração ≠ comportamento
   exatamente onde o consumidor decide. A versão derivada torna o `tree_sha` e a `version` consistentes por construção.
2. **Pre-commit e CI concordam**: com mudança pendente no índice a versão já conta o commit em curso (caso (b)); commit que não
   toca as fontes não anda a versão (caso (c)); `ONION_PLUGIN_VERSION_DERIVED=0` preserva o manifesto para alvo sem git (caso (d)).
3. **Primeiro salto é grande por construção** (0.1.0 → 0.1.163 no `onion`): N conta o histórico inteiro das fontes. Declarado; o
   `plugin update` só precisa de "maior que a instalada". A publicação externa (`onion-plugins`, human-gated) herda as versões.
