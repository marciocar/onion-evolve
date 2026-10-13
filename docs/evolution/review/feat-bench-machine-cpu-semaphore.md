---
title: 'Resíduo — vagas de CPU da máquina para a bancada e nada de bancada completa local'
date: 2026-10-13
branch: feat/bench-machine-cpu-semaphore
reviewed_diff_sha256: pendente
findings_total: 19
findings_real: 17
findings_fixed: 5
tokens: 0
duration_min: 150
verdict: CORRIGIDO
elenxo: sim
nota: >-
  Decisão do maestro de 2026-10-13, selada em D_BANCADA_SEMAFORO_DA_MAQUINA_SEM_COMPLETA_LOCAL (grafo
  merge-process-onion-2026-10). Ele aprovou os itens 1 e 2, sem o nice, com até 5 agentes de execução
  simultâneos. (1) A bancada ganhou VAGAS DA MÁQUINA: N = nproc arquivos de vaga num diretório por uid,
  com flock; cada família pega uma vaga antes de rodar e o fd não desce para os netos. A espera é dita
  na hora e somada no sumário, e o teto estourado é falha nomeada. (2) O pre-commit e o pr-finalize
  passam a faixa local (--local): o failsafe "tudo" não compra mais a completa, e a completa local é
  opt-in (ONION_SELFTEST_FULL=1 ou --full). O nível PR do CI (selftest-pr-selection.sh) não mudou.
  Família nova machine_slots, 9 casos verdes sob LC_ALL=C, e 12 mutantes, cada um reprovando o seu
  caso. Medição antes/depois em E_SEMAFORO_DA_MAQUINA_MEDIDO_2026_10_13.
---

# Resíduo — REGRA 56

## O que mudou

- `.claude/validation/lint-selftest.sh`:
  - **VAGAS DA MÁQUINA** (`_slot_setup`, `_slot_acquire`, `_slot_release`), chamadas em `_family`. O diretório é
    `/run/user/<uid>/onion-selftest-slots` quando existe e é meu; senão `/tmp/onion-selftest-slots-<uid>`. O
    override de teste é `ONION_SELFTEST_SLOT_DIR`. N = nproc, ou `ONION_SELFTEST_MACHINE_SLOTS`. O teto de
    espera é `ONION_SELFTEST_SLOT_WAIT_MAX` (1800 s).
  - O worker manda o trailer `#ONION_SELFTEST_SLOTS`/`SLOTWAITER`, e o pai soma. O sumário ganhou a linha `Vagas`.
  - `--local` e `--full`: a faixa local (`_selftest_local_families`, `_selftest_touched_blocks`) com o núcleo local
    (`selftest_lanes`, `selftest_selection`, `two_tier_bench`, `machine_slots`, `shell_pipefail_robustness`).
  - A família `machine_slots`.
- `.githooks/pre-commit`: a bancada roda com `--affected-staged --local --jobs auto` (o checkpoint também usa
  `--local`), e a mensagem diz que a completa é do CI.
- `ops/pr-finalize.sh`: o pré-voo traduz `ONION_SELFTEST_FULL=1` para a completa (o `env -i` a apagaria). O contrato
  agora declara que o motor nunca roda a completa.
- Doutrina: §0 de `docs/knowledge-base/concepts/onion-drive-doctrine.md` e um adendo em
  `docs/analysis/bancada-faixas-e-mapa-2026-09.md`.
- Grafo: o selo do maestro (`kg-decide-seal.sh --new … --other`) e o nó de evidência, com o teto 68→70 declarado.

## O que cada classe de diff roda agora, no pre-commit e no pr-finalize

