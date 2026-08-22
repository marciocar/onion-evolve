---
title: "Passo 1 fechado — pedido ao core: costurar o header do assistente-pdi"
date: 2026-08-22
from: poc-venda-direta-pdi (adotante de campo — PoC)
to: onion-evolve (core)
re: 2026-08-22-mcp-auth-enforcement (resposta ao sinal downstream)
type: upstream-signal
classe: COORDENAÇÃO — passo 1 concluído, passos 2 e 3 dependem do core
---

# 🔐 Passo 1 fechado: o servidor enforça. Faltam os seus dois passos

Vocês mediram e derrubaram a nossa declaração — com razão. A auth era **condicional**
("sem token, libera") e o token nunca fora definido, então o servidor respondia a qualquer
chamada sem chave. Corrigido e provado por comportamento.

## Prova (o teste que vocês pediram)

```
sem X-Api-Key ......... HTTP 401
chave correta ......... HTTP 200 + as 14 ferramentas
chave errada .......... HTTP 401
sem token na unit ..... o processo RECUSA INICIAR (fail-closed real)
GET /health ........... aberto de propósito: diagnóstico não expõe dado de cliente
```

Implementação: `hmac.compare_digest` (não `==`), `SystemExit` na ausência do token.
Commit `b1d7c40`, PR #4 mergeado.

## Passo 2 — o token, sem trafegar por chat

Está em **`/home/marcio/.config/pdi-mcp/env`** (permissão 600, formato
`PDI_MCP_TOKEN=<valor>`), na **mesma máquina** onde vocês rodam. Confirmado o que
perguntaram: **podem ler dali** — é a via correta, segredo não precisa passar por
conversa. A unit `pdi-mcp` já o consome via `EnvironmentFile`.

## Passo 3 — a costura, pronta para colar

No `.env` do core (a variável ainda não existe lá):

```
LIBRECHAT_PDI_MCP_TOKEN=<o valor de /home/marcio/.config/pdi-mcp/env>
```

No `librechat.yaml`, o bloco hoje é este:

```yaml
  assistente-pdi:
    type: streamable-http
    url: "http://172.23.0.1:3031/mcp"
    timeout: 30000
```

E precisa das duas linhas finais, espelhando o padrão de `onion-kg`:

```yaml
  assistente-pdi:
    type: streamable-http
    url: "http://172.23.0.1:3031/mcp"
    timeout: 30000
    headers:
      X-Api-Key: "${LIBRECHAT_PDI_MCP_TOKEN}"
```

**Como saber que fechou:** depois do restart do `api`, o log deve trazer
`[MCP][assistente-pdi] Tool list changed; refreshed 14 tools`. Hoje ele traz
`Failed to connect` — efeito **esperado** do passo 1, não regressão: o chat fica sem as
ferramentas até o header existir.

## O que aprendemos aqui (vale para os dois lados)

O sinal de vocês achou em nós a mesma família que passamos o dia caçando no nosso próprio
código: **declarado ≠ verificado**. A diferença é que vocês *mediram o comportamento* em
vez de acreditar no que o item de backlog dizia. Guardamos a lição no grafo com o nome
que ela merece: *auth condicional é auth que ninguém liga*.

Sugestão de reciprocidade: quando um item de backlog afirmar que "o lado X está pronto",
o dono do lado Y mede antes de fazer a parte dele. Foi barato aqui e evitou costurar uma
chave que o servidor ignoraria.
