---
title: Radar E3 r19 — o delta do Claude Code 2.1.311 contra o Onion
date: 2026-10-26
kg: docs/evolution/research/radar-E3-2026-10-26-r19/radar-E3-2026-10-26-r19.kg.yaml
run_id: "nenhum (sem Workflow: rodada conduzida por um subagente da sessão, com um juiz subagente independente)"
tokens: 213361
agents: 1
duration_min: 30
review_after: 2026-11-25
type: research
mode: cc-update
---

> **Projeção do grafo, nunca fonte.** `tokens` é só o juiz (213.361, 101 chamadas, 12,2 min, medidos pelo harness);
> os da rodada, que rodou como subagente da sessão, não ficaram expostos a ela. `agents: 1` é o juiz.

## O que mediu

A rodada mediu 1 versão, a 2.1.311, com 92 itens (95 linhas). A baseline era 2.1.310; disco e processo estão em
2.1.311. O /chat do bridge está no SDK 0.3.310 (CLI embutido 2.1.310) e o revisor do CI no pin v1.0.262 da
claude-code-action (CLI 2.1.310): os dois uma versão atrás. O npm já publica o SDK 0.3.311 e a action já tem a
v1.0.263, que só troca versões (1 commit, 6 arquivos). O SDK do bridge é repo alheio e o deploy é do maestro:
nada foi subido, só registrado.

## O que toca a casa

- **Quem serve está uma versão atrás** (`E_HOST_NA_2_1_311_BRIDGE_E_REVISOR_NA_2_1_310_1026`). A razão medida para
  subir o SDK do bridge é a linha 11 (ordem do transcript em sessões de SDK): o bridge servido retoma sessões por
  `resume` (`src/chat-query-options.ts` linha 84). O novo escape do stream-json (linha 70) não muda o que a casa lê.
  O pin do revisor é paridade, porque ele está desligado. Ação: `Q_SUBIR_SDK_DO_BRIDGE_PARA_0_3_311_E_PIN_DO_REVISOR_PARA_V1_0_263_1026`
  (**SAC-259**).
- **core.hooksPath absoluto: a 2.1.311 não muda nada** (`E_HOOKSPATH_SEGUE_ABSOLUTO_NA_2_1_311_1026`). Nenhum item
  cita hooksPath ou hook de git. A worktree desta rodada, criada pelo processo 2.1.311, regravou o `.git/config` do
  checkout principal no mesmo nanossegundo, com o valor absoluto. As issues 85039 e 88747 do claude-code seguem
  abertas, e o trampolim dos hooks de git continua sendo o que torna o absoluto inofensivo. Nenhum gatilho de
  reabertura do WorktreeCreate próprio disparou.
- **Worktrees de agente** (`E_WORKTREE_DE_SUBAGENTE_NAO_SOME_COM_FILHO_EM_FUNDO_1026`): a linha 14 deixa de remover a
  worktree de um subagente enquanto um agente de fundo lançado por ele ainda trabalha nela. Isso protege o padrão da
  casa de worker isolado que lança outro agente, e não mexe no hooksPath.
- **Extensão do VS Code do host em 2.1.306** (`E_EXTENSAO_VSCODE_DO_HOST_NA_2_1_306_1026`, omissão apontada pelo
  juiz): cinco versões atrás, e o censo não a mede. Ação: `Q_EXTENSAO_VSCODE_ENTRA_NO_CENSO_OU_SOBE_1026` (**SAC-260**).
- **Compactação** (`E_CLAUDE_MD_E_MEMORIA_FRESCOS_APOS_COMPACTACAO_1026`, `E_INSTRUCTIONSLOADED_MEDE_A_RECARGA_POS_COMPACTACAO_1026`):
  o host passa a ver CLAUDE.md e memória frescos depois da compactação (linha 10). A casa tem o instrumento para
  medir isso: o log do InstructionsLoaded com `load_reason=compact`, que ainda não tem registro na 2.1.311. O maior
  item de lista do CLAUDE.md tem até 4.969 caracteres; o limiar que congelava (linha 5) não é público.
- **Sem efeito no core, medido:**
  - Linha 71, sufixo `[1m]`: a guarda de troca de modelo, executada como o runner, decide igual com e sem ele.
  - Linha 58, timeout do Bash com saída parcial: o PostToolUse anti-fail-open cala, e a sonda de tarefas de fundo
    segue achando o comando.
  - Linha 9, MCP em subagente: dois agentes declaram MCP; o general-purpose, que a casa usa como juiz, herda tudo.
  - SendMessage e Workflow: nenhum item os cita. Agent teams e Remote Control estão ligados no usuário, sem guarda
    do core que dependa deles.
  - Sem superfície: SubagentStop, watchdog de retry, DISABLE_COMPACT, sincronia de skills, runner auto-hospedado,
    ultrathink, daemon, catálogo de modelos, plugin-dir, sandbox, Claude Tag e Code Review gerenciado.
  - A guarda de deriva de binário (`cited_directive`) segue verde na 2.1.311.
- **Aufhebung:** SUPERSEDES de um nó da rodada anterior, o das versões de quem serve (host 2.1.310, bridge e revisor
  2.1.309), que caiu nas duas metades.

## Juiz

Juiz **independente**: um subagente `general-purpose` com modelo opus e effort high, não-fork, mandato REFUTAR. Os
critérios CU1 a CU5 foram gravados antes em `data/judge-verdicts.json`. Resultado: **13 SUSTENTA, 7 EXAGERA,
0 REPROVA**, 7 superações; `judge-verdict-check.sh` rc 0, nenhuma recusa.

- A cópia do CHANGELOG bate byte a byte com a oficial (`cmp` sem diferença), e as linhas citadas batem.
- **EXAGERA nos nós:** a prova do `resume` vinha do clone de desenvolvimento do bridge (SDK 0.3.232), não do servido;
  o maior item do CLAUDE.md foi contado sem o aninhamento (1.391 contra 4.969 caracteres); e eram dois agentes com
  MCP declarado, não três. Os três foram reescritos.
- **EXAGERA por omissão:** o InstructionsLoaded como instrumento da compactação (nó novo), a extensão do VS Code em
  2.1.306 (nó novo e pergunta), o Remote Control ligado no host e a sonda de tarefas de fundo, que lê o mesmo texto
  da linha 58 (absorvidos em nós existentes).
- Cada superação virou nó `C_SUPERACAO_20261026_*` com `TRACES_TO` ao nó julgado.
- A rodada re-mediu no vivo as alegações centrais do juiz antes de aplicar: a linha 84 do bridge servido (como a
  conta do serviço), o binário da extensão (2.1.306), o frontmatter do agent-creator-specialist e as 48 recargas
  por compactação.

## NÃO-VERIFICADOS

- Linha 5: se o item de lista longo do CLAUDE.md passa do limiar que congelava. O limiar não está no CHANGELOG.
- Linha 10: o efeito real da recarga fresca pós-compactação. Nenhuma compactação foi registrada na 2.1.311 ainda.
- Linha 7: se alguma sessão da casa roda em contexto padrão acima de 200K. Não foi medido por sessão.
- Linha 11 no /chat: o efeito só pode ser medido depois da subida do SDK (SAC-259).
- O uso real da extensão do VS Code no core.
- A versão do CLI no runner do revisor: só o pin a afirma; o revisor está desligado.
- Linhas de tela e de nuvem sem superfície no core (13, 18, 19, 27 a 29, 31, 33 a 35, 39 a 44, 46 a 50, 54 a 57,
  60 a 66, 69, 72, 73, 77, 78, 81, 83, 84, 86 a 89): não medidas uma a uma.
