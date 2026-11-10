# Supervisão de agentes e de trabalhadores: como o mercado resolve (2026-11-10)

Para a "batuta": um orquestrador mecânico de sessões de agente de código (Claude Code e Codex) numa VPS
compartilhada por várias sessões e repositórios.

Método: toda página citada foi baixada por `curl` em 2026-11-10 e o trecho foi conferido no texto da página.
As cópias estão em `/tmp/claude-1000/supervision/pages/`. O que não abri está marcado **não verificado**.
"Externo" quer dizer que o mecanismo depende de um serviço fora da VPS.

## 0. O que a casa já sabe (corpus primeiro)

`kg-corpus-grep.sh` sobre 72 grafos, em 2026-11-10:

- `heartbeat`, `watchdog`, `fencing` e `orquestração`: **0 nós**. É lacuna: o corpus não tem nada sobre
  liveness nem sobre fencing.
- `lease`: 24 nós. Os que importam aqui são:
  - `session-orchestration-market-2026-11/E_SOM_RESEARCH_E2_E4` (confirmed): "o lease de mercado é TTL com
    renovação e token monotônico aplicado pelo recurso; a CPU não rejeita token velho, então quem cumpre é o SO,
    por cgroup v2 cpu.weight e cpu.max (CPUWeight e CPUQuota do systemd)."
  - `C_SOM_E2_LEASE_PARTIAL` (open): o padrão cobre titular, TTL e renovação, mais o cumprimento pelo SO, mas não
    cobre a janela exclusiva. Medido sem root: o cgroup já divide a CPU entre as sessões.
  - `claude-code-channels-2026-11/I_CH_AGENT_MAIL_COORDINATION_AND_DELIVERY` (open): o MCP Agent Mail oferece
    "lease consultiva" e cursor durável.
- `ocioso`: 1 nó, `vertical-personas-2026-10/E_VP_FAMILY_FAILS`. O que falha é o que vive fora do grafo: a
  sessão do core reiniciou e perdeu o contexto, e o grafo de coordenação fica atrás do vivo.
- `idle`: 1 nó, mas fora do tema (IMAP IDLE).
- **Pergunta do core.** O comando do brief (`docs/onion/graph/*.kg.yaml`) voltou com rc 1. O nó
  `Q_SO_PADROES_DE_MERCADO` está em
  `docs/evolution/research/session-orchestration-2026-11/session-orchestration-2026-11.kg.yaml:221` (origin/main
  do core), com status open, owner core e verificado contra "nenhuma busca feita nesta rodada". Ele pergunta
  quais padrões de mercado cobrem papéis entre agentes, reserva de recurso compartilhado e passagem de tarefa
  com aceite. A narrativa diz: market-standards-first, e cunhagem só onde o mercado não tiver.

## 1. Agente ou sessão ociosa e trabalho pela metade

