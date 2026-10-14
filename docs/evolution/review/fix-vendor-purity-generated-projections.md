---
branch: fix/vendor-purity-generated-projections
date: 2026-10-14
reviewed_diff_sha256: eb445c0b9d37fe96d9521eade2496c0f3c2a3a822a661d6b819da02654612c30
reviewed_code_sha256: 9396173057d8a7032e87bed68333f01a0d9a0df5869f9f8d9e01799e09bea574
findings_total: 2
findings_real: 2
findings_fixed: 1
tokens: 0
duration_min: 35
verdict: REPROVADO_E_CURADO
reviewer: passada adversarial própria (sem subagente), default reprovado na dúvida; causa medida no --update real de um hub, caso (g2) com mutante, dogfood no mesmo update
---

# O teste de pureza da onion/vendor reconhece as projeções geradas como framework

## O que aconteceu

O `--update` de um hub para o pin 0d0636f4ca74 foi recusado com BASE CRUZADA (rc=11). Os 5 "arquivos alheios" eram
as projeções que o próprio commit da `onion/vendor` regenera em `docs/onion/` (inventory, graph, kg-read-index,
testing-inventory, testing-state). Elas ficam fora do manifesto, e o teste de pureza as lia como produto de outra
integration branch. O conserto que o helper sugeria (renomear a vendor) estaria errado neste caso.

## A cura

- `regen-ssot-projections.sh --list-outputs` imprime tudo o que o gerador escreve, a partir da MESMA lista que o
  laço dele usa (`_PAIRS`).
- `_vendor_is_framework_pure` tira essa lista do diff antes de julgar. Se o gerador estiver ausente ou mudo, não
  tira nada (falha fechada: a recusa segue como antes).

## Passada adversarial

1. **A cura mata a guarda?** Não: o caso (g), base cruzada de verdade com `src/app.js`, segue saindo rc 11. O (g2)
   cobre a projeção e passa. O mutante sem o filtro devolve o mesmo caso a rc 11. As famílias mapeadas aos dois
   scripts deram 83/0, e a vendor_branch inteira passou.
2. **O dogfood real passou?** Real, e NÃO curado aqui: no mesmo update, com o helper curado, a BASE CRUZADA
   sumiu, mas o merge deu 2 conflitos reais em projeção gerada (`kg-read-index.tsv`, `testing-inventory.md`),
   porque as duas pontas as regeneram. Foram resolvidos regenerando do filesystem. Fica como próximo passo: o
   vendor-branch resolver sozinho, por regeneração, os conflitos limitados às projeções geradas, em vez de
   devolver rc 10.
