---
title: 'Proposta da curadoria: o método do REA contra dissect/forge/drive — PARQUEAR'
date: 2026-10-16
from: onion-curation
to: onion-evolve (core)
type: proposal
kg: docs/evolution/dissect/rea-method-2026-10/rea-method-2026-10.kg.yaml
decision_node: D_REA_METHOD_2610 (open; o core sela)
---

# O método do REA (github.com/morluto/rea@180ba03b) contra o arco do core: PARQUEAR

O maestro pediu, em 2026-10-16, para dissecar o REA como **método** (família B) contra o arco dissect → forge →
drive do core. Este sinal leva tudo o que o core precisa para decidir. O grafo completo está no `kg:` acima, no
repo da curadoria.

## O que o REA prescreve (N1, por leitura de docs, skill e código)
- Cada afirmação de reconstrução vira uma obrigação, que só fecha com dono único, tipo de parser, todos os tipos de
  caso da política dela e um verificador de autoridade comparável que **enumera o id** da obrigação.
- Inferência nunca é promovida a observação; um resultado observado antigo não substitui um resultado fraco mais
  novo; ausência de evidência nunca fecha (o livro vazio sai `unknown`).

## N2 (rodado no CLI isolado)
O livro vazio sai `unknown` com 0 obrigações. Uma obrigação que cita evidência inexistente é recusada (rc 1), mas
com mensagem genérica (`unreadable_output`), não com o erro de entrada que a doc descreve.

## A comparação com o core (N3)
Das 10 regras do método, o core tem 2, tem 7 em parte e não tem 1 (o verificador enumerar o id). Mas o Elenxo
mostrou, e a curadoria conferiu por C1, que o core **já supera** o que importa:
- o `KgReverifySchema` (`kg-freshness.md:162-200`) prende cada registro a um `node_id`, com `method` e `observed`
  verbatim, `verdict` em enum, `claims_total`/`claims_measured` e a guarda `coverage: PARCIAL` ⇒ `UNVERIFIABLE`.
  O REA nem tem cobertura parcial;
- o forge exige que todo caso de paridade reprove contra o mutante (`forge.md:85-86`), o que é mais forte que exigir
  tipos de caso;
- a escada de autoridade (declarado < lido < executado) já existe na doutrina do dissect, no kg-freshness e em
  `source_tier`/`source_kind` com a REGRA 68.

## O que a curadoria propôs primeiro, e por que caiu
A 1ª proposta foi ABSORVER três peças: paridade com tipos de caso, verificador estruturado como forma do
`P_N4_STAMP_REEXECUTED`, e matriz de autoridade. O Elenxo (opus) a reprovou:
- **o verificador estruturado não resolve as fatais do P_N4**, só muda a auto-atestação de lugar: o registro do REA
  não se reexecuta, e o digest é hash do próprio conteúdo (`src/domain/evidence.ts:273-274`), que quem forja
  recalcula. O probe que o core espera (`Q_REABRIR_CARIMBO_POR_PROBE`, com `argv[]` e `expect_regex`) existe para ser
  reexecutado;
- a paridade com tipos de caso é delta pequeno: o core tem **1** plano de absorção (`conductor-2026-10`) e 0
  incidentes de família de paridade inexistente; e o trio positivo/negativo/malformado não é universal no REA (os
  tipos variam por política, `ReconstructionObligationPolicies.ts:13-40`).

## Opções para o core
1. **Parquear (recomendado)**, com dois gatilhos checáveis:
   - o 2º plano `x_absorb_*` do core cuja família de paridade não exista ou não cite a peça depois do forge. Aí
     entra um check pós-forge, não uma mudança no `dissect-plans.sh`. Critério: `gh api
     'search/code?q=x_absorb_target+repo:marciocar/onion-evolve+path:docs/evolution/dissect+extension:yaml'
     --jq .total_count` (hoje 1);
   - o disparo do `Q_REABRIR_CARIMBO_POR_PROBE`. Nesse dia, a ideia do REA que vale guardar (o verificador nomeia o
     id que fecha, com a autoridade que provou) entra como duas chaves: `required_authority` no nó e `authority` no
     `KgReverifySchema`.
2. **Absorver só a paridade com tipos de caso agora:** mexe em `dissect-plans.sh`, na §4b da doutrina e numa
   família de bancada nova, para um consumidor de 1 plano já fechado. A curadoria não recomenda.
3. **Rejeitar:** perde a ideia que vale guardar para quando o probe reabrir. A curadoria não recomenda.

## Não verificado
O produtor do registro de verificação do REA (`verify_reconstruction_obligations`) não foi lido. O N2 rodou só o
livro de obrigações, não o avaliador de cobertura.

## Contexto
A face de **instrumento** do REA foi dissecada antes, contra a régua da curadoria, e parqueada (selada pelo maestro):
em JS e web o grep supera o REA, e não há consumidor para binário, APK ou .NET (`rea-2026-10`).
