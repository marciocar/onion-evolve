---
title: 'Resíduo — o onion-kg-ssot no registro, a semente que executava o próprio comentário e dois achados na fila'
date: 2026-10-06
branch: chore/register-onion-kg-ssot
reviewed_diff_sha256: f7b0fda148f22df565b8762acaaab55e2b11e474ef81f71a2f116a86f57c76e8
reviewed_code_sha256: ebe47a0f8a8844dc9146b96e24e29eb16548fb940d27181d3f8cd541792122db
findings_total: 1
findings_real: 1
findings_fixed: 1
tokens: 0
duration_min: 15
verdict: CORRIGIDO
elenxo: nao
nota: >-
  (1) O onion-kg-ssot entra no members.yaml (produto independente, dogfood nos dois sentidos; pin-ok
  fe8359e38b43, members-validate válido com 26 membros). (2) DEFEITO MEU, do PR #938: o comentário novo da
  semente do /meta:adopt pôs o separador YAML entre crases DENTRO de um heredoc sem aspas, e o shell o executou
  (erro de comando não encontrado, comentário cortado no adotante). Achado pela adoção do onion-kg-ssot; a
  bancada não pegava porque o caso (a) descartava o stderr do semeador. Cura: o comentário sem crase, e o caso
  (a0) exige o stderr sem "command not found". O caso pegou na 1ª rodada MAIS UMA crase, na própria nota que
  explicava o erro — o defeito real serviu de mutante: reprova com a crase, passa sem ela. Varredura: zero crase
  não escapada no corpo do heredoc. (3) A fila-2026-10-06 ganha dois achados da adoção: a trava de merge inerte
  no adotante (sai 0 sem ops/) e a hipótese da skill core-only que viajou. Sem Elenxo, declarado.
---

# Resíduo — `chore/register-onion-kg-ssot`

Teto: a semente já entregue ao onion-curation e ao onion-kg-ssot não é reescrita; o comentário cortado lá foi
reparado à mão no onion-kg-ssot pela própria adoção.
