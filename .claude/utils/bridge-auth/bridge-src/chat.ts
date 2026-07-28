// Handler do POST /chat: roda o Onion via Claude Agent SDK e devolve o output em SSE.
// Suporta: texto puro, imagem inline base64, upload multipart (arquivo genérico) e systemPromptAppend.
import type { Context } from "hono";
import { streamSSE } from "hono/streaming";
import { query, type SDKUserMessage } from "@anthropic-ai/claude-agent-sdk";
import type { ImageBlockParam, Base64ImageSource } from "@anthropic-ai/sdk/resources";
import { writeFileSync, unlinkSync, existsSync } from "node:fs";
import { join } from "node:path";
import { randomUUID } from "node:crypto";
import { config } from "./config.ts";
import { ensureWorkspace } from "./workspace.ts";

// MIME types aceitos para imagens inline e upload.
const ALLOWED_IMAGE_MIME = new Set([
  "image/jpeg",
  "image/png",
  "image/gif",
  "image/webp",
]);

// Tipos de MIME aceitos para qualquer upload de arquivo (imagens + PDF + texto).
const ALLOWED_UPLOAD_MIME = /^(image\/.+|application\/pdf|text\/.*)$/;

interface ChatBody {
  prompt?: string;
  sessionId?: string;
  // Imagem inline (compat, única): data-URI "data:<mime>;base64,<dados>" ou base64 puro.
  image?: string;
  // Imagens inline (múltiplas): cada item é data-URI ou base64 puro (usa imageMimeType).
  images?: string[];
  // MIME da imagem quando `image` é base64 puro sem data-URI prefix.
  imageMimeType?: string;
  // Texto adicional a anexar ao system prompt do Claude Code.
  context?: string;
  // Alias de `context` — o front pode usar qualquer um dos dois.
  systemPromptAppend?: string;
}

/**
 * Extrai (mimeType, base64Data) de um valor que pode ser:
 *   - data-URI:  "data:image/png;base64,iVBORw0..."
 *   - base64 puro: requer mimeType explícito em imageMimeType
 */
function parseImageField(
  raw: string,
  mimeHint?: string,
): { mimeType: Base64ImageSource["media_type"]; data: string } | null {
  const dataUriMatch = raw.match(/^data:(image\/[^;]+);base64,(.+)$/);
  if (dataUriMatch) {
    const mimeType = dataUriMatch[1] as Base64ImageSource["media_type"];
    const data = dataUriMatch[2];
    if (!ALLOWED_IMAGE_MIME.has(mimeType)) return null;
    return { mimeType, data };
  }

  // Base64 puro: mime vem do campo imageMimeType
  const mime = mimeHint ?? "";
  if (!ALLOWED_IMAGE_MIME.has(mime)) return null;
  return { mimeType: mime as Base64ImageSource["media_type"], data: raw };
}

export async function handleChat(c: Context) {
  // byokKey presente se tokenType === 'byok' (injetado pelo authGuard).
  const byokKey = (c as Context & { var?: { byokKey?: string } }).var?.byokKey;

  // Resolve workspace isolado por token (idempotente — cria só na 1ª vez).
  const bearer = (c.req.header("Authorization") ?? "").replace(/^Bearer /, "");
  const { cwd, uploadsDir } = bearer
    ? await ensureWorkspace(bearer)
    : { cwd: config.onionCwd, uploadsDir: config.uploadTempDir };

  const contentType = c.req.header("Content-Type") ?? "";
  const isMultipart = contentType.includes("multipart/form-data");

  // ── Caminho 1: multipart/form-data (upload de arquivo) ─────────────────────
  if (isMultipart) {
    return handleMultipartChat(c, cwd, uploadsDir);
  }

  // ── Caminho 2: JSON (texto puro ou imagem inline base64) ───────────────────
  let body: ChatBody;
  try {
    body = await c.req.json<ChatBody>();
  } catch {
    return c.json({ error: "corpo JSON inválido" }, 400);
  }

  const prompt = body.prompt?.trim();
  if (!prompt) {
    return c.json({ error: "campo 'prompt' é obrigatório" }, 400);
  }

  const appendText = (body.systemPromptAppend ?? body.context ?? "").trim();

  // Imagens inline (base64 / data-URI). Aceita `images[]` (múltiplas) e `image` (compat).
  // Todas viram blocos multimodais; lista vazia => texto puro (caminho original).
  const rawImages = [...(body.images ?? []), ...(body.image ? [body.image] : [])];
  const imageBlocks: ImageBlockParam[] = [];
  for (const raw of rawImages) {
    const parsed = parseImageField(raw, body.imageMimeType);
    if (!parsed) {
      return c.json(
        { error: "imagem inválida — use data-URI (data:image/<mime>;base64,...) com mime em image/jpeg|png|gif|webp" },
        400,
      );
    }
    imageBlocks.push({
      type: "image",
      source: { type: "base64", media_type: parsed.mimeType, data: parsed.data },
    });
  }

  return runQuery(c, prompt, appendText, body.sessionId, imageBlocks, [], byokKey, cwd, uploadsDir);
}

