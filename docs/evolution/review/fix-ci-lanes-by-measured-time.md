---
branch: fix/ci-lanes-by-measured-time
pr: pendente
date: 2026-11-12
reviewed_diff_sha256: pendente
findings_total: 3
findings_real: 3
findings_blocking: 0
tokens: 0
duration_min: 0
findings_fixed: 3
verdict: FIXED
elenxo: false
reviewer: autor (passada própria; o brief da SAC-423 proibiu lançar agentes, então não houve refutador opus)
nota: "tokens e duração não medidos. Sem refutador externo: a passada adversarial ainda está pendente antes do PR (preâmbulo do agente de execução)."
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
  parede, depois a soma dos quadrados). O simulador acertou as 35 faixas de 7 runs completos com erro de
  −3% a +3%. `--project` imprime a projeção por faixa.
- **Tabela re-medida** (`ops/testing/selftest-family-times.tsv`): é a mediana de 7 runs completos da main de
  2026-11-12. A linha `fixtures` passa a ser o TOTAL do run. O coletor (`collect-family-times.sh`) aceita
  vários run-ids e tira a mediana.
- **6 faixas** no workflow. O piso da faixa da `selftest_selection` é a fatia da `fixtures` mais a própria
  família (~11–16 min sozinha). Só mais faixas baixam esse piso.
- **Caso (h)** passa a ler a projeção do próprio plano contra 75% do teto do PASSO. **Caso (i) novo**: a
  projeção é a parede da fila, não a soma.

## Achados

1. (real, curado) O caso (h) aprovava um plano que estourava na main: `soma/W + fixtures/(N·W) + arranque`
   não vê a ordem da fila. Ele agora usa o `--project` do plano, e a régua e o plano são o mesmo modelo.
2. (real, curado) A 1ª versão do guloso pela parede deixava faixas de 9 e de 17 min no mesmo plano. O
   desempate pela menor parede não espalhava a folga. A melhora local por (pior, soma dos quadrados) reduziu
   a soma das paredes de 76,4 para 74,6 min. O pior continua no piso da `selftest_selection`.
3. (real, curado) Durante a medição, um `git reset --soft HEAD~1` encadeado por `;` depois de um commit que
   não aconteceu tirou um commit da base da worktree. O HEAD foi restaurado para `e4a45fc16` (o da
   origin/main buscada) com a árvore intacta. O `stash` próprio usado no passo foi descartado.

## Mutantes

Todos plantados por `ops/mutate-and-restore.sh`, com `LC_ALL=C`, contra `--families shard_plan`. Os três
morreram (rc 1):

- M1: `selftest-shard-plan.sh 6` → `5` no workflow. O (h) reprova: pior faixa 1037 s contra o orçamento de 1035 s.
- M2: `return max(t)` → `return sum(t) / W` no simulador. O (i) reprova: paredes 450,228,228,228.
- M3: fatia da `fixtures` zerada (`fx_w = 0.0`). O (i) reprova: paredes 1000,28,28,28.

## Limites declarados

- O piso da faixa da `selftest_selection` é estrutural. Pela mediana, o plano de 6 faixas projeta 16,7 min,
  27% abaixo do teto do passo. Com todas as famílias no pior valor medido ao mesmo tempo, são 21,2 min. A
  cura que tira o piso é a fila pegar o caro primeiro, ou partir a `selftest_selection`. As duas mexem no
  `lint-selftest.sh` e ficam fora desta mudança mínima.
- O (h) aprova o N=6 com folga de 35 s (1000 contra 1035). O N=5 reprova por 2 s. É a régua do brief (25%
  abaixo do teto), e não foi afrouxada.
- O coletor depende do `gh` e da rede, e não tem caso na bancada. A mediana foi conferida à mão contra a
  análise independente dos mesmos 7 logs.
- Não há mutante que troque o plano pelo LPT da soma mantendo o simulador. Pela mediana, esse plano daria
  17,0 min com N=6 e passaria no (h).
