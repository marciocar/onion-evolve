# 🔍 Detector de Provedor - Task Manager

## 🎯 Propósito

Detecta e valida o provedor de gerenciamento de tarefas configurado e o transporte a usar (API REST ou MCP), além de identificar a origem de IDs de tasks para garantir compatibilidade.

---

## 📋 Funções Principais

### detectTransport()

```typescript
/**
 * Detecta o transporte configurado via variável de ambiente.
 *
 * TASK_MANAGER_TRANSPORT controla como o adapter se comunica com o provider:
 *   'api'  (default) — REST API direta; sempre disponível.
 *   'mcp'            — MCP server do provider; usado apenas quando disponível
 *                      para o provider ativo. Cai para 'api' se indisponível.
 *
 * @returns 'api' | 'mcp'
 */
function detectTransport(): TaskManagerTransport {
  const raw = (process.env.TASK_MANAGER_TRANSPORT || 'api').toLowerCase();
  return raw === 'mcp' ? 'mcp' : 'api';
}
```

---

### detectProvider()

```typescript
/**
 * Detecta o provedor configurado via variáveis de ambiente e resolve o
 * transporte ativo. O campo `transport` no ProviderConfig retornado reflete
 * a decisão final. Todos os providers honram o transporte solicitado
 * (api default; mcp opcional); a disponibilidade real do servidor MCP é
 * verificada em RUNTIME pelo adapter, que cai para 'api' se o MCP não responder.
 * 'none' opera offline (transport='api').
 *
 * @returns Configuração do provedor ativo (inclui campo `transport`)
 */
function detectProvider(): ProviderConfig {
  const provider = (process.env.TASK_MANAGER_PROVIDER || 'none') as TaskManagerProvider;
  const requestedTransport = detectTransport();

  /**
   * Resolve o transporte efetivo (uniforme para todos os providers):
   * 'none' opera offline (api); os demais honram o solicitado (api default | mcp).
   * A disponibilidade real do MCP é verificada em runtime pelo adapter (fallback → api).
   */
  function resolveTransport(p: TaskManagerProvider): TaskManagerTransport {
    return p === 'none' ? 'api' : requestedTransport;
  }

  const configs: Record<TaskManagerProvider, ProviderConfig> = {
    clickup: {
      provider: 'clickup',
      transport: resolveTransport('clickup'),
      isConfigured: !!process.env.CLICKUP_API_TOKEN,
      requiredEnvVars: ['CLICKUP_API_TOKEN'],
      optionalEnvVars: ['CLICKUP_WORKSPACE_ID', 'CLICKUP_DEFAULT_LIST_ID'],
      errorMessage: !process.env.CLICKUP_API_TOKEN
        ? '❌ CLICKUP_API_TOKEN não configurado. Execute /meta/setup-integration'
        : undefined
    },

    asana: {
      provider: 'asana',
      transport: resolveTransport('asana'),
      isConfigured: !!process.env.ASANA_ACCESS_TOKEN,
      requiredEnvVars: ['ASANA_ACCESS_TOKEN'],
      optionalEnvVars: ['ASANA_WORKSPACE_ID', 'ASANA_DEFAULT_PROJECT_ID'],
      errorMessage: !process.env.ASANA_ACCESS_TOKEN
        ? '❌ ASANA_ACCESS_TOKEN não configurado. Execute /meta/setup-integration'
        : undefined
    },

    jira: (() => {
      const host = process.env.JIRA_HOST;
      const token = process.env.JIRA_API_TOKEN;
      const authType = (process.env.JIRA_AUTH_TYPE || 'basic') as 'basic' | 'bearer';
      const email = process.env.JIRA_EMAIL;
      const isConfigured = !!(host && token && (authType === 'bearer' || email));

      const missing: string[] = [];
      if (!host) missing.push('JIRA_HOST');
      if (!token) missing.push('JIRA_API_TOKEN');
      if (authType !== 'bearer' && !email) missing.push('JIRA_EMAIL');

      return {
        provider: 'jira' as TaskManagerProvider,
        transport: resolveTransport('jira'),
        isConfigured,
        requiredEnvVars: ['JIRA_HOST', 'JIRA_API_TOKEN', 'JIRA_EMAIL'],
        optionalEnvVars: ['JIRA_PROJECT_KEY', 'JIRA_AUTH_TYPE', 'JIRA_API_VERSION'],
        errorMessage: !isConfigured
          ? `❌ Jira não configurado. Variáveis faltando: ${missing.join(', ')}. Execute /meta/setup-integration`
          : undefined
      };
    })(),

    linear: {
      provider: 'linear',
      transport: resolveTransport('linear'),
      isConfigured: !!process.env.LINEAR_API_KEY,
      requiredEnvVars: ['LINEAR_API_KEY'],
      optionalEnvVars: ['LINEAR_TEAM_ID'],
      errorMessage: !process.env.LINEAR_API_KEY
        ? '❌ LINEAR_API_KEY não configurado. Execute /meta/setup-integration'
        : undefined
    },

    none: {
      provider: 'none',
      transport: 'api',  // Modo offline; sem transporte real
      isConfigured: true,  // Sempre "configurado" pois é o fallback
      requiredEnvVars: [],
      optionalEnvVars: [],
      errorMessage: undefined
    }
  };

  return configs[provider] || configs.none;
}
```

