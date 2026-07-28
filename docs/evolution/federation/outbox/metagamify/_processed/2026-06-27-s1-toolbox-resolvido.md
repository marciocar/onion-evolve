---
title: 'S1 RESOLVIDO: padrão "toolbox" = régua P0-P3 + coesão dos create-*'
date: 2026-06-27
from: onion-evolve (core / maestro principal)
to: rhilo-metagamify (rhilo-metagamify (MetaGamify) — consumidor)
re: CHANGELOG de co-evolução, entrada 2026-06-27 (downstream)
type: downstream-announce
classe: COMPATÍVEL
status: a transportar (rascunho na staging do core)
---

# 📣 Anúncio do core — S1 RESOLVIDO: padrão "toolbox" (régua P0-P3 + coesão dos create-*)

> Push core→derivado (downstream, doc-bridge), transportado pelo humano. Gerado de uma entrada do CHANGELOG
> do core por `/meta:co-announce`. O adotante é cego ao core: só vê o que é commitado no PRÓPRIO `inbound/`.

- **Seu sinal S1 (padrão "toolbox") saiu de "triado" para RESOLVIDO** ([inbox 2026-06-24](../../../../inbox/_processed/2026-06-24-sinal-padrao-toolbox.md)). O pedido — um **meio de 1ª classe para classificar procedimentos recorrentes** (script/skill/comando) e gerir seu ciclo de vida — foi escopado, trialado e selado num ciclo completo (ASSESS #181 → TRIAL #183/#184/#185 → ADOPT #186).
- **Veredito do scoping (ASSESS, PR #181):** o "toolbox" **NÃO é infra nova**. É uma **régua de classificação P0-P3 + coesão dos `/meta:create-*`** assentada sobre o substrato que já existe (`inventory.sh` + lint + `context-freshness`). Construir registry/dedup/embedding seria inchaço sem dogfood.
- **O que entrou (vendorizado no próximo `--update`):**
  1. **Régua P0-P3 de classificação** no `onion/SKILL.md` (#184) — o classificador que você pediu: como decidir se um procedimento recorrente vira script (P0, determinístico/controle), comando (P1, juízo/quando), skill (P2, recall) ou ADR (P3, doutrina).
  2. **Passo `inventory-sync` nos `/meta:create-*`** (#183, fragmento `common:prompts:inventory-sync-after-create`) — fecha um **HARD-fail silencioso** que você poderia pegar: criar command/agent/skill/KB sem regenerar a SSOT deixava o repo em falha da **Regra 8** até o CI pegar no PR. Agora "criar" carrega "sincronizar" (mesmo espírito do entrega-sem-commit).
  3. **Outliers de coesão** (#185): `create-task-structure` movido `/meta:`→`/product:` (é task de produto, não artefato Onion); `create-agent-express` ganhou path categorizado; cross-links dos `create-*` fechados (eram assimétricos).
  4. **Doutrina selada** (ADR `onion-adr-toolbox-lifecycle-2026-06`, #186).
- **Deferido conscientemente (gatilho = gate-de-uso, não esquecimento):** `kind/status` no frontmatter, dedup por embedding e registry externo só graduam **quando a régua P0-P3 acumular uso real**. Radar, não roadmap.
- **Conexão com o seu S2:** o `/meta:co-relay` (resolvido ontem) foi o **1º caso concreto** deste padrão e destilou o critério (*procedimento recorrente → script + comando + ADR + gate humano*); a régua P0-P3 agora é o **classificador genérico** desse critério.

## Ação esperada no adotante
- Ler este anúncio (o hook "you have mail" já o sinala como 📥 inbound).
- **Sem ação obrigatória.** No próximo `/meta:adopt --update`, a régua P0-P3 + os `create-*` coesos chegam vendorizados. Pode **mover o blip "toolbox" no seu radar → done**.
- Tratado → `git mv` deste arquivo para `inbound/_processed/` (lido/não-lido git-visível).

---
> **Transporte (maestro):** revise e copie este arquivo para o `inbound/` do adotante:
> `cp docs/evolution/federation/outbox/rhilo-metagamify/2026-06-27-s1-toolbox-resolvido.md /home/marciocar/rhilo-metagamify/docs/evolution/inbound/`
> e commite **no repo do adotante** (a sessão do core não pusha repo alheio). Ou, na mesma máquina,
> use `/meta:co-deliver rhilo-metagamify --target /home/marciocar/rhilo-metagamify`.
