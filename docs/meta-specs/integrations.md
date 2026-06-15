---
title: Meta-spec — Padrões de Integração do Sistema Onion
date: 2026-05-18
version: 1.2.0
level: L0
status: active
gate-keeper: "@metaspec-gate-keeper"
---

# Meta-spec — Padrões de Integração do Sistema Onion

## Propósito

Define os padrões obrigatórios para integrações com sistemas externos (Task Managers, MCPs, APIs). Usa **Task Manager Abstraction** como referência canônica de design de adapter — toda nova integração deve seguir o mesmo padrão.

Aplica-se ao **Sistema Onion**, não ao projeto-alvo onde o Onion é instalado.

Referências relacionadas:

- [agents.md](./agents.md), [commands.md](./commands.md)
- [architecture.md](./architecture.md), [code-standards.md](./code-standards.md)

Referência técnica: [.claude/utils/task-manager/](../../.claude/utils/task-manager/).

---

## 1. Task Manager Abstraction como referência canônica

A Task Manager Abstraction é o padrão **SDAAL** (Specification-Driven AI Abstraction Layer) implementado de referência. Estrutura:

```
.claude/utils/task-manager/
├── factory.md           # Instancia o adapter via TASK_MANAGER_PROVIDER
├── interface.md         # Contrato ITaskManager
├── types.md             # Tipos e DTOs
├── detector.md          # Detecção automática de provider
└── adapters/
    ├── jira.md          # Adapter Jira (REST v3, ADF)
    ├── clickup.md       # Adapter ClickUp (API-first; MCP opcional)
    ├── asana.md         # Adapter Asana (API-first; MCP opcional)
    └── linear.md        # Adapter Linear (API-first; MCP opcional)
```

Toda nova integração (ex: novo Task Manager, novo serviço de comunicação) deve replicar essa estrutura.

### 1.0 Segunda instância de referência: Forge Abstraction

A **Forge Abstraction** (`.claude/utils/forge/`) é a segunda instância concreta do SDAAL, adicionada em 2026-06-13. Abstrai o **host de código remoto** (GitHub, GitLab, Bitbucket) para operações de **PR, review, CI/checks e Release**. Replica a estrutura canônica (factory/interface/types/detector/adapters + Null Object) e comprova que o padrão generaliza além de Task Managers.

Particularidades documentadas no próprio adapter:

- **Escopo restrito a host remoto**: git local (branch/merge/tag/push) **não** passa pelo adapter — é `git` direto orientado pelo motor GitFlow (`gitflow-patterns.md`). A fronteira está em `forge/interface.md`.
- **Transporte default `cli`** (não `api`): a CLI oficial (`gh`/`glab`) embute auth, paginação e rate-limit — é o caminho padronizado para forges, com REST como fallback (`FORGE_TRANSPORT=api`). Divergência **deliberada e documentada** em `forge/factory.md`; coerente com o princípio SDAAL ("padronizar a via preferencial do domínio").

### 1.1 Transporte: API-first, MCP opcional

Cada adapter usa a **REST API** do provider como transporte **padrão e preferencial**. O **MCP é opcional e ativável** via `TASK_MANAGER_TRANSPORT` (`api` | `mcp`; **default `api`**): quando `mcp` e o provider tiver servidor MCP disponível, o adapter usa MCP; caso contrário, cai para API. Isso é coerente com o SDAAL — a *spec* define **o quê** (operações de `ITaskManager`); o adapter define **o como** (API ou MCP). Não há wrappers MCP específicos por provider.

---

## 2. Estrutura obrigatória de adapter

Para cada integração com sistema externo:

```
.claude/utils/<dominio>/
├── factory.md           # Roteamento por variável de ambiente
├── interface.md         # Contrato comum (operações independentes de provider)
├── types.md             # Tipos compartilhados
├── detector.md          # Detecção automática (opcional)
└── adapters/
    └── <provider>.md    # Um arquivo por provider suportado
```

### 2.1 Conteúdo de cada arquivo

**factory.md**:

- Lê variável de ambiente do `.env` para decidir provider
- Valida variáveis obrigatórias do provider escolhido
- Retorna instância do adapter ou erro descritivo
- Lida com `none` ou ausência (fallback gracioso)

**interface.md**:

- Lista operações que **todo provider deve suportar**
- Define inputs e outputs em formato neutro
- Não vaza detalhes de provider

**types.md**:

- DTOs comuns
- Enums
- Tipos compartilhados

**detector.md** (opcional):

- Detecção automática quando variável não é declarada explicitamente
- Heurísticas (existência de outras variáveis, presença de arquivos config)

**adapters/<provider>.md**:

