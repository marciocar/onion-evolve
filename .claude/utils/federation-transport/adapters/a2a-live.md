# adapter: a2a-live — endpoint VIVO desde 2026-07-09; ACEITAÇÃO segue humana (gated)

> **CORREÇÃO 2026-08-30 (censo, juiz adversarial): o endpoint ESTÁ implementado e VIVO.** A frase
> anterior — "ENDPOINT NÃO IMPLEMENTADO" — ficou CADUCA e quase virou carimbo: um worker a citou como
> evidência e o juiz mediu **200** em `GET /.well-known/agent-card.json` (serviço `onion-vps-bridge`
> ativo; `POST /a2a` com a2aGuard + pool de token dedicado; 1º handshake real registrado no diário em
> **2026-07-09**). O que SEGUE gated é a **ACEITAÇÃO**: todo payload entra em `data/a2a-pending/` e só
> vira inbox por ato humano (`a2a-accept.sh`) — o transporte nunca é auto-selecionado. Doutrina:
> declaração de doc ≠ estado do sistema ([[behavior-over-declaration]]); este cabeçalho agora descreve
> o que o sistema FAZ.


## Desenho (fundamentado — pesquisa `research/federation-2026/G1` + RFC-0004 §3)

- **Transporte:** A2A (JSON-RPC/HTTP + **SSE** quando conectado) + **`PushNotificationConfig` webhook** quando
  offline (recebe/retoma) + **checkpoint durável** (o `inbound/` commitado já é o checkpoint). Agent Card em
  `/.well-known/agent-card.json`. Hospedável atrás do Caddy já existente, sobre o `onion-bridge` (já roda).
- **Só SINAIS gated** (`Signal`), **nunca** conversa autônoma agente↔agente (A2A não protege prompt-injection
  cross-agent — `G1`). O gate humano = consumo idiomático dos estados A2A `input_required`/`auth_required`.
- **Verificação-antes-de-agir** (a spec A2A já exige do receptor): `pin-integrity-check.sh` + trust SDAAL +
  anti-replay (`jti`)/anti-SSRF/assinatura (JWS) **antes** de qualquer sinal virar ação. Ingestão remota =
  supply-chain não-confiável até verificada (`S4·F6`).
- **`never-live-pull`** p/ regulados (ex.: um adotante regulado): recebe sinal, mas só aplica pelo mesmo gate (proposta →
  confirmação do maestro). Nunca puxa framework ao vivo.

## deliver(signal)
Push A2A JSON-RPC/SSE quando conectado; senão `PushNotificationConfig` webhook (retoma quando o receptor
reconecta). O **checkpoint durável** é o `inbound/` commitado pelo destino (não este canal). Retorna
`DeliveryResult{ transport:'a2a-live', delivered, committed:false, gated:true }` — **committed SEMPRE false**
(I3, entrega-sem-commit: quem commita/tria é a sessão do destino) e **gated SEMPRE true** (nada é auto-aplicado).
Bridge down / qualquer falha de canal → **degrada p/ `git-async`** (o system-of-record e fallback — factory.md).
Nunca commita cross-repo; nunca dá ao transporte remoto poder de escrita (isolamento do bridge `bypassPermissions`).

## receive(memberId)
Antes de QUALQUER sinal virar ação, delega ao gate obrigatório **`a2a-verify.sh --receiver <self>`**
(verificação-antes-de-agir; a spec A2A a exige do receptor):
1. **trust policy** (compõe `trust-topology-check.sh`: origem ∈ policy-as-data do `members.yaml`) ·
2. **anti-replay** (`jti` single-use) · 3. **janela de timestamp** · 4. **anti-SSRF** (`a2a-ssrf-check.sh` na
URL do webhook) · 5. **assinatura JWS** (RS256, pubkey pinada por `kid` no JWKS fixture) · 6. **never-live-pull**
(receptor `mode:regulated` → `apply_mode:propose-only`).
- **Veredito `verified:false` → REJEITA** (fail-safe: ausência/erro nunca é aprovação; payload remoto =
  supply-chain não-confiável até verificado). Toda camada não-avaliável (ferramenta ausente) → VETO, nunca skip.
- **Veredito `verified:true` → ainda `gated:true`**: o sinal entra para triagem sob **gate humano** (consumo
  idiomático dos estados A2A `input_required`/`auth_required`), nunca auto-aplicado. Regulado → propose-only.
- O gate NÃO faz rede (JWKS é fixture local pinada); o fetch de JWKS ao vivo + o socket SSE/webhook são do
  **endpoint na VPS**, fora do core.

## Agent Card
Gerado por `.claude/validation/a2a-agent-card.sh` → `docs/onion/agent-card.json` (drift-guard REGRA 25):
projeção do SSOT **filtrada ao próprio core** (confidencialidade — zero dado de adotante), `skills` **signals-only**
(nunca conversa autônoma), `securitySchemes` oauth2(PKCE)+mTLS. O endpoint na VPS o serviria em
`/.well-known/agent-card.json`.

## Pré-condições p/ sair do stub (F2.2)
- **Fundação de segurança no core: ✅** (`a2a-verify.sh` + `a2a-ssrf-check.sh` + Agent Card + selftests +
  drift-guard REGRA 25) — de-risca o endpoint sem abrir canal.
- **Endpoint vivo (VPS): pendente, GATED** — RFC-0004 aceita ✅ · Fase 1 completa ✅ · falta **gate humano do
  maestro** + **dogfood do handshake com um adotante regulado**. Vive no repo privado `~/onion-bridge` (Hono/
  SSE/webhook), que serve o Agent Card e chama o `a2a-verify` do core na fronteira transport→ação.
- Fallback: sempre degrada p/ `git-async` (system-of-record).
