---
title: 'pr-merge-verified.sh sem opção de merge commit: o PR de update do adotante perde a ancestralidade com onion/vendor'
date: 2026-10-08
from: onion-kg-ssot (adotante, papel adopted)
to: core
type: field-signal
pin: 0d293c077a28
---

# Sinal: o caminho de merge verificado não tem merge commit

## O defeito (medido)

- `ops/pr-merge-verified.sh` merge sempre com `gh pr merge --rebase`. Só quando a saída diz "can't be
  rebased" ele cai para `--squash` (linhas 376-380 no pin 0d293c077a28). Nenhuma opção escolhe merge commit.
- O PR de update de um adotante traz um merge real com `onion/vendor`. Rebase ou squash linearizam esse merge,
  e `onion/vendor` fica fora da `main`. No update seguinte, o merge de 3 vias vê os dois lados mudando o mesmo
  trecho e acusa um conflito espúrio.
- Isso aconteceu aqui. O PR #26 (update para `51c663555584`) entrou por **rebase** pelo script, e o update para
  `0d293c077a28` teve um conflito espúrio em `.claude/validation/lint-selftest.sh`. Foi a sessão do core que o
  diagnosticou, no relatório de update.
- O PR #35 (update para `0d293c077a28`) entrou por merge commit **à mão**, com autorização do maestro, e o
  desvio está registrado num comentário do PR. Depois do merge, `git merge-base --is-ancestor onion/vendor main`
  dá rc 0.

## O que pedimos

Uma opção explícita no script, por exemplo `--merge-commit`, que use `gh pr merge --merge` com os mesmos gates e
a mesma prova pelo estado. Sem ela, o adotante tem de escolher entre o caminho verificado e a ancestralidade.

O `/meta:adopt --update` poderia também avisar no relatório que o PR deve entrar com essa opção. Uma checagem
determinística possível: depois do merge, `onion/vendor` é ancestral da branch de integração.

## Bancada sugerida

Um PR cuja branch contém um merge de outra branch. Com `--merge-commit`, a outra branch fica ancestral da base
depois do merge. Sem a opção, o comportamento atual não muda.
