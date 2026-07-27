/**
 * identity.ts — validação de identidade OIDC para o onion-bridge.
 *
 * CÓPIA DE REFERÊNCIA. O original vive em /home/onion/onion-bridge/src/identity.ts
 * (deploy fora deste repo). Está aqui para ser REVISÁVEL no PR — código de segurança
 * que só existe no host é código que ninguém revisa.
 *
 * Por que sem `jose`: o bridge é serviço de produção SEM rollback por git (não é repo)
 * e o `alg` é PINADO por desenho (§3.3 do spec M2), o que fecha a armadilha principal
 * do JWT — confusão de algoritmo. Em troca da superfície de dependência zero, cada
 * caso negativo é PROVADO contra o issuer vivo (assinatura adulterada, aud errada,
 * expirado, scope ausente, alg trocado).
 *
 * O que este módulo NÃO faz: autorização fina de produto. Ele responde "QUEM é, e o
 * token vale para ESTA audiência com ESTE scope" — nada além disso.
 */

import { createPublicKey, verify as cryptoVerify, type KeyObject } from "node:crypto";

export type Identity = {
  subject: string;       // `sub` — o usuário (humano) ou o client_id (serviço)
  clientId: string;
  scopes: string[];
  isMachine: boolean;    // sub === client_id ⇒ M2M; senão, humano
};

const ISSUER = process.env.OIDC_ISSUER ?? "https://auth.onionevolve.com/oidc";
const AUDIENCE = process.env.OIDC_AUDIENCE ?? "https://bridge.onionevolve.com";
const REQUIRED_SCOPE = process.env.OIDC_REQUIRED_SCOPE ?? "bridge:invoke";
// PINADO. Medido no token real emitido pelo Logto 1.41.0 em 2026-07-26: ES384.
// Aceitar o `alg` do header seria deixar o atacante escolher a criptografia.
const PINNED_ALG = "ES384";
const JWKS_URI = `${ISSUER}/jwks`;

// Cache de JWKS com piso de re-fetch: um `kid` desconhecido pode ser rotação legítima,
// mas re-buscar a cada request transformaria um token forjado em amplificador de DoS
// contra o Logto. 60s é o piso.
let jwksCache: Map<string, KeyObject> = new Map();
let jwksFetchedAt = 0;
const JWKS_MIN_REFETCH_MS = 60_000;

async function loadJwks(force = false): Promise<void> {
  const now = Date.now();
  if (!force && jwksCache.size > 0 && now - jwksFetchedAt < 3_600_000) return;
  if (force && now - jwksFetchedAt < JWKS_MIN_REFETCH_MS) return;

  const res = await fetch(JWKS_URI, { signal: AbortSignal.timeout(5000) });
  if (!res.ok) throw new Error(`jwks http ${res.status}`);
  const body = (await res.json()) as { keys?: unknown[] };
  if (!Array.isArray(body.keys)) throw new Error("jwks sem array `keys`");

  const next = new Map<string, KeyObject>();
  for (const jwk of body.keys as Array<Record<string, unknown>>) {
    // Só importamos chaves do algoritmo pinado. Uma chave RSA no JWKS não deve
    // sequer entrar no cache — se não está no cache, não pode ser escolhida.
    if (jwk.alg !== PINNED_ALG || jwk.kty !== "EC" || typeof jwk.kid !== "string") continue;
    try {
      next.set(jwk.kid, createPublicKey({ key: jwk as never, format: "jwk" }));
    } catch {
      /* chave malformada é ignorada, não derruba o gate */
    }
  }
  if (next.size === 0) throw new Error(`jwks sem chave ${PINNED_ALG} utilizável`);
  jwksCache = next;
  jwksFetchedAt = now;
}

function b64uToBuf(s: string): Buffer {
  return Buffer.from(s, "base64url");
}

/**
 * Valida um access token. Devolve a Identity, ou `null` se o token não vale.
 * FALHA FECHADO: qualquer exceção (rede, parse, chave ausente) ⇒ null.
 */
export async function verifyAccessToken(token: string): Promise<Identity | null> {
  try {
    const parts = token.split(".");
    if (parts.length !== 3) return null;
    const [h64, p64, s64] = parts;

    const header = JSON.parse(b64uToBuf(h64).toString("utf8")) as Record<string, unknown>;
    // (1) ALG PINADO — antes de qualquer outra coisa.
    if (header.alg !== PINNED_ALG) return null;
    if (typeof header.kid !== "string") return null;

    await loadJwks();
    let key = jwksCache.get(header.kid);
    if (!key) {
      // `kid` desconhecido pode ser rotação legítima — uma re-busca, com piso.
      await loadJwks(true);
      key = jwksCache.get(header.kid);
      if (!key) return null;
    }

    // (2) ASSINATURA. ES384 = ECDSA P-384 + SHA-384, assinatura em formato
    // IEEE-P1363 (r||s) no JWS — não DER. Errar isso faz TUDO falhar (ou, pior,
    // passar) em silêncio.
    const signingInput = Buffer.from(`${h64}.${p64}`, "utf8");
    const ok = cryptoVerify(
      "sha384",
      signingInput,
      { key, dsaEncoding: "ieee-p1363" },
      b64uToBuf(s64),
    );
    if (!ok) return null;

    // (3) CLAIMS. Só depois da assinatura — antes disso o corpo é texto de estranho.
    const claims = JSON.parse(b64uToBuf(p64).toString("utf8")) as Record<string, unknown>;

    if (claims.iss !== ISSUER) return null;

    // `aud` pode ser string ou array (RFC 7519). O binding de audiência é o que
    // impede replay de um token emitido para outro serviço do mesmo tenant.
    const aud = claims.aud;
    const audOk = typeof aud === "string"
      ? aud === AUDIENCE
      : Array.isArray(aud) && aud.includes(AUDIENCE);
    if (!audOk) return null;

    const nowSec = Math.floor(Date.now() / 1000);
    if (typeof claims.exp !== "number" || claims.exp <= nowSec) return null;
    if (typeof claims.nbf === "number" && claims.nbf > nowSec + 60) return null;

    // (4) SCOPE. Audiência certa sem o scope certo ainda não autoriza invocar.
    const scopes = typeof claims.scope === "string" ? claims.scope.split(" ").filter(Boolean) : [];
    if (!scopes.includes(REQUIRED_SCOPE)) return null;

    const sub = typeof claims.sub === "string" ? claims.sub : "";
    const clientId = typeof claims.client_id === "string" ? claims.client_id : "";
    if (!sub) return null;

    return { subject: sub, clientId, scopes, isMachine: sub === clientId };
  } catch {
    // FAIL-CLOSED: Logto fora do ar, JWKS inacessível, JSON quebrado — nada disso
    // vira "pode entrar". O caminho legado (se ligado) é quem decide o resto.
    return null;
  }
}

/** Exposto para o assert de boot: prova que o JWKS é alcançável e tem chave utilizável. */
export async function jwksSelfCheck(): Promise<{ ok: boolean; keys: number; error?: string }> {
  try {
    await loadJwks(true);
    return { ok: true, keys: jwksCache.size };
  } catch (e) {
    return { ok: false, keys: 0, error: e instanceof Error ? e.message : String(e) };
  }
}
