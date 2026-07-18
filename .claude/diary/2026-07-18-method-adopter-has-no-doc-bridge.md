---
date: 2026-07-18
instance: onion-evolve
type: learning
classification: public
tags: [method-adopter, sovereignty, doc-bridge, devolucao, co-announce, g1]
affects: [co-evolution]
breadcrumb_for: []
share_with: []
next_recommended: ""
review_after: 2026-10-15
conflict_class: static
---

## Signal
Um **method-adopter** — que adota o **MÉTODO** do Onion (KG SDAAL) e **não vendoriza** `.claude/` (onion-pessoal: a raiz É o KG de vida) — **não tem canal `inbound/`**. A devolução downstream a ele **não é um arquivo**: a doutrina chega **via o método** que ele adota (quando ele roda `/meta:orchestrate`/`/meta:kg`, segue a doutrina atualizada) + via o maestro. **Não force-criar `inbound/`** num method-adopter — isso impõe a estrutura vendorizada e fere a soberania (o gap G1: adoção de domínio não-software).

## Evidence
- onion-pessoal não tem `docs/evolution/` (sem doc-bridge); a raiz tem `marcio-{trabalho,saude,relacoes,aprendizado}-f0.kg.yaml`.
- `members.yaml:185` (`id: marcio-pessoal`): "adota o MÉTODO (KG SDAAL), NÃO vendoriza `.claude/`"; `onion_version: n/a`; `--profile` de domínio é F2 (gap G1).
- Na devolução 2026-07-18: `cp` do anúncio p/ o `inbound/` do onion-pessoal falhou (`No such file or directory`) — **correto, não bug**. granaai (file-adopter, tem `inbound/`) recebeu normal.

## Next crumb
Antes de transportar um anúncio downstream, cheque o **modo de adoção** do alvo (`members.yaml`): **file-adopter** (vendoriza) → `cp` p/ `docs/evolution/inbound/` (entrega-sem-commit); **method-adopter** (adota o método, `onion_version: n/a`) → **não há arquivo a entregar** — a doutrina o alcança via o método + o maestro. O `resolve-target` de `alvo: todos` inclui method-adopters; o **transporte** é que difere por modo.
