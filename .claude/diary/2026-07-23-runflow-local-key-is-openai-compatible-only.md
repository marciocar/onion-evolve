---
date: 2026-07-23
instance: onion-evolve
type: learning
classification: collective
tags: [runflow, dogfood, provider-abstraction, local-dev, sdk-1.6.2, smoke-test, zero-fabrication]
affects: [engineering, meta]
breadcrumb_for: []
share_with: []
next_recommended: "Para rodar um agente Runflow LOCAL (rf test / tsx) com chave própria sem tocar o tenant: use um provider OpenAI-compatible (openai/groq/xai/openrouter/litellm) e passe { apiKey } inline — só esses aceitam OpenAICompatibleOptions. anthropic/bedrock/gemini (ModelOptions: providerName/legacy) NÃO têm bypass de key local: exigem credencial no portal do tenant (Settings > LLM Providers). Antes de culpar o SDK por 'travar', separe as camadas: (1) valide a key+rede com curl direto ao provider; (2) veja se o processo respondeu rápido e só não ENCERROU (TraceCollector da observabilidade mantém timer aberto — force process.exit após o resultado)."
review_after: 2026-10-21
conflict_class: conditional
valid_when: "@runflow-ai/sdk mantém a assimetria de tipos — OpenAICompatibleOptions (openai/groq/xai) com apiKey/baseUrl inline vs ModelOptions (anthropic/bedrock/gemini) só providerName/legacy; re-verificar em core/models.d.ts ao subir de major do SDK (achado em 1.6.2)"
significance: "A demo Runflow só rodou local porque OpenAI é OpenAI-compatible (aceita apiKey inline); Anthropic/Bedrock/Gemini exigem credencial no tenant — uma assimetria da abstração de provider que o plano não previa e só o dogfood do smoke-test revelou, com o falso-'travamento' sendo a observabilidade, não a chamada."
---

## Signal
**Nem todo provider Runflow roda local com chave própria — e o que parece travamento pode ser a observabilidade.**
Preparando a demo do Tech Sync (IFTL, dono do Runflow), o agente-wow "não inventa" só rodou local porque
o provider era **OpenAI**. A tentativa de plano B com **Anthropic** falhou com *"No credential configured for
ANTHROPIC"* — o `{ apiKey }` inline foi **silenciosamente ignorado**. A causa está nos tipos do SDK 1.6.2, não
no acaso; e o "travamento" de 73s que assustou no meio do caminho era o TraceCollector, não o LLM.

## Evidence
- **Assimetria confirmada nos tipos** (`@runflow-ai/sdk/dist/core/models.d.ts`): `OpenAICompatibleOptions
  extends ModelOptions` e adiciona `baseUrl` + `apiKey`. As factories `openai/groq/xai` (e openrouter/litellm)
  recebem `OpenAICompatibleOptions` → **aceitam key inline e chamam o provider direto** (bypass do tenant).
  `anthropic/bedrock/gemini` recebem só `ModelOptions` (`providerName`, `legacy`) → **sem bypass**: a chamada
  roteia pelo runtime, que exige credencial cadastrada no portal (*Settings > LLM Providers*).
- **Prova de campo (smoke-test):** `openai('gpt-4o', { apiKey })` respondeu grounded + citou a fonte em ~1,5s;
  `anthropic('claude-...', { apiKey })` → HTTP 400 *"No credential configured for ANTHROPIC"*. As duas chaves
  eram válidas (curl direto: OpenAI `/v1/models` 200; Anthropic `/v1/models` 200) — logo não era key nem rede,
  era a arquitetura do provider.
- **O falso-travamento:** com key ruim, o processo falhava em ~3s; com key boa, "pendurava" >73s **depois** de
  já ter respondido ("Agent processing completed" em 1,2s → SIGTERM 73s depois → `[TraceCollector] flushing
  traces`). A lógica do agente terminava rápido; o TraceCollector da observabilidade mantinha um timer aberto e
  impedia o Node de sair. Fix no runner: `process.exit(0)` após o resultado. Em `rf test` (servidor longo) é
  irrelevante.
- **Método que isolou:** separar camadas antes de acusar o SDK — `curl` direto ao provider (valida key+rede),
  ler o `.d.ts` (valida a forma da API), capturar o log em arquivo (não em pipe bufferizado) para achar a
  ÚLTIMA linha antes do "hang". Cada passo matou uma hipótese.
- **Bônus de fidelidade:** `gpt-4o` reproduz a `FONTE_A_CITAR` completa (`[Fonte: KB runflow.md §Providers ·
  docs.runflow.ai/...]`); `gpt-4o-mini` cita o ID interno do item (`[Fonte: K6]`) — mesmo comportamento
  (grounding+recusa), citação menos polida. Modelo maior = citação melhor no palco.

## Next crumb
Ver `next_recommended`. Fecha o arco Runflow do dia junto de
[[runflow-doctrine-freshness-proves-value-day-one]] (a KB reescrita verificada que virou o conhecimento do
agente) — aqui a lição é operacional: **a abstração de provider do Runflow não é simétrica**, e dogfoodar o
artefato (não o plano) foi o que revelou isso. Irmã da [[onion-dogfooding-doctrine]] (rodar o artefato de
verdade, testar modo-de-falha, não só o happy-path).
