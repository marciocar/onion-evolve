#!/usr/bin/env bash
# =============================================================================
# kg-console.sh — projeta um Knowledge Graph SDAAL (.kg.yaml) num CONSOLE estático (HTML self-contained).
#
# Irmão do federation-console.sh (mesmo padrão F1.3/RFC-0004): PROJEÇÃO read-only (CQRS leve) sobre
# o SSOT que JÁ existe (o .kg.yaml). NÃO é "motor de UI de adotante" (isso viola identidade/soberania —
# ver ADR design-extends-kg): é o core visualizando os PRÓPRIOS artefatos, como o console da federação.
# Zero backend, zero DB, zero CDN. Data inlined → self-contained (abre em file://; CSP-safe).
#
# O veredito NÃO é recalculado aqui: o painel embute a saída do kg-radar.sh (motor soberano, SSOT
# das 4 saídas) — este script só projeta grafo + veredito em pixels.
#
# Uso : kg-console.sh [<arquivo.kg.yaml>]   → HTML (stdout)
#       (sem arg = mais recente de docs/onion/graph/*.kg.yaml)
# Gracioso: sem python3+yaml → exit 3. Sem arquivo → exit 2. Determinístico.
# Exercitado por lint-selftest (run_kg_console_selftests).
# =============================================================================
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "${HERE}" rev-parse --show-toplevel 2>/dev/null || (cd "${HERE}/../.." && pwd))"

FILE="${1:-}"
if [ -z "${FILE}" ]; then
  FILE="$(ls -1 "${ROOT}"/docs/onion/graph/*.kg.yaml 2>/dev/null | sort | tail -1 || true)"
fi
[ -n "${FILE}" ] && [ -f "${FILE}" ] || { echo "uso: kg-console.sh [<arquivo.kg.yaml>] (default: mais recente em docs/onion/graph/)" >&2; exit 2; }

command -v python3 >/dev/null 2>&1 && python3 -c 'import yaml' >/dev/null 2>&1 \
  || { echo "kg-console: python3+yaml ausente (exit 3)." >&2; exit 3; }

# Veredito do motor soberano (integridade quebrada não impede a projeção — o console MOSTRA o problema)
RADAR_TEXT="$(bash "${HERE}/kg-radar.sh" "${FILE}" 2>&1 || true)"
export RADAR_TEXT

python3 - "${FILE}" <<'PY'
import sys, json, yaml, os
path = sys.argv[1]
try: doc = yaml.safe_load(open(path)) or {}
except Exception: doc = {}
N = []
for n in (doc.get('nodes') or []):
    if not isinstance(n, dict) or not n.get('id'): continue
    N.append({'id': str(n.get('id')), 'type': str(n.get('node_type') or ''),
              'layer': str(n.get('layer') or 'audit'), 'plane': str(n.get('plane') or ''),
              'status': str(n.get('status') or ''), 'label': str(n.get('label') or ''),
              'impact': n.get('impact') or 0, 'confidence': n.get('confidence') or 0})
E = []
for e in (doc.get('edges') or []):
    if not isinstance(e, dict): continue
    on = e.get('on', e.get(True, ''))  # YAML 1.1: chave crua `on` resolve para bool True
    E.append({'from': str(e.get('from') or ''), 'to': str(e.get('to') or ''),
              'type': str(e.get('edge_type') or ''), 'on': str(on or '')})
meta = doc.get('meta') or {}
data = json.dumps({'file': os.path.basename(path), 'kg': str(meta.get('id') or ''),
                   'date': str(meta.get('date') or ''), 'nodes': N, 'edges': E,
                   'radar': os.environ.get('RADAR_TEXT', '')}, ensure_ascii=False, sort_keys=True)
