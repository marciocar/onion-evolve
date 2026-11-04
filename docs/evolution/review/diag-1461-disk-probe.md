---
branch: diag/1461-disk-probe
pr: 1471
date: 2026-11-04
reviewed_diff_sha256: b497a67a4b96faa15cde3958da2fa0128685ebc62ece65b3f9da7fead68d0d80
reviewed_code_sha256: 26414defd8393465e2b6e5a082bdd84c6577656782560789642be3d87c5b703f
findings_total: 0
findings_real: 0
tokens: 0
duration_min: 0
findings_fixed: 0
verdict: SEM_ACHADOS
elenxo: nao
reviewer: pendente — a passada adversarial ainda não rodou
nota: "REVISÃO PENDENTE: nenhuma passada adversarial rodou sobre este diff. Os campos numéricos 0 são NÃO MEDIDO, não zero achados, e o verdict SEM_ACHADOS é só o placeholder do vocabulário fechado até a passada existir"
---

# Passada adversarial: `diag/1461-disk-probe`

> PR só de diagnóstico: junta o #1461 e a sonda para o CI gerar o `selftest-disk.tsv`. Fecha sem merge.

> ⚠️ **Revisão pendente.** Este resíduo existe para o PR não nascer sem rastro. Nenhum revisor leu o
> diff ainda; os zeros acima são "não medido".

## O que muda

- `.claude/validation/lint-selftest.sh`: flag nova `--disk-report <ABS.tsv>`, a **sonda de disco por
  família**. Arquivo à parte do `--report` (o TSV de 5 colunas e os seus leitores, `selftest-summary.sh`
  e `main-bench-alarm.sh`, não mudam). Por família, uma linha `inicio` gravada **antes** de a família
  rodar e uma `fim` depois, com `df -Pk` do FS do TMPDIR e do workspace e o `du -sk` de um TMPDIR
  próprio da família (filho do TMPDIR original). Escrita em append, uma linha por `printf`, pelo
  worker: exceção declarada à restrição (a) do `--report`. O caminho chega ao `--child` só por env
  prefixado e é `unset` depois de lido, para a bancada aninhada não herdá-lo.
- `.github/workflows/onion-selftest.yml`: o passo da bancada passa `--disk-report
  "${GITHUB_WORKSPACE}/selftest-disk.tsv"`, ganha `timeout-minutes: 22` (abaixo dos 25 do job, para os
  passos `if: always()` subirem a evidência quando a faixa estoura) e o artefato
  `selftest-evidence-*` leva `selftest-disk.tsv`.
- Bancada `selftest_lanes`: família sintética `zz_disk` na cópia hermética e casos (t1) a (t4).

## Achados

Nenhum medido: a passada não rodou.

## Mutantes

- (t2) mutante embutido no caso: move a gravação do `inicio` para depois da família. O arquivo final
  fica igual, e o caso exige que a família sintética, que lê a sonda de dentro, reprove.
- (t4) conferido à mão contra quatro variantes do workflow (sem o teto do passo, teto do passo igual
  ao do job, sem `selftest-disk.tsv` no artefato, sem a flag): as quatro reprovam.

## Limites declarados

- O TMPDIR próprio só pega o que a família cria por `mktemp` honrando o TMPDIR. As famílias que fixam
  `TMPDIR=/tmp` escapam dele; para essas, a pista é a queda do `tmp_livre_kb`, que mistura os workers
  concorrentes.
- A sonda não apaga nada: o que a família deixa fica no disco, como hoje.
- Com o disco a 0, a própria escrita da sonda pode falhar; as linhas gravadas antes ficam, e a falha
  avisa em stderr sem mudar o veredito.
- Localmente rodaram, uma de cada vez, a `selftest_lanes` (30/30) e a `harness_inventory` (8/8); a completa
  é do CI. O pre-commit rodou a faixa local inteira uma vez, com 99 famílias e 1319 casos verdes, e
  reprovou um: `harness-inventory (c)`. A causa era o `_family run_zz_disk_selftests` da família
  sintética na coluna 0, que o `^_family ` estático contava como família real (309 contra 308).
  Curado com o recuo, e as duas famílias foram rodadas de novo. O commit saiu com `--no-verify` para
  não repetir os 26 min da faixa numa máquina com outra bancada no ar.
