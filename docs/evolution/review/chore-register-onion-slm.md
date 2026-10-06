---
title: 'Resíduo — o onion-slm entra no registro da federação'
date: 2026-10-06
branch: chore/register-onion-slm
reviewed_diff_sha256: 2541173765d3cec7ad6c4a395b7cd80a0292097508e125d1b1164c3da7709046
reviewed_code_sha256: cd6ee2c48f7e4dba9faf3989fd166b711471dd28fc0041f1213a3c5d471a8236
findings_total: 0
findings_real: 0
findings_fixed: 0
tokens: 0
duration_min: 5
verdict: SEM_ACHADOS
elenxo: nao
nota: >-
  PR sem superfície executável, mesmo molde do chore/registry-reconcile-after-849: uma entrada em
  members.yaml, o mapa da federação regenerado e um nó question aberto. A verificação é a dos
  validadores determinísticos do /meta:federation-member register — pin-integrity-check (pin-ok
  9e75a73d0401), members-validate (valid:true, 0 erros), projection-safety (nenhum termo sensível) e
  kg-radar --integrity --schema exit 0 no grafo tocado. Sem Elenxo, declarado. O nó novo
  Q_MERGE_VERIFICADO_EM_REPO_SEM_CI registra a lacuna medida no PR #1 do onion-slm (o caminho
  verificado não fecha PR em repo que nunca teve CI); é pergunta aberta com gatilho, não decisão.
---

# Resíduo — `chore/register-onion-slm`

Registrar o adotante é ato de segurança: repo `onion-*` fora do `members.yaml` fica invisível à REGRA 36
(Superfície VENDORIZADA sem nome comercial de cliente), e sem entrada o `/meta:co-deliver` não resolve o `--target`.
