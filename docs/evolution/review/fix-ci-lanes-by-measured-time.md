---
branch: fix/ci-lanes-by-measured-time
pr: pendente
date: 2026-11-12
reviewed_diff_sha256: pendente
findings_total: 8
findings_real: 8
findings_blocking: 1
tokens: 0
duration_min: 0
findings_fixed: 7
verdict: REJECTED_AND_FIXED
elenxo: true
reviewer: refutador opus (refute-ci-lanes, mandato de REFUTAR o b2ee4e9a0) + passada própria do autor
nota: "tokens e duração não medidos. O refutador reprovou o b2ee4e9a0 (REJECTED) por declaração falsa (o ±3%); a cura está no commit seguinte. 1 dos 8 achados fica como limite (o ganho pequeno da 6ª faixa)."
---

# Passada adversarial: `fix/ci-lanes-by-measured-time`

## O que muda

SAC-423. No nível completo, a faixa 2 do `onion-selftest.yml` (a da `selftest_selection`) estourou o teto
do passo (23 min) no PR #1612 e chegou a 23,4 min na main (run 43208784215).

- **Causa medida.** A fila dinâmica do `lint-selftest.sh --jobs` NÃO pega o caro primeiro. Cada worker
  percorre o script na ordem dele e reivindica a próxima família livre, e a `fixtures` (posição 11) roda
  em todo worker. A `selftest_selection` (posição 130) só começou aos 393 s e terminou aos 1377 s; os
  outros três workers ficaram parados no fim. A sonda de disco do artefato da faixa 2 mostra isso. O plano
  equilibrava a SOMA, e o caso (h) projetava `soma/W`. Os dois erravam o modelo.
- **Simulador da fila no plano** (`ops/testing/selftest-shard-plan.sh`). O plano simula a fila: ordem do
  `--list`, W workers (`ONION_SHARD_WORKERS`, 4 = o nproc do runner) e a fatia da `fixtures` em cada um. Ele
  põe cada família na faixa onde a parede projetada fica menor e depois faz uma melhora local (pior
  parede, depois a soma dos quadrados). Nas 35 faixas de 7 runs completos, o erro é de ±3% com os tempos
  do próprio run e a fatia real da `fixtures`; pela mediana da tabela (o que o `--project` e o (h) usam), é
  de −18% a +43% por faixa. `--project` imprime a projeção por faixa.
- **Tabela re-medida** (`ops/testing/selftest-family-times.tsv`): é a mediana de 7 runs completos da main de
  2026-11-12. A linha `fixtures` passa a ser o TOTAL do run. O coletor (`collect-family-times.sh`) aceita
  vários run-ids e tira a mediana.
- **6 faixas** no workflow. O piso da faixa da `selftest_selection` é a fatia da `fixtures` mais a própria
  família (~11–16 min sozinha). Só mais faixas baixam esse piso.
- **Caso (h)** passa a ler a projeção do próprio plano contra 75% do teto do PASSO. **Casos novos**: (i) a
  projeção é a parede da fila, não a soma; (j) a fila anda na ordem do --list; (k) a repartição minimiza a
  parede; (l) a melhora local baixa o custo de runner; (m) a tabela de tempos cobre o --list.

## Achados

1. (real, curado) O caso (h) aprovava um plano que estourava na main: `soma/W + fixtures/(N·W) + arranque`
   não vê a ordem da fila. Ele agora usa o `--project` do plano, e a régua e o plano são o mesmo modelo.
2. (real, curado) A 1ª versão do guloso pela parede deixava faixas de 9 e de 17 min no mesmo plano. O
   desempate pela menor parede não espalhava a folga. A melhora local por (pior, soma dos quadrados) reduziu
   a soma das paredes de 76,4 para 74,6 min. O pior continua no piso da `selftest_selection`.
3. (real, curado) Durante a medição, um `git reset --soft HEAD~1` encadeado por `;` depois de um commit que
   não aconteceu tirou um commit da base da worktree. O HEAD foi restaurado para `e4a45fc16` (o da
   origin/main buscada) com a árvore intacta. O `stash` próprio usado no passo foi descartado.

