# 🟠 Zoho Projects Adapter

> Instância do padrão [SDAAL](../../../../docs/knowledge-base/concepts/specification-driven-ai-abstraction-layer.md).
> Transporte **único: REST API V3**. **Não há MCP nativo da Zoho para Projects** (medido 2026-09-30: só
> terceiros; o da CData é read-only e exige driver JDBC licenciado). Sem MCP, não há atalho tentador —
> e é por isso que este adapter não tem transporte dual como o do Linear.

> ⚠️ **TUDO NESTE ARQUIVO FOI MEDIDO CONTRA O PORTAL REAL** em 2026-09-30, em duas sondas de escrita
> com projeto descartável e limpeza verificada. Onde algo **não** foi medido, está dito. A referência de
> plataforma (auth, limites, escopos) vive em
> [`docs/knowledge-base/platforms/zoho-projects-api.md`](../../../../docs/knowledge-base/platforms/zoho-projects-api.md).

---

## ⚠️ As três coisas que quebram um adapter escrito por analogia

Leia antes de qualquer método. Cada uma foi medida, e cada uma **devolve HTTP 200**.

### 1. Parâmetro aceito e IGNORADO em silêncio — e isto é SISTÊMICO

Provado por contagem no mesmo projeto, com 2 tasks:

| chamada | resultado |
|---|---|
| `GET /tasks` (sem filtro) | 2 tasks |
| `GET /tasks?search=PAI` | **2** |
| `GET /tasks?search=ZZZINEXISTENTE` | **2** ← termo que não existe |
| `GET /tasks?parent_task=<id>` | **2** (incluindo a própria task pai) |
| `POST` tasklist com `{"milestone_id":…}` | **200**, e a tasklist nasce em milestone `None` |
| `PATCH` task com `{"owners":[…]}` ou `{"owner":{…}}` | **200**, e a atribuição não acontece |
| `POST` task com `{"depth":1}` | **200**, e a task nasce com `depth: 0` |

**Seis casos medidos, todos HTTP 200.** Isto não é curiosidade: é a regra de desenho deste adapter. O
vínculo correto é sempre **objeto aninhado** — `{"milestone":{"id":…}}`, `{"tasklist":{"id":…}}`,
`{"status":{"id":…}}`, `{"owners_and_work":{"owners":[…]}}`.

**Regra do adapter, não conselho:** *nenhum filtro nem vínculo é confiado sem provar que discriminou.*
Verifique no **corpo da resposta**, nunca no código HTTP.

### 2. A forma da resposta muda — por versão E por método

```
V3  GET  /portal/{p}/projects                → [ {...} ]                       ARRAY no topo
V2  GET  /restapi/portal/{p}/projects/       → { "projects": [...] }           envelope
V3  POST /tasks/{id}/comments                → [ {...} ]                       ARRAY no topo
V3  GET  /tasks/{id}/comments                → { "comments": [...], "page_info": {...} }
```

O mesmo recurso, o mesmo endpoint, formas diferentes por **método**. Um parser único quebra.

### 3. O segmento é `portal` SINGULAR

`/api/v3/portal/{id}/…` responde; `/api/v3/portals/{id}/…` devolve **400 `URL_RULE_NOT_CONFIGURED`**.

---

## 📋 Configuração

### Variáveis de Ambiente

```bash
# Obrigatórias
ZOHO_CLIENT_ID=1000.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
ZOHO_CLIENT_SECRET=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
ZOHO_PORTAL_ID=xxxxxxxxx          # o id da V3 (ver a armadilha abaixo)

# Opcional
ZOHO_ACCOUNTS_HOST=https://accounts.zoho.com   # troque por .eu / .in / .com.au conforme o datacenter
```

⚠️ **`portal_id` (V3) ≠ `login_id` (V2).** Medido no mesmo portal: a V3 devolve `940471693` e a V2
devolve `2971200`. São campos de versões diferentes e **não são intercambiáveis** — trocá-los produz
erro que parece de permissão. Resolva o id **na versão em que for chamar**.

### Obter as credenciais

O caminho é **Self client** + **`client_credentials`**, e ele dispensa grant code e refresh token:

1. `api-console.zoho.com` → **GET STARTED** → **Self client** → `CREATE NOW` → `CREATE` → `OK`
2. copie **Client ID** (começa com `1000.`) e **Client Secret** na aba *Client Secret*
3. **não** gere grant code — o fluxo abaixo não precisa dele

```bash
curl -s -X POST "${ZOHO_ACCOUNTS_HOST}/oauth/v2/token" \
  -d grant_type=client_credentials \
  -d "client_id=${ZOHO_CLIENT_ID}" \
  -d "client_secret=${ZOHO_CLIENT_SECRET}" \
  -d "scope=ZohoProjects.portals.READ,ZohoProjects.projects.ALL,ZohoProjects.tasks.ALL,ZohoProjects.tasklists.ALL,ZohoProjects.milestones.ALL"
# → {"access_token":"1000.…","api_domain":"https://www.zohoapis.com","token_type":"Bearer","expires_in":3600}
```

