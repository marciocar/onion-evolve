---
branch: chore/caddy-sandbox-verify-200
pr: pendente
date: 2026-10-22
reviewed_diff_sha256: pendente
findings_total: 2
findings_real: 2
tokens: 0
duration_min: 5
findings_fixed: 2
verdict: CORRIGIDO
elenxo: nao
reviewer: "sessão principal (claude-opus-5-5), passada própria"
nota: "tokens não medidos (passada na própria sessão, sem subagente); diff de 2 arquivos"
---

# Passada adversarial: `chore/caddy-sandbox-verify-200`

## O que muda

- `ops/caddy/conf.d/sandbox.caddy`: entra `# verify: https://sandbox.onionevolve.com/sandbox.html 200` ao lado do
  verify do 404, e o comentário que dizia "acrescente depois da 1ª publicação" passa a registrar que ela aconteceu.
- `docs/onion/graph/vps-shared-tools-2026-07.kg.yaml`: nó `E_UI_SANDBOX_ORIGIN_LIVE_1022` (evidence, confirmed)
  com a medição da publicação, `SUPPORTS` o `C_UI_SANDBOX_ORIGIN_VERSIONED_NOT_LIVE_1022`, que segue open até o
  teste no navegador.

## Achados

1. O nó novo citava um caminho de máquina em `verified_against` (REGRA 99 (Caminho de máquina no grafo)): reescrito
   como `onion-bridge@63542508:deploy/sandbox/sandbox.html`.
2. `provenance.locality: "vps"` fora do vocabulário do contrato: trocado por `host`. O contrato saiu rc 0 depois.

## Mutantes

- O extrator do `ops/install-caddy-config.sh` (o mesmo `sed` da linha 183) aplicado ao arquivo devolve as duas
  linhas; contra o vivo: `/sandbox.html` esperado 200 obtido 200, `/qualquer` esperado 404 obtido 404.
- Mutante: esperar 404 em `/sandbox.html` diverge do vivo (obtido 200), então o verify reprovaria a instalação.

## Limites declarados

- O vhost não foi reinstalado neste PR: a mudança é só a linha de verify, e o Caddy vivo já serve o mesmo bloco.
  A próxima rodada do `ops/install-caddy-config.sh` cobra o 200.
- O CSP no navegador continua não medido; é o dogfood do passo 4 do piloto.
