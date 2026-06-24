# Triagem — "o que travou tudo": 4 laços sem guarda (ranqueado)

> **Propósito.** Diagnóstico operacional ranqueado das hipóteses de "o que trava/derruba o
> MetaGamify sob carga" (lentidão de API, 503, distribuição distorcida). Insumo para decidir
> **onde olhar primeiro** e **a guarda mais barata** de cada laço. Companheiro da doutrina em
> [`dose-base-pesquisa-tecnicas-controle-vazao.md`](./dose-base-pesquisa-tecnicas-controle-vazao.md)
> (seção "Acoplamento operacional").
>
> **Base.** 4 explorações read-only do código (rhilo-metagamify + rhilo-app) + `grep @Cron`.
> **Data:** 2026-06-24. **Ambiente:** prod = branch `rhilo/main`, container ECS ~0.5vCPU/1GB,
> banco `metagamify_hml` (que é prod-RHILO e dev/homolog ao mesmo tempo).

---

## Antes de tudo — o que NÃO é o culpado

Duas suspeitas comuns que a investigação **descartou**:

- **Feed de alertas** (`wrr/alerts/alerts.aggregator.ts`, 5 triggers): **on-read, cache 60s,
  query-only**. Sem fila/CRON/listener. Não trava. Risco de "alert storm" ≈ 0.
- **CRON de burst-control reescrevendo overrides**: **não existe**. Overrides são 100% manuais.
  `grep @Cron` no rhilo-app = só outbox (30s/2min/5min/3AM) + `fix-orphan-actions` (5min, ações AT).
  Zero `burst`. _(Corrige anotação anterior que culpava um CRON automático pela pilha de overrides.)_

---

## Ranking das hipóteses

### 🥇 #1 — Motor de eventos BullMQ in-process (mais provável)

**Por que é o nº1:** é o único laço que (a) roda **no mesmo processo Node da API**, no container de
0.5vCPU/1GB; (b) tem **concorrência 10** em `event-processing` e `notification`; (c) tem **cascata
recursiva sem cap de profundidade**; (d) **não tem dead-letter**; e (e) **não tem visibilidade** em
prod (Bull Board off). É a combinação clássica de _amplificação ilimitada + contenção de recurso sem
isolamento_.

**Evidência:**

- 7 filas, workers sobem incondicionalmente no boot — `apps/api/src/main.ts:312-335` (sem flag de kill).
- Config das filas (concorrência 2–10, 3 retries exp 2s, sem DLQ) — `apps/api/src/lib/bullmq.ts:44-186`.
- Cascata `ELEMENT_EARNED` que re-entra na fila **sem limite de profundidade** —
  `apps/api/src/services/element-assigner.service.ts:153` (recompensas têm cap de 3 níveis; **eventos
  não têm cap nenhum**).
- Pipeline de evento → completion → triggers → feedback → N notificações —
  `apps/api/src/processors/event.processor.ts:28-198`. Estimativa: 1 ação de usuário pode gerar **6–9
  jobs**.
- `WRRComparator` (consistência metadata × workload) **definido mas nunca ligado no boot** —
  `apps/api/src/wrr/comparator/comparator.worker.ts:105` → divergência de contadores silenciosa.

**Mecanismo do "trava tudo":** 10 workers processando eventos pesados (queries Prisma + render de
template + Redis) saturam CPU e o pool de conexões; requests de `getNextParticipant`/admin enfileiram
atrás → latência → 503. Sob rajada (manhã), a cascata amplifica.

**Guarda mais barata:** flag/env para **desligar ou reduzir concorrência** dos workers (kill-switch);
**cap de profundidade** na cascata de eventos; depois, mover workers para fora do processo da API.
**Princípio:** crédito/backpressure (Kung) — isolar o plano de efeito-colateral do plano de servir.

---

### 🥈 #2 — Sync / Outbox windup

**Por que aqui:** acumula **sem teto** e roda em loop curto; casa com um blind-spot já conhecido. Não
derruba a API sozinho, mas degrada e mascara falhas.

**Evidência:**

- `rhilo-app .../shared/outbox/outbox.processor.ts`: `@Cron(EVERY_30_SECONDS)` processa pendentes;
  eventos **FAILED "kept indefinitely"**, alerta só se >10 (`logMetrics` `@Cron(EVERY_5_MINUTES)`);
  ainda há `@Cron('*/2 * * * *')`.
