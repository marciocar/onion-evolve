# Exemplos de Templates SDAAL

## 📋 Metadados

| Campo | Valor |
|-------|-------|
| **Versão** | 1.0.0 |
| **Criado** | 2026-06-02 |
| **Última Atualização** | 2026-06-15 |
| **Categoria** | Patterns |
| **Tags** | `sdaal`, `abstraction-layer`, `templates`, `adapter-pattern`, `factory` |

---

## 🎯 Visão Geral

Este documento reúne os **templates completos de geração** usados pelo comando `/meta/create-abstraction` ao criar uma nova Abstraction Layer seguindo o padrão **SDAAL** (Specification-Driven AI Abstraction Layer).

Para a **explicação conceitual** do padrão (fundamentos, arquitetura, design patterns, anti-patterns), consulte:
- [Specification-Driven AI Abstraction Layer](../concepts/specification-driven-ai-abstraction-layer.md)
- [Task Manager Abstraction](../concepts/task-manager-abstraction.md) — implementação de referência

Os templates abaixo usam placeholders `{{...}}` que são substituídos durante a geração:

| Placeholder | Exemplo | Derivação |
|-------------|---------|-----------|
| `{{abstraction_name}}` | `notification-manager` | input (kebab-case) |
| `{{interface_name}}` | `INotificationManager` | `I` + PascalCase do nome |
| `{{providers}}` | `slack,discord,email` | input (ou `none`) |
| `{{env_prefix}}` | `NOTIFICATION_MANAGER` | UPPER_SNAKE do nome |
| `{{description}}` | descrição livre | input |
| `{{data_atual}}` | `2026-06-02` | data corrente |

> Convenção `interface_name.slice(1)`: remove o prefixo `I` (ex.: `INotificationManager` → `NotificationManager`), usado em nomes de provider type e funções factory `get<Nome>()`.

---

## 1. README.md

```markdown
# 🔌 {{interface_name}} - Abstraction Layer

## 🎯 Propósito

Camada de abstração que permite trocar o provedor de {{description}} sem modificar os comandos do Sistema Onion.

## 📁 Estrutura

\`\`\`
{{abstraction_name}}/
├── README.md          # Este arquivo
├── interface.md       # Interface {{interface_name}}
├── types.md           # Tipos compartilhados
├── detector.md        # Detecção de provedor
├── factory.md         # Factory para adapters
└── adapters/
{{#each providers}}
    ├── {{this}}.md    # Adapter {{this}}
{{/each}}
    └── none.md        # Adapter Fallback
\`\`\`

## ⚡ Uso Rápido

### 1. Configurar Provedor

No \`.env\`:
\`\`\`bash
{{env_prefix}}_PROVIDER={{providers[0]}}  # {{providers.join(' | ')}} | none
\`\`\`

### 2. Usar nos Comandos

\`\`\`typescript
import { get{{interface_name.slice(1)}} } from '.claude/utils/{{abstraction_name}}/factory';

const manager = get{{interface_name.slice(1)}}();
await manager.send({ ... });
\`\`\`

## 🔧 Provedores Suportados

| Provedor | Status | Notas |
|----------|--------|-------|
{{#each providers}}
| {{this}} | 📝 Stub | Implementação necessária |
{{/each}}
| None | ✅ Funcional | Modo offline |

## 📚 Documentação Relacionada

- [SDAAL Pattern](../../docs/knowledge-base/concepts/specification-driven-ai-abstraction-layer.md)
- [Interface](./interface.md)
- [Factory](./factory.md)

---

**Versão**: 1.0.0
**Criado em**: {{data_atual}}
```

---

## 2. interface.md

