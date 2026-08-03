---
date: 2026-08-02
instance: onion-evolve
type: error
classification: collective
tags: [cerimonia, amputacao, sdaal, adotante-e-o-consumidor, inferencia, medicao]
affects: [meta, engineering]
breadcrumb_for: []
share_with: []
next_recommended: "Antes de propor AMPUTAR qualquer peça por 'cerimônia' ou 'zero consumidores': (1) abra a peça e leia inteira — 13 acusadas, ZERO sobreviveram ao exame; (2) se é abstração SDAAL do CORE, o consumidor é o ADOTANTE, não o core — meça com `grep -rl <peça> ~/onion-*/ ` e nos repos de adotante registrados em members.yaml, nunca só em `git grep` daqui. O erro tem forma fixa: contei call-sites no lugar errado e chamei o resultado de fato."
review_after: 2026-10-31
conflict_class: static
kg: docs/evolution/research/kg-read-leg-2026-08/kg-read-leg-2026-08.kg.yaml
significance: "Listei 13 peças de 'cerimônia' a amputar e 3 'dívidas de SDAAL'. Ao examinar uma a uma: das 13, NENHUMA sobreviveu como cerimônia; das 3, só 1 era real. A lista tinha sido montada por inferência e apresentada como medição."
---

## Signal

**Acusar de cerimônia é barato; provar é caro — e eu cobrei o preço barato.** Uma lista montada por
inferência (nome parece decorativo, `git grep` local devolveu pouco) foi apresentada com a mesma
confiança de uma medição. O exame peça a peça desmontou quase tudo.

## Evidência

| lista | eu afirmei | sobreviveu ao exame |
|---|---|---|
| peças de "cerimônia" a amputar | 13 | **0** |
| "dívidas de SDAAL" abertas | 3 | **1** |

A raiz não foi descuido — foi **medir no lugar errado**, e o caso exemplar é `de-identification`.
Afirmei "zero consumidores" porque `git grep` **no core** não achava call-site. Mas a peça é uma
**abstração SDAAL do core**, e o consumidor de uma abstração do core **é o adotante**: 9 repos de
adotante mais `onion-pessoal-app/deid.ts` a usam. O número que eu tinha era real; a **pergunta** é
que estava errada.

E o mesmo padrão numa segunda forma: afirmei que a doutrina se contradizia com `plugins/` — *"a
doutrina diz indivisível enquanto o `plugins/` divide"*. `CLAUDE.md:12` diz **"não devem ser
CONSOLIDADOS"**, isto é, *não devem ser fundidos uns nos outros* — o **oposto** de "divididos". Li o
inverso de uma linha que estava aberta na minha frente.

## O que fecha

Fecha com a regra da casa que já existia e não foi aplicada:
**`read-full-content-before-triage`** (memória) — nunca caracterizar pelo título ou
pelo frontmatter. Aqui a violação foi caracterizar por **contagem em escopo errado**, que é a mesma
falha um nível abaixo: o instrumento devolveu um número honesto para uma pergunta mal-feita, e eu
carimbei o número como veredito.

Par exato de **`worst-truth-is-uncertain`** (memória): a pior verdade é a que não temos
certeza — e a lista das 13 tinha **tom** de certeza sem ter **campo** de certeza.

## Fronteira honesta

Correção registrada no grafo com `REFUTES` e status reconciliado (nó que recebe `REFUTES` e continua
`confirmed` é contradição estrutural — o radar reprova). Mas **nenhuma guarda impede a próxima**: não
há mecanismo que exija medição-no-escopo-certo antes de uma proposta de amputação. Fica como padrão
escrito, degrau mais fraco da escada `guarda > KB > migalha`. A generalização mecânica plausível —
"proposta de remoção de peça em `.claude/utils/` exige contagem nos repos de adotante" — **não foi
construída**, e declaro que não foi.
