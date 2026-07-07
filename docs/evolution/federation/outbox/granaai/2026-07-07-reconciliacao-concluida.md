---
title: 'Reconciliação concluída — PR #1094 e #1096 mergeados em develop'
date: 2026-07-07
from: onion-evolve (core / maestro principal)
to: granaai (Grana.Ai — consumidor, regulated)
re: PR #1094 (reconciliação, 14 commits) + PR #1096 (fix .gitignore) + comentário de review do Mauricio (2026-07-07T01:40:44Z)
type: downstream-announce
classe: COMPATÍVEL
status: a transportar (rascunho na staging do core)
---

# 📣 Anúncio do core — reconciliação concluída, dois ajustes fechados

> Push core→derivado (downstream, doc-bridge), transportado pelo humano.

Obrigado pela revisão rigorosa no #1094 — os dois ajustes que você apontou foram fechados:

1. **Guia restaurado** — cherry-pick de `1af2e8b2d` aplicado na branch `onion/reconcile-2026-07-06`
   (`docs/technical-context/admin-user-realm-routing-guide.md` de volta, `inventory.md` 27→28).
   Lint HARD confirmado limpo antes do merge.
2. **`.gitignore` corrigido** — PR #1096 mergeado (removeu as duas regras blanket, linha 105 `/docs/`
   e linha 109 `/docs/*`; `apps/docs` intacto).

**Ambos os PRs estão `MERGED` em `develop`** (verificado via API, não só via comentário).
`members.yaml` do core já reflete isso: `onion_version` passou de "declarado" para **verificado
byte-a-byte** (lemos `.claude/.onion-version` direto), `reconciliation_status: merged_2026-07-07`.

## Sobre o sinal que você mencionou ter relayado

Procuramos em todas as branches do granaai (pós-`fetch`) e no inbox do core — **o sinal formal não
chegou por nenhum canal que a gente consiga verificar**. O achado técnico em si (a real causa raiz
do `.gitignore`, linha 105 vs. 109 — e a ironia de que essa mesma regra engolia o `docs/evolution/
inbox/` do próprio doc-bridge) a gente já tinha, verbatim, no seu comentário do #1094. Reconstruímos
como sinal formal do lado do core (`docs/evolution/inbox/2026-07-07-sinal-gitignore-blanket-engole-
inbox.md`, com a proveniência documentada) — não precisa reenviar nada. Só um aviso honesto: se você
esperava que aquele relay tivesse chegado sozinho, ele não chegou — vale checar o mecanismo do seu
lado se isso importar de novo no futuro.

## Ação esperada no adotante

- `git checkout develop && git pull origin develop` — trazer os 2 merges pro seu clone local.
- Sem `/meta:adopt --update` necessário — nada no framework vendorizado mudou, só conteúdo do
  próprio repo (o guia + o `.gitignore`).
- O canal `docs/evolution/inbox/` agora comita normal (sem precisar de `-f`) — a regra que o
  engolia foi removida no #1096.
- Tratado → `git mv` deste arquivo para `inbound/_processed/`.

---
> **Transporte (maestro):** este rascunho já foi entregue como **entrega-sem-commit** (untracked)
> em `/home/marciocar/granaai/docs/evolution/inbound/` (mesma máquina) — aparece na próxima sessão
> Claude Code dele lá, sem precisar de cópia manual. Comitar no repo do granaai é decisão do
> Mauricio (ou sua, se preferir fazer agora) — a sessão do core não pusha repo alheio.
