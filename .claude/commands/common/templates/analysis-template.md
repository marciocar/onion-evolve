---
# Claude Code - Analysis Template Metadata
template:
  type: analysis
  version: 2.0
  category: documentation
  name: "[Tipo de Análise]"

analysis_metadata:
  analysis_type: "[Crítica | Implementação | Status]"
  date: "[YYYY-MM-DD]"
  analyst: "[Nome do analista/equipe]"
  base_document: "[Referência ao que está sendo analisado]"
  scope: "[O que está sendo analisado - ex: Migração, Implementação, Arquitetura]"

severity_config:
  critical:
    label: "🔴 CRÍTICO"
    criteria: "[Critério para problemas críticos]"
  high:
    label: "🟡 ALTO"
    criteria: "[Critério para problemas altos]"
  medium:
    label: "🟢 MÉDIO"
    criteria: "[Critério para problemas médios]"

status:
  overall: "[EXCELENTE | BOM | CRÍTICO]"
  completion_percentage: 0
  critical_actions: 0
  risks_identified: 0
  main_findings: []

tracking:
  phases:
    immediate: "[Esta Semana]"
    short_term: "[Próximas 2 Semanas]"
    medium_term: "[Próximo Mês]"
  
  metrics:
    - name: "[Métrica 1]"
      current: "[Valor]"
      expected: "[Target]"
      status: "[OK | WARNING | CRITICAL]"

ai_assistant:
  auto_status: true
  track_actions: true
  monitor_metrics: true
  prioritize_risks: true
  suggest_solutions: true
---

# Análise [Tipo]: [Título da Análise]

**Documento de Análise [Crítica/Implementação/Status]**  
**Data:** [YYYY-MM-DD]  
**Analisado por:** [Nome do analista/equipe]  
**Documento/Sistema Base:** [Referência ao que está sendo analisado]  
**Escopo:** [O que está sendo analisado - ex: Migração, Implementação, Arquitetura]

---

## 🚨 **RESUMO EXECUTIVO**

[Resumo conciso do status geral da análise, incluindo:]

- **Status Geral**: [🟢 EXCELENTE / 🟡 BOM / 🔴 CRÍTICO] ([X%] implementado/conforme)
- **Principais Achados**: [2-3 pontos mais importantes]
- **Ações Críticas**: [Quantas ações críticas identificadas]
- **Riscos Identificados**: [Número de riscos por severity]

**Severity Levels:**
- 🔴 **CRÍTICO**: [Critério para problemas críticos]
- 🟡 **ALTO**: [Critério para problemas altos]
- 🟢 **MÉDIO**: [Critério para problemas médios]

---

## 📋 **ANÁLISE DETALHADA**

### **1. [CATEGORIA DE ANÁLISE 1]**

#### **🟢 [Subcategoria] - STATUS POSITIVO**
**Status**: ✅ **[STATUS]** ([X%] [métrica])

**[Componentes/Aspectos] Analisados:**
- ✅ **[Item 1]**: [Descrição do status]
- ✅ **[Item 2]**: [Descrição do status] 
- ✅ **[Item 3]**: [Descrição do status]

**Evidências:**
- [Evidência 1 - arquivo/configuração/teste]
- [Evidência 2 - métrica/resultado]
- [Evidência 3 - observação]

#### **🟡 [Subcategoria] - STATUS PARCIAL**
**Status**: ⚠️ **[STATUS]** ([X%] [métrica])

**[Componentes/Aspectos] Analisados:**
- ✅ **[Item implementado]**: [Descrição]
- ⚠️ **[Item parcial]**: [Descrição do que falta]
- ❌ **[Item faltando]**: [Descrição do problema]

**Gaps Identificados:**
- [Gap 1 com impacto]
- [Gap 2 com impacto]

#### **🔴 [Subcategoria] - STATUS CRÍTICO**
**Status**: ❌ **[STATUS]** ([X%] [métrica])

**Problemas Críticos:**
- 🔴 **[Problema 1]**: [Descrição detalhada]
  - **Impacto**: [Impacto específico]
  - **Causa Raiz**: [Análise da causa]
  - **Recomendação**: [Solução específica]

---

## 📊 **MATRIZ DE STATUS/PROBLEMAS**

### **Matriz de Implementação**
| Componente | Status | % Completo | Prioridade | Estimativa |
|------------|--------|------------|------------|------------|
| [Componente 1] | ✅ COMPLETO | 100% | - | - |
| [Componente 2] | ⚠️ PARCIAL | 75% | 🟡 ALTA | 4h |
| [Componente 3] | ❌ FALTANDO | 0% | 🔴 CRÍTICA | 8h |

### **Matriz de Riscos**
| Risco | Probabilidade | Impacto | Severity | Mitigação |
|-------|--------------|---------|----------|-----------|
| [Risco 1] | Alta | Crítico | 🔴 | [Estratégia de mitigação] |
| [Risco 2] | Média | Alto | 🟡 | [Estratégia de mitigação] |
| [Risco 3] | Baixa | Médio | 🟢 | [Estratégia de mitigação] |

---

## 🎯 **PROBLEMAS IDENTIFICADOS POR CATEGORIA**

### **1. PROBLEMAS CRÍTICOS** 🔴

