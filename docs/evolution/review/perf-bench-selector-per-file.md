---
title: 'Resíduo — seletor por arquivo, arranque compartilhado e bloco da bancada no nível PR'
date: 2026-10-13
branch: perf/bench-selector-per-file
reviewed_diff_sha256: 81997f4d196f8981d6a8222fc907f6915b61eb53fdb46a86b348178b5b3a76d4
reviewed_code_sha256: 979645a6f4fb843540da45ee3568730647690efa104ef0c0ff2eb709b23390f3
findings_total: 9
findings_real: 8
findings_fixed: 6
tokens: 0
duration_min: 240
verdict: CORRIGIDO
elenxo: sim
nota: >-
  Duas decisões do maestro de 2026-10-13. A primeira, «1+2 juntos, medido», pediu (1) o seletor por ARQUIVO e
  (2) o ARRANQUE compartilhado. A segunda, «Blocos mudados + núcleo», selada em D_CI_PR_BLOCOS_MUDADOS_DA_BANCADA
  no grafo merge-process-onion-2026-10, ampliou o escopo no mesmo PR: no nível PR do CI, a bancada modificada vai à
  regra do BLOCO, e o MOTOR (fora dos marcadores ONION-BENCH) segue comprando a completa. Também fecha o falso
  negativo do #1068 (kg_fixture_paths não rodava quando mudava migrate-seed-graph.sh). A medição antes/depois
  está em E_SELETOR_POR_ARQUIVO_E_ARRANQUE_MEDIDO_2026_10_13 e foi feita com o medidor versionado
  ops/testing/selection-replay.sh sobre os mesmos 50 PRs mergeados.
---

# Resíduo — REGRA 56 (PR aberto carrega RESÍDUO da passada adversarial)

## O que mudou

- `ops/testing/selection-replay.sh` (novo): replay do seletor ATUAL sobre PRs já mergeados (`gh pr list` ou
  `--ranges`). Mede a distribuição de famílias no nível PR do CI (`#REPLAY`), a parte do diff que o mapa decide
  (`#REPLAY_SEM_INFRA`), a CPU estimada pela soma de `selftest-family-times.tsv` (`#REPLAY_SEGUNDOS_CPU`) e o
  arranque do worker e do serial (`#STARTUP_WORKER`, `#STARTUP_SERIAL`).
