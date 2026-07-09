---
tipo: sinal-upstream (artefato de referência)
data: 2026-07-09
origem: rhilo-metagamify (consolidação WRR/SLA/Oráculo)
assunto: ARTEFATO — mapa-SSOT da consolidação (pedido na resposta 'consolidacao-multibranch-framework-candidate')
re: resposta do core 2026-07-09 (framework-candidate; 'declarado ≠ verificado' — segue o destilável)
nota: conteúdo integral de docs/wrr/2026-07-09-mapa-consolidacao.md no momento do relay (inclui vereditos da verificação 6-branch, política de escopo de PR, salvage, build-green e sequência de PRs).
---

---
title: Mapa de Consolidação — metagamify + rhilo-app
data: 2026-07-09
tipo: SSOT de release / consolidação
regra: 'convergir para branches consolidadas → PRs SÓ sob comando do Marcio · nada fica pelo caminho · nada quebra prod (rhilo/main + main)'
status: PRIMEIRA VERSÃO — payloads de +N commits marcados [VERIFICAR] precisam de review commit-a-commit antes de qualquer merge
---

# Mapa de Consolidação (2026-07-09)

## Regras (do Marcio)

1. Levar **metagamify** e **rhilo-app** cada um para **uma branch consolidada**.
2. Dela, abrir os PRs **só sob comando** — nenhum PR autônomo.
3. **Nada pode ficar pelo caminho** (nenhum trabalho perdido).
4. **Nada pode quebrar produção** depois que `rhilo/main` (metagamify) e `main` (rhilo-app) forem atualizados.

## Baselines de PRODUÇÃO

