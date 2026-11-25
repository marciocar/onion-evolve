---
title: Radar E3 r28 — o delta do Claude Code 2.1.331 e 2.1.332 contra o Onion
date: 2026-11-25
kg: docs/evolution/research/radar-E3-2026-11-25-r28/radar-E3-2026-11-25-r28.kg.yaml
run_id: "nenhum (sem Workflow: rodada conduzida por um colega de time do core, com um juiz subagente independente)"
tokens: 315324   # o juiz (241.443) e a sonda do agent_id (73.881); o contexto do agente coordenador não tem contador
agents: 2
duration_min: 31   # do esqueleto à aplicação do juiz; o juiz sozinho levou 18 min
review_after: 2026-12-25
type: research
mode: cc-update
---

# Radar E3 r28 — o delta do Claude Code 2.1.331 e 2.1.332

Esta é a rodada 28 do radar do Claude Code. O radar é o eixo E3 do radar de mundo. Ele mede o que cada versão nova do Claude Code muda no Onion.

**Versões:** a baseline estava na 2.1.330. O disco está na 2.1.332, que chegou às 01:34 UTC de hoje. O processo da sessão está na 2.1.331. O delta tem duas versões, com 285 itens copiados byte a byte em `data/2.1.331.txt` (135) e `data/2.1.332.txt` (150). O juiz conferiu as duas cópias contra o CHANGELOG oficial, e o diff saiu vazio. O grafo tem 24 nós (teto 25): 2 do esqueleto, 13 da rodada, 2 nós para as 3 omissões medidas pelo juiz, 1 pergunta nova e 6 superações.

Como o processo está na 2.1.331, a rodada não mediu a capacidade da 2.1.332 pela própria sessão. Ela mediu pelo **motor real das duas versões**, chamado lado a lado com a Messages API falsa da bancada do deny. A sonda do `PreSkillShellCommand` está em `data/`; as sondas do deny ficam no registro privado do core (ver o primeiro achado).

## O que toca a casa (medido no vivo)

- **O deny da casa não segura em bypass.** Este é o achado mais grave da rodada. O juiz o achou, e a rodada o confirmou de forma independente. A casa roda em `bypassPermissions`. O deny da casa não segura em bypassPermissions sob certas formas de comando Bash, medido em 2.1.330–2.1.332. Os hooks PreToolUse seguem barrando merge e push para a main. Detalhes e reprodução ficam fora do repositório público (registro privado do core, 25/11), até a coordenação com o fornecedor.

  Um push acidental de sonda criou um branch sem conteúdo novo, já apagado.

  Cai o nó da r27 que dava o deny por valendo em bypass. Ação: SAC-551 (`Q_DENY_SEGURA_EM_BYPASS_1125`).
- **Deny lento em comando longo** (`data/2.1.332.txt` l.15). Este item pega a casa. Com o deny da casa (75 regras, 52 com dois ou mais curingas), julgar um comando de 150 mil caracteres leva 33,5 s na 2.1.331 e 1,6 s na 2.1.332. Com 50 mil caracteres, leva de 5 a 11 s contra 1,3 s. A recusa foi medida em default. A casa não tem hook com condição `if`.
- **Hooks que imprimem muito** (l.16 e l.17). Estes itens não pegam a casa hoje:
  - a maior saída medida de hook foi 1.461 bytes (session-currency-check). Os dois hooks de Stop, rodados pelo juiz contra transcripts de 179 MB, imprimem 0 bytes;
  - os 4 hooks sem timeout fora do PreToolUse imprimem no máximo 462 bytes;
  - os três bloqueios disparados por comandos de 100 mil caracteres respondem com 274 a 436 bytes e não ecoam o comando;
  - o corte em cerca de 50 mil caracteres fica longe disso.
- **`PreSkillShellCommand`** (l.4). Este é o achado de maior alcance:
  - na 2.1.332, um hook do evento que sai 2 recusa a diretiva antes de ela rodar. A entrada traz `tool_input.command`, o nome e a origem do comando;
  - **na 2.1.331 e na 2.1.332, os hooks `PreToolUse` de Bash não são chamados para a diretiva.** O `permissions.deny` recusou a diretiva testada, mas não segura toda forma dela em bypass (detalhes fora do repositório público). Ou seja, os guardas da casa que só existem como hook (env-guard, moat-gate, merge-gate, direct-provider-api, protect-main e os demais) não veem a diretiva;
  - hoje as 28 diretivas da casa (em 14 arquivos: 12 comandos e 2 skills) são escritas pela própria casa, e o canal de conversa já desliga diretiva e hook juntos. O buraco importa para comando ou skill de fora: de adotante, de plugin ou de servidor MCP (l.3);
  - **na 2.1.331, o settings que nomeia o evento é ignorado em silêncio no `claude -p`.** Não há diálogo, e a diretiva roda. Na sessão interativa, o juiz mediu o diálogo «Settings Warning … Unknown hook event "PreSkillShellCommand"», com as opções Continue, Fix e Exit.

  Ação: ligar os guardas também ao `PreSkillShellCommand`, com versão mínima declarada (SAC-552, `Q_GUARDA_DE_DIRETIVA_POR_PRESKILLSHELLCOMMAND_1125`).
