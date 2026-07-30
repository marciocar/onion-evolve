---
title: "Onion Evolution Backlog — 2026-07-30"
date: 2026-07-30
kg: docs/onion/graph/onion-evolution-2026-07-30.kg.yaml
---

# Onion Evolution Backlog — 2026-07-30

## 0. Sumário

◆ Dimensões: 10 (D1–D8 scan/fan-out · D9 no-op no framework · D10 memória de sessão)
◆ Padrão: fan-out-and-synthesize + verificação adversarial · Run ID: `wf_7a6ca1e6-064`
◆ Achados brutos: 13 → **5 refutados** (3 juiz adversarial + 2 verificação principal) → **8 sobreviventes**
◆ Severidade: **🔴 0 blocker · 🟡 2 recommended · 🟢 6 opportunistic** (após verificação)
◆ **Veredito: framework SAUDÁVEL** — 0 dívida estrutural, nenhum agente acima do limite de peso, nenhum
resíduo `.onion`/CLI/npm/multi-IDE, lint 0 HARD. Os sobreviventes são **polimento**, não dívida.
◆ **Grafo primeiro:** `docs/onion/graph/onion-evolution-2026-07-30.kg.yaml` (radar exit 0) — este
relatório é a **projeção** dele.

> ⚠️ **A 1ª rodada falhou (schema bug) e o "0 findings" era FALSO** — os 6 workers erraram; o harness
> expôs. Re-rodei com o schema corrigido. Behavior-over-declaration: um "tudo limpo" não-verificado teria
> sido mentira com cara de sucesso (o próprio crítico sinalizou "zero achados é red flag").

## 1. Backlog priorizado

| # | Sev | Dim | Achado (arquivo:linha) | Padrão (doutrina) | Esforço | Comando de execução |
|---|-----|-----|------------------------|-------------------|---------|---------------------|
| 1 | 🟡 | D6 | `system-documentation-orchestrator.md:6-13,177-201` — usa `mcp_code-understanding_*` (4 chamadas sequenciais em prosa) sem declarar no `tools:` nem gatear ausência | declarar+gatear MCP + prosa-sequencial→Workflow fan-out | S | `/meta:create-agent` (edit) |
| 2 | 🟡 | D3 | story-points workflow duplicado em `product/{task,estimate,feature}.md` (~100 linhas) | consolidar em `common/prompts/story-points-gate.md` (já parcial) | M | `/product:spec → /engineer:plan` |
| 3 | 🟢 | D2 | `quick/analysis.md` × `meta/analyze-complex-problem.md` — sem nota de diferenciação | self-differentiating description | S | `/meta:create-command` (edit) |
| 4 | 🟢 | D3 | template de comentário Unicode dup em `product/{task,feature}.md` (~40 linhas) | snippet em `common/prompts/` | S | edit |
| 5 | 🟢 | D2 | `test-agent.md:1-6` — falta a linha de diferenciação vs `test-planner` na **description** (o corpo já tem `### Com test-planner:`) | self-differentiating description | S | edit |
| 6 | 🟢 | D7 | docs de discussão (`onion-pessoal-marcio/`, `proto/README`, `technical-context/contributing`) usam links relativos internos | convenção de links absolutos do `.claude/` | S | edit (baixo valor — fora da superfície de comando) |

## 2. Achados por dimensão

- **D1 (peso):** ✅ limpo — 0 agentes acima do soft (1200); os comandos >500 linhas são **templates**
  (`common/templates/*`) e `adopt.md`/`kg.md` (comandos densos por design, dentro do hard 800).
- **D2 (redundância):** 3 pares sem nota de diferenciação (test-agent/test-planner ⇒ #5;
  quick:analysis/analyze-complex-problem ⇒ #3). **Nenhuma fusão** — são peers/profundidades distintas.
- **D3 (duplicação):** 2 sobreviventes (#2 story-points, #4 comment-template) + **3 refutados pelo juiz**
  (eram adapters finos ou citações ao fragmento canônico, não texto duplicado).
- **D6 (moderna/legada + SDAAL):** 1 achado (#1 — o único de "modernização" real: MCP não-declarado +
  prosa-sequencial). **Nenhum resíduo `.onion`/CLI/npm/multi-IDE.**
- **D7 (links):** 3 achados, todos em **docs de discussão** (fora de `.claude/`) — cosmético.
- **D8 (frontmatter/plataforma):** ✅ limpo (2 achados brutos **refutados na verificação**).
- **D9 (contexto de domínio):** no-op — os `docs/*-context/` do framework são templates (só README).
- **D10 (memória de sessão):** varredura **parcial** (o classificador de Bash caiu no meio) — 1 entrada
  stale já identificada (`session-state-2026-07-27`: "vnextpin metagamify aguarda re-stampar" → **esta
  sessão reconciliou** no #490). **Não corrigida sem re-teste** (doutrina D10: nunca re-carimbar sem
  re-testar). Follow-up: completar quando o Bash-classifier estabilizar.

## 3. Alertas transversais (causa sistêmica)

Um só, e é **positivo por inversão:** os 3 pares "quase-duplicados" (D2) e as 3 falsas-duplicações (D3)
mostram que **a doutrina de fonte-única/diferenciação-explícita JÁ está internalizada** — os adapters
citam o fragmento canônico, os pares peer carregam a nota "Diferença vs…". Os sobreviventes são os
**poucos que ainda não** seguem o padrão que o resto já segue. Não é dívida sistêmica; é acabamento.

## 4. Invariantes respeitadas

- **Nenhuma proposta funde fases** de `engineer/*`, `product/*` ou os modos de `kg` — o juiz adversarial
  vetou explicitamente (e nenhum sobrevivente propõe fusão de fases).
- **Read-only:** este `/meta:evolve` não mutou `.claude/`. Escreveu só o grafo + este relatório.

## 5. Próximos passos (cada item → seu atuador)

O backlog é **opcional e de polimento** (0 blocker). Se atacado, por prioridade: #1 (o único
"modernização") → #2 (a consolidação de maior retorno) → #3-5 (notas de diferenciação, S) → #6 (baixo
valor). Completar o D10 (memória) quando o classificador estabilizar.

**O sinal mais importante deste evolve não é o backlog — é que ele está curto e sem blocker.** Após 500
PRs e uma sessão intensa, o framework se auditou e saiu **saudável**; o mecanismo que mais trabalhou foi
o de **refutação** (5 de 13 achados eram falso-positivo, pegos pelo juiz + pela verificação principal) —
a auditoria duvidando dos próprios achados, o mesmo fio da sessão inteira.
