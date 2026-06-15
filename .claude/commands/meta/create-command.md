---
name: create-command
description: |
  Criação de novos comandos Claude Code com análise de contexto.
  Use para criar comandos que seguem padrões do Sistema Onion.
model: sonnet
allowed-tools: Read Write Bash(ls *) Bash(grep *) Bash(find *)

parameters:
  - name: command_name
    description: Nome do comando em kebab-case
    required: true
  - name: category
    description: Categoria (engineer/product/git/docs/meta)
    required: false
  - name: description
    description: Descrição do que o comando faz
    required: false

category: meta
tags:
  - command-creation
  - meta
  - automation

version: "3.0.0"
updated: "2025-11-24"

related_commands:
  - /meta/create-agent
  - /meta/create-agent-express
  - /meta/create-abstraction

related_agents:
  - command-creator-specialist
  - onion
---

# 📝 Criar Comando Claude Code

Facilitador para criação de comandos seguindo padrões Onion v3.0.

## 🎯 Objetivo

Criar comandos que se integram ao ecossistema existente.

## ⚡ Fluxo de Execução

### Passo 1: Análise de Contexto

```bash
# Listar comandos existentes
ls .claude/commands/*/*.md | wc -l

# Verificar categoria existe
ls .claude/commands/{{category}}/ 2>/dev/null

# Verificar duplicação
grep -l "name: {{command_name}}" .claude/commands/**/*.md
```

### Passo 2: Determinar Categoria

SE `{{category}}` fornecido → usar diretamente
SENÃO → inferir do propósito:

| Propósito | Categoria |
|-----------|-----------|
| Desenvolvimento, código | `engineer` |
| Tasks, specs, features | `product` |
| Git, branches, PRs | `git` |
| Documentação | `docs` |
| Comandos, agentes | `meta` |
| Validações | `validate` |

### Passo 3: Gerar Estrutura

Usar template de `common/templates/command-template.md`:

```yaml
---
name: {{command_name}}
description: |
  [Descrição em 2 linhas]
  Use para [caso de uso principal].
model: sonnet

parameters:
  - name: param1
    description: [descrição]
    required: [true/false]

category: {{category}}
tags:
  - [tag1]
  - [tag2]

version: "3.0.0"
updated: "[data atual]"

related_commands:
  - /category/comando

related_agents:
  - agente-relacionado
---

# [Título do Comando]

[Descrição breve]

## 🎯 Objetivo

[O que este comando faz]

## ⚡ Fluxo de Execução

### Passo 1: [Nome]
[Instruções]

### Passo 2: [Nome]
[Instruções]

## 📤 Output Esperado

[Formato de saída]

## 🔗 Referências

- [Referências relevantes]

## ⚠️ Notas

- [Notas importantes]
```

### Passo 4: Validações Obrigatórias

**CRÍTICO**: Executar TODAS as validações antes de criar:

```bash
# 1. DUPLICAÇÃO - Verificar nome único
if grep -r "^name: {{command_name}}$" .claude/commands/ 2>/dev/null; then
  echo "❌ ERRO: Comando '{{command_name}}' já existe!"
  exit 1
fi

# 2. FORMATO - Verificar kebab-case
if [[ ! "{{command_name}}" =~ ^[a-z][a-z0-9]*(-[a-z0-9]+)*$ ]]; then
  echo "❌ ERRO: Nome deve ser kebab-case (ex: my-command)"
  exit 1
fi

# 3. CATEGORIA - Verificar categoria válida
VALID_CATEGORIES="engineer product git docs meta validate test development quick"
if [[ ! " $VALID_CATEGORIES " =~ " {{category}} " ]]; then
  echo "❌ ERRO: Categoria '{{category}}' inválida!"
  echo "Válidas: $VALID_CATEGORIES"
  exit 1
fi
```

**Checklist de Validação:**
- [ ] Nome único (não existe em `.claude/commands/`)
- [ ] Nome em kebab-case válido
- [ ] Categoria válida (engineer|product|git|docs|meta|validate|test|development|quick)
- [ ] YAML header completo
- [ ] < 400 linhas
- [ ] Seções obrigatórias (Objetivo, Fluxo, Output)

### Passo 5: Criar Arquivo

```bash
write .claude/commands/{{category}}/{{command_name}}.md
```

## 📤 Output Esperado

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ COMANDO CRIADO
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📁 Arquivo: .claude/commands/{{category}}/{{command_name}}.md

📋 Detalhes:
∟ Nome: {{command_name}}
∟ Categoria: {{category}}
∟ Linhas: ~150

🚀 Para usar: /{{category}}/{{command_name}}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## 🔗 Referências

- Template: `common/templates/command-template.md`
- Agente: @command-creator-specialist

## ⚠️ Notas

- Máximo 400 linhas por comando
- Usar prompts modulares de `common/prompts/`
- Sempre validar duplicação antes de criar
