---
versao: 1.1.0
data: 2026-09-30
categoria: platforms
applies_to: "Zoho Projects API V3 (V2 em maintenance mode desde 2026-01-01, EOL 2026-12-31 — ainda NO AR nesta data)"
verified_at: 2026-09-30
verified_against: "absorvida de um adotante hub em 2026-09-30, com scrub. A data do EOL da V2 foi corrigida DUAS VEZES no mesmo dia, e o registro fica porque a lição é a classe: a KB de origem dizia 2025-12-31; uma 1a busca me deu 2026-06-30 e eu GRAVEI isso; a leitura da fonte (help.zoho.com, topico Update on V2 API End-of-Life Timeline) devolveu 31st December, 2026 verbatim, com 2025-12-31 sendo apenas o inicio do maintenance mode. Resultado: a V2 AINDA ESTA NO AR em 2026-09-30, o oposto do que a 2a versao desta linha afirmava. Busca que RESUME nao substitui fonte que DECLARA. Os endpoints e limites NAO foram chamados contra instancia real."
---

# Zoho Projects API — Knowledge Base


> **Categoria**: Platforms
> Referência técnica da **Zoho Projects REST API V3**: autenticação OAuth 2.0 (Self Client e
> fluxo web), geração/renovação de tokens, data centers, escopos, paginação, rate limit e erros.
> Tudo com fonte na documentação oficial da Zoho; o que extrapola a fonte está `[INFERÊNCIA]`.

---

## 📋 Metadata

| Campo | Valor |
|-------|-------|
| **Versão** | 1.1.0 |
| **Data de Criação** | 2026-09-30 |
| **Última Atualização** | 2026-09-30 (v1.1: endpoints de tarefa + webhooks/automação) |
| **Categoria** | platforms |
| **Versão da API** | V3 (`/api/v3/`) — a única viva desde 2026-01-01 |
| **Fontes Principais** | [1] <https://projects.zoho.com/api-docs> (V3, oficial) · [2] <https://www.zoho.com/accounts/protocol/oauth/self-client/overview.html> · [3] <https://www.zoho.com/accounts/protocol/oauth/self-client/authorization-code-flow.html> · [4] <https://www.zoho.com/accounts/protocol/oauth/web-apps/authorization.html> · [5] <https://www.zoho.com/accounts/protocol/oauth/multi-dc.html> · [6] <https://www.zoho.com/developer/oauth/token-limits.html> · [7] <https://www.zoho.com/projects/help/rest-api/zohoprojectsapi.html> (legado) · [8] <https://ascentbusiness.co.uk/zoho-projects-api-deadline-migrate-to-v3-by-31-december-2025/> · [9] <https://www.zoho.com/projects/taskautomation.html> · [10] <https://www.zoho.com/projects/zoho-flow-integrations.html> |

---

## 📋 Visão Geral

O **Zoho Projects** é o gerenciador de projetos SaaS da Zoho (projetos, tasklists, tasks, milestones,
bugs/issues, timesheets, documentos, fóruns). A API REST expõe esses módulos para integração.

| Ponto | Valor | Fonte |
|---|---|---|
| Versão vigente | **V3**: prefixo `/api/v3/`, JSON puro, datas ISO-8601, `PATCH` para update | [1] |
| Legado (`/restapi/`) | **desligado**: pré-V3 retorna 4xx desde 2026-01-01 (prazo 2025-12-31 23:59 UTC) | [8] |
| Autenticação | OAuth 2.0; header `Authorization: Bearer <access_token>` | [1] |
| Unidade raiz | **portal** (a organização no Zoho Projects); quase toda rota é `/api/v3/portal/{portal_id}/...` | [1] |
| Formato | JSON (request = response: o mesmo shape volta e vai, ex.: `assignee: {zpuid, name}`) | [1] |

### Hierarquia de recursos

```
Portal (portal_id)
 └─ Project (project_id)
     ├─ Milestone
     ├─ Tasklist
     │   └─ Task ── Subtask
     ├─ Issue / Bug
     ├─ Timesheet (timelog)
     ├─ Document · Forum · Event
     └─ Custom fields (api_name, ex.: cf_priority_level)
```

---

## 🎯 Casos de Uso