**Não vem `refresh_token`, e não faz falta**: o token dura 3600 s e se pede de novo com o mesmo par. Um
segredo a menos para guardar e rotacionar. `ALL` só é documentado para `projects`, `tasks` e
`timesheets`; nos outros módulos peça a operação explícita.

---

## 🗺️ Hierarquia, e o que faz papel de "épico"

```
portal → projeto → milestone → tasklist → task → subtask
```

**Zoho Projects não tem "épico".** O equivalente funcional é o **milestone** (tem início, fim e agrupa
tasklists); a tasklist é o agrupador de segundo nível. Medido montando a árvore inteira.

---

## 🔧 Implementação da interface

Os 16 membros de [`../interface.md`](../interface.md). Base: `https://projects.zoho.com/api/v3/portal/${ZOHO_PORTAL_ID}`.

### `provider` · `isConfigured`

```
provider     = "zoho"
isConfigured = ZOHO_CLIENT_ID && ZOHO_CLIENT_SECRET && ZOHO_PORTAL_ID
```

Sem `refresh_token` na lista — é o que distingue este adapter dos outros OAuth.

### `getProjectList()` · `getProject(projectId)`

```
GET /projects                  → ARRAY no topo (não envelope)
GET /projects/{projectId}
```

### `createTask(input)`

```
POST /projects/{projectId}/tasks
{ "name": "...", "tasklist": { "id": "..." } }
```

O vínculo com a tasklist é **objeto aninhado**. `tasklist_id` seria aceito e ignorado.

### `getTask(taskId)` · `updateTask(taskId, updates)`

```
GET   /projects/{projectId}/tasks/{taskId}
PATCH /projects/{projectId}/tasks/{taskId}
```

**`PATCH` e só `PATCH`** — `PUT` e `POST` no recurso devolvem `INVALID_METHOD`.

### `deleteTask(taskId)`

```
DELETE /projects/{projectId}/tasks/{taskId}     → 204
```

⚠️ **Assimetria medida:** para **task** o verbo é `DELETE`; para **projeto** é `POST /projects/{id}/trash`
(o `DELETE` de projeto falha de duas formas diferentes). Não generalize de um para o outro.

### `createSubtask(parentId, input)` — **exige a API V2**

Medido em três rodadas, e a conclusão é que **o modelo da V3 tem subtask e a escrita dela não está
exposta**:

| tentativa | resultado |
|---|---|
| `parent_task` como objeto, string **e número** | `INVALID_PARAMETER_VALUE` — o campo **existe** |
| `parent_task` + `depth: 1` | idem |
| `depth: 1` sozinho | **200**, e a task nasce com `depth: 0` |
| `association_info.parent_task` | **200**, e nada vincula |
| `/tasks/{id}/subtasks`, `/subtasks`, `/tasks/subtasks`, `/tasks/{id}/tasks` | `URL_RULE_NOT_CONFIGURED` |
| **e no entanto** | toda task traz `association_info.has_subtasks` |

Nem a doc nem a comunidade deram o caminho (a doc V3 é um SPA de >10 MB; busca de código no GitHub
voltou vazia). **Na V2 funciona:**

```
POST /restapi/portal/{loginId}/projects/{projectId}/tasks/   (form-urlencoded)
name=...&parent_task_id={parentId}                            → 201
```

⚠️ **Dois avisos, e os dois são prazo:** (1) isto torna o adapter **híbrido V3+V2** por necessidade, não
por escolha; (2) a **V2 sai de linha em 2026-12-31**. Quando sair, `createSubtask` fica sem caminho
conhecido — é fio com data, não detalhe. (3) A V2 usa `login_id`, não `portal_id`.

### `getSubtasks(parentId)` — **não há caminho confiável**

`GET /tasks?parent_task=<id>` devolve **200** e **a listagem completa**, incluindo a própria task pai, e
a subtask criada pela V2 vem com `depth: 0`. Provado: sem filtro 2 tasks, com filtro 2 tasks.

**O adapter lista e filtra no cliente**, ou declara que não sabe. O que ele **não** faz é confiar no
parâmetro.

### `addComment(taskId, comment)` · `getComments(taskId)`

```
POST /projects/{projectId}/tasks/{taskId}/comments
{ "comment": "..." }              ← o campo é `comment`; `content`/`text`/`body` dão LESS_THAN_MIN_OCCURANCE
                                  → resposta: ARRAY no topo

GET  /projects/{projectId}/tasks/{taskId}/comments
                                  → resposta: { "comments": [...], "page_info": {...} }
```

Formatação: **Markdown simples**. Zoho não exige ADF (Jira) nem Unicode visual (ClickUp), então **não
existe fragmento de formatação próprio** — e não criar um é decisão, não esquecimento. A estratégia dual
de comentário (detalhado na subtask, resumido na principal, com timestamp e status) é do fragmento
[`task-manager-auto-update`](../../../commands/common/prompts/task-manager-auto-update.md).

### Atribuir responsável — o campo é `owners_and_work`, e é OBJETO

