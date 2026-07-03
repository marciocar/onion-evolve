---
date: 2026-07-03
instance: onion-evolve
type: innovation
classification: public
tags: [doctrine, verification, pin-integrity, session-beacon, read-path]
affects: [meta, federation, engineering]
breadcrumb_for: [meta:adopt, meta:co-evolve, onion-orchestration]
share_with: [collective]
next_recommended: "2026-07-02-forged-pin-false-announcement"
review_after: 2026-10-01
conflict_class: static
---

## Signal
Três incidentes independentes de 2026-07-02 são O MESMO erro em três roupas: **estado declarado ≠
fato verificado**. Pin de stamp (declarado) ≠ artefato vendorizado (fato); `git status` limpo
(declarado) ≠ working tree livre (fato — sessões vivas); tabela de nome óbvio (declarado) ≠
read-path real (fato). Ao encontrar um QUARTO caso da família, não trate como incidente novo —
aplique o padrão: identificar a declaração confiada às cegas, achar o artefato que a verifica,
criar guarda determinística.

## Evidence
- Membro 1: pin forjado → `pin-integrity-check.sh` (canário byte-a-byte) — PR #222.
- Membro 2: colisão W1×W2 → farol de sessão 🕯️ — PR #224.
- Membro 3: split-brain de tabelas (sinal do rhilo) → verify-read-path-first — PR #225.
- Os 3 nasceram em <24h de fontes distintas (core errou, core colidiu, adotante quase errou) e
  convergiram sem coordenação — evidência de que é padrão estrutural, não coincidência.
- Registro consolidado: tabela da família em
  `docs/knowledge-base/agentic-patterns/ai-strategies/verify-read-path-first.md`.

## Next crumb
Candidatos a 4º membro para vigiar: contagens de inventário (declarado no doc vs filesystem — já
guardado pelo lint), `members.yaml.personality_summary` (declarado vs comportamento real — F2),
CHANGELOG "entregue" vs inbound real do adotante. Ao guardar um novo membro, atualizar a tabela
da família na KB.
