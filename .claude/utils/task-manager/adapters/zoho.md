# 🟠 Zoho Projects Adapter

> Instância do padrão [SDAAL](../../../../docs/knowledge-base/concepts/specification-driven-ai-abstraction-layer.md).
> Transporte **único: REST API V3**. **Não há MCP nativo da Zoho para Projects** — e este item é
> **PESQUISADO, não medido**: a varredura de 2026-09-30 (web + registros de MCP) só achou servidores de
> terceiro, e o da CData é read-only com driver JDBC licenciado. Nenhum servidor foi instalado nem
> chamado aqui. A distinção importa porque é esta linha que justifica a assimetria com o `linear.md`,
> que tem transporte dual: **se aparecer MCP oficial, a razão do transporte único cai**. Gatilho para
> re-medir: alguém apontar um servidor oficial da Zoho, ou a próxima rodada do radar de mercado.

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
| `POST` tasklist com `{"milestone_id":…}` | **201**, e a tasklist nasce em milestone `None` |
| `PATCH` task com `{"owners":[…]}` ou `{"owner":{…}}` | **200**, e a atribuição não acontece |
| `POST` task com `{"depth":1}` | **201**, e a task nasce com `depth: 0` |

**Seis casos medidos, todos 2xx** (os `GET`/`PATCH` em 200, os `POST` em 201 — quem escrever
`assert status == 200` a partir daqui quebra nos dois de criação). Isto não é curiosidade: é a regra de desenho deste adapter. O
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

⚠️ **`ZOHO_PORTAL_ID` é o `id` do portal — e as DUAS versões usam o MESMO.** Corrigido em 2026-09-30
por medição, contra o que este arquivo afirmava antes: o `login_id` que a V2 devolve **no topo** do
envelope de `/restapi/portals/` é o **usuário** (bate com `owner.id` da V3), **não** um portal id de
outra versão. Quem o põe na URL recebe **404 `6504 Domain Not Available`** — e não erro de permissão,
como a versão anterior desta linha dizia.

```
V3  GET /api/v3/portals                       → [ { "id": <PORTAL>, "owner": { "id": <USUARIO> } } ]
V2  GET /restapi/portals/                     → { "login_id": <USUARIO>, "portals": [ { "id": <PORTAL> } ] }
                                                             ↑ o USUÁRIO, não um portal
V2  GET /restapi/portal/<PORTAL>/projects/    → 200          ← o id do portal serve na V2
V2  GET /restapi/portal/<USUARIO>/projects/   → 404  6504 Domain Not Available
```

**Como o erro nasceu, porque a classe importa mais que o caso:** `login_id` está no envelope ao lado de
`portals[]`, e eu o li como "o id que a V2 usa" sem chamar a V2 com ele. Nome de campo é declaração; o
que ele **é** só a chamada diz.

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
segredo a menos para guardar e rotacionar.

⚠️ **Reuse o token: pedir um por chamada BLOQUEIA o client.** Medido por um adotante em 2026-10-07: depois
de umas 30 emissões em poucos minutos o accounts.zoho devolveu `{"error":"Access Denied","error_description":
"You have made too many requests continuously…"}` e o client ficou **~5 minutos sem operar** (o número é
estimativa pela contagem das chamadas, não limite documentado). Uma fase do `/engineer:work` que atualiza
várias tasks reproduz isso. O mecanismo é o helper, não esta frase:

```bash
set -a; source .env; set +a                       # no MESMO comando; nunca ler o .env para o contexto
TOKEN="$(bash .claude/utils/task-manager/zoho-token.sh)"            # cache por escopo, renova a 300 s do fim
bash .claude/utils/task-manager/zoho-token.sh --invalidate          # depois de um 401
```

O cache é por `host|client_id|escopo` (token de leitura não serve a escrita), em arquivo 600 fora do
repositório (`${XDG_CACHE_HOME:-$HOME/.cache}/onion/`), e o segredo vai ao curl pela entrada padrão. `ALL` só é documentado para `projects`, `tasks` e
`timesheets`; nos outros módulos peça a operação explícita.

---

## 🗺️ Hierarquia, e o que faz papel de "épico"

```
portal → projeto → milestone → tasklist → task → subtask
```

**Zoho Projects não tem "épico".** O equivalente funcional é o **milestone** (tem início, fim e agrupa
tasklists); a tasklist é o agrupador de segundo nível. Medido montando a árvore inteira.

### Criar milestone: a data segue o FORMATO DO PORTAL, não ISO-8601

```
POST /projects/{projectId}/milestones
{ "name": "…", "start_date": "10-07-2026", "end_date": "10-31-2026" }
```

