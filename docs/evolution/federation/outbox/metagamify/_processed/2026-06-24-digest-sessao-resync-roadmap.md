---
title: 'Digest de sessão — re-sync recomendado (catálogo #9) + roadmap dos 2 follow-ups gated'
date: 2026-06-24
from: onion-evolve (core / "mestre")
to: rhilo-metagamify (rhilo-metagamify (MetaGamify) — consumidor)
re: CHANGELOG de co-evolução, entrada 2026-06-24 (downstream)
type: downstream-announce
classe: COMPATÍVEL
status: a transportar (rascunho na staging do core)
---

# 📣 Digest de sessão — net pra você (sync + roadmap)

> Push core→derivado (downstream). **Complementa** os anúncios individuais de hoje (branching,
> laço-sem-guarda, #9) — não re-anuncia, **consolida**.

## 1. Re-sync recomendado (delta pequeno)

Você sincronizou para **`025225e`**. O **catálogo #9** (5 playbooks recognition-primed) entrou **depois**,
em **`0dcdc47`** (PR #164). Um novo `/meta:adopt --update` — **já na trunk `rhilo/main`** que você setou —
traz os playbooks vendorizados em `onion-patterns`. **Delta:** 1 arquivo (`SKILL.md`). Sem urgência.

## 2. Roadmap dos 2 follow-ups GATED (decididos, costura diferida)

Nada que você precise fazer agora — são decisões tomadas cuja **implementação espera o gatilho**:

1. **`git:*` com base resolvida** — `onion-adr-branching-base-agnostic`. sync/flow/init deixarão de
   hardcodar `develop`; resolverão a integration branch (como o `/engineer:pr` já faz). **O gatilho é o
   SEU caso** (migrar p/ trunk única). Quando graduar, anuncio por downstream e você ganha os `git:*`
   coerentes com `rhilo/main` — fim do "metade em cada lado".

2. **Adoção-de-design defere ao padrão do projeto** — `onion-adr-adopt-to-not-impose`. Se um dia o
   `/design:identity` rodar num projeto seu com design próprio (shadcn/Tailwind etc.), ele **detecta e
   defere/estende** (never-clobber), não impõe o `design-context/` nativo.

## Ação esperada no adotante

- Rodar `/meta:adopt --update` quando oportuno (traz o catálogo #9).
- Mover o blip #9 → `done` (se ainda não moveu — ver o anúncio anterior `2026-06-24-anuncio-9-materializado`).
- Os 2 follow-ups chegam por downstream quando graduarem. **Sem ação obrigatória.**
- Tratado → `git mv` deste arquivo para `inbound/_processed/`.

---
> **Transporte (maestro):** `cp docs/evolution/federation/outbox/rhilo-metagamify/2026-06-24-digest-sessao-resync-roadmap.md /home/marciocar/rhilo-metagamify/docs/evolution/inbound/` e commite no repo do adotante. Ou `/meta:co-deliver`.
