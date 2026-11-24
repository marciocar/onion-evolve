---
name: restart
description: |
  Reinício gracioso (drain) da sessão: declara «sem despacho novo», mede os agentes e as tarefas de fundo desta
  sessão, espera com teto até zerarem, grava um bilhete de retomada com cada agente em voo e imprime o comando exato
  para reabrir a sessão pelo id. Na volta, o --resume-check lista quem retomar e apaga o marcador.
category: meta
tags:
  - orchestration
  - sessions
  - restart
version: "1.1.0"
updated: "2026-11-24"
related_commands:
  - /meta:baton
  - /meta:cc-update
allowed-tools: Read, Bash, SendMessage, TodoWrite
---

# 🔁 /meta:restart — reiniciar sem perder agentes e tarefas de fundo

**O problema (medido em 2026-11-21):** atualizar o Claude Code («Update installed · Restart to update») ou reabrir a
sessão mata os subagentes e as tarefas de fundo, porque eles vivem no processo. Naquele dia, 5 agentes pararam no meio
de pre-commit e CI e foram retomados à mão, um por um, por `SendMessage`, sem registro de quem estava em qual worktree
nem em qual passo.

**A forma é a do mercado: desligamento gracioso (drain).** Parar de aceitar trabalho novo, esperar o que está em curso
com teto, gravar o estado, reiniciar, retomar. É o prazo de encerramento do Kubernetes antes do SIGKILL, o `drain` do
Nomad, o SIGTERM com prazo. Aqui o «trabalho novo» é despacho de agente e o estado gravado é o **bilhete de retomada**.

A peça que mede e grava é `.claude/utils/orchestration/restart-drain.sh` (bancada `run_restart_drain_selftests`). Ela
**não reimplementa** medição: os agentes vêm do `.claude/validation/baton-pulse.sh --tsv` (as classes `AGENT_*` da
batuta) e as tarefas de fundo da sonda `.claude/hooks/background-task-probe.sh`. A doutrina de quem rege as sessões é a
[da batuta](../common/prompts/baton-doctrine.md).

## Estado agora (só leitura)

!`bash .claude/utils/orchestration/restart-drain.sh --status 2>&1 || true`

> A linha acima é uma diretiva de injeção (bang seguido de crase) e o harness executa toda diretiva do arquivo; por
> isso a forma literal não aparece em mais nenhum lugar daqui. Ela só lê: marcadores (`draining`) e bilhetes
> pendentes (`ticket`). Bilhete pendente da sessão atual quer dizer **você acabou de voltar**: vá direto ao passo 6.

## Uso

```
/meta:restart              drena (padrão): espera até 15 min pelos agentes e tarefas em curso
/meta:restart --now        pula a espera: só marcador e bilhete (o update já está esperando)
/meta:restart --resume-check   na volta: lista quem retomar, apaga o marcador, arquiva o bilhete
```

Teto e sondagem são ajustáveis: `--timeout-min N` (padrão 15), `--poll-s N` (padrão 30), `--stale-min N` (padrão 240:
agente não terminado sem escrita há mais que isso é resto de vida anterior e vai para «Antigos», fora da retomada).

## Procedimento

1. **Rode da sessão principal, nunca de um subagente.** O id da sessão vem de `CLAUDE_CODE_SESSION_ID`; um subagente
   que rodasse o drain contaria a si mesmo como agente em curso e só sairia no teto.
