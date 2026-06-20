---
name: estimate
description: |
  Calcula QA Story Points usando a fórmula exata do Framework de Testes.
  Use para estimar esforço de teste com precisão, incluindo breakdown por perspectiva e sugestões de técnicas.
  Integra com task managers para atualizar story points automaticamente.
model: sonnet
allowed-tools: Read

parameters:
  - name: task-description
    description: Descrição da tarefa de teste (entre aspas)
    required: true
  - name: complexity
    description: 'Complexidade base (simple|medium|complex|epic). Default: auto-detect'
    required: false
  - name: risk
    description: 'Nível de risco (low|medium|high|critical). Default: auto-detect'
    required: false
  - name: type
    description: 'Tipo de teste (unit|integration|ui|api|e2e|performance|security|manual). Default: auto-detect'
    required: false
  - name: task-id
    description: 'ID da task no task manager para atualizar (ex: PROJ-123, CU-456)'
    required: false
  - name: task-manager
    description: Provedor do task manager (jira|clickup|asana|auto-detect). Se não fornecido, será inferido do .env ou formato do task-id
    required: false
  - name: update
    description: Atualiza story points diretamente no task manager quando fornecido task-id
    required: false
  - name: breakdown
    description: Mostra breakdown detalhado por perspectiva (White/Grey/Black-box)
    required: false
  - name: suggest-techniques
    description: Sugere técnicas de teste baseadas no framework
    required: false

category: validate
tags:
  - qa
  - testing
  - story-points
  - estimation
  - quality-assurance
  - test-planning

version: "1.0.0"
updated: "2025-12-03"

related_commands:
  - /validate/test-strategy/create
  - /validate/test-strategy/analyze
  - /product/estimate
  - /product/task

related_agents:
  - test-engineer
  - test-planner
---

# 🧮 Estimativa de QA Story Points

Calcula QA Story Points usando a fórmula exata do Framework de Testes, com análise contextual inteligente, breakdown por perspectiva e sugestões de técnicas.

> **Base de conhecimento (carregue antes de calcular):**
> - **Conceito canônico** — `docs/knowledge-base/frameworks/framework-testes.md`, seção "QA Story Points - Sistema de Estimativa" (3 dimensões, fórmula, escala de conversão para horas, padrões White/Grey/Black-box).
> - **Tabelas determinísticas de cálculo, keywords, distribuição por tipo e técnicas** — `docs/knowledge-base/frameworks/qa-story-points.md`.
> - **Operacionalização para auditoria** (validação de discrepância, distribuição por complexidade) — `docs/knowledge-base/frameworks/test-strategy-scoring.md`.

## 🎯 Objetivo

Fornecer estimativas precisas de esforço de teste através de:
- Fórmula exata do Framework de Testes (sem desvios)
- Análise contextual inteligente da descrição
- Breakdown por perspectiva (White/Grey/Black-box)
- Sugestões de técnicas apropriadas
- Integração com task managers para atualização automática

## ⚡ Fluxo de Execução

### Passo 1: Carregar referências (OBRIGATÓRIO)

Ler antes de qualquer cálculo:

```bash
Read docs/knowledge-base/frameworks/framework-testes.md       # conceito + fórmula + conversão p/ horas
Read docs/knowledge-base/frameworks/qa-story-points.md        # tabelas de cálculo, keywords, técnicas
```

SE `framework-testes.md` não encontrado:
> ❌ ERRO: Framework de testes não encontrado. 💡 Verifique se o arquivo existe e tente novamente.

### Passo 2: Análise contextual da descrição

1. **Detectar keywords** de complexidade, risco e tipo — usar o "Mapa de Detecção de Keywords" (`qa-story-points.md` §2).
2. **Inferir parâmetros** não fornecidos a partir das keywords; aplicar os defaults da §2 quando nenhuma keyword for detectada.

### Passo 3: Cálculo de QA Story Points

Aplicar a fórmula `QA Points = Complexidade Base + Ajuste de Risco + Ajuste de Tipo` usando os **valores determinísticos** da `qa-story-points.md` §1 (sem desvios). Somar ajustes contextuais de keywords (ex.: `third-party integration` +1 complexity; `legacy system` +1 complexity +1 risk).

Converter o total para horas pela escala do framework (`framework-testes.md`), aplicando os fatores de ajuste quando relevantes.

**Exemplo:** medium (4) + context (+1) + high risk (+3) + integration (+2) = **10 QA Story Points** ≈ 14-18h.

### Passo 4: Breakdown multi-perspectiva (SE `--breakdown`)

Distribuir o total pelos percentuais White/Grey/Black-box do tipo de teste (`qa-story-points.md` §3). Reportar pontos, horas e percentual por perspectiva.

### Passo 5: Sugestões de técnicas (SE `--suggest-techniques`)

