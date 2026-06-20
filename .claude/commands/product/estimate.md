---
name: estimate
description: |
  Orquestra estimativas de story points utilizando o Framework de Story Points.
  Use para estimar tarefas, quebrar épicos e calibrar velocity do time.
  Integra com @story-points-framework-specialist e framework completo.
model: sonnet
allowed-tools: Read Bash(cat .env*)

parameters:
  - name: task_description
    description: Descrição da tarefa ou feature a ser estimada
    required: true
  - name: assignee_level
    description: Nível do responsável (junior/pleno/senior) para ajuste contextual
    required: false
  - name: methodology
    description: 'Metodologia a usar (planning-poker/t-shirt/decomposition). Default: auto-detect'
    required: false
  - name: create_task
    description: Se true, cria task no gerenciador configurado com a estimativa
    required: false

category: product
tags:
  - story-points
  - estimation
  - agile
  - planning

version: "3.0.0"
updated: "2025-11-24"

related_commands:
  - /product/task
  - /product/feature
  - /product/spec

related_agents:
  - story-points-framework-specialist
  - product-agent
  - task-specialist
---

# 🎯 Estimativa de Story Points

Comando para orquestrar estimativas ágeis utilizando o Framework de Story Points, integrando análise de complexidade, decomposição de tarefas e calibração contextual.

## 🎯 Objetivo

Fornecer estimativas precisas e acionáveis de story points para tarefas de desenvolvimento, considerando:
- Complexidade técnica
- Incerteza e riscos
- Esforço necessário
- Contexto do responsável (senioridade)
- Métricas históricas do time

## ⚡ Fluxo de Execução

### Passo 1: Carregar Base de Conhecimento

```bash
# Carregar framework completo de story points
Read docs/knowledge-base/frameworks/framework-story-points.md

# Verificar se há métricas históricas disponíveis
# (velocity, accuracy rate, reference stories)
Grep "velocity tracking metrics historical data"
```

**Objetivo:** Garantir que o agente tem acesso ao framework completo e contexto histórico.

### Passo 2: Análise Inicial da Tarefa

```markdown
## 📋 Informações Coletadas

**Tarefa:** {{task_description}}
**Responsável:** {{assignee_level}} (se fornecido)
**Metodologia:** {{methodology}} (ou auto-detect)

## 🔍 Análise Preliminar

1. **Natureza do Problema:**
   - [ ] Técnico (arquitetura, algoritmos, performance)
   - [ ] Negócio (regras de negócio, validações)
   - [ ] Infraestrutura (DevOps, deploy, config)
   - [ ] Integração (APIs externas, sistemas legados)

2. **Red Flags Detectados:**
   - [ ] Requisitos nebulosos
   - [ ] Tecnologias desconhecidas
   - [ ] Dependências não confirmadas
   - [ ] Impacto crítico sem rollback plan
```

**Ação:** Se red flags detectados, solicitar clarificações antes de estimar.

### Passo 3: Invocar Agente Especialista

```markdown
@story-points-framework-specialist

Por favor, analise a seguinte tarefa e forneça estimativa completa:

**Tarefa:** {{task_description}}
**Responsável:** {{assignee_level}}
**Metodologia sugerida:** {{methodology}}

Siga o processo completo:
1. Análise de Domínio
2. Seleção Metodológica (se não especificada)
3. Aplicação de Checklist apropriado
4. Contextualização por senioridade
5. Validação final

Forneça output estruturado conforme template do agente.
```

**Output Esperado do Agente:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 ANÁLISE DE STORY POINTS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 TAREFA: [Nome da tarefa]

🎯 CLASSIFICAÇÃO DO DOMÍNIO:
∟ Natureza: [Técnico/Negócio/Infra/Integração]
∟ Componentes: [lista]
∟ Tecnologias: [lista]

🔧 METODOLOGIA SELECIONADA:
∟ Técnica: [Planning Poker / T-Shirt / Decomposição]
∟ Justificativa: [por que essa técnica]

🎲 STORY POINTS ATRIBUÍDOS:
∟ Pontuação: [X pontos] ou [X-Y pontos] (range se incerteza)
∟ Checklist aplicado: [3/5/8/13 pontos]
∟ Itens marcados: [X de Y]

⚡ FATORES DE COMPLEXIDADE:
∟ Complexidade técnica: [alta/média/baixa]
∟ Incerteza: [alta/média/baixa]
∟ Esforço: [alto/médio/baixo]
∟ Risco: [alto/médio/baixo]

👤 AJUSTES POR CONTEXTO:
∟ Responsável: [Junior/Pleno/Senior]
∟ Buffer aplicado: [+X pontos] ou [nenhum]
∟ Velocity histórico considerado: [sim/não]

💡 RECOMENDAÇÕES:
∟ Quebra de tarefas: [sim/não] → [justificativa]
∟ Riscos identificados: [lista]
∟ Dependências: [lista]
∟ Sugestões: [pair programming, spike, etc]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Passo 4: Validação e Ajustes

#### 4.1. Verificar Se É Épico (>13 pontos)

