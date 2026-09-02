#!/usr/bin/env bash
# =============================================================================
# kg-census-extract.sh — extrator determinístico do censo populacional do backlog
#
# Propósito : F0 do /meta:census. Lê docs/backlog.md (projeção REGRA 62) + os grafos-fonte e
#             emite os alvos do censo com partição FRESCO/A-MEDIR — KG-SSOT first: o estado de
#             retomada É o carimbo nos grafos (re-rodar extrai só o que ainda não foi medido).
# Uso       : kg-census-extract.sh [--window DIAS=14] [--floor ATENCAO=0] [--format json|summary]
# Exit      : 0 ok · 2 fail-loud (contagem extraída ≠ declarada no backlog — a projeção mentiu
#             ou o parser quebrou; NUNCA seguir medindo população errada).
# Custo     : 0 tokens. A disciplina de custo do censo COMEÇA aqui: window corta o já-medido,
#             floor corta a cauda — a 2ª rodada histórica (2026-09-01) custou 5,39M medindo 72;
#             o default incremental existe para a rodada típica caber em <1M.
# =============================================================================
set -euo pipefail
REPO_ROOT="${ONION_CENSUS_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
WINDOW=14; FLOOR=0; FORMAT=json
while [ $# -gt 0 ]; do
  case "$1" in
    --window) WINDOW="$2"; shift 2;;
    --floor) FLOOR="$2"; shift 2;;
    --format) FORMAT="$2"; shift 2;;
    *) echo "uso: kg-census-extract.sh [--window DIAS] [--floor ATENCAO] [--format json|summary]" >&2; exit 2;;
  esac
done
BACKLOG="${ONION_CENSUS_BACKLOG:-${REPO_ROOT}/docs/backlog.md}"
[ -f "$BACKLOG" ] || { echo "kg-census-extract: backlog ausente: $BACKLOG" >&2; exit 2; }
WINDOW="$WINDOW" FLOOR="$FLOOR" FORMAT="$FORMAT" BACKLOG="$BACKLOG" REPO_ROOT="$REPO_ROOT" python3 - <<'PYEOF'
import re, json, glob, os, sys, datetime
window=int(os.environ['WINDOW']); floor=float(os.environ['FLOOR'])
fmt=os.environ['FORMAT']; backlog=os.environ['BACKLOG']; root=os.environ['REPO_ROOT']
rows=[]
txt=open(backlog).read()
for l in txt.splitlines():
    m=re.match(r'\|\s*([\d.]+)\s*\|\s*`([^`]+)`\s*\|\s*([\w.-]+)\s*\|', l)
    if m: rows.append({'atencao':float(m.group(1)),'id':m.group(2),'grafo':m.group(3)})
md=re.search(r'\*\*(\d+) itens abertos\*\*', txt)
declared=int(md.group(1)) if md else -1
if len(rows)!=declared:
    print(f"kg-census-extract: FAIL-LOUD — extraí {len(rows)} linhas mas o backlog declara {declared} itens. "
          f"Parser quebrado ou projeção mentindo; não se mede população errada.", file=sys.stderr)
    sys.exit(2)
paths={}
for g in glob.glob(root+'/docs/onion/graph/*.kg.yaml')+glob.glob(root+'/docs/evolution/research/*/*.kg.yaml'):
    paths[os.path.basename(g)[:-8]]=g
missing=set(r['grafo'] for r in rows if r['grafo'] not in paths)
if missing:
    print(f"kg-census-extract: FAIL-LOUD — grafos não resolvidos: {sorted(missing)}", file=sys.stderr); sys.exit(2)
def node_block(t,nid):
    i=t.find(f'- id: {nid}\n')
    if i<0: return None
    ends=[x for x in (t.find('\n  - id: ',i+1), t.find('\nedges:',i+1)) if x>0]
    return t[i:min(ends) if ends else len(t)]
cache={}; frescos=[]; medir=[]; testemunho=[]; cortados_floor=0
cutoff=(datetime.date.today()-datetime.timedelta(days=window)).isoformat()
for r in rows:
    p=paths[r['grafo']]
    t=cache.setdefault(p, open(p).read())
    b=node_block(t, r['id'])
    if b is None:
        print(f"kg-census-extract: FAIL-LOUD — nó {r['id']} não achado em {p} (backlog e grafo dessincronizados)", file=sys.stderr); sys.exit(2)
    r['path']=os.path.relpath(p, root)
    va=re.search(r'verified_at:\s*(\S+)', b)
    r['verified_at']=va.group(1) if va else ''
    lab=re.search(r"label:\s*'((?:[^']|'')*)'", b) or re.search(r'label:\s*"([^"]*)"', b)
    r['label']=(lab.group(1) if lab else '')[:300]
    if r['atencao']<floor: cortados_floor+=1; continue
    # TESTEMUNHO (evidence_class: testimony): a fonte é relato — medir é circular. Sai NOMEADO,
    # nunca para a fila de workers (74k tokens/nó para concluir UNVERIFIABLE por construção).
    if re.search(r'^\s*evidence_class:\s*testimony\b', b, re.M): testemunho.append(r); continue
    (frescos if r['verified_at']>=cutoff else medir).append(r)
out={'declarado':declared,'janela_dias':window,'piso_atencao':floor,
     'frescos':frescos,'medir':medir,'testemunho':testemunho,'cortados_pelo_piso':cortados_floor}
if fmt=='summary':
    print(f"censo-extract: {declared} abertos → {len(medir)} A-MEDIR · {len(frescos)} FRESCOS (janela {window}d) · {len(testemunho)} TESTEMUNHO (não-mensuráveis, nomeados) · {cortados_floor} cortados pelo piso {floor} (corte DECLARADO)")
else:
    print(json.dumps(out, ensure_ascii=False))
PYEOF
