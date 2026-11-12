---
date: 2026-11-09
instance: onion-evolve
type: decision
classification: public
tags: [settings, deny, adoption, irreversible, secrets]
affects: [engineering, compliance]
breadcrumb_for: []
share_with: []
next_recommended: "Rodar o update num adotante com deny próprio maior e conferir que nenhuma linha dele some"
review_after: 2027-02-07
conflict_class: dynamic
significance: "Um piso portátil contra atos irreversíveis e leitura de segredos, com catraca: a atualização só pode somar."
---

## Signal
O core ganha um `deny` mínimo e portátil contra atos irreversíveis e leitura de segredos, que viaja para o adotante.
A atualização nunca encolhe o deny do adotante, e quem roda em sandbox é avisado do que muda.

## Evidence
- PR #1552: deny mínimo portátil de atos irreversíveis e leitura de segredos.
- PR #1514: a branch do update nasce da ponta mais nova, e o deny do adotante nunca encolhe.
- PR #1558: o update avisa quem tem sandbox, e a retirada do deny passa a existir como ato explícito.

## Next crumb
O deny é camada de conformidade, não fronteira de segurança (o mesmo limite do `exit 2`): registrar no próximo
radar se algum mod ou harness passou por cima dele.
