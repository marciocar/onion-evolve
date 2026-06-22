# 🎨 Design Context — Índice

> **Última Atualização:** 2026-06-22 · **Status:** provisório (incubação do 4º peer — ver [README](README.md))

Hub navegável da identidade visual do Onion (SSOT). Spec-as-code aplicado ao design: tokens são a fonte
de verdade; CSS/componentes/material são saída gerada.

## Camadas (cascata de resolução)

| Camada | Arquivo(s) | Papel |
|--------|-----------|-------|
| **Foundations** (core) | [`foundations/color.tokens.json`](foundations/color.tokens.json) | Primitivos brand-agnostic — a paleta crua. Identidade real do Onion (#D97757 laranja, #8A2BE2 roxo). |
| **Semantic** | [`semantic/color.tokens.json`](semantic/color.tokens.json) | Papéis (`surface`, `on-surface`, `action`, `feedback`) → referenciam foundations. **Componentes consomem AQUI.** |
| **Brand** | `brands/<brand>/` | Override por marca (multi-brand; esparso). _vazio no core._ |
| **Product** | `products/<product>/` | Override por produto (herda brand). _vazio no core._ |
| **Mode** | `modes/<light\|dark\|hc>.json` | Override por modo. _a popular._ |

## Resolução

A identidade de um escopo = `merge(foundations, semantic, brand[X], product[Y], mode[Z])`, resolvida
**lazy por escopo pedido** (nunca pré-gerar a matriz). Consumo via abstração `design-sink/` (→ Tailwind
`@theme`, CSS vars, Style Dictionary).

## Governança

- **Frescor:** design estável ≠ stale (tensão T6) — threshold próprio ("bate com produção"), não os 18m
  herdados de `kb-freshness`. Auditado por `/meta:context-freshness`.
- **Gate determinístico:** `.claude/validation/lint-design-tokens.sh` valida DTCG bem-formado +
  referências resolvidas (sem órfãs/ciclos) + contraste WCAG dos pares semânticos. Logos/pixels ficam fora
  da SSOT, sob gate humano.

## Próximos (roadmap — plano `transient-cooking-pebble`)

- Fase 1: gate + sink Tailwind + dogfood (gerar tema do Onion). ◀ _em andamento_
- Fase 2: comando `/design` faseado. · Fase 3: `@design-system-specialist` + Figma/Penpot.
- Fase 4: camada generativa (`@brand-generator` + diverge/converge). · Fase 5: WCAG como guard de CI.
