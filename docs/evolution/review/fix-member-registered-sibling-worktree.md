---
branch: fix/member-registered-sibling-worktree
pr: pendente
date: 2026-10-15
reviewed_diff_sha256: pendente
findings_total: 1
findings_real: 1
tokens: 0
duration_min: 0
findings_fixed: 1
verdict: CORRIGIDO
elenxo: sim
reviewer: a sessão executora (SAC-144 item 2); mutante e dogfood numa worktree real do core
nota: "tokens e duration_min em 0 = não medidos."
---

# Passada adversarial: `fix/member-registered-sibling-worktree`

## O que muda

O `check-member-registered.sh`, que o `/meta:adopt` roda contra o `INSTALL_DIR`, reconhece também o checkout PRINCIPAL
do repo do alvo, derivado do `git-common-dir`. Assim uma worktree irmã de um membro registrado deixa de sair "NÃO
REGISTRADO".

## Achados

1. **Falso "NÃO REGISTRADO" em todo update feito em worktree irmã** (SAC-144, item 2), medido no update do
   `onion-curation`. O `--update` roda numa worktree irmã quando há sessão viva no alvo, e o caminho dela nunca é o
   `local_path` do registro.

## Mutantes

- Sem a comparação com o checkout principal, o caso (d) reprova.

## Dogfood

Numa worktree real do core: a versão antiga sai rc 3, e a nova sai rc 0.

## Limites declarados

- Uma worktree irmã de um repo FORA do registro segue em rc 3, coberto no caso (d).
- Repo bare, ou em que o common-dir não termina em `.git`, cai no caminho literal de antes.