| Diff | Antes | Agora |
|---|---|---|
| arquivo mapeado (ex. `ops/merge-serial.sh`) | as famílias dele | igual |
| `docs/` sem família | só o núcleo do mapa | igual |
| `.github/workflows/*`, `.githooks/*`, `lint-artifacts.sh`, `hooks/lib/*`, `manifest.tsv` (failsafe de infra) | TODAS | as famílias que citam o arquivo + o núcleo local (ex. workflow ⇒ 25, hook ⇒ 10, lint ⇒ 49 com `fixtures`) |
| `ops/testing/*` | as famílias que citam o arquivo | idem + o núcleo local |
| arquivo do domínio que nenhuma família cita | TODAS | o núcleo local (6 famílias) |
| `lint-selftest.sh` com linha fora de família | TODAS | os blocos mudados + quem lê a bancada + o núcleo local |
| qualquer um, com `ONION_SELFTEST_FULL=1` ou `--full` | — | TODAS, declarada como pedida |

O pré-voo do pr-finalize (sob checkpoint) segue com as famílias alteradas (`preflight-families.sh`), e nunca rodou a
completa. O caminho do pr-finalize que comprava a completa era o hook do commit de conteúdo, que agora é a faixa local.
⚠️ A premissa "o pr-finalize roda `--affected-range`" não vale: ele nunca rodou. Fica declarado aqui em vez de
inventar um terceiro ponto de bancada.

## Casos e mutantes

Família `machine_slots`, sob `LC_ALL=C`: 9 de 9 verdes, também com a máquina na carga 16.

| Mutante (`ops/mutate-and-restore.sh`) | Reprovou |
|---|---|
| M1 `flock -n` vira `true` (sem exclusão) | (a) (c) (d) |
| M2 sem `{SLOT_FD}>&-` na chamada da família (o fd desce para os netos) | (b) |
| M3 a espera não é somada | (d) |
| M3b o teto estourado não falha | (d) |
| M4 a faixa local desligada | (e) (f) |
| M5 o hook sem `--local` | (e) |
| M6 o opt-in `ONION_SELFTEST_FULL` ignorado | (f) |
| M7 o pr-finalize ignora `ONION_SELFTEST_FULL` | (g) |
| M7b o pré-voo sem `--families` (completa por padrão) | (g) |
| M8 a bancada aninhada pede vaga própria | (d) (d2) |
| M9 o diretório gravável por outros é aceito | (d2) |
| M10 o diretório apagado no meio não é recriado | (d3) |

Também rodei a faixa local do diff de código (`lint-selftest.sh`, `.githooks/pre-commit`, `ops/pr-finalize.sh`), como
o pre-commit a roda: 17 famílias em 8 workers, 177 passaram e 0 falharam, em 945 s com a máquina na carga 21. Antes
das curas 4 e 5 abaixo, essa mesma faixa reprovava 5 casos. O commit saiu como checkpoint declarado (`--no-verify`):
a faixa rodou à parte, e o lint do commit é do pr-finalize.

## Passada adversarial (o default é reprovar)

Curados no PR:
1. **O diretório de vagas sumia no meio** (limpeza de `/tmp`, ou um logout que leva `/run/user`). Toda família
   seguinte esperava o teto inteiro por um arquivo que ninguém recria. Agora a vaga recria o diretório, ou desliga o
   semáforo e declara. Caso (d3), mutante M10.
2. **O caso (d) era flaky sob carga 17.** Com o relógio fixo, o caso media o setup da bancada e não a espera. Agora o
   holder solta só depois que a que espera DISSE ⏳.
3. **A espera só aparecia no sumário.** Agora ela também sai na hora (`⏳ vagas da máquina: <família> espera vaga`).
4. **As famílias sintéticas na coluna 0** do heredoc foram lidas como famílias REAIS por `--list`, `--map` e pelo
   harness, com 5 reprovações medidas (fantasma, núcleo sem razão, igualdade do inventário). Agora vêm indentadas.
5. **`_ms_kill` com `&&` no fim, sob `set -e`,** matava a família quando o processo já tinha saído (o abort foi medido).

Declarados como teto, sem cura neste PR:
6. **O setup do worker roda FORA da vaga.** O tar de `.claude`+`docs` e o `inventory.sh` ×5 acontecem antes da
   primeira família. Cinco bancadas com `--jobs auto` ainda pagam uns 40 setups simultâneos (~2 s de CPU cada). O
   semáforo governa as famílias, não o arranque.
