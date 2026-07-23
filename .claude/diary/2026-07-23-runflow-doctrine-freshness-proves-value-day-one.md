---
date: 2026-07-23
instance: onion-evolve
type: innovation
classification: collective
tags: [dogfood, doctrine-freshness, runflow, verification, fan-out, partner-kb, zero-fabrication]
affects: [meta, engineering, product]
breadcrumb_for: []
share_with: []
next_recommended: "Reescrever documentação de terceiro (SDK de parceiro, API externa) NUNCA a partir do cutoff — sempre fan-out sobre a fonte viva (docs.runflow.ai neste caso), sintetizar, e verificar adversarialmente re-fetching um subconjunto (13+ de ~20 páginas aqui). Adicionar a KB reescrita à lista world-facing da REGRA 42 no MESMO commit, para o gate cobrar a próxima re-verificação em vez de deixá-la envelhecer de novo em silêncio."
review_after: 2026-10-21
conflict_class: dynamic
significance: "A REGRA 42, recém-nascida há horas, pegou no primeiro uso real uma KB de parceiro 8 meses defasada — e a reescrita inteira saiu 100% verificada contra a fonte viva, zero fabricação, no mesmo dia em que o gate nasceu."
---

## Signal
**O gate provou valor no dia em que nasceu.** Horas depois da REGRA 42 (`44d7e05`) entrar, o próprio
gate acionou sobre a KB do Runflow (SDK do parceiro IFTL, usado numa apresentação no dia seguinte): versão
pinada em 1.0.56 (nov/2025), **~8 meses defasada**. A reescrita completa que se seguiu foi 100% verificada
contra a documentação viva — zero fabricação — e o método (fan-out + verificação adversarial + re-fetch) é
agora o padrão para reescrever doc de terceiro sem inventar.

## Evidence
- **Gatilho:** commit `b859471` (2026-07-23) verifica a versão do SDK `@runflow-ai/sdk` contra o registro
  npm (`dist-tag latest`): **1.0.56 → 1.6.2**, node ≥22 confirmado, playwright ≥1.40.0 como peer opcional.
  `runflow.md` entra na lista world-facing da REGRA 42 no mesmo commit (frontmatter `verified_at`
  registrado) — passa a ser cobrado pelo gate, não vira ruído de Nível B lexical.
- **Motivo declarado no commit:** o maestro apresenta o Onion no IFTL no dia seguinte, e o Runflow é
  produto do IFTL — aparecer com a própria API deles inventada seria pior que desatualizada.
- **Reescrita completa e verificada:** commit `f85abe1` reescreve o corpo inteiro da KB a partir de
  fan-out sobre ~20 páginas de `docs.runflow.ai`, sintetizado, e depois verificado adversarialmente
  re-buscando 13+ páginas. Resultado no risco central: **ZERO fabricações** — todo bloco de código, nome
  de API, import, env var, provider, comando de CLI e versão rastreia verbatim à doc viva.
- **APIs mortas removidas:** exemplos da era 1.0.x (`@runflow-ai/sdk/connectors`, `LLM.openai`,
  `hubspotConnector.tickets.create`) substituídos por código atual; conceitos mortos removidos
  ("150 conectores", "11x mais rápido", lista datada de model-IDs OpenAI/Bedrock).
- **A verificação pegou o INVERSO da fabricação também** — a KB SUBDECLARAVA o que a doc cobria: a nota
  sobre Workflows dizia que a doc não mostrava `flow()`/`createWorkflow()`; falso — a doc mostra
  `await workflow.execute({...})` e afirma verbatim que `flow()` é a via recomendada e `createWorkflow()`
  está deprecated. Corrigido contra a doc re-buscada, não contra memória.
- **Honestidade preservada onde a doc não cobre:** seção explícita "Pontos não cobertos pela doc
  consultada" (shape de `ChunkType`, sinks externos de observabilidade, listas fechadas de model-ID) — nada
  preenchido a partir de memória de cutoff.

## Next crumb
Ver `next_recommended`. Esta migalha fecha o arco do dia — [[doctrine-fades-declared-not-verified]] (o
achado que pariu o gate) → [[doctrine-freshness-ratchet-composed-not-new]] (o gate) → esta (a prova em
produção, horas depois, sobre doc de parceiro real).
