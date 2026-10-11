---
kg: docs/evolution/research/onion-brain-mcp-remoto-2026-10/onion-brain-mcp-remoto-2026-10.kg.yaml
run_id: wf_19d83833-a3e
tokens: 7998840
agents: 104
duration_min: 19
---

# MCP remoto do Company Brain (SAC-70): decisão aberta

Pesquisa pelo `/onion-research` no modo `decision`. O grafo traz **1 nó de decisão aberto**,
`D_ONION_BRAIN_MCP_REMOTO`, que o maestro sela. Esta sessão não sela.

- **Fontes:** 15 lidas e 64 claims extraídas. Das 25 verificadas por votação 3/2, 11 foram confirmadas
  e 14 refutadas.
- **Elenxo:** 45 objeções, das quais 30 sobreviveram e entraram como `CONSTRAINS`.
- **Grafo:** 52 nós.
- **Retorno completo:** `data/run-wf_19d83833-a3e.json`.

## As opções do nó D_

| | Opção |
|---|---|
| **A** | Reativar o precedente `ops/mcp-onion-kg`. Ele passa a servir o clone do hub e é consumido só pelo LibreChat da VPS, que já tem SSO Logto. Bind privado e token estático. |
| **B** | MCP público em streamable-http stateless, como resource server OAuth 2.1 (PRM, RFC 9728). O Logto é o authorization server, a claim de org é obrigatória e há uma instância por org. |
| **C** | Gateway de terceiros na frente de um servidor sem auth própria. |
| **D** | O servidor atua como proxy de AS para o IdP do hub. **Rejeitada**: acoplamento e confused deputy. |
| **E** | Uma instância multi-tenant com a raiz escolhida por claim. **Adiada** até existir mais de um hub. |
| **F** | Não fazer MCP e manter o segundo leitor JS do corpus. |

**Recomendação do Elenxo** (de um agente, sem votação): ir em **dois degraus**.

- **Código e hospedagem.** O código do servidor fica no core, em stdlib e sem acoplamento. A hospedagem
  fica com a família, com uma instância por org.
- **Degrau 1, agora: opção A.**
- **Degrau 2: opção B.** Só entra quando houver demanda medida de uso em Claude.ai ou ChatGPT.

**Divergência a selar:** a síntese do run discorda do Elenxo sobre onde mora o código.

- **A síntese:** uma peça separada da família, com o core guardando só o contrato das tools.
- **O Elenxo:** o código no core.

Os dois concordam que a operação **não** é do core. O precedente medido apoia isso: o servidor
desligado em 2026-08-27 apodreceu sem consumidor.

## Pré-condições que sobreviveram (antes de qualquer degrau)

1. Curar os defeitos medidos do precedente:
   - falta `--` no grep do `kb_search`;
   - o servidor lê a árvore de trabalho sem declarar o commit;
   - a raiz está fixa no core;
   - falta a tool `kg_node`.
2. Frescor:
   - fazer fetch de `origin/main` do hub com uma deploy key só de leitura;
   - servir de um worktree destacado no SHA;
   - devolver `served_commit` e `fetched_at` em toda resposta.
3. O tenant e a raiz vêm da instância ou da claim, nunca de argumento de tool.
4. O Logto tem cadastro aberto, então ter token não basta. O gate é por org ou papel atribuído pelo
   admin, e vale também para o LibreChat da opção A.
5. A saída vai marcada como dado não confiável, por causa da injeção indireta contra usuário não técnico.

## O que a decisão envolve além do código

O degrau 1 é **deploy na VPS**: religar o systemd, apontar para o clone do hub e restringir o papel no
LibreChat. Isso é MOAT, e o maestro executa na janela dele. O degrau 2 depende de medir no Logto o
discovery, os resource indicators e o DCR/CIMD, e de um dogfood OAuth ao vivo em cada cliente.

## NÃO-VERIFICADOS

- **Refutadas (14):** quase todas por fonte fraca ou por exagero sobre a spec. Entre elas está a
  afirmação de que conectores do Claude exigem endpoint público, refutada por 1-2. Isso **não** prova o
  contrário, e a pergunta segue aberta.
- **Não verificadas por orçamento (39):** inclui a ordem de registro de cliente (pré-registro, CIMD,
  DCR), o PKCE S256 obrigatório e o fato de só tools serem expostas pelo caminho de conector. Estão em
  `data/` e não entraram como evidência.
- **Cortadas no fetch (43 URLs):** entre elas a matriz de compatibilidade de clientes da Zuplo
  (relevância alta).
- **Lacunas nomeadas** (`E_LACUNAS_ONION_BRAIN_MCP_2026_10`):
  - o suporte do Logto a RFC 8707 e a DCR/CIMD;
  - o comportamento do ChatGPT e do LibreChat como conectores OAuth (nenhuma afirmação sobreviveu);
  - o custo medido de operar uma instância por org;
  - o filtro contra vazamento de conteúdo privado pelo `docs_search`, paralelo à REGRA 36 (Superfície
    VENDORIZADA sem nome comercial de cliente).
- **Mercado:** sem sinal de capital. Só aparecem vendors explicando o próprio caminho (Cloudflare, AAIF,
  Salesforce).

## valeu-a-pena

O run custou 7.998.840 tokens para 52 nós, cerca de **154k por nó**.

- É o dobro do censo (68 a 74k por nó).
- É menos que a varredura de decisão de 2026-09-13 (cerca de 291k por nó).

A mesma pergunta em `primaries` sairia mais barata. Com as lacunas agora nomeadas (Logto, clientes,
Zuplo), a revisita deve usar esse modo.