---

### detectProviderFromTaskId()

```typescript
/**
 * Detecta o provedor de origem baseado no formato do ID da task.
 * @param taskId - ID da task a analisar
 * @returns Provedor detectado ou null se formato desconhecido
 */
function detectProviderFromTaskId(taskId: string): TaskManagerProvider | null {
  if (!taskId || typeof taskId !== 'string') {
    return null;
  }
  
  const trimmedId = taskId.trim();
  
  // ═══════════════════════════════════════════════════════════════════════════
  // CLICKUP
  // Formato: alfanumérico, 9 caracteres (ex: 86adfe9eb, abc123def)
  // ═══════════════════════════════════════════════════════════════════════════
  if (/^[a-z0-9]{9}$/i.test(trimmedId)) {
    return 'clickup';
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // ASANA
  // Formato: numérico, 16+ dígitos (ex: 1234567890123456)
  // ═══════════════════════════════════════════════════════════════════════════
  if (/^\d{15,}$/.test(trimmedId)) {
    return 'asana';
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // JIRA / LINEAR (formato PREFIX-NUM colide entre os dois)
  // - Jira:   PROJ-123 (project key + número)
  // - Linear: ABC-456  (team prefix + número)
  // Disambiguação: consulta TASK_MANAGER_PROVIDER em runtime; se for jira/linear,
  // retorna o configurado. Caso contrário, default = linear (por compatibilidade
  // histórica com a detecção anterior).
  // ═══════════════════════════════════════════════════════════════════════════
  if (/^[A-Z][A-Z0-9_]*-\d+$/.test(trimmedId)) {
    const configured = (process.env.TASK_MANAGER_PROVIDER || '').toLowerCase();
    if (configured === 'jira') return 'jira';
    if (configured === 'linear') return 'linear';
    return 'linear'; // fallback
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LINEAR (UUID)
  // Formato: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
  // ═══════════════════════════════════════════════════════════════════════════
  if (/^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$/i.test(trimmedId)) {
    return 'linear';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // JIRA (ID interno numérico — raro em uso humano, mas válido)
  // Formato: número puro, 5+ dígitos (ex: 10000, 234567)
  // Distinguir de Asana (15+ dígitos) por comprimento
  // ═══════════════════════════════════════════════════════════════════════════
  if (/^\d{5,14}$/.test(trimmedId)) {
    const configured = (process.env.TASK_MANAGER_PROVIDER || '').toLowerCase();
    if (configured === 'jira') return 'jira';
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // LOCAL (gerado pelo NoProviderAdapter)
  // Formato: local-timestamp (ex: local-1732456789012)
  // ═══════════════════════════════════════════════════════════════════════════
  if (/^local-\d+$/.test(trimmedId)) {
    return 'none';
  }
  
  // Formato desconhecido
  return null;
}
```

---

### validateProviderMatch()

```typescript
/**
 * Valida se um ID de task é compatível com o provedor configurado.
 * @param taskId - ID da task a validar
 * @param currentProvider - Provedor atualmente configurado
 * @returns Resultado da validação com possível warning
 */
function validateProviderMatch(
  taskId: string, 
  currentProvider: TaskManagerProvider
): ValidationResult {
  const detectedProvider = detectProviderFromTaskId(taskId);
  
  // Formato desconhecido - assumir válido
  if (!detectedProvider) {
    return { 
      valid: true, 
      warning: null,
      detectedProvider: null
    };
  }
  
  // Provedor 'none' aceita qualquer ID (modo offline)
  if (currentProvider === 'none') {
    return {
      valid: true,
      warning: `ℹ️ Task ID "${taskId}" detectado como ${detectedProvider}, ` +
               `mas nenhum provedor está configurado. Operando em modo local.`,
      detectedProvider
    };
  }
  
  // Provedores diferentes - incompatibilidade
  if (detectedProvider !== currentProvider) {
    return {
      valid: false,
      warning: `⚠️ INCOMPATIBILIDADE DETECTADA\n` +
               `━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n` +
               `Task ID: "${taskId}"\n` +
               `Provedor detectado: ${detectedProvider}\n` +
               `Provedor configurado: ${currentProvider}\n\n` +
               `💡 Ações sugeridas:\n` +
               `   1. Altere TASK_MANAGER_PROVIDER para '${detectedProvider}' no .env\n` +
               `   2. Ou limpe a sessão atual e crie uma nova task\n` +
               `   3. Execute /meta/setup-integration para reconfigurar`,
      detectedProvider
    };
  }
  
  // Tudo OK
  return { 
    valid: true, 
    warning: null,
    detectedProvider 
  };
}
```

---

### checkProviderConfiguration()

