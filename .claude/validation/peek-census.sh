#!/usr/bin/env bash
# ===========================================================================
# peek-census.sh — o MEDIDOR da peça 3 do /meta:peek (espiar o mercado na dúvida).
#
# Pedido do maestro em 2026-11-13: «nas dúvidas você tem que espiar o mercado e principalmente fóruns e comunidades
# [...] gastando o esforço que você enxergue (com um padrão escolhido e aprendido também) quanto de energia vale a
# pena gastar na descoberta». Este medidor responde por medição as duas metades disso:
#   ESCOLHIDO  --pick: a tabela .claude/utils/peek/peek-ladder.tsv (achada AO LADO, em ../utils/peek/) dá o nível
#              (0 a 3) pela reversibilidade x severidade x incerteza da dúvida, com o orçamento do nível.
#   APRENDIDO  o histórico: cada espiada registrada num .kg.yaml rastreado (nó com x_peek_level) entra na conta
#              por célula da tabela, e o medidor PROPÕE subir ou descer a célula pelo que as espiadas renderam
#              (se mudaram a decisão). Propõe; quem muda a tabela é o maestro.
#
# ── O QUE É NOSSO E O QUE É DE MERCADO (rodada market-peek-machinery-2026-11, run wf_3157a547-84f) ──────
#   De mercado: a escada de esforço embutida no prompt e o degrau-base de 1 agente com 3-10 chamadas (Anthropic,
#   multi-agent research system); a taxonomia porta de mão única x dupla (carta da Amazon de 2015).
#   CUNHAGEM ONION, declarada: a ponte reversibilidade -> degrau, o registro por espiada e a recalibração pelo
#   histórico. A rodada não achou evidência de mercado para nenhum dos três; eles se medem por dogfood.
#   VOI/EVPI ficam como teto conceitual: sem payoffs numéricos não viram regra de parada (objeção que bloqueia).
#
# ── O REGISTRO (descoberto pelo CAMPO, nunca pelo nome do arquivo) ────────────────────────────────────
#   Todo nó com x_peek_level em qualquer .kg.yaml rastreado (fora fixtures e vendor) é uma espiada. Campos:
#     x_peek_level (0-3) · x_peek_reversibility (one-way|two-way) · x_peek_severity (1-5)
#     x_peek_uncertainty (low|med|high) · x_peek_calls (inteiro) · x_peek_sources (lista não vazia)
#     x_peek_changed_decision (yes|no|pending; o yes/no sem aspas, que o YAML 1.1 lê como booleano, vale) · verified_at (AAAA-MM-DD)
#     x_peek_override (texto) é OBRIGATÓRIO quando o nível difere do que a tabela escolhe.
#   Registro inválido sai em linha `peek ... invalid(...)` e o rc vira 1: série com buraco não ensina.
#
# Uso:  bash .claude/validation/peek-census.sh [<repo>] [--markdown|--tsv] [--min-n N] [--ladder <tsv>]
#       bash .claude/validation/peek-census.sh [<repo>] --pick <one-way|two-way> <1-5> <low|med|high>
# Env (bancada; override ativo é DECLARADO na saída): PEEK_TODAY=AAAA-MM-DD
# Exit: 0 = medido · 1 = há registro de espiada inválido (listado) · 2 = não deu para medir (tabela quebrada,
#       sem git, python3/PyYAML ausente, argumento inválido).
# Determinístico, sem LLM, sem rede, 0 tokens. Exercitado por lint-selftest.sh (run_market_peek_selftests).
# ===========================================================================
set -uo pipefail
REPO="."; FMT="--markdown"; MINN="5"; LADDER=""; PICK=""
_need() { [ $# -ge 2 ] && [ -n "$2" ] || { echo "peek-census: $1 exige um valor" >&2; exit 2; }; }
while [ $# -gt 0 ]; do
  case "$1" in
    --markdown|--tsv) FMT="$1" ;;
    --min-n) _need "$@"; shift; MINN="$1" ;;
    --ladder) _need "$@"; shift; LADDER="$1" ;;
    --pick) [ $# -ge 4 ] || { echo "peek-census: --pick exige <reversibilidade> <severidade> <incerteza>" >&2; exit 2; }
            PICK="$2 $3 $4"; shift 3 ;;
    --*) echo "peek-census: opção desconhecida: $1" >&2; exit 2 ;;
    *) REPO="$1" ;;
  esac
  shift
