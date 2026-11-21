---
title: Radar E3 r27 — o delta do Claude Code 2.1.330 contra o Onion
date: 2026-11-21
kg: docs/evolution/research/radar-E3-2026-11-21-r27/radar-E3-2026-11-21-r27.kg.yaml
run_id: "nenhum (sem Workflow: rodada conduzida por um agente de execução do core, com um juiz subagente independente)"
tokens: 174460   # só o juiz; o contexto do agente coordenador não tem contador
agents: 1
duration_min: 75   # do esqueleto à aplicação do juiz; as duas guardas de binário esperaram a fila de carga
review_after: 2026-12-21
type: research
mode: cc-update
---

# Radar E3 r27 — o delta do Claude Code 2.1.330

Esta é a rodada 27 do radar do Claude Code. O radar é o eixo E3 do radar de mundo. Ele mede o que cada versão nova do Claude Code muda no Onion.

**Versões:** a baseline estava na 2.1.329. O disco e o processo estão na 2.1.330. O delta tem uma versão, com 142 itens copiados byte a byte em `data/2.1.330.txt`. O juiz conferiu a cópia contra o CHANGELOG oficial, e o diff saiu vazio. O grafo tem 17 nós: 2 do esqueleto, 12 da rodada, 2 omissões medidas pelo juiz e 1 superação.

## O que toca a casa (medido no vivo)

- **Quem serve.** O host está na 2.1.330. O bridge segue na 2.1.323 (SDK 0.3.323), 6 versões atrás. O revisor do CI segue na 2.1.322 (action v1.0.272), 7 versões atrás. As duas contas usam só as versões que têm seção no CHANGELOG. A subida do bridge para o SDK 0.3.330 já está no PR onion-bridge #112, aberto, à espera do merge e do deploy do maestro. A rodada só registra isso. O pin do revisor não andou, e o alvo agora é a v1.0.286. Tarefa: a subida do SDK do bridge e do pin do revisor (SAC-432), em andamento, comentada com os alvos novos.
- **O censo conta README como agente.** A linha do censo «(sem model)=9» é falsa. Os 9 são os README das categorias. Os 51 agentes da casa declaram model. Ação: corrigir a contagem e pôr um caso na bancada (`Q_CENSO_EXCLUI_README_DA_CONTAGEM_DE_AGENTES_1121`). O Linear recusou a criação da issue («usage limit exceeded»). Por isso fica só o nó.
- **Fallback de modelo do subagente** (`data/2.1.330.txt` l.110). Na casa, só os agentes embutidos lançados sem model e os forks recebem o fallback. Os 51 agentes e o juiz do cc-update declaram model. Nenhuma skill tem model no frontmatter (l.109).
- **Guarda de deriva do cited-directive.** Segue reprovando, pelo mesmo motivo da 2.1.329. Só os nomes de função mudaram. As locais seguem `o`, `r` e `g`, e as duas regex seguem iguais ao molde. O comportamento do motor é o mesmo. A tarefa do curinga de todas as locais no molde (SAC-433) segue valendo e foi comentada. A `channel_session` segue verde.
- **Deny.** O `permissions.deny` segue valendo na 2.1.330 em default e em bypass. A bancada rodou 75 regras e 362 casos, com 0 divergentes. Isso inclui a mudança do `rm` na raiz, na home e na pasta de trabalho (l.105).
- **Atribuição de commit** (l.46). A correção vale por inteiro: a atribuição está no settings do projeto, e a exceção da correção é só a de managed settings.
- **`/loop` e tarefa agendada de 7 para 30 dias** (l.104). Nenhum texto da casa fica defasado: o modo `/loop` do baton não promete prazo.
- **Várias sessões ao mesmo tempo** (l.14, l.15, l.29, l.30). As correções do ExitWorktree, do settings gravado ao mesmo tempo e dos plugins que sumiam protegem o regime do host, que tem 57 worktrees. Elas não mudam texto nem guarda.
- **Verde na 2.1.330, medido pelo juiz:**
  - a guarda de espera em fundo em subagente, que ainda recebe o `agent_id`;
  - os nomes de modelo da casa, que estão no binário (l.108).
- **O que a casa não usa:** env gravada por SessionStart, servidor MCP declarado por subagente, `deniedMcpServers`, hook de prompt, self-hosted runner, `AbovePrompt`, link em CLAUDE.md com comentário HTML e agente de nome duplicado. A volta da nova tentativa no limite de `max_tokens` (l.89) também não pega a casa: nenhuma superfície fixa `max_tokens`.

## Juiz

O juiz foi um subagente opus independente, lançado com `effort: high`, com mandato de refutar e com os critérios CU1 a CU7 pré-registrados em `data/judge-verdicts.json`. O resultado foi 11 SUSTENTA, 1 EXAGERA e 0 REPROVA. O `judge-verdict-check.sh` saiu rc 0, com 0 vereditos recusados.

O exagero estava no nó do que a casa não usa:

- O `claude -p` em disco cheio (l.44) é usado, sim: a bancada do deny roda `claude -p` com a saída num arquivo. Ela já reprova um caso sem resultado, então a correção só troca um rc 0 calado por rc 1.
- A razão dada para a volta do retry de `max_tokens` estava errada. O nó foi corrigido com a superação do juiz (`C_SUPERACAO_20261121_CLAUDE_P_DA_BANCADA_DO_DENY`).

O juiz também apontou que a rodada repetiu uma omissão da r26: a re-sonda do `agent_id`, que o cabeçalho do hook pede a cada `/meta:cc-update`. Ele mediu a sonda, e ela entrou como nó. Ele lembrou ainda que a worktree estava 1 commit atrás da `origin/main`, e a rodada fez rebase antes do PR.

**Aufhebung:** caem dois nós da r26 (`external_edges` SUPERSEDES):

- as versões de quem serve;
- a pergunta da subida, cujo alvo foi ultrapassado.

O juiz manteve as duas superações. A deriva do cited-directive da r26 **não** cai, porque o estado dela segue valendo. O nó de configuração da r26 também não cai: só o narrative dele envelheceu com a l.89.

## NÃO-VERIFICADOS

- **Code Mode** (l.32 a l.37, l.101 a l.103). A casa tem exatamente as condições da l.32: regras deny de Read e 7 rules com `paths:`. Mas o Code Mode está desligado neste host. Segue com a tarefa da sonda dos vetos no Code Mode (SAC-492).
- A metade da sessão principal da sonda do `agent_id`: um Bash em fundo sem `agent_id` deve passar.
- O efeito do novo «quem não pode responder é recusado» do `rm` (l.105) num subagente de fundo.
- Uma sessão real caída no fallback (`claude-sonnet-5-5`) lançando um fork (l.110).
- Se há um pulso do baton armado antes da 2.1.330, que ainda morre no 7º dia (l.104).
- O efeito da correção da atribuição (l.46), isto é, se o turno deixou de encerrar cedo.
- A entrada por organização do Admin Console (l.3), que pode trazer managed settings com atribuição.
