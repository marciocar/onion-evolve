---
branch: docs/wsync-workspace-updated-1022
pr: pendente
date: 2026-10-22
reviewed_diff_sha256: pendente
findings_total: 1
findings_real: 1
tokens: 0
duration_min: 5
findings_fixed: 1
verdict: CORRIGIDO
elenxo: nao
reviewer: "fork da sessão principal (claude-opus-5-5), passada própria"
nota: "tokens não medidos; só grafo"
---

# Passada adversarial: `docs/wsync-workspace-updated-1022`

## O que muda

- `E_WORKSPACE_ADMIN_ONION_ATUALIZADO_1022` no grafo das rotas da VPS, `SUPPORTS` a decisão
  `D_UI_PILOT_WORKSPACE_ATUALIZA_POR_STAGING_E_WRAPPER_1022`: o workspace do admin no /chat no pin 94d24a0ccc68,
  conferido pelo `verify` do wrapper, com o ACL do runner restaurado.

## Achados

1. O localizador citava o diretório de backup da VPS (REGRA 99 (Caminho de máquina no grafo)): reescrito pela
   forma. Radar e contrato rc 0.

## Mutantes

- Não se aplica: só grafo.

## Limites declarados

- A medição é do instante do `verify`; o workspace segue escrito pelo serviço depois dela.
