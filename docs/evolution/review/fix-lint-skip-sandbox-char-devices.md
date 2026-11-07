---
title: 'Resíduo — o lint pula o dispositivo de caractere do sandbox, e a forma óbvia não curava'
date: 2026-11-06
branch: fix/lint-skip-sandbox-char-devices
reviewed_diff_sha256: 9708a28c419d986b65673ea1b6559c8e69484443df3ea42ad505ab996ed17967
reviewed_code_sha256: 22361ed1a433ed4e312c65e185a2922b0a1f956f12bde619b21f210a75a870b0
findings_total: 5
findings_real: 3
findings_fixed: 3
tokens: 0
duration_min: 20
verdict: REPROVADO_E_CURADO
elenxo: sim
nota: >-
  Passada adversarial feita pelo próprio agente de execução, sem subagente (regra do brief), sobre o
  diff inteiro. Antes dela, a 1ª forma da cura (`! -type c` no _find, a sugerida no brief) foi
  REFUTADA por medição: o GNU find julga -type pelo d_type do ponto de montagem e vê arquivo regular.
  Achados reais curados: a contagem só olhava .claude/ e a raiz (o _find pula em toda raiz); a
  contagem sob pipefail podia matar o lint no sumário com um diretório ilegível; o --only num
  dispositivo dizia "arquivo inexistente". `tokens: 0` porque não houve subagente medido.
---

# O lint pula o dispositivo de caractere do sandbox, e a forma óbvia não curava

## O defeito

Com o sandbox do Claude Code 2.1.319 ligado, a curadoria mediu (2026-11-06): o sandbox monta
`/dev/null`, sem leitura, sobre 16 caminhos do projeto (`.claude/loop.md`, `.claude/launch.json`,
`.claude/routines`, `.mcp.json`, `.gitconfig`…). O `_find "${CLAUDE_DIR}" -name '*.md'` casava o
`loop.md`, o `awk` da REGRA 3 (Campo model: restrito à allowlist sonnet|opus|haiku|fable) o abria e
morria com `Permission denied`, rc=2. Todo commit do adotante com sandbox parava.

Reproduzido aqui com `bwrap --bind / / --dev-bind /dev /dev --ro-bind /dev/null <caminho>`: a mesma
mensagem, o mesmo rc.

## A forma óbvia foi refutada

`find -type f` e `! -type c` **não curam**. Medido no bwrap, GNU findutils 4.9.0: sobre o `loop.md`
montado, `find -type c` não casa e `find -type f` casa. O GNU find lê `-type` do d_type do readdir,
que é o do arquivo vazio debaixo da montagem. `stat`, `[ -c ]`, `-printf %y` e `-xtype` enxergam o
dispositivo. A cura usa `-xtype c` quando o find o tem (detectado, não presumido) e cai para
`-type c` no find BSD, cujo `-type` vem do lstat.

## Os sítios curados

| sítio | o que mudou |
|---|---|
| `lint-artifacts.sh` `_CHARDEV_TYPE` | predicado resolvido uma vez (`-xtype c` ou `-type c`) |
| `lint-artifacts.sh` `_find` (os dois ramos) | `! "${_CHARDEV_TYPE[@]}"` antes dos predicados do chamador: todas as regras que varrem por `_find` |
| `lint-artifacts.sh` `--only` | dispositivo nomeado como tal, não como "arquivo inexistente" (rc 2 mantido: nada a julgar) |
| `lint-artifacts.sh` sumário | linha `Pulados : N caminho(s) por serem DISPOSITIVO DE CARACTERE` |
| `lint-selftest.sh` `_chardev_excludes` + `_snapshot_create` + o tar da árvore viva | o retrato da bancada não carrega o dispositivo (sem isso o `tar -x` morria em `mknod`, rc=2) |

## Os achados da passada e o destino de cada um

| # | achado | destino |
|---|---|---|
| 1 | a contagem olhava só `.claude/` e a raiz, e o `_find` pula em toda raiz | curado: o repo inteiro, fora de `.git`, `node_modules` e worktrees |
| 2 | sob pipefail, um diretório ilegível daria rc=1 ao find da contagem e mataria o lint no sumário | curado: `|| true` dentro do grupo. Medido: `docs/locked` com chmod 000 dá rc=1 (sumário), não 2 |
| 3 | `--only` num dispositivo dizia "arquivo inexistente" | curado: mensagem nomeia o dispositivo |
| 4 | arquivo regular ilegível poderia ser calado junto | confirmação: segue chegando ao leitor e o lint sai rc=2 nomeando o arquivo (caso (b)) |
| 5 | diretório onde se espera arquivo (`.claude/output-styles`) | confirmação: no sandbox é dispositivo, então pulado; diretório de verdade não é a assinatura e ficou fora do escopo |

## A bancada

Família nova `sandbox_chardev`, duas formas de reproduzir: `bwrap` (a mesma montagem do sandbox) e,
sem bwrap utilizável (o runner do CI), symlink para um dispositivo ilegível do host (`/dev/mem`).
`ONION_SELFTEST_CHARDEV_MODE=link` força o 2º ramo; os dois passaram aqui, 5 de 5 cada:
(a) pula e conta 3; (b) regular ilegível segue reprovando; (c-MUT) sem o filtro do `_find` o lint
volta a morrer; (d-MUT) `-type c` no lugar de `-xtype c` também morre; (e) o retrato sem e com as
exclusões.

## Sem regressão no lint do core

- Árvore real, sem sandbox: as mesmas violações da base (`16b53832b`), menos o inventário do harness
  regenerado. Base 784 s, cura 694 s (ruído de carga).
- Árvore real sob o bwrap com os 16 caminhos: rc=0, `Pulados : 16`, as mesmas violações.

## O que NÃO foi coberto (declarado)

- As 135 famílias que o pre-commit selecionaria não rodaram aqui. Rodaram `sandbox_chardev`,
  `backtick_ref`, `two_tier_bench` e `selftest_lanes` (59 de 59). A `fixtures` NÃO terminou: o teto de
  60 min a cortou com 95 ✓ e nenhum ✗, e o banner de aborto dela é o corte, não um defeito. A completa é do CI.
- Achado à parte, PRÉ-EXISTENTE e fora deste PR: o `lint-artifacts.sh --only=<arquivo>` leva 73 s na
  base e 74 s com a cura (o comentário do pre-commit fala em ~16 s), e o lint inteiro leva 694–784 s.
  É isso que faz a `fixtures` passar de uma hora aqui.
- O sandbox real do Claude Code não rodou nesta máquina: a reprodução é o bwrap. A prova no campo é
  o próximo `--update` da curadoria.
