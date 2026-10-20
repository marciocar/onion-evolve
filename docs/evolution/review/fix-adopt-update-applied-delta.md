---
title: 'Resíduo — o relatório do --update mede os arquivos aplicados no alvo'
date: 2026-10-20
branch: fix/adopt-update-applied-delta
reviewed_diff_sha256: pendente
findings_total: 3
findings_real: 1
findings_fixed: 1
tokens: 0
duration_min: 45
verdict: CORRIGIDO
elenxo: nao
nota: >-
  Sinal do hub brain-granaai (2026-10-19, fricção 3): o relatório colava o git diff --stat <pin>..HEAD --
  <manifesto> da fonte e dizia 239 arquivos, mas no alvo chegaram 540. A causa medida: vendor/kg-ssot já
  existia no core no pin e só entrou no manifesto depois (5eed13fa), então chega inteiro e o delta da fonte não
  o vê. A cura é o helper applied-delta.sh, que mede NO ALVO, de merge-base(<integração>, HEAD) até HEAD, e
  conta à parte o que ainda está sem commit. O adopt.md passa a mandá-lo no relatório, e o delta da fonte fica
  rotulado como o que mudou no core. Dogfood no caso real: num clone do hub em scratchpad, com a integração no
  pai do update (cf5b652ba) e o HEAD em 5f482ea0b, o helper deu "540 commitados", 389 deles em vendor/kg-ssot,
  que são os números do sinal. A passada adversarial levantou três pontos. (1) Duas pontas em vez do
  merge-base: um commit novo na integração entraria na conta. É real e curado, com o merge-base no helper e o
  mutante (m) da bancada mordendo. (2) Medir depois do merge na integração daria 0, porque o merge-base vira a
  ponta da branch. Não é defeito: o relatório é escrito antes do PR, e o adopt.md diz isso. (3) Nome de
  arquivo com quebra de linha contaria dobrado. Também não é defeito: o git põe esse nome entre aspas numa linha
  só, com ou sem core.quotepath. A família nova applied_delta deu 5/0. Sem Elenxo, declarado: é um helper de
  medição read-only com bancada e mutante, sem guarda nova nem mudança de veredito.
---

# Resíduo — `fix/adopt-update-applied-delta`

Teto: o helper mede o que a branch do update traz em relação à integração. Ele não sabe quais desses arquivos
vieram do manifesto e quais são do próprio adotante na mesma branch, o que não acontece no fluxo escrito: a
branch dedicada só recebe o merge da onion/vendor, a config pós-merge e o carimbo.
