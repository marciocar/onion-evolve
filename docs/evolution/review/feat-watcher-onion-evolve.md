---
branch: feat/watcher-onion-evolve
pr: pendente
date: 2026-11-23
reviewed_diff_sha256: 1bda6ef3101c508db634fb7d50f816266b388b870cafd0870060551fed41ada1
reviewed_code_sha256: 3c8b068460350d2eb2250e4d10b1eba7f338bfa7f7b10f05724e7defef3b132d
findings_total: 4
findings_real: 3
findings_blocking: 1
tokens: 109814
duration_min: 8
findings_fixed: 2
verdict: FIXED
elenxo: true
elenxo_isolado: true
reviewer: subagente general-purpose (opus), isolado; mandato REFUTAR, só leitura (stat da chave privada, nunca o conteúdo)
nota: "uma rodada isolada; o bloqueio (mapa da federação) e o comentário do cabeçalho foram curados; o ato do maestro (policy approve da fila) fica fora do PR, declarado"
---

# Passada adversarial: `feat/watcher-onion-evolve`

## O que muda

O core faz a sua parte para o vigia de webhooks da messaging (o ato `tools/acts/watcher-install.sh`, PR #62 dela):

- `members.yaml`: o membro `watcher-onion-evolve` (kind method, standalone, parent onion-evolve), que só ASSINA sinais
  ao core (`a2a.sends_to: onion-evolve`, `keys: [watcher-onion-evolve-1]`), sem receber nem corrigir;
- `jwks/watcher-onion-evolve-1.pem`: a chave PÚBLICA pinada (RSA 3072), gerada pelo core com `a2a-keygen.sh`; a
  privada fica em `~/.config/onion/a2a/` (0600) e nunca foi impressa nem lida;
- `ops/caddy/service-vhosts.tsv`: a linha do `hooks.caddy` (hooks.onionevolve.com → 127.0.0.1:8791) para o
  `install-caddy-config.sh` instalar o vhost a partir do blob commitado na main da messaging;
- `docs/onion/federation-map.md`: o mapa regenerado com o membro novo.

## Achados

| # | achado | real? | bloq.? | destino |
|---|---|---|---|---|
| 1 | O mapa da federação ficou desatualizado (REGRA 38 (Mapa da federação sincronizado com members.yaml)): faltavam o nó, a aresta e a linha do membro novo | sim | sim | Curado: `graph.sh --map` regenerado no mesmo commit |
| 2 | O cabeçalho da lista de vhosts dizia «todos em `master`», e a linha nova usa `origin/main` | sim | não | Curado: o comentário diz que a messaging usa `main` |
| 3 | O ato lê o registro do checkout principal, não da worktree: só passa depois do merge e do pull | sim | não | Declarado: é a ordem dos atos (merge → pull → ato) |
| 4 | O ato também cobra a política do receptor aprovada com o membro novo | não | não | Fica fora do PR: é ato do maestro (`queue … policy approve`), dito no corpo do PR |

## Conferido pelo revisor

- A impressão SHA-256 do DER SPKI do `.pem` bate com a declarada (`ee989e9a…fc86`); o arquivo é só público.
- `members-validate.sh` rc 0 (35 membros); `trust-topology-check.sh --dry-run`: sinal ao core AUTORIZADO, envio
  lateral BLOQUEADO, correção ao core BLOQUEADA.
- A linha do vhost tem as 6 colunas que o `service_rows()` do `install-caddy-config.sh` exige, e o `hooks.caddy` da
  main da messaging declara exatamente esse host e esse upstream.

## Limites declarados

- Não rodados: o `install-caddy-config.sh --plan` e o `caddy adapt` (mexem com /etc/caddy e sudo; são do maestro).
- O DNS de hooks.onionevolve.com é ato do maestro (o ato de DNS da vps-ops).
