---
branch: fix/empty-result-guard-pr-cwd
date: 2026-10-14
reviewed_diff_sha256: 241807261279eb16ca1887324c3bb9ef34dc4039f01ced8cca045d8ac4cfd03b
reviewed_code_sha256: f4cf1c4ca141950fb9bc2689db473c29f7931c30b43e456e0ddffcdd91df1f0a
findings_total: 1
findings_real: 1
findings_fixed: 1
tokens: 0
duration_min: 20
verdict: REPROVADO_E_CURADO
reviewer: passada adversarial própria (sem subagente), default reprovado na dúvida; causa medida no comando real gravado no transcript, caso (u2) com mutante
---

# O aviso de PR sem resíduo olha onde o comando rodou, não o checkout principal

## O que aconteceu

Duas vezes no mesmo dia (#1110 e #1112) o hook `bash-empty-result-guard.sh` acusou PR-SEM-PASSADA-ADVERSARIAL
com o resíduo commitado na branch. Na 1ª vez não reproduzi; na 2ª li o comando como o harness o gravou: ele
começa em `gh pr create`, SEM o `cd <worktree> &&` que escrevi, porque o harness tira o `cd` que leva ao cwd
da sessão. Sem `cd`, o hook caía no `$CLAUDE_PROJECT_DIR`, o checkout principal na `main`, onde o resíduo de
branch nenhuma existe.

## A cura

O hook lê o `cwd` do payload e o usa antes do `$CLAUDE_PROJECT_DIR` quando o comando não tem `cd`. O caso (u)
(com `cd` explícito) segue valendo; o (u2) cobre o caminho sem `cd`.

## Passada adversarial

1. **O caso reprova o defeito?** Mutante (o hook antigo): (u2) reprova com o aviso falso. Com a cura, a família
   `empty_result_guard` passa inteira.
2. **Payload sem `cwd` (versão antiga do harness)?** `hook_cwd` vazio cai no `$CLAUDE_PROJECT_DIR`, o
   comportamento de antes; nada piora. Real, não curado e declarado: a prova ao vivo é o próximo `gh pr create`
   de uma worktree sair calado.
