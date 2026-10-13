---
branch: chore/ruleset-bypass-pull-request
date: 2026-10-13
reviewed_diff_sha256: 2651f01b93772959ba3a282e9e211756220bd846b9e281bacd8006a27172a319
reviewed_code_sha256: 885577c646d7a8582149eb8c4e5b422dc759c5270ede36b06c513bac9e0dd75d
findings_total: 2
findings_real: 0
findings_fixed: 0
tokens: 0
duration_min: 10
verdict: APROVADO
reviewer: passada adversarial própria (sem subagente), default reprovado na dúvida. Gate mecânico: radar e contrato do grafo pelo selador; dry-run do apply-ruleset-main.sh
---

# O bypass do admin no ruleset do main passa a valer só em merge de PR

Aplica duas respostas do maestro (2026-10-13, /meta:decide) sobre o que o passo D (#1074) deixou para
ele: `bypass_mode: pull_request` no `ops/github-ruleset-main.json` (selo `D_RULESET_BYPASS_SO_EM_PR`) e
a permissão do Actions para abrir o PR de revert (selo `D_ACTIONS_ABRE_PR_DE_REVERT`; a permissão é
configuração do repo, aplicada fora do diff).

## Passada adversarial

1. **`pull_request` trava algum fluxo que empurra direto ao main?** Medido: `grep -rn "git push"` em
   `.github/workflows/` e `ops/*.sh` não acha nenhum push ao main (o `pr-finalize` empurra a branch do
   PR; o alarme da bancada empurra `revert/<sha12>`). As projeções geradas nascem dentro dos PRs.
   Não real.
2. **O merge verificado com o revisor do CI vermelho ainda passa?** O `onion-review-verdict` não está na
   lista exigida, e o merge do `ops/pr-merge-verified.sh` é `gh pr merge` (merge de PR), que o bypass
   `pull_request` cobre. Não real. Fica a medir ao vivo no 1º merge depois de aplicar o ruleset.

`actor_id 5` (admin) segue vindo da documentação REST, não medido ao vivo — teto declarado do #1074.
