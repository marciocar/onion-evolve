---
title: 'BREAKING: skill onion-fleet→onion-orchestration + /meta:fleet→/meta:orchestrate (migração de vocabulário)'
date: 2026-06-28
from: onion-evolve (core / maestro principal)
to: rhilo-metagamify (rhilo-metagamify (MetaGamify) — consumidor)
re: CHANGELOG de co-evolução, entrada 2026-06-28 (downstream)
type: downstream-announce
classe: BREAKING
status: a transportar (rascunho na staging do core)
---

# 📣 Anúncio do core — BREAKING: migração de vocabulário de orquestração

> Push core→derivado (downstream, doc-bridge), transportado pelo humano. Gerado de uma entrada do CHANGELOG
> do core por `/meta:co-announce`. O adotante é cego ao core: só vê o que é commitado no PRÓPRIO `inbound/`.

- **Migração de vocabulário no core:** os apelidos `frota` (PT) / `fleet` (EN) foram **aposentados** em favor do vocabulário canônico da indústria — `orquestração` (conceito) / `orchestrator-worker` (padrão) / `workers` (coletivo executor). Fundamentada por pesquisa (3 ângulos + web jul-2026): o canônico é *orchestrator-worker / fan-out-fan-in*; "fleet" é jargão em transição e "frota" era o único termo técnico traduzido.
- **O que mudou (afeta você):**
  - **Skill:** `onion-fleet` → **`onion-orchestration`** (mesma capacidade).
  - **Comando:** `/meta:fleet` → **`/meta:orchestrate`**.
  - **KB:** `agent-fleet-orchestration.md` → `agent-orchestration.md` (+ 4 ADRs `onion-fleet-*` → `onion-orchestration-*`).
  - **Anti-pattern:** `fleet-orchestrator` → `worker-orchestrator` (guarda §4.2 / Regra 7 do lint).
  - **Vocabulário:** prosa migrada para `orquestração`/`workers` no core inteiro (308 reescritas).
- **Validação:** lint 0/0, selftest 100/0, revisão independente (corrigiu substituição semântica em L0), grep-zero limpo. PR #205 MERGED.

## Ação esperada no adotante
- Ler este anúncio (o hook "you have mail" já o sinala como 📥 inbound).
- **Classe BREAKING (rename de invocáveis):** seu repo tem `onion-fleet` vendorizado.
  1. Rodar `/meta:adopt --update` quando oportuno — o delta aplica a skill/comando renomeados.
  2. Atualizar refs próprias (docs/sessões) que citem `/meta:fleet` ou `onion-fleet` → `/meta:orchestrate` / `onion-orchestration`.
  3. O anti-pattern proibido passou a ser `worker-orchestrator` (refletido no lint vendorizado).
  - Sem pressa — o `--update` é idempotente; coordene quando for atualizar o framework.
- Tratado → `git mv` deste arquivo para `inbound/_processed/` (lido/não-lido git-visível).

---
> **Transporte (maestro):** revise e copie este arquivo para o `inbound/` do adotante:
> `cp docs/evolution/federation/outbox/rhilo-metagamify/2026-06-28-orchestration-rename.md /home/marciocar/rhilo-metagamify/docs/evolution/inbound/`
> e commite **no repo do adotante** (a sessão do core não pusha repo alheio).
