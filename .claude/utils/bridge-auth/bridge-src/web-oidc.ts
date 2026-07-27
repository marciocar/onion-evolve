/**
 * oidc.ts — login humano da PWA por Authorization Code + PKCE (Logto).
 *
 * CÓPIA DE REFERÊNCIA. O original vive em /home/onion/onion-bridge/web/src/auth/oidc.ts.
 * Está aqui para ser revisável no PR — código de auth que só existe no host é código que
 * ninguém revisa.
 *
 * DESENHO — três escolhas que carregam o resto:
 *
 * 1. CLIENT PÚBLICO, ZERO SEGREDO. É uma PWA: qualquer `client_secret` embarcado é extraível
 *    do bundle ou do device. PKCE existe exatamente para isso — o `code_verifier` é gerado
 *    por sessão, nunca trafega no redirect, e sem ele o `code` interceptado não vale nada.
 *
 * 2. REDIRECT NA RAIZ, não em /callback. O bridge serve a PWA com um catch-all estático sem
 *    fallback de SPA, então /callback daria 404 e exigiria mudar o roteamento do servidor.
 *    Na raiz o `?code=` chega, é consumido e a URL é limpa com replaceState. Zero mudança
 *    no servidor — menos raio de mudança, menos coisa para quebrar.
 *
 * 3. `getToken()` CONTINUA SÍNCRONO. Todo o app já passa por ele; torná-lo async espalharia
 *    a mudança por toda a base. Em vez disso o access token vive em memória + localStorage,
 *    e um refresh proativo roda antes de expirar.
 *
 * FRONTEIRA HONESTA sobre storage: o refresh token fica em localStorage, logo é exposto a XSS.
 * Não é ideal. Mas o que ele SUBSTITUI é um token de convite estático, de vida longa e sem
 * expiração, guardado no mesmo localStorage — e que hoje dá acesso irrestrito ao Agent SDK.
 * A troca é estritamente melhor: passa a haver expiração, rotação e revogação por pessoa.
 * O passo seguinte (não feito aqui) seria refresh em cookie httpOnly, que exige backend de
 * sessão no bridge.
 */

const ISSUER    = "https://auth.onionevolve.com/oidc";
const CLIENT_ID = "o5i5f4wb2x2r5ulut9j61";          // app SPA público `onion-bridge-pwa`
const RESOURCE  = "https://bridge.onionevolve.com"; // RFC 8707 — o aud que o bridge exige
const SCOPES    = "openid profile offline_access bridge:invoke";
const REDIRECT  = window.location.origin + "/";

const K_ACCESS  = "onion_oidc_access";
const K_REFRESH = "onion_oidc_refresh";
const K_EXPIRES = "onion_oidc_expires";
const K_VERIFIER = "onion_oidc_verifier";
const K_STATE    = "onion_oidc_state";

// ── util cripto (WebCrypto nativo; sem dependência) ─────────────────────────
function b64url(buf: ArrayBuffer): string {
  return btoa(String.fromCharCode(...new Uint8Array(buf)))
    .replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}
function randomString(bytes = 32): string {
  const a = new Uint8Array(bytes);
  crypto.getRandomValues(a);
  return b64url(a.buffer);
}
async function challengeOf(verifier: string): Promise<string> {
  return b64url(await crypto.subtle.digest("SHA-256", new TextEncoder().encode(verifier)));
}

// ── estado ──────────────────────────────────────────────────────────────────
export function getAccessToken(): string {
  return localStorage.getItem(K_ACCESS) ?? "";
}
export function isLoggedIn(): boolean {
  return !!getAccessToken();
}
function expiresAt(): number {
  return Number(localStorage.getItem(K_EXPIRES) ?? 0);
}
function store(tok: { access_token: string; refresh_token?: string; expires_in?: number }): void {
  localStorage.setItem(K_ACCESS, tok.access_token);
  if (tok.refresh_token) localStorage.setItem(K_REFRESH, tok.refresh_token);
  // 60s de folga: renovar já expirado é a mesma coisa que não renovar.
  localStorage.setItem(K_EXPIRES, String(Date.now() + ((tok.expires_in ?? 3600) - 60) * 1000));
}
export function logout(): void {
  [K_ACCESS, K_REFRESH, K_EXPIRES].forEach((k) => localStorage.removeItem(k));
}

