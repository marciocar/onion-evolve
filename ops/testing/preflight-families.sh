#!/usr/bin/env bash
# =============================================================================
# preflight-families.sh — as famílias da bancada que o diff STAGEADO de fato alterou
#
# POR QUÊ (2026-10-07): sob checkpoint (ONION_FINALIZE_CHECKPOINT=1) o motor só lintava, e a bancada ficava
# para o CI. Num só dia, três PRs quebraram no CI por casos NOVOS que passavam local: identidade git ausente
# no runner (#943, duas vezes), `[ ] && echo` devolvendo 1 sem a variável (#944) e um sítio novo da catraca
# `| grep -q` (#936). O mapa `--affected-staged` não serve aqui: mexer no lint-selftest.sh cai no failsafe
# "tudo" (217 famílias). Este helper responde a pergunta estreita que o pré-voo precisa — QUAIS famílias o
# diff alterou por dentro — e soma sempre a catraca estática `shell_pipefail_robustness`.
#
# USO  : preflight-families.sh [BASE]     (BASE default: merge-base com origin/main, ou main)
# SAÍDA: famílias separadas por vírgula (sempre inclui shell_pipefail_robustness)
# EXIT : 0 ok · 2 sem base para comparar (não chuta)
# =============================================================================
set -uo pipefail
SUT=".claude/validation/lint-selftest.sh"
BASE="${1:-$(git merge-base origin/main HEAD 2>/dev/null || git merge-base main HEAD 2>/dev/null || true)}"
[ -n "${BASE}" ] || { echo "preflight-families: sem merge-base com origin/main nem main — não chuto" >&2; exit 2; }

fams="shell_pipefail_robustness"
if git cat-file -e ":${SUT}" 2>/dev/null; then
  # linhas do arquivo STAGEADO tocadas pelo diff (lado +, com -U0) → a função run_*_selftests que as contém
  changed="$(git diff --cached -U0 "${BASE}" -- "${SUT}" | sed -n 's/^@@ -[0-9,]* +\([0-9]*\)\(,\([0-9]*\)\)\{0,1\} @@.*/\1 \3/p')"
  if [ -n "${changed}" ]; then
    hit="$(git show ":${SUT}" | CH="${changed}" python3 -c '
import os, re, sys
lines = sys.stdin.read().split("\n")
owner, cur = {}, None
for i, l in enumerate(lines, 1):
    m = re.match(r"^run_([a-z0-9_]+)_selftests\(\) \{", l)
    if m: cur = m.group(1)
    elif l.startswith("}") and cur: owner[i] = cur; cur = None; continue
    if cur: owner[i] = cur
out = set()
for row in os.environ["CH"].split("\n"):
    p = row.split()
    if not p: continue
    start = int(p[0]); n = int(p[1]) if len(p) > 1 and p[1] != "" else 1
    for k in range(start, start + max(n, 1)):
        if k in owner: out.add(owner[k])
print(",".join(sorted(out)))
')"
    [ -n "${hit}" ] && fams="${fams},${hit}"
  fi
fi
printf '%s\n' "${fams}"
