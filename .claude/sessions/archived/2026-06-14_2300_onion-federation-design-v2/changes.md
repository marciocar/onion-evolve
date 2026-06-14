# Mudanças Realizadas — Onion Federation Design v2

## Arquivos Criados

- `docs/analysis/onion-federation-design-review-2026-06.md`
  Relatório consolidado da review adversarial (frota `wf_dbfb2b91-cd3`):
  36 raw → 24 confirmados (12 refutados, taxa 33%). 3 alertas sistêmicos:
  SA-1 (viola meta-spec L0), SA-2 (segurança declarada não especificada),
  SA-3 (spike cross-dir load-bearing não-verificado). Backlog priorizado:
  7 blockers · 15 recommended · 2 opportunistic.

- `docs/analysis/onion-federation-design-v2-2026-06.md`
  Design completo da topologia peer (9 seções): pivô hub→peer, guardrails de
  identidade, modelo mental (diagrama ASCII ledger spine), componentes + onde vivem
  + reuso, máquina de segurança realocada, workflow do maestro (6 checkpoints HitL),
  backlog faseado (Fases 0–5; Fase 5 fora de escopo), mapeamento dos 24 achados
  da review (resolvido/endereçado/aberto). **Este é o design vigente.**

## Arquivos Modificados

- `docs/analysis/onion-federation-design-2026-06.md`
  Header SUPERSEDED adicionado no início do arquivo:
  ```
  > **⚠️ SUPERSEDED (2026-06-14):** esta é a **v1 (topologia hub)**. Após a review adversarial
  > (24 achados confirmados, 7 blockers), o design vigente passou a ser
  > **onion-federation-design-v2-2026-06.md**. Este v1 fica como **trilha de racional do pivô**.
  ```

## Arquivos Removidos

- `.claude/sessions/allowed-tools-and-kb-content/` (diretório)
  Resíduo de sessão pré-refactor: só `context.md` + `architecture.md`, sem STATE.md/plan.md.
  Gitignored. Trabalho já estava em main (8 comandos com `allowed-tools:` + 2 KBs corrigidas).
  Removido sem impacto.

## Workflows / Agentes Executados

1. **`wf_dbfb2b91-cd3`** (`federation-design-review`)
   - 42 agents · ~1.46 M tokens · ~24 min
   - 6 lentes de review (identity, feasibility, safety, reuse, phasing, completeness) →
     pipeline verify adversarial por achado → consolidação com alertas sistêmicos
   - Output: `{"total_raw":36,"confirmed_count":24,"dropped_count":12,...}`

## PRs Criados e Merged

| PR | Hash | Branch | Título |
|---|---|---|---|
| #36 | `4cebe5a` | `docs/onion-federation-design` | `docs(analysis): Onion Federation design + phased backlog (multi-repo orchestration)` |
| #37 | `a6c9083` | `docs/onion-federation-design-v2` | `docs(analysis): Onion Federation v2 — pivot to peer topology + git ledger` |

## Branches Deletadas

- `docs/onion-federation-design` — deletada local + remoto (pós-merge PR #36)
- `docs/onion-federation-design-v2` — deletada local + remoto (pós-merge PR #37)

## Comandos Onion Executados

1. `/validate:workflow` — executado por acidente, abortado
2. `Workflow` (federation-design-review) — frota adversarial de review
3. Plan mode (`EnterPlanMode`/`ExitPlanMode`) — design v2 aprovado pelo usuário
4. `/docs:sync-sessions` — esta sessão de archiving