```markdown
# 📐 Interface {{interface_name}}

## 🎯 Propósito

Define o contrato que todos os adapters devem implementar, garantindo consistência e permitindo troca transparente de provedores.

---

## 📋 Interface Completa

\`\`\`typescript
/**
 * Interface abstrata para {{description}}.
 * Todos os adapters devem implementar esta interface.
 */
interface {{interface_name}} {
  // ═══════════════════════════════════════════════════════════════════════════
  // IDENTIFICAÇÃO
  // ═══════════════════════════════════════════════════════════════════════════

  /** Nome do provedor: '{{providers.join("' | '")}}' | 'none' */
  readonly provider: {{interface_name.slice(1)}}Provider;

  /** Indica se o provedor está configurado corretamente */
  readonly isConfigured: boolean;

  // ═══════════════════════════════════════════════════════════════════════════
  // OPERAÇÕES PRINCIPAIS
  // ═══════════════════════════════════════════════════════════════════════════

  // TODO: Adicionar métodos específicos da abstração
  // Exemplo:
  // send(input: SendInput): Promise<SendOutput>;
  // get(id: string): Promise<ItemOutput>;

  // ═══════════════════════════════════════════════════════════════════════════
  // VALIDAÇÃO
  // ═══════════════════════════════════════════════════════════════════════════

  /** Valida configuração do provedor. @returns true se válida */
  validateConfiguration(): boolean;
}
\`\`\`

---

## 📊 Métodos por Categoria

| Categoria | Métodos | Descrição |
|-----------|---------|-----------|
| **Identificação** | \`provider\`, \`isConfigured\` | Informações do adapter |
| **Principais** | TODO | Operações de negócio |
| **Validação** | \`validateConfiguration\` | Verificação de setup |

---

## 🔄 Implementação Necessária

1. Definir métodos específicos em [types.md](./types.md)
2. Implementar em cada adapter em [adapters/](./adapters/)
3. Atualizar mapeamentos de campos

---

**Versão**: 1.0.0
**Criado em**: {{data_atual}}
```

---

## 3. types.md

```markdown
# 📦 Tipos Compartilhados - {{interface_name}}

## 🎯 Propósito

Define os tipos TypeScript compartilhados entre todos os adapters, garantindo consistência nas operações de entrada e saída.

---

## 🔧 Enums e Constantes

\`\`\`typescript
/** Provedores suportados. */
type {{interface_name.slice(1)}}Provider = '{{providers.join("' | '")}}' | 'none';
\`\`\`

---

## 📥 Tipos de Entrada (Input)

\`\`\`typescript
/** TODO: Definir tipos de entrada. Exemplo: */
interface BaseInput {
  /** Campo obrigatório */
  requiredField: string;
  /** Campo opcional */
  optionalField?: string;
}
\`\`\`

---

## 📤 Tipos de Saída (Output)

\`\`\`typescript
/** TODO: Definir tipos de saída. Exemplo: */
interface BaseOutput {
  /** ID único */
  id: string;
  /** Provedor de origem */
  provider: {{interface_name.slice(1)}}Provider;
  /** Timestamp de criação */
  createdAt: string;
}
\`\`\`

---

## ⚙️ Tipos de Configuração

\`\`\`typescript
/** Configuração de um provedor. */
interface ProviderConfig {
  provider: {{interface_name.slice(1)}}Provider;
  isConfigured: boolean;
  requiredEnvVars: string[];
  optionalEnvVars: string[];
  errorMessage?: string;
}
\`\`\`

---

**Versão**: 1.0.0
**Criado em**: {{data_atual}}
```

---

## 4. detector.md

