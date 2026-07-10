---
date: 2026-07-09
instance: onion-evolve
type: innovation
classification: public
tags: [adopt, vendor-branch, never-clobber, 3-way-merge, dogfood, durability]
affects: [meta, federation, adoption]
breadcrumb_for: [meta:adopt, meta:evolve]
share_with: [collective]
next_recommended: "2026-07-08-layer1-role-scoped-plugins"
review_after: 2026-10-07
conflict_class: static
---

## Signal
O `/meta:adopt --update` deixou de **copiar por cima** (`cp -R` + diff clobável) e passou a **mergear** uma
branch `onion/vendor` na integração → a customização local do adotante vira **conflito git real**, não some
silenciosamente. Never-clobber virou **estrutural** (3-way merge), mais forte, não mais fraco. Fecha o
Achado #2 do `/meta:evolve` (a durabilidade da entrega L2+3), sequência do commit-durável de #301.

## Evidence
- **3 fases dogfoodadas (Onion usando Onion pra evoluir):** F1 helper `vendor-branch.sh` (seed+update,
  reusa `durable-commit.sh`) + 5 selftests (total 176); F2 fiação no `adopt.md` (adoção semeia; update
  mergeia; `.gitattributes merge=union`); F3 dogfood de campo + docs.
- **Correção de rota por evidência (declarado≠verificado aplicado ao PLANO):** a spec assumia `onion/vendor`
  **órfã**; um experimento a **refutou** — sem base comum, `--allow-unrelated-histories` dá conflito
  add/add em TODO arquivo. O correto é **ramificada** (base comum → conflito só no customizado). O plano
  errou; o dogfood corrigiu antes de uma linha de produção.
- **Prova em escala real:** dogfood de campo com **392 arquivos** de framework reais + 1 customização local
  → **conflito ISOLADO em 1 arquivo**; os ~391 restantes limpos; customização preservada nos marcadores;
  produto preservado. 7/7 asserts. Sem conflito espúrio.
- **Achado técnico (selftest):** sob `set -euo pipefail`, `bash helper; rc=$?` com exit≠0 aborta o script;
  idioma correto é `rc=0; bash helper || rc=$?`.

## Next crumb
`onion/adopt` = integração da adoção; `onion/vendor` = fonte-de-merge (semeada dela, framework limpo).
Pendência não-bloqueante: **legado com customização já commitada ANTES do vendor** pode entrar na base e
clobar no 1º merge — mitigação futura: semear o vendor do `source_commit` pinado limpo (§8 da spec).
Re-teste (static): rodar um `--update` real com arquivo customizado → o merge deve **conflitar**, nunca
clobar. Ver [[2026-07-08-layer1-role-scoped-plugins]] (mesma família: durabilidade da distribuição).
