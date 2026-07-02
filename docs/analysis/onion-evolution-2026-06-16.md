---
title: Onion Evolution Backlog — 2026-06-16
date: 2026-06-16
author: Sistema Onion (assistido por IA — /meta:evolve)
status: executado-e-superseded   # blockers #1-#6 executados (PRs #57/#69/#82, mesmo dia); backlog ativo atual = onion-evolution-2026-06-25.md
scope: framework-template-instalavel
run_id: wf_1088017b-b73
supersedes_active_backlog: onion-evolution-2026-06-15.md
superseded_by: onion-evolution-2026-06-25.md
note: "2026-06-15 é RETIDO (não removido) — virou âncora de citação dos materiais/identidade (§0 métricas). Ver §7."
---

# Onion Evolution Backlog — 2026-06-16

> **Nota de curadoria (2026-07-01, auditoria de federação item #14):** este backlog foi **executado 26
> minutos depois de gerado** e nunca anotado. Itens #1–#5 resolvidos no PR #69 (`c810ee6`, 2026-06-16
> 07:27) + guard no PR #82; #6 era stale já na origem (fan-out presente desde o PR #57). O alerta
> transversal 1 ("MCP-first NÃO executado") e os próximos passos 🔴 1–2 foram concluídos nos mesmos PRs.
> **Permanecem abertos apenas #7 e #8** (revalidação dos KBs de spec-driven development — ver
> `/meta:kb-freshness`). O backlog ativo é [onion-evolution-2026-06-25.md](onion-evolution-2026-06-25.md).

## 0. Sumário

| | |
|---|---|
| Dimensões auditadas | 8 (D1–D8) — todas retornaram |
| Padrão | fan-out-and-synthesize + verificação adversarial |
| Workers | 21 agentes (8 auditores + 13 juízes) · ~900K tokens · 384 tool-uses · ~17 min |
| Achados brutos | 35 |
| Refutados pelo juiz | 8 (**0 vetos de fusão de fase** — invariante intacta) |
| Curados como verificado-limpo / falso-positivo / suspeito | 7 |
| **Backlog acionável** | **~20** (2 🔴 · 11 🟡 · ~7 🟢) + 1 carry-forward (A1) |
| Run ID | `wf_1088017b-b73` |

