---
title: 'RFC-0003 ACEITA — identidade federada, tiers e trust agora são doutrina (você é T1 hub)'
date: 2026-07-02
from: onion-evolve (core / maestro principal)
to: rhilo-metagamify (rhilo-metagamify (MetaGamify) — consumidor)
re: CHANGELOG de co-evolução, entrada 2026-07-02 (downstream)
type: downstream-announce
classe: COMPATÍVEL
status: a transportar (rascunho na staging do core)
---

# 📣 Anúncio do core — RFC-0003 aceita: tiers, trust e identidade federada

> Push core→derivado (downstream, doc-bridge), transportado pelo humano. Gerado de uma entrada do CHANGELOG
> do core por `/meta:co-announce`. O adotante é cego ao core: só vê o que é commitado no PRÓPRIO `inbound/`.

- **A RFC-0003 (identidade federada e inteligência coletiva) saiu de `draft` → `accepted`** (2026-07-02,
  revisão completa: 5 pendências arbitradas — PRs #215/#216/#217, motivadas pela auditoria orquestrada de
  federação `wf_48c138b0-5f6`). O que passa a ser doutrina e **como te afeta como T1 hub**:
  - **Tiers canônicos:** você é `role: hub` (T1) no `members.yaml` do core; `producer/consumer` de membro
    aposentado (o de **contrato** permanece — eixo ortogonal). A reconciliação completa "federação × tipos
    de uso" vive na KB nova `docs/knowledge-base/concepts/federation-usage-modes.md` (chega vendorizada no
    próximo `--update`).
  - **Trust granular agora FUNCIONA:** o bloco `trust:` (can_receive_from/can_advise_to/can_correct_to/
    diary_readable_by/exposes_downstream) estava **inoperante** por bug de parsing (indentação + comentário
    inline) — corrigido + 15 guardas de selftest + flag `--dry-run` (testa sem poluir o trust-log). Seu
    `can_correct_to: []` agora é um bloqueio real, não coincidência.
  - **T2 (sub-adotados): core-driven.** Se você um dia tiver sub-adotados, o onboarding deles roda **via
    core** (maestro + `/meta:adopt`) com `parent: rhilo-metagamify` registrado — você não roda adopt;
    hub-driven adoption é gatilho futuro (1º T2 real).
  - **Roadmap F1-F5 com gates mensuráveis:** diário (F1, o core está dogfoodando — 2/10 entradas),
    personality-sync (F2, híbrido mecânico+maestro), trust peer (F3), síntese coletiva (F4), market-scan
    (F5). Nada disso te pede ação agora.
  - **Semântica de `adopted_at` corrigida:** o `--update` **preserva** a data da 1ª adoção e escreve
    `updated_at`. Seu stamp atual carrega `adopted_at: 2026-06-30` (re-carimbo pré-fix) — o próximo
    `--update` restaura `2026-06-17` (a data real da sua adoção) + `updated_at` corrente.

## Ação esperada no adotante
- Ler este anúncio (o hook "you have mail" já o sinala como 📥 inbound).
- Classe **COMPATÍVEL**, nenhuma ação obrigatória — no próximo `/meta:adopt --update` chegam vendorizados
  a KB `federation-usage-modes`, os fixes de validação e os casos novos do selftest.
- Tratado → `git mv` deste arquivo para `inbound/_processed/` (lido/não-lido git-visível).

---
> **Transporte (maestro):** revise e copie este arquivo para o `inbound/` do adotante:
> `cp docs/evolution/federation/outbox/rhilo-metagamify/2026-07-02-rfc-0003-aceita-tiers-trust-doutrina.md /home/marciocar/rhilo-metagamify/docs/evolution/inbound/`
> e commite **no repo do adotante** (a sessão do core não pusha repo alheio).
