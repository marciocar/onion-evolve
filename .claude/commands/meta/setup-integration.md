---
name: setup-integration
description: |
  Configura integrações do Sistema Onion (Task Managers, Gamma, etc).
  Guia o usuário na configuração segura de variáveis de ambiente para MCPs e APIs.
allowed-tools: Read Bash(test -f *) Bash(grep *) Bash(git ls-files*) Bash(bash .claude/utils/task-manager/env-check.sh *)
parameters:
  - name: integration
    description: Nome da integração (task-manager, clickup, asana, linear, zoho, gamma, postgres)
    required: false
category: meta
tags:
  - meta
  - setup
  - integrations
  - task-manager
version: "3.0.0"
updated: "2025-12-02"
related_commands:
  - /product/task
  - /engineer/start
related_agents:
  - clickup-specialist
---

# ⚙️ Configuração de Integrações

Você é um assistente de configuração do Sistema Onion. Sua missão é guiar o usuário na configuração segura de integrações externas, especialmente **Task Managers** (ClickUp, Asana, Linear).

## 🎯 Objetivo

Configurar variáveis de ambiente necessárias para integrações do Sistema Onion, com foco especial em **Task Manager Abstraction** que permite usar múltiplos gerenciadores de tarefas.

## ⚡ Fluxo de Execução

### Passo 1: Identificar Integração

SE `{{integration}}` foi fornecido:
- Use diretamente
SENÃO:
- Pergunte qual integração configurar:
  - **task-manager** - Configurar gerenciador de tarefas (ClickUp, Asana, Linear, Zoho Projects) - **RECOMENDADO PRIMEIRO**
  - **clickup** - ClickUp (API-first; MCP opcional) para gestão de tarefas
  - **asana** - Asana (API-first; MCP opcional) para gestão de tarefas
  - **linear** - Linear (API-first) para gestão de tarefas
  - **zoho** - Zoho Projects (API V3; OAuth Self client)
  - **gamma** - Gamma.App API para apresentações
  - **postgres** - PostgreSQL para banco de dados

### Passo 2: Verificar Estado Atual

**CRÍTICO:** o `.env` só é olhado pelo helper, que devolve **nomes** de chave e o provider — nunca valores:

```bash
bash .claude/utils/task-manager/env-check.sh --provider          # provider ativo (não é segredo)
bash .claude/utils/task-manager/env-check.sh --check <provider>  # presença, por NOME, das chaves obrigatórias
```

**⚠️ REGRA DE SEGURANÇA:**
- **NUNCA** ler o `.env` com `Read`, `cat` ou `grep` que mostre valores. `Read` devolve o arquivo inteiro ao
  modelo: os segredos entram no contexto e no transcript. Até 2026-10-05 este passo afirmava o contrário, e um
  hub mediu o vazamento ao configurar o Zoho.
- **NUNCA** exibir tokens/senhas no output

### Passo 3: Guiar Configuração por Integração

#### 🎯 Task Manager (Recomendado - Configuração Principal)

**Este é o passo mais importante!** O Sistema Onion usa **Task Manager Abstraction** que suporta múltiplos provedores.

**1. Escolher Provedor:**
```env
# ═══════════════════════════════════════
# GERENCIADOR DE TAREFAS (escolha um)
# ═══════════════════════════════════════
TASK_MANAGER_PROVIDER=clickup  # clickup | asana | jira | linear | zoho | none
```

**2. Configurar ClickUp (se escolhido):**
```env
# ClickUp (API-first; MCP opcional)
CLICKUP_API_TOKEN=pk_xxxxxxx_xxxxxxxxxxxxxxx
CLICKUP_WORKSPACE_ID=your_workspace_id  # Opcional, detectado automaticamente
CLICKUP_DEFAULT_LIST_ID=your_list_id  # Opcional, lista padrão
```

**Como obter:**
- **API Token**: Settings > Apps > API Token no ClickUp
- **Workspace ID**: URL do workspace `https://app.clickup.com/XXXXXXXX/home` → `XXXXXXXX`
- **List ID**: URL da lista `https://app.clickup.com/XXXXXXXX/v/li/YYYYYYYY` → `YYYYYYYY`

**3. Configurar Asana (alternativa):**
```env
# Asana (API-first; MCP opcional)
ASANA_ACCESS_TOKEN=1/xxxxx_xxxxxxxxxxxxxxx
ASANA_DEFAULT_WORKSPACE=1234567890  # Opcional
ASANA_DEFAULT_PROJECT_ID=0987654321  # Opcional
```

