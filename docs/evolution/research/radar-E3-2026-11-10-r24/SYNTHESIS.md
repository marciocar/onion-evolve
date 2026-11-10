---
title: Radar E3 r24 — o delta do Claude Code 2.1.319 a 2.1.322 contra o Onion
date: 2026-11-10
kg: docs/evolution/research/radar-E3-2026-11-10-r24/radar-E3-2026-11-10-r24.kg.yaml
run_id: "nenhum (sem Workflow: rodada conduzida pela sessão do core, com um juiz subagente independente)"
tokens: 299955   # só o juiz; o contexto da sessão coordenadora não tem contador
agents: 1
duration_min: 60   # do esqueleto (23:20 UTC) ao fim da aplicação
review_after: 2026-12-10
type: research
mode: cc-update
---

# Radar E3 r24 — o delta do Claude Code 2.1.319 a 2.1.322

Rodada 24 do radar do Claude Code (eixo E3 do radar de mundo: a medição do que cada versão nova do Claude Code muda no Onion).

**Versões:** a baseline estava na 2.1.318; o disco e o processo estão na 2.1.322. O delta tem três versões publicadas (a 2.1.320 não saiu), com 265 itens copiados byte a byte em `data/`. O grafo tem 24 nós: 2 do esqueleto, 14 da rodada, 1 pergunta nova e 7 superações do juiz.

## O que toca a casa (medido no vivo)

- **O Fable atual é vetado pela nossa guarda.** Desde a 2.1.321, `/model fable` resolve para `claude-fable-5-2`, que não está em `session_models` do eixo E6. Medido no binário real e no hook real: rc 2. É a repetição do caso do Opus 5.5 em 2026-10-03. A inclusão espera uma comparação com gabarito dentro do Onion, por ordem do maestro: `Q_E6_ADMITE_O_FABLE_5_2_NO_LINEUP_1110`.
- **Os vetos por exit 2 têm mapa, e o mapa tem furos.** Barram palavra com aspas, caminho absoluto, `env`, `timeout` e substituição no prefixo. Não barram prefixo com quebra de linha dentro de valor citado (`merge-gate` e `plugin-write`), nome de arquivo em ANSI-C (`env-guard`), `xargs`, `env --chdir` e `sed` com `w`. O próprio veto se declara contenção de acidente, não fronteira. Ação: `Q_CURAR_O_TOKENIZADOR_DOS_VETOS_1110`.
- **Bancada do `permissions.deny`:** 340 casos, 0 divergentes na 2.1.322, nas fases default e bypass.
- **Mods.** O veto de escrita em `.claude/skills` já era a única barreira na carga da sessão seguinte desde a 2.1.318. A 2.1.321 acrescenta a carga no meio da sessão, ainda sem medida. Ação: `Q_RERODAR_O_LAB_DE_MODS_NA_2_1_322_1110`.
- **Quem serve:** host na 2.1.322, revisor do CI em dia (action v1.0.271), bridge na 2.1.319 (SDK 0.3.319), duas versões publicadas atrás. Ação: `Q_SUBIR_SDK_DO_BRIDGE_PARA_0_3_322_1110`; o deploy é do maestro.
- **Sessões longas:** nove executáveis seguem atrasados. Duas conversas na 2.1.318 não têm as correções de permissão da 2.1.319; quem está na 2.1.319 só não tem as da 2.1.321. O reinício é de quem é dono de cada sessão.
- **Sandbox:** a curadoria é a única sessão medida com sandbox e roda a 2.1.319; a correção da 2.1.321 sobre Bash de leitura fora do sandbox não a alcança.
- **`/loop` sem intervalo** agora termina se o turno acabar sem reagendar. Nenhuma peça do core depende da batida de reserva.
- **PostToolUse em chamada interrompida:** o único hook do core cabe com folga nos 10 segundos.
- **Sem superfície no core:** MCP tasks, `afkTimeoutMs`, auto mode por gateway, `--settings` do remote-control, gateway, runner, nuvem, VS Code, Claude Tag e Code Review.
- **Guardas de deriva de binário:** `cited_directive` e `channel_session` com rc 0 na 2.1.322.

## Juiz

Subagente opus independente, não-fork, com critérios pré-registrados (`data/judge-verdicts.json`, CU1 a CU6): 21 vereditos, **13 SUSTENTA, 4 EXAGERA, 4 REPROVA**, 7 superações, `judge-verdict-check` rc 0 e nenhuma reprovação recusada. Cópias e citações batem com o CHANGELOG.

- **Reprovações:** a afirmação de que os vetos resistiam à classe (virou o mapa acima e abriu a pergunta da cura); a versão da sessão da curadoria; os nós da r23 que caíram e não estavam superados; as omissões do delta.
- **Exageros corrigidos:** duas versões do SDK, não três; a datação do item dos mods; a contagem das sessões; o fecho prematuro da pergunta da rodada.

Cada superação virou nó `C_SUPERACAO_20261110_…` com aresta TRACES_TO ao nó superado.

**Aufhebung:** SUPERSEDES de sete nós da r23: as versões de quem serve, a pergunta da subida, a guarda de deriva, o binário apagado, as correções sem terminal, a dica do `--continue` e a extensão do VS Code. As perguntas de subida de SDK e pin já cumpridas, das rodadas r19 a r23, foram fechadas com o carimbo da medição.

## NÃO-VERIFICADOS

- A re-rodada do laboratório de mods na 2.1.322, e se a carga no meio da sessão vale para mod escrito pelo Claude.
- As fases sandbox e flows da bancada do `permissions.deny`, e regra deny com palavra entre aspas, caso que a bancada não tem.
- A correção da saída perdida de comando de fundo instantâneo, contra a sonda de tarefas de fundo.
- A saída grande de hook apontando outro hook.
- Subagente em worktree com sandbox carregando skills.
- 2.1.321: comandos Bash na pasta errada quando vários saem juntos; o relatório de subagente em fundo perdido em compactação; o aviso de workflow parado. Têm superfície na casa, sem caso reproduzido.

## Valeu a pena

24 nós e quatro tarefas propostas. O achado de mais peso veio do juiz: a rodada afirmou que os vetos resistiam à classe dos bypasses, e ele achou as formas que passam.
