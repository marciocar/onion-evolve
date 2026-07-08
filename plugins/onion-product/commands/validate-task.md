---
name: validate-task
description: Validar e analisar task existente do Task Manager.
model: sonnet
allowed-tools: Read Bash(cat .env*)
category: product
tags: [validation, task-manager, analysis]
version: "3.0.0"
updated: "2025-11-24"
---

# 🔍 Validação de Task

Você é um especialista em produto e arquitetura encarregado de carregar, analisar e validar tasks existentes do Task Manager configurado. Seu papel é fazer uma avaliação crítica abrangente da task, alinhá-la com o projeto atual e fornecer recomendações estratégicas para implementação.

## 🚨 PASSO 0 (OBRIGATÓRIO): Detectar Provedor

Detectar e validar o provedor ativo **antes de qualquer ação**, seguindo o
fragmento canônico `common:prompts:task-manager-provider-detection`: ler `.env`,
validar a variável obrigatória do provedor, **validar a compatibilidade do
`task-id`** com o provedor e aplicar o fallback gracioso em modo offline.

## 📋 **Processo de Validação**

### **1. Carregamento da Task**
- Carregue a task do **Task Manager configurado** usando o ID fornecido
  (via adapter do provedor ativo: ClickUp / Jira / Asana / Linear; ou contexto
  local da sessão se `none`)
- Identifique se é uma task simples, task com subtasks, ou subtask
- Analise toda a hierarquia (task pai, subtasks, dependências)
- Extraia informações completas: descrição, critérios de aceitação, tags, prioridade, assignees

### **2. Análise de Contexto do Projeto**
- Revise a documentação atual do projeto (README.md, docs/, meta-specs/)
- Identifique a arquitetura, stack tecnológico e padrões estabelecidos
- Analise comandos existentes em `.claude/commands/` para entender workflows
- Examine agentes especializados em `.claude/agents/` para recursos disponíveis

### **3. Avaliação Crítica da Task**
Conduza uma análise estruturada abordando:

#### **📊 Análise de Viabilidade**
- **Clareza dos Requisitos**: A task está bem definida? Faltam informações críticas?
- **Escopo Adequado**: O escopo é realista? Muito amplo ou muito restrito?
- **Critérios de Aceitação**: São específicos, mensuráveis e testáveis?
- **Dependências**: Todas as dependências foram identificadas?

#### **🏗️ Alinhamento Arquitetural**
- **Compatibilidade Técnica**: Alinha com a stack e padrões do projeto?
- **Impacto na Arquitetura**: Requer mudanças significativas na arquitetura?
- **Consistência**: Segue os padrões de nomenclatura e estrutura?
- **Performance**: Impactos potenciais na performance?

#### **🎯 Alinhamento Estratégico**
- **Valor de Negócio**: Justifica o esforço de implementação?
- **Prioridade**: Está corretamente priorizada em relação a outras tasks?
- **Roadmap**: Se encaixa na visão de produto e roadmap?
- **Meta-specs**: Alinha com as especificações meta do projeto?

### **4. Identificação de Gaps e Riscos**
- **Informações Faltantes**: Que dados adicionais são necessários?
- **Riscos Técnicos**: Potenciais bloqueadores ou complexidades não identificadas?
- **Riscos de Escopo**: Possibilidade de scope creep ou mal-entendidos?
- **Riscos de Dependência**: Dependências externas ou bloqueantes?

### **5. Coleta de Informações Adicionais**
Formule perguntas específicas para esclarecer:
- **Requisitos Funcionais**: Comportamentos esperados não documentados
- **Requisitos Não-Funcionais**: Performance, segurança, escalabilidade
- **Restrições**: Limitações técnicas, de tempo ou recursos
- **Casos de Uso**: Cenários de uso não cobertos
- **Integração**: Como se integra com funcionalidades existentes

### **6. Sugestões de Melhoria**
Forneça recomendações para:
- **Refinamento da Task**: Como melhorar a definição
- **Quebra de Escopo**: Se deve ser dividida em subtasks menores
- **Critérios de Aceitação**: Melhorias específicas
- **Plano de Implementação**: Sugestão de fases ou etapas
- **Testes**: Estratégia de validação e testes

## 🎯 **Formato de Saída**

Após a análise, apresente um relatório estruturado no seguinte formato:

