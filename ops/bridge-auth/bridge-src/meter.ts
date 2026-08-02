// Medidor de recursos do Onion — append-only, auditável, SÓ METADADO NUMÉRICO.
//
// Doutrina: docs/analysis/onion-adr-hosted-service-identity-2026-08.md
//   · MEDIR PARA LIMITAR, não cobrar por unidade (cobrança por unidade = outro ADR).
//   · "MEDIDO ≠ COBRÁVEL" — nasce auditável mesmo servindo só a observabilidade,
//     porque reformar medidor depois que ele vira base de cota é caro.
//   · Unidade de conta = Organization do Logto (projetada de members.yaml, o SSOT).
//   · ESCOPO FECHADO: nunca prompt, completion, payload ou nome de arquivo.
//     Acrescentar campo de CONTEÚDO exige novo ADR. (A lição do incidente do evento
//     `message` do WAHA, 2026-08-01, mecanizada: escopo é decisão, não conveniência.)
//
// Quem paga (dimensão levantada pelo maestro 2026-08-01): o `payer` deriva do
// tokenType que o authGuard já injeta. `byok` = o membro traz a própria chave (o
// custo é DELE — mede-se eficiência, não se limita); `courtesy`/`oidc`/`admin` =
// a credencial é do core (é subsídio — é o que entra em cota).
//
// Honestidade do dado: campo ausente é gravado como null, JAMAIS estimado.
// `partial: true` marca a linha em que o SDK não entregou usage — para que a
// contagem saiba o que ela NÃO sabe (aceite ≠ entrega, aplicado à medição).

import { appendFileSync, mkdirSync } from "node:fs";
import { dirname, join } from "node:path";

export type Payer = "core" | "member" | "unknown";

export interface MeterLine {
  ts: string;                    // ISO-8601 UTC
  org: string | null;            // Organization do Logto (null quando o token não a carrega)
  sub: string | null;            // ator (humano ou serviço)
  payer: Payer;                  // quem custeia — deriva do tokenType
  token_type: string | null;     // oidc | admin | courtesy | byok (o valor bruto, para auditoria)
  resource: string;              // ex.: "ai.chat"
  quantity: number | null;       // valor medido (tokens, bytes, contagem)
  unit: string;                  // ex.: "tokens", "usd", "call"
  model: string | null;          // quando aplicável
  partial: boolean;              // true = o provedor não entregou a métrica; NÃO estimar
}

/** tokenType (do authGuard) → quem custeia. `byok` é o único em que o membro paga. */
export function payerOf(tokenType: string | null | undefined): Payer {
  if (!tokenType) return "unknown";
  if (tokenType === "byok") return "member";
  if (tokenType === "oidc" || tokenType === "courtesy" || tokenType === "admin") return "core";
  return "unknown";
}

/** Caminho do ledger. Um arquivo por dia — rotação trivial, sem daemon. */
export function meterPath(baseDir: string, when = new Date()): string {
  const day = when.toISOString().slice(0, 10);
  return join(baseDir, "meter", `${day}.jsonl`);
}

/**
 * Grava UMA linha append-only. Nunca lança: medir não pode derrubar o que se mede
 * (um medidor que quebra a requisição é pior que a ausência dele).
 */
export function record(baseDir: string, line: MeterLine): void {
  try {
    const p = meterPath(baseDir, new Date(line.ts));
    mkdirSync(dirname(p), { recursive: true });
    appendFileSync(p, JSON.stringify(line) + "\n", "utf8");
  } catch {
    // silencioso por decisão: a medição é observacional, jamais bloqueante.
  }
}

/**
 * Extrai as métricas do evento `result` do Agent SDK — DEFENSIVAMENTE.
 * O formato do SDK não é contrato nosso e já mudou no passado; por isso lemos o
 * que existir e marcamos `partial` quando não existir, em vez de assumir a forma.
 * (doc ≠ comportamento: 5 divergências medidas só no Logto nesta mesma sessão.)
 */
