---
name: publish
description: |
  Publica uma porta do Onion (onion-core, onion-standalone, onion-plugins, onion-mini) a partir de
  origin/main, sob demanda: ensaia, verifica o bundle, commita, empurra só com confirmação e confere no
  remoto. --status mostra a defasagem de cada porta lida do remoto. Core-only.
category: meta
tags:
  - doors
  - publish
  - forge
version: "1.0.0"
updated: "2026-10-10"
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
A doutrina inteira (as 5 cláusulas, o destino e o que ela não promete) vive em
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
- **Não escreve no core.** Nenhum commit, PR nem edição no `members.yaml`. O `onion_version` do
  registro virou cache, e quem diz a verdade é o carimbo publicado.

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
**publicado** e `origin/main`. `NÃO-MEDIDO` é "não sei", nunca "em dia".

## Procedimento

1. **ORIENTAR.** Com `--status` no pedido, apresente a tabela injetada e **pare**. Para uma porta,
   confira na tabela o papel e a defasagem. `em dia` significa que não há o que publicar: diga isso e
   pare.
2. **ENSAIAR** (sempre, antes de qualquer push):
   `bash ops/publish-door.sh <porta>`
   O motor monta em clone descartável, verifica e commita sem empurrar. Leia o resultado de cada
   etapa. rc 1 significa que a verificação reprovou: mostre o achado (vazamento, papel, lint) e
   **pare**. A cura vai para o core por PR, nunca para a porta. rc 2 é precondição ou recusa, e rc 3
   é fonte irresolúvel.
   - Troca de papel deliberada (a onion-core de `hub` para `source`, decidida na matriz):
     `--role source --force-role-change`.
   - Para ensaiar uma **branch** antes do merge: `--from <ref>` (o `--push` é recusado com ele).
3. **CONFIRMAR** com AskUserQuestion: a porta, o papel, o pin de `origin/main`, o resumo do commit
   ensaiado e o que vai a público. As opções são **publicar** ou **parar**. Nunca assuma.
4. **PUBLICAR** só com o "sim":
   `bash ops/publish-door.sh <porta> --push --expect-pin <pin do ensaio>`
   O motor refaz a rodada inteira (verificação inclusa), empurra e confere no remoto com
   `git ls-remote`. Se a verificação não pôde ser medida (por exemplo, sem a CLI `claude` nos
   plugins), o push é recusado.
5. **CONFERIR** com `bash ops/publish-door.sh --status`: a porta tem de aparecer `em dia`, com o pin
   novo lido do remoto.
6. **REGISTRAR SÓ O QUE ENSINA.** Defeito achado, troca de papel ou modo de falha novo viram nó no
   grafo `door-role-parity` na leva seguinte, com `kg-radar` exit 0 (peça 5 da doutrina). Publicação
   rotineira não gera nó nem PR.

`--all` roda o ensaio (ou, com `--push`, a publicação) porta a porta, cada uma em clone próprio. O
onion-mini é recusado até a F5 (SAC-94): o repo dele guarda a destilação curada, e substituí-la é a 1ª materialização.

## O que este comando NÃO faz

- Não publica a 1ª materialização do onion-mini (F5) nem roda as REGRAS 19/72–79/61 sobre um bundle de
  plugins temporário (F4, SAC-93).
- Não empurra sem confirmação, não força push e não reescreve a história de porta nenhuma.
- Não atualiza o clone local da porta nem o `role:` do registro depois de uma troca de papel. Isso vai
  como instrução no fim da rodada.

## 🔗 Referências

- Doutrina (peça 2): [`common:prompts:publish-doctrine`](../common/prompts/publish-doctrine.md)
- Motor e medidor (peça 3): `ops/publish-door.sh` (`--status`) · contagem: `door-staleness-check.sh --count`
- Lente (peça 6): `.claude/rules/publish-lens.md`
- Bancada (peça 7): `run_publish_selftests` e `run_door_staleness_severity_selftests` em `lint-selftest.sh`
- Materializadores: `ops/materialize-door.sh` (core, standalone, mini) ·
  `.claude/utils/marketplace/materialize-marketplace-repo.sh` (plugins)
- Grafo da decisão: `docs/onion/graph/door-role-parity-2026-09.kg.yaml` (`D_MATRIZ_DE_PORTAS_2026_10`)
