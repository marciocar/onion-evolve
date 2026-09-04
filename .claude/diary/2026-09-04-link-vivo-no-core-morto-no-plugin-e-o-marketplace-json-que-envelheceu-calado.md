---
date: 2026-09-04
instance: onion-evolve
type: learning
classification: public
tags: [plugins, marketplace, links, projecao, behavior-over-declaration]
affects: [meta]
breadcrumb_for: []
share_with: []
next_recommended: "F2: consolidação 8→5 + REGRA 77 (contrato de dependência entre plugins)"
review_after: 2026-12-03
conflict_class: static
---

# Link vivo no core, morto no plugin — e o marketplace.json que envelheceu calado

**Links.** O assembler já curava "irmã não embarcada → texto", mas só em `kb/` e só para `irma.md` no mesmo diretório. Medidos 123 links relativos mortos fora dessa cura (commands 46, utils 31, kb 30, skills 17). A generalização (REGRA 75) tinha um furo que a REGRA 19 pegou na hora: `../../../docs/x.md` resolvia para FORA do plugin — existe no core ao lado de `plugins/`, não existe no consumidor — e o veredito dependia de ONDE o plugin era montado (em `/tmp` morria, em `plugins/` vivia). "Vivo" agora é *resolve dentro do plugin*. O gate de sincronia é o revisor da própria cura.

**marketplace.json da raiz.** Estava no formato pré-2026-09-04 (todas as entradas `0.1.0`, sem displayName/category/tags) e nenhuma guarda o comparava ao gerador. Ao curar, outro defeito de uso: `gerador > marketplace.json` trunca o arquivo antes de o gerador ler o top-level dele (name/owner viram default). Cura: `marketplace-root-check.sh --write` (temp + mv); o pre-commit regenera junto com os plugins; REGRA 76 confere no CI.
