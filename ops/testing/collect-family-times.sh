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
# TODAS AS TENTATIVAS (2026-11-12, refutador do #1635): `gh run download` baixa só o artefato da ÚLTIMA
# tentativa. No run 43268758579 o estouro da tentativa 1 (selftest_selection no ar desde +390 s) foi trocado
# pela tentativa 2, verde em 660 s, e a tabela perdeu justamente o estouro que motivou a cura. Agora o
# coletor LISTA `actions/runs/<id>/artifacts` e baixa cada artefato pelo id: cada tentativa de cada faixa é
# uma observação. O total da `fixtures` por run soma, por faixa, a mediana das tentativas dela.
# O repo vem de ONION_COLLECT_REPO ou do `gh repo view`.
#
# FAMÍLIA PARTIDA (2026-11-12, tarde): ONION_COLLECT_SPLIT="<antiga>:<fração>:<nova>" diz que a <nova> nasceu
# de casos tirados da <antiga>. Num run em que a <nova> ainda não existia, a medida da <antiga> é a família
# inteira: o coletor a divide, <fração> fica com a <antiga> e o resto vai para a <nova>. Num run em que a
# <nova> já rodou, nada muda. A fração é MEDIDA (o tempo por caso de uma rodada) e fica escrita no cabeçalho
# da tabela, para a próxima re-medição saber de onde veio.
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
REPO="${ONION_COLLECT_REPO:-}"
if [ -z "${REPO}" ]; then
  REPO="$(gh repo view --json nameWithOwner -q .nameWithOwner 2>&1)" || { echo "collect-family-times: não descobri o repo (${REPO:0:160}); use ONION_COLLECT_REPO" >&2; exit 1; }
fi
work="$(mktemp -d)"
trap 'rm -rf -- "${work}"' EXIT
for RUN in "$@"; do
  mkdir -p "${work}/${RUN}"
  if ! gh api "repos/${REPO}/actions/runs/${RUN}/artifacts?per_page=100" > "${work}/${RUN}/list.json" 2> "${work}/${RUN}/list.err"; then
    echo "collect-family-times: não listei os artefatos do run ${RUN}: $(head -c 200 "${work}/${RUN}/list.err")" >&2; exit 1
  fi
  ids="$(python3 -c '
import json, sys
for a in json.load(open(sys.argv[1])).get("artifacts", []):
    if a.get("name", "").startswith("selftest-evidence-") and not a.get("expired"): print("%s\t%s" % (a["id"], a["name"]))
' "${work}/${RUN}/list.json")" || { echo "collect-family-times: a lista de artefatos do run ${RUN} não é JSON legível" >&2; exit 1; }
  [ -n "${ids}" ] || { echo "collect-family-times: o run ${RUN} não tem artefato selftest-evidence-*" >&2; exit 1; }
  while IFS=$'\t' read -r aid aname; do
    if ! gh api "repos/${REPO}/actions/artifacts/${aid}/zip" > "${work}/${RUN}/${aid}.zip" 2> "${work}/${RUN}/${aid}.err"; then
      echo "collect-family-times: não baixei o artefato ${aid} do run ${RUN}: $(head -c 200 "${work}/${RUN}/${aid}.err")" >&2; exit 1
    fi
    python3 -c '
import sys, zipfile
zipfile.ZipFile(sys.argv[1]).extractall(sys.argv[2])
' "${work}/${RUN}/${aid}.zip" "${work}/${RUN}/${aid}" || { echo "collect-family-times: o artefato ${aid} do run ${RUN} não é zip legível" >&2; exit 1; }
    printf '%s\n' "${aname}" > "${work}/${RUN}/${aid}/.name"
  done <<< "${ids}"
done
RUNS="$*" STEP_S="${STEP_S}" SPLIT="${ONION_COLLECT_SPLIT:-}" python3 -c '
import csv, glob, os, statistics, sys
work, step = sys.argv[1], int(os.environ["STEP_S"])
per, fx_by_run, bounds = {}, {}, 0
split = os.environ.get("SPLIT", "").split(":") if os.environ.get("SPLIT") else None
if split and (len(split) != 3 or not split[0] or not split[2]):
    print("collect-family-times: ONION_COLLECT_SPLIT deve ser <antiga>:<fração>:<nova>", file=sys.stderr); sys.exit(2)
if split:
    try: frac = float(split[1]); assert 0 < frac < 1
    except Exception: print("collect-family-times: fração inválida em ONION_COLLECT_SPLIT", file=sys.stderr); sys.exit(2)
for run in os.environ["RUNS"].split():
    run_per = {}
    files = glob.glob(os.path.join(work, run, "*", "selftest-disk.tsv"))
    if not files:
        print("collect-family-times: o run %s não tem selftest-disk.tsv no artefato" % run, file=sys.stderr); sys.exit(1)
    fx_by_lane = {}
    for p in files:
        fx = 0
        name = open(os.path.join(os.path.dirname(p), ".name"), encoding="utf-8").read().strip()
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
                else: run_per.setdefault(f, []).append(d)
        if tf is None and t0 is not None: last = max(last, t0 + step)   # a faixa morreu no teto do passo
        for (f, w), s in st.items():                                   # no ar quando a faixa morreu
            if f == "fixtures": fx += last - s
            else: run_per.setdefault(f, []).append(last - s); bounds += 1
        fx_by_lane.setdefault(name, []).append(fx)
    if split and split[0] in run_per and split[2] not in run_per:   # o run é de antes da partição
        whole = run_per[split[0]]
        run_per[split[0]] = [v * frac for v in whole]
        run_per[split[2]] = [v * (1 - frac) for v in whole]
    for f, v in run_per.items(): per.setdefault(f, []).extend(v)
    fx_by_run[run] = sum(statistics.median(v) for v in fx_by_lane.values())
runs = os.environ["RUNS"].split()
print("# familia\tsegundos — mediana de %d run(s) completo(s) no runner do CI, pela sonda de disco (collect-family-times.sh %s)" % (len(runs), " ".join(runs)))
print("# todas as tentativas de cada run; %d medida(s) de família que estava no ar quando a faixa estourou entraram como limite inferior" % bounds)
print("# fixtures = TOTAL do run (soma das fatias de todas as faixas e workers)")
if split: print("# partição: nos runs sem %s, a medida de %s foi dividida %.3f / %.3f (ONION_COLLECT_SPLIT=%s)" % (split[2], split[0], frac, 1 - frac, os.environ["SPLIT"]))
per["fixtures"] = list(fx_by_run.values())
for f in sorted(per): print("%s\t%d" % (f, round(statistics.median(per[f]))))
' "${work}"