```typescript
/**
 * Verifica a configuração completa do provedor e do transporte.
 * @returns Objeto com status, transporte ativo e mensagens
 */
function checkProviderConfiguration(): {
  provider: TaskManagerProvider;
  transport: TaskManagerTransport;
  isConfigured: boolean;
  missingVars: string[];
  optionalVars: { name: string; set: boolean }[];
  message: string;
} {
  const config = detectProvider();

  const missingVars = config.requiredEnvVars.filter(
    varName => !process.env[varName]
  );

  const optionalVars = config.optionalEnvVars.map(varName => ({
    name: varName,
    set: !!process.env[varName]
  }));

  // Informa o transporte escolhido (a disponibilidade real do MCP é runtime)
  const requestedTransport = detectTransport();
  const transportNote = (requestedTransport === 'mcp' && config.transport === 'mcp')
    ? `\nℹ️ TASK_MANAGER_TRANSPORT=mcp: o adapter usará MCP se o servidor estiver disponível em runtime; senão, cai para API.`
    : '';

  let message: string;

  if (config.provider === 'none') {
    message = `ℹ️ Nenhum gerenciador de tarefas configurado.\n` +
              `Transporte: ${config.transport} (modo offline).\n` +
              `Comandos funcionarão em modo offline.\n` +
              `Execute /meta/setup-integration para configurar.`;
  } else if (!config.isConfigured) {
    message = `❌ ${config.provider.toUpperCase()} selecionado mas não configurado.\n` +
              `Variáveis faltando: ${missingVars.join(', ')}\n` +
              `Execute /meta/setup-integration para configurar.`;
  } else {
    const optionalStatus = optionalVars
      .map(v => `   ${v.set ? '✅' : '⚪'} ${v.name}`)
      .join('\n');

    message = `✅ ${config.provider.toUpperCase()} configurado corretamente.\n` +
              `Transporte ativo: ${config.transport}${transportNote}\n` +
              `Variáveis opcionais:\n${optionalStatus}`;
  }

  return {
    provider: config.provider,
    transport: config.transport,
    isConfigured: config.isConfigured,
    missingVars,
    optionalVars,
    message
  };
}
```

---

## 📊 Tabela de Formatos de ID

| Provedor | Formato | Regex | Exemplo | Notas |
|----------|---------|-------|---------|-------|
| ClickUp | 9 chars alfanuméricos | `^[a-z0-9]{9}$` | `86adfe9eb` | Único |
| Asana | 15+ dígitos | `^\d{15,}$` | `1234567890123456` | Único |
| Jira (key) | PREFIXO-NUMERO | `^[A-Z][A-Z0-9_]*-\d+$` | `PROJ-123` | ⚠️ Colide com Linear — desambigua via `TASK_MANAGER_PROVIDER` |
| Jira (ID) | 5-14 dígitos | `^\d{5,14}$` | `10000` | Só identificado se `TASK_MANAGER_PROVIDER=jira` |
| Linear (key) | PREFIXO-NUMERO | `^[A-Z]+-\d+$` | `DEV-123` | ⚠️ Colide com Jira — default quando não desambiguado |
| Linear (UUID) | UUID v4 | UUID regex | `a1b2c3d4-...` | Único |
| Local | local-timestamp | `^local-\d+$` | `local-1732456789` | Único |

---

## 🧪 Exemplos de Uso

```typescript
// Detectar provedor e transporte configurados
const config = detectProvider();
console.log(`Provedor:   ${config.provider}`);
console.log(`Transporte: ${config.transport}`);   // 'api' | 'mcp'
console.log(`Configurado: ${config.isConfigured}`);

// Detectar apenas o transporte
const transport = detectTransport();  // lê TASK_MANAGER_TRANSPORT; default 'api'

// Validar ID de task
const taskId = '86adfe9eb';
const currentProvider = 'asana';
const validation = validateProviderMatch(taskId, currentProvider);

if (!validation.valid) {
  console.warn(validation.warning);
  // Perguntar ao usuário o que fazer
}

// Verificar configuração completa (inclui campo `transport` no retorno)
const status = checkProviderConfiguration();
console.log(status.message);
// Ex: "✅ CLICKUP configurado corretamente.\nTransporte ativo: mcp\n..."
```

---

## 🔀 Lógica de Transporte

| `TASK_MANAGER_TRANSPORT` | Provider | Transporte efetivo | Motivo |
|--------------------------|----------|--------------------|--------|
| `api` (ou ausente)       | qualquer | `api`              | default |
| `mcp`                    | `clickup`/`asana`/`jira`/`linear` | `mcp` | usa MCP se disponível em runtime; senão fallback p/ `api` |
| `mcp`                    | `none`    | `api`             | modo offline — sem transporte real |

> Os adapters consultam `config.transport` para decidir qual via usar internamente
> (REST direto vs. chamadas ao servidor MCP). Ver cada adapter doc para detalhes.

---

## 📚 Referências

- [Types](./types.md) - Definições de tipos (inclui `TaskManagerTransport` e campo `transport` em `ProviderConfig`)
- [Factory](./factory.md) - Criação de adapters
- [SDAAL](../../../docs/knowledge-base/concepts/specification-driven-ai-abstraction-layer.md) - Padrão-pai

---

**Versão**: 1.1.0
**Criado em**: 2025-11-24
**Atualizado em**: 2026-06-13

