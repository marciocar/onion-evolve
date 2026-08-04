#!/usr/bin/env bash
# =============================================================================
# kg-console.sh — projeta um Knowledge Graph SDAAL (.kg.yaml) num CONSOLE RICO
#                 (HTML self-contained, interativo, narrável).
#
# Irmão do federation-console.sh (mesmo padrão F1.3/RFC-0004): PROJEÇÃO read-only
# (CQRS leve) sobre o SSOT que JÁ existe (o .kg.yaml). NÃO é "motor de UI de
# adotante" (isso viola identidade/soberania — ver ADR design-extends-kg): é o
# core visualizando os PRÓPRIOS artefatos, como o console da federação.
# Zero backend, zero DB, zero CDN. Data inlined (base64) → self-contained
# (abre em file://; CSP-safe). O renderer (Cytoscape) é VENDORIZADO inline.
#
# O veredito NÃO é recalculado aqui: o painel embute a saída do kg-radar.sh
# (motor soberano, SSOT das saídas) e o grafo vem do kg-view.sh --json (a lente
# vigiada por --assert-parity) — este script só projeta grafo + veredito em pixels.
#
# CONTRATO DE DADOS (o que viaja na federação é ISTO, não o JS):
#   - grafo:      kg-view.sh --json  (nós ranqueados por atenção; encoding epistêmico)
#   - freshness:  kg-radar.sh --freshness-tsv  (veredito por nó — join, não recomputo)
#   - veredito:   kg-radar.sh  (texto pt-BR embutido)
#   - narração:   <slug>.narration.json  (OPCIONAL, autorada por agente; degrada se ausente)
#
# Uso : kg-console.sh [<arquivo.kg.yaml>]   → HTML (stdout)
#       (sem arg = mais recente de docs/onion/graph/*.kg.yaml)
# Exit: 2 sem arquivo · 3 dependência ausente (kg-view.sh ou vendor) · 0 ok. Determinístico.
# Exercitado por lint-selftest (run_kg_console_selftests).
# =============================================================================
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# GIT_DIR neutralizado: sob hook do git em worktree o GIT_DIR e ABSOLUTO, e com ele
# setado `git -C <subdir> rev-parse --show-toplevel` devolve o SUBDIR, nao a raiz —
# o script passa a procurar tudo no lugar errado e emite vazio (medido 2026-08-04).
ROOT="$(env -u GIT_DIR -u GIT_WORK_TREE git -C "${HERE}" rev-parse --show-toplevel 2>/dev/null || (cd "${HERE}/../.." && pwd))"
VENDOR="${HERE}/vendor/kg-console/cytoscape.min.js"

FILE="${1:-}"
if [ -z "${FILE}" ]; then
  FILE="$(ls -1 "${ROOT}"/docs/onion/graph/*.kg.yaml 2>/dev/null | sort | tail -1 || true)"
fi
[ -n "${FILE}" ] && [ -f "${FILE}" ] || { echo "uso: kg-console.sh [<arquivo.kg.yaml>] (default: mais recente em docs/onion/graph/)" >&2; exit 2; }

# --- dependências (gracioso, exit 3 — mesmo espírito do exit-3 antigo) --------
[ -f "${HERE}/kg-view.sh" ] || { echo "kg-console: kg-view.sh ausente em ${HERE} (exit 3)." >&2; exit 3; }
[ -f "${VENDOR}" ]         || { echo "kg-console: renderer vendorizado ausente (${VENDOR}) — exit 3." >&2; exit 3; }

# --- 1) grafo: a lente vigiada (awk, sem python) ------------------------------
GRAPH_JSON="$(bash "${HERE}/kg-view.sh" "${FILE}" --json 2>/dev/null || true)"
case "${GRAPH_JSON}" in
  '{'*) : ;;
  *) echo "kg-console: kg-view.sh --json não produziu JSON para ${FILE} (exit 3)." >&2; exit 3 ;;
esac

# --- 2) veredito do motor soberano (integridade quebrada NÃO impede a projeção
#        — o console MOSTRA o problema em vez de silenciar) --------------------
RADAR_TEXT="$(bash "${HERE}/kg-radar.sh" "${FILE}" 2>&1 || true)"

# --- 3) freshness: {id: verdict} do radar (JOIN, não recomputo) ---------------
FRESH_JSON="$(bash "${HERE}/kg-radar.sh" "${FILE}" --freshness-tsv 2>/dev/null \
  | awk -F'\t' 'BEGIN{printf "{"; sep=""}
      NF>=11 && $1!="" { id=$1; v=$11; gsub(/"/,"",id); gsub(/"/,"",v);
                         printf "%s\"%s\":\"%s\"", sep, id, v; sep="," }
      END{printf "}"}' 2>/dev/null || true)"
case "${FRESH_JSON}" in '{'*) : ;; *) FRESH_JSON="{}" ;; esac

