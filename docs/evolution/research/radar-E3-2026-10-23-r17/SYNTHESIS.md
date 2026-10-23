---
title: Radar E3 r17 — o delta do Claude Code 2.1.309 contra o Onion
date: 2026-10-23
kg: docs/evolution/research/radar-E3-2026-10-23-r17/radar-E3-2026-10-23-r17.kg.yaml
run_id: "nenhum (sem Workflow: rodada conduzida por um subagente da sessão, com um juiz subagente independente)"
tokens: 139178
agents: 1
duration_min: 35
review_after: 2026-11-22
type: research
mode: cc-update
---

> **Projeção do grafo, nunca fonte.** `tokens` é só o juiz (139.178, 51 chamadas, 8,1 min, medidos pelo harness);
> os da rodada, que rodou como subagente da sessão, não ficaram expostos a ela. `agents: 1` é o juiz.

## O que mediu

A rodada mediu 1 versão, a 2.1.309, com 79 itens (82 linhas). A baseline era 2.1.308; disco e processo estão
em 2.1.309. O /chat do bridge segue no SDK 0.3.308 (CLI embutido 2.1.308), uma versão atrás do host, e o
revisor do CI segue no pin v1.0.258 da claude-code-action; o npm já publica o SDK 0.3.309 e a action já tem
v1.0.259 e v1.0.260, as duas pedindo ^0.3.309. Por ordem desta rodada, nada foi subido: só registrado.

## O que toca a casa

- **Quem serve está uma versão atrás** (`E_HOST_NA_2_1_309_BRIDGE_E_REVISOR_ATRAS_1023`): o /chat do bridge
  (SDK 0.3.308) e o revisor do CI (pin v1.0.258, `bun.lock` travado em 0.3.308) seguem na 2.1.308. A subida do SDK
  para 0.3.309 e do pin para v1.0.260 é `Q_SUBIR_SDK_DO_BRIDGE_E_PIN_DO_REVISOR_PARA_2_1_309_1023` (SAC-239). Ela
  executa a decisão da r16 e ganha um motivo a mais: o revisor posta texto do modelo sem sanitizar `@`
  (`E_REVISOR_POSTA_TEXTO_DO_MODELO_SEM_SANITIZAR_ARROBA_1023`), e a correção das menções indevidas (linha 41) só
  chega a ele com o pin novo.
- **O `sed -i` vira Bash comum** (linha 54). A guarda do arquivo de segredos segue barrando, mas a perna de
  leitura do grafo é surda ao `sed -i` em arquivo rastreado comum: o Edit recebe 988 bytes de aviso e o `sed -i`
  no mesmo arquivo recebe 0. A proposta é `Q_PERNA_DE_LEITURA_AVISA_NO_SED_I_EM_ARQUIVO_RASTREADO_1023` (SAC-240).
- **Worktree isolada** (linhas 10 a 12 e 58). A doutrina de orquestração prescreve `isolation: worktree`, e a casa
  roda as guardas com `LC_ALL=C`. Se a guarda endurecida recusa esse prefixo num agente isolado ainda está por
  medir: `Q_GUARDA_DE_ISOLAMENTO_ACEITA_O_PREFIXO_LC_ALL_DA_CASA_1023` (SAC-241).
- **Sem efeito no core, medido:** sandbox, deny e `--mcp-config` (o settings não os usa; o único `deny` é o do
  runner do convidado do /chat, que desabilita o Bash); transcripts com emoji cortado (3437 de 3437 parseiam com
  `jq`, e os leitores do core toleram linha quebrada); APCA na skill dataviz (o gate do core segue WCAG);
  CLAUDE.md aninhado (só existe o da raiz); `/add-dir` com skill homônima (o adopt efêmero passa a ver
  `<pasta>:<nome>`, efeito baixo). A guarda de deriva de binário (`cited_directive`) segue verde na 2.1.309.
- **O censo** zera `scriptPath` numa worktree só com a raiz absoluta ou sem argumento; com `.` conta 8
  (`E_CENSO_ZERA_SCRIPTPATH_SO_COM_RAIZ_ABSOLUTA_1023`). O `/meta:cc-update` usa `.`, mas a bancada usa a raiz
  absoluta. A medição foi comentada na SAC-219.
- **Aufhebung:** SUPERSEDES de dois nós da r16, a paridade das três superfícies e o censo que "zera numa worktree".

## Juiz

Juiz **independente**: um subagente `general-purpose` com modelo opus, não-fork, mandato REFUTAR. É a correção da
falha da r16. Os critérios CU1 a CU5 foram gravados antes em `data/judge-verdicts.json`. Resultado: **10 SUSTENTA,
2 EXAGERA, 1 REPROVA**, 3 superações e 6 omissões; `judge-verdict-check.sh` rc 0.

- A cópia do CHANGELOG bate byte a byte com a oficial, e as versões, o censo, o env-guard e o `jq` se reproduzem.
- **REPROVA:** o nó de worktree dizia "só exemplo em comentário", mas a doutrina prescreve a worktree isolada em
  três artefatos. O nó foi reescrito.
- **EXAGERA:** o nó do `sed -i` afirmava que a perna de leitura dispara; não dispara em arquivo comum. O nó de
  permissões dizia que o core não usa deny; usa, no `ops/chat-runner.sh`. Os dois foram reescritos.
- Cada superação virou nó `C_SUPERACAO_20261023_*` com `TRACES_TO` ao nó reprovado. As omissões das linhas 41 e 29
  viraram nós. A da linha 15 fica abaixo.
- Forma: o juiz deu às superações classes livres (`superficie_omitida` e outras), e o checador aceita só
  `entrega|nenhuma`. A rodada normalizou para `entrega` e manteve o rótulo original entre parênteses no `o_que`.

## NÃO-VERIFICADOS

- Se a guarda de isolamento endurecida da 2.1.309 recusa `LC_ALL=C bash …` dentro de um agente isolado. Não foi
  medido porque criar uma worktree de agente regrava o `core.hooksPath` compartilhado (SAC-241).
- Linha 15 (ctrl+enter re-executava hooks de UserPromptSubmit com a mensagem na fila). Pode ter duplicado linhas
  do beacon antes da correção; não foi medido no `session-lifecycle.jsonl`, e não há ação no core.
- A versão exata do CLI no runner do CI: lida pelo `bun.lock` da action, não num log de job (segue estacionada,
  `Q_REVISOR_NO_PIN_1_0_258_PROVADO_NUM_PR_COM_A_LABEL` da r16).
- Os itens de VSCode, Cloud sessions, Claude Tag, Code Review, Windows, macOS e self-hosted runner: sem superfície
  no core (host Linux, revisor próprio no CI), não medidos um a um.
