// onion-bridge — servidor Hono que expõe o Onion via Agent SDK + serve a PWA.
import { Hono } from "hono";
import type { Context, Next } from "hono";
import { serve } from "@hono/node-server";
import { serveStatic } from "@hono/node-server/serve-static";
import { existsSync } from "node:fs";
import { config, assertConfig } from "./config.ts";
import { handleChat } from "./chat.ts";
import { handleCommands } from "./commands.ts";
import { handleFederationInbox } from "./federation.ts";
import { adminRouter } from "./admin.ts";
import { handleAgentCard, handleA2A } from "./a2a.ts";
import { verifyAccessToken, jwksSelfCheck, type Identity } from "./identity.ts";

assertConfig();

// Variáveis por-request injetadas pelo authGuard e consumidas pelos handlers.
type Variables = {
  tokenType: "admin" | "courtesy" | "byok" | "oidc";
  byokKey?: string;
  identity?: Identity;   // presente só quando o portador provou identidade (OIDC)
};

const app = new Hono<{ Variables: Variables }>();

// Auth admin — aceita APENAS AUTH_TOKEN (não courtesy/byok).
async function adminGuard(c: Context<{ Variables: Variables }>, next: Next) {
  const auth = c.req.header("Authorization") ?? "";
  const bearer = auth.startsWith("Bearer ") ? auth.slice(7) : "";
  // P9 — ADMIN POR IDENTIDADE. Este guard comparava direto com AUTH_TOKEN e por isso
  // SOBREVIVEU ao flip do P7: medido em 2026-07-27, o segredo compartilhado ainda abria
  // /admin/* (incluindo POST /admin/tokens, que CUNHA convites) enquanto o token OIDC do
  // humano era recusado — o velho entrava e o novo não. Agora exige `bridge:admin`, que
  // só a role humana carrega (o app de serviço NÃO recebe: M2M não cunha convite).
  const admin = bearer ? await verifyAccessToken(bearer, "bridge:admin") : null;
  if (!admin) {
    return c.json({ error: "não autorizado — acesso admin requer identidade com bridge:admin" }, 401);
  }
  c.set("tokenType", "oidc");
  c.set("identity", admin);
  return next();
}

// Auth do /a2a — aceita admin OU token dedicado a2a (INVITE_TOKENS_A2A); NÃO aceita courtesy/byok
// (separação: um remetente a2a não ganha acesso ao /chat).
async function a2aGuard(c: Context<{ Variables: Variables }>, next: Next) {
  const auth = c.req.header("Authorization") ?? "";
  const bearer = auth.startsWith("Bearer ") ? auth.slice(7) : "";
  // P9 — o bypass do segredo de admin SAIU. O /a2a tem pool dedicado (INVITE_TOKENS_A2A) e
  // é canal entre cores, não superfície humana; aceitar o token de admin por cima anulava o
  // isolamento que o pool existe para dar (achado 2026-07-26, quando o pool estava vazio e o
  // admin era o ÚNICO caminho). Zero tráfego em 30 dias — fechar aqui não interrompe ninguém.
  const ok = !!bearer && config.a2aTokens.has(bearer);
  if (!ok) // A mensagem dizia "(ou admin)" — texto sobrevivente do bypass que o P9 REMOVEU. Medido
    // 2026-07-28: o segredo de admin devolve 401 aqui. Mensagem que promete caminho inexistente
    // manda o operador depurar a credencial errada, e e a mesma doenca de declarado!=verificado
    // — so que na superficie que o humano le primeiro.
    return c.json({ error: "não autorizado — /a2a requer token do pool a2a dedicado" }, 401);
  return next();
}

// Auth obrigatório em /chat, /commands, /a2a e /admin.
app.use("/chat", authGuard);
app.use("/commands", authGuard);
app.use("/a2a", a2aGuard);
app.use("/admin/*", adminGuard);
app.route("/admin", adminRouter);

/**
 * Valida o convite e resolve o tipo (admin | courtesy | byok).
 * Para tokens BYOK exige o header X-Anthropic-Key.
 */
