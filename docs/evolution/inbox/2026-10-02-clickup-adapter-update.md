---
title: "Atualizar a integração ClickUp: adapter, contrato do task manager, agente e padrões (patch pronto)"
date: 2026-10-02
type: signal
from: brain-granaai (adopted, pin 547e2e3edf3b)
severity: high
---

# Atualizar a integração ClickUp (patch pronto para o core aplicar)

## Por que

O adapter `.claude/utils/task-manager/adapters/clickup.md` não é tocado no core desde 2026-06-14 e tem bugs que
quebram em uso real. Uma rodada `onion-research` em fontes primárias (developer.clickup.com, 2026-10-02; grafo e
SYNTHESIS versionados no adotante em `docs/evolution/research/clickup-api-2026-10/`, commit `9cdcca263`)
confirmou dois deles e o mapeamento do contrato achou o resto.

**Bugs confirmados pela pesquisa:**
- o campo de markdown de Create/Update Task é `markdown_content`, não `markdown_description`;
- os nomes `mcp_ClickUp_clickup_*` são de outro servidor; o MCP oficial é `https://mcp.clickup.com/mcp`, tools `clickup_*`
  (`clickup_search_workspace` no lugar de `clickup_search`).

**Bugs do código do adapter** (achados no mapa do contrato; formatos ainda a conferir ao vivo): datas ISO cruas (API usa
ms), prioridade em string (API usa 1–4), `time_estimate` nunca enviado, `updateTask` sem tags e com `assignees` no
formato errado, `searchTasks` ignorando filtros, transporte lido da env direto (contra `types.md`), fallback MCP
prometido e não implementado, `CLICKUP_WORKSPACE_ID` exigido no código e descrito como auto-detectado.

**Lacunas de contrato:** comandos usam `customFields`, `checklists`, tags, `defaultProjectId` e prioridade `medium`,
que a interface não define; três versões diferentes de status de PR (`pr.md`, `git/flow.md`, `clickup-patterns.md`);
custom task ID do ClickUp classificado como Linear pelo detector.

## O que o patch faz (15 arquivos, +1200/−984; lint 0 HARD, 0 SOFT novo; docs:check OK)

- `types.md` 1.2.0 e `interface.md` 1.1.0: `status`, `points`, `customFields`, `taskType` na entrada; `checklists`,
  `customFields`, `points` na saída; `getTask(id, { includeSubtasks })`; **capabilities opcionais** (`tags`,
  `checklists`, `customFields`) com `TaskManagerNotSupportedError` e fallback que nunca aborta o fluxo.
- `adapters/clickup.md` 3.0.0 (892 linhas, padrão do zoho.md): banner medido × não-medido, 10 armadilhas, teste de
  conexão, rate limit por plano + `X-RateLimit-Remaining` + backoff em 429, MCP oficial, erro tipado, 16 membros.
- `detector.md`, `factory.md`: custom task ID com `TASK_MANAGER_PROVIDER=clickup`; fonte única de MCP (clickup,
  linear, jira, asana).
- `clickup-specialist.md` 4.0.0 e `clickup-patterns.md`.
- **Status canônico de PR:** `review` ao abrir, `done` no merge, tag `under-review` opcional (capability) — aplicado
  em `pr.md`, `pr-update.md`, `git/flow.md`, `task-manager-auto-update.md`.
- Consumidores corrigidos: `product/feature.md`, `validate/qa-points/estimate.md`.
- KB nova `docs/knowledge-base/platforms/clickup-api.md` + entrada no índice da KB.

## Como aplicar no core

```bash
git apply --check <este-patch>   # extraia o bloco diff abaixo para um arquivo
git apply <este-patch>
/meta:inventory                  # o inventory.md ficou fora do patch (contagem do adotante difere)
bash .claude/validation/lint-artifacts.sh
```

Conferido com `git apply --check` contra os arquivos do core no pin `547e2e3edf3b` (o `index.md` da KB aplica com
offset). **Conteúdo pesquisado, não medido**: nada foi chamado contra um Workspace real (o token do adotante ainda não
validou). Lacunas a medir ao vivo estão no banner do adapter: `include_subtasks` × `subtasks=true`,
`clickup_delete_task` no MCP, alias `markdown_description`, formatos de priority/datas/time_estimate/tags/assignees,
Edit Checklist Item, headers em 429, `inputSchema` das tools MCP.

## Decisões que o core deve validar

1. Status canônico de PR `review` (vs `in_progress` + tag).
2. Capabilities opcionais como forma de ampliar a interface sem quebrar os outros adapters.
3. `blocked` fora de `TaskStatus` (lido como `in_progress` com `statusRaw`).
4. Sprint Points nativo exposto como "Story Points" quando não há custom field.

## Patch

```diff
From ee1e0ed8e1f93bef38b6eecd1aa69565390c11f7 Mon Sep 17 00:00:00 2001
From: Marcio Carvalho <marciocar@gmail.com>
Date: Fri, 2 Oct 2026 01:26:25 +0000
Subject: [PATCH] wip

---
 .../agents/development/clickup-specialist.md  |  464 ++----
 .../common/prompts/clickup-patterns.md        |   48 +-
 .../prompts/task-manager-auto-update.md       |    4 +-
 .claude/commands/engineer/pr-update.md        |    2 +-
 .claude/commands/engineer/pr.md               |    4 +-
 .claude/commands/git/flow.md                  |    2 +-
 .claude/commands/product/feature.md           |   10 +-
 .../commands/validate/qa-points/estimate.md   |    4 +-
 .../utils/task-manager/adapters/clickup.md    | 1318 +++++++++--------
 .claude/utils/task-manager/detector.md        |   15 +-
 .claude/utils/task-manager/factory.md         |    9 +-
 .claude/utils/task-manager/interface.md       |   65 +-
 .claude/utils/task-manager/types.md           |   69 +-
 docs/knowledge-base/index.md                  |    1 +
 docs/knowledge-base/platforms/clickup-api.md  |  169 +++
 15 files changed, 1200 insertions(+), 984 deletions(-)
 create mode 100644 docs/knowledge-base/platforms/clickup-api.md

diff --git a/.claude/agents/development/clickup-specialist.md b/.claude/agents/development/clickup-specialist.md
index 95dceebc1..1fd2a35a1 100644
--- a/.claude/agents/development/clickup-specialist.md
+++ b/.claude/agents/development/clickup-specialist.md
@@ -1,7 +1,7 @@
 ---
 name: clickup-specialist
 description: |
-  Especialista técnico em ClickUp (API-first; MCP opcional) para automações avançadas e otimizações de performance.
+  Especialista técnico em ClickUp (API-first; MCP oficial opcional) para automações avançadas e otimizações de performance.
   Use para operações técnicas ClickUp, bulk operations e workflows. Relacionado: @product-agent, @task-specialist.
 model: sonnet
 tools:
@@ -12,7 +12,7 @@ tools:
   - WebSearch
   - WebFetch
   - TodoWrite
-  - Bash        # REST da ClickUp API (curl) — API-first; MCP é transporte OPCIONAL via adapter
+  - Bash        # REST da ClickUp API v2 (curl) — API-first; MCP é transporte OPCIONAL via adapter
 
 color: orange
 priority: alta
@@ -23,7 +23,8 @@ expertise:
   - workflow-automation
   - performance-optimization
   - bulk-operations
-  - time-tracking
+  - custom-fields
+  - checklists
 
 related_agents:
   - product-agent
@@ -33,355 +34,158 @@ related_commands:
   - /product/task
   - /product/check
 
-version: "3.0.0"
-updated: "2025-11-24"
+version: "4.0.0"
+updated: "2026-10-02"
 
 # Configurações Necessárias
 required_env:
   - name: CLICKUP_API_TOKEN
-    description: Token de API do ClickUp (Settings > Apps > API Token)
+    description: Token pessoal pk_ (Settings > Apps > API Token) — vai cru no header Authorization, SEM Bearer
     required: true
   - name: CLICKUP_WORKSPACE_ID
-    description: ID do workspace (obtido automaticamente ou via URL)
+    description: ID do Workspace (= team_id da v2). Ausente → auto-detectado via GET /team quando há um só
+    required: false
+  - name: CLICKUP_DEFAULT_LIST_ID
+    description: List padrão para createTask sem projectId
     required: false
 ---
 
-Você é um especialista técnico em ClickUp com foco absoluto em otimização, automação e configurações avançadas.
-
-> **Doutrina de transporte (SDAAL — API-first):** opere o ClickUp por **REST API** (HTTP via
-> `Bash`/curl ou `WebFetch`, token `CLICKUP_API_TOKEN`), através do adapter
-> `.claude/utils/task-manager/adapters/clickup.md`. O **MCP é transporte OPCIONAL** — só quando
-> `TASK_MANAGER_TRANSPORT=mcp` E o servidor MCP do ClickUp estiver configurado. Os exemplos
-> abaixo que citam ferramentas `mcp_ClickUp_*` são **legado/opcional**; o caminho default é REST.
-> Nunca dependa de MCP para a operação básica. *(Modernização completa dos exemplos p/ REST: follow-up.)*
-
-## 🎯 Filosofia Core
-
-### Especialização Técnica
-Sua expertise é **puramente técnica** - você transforma operações ClickUp simples em workflows eficientes e automatizados. Enquanto o `product-agent` foca na **estratégia e gestão**, você domina a **implementação técnica**.
-
-### Complementaridade com product-agent
-- **product-agent**: "O QUE fazer" (estratégia, coordenação, especificação)
-- **clickup-specialist**: "COMO otimizar" (automações, performance, configurações técnicas)
-
-### Princípios Fundamentais
-1. **Performance First** - Toda operação deve ser otimizada para velocidade
-2. **Automation by Design** - Automatizar workflows repetitivos sempre que possível  
-3. **Bulk Operations** - Preferir operações em lote vs. individuais
-4. **Error Handling** - Implementar retry logic e fallbacks robustos
-
-## 🔧 Áreas de Especialização
-
-### 1. **Workflow Automation**
-Criar automações inteligentes baseadas em:
-- **Status Changes**: Triggers automáticos quando tasks mudam de status
-- **Assignee Updates**: Notificações e ações baseadas em atribuições
-- **Tag Management**: Aplicação automática de tags baseada em contexto
-- **Time-based Triggers**: Ações baseadas em datas e prazos
-
-### 2. **Performance Optimization**
-Otimizar operações ClickUp através de:
-- **Bulk Operations**: Usar `create_bulk_tasks`, `update_bulk_tasks`, etc.
-- **Rate Limit Management**: Respeitar limites de 100 req/min com batching inteligente
-- **Query Optimization**: Filtros eficientes para reduzir transferência de dados
-- **Caching Strategies**: Cache inteligente de dados frequentemente acessados
-
-### 3. **Advanced Configuration**
-Gerenciar configurações complexas:
-- **Custom Fields**: Setup e management de campos personalizados
-- **Workspace Hierarchy**: Otimizar estrutura Space→List→Task
-- **Templates**: Criar e aplicar templates reutilizáveis
-- **Permissions**: Configurar sharing e access levels
-
-### 4. **Notification & Integration**
-Implementar notificações e integrações:
-- **Webhook Configuration**: Setup de eventos e endpoints
-- **Comment Automation**: Comentários contextuais automáticos
-- **Status Synchronization**: Sync entre ClickUp e sistemas externos
-- **Alert Systems**: Notificações inteligentes baseadas em condições
-
-## 🛠️ Metodologia Técnica
-
-### Abordagem de Otimização
-```python
-# Padrão de otimização típico
-1. Analisar operação atual (single operation)
-2. Identificar oportunidades de bulk processing
-3. Implementar batching com rate limit awareness
-4. Adicionar error handling e retry logic
-5. Monitorar performance e ajustar
-```
-
-### Workflow de Automação
-```python
-# Framework de automação
-1. Identificar trigger events (status, assignee, date)
-2. Definir condições e filtros
-3. Implementar ações automáticas
-4. Configurar fallbacks e error handling
-5. Documentar automação para manutenibilidade
-```
-
-### Pattern de Integração
-```python
-# Como trabalhar com product-agent
-1. product-agent define ESTRATÉGIA (que tasks criar, prioridades)
-2. clickup-specialist implementa OTIMIZAÇÕES (como criar eficientemente)
-3. Resultado: Estratégia sólida + Implementação otimizada
-```
-
-## 📊 Ferramentas ClickUp (API-first; MCP opcional) - Especialização
-
-### **Core Operations** (Básicas - shared com product-agent)
-- `create_task` - Criação individual de tasks
-- `update_task` - Atualizações de status e conteúdo
-- `get_task` - Recuperação de task details
-- `create_task_comment` - Comentários contextuais
-
-### **Bulk Operations** (Sua especialidade)
-- `create_bulk_tasks` - Criação em lote otimizada
-- `update_bulk_tasks` - Updates em massa 
-- `move_bulk_tasks` - Movimentação eficiente entre lists
-- `delete_bulk_tasks` - Limpeza em lote
-
-### **Advanced Management** (Configurações técnicas)
-- `get_workspace_hierarchy` - Mapeamento de estrutura
-- `get_workspace_tasks` - Queries otimizadas com filtros
-- `move_task` - Movimentação entre lists/spaces
-- `duplicate_task` - Clonagem eficiente
-
-### **Tag & Organization** (Automação de organização)
-- `get_space_tags` - Inventário de tags disponíveis
-- `add_tag_to_task` - Aplicação automática de tags
-- `remove_tag_from_task` - Cleanup de tags
-
-### **Comments & Communication** (Automação de comunicação)
-- `get_task_comments` - Análise de histórico
-- `create_task_comment` - Comentários automáticos contextuais
-
-### **File & Tracking** (Integrações avançadas)
-- `attach_task_file` - Anexos automáticos
-- `get_task_time_entries` - Análise de time tracking
-- `start_time_tracking` - Automação de tracking
-- `stop_time_tracking` - Finalização automática
-
-## 🎯 Casos de Uso Específicos
-
-### **Caso 1: Bulk Task Creation**
-```python
-# Otimização típica
-❌ ANTES: 10 chamadas create_task individuais
-✅ DEPOIS: 1 chamada create_bulk_tasks otimizada
-
-# Benefício: 90% redução em API calls + 5x mais rápido
-```
-
-### **Caso 2: Status Automation**
-```python
-# Workflow automatizado
-Trigger: Task status → "in progress"
-Action: 
-  - Add tag "development"
-  - Start time tracking automático
-  - Comment com branch info
-  - Notify assignee
-```
-
-### **Caso 3: Performance Monitoring**
-```python
-# Query otimizada
-❌ ANTES: get_task individual para cada task
-✅ DEPOIS: get_workspace_tasks com filtros específicos
-
-# Benefício: Dados batch + filtros server-side
-```
-
-### **Caso 4: Template Application**
-```python
-# Automação de templates
-Trigger: Nova task criada com tag "feature"
-Action:
-  - Apply template "feature-template"
-  - Set custom fields (estimate, priority)  
-  - Create standard subtasks
-  - Assign para team lead
-```
-
-## ⚡ Patterns de Performance
-
-### Rate Limit Management
-```python
-# Estratégia inteligente de batching
-MAX_REQUESTS_PER_MINUTE = 100
-BATCH_SIZE = 10
-DELAY_BETWEEN_BATCHES = 6  # seconds
-
-# Implementar backoff exponential em case de rate limit
-```
-
-### Bulk Operations Strategy
-```python
-# Preferir sempre bulk operations
-if tasks_count > 5:
-    use create_bulk_tasks()
-else:
-    use individual create_task()
-```
-
-### Query Optimization
-```python
-# Filtros server-side vs client-side
-✅ GOOD: get_workspace_tasks(filters={status: "in progress"})
-❌ BAD: get_all_tasks() → filter_locally()
-```
-
-### Error Handling Pattern  
-```python
-try:
-    result = bulk_operation()
-except RateLimitError:
-    wait_and_retry()
-except APIError as e:
-    fallback_to_individual_operations()
-    log_error_for_analysis()
-```
-
-## 🔗 Integração com Sistema Onion
-
-### Delegação Automática
-O sistema deve reconhecer automaticamente quando usar clickup-specialist:
+Você é o especialista técnico em ClickUp do Sistema Onion: **como** operar o ClickUp de forma correta,
+eficiente e automatizada. O `@product-agent` decide **o que** fazer.
+
+> **Fonte de verdade (leia antes de agir):**
+> - Contrato e implementação: [`.claude/utils/task-manager/adapters/clickup.md`](../../utils/task-manager/adapters/clickup.md)
+>   (v3.0.0, 2026-10-02). As armadilhas, os mapeamentos, a busca e as lacunas estão lá.
+> - Plataforma (API vigente, fontes, limites): [`docs/knowledge-base/platforms/clickup-api.md`](../../../docs/knowledge-base/platforms/clickup-api.md)
+> - Formatação e status de PR: [`clickup-patterns`](../../commands/common/prompts/clickup-patterns.md)
+>
+> Este agente **não duplica** endpoints nem payloads. Quando o adapter e este texto divergirem, vale o
+> adapter.
+
+## 🚦 Doutrina de transporte (SDAAL, API-first)
+
+1. **REST API v2** (`https://api.clickup.com/api/v2`) é o caminho default, via `Bash`/curl ou `WebFetch`,
+   com `Authorization: $CLICKUP_API_TOKEN` (sem `Bearer`). A v3 só importa para anexos.
+2. **MCP oficial** (`https://mcp.clickup.com/mcp`, tools `clickup_*`) é opcional e só entra quando o
+   detector resolve `transport: 'mcp'` **e** o servidor responde. No Claude Code, a tool se chama
+   `mcp__<servidor>__clickup_create_task`, e `<servidor>` é o nome do registro. **Delete, checklists,
+   custom fields e hierarquia vão sempre pela API.**
+3. Comandos e outros agentes **não** chamam o ClickUp direto: usam `taskManager.*` (adapter). Este
+   especialista é a exceção declarada no lint (Regras 10/11), para operações técnicas fora do contrato.
+
+## ⚠️ Cinco regras que evitam 90% dos bugs
+
+| Regra | Errado | Certo |
+|---|---|---|
+| Campo de markdown na escrita | `markdown_description` | **`markdown_content`** (`C_ADAPTER_MARKDOWN_FIELD_MISMATCH`) |
+| Datas e estimativa | `"2026-10-02"`, minutos | **Unix ms** (`due_date`, `start_date`, `time_estimate`) |
+| Prioridade | `"medium"`, `"high"` | **1 urgent · 2 high · 3 normal · 4 low** (não existe `medium`) |
+| Tags e assignees no update | `tags: [...]`, `assignees: [...]` no PUT | tag: `POST/DELETE /task/{id}/tag/{name}`; assignees: `{add, rem}` |
+| Custom field | nome da opção; campo de outro tipo de task | **UUID da opção**; conferir `applied_objects` × `custom_item_id` (senão 400) |
+
+Os formatos de data, prioridade, tags e assignees são prática v2 **não ancorada** na pesquisa de
+2026-10-02. Na primeira operação real, confira no corpo da resposta (adapter, §Lacunas).
+
+## 🔧 Áreas de especialização
+
+### 1. Bulk e hierarquia
+- `clickup_create_bulk_tasks` (MCP) serve para tasks **independentes no mesmo nível**.
+- **Bulk ignora `parent`.** Hierarquia se cria em sequência: task → `createSubtask` (mesma List, e o pai
+  pode ser subtask) → checklist → comentário de setup.
+
+### 2. Rate limit (por token, conforme o plano do Workspace)
+
+| Plano | req/min |
+|---|---|
+| Free Forever · Unlimited · Business | 100 |
+| Business Plus | 1.000 |
+| Enterprise / Enterprise Plus | 10.000 |
+
+- Leia `X-RateLimit-Remaining` em toda resposta e desacelere perto de zero.
+- Em 429, use backoff exponencial com jitter (1 s, 2 s, 4 s; máx. 3) e respeite `X-RateLimit-Reset` se
+  vier. **É prática nossa: o ClickUp não documenta backoff.**
+- Não retente 5xx em `POST`, porque pode duplicar a task.
+- Cacheie a hierarquia (`getProjectList` custa 1 + Spaces + Folders chamadas).
+
+### 3. Custom fields e Sprint Points
+- `GET /list/{id}/field` lista os campos com `applied_objects`. Setar é
+  `POST /task/{id}/field/{field_id}` `{value}`.
+- Pelo contrato: `taskManager.setCustomField(taskId, 'Story Points', 5)`. O adapter resolve o nome, o
+  UUID do dropdown e o ms da data.
+- **Sprint Points nativo** (`points`) existe no Create/Update Task. Na leitura, o adapter o expõe também
+  como custom field "Story Points", para o `story-points-gate`.
+- Tipo de task: `custom_item_id` (0 Task, 1 Milestone, demais do Workspace).
+
+### 4. Checklists
+- `POST /task/{id}/checklist` `{name}` → `POST /checklist/{cid}/checklist_item` `{name}`. Pelo contrato:
+  `createChecklist(taskId, name, items)` e `setChecklistItem(cid, iid, resolved)`.
+- Progresso = Σ resolved / Σ (resolved + unresolved) sobre `getTask(id, { includeSubtasks: true })`.
+
+### 5. Custom task IDs
+- IDs `PREFIX-NUM` (ex.: `DEV-42`) exigem as queries `custom_task_ids=true` + `team_id=<ws>` em todo `/task/{id}`.
+- O formato colide com Jira/Linear no detector: com ClickUp, fixe `TASK_MANAGER_PROVIDER=clickup`.
+
+### 6. Webhooks (sincronia por evento)
+- Criados por evento (`taskCreated`, `taskUpdated`, `taskStatusUpdated`…) + URL. Valide `X-Signature` =
+  HMAC SHA-256 (hex) do corpo bruto com o secret devolvido na criação.
+
+## 🧪 Receitas REST (curl)
 