Medido por um adotante em 2026-10-07 (portal com formato de data padrão `MM-DD-AAAA`):

| `start_date` | resultado |
|---|---|
| `2026-10-07T00:00:00Z`, `…000Z`, `…+00:00`, `…-03:00` | 400 `PATTERN_NOT_MATCHED` |
| `2026-10-07` | 400 `INVALID_PARAMETER_VALUE` |
| **`10-07-2026`** | **201** |

⚠️ Isto **difere da task**, que aceita ISO-8601. O formato segue a configuração de data do portal, então
um portal configurado em `DD-MM-AAAA` pode exigir outra ordem — **teto**: medido num portal só.

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

O vínculo com a tasklist é **objeto aninhado**. `tasklist_id` plano dá **400** (medido; a forma
aceito-e-ignorado da §1 vale para `milestone_id`, **não** para este — não generalize de um para o outro).

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

### `createSubtask(parentId, input)` — **o vínculo é `parental_info`, objeto ANINHADO**

```
POST /projects/{projectId}/tasks
{ "name": "...", "parental_info": { "parent_task_id": "<parentId>" } }     → 201
```

Medido em 2026-09-30, e **conferido no corpo** como manda a §1: a filha nasce com `depth: 1` e
`parental_info.parent_task_id` preenchido, e **o pai passa a `association_info.has_subtasks: true``.

⚠️ **RETRATAÇÃO, e ela ensina mais que o endpoint.** Entre a manhã e a tarde deste mesmo dia esta
seção afirmou duas coisas erradas, em direções opostas:

1. primeiro que a **V2** entregava subtask — com base num `201` que eu não abri. A task nascia RASA;
2. depois que **não havia caminho nenhum** — porque sondei `parent_task`, `parent` e `parent_task_id`
   **no topo do objeto**, os três 400, e concluí impossibilidade a partir de três formas PLANAS.

A segunda conclusão caiu quando a KB de um adotante, mais nova que a nossa, documentou a forma
aninhada — e a sonda confirmou na hora. **O arquivo já continha a resposta**: a §1 diz, em letra
maiúscula, que *todo vínculo é objeto aninhado* e que o `*_id` plano é ignorado. Declarei uma
impossibilidade tendo escrito, acima, a regra que a desfaz. Não foi falta de medição — foi não aplicar
a si a regra que se acabou de descobrir.

**O que fica de mecanismo:** antes de declarar que uma escrita não existe nesta API, **teste a forma
aninhada** — ela é a convenção da casa, não a exceção. Ausência de caminho só se declara depois de
tentar o aninhamento que a §1 prevê.

### `getSubtasks(parentId)` — filtre no CLIENTE pelo `parental_info`

`GET /tasks?parent_task=<id>` devolve **200** e **a listagem completa**, incluindo a própria task pai:
sem filtro 2 tasks, com filtro 2 tasks. O parâmetro é aceito e ignorado, como a §1 descreve.

**O caminho que funciona** é ler `parental_info.parent_task_id` de cada task da listagem e filtrar no
cliente — o campo é confiável (nasce preenchido no POST aninhado e o pai reflete em `has_subtasks`).

**NÃO MEDIDO:** a KB de um adotante documenta um filtro por `criteria`
(`{"criteria":[{"field_name":"parent_task",…}],"pattern":"1"}`). Tentei-o em `POST …/tasks/search` e o
endpoint **não existe** (`URL_RULE_NOT_CONFIGURED`); onde esse corpo é aceito, eu não descobri. Fica
declarado como lacuna, não como inexistência — a distinção que este arquivo pagou caro para aprender.

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
"status": { "id": "<ID_DO_STATUS>", "name": "Open", "is_closed_type": false }
```

O adapter **descobre o mapa lendo uma task do projeto** e guarda `{id, name, is_closed_type}`. O
`is_closed_type` é o que distingue status terminal — é o que o mapeamento canônico precisa para saber o
que é "feito".

⚠️ **No layout PADRÃO não há `In Progress`, e "ler uma task" não acha o mapa.** Medido por um adotante em
2026-10-07, num projeto novo do layout padrão:

| sonda | resultado |
|---|---|
| todas as tasks do portal | só `Open` aparece — ler task nunca encontra outro status |
| `PATCH {"status":{"name":"In Progress"}}` | 400 `status id is invalid or missing` |
| varredura de 30 ids vizinhos de `Open` (task descartável) | só **`Open`** (`is_closed_type: false`) e **`Closed`** (`true`) aceitos |
| `PATCH {"completion_percentage":100}` | 200, e a task vira **`Closed`**, com o id do status no corpo |
| `PATCH {"completion_percentage":10}` | 200, status fica `Open`, 10% gravados |
| `GET /settings/status` (com `module=tasks` e `layout_id=…`) | 200, mas só o status padrão (`Open`), com qualquer filtro |
| `GET /settings/layouts?module=tasks` | 200 só com o escopo `ZohoProjects.custom_fields.READ`; as opções do picklist de status **não vêm** |

