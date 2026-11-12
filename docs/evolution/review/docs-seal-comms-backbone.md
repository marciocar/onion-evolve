---
branch: docs/seal-comms-backbone
pr: pendente
date: 2026-11-12
reviewed_diff_sha256: 65cf94b0434d9bf605d9a3b23f1ce80d1a62a2b77a5c7aec7e1f2fb6fe8cd69b
reviewed_code_sha256: 23a19f5bf341a582ff362eacba3619ba30acd37c976e0f9bf932bc8cb4b8d8d7
findings_total: 1
findings_real: 1
findings_blocking: 0
tokens: 0
duration_min: 60
findings_fixed: 1
verdict: FIXED
elenxo: true
reviewer: "Delphi em 3 rodadas (core, kg-ssot, curadoria, hub) e o maestro, que corrigiu a síntese ao selar"
nota: "tokens 0 = não medido"
---

# Passada adversarial: `docs/seal-comms-backbone`

## O que muda

Este PR traz dois selos do maestro, no estudo company-brain-non-devs-2026-11, e a tabela de critérios e valores:
- `D_COMMS_BACKBONE_COMPOSED_1112`: a construção do backbone, orquestrada pelo core, na ordem da dor medida;
- `D_COMMS_BACKBONE_VALUE_TABLE_1112`: as qualidades do transporte se vendem, medidas;
- `comms-backbone-value-table.md`: a tabela de critérios e valores.

## Achados

1. **Curado pelo maestro.** A síntese dizia "o transporte não se vende". O maestro corrigiu: o encanamento não se vende sozinho, mas as qualidades do transporte se vendem, e cada uma precisa de critério e medida (segurança, criptografia, rastreabilidade, observabilidade, monitoramento, eventos, agendamento, gestão de falhas e auditoria). A tabela registra isso, e o segundo selo complementa o primeiro.

Na rodada 2, a crítica cruzada corrigiu duas posições:
- a de "toda interação vira nó", que transformaria o grafo em log com dado pessoal;
- a ordem que punha a conformidade A2A antes das dores medidas no mesmo host.

## Mutantes

Não se aplica: são selos e prosa.

## Limites declarados

- A coluna "Hoje" da tabela é a leitura do core e precisa ser medida peça por peça.
- Ainda falta medir que o comprador paga pelas qualidades e pela governança. Esse é o limite da curadoria.
