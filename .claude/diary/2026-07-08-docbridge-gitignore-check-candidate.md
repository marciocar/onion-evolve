---
date: 2026-07-08
instance: onion-evolve
type: observation
classification: protected
tags: [doc-bridge, gitignore, meta-adopt, co-evolution, gated-candidate]
affects: [meta, federation]
breadcrumb_for: [meta:adopt, meta:evolve]
share_with: []
next_recommended: ""
review_after: 2026-10-06
conflict_class: conditional
valid_when: "nenhum 2º adotante reportou/reproduziu regra docs/ larga demais engolindo docs/evolution/"
---

## Signal
Existe um candidato de evolução GATED (não implementar ainda): adicionar checagem
"canal do doc-bridge não pode estar gitignored" ao `/meta:adopt` (validação pós-adoção) ou ao lint
vendorizado. Enquanto o `valid_when` valer (nenhum 2º adotante reproduziu), NÃO construir a checagem
— o custo não se justifica. Ao encontrar o 2º caso, promover a checagem e superseder esta migalha.

## Evidence
- 1º caso (granaai, sinal 2026-07-07): regra blanket `/docs/` (linha 105 do `.gitignore`) engolia
  `docs/evolution/inbox/` — o canal upstream do doc-bridge; commit do sinal precisou de `git add -f`.
  Já **corrigido no adotante** (PR #1096, mergeado em develop). Não é bug ativo no core.
- Teste do 2º adotante (triagem 2026-07-08): no `/meta:adopt --update` de `rhilo-metagamify`,
  `git check-ignore -v` sobre `docs/evolution/inbox/README.md` e os `_processed/.gitkeep` de inbox e
  inbound → **não-ignorado**; repo **sem regra blanket `/docs/`**. Padrão **não recorreu**.
- Gatilho declarado no sinal: "candidato até um 2º adotante reportar o mesmo padrão" → não atendido.

## Next crumb
Re-teste (conditional → checar só o `valid_when`, o mais barato): quando vencer, verificar se algum
adotante novo reproduziu uma regra `docs/` larga que engula `docs/evolution/`. Se NÃO → renovar
`review_after` +90d. Se SIM → promover a checagem no `/meta:adopt`/lint vendorizado e marcar esta
entrada `superseded: true`. Sinal-fonte já triado e arquivado em
`docs/evolution/inbox/_processed/2026-07-07-sinal-gitignore-blanket-engole-inbox.md`.
