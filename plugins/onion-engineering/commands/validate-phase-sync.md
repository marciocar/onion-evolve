---
name: validate-phase-sync
description: Validar sincronização entre fases do plan.md e subtasks do Task Manager.
model: sonnet
allowed-tools: Read Grep Edit Bash(find .claude/sessions*) Bash(cat .env*)
category: engineer
tags: [validation, sync, task-manager]
version: "3.0.0"
updated: "2025-11-24"
---

# 🔄 Validate Phase-Subtask Sync

Validar e corrigir sincronização automática entre fases do plan.md e status das subtasks do Task Manager ativo. Este comando identifica discrepâncias e corrige status desatualizados.

## 🎯 Funcionalidades

### Validação Automática de Status
- Lê todas as fases do plan.md e identifica status atual (`[DONE]`, `[ACTIVE]`, `[TODO]`)
- Verifica status das subtasks correspondentes no Task Manager via Phase-Subtask Mapping
- Identifica discrepâncias entre plan.md e Task Manager
- Gera relatório de inconsistências encontradas

### Correção Automática de Status
- Atualiza automaticamente status das subtasks para refletir estado real das fases
- Adiciona comentários retroativos nas subtasks com timestamp de correção
- Documenta ações de correção realizadas
- Valida integridade do mapeamento Phase→Subtask

### Sistema de Alertas Proativo
- Alerta quando mapeamento Phase-Subtask está ausente ou incompleto
- Sugere criação de mapeamento quando detecta subtasks sem correlação
- Identifica fases órfãs (sem subtask correspondente)
- Reporta subtasks órfãs (sem fase correspondente)

## 🚀 Como Usar

```bash
/engineer/validate-phase-sync
```

### Exemplos de Casos de Uso
```bash
/engineer/validate-phase-sync                    # Validação geral da sessão ativa
/engineer/validate-phase-sync --fix-all         # Corrige todas inconsistências encontradas
/engineer/validate-phase-sync --report-only     # Apenas relatório, não aplica correções
```

## 🤝 Integração com o Task Manager

### Operações Automáticas
Executadas via adapter (REST API default; MCP opcional — ativado com `TASK_MANAGER_TRANSPORT=mcp`):
- **Leitura de Task**: Obtém a task com subtasks para estrutura completa
- **Update de Status**: Atualiza subtasks com o status correto
- **Comentários de Correção**: Cria comentário na subtask para documentar ajustes
- **Validação de Integridade**: Verifica se mapeamento está correto e completo

### Mapeamento Phase-Subtask
Lê o mapeamento do arquivo `.claude/sessions/[slug]/context.md` (formato canônico na [SSOT](../../../docs/knowledge-base/frameworks/gitflow-patterns.md#contrato-de-sessão-de-desenvolvimento)):
```markdown
## 📋 Phase-Subtask Mapping
- **Phase 1**: "Template Consolidation" → Subtask ID: [id-1]
- **Phase 2**: "Feature Commands" → Subtask ID: [id-2]
- **Phase 3**: "Release Commands" → Subtask ID: [id-3]
```

### Correções Aplicadas
Mapeie pelo token ASCII do `plan.md` (vocabulário em [worklog-protocol.md §6](../../../docs/knowledge-base/concepts/worklog-protocol.md)):
- Fases `[DONE]` → Subtask status "done"
- Fases `[ACTIVE]` → Subtask status "in progress"
- Fases `[TODO]` → Subtask status "to do"

> Se a fase atual (`[ACTIVE]`) divergir de `STATE.md.NEXT.phase`, o `STATE.md` é a fonte autoritativa — sinalize o drift antes de corrigir.

## ⚙️ Processo de Validação

1. **Detecta Sessão Ativa**: Identifica sessão em `.claude/sessions/`
2. **Lê Context.md**: Carrega mapeamento Phase-Subtask e task ID principal
3. **Analisa Plan.md**: Extrai status atual de todas as fases
4. **Consulta o Task Manager**: Obtém status atual das subtasks via adapter (REST API; MCP opcional)
5. **Identifica Discrepâncias**: Compara status plan.md vs Task Manager
6. **Aplica Correções**: Atualiza status das subtasks conforme necessário
7. **Documenta Ações**: Registra todas correções aplicadas

## ⚠️ Resolução de Problemas

### Problema: "Mapeamento Phase-Subtask não encontrado"
**Solução**: Verificar se context.md contém seção "Phase-Subtask Mapping"
```bash
# Execute se necessário:
/engineer/create-phase-mapping
```

### Problema: "Subtask não encontrada no Task Manager"
**Solução**: IDs do mapeamento podem estar incorretos
- Verificar IDs das subtasks no Task Manager ativo
- Atualizar mapeamento no context.md
- Executar validação novamente

### Problema: "Múltiplas fases para mesma subtask"
**Solução**: Revisar estrutura do projeto
- Uma subtask deve corresponder a uma fase específica
- Considerar quebrar fase complexa em múltiplas fases

## 💡 Integração com Workflow

### Uso Recomendado
- **Durante desenvolvimento**: Executar ao final de cada sessão de trabalho
- **Antes de PRs**: Validar sincronização completa antes de `/engineer/pr`
- **Após interrupções**: Garantir consistência após retomar trabalho
- **Debugging**: Identificar problemas de tracking de progresso

### Prevenção Automática
Este comando corrige o problema identificado onde `/engineer/work` não atualizava automaticamente os status das subtasks. Para projetos futuros:
1. `/engineer/start` deve criar o mapeamento automaticamente
2. `/engineer/work` deve usar este mapeamento para updates automáticos
3. Este comando serve como backup/validação do processo automático

---

**🎯 CRITICAL FIX: Este comando resolve a falha arquitetural onde fases completadas não atualizavam automaticamente o status das subtasks correspondentes, garantindo sincronização perfeita entre plan.md e Task Manager.**