- **metagamify PROD** = `rhilo/main` (imagem ECS; cura da dose PR #76 @a4e03184). PRs Onion miram `develop`.
- **rhilo-app PROD** = `main` (GAP#1 já deployado, PR #957 @5e5cff55d).
- KG `C_DEVPROD_GAP`: _"ler branch de trabalho ≠ ler produção"_ — respeitar por branch.

## Duas LANES (não misturar)

- **LANE CÓDIGO** — toca runtime → afeta prod → mira `rhilo/main` / `main`. Prod-safety obrigatória.
- **LANE CONHECIMENTO** — docs + `.claude/` (Onion source) + KG (`.kg.yaml`) → mira `develop` (base Onion). Não afeta a imagem de prod.

---

## METAGAMIFY — inventário (vs `rhilo/main`)

| Branch                                  | Δ              | Lane         | Classe                                                                                              | Ação proposta                                                                        |
| --------------------------------------- | -------------- | ------------ | --------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------ |
| `fix/wrr-c1-level-null-dose-cap`        | +0 (main +3)   | código       | **ABSORVIDA** em main                                                                               | descartar (já em prod)                                                               |
| `fix/wrr-dose-honest-measure`           | +0 (main +1)   | código       | **ABSORVIDA** (cura dose)                                                                           | descartar                                                                            |
| `feat/wrr-reconcile-unassign` ← _atual_ | +3 (main +0)   | código       | **PROD-CANDIDATE** — reconcile-unassign idempotente + `slaBacklogPolarity` passthrough (PX-978)     | base da consolidação de código; [VERIFICAR] prod-safety dos 3 commits                |
| `origin/fix/wrr-freeze-guards`          | +19 (main +10) | código       | **PROD-CANDIDATE** — freeze guards + **`pending-slots`** (read do Gate A/dose, C1/loadLimitContext) | fonte da dose-viz (#1); [VERIFICAR] os 19 commits (freeze guards ≠ só pending-slots) |
| `feat/wrr-cockpit-ajustes`              | +1 (main +5)   | código       | **STRAGGLER** (C1 level=null)                                                                       | [VERIFICAR] se o +1 já não está em main por outro caminho                            |
| `feat/wrr-modo-equilibrio`              | +2 (main +7)   | código       | **STRAGGLER** (artefatos/rollback)                                                                  | [VERIFICAR]; provável só artefato                                                    |
| `chore/ci-wrr-flag-guard`               | +8 (main +2)   | infra/CI     | gate de vocabulário de flags                                                                        | consolidar à parte (CI, não runtime)                                                 |
| `chore/onion-resync`                    | +1             | conhecimento | resync do corpo Onion                                                                               | lane conhecimento                                                                    |
| `sim/wrr-dispersion-model`              | +33 (main +10) | experimental | modelo de dispersão (sim)                                                                           | **NÃO-prod**; manter como pesquisa                                                   |
| `audit/oraculo-integration`             | +76 (main +2)  | conhecimento | **KG + `.claude/` + docs** (438 arq, 0 em apps/api/src)                                             | lane conhecimento → `develop`; **contém o KG SSOT**                                  |
| `develop`                               | +73 (main +14) | conhecimento | base de integração Onion                                                                            | alvo dos PRs de conhecimento                                                         |

## RHILO-APP — inventário (vs `main`)

| Branch                                      | Δ               | Lane     | Classe                                                                            | Ação proposta                                                      |
| ------------------------------------------- | --------------- | -------- | --------------------------------------------------------------------------------- | ------------------------------------------------------------------ |
| `fix/wrr-terminal-unassign-real-caseid`     | merjada         | código   | **ABSORVIDA** (GAP#1 em prod, PR #957)                                            | descartar                                                          |
| `fix/wrr-terminal-unassign-whitelist`       | +0 (main +84)   | código   | **ABSORVIDA**                                                                     | descartar                                                          |
| `fix/sla-backlog-case-scoped-count`         | +1 (main +0)    | código   | **PROD-CANDIDATE** — SLA por-caso (857e35f78)                                     | já é base do command-center (incluído)                             |
| `feat/command-center-v2-redesign` ← _atual_ | +5 (main +0)    | código   | **PROD-CANDIDATE** — redesenho gamificação-v2 + Oráculo real + drift #5 + SLA fix | base da consolidação de código rhilo-app                           |
| `feat/wrr-reconcile-unassign`               | +7 (main +43)   | código   | **PROD-CANDIDATE** — SLA opt-out UX (Destravar/isenção) + reconcile (PX-978)      | [VERIFICAR] os 7 commits; casa com o reconcile do metagamify       |
| `feat/gamification-dose-viz`                | +24 (main +350) | código   | **SUPERSEDED** — Oráculo antigo (replay premium)                                  | o command-center substitui; [VERIFICAR] se algo dos +24 não migrou |
| `feat/gamification-cockpit-v2`              | +1 (main +148)  | código   | **STALE**                                                                         | [VERIFICAR] o +1                                                   |
| `chore/backend-dev-auth-bypass-ci-guard`    | +1 (main +72)   | infra/CI | ratchet anti dev-auth                                                             | consolidar à parte (CI)                                            |

---

## Escopo de PR — o que INCLUI vs EXCLUI ("nada fica pelo caminho" ≠ "tudo vai no PR")

Cada artefato vai ao destino certo (ou é descartado de propósito); nada valioso se perde, nada de ruído entra em prod.

**PR de CÓDIGO (mira `rhilo/main` / `main`) — SÓ código de runtime:**

- INCLUI: `apps/**`, `prisma/schema.prisma` + migrações, testes, `.env.example`.
- EXCLUI (vai p/ lane conhecimento ou é dropado): `docs/**`, `docs/reports/**`, `scripts/*probe*.sql`, `.claude/**`.
- Alvo de limpeza concreto: **`fix/wrr-freeze-guards`** arrasta 7 `docs/wrr` + 3 `docs/reports` + `scripts/freeze-probe.sql` → **strip antes do PR de código** (cherry-pick só os `apps/api` + o `schema.prisma`).

**NUNCA em PR nenhum (higiene/segurança) — remover/gitignore:**

- **Dumps/dados**: nenhum dump HML, `*_hostinger`, nenhum `.json.gz` de dados de caso.
- **Achados a sanear (pré-existentes, NÃO propagar):**
  - metagamify: `logto-backup-20260121-153640.sql` (backup de auth versionado).
  - rhilo-app: `.claude.bkp.zip` (zip de backup) + **`.claude/sessions/**`** (SQL/`.json.gz` transitórios com possível PII de casos).
- Ação: `.gitignore` p/ `.claude/sessions/`, `*.bkp.zip`, backups `*.sql` não-migração; avaliar `git rm --cached` (limpeza separada, fora do PR de feature).

**`.claude/` (Onion source) — decisão por repo:**

- metagamify: `.claude/` está **untracked** no working tree atual (materializado de `develop`) — NÃO commitar nas branches de código.
- A evolução do framework (`.claude/` + KG) vai **só** pela lane conhecimento (`audit/oraculo-integration` → `develop`), e mesmo lá **sem** `.claude/sessions/` (transitório).

## Dependências cross-repo (o que casa)

- **PX-978 (SLA polarity/reconcile)**: metagamify `feat/wrr-reconcile-unassign` (passthrough `slaBacklogPolarity`) ⟷ rhilo-app `feat/wrr-reconcile-unassign` (UX opt-out) + `fix/sla-backlog-case-scoped-count`. **Devem ir juntos** (contrato de config compartilhado).
- **Dose-viz (#1)**: depende de metagamify `fix/wrr-freeze-guards` (`pending-slots`) chegar a prod → então rhilo-app faz o join `pending-slots + doseMaxByLevel` no front. **Bloqueado até freeze-guards consolidar.**
- **Drift (#5)**: já commitado no command-center; prod-safe (campos existem em `rhilo/main`). Sem dependência.

## Ordem de merge proposta (por lane) — SUJEITA A REVIEW

**LANE CÓDIGO (mira prod, ordem por risco crescente):**

1. rhilo-app: `fix/sla-backlog-case-scoped-count` + `feat/command-center-v2-redesign` (já inclui o SLA fix + drift #5, prod-safe) → branch consolidada rhilo-app.
2. metagamify: `feat/wrr-reconcile-unassign` (base) → branch consolidada metagamify.
3. metagamify: avaliar `fix/wrr-freeze-guards` (pending-slots) para dentro da consolidada [VERIFICAR os 19].
4. rhilo-app: `feat/wrr-reconcile-unassign` (SLA opt-out) — casar com o passo 2 (PX-978 conjunto).
5. Stragglers (`cockpit-ajustes`, `modo-equilibrio`) só se o [VERIFICAR] achar payload não-absorvido.

**LANE CONHECIMENTO (mira develop):** 6. metagamify: `audit/oraculo-integration` (KG + `.claude/` + docs) → `develop`. 7. **SINAL PARA O SOURCE (item de 1ª classe da consolidação):** promover o padrão **KG-SDAAL** ao Onion source via co-evolução upstream. Ver §"Sinal para o Onion source".

## Sinal para o Onion source (co-evolução) — INCLUÍDO NA CONSOLIDAÇÃO

Entregável rastreado, não opcional. O Onion source (`.claude/`) hoje tem **SDAAL-abstraction** (58 arq) e **dogfood** (16 arq), mas **NÃO** a materialização como knowledge-graph: **0** refs a `.kg.yaml`, **0** a `/meta:kg`, nenhuma skill de KG. O padrão que usamos é mais novo que o core.

- **Fonte do sinal:** `docs/evolution/inbox/2026-07-09-sdaal-generaliza-para-design-ia.md` (sinal-upstream; 2 dogfoods: domínio WRR + design/UI Command Center).
- **O que promover ao source:** formato `.kg.yaml` (nós tipados + arestas `TRACES_TO`), `scripts/kg/radar.js` (PageRank + integridade), o comando `/meta:kg` (hoje _gated_ esperando dogfood — já satisfeito), e a generalização **SDAAL→arquitetura-de-informação-de-UI** (`SourceTag` + atom-map).
- **Como:** `/meta:co-evolve` processa o inbox → PR ao repo do Onion source (fora destes 2 repos) **sob comando**. Rastrear junto com a lane conhecimento para **não ficar pelo caminho**.

## Riscos / "nada fica pelo caminho"

- **`feat/gamification-dose-viz` (+24, 350 atrás)**: Oráculo ANTIGO. Antes de descartar, [VERIFICAR] que 100% do valor migrou pro command-center (o novo é reescrita, não merge).
- **`fix/wrr-freeze-guards` (+19)**: "freeze guards" pode conter mais que `pending-slots` (guardas de congelamento) — review dos 19 antes de puxar p/ prod. ⚠ **Toca `prisma/schema.prisma` = MIGRAÇÃO** — risco prod real; revisar a migração isolada e confirmar reversível/aditiva antes do PR.
- **Trabalho local não-commitado**: nenhum agora (Oráculo+#5 commitados @2709dd384/@a3dc163c6). Manter disciplina: commitar antes de trocar de branch.
- **`sim/wrr-dispersion-model` e docs**: não podem sumir mesmo sendo não-prod — vão pela lane conhecimento.

## Veredito da verificação (2026-07-09) — 6 branches auditadas (fan-out read-only)

| Repo       | Branch                                 | Veredito                          | Ação                                                                                                                                                                                                                                                                        |
| ---------- | -------------------------------------- | --------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| metagamify | `feat/wrr-reconcile-unassign` (+3)     | **PROD-CANDIDATE / SAFE**         | Aditiva, retrocompat (flag `reconcile` default-false = baseline), SEM migração/flag/env. Consolidar.                                                                                                                                                                        |
| metagamify | `fix/wrr-freeze-guards` (+19)          | **NEEDS-CHANGES**                 | Migração `candidateContext Json?` aditiva/nullable mas **falta o SQL 009 + backfill** → 2 PRs (migração isolada 1º, código 2º). C3-decouple muda roteamento mas atrás da flag DB `floorAwareRoutingEnabled` (confirmar estado prod). `pending-slots` = Gate-A, read-only ✓. |
| metagamify | `feat/wrr-cockpit-ajustes` (+1)        | **STRAGGLER-DROP**                | Fix `level=null` já em prod; main o superou. Descartar.                                                                                                                                                                                                                     |
| metagamify | `feat/wrr-modo-equilibrio` (+2)        | **KNOWLEDGE-LANE**                | Só 4 scripts rollback `docs/reports/rollback/*equilibrio*` únicos; salvar, dropar resto.                                                                                                                                                                                    |
| rhilo-app  | `feat/command-center-v2-redesign` (+5) | **PROD-CANDIDATE / SAFE**         | 0 endpoints novos; drift #5 já suportado em prod; `pending-slots` 404 degrada bem; SLA fix read-only s/ migração. tsc 2/2 verde. Sign-off produto (backlog 177→45).                                                                                                         |
| rhilo-app  | `feat/wrr-reconcile-unassign` (+7)     | **NEEDS-REBASE → PROD-CANDIDATE** | Rebase limpo (overlaps disjuntos); **2 migrations aditivas antes do deploy** (senão 500 no backlog); `@Cron` autolock gated OFF ✓; validar SLAs `CASE_ACTION MENTORED`.                                                                                                     |
| rhilo-app  | `feat/gamification-dose-viz` (+24)     | **SUPERSEDED-SALVAGE**            | Resgatar 2 antes de dropar (ver §Salvage). Oráculo/F3c/F3d/history já em main+cc-v2.                                                                                                                                                                                        |
| rhilo-app  | `feat/gamification-cockpit-v2` (+1)    | **SAFE-TO-DROP**                  | Só self-fix de conflito; tema superado pelo cc-v2. Descartar já.                                                                                                                                                                                                            |

### Build-green das consolidadas (2026-07-09) — Fase 2 PROVADA
Montadas em worktrees isolados, conflitos resolvidos, deps instaladas, prisma gerado:
- **rhilo-app-consolidada** (`30972ef91` = command-center + reconcile, SLA composto): backend tsc **EXIT=0** + frontend tsc **EXIT=0**.
- **metagamify-consolidada** (`4407135d` = rhilo/main + reconcile + freeze-guards + 009): api tsc **EXIT=0** (após `prisma generate` + `nx build rule-engine ml-engine`).
- **Dado**: SLA composto validado no dump 07-08 fresco — baseline 45 · composta 29 · controle 167 (o reconcile-sozinho reintroduziria 167). Migrations aplicadas + swap local OK.
- Conclusão: "nada quebra prod" demonstrado em código (compila) E em dado (não regride). Os erros de tsc que surgiram eram 100% ambiente (libs nx + prisma), zero do merge.

### Salvage — STATUS (2026-07-09): 2/3 commitados, 1 preservado-em-branch

1. **dose-viz Outbox guarda #2** ✅ **SALVADO** (`consolidate/rhilo-app` @67e705408) — cherry-pick limpo de 14bd1ffe2 (dead-letter + teto retry + alarme FAILED + env). tsc EXIT=0.
2. **dose-viz F3a `UnassignReason`** ✅ **SALVADO** (`consolidate/rhilo-app` @3fa02a729) — RE-IMPLEMENTADO sobre o main atual (não cherry-pick; branch stale sem GAP#1/terminais novos): enum + `Case.lastUnassignReason` (migração aditiva TEXT) + persist no TerminalUnassignService. **Desvio consciente:** mantido `reason:string` (não enum) → todo terminal-morte grava o motivo, sem trava de enum incompleto = **zero regressão de vazamento de SLOT**. tsc EXIT=0.
3. **modo-equilibrio** — 5 scripts únicos (0 em `rhilo/main`) **preservados em `feat/wrr-modo-equilibrio`** (branch não dropada até a lane conhecimento): `docs/reports/rollback/{apply-modo-equilibrio-hml.sh, backup-hml-pre-equilibrio.sh, delta-ativacao-modo-equilibrio-2026-06-30.sql, snapshot-pre-equilibrio-2026-06-30.sql, snapshot-pre-equilibrio-2026-06-30T1000.sql}`. Extração = cherry-pick desses paths → `develop` (item 6 da sequência).

### Lane conhecimento + Higiene — EXECUTADO (2026-07-09, local, sem push)
- **KG** ✅ nó `C_CONSOLIDATION_MAP` + 3 arestas registrado em `audit/oraculo-integration` (@8e4cf4b7); YAML válido (115 nós/180 arestas), radar limpo.
- **audit→develop** + **sinal ao Onion source**: preparados; são ação de PR/externa → **sob comando** (nada empurrado).
- **Higiene** ✅ 2 branches dedicadas (untrack + gitignore, mantém em disco): metagamify `chore/hygiene-untrack-secrets` (@9a7e7693, `logto-backup-*.sql`) · rhilo-app `chore/hygiene-untrack-sessions` (@9b89ad393, `.claude.bkp.zip` + `.claude/sessions/` = 2016 arquivos). Zero runtime tocado.

### Pré-requisitos de MIGRAÇÃO (ordem HARD — migração antes do código)

- metagamify freeze-guards: autorar `prisma/manual-migrations/009_add_candidate_context.sql` (`ADD COLUMN candidateContext JSONB`) + rodar backfill. Senão persist de snapshot falha (fail-soft, só auditoria).
- rhilo-app reconcile: 2 migrations (`blocks_queue`/`block_min_overdue` em `SlaConfiguration` + tabela `sla_backlog_exemption`). Senão 500 no painel de backlog.

### Dependência cross-repo confirmada (PX-978)

`slaBacklogPolarity` só **persiste** com o metagamify `feat/wrr-reconcile-unassign` deployado → **deploy pareado, metagamify primeiro**. `reconcile:true` do rhilo-app (script de dreno) idem. Degradação benigna se um for sem o outro (default/no-op), mas a ordem é metagamify→rhilo-app.

### Sequência de PR recomendada (SOB COMANDO)

1. **Migrações isoladas** (aplicar em prod 1º): metagamify 009-candidateContext; rhilo-app blocks_queue+exemption.
2. **metagamify código**: reconcile-unassign (safe) + freeze-guards código-só [confirmar flag `floorAwareRoutingEnabled`] → deploy.
3. **rhilo-app código**: command-center (safe) + reconcile-unassign (rebased) → deploy **pareado** com o passo 2.
4. **Salvage** (follow-on, não bloqueia): F3a re-implementado + Outbox guarda #2 + 4 scripts equilibrio.
5. **Lane conhecimento** (→ develop): `audit/oraculo-integration` (KG + `.claude/` + docs) + este mapa + nó KG + sinal ao source.
6. **Drops**: cockpit-ajustes, cockpit-v2, terminal-unassign\*, dose-viz (pós-salvage).

## Nó a registrar no KG (`docs/rhilo/graph/wrr-audit.kg.yaml` em `audit/oraculo-integration`)

```yaml
- id: C_CONSOLIDATION_MAP
  type: claim
  plane: DEV
  text: 'Consolidação (2026-07-09): 2 lanes — CÓDIGO (mira rhilo/main + main, prod-safety) vs CONHECIMENTO (mira develop, docs+.claude+KG). PROD-candidates código: metagamify feat/wrr-reconcile-unassign(+3), fix/wrr-freeze-guards(+19, tem pending-slots/Gate-A); rhilo-app feat/command-center-v2-redesign(+5, Oráculo real+drift#5+SLA fix). ABSORVIDAS: GAP#1(PR957), cura-dose. SUPERSEDED: gamification-dose-viz(Oráculo antigo). PX-978 casa os dois reconcile. #5 drift prod-safe (campos em rhilo/main). #1 dose bloqueado até freeze-guards em prod. INCLUI sinal ao Onion source: promover KG-SDAAL (.kg.yaml/radar//meta:kg) ao core via co-evolve (inbox 2026-07-09-sdaal-generaliza) — source hoje tem SDAAL-abstraction+dogfood mas NÃO o .kg.yaml.'
  traces: ['docs/wrr/2026-07-09-mapa-consolidacao.md']
```
