---
title: "Nota 01 — Telemetria útil e ética da própria sessão (pergunta 1 do SEED)"
category: discussion-note
status: fonte-de-discussao-isolada
date: 2026-07-12
branch: discuss/interface-state-of-art
responde: SEED.md — pergunta 1
metodo: pesquisa orquestrada citada (3 frentes) antes de posição
---

# 🧵 Nota 01 — Que telemetria seria útil e ética capturar da própria sessão

> **Isolada.** Pensa, não entrega. Nada vai pro core sem o maestro pedir.
> Síntese de discussão aterrada em pesquisa citada (não priors). Fontes ao final.

## Posição em uma linha

A pergunta tem duas metades aparentemente independentes (útil / ético), mas a nossa
situação **colapsa a metade ética quase inteira** — e o risco que sobra não é o intuitivo.
O eixo útil aponta para sinais de **atrito/retrabalho**, não de produtividade. E o mais
acionável: **não precisamos instrumentar do zero** — o Claude Code já emite a matéria-prima.

## O que a pesquisa mudou nos priors (lente Aristóteles: igual→transfere / diferente→desenha)

- **Bossware / vigilância de produtividade** — *diferente, não transfere.* O dano documentado
  (Amazon FR multada €32M pela CNIL; mercado "bossware" US$587M→1,4B; ansiedade/rotatividade)
  vem de uma assimetria estrutural: **observado ≠ beneficiário**. O marcador ético não é a
  granularidade do dado — é *quem se beneficia da inferência e quem pode agir sobre ela*. No
  nosso caso **observado = beneficiário = quem age = o maestro** → desloca o instrumento por
  definição para "observability de sistema", não "vigilância de pessoa". O que **transfere** é
  a invariante: quando um terceiro observador aparece (compartilhar relatório, treinar modelo),
  a simetria quebra e exige novo consentimento.
- **Differential privacy (Apple/Google)** — *diferente, não transfere.* DP resolve "n usuários,
  1 observador central"; sessão única não tem população para adicionar ruído. Princípio
  transferível (mais fraco): *preferir sinal agregado/sintético a replay bruto navegável* — não
  por privacidade contra terceiro, mas para reduzir a **auto-vigilância retrospectiva**.
- **OpenTelemetry GenAI semconv** — *igual, transfere direto.* Vocabulário padrão já existe:
  `gen_ai.conversation.id` (sessão), `gen_ai.tool.*`, `gen_ai.usage.{input,output,cache_*}_tokens`,
  `finish_reasons`; cada tool-call/LLM-call/retrieval como *child span* reconstruindo a cadeia de
  decisão. Adotar os nomes canônicos faz o KG falar a mesma língua que qualquer backend OTel
  (mas estão em *Development* — versionar o mapping).

## Achado mais acionável: o Claude Code **já emite** isto

`CLAUDE_CODE_ENABLE_TELEMETRY=1` (+ traces beta) expõe via OTLP, sem construir instrumento:
- `session.id` em todo span (filtra a sessão como timeline);
- eventos `tool_decision` (aceite/rejeição de Edit/Write = **retrabalho direto**) e `tool_result`;
- span `claude_code.tool.blocked_on_user` = **tempo esperando permissão humana** (custo do gate);
- subagentes (Task) aninham sob o span do pai → **toda a cadeia de delegação vira um trace só**;
- **estrutura vem de graça; conteúdo é opt-in gated** (`OTEL_LOG_USER_PROMPTS`, `OTEL_LOG_TOOL_CONTENT`…).

## A resposta em duas metades

### Útil — sinais de alto valor (paper "Signals", arXiv 2604.00356)

Contra-intuitivo: os reveladores são de **degradação**, não de produção:
- `tool_decision` reject-rate → *retrabalho/atrito* (onde o que produzi foi rejeitado);
- `blocked_on_user` → *onde o gate humano me segurou* (quantifica o custo do gating — liga no estudo intake×execução);
- **repeated-span / loops** → *onde travei* (repetição cresce ~step 9 = candidato a "stalled");
- `finish_reasons` + errors → *falhas*;
- custo/tokens **por fase/subtarefa** (custo modelado por token, não por request);
- eval score anexado à sessão → *o que funcionou*.

### Ético — a linha

Colapsada a assimetria de vigilância, sobra **um** risco real (revisão de 65 estudos de
quantified-self, Tandfonline): o **paradoxo da auto-vigilância** — "performance para o próprio
dashboard", ansiedade de otimizar a métrica em vez de refletir, mesmo sem observador externo.
Mitigação assinada: **sinais formativos, não performáticos** — nada de rankings ou scores
comparáveis ao longo do tempo que convidem a auto-disciplina punitiva. "O que aprendi / que
padrão se repete" > "fui X% mais rápido que ontem".

