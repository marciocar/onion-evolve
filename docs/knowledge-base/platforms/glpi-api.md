---
versao: 1.1.0
data: 2026-09-30
categoria: platforms
applies_to: "GLPI 11.0.x (API V1 + API V2) · GLPI 10.0.x (API V1 apenas)"
verified_at: 2026-09-30
verified_against: "absorvida de um adotante hub em 2026-09-30, com scrub. Linha 11.x conferida na fonte primária no dia (api.github.com/repos/glpi-project/glpi/releases/latest devolveu 11.0.10, publicada em 2026-09-30T09:25:10Z) — a busca web dizia 11.0.8, três releases atrás. Nenhuma instância real foi chamada."
---

# GLPI API — Knowledge Base


> **Categoria**: Platforms
> Referência técnica das APIs do **GLPI** (ITSM / service desk / gestão de ativos, open source):
> a **API legada V1** (`apirest.php`, App-Token + user_token + Session-Token) e a **API V2
> "high-level"** do GLPI 11 (`/api.php/v2`, OAuth2 + Bearer). Tudo com fonte na documentação
> oficial; o que extrapola a fonte está `[INFERÊNCIA]`.

---

## 📋 Metadata

| Campo | Valor |
|-------|-------|
| **Versão** | 1.1.0 |
| **Data de Criação** | 2026-09-30 |
| **Última Atualização** | 2026-09-30 (v1.1: webhooks nativos + acompanhamentos) |
| **Categoria** | platforms |
| **Versões cobertas** | GLPI 10.0.x (só API V1) · GLPI 11.x (V1 legada + V2 OAuth2) |
| **Fontes Principais** | [1] <https://github.com/glpi-project/glpi/blob/10.0/bugfixes/apirest.md> (V1, oficial) · [2] <https://help.glpi-project.org/documentation/modules/configuration/general/api/restful-api-v2> · [3] <https://help.glpi-project.org/documentation/modules/configuration/oauth-clients> · [4] <https://help.glpi-project.org/tutorials/readme-1/api-v2> · [5] <https://help.glpi-project.org/documentation/modules/configuration/general/api/api.md> · [6] <https://www.glpi-project.org/en/blog/> · [7] <https://forum.glpi-project.org/viewtopic.php?id=293338> · [8] <https://help.glpi-project.org/documentation/modules/configuration/webhook.md> · [9] <https://github.com/ericferon/glpi-webhook> · [10] <https://forum.glpi-project.org/viewtopic.php?id=294543> · [11] <https://github.com/glpi-project/glpi/issues/20762> |

---

## 📋 Visão Geral

O **GLPI** é uma plataforma open source (PHP) de **ITSM**: chamados (tickets, problemas, mudanças),
inventário e gestão de ativos (via GLPI Agent), contratos, fornecedores e base de conhecimento. Roda
self-hosted ou como SaaS (GLPI Network Cloud).

### As duas APIs — escolha primeiro qual

| | **V1 — legada** | **V2 — high-level** |
|---|---|---|
| Disponível em | GLPI 9.1+ / 10.x / 11.x | **GLPI 11+** (11.0.0 em 2025-10-01 [6]) |
| Endpoint | `/apirest.php/...` (ou `/api/` com URL rewrite) [1] | `/api.php/v2/...` [2] |
| Autenticação | `initSession` → **Session-Token**; login por `user_token` ou Basic; `App-Token` opcional [1] | **OAuth2** → `Authorization: Bearer <JWT>` [2] |
| Modelo | Espelha as tabelas/itemtypes internos (`/Ticket/`, `/Computer/`) | Recursos agrupados e estáveis (`/Assistance/Ticket`), versionados |
| Filtro | `/search/:itemtype` com `criteria[]` + ids de *search options* [1] | **RSQL** no parâmetro `filter` (`==`, `!=`, `=in=`, `=like=`, `=isnull=`) [2] |
| Paginação | `range=0-49` + header `Content-Range` [1] | `start` + `limit` + header `Content-Range` [2] |
| Doc interativa | — | **Swagger em `/api.php/doc`** (e `.json`) na própria instância [2] |
| Extra | — | **GraphQL** read-only em `/api.php/GraphQL` (escopo `graphql`) [2] |
| Status | "Old version of the API", ainda disponível no 11 [2][5] | Caminho recomendado para integrações novas |