print("""<!doctype html><html lang=pt-BR><head><meta charset=utf-8>
<meta name=viewport content="width=device-width,initial-scale=1"><title>KG Console — Onion</title>
<style>
:root{--bg:#fff;--fg:#1f2328;--mut:#656d76;--line:#d0d7de;--card:#f6f8fa;--au:#1f6feb;--do:#238636;--warn:#9a6700;--bad:#cf222e}
@media(prefers-color-scheme:dark){:root{--bg:#0d1117;--fg:#e6edf3;--mut:#8b949e;--line:#30363d;--card:#161b22}}
:root[data-theme=dark]{--bg:#0d1117;--fg:#e6edf3;--mut:#8b949e;--line:#30363d;--card:#161b22}
:root[data-theme=light]{--bg:#fff;--fg:#1f2328;--mut:#656d76;--line:#d0d7de;--card:#f6f8fa}
*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--fg);font:15px/1.5 -apple-system,Segoe UI,Roboto,sans-serif}
.wrap{max-width:1100px;margin:0 auto;padding:24px}h1{font-size:22px;margin:0 0 4px}.sub{color:var(--mut);font-size:13px;margin:0 0 16px}
.filters{display:flex;flex-wrap:wrap;gap:6px;margin:12px 0}.chip{border:1px solid var(--line);background:var(--card);color:var(--fg);
border-radius:999px;padding:3px 11px;font-size:12px;cursor:pointer}.chip.on{background:var(--au);color:#fff;border-color:var(--au)}
h2{font-size:15px;border-bottom:1px solid var(--line);padding-bottom:6px;margin:24px 0 12px}
.card{border:1px solid var(--line);border-radius:8px;padding:12px 14px;margin:8px 0;background:var(--card);overflow-x:auto}
svg{display:block;max-width:100%;height:auto}
.n circle{stroke:var(--bg);stroke-width:1.5;cursor:pointer}.n text{font-size:10px;fill:var(--fg)}
.n.dim{opacity:.18}.e{stroke:var(--mut);stroke-opacity:.45;fill:none}.e.hi{stroke:var(--au);stroke-opacity:1;stroke-width:2}
.e.dim{opacity:.08}.el{font-size:8px;fill:var(--mut)}
.legend{display:flex;flex-wrap:wrap;gap:10px;font-size:12px;color:var(--mut);margin:6px 0}
.dot{display:inline-block;width:10px;height:10px;border-radius:50%;margin-right:4px;vertical-align:-1px}
pre{margin:0;font:12px/1.5 ui-monospace,SFMono-Regular,Menlo,monospace;white-space:pre-wrap}
#detail{min-height:44px;font-size:13px}.meta{color:var(--mut);font-size:12px}
</style></head><body><div class=wrap>
<h1>🧠 KG Console</h1>
<p class=sub id=head>Projeção read-only do <code>.kg.yaml</code> — GERADO pelo kg-console.sh, não editar à mão.
Veredito = kg-radar.sh (motor soberano), não recalculado aqui.</p>
<div class=filters id=filters></div>
<div class=legend id=legend></div>
<div class=card><svg id=g></svg></div>
<div class=card id=detail>(clique num nó para ver detalhes e vizinhança)</div>
<h2>Veredito do radar (kg-radar.sh)</h2><div class=card><pre id=radar></pre></div>
</div><script>
const D=__DATA__;
document.getElementById('head').innerHTML='Projeção read-only de <code>'+D.file+'</code>'+(D.kg?' (<b>'+D.kg+'</b>'+(D.date?' · '+D.date:'')+')':'')+' — GERADO pelo kg-console.sh, não editar à mão. Veredito = kg-radar.sh (motor soberano).';
document.getElementById('radar').textContent=D.radar||'(radar sem saída)';
const TYPE_COLOR={entity:'#8957e5',state:'#238636',event:'#d29922',rule:'#cf222e',invariant:'#cf222e',policy:'#bf3989',
 claim:'#1f6feb',decision:'#8957e5',question:'#d29922',evidence:'#2da44e',artifact:'#656d76'};
let filter=null,sel=null;
const nodes=[...D.nodes].sort((a,b)=>(a.layer+a.type+a.id).localeCompare(b.layer+b.type+b.id));
const match=n=>{if(!filter)return true;const[k,v]=filter.split(/:(.*)/);
 if(k==='layer')return n.layer===v;if(k==='type')return n.type===v;if(k==='status')return n.status===v;return true};
function layout(){const vis=nodes.filter(match);const R=Math.max(170,vis.length*13);const cx=R+90,cy=R+40;
 const pos={};vis.forEach((n,i)=>{const a=2*Math.PI*i/Math.max(vis.length,1)-Math.PI/2;
  pos[n.id]={x:cx+R*Math.cos(a),y:cy+R*Math.sin(a)}});return{pos,w:2*cx,h:2*cy+20,vis}}
function adj(id){const s=new Set([id]);D.edges.forEach(e=>{if(e.from===id)s.add(e.to);if(e.to===id)s.add(e.from);if(e.on===id){s.add(e.from);s.add(e.to)}});return s}
function esc(s){return String(s).replace(/[&<>"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]))}
function render(){
 const fl=document.getElementById('filters');fl.innerHTML='';
 const facets=new Set();nodes.forEach(n=>{facets.add('layer:'+n.layer);facets.add('type:'+n.type);facets.add('status:'+n.status)});
 const all=document.createElement('span');all.className='chip'+(filter?'':' on');all.textContent='todos';all.onclick=()=>{filter=null;sel=null;render()};fl.appendChild(all);
 [...facets].sort().forEach(f=>{const c=document.createElement('span');c.className='chip'+(filter===f?' on':'');c.textContent=f;
  c.onclick=()=>{filter=(filter===f?null:f);sel=null;render()};fl.appendChild(c)});
 document.getElementById('legend').innerHTML=Object.entries(TYPE_COLOR).filter(([t])=>nodes.some(n=>n.type===t))
  .map(([t,c])=>'<span><span class=dot style="background:'+c+'"></span>'+t+'</span>').join('')+
  '<span>· contorno duplo = <b>layer:domain</b> · raio ∝ impact</span>';
 const{pos,w,h,vis}=layout();const hi=sel?adj(sel):null;
 let svg='';
 D.edges.forEach(e=>{const a=pos[e.from],b=pos[e.to];if(!a||!b)return;
  const cls='e'+(hi?(hi.has(e.from)&&hi.has(e.to)&&(e.from===sel||e.to===sel||e.on===sel)?' hi':' dim'):'');
  const mx=(a.x+b.x)/2,my=(a.y+b.y)/2;
  svg+='<line class="'+cls+'" x1="'+a.x+'" y1="'+a.y+'" x2="'+b.x+'" y2="'+b.y+'"></line>';
  svg+='<text class=el x="'+mx+'" y="'+(my-2)+'" text-anchor=middle>'+esc(e.type)+(e.on?' on '+esc(e.on):'')+'</text>'});
 vis.forEach(n=>{const p=pos[n.id];const r=5+2.2*(+n.impact||1);const c=TYPE_COLOR[n.type]||'#656d76';
  const cls='n'+(hi&&!hi.has(n.id)?' dim':'');
  svg+='<g class="'+cls+'" data-id="'+esc(n.id)+'"><circle cx="'+p.x+'" cy="'+p.y+'" r="'+r+'" fill="'+c+'"'+
   (n.layer==='domain'?' stroke-dasharray="none" stroke="'+c+'" stroke-width="3" fill-opacity=".55"':'')+'>'+
   '</circle><title>'+esc(n.id)+' — '+esc(n.label)+'</title>'+
   '<text x="'+(p.x+r+3)+'" y="'+(p.y+3)+'">'+esc(n.id)+'</text></g>'});
 const g=document.getElementById('g');g.setAttribute('viewBox','0 0 '+w+' '+h);g.innerHTML=svg;
 g.querySelectorAll('.n').forEach(el=>{el.onclick=()=>{const id=el.getAttribute('data-id');sel=(sel===id?null:id);render()}});
 const d=document.getElementById('detail');
 if(sel){const n=nodes.find(x=>x.id===sel);const ed=D.edges.filter(e=>e.from===sel||e.to===sel||e.on===sel);
  d.innerHTML='<b>'+esc(n.id)+'</b> <span class=meta>'+esc(n.type)+' · layer:'+esc(n.layer)+' · '+esc(n.plane)+'/'+esc(n.status)+
   ' · impact '+esc(n.impact)+' × conf '+esc(n.confidence)+'</span><br>'+esc(n.label)+
   '<br><span class=meta>'+ed.map(e=>esc(e.from)+' —'+esc(e.type)+(e.on?'(on '+esc(e.on)+')':'')+'→ '+esc(e.to)).join(' · ')+'</span>'}
 else d.innerHTML='<span class=meta>(clique num nó para ver detalhes e vizinhança · '+vis.length+'/'+nodes.length+' nós, '+D.edges.length+' arestas)</span>';
}
render();
</script></body></html>""".replace("__DATA__", data))
PY