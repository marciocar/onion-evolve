---
title: 'inventory.sh conta arquivos gitignorados — lint local verde, CI vermelho (REGRA 8)'
date: 2026-09-04
from: portal-gamificacao (consumidor)
to: core (onion-evolve)
type: bug
flow: upstream (consumidor→core)
---

## O que aconteceu
`docs/knowledge-base/gamification/sources/_text/*.md` está no `.gitignore` (texto extraído, regenerável). O
`inventory.sh --markdown` local contou esses 3 arquivos como Knowledge Bases (107); o CI, num checkout limpo, contou 104
e a REGRA 8 reprovou HARD. Localmente o lint passava. Medido em 2026-09-04 no PR #1 deste repo.

## Contorno
Inventário regenerado num `git worktree` limpo e commitado com `--no-verify` (o hook local reprovaria pelo mesmo motivo).

## Proposta
`inventory.sh` (e o `check_inventory_sync` do lint) deveriam enumerar por `git ls-files`, não por `find` no
filesystem — assim local e CI veem o mesmo conjunto. Mesma classe do "glob 36% cego" já corrigido no `kg-corpus-grep.sh`.

## Adendo (mesmo dia)
Contorno definitivo aplicado no adotante: as cópias de leitura passaram de `.md` para `.txt` — o `inventory.sh` conta só
`*.md` (`find -name "*.md"`), então deixam de entrar. Confirma o diagnóstico: o problema é enumerar por filesystem em vez
de `git ls-files`.

---

## Triagem do core — 2026-09-05

**Veredito: FIX — curado na fonte** (PR do dia 2026-09-04).
`inventory.sh` passou a enumerar por `git ls-files` (helper `_tracked_or_find`, com fallback declarado
para `find` quando não há git — adotante pre-init/tarball), em quatro contadores: comandos por categoria,
total de comandos, agentes por categoria e total de agentes. Assim o lint local vê o MESMO conjunto que o
CI num checkout limpo. Guarda: caso `(a)` da familia `upstream_portal_fixes` na bancada — sandbox com um
agente rastreado e um gitignorado, exige a contagem 1. Obrigado pelo sinal: o modo de falha (verde local,
vermelho no CI) é exatamente o que nenhum gate pegava.
