---
name: analyze
description: |
  Analisa estratégias de teste existentes e sugere melhorias baseadas no Framework de Testes.
  Use para auditar conformidade, identificar gaps e otimizar estratégias de teste com base no framework.
model: sonnet
allowed-tools: Read Write Bash(find *) Bash(grep *) Bash(mkdir *)

parameters:
  - name: feature-id
    description: 'ID da feature/epic no task manager (ex: PROJ-123, CU-456)'
    required: true
  - name: task-manager
    description: Provedor do task manager (jira|clickup|asana). Se não fornecido, será inferido automaticamente do .env ou formato do feature-id
    required: false
  - name: deep-scan
    description: Análise profunda incluindo código e cobertura
    required: false
  - name: auto-fix
    description: Aplica correções automáticas quando possível
    required: false
  - name: export-report
    description: Gera relatório detalhado em arquivo
    required: false

category: validate
tags:
  - testing
  - qa
  - strategy
  - analysis
  - compliance
  - audit
  - improvement

version: "3.0.0"
updated: "2025-12-03"

related_commands:
  - /validate/test-strategy/create
  - /product/task
  - /product/estimate

related_agents:
  - test-engineer
  - test-planner
---

# 🔍 Análise de Estratégia de Teste

Analisa estratégias de teste existentes e sugere melhorias baseadas no Framework de Testes, identificando gaps de conformidade e oportunidades de otimização.

Este comando é um **orquestrador**. Ele não duplica o framework nem as matrizes de scoring — carrega ambos por referência:

- **Framework canônico** (perspectivas White/Grey/Black-box, fórmula de QA Story Points, técnicas, templates, padrões de colaboração): `docs/knowledge-base/frameworks/framework-testes.md`
- **Matrizes de scoring, thresholds, regras de gap e fórmulas de impacto:** `docs/knowledge-base/frameworks/test-strategy-scoring.md`

## 🎯 Objetivo

Auditar e melhorar estratégias de teste existentes através de:
- Análise de conformidade com o Framework de Testes
- Identificação de gaps de cobertura e qualidade
- Sugestões priorizadas de melhorias
- Correções automáticas quando aplicável (`--auto-fix`)
- Relatórios detalhados e acionáveis (`--export-report`)

## ⚡ Fluxo de Execução

### Passo 1: Carregar Framework e Matrizes de Scoring (OBRIGATÓRIO)

**CRÍTICO:** Sempre carregar antes de qualquer análise.

```bash
Read docs/knowledge-base/frameworks/framework-testes.md
Read docs/knowledge-base/frameworks/test-strategy-scoring.md
```

Do **framework** extrair: QA Story Points, perspectivas White/Grey/Black-box, técnicas por tipo, métricas de qualidade, template universal de caso de teste, padrões de colaboração.

Da **KB de scoring** extrair: matriz de discrepância de QA points, score multi-perspectiva, matriz de detecção de gaps, thresholds de métricas, fórmulas de impacto e priorização, limites de auto-fix.

```markdown
SE algum arquivo não encontrado:
  ❌ ERRO: Arquivo de referência não encontrado
  💡 Verifique docs/knowledge-base/frameworks/framework-testes.md e test-strategy-scoring.md
```

### Passo 2: Detectar e Configurar Task Manager

**CRÍTICO:** Detectar provedor automaticamente do `.env` primeiro, depois usar fallback.

```bash
Read .env
```

**Lógica de detecção (prioridade):**

```markdown
1. SE {{task-manager}} fornecido → usar diretamente (validar: jira|clickup|asana)
2. SENÃO, TASK_MANAGER_PROVIDER do .env (clickup|asana|linear; linear → jira por compatibilidade)
3. SENÃO, inferir do formato do feature-id:
   - "CU-"/"cu-" → clickup
   - "PROJ-"/"JIRA-"/numérico → jira
   - "ASANA-"/padrão específico → asana
4. SENÃO → ❌ ERRO: configure TASK_MANAGER_PROVIDER no .env ou forneça --task-manager
```