- Fila `METAGAMIFY_SYNC` (5 retries exponenciais) — casa com o sync blind-spot
  (`mg-create-participant` falha 5× e é descartado sem alarme → escritório ativo sem Participant).

**Mecanismo:** retry sem dead-letter eficaz = **windup** (o "integrador" satura de jobs FAILED). Sob
falha persistente do MG, acumula e re-tenta, competindo por recurso.

**Guarda mais barata:** **dead-letter + teto** de retry e drenagem dos FAILED; alarme quando FAILED
cresce. **Princípio:** AIMD / anti-windup.

---

### 🥉 #3 — Snapshot TOAST (estado sem poda)

**Por que aqui:** causa documentada do 503 de 2026-06-23, mas é **carga sobre fragilidade
pré-existente**, não gatilho autônomo — e a machinery de poda **já existe**, só está desligada.

**Evidência:**

- `WRRSelectionDecision`: 1 row por `getNext` (~947/dia), `candidateContext` ~90KB (**94% do peso**) —
  `prisma/schema.prisma` (modelo) + escrita fire-and-forget em
  `apps/api/src/services/wrr-distribution.service.ts:783,2137-2147`.
- Retenção §R1 (payload mínimo + top-N) / §R2 (janela) / §R3 (anula, não deleta) **implementada**
  (commit be8a886) mas **DESLIGADA** por padrão: `WRR_DECISION_CONTEXT_RETENTION_DAYS` ausente/≤0 = no-op
  (`apps/api/src/wrr/retention/prune-decision-context.worker.ts`).
- Endpoint de listagem puxando payloads grandes × `limit` alto → TOAST descomprimido (incidente
  14:14–14:33 de 2026-06-23).

**Mecanismo:** sem poda, `candidateContext` cresce; uma leitura ampla descomprime dezenas de MB de
TOAST no container pequeno → OOM/lentidão da camada admin.

**Guarda mais barata:** ligar `WRR_DECISION_CONTEXT_RETENTION_DAYS`; listagem sem `candidateContext`
(já é o default na rota de listagem); cache curto no RHILO. **Princípio:** estado mínimo (Kung).

---

### #4 — Matemática da dose (distorce mais do que "trava")

**Por que por último:** o efeito é **distribuição errada/explosão de teto**, não queda da API. Importa
para correção, não para o "travou tudo".

**Evidência:**

- `deriveDoseMaxByLevel = ceil(1/conv)` **sem clamp** — `apps/api/src/wrr/conversion/estimator.ts:174`
  (só o schema Zod garante ≥1).
- Conversão medida sem filtro numérico; `minCalls=10` é guarda de amostra, recálculo a cada `getNext`,
  cache 5 min — `apps/api/src/services/wrr-distribution.service.ts:673-699`.

**Mecanismo:** ganho `∝ 1/conv` sobre conversão baixa e ruidosa (ruído-Urano) → teto de dose explode
em níveis de baixa conversão (MESTRE/CHAMPION). Já observado no reframe da dose-first.

**Guarda mais barata:** **clamp** em `deriveDoseMaxByLevel`. **Princípio:** WF²Q (janela maior não tira
ruído) + PIE (clamp/ganho adaptativo/tolerar transiente).

---

## Síntese

| #   | Laço              | Trava API?      | Guarda existe?                      | Guarda mais barata                          |
| --- | ----------------- | --------------- | ----------------------------------- | ------------------------------------------- |
| 1   | BullMQ in-process | **Sim, direto** | Não (sem flag/cap/DLQ/visibilidade) | Kill-switch + cap de profundidade           |
| 2   | Sync/Outbox       | Degrada/mascara | Parcial (retry exp, sem DLQ)        | Dead-letter + teto + alarme                 |
| 3   | Snapshot TOAST    | Sob carga       | **Sim, mas desligada**              | Ligar `WRR_DECISION_CONTEXT_RETENTION_DAYS` |
| 4   | Dose math         | Não (distorce)  | Não (sem clamp)                     | Clamp em `deriveDoseMaxByLevel`             |

**Recomendação de ordem de ataque:** (1) visibilidade + kill-switch do BullMQ → (2) dead-letter do
outbox → (3) ligar retenção → (4) clamp da dose. As quatro são **pré-condições do rollout da
`measured_conversion`** (ligar o laço da dose num ambiente com três outros laços sem guarda amplifica o
risco). Implementação = Frente 2 (mudança de código); este doc é diagnóstico/doutrina.
