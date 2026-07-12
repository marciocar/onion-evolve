---
title: "Nota 05 — Dogfood da prova barata: telemetria real de sessão (evidência)"
category: discussion-evidence
status: fonte-de-discussao-isolada
date: 2026-07-12
branch: discuss/interface-state-of-art
executa: NOTE-01 fio 3 (a prova barata proposta)
atualiza: NOTE-01, NOTE-03
metodo: dogfood real (não teoria) — sink OTLP local + sub-sessão claude -p instrumentada
---

# 🧵 Nota 05 — Dogfood: `CLAUDE_CODE_ENABLE_TELEMETRY=1` numa sessão real

> **Isolada.** Pensa, não entrega. Nada vai pro core sem o maestro pedir.
> Executa a prova barata que a Nota 01 (fio 3) propôs. Rodou de ponta a ponta em
> telemetria real. Honra a própria doutrina: local-first, só estrutura, intake (sem tocar o core).

## Setup (reproduzível)

- **Sink OTLP local** (`otlp_sink.py`, ~50 linhas Python, sem dependências): escuta `127.0.0.1:4318`,
  aceita OTLP/HTTP-JSON, grava ndjson por sinal. Local-first — nada sai da máquina.
- **Sub-sessão real:** `claude -p "<tarefa de 3 arquivos>" --allowedTools "Write" "Bash(wc:*)"`, com
  `CLAUDE_CODE_ENABLE_TELEMETRY=1` + `CLAUDE_CODE_ENHANCED_TELEMETRY_BETA=1` (traces) apontando pro sink.
- **Conteúdo OFF:** `OTEL_LOG_USER_PROMPTS` etc. **não** setados — intake=estrutura, conteúdo gated.
- Captura: 7 payloads de metrics, 6 de logs, 5 de traces (~336K ndjson real).

## O que funcionou — Nota 01 confirmada MECANICAMENTE

- **Estrutura veio de graça, conteúdo ficou fora, custo zero.** Capturado: `token.usage`
  (input 581, output 860, cacheRead 112827, cacheCreation 15927), `cost.usage` $0.237,
  `code_edit_tool.decision`, `lines_of_code.count[added]=15`, e a árvore de trajetória:
  `claude_code.interaction` (16,5s) → `llm_request` (5×, méd 3,4s / max 7,4s) → `tool` (5×) →
  `tool.execution`. **Nenhum prompt/código** em lugar nenhum. A linha intake=estrutura /
  conteúdo=gated **segurou por construção**.
- **Sinais de alto valor existem e são consultáveis:** `tool_decision` (4× accept / 0× reject),
  `tool_result`, `api_request` (5), reconstrução por sessão via spans. O instrumento que as Notas
  01–03 assumiram é real e já embarcado.

## Os dois achados que o dogfood revelou (a teoria errou) → atualizam as notas

### Achado A — `blocked_on_user` flatlina em headless; o sinal de fadiga de gate EXIGE interativo
O span `claude_code.tool.blocked_on_user` **existe** (5×, 47ms total) mas é só overhead de checagem
— não há humano esperando num `-p`. Isso **confirma na prática** a tese das Notas 03/04: o custo-do-gate
só é mensurável **com humano no loop**. → **Atualiza N01/N03:** para dogfoodar design de gate de verdade,
instrumentar a sessão **interativa**, não headless. O sinal-âncora do loop (N01→N03) é interativo-only.

### Achado B — "estrutura grátis" é grátis mas RUIDOSA; filtro de prefixo é passo-0
O stream veio **entrelaçado com a telemetria do próprio app da máquina**: `prisma:engine:*` (7 spans),
`rhilo.bullmq.queue.jobs=103`, `[Outbox] Found 0 pending events`, `mcp_server_connection ×6`,
`plugin_loaded ×6`, `nodejs.eventloop.*`, `v8js.memory.*`. → **Atualiza N01:** o substrato é grátis mas
**não limpo**. Instrumentar a sessão ≠ sinal limpo — exige um **filtro de prefixo `claude_code.*` /
`gen_ai.*` como passo-0** obrigatório antes de qualquer análise. A Nota 01 subvalorizou esse custo.

## O limite honesto (escopo correto de uma prova barata)

Tarefa trivial → `0 reject`, `1 interaction`. **Nenhum padrão-candidato emergiu** — nem poderia: a própria
Nota 02 (Rule of Three) exige **N≥3 sessões reais independentes**. A prova mostra que **o instrumento
funciona e o que ele captura**; **não** que um padrão existe. É exatamente o que uma prova barata deve
entregar — e não fingir entregar mais. Próximo passo real: instrumentar N sessões **interativas** e só
então rodar detecção de recorrência (N02) sobre `tool_decision` reject-rate + `blocked_on_user` + loops.

## O bônus meta (a doutrina se dogfoodou sozinha)

Na 1ª tentativa, o **gate de auto-mode do Claude Code barrou** `--permission-mode bypassPermissions` com a
razão *"spawns an autonomous agent loop... disabling all per-action approval gates"*. Foi **um exemplo vivo
da tese da Nota 04**: o gate de execução disparando no antipadrão "agente autônomo sem aprovação humana".
Não contornei — usei allowlist escopado. A linha intake×execução se materializou **no meio do experimento**,
não na prosa.

## Veredito

A prova barata **passou no seu escopo**: pipe real, estrutura grátis, conteúdo gated por construção, sinais
de alto valor presentes. E entregou o que dogfood entrega e teoria não: **dois ajustes de design** (gate-signal
é interativo-only; filtro-de-prefixo é passo-0) e **um exemplo vivo** da própria doutrina. Tudo intake, local,
isolado — nada foi pro core.

## Artefatos (efêmeros, no scratchpad da sessão)

- `otlp_sink.py` (sink), `analyze.py` (extrator), `otlp-capture/*.ndjson` (captura real).
- Não versionados — evidência de dogfood, não código de produto. Reproduzível pelo setup acima.
