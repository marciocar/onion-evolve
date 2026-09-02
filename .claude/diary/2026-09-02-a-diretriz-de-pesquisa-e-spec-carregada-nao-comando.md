---
date: 2026-09-02
instance: onion-evolve
type: learning
classification: public
tags: [pesquisa, meta, lente, fontes, mercado, instruction-bloat, kg-ssot, deep-research]
affects: [meta, engineering, product]
breadcrumb_for: []
share_with: []
next_recommended: "F1 do plano (fragmento + campos + guardas + kg-corpus-grep) — só depois do selo do maestro; e toda pesquisa nova abre com kg-corpus-grep antes de buscar"
review_after: 2026-12-01
conflict_class: static
significance: "A pergunta 'como não redigir a diretriz toda vez?' respondeu-se com 'não é comando, é contexto carregado + campo + guarda' — e a pesquisa devolveu duas coisas que valiam sozinhas: não há doutrina de fontes no core, e o mercado descreve o Onion em CAUTION (instruction bloat) e em ASSESS (context graph) ao mesmo tempo."
kg: "docs/evolution/research/meta-research-lens-2026-09/meta-research-lens-2026-09.kg.yaml"
---

## Signal
A diretriz de pesquisa do maestro é **contexto**, não procedimento: vira fragmento + rule por path + skill
auto-ativada com `!cmd` (o corpus entra antes da busca), três campos no grafo (`valid_from`, `source_tier`,
`meta.review_after`) e duas guardas SOFT. Um comando só (`/onion-research`, derivado do `/deep-research`
embutido no 2.1.258), porque workflow exige opt-in e o comando é o opt-in.

## Evidence
- Reforços do maestro na mesma sessão: *"sempre precisamos estar de olho no mercado"* (mercado/capital é
  eixo INVARIANTE, worker sempre no fan-out) e *"tem doutrina, maquinaria ou arquitetura para escolher as
  fontes?"* — medido: **não**; só R15 e uma frase em `kg.md:116`.
- 70% da diretriz já vivia no `/meta:radar`; os 3 gaps (tema livre · grafo não envelhece · ninguém lê o
  corpus) são uma superfície só.
- Literatura 2026 endossa metadado explícito + regra determinística sobre julgamento do modelo (STALE:
  55,2%); Anthropic admite 17% de falso-negativo no auto mode — número externo para o `exit 2`.
- Contra-sinal: Thoughtworks Radar v34 pôs *agent instruction bloat* em CAUTION — descreve o core. Por isso
  a diretriz NÃO entra no CLAUDE.md.

## Next crumb
- Selar F1–F4 (nós `D_F*` no grafo); F1 é a fundação e o dogfood é o próprio `kg-corpus-grep` devolvendo os
  nós desta sessão. O fio de poda (`D_PODA_INSTRUCTION_BLOAT_MEDIDA`) fica gated no dogfood de F3.
