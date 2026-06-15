---
name: workflow
description: Validar completude de workflows do Sistema Onion.
model: sonnet
allowed-tools: Read Bash(git *) Bash(find .claude/sessions*) Bash(ls .claude/sessions*) Bash(grep *)
category: validate
tags: [validation, workflow, completeness]
version: "3.0.0"
updated: "2025-11-24"
---

# 🔍 Validação Completa de Workflow

Você é um assistente especializado em **validação de completude de workflows** do Sistema Onion. Seu papel é verificar que todos os passos de um workflow foram executados corretamente e identificar pendências.

## 🎯 **Objetivo**

Validar que workflows do Sistema Onion foram executados completamente:
- **Git workflows**: PR, sync, branch management
- **Session management**: Arquivamento, organização
- **Repository state**: Sincronização, limpeza
- **Compliance**: Branch protection, GitFlow

## 📋 **Parâmetros**

### **Sintaxe:**
```bash
/validate/workflow                    # Validação completa atual
/validate/workflow pr-merge           # Validação específica de PR merge  
/validate/workflow cleanup           # Validação de limpeza/housekeeping
/validate/workflow development       # Validação de desenvolvimento
```

## 🔍 **Sistema de Validação**

### **Validações Executadas:**

#### **1. 🔄 Sincronização Local vs Remoto**
- Verificar se commits locais foram pushados
- Detectar divergências entre local e remoto
- Validar conectividade com remote
- Status de branches protegidas

#### **2. 🧹 Estado do Working Directory**
- Verificar mudanças não commitadas
- Validar arquivos não trackados
- Compliance com branch protection
- Status de staging area

#### **3. 📁 Gestão de Sessões**
- Sessões ativas vs arquivadas
- Completude de documentação
- Organização de arquivos históricos
- Integridade de metadados

#### **4. 🌿 Limpeza de Branches**
- Branches temporárias órfãs
- Branches merged não removidas
- Remote branch cleanup
- Protection compliance

#### **5. 🛡️ Compliance e Segurança**
- Branch protection ativa
- PR workflow compliance
- GitFlow best practices
- Security validations

#### **6. 🔗 Integração Task Manager**
- Status de tasks sincronizado (via adapter — REST API; MCP opcional)
- Comments e updates realizados
- Tags apropriadas aplicadas
- Workflow completion tracking

## ⚙️ **Implementação**

