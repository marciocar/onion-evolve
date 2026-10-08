---
title: 'Resíduo — o pr-finalize sem os quatro atritos da leva de 2026-10-07/08 (SAC-66)'
date: 2026-10-08
branch: fix/pr-finalize-pipeline
reviewed_diff_sha256: pendente
findings_total: 4
findings_real: 4
findings_fixed: 2
tokens: 0
duration_min: 60
verdict: CORRIGIDO
elenxo: nao
nota: >-
  Conduzido pelo /meta:drive no nó Q_PR_FINALIZE_MELHORIAS (Linear SAC-66), com aprovações automáticas
  do maestro até o merge. Os quatro atritos de E_PR_FINALIZE_ATRITO_MEDIDO, curados em ops/pr-finalize.sh.
  (1) O carimbo só fica em rodada que termina: o estado do resíduo (arquivo e entrada do índice) é
  guardado antes do primeiro carimbo, e um trap EXIT único o devolve se a rodada não chegar ao lint do
  commit com 0 HARD. Antes, a falha deixava o resíduo carimbado e a rodada seguinte recusava "o código
  mudou depois da revisão", com limpeza à mão. (2) O commit que carrega SÓ projeção gerada e o resíduo
  deste PR sai sem o hook: o hook rodaria o lint inteiro, e o passo 3 roda o mesmo lint sobre o mesmo
  commit, no ambiente do CI, antes de qualquer envio. Commit com conteúdo do PR segue pelo hook. Escolhi
  isto em vez de comparar o hash da árvore com um pré-voo de lint (a forma sugerida no pedido): o lint
  do passo 3 já julga exatamente o commit que vai ao push, e a forma do hash exigiria mexer no hook
  vendorizado para ele confiar num marcador. (3) A violação sai nomeada no fim: o commit é capturado,
  e em reprovação o motor imprime a lista do ONION_LINT_HARD_FILE (que passa ao hook) ou as linhas de
  VIOLATION/✗. (4) --check: monta o índice como commit, abre uma worktree descartável, roda regen,
  carimbo e lint nela e relata o que faria; o repo vivo não é tocado. Recusa --push e --rebase.
  Bancada (família pre_push, LC_ALL=C): 15 casos novos, as duas polaridades de cada cura, 50/50 verdes.
  Mutantes (todos reprovam): sem o restauro do resíduo → 3 casos, inclusive a mensagem exata "o CÓDIGO
  mudou depois da revisão" da leva; projeção sempre pelo hook → 1; hook nunca (fail-open) → 4; sem o
  resumo final → 1; --check caindo no modo real → 2. O caso (c) de lint_hard_file foi atualizado para a
  forma nova (_lint_in recebe o arquivo). PASSADA ADVERSARIAL própria, atrás do falso positivo e do
  fail-open: (a) REAL e curado no desenho: pular o hook com conteúdo do PR seria fail-open; o mutante
  "hook nunca" prova que o caso de conteúdo o pega. (b) REAL, declarado: uma projeção editada à mão sai
  sem o hook; quem a pega é o lint do passo 3 (as REGRAS 62/81/39 cobram projeção defasada), e o
  federation-console.html não tem regra própria, nem antes nem agora. (c) REAL, declarado: quando o lint
  do passo 3 reprova DEPOIS de o commit com o carimbo existir, o restauro deixa o resíduo 'pendente'
  STAGEADO sobre um HEAD carimbado; a rodada seguinte carimba de novo (provado no caso que roda duas
  vezes), mas um --rebase nesse estado é recusado por índice sujo até alguém commitar. Também declarado:
  a saída do git commit agora aparece no fim, não ao vivo; o --check deixa objetos soltos no banco do
  git (o gc recolhe). Grafo: a fila está no teto de 30, por isso a evidência da execução foi para o
  verified_against de Q_PR_FINALIZE_MELHORIAS, que segue open com o que resta (registrar etapa e rc,
  catracas estáticas no checkpoint, rebase com índice sujo); radar --integrity --schema exit 0, nenhum
  id colhido. REGRA 87 (PR que EDITA um .kg.yaml enxergou os confirmed dele) — confirmed vistos neste
  grafo: os 16 nós confirmed da fila, inclusive E_PR_FINALIZE_ATRITO_MEDIDO, que sustenta o nó editado.
  (d) REAL e curado, achado pelo CI (faixa 3): dois dos casos novos decidiam por `<produtor> | grep -q`
  e a catraca do shell_pipefail_robustness subiu de 34 para 36 sítios; os dois viraram here-string, e
  a família da catraca passa. Sem Elenxo de agente separado, declarado. Pre-commit pulado por ordem do maestro (commits com
  --no-verify como checkpoint); validação = famílias tocadas + mutantes + pr-finalize + CI.
---

# Resíduo — `fix/pr-finalize-pipeline`

Fecha SAC-66. O motor fechou o próprio PR com a versão nova (dogfood).
