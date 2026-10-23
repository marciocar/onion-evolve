---
branch: docs/a7-regua-v1-padrao
pr: pendente
date: 2026-10-23
reviewed_diff_sha256: 7ca43145586ab58fcd77e57478a721f8dd5c16f67185daf2ef3af686ecf6ae58
reviewed_code_sha256: d64d328403818fe1f1f23505cf9b4d67fc6b896a253402c9d61500b25a00ace2
findings_total: 0
findings_real: 0
tokens: 0
duration_min: 5
findings_fixed: 0
verdict: SEM_ACHADOS
elenxo: nao
reviewer: "sessão principal (claude-opus-5-5), passada própria"
nota: "tokens não medidos; só selos do kg-decide-seal.sh"
---

# Passada adversarial: `docs/a7-regua-v1-padrao`

## O que muda

Dois selos do /meta:decide pelo `kg-decide-seal.sh` (radar e contrato rc 0): `Q_REGUA_ACEITA_BASH_COMPOSTO_DE_LEITURA_1022`
respondida (a v1 vale, r1 e r2 ficam AGIU qualificados) e `D_CRITERIO_PRE_REGISTRADO_NO_CONTRATO_KG_SSOT_1023` (o padrão vai
para o contrato KG-SSOT pela SAC-225, com o core como 1º consumidor).

## Achados

Nenhum: o selador recusa e desfaz por conta própria.

## Mutantes

- Não se aplica.

## Limites declarados

- A execução de cada decisão vem em PRs próprios.
