---
title: 'Resíduo — o onion-curation entra no registro da federação'
date: 2026-10-06
branch: chore/register-onion-curation
reviewed_diff_sha256: 092c957f4c1bdbfdce35c39edfa0255119f45270902a4fe91be953bb0fb9a78a
reviewed_code_sha256: e56377eb77215bf2633213711b80e49550dbbb5cb56d4d2efa5bc02fda9b355c
findings_total: 0
findings_real: 0
findings_fixed: 0
tokens: 0
duration_min: 5
verdict: SEM_ACHADOS
elenxo: nao
nota: >-
  PR sem superfície executável, no mesmo molde do chore/register-onion-slm: uma entrada no members.yaml e
  as projeções regeneradas. Verificação determinística: check-member-registered reconhece o
  /home/marcio/onion-curation, pin-integrity-check dá pin-ok 5b529e980779 e members-validate dá válido
  (25 membros). O projection-safety acusa 6 violações sobre o members.yaml bruto, e acusa as mesmas 6
  na main: o registro é a fonte interna e não superfície pública; as projeções passam pelo lint. Sem
  Elenxo, declarado. A adoção em si (PR #1 do onion-curation) teve a passada adversarial dela, com 7
  achados reais curados lá; três deles são do CORE e ficam como pendência daqui: o /meta:adopt não gera
  .gitignore de segredos, o durable-commit.sh não escreve a assinatura e o template do CI não dispara
  em mudança de .githooks/**.
---

# Resíduo — `chore/register-onion-curation`

Registrar o adotante é ato de segurança: repo `onion-*` fora do `members.yaml` fica invisível à REGRA 36
(Superfície VENDORIZADA sem nome comercial de cliente), e sem a entrada o `/meta:co-deliver` não resolve o
`--target`.