-**Use clickup-specialist quando**:
-- Operações em bulk (>5 tasks)
-- Configurações técnicas (webhooks, custom fields)
-- Otimizações de performance
-- Automações de workflow
-- Análise de time tracking
-- Setup de templates
-
-**Use product-agent quando**:
-- Decisões estratégicas de produto
-- Coordenação de equipes
-- Especificação de funcionalidades
-- Priorização de backlog
-
-### Comandos de Integração
 ```bash
-# Fluxos que devem usar clickup-specialist automaticamente:
-/product/task → criar task optimizada com template
-/engineer/pr → automação de status + tags + comments
-/engineer/start → setup automático de time tracking
-```
+H="Authorization: ${CLICKUP_API_TOKEN}"; B=https://api.clickup.com/api/v2
 
-## 📋 Workflows Prioritários
+# Conexão + Workspace
+curl -s -H "$H" $B/user && curl -s -H "$H" $B/team
 
-### **1. Task Workflow Automation**
-```python
-# Automação completa do ciclo de vida da task
-task_created → apply_template() → set_custom_fields()
-status_change → update_tags() → notify_stakeholders()
-assignee_change → update_permissions() → log_activity()
-```
+# Task com markdown, prioridade normal, prazo em ms, Sprint Points
+curl -s -X POST -H "$H" -H 'Content-Type: application/json' "$B/list/$LIST/task" \
+  -d '{"name":"🚀 Feature X","markdown_content":"## 🎯 Objetivo\n...","priority":3,
+       "due_date":1791374400000,"points":5,"tags":["feature"]}'
 
-### **2. Notification Management**
-```python
-# Sistema inteligente de notificações
-urgent_task_created → instant_notification()
-deadline_approaching → reminder_sequence()
-task_completed → completion_summary()
-```
+# Subtask (mesma List do pai)
+curl -s -X POST -H "$H" -H 'Content-Type: application/json' "$B/list/$LIST/task" \
+  -d "{\"name\":\"🔧 Backend\",\"parent\":\"$TASK\"}"
 
-### **3. Performance Monitoring**
-```python
-# Monitoramento automático de performance
-track_api_response_times()
-monitor_rate_limit_usage()
-analyze_bulk_vs_individual_efficiency()
-generate_optimization_recommendations()
+# Tag avulsa, status de PR aberto, checklist
+curl -s -X POST -H "$H" "$B/task/$TASK/tag/under-review"
+curl -s -X PUT  -H "$H" -H 'Content-Type: application/json' "$B/task/$TASK" -d '{"status":"review"}'
+curl -s -X POST -H "$H" -H 'Content-Type: application/json' "$B/task/$TASK/checklist" -d '{"name":"Aceite"}'
 ```
 
-## 🚨 Rate Limits & Error Handling
+## 🔗 Integração com o Sistema Onion
 
-### ClickUp API Constraints
-- **Rate Limit**: 100 requests/minute
-- **Burst Allowance**: Pequeno buffer para picos
-- **Response Time**: Típico 100-500ms
+**Use `@clickup-specialist` para:** bulk (mais de 5 tasks), custom fields e tipos de task, webhooks,
+automações, diagnóstico de 400/401/429, migração de status ou de Lists, e as sondas ao vivo das lacunas
+do adapter.
 
-### Error Recovery Strategy
-```python
-# Hierarchical fallback
-1. Retry with exponential backoff
-2. Switch to alternative endpoint
-3. Degrade to basic functionality
-4. Log error for manual intervention
-```
-
-### Monitoring & Alerts
-```python
-# Proactive monitoring
-if api_response_time > 1000ms: investigate_performance()
-if error_rate > 5%: enable_conservative_mode()
-if rate_limit_hit: implement_smart_queuing()
-```
+**Use `@product-agent` para:** estratégia, priorização e especificação.
 
-## 💡 Advanced Use Cases
-
-### **Multi-Space Operations**
-Operações que envolvem múltiplos spaces/lists:
-- Bulk move tasks entre projects
-- Sync status cross-workspace
-- Duplicate templates entre spaces
-
-### **Custom Field Automation**
-Setup automático de custom fields:
-- Dynamic field population
-- Validation rules implementation
-- Calculated fields updates
-
-### **Integration Pipelines**
-Integração com sistemas externos:
-- Git branch → ClickUp task linking
-- CI/CD status → Task status sync
-- Time tracking → Billing system integration
-
-### **Analytics & Reporting**
-Análise avançada de dados ClickUp:
-- Team velocity calculations
-- Bottleneck identification
-- Performance trends analysis
-- Resource utilization reports
-
-## 🎯 Success Metrics
-
-### Performance Improvements
-- **Latency**: Redução de 50%+ em operações comuns
-- **API Efficiency**: 70%+ menos calls via bulk operations
-- **Error Rate**: <2% em operações críticas
-
-### Automation Coverage
-- **Workflow Automation**: 80%+ de tasks seguem workflows automáticos
-- **Notification Accuracy**: 95%+ de notificações são contextualmente relevantes
-- **Template Usage**: 90%+ de tasks usam templates otimizados
-
-### User Experience
-- **Transparency**: Automações são invisíveis ao usuário
-- **Reliability**: 99%+ uptime em integrações críticas
-- **Speed**: Operações ClickUp completam em <2 segundos
+| Fluxo | O que o especialista garante |
+|---|---|
+| `/product/task` | hierarquia sequencial, `markdown_content`, points/custom fields corretos |
+| `/engineer/pr` | status canônico **`review`** ao abrir PR (+ tag `under-review` opcional), comentário Unicode |
+| `/git:sync` (pós-merge) | status **`done`** + comentário de conclusão |
+| `/engineer/start` | `in progress` + mapeamento fase→subtask no `context.md` |
 
----
+## 🚨 Diagnóstico rápido
 
-## 🔄 Continuous Improvement
+| Sintoma | Causa provável |
+|---|---|
+| Task criada **sem descrição** (200) | `markdown_description` em vez de `markdown_content` |
+| 401 | `Bearer` prefixado ao `pk_`, ou token revogado |
+| Prazo no dia errado ou sem prazo | ISO em vez de ms, ou ms sem fuso (use meio-dia UTC) |
+| Tag "não pega" no update | tag enviada no PUT; use `POST /task/{id}/tag/{name}` |
+| 400 ao setar campo | campo fora do `custom_item_id` da task, ou dropdown por nome |
+| Subtasks soltas | criadas por bulk com `parent` |
+| `DEV-42` não encontrado | faltou `custom_task_ids=true` + `team_id` |
+| 429 em rajada | plano de 100 req/min; leia `X-RateLimit-Remaining` |
+| Tool MCP "inexistente" | nomes `mcp_ClickUp_clickup_*` são de servidor comunitário; o oficial é `clickup_*` |
 
-### Learning & Adaptation
-- Monitor usage patterns para identificar novas oportunidades de automação
-- Analyze error logs para melhorar error handling
-- Track performance metrics para otimizações contínuas
-- Gather feedback para enhancement de workflows
+## 📋 Lacunas abertas (conferir ao vivo antes de prometer)
 
-### Evolution Strategy
-- **Phase 1**: Core optimizations (bulk ops, rate limiting)
-- **Phase 2**: Advanced automations (workflows, notifications)
-- **Phase 3**: Predictive optimizations (ML-based recommendations)
-- **Phase 4**: Full ecosystem integration (external APIs, webhooks)
+- `include_subtasks` × `subtasks=true` no Get Task
+- `clickup_delete_task` no MCP oficial (o guia diz que não existe, o catálogo diz que sim). Delete só via
+  API até confirmar.
+- Edit Checklist Item, `markdown_description` como alias, formato dos argumentos das tools MCP.
 
-**Lembre-se: Você é o especialista técnico que torna o ClickUp (via API; MCP opcional) incrivelmente eficiente e automatizado! 🚀**
+Lista completa com as sondas: adapter, §Lacunas a conferir ao vivo.
diff --git a/.claude/commands/common/prompts/clickup-patterns.md b/.claude/commands/common/prompts/clickup-patterns.md
index 948a7539c..1a3f5cb55 100644
--- a/.claude/commands/common/prompts/clickup-patterns.md
+++ b/.claude/commands/common/prompts/clickup-patterns.md
@@ -1,7 +1,15 @@
 # Padrões de Formatação ClickUp
 
+> Fonte técnica: adapter [`clickup.md`](../../../utils/task-manager/adapters/clickup.md) (v3.0.0,
+> 2026-10-02). Este fragmento cuida só de **forma** (templates, símbolos, convenção de status).
+
 ## 📋 Task Descriptions (Markdown)
 
+O campo de escrita é **`markdown_content`**, não `markdown_description`. Via contrato, é
+`CreateTaskInput.markdownDescription`, e o adapter traduz. Na leitura, o ClickUp devolve
+`markdown_description` (com `include_markdown_description=true`). Comentários **não** usam markdown:
+veja a seção seguinte.
+
 ### Estrutura Padrão
 
 ```markdown
@@ -96,11 +104,10 @@
 
 ## 🏷️ Tags Padrão
 
-### Por Prioridade
-- `urgent` - Crítico
-- `high` - Alta
-- `medium` - Média  
-- `low` - Baixa
+### Prioridade (campo nativo, não tag)
+Use o campo `priority` (contrato `TaskPriority`), não tags. Valores: `urgent` (1) · `high` (2) ·
+**`normal`** (3) · `low` (4). **Não existe `medium`**: quem escreve `medium` cai em erro ou fica sem
+prioridade.
 
 ### Por Tipo
 - `feature` - Funcionalidade
@@ -109,10 +116,10 @@
 - `docs` - Documentação
 - `subtask` - Subtask
 
-### Por Status
-- `blocked` - Bloqueado
-- `review` - Em revisão
-- `testing` - Em teste
+### Tags de estado (opcionais, complementam o status)
+- `blocked`: bloqueado (o status canônico continua `in_progress`; ver Status Flow)
+- `under-review`: PR aberto (opcional; o **status** canônico é `review`)
+- `testing`: em teste
 
 ---
 
@@ -129,16 +136,23 @@
 
 ---
 
-## 🔄 Status Flow
+## 🔄 Status Flow (convenção canônica de PR — 2026-10-02)
 
 ```
-TO DO → IN PROGRESS → REVIEW → DONE
-         ↓
-      BLOCKED → IN PROGRESS
+backlog → todo → in_progress → review → done
+                     ↑   ↓ (tag blocked)
 ```
 
-### Transições Automáticas
-- PR aberto → `review`
-- PR merged → `done`
-- Bloqueio detectado → `blocked`
+| Evento | Status canônico (`TaskStatus`) | Tag opcional | Quem aplica |
+|---|---|---|---|
+| `/engineer:start` | `in_progress` | — | `updateStatus` |
+| **PR aberto** (`/engineer:pr`, `/git:flow feature publish`) | **`review`** | `under-review` | `updateStatus(id, 'review')` + `addTag` se a capability `tags` existir |
+| PR atualizado (`/engineer:pr-update`) | mantém `review` | — | só comentário |
+| **PR merged** (`/git:sync`, `/git:flow * finish`) | **`done`** | remover `under-review` | `updateStatus(id, 'done')` |
+| Bloqueio detectado | mantém o status | `blocked` | `addTag` (status `blocked` só se a List tiver) |
+
+**Por que um só:** até 2026-10-02 havia três convenções concorrentes (`in_progress` + tag
+`under-review` em `/engineer:pr`, `review` em `/git:flow`, `review`/`blocked` aqui). `review` é status
+canônico em **todos** os adapters (`interface.md`). Já a tag depende da capability opcional `tags`, e
+por isso fica como complemento, nunca como o sinal principal.
 
diff --git a/.claude/commands/common/prompts/task-manager-auto-update.md b/.claude/commands/common/prompts/task-manager-auto-update.md
index 358732b85..69d02b916 100644
--- a/.claude/commands/common/prompts/task-manager-auto-update.md
+++ b/.claude/commands/common/prompts/task-manager-auto-update.md
@@ -63,9 +63,9 @@ Os eventos do ciclo de engenharia disparam o mecanismo via adapter (transporte d
 
 | Evento | Ação (agnóstica via adapter) |
 |--------|------------------------------|
-| `/engineer:start` | `getTask(id, {subtasks:true})` → `updateStatus(id,'in_progress')` → `addComment(id, '🚀 …')` → criar mapeamento fase→subtask no `context.md` |
+| `/engineer:start` | `getTask(id, { includeSubtasks: true })` → `updateStatus(id,'in_progress')` → `addComment(id, '🚀 …')` → criar mapeamento fase→subtask no `context.md` |
 | `/engineer:work` (fim de fase) | `updateStatus(subtaskId,'done')` → `addComment(mainTaskId, '🔧 progresso …')` → atualizar `plan.md` |
-| `/engineer:pr` | `updateStatus(id,'in_progress')` + tag `under-review` → `addComment(id, '🚀 PR …')` |
+| `/engineer:pr` | `updateStatus(id,'review')` (+ `addTag(id,'under-review')` opcional, capability `tags`) → `addComment(id, '🚀 PR …')` |
 | `/git:sync` (pós-merge) | `updateStatus(id,'done')` → `addComment(id, '✅ concluída/merged …')` |
 
 > Exemplos de transporte específico (ClickUp/Jira/etc.) vivem no respectivo adapter — ex.: `adapters/clickup.md` (Hierarquia, Checklists, formatação Unicode). O comando **nunca** chama o MCP/SDK do provider direto.
diff --git a/.claude/commands/engineer/pr-update.md b/.claude/commands/engineer/pr-update.md
index 9361f4d65..8004a7383 100644
--- a/.claude/commands/engineer/pr-update.md
+++ b/.claude/commands/engineer/pr-update.md
@@ -53,7 +53,7 @@ Antes de operar com a task, carregue o `.env` e leia `TASK_MANAGER_PROVIDER` (`j
 ### Detecção de Task Ativa
 - Lê task ID do arquivo `.claude/sessions/[slug]/context.md`
 - Identifica PR existente através da task ou branch
-- Valida se task está em status "in progress" com tag "under-review"
+- Valida se task está em status "review" (status canônico de PR aberto; tag "under-review" é opcional)
 
 ### Comentário Automático Padronizado
 
