---
paths:
  - "docs/{onion,sdaal}/**"
---
Lente VIVA com braces: o harness EXPANDE `{a,b}` (medido por sonda 2026-09-29) e carrega. O git não
reconhece braces nem com `:(glob)` — 0 hits —, então a guarda acusava lente viva. A expansão de um
nível antes de consultar o git corrige.
