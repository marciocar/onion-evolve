---
title: 'Resíduo — o Agent Card deixa de declarar streaming e push que o bridge não serve'
date: 2026-10-21
branch: fix/agent-card-capabilities-honest
reviewed_diff_sha256: cde15f1c54c2319810fa02cbdb96a76a5c643b4ee7b24de9f20cbbeee55cfd20
reviewed_code_sha256: b6c5fe2b7f98886d7a5fe832551a401749b9e2c6156553754fbff1f5fd4c7dc5
findings_total: 6
findings_real: 5
findings_fixed: 0
tokens: 0
duration_min: 20
verdict: APROVADO
elenxo: sim
nota: >-
  Passada adversarial do próprio executor sobre o diff inteiro, com três mutantes rodados na bancada
  (família agent_card). A guarda morde nos dois lados (gerador e projeção) e o controle com marcador
  preenchido passa. Três declarações do card que o bridge não cumpre foram medidas no onion-bridge
  origin/main 21ae69c e ficam NOMEADAS, sem mudança, por estarem fora da decisão selada.
---

# O card só declara o que o bridge serve

## O que entrou

- `.claude/validation/a2a-agent-card.sh`: `capabilities` vira `{"streaming": False, "pushNotifications": False}`,
  com comentário em pt-BR sobre o porquê e o gatilho de volta (o bridge servir tasks/get ou SSE, conferido no
  código dele). O marcador `A2A_BRIDGE_ASYNC_VERIFIED=""` fica no topo do script; vazio quer dizer que o bridge
  não serve nenhum dos dois.
- `docs/onion/agent-card.json`: regenerado pelo gerador; só as duas chaves mudam.
- `.claude/validation/lint-selftest.sh`, família `agent_card`: caso novo **capacidades honestas**. Ele reprova
  `streaming` ou `pushNotifications` igual a `true`, no card gerado em sandbox E na projeção versionada,
  enquanto o marcador estiver vazio.
- `docs/evolution/federation-roadmap-2026.md:68`: a frase de 2026-07 ("capabilities streaming/pushNotifications
  declaradas") ganha a emenda datada de que deixaram de ser declaradas em 2026-10-21.

## Os mutantes (família `agent_card`, `bash .claude/validation/lint-selftest.sh --families agent_card`)

| mutante | o que muda | resultado |
|---|---|---|
| sem mutação | — | 7/7 ✓ |
| A: o gerador volta a `True` | `{"streaming": True, "pushNotifications": True}` | ✗ `agent-card: capacidades — gerado=True/True projeção=False/False` |
| B: só a projeção versionada com `"streaming": true` | `docs/onion/agent-card.json` | ✗ `agent-card: capacidades — gerado=False/False projeção=True/False` |
| C (controle): `True` com o marcador preenchido | `A2A_BRIDGE_ASYNC_VERIFIED="deadbeef"` | ✓ (a volta legítima não é barrada) |

Os três foram revertidos por cópia de backup; `git diff --stat` conferido depois.

## Os achados e o destino de cada um

| # | achado | sev. | destino |
|---|---|---|---|
| 1 | O marcador é lido como linha literal; a bancada não confere o sha contra o código do bridge. Um sha qualquer libera o `True`. | menor | LIMITE declarado no comentário do gerador e do caso: o marcador é a palavra de quem mediu, não a medição. |
| 2 | Se o JSON gerado não parsear, `caps` sai vazio. | — | verificado: vazio ≠ `False/False`, então o caso reprova (falha fechada). |
| 3 | `securitySchemes` declara `oauth2` (authorizationCode em `/oauth/authorize` e `/oauth/token`) e `mtls`. No bridge, o `/a2a` autentica por `Authorization: Bearer <token de convite>` (src/a2a-invites.ts:279) mais o JWS do envelope, verificado pelo `a2a-verify.sh` do core. `git grep` por `/oauth/` e por `mtls\|requestCert\|peerCertificate` em src/ devolve zero. | importante | NOMEADO, sem mudança (fora da decisão). O caso antigo `agent-card: securitySchemes oauth2 + mtls` da bancada **trava** essa declaração; quem a corrigir precisa mudar o caso junto. |
| 4 | `protocolVersion: 0.3.0` sugere o binding JSON-RPC do A2A (`message/send`). O bridge recebe um envelope próprio `{ jws, signal }` por POST cru (src/a2a.ts:120-133) e responde `{ a2a: { state }, verified }`. Um cliente A2A padrão não conversa com ele. | importante | NOMEADO, sem mudança. |
| 5 | O comentário do handler (src/a2a.ts:120) cita `pushNotificationConfig?` no corpo, mas nada o lê (`grep -i push` no arquivo só devolve essa linha). Aceito e ignorado em silêncio. | menor | NOMEADO; é do bridge. |
| 6 | O label do nó `D_AGENT_CARD_DEIXA_DE_DECLARAR_O_QUE_NAO_FAZ_1021` (PR #1263) diz "PR no onion-bridge". O card é gerado pelo core, e o bridge só o serve do clone (src/a2a.ts:23,34-40). | menor | NOMEADO: a cura certa mora no core (este PR). O bridge só precisa do `ops/update-bridge.sh` para o clone servido avançar. |

## Fora do escopo

O card não foi alterado além de `capabilities`. Os achados 3 a 6 ficam para decisão do maestro.
