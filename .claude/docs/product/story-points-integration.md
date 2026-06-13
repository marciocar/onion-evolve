# 📊 Integração Automática de Story Points

Documentação da integração automática de estimativas de story points nos comandos do Sistema Onion.

## 🎯 Objetivo

Automaticamente calcular e atualizar story points em todas as tarefas criadas ou modificadas pelos comandos do Sistema Onion, garantindo:
- Estimativas precisas baseadas no Framework de Story Points
- Rastreabilidade de mudanças (histórico)
- Consistência entre task principal e subtasks
- Alertas para épicos (>13 pontos)

## 🔄 Comandos Integrados

### ✅ `/product/task`
**Quando:** Ao criar task com decomposição hierárquica

**Ações:**
1. Estima story points para **task principal** após decomposição
2. Estima story points para **cada subtask** individualmente
3. Valida consistência (soma subtasks vs task principal)
4. Alerta se task > 13 pontos (épico)
5. Insere estimativas em custom fields e descrições
6. Adiciona comentário com análise completa

**Output:**
```
🎲 STORY POINTS:
∟ Task Principal: [X] pontos
∟ Subtasks: [Y] pontos ([N] subtasks)
∟ Total: [Z] pontos
```

### ✅ `/product/collect`
**Quando:** Ao coletar nova ideia/feature/bug

**Ações:**
1. Estima story points após criar task
2. Atualiza custom field "Story Points"
3. Adiciona comentário com análise inicial
4. Alerta se > 13 pontos (pode precisar refinement)

**Nota:** Estimativa inicial pode ser refinada posteriormente.

### ✅ `/product/refine`
**Quando:** Ao refinar requisitos de uma task existente

**Ações:**
1. **Lê estimativa anterior** (custom field + comentários)
2. **Recalcula** story points com requisitos refinados
3. **Compara** estimativa anterior vs nova
4. **Documenta histórico** de mudanças
5. **Atualiza** custom field com nova estimativa
6. **Adiciona comentário** com:
   - Estimativa anterior
   - Nova estimativa
   - Delta (mudança)
   - Motivo da mudança
   - Análise atualizada

**Template de Histórico:**
```
📊 HISTÓRICO DE ESTIMATIVAS:
| Data | Estimativa | Mudança | Motivo |
|------|------------|---------|--------|
| [data inicial] | [X] pontos | - | Criação inicial |
| [data refinamento] | [Y] pontos | [+/-Z] | Refinamento de requisitos |
```

### ✅ `/product/feature`
**Quando:** Ao criar feature de backlog

**Ações:**
1. Estima story points após criar task
2. Atualiza custom field "Story Points"
3. Adiciona comentário com estimativa inicial
4. Nota que estimativa pode ser refinada

**Nota:** Features de backlog têm estimativas iniciais para planejamento.

## 🔧 Agente Utilizado

**@story-points-framework-specialist**

Este agente é invocado automaticamente pelos comandos para:
- Análise de domínio (técnico/negócio/infra/integração)
- Seleção metodológica (Planning Poker / T-Shirt / Decomposição)
- Aplicação de checklists (3/5/8/13 pontos)
- Contextualização por senioridade
- Detecção de épicos

**Base de Conhecimento:**
- `docs/knowledge-base/frameworks/framework-story-points.md`

## 📋 Fluxo de Estimativa

### 1. Criação de Task (`/product/task`)

```
1. Decompor hierarquicamente (task → subtasks → action items)
2. Estimar task principal
   └─ @story-points-framework-specialist
3. Estimar cada subtask
   └─ @story-points-framework-specialist (para cada)
4. Validar consistência
   └─ Se soma(subtasks) > principal: ajustar
   └─ Se principal > 13: alertar épico
5. Criar task com estimativas
   └─ Custom field "Story Points"
   └─ Descrição com análise
   └─ Comentário inicial
```

### 2. Refinamento (`/product/refine`)

```
1. Ler estimativa anterior
   └─ Custom field atual
   └─ Comentários anteriores
2. Recalcular com requisitos refinados
   └─ @story-points-framework-specialist
3. Comparar e documentar
   └─ Calcular delta
   └─ Identificar mudanças que afetaram
4. Atualizar task
   └─ Custom field atualizado
   └─ Comentário com histórico
   └─ Descrição atualizada
```

## 📊 Estrutura de Dados

### Custom Field "Story Points"
- **Tipo:** Number
- **Localização:** Task principal e subtasks
- **Atualização:** Automática em criação e refinamento

### Comentários de Estimativa

**Formato Padrão:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 ESTIMATIVA DE STORY POINTS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🎲 Story Points: [X] pontos

⚡ ANÁLISE:
∟ Complexidade: [alta/média/baixa]
∟ Risco: [alto/médio/baixo]
∟ Incerteza: [alta/média/baixa]

💡 RECOMENDAÇÕES:
[lista de recomendações]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Formato de Histórico (Refine):**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔄 ESTIMATIVA ATUALIZADA APÓS REFINAMENTO
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📅 Data: [data]

📊 HISTÓRICO:
∟ Estimativa anterior: [X] pontos
∟ Nova estimativa: [Y] pontos
∟ Mudança: [+/-Z] pontos

📝 MUDANÇAS QUE AFETARAM A ESTIMATIVA:
- [mudança 1]
- [mudança 2]

💡 RECOMENDAÇÕES:
[recomendações atualizadas]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## ⚠️ Regras e Validações

### Validação de Consistência

**Regra:** Soma das subtasks não deve ser muito diferente da task principal

```typescript
if (sum(subtasks) > mainTask * 1.5) {
  // Ajustar task principal para soma das subtasks
  mainTask = sum(subtasks);
  log("⚠️ Ajustada estimativa da task principal para consistência");
}
```

### Detecção de Épicos

**Regra:** Tasks > 13 pontos devem ser alertadas

```typescript
if (storyPoints > 13) {
  alert("⚠️ Task identificada como ÉPICO");
  suggest("Quebrar em múltiplas tasks menores");
  log("Recomendação: usar estratégia de quebra por camadas/funcionalidades");
}
```

### Histórico Obrigatório

**Regra:** Mudanças de estimativa devem sempre manter histórico

```typescript
const history = {
  date: new Date(),
  previous: previousEstimate,
  current: newEstimate,
  delta: newEstimate - previousEstimate,
  reason: "Refinamento de requisitos",
  changes: identifiedChanges
};

// Sempre adicionar ao histórico antes de atualizar
addToHistory(taskId, history);
updateEstimate(taskId, newEstimate);
```

## 🔗 Comandos Relacionados

- `/product/estimate` - Estimativa manual/standalone
- `/product/task` - Criação com estimativa automática
- `/product/collect` - Coleta com estimativa inicial
- `/product/refine` - Refinamento com recalculo automático
- `/product/feature` - Feature backlog com estimativa

## 📚 Referências

- **Agente:** @story-points-framework-specialist
- **Framework:** `docs/knowledge-base/frameworks/framework-story-points.md`
- **Comando de Estimativa:** `/product/estimate`

## 🚀 Próximos Passos

1. **Configurar Custom Field:** Garantir que "Story Points" existe no ClickUp/Asana
2. **Calibrar Baseline:** Estabelecer histórias de referência
3. **Tracking de Velocity:** Implementar dashboard de velocity
4. **Accuracy Rate:** Calcular precisão das estimativas ao longo do tempo

---

**Versão:** 3.0.0  
**Última atualização:** 2025-11-24  
**Mantido por:** Sistema Onion