**Como obter:**
- **Access Token**: [Asana Developer Console](https://app.asana.com/0/my-apps)
- **Workspace ID**: URL do workspace ou via API
- **Project ID**: URL do projeto ou via API

**4. Configurar Linear (alternativa):**
```env
# Linear API
LINEAR_API_KEY=lin_api_xxxxxxxxxxxxxxx
LINEAR_TEAM_ID=abc123  # Opcional
```

**Como obter:**
- **API Key**: Settings > API no Linear
- **Team ID**: URL do time ou via API

**5. Configurar Zoho Projects (alternativa):**
```env
# Zoho Projects (API V3 — NÃO há MCP nativo da Zoho para Projects)
ZOHO_CLIENT_ID=1000.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
ZOHO_CLIENT_SECRET=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
ZOHO_PORTAL_ID=xxxxxxxxx           # o id do PORTAL (serve na V3 e na V2)
ZOHO_ACCOUNTS_HOST=https://accounts.zoho.com   # opcional: troque por .eu / .in / .com.au
```

**Como obter (o caminho que dispensa grant code):**
- Acesse `api-console.zoho.com` → **GET STARTED** → **Self client** → `CREATE NOW` → `CREATE` → `OK`
- Copie **Client ID** (começa com `1000.`) e **Client Secret** na aba *Client Secret*
- **Não gere grant code**: o fluxo `client_credentials` não precisa dele e não devolve `refresh_token`
- `portal_id`: `GET https://projects.zoho.com/api/v3/portals` com o token → `[{"id": …}]`. Ele serve nas
  **duas** versões da API; o `login_id` que a V2 devolve no topo do envelope é o **usuário** e na URL dá
  `404 6504 Domain Not Available` (medido 2026-09-30 — a 1ª redação dizia o contrário)
- ⚠️ **O datacenter importa**: token de `.com` não vale em `.eu`/`.in`/`.com.au`

**5.1. Modo Offline (sem gerenciador):**
```env
TASK_MANAGER_PROVIDER=none
# Sistema funcionará em modo local sem sincronização
```

#### Gamma.App
1. Acesse: gamma.app/settings/api
2. Gere uma API Key
3. Adicione ao `.env`:
```env
# Gamma.App API
GAMMA_API_KEY=gm_xxxxxxxxxxxxxxxx
```

#### PostgreSQL
1. Configure conexão local ou cloud
2. Adicione ao `.env`:
```env
# PostgreSQL
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_DB=mydb
POSTGRES_USER=myuser
POSTGRES_PASSWORD=change_me_in_production  # Use senhas seguras!
```

### Passo 4: Criar/Atualizar .env

**SE `.env` não existir:** `cp .env.example .env` (o exemplo nasce com `TASK_MANAGER_PROVIDER=none`).

**A escolha do provider é a ÚNICA chave que o setup escreve** — e escreve com o valor escolhido, avisando se havia outro:
```bash
bash .claude/utils/task-manager/env-check.sh --set-provider <jira|clickup|asana|linear|zoho|none>
```
As credenciais o **usuário** cola no `.env` (nunca passam pelo chat). Para as demais chaves:
- **NUNCA** sobrescrever valores existentes
- **SEMPRE** adicionar novas variáveis ao final

> Até 2026-10-05 o `.env.example` vinha com `jira` e este passo proibia sobrescrever: quem escolhia outro
> provider terminava com `jira` ativo e as variáveis novas sem efeito (sinal de campo, dogfood do Zoho).

### Passo 5: Validar Configuração

Após o usuário adicionar as credenciais:

**Para Task Manager** (só-leitura; nada é escrito no provider; imprime só o resultado, nunca a credencial):
```bash
bash .claude/utils/task-manager/env-check.sh --check    # todas as chaves obrigatórias presentes?
bash .claude/utils/task-manager/env-check.sh --test     # a credencial vale? (Zoho: confere também que o PORTAL é visto por ela)
```
Depois, carregue na sessão: `set -a; source .env; set +a` (o hook avisa quando o `.env` declara um provider que o
ambiente da sessão não tem).

**Para outras integrações:**
```bash
# Teste de conexão específico da integração
# Depende da integração escolhida
```

### Passo 6: Atualizar .gitignore

**CRÍTICO:** Verificar se `.env` está protegido:

```bash
# Verificar se .env está no .gitignore
if ! grep -q "^\.env$" .gitignore 2>/dev/null; then
  echo ".env" >> .gitignore
  echo "✅ .env adicionado ao .gitignore"
else
  echo "✅ .env já está protegido no .gitignore"
fi

# Verificar se há .env commitado no Git
if git ls-files --error-unmatch .env >/dev/null 2>&1; then
  echo "⚠️ ATENÇÃO: .env está sendo rastreado pelo Git!"
  echo "💡 Execute: git rm --cached .env"
fi
```

## 🔒 Regras de Segurança

1. **NUNCA** exiba tokens/senhas completos no output
2. **SEMPRE** olhe o `.env` pelo helper `env-check.sh` — **nunca** com `Read`, `cat` ou `grep` (os três expõem valores)
3. **SEMPRE** verifique `.gitignore` antes de concluir
4. **ALERTE** se detectar credenciais em arquivos não protegidos
5. **SUGIRA** uso de vault/secrets manager para produção
6. **VALIDE** se `.env` está sendo rastreado pelo Git e alerte

## 📤 Output Final

Apresente um resumo formatado:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Configuração de [INTEGRAÇÃO] Concluída
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 Status:
∟ .env: ✅ Configurado
∟ .gitignore: ✅ Protegido
∟ [INTEGRAÇÃO]: ✅ Pronta para uso

🔧 Configuração:
∟ TASK_MANAGER_PROVIDER: [clickup/asana/linear/none]
∟ [Variáveis específicas configuradas]

🚀 Próximos Passos:
∟ Execute /product/task para criar sua primeira task
∟ Use @clickup-specialist para operações ClickUp
∟ Ou execute /engineer/start para iniciar desenvolvimento

💡 Dica: Teste a integração criando uma task de teste:
   /product/task "Task de teste do sistema"
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## 📚 Referências

- **Task Manager Abstraction**: `.claude/utils/task-manager/README.md`
- **Detector de Provedor**: `.claude/utils/task-manager/detector.md`
- **Adapter ClickUp** (transporte API-first, formatação, hierarquia, checklists): `.claude/utils/task-manager/adapters/clickup.md`
- **Comando de Task**: `/product/task` - Criar tasks com decomposição

## ⚠️ Notas Importantes

- **Task Manager é OBRIGATÓRIO** para comandos como `/product/task` funcionarem com sincronização
- **Modo `none`** permite funcionamento offline sem gerenciador
- **Múltiplos provedores** podem ser configurados, mas apenas um será usado por vez via `TASK_MANAGER_PROVIDER`
- **Variáveis opcionais** melhoram UX mas não são obrigatórias (sistema detecta automaticamente)

