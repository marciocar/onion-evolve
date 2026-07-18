# Contrato do endpoint de chat do onion-bridge — VERIFICADO (2026-07-18)

> Fecha a `Q_PROTOCOL`. Lido do FONTE REAL na VPS (`/home/onion/onion-bridge/src/{server,chat,config,workspace}.ts`,
> via sudo read-only). `[VERIFICADO]` = está no código hoje; `[HARDENING]` = o que o review recomenda mudar p/ o life-KG.
> Deps reais: `@anthropic-ai/claude-agent-sdk ^0.3.195`, `hono ^4.12.27`, node ≥22, pnpm. Bridge = POC v0.1.0.

## Contrato real `[VERIFICADO]`

```
POST /chat        auth: Authorization: Bearer <token>   (+ X-Anthropic-Key se token BYOK)
  # JSON:
  { "prompt": "req", "sessionId?": "resume", "image?": "data:image/png;base64,... | base64",
    "imageMimeType?": "image/png", "context?"|"systemPromptAppend?": "append ao system prompt" }
  # OU multipart/form-data: campos prompt + file (File: image/*|pdf|text/*, ≤10MB) + sessionId? + context?

  → 200 text/event-stream (SSE):
     event: session         data: { "sessionId": "..." }        # 1x, p/ resume no cliente
     event: <SDKMessage.type>  data: <SDKMessage cru em JSON>    # type = system|assistant|user|result
     event: done            data: {}
     event: error           data: { "message": "..." }
  # rate-limit 20/min por token; workspace isolado por token (ver abaixo)

GET  /health   → { ok:true, onionCwd:"..." }   # ⚠ SEM auth + vaza o path do cwd (achado do review, real)
GET  /commands (auth) · POST /a2a (token a2a dedicado) · /admin (AUTH_TOKEN)
```

## Como o SDK é chamado `[VERIFICADO]` (o proto rev.2 acertou a API)
```ts
import { query } from "@anthropic-ai/claude-agent-sdk";   // função top-level — NÃO ClaudeSDKClient ✅
const conversation = query({
  prompt,                                    // string OU AsyncIterable<SDKUserMessage> (imagem inline)
  options: {
    cwd,                                      // workspace isolado por token (NÃO o core direto — ver abaixo)
    settingSources: ["project"],             // carrega .claude/ do cwd ✅
    permissionMode: "bypassPermissions",     // ⚠ [HARDENING] ligado + allowDangerouslySkipPermissions:true
    resume: sessionId,                       // retomada de sessão
    additionalDirectories: [uploadsDir],     // expõe uploads ao tool Read
    systemPrompt: { type:"preset", preset:"claude_code", append: context },
    env: { ...process.env, ANTHROPIC_API_KEY: byokKey },  // BYOK
  },
});
for await (const message of conversation) stream.writeSSE({ event: message.type, data: JSON.stringify(message) });
```

## A descoberta que resolve o cwd-vs-tools `[VERIFICADO]`
`workspace.ts`: cada token → `workspaces/<sha256(token)[:16]>/` como `cwd`, com **symlinks read-only** pro Onion
canônico: `.claude` → `${ONION_CWD}/.claude`, `CLAUDE.md`, `docs`. **É exatamente o padrão "tools do core + dados
separados"** — o bridge já o implementa. Uploads isolados por token (`workspaces/<slug>/uploads`).
⇒ **Para o app pessoal:** o workspace do token vira o life-KG (os `.kg.yaml`) COM `.claude` symlinkado do core. Não
precisa "cwd=core + LIFE_KG env" (rev.2) — reusa o modelo de workspace que já existe. `ONION_CWD` real hoje = `/home/marciocar/onion-evolve` (o core).

## Deltas p/ o life-KG `[HARDENING — o review, agora contra o real]`
1. **Locus:** workspaces + uploads vivem na **VPS** (`/home/onion/...`, `/tmp/onion-bridge-uploads`). Pro life-KG
   `private` isso viola INVARIANTE 0 (dado soberano no disco de terceiro) → mover pro **nó pessoal confiável**.
2. **`bypassPermissions` + `allowDangerouslySkipPermissions`:** ligado. O próprio `.env.example` anota "hardening
   futuro: allowlist via hook PreToolUse/canUseTool" → **fazer isso** pro life-KG (radar read-only; escrita `.kg.yaml` gated).
3. **Auth:** bearer + TLS + rate-limit (não mTLS — a spec A2A do card era aspiracional; a2aGuard também é bearer).
   Pro dado mais sensível → considerar token device-bound + expiração.
4. **Uploads crus na VPS antes de de-id:** mídia (foto do cônjuge = 3º) vai a `/tmp` no servidor → processar
   on-device (executorch) antes de subir (D5/D7).
5. **`/health` sem auth vaza `onionCwd`** → autenticar + omitir path.
6. **kg-radar NÃO é gate no endpoint** — o handler só faz `query()`+stream; rodar o radar é comportamento do agente
   (via prompt/tools), não enforçado. Pro KG-SSOT-first (D6), o gate teria de ser adicionado (hook/wrapper).
```
