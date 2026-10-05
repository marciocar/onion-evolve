---
title: "Update perde arquivos NOVOS em silêncio quando o .gitignore da onion/vendor ignora .claude/ (17 arquivos em dois updates)"
date: 2026-10-04
type: signal
from: brain-granaai (hub, pin 3a3c7cf280ac)
severity: high
---

# `durable-commit` na vendor pula arquivos novos ignorados

## Sintoma
Depois do update para `3a3c7cf280ac`, todo fim de turno: `Stop hook error: … background-state-needs-evidence.sh: No such
file or directory`. O `settings.json` (mesclado pelo `merge-onion-hooks.sh`) registrou o hook, mas o script não veio.

## Medido
Comparando `ls-tree -r` do core@`3a3c7cf280ac` (raízes positivas do manifesto `hub`) com o `HEAD` do adotante: **17
arquivos do core ausentes** — todos **novos** desde o pin `547e2e3edf3b` (o hook, `clickup-operacao.md`,
`/meta:forge-guard`, `guard-doctrine.md`, `/meta:dissect`, `dissect-doctrine.md`, 2 rules, 7 scripts de validação,
2 fixtures). Nenhum arquivo **modificado** se perdeu.

## Causa (verificada)
A `onion/vendor` deste adotante foi semeada (2026-10-01, convergência docs-only → padrão do core) de um commit cujo
`.gitignore` ainda ignorava `.claude/`; a convergência do `.gitignore` foi feita só na integração (levá-la à vendor
faria a guarda de base cruzada recusar o arquivo de produto). No `vendor-branch.sh update`, o `tar -x` traz os
arquivos novos para a worktree, mas o `durable-commit.sh` faz `git add -- .claude` — e `git add` **pula arquivo novo
ignorado** sem erro. Só modificações de arquivos já rastreados chegam ao commit da vendor. O update reporta
"merge limpo" (rc=0).

Um agravante: a 1ª contagem saiu 0 porque `git ls-tree` **recusa** a pathspec `:(exclude)…jwks/*.pem` do manifesto
(`pathspec magic not supported`) — a mesma armadilha já documentada no `vendor-branch.sh`.

## Correção aplicada aqui
1. `.gitignore` da `onion/vendor` = o da integração (commit na vendor + merge na integração sem mudança de árvore,
   para a base comum já conter o mesmo `.gitignore` e a guarda de base cruzada seguir passando).
2. `--update` re-rodado para o mesmo pin: os 17 chegaram, idênticos ao core (`cmp`), hook executa (rc=0); lint 0 HARD
   após regenerar as projeções.

## Pedido ao core
- `durable-commit.sh`: stajar a superfície do manifesto com `git add -f` (ou detectar e **falhar alto** quando houver
  arquivo do manifesto untracked+ignored na worktree da vendor).
- `vendor-branch.sh update`: pós-condição "todo arquivo do manifesto no core@pin existe no commit da vendor" (comparar
  `ls-tree` só com as raízes positivas), em vez de confiar no rc do merge.
- Para a convergência docs-only → durável (item `I_ADOPT_DOCS_ONLY_CONVERGENCIA_GATILHO_DISPAROU`): a semeadura da
  vendor deve incluir o `.gitignore` convergido, ou esta perda se repete em todo adotante que convergir.