```
PATCH /projects/{projectId}/tasks/{taskId}
{ "owners_and_work": { "owners": [ { "zpuid": "..." } ] } }      → owners = ["nome"]
```

Medido 2026-09-30, por eliminação: `owners` e `owner` são **aceitos e ignorados** (200, nada muda);
`assignees` dá `INVALID_PARAMETER_VALUE`; `owners_and_work` como **array** dá `JSON_PARSE_ERROR` —
porque ele é **objeto**, e traz também `work_type`, `total_work`, `unit` e `copy_task_duration`.
O identificador da pessoa é o **`zpuid`** (não o `zuid`, que é da conta Zoho).

### `updateStatus(taskId, status)`

```
PATCH /projects/{projectId}/tasks/{taskId}
{ "status": { "id": "<id do status>" } }
```

⚠️ **O campo é `status`, objeto com `id`.** `custom_status` recusa **nome e id**. E **não existe endpoint
que liste os status** — medido: `taskstatuses`, `statuses`, `customstatus`, `custom_status`,
`settings/statuses` e o equivalente V2 devolvem 400. Os ids vêm **de dentro de uma task**:

```json
"status": { "id": "2723266000000016068", "name": "Open", "is_closed_type": false }
```

O adapter **descobre o mapa lendo uma task do projeto** e guarda `{id, name, is_closed_type}`. O
`is_closed_type` é o que distingue status terminal — é o que o mapeamento canônico precisa para saber o
que é "feito".

### `searchTasks(query)`

```
GET /projects/{projectId}/tasks        → { "tasks": [...], "page_info": {...} }
```

⚠️ **`?search=` não filtra** (medido: termo inexistente devolve tudo). O adapter **pagina pelo
`page_info.has_next_page` e filtra no cliente**. Se o volume tornar isso inviável, a resposta honesta é
declarar `searchTasks` como não suportado — nunca devolver a lista inteira como se fosse resultado.

### `validateTaskId(taskId)` · `getProviderFromTaskId(taskId)`

Ids do Zoho são numéricos longos (19 dígitos observados, ex. `2723266000000123001`). Forma:
`/^\d{15,}$/`. ⚠️ **Não são distinguíveis de outros provedores numéricos** (ClickUp usa alfanumérico,
Jira usa `KEY-123`, Linear usa `ABC-123`) — mas um id só-dígitos **não identifica o Zoho com certeza**.
`getProviderFromTaskId` devolve `"zoho"` apenas quando `TASK_MANAGER_PROVIDER=zoho`; fora disso, `null`.
Declarar o limite é melhor que afirmar identificação que não existe.

---

## 🔁 Tratamento de erro

O erro **nomeia o campo**, o que permite tratamento preciso:

```json
{ "error": { "status_code": "400", "title": "EXTRA_KEY_FOUND_IN_JSON",
             "error_type": "FIELDS_VALIDATION_ERROR",
             "details": [ { "message": "Extra key found in JSON.", "field_name": "owner" } ] } }
```

| `title` | o que significa, medido |
|---|---|
| `URL_RULE_NOT_CONFIGURED` | o **path** não existe (use para distinguir path errado de payload errado) |
| `EXTRA_KEY_FOUND_IN_JSON` | o campo **não existe** no recurso |
| `INVALID_PARAMETER_VALUE` | o campo **existe** e o valor é inválido — diferença que economiza horas |
| `LESS_THAN_MIN_OCCURANCE` | campo obrigatório **ausente** (`details[].field_name` diz qual) |
| `INVALID_METHOD` | verbo errado (foi assim que `PATCH` se provou o único) |
| `INVALID_TICKET` | auth — na V2 vem como `{"error":{"code":6890,"message":"Invalid Ticket"}}`, forma diferente |

---

## 🗺️ Mapeamentos

### Status

O mapa canônico→Zoho **não é fixo**: os ids são por projeto e não há endpoint de listagem. O adapter
resolve por **nome**, lendo uma task, e usa `is_closed_type` para o terminal. A tabela canônica vive em
[`../interface.md`](../interface.md).

| canônico | Zoho (nome observado) |
|---|---|
| `backlog` / `todo` | `Open` |
| `in_progress` | `In Progress` |
| `review` | (não há nativo — usar status customizado do projeto) |
| `done` / `closed` / `canceled` | o status com `is_closed_type: true` |

⚠️ `review` **não foi medido** num projeto com status customizado. Declarado como lacuna.

### Prioridade

`None` / `Low` / `Medium` / `High` — mapeamento canônico em [`../interface.md`](../interface.md).
⚠️ **Não medido** contra a API; vem da UI.

---

## 🔗 Referências

- Plataforma (auth, limites, escopos, sondas): [`zoho-projects-api.md`](../../../../docs/knowledge-base/platforms/zoho-projects-api.md)
- Interface: [`../interface.md`](../interface.md) · Fábrica: [`../factory.md`](../factory.md)
- Decisão que põe o Zoho como 6º adapter: `docs/evolution/research/zoho-glpi-adapters-2026-09/`
- Sem especialista dedicado (por critério declarado no CLAUDE.md): usar `@task-specialist`
