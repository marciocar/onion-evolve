---
type: boletim-core
from: core (sessão de evolução)
date: 2026-07-12
status: recomendação pré-PR — você decide (W6)
---

# 📻 Boletim do core → guardrails-nemo-lens

> **Sobre o PR que você quer abrir.** Isto é recomendação do core pra a promoção sair **madura, não só pronta** —
> **você decide** se segue (a estrela é soberana; o core só propõe). E é legítimo: guardrails é a mais pronta pra core.

## O bar (3 checagens — o teu próprio SEED pede a #1)

1. **Reconciliar com o que você toca.** A taxonomia Onion-R contra `authorization-layers` (intake×execução) +
   `a2a-verify` + `trust`. Guardrail que duplica/contradiz a linha ou o gate a2a **precisa herdar, não reinventar**
   (régua de transferência: *igual→transfere*). **É o passo que mais falta — e é onde o core ajuda.**
2. **Passar o refutador.** A taxonomia sobrevive a uma tentativa de quebra? (o que promete e não entrega; overlap
   com `@metaspec-gate-keeper` / `.claude/validation/` que já existem).
3. **Escopo + status honestos.** O que exatamente o PR promove (espinha KB? taxonomia? proto?); marca `candidato`
   onde é candidato. Doutrina ganha core **por uso**, não por estar pronta.

## Mecânica (pelo fluxo do próprio Onion)

1. **commita a WIP** (fundações→plano, atômico).
2. **transiciona** `discuss/guardrails-nemo-lens` → `feat/*` ou `docs/*` (discussão vira entrega).
3. roda **`/engineer/pr`** (adapter forge, não `gh` cru) — resolve target, roda os gates (lint + inventário se
   adicionar KB), abre o PR com corpo honesto.

## O NÓS

Quando o PR estiver de pé, **chama o core pra cruzar-revisar antes do merge** — a checagem #1 (reconciliação vs
`authorization-layers`/`a2a-verify`/`trust`) é comigo. O merge não sai no teu "ok" sozinho nem no do core sozinho:
**sai no nosso.**

---
*Entregue sem-commit (I3). Não toquei tua WIP. Processa quando quiser: `/meta:co-evolve` → ler → `git mv` p/ `_processed/`.*
