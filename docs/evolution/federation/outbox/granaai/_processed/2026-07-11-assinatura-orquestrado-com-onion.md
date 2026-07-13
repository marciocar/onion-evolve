---
title: 'Assinatura da família revisada: 🧅 "Orquestrado com Onion"'
date: 2026-07-11
from: onion-evolve (core / maestro principal)
to: granaai (Grana.Ai — consumidor)
re: CHANGELOG de co-evolução, entrada 2026-07-11 (downstream)
type: downstream-announce
classe: COMPATÍVEL
status: a transportar (rascunho na staging do core)
---

# 📣 Anúncio do core — Assinatura da família revisada: 🧅 "Orquestrado com Onion"

> Push core→derivado (downstream, doc-bridge), transportado pelo humano. Gerado de uma entrada do CHANGELOG
> do core por `/meta:co-announce`. O adotante é cego ao core: só vê o que é commitado no PRÓPRIO `inbound/`.

## 2026-07-11 · Assinatura da família revisada: 🧅 "Orquestrado com Onion" · COMPATÍVEL · alvo: todos

- **Nova superfície** (decisão do maestro, 2026-07-11): a assinatura da família nos PRs passa a ser
  `🧅 Orquestrado com [Onion](https://onionevolve.com)` — dropa o "Gerado por [Claude Code] usando". A autoria
  da superfície é do **Onion**; a ferramenta subjacente fica implícita.
- **Substitui** a assinatura de 2026-07-10 (entrada abaixo — mantida por auditoria). Onde vive: `/engineer:pr`
  v3.4.0 (chega via `/meta:adopt --update`). Aplique também em PRs manuais do fluxo Onion.

## Ação esperada no adotante
- Ler este anúncio (o hook "you have mail" já o sinala como 📥 inbound).
- Classe **COMPATÍVEL** — sem urgência. A nova assinatura chega no `/engineer:pr` v3.4.0 quando rodar
  `/meta:adopt --update` no momento oportuno. Até lá, em PRs manuais do fluxo Onion, aplique
  `🧅 Orquestrado com [Onion](https://onionevolve.com)`.
- Tratado → `git mv` deste arquivo para `inbound/_processed/` (lido/não-lido git-visível).

---
> **Transporte (maestro):** revise e copie este arquivo para o `inbound/` do adotante:
> `cp docs/evolution/federation/outbox/granaai/2026-07-11-assinatura-orquestrado-com-onion.md <repo-granaai>/docs/evolution/inbound/`
> e commite **no repo do adotante** (a sessão do core não pusha repo alheio).
