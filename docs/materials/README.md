# Materiais Derivados — Sistema Onion

> Esqueletos de materiais externos gerados na **Fase 4** do plano de identidade e produto.
> Fonte primária de todos eles: [Onion: Identidade e Produto](../knowledge-base/meta/onion-framework-identity.md) (SSOT canônica, Fase 3).

**Status:** Esqueletos produzidos (Fase 4 — 2026-06-15) · Prontos para refinamento/finalização
**Material bruto (profundidade):** [onion-product-material-raw-2026-06.md](../analysis/onion-product-material-raw-2026-06.md)

---

## Mapa de Materiais

| Material | Arquivo | Alimentado por (seções da KB) | Próximo passo |
|---|---|---|---|
| 🌐 Landing Page | [landing-page.md](./landing-page.md) | §1 (O que é), §2 (Problema), §4 (Capacidades), §9 (Citações) | Copy final + design |
| 📖 Manual (sumário) | [manual-toc.md](./manual-toc.md) | §3 (Arquitetura), §4 (Capacidades) + `docs/onion/` | Redigir caps 🔲 (6 e 7) |
| 📊 Case Studies | [case-studies.md](./case-studies.md) | §5 (Casos de Uso) + material bruto | Versões de 1-pager por caso |
| 📰 Artigo Crítico | [critical-article-outline.md](./critical-article-outline.md) | §2, §7 (Posicionamento) + material bruto | Redigir artigo completo |
| 🗂️ Press Kit | [press-kit.md](./press-kit.md) | §6 (Métricas), §8 (FAQ), §9 (Citações) | Validar com stakeholders |

---

## Como usar estes materiais

### Para copywriters / designers (landing page)
Leia `landing-page.md` — cada seção tem headline proposta, bullets de mensagens-chave e nota de elemento visual. O trabalho é transformar os bullets em copy de marketing acabado, mantendo rastreabilidade à KB-fonte. Antes de publicar, valide contagens (82/49/5/34) contra `/meta:inventory`.

### Para redatores técnicos (manual)
Leia `manual-toc.md` — o TOC já mapeia quais capítulos têm conteúdo existente em `docs/onion/` (✅) vs quais precisam ser escritos do zero (🔲). Há apenas 2 capítulos 🔲 (Task Manager & Forge Adapters, e Orquestração de Frota) — os demais já têm fontes reaproveitáveis.

### Para jornalistas / analistas (press kit + artigo crítico)
Leia `press-kit.md` para o one-pager e FAQ de imprensa, depois `critical-article-outline.md` para os ângulos críticos e as perguntas difíceis que valem apuração. O artigo crítico foi intencionalmente balanceado: força e limitações com a mesma honestidade.

### Para vendas / eventos (case studies)
Leia `case-studies.md` — 3 estudos desenvolvidos (Federation v2, `/meta:evolve`, Cursor→Native + Agent Teams) com estrutura Contexto/Abordagem/Resultado/Lição. Para slides: extrair Contexto + Resultado + Citação de cada caso.

---

## Hierarquia de fontes

```
KB canônica (SSOT)
└── docs/knowledge-base/meta/onion-framework-identity.md  ← síntese (381 linhas)
    └── Alimenta todos os 5 materiais desta pasta

Material bruto (profundidade)
└── docs/analysis/onion-product-material-raw-2026-06.md   ← 422 linhas, narrativa completa
    └── Alimenta case-studies.md e critical-article-outline.md (profundidade narrativa)

Docs operacionais (conteúdo reaproveitável)
└── docs/onion/                                            ← 15 arquivos
    └── Alimenta manual-toc.md (caps ✅)
```

---

## Relação com a KB fonte

| Seção KB | Material(is) que alimenta |
|---|---|
| §1 O que é o Onion | landing-page.md (hero + boilerplate), press-kit.md (bio) |
| §2 O Problema | landing-page.md (seção problema), critical-article-outline.md |
| §3 Arquitetura | manual-toc.md (estrutura de caps), landing-page.md (como funciona) |
| §4 Capacidades | landing-page.md (feature grid), manual-toc.md |
| §5 Casos de Uso | case-studies.md (fonte primária dos 3 casos) |
| §6 Métricas | press-kit.md (one-pager), landing-page.md (prova social) |
| §7 Posicionamento | critical-article-outline.md (análise comparativa) |
| §8 FAQ | press-kit.md (FAQ imprensa), landing-page.md (FAQ teaser) |
| §9 Citações-chave | press-kit.md, landing-page.md (prova social), case-studies.md |

---

**Mantido por:** Sistema Onion · **Última atualização:** 2026-06-15
