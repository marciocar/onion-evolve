---
title: 'KG-SSOT ganha guardas de FRESCOR + SCHEMA e a doutrina SSOT-as-runtime (crédito: seus sinais)'
date: 2026-07-16
from: onion-evolve (core / maestro principal)
to: metagamify (MetaGamify — consumidor, radar soberano próprio)
re: CHANGELOG de co-evolução, entrada 2026-07-16 (downstream)
type: downstream-announce
classe: COMPATÍVEL
status: a transportar (rascunho na staging do core)
---

# 📣 Anúncio do core — KG-SSOT: frescor + schema + SSOT-as-runtime

> Push core→derivado (downstream, doc-bridge), transportado pelo humano. Gerado de uma entrada do CHANGELOG
> do core por `/meta:co-announce`. O adotante é cego ao core: só vê o que é commitado no PRÓPRIO `inbound/`.

**Isto fecha o loop dos seus dois sinais de campo desta rodada** — o "ouro" do dogfood WRR/Modo Equilíbrio
e o companheiro `ssot-como-runtime-para-adr`. Vocês nomearam a lição-mestra; o core a virou guarda.

## O que o core shippou (a partir do que vocês relataram)

- **`kg-radar.sh --freshness`** (⚠ aviso): `verified_at:` carimba *quando* um nó foi cruzado com o vivo.
  **STALE-MISSING** (nó rastreado sem carimbo) · **STALE-OLD** (`verified_at` < `meta.baseline`). Rastreado =
  `plane:PROD` **OU** nó com `verified_against:` — isto cobre nós **DEV** que apontam para branch/commit
  (o seu `C_CONSOLIDATION_MAP` stale foi o caso que **refutou** o meu "só PROD" inicial; a decisão foi
  reconciliada com `SUPERSEDES`, não apagada). Determinístico: compara duas datas do arquivo, sem "agora".
- **`kg-radar.sh --schema`** (✗ recusa): `schema_version:` no `meta:`; divergência = recusa. Pega o fork
  `scripts/kg`↔radar-canônico que vocês viveram, no dia 1.
- **Doutrina SSOT-as-runtime** (KB): a SSOT é o programa que se **executa** (`read→verify→act→write`;
  KG-first + drive-to-verify). Nomeada do seu relato "montei o SSOT e o ignorei 3×".

## O que isso significa PARA VOCÊS (radar soberano)

Vocês têm **motor próprio** (`radar.js`) — a soberania é intencional (viaja schema+método, não o código). A
ação é **espelhar as 3 checagens** no seu radar: (1) `verified_at`/STALE, (2) `verified_against` estendendo a
DEV, (3) `schema_version`/drift. O design de referência está no ADR `onion-adr-kg-freshness-gate-2026-07`.
Nada obrigatório — é aviso, não gate-duro.

## Ação esperada no adotante
- Ler este anúncio (o hook "you have mail" já o sinala como 📥 inbound).
- Espelhar as guardas no radar soberano quando fizer sentido (design no ADR citado).
- Tratado → `git mv` deste arquivo para `inbound/_processed/`.

---
> **Transporte (maestro):** revise e copie para o `inbound/` do adotante:
> `cp docs/evolution/federation/outbox/metagamify/2026-07-16-kg-ssot-freshness-schema-runtime.md /home/marcio/rhilo-metagamify/docs/evolution/inbound/`
> e commite **no repo do adotante** (a sessão do core não pusha repo alheio).
