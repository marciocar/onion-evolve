# adapter: a2a-live — 🔒 GATED (stub — RFC-0004 fase-2)

> **NÃO IMPLEMENTADO.** Este adapter é a **costura pronta** (interface) do transporte ao vivo; o endpoint é o
> **F2.2** do roadmap, **gated** (gate humano + dogfood). Documenta o contrato que o F2.2 vai preencher — não
> abre canal vivo. `detect-transport.sh` só o retorna via `FEDERATION_TRANSPORT=a2a-live` explícito, avisando
> que é stub.

## Desenho (fundamentado — pesquisa `research/federation-2026/G1` + RFC-0004 §3)

- **Transporte:** A2A (JSON-RPC/HTTP + **SSE** quando conectado) + **`PushNotificationConfig` webhook** quando
  offline (recebe/retoma) + **checkpoint durável** (o `inbound/` commitado já é o checkpoint). Agent Card em
  `/.well-known/agent-card.json`. Hospedável atrás do Caddy já existente, sobre o `onion-bridge` (já roda).
- **Só SINAIS gated** (`Signal`), **nunca** conversa autônoma agente↔agente (A2A não protege prompt-injection
  cross-agent — `G1`). O gate humano = consumo idiomático dos estados A2A `input_required`/`auth_required`.
- **Verificação-antes-de-agir** (a spec A2A já exige do receptor): `pin-integrity-check.sh` + trust SDAAL +
  anti-replay (`jti`)/anti-SSRF/assinatura (JWS) **antes** de qualquer sinal virar ação. Ingestão remota =
  supply-chain não-confiável até verificada (`S4·F6`).
- **`never-live-pull`** p/ regulados (ex.: granaai): recebe sinal, mas só aplica pelo mesmo gate (proposta →
  confirmação do maestro). Nunca puxa framework ao vivo.

## Pré-condições p/ sair do stub (F2.2)
RFC-0004 aceita ✅ · Fase 1 completa ✅ · gate humano do maestro · dogfood no bridge com um adotante regulado.
Fallback: sempre degrada p/ `git-async`.
