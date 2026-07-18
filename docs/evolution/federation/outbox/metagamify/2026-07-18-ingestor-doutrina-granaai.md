---
title: 'O core absorve doutrina de campo do granaai (1º ingestor de doutrina)'
date: 2026-07-18
from: onion-evolve (core / maestro principal)
to: metagamify (MetaGamify — consumidor)
re: CHANGELOG de co-evolução, entrada 2026-07-18 (downstream)
type: downstream-announce
classe: COMPATÍVEL
status: a transportar (rascunho na staging do core)
---

# 📣 Anúncio do core — O core absorve doutrina de campo do granaai (1º ingestor de doutrina)

> Push core→derivado (downstream, doc-bridge), transportado pelo humano. Gerado de uma entrada do
> CHANGELOG do core por `/meta:co-announce`. O adotante é cego ao core: só vê o commitado no PRÓPRIO `inbound/`.

## 2026-07-18 · O core absorve doutrina de campo do granaai: integridade≠rastreabilidade + soberania do validador (1º ingestor) · COMPATÍVEL · alvo: todos

- **Nasceu o ingestor de doutrina** (o elo que faltava na cadeia adotante→core): o core passa a
  **absorver doutrina de campo** por absorção **curada, trust-gated** (só de quem tem `can_correct_to`),
  **KG-backed** (grafo audit, `kg-radar` exit 0) e **human-gated** — o precursor curado da síntese
  coletiva (RFC-0003 F4, gated). ADR: `onion-adr-doctrine-ingestor-2026-07`.
- **1º dogfood — granaai (2 doutrinas absorvidas no KB `knowledge-graph-sdaal.md`):**
  - **integridade técnica ≠ completude de rastreabilidade** — um `.kg.yaml` sela verde na integridade e
    mesmo assim tem `TRACES_TO` órfão; a família *declarado≠verificado* estendida à rastreabilidade.
  - **soberania do validador** — um validador local **delega** ao `kg-radar` soberano, não reimplementa
    a gramática (parser duplicado divergente = a superfície onde o falso-verde volta).
- **S3b** (`--update` regenera `inventory.md`) e **S4** (`/meta:kg map <projeto>`) → backlog de engenharia;
  **S2** (fail-open) já estava absorvido. Grafo da absorção: `granaai-doctrine-absorption-2026-07.kg.yaml`.
- **Ação p/ adotantes:** nenhuma — a doutrina chega vendorizada no próximo `/meta:adopt --update` (KB
  atualizado). Crédito: dogfood de campo do **granaai** (2026-07-17).


## Ação esperada no adotante
- Ler este anúncio (o hook "you have mail" já o sinala como 📥 inbound).
- Classe **COMPATÍVEL** — a mudança chega vendorizada via `/meta:adopt --update` no momento oportuno.
- Tratado → `git mv` deste arquivo para `inbound/_processed/` (lido/não-lido git-visível).

---
> **Transporte (maestro):** `cp docs/evolution/federation/outbox/metagamify/2026-07-18-ingestor-doutrina-granaai.md <repo-metagamify>/docs/evolution/inbound/` e commite **no repo do adotante**.
