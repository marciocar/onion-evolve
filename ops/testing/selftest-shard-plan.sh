#!/usr/bin/env bash
# =============================================================================
# selftest-shard-plan.sh — distribui as famílias da bancada em N faixas de matriz
#
# POR QUE EXISTE (medido 2026-09-22/23): o job do selftest encostou DUAS VEZES no
# teto de 40 min (41m29s e 40m18s, ambas canceladas), com uma passagem de 32m20s
# no meio. A nota do próprio `onion-selftest.yml`, escrita em 2026-09-13, já havia
# decidido a resposta: *"se encostar de novo, o sinal é a suíte ter crescido, e a
# resposta é PARALELIZAR NO RUNNER, não subir o teto outra vez"*. A suíte foi de
# 689 asserções (quando o teto foi calibrado) para mais de 1400, e `--jobs auto`
# não resolve: o runner do GitHub tem 2 núcleos contra os 8 da máquina onde ela
# roda em ~19 min.
#
# ROUND-ROBIN, não blocos contíguos: famílias vizinhas na lista tendem a ser da
# mesma área e a custar o mesmo, então bloco contíguo concentraria o caro numa
# faixa só e o gargalo continuaria de pé.
#
# Vive em `ops/` e não inline no YAML de propósito: (a) o inline anterior quebrou
# o bloco escalar do YAML na primeira tentativa, e (b) script em arquivo tem
# bancada — YAML inline não tem.
#
# Uso  : bash ops/testing/selftest-shard-plan.sh [N=4]
# Saída: uma linha JSON `[{"n":1,"familias":"a,b,c"}, …]` para `fromJson` da matriz.
# Exit : 0 ok · 1 lista vazia (VAZIO NUNCA VIRA OK — matriz vazia = job verde que
#        não exerceu nada, o fail-open mais caro num gate de gate) · 2 sem SUT.
# =============================================================================
set -uo pipefail

N="${1:-4}"
case "${N}" in (*[!0-9]*|"") echo "uso: $0 [N inteiro >= 1]" >&2; exit 2 ;; esac
[ "${N}" -ge 1 ] || { echo "uso: $0 [N inteiro >= 1]" >&2; exit 2; }

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SUT="${ROOT}/.claude/validation/lint-selftest.sh"
[ -f "${SUT}" ] || { echo "selftest-shard-plan: ${SUT} AUSENTE — não pude planejar (≠ plano vazio)." >&2; exit 2; }

mapfile -t FAMS < <(bash "${SUT}" --list)
if [ "${#FAMS[@]}" -eq 0 ]; then
  echo "selftest-shard-plan: --list devolveu ZERO famílias. A matriz sairia vazia e o verde não significaria nada." >&2
  exit 1
fi

# TEMPO MEDIDO (2026-10-07): com a tabela `familia<TAB>segundos` (medida no RUNNER pelo coletor
# ops/testing/collect-family-times.sh), o plano distribui por LPT guloso — a familia mais cara vai para a
# faixa mais leve. Medido antes: faixas de 5/10/17/19 min no mesmo PR, com a soma pedindo ~11 por faixa.
# Sem a tabela, segue o round-robin. Familia que a tabela nao conhece entra com a MEDIANA, nunca com zero.
TIMES="${ONION_SHARD_TIMES:-${ROOT}/ops/testing/selftest-family-times.tsv}"
[ -f "${TIMES}" ] || TIMES=""
printf '%s\n' "${FAMS[@]}" | N="${N}" TIMES="${TIMES}" python3 -c '
import json, os, sys
fams = [l.strip() for l in sys.stdin if l.strip()]
n = max(1, int(os.environ["N"]))
times = {}
if os.environ.get("TIMES"):
    for line in open(os.environ["TIMES"], encoding="utf-8"):
        parts = line.rstrip("\n").split("\t")
        if len(parts) == 2 and not parts[0].startswith("#"):
            try: times[parts[0]] = float(parts[1])
            except ValueError: pass
# `fixtures` NAO entra no round-robin: vai a TODA faixa com a sua fatia do manifest (fixtures_lane i/n).
# Medido 2026-10-05: ~1600 s de CPU numa faixa so, teto de 25 min estourado 3x no PR #927 — somar
# faixas nao ajudava enquanto ela inteira caisse numa so.
fx = "fixtures" in fams
rest = [f for f in fams if f != "fixtures"]
shards = [[] for _ in range(n)]
if times:
    known = sorted(v for v in times.values())
    med = known[len(known) // 2] if known else 1.0
    load = [0.0] * n
    for f in sorted(rest, key=lambda f: -times.get(f, med)):   # LPT: o mais caro primeiro
        k = load.index(min(load))
        shards[k].append(f); load[k] += times.get(f, med)
else:
    for i, f in enumerate(rest):
        shards[i % n].append(f)
out = []
for i, s in enumerate(shards):
    if fx: s = ["fixtures"] + s
    if not s: continue
    d = {"n": i + 1, "familias": ",".join(s)}
    if fx: d["fixtures_lane"] = "%d/%d" % (i, n)
    out.append(d)
print(json.dumps(out))
'