done
case "${MINN}" in ''|*[!0-9]*|0) echo "peek-census: --min-n inválido (${MINN})" >&2; exit 2 ;; esac
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[ -n "${LADDER}" ] || LADDER="${HERE}/../utils/peek/peek-ladder.tsv"
[ -f "${LADDER}" ] || { echo "peek-census: tabela da escada ausente (${LADDER})" >&2; exit 2; }
command -v python3 >/dev/null 2>&1 && python3 -c 'import yaml' >/dev/null 2>&1 \
  || { echo "peek-census: python3/PyYAML ausentes" >&2; exit 2; }
REPO="$(cd "${REPO}" 2>/dev/null && pwd -P)" || { echo "peek-census: repo inexistente" >&2; exit 2; }
FILES=""
if [ -z "${PICK}" ]; then
  git -C "${REPO}" rev-parse --git-dir >/dev/null 2>&1 || { echo "peek-census: ${REPO} não é repo git (o registro é o que está rastreado)" >&2; exit 2; }
  # pré-filtro barato: só os grafos rastreados que CITAM o campo; o python confirma pelo YAML
  FILES="$(git -C "${REPO}" grep -l -e 'x_peek_level' -- '*.kg.yaml' ':!:*fixtures*' ':!:vendor/*' 2>/dev/null || true)"
fi

python3 -I - "${REPO}" "${FMT}" "${MINN}" "${LADDER}" "${PICK}" "${PEEK_TODAY:-}" "${FILES}" <<'PC_PY'
import datetime as dt, os, sys, yaml
repo, fmt, minn, ladder, pick, today_s, files = sys.argv[1:8]
minn = int(minn)
REV, BAND, UNC = ('one-way', 'two-way'), ('low', 'high'), ('low', 'med', 'high')
CAP = {'two-way': 1, 'one-way': 3}
BUDGET = {
    0: ('2', 'corpus (kg-corpus-grep) + no máximo 1 busca web; sem agente'),
    1: ('10', 'comunidades: community-peek.sh (HN, GitHub, Lobsters) + leitura dos achados; ~1 agente, 3-10 chamadas'),
    2: ('run', '/onion-research modo primaries (fontes nomeadas); o custo é o contrato do run'),
    3: ('run', 'varredura com refutação (/onion-research com Elenxo); o custo é o contrato do run'),
}
def die(msg):
    print('peek-census: ' + msg, file=sys.stderr); sys.exit(2)

# ── a tabela: 12 combinações, uma vez cada, nível 0-3, mão dupla <= 1 ──
table, seen = {}, set()
for n, line in enumerate(open(ladder, encoding='utf-8'), 1):
    line = line.rstrip('\n')
    if not line.strip() or line.startswith('#'): continue
    f = line.split('\t')
    if f == ['reversibility', 'severity_band', 'uncertainty', 'level']: continue
    if len(f) != 4: die('tabela linha %d: 4 colunas esperadas' % n)
    r, b, u, lv = f
    if r not in REV or b not in BAND or u not in UNC: die('tabela linha %d: célula desconhecida (%s/%s/%s)' % (n, r, b, u))
    if lv not in ('0', '1', '2', '3'): die('tabela linha %d: nível fora de 0-3 (%s)' % (n, lv))
    if (r, b, u) in seen: die('tabela linha %d: célula repetida (%s/%s/%s)' % (n, r, b, u))
    if int(lv) > CAP[r]: die('tabela linha %d: porta de mão dupla acima do nível 1 (%s/%s/%s=%s): processo de Tipo 1 em decisão de Tipo 2' % (n, r, b, u, lv))
    seen.add((r, b, u)); table[(r, b, u)] = int(lv)
