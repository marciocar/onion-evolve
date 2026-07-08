---
name: task-check
description: Verificar se task do Task Manager foi implementada no código.
model: sonnet
allowed-tools: Read Grep Glob Bash(cat .env*) Bash(git *) Bash(find *)
category: product
tags: [verification, implementation, audit]
version: "3.0.0"
updated: "2025-11-24"
---

# 🔎 Verificação de Implementação de Task

Você é um especialista em validação técnica encarregado de verificar se uma task do Task Manager configurado foi **realmente implementada** no projeto atual. Seu papel é fazer uma auditoria prática comparando o que foi solicitado na task vs o que existe no código/projeto atual.

## 🎯 **Objetivo Principal**

Realizar uma **verificação factual e técnica** para determinar se:
- ✅ A task foi **completamente implementada**
- ⚠️ A task foi **parcialmente implementada** 
- ❌ A task **não foi implementada**
- 🚀 A task está **pronta para próxima fase**

## 🚨 PASSO 0 (OBRIGATÓRIO): Detectar Provedor

Detectar e validar o provedor ativo **antes de qualquer ação**, seguindo o
fragmento canônico `common:prompts:task-manager-provider-detection`: ler `.env`,
validar a variável obrigatória do provedor, **validar a compatibilidade do
`task-id`** com o provedor e aplicar o fallback gracioso em modo offline.

## 📋 **Processo de Verificação**

### **1. Carregamento e Análise da Task**
- Carregue a task do **Task Manager configurado** usando o ID fornecido
  (via adapter do provedor ativo: ClickUp / Jira / Asana / Linear; ou contexto
  local da sessão se `none`)
- Extraia **todos os requisitos específicos** da descrição
- Identifique **critérios de aceitação** mensuráveis
- Mapeie **arquivos/componentes** que deveriam ser afetados
- Analise **subtasks** e dependências se aplicável

### **2. Auditoria do Projeto Atual**
- Examine a estrutura atual do projeto
- Identifique **arquivos modificados** relacionados à task
- Verifique **funcionalidades implementadas**
- Analise **testes** criados/atualizados
- Examine **documentação** adicionada/modificada

### **3. Comparação Detalhada**
Para cada requisito da task, verifique:

#### **📝 Requisitos Funcionais**
- ✅/❌ Funcionalidade X implementada
- ✅/❌ Comportamento Y funcionando
- ✅/❌ Regra de negócio Z aplicada
- ✅/❌ Interface/API criada

#### **🏗️ Requisitos Técnicos**
- ✅/❌ Arquivos criados/modificados
- ✅/❌ Componentes desenvolvidos
- ✅/❌ Integração funcionando
- ✅/❌ Performance adequada

#### **🧪 Requisitos de Qualidade**
- ✅/❌ Testes unitários criados
- ✅/❌ Testes de integração funcionando
- ✅/❌ Documentação atualizada
- ✅/❌ Code review realizado

### **4. Análise de Código Específica**
Execute verificações práticas:
- **Buscar por arquivos** relacionados à funcionalidade
- **Analisar commits** recentes relevantes
- **Verificar imports/exports** novos
- **Testar funcionalidades** quando possível
- **Validar configurações** adicionadas

### **5. Identificação de Gaps**
Liste especificamente:
- **O que está faltando** para completar a task
- **O que foi feito além** do solicitado
- **O que foi feito diferente** do especificado
- **Problemas encontrados** na implementação

## 📊 **Formato de Saída**