| Mecanismo | O que faz (fato, da fonte) | Fonte | Externo? | Quem adota |
|---|---|---|---|---|
| Activity Heartbeat + Heartbeat Timeout (Temporal) | O worker manda um "ping" que diz que a execução avança e que ele não caiu. O Heartbeat Timeout é "the maximum time between Activity Heartbeats". O heartbeat pode levar o progresso, que é usado na retentativa. Junto com Start-To-Close e Schedule-To-Close, mais a Retry Policy | docs.temporal.io/encyclopedia/detecting-activity-failures, seções "Activity Heartbeat" e "Heartbeat Timeout" | Sim: o Temporal Service (open source e auto-hospedável, ou Temporal Cloud) | Temporal (open source) |
| Visibility timeout (SQS) | A mensagem entregue fica invisível. Se não for apagada antes do prazo, "becomes visible again" para outro consumidor. O padrão é 30 s e o teto é 12 h. `ChangeMessageVisibility` estende o prazo | docs.aws.amazon.com/.../sqs-visibility-timeout.html, "Setting and adjusting the visibility timeout" | Sim (AWS) | AWS |
| Visibility timeout + `acks_late` (Celery) | No Redis, tarefa sem ack dentro do visibility timeout "will be redelivered to another worker". Há um efeito colateral: ETA maior que o timeout faz a tarefa executar "again, and again in a loop". `acks_late` só é seguro com tarefa idempotente, e há `task_reject_on_worker_lost` | docs.celeryq.dev/.../redis.html, "Caveats > Visibility timeout"; docs.celeryq.dev/.../tasks.html (acks_late) | Broker (Redis ou RabbitMQ), que pode ser local | Celery |
| Task Instance Heartbeat Timeout (Airflow, antes "zombie tasks") | Tarefa "stuck in a running state despite their associated jobs being inactive". O Airflow as acha periodicamente e as marca como failed ou retry. Configurável por `TASK_INSTANCE_HEARTBEAT_SEC` e `..._TIMEOUT` | airflow.apache.org/.../core-concepts/tasks.html, "Task Instance Heartbeat Timeout" | Não (scheduler e banco próprios) | Apache Airflow |
| Liveness probe (Kubernetes) | "Liveness probes determine when to restart a container", por exemplo num deadlock em que o processo roda mas não avança. Passada a tolerância de falhas, o kubelet reinicia o contêiner | kubernetes.io/.../liveness-readiness-startup-probes/, "Liveness probe" | Não (kubelet local) | Kubernetes |
| `WatchdogSec=` + `sd_notify("WATCHDOG=1")` (systemd) | O serviço manda keep-alive periódico. Se o intervalo passar do configurado, o serviço vai para failed e leva SIGABRT. Com `Restart=on-watchdog` ele reinicia. Há também `RuntimeMaxSec=` como teto de duração | freedesktop.org/.../systemd.service.html, `WatchdogSec=` e `RuntimeMaxSec=` | Não (PID 1 local) | systemd (distros Linux) |
| Lease com TTL e keepAlive (etcd) | "Leases are a mechanism for detecting client liveness". A lease expira sem keepAlive no TTL, e as chaves ligadas a ela são apagadas, gerando evento de delete | etcd.io/docs/v3.5/learning/api/, "Lease API" | Sim (cluster etcd, que pode ser local) | etcd, Kubernetes |
| Lease de nó (Kubernetes) | Todo heartbeat do kubelet é um update no objeto Lease (`spec.renewTime`), e o control plane usa esse campo para julgar o nó | kubernetes.io/docs/concepts/architecture/leases/, "Node heartbeats" | Não, dentro do cluster | Kubernetes |
| Dead man's switch (Healthchecks.io) | O serviço "keeps silent as long as pings arrive on time" e alerta quando o ping atrasa além do Grace Time | healthchecks.io/docs/ (página de doc do fornecedor) | Sim no SaaS. A página tem link "Self-hosted"; a licença não foi verificada | Healthchecks.io |
| Checkpointer + pending writes (LangGraph) | Salva o estado a cada super-step, por `thread_id`. Se um nó falha, as escritas dos nós que terminaram ficam guardadas e "you don't re-run the successful nodes" ao retomar | docs.langchain.com/oss/python/langgraph/checkpointers.md, "Fault-tolerance" e "Pending writes" | Não (Saver em memória, SQLite ou Postgres) | LangGraph (LangChain) |
| Claude Code: hook `Notification` com `idle_prompt` | Dispara "about 60 seconds after Claude finishes responding", só se o humano não digitou e nenhum agente de fundo roda. Não dispara enquanto espera o limite de uso. Outros tipos: `permission_prompt`, `agent_needs_input`, `agent_completed` | code.claude.com/docs/en/hooks, "Notification" | Não | Anthropic (Claude Code) |
| Claude Code: hook `Stop` | Recebe `background_tasks` e `session_crons`, que distinguem "session is done" de "paused waiting for background work". `decision: "block"` impede a parada. Há um teto de 8 continuações seguidas | code.claude.com/docs/en/hooks, "Stop input" e "Stop decision control" | Não | Claude Code |
| Claude Code: `TeammateIdle` e `SubagentStop` | `TeammateIdle` dispara quando um colega do agent team vai ficar ocioso. Exit 2 o mantém trabalhando, e `{"continue": false}` o encerra | code.claude.com/docs/en/hooks, "TeammateIdle decision control" | Não | Claude Code (agent teams experimentais, `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`) |
| Claude Code: status de sessão e check-in | `CLAUDE_CODE_BG_TASKS_REPORT_RUNNING`: a sessão não interativa reporta "running" ao host enquanto houver trabalho de fundo, e `0` faz reportar idle a cada fim de turno. `CLAUDE_CODE_WORKER_CHECKIN_SCHEDULE` (ex.: `600,1800,3600`) lembra Claude de checar subagentes de fundo | code.claude.com/docs/en/env-vars | Não | Claude Code |
| Codex: `notify` e hooks | `notify` chama um programa externo nos eventos suportados, hoje "only agent-turn-complete". Há hooks de ciclo de vida, entre eles `SessionStart`, `PreToolUse`, `PostToolUse`, `UserPromptSubmit`, `SubagentStop` e `Stop` | developers.openai.com/codex/config-advanced ("notify"); developers.openai.com/codex/hooks | Não | OpenAI (Codex CLI) |

