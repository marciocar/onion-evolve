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
# Uso  : [ONION_SHARD_FAMILIES=a,b,c] bash ops/testing/selftest-shard-plan.sh [--project] [N=4]
# Saída: uma linha JSON `[{"n":1,"familias":"a,b,c"}, …]` para `fromJson` da matriz.
# Exit : 0 ok · 1 lista vazia (VAZIO NUNCA VIRA OK — matriz vazia = job verde que
#        não exerceu nada, o fail-open mais caro num gate de gate) · 2 sem SUT.
# =============================================================================
set -uo pipefail

PROJECT=0
if [ "${1:-}" = "--project" ]; then PROJECT=1; shift; fi
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

# SUBCONJUNTO (nível PR da bancada em dois níveis, passo D de D_MERGE_PROCESS_ONION_2026_10, 2026-10-13):
# `ONION_SHARD_FAMILIES=a,b,c` reparte SÓ estas, na ordem do --list. Vazio ou `ALL` = todas (o push ao
# main, o cron e o workflow_dispatch). Nome que o --list não conhece REPROVA (exit 2): uma seleção que
# cita família inexistente é incoerente, e filtrá-la em silêncio faria a matriz exercer menos do que
# o seletor prometeu.
SUBSET="${ONION_SHARD_FAMILIES:-}"
if [ -n "${SUBSET}" ] && [ "${SUBSET}" != "ALL" ]; then
  _keep=()
  for _f in ${SUBSET//,/ }; do
    _hit=0
    for _g in "${FAMS[@]}"; do [ "${_g}" = "${_f}" ] && { _hit=1; break; }; done
    [ "${_hit}" = "1" ] || { echo "selftest-shard-plan: família '${_f}' do subconjunto não existe no --list." >&2; exit 2; }
  done
  for _g in "${FAMS[@]}"; do
    case ",${SUBSET}," in *",${_g},"*) _keep+=("${_g}") ;; esac
  done
  FAMS=("${_keep[@]}")
  if [ "${#FAMS[@]}" -eq 0 ]; then
    echo "selftest-shard-plan: o subconjunto '${SUBSET}' não deixou família nenhuma." >&2
    exit 1
  fi
fi

# TEMPO MEDIDO (2026-10-07): com a tabela `familia<TAB>segundos` (medida no RUNNER pelo coletor
# ops/testing/collect-family-times.sh), o plano distribui por LPT guloso — a familia mais cara vai para a
# faixa mais leve. Medido antes: faixas de 5/10/17/19 min no mesmo PR, com a soma pedindo ~11 por faixa.
# Sem a tabela, segue o round-robin. Familia que a tabela nao conhece entra com a MEDIANA, nunca com zero.
#
# A CARGA DA FAIXA É A PAREDE DA FILA, NÃO A SOMA (2026-11-12, SAC-423). A faixa 2 estourou 23 min no PR #1612
# com a soma dela pedindo 913 s por worker. A fila dinâmica do `--jobs` NÃO pega o caro primeiro: cada
# worker anda o lint-selftest.sh na ORDEM DO SCRIPT e reivindica a próxima família livre, e a `fixtures`
# (posição 11) roda em todo worker. A `selftest_selection` (posição 130, 984 s) só começou aos 393 s e a faixa
# terminou aos 1378 s, com os outros três workers parados no fim. O LPT pela soma não vê isso. Agora o
# plano SIMULA a fila (ordem do --list, W workers, a fatia da `fixtures` em cada um) e põe cada família na
# faixa onde a parede projetada fica menor. Nas 35 faixas de 7 runs completos da main de 2026-11-12 o erro
# do simulador é de ±3% COM OS TEMPOS DO PRÓPRIO RUN e a fatia real da `fixtures`; pela MEDIANA da tabela (o
# que o `--project` usa), é de −18% a +43% por faixa: a variância entre runners e o desbalanço da `fixtures`
# entre workers (o maior worker leva 1,05 a 1,45× a média) não estão modelados. A régua prevê a ORDEM de
# grandeza e o piso estrutural, não a parede de um run.
# A linha `fixtures` da tabela é o TOTAL da família no run (soma das fatias de todas as faixas). W vem de
# ONION_SHARD_WORKERS (4 = o nproc do runner, medido no log "em 4 workers").
# `--project` imprime `faixa<TAB>parede_s<TAB>soma_s` em vez da matriz: é a projeção que o caso (h) da
# bancada lê, para que a régua do teto e a do plano sejam o MESMO modelo.
TIMES="${ONION_SHARD_TIMES:-${ROOT}/ops/testing/selftest-family-times.tsv}"
[ -f "${TIMES}" ] || TIMES=""
printf '%s\n' "${FAMS[@]}" | N="${N}" TIMES="${TIMES}" W="${ONION_SHARD_WORKERS:-4}" PROJECT="${PROJECT}" IMPROVE="${ONION_SHARD_IMPROVE:-1}" python3 -c '
import json, os, sys
fams = [l.strip() for l in sys.stdin if l.strip()]
n = max(1, int(os.environ["N"]))
W = max(1, int(os.environ["W"]) if os.environ["W"].isdigit() else 4)
times = {}
fx_total = 0.0
if os.environ.get("TIMES"):
    for line in open(os.environ["TIMES"], encoding="utf-8"):
        parts = line.rstrip("\n").split("\t")
        if len(parts) == 2 and not parts[0].startswith("#"):
            try: v = float(parts[1])
            except ValueError: continue
            if parts[0] == "fixtures": fx_total = v
            else: times[parts[0]] = v
# `fixtures` NAO entra no round-robin: vai a TODA faixa com a sua fatia do manifest (fixtures_lane i/n).
# Medido 2026-10-05: ~1600 s de CPU numa faixa so, teto de 25 min estourado 3x no PR #927 — somar
# faixas nao ajudava enquanto ela inteira caisse numa so.
fx = "fixtures" in fams
rest = [f for f in fams if f != "fixtures"]
pos = {f: i for i, f in enumerate(fams)}
known = sorted(times.values())
med = known[len(known) // 2] if known else 1.0
cost = lambda f: times.get(f, med)
# Familia que a tabela nao conhece entra pela MEDIANA; o plano AVISA no stderr pelo nome (nunca em silencio):
# familia nova nasce sem tempo medido e so ganha linha quando rodar na main (collect-family-times.sh).
_sem = sorted(f for f in rest if f not in times) if os.environ.get("TIMES") else []
if _sem:
    print("selftest-shard-plan: %d familia(s) sem tempo na tabela entram pela mediana (%.0f s): %s"
          % (len(_sem), med, ",".join(_sem[:12])), file=sys.stderr)
fx_w = (fx_total / (n * W)) if fx else 0.0

def wall(lane):
    # a fila dinamica do lint-selftest.sh --jobs: cada worker livre pega a proxima familia LIVRE na ordem
    # do script; ao chegar na `fixtures`, roda a SUA fatia (todo worker roda a dele)
    seq = sorted(lane, key=lambda f: pos[f])
    if fx:
        k = next((i for i, f in enumerate(seq) if pos[f] > pos["fixtures"]), len(seq))
        seq = seq[:k] + ["fixtures"] + seq[k:]
    t = [0.0] * W; ptr = [0] * W; taken = set()
    while True:
        live = [w for w in range(W) if ptr[w] < len(seq)]
        if not live: return max(t)
        w = min(live, key=lambda w: t[w])
        f = seq[ptr[w]]; ptr[w] += 1
        if f == "fixtures": t[w] += fx_w
        elif f not in taken: taken.add(f); t[w] += cost(f)

shards = [[] for _ in range(n)]
if times:
    walls = [wall(s) for s in shards]
    for f in sorted(rest, key=lambda f: (-cost(f), pos[f])):   # LPT: o mais caro primeiro
        best = None
        for k in range(n):
            wk = wall(shards[k] + [f])
            others = max([walls[j] for j in range(n) if j != k], default=0.0)
            key = (max(wk, others), wk, k)
            if best is None or key < best[0]: best = (key, k, wk)
        _, k, wk = best
        shards[k].append(f); walls[k] = wk
    # MELHORA LOCAL: o guloso fixa o pior e deixa faixas de 9 e de 17 min no mesmo plano. Move uma família
    # de faixa enquanto isso baixar (pior parede, soma dos quadrados): a folga se espalha por todas, e
    # a variância medida entre runners (+/-20%) não cai inteira numa faixa só.
    score = lambda ws: (round(max(ws)), sum(x * x for x in ws))
    # ONION_SHARD_IMPROVE=0 desliga a melhora (só para o caso (l) da bancada comparar)
    for _ in range(30 if os.environ.get("IMPROVE", "1") != "0" else 0):
        moved = False
        for f in sorted(rest, key=lambda f: -cost(f)):
            a = next(i for i, s in enumerate(shards) if f in s)
            base = score(walls); best = None
            src = [g for g in shards[a] if g != f]; wa = wall(src)
            for b in range(n):
                if b == a: continue
                wb = wall(shards[b] + [f])
                ws = list(walls); ws[a] = wa; ws[b] = wb
                if score(ws) < base and (best is None or score(ws) < best[0]): best = (score(ws), b, wb)
            if best:
                _, b, wb = best
                shards[a] = src; shards[b].append(f); walls[a] = wa; walls[b] = wb; moved = True
        if not moved: break
else:
    for i, f in enumerate(rest):
        shards[i % n].append(f)
if os.environ.get("PROJECT") == "1":
    for i, s in enumerate(shards):
        print("%d\t%.0f\t%.0f" % (i + 1, wall(s), sum(cost(g) for g in s)))
    raise SystemExit(0)
out = []
for i, s in enumerate(shards):
    if fx: s = ["fixtures"] + s
    if not s: continue
    d = {"n": i + 1, "familias": ",".join(s)}
    if fx: d["fixtures_lane"] = "%d/%d" % (i, n)
    out.append(d)
print(json.dumps(out))
'
