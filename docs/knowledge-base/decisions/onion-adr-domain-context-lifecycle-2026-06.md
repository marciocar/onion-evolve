---
title: "ADR — Contexto de domínio: SSOT viva com ciclo de vida CRUD+"
date: 2026-06-16
type: adr
status: accepted
decision-scope: domain-context / lifecycle
supersedes: none
related:
  - ../meta-specs/architecture.md
  - ../knowledge-base/concepts/domain-context-lifecycle.md
  - ../knowledge-base/concepts/onion-modernization-doctrine.md
---

# ADR — Contexto de domínio: SSOT viva com ciclo de vida CRUD+

| Campo | Valor |
|-------|-------|
| **Decisão** | Cada contexto de domínio (`business-context/`, `technical-context/`, `compliance-context/`) é uma **SSOT viva com ciclo de vida CRUD+**, não um artefato gerado uma vez (snapshot). A geração é só o **primeiro tick**; a fase *Manage* (validar/remover-stale/pesar-por-frescor) é de primeira classe. |
| **Escopo** | Doutrina de contexto de domínio + paridade dos 3 geradores. Reafirma `architecture.md §1.3` (pastas `*-context/`) e introduz uma regra L0 de ciclo de vida. |
| **Status** | ✅ **Aceito (doutrinário)** em 2026-06-16. Define a *forma* (doutrina + paridade = Tijolo 1); a camada *Manage* executável é o **Tijolo 2** (gatilho abaixo). |
| **Origem** | Pergunta de design (2026-06): "o que acontece com um contexto de domínio *depois* de gerado?" + estado da arte 2026 (context engineering) que aponta "Manage" como ponto cego universal. |

---

## Status

✅ **Aceito (doutrinário)** — 2026-06-16. Este ADR fixa a *forma* (contexto de domínio = SSOT viva)
e dá **paridade** aos três geradores para que o primeiro tick já nasça consistente. A camada
*Manage* executável (comando de audit de frescor + extensão de inventory/lint + composição no
`/meta:evolve`) é **diferida ao Tijolo 2**, com contrato especificado em `## Gatilho de
Implementação`.

> **Atualização 2026-06-17 — Tijolo 2 ENTREGUE.** A camada *Manage* foi implementada:
> comando `/meta:context-freshness` +
> extensão de `inventory.sh` (conta `*-context/`) e `lint-artifacts.sh` (Regra 15 — carimbo
> de frescor) + composição **D9** no `/meta:evolve`.

---

## Contexto

### O gap: geração-snapshot vs SSOT viva

Os três geradores — `/docs:build-business-docs`, `/docs:build-tech-docs`,
`/docs:build-compliance-docs` — produzem a árvore de documentos **uma vez** e não modelam o que
acontece depois. São geração-snapshot. Mas contexto não é estático: o código muda, a fonte é
abandonada, a doc envelhece.

### O estado da arte (2026) converge num diagnóstico

A pesquisa de context engineering de 2026 (Anthropic *effective context engineering*; *Context
Development Lifecycle*; *Git Context Controller*, arXiv 2508.00031) converge: a fase **"Manage"**
(validar / pesar-por-frescor / remover-stale / reorganizar) é o ponto cego universal — *"managing
is the hard part, where most systems struggle or outright fail"*. E o modo de falha é específico:
**contexto stale engana ativamente** — uma doc desatualizada é *pior* que ausente, porque a IA
age com confiança sobre uma realidade que já não existe.

### O ponto cego se repete no Onion

A maquinaria de "Manage" **já existe** no Onion (`/meta:kb-freshness`, `/meta:evolve`,
`inventory.sh` + `lint-artifacts.sh`, skill `onion-orchestration`), mas **nenhuma peça toca**
`docs/business-context/`, `docs/technical-context/`, `docs/compliance-context/`. Além disso, os
três geradores **divergiram** entre si: `build-tech-docs` e `build-business-docs` ganharam
resolução de evidência conflitante, modo não-interativo e marcadores de status; o
`build-compliance-docs` ficou para trás (`version 3.1.0`, sem essas fases) e ainda declara
`allowed-tools` que não permitem o que o corpo promete (gera arquivos e faz fan-out a 4
especialistas com apenas `Read Bash(grep *)`).

---

## Decisão

1. **Contexto de domínio é SSOT viva com ciclo CRUD+, não geração-snapshot.** A geração é o
   primeiro tick. A gramática de operações (Pesos/Formato/Adicionar/Remover/Alterar/Inferir/
   Agrupar/Reorganizar/Validar) vive na KB [domain-context-lifecycle.md](../../knowledge-base/concepts/domain-context-lifecycle.md).