- **Ctrl+V de imagem na VPS** (l.92). A 2.1.332 só melhorou a mensagem. Os dois pacotes que ela nomeia já estão instalados na VPS. Mesmo assim não há display, e a área de transferência lida é a do servidor, não a do Windows do maestro. A colagem de imagem pelo terminal não alcança a VPS headless.

  Ação: declarar e medir o caminho da imagem, que pode ser o app pelo Remote Control ou o arquivo enviado e citado por `@caminho` (SAC-553, `Q_CAMINHO_DE_IMAGEM_PARA_AS_SESSOES_DA_VPS_1125`).
- **Quem serve.**
  - O host está na 2.1.332 em disco. Das 17 sessões e colegas de time vivos, 6 rodam a 2.1.330, 8 a 2.1.331 e 3 a 2.1.332.
  - O bridge segue na 2.1.323 (SDK 0.3.323), 8 versões atrás. O PR onion-bridge #112 segue aberto e mira 0.3.330, então precisa de novo alvo (0.3.332).
  - O revisor do CI subiu desde a r27: está na 2.1.330 (action v1.0.286), e o alvo é a v1.0.290.

  Tarefa: a subida do SDK do bridge e do pin do revisor (SAC-432), comentada com os alvos novos e com o título corrigido.
- **Colega de time em painel.**
  - Esta rodada roda como colega de time: uma sessão própria, que nasceu às 01:38 com o binário da sessão líder (2.1.331), 3 minutos depois de a 2.1.332 chegar ao disco.
  - O argv dela traz `--agent-id`, mas o JSON do hook não traz o campo `agent_id`, então a guarda de espera em fundo não a veta. E o aviso de fim da tarefa de fundo chegou a ela.
  - A sonda do `agent_id` em subagente de verdade foi refeita: um subagente sem nome foi recusado pela guarda. As duas metades estão verdes na 2.1.331.
  - Um colega de time não pode lançar outro colega com nome («the team roster is flat»). Por isso o juiz desta rodada é subagente sem nome.
- **Guarda de deriva do cited-directive.** Segue vermelha na 2.1.332 pelo mesmo motivo de antes: só os nomes de função mudaram, e as regex da diretiva são as mesmas. A `channel_session` segue verde. Quem mediu foi o juiz, e a tarefa SAC-433 segue valendo.
- **Reenvio do CLAUDE.md em worktree** (l.24). Pega pouco a casa: só 5 das 57 worktrees ficam em `.claude/worktrees`.
- **O que a casa não usa:** prefixo `oat02` do runner, `isSynthetic` do SDK, PushNotification, OpenTelemetry, `apiKeyHelper`, hook `PermissionDenied`, auto-update de marketplace gerenciado, nome `computer-use`, regra de permissão no Agent ou no Skill e `SubagentStop`.

## Juiz

O juiz foi um subagente opus independente, lançado com `effort: high` e mandato de refutar. Os critérios CU1 a CU8 foram pré-registrados em `data/judge-verdicts.json`. A sessão líder pediu um juiz com nome, mas o harness não deixa um colega de time lançar outro colega («the team roster is flat»), então ele foi lançado sem nome.

Resultado: 9 SUSTENTA, 6 EXAGERA e 0 REPROVA. O `judge-verdict-check.sh` saiu rc 0, com 6 superações e 0 recusados. Cada superação virou um nó `C_SUPERACAO_20261125_*`.

Os 6 exageros, todos aplicados:

- **Deny lento.** O label não declarava o modo de permissão em que a recusa foi medida (default).
- **Diretiva e deny.** O deny recusou a diretiva testada, mas não segura toda forma dela em bypass.
- **Hooks.** 4 hooks fora do PreToolUse não têm timeout. Hoje eles imprimem pouco.
- **Contagem das diretivas.** São 14 arquivos, não 17.
- **Colega de time.** Falta o campo do hook, não o flag do processo. E só o colega desta rodada prova a tese do binário do líder.
- **SAC-432.** Ainda não estava comentada. Foi comentada e teve o título corrigido.

As três omissões medidas viraram nós: as duas do deny em bypass, reunidas num nó só na versão pública, e a deriva do cited-directive. Uma quarta omissão foi para NÃO-VERIFICADOS: o «Always deliver» (l.5), que o baton toca.

**Aufhebung:** caem três nós da r27 (`external_edges` SUPERSEDES):

- as versões de quem serve;
- a pergunta da subida;
- a bancada do deny verde em bypass, derrubada pela medição do juiz na própria 2.1.330.

## NÃO-VERIFICADOS

- **Code Mode** (2.1.331: l.3, l.24, l.25, l.37, l.39, l.52; 2.1.332: l.61 a l.66, l.79, l.80, l.89, l.90, l.91). Segue desligado neste host. Ele continua com a tarefa da sonda dos vetos no Code Mode (SAC-492).
- O texto que o modelo recebe no lugar de uma diretiva recusada.
- As skills vindas de servidor MCP (beta, l.3): se elas trazem diretiva e se o nome `servidor:skill` colide com os nomes `categoria:comando` da casa.
- O deny lento na sessão interativa. A sonda é `claude -p`.
- O PreCompact sob o corte de 50 mil caracteres.
- Se o `isolation: worktree` do Agent passa pelo mesmo caminho do reenvio do CLAUDE.md (l.24).
- O `isSynthetic` (l.106) no bridge, quando o SDK subir: o bridge repassa texto pelo SDK.
- Se as perguntas do `/meta:baton` às sessões vivas (SendMessage, l.99 do comando) chegam retidas, e o «Always deliver» das mensagens retidas de outras sessões (l.5) e o id de sessão novo do MCP local depois do reinício do Remote Control (l.48), no uso da campainha e da fila A2A.
