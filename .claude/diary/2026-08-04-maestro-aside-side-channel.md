---
date: 2026-08-04
instance: onion-evolve
type: innovation
classification: collective
tags: [side-channel, steering, hooks, user-prompt-submit, maestro-aside, dogfood]
affects: [meta, engineering]
breadcrumb_for: []
share_with: []
next_recommended: ""
review_after: 2026-11-04
conflict_class: static
significance: "Maestro's Aside: 1º protocolo de PREFIXOS TIPADOS de steering (gap aberto no estado-da-arte ago/2026). Marcador pt-BR no início da msg → hook injeta a rota canônica (recall, não gate). Dispatcher, cria zero store. No 1º dogfood, o 'dúvida:' pegou um furo no PRÓPRIO protocolo (o nome violava código=inglês)."
---

# Maestro's Aside — entrada lateral tipada (side-channel)

**A invenção.** Um vocabulário FECHADO de marcadores tipados que o maestro escreve no **início** da mensagem
(`dúvida:` `corrige:` `reforço:` `nota:` `guarda:` `+etapa:` `-etapa:` `paralelo:` `guarda-regra:`) para injetar,
no meio da sessão, um sinal lateral (pergunta, correção, lembrete, ±etapa, memória, pesquisa paralela) **sem
descarrilhar a tarefa**. O hook `UserPromptSubmit` (`aside-router-hook.sh` + motor `aside-router.sh`) detecta o
marcador e injeta a **rota canônica** como `additionalContext`.

**Por que é doutrinariamente sólida.** É **recall recognition-primed, não gate** (`onion-working-method` §5):
injeta o MAPA da rota, nunca bloqueia. É um **DISPATCHER** — roteia para diário/memória/STATE/orquestração que já
existem; **cria zero store novo**. Efeito irreversível (`-etapa:`, `guarda-regra:`) injeta propor→confirmar (Ato
3/W6). Maestro é fonte confiável (R15.2 — sem envelope untrusted). Custo-zero quando não há marcador.

**Fundamento (pesquisa 3-frentes, ago/2026).** Consenso "**steer, don't stop**" (input nos step boundaries);
`/btw` nativo p/ pergunta sem descarrilhar; guardrails determinísticos (hooks) > prosa "never do X". **Achado:**
um protocolo de PREFIXOS TIPADOS de steering **não existe padronizado** — espaço aberto/emergente.

**O dogfood que fechou o gatilho.** Na estreia, o maestro usou `dúvida:` e o protocolo **pegou um furo no próprio
protocolo**: o nome (`aparte`) violava a regra código=inglês. Renomeado para `aside` (o aparte teatral — metáfora
idêntica), mantendo `maestro`, os marcadores pt-BR e o nome-produto pt-BR "Aparte do Maestro". Behavior-over-declaration
aplicado a si mesmo.

**Como aplicar.** Casa canônica: `docs/knowledge-base/agentic-patterns/harness/maestro-aside.md` (vocabulário +
tabela de roteamento). Registrado como invenção nomeada em `onion-framework-identity.md` §1.5. No `/warm-up` §4.6.