2. **Três domínios peer + critério de promoção.** Business/technical/compliance são peers. As
   sub-camadas Decisional (ADRs) e Operacional/Runtime ficam *dentro* de `technical-context/`.
   Promove-se a peer apenas quando valem juntos **dono distinto × ritmo de mudança distinto ×
   decisão distinta que informam** — nunca por organograma. O projeto-alvo promove quando se
   justifica; o framework não força.

3. **Pesos são derivados, não declarados.** A relevância de um fragmento deriva de posição na
   progressive-disclosure + carimbo de frescor + tier de evidência. **Proíbe** número mágico no
   frontmatter (ex.: `priority: 0.8` manual).

4. **Remover e Validar são operações de primeira classe** — maior valor da gramática, e
   exatamente as ausentes hoje. O contrato executável dessas operações é **delegado ao Tijolo 2**
   (ver gatilho).

---

## Alternativas consideradas

- **A — Manter geração-snapshot ❌.** *Pró:* nada a construir. *Contra:* deixa o ponto cego
  universal sem dono; contexto stale engana ativamente. Rejeitada.
- **B — Doutrina + paridade primeiro (Tijolo 1), Manage executável depois (Tijolo 2) ✅ ESCOLHIDA.**
  *Pró:* estabelece o contrato antes de codificar; o primeiro tick já nasce consistente; reusa o
  molde de `kb-freshness` no Tijolo 2. *Contra:* a camada de runtime não existe ao fim do Tijolo 1
  (por design).
- **C — Construir o comando de Manage já, sem doutrina ❌.** *Pró:* runtime imediato. *Contra:*
  codificaria sem contrato (pesos, promoção, marcadores ainda ambíguos) e arriscaria reimplementar
  o que `kb-freshness` já resolve. Rejeitada.
- **D — Recortar contextos por organograma ❌.** *Contra:* peers proliferam sem ganho; viola o
  critério dono × ritmo × decisão. Rejeitada em favor do critério de promoção (decisão 2).

---

## Consequências

### Positivas
- **Nomeia o ponto cego** (Manage) e lhe dá doutrina antes de runtime.
- **Paridade** elimina a assimetria entre os 3 geradores; o primeiro tick nasce consistente.
- **Reuso máximo**: o Tijolo 2 herda o molde de `kb-freshness` (verdito, threshold, orquestração,
  schema) — superfície nova mínima.
- Corrige um bug latente: `build-compliance-docs` prometia escrever/orquestrar sem as tools.

### Negativas / trade-offs
- **Sem runtime de Manage no Tijolo 1** — o frescor de contexto ainda não é auditado/barrado no CI
  até o Tijolo 2.
- **Mudança de constituição**: adiciona uma seção L0 a `architecture.md` (bump de versão).

---

## Gatilho de Implementação (Tijolo 2 — a camada *Manage* executável)

Construir quando o Tijolo 1 estiver em uso e a primeira drift de contexto aparecer. **Reusa, não
reimplementa**, o molde de `/meta:kb-freshness`:

1. **Comando de audit de frescor de contexto** — verdito `CURRENT/STALE/HISTORICAL`, threshold
   herdado (`≤18 meses`), fan-out via `onion-orchestration` (worker haiku → fan-in sonnet), retorno
   `FreshnessSchema[]`. Cobre `docs/*-context/` como o `kb-freshness` cobre `docs/knowledge-base/`.
2. **Extensão de validação** — `.claude/validation/inventory.sh` passa a contar `*-context/`
   (hoje só conta `knowledge-base/`); `.claude/validation/lint-artifacts.sh` ganha barreira de
   drift/staleness (hoje Regra 8 = inventory sync, Regra 6 = kebab-case SOFT; nenhuma checa frescor).
3. **Composição no `/meta:evolve`** — nova dimensão **no fluxo principal**, como D4/D5 hoje delegam
   a `kb-freshness`/`metaspec-validate` sem aninhar orquestração dentro de orquestração.

---

## Referências

- [`architecture.md`](../../meta-specs/architecture.md) — §1.3 pastas `*-context/` · nova seção de ciclo de vida de contexto
- [`domain-context-lifecycle.md`](../../knowledge-base/concepts/domain-context-lifecycle.md) — a gramática CRUD+ (explainer)
- [`onion-modernization-doctrine.md`](../../knowledge-base/concepts/onion-modernization-doctrine.md) — doutrina-vizinha (peso/acoplamento)
- `/meta:kb-freshness` — molde reusado pelo Tijolo 2
- `/docs:build-business-docs` · `/docs:build-tech-docs` · `/docs:build-compliance-docs` — os geradores (primeiro tick)

---

**Mantido por:** Sistema Onion · **Última atualização:** 2026-06-17
