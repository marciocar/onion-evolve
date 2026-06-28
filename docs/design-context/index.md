# 🎨 Design Context — Índice

> **Última Atualização:** 2026-06-24 · **Status:** provisório (incubação do 4º peer — ver [README](README.md))

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

## Roadmap (plano `transient-cooking-pebble`)

**Entregue (em main):**
- ✅ **Fase 1** (`gate+sink`): `lint-design-tokens.sh` + `design-sink/` Tailwind + dogfood (tema do Onion). _PR #143_
- ✅ **Fase 2** (`comando+specialist`): comando `/design:identity` + `@design-system-specialist` (puxado da F3). _PR #145_

- ✅ **Fase 5** (`wcag-guard-ci`): contraste WCAG como guard de CI bloqueante (`onion-validate.yml` roda `lint-design-tokens.sh` em `docs/design-context/**`). _PR #150_
- ✅ **Fase 3** (`fontes-externas`): abstração SDAAL de ingestão `design-source/` (irmã do `design-sink/`) — adapter `file` funcional (paleta flat → DTCG, round-trip validado no gate); `figma`/`penpot` como **costura** (sem ferramenta viva p/ dogfoodar). _PR #151_

- ✅ **Fase 4** (`brand-generator`): camada generativa via orquestração — comando `/design:generate` + agente `@brand-generator` (diverge N paletas em paralelo → converge pelo gate WCAG + juiz). A IA gera, o gate decide. _PR #152_

**Roadmap completo.** Fases pendentes viram gatilho-de-evidência, não trabalho aberto:
- ⏳ Adapters `figma`/`penpot` (costura da F3) entram com ferramenta viva para dogfoodar.
- ⏳ Promoção a 4º peer pleno (ADR provisório) pende de ritmo-de-mudança distinto observável (adotante populando contextos / 2ª marca real exercitando a cascata).
- 💡 Ideia: `/design:evolve` — faceta de `/meta:evolve` que audita drift visual.
