---
title: Radar E3 r25 — o delta do Claude Code 2.1.323 a 2.1.327 contra o Onion
date: 2026-11-18
kg: docs/evolution/research/radar-E3-2026-11-18-r25/radar-E3-2026-11-18-r25.kg.yaml
run_id: "nenhum (sem Workflow: rodada conduzida pela sessão do core, com um juiz subagente independente e uma sonda em worktree isolada)"
tokens: 352227   # juiz 191039 + sonda isolada 161188; o contexto da sessão coordenadora não tem contador
agents: 2
duration_min: 45   # do esqueleto (23:06 UTC) ao fim da aplicação, sem contar a pausa pedida pelo maestro
review_after: 2026-12-18
type: research
mode: cc-update
---

# Radar E3 r25 — o delta do Claude Code 2.1.323 a 2.1.327

Rodada 25 do radar do Claude Code (eixo E3 do radar de mundo: a medição do que cada versão nova do Claude Code muda no Onion).

**Versões:** a baseline estava na 2.1.322; o disco e o processo estão na 2.1.327. O delta tem quatro versões publicadas com seção (a 2.1.324 não tem seção no CHANGELOG), com 973 itens copiados byte a byte em `data/`. O grafo tem 23 nós: 2 do esqueleto, 15 da rodada, 3 omissões medidas pelo juiz e 4 superações.

Uma tentativa anterior de r25, de 2026-11-14 (2.1.323 a 2.1.325), ficou numa worktree sem commit e sem PR. Esta rodada não a herda: tudo aqui foi medido de novo.

## O que toca a casa (medido no vivo)

- **Autorização de um toque (prompt humano contra mensagem de outra sessão).** Na 2.1.327 o transcript ainda separa `origin.kind=human` com `promptSource=typed` de `origin.kind=peer` com `promptSource=system` e `isMeta=true`. Nenhum item do delta mexe nesses campos. O delta reforça a distinção: a 2.1.323 deixou de entregar aos agentes de workflow, como pedido do usuário, um prompt que o app marca como não digitado (`data/2.1.323.txt` l.238). A 2.1.327 também tirou o «don't ask again» do Artifact depois de mensagem de outra pessoa (`data/2.1.327.txt` l.152).
- **O `ask` de hook em bypassPermissions.** Num `-p` sem ninguém para responder, o `ask` de um hook PreToolUse é **recusado** em bypass, não auto-aprovado. O juiz mediu o mesmo na 2.1.322 e na 2.1.325, então isso não vem do delta. O modo interativo sob bypass, que é o das sessões da casa, não foi medido. A decisão do motor de um toque de não depender do `ask` continua certa.
- **Mensagens entre sessões.** Desde a 2.1.323 as sessões da mesma máquina trocam até 100.000 mensagens sem prompt humano no meio; antes eram cerca de 20 (`data/2.1.323.txt` l.203). O freio era de volume, não de autoria: os atos do maestro são barrados por alvo (`pretooluse-moat-gate.sh`, `pretooluse-merge-gate.sh`), e a origem marcada só é lida pelo `house-code-gloss.sh` e pelo motor de um toque.
- **Worktree de agente e `core.hooksPath`.** A 2.1.327 ainda grava o caminho absoluto no `.git/config` comum ao criar uma worktree de agente. O juiz mediu o mesmo na 2.1.322, e nenhum item do delta trata disso. Quem desfaz é o `session-currency-check.sh`, logo depois.
- **Agente isolado e git.** O agente isolado em worktree recusa git seguido de `; echo rc=$?`, mesmo inofensivo, e já recusava na 2.1.322. `&& echo ok`, `branch -f` e `rebase` em forma simples passam. Ação: a tarefa do preâmbulo de agente isolado (SAC-434).
- **Guarda de deriva do cited-directive.** Reprova na 2.1.327, mas o parser de injeção do harness não mudou: só as variáveis locais `r` e `s` viraram `o` e `u`. Ação: a tarefa do curinga das locais no molde (SAC-433). A `channel_session` segue verde.
- **Quem serve.** O host está na 2.1.327, o bridge na 2.1.323 (SDK 0.3.323) e o revisor do CI na 2.1.322 (action v1.0.272). Desde a 2.1.326 mais chamadas são recusadas onde ninguém pode responder, e isso chega ao revisor e ao bridge quando eles subirem. Ação: a tarefa da subida do SDK e do pin do revisor (SAC-432).
- **`/loop` e o baton.** Desde a 2.1.325 o `/loop` pede confirmação antes de rodar uma skill que declara `allowed-tools`. O `/meta:baton` declara, e não há `Skill(meta:baton)` liberado. Ação: a tarefa do pulso do baton no `/loop` (SAC-435).
- **Verdes na 2.1.327 (medidos pelo juiz).** A sonda do `agent_id` da guarda de espera em fundo; o `permissions.deny` (340 casos, 0 divergentes, default e bypass); e o hook que não roda (exit 127), que segura a chamada com `onFailure: block` e falha aberto sem ele.

## Juiz

Um subagente opus independente, com mandato de refutar e critérios pré-registrados (CU1 a CU7 em `data/judge-verdicts.json`), deu 12 SUSTENTA e 4 EXAGERA. Conferiu as quatro cópias byte a byte contra o CHANGELOG oficial. Os quatro exageros (o `ask`, o freio de mensagens, a recusa do git e o fechamento da pergunta) foram reescritos com as superações dele (`C_SUPERACAO_20261118_*`). `judge-verdict-check.sh`: rc 0, 0 recusados.

**Aufhebung:** caem três nós da r24 (`external_edges` SUPERSEDES): as versões de quem serve, a pergunta da subida do SDK (alvo ultrapassado) e a guarda de deriva verde. Seguem valendo: a bancada do deny (re-medida, igual), os mods e as sessões longas.

## NÃO-VERIFICADOS

- O `ask` de hook em sessão **interativa** sob bypassPermissions.
- Subagente retomado por mensagem de irmão passa a seguir as permissões da sessão e pode perguntar ou ser recusado (`data/2.1.327.txt` l.145; l.59 para modelo e esforço). Toca a orquestração por SendMessage.
- Pasta de mods que pergunta mais (`data/2.1.326.txt` l.237) e mods que não reescrevem mais as confirmações (`data/2.1.323.txt` l.78). O laboratório de mods da r24 não foi re-rodado.
- Recusas sem quem responda no revisor do CI e no bridge depois da subida (`data/2.1.326.txt` l.233, l.313, l.314).
- `push --force-with-lease` e `bash ops/pr-finalize.sh` dentro de agente isolado.
- Efeito do `/loop` sobre o baton em bypass e em default.
- Mensagem de outra sessão com prioridade «later» entrando no turno em curso (`data/2.1.327.txt` l.64): o item cita Remote Control e Desktop, que a casa não usa.
