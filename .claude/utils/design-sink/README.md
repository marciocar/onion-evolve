# 🎨→💻 design-sink — consumidores da SSOT de design (DTCG → formato-alvo)

Abstração **SDAAL** (irmã de `design-source/`) que traduz a SSOT de tokens (`docs/design-context/`,
W3C/DTCG) para o formato que cada alvo consome. **Anti-lock-in:** trocar o alvo = trocar `DESIGN_SINK_PROVIDER`
no `.env`; a SSOT permanece neutra. Nunca chamar a ferramenta-alvo direto no comando — sempre via o sink.

## Providers

| Provider | Saída | Status |
|----------|-------|--------|
| **`css-vars`** | `:root { --color-... }` (CSS custom properties) | ✅ implementado (`tokens-to-css-vars.sh`) — universal, zero dependência |
| `tailwind` | `@theme { --color-...: ... }` (Tailwind v4) | 🔜 spec (Fase 1+) — deriva do css-vars |
| `style-dictionary` | build multi-plataforma (CSS/TS/Swift/Kotlin) | 🔜 adapter (dependência node, opcional) |
| `artifact-design` | preview/dogfood visual via skill nativa | 🔜 |
| `none` | no-op (fallback gracioso) | ✅ |

## Resolução de cascata

O sink resolve `merge(foundations → semantic → brand[X] → product[Y] → mode[Z])` **lazy por escopo pedido**
e emite só o resultado. Aliases `{color.x.y}` são resolvidos ao valor final; o nome do token vira a
custom property em kebab-case (`color.action.primary` → `--color-action-primary`).

## Determinismo

A tradução é **determinística (sem LLM)** — é transformação de dados, não geração. O gate
`lint-design-tokens.sh` garante que a SSOT é válida (DTCG + refs + WCAG) **antes** do sink consumir.