> **Regra prática** `[INFERÊNCIA]`: instância em **GLPI 10** → só existe V1. Instância em **GLPI 11** →
> use **V2**; recorra à V1 só para o que a V2 ainda não expõe (confira no Swagger da instância).

---

## 🎯 Casos de Uso

| Use quando | Não use quando |
|---|---|
| Abrir/atualizar chamados a partir de outro sistema (monitoramento, chatbot, portal) | Inventário de máquinas: use o **GLPI Agent** nativo (escopo `inventory`), não CRUD manual |
| Sincronizar ativos/usuários com ERP, CMDB ou BI | Relatórios pesados recorrentes direto na API: prefira réplica de banco/BI `[INFERÊNCIA]` |
| Automação de service desk (triagem, SLA, notificações externas) | Reagir a eventos por polling: o GLPI 11 tem **Webhooks nativos** [8] (ver [Webhooks e Acompanhamentos](#-webhooks-e-acompanhamentos)) |
| Integração máquina-a-máquina com usuário técnico dedicado | Sem conta de serviço: a V2 exige **usuário real** para o escopo `api` [2] |

---

## ⚡ Quick Start — API V2 (GLPI 11, recomendado)

### 1. Cadastrar o OAuth Client

**Configuração → OAuth Clients → Adicionar** [3]:

| Campo | Valor |
|---|---|
| Nome / Comentário | ex.: `integracao-onion` |
| Grants | **Password** (script/back-end) ou **Authorization Code** (app com usuário) [2][3] |
| Scopes | `api` (+ `user`, `email`, `status`, `graphql` se precisar) [2][3] |
| Redirect URIs | só para Authorization Code [3] |
| Restrição de IP | whitelist dos IPs do integrador [3] |

Ao salvar, copie `client_id` e **`client_secret` — exibido uma única vez** [3].

### 2. Obter o token (password grant)

```bash
curl -s -X POST "https://$GLPI_HOST/api.php/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password" \
  -d "client_id=$GLPI_CLIENT_ID" \
  -d "client_secret=$GLPI_CLIENT_SECRET" \
  -d "username=$GLPI_USERNAME" \
  -d "password=$GLPI_PASSWORD" \
  -d "scope=api"
```

Resposta [4]: `{"token_type":"Bearer","expires_in":3600,"access_token":"<JWT>","refresh_token":"..."}`

### 3. Chamar a API

```bash
# Ler um chamado
curl -s "https://$GLPI_HOST/api.php/v2/Assistance/Ticket/123" \
  -H "Authorization: Bearer $GLPI_ACCESS_TOKEN" \
  -H "Accept-Language: pt_BR"

# Criar um chamado (campos básicos; o schema completo está no Swagger /api.php/doc)
curl -s -X POST "https://$GLPI_HOST/api.php/v2/Assistance/Ticket" \
  -H "Authorization: Bearer $GLPI_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"Impressora do CD fora do ar","content":"Descrição do problema","urgency":3,"impact":3}'
```

Headers de contexto opcionais [2]: `GLPI-Entity` (entidade ativa), `GLPI-Entity-Recursive`,
`GLPI-Profile` (perfil ativo), `Accept-Language`.

### Variáveis de ambiente sugeridas `[INFERÊNCIA]`

```bash
# .env (NUNCA versionar)
GLPI_HOST=glpi.exemplo.com.br
GLPI_API_VERSION=v2                 # v2 (GLPI 11) | v1 (legada)
# V2 — OAuth2
GLPI_CLIENT_ID=xxxx
GLPI_CLIENT_SECRET=xxxx             # mostrado 1x na criação
GLPI_USERNAME=svc-integracao        # usuário técnico dedicado, perfil mínimo
GLPI_PASSWORD=xxxx
# V1 — legada
GLPI_APP_TOKEN=xxxx                 # do API client (Configuração → Geral → API)
GLPI_USER_TOKEN=xxxx                # "Chave de acesso remoto" nas preferências do usuário
```

---

## ⚡ Quick Start — API V1 (legada, GLPI 10 e 11)

### 1. Habilitar e configurar

- **Configuração → Geral → aba API** [1][5]: habilitar a API REST; habilitar login por credenciais
  e/ou por token externo `[INFERÊNCIA — rótulos da UI]`.
- **API clients** na mesma aba: cada integração ganha um cliente com **faixa IPv4/IPv6** permitida e
  **App-Token** próprio (cada cliente tem histórico separado) [1][5].
- **Token do usuário**: em **Preferências do usuário → "Chave de acesso remoto"** (`user_token`) [1][5].

### 2. Abrir sessão, operar, fechar

```bash
API="https://$GLPI_HOST/apirest.php"

# initSession com user_token (alternativa: Authorization: Basic base64(login:senha))
SESSION=$(curl -s "$API/initSession" \
  -H "Content-Type: application/json" \
  -H "Authorization: user_token $GLPI_USER_TOKEN" \
  -H "App-Token: $GLPI_APP_TOKEN" | jq -r .session_token)

# Ler / listar / criar
curl -s "$API/Ticket/123?expand_dropdowns=true" -H "Session-Token: $SESSION" -H "App-Token: $GLPI_APP_TOKEN"
curl -s "$API/Ticket/?range=0-49"               -H "Session-Token: $SESSION" -H "App-Token: $GLPI_APP_TOKEN"
curl -s -X POST "$API/Ticket/" -H "Content-Type: application/json" \
  -H "Session-Token: $SESSION" -H "App-Token: $GLPI_APP_TOKEN" \
  -d '{"input":{"name":"Assunto","content":"Descrição"}}'

# Sempre encerrar
curl -s "$API/killSession" -H "Session-Token: $SESSION" -H "App-Token: $GLPI_APP_TOKEN"
```

### Endpoints V1 essenciais [1]

| Método | Endpoint | Uso |
|---|---|---|
| GET | `/initSession` · `/killSession` | Abre / encerra a sessão |
| GET | `/getMyProfiles` · `/changeActiveProfile` | Perfis do usuário / troca o ativo |
| GET | `/getMyEntities` · `/changeActiveEntities` | Entidades / troca a ativa |
| GET | `/getFullSession` | Dump da sessão (debug de permissões) |
| GET | `/:itemtype/:id` · `/:itemtype/` | Item / lista paginada |
| GET | `/:itemtype/:id/:sub_itemtype` | Sub-itens (ex.: `/Ticket/1/TicketFollowup`) |
| POST | `/:itemtype/` | Cria (`{"input": {...}}` ou lista de inputs) |
| PUT/PATCH | `/:itemtype/:id` | Atualiza |
| DELETE | `/:itemtype/:id` | Apaga (`force_purge=true` para purgar) |
| GET | `/search/:itemtype/` · `/listSearchOptions/:itemtype/` | Busca por critérios / ids dos campos buscáveis |

**Busca** [1]: cada critério é um trio de parâmetros de query, unidos por `&`:
`criteria[0][field]` (id da search option), `criteria[0][searchtype]` (operador) e `criteria[0][value]`.
Operadores: `contains`, `equals`, `notequals`, `lessthan`, `morethan`, `under`, `notunder`. Os `field` são
**números**, descobertos via `listSearchOptions`.

**Parâmetros úteis** [1]: `expand_dropdowns=true` (troca ids por nomes), `get_hateoas`,
`session_write=true` (sessões são **read-only por padrão** para permitir chamadas paralelas).

---

## 🔐 Autenticação — Referência Comparada

| Aspecto | V1 | V2 |
|---|---|---|
| Credencial da app | `App-Token` (opcional, recomendado) + filtro de IP [1] | `client_id` + `client_secret` + filtro de IP [3] |
| Credencial do usuário | `user_token` ou login/senha (Basic) [1] | username/password (password grant) ou consentimento (auth code) [2] |
| Token de acesso | `Session-Token` (sessão PHP do GLPI) [1] | JWT Bearer, **1 h** padrão [2][4] |
| Ajuste de vida útil | segue a sessão do servidor `[INFERÊNCIA]` | `GLPI_OAUTH_ACCESS_TOKEN_EXPIRES` [2] |
| Refresh | não há: nova `initSession` | `refresh_token` (retornado no password grant [4]; doc de config cita só auth code [2]) |
| Máquina-a-máquina pura | `user_token` de usuário técnico | **client_credentials só no escopo `inventory`**; escopo `api` exige usuário real [2] |

### Escopos V2 [2][3]

| Escopo | Dá acesso a |
|---|---|
| `api` | Toda a API REST não coberta por outros escopos |
| `inventory` | Envio de inventário (GLPI Agent) |
| `user` / `email` | Dados / e-mail do usuário logado |
| `status` | Endpoints de status |
| `graphql` | Endpoint GraphQL |

### Erros comuns (V1) [1]

| Código | Causa / ação |
|---|---|
| `ERROR_APP_TOKEN_PARAMETERS_MISSING` | App-Token exigido pelo API client e não enviado |
| `ERROR_SESSION_TOKEN_INVALID` / `..._MISSING` | Sessão expirada ou ausente: refaça `initSession` |
| `ERROR_RIGHT_MISSING` | Perfil/entidade ativos sem direito: confira `getFullSession` |
| `ERROR_ITEM_NOT_FOUND` | Id inexistente ou fora da entidade ativa |

---

## 🔔 Webhooks e Acompanhamentos

### Webhooks nativos (GLPI 11) [8]

**Administração → Configuração → Webhooks**. No GLPI 10 não existe nativo: há o plugin comunitário
`glpi-webhook`, descontinuado porque a função entrou no core do 11 [9].

| Grupo | Campos |
|---|---|
| Básico | Nome, ativo, categoria, **entidade** (com filhas), **itemtype**, **evento** (criação, atualização, exclusão), nº de tentativas |
| Destino | URL (HTTPS, aceita tags), método `POST`/`GET`/`PUT`/`PATCH`, salvar corpo da resposta, registrar no histórico do item |
| Segurança | **Secret key** (assinatura SHA256) · **expiration delay** (anti-replay) · desafio CRA · **OAuth** (client id/secret) · headers customizados |
| Payload | Texto, HTML, XML ou JSON. Default gerado automaticamente; editor com variáveis `{{item.*}}` |
| Filtros | Motor de busca padrão do GLPI, com Preview |
| Teste | Aba **Preview**: escolhe itens e vê os dados de API e o payload renderizado |

**Fila**: os envios ficam em `glpi_queuedwebhooks`, processados pela ação automática **`queuedwebhook`**
(envio + retry) e limpos por **`queuedwebhookclean`**. Há botão "Forçar envio" [8].
⚠️ **Sem o cron do GLPI rodando, nenhum webhook sai.** Há relatos de "webhook não envia" no 11.0.5 [10].

### Acompanhamentos (followups) via API

| API | Como |
|---|---|
| V2 | Timeline do chamado em `/api.php/v2/Assistance/Ticket/{id}/Timeline` (itens tipo *Followup*, *Solution*, *Document*) [11]. Confira o sub-recurso de criação no Swagger `/api.php/doc` |
| V1 | `POST /apirest.php/ITILFollowup/` com `{"input":{"itemtype":"Ticket","items_id":<id>,"content":"..."}}` `[INFERÊNCIA — padrão dos fóruns]` |

> Fluxo completo usando isto: [GLPI → Zoho: chamado vira tarefa](../patterns/glpi-zoho-ticket-to-task.md).

---

## 💡 Best Practices

1. **GLPI 11 → V2**: modelo estável, OAuth2, Swagger na instância [2]. A V1 é "old version" [5].
2. **Usuário técnico dedicado** com **perfil e entidades mínimos**. A API respeita os direitos do
   perfil ativo; o problema nº 1 de "não acho o item" é entidade/perfil errados [1][2].
3. **Restrição de IP** no API client (V1) ou OAuth client (V2) [1][3].
4. **V1: sempre `killSession`** ao terminar e **reuse a sessão** num lote, em vez de abrir uma
   sessão por chamada `[INFERÊNCIA]`.
5. **V1: `session_write=true` só quando precisar gravar na sessão** (trocar perfil/entidade). O
   padrão read-only permite paralelismo [1].
6. **Descubra campos antes de filtrar**: `listSearchOptions` (V1) ou `/api.php/doc` (V2) [1][2].
7. **Cache do Bearer** até perto de `expires_in` e renove com `refresh_token` [2][4].
8. **Fixe a versão da V2** no path quando o contrato importar: aceita major, major.minor ou
   major.minor.patch; sem fixar, vale o último minor/patch [2].

---

## ⚠️ Limitações e Gotchas

| Gotcha | Detalhe |
|---|---|
| `client_credentials` não serve para tickets | Só o escopo `inventory`. Para `api`, use password ou auth code [2][7] |
| `client_secret` aparece 1 vez | Perdeu: regenere/recrie o client [3] |
| GET com body | V1 exige **body vazio** em GET; parâmetros vão na URL [1] |
| `field` numérico na busca V1 | `criteria[][field]` usa o **id** da search option, que muda por itemtype e plugin [1] |
| Paginação V1 | Default `0-49`; o total vem em `Content-Range: offset-limit/total` e o máximo em `Accept-Range` [1] |
| Entidade ativa | Itens de outras entidades "somem" (404/vazio) sem `GLPI-Entity-Recursive`/`changeActiveEntities` [1][2] |
| URL com rewrite | `/api/` só funciona se o servidor web tiver a regra; `apirest.php` sempre existe [1] |
| Formato de data V2 | Exemplos de payload usam `"YYYY-MM-DD HH:MM:SS"`, não ISO-8601 com `T`/`Z` [4] |
| Ciclo de vida | GLPI 10.0 encerra bugfixes com a chegada do 12.0 (10.0.28 é a última) [6] |

---

## 🔗 Integração com o Sistema Onion

- **Não é task manager do SDAAL.** `TASK_MANAGER_PROVIDER` aceita `jira | clickup | asana | linear |
  none` ([task-manager-abstraction](../concepts/task-manager-abstraction.md)). O GLPI é **ITSM**
  (chamados/ativos), não backlog de produto. Um adapter faria sentido para *service desk*, não para
  `/product:task`. Caminho: `/meta:create-abstraction` + sinal upstream ao core.
- **Segredos** `GLPI_*` no `.env` (`set -a; source .env; set +a`). Doutrina:
  [secret-handling-agent](../concepts/secret-handling-agent.md). Nunca ecoar token ou senha em log/chat.
- **Configuração guiada**: `/meta:setup-integration`.
- **Frescor**: a V2 é nova (GLPI 11, 2025) e versionada em minor. Confira contra o Swagger da
  instância antes de decisão (`/meta:kb-freshness`;
  [verify-external-for-current](../concepts/verify-external-for-current.md)).
- **No seu projeto**: se o GLPI entrar como ferramenta de TI, registre no
  `docs/technical-context/` (versão da instância, V1/V2, entidades) e **não** trafegue dado de
  pessoal sensível em chamados (a regra de proteção de dados do seu projeto).
- KB irmã (mesma família, outra plataforma): [zoho-projects-api](zoho-projects-api.md).
- **Integrações estudadas:** [GLPI → Zoho: chamado vira tarefa](../patterns/glpi-zoho-ticket-to-task.md).

---

## 🔗 Referências

1. GLPI REST API V1 (apirest.md, oficial): <https://github.com/glpi-project/glpi/blob/10.0/bugfixes/apirest.md>
2. GLPI Docs, RESTful API (V2): <https://help.glpi-project.org/documentation/modules/configuration/general/api/restful-api-v2>
3. GLPI Docs, OAuth Clients: <https://help.glpi-project.org/documentation/modules/configuration/oauth-clients>
4. GLPI Tutorials, API V2: <https://help.glpi-project.org/tutorials/readme-1/api-v2>
5. GLPI Docs, API (V1, "old version"): <https://help.glpi-project.org/documentation/modules/configuration/general/api/api.md>
6. GLPI Project, blog de releases: <https://www.glpi-project.org/en/blog/> · <https://www.glpi-project.org/en/glpi-new-versions-11-0-4-and-10-0-22/>
7. Fórum GLPI, "High-level API, GLPI v11": <https://forum.glpi-project.org/viewtopic.php?id=293338>
8. GLPI Docs, Webhook: <https://help.glpi-project.org/documentation/modules/configuration/webhook.md>
9. Plugin comunitário glpi-webhook (GLPI 10): <https://github.com/ericferon/glpi-webhook>
10. Fórum GLPI, "Webhooks not sending from GLPI 11.0.5": <https://forum.glpi-project.org/viewtopic.php?id=294543>
11. GLPI issue #20762, HLAPI timeline: <https://github.com/glpi-project/glpi/issues/20762>

---

*Pesquisado e gerado em 2026-09-30 (v1.1 no mesmo dia: webhooks + acompanhamentos) via `/meta:create-knowledge-base`. Nenhuma chamada real foi feita: os exemplos seguem a doc oficial e não foram executados contra uma instância.*
