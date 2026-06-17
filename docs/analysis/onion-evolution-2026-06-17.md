---
title: "Onion Evolution Backlog — 2026-06-17"
date: 2026-06-17
type: evolution-backlog
status: active
generated-by: /meta:evolve (fan-out-and-synthesize, 9 dimensões + verificação adversarial)
supersedes: onion-evolution-2026-06-16.md
---

# Onion Evolution Backlog — 2026-06-17

## 0. Sumário

| Métrica | Valor |
|---|---|
| Dimensões auditadas | 9 (D1–D9) |
| Padrão | fan-out-and-synthesize + juiz adversarial |
| Agentes | 36 (9 scan + 27 juízes) · ~1.5M tokens · ~29 min |
| Achados brutos | 42 |
| Refutados/vetados pelo juiz | 21 |
| **Sobreviventes (backlog)** | **21** — 🔴 1 blocker · 🟡 12 recommended · 🟢 8 opportunistic |
| Run ID | `wf_21e05d2d-3df` |

> Contexto: este run roda **após** #76–#80 (Tijolo 1+2 do ciclo de vida de contexto + correção da drift hand-maintained). Os 4 arquivos de descrição viva já alinhados em #80 **não** reaparecem; os achados de contagem abaixo são dos arquivos **gerados/derivados/históricos** restantes.

---

## 1. Backlog priorizado

