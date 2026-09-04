---
date: 2026-09-04
instance: onion-evolve
type: learning
classification: public
tags: [plugins, marketplace, readme, documentacao, behavior-over-declaration]
affects: [meta, engineering]
breadcrumb_for: []
share_with: []
next_recommended: "após o merge: materializar o onion-plugins e pushar; conferir no GitHub a tabela e os 8 READMEs por plugin"
review_after: 2026-12-03
conflict_class: static
---

## Signal
Pedido do maestro: revisar `~/onion-plugins` e levar o README ao padrão de referência de plugins do Claude Code, com documentação
premium. A revisão achou duas coisas antes do README: o README era GERADO (editar lá seria sobrescrito) e o `marketplace.json`
repetia `version` por entrada — exatamente o que a doc oficial manda não fazer (o `plugin.json` é a autoridade; uma versão
estagnada na entrada esconde updates). "Premium" aqui virou **catálogo gerado do próprio artefato**, não prosa escrita à mão.

## Evidence
- Padrão de referência medido na fonte: doc oficial de marketplaces (campos `displayName`/`category`/`tags`/`license`; README
  com add/install/update/enable/uninstall/list; regra de versão) e o README do diretório oficial (estrutura de plugin, nomes
  imutáveis, licença por plugin).
- `plugin-readme.sh`: README por plugin a partir do frontmatter (só entre os dois `---`, `>` dobrado juntado, 1ª frase),
  `capability.json` (provides/requires), `provenance.json` (repo/ref/tree_sha), hooks.json — namespace `/<plugin>:<comando>`.
- `marketplace-readme.sh`: quick start slash+CLI, tabela dos 8 plugins com contagens, manter em dia, política de versão, moat,
  estrutura de plugin. `generate-marketplace.sh`: entradas com `displayName`/`category`/`tags`/`license`, SEM `version`.
- Bancada `marketplace_readmes` (3 casos): catálogo do plugin, tabela do marketplace + manifesto, e re-montagem sobrescreve
  edição manual (é artefato gerado — o README também obedece à REGRA 19).

## Next crumb
O README "premium" que não é derivado do artefato mente em semanas (contagens, comandos renomeados). Documentação de plugin
é PROJEÇÃO do plugin: quem quer melhorar o texto muda a fonte (descriptions de comando/agente/skill), não o README.
