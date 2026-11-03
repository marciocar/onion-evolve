---
title: Radar E3 r22 — o delta do Claude Code 2.1.316 e 2.1.317 contra o Onion
date: 2026-11-03
kg: docs/evolution/research/radar-E3-2026-11-03-r22/radar-E3-2026-11-03-r22.kg.yaml
run_id: "nenhum (sem Workflow: rodada conduzida pela sessão do core, com um juiz subagente independente)"
tokens: 202074
agents: 1
duration_min: 60
review_after: 2026-12-03
type: research
mode: cc-update
---

# Radar E3 r22 — o delta do Claude Code 2.1.316 e 2.1.317

**Versões:** a baseline estava na 2.1.314; o disco e o processo estão na 2.1.317. O delta tem duas versões,
com 142 itens (55 na 2.1.316 e 87 na 2.1.317), copiados byte a byte em `data/`. Os tokens do frontmatter são
os do juiz; a rodada da sessão não foi medida em tokens.

## O que toca a casa (medido no vivo)

- **Quem serve está atrás.** O host está na 2.1.317, o revisor do CI na 2.1.314 (pin v1.0.265) e o bridge na
  2.1.310 (SDK 0.3.310), seis versões publicadas atrás. Ação: `Q_SUBIR_SDK_DO_BRIDGE_PARA_0_3_317_E_PIN_DO_REVISOR_PARA_V1_0_267_1103`
  (**SAC-265**, a tarefa de subir o SDK do bridge para 0.3.317 e o pin do revisor para v1.0.267). Ela supera a
  SAC-262 da rodada anterior. O deploy do bridge é do maestro.
- **O esforço dos subagentes.** Desde a 2.1.317, o agente cujo modelo difere do da sessão roda no esforço padrão
  do modelo dele. No core nenhum agente declara `effort`; numa sessão opus mudam os 43 sonnet. Os workflows não
  mudam, porque declaram o esforço por chamada. Ação: `Q_AGENTES_DECLARAM_O_ESFORCO_1103` (**SAC-266**, a tarefa
  de decidir se esses agentes declaram o esforço).
- **Configurações gerenciadas sem aprovação.** Desde a 2.1.316, as configurações da organização aplicam sem
  pedir. Elas chegaram às sessões de teste A2A e hoje ligam os canais (`channelsEnabled: true`), um caminho de
  entrada de mensagem que o pré-registro do teste não lista. Sem ação nova nesta rodada; o dado vai ao teste A2A.
- **A dica de retomada perde as flags.** Na 2.1.317, a dica de saída da sessão de teste A2A veio sem nenhuma flag
  de isolamento; o juiz achou no binário que um valor de flag vazio (`--tools ""`) faz a dica descartar todas.
  Ação: `Q_CARD_DO_TESTE_PROIBE_RETOMAR_PELA_DICA_1103` (**SAC-267**, a tarefa de o card proibir retomar pela dica).
- **O MCP do Chrome fura o `--strict-mcp-config`.** Não é item do delta: medido na 2.1.317, com
  `claudeInChromeDefaultEnabled` ligado. Curado no teste A2A com `--no-chrome`.
- **Mensagem a agente em fundo.** Na 2.1.317, um `SendMessage` a um agente em fundo manda o comando dele para o
  fundo sem pará-lo; a resposta de um agente no meio de um gate longo não prova o gate.
- **Limpeza de transcripts.** A limpeza volta a rodar onde o `--setting-sources` a pulava (o `ops/chat-runner.sh`
  o usa); o custo de runs antigos, que a casa recupera do journal, pode sumir com os transcripts.
- **Sem superfície:** o `onFailure` para callbacks do SDK (o bridge corta os hooks em vez de registrá-los), o fim
  do fast mode do Opus 4.8, os hooks PowerShell, gateway, nuvem, Claude Tag, runner e Windows. A extensão do VS Code
  do host segue na 2.1.306, e o Remote Control só toca o host.
- **Guarda de deriva de binário:** `cited_directive` rc 0 na 2.1.317.

## Juiz

Subagente opus independente, não-fork, com critérios pré-registrados (`data/judge-verdicts.json`): **10 SUSTENTA,
5 EXAGERA, 2 REPROVA**, 7 superações, `judge-verdict-check` rc 0. Os exageros corrigidos: a conta de versões
(seis publicadas, não sete), o esforço (só para modelo diferente do da sessão), a fonte das configurações
gerenciadas, e o grep sem `-E`. As reprovações: o nó do VS Code da r21 caiu sem sucessor, e seis omissões do
delta. Cada superação virou nó `C_SUPERACAO_20261103_…`.

**Aufhebung:** SUPERSEDES de quatro nós da r21 (as versões de quem serve, a pergunta da subida, a extensão do
VS Code e a guarda de deriva).

## NÃO-VERIFICADOS

- O efeito na qualidade dos agentes que perderam o esforço da sessão: não medido.
- O Read sem o aviso de «arquivo inalterado» (2.1.317): só muda o custo de reler; não medido em tokens.
- O subagente que herdou o modelo do pai e voltava ao principal ao acordar (2.1.316): sem caso reproduzido.
- O «Prompt is too long» depois da compactação com CLAUDE.md grande e alterado (2.1.317): o CLAUDE.md do core tem
  cerca de 26 KB; sem caso reproduzido.
- O aviso antes de enviar o e-mail da conta pela rede (2.1.317): nenhum caminho de shell do core o envia, pelo
  juiz; não exercitado.
- O `/chat` do bridge e o MCP do Chrome: o usuário do serviço não tem a chave, mas o SDK não foi medido aqui.

## Valeu a pena

24 nós por cerca de 202 mil tokens do juiz, ou 8,4 mil por nó. Três tarefas novas, uma superação de tarefa
antiga e um achado de isolamento (as configurações gerenciadas ligando canais) que o teste A2A não via.
