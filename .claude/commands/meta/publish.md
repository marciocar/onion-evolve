---
name: publish
description: |
  Publica uma porta do Onion (onion-core, onion-standalone, onion-plugins, onion-mini) a partir de
  origin/main, sob demanda: ensaia, verifica o bundle, commita, empurra só com confirmação e confere no
  remoto. Toda publicação é uma release onion-vX.Y.Z: o motor propõe o bump e o maestro sela o número.
  --status mostra a defasagem e a versão de cada porta, lidas do remoto. Core-only.
category: meta
tags:
  - doors
  - publish
  - forge
version: "1.2.0"
updated: "2026-10-11"
related_commands:
  - /meta:forge
  - /meta:adopt
related_agents:
  - claude-code-specialist
allowed-tools: Read, Bash, AskUserQuestion
---

# 🚪 /meta:publish — publicar uma porta, sob demanda, sem travar o core

`/meta:publish <porta> | --all | --status`

Publicar uma porta passa a ser **um comando**. O motor `ops/publish-door.sh` destaca uma worktree em
`origin/main`, materializa pelo manifesto da porta, verifica o que montou, commita num clone e só
empurra quando o maestro confirma. O selo é o **carimbo da porta**, e nenhum PR no core depende dele.
A doutrina inteira (as 6 cláusulas, o destino e o que ela não promete) vive em
[`common:prompts:publish-doctrine`](../common/prompts/publish-doctrine.md). **Referencie, não copie.**

**Por que existe:** F3 do plano das portas (SAC-92, nó `D_MATRIZ_DE_PORTAS_2026_10` do grafo
`docs/onion/graph/door-role-parity-2026-09.kg.yaml`). Havia três caminhos de publicação, um deles
lendo a árvore de trabalho, e um workflow que deixava a main vermelha depois de todo merge. Forjado
pelo `/meta:forge` em 2026-10-10. O caminho antigo de plugins agora passa por aqui
(a skill `onion-publish` virou condução deste comando).

## Degrau e limites

- **Core-only.** Maestro-invocado. Publicar é ato voltado ao público (I3: um escritor por repo).
- **O `--push` é a confirmação explícita.** Esta superfície **só** o passa depois de perguntar ao
  maestro com AskUserQuestion. Sem ele, a rodada é ensaio.
- **Não escreve no core.** Nenhum commit, tag, PR nem edição no `members.yaml`. O `onion_version` do
  registro virou cache, e quem diz a verdade é o carimbo publicado.
- **Toda publicação é uma release** (cláusula 6 da doutrina, decisão do maestro de 2026-10-11). A
  versão `onion-vX.Y.Z` é **rótulo** de um pin: nenhuma guarda a lê. O motor **propõe** o bump, e o
  maestro **sela** o número na mesma pergunta que confirma a publicação. O `--push` sem `--version` é
  recusado.

## Contexto medido injetado (peça 3: o medidor roda ANTES de você pensar)

**Hoje:** !`date +%F`

!`if [ -f ops/publish-door.sh ]; then bash ops/publish-door.sh --status 2>&1; else echo "motor ausente: ops/ não viaja, e publicar portas é ato do core — nada a fazer aqui"; fi; true`

> ⚠️ As duas linhas acima são **diretivas de injeção** (exclamação seguida de crase), e o harness
> executa toda diretiva do arquivo, inclusive uma escrita como exemplo. Por isso a forma literal não
> aparece em mais nenhum lugar daqui. O `true` final mantém a carga viva quando o medidor sai com rc 3
> (nenhuma porta medida); a mensagem dele chega no texto injetado, e isso **é** a medição. O teste de
> existência existe porque este comando viaja para a porta onion-core (papel source) e o motor, em
> `ops/`, não.

Leia o status como ele se declara. A defasagem conta commits da superfície que viaja entre o pin
**publicado** e `origin/main`. `NÃO-MEDIDO` é "não sei", nunca "em dia". A coluna `versão` é o rótulo
lido do carimbo remoto (`—` = porta sem release). Numa porta defasada, o estado mostra a versão
**derivada** do pin novo (`onion-v1.0.0-N-g<sha>`), que não é release e não se guarda em lugar nenhum.

## Procedimento

1. **ORIENTAR.** Com `--status` no pedido, apresente a tabela injetada e **pare**. Para uma porta,
   confira na tabela o papel e a defasagem. `em dia` significa que não há o que publicar: diga isso e
   pare.