diff --git a/.claude/commands/engineer/pr.md b/.claude/commands/engineer/pr.md
index e87a7d8df..30aba428b 100644
--- a/.claude/commands/engineer/pr.md
+++ b/.claude/commands/engineer/pr.md
@@ -37,7 +37,7 @@ Siga estes passos para criar o PR:
    ```
    Faça commit apenas dos arquivos alterados (ver Regra de Ouro) e push para a branch de trabalho.
 
-3. **Task → in progress + under-review**: se `TASK_MANAGER_PROVIDER` != `none`, via o adapter Task Manager — `updateStatus(taskId, 'in_progress')` + tag `under-review`. Carregue `.env` e leia o provider; em `none`, pule (sem persistência remota). **Não reimplementar** roteamento aqui — é responsabilidade do adapter.
+3. **Task → review** (status canônico de PR aberto, ver `common:prompts:clickup-patterns` §Status Flow): se `TASK_MANAGER_PROVIDER` != `none`, via o adapter Task Manager — `updateStatus(taskId, 'review')`; tag `under-review` **opcional** via `addTag` quando o adapter declara a capability `tags` (sem ela, pule a tag — não é erro). Carregue `.env` e leia o provider; em `none`, pule (sem persistência remota). **Não reimplementar** roteamento aqui — é responsabilidade do adapter.
 
 4. **Comentário na task** documentando o PR (via adapter Task Manager): URL do PR, branch, descrição das mudanças e status dos testes (passing | review | pending). A **formatação por provider** (ADF/Jira, Markdown/ClickUp-Linear-Zoho, HTML/Asana, Unicode em comments ClickUp) é resolvida pelo adapter / especialista do provider — o comando não formata manualmente.
 
@@ -144,7 +144,7 @@ Seu output final deve ser:
 Tarefa completada:
 - Testes passando
 - Mudanças commitadas
-- Task [TASK ID] movida para "in progress" + tag "under-review" no Task Manager ([PROVIDER]) via adapter
+- Task [TASK ID] movida para "review" (+ tag "under-review" se suportada) no Task Manager ([PROVIDER]) via adapter
 - PR aberto via forge adapter: [PR TITLE]
 - Passada adversarial rodada EM PARALELO ao CI: [N] refutadores, [X] achados reais, [Y] curados neste PR, [Z] declarados com gatilho
 - Comentários do code review automatizado abordados e pushed
diff --git a/.claude/commands/git/flow.md b/.claude/commands/git/flow.md
index f64567e10..596e4b62e 100644
--- a/.claude/commands/git/flow.md
+++ b/.claude/commands/git/flow.md
@@ -55,7 +55,7 @@ Cada combinação `(type, action)` resolve para um Template do motor + ações d
 | Combinação | Motor (KB) | Git local | Forge | Task Manager |
 |---|---|---|---|---|
 | `feature start <nome>` | [§Template 2](../../../docs/knowledge-base/frameworks/gitflow-patterns.md#template-2-feature-development) + [§Contrato de Sessão](../../../docs/knowledge-base/frameworks/gitflow-patterns.md#contrato-de-sessão-de-desenvolvimento) | cria `feature/<nome>` de `develop`, checkout; cria `.claude/sessions/<slug>/` | — | vincula task (opcional) |
-| `feature publish` | §Template 2 | `git push -u origin feature/<nome>` | `requestReviewers` / PR draft (opcional) | `updateStatus → review` |
+| `feature publish` | §Template 2 | `git push -u origin feature/<nome>` | `requestReviewers` / PR draft (opcional) | `updateStatus → review` (+ tag `under-review` opcional) |
 | `feature finish` | §Template 2 / §6 | merge `feature → develop`, cleanup, arquiva sessão | — | `updateStatus → done` |
 | `release start <ver>` | [§Template 3](../../../docs/knowledge-base/frameworks/gitflow-patterns.md#template-3-release-process) + [§Semver](../../../docs/knowledge-base/frameworks/gitflow-patterns.md#algoritmo-unificado-de-auto-bump-semver) | resolve versão (explícita/auto-bump), cria `release/<ver>` de `develop` | — | cria task de release (opcional) |
 | `release finish` | §Template 3 | merge `release → main`+`develop`, `git tag -a`, push `--tags` | `createRelease` (notas) + `getCIStatus(main)` | `updateStatus → done` |
diff --git a/.claude/commands/product/feature.md b/.claude/commands/product/feature.md
index dce9c89c2..d0dedcac8 100644
--- a/.claude/commands/product/feature.md
+++ b/.claude/commands/product/feature.md
@@ -95,8 +95,10 @@ function getCurrentProjectId() {
     }
   }
   
-  // Fallback: usar projeto padrão configurado
-  return taskManager.defaultProjectId;
+  // Fallback: sem projectId → o adapter aplica o default do provider
+  // (ClickUp: CLICKUP_DEFAULT_LIST_ID). Sem default configurado, perguntar ao
+  // usuário oferecendo as opções de taskManager.getProjectList().
+  return undefined;
 }
 
 const projectId = getCurrentProjectId();
@@ -164,7 +166,7 @@ $FEATURE_NAME
 ## 🏷️ **Tags e Categorização**
 - **Type**: feature
 - **Status**: backlog  
-- **Priority**: medium (ajustar conforme roadmap)
+- **Priority**: normal (ajustar conforme roadmap)
 - **Phase**: planning
 
 **Criada automaticamente pelo Sistema Onion** 🧅"
@@ -178,7 +180,7 @@ const task = await taskManager.createTask({
   projectId: projectId,
   markdownDescription: TASK_DESCRIPTION,
   status: 'backlog',
-  priority: 'medium',
+  priority: 'normal',   // TaskPriority: urgent | high | normal | low (não existe 'medium')
   tags: ['feature', 'backlog', 'planning']
 });
 
diff --git a/.claude/commands/validate/qa-points/estimate.md b/.claude/commands/validate/qa-points/estimate.md
index b13093f03..615428833 100644
--- a/.claude/commands/validate/qa-points/estimate.md
+++ b/.claude/commands/validate/qa-points/estimate.md
@@ -115,8 +115,8 @@ Listar as técnicas do tipo de teste a partir de `qa-story-points.md` §4 (detal
 
 1. **Detectar provedor:** usar `{{task-manager}}` se explícito; senão delegar a `detector.detectProviderFromTaskId(taskId)` (o detector/factory resolve o provider — não inferir manualmente pelo prefixo do ID) ou ler `TASK_MANAGER_PROVIDER` no `.env`. Se nada detectado → continuar apenas com output local.
 2. **Buscar a task** via `taskManager.getTask(taskId)` e validar que existe; ler story points atuais.
-3. **Atualizar (SE `--update`):** chamar `taskManager.updateTask(taskId, { customField: "QA Story Points", value: totalPoints })` (REST API default; o adapter resolve o nome/ID do custom field por provider e aciona o especialista quando necessário); comentar a análise via `taskManager.addComment(taskId, commentText)`.
-   - Se o custom field não existir: comentar a estimativa e sugerir criar o campo (o adapter/especialista orienta o formato correto por provider).
+3. **Atualizar (SE `--update`):** chamar `taskManager.setCustomField(taskId, "QA Story Points", totalPoints)` (capability opcional `customFields`; o adapter resolve nome → ID/formato por provider); comentar a análise via `taskManager.addComment(taskId, commentText)`.
+   - Se o adapter não tiver a capability (`TaskManagerNotSupportedError`) ou o custom field não existir: comentar a estimativa e sugerir criar o campo (o adapter/especialista orienta o formato correto por provider).
 
 **Template de comentário (Unicode):**
 
diff --git a/.claude/utils/task-manager/adapters/clickup.md b/.claude/utils/task-manager/adapters/clickup.md
index 60cf19377..03999567f 100644
--- a/.claude/utils/task-manager/adapters/clickup.md
+++ b/.claude/utils/task-manager/adapters/clickup.md
@@ -1,796 +1,892 @@
 # 🔵 ClickUp Adapter
 
-## 🎯 Propósito
+> Instância do padrão [SDAAL](../../../../docs/knowledge-base/concepts/specification-driven-ai-abstraction-layer.md).
+> Transporte **padrão: REST API v2** (`https://api.clickup.com/api/v2`). A **v3** cobre poucos
+> endpoints e não tem cronograma de migração. Aqui ela só importa para **anexos**, que ficam fora do
+> escopo deste adapter (`C_V2_REMAINS_ADAPTER_BASE`, `C_ATTACHMENTS_MOVE_TO_V3`). Transporte
+> **opcional: MCP oficial do ClickUp** (`https://mcp.clickup.com/mcp`), ativado por
+> `config.transport === 'mcp'` e com fallback real para a API.
+
+> ⚠️ **O QUE FOI PESQUISADO E O QUE FOI MEDIDO.** Esta revisão (2026-10-02) foi **pesquisada em fontes
+> primárias** (developer.clickup.com, help.clickup.com) por uma rodada com verificador independente:
+> grafo `clickup-api-2026-10`, 14 claims e 34 evidências ancoradas. Os ids `C_*`/`E_*` citados abaixo
+> são nós desse grafo. **Nada aqui foi chamado contra um Workspace real nesta revisão.** Onde a doc
+> oficial não ancorou o detalhe, o texto diz **NÃO ANCORADO** e o comportamento vem da prática
+> estabelecida da v2. A referência de plataforma vive em
+> [`docs/knowledge-base/platforms/clickup-api.md`](../../../../docs/knowledge-base/platforms/clickup-api.md).
+
+| Medido × não medido | Estado | Nó |
+|---|---|---|
+| Auth: token `pk_` cru em `Authorization`, **sem** `Bearer` (OAuth usa Bearer) | ancorado | `C_AUTH_HEADER_UNCHANGED` |
+| `team_id` da v2 = ID do **Workspace** | ancorado | `C_TEAM_ID_IS_WORKSPACE` |
+| Campo de markdown no Create Task é **`markdown_content`** | ancorado | `C_ADAPTER_MARKDOWN_FIELD_MISMATCH` |
+| Create Task aceita `parent`, `custom_item_id`, `points`, `links_to`, `check_required_custom_fields` | ancorado | `C_CREATE_TASK_FIELDS_CURRENT` |
+| Custom field escopado por tipo (`applied_objects`), Dropdown por UUID, Date em ms | ancorado | `C_CUSTOM_FIELDS_TYPE_SCOPED` |
+| Checklist (create), item de checklist (create), comentário | ancorado | `C_COMMENTS_CHECKLISTS_CURRENT` |
+| Rate limit por plano + `X-RateLimit-Remaining` | ancorado (limitado) | `C_RATE_LIMIT_BY_PLAN` |
+| MCP oficial e nomes `clickup_*` | ancorado | `C_OFFICIAL_MCP_TOOL_NAMES` |
+| Hierarquia (Spaces, Folders, Lists, `GET /list/{id}`) | ancorado | `C_HIERARCHY_ENDPOINTS_CURRENT` |
+| `include_subtasks` (documentado) × `subtasks=true` (usado até 1.x) no Get Task | **CONFERIR AO VIVO** | `C_GET_TASK_SUBTASKS_PARAM` |
+| `clickup_delete_task` existe no MCP? (o guia diz que não, o catálogo diz que sim) | **CONFERIR AO VIVO** | `C_MCP_DELETE_TOOL_INCONSISTENT` |
+| Formato de `assignees`/`priority`/`due_date`/`time_estimate`/`tags` no Create/Update | **NÃO ANCORADO** (prática v2) | `E_LACUNAS_CLICKUP_2026_10` |
+| Edit Checklist Item, backoff após 429, `markdown_description` como alias | **NÃO ANCORADO** | `E_LACUNAS_CLICKUP_2026_10` |
+
+Gatilho para re-medir: a 1ª execução com token real roda as sondas de §Lacunas e atualiza esta tabela.
 
-Implementação do `ITaskManager` para ClickUp, seguindo o padrão **SDAAL** (ver [specification-driven-ai-abstraction-layer.md](../../../../docs/knowledge-base/concepts/specification-driven-ai-abstraction-layer.md)).
+---
 
-**Transporte padrão**: ClickUp REST API v2 via `fetch` — sem dependências externas.
-**Transporte opcional**: MCP ClickUp, ativado quando `TASK_MANAGER_TRANSPORT=mcp`.
+## ⚠️ As armadilhas que quebram um adapter escrito de memória
+
+Cada uma abaixo foi um bug real da versão 2.0 deste arquivo. Várias **devolvem 200** e falham em
+silêncio.
+
+1. **`markdown_description` não é o campo de escrita.** O Create Task documenta `markdown_content`, e
+   ele prevalece sobre `description` quando os dois vêm (`E_TASK_MARKDOWN_CONTENT_PRECEDENCE`). Não se
+   sabe se `markdown_description` ainda é aceito como alias. Mandá-lo pode criar a task **sem
+   descrição**, com status 200. Na leitura, o Get Task devolve markdown com
+   `include_markdown_description=true`.
+2. **Datas são Unix ms (inteiro), não ISO.** `due_date: "2026-10-02"` não é o formato da API. O adapter
+   converte `YYYY-MM-DD` → ms. *(NÃO ANCORADO nesta rodada para tasks. Para custom field Date, ancorado
+   em `E_CF_VALUE_FORMATS`.)*
+3. **Prioridade é numérica 1–4** (1 urgent, 2 high, 3 normal, 4 low). Na leitura vem objeto
+   `priority.priority` como string (`"urgent"`…) ou `null`. **Não existe `medium`.** *(NÃO ANCORADO.)*
+4. **`time_estimate` é em ms.** O contrato usa minutos, então o adapter multiplica por 60 000. A 2.0 nunca
+   enviava o campo.
+5. **Tags no PUT da task não fazem efeito** (prática v2). Tag se adiciona com
+   `POST /task/{id}/tag/{tag_name}` e se remove com `DELETE /task/{id}/tag/{tag_name}`. No create, `tags[]`
+   é aceito.
+6. **Assignees no PUT são `{ add: [...], rem: [...] }`**, não array. Array no PUT não atribui. No create é
+   array de ids numéricos. *(rótulos add/rem vistos na doc de Update Task, formato não ancorado
+   verbatim: item 4 das rejeitadas em `E_LACUNAS_CLICKUP_2026_10`.)*
+7. **Custom field fora do tipo da task dá 400.** O campo precisa valer para o `custom_item_id` da task
+   (`E_CF_SET_VALUE_APPLICABILITY`). Dropdown recebe o **UUID da opção**, não o nome.
+8. **Subtask precisa estar na mesma List do pai** (`E_TASK_PARENT_SUBTASK`). Parent `null` **não**
+   converte subtask em task.
+9. **Os nomes de tool MCP `mcp_ClickUp_clickup_*` da 2.0 eram de outro servidor.** O oficial usa
+   `clickup_*`, e `clickup_search` passou a ser `clickup_search_workspace` (`E_MCP_TASK_TOOL_NAMES`).
+10. **Custom task ID (`DEV-42`) exige query.** Sem as queries `custom_task_ids=true` + `team_id=<ws>` a API procura um
+    id interno com esse texto e devolve erro. Esse formato **colide com Jira/Linear** no detector (ver
+    [`../detector.md`](../detector.md)).
 
 ---
 
 ## 📋 Configuração
 
-### Variáveis de Ambiente
+### Variáveis de ambiente
 
 ```bash
 # Obrigatória
-CLICKUP_API_TOKEN=pk_xxxxx
+CLICKUP_API_TOKEN=pk_xxxxx                 # token pessoal; vai cru no header (sem Bearer)
 
 # Opcionais
-CLICKUP_WORKSPACE_ID=your_workspace_id    # Auto-detectado se não informado
-CLICKUP_DEFAULT_LIST_ID=your_list_id      # Lista padrão para novas tasks
+CLICKUP_WORKSPACE_ID=9012345678            # = team_id da v2. Ausente → auto-detectado via GET /team
+CLICKUP_DEFAULT_LIST_ID=901234567890       # List padrão de createTask sem projectId
 
-# Controle de transporte (default: api)
-TASK_MANAGER_TRANSPORT=api               # api (default) | mcp
+# Transporte (lido pelo DETECTOR, não pelo adapter)
+TASK_MANAGER_TRANSPORT=api                 # api (default) | mcp
 ```
 
-### Obter Token
+O adapter **não lê env de transporte**. Recebe `config.transport` já resolvido pelo detector
+(`types.md` → `ProviderConfig.transport`). Ler `process.env.TASK_MANAGER_TRANSPORT` direto era o bug 1 da
+versão 2.0, porque ignorava a decisão do detector e o fallback.
 
-1. Acesse ClickUp → Settings → Apps
-2. Clique em "Generate" em API Token
-3. Copie o token e adicione ao `.env`
+### Obter o token
 
----
-
-## 🌐 Transporte: REST API v2 (padrão)
+1. ClickUp → avatar → **Settings** → **Apps** → **API Token** → *Generate*
+2. Copie o `pk_…` para o `.env`. **Não** prefixe com `Bearer` (`E_AUTH_PERSONAL_TOKEN_PK`).
 
-### Endpoint Base
+### Teste de conexão (setup rápido)
 
-```
-https://api.clickup.com/api/v2/
+```bash
+H="Authorization: ${CLICKUP_API_TOKEN}"
+curl -s -H "$H" https://api.clickup.com/api/v2/user   # → {"user":{"id":…,"username":…}}  token válido
+curl -s -H "$H" https://api.clickup.com/api/v2/team   # → {"teams":[{"id":"<WORKSPACE_ID>","name":…}]}
+curl -s -H "$H" "https://api.clickup.com/api/v2/team/<WORKSPACE_ID>/space?archived=false"
+curl -s -H "$H" https://api.clickup.com/api/v2/list/<LIST_ID>   # statuses da List (E_HIER_GET_LIST)
 ```
 
-### Autenticação
+`GET /team` ("Get Authorized Teams (Workspaces)", `E_AUTH_AUTHORIZED_TEAMS_LABEL`) é também o
+**auto-detect** de `CLICKUP_WORKSPACE_ID`: com **um** Workspace, o adapter usa esse id. Com vários, lança
+erro listando `id — name` para o usuário fixar a env. **Nunca escolhe sozinho.** O List ID é o fim da
+URL de *Copy link* da List.
 
-```
-Authorization: {CLICKUP_API_TOKEN}
-Content-Type: application/json
-```
+---
 
-> Nota: o ClickUp usa o token direto no header `Authorization`, sem prefixo `Bearer`.
+## 🌐 Transporte: REST API v2 (padrão)
 
-### Endpoints Principais
+```
+Base:  https://api.clickup.com/api/v2
+Auth:  Authorization: {CLICKUP_API_TOKEN}        ← sem "Bearer"
+       Content-Type: application/json
+```
 
-| Operação | Método | Endpoint |
-|----------|--------|----------|
-| Criar task | POST | `/list/{list_id}/task` |
-| Obter task | GET | `/task/{task_id}?subtasks=true` |
-| Atualizar task | PUT | `/task/{task_id}` |
-| Deletar task | DELETE | `/task/{task_id}` |
-| Criar comentário | POST | `/task/{task_id}/comment` |
-| Listar comentários | GET | `/task/{task_id}/comment` |
-| Buscar tasks | GET | `/team/{workspace_id}/task?` |
-| Hierarquia do workspace | GET | `/team/{workspace_id}/space?archived=false` |
-| Listas de um space | GET | `/space/{space_id}/list` |
-| Obter lista | GET | `/list/{list_id}` |
+| Operação | Método | Endpoint | Nó / estado |
+|---|---|---|---|
+| Criar task / subtask | POST | `/list/{list_id}/task` (`parent` p/ subtask) | `E_TASK_PARENT_SUBTASK` |
+| Obter task | GET | `/task/{id}` + `include_subtasks=true` + `include_markdown_description=true` | `E_TASK_FILTERED_AND_GET_PARAMS` (conferir ao vivo) |
+| Atualizar task | PUT | `/task/{id}` | prática v2 |
+| Deletar task | DELETE | `/task/{id}` | prática v2 |
+| Adicionar / remover tag | POST / DELETE | `/task/{id}/tag/{tag_name}` | prática v2 (MCP: `clickup_add_tag_to_task`) |
+| Comentar / listar | POST / GET | `/task/{id}/comment` | `E_COMMENT_CREATE_NOTIFY_ALL` |
+| Criar checklist | POST | `/task/{id}/checklist` `{name}` | `E_CHECKLIST_CREATE` |
+| Criar item | POST | `/checklist/{checklist_id}/checklist_item` `{name, assignee?}` | `E_CHECKLIST_ITEM_CREATE` |
+| Editar item | PUT | `/checklist/{checklist_id}/checklist_item/{item_id}` `{resolved}` | **NÃO ANCORADO** |
+| Campos da List | GET | `/list/{list_id}/field` (traz `applied_objects`) | `E_CF_ACCESSIBLE_APPLIED_OBJECTS` |
+| Setar custom field | POST | `/task/{id}/field/{field_id}` `{value}` | `E_CF_SET_VALUE_APPLICABILITY` |
+| Busca filtrada | GET | `/team/{team_id}/task?page=N&…` (100/página, page desde 0) | `E_TASK_FILTERED_AND_GET_PARAMS` |
+| Workspaces | GET | `/team` | `E_AUTH_AUTHORIZED_TEAMS_LABEL` |
+| Spaces | GET | `/team/{team_id}/space?archived=false` | `E_HIER_GET_SPACES` |
+| Folders / Lists | GET | `/space/{id}/folder` · `/folder/{id}/list` · `/space/{id}/list` | `E_HIER_LISTS_FOLDER_FOLDERLESS` |
+| Obter List | GET | `/list/{list_id}` (statuses, folder, space) | `E_HIER_GET_LIST` |
+
+**Custom task IDs:** todo endpoint `/task/{id}…` aceita `custom_task_ids=true` + `team_id={ws}` (ancorado
+para Get Task e Create Checklist). O adapter acrescenta a query sempre que o id casa `^[A-Z][A-Z0-9_]*-\d+$`.
+
+### Rate limit, 429 e retry
+
+| Plano | Limite por token | Nó |
+|---|---|---|
+| Free Forever · Unlimited · Business | 100 req/min | `E_RATE_LIMITS_BY_PLAN` |
+| Business Plus | 1.000 req/min | idem |
+| Enterprise / Enterprise Plus | 10.000 req/min | idem |
+
+- **Ler `X-RateLimit-Remaining`** em toda resposta (`E_RATE_REMAINING_HEADER`). Abaixo de 5, o adapter
+  pausa até `X-RateLimit-Reset`, se o header vier, ou 2 s.
+- **Em 429: retry com backoff exponencial + jitter** (1 s, 2 s, 4 s; máx. 3 tentativas), respeitando
+  `X-RateLimit-Reset` se presente. ⚠️ **Isto é PRÁTICA do adapter, não doc**: a página oficial não
+  documenta backoff após 429. Que `X-RateLimit-Reset` seja um timestamp Unix está sustentado, mas usá-lo
+  como base de backoff é decisão nossa (rejeitada como claim em `E_LACUNAS_CLICKUP_2026_10`).
+- `getProjectList` faz 1 + S + F chamadas (Spaces, Folders, Lists). Em plano de 100 req/min, cacheie.
 
 ---
 
-## 🔌 Transporte: MCP (opcional)
-
-Ativado quando `TASK_MANAGER_TRANSPORT=mcp` **e** o servidor MCP do ClickUp estiver disponível no ambiente.
+## 🔌 Transporte: MCP oficial (opcional)
 
-Quando ativo, substitui os `fetch` calls pelas funções MCP equivalentes:
+Servidor **hospedado pelo ClickUp**: `https://mcp.clickup.com/mcp` (`E_MCP_OFFICIAL_ENDPOINT`), com
+autenticação OAuth gerenciada pelo cliente MCP. Está em public beta, com catálogo de tools atualizado
+em 19/03/2026. As tools têm prefixo `clickup_` (`E_MCP_TOOL_PREFIX_CATALOG`). No Claude Code, o nome
+completo é `mcp__<servidor>__<tool>`, e `<servidor>` é o nome dado no registro: `clickup` em
+`claude mcp add --transport http clickup https://mcp.clickup.com/mcp`, ou `claude_ai_ClickUp` se vier
+pelo conector do claude.ai. O adapter recebe esse nome em `config.mcpServerName` (default `clickup`).
 
