# 🧅 Onion — Brand Book

> **Material on-brand gerado da SSOT** (`docs/design-context/`) — Fase 3 de `/design:identity`.
> Não edite valores aqui à mão: a fonte de verdade são os tokens DTCG. Regenere a partir deles.
> Contrastes abaixo são **calculados** (WCAG 2.1), não estimados.

## Personalidade

**Confiável · Estruturado · Modular · Transparente.** Ferramenta séria, feita por e para engenheiros —
clareza e consistência acima de ornamento. Ver [`brief.md`](../design-context/brief.md).

## Paleta de marca

| Papel | Cor | Hex | Origem |
|---|---|---|---|
| **Primária** (ação/CTA) | 🟧 laranja-quente | `#D97757` | Badge "Claude Code" do README |
| **Acento** (família) | 🟪 roxo médio | `#8A2BE2` | Badge "família Onion" do README |

**Hierarquia:** o laranja ancora a plataforma e é a ação primária; o roxo é acento/identidade da família e
**nunca concorre com o laranja em CTA**.

## Neutros (escala quente)

| Token | Hex | Uso |
|---|---|---|
| `neutral.0` | `#FFFFFF` | Superfície base (light) |
| `neutral.50` | `#F7F6F4` | Fundo secundário / cards |
| `neutral.100` | `#ECE9E4` | Fundo mudo |
| `neutral.300` | `#C9C3BA` | Bordas / divisores |
| `neutral.500` | `#8A8378` | Texto desabilitado |
| `neutral.700` | `#4A453E` | Texto secundário |
| `neutral.900` | `#1A1714` | Texto principal (quase-preto quente) |

## Papéis semânticos (camada de consumo)

> Componentes consomem **estes papéis**, nunca o primitivo cru.

| Papel | → Alias | Valor |
|---|---|---|
| `surface.base` | `{neutral.0}` | `#FFFFFF` |
| `surface.subtle` | `{neutral.50}` | `#F7F6F4` |
| `surface.muted` | `{neutral.100}` | `#ECE9E4` |
| `on-surface.strong` | `{neutral.900}` | `#1A1714` |
| `on-surface.muted` | `{neutral.700}` | `#4A453E` |
| `action.primary` | `{brand.orange}` | `#D97757` |
| `action.on-primary` | `{neutral.900}` | `#1A1714` |
| `action.accent` | `{brand.purple}` | `#8A2BE2` |
| `feedback.success` | `{green.500}` | `#3FB950` |
| `feedback.info` | `{blue.500}` | `#3B82F6` |
| `feedback.danger` | `{red.500}` | `#E5484D` |
| `feedback.warning` | `{amber.500}` | `#E0A020` |

## Contraste WCAG (calculado — `lint-design-tokens.sh`)

| Par | Razão | AA texto normal (≥4.5) | AA texto grande/UI (≥3.0) |
|---|---:|:---:|:---:|
| Texto principal sobre fundo | **17.85:1** | ✅ | ✅ |
| Texto secundário sobre fundo | **9.49:1** | ✅ | ✅ |
| Texto principal sobre `surface.subtle` | **16.53:1** | ✅ | ✅ |
| Texto principal sobre `surface.muted` | **14.74:1** | ✅ | ✅ |
| Acento (roxo) sobre fundo | **5.96:1** | ✅ | ✅ |
| **Texto escuro sobre CTA laranja** | **5.72:1** | ✅ | ✅ |

## Do / Don't

✅ **Do**
- Use `action.on-primary` (**texto escuro `#1A1714`**) no CTA laranja — **5.72:1**, AA-normal pleno em
  qualquer tamanho. O gate exige `min 4.5` para esse par.
- Use `on-surface.strong` para corpo de texto (17.85:1 — folga enorme).
- Use o roxo como acento/destaque (links, badges, realces) — 5.96:1 sobre fundo claro é seguro.
- Consuma sempre os **papéis semânticos**, regenere o `theme.css` pelo sink.

❌ **Don't**
- **Não** ponha branco sobre o laranja (3.12 < 4.5 — falha AA-normal; o gate barra). O `on-primary` é
  escuro de propósito.
- **Não** use o roxo como ação primária (ele é acento; o laranja é o CTA).
- **Não** edite o `theme.css` à mão — é saída gerada.
- **Não** introduza cor fora da escala sem passar pelo gate.

## Uso do tema

```html
<link rel="stylesheet" href="theme.css">
```
```css
.btn-primary {
  background: var(--color-action-primary);   /* #D97757 */
  color:      var(--color-action-on-primary); /* #1A1714 — texto escuro, AA-normal pleno */
}
.link-accent { color: var(--color-action-accent); }  /* #8A2BE2 */
body {
  background: var(--color-surface-base);
  color:      var(--color-on-surface-strong);
}
```

## Regenerar

```bash
bash .claude/validation/lint-design-tokens.sh           # gate (obrigatório)
bash .claude/utils/design-sink/tokens-to-css-vars.sh > docs/materials/theme.css
```

---
> Fonte: `docs/design-context/{foundations,semantic}/color.tokens.json` + `brief.md`.
> Gerado em 2026-06-24 (Fase 3 — `/design:identity` core).