**Validações:** feature-id não vazio; provedor detectado válido (jira|clickup|asana); abortar com erro claro se não detectado.

### Passo 3: Validar e Normalizar Parâmetros

```markdown
- feature-id: {{feature-id}} ✅ obrigatório
- task-manager: [detectado] ✅ automático
- deep-scan / auto-fix / export-report: {{valor}} ou false
```

### Passo 4: Coletar Dados do Task Manager

Seguir o padrão de integração de `/product/task` (o `.env` já foi lido no Passo 2). Para o provedor ativo, buscar:

- Epic/feature principal: nome, descrição, status, labels/tags, QA Story Points.
- Todas as subtasks relacionadas (White/Grey/Black-box): nome, status, pontos, labels, comentários.
- Acceptance criteria definidos.
- Histórico (comentários com timestamps, mudanças de status, time tracking quando disponível).

```markdown
- ClickUp: clickup_get_task / clickup_search_tasks + subtasks por parent
- Jira: epic/issue + linked issues + changelog/worklog
- Asana: asana_get_task + subtasks + stories (histórico)
```

### Passo 5: Coletar Dados do Código (se `--deep-scan`)

```bash
Glob "**/*test*.{js,ts,jsx,tsx,py}"
Glob "**/__tests__/**/*"; Glob "**/tests/**/*"; Glob "**/spec/**/*"
Glob "**/jest.config.*"; Glob "**/pytest.ini"; Glob "**/.nycrc*"
Glob "**/coverage/**/*"
Glob "**/.github/workflows/*test*.yml"; Glob "**/.gitlab-ci.yml"
```

Analisar: tipos de teste presentes (Unit/Integration/E2E) e contagem por tipo; métricas de cobertura (coverage-summary.json, lcov); quality gates e thresholds de CI/CD; histórico de falhas, testes flaky e tempo de execução.

### Passo 6: Analisar Conformidade com o Framework

Aplicar as matrizes da KB de scoring (`test-strategy-scoring.md`):

1. **QA Story Points** — comparar atribuído vs. calculado pela fórmula do framework; marcar discrepância > 20% (KB §1).
2. **Cobertura multi-perspectiva** — verificar White/Grey/Black-box e calcular score (KB §2).
3. **Conformidade com templates** — AC completos, classificação e métricas de sucesso (KB §3).
4. **Padrões de colaboração** — Three Amigos, Pair Testing, Handoff (KB §4).

### Passo 7: Detectar Gaps e Problemas

Classificar gaps usando a **matriz de detecção** (KB §5): cobertura/perspectivas faltantes, estimativas incorretas, métricas fora do threshold, técnicas inadequadas, falta de automação e debt técnico. Cada gap recebe severidade CRITICAL/HIGH/MEDIUM/LOW conforme a KB.

### Passo 8: Calcular Impacto dos Gaps

Usar as **fórmulas de impacto** (KB §6): risco de bugs em produção, eficiência perdida (horas por gap), score de qualidade (base 100 com penalidades) e impacto na velocity.

### Passo 9: Gerar Sugestões de Melhoria

Categorizar por severidade e tipo, e priorizar pela fórmula `Prioridade = (Impacto × Severidade) / Esforço` (KB §7). Cada sugestão inclui: problema, ação específica, impacto esperado e esforço estimado (horas).

### Passo 10: Aplicar Auto-Fixes (se `--auto-fix`)

Apenas correções seguras e não-destrutivas, conforme os **limites de auto-fix** (KB §8):

- Recalcular QA Story Points quando discrepância > 20%.
- Adicionar labels/tags faltantes (perspectiva, tipo, prioridade).
- Criar subtasks para perspectivas faltantes (template do framework).
- Completar AC incompletos com o template universal.

Sempre: backup antes, log detalhado, comentário na task explicando a mudança, rollback possível. Nunca deletar tasks, modificar código de testes ou alterar histórico.

