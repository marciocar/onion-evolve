# proto — Endpoint de chat do bridge pessoal (spec-as-code, PROPOSTO)

> Spec-alvo da `Q_PROTOCOL` (ADR-001 D4). PROPOSTO — a reconciliar contra o fonte do bridge na VPS.
> Fundamentado no VERIFICADO: bridge = Hono + `@anthropic-ai/claude-agent-sdk`; `streaming:true`; o A2A é
> signals-only (não-chat). Fork-chave (D3): `ONION_CWD` → `~/onion-pessoal` (life-KG), não o core.

## Contrato

```
POST /chat
  Authorization: Bearer <MAESTRO_TOKEN>          # separado do oauth2/mTLS do A2A (federação)
  Content-Type: application/json
  body: { "sessionId": "string", "message": "string", "attachments?": [{ "type":"image|audio|file", "uri":"..." }] }

  → 200, Content-Type: text/event-stream (SSE)
     event: assistant_delta   data: { "text": "..." }                    # tokens da resposta
     event: tool_use          data: { "name": "kg-radar", "input": {...} } # o agente rodando ferramentas
     event: tool_result       data: { "name": "kg-radar", "verdict": {...} }
     event: kg_write          data: { "file": "marcio-saude-f0.kg.yaml", "nodes": ["P_..."] } # reconciliação
     event: done              data: { "reconciled": true, "radarExit": 0, "attention": [...] }

GET /health → 200 { "ok": true, "cwd": "/home/marcio/onion-pessoal" }   # afere o fork D3
```

## Referência (Hono + Agent SDK, apontado pro life-KG)

```ts
// server.ts — bridge pessoal (reconfig do onion-bridge; NÃO app do zero)
import { Hono } from 'hono'
import { streamSSE } from 'hono/streaming'
import { ClaudeSDKClient } from '@anthropic-ai/claude-agent-sdk' // stateful multi-turn

const ONION_CWD = process.env.ONION_CWD ?? '/home/marcio/onion-pessoal' // FORK D3: o life-KG
const app = new Hono()

app.use('/chat', bearerAuth({ token: process.env.MAESTRO_TOKEN }))      // auth do maestro

app.post('/chat', (c) => streamSSE(c, async (sse) => {
  const { sessionId, message } = await c.req.json()
  const client = new ClaudeSDKClient({
    cwd: ONION_CWD,                    // ← lê o grafo de vida, não o framework
    // allowedTools inclui Bash(bash .claude/validation/kg-radar.sh*) via o core clonado
    // systemPrompt: KG-SSOT-first (read→verify→act→write); superfície do veredito do radar
  })
  for await (const ev of client.query({ sessionId, prompt: message })) {
    if (ev.type === 'text')        await sse.writeSSE({ event: 'assistant_delta', data: JSON.stringify({ text: ev.text }) })
    if (ev.type === 'tool_use')    await sse.writeSSE({ event: 'tool_use',     data: JSON.stringify(ev) })
    if (ev.type === 'tool_result') await sse.writeSSE({ event: 'tool_result',  data: JSON.stringify(ev) })
  }
  await sse.writeSSE({ event: 'done', data: JSON.stringify({ reconciled: true }) })
}))

app.get('/health', (c) => c.json({ ok: true, cwd: ONION_CWD }))
export default app
```

## Cliente RN (Expo) — thin, só consome o SSE

```ts
// useChat.ts — Expo/RN; SSE via fetch stream (expo/fetch) ou react-native-sse
async function send(sessionId: string, message: string, onEvent: (e:{event:string,data:any})=>void) {
  const res = await fetch(`${BRIDGE_URL}/chat`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ sessionId, message }),
  })
  // parse text/event-stream → onEvent({event, data}); render assistant_delta; mostrar veredito do radar no done
}
```

## A reconciliar (fecha a Q_PROTOCOL VERIFICADA)
1. O bridge da VPS já tem rota de chat/SSE? Qual o path/auth/formato real? (precisa do fonte)
2. `ClaudeSDKClient` expõe `sessionId`/streaming de tool events como assumido? (verificar contra a versão instalada)
3. Attachments (câmera/mic/arquivo) — como o Agent SDK os recebe (upload → path local no cwd)?