- `.claude/validation/lint-selftest.sh`:
  - **Mapa por arquivo em docs/** (`_selftest_family_map`):
    - um diretório de docs/ só NOMEADO numa mensagem, num teste ou num `mkdir` sai `weak-named` e cobre só os
      arquivos que moram diretamente nele;
    - o rótulo de `case` (`docs/analysis/*) return 0`) deixa de ser leitura;
    - o glob de nome solto (`*.md`) vale debaixo do diretório da MESMA linha, com a variável resolvida pelas
      atribuições dela até 2 níveis, e a que vem de parâmetro (`d="$1"`) só conta para a família que entrega a
      raiz viva solta;
    - docs/ não compacta 3 arquivos em diretório, e a entrada mais funda não é engolida pelo ancestral.
  - **Classe por arquivo no seletor** (`_selftest_affected_families`, passo 4): prosa, grafo e resíduo de docs/.
    O resíduo tem destino declarado: quem nomeia `docs/evolution/review/`, o forte e o núcleo. Os outros tipos de
    docs/ e todo o domínio da bancada seguem a regra antiga.
  - **População varrida pelo corpo** (`_scan_body`): `grep -rl PADRÃO dir`, `git grep -l` e `git ls-files 'dir'`
    no corpo de uma família viram cobertura fraca pelos arquivos que casam. Um caminho literal rastreado no corpo
    também. Isso fecha o #1068.
  - **Arranque compartilhado**:
    - `_snapshot_create`, `_snapshot_key` e `_inventory_env`: o pai tira o retrato uma vez, num tar read-only, e
      o worker extrai a cópia dele;
    - o inventário é lido UMA vez por bancada (eram cinco `--env` por processo), com cache por uid indexado pela
      sha256 do retrato;
    - `--list` não paga arranque;
    - o worker manda o trailer `#ONION_SELFTEST_STARTUP` e o sumário ganhou a linha `Arranque`.
  - **Fronteira do motor**: os marcadores `# ═══ ONION-BENCH: FIM DO MOTOR` e `# ═══ ONION-BENCH: INÍCIO DO
    SUMÁRIO`.
    - Linha de código fora deles ⇒ a completa, com o motivo "no MOTOR".
    - Marcador ausente, duplicado ou fora de ordem, ou família fora da região ⇒ a completa.
    - `ONION_SELFTEST_REPLAY_SYNTH_BOUNDS=1` existe SÓ para o medidor: sintetiza a fronteira numa bancada
      histórica que ainda não tinha os marcadores.
  - **Regra do bloco em modo `range:`**: a regra lê a merge-base e a ponta do PR. Com bloco mudado, o nível PR
    acrescenta `SELFTEST_BENCH_CORE`, que é o núcleo local mais `selector_per_file` e `shared_startup`. A bancada
    renomeada, criada ou apagada segue comprando tudo.
  - **Fail-closed do leitor do bloco**: com python rc≠0, a seleção vai a tudo. Antes, a saída vazia estreitava.
  - Famílias novas `selector_per_file` (a–k, h2) e `shared_startup` (a–f). Casos ajustados em
    `selftest_selection` (c2, c3, c-setup) e `two_tier_bench` (c, f).
- `ops/testing/selftest-pr-selection.sh`: `lint-selftest.sh` saiu da lista que compra a completa por política.
  Workflows e `ops/testing/*` continuam nela.

## Medição (os mesmos 50 PRs, #1031–#1080)

O medidor é `ops/testing/selection-replay.sh --ranges <os 50> --startup --startup-runs 5`. O ANTES roda a bancada
da origin/main 5736c019 (a main em que o #1080 entrou), numa worktree separada. Os dois rodaram em sequência,
com carga 1,7–3,3.

| | antes | depois |
|---|---|---|
| nível PR do CI — p50 / p90 / máx / mín (famílias de 255–258) | 255 / 255 / 255 / 78 | 137 / 258 / 258 / 68 |
| PRs na completa | 38 de 50 | 23 de 50 |
| só os seletivos — p50 / p90 / máx | 113 / 114 / 115 (12 PRs) | 107 / 135 / 140 (27 PRs) |
| a parte do diff que o mapa decide (sem bancada/workflow/ops/testing) — p50 | 131 | 121 |
| CPU de bancada estimada por PR (soma de `selftest-family-times.tsv`) — p50 | 4908 s | 1785 s |
| arranque do worker (mediana de 5) | 1,81 s | 0,46 s |
| arranque serial com cache vazio (mediana de 5) | 1,93 s | 0,98 s |

Por que eram 38 na completa: 35 tocavam a própria bancada, 2 um workflow e 1 tinha arquivo não citado. A
hipótese de partida (o PR típico cai em ~100 famílias pelo mapa de docs/) só valia para os 12 seletivos. O PR
típico caía na COMPLETA, pela política "quem muda o juiz roda tudo".

Os 23 que seguem na completa: 8 por infra do CI (workflow, `ops/testing`), 6 por infra da bancada
(`lint-artifacts.sh`, `hooks/lib`), 7 por arquivo do domínio não citado (failsafe) e 1 por motor da bancada
mudado. Mais 1 por fronteira de bloco ambígua.

A meta indicativa de 10–30 famílias NÃO foi atingida. O PR seletivo típico fica em ~107: o núcleo da bancada é
somado sempre que ela muda, e o grafo e a prosa seguem largos (limitações abaixo).

Caça a falso negativo: o CI dos 50 PRs tem 10 runs da bancada que reprovaram, com 11 eventos de família. Cada
(PR, sha, família) foi rodado de novo pela política NOVA no diff `base...sha`, e a família reprovada foi
selecionada em todos (11/11, 5 pela completa). O único falso negativo do mapa, o `kg_fixture_paths` do #1068,
era pré-existente e está fechado (caso (h)).

## Mutantes (por `ops/mutate-and-restore.sh`; cada um reprova o seu caso)

| id | mutação | caso que reprova |
|---|---|---|
| M1 | resíduo sem destino declarado (regra genérica) | selector-per-file (a) |
| M2 | rótulo de `case` volta a ser leitura | selector-per-file (c) |
| M4 | todo diretório nomeado vira varrido | selector-per-file (f) |
| M6 | classe por arquivo desligada | selector-per-file (a) |
| M7 | glob `*.md` sem restrição de diretório | selector-per-file (c) |
| S1 | retrato gravável | shared-startup (a) |
| S2 | chave do cache fixa | shared-startup (b) |
| S3 | retrato herdado fora de `--child` | shared-startup (e) |
| S4 | pai não passa retrato/inventário | shared-startup (d) |
| S5 | cache gravável por outros aceito | shared-startup (c) |
| S6 | SSOT lida da chave errada | shared-startup (f) |
| B2 | linha do motor não acusa MOTOR | selector-per-file (j) |
| B3b | fronteira ausente aceita | selector-per-file (k) |
| B4 | bancada modificada volta ao failsafe do range | selector-per-file (i)(j)(k) |
| B5 | política volta a mandar a bancada à completa | selector-per-file (i)(j)(k) |
| D1 | população varrida pelo corpo desligada | selector-per-file (h) |
| F1 | leitor do bloco quebrado estreita | selector-per-file (h2) |

Sobreviventes declarados:
- **M3** (docs/ volta a compactar) é EQUIVALENTE hoje: medido em 4 caminhos (resíduo, prosa de docs/analysis,
  grafo, KB), a seleção é idêntica com e sem a mutação. A exceção fica porque protege o resíduo de um diretório
  compactado (3 resíduos expandidos por glob virariam `docs/evolution/review/` fraco).
- **B1** (o núcleo da bancada não é somado no nível PR) é EQUIVALENTE hoje: as 7 famílias do núcleo já entram
  como "leem a bancada como dado". A soma fica como garantia declarada para quando uma delas deixar de citar a
  bancada.

## Passada adversarial (Elenxo)

1. **Família que lê um diretório por glob em vez de caminho literal fica fora do mapa por arquivo?** REAL e
   CURADO em parte. O glob no SCRIPT (`find "$KB_DIR" -name '*.md'`) é resolvido pelas atribuições. O glob sem
   resolução (`"${SRC}/${c}"/*.md`, laço) vale o repo inteiro, e por isso a prosa ainda seleciona ~50. O glob no
   CORPO da família (`grep -rl`, `git ls-files`) agora entra (`_scan_body`). FICA: o helper de topo que a família
   chama não é lido. É a classe já registrada no comentário do failsafe (`members-validate.sh` por helper da
   `fixtures`). Por isso o failsafe do domínio continua fechado.
2. **Família que gera fixture em docs/?** As famílias que escrevem fixture na árvore viva usam `__*__`, que o
   retrato exclui. O retrato agora é UM por bancada, então a fixture transitória de outro caso aparece igual para
   todos os workers, ou para nenhum. Medido: o isolamento entre workers continua (shared-startup (a)).
3. **Regra que varre todo `.md`?** Entra pela prosa, como decidido: o `*.md` sem diretório resolvido vale o repo
   inteiro. No RESÍDUO ela fica de fora POR DECISÃO: a varredura de prosa viva do resíduo é do job de lint do CI,
   sobre a árvore real, e não de família da bancada.
4. **Leitor do bloco que quebra estreitava.** REAL e CURADO. Achado ao montar o caso c3: o python do bloco
   quebrou e a saída vazia foi lida como "nenhuma família". Agora rc≠0 ⇒ tudo (h2, F1).
5. **Inserir família sintética procurando o marcador por `str.index`** casava a cópia do marcador DENTRO do
   código python do leitor e corrompia a cópia. REAL e CURADO: a busca é por início de linha.
6. **A rede do nível PR.** Com a bancada fatiada no PR, uma quebra que só a completa vê chega à main e é pega no
   push. Janela declarada: do merge até o fim da bancada completa no push, ~15–25 min no runner, com o alarme
   (main-bench-alarm.sh, issue) e o PR de revert. Foi o que aconteceu no #1086, fechado pelo #1088.
7. **Mapa maior e seletor mais lento.** O `--map` vai de 11,7 mil para ~81 mil linhas e de 3,8 s para 4,6 s.
   O `--dry-run` de um arquivo leva ~11 s porque o mapa é calculado 2× (pré-existente). Não corrigido.
8. **40 scripts de .claude/ e ops/ sem citação forte** seguem indo à completa (fail-closed). 14 deles ganharam
   cobertura fraca pelo corpo das famílias que os varrem. Nenhum foi afrouxado. A lista está no nó de evidência.
9. **Falso positivo do medidor.** A coluna `segundos_cpu` soma o tempo por família do runner. Família sem tempo
   medido conta 0, então a soma SUBestima. Declarado na saída.

## Limitações

- A cura 1 sozinha rende pouco no CI: o grafo e a prosa seguem largos (~50–70 famílias por arquivo), porque o
  fecho script→script põe ~13 famílias em fechos de ~158 scripts e porque os globs não resolvidos valem o repo.
- O semáforo de vagas segue fora do arranque (o retrato é feito pelo pai antes das vagas).
- O cache do inventário é por uid e por retrato exato (mtime incluso), então só acerta em re-rodada da mesma árvore.