> **Continuidade:** este run supersede `onion-evolution-2026-06-15.md`. Como aquele backlog foi
> **proposto, não executado** (desde então só mergeou o PR #67 — docs do ADR A2A), a maioria dos
> itens **reaparece** (MCP-first, categorias fantasma, links mortos). Isso é esperado: medem o mesmo
> estado. O item **A1** (projeção A2A) é carregado adiante no §6 (gatilho não disparou).

> **Read-only:** a auditoria propôs; nada em `.claude/` foi mutado. A única escrita é este relatório.

---

## 1. Backlog acionável priorizado

| # | Sev | Dim | Achado (arquivo:linha) | Padrão (doutrina) | Esf. | Comando de execução |
|---|-----|-----|------------------------|-------------------|------|---------------------|
| 1 | 🔴 | D5 | `command-creator-specialist.md` lista **categorias de comando fantasma** `compliance/` + `admin/` em 8 trechos (`:230,232,691,693,703,705,913,919`) — inexistentes; viola `commands.md §8`. Meta-creator propaga a todo comando futuro. **(juiz: confirmado)** | meta-spec / phantom-category | S | editar (gate-keeper) → lista canônica `commands.md §2` |
| 2 | 🔴 | D6 | `product/task.md` prosa **MCP-first** (`:168,182,184,273`): "Executar MCP" / "usar ferramentas MCP do provedor" como caminho default em vez do adapter agnóstico. **(juiz: confirmado; nuance: lint Regra 10 só pega token `mcp_*`, então passa o CI — é blocker *doutrinário*, não gate vermelho)** | API-first / SDAAL | S | editar (gate-keeper) → `taskManager.createTask()` via adapter |
| 3 | 🟡 | D6 | `agent-template.md:176-178` **propagador MCP-first** ("potencializado com MCPs"; comentário classifica por presença de MCP) — todo agente novo herda | API-first (propagador) | S | editar template (fonte) |
| 4 | 🟡 | D6 | `agent-creator-specialist.md` campo inventado `mcp_servers:` em 4 templates (`:395,613,1076,1093`) — hardcoda nomes de MCP server; fora do schema canônico | API-first (propagador) | S | editar (gate-keeper) |
| 5 | 🟡 | D5 | `agent-creator-specialist.md:1058` Template 2 `related_commands:["/compliance/generate"]` — comando+categoria fantasma (cluster do #1) | meta-spec / phantom | S | editar → comando real (`/docs:build-compliance-docs`) |
| 6 | 🟡 | D6 | `command-creator-specialist.md:409` ensina só "Orquestração Sequencial"; sem Pattern 1 de **fan-out (Workflow)** para passos independentes | Workflow fan-out vs prosa | M | editar → add Pattern 1 citando `agent-orchestration.md` |
| 7 | 🟡 | D4 | `spec-driven-development-tools-2025.md:17` flag "revalidar antes de citar" **não honrado** (conteúdo parado em 2025-12-16; só o campo Status mudou no commit ed4c6a6) | kb-freshness (date-gate desonesto) | M | `/meta:kb-freshness` |
| 8 | 🟡 | D4 | `spec-driven-development.md:14` flag "revalidar periodicamente" não honrado desde 2025-12-02 | kb-freshness | M | `/meta:kb-freshness` |
| 9 | 🟡 | D7 | `onion-federation-design-v2-2026-06.md:5,13` **links mortos p/ v1** (removido no #53). **CORRIGIDO vs worker:** `:5` é ponteiro `Supersede:` — **delink** ambos, **não** repointar p/ v2 (auto-referência). **(juiz refutou o fix do worker)** | reparar link (delink) | S | editar → delink `:5` e `:13` |
| 10 | 🟡 | D7 | `docs/compliance-context/README.md:130` path errado `agents/compliance/` — o agente existe em `agents/review/`. **CORRIGIDO vs worker:** fix de 1 linha, **não** criar agente (já existe). **(juiz refutou o premissa do worker)** | reparar path | S | editar `compliance/`→`review/` |
| 11 | 🟡 | D7 | `docs/compliance-context/README.md:137` path errado `../onion/applying-regulated.md` — arquivo existe em `docs/applying/`. **CORRIGIDO vs worker:** fix de path, **não** criar arquivo | reparar path | S | editar `onion/`→`applying/` |
| 12 | 🟡 | D7 | `sdaal-examples.md:92` path com `docs/` duplicado (`../../docs/knowledge-base/...` deveria ser `../concepts/...`) | reparar path | S | editar |
| 13 | 🟡 | D5/D8 | **Threshold ambíguo (NOVO — surgido na própria auditoria):** "~400 linhas" em `onion-patterns`/`onion-validation`/`command-template` ≠ constituição `commands.md §5` (≤500 OK / >800 hard). Causou 2 falsos D1 + **divergência do painel de juízes**. | meta-spec / SSOT | M | editar → rotular "~400" como heurística não-vinculante |

### 🟢 Oportunístico

| # | Dim | Achado | Esf. | Comando |
|---|-----|--------|------|---------|
| 14 | D6 | `agent-skills-specialist.md:103` resíduo **multi-IDE** (".agents/skills p/ Cursor/VS Code") — abandonado em 2026-05-18 (`architecture.md §5/§7`) | S | editar |
| 15 | D4 | `context-window-optimization.md:40-53` versões fixas de modelo sem disclaimer evergreen → referenciar SSOT `agent-orchestration.md §lineup` ([[prefer-evergreen-model-references]]) | S | editar |
| 16 | D4 | `identificar-precificar-dor-cliente.md` + `branding-posicionamento-marca.md` sem `date` em frontmatter (auditoria automática cega) | S | editar |
| 17 | D2 | `agent-creator-specialist.md:838-1132` (~294 linhas inline: matriz/anti-patterns/templates) sem KB paralela — `command-creator` já tem a sua | M | `/meta:create-knowledge-base` |
| 18 | D2 | `command-creator-specialist.md:926-956,1010-1018` duplica inline o que já está na sua KB | S | editar → referenciar KB |
| 19 | D1 | `product/estimate.md` **2 blocos quase-duplicados** de output ClickUp (`:122-161` vs `:276-332`). **Reclassificado:** NÃO é violação de tamanho (491 ≤ 500 OK); é dup de conteúdo | S | editar / `common/prompts` |
| 20 | D7 | `sessions/INDEX.md:9-14` linka diretório em vez de `STATE.md` (gitignored — não embarca) | S | editar |
| 21? | D3 | `test/{unit,integration,e2e}.md` "Validações e Regras" — **NÃO VERIFICADO** pelo juiz; **mesmo padrão** dos D3 refutados (line-count inflado, trio é diferenciação intencional). **Re-verificar antes de agir** | M | re-verificar |

---

## 2. Achados por dimensão

- **D1 (peso) — 0 reais.** Os 3 "outliers" (estimate/runflow/branding, 474–491 linhas) usaram threshold falso "~400"; todos ≤500 (OK por `commands.md §5`). Juiz refutou 2; o 3º (estimate) reconciliado aqui. Sobra só dup de conteúdo em estimate (→ #19, oportunístico).
- **D2 (redundância) — 2:** ambos creators (#17, #18). Sem propostas de fusão de artefatos diferenciados (calibração do run anterior respeitada).
- **D3 (duplicação) — 1 suspeito (#21).** 3 dos 4 achados D3 **refutados** pelo juiz: line-counts inflados ("71+ idênticas" em 77 linhas totais = impossível) e trio testing é diferenciação intencional confirmada.
- **D4 (KBs stale) — 4 (#7,#8,#15,#16):** todos por flag-não-honrado / evergreen / data-ausente — **nenhum** passou do gate ≤18mo (calibração correta).
- **D5 (meta-spec) — 2 + 1 sistêmico (#1,#5,#13).** `architect/` (c4) **confirmado fechado** (não-achado). Categorias `compliance/`/`admin/` fantasma reais.
- **D6 (legado/vazamento) — 5 (#2,#3,#4,#6,#14):** **MCP-first segue a causa #1** (3 achados + propagadores). Resíduo multi-IDE e gap de fan-out.
- **D7 (links) — 6 acionáveis (#9–#12,#20 + carry):** v1 federação morto (2 refs), 2 paths errados (corrigidos), path SDAAL, INDEX. **2 falsos-positivos** curados (ver §curados).
- **D8 (frontmatter/inventário) — 0 reais.** Inventário **limpo** (82/49/5/34 em sync). Os 3 achados de frontmatter em `common/*` + READMEs **refutados/suspeitos** — `commands.md §5.1` **isenta** esses fragmentos (não são comandos invocáveis).

---

## 3. Alertas transversais (causa sistêmica)

1. **🔴 Vazamento MCP-first vs API-first — segue sendo a causa #1 (NÃO executado desde 2026-06-15).** Itens #2,#3,#4 (+ #5 phantom correlato). Crítico: **propagadores** (`agent-template.md`, `agent-creator-specialist.md`) infectam todo artefato novo. **Varredura única num PR**, começando pelos propagadores ([[agent-fleet-cursor-tool-names-broken]] — consertar a fonte, não as folhas).
2. **🟡 Categorias de comando fantasma** — #1, #5 (`compliance/`, `admin/` em meta-creators). Confinado a 2 agentes; `c4` já corrigido.
3. **🟡 Ambiguidade de threshold de tamanho (NOVO)** — #13. O "~400" heurístico vs `§5` (500/800) gerou 2 falsos-positivos D1 **e fez o painel de juízes divergir** (estimate mantido no juiz, runflow/branding refutados, mesma régua). Reconciliar a documentação de validação.
4. **🟡 Links mortos do v1 da federação** — #9 (+ path em sessão arquivada gitignored). Remoção do v1 (#53) deixou refs penduradas.

---

## 4. Invariantes respeitadas

- **0 vetos de fusão de fase.** Nenhum juiz marcou `vetoed_phase_merge=true`. Nenhuma proposta tocou as fases de `engineer/* (plan→pr-update)` ou `product/* (collect→feature)`.
- **Camada adversarial fez o trabalho — 8/13 refutados** pegando: threshold falso (~400), duplicação aritmeticamente impossível (D3-6), exemplos "idênticos" que eram diferenciados (D3-8), **fix errado** (repoint vs delink, D7-21), **premissa falsa** (agente "não criado" que existe, D7-22), e **leitura invertida da meta-spec** (§5.1 isenta fragmentos, D8-30).
- **Diferenciação intencional preservada:** trio testing, branch-scoped vs general, meta-creators — nenhuma fusão proposta sobreviveu/foi feita.

---

## 5. Próximos passos (cada item → atuador)

1. **🔴 Varredura MCP-first → API-first** (#2,#3,#4,#5) — 1 PR, propagadores primeiro, sob `@metaspec-gate-keeper`.
2. **🔴 Corrigir categorias fantasma** (#1) — editar `command-creator-specialist.md`.
3. **🟡 `/meta:kb-freshness`** (#7,#8) + edits evergreen/data (#15,#16).
4. **🟡 Reconciliar threshold de tamanho** (#13) — alinhar `onion-patterns`/`onion-validation`/`command-template` à `commands.md §5`.
5. **🟡 Reparar links** (#9–#12,#20) — edits pontuais (delink v1; paths corrigidos).
6. **🟢 Oportunístico:** KBs dos creators (#17,#18), resíduo multi-IDE (#14), dup estimate (#19); **re-verificar #21** antes de agir.

---

## 6. Addendum — itens registrados manualmente (pós-run)

> Itens **não** produzidos por nenhum run de `/meta:evolve` — registrados à mão, com **gatilho**.
> Carregados de `onion-evolution-2026-06-15.md §6` (superseded). Não são dívida ativa.

| # | Sev | Tema | Item | Gatilho | Atuador |
|---|-----|------|------|---------|---------|
| A1 | 🟢 | Federação / interop | Implementar **projeção export-only Agent Card** do `members.yaml` (formato A2A, **sem runtime**) — decisão em [ADR A2A](onion-federation-adr-a2a-format-interop-2026-06.md) | **1º consumer não-Onion** na federação **ou** necessidade nomeada de interop A2A externa | script emissor em `.claude/validation/` + revalidar campos contra spec A2A vigente |

> **Não é dívida ativa.** Doutrina já permite (linha vermelha partida em `multi-repo-federation.md §7`);
> construir antes do gatilho seria especulação (sem consumer não-Onion hoje).

---

## 7. Curados como NÃO-acionável (transparência — sem ação)

> Listados para não reaparecerem como "novos" no próximo run e para registrar o veredito.

| Achado | Veredito |
|--------|----------|
| `c4-architecture-specialist.md:681` categoria `architect/` | **Fechado** — o arquivo já se autodeclara conforme; não-achado |
| Inventário `82/49/5/34` | **Limpo** — em sync com SSOT; não-achado |
| 3 READMEs não-kebab-case | **Conforme** — exceção legítima `commands.md §4.1` |
| `c4-adr-patterns.md:150-511` (~40 "links quebrados") | **Falso-positivo** — são paths-exemplo de template p/ adotantes |
| `technical.md:52-65` placeholders | **Falso-positivo** — placeholders de template, não refs reais |
| `common/*` sem `description` (16) / `allowed-tools` (18) / `name` (14) | **Refutado/suspeito** — `commands.md §5.1` isenta fragmentos (não-invocáveis); skills `common:*` já estão registradas |

> **Ciclo de vida (exceção ao supersede limpo):** este é o **backlog ativo**, mas `onion-evolution-2026-06-15.md` **NÃO é removido** — ele virou **âncora de citação** de `docs/materials/*`, `press-kit.md`, `case-studies.md` e da KB de identidade (que citam suas métricas §0 específicas: 28 agentes · 1.27M tokens · ~26 min · 30 achados — números que só existem lá). Removê-lo quebraria citações duráveis. Os dois reports coexistem com papéis distintos: **06-16 = backlog ativo**; **06-15 = run citado (proof-point)**. Itens executados saem na próxima rodada de `/meta:evolve`.