missing = [c for c in [(r, b, u) for r in REV for b in BAND for u in UNC] if c not in table]
if missing: die('tabela incompleta: faltam ' + ', '.join('/'.join(c) for c in missing))
band_of = lambda s: 'high' if s >= 4 else 'low'

if pick:
    r, s, u = pick.split()
    if r not in REV or u not in UNC or s not in ('1', '2', '3', '4', '5'): die('--pick inválido: ' + pick)
    b = band_of(int(s)); lv = table[(r, b, u)]
    if fmt == '--tsv':
        print('pick\t%d\t%s\t%s\t%s\tmax_calls=%s\t%s' % (lv, r, b, u, BUDGET[lv][0], BUDGET[lv][1]))
    else:
        print('**Nível %d** (%s · severidade %s=%s · incerteza %s) — teto de chamadas: %s — %s' % (lv, r, s, b, u, BUDGET[lv][0], BUDGET[lv][1]))
    sys.exit(0)

today = dt.date.fromisoformat(today_s) if today_s else dt.date.today()
peeks, invalid = [], 0
for rel in [x for x in files.split('\n') if x]:
    try:
        doc = yaml.safe_load(open(os.path.join(repo, rel), encoding='utf-8')) or {}
    except Exception as e:
        peeks.append({'ref': rel, 'flags': ['invalid(yaml ilegível: %s)' % type(e).__name__]}); invalid += 1; continue
    for nd in (doc.get('nodes') or []):
        if not isinstance(nd, dict) or 'x_peek_level' not in nd: continue
        p = {'ref': '%s#%s' % (rel, nd.get('id', '?')), 'flags': []}
        bad = []
        lv = nd.get('x_peek_level'); r = nd.get('x_peek_reversibility'); s = nd.get('x_peek_severity')
        u = nd.get('x_peek_uncertainty'); c = nd.get('x_peek_calls'); src = nd.get('x_peek_sources')
        ch = nd.get('x_peek_changed_decision'); va = str(nd.get('verified_at') or '')
        # YAML 1.1 lê yes/no SEM aspas como booleano (achado da bancada, 2026-11-13): normaliza, não reprova
        if ch is True: ch = 'yes'
        elif ch is False: ch = 'no'
        if lv not in (0, 1, 2, 3): bad.append('x_peek_level')
        if r not in REV: bad.append('x_peek_reversibility')
        if s not in (1, 2, 3, 4, 5): bad.append('x_peek_severity')
        if u not in UNC: bad.append('x_peek_uncertainty')
        if not isinstance(c, int) or isinstance(c, bool) or c < 0: bad.append('x_peek_calls')
        if not isinstance(src, list) or not src: bad.append('x_peek_sources')
        if ch not in ('yes', 'no', 'pending'): bad.append('x_peek_changed_decision')
        try: vd = dt.date.fromisoformat(va)
        except ValueError: vd = None; bad.append('verified_at')
        if bad:
            p['flags'].append('invalid(%s)' % ','.join(bad)); invalid += 1; peeks.append(p); continue
        cell = (r, band_of(s), u); want = table[cell]
        p.update(level=lv, cell=cell, pick=want, calls=c, changed=ch)
        if lv != want:
            if not str(nd.get('x_peek_override') or '').strip():
                p['flags'].append('invalid(nível %d difere da tabela %d sem x_peek_override)' % (lv, want)); invalid += 1
            else:
                p['flags'].append('override')
        cap = BUDGET[lv][0]
        if cap.isdigit() and c > int(cap): p['flags'].append('over-budget(%d>%s)' % (c, cap))
        if ch == 'pending' and vd and (today - vd).days > 30: p['flags'].append('pending-old(%dd sem desfecho)' % (today - vd).days)
        peeks.append(p)

# ── a recalibração: por CÉLULA, só com n decidido >= min-n ──
stats = {}
for p in peeks:
    if 'cell' not in p or any(f.startswith('invalid') for f in p['flags']): continue
    st = stats.setdefault(p['cell'], {'n': 0, 'yes': 0, 'no': 0, 'pending': 0})
    st['n'] += 1; st[p['changed']] += 1
props = []
for cell, st in sorted(stats.items()):
    lv, dec = table[cell], st['yes'] + st['no']
    if dec < minn: continue
    if st['yes'] == 0 and lv > 0:
        props.append((cell, lv, lv - 1, '%d espiada(s) decidida(s) neste degrau e nenhuma mudou a decisão: o degrau custa e não rende' % dec))
    elif st['yes'] * 2 >= dec and lv < CAP[cell[0]]:
        props.append((cell, lv, lv + 1, '%d de %d espiada(s) mudaram a decisão: o degrau está raso para a célula' % (st['yes'], dec)))
    elif st['yes'] * 2 >= dec:
        props.append((cell, lv, lv, '%d de %d mudaram a decisão, mas a célula está no teto (%s): fica, e o maestro julga' % (st['yes'], dec, 'mão dupla <= 1' if cell[0] == 'two-way' else 'nível 3')))

ov = ['PEEK_TODAY'] if today_s else []
cs = lambda c: '/'.join(c)
if fmt == '--tsv':
    if ov: print('override\t' + ' '.join(ov))
    for c in sorted(table): print('ladder\t%s\t%s\t%s\t%d' % (c + (table[c],)))
    for lv in range(4): print('budget\t%d\t%s\t%s' % (lv, BUDGET[lv][0], BUDGET[lv][1]))
    for p in peeks:
        print('peek\t%s\t%s\t%s\t%s\t%s\t%s' % (p['ref'], p.get('level', '-'), p.get('pick', '-'), p.get('calls', '-'), p.get('changed', '-'), ','.join(p['flags']) or '-'))
    for c, st in sorted(stats.items()): print('cell\t%s\t%d\tn=%d\tyes=%d\tno=%d\tpending=%d' % (cs(c), table[c], st['n'], st['yes'], st['no'], st['pending']))
    for c, a, b, why in props: print('propose\t%s\t%d\t%d\t%s' % (cs(c), a, b, why))
    print('summary\tpeeks=%d\tinvalid=%d\tproposals=%d\tmin_n=%d' % (len(peeks), invalid, len([x for x in props if x[1] != x[2]]), minn))
else:
    print('# escada da espiada · %d espiada(s) registrada(s) · %d inválida(s) · amostra mínima por célula: %d' % (len(peeks), invalid, minn))
    if ov: print('> override ativo: ' + ' '.join(ov))
    print('\n| nível | teto de chamadas | forma |\n|---|---|---|')
    for lv in range(4): print('| %d | %s | %s |' % (lv, BUDGET[lv][0], BUDGET[lv][1]))
    print('\n| célula (reversibilidade/severidade/incerteza) | nível | espiadas | mudou | não mudou | pendente |\n|---|---|---|---|---|---|')
    for c in sorted(table):
        st = stats.get(c, {'n': 0, 'yes': 0, 'no': 0, 'pending': 0})
        print('| %s | %d | %d | %d | %d | %d |' % (cs(c), table[c], st['n'], st['yes'], st['no'], st['pending']))
    if peeks:
        print('\n**Registro:**')
        for p in peeks: print('- `%s` nível %s (tabela %s) · %s chamada(s) · mudou: %s%s' % (p['ref'], p.get('level', '-'), p.get('pick', '-'), p.get('calls', '-'), p.get('changed', '-'), (' · ⚠️ ' + ', '.join(p['flags'])) if p['flags'] else ''))
    print('\n**Propostas de recalibração** (o maestro edita a tabela; o medidor só propõe):')
    if not props: print('- nenhuma: nenhuma célula tem %d espiada(s) decidida(s) ainda. Sem amostra, a tabela fica como está.' % minn)
    for c, a, b, why in props: print('- `%s`: %d → %d — %s' % (cs(c), a, b, why))
sys.exit(1 if invalid else 0)
PC_PY