- Implementação concreta para o provider
- Lista variáveis específicas necessárias
- Formatação requerida (ADF, Markdown, HTML, Unicode)
- Tratamento de erros específicos do provider
- Limites e cotas conhecidas

---

## 3. Gestão de `.env` e variáveis de ambiente

### 3.1 Convenção de nomes

- Prefixo do domínio em UPPER_SNAKE_CASE: `TASK_MANAGER_PROVIDER`, `JIRA_API_TOKEN`, `CLICKUP_WORKSPACE_ID`
- Sufixo descritivo do que a variável contém (`_TOKEN`, `_HOST`, `_ID`, `_URL`)
- Booleanos como string: `"true"` / `"false"`

### 3.2 Obrigatórias vs opcionais

Cada adapter deve documentar em sua seção:

| Variável | Tipo | Obrigatoriedade | Default | Descrição |
|---|---|---|---|---|
| `JIRA_HOST` | URL | Obrigatória | — | URL base da instância Jira |
| `JIRA_EMAIL` | email | Obrigatória | — | Email do usuário Jira |
| `JIRA_API_TOKEN` | secret | Obrigatória | — | Token gerado em Atlassian |
| `JIRA_PROJECT_KEY` | string | Opcional | — | Filtro default |
| `JIRA_AUTH_TYPE` | enum | Opcional | `basic` | `basic` ou `bearer` |
| `JIRA_API_VERSION` | enum | Opcional | `3` | `2` (Server/DC) ou `3` (Cloud) |

### 3.3 Fallback gracioso

Quando o usuário invoca um comando que requer integração mas a variável obrigatória está ausente:

1. **Não inventar** valor nem assumir provider alternativo
2. Reportar em pt-BR qual variável falta
3. Sugerir comando para configurar: `/meta:setup-integration`
4. Continuar offline quando possível (ex: `@task-specialist` decompõe localmente sem persistir)

Exemplo de mensagem:

```
Não foi possível conectar ao Jira: variável JIRA_API_TOKEN está vazia.
Para configurar, execute: /meta:setup-integration
Para operar offline, defina TASK_MANAGER_PROVIDER=none no .env.
```

### 3.4 `.env.example` versionado

- `.env.example` no root deve conter **todas** as variáveis documentadas com valor placeholder
- Comentários explicando obrigatoriedade e formato
- `.env` no `.gitignore` sempre

---

## 4. MCPs (Model Context Protocol) — transporte opcional

> MCP é um **transporte opcional** dos adapters, não o padrão. O default é API (Seção 1.1). Use MCP apenas quando `TASK_MANAGER_TRANSPORT=mcp` e o provider tiver servidor MCP.

### 4.1 MCPs declarados em agentes

Quando um agente depende de MCP, declarar nas `tools`:

```yaml
tools:
  - Read
  - mcp__clickup__create_task
  - mcp__clickup__update_task
```

### 4.2 MCPs comuns no framework atual

| MCP | Provedor | Usado por |
|---|---|---|
| `ClickUp_*` | ClickUp MCP | `@clickup-specialist`, comandos `/product/*` quando provider é ClickUp |
| `claude_ai_Asana__*` | Anthropic-managed | Provider Asana |
| `claude_ai_Linear__*` | Anthropic-managed | Provider Linear |
| `claude_ai_Atlassian__*` | Anthropic-managed | Provider Jira |
| `claude_ai_Slack__*` | Anthropic-managed | Notificações (opcional) |
| `claude_ai_Notion__*` | Anthropic-managed | Documentação externa (opcional) |

> **Forge não usa MCP.** O adapter `.claude/utils/forge/` usa transporte `cli` (CLI oficial `gh`/`glab`, default) ou `api` (REST/GraphQL, fallback). Não há servidor MCP envolvido — auth é gerenciada pela própria CLI ou por `GH_TOKEN`/`GITHUB_TOKEN`.

### 4.3 Configuração

- **MCP servers stdio** (ex.: ClickUp) são declarados em `.mcp.json` na raiz do
  projeto. O framework versiona um template **`.mcp.json.example`** — o
  projeto-alvo copia para `.mcp.json` e ajusta ao provider ativo.
- **NUNCA** colar tokens no `.mcp.json`: usar interpolação `${VAR}` resolvida do
  `.env`/ambiente.
- MCPs **Anthropic-managed** (Asana, Linear, Atlassian/Jira) entram como
  conectores hospedados (claude.ai) e normalmente **não** precisam de entrada
  stdio no `.mcp.json`.
- Aprovação/habilitação de MCP servers via `enableAllProjectMcpServers` /
  `enabledMcpjsonServers` em `.claude/settings.json`.
