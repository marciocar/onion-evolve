#!/usr/bin/env bash
# =============================================================================
# collect-family-times.sh — a tabela `familia<TAB>segundos` medida NO RUNNER do CI
#
# POR QUÊ (2026-10-07): as faixas da bancada no CI saíam com 5/10/17/19 min no mesmo PR — o round-robin
# ignora o custo. O plano (selftest-shard-plan.sh) distribui por tempo quando esta tabela existe. A régua é
# o runner de 4 núcleos, não a máquina de 8 onde a bancada roda local: o tempo relativo muda entre os dois.
#
# VÁRIOS RUNS, MEDIANA (2026-11-12, SAC-423): a mesma família variou de 660 a 984 s em 7 runs completos da
# main no mesmo dia (`selftest_selection`), porque cada faixa cai num runner diferente. Uma tabela de UM run
# carrega o ruído daquele runner. Com vários run-ids, cada família sai com a MEDIANA dos runs.
#
# USO : collect-family-times.sh <run-id> [<run-id> …]  > ops/testing/selftest-family-times.tsv
#       (runs do workflow Onion Selftest no nível COMPLETO; ele imprime `⏱ <familia> <N>s` com
#        ONION_SELFTEST_TIMING=1)
# EXIT: 0 ok · 1 nenhuma linha ⏱ num dos logs (run sem timing, ou log ainda indisponível) · 2 uso errado
# `fixtures` sai como o TOTAL do run (a soma das fatias de todas as faixas e workers): ela roda em TODA faixa
# com a sua fatia, e o plano divide esse total por faixas × workers para simular a fila.
# =============================================================================
set -uo pipefail
[ "$#" -ge 1 ] || { echo "uso: collect-family-times.sh <run-id> [<run-id> …]" >&2; exit 2; }
for RUN in "$@"; do
  case "${RUN}" in (''|*[!0-9]*) echo "uso: run-id numérico ('${RUN}')" >&2; exit 2 ;; esac
done
tmp="$(mktemp)"
for RUN in "$@"; do
  log="$(gh run view "${RUN}" --log 2>&1)" || { echo "collect-family-times: não li o log do run ${RUN}: ${log:0:200}" >&2; rm -f "${tmp}"; exit 1; }
  one="$(RUN="${RUN}" python3 -c '
import os, re, sys
best = {}; fx = 0
for line in sys.stdin:
    m = re.search(r"⏱ ([a-z0-9_]+) ([0-9]+)s", line)
    if not m: continue
    if m.group(1) == "fixtures": fx += int(m.group(2))
    else: best[m.group(1)] = max(best.get(m.group(1), 0), int(m.group(2)))
for f in sorted(best): print("%s\t%s\t%d" % (os.environ["RUN"], f, best[f]))
if fx: print("%s\tfixtures\t%d" % (os.environ["RUN"], fx))
' <<< "${log}")"
  [ -n "${one}" ] || { echo "collect-family-times: nenhuma linha ⏱ no run ${RUN} — o run tinha ONION_SELFTEST_TIMING=1?" >&2; rm -f "${tmp}"; exit 1; }
  printf '%s\n' "${one}" >> "${tmp}"
done
RUNS="$*" python3 -c '
import os, statistics, sys
per = {}
for l in open(sys.argv[1], encoding="utf-8"):
    r, f, v = l.rstrip("\n").split("\t")
    per.setdefault(f, []).append(int(v))
print("# familia\tsegundos — mediana de %d run(s) completo(s) no runner do CI (collect-family-times.sh %s)" % (len(os.environ["RUNS"].split()), os.environ["RUNS"]))
print("# fixtures = TOTAL do run (soma das fatias de todas as faixas e workers)")
for f in sorted(per): print("%s\t%d" % (f, round(statistics.median(per[f]))))
' "${tmp}"
rc=$?
rm -f "${tmp}"
exit "${rc}"
