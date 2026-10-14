---
date: 2026-07-03
instance: onion-evolve
type: learning
classification: public
tags: [selftest, sandbox, latent-bugs, pipefail, dogfooding]
affects: [meta, engineering]
breadcrumb_for: [onion-validation, meta:evolve]
share_with: [collective]
next_recommended: "2026-07-01-audit-dogfood-finds-code-bugs"
review_after: 2027-01-12
conflict_class: static
---

## Signal
Escrever guarda de selftest em **sandbox mínimo** (mktemp, fixture só com o essencial) expõe
pressupostos invisíveis do repo real — 2 bugs latentes achados assim em 3 dias. Ao criar um modo
novo de selftest, NÃO copie uma entrada real como fixture: construa a fixture mínima; a diferença
entre ela e o repo real é exatamente onde os bugs latentes moram.

## Evidence
- Bug 1 (2026-06-30): lint morria silencioso sem `jq` — 12 guardas com `|| return` sob `set -e`;
  invisível no ambiente com jq, exposto ao rodar em ambiente mínimo.
- Bug 2 (2026-07-02, modo diary-crumbs): `diary-index.sh` morria silencioso com entrada sem
  `share_with` (grep -v saindo 1 sob pipefail) — invisível no repo real porque TODAS as entradas
  tinham o campo populado; a fixture mínima do sandbox não tinha, e quebrou na 1ª rodada.
- Padrão comum: `set -euo pipefail` + pipeline cujo passo intermediário legitimamente "não acha
  nada" = morte silenciosa. Grep em pipeline sob pipefail exige `{ grep ... || true; }`.

## Next crumb
Ao revisar scripts de `.claude/validation/` e hooks: procurar pipelines com grep/awk
intermediário sem proteção `|| true` — candidatos a morte silenciosa no campo (adotante com dados
diferentes dos nossos). O selftest de cada script novo nasce com fixture mínima, não com cópia
do estado atual.

## Re-testada em 2026-10-14: (static, contra a melhor fonte atual) a cura do bug 2 está no código (`diary-index.sh` l.45-47, `{ grep -v '\[\]' || true; }`), e a família `diary_crumbs` passou 8/8 em fixture mínima, inclusive "entrada sem conflict_class → passa". A doutrina posterior estende esta, sem contradizê-la: a bancada espelha o runner (locale C, `set -e`) e o pipefail tem uma classe nova (EPIPE de quem fecha cedo).