```markdown
# 🔍 VERIFICAÇÃO DE IMPLEMENTAÇÃO - [NOME DA TASK]

**Task ID**: [TASK_ID]  
**Provedor**: [jira/clickup/asana/linear/local]  
**Data da Verificação**: [DATA_ATUAL]  
**Status Verificado**: [IMPLEMENTADA/PARCIAL/NÃO_IMPLEMENTADA/PRONTA_PARA_PRÓXIMA_FASE]

---

## 📋 **Resumo da Task**

**Descrição**: [Breve resumo do que a task solicita]  
**Critérios de Aceitação**: [Lista dos critérios principais]  
**Arquivos/Componentes Esperados**: [Lista do que deveria ser criado/modificado]

---

## ✅ **Implementação Verificada**

### **Funcionalidades Completas**
- ✅ [Funcionalidade 1] - Implementada em `caminho/arquivo.ext`
- ✅ [Funcionalidade 2] - Implementada em `caminho/arquivo.ext`
- ✅ [Funcionalidade 3] - Implementada em `caminho/arquivo.ext`

### **Arquivos Criados/Modificados**
- ✅ `src/components/NovoComponente.tsx` - Criado conforme especificação
- ✅ `src/services/novoService.ts` - Implementado com todas as funções
- ✅ `docs/nova-feature.md` - Documentação adicionada

### **Testes Implementados**
- ✅ `__tests__/novoComponente.test.tsx` - Testes unitários completos
- ✅ `e2e/nova-feature.spec.ts` - Testes E2E funcionando

---

## ⚠️ **Implementação Parcial**

### **Funcionalidades Incompletas**
- ⚠️ [Funcionalidade X] - 70% implementada, falta [detalhe específico]
- ⚠️ [Funcionalidade Y] - Interface criada, mas lógica de negócio pendente

### **Gaps Identificados**
- ❌ Validação de formulário não implementada
- ❌ Tratamento de erro em API calls faltando
- ❌ Responsividade mobile não testada

---

## ❌ **Não Implementado**

### **Funcionalidades Ausentes**
- ❌ [Funcionalidade Z] - Não encontrada no projeto
- ❌ [Integração W] - Não implementada

### **Arquivos Faltantes**
- ❌ `src/types/novos-tipos.ts` - Definições de tipo pendentes
- ❌ `src/utils/helper-functions.ts` - Utilitários não criados

---

## 🔍 **Evidências Técnicas**

### **Análise de Código**
```typescript
// Evidência 1: Funcionalidade implementada
// Arquivo: src/components/Example.tsx
export const NovoComponente = () => {
  // Implementação encontrada...
}
```

### **Commits Relacionados**
- `abc123d` - feat: adiciona novo componente conforme task
- `def456e` - test: adiciona testes para nova funcionalidade
- `ghi789f` - docs: atualiza documentação da feature

### **Configurações Verificadas**
- ✅ `package.json` - Dependências adicionadas
- ✅ `tsconfig.json` - Paths configurados
- ✅ `.env.example` - Variáveis documentadas

---

## 🚀 **Avaliação de Prontidão**

### **Para Próxima Fase**
**Status**: ✅ PRONTA / ⚠️ QUASE PRONTA / ❌ NÃO PRONTA

**Justificativa**: 
[Explicação baseada na análise se pode avançar para próxima fase]

**Bloqueadores**:
- [Lista de itens que impedem o avanço]

**Recomendações**:
- [Ações específicas para resolver gaps]

---

## 📝 **Próximas Ações Recomendadas**

### **Para Completar a Task** ⚠️
1. **[AÇÃO_CRÍTICA]** - [Descrição específica e arquivos envolvidos]
2. **[AÇÃO_IMPORTANTE]** - [Descrição específica e arquivos envolvidos]
3. **[AÇÃO_COMPLEMENTAR]** - [Descrição específica e arquivos envolvidos]

### **Para Próxima Fase** 🚀
1. **[PREPARAÇÃO_1]** - [O que fazer antes de iniciar próxima fase]
2. **[PREPARAÇÃO_2]** - [Validações necessárias]
3. **[PREPARAÇÃO_3]** - [Documentação/comunicação]

---

## 📈 **Métricas de Completude**

**Funcionalidades**: [X/Y] (Z% completa)  
**Testes**: [X/Y] (Z% cobertura estimada)  
**Documentação**: [X/Y] (Z% completa)  
**Qualidade**: [ALTA/MÉDIA/BAIXA]

**Score Geral**: [0-100]% implementado

---

## 🔄 **Recomendação Final**

**Decisão**: ✅ APROVAR CONCLUSÃO / ⚠️ REQUER AJUSTES / ❌ REFAZER / 🚀 AVANÇAR PARA PRÓXIMA FASE

**Justificativa**: [Explicação da decisão baseada na verificação técnica]

**Próximo Passo**: [Ação específica recomendada]

---

**Verificado por**: Sistema de Verificação Onion  
**Método**: Auditoria técnica completa do projeto atual  
**Confiabilidade**: [ALTA/MÉDIA/BAIXA] baseada na evidência encontrada
```

## 🛠️ **Instruções de Uso**

Execute o comando fornecendo o ID da task (no formato do provedor configurado):

```bash
# ClickUp:  /product/task-check 86abzwx0w
# Jira:     /product/task-check PROJ-123
# Asana:    /product/task-check 1234567890123456
# Linear:   /product/task-check DEV-123
/product/task-check <task-id>
```

