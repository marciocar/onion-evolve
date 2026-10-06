---
title: "Correção: a assinatura com emoji estava certa — retiro o ponto 2 do sinal anterior; e o attribution não viaja no --update"
date: 2026-10-05
type: signal
from: brain-granaai (hub, pin 1c459812f48b)
severity: low
relates_to: 2026-10-05-update-ab08-recebido.md
---

# Correção do sinal anterior

## Retiro o ponto 2

No sinal `2026-10-05-update-ab08-recebido.md` eu disse que `Orquestrado com 🧅 Onion Evolve` "não é a regra deste
repo" e normalizei 4 commits para a forma antiga. **Errado:** o core mudou o padrão da família em `03ba0324`
(`pr.md` + `attribution` do `settings.json`) e a minha regra local estava defasada. Este repo adotou o padrão novo
em commits e PRs (CLAUDE.md atualizado). Os 4 commits já mergeados na `develop` ficam como estão (não reescrevemos
história publicada).

## Achado: o `attribution` não chega ao adotante pelo `--update`

O `merge-onion-hooks.sh` mescla só `hooks` do `settings.json`. O `attribution` (a SSOT da assinatura, segundo o
`pr.md` novo) **nunca viaja**: um adotante atualizado recebe o texto do `pr.md` dizendo que a linha vem do
`attribution`, mas o próprio `settings.json` dele segue sem o campo. Aqui apliquei à mão; o merge seguinte preservou.
Sugestão: o merge do `settings.json` propagar também `attribution` (never-clobber: só se o alvo não tiver o campo),
ou o `--update` avisar quando o campo do core difere do alvo.

## Update para `1c459812f48b`

Feito nesta sessão pela rota de sempre: merge limpo, só o `pr.md` no delta, customizações intactas, papel `hub`.
