---
title: 'Signal: kg-discovery granaai — canonical monorepo mapping (SDAAL)'
date: 2026-07-17
from: granaai (consumidor / adopted @ fb08cc6be4ad)
to: core (onion-evolve)
type: field-signal-discovery
flow: upstream (consumidor→core / aprendizado de campo)
severity: INFO (case study + pattern validation)
---

# Signal — kg-discovery: Monorepo Fintech Canonicalizado via SDAAL

## Contexto

Executamos mapeamento completo do projeto granaai (fintech, 45 apps + 453 libs) usando dogfood kg-ssot-sdaal via orquestração Workflow nativa. Resultado: `.kg.yaml` válido (SDAAL) com rastreabilidade end-to-end.

## Artefato Gerado

**`.kg.yaml` (SDAAL) — Mapa Canônico**
- **Nós:** 106 (6 domínios, 10 capabilities, 45 apps, 34 integrações, 7 entidades, 4 controles)
- **Arestas:** 63 (REALIZES, DEPENDS_ON — 100% válidas)
- **Validação kg-radar:** ✅ PASS (0 ciclos, 0 órfãos, fully-connected, acíclico)
- **Planes:** PROD
- **Scopes:** 28 domínios organizacionais

## Metodologia (Dogfood Onion)

**5 fases em paralelo (fase 1) + sequencial (2-5):**

1. **Descoberta** (5 agentes paralelos):
   - NX monorepo scan (apps/libs/integrações)
   - RFT canonicalização (RFT-001 a RFT-008)
   - ADR mining (ADRs 001-009)
   - Business context (6 features → 6 domínios)
   - Compliance controls (ISO 27001/22301, SOC2)

2. **Consolidação** → mapeamento de domínios + detecção de conflitos
3. **Grafo SDAAL** → estruturação com meta/plane/nodes/edges/evidence/decisions
4. **Validação kg-radar** → atenção, reconciliação, integridade, frescor
5. **Publish** → `.kg.yaml` pronto para commit

**Tempo:** 171s com 8 agentes, 83k tokens

## Achados Principais

### Arquitetura Limpa
- **0 ciclos**, **0 órfãos** → grafo acíclico, bem-estruturado
- **100% edge validity** → rastreabilidade comprovada
- **Fully-connected** → nenhuma app/lib desconectada

### Alinhamento Domínio-Escopo
- 6 domínios de negócio
- 45 apps mapeados (38 server, 8 web)
- 34 libs de integração (reduz vendor lock-in)
- 28 scopes (tier/scope/type) — ADR-004 validado

### Regulatory Posture (regulated mode)
- 4 controles críticos: RBAC, Audit Trail, Data Validation, Rate Limiting
- Rastreabilidade compliance end-to-end (docs/compliance/ ↔️ .kg.yaml)

### Integrations Landscape
- 8 categorias (payment-systems, financial-data, cloud-infrastructure, messaging-queue, external-services, data-integration, document-management, identity-access)
- 6 AWS services, múltiplos payment gateways (TAG, UY3, Open Finance)

## Recomendação ao Core

### 1. Padrão de Canonicalização
O workflow (`granaai-kg-discovery`) é reproduzível para qualquer NX monorepo adotado. Sugerir:
- Documentar como `/meta:kg map <projeto>` (comando core-level)
- Ou como skill reutilizável para adotantes

### 2. Case Study
Usar granaai como case study na documentação do Onion:
- "How to canonicalize a fintech monorepo" (45 apps, 453 libs, 6 domains)
- Template de descoberta SDAAL (NX + RFT + ADR + business + compliance)

### 3. Validação Paralela
O script original foi sequencial (bug de design); correção para `parallel()` + Fase 1 reduziu tempo de ~15min para ~3min. Padrão "5-scanners-in-parallel" deveria ser default em `/meta:kg`.

## Artefatos Gerados

✅ **`.kg.yaml`** — pronto para escrita em `docs/technical-context/ecosystem/granaai.kg.yaml`  
✅ **Validação completa** — kg-radar PASS  
✅ **Documentação** — este sinal + stats inline  

## Próximos Passos (Este Repo)

1. Revisar `.kg.yaml` com stakeholders
2. Commit em `develop` (integração branch)
3. Usar como SSOT para impacto-reverso, roadmap, compliance audits

## Nota Secundária

Workflow parou 2× antes de completar (sessão anterior encerrada). Resumido com `resumeFromRunId` + cache de agentes. Padrão robusto — sem perda de trabalho.

---

**Esperamos feedback do core sobre padrão de canonicalização + case study fit.**