### Passo 11: Gerar Relatório Detalhado

Estruturar o relatório com: resumo executivo (score de conformidade, total de gaps por severidade, risco, impacto em horas), dados coletados (task manager + code analysis), conformidade com framework (4 dimensões do Passo 6), gap analysis por severidade, impact assessment, recomendações priorizadas, tabela Current vs Target (KB §9), auto-fixes aplicados e action items.

```bash
mkdir -p reports/test-strategy-analysis
write reports/test-strategy-analysis/analysis-[feature-id]-[YYYYMMDD-HHMM].md
```

**SE `--export-report`:** gerar também versão JSON estruturada e resumo executivo de 1 página.

### Passo 12: Apresentar Resultado Final

Saída em console com blocos: identificação da feature/provedor, data collection, framework compliance (QA points, multi-perspectiva, métricas, colaboração), gap analysis por severidade (🔴 CRITICAL / 🟡 HIGH / 🟢 MEDIUM / 🔵 LOW), impact assessment (risk level, quality score, debt), recomendações priorizadas, métricas Current vs Target, relatórios gerados e auto-fixes aplicados.

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔍 ANÁLISE DE ESTRATÉGIA DE TESTE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎯 Feature: [feature-id] - [nome]
📊 Task Manager: [provedor] (inferido do .env)

✅ Framework Compliance: QA Points [X]% | Multi-Perspective [Y]% | Métricas [Z] gaps
🔍 Gaps: 🔴 [N] CRITICAL | 🟡 [N] HIGH | 🟢 [N] MEDIUM | 🔵 [N] LOW
📊 Quality Score: [X]/100 ([classificação]) | Debt: [X]h

💡 [M] melhorias sugeridas (priorizadas por impacto/esforço)
[SE export-report:] 📄 Relatórios em ./reports/test-strategy-analysis/
[SE auto-fix:] 🔧 [N] correções aplicadas

💡 Próximos passos: revisar gaps críticos → aplicar melhorias prioritárias →
   [SE auto-fix não usado:] executar com --auto-fix → monitorar métricas
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## 📋 Exemplos de Uso

```bash
# Análise básica (provedor inferido do .env)
/test-strategy/analyze PROJ-123

# Provedor explícito (ignora .env)
/test-strategy/analyze CU-456 --task-manager clickup

# Análise profunda com auto-fix
/test-strategy/analyze TICKET-101 --deep-scan --auto-fix

# Análise completa com relatórios em múltiplos formatos
/test-strategy/analyze FEATURE-789 --deep-scan --export-report --auto-fix
```

## ⚠️ Validações e Regras

**Validações obrigatórias:**
1. Framework e KB de scoring devem existir (Passo 1) — senão abortar.
2. `feature-id` não pode estar vazio.
3. Task manager detectado e acessível — senão erro claro sugerindo `/meta/setup-integration`.
4. Epic/feature deve ser encontrado no task manager.

**Regras de negócio:**
1. **Sempre baseado em referência** — toda verificação cita seção do framework ou da KB de scoring.
2. **Auto-fix apenas seguro** — nunca mudanças destrutivas (KB §8).
3. **Priorização inteligente** — sugestões ordenadas por impacto/esforço (KB §7).
4. **Relatórios acionáveis** — ações específicas com estimativas.
5. **Preservar histórico** — nunca deletar/modificar dados históricos.

## 🔗 Referências

- **Framework canônico:** `docs/knowledge-base/frameworks/framework-testes.md`
- **Matrizes de scoring / gap analysis:** `docs/knowledge-base/frameworks/test-strategy-scoring.md`
- **Comando relacionado:** `/validate/test-strategy/create`
- **Task Manager:** `.claude/utils/task-manager/`
- **Agentes:** @test-engineer, @test-planner

---

**Versão:** 3.0.0  
**Última atualização:** 2025-12-03  
**Mantido por:** Sistema Onion
