# ⚠️ AVISO — Investigação de "o que trava o MetaGamify" + como sondar (acesso limitado)

> **Leia isto primeiro** se for diagnosticar lentidão / 503 / "travou tudo" em produção, ou
> antes de ligar a dose (`measured_conversion`). Resume o que foi investigado em 2026-06-24, o que
> dá e o que **não** dá para acessar hoje, e como inspecionar com segurança (read-only). Tudo aqui é
> **diagnóstico/doutrina** — nenhuma mudança de código de runtime foi feita.

---

## TL;DR

1. **Há 4 laços de realimentação sem guarda** rodando em prod (mesma lição de teoria de controle:
   alto ganho/amplificação sem amortecimento). Ranking de quem mais provavelmente "trava tudo":
   **BullMQ in-process > outbox/windup > snapshot TOAST > matemática da dose.** Detalhe e evidência
   (arquivo:linha) em [`freeze-triage-4-lacos.md`](./freeze-triage-4-lacos.md) e na seção
   "Acoplamento operacional" de [`dose-base-pesquisa-tecnicas-controle-vazao.md`](./dose-base-pesquisa-tecnicas-controle-vazao.md).
2. **Os alertas NÃO travam** (on-read, cache 60s, query-only) e **não existe CRON de burst-control**
   (era script pessoal já parado em 18/jun). Essas duas suspeitas foram **descartadas**.
3. **Não dá para acessar o Redis/BullMQ de prod diretamente** com o IAM atual. Mas dá para **sondar
   o estado das filas pelo Postgres** (read-only) — ver [`scripts/freeze-probe.sql`](../../scripts/freeze-probe.sql).

---

## Topologia de produção (verificada via AWS, read-only)

- **Runtime:** ECS Fargate, cluster `rhillo-hml` (serviços `metagamify-api-service` / `metagamify-admin-service`).
  Deploy via `.github/workflows/deploy-api-ecs.yml` no push para `rhilo/main`. **Não é VPS** — só
  existem 2 EC2 na conta: `rhillo-hml-bastion` e `grafana-obs`.
- **Redis:** **ElastiCache**. O `REDIS_URL` vem do **Secrets Manager** (`metagamify/hml/redis-url-CkD2eE:url`),
  não está em nenhum `.env`. O motor de eventos BullMQ roda **no mesmo processo da API**.
- **Banco:** RDS `rhillo-hml-postgres` (bancos `metagamify_hml` e `rhillo_hml`), alcançável pelo túnel SSM.

## Realidade de acesso (IAM `marcio-metagamify`) — testado

| Consigo                                                     | Não consigo (AccessDenied)                                                         |
| ----------------------------------------------------------- | ---------------------------------------------------------------------------------- |
| EC2 describe, **SSM start-session**, RDS describe, STS      | `elasticache:Describe*`                                                            |
| → ou seja, **o túnel do Postgres** (`./.vpn/connect-db.sh`) | `ecs:ListClusters` / `DescribeServices` / Exec                                     |
|                                                             | `cloudwatch:ListMetrics` / `GetMetric*`                                            |
|                                                             | `logs:DescribeLogGroups` (sem logs do ECS)                                         |
|                                                             | `secretsmanager:GetSecretValue` no secret do Redis (bloqueado: credencial de prod) |

**Consequência:** sem o endpoint do Redis (trancado no Secrets Manager) e sem ECS Exec, **não há como
conectar no Redis de prod** com essas credenciais. CloudWatch/Logs também fechados. O Grafana
(`grafana-obs`) é da RHILO (OTEL/ADR-052); o MetaGamify **não emite OTEL** → provavelmente não tem as
filas dele.

---

## Como sondar HOJE (sem Redis, sem AWS extra) — `scripts/freeze-probe.sql`

O estado das filas tem **proxies no Postgres**, alcançáveis pelo túnel que você já usa:

```bash
./.vpn/connect-db.sh                                  # abre localhost:55432 -> RDS
psql -h localhost -p 55432 -U <user> -f scripts/freeze-probe.sql
```

Cobre:

- **Laço nº1 (event-queue):** `AnalyticsEvent.processedAt IS NULL` antigo = fila BullMQ entupida.
- **Laço nº2 (outbox/windup):** as 3 tabelas de outbox por status + retry-no-teto + últimos erros
  (inclui o sync MetaGamify — o _blind-spot_ do `createParticipant`).
- **Laço nº3 (snapshot):** tamanho da `WRRSelectionDecision` (inc. TOAST) + volume/dia.

**Segurança:** cada conexão entra em `default_transaction_read_only = on` → qualquer write **aborta**.
**Limite:** o Postgres mostra event-queue e outbox (os grandes), **não** reward/notification/email
(esses vivem só no Redis).

### Se precisar mesmo do Redis (regras pra NÃO ferrar tudo)

- **NUNCA** instanciar um `Worker` BullMQ apontando pro Redis de prod (consome jobs reais). Só `Queue`
  com leitura (`getJobCounts`).
- **NUNCA** `KEYS *` (bloqueia o Redis → derruba prod). Use `SCAN`.
- **NUNCA** `FLUSH*/DEL`, `queue.clean()/obliterate()/drain()`, `job.retry()/remove()`.
- Bull Board exige redeploy (`ENABLE_BULL_BOARD=true`) e a UI tem botões que mutam.

---

## Para destravar acesso direto (pedidos à DevOps/RHILO)

1. **Endpoint do ElastiCache + liberar o SG pro bastion** → o SSM-tunnel read-only passa a funcionar
   (igual ao RDS); aí um inspector `getJobCounts` resolve.
2. **OU** policy IAM mínima: `secretsmanager:GetSecretValue` no secret do Redis + `elasticache:Describe*`
   - `ecs:ExecuteCommand`.
3. **OU** habilitar ECS Exec na task (mudança de infra) para `redis-cli`/inspector read-only de dentro.

## Guardas como PRÉ-CONDIÇÕES do rollout da dose

Ligar `measured_conversion` sem estas = ligar 4 integradores sem anti-windup ao mesmo tempo:
clamp em `deriveDoseMaxByLevel` · ligar `WRR_DECISION_CONTEXT_RETENTION_DAYS` · cap de profundidade +
dead-letter no BullMQ · teto/dead-letter no outbox. Implementação = Frente 2 (código).

---

_Investigação: 4 explorações read-only do código (rhilo-metagamify + rhilo-app) + testes AWS read-only.
Data: 2026-06-24. Sem mudança de runtime — Spec-as-Code (doutrina precede implementação)._
