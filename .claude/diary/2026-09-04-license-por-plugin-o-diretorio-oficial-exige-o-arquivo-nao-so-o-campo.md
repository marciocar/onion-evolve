---
date: 2026-09-04
instance: onion-evolve
type: decision
classification: public
tags: [plugins, marketplace, license, diretorio-oficial]
affects: [meta]
breadcrumb_for: []
share_with: []
next_recommended: "após o merge: materializar o onion-plugins e pushar; submeter `onion` ao diretório oficial (ato do maestro)"
review_after: 2026-12-03
conflict_class: static
---

# LICENSE por plugin — o diretório oficial exige o arquivo, não só o campo

O `plugin.json` já declarava `license: MIT`, mas o diretório oficial de plugins do Claude Code exige o **arquivo** `LICENSE` na raiz de cada plugin (junto de `plugin.json` e `README.md`). O assembler agora copia o `LICENSE` do source; sem LICENSE no source, escreve MIT **sem ano** — content-stable, a lição da REGRA 19 (Plugins de vertical sincronizados com as fontes) do #790 aplicada antes de doer.

**Bancada:** caso (e) da família `marketplace_readmes` — o LICENSE do source aparece no plugin montado com o mesmo conteúdo.
