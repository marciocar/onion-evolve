---
title: "ADR-002 — Adoção (ou não) da Vercel AI SDK como camada-interface de modelo"
category: discussion-adr
status: proposed — aguarda ratificação do maestro (NÃO auto-selado)
date: 2026-07-19
branch: discuss/onion-pessoal-app
decision-scope: arquitetura do app pessoal / camada-interface de LLM (C_ALIGN)
deciders: maestro (ratifica); esta sessão conduz até o ADR verde (padrão D2 door-topology)
related:
  - research/standards-planb-research-2026-07.md (wzxz11dvf — Vercel AI SDK dominante; C_ALIGN)
  - ADR-001-arquitetura.md (D2 stack = executorch; D3 cérebro = claude-agent-sdk)
---

# ADR-002 — Vercel AI SDK como camada-interface de modelo?

> **PROPOSTO — não selado.** Conduzo até aqui; **o maestro ratifica** (decisão de arquitetura do app dele).
> Não marco "aceito" sozinho.

## Contexto
`C_ALIGN` (pesquisa de standards) apontou a **ausência da camada Vercel AI SDK** como o maior risco de divergência
dos padrões dominantes: *"cada troca local/nuvem vira reescrita de call-site; fora do ecossistema TS dominante."*
Este ADR decide **se e ONDE** adotá-la.

## Fatos verificados (fontes primárias)
1. **Vercel AI SDK = interface-padrão de LLM em TS** (25.6k stars, 20+ providers, ativa) — `wzxz11dvf`.
2. **`@ai-sdk/anthropic` é MODEL-provider** (verificado 2026-07-19): `generateText`/`streamText`, tool-calling,
   streaming, structured outputs — nível **Messages API**. **Separado** do `@anthropic-ai/claude-agent-sdk`
   (agent-loop com MCP/tools/subagents), sem dependência entre eles. **São camadas diferentes.**
3. **`callstack/ai` (react-native-ai) = on-device Vercel-AI-SDK-first-class** (verificado 2026-07-19; 1.4k stars,
   v0.12=AI SDK v6, jan/2026): roda **Apple Foundation Models · llama.rn(GGUF) · MLC**. **NÃO suporta executorch/.pte.**

## A tensão-núcleo (o que decide a forma)
- O **cérebro-nuvem** (D3) é um **agent-loop** (`claude-agent-sdk`), NÃO uma chamada de modelo → a Vercel AI SDK
  **não o substitui** (perderia MCP/tools/agent). Onde a Vercel AI SDK vale é a **camada de modelo direto** e o
  **on-device SLM** (troca local↔nuvem por provider).
- **MAS** a via on-device Vercel (`callstack/ai`) **não cobre executorch (D2)** → escolher a Vercel AI SDK
  on-device **reabre o D2**: executorch(.pte, provado — Whisper/VisionCamera/"Private Mind") **vs** llama.rn(GGUF,
  Vercel-nativo). Não dá os dois via callstack/ai sem um adapter executorch↔Vercel que **não existe**.
- **No near-term** (shell) o app é **cliente SSE fino do cérebro-agente** — **não faz troca local↔nuvem de modelo**.
  O valor da Vercel AI SDK só se realiza quando o **on-device SLM** entrar (camada futura, `Q_DEID`).

## Opções
- **A — Adotar como padrão de interface de modelo, deferir o provider on-device.** Cérebro-nuvem fica
  `claude-agent-sdk`; a Vercel AI SDK vira o **contrato/seam** que o app codifica p/ chamadas de modelo direto +
  on-device; a escolha concreta **executorch × llama.rn** vira **sub-decisão do spike Q_DEID/Q_PERF**.
- **B — Não adotar agora; deferir tudo.** Mantém D2 (executorch) intacto; menos camadas; near-term não precisa.
  Custo: se a rota híbrida local↔nuvem virar real, retrofit; `C_ALIGN` fica aberto.
- **C — Adotar Vercel AI SDK + trocar on-device p/ llama.rn/GGUF (via callstack/ai).** Alinhamento total; mas
  **abandona executorch** (perde STT Whisper/VisionCamera/produção-provada) — troca de ecossistema (.pte→GGUF).

## Recomendação (proposta — a ratificar)
**Opção A.** Justificativa:
1. **Cérebro-nuvem: mantém `claude-agent-sdk`** — a Vercel AI SDK não é do nível certo (agent-loop). Zero mudança em D3.
2. **Adotar a Vercel AI SDK como o PADRÃO-DE-INTERFACE de modelo** (contrato que o app codifica) — fecha o `C_ALIGN`
   (não ficar fora do ecossistema TS dominante) e torna a rota híbrida futura uma troca de provider, **direcional**.
3. **NÃO forçar o provider on-device agora.** executorch(D2) × llama.rn(callstack/ai) é **sub-decisão acoplada ao
   spike Q_DEID/Q_PERF** (device-blocked) — porque callstack/ai não cobre executorch. Decidir no dado real do spike,
   não no papel. Near-term (shell) não depende disso.

**Efeito líquido:** compromisso **direcional** com a Vercel AI SDK na camada de modelo, **sem** tocar o cérebro-agente
e **sem** reabrir o D2 no papel — a resolução executorch×GGUF fica onde o dado vai existir (o spike on-device).

## Consequências / aberto
- Reabre uma **tensão D2↔Vercel** que só fecha no spike on-device (`Q_DEID`): se o de-id/SLM valer mais via
  llama.rn(GGUF, Vercel-nativo) ou via executorch(.pte, features) — dado real decide.
- Sub-pergunta nova: existe/vale um **adapter executorch↔Vercel AI SDK** (custom)? (não existe hoje).
- Status **proposto** — o maestro ratifica (→ `accepted`) ou ajusta a opção.
