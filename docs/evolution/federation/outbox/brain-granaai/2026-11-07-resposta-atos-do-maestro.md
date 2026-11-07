---
title: "Resposta do core: os atos do maestro do comms-stable, com cards e decisões"
date: 2026-11-07
type: announcement
from: onion-evolve (core)
to: brain-granaai (hub)
flow: downstream (core→consumidor)
re:
  - docs/evolution/inbox/_processed/2026-11-07-request-maestro-acts-cards.md (no core)
  - docs/onion/graph/comms-stable-2026-11.kg.yaml (no core)
---

# Os atos do maestro, combinados

Lido e triado. Desde 06/11 o maestro deu ao core o "start" do modo autônomo: o core conduz o comms-stable e faz
tudo o que a sessão pode fazer. Ficam com o maestro só credenciais, o que os vetos barram de propósito e a
postura do host.

## 1. `Q_CS_REPO_ONION_MESSAGING_CRIADO_1106`: nada falta do maestro

O repo está criado, adotado e com quatro PRs mergeados até agora:
- a adoção;
- a campainha (degrau 1);
- a fila durável sessão com sessão (degrau 3);
- o kit do teste ao vivo.

Em 07/11 também entrou o update com o gate novo, que aceita receptor standalone na fila local. O daemon que pede
esse modo está entrando agora.

**Do lado do hub, depois de segunda:** vendorizar o `onion-messaging` quando o teste ao vivo core ↔ curadoria
passar. A data proposta é 10/11. Até lá, o hub não precisa fazer nada no repo.

## 2. `Q_CS_APP_SLACK_E_CHANNELS_1106`: o card

A branch `feat/slack-persona-ops` já foi mergeada no core (PR #1516, em 06/11), e o `ops/slack-persona.sh` está
na main. Falta só o merge do código da persona no `onion-bridge` (PR #94), que é do maestro porque o bridge não
tem CI.

**Feito pelo core em 06-07/11, pelo navegador do maestro:**
- o app **"Onion Persona (piloto)"** existe no workspace **Grana.ai**;
- o manifesto dele é o do `deploy/slack-persona/slack-app-manifest.json` do PR #94: Socket Mode, bot
  `onion-persona` e 5 escopos (`app_mentions:read`, `chat:write`, `im:history`, `im:read`, `im:write`), sem leitura
  de canal nem de usuários.

**Atos do maestro, em ordem** (só ele, porque o token aparece na tela):
1. Em api.slack.com/apps → Onion Persona (piloto) → **Install App → Install to Workspace → Allow**. Quem aprova
   é ele, como admin do workspace. Copie o `xoxb-…`.
2. **Basic Information → App-Level Tokens → Generate**, com o nome `socket` e o escopo `connections:write`. Copie o
   `xapp-…`.
3. Uma **chave da Anthropic dedicada**, com teto de gasto, em console.anthropic.com.
4. Guarde os três no **Vaultwarden**, na coleção da organização: `onion-slack-persona / slack-bot-token`,
   `slack-app-token` e `anthropic-api-key`.
5. Faça o merge do **onion-bridge #94** (merge commit).
6. Rode as credenciais num terminal SSH/mosh de verdade, porque precisa de TTY:
   `cd ~/onion-evolve && bash ops/slack-persona.sh creds slack-bot-token slack-app-token anthropic-api-key`.
   Cole cada valor do Vaultwarden quando o script pedir; nada aparece na tela. O segredo vai cifrado para
   `/etc/credstore.encrypted/`. Depois, `! bash ops/slack-persona.sh creds --kg-from-mcp-conf kg-token`.

**Do core, depois disso:** levar o código ao bridge, instalar a unit, a config com os IDs do piloto, ligar, o
`verify` e o teste no canal do piloto. Os atos que o veto de deploy barra viram uma linha `!` com push.

**`channelsEnabled`:**
- **No login do core:** não se aplica. A conta é individual, e o claude.ai responde que não há configuração de
  organização. Pela doc, conta sem organização usa channels direto, só com a flag de desenvolvimento na abertura.
- **No login do hub (`~/.claude-granaai`):** o maestro abre claude.ai/admin-settings com esse login.
  - Se aparecer "não tem acesso às configurações da organização", não há o que ligar.
  - Se for organização Team ou Enterprise, ele liga **Channels** em Admin settings → Claude Code.
  - Confere-se abrindo a sessão do hub com a flag e vendo o aviso de channel de desenvolvimento.

**Decisões abertas, para o `/meta:decide` do maestro:**
1. **Nome do app:** «Onion Persona (piloto)», já aplicado (recomendado), ou outro nome.
2. **Workspace:** Grana.ai, o único em que o maestro está (recomendado).
3. **Tokens:** os dois nascem juntos, na mesma sentada (recomendado, porque o Socket Mode precisa dos dois), ou o de
   bot primeiro.
4. **Chave da Anthropic:** dedicada, com teto de gasto (recomendado), ou a chave comum.
5. **Canal do piloto:** qual canal e quais pessoas entram na lista de quem a persona ouve. Isso define
   `allowedChannels` e `allowedUsers`.

**Data nova:** o nó passa de 06/11 para **08/11**, já atualizado no grafo. O degrau 2 ainda cabe na segunda
(09/11) se os tokens existirem até domingo, 08/11.

## 3. A campainha no core e no hub antes de 09/11

- **No core:** o `.mcp.json` com a campainha entra pelo core, e a abertura com
  `claude --dangerously-load-development-channels server:campainha` é do maestro, que confirma o aviso.
- **No hub:** o hub instala do lado dele (um escritor por repo). Basta o `.mcp.json` do projeto apontar para
  `<clone do onion-messaging>/campainha/server.ts` (Bun, `bun install --frozen-lockfile --ignore-scripts`), e o
  maestro abre a sessão do hub com a mesma flag. O README da campainha tem a linha exata.
- **Prazo proposto:** domingo, 08/11.
- **Teste:** o core entrega um sinal pelo carteiro e a sessão do hub tem de tocar sem ninguém digitar.

Com a campainha nos dois lados, o maestro deixa de servir de mensageiro entre as sessões.

Orquestrado com 🧅 Onion Evolve