Listar as técnicas do tipo de teste a partir de `qa-story-points.md` §4 (detalhe técnico no framework). Não inventar técnicas fora do framework.

### Passo 6: Integração com Task Manager (SE `--task-id`)

1. **Detectar provedor:** usar `{{task-manager}}` se explícito; senão delegar a `detector.detectProviderFromTaskId(taskId)` (o detector/factory resolve o provider — não inferir manualmente pelo prefixo do ID) ou ler `TASK_MANAGER_PROVIDER` no `.env`. Se nada detectado → continuar apenas com output local.
2. **Buscar a task** via `taskManager.getTask(taskId)` e validar que existe; ler story points atuais.
3. **Atualizar (SE `--update`):** chamar `taskManager.updateTask(taskId, { customField: "QA Story Points", value: totalPoints })` (REST API default; o adapter resolve o nome/ID do custom field por provider e aciona o especialista quando necessário); comentar a análise via `taskManager.addComment(taskId, commentText)`.
   - Se o custom field não existir: comentar a estimativa e sugerir criar o campo (o adapter/especialista orienta o formato correto por provider).

**Template de comentário (Unicode):**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🧮 QA STORY POINTS ESTIMATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📅 Timestamp: [data/hora]

📋 TASK ANALYSIS:
∟ Description: "{{task-description}}"
∟ Detected Keywords: [keywords]
∟ Context Factors: [ajustes contextuais]

🧮 FORMULA BREAKDOWN:
∟ Base Complexity: {{complexity}} = {{base_points}} points
∟ Context Adjustment: {{context_adjustment}} points
∟ Risk Adjustment: {{risk}} = {{risk_points}} points
∟ Type Adjustment: {{type}} = {{type_points}} points
∟ **Total: {{total_points}} QA Story Points**

⏱️ ESTIMATED EFFORT: {{hours_range}} hours

🎭 MULTI-PERSPECTIVE BREAKDOWN:
∟ White-box: {{white_points}} pts | {{white_hours}}h | {{white_percent}}%
∟ Grey-box: {{grey_points}} pts | {{grey_hours}}h | {{grey_percent}}%
∟ Black-box: {{black_points}} pts | {{black_hours}}h | {{black_percent}}%

💡 SUGGESTED TECHNIQUES:
{{lista de técnicas}}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ {{total_points}} QA Story Points estimated.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## 📤 Output Esperado

**Resumido (sem flags):**

```
🧮 QA STORY POINTS: {{total_points}} pontos
⏱️ Estimated Effort: {{hours_range}} hours
📊 Type: {{type}} | Complexity: {{complexity}} | Risk: {{risk}}
```

**Completo (com `--breakdown` / `--suggest-techniques`):** seguir a estrutura do template de comentário acima (Task Analysis → Formula Breakdown → Effort → Multi-Perspective → Suggested Techniques), com as técnicas/responsabilidades agrupadas por perspectiva.

## 📋 Exemplos de Uso

```bash
# Básico — detecta payment (high risk) + API (integration): medium(4)+high(+3)+integration(+2)=9 pts (~12-16h)
/qa-points/estimate "API integration tests for payment gateway"

# Com breakdown e técnicas — total 10 pts, distribuição por perspectiva + técnicas
/qa-points/estimate "API tests for payment gateway with third-party service" medium high integration --breakdown --suggest-techniques

# Com atualização — simple(2)+low(+0)+ui(+3)=5 pts; grava custom field + comentário em CU-456
/qa-points/estimate "Login form validation" simple low ui --task-id CU-456 --update

# Inferência automática — e2e + complex + high risk: complex(7)+high(+3)+e2e(+4)=14 pts → alerta >13 (quebrar)
/qa-points/estimate "E2E testing for checkout flow with payment integration"
```

## ⚠️ Regras e Validações

- **Descrição obrigatória:** vazia → ❌ ERRO pedindo detalhes.
- **Valores válidos e anti-patterns:** ver `qa-story-points.md` §5 (valores aceitos por parâmetro, alerta de épico >13 pts, inconsistências como `unit+critical` e `manual+epic`).
- **Task-id inválido:** ⚠️ AVISO, continuar sem atualização.
- **Fórmula exata:** sempre usar os valores das KBs, sem desvios; técnicas sempre do framework.
- **Atualização automática:** usar `--update` apenas quando confiante na estimativa; requer integração configurada via `/meta/setup-integration`.

## 🔗 Integração com Outros Comandos

- `/validate/test-strategy/create "{{task-description}}" --qa-points={{estimated_points}}` — estratégia completa após estimar.
- `/product/task "{{task-description}}" --qa-points={{estimated_points}}` — criar task com a estimativa QA.
- `/product/estimate` — comparar estimativa dev vs QA.

---

**Versão:** 1.0.0 · **Última atualização:** 2025-12-03 · **Mantido por:** Sistema Onion
