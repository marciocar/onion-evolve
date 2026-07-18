---
title: 'Signal: redogfood kg-sdaal — validação de rastreabilidade incompleta'
date: 2026-07-17
from: granaai (consumidor / adopted @ fb08cc6be4ad)
to: core (onion-evolve)
type: field-signal-discovery
flow: upstream (consumidor→core / learning de engenharia)
severity: MEDIUM (architectural insight + generator improvement)
---

# Signal — Redogfood KG-SDAAL: Validação de Rastreabilidade Incompleta

## Contexto

Executamos **redogfood** do `.kg.yaml` gerado (107 nós, 154 arestas, Fable 5) — ou seja, validamos o próprio KG contra o padrão SDAAL que ele implementa. Achados: integridade técnica perfeita, **mas breadcrumbs SDAAL (rastreabilidade decisões→nós) orphaned**.

## Status Geral

**✅ Validação SDAAL: PASSA (integridade técnica 100%)**
- Meta conforme (v2.0, standard=SDAAL, adoption_mode=regulated)
- 107 nós com tipos válidos
- 154 arestas tipadas (REALIZES, IMPLEMENTS, DEPENDS_ON, CONTROLLED_BY)
- Evidence 100% (todos nós linkam artefatos reais)
- 0 ciclos, 0 órfãos, 0 arestas inválidas

**❌ Breadcrumbs SDAAL: 60% completo (gaps críticos em rastreabilidade)**

## Achados Críticos

### 🔴 **F1: TRACES_TO Desconectado (CRITICAL)**

| Métrica | Valor | Esperado | Gap |
|---------|-------|----------|-----|
| TRACES_TO (nó → decision) | **0** | 10 | 10 (100% ausente) |

**Impacto**: Nenhuma das 10 decisions (ADRs) está linkada a nós que ela justifica.

**Exemplo**:
```
app:api-cerc 
  → IMPLEMENTS capability:registro-recebiveis
  → REALIZES domain:antecipacao-recebiveis
  ❌ X TRACES_TO decision:adr-001 (Monorepo NX — que justifica por que api-cerc existe em server/cerc)
```

**Recomendação ao core**: O `/meta:kg` generator deveria extrair `TRACES_TO` automaticamente por:
- Parsing ADRs (docs/technical-context/adr/) e extração de "afeta quais apps/libs?"
- Linking nós → ADRs que os justificam

### 🔴 **F2: CONTROLLED_BY Incompleto (MEDIUM)**

| Métrica | Valor | Esperado | Gap |
|---------|-------|----------|-----|
| CONTROLLED_BY (nó → control) | 21 | ~45 | ~24 (47% ausente) |

**Não linkadas**: 15 capabilities (registro-recebiveis, antecipacao, liquidacao, garantia-locaticia, onboarding-self-service, originacao-credito, gestao-emprestimos, dashboard-whitelabel, portal-desenvolvedor, billing, processamento-jobs, eventos-webhooks, assinatura-digital, administracao, multi-tenancy)

**Impacto**: Audit trail invisível (capability → controles SOC2/segurança não mapeados).

**Recomendação ao core**: Mapear capabilities → controles via:
- Parsing compliance docs (docs/compliance/soc2/, iso-27001/, etc.)
- Inferência automática (billing → rate-limiting, antecipacao → audit-trail, etc.)

### 🟡 **F3: DEPENDS_ON Parcial (MEDIUM)**

| Métrica | Valor | Esperado | Gap |
|---------|-------|----------|-----|
| DEPENDS_ON | 77 | ~90 | ~13 (85%) |

**Impacto**: Mapeamento de dependências incompleto entre apps/libs/integrações.

---

## Dados Estruturados (Validação)

```json
{
  "validation_sdaal": {
    "meta_conform": true,
    "nodes_typed": true,
    "evidence_linking": "100% (107/107)",
    "edge_type_rules": "100%",
    "cycles": 0,
    "orphans": 0,
    "invalid_edges": 0
  },
  "breadcrumbs_sdaal": {
    "traces_to": { "count": 0, "expected": 10, "gap": 10, "status": "CRITICAL" },
    "controlled_by": { "count": 21, "expected": 45, "gap": 24, "status": "MEDIUM" },
    "depends_on": { "count": 77, "expected": 90, "gap": 13, "status": "MEDIUM" }
  },
  "recommendation": "Melhorar /meta:kg generator para capturar TRACES_TO + CONTROLLED_BY automaticamente"
}
```

---

## Recomendação Estruturante (ao Core)

### Problema Raiz
O `/meta:kg` generator não está capturando breadcrumbs SDAAL completos:
- **TRACES_TO**: nenhuma decision linkada (nós justificados)
- **CONTROLLED_BY**: 47% das nós sem linking a controles (audit trail incompleto)

### Solução Proposta (Fase Mejora)
1. **Extração automática TRACES_TO** — parser de ADRs + matching nós afetadas
2. **Extração automática CONTROLLED_BY** — parser de compliance docs + inferência semântica
3. **Validação periódica** — rodar kg-radar com breadcrumb checks (não apenas integridade técnica)

### Impacto Esperado
- ✅ KG 100% validável para audits/compliance
- ✅ Rastreabilidade decisões→nós visível e auditável
- ✅ Spec-as-code pronto para automação (policy enforcement, impact analysis)

---

## Artefatos

- **KG gerado**: `granaai/.kg.yaml` (1565 linhas, v2.0 SDAAL)
- **Relatório de validação**: `granaai/kg-validation-report.json`
- **Achados**: este sinal

---

**Este learning beneficia o core**: o padrão SDAAL é forte em integridade técnica, mas breadcrumbs rastreáveis (TRACES_TO, CONTROLLED_BY) são o "pulo do gato" para auditabilidade. A melhoria proposta faria KG uma SSOT não só válida, mas **verificável e auditável automaticamente**.

Esperamos feedback do core sobre priorização desta mejora no `/meta:kg` generator.
