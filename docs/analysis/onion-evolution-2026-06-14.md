---
title: Onion Evolution Backlog — 2026-06-14
date: 2026-06-14
status: backlog
gerado-por: /meta:evolve (fan-out-and-synthesize + verificação adversarial)
run-id: wf_2e8f1867-26f
escopo: auditoria completa (8 dimensões D1..D8)
branch: feature/onion-forge-adapter-and-evolve
---

# Onion Evolution Backlog — 2026-06-14

## 0. Sumário

| Métrica | Valor |
|---|---|
| Dimensões auditadas | 8 / 8 (D1..D8) |
| Padrão de frota | fan-out-and-synthesize + verificação adversarial |
| Workers | 8 scan (haiku/sonnet) + 31 juízes adversariais (opus) = 39 agentes |
| Achados brutos | 36 |
| **Refutados/vetados pelos juízes** | **11** |
| **Confirmados (backlog)** | **25** |
| Severidade (confirmados) | 🔴 7 blocker · 🟡 15 recommended · 🟢 3 opportunistic |
| Budget gasto | ~1,55M tokens · 801 tool-uses · 34min |
| Run ID | `wf_2e8f1867-26f` |
| Vetos de fusão de fase | **0** (nenhuma proposta tentou fundir fases faseadas) |

> **Read-only.** Este comando não mutou `.claude/`. A única escrita é este
> relatório. A execução das correções é dos atuadores (`/meta:create-*`,
> `/meta:kb-freshness`, `/meta:metaspec-validate`, ou edição direta para
> links) sob validação do `@metaspec-gate-keeper`.

### ⚠️ Nota de processo — correção de fan-in feita no contexto principal

O script de frota deduplicava refutados por `verdict.finding.slice(0,80)`, mas
os juízes devolveram o campo `finding` em formatos heterogêneos (ora o JSON do
achado, ora prosa `"REFUTED. …"`). O match casou **apenas 1** dos 11 refutados,
deixando 10 achados refutados na lista "sobrevivente". **A reconciliação foi
refeita manualmente** lendo os 31 vereditos um a um — os números acima já são os
corretos. Isto é, em si, um achado sobre o próprio `/meta:evolve` (ver §6).

---

## 1. Backlog priorizado (25 confirmados)

