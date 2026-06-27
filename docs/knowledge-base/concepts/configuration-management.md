# Gestão de Configurações e Integrações

---

## 📋 Metadata

| Campo | Valor |
|-------|-------|
| **Versão** | 1.0.0 |
| **Data de Criação** | 2025-11-24 |
| **Última Atualização** | 2025-11-24 |
| **Categoria** | Concepts |
| **Aplicação** | Sistema Onion - Configurações e MCPs |

> ⚠️ **Provider-agnóstico**: o Task Manager do Onion é abstraído via
> `TASK_MANAGER_PROVIDER` (jira | clickup | asana | linear | none). Onde o ClickUp
> aparece abaixo (variáveis, validação curl) é **um** provider de exemplo — os demais
> vivem em `.claude/utils/task-manager/adapters/`. Leia o provider ativo do `.env`
> antes de assumir ClickUp. Ver [task-manager-abstraction.md](task-manager-abstraction.md).

### Fontes

- [12-Factor App - Config](https://12factor.net/config)
- [dotenv Best Practices](https://github.com/motdotla/dotenv)
- Práticas do Sistema Onion
- Decisões de arquitetura onion-v3-refactoring

---

## 🎯 Visão Geral

Este documento define padrões para gestão de configurações, credenciais e integrações MCP no Sistema Onion, priorizando segurança, portabilidade e experiência do desenvolvedor.

### Princípios Fundamentais

1. **Segurança**: Credenciais nunca vão para o Git
2. **Portabilidade**: Sistema funciona em qualquer ambiente
3. **Documentação**: Variáveis são auto-explicativas
4. **Onboarding**: Setup guiado para novos usuários
5. **Fallback**: Comportamento definido sem configuração

---

## 📁 Estrutura de Arquivos

### Organização

```
projeto/
├── .env                    # Configurações reais (NÃO versionar)
├── .env.example            # Template documentado (versionar)
├── .gitignore              # Inclui .env
└── .claude/
    └── docs/
        └── configuration/
            └── setup-guide.md  # Guia de configuração
```

### .gitignore Essencial

```gitignore
# Configurações sensíveis
.env
.env.local
.env.*.local

# Credenciais específicas
*.pem
*.key
credentials.json
```

---

## 📝 Estrutura do .env.example

### Template Padrão

```bash
# ═══════════════════════════════════════════════════════════════════════════════
# Sistema Onion - Configurações de Ambiente
# ═══════════════════════════════════════════════════════════════════════════════
# 
# INSTRUÇÕES:
# 1. Copie este arquivo para .env: cp .env.example .env
# 2. Preencha os valores necessários
# 3. NUNCA commite o arquivo .env
#
# ═══════════════════════════════════════════════════════════════════════════════

# ─────────────────────────────────────────────────────────────────────────────────
# TASK MANAGER (provider-agnóstico — abstração SDAAL)
# ─────────────────────────────────────────────────────────────────────────────────
# Escolha o provider ATIVO; preencha SÓ as variáveis dele. O adapter em
# .claude/utils/task-manager/ resolve transporte/formato. Ver CLAUDE.md §Task Manager.

TASK_MANAGER_PROVIDER=clickup        # jira | clickup | asana | linear | none
TASK_MANAGER_TRANSPORT=api           # api (default) | mcp (opcional)

# --- jira ---      (obrigatórias se PROVIDER=jira)
# JIRA_HOST=
# JIRA_EMAIL=
# JIRA_API_TOKEN=
# --- clickup ---   (obrigatórias se PROVIDER=clickup) — https://app.clickup.com/settings/apps
CLICKUP_API_TOKEN=
# CLICKUP_WORKSPACE_ID=
# CLICKUP_DEFAULT_LIST_ID=
# --- asana ---     (obrigatórias se PROVIDER=asana)
# ASANA_ACCESS_TOKEN=
# --- linear ---    (obrigatórias se PROVIDER=linear)
# LINEAR_API_KEY=

# ─────────────────────────────────────────────────────────────────────────────────
# GITHUB INTEGRATION
# ─────────────────────────────────────────────────────────────────────────────────
# Obter em: https://github.com/settings/tokens
# Permissões necessárias: repo, workflow

GITHUB_TOKEN=
# GITHUB_DEFAULT_OWNER=              # Opcional: owner padrão para PRs
# GITHUB_DEFAULT_REPO=               # Opcional: repo padrão

# ─────────────────────────────────────────────────────────────────────────────────
# CONTEXT7 INTEGRATION
# ─────────────────────────────────────────────────────────────────────────────────
# Documentação: consulte docs do Context7

CONTEXT7_ENABLED=false               # true para ativar
# CONTEXT7_API_KEY=                  # Se necessário

# ─────────────────────────────────────────────────────────────────────────────────
# ONION SYSTEM
# ─────────────────────────────────────────────────────────────────────────────────
# Configurações do Sistema Onion

ONION_DEFAULT_LANGUAGE=pt-BR         # Idioma padrão (pt-BR, en-US)
TASK_MANAGER_AUTO_SYNC=true          # Sincronizar com o task manager ativo (qualquer provider)
ONION_SESSION_AUTO_SAVE=true         # Salvar sessões automaticamente
# ONION_LOG_LEVEL=info               # debug, info, warn, error

# ─────────────────────────────────────────────────────────────────────────────────
# ADVANCED (geralmente não precisa alterar)
# ─────────────────────────────────────────────────────────────────────────────────

# AI_MODEL_PREFERENCE=sonnet         # sonnet, opus, haiku, fable
# MAX_CONTEXT_TOKENS=128000          # Limite de tokens por contexto
```

### Convenções de Nomenclatura

| Padrão | Exemplo | Uso |
|--------|---------|-----|
| `SERVICE_VARIABLE` | `CLICKUP_API_TOKEN` | Variável de serviço |
| `SERVICE_DEFAULT_X` | `GITHUB_DEFAULT_REPO` | Valor padrão opcional |
| `SERVICE_ENABLED` | `CONTEXT7_ENABLED` | Toggle de feature |
| `ONION_*` | `ONION_LOG_LEVEL` | Configurações do sistema |

---

## 🔄 Workflow de Onboarding

### Fluxo de Configuração

```
┌─────────────────────────────────────────────────────────────┐
│                    AGENTE INVOCADO                          │
└─────────────────────────────┬───────────────────────────────┘
                              │
                              ▼
                    ┌─────────────────────┐
                    │ Precisa de MCP/     │
                    │ integração?         │
                    └──────────┬──────────┘
                               │
              ┌────────────────┴────────────────┐
              │ SIM                              │ NÃO
              ▼                                  ▼
    ┌─────────────────────┐            ┌─────────────────────┐
    │ Verificar .env      │            │ Executar            │
    │ existe?             │            │ normalmente         │
    └──────────┬──────────┘            └─────────────────────┘
               │
    ┌──────────┴──────────┐
    │ SIM                 │ NÃO
    ▼                     ▼
┌─────────────┐    ┌─────────────────────┐
│ Variável    │    │ "Deseja configurar  │
│ configurada?│    │ .env agora?"        │
└──────┬──────┘    └──────────┬──────────┘
       │                      │
  ┌────┴────┐           ┌─────┴─────┐
  │SIM      │NÃO        │SIM        │NÃO
  ▼         ▼           ▼           ▼
┌─────┐  ┌──────────┐  ┌─────────┐  ┌──────────────┐
│VALID│  │"Deseja   │  │GUIAR    │  │Perguntar:    │
│ AR  │  │configurar│  │CONFIG   │  │ - Configurar │
│     │  │agora?"   │  │         │  │ - Continuar  │
└──┬──┘  └────┬─────┘  └────┬────┘  │ - Abortar    │
   │          │              │      └──────────────┘
   ▼          │              │
┌──────────┐  │              │
│Complexi- │  │              │
│dade?     │  │              │
└────┬─────┘  │              │
     │        │              │
┌────┴────┐   │              │
│BAIXA    │ALTA              │
▼         ▼   │              │
┌────┐ ┌─────────────┐       │
│AUTO│ │"Posso       │       │
│    │ │validar?"    │       │
└─┬──┘ └──────┬──────┘       │
  │           │              │
  └─────┬─────┘              │
        ▼                    ▼
    EXECUTAR              FALLBACK
```

### Níveis de Complexidade

| Nível | Validação | Exemplo |
|-------|-----------|---------|
| **Baixa** | Automática | Verificar formato de token |
| **Média** | Perguntar antes | Fazer API call de teste |
| **Alta** | Sempre perguntar | Operações que consomem créditos |

### Mensagens de Onboarding

**Quando .env não existe:**
```
⚠️ Arquivo .env não encontrado.

Este comando usa o task manager configurado (via TASK_MANAGER_PROVIDER).
Para configurar:

1. Copie o template: cp .env.example .env
2. Defina TASK_MANAGER_PROVIDER (jira | clickup | asana | linear | none)
3. Preencha as variáveis do provider escolhido
   (ex.: jira → JIRA_HOST/JIRA_EMAIL/JIRA_API_TOKEN; clickup → CLICKUP_API_TOKEN)

Deseja:
(a) Configurar agora (vou te guiar pelo /meta:setup-integration)
(b) Continuar sem integração (provider=none)
(c) Abortar
```

**Quando variável não configurada:**
```
⚠️ Variável obrigatória do provider ativo não configurada.

Detecte TASK_MANAGER_PROVIDER no .env e configure as variáveis dele:
- jira    → JIRA_HOST, JIRA_EMAIL, JIRA_API_TOKEN
- clickup → CLICKUP_API_TOKEN (https://app.clickup.com/settings/apps)
- asana   → ASANA_ACCESS_TOKEN
- linear  → LINEAR_API_KEY

Deseja continuar sem a integração (provider=none)?
```

---

## 🔐 Segurança

### Regras de Ouro

1. **Nunca** hardcode credenciais no código
2. **Nunca** commite .env
3. **Sempre** use .env.example para documentar
4. **Sempre** valide tokens antes de usar
5. **Sempre** ofereça fallback quando possível

### Validação de Tokens

```typescript
// Pseudocódigo de validação
async function validateToken(service: string, token: string): Promise<ValidationResult> {
  const complexity = getValidationComplexity(service);
  
  if (complexity === 'low') {
    // Validar formato automaticamente
    return validateFormat(service, token);
  }
  
  if (complexity === 'medium' || complexity === 'high') {
    // Perguntar antes de fazer API call
    const proceed = await askUser(`Posso validar o token ${service}?`);
    if (!proceed) return { valid: 'unknown', message: 'Não validado' };
  }
  
  try {
    return await testApiConnection(service, token);
  } catch (error) {
    return { valid: false, message: error.message };
  }
}
```

### Erros e Fallbacks

| Erro | Fallback | Mensagem |
|------|----------|----------|
| Token inválido | Perguntar ao usuário | "Token inválido. Reconfigure?" |
| Serviço indisponível | Retry ou skip | "Task manager indisponível. Continuar sem?" |
| Permissão negada | Guiar reconfiguração | "Permissões insuficientes. Veja..." |
| .env ausente | Criar ou skip | "Criar .env agora?" |

---

## 🔌 Integrações Suportadas

> **Task Manager é plugável**: o ClickUp abaixo é **um** dos providers (`jira` | `clickup` | `asana` | `linear`), selecionado por `TASK_MANAGER_PROVIDER`. O consumo é sempre via a abstração (`taskManager.*`) — o adapter resolve transporte (REST API default; MCP opcional). Variáveis dos demais providers: ver `.claude/utils/task-manager/adapters/`.

### ClickUp (provider de Task Manager)

**Variáveis:**
| Variável | Obrigatória | Descrição |
|----------|-------------|-----------|
| `CLICKUP_API_TOKEN` | ✅ | Token de API pessoal |
| `CLICKUP_WORKSPACE_ID` | ✅ | ID do workspace |
| `CLICKUP_DEFAULT_LIST_ID` | ❌ | Lista padrão para tasks |

**Como Obter:**
1. Acesse https://app.clickup.com/settings/apps
2. Clique em "Generate" ou "Regenerate"
3. Copie o token
4. Para Workspace ID: URL do ClickUp contém (ex: `app.clickup.com/<workspace_id>/...`)

**Validação:**
```bash
# Teste manual (curl)
curl -H "Authorization: $CLICKUP_API_TOKEN" \
  https://api.clickup.com/api/v2/team
```

### GitHub MCP

**Variáveis:**
| Variável | Obrigatória | Descrição |
|----------|-------------|-----------|
| `GITHUB_TOKEN` | ✅ | Personal Access Token |
| `GITHUB_DEFAULT_OWNER` | ❌ | Owner padrão para PRs |
| `GITHUB_DEFAULT_REPO` | ❌ | Repo padrão |

**Como Obter:**
1. Acesse https://github.com/settings/tokens
2. "Generate new token (classic)"
3. Selecione escopos: `repo`, `workflow`
4. Copie o token gerado

### Context7

**Variáveis:**
| Variável | Obrigatória | Descrição |
|----------|-------------|-----------|
| `CONTEXT7_ENABLED` | ❌ | Toggle (true/false) |
| `CONTEXT7_API_KEY` | Condicional | Se serviço requer autenticação |

---

## 📋 Template para Agentes

### Agente Especializado (com MCP)

> Exemplo com o **especialista dedicado de UM provider** (ClickUp). Só o especialista do provider
> usa `mcp__<provider>__*` direto; o **consumidor** (comando/agente comum) nunca faz isso — vai pela
> abstração `taskManager.*`, que resolve o provider ativo (`TASK_MANAGER_PROVIDER`: jira | clickup |
> asana | linear). Ver [task-manager-abstraction.md](task-manager-abstraction.md).

```yaml
---
name: clickup-specialist
tools:
  - Read
  - write
  - mcp__clickup__*  # MCP do provider — legítimo só aqui (especialista dedicado), não no consumidor
---

## 🔧 Configurações Necessárias

Este agente requer as seguintes variáveis de ambiente:

| Variável | Obrigatória | Descrição | Como Obter |
|----------|-------------|-----------|------------|
| `CLICKUP_API_TOKEN` | ✅ | Token de API | [ClickUp Settings](https://app.clickup.com/settings/apps) |
| `CLICKUP_WORKSPACE_ID` | ✅ | ID do workspace | URL do ClickUp |

### Verificação
Ao ser invocado, este agente:
1. Verifica existência do .env
2. Valida tokens automaticamente (baixa complexidade)
3. Se inválido, guia reconfiguração
```

### Agente Agnóstico (sem MCP)

```yaml
---
name: task-specialist
tools:
  - Read
  - write
  - Grep
  - grep
---

## 🔌 Integrações Opcionais

Este agente pode ser potencializado com MCPs quando disponíveis:

| MCP | Variáveis | Uso |
|-----|-----------|-----|
| ClickUp | `CLICKUP_*` | Criar/atualizar tasks |
| GitHub | `GITHUB_*` | Criar PRs, issues |

Consulte `docs/knowledge-base/concepts/configuration-management.md` para setup.

### Fallback
Sem integrações configuradas, o agente:
- Gera output em formato Markdown
- Sugere ações manuais ao usuário
```

---

## 🔄 Comandos de Configuração

### /onion/setup (Proposto)

```markdown
# Setup do Sistema Onion

## Processo
1. Verificar .env existe
2. Se não: criar a partir de .env.example
3. Guiar configuração de cada integração
4. Validar tokens
5. Confirmar setup completo

## Integrações
- [ ] ClickUp
- [ ] GitHub
- [ ] Context7

## Output
- .env configurado
- Integrações validadas
- Relatório de status
```

---

## ⚠️ Anti-Patterns

### 1. Hardcoded Credentials

**❌ Problema:**
```typescript
const token = process.env.SLACK_TOKEN;
```

**✅ Solução:**
```typescript
const token = process.env.SLACK_TOKEN;
```

### 2. Commit de .env

**❌ Problema:** .env no repositório

**✅ Solução:** .gitignore + .env.example

### 3. Falha Silenciosa

**❌ Problema:**
```typescript
if (!token) {
  // Silenciosamente não faz nada
}
```

**✅ Solução:**
```typescript
if (!token) {
  console.warn("⚠️ CLICKUP_TOKEN não configurado. Integrações desativadas.");
  return askUserForAction(['configurar', 'continuar', 'abortar']);
}
```

### 4. Validação Excessiva

**❌ Problema:** Validar token a cada chamada

**✅ Solução:** Validar uma vez por sessão, cachear resultado

---

## 📚 Recursos Adicionais

- [12-Factor App](https://12factor.net/)
- [dotenv Documentation](https://github.com/motdotla/dotenv)
- [ClickUp API Docs](https://clickup.com/api)
- [GitHub Token Scopes](https://docs.github.com/en/developers/apps/building-oauth-apps/scopes-for-oauth-apps)

---

**Próxima Atualização Planejada**: Janeiro 2026
**Responsável**: Sistema Onion

