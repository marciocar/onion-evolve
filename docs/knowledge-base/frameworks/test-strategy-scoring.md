---
title: Matrizes de Scoring e Gap Analysis de Estratégia de Teste
category: frameworks
status: active
version: "1.0.0"
updated: "2026-06-02"
maintained_by: Sistema Onion
related:
  - docs/knowledge-base/frameworks/framework-testes.md
  - .claude/commands/validate/test-strategy/analyze.md
  - .claude/commands/validate/test-strategy/create.md
---

# Matrizes de Scoring e Gap Analysis de Estratégia de Teste

Knowledge base de referência com as **matrizes de pontuação**, **thresholds**, **regras de detecção de gaps** e **fórmulas de impacto** usadas para auditar estratégias de teste contra o [Framework de Testes](framework-testes.md).

Esta KB é consumida pelo comando `/validate/test-strategy/analyze`. O comando atua como orquestrador e carrega estas matrizes quando precisa pontuar conformidade, classificar gaps ou estimar impacto. O **framework canônico** (perspectivas White/Grey/Black-box, fórmula de QA Story Points, técnicas, templates, padrões de colaboração) vive em [`framework-testes.md`](framework-testes.md) — esta KB **não duplica** esse conteúdo, apenas o operacionaliza para análise.

---

## 1. Validação de QA Story Points

Para cada task, comparar pontos atribuídos vs. calculados pela fórmula do framework (seção "QA Story Points - Sistema de Estimativa" em `framework-testes.md`):

```
QA Points = Complexidade Base + Risco + Tipo de Teste
```

- Complexidade Base — simples: 1-2, médio: 3-5, complexo/épico: 8-13
- Ajuste por Risco — baixo: +0, médio: +1-2, alto: +3-5
- Tipo de Teste — básico: +1, padrão: +2-3, extensivo: +4-6

**Regra de discrepância:** diferença `> 20%` entre atribuído e calculado é marcada como problema (recalcular necessário).

### Distribuição sugerida por perspectiva

| Complexidade | White-box | Grey-box | Black-box |
|--------------|-----------|----------|-----------|
| Simples/Médio | 30% | 30% | 40% |
| Complexo/Épico | 25% | 35% | 40% |

---

## 2. Score de Cobertura Multi-Perspectiva

Verifica presença e definição das 3 perspectivas (referência: seção "Diferenças entre White-box vs Black-box vs Grey-box" do framework).

| Perspectivas presentes e bem definidas | Score |
|-----------------------------------------|-------|
| Todas as 3 | 100% |
| 2 perspectivas | 67% |
| 1 perspectiva | 33% |
| Nenhuma identificada | 0% |

**Critérios por perspectiva (resumo — detalhe técnico no framework):**

- **White-box (Dev):** unit testing presente; Code Coverage e Mutation Testing; metas >80% coverage e >70% mutation; ferramentas Jest/PyTest/JUnit.
- **Grey-box (Cross-Dev):** integration testing; API Contract Testing e Fuzzing; metas >95% pass rate e 100% contract coverage; foco em contratos e fronteiras.
- **Black-box (QA):** system/acceptance testing; Partição de Equivalência e Valor Limite; metas 100% user story coverage e >85% bug detection; foco na jornada do usuário.

---

## 3. Conformidade com Templates

Checar contra o "Template Universal de Caso de Teste" e o "Caso de Teste Unificado" do framework:

1. **Acceptance criteria completos:** objetivo, pré-condições, dados de teste, passos, resultado esperado, critérios de sucesso.
2. **Classificação presente:** tipo (Unit/Integration/System/Acceptance), perspectiva (White/Grey/Black-box), prioridade, complexidade, QA Story Points, tags.
3. **Métricas de sucesso definidas:** thresholds claros, KPIs mensuráveis, critérios de aceitação.

Score de conformidade = % de itens acima satisfeitos pelas tasks analisadas.

---

## 4. Padrões de Colaboração

Buscar evidência (referência: seção "Padrões de Colaboração" do framework):

- **Three Amigos:** comentários de refinement PO+Dev+QA; AC refinados colaborativamente.
- **Pair Testing:** menção a pair testing; múltiplos owners; cross-review.
- **Handoff Protocols:** handoff Dev→QA documentado; guia "how to test"; validação de estimativas.

---

## 5. Matriz de Detecção de Gaps

### 5.1 Gaps de cobertura (perspectivas/técnicas faltantes)

| Condição | Severidade |
|----------|-----------|
| Apenas 1 perspectiva presente (faltam 2) | CRITICAL |
| Nenhuma perspectiva clara | CRITICAL |
| White-box sem Mutation Testing | MEDIUM |
| Grey-box sem API Contract Testing | HIGH |
| Black-box sem Exploratory Testing | MEDIUM |
| Sem automação onde deveria haver | HIGH |

