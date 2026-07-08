---
name: analyze-pain-price
description: |
  Análise de Dor e Precificação do Cliente.
  Executa análise profunda de dores e precificação estratégica via @pain-price-specialist.
model: sonnet
allowed-tools: Read Glob
category: product
tags: [pain, pricing, discovery, value]
version: "3.0.0"
updated: "2026-06-02"
related_agents:
  - pain-price-specialist
---

# Análise de Dor e Precificação do Cliente

Orquestrador que prepara contexto e delega ao agente `@pain-price-specialist` para análises profundas de dores do cliente e precificação estratégica.

> **Comunicação:** siga a convenção padrão do Sistema Onion (pt-BR, linguagem natural, sem citar nomes de ferramentas). Ver skill `onion-patterns`.

---

## 🎯 Propósito

Wrapper otimizado para `@pain-price-specialist`. Em vez de invocar o agente diretamente, este comando:

- Identifica o **tipo de análise** solicitada
- Carrega contexto de negócio relevante de `docs/business-context/`
- Seleciona métodos apropriados a partir da KB de referência
- Garante a geração de relatório estruturado em `docs/reports/pain-price/`

**Frameworks e métodos** (JTBD, Value Proposition Canvas, Customer Development, SPIN, 5 Porquês, Value-Based Pricing, WTP/Van Westendorp, Outcome-Based, matriz de priorização etc.) NÃO são duplicados aqui — estão na KB:
`docs/knowledge-base/concepts/identificar-precificar-dor-cliente.md`

---

## 📋 Processo

### 1. Identificar tipo de análise

| Tipo | Indicador | Contexto a carregar |
|------|-----------|---------------------|
| **A — Cliente específico** | menciona empresa/cliente nominal | `CUSTOMER_PERSONAS.md`, `CUSTOMER_JOURNEY.md` |
| **B — Segmento/persona** | menciona segmento, sem cliente nominal | `CUSTOMER_PERSONAS.md`, `CUSTOMER_JOURNEY.md`, `VOICE_OF_CUSTOMER.md` |
| **C — Validação de proposta de valor** | menciona preço/proposta atual a validar | `PRODUCT_STRATEGY.md`, `SALES_PROCESS.md`, `COMPETITIVE_LANDSCAPE.md` |
| **D — Comparativa** | menciona múltiplos cenários/modelos | `COMPETITIVE_LANDSCAPE.md` + repetir invocação por cenário |

### 2. Preparar contexto

1. Ler a KB de referência e selecionar os métodos mais adequados ao caso.
2. Carregar em paralelo os arquivos de `docs/business-context/` relevantes ao tipo (tabela acima); seguir com os existentes e avisar sobre faltantes.
3. Se faltar contexto mínimo, fazer perguntas de elucidação padronizadas:
   - **Cliente:** segmento (Startup/PME/Enterprise), persona, contexto atual.
   - **Dor:** problema principal, como resolve hoje, impacto financeiro/temporal, urgência.
   - **Preço:** valor percebido, disposição a pagar, alternativas e seus preços.

   Não invocar o agente sem contexto mínimo nem assumir dados sobre o cliente.

### 3. Invocar o agente

```
@pain-price-specialist [contexto consolidado] + [solicitação do usuário]
```

Para o Tipo D, invocar uma vez por cenário e consolidar.

### 4. Validar e apresentar

- Confirmar que o relatório foi criado em `docs/reports/pain-price/*-report.md` (criar diretório/solicitar explicitamente se ausente).
- Validar completude das seções e cálculos.
- Apresentar resumo: dores priorizadas, recomendação de precificação, próximos passos, e caminho do relatório.

---

## 💡 Diretrizes

- **Fazer:** identificar o tipo antes de invocar; carregar contexto em paralelo; estruturar o contexto de forma clara; validar o relatório antes de apresentar.
- **Evitar:** invocar sem contexto mínimo; fornecer contexto genérico demais; assumir que o relatório foi gerado sem verificar; especificar métodos sem justificativa.
- **Boa solicitação:** específica, com cliente/segmento, objetivo e proposta de valor/preço quando houver.

---

## 📊 Estrutura do relatório (gerada pelo agente)

`docs/reports/pain-price/*-report.md` contém: Resumo Executivo · Análise de Dores (priorizadas, com métodos) · Análise de Precificação (valor percebido, método, estrutura, comparação competitiva) · Recomendações Estratégicas (produto/vendas/CS) · Métricas & KPIs · Próximos Passos.

---

## 🔧 Casos de uso

```bash
# Tipo A — cliente específico
/product/analyze-pain-price Analise a dor do cliente TechStartup que precisa de certificação ISO 27001

# Tipo B — segmento
/product/analyze-pain-price Analise dores das startups que buscam capacitação em compliance

# Tipo C — validação de proposta
/product/analyze-pain-price Valide se R$ 1.000 está alinhado com a dor dos clientes startups

# Tipo D — comparativa
/product/analyze-pain-price Compare precificação fixa vs outcome-based para enterprise
```

**Exemplo de saída (Tipo A):**

```markdown
## 📊 Análise — TechStartup
Dores priorizadas:
1. Falta de certificação ISO 27001 (Score 75) — bloqueio p/ investimento, urgência alta
2. Equipe sem capacitação (Score 60) — riscos de segurança, urgência média

Precificação:
- Atual: R$ 1.000 fixo (adequado p/ MVP)
- Recomendado (Enterprise): R$ 5.000 base + R$ 2.000 se certificação obtida (outcome-based)

Próximos passos: apresentar proposta outcome-based · validar WTP · contrato com métricas de sucesso
📄 docs/reports/pain-price/*-report.md
```

---

## 📚 Referências

- **KB (frameworks/métodos):** `docs/knowledge-base/concepts/identificar-precificar-dor-cliente.md`
- **Contexto de negócio:** `docs/business-context/` (`CUSTOMER_PERSONAS`, `CUSTOMER_JOURNEY`, `VOICE_OF_CUSTOMER`, `PRODUCT_STRATEGY`, `SALES_PROCESS`, `COMPETITIVE_LANDSCAPE`)
- **Agente:** `@pain-price-specialist`
- **Relacionados:** `@product-agent`, `/product/spec`, `/product/task`
