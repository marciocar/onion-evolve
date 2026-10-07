#!/usr/bin/env bash
# =============================================================================
# collect-family-times.sh — a tabela `familia<TAB>segundos` medida NO RUNNER do CI
#
# POR QUÊ (2026-10-07): as faixas da bancada no CI saíam com 5/10/17/19 min no mesmo PR — o round-robin
# ignora o custo. O plano (selftest-shard-plan.sh) distribui por tempo quando esta tabela existe. A régua é
# o runner de 2 núcleos, não a máquina de 8 onde a bancada roda local: o tempo relativo muda entre os dois.
#
# USO : collect-family-times.sh <run-id do workflow Onion Selftest>  > ops/testing/selftest-family-times.tsv
#       (o workflow imprime `⏱ <familia> <N>s` com ONION_SELFTEST_TIMING=1)
# EXIT: 0 ok · 1 nenhuma linha ⏱ no log (run sem timing, ou log ainda indisponível) · 2 uso errado
# `fixtures` fica de fora: ela roda em TODA faixa com a sua fatia, e não entra na distribuição.
# =============================================================================
set -uo pipefail
RUN="${1:?uso: collect-family-times.sh <run-id>}"
case "${RUN}" in (*[!0-9]*) echo "uso: run-id numérico" >&2; exit 2 ;; esac
log="$(gh run view "${RUN}" --log 2>&1)" || { echo "collect-family-times: não li o log do run ${RUN}: ${log:0:200}" >&2; exit 1; }
out="$(python3 -c '
import re, sys
best = {}
for line in sys.stdin:
    m = re.search(r"⏱ ([a-z0-9_]+) ([0-9]+)s", line)
    if m and m.group(1) != "fixtures":
        best[m.group(1)] = max(best.get(m.group(1), 0), int(m.group(2)))
print("# familia\tsegundos — medido no runner do CI (collect-family-times.sh)")
for f in sorted(best): print("%s\t%d" % (f, best[f]))
' <<< "${log}")"
[ "$(grep -vc '^#' <<< "${out}")" -gt 0 ] || { echo "collect-family-times: nenhuma linha ⏱ no run ${RUN} — o run tinha ONION_SELFTEST_TIMING=1?" >&2; exit 1; }
printf '%s\n' "${out}"
