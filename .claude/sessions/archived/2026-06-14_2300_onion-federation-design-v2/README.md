# Onion Federation Design v2 — Pivot to Peer Topology — 2026-06-14

## 🎯 Objetivo

Projetar e consolidar a capacidade **Onion Federation**: coordenar mudanças entre múltiplos
repositórios de forma contract-safe, sem quebrar integrações, com o humano como maestro.

A sessão percorreu **três rodadas**:
1. Design v1 (topologia hub) → PR #36 merged
2. Review adversarial (frota 42 agents) → 24 achados confirmados → relatório
3. Pivô hub → peer + ledger git → design v2 → PR #37 merged

## 📊 Resultados

### Arquivos criados
- [`docs/analysis/onion-federation-design-review-2026-06.md`](../../../../docs/analysis/onion-federation-design-review-2026-06.md) — relatório da frota adversarial (24/36 achados, 3 alertas sistêmicos)
- [`docs/analysis/onion-federation-design-v2-2026-06.md`](../../../../docs/analysis/onion-federation-design-v2-2026-06.md) — design vigente (topologia peer + ledger git)

### Arquivos modificados
- [`docs/analysis/onion-federation-design-2026-06.md`](../../../../docs/analysis/onion-federation-design-2026-06.md) — header SUPERSEDED adicionado (v1 = trilha de racional)

### PRs merged
- **#36** (`4cebe5a`) — `docs(analysis): Onion Federation design + phased backlog (multi-repo orchestration)` — design v1
- **#37** (`a6c9083`) — `docs(analysis): Onion Federation v2 — pivot to peer topology + git ledger` — design v2 + review + superseded

### Limpeza
- Sessão orphan `.claude/sessions/allowed-tools-and-kb-content/` removida (resíduo pré-refactor; trabalho já em main)
- Branches `docs/onion-federation-design` e `docs/onion-federation-design-v2` deletadas (local + remoto)

## 🤖 Agentes e Workflows

| Artefato | Tipo | Resultado |
|---|---|---|
| `wf_dbfb2b91-cd3` (federation-design-review) | Workflow · 42 agents · ~1.46M tokens | 36 raw → 24 confirmados (12 refutados) |
| Frota de review adversarial | 6 lentes (identity, feasibility, safety, reuse, phasing, completeness) + verify stage | 3 alertas sistêmicos: SA-1, SA-2, SA-3 |

## 🔗 Links Relacionados

- PR #36: `4cebe5a` — design v1 (hub)
- PR #37: `a6c9083` — design v2 (peer) + review
- Plan aprovado: `/home/marciocar/.claude/plans/onion-quero-que-fa-a-foamy-babbage.md`
- Design vigente: `docs/analysis/onion-federation-design-v2-2026-06.md`

## ⏱️ Tempo Investido

Sessão multi-turno (~3–4 horas efetivas): design v1 → review adversarial (24 min de frota) → design v2.

## ⏭️ Próximo Passo Natural

**Fase 0 do backlog Federation v2** (gate de tudo, antes de qualquer arquivo em `.claude/`):
- (a) Veredito do `@metaspec-gate-keeper` sobre placement (`meta/` vs nova categoria)
- (b) Spike go/no-go: validar ledger git como additional working directory
