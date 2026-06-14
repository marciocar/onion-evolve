---
title: Onion Evolution Backlog v2 (medição "depois") — 2026-06-14
date: 2026-06-14
status: backlog
gerado-por: /meta:evolve v1.1.0 (fan-out-and-synthesize + verificação adversarial, finding_id estável)
run-id: wf_82ddb76e-21f
escopo: re-auditoria completa (8 dimensões) pós-merge dos 5 PRs do ciclo v1
compara-com: onion-evolution-2026-06-14.md (v1)
---

# Onion Evolution Backlog v2 — medição "depois"

Segunda rodada de `/meta:evolve`, executada **após o merge dos 5 PRs** que
endereçaram o backlog v1. Mede o "depois" e valida o fix do finding_id (#18).

## 0. Antes × Depois

| Métrica | v1 (antes) | v2 (depois) | Δ |
|---|---|---|---|
| Achados brutos | 36 | 20 | −44% |
| Refutados/vetados | 11 | 3 | — |
| **Confirmados (backlog)** | **25** | **17** | **−32%** |
| 🔴 blocker | 7 | 2 | −5 |
| 🟡 recommended | 15 | 13 | −2 |
| 🟢 opportunistic | 3 | 2 | −1 |
| Budget | ~1,55M tok | ~0,90M tok | −42% |

> **O fix do #18 funcionou**: `surviving (17) = raw (20) − refutados (3)` — bate
> exato. Na v1 a correlação por texto deixava 10 refutados vazarem; na v2 a
> correlação por `finding_id` removeu os 3 refutados corretamente.

### O que o ciclo v1 resolveu (verificado pela v2)
- ✅ **D7 (links)**: a maioria dos 7 links do v1 resolve. **Mas** a v2 pegou
  **3 links que escaparam** da minha correção do #16 (ver §2 — footers + 1 linha).
- ✅ **D3 (dedup)**: os 2 blocos extraídos para `common:prompts` não reaparecem.
- ✅ **D5 (recategorização)**: `task-specialist`/`gitflow-specialist` nas categorias
  certas; contradição §1.1↔§8 resolvida. **Mas** surgiram 2 staleness novos de
  meta-spec (§2).
- ✅ **D1 (tamanho)**: novamente 0 hard violations (1 near-soft refutado).
- ✅ **D4 (frescor)**: os 6 KBs do v1 OK. **Mas** a v2 (não-bounded) achou 2 KBs
  com staleness **de conteúdo** mais profundo que meu refresh superficial não pegou.

## 1. Backlog v2 priorizado (17 confirmados)

### 🔴 Blockers (2)
| id | Achado | Padrão | Alvo | Esf |
|----|--------|--------|------|-----|
| D5-8 | `architecture.md` (L0) não documenta `utils/forge/` — diverge da realidade desde 2026-06-13; qualquer PR que toque `utils/` tem ground-truth errado | Shed→KB / sync spec | `docs/meta-specs/architecture.md` | S |
| D8-17 | Comandos de subdiretório com `name` achatado (`test-strategy-analyze`) violam a regra §1.1 que **nós** adicionamos no #19 (`name` deve casar o filename) | commands.md §1.1 | `validate/test-strategy/{analyze,create}`, `validate/qa-points/estimate` | S |

### 🟡 Recommended (13)
| id | Achado | Padrão | Esf |
|----|--------|--------|-----|
| D7-14 | `abstraction-template.md:394` link `../meta/create-abstraction.md` quebrado (→ `../../meta/`) — **escapou do #16** | fix-link | S |
| D7-15 | `asana.md:541` footer SDAAL `../../../docs` quebrado (→ `../../../../`) — **escapou do #16** (corrigi só a linha 3) | fix-link | S |
| D7-16 | `linear.md:780` footer SDAAL idem | fix-link | S |
| D5-9 | `commands.md §2` + `architecture.md §1.2` listam `global/` como categoria válida, mas foi removida no saneamento 2026-05-18 | sync spec | S |
| D5-10 | `agents.md §2` lista `code-reviewer` como exemplo de `git/`, mas o agente só existe em `review/` | sync spec | S |
| D8-2 | `pr-update.md` faz commit+push sem `allowed-tools` (§1.3) | commands.md §1.3 | S |
| D8-18 | 6 comandos mutantes sem `allowed-tools` (feature, bump, create-*, test-strategy) | commands.md §1.3 | M |
| D4-6 | `abstraction-patterns-catalog.md` stale de **conteúdo**: Jira como "🔮 Futuro" (já implementado), Git Provider "Proposto" (Forge existe), var `GIT_PROVIDER` errada (é `FORGE_PROVIDER`) | Shed→KB | M |
| D4-7 | `task-manager-abstraction.md` diagrama stale: Jira ausente, Linear marcado "(Stub)" (tem 785 linhas), transporte "MCP" (doutrina é API-first) | Shed→KB | S |
| D2-4 | `test-agent` embute conhecimento de test-strategy que duplica `/validate/test-strategy/create` + `/validate/qa-points/estimate`, sem cross-ref | Reposicionar detentor de conhecimento | M |
| D6-12 | `build-compliance-docs` despacha 4 especialistas independentes em prosa → candidato a fan-out | Workflow fan-out | S |
| D6-13 | Cluster de 9 guias em `.claude/docs/onion/` (5.698 linhas) com conhecimento citável | Shed→KB | M |
| D1-0 | `docker-specialist` (1192) com cerimônia extensa (Guidelines/Examples) → KB | Shed→KB | M |

### 🟢 Opportunistic (2)
| id | Achado | Esf |
|----|--------|-----|
| D2-5 | `docs/consolidate-documents` e `product/consolidate-meetings` compartilham Steps 1-3 quase idênticos | S |
| D5-11 | 4 agentes com `description` YAML sem padrão de gatilho ("use para") exigido por agents.md §5 | S |

## 2. Achados que são correções/completações do ciclo v1 (auto-crítica)

A v2 expôs que **meu trabalho no v1 foi incompleto em 2 frentes** — exatamente o
valor de re-auditar:

1. **#16 (links) ficou incompleto** — corrigi a linha 3 dos adapters e as linhas
   392-393 do template, mas deixei: o footer SDAAL de `asana.md:541` e
   `linear.md:780`, e o link `create-abstraction.md` em `abstraction-template.md:394`.
   (D7-14/15/16). Verificado manualmente no contexto principal.
2. **#20 (frescor KB) foi superficial** — adicionei campos de data, mas não
   corrigi o **conteúdo stale** de `abstraction-patterns-catalog.md` (Jira/Forge
   como "futuro") nem o diagrama de `task-manager-abstraction.md`. (D4-6/D4-7).

E o ciclo v1 **criou** 1 conformance gap: a regra §1.1 que adicionei (#19,
"`name` casa o filename") agora é violada por 3 comandos de subdiretório (D8-17).

## 3. Alertas transversais
- 🟡 **Meta-specs L0 defasadas vs realidade** (D5-8, D5-9, D5-10): `architecture.md`/`commands.md`/`agents.md` descrevem estrutura que mudou (forge adicionado, global/ removido, code-reviewer só em review/). A constituição precisa de um sync.
- 🟡 **KBs de abstração stale de conteúdo** (D4-6, D4-7): catálogo e task-manager-abstraction descrevem Jira/Forge/Linear como futuros/stubs quando estão implementados.

## 4. Invariantes respeitadas
- ✅ 0 vetos de fusão de fase. Nenhuma proposta tocou fases de `engineer/*`//`product/*`.
- ✅ finding_id correlacionou achado↔veredito corretamente (fix #18 validado em produção).

## 5. Próximos passos (clusters → atuador)
1. **Quick wins de consistência** (D7-14/15/16 links + D5-8/9/10 sync de meta-spec + D8-17 names) — edição direta, baixo risco. **Completam os #16/#19.**
2. **`allowed-tools` em mutantes** (D8-2, D8-18) — 7 comandos → `/meta:metaspec-validate` + edição.
3. **Refresh de conteúdo de KB** (D4-6, D4-7) — `/meta:kb-freshness` profundo ou edição.
4. **Refactors maiores** (D1-0 docker, D2-4 test-agent, D6-13 docs cluster) — `/product:spec → /engineer:plan`.

## 6. Referências
- Run: `wf_82ddb76e-21f` · v1: [onion-evolution-2026-06-14.md](onion-evolution-2026-06-14.md)
- Doutrina: [onion-modernization-doctrine.md](../knowledge-base/concepts/onion-modernization-doctrine.md)
