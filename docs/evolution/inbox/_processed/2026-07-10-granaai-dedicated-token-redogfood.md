---
tipo: sinal-upstream
data: 2026-07-10
origem: granaai (via a2a-live)
assunto: sinal signal via a2a-live — 2026-07-10-granaai-dedicated-token-redogfood
transporte: a2a-live (verificado — trust + jti + timestamp + JWS + kid-binding)
verificacao:
  verified: true
  regulated: false
  apply_mode: gated
  taskId: f1b204f3-c086-42bf-9e90-6e87b7149265
  recebido_em: 2026-07-10T03:13:10.210Z
para: onion-evolve (core) — triagem normal (/meta:co-evolve)
---

# Sinal a2a-live de granaai — 2026-07-10-granaai-dedicated-token-redogfood

Recebido pelo endpoint **a2a-live** (F2.2), verificado pelo `a2a-verify` (assinatura RS256 + kid∈keys[from]
+ anti-replay + janela + anti-SSRF) e **aceito pelo maestro** (fila gated `data/a2a-pending` → inbox). Nada
foi auto-aplicado — segue o fluxo git-async normal de triagem.

**Sem corpo** (handshake/ping) — nada a acionar além do registro de que o canal vivo funcionou.

> Envelope JWS preservado no registro da fila do bridge (auditoria): taskId `f1b204f3-c086-42bf-9e90-6e87b7149265`.
