#!/usr/bin/env bash
# test-r15-3b.sh — dogfood do gate de efeito R15.3b (onion-effect-gate.sh).
# Testa o modo-de-falha (o ataque C3 concreto), não só o happy-path. Isolado.
# Exit: 0 = todos passam · 1 = alguma falha.

set -uo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
GATE="${DIR}/onion-effect-gate.sh"
PASS=0; FAIL=0
ok()  { printf '  ✅ %s\n' "$1"; PASS=$((PASS+1)); }
bad() { printf '  ❌ %s\n' "$1"; FAIL=$((FAIL+1)); }

# roda o gate, captura verdict + exit
run() { out="$(bash "$GATE" "$@" 2>/dev/null)"; rc=$?; printf '%s|%s' "$out" "$rc"; }

echo "== R15.3b onion-effect-gate.sh — dogfood =="

# T1 — INTAKE é autônomo (resumir conteúdo alheio não precisa de gate)
r="$(run --action summarize --untrusted-derived true)"
[ "$r" = "allow intake|0" ] && ok "T1 intake (summarize) → allow, exit 0" || bad "T1 veio '$r'"

# T2 — o ATAQUE C3: 'push' derivado de conteúdo não-confiável → GATE
r="$(run --action push --untrusted-derived true)"
[ "$r" = "gate execution-untrusted|3" ] && ok "T2 push+untrusted → gate, exit 3 (ataque C3 barrado)" || bad "T2 veio '$r'"

# T3 — execução NÃO derivada de untrusted → R15 não bloqueia (fluxo normal segue)
r="$(run --action commit --untrusted-derived false)"
[ "$r" = "allow execution-normal|0" ] && ok "T3 commit não-untrusted → allow-normal, exit 0" || bad "T3 veio '$r'"

# T4 — FAIL-SAFE: verbo desconhecido → gate (deny-by-default)
r="$(run --action frobnicate --untrusted-derived false)"
[ "$r" = "gate unknown-verb|3" ] && ok "T4 verbo desconhecido → gate (fail-safe), exit 3" || bad "T4 veio '$r'"

# T5 — mais verbos de execução derivados de untrusted, todos gated
allg=1
for v in commit push pr merge apply install delete send publish force-push; do
  r="$(run --action "$v" --untrusted-derived true)"
  [ "$r" = "gate execution-untrusted|3" ] || { allg=0; echo "     ↳ falhou p/ '$v': '$r'"; }
done
[ "$allg" -eq 1 ] && ok "T5 todos os verbos de execução+untrusted → gate" || bad "T5 algum verbo de execução escapou"

# T6 — --action ausente → exit 2
rc=0; bash "$GATE" --untrusted-derived true >/dev/null 2>&1 || rc=$?
[ "$rc" -eq 2 ] && ok "T6 --action ausente → exit 2" || bad "T6 esperava exit 2, veio $rc"

# T7 — case-insensitive (PUSH == push)
r="$(run --action PUSH --untrusted-derived true)"
[ "$r" = "gate execution-untrusted|3" ] && ok "T7 verbo maiúsculo normalizado (PUSH → gate)" || bad "T7 veio '$r'"

# T8 — REGRESSÃO (blocker): flag final sem valor NÃO pode travar (loop infinito) → exit 2 rápido
rc=0; timeout 5 bash "$GATE" --action </dev/null >/dev/null 2>&1 || rc=$?
[ "$rc" -eq 2 ] && ok "T8 --action sem valor → exit 2 (sem loop)" || bad "T8 esperava exit 2, veio $rc (124=LOOP)"
rc=0; timeout 5 bash "$GATE" --untrusted-derived </dev/null >/dev/null 2>&1 || rc=$?
[ "$rc" -eq 2 ] && ok "T8 --untrusted-derived sem valor → exit 2 (sem loop)" || bad "T8 esperava exit 2, veio $rc (124=LOOP)"

echo "== resultado: ${PASS} passaram · ${FAIL} falharam =="
[ "$FAIL" -eq 0 ]
