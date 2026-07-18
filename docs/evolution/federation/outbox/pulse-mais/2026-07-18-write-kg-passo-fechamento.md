---
title: 'write(KG) virou passo de fechamento da orquestração — pesquisa persiste no KG-SSOT'
date: 2026-07-18
from: onion-evolve (core / maestro principal)
to: pulse-mais (Pulse Mais — consumidor)
re: CHANGELOG de co-evolução, entrada 2026-07-18 (downstream)
type: downstream-announce
classe: COMPATÍVEL
status: a transportar (rascunho na staging do core)
---

# 📣 Anúncio do core — write(KG) virou passo de fechamento da orquestração — pesquisa persiste no KG-SSOT

> Push core→derivado (downstream, doc-bridge), transportado pelo humano. Gerado de uma entrada do
> CHANGELOG do core por `/meta:co-announce`. O adotante é cego ao core: só vê o commitado no PRÓPRIO `inbound/`.

## 2026-07-18 · `write(KG)` virou passo de fechamento da orquestração — pesquisa persiste no KG-SSOT, não no efêmero · COMPATÍVEL · alvo: todos

- **Bookend simétrico do read(KG).** Toda orquestração que **produz conhecimento** (pesquisa, auditoria,
  investigação, design) fecha com **`write(KG)`**: persiste a síntese no repo (`docs/**/research/*.md`) **e**
  materializa o `.kg.yaml` via `/meta:kg` + `kg-radar` (exit 0) — nunca deixa no `/tmp` efêmero do harness.
  Vive na skill `onion-orchestration` (passo 7) + `/meta:orchestrate` (Passo 4.5). **Mecanismo, não conselho.**
- **Ação p/ adotantes:** chega via `/meta:adopt --update`. A skill `deep-research` do harness não persiste —
  a orquestração Onion é dona desse leg agora. Origem: **sinal de campo do onion-pessoal** (2026-07-18).


## Ação esperada no adotante
- Ler este anúncio (o hook "you have mail" já o sinala como 📥 inbound).
- Classe **COMPATÍVEL** — a mudança chega vendorizada via `/meta:adopt --update` no momento oportuno.
- Tratado → `git mv` deste arquivo para `inbound/_processed/` (lido/não-lido git-visível).

---
> **Transporte (maestro):** `cp docs/evolution/federation/outbox/pulse-mais/2026-07-18-write-kg-passo-fechamento.md <repo-pulse-mais>/docs/evolution/inbound/` e commite **no repo do adotante**.
