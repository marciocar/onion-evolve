---
title: "co-deliver.sh não resolve o path do adotante pelo members.yaml (busca 'path:', o arquivo usa 'local_path:')"
date: 2026-07-10
from: onion-evolve (dogfood do core — entrega dos anúncios da convenção de worktrees)
type: bug
status: assess
---

# Sinal — carteiro-local exige --target mesmo com local_path registrado

## O que aconteceu

Na entrega dos anúncios da convenção de worktrees (2026-07-10), o `/meta:co-deliver` falhou a
resolução automática do alvo para **membros com `local_path:` válido no members.yaml**:

```
$ bash .claude/utils/co-evolution/co-deliver.sh metagamify 2026-07-10-worktree-convention-credito.md --dry-run
ERRO: path local do adotante 'metagamify' não resolvido. Informe --target <path>
      (members.yaml não traz 'path:' utilizável para este membro).
```

O maestro contornou com `--target /home/marcio/rhilo-metagamify` (e `--target /home/marcio/granaai`).

## Causa

`co-deliver.sh` chama `member_field "${MEMBER}" path` — mas o campo real do `members.yaml` é
**`local_path:`** (com comentário inline, que o `clean()` do awk já sabe remover). O helper nunca
encontra o campo e cai no erro de uso.

## Direção de fix

Resolver **`local_path:` primeiro, `path:` como fallback** (compat), e atualizar a mensagem de erro.
Selftest cobrindo: resolução via `local_path` (com comentário inline, o caso real), membro sem path →
exit 2, e `--target` continua soberano.
