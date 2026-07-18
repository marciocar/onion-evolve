# proto — Endpoint de chat do bridge pessoal (spec-as-code, PROPOSTO, rev.2)

> Spec-alvo da `Q_PROTOCOL` (ADR-001 D4/D6). rev.2 conserta os furos do review adversarial. PROPOSTO — a reconciliar
> contra o fonte do bridge na VPS. Roda no **nó pessoal confiável**, não na VPS (ADR INVARIANTE 0).
> VERIFICADO: bridge = Hono; A2A é signals-only (não-chat). Fork-de-config (D3): `cwd`=clone do CORE (tools resolvem);
> `LIFE_KG` = caminho SEPARADO do grafo de vida.

## Contrato

```
POST /chat
  # auth >= A2A (D4): mTLS client-cert device-bound + token curto PKCE — NÃO bearer estático
  Content-Type: application/json
  body: { "sessionId": "string (vinculado à identidade do cert)", "message": "string" }
  # attachments: GATED-ON-DE-ID (D5/D7) — NÃO near-term; mídia processada 100% on-device antes de qualquer subida

  → 200, text/event-stream (SSE):
     event: assistant_delta   data: { "text": "..." }
     event: tool_use          data: { "name": "Bash", "input": {"command":"kg-radar..."} }
     event: radar_gate        data: { "exit": 0, "integrity": "ok" }     # exit 1 → BLOQUEIA write, superfície erro
     event: kg_write          data: { "file": "...", "nodes": ["P_..."], "verified_at": "2026-07-18", "edges": ["REFUTES ..."] }
     event: done              data: { "reconciled": <do radar, NÃO hardcoded>, "radarExit": 0, "attention": [...] }

GET /health  # autenticado; NÃO vaza path absoluto
  → 200 { "ok": true }
```

## Referência (Hono + Agent SDK — API `query()` CORRETA, radar como gate)

```ts
// server.ts — bridge pessoal (reconfig do onion-bridge por ENV; ZERO fork de código — D3)
import { Hono } from 'hono'
import { streamSSE } from 'hono/streaming'
import { query } from '@anthropic-ai/claude-agent-sdk'  // função top-level (NÃO existe ClaudeSDKClient no SDK TS)

const CORE_CWD = process.env.ONION_CWD                    // clone do CORE → resolve .claude/kg-radar.sh + agents
const LIFE_KG  = process.env.LIFE_KG                      // caminho SEPARADO do grafo de vida (nó confiável)
const app = new Hono()

app.use('/chat', mtlsAndPkce())                          // D4: auth device-bound, não bearer estático

app.post('/chat', (c) => streamSSE(c, async (sse) => {
  const { sessionId, message } = await c.req.json()
  const q = query({
    prompt: message,
    options: {
      cwd: CORE_CWD,                                      // ← tools do core resolvem
      resume: sessionId,                                  // sessão vinculada ao cert
      settingSources: ['project'],                        // carrega .claude/ do core explicitamente
      // SEM bypassPermissions (P4). Allow-list: radar read-only; kg-radar aponta LIFE_KG por caminho absoluto.
      allowedTools: [`Bash(bash ${CORE_CWD}/.claude/validation/kg-radar.sh ${LIFE_KG}/*)`],
      // escrita ao .kg.yaml = human-gated (canDenyTool / hook), nunca auto-aplicada
    },
  })
  for await (const msg of q) {                            // itera SDKMessage; .type = assistant|user|result|system
    if (msg.type === 'assistant') {
      for (const block of msg.message.content) {          // text/tool_use são content blocks aninhados
        if (block.type === 'text')     await sse.writeSSE({ event: 'assistant_delta', data: JSON.stringify({ text: block.text }) })
        if (block.type === 'tool_use') await sse.writeSSE({ event: 'tool_use', data: JSON.stringify(block) })
      }
    }
    // tool_result chega como msg.type 'user'/'result'; ramificar no exit do kg-radar → radar_gate/kg_write
  }
  // 'done' reflete o veredito REAL do radar (D6) — nunca hardcoded
}))

app.get('/health', mtlsAndPkce(), (c) => c.json({ ok: true }))
export default app
```

## Cliente RN (Expo) — SSE de verdade (fetch nativo do RN NÃO faz streaming)

```ts
import { fetch } from 'expo/fetch'   // res.body.getReader() suportado (Expo SDK 52+); ou react-native-sse
async function send(sessionId: string, message: string, onEvent: (e:{event:string,data:any})=>void) {
  const res = await fetch(`${BRIDGE_URL}/chat`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },   // + client-cert mTLS (device-bound)
    body: JSON.stringify({ sessionId, message }),
  })
  const reader = res.body!.getReader()                 // streaming real; bare fetch bufferizaria a resposta inteira
  // decodifica text/event-stream → onEvent({event,data}); mostra assistant_delta e o veredito do radar no done
}
```

## A reconciliar (fecha a Q_PROTOCOL VERIFICADA — precisa do fonte do bridge)
1. O bridge da VPS já tem rota de chat/SSE? path/auth/formato real?
2. Confirmar a forma exata de `query()`/`SDKMessage` contra a versão instalada do SDK.
3. `content-source`/`media-store` como eixo SDAAL (gated) — NÃO hardcodar ingestão de mídia aqui (DRIFT-5).