| # | Sev | Dim | Achado | Padrão (doutrina) | Artefato-alvo | Esf. | Comando de execução |
|---|-----|-----|--------|-------------------|---------------|------|---------------------|
| 1 | 🔴 | D5 | `zen-engine-specialist` referencia KB inexistente `docs/knowledge-base/tools/zen-engine.md` no workflow principal | agents.md §7 (dependência deve existir) | `.claude/agents/development/zen-engine-specialist.md` | S | `/meta:create-knowledge-base` |
| 2 | 🔴 | D7 | `detector.md:400` link SDAAL com profundidade errada (`../../docs` → `.claude/docs`, inexistente) | fix-link | `.claude/utils/task-manager/detector.md` | S | edição direta |
| 3 | 🔴 | D7 | `abstraction-template.md:393` link com `.claude` duplicado (`../../../.claude/utils/...` → `.claude/.claude/...`) | fix-link | `.claude/commands/common/templates/abstraction-template.md` | S | edição direta |
| 4 | 🔴 | D7 | `abstraction-template.md:392` link SDAAL com profundidade errada (falta 1 nível) | fix-link | `.claude/commands/common/templates/abstraction-template.md` | S | edição direta |
| 5 | 🔴 | D7 | Adapters `asana/clickup/linear.md` (linha 3) link SDAAL com profundidade insuficiente (`../../../docs` → falta 1 nível) | fix-link | `.claude/utils/task-manager/adapters/` | M | edição direta |
| 6 | 🔴 | D7 | Arquivo ausente: `workflows.md` referenciado em 3 docs (`agents.md:329`, `commands.md:604`, `rules.md:422`) | fix-link | `.claude/docs/tools/` | M | criar arquivo OU remover 3 links |
| 7 | 🔴 | D7 | Arquivo ausente: `testing-validation-system.md` referenciado 2× em `commands-guide.md:727,799` | fix-link | `.claude/docs/onion/commands-guide.md` | M | criar arquivo OU remover 2 links |
| 8 | 🟡 | D2 | `agent-creator-specialist` e `command-creator-specialist` compartilham protocolo idêntico de 6 FASES | Reposicionar detentor de conhecimento → KB | `.claude/agents/meta/{agent,command}-creator-specialist.md` | M | `/meta:create-knowledge-base` |
| 9 | 🟡 | D2 | `/test/{unit,integration,e2e}` têm fluxo de execução idêntico de 7 passos | Dispatcher arg-driven (candidato) | `.claude/commands/test/*.md` | M | `/product:spec → /engineer:plan` |
| 10 | 🟡 | D3 | Bloco "PASSO 0: Detectar Provedor" duplicado em 3 comandos (~70% overlap) | Shed ceremony → KB / `common/prompts` | `.claude/commands/common/prompts/` (novo fragmento) | M | extrair fragmento `common/prompts` |
| 11 | 🟡 | D3 | Bloco "Auto-Update no Task Manager" repetido em 5 comandos (60-80% overlap) | Shed ceremony → KB / `common/prompts` | `.claude/commands/common/prompts/` (novo fragmento) | L | extrair fragmento `common/prompts` |
| 12 | 🟡 | D4 | `runflow.md`: model IDs Claude fixados por versão (`claude-3-5-sonnet`…) em vez de tier | Shed ceremony → KB (ref stale) | `docs/knowledge-base/platforms/runflow.md` | S | `/meta:kb-freshness` |
| 13 | 🟡 | D4 | `spec-driven-development-tools-2025.md`: sinais "dezembro 2025" potencialmente stale | Shed ceremony → KB | `docs/knowledge-base/frameworks/spec-driven-development-tools-2025.md` | M | `/meta:kb-freshness` |
| 14 | 🟡 | D4 | `configuration-management.md`: ClickUp hardcoded como provider (contradiz abstração agnóstica) | Shed ceremony → KB | `docs/knowledge-base/concepts/configuration-management.md` | M | `/meta:kb-freshness` |
| 15 | 🟡 | D4 | `spec-driven-development.md`: sinal de frescor stale ("Em evolução (2025)") | Shed ceremony → KB | `docs/knowledge-base/concepts/spec-driven-development.md` | S | `/meta:kb-freshness` |
| 16 | 🟡 | D5 | `task-specialist` está em `development/` mas `agents.md §2` o classifica em `product/` | agents.md §2 (categorias) | `.claude/agents/development/task-specialist.md` | S | `/meta:metaspec-validate` |
| 17 | 🟡 | D5 | `gitflow-specialist` está em `development/` mas `agents.md §2` o classifica em `git/` | agents.md §2 (categorias) | `.claude/agents/development/gitflow-specialist.md` | S | `/meta:metaspec-validate` |
| 18 | 🟡 | D5 | `commands.md §1.1` não define campo `name`, mas §8 o referencia — contradição interna na meta-spec | commands.md §1.1 vs §8 | `docs/meta-specs/commands.md` | S | `/meta:metaspec-validate` |
| 19 | 🟡 | D6 | `build-compliance-docs` despacha 4 especialistas independentes em prosa sequencial → candidato a fan-out | Workflow fan-out vs prosa sequencial | `.claude/commands/docs/build-compliance-docs.md` | S | `/meta:create-command` |
| 20 | 🟡 | D6 | Cluster de 5 guias em `.claude/docs/onion/` com conhecimento que poderia citar KB | Shed ceremony → KB | `.claude/docs/onion/*` | M | `/meta:create-knowledge-base` |
| 21 | 🟡 | D7 | Cross-links com prefixo absoluto `.claude/…` em vez de relativo em `.claude/docs/onion/` | fix-link | `.claude/docs/onion/` | M | edição direta |
| 22 | 🟡 | D8 | `pre-pr.md` / `pr-update.md` executam ações mutantes (git commit+push) sem `allowed-tools` (spec §1.3) | commands.md §1.3 (comando mutante) | `.claude/commands/engineer/{pre-pr,pr-update}.md` | S | `/meta:metaspec-validate` |
| 23 | 🟢 | D4 | `whisper.md`: sem campo "Última Atualização" / nota de frescor | Shed ceremony → KB | `docs/knowledge-base/tools/whisper.md` | S | `/meta:kb-freshness` |
| 24 | 🟢 | D4 | `abstraction-patterns-catalog.md`: frontmatter sem campo "atualizado" | Shed ceremony → KB | `docs/knowledge-base/concepts/abstraction-patterns-catalog.md` | S | `/meta:kb-freshness` |
| 25 | 🟢 | D8 | Frontmatter de comandos inclui `version`/`updated` não mencionados no spec §1.1 (ruído de schema) | commands.md §1.1 (clareza de schema) | `docs/meta-specs/commands.md` + comandos | S | `/meta:metaspec-validate` |

