---
date: 2026-07-02
instance: onion-evolve
type: error
classification: public
tags: [federation, pin-integrity, adopt-update, recover, dev-prod-governance, w6-field-test]
affects: [meta, federation, co-evolution]
breadcrumb_for: [meta:adopt, meta:recover, meta:co-announce, meta:co-evolve]
share_with: [collective]
next_recommended: "2026-07-02-work-models-eixo-e-decision"
review_after: 2026-09-30
---

## Signal
O core anunciou "você já tem o fix" raciocinando sobre o **carimbo** (pin do stamp/members.yaml) em
vez do **artefato vendorizado** — e o pin era forjado. O adotante (rhilo) re-rodou como o anúncio
pedia, verificou os arquivos reais e **refutou o anúncio** com evidência
(sinal `2026-07-02-sinal-lint-only-ausente-no-vendor`). Primeiro exercício W6 de campo: funcionou —
o responder verificou em vez de confiar.

## Evidence
- Cadeia do erro: restore manual (30/jun, `828dd8f7` no rhilo) carimbou o HEAD do core (`a458a0f`)
  numa branch que só tinha o próprio stamp → `members.yaml` herdou o pin forjado → anúncio projetou
  "ancestralidade ⇒ você tem o fix" (a ancestralidade era VERDADEIRA; a premissa "vendor = pin" era falsa).
- Estado real verificado byte-a-byte: vendor do `develop` = core@`aeee056` (6 dias antes do pin declarado).
- Cura de raiz (não paliativo): `pin-integrity-check.sh` (pin é hipótese — existência na história +
  canário byte-a-byte) chamado pelo guard do `/meta:adopt --update`; 5 guardas novas no lint-selftest
  (100→105); dogfood real: o script delatou o rhilo na 1ª rodada (`pin-untrusted canario-divergente`).
- Convergência: a **governança DEV↔PROD** proposta pelo próprio rhilo no Sinal B (KG SDAAL) é esta
  mesma lição — carimbo/doc é plane DEV; só o artefato vivo é plane PROD.

## Next crumb
Antes de qualquer anúncio "você já tem X" ou raciocínio sobre versão de membro: rodar
`pin-integrity-check.sh` — nunca concluir do pin sem canário. Pin de stamp, members.yaml e anúncio
são declarações; o artefato vendorizado é o fato. Regra irmã do "RODE o artefato" da entrada
2026-07-01-audit-dogfood-finds-code-bugs.
