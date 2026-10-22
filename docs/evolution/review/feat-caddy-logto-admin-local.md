---
branch: feat/caddy-logto-admin-local
pr: pendente
date: 2026-10-22
reviewed_diff_sha256: pendente
findings_total: 3
findings_real: 3
tokens: 0
duration_min: 15
findings_fixed: 3
verdict: CORRIGIDO
elenxo: nao
reviewer: "sessão principal (claude-opus-5-5), passada própria"
nota: "tokens não medidos (passada na própria sessão, sem subagente)"
---

# Passada adversarial: `feat/caddy-logto-admin-local`

## O que muda

- `ops/caddy/conf.d/logto-admin-local.caddy` (novo): site `http://127.0.0.1:3013`, `bind 127.0.0.1`, que repassa ao
  admin do Logto (`127.0.0.1:3012`) com `Host`, `X-Forwarded-Host` e `X-Forwarded-Proto: https`.
- `docs/onion/graph/vps-shared-tools-2026-07.kg.yaml`: nó `E_LOGTO_ADMIN_LOCAL_LISTENER_1022` com a medição, ligado
  a `ENT_logto`.

## Achados

1. O 1º bloco só reescrevia `Host` e `X-Forwarded-Proto`. Num Caddy descartável em `127.0.0.1:3014` o issuer saiu
   `auth.onionevolve.com` e o token deu 400: o Caddy preenche `X-Forwarded-Host` com o host original e o Logto o
   prefere. Curado com `header_up X-Forwarded-Host`; o mesmo teste deu issuer `console` e token 200.
2. Sem `bind 127.0.0.1` o endereço do site não basta para não abrir a porta em todas as interfaces. O bind está
   explícito; no teste, `ss -ltn` mostrou só `127.0.0.1:3014`.
3. O nó nasceu órfão (radar `integrity.orphan-node`): ganhou `TRACES_TO ENT_logto`.

## Mutantes

- Sem `X-Forwarded-Host`: token 400 (medido). Sem `X-Forwarded-Proto: https`: token 400 (medido no `curl` direto
  ao `:3012`). Os dois cabeçalhos são necessários.

## Limites declarados

- O `# verify:` cobra 200 no `openid-configuration`, que o tenant errado também responde: ele prova que a escuta está
  no ar, não que o tenant é o admin. A prova do tenant é o issuer `console` medido no teste e, depois, a tela de
  identidades do admin sem 502.
- O secret do `m-default` foi lido do banco para uma variável de shell e nunca impresso, como faz o
  `ops/bridge-auth/logto-provision.sh`.
