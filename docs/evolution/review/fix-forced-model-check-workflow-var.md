---
title: 'Resíduo — a checagem de modelo forçado cegava a variável nova, e a cura quase quebrou o plugin'
date: 2026-10-11
branch: fix/forced-model-check-workflow-var
reviewed_diff_sha256: d2c23f600bac457dbae80d70f268243c9fb6b4e771866acc77ecffc8c62292b5
reviewed_code_sha256: 3c5c1f8aff9e2bb2638b6a8fcd7b3f1a7ff9894df18f1f29181f19afe714ec10
findings_total: 6
findings_real: 6
findings_fixed: 5
tokens: 121569
duration_min: 8
verdict: CORRIGIDO
elenxo: nao
nota: >-
  SAC-105 (rodada r9 do radar E3). Refutador general-purpose, com reprovação como ponto de
  partida, sobre o diff inteiro. Veredito: REPROVA. Seis achados reais: cinco curados neste PR e um
  declarado como lacuna (o remapeamento de alias).
---

# A checagem enxergava um nome e não via o outro

## O defeito de origem

O passo 8 da `onion-orchestration` e a KB `agent-orchestration` checavam o modelo forçado por um
grep de substring `CLAUDE_CODE_SUBAGENT_MODEL` no `env`. Esse grep errava nos dois sentidos:

- dava **0** para `CLAUDE_CODE_WORKFLOW_SUBAGENT_MODEL`, a variável criada na 2.1.296;
- acusava `CLAUDE_CODE_SUBAGENT_MODEL` sozinha, que desde a 2.1.251 é piso e não força.

A cura tirou a checagem da prosa e a pôs num helper determinístico,
`.claude/utils/orchestration/forced-model-check.sh`. A skill e a KB citam o helper. Ele cobre um
catálogo de duas variáveis mais uma rede para nomes novos.

## O que o refutador achou

| # | Achado | Real? | Destino |
|---|---|---|---|
| 1 | **O plugin `onion` quebra.** O manifesto empacota a skill, mas não `utils/orchestration`. O `plugin_bundle` reprova com HARD `NOVO` e a catraca cresce de 81 para 82 | sim | curado: o diretório entrou no `UTILS` do `onion.manifest.sh`. O mutante M8 prova a guarda |
| 2 | Fail-open: sem `tr` no PATH, `FORCE=1` saía com rc 0. Sem `grep`, o `\|\| true` engolia a rede | sim | curado: o helper só usa builtins (`${v,,}`, `case`, `compgen`). Caso (a2) roda com PATH num diretório vazio; mutante M7 |
| 3 | O padrão do caso (f) deixava escapar aspas, flag longa e regex ancorada, e não via arquivo não rastreado | sim | curado: padrão com limite e no máximo uma quebra de linha, mais `--others`. Mutante M6 |
| 4 | Mutantes sobreviventes: modelo efetivo vazio sem piso; Workflow fora da lista de exclusão do laço (gera AVISO duplicado) | sim | curados: caso (b2) e contagem exata no caso (a). Mutantes M4 e M5 |
| 5 | A rede de novidade (`*AGENT_MODEL*`) era estreita: não pegava `CLAUDE_CODE_TEAMMATE_MODEL` | sim | curado: a rede passou a `CLAUDE_CODE_*MODEL*`, e o caso (e) usa o nome sem `AGENT` |
| 6 | `ANTHROPIC_DEFAULT_*_MODEL` remapeia o alias e troca o modelo executado sem forçar nada | sim, como classe | **lacuna declarada** no cabeçalho do helper e na KB. Não foi verificado na documentação nesta rodada |

Achado menor, também curado: `CLAUDE_CODE_WORKFLOW_SUBAGENT_MODEL=" "` gerava um AVISO com modelo
vazio. O valor agora passa por trim, e o caso (d) cobre essa forma.

## O que eu errei

- **O `--affected` não seleciona `plugin_bundle`** quando o diff toca uma skill bundlada e o seu
  helper. A minha bancada por famílias passou verde com o plugin quebrado. Quem pegou foi o
  refutador, rodando a família certa. É a repetição do precedente que o próprio manifesto documenta
  (`workflow-syntax-check.sh`, 2026-09-22). A cura de mecanismo, fazer o mapa do `--affected` ligar
  skill bundlada a `plugin_bundle`, **não está neste PR**: fica como fio aberto.
- O primeiro caso de PATH vazio usava `env -i` sem PATH. Nesse caso o bash cai num PATH default e
  acha o `tr`. O mutante M7 sobreviveu até eu apontar o PATH para um diretório vazio.

## Mutantes (8, todos mortos)

M1, o grep antigo devolvido ao helper, reprova 9 casos. M2 desliga a checagem de Workflow. M3 põe o
grep antigo de volta na skill, quebrado na linha. M4 deixa o modelo efetivo vazio. M5 tira o
Workflow da exclusão do laço. M6 põe o grep entre aspas e com flag longa. M7 volta a depender do
`tr`. M8 tira `utils/orchestration` do manifesto do plugin.

Todos rodaram por `mutate-and-restore`, com a restauração conferida por hash.
