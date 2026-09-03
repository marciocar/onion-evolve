---
name: create-command
description: |
  Criação de novos comandos Claude Code com análise de contexto.
  Use para criar comandos que seguem padrões do Sistema Onion.
allowed-tools: Read Write Bash(ls *) Bash(grep *)

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

version: "3.1.0"
updated: "2026-07-10"

related_commands:
  - /meta/create-agent
  - /meta/create-agent-express
  - /meta/create-skill
  - /meta/create-knowledge-base
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

### Passo 3: Delegar Geração ao @command-creator-specialist

A expertise de estruturação (workflow, integração ao ecossistema, relacionamentos) vive no
especialista — este comando coleta o contexto e **delega**:

```
@command-creator-specialist

Comando: {{command_name}}
Categoria: {{category}}
Propósito: {{description}}
Template SSOT: common/templates/command-template.md
Contexto descoberto (Passo 1): [comandos/agentes relacionados, duplicação verificada]
```

O especialista gera o artefato completo: frontmatter, fluxo, output esperado e
relacionamentos (`related_commands`/`related_agents`) coerentes com o ecossistema.

> **Camadas deliberadas:** este comando é a camada fina (coleta + validação + escrita);
> a geração contextualizada é do especialista. Para o esqueleto cru sem análise, use
> diretamente o template SSOT `common/templates/command-template.md`.

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
VALID_CATEGORIES="engineer product git docs meta validate test development quick design"
if [[ ! " $VALID_CATEGORIES " =~ " {{category}} " ]]; then
  echo "❌ ERRO: Categoria '{{category}}' inválida!"
  echo "Válidas: $VALID_CATEGORIES"
  exit 1
fi
```

**Checklist de Validação:**
- [ ] Nome único (não existe em `.claude/commands/`)
- [ ] Nome em kebab-case válido
- [ ] Categoria válida (engineer|product|git|docs|meta|validate|test|development|quick|design)
- [ ] YAML header completo
- [ ] ≤ 500 linhas (recomendado; hard limit 800 — meta-spec `commands.md`)
- [ ] Seções obrigatórias (Objetivo, Fluxo, Output)

### Passo 5: Criar Arquivo

Escrever o artefato gerado pelo especialista com a tool **Write** em
`.claude/commands/{{category}}/{{command_name}}.md`.

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

- Limites de tamanho da meta-spec `commands.md`: 500 linhas recomendado, 800 hard
- Usar prompts modulares de `common/prompts/`
- Sempre validar duplicação antes de criar
- **Passo final — sincronizar a SSOT:** após criar, rodar **`/meta:inventory`** (regenera `inventory.md`; a Regra 8 do lint é HARD → criar sem regenerar deixa o repo em HARD-fail silencioso). Mecanismo: `common:prompts:inventory-sync-after-create`.
