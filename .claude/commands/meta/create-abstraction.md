---
name: create-abstraction
description: |
  Geração de camada de abstração seguindo o padrão SDAAL.
  Use para criar abstrações agnósticas de provedor (Task Manager, Notification, Storage).
allowed-tools: Read Write Bash(ls *) Bash(mkdir *) Bash(grep *)

parameters:
  - name: abstraction_name
    description: 'Nome da abstração em kebab-case (ex: notification-manager)'
    required: true
  - name: interface_name
    description: 'Nome da interface TypeScript (ex: INotificationManager)'
    required: false
  - name: providers
    description: 'Lista de provedores separados por vírgula (ex: slack,discord,email)'
    required: false
  - name: description
    description: Descrição breve do propósito da abstração
    required: false

category: meta
tags:
  - abstraction
  - sdaal
  - architecture
  - adapter-pattern

version: "1.0.0"
updated: "2025-11-25"

related_commands:
  - /meta/create-command
  - /meta/create-agent

related_agents:
  - onion

knowledge_base:
  - docs/knowledge-base/concepts/specification-driven-ai-abstraction-layer.md
  - docs/knowledge-base/concepts/task-manager-abstraction.md
  - docs/knowledge-base/patterns/sdaal-examples.md
---

# 🏗️ Criar Abstraction Layer (SDAAL)

Gerador de camadas de abstração seguindo o padrão **Specification-Driven AI Abstraction Layer**.

## 🎯 Objetivo

Criar estrutura completa de abstração agnóstica de provedor, permitindo trocar implementações sem modificar comandos ou agentes.

## 📚 Base Conceitual (NÃO duplicar aqui)

Este comando **orquestra** a criação. O conhecimento de fundo já existe nas KBs — leia-as antes de gerar:

- **Critério de elegibilidade** (o Passo 0 abaixo — *quando* algo vira SDAAL): [`onion-abstraction-doctrine.md`](../../../docs/knowledge-base/concepts/onion-abstraction-doctrine.md)
- **Padrão SDAAL** (fundamentos, arquitetura, design patterns, anti-patterns): [`specification-driven-ai-abstraction-layer.md`](../../../docs/knowledge-base/concepts/specification-driven-ai-abstraction-layer.md)
- **Implementação de referência real**: [`task-manager-abstraction.md`](../../../docs/knowledge-base/concepts/task-manager-abstraction.md) e `.claude/utils/task-manager/`
- **Templates completos de geração** (README, interface, types, detector, factory, adapters, none, .env): [`sdaal-examples.md`](../../../docs/knowledge-base/patterns/sdaal-examples.md)

## 🚦 Passo 0 (OBRIGATÓRIO) — Teste do Eixo: isto merece ser SDAAL?

**Não gere nada antes de responder.** O comando assumia que quem invoca já decidiu — e o resultado foi
abstração-por-declaração no core (auditoria 2026-07-17). Doutrina:
[`onion-abstraction-doctrine.md`](../../../docs/knowledge-base/concepts/onion-abstraction-doctrine.md).

Pergunte ao maestro e **exija as três**:

| # | Pergunta | Se **não** → **PARE** |
|---|---|---|
| **a** | Existem **≥2 implementações reais** (não prometidas) do mesmo contrato? | → **script** em `.claude/utils/` (whitepaper §13: provider único = overhead que não compensa) |
| **b** | Quem escolhe é o **ambiente/`.env`**, não o autor da chamada? | → **script** (a escolha é uma chamada, não configuração) |
| **c** | O consumidor **precisa ser cego** ao provider ativo? | → **script chamado direto** (cegueira sem necessidade é cerimônia) |

**Teste do gatilho:** 1 provider real + N prometidos = **script**. O 2º provider **real** é a graduação
(`gated-until-trigger`). "Ficaria simétrico com o task-manager" **não é gatilho**.

Se qualquer resposta for "não": **registre o desenho como gated** (com o gatilho nomeado) e encerre —
não gere a estrutura.

## 📐 Estrutura Gerada

```
.claude/utils/{{abstraction_name}}/
├── README.md           # Visão geral e uso rápido
├── interface.md        # Interface/Contrato principal
├── types.md            # Tipos de entrada e saída
├── factory.md          # Criação de instâncias
├── detector.md         # Detecção de contexto/provedor
└── adapters/
    ├── {{provider}}.md  # Um por provedor
    └── none.md          # Fallback (Null Object Pattern)
```

## ⚡ Fluxo de Execução

### Passo 1: Validação de Entrada

```bash
# Verificar se abstração já existe
if [ -d ".claude/utils/{{abstraction_name}}" ]; then
  echo "❌ ERRO: Abstração '{{abstraction_name}}' já existe!"
  ls -la .claude/utils/{{abstraction_name}}/
  exit 1
fi

# Validar formato kebab-case
if [[ ! "{{abstraction_name}}" =~ ^[a-z][a-z0-9]*(-[a-z0-9]+)*$ ]]; then
  echo "❌ ERRO: Nome deve ser kebab-case (ex: notification-manager)"
  exit 1
fi
```

