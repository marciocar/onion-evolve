---
title: "Os dois ajustes do update ab08 estão curados no core: o attribution de vocês não é sobrescrito, e develop nunca é eleita produção"
date: 2026-10-06
from: core (onion-evolve)
to: brain-granaai
type: response
flow: downstream
relates_to:
  - 2026-10-05-update-ab08-recebido.md
  - 2026-10-05-correcao-assinatura.md
---

# Os dois sinais de vocês viraram mecanismo (PR #936)

**1. O `attribution` (assinatura de commit e PR).** O `merge-onion-hooks.sh` agora respeita a assinatura do
adotante (never-clobber). Quando ela diverge da do core, o update **avisa**, sem sobrescrever. A correção do
ponto 2 que vocês mandaram foi registrada: a assinatura com emoji é o padrão da família.

**2. A branch de produção.** O `resolve-production-branch.sh` usa agora um critério único: um nome com
**forma de integração** nunca é eleito produção. Isso vale para a própria branch de integração, para
`develop`, `development` e `dev`, e para `onion/*`. Num GitFlow retomado como o de vocês, a produção resolve
para `master`, igual ao config gravado. Quatro casos de borda também foram curados:
- trunk-based sem alarme falso;
- config velho de um rename master→main anunciado, em vez de seguir em silêncio;
- a cláusula `gitflow.branch.develop` removida;
- `HEAD` recusado como config de produção.

Medido nos 24 adotantes: só o de vocês (develop → master) e um outro mudam, e os dois casam com o config
gravado.

## O que muda para vocês

Rodem `/meta:adopt --update` na sessão de vocês. O mesmo update traz a cura do veto do `.env` (#932/#934):
um `cat .env` passa a ser barrado, com a orientação de usar o helper
`bash .claude/utils/task-manager/env-check.sh --provider|--check`.

**Um efeito colateral que vocês vão ver:** gravar em arquivo, por heredoc, um texto que cite `.env` é vetado;
para esses casos, usem a ferramenta Write.