### 5.2 Estimativas incorretas (se houver dados de tempo)

- Tempo gasto > 150% do estimado → complexidade subestimada.
- Tempo gasto < 50% do estimado → complexidade superestimada.
- QA points atribuídos ≠ calculados → recalcular.
- Padrão consistente de erro → problema de processo; variação alta → falta de padronização.

### 5.3 Métricas fora do threshold

| Métrica | OK | MEDIUM | Gap maior |
|---------|-----|--------|-----------|
| Code Coverage | > 85% | 80-85% | < 80% → **CRITICAL** |
| Integration Pass Rate | > 98% | 95-98% | < 95% → **HIGH** |
| Mutation Score | > 75% | 70-75% | < 70% → **HIGH** |
| Bug Detection Rate | > 90% | 85-90% | < 85% → **HIGH** |
| QA Estimation Accuracy | > 85% | 80-85% | < 80% → **HIGH** |

### 5.4 Outros gaps

- **Técnicas inadequadas:** White-box usando técnica de Black-box (ou vice-versa); técnica obsoleta ou fora do framework.
- **Falta de automação:** regressão/repetitivos manuais (candidatos); smoke sem automação (MEDIUM); E2E crítico sem automação (HIGH).
- **Debt técnico:** testes flaky, tempo de execução alto, cobertura baixa em área crítica, testes mal estruturados.

---

## 6. Cálculo de Impacto dos Gaps

### 6.1 Risco de bugs em produção

- CRITICAL → risco alto de bugs críticos; HIGH → médio-alto; MEDIUM → médio; LOW → baixo.
- Fatores amplificadores: cobertura insuficiente em área crítica = risco muito alto; falta de perspectiva + complexidade alta = risco alto.

### 6.2 Eficiência perdida (horas de impacto por gap)

| Severidade | Impacto estimado |
|-----------|------------------|
| CRITICAL | 8-16 h |
| HIGH | 4-8 h |
| MEDIUM | 2-4 h |
| LOW | 1-2 h |

### 6.3 Score de qualidade

Base **100 pontos**, subtrair por gap:

| Severidade | Penalidade |
|-----------|-----------|
| CRITICAL | -20 cada |
| HIGH | -10 cada |
| MEDIUM | -5 cada |
| LOW | -2 cada |

| Faixa | Classificação |
|-------|---------------|
| 90-100 | Excelente |
| 75-89 | Bom (melhorias recomendadas) |
| 60-74 | Regular (melhorias necessárias) |
| < 60 | Crítico (ação imediata) |

### 6.4 Velocity do time

Estimativas incorretas afetam planejamento; testes flaky reduzem confiança; falta de automação reduz capacidade de entrega; debt técnico acumula e reduz velocity ao longo do tempo.

---

## 7. Categorização e Priorização de Sugestões

### Severidade

- **CRITICAL** — cobertura abaixo de threshold crítico, perspectivas críticas faltando, métricas críticas não atingidas, risco alto de bugs.
- **HIGH** — estimativas incorretas afetando planejamento, falta de automação crítica, técnicas inadequadas, métricas importantes abaixo do threshold.
- **MEDIUM** — templates fora do padrão, labels/tags faltantes, técnicas não ótimas, métricas próximas do threshold.
- **LOW** — melhorias de documentação, otimizações menores, ajustes de processo.

### Tipos de sugestão

Redistribuir QA Points · Adicionar perspectiva faltante · Upgrade de técnicas · Automatizar tasks manuais · Atingir threshold de métrica · Reestruturar épico/subtasks. Cada sugestão deve incluir: problema, ação específica, impacto e esforço (horas).

### Fórmula de priorização

```
Prioridade = (Impacto × Severidade) / Esforço
```

- **Impacto:** 1-10
- **Severidade:** CRITICAL=4, HIGH=3, MEDIUM=2, LOW=1
- **Esforço:** horas estimadas

---

## 8. Limites de Auto-Fix

Auto-fixes seguros e não-destrutivos: recalcular QA Story Points (discrepância > 20%), adicionar labels/tags faltantes, criar subtasks para perspectivas faltantes, completar template de AC.

**Nunca via auto-fix:** deletar tasks, modificar código de testes, alterar estimativa com discrepância < 20%, criar tasks sem contexto, modificar histórico/comentários.

**Sempre:** gerar backup, log detalhado, comentar a mudança na task, permitir rollback.

---

## 9. Tabela Current vs Target (relatório)

| Métrica | Target |
|---------|--------|
| Unit Coverage | > 80% |
| Integration Pass Rate | > 95% |
| E2E Flakiness | < 3% |
| QA Estimation Accuracy | > 85% |
| Mutation Score | > 70% |
| Bug Detection Rate | > 85% |