```markdown
SE estimativa > 13 pontos:
  ⚠️ ALERTA: Tarefa identificada como ÉPICO
  
  Ações:
  1. Propor quebra em histórias menores
  2. Sugerir estratégia de quebra:
     - Por camadas técnicas
     - Por funcionalidades
     - Por complexidade
  3. Estimar cada história resultante
  4. Validar quebra (valor independente, paralelização)
  
  Template de quebra:
  🎯 ÉPICO: [Nome] - [X pontos total]
  📦 HISTÓRIAS:
  1. [História 1] - [X pontos]
  2. [História 2] - [X pontos]
  ...
```

#### 4.2. Verificar Incerteza Alta (Range >50%)

```markdown
SE range de estimativa > 50%:
  ⚠️ ALERTA: Alta incerteza detectada
  
  Ações:
  1. Identificar fontes de incerteza
  2. Propor spike/POC para reduzir incerteza
  3. Sugerir estimativa conservadora (maior valor do range)
  4. Documentar riscos e dependências
```

#### 4.3. Validar Critérios de Aceite

```markdown
SE critérios de aceite não claros:
  ⚠️ ALERTA: Tarefa sem critérios de aceite
  
  Ações:
  1. Solicitar definição de critérios antes de estimar
  2. Explicar impacto na precisão da estimativa
  3. Sugerir template de critérios de aceite
```

### Passo 5: Criar Task (Opcional)

**SE `{{create_task}}` = true:**

```markdown
## 🚀 Criando Task no Gerenciador

1. **Detectar Provedor:**
   - Verificar TASK_MANAGER_PROVIDER no .env
   - Se não configurado: avisar e continuar apenas com output local

2. **Estruturar Task:**
   ```
   Nome: [Nome da tarefa]
   Descrição: [Descrição completa]
   
   📊 ESTIMATIVA:
   - Story Points: [X pontos]
   - Complexidade: [alta/média/baixa]
   - Risco: [alto/médio/baixo]
   
   ⚡ FATORES CONSIDERADOS:
   - [Lista de fatores]
   
   💡 RECOMENDAÇÕES:
   - [Lista de recomendações]
   ```

3. **Criar via Adapter:**
   - Usar adapter apropriado de `.claude/utils/task-manager/adapters/`
   - Adicionar custom field "Story Points" se disponível
   - Adicionar tags apropriadas (complexity, risk, etc)

4. **Linkar com Épico (se aplicável):**
   - Se tarefa foi quebrada de épico, criar relação parent-child
   - Adicionar referência ao épico na descrição
```

### Passo 6: Documentar Métricas (Opcional)

```markdown
## 📈 Tracking de Métricas

Se métricas históricas disponíveis:

1. **Atualizar Velocity:**
   - Adicionar estimativa ao backlog
   - Calcular velocity projetado

2. **Calcular Accuracy Rate:**
   - Comparar com estimativas anteriores
   - Identificar padrões de sub/super-estimativa

3. **Atualizar Reference Stories:**
   - Se tarefa similar a histórias anteriores
   - Documentar como nova referência
```

## 📤 Output Esperado

### Formato Completo

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ ESTIMATIVA COMPLETA
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 TAREFA: {{task_description}}

🎯 CLASSIFICAÇÃO DO DOMÍNIO:
∟ Natureza: [Técnico/Negócio/Infra/Integração]
∟ Componentes: [lista]
∟ Tecnologias: [lista]
∟ Dependências: [lista]

🔧 METODOLOGIA UTILIZADA:
∟ Técnica: [Planning Poker / T-Shirt / Decomposição]
∟ Justificativa: [por que essa técnica foi escolhida]

🎲 STORY POINTS:
∟ Estimativa: [X pontos] ou [X-Y pontos]
∟ Confiança: [alta/média/baixa]
∟ Checklist aplicado: [3/5/8/13 pontos]
∟ Itens marcados: [X de Y]

⚡ ANÁLISE DE COMPLEXIDADE:
∟ Complexidade técnica: [alta/média/baixa] - [justificativa]
∟ Incerteza: [alta/média/baixa] - [fontes]
∟ Esforço: [alto/médio/baixo] - [breakdown]
∟ Risco: [alto/médio/baixo] - [riscos identificados]

👤 CONTEXTUALIZAÇÃO:
∟ Responsável: [Junior/Pleno/Senior] ou [a definir]
∟ Buffer aplicado: [+X pontos] ou [nenhum]
∟ Ajuste por senioridade: [sim/não]
∟ Velocity histórico: [considerado/não disponível]

💡 RECOMENDAÇÕES:
∟ Quebra necessária: [sim/não]
  └─ Se sim: [estratégia de quebra proposta]
∟ Riscos críticos: [lista]
∟ Dependências: [lista]
∟ Sugestões: [pair programming, spike, pesquisa, etc]

📊 MÉTRICAS (se disponível):
∟ Velocity atual: [X pontos/sprint]
∟ Accuracy rate: [X%]
∟ Comparação com histórico: [análise]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🚀 PRÓXIMOS PASSOS:
1. [ ] Validar estimativa com time
2. [ ] Definir responsável (se não definido)
3. [ ] Criar task no gerenciador (se não criado)
4. [ ] Documentar como reference story (se aplicável)
5. [ ] Agendar spike/POC (se recomendado)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Formato Resumido (Quick Estimate)