-| Via API (padrão) | Via MCP (opcional) |
-|------------------|--------------------|
-| `POST /list/{id}/task` | `mcp_ClickUp_clickup_create_task(...)` |
-| `GET /task/{id}` | `mcp_ClickUp_clickup_get_task(...)` |
-| `PUT /task/{id}` | `mcp_ClickUp_clickup_update_task(...)` |
-| `DELETE /task/{id}` | `mcp_ClickUp_clickup_delete_task(...)` |
-| `POST /task/{id}/comment` | `mcp_ClickUp_clickup_create_task_comment(...)` |
-| `GET /task/{id}/comment` | `mcp_ClickUp_clickup_get_task_comments(...)` |
-| `GET /team/{wid}/task` | `mcp_ClickUp_clickup_search(...)` |
-| Hierarquia workspace | `mcp_ClickUp_clickup_get_workspace_hierarchy(...)` |
-| `GET /list/{id}` | `mcp_ClickUp_clickup_get_list(...)` |
-
-Se `TASK_MANAGER_TRANSPORT=mcp` mas o servidor MCP não estiver disponível, o adapter cai para API automaticamente (fallback gracioso).
+| Via API (padrão) | Via MCP oficial | Observação |
+|---|---|---|
+| `POST /list/{id}/task` | `mcp__clickup__clickup_create_task` | |
+| `GET /task/{id}` | `mcp__clickup__clickup_get_task` | |
+| `PUT /task/{id}` | `mcp__clickup__clickup_update_task` | |
+| `POST /task/{id}/comment` | `mcp__clickup__clickup_create_task_comment` | |
+| `GET /task/{id}/comment` | `mcp__clickup__clickup_get_task_comments` | |
+| busca textual | `mcp__clickup__clickup_search_workspace` | único caminho com **texto** server-side |
+| `POST /task/{id}/tag/{t}` | `mcp__clickup__clickup_add_tag_to_task` | remoção: só API |
+| mover task de List | `mcp__clickup__clickup_move_task_to_list` | fora do contrato |
+| dependência | `mcp__clickup__clickup_add_dependency` | fora do contrato |
+| criação em lote | `mcp__clickup__clickup_create_bulk_tasks` | **sem** hierarquia (ver §Bulk) |
+| `DELETE /task/{id}` | **sempre API** | `clickup_delete_task` em disputa (`C_MCP_DELETE_TOOL_INCONSISTENT`) |
+| checklists, custom fields, hierarquia, `getProject` | **sempre API** | tools não ancoradas no catálogo |
+
+⚠️ **Os argumentos das tools não foram ancorados**, só os nomes. O adapter lê o `inputSchema` da tool
+na primeira chamada e monta os argumentos a partir dele. Os campos usados abaixo (`task_id`, `list_id`,
+`name`…) são indicativos.
+
+**Fallback real:** se a chamada MCP lançar (servidor ausente, tool inexistente, schema incompatível), o
+adapter registra `[clickup] MCP falhou em <tool>, usando API` e executa o caminho REST da mesma
+operação. O fallback vale **por chamada**: uma tool quebrada não derruba o transporte inteiro.
 
 ---
 
-## 🔧 Implementação
+## 🔧 Implementação da interface
+
+Os **16 membros** de [`../interface.md`](../interface.md) (`provider`, `isConfigured`, `createTask`,
+`getTask`, `updateTask`, `deleteTask`, `createSubtask`, `getSubtasks`, `addComment`, `getComments`,
+`updateStatus`, `searchTasks`, `getProjectList`, `getProject`, `validateTaskId`,
+`getProviderFromTaskId`) mais as **capabilities opcionais**, todas declaradas:
+`capabilities = ['tags', 'checklists', 'customFields']` → `addTag`, `removeTag`, `createChecklist`,
+`setChecklistItem`, `setCustomField`.
 
 ```typescript
-/**
- * Adapter ClickUp implementando ITaskManager.
- *
- * Transporte:
- * - PADRÃO: ClickUp REST API v2 via fetch (TASK_MANAGER_TRANSPORT=api ou ausente)
- * - OPCIONAL: MCP ClickUp (TASK_MANAGER_TRANSPORT=mcp, quando servidor disponível)
- *
- * Formatação de conteúdo:
- * - Descrições de tasks: Markdown nativo (campo markdown_description)
- * - Comentários: formatação visual Unicode (independente do transporte)
- */
+interface ClickUpAdapterConfig {
+  transport: TaskManagerTransport;   // EFETIVO, vindo do detector (nunca ler env aqui)
+  apiToken: string;
+  workspaceId?: string;              // ausente → auto-detect via GET /team
+  defaultListId?: string;
+  mcpServerName?: string;            // default 'clickup' → mcp__clickup__clickup_*
+}
+
+/** Erro tipado: status HTTP + código do ClickUp + sobra de rate limit. */
+class ClickUpApiError extends Error {
+  constructor(
+    readonly status: number, readonly method: string, readonly path: string,
+    readonly ecode?: string,          // corpo de erro { err, ECODE } — forma NÃO ANCORADA nesta rodada
+    readonly rateLimitRemaining?: number
+  ) { super(`ClickUp ${method} ${path} → ${status}${ecode ? ` (${ecode})` : ''}`); }
+}
+
 class ClickUpAdapter implements ITaskManager {
   readonly provider: TaskManagerProvider = 'clickup';
   readonly isConfigured: boolean;
+  readonly capabilities = ['tags', 'checklists', 'customFields'] as const;
 
-  private apiToken: string;
-  private workspaceId?: string;
-  private defaultListId?: string;
   private baseUrl = 'https://api.clickup.com/api/v2';
   private useMcp: boolean;
+  private workspaceId?: string;
+  private fieldCache = new Map<string, any[]>();       // list_id → campos (GET /list/{id}/field)
+  private statusCache = new Map<string, string[]>();   // list_id → nomes de status
 
-  constructor(config: ClickUpAdapterConfig) {
-    this.apiToken = config.apiToken;
+  constructor(private config: ClickUpAdapterConfig) {
+    this.isConfigured = !!config.apiToken;
+    this.useMcp = config.transport === 'mcp';          // ← config, não env (bug 1 da 2.0)
     this.workspaceId = config.workspaceId;
-    this.defaultListId = config.defaultListId;
-    this.isConfigured = !!this.apiToken;
-    this.useMcp = process.env.TASK_MANAGER_TRANSPORT === 'mcp';
   }
 
-  // ═══════════════════════════════════════════════════════════════════════════
-  // HELPERS DE TRANSPORTE
-  // ═══════════════════════════════════════════════════════════════════════════
-
-  private get headers() {
-    return {
-      'Authorization': this.apiToken,
-      'Content-Type': 'application/json'
-    };
-  }
+  // ═══════════════════════ TRANSPORTE ═══════════════════════
 
-  /** Executa fetch na REST API v2 do ClickUp. */
-  private async api<T>(method: string, path: string, body?: unknown): Promise<T> {
+  private async api<T>(method: string, path: string, body?: unknown, attempt = 0): Promise<T> {
     const res = await fetch(`${this.baseUrl}${path}`, {
       method,
-      headers: this.headers,
-      body: body ? JSON.stringify(body) : undefined
+      headers: { Authorization: this.config.apiToken, 'Content-Type': 'application/json' },
+      body: body === undefined ? undefined : JSON.stringify(body)
     });
-
+    const remaining = Number(res.headers.get('X-RateLimit-Remaining') ?? NaN);
+    const reset = Number(res.headers.get('X-RateLimit-Reset') ?? NaN);   // Unix s
+
+    if (res.status === 429 && attempt < 3) {             // PRÁTICA: backoff não documentado
+      const waitMs = Number.isFinite(reset)
+        ? Math.max(0, reset * 1000 - Date.now()) + 250
+        : 1000 * 2 ** attempt + Math.random() * 250;
+      await sleep(waitMs);
+      return this.api<T>(method, path, body, attempt + 1);
+    }
     if (!res.ok) {
-      const err = await res.text();
-      throw new Error(`ClickUp API ${method} ${path} → ${res.status}: ${err}`);
+      const raw = await res.json().catch(() => ({}));
+      throw new ClickUpApiError(res.status, method, path, raw.ECODE, remaining);
     }
-
-    return res.json() as Promise<T>;
+    if (Number.isFinite(remaining) && remaining < 5) await sleep(2000);
+    return (res.status === 204 ? undefined : res.json()) as Promise<T>;
   }
 
-  // ═══════════════════════════════════════════════════════════════════════════
-  // CRUD DE TASKS
-  // ═══════════════════════════════════════════════════════════════════════════
-
-  async createTask(input: CreateTaskInput): Promise<TaskOutput> {
-    const listId = input.projectId || this.defaultListId;
-
-    if (!listId) {
-      throw new Error('❌ list_id ou CLICKUP_DEFAULT_LIST_ID obrigatório');
+  /** Chama a tool MCP; em QUALQUER falha, executa o caminho REST (fallback por chamada). */
+  private async viaMcpOr<T>(tool: string, args: object, rest: () => Promise<T>,
+                            parse: (r: any) => T): Promise<T> {
+    if (!this.useMcp) return rest();
+    try {
+      const name = `mcp__${this.config.mcpServerName ?? 'clickup'}__${tool}`;
+      const result = await callMcpTool(name, args);      // args conferidos contra o inputSchema
+      return parse(JSON.parse(result.content[0].text));
+    } catch (e) {
+      console.warn(`[clickup] MCP falhou em ${tool} (${(e as Error).message}), usando API`);
+      return rest();
     }
+  }
 
-    const payload = {
-      name: input.name,
-      description: input.description,
-      markdown_description: input.markdownDescription,
-      priority: this.mapPriorityToClickUp(input.priority),
-      due_date: input.dueDate,
-      start_date: input.startDate,
-      assignees: input.assignees,
-      tags: input.tags
-    };
+  /** CLICKUP_WORKSPACE_ID ou auto-detect via GET /team (1 Workspace). Com N, lança e lista. */
+  private async ws(): Promise<string> {
+    if (this.workspaceId) return this.workspaceId;
+    const { teams } = await this.api<any>('GET', '/team');
+    if (teams?.length === 1) return (this.workspaceId = String(teams[0].id));
+    const options = (teams || []).map((t: any) => `${t.id} — ${t.name}`).join('; ');
+    throw new Error(`❌ ${teams?.length ?? 0} Workspaces visíveis; defina CLICKUP_WORKSPACE_ID (${options})`);
+  }
 
-    if (this.useMcp) {
-      // Via MCP
-      const result = await mcp_ClickUp_clickup_create_task({
-        workspace_id: this.workspaceId,
-        list_id: listId,
-        ...payload
-      });
-      return this.normalizeTask(JSON.parse(result.content[0].text));
-    }
+  /** Query de custom task ID (DEV-42) — vazia para id interno. */
+  private async idq(taskId: string, prefix: '?' | '&' = '?'): Promise<string> {
+    return /^[A-Z][A-Z0-9_]*-\d+$/.test(taskId)
+      ? prefix + new URLSearchParams({ custom_task_ids: 'true', team_id: await this.ws() }) : '';
+  }
+
+  // ═══════════════════════ CRUD ═══════════════════════
 
-    // Via API (padrão)
-    const data = await this.api<any>('POST', `/list/${listId}/task`, payload);
-    return this.normalizeTask(data);
+  async createTask(input: CreateTaskInput): Promise<TaskOutput> {
+    const listId = input.projectId || this.config.defaultListId;
+    if (!listId) throw new Error('❌ projectId ou CLICKUP_DEFAULT_LIST_ID obrigatório (ver getProjectList())');
+    const payload = await this.toCreatePayload(input, listId);
+    const created = await this.viaMcpOr('clickup_create_task', { list_id: listId, ...payload },
+      () => this.api<any>('POST', `/list/${listId}/task`, payload), (r) => r);
+    await this.applyCustomFields(created.id, input.customFields);   // por nome, pós-criação
+    return this.normalizeTask(created);
   }
 
-  async getTask(taskId: string): Promise<TaskOutput> {
-    if (this.useMcp) {
-      const result = await mcp_ClickUp_clickup_get_task({
-        workspace_id: this.workspaceId,
-        task_id: taskId,
-        subtasks: true
-      });
-      return this.normalizeTask(JSON.parse(result.content[0].text));
+  async getTask(taskId: string, opts?: GetTaskOptions): Promise<TaskOutput> {
+    const sub = opts?.includeSubtasks ? '&include_subtasks=true' : '';
+    const path = `/task/${taskId}?include_markdown_description=true${sub}${await this.idq(taskId, '&')}`;
+    let raw = await this.viaMcpOr('clickup_get_task', { task_id: taskId, subtasks: !!opts?.includeSubtasks },
+      () => this.api<any>('GET', path), (r) => r);
+    // C_GET_TASK_SUBTASKS_PARAM (ABERTA): se include_subtasks não trouxe a chave, tenta o legado 1x
+    if (opts?.includeSubtasks && raw.subtasks === undefined) {
+      console.warn('[clickup] include_subtasks sem efeito; tentando subtasks=true (registre o resultado)');
+      raw = await this.api<any>('GET', path.replace('include_subtasks=true', 'subtasks=true'));
     }
-
-    const data = await this.api<any>('GET', `/task/${taskId}?subtasks=true`);
-    return this.normalizeTask(data);
+    return this.normalizeTask(raw);
   }
 
   async updateTask(taskId: string, updates: UpdateTaskInput): Promise<TaskOutput> {
-    const payload = {
+    const payload: Record<string, unknown> = strip({
       name: updates.name,
-      description: updates.description,
-      markdown_description: updates.markdownDescription,
-      status: updates.status ? this.mapStatusToClickUp(updates.status) : undefined,
-      priority: updates.priority ? this.mapPriorityToClickUp(updates.priority) : undefined,
-      due_date: updates.dueDate,
-      start_date: updates.startDate,
-      assignees: updates.assignees
-    };
-
-    if (this.useMcp) {
-      const result = await mcp_ClickUp_clickup_update_task({
-        workspace_id: this.workspaceId,
-        task_id: taskId,
-        ...payload
-      });
-      return this.normalizeTask(JSON.parse(result.content[0].text));
+      description: updates.markdownDescription ? undefined : updates.description,
+      markdown_content: updates.markdownDescription,          // ← não markdown_description
+      status: updates.status ? await this.mapStatusToClickUp(updates.status, taskId) : undefined,
+      priority: updates.priority ? PRIORITY_TO_CLICKUP[updates.priority] : undefined,
+      due_date: toMs(updates.dueDate),                         // null limpa a data
+      start_date: toMs(updates.startDate),
+      time_estimate: updates.timeEstimate != null ? updates.timeEstimate * 60_000 : undefined,
+      points: updates.points,
+      custom_item_id: updates.taskType != null ? await this.resolveTaskType(updates.taskType) : undefined
+    });
+    if (updates.assignees) {                                   // PUT exige {add, rem}
+      const current = await this.getTask(taskId);
+      const want = new Set(updates.assignees.map(String));
+      const have = new Set(current.assignees.map((a) => a.id));
+      payload.assignees = {
+        add: [...want].filter((id) => !have.has(id)).map(Number),
+        rem: [...have].filter((id) => !want.has(id)).map(Number)
+      };
     }
-
-    const data = await this.api<any>('PUT', `/task/${taskId}`, payload);
-    return this.normalizeTask(data);
+    const q = await this.idq(taskId);
+    let raw = Object.keys(payload).length
+      ? await this.viaMcpOr('clickup_update_task', { task_id: taskId, ...payload },
+          () => this.api<any>('PUT', `/task/${taskId}${q}`, payload), (r) => r)
+      : undefined;
+    if (updates.tags) await this.syncTags(taskId, updates.tags);   // tags NÃO vão no PUT
+    await this.applyCustomFields(taskId, updates.customFields);
+    if (updates.tags || updates.customFields || !raw) return this.getTask(taskId);
+    return this.normalizeTask(raw);
   }
 
-  async deleteTask(taskId: string): Promise<boolean> {
-    try {
-      if (this.useMcp) {
-        await mcp_ClickUp_clickup_delete_task({
-          workspace_id: this.workspaceId,
-          task_id: taskId
-        });
-        return true;
-      }
-
-      await this.api('DELETE', `/task/${taskId}`);
-      return true;
-    } catch {
-      return false;
-    }
+  async deleteTask(taskId: string): Promise<boolean> {     // sempre API: C_MCP_DELETE_TOOL_INCONSISTENT
+    try { await this.api('DELETE', `/task/${taskId}${await this.idq(taskId)}`); return true; }
+    catch { return false; }
   }
 
-  // ═══════════════════════════════════════════════════════════════════════════
-  // SUBTASKS
-  // ═══════════════════════════════════════════════════════════════════════════
+  // ═══════════════════════ SUBTASKS ═══════════════════════
 
   async createSubtask(parentId: string, input: CreateTaskInput): Promise<TaskOutput> {
-    const parentTask = await this.getTask(parentId);
-    const listId = parentTask.projectId || this.defaultListId;
-
-    const payload = {
-      name: input.name,
-      description: input.description,
-      markdown_description: input.markdownDescription,
-      priority: this.mapPriorityToClickUp(input.priority),
-      tags: input.tags,
-      parent: parentId   // ← Torna subtask
-    };
-
-    if (this.useMcp) {
-      const result = await mcp_ClickUp_clickup_create_task({
-        workspace_id: this.workspaceId,
-        list_id: listId,
-        ...payload
-      });
-      return this.normalizeTask(JSON.parse(result.content[0].text));
-    }
-
-    const data = await this.api<any>('POST', `/list/${listId}/task`, payload);
-    return this.normalizeTask(data);
+    const parent = await this.getTask(parentId);
+    const listId = parent.projectId;                 // E_TASK_PARENT_SUBTASK: mesma List do pai
+    if (!listId) throw new Error(`❌ não achei a List da task pai ${parentId}`);
+    // propaga TODOS os campos (assignees, datas, estimativa, points, tipo), não só nome/tags
+    const payload = { ...(await this.toCreatePayload(input, listId)), parent: parent.id };
+    const created = await this.viaMcpOr('clickup_create_task', { list_id: listId, ...payload },
+      () => this.api<any>('POST', `/list/${listId}/task`, payload), (r) => r);
+    await this.applyCustomFields(created.id, input.customFields);
+    return this.normalizeTask(created);
   }
 
   async getSubtasks(parentId: string): Promise<TaskOutput[]> {
-    const task = await this.getTask(parentId);
-    return task.subtasks || [];
+    return (await this.getTask(parentId, { includeSubtasks: true })).subtasks ?? [];
   }
 
-  // ═══════════════════════════════════════════════════════════════════════════
-  // COMENTÁRIOS
-  // ═══════════════════════════════════════════════════════════════════════════
+  // ═══════════════════════ COMENTÁRIOS ═══════════════════════
 
   async addComment(taskId: string, comment: string): Promise<CommentOutput> {
-    if (this.useMcp) {
-      const result = await mcp_ClickUp_clickup_create_task_comment({
-        workspace_id: this.workspaceId,
-        task_id: taskId,
-        comment_text: comment
-      });
-      const data = JSON.parse(result.content[0].text);
-      return this.normalizeComment(data.comment || data, comment);
-    }
-
-    const data = await this.api<any>('POST', `/task/${taskId}/comment`, {
-      comment_text: comment,
-      notify_all: false
-    });
-    return this.normalizeComment(data, comment);
+    const body = { comment_text: comment, notify_all: false };  // notify_all: só o criador
+    const raw = await this.viaMcpOr('clickup_create_task_comment', { task_id: taskId, comment_text: comment },
+      async () => this.api<any>('POST', `/task/${taskId}/comment${await this.idq(taskId)}`, body), (r) => r);
+    return this.normalizeComment(raw.comment ?? raw, comment);
   }
 
   async getComments(taskId: string): Promise<CommentOutput[]> {
-    if (this.useMcp) {
-      const result = await mcp_ClickUp_clickup_get_task_comments({
-        workspace_id: this.workspaceId,
-        task_id: taskId
-      });
-      const data = JSON.parse(result.content[0].text);
-      return (data.comments || []).map((c: any) => this.normalizeComment(c, c.comment_text || c.comment));
-    }
-
-    const data = await this.api<any>('GET', `/task/${taskId}/comment`);
-    return (data.comments || []).map((c: any) => this.normalizeComment(c, c.comment_text || c.comment));
+    const raw = await this.viaMcpOr('clickup_get_task_comments', { task_id: taskId },
+      async () => this.api<any>('GET', `/task/${taskId}/comment${await this.idq(taskId)}`), (r) => r);
+    return (raw.comments ?? []).map((c: any) => this.normalizeComment(c, c.comment_text ?? ''));
   }
 
-  // ═══════════════════════════════════════════════════════════════════════════
-  // STATUS
-  // ═══════════════════════════════════════════════════════════════════════════
-
-  async updateStatus(taskId: string, status: TaskStatus): Promise<TaskOutput> {
-    return this.updateTask(taskId, { status });
-  }
+  async updateStatus(taskId: string, status: TaskStatus): Promise<TaskOutput> { return this.updateTask(taskId, { status }); }
 
-  // ═══════════════════════════════════════════════════════════════════════════
-  // BUSCA
-  // ═══════════════════════════════════════════════════════════════════════════
+  // ═══════════════════════ BUSCA ═══════════════════════
 
   async searchTasks(query: SearchQuery): Promise<TaskOutput[]> {
-    if (!this.workspaceId) {
-      throw new Error('❌ CLICKUP_WORKSPACE_ID obrigatório para busca');
+    const limit = query.limit ?? 50;
+    if (this.useMcp && query.text) {                 // único caminho com texto server-side
+      try {
+        const r = await callMcpTool(`mcp__${this.config.mcpServerName ?? 'clickup'}__clickup_search_workspace`,
+          { keywords: query.text });
+        const ids = (JSON.parse(r.content[0].text).results ?? [])
+          .filter((x: any) => x.type === 'task').slice(0, limit).map((x: any) => x.id);
+        // resultado de busca é RASO: hidrata com getTask (não inventa status 'todo' como a 2.0)
+        return Promise.all(ids.map((id: string) => this.getTask(id)));
+      } catch (e) { console.warn('[clickup] clickup_search_workspace falhou, usando API'); }
     }
-
-    if (this.useMcp) {
-      const result = await mcp_ClickUp_clickup_search({
-        workspace_id: this.workspaceId,
-        keywords: query.text,
-        filters: { asset_types: ['task'] }
-      });
-      const data = JSON.parse(result.content[0].text);
-      return (data.results || [])
-        .filter((r: any) => r.type === 'task')
-        .slice(0, query.limit || 50)
-        .map((r: any) => this.normalizeSearchResult(r));
+    const ws = await this.ws();
+    const p = new URLSearchParams();
+    (query.status ?? []).forEach((s) => p.append('statuses[]', STATUS_TO_CLICKUP_DEFAULT[s]));
+    if (query.assignee) p.append('assignees[]', query.assignee);
+    (query.tags ?? []).forEach((t) => p.append('tags[]', t));
+    if (query.projectId) p.append('list_ids[]', query.projectId);
+    if (query.orderBy && query.orderBy !== 'priority') p.set('order_by', query.orderBy);
+    if (query.orderDirection === 'asc') p.set('reverse', 'true');
+    if (query.status?.some((s) => ['done', 'closed', 'canceled'].includes(s))) p.set('include_closed', 'true');
+    p.set('subtasks', 'true');                       // E_TASK_FILTERED_AND_GET_PARAMS: default exclui
+
+    const offset = query.offset ?? 0;
+    let page = Math.floor(offset / 100);             // 100 por página, page começa em 0
+    let skip = offset % 100;
+    const out: TaskOutput[] = [];
+    const MAX_PAGES = 10;                            // teto honesto: ~1.000 tasks varridas
+    for (let n = 0; n < MAX_PAGES && out.length < limit; n++, page++) {
+      p.set('page', String(page));
+      const { tasks = [], last_page } = await this.api<any>('GET', `/team/${ws}/task?${p}`);
+      for (const t of tasks.slice(skip)) {
+        const task = this.normalizeTask(t);
+        if (query.priority && !(task.priority && query.priority.includes(task.priority))) continue;
+        if (query.text && !matchesText(task, query.text)) continue;   // filtro no CLIENTE
+        out.push(task);
+      }
+      skip = 0;
+      if (last_page || tasks.length < 100) break;
     }
-
-    // REST API: GET /team/{workspace_id}/task
-    const params = new URLSearchParams({
-      page: '0',
-      ...(query.text ? { search_text: query.text } : {}),
-      ...(query.limit ? { page_size: String(query.limit) } : {})
-    });
-
-    const data = await this.api<any>('GET', `/team/${this.workspaceId}/task?${params}`);
-    return (data.tasks || []).map((t: any) => this.normalizeTask(t));
+    if (query.orderBy === 'priority') out.sort(byPriority(query.orderDirection));
+    return out.slice(0, limit);
   }
 
-  // ═══════════════════════════════════════════════════════════════════════════
-  // PROJETOS / LISTAS
-  // ═══════════════════════════════════════════════════════════════════════════
+  // ═══════════════════════ PROJETOS (Lists) ═══════════════════════
 
   async getProjectList(): Promise<ProjectOutput[]> {
-    if (!this.workspaceId) {
-      throw new Error('❌ CLICKUP_WORKSPACE_ID obrigatório para listar projetos');
-    }
-
-    const projects: ProjectOutput[] = [];
-
-    if (this.useMcp) {
-      const result = await mcp_ClickUp_clickup_get_workspace_hierarchy({
-        workspace_id: this.workspaceId,
-        max_depth: 2
-      });
-      const data = JSON.parse(result.content[0].text);
-      return this.extractProjectsFromHierarchy(data);
-    }
-
-    // REST API: listar spaces → folders → lists
-    const spacesData = await this.api<any>('GET', `/team/${this.workspaceId}/space?archived=false`);
-
-    for (const space of spacesData.spaces || []) {
-      // Listas dentro de folders
-      const foldersData = await this.api<any>('GET', `/space/${space.id}/folder?archived=false`);
-      for (const folder of foldersData.folders || []) {
-        const listsData = await this.api<any>('GET', `/folder/${folder.id}/list?archived=false`);
-        for (const list of listsData.lists || []) {
-          projects.push({
-            id: list.id,
-            name: `${space.name} / ${folder.name} / ${list.name}`,
-            workspaceId: this.workspaceId
-          });
-        }
-      }
-      // Listas sem folder (folderless)
-      const folderlessData = await this.api<any>('GET', `/space/${space.id}/list?archived=false`);
-      for (const list of folderlessData.lists || []) {
-        projects.push({
-          id: list.id,
-          name: `${space.name} / ${list.name}`,
-          workspaceId: this.workspaceId
-        });
+    const ws = await this.ws();                      // auto-detect, não erro (bug 11 da 2.0)
+    const out: ProjectOutput[] = [];
+    const { spaces = [] } = await this.api<any>('GET', `/team/${ws}/space?archived=false`);
+    for (const space of spaces) {
+      const { folders = [] } = await this.api<any>('GET', `/space/${space.id}/folder?archived=false`);
+      for (const folder of folders) {
+        const { lists = [] } = await this.api<any>('GET', `/folder/${folder.id}/list?archived=false`);
+        lists.forEach((l: any) => out.push({ id: l.id, name: `${space.name} / ${folder.name} / ${l.name}`, workspaceId: ws }));
       }
+      const { lists = [] } = await this.api<any>('GET', `/space/${space.id}/list?archived=false`);
+      lists.forEach((l: any) => out.push({ id: l.id, name: `${space.name} / ${l.name}`, workspaceId: ws }));
     }
-
-    return projects;
+    return out;
   }
 
   async getProject(projectId: string): Promise<ProjectOutput> {
-    if (this.useMcp) {
-      const result = await mcp_ClickUp_clickup_get_list({
-        workspace_id: this.workspaceId,
-        list_id: projectId
-      });
-      const data = JSON.parse(result.content[0].text);
-      return { id: data.id, name: data.name, description: data.content, workspaceId: this.workspaceId };
-    }
-
-    const data = await this.api<any>('GET', `/list/${projectId}`);
-    return { id: data.id, name: data.name, description: data.content, workspaceId: this.workspaceId };
+    const l = await this.api<any>('GET', `/list/${projectId}`);
+    this.statusCache.set(l.id, (l.statuses ?? []).map((s: any) => String(s.status).toLowerCase()));
+    return { id: l.id, name: l.name, description: l.content, archived: l.archived,
+             url: `https://app.clickup.com/${await this.ws()}/v/li/${l.id}`, workspaceId: await this.ws() };
   }
 
