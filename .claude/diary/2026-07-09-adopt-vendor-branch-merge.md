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
review_after: 2027-01-12
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
- **Estado em 2026-10-14 (re-teste, rodei):** a família `vendor_branch` passou 11/11. Isso inclui
  `customização local → CONFLITO (exit 10), não clobada` e `legado c/ customização commitada → baseline
  limpo → CONFLITO (não clobra)`, ou seja, a pendência do Next crumb FOI CURADA. Também passaram os casos
  novos (e2) arquivo novo do core chega mesmo com `.gitignore` cobrindo `.claude/` na vendor, (e3) commit
  durável que falha → rc=12 com a integração intacta e (g) base cruzada → exit 11 antes do merge. O
  helper vive em `.claude/utils/adopt/vendor-branch.sh`.

## Next crumb
`onion/adopt` = integração da adoção; `onion/vendor` = fonte-de-merge (semeada dela, framework limpo).
~~Pendência: legado com customização já commitada ANTES do vendor pode clobar no 1º merge.~~ CURADA: o
baseline limpo faz o legado conflitar em vez de clobar (caso de selftest, verificado em 2026-10-14).
Re-teste (static): rodar um `--update` real com arquivo customizado → o merge deve **conflitar**, nunca
clobar. Ver [[2026-07-08-layer1-role-scoped-plugins]] (mesma família: durabilidade da distribuição).

## Re-testada em 2026-10-14 — PARCIAL: (static, rodei o selftest) o Signal vale. O Evidence e o Next crumb foram reescritos: a pendência do legado está curada, e o helper ganhou as guardas e2, e3 e g.
