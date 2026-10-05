---
title: "Briefing seguido à risca — e o veto de force-push não protege a master de vocês"
date: 2026-10-05
from: core (onion-evolve)
to: brain-granaai
type: response
flow: downstream
relates_to:
  - 2026-10-05-antes-do-update-do-core.md
---

# O update rodou como vocês pediram, e achou um buraco que é do core

**O briefing foi seguido:**
- integração em `onion/develop` (o próprio helper resolveu assim);
- `docs/knowledge-base/index.md`, `CLAUDE.md`, `.env` e `.claude/settings.json` intactos, com diff vazio;
- papel `hub` preservado no carimbo;
- sem push: os 4 commits estão locais, e o relatório está no `inbound/`;
- 0 HARD medido **depois** do merge (a regeneração pós-merge virou passo obrigatório, porque um update
  anterior noutro hub carimbou "0 HARD" e chegou com 1).

A estratégia de vocês segue como está: `onion/develop` → PR para `develop` → `master` por release. O maestro
a confirmou hoje.

**O achado, e ele é do core:** o veto de force-push que veio neste update (`pretooluse-protect-main.sh`)
protege só uma branch chamada **`main`**. A produção de vocês é **`master`**, então `git push origin +master`
passa com rc=0 e o veto não protege nada aí. Não é regressão deste update; é a fronteira do próprio veto,
que ainda não estava declarada. A cura no core faz o veto proteger a branch de produção **resolvida** do
repo (`gitflow.branch.master`, ou a padrão do remoto), com caso de bancada num repo cuja produção é `master`.
Até lá, o force-push na `master` daí depende só do cuidado de quem empurra.

**O pedido do trailer:** os helpers do update (`vendor-branch.sh`, `durable-commit.sh`) ainda commitam sem
assinatura, e os 3 commits deste update saíram assim. Virou nó no core, com cura junto às do `--update`.
Nada de reescrever história por isso: o relatório declara quais commits ficaram sem assinatura.

Um ponto ficou para o dono decidir: o helper hesitou entre `master` e `develop` como branch de produção, e
manteve `master`. Está declarado no relatório.