// ── Upload multipart ──────────────────────────────────────────────────────────
async function handleMultipartChat(c: Context, cwd: string, uploadsDir: string) {
  let formData: Record<string, string | File>;
  try {
    formData = await c.req.parseBody();
  } catch {
    return c.json({ error: "multipart inválido" }, 400);
  }

  const prompt = typeof formData.prompt === "string" ? formData.prompt.trim() : "";
  if (!prompt) {
    return c.json({ error: "campo 'prompt' é obrigatório" }, 400);
  }

  const appendText =
    typeof formData.systemPromptAppend === "string"
      ? formData.systemPromptAppend.trim()
      : typeof formData.context === "string"
        ? formData.context.trim()
        : "";

  const sessionId = typeof formData.sessionId === "string" ? formData.sessionId : undefined;
  const byokKey = (c as Context & { var?: { byokKey?: string } }).var?.byokKey;

  const file = formData.file;
  if (!file || typeof file === "string") {
    return c.json({ error: "campo 'file' (File) é obrigatório no upload multipart" }, 400);
  }

  // Validação de MIME
  const mime = file.type ?? "";
  if (!ALLOWED_UPLOAD_MIME.test(mime)) {
    return c.json({ error: `tipo de arquivo não permitido: ${mime}` }, 400);
  }

  // Validação de tamanho
  const maxBytes = config.maxUploadSizeMB * 1024 * 1024;
  if (file.size > maxBytes) {
    return c.json(
      { error: `arquivo excede o limite de ${config.maxUploadSizeMB} MB` },
      413,
    );
  }

  // Nome seguro (anti path-traversal)
  const ext = file.name.split(".").pop()?.replace(/[^a-zA-Z0-9]/g, "") ?? "bin";
  const safeName = `${randomUUID()}.${ext}`;
  const filePath = join(uploadsDir, safeName);

  const bytes = await file.arrayBuffer();
  writeFileSync(filePath, Buffer.from(bytes));

  return runQuery(c, prompt, appendText, sessionId, [], [filePath], byokKey, cwd, uploadsDir);
}

// ── Motor central: cria o query e faz stream SSE ──────────────────────────────

// ── P10 — CAPACIDADE por identidade ────────────────────────────────────────────
// P0-P9 fecharam QUEM entra; nada limitava O QUE se pode fazer. `bridge:invoke` era
// tudo-ou-nada e todo chamador autenticado executava irrestrito — o ganho real da
// identidade e poder DIFERENCIAR, e sem isto so trocamos "quem tem o segredo faz tudo"
// por "quem tem identidade faz tudo".
//
// A restricao mora em `tools` do Agent SDK. NAO em `allowedTools`: a doc do pacote
// (v0.3.195) e explicita — allowedTools "auto-allows without prompting", e "to restrict
// which tools are available, use the `tools` option instead". Usar allowedTools como
// allowlist produziria uma guarda que NAO GUARDA — falso-verde por construcao.
//
// `Task` fica de FORA de proposito: um subagente poderia receber o conjunto completo,
// e ai a restricao vazaria pelo delegado.
const READ_ONLY_TOOLS = ["Read", "Grep", "Glob", "WebFetch", "WebSearch", "TodoWrite"];