async function authGuard(c: Context<{ Variables: Variables }>, next: Next) {
  const auth = c.req.header("Authorization") ?? "";
  const bearer = auth.startsWith("Bearer ") ? auth.slice(7) : "";

  if (!bearer) {
    return c.json({ error: "não autorizado" }, 401);
  }

  // (1) IDENTIDADE — o caminho novo. Um JWT do Logto com a audiência deste bridge e o
  // scope exigido. Quem passa por aqui tem QUEM: `sub` é a pessoa (ou o client_id do
  // serviço), revogável individualmente, ao contrário do segredo compartilhado.
  const identity = await verifyAccessToken(bearer);
  if (identity) {
    c.set("tokenType", "oidc");
    c.set("identity", identity);
    return next();
  }

  // (2) LEGADO — só existe durante a janela de coexistência. Com BRIDGE_AUTH_MODE
  // ausente (o default), este bloco inteiro é inalcançável e só a identidade entra.
  // O FLIP (P7) é remover a linha do .env; o rollback é re-adicioná-la.
  if (config.authMode !== "dual-legacy") {
    return c.json({ error: "não autorizado" }, 401);
  }

  // Admin legado.
  if (config.authToken && bearer === config.authToken) {
    c.set("tokenType", "admin");
    return next();
  }

  // Convite de cortesia — servidor cobre o custo.
  if (config.courtesyTokens.has(bearer)) {
    c.set("tokenType", "courtesy");
    return next();
  }

  // Convite BYOK — exige a chave Anthropic do usuário.
  if (config.byokTokens.has(bearer)) {
    const byokKey = c.req.header("X-Anthropic-Key") ?? "";
    if (!byokKey) {
      return c.json(
        { error: "este convite requer sua chave Anthropic (X-Anthropic-Key)" },
        401,
      );
    }
    c.set("tokenType", "byok");
    c.set("byokKey", byokKey);
    return next();
  }

  return c.json({ error: "não autorizado" }, 401);
}

// Rate-limit simples (janela deslizante in-memory) — endpoint caro e sensível.
const hits = new Map<string, number[]>();
app.use("/chat", async (c, next) => {
  const key = c.req.header("Authorization") ?? c.req.header("x-forwarded-for") ?? "anon";
  const now = Date.now();
  const recent = (hits.get(key) ?? []).filter((t) => now - t < 60_000);
  if (recent.length >= config.rateLimitPerMin) {
    return c.json({ error: "rate limit excedido — tente em instantes" }, 429);
  }
  recent.push(now);
  hits.set(key, recent);
  await next();
});

app.get("/health", (c) => c.json({ ok: true, onionCwd: config.onionCwd }));
// Agent Card A2A do CORE (público — descoberta A2A). Deve vir ANTES do serveStatic catch-all.
app.get("/.well-known/agent-card.json", handleAgentCard);
app.post("/chat", (c) => handleChat(c as Context));
app.get("/commands", (c) => handleCommands(c as Context));
// Endpoint a2a-live (RFC-0004 F2.2): recebe SINAIS gated, verifica no core, enfileira input_required.
app.post("/a2a", (c) => handleA2A(c as Context));
// Downstream por PULL (ADR transport-pull D1). Auth PROPRIA: exige token de ORGANIZACAO,
// nao o authGuard — sao publicos diferentes (adotante puxando o proprio inbox, nao humano
// conversando). Por isso NAO entra na lista de app.use(authGuard) acima.
app.get("/federation/inbox/:member", (c) => handleFederationInbox(c as Context));

// Em produção, serve o build do front em web/dist (se existir).
// Em dev, o front é servido pela pasta public (vanilla de referência).
const webDistPath = "./web/dist";
const publicPath = "./public";

if (existsSync(webDistPath)) {
  console.log("[onion-bridge] servindo PWA de produção em web/dist");
  app.use("/*", serveStatic({ root: webDistPath }));
} else {
  app.use("/*", serveStatic({ root: publicPath }));
}

serve({ fetch: app.fetch, port: config.port, hostname: config.host }, (info) => {
  console.log(`[onion-bridge] no ar em http://${config.host}:${info.port}`);
  console.log(`[onion-bridge] Onion cwd: ${config.onionCwd}  |  modo: ${config.permissionMode}  |  rate: ${config.rateLimitPerMin}/min`);
  // ASSERT DE BOOT — o gate de identidade é inútil se o JWKS for inalcançável, e
  // silêncio no boot é como isso passa despercebido até o primeiro 401 misterioso.
  void jwksSelfCheck().then((r) => {
    console.log(
      r.ok
        ? `[onion-bridge] identidade: JWKS OK (${r.keys} chave(s) ES384)  |  auth: ${config.authMode}`
        : `[onion-bridge] identidade: JWKS INALCANÇÁVEL (${r.error}) — só o legado entra enquanto durar  |  auth: ${config.authMode}`,
    );
    if (config.authMode === "dual-legacy") {
      console.warn("[onion-bridge] AVISO: BRIDGE_AUTH_MODE=dual-legacy — tokens legados ainda aceitos. EXPIRA 2026-08-10.");
    }
  });
});