---

## 2. Blockers detalhados (🔴 — fixes verificados no filesystem)

Todos os 7 blockers foram **re-verificados manualmente** no contexto principal
(não só pelos juízes). Profundidades de path corrigidas abaixo (alguns achados
sugeriram o fix errado — anotado).

### B1 · `zen-engine-specialist` → KB fantasma
- **Evidência**: `.claude/agents/development/zen-engine-specialist.md:7,62,92` citam `docs/knowledge-base/tools/zen-engine.md`. O arquivo **não existe** (`tools/` só tem `agent-skills.md`, `claude-code-commands-best-practices-2026.md`, `whisper.md`).
- **Fix**: criar a KB `docs/knowledge-base/tools/zen-engine.md` (`/meta:create-knowledge-base`) **ou** remover/realinhar as 3 referências.

### B2 · `detector.md:400` — profundidade de link
- **Linha**: `- [SDAAL](../../docs/knowledge-base/concepts/specification-driven-ai-abstraction-layer.md)`
- **Verificado**: de `.claude/utils/task-manager/`, `../../docs` resolve para `.claude/docs/…` (inexistente); o correto é `../../../docs` (raiz). 
- **Fix**: `../../docs` → `../../../docs`.

### B3 · `abstraction-template.md:393` — `.claude` duplicado
- **Linha**: `- [Task Manager (Exemplo)](../../../.claude/utils/task-manager/)`
- **Verificado**: de `.claude/commands/common/templates/`, `../../../` já é `.claude/`; somar `.claude/` gera `.claude/.claude/…`.
- **Fix correto**: `../../../utils/task-manager/` ⚠️ (o achado sugeriu `../../utils/…`, que resolve para `.claude/commands/utils/` — **também errado**; usar `../../../utils/...`).

### B4 · `abstraction-template.md:392` — profundidade de link
- **Linha**: `- [SDAAL Pattern](../../../docs/knowledge-base/concepts/specification-driven-ai-abstraction-layer.md)`
- **Verificado**: de `templates/`, `../../../docs` = `.claude/docs/…` (inexistente); correto é raiz.
- **Fix**: `../../../docs` → `../../../../docs`.

### B5 · adapters `asana/clickup/linear.md:3` — profundidade insuficiente
- **Linha**: `> Instância do padrão [SDAAL](../../../docs/knowledge-base/concepts/specification-driven-ai-abstraction-layer.md).`
- **Verificado**: de `.claude/utils/task-manager/adapters/`, `../../../docs` = `.claude/docs/…` (inexistente); correto é raiz (4 níveis).
- **Fix**: `../../../docs` → `../../../../docs` nos 3 adapters.