4. (real, BLOQUEAVA, curado; refutador) O "±3%" era declaração falsa no lugar onde valia: só vale com os
   tempos do próprio run. Pela mediana, que é o que o (h) lê, o erro por faixa vai de −18% a +43% (a faixa 2
   do run 43208784215 projetou 1127 s e mediu 1378 s). Reescrito no cabeçalho do plano, no workflow, no
   comentário do (h) e na mensagem do commit.
5. (real, curado; refutador) O mutante `sorted(lane)` (ordem alfabética na fila) sobrevivia, e a ordem é o
   achado central desta cura. O caso (j) o mata.
6. (real, curado; refutador) Família nova entrava pela mediana (~3 s) sem aviso. O caso (m) exige que a
   tabela cubra o --list.
7. (real, curado; refutador) Sobreviviam o guloso pela soma, o LPT antigo e a melhora local desligada. Os
   casos (k) e (l) os matam.
8. (real, LIMITE; refutador) O ganho da 6ª faixa é pequeno (ver os limites).

## Mutantes

Todos plantados por `ops/mutate-and-restore.sh`, com `LC_ALL=C`, contra `--families shard_plan`. Os 10
abaixo morreram (rc 1):

- M1: `selftest-shard-plan.sh 6` → `5` no workflow. O (h) reprova: pior faixa 1037 s contra o orçamento de 1035 s.
- M2: `return max(t)` → `return sum(t) / W` no simulador. O (i) reprova: paredes 450,228,228,228.
- M3: fatia da `fixtures` zerada (`fx_w = 0.0`). O (i) reprova: paredes 1000,28,28,28.
- M4: `sorted(lane)`. O (j) reprova: parede 1000 contra 1100.
- M5: chave do guloso pela soma. O (k) reprova: paredes 800,1200.
- M6: melhora local desligada (`range(0)`). O (l) reprova: 5562 s com e sem.
- M7: linha `selftest_selection` apagada da tabela. O (m) reprova.
- M8: `w = live[0]` (sem fila). O (h) reprova (2411 s) e o (j) também.
- M9: `fixtures` sem dividir por worker. O (h) reprova (1545 s).
- M10: `W = 8`. O (i) e o (j) reprovam.

Mutantes EQUIVALENTES (não matáveis no modelo): a `fixtures` movida para o início ou para o fim da fila
simulada. Com a fatia igual em todo worker, a parede não muda. Uma busca exaustiva (W de 2 a 4, até 4
famílias antes e 3 depois, custos 100/300/700, fatias de 100 e 300) não achou nenhuma configuração que os
distinga. Na fila real o desbalanço da fatia entre workers faria diferença, mas ele não está modelado (ver os
limites).

## Limites declarados

- O piso da faixa da `selftest_selection` é estrutural. Pela mediana, o plano de 6 faixas projeta 16,7 min,
  27% abaixo do teto do passo. Com todas as famílias no pior valor medido ao mesmo tempo, são 21,2 min. A
  cura que tira o piso é a fila pegar o caro primeiro, ou partir a `selftest_selection`. As duas mexem no
  `lint-selftest.sh` e ficam fora desta mudança mínima.
- O (h) aprova o N=6 com folga de 35 s (1000 contra 1035). O N=5 reprova por 2 s. É a régua do brief (25%
  abaixo do teto), e não foi afrouxada.
- **A folga real no pior caso medido é de cerca de 1,7 min**, não os 6,3 min que a projeção pela mediana
  sugere. O refutador avaliou o plano de 6 faixas contra 10 runs e achou a pior faixa em até 21,3 min, contra
  23 do passo. O desbalanço da `fixtures` entre os workers de uma faixa (o maior leva 1,05 a 1,45× a média)
  e a variância entre runners não estão modelados: o (h) mede a ordem de grandeza, não a parede de um run.
- **O ganho da 6ª faixa é pequeno.** O plano novo com 5 faixas daria de 16,9 a 20,5 min, e a maior parte da
  melhora vem do simulador, não da faixa a mais. N=6 fica porque N=5 reprova no (h).
- O coletor depende do `gh` e da rede, e não tem caso na bancada. A mediana foi conferida à mão contra a
  análise independente dos mesmos 7 logs.