2. **ENSAIAR** (sempre, antes de qualquer push):
   `bash ops/publish-door.sh <porta>`
   O motor monta em clone descartável, verifica e commita sem empurrar. Leia o resultado de cada
   etapa. O passo (4b) traz a **proposta de bump** (`major`, `minor`, `patch` ou `primeira`, com os
   motivos), e o fim do ensaio mostra o **changelog da release**, que vira a mensagem da tag e já passou
   pela varredura de vazamento. rc 1 significa que a verificação reprovou: mostre o achado (vazamento, papel, lint e, nos
   plugins, as guardas de plugin sobre o bundle montado) e
   **pare**. A cura vai para o core por PR, nunca para a porta. rc 2 é precondição ou recusa, e rc 3
   é fonte irresolúvel. Id `onion-*` de adotante e caminho de máquina já são barrados no PR pela
   REGRA 106 (Superfície que viaja passa pela varredura de vazamento da publicação), que roda a mesma
   varredura. Se um deles aparecer aqui, a regra foi contornada ou a superfície que viaja mudou.
   - Troca de papel deliberada (a onion-core de `hub` para `source`, decidida na matriz):
     `--role source --force-role-change`.
   - Para ensaiar uma **branch** antes do merge: `--from <ref>` (o `--push` é recusado com ele).
   - **1ª materialização** de uma porta cujo repo guarda outro conteúdo (o onion-mini, com a destilação
     antiga): `--replace-foreign`. O motor arquiva o conteúdo atual numa tag `archive/pre-door-<data>`,
     empurrada e conferida ANTES da porta no `--push`, e só então o substitui. Sem a flag, rc 2.
     O mini não leva lint: a verificação dele (passo 5c) é o `door-mini-check.sh` — allowlist exata,
     sem ponteiro morto, sem caminho de máquina.
3. **CONFIRMAR e SELAR** com AskUserQuestion: a porta, o papel, o pin de `origin/main`, o resumo do
   commit ensaiado, o que vai a público e a **versão**. As opções são **publicar como
   `onion-v<proposta>`** (a recomendada, com os motivos do motor), **publicar com outro número**
   (o maestro diz qual; tem de ser maior que a última tag) e **parar**. No `--all`, a pergunta usa a
   **PROPOSTA DA FAMÍLIA**, porque o número é único nas quatro portas (mesmo numa porta só, a
   proposta já parte do máximo da família, e o motor recusa um número que outra porta usa noutro pin).
   Nunca assuma o número.
4. **PUBLICAR** só com o "sim":
   `bash ops/publish-door.sh <porta> --push --expect-pin <pin do ensaio> --version <número selado>`
   O motor refaz a rodada inteira (verificação inclusa), empurra o ramo, cria a tag anotada
   `onion-v<número>` com o changelog e confere os dois no remoto com `git ls-remote`. Se a verificação
   não pôde ser medida (por exemplo, sem a CLI `claude` nos plugins), o push é recusado. Se o ramo
   subir e a tag não for conferida, o rc é 4: re-rode com o **mesmo** número, que só empurra a tag.
5. **CONFERIR** com `bash ops/publish-door.sh --status`: a porta tem de aparecer `em dia`, com o pin
   novo e a versão selada lidos do remoto.
6. **REGISTRAR SÓ O QUE ENSINA.** Defeito achado, troca de papel ou modo de falha novo viram nó no
   grafo `door-role-parity` na leva seguinte, com `kg-radar` exit 0 (peça 5 da doutrina). Publicação
   rotineira não gera nó nem PR.

`--all` roda o ensaio (ou, com `--push --version`, a publicação) porta a porta, cada uma em clone
próprio, e no fim agrega a **PROPOSTA DA FAMÍLIA**: a maior tag entre as portas com o maior bump
proposto. Ele **nunca** repassa `--replace-foreign`: a 1ª materialização do onion-mini é rodada sozinha,
de propósito. A publicação da família não é atômica: se uma porta reprovar, cure no core e re-rode com
o **mesmo** número (a porta que já está na release passa como re-rodada idempotente).

## O que este comando NÃO faz

- Não substitui conteúdo que não reconhece como porta sem `--replace-foreign`, e com ele não apaga:
  arquiva numa tag antes. (As guardas de plugin — REGRAS 61, 72–77 e 79 — rodam desde a F4 no passo
  5d, sobre o bundle montado, por `plugin-bundle-check.sh`; elas não estão mais no lint de PR, porque o
  core não versiona mais o `plugins/` montado.)
- Não empurra sem confirmação, não força push e não reescreve a história de porta nenhuma. Também não
  reescreve tag: o número de uma release já publicada só passa de novo quando o conteúdo é o mesmo.
- Não deriva a versão de Conventional Commits, e não deixa guarda nenhuma decidir pela versão.
- Não atualiza o clone local da porta nem o `role:` do registro depois de uma troca de papel. Isso vai
  como instrução no fim da rodada.

## 🔗 Referências

- Doutrina (peça 2): [`common:prompts:publish-doctrine`](../common/prompts/publish-doctrine.md)
- Motor e medidor (peça 3): `ops/publish-door.sh` (`--status`) · contagem: `door-staleness-check.sh --count`
- Lente (peça 6): `.claude/rules/publish-lens.md`
- Bancada (peça 7): `run_publish_selftests`, `run_publish_release_selftests` (versionamento) e
  `run_door_staleness_severity_selftests` em `lint-selftest.sh`
- Verificação do mini (sem lint): `.claude/validation/door-mini-check.sh` · overlays em `ops/door-templates/mini/`
- Materializadores: `ops/materialize-door.sh` (core, standalone, mini) ·
  `.claude/utils/marketplace/materialize-marketplace-repo.sh` (plugins)
- Grafo da decisão: `docs/onion/graph/door-role-parity-2026-09.kg.yaml` (`D_MATRIZ_DE_PORTAS_2026_10`,
  `D_VERSIONAR_AS_PORTAS_POR_RELEASE`)