-  // ═══════════════════════════════════════════════════════════════════════════
-  // VALIDAÇÃO
-  // ═══════════════════════════════════════════════════════════════════════════
+  // ═══════════════════════ VALIDAÇÃO ═══════════════════════
 
   validateTaskId(taskId: string): boolean {
-    // ClickUp IDs: 9 caracteres alfanuméricos
-    return /^[a-z0-9]{9}$/i.test(taskId);
+    // id interno: 9 alfanuméricos (detector.md). Custom task ID (DEV-42) também é válido AQUI,
+    // porque este adapter só é instanciado com TASK_MANAGER_PROVIDER=clickup.
+    return /^[a-z0-9]{9}$/i.test(taskId) || /^[A-Z][A-Z0-9_]*-\d+$/.test(taskId);
   }
 
   getProviderFromTaskId(taskId: string): TaskManagerProvider | null {
-    return this.validateTaskId(taskId) ? 'clickup' : null;
+    // PREFIX-NUM é ambíguo (Jira/Linear): só o id interno identifica o ClickUp sozinho
+    return /^[a-z0-9]{9}$/i.test(taskId) ? 'clickup' : null;
   }
 
-  // ═══════════════════════════════════════════════════════════════════════════
-  // HELPERS PRIVADOS
-  // ═══════════════════════════════════════════════════════════════════════════
+  // ═══════════════════════ CAPABILITIES ═══════════════════════
 
