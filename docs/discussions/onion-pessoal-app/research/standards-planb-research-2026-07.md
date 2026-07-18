# Pesquisa: plano-B do SLM antecipado + estratégias populares a não perder (deep-research, 2026-07-18)

> Fonte: deep-research `wzxz11dvf` — 100 agentes, verificação adversarial, fontes primárias.
> ⚠ **Caveat metodológico forte:** o orçamento de WebSearch dos verificadores esgotou (200/200) → a maioria dos
> claims foi confirmada contra a **fonte primária única** (repo/docs oficiais), sem 2ª busca adversarial. Forte
> para fatos descritivos ("o que o repo afirma de si"); mais fraco para **dominância/adoção de mercado** (parte
> auto-descrição do vendor). Tratar rankings de dominância como indicativos.

## (A) Plano-B: arquitetura de conexão se o SLM for ANTECIPADO

1. **Camada-interface = Vercel AI SDK** sobre todo consumo de LLM (app + backend) → modelo **local** e **cérebro-
   nuvem (Claude Agent SDK)** viram **troca de string de provider**. (25.6k stars, 20+ providers, release 17/07/2026 = viva.)
2. **Roteamento HÍBRIDO app-level** local↔nuvem: local p/ **de-id/PII/offline**, nuvem p/ raciocínio pesado.
   Padrão **shipped em escala**: Apple Intelligence (~3B on-device + Private Cloud Compute) + RouteLLM (LMSYS, −85% custo/95% perf).
   *Nuance:* a AI SDK é o **substrato** (troca de provider), NÃO o roteador — a política é lógica app-level.
3. **Runtime on-device** = executorch/.pte (já no stack) ou llama.rn/GGUF, exposto por **hooks** (`useLLM`).
4. **Bridge = adapter:** nenhum runtime on-device é **OpenAI-compatible drop-in** → entra na AI SDK via adapter
   (callstack/ai é a referência: "first-class Vercel AI SDK support"). llama.rn usa métodos nativos `context.completion()`.
5. **Tools/contexto = MCP** no lado do cérebro Claude (ver abaixo).

## (B) Standards dominantes que NÃO podemos perder (ranqueado + risco de divergir)

| # | Standard | Risco de divergir | Nosso stack |
|---|---|---|---|
| 1 | **Vercel AI SDK** (interface-padrão de LLM em TS) | cada troca local/nuvem vira reescrita de call-site; fora do ecossistema TS dominante | ⚠ **NÃO adotado ainda** — é o principal risco |
| 2 | **MCP** (Model Context Protocol — tools/contexto) | reimplementar tools fora do padrão que Claude/OpenAI/Google já falam | ✅ **JÁ alinhado** — Claude Agent SDK usa MCP nativo (`mcpServers`, stdio/HTTP-SSE/in-process) |
| 3 | **Roteamento híbrido** local↔nuvem | nuvem-only quebra offline/PII; local-only perde raciocínio | 🟡 a desenhar (é o D5 + plano-B) |
| 4 | **Formato on-device** (GGUF · .pte · MLC — 3 famílias, sem vencedor único) | lock-in de família ao escolher | ✅ `.pte` (executorch) é família válida |

**MCP é forte:** standard aberto cross-vendor (OpenAI mar/2025, Google abr/2025, doado à Agentic AI Foundation dez/2025).
Estar no MCP = já estar no padrão que os grandes falam.

## Alinhamento do stack atual
- ✅ **JÁ alinhado:** MCP (Agent SDK nativo) + formato on-device válido (.pte).
- ⚠ **Risco de divergência:** (a) ausência da **camada Vercel AI SDK** (a decisão de arquitetura mais importante que falta);
  (b) **custo do adapter** do executorch — não é OpenAI-compatible, precisa de shim pra entrar na AI SDK.

## Refutados (verificação adversarial)
- callstack/ai **NÃO** é "drop-in replacement" (1-2) nem padroniza em GGUF-excluindo-executorch (1-2).
- Ollama/LM Studio **NÃO** são providers oficiais embarcados na AI SDK (0-3) — entram via OpenAI-compatible/community.

## 🕳️ LACUNA GRANDE (nenhum claim sobreviveu — precisa de rodada dedicada)
- **Sincronização local-first** (CRDTs Yjs/Automerge vs **git** vs movimento Ink & Switch): **zero evidência** sobreviveu.
  Liga direto com `Q_GITSYNC` (o git-no-device já flagado). **É a próxima pesquisa a fazer antes de decidir a camada de sync.**
- **AI SDK data stream protocol** específico: só houve evidência de SSE como transporte MCP, não do wire-format da Vercel.
