---
branch: fix/backup-retention-glob
pr: 596
date: 2026-08-14
reviewed_diff_sha256: 850a3982a201fbbf59f502fb907fbdc792582b8beaa4d894fcb6ff43fd071f16
findings_total: 1
findings_real: 1
findings_fixed: 1
tokens: 0
duration_min: 5
verdict: CORRIGIDO
reviewer: o próprio mecanismo (update-bridge.sh fail-closed) + verificação por bash -x — diff de 1 linha, sem passada de agente
---

# Resíduo — `fix/backup-retention-glob`

A 1ª execução do ramo cheio do `ops/update-bridge.sh` (gate G0 do BRIDGE-EVOLVE) abortou
fail-closed em "backup falhou" — e a investigação por `bash -x` achou a mentira: o backup
NASCE são (o .gpg existe, 3,7KB) e quem mata é a RETENÇÃO, cega desde 2026-08-11 quando os
dumps viraram `.gpg`: `bridge-diario-*.tar.gz` não casa mais nada, glob sem match vira
literal, `ls` sai 2, `set -e` derruba — DEPOIS do artefato pronto. O cron noturno (root,
03:40) vinha morrendo ali há 3 dias sem ninguém ver (exit-code-não-é-a-verificação, na
direção inversa: exit 2 com trabalho FEITO).

Cura: padrão segue o formato vivo (`.tar.gz.gpg`) + `|| true` (retenção vazia não é
falha). Provado: `rc=0` com artefato nomeado. O mérito é do mecanismo: o `|| fail` do
update-bridge pegou no 1º uso o que o cron engolia.
