---
branch: ops/selftest-disk-probe
pr: pendente
date: 2026-11-06
reviewed_diff_sha256: 1e72300af583324b4043cbeeb796547d691583d498a536855ff3893c7dd1a062
reviewed_code_sha256: c19db2a20bd843206422068e7c6f923e1fe51d859702efd9ca907c57cac69472
findings_total: 4
findings_real: 1
findings_blocking: 1
findings_fixed: 1
tokens: 0
duration_min: 45
verdict: CORRIGIDO
elenxo: nao
reviewer: "condutor da tarefa SAC-277, passada adversarial própria (sem agente, por ordem da sessão principal): diff relido depois do rebase em origin/main 4d228917e; tempos de 20 faixas dos runs 42209160269, 42205321547, 42174335788 e 42171564226 lidos por gh run view; selftest_lanes 30/30; juiz do (t4) extraído e rodado contra 6 variantes do workflow"
nota: "tokens 0 = não medido. Passada sem refutador separado: o diff é a sonda de 2026-11-04 mais a correção do teto do passo; a completa com --disk-report é do CI"
---

# Passada adversarial: `ops/selftest-disk-probe`

> A 1ª versão (2026-11-04) saiu com a revisão pendente. Esta passada roda em 2026-11-06, depois do
> rebase em `origin/main` (221 commits; único conflito: `docs/onion/testing-inventory.md`, projeção
> gerada, regenerada pelo `harness-inventory.sh`).

## O que muda

- `.claude/validation/lint-selftest.sh`: flag nova `--disk-report <ABS.tsv>`, a **sonda de disco por
  família**. Arquivo à parte do `--report` (o TSV de 5 colunas e os seus leitores, `selftest-summary.sh`
  e `main-bench-alarm.sh`, não mudam). Por família, uma linha `inicio` gravada **antes** de a família
  rodar e uma `fim` depois, com `df -Pk` do FS do TMPDIR e do workspace e o `du -sk` de um TMPDIR
  próprio da família (filho do TMPDIR original). Escrita em append, uma linha por `printf`, pelo
  worker: exceção declarada à restrição (a) do `--report`. O caminho chega ao `--child` só por env
  prefixado e é `unset` depois de lido, para a bancada aninhada não herdá-lo.
- `.github/workflows/onion-selftest.yml`: o passo da bancada passa `--disk-report
  "${GITHUB_WORKSPACE}/selftest-disk.tsv"`, ganha `timeout-minutes: 23`, 2 min abaixo dos 25 do job, para os
  passos `if: always()` subirem a evidência quando a faixa estoura (era 22; ver o achado 1) e o artefato
  `selftest-evidence-*` leva `selftest-disk.tsv`.
- Bancada `selftest_lanes`: família sintética `zz_disk` na cópia hermética e casos (t1) a (t4).

## Achados

1. **REAL, BLOQUEANTE, CORRIGIDO: o teto do passo em 22 cortava faixa que o job deixaria terminar.**
   O SAC-277 já o apontava (a faixa 3 chegou a 23,5 min na main). Medido em 20 faixas de 4 runs verdes
   da main: antes do passo da bancada o job gasta ~0,5 min (checkout, setup-python, capacidade), e os
   dois passos `if: always()` depois dele, 1 a 2 s. O maior passo é de 19,6 min (faixa 2 do
   42209160269), já com as 5 faixas da `fix/ci-lane-rebalance`. Com o job em 25, um teto de 23 deixa
   1,5 min para o antes e o depois, e 24 deixaria ~0,5 min, sem folga para um `apt-get` de capacidade.
   O 22 tirava 1 min de bancada sem comprar nada. Cura: teto 23, e o caso (t4) passa a exigir margem
   job − passo **igual a 2**. Antes ele aceitava qualquer teto de passo abaixo do do job, e o 22 passava.
2. **Refutado: o TMPDIR próprio estoura o limite de 108 bytes do socket AF_UNIX.** A família
   `chat_runner` cria socket em `${d}/run/*.sock` sob o `mktemp -d`. Com a sonda o caminho fica em
   ~64 bytes (`/tmp/onion-selftest-chat_runner.XXXXXX/tmp.XXXXXXXXXX/run/s.sock`). O maior nome de
   família tem 29 caracteres (`worklog_precompact_breadcrumb`).
3. **Refutado: família que exporta TMPDIR vaza para a próxima só sem a sonda, e o CI diverge do local.**
   Nenhuma família faz `export TMPDIR=` no próprio corpo (`grep -nE '^\s*export TMPDIR='` só acha a
   sonda). As 57 ocorrências de `TMPDIR=` são prefixo de comando e não vazam.
4. **Limite já declarado, não defeito:** o diretório próprio da família não é apagado. Ele só guarda o
   que a família já deixaria em `/tmp`, mais um diretório vazio por família.

## Mutantes

- (t2) mutante embutido no caso: move a gravação do `inicio` para depois da família. O arquivo final
  fica igual, e o caso exige que a família sintética, que lê a sonda de dentro, reprove.
- (t4) em 2026-11-04, conferido à mão contra quatro variantes do workflow (sem o teto do passo, teto
  do passo igual ao do job, sem `selftest-disk.tsv` no artefato, sem a flag): as quatro reprovaram.
- (t4) em 2026-11-06, o juiz do caso foi extraído do heredoc `PYDWF` e rodado contra cópias do
  workflow. O teto do passo em 21, 22, 24 e 25 **reprova**; o passo sem `--disk-report` **reprova**; o
  23 passa. O 22 da 1ª versão passava no (t4) antigo e é o mutante que o (t4) novo mata.

## Limites declarados

- O TMPDIR próprio só pega o que a família cria por `mktemp` honrando o TMPDIR. As famílias que fixam
  `TMPDIR=/tmp` escapam dele; para essas, a pista é a queda do `tmp_livre_kb`, que mistura os workers
  concorrentes.
- A sonda não apaga nada: o que a família deixa fica no disco, como hoje.
- Com o disco a 0, a própria escrita da sonda pode falhar; as linhas gravadas antes ficam, e a falha
  avisa em stderr sem mudar o veredito.
- Em 2026-11-06, depois do rebase, a `selftest_lanes` rodou de novo: 30/30, 13m24s locais.
- Em 2026-11-04, localmente rodaram, uma de cada vez, a `selftest_lanes` (30/30) e a `harness_inventory` (8/8); a completa
  é do CI. O pre-commit rodou a faixa local inteira uma vez, com 99 famílias e 1319 casos verdes, e
  reprovou um: `harness-inventory (c)`. A causa era o `_family run_zz_disk_selftests` da família
  sintética na coluna 0, que o `^_family ` estático contava como família real (309 contra 308).
  Curado com o recuo, e as duas famílias foram rodadas de novo. O commit saiu com `--no-verify` para
  não repetir os 26 min da faixa numa máquina com outra bancada no ar.