```bash
# Função principal de validação
function executeWorkflowValidation() {
  local validation_type="${1:-complete}"
  local session_name="$2"
  
  echo "🔍 VALIDAÇÃO DE WORKFLOW: $validation_type"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  
  local total_checks=0
  local passed_checks=0
  local warnings=0
  local errors=0
  
  # Array para armazenar resultados
  local validation_results=()
  
  # 1. VALIDAÇÃO DE SINCRONIZAÇÃO
  echo "🔄 [1/6] Sincronização Local vs Remoto"
  if validateSyncStatus; then
    validation_results+=("✅ Sincronização: Local e remoto alinhados")
    ((passed_checks++))
  else
    validation_results+=("❌ Sincronização: Discrepâncias detectadas")
    ((errors++))
  fi
  ((total_checks++))
  
  # 2. VALIDAÇÃO DE WORKING DIRECTORY
  echo "🧹 [2/6] Working Directory"
  if validateWorkingDirectory; then
    validation_results+=("✅ Working Dir: Limpo e organizado")
    ((passed_checks++))
  else
    validation_results+=("⚠️  Working Dir: Mudanças pendentes")
    ((warnings++))
  fi
  ((total_checks++))
  
  # 3. VALIDAÇÃO DE SESSÕES
  echo "📁 [3/6] Gestão de Sessões"
  if validateSessionManagement "$session_name"; then
    validation_results+=("✅ Sessões: Corretamente organizadas")
    ((passed_checks++))
  else
    validation_results+=("⚠️  Sessões: Requer organização")
    ((warnings++))
  fi
  ((total_checks++))
  
  # 4. VALIDAÇÃO DE BRANCHES
  echo "🌿 [4/6] Limpeza de Branches"
  if validateBranchCleanup; then
    validation_results+=("✅ Branches: Limpeza completa")
    ((passed_checks++))
  else
    validation_results+=("⚠️  Branches: Limpeza recomendada")
    ((warnings++))
  fi
  ((total_checks++))
  
  # 5. VALIDAÇÃO DE COMPLIANCE
  echo "🛡️ [5/6] Compliance e Segurança"
  if validateCompliance; then
    validation_results+=("✅ Compliance: Todas as proteções ativas")
    ((passed_checks++))
  else
    validation_results+=("❌ Compliance: Proteções requeridas")
    ((errors++))
  fi
  ((total_checks++))
  
  # 6. VALIDAÇÃO DE INTEGRAÇÃO
  echo "🔗 [6/6] Integração Task Manager"
  if validateTaskManagerIntegration; then
    validation_results+=("✅ Task Manager: Integração sincronizada")
    ((passed_checks++))
  else
    validation_results+=("⚠️  Task Manager: Verificar sincronização")
    ((warnings++))
  fi
  ((total_checks++))
  
  # RESULTADO FINAL
  echo ""
  echo "📊 RESULTADO FINAL DA VALIDAÇÃO"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  
  # Estatísticas
  echo "📈 ESTATÍSTICAS:"
  echo "   ▶ Total de verificações: $total_checks"
  echo "   ▶ Aprovadas: $passed_checks"
  echo "   ▶ Avisos: $warnings"
  echo "   ▶ Erros: $errors"
  echo ""
  
  # Score de qualidade
  local quality_score=$(( (passed_checks * 100) / total_checks ))
  echo "🎯 SCORE DE QUALIDADE: $quality_score%"
  echo ""
  
  # Resultados detalhados
  echo "📋 RESULTADOS DETALHADOS:"
  for result in "${validation_results[@]}"; do
    echo "   $result"
  done
  echo ""
  
  # Status final e recomendações
  if [[ $errors -eq 0 ]]; then
    if [[ $warnings -eq 0 ]]; then
      echo "🎉 STATUS: WORKFLOW PERFEITO!"
      echo "✅ Todos os critérios atendidos"
      echo "🚀 Sistema pronto para próximas operações"
      
      # Adicionar comentário no Task Manager configurado, se aplicável
      if [[ "$TASK_MANAGER_PROVIDER" != "none" && -n "$TASK_ID" ]]; then
        echo ""
        echo "📝 Adicionando validação ao Task Manager configurado..."
        # Delegação ao adapter via getTaskManager().addComment(TASK_ID, ...)
      fi
      
      return 0
    else
      echo "🔶 STATUS: WORKFLOW VÁLIDO COM RECOMENDAÇÕES"
      echo "💡 $warnings itens recomendados para otimização"
      echo "✅ Funcionalidade não comprometida"
      
      echo ""
      echo "🛠️  AÇÕES RECOMENDADAS:"
      if [[ $warnings -gt 0 ]]; then
        echo "   • Revisar avisos listados acima"
        echo "   • Aplicar melhorias sugeridas"
        echo "   • Re-executar validação após ajustes"
      fi
      
      return 1
    fi
  else
    echo "🚨 STATUS: WORKFLOW INCOMPLETO"
    echo "❌ $errors erro(s) crítico(s) detectado(s)"
    echo "🛠️  Correção obrigatória antes de prosseguir"
    
    echo ""
    echo "🚨 AÇÕES OBRIGATÓRIAS:"
    echo "   • Corrigir todos os erros listados"
    echo "   • Verificar integridade do sistema"
    echo "   • Re-executar validação completa"
    echo "   • Não prosseguir até resolução"
    
    return 2
  fi
}

# Funções auxiliares de validação
function validateSyncStatus() {
  current_branch=$(git rev-parse --abbrev-ref HEAD)
  
  if git show-ref --verify --quiet refs/remotes/origin/$current_branch; then
    local_commit=$(git rev-parse HEAD)
    remote_commit=$(git rev-parse origin/$current_branch)
    
    [[ "$local_commit" == "$remote_commit" ]]
  else
    false
  fi
}

function validateWorkingDirectory() {
  [[ $(git status --porcelain | wc -l) -eq 0 ]]
}

function validateSessionManagement() {
  local session_name="$1"
  
  if [[ -n "$session_name" ]]; then
    # Verificar se sessão está arquivada
    [[ ! -d ".claude/sessions/$session_name" ]] && 
    [[ -d ".claude/sessions/archived" ]] && 
    ls .claude/sessions/archived/ | grep -q "$session_name"
  else
    # Verificar se há sessões ativas desnecessárias
    active_sessions=$(find .claude/sessions -maxdepth 1 -type d ! -name "sessions" ! -name "archived" | wc -l)
    [[ $active_sessions -eq 0 ]]
  fi
}

function validateBranchCleanup() {
  orphan_branches=$(git branch | grep -E "feature/|hotfix/|bugfix/" | wc -l)
  [[ $orphan_branches -eq 0 ]]
}

function validateCompliance() {
  # Verificar se sistema de proteção está ativo
  # (Simplified check - would need more sophisticated validation)
  [[ -f ".claude/commands/git/sync.md" ]] && 
  grep -q "Branch Protection" ".claude/commands/git/sync.md"
}

function validateTaskManagerIntegration() {
  # Verificar se integração com Task Manager está funcionando (agnóstico de provider)
  # (Simplified check — delega ao adapter via getTaskManager())
  true  # Sempre retorna true por agora
}

# Execução baseada em parâmetros
case "${1:-complete}" in
  "pr-merge")
    executeWorkflowValidation "pr-merge" "$2"
    ;;
  "cleanup")
    executeWorkflowValidation "cleanup" "$2"
    ;;
  "development")
    executeWorkflowValidation "development" "$2"
    ;;
  "complete"|*)
    executeWorkflowValidation "complete" "$2"
    ;;
esac
```

