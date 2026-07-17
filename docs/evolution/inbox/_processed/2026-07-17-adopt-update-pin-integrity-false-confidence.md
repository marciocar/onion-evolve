---
title: 'Signal: adopt --update clobra adotante stale-stampado (3 bugs de core)'
date: 2026-07-17
from: core (dogfood de campo — sessão-fonte operando no adotante granaai)
to: core (/meta:evolve backlog)
type: field-signal-bug
flow: internal (achado de campo → backlog de modernização)
severity: HIGH (clobber silencioso de customização em adotante regulado)
---

# Signal — `/meta:adopt --update` clobra em silêncio um adotante stale-stampado

## Contexto
Dogfood de campo: `--update` do adotante **regulado** granaai (declarado `fb08cc6b` → core `ef70fe1`). O merge deu **exit 0 "limpo"**, mas o estado real expôs **3 bugs encadeados** no mecanismo de adoção. Rollback aplicado (merge local, nada perdido).

## Os 3 bugs

### B1 — `pin-integrity-check.sh`: canário-só = falsa confiança (HIGH)
Reportou `pin-ok fb08cc6b` enquanto **12+ arquivos de framework** e o **nível inteiro** divergiam (`lint-selftest.sh` 1003 vs 2649 linhas). Checar um canário ≠ verificar integridade do framework.
**Fix proposto:** amostrar N arquivos do manifesto (ou hash-set do nível) além do canário; divergência acima de limiar → pin não-confiável.

### B2 — `vendor-branch.sh`: fallback do HEAD clobra em silêncio (HIGH)
Sem baseline limpo == pin ("legado entrelaçado"), o helper ramifica `onion/vendor` do **HEAD** (customização já na base) → merge "limpo" **sobrescreve** local sem conflito. Exit 0 é o caso ARRISCADO.
**Fix proposto:** no fallback, **ABORTAR** (ou marcar gated maestro), nunca prosseguir com merge que pode clobrar. Alternativa: reconstruir baseline por content-address mais agressivo antes de desistir.

### B3 — `--update` lê o stamp da branch errada (MEDIUM)
Lê `.onion-version` da working-tree/branch checada, mas mergeia na **integração** (que pode ter framework/stamp diferente). Delta computado sobre pin errado.
**Fix proposto:** resolver a integração PRIMEIRO e ler o stamp DELA (`git show <IB>:.claude/.onion-version`).

## Antídoto imediato (já aplicado)
Verificação de clobber cross-repo (hash por arquivo do delta) antes de aceitar o merge → rollback determinístico. Deveria virar **guard nativo** do `--update`: pós-merge, se algum arquivo do delta divergia do pin no alvo, exigir revisão humana.

## Recomendação
Triar no `/meta:evolve` como cluster "adopt-update hardening" (B1+B2+B3 são um só modo de falha: **o mecanismo confia em estado declarado sem verificar o real** — a própria família declarado≠verificado). Migalha de diário: `2026-07-17-adopt-update-clobbers-stale-stamped-adopter`.