### B6 · `workflows.md` ausente (3 referências)
- **Evidência**: `.claude/docs/tools/{agents.md:329, commands.md:604, rules.md:422}` têm `- [Workflows](./workflows.md)`. O arquivo **não existe**.
- **Fix**: criar `.claude/docs/tools/workflows.md` **ou** remover os 3 links de nav. ⚠️ `commands.md` foi **tocado por este branch** — possível regressão.

### B7 · `testing-validation-system.md` ausente (2 referências)
- **Evidência**: `.claude/docs/onion/commands-guide.md:727,799` linkam `../onion/testing-validation-system.md`. O arquivo **não existe** nesse diretório.
- **Fix**: criar o doc **ou** remover/redirecionar os 2 links. ⚠️ `commands-guide.md` foi **alterado neste branch** (último commit `5cb9ebf`) — **provável regressão a corrigir antes do PR**.

> **Sinal de PR**: B6 e B7 vivem em arquivos modificados por
> `feature/onion-forge-adapter-and-evolve`. Recomendo resolvê-los **antes** do
> merge — são links mortos introduzidos/expostos por este branch.

---

## 3. Achados por dimensão

| Dim | Tema | Brutos | Confirmados | Refutados |
|-----|------|--------|-------------|-----------|
| D1 | Peso/tamanho | 4 | **0** | 4 (todos) |
| D2 | Redundância/overlap | 4 | 2 | 2 |
| D3 | Duplicação >50 linhas | 3 | 2 | 1 |
| D4 | KBs stale | 7 | 6 | 1 |
| D5 | Conformidade meta-spec | 5 | 4 | 1 (já no raw) |
| D6 | Moderna vs legada | 2 | 2 | 0 |
| D7 | Cross-refs / links | 8 | 8 | 0 |
| D8 | Plataforma/frontmatter | 3 | 1 | 2 |

**Destaques:**
- **D7 (links) é a dimensão mais íntegra do achado**: 8/8 confirmados, todos verificados no filesystem. É o cluster mais acionável e barato.
- **D4 (frescor de KB)**: 6 confirmados — todos roteiam para `/meta:kb-freshness`, que faz a auditoria profunda por-KB. `/meta:evolve` apenas sinalizou.
- **D1 (tamanho): 0 confirmados** — a frota não achou outliers acima do limite *hard*; os 4 achados eram "near soft-limit", e os juízes os refutaram com base na doutrina (limite soft é advisory, não defeito).

---

## 4. Camada adversarial — 11 refutados (a frota se autocorrigindo)

Os juízes opus refutaram 11 dos 36 achados. Os mais relevantes:

| Achado refutado | Por quê (juiz) |
|---|---|
| **"Todos os 76 comandos têm frontmatter não-conforme" (D8, era 🔴 L)** | O schema de frontmatter é **deliberadamente aberto**, não fechado. `name/model/category/tags/version` são extensões válidas, não violação. Premissa central falsa. |
| 4× achados de tamanho D1 (presentation, docker, estimate, branding) | Contagem de linhas confere, mas "aproximando-se do limite" não é defeito — a doutrina trata o limite soft como advisory. |
| `test-agent` ⊃ `test-planner` (consolidar) | Citações corretas, mas a inferência "subconjunto ⇒ fundir" falha: estratégia prescritiva ≠ auditoria empírica de cobertura. Papéis distintos. |
| `create-agent` vs `create-agent-express` (divergência) | A premissa de que `create-agent` "delega protocolo completo" não se sustenta na fonte. |
| `spec-as-code-strategy` sem nota de frescor | Justificativa load-bearing não se sustentou. |
| Templates com links placeholder | Não são links quebrados — são exemplos **dentro de code fences**, intencionais. |

> **Leitura**: a verificação adversarial evitou que **1 blocker falso de esforço
> L** ("refatorar 76 comandos") e **4 ruídos de tamanho** entrassem no backlog.
> É exatamente o modo de falha que a camada existe para barrar.

