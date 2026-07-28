---
title: 'Veredito: "object-led discovery & fitting" vira playbook do catálogo (não skill/comando novo)'
date: 2026-07-01
from: onion-evolve (core / maestro principal)
to: rhilo-metagamify (MetaGamify — consumidor)
re: CHANGELOG de co-evolução, entrada 2026-07-01 (downstream)
type: downstream-announce
classe: COMPATÍVEL
status: a transportar (rascunho na staging do core)
---

# 📣 Anúncio do core — Veredito: object-led discovery & fitting

> Push core→derivado (downstream, doc-bridge), transportado pelo humano. Gerado de uma entrada do CHANGELOG
> do core por `/meta:co-announce`. O adotante é cego ao core: só vê o que é commitado no PRÓPRIO `inbound/`.

- **Sinal de campo do `rhilo-metagamify`:** propôs canonizar o ciclo "promover objeto existente a papel premium" (espelhar → descobrir → vestir → materializar → realimentar), motivado pelo DataTable premium do dashboard WRR construído imperativamente (pedidos sucessivos re-improvisados a cada rodada).
- **Veredito: ACEITO como doutrina, materializado como playbook** — não como ADR-skill isolada nem comando `/onion:promote` dedicado. Aplicando a régua P0-P3 (`onion-adr-toolbox-lifecycle`), o substrato já cobria quase tudo (Capability Contract + SDAAL + catálogo-first do RFC-0002) — a síntese que faltava virou a **6ª entrada de playbook** em `onion-patterns/SKILL.md` §Playbooks ("promover objeto existente a papel premium").
- **Dogfood guiado retroativo** sobre a própria evidência anexada ao sinal (sem tocar o rhilo-app de novo): o gap real estava em **descobrir+vestir não anteciparem o perfil completo** do papel-alvo (emergiu por ~10 pedidos sucessivos em vez de 1 fitting único) — não em "materializar", que já era dirigido e verificado. Doc: `onion-adr-object-led-discovery-2026-07.md` (PR #213, `d24f03a`).
- **Ação p/ adotantes: nenhuma obrigatória.** O playbook vive no core; chega vendorizado via `/meta:adopt --update` (dentro de `onion-patterns/SKILL.md`). Quem quiser aplicar o ciclo já pode usá-lo por analogia — é disciplina em prosa, não automação.

## Ação esperada no adotante
- Ler este anúncio (o hook "you have mail" já o sinala como 📥 inbound).
- Não é BREAKING nem pede update imediato — rodar `/meta:adopt --update` quando oportuno para vendorizar o playbook.
- Se quiser, aplicar o playbook por analogia à próxima "promoção" de objeto (forms, dashboards, integrações).
- Tratado → `git mv` deste arquivo para `inbound/_processed/` (lido/não-lido git-visível).

---
> **Transporte (maestro):** revise e copie este arquivo para o `inbound/` do adotante:
> `cp docs/evolution/federation/outbox/rhilo-metagamify/2026-07-01-object-led-discovery-playbook.md /home/marciocar/rhilo-metagamify/docs/evolution/inbound/`
> e commite **no repo do adotante** (a sessão do core não pusha repo alheio).
