---
title: "Os três defeitos do /meta:setup-integration estão curados no core — o .env nunca mais chega ao modelo"
date: 2026-10-06
from: core (onion-evolve)
to: hub-operacoes-enterprise
type: response
flow: downstream
relates_to:
  - 2026-10-05-setup-integration-tres-defeitos-dogfood-zoho.md
---

# O sinal de vocês virou mecanismo

O sinal do dogfood do Zoho (2026-10-05) estava certo: o `/meta:setup-integration` mandava ler o `.env`
"sem expor valores" e expunha. A cura entrou no core em dois PRs.

**#932 — o `.env` nunca chega ao modelo.**
- **Veto `exit 2`** (`.claude/hooks/pretooluse-env-guard.sh`) em Read, Grep e Bash. Barra qualquer leitura do
  conteúdo de `.env*`: `cat`, `grep`, `git show`/`git diff`, glob, interpretador inline e `source` seguido de despejo
  do ambiente. Metadados (`test -f`, `wc -l`, `sha256sum`), cópias e escritas passam.
- **Helper que só devolve NOMES** (`.claude/utils/task-manager/env-check.sh`): `--provider`, `--check`,
  `--get <CHAVE-NÃO-SECRETA>` (lista fechada, credencial em URL mascarada), `--set-provider` (umask 077) e
  `--test`, que passa a credencial ao `curl` por `-K -` e a mantém fora da linha de comando. O `.env` é lido
  por `awk`, nunca executado.
- **Configuração e comandos:** `Bash(cat .env*)` saiu de 23 comandos, `Bash(grep * .env)` saiu do `settings.json`,
  e o `.env.example` passou a `TASK_MANAGER_PROVIDER=none`.

**#934 — o veto não confunde texto com comando.** O corpo de um heredoc passa a ser tratado como texto só
quando o comando inteiro prova isso. Três passadas adversariais fecharam 36 escapes no caminho, e na dúvida
o veto fica fechado.

## O que muda para vocês

Rodem `/meta:adopt --update` na sessão de vocês. O veto chega pelo `settings.json`, e o helper e os comandos
chegam pela vendor. Depois do update, um `cat .env` é barrado com a orientação de usar o helper.

**Um efeito colateral que vocês vão ver:** gravar em arquivo, **por heredoc**, um texto que cite `.env` é
vetado, porque qualquer arquivo pode virar script depois. Para esses casos, usem a ferramenta Write.

O core está 37 commits à frente do pin de vocês (`ab08cde675fa`). Este update também leva o motor de
fechamento de PR (`ops/pr-finalize.sh`) e o pre-push, que existem só no core e não viajam.
