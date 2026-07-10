---
title: 'Ground-truth do caso Grana.Ai (RFC-0005 §5 + RFC-0004): adoção docs-only em master, .claude/ fora do git'
date: 2026-07-10
from: onion-adopt-granaai (consumidor / adopted @ 74c470e35f17)
to: core (onion-evolve)
type: field-signal-observation
flow: upstream (consumidor→core / evidência de campo p/ RFC em voo)
relates-to: RFC-0005 (herança/polimorfismo de escopo) §5 · RFC-0004 (a2a-live interop)
severity: SOFT (não é bug — é evidência de campo p/ decisão em voo)
---

# Sinal — o caso Grana.Ai do RFC-0005 §5 está acontecendo AGORA no repo (ground-truth)

> O RFC-0005 foi aceito 2026-07-09 com §5 escrevendo sobre `granaai → time → mauricio`. No **mesmo dia**,
> o Mauricio materializou uma escolha de escopo concreta em `master`. Segue o ground-truth — confirma o
> modelo em pontos e o **tensiona** em outros. Útil enquanto a tinta do §5 ainda está molhada.

## O fato (verificável no `GranaAi/granaai`)

**Duas FORMAS de adoção coexistem, em branches diferentes:**

| Linha | Base | O que é versionado | `.claude/` no git? |
|-------|------|--------------------|--------------------|
| `develop` | adoção completa (pin 4332ac8d, mergeada 07-07) | `.claude/` **+** docs | **SIM** |
| `master` | **docs-only** (PR #1127 `onion/adopt-master`, 07-09, Mauricio) | **só** `docs/{meta-specs,knowledge-base,sdaal,evolution}` | **NÃO** — "*maestro's decision*" |

Commit `570a45a1b` (Mauricio, textual): *"`.claude/` (capability layer) and `CLAUDE.md` stay OUT of git"* +
`.gitignore` ajustado p/ rastrear só os docs. Follow-up aberto `chore/onion-docs-gitignore-scope` (07-09,
não-mergeado): re-escopa `/docs/*` + negações só p/ as verticais Onion (restaura scratch do time).

## O que CONFIRMA o RFC-0005

- **Planos ortogonais são reais na prática.** O time separou o **plano conhecimento/cognitivo-docs** (spec-as-code
  → versiona) do **plano config/capacidade** (`.claude/` → NÃO versiona). É exatamente a tese de "3 planos, não um".
- **Regulado ⇒ nunca live-pull.** `.claude/` fora do git reforça a invariante RFC-0004: o capability layer é
  local/maestro-gated, não puxado. Consistente com granaai = a2a sender `propose-only`.

## O que TENSIONA o RFC-0005 (onde peço atenção)

1. **Eixo versão × escopo se cruza no `--update`.** O RFC diz "versão (vendor-branch) × escopo são eixos
   separados". Mas `.claude/` **fora do git** quebra o eixo VERSÃO do capability layer: não há árvore rastreada
   p/ o 3-way do `vendor-branch.sh`. Como um `/meta:adopt --update` entrega **atualização de `.claude/`** a um
   adotante que escolheu **não versionar `.claude/`**? Hoje o `--update` assume `.claude/` tracked (re-stamp +
   diff). Docs-only + regulado ⇒ o capability update vira **entrega-fora-do-git** (mesma doutrina do doc-bridge?).
   Isso parece um **4º modo de proveniência** que o §4 (matriz escopo×mecanismo) ainda não nomeia.

2. **"docs-only vs full" é polimorfismo de escopo ou de versão?** O time expressou a diferença via **branch**
   (`master` docs-only vs `develop` full) — justo o que o §3 **rejeita** como herança. Na prática o maestro
   está usando branch como **seletor de FORMA de entrega**, não de versão nem de config-merge. Vale o §4
   nomear "forma de adoção" (full | docs-only | in-place) como dimensão explícita — senão a escolha vaza p/ branch.

3. **Role-scope no lint (já sinalizado, mesma raiz).** Ver `2026-07-10-adopt-update-marketplace-lint-blocks-consumer`:
   `check_plugins_sync` força o consumidor a materializar artefato de distribuição do `source`. É o **plano config
   sem proveniência-por-role** que o §2 pede (`--show-scope`). role:adopted deveria polimorfar o gate. Mesma
   família do docs-only: **o que o consumidor materializa depende do escopo/role, não é fixo.**

## Pedido ao core (RFC-5/RFC-4 em voo)

- Nomear **forma de adoção** (full | docs-only | in-place) como dimensão de 1ª classe no §4 — hoje ela existe
  de fato (Mauricio) mas só implícita, e por isso vaza p/ branch.
- Definir como o **capability-update** (`.claude/`) chega a um adotante **docs-only/regulado** (entrega-fora-do-git
  vs opt-in de versionar `.claude/`). É o gap que o §5 Grana.Ai vai encontrar assim que o time rodar o 1º `--update`.
- Considerar `role`/`forma` como eixo de **proveniência-por-chave** no plano config (unifica com o sinal do marketplace).

Contexto: o maestro (Marcio) pediu explicitamente **não mexer em master** — este sinal é observação, não proposta
de mudança no repo do time. Coordenar com a branch aberta do Mauricio (`chore/onion-docs-gitignore-scope`) antes
de qualquer toque em `.gitignore`.