**Checklist de Validação:**
- [ ] Nome único (não existe em `.claude/utils/`)
- [ ] Nome em kebab-case válido
- [ ] Pelo menos 1 provedor definido (ou usar fallback only)

### Passo 2: Determinar Valores

Derivar automaticamente os placeholders usados pelos templates:

| Input | Derivação |
|-------|-----------|
| `{{abstraction_name}}` | `notification-manager` (input) |
| `{{interface_name}}` | `INotificationManager` (auto: `I` + PascalCase) |
| `{{providers}}` | `slack,discord,email` ou `none` se vazio |
| `{{env_prefix}}` | `NOTIFICATION_MANAGER` (auto: UPPER_SNAKE) |

```typescript
// Derivar interface_name se não fornecido
const interfaceName = "{{interface_name}}" ||
  "I" + "{{abstraction_name}}"
    .split('-')
    .map(w => w.charAt(0).toUpperCase() + w.slice(1))
    .join('');

// Derivar env_prefix
const envPrefix = "{{abstraction_name}}".toUpperCase().replace(/-/g, '_');
```

> Convenção: `interface_name.slice(1)` remove o prefixo `I` (ex.: `INotificationManager` → `NotificationManager`), usado em provider types e funções factory `get<Nome>()`.

### Passo 3: Criar Estrutura de Diretórios

```bash
mkdir -p .claude/utils/{{abstraction_name}}/adapters
```

### Passo 4: Gerar Arquivos a partir dos Templates

Para cada arquivo abaixo, **use o template correspondente** em [`sdaal-examples.md`](../../../docs/knowledge-base/patterns/sdaal-examples.md), substituindo os placeholders pelos valores derivados no Passo 2:

| Arquivo gerado | Seção do template em `sdaal-examples.md` |
|----------------|-------------------------------------------|
| `README.md` | 1. README.md |
| `interface.md` | 2. interface.md |
| `types.md` | 3. types.md |
| `detector.md` | 4. detector.md |
| `factory.md` | 5. factory.md |
| `adapters/{{provider}}.md` (um por provedor) | 6. adapters/{{provider}}.md |
| `adapters/none.md` | 7. adapters/none.md |

**Regras ao gerar:**
- Cada provedor em `{{providers}}` gera um adapter em estado **stub** (métodos com `TODO`).
- O `none.md` é sempre gerado e é **funcional** (degradação graciosa).
- Manter emojis nos headers e separadores ASCII (otimização para parsing por IA — ver KB conceitual).
- Cada arquivo deve ter < 400 linhas.

### Passo 5: Atualizar .env.example

Acrescentar ao `.env.example` o bloco de configuração (template seção 8 em [`sdaal-examples.md`](../../../docs/knowledge-base/patterns/sdaal-examples.md)):

```bash
{{env_prefix}}_PROVIDER=none  # {{providers.join(' | ')}} | none
# + uma seção <PROVIDER>_TOKEN / _WORKSPACE por provedor
```

## 🧪 Exemplos de Invocação

```bash
# Abstração de notificações com 3 provedores
/meta/create-abstraction notification-manager --providers slack,discord,email

# Abstração de storage, interface explícita
/meta/create-abstraction file-storage --interface_name IFileStorage --providers s3,gcs

# Apenas fallback (sem provedor externo)
/meta/create-abstraction local-cache
```

## 📤 Output Esperado

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ ABSTRACTION LAYER CRIADA (SDAAL)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📁 Estrutura:
.claude/utils/{{abstraction_name}}/
├── README.md           ✅
├── interface.md        ✅
├── types.md            ✅
├── factory.md          ✅
├── detector.md         ✅
└── adapters/
    ├── {{provider}}.md  📝 (stub)  ← um por provedor
    └── none.md          ✅

📋 Detalhes:
∟ Interface: {{interface_name}}
∟ Provedores: {{providers.join(', ')}}
∟ Env Prefix: {{env_prefix}}_PROVIDER

🔧 Próximos Passos:
1. Definir métodos em interface.md
2. Adicionar tipos em types.md
3. Implementar adapters em adapters/
4. Configurar .env com {{env_prefix}}_PROVIDER

📚 Documentação:
∟ Pattern: docs/knowledge-base/concepts/specification-driven-ai-abstraction-layer.md
∟ Templates: docs/knowledge-base/patterns/sdaal-examples.md
∟ Exemplo real: .claude/utils/task-manager/

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## 🔗 Referências

- [SDAAL Pattern](../../../docs/knowledge-base/concepts/specification-driven-ai-abstraction-layer.md)
- [Templates SDAAL](../../../docs/knowledge-base/patterns/sdaal-examples.md)
- [Task Manager (referência)](../../../.claude/utils/task-manager/)
- Agente: @onion

## ⚠️ Notas

- Cada arquivo deve ter < 400 linhas.
- Interface deve ser extensível (Open/Closed).
- Sempre incluir `NoProviderAdapter` (fallback funcional).
- Documentar variáveis de ambiente necessárias.
- Usar emojis e separadores ASCII para facilitar parsing por IA.
