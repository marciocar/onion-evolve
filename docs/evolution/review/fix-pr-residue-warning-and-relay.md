---
title: 'Resíduo — o aviso do gh pr create olha o resíduo e o papel; o carteiro decide a colisão de nome pelo conteúdo'
date: 2026-10-07
branch: fix/pr-residue-warning-and-relay
reviewed_diff_sha256: 1cae17b682b8c7a75ac39c9edcad9d1075ccc83027604307872b325726ec6f67
reviewed_code_sha256: 5939df97d3d147d24841e854a347edd82c57466f80ad2ed9ca34024cc601fc4d
findings_total: 3
findings_real: 3
findings_fixed: 3
tokens: 0
duration_min: 35
verdict: CORRIGIDO
elenxo: nao
nota: >-
  Triagem do sinal upstream do onion-kg-ssot (2026-10-07). Os três defeitos de mecanismo que ele
  mediu foram reproduzidos no core antes de curar. (1) O aviso PR-SEM-PASSADA-ADVERSARIAL casava só a
  string do comando: disparava também para quem tinha o resíduo commitado (o PR #3 de lá; e os PRs
  abertos de worktree aqui, já na fila como Q_HOOK_LER_RESIDUO_DA_BRANCH_DO_PR). Agora confere o
  resíduo na branch do PR (o `--head`, senão a corrente; o diretório do último `cd`, senão o do
  projeto). (2) No repo com papel adopted|hub|standalone, o aviso dizia "o gate vai acusar" onde a
  REGRA 56 (PR aberto carrega RESÍDUO da passada adversarial) sai fora de escopo por desenho. Agora
  usa o mesmo predicado do review-artifact-check.sh e diz a verdade. (3) No co-relay.sh, a checagem de
  existência saía "já relayado" antes do dedup por conteúdo, e a versão atualizada de um sinal nunca
  chegava. Agora o idêntico vira no-op, o diferente sobre destino untracked é entregue por cima, e o
  diferente sobre destino TRACKED é recusado com a instrução de usar nome novo (I3: nunca mexer na
  árvore do core). Bancada: (s)(t)(u) no empty_result_guard, (h)(h2)(h3) no corelay, e o (j) ficou
  hermético (ele dependia do checkout vivo). Os três mutantes reprovam: tirar `_residuo_commitado`
  reprova (s) e (u), tirar `_repo_derivado` reprova (t), voltar à colisão por existência reprova
  (h) e (h2). Sem Elenxo, declarado: é a cura de um AVISO (exit 2 de PostToolUse, que não veta) e de
  um carteiro, com as duas polaridades e o mutante de cada cura. A opção (a) do sinal (veto
  PreToolUse no create) NÃO entra aqui: fica como nó GATED, com a taxa de falso positivo a medir.
---

# Resíduo — `fix/pr-residue-warning-and-relay`

Teto: o aviso só segue um `cd <caminho>` literal. Caminho com variável cai no diretório do projeto,
e o efeito é avisar a mais, não a menos. A branch vem do `--head`; um `owner:branch` é cortado no `:`.