Padrão comum (fato, pela soma das fontes): **quem trabalha prova vida, e quem supervisiona julga pelo prazo.**
Vencido o prazo, o trabalho volta à fila (SQS, Celery, Temporal), é marcado como failed ou retry (Airflow) ou o
processo reinicia (k8s, systemd). A retomada sem refazer o que terminou exige um checkpoint por passo (LangGraph
pending writes, progresso no heartbeat do Temporal) e efeito colateral idempotente (Celery `acks_late`, regra de
interrupt do LangGraph).

## 2. Dono único por pergunta ao humano

| Mecanismo | O que faz (fato) | Fonte | Externo? | Quem adota |
|---|---|---|---|---|
| `interrupt()` + `Command(resume=...)` (LangGraph) | Pausa o grafo e expõe um payload ao chamador. A retomada usa o mesmo `thread_id` ("your persistent cursor"). Na retomada, "the runtime restarts the entire node from the beginning", e por isso efeito colateral antes do interrupt "must be idempotent". Com vários interrupts, os resume values casam por posição | docs.langchain.com/oss/python/langgraph/interrupts.md, "Rules of interrupts" | Não | LangGraph |
| Signals e Updates (Temporal) | Signal: "asynchronous write requests", sem resposta. Update: "synchronous, tracked write requests", e o remetente espera completion ou erro. Há validador para rejeitar | docs.temporal.io/encyclopedia/workflow-message-passing | Temporal Service | Temporal |
| Unicidade de Workflow Id (Temporal) | "only one Workflow Execution with a given Workflow Id can be in an Open state at any given time". Reuse Policy e Conflict Policy controlam o duplicado | docs.temporal.io/workflow-execution/workflowid-runid | Temporal Service | Temporal |
| Escalation policy (PagerDuty) | Projetada "to notify a single target at a time until one individual acknowledges". O escalation timeout padrão é 30 min. O ack para o escalonamento mas não resolve, e se o incidente re-triggar a política volta. Ela se repete até 9 vezes, com round robin opcional | support.pagerduty.com/main/docs/escalation-policies | Sim (SaaS) | PagerDuty |
| `dedup_key` (PagerDuty Events API v2) | Eventos com o mesmo `dedup_key` aplicam-se ao alerta aberto. Depois de resolvido, um trigger novo cria outro alerta | developer.pagerduty.com/docs/events-api-v2/trigger-events/; support.pagerduty.com/main/docs/event-management | Sim | PagerDuty |
| Escalation e `alias` (Opsgenie) | Regras ordenadas de responders (usuário, time, on-call, próximo on-call e outros). "There can be at most one open alert with the same alias", e a repetição só incrementa o Count. O Repeat fica só nos planos Standard e Enterprise | support.atlassian.com/opsgenie/docs/how-do-escalations-work-in-opsgenie/; .../what-is-alert-de-duplication/ | Sim (SaaS) | Atlassian. A doc tem a seção "Migrate Opsgenie to Jira Service Management"; a data de fim de venda e de suporte **não foi verificada** |
| Atribuição em ticket (GitHub) | Issue e PR aceitam "up to 10 assignees". O ticket não força dono único | docs.github.com/.../assigning-issues-and-pull-requests-to-other-github-users | Sim | GitHub |