2. **Drene:**
   `bash .claude/utils/orchestration/restart-drain.sh` (ou com `--now`). O script faz, nesta ordem:
   - antes de tudo, confere que consegue medir (o medidor de agentes, a sonda de tarefas e o transcript da sessão);
     se não consegue, **recusa sem gravar marcador** (`rc 2`): drenar às cegas é o defeito que ele evita;
   - (a) grava o marcador **sem despacho novo** em `~/.local/state/onion/restart/<sessão>.draining` (com
     `XDG_STATE_HOME`, em `$XDG_STATE_HOME/onion/restart/`, o mesmo lugar que a batida lê; arquivos só do dono);
   - (b) mede os agentes desta sessão e as tarefas de fundo dela e de cada agente;
   - (c) espera com teto até zerarem `AGENT_RUNNING`, `AGENT_STALLED`, `AGENT_UNMEASURED` e as tarefas vivas ou não
     medidas (o que não se mediu segura a espera), dizendo a cada sondagem o que ainda corre (agente, descrição,
     último passo; tarefa, PID);
   - (d) grava o bilhete em `~/.local/state/onion/restart/<sessão>.md` (e `.tsv`, para máquina) com cada agente em
     voo: id, descrição, classe, worktree, branch, último passo. O último passo é o comando pendente **como o
     baton-pulse o entrega, já com segredo trocado por `[REDACTED]`** pela lista dele; sem pendência, só o nome da
     ferramenta (e o arquivo). O texto cru do comando nunca é lido para o bilhete;
   - (e) imprime o comando de retomada: `bash ops/session-open.sh <nome> --resume <id>` (core-only), que reabre a sessão pelo id
     exato dentro do tmux. O nome é o último título da sessão (`customTitle`, ou `--name`). Onde o
     `ops/session-open.sh` (core-only) não existe (fora do core), ou o título está fora do padrão de nome dele (espaço, acento,
     parênteses), imprime `claude --resume <id>` e diz por quê. O sufixo « (N)» que o harness acrescenta ao nome
     repetido (medido: `onion-evolve (5)`) sai antes.
   - (f) a receita **depende do modo da sessão**, medido na lista de peers (`claude agents --json`, pela regra única de
     «viva» em `.claude/utils/orchestration/session-liveness.sh`) e na chave `TMUX` do ambiente do processo:

     | Modo | Como se reconhece | Receita |
     |---|---|---|
     | tmux | interativa, com `TMUX` no ambiente | `bash ops/session-open.sh <nome> --resume <id>` (core-only) |
     | fundo nativo | `kind: background` na lista de peers | `claude stop <id-curto> && bash ops/session-open.sh <nome> --resume <id>` (core-only): o stop para sem perder a conversa, e o abridor volta ao tmux e recupera o canal da campainha |
     | terminal solto | interativa, sem `TMUX` | a receita do tmux, com o aviso: dê `/exit` nela antes |
     | não medido | lista ou ambiente ilegíveis | a receita do tmux, com a lacuna dita |

     O modo vai ao bilhete (`- modo da sessão:` no `.md`, 7ª coluna da linha `session` no `.tsv`).
     **Não medido no 2.1.331** (nenhuma peça roda `stop` nem `attach` para medir): que a retomada interativa depois do
     `claude stop` mantém o mesmo id, que `stop` e `attach` aceitam o id curto que o harness lista, e que a janela
     `claude attach` fecha sozinha depois do stop. Se ela sobrar, o abridor manda fechá-la em vez de repetir a receita.
3. **Enquanto o marcador existir, não despache agente novo nem lance tarefa de fundo.** A batida (`/meta:baton`) avisa
   o marcador como «SEM DESPACHO NOVO» para esta sessão. Se um agente perguntar algo, responda; não dê tarefa nova.
4. **Leia o resultado.** `rc 0`: zerou (ou `--now`), bilhete gravado. `rc 3`: o teto venceu com trabalho em curso; o
   bilhete foi gravado com o que corria e a saída diz o quê. Decida com o maestro entre esperar mais (rode de novo) ou
   reiniciar assim mesmo: o bilhete já cobre a retomada. `rc 5`: bilhete gravado **com lacuna** (algo não foi medido,
   no `--now` ou numa falha durante a espera; nesse caso fica a última medição boa); o bilhete diz «NÃO MEDIDOS», nunca
   «nenhum». `rc 2`: não conseguiu medir; ele **não drena às cegas**. Corrija a causa dita ou use `--now`, que grava só
   o que se sabe. Se o `rc 2` veio depois do marcador (o medidor falhou no meio), o marcador fica: o
   `--resume-check` o apaga (sai `rc 4`, sem bilhete).
5. **Reinicie.** Entregue ao maestro o comando do passo 2(e) e o caminho do bilhete. Quem reinicia é ele (ou o
   update); este comando não mata nem reinicia nada.
