---
name: create-agent-express
description: 'Criar agente de forma rápida e simplificada. Diferença vs /meta:create-agent: este é o caminho RÁPIDO (mínimo de prompts, sem descoberta de contexto profunda); o create-agent faz análise completa do ecossistema antes de criar.'
allowed-tools: Read Write
category: meta
tags: [agent, creation, quick]
version: "3.0.0"
updated: "2025-11-24"
---

# Comando Criar Agente

Você tem a tarefa de criar um novo sub-agente do Claude Code baseado nos requisitos do usuário. Siga esta abordagem sistemática para construir um agente bem estruturado.

## Requisitos do Usuário
<requirements>
#$ARGUMENTS
</requirements>

## Processo

### 1. Entender o Propósito do Agente
Primeiro, analise o que o usuário quer que este agente faça:
- Qual é a responsabilidade principal do agente?
- Que tarefas ele executará?
- O que torna este agente especializado?

### 2. Definir Configuração do Agente
Com base nos requisitos, determine:
- **Nome**: Crie um identificador em minúsculas, separado por hífens
- **Descrição**: Escreva uma descrição clara e concisa do propósito do agente
- **Ferramentas**: Selecione as ferramentas apropriadas do conjunto disponível

### 3. Seleção de Ferramentas
Liste todas as ferramentas disponíveis e pergunte ao usuário quais o sub-agente deve ter acesso:

Ferramentas disponíveis:
- **Operações de Arquivo**: Read, Write, Edit, Edit, NotebookRead, NotebookEdit
- **Pesquisa e Navegação**: Glob, Grep, LS
- **Execução**: Bash, Task
- **Web**: WebFetch, WebSearch
- **Desenvolvimento**: ExitPlanMode, TodoWrite
- **Ferramentas MCP**: ferramentas com prefixo `mcp__` para integrações **genéricas** (Playwright, etc.). ⚠️ Providers de task (ClickUp/Jira/Asana/Linear) e forge (GitHub) vão via adapter SDAAL (`taskManager.*`/`forge.*`), **NÃO** como `mcp__<provider>__*` direto — ver CLAUDE.md §Task Manager.

Apresente essas ferramentas organizadas por categoria e peça ao usuário para selecionar quais são apropriadas para o propósito do agente. Por padrão, use acesso mínimo às ferramentas por segurança.

### 4. Projetar o Prompt do Sistema
Crie um prompt do sistema detalhado que:
- Define claramente o papel e expertise do agente
- Fornece instruções passo a passo para completar suas tarefas
- Inclui qualquer restrição ou diretriz
- Especifica requisitos de formato de saída
- Contém exemplos se úteis

### 5. Criar o Arquivo do Agente
Gere o arquivo .md com:
```markdown
---
name: [nome-do-agente]
description: [descrição clara do propósito do agente]
tools: [lista separada por vírgulas das ferramentas selecionadas]
---

[Prompt do sistema detalhado com instruções claras]
```
IMPORTANTE: a extensão do arquivo deve ser .md, não .yaml

### 6. Implementação
- **Escolha a categoria** existente mais adequada ao escopo do agente: `development` | `product` | `compliance` | `git` | `meta` | `testing` | `review` | `research` | `deployment` (veja `.claude/agents/<categoria>/`).
- Crie o arquivo em `.claude/agents/[categoria]/[name-agent].md` — agentes vivem em **subpasta de categoria**, nunca no root de `agents/` (estrutura canônica; o `create-agent` completo também categoriza).
- Torne o prompt do sistema abrangente mas focado

### 7. Confirmar Criação
Após criar o agente, confirme que o arquivo foi criado com sucesso

## Melhores Práticas
- Mantenha agentes focados em uma única responsabilidade
- Escreva prompts do sistema claros e acionáveis
- Limite o acesso às ferramentas ao que é necessário
- Inclua exemplos em prompts complexos
- Considere tratamento de erros e casos extremos
- Torne os formatos de saída explícitos

## ⚠️ Passo final — sincronizar a SSOT

Após criar o agente, rodar **`/meta:inventory`** (regenera `inventory.md`; a Regra 8 do lint é HARD → criar sem regenerar deixa o repo em HARD-fail silencioso). Mecanismo: `common:prompts:inventory-sync-after-create`.

Agora, analise os requisitos e comece a criar o agente seguindo este processo.