**O mecanismo, por status canônico:**

- **`in_progress`** → se o mapa conhecido tiver um status de nome `In Progress`, use o id dele. Senão,
  **mantenha `Open`** e grave `PATCH {"completion_percentage": <n>}`, com `n` proporcional às fases
  concluídas do plano (1–99). É o que o layout padrão tem para "em andamento".
- **`done`** (e `closed`/`canceled` quando não houver status terminal próprio) → `PATCH
  {"completion_percentage": 100}`. A resposta traz o status `Closed` com o **id**, que passa a compor o
  mapa. É o caminho para o terminal que **não depende de saber o id antes**.
- O `is_closed_type` continua sendo a fonte de verdade do "terminal".

**Teto:** medido num portal só, de teste, no layout padrão. Um portal com status customizados pode ter
`In Progress` (e o mecanismo o usa quando existe); nenhum escopo emitido lista os status de um layout
(`ZohoProjects.settings.READ` e `.layouts.READ` não são emitidos pelo accounts.zoho).

### `searchTasks(query)`

```
GET /projects/{projectId}/tasks        → { "tasks": [...], "page_info": {...} }
```

⚠️ **`?search=` não filtra** (medido: termo inexistente devolve tudo). O adapter **pagina pelo
`page_info.has_next_page` e filtra no cliente**. Se o volume tornar isso inviável, a resposta honesta é
declarar `searchTasks` como não suportado — nunca devolver a lista inteira como se fosse resultado.

### `validateTaskId(taskId)` · `getProviderFromTaskId(taskId)`

Ids do Zoho são numéricos longos (19 dígitos observados). Forma:
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
| `EXTRA_KEY_FOUND_IN_JSON` | chave desconhecida — **medido em `/milestones`** |
| `INVALID_PARAMETER_VALUE` | **depende do recurso, e NÃO prova que o campo existe** — ver abaixo |
| `LESS_THAN_MIN_OCCURANCE` | campo obrigatório **ausente** (`details[].field_name` diz qual) |
| `INVALID_METHOD` | verbo errado (foi assim que `PATCH` se provou o único) |
| `INVALID_TICKET` | auth — na V2 vem como `{"error":{"code":6890,"message":"Invalid Ticket"}}`, forma diferente |

⚠️ **A leitura "`INVALID_PARAMETER_VALUE` ⇒ o campo existe" é FALSA, e era minha.** Medido em
`/tasks` em 2026-09-30: chave **inventada agora** dá exatamente o mesmo erro que um nome plausível.

```
parent_task                   → INVALID_PARAMETER_VALUE  "Enter a valid custom field."
parent_task_id                → INVALID_PARAMETER_VALUE  "Enter a valid custom field."
campo_que_nunca_existiu_zzz   → INVALID_PARAMETER_VALUE  "Enter a valid custom field."
```

Em `/tasks` o erro quer dizer *"chave desconhecida, e nem custom field válido"*; a mesma chave
desconhecida em `/milestones` dá `EXTRA_KEY_FOUND_IN_JSON`. **O vocabulário de erro varia por recurso** —
tratar por `title` só vale dentro do recurso onde foi medido. Foi esta inferência que me fez acreditar
que `parent_task` existia, e daí que a V2 entregava subtask: **um erro de leitura produziu uma promessa
de API**.

⚠️ **A forma do erro também muda:** `DELETE /projects/{id}` devolve `"error": [ {…} ]` — **array**, não
o objeto acima. Parser escrito a partir de um único exemplo quebra, que é literalmente a §2 deste
arquivo aplicada ao canal de erro.

---

## 🗺️ Mapeamentos

### Status

O mapa canônico→Zoho **não é fixo**: os ids são por projeto e não há endpoint de listagem. O adapter
resolve por **nome**, lendo uma task, e usa `is_closed_type` para o terminal. A tabela canônica vive em
[`../interface.md`](../interface.md).

| canônico | Zoho (nome observado) |
|---|---|
| `backlog` / `todo` | `Open` |
| `in_progress` | `In Progress` **se o mapa tiver**; no layout padrão, `Open` + `completion_percentage` 1–99 |
| `review` | (não há nativo — usar status customizado do projeto) |
| `done` / `closed` / `canceled` | o status com `is_closed_type: true` — sem id conhecido, `completion_percentage: 100` (devolve o de `Closed`) |

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