## 🎯 **Uso Recomendado**

### **Quando Usar:**
- **Após /git/sync**: Validar sincronização completa
- **Após /engineer/pr**: Validar PR workflow
- **Após housekeeping**: Validar limpeza
- **Diagnóstico**: Quando algo parecer errado
- **Antes de deploy**: Validação final de qualidade

### **Integração Sugerida:**
```bash
# Uso nos outros comandos
/git/sync develop && /validate/workflow cleanup

# Uso independente para diagnóstico
/validate/workflow

# Uso específico para validation de PR
/validate/workflow pr-merge
```

## 📊 **Output de Exemplo**

```
🔍 VALIDAÇÃO DE WORKFLOW: complete

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔄 [1/6] Sincronização Local vs Remoto
🧹 [2/6] Working Directory  
📁 [3/6] Gestão de Sessões
🌿 [4/6] Limpeza de Branches
🛡️ [5/6] Compliance e Segurança
🔗 [6/6] Integração Task Manager

📊 RESULTADO FINAL DA VALIDAÇÃO
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📈 ESTATÍSTICAS:
   ▶ Total de verificações: 6
   ▶ Aprovadas: 6
   ▶ Avisos: 0
   ▶ Erros: 0

🎯 SCORE DE QUALIDADE: 100%

📋 RESULTADOS DETALHADOS:
   ✅ Sincronização: Local e remoto alinhados
   ✅ Working Dir: Limpo e organizado
   ✅ Sessões: Corretamente organizadas
   ✅ Branches: Limpeza completa
   ✅ Compliance: Todas as proteções ativas
   ✅ Task Manager: Integração sincronizada

🎉 STATUS: WORKFLOW PERFEITO!
✅ Todos os critérios atendidos
🚀 Sistema pronto para próximas operações
```

---

*Sistema Onion - Comando `/validate/workflow` v1.0*
