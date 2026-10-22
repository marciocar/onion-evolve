---
branch: docs/a2a-a7c1-stop-and-record
pr: pendente
date: 2026-10-22
reviewed_diff_sha256: befefa23343c1c9825b4ad767c9ad26783e05f9d442c63c8cf9c0605a2234d56
reviewed_code_sha256: 35799fe31fae7e14e43189380c0a4bff6d557d07501764fb23711a243c32474d
findings_total: 1
findings_real: 1
tokens: 0
duration_min: 5
findings_fixed: 1
verdict: CORRIGIDO
elenxo: sim
reviewer: sessao-principal
nota: >-
  Selo da parada (D_A7C1_PARA_COM_DUAS_REPLICAS_1022), a evidência das r1 e r2 medida pela sessão (juiz,
  fotos, trust-log novo 0600) e a pergunta aberta da régua. Achado curado: o method da pergunta não
  casava o padrão do contrato (derivação → derivado); contrato conforme e radar 0 depois.
---

# Passada adversarial: `docs/a2a-a7c1-stop-and-record`

## O que muda

Grafo do spike: o selo, a evidência `E_A7C1_R1_R2_…` e a `Q_REGUA_ACEITA_BASH_COMPOSTO_DE_LEITURA_1022`.
O `SPIKE-PROTOCOL.md` ganha a §12.16.

## O que a passada tentou refutar

- **A volta foi declarada provada sem medir:** refutado. O ack e o reply foram conferidos pelo
  fetch-replies, o juiz e as fotos foram rodados pela sessão na VPS, e o trust-log foi lido por `ls`.
- **A régua foi afrouxada:** não foi. O A7-C1 fica NÃO PASSOU, e a mudança vira pergunta aberta.

## NÃO MEDIDO

O relógio do notebook depois do lote.
