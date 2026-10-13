---
title: 'Resíduo — passo D do processo de merge: bancada em dois níveis sem fila, check estável selftest-gate e ruleset preparado'
date: 2026-10-13
branch: feat/merge-process-step-d-two-tier-bench
reviewed_diff_sha256: cba3bc080fdb353077e2c3584275faf3499dffaa96774495c63468be601d2f53
reviewed_code_sha256: ef55926aa4da026e97d50bb898c7125e2711cbfeea254291523b73a2459c6795
findings_total: 13
findings_real: 12
findings_fixed: 2
tokens: 0
duration_min: 120
verdict: CORRIGIDO
elenxo: sim
nota: >-
  Passo D da decisão selada D_MERGE_PROCESS_ONION_2026_10 (nó C_OPCAO_D_TWO_TIER_BENCH_NO_QUEUE, agora
  done, com a evidência E_PASSO_D_EXECUTADO_2026_10_13). No PR, onion-selftest.yml roda só as famílias
  do diff (ops/testing/selftest-pr-selection.sh sobre o lint-selftest.sh --affected-range novo, a
  mesma seleção do pre-commit pelo range base...head). Cai na completa, com o porquê no log, quando o
  mapa não classifica, quando o diff toca a bancada ou a infra do CI (lint-selftest.sh,
  .github/workflows/*, ops/testing/*), ou com a label ci:full. No push ao main roda a completa; se
  reprovar, ops/testing/main-bench-alarm.sh abre ou atualiza a issue de título fixo e prepara
  revert/<sha12>, sem merge. O job selftest-gate (if always) é o check estável. O lint perdeu o filtro
  de path para virar check obrigatório. Ruleset preparado, não aplicado (ops/github-ruleset-main.json
  + ops/apply-ruleset-main.sh --dry-run). Família nova two_tier_bench, 12 casos verdes sob LC_ALL=C, e
  15 mutantes por ops/mutate-and-restore.sh, cada um reprovando o seu caso. Passada adversarial com o
  default reprovado: 13 achados, 12 reais, 2 curados e 10 declarados como teto; 1 hipótese refutada.
  Validação: famílias tocadas (125 casos, 0 falhas após a cura do achado 2), mutantes, radar
  --integrity --schema exit 0, kg-contract-check rc 0, pr-finalize e CI do PR. O PR toca workflows,
  então o próprio desenho manda a bancada completa.
---

# Resíduo — REGRA 56

## O que mudou

- `.claude/validation/lint-selftest.sh`: `--affected-range <A...B>` (a seleção do pre-commit pelo diff
  de um range). A bancada no range ⇒ tudo; range ilegível ou vazio ⇒ tudo. Família `two_tier_bench`.
- `ops/testing/selftest-pr-selection.sh` (novo): a política do nível PR (label `ci:full`, infra ⇒
  completa, seletor fora do formato ⇒ completa) por cima do `--affected-range`.
- `ops/testing/selftest-shard-plan.sh`: `ONION_SHARD_FAMILIES` reparte só o subconjunto; nome
  inexistente ⇒ exit 2.
- `ops/testing/main-bench-alarm.sh` (novo): alarme de título fixo, revert `revert/<sha12>`, CI
  disparado por `workflow_dispatch` na branch, fecha a issue no verde, **nunca mergeia**.
- `.github/workflows/onion-selftest.yml`: sem `paths:`, `push` ao main, concorrência por sha no push e
  sem cancelamento, job de nível, `selftest-gate`, `alarme-main`.
- `.github/workflows/onion-validate.yml`: sem `paths:` (a lista ficou comentada como história),
  `workflow_dispatch`.
- `ops/github-ruleset-main.json` + `ops/apply-ruleset-main.sh` (novos, **não aplicados**).
- Doutrina: `docs/knowledge-base/concepts/onion-drive-doctrine.md` §0.

## O que o seletor faz, por classe de arquivo

| Classe | Exemplo medido | Nível |
|---|---|---|
| fora do domínio da bancada | `docs/README.md` | seletivo, só o núcleo (`gitattributes_eol`) |
| mapeado no domínio | `ops/merge-serial.sh` | seletivo, 15 de 252 famílias, com `merge_serial` |
| no domínio, não citado por família | `ops/zz-…-nao-mapeado.sh` | **completa** (failsafe do mapa) |
| bancada / infra do CI | `lint-selftest.sh`, `.github/workflows/*`, `ops/testing/*` | **completa** |
| infra da bancada (já no mapa) | `lint-artifacts.sh`, `.claude/hooks/lib/*`, `.githooks/*` | **completa** (failsafe existente) |
| label `ci:full` | qualquer | **completa** |
| range ilegível ou vazio | `nao-existe...HEAD` | **completa** |

## Mutantes (ops/mutate-and-restore.sh, 2026-10-13) — 15 de 15 reprovados

| # | Mutante | Caso que reprovou |
|---|---|---|
| M1 | a label `ci:full` deixa de ser lida | (d) |
| M2 | `ops/testing/*` sai da lista de infra | (c) |
| M3 | o failsafe `<todas>` do mapa é ignorado | (b) |
| M4 | range ilegível deixa de cair na completa | (e) |
| M5 | a bancada no range deixa de comprar tudo (`lint-selftest.sh`) | (f) |
| M6 | o plano ignora o subconjunto | (g) |
| M7 | `selftest-gate` sem `if: always()` | (h) |
| M8 | filtro de path de volta no `onion-selftest.yml` | (h) |
| M9 | `cancel-in-progress: true` (o push ao main cancelável) | (h) |
| M10 | o ruleset exige um nome que nenhum job produz | (h) |
| M11 | filtro de path de volta no `onion-validate.yml` | (h) |
| M12 | revert de merge sem `-m 1` | (i) |
| M13 | o alarme aberto é ignorado (abriria outra issue) | (i2) |
| M14 | o verde não fecha a issue | (i3) |
| M15 | o alarme passa a mergear | (h) |

## Passada adversarial (refutador com o default reprovado)

1. **O 1º M14 "morreu" por erro de sintaxe, não pelo caso** (real, curado). A âncora terminava em
   `||` e colidia com o separador `|||` do `mutate-and-restore.sh`, então o mutante plantado era bash
   inválido. A bancada reprovou, mas pelo motivo errado. Refeito com uma âncora sem `||`, ele reprova
   (i3) pelo motivo certo.
2. **`… | grep -qxF` sob pipefail no `apply-ruleset-main.sh`** (real, curado). A família
   `shell_pipefail_robustness` acusou o sítio novo, e virou here-string.
3. **O bypass do admin solta o dono** (real, teto declarado). Num repo de dono User, o dono é o admin,
   e `bypass_mode: always` faz o ruleset não prender quem mergeia. Para o dono, quem prende continua
   sendo o hook exit 2 mais o caminho verificado. O ruleset prende colaborador e App. Uma alternativa a
   decidir é `bypass_mode: pull_request`, que libera o admin só via PR e barra o push direto. O
   `actor_id 5` (admin) vem da doc REST e **não foi medido ao vivo**.
4. **O GITHUB_TOKEN não abre PR** (real, teto declarado, medido: `can_approve_pull_request_reviews:
   false`). O alarme empurra `revert/<sha12>` e escreve o comando na issue. Ligar a permissão é
   decisão do maestro.
5. **O revert aplicado sobre um main que andou pode conflitar** (real, declarado). Nesse caso a issue
   diz "revert manual".
6. **Qualquer label posta ou tirada refaz o run do PR** (real, declarado). Os gatilhos
   `labeled`/`unlabeled` existem para a `ci:full`, e o run anterior é cancelado. O custo é um
   recálculo, nunca um veredito errado.
7. **A quebra vinda do cron noturno não alarma** (real, declarado). Só o push ao main abre a issue; o
   cron fica vermelho no Actions.
8. **O custo do CI muda de lugar** (real, não medido). Cada merge passa a pagar uma completa no main,
   enquanto o PR deixa de pagar a completa a cada auto-rebase. O saldo líquido não foi medido.
9. **O lint passa a rodar em todo PR** (real, intencional). Um PR que escapava do filtro, como um que
   toca só a raiz, agora é julgado pelas REGRAS. Pode reprovar um PR que antes passava calado.
10. **O nível seletivo não foi exercido no forge** (real, declarado). Este PR toca workflows, então
    roda a completa. O primeiro PR comum depois do merge é a confirmação do caminho seletivo no
    GitHub (matriz de 1 faixa, `selftest-gate` verde). A bancada o exercita pelo range, como o
    runner o invoca.
11. **O alarme só foi exercido contra um remoto bare e um `gh` falso** (real, declarado). O caminho
    real do forge só roda quando o main quebrar.
12. **A guarda (h) do "nunca merge" é textual** (real, declarado). Ela procura `gh pr merge`; um merge
    por `gh api …/merge` escaparia dela. O alarme não faz isso, e o hook exit 2 continua sendo a
    fronteira.
13. **"Faixa que o nível PR não criou aparece como pulada e reprova o gate"** (hipótese refutada).
    Faixa não criada não existe na matriz: `needs.selftest.result` é `success` quando todas as faixas
    que existem passaram. Uma faixa pulada de fato (plano quebrado) leva o plano a `!= success`, e o
    gate reprova.

## Janela declarada

Entre o merge de um PR e o merge do revert, o main **pode estar quebrado**: a completa leva da ordem
de 25 min por faixa, mais o tempo do merge verificado. Com o alarme aberto, só se mergeia o conserto.
