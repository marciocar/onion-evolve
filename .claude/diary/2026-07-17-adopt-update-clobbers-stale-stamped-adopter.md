---
date: 2026-07-17
instance: onion-evolve
type: error
classification: protected
tags: [adopt, update, pin-integrity, vendor-branch, declared-vs-verified, clobber]
affects: [meta, engineering]
breadcrumb_for: []
share_with: []
next_recommended: ""
review_after: 2026-10-15
conflict_class: dynamic
valid_when: "os 3 bugs abaixo seguem sem fix no adopt.md / pin-integrity-check.sh / vendor-branch.sh"
---

## Signal
`/meta:adopt --update` num adotante **stale-stampado** (stamp mente sobre o framework real) **clobra em silêncio** — "merge limpo/exit 0" mascara o risco. Antes de qualquer `--update`, **verificar o estado REAL do framework do alvo** (não confiar no `.onion-version` nem no pin-integrity canário-só). Declarado≠verificado aplicado ao próprio mecanismo de adoção.

## Evidence
- Dogfood de campo (adotante regulado granaai, 2026-07-17): `--update` de um pin declarado → **3 bugs de core** encadeados:
  - **B1 — pin-integrity canário-só = falsa confiança:** `pin-integrity-check.sh` disse `pin-ok` enquanto **12+ arquivos de framework e o nível inteiro** divergiam (`lint-selftest.sh` 1003 vs 2649 linhas; `kg-radar.sh` ausente em develop). Canário bate ≠ framework íntegro.
  - **B2 — fallback do `vendor-branch.sh` clobra:** sem baseline limpo == pin ("legado entrelaçado"), ramifica `onion/vendor` do **HEAD** (que já tem a customização na base) → merge "limpo" **sobrescreve** as versões locais sem conflito. Exit 0 é o caso ARRISCADO, não o seguro.
  - **B3 — stamp lido da branch errada:** `--update` lê o `.onion-version` da working-tree/branch checada (feat=`fb08cc6b`) mas mergeia na **integração** (develop=`4332ac8d`, 16 dias mais velho). Premissa do delta furada. O stamp deve vir da branch de integração.
- Antídoto aplicado: verifiquei clobber cross-repo (hash de cada arquivo do delta) → 12+ divergentes → **rollback** (`reset --hard origin/develop`, merge era local/não-pushado). Nada perdido.
- Raiz do stamp mentiroso: bug "re-carimbo por deslize de sessão" (sinal granaai 2026-07-10) manifestado por inteiro.

## Next crumb
Fix no core (candidatos a `/meta:evolve`): (B1) pin-integrity checar N arquivos/nível, não só canário; (B2) fallback deve ABORTAR (ou marcar gated), nunca clobrar em silêncio; (B3) ler o stamp da branch de integração resolvida, não da working-tree. Antes de re-tentar `--update` no granaai: re-adoção deliberada numa sessão dona (W2) + conserto do stamp. Re-teste desta migalha = rodar `--update` num alvo stale após os fixes e confirmar ABORT/CONFLITO, não exit-0-clobber.
