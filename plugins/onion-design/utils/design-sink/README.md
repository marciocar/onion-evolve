# 🎨→💻 design-sink — consumidores da SSOT de design (DTCG → formato-alvo)

**Script determinístico** (irmão de `design-source/`) que traduz a SSOT de tokens (`docs/design-context/`,
W3C/DTCG) para o formato que cada alvo consome. **Anti-lock-in:** a SSOT é W3C/DTCG — neutra por formato;
quem quiser outro alvo escreve outro conversor lendo a mesma SSOT.

> **Por que script e não SDAAL** ([abstraction-doctrine](../../../docs/knowledge-base/concepts/onion-abstraction-doctrine.md)):
> há **1 conversor real** (`css-vars`) e os demais são costura. Teste do Eixo (a) reprova — abstração de
> provider único é overhead sem ganho (whitepaper §13); e é transformação **determinística sem LLM**, que
> a régua P0-P3 manda para script (P1). **Gatilho de graduação a SDAAL:** o **2º conversor real** nascer.
> Até lá, o comando chama o script direto — o que é legítimo, não vazamento.

## Providers

| Provider | Saída | Status |
|----------|-------|--------|
| **`css-vars`** | `:root { --color-... }` (CSS custom properties) | ✅ implementado (`tokens-to-css-vars.sh`) — universal, zero dependência |
| `tailwind` | `@theme { --color-...: ... }` (Tailwind v4) | 🟡 **output de referência validado** em [`docs/materials/theme.tailwind.css`](../../../docs/materials/theme.tailwind.css) (materializado via `@design-system-specialist`, gate verde) · **adapter reutilizável 🔜** |
| `shadcn` | `:root { --background/--primary/--ring/… }` (19 vars shadcn/ui, hex v4) | 🟡 **output de referência validado** em [`docs/materials/theme.shadcn.css`](../../../docs/materials/theme.shadcn.css) (gate verde, contrastes calculados) · **adapter reutilizável 🔜** |
| `style-dictionary` | build multi-plataforma (CSS/TS/Swift/Kotlin) | 🔜 adapter (dependência node, opcional) |
| `artifact-design` | preview/dogfood visual via skill nativa | 🔜 |
| `none` | no-op (fallback gracioso) | ✅ |

> **🟡 output validado vs adapter:** `tailwind` e `shadcn` já têm **arquivos-alvo corretos e validados pelo
> gate** (servem hoje como tema pronto p/ `@import` e como *fixture* de validação). O que falta é o **script
> adapter reutilizável** (`tokens-to-tailwind.sh` / `tokens-to-shadcn.sh`, irmãos do `tokens-to-css-vars.sh`)
> para regenerar automaticamente quando a SSOT mudar — esse é o **próximo passo de transformação do core**
> (distinto de produzir mais output one-off, que é execução). Recovery point para retomar a vertical.

## Resolução de cascata

O sink resolve `merge(foundations → semantic → brand[X] → product[Y] → mode[Z])` **lazy por escopo pedido**
e emite só o resultado. Aliases `{color.x.y}` são resolvidos ao valor final; o nome do token vira a
custom property em kebab-case (`color.action.primary` → `--color-action-primary`).

## Determinismo

A tradução é **determinística (sem LLM)** — é transformação de dados, não geração. O gate
`lint-design-tokens.sh` garante que a SSOT é válida (DTCG + refs + WCAG) **antes** do sink consumir.