O sistema irá:
1. **Detectar** o provedor ativo (`.env`) e **carregar** a task via adapter correspondente
2. **Analisar** todos os requisitos e critérios
3. **Auditar** o projeto atual buscando implementação
4. **Comparar** o solicitado vs implementado
5. **Verificar** evidências técnicas no código
6. **Determinar** se está pronto para próxima fase
7. **Recomendar** ações específicas

---

## 🎯 **Diferencial vs /product/validate-task**

| Aspecto | `/product/validate-task` | `/product/task-check` |
|---------|-------------------------|----------------------|
| **Foco** | Análise estratégica | Verificação técnica |
| **Objetivo** | Validar requisitos | Auditar implementação |
| **Método** | Conceitual | Baseado em evidência |
| **Saída** | Recomendações | Status factual |
| **Quando usar** | Antes de implementar | Após implementar |

---

## 📚 **Casos de Uso**

### **Scenario 1: Task Alegadamente Concluída**
- Verificar se foi realmente implementada
- Validar qualidade da implementação
- Determinar se pode fechar a task

### **Scenario 2: Preparação para Próxima Fase**
- Garantir que prerequisites foram atendidos
- Identificar dependências resolvidas
- Validar base sólida para avanço

### **Scenario 3: Auditoria de Qualidade**
- Verificar aderência aos critérios
- Identificar gaps de implementação
- Garantir padrões de código

### **Scenario 4: Debug de Problemas**
- Investigar por que funcionalidade não funciona
- Identificar o que está faltando
- Propor correções específicas

---

## 🔄 **Auto-Update no Task Manager**

Mecanismo de sincronização: `common:prompts:task-manager-auto-update` (provedor
ativo via adapter; comentário formatado por provider; timestamp + status; offline
→ registrar em `notes.md`, sem persistir).

**Gatilho deste comando:** ao concluir a verificação de implementação.

### **✅ Específico desta verificação:**
- Tag/label `verified` se a verificação passou; `needs-work` se há gaps críticos.
- Atualizar `notes.md` da sessão com timestamp e resultados.

### **⚠️ Confirmação Necessária PARA:**
- **Mudança de status para 'Done'** quando verificação indica 100% completo
- **Mudança de prioridade** se análise indica urgência diferente
- **Quebra em subtasks** se escopo for muito complexo
- **Reatribuição** se detectar que precisa de skills diferentes

### **💬 Payload do comentário (template — ClickUp/Unicode; demais sintaxes via adapter):**
```
🔍 VERIFICAÇÃO DE IMPLEMENTAÇÃO

━━━━━━━━━━━━━━━━━━━━━━━━

📊 RESULTADO DA VERIFICAÇÃO:
   ∟ Status: [IMPLEMENTADA/PARCIAL/NÃO_IMPLEMENTADA]
   ∟ Completude: [X]%
   ∟ Arquivos verificados: [N] arquivos

✅ IMPLEMENTADO:
   ∟ [Lista do que foi encontrado implementado]

⚠️ PENDENTE:
   ∟ [Lista do que ainda falta]

🎯 PRÓXIMOS PASSOS:
   ∟ [Ações específicas recomendadas]

━━━━━━━━━━━━━━━━━━━━━━━━

⏰ Verificado: [TIMESTAMP] | 🤖 Sistema de Verificação Onion
```

## 🔗 **Integração com Sistema Onion**

Este comando se integra perfeitamente com:
- **`/product/task <description>`**: Para criar tasks com workflow completo
- **`/engineer/start <slug>`**: Para iniciar desenvolvimento
- **`/product/validate-task <task-id>`**: Para análise estratégica
- **Sessions em `.claude/sessions/`**: Utiliza contexto das sessões ativas

### **📁 Uso da Sessão Ativa (worklog)**
Se existir um worklog ativo em `.claude/sessions/` relacionado à task, siga o protocolo de leitura escalonado ([worklog-protocol.md §4](../../../docs/knowledge-base/concepts/worklog-protocol.md)) — não faça `cat` da pasta inteira:
- Leia o `STATE.md` primeiro (objetivo, `## Map`, progresso via `NEXT`)
- Analise `context.md` para o escopo original e o Phase-Subtask Mapping
- Examine `architecture.md` (só a seção relevante) para validar implementação vs design
- Consulte o bloco da fase atual em `plan.md` para o progresso
- Atualize `notes.md` (append-only) com resultados da verificação

---

**Agora proceda com a verificação técnica da task fornecida:**

<task_id>
#$ARGUMENTS
</task_id>
