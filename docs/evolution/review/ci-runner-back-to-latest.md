---
title: 'Resíduo — o CI volta ao ubuntu-latest, com a bancada completa verde no 26.04'
date: 2026-10-19
branch: ci/runner-back-to-latest
reviewed_diff_sha256: 4e0e1137618ca0892255cc2d05faaf258e07dde9ae7ec54a48b1bf8b7a9fa736
reviewed_code_sha256: d247080dae337abcafea5ba9d833b264b1d65172853117d2b4cb3be710f727db
findings_total: 1
findings_real: 1
findings_fixed: 1
tokens: 0
duration_min: 40
verdict: CORRIGIDO
elenxo: nao
nota: >-
  Fecha a perna "adaptar" de D_RUNNER_FIXADO_2404_1019. Gatilho de Q_ADAPTAR_GUARDAS_AO_2604_E_VOLTAR_AO_LATEST
  cumprido e medido: o PR-sonda #1210 apontou a bancada para o ubuntu-26.04, e as 4 faixas deram 4171 passaram,
  0 pulados e 0 falharam em STRICT, com Image: ubuntu-26.04 conferida nos logs. O #1210 foi fechado sem merge.
  Achado: a 1ª medida, num container ubuntu:26.04 na VPS, não serviu. O container não espelha a imagem do GitHub
  (mawk no lugar de gawk, sem as ferramentas pré-instaladas), deu asorti indefinido em massa e deixou 263 famílias
  sem rodar; a medida válida é o runner real. Os 10 runs-on voltam a ubuntu-latest, sem nenhum pin restante. Grafo
  ci-runner-2604-2026-10: a pergunta vira done com a evidência E_BANCADA_COMPLETA_VERDE_NO_2604; radar e
  contrato verdes. Confirmed do grafo editado, todos vistos: E_RUNNER_2604_DERRUBA_GUARDAS_POR_AMBIENTE,
  E_BANCADA_COMPLETA_VERDE_NO_2604.
---