```markdown
# 🔍 Detector de Provedor - {{interface_name}}

## 🎯 Propósito

Detecta e valida o provedor configurado via variáveis de ambiente.

---

## 📋 Funções Principais

### detectProvider()

\`\`\`typescript
/** Detecta o provedor configurado via env. @returns Config do provedor ativo */
function detectProvider(): ProviderConfig {
  const provider = (process.env.{{env_prefix}}_PROVIDER || 'none') as {{interface_name.slice(1)}}Provider;

  const configs: Record<{{interface_name.slice(1)}}Provider, ProviderConfig> = {
{{#each providers}}
    '{{this}}': {
      provider: '{{this}}',
      isConfigured: !!process.env.{{../env_prefix}}_{{this.toUpperCase()}}_TOKEN,
      requiredEnvVars: ['{{../env_prefix}}_{{this.toUpperCase()}}_TOKEN'],
      optionalEnvVars: ['{{../env_prefix}}_{{this.toUpperCase()}}_WORKSPACE'],
      errorMessage: !process.env.{{../env_prefix}}_{{this.toUpperCase()}}_TOKEN
        ? '❌ {{../env_prefix}}_{{this.toUpperCase()}}_TOKEN não configurado'
        : undefined
    },
{{/each}}
    'none': {
      provider: 'none',
      isConfigured: true,
      requiredEnvVars: [],
      optionalEnvVars: [],
      errorMessage: undefined
    }
  };

  return configs[provider] || configs.none;
}
\`\`\`

### checkProviderConfiguration()

\`\`\`typescript
/** Verifica a configuração completa do provedor. */
function checkProviderConfiguration(): {
  provider: {{interface_name.slice(1)}}Provider;
  isConfigured: boolean;
  missingVars: string[];
  message: string;
} {
  const config = detectProvider();
  const missingVars = config.requiredEnvVars.filter(v => !process.env[v]);

  let message: string;
  if (config.provider === 'none') {
    message = 'ℹ️ Nenhum provedor configurado. Operando em modo offline.';
  } else if (!config.isConfigured) {
    message = \`❌ \${config.provider.toUpperCase()} não configurado. Faltando: \${missingVars.join(', ')}\`;
  } else {
    message = \`✅ \${config.provider.toUpperCase()} configurado corretamente.\`;
  }

  return { provider: config.provider, isConfigured: config.isConfigured, missingVars, message };
}
\`\`\`

---

## 📊 Variáveis de Ambiente

| Provedor | Variável Obrigatória | Variáveis Opcionais |
|----------|---------------------|---------------------|
{{#each providers}}
| {{this}} | \`{{../env_prefix}}_{{this.toUpperCase()}}_TOKEN\` | \`{{../env_prefix}}_{{this.toUpperCase()}}_WORKSPACE\` |
{{/each}}
| none | - | - |

---

**Versão**: 1.0.0
**Criado em**: {{data_atual}}
```

---

## 5. factory.md

```markdown
# 🏭 Factory - {{interface_name}}

## 🎯 Propósito

Fornece factory para instanciar o adapter correto baseado na configuração do ambiente.

---

## 📋 Função Principal

\`\`\`typescript
/**
 * Retorna uma instância do manager configurado.
 * Baseado em {{env_prefix}}_PROVIDER no .env
 */
function get{{interface_name.slice(1)}}(options?: FactoryOptions): {{interface_name}} {
  const config = detectProvider();

  if (options?.debug) {
    console.log(\`[{{interface_name}}] Provider: \${config.provider}\`);
    console.log(\`[{{interface_name}}] Configured: \${config.isConfigured}\`);
  }

  if (!config.isConfigured) {
    if (options?.throwOnMisconfigured) {
      throw new Error(config.errorMessage || 'Provider not configured');
    }
    console.warn(\`⚠️ \${config.errorMessage}\`);
    console.warn(\`💡 Continuando em modo offline...\`);
    return new NoProviderAdapter();
  }

  switch (config.provider) {
{{#each providers}}
    case '{{this}}':
      return new {{this.charAt(0).toUpperCase() + this.slice(1)}}Adapter({
        token: process.env.{{../env_prefix}}_{{this.toUpperCase()}}_TOKEN!,
        workspace: process.env.{{../env_prefix}}_{{this.toUpperCase()}}_WORKSPACE
      });
{{/each}}
    case 'none':
    default:
      return new NoProviderAdapter();
  }
}
\`\`\`

---

## ⚙️ Tipos da Factory

\`\`\`typescript
interface FactoryOptions {
  debug?: boolean;
  throwOnMisconfigured?: boolean;
  forceProvider?: {{interface_name.slice(1)}}Provider;
}
\`\`\`

---

## 📊 NoProviderAdapter (Fallback)

\`\`\`typescript
class NoProviderAdapter implements {{interface_name}} {
  readonly provider: {{interface_name.slice(1)}}Provider = 'none';
  readonly isConfigured: boolean = false;

  // TODO: Implementar métodos com comportamento offline

  validateConfiguration(): boolean {
    return false;
  }
}
\`\`\`

---

## 🧪 Exemplos de Uso

\`\`\`typescript
const manager = get{{interface_name.slice(1)}}();

if (manager.isConfigured) {
  // Operações online
} else {
  console.log('⚠️ Modo offline');
}

try {
  const m = get{{interface_name.slice(1)}}({ throwOnMisconfigured: true });
} catch (error) {
  console.error('❌ Provedor não configurado');
}
\`\`\`

---

**Versão**: 1.0.0
**Criado em**: {{data_atual}}
```

---

