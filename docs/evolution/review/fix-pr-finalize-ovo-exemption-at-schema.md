---
branch: fix/pr-finalize-ovo-exemption-at-schema
pr: pendente
date: 2026-10-20
reviewed_diff_sha256: b7a3c816fc5f5b05c04b734ef3550971ee947a1c3a9d53f4e358c2d266e70300
reviewed_code_sha256: e2e78d1f1c0f7cc7ecb0fde5af78003079378961df8cb9337e97dbca8239706d
findings_total: 2
findings_real: 1
tokens: 0
duration_min: 15
findings_fixed: 1
verdict: CORRIGIDO
elenxo: sim
reviewer: passada adversarial manual da sessão, com dogfood pelo --check e mutante; sem subagentes
nota: ""
---

# Passada adversarial: `fix/pr-finalize-ovo-exemption-at-schema`

## O que muda

Entra `_ovo_exempt()` no `ops/pr-finalize.sh`: pergunta à própria guarda se o PR está isento
(`PR-edita-o-proprio-revisor(ovo-galinha)`). É usada nos dois pontos que exigem resíduo: o 0a (esquema) e o
`_restamp` (carimbo). O caso (ovo) da família `review_artifact` passa a exigir a definição e as duas chamadas.

## Achados

1. **REAL (a causa, e um erro meu):** a cura do #1226 tratou só o `_restamp`. Eu tinha medido a falha num ponto e
   curei esse ponto, sem procurar os outros lugares que exigem o mesmo resíduo. O 0a roda antes e barrava o mesmo
   PR, gerando um esqueleto: "resíduo ausente: o esqueleto foi gerado". Medido ao re-rodar o PR do pin depois
   do merge do #1226.
2. **Refutado:** "pular o 0a deixa passar resíduo fora do esquema?" Não deixa. O pulo só acontece quando NÃO há
   resíduo E a guarda declara a isenção. Com resíduo presente, o esquema é conferido como antes.

## Dogfood

`bash <motor novo> --check` no PR do pin (diff = só o workflow) declara a isenção no 0a e passa: pré-voo
verde, 0 HARD, contrato verde, "a rodada real passaria". Com o motor da `main`, o mesmo PR parava no 0a.

## Mutantes

A chamada do 0a trocada por `false` faz o caso (ovo) reprovar (morde). Família `review_artifact`: 18/18.
