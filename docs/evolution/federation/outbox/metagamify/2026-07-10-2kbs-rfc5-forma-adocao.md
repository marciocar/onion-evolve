---
title: '2 KBs novas + RFC-0005 §4.1 (forma de adoção nomeada)'
date: 2026-07-10
from: onion-evolve (core / maestro principal)
to: metagamify (MetaGamify — consumidor)
re: CHANGELOG de co-evolução, entrada 2026-07-10 (downstream, conciliação de backlog)
type: downstream-announce
classe: COMPATÍVEL
status: a transportar (rascunho na staging do core)
---

# 📣 Anúncio do core — 2 KBs novas + RFC-0005 §4.1 (forma de adoção nomeada)

> Push core→derivado (downstream, doc-bridge), transportado pelo humano. Gerado de uma entrada do
> CHANGELOG do core por `/meta:co-announce` (conciliação de backlog `alvo: todos`). O adotante é
> cego ao core: só vê o que é commitado no PRÓPRIO `inbound/`.

## 2026-07-10 · 2 KBs novas + RFC-0005 §4.1 ("forma de adoção" nomeada) · COMPATÍVEL · alvo: todos

- **KB `frameworks/safe-multibranch-consolidation`**: o método de consolidação segura multi-branch
  (2 lanes código×conhecimento, migração-antes-do-código, salvage-antes-de-drop, build-green como
  prova, schema de veredito por branch validado pelo gate-keeper). Crédito: dogfood completo do
  **metagamify/rhilo-app** (~19 branches, verificado).
- **KB `patterns/literate-policy-as-data`**: a "config de três leitores" (parser lê dados, humano
  lê história, IA lê ordens) — o padrão do `members.yaml` batizado, com genealogia (Knuth→UNIX→
  ADRs→policy-as-data) e as 6 regras da casa. Copiem à vontade — é feito para isso.
- **RFC-0005 §4.1**: "**forma de adoção**" (`full | docs-only | in-place`) agora é dimensão de 1ª
  classe, ortogonal a escopo E versão (ground-truth: adoção docs-only real na Grana.Ai). O
  capability-update p/ adotante docs-only/regulado está registrado como 4º modo de proveniência
  (GATED, a-desenhar) — se você pretende adotar docs-only, sinalize antes do 1º `--update`.
- Ação p/ adotantes: nenhuma — chega via `/meta:adopt --update`.

## Ação esperada no adotante
- Ler este anúncio (o hook "you have mail" já o sinala como 📥 inbound).
- Classe **COMPATÍVEL** — sem urgência. A mudança chega vendorizada via `/meta:adopt --update` no
  momento oportuno (ver a linha "Ação p/ adotantes" acima).
- Tratado → `git mv` deste arquivo para `inbound/_processed/` (lido/não-lido git-visível).

---
> **Transporte (maestro):** revise e copie este arquivo para o `inbound/` do adotante:
> `cp docs/evolution/federation/outbox/metagamify/2026-07-10-2kbs-rfc5-forma-adocao.md <repo-metagamify>/docs/evolution/inbound/`
> e commite **no repo do adotante** (a sessão do core não pusha repo alheio).