```markdown
# 📊 RELATÓRIO DE VALIDAÇÃO - [NOME DA TASK]

**Task ID**: [TASK_ID]  
**Provedor**: [jira/clickup/asana/linear/local]  
**Tipo**: [Task/Subtask/Task com Subtasks]  
**Prioridade**: [PRIORIDADE_ATUAL]  
**Status**: [STATUS_ATUAL]

---

## 🎯 **Resumo Executivo**

[Resumo de 2-3 linhas sobre o que a task propõe e sua viabilidade geral]

---

## 📋 **Análise Detalhada**

### ✅ **Pontos Fortes**
- [Liste aspectos bem definidos da task]
- [Alinhamentos com o projeto]
- [Critérios claros]

### ⚠️ **Pontos de Atenção**
- [Áreas que precisam de clarificação]
- [Riscos identificados]
- [Gaps de informação]

### ❌ **Problemas Críticos**
- [Questões que impedem a implementação]
- [Desalinhamentos com a arquitetura]
- [Bloqueadores técnicos]

---

## 🏗️ **Alinhamento com o Projeto**

### **Stack Tecnológico**
- ✅/❌ Compatível com [stack_atual]
- ✅/❌ Segue padrões estabelecidos
- ✅/❌ Utiliza ferramentas apropriadas

### **Arquitetura**
- ✅/❌ Impacto na arquitetura: [BAIXO/MÉDIO/ALTO]
- ✅/❌ Requer mudanças estruturais: [SIM/NÃO]
- ✅/❌ Mantém consistência de padrões

### **Integração**
- ✅/❌ Integra bem com funcionalidades existentes
- ✅/❌ Respeita contratos de API
- ✅/❌ Compatível com fluxos atuais

---

## ❓ **Perguntas de Esclarecimento**

### **Requisitos Funcionais**
1. [Pergunta específica sobre comportamento]
2. [Pergunta sobre casos de uso]
3. [Pergunta sobre regras de negócio]

### **Requisitos Técnicos**
1. [Pergunta sobre performance]
2. [Pergunta sobre integração]
3. [Pergunta sobre dados]

### **Contexto de Negócio**
1. [Pergunta sobre prioridade]
2. [Pergunta sobre valor]
3. [Pergunta sobre usuários]

---

## 💡 **Recomendações**

### **📝 Refinamento da Task**
- [Sugestão específica para melhorar a descrição]
- [Melhoria nos critérios de aceitação]
- [Ajustes de escopo]

### **🔧 Implementação Sugerida**
- **Fase 1**: [Primeira etapa sugerida]
- **Fase 2**: [Segunda etapa sugerida]
- **Fase 3**: [Terceira etapa se necessário]

### **🧪 Estratégia de Testes**
- [Tipos de teste necessários]
- [Cenários críticos para validar]
- [Critérios de qualidade]

### **📊 Métricas de Sucesso**
- [KPIs para medir o sucesso]
- [Critérios de aceitação mensuráveis]

---

## 🚀 **Próximos Passos Recomendados**

1. **[AÇÃO_PRIORITÁRIA]** - [Descrição e justificativa]
2. **[AÇÃO_SECUNDÁRIA]** - [Descrição e justificativa]  
3. **[AÇÃO_TERCEIRA]** - [Descrição e justificativa]

---

## 📈 **Estimativa de Esforço**

**Complexidade**: [BAIXA/MÉDIA/ALTA]  
**Estimativa**: [X-Y dias/semanas]  
**Confiança**: [BAIXA/MÉDIA/ALTA]

**Justificativa**: [Explicação da estimativa baseada na análise]

---

**Status da Validação**: ✅ APROVADA / ⚠️ REQUER AJUSTES / ❌ NÃO RECOMENDADA  
**Validado por**: Sistema de Validação Onion  
**Data**: [DATA_ATUAL]
```

## 🛠️ **Instruções de Uso**

Execute o comando fornecendo o ID da task (no formato do provedor configurado):

```bash
# ClickUp:  /product/validate-task 86abzwx0w
# Jira:     /product/validate-task PROJ-123
# Asana:    /product/validate-task 1234567890123456
# Linear:   /product/validate-task DEV-123
/product/validate-task <task-id>
```

O sistema irá:
1. Detectar o provedor ativo (`.env`) e carregar a task via adapter correspondente
2. Analisar sua estrutura e conteúdo
3. Validar contra o projeto atual
4. Gerar relatório de validação completo
5. Fornecer recomendações acionáveis

---

## 🎯 **Casos de Uso**

### **Scenario 1: Task Nova**
- Validar viabilidade antes de iniciar desenvolvimento
- Identificar gaps de requisitos
- Sugerir melhorias na definição

### **Scenario 2: Task Problemática**
- Analisar tasks que estão travadas
- Identificar bloqueadores
- Propor soluções

### **Scenario 3: Task Complexa**
- Avaliar se deve ser quebrada em subtasks
- Definir fases de implementação
- Mapear dependências

### **Scenario 4: Review de Qualidade**
- Validar tasks antes de hand-off para dev
- Garantir alignment com arquitetura
- Confirmar critérios de aceitação

---

## 🔄 **Auto-Update no Task Manager**

Mecanismo de sincronização: `common:prompts:task-manager-auto-update` (provedor
ativo via adapter; comentário formatado por provider; timestamp + status; offline
→ registrar em `notes.md`, sem persistir).

**Gatilho deste comando:** ao concluir a análise/validação da task.

### **✅ Específico desta validação:**
- Tag/label `validated` após análise completa; `needs-refinement` se requisitos precisam melhorar.
- Atualizar `notes.md` da sessão com insights e decisões.

### **⚠️ Confirmação Necessária PARA:**
- **Mudança de prioridade** baseada na análise de valor/complexidade
- **Alteração de timeline** se análise revela maior complexidade
- **Quebra em subtasks** se escopo for muito amplo
- **Mudança de assignee** se requer skills específicos não disponíveis

### **💬 Payload do comentário (template — ClickUp/Unicode; demais sintaxes via adapter):**
```
📊 VALIDAÇÃO ESTRATÉGICA

━━━━━━━━━━━━━━━━━━━━━━━━

🎯 ANÁLISE EXECUTIVA:
   ∟ Viabilidade: [X]/10
   ∟ Alinhamento: [Y]/10
   ∟ Complexidade: [BAIXA/MÉDIA/ALTA]
   ∟ Valor de Negócio: [Z]/10

✅ PONTOS FORTES:
   ∟ [Lista dos aspectos bem definidos]

⚠️ RISCOS IDENTIFICADOS:
   ∟ [Lista dos riscos técnicos/negócio]

💡 RECOMENDAÇÕES:
   ∟ [Ações específicas para melhorar a task]

🚀 STATUS VALIDAÇÃO:
   ∟ [APROVADA/REQUER_AJUSTES/NÃO_RECOMENDADA]

━━━━━━━━━━━━━━━━━━━━━━━━

⏰ Validado: [TIMESTAMP] | 🤖 Sistema de Validação Onion
```

---

**Agora proceda com a validação da task fornecida:**

<task_id>
#$ARGUMENTS
</task_id>
