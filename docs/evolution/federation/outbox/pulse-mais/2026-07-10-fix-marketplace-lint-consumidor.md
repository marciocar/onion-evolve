---
title: 'Fix pós-update: lint de marketplace não bloqueia mais o consumidor + stamp determinístico'
date: 2026-07-10
from: onion-evolve (core / maestro principal)
to: pulse-mais (Pulse Mais — consumidor)
re: CHANGELOG de co-evolução, entrada 2026-07-10 (downstream, conciliação de backlog)
type: downstream-announce
classe: COMPATÍVEL
status: a transportar (rascunho na staging do core)
---

# 📣 Anúncio do core — Fix pós-update: lint de marketplace não bloqueia mais o consumidor + stamp determinístico

> Push core→derivado (downstream, doc-bridge), transportado pelo humano. Gerado de uma entrada do
> CHANGELOG do core por `/meta:co-announce` (conciliação de backlog `alvo: todos`). O adotante é
> cego ao core: só vê o que é commitado no PRÓPRIO `inbound/`.

## 2026-07-10 · Fix importante pós-update: lint de marketplace não bloqueia mais o consumidor + stamp determinístico · COMPATÍVEL · alvo: todos

- **Se o seu lint ficou HARD-red após um `--update`** (12 violações "plugin ausente"/"não registrado
  no marketplace" + commits bloqueados pelo pre-commit): corrigido. Os checks de marketplace agora
  têm **guarda por papel** — `role: adopted` pula (consumidor não distribui plugins; marketplace é
  superfície do `source`). Crédito: sinal de campo da **granaai**, fix idêntico ao drift local dela
  (o `DRIFT-ONION` de vocês converge sozinho no próximo update). +selftest `adopted-role` fechando a
  cegueira "selftest roda como source".
- **`write-stamp.sh`**: a escrita do `.claude/.onion-version` virou helper determinístico — o
  `--update` agora **preserva `adopted_at`** (1ª adoção, semântica única) e escreve `updated_at`
  por código testado, não por prosa que sessão pode violar (aconteceu — sinal multi-lineage granaai).
  `adopted_at` perdido é restaurado do `members.yaml`; irrecuperável → omitido com aviso, nunca inventado.
- Ação p/ adotantes: `/meta:adopt --update` traz ambos. Quem aplicou fix local no lint: remover a
  marca de drift após o update.

## Ação esperada no adotante
- Ler este anúncio (o hook "you have mail" já o sinala como 📥 inbound).
- Classe **COMPATÍVEL** — sem urgência. A mudança chega vendorizada via `/meta:adopt --update` no
  momento oportuno (ver a linha "Ação p/ adotantes" acima).
- Tratado → `git mv` deste arquivo para `inbound/_processed/` (lido/não-lido git-visível).

---
> **Transporte (maestro):** revise e copie este arquivo para o `inbound/` do adotante:
> `cp docs/evolution/federation/outbox/pulse-mais/2026-07-10-fix-marketplace-lint-consumidor.md <repo-pulse-mais>/docs/evolution/inbound/`
> e commite **no repo do adotante** (a sessão do core não pusha repo alheio).
