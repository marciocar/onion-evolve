---
date: 2026-07-09
instance: onion-evolve
type: decision
classification: public
tags: [scope, rfc-0005, inheritance, settings-cascade, compose-settings, supersedes, cavalgar-o-nativo]
affects: [scope, config, meta, adoption]
breadcrumb_for: [meta:adopt, meta:kg, engineer:plan]
share_with: [collective]
next_recommended: "2026-07-09-granaai-readonly-field-dogfood"
review_after: 2026-10-07
conflict_class: static
---

## Signal
Herança de escopo **framework → empresa → time → pessoa** decidida: **RFC-0005 ACCEPTED** (#308) — mecanismo
**HÍBRIDO de 3 planos**, cada um resolvido onde ele já resolve melhor, em vez de um único mecanismo forçado:
1. **Cognitivo** (CLAUDE.md/skills/agentes) → **cavalgar o nativo** do Claude Code (cascata hierárquica de
   diretórios + `~/.claude`). Zero código. **Time-dentro-do-repo já é nativo.**
2. **Config** (`settings.json`) → o **único gap real** (o `settings.json` não herda pela árvore de dirs) →
   `compose-settings.sh` (merge N-camadas type-aware + proveniência).
3. **Conhecimento** (verdade) → `SUPERSEDES` do KG ("git merge não reconcilia verdades") — **gated** (Fase 3).

## Evidence
- **Decidido por pesquisa orquestrada** (`docs/evolution/research/scope-inheritance-2026/`), mesmo padrão
  fan-out→verificação adversarial da RFC-0004.
- **`branch-para-escopo` REJEITADO** (RFC-0005 §3): é antipadrão GitOps e **não compõe** — versão (vendor-branch
  no tempo) e escopo (camadas que compõem no espaço) são **eixos ortogonais**, não se colapsam num só.
- **Loop fechado, dogfood-first:** #309 `compose-settings.sh` (objetos recursam · arrays unem hooks/permissions ·
  escalares last-wins · `--provenance`); #314 convenção `scope-convention-2026.md` (matriz escopo×3-planos) +
  `resolve-scope-layers.sh` (descobre a cadeia empresa→time→pessoa que EXISTE e delega ao compose).
- **Insight que economizou código:** o nativo cobre user/project/local; **só a camada do TIME (subdiretório)**
  exige o compose. Ver o gap com precisão evitou reconstruir a cascata inteira à mão.

## Next crumb
Fase 3 (`SUPERSEDES` de escopo) fica **gated atrás de dogfood** — não colar merge-de-arquivo com override-de-verdade.
Invariante a proteger: **never-clobber** (o compose é merge determinístico + proveniência, não clobber).
Ver [[2026-07-09-granaai-readonly-field-dogfood]] (validação de campo desta convenção) e
[[2026-07-09-federation-redesign-rfc0004-shipped]] (RFC-irmã).
