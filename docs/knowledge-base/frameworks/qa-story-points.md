---
title: Tabelas de Referência para Estimativa de QA Story Points
category: frameworks
status: active
version: "1.0.0"
updated: "2026-06-02"
maintained_by: Sistema Onion
related:
  - docs/knowledge-base/frameworks/framework-testes.md
  - docs/knowledge-base/frameworks/test-strategy-scoring.md
  - .claude/commands/validate/qa-points/estimate.md
---

# Tabelas de Referência para Estimativa de QA Story Points

Knowledge base de referência com as **tabelas determinísticas de cálculo**, **mapas de detecção de keywords**, **distribuição por perspectiva por tipo de teste** e **técnicas sugeridas por tipo** usadas pelo comando `/validate/qa-points/estimate`.

O **framework canônico** (definição conceitual das 3 dimensões, fórmula, escala de conversão para horas, padrões de colaboração) vive em [`framework-testes.md`](framework-testes.md), seção "QA Story Points - Sistema de Estimativa". A operacionalização para auditoria de estratégias está em [`test-strategy-scoring.md`](test-strategy-scoring.md). Esta KB **não duplica** o conceito — apenas fornece os valores pontuais que o comando usa para cálculo automático e reprodutível.

```
Fórmula (do framework): QA Points = Complexidade Base + Ajuste de Risco + Ajuste de Tipo
```

---

## 1. Valores Determinísticos de Cálculo

Para garantir cálculo reprodutível, o comando usa o **valor médio do range do framework, arredondado**:

### Complexidade Base

| Nível | Range (framework) | Valor usado |
|-------|-------------------|-------------|
| simple | 1-2 | 2 |
| medium | 3-5 | 4 |
| complex | 5-8 | 7 |
| epic | 8-13 | 11 |

### Ajuste de Risco

| Nível | Range (framework) | Valor usado |
|-------|-------------------|-------------|
| low | +0 | +0 |
| medium | +1-2 | +2 |
| high | +2-3 | +3 |
| critical | +3-5 | +4 |

### Ajuste de Tipo

| Tipo | Range | Valor usado |
|------|-------|-------------|
| unit | +0-1 | +1 |
| integration | +1-2 | +2 |
| api | +1-2 | +2 |
| ui | +2-3 | +3 |
| performance | +2-4 | +3 |
| e2e | +3-4 | +4 |
| security | +3-5 | +4 |
| manual | +1-3 | +2 |

### Conversão para horas

Usar a escala "QA POINTS TO TIME CONVERSION" e os "FATORES DE AJUSTE" do framework (`framework-testes.md`). Resumo: 1pt≈1-2h, 2pt≈2-4h, 3pt≈4-6h, 5pt≈6-10h, 8pt≈10-16h, 13pt≈16-24h, 20+pt → quebrar.

---

## 2. Mapa de Detecção de Keywords

Quando `complexity`, `risk` ou `type` não são fornecidos, inferir da descrição:

### Ajustes de complexidade (contextual, somam ao base)

| Keyword | Efeito |
|---------|--------|
| `multiple APIs`, `third-party integration`, `new technology` | +1 complexity |
| `legacy system` | +1 complexity, +1 risk |

### Indicadores de risco

| Keywords | Nível inferido |
|----------|----------------|
| `payment`, `gateway`, `financial`, `critical user flow`, `security`, `auth`, `authentication`, `data`, `personal`, `LGPD` | high/critical |
| `third-party service` | +1 risk |

### Inferência de tipo

| Keywords | Tipo |
|----------|------|
| `API`, `endpoint`, `contract` | integration/api |
| `form`, `button`, `UI`, `interface` | ui |
| `login`, `checkout`, `user journey`, `flow` | e2e |
| `load`, `stress`, `performance` | performance |
| `security`, `vulnerability`, `penetration` | security |
| `manual`, `exploratory` | manual |

### Defaults (sem keyword detectada)

- complexity → `medium`; risk → `medium`; type → `integration`.
- 1 keyword de complexidade → `medium`; 2+ → `complex`.

---

## 3. Distribuição por Perspectiva por Tipo de Teste

Percentuais White-box / Grey-box / Black-box usados no `--breakdown`. (A distribuição por complexidade — visão de auditoria — está em [`test-strategy-scoring.md`](test-strategy-scoring.md) §1.)

| Tipo | White-box | Grey-box | Black-box |
|------|-----------|----------|-----------|
| unit | 70% | 20% | 10% |
| integration | 30% | 60% | 10% |
| api | 40% | 50% | 10% |
| ui | 20% | 30% | 50% |
| e2e | 10% | 30% | 60% |
| performance | 30% | 40% | 30% |
| security | 25% | 35% | 40% |

---

## 4. Técnicas Sugeridas por Tipo de Teste

Usadas no `--suggest-techniques`. Detalhe técnico de cada técnica está no framework (`framework-testes.md`, seção "Padrões de Teste por Perspectiva").

| Tipo | Técnicas |
|------|----------|
| unit | TDD, Mutation Testing, Code Coverage Analysis, Behavior-Driven Testing |
| integration | Contract Testing (Pact), API Mocking (Wiremock), Database Testing, Fuzzing de API |
| ui | Page Object Model, Visual Testing, Accessibility Testing, Cross-browser Testing |
| api | Schema Validation, Error Handling Testing, Rate Limiting Testing, Contract Testing |
| e2e | User Journey Mapping, Browser Testing (Cypress/Selenium), Acceptance Testing |
| performance | Load Testing, Stress Testing, Profiling, Performance Monitoring |
| security | Penetration Testing, OWASP Guidelines, Vulnerability Scanning, Security Audit |
| manual | Exploratory Testing, Usability Testing, Session-Based Testing |

---

## 5. Validações e Anti-Patterns

### Valores válidos

- complexity ∈ {simple, medium, complex, epic} — inválido → auto-detect.
- risk ∈ {low, medium, high, critical} — inválido → auto-detect.
- type ∈ {unit, integration, ui, api, e2e, performance, security, manual} — inválido → auto-detect.

### Anti-patterns

- **Total > 13 pontos** → alertar (épico de teste); recomendar quebra em múltiplas tasks.
- **type=unit + risk=critical** → inconsistência provável; verificar tipo.
- **type=manual + complexity=epic** → considerar automação ou quebra.
