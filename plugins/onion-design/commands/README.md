# 🎨 Comandos `design/` — vertical de design

Comandos da **vertical de design** do Onion: identidade visual como spec-as-code (design tokens
W3C/DTCG como SSOT em `docs/design-context/`; CSS/componentes/material como saída gerada).

> **Categoria de comando ≠ dimensão peer.** Esta categoria organiza os comandos de design; ela **não**
> afirma uma 4ª dimensão de domínio (como `meta/`, `validate/`, `test/` também não são dimensões). A
> promoção de `design-context` a 4º peer é decisão separada e provisória — ver
> [`docs/design-context/decisions/onion-adr-design-peer-promotion.md`](../../../docs/design-context/decisions/onion-adr-design-peer-promotion.md).

## Comandos

| Comando | Faz |
|---------|-----|
| [`/design:identity`](identity.md) | Ciclo brief → develop (tokens + gate WCAG + materializa) → material. Faseado, retomável. Delega a `@design-system-specialist`. |
| [`/design:generate`](generate.md) | Camada generativa: diverge (N identidades por IA, em orquestração) → converge (gate WCAG + juiz) → vencedora alimenta o DEVELOP do identity. Delega a `@brand-generator`. |

## Próximos (roadmap — plano `transient-cooking-pebble`)

- `/design:evolve`: faceta de `/meta:evolve` — audita drift visual e produz backlog priorizado.
  **Gated até:** existir ≥1 identidade de projeto com tokens materializados **que drifte** dos
  tokens da SSOT. Sem esse gatilho não há o que auditar — construir antes seria catedral à frente
  do uso ([modernization §🚦](../../../docs/knowledge-base/concepts/onion-modernization-doctrine.md)).

## Princípios

- **A IA gera; o gate determinístico decide** (`${CLAUDE_PLUGIN_ROOT}/validation/lint-design-tokens.sh`).
- **Anti-lock-in**: SSOT são tokens abertos; ferramentas (artifact-design, Figma, Penpot, Style
  Dictionary, Tailwind) entram como adapters plugáveis (`design-source/`, `design-sink/`).
- **Dogfood**: a identidade do próprio Onion é o caso de teste.