- `/meta:setup-integration` guia a configuração de `.env` + `.mcp.json` quando
  aplicável.

---

## 5. Formatação por provider

Cada provider tem formato preferido para descrições, comentários e payloads. **Adapter é responsável por traduzir** dados internos para formato do provider.

| Provider | Descrições de task | Comments | Estrutura |
|---|---|---|---|
| Jira Cloud (v3) | ADF (Atlassian Document Format) — JSON estruturado | ADF | Bulk via `/issue/bulk` |
| Jira Server/DC (v2) | Wiki markup ou plain text (string) | Wiki markup | Search via `/search` (paginated) |
| ClickUp | Markdown nativo em `markdown_description` | Unicode visual em `commentText` (`━━━`, `∟`, `▶`, `◆`, `✅`) | API REST (default) · MCP opcional |
| Asana | HTML notes (subset) ou plain text | HTML | API REST (default) · MCP opcional |
| Linear | Markdown nativo (suporte rico) | Markdown | API GraphQL (default) · MCP opcional |

**Forge** (domínio de host remoto, não Task Manager):

| Provider | Corpo de PR / Release | Comentários de review | Estrutura |
|---|---|---|---|
| GitHub | Markdown nativo | Markdown nativo | CLI `gh` (default) · REST `gh api`/curl (fallback) |
| GitLab / Bitbucket | Markdown nativo | Markdown nativo | 🔜 costura (não implementado) |

### 5.1 Templates por provider

Templates de formatação para cada provider devem viver em:

```
.claude/utils/<dominio>/adapters/<provider>.md
.claude/utils/<dominio>/templates/<provider>-<tipo>.md   # quando aplicável
```

Para ClickUp especificamente, existe documento de referência: `.claude/utils/clickup-formatting.md`.

---

## 6. Bulk operations e performance

### 6.1 Bulk-first

Quando operar em lote (>5 itens), preferir operação bulk do provider:

- Jira: `POST /rest/api/3/issue/bulk` (até 50/req)
- ClickUp: endpoints bulk quando disponíveis
- Evitar loops N+1 em criação/update

### 6.2 Field selection

Ao buscar itens, declarar apenas campos necessários para reduzir payload:

- Jira: `fields=summary,status,assignee`
- Linear: query GraphQL com seleção explícita

### 6.3 Paginação

- Implementar paginação consistente
- Jira Cloud v3: usar `nextPageToken` (o antigo `/search` foi removido em maio/2025)
- ClickUp: usar `page` parameter
- Não iterar todas as páginas quando não necessário

---

## 7. Tratamento de erros

### 7.1 Categorias

| Erro | Resposta esperada do adapter |
|---|---|
| Variável de ambiente ausente | Fallback gracioso (Seção 3.3) |
| Token inválido / expirado | Mensagem clara em pt-BR + sugestão de regeneração |
| Rate limit | Retry com backoff exponencial, máximo 3 tentativas |
| Recurso não encontrado | Reportar ID + provider + sugestão de verificação |
| Erro de validação do provider | Reportar mensagem original do provider + tradução pt-BR |
| Erro de rede transitório | Retry com backoff |
| Erro inesperado | Logar e reportar, não silenciar |

### 7.2 Não silenciar

- Adapter nunca deve "engolir" erro sem reportar
- Comandos chamadores devem propagar erro ao usuário com contexto

---

## 8. Adicionar novo adapter — checklist

Ao adicionar suporte a novo provider:

1. Criar `.claude/utils/<dominio>/adapters/<provider>.md` seguindo estrutura de Seção 2.1
2. Atualizar `factory.md` para reconhecer o novo provider
3. Atualizar `detector.md` se houver detecção automática
4. Documentar variáveis de ambiente em `.env.example`
5. Atualizar CLAUDE.md com tabela "Provider → Variáveis → Agente → Adapter"
6. Criar especialista em `.claude/agents/development/<provider>-specialist.md` (opcional, mas recomendado)
7. Adicionar a esta meta-spec (Seções 4.2 e 5)
8. Validar com `@metaspec-gate-keeper`

---

## 9. Proibições explícitas

- **Proibido** integração que requer credencial fora de `.env`
- **Proibido** invocar API externa diretamente em comando sem passar pelo adapter
- **Proibido** adapter que vaza tipos específicos do provider para o nível de interface
- **Proibido** assumir provider sem ler `.env` primeiro

---

## 10. Versionamento e mudanças

Mudanças nesta spec exigem:

1. PR específico para `docs/meta-specs/integrations.md`
2. Atualização do campo `version`
3. Migração de adapters existentes quando aplicável
4. Validação por `@metaspec-gate-keeper`
