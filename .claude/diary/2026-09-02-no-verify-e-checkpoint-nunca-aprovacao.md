---
date: 2026-09-02
instance: onion-evolve
type: error
classification: public
tags: [no-verify, gate, pre-commit, ci, aprovacao, declarado-vs-verificado]
affects: [engineering, meta]
breadcrumb_for: []
share_with: []
next_recommended: "todo relatório de PR nomeia O GATE QUE VALIDOU o SHA final (pre-commit re-rodado ou CI verde no head) — nunca o `--no-verify` como se fosse a validação"
review_after: 2026-12-01
conflict_class: static
significance: "O maestro separou duas coisas que eu tinha colado numa só: `--no-verify` garante que o trabalho incompleto não se perde; a APROVAÇÃO só vem do gate completo executado sobre o SHA final."
---

## Signal
`git commit --no-verify` é **checkpoint** (não perder trabalho ainda incompleto). **Nunca** é validação
final para aprovação. A aprovação de um PR/merge exige o **gate completo executado sobre o SHA final**
(pre-commit re-rodado, ou lint + selftest + onion-review verdes no head no CI) — e o relatório **nomeia
esse gate**, não o pulo.

## Evidence
- 2026-09-02, PR #765: reportei "commits foram `--no-verify`" como parte do fechamento. O gate real
  tinha rodado (lint local 0 HARD + CI verde no head + `ops/pr-merge-verified.sh`), mas a frase
  apresentava o **pulo** como se fosse a **validação** — declarado no lugar do verificado
  ([[worst-truth-is-uncertain]], [[exit-code-nao-e-a-verificacao]]).
- Reforço do maestro (verbatim): *"isso não pode ser usado como final, pode ser usado para garantir um
  commit para não perder algo que está ainda incompleto, mas NUNCA como validação final para aprovação"*.
- A memória anterior ([[shared-vps-precommit-slow-noverify]]) enquadrava o `--no-verify` como
  "desbloqueio pragmático com 3 condições" — enquadramento fraco: tratava o pulo como caminho legítimo
  de fechamento. O enquadramento certo é **provisório por natureza**: um commit `--no-verify` fica
  "sem carimbo" até o gate completo rodar sobre ele (ou sobre um SHA que o contenha).
- O mecanismo de aprovação **já existe e é o correto**: `ops/pr-merge-verified.sh` só mergeia com
  check-runs verdes no head SHA + `onion-review-verdict`. O buraco não era mecânico — era a
  **narrativa** do relatório, que é o que o maestro lê para aprovar.

## Next crumb
- Sequência canônica quando o pre-commit estoura na VPS: `--no-verify` (checkpoint) → push → **CI
  verde no head** = a validação → merge pelo caminho verificado. No relatório: *"validado por: CI
  <run> no SHA <x> (lint/selftest/review verdes)"*; o `--no-verify` aparece só como nota de
  checkpoint, se aparecer.
- Se o CI **não** cobrir tudo o que o pre-commit cobre (conferir antes de confiar), re-rodar o
  pre-commit localmente sobre o SHA final antes de pedir aprovação.
