---
title: "Revisão — o (h) da selftest_lanes caía no CI porque o mkdir do uutils não é atômico; a fila reivindica pelo O_EXCL do bash e o pai acusa dupla execução"
date: 2026-10-20
branch: fix/selftest-lanes-h-flaky
reviewer: "duas passadas adversariais com lentes distintas (maquinaria/shell · o artefato mente?), cada uma medindo em scratch próprio; todo achado re-medido pelo condutor antes de entrar"
reviewed_diff_sha256: pendente
findings_total: 10
findings_real: 8
verdict: APROVADO
tokens: 245000
duration_min: 23
---

# Resíduo — REGRA 56 (PR aberto carrega RESÍDUO da passada adversarial)

## A causa, medida antes da cura

- O runner `ubuntu-26.04` (imagem 20261018.168.1) traz o **uutils 0.10.0** no lugar do coreutils GNU.
  O `mkdir` dele confere a existência e só depois cria: dois processos no mesmo nome recebem rc=0
  (4% a 48% das corridas em 2 núcleos, conforme o harness; GNU 0 em todos).
- A fila da faixa paralela reivindicava família com `mkdir claimed/<família>`: dois workers rodavam a
  mesma família, o pai somava 3 ou 4 com exit 0, e o (h) reprovava por "Passaram ≠ 2".
- Reprodução do (h) com o **binário real** do uutils extraído da imagem, `taskset -c 0,1`,
  `LC_ALL=C`, `ONION_SELFTEST_STRICT=1`, com e sem dois laços de CPU nos mesmos núcleos:

| árvore | mkdir | falhas do (h) |
|---|---|---|
| main (antes) | GNU | 0/240 |
| main (antes) | uutils | 14/180 |
| branch do #1238 (antes) | GNU | 0/120 |
| branch do #1238 (antes) | uutils | 5/120 |
| esta branch (cura) | uutils | **0/300** |
| mutante (trava devolvida ao mkdir) | uutils | 8/120 |

- A hipótese do coordenador (o (h) depende de algo que muda quando o PR toca a bancada) foi medida e
  **não** é a causa: o tree do #1238 falha na mesma taxa do main. A correlação é de SELEÇÃO — a
  selftest_lanes entra no nível PR pelo núcleo da bancada quando o diff toca a bancada.

## Achados da passada e destino

1. **HARD (o artefato mente) — o nó dava o mecanismo de seleção errado** ("failsafe do --affected";
   "nos demais ela nem roda"). O job `plano` mostra o núcleo da bancada do nível PR, e fora de PR a
   bancada roda inteira. **Curado** na narrative.
2. **HARD (as duas lentes) — o (h2) aprovava um mutante que morria antes do sumário** (só checava
   "não deu 2"). **Curado:** casamento positivo `Passaram ≥ 3` e rc lido.
3. **SOFT — o "3" não estava na evidência do CI**: o `cut -c1-140` engoliu o número. **Curado:** a
   mensagem do (h) põe a soma primeiro; o nó atribui o 3/4 à reprodução.
4. **SOFT — "480/1000" não se reproduz no harness do refutador** (37–77/1000). **Curado:** o nó, o
   comentário e o commit declaram a faixa por harness.
5. **SOFT — "11 linhas de caso" eram 10 casos + a linha de tempo.** **Curado.**
6. **SOFT — "atomicidade nunca se pede a utilitário de userland" contradizia o `flock` das vagas.**
   **Curado:** a regra fala de primitiva do kernel que o binário só pode embrulhar se for fino.
7. **SOFT — comentário antigo dizia "mkdir atômico"** sete linhas acima da cura. **Curado.**
8. **SOFT (defesa em profundidade) — o pai não acusava família rodada duas vezes**; a duplicação da
   vendor_manifest no run do #1238 passou com rc=0. **Curado como mecanismo:** o pai conta as linhas
   de família por nome (fora `fixtures`, fatiada de propósito) e falha nomeando "rodou N vezes". O
   (h2) exige que o mutante seja acusado assim (exit 1).
9. **NADA — barreira do imitador de 5 s podia dar falso vermelho**: subida para 30 s (o SUT nunca a toca).
10. **NADA — noclobber não é O_EXCL em caminho não-regular (FIFO, /dev/null)**: inalcançável, a fila
    vive num `mktemp -d` privado. Strace confirma `O_CREAT|O_EXCL` no bash 5.2.

## Fora de escopo, declarado

- Outras travas da casa: o refutador varreu `.claude/` e `ops/`; todas usam `flock` (util-linux, não
  trocado pelo uutils), `os.open(O_EXCL)`, `fcntl.flock` ou `set -C`. Nenhuma outra por `mkdir`.

## Gate

família selftest_lanes 26/26 (GNU e uutils no PATH) · radar exit 0 · kg-contract-check conforme ·
kg-machine-path 0 acusações · lint 0 HARD pelo `ops/pr-finalize.sh`.
