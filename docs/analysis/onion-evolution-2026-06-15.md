---
title: Onion Evolution Backlog — 2026-06-15
date: 2026-06-15
author: Sistema Onion (assistido por IA — /meta:evolve)
status: backlog-ativo
scope: framework-template-instalavel
run_id: wf_7c50cb89-ceb
supersede: onion-evolution-2026-06-14-v2.md
---

# Onion Evolution Backlog — 2026-06-15

## 0. Sumário

| | |
|---|---|
| Dimensões auditadas | 8 (D1–D8) |
| Padrão | fan-out-and-synthesize + verificação adversarial |
| Workers | 28 agentes (8 auditores + ~19 juízes + critic) · 1.27M tokens · 635 tool-uses · ~26 min |
| Achados brutos | 41 |
| **Sobreviventes** | **30** (2 🔴 blocker · 18 🟡 recommended · 10 🟢 opportunistic) |
| Refutados/vetados pelo juiz | 11 (todos `refuted`; **0 vetos de fusão de fase**) |
| Run ID | `wf_7c50cb89-ceb` |

**Por dimensão:** D4=7 (KBs stale) · D6=6 (legado/vazamento) · D2=5 · D7=5 (links) · D5=3 · D3=2 · D8=2 · **D1=0** (nenhum outlier de tamanho — framework dentro dos limites).

> **Read-only:** esta auditoria propôs; nada em `.claude/` foi mutado. A única escrita é este relatório. Cada item tem comando atuador.

---

## 1. Backlog priorizado (top)

