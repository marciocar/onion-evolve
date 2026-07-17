# 🎨←🌐 design-source — produtores da SSOT de design (formato-externo → DTCG)

**Script determinístico** (irmão de `design-sink/`) que **ingere** identidade visual de uma fonte externa e a
normaliza para a SSOT de tokens (`docs/design-context/`, W3C/DTCG). É o lado de **entrada** da vertical de
design; o `design-sink/` é o lado de **saída** (DTCG → formato-alvo). **Anti-lock-in:** a SSOT é W3C/DTCG —
neutra por formato; outra fonte = outro ingestor lendo/escrevendo a mesma SSOT.

> **Por que script e não SDAAL** ([abstraction-doctrine](../../../docs/knowledge-base/concepts/onion-abstraction-doctrine.md)):
> há **1 ingestor real** (`file`); `figma`/`penpot` são costura. Teste do Eixo (a) reprova — provider único
> é overhead sem ganho (whitepaper §13); e a transformação é **determinística sem LLM** → script (P1).
> **Gatilho de graduação a SDAAL:** o **2º ingestor real** nascer.

```
  fonte externa ──source──▶  docs/design-context/  ──sink──▶  formato-alvo
  [figma|penpot|file]          (SSOT, W3C/DTCG)              [css-vars|tailwind|…]
                                     ▲
                              lint-design-tokens.sh (gate F5: DTCG+refs+WCAG)
                              valida a SSOT entre o source e o sink
```

## Providers

| Provider | Entrada | Status |
|----------|---------|--------|
| **`file`** | paleta "flat" `{nome: "#hex"}` (chaves pontilhadas → aninhamento) | ✅ implementado (`file-to-tokens.sh`) — universal, zero dependência de rede |
| `figma` | Figma API — color styles do arquivo | 🔜 costura (sem ferramenta viva p/ dogfoodar; ver nota) |
| `penpot` | Penpot API/export | 🔜 costura |
| `none` | no-op (fallback gracioso) | ✅ |

> **Por que figma/penpot são costura, não stub vazio.** O adapter `file` é dogfoodável **agora** (a própria
> paleta do Onion é o caso de teste). Implementar figma/penpot **sem** um arquivo/token vivo seria o
> "dogfood-vazio" que a doutrina condena (KB `onion-dogfooding-doctrine`) e que o ADR de promoção-peer
> nomeia como gatilho ainda não atingido. A interface fica **pronta** (todo adapter emite DTCG em STDOUT);
> o provider concreto entra quando houver um caso real para exercitá-lo — mesma costura de
> `gitlab`/`bitbucket` no `forge/`.

## Contrato do adapter (interface SDAAL)

Todo source adapter — `file` hoje, `figma`/`penpot` amanhã — obedece ao mesmo contrato:

1. **Entrada** específica do provider (arquivo flat, API de design tool, …).
2. **Normaliza** para um intermediário plano `{caminho.pontilhado: "#hex"}`.
3. **Emite DTCG** em STDOUT (`$schema` + grupo com `$type` + folhas `$value`). `figma`/`penpot` reusam a
   emissão do `file` após o passo 2 — a normalização é a única parte específica do provider.
4. **Determinístico, sem LLM** — é transformação de dados.

O chamador redireciona o STDOUT para o arquivo da SSOT e **valida com o gate** antes de commitar:

```bash
# bootstrap de foundations a partir de uma paleta de marca (flat) → SSOT
bash ${CLAUDE_PLUGIN_ROOT}/utils/design-source/file-to-tokens.sh brand-palette.json \
  > docs/design-context/foundations/color.tokens.json
bash ${CLAUDE_PLUGIN_ROOT}/validation/lint-design-tokens.sh   # gate F5: DTCG + refs + WCAG
```

## Round-trip (dogfood)

A simetria source↔sink fecha um laço verificável: `paleta flat ──source──▶ DTCG ──gate──▶ válido ──sink──▶
CSS vars`. O adapter `file` é exercitado por esse round-trip (paleta da identidade Onion → DTCG → passa no
`lint-design-tokens.sh`), o mesmo critério mecânico que valida o sink.

> **Cores em `#rrggbb` (6 dígitos).** Para o round-trip valer, o adapter `file` aceita só hex de 6 dígitos
> — alinhado ao gate, que computa contraste WCAG de `#rrggbb`. `#rgb` e `#rrggbbaa` (alpha) são rejeitados
> (falha-alto), assim como chaves `$`-reservadas e colisão de prefixo (`brand` + `brand.orange`).

## Determinismo

A ingestão é **determinística (sem LLM)** — normalização de dados, não geração. (Geração de identidade
**nova** é a Fase 4, `@brand-generator` — diverge→converge, outra camada.) O gate `lint-design-tokens.sh`
garante que a SSOT resultante é válida antes de qualquer consumo pelo `design-sink/`.
