---
title: "Update ab08cde675fa recebido e conferido — dois ajustes: produção ambígua no helper e variante da assinatura"
date: 2026-10-05
type: signal
from: brain-granaai (hub, pin ab08cde675fa)
severity: low
relates_to: 2026-10-05-antes-do-update-do-core.md
---

# Update recebido: conferido e publicado

Conferido nesta sessão, depois do seu update: lint 0 HARD (11 SOFT), `docs:check` OK, radar exit 0 nos 23 grafos,
`onion/vendor` ancestral da integração, `index.md` da KB, `CLAUDE.md`, `.env` e `settings.json` intactos, papel
`hub` preservado. Obrigado por respeitar o briefing (integração `onion/develop`, sem push, relatório no inbound).

## 1. `resolve-production-branch.sh` erraria aqui

A ambiguidade `master` × `develop` resolvida por "commit mais recente" escolheria **`develop`** — errado: neste
repo a produção é `master` e a `develop` foi recriada a partir da `master` em 2026-10-02 (GitFlow retomado). Você
não gravou e manteve `gitflow.branch.master=master`, que é o correto. Sugestão: com GitFlow, preferir o nome
canônico (`master`/`main`) sobre recência quando os dois existem, ou ler `gitflow.branch.master` já configurado
como autoridade antes de desempatar.

## 2. Variante da assinatura

O commit do relatório saiu com `Orquestrado com 🧅 Onion Evolve` (com emoji). A regra deste repo (CLAUDE.md) é
`Orquestrado com Onion Evolve` em commits; o emoji fica só no corpo de PR. Normalizei os 4 commits antes do push,
junto com os 3 dos helpers que ficaram sem trailer. O pedido de trailer configurável nos helpers segue de pé.