## Onde o estudo intake×execução governa isto

- **Telemetria de estrutura** (tokens, latência, `tool_decision`, grafo de spans) = **intake de
  fonte permitida (a própria sessão) → autônoma**, sem gate.
- **Telemetria de conteúdo** (trechos de prompt/código) ganha gate **não por ser "execução"**
  (continua intake), mas por um segundo princípio: **purpose limitation** (GDPR Art. 5). O padrão
  que separa "aceitável" de "revolta" é esse — "diagnóstico anônimo" nunca pode secretamente
  carregar payload de conteúdo (casos devenv 2025, Copilot opt-in→opt-out 2026). Modelo JetBrains:
  toggle dedicado, *default-off*, para dado de conteúdo.

Resumo da régua: a linha intake×execução libera a **estrutura** sozinha; o **conteúdo** ganha uma
segunda trava (opt-in, propósito declarado, não-reaproveitável) que é sobre *finalidade*, não execução.

## A conexão que fecha com o NS1 (o diferenciador)

O gap que a pesquisa de agentes aponta como fronteira aberta (arXiv 2603.10600, 2602.05665) é
**provenance do aprendizado de volta à trajetória-fonte** — condensar cada nó de decisão em
*pitfall/success* num grafo persistente. **O Onion já faz esse loop, em prosa**: diário → padrão
candidato → doutrina. A telemetria adiciona a **evidência estruturada por baixo da prosa**: um
padrão candidato deixa de ser "senti que isto se repetiu" e vira "este span-pattern se repetiu em
N sessões, com reject-rate X e blocked_on_user Y". **É o diário ganhando lastro** — o loop
dogfood-auditável (NS1) observável de verdade.

## Fios abertos que voltam ao maestro

1. A régua **formativa-vs-performática** vale como invariante de design? (proibir por design métrica
   rankeável/comparável no tempo, mesmo "útil"?)
2. Conteúdo (prompt/código) fica **default-off permanente** — ou há caso em que o snippet é
   necessário pro padrão fazer sentido?
3. Vale o **experimento barato**: ligar `CLAUDE_CODE_ENABLE_TELEMETRY=1` numa sessão real e olhar
   o que `tool_decision` + `blocked_on_user` + loops revelam — responder à pergunta 2 do SEED
   (reconhecimento de padrões) *dogfoodando* em vez de teorizar?

## Fontes (seleção)

- OpenTelemetry GenAI semconv — https://opentelemetry.io/docs/specs/semconv/gen-ai/gen-ai-spans/
- Claude Code Agent SDK — Observability — https://code.claude.com/docs/en/agent-sdk/observability
- "Signals: Trajectory Sampling and Triage for Agentic Interactions" — https://arxiv.org/html/2604.00356v1
- Trajectory-Informed Memory Generation for Self-Improving Agents — https://arxiv.org/html/2603.10600
- Graph-based Agent Memory (survey) — https://arxiv.org/html/2602.05665v1
- "Mind the Metrics" (telemetry-aware in-IDE dev) — https://arxiv.org/pdf/2506.11019
- Privacy by Design (Cavoukian, 7 princípios) — https://student.cs.uwaterloo.ca/~cs492/papers/7foundationalprinciples_longer.pdf
- GDPR Art. 5 (data minimization + purpose limitation) — https://www.exabeam.com/explainers/gdpr-compliance/gdpr-article-5-key-principles-and-6-compliance-best-practices/
- "The ethics of self-tracking" (revisão de 65 estudos) — https://www.tandfonline.com/doi/full/10.1080/10508422.2022.2082969
- Integridade contextual (Nissenbaum) — https://www.researchgate.net/publication/51876964_A_Contextual_Approach_to_Privacy_Online
- devenv AI telemetry backlash — https://socket.dev/blog/devenv-faces-backlash-over-ai-driven-telemetry-in-version-1-4-1
- GitHub Copilot opt-in→opt-out (2026) — https://github.blog/news-insights/company-news/updates-to-github-copilot-interaction-data-usage-policy/
- Bossware / vigilância de produtividade (NELP, 2025) — https://www.nelp.org/app/uploads/2025/07/When-Bossware-Manages-Workers-Policy-Agenda-July-2025.pdf
- Langfuse observability (session/trace/score) — https://langfuse.com/docs/observability/overview
