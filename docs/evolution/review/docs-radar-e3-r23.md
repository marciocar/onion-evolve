---
branch: docs/radar-e3-r23
pr: pendente
date: 2026-11-04
reviewed_diff_sha256: 7320148801edcbb8c8367cbc037504cf31de3dd39c44a209c2ab5c97bfbf0b77
reviewed_code_sha256: bfc5868f719caddf4bcce3465cf9a0268048788a83e654e6447d74a3837ae9e9
findings_total: 22
findings_real: 5
tokens: 608654
duration_min: 25
findings_fixed: 5
verdict: REPROVADO_E_CURADO
elenxo: sim
reviewer: "juiz separado (subagente opus, mandato REFUTAR), critérios CU1–CU6 pré-registrados em data/judge-verdicts.json; judge-verdict-check rc 0"
nota: "tokens = rodada (2 passadas) + juiz"
---

# Passada adversarial: `docs/radar-e3-r23`

## O que muda

A rodada r23 do radar do Claude Code (eixo E3), o `/meta:cc-update` da 2.1.318: o grafo com 24 nós, a SYNTHESIS,
o CHANGELOG da versão em `data/` (byte a byte com o oficial) e o selo do E3 em `docs/onion/radar-baselines.yaml`.

## Achados

O juiz julgou 22 alvos: 13 SUSTENTA, 4 EXAGERA, nenhum REPROVA e 1 omissão registrada como REPROVA com superação.
Todos os 5 negativos foram aplicados:
- os quatro nós exagerados foram reescritos com a medida do juiz: os 6 processos em binário apagado, o
  `--continue` sem conversa viva, o censo pelo executável e o corte de 3 min que já valia por flag do servidor;
- as omissões viraram nó (o `claude plugin` saindo antes de salvar o token) ou entraram nos nós existentes (o
  daemon e a 2.1.288 sem impacto).

As 5 superações viraram nós `C_SUPERACAO_20261104_…`, e os 4 SUPERSEDES sobre a r22 entraram em `external_edges`.
As Q_* abertas viraram as issues SAC-271 a SAC-274, e a do SDK foi ligada ao SAC-270.

## Mutantes

Nenhum: não há código.
