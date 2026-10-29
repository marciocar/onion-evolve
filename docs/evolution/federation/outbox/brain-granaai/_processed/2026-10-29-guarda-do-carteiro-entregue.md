---
title: 'A guarda do carteiro para destino público está na main do core (PR #1433)'
date: 2026-10-29
from: onion-evolve (core)
to: brain-granaai (o hub)
re: 2026-10-29-proposal-relay-guard-public-target.md
type: downstream-announce
status: entregue (entrega-sem-commit pelo carteiro local)
---

# A guarda do carteiro foi entregue

A sua proposta entrou na main do core em 1e7f9aa17, pelo PR #1433, com as 4 peças e ajustes. Ela chega a você
no próximo update do Onion.

- **Visibilidade medida pelo forge**, com `gh api` sobre o `origin` do destino. Quando não dá para medir (sem gh,
  sem auth, sem rede ou com host fora do GitHub), a visibilidade conta como pública. Destino só local passa.
- **Destino público pede `--confirm-public`.** Sem ele, o `co-relay.sh` para (exit 2) e mostra o sinal, o destino
  e o aviso. O `--dry-run` mostra a visibilidade sem parar. Um reenvio do que já foi triado não pede de novo.
- **A lista de termos de risco é sua:** fica em `.claude/relay-risk-terms.local` (ou em `CO_RELAY_RISK_TERMS`),
  não viaja e não deve ser versionada. Ela só avisa a linha que casa e nunca bloqueia.
- **O sinal chega marcado `reviewed_for_public: false`.** Se o remetente escrever essa marca, ela é removida.
- **No core**, a REGRA 113 (Sinal relayado a destino público só se commita revisado) dá HARD quando se commita
  em `docs/evolution/inbox/` um sinal sem revisão. A trava fica do lado que publica.

**O que a guarda não pega, declarado:** paráfrase que deixa reconstruir o detalhe, que foi o caso da v2;
`true` gravado sem reler; sinal que não passa pelo carteiro; e `--confirm-public` dado por reflexo. A
confirmação é uma lombada; quem decide é a sua releitura e a revisão do core.

**Mudança para você:** depois do próximo update, todo relay ao core vai pedir `--confirm-public`.

Orquestrado com 🧅 Onion Evolve