/** true se a identidade do chamador carrega `bridge:write`. Sem identidade (a2a) => false. */
function callerCanWrite(c: Context): boolean {
  const id = (c as Context & { var?: { identity?: { scopes?: string[] } } }).var?.identity;
  return Array.isArray(id?.scopes) && id!.scopes!.includes("bridge:write");
}

async function runQuery(
  c: Context,
  prompt: string,
  appendText: string,
  sessionId: string | undefined,
  imageBlocks: ImageBlockParam[],
  uploadedFiles: string[],
  byokApiKey: string | undefined,
  cwd: string,
  uploadsDir: string,
) {
  return streamSSE(c, async (stream) => {
    try {
      // Quando há arquivos enviados, anexa os caminhos ao prompt para que o Onion
      // saiba ONDE ler (additionalDirectories só concede acesso, não revela o path).
      const effectivePrompt =
        uploadedFiles.length > 0
          ? `${prompt}\n\n[Arquivo(s) anexado(s) para você ler com a ferramenta Read]:\n` +
            uploadedFiles.map((f) => `- ${f}`).join("\n")
          : prompt;

      // Quando há imagem inline, o prompt vai como AsyncIterable<SDKUserMessage>
      // com content multimodal. Sem imagem, permanece string (caminho original).
      let promptParam: string | AsyncIterable<SDKUserMessage>;

      if (imageBlocks.length > 0) {
        async function* makeMessages(): AsyncIterable<SDKUserMessage> {
          yield {
            type: "user",
            parent_tool_use_id: null,
            message: {
              role: "user",
              content: [
                { type: "text", text: effectivePrompt },
                ...imageBlocks,
              ],
            },
          } satisfies SDKUserMessage;
        }
        promptParam = makeMessages();
      } else {
        promptParam = effectivePrompt;
      }

      const conversation = query({
        prompt: promptParam,
        options: {
          cwd,
          settingSources: ["project"],
          permissionMode: config.permissionMode,
          ...(config.permissionMode === "bypassPermissions"
            ? { allowDangerouslySkipPermissions: true }
            : {}),
          // Sem `bridge:write` o chamador LE e PROPOE; nao escreve, nao executa.
          ...(callerCanWrite(c) ? {} : { tools: READ_ONLY_TOOLS }),
          ...(sessionId ? { resume: sessionId } : {}),
          // Expõe arquivos enviados via upload ao Onion (ferramenta Read do SDK).
          ...(uploadedFiles.length > 0
            ? { additionalDirectories: [uploadsDir] }
            : {}),
          // Contexto extra no system prompt (context / systemPromptAppend).
          ...(appendText
            ? { systemPrompt: { type: "preset", preset: "claude_code", append: appendText } as const }
            : {}),
          // BYOK: substitui a chave do servidor pela chave do usuário.
          // O SDK aceita `env` que SUBSTITUI process.env no subprocess —
          // espalhamos process.env para preservar PATH, HOME, etc.
          ...(byokApiKey
            ? { env: { ...process.env, ANTHROPIC_API_KEY: byokApiKey } as Record<string, string> }
            : {}),
        },
      });

      let sentSession = false;
      for await (const message of conversation) {
        const type = (message as { type?: string }).type ?? "message";

        // Devolve o session_id uma única vez (para resume no cliente).
        if (!sentSession) {
          const sid = (message as { session_id?: string }).session_id;
          if (sid) {
            sentSession = true;
            await stream.writeSSE({ event: "session", data: JSON.stringify({ sessionId: sid }) });
          }
        }

        await stream.writeSSE({ event: type, data: JSON.stringify(message) });
      }

      await stream.writeSSE({ event: "done", data: "{}" });
    } catch (err) {
      await stream.writeSSE({
        event: "error",
        data: JSON.stringify({ message: err instanceof Error ? err.message : String(err) }),
      });
    } finally {
      // Cleanup de arquivos temporários de upload.
      for (const fp of uploadedFiles) {
        try {
          if (existsSync(fp)) unlinkSync(fp);
        } catch {
          // silencioso — arquivo já pode ter sido removido
        }
      }
    }
  });
}
