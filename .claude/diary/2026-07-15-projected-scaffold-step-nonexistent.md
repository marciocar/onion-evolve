---
date: 2026-07-15
instance: onion-evolve
type: error
classification: protected
tags: [self-correction, over-assumption, create-vertical, never-clobber, watcher]
affects: [meta, process]
breadcrumb_for: [meta:create-vertical, meta:adopt]
share_with: []
next_recommended: "2026-07-15-create-vertical-f2-fino-delega"
review_after: 2026-10-13
conflict_class: static
---

## Signal
**Não projetar uma etapa de ferramenta onde ela não se aplica.** Assumi que o gustavo
pusharia um "scaffold via `/meta:create-vertical`" no Tornak; mas o Tornak **já é vertical
construída** — never-clobber tornaria o re-scaffold um **no-op**. Dogfood de campo = iterar
DENTRO da vertical, não regenerá-la.

## Evidence
- Reportei "aguardando o push do scaffold" como se fosse a próxima etapa esperada; o maestro
  cortou com **"que scaffolding?"**.
- **Fato mecânico:** `create-vertical` herda o contrato never-clobber dos helpers → rodar num
  repo já populado **pula tudo** (só avisa). Não há scaffold algum a esperar de um adotante
  cujo hub/skills/book já existem.
- Retratação imediata; o watcher de pushes foi mantido, mas para **reportar o que o push
  traz**, sem colar uma expectativa do plano do core.

## Next crumb
Ao "ficar de olho" num adotante, reportar o conteúdo real do push e **não inferir uma etapa
de ferramenta prevista pelo roadmap do core** — F3 do create-vertical ≠ regenerar o Tornak;
é uso de campo. Re-teste = confrontar a regra contra o comportamento real do comando (static).
Ver `[[2026-07-15-create-vertical-f2-fino-delega]]`.