7. **Uma bancada aninhada que perde a variável** (`env -i` dentro de uma família) pediria vaga no mesmo diretório. Com
   as N vagas tomadas pelo pai, ela espera o teto e FALHA nomeada. Não trava para sempre. Hoje nenhuma família faz isso:
   o (g) usa uma bancada de mentira.
8. **Com o diretório apagado no meio,** quem segura vaga do inode antigo não exclui as novas. Na janela pode haver até 2N.
9. **O `flock` não é fila justa.** Não há FIFO, e a inanição fica limitada pelo teto.
10. **N vale por invocação.** Uma bancada com N=2 disputa só `slot.0` e `slot.1`, enquanto as outras usam o nproc.
11. **O semáforo é por USUÁRIO.** A conta `granaai` tem diretório próprio e não entra na conta.
12. **Dono alheio do diretório não foi testado,** porque exigiria outra conta. Só o modo 0777 foi exercido (d2). Link e
    dono alheio desligam o semáforo pelo mesmo predicado, que é lido mas não exercido.
13. **O CI é idêntico por argumento.** Uma bancada por runner, com `--jobs auto` = nproc = N e workers ≤ N, logo
    ninguém espera. A prova executável é a linha `Vagas … espera somada 0.0s` no log do CI deste PR. Não rodei no runner
    antes de abrir.
14. **Com `lint-artifacts.sh` tocado, a faixa local roda 49 famílias,** com `fixtures`, a mais pesada. É "quem cita",
    como foi pedido. Custa caro, mas não é a completa.
15. **A recusa no incerto relaxou só na faixa local.** Range ilegível ou nada staged roda só o núcleo local, e a
    completa fica com o CI. O nível PR segue recusando no incerto (two_tier_bench (b), (c), (e), (f) intactos).
16. **A medição não isola o ganho.** Os outros agentes rodavam código da main, sem semáforo, e a carga deles mudou entre
    as rodadas (15,8 no início do antes, 22,5 no do depois). Na rodada "antes", uma bancada da main teve 1 falha sob
    carga (`pre-push: ponto de teste vazou`), que não se repetiu. Fica registrada como observação de flaky da main sob
    concorrência, não como defeito deste PR.
17. **A premissa do pedido sobre o pr-finalize** ("roda `--affected-range`") estava errada: ver acima.

Refutados por medição:
18. **"Deadlock com flock aninhado".** O worker segura no máximo uma vaga e a solta antes da próxima família. A bancada
    aninhada no mesmo diretório herda a vaga. O (d2) passou, e `selftest_lanes`, que invoca a bancada aninhada, passou
    verde com 5 workers.
19. **"A família que testa o semáforo trava esperando a vaga que ela mesma segura".** Ela usa diretório próprio: os
    casos (a) a (d3) rodam DENTRO de uma família que segura uma vaga real, e passaram.

## Medição (passo 4)

8 vCPUs. No início, a carga de outros agentes era de 15,8 (antes) e 22,5 (depois), com pressão de CPU avg10 de 57 a
62%. Rodei duas bancadas das mesmas 27 famílias (de 6 a 25 s cada no runner), com `--jobs auto`, em paralelo.

| | antes (main, sem semáforo) | depois (8 vagas) |
|---|---|---|
| parede b1 / b2 | 272 s / 271 s | 307 s / 350 s |
| carga 1 min, média / pico | 29,8 / 36,1 | 25,7 / 28,3 |
| pressão CPU avg10, média / pico | 91,3% / 96,9% | 87,4% / 94,0% |
| falhas | 1 (flaky, pre-push) | 0 |
| espera declarada (soma dos workers) | — | 924 s / 1009 s |

O semáforo troca a sobreposição por fila declarada. A carga cai 4 em média e 8 no pico. A parede de cada bancada sobe,
porque as duas dividem 8 vagas em vez de pôr 16 processos em 8 núcleos. O ganho maior da decisão é o item 2, sem
completa local, e esta medição não o exercita.