---

## 5. Alertas transversais (causa sistêmica)

1. **🔴 Integridade de cross-references é o problema dominante** — 7 dos 8
   confirmados de D7 + B1 (D5) = **8 links/arquivos quebrados**. Causa comum:
   confusão de profundidade relativa (`../`) entre `.claude/` e a raiz `docs/`,
   agravada pela coexistência de `docs/` (raiz) **e** `.claude/docs/`. Vale um
   **lint de links** no CI (`/meta:setup-code-review`) para travar isso na fonte.

2. **🟡 Drift de frescor de KB (D4)** — 6 KBs com sinais de data/modelo stale.
   Roteiam todos para `/meta:kb-freshness` (auditoria profunda). Reforça a
   memória do projeto: *auditar frescor antes de citar uma KB*.

3. **🟡 Duplicação de blocos de task-manager (D3)** — "Detectar Provedor" e
   "Auto-Update" repetidos em 3-5 comandos. Candidatos a `common/prompts`.

---

## 6. Invariantes respeitadas + meta-achado

- ✅ **Nenhuma proposta funde fases** de `engineer/plan→…→pr-update` ou
  `product/collect→…→feature` (0 vetos de fusão; os juízes não precisaram vetar).
- ✅ Achados de consolidação (D2) que tocavam papéis distintos foram **refutados
  por mérito** — a frota não forçou consolidação indevida.
- ⚠️ **Meta-achado sobre o próprio `/meta:evolve`** (não está na tabela, é sobre
  o comando): a lógica de fan-in deduplica refutados por
  `verdict.finding.slice(0,80)`, frágil porque o `finding` devolvido pelo juiz
  não é estável. **Correção recomendada**: o `VerdictSchema` deve carregar um
  `finding_id` estável (índice do achado), e o fan-in casar por ele. Sem isso, o
  relatório bruto da frota subreporta refutações (reportou 1, real eram 11).
  → atuador: `/meta:create-command` (afinar `meta/evolve.md` + script de frota).

---

## 7. Próximos passos (por cluster → atuador)

1. **🔴 Cluster de links (itens 1-7, 21)** — esforço baixo, alto valor, e
   **bloqueia o PR atual** (B6/B7 em arquivos do branch). Resolver por edição
   direta + criar/remover os 2 arquivos ausentes. **Fazer agora, neste branch.**
2. **🟡 Frescor de KB (itens 12-15, 23-24)** — rodar `/meta:kb-freshness` para a
   auditoria profunda e aplicar os refreshes.
3. **🟡 Conformidade meta-spec (itens 16-18, 22, 25)** — rodar
   `/meta:metaspec-validate`; decidir recategorização de agentes e clareza do
   schema de frontmatter em `commands.md`.
4. **🟡 Consolidação/dedup (itens 8-11, 19-20)** — rotear por
   `/product:spec → /engineer:plan` (cluster), **nunca** fusão direta.
   Começar pelo D3 (`common/prompts`), que é o mais mecânico.
5. **Afinar o `/meta:evolve`** (meta-achado §6) — `finding_id` estável no veredito.

---

## 8. Referências

- Run da frota: `wf_2e8f1867-26f` · script: `…/workflows/scripts/onion-evolve-audit-wf_91bf5f2a-5c3.js`
- Doutrina de julgamento: [onion-modernization-doctrine.md](../knowledge-base/concepts/onion-modernization-doctrine.md)
- Doutrina de frota: [agent-fleet-orchestration.md](../knowledge-base/concepts/agent-fleet-orchestration.md)
- Baseline que automatiza: [onion-vv-baseline-2026-06.md](onion-vv-baseline-2026-06.md)
- Atuadores: `/meta:kb-freshness` · `/meta:metaspec-validate` · `/meta:create-*` · `/meta:setup-code-review`
