---
paths:
  - "docs/evolution/research/**"
---

# Lente de pesquisa — carrega quando você toca `docs/evolution/research/`

Você está dentro de uma pesquisa do Onion. A doutrina inteira vive em **um** fragmento — leia-o antes de
buscar, sintetizar ou carimbar: `.claude/commands/common/prompts/research-doctrine.md`.

O mínimo que não se negocia aqui:

- **Corpus primeiro:** `bash .claude/validation/kg-corpus-grep.sh <tema>` antes de qualquer busca externa.
- **Mercado/capital é invariante** (worker de mercado no fan-out; rodadas, M&A, analistas dos últimos 6–12 m).
- **Fonte tem tier** (`source_tier` 1–10, `source_kind`); `vendor-on-competitor` é sempre suspeito.
- **Bi-temporal:** `valid_from` (o fato) ≠ `verified_at` (você); grafo com `meta.review_after`.
- **Lacuna vira nó**, nunca omissão; **NÃO-VERIFICADOS** são lista de 1ª classe.
- **Grafo primeiro, prosa depois** — radar exit 0 antes de qualquer SYNTHESIS.

Esta rule carrega só por path (progressive context disclosure) — é por desenho que ela não está no CLAUDE.md.