6. **Na volta, retome:**
   `bash .claude/utils/orchestration/restart-drain.sh --resume-check`
   Ele lista cada agente do bilhete com a mensagem pronta e, depois de listar, apaga o marcador e arquiva o bilhete
   como `<sessão>.<epoch>.resumed.md`. **O bilhete segue a cópia:** mandar a sessão ao fundo nativo (a tecla `←`) cria
   uma cópia com id novo, e o bilhete ficou no id antigo. Chamado da cópia sem bilhete do próprio id, o `--resume-check`
   segue o do **ancestral**: o bilhete pendente cujo transcript é a origem dela (1ª linha `history-suppression` com
   `cause: fork_inherit`, e o **último** `uuid` herdado da cópia presente no transcript da origem; o primeiro se repete em irmãs e seguiria o
   bilhete de uma delas). Ele diz que seguiu. Para cada agente listado, mande `SendMessage` com `to` = o id e o texto
   «Reinício da sessão: retome de onde parou. Último passo: <o do bilhete>. Confira o estado (git status, PR, CI)
   antes de repetir qualquer passo.» As tarefas de fundo morreram com o processo: relance à mão só as que ainda
   forem necessárias. Sem bilhete, ele sai `rc 4` e diz isso. Bilhete com lacuna sai `rc 5` e repete o que não foi
   medido: aí confira os transcripts em `subagents/` antes de dar a retomada por completa.

## O que o bilhete não garante (teto declarado)

- **Fundo nativo é para tarefa curta.** A sessão de serviço longo (dona de peça ou de batuta) vive no tmux, que tem o
  canal da campainha e volta no boot pelo systemd do usuário. A cópia de fundo nasce de um `claude bg-spare` genérico,
  sem a flag do canal, e o daemon de fundo é transitório (sai sem clientes, aposenta sessão ociosa). A batida avisa
  (`SESSION_NATIVE_BG_LONG_DUTY`). Este comando nunca roda `claude stop`, `attach` nem `rm`: só os imprime.

- **O id do agente sobrevive ao reinício** é o que se mediu em 2026-11-21 (os 5 agentes foram retomados por
  `SendMessage` ao id). Se um dia o harness deixar de aceitar, o bilhete ainda tem descrição, worktree, branch e passo
  para relançar o agente com um brief novo.
- **Não sabe se o processo do subagente vive**: o harness não expõe pid por subagente; o que se mede é o transcript.
- **Worktree por citação**: é a worktree do repo citada por último nas chamadas de ferramenta do agente. Agente que
  nunca cita uma sai com o cwd da sessão, dito como tal.
- **Agente da ferramenta Workflow** sai com id `<run>/<id>`; não está medido se `SendMessage` aceita esse alvo. Se
  recusar, relance pelo workflow.
- **Tarefa de fundo que redireciona a própria saída** pode sair como viva ou morta pelo processo que segura o
  `.output` (o mesmo teto da sonda).
- **A redação é a lista do baton-pulse**: o que não está nela passa. Medido em 2026-11-21: `--token X` (com espaço)
  e `usuário:senha@` dentro de URL passam. O bilhete é 0600 e fica fora do repo, mas não o cole sem ler.
- **A pasta padrão é a mesma da batida** só com o `BATON_STATE_DIR` padrão: com ele customizado, passe
  `ONION_RESTART_DIR` aos dois.
- **O marcador é aviso, não trava.** Nada barra um despacho com o marcador presente; ele existe para a batida e a
  sessão lerem. Virar trava (hook) é passo separado, com a forja de guarda.

## Referências

- Medidor e escritor: `.claude/utils/orchestration/restart-drain.sh` · bancada: `run_restart_drain_selftests` em
  `.claude/validation/lint-selftest.sh`
- Agentes: `.claude/validation/baton-pulse.sh` (o `/meta:baton`), que também avisa do marcador e do bilhete
- Tarefas de fundo: `.claude/hooks/background-task-probe.sh`
- Retomada pelo id, no tmux: `ops/session-open.sh` (core-only) · posse: `.claude/utils/orchestration/ownership.sh`
