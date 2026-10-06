---
title: "O radar não avisa tipo de nó trocado (MU-07) nem decisão done em DEV (MU-18) — medido na fumaça da porta 0 do Onion SLM"
date: 2026-10-06
type: signal
from: onion-slm (adopted, pin 9e75a73d0401)
to: core (onion-evolve)
flow: upstream
severity: medium
---

# O radar só reprova o erro estrutural; o semântico passa calado

Medido em 2026-10-06 com `kg-radar.sh` do pin `9e75a73d0401`, sobre 80 fragmentos de 2 nós tirados
de grafos reais do core (commit `2d316566c9a4`) e mutados pelos operadores do catálogo MU-01..18
(fonte do chat, branch `discuss/onion-slm`). O critério foi o código de saída do radar.

> Esta é a versão 4 do sinal. Na v1 da fumaça, 13 dos 20 casos MU-18 não mutavam nada (a decisão
> já estava em DEV); depois, os fragmentos passaram a excluir as verticais PRIVATE do core
> (`docs/discussions/onion-pessoal-*`). A fumaça foi regenerada e medida de novo; os números abaixo
> são os da última. A conclusão sobre o radar não mudou em nenhuma das três.

| operador | o que muda | fragmentos | radar reprova |
|---|---|---|---|
| nenhum (controle) | — | 20 | 0 |
| MU-02 | SUPPORTS → REFUTES num nó que segue `confirmed` | 20 | 20 |
| MU-07 | `node_type` trocado (evidence→claim, decision↔question) | 20 | 0 |
| MU-18 | decisão `done` movida de `plane: PROD` para `DEV` (só onde estava em PROD) | 20 | 0 |

## O que pede atenção

1. **MU-18 contradiz a gramática sem aviso.** A `kg-grammar.md` diz que "`decision` só vira `done`
   verificada em **PROD**", mas o motor só rebaixa a atenção do nó (`DEV/done` = 0,5). Não sai nenhum
   ⚠ nem ✗. Sugestão: um aviso SOFT `decision-done-em-DEV`, que é checável por awk.
2. **MU-07 não é checável por regra, e isso é o achado.** O tipo de nó trocado é erro semântico. No
   mesmo conjunto, o Claude zero-shot (`claude-opus-5-5`, effort medium) pegou 17 de 20 MU-07 e 12 de
   20 MU-18, com 7 alarmes falsos em 20 controles (contado pelo corretor do eval em modo fumaça). O
   MU-18, que o radar poderia checar por awk, um modelo pega só metade das vezes: é argumento para a
   regra do item 1, não para um modelo. O MU-07 é o espaço onde um especialista do Onion SLM teria de
   provar valor, e onde o gate determinístico precisa de um sensor que ele hoje não tem.

## De onde vem

`onion-slm` → `eval/smoke/mutate.py` e `eval/smoke/radar_summary.json`, e o nó
`onion-slm-stage0#E_RADAR_CATCHES_MU02_ONLY` em `docs/onion/graph/onion-slm-stage0.kg.yaml`.
Os casos do eval selado são privados e não vão neste sinal; os fragmentos de fumaça são dados do
próprio core.
