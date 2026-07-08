---
name: pr-update
description: Atualizar PR existente com mudanças adicionais.
model: sonnet
allowed-tools: Bash(git *) Bash(cat .env*) Read Edit Write Grep
category: engineer
tags: [pr, update, git]
version: "3.0.0"
updated: "2025-11-24"
---

# 🔄 Engineer PR Update

Atualizar um Pull Request existente com mudanças adicionais. Este comando automatiza o processo completo de commit, push e documentação quando você já executou `/engineer/pr` mas fez mudanças subsequentes.

## 🎯 Funcionalidades

### Detecção Automática de Contexto
- Identifica automaticamente a branch de feature ativa
- Detecta mudanças pendentes (staged/unstaged/untracked)
- Valida se existe PR aberto para a branch atual
- Verifica se está na sessão de desenvolvimento correta

### Commit Inteligente e Descritivo
- Analisa arquivos modificados para categorizar mudanças
- Gera mensagem de commit contextual e descritiva
- Suporta diferentes tipos de mudanças (fix, feat, docs, refactor)
- Mantém histórico limpo com commits atômicos

### Sincronização Automática
- Push automático para branch do PR existente
- Atualização do Task Manager configurado com comentário detalhado (conforme `TASK_MANAGER_PROVIDER`)
- Validação de que PR foi atualizado com sucesso
- Timestamp e métricas das mudanças aplicadas

## 🚀 Como Usar

```bash
/engineer/pr-update
```

### Exemplos com Parâmetros Opcionais
```bash
/engineer/pr-update                           # Análise automática + commit inteligente
/engineer/pr-update --type fix               # Força tipo de commit específico
/engineer/pr-update --message "Custom msg"   # Mensagem personalizada
/engineer/pr-update --dry-run               # Preview sem executar
```

## 🤝 Integração com o Task Manager

Antes de operar com a task, carregue o `.env` e leia `TASK_MANAGER_PROVIDER` (`jira` | `clickup` | `asana` | `linear` | `none`) para rotear ao provider e adapter corretos. Se `none`, pule a atualização remota (apenas commit + push).

### Detecção de Task Ativa
- Lê task ID do arquivo `.claude/sessions/[slug]/context.md`
- Identifica PR existente através da task ou branch
- Valida se task está em status "in progress" com tag "under-review"

### Comentário Automático Padronizado

O comentário de atualização deve documentar: tipo do commit (fix | feat | refactor | docs | chore), hash do commit, arquivos modificados, linhas adicionadas/removidas e descrição das mudanças.

**Adicionar comentário via abstração agnóstica** (carregar `.env` → ler `TASK_MANAGER_PROVIDER`):

Chamar `taskManager.addComment(taskId, conteudo)` e `taskManager.updateStatus(taskId, status)` — o adapter resolve automaticamente formato (ADF / Unicode / Markdown), transporte (REST API por padrão; MCP opcional via `TASK_MANAGER_TRANSPORT=mcp`) e qual especialista acionar por provider. Referências: `docs/meta-specs/integrations.md` e `.claude/utils/task-manager/adapters/`.

- **`none`** → não persistir comentário remoto.

## ⚙️ Processo Automático

1. **Validação de Contexto**: Confirma branch de feature + sessão ativa
2. **Análise de Mudanças**: Categoriza arquivos modificados por tipo
3. **Geração de Commit**: Cria mensagem contextual e descritiva
4. **Staging Inteligente**: Adiciona apenas arquivos relevantes
5. **Commit & Push**: Executa commit + push para branch do PR
6. **Atualização do Task Manager**: Documenta mudanças com comentário formatado no provider configurado (`TASK_MANAGER_PROVIDER`)
7. **Validação Final**: Confirma que PR foi atualizado com sucesso

## 🧠 Detecção Inteligente de Tipos

### Tipos de Commit Auto-Detectados
- **fix**: Correções de bugs, patches, hotfixes
- **feat**: Novas funcionalidades, enhancements
- **docs**: Mudanças apenas em documentação
- **refactor**: Refatoração sem mudança de funcionalidade
- **style**: Formatação, linting, style fixes
- **test**: Adição ou correção de testes
- **chore**: Tarefas de manutenção, configuração

### Análise de Arquivos Modificados
```markdown
## Categorização Automática:
- `.claude/commands/` → "feat/fix: Comando updates"
- `docs/` → "docs: Documentation updates"
- `tests/` → "test: Test updates"
- `*.md` (session files) → "chore: Session documentation"
- Múltiplos tipos → "chore: Multiple updates"
```

## ⚠️ Resolução de Problemas

### Problema: "Não há PR ativo para esta branch"
**Solução**: Executar `/engineer/pr` primeiro para criar o PR inicial
```bash
# Se necessário, criar PR primeiro:
/engineer/pr
```

### Problema: "Nenhuma mudança detectada"
**Solução**: Verificar se há arquivos modificados
```bash
git status  # Confirmar mudanças pendentes
```

### Problema: "Branch não está sincronizada"
**Solução**: Sincronizar branch antes de atualizar
```bash
git pull origin [branch-name]  # Sincronizar primeiro
/engineer/pr-update           # Depois atualizar
```

### Problema: "Task do Task Manager não encontrada"
**Solução**: Verificar context.md da sessão ativa
- Confirmar task ID no arquivo `.claude/sessions/[slug]/context.md`
- Validar se task existe e está acessível

## 💡 Casos de Uso Comuns

### 1. Correções Pós-Review
```bash
# Após feedback do code review:
# 1. Fazer correções solicitadas
# 2. Executar:
/engineer/pr-update --type fix
```

### 2. Melhorias Adicionais
```bash
# Após pensar em melhorias:
# 1. Implementar enhancements
# 2. Executar:
/engineer/pr-update --type feat
```

### 3. Documentação Esquecida
```bash
# Após lembrar de documentar:
# 1. Atualizar docs
# 2. Executar:
/engineer/pr-update --type docs
```

### 4. Correções Arquiteturais
```bash
# Como no exemplo atual:
# 1. Implementar correções arquiteturais
# 2. Executar:
/engineer/pr-update --type fix --message "Correção arquitetural - Phase→Subtask sync"
```

## 🔗 Integração com Workflow

### Fluxo Padrão Completo
1. `/product/task` - Criar task no Task Manager configurado
2. `/engineer/start` - Iniciar desenvolvimento  
3. `/engineer/work` - Desenvolver features
4. `/engineer/pre-pr` - Validações finais
5. `/engineer/pr` - Criar Pull Request
6. **`/engineer/pr-update`** - Atualizar PR com mudanças adicionais (quantas vezes necessário)
7. Merge do PR → Auto-sync `/git/sync`

### Compatibilidade com Comandos Existentes
- ✅ Funciona após `/engineer/pr`
- ✅ Integra com `/engineer/work` progress tracking
- ✅ Compatível com `/git/sync` automático pós-merge
- ✅ Respeita mapeamento Phase→Subtask do context.md (formato canônico na [SSOT](../../../docs/knowledge-base/frameworks/gitflow-patterns.md#contrato-de-sessão-de-desenvolvimento))

---

**🎯 VALOR AGREGADO: Este comando elimina o processo manual de atualização de PRs, automatizando commit inteligente, push, e documentação no Task Manager configurado em uma única operação otimizada.**

## 📈 Benefícios

- ⚡ **Automação completa** do processo de update
- 🧠 **Commits inteligentes** com mensagens contextuais
- 📝 **Documentação automática** no Task Manager configurado
- 🔄 **Consistência** no workflow de PRs
- ⏰ **Economia de tempo** significativa
- 🎯 **Redução de erros** manuais
