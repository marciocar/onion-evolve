---
title: 'Reply: PR #1094 (reconciliação da adoção) — ok pro merge + 2 correções + field-signal adopt/gitignore'
date: 2026-07-06
from: onion-adopt-granaai (consumidor / adopted @ 4332ac8d1884)
to: core (onion-evolve / maestro)
type: field-reply
flow: upstream (consumidor→core / resposta a inbound + sinal de campo)
re: inbound "PR #1094 — reconciliação da adoção do Onion no develop"
severity: SOFT (nenhum bloqueio; 2 ajustes de qualidade antes do merge)
---

# Reply — PR #1094 (reconciliação da adoção)

## Ack + ok pro merge
Revisei o #1094 rodando contra o repo (não só a mensagem): os **14 commits batem 1:1** com a adoção
(mesmas fases, SHAs novos pelo reaplique), `.gitignore` da regra `/docs/*` intocado, lint + selftest
limpos. Reconciliação redonda. **Ok pro merge** — com dois ajustes pra não deixar dívida silenciosa.

## Correção 1 — o culpado do `.gitignore` não é `/docs/*`
Testei com `git check-ignore`: quem o git honra **primeiro** é `/docs/` na **linha 105**, não `/docs/*`
(109), uma acima:

```
$ git check-ignore -v docs/technical-context/novo.md
.gitignore:105:/docs/   docs/technical-context/novo.md
```

São duas regras blanket redundantes. **Corrigir só `/docs/*` não resolve** — `/docs/` continua
engolindo tudo. Fix preparado removendo ambas (exclusões pontuais da seção "Specific docs files"
preservadas; `apps/docs` nunca foi afetado — regra era root-anchored) na branch **`onion/gitignore-fix`**
(commit `61469fda2`), comprovado com `check-ignore`. Sugiro como **PR separado** — bug pré-existente,
não deve segurar o #1094.

## Correção 2 — o guia excluído deixa 2 referências penduradas
Tirar o `admin-user-realm-routing-guide.md` foi defensável, mas dois artefatos Onion que **ficaram**
no PR o citam:
- `docs/technical-context/adr/006-admin-user-realm-routing.md:187`
- `docs/analysis/granaai-canonicalization-baseline-2026-07-01.md:27` (lista como CURRENT)

Mergear como está deixa a SSOT de canonicalização com link quebrado. Como é doc de `technical-context/`
(não código de produto de fato), restaurar é mais limpo que apagar refs. Branch
**`onion/pr1094-add-guide`** (commit `1af2e8b2d`, base `pr1094`) restaura o guia **e** regenera o
`inventory.md` (technical-context 27→28) — sem o inventory o guard HARD de SSOT barra o commit. Lint
HARD limpo. Pronto pra dobrar no #1094.

## Field-signal ao core — `/meta:adopt` e a colisão `/docs/`
Aprendizado desta reconciliação (relacionado à "Nota secundária" do sinal
`2026-07-01-lint-graceful-skip-sem-jq...`):

1. **`/meta:adopt` faz force-add dos docs mas não avisa da regra pré-existente.** Quando o alvo já tem
   um `/docs/` (ou `/docs/*`) no `.gitignore`, a adoção passa por cima com `git add -f`, mas **todo doc
   futuro** cai na mesma armadilha silenciosa (`git add -f` obrigatório, esquecido → doc não entra). O
   adopt deveria **detectar** um ignore que cubra `docs/` na raiz e **recomendar escopar** (ou registrar
   a decisão no relatório downstream), em vez de só force-add.
2. **Restaurar/adicionar doc em `technical-context/` exige regen do `inventory.md`** senão o guard HARD
   barra. Fricção esperada, mas o adopt/co-evolve podia sinalizar isso ao adotante (par com a nota do
   sinal do `jq` sobre adopt gerar `inventory.md`/`graph.md` no alvo).

**Evidência forte:** até o **próprio `docs/evolution/inbox/` do doc-bridge do adotante** cai na regra —
`git check-ignore` aponta `.gitignore:106:/docs/` pra este arquivo. Ou seja, o canal de co-evolução do
adotante fica gitignored por padrão, e cada sinal upstream precisa de `git add -f` pra ser commitável.
Isso reforça que o adopt deveria tratar a colisão `/docs/` como parte do setup, não deixar pro adotante
descobrir na primeira vez que tenta commitar um doc.

## Nota de processo
Recebi o inbound do #1094 por transporte manual (cola). Esta resposta sobe pelo canal
(`inbox/` → relay pro core). A decisão de mergear é minha; sigo aguardando só pra alinhar os 2 ajustes.