| # | Sev | Dim | Achado (arquivo:linha) | Padrão / Alvo | Esf. | Comando |
|---|-----|-----|------------------------|---------------|------|---------|
| 1 | 🔴 | D6 | `three-amigos.md:82` hardcoda transporte **MCP-first** p/ ClickUp (`via ClickUp MCP`) enquanto linha 83 usa `via Jira API` — viola API-first/agnose SDAAL | API-first / `validate/collab/three-amigos.md` | S | editar (passar pelo adapter) |
| 2 | 🔴 | D8 | `docs/INDEX.md:39-49` contagens stale (`77 comandos`, git=12, meta=13) vs SSOT (82; git=6, meta=21) | inventário / `docs/INDEX.md` | M | `/meta:inventory` |
| 3 | 🟡 | D6 | `setup-integration.md` rotula ClickUp/Asana como **"MCP"** no menu (contraria API-first) | API-first | S | editar |
| 4 | 🟡 | D6 | `agent-template.md` Exemplo 2: clickup-specialist = "Especialista em ClickUp **MCP**" → propaga label MCP-first em todo agente novo | API-first (propagador) | S | editar template |
| 5 | 🟡 | D6 | `task-specialist.md` lista "ClickUp **MCP** Integration" como ferramenta (agente agnóstico usando MCP direto) | API-first | S | editar |
| 6 | 🟡 | D7 | `security-information-master.md` — **21 links relativos quebrados** p/ docs de compliance | links / agente | M | editar/gerar |
| 7 | 🟡 | D5 | `agent-creator-specialist` + `command-creator-specialist` fazem Glob em categorias inexistentes (`commands/compliance/`, `commands/admin/`) | meta-spec / phantom-category | S | editar |
| 8 | 🟡 | D5 | `c4-architecture-specialist` referencia categoria `commands/architect/` inexistente | meta-spec | S | editar |
| 9 | 🟡 | D4 | 6 KBs stale sem honrar date-gate (whisper, spec-driven, branding, pain-cliente 17mo, meeting-transcription, spec-driven-tools) | kb-freshness #7 | S–L | `/meta:kb-freshness` |
| 10 | 🟡 | D7 | KB de federação referencia o **v1 inexistente** (`onion-federation-design-2026-06.md`, removido no #53) | links | S | editar `related:` |

(+ 8 recommended e 10 opportunistic — §2.)

---

## 2. Achados por dimensão

- **D1 (peso):** ✅ limpo — nenhum agente/comando acima dos limites (1200/1500; 500/800).
- **D2 (redundância) — 5:** branch-metaspec-checker × metaspec-gate-keeper; c4-architecture × c4-documentation; product/consolidate-meetings × docs/consolidate-documents; meta/create-agent × create-agent-express; docs/docs-health × validate-docs. *(O juiz refutou 4 propostas de fusão exageradas — ver §refutados.)*
- **D3 (duplicação) — 2:** seção "Contexto Geral (Base)" idêntica em engineer/product warm-up; estrutura de Passos comum em test/{unit,integration,e2e} → `common/templates`.
- **D4 (KBs stale) — 7:** cluster de date-gate (#7) não honrado; pior caso `identificar-precificar-dor-cliente` (17+ meses). → `/meta:kb-freshness`.
- **D5 (meta-spec) — 3:** categorias de comando fantasma (`compliance/`, `admin/`, `architect/`) referenciadas por creators/c4; `create-command.md` inclui categoria `general` não listada na commands.md §2.
- **D6 (legado/vazamento) — 6:** **vazamento MCP-first** (itens 1,3,4,5 — sistêmico); `command-creator-specialist` ensina "Orquestração Sequencial" sem citar Workflow fan-out; `technical-context-template` menciona Windsurf (multi-IDE, abandonado).
- **D7 (links) — 5:** 21 links quebrados em security-information-master; path-depths errados em contextos de federação arquivados; ref ao v1 removido; templates com links-placeholder; c4-adr-patterns refs de exemplo.
- **D8 (frontmatter/inventário) — 2:** `docs/INDEX.md` stale (item 2); só 31/82 comandos declaram `allowed-tools` (campo opcional).

---

## 3. Alertas transversais (causa sistêmica)

1. **🔴 Vazamento MCP-first vs API-first (SDAAL)** — **a causa mais importante.** Pelo menos **4–5 achados** (D6 itens 1,3,4,5 + D5) rotulam ClickUp/Asana como "MCP" ou hardcodam transporte MCP em comandos/agentes/**templates**, contrariando a doutrina API-first (MCP é transporte *opcional*). Crítico porque o **`agent-template.md` é propagador**: cada agente novo herda o label. **Recomendação:** uma varredura única "MCP-first → adapter/API-first" em comandos + agentes + templates (atuável como 1 PR), priorizando o template (fonte) — espelha a lição [[agent-fleet-cursor-tool-names-broken]] (consertar o propagador, não só as folhas).
2. **🟡 Date-gate de KB não honrado (kb-freshness #7)** — 6+ KBs com "revalidar antes de citar" no frontmatter que nunca foram revalidadas. → rodar `/meta:kb-freshness` completo (a auditoria foi scan focado).
3. **🟡 Categorias de comando fantasma** — 3 agentes referenciam `commands/{compliance,admin,architect}/` que não existem. Confunde o roteamento.
4. **🟡 Links quebrados** — 5 achados D7; o pior é `security-information-master` (21 links).

---

## 4. Invariantes respeitadas

- **0 vetos de fusão de fase.** O juiz adversarial confirmou que **nenhuma** proposta funde fases de `engineer/*` (plan→pr-update) ou `product/*` (collect→feature). Todas as propostas de consolidação eram de **agentes/comandos**, não de workflows faseados.
- **11 refutados com mérito** (validação da camada adversarial): 4 fusões D2 exageradas (test-trio, code-reviewer pair, NX pair — "diferenciação real é valor", confirmado vs `onion-review-2026-05.md`), 2 D3 ("duplicação" superdeclarada), 3 D4 (date-gate mal-medido), 1 D5 (Read confundido com invocação), 1 D8 (falso positivo de naming).

---

## 5. Próximos passos (cada item → atuador)

1. **🔴 Varredura MCP-first → API-first** (template + comandos + agentes) — alerta sistêmico #1. Atuador: edição direta sob `@metaspec-gate-keeper`; começar pelo `agent-template.md` (propagador).
2. **🔴 `/meta:inventory`** — reconciliar `docs/INDEX.md` (item 2).
3. **🟡 `/meta:kb-freshness`** — varredura exaustiva das KBs stale (#7).
4. **🟡 Corrigir categorias fantasma** (D5) + links quebrados (D7, começar pelos 21 de security-information-master).
5. **🟢 Oportunístico:** `allowed-tools` em mais comandos; extrações `common/templates` (warm-up, test commands).

---

## 6. Addendum — itens registrados manualmente (pós-run)

> Itens **não** produzidos pelo run `wf_7c50cb89-ceb` — **não** contam nos 30 sobreviventes nem nas
> contagens por dimensão (§0/§2). Registrados à mão entre rodadas de `/meta:evolve`. Cada um tem
> **gatilho**: só viram trabalho quando o gatilho dispara; até lá **não são dívida ativa**.

| # | Sev | Tema | Item | Gatilho | Atuador |
|---|-----|------|------|---------|---------|
| A1 | 🟢 | Federação / interop | Implementar **projeção export-only Agent Card** do `members.yaml` (formato A2A, **sem runtime**) — decisão em [ADR A2A](onion-federation-adr-a2a-format-interop-2026-06.md) | **1º consumer não-Onion** na federação **ou** necessidade nomeada de interop com registry/ferramenta A2A externa | script emissor em `.claude/validation/` + **revalidar campos contra o spec A2A vigente** antes de codar |

> **Por que oportunístico e não ativo:** a doutrina **já permite** (linha vermelha partida em
> [`multi-repo-federation.md §7`](../knowledge-base/concepts/multi-repo-federation.md)); construir antes
> do gatilho seria especulação — não há consumer não-Onion hoje (review §4). O ADR carrega a razão, o
> mapeamento Agent Card→Onion e o caveat de frescor.

> **Ciclo de vida:** este relatório supersede `onion-evolution-2026-06-14-v2.md` (removido neste mesmo PR, conforme [analysis/README.md](README.md)). Os itens executados saem do backlog na próxima rodada de `/meta:evolve`.
