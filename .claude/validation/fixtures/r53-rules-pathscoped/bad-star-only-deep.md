---
paths:
  - ".claude/validation/fixtures/*.md"
---
Lente MORTA pela semântica do harness: o `*` não cruza `/`, e não há `.md` DIRETO nesse diretório —
só em subpastas. O pathspec NU do git devolvia 83 hits e ABSOLVIA (fail-open, medido 2026-09-29);
com `:(glob)` devolve 0 e a lente é corretamente acusada.
