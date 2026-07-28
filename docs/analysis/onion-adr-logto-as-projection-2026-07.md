---
title: "ADR — Logto como PLANO DE EXECUÇÃO projetado do Onion, nunca como registro paralelo"
date: 2026-07-28
status: ACEITO (padrão ratificado; fatia 1 implementada, fatias 2-4 gated)
origem: pedido do maestro — "usar o máximo do Logto integrado ao Onion" (2026-07-28)
kg: docs/onion/graph/m2-bridge-logto-2026-07.kg.yaml
---

# ADR — Logto como projeção, não como segundo registro

## Contexto

Depois de P0-P10 o bridge tem identidade emitida (OIDC/PKCE), audiência vinculada e
capacidade diferenciada por scope. Isso usa **três** primitivas do Logto: um API Resource,
dois Applications e três Scopes. O Logto 1.41.0 instalado traz muito mais — em particular
**Organizations** completas (14 tabelas), com org roles, org scopes, convites com expiração
e relações org↔app.

O Onion, por sua vez, já modela uma federação: `docs/evolution/federation/members.yaml`
com 12 entradas e tiers (`source` T0, `hub` T1, `consumer` T2, `standalone` T3, RFC-0003).

A tentação óbvia é mapear 1:1 — cada membro vira uma Organization. **Este ADR aceita a
direção e recusa o mapeamento ingênuo**, por duas razões medidas.

## Achado 1 — `role:` está sobrecarregado; a projeção não é 1:1

Lendo o `members.yaml`, três entradas marcadas `standalone` **não são projetos adotantes**:

| entrada | o comentário diz | por que não é adotante |
|---|---|---|
| destilação curada | "não vendoriza `.claude/`" | consome conteúdo, não o framework |
| porta de framework | "distribui o bundle standalone, não projeto-adotante" | é canal de distribuição |
| adota o método | "adota o MÉTODO (KG SDAAL), NÃO vendoriza `.claude/`" | consome doutrina, não código |

O campo `role:` carrega **tier** (T0-T3) e **natureza da relação** ao mesmo tempo, e a
segunda só existe em **comentário de YAML** — invisível a qualquer projetor. Projetar
org-por-membro criaria três organizações para relações que não pedem identidade nenhuma,
e o erro seria silencioso: nada falha, só nasce estrutura errada.

**Consequência:** antes de projetar orgs, o `members.yaml` precisa de um campo explícito
separando tier de natureza (`kind:` adopter | distillation | door | method). Isso é
pré-requisito da fatia 2, não dela.

## Achado 2 — o registro de convites já morreu, e ninguém notou

`INVITE_TOKENS_COURTESY` (10) e `INVITE_TOKENS_BYOK` (1) seguem no `.env` e **retornam 401
desde o flip do P7**. O `authGuard` passou a exigir OIDC e o caminho legado só sobrevive sob
`dual-legacy`, que está desligado. Nenhum gate avisou; nenhum humano reclamou.

Isso é evidência a favor da tese deste ADR e contra o modelo antigo: **segredo compartilhado
distribuído por chat não tem quem o observe**. Um convite de Organization tem emissor,
destinatário, expiração e estado — some quando expira, e o sumiço é visível.

## Decisão

**D1 — O `members.yaml` (sob o KG) é o SSOT; o Logto é PROJEÇÃO dele.** O fluxo é sempre
`repo → Logto`, por projetor idempotente, no mesmo formato do `logto-provision.sh`. Nunca o
inverso. Dois registros editáveis dos dois lados divergem, e a divergência é exatamente a
doença que o framework combate (`declarado ≠ verificado`) — institucionalizá-la na camada de
identidade seria o pior lugar possível para tê-la.

**D2 — Mapa canônico das primitivas.**

| conceito Onion | primitiva Logto | estado |
|---|---|---|
| capacidade (ler-propor / escrever / admin) | Resource scope | ✅ P9/P10 |
| chamador de serviço | **um M2M app por chamador** | fatia 1 |
| membro da federação | Organization | fatia 2 (gated no Achado 1) |
| tier (hub/standalone/consumer) | Organization role | fatia 2 |
| convite (cortesia, BYOK) | Organization invitation | fatia 3 |
| a2a (agente↔agente) | M2M app com contexto de org | fatia 4 |

**D3 — Um M2M app por chamador, nunca um compartilhado (fatia 1).** Hoje existe um único
`onion-bridge-service`. Revogá-lo derruba todos os chamadores de uma vez; e o log não
distingue quem chamou. Um app por chamador torna a revogação **por-chamador** e a auditoria
nominal — a mesma razão pela qual o segredo compartilhado foi aposentado no P7.

**D4 — Ordem inegociável: `kind:` antes de orgs.** A fatia 2 não começa antes de o
`members.yaml` separar tier de natureza. Projetar sobre um campo sobrecarregado produz
estrutura errada sem erro.

**D5 — Nada de sincronização bidirecional, nunca.** Se alguém criar uma org à mão no
console, o projetor **reporta a divergência** e não a absorve. Absorver seria deixar o
plano de execução redefinir o SSOT pelas costas.

## Consequências

- Revogar um adotante passa a ser um ato, não uma caça a tokens.
- Convidar alguém vira convite rastreável com expiração, não string colada no chat.
- `bridge:write` pode virar **por organização** — um adotante escreve no escopo dele.
- Custo: o projetor vira artefato a manter, e o `members.yaml` ganha um campo.

## Fronteira declarada

- **Fatias 2-4 não foram exercitadas.** O mapa D2 é desenho, não medição — só a fatia 1 tem
  prova. Não afirmar que as outras funcionam antes de rodá-las.
- **O Achado 1 é leitura de YAML e comentário**, não medição de comportamento: nenhum
  projetor existe ainda para errar. É `plane: DEV` — uma predição de falha, não uma falha
  observada.
- Este ADR **não** decide se a federação inteira deve viver no Logto. Decide que, **se**
  viver, é por projeção — e nomeia o pré-requisito.

## Verificação

Fatia 1: cada chamador tem app próprio, e revogar um **não** derruba o outro — medido
desligando um app e reconfirmando o outro no ar.
