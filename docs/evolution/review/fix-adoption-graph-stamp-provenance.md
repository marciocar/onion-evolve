---
title: 'Resíduo — o recarimbo do grafo de adoção leva a fonte da verificação junto com o pin'
date: 2026-10-18
branch: fix/adoption-graph-stamp-provenance
reviewed_diff_sha256: 9d90d8c7655487a29f1dce10b34e7f915ffe0e0c3ca06b00cf8b30fc4442f95a
reviewed_code_sha256: 2f56f6b9d1a4859b8b5ed7c2ebbc3e38f314523730408ee552e6c5c916ffc9ed
findings_total: 1
findings_real: 1
findings_fixed: 1
tokens: 0
duration_min: 25
verdict: CORRIGIDO
elenxo: nao
nota: >-
  Sinal de um adotante, depois do --update para 3bd13fc565e2: o stamp-adoption-graph-pin.sh trocava o
  verified_at e o x_pin do nó ONION_INSTALLED, mas o verified_against e a provenance (source/locator)
  continuavam citando o pin anterior. O nó declarava como verificado algo que já não era o verificado, e a
  revisão independente do adotante pegou isso à mão. A cura: no recarimbo, as citações do pin que ESTAVA no nó
  passam a citar o pin novo, e só em verified_against e em provenance.source/locator, os campos que descrevem
  a verificação atual. O label e a narrative guardam a história e ficam como o dono escreveu, a mesma regra
  que o motor já tinha para o label. Um outro hash citado no nó como referência também fica. A saída diz
  quantas citações trocou. Dogfood no grafo real do adotante, no estado anterior ao update (349fc50), num
  sandbox: 3 citações trocadas no ONION_INSTALLED; o label editado pelo dono ficou intacto (rc=3, como antes);
  o outro nó, que cita o mesmo pin como referência de uma prova antiga, também não mudou. Bancada: caso (i4) de
  adopter_shape, com mutante; adopter_shape tem 16/16, e as 9 famílias vizinhas (write_stamp,
  seed_adoption_graph, adopt_*, …) somam 85/85. Sem Elenxo, declarado: a troca atinge só dois campos de um
  único nó, a âncora é o pin que estava no próprio nó, e o mutante prova que o caso mede a cura.
---

# Resíduo — `fix/adoption-graph-stamp-provenance`

Teto: só se troca o pin que o próprio nó declarava (x_pin, ou o pin do label). Se o dono citar na fonte um pin
antigo que não é esse, a citação fica, e o sinal certo para isso é revisão humana, não substituição cega.
