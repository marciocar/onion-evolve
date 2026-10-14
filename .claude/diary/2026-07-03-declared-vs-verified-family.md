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
review_after: 2027-01-12
conflict_class: static
---

## Signal
Três incidentes independentes de 2026-07-02 são O MESMO erro em três roupas: **estado declarado ≠
fato verificado**. Pin de stamp (declarado) ≠ artefato vendorizado (fato); `git status` limpo
(declarado) ≠ working tree livre (fato — sessões vivas); tabela de nome óbvio (declarado) ≠
read-path real (fato). A família CRESCEU (7 membros na tabela da KB em 2026-10-14) e ganhou raiz
nomeada pelo maestro (*"a pior verdade é aquela que não temos certeza"*). Ao encontrar um caso novo, não
trate como incidente novo: identifique a declaração confiada às cegas, ache o artefato que a verifica e
crie a guarda determinística. Depois, atualize a tabela da KB.

## Evidence
- Membro 1: pin forjado → `pin-integrity-check.sh` (canário byte-a-byte) — PR #222.
- Membro 2: colisão W1×W2 → farol de sessão 🕯️ — PR #224.
- Membro 3: split-brain de tabelas (sinal do rhilo) → verify-read-path-first — PR #225.
- Os 3 nasceram em <24h de fontes distintas (core errou, core colidiu, adotante quase errou) e
  convergiram sem coordenação — evidência de que é padrão estrutural, não coincidência.
- Registro consolidado: tabela da família em
  `docs/knowledge-base/agentic-patterns/ai-strategies/verify-read-path-first.md`.
- **Estado em 2026-10-14 (re-teste):** a tabela da KB (§"Família doutrinária") tem 7 membros: os 3
  originais, a linhagem de branch (4º, sinal `2026-07-03-branch-lineage-divergence`), a gramática do
  artefato (`kg-radar.sh` com guarda de legibilidade, PR #398), a síntese declarada ≠ achado verificável
  e a doutrina declarada ≠ praticada (`effort` nos scripts Workflow, guarda ainda a nomear). A KB irmã,
  um nível acima, é `behavior-over-declaration.md`.

## Next crumb
Candidatos a 4º membro para vigiar: contagens de inventário (declarado no doc vs filesystem — já
guardado pelo lint), `members.yaml.personality_summary` (declarado vs comportamento real — F2),
CHANGELOG "entregue" vs inbound real do adotante. Ao guardar um novo membro, atualizar a tabela
da família na KB.

## Re-testada em 2026-10-14 — PARCIAL: (static, contra a KB atual) o padrão vale. O Signal deixou de pedir "o quarto caso", porque a família já tem 7 membros e raiz nomeada; o Evidence agora traz o estado atual da tabela.