// ── login ───────────────────────────────────────────────────────────────────
export async function beginLogin(): Promise<void> {
  const verifier = randomString();
  const state = randomString(16);
  // sessionStorage, não localStorage: o verifier vale para ESTA aba e ESTE fluxo.
  sessionStorage.setItem(K_VERIFIER, verifier);
  sessionStorage.setItem(K_STATE, state);
  const q = new URLSearchParams({
    client_id: CLIENT_ID,
    redirect_uri: REDIRECT,
    response_type: "code",
    scope: SCOPES,
    resource: RESOURCE,            // sem isto o token sai com aud do Logto, não do bridge
    state,
    code_challenge: await challengeOf(verifier),
    code_challenge_method: "S256",
    prompt: "consent",
  });
  window.location.assign(`${ISSUER}/auth?${q}`);
}

/**
 * Consome `?code=` da raiz, se houver. Devolve true se logou agora.
 * Idempotente: sem `code` na URL, não faz nada.
 */
export async function completeLoginIfCallback(): Promise<boolean> {
  const url = new URL(window.location.href);
  const code = url.searchParams.get("code");
  if (!code) return false;

  const expected = sessionStorage.getItem(K_STATE);
  const got = url.searchParams.get("state");
  // Limpa a URL ANTES de qualquer coisa: um `code` que sobra na barra vaza por
  // histórico, Referer e screenshot — e o code é de uso único, então guardá-lo não serve.
  url.searchParams.delete("code"); url.searchParams.delete("state");
  window.history.replaceState({}, "", url.toString());

  // CSRF: state ausente ou divergente ⇒ este redirect não é do nosso fluxo. Descarta.
  if (!expected || expected !== got) { sessionStorage.removeItem(K_VERIFIER); return false; }

  const verifier = sessionStorage.getItem(K_VERIFIER) ?? "";
  sessionStorage.removeItem(K_VERIFIER); sessionStorage.removeItem(K_STATE);
  if (!verifier) return false;

  const res = await fetch(`${ISSUER}/token`, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "authorization_code",
      client_id: CLIENT_ID,
      redirect_uri: REDIRECT,
      code,
      code_verifier: verifier,
      resource: RESOURCE,
    }),
  });
  if (!res.ok) return false;
  store(await res.json());
  return true;
}

/**
 * Renova se estiver perto de expirar. FALHA FECHADO: sem refresh token, ou refresh recusado,
 * limpa a sessão — um access token vencido em localStorage só produz 401 confuso mais tarde.
 */
export async function refreshIfNeeded(): Promise<void> {
  if (!getAccessToken() || Date.now() < expiresAt()) return;
  const refresh = localStorage.getItem(K_REFRESH);
  if (!refresh) { logout(); return; }
  try {
    const res = await fetch(`${ISSUER}/token`, {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({
        grant_type: "refresh_token",
        client_id: CLIENT_ID,
        refresh_token: refresh,
        resource: RESOURCE,
        scope: SCOPES,
      }),
    });
    if (!res.ok) { logout(); return; }
    store(await res.json());
  } catch {
    logout();
  }
}

/** Chame no boot: consome o callback e agenda o refresh. */
export async function initAuth(): Promise<boolean> {
  const logged = await completeLoginIfCallback();
  await refreshIfNeeded();
  // Checagem periódica barata — o refresh real só acontece perto do vencimento.
  setInterval(() => { void refreshIfNeeded(); }, 60_000);
  return logged || isLoggedIn();
}