Quando o dono some, o mercado faz assim (fato): no PagerDuty, o timeout de ack escala para a próxima regra e
repete a política. No Temporal e no LangGraph a pergunta fica pendente indefinidamente no estado durável. Nenhum
dos dois tem escalonamento embutido para o humano: quem escala é um timer ou uma regra escrita pelo autor. No
LangGraph não encontrei timeout de interrupt na página lida, o que pede uma busca mais funda antes de afirmar
ausência. A deduplicação é sempre uma **chave de identidade escolhida pelo produtor** (`dedup_key`, `alias`,
Workflow Id) com "no máximo um aberto".

## 3. Trava de carga entre agentes numa máquina compartilhada

| Mecanismo | O que faz (fato) | Fonte | Externo? | Quem adota |
|---|---|---|---|---|
| Fencing token (Kleppmann) | O lease pode expirar durante uma pausa (GC, rede) e o cliente segue achando que tem a trava. A correção é "include a fencing token with every write request": um número que cresce a cada aquisição, e o recurso rejeita o token velho. Ele separa trava por **eficiência** de trava por **correção**, e para eficiência basta uma instância simples | martin.kleppmann.com/2016/02/08/how-to-do-distributed-locking.html (artigo técnico com autor) | — | Prática citada pela própria doc do Redis |
| Redlock (Redis) | Maioria de N instâncias, com validity time = TTL menos o tempo gasto. A exclusão só vale se o cliente terminar dentro desse prazo. A seção "Analysis of Redlock" aponta a análise de Kleppmann e um contraponto | redis.io/docs/latest/develop/clients/patterns/distributed-locks/ (doc do fornecedor) | Redis | Redis. O contraponto (antirez) **não foi aberto, não verificado** |
| `flock(1)` e `flock(2)` | Trava **advisory** num fd aberto, com `-n` (não bloqueia), `-w` (timeout) e `-E` (código de conflito). A trava é liberada por `LOCK_UN` ou quando todos os fds duplicados fecham, então a morte do processo a libera sem trava velha | man7.org/linux/man-pages/man1/flock.1.html; .../man2/flock.2.html | Não (kernel) | util-linux, Linux |
| `CPUWeight=`, `CPUQuota=`, `MemoryHigh=`, `MemoryMax=`, `TasksMax=` (systemd) | `CPUQuota` é teto percentual e controla o `cpu.max`. `MemoryMax` é o limite absoluto, com OOM killer dentro da unit, e a doc recomenda `MemoryHigh=` como controle principal | freedesktop.org/.../systemd.resource-control.html | Não | systemd |
| `systemd-run --scope`, `--slice`, `-p` | Cria unit transitória (`.scope`) para um processo já em curso de linha de comando, numa slice, com as propriedades acima | freedesktop.org/.../systemd-run.html | Não | systemd |
| cgroup v2: `cpu.weight`, `cpu.max`, `memory.high`, `memory.max`, PSI (`cpu.pressure`, `memory.pressure`) | Acima de `memory.high` há throttle e reclaim, e isso "never invokes the OOM killer". `memory.max` é o limite duro. PSI mede pressão por cgroup | docs.kernel.org/admin-guide/cgroup-v2.html | Não | Kernel Linux |
| Slot suppliers (Temporal Worker) | Fixed Size: slots até um limite pré-calculado para "without oversubscribing or hitting out-of-memory". Resource-Based: alvo de CPU e de memória, que respeita o limite do contêiner | docs.temporal.io/develop/worker-performance, "Slot suppliers" | Temporal | Temporal |
| `--concurrency`, prefetch, `max-tasks-per-child` (Celery) | Número fixo de processos por worker, autoscale e reciclagem de processo | docs.celeryq.dev/en/stable/userguide/workers.html, "Concurrency", "Autoscaling" | Broker | Celery |
| `--load`, `--memfree` (GNU parallel) | "Do not start new jobs ... unless the number of running processes ... is less than max-load". `--memfree` define a memória livre mínima para iniciar outro job | gnu.org/software/parallel/parallel.html, `--load`, `--memfree` | Não | GNU |
| Claude Code: limite de subagentes concorrentes | Com 20 subagentes rodando **por sessão**, o próximo spawn falha com `Concurrent subagent limit reached`. `CLAUDE_CODE_MAX_CONCURRENT_SUBAGENTS` ajusta. Há também limite de profundidade (3) | code.claude.com/docs/en/sub-agents.md, "Concurrent subagent limit"; env-vars | Não | Claude Code |

