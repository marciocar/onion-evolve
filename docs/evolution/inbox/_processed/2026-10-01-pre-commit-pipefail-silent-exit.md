---
title: "pre-commit do Onion sai com 1 em silêncio quando o lint-staged está configurado sem node_modules e sem packageManager"
date: 2026-10-01
type: signal
from: brain-granaai (adopted, pin 547e2e3edf3b)
severity: high
---

# pre-commit sai com 1 em silêncio: `pipefail` + `grep` sem match

## O que aconteceu

Na primeira tentativa de commit depois da atualização para o pin `547e2e3edf3b`, todos os commits falharam
sem mensagem: o lint Onion imprimia `OK ✓ — nenhuma violação HARD` e o `git commit` saía com 1, sem criar
o commit. Um `git commit ... > /dev/null` chegou a parecer bem-sucedido.

## Causa (verificada)

`.githooks/pre-commit` roda com `set -euo pipefail`. No ramo `elif` do lint-staged (configurado no
`package.json`, mas sem `node_modules`), a linha

```bash
onion_pm="$(grep -oE '"packageManager"…' package.json 2>/dev/null | grep -oE '[a-z]+$' | tail -1)"
```

devolve status 1 quando o `package.json` não tem `packageManager`. Com `pipefail` a substituição falha,
com `set -e` o script morre ali: antes do `echo` que explicaria o skip.

Condições para reproduzir: lint-staged declarado no `package.json`, `node_modules` ausente (clone novo,
worktree) e nenhum campo `packageManager`.

## Correção aplicada localmente

```bash
onion_pm="$(grep … | grep -oE '[a-z]+$' | tail -1 || true)"
```

## Pedido ao core

1. Aplicar o `|| true` no template do hook.
2. Cobrir com teste de bancada: hook com lint-staged configurado, sem `node_modules`, sem `packageManager`.
3. Registro adjacente: a atualização sobrescreveu `docs/knowledge-base/index.md` do adotante com a versão
   do core (perdeu frontmatter e entradas locais; o `docs:check` do adotante passou a reprovar). O índice
   foi restaurado aqui. Vale tratar esse arquivo como local do adotante no `/meta:adopt`/update.

## Adendo (2026-10-01, mesma sessão): convergência docs-only → padrão do core

O adotante estava na "forma docs-only" (`.claude/` ignorado), que o `adopt.md` marca como fora do fluxo de
vendor-branch. Por decisão do maestro, convergiu para o modelo durável **sem readoção**: o `.claude/` local era
idêntico ao core@`547e2e3edf3b` (menos o corte de papel e baselines locais), então foi versionado; `.githooks/`
idem; `onion/vendor` re-semeada em `bd74ec774` + `.claude/`, ancestral da integração (`onion/develop`).

Para o core:
1. O update anterior saiu como `chore/onion-update-<pin>` (copy-over) porque o vendor estava em base cruzada e o
   `.claude/` não era versionado. Vale o `/meta:adopt --update` detectar docs-only e **oferecer a convergência**
   (scope-gitignore + versionar + re-semear vendor) em vez de cair no copy-over silencioso.
2. O `_clean_baseline` nunca acha base num adotante cujo `docs/knowledge-base` mistura KBs locais com as do core;
   a base correta foi o commit do copy-over, antes das customizações. Sugestão: registrar esse commit como
   baseline explícito no stamp.