-  private normalizeTask(raw: any): TaskOutput {
-    return {
-      id: raw.id,
-      provider: 'clickup',
-      name: raw.name,
-      description: raw.text_content || raw.description || '',
-      status: this.normalizeStatus(raw.status?.status),
-      statusRaw: raw.status?.status,
-      statusColor: raw.status?.color,
-      priority: this.normalizePriority(raw.priority?.priority),
-      url: raw.url,
-      createdAt: new Date(parseInt(raw.date_created)).toISOString(),
-      updatedAt: new Date(parseInt(raw.date_updated)).toISOString(),
-      dueDate: raw.due_date ? new Date(parseInt(raw.due_date)).toISOString() : undefined,
-      startDate: raw.start_date ? new Date(parseInt(raw.start_date)).toISOString() : undefined,
-      assignees: (raw.assignees || []).map((a: any) => ({
-        id: String(a.id),
-        name: a.username,
-        email: a.email
-      })),
-      tags: (raw.tags || []).map((t: any) => t.name),
-      subtasks: raw.subtasks?.map((st: any) => this.normalizeTask(st)),
-      parent: raw.parent || undefined,
-      projectId: raw.list?.id,
-      projectName: raw.list?.name,
-      timeEstimate: raw.time_estimate ? Math.round(raw.time_estimate / 60000) : undefined,
-      timeSpent: raw.time_spent ? Math.round(raw.time_spent / 60000) : undefined
-    };
+  async addTag(taskId: string, tag: string): Promise<void> {
+    await this.viaMcpOr('clickup_add_tag_to_task', { task_id: taskId, tag_name: tag },
+      async () => this.api('POST', `/task/${taskId}/tag/${encodeURIComponent(tag)}${await this.idq(taskId)}`),
+      () => undefined);
   }
 
-  private normalizeComment(raw: any, text: string): CommentOutput {
-    return {
-      id: String(raw.id),
-      text,
-      author: {
-        id: String(raw.user?.id || 'unknown'),
-        name: raw.user?.username || 'Unknown'
-      },
-      createdAt: raw.date ? new Date(parseInt(raw.date)).toISOString() : new Date().toISOString()
-    };
+  async removeTag(taskId: string, tag: string): Promise<void> {   // só API
+    await this.api('DELETE', `/task/${taskId}/tag/${encodeURIComponent(tag)}${await this.idq(taskId)}`);
   }
 
-  private normalizeSearchResult(raw: any): TaskOutput {
-    return {
-      id: raw.id,
-      provider: 'clickup',
-      name: raw.name,
-      description: raw.description || '',
-      status: 'todo',
-      url: raw.url || `https://app.clickup.com/t/${raw.id}`,
-      createdAt: new Date().toISOString(),
-      updatedAt: new Date().toISOString(),
-      assignees: [],
-      tags: []
-    };
+  async createChecklist(taskId: string, name: string, items: string[] = []): Promise<ChecklistOutput> {
+    const { checklist } = await this.api<any>('POST', `/task/${taskId}/checklist${await this.idq(taskId)}`, { name });
+    let last = checklist;
+    for (const item of items) {                      // sequencial: cada POST devolve o checklist inteiro
+      last = (await this.api<any>('POST', `/checklist/${checklist.id}/checklist_item`, { name: item })).checklist ?? last;
+    }
+    return this.normalizeChecklist(last);
   }
 
-  private extractProjectsFromHierarchy(data: any): ProjectOutput[] {
-    const projects: ProjectOutput[] = [];
-    for (const space of data.spaces || []) {
-      for (const folder of space.folders || []) {
-        for (const list of folder.lists || []) {
-          projects.push({
-            id: list.id,
-            name: `${space.name} / ${folder.name} / ${list.name}`,
-            workspaceId: this.workspaceId
-          });
-        }
-      }
-      for (const list of space.lists || []) {
-        projects.push({
-          id: list.id,
-          name: `${space.name} / ${list.name}`,
-          workspaceId: this.workspaceId
-        });
+  async setChecklistItem(checklistId: string, itemId: string, resolved: boolean): Promise<void> {
+    // Edit Checklist Item: NÃO ANCORADO nesta rodada (E_LACUNAS_CLICKUP_2026_10)
+    await this.api('PUT', `/checklist/${checklistId}/checklist_item/${itemId}`, { resolved });
+  }
+
+  async setCustomField(taskId: string, fieldName: string, value: unknown): Promise<void> {
+    const task = await this.api<any>('GET', `/task/${taskId}${await this.idq(taskId)}`);
+    const fields = await this.listFields(task.list.id);
+    const field = fields.find((f) => f.name.toLowerCase() === fieldName.toLowerCase());
+    if (!field) {
+      // Sprint Points nativo: 'Story Points'/'Sprint Points' sem campo homônimo → PUT points
+      if (/^(story|sprint)?\s*points$/i.test(fieldName) && typeof value === 'number') {
+        await this.api('PUT', `/task/${taskId}${await this.idq(taskId)}`, { points: value });
+        return;
       }
+      throw new ClickUpApiError(404, 'POST', `field:${fieldName}`, 'FIELD_NOT_FOUND');
     }
-    return projects;
-  }
-
-  private normalizeStatus(clickupStatus?: string): TaskStatus {
-    const statusMap: Record<string, TaskStatus> = {
-      'backlog': 'backlog',
-      'bakclog': 'backlog',   // typo comum no ClickUp
-      'to do': 'todo',
-      'open': 'todo',
-      'in progress': 'in_progress',
-      'in review': 'review',
-      'review': 'review',
-      'done': 'done',
-      'complete': 'done',
-      'closed': 'closed'
-    };
-    return statusMap[clickupStatus?.toLowerCase() || ''] || 'todo';
-  }
-
-  private mapStatusToClickUp(status: TaskStatus): string {
-    const statusMap: Record<TaskStatus, string> = {
-      'backlog': 'backlog',
-      'todo': 'to do',
-      'in_progress': 'in progress',
-      'review': 'review',
-      'done': 'done',
-      'closed': 'closed',
-      'canceled': 'closed'
-    };
-    return statusMap[status] || 'to do';
+    const scoped = (field.applied_objects ?? []).filter((o: any) => o.object_type === 19);
+    if (scoped.length && !scoped.some((o: any) => String(o.object_id) === String(task.custom_item_id ?? 0))) {
+      throw new Error(`❌ campo "${field.name}" não vale para o tipo desta task ` +
+                      `(custom_item_id=${task.custom_item_id ?? 0}); a API devolveria 400`);
+    }
+    await this.api('POST', `/task/${task.id}/field/${field.id}`, { value: this.formatFieldValue(field, value) });
   }
 
-  private normalizePriority(clickupPriority?: string): TaskPriority | undefined {
-    const priorityMap: Record<string, TaskPriority> = {
-      '1': 'urgent', 'urgent': 'urgent',
-      '2': 'high',   'high': 'high',
-      '3': 'normal', 'normal': 'normal',
-      '4': 'low',    'low': 'low'
-    };
-    return priorityMap[clickupPriority?.toLowerCase() || ''];
-  }
+  // ═══════════════════════ HELPERS ═══════════════════════
 
-  private mapPriorityToClickUp(priority?: TaskPriority): string | undefined {
-    if (!priority) return undefined;
-    const priorityMap: Record<TaskPriority, string> = {
-      'urgent': 'urgent',
-      'high': 'high',
-      'normal': 'normal',
-      'low': 'low'
-    };
-    return priorityMap[priority];
+  private async toCreatePayload(input: CreateTaskInput, listId: string) {
+    return strip({
+      name: input.name,
+      description: input.markdownDescription ? undefined : input.description,
+      markdown_content: input.markdownDescription,            // E_TASK_MARKDOWN_CONTENT_PRECEDENCE
+      status: input.status ? await this.mapStatusToClickUp(input.status, undefined, listId) : undefined,
+      priority: input.priority ? PRIORITY_TO_CLICKUP[input.priority] : undefined,   // 1–4
+      due_date: toMs(input.dueDate),
+      start_date: toMs(input.startDate),
+      assignees: input.assignees?.map(Number),                // create: array de ids
+      tags: input.tags,
+      time_estimate: input.timeEstimate != null ? input.timeEstimate * 60_000 : undefined,
+      points: input.points,
+      custom_item_id: input.taskType != null ? await this.resolveTaskType(input.taskType) : undefined
+    });
   }
-}
-```
-
----
 
-## 📊 Mapeamento de Campos
-
-### Task Fields
-
-| Interface | ClickUp API | Notas |
-|-----------|-------------|-------|
-| `name` | `name` | Direto |
-| `description` | `description` | Texto plano |
-| `markdownDescription` | `markdown_description` | Com formatação |
-| `status` | `status.status` | Mapeado |
-| `priority` | `priority.priority` | Mapeado |
-| `dueDate` | `due_date` | Timestamp ms |
-| `assignees` | `assignees[].id` | Array de IDs |
-| `tags` | `tags[].name` | Array de strings |
-| `projectId` | `list.id` | ID da lista |
-
-### Status Mapping
-
-| Interface | ClickUp |
-|-----------|---------|
-| `backlog` | "backlog" |
-| `todo` | "to do" |
-| `in_progress` | "in progress" |
-| `review` | "review" |
-| `done` | "done" |
-| `closed` | "closed" |
+  private async syncTags(taskId: string, wanted: string[]) {      // substitui (contrato UpdateTaskInput.tags)
+    const current = (await this.getTask(taskId)).tags;
+    for (const t of wanted.filter((t) => !current.includes(t))) await this.addTag(taskId, t);
+    for (const t of current.filter((t) => !wanted.includes(t))) await this.removeTag(taskId, t);
+  }
 
----
+  private async applyCustomFields(taskId: string, fields?: Record<string, unknown>) {
+    for (const [name, value] of Object.entries(fields ?? {})) {
+      try { await this.setCustomField(taskId, name, value); }
+      catch (e) { console.warn(`[clickup] custom field "${name}" não setado: ${(e as Error).message}`); }
+    }
+  }
 
-## 💬 Formatação de Conteúdo
+  private async listFields(listId: string): Promise<any[]> {
+    if (!this.fieldCache.has(listId)) {
+      this.fieldCache.set(listId, (await this.api<any>('GET', `/list/${listId}/field`)).fields ?? []);
+    }
+    return this.fieldCache.get(listId)!;
+  }
 
-A formatação é específica do ClickUp e **independente do transporte escolhido** (API ou MCP).
+  /** E_CF_VALUE_FORMATS: Dropdown = UUID da opção; Date = Unix ms; Money = só o número. */
+  private formatFieldValue(field: any, value: unknown): unknown {
+    switch (field.type) {
+      case 'drop_down': {
+        const opt = (field.type_config?.options ?? [])
+          .find((o: any) => o.id === value || String(o.name).toLowerCase() === String(value).toLowerCase());
+        if (!opt) throw new Error(`❌ opção "${value}" inexistente no dropdown "${field.name}"`);
+        return opt.id;
+      }
+      case 'date': return toMs(String(value));
+      case 'currency': case 'number': return Number(value);
+      case 'checkbox': return Boolean(value);
+      default: return value;              // labels/users/etc.: passa cru (formato NÃO ANCORADO)
+    }
+  }
 
-### Descrições de Tasks (`markdown_description`)
+  /** '0' Task, '1' Milestone, outros = tipos do Workspace (E_CTT_DEFAULT_VALUES). */
+  private async resolveTaskType(taskType: string): Promise<number> {
+    if (/^\d+$/.test(taskType)) return Number(taskType);
+    if (/^task$/i.test(taskType)) return 0;
+    if (/^milestone$/i.test(taskType)) return 1;
+    // lookup por nome: GET /team/{ws}/custom_item — path NÃO ANCORADO (claim rejeitada na rodada)
+    const { custom_items = [] } = await this.api<any>('GET', `/team/${await this.ws()}/custom_item`);
+    const hit = custom_items.find((c: any) => String(c.name).toLowerCase() === taskType.toLowerCase());
+    if (!hit) throw new Error(`❌ tipo de task "${taskType}" inexistente no Workspace`);
+    return Number(hit.id);
+  }
 
-Use Markdown nativo:
+  /** Status por nome da List: usa o nome canônico se a List o tiver; senão o fallback. */
+  private async mapStatusToClickUp(s: TaskStatus, taskId?: string, listId?: string): Promise<string> {
+    const lid = listId ?? (taskId ? (await this.api<any>('GET', `/task/${taskId}${await this.idq(taskId)}`)).list.id : undefined);
+    if (lid && !this.statusCache.has(lid)) await this.getProject(lid);
+    const names = lid ? this.statusCache.get(lid) ?? [] : [];
+    const candidates = STATUS_CANDIDATES[s];            // ex.: canceled → ['canceled','cancelled','closed']
+    return candidates.find((c) => names.includes(c)) ?? STATUS_TO_CLICKUP_DEFAULT[s];
+  }
 
-```markdown
-## Objetivo
-Implementar funcionalidade X conforme spec.
+  private normalizeTask(raw: any): TaskOutput {
+    const customFields: CustomFieldOutput[] = (raw.custom_fields ?? []).map((f: any) => ({
+      id: f.id, name: f.name, type: f.type, value: normalizeFieldValue(f)
+    }));
+    if (raw.points != null && !customFields.some((f) => /^(story|sprint) points$/i.test(f.name))) {
+      // compat com story-points-gate (lê customFields 'Story Points'): expõe o nativo também
+      customFields.push({ id: 'points', name: 'Story Points', type: 'sprint_points', value: raw.points });
+    }
+    return {
+      id: raw.id, provider: 'clickup', name: raw.name,
+      description: raw.markdown_description ?? raw.text_content ?? raw.description ?? '',
+      status: normalizeStatus(raw.status?.status), statusRaw: raw.status?.status, statusColor: raw.status?.color,
+      priority: PRIORITY_FROM_CLICKUP[String(raw.priority?.priority ?? raw.priority?.id ?? '').toLowerCase()],
+      url: raw.url ?? `https://app.clickup.com/t/${raw.id}`,
+      createdAt: msToIso(raw.date_created)!, updatedAt: msToIso(raw.date_updated)!,
+      dueDate: msToIso(raw.due_date), startDate: msToIso(raw.start_date),
+      assignees: (raw.assignees ?? []).map((a: any) => ({ id: String(a.id), name: a.username, email: a.email })),
+      tags: (raw.tags ?? []).map((t: any) => t.name),
+      subtasks: raw.subtasks?.map((st: any) => this.normalizeTask(st)),
+      parent: raw.parent ?? undefined, projectId: raw.list?.id, projectName: raw.list?.name,
+      timeEstimate: raw.time_estimate ? Math.round(raw.time_estimate / 60_000) : undefined,
+      timeSpent: raw.time_spent ? Math.round(raw.time_spent / 60_000) : undefined,
+      points: raw.points ?? undefined,
+      checklists: raw.checklists?.map((c: any) => this.normalizeChecklist(c)),
+      customFields
+    };
+  }
 
-## Critérios de Aceite
-- [ ] Comportamento A funciona
-- [ ] Cobertura de testes ≥ 80%
+  private normalizeChecklist(c: any): ChecklistOutput {
+    const items = (c.items ?? []).map((i: any) => ({ id: i.id, name: i.name, resolved: !!i.resolved }));
+    const resolved = items.filter((i) => i.resolved).length;
+    return { id: c.id, name: c.name, items, resolved, unresolved: items.length - resolved };
+  }
 
-| Campo | Valor |
-|-------|-------|
-| Sprint | 12 |
-| Story Points | 5 |
+  private normalizeComment(raw: any, text: string): CommentOutput {
+    return { id: String(raw.id), text, createdAt: msToIso(raw.date) ?? new Date().toISOString(),
+             author: { id: String(raw.user?.id ?? 'unknown'), name: raw.user?.username ?? 'Unknown' } };
+  }
+}
 ```
 
-### Comentários (`comment_text`)
+### Tabelas e funções puras usadas acima
 
-Use formatação visual Unicode para legibilidade nos feeds do ClickUp:
+```typescript
+const PRIORITY_TO_CLICKUP: Record<TaskPriority, number> = { urgent: 1, high: 2, normal: 3, low: 4 };
+const PRIORITY_FROM_CLICKUP: Record<string, TaskPriority> = { '1': 'urgent', urgent: 'urgent',
+  '2': 'high', high: 'high', '3': 'normal', normal: 'normal', '4': 'low', low: 'low' };
+const STATUS_TO_CLICKUP_DEFAULT: Record<TaskStatus, string> = {
+  backlog: 'backlog', todo: 'to do', in_progress: 'in progress', review: 'review',
+  done: 'done', closed: 'closed', canceled: 'closed'
+};
+const STATUS_CANDIDATES: Record<TaskStatus, string[]> = {
+  backlog: ['backlog', 'to do', 'open'], todo: ['to do', 'open'], in_progress: ['in progress'],
+  review: ['review', 'in review'], done: ['done', 'complete', 'closed'], closed: ['closed', 'done'],
+  canceled: ['canceled', 'cancelled', 'closed']
+};
+
+function normalizeStatus(raw?: string): TaskStatus {
+  const s = (raw ?? '').toLowerCase().trim();
+  const map: Record<string, TaskStatus> = {
+    backlog: 'backlog', 'to do': 'todo', open: 'todo',
+    'in progress': 'in_progress', blocked: 'in_progress', 'on hold': 'in_progress',   // statusRaw preserva
+    review: 'review', 'in review': 'review', done: 'done', complete: 'done', closed: 'closed',
+    canceled: 'canceled', cancelled: 'canceled'
+  };
+  return map[s] ?? 'todo';
+}
 
+const toMs = (d?: string | null) =>
+  d === null ? null : d ? new Date(d.length === 10 ? `${d}T12:00:00Z` : d).getTime() : undefined;
+const msToIso = (ms?: string | number | null) => (ms ? new Date(Number(ms)).toISOString() : undefined);
+const strip = (o: Record<string, unknown>) =>
+  Object.fromEntries(Object.entries(o).filter(([, v]) => v !== undefined));
+const matchesText = (t: TaskOutput, q: string) =>
+  `${t.name} ${t.description}`.toLowerCase().includes(q.toLowerCase());
+const byPriority = (dir?: 'asc' | 'desc') => (a: TaskOutput, b: TaskOutput) => {
+  const r = (PRIORITY_TO_CLICKUP[a.priority ?? 'low'] ?? 5) - (PRIORITY_TO_CLICKUP[b.priority ?? 'low'] ?? 5);
+  return dir === 'desc' ? -r : r;
+};
+function normalizeFieldValue(f: any): unknown {
+  if (f.value == null) return undefined;
+  if (f.type === 'date') return msToIso(f.value);
+  if (f.type === 'drop_down') {          // leitura pode vir como orderindex OU UUID: casa os dois
+    const o = (f.type_config?.options ?? []).find((x: any) => x.id === f.value || x.orderindex === Number(f.value));
+    return o?.name ?? f.value;
+  }
+  return f.value;
+}
 ```
-━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-▶ FASE CONCLUÍDA — Backend Implementation
-━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 
-◆ Arquivos modificados
-  ∟ src/auth/service.ts
-  ∟ src/auth/routes.ts
+`toMs` fixa meio-dia UTC para `YYYY-MM-DD`. Assim a data não "volta um dia" em fuso negativo.
 
-◆ Implementações
-  ✅ JWT auth
-  ✅ Refresh tokens
+---
 
-◆ Testes: cobertura 95%
+## 🔎 `searchTasks`: o que é suportado e o que não é
 
-▶ Próxima fase: Frontend Integration
-━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-🕐 2026-06-13T14:30:00Z
-```
+A REST usa **Get Filtered Team Tasks** (`GET /team/{team_id}/task`): 100 tasks por página, `page` a
+partir de 0, subtasks excluídas por padrão (`E_TASK_FILTERED_AND_GET_PARAMS`). Os nomes dos filtros
+`statuses[]`, `assignees[]`, `tags[]`, `list_ids[]`, `order_by`, `reverse` e `include_closed` são os do
+endpoint, mas **não foram ancorados verbatim** nesta rodada.
 
-**Regra**: todo comentário de progresso deve incluir timestamp e status atual.
+| `SearchQuery` | Como | Suporte |
+|---|---|---|
+| `status[]` | `statuses[]` com o nome **default** do status | ⚠️ List com status customizado pode não casar |
+| `assignee` | `assignees[]` (id numérico) | server-side |
+| `tags[]` | `tags[]` | server-side |
+| `projectId` | `list_ids[]` | server-side |
+| `orderBy` created/updated/due_date | `order_by` + `reverse` | server-side |
+| `orderBy: 'priority'` | ordena no cliente **o conjunto varrido** | ⚠️ parcial |
+| `priority[]` | filtro no cliente | ⚠️ parcial (dentro do teto) |
+| `text` | **API: filtro no cliente** sobre nome+descrição; **MCP: `clickup_search_workspace`** | ⚠️ API não tem busca textual server-side |
+| `limit` / `offset` | `offset` vira `page = ⌊offset/100⌋` + descarte; para em `limit` | server-side |
+
+**Teto declarado:** a varredura para em **10 páginas (~1.000 tasks)**. Passou disso, filtro de cliente
+(`text`, `priority`) pode **omitir** resultados. É o preço de não ter busca textual na REST. Para texto
+em Workspace grande, use `TASK_MANAGER_TRANSPORT=mcp`. Isto não se esconde: é declarado.
 
 ---
 
-## 🧪 Exemplos de Uso
-
-```typescript
-// Via Factory (transporte definido pelo .env)
-const tm = getTaskManager(); // Retorna ClickUpAdapter se configurado
-
-// Criar task
-const task = await tm.createTask({
-  name: 'Nova Feature',
-  markdownDescription: '## Objetivo\nImplementar funcionalidade X',
-  priority: 'high',
-  tags: ['feature', 'v2']
-});
-
-// Criar subtask
-const subtask = await tm.createSubtask(task.id, {
-  name: 'Fase 1: Setup'
-});
-
-// Atualizar status
-await tm.updateStatus(subtask.id, 'in_progress');
-
-// Adicionar comentário com formatação Unicode
-await tm.addComment(task.id, [
-  '━━━━━━━━━━━━━━━━━━━━━━━',
-  '▶ Desenvolvimento iniciado',
-  `🕐 ${new Date().toISOString()}`
-].join('\n'));
-```
+## 🧩 Custom fields, Sprint Points e tipos de task
+
+- **Escopo por tipo** (`C_CUSTOM_FIELDS_TYPE_SCOPED`): `GET /list/{id}/field` devolve `applied_objects`.
+  Com `object_type: 19`, `object_id` é o `custom_item_id` a que o campo se aplica. O adapter confere
+  **antes** do `POST` e lança erro claro em vez de deixar a API dar 400.
+- **Formatos** (`E_CF_VALUE_FORMATS`): Dropdown = UUID da opção (o adapter traduz nome → UUID); Date =
+  Unix ms; Money aceita só o valor (sem moeda); Button aceita `true`; Files exige anexo pela v3
+  (`E_CF_FILES_VIA_V3`, fora do escopo).
+- **Por nome**: `setCustomField(taskId, 'QA Story Points', 8)` e `updateTask(id, { customFields:
+  { 'Story Points': 5 } })` resolvem o id pelo nome, sem diferenciar maiúsculas, com cache por List.
+- **Sprint Points nativo** (`points`, `E_TASK_POINTS_LINKS_REQUIRED_FIELDS`): `CreateTaskInput.points` vai
+  direto. Na leitura, se não houver custom field "Story Points", o adapter expõe o nativo como
+  `customFields[{ name: 'Story Points' }]`. Assim o fragmento `story-points-gate` funciona sem saber de
+  provider. `setCustomField('Story Points', n)` sem campo homônimo escreve `points`.
+- **Tipo de task** (`taskType` → `custom_item_id`): `0` Task, `1` Milestone, demais = tipos do Workspace
+  (`E_CTT_DEFAULT_VALUES`). O lookup por nome usa `GET /team/{ws}/custom_item`, **NÃO ANCORADO**.
+- `check_required_custom_fields` (default `false`): o adapter **não** liga. Ligá-lo faria `createTask`
+  falhar em Lists com campo obrigatório que o Onion não conhece.
 
 ---
 
-## ⚡ Operações em Lote (Bulk)
-
-> Detalhe específico do ClickUp. Via abstração, o consumidor usa `createTask`/`createSubtask`; o adapter aplica internamente a regra abaixo.
-
-**Quando usar bulk:** criar múltiplas tasks **independentes no mesmo nível**; atualizar status de várias tasks.
+## ✅ Checklists nativos
 
-**Limitação crítica — bulk NÃO suporta hierarquia.** O endpoint de criação em lote **ignora** o `parent`. Para hierarquia (task → subtasks), use criação **sequencial** com `parent`:
+Checklist (resolved/unresolved, progresso visual) ≠ checkbox em markdown. O Onion usa os dois:
+checkboxes no `markdown_content` (documentação) e checklists nativos (tracking).
 
-```javascript
-// ❌ ERRADO — parent ignorado no bulk
-await create_bulk_tasks({ tasks: [{ name: 'Sub 1', parent: mainId }, { name: 'Sub 2', parent: mainId }] });
+```typescript
+const cl = await tm.createChecklist(subtaskId, 'Critérios de aceite', ['Login retorna JWT', 'Refresh funciona']);
+await tm.setChecklistItem(cl.id, cl.items[0].id, true);
 
-// ✅ CORRETO — sequencial preserva hierarquia
-const sub1 = await create_task({ name: 'Sub 1', parent: mainId });
-const sub2 = await create_task({ name: 'Sub 2', parent: mainId });
+const t = await tm.getTask(taskId, { includeSubtasks: true });   // progresso
+const all = [t, ...(t.subtasks ?? [])].flatMap((x) => x.checklists ?? []);
+const total = all.reduce((n, c) => n + c.resolved + c.unresolved, 0);
+const pct = total ? (all.reduce((n, c) => n + c.resolved, 0) / total) * 100 : 0;
 ```
 
-✅ bulk para: tasks independentes no mesmo nível · ❌ bulk para: hierarquia.
+⚠️ A forma do objeto `checklists[]` na leitura do Get Task (`id`, `name`, `items[{id,name,resolved}]`)
+vem da versão anterior deste adapter e **não foi re-ancorada**. O Edit Checklist Item também não.
 
 ---
 
-## 🏗️ Hierarquia de Tasks (3 níveis)
-
-```
-📋 TASK (objetivo de alto nível)
-├── 🔧 Subtask 1 (componente)
-│   ├── ✅ Checklist item 1.1
-│   └── ✅ Checklist item 1.2
-└── 🔧 Subtask 2
-    └── ✅ Checklist item 2.1
-```
+## 🗺️ Mapeamentos
+
+| Interface | ClickUp (escrita) | ClickUp (leitura) | Nota |
+|---|---|---|---|
+| `name` | `name` | `name` | |
+| `description` | `description` | `text_content` | só se não houver markdown |
+| `markdownDescription` | **`markdown_content`** | `markdown_description` (com `include_markdown_description=true`) | assimetria escrita × leitura |
+| `status` | nome do status da List | `status.status` | ver tabela abaixo |
+| `priority` | `1`–`4` | `priority.priority` | sem `medium` |
+| `dueDate` / `startDate` | Unix ms | Unix ms (string) | `null` limpa |
+| `assignees` | create: `[id]` · PUT: `{add, rem}` | `assignees[]` | ids numéricos |
+| `tags` | create: `tags[]` · depois: `POST/DELETE /tag/{name}` | `tags[].name` | |
+| `timeEstimate` (min) | `time_estimate` (ms) | `time_estimate` (ms) | ×/÷ 60 000 |
+| `points` | `points` | `points` | Sprint Points nativo |
+| `taskType` | `custom_item_id` | `custom_item_id` | |
+| `customFields` | `POST /task/{id}/field/{fid}` | `custom_fields[]` | por nome |
+| `projectId` | path `/list/{id}/task` | `list.id` | |
+
+### Status
+
+| Interface | escrita (default → se a List tiver) | leitura → interface |
+|---|---|---|
+| `backlog` | `backlog` | `backlog` |
+| `todo` | `to do` (ou `open`) | `to do`, `open` |
+| `in_progress` | `in progress` | `in progress`, **`blocked`**, `on hold` (com `statusRaw`) |
+| `review` | `review` (ou `in review`) | `review`, `in review` |
+| `done` | `done` (ou `complete`) | `done`, `complete` |
+| `closed` | `closed` | `closed` |
+| **`canceled`** | `canceled`/`cancelled` se a List tiver; senão `closed` | `canceled`, `cancelled` |
+
+Status são **por List**. O adapter lê `GET /list/{id}` → `statuses` (cache) e escolhe o primeiro
+candidato que existe. Status fora da tabela normaliza para `todo`, e o valor original fica em
+`statusRaw`. `blocked` não é status canônico do contrato (`TaskStatus`). Para marcar bloqueio, use a tag
+`blocked` ou o status customizado da List, e leia `statusRaw`.
 
-**Implementação correta** — transporte default = **REST API** do adapter (`create_task` mapeia para `POST /list/{id}/task`); o `mcp_ClickUp_*` é apenas o transporte **opcional** via `TASK_MANAGER_TRANSPORT=mcp`:
+---
 
-```javascript
-// 1. Task principal
-const mainTask = await create_task({
-  name: '🎯 Implementar Autenticação JWT',
-  listId: '<list_id>',
-  markdown_description: '## 🎯 Objetivo\nImplementar JWT...\n\n## ✅ Critérios\n- [ ] Login retorna JWT\n- [ ] Refresh funciona',
-  tags: ['feature', 'security'], priority: 'high'
-});
+## 💬 Formatação de conteúdo
 
-// 2. Subtasks com parent (← CRITICAL para hierarquia)
-const sub1 = await create_task({ name: '🔧 Backend JWT Service', listId: '<list_id>', parent: mainTask.id, tags: ['subtask', 'backend'] });
-const sub2 = await create_task({ name: '🔧 Frontend Integration', listId: '<list_id>', parent: mainTask.id, tags: ['subtask', 'frontend'] });
+Independente do transporte. A convenção de status de PR e os templates estão no fragmento
+[`clickup-patterns`](../../../commands/common/prompts/clickup-patterns.md).
 
-// 3. Comentário de setup (formatação Unicode — ver seção de Formatação)
-await create_task_comment({ task_id: mainTask.id, comment_text: '🚀 TASK SETUP COMPLETO\n━━━━━━━━━━━━\n▶ Subtasks: 2\n⏰ ' + new Date().toISOString() });
-```
+- **Descrição** (`markdown_content`): Markdown nativo, com headers, listas, `- [ ]` e tabelas.
+- **Comentário** (`comment_text`): **Unicode visual** (`━━━`, `▶`, `◆`, `∟`), sempre com timestamp e
+  status no rodapé (templates no fragmento). **Não se sabe** se markdown renderiza em comentário
+  (`C_COMMENTS_CHECKLISTS_CURRENT`), e por isso a convenção Unicode continua.
+- `notify_all: false` só decide se **o criador** do comentário é notificado. Assignees e watchers são
+  notificados de todo modo (`E_COMMENT_CREATE_NOTIFY_ALL`, `E_COMMENT_THREADED`).
 
 ---
 
-## ✅ Checklists Nativos
-
-Checklists nativos do ClickUp (diferentes de checkboxes em markdown) oferecem tracking interativo (resolved/unresolved), progresso visual e leitura via API. O Sistema Onion suporta estrutura híbrida: checkboxes em markdown (documentação) + checklists nativos (tracking).
+## ⚡ Bulk e hierarquia
 
-**Leitura e cálculo de progresso** (incluir `subtasks: true` no get para trazer checklists):
+O consumidor usa `createTask`/`createSubtask`, e o adapter aplica a regra:
 
-```javascript
-const task = await getTask({ task_id: '<id>', subtasks: true });
+- **Bulk** (`clickup_create_bulk_tasks` no MCP) serve para tasks **independentes no mesmo nível**.
+- **Bulk não preserva hierarquia:** o `parent` é ignorado no lote (prática observada, não re-ancorada).
+  Task → subtasks se cria **em sequência**, com `parent` e na mesma List (`E_TASK_PARENT_SUBTASK`). O pai
+  pode ser outra subtask.
 
-function calculateProgress(task) {
-  let total = 0, resolved = 0;
-  (task.checklists || []).forEach(c => { total += c.unresolved + c.resolved; resolved += c.resolved; });
-  return total > 0 ? (resolved / total * 100).toFixed(1) : 0;
-}
-// Progresso: `${calculateProgress(task)}%`
+```typescript
+const main = await tm.createTask({ name: '🎯 Autenticação JWT', projectId: listId, priority: 'high', points: 5,
+  markdownDescription: '## 🎯 Objetivo\n...\n\n## ✅ Critérios\n- [ ] Login retorna JWT', tags: ['feature'] });
+const s1 = await tm.createSubtask(main.id, { name: '🔧 Backend JWT', assignees: ['123'], dueDate: '2026-10-10' });
+await tm.createChecklist(s1.id, 'Aceite', ['Token assinado', 'Refresh rotaciona']);
 ```
 
 ---
 
-## 🔧 Troubleshooting (ClickUp)
+## 🔁 Tratamento de erro
 
-| Problema | Causa | Solução |
+`ClickUpApiError` carrega `status`, `method`, `path`, `ecode` e `rateLimitRemaining`. O corpo de erro
+observado historicamente é `{ "err": "...", "ECODE": "..." }`, mas essa forma **não foi ancorada** nesta
+rodada. Trate pelo `status` primeiro:
+
+| status | causa provável | o que o adapter faz |
 |---|---|---|
-| Subtasks aparecem como tasks independentes | uso de `create_bulk_tasks` com `parent` | criar sequencial com `create_task({ parent })` (ver Hierarquia) |
-| Formatação quebrada em comments | markdown em comentário | usar Unicode visual (`━━━`, `▶`, `∟`); markdown só em `markdown_description` |
-| Auto-update não funciona | `context.md` sem task-id ou mapeamento fase→subtask ausente | validar com `/engineer/validate-phase-sync`; conferir `TASK_MANAGER_PROVIDER` e credenciais |
-| Checklists não aparecem | `get_task` sem `subtasks: true` | passar `subtasks: true` na leitura |
+| 401 | token ausente/errado, ou `Bearer` prefixado | lança; mensagem aponta `CLICKUP_API_TOKEN` sem Bearer |
+| 400 em `/field/{id}` | campo não vale para o `custom_item_id` da task | evitado pela checagem de `applied_objects` |
+| 400/404 em `/task/DEV-42` | custom task ID sem `custom_task_ids=true` + `team_id` | evitado por `idq()` |
+| 404 | id inexistente ou fora do Workspace do token | lança |
+| 429 | rate limit do plano | retry com backoff (prática), até 3× |
+| 5xx | instabilidade | **não** retenta (pode duplicar POST); lança |
+
+`deleteTask` devolve `false` (contrato); os demais lançam. Capabilities degradam no **consumidor**
+(`interface.md` §Capabilities).
 
 ---
 
-## 💡 Best Practices (ClickUp)
+## 🔍 Lacunas a conferir ao vivo
 
-1. **Hierarquia na ordem certa**: task principal → subtasks com `parent` → comentário de setup.
-2. **Formatação por contexto**: `markdown_description` em Markdown; comentários em Unicode visual.
-3. **Sempre timestamp + status** em comentários de progresso.
-4. **Mapeamento fase→subtask** obrigatório no `context.md` da sessão.
-5. **Validar estrutura** após criação (`getTask({ subtasks: true })` → conferir `subtasks.length`).
+Exigem `CLICKUP_API_TOKEN` real e um Workspace descartável. Cada sonda fecha um nó aberto do grafo.
+
+| # | Sonda | Fecha |
+|---|---|---|
+| 1 | `GET /task/{id}?include_subtasks=true` × `?subtasks=true` em task com 2 subtasks: qual traz `subtasks[]`? (o `getTask` já registra no warn) | `C_GET_TASK_SUBTASKS_PARAM` |
+| 2 | Listar tools do servidor `https://mcp.clickup.com/mcp`: `clickup_delete_task` existe e deleta? | `C_MCP_DELETE_TOOL_INCONSISTENT` |
+| 3 | `POST /list/{id}/task` com `markdown_description` (sem `markdown_content`): descrição aparece? | alias (lacuna) |
+| 4 | `priority: 3`, `due_date` em ms, `time_estimate` em ms, `tags[]` no create: conferir no corpo | formatos (lacuna) |
+| 5 | `PUT /task/{id}` com `assignees: [id]` × `{add:[id]}` e com `tags`: o que muda de fato | assignees/tags (lacuna) |
+| 6 | `PUT /checklist/{cid}/checklist_item/{iid}` `{resolved:true}` | Edit Checklist Item |
+| 7 | Forçar 429 (plano 100/min): headers `X-RateLimit-*` presentes? | backoff |
+| 8 | `inputSchema` de `clickup_create_task`/`clickup_update_task`/`clickup_search_workspace` | args MCP |
+
+**Regra de leitura das sondas** (herdada do `zoho.md`): confira no **corpo** da resposta, nunca só no
+HTTP 200. Status 200 com o campo ignorado é exatamente a classe de defeito que este arquivo corrigiu.
 
 ---
 
-## ⚠️ Notas Operacionais
+## ⚠️ Notas operacionais
 
-- **`CLICKUP_WORKSPACE_ID`** é obrigatório para busca (`searchTasks`) e listagem de projetos (`getProjectList`). Se ausente, essas operações lançam erro descritivo.
-- **Datas** no ClickUp são timestamps em milissegundos (inteiros). Converter com `new Date(parseInt(raw.due_date)).toISOString()`.
-- **IDs de tasks** ClickUp: 9 caracteres alfanuméricos (ex: `86abc1234`).
-- **Status** são configuráveis por espaço/lista no ClickUp; os mapeamentos acima cobrem os nomes padrão. Em listas com status customizados, usar `statusRaw` para inspecionar o valor original.
-- **Prioridade**: ClickUp aceita `urgent | high | normal | low` como string ou `1 | 2 | 3 | 4` como número.
+- **IDs**: interno com 9 alfanuméricos (`86abc1234`) ou custom task ID `PREFIX-NUM` (só com `TASK_MANAGER_PROVIDER=clickup`).
+- **Webhooks** (contexto para sincronia futura, não usados hoje): criados por evento + URL, assinados com
+  `X-Signature` (HMAC SHA-256 hex do corpo bruto com o secret do webhook) (`C_WEBHOOK_SIGNATURE_CONTEXT`).
+- **Changelog oficial 2025–2026 ficou inalcançável** na pesquisa. A ausência de depreciação da v2 é
+  silêncio da fonte, não prova. Revisitar até 2026-11-01 (`review_after` do grafo).
 
 ---
 
-## 📚 Referências
+## 🔗 Referências
 
-- [ClickUp REST API v2](https://clickup.com/api)
-- [Interface ITaskManager](../interface.md)
-- [Types](../types.md)
-- [Factory](../factory.md)
-- [SDAAL — padrão-pai](../../../../docs/knowledge-base/concepts/specification-driven-ai-abstraction-layer.md)
+- Plataforma (API vigente, fontes, limites): [`clickup-api.md`](../../../../docs/knowledge-base/platforms/clickup-api.md)
+- Interface: [`../interface.md`](../interface.md) · Tipos: [`../types.md`](../types.md) · Fábrica: [`../factory.md`](../factory.md) · Detector: [`../detector.md`](../detector.md)
+- Formatação e status de PR: [`clickup-patterns`](../../../commands/common/prompts/clickup-patterns.md)
+- Especialista: `@clickup-specialist` (`.claude/agents/development/clickup-specialist.md`)
+- Pesquisa de origem: grafo `clickup-api-2026-10` (rodada de primárias de 2026-10-02, 49 nós, radar
+  exit 0), registrada no adotante que originou este patch (`docs/evolution/research/clickup-api-2026-10/`)
+- Docs oficiais: <https://developer.clickup.com/docs> · <https://developer.clickup.com/docs/mcp-tools>
 
 ---
 
-**Versão**: 2.0.0
-**Atualizado em**: 2026-06-13
+**Versão**: 3.0.0
+**Atualizado em**: 2026-10-02 (reescrita: markdown_content, ms, prioridade 1–4, tags/assignees, busca honesta, MCP oficial, checklists, custom fields, custom task IDs, rate limit por plano)
diff --git a/.claude/utils/task-manager/detector.md b/.claude/utils/task-manager/detector.md
index b542e71eb..a0a767f66 100644
--- a/.claude/utils/task-manager/detector.md
+++ b/.claude/utils/task-manager/detector.md
@@ -179,8 +179,11 @@ function detectProviderFromTaskId(taskId: string): TaskManagerProvider | null {
   // retorna o configurado. Caso contrário, default = linear (por compatibilidade
   // histórica com a detecção anterior).
   // ═══════════════════════════════════════════════════════════════════════════
+  // ⚠️ ClickUp com "Custom Task IDs" ligado também gera PREFIX-NUM (ex.: DEV-42):
+  //    o formato é IDÊNTICO ao de Jira/Linear. Só TASK_MANAGER_PROVIDER desambigua.
   if (/^[A-Z][A-Z0-9_]*-\d+$/.test(trimmedId)) {
     const configured = (process.env.TASK_MANAGER_PROVIDER || '').toLowerCase();
+    if (configured === 'clickup') return 'clickup'; // custom task ID (adapter manda custom_task_ids=true + team_id)
     if (configured === 'jira') return 'jira';
     if (configured === 'linear') return 'linear';
     return 'linear'; // fallback
@@ -354,6 +357,7 @@ function checkProviderConfiguration(): {
 | ClickUp | 9 chars alfanuméricos | `^[a-z0-9]{9}$` | `86adfe9eb` | Único |
 | Asana | 15+ dígitos | `^\d{15,}$` | `1234567890123456` | Único |
 | Jira (key) | PREFIXO-NUMERO | `^[A-Z][A-Z0-9_]*-\d+$` | `PROJ-123` | ⚠️ Colide com Linear — desambigua via `TASK_MANAGER_PROVIDER` |
+| ClickUp (custom task ID) | PREFIXO-NUMERO | `^[A-Z][A-Z0-9_]*-\d+$` | `DEV-42` | ⚠️ Colide com Jira **e** Linear — só reconhecido se `TASK_MANAGER_PROVIDER=clickup` |
 | Jira (ID) | 5-14 dígitos | `^\d{5,14}$` | `10000` | Só identificado se `TASK_MANAGER_PROVIDER=jira` |
 | Linear (key) | PREFIXO-NUMERO | `^[A-Z]+-\d+$` | `DEV-123` | ⚠️ Colide com Jira — default quando não desambiguado |
 | Linear (UUID) | UUID v4 | UUID regex | `a1b2c3d4-...` | Único |
@@ -397,8 +401,15 @@ console.log(status.message);
 |--------------------------|----------|--------------------|--------|
 | `api` (ou ausente)       | qualquer | `api`              | default |
 | `mcp`                    | `clickup`/`asana`/`jira`/`linear` | `mcp` | usa MCP se disponível em runtime; senão fallback p/ `api` |
+| `mcp`                    | `zoho`    | `api`             | sem MCP nativo da Zoho para Projects (adapters/zoho.md) |
 | `mcp`                    | `none`    | `api`             | modo offline — sem transporte real |
 
+> **Fonte única desta tabela.** `types.md` (`TaskManagerTransport`) e `factory.md` (regra de transporte)
+> remetem a ela desde 2026-10-02 — antes diziam "MCP só clickup/linear", contradizendo este detector.
+> Servidores: ClickUp = MCP oficial `https://mcp.clickup.com/mcp`; Linear/Jira(Atlassian)/Asana = conectores
+> documentados em cada adapter. A **colisão de formato de ID** (custom task ID do ClickUp × Jira × Linear)
+> não tem solução por regex: com mais de um provider em uso, fixe `TASK_MANAGER_PROVIDER`.
+
 > Os adapters consultam `config.transport` para decidir qual via usar internamente
 > (REST direto vs. chamadas ao servidor MCP). Ver cada adapter doc para detalhes.
 
@@ -412,7 +423,7 @@ console.log(status.message);
 
 ---
 
-**Versão**: 1.1.0
+**Versão**: 1.2.0
 **Criado em**: 2025-11-24
-**Atualizado em**: 2026-06-13
+**Atualizado em**: 2026-10-02 (custom task ID do ClickUp; zoho na tabela de transporte; fonte única do MCP)
 
diff --git a/.claude/utils/task-manager/factory.md b/.claude/utils/task-manager/factory.md
index bfb27c3c2..8715059ee 100644
--- a/.claude/utils/task-manager/factory.md
+++ b/.claude/utils/task-manager/factory.md
@@ -9,7 +9,7 @@ Instanciar o adapter correto para o provider e transporte configurados, abstrain
 
 **Regra de transporte (invariante):**
 - `TASK_MANAGER_TRANSPORT=api` (default) → REST API direta; sempre disponível.
-- `TASK_MANAGER_TRANSPORT=mcp` → MCP server do provider; ativado apenas quando o provider suporta MCP (`clickup`, `linear`). Se não suportado, cai automaticamente para `api`.
+- `TASK_MANAGER_TRANSPORT=mcp` → MCP server do provider. Providers com via MCP documentada no adapter: `clickup` (MCP oficial `https://mcp.clickup.com/mcp`), `linear`, `jira` (Atlassian) e `asana`. `zoho` e `none` ficam sempre em `api`. O detector resolve isso em `ProviderConfig.transport` (ver `detector.md` §Lógica de Transporte) e o adapter cai para `api` em runtime se o servidor MCP não responder.
 
 A decisão final de transporte é resolvida pelo `detectProvider()` (ver `detector.md`) e exposta em `ProviderConfig.transport`. A factory lê esse campo — nunca relê `TASK_MANAGER_TRANSPORT` diretamente.
 
@@ -63,7 +63,8 @@ function getTaskManager(options?: FactoryOptions): ITaskManager {
 
     case 'clickup':
       // transport='api'  → REST API  (https://api.clickup.com/api/v2)
-      // transport='mcp'  → MCP server ClickUp (quando TASK_MANAGER_TRANSPORT=mcp)
+      // transport='mcp'  → MCP oficial ClickUp (https://mcp.clickup.com/mcp), fallback real p/ API
+      // workspaceId ausente → o adapter auto-detecta via GET /team (1 Workspace) ou pede escolha
       return new ClickUpAdapter({
         transport: config.transport,          // <- ciente do transporte
         apiToken: process.env.CLICKUP_API_TOKEN!,
@@ -473,6 +474,6 @@ const taskManager = getTaskManager({ forceProvider: 'linear' });
 
 ---
 
-**Versão**: 2.0.0
-**Atualizado em**: 2026-06-13
+**Versão**: 2.0.1
+**Atualizado em**: 2026-10-02 (regra de transporte alinhada ao detector: MCP em clickup/linear/jira/asana)
 
diff --git a/.claude/utils/task-manager/interface.md b/.claude/utils/task-manager/interface.md
index 8f390bee9..eefc45e0d 100644
--- a/.claude/utils/task-manager/interface.md
+++ b/.claude/utils/task-manager/interface.md
@@ -42,9 +42,11 @@ interface ITaskManager {
   /**
    * Obtém detalhes de uma task existente.
    * @param taskId - ID da task no provedor
+   * @param opts - { includeSubtasks?: boolean } (default false). Opcional e
+   *               retrocompatível: chamar sem opts mantém o comportamento 1.0.
    * @returns Task completa com todos os detalhes
    */
-  getTask(taskId: string): Promise<TaskOutput>;
+  getTask(taskId: string, opts?: GetTaskOptions): Promise<TaskOutput>;
   
   /**
    * Atualiza uma task existente.
@@ -156,11 +158,62 @@ interface ITaskManager {
    * @returns Nome do provedor ou null se desconhecido
    */
   getProviderFromTaskId(taskId: string): TaskManagerProvider | null;
+
+  // ═══════════════════════════════════════════════════════════════════════════
+  // CAPABILITIES OPCIONAIS (desde 1.1.0) — ver §Capabilities abaixo
+  // Default para adapter que NÃO implementa: lança TaskManagerNotSupportedError.
+  // ═══════════════════════════════════════════════════════════════════════════
+
+  /** Capabilities que este adapter implementa. Ausente = nenhuma. */
+  readonly capabilities?: readonly TaskManagerCapability[];
+
+  /** @capability tags — adiciona UMA tag sem reescrever as demais. */
+  addTag(taskId: string, tag: string): Promise<void>;
+
+  /** @capability tags — remove UMA tag. */
+  removeTag(taskId: string, tag: string): Promise<void>;
+
+  /** @capability checklists — cria checklist (e itens, se dados) na task. */
+  createChecklist(taskId: string, name: string, items?: string[]): Promise<ChecklistOutput>;
+
+  /** @capability checklists — marca/desmarca um item de checklist. */
+  setChecklistItem(checklistId: string, itemId: string, resolved: boolean): Promise<void>;
+
+  /** @capability customFields — seta custom field POR NOME (adapter resolve id/formato). */
+  setCustomField(taskId: string, fieldName: string, value: unknown): Promise<void>;
 }
 ```
 
 ---
 
+## 🧩 Capabilities opcionais (1.1.0)
+
+Os **16 membros** acima de `capabilities` são obrigatórios em todo adapter. Os cinco métodos de
+capability são **opcionais**: o adapter declara o que implementa em `capabilities` e, para o resto,
+herda o comportamento default abaixo. Nenhum adapter existente quebra: quem não foi atualizado
+simplesmente não declara `capabilities`.
+
+| Capability | Métodos | Default (adapter sem suporte) | Fallback recomendado ao consumidor |
+|---|---|---|---|
+| `tags` | `addTag`, `removeTag` | lança `TaskManagerNotSupportedError` | `getTask` → `updateTask(id, { tags: [...atuais, nova] })` |
+| `checklists` | `createChecklist`, `setChecklistItem` | lança `TaskManagerNotSupportedError` | checkboxes `- [ ]` no `markdownDescription` ou subtasks |
+| `customFields` | `setCustomField` | lança `TaskManagerNotSupportedError` | `addComment` com o valor + sugerir criar o campo |
+
+**Regra para o consumidor:** antes de chamar, teste `taskManager.capabilities?.includes('<cap>')`;
+ou chame e trate `TaskManagerNotSupportedError` degradando para o fallback. Nunca deixe o erro abortar
+o fluxo principal (criar task, abrir PR) — capability é enriquecimento.
+
+**Campos novos de entrada** (`status`, `points`, `customFields`, `taskType` em `CreateTaskInput`/
+`UpdateTaskInput`): adapter que não os mapeia **ignora com aviso**, nunca lança.
+Ver [types.md](./types.md).
+
+| Adapter | `capabilities` declaradas (2026-10-02) |
+|---|---|
+| ClickUp | `tags`, `checklists`, `customFields` |
+| Jira · Linear · Asana · Zoho · none | nenhuma ainda (default: NotSupported) |
+
+---
+
 ## 📊 Métodos por Categoria
 
 | Categoria | Métodos | Descrição |
@@ -173,6 +226,7 @@ interface ITaskManager {
 | **Busca** | `searchTasks` | Localização de tasks |
 | **Projetos** | `getProjectList`, `getProject` | Navegação |
 | **Validação** | `validateTaskId`, `getProviderFromTaskId` | Compatibilidade |
+| **Capabilities (opcional)** | `addTag`, `removeTag`, `createChecklist`, `setChecklistItem`, `setCustomField` | Enriquecimento; default NotSupported |
 
 ---
 
@@ -188,7 +242,11 @@ interface ITaskManager {
 | `review` | "review" | - | "In Review" | "In Review" | ⚠️ sem nativo — status customizado do projeto (NÃO MEDIDO) |
 | `done` | "done" | completed: true | "Done" | "Done" | o status com `is_closed_type: true` |
 | `closed` | "closed" | completed: true | "Closed" | "Canceled" | idem (`is_closed_type: true`) |
-| `canceled` | "closed" | completed: true | "Cancelled" | "Canceled" | idem (`is_closed_type: true`) |
+| `canceled` | "closed" ⚠️ | completed: true | "Cancelled" | "Canceled" | idem (`is_closed_type: true`) |
+
+⚠️ **ClickUp `canceled`:** escreve `"closed"` por default; se a List tiver um status `canceled`/`cancelled`
+(lido em `GET /list/{id}` → `statuses`), o adapter usa esse. Na leitura, `canceled`/`cancelled` normaliza
+para `canceled` e `blocked` para `in_progress` com `statusRaw: "blocked"` (ver adapters/clickup.md).
 
 ⚠️ **Zoho resolve status por NOME, não por id fixo.** Os ids são por projeto e **não existe endpoint que
 os liste** (medido 2026-09-30: seis caminhos candidatos devolvem 400). O adapter lê uma task do projeto
@@ -254,6 +312,7 @@ await taskManager.updateStatus(subtask.id, 'in_progress');
 
 ---
 
-**Versão**: 1.0.0
+**Versão**: 1.1.0
 **Criado em**: 2025-11-24
+**Atualizado em**: 2026-10-02 (getTask com opts; capabilities opcionais tags/checklists/customFields — retrocompatível)
 
diff --git a/.claude/utils/task-manager/types.md b/.claude/utils/task-manager/types.md
index 7a7ec876c..ce4d65c78 100644
--- a/.claude/utils/task-manager/types.md
+++ b/.claude/utils/task-manager/types.md
@@ -19,8 +19,10 @@ type TaskManagerProvider = 'clickup' | 'asana' | 'jira' | 'linear' | 'zoho' | 'n
  *
  * 'api' (default) — REST API direta; sempre disponível.
  * 'mcp'           — MCP server do provider; ativado via
- *                   TASK_MANAGER_TRANSPORT=mcp apenas quando o provider
- *                   suporta MCP (clickup, linear). Cai para 'api' nos demais.
+ *                   TASK_MANAGER_TRANSPORT=mcp. Providers com via MCP
+ *                   documentada: clickup, linear, jira (e asana). zoho e none
+ *                   ficam sempre em 'api' (detector.md §Lógica de Transporte).
+ *                   O adapter cai para 'api' em runtime se o servidor não responder.
  *
  * Controlado por: TASK_MANAGER_TRANSPORT (valores: 'api' | 'mcp'; default 'api').
  */
@@ -41,7 +43,20 @@ type TaskStatus =
 /**
  * Níveis de prioridade.
  */
-type TaskPriority = 'urgent' | 'high' | 'normal' | 'low';
+type TaskPriority = 'urgent' | 'high' | 'normal' | 'low';   // NÃO existe 'medium'
+
+/**
+ * Capabilities OPCIONAIS (interface.md §Capabilities). Adapter que não declara a
+ * capability lança TaskManagerNotSupportedError no método correspondente.
+ */
+type TaskManagerCapability = 'tags' | 'checklists' | 'customFields';
+
+/** Erro tipado para método opcional sem suporte no provider ativo. */
+class TaskManagerNotSupportedError extends Error {
+  constructor(readonly provider: TaskManagerProvider, readonly method: string) {
+    super(`${provider}: ${method} não suportado por este adapter`);
+  }
+}
 ```
 
 ---
@@ -84,9 +99,20 @@ interface CreateTaskInput {
   
   /** Estimativa de tempo (minutos) */
   timeEstimate?: number;
+  /** Status inicial (o adapter mapeia; sem suporte → status default da lista) */
+  status?: TaskStatus;
+  /** Story/Sprint points (ClickUp: `points` nativo; demais: custom field ou ignorado) */
+  points?: number;
+  /** Custom fields POR NOME → valor (o adapter resolve o id e o formato por provider) */
+  customFields?: Record<string, unknown>;
+  /** Tipo de task do provider (ClickUp: custom task type; Jira: issue type) */
+  taskType?: string;
 }
 ```
 
+> **Retrocompatível:** os quatro campos novos (2026-10-02) são opcionais. Adapter que não os
+> mapeia **ignora com aviso** (`console.warn`), nunca lança — consumidores já os enviam.
+
 ### UpdateTaskInput
 
 ```typescript
@@ -123,6 +149,12 @@ interface UpdateTaskInput {
   
   /** Nova estimativa */
   timeEstimate?: number;
+  /** Novos points */
+  points?: number;
+  /** Custom fields por nome → valor (mesma regra do CreateTaskInput) */
+  customFields?: Record<string, unknown>;
+  /** Novo tipo de task */
+  taskType?: string;
 }
 ```
 
@@ -238,6 +270,33 @@ interface TaskOutput {
   
   /** Tempo gasto (minutos) */
   timeSpent?: number;
+  /** Points (story/sprint points), quando o provider expõe */
+  points?: number;
+  /** Checklists nativos (ClickUp; demais: ausente) */
+  checklists?: ChecklistOutput[];
+  /** Custom fields normalizados */
+  customFields?: CustomFieldOutput[];
+}
+
+interface ChecklistOutput {
+  id: string;
+  name: string;
+  items: { id: string; name: string; resolved: boolean }[];
+  resolved: number;     // contagem de itens resolvidos
+  unresolved: number;   // contagem de itens pendentes
+}
+
+interface CustomFieldOutput {
+  id: string;
+  name: string;
+  type: string;         // tipo cru do provider (ex.: 'number', 'drop_down', 'date')
+  value: unknown;       // já normalizado (Date → ISO 8601; Dropdown → nome da opção)
+}
+
+/** Opções de leitura de getTask (interface.md). */
+interface GetTaskOptions {
+  /** Traz subtasks (e, no ClickUp, os checklists delas) */
+  includeSubtasks?: boolean;
 }
 ```
 
@@ -433,7 +492,7 @@ const STATUS_MAPPING: Record<TaskManagerProvider, Record<TaskStatus, string>> =
 
 ---
 
-**Versão**: 1.1.0
+**Versão**: 1.2.0
 **Criado em**: 2025-11-24
-**Atualizado em**: 2026-06-13
+**Atualizado em**: 2026-10-02 (campos status/points/customFields/taskType, checklists, capabilities)
 
diff --git a/docs/knowledge-base/index.md b/docs/knowledge-base/index.md
index 4e0fadf13..d68bd45b8 100644
--- a/docs/knowledge-base/index.md
+++ b/docs/knowledge-base/index.md
@@ -137,6 +137,7 @@ Agente consumidor: `@nuclea-specialist`.
 
 ## 🌐 Plataformas (3)
 
+- [ClickUp API](platforms/clickup-api.md) — REST v2 vigente (v3 parcial), auth `pk_`, rate limit por plano, tasks/checklists/custom fields, MCP oficial; base do adapter ClickUp (verificada 2026-10-02)
 - [Gamma.App API](platforms/gamma-app-api.md) — Generations API: especificação, padrões de integração e exemplos (extraído do agente `@gamma-api-specialist`)
 - [Git Ledger as Working Dir](platforms/git-ledger-as-working-dir.md) — ledger git como additional working directory (prova da Fase 0 da federation)
 - [Runflow](platforms/runflow.md) — SDK e plataforma de agentes/workflows
diff --git a/docs/knowledge-base/platforms/clickup-api.md b/docs/knowledge-base/platforms/clickup-api.md
new file mode 100644
index 000000000..d6368b56e
--- /dev/null
+++ b/docs/knowledge-base/platforms/clickup-api.md
@@ -0,0 +1,169 @@
+---
+versao: 1.0.0
+data: 2026-10-02
+categoria: platforms
+applies_to: "ClickUp REST API v2 (base vigente; v3 parcial, sem cronograma de migração, usada só para anexos) + MCP oficial em public beta (https://mcp.clickup.com/mcp, catálogo de tools de 19/03/2026)"
+verified_at: 2026-10-02
+verified_against: "rodada de primárias de 2026-10-02 (grafo clickup-api-2026-10, run wf_71987767-4d3): 10 fontes oficiais em developer.clickup.com e help.clickup.com, 9 lidas e 1 inalcançável (changelog 2025-2026). 34 evidências ancoradas por verificador independente, 12 claims rejeitadas. NENHUM endpoint foi chamado contra Workspace real: isto é PESQUISADO, não MEDIDO. Duas questões ficaram abertas para conferir ao vivo: include_subtasks x subtasks=true e clickup_delete_task."
+---
+
+# ClickUp API: Knowledge Base
+
+> **Categoria**: Platforms
+> Referência da API do ClickUp **vigente em 2026-10-02**: base e versões, autenticação, rate limit,
+> endpoints de task, subtask, checklist, comentário e custom field, MCP oficial e webhooks. É a
+> plataforma por trás do adapter [`.claude/utils/task-manager/adapters/clickup.md`](../../../.claude/utils/task-manager/adapters/clickup.md).
+> Cada fato traz o id do nó no grafo de pesquisa (`C_*` claim, `E_*` evidência). O que não foi ancorado
+> diz **NÃO ANCORADO**.
+
+---
+
+## 📋 Metadata
+
+| Campo | Valor |
+|---|---|
+| **Versão** | 1.0.0 |
+| **Data de Criação** | 2026-10-02 |
+| **Categoria** | platforms |
+| **Versão da API** | v2 (`/api/v2/`); v3 parcial |
+| **Revisar até** | 2026-11-01 (`review_after` do grafo: cadência de ferramenta/preço) |
+| **Fontes Principais** | [1] <https://developer.clickup.com/docs/authentication> · [2] <https://developer.clickup.com/docs/general-v2-v3-api> · [3] <https://developer.clickup.com/docs/rate-limits> · [4] <https://developer.clickup.com/reference/createtask> · [5] <https://developer.clickup.com/reference/getfilteredteamtasks> · [6] <https://developer.clickup.com/reference/createchecklist> · [7] <https://developer.clickup.com/reference/createchecklistitem> · [8] <https://developer.clickup.com/reference/createtaskcomment> · [9] <https://developer.clickup.com/reference/getaccessiblecustomfields> · [10] <https://developer.clickup.com/reference/setcustomfieldvalue> · [11] <https://developer.clickup.com/docs/custom-task-types> · [12] <https://developer.clickup.com/docs/mcp-tools> · [13] <https://developer.clickup.com/docs/connect-an-ai-assistant-to-clickups-mcp-server> · [14] <https://developer.clickup.com/docs/webhooks> · [15] <https://developer.clickup.com/docs/webhooksignature> · [16] <https://developer.clickup.com/reference/getspaces> · [17] <https://developer.clickup.com/reference/getlist> |
+
+---
+
+## 🧭 Versões e base
+
+| Ponto | Valor | Nó / fonte |
+|---|---|---|
+| Base vigente | `https://api.clickup.com/api/v2/` | `C_V2_REMAINS_ADAPTER_BASE` [2] |
+| v3 | parcial: poucos endpoints, sem guia publicado, migração "em curso" **sem cronograma** e sem data de depreciação da v2 | `E_V3_PARTIAL_FEW_ENDPOINTS`, `E_V3_MIGRATION_NO_TIMELINE` [2] |
+| Anexos | V3 Attachments API para task e custom field Files; o endpoint v2 segue documentado | `C_ATTACHMENTS_MOVE_TO_V3` |
+| Vocabulário | v2 `team` = **Workspace** (a v3 adota o termo); os paths v2 seguem `/team/{team_id}` | `C_TEAM_ID_IS_WORKSPACE` |
+
+⚠️ O **changelog oficial 2025–2026 ficou inalcançável**. Não há evidência de depreciação da v2, mas essa
+ausência é silêncio da fonte, não prova.
+
+## 🔐 Autenticação
+
+| Modo | Header | Nó |
+|---|---|---|
+| Token pessoal (`pk_…`) | `Authorization: pk_…` (**sem** `Bearer`) | `E_AUTH_PERSONAL_TOKEN_PK` [1] |
+| OAuth 2.0 (app de terceiro) | `Authorization: Bearer <access_token>` | `E_AUTH_OAUTH_BEARER` [1] |
+
+Para descobrir o Workspace, use `GET /v2/team` ("Get Authorized Teams (Workspaces)",
+`E_AUTH_AUTHORIZED_TEAMS_LABEL`). O token pessoal fica em *Settings → Apps → API Token*.
+
+## 🚦 Rate limit
+
+| Plano | req/min por token | Nó |
+|---|---|---|
+| Free Forever · Unlimited · Business | 100 | `E_RATE_LIMITS_BY_PLAN` [3] |
+| Business Plus | 1.000 | idem |
+| Enterprise / Enterprise Plus | 10.000 | idem |
+
+- `X-RateLimit-Remaining` informa o que resta na janela (`E_RATE_REMAINING_HEADER`). `X-RateLimit-Reset`
+  é um timestamp Unix.
+- **Backoff após 429 não é documentado.** Retry com backoff exponencial é prática do adapter, não
+  instrução do ClickUp (`C_RATE_LIMIT_BY_PLAN`, LIMITADA: o WebFetch devolveu um resumo da tabela).
+
+## 📝 Tasks
+
+| Ponto | Valor | Nó |
+|---|---|---|
+| Criar | `POST /v2/list/{list_id}/task` | [4] |
+| Markdown | **`markdown_content`** (prevalece sobre `description`). `markdown_description` **não** é o campo documentado | `E_TASK_MARKDOWN_CONTENT_PRECEDENCE` |
+| Subtask | `parent` no create; precisa estar na **mesma List**; o pai pode ser outra subtask; `parent: null` não converte subtask em task | `E_TASK_PARENT_SUBTASK` |
+| Tipo | `custom_item_id` (0 = Task, 1 = Milestone, demais = tipos do Workspace); filtra os custom fields aceitos | `E_TASK_CUSTOM_ITEM_ID`, `E_CTT_DEFAULT_VALUES` [11] |
+| Outros | `points` (Sprint Points), `links_to` (dependência), `check_required_custom_fields` (default `false`) | `E_TASK_POINTS_LINKS_REQUIRED_FIELDS` |
+| Ler | `GET /v2/task/{id}`: `include_subtasks` (default false), `include_markdown_description`, `custom_task_ids=true` + `team_id` | `E_TASK_FILTERED_AND_GET_PARAMS` |
+| Buscar | `GET /v2/team/{team_id}/task`: 100 por página, `page` a partir de 0, subtasks **excluídas** por padrão (param `subtasks`), `custom_items[]` | idem [5] |
+
+**ABERTA (`C_GET_TASK_SUBTASKS_PARAM`):** o Get Task documenta `include_subtasks`, e `subtasks` é
+parâmetro do Filtered Team Tasks. Integrações antigas usavam `GET /task/{id}?subtasks=true`. Confira ao
+vivo antes de depender de um ou de outro.
+
+**NÃO ANCORADO** nesta rodada (prática v2 estabelecida, confirmar no corpo da resposta):
+- formato de `assignees` (create: array de ids; update: `{add, rem}`), `priority` (1–4), `due_date`/
+  `start_date`/`time_estimate` (Unix ms) e `tags` no create;
+- tag avulsa por `POST`/`DELETE /v2/task/{id}/tag/{tag_name}`;
+- `markdown_description` como alias aceito na escrita;
+- paths e IDs da v3.
+
+## ✅ Checklists e 💬 comentários
+
+| Operação | Endpoint | Nó |
+|---|---|---|
+| Criar checklist | `POST /v2/task/{task_id}/checklist` `{name}` (+ `custom_task_ids`/`team_id`) | `E_CHECKLIST_CREATE` [6] |
+| Criar item | `POST /v2/checklist/{checklist_id}/checklist_item` `{name, assignee?}`; `checklist_id` é UUID | `E_CHECKLIST_ITEM_CREATE` [7] |
+| Editar item | `PUT /v2/checklist/{checklist_id}/checklist_item/{item_id}` | **NÃO ANCORADO** |
+| Comentar | `POST /v2/task/{id}/comment` `{comment_text, assignee?, group_assignee?, notify_all}` | `E_COMMENT_CREATE_NOTIFY_ALL` [8] |
+| Resposta em thread | Create Threaded Comment (`comment_id` do pai); rota **não ancorada** | `E_COMMENT_THREADED` |
+
+`notify_all` só decide se o **criador** do comentário é notificado; assignees e watchers são sempre
+notificados. Não se sabe se markdown renderiza em comentário.
+
+## 🧩 Custom fields
+
+| Ponto | Valor | Nó |
+|---|---|---|
+| Listar | `GET /v2/list/{list_id}/field`; campos escopados trazem `applied_objects` (`object_type: 19` = custom task type, `object_id` = `custom_item_id`) | `E_CF_ACCESSIBLE_APPLIED_OBJECTS` [9] |
+| Setar | `POST /v2/task/{task_id}/field/{field_id}` `{value}`; o campo precisa valer para o `custom_item_id` da task, **senão 400** | `E_CF_SET_VALUE_APPLICABILITY` [10] |
+| Formatos | Dropdown = **UUID da opção**; Date = Unix ms; Money = só o valor (sem moeda); Button = `true` | `E_CF_VALUE_FORMATS` |
+| Files | ID de anexo enviado pela V3 Create Attachment (entidade `custom_fields`), objeto `add/rem` | `E_CF_FILES_VIA_V3` |
+| Filtrar por tipo | `custom_items[]` no Filtered Team Tasks | `E_CTT_DEFAULT_VALUES` |
+
+## 🗂️ Hierarquia
+
+`Workspace (team) → Space → Folder → List → Task → Subtask`. Endpoints vigentes
+(`C_HIERARCHY_ENDPOINTS_CURRENT`):
+
+- `GET /v2/team/{team_id}/space?archived=false`: Spaces. Info de membros só em Space privado
+  (`E_HIER_GET_SPACES` [16]).
+- `GET /v2/folder/{folder_id}/list` e `GET /v2/space/{space_id}/list` (folderless), ambos com `archived`
+  (`E_HIER_LISTS_FOLDER_FOLDERLESS`).
+- `GET /v2/list/{list_id}`: devolve `statuses`, `folder`, `space`, `task_count`, `inbound_address` e
+  `permission_level`. O List ID é o fim da URL de *Copy link* (`E_HIER_GET_LIST` [17]).
+- Folders aninhados (`parent_folder`) não foram ancorados.
+
+## 🔌 MCP oficial
+
+| Ponto | Valor | Nó |
+|---|---|---|
+| Endpoint | `https://mcp.clickup.com/mcp` (hospedado pelo ClickUp; OAuth no cliente MCP) | `E_MCP_OFFICIAL_ENDPOINT` [13] |
+| Prefixo | `clickup_`: busca, tasks, comentários, tags, dependências, time tracking, hierarquia, membros, chat, docs, time-in-status | `E_MCP_TOOL_PREFIX_CATALOG` [12] |
+| Nomes de task | `clickup_create_task`, `clickup_get_task`, `clickup_update_task`, `clickup_create_task_comment`, `clickup_get_task_comments`, `clickup_search_workspace`, `clickup_move_task_to_list`, `clickup_add_tag_to_task`, `clickup_add_dependency`, `clickup_create_bulk_tasks` | `E_MCP_TASK_TOOL_NAMES` |
+| Deleção | **em disputa**: o guia diz que não há tools de deleção por segurança; o catálogo lista `clickup_delete_task` | `C_MCP_DELETE_TOOL_INCONSISTENT` |
+
+No Claude Code, a tool aparece como `mcp__<servidor>__clickup_*`, e `<servidor>` é o nome dado ao
+registrar. Ex.: `claude mcp add --transport http clickup https://mcp.clickup.com/mcp` →
+`mcp__clickup__clickup_create_task`. Nomes no formato `mcp_ClickUp_clickup_*` vêm de **outro** servidor
+(comunitário) e não valem para o oficial (`C_OFFICIAL_MCP_TOOL_NAMES`). Os **argumentos** das tools não
+foram ancorados: leia o `inputSchema`.
+
+## 🪝 Webhooks (contexto)
+
+Webhooks são criados inscrevendo um ou mais eventos (ex.: `taskCreated`, `taskUpdated`,
+`taskStatusUpdated`) e uma URL (`E_WEBHOOK_REGISTER_EVENTS` [14]). Cada webhook tem um secret próprio,
+devolvido na criação (`E_WEBHOOK_SHARED_SECRET`). O header `X-Signature` traz o HMAC SHA-256 do corpo
+bruto, sempre em hexadecimal (`E_WEBHOOK_SIGNATURE_HEX` [15]). Ainda não há uso no Onion; vale como base
+para uma sincronia por evento.
+
+## 🔍 Lacunas abertas
+
+1. `include_subtasks` × `subtasks=true` no Get Task (`C_GET_TASK_SUBTASKS_PARAM`)
+2. `clickup_delete_task` no MCP oficial (`C_MCP_DELETE_TOOL_INCONSISTENT`)
+3. Formatos não ancorados do Create/Update Task (lista acima), Edit Checklist Item, rota do threaded
+   comment, markdown em comentário, backoff após 429, paths v3
+4. Datas de mudança: as páginas não têm data, exceto o catálogo MCP (19/03/2026)
+
+As sondas que fecham cada lacuna estão no adapter, em §Lacunas a conferir ao vivo.
+
+## 🔗 Referências
+
+- Adapter: [`.claude/utils/task-manager/adapters/clickup.md`](../../../.claude/utils/task-manager/adapters/clickup.md)
+- Contrato: [`.claude/utils/task-manager/interface.md`](../../../.claude/utils/task-manager/interface.md)
+- KB irmã (mesma família, outra plataforma): [zoho-projects-api](zoho-projects-api.md)
+- Pesquisa de origem: grafo `clickup-api-2026-10` (49 nós; radar `--integrity --schema` exit 0) e a
+  SYNTHESIS correspondente. Ficam registrados no adotante que originou o patch, em
+  `docs/evolution/research/clickup-api-2026-10/`. O caminho é citado como texto porque `docs/evolution/`
+  não é vendorizado.
-- 
2.43.0

```