Fato que importa: os limites de agente que achei são **por sessão** (Claude Code) ou **por worker** (Temporal,
Celery). Nenhuma fonte lida oferece um limite **entre sessões na mesma máquina**. Isso cabe ao SO (cgroup,
systemd slice) ou a um semáforo local (`flock`). Não busquei os orquestradores de agente de terceiros (OpenHands,
Agent Mail e outros) nesta rodada: **lacuna**.

## 4. O que serve à batuta

### FATO (com fonte acima)

1. Ociosidade: o mercado separa **liveness** (processo vivo: watchdog, probe, keepAlive) de **progresso**
   (heartbeat com progresso no Temporal, deadlock na liveness probe). Um prazo sem prova de vida devolve o
   trabalho (SQS, Celery, Temporal) ou o marca failed ou retry (Airflow).
2. O Claude Code já expõe, sem serviço externo, os sinais de que a batuta precisa: `Notification/idle_prompt`
   (cerca de 60 s, só sem agente de fundo), `Stop` com `background_tasks` e `session_crons` (feito ou pausado),
   `TeammateIdle`, `SubagentStop` e o status running ou idle que a sessão não interativa reporta ao host. O
   Codex expõe `notify` (agent-turn-complete) e hook `Stop`.
3. Retomar sem refazer exige checkpoint por passo mais idempotência do efeito anterior (LangGraph, Celery).
4. Pergunta ao humano: o padrão é **uma chave de identidade com no máximo um aberto** (dedup_key, alias, Workflow
   Id), **um alvo por vez** e **timeout de ack que escala** (PagerDuty, padrão de 30 min, até 9 repetições). O
   ack não é resolução.
5. Trava: `flock` é local, kernel e liberada na morte do processo. O lease com TTL precisa de fencing token
   checado pelo recurso para valer como correção, e a CPU não checa token (já no corpus, `E_SOM_RESEARCH_E2_E4`).
   Quem cumpre o teto é o cgroup v2 ou o systemd (`CPUQuota`, `MemoryHigh`, `MemoryMax`, `TasksMax`). A admissão
   por carga existe pronta (`parallel --load` e `--memfree`, Temporal resource-based slots, PSI).

### OPINIÃO (minha, a pesar)

- A batuta pode ser **só peças locais de padrão de mercado**, sem Temporal nem PagerDuty. A prova de vida pelos
  hooks do Claude Code e do Codex escreveria um carimbo de tempo por sessão. O juízo do prazo seria um timer do
  systemd com watchdog no próprio supervisor. A trava seria `flock`. O teto seria uma slice systemd por sessão.
  A admissão leria PSI ou load antes de iniciar o trabalho. Isso respeita `no-external-service-dependencies`.
