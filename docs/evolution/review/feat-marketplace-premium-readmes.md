---
title: "Revisão — READMEs gerados no padrão de referência de plugins do Claude Code; marketplace.json sem version duplicada"
date: 2026-09-04
branch: feat/marketplace-premium-readmes
reviewer: "condutor com dogfood EXECUTADO: 8 plugins regenerados e materializados num alvo de scratch (tabela + 8 READMEs lidos); família marketplace_readmes 3/3; padrão de referência lido na doc oficial e no diretório oficial"
reviewed_diff_sha256: 3fec8ef094a99fd8dab655eabc7d8dd100a990a63126d2e4ed54e41e2868f2a8
findings_total: 4
findings_real: 4
verdict: APROVADO
tokens: 180000
duration_min: 60
---

# Resíduo — REGRA 56 (PR aberto carrega RESÍDUO da passada adversarial)

Pedido: revisar `~/onion-plugins` e levar o README ao padrão de referência com documentação premium. Entregue como MECANISMO:
`plugin-readme.sh` (README por plugin, catálogo gerado) e `marketplace-readme.sh` (README do marketplace), chamados pelo assembler
e pelo materializador; `generate-marketplace.sh` com entradas ricas e sem `version`.

## Achados

1. **O README do alvo é gerado** — editar em `~/onion-plugins` seria sobrescrito na próxima materialização; o padrão entra no core.
2. **`version` duplicada na entrada do marketplace** contrariava a doc oficial ("plugin.json é a autoridade; versão estagnada na
   entrada esconde updates"): removida; entradas ganham `displayName`, `category` (core/vertical/tools), `tags`, `license`, `homepage`.
3. **Catálogo por plugin derivado do frontmatter**: comandos com namespace `/<plugin>:<comando>` + 1ª frase da description; agentes
   (description dobrada `>` juntada); skills; hooks (evento → script); capability (provides/requires); proveniência (repo/ref/tree_sha).
   O primeiro corte era por 140 caracteres — o teste exigiu 1ª frase e o gerador foi corrigido.
4. **A regeneração dos plugins no core traz os 8 READMEs para `plugins/`** (REGRA 19 os mantém em sincronia); a re-montagem sobrescreve
   edição manual (caso (c)). Limite declarado: o README do marketplace só nasce na materialização (o clone `~/onion-plugins` recebe na
   próxima `materialize` + push do maestro).

### Achado 5 — CI, REGRA 19 (Plugins de vertical sincronizados com as fontes) reprovou os 8 plugins

O README gerado embutia `ref` (sha do HEAD no momento da montagem) e `commit_date`. O hook monta os plugins ANTES do commit existir, então o `ref` gravado é o do commit anterior; o CI re-monta com o HEAD do PR e o README diverge. O drift-guard ignora esses campos no `provenance.json`, mas no README eles contavam. **Cura:** o README só carrega campos content-stable (`repository`, `tree_sha`); ref/data ficam no `provenance.json`. **Bancada:** caso (d) — dois HEADs com as mesmas fontes ⇒ README `cmp` idêntico; mutante (gerador antigo) reprova, corrigido passa.