# --- 4) narração pré-cozida (OPCIONAL) — autorada por agente, só EMBUTIDA aqui -
NARR_FILE="$(dirname "${FILE}")/$(basename "${FILE}" .kg.yaml).narration.json"
if [ -f "${NARR_FILE}" ]; then NARR_JSON="$(cat "${NARR_FILE}")"; else NARR_JSON="null"; fi
case "${NARR_JSON}" in '{'*|null) : ;; *) NARR_JSON="null" ;; esac

# --- Injeção à prova de </script> e de escaping: base64 + decode no cliente ----
b64() { printf '%s' "$1" | base64 | tr -d '\n'; }
KG_B64="$(b64 "${GRAPH_JSON}")"
FRESH_B64="$(b64 "${FRESH_JSON}")"
NARR_B64="$(b64 "${NARR_JSON}")"
VERDICT_B64="$(b64 "${RADAR_TEXT}")"

# =============================================================================
# Emissão do HTML por concatenação em stream (sem replace frágil).
# =============================================================================
cat <<'HTMLHEAD'
<!doctype html><html lang=pt-BR><head><meta charset=utf-8>
<meta name=viewport content="width=device-width,initial-scale=1">
<title>KG Console — Onion</title>
<style>
:root{--bg:#0d1117;--fg:#e6edf3;--mut:#8b949e;--line:#30363d;--card:#161b22;--accent:#1f6feb}
:root[data-theme=light]{--bg:#fff;--fg:#1f2328;--mut:#656d76;--line:#d0d7de;--card:#f6f8fa;--accent:#0969da}
@media(prefers-color-scheme:light){:root:not([data-theme=dark]){--bg:#fff;--fg:#1f2328;--mut:#656d76;--line:#d0d7de;--card:#f6f8fa;--accent:#0969da}}
*{box-sizing:border-box}
html,body{margin:0;height:100%}
body{background:var(--bg);color:var(--fg);font:14px/1.5 -apple-system,Segoe UI,Roboto,sans-serif;overflow:hidden}
#app{display:grid;grid-template-columns:1fr 320px;grid-template-rows:auto 1fr;height:100vh}
header{grid-column:1/3;display:flex;align-items:center;gap:12px;padding:8px 14px;border-bottom:1px solid var(--line);background:var(--card)}
header h1{font-size:15px;margin:0;font-weight:600}header .meta{color:var(--mut);font-size:12px}
header .sp{flex:1}
.btn{border:1px solid var(--line);background:var(--bg);color:var(--fg);border-radius:6px;padding:4px 9px;font-size:12px;cursor:pointer}
.btn:hover{border-color:var(--accent)}.btn.on{background:var(--accent);color:#fff;border-color:var(--accent)}
#stage{position:relative;overflow:hidden;background:radial-gradient(circle at 50% 40%,color-mix(in srgb,var(--accent) 6%,transparent),transparent 70%)}
#cy{position:absolute;inset:0}
#side{border-left:1px solid var(--line);background:var(--card);overflow-y:auto;padding:12px;font-size:13px}
.toolbar{grid-column:1/3;display:none}
.controls{position:absolute;top:10px;left:10px;right:10px;display:flex;flex-wrap:wrap;gap:6px;align-items:center;z-index:5;pointer-events:none}
.controls>*{pointer-events:auto}
#search{border:1px solid var(--line);background:var(--bg);color:var(--fg);border-radius:6px;padding:4px 9px;font-size:12px;width:180px}
.chip{border:1px solid var(--line);background:var(--bg);color:var(--fg);border-radius:999px;padding:2px 10px;font-size:11px;cursor:pointer;opacity:.72}
.chip.on{opacity:1;border-color:var(--accent);box-shadow:0 0 0 1px var(--accent) inset}
.grp{display:flex;flex-wrap:wrap;gap:4px;align-items:center}
.grp .lbl{font-size:10px;color:var(--mut);text-transform:uppercase;letter-spacing:.4px;margin-right:2px}
#fx{position:absolute;inset:0;pointer-events:none;z-index:3}
#minimap{position:absolute;right:10px;bottom:10px;width:168px;height:120px;background:color-mix(in srgb,var(--card) 88%,transparent);border:1px solid var(--line);border-radius:6px;z-index:8;cursor:crosshair;opacity:.92}
#tip{position:absolute;z-index:20;max-width:300px;background:var(--card);border:1px solid var(--line);border-radius:8px;
 padding:9px 11px;font-size:12px;box-shadow:0 6px 24px rgba(0,0,0,.35);pointer-events:none;display:none}
#tip b{font-size:12px}#tip .k{color:var(--mut)}
.sect{margin:0 0 8px;font-size:11px;text-transform:uppercase;letter-spacing:.5px;color:var(--mut);border-bottom:1px solid var(--line);padding-bottom:4px}
#detail{min-height:40px}#detail .id{font-weight:600}#detail .k{color:var(--mut);font-size:12px}
.recon{font-size:12px}.recon .row{padding:4px 6px;border-radius:6px;cursor:pointer;border:1px solid transparent}
.recon .row:hover{border-color:var(--line);background:var(--bg)}
.recon .refutes{color:#f85149}.recon .supersedes{color:#8b949e}
#radar{white-space:pre-wrap;font:11px/1.5 ui-monospace,SFMono-Regular,Menlo,monospace;color:var(--fg);
 max-height:220px;overflow:auto;background:var(--bg);border:1px solid var(--line);border-radius:6px;padding:8px}
#radar .idlink{color:var(--accent);cursor:pointer;text-decoration:underline dotted}
.legend{font-size:11px;color:var(--mut);line-height:1.9}.legend .dot{display:inline-block;width:9px;height:9px;border-radius:50%;margin-right:4px;vertical-align:-1px}
.narr{position:absolute;left:50%;bottom:16px;transform:translateX(-50%);z-index:15;width:min(680px,92%);
 background:var(--card);border:1px solid var(--line);border-radius:10px;padding:10px 14px;box-shadow:0 8px 30px rgba(0,0,0,.4);display:none}
.narr .txt{font-size:13px;margin:0 0 8px}.narr .bar{display:flex;gap:8px;align-items:center;font-size:12px;color:var(--mut)}
.narr .bar .sp{flex:1}
@media(max-width:820px){#app{grid-template-columns:1fr}#side{display:none}}
</style></head><body><div id=app>
<header>
 <h1>🧠 KG Console</h1><span class=meta id=head></span><span class=sp></span>
 <button class=btn id=btnTour>▶ Tour</button>
 <button class=btn id=btnPhysics>Física</button>
 <button class=btn id=btnFx class=on>✨ Fluxo</button>
 <button class=btn id=btnFit>Ajustar</button>
 <button class=btn id=btnTheme>◐</button>
</header>
<div id=stage>
 <div class=controls id=controls></div>
 <div id=cy></div>
 <canvas id=fx></canvas>
 <canvas id=minimap></canvas>
 <div id=tip></div>
 <div class=narr id=narr><p class=txt id=narrTxt></p><div class=bar>
   <span id=narrPos></span><span class=sp></span>
   <button class=btn id=narrPrev>‹ Anterior</button>
   <button class=btn id=narrNext>Próximo ›</button>
   <button class=btn id=narrClose>Fechar</button></div></div>
</div>
<div id=side>
 <div class=sect>Nó selecionado</div><div id=detail><span class=k>(clique num nó — ou toque um foco no Tour)</span></div>
 <div class=sect style="margin-top:16px">Escada de reconciliação</div><div class=recon id=recon></div>
 <div class=sect style="margin-top:16px">Legenda</div><div class=legend id=legend></div>
 <div class=sect style="margin-top:16px">Veredito do radar</div><div id=radar></div>
</div></div>
<script>
HTMLHEAD

# --- renderer vendorizado (inline) --------------------------------------------
cat "${VENDOR}"

# --- dados (base64 → decode no cliente) ---------------------------------------
printf '\n</script>\n<script>\n'
printf 'const _B64={kg:"%s",fresh:"%s",narr:"%s",verdict:"%s"};\n' \
  "${KG_B64}" "${FRESH_B64}" "${NARR_B64}" "${VERDICT_B64}"

# --- app (heredoc quoted — sem expansão de $) ---------------------------------
cat <<'APPJS'
function b64d(s){return new TextDecoder().decode(Uint8Array.from(atob(s),c=>c.charCodeAt(0)))}
const KG        = JSON.parse(b64d(_B64.kg));
const FRESH     = (function(){try{return JSON.parse(b64d(_B64.fresh))}catch(e){return {}}})();
const NARRATION = (function(){try{return JSON.parse(b64d(_B64.narr))}catch(e){return null}})();
const VERDICT   = b64d(_B64.verdict);

// ── paletas epistêmicas ─────────────────────────────────────────────────────
const TYPE_COLOR={entity:'#8957e5',state:'#2da44e',event:'#d29922',rule:'#cf222e',invariant:'#bf3989',policy:'#bf3989',
 claim:'#1f6feb',decision:'#8957e5',question:'#d29922',evidence:'#2da44e',artifact:'#768390'};
const EDGE_COLOR={SUPPORTS:'#2da44e',REFUTES:'#f85149',SUPERSEDES:'#8b949e',DEPENDS_ON:'#58a6ff',
 TRACES_TO:'#a371f7',CAUSES:'#e3922a',HAS_STATE:'#2da44e',TRANSITIONS:'#d29922',EMITS:'#d29922',
 CONSTRAINS:'#cf222e',READS:'#58a6ff',WRITES:'#bf3989'};
const STATUS_BORDER={confirmed:'#2da44e',refuted:'#f85149',superseded:'#6e7681',open:'#8b949e',done:'#484f58'};

const maxW=Math.max(1,...KG.nodes.map(n=>n.w||0));
function nodeSize(w){return 16+46*Math.sqrt((w||0)/maxW)}

// ── elementos ───────────────────────────────────────────────────────────────
const idset=new Set(KG.nodes.map(n=>n.id));
const els=[];
KG.nodes.forEach(n=>{
  const fresh=FRESH[n.id]||'';
  els.push({data:{id:n.id,label:n.id,l:n.l||'',t:n.t,p:n.p,s:n.s,ly:n.ly,w:n.w,d:n.d,
    i:n.i,c:(n.c==null?1:n.c),va:n.va||'',vg:n.vg||'',fresh:fresh,
    sz:nodeSize(n.w),col:TYPE_COLOR[n.t]||'#768390',bcol:STATUS_BORDER[n.s]||'#8b949e',
    op:0.5+0.5*(n.c==null?1:n.c)}});
});
KG.edges.forEach((e,i)=>{
  if(!idset.has(e.f)||!idset.has(e.t))return;
  els.push({data:{id:'e'+i,source:e.f,target:e.t,k:e.k,on:e.on||'',
    ecol:EDGE_COLOR[e.k]||'#6e7681'}});
});

const isDark=()=>document.documentElement.getAttribute('data-theme')==='dark'
  ||(document.documentElement.getAttribute('data-theme')!=='light'&&matchMedia('(prefers-color-scheme:dark)').matches);
const labelCol=()=>isDark()?'#c9d1d9':'#24292f';

const aiSummary=id=>(NARRATION&&NARRATION.node_summaries&&NARRATION.node_summaries[id])||'';

const cy=cytoscape({
  container:document.getElementById('cy'),
  elements:els,
  wheelSensitivity:0.25,
  style:[
    {selector:'node',style:{
      'width':'data(sz)','height':'data(sz)','background-color':'data(col)','background-opacity':'data(op)',
      'border-width':2,'border-color':'data(bcol)','label':'data(label)','color':labelCol(),
      'font-size':9,'text-valign':'bottom','text-margin-y':3,'min-zoomed-font-size':7,
      'text-wrap':'none','text-opacity':0.9}},
    {selector:'node[ly="domain"]',style:{'border-width':4,'border-style':'double'}},
    {selector:'node[s="superseded"]',style:{'border-style':'dashed','background-opacity':0.28}},
    {selector:'node[s="refuted"]',style:{'border-width':3,'border-style':'dashed'}},
    {selector:'node[s="done"]',style:{'border-width':1}},
    // freshness: halo (underlay) âmbar nos nós que MENTEM sem carimbo
    {selector:'node[fresh="STALE-MISSING"],node[fresh="STALE-OLD"],node[fresh="UNANCHORED"],node[fresh="MISPLANED"]',
      style:{'underlay-color':'#d29922','underlay-opacity':0.28,'underlay-padding':6}},
    {selector:'edge',style:{
      'width':1.4,'line-color':'data(ecol)','line-opacity':0.55,'curve-style':'bezier',
      'target-arrow-color':'data(ecol)','target-arrow-shape':'triangle','arrow-scale':0.8}},
    {selector:'edge[k="REFUTES"]',style:{'target-arrow-shape':'tee','width':2,'line-style':'solid'}},
    {selector:'edge[k="SUPERSEDES"]',style:{'line-style':'dashed','target-arrow-shape':'chevron'}},
    {selector:'edge[k="SUPPORTS"]',style:{'width':1.8}},
    // semantic-zoom: rótulo de baixa atenção some ao afastar (vem ANTES de .faded/.hl, que vencem)
    {selector:'node.hideLabel',style:{'text-opacity':0}},
    // foco+contexto
    {selector:'.faded',style:{'opacity':0.09,'text-opacity':0}},
    {selector:'.hl',style:{'opacity':1,'text-opacity':1,'z-index':99}},
    {selector:'node.pulse',style:{'underlay-color':'#1f6feb','underlay-opacity':0.55,'underlay-padding':10}},
    {selector:'node:selected',style:{'border-width':4,'border-color':'#f0c000'}},
    {selector:'.planeDim',style:{'opacity':0.12,'text-opacity':0}}
  ],
  layout:layoutOpts()
});

function layoutOpts(){
  const big=KG.nodes.length>250;
  if(big) return {name:'concentric',concentric:n=>n.data('w'),levelWidth:()=>Math.max(1,maxW/6),
    minNodeSpacing:12,animate:true,animationDuration:700,fit:true,padding:30};
  return {name:'cose',animate:true,animationDuration:900,randomize:true,nodeRepulsion:9000,
    idealEdgeLength:95,edgeElasticity:120,gravity:0.5,numIter:1000,fit:true,padding:40,nodeDimensionsIncludeLabels:false};
}
function runPhysics(){cy.layout({name:'cose',animate:true,animationDuration:900,randomize:false,
  nodeRepulsion:9000,idealEdgeLength:95,edgeElasticity:120,gravity:0.5,numIter:800,fit:true,padding:40}).run();}

// ── header + legend + radar ─────────────────────────────────────────────────
document.getElementById('head').innerHTML=
  KG.graph?('<b>'+esc(KG.graph)+'</b> · '+KG.node_count+' nós · '+KG.edge_count+' arestas · projeção read-only'):'';
document.getElementById('legend').innerHTML=
  Object.entries(TYPE_COLOR).filter(([t])=>KG.nodes.some(n=>n.t===t))
   .map(([t,c])=>'<span class=dot style="background:'+c+'"></span>'+t+'<br>').join('')
  +'<hr style="border:0;border-top:1px solid var(--line);margin:6px 0">'
  +'tamanho ∝ <b>atenção</b> · opacidade ∝ confiança<br>'
  +'borda: <span style="color:#2da44e">confirmed</span> · <span style="color:#f85149">refuted</span> · '
  +'<span style="color:#8b949e">superseded</span><br>contorno duplo = <b>domain</b> · halo âmbar = <b>stale</b><br>'
  +'aresta: <span style="color:#2da44e">SUPPORTS</span> · <span style="color:#f85149">REFUTES⊣</span> · '
  +'<span style="color:#8b949e">SUPERSEDES⇢</span>';

// veredito com ids clicáveis
(function(){
  const el=document.getElementById('radar');
  const html=esc(VERDICT||'(radar sem saída)').replace(/[A-Za-z][A-Za-z0-9_]+/g,
    w=>idset.has(w)?'<span class=idlink data-id="'+w+'">'+w+'</span>':w);
  el.innerHTML=html;
  el.querySelectorAll('.idlink').forEach(s=>s.onclick=()=>focusNode(s.getAttribute('data-id')));
})();

// ── reconciliação (derivada das arestas — Aufhebung visível) ────────────────
(function(){
  const rows=KG.edges.filter(e=>e.k==='REFUTES'||e.k==='SUPERSEDES');
  const box=document.getElementById('recon');
  if(!rows.length){box.innerHTML='<span class=k>(sem REFUTES/SUPERSEDES)</span>';return}
  box.innerHTML=rows.map((e,i)=>{
    const kind=e.k==='REFUTES'?'refutes':'supersedes';const sym=e.k==='REFUTES'?'⊣':'⇢';
    return '<div class=row data-f="'+esc(e.f)+'" data-t="'+esc(e.t)+'"><span class="'+kind+'">'
      +sym+' '+esc(e.k)+'</span><br><span class=k>'+esc(e.f)+' → '+esc(e.t)+'</span></div>';
  }).join('');
  box.querySelectorAll('.row').forEach(r=>r.onclick=()=>{
    const f=r.getAttribute('data-f'),t=r.getAttribute('data-t');
    cy.elements().removeClass('faded hl');
    const sub=cy.$id(f).union(cy.$id(t)).union(cy.$id(f).edgesWith(cy.$id(t)));
    cy.elements().not(sub).addClass('faded');sub.addClass('hl');
    cy.animate({fit:{eles:sub,padding:120}},{duration:500});
    showDetail(f);
  });
})();

// ── interação: hover, click, foco ───────────────────────────────────────────
const tip=document.getElementById('tip');
cy.on('mouseover','node',ev=>{
  const d=ev.target.data();const ai=aiSummary(d.id);
  tip.innerHTML='<b>'+esc(d.id)+'</b> <span class=k>'+esc(d.t)+'</span><br>'
    +(ai?'<span style="color:var(--accent)">🧠 '+esc(ai)+'</span><br>':esc(d.l)+'<br>')
    +'<span class=k>'+esc(d.p)+'/'+esc(d.s)+' · atenção '+(+d.w).toFixed(1)+' · impacto '+d.i+' × conf '+d.c
    +(d.fresh&&d.fresh!=='OK'?' · <span style="color:#d29922">⚠ '+esc(d.fresh)+'</span>':'')+'</span>';
  tip.style.display='block';
});
cy.on('mousemove','node',ev=>{
  const p=ev.renderedPosition||ev.target.renderedPosition();
  tip.style.left=Math.min(p.x+14,innerWidth-320)+'px';tip.style.top=(p.y+14)+'px';
});
cy.on('mouseout','node',()=>tip.style.display='none');
cy.on('tap','node',ev=>focusNode(ev.target.id()));
cy.on('tap',ev=>{if(ev.target===cy){cy.elements().removeClass('faded hl');clearDetail()}});

function focusNode(id){
  const n=cy.$id(id);if(!n||n.empty())return;
  cy.elements().removeClass('faded hl');
  const nb=n.closedNeighborhood();
  cy.elements().not(nb).addClass('faded');nb.addClass('hl');
  cy.animate({fit:{eles:nb,padding:90}},{duration:450});
  n.select();showDetail(id);
}
function showDetail(id){
  const n=cy.$id(id);if(n.empty())return;const d=n.data();
  const inc=n.connectedEdges().map(e=>{const ed=e.data();
    return esc(ed.source)+' —'+esc(ed.k)+(ed.on?'(on '+esc(ed.on)+')':'')+'→ '+esc(ed.target)});
  const ai=aiSummary(id);
  document.getElementById('detail').innerHTML=
    '<span class=id>'+esc(d.id)+'</span> <span class=k>'+esc(d.t)+' · layer:'+esc(d.ly)+'</span><br>'
    +'<span class=k>'+esc(d.p)+'/'+esc(d.s)+' · atenção '+(+d.w).toFixed(1)+' · impacto '+d.i+' × conf '+d.c
    +(d.va?' · verified_at '+esc(d.va):'')+(d.fresh&&d.fresh!=='OK'?' · <b style="color:#d29922">⚠ '+esc(d.fresh)+'</b>':'')+'</span>'
    +(ai?'<p style="margin:6px 0;color:var(--accent)">🧠 '+esc(ai)+'</p>':'')
    +'<p style="margin:6px 0'+(ai?';color:var(--mut);font-size:12px':'')+'">'+esc(d.l)+'</p>'
    +'<span class=k>'+inc.join('<br>')+'</span>';
}
function clearDetail(){document.getElementById('detail').innerHTML='<span class=k>(clique num nó)</span>';cy.$(':selected').unselect();}

// ── busca ────────────────────────────────────────────────────────────────────
const controls=document.getElementById('controls');
const search=document.createElement('input');search.id='search';search.placeholder='buscar id/label…';
search.oninput=()=>{const q=search.value.trim().toLowerCase();
  if(!q){cy.elements().removeClass('faded hl');return}
  const hit=cy.nodes().filter(n=>n.id().toLowerCase().includes(q)||(n.data('l')||'').toLowerCase().includes(q));
  cy.elements().addClass('faded');hit.removeClass('faded').addClass('hl');hit.connectedEdges().removeClass('faded');
  if(hit.length)cy.animate({fit:{eles:hit,padding:80}},{duration:400});};
controls.appendChild(search);

// ── filtros combinados (AND entre grupos, OR dentro) ─────────────────────────
const active={type:new Set(),status:new Set(),plane:new Set(),layer:new Set()};
function facetGroup(key,values,label){
  const g=document.createElement('span');g.className='grp';
  g.innerHTML='<span class=lbl>'+label+'</span>';
  values.forEach(v=>{const c=document.createElement('span');c.className='chip';c.textContent=v;
    c.onclick=()=>{active[key].has(v)?active[key].delete(v):active[key].add(v);c.classList.toggle('on');applyFilters()};
    g.appendChild(c)});
  controls.appendChild(g);
}
facetGroup('type',[...new Set(KG.nodes.map(n=>n.t))].sort(),'tipo');
facetGroup('status',[...new Set(KG.nodes.map(n=>n.s))].sort(),'status');
facetGroup('plane',[...new Set(KG.nodes.map(n=>n.p))].filter(Boolean).sort(),'plano');
function applyFilters(){
  const any=Object.values(active).some(s=>s.size);
  if(!any){cy.nodes().removeClass('faded');cy.edges().removeClass('faded');return}
  cy.nodes().forEach(n=>{
    const ok=(!active.type.size||active.type.has(n.data('t')))
      &&(!active.status.size||active.status.has(n.data('s')))
      &&(!active.plane.size||active.plane.has(n.data('p')))
      &&(!active.layer.size||active.layer.has(n.data('ly')));
    n.toggleClass('faded',!ok);
  });
  cy.edges().forEach(e=>e.toggleClass('faded',e.source().hasClass('faded')||e.target().hasClass('faded')));
}

// ── plano toggle (focus+context: desatura o inativo) ─────────────────────────
let planeFocus=null;
function togglePlane(pl){
  planeFocus=(planeFocus===pl?null:pl);
  cy.nodes().forEach(n=>n.toggleClass('planeDim',!!planeFocus&&n.data('p')!==pl));
  cy.edges().forEach(e=>e.toggleClass('planeDim',!!planeFocus&&(e.source().hasClass('planeDim')||e.target().hasClass('planeDim'))));
  [...document.querySelectorAll('[data-plane]')].forEach(b=>b.classList.toggle('on',b.getAttribute('data-plane')===planeFocus));
}
if(KG.nodes.some(n=>n.p==='PROD')&&KG.nodes.some(n=>n.p==='DEV')){
  const g=document.createElement('span');g.className='grp';g.innerHTML='<span class=lbl>foco</span>';
  ['DEV','PROD'].forEach(pl=>{const b=document.createElement('button');b.className='btn';b.textContent=pl;
    b.setAttribute('data-plane',pl);b.onclick=()=>togglePlane(pl);g.appendChild(b)});
  controls.appendChild(g);
}

// ── glow/pulse nos 3 de maior atenção + nos stale ────────────────────────────
(function(){
  const top=[...KG.nodes].sort((a,b)=>b.w-a.w).slice(0,3).map(n=>n.id);
  top.forEach(id=>cy.$id(id).addClass('pulse'));
})();

// ── narração pré-cozida (ou tour-esqueleto por atenção) ──────────────────────
function buildTour(){
  if(NARRATION&&Array.isArray(NARRATION.guided_tour)&&NARRATION.guided_tour.length) return NARRATION.guided_tour;
  // esqueleto: top-atenção, sem prosa (degradação graciosa)
  return [...KG.nodes].sort((a,b)=>b.w-a.w).slice(0,Math.min(8,KG.nodes.length)).map(n=>({
    focus:[n.id],narration:'Foco: '+n.id+' — '+(n.l||'')+'  (atenção '+(+n.w).toFixed(1)+')'}));
}
let tour=[],tstep=0;
const narrBox=document.getElementById('narr');
function playStep(i){
  if(!tour.length)return;tstep=(i+tour.length)%tour.length;
  const st=tour[tstep];const ids=(st.focus||[]).filter(x=>idset.has(x));
  cy.elements().removeClass('faded hl');
  if(ids.length){let sub=cy.collection();ids.forEach(x=>{sub=sub.union(cy.$id(x).closedNeighborhood())});
    cy.elements().not(sub).addClass('faded');sub.addClass('hl');
    cy.animate({fit:{eles:sub,padding:100}},{duration:600});
    if(ids.length===1)showDetail(ids[0]);}
  document.getElementById('narrTxt').textContent=st.narration||'';
  document.getElementById('narrPos').textContent=(tstep+1)+' / '+tour.length+'  · scroll/setas'
    +(NARRATION?'':'  · tour-esqueleto (sem narração autorada)');
}
function openTour(){tour=buildTour();narrBox.style.display='block';playStep(0);}
document.getElementById('btnTour').onclick=()=>{narrBox.style.display==='block'?closeTour():openTour()};
function closeTour(){narrBox.style.display='none';cy.elements().removeClass('faded hl')}
document.getElementById('narrNext').onclick=()=>playStep(tstep+1);
document.getElementById('narrPrev').onclick=()=>playStep(tstep-1);
document.getElementById('narrClose').onclick=closeTour;

// ── botões globais ───────────────────────────────────────────────────────────
document.getElementById('btnFit').onclick=()=>{cy.elements().removeClass('faded hl');cy.animate({fit:{padding:40}},{duration:400})};
document.getElementById('btnPhysics').onclick=runPhysics;
document.getElementById('btnTheme').onclick=()=>{
  const cur=isDark()?'light':'dark';document.documentElement.setAttribute('data-theme',cur);
  cy.style().selector('node').style('color',labelCol()).update();
};

// ═══ F3 — camada de brilho: partículas · semantic-zoom · minimapa · scrollytelling ═══
const stageEl=document.getElementById('stage');
const dpr=Math.max(1,window.devicePixelRatio||1);

// — partículas: pontos fluem pelas arestas (coords RENDERIZADAS → sincronizam com pan/zoom) —
const fx=document.getElementById('fx'),fxc=fx.getContext('2d');
let fxOn=true;
function sizeFx(){const r=document.getElementById('cy').getBoundingClientRect();
  fx.width=Math.max(1,r.width*dpr);fx.height=Math.max(1,r.height*dpr);
  fx.style.width=r.width+'px';fx.style.height=r.height+'px';fxc.setTransform(dpr,0,0,dpr,0,0);}
const FX_CAP=350;   // acima disso, só arestas em foco (perf no grafo grande)
function fxFrame(ts){
  requestAnimationFrame(fxFrame);
  const w=fx.width/dpr,h=fx.height/dpr;fxc.clearRect(0,0,w,h);
  if(!fxOn)return;
  let eds=cy.edges().filter(e=>e.visible()&&!e.hasClass('faded')&&!e.hasClass('planeDim'));
  if(eds.length>FX_CAP)eds=cy.edges('.hl').filter(e=>!e.hasClass('faded'));
  if(!eds.length)return;
  const ph=(ts%1800)/1800;
  fxc.globalCompositeOperation=isDark()?'lighter':'source-over';
  eds.forEach(e=>{
    const s=e.renderedSourceEndpoint(),t=e.renderedTargetEndpoint(),col=e.data('ecol');
    [ph,(ph+0.5)%1].forEach(p=>{const x=s.x+(t.x-s.x)*p,y=s.y+(t.y-s.y)*p;
      fxc.fillStyle=col;fxc.globalAlpha=0.20;fxc.beginPath();fxc.arc(x,y,5,0,7);fxc.fill();
      fxc.globalAlpha=0.95;fxc.beginPath();fxc.arc(x,y,2,0,7);fxc.fill();});
  });
  fxc.globalAlpha=1;fxc.globalCompositeOperation='source-over';
}
sizeFx();requestAnimationFrame(fxFrame);
document.getElementById('btnFx').onclick=function(){fxOn=!fxOn;this.classList.toggle('on',fxOn);
  if(!fxOn)fxc.clearRect(0,0,fx.width/dpr,fx.height/dpr);};

// — semantic-zoom: rótulo de baixa atenção some ao afastar; reaparece ao aproximar (.hl sempre mostra) —
function semanticZoom(){const show=cy.zoom()>=0.72;
  cy.batch(()=>{cy.nodes().forEach(n=>n.toggleClass('hideLabel',!show&&n.data('w')<maxW*0.5));});}
cy.on('zoom',semanticZoom);semanticZoom();

// — minimapa: overview + retângulo do viewport, clique p/ centralizar —
const mm=document.getElementById('minimap'),mmc=mm.getContext('2d');
mm.width=168*dpr;mm.height=120*dpr;mm.style.width='168px';mm.style.height='120px';mmc.setTransform(dpr,0,0,dpr,0,0);
let mmMap=null;
function drawMinimap(){
  const W=168,H=120,pad=8;mmc.clearRect(0,0,W,H);
  const bb=cy.elements().boundingBox();if(!isFinite(bb.w)||bb.w<=0)return;
  const sc=Math.min((W-2*pad)/bb.w,(H-2*pad)/bb.h),ox=(W-bb.w*sc)/2,oy=(H-bb.h*sc)/2;
  mmMap={sc,ox,oy,x1:bb.x1,y1:bb.y1};
  const mx=x=>ox+(x-bb.x1)*sc,my=y=>oy+(y-bb.y1)*sc;
  cy.edges().forEach(e=>{if(e.hasClass('faded'))return;const s=e.source().position(),t=e.target().position();
    mmc.strokeStyle=e.data('ecol');mmc.globalAlpha=0.3;mmc.beginPath();mmc.moveTo(mx(s.x),my(s.y));mmc.lineTo(mx(t.x),my(t.y));mmc.stroke();});
  mmc.globalAlpha=1;
  cy.nodes().forEach(n=>{if(n.hasClass('faded'))return;const p=n.position();
    mmc.fillStyle=n.data('col');mmc.beginPath();mmc.arc(mx(p.x),my(p.y),1.7,0,7);mmc.fill();});
  const ext=cy.extent();mmc.strokeStyle='#f0c000';mmc.lineWidth=1.2;
  mmc.strokeRect(mx(ext.x1),my(ext.y1),(ext.x2-ext.x1)*sc,(ext.y2-ext.y1)*sc);
}
cy.on('pan zoom dragfree layoutstop',drawMinimap);cy.ready(drawMinimap);
mm.addEventListener('click',ev=>{if(!mmMap)return;const r=mm.getBoundingClientRect();
  const px=mmMap.x1+(ev.clientX-r.left-mmMap.ox)/mmMap.sc,py=mmMap.y1+(ev.clientY-r.top-mmMap.oy)/mmMap.sc;
  const z=cy.zoom(),cont=cy.container().getBoundingClientRect();
  cy.animate({pan:{x:cont.width/2-px*z,y:cont.height/2-py*z}},{duration:300});});
addEventListener('resize',()=>{sizeFx();drawMinimap();});
cy.on('resize',()=>{sizeFx();drawMinimap();});

// — scrollytelling: com o tour aberto, scroll/setas conduzem os passos (o wheel deixa de dar zoom) —
let wheelLock=0;
stageEl.addEventListener('wheel',e=>{
  if(narrBox.style.display!=='block')return;
  e.preventDefault();const now=performance.now();if(now-wheelLock<520)return;wheelLock=now;
  playStep(tstep+(e.deltaY>0?1:-1));},{passive:false});
addEventListener('keydown',e=>{
  if(narrBox.style.display!=='block')return;
  if(e.key==='ArrowRight'||e.key==='ArrowDown'||e.key===' '){playStep(tstep+1);e.preventDefault();}
  else if(e.key==='ArrowLeft'||e.key==='ArrowUp'){playStep(tstep-1);e.preventDefault();}
  else if(e.key==='Escape')closeTour();});

function esc(s){return String(s==null?'':s).replace(/[&<>"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]))}
</script></body></html>
APPJS
