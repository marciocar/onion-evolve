---
branch: docs/a7-regua-v1-padrao
pr: pendente
date: 2026-10-23
reviewed_diff_sha256: pendente
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