- Para a pergunta ao humano, copiar a forma PagerDuty e Opsgenie: chave = repo + id da pergunta, no máximo uma
  aberta, um dono, ack com prazo e escalonamento para o próximo da lista (por exemplo, a sessão do core e depois
  o Maestro). Ack ≠ resolvido, e a pergunta que volta reabre.
- Usar a separação de Kleppmann: a trava de carga na VPS é de **eficiência**, não de correção. Por isso `flock`
  mais o cgroup bastam, e o fencing token só entra se a trava proteger escrita em recurso compartilhado (o git do
  mesmo repo, por exemplo).
- `idle_prompt` sozinho não serve para "trabalho pela metade": ele não dispara com agente de fundo vivo. A batuta
  deve cruzar `Stop.background_tasks` com a idade do último heartbeat próprio.
- Lacunas antes de selar: orquestradores de agente de terceiros, timeout de interrupt no LangGraph, contraponto
  de antirez e a data de fim de suporte do Opsgenie.

## URLs (todas abertas em 2026-11-10, salvo marcação)

- https://docs.temporal.io/encyclopedia/detecting-activity-failures
- https://docs.temporal.io/encyclopedia/workflow-message-passing
- https://docs.temporal.io/workflow-execution/workflowid-runid
- https://docs.temporal.io/develop/worker-performance
- https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-visibility-timeout.html
- https://docs.celeryq.dev/en/stable/getting-started/backends-and-brokers/redis.html
- https://docs.celeryq.dev/en/stable/userguide/tasks.html
- https://docs.celeryq.dev/en/stable/userguide/workers.html
- https://airflow.apache.org/docs/apache-airflow/stable/core-concepts/tasks.html
- https://kubernetes.io/docs/concepts/configuration/liveness-readiness-startup-probes/
- https://kubernetes.io/docs/concepts/architecture/leases/
- https://www.freedesktop.org/software/systemd/man/latest/systemd.service.html
- https://www.freedesktop.org/software/systemd/man/latest/systemd.resource-control.html
- https://www.freedesktop.org/software/systemd/man/latest/systemd-run.html
- https://docs.kernel.org/admin-guide/cgroup-v2.html
- https://etcd.io/docs/v3.5/learning/api/
- https://healthchecks.io/docs/ (doc do fornecedor)
- https://docs.langchain.com/oss/python/langgraph/persistence.md
- https://docs.langchain.com/oss/python/langgraph/checkpointers.md
- https://docs.langchain.com/oss/python/langgraph/interrupts.md
- https://code.claude.com/docs/en/hooks
- https://code.claude.com/docs/en/env-vars.md
- https://code.claude.com/docs/en/sub-agents.md
- https://developers.openai.com/codex/config-advanced
- https://developers.openai.com/codex/hooks
- https://support.pagerduty.com/main/docs/escalation-policies
- https://developer.pagerduty.com/docs/events-api-v2/trigger-events/
- https://support.pagerduty.com/main/docs/event-management
- https://support.atlassian.com/opsgenie/docs/how-do-escalations-work-in-opsgenie/
- https://support.atlassian.com/opsgenie/docs/what-is-alert-de-duplication/
- https://docs.github.com/en/issues/tracking-your-work-with-issues/using-issues/assigning-issues-and-pull-requests-to-other-github-users
- https://martin.kleppmann.com/2016/02/08/how-to-do-distributed-locking.html (artigo técnico com autor)
- https://redis.io/docs/latest/develop/clients/patterns/distributed-locks/ (doc do fornecedor)
- https://man7.org/linux/man-pages/man1/flock.1.html
- https://man7.org/linux/man-pages/man2/flock.2.html
- https://www.gnu.org/software/parallel/parallel.html (a URL `man.html` deu 403; usei esta)
- Não verificado: o contraponto de antirez ao Kleppmann (linkado pela doc do Redis), a data de fim de venda e de
  suporte do Opsgenie, a licença do Healthchecks self-hosted e os orquestradores de agente de terceiros.
