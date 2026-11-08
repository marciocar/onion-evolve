---
branch: chore/vendor-push-consent-1108
pr: pendente
date: 2026-11-08
reviewed_diff_sha256: 6a9b1ede16b9633e850f6ba31aa607634fa5b328bd8ed98af707584e6b255730
reviewed_code_sha256: 45f2a7c0be1c9f0249df0c6f44539538aa86f4abc44ab3b5f27adb5e1f4a65ca
findings_total: 1
findings_real: 1
findings_blocking: 0
tokens: 0
duration_min: 10
findings_fixed: 0
verdict: APROVADO
elenxo: nao
reviewer: passada própria sobre o próprio diff (sem subagente); gate mecânico members-validate e lint
nota: "tokens 0 = não medido. Diff de 3 linhas de dado no registro."
---

# Passada adversarial: `chore/vendor-push-consent-1108`

## O que muda

`vendor_push: true` em três membros do registro, por selo do maestro no /meta:decide de 2026-11-08: onion-kg-ssot,
granaai e brain-granaai. Os dois últimos dividem o remote `github.com/GranaAi/granaai` e consentem juntos, o que é a
condição do #1533 para empurrar um remote dividido.

## Achados

1. **O consentimento só passa a valer depois do merge, e o casamento por URL não foi exercitado nestes três
   membros (LIMITE).** O #1533 lê o registro do `origin/main` do core e casa o membro pela URL de push. Os remotes
   registrados são `https://github.com/marciocar/onion-kg-ssot (privado)` e `github.com/GranaAi/granaai`, formas
   que a bancada `vendor_push_trailer` cobre (a nota "(privado)" e a forma sem esquema, caso D2). A prova real fica
   para o próximo update de cada um, e o relatório downstream dirá se empurrou.

## Mutantes

Não se aplica: o diff é dado de registro. O gate é o `members-validate.sh` (rc 0).

## Limites declarados

- O brain-granaai roda em outra conta do Claude. O consentimento é do maestro, dono dos dois repos, e não da sessão
  do hub. O core avisa o hub no próximo update.
