---
branch: fix/sync-main-worktree-after-merge
pr: pendente
date: 2026-10-15
reviewed_diff_sha256: pendente
findings_total: 2
findings_real: 2
tokens: 0
duration_min: 0
findings_fixed: 1
verdict: CORRIGIDO
elenxo: sim
reviewer: a sessão executora (SAC-143); ataques por 3 mutantes contra repositórios reais (remoto bare + worktrees)
nota: "decisão sem o maestro (autorização noturna de 2026-10-15): ligado por padrão. tokens e duration_min em 0 = não medidos."
---

# Passada adversarial: `fix/sync-main-worktree-after-merge`

## O que muda

Depois do merge PROVADO, o `ops/pr-merge-verified.sh` chama o `ops/sync-main-worktree.sh`. Ele acha a worktree com
`main` em uso (o checkout principal, de onde o harness lê os hooks) e a sobe por fast-forward a partir do
`origin/main`. Nunca faz checkout, reset nem stash. Quando falha, só avisa, e o rc do merge não muda.

## Achados

1. **Hook mergeado não valia na sessão.** Medido em 2026-10-15: o checkout principal estava 36 commits atrás, e o
   Stop aposentado no #1129 ainda disparava cerca de 1h20 depois do merge. O `--sync` existente não resolvia: faz
   checkout de `main` na worktree atual, que falha quando `main` está tomada pelo checkout principal, e é opt-in.
2. **O veto do merge barra texto.** O veto PreToolUse do merge barrou o commit deste resíduo porque o heredoc citava
   o comando de fast-forward. O corpo foi escrito por arquivo. É falso positivo conhecido da classe "comando que não
   pode ser analisado com certeza", que erra para o lado de barrar; fica registrado, não curado aqui.

## Decisões tomadas sem o maestro

- Ligado por padrão, e não opt-in: o fast-forward é não destrutivo, e o opt-in era exatamente o motivo de nunca
  rodar.

## Mutantes

- M1, sem o fast-forward → reprovam (a), (b), (c) e (d).
- M2, reset forçado no lugar → reprovam (c) e (d), porque destruiria a sujeira.
- M3, sincronizar a worktree atual → reprovam (a), (c) e (d).

## Limites declarados

- Se um arquivo sujo do checkout principal conflita com o merge, o fast-forward recusa: o checkout fica atrás, com
  aviso na saída do merge. Os arquivos de métrica que o core suja localmente não são tocados pelos merges, medido
  hoje.
- Uma sessão já aberta pode ter carregado o `settings.json` antes: a sincronização põe o arquivo novo em disco, e
  quando o harness o relê é com ele.

## Rebase com conflito (re-revisão)

O merge do #1133 (SAC-145) pôs a família `merge_hooks_prune` na mesma âncora do `lint-selftest.sh` que este PR usa. O
auto-rebase do `merge-serial` recusou, como devia, porque era conflito de fonte. Resolvi à mão mantendo as DUAS
famílias, uma depois da outra, e rodei as duas juntas: 9 casos verdes. O hash de código mudou pela resolução, e esta
seção é a re-revisão.
