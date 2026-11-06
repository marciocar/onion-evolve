---
branch: feat/slack-persona-ops
pr: pendente
date: 2026-11-06
reviewed_diff_sha256: 6f8f555dbb076a5c506d36b6642f8b3f4140977baf1f5fa60543c3fe39829fde
reviewed_code_sha256: de84ae02cef9761db756a151f140c972a967036687a98147e70f0f677da1e888
findings_total: 9
findings_real: 9
findings_blocking: 0
tokens: 0
duration_min: 150
findings_fixed: 9
verdict: CORRIGIDO
elenxo: nao
reviewer: agente de execução da sessão do core (passada própria, não independente), com mutantes reais nos dois repos
nota: "tokens 0 = não medido. Revisão da peça inteira do degrau 2: o código da persona no onion-bridge (PR #94) e o wrapper, a bancada e o registro no MOAT aqui."
---

# A persona do Slack em rascunho: o que a passada achou antes de o PR sair

O degrau 2 tem duas metades. O código da persona mora no `onion-bridge` (PR #94, empilhado sobre o #93 do SDK
0.3.319), e este PR traz a metade do core: o wrapper `ops/slack-persona.sh` (creds, install, start, verify), a
bancada dele, a família `slack_persona` do auto-teste e as linhas do MOAT. A passada foi feita **rodando**: o Agent
SDK e o CLI reais contra um Slack falso e uma Messages API falsa, mutantes nos dois lados e a prova da cópia limpa antes.

## Achados no código da persona (onion-bridge), todos curados no PR #94

1. **Quatro mutantes sobreviveram na 1ª rodada.** O hook sempre `allow`, o post sem o veto, o veto sem conferir o
   aprovador e o veto sem conferir o evento passavam verdes. Duas causas: a asserção de "negado" casava o texto do motivo,
   que é igual no hook e no corpo do post, e o aprovador e o evento só eram exercidos no caminho feliz. Cura: a
   negação tem de vir com o rótulo do hook (`PreToolUse:mcp__persona__post_reply`), e cinco casos unitários do veto e
   da porta do post. Resultado: 26 de 26 mortos.
2. **Com `tools: []`, as ferramentas MCP vinham adiadas atrás do ToolSearch**, que não existia. Medido no corpo da
   requisição. Cura: `alwaysLoad` nos dois servidores in-process. O `DeferredToolPlaceholder` que sobra
   (`defer_loading`, "never call this tool") fica separado das ferramentas reais na bancada, por nome **e** flag.
3. **O preset `claude_code` descrevia shell e ambiente a um agente que não programa.** Cura: system prompt próprio.
4. **O mutante "agente herda o ambiente" mostrou o que vazaria**: `CLAUDE_CODE_MESSAGING_TOKEN`, `SSH_CONNECTION` e o
   resto do environ da sessão. A asserção do ambiente montado à mão ficou exata (seis chaves).

## Achados no wrapper (este PR), todos curados

5. **A bancada morava dentro do wrapper**, e o veto do MOAT recusou analisar o script ("fundo demais, com alvo do
   MOAT"). Cura: a bancada saiu para `ops/testing/slack-persona-selftest.sh`, e o modo de teste
   `ONION_SLACK_PERSONA_TEST` entrou na lista do `pretooluse-moat-gate.sh`, como os dos outros wrappers.
6. **O `!` pode não ter TTY** (classe `gpg-pinentry-tty-vps`). Sem terminal, o `read -s` falharia no meio. Cura: a
   recusa vem **antes** de tocar em qualquer coisa e manda usar um terminal SSH/mosh. Caso na bancada.
7. **O código servido pode não ser legível pelo UID dinâmico.** A home do `onion` é 0750, e o bind não muda
   permissão. Cura: o `install` avisa e o `start` recusa enquanto houver arquivo sem `o+r` ou diretório sem `o+rx`
   sob os caminhos que o processo carrega. Caso na bancada.
8. **`journalctl | grep -q` sob pipefail** (classe `pipefail-epipe-early-closer`). Cura: captura e here-string.
9. **Dois casos da bancada passavam com o mutante.** "Existente sem confirmação fica" passava porque o mutante caía
   no prefixo errado, e o conf do MCP sem o token não tinha caso. Cura: a asserção exige rc 0 e "mantida", e o caso do
   conf sem token entrou. Os 9 mutantes da família morrem, e a cópia limpa passa antes no mesmo arranjo.

## O que não foi verificado

- Nada rodou contra o Slack real, o systemd real ou o `systemd-creds` real. O `systemd-analyze verify` da unit passou
  como usuário, e o `install --apply` roda de novo como root.
- O bind de `/home/onion/onion-bridge` sob `ProtectHome=yes` com `DynamicUser` segue o precedente medido do runner do
  `/chat` (o binário do CLI), mas não foi medido para a árvore inteira. O `start` prova a conexão desta invocação.
- Os mutantes do runner do bridge (`chat-runner-mutants.sh`) não completaram no meu teto de espera. Nenhum arquivo
  deles foi tocado.