## 6. adapters/{{provider}}.md

Gerar um arquivo por provedor em `{{providers}}`:

```markdown
# 🔵 {{provider}} Adapter

## 🎯 Propósito

Implementação do {{interface_name}} para {{provider}}.

---

## 📋 Configuração

\`\`\`bash
# Obrigatória
{{env_prefix}}_{{provider.toUpperCase()}}_TOKEN=xxx
# Opcionais
{{env_prefix}}_{{provider.toUpperCase()}}_WORKSPACE=xxx
\`\`\`

---

## 🔧 Implementação

\`\`\`typescript
/** Adapter {{provider}} implementando {{interface_name}}. */
class {{provider.charAt(0).toUpperCase() + provider.slice(1)}}Adapter implements {{interface_name}} {
  readonly provider: {{interface_name.slice(1)}}Provider = '{{provider}}';
  readonly isConfigured: boolean;

  private token: string;
  private workspace?: string;

  constructor(config: {{provider.charAt(0).toUpperCase() + provider.slice(1)}}AdapterConfig) {
    this.token = config.token;
    this.workspace = config.workspace;
    this.isConfigured = !!this.token;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TODO: IMPLEMENTAR MÉTODOS
  // ═══════════════════════════════════════════════════════════════════════════

  validateConfiguration(): boolean {
    return this.isConfigured;
  }
}
\`\`\`

---

## 📊 Mapeamento de Campos

| Interface | {{provider}} API | Notas |
|-----------|-----------------|-------|
| TODO | TODO | Mapear campos |

---

## 🧪 Exemplos de Uso

\`\`\`typescript
// Via Factory (recomendado)
const manager = get{{interface_name.slice(1)}}();

// Direto (para testes)
const adapter = new {{provider.charAt(0).toUpperCase() + provider.slice(1)}}Adapter({
  token: 'xxx',
  workspace: 'xxx'
});
\`\`\`

---

**Versão**: 1.0.0
**Criado em**: {{data_atual}}
```

---

## 7. adapters/none.md (Fallback)

```markdown
# ⚪ NoProvider Adapter (Fallback)

## 🎯 Propósito

Adapter de fallback que permite operação offline quando nenhum provedor está configurado.

---

## 📋 Comportamento

- ✅ Permite que comandos executem sem falhar
- ⚠️ Exibe warnings quando operações são tentadas
- 📝 Pode gerar IDs locais para rastreamento
- ❌ Não persiste dados em serviços externos

---

## 🔧 Implementação

\`\`\`typescript
/** Adapter de fallback - modo offline. */
class NoProviderAdapter implements {{interface_name}} {
  readonly provider: {{interface_name.slice(1)}}Provider = 'none';
  readonly isConfigured: boolean = false;

  // TODO: Implementar cada método com:
  // 1. console.warn('⚠️ Operação X - modo offline');
  // 2. Retornar valor sensato ou throw com mensagem clara

  validateConfiguration(): boolean {
    console.warn('⚠️ Nenhum provedor configurado');
    return false;
  }
}
\`\`\`

---

## 📊 Comportamento por Operação

| Operação | Comportamento Offline |
|----------|----------------------|
| Leitura | Retorna array vazio ou null |
| Escrita | Warning + ID local |
| Atualização | Warning + throw/false |
| Deleção | Warning + false |

---

**Versão**: 1.0.0
**Criado em**: {{data_atual}}
```

---

## 8. Bloco do .env.example

```bash
# ═══════════════════════════════════════════════════════════════════════════
# {{interface_name.slice(1)}} Configuration
# ═══════════════════════════════════════════════════════════════════════════
{{env_prefix}}_PROVIDER=none  # {{providers.join(' | ')}} | none

{{#each providers}}
# {{this}}
{{../env_prefix}}_{{this.toUpperCase()}}_TOKEN=
{{../env_prefix}}_{{this.toUpperCase()}}_WORKSPACE=

{{/each}}
```

---

## 📚 Referências

- [SDAAL Pattern (conceitual)](../concepts/specification-driven-ai-abstraction-layer.md)
- [Task Manager Abstraction (referência real)](../concepts/task-manager-abstraction.md)
- [Comando /meta/create-abstraction](../../../.claude/commands/meta/create-abstraction.md)
- Template base: skill `common:templates:abstraction-template`
