#!/usr/bin/env bash
# =============================================================================
# sync-main-worktree.sh — traz para o origin/main a worktree que tem `main` em uso (fast-forward, nunca mais)
#
# POR QUÊ (SAC-143, 2026-10-15): o harness lê `.claude/settings.json` e os hooks de $CLAUDE_PROJECT_DIR, que é o
#   checkout principal, em `main`. Os merges saem de worktrees pelo ops/merge-serial.sh, e nada trazia esse checkout
#   junto: medido em 2026-10-15, ele estava 36 commits atrás, e o hook Stop aposentado no #1129 ainda disparou na
#   sessão ~1h20 depois do merge, enquanto a sonda nova não valia. O `--sync` do pr-merge-verified não resolvia:
#   ele faz `checkout main` na worktree ATUAL, que falha justamente quando `main` está tomada pelo checkout principal.
#
# O QUE FAZ: acha pela `git worktree list --porcelain` a worktree com `branch refs/heads/main` e roda nela
#   `git fetch origin main` + `git merge --ff-only origin/main`. Nunca faz checkout, reset, stash nem merge de verdade.
#   Árvore suja: o ff-only recusa sozinho se um arquivo sujo for tocado, e o que não for tocado fica como estava.
#
# CONTRATO: sempre exit 0 (é cortesia depois de um merge PROVADO; o rc de quem chama responde pelo merge).
#   Uma linha no stdout: "sync-main: <worktree> <antes>→<depois>" · "já em dia" · "sem worktree em main" · "⚠️ …".
# Bancada: run_sync_main_worktree_selftests.
# =============================================================================
set -uo pipefail

wt="$(git worktree list --porcelain 2>/dev/null | awk '/^worktree /{w=substr($0,10)} /^branch refs\/heads\/main$/{print w; exit}')"
if [ -z "${wt}" ]; then echo "sync-main: nenhuma worktree com main em uso — nada a sincronizar"; exit 0; fi
git -C "${wt}" fetch -q origin main 2>/dev/null || { echo "sync-main: ⚠️ fetch de origin/main falhou em ${wt} — não sincronizei"; exit 0; }
before="$(git -C "${wt}" rev-parse --short HEAD 2>/dev/null)"
behind="$(git -C "${wt}" rev-list --count HEAD..origin/main 2>/dev/null || echo '?')"
if [ "${behind}" = 0 ]; then echo "sync-main: ${wt} já em dia (${before})"; exit 0; fi
if out="$(git -C "${wt}" merge --ff-only -q origin/main 2>&1)"; then
  echo "sync-main: ${wt} ${before}→$(git -C "${wt}" rev-parse --short HEAD) (${behind} commit(s); hooks e settings mergeados passam a valer)"
else
  echo "sync-main: ⚠️ ${wt} ficou em ${before}, ${behind} commit(s) atrás — o ff-only recusou: $(head -1 <<< "${out}")"
fi
exit 0
