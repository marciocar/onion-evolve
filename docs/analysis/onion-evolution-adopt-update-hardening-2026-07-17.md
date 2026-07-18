---
title: 'Backlog de evolução — cluster "adopt-update hardening" (3 bugs de core)'
date: 2026-07-17
type: evolution-backlog
status: aberto
severity: HIGH
origin: sinal de campo (dogfood no adotante regulado granaai) — inbox/2026-07-17-adopt-update-pin-integrity-false-confidence.md
diary: .claude/diary/2026-07-17-adopt-update-clobbers-stale-stamped-adopter.md
family: declarado≠verificado
---

# Backlog — `/meta:adopt --update` clobra em silêncio um adotante stale-stampado

> Triado na sessão de co-evolução de 2026-07-17. Sinal de campo do dogfood no adotante **regulado**
> `granaai` (`--update` de pin declarado `fb08cc6b` → core `ef70fe1`): o merge deu **exit 0 "limpo"**,
> mas o estado real expôs **3 bugs encadeados** no mecanismo de adoção. Rollback aplicado (merge local,
> nada perdido). Números divergentes-de-snapshot por design (`type: evolution-backlog` isenta o lint de contagem).

## Modo de falha único

Os 3 bugs são **um só modo de falha**: o mecanismo de adoção **confia em estado declarado sem verificar
o real** — a própria família **declarado≠verificado** aplicada a si mesma. Um `exit 0` "limpo" é o caso
**arriscado**, não o seguro, quando o alvo está stale-stampado (o stamp mente sobre o framework real).

## Os bugs do cluster (B1-B3 de 2026-07-17; B4 apensado 2026-07-18)

### B1 — `pin-integrity-check.sh`: canário-só = falsa confiança 🔴 HIGH
Reportou `pin-ok fb08cc6b` enquanto **12+ arquivos de framework** e o **nível inteiro** divergiam
(`lint-selftest.sh` 1003 vs 2649 linhas; `kg-radar.sh` ausente em develop). Checar um canário ≠ verificar
integridade do framework.
- **Fix proposto:** amostrar N arquivos do manifesto (ou hash-set do nível) além do canário; divergência
  acima de limiar → pin **não-confiável**.
- **Alvo:** `.claude/utils/adopt/pin-integrity-check.sh`

### B2 — `vendor-branch.sh`: fallback do HEAD clobra em silêncio 🔴 HIGH
Sem baseline limpo == pin ("legado entrelaçado"), o helper ramifica `onion/vendor` do **HEAD**
(customização já na base) → merge "limpo" **sobrescreve** as versões locais sem conflito.
- **Fix proposto:** no fallback, **ABORTAR** (ou marcar gated-maestro), nunca prosseguir com merge que pode
  clobrar. Alternativa: reconstruir baseline por content-address mais agressivo antes de desistir.
- **Alvo:** `.claude/utils/adopt/vendor-branch.sh`

### B3 — `--update` lê o stamp da branch errada 🟡 MEDIUM
Lê `.onion-version` da working-tree/branch checada (`feat=fb08cc6b`) mas mergeia na **integração**
(`develop=4332ac8d`, 16 dias mais velho) → delta computado sobre pin errado.
- **Fix proposto:** resolver a integração PRIMEIRO e ler o stamp DELA
  (`git show <IB>:.claude/.onion-version`).
- **Alvo:** `.claude/commands/meta/adopt.md` (--update)

### B4 — `--update` deixa `docs/onion/inventory.md` stale 🟡 MEDIUM
Adicionado 2026-07-18 (sinal `kg-fail-open-primo` do granaai): o `--update` **não regenera o inventário**,
então o 1º commit pós-update bate no **lint HARD** (Regra 8 / drift de contagem). A **Fase 3** da adoção
regenera (`/meta:inventory`), mas o `--update` não — mesma família *declarado≠verificado* (o estado gerado
não é reconciliado com o real após o merge).
- **Fix proposto:** o `--update` regenera `inventory.md` (rodar `/meta:inventory`) ou **avisa** a staleness
  ao final (never-silent). Encaixa no "Procedimento de Configuração pós-cópia (idempotente)".
- **Alvo:** `.claude/commands/meta/adopt.md` (--update)

## Antídoto imediato (já provado em campo → candidato a guard nativo)
Verificação de clobber cross-repo (hash por arquivo do delta) antes de aceitar o merge → rollback
determinístico. Deveria virar **guard nativo** do `--update`: pós-merge, se algum arquivo do delta divergia
do pin no alvo, **exigir revisão humana**.

## Conexões
- **Dívida transversal já registrada:** `onion-coevolution-backlog-2026-06-18.md` §"Dívida técnica
  transversal" (*`/meta:adopt --update` sem teste ponta-a-ponta automatizado*) — este cluster é a
  manifestação completa daquela lacuna.
- **Raiz do stamp mentiroso:** bug "re-carimbo por deslize de sessão" (sinal granaai 2026-07-10),
  manifestado por inteiro aqui.
- **Sessão de origem do mecanismo:** `.claude/sessions/adopt-vendor-branch-merge/` (F1-F3 done; este
  sinal é o dogfood de campo que o `next_action` daquela sessão pedia).

## Re-teste da migalha (pré-condição de fechamento)
Rodar `--update` num alvo stale **após** os fixes e confirmar **ABORT/CONFLITO**, não exit-0-clobber.
Antes de re-tentar no granaai: re-adoção deliberada em sessão-dona (W2) + conserto do stamp.
