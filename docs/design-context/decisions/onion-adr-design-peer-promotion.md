---
title: 'ADR — promoção de design-context a 4º contexto peer (PROPOSTO / provisório)'
status: proposto
date: 2026-06-22
deciders: maestro + sessão de evolução
context_freshness: 2026-06-22
related: [docs/meta-specs/architecture.md §8, transient-cooking-pebble (plano), tensão T1]
---

# ADR — design-context como 4º contexto peer

> **Última Atualização:** 2026-06-22 · **Status: PROPOSTO (provisório).** Esta decisão **não** crava a
> constituição ainda — documenta por que esperamos, e o gatilho que dispara o PR formal à meta-spec.

## Contexto

O plano `transient-cooking-pebble` cria a vertical de design com `docs/design-context/` candidato a **4º
peer** (ao lado de business/technical/compliance). A meta-spec `architecture.md §8` exige, para promover a
peer: **dono distinto × ritmo de mudança distinto × decisão distinta que informa** — *juntos*, nunca por
organograma. A tensão T1 alertou: não cravar antes de evidência empírica.

## Evidência coletada (2026-06-22)

**Frescor (`/meta:context-freshness`, régua de contexto):** `design-context` = **CURRENT** — fiel à
realidade (cores reais #D97757/#8A2BE2 ancoradas nos badges do README; sem invenção apresentada como fato).
É estruturalmente um contexto de domínio válido. _Achado T6:_ o threshold de 18 meses herdado de
`kb-freshness` **não se aplica** a tokens (design estável ≠ stale) — precisa de threshold próprio.

**Critério §8, item por item:**
| Critério | Veredito | Base |
|----------|----------|------|
| Dono distinto | ✅ argumentável | papel design/brand ≠ PM/eng/compliance (como compliance, o papel é distinto mesmo se a pessoa acumula) |
| Decisão distinta que informa | ✅✅ **forte, já evidenciado** | o conteúdo criado (tokens, cascata multi-brand, regras WCAG) **não cabe** em business (mercado/persona), technical (stack/arquitetura) nem compliance (paleta/tipografia não é compliance) — e os três o **consomem** |
| Ritmo de mudança distinto | ⏳ **não mensurável no framework** | medição objetiva: business/technical/compliance-context têm **0 arquivos de conteúdo** (são templates no framework); ritmo só existe em **projeto adotante** que os popula. Não há série temporal para comparar |

## Decisão

**Manter `design-context` como peer PROVISÓRIO** (vive em `docs/`, entrega valor, mas **sem** PR à meta-spec
§1.3/§7/§8 e **sem** alterar o pitch "3 dimensões" em CLAUDE.md/README/identity).

**Justificativa:** 2 dos 3 critérios §8 já estão evidenciados (dono + decisão distinta). O 3º (ritmo) é
**temporal e contextual** — só observável onde os contextos têm conteúdo vivo. Cravar a constituição com 1/3
critérios immensuráveis seria promover por organograma, o que o §8 proíbe explicitamente.

## Gatilho de promoção (quando cravar a Fase 0)

Disparar o PR constitucional quando **qualquer** um ocorrer:
1. **Adotante popula os contextos** e o git mostra `design-context` mudando em cadência própria (rebrand /
   novo produto) **independente** de business/technical/compliance — evidência direta de ritmo distinto.
2. **A identidade do próprio Onion evolui** ao longo das Fases 2-5 mostrando design-context com histórico de
   mudança desacoplado dos demais.
3. Um **2º produto/marca** exercita a cascata (`brands/`, `products/`) — prova que a dimensão multi-brand é
   real, não hipotética.

Até lá: provisório. Na promoção, tratar também o **T6** (threshold de frescor próprio para design).

## Consequências

- ✅ Valor da vertical (SSOT, gate, sink, comando) é entregue sem risco constitucional.
- ✅ A decisão de mexer na identidade canônica fica ancorada em evidência, não em entusiasmo.
- ⚠️ `design-context` carrega o rótulo "provisório" até o gatilho — aceitável (o README já o declara).
