---
title: 'Veredito: branching = base resolvida (agnóstica), não trunk-default — e onde vive o canal'
date: 2026-06-24
from: onion-evolve (core / "mestre")
to: rhilo-metagamify (rhilo-metagamify (MetaGamify) — consumidor)
re: CHANGELOG de co-evolução, entrada 2026-06-24 (downstream)
type: downstream-announce
classe: COMPATÍVEL
status: a transportar (rascunho na staging do core)
---

# 📣 Anúncio do core — branching: base resolvida (agnóstica), não trunk-default

> Push core→derivado (downstream, doc-bridge), transportado pelo humano. Gerado de uma entrada do CHANGELOG
> do core por `/meta:co-announce`. O adotante é cego ao core: só vê o que é commitado no PRÓPRIO `inbound/`.

Seu sinal de 2026-06-24 (branching GitFlow/`develop` vs trunk-based + onde vive o canal) foi recebido e
triado. Veredito abaixo — fiz a diligência adversarial sobre suas 3 alegações antes de decidir.

## Diligência (o que confirmei e o que corrigi)

1. **git:* embute `develop`** — ✅ verdade (`sync` default develop, `init` cria develop, `flow`
   feature→develop / release de develop).
2. **Já há resolução de base** — ✅ verdade, **mas só metade**: o `resolve-integration-branch.sh` existe e o
   `/engineer:pr` já resolve a base (`.onion-version` → `git config` → detect, #104). **Não propagou** aos git:*.
3. **"/meta:co-evolve mandou commitar em develop"** — ❌ **falso (correção)**: o co-evolve é **agnóstico a
   branch** — não menciona branch nenhuma. O canal vive **onde o `docs/evolution/` foi commitado**; quem o
   pôs em develop foi a adoção, não o comando. (Importa pro fix: não é "mudar o co-evolve", é "mover o canal".)

## Veredito às 3 perguntas

**(Q1) Migrar o default p/ trunk-based? → NÃO. A base vira DADO RESOLVIDO (agnóstico).** Trocar o default
GitFlow→trunk-based só **troca uma imposição por outra** — vetado pelo ADR **"Onion adota, não impõe"**
(mergeado no core hoje). Decisão: a base de integração é **resolvida** pela cadeia que o `/engineer:pr` já
usa; GitFlow continua **uma** topologia; trunk-based = setar a integration branch = sua trunk. Seu sinal é
**evidência de campo** que estende esse ADR de design para branching. Registrado no core como
[ADR onion-adr-branching-base-agnostic] (provisório).

**(Q2) Onde vive o canal num adotante trunk-based? → na integration/deploy trunk resolvida**, não preso em
`develop`. O `docs/evolution/` (e os comandos vendorizados) devem morar na linha que você integra/deploya.
O mesmo encalhe explica o *"Unknown command: /meta:co-evolve"* fora de develop — comandos vendorizados
encalhados lá.

**(Q3) Blip? → novo, no SEU radar** (modelo-de-branching, quadrante MET). No core não é ADR novo — é
instância do "adota não impõe" + um follow-up de costura.

## Ação esperada no adotante

**Você pode resolver localmente JÁ — não espere o framework:**
- Setar `integration_branch: rhilo/main` no `.claude/.onion-version` → o `/engineer:pr` **já respeita**
  (resolve a base de lá), sem esperar a costura dos demais git:*.
- Mover `docs/evolution/` + radar para a trunk que deploya (`rhilo/main`), colapsando o "metade em cada
  lado". O `co-evolution-inbox-check.sh` dispara onde os arquivos estiverem.
- Abrir o **blip novo** (modelo-de-branching) no seu radar.
- Os `git:*` (sync/flow/init) com base resolvida chegam no **follow-up do core** (costura diferida ao
  gatilho — anunciada por downstream quando graduar).
- Tratado → `git mv` deste arquivo para `inbound/_processed/`.

---
> **Transporte (maestro):** revise e copie este arquivo para o `inbound/` do adotante:
> `cp docs/evolution/federation/outbox/rhilo-metagamify/2026-06-24-veredito-branching-base-agnostica.md /home/marciocar/rhilo-metagamify/docs/evolution/inbound/`
> e commite **no repo do adotante** (a sessão do core não pusha repo alheio). Ou use `/meta:co-deliver`.
