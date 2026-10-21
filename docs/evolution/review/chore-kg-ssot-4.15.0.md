---
branch: chore/kg-ssot-4.15.0
pr: pendente
date: 2026-10-21
reviewed_diff_sha256: pendente
findings_total: 0
findings_real: 0
tokens: 0
duration_min: 10
findings_fixed: 0
verdict: SEM_ACHADOS
elenxo: nao
reviewer: sessão principal
nota: "tokens 0 = não medido; vendor por kg_vendor.py com sha256 por arquivo (vendor íntegro), medido pelo ops/kg-gate-ci.sh"
---

# Passada adversarial: `chore/kg-ssot-4.15.0`

## O que muda

O vendor `vendor/kg-ssot` sai da kg-ssot-v4.13.1 para a kg-ssot-v4.15.0 (espelho 85c5ddd), passando pela
4.14.0. A base do gate em `.kg-ssot/gate.json` foi regravada, e o comentário do pin em
`onion-validate.yml` foi alinhado.

## Achados

Nenhum. Medi três coisas:
- **Veredito sem troca:** pelo caminho do CI (`ops/kg-gate-ci.sh`), são 179 grafos e os mesmos 16 na
  dívida herdada. Só a identidade do contrato muda (62909ed9 → f4e5253a), como a sessão do kg-ssot avisou.
- **Chaves novas no radar do core:** `kg-radar.sh --integrity --schema` sai 0 nas 13 fixtures de
  `spec/conformance/fixtures/latest/form/reverify/`, válidas e de aviso. O radar não fecha as chaves do
  nó, então `reverify_every`, `reverify_on` e `retain_for` não reprovam.
- **Vendor íntegro:** o `kg_vendor.py` confere o sha256 dos 490 arquivos.

## Mutantes

Não se aplica: vendor de terceiro com checagem de integridade própria, sem guarda nova.

## Limites declarados

O radar do core ainda NÃO LÊ o vencimento: o leitor `STALE-EXPIRED` é trabalho seguinte e consome o
`kg_validate.py --due` ou os campos. Não rodei os testes próprios do kg-ssot, que já rodam na release
dele.