#### **[Nome do Problema Crítico]**
- **Problema**: [Descrição específica]
- **Impacto**: [Consequências detalhadas]
- **Evidência**: [Como foi identificado]
- **Solução**: [Ação específica necessária]
- **Prazo**: [Quando deve ser resolvido]

### **2. PROBLEMAS ALTOS** 🟡

#### **[Nome do Problema Alto]**
- **Problema**: [Descrição específica]
- **Impacto**: [Consequências detalhadas]
- **Solução**: [Ação específica necessária]

### **3. MELHORIAS RECOMENDADAS** 🟢

#### **[Nome da Melhoria]**
- **Oportunidade**: [Descrição da melhoria]
- **Benefício**: [Vantagens esperadas]
- **Implementação**: [Como implementar]

---

## 📈 **MÉTRICAS E VALIDAÇÃO**

### **Métricas Atuais vs. Esperadas**
| Métrica | Atual | Esperado | Status | Gap |
|---------|-------|----------|--------|-----|
| [Métrica 1] | [Valor] | [Target] | [✅/⚠️/❌] | [Diferença] |
| [Métrica 2] | [Valor] | [Target] | [✅/⚠️/❌] | [Diferença] |
| [Métrica 3] | [Valor] | [Target] | [✅/⚠️/❌] | [Diferença] |

### **Critérios de Sucesso**
- [ ] **[Critério 1]**: [Descrição específica e mensurável]
- [ ] **[Critério 2]**: [Descrição específica e mensurável]
- [ ] **[Critério 3]**: [Descrição específica e mensurável]

### **Testes de Validação**
```bash
# Comandos para validar os resultados
validation-command-1
validation-command-2
validation-command-3
```

---

## 🔧 **RECOMENDAÇÕES PRIORITÁRIAS**

### **AÇÕES IMEDIATAS** (Esta Semana) 🔴
1. **[Ação Crítica 1]** - [Estimativa: Xh]
   - **Por que**: [Justificativa da urgência]
   - **Como**: [Passos específicos]
   - **Resultado**: [Outcome esperado]

2. **[Ação Crítica 2]** - [Estimativa: Xh]
   - **Por que**: [Justificativa da urgência]
   - **Como**: [Passos específicos]
   - **Resultado**: [Outcome esperado]

### **AÇÕES CURTO PRAZO** (Próximas 2 Semanas) 🟡
1. **[Ação Importante 1]** - [Estimativa: Xh]
2. **[Ação Importante 2]** - [Estimativa: Xh]

### **AÇÕES MÉDIO PRAZO** (Próximo Mês) 🟢
1. **[Melhoria 1]** - [Estimativa: Xh]
2. **[Melhoria 2]** - [Estimativa: Xh]

---

## ✅ **PLANO DE AÇÃO DETALHADO**

### **Fase 1: Correções Críticas** (Prazo: [Data])
- [ ] **[Task 1]** - [Responsável] - [Deadline]
- [ ] **[Task 2]** - [Responsável] - [Deadline]
- [ ] **[Task 3]** - [Responsável] - [Deadline]

**Critérios de Aceitação:**
- [ ] [Critério específico 1]
- [ ] [Critério específico 2]

### **Fase 2: Melhorias** (Prazo: [Data])
- [ ] **[Task 1]** - [Responsável] - [Deadline]
- [ ] **[Task 2]** - [Responsável] - [Deadline]

**Critérios de Aceitação:**
- [ ] [Critério específico 1]
- [ ] [Critério específico 2]

### **Fase 3: Otimizações** (Prazo: [Data])
- [ ] **[Task 1]** - [Responsável] - [Deadline]
- [ ] **[Task 2]** - [Responsável] - [Deadline]

---

## 🏆 **CONCLUSÃO E PRÓXIMOS PASSOS**

### **✅ PONTOS FORTES IDENTIFICADOS**
- **[Ponto forte 1]**: [Por que é importante]
- **[Ponto forte 2]**: [Por que é importante]
- **[Ponto forte 3]**: [Por que é importante]

### **⚠️ LACUNAS CRÍTICAS**
- **[Lacuna 1]**: [Impacto e urgência]
- **[Lacuna 2]**: [Impacto e urgência]
- **[Lacuna 3]**: [Impacto e urgência]

### **🎯 PRÓXIMO PASSO RECOMENDADO**
**[Ação específica mais importante]** - [Justificativa detalhada]

### **📊 EXPECTATIVA DE MELHORIA**
Após implementar as recomendações:
- **Status esperado**: [De X% para Y%]
- **Riscos mitigados**: [Quantos riscos serão resolvidos]
- **Benefícios**: [Principais benefícios esperados]

---

## 📚 **ANEXOS E REFERÊNCIAS**

### **Documentos Analisados**
- [Documento 1] - [Relevância para análise]
- [Documento 2] - [Relevância para análise]

### **Ferramentas Utilizadas**
- [Ferramenta 1] - [Para que foi usada]
- [Ferramenta 2] - [Para que foi usada]

### **Metodologia**
- **Critérios de análise**: [Como foi feita a análise]
- **Fontes de dados**: [De onde vieram as informações]
- **Limitações**: [O que não foi possível analisar]

---

**📅 Criado em:** [Data]  
**👤 Analista:** [Nome e contato]  
**🔄 Próxima revisão:** [Data recomendada para nova análise]  
**📋 Status do documento:** [Draft/Review/Approved] 