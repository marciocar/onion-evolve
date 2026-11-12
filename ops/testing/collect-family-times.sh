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
# A FAIXA QUE ESTOUROU TAMBÉM CONTA (2026-11-12, tarde): a fonte é a SONDA DE DISCO do artefato
# (`selftest-disk.tsv`, linhas `inicio`/`fim` por família, gravadas NA HORA), e não as linhas `⏱` do log. O
# `⏱` só sai no fim do passo: a faixa morta pelo teto não imprime nenhum, e a tabela via só os runs em que a
# família COUBE — o viés que escondia a `selftest_selection` acima de 1000 s. Família com `inicio` e sem
# `fim` entra como LIMITE INFERIOR: do início dela até o teto do passo (ONION_COLLECT_STEP_TIMEOUT_S, 1380 s
# = 23 min) contado do `inicio` da faixa.
#
# USO : collect-family-times.sh <run-id> [<run-id> …]  > ops/testing/selftest-family-times.tsv
#       (runs do workflow Onion Selftest no nível COMPLETO, com o artefato `selftest-evidence-*`)
# EXIT: 0 ok · 1 run sem artefato de sonda legível · 2 uso errado
# `fixtures` sai como o TOTAL do run (a soma das fatias de todas as faixas e workers): ela roda em várias
# faixas com a sua fatia, e o plano divide esse total pelas faixas que a recebem × workers.
# =============================================================================
set -uo pipefail
[ "$#" -ge 1 ] || { echo "uso: collect-family-times.sh <run-id> [<run-id> …]" >&2; exit 2; }
for RUN in "$@"; do
  case "${RUN}" in (''|*[!0-9]*) echo "uso: run-id numérico ('${RUN}')" >&2; exit 2 ;; esac
done
STEP_S="${ONION_COLLECT_STEP_TIMEOUT_S:-1380}"
work="$(mktemp -d)"
trap 'rm -rf -- "${work}"' EXIT
for RUN in "$@"; do
  if ! out="$(gh run download "${RUN}" -p 'selftest-evidence-*' -D "${work}/${RUN}" 2>&1)"; then
    echo "collect-family-times: não baixei os artefatos do run ${RUN}: ${out:0:200}" >&2; exit 1
  fi
done
RUNS="$*" STEP_S="${STEP_S}" python3 -c '
import csv, glob, os, statistics, sys
work, step = sys.argv[1], int(os.environ["STEP_S"])
per, fx_by_run, bounds = {}, {}, 0
for run in os.environ["RUNS"].split():
    files = glob.glob(os.path.join(work, run, "*", "selftest-disk.tsv"))
    if not files:
        print("collect-family-times: o run %s não tem selftest-disk.tsv no artefato" % run, file=sys.stderr); sys.exit(1)
    fx = 0
    for p in files:
        rows = list(csv.reader(open(p, encoding="utf-8"), delimiter="\t"))[1:]
        st, last, t0, tf = {}, 0, None, None
        for r in rows:
            if len(r) < 4: continue
            f, ph, ep, w = r[0], r[1], int(r[2]), r[3]
            last = max(last, ep)
            if f == "_faixa":
                if ph == "inicio": t0 = ep
                else: tf = ep
                continue
            if ph == "inicio": st[(f, w)] = ep
            elif (f, w) in st:
                d = ep - st.pop((f, w))
                if f == "fixtures": fx += d
                else: per.setdefault(f, []).append(d)
        if tf is None and t0 is not None: last = max(last, t0 + step)   # a faixa morreu no teto do passo
        for (f, w), s in st.items():                                   # no ar quando a faixa morreu
            if f == "fixtures": fx += last - s
            else: per.setdefault(f, []).append(last - s); bounds += 1
    fx_by_run[run] = fx
runs = os.environ["RUNS"].split()
print("# familia\tsegundos — mediana de %d run(s) completo(s) no runner do CI, pela sonda de disco (collect-family-times.sh %s)" % (len(runs), " ".join(runs)))
print("# %d medida(s) de família que estava no ar quando a faixa estourou entraram como limite inferior" % bounds)
print("# fixtures = TOTAL do run (soma das fatias de todas as faixas e workers)")
per["fixtures"] = list(fx_by_run.values())
for f in sorted(per): print("%s\t%d" % (f, round(statistics.median(per[f]))))
' "${work}"
