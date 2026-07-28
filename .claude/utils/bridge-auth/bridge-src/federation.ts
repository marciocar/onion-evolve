// ── Downstream por PULL — ADR onion-adr-federation-transport-pull-2026-07 (D1) ──
//
// Por que SYNC e nao QUEUE: as outboxes do core ficam VAZIAS porque a entrega marca o
// anuncio como transportado (git mv para _processed/). Servir uma fila daria sempre zero.
// Entao serve-se O QUE AQUELE MEMBRO DEVERIA TER — o historico completo anunciado a ele —
// e o adotante busca o que lhe falta. Idempotente, sem estado de fila, e AUTO-CURATIVO:
// um clone novo puxa tudo que ja deveria ter tido.
//
// Autorizacao: o token M2M carrega `organization_id`; o membro que ele pode ler e a
// organizacao a que o app pertence. Sem consulta extra, sem segundo registro.
import type { Context } from "hono";
import { readdir, readFile } from "node:fs/promises";
import { createHash } from "node:crypto";
import { join, basename } from "node:path";
import { config } from "./config.ts";
import { verifyOrganizationToken } from "./identity.ts";

// Mapa DERIVADO id-da-org -> membro, gerado por `logto-provision.sh --write-org-map`.
// O token so traz o id (medido); dar Management API ao bridge para traduzir seria
// conceder o universo por conveniencia. Id ausente do mapa => recusa, nunca adivinha.
const ORG_MAP = join(config.onionCwd, "docs/onion/federation-orgs.json");
async function memberOfOrg(orgId: string): Promise<string | null> {
  try {
    const m = JSON.parse(await readFile(ORG_MAP, "utf-8")) as Record<string, string>;
    return m[orgId] ?? null;
  } catch { return null; }
}

const OUTBOX = join(config.onionCwd, "docs/evolution/federation/outbox");

/** Nome de membro seguro: sem separador, sem `..`, sem oculto. Nao confiar no token. */
function safeMember(id: string): string | null {
  return /^[a-z0-9][a-z0-9._-]{0,63}$/.test(id) && !id.includes("..") ? id : null;
}

async function announcedTo(member: string) {
  const dir = join(OUTBOX, member, "_processed");
  let names: string[];
  try {
    names = (await readdir(dir)).filter((n) => n.endsWith(".md"));
  } catch {
    return [];
  }
  const out = [];
  for (const n of names.sort()) {
    const buf = await readFile(join(dir, n));
    out.push({ name: n, bytes: buf.length, sha256: createHash("sha256").update(buf).digest("hex") });
  }
  return out;
}

/**
 * GET /federation/inbox/:member          → manifesto (name, bytes, sha256)
 * GET /federation/inbox/:member?file=X   → conteudo de UM anuncio
 *
 * O `:member` da URL tem de bater com a organizacao do token. Divergencia => 403, e a
 * mensagem diz QUAL foi o conflito: identidade de transporte que nao amarra no recurso
 * pedido e buraco, nao muro (licao registrada no desenho da fatia 4).
 */
export async function handleFederationInbox(c: Context) {
  const wanted = safeMember(c.req.param("member") ?? "");
  if (!wanted) return c.json({ error: "membro inválido" }, 400);

  const auth = c.req.header("Authorization") ?? "";
  const bearer = auth.startsWith("Bearer ") ? auth.slice(7) : "";
  const orgId = bearer ? await verifyOrganizationToken(bearer) : null;
  if (!orgId) return c.json({ error: "requer token de organização (client_credentials + organization_id)" }, 401);
  const org = await memberOfOrg(orgId);
  if (!org) return c.json({ error: "organização desconhecida — mapa desatualizado no core" }, 403);
  if (org !== wanted) {
    return c.json({ error: `identidade pertence a '${org}', pediu '${wanted}'` }, 403);
  }

  const items = await announcedTo(wanted);
  const file = c.req.query("file");
  if (!file) {
    return c.json({ member: wanted, count: items.length, items });
  }
  const safeFile = basename(file);
  const hit = items.find((i) => i.name === safeFile);
  if (!hit) return c.json({ error: "anúncio não encontrado para este membro" }, 404);
  const buf = await readFile(join(OUTBOX, wanted, "_processed", hit.name));
  return c.text(buf.toString("utf-8"), 200, { "content-type": "text/markdown; charset=utf-8" });
}