| # | Sev | Dim | Achado (evidência) | Padrão (doutrina) | Alvo | Esf. | Comando atuador |
|---|-----|-----|--------------------|-------------------|------|------|-----------------|
| 1 | 🔴 | D6 | `agent-creator-specialist` guia listar "Ferramentas MCP (ClickUp, GitHub…)" sem steering SDAAL → novos agentes violam API-first (`agent-creator-specialist.md:235-241`) | API-first / SDAAL | `agents/meta/agent-creator-specialist.md` | S | editar seção 4️⃣ (apontar `taskManager.*`/`forge.*`) |
| 2 | 🟡 | D6 | Mesma falha no caminho rápido `create-agent-express.md:44` ("Ferramentas MCP: prefixo mcp__" sem restrição) | API-first / SDAAL | `commands/meta/create-agent-express.md` | S | nota inline SDAAL na linha 44 |
| 3 | 🟡 | D8 | `docs/onion/index.md` "82 comandos" (3×) — arquivo **gerado** por `/docs:build-index`, stale (2026-06-14) | regenerate | `docs/onion/index.md` | S | `/docs:build-index onion` |
| 4 | 🟡 | D8 | `docs/onion/getting-started.md` "77 comandos" + "30 KBs" (hand-maintained) | derive-from-SSOT | `docs/onion/getting-started.md` | S | `/meta:inventory` + edição |
| 5 | 🟡 | D8 | `docs/materials/{landing-page,press-kit}.md` "82 comandos" (6 linhas) — derivados da KB de identidade | derive-from-SSOT | `docs/materials/*` | S | regenerar da KB (não sed cego — ver §3) |
| 6 | 🟡 | D8/D4 | **Lint guard gap**: Regra 9 valida só `CLAUDE.md`; não cobre `docs/onion/` nem arquivos gerados → drift silencioso | extend-lint-guard | `validation/lint-artifacts.sh` | M | estender Regra 9 / nova regra de índices gerados |
| 7 | 🟡 | D1 | Contagens stale em `getting-started`/`index`/comando `onion` (consolidado com #3-#4) | SSOT | (idem #3-#6) | S | `/meta:inventory` |
| 8 | 🟡 | D4 | Inconsistência de contagem entre docs + ausência de guarda automatizada | SSOT-via-lint | docs/onion/ + lint | M | (idem #6) |
| 9 | 🟡 | D2 | `/product:branding` referencia `@business-context` como **agente** (é diretório) (`branding.md:23`) | agent-invocation-hygiene | `commands/product/branding.md` | S | reescrever para "diretório `business-context/`" |
| 10 | 🟡 | D5 | Placeholder `@nome-do-agente` vazou para comando vivo (`onion.md:151`) | template-hygiene | `commands/onion.md` | S | trocar por `<nome-do-agente>` |
| 11 | 🟡 | D5 | `adopt.md`/`metaspec-validate.md` declaram `Bash` irrestrito (commands.md §1.3 exige prefixos escopados) | align-to-metaspec | `commands/meta/{adopt,metaspec-validate}.md` | S | escopar `Bash(git *)` etc. |
| 12 | 🟡 | D3 | Bloco validação story-points (80 linhas, `start.md:61-140`) duplicável | extract-to-common | `common/prompts/` (novo) | M | extrair fragmento |
| 13 | 🟡 | D3 | Bloco análise-de-task + provider-detection (`start.md:18-33,47-120`) duplicável | extract-to-common | `common/templates/` (novo) | M | extrair template |
| 14 | 🟢 | D3 | Help do comando `/onion` "94 comandos em 11 categorias" (`onion.md:87`) | documentation-accuracy | `commands/onion.md` | S | corrigir → 84/9 |
| 15 | 🟢 | D1 | `/engineer:pr-update` sub-equipado: falta `Bash(cat .env*)` p/ detectar provider | config-alignment | `commands/engineer/pr-update.md` | S | alinhar allowed-tools |
| 16 | 🟢 | D6 | `sessions/INDEX.md` viola kebab (SOFT) — renomear ou isentar explicitamente | lint-governance | `sessions/INDEX.md` ou Regra 6 | S | (sessions é gitignored — baixa urgência) |
| 17 | 🟢 | D4 | Sugestão: pre-commit hook validando `inventory.md` vs filesystem (Regra 8 já no CI) | validation-drift-guard | `validation/` | S | opcional |
| 18 | 🟢 | D8 | `docs/analysis/onion-product-material-raw-2026-06.md` "82 comandos" (material bruto) | derive-from-SSOT (com cuidado histórico) | analysis/ | M | revisar caso a caso |
| 19 | 🟢 | D4 | KBs citam Gemini/GPT-4 como provedores (context-appropriate; verificar frescor) | refresh-kb | 3 KBs | S | spot-check |
| 20 | 🟢 | D5 | Typo "preparacao"→"preparação" (`consolidation-prep.md:3`) | align-to-metaspec | `common/prompts/consolidation-prep.md` | S | corrigir acento |
| — | 🟢 | D8 | `onion-review-2026-05.md` "94 comandos" — **snapshot histórico datado** | preserve-historical | — | — | **nenhum** (preservar) |

---

## 2. Achados por dimensão

- **D1/D3/D4/D8 (contagem)** — drift pervasivo (ver §3 Alerta A). Núcleo: gerados (`index.md`), derivados (`materials/`), hand-maintained (`getting-started`, comando `onion`), histórico (`review-2026-05` = preservar).
- **D2** — 1 higiene de referência (`@business-context` não é agente). Cluster `branch-*`/meta-creators foi **refutado** pelo juiz (sobreposição justificada, não duplicação).
- **D5** — placeholder vazado, `Bash` irrestrito, typo. (Vários falsos-positivos de "inconsistência de linguagem" refutados.)
- **D6** — MCP-first nos criadores (ver §3 Alerta B). Demais resíduos legados refutados.
- **D7** — todos os 4 candidatos de link quebrado **refutados** (links válidos).
- **D9** — vazio (contextos são templates no framework — **no-op correto**, não falha).

---

## 3. Alertas transversais (causa sistêmica)

### 🔴 Alerta A — Drift de contagem é pervasivo e sub-guardado (8+ achados)
Contagens hardcoded (`82`/`77`/`94` comandos, `30/33` KBs, `11` categorias) aparecem em **gerados, derivados e hand-maintained**, e a Regra 9 do lint só guarda `CLAUDE.md`. **A correção pontual (sed 82→84) é armadilha** — recria drift e corrompe narrativa histórica. Fix de raiz, em ordem:
1. **Regenerar os gerados**: `/docs:build-index onion` (cobre `index.md`).
2. **Derivar nos hand-maintained**: substituir números por ponteiro à SSOT (`inventory.md`) onde possível; senão `/meta:inventory` + edição.
3. **Estender a guarda do lint** (#6): nova regra que flague contagem hardcoded de comando/agente/skill/KB fora de `inventory.md`/`CLAUDE.md` — fecha o vazamento de vez.
4. **Preservar** o histórico datado (`review-2026-05`, material-raw §D8).

### 🔴 Alerta B — Vazamento MCP-first nos criadores de agente (2 achados)
Tanto `agent-creator-specialist` quanto `create-agent-express` guiam o dev a declarar `mcp__<provider>__*` direto, **sem** steering ao adapter SDAAL — então **todo agente novo** nasce com risco de violar API-first. Os anti-patterns existem mas a fase de *discovery* não ensina a alternativa. Fix: corrigir os **dois** caminhos de criação (a guarda na origem, não nas folhas — doutrina "conserta o propagador").

---

## 4. Invariantes respeitadas
- O juiz adversarial **refutou/vetou 21 de 42** achados (cull saudável de finders recall-biased).
- **Nenhuma proposta funde fases** de workflow faseado (`engineer/*`, `product/*`) — verificado; nenhum veto de phase-merge necessário.
- Read-only: a única escrita deste run é este relatório.

---

## 5. Próximos passos (cada item → atuador)
1. 🔴 **Alerta B** (S): corrigir os 2 criadores de agente (API-first) — maior risco sistêmico, baixo esforço.
2. 🔴 **Alerta A** (M): `/docs:build-index onion` + estender lint guard + derivar hand-maintained. Um PR de "contagem deriva da SSOT".
3. 🟡 Higiene rápida (S): `@business-context` em branding, placeholder em onion.md, `Bash` escopado em adopt/metaspec-validate, typo preparação.
4. 🟡 Refactor (M): extrair story-points + task-analysis de `start.md` para `common/` (`/meta:create-abstraction`).
5. 🟢 Oportunístico: allowed-tools de pr-update, frescor de refs Gemini/GPT nas KBs, sessions/INDEX.md.

> Atuadores: `/docs:build-index` · `/meta:inventory` · `/meta:create-abstraction` · `/meta:create-knowledge-base` · edição direta sob `@metaspec-gate-keeper`.