export function fromSdkResult(msg: unknown): {
  inputTokens: number | null;
  outputTokens: number | null;
  cacheReadTokens: number | null;
  cacheWriteTokens: number | null;
  costUsd: number | null;
  model: string | null;
} {
  const m = (msg ?? {}) as Record<string, unknown>;
  const num = (v: unknown): number | null => (typeof v === "number" && Number.isFinite(v) ? v : null);
  const str = (v: unknown): string | null => (typeof v === "string" && v.length > 0 ? v : null);

  // FORMA REAL, MEDIDA em 2026-08-01 contra o SDK vivo (doc != comportamento — a
  // 6a divergencia desta sessao): o evento `result` traz `modelUsage`, um objeto
  // CHAVEADO PELO NOME DO MODELO, com inputTokens/outputTokens/costUSD em camelCase
  // e — decisivo — cacheCreationInputTokens, que DOMINA o custo real (medido:
  // 9635 tokens de cache-write contra 40 de input). Ignorar cache e reportar
  // custo errado por ordem de grandeza.
  const mu = (m.modelUsage ?? {}) as Record<string, Record<string, unknown>>;
  const modelKey = Object.keys(mu)[0] ?? null;
  const u = (modelKey ? mu[modelKey] : {}) ?? {};

  // Os fallbacks snake_case ficam: se o SDK voltar ao formato documentado, ainda lemos.
  const legacy = (m.usage ?? {}) as Record<string, unknown>;

  return {
    inputTokens: num(u.inputTokens) ?? num(legacy.input_tokens),
    outputTokens: num(u.outputTokens) ?? num(legacy.output_tokens),
    cacheReadTokens: num(u.cacheReadInputTokens) ?? num(legacy.cache_read_input_tokens),
    cacheWriteTokens: num(u.cacheCreationInputTokens) ?? num(legacy.cache_creation_input_tokens),
    costUsd: num(u.costUSD) ?? num(m.total_cost_usd) ?? num(m.cost_usd),
    model: modelKey ?? str(m.model),
  };
}

/**
 * Registra o consumo de uma chamada de IA a partir do evento `result` do SDK.
 * Emite ATÉ 3 linhas (input, output, custo) — uma por métrica, para que cada uma
 * seja somável sem desempacotar objeto. Se o SDK não entregar nada, emite 1 linha
 * `unit:"call"` com `partial:true` — a chamada aconteceu e isso é fato mesmo sem números.
 */
export function recordAiResult(
  baseDir: string,
  ctx: { org: string | null; sub: string | null; tokenType: string | null },
  sdkResult: unknown,
): void {
  const { inputTokens, outputTokens, cacheReadTokens, cacheWriteTokens, costUsd, model } =
    fromSdkResult(sdkResult);
  const base = {
    ts: new Date().toISOString(),
    org: ctx.org,
    sub: ctx.sub,
    payer: payerOf(ctx.tokenType),
    token_type: ctx.tokenType ?? null,
    resource: "ai.chat",
    model,
  };

  const metrics: Array<{ quantity: number | null; unit: string }> = [];
  if (inputTokens !== null) metrics.push({ quantity: inputTokens, unit: "tokens.input" });
  if (outputTokens !== null) metrics.push({ quantity: outputTokens, unit: "tokens.output" });
  if (cacheReadTokens !== null) metrics.push({ quantity: cacheReadTokens, unit: "tokens.cache_read" });
  if (cacheWriteTokens !== null) metrics.push({ quantity: cacheWriteTokens, unit: "tokens.cache_write" });
  if (costUsd !== null) metrics.push({ quantity: costUsd, unit: "usd" });

  if (metrics.length === 0) {
    record(baseDir, { ...base, quantity: 1, unit: "call", partial: true });
    return;
  }
  for (const m of metrics) record(baseDir, { ...base, ...m, partial: false });
}