| Use quando | Não use quando |
|---|---|
| Sincronizar tasks/projetos Zoho com outro sistema (ERP, BI, service desk) | Precisa de reação em tempo real: prefira **Webhooks + Workflow Rules** nativos [1][9] a polling (ver [Tarefas e Automação](#-tarefas-e-automação)) |
| Extrair timesheets e horas para faturamento ou relatórios | Carga massiva recorrente: há **Data Backup/Portal Export** nativos (1 export a cada 24 h [1]) |
| Criar tasks programaticamente a partir de outro fluxo | O dado vive em outro produto Zoho (CRM, Books): o token com escopo Projects **não** serve lá [7] |
| Automação back-end sem usuário interativo (Self Client) | App multiusuário/multi-org público: use o fluxo web com `redirect_uri`, não Self Client |

---

## ⚡ Quick Start — Self Client (back-end, sem redirect)

O **Self Client** gera um grant token da própria organização, sem domínio nem redirect URL. É o caminho
certo para um job servidor ou script [1][2].

### 1. Criar o Self Client

1. Acessar o **Zoho API Console** do seu data center (ex.: <https://api-console.zoho.com>) [2].
2. **GET STARTED → Self Client → CREATE NOW → OK** [2].
3. Na aba **Client Secret**, copiar `client_id` e `client_secret` [1].

### 2. Gerar o grant code

1. Aba **Generate Code** → informar os **escopos separados por vírgula** (ver [Escopos](#-escopos-oauth)).
   Escopo inválido gera o erro *"Enter a valid scope"* [1].
2. Escolher a **Time Duration** (validade do código; o default é **3 minutos**) [3].
3. Descrição → **Create** → copiar o código. **Use-o imediatamente**, porque ele expira.

### 3. Trocar o grant code por tokens

```bash
# accounts-server-url depende do DC (tabela abaixo). US = https://accounts.zoho.com
curl -X POST "https://accounts.zoho.com/oauth/v2/token" \
  -d "grant_type=authorization_code" \
  -d "client_id=$ZOHO_CLIENT_ID" \
  -d "client_secret=$ZOHO_CLIENT_SECRET" \
  -d "code=<GRANT_CODE>"
```

Resposta [3]:

```json
{
  "access_token": "1000.xxxx",
  "refresh_token": "1000.yyyy",
  "api_domain": "https://www.zohoapis.com",
  "token_type": "Bearer",
  "expires_in": 3600
}
```

> ⚠️ O `refresh_token` **só aparece nessa troca**. Guarde-o no `.env` na hora. Se perder, gere um
> novo grant code.

### 4. Renovar o access token (a cada ≤ 1 h)

```bash
curl -X POST "https://accounts.zoho.com/oauth/v2/token" \
  -d "grant_type=refresh_token" \
  -d "client_id=$ZOHO_CLIENT_ID" \
  -d "client_secret=$ZOHO_CLIENT_SECRET" \
  -d "refresh_token=$ZOHO_REFRESH_TOKEN"
```

### 5. Descobrir o `portal_id` e chamar a API

```bash
# Escopo: ZohoProjects.portals.READ
curl -s "https://projects.zoho.com/api/v3/portals" \
  -H "Authorization: Bearer $ZOHO_ACCESS_TOKEN"

# Listar projetos do portal (escopo ZohoProjects.projects.READ)
curl -s "https://projects.zoho.com/api/v3/portal/$ZOHO_PORTAL_ID/projects?page=1&per_page=100" \
  -H "Authorization: Bearer $ZOHO_ACCESS_TOKEN"

# Tasks de um projeto (escopo ZohoProjects.tasks.READ)
curl -s "https://projects.zoho.com/api/v3/portal/$ZOHO_PORTAL_ID/projects/$PROJECT_ID/tasks" \
  -H "Authorization: Bearer $ZOHO_ACCESS_TOKEN"
```

### Variáveis de ambiente sugeridas `[INFERÊNCIA]`

```bash
# .env (NUNCA versionar; o .gitignore deste repo já protege o .env)
ZOHO_DC=com                         # com | eu | in | com.au | jp | ...
ZOHO_ACCOUNTS_URL=https://accounts.zoho.com
ZOHO_PROJECTS_API_URL=https://projects.zoho.com
ZOHO_CLIENT_ID=1000.xxxx
ZOHO_CLIENT_SECRET=xxxx
ZOHO_REFRESH_TOKEN=1000.xxxx        # longa duração: é o segredo que importa
ZOHO_PORTAL_ID=12345678
# ZOHO_ACCESS_TOKEN não se guarda: é derivado (1 h) e renovado em runtime
```

---

## 🔐 OAuth 2.0 — Referência

### Fluxos disponíveis

| Fluxo | Quando | Refresh token? | Fonte |
|---|---|---|---|
| **Self Client: authorization code** | Script/job servidor da própria org | ✅ sim | [2][3] |
| **Self Client: client credentials** | Back-end que só precisa do token | ❌ não: repete a requisição a cada expiração | [2] |
| **Web app (server-based)** | App com usuários e `redirect_uri` | ✅ com `access_type=offline` | [4] |

### Fluxo web: URL de autorização [4]

```
GET {accounts-server-url}/oauth/v2/auth
  ?response_type=code
  &client_id=<CLIENT_ID>
  &scope=ZohoProjects.portals.READ,ZohoProjects.tasks.ALL
  &redirect_uri=<URI registrada no console>
  &access_type=offline      # obrigatório para receber refresh_token (default = online)
  &prompt=consent           # força a tela de consentimento
```

O redirect volta com `code`, `location` e `accounts-server`. Troque o `code` no `accounts-server`
**retornado**, não no US fixo [5].

### Validade e limites de tokens

| Item | Limite | Fonte |
|---|---|---|
| Access token | **1 hora** (`expires_in: 3600`) | [3] |
| Refresh token | Sem expiração até ser revogado | [6]* |
| Refresh tokens ativos por usuário/client | **20**; o 21º invalida o mais antigo | [6] |
| Access tokens ativos por refresh token | **10** | [6] |
| Pedidos de access token | **10 a cada 10 minutos** (throttle) | [6] |
| Authorization codes | 10 por usuário em 10 min | [6] |

\* Validade "ilimitada até revogação" vem de páginas de token-validity de outros produtos Zoho, que
seguem o mesmo servidor de contas. Para o Zoho Projects especificamente, é `[INFERÊNCIA]`.

**Consequências práticas:**
- **Faça cache do access token** e renove só perto do vencimento. Renovar a cada chamada estoura o
  throttle de 10/10 min.
- Não gere refresh token novo a cada deploy. O 21º derruba silenciosamente o mais antigo, e outra
  integração pode ser a vítima.

### Multi-DC: accounts × API por região [1][5]

| DC | Accounts server | Projects API base |
|---|---|---|
| US | `https://accounts.zoho.com` | `https://projects.zoho.com` |
| EU | `https://accounts.zoho.eu` | `https://projects.zoho.eu` |
| IN | `https://accounts.zoho.in` | `https://projects.zoho.in` |
| AU | `https://accounts.zoho.com.au` | `https://projects.zoho.com.au` |
| JP | `https://accounts.zoho.jp` | `https://projects.zoho.jp` |
| CA | `https://accounts.zohocloud.ca` | `https://projects.zohocloud.ca` |
| SA | `https://accounts.zoho.sa` | `https://projects.zoho.sa` |
| UK | `https://accounts.zoho.uk` | `https://projects.zoho.uk` |
| CN / UAE / SG | ver `serverinfo` | `projects.zoho.com.cn` / `.ae` / `.sg` |

- Descoberta dinâmica: `GET https://accounts.zoho.com/oauth/serverinfo` [5].
- A resposta de token traz `location` e `api_domain`: use-os para escolher a base, **nunca hardcode** [1].
- Um app multi-região precisa **habilitar Multi-DC no API Console** (Settings → toggle por DC). O
  `client_id` é comum; o `client_secret` pode ser comum ou por DC [5].

---

## ✅ O caminho que FUNCIONOU, medido com credencial real (2026-09-30)

⚠️ **Esta seção corrige o Quick Start acima, que ensina o caminho mais difícil como se fosse o único.**
O Self client aceita **`client_credentials`**, e esse fluxo **dispensa o grant code** — logo dispensa a
corrida contra a expiração dele, que é de **~3 minutos** (medido no `expiry_time` do `self_client.json`,
não os 10 que a tela sugere). Duas tentativas pelo caminho do código falharam antes de alguém notar que
ele não era necessário: `invalid_client` (o `client_id` copiado sem o prefixo `1000.`) e `invalid_code`
(expirado 2min45 depois de gerado).

```bash
# nenhum grant code, nenhum refresh_token, nenhum redirect
curl -s -X POST 'https://accounts.zoho.com/oauth/v2/token' \
  -d grant_type=client_credentials \
  -d "client_id=${ZOHO_CLIENT_ID}" \
  -d "client_secret=${ZOHO_CLIENT_SECRET}" \
  -d "scope=ZohoProjects.portals.READ,ZohoProjects.projects.READ,ZohoProjects.tasks.ALL"
# → {"access_token":"1000.…","scope":"…","api_domain":"https://www.zohoapis.com",
#    "token_type":"Bearer","expires_in":3600}
```

| o que se mediu | resultado |
|---|---|
| precisa de `grant code`? | **não** |
| vem `refresh_token`? | **não vem, e não faz falta**: o token dura 3600 s e se pede de novo com o mesmo par id+secret |
| `soid` é obrigatório? | **não** — funcionou com e sem |
| o token chama a API de verdade? | **sim, HTTP 200** em `/api/v3/portals` **e** `/restapi/portals/`, nos **dois** hosts |

**Um refresh_token a menos é um segredo a menos para guardar e rotacionar** — para um job de servidor
que é dono dos próprios dados, `client_credentials` é o caminho mais simples E o mais seguro.

### ⚠️ O `login_id` do envelope V2 é o USUÁRIO, não um portal id

Corrigido em 2026-09-30 **por medição**, contra o que esta seção afirmava antes. As duas versões usam
o **mesmo** id de portal no caminho:

```
V3  GET /api/v3/portals                       → [ { "id": <PORTAL>, "owner": { "id": <USUARIO> } } ]
V2  GET /restapi/portals/                     → { "login_id": <USUARIO>, "portals": [ { "id": <PORTAL> } ] }
V2  GET /restapi/portal/<PORTAL>/projects/    → 200
V2  GET /restapi/portal/<USUARIO>/projects/   → 404  6504 Domain Not Available
```

`login_id` está **no topo** do envelope, ao lado de `portals[]`, e bate com `owner.id` da V3 — é o dono,
não uma variante de portal id. O erro de trocá-los **não** parece de permissão: é `6504 Domain Not
Available`, um 404. A lição de classe: **nome de campo é declaração**; o que ele é só a chamada diz. E o
teste de fumaça de qualquer
integração nova é pedir o portal e conferir de qual campo veio.

### A forma da resposta MUDA entre as versões, e isso é decisão de parsing

```
V3  GET /api/v3/portals    → [ {"owner":{…},"id":…}, … ]          ← ARRAY no topo
V2  GET /restapi/portals/  → { "login_id":"…","portals":[ … ] }   ← OBJETO com envelope
```

Um adapter que assume envelope quebra na V3; um que assume array quebra na V2 — e a V2 **ainda está no
ar** até 2026-12-31. O mesmo vale para o erro: V3 traz `status_code`/`title`/`instance`, V2 traz `code`
numérico + `message`.

## 🔬 Medido por sonda sem credencial (2026-09-30)

Três fatos que **nenhuma busca entregou** e um `curl` de doze segundos resolveu. Vale como método: a
sonda sem credencial custa quase nada e derruba suposição — foi pedido do maestro, *"pequenos testes
para não perder tempo com suposições"*.

| pergunta | medição | consequência |
|---|---|---|
| `projects.zoho.com` e `projectsapi.zoho.com` são a mesma coisa? | **sim**, para estes paths: os dois respondem `/api/v3/portals` **e** `/restapi/portals/` com o mesmo erro de auth | a "divergência de dois hosts na doc" deixa de ser incerteza de desenho; escolha um e siga |
| a V2 já saiu do ar? | **não**: `/restapi/` devolve **401**, não 404 nem 410 | confirma o EOL de 2026-12-31 **por comportamento**, não por anúncio — e é a evidência que vale |
| o erro tem a mesma forma nas duas versões? | **não** | é decisão de adapter, e a mais fácil de esquecer |

```
V3  GET /api/v3/portals    → 401 {"error":{"status_code":"401","instance":"/api/v3/portals","title":"INVALID_TICKET",…}}
V2  GET /restapi/portals/  → 401 {"error":{"code":6890,"message":"Invalid Ticket"}}
```

O tratamento de erro do adapter precisa das **duas** formas: a V3 traz `status_code`/`title`/`instance`
(string no `status_code`, não inteiro), a V2 traz `code` numérico + `message`. Um adapter que só lê
`error.code` fica cego na V3, e um que só lê `error.title` fica cego na V2 — que **ainda está no ar**.

**Fronteira declarada:** a sonda foi feita **sem credencial**, logo ela prova roteamento, versão viva e
forma de erro. Ela **não** prova cobertura de campo, paginação, rate limit nem o mapeamento de
`updateStatus`/`custom_status` — isso exige token e fica aberto.

## ⚠️ "O console está me pedindo Authorized Redirect URIs"

**Então você está no tipo errado de client** — e este é o tropeço mais comum de quem começa, medido em
2026-09-30. O **Self Client não tem esse campo**: ele existe exatamente para o caso sem navegador e sem
usuário autorizando. Se o campo apareceu, volte e crie como *Self Client*; saem só Client ID + Secret,
e o código você gera na própria console.

Se ainda assim você **quiser** o fluxo web (Server-based Application), os valores são:

| onde roda | o que registrar |
|---|---|
| máquina local / sessão de agente | `http://localhost:8080/callback` — o Zoho aceita `http://` para localhost |
| servidor próprio | `https://<seu-domínio>/oauth/callback` — HTTPS real |

Três coisas que economizam uma tarde:

- **O match é EXATO**: barra final, porta, `http` × `https`. Qualquer diferença devolve
  `invalid_redirect_uri`, e a mensagem **não diz qual parte divergiu**.
- **Cadastre as duas URIs no MESMO client** (o console aceita várias) em vez de manter dois clients.
- **O redirect só serve para a troca inicial**: com o `refresh_token` em mão, nada mais passa por ele.
  É por isso que o Self Client resolve o caso de back-end sem esse campo sequer existir.

## 🔑 Escopos OAuth

Formato: `ZohoProjects.<módulo>.<OPERAÇÃO>`, com operação em `READ | CREATE | UPDATE | DELETE | ALL`. Os
escopos são separados por vírgula. `ALL` cobre as quatro operações [1].

| Módulos com escopo próprio (V3) [1] |
|---|
| `portals` · `projects` · `projectgroups` · `milestones` · `tasklists` · `tasks` · `bugs` · `timesheets` · `users` · `teams` · `clients` · `documents` · `forums` · `events` · `tags` · `status` · `custom_fields` · `extensions` · `integrations` · `leave` · `skillset` · `bulk` · `custom_functions` |

`ALL` aparece documentado para `projects`, `tasks` e `timesheets` [1]. Para os demais módulos, peça
as operações explícitas.

**Conjuntos mínimos sugeridos** `[INFERÊNCIA]`:

| Integração | Escopos |
|---|---|
| Leitura/BI | `ZohoProjects.portals.READ,ZohoProjects.projects.READ,ZohoProjects.tasks.READ,ZohoProjects.timesheets.READ,ZohoProjects.users.READ` |
| Sync bidirecional de tasks | acima + `ZohoProjects.tasks.ALL,ZohoProjects.tasklists.READ,ZohoProjects.milestones.READ` |

> Token com escopo de Zoho Projects **não** funciona no Zoho BugTracker, e o contrário também vale [7].

---

## 📐 Convenções da V3

### Paginação

`page` + `per_page`, com `page_info` na resposta [1]:

```json
{ "page_info": { "page": 1, "per_page": 100, "page_count": 100, "has_next_page": true },
  "projects": [ ... ] }
```

Itere enquanto `has_next_page == true`. (O legado usava `index` + `range`, com range ≤ 200 [7].)

### Datas, updates e custom fields [1]

| Área | V2 (`/restapi`, morto) | V3 (`/api/v3`) |
|---|---|---|
| Data | `05-26-2014`, epoch… | `2024-05-26` ou `2024-05-26T11:25:58.000Z` (ISO-8601) |
| Update | `POST` | **`PATCH`** |
| Custom field | `UDF_CHAR1` | `api_name` (ex.: `cf_priority_level`) |
| Filtro | vários params | objeto `filter.criteria[]` + `pattern` |

### Rate limit [1]

- **200 chamadas por janela de 2 minutos, por endpoint.**
- Headers em toda resposta: `RateLimit`, `RateLimit-Remaining`, `RateLimit-Window`, `RateLimit-Window-Unit`.
- Ao exceder, **aquele endpoint fica bloqueado por 10 minutos** e a resposta traz `Retry-After` (segundos).
- ⚠️ Fontes antigas citam 100 chamadas/2 min com lock de 30 min [7][8]. Isso é do legado; vale a doc V3.

### Erros [1]

```json
{ "error": { "status_code": "400", "instance": "/api/v3/portal/25450296/...",
  "method": "GET", "error_type": "FIELDS_VALIDATION_ERROR",
  "details": [ { "message": "Invalid module", "field_name": "module" } ],
  "title": "INVALID_PARAMETER_VALUE" } }
```

| Código | HTTP | Significado / ação |
|---|---|---|
| `INVALID_OAUTHTOKEN` | 400 | Token inválido/expirado: renove com o refresh token |
| `URL_RULE_NOT_CONFIGURED` | 400 | URL errada: confira prefixo `/api/v3/` e DC |
| `INVALID_INPUTSTREAM` / `INVALID_PARAMETER_VALUE` | 400 | Parâmetro ou payload inválido |
| `INVALID_METHOD` | 400 | Método HTTP errado (ex.: `POST` onde a V3 pede `PATCH`) |
| `INTERNAL_SERVER_ERROR` | 500 | Erro do servidor: `support@zohoprojects.com` |

Note: token expirado volta como **400, não 401**. Um cliente que só renova em 401 nunca renova.

---

## 🧩 Tarefas e Automação

### Endpoints de tarefa (V3) [1]

| Operação | Método e rota | Escopo |
|---|---|---|
| Criar tarefa | `POST /api/v3/portal/{portal_id}/projects/{project_id}/tasks` | `tasks.CREATE` |
| Atualizar tarefa | `PATCH /api/v3/portal/{portal_id}/projects/{project_id}/tasks/{task_id}` | `tasks.UPDATE` |
| Comentar na tarefa | `POST /api/v3/portal/{portal_id}/projects/{project_id}/tasks/{task_id}/comments` (`{"comment": "..."}`) | `tasks.CREATE` |
| Listar tasklists | `GET /api/v3/portal/{portal_id}/projects/{project_id}/tasklists` | `tasklists.READ` |

Campos principais do **Create Task** [1]:

| Campo | Regra |
|---|---|
| `name` | **Obrigatório**, até 10000 caracteres |
| `description` | Até 80000 caracteres |
| `tasklist.id` | Sem ele, a tarefa cai na lista geral |
| `parental_info.parent_task_id` | Cria como subtarefa |
| `status.id` | Default: aberta |
| `priority` | `none` · `low` · `medium` · `high` |
| `start_date` / `end_date` | ISO-8601 (`yyyy-MM-dd'T'HH:mm:ss'Z'` ou com offset) |
| `owners_and_work.owners[]` | Por `zpuid`, `zuid` ou `email` |
| `tags`, `teams` | Objetos `add`/`remove` com ids |
| Custom fields | Por `api_name` (ex.: `cf_glpi_ticket_id`) |

### Webhooks e Workflow Rules [9]

- **Webhook** = notificação HTTP de saída para um sistema terceiro. **Só dispara quando associado a
  uma Workflow Rule** (ou Business Rule) cujas condições casam [9].
- **Workflow Rule** = gatilho + condição + ações (atribuir, atualizar campo, e-mail, webhook, custom function) [9].
- Também há **Macro Rules** (atualização em lote) e **Blueprints** (máquina de estados de tarefa) [1][9].
- **Zoho Flow** é a alternativa low-code para ligar o Projects a apps externos [10].
- Autenticar o webhook de saída (segredo no header/URL) e validar no receptor fica por conta do
  integrador `[INFERÊNCIA]`. A disponibilidade de webhooks pode variar por plano `[INFERÊNCIA]`.

> Fluxo completo usando isto: [GLPI → Zoho: chamado vira tarefa](../patterns/glpi-zoho-ticket-to-task.md).

---

## 💡 Best Practices

1. **V3 sempre**: qualquer código, SDK ou exemplo com `/restapi/` está morto desde 2026-01-01 [8].
2. **Menor escopo possível**: os escopos aparecem na tela de consentimento [1].
3. **Base URL derivada do token** (`api_domain`/`location`), nunca fixa no US [1][5].
4. **Cache do access token + renovação proativa** (~55 min), respeitando 10 renovações/10 min [6].
5. **Backoff guiado por `Retry-After`** e leitura de `RateLimit-Remaining` antes de lotes [1].
6. **Renovar em `INVALID_OAUTHTOKEN`**, não em 401 (ver erros acima) [1].
7. **Datas em ISO-8601 UTC** no payload. Formato errado gera 400 [1][8].
8. **Custom fields por `api_name`**, descoberto via *Module Meta → Get Field Info* [1].

---

## ⚠️ Limitações e Gotchas

| Gotcha | Detalhe |
|---|---|
| Grant code expira rápido | Default de 3 min: gere o código e troque em seguida [3] |
| Refresh token some | Só vem na troca inicial (e, no fluxo web, só com `access_type=offline`) [3][4] |
| Teto de 20 refresh tokens | Regerar demais invalida o token de outra integração em silêncio [6] |
| Bloqueio de 10 min | O rate limit é por endpoint; um loop de polling tranca o endpoint inteiro [1] |
| Dois hosts na doc | A V3 usa `projects.zoho.com` como raiz; exemplos e URLs de export mostram `projectsapi.zoho.com` [1][7]. Padronize no primeiro e trate o segundo como alias `[INFERÊNCIA]` |
| Header de auth | Projects V3 documenta `Bearer`. Outros produtos Zoho (ex.: CRM) documentam `Zoho-oauthtoken`: não copie exemplos entre produtos `[INFERÊNCIA]` |
| Escopo por produto | O token do Projects não vale no BugTracker nem em outros apps Zoho [7] |
| Portal export | 1 por 24 h (`EXPORT_ONCE_IN_24_HOURS`) [1] |

---

## 🧪 Sonda de ESCRITA em portal real (2026-09-30) — o que só a chamada revelou

Projeto descartável criado, hierarquia montada, medida e apagada. Sete achados que **nenhuma doc e
nenhuma busca** deram, e cada um é decisão de adapter:

| # | achado | evidência |
|---|---|---|
| 1 | o segmento é **`portal` singular** | `/api/v3/portal/{id}/projects` → 200 · `/api/v3/portals/{id}/projects` → 400 `URL_RULE_NOT_CONFIGURED` |
| 2 | **vínculo é OBJETO ANINHADO, não `*_id`** | `{"milestone":{"id":"…"}}` vincula · `{"milestone_id":"…"}` é **aceito e IGNORADO em silêncio** (a tasklist nasce em milestone `None`) |
| 3 | o update é **PATCH**, e só | `PUT` e `POST` no recurso devolvem `INVALID_METHOD` |
| 4 | status se muda por **`status`**, objeto com `id` | `{"status":{"id":"…"}}` → 200 · `{"custom_status": <nome ou id>}` → `INVALID_PARAMETER_VALUE` nas duas formas |
| 5 | **não achei endpoint que LISTE os status** | `taskstatuses`, `statuses`, `customstatus`, `custom_status`, `settings/statuses` e o equivalente V2: todos 400. O id do status vem **de dentro da própria task** |
| 6 | o erro de validação **nomeia o campo** | `EXTRA_KEY_FOUND_IN_JSON` + `details[].field_name: "owner"` — dá para tratar com precisão |
| 7 | o `login_id` da V2 é o **usuário**, não um portal id | as duas versões usam o mesmo id de portal no caminho; o `login_id` bate com `owner.id` da V3, e usá-lo na URL dá **404 `6504 Domain Not Available`** (achado corrigido por medição; a 1ª redação estava invertida) |
| 8 | **remover projeto é `POST …/trash`**, não `DELETE` | `DELETE /projects/{id}` → 404 (e o erro cita `method: POST`) · `DELETE /projects/{id}/` → 400 · **`POST /projects/{id}/trash` → 204** · e o `PATCH` seguinte devolve **410 Gone**, que é a confirmação por comportamento |

**O achado nº 2 é o mais perigoso**, e por isso está aqui em primeiro lugar entre iguais: `milestone_id`
não dá erro. A chamada devolve **200** e o vínculo simplesmente não acontece. Um adapter escrito por
analogia com outras APIs (`*_id` em tudo) passaria em teste de status HTTP e produziria hierarquia
silenciosamente quebrada. **Verificar o vínculo no corpo da resposta, nunca no código HTTP.**

**Consequência do nº 5 para o mapeamento:** sem endpoint de listagem, o adapter descobre os status
possíveis **lendo uma task do projeto** e guardando o `{id, name}`. `is_closed_type` vem no objeto e é o
que distingue status terminal — é o que o `updateStatus` da abstração precisa para saber o que é "feito".

**A sonda é reversível, e isso foi verificado:** depois do `trash`, a listagem do portal voltou a ter
exatamente o projeto que existia antes. Uma sonda de escrita só é aceitável se o caminho de volta for
medido — e o caminho de volta aqui **não** é o que se supõe (`DELETE` falha de duas formas diferentes).

### Vocabulário: Zoho Projects não tem "épico"

A hierarquia é `projeto → milestone → tasklist → task → subtask`. O equivalente funcional de épico é o
**milestone** (tem data de início e fim, e agrupa tasklists) — a tasklist é o agrupador de segundo nível.
Medido montando a árvore inteira: projeto → milestone → tasklist → task, com o vínculo do nº 2.

## 🔌 MCP: não existe servidor NATIVO da Zoho para Projects

Medido em 2026-09-30. A Zoho publica MCP oficial para **Analytics**, **não** para Projects. O que existe
para Projects é de terceiro:

| opção | natureza | limite |
|---|---|---|
| `qpiai/zoho-projects-mcp` | comunitário | manutenção de terceiro; cobre portal, projeto, task, issue, milestone, busca, usuários |
| CData Zoho Projects MCP | comercial | **read-only**, e exige driver JDBC licenciado à parte + arquivo `.prp` de conexão |
| wrappers de plataformas de integração | SaaS | acrescenta um intermediário entre você e a API |

**Isto simplifica o desenho, e a doutrina da casa já dizia por quê:** o adapter é **API-first** e o MCP é
transporte **opcional** (SDAAL). Sem MCP nativo não há atalho tentador — o adapter fala REST direto, que
é o caminho provado por medição nesta KB. Um MCP de terceiro no meio acrescentaria uma dependência que
não se controla e que fica entre o gate e o dado.

⚠️ Sinal relatado pela comunidade e **não medido aqui**: o schema de ferramentas de um desses MCPs
divergia da doc REST. Se algum dia um MCP entrar como transporte, ele entra **atrás** da abstração e com
a divergência medida, nunca como fonte de verdade sobre a API.

## 🗺️ Mapeamento método↔endpoint (o adapter do Onion)

Derivado de **duas sondas de escrita** em portal real (2026-09-30), com projeto descartável e limpeza
verificada. O adapter é [`adapters/zoho.md`](../../../.claude/utils/task-manager/adapters/zoho.md).

| método da abstração | endpoint medido | achado que muda a implementação |
|---|---|---|
| `getProjectList` | `GET /portal/{p}/projects` | **array no topo**, sem envelope |
| `getProject` | `GET …/projects/{id}` | — |
| `createTask` | `POST …/projects/{pr}/tasks` | vínculo `{"tasklist":{"id":…}}` — objeto, não `*_id` |
| `getTask` | `GET …/tasks/{id}` | o `status` vem como objeto com `is_closed_type` |
| `updateTask` | **`PATCH`** …/tasks/{id}` | `PUT`/`POST` → `INVALID_METHOD` |
| `deleteTask` | **`DELETE`** …/tasks/{id}` → 204 | ⚠️ **assimétrico**: projeto exige `POST …/trash` |
| `createSubtask` | `POST …/tasks` com `{"parental_info":{"parent_task_id":…}}` | vínculo **aninhado**; filha nasce `depth: 1` e o pai vira `has_subtasks: true` (conferido no corpo). As formas PLANAS (`parent_task`, `parent`, `parent_task_id` no topo) dão 400, e a V2 devolve 201 com task RASA — duas redações anteriores erraram, uma em cada direção |
| `getSubtasks` | filtrar no CLIENTE por `parental_info.parent_task_id` | `?parent_task=` é aceito e ignorado (lista inteira). O filtro por `criteria` que um adotante documenta NÃO foi localizado: `POST …/tasks/search` devolve `URL_RULE_NOT_CONFIGURED` — lacuna declarada, não inexistência |
| `addComment` | `POST …/tasks/{id}/comments`, campo **`comment`** | resposta é **array**; `content`/`text`/`body` dão `LESS_THAN_MIN_OCCURANCE` |
| `getComments` | `GET …/tasks/{id}/comments` | resposta é **objeto** `{comments, page_info}` — forma diferente do POST |
| `updateStatus` | `PATCH …/tasks/{id}` com `{"status":{"id":…}}` | `custom_status` recusa **nome e id** |
| `searchTasks` | `GET …/tasks` + filtro **no cliente** | ⚠️ **`?search=` não filtra** (prova abaixo) |
| `getProjectList`/paginação | `page_info.has_next_page` | a listagem pagina; o array de projetos, não |

### A prova de que os filtros são ignorados

Mesmo projeto, 2 tasks, contagens medidas:

```
GET  /tasks                       → 2 tasks
GET  /tasks?search=PAI            → 2
GET  /tasks?search=ZZZINEXISTENTE → 2      ← termo que não existe
GET  /tasks?parent_task=<id>      → 2      ← e inclui a PRÓPRIA task pai
POST tasklist {"milestone_id":…}  → 200, e nasce em milestone None
PATCH task {"owners":[…]}         → 200, e a atribuição não acontece
PATCH task {"owner":{…}}          → 200, idem
POST task {"depth":1}             → 200, e nasce com depth: 0
```

**Seis casos, todos HTTP 200.** "Parâmetro aceito e ignorado em silêncio" é **sistêmico** nesta API, não
um caso — e é a regra que governa o adapter: *verificar no corpo da resposta, nunca no código HTTP.*
O corolário útil: **todo vínculo é objeto aninhado** — `{"milestone":{"id":…}}`,
`{"tasklist":{"id":…}}`, `{"status":{"id":…}}`, `{"owners_and_work":{"owners":[…]}}`.

### Atribuição: `owners_and_work`, objeto, com `zpuid`

```
PATCH …/tasks/{id}   { "owners_and_work": { "owners": [ { "zpuid": "..." } ] } }
```

Achado por eliminação: `owners`/`owner` aceitos e ignorados; `assignees` → `INVALID_PARAMETER_VALUE`;
`owners_and_work` como **array** → `JSON_PARSE_ERROR`, porque ele é objeto (traz também `work_type`,
`total_work`, `unit`, `copy_task_duration`). O identificador é o **`zpuid`**, não o `zuid`.

### Subtask na V3: o modelo tem, a escrita não está exposta

Três rodadas de medição, e nenhuma achou caminho: `parent_task` recusa objeto, string e número (o campo
**existe** — `INVALID_PARAMETER_VALUE`); `depth: 1` é aceito e ignorado; `association_info.parent_task`
não vincula; quatro paths candidatos dão `URL_RULE_NOT_CONFIGURED`. **E no entanto** toda task traz
`association_info.has_subtasks`. Nem a doc (SPA de >10 MB, não fetchável) nem busca de código no GitHub
deram resposta. **A V2 cria** (`parent_task_id`, 201) e sai de linha em 2026-12-31.

### Os cinco títulos de erro, e por que a distinção economiza horas

| `title` | significado medido |
|---|---|
| `URL_RULE_NOT_CONFIGURED` | o **path** não existe |
| `EXTRA_KEY_FOUND_IN_JSON` | o campo **não existe** no recurso (`details[].field_name` diz qual) |
| `INVALID_PARAMETER_VALUE` | o campo **existe**, o valor é inválido |
| `LESS_THAN_MIN_OCCURANCE` | campo obrigatório **ausente** |
| `INVALID_METHOD` | verbo errado |

A diferença entre os dois do meio foi o que revelou que `parent_task` existe na V3 mas nenhum formato
serve — sem ela, a conclusão teria sido "o campo não existe" e a V2 nunca seria testada.

## 🔗 Integração com o Sistema Onion

- **Não é um provider do SDAAL de task manager.** `TASK_MANAGER_PROVIDER` aceita `jira | clickup |
  asana | linear | none` (ver [task-manager-abstraction](../concepts/task-manager-abstraction.md)).
  Operar tasks do Zoho via `/product:task` exigiria um **adapter novo** em
  `.claude/utils/task-manager/adapters/`, caminho de `/meta:create-abstraction` + sinal upstream ao core.
- **Segredos:** `ZOHO_*` no `.env`, carregado com `set -a; source .env; set +a`. Doutrina em
  [secret-handling-agent](../concepts/secret-handling-agent.md). Nunca imprimir o token em log ou chat.
- **Configuração guiada:** `/meta:setup-integration` é o comando canônico para registrar as variáveis.
- **Integrações estudadas:** [GLPI → Zoho: chamado vira tarefa](../patterns/glpi-zoho-ticket-to-task.md) · KB irmã [glpi-api](glpi-api.md).
- **Frescor:** a API mudou de major (V2→V3) em 2025. Reverifique esta KB contra [1] antes de
  decisão (`/meta:kb-freshness`; doutrina [verify-external-for-current](../concepts/verify-external-for-current.md)).

---

## 🔗 Referências

1. Zoho Projects V3 API Documentation: <https://projects.zoho.com/api-docs>
2. Zoho Accounts, Self Client overview: <https://www.zoho.com/accounts/protocol/oauth/self-client/overview.html>
3. Zoho Accounts, Self Client authorization code flow: <https://www.zoho.com/accounts/protocol/oauth/self-client/authorization-code-flow.html>
4. Zoho Accounts, Web apps authorization: <https://www.zoho.com/accounts/protocol/oauth/web-apps/authorization.html>
5. Zoho Accounts, Multi-DC support: <https://www.zoho.com/accounts/protocol/oauth/multi-dc.html>
6. Zoho Developer, OAuth token limits: <https://www.zoho.com/developer/oauth/token-limits.html>
7. Zoho Projects, API legado (restapi): <https://www.zoho.com/projects/help/rest-api/zohoprojectsapi.html>
8. Ascent Business, "Migrate to V3 by 31 Dec 2025": <https://ascentbusiness.co.uk/zoho-projects-api-deadline-migrate-to-v3-by-31-december-2025/>
9. Zoho Projects, Task Automation (Workflow Rules, Webhooks, Macros, Blueprints): <https://www.zoho.com/projects/taskautomation.html>
10. Zoho Projects + Zoho Flow: <https://www.zoho.com/projects/zoho-flow-integrations.html>

---

*Pesquisado e gerado em 2026-09-30 (v1.1 no mesmo dia: tarefas + automação) via `/meta:create-knowledge-base`. Nenhuma chamada real à API foi feita: os exemplos seguem a doc oficial e não foram executados contra um portal.*