**SE usuário solicitar estimativa rápida:**

```
🎲 ESTIMATIVA RÁPIDA: [X pontos]
📊 Confiança: [alta/média/baixa]
💡 Nota: [observação principal]
```

## 🔗 Integração com Outros Comandos

### Com `/product/task`
```markdown
Após estimar, criar task completa:
/product/task "{{task_description}}" --story-points={{estimated_points}}
```

### Com `/product/feature`
```markdown
Estimar feature completa antes de especificar:
/product/estimate "{{feature_description}}" --create_task=true
/product/feature "{{feature_description}}" --estimated_points={{points}}
```

### Com `/product/spec`
```markdown
Incluir estimativa na especificação:
/product/spec "{{feature}}" --include-estimate=true
```

## 📋 Exemplos de Uso

### Exemplo 1: Estimativa Simples

```bash
/product/estimate "Criar API REST para gerenciamento de usuários com autenticação JWT"
```

**Output esperado:**
- Estimativa: 8 pontos
- Justificativa: Sistema de autenticação/autorização (checklist 8 pontos)
- Recomendações: Considerar segurança, testes de integração

### Exemplo 2: Estimativa com Contexto

```bash
/product/estimate "Implementar dashboard com múltiplas visualizações" --assignee_level=junior
```

**Output esperado:**
- Estimativa base: 5 pontos
- Ajuste por senioridade: +1 ponto (buffer para júnior)
- Estimativa final: 6 pontos
- Recomendações: Pair programming sugerido

### Exemplo 3: Estimativa de Épico

```bash
/product/estimate "Sistema completo de notificações com email, SMS e push"
```

**Output esperado:**
- ⚠️ Detectado como épico (>20 pontos estimado)
- Proposta de quebra:
  1. API de envio básica - 5 pontos
  2. Templates de email - 3 pontos
  3. Preferências do usuário - 5 pontos
  4. Dashboard admin - 8 pontos
  5. Integração mobile - 8 pontos
  6. Analytics/métricas - 3 pontos
- Total: 32 pontos → 6 histórias

### Exemplo 4: Estimativa com Criação de Task

```bash
/product/estimate "Refatorar módulo de autenticação" --create_task=true --assignee_level=senior
```

**Output esperado:**
- Estimativa: 8 pontos
- Task criada no ClickUp/Asana com:
  - Custom field "Story Points" = 8
  - Tags: [refactoring, authentication, high-complexity]
  - Descrição completa com análise

## ⚠️ Regras e Validações

### Validações Obrigatórias

1. **Descrição não vazia:**
   ```markdown
   SE task_description vazio:
     ❌ ERRO: Descrição da tarefa é obrigatória
     💡 Sugestão: Forneça detalhes suficientes para análise
   ```

2. **Nível de senioridade válido:**
   ```markdown
   SE assignee_level fornecido E não está em [junior, pleno, senior]:
     ⚠️ AVISO: Nível inválido, usando estimativa padrão
   ```

3. **Metodologia válida:**
   ```markdown
   SE methodology fornecido E não está em [planning-poker, t-shirt, decomposition]:
     ⚠️ AVISO: Metodologia inválida, usando auto-detect
   ```

### Anti-Patterns Detectados

1. **Tarefas > 13 pontos sem justificativa:**
   - ⚠️ Alertar e propor quebra
   - Sugerir estratégia de decomposição

2. **Estimativas sem critérios de aceite:**
   - ⚠️ Alertar sobre impacto na precisão
   - Sugerir definir critérios antes de estimar

3. **Alta incerteza (>50% range):**
   - ⚠️ Propor spike/POC
   - Sugerir estimativa conservadora

## 🔗 Referências

- **Agente:** @story-points-framework-specialist
- **Framework:** `docs/knowledge-base/frameworks/framework-story-points.md`
- **Comandos relacionados:** `/product/task`, `/product/feature`, `/product/spec`
- **Agentes relacionados:** @product-agent, @task-specialist

## 📚 Base de Conhecimento

O comando utiliza o framework completo de story points disponível em:
- `docs/knowledge-base/frameworks/framework-story-points.md`

**Conteúdo incluído:**
- Escala Fibonacci (1, 2, 3, 5, 8, 13, 20+)
- Checklists detalhados para cada nível
- Regras de quebra de épicos
- Ajustes por senioridade
- Métricas de calibração (velocity, accuracy, commitment)
- Técnicas de Planning Poker
- Templates de quebra de épicos

## ⚠️ Notas

- **Estimativas são relativas:** Story points não são horas, são esforço relativo
- **Contexto importa:** Sempre considerar quem vai executar e histórico do time
- **Épicos devem ser quebrados:** Tarefas > 13 pontos precisam de justificativa forte ou quebra
- **Melhoria contínua:** Use métricas históricas para calibrar estimativas futuras
- **Validação com time:** Estimativas individuais devem ser validadas em planning poker quando possível

---

**Versão:** 3.0.0  
**Última atualização:** 2025-11-24  
**Mantido por:** Sistema Onion

