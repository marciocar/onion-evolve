---
branch: chore/members-owner-session-slm
pr: 1687
date: 2026-11-18
reviewed_diff_sha256: 82ca9638ce22ca24cc84e1a42646392314daf3c7d499e408058287ea949fd031
reviewed_code_sha256: f7922ed6adf1e7371c6021ed42a02187b45f252f023c0a2c4517ac8791ab1924
findings_total: 0
findings_real: 0
findings_blocking: 0
tokens: 0
duration_min: 5
findings_fixed: 0
verdict: NO_FINDINGS
elenxo: true
elenxo_isolado: false
reviewer: "Passada da própria sessão do core, só leitura, mandato de refutar: a catraca lê owner_session pelo awk de ops/pr-merge-verified.sh (l.324), que tira comentário e aspas; o membro onion-slm já casava pelo remote (a recusa do PR #15 da slm o achou como kind: adopter); a bancada cr1/cr4 do lint-selftest cobre aceita com owner_session e recusa sem. Não é isolada: o PR toca a catraca e o merge é do maestro, com --maestro."
nota: "tokens 0 = não medido."
---

# Passada adversarial: `chore/members-owner-session-slm`

## O que muda

Duas linhas no bloco `onion-slm` do `members.yaml`: `owner_session: onion-slm` e `sponsor: maestro`. Com elas, a
catraca do merge pelas sessões (D_SESSIONS_MERGE_OWN_PRS_INCL_GUARD_1118) passa a aceitar que a sessão da slm merje o
PR do próprio repo pelo caminho verificado. Sem elas, o PR #15 da slm (CI verde, revisão isolada aprovada) foi recusado.

## O que se tentou refutar

- **O valor casa com o comentário da linha?** O awk corta no primeiro espaço ou `#`, então `onion-slm` sai limpo.
- **Abre repo de cliente?** Não: o remote é `marciocar/onion-slm`, dono do core; a catraca continua recusando outro dono.
- **Promove a slm a peça estratégica?** Não: `piece:` ficou de fora de propósito, porque é outra decisão.

## Veredito

NO_FINDINGS. O merge é do maestro, porque o PR toca a lista da catraca (M1).
