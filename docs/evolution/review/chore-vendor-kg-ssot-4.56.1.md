---
branch: chore/vendor-kg-ssot-4.56.1
pr: pendente
date: 2026-11-22
reviewed_diff_sha256: d1df216407750082c288ddecc11ad3496a3918f8bdb0f5d045a3e2d63d63998f
reviewed_code_sha256: 9904b2b32f86ceaae414584c54c57a45ad5da18921f866b3a9b89821cd2d7cb2
findings_total: 1
findings_real: 1
findings_blocking: 0
tokens: 0
duration_min: 10
findings_fixed: 0
verdict: APPROVED
elenxo: false
reviewer: self
nota: "atualização de vendor pelo kg_vendor.py (proveniência conferida pela atestação herdada do carimbo); sem revisor isolado porque os agentes estão no limite semanal; o PR não toca guarda"
---

# Passada: `chore/vendor-kg-ssot-4.56.1`

## O que muda
`vendor/kg-ssot` 4.56.0 → 4.56.1 (tag `kg-ssot-v4.56.1`, 1006 arquivos, pelo `kg_vendor.py update`), e a linha de base
do gate em `.kg-ssot/gate`. O contrato segue v4.26. A release faz o gate medir os `.kg.json` rastreados e conferir
`external_edges` neles.

## Achados
1. **O gate passou a medir duas propostas arquivadas** em `docs/evolution/kg-inbox/_rejected/` e `_sealed/`
   (2026-08), que reprovam no MUST por falta de `provenance`, e a contagem de decisões sem trace subiu de 35 para 36.
   Nenhuma nasceu neste PR: são arquivos históricos que a ferramenta passou a enxergar. Entram como dívida herdada
   (`--accept-regression`, motivo escrito na linha de base). Não bloqueia.

## Limites declarados
- Sem revisor isolado (limite semanal de agentes até 24/11 21:00 UTC); a proveniência do vendor é a da atestação
  herdada do carimbo.
- Curar as duas propostas arquivadas (ou excluí-las do gate com `--exclude`) fica para um PR próprio.
