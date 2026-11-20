---
title: Radar E3 r26 — o delta do Claude Code 2.1.328 a 2.1.329 contra o Onion
date: 2026-11-20
kg: docs/evolution/research/radar-E3-2026-11-20-r26/radar-E3-2026-11-20-r26.kg.yaml
run_id: "nenhum (sem Workflow: rodada conduzida por um agente de execução do core, com um juiz subagente independente)"
tokens: 182619   # só o juiz; o contexto do agente coordenador não tem contador
agents: 1
duration_min: 30   # do esqueleto (17:40 UTC) ao fim da aplicação do juiz
review_after: 2026-12-20
type: research
mode: cc-update
---

# Radar E3 r26 — o delta do Claude Code 2.1.328 a 2.1.329

Esta é a rodada 26 do radar do Claude Code. O radar é o eixo E3 do radar de mundo, que mede o que cada versão nova do Claude Code muda no Onion.

**Versões:** a baseline estava na 2.1.327. O disco e o processo estão na 2.1.329. O delta tem duas versões com seção, com 274 itens copiados byte a byte em `data/`. O juiz conferiu as duas cópias contra o CHANGELOG oficial, com diff vazio. O grafo tem 20 nós: 2 do esqueleto, 10 da rodada, 4 omissões medidas pelo juiz e 4 superações.

## O que toca a casa (medido no vivo)

- **Quem serve.** O host está na 2.1.329. O bridge segue na 2.1.323 (SDK 0.3.323), 5 versões com seção atrás. O revisor do CI segue na 2.1.322 (pin `anthropics/claude-code-action@d5f7970a`, action v1.0.272), 6 versões atrás. A tarefa da subida do SDK e do pin do revisor (SAC-432), aberta na r25, não andou, e os alvos subiram para o SDK 0.3.329 e a action v1.0.284. O comentário com os alvos novos já está na SAC-432.
- **Guarda de deriva do cited-directive.** Segue reprovando na 2.1.329, e o parser de injeção segue com o mesmo comportamento. Desta vez a troca de locais pegou também o `n` (`let o=e.matchAll(rkr),r=…,g=[]`). Com isso, o curinga só para `r` e `s`, que a tarefa do curinga das locais no molde (SAC-433) pedia, reprovaria de novo. O escopo da SAC-433 passou a ser todas as locais, e o comentário foi feito na issue. A `channel_session` segue verde.
- **Code Mode e `onFailure`.** Na 2.1.329, um hook PreToolUse que dá erro deixa de recusar a chamada feita por script do Code Mode (`data/2.1.329.txt` l.108). Isso não abre buraco nos vetos da casa: os 9 vetos PreToolUse já declaram `onFailure: block`, e os 2 sem a chave nunca vetam. A 2.1.328 l.4 leva o `onFailure: block` aos hooks `mcp_tool`, e a casa não tem nenhum (35 hooks, todos `command`). O Code Mode não está ligado neste host. Por isso não foi medido se os vetos disparam nas chamadas feitas de dentro de um script. Ação: a tarefa da sonda dos vetos no Code Mode (SAC-492).
- **Sonda de tarefas de fundo.** As mudanças em `background_tasks` (Monitor listado como `monitor`) e no `/tasks` não tocam a sonda da casa (`data/2.1.329.txt` l.113, l.114). Ela não lê `background_tasks`, e o vocabulário do transcript que ela lê segue presente nas entradas 2.1.329.
- **Mensagens entre sessões.** Este host aceita mensagens de outras sessões (`crossSessionInbound: accept`). A retenção descrita no delta é da nuvem, do `-p` e do VS Code. O `/list-agents` que mudou é o comando, e a casa usa a ferramenta `ListAgents`.
- **Verdes na 2.1.329 (medidos pelo juiz):**
  - a guarda de espera em fundo em subagente;
  - os campos de origem do prompt (`origin.kind`, `promptSource`, `isMeta`), sem `promptSource` novo;
  - o `permissions.deny`: 75 regras, 362 casos, 0 divergentes, em default e em bypass.
- **Configuração que a casa não usa.** Hooks em managed settings, PermissionRequest, `CLAUDE_CODE_FORK_SUBAGENT=0`, `autoCompactWindow`, status line, sandbox, `allowManagedModsOnly`, a retomada de chamada adiada por hook e o `max_tokens` atrás de gateway.

## Juiz

O juiz foi um subagente opus independente, lançado com `effort: high`, com mandato de refutar e critérios pré-registrados (CU1 a CU7, em `data/judge-verdicts.json`). Resultado: 8 SUSTENTA, 4 EXAGERA e 0 REPROVA. Os exageros eram citação de linha errada (2), régua de defasagem misturada (1) e fechamento da pergunta antes das omissões (1). Os quatro foram corrigidos com as superações dele (`C_SUPERACAO_20261120_*`). `judge-verdict-check.sh` saiu rc 0, com 0 recusados.

Uma afirmação do juiz foi refutada pela rodada: a de que o `effort: high` nunca chega ao Agent tool. Ele contou só o transcript da sessão principal. A chamada que o lançou traz `"model":"opus"` e `"effort":"high"` (`E_EFFORT_DO_JUIZ_SAI_NA_CHAMADA_DO_AGENT_1120`).

**Aufhebung:** caem quatro nós da r25 (`external_edges` SUPERSEDES):

- as versões de quem serve;
- a pergunta da subida (alvo ultrapassado);
- a deriva do cited-directive, porque agora o `n` também mudou;
- a pergunta do curinga, porque `r` e `s` não bastam.

O juiz manteve as quatro. A `channel_session`, o deny e a sonda do agent_id seguem verdes e ganham nó com a data nova, sem superação.

## NÃO-VERIFICADOS

- Se os vetos PreToolUse disparam nas chamadas de um script do Code Mode (SAC-492).
- A metade da sessão principal da sonda do agent_id: um Bash em fundo sem `agent_id` deve passar.
- Se o `effort: high` pedido de fato vigorou dentro do juiz.
- Tarefas agendadas salvas por versões anteriores que precisam ser re-agendadas em sessão nova, e o «Exit and stop tasks» (`data/2.1.329.txt` l.97, l.101). Isso pode tocar o batimento de reserva do baton no `/loop`, e o efeito não foi medido.
- Painéis de teammate iniciados por `/bin/sh` e o lock ao iniciar teammates em processo (`data/2.1.329.txt` l.102; `data/2.1.328.txt` l.118). O host tem `teammateMode: auto`.
- A compactação automática que passa a reconstruir o system prompt (`data/2.1.328.txt` l.17).
- O aviso do diálogo de confiança sobre onde os hooks são declarados (`data/2.1.329.txt` l.3), que muda o que o adotante vê na primeira abertura.
- A mensagem do core retida por uma sessão de nuvem quando o remetente está em bypass (`data/2.1.328.txt` l.5), e o efeito em adotante com outro `crossSessionInbound`.
