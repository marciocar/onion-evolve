---
title: 'Resíduo — o caminho de merge verificado rebaseia sozinho o PR em conflito de projeção, e espera as runs nascerem'
date: 2026-10-08
branch: fix/merge-verified-auto-rebase
reviewed_diff_sha256: pendente
findings_total: 1
findings_real: 1
findings_fixed: 1
tokens: 0
duration_min: 40
verdict: CORRIGIDO
elenxo: nao
nota: >-
  Decisão do maestro em 2026-10-08 (opção 2 da avaliação de três; a 1 é ponte de processo e a 3 ficou
  com gatilho). Defeito medido: desde 2026-10-07, 25 PRs e 33 commits de "projeções geradas
  regeneradas"; cada merge deixava os PRs abertos CONFLICTING e o GitHub não dispara CI em PR em
  conflito, então a espera parava em "no checks reported" (#957 duas vezes, #959, #960, #975). Cura em
  ops/pr-merge-verified.sh: ao ler mergeable=CONFLICTING (só o literal; leitura vazia segue os gates de
  sempre), roda ops/pr-finalize.sh --rebase --push na worktree LOCAL da branch do PR, achada por git
  worktree list --porcelain; no máximo ONION_MERGE_REBASE_MAX (2) vezes; conflito de fonte para com rc
  diferente de zero nomeando o arquivo (lê "conflito REAL em" do pr-finalize); sem worktree local, diz o
  comando exato e para; depois do rebase confere que o head do PR é o HEAD da worktree (a branch certa)
  e espera as runs do head novo NASCEREM e terminarem, com prazo ONION_MERGE_WAIT_SECS (1800). Bancada
  pr_merge_verified: 27 de 27 com LC_ALL=C, casos novos (w) rebase e merge provado, (w2) runs que não
  nascem param no prazo sem merge, (x) conflito de fonte para nomeando src/x.sh sem merge, (y) sem
  worktree diz o comando sem rebasear, (z) conflito recorrente para em 2 rebases. Mutantes, os 5
  morderam: M1 sem a chamada do rebase (w)(x)(z); M2 rc do rebase ignorado (x); M3 worktree escolhida às
  cegas (w)(w2)(x)(y)(z); M4 sem limite (w)(z); M5 sem a espera das runs (w2). Achado na própria passada:
  a 1ª forma do M5 não mordia — o mutante era fraco (o awk ainda falhava na linha vazia), não a cura;
  refeito como quebra direta da espera, mordeu. Passada adversarial própria, pelos três riscos pedidos:
  laço de rebase (fechado pelo limite, caso z); rebase da branch errada (fechado pela busca exata
  "branch refs/heads/<head>" na porcelain e pela conferência head do PR = HEAD da worktree depois do
  rebase); rebase que esconde conflito de fonte (o pr-finalize aborta e devolve rc 1, e o rc é lido,
  caso x e M2). Teto: o auto-rebase só age com a branch numa worktree deste repo — PR de fork ou de outra
  máquina recebe o comando; a espera das runs é por prazo, não por evento. Grafo: Q_MERGE_DRIVER_PARA_
  PROJECAO_GERADA vai a done com verified_at entre aspas e o gatilho da opção 3 no narrative; radar
  --integrity --schema exit 0 e kg-contract-check rc 0. REGRA 87 (PR que EDITA um .kg.yaml enxergou os
  confirmed dele): o grafo editado é o da fila, cujos confirmed seguem como estavam. Sem Elenxo separado,
  declarado. Pre-commit pulado por ordem do maestro; validação = família + mutantes + pr-finalize + CI.
---

# Resíduo — `fix/merge-verified-auto-rebase`
