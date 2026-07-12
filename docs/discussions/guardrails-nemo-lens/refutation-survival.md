---
title: "Checagem #2 do core — refutação adversarial: o que sobreviveu, o que caiu"
category: discussion
status: refutacao-checagem-2-core
date: 2026-07-12
branch: discuss/guardrails-nemo-lens
responde: docs/evolution/inbound/_processed/2026-07-12-boletim-core-pre-pr.md (checagem #2)
metodo: 4 refuters adversariais (run wf_c5768d14-fa5), default = claim quebrado até evidência forçar sobrevivência
resultado: 1 ataque PEGOU (major, corrigido) · 3 sobreviveram (1 com concessão minor, corrigida)
---

# Checagem #2 — o refutador

> **Pedido do core:** *"Passar o refutador. A taxonomia sobrevive a uma tentativa de quebra? (o que promete e
> não entrega; overlap com `@metaspec-gate-keeper` / `.claude/validation/`)."*

Quatro refuters foram mandatados a **destruir** o claim (não defendê-lo), lendo o corpus **e** os mecanismos
existentes do core. Veredito honesto abaixo — **o que caiu foi consertado; o que sobreviveu, defendido com
evidência.**

## Placar

| # | Ataque | Veredito | Severidade |
|---|--------|----------|-----------|
| A1 | "onion-guardrails é puro re-labeling do gate-keeper/lint — vaporware" | 🟢 sobreviveu | — |
| A2 | "a taxonomia é um 2º SSOT que vai divergir do lint (viola seu próprio R1)" | 🔴 **PEGOU** | **major** → corrigido |
| A3 | "promete capacidade (bloqueia injeção) que não está no core" | 🟢 sobreviveu | — |
| A4 | "148 vetos infla o número misturando gate genérico com guardrail de segurança" | 🟢 sobreviveu | minor → corrigido |

## A2 — o ataque que PEGOU (e por que aceitá-lo fortalece)

**A acusação:** a taxonomia copia `arquivo:linha` verbatim (ex. `lint-artifacts.sh:635`) e carimba contagens
fixas (`148`, `R1 22/0`) **sem nenhum gate** que revalide contra o código. Se um refactor mover a violação de
`:635` para `:650`, a taxonomia fica **stale e ninguém acusa** — exatamente o pecado que **ONION-R1 (SSOT
drift)** pune no CLAUDE.md/inventory. *"O catálogo de guardrails anti-drift não tem guardrail anti-drift de si
mesmo."* Evidência: `check_inventory_sync` (`lint-artifacts.sh:365-380`) protege o inventory por `diff`
byte-a-byte gerado-do-filesystem; **grep por `taxonomy-onion-r` em `.claude/validation/` = zero.**

**Concessão:** o ataque está certo. O rigor foi na **criação** (11/14 herdam por read-path verificado, 11
hipóteses fechadas por grep) — mas rigor de criação **não é** proteção contra drift futuro. É uma ironia
estrutural real, não cosmética.

**Correção aplicada:**
1. **Taxonomia** ganhou uma nota de **auto-drift**: as citações `arquivo:linha` e as contagens são
   **snapshot de 2026-07-12**; até haver gate, leem-se como *read-path a revalidar*, não verdade perpétua.
2. **Plano de promoção** ganhou um passo explícito: **onion-guardrails DEVE obedecer ONION-R1 sobre si
   mesmo** — na promoção, a KB entra no escopo de um gate de drift (re-grep dirigido via `/meta:kb-freshness`,
   idealmente bloqueante como o `check_inventory_sync`). *A camada de guardrails passa nos próprios
   guardrails* — o dogfood da doutrina sobre ela mesma. **Aceitar a A2 tornou a camada mais consistente, não
   menos.**

## A4 — sobreviveu, com concessão minor (corrigida)

**A acusação:** "148 vetos" infla a narrativa de *segurança* empacotando R1 (drift), R7 (CLI), R12 (WCAG) —
gates de qualidade, não guardrails de segurança de IA. **Sobreviveu na forma forte** porque a autodeclaração
("R12 **não é risco de segurança**", `taxonomy:248`) mora **na mesma tabela** de onde vem o número — não é
disclaimer enterrado. **Concessão minor:** os resumos-manchete (`kb-spine`, `promotion-plan`) repetem "148/14"
sem reanexar o caveat. **Corrigido:** as menções-manchete agora carregam "nem todos são guardrails de
segurança — inclui gates de qualidade (R1/R7/R12)".

## A1 e A3 — sobreviveram limpo

- **A1 (re-labeling):** sobrevive porque o corpus **já concede** que R1–R14 são lente/nomeação (`kb-spine:20`
  "não é código novo; é o nome e a lente") — não finge ser capacidade nova. O ataque só quebraria na forma
  universal ("NADA novo"), e **R15 a refuta**: cerca de proveniência + gate de efeito não existem em lugar
  nenhum do `.claude/` (grep vazio), e o dogfood mediu mudança de comportamento (75%→0%). **Reforça a
  conclusão da checagem #1:** R1–R14 herdam; **R15 é a única capacidade nova** — e é honesta sobre ser
  protótipo, não core.
- **A3 (overclaim):** sobrevive porque **todo** claim forte está territorializado em `prototype/` com banner
  QUARENTENA ou `status:` de draft/spike; **zero vazamento** pra fora de `docs/discussions/` (nenhum doc do
  core cita R15 como capacidade ativa; a KB `onion-guardrails` nem existe ainda no core).

## Veredito (checagem #2)

**A taxonomia sobrevive ao refutador** — com **uma correção honesta que a fortalece** (A2: a camada agora
obedece seu próprio R1) e um ajuste de higiene (A4: caveat nos resumos-manchete). Nenhum ataque de
"promete-e-não-entrega" pegou: o corpus é rigorosamente territorializado. A conclusão que atravessa #1 e #2 é
a mesma e agora à prova de refutação: **ONION-R é lente sobre gates existentes (herda); R15 é a única
capacidade nova (honestamente protótipo); e a camada agora se auto-fiscaliza contra drift.**

> **Para o NÓS:** #2 é passável. Os itens que restam pro cross-review do core são as **extensões conscientes**
> da #1 (R15.2 semântica; R15.3b materializa o TODO da §7) — não fraquezas. O gate de auto-drift (A2) é um
> item concreto de trabalho na promoção, não um bloqueio de mérito.
