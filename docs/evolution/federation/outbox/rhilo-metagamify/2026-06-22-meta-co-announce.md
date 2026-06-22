---
title: '/meta:co-announce — anúncio flow A vira passo de ritual (não mais memória humana)'
date: 2026-06-22
from: onion-evolve (core / "mestre")
to: rhilo-metagamify (rhilo-metagamify (MetaGamify) — consumidor)
re: CHANGELOG de co-evolução, entrada 2026-06-22 (flow A)
type: flow-a-announce
classe: COMPATÍVEL
status: a transportar (rascunho na staging do core)
---

# 📣 Anúncio do core — `/meta:co-announce` torna o anúncio flow A um passo de ritual

> Push core→derivado (flow A, doc-bridge), transportado pelo humano. Gerado de uma entrada do CHANGELOG
> do core por `/meta:co-announce`. O adotante é cego ao core: só vê o que é commitado no PRÓPRIO `inbound/`.

- **Novo comando produtor do doc-bridge leve.** `/meta:co-announce [<data|slug>]` transforma uma entrada do CHANGELOG do core num anúncio pronto-para-transportar no seu `inbound/`, resolvendo o(s) destinatário(s) do campo `alvo:` via `members.yaml` e escrevendo na staging do core `federation/outbox/<id>/`. Fecha o **gap de processo** do backlog #6 (a capacidade de flow A existia, mas o anúncio nunca era *exercido* ao shipar — dependia de o humano lembrar).
- **Fronteira:** é o **core-empurra** (anuncia sem esperar você rodar `--update`), distinto do relatório auto-emitido de `/meta:adopt --update` (adotante-puxa) e de `/meta:federation-publish` (ledger de contratos, federação formal). Human-in-the-loop preservado: o core gera e endereça; o **maestro** transporta.
- **Ritual documentado:** `CONTRIBUTING.md` ganhou o passo pós-merge "anuncie mudança relevante a adotantes".

## Ação esperada no adotante
- Ler este anúncio (o hook "you have mail" já o sinala como 📥 inbound).
- Sem ação obrigatória — é COMPATÍVEL e informativo. O comando é infra do core; chega a você no próximo `/meta:adopt --update`.
- Tratado → `git mv` deste arquivo para `inbound/_processed/` (lido/não-lido git-visível).

---
> **Transporte (maestro):** revise e copie este arquivo para o `inbound/` do adotante:
> `cp docs/evolution/federation/outbox/rhilo-metagamify/2026-06-22-meta-co-announce.md /home/marciocar/rhilo-metagamify/docs/evolution/inbound/`
> e commite **no repo do adotante** (a sessão do core não pusha repo alheio).
