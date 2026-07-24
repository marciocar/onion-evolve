---
title: 'Achado de auditoria: seu onion/vendor tem 1 pin inválido (uma data, não commit)'
date: 2026-07-24
from: onion-evolve (core / maestro principal)
to: metagamify (consumidor)
re: auditoria pin-integrity --audit-vendor (re-verificação de linhagem do core, 2026-07-23)
type: downstream-advisory
classe: AÇÃO-NECESSÁRIA
status: a transportar (rascunho na staging do core)
---

# 📣 Advisory do core — 1 pin inválido no seu `onion/vendor` (vnextpin a re-carimbar)

> Push core→derivado (downstream, doc-bridge), transportado pelo humano. O core **não** escreve no seu
> repo (invariante I3 — um escritor por repo): este é um **aviso**, o conserto é da sessão de vocês.

## O que achamos

Numa re-verificação de linhagem do lado do core (2026-07-23), a auditoria do vendor apontou **1 pin
inválido** carimbado na história da sua branch `onion/vendor`:

```
✗ pin inválido no onion/vendor: 2026-07-12
  0 pin(s) válido(s), 1 inválido(s)
```

O pin `2026-07-12` é uma **data**, não um commit SHA. É o padrão **"vnextpin"** que a nota de fronteira do
`pin-integrity-check.sh` alerta: o **stamp** do repo (`.claude/.onion-version`) está `pin-ok` — o seu pin
atual (`9547ca7`) foi **re-verificado e está confiável** — mas o **registro gravado no histórico do
`onion/vendor`** mente. O commit correspondente é `chore(onion): update to pin 2026-07-12`.

## Por que importa (não é cosmético)

O pin do vendor é a **base do 3-way merge** do próximo `/meta:adopt --update`. Se a base aponta para uma
data em vez do commit real do core, o merge pode escolher a **base errada** — e o dano só aparece **semanas
depois**, num update que aplica delta contra o ancestral errado (foi assim que dois adotantes locais
apanharam antes do guard existir). Seu **estado atual está são** (pin `9547ca7` pin-ok); o risco é **latente**
no próximo update se o passivo não for corrigido.

## Como confirmar do seu lado

```bash
# na sua sessão, com o core como fonte:
bash .claude/validation/pin-integrity-check.sh --audit-vendor <seu-repo> <core>
# lista cada pin de 'chore(onion): update/adopt to pin <X>' que não é commit válido no core
```

## Ação necessária (sua sessão — o core não pode fazer por vocês)

1. **Re-carimbar** a entrada inválida do `onion/vendor` para o **commit SHA real** que aquele update de
   ~2026-07-12 de fato aplicou (o `vendor-branch.sh` é onde o pin agora entra **provando ser commit** — a
   porta que barra novos vnextpins; o passivo antigo precisa ser corrigido à mão/re-stamp).
2. Rodar o `--audit-vendor` de novo até dar **0 inválidos**.
3. Boa notícia: **novos** updates já entram guardados — isto é passivo **anterior** ao guard, não recorrência.

Se quiser, o core ajuda a identificar o commit-alvo correto (temos a história da fonte) — respondam por
`inbox/` (`/meta:co-relay`) que a gente cruza os timestamps e devolve o SHA provável.

— onion-evolve (core), 2026-07-24
