#!/usr/bin/env bash
# =============================================================================
# federation-console.sh — projeta o SSOT da federação num CONSOLE estático (HTML self-contained).
#
# F1.3 do roadmap de federação (RFC-0004), P0-3: "falta lugar p/ VER comunicações, histórico e relações".
# NAO e' plataforma (Backstage/Port = over-engineering p/ N pequeno — pesquisa S3·F1). E' uma PROJEÇÃO
# read-only (CQRS leve) sobre o event-log que JA existe: members.yaml (relações) + CHANGELOG append-only
# (comunicações). Zero backend, zero DB. Servível pelo Caddy que já roda na VPS (console.onionevolve.com).
# Data inlined → self-contained (abre em file:// ou file_server; sem CDN, sem fetch, CSP-safe).
#
# Uso : federation-console.sh            → HTML (stdout) → docs/onion/federation-console.html
# Reusa: members.yaml (SSOT) + CHANGELOG.md. Filtro por tier/mode/specialization = o fix F1.2 VISUALIZADO.
# Gracioso: sem python+yaml → exit 3. Determinístico. Exercitado por lint-selftest (run_federation_console_selftests).
# =============================================================================
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# GIT_DIR neutralizado: sob hook do git em worktree o GIT_DIR e ABSOLUTO, e com ele
# setado `git -C <subdir> rev-parse --show-toplevel` devolve o SUBDIR, nao a raiz —
# o script passa a procurar tudo no lugar errado e emite vazio (medido 2026-08-04).
ROOT="$(env -u GIT_DIR -u GIT_WORK_TREE git -C "${HERE}" rev-parse --show-toplevel 2>/dev/null || (cd "${HERE}/../.." && pwd))"
command -v python3 >/dev/null 2>&1 && python3 -c 'import yaml' >/dev/null 2>&1 \
  || { echo "federation-console: python3+yaml ausente (exit 3)." >&2; exit 3; }

python3 - "${ROOT}/docs/evolution/federation/members.yaml" "${ROOT}/docs/evolution/federation/CHANGELOG.md" <<'PY'
import sys, json, yaml, re, html
mpath, cpath = sys.argv[1], sys.argv[2]
try: members = (yaml.safe_load(open(mpath)) or {}).get('members') or []
except Exception: members = []
# projeta membros
M = []
for m in members:
    if not m.get('id'): continue
    t = m.get('trust') or {}
    M.append({
        # Superfície PÚBLICA: só o nome curto — o parêntese do name: no members.yaml é anotação
        # interna do maestro (incl. marcador de confidencialidade) e NUNCA entra na projeção
        # (regra 2026-07-09; incidente 2026-07-10: o console público vazou nome comercial +
        # marcador verbatim).
        # Este split é o SANITIZADOR. O VERIFICADOR que o cobre é
        # .claude/validation/projection-safety.sh (REGRA 30 do lint), que audita a SAÍDA deste
        # script — se o split falhar ou alguém projetar por outro caminho, o lint reprova.
        # Promovido de convenção local a guarda compartilhada em 2026-07-21.
        'id': m.get('id'), 'name': (m.get('name') or '').split(' (')[0], 'tier': m.get('role','member'),
        'mode': m.get('mode',''), 'parent': m.get('parent',''), 'pin': m.get('onion_version',''),
        'specializations': m.get('specializations') or [],
        'corrects': (t.get('can_correct_to') or []),
    })
# projeta timeline do CHANGELOG (## <data> · <assunto> · <COMPAT> · alvo: <x>)
T = []
if __import__('os').path.exists(cpath):
    for line in open(cpath):
        line = line.rstrip('\n')
        if not line.startswith('## '): continue
        parts = [p.strip() for p in line[3:].split(' · ')]
        date = parts[0] if parts else ''
        alvo = next((p[len('alvo:'):].strip() for p in parts if p.lower().startswith('alvo:')), '')
        compat = next((p for p in parts if p in ('COMPATÍVEL','BREAKING','INITIAL')), '')
        subj = ' · '.join(p for p in parts[1:] if p != compat and not p.lower().startswith('alvo:'))
        T.append({'date': date, 'subject': subj, 'compat': compat, 'alvo': alvo})
# ordem reversa cronológica (mais recente primeiro) — estável
T = sorted(T, key=lambda e: e['date'], reverse=True)

data = json.dumps({'members': M, 'timeline': T}, ensure_ascii=False, sort_keys=True)
print("""<!doctype html><html lang=pt-BR><head><meta charset=utf-8>
<meta name=viewport content="width=device-width,initial-scale=1"><title>Console da Federação Onion</title>
<style>
:root{--bg:#fff;--fg:#1f2328;--mut:#656d76;--line:#d0d7de;--card:#f6f8fa;--src:#1f6feb;--hub:#238636;--sa:#8957e5}
@media(prefers-color-scheme:dark){:root{--bg:#0d1117;--fg:#e6edf3;--mut:#8b949e;--line:#30363d;--card:#161b22}}
:root[data-theme=dark]{--bg:#0d1117;--fg:#e6edf3;--mut:#8b949e;--line:#30363d;--card:#161b22}
:root[data-theme=light]{--bg:#fff;--fg:#1f2328;--mut:#656d76;--line:#d0d7de;--card:#f6f8fa}
*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--fg);font:15px/1.5 -apple-system,Segoe UI,Roboto,sans-serif}
.wrap{max-width:960px;margin:0 auto;padding:24px}h1{font-size:22px;margin:0 0 4px}.sub{color:var(--mut);font-size:13px;margin:0 0 20px}
.filters{display:flex;flex-wrap:wrap;gap:6px;margin:14px 0}.chip{border:1px solid var(--line);background:var(--card);color:var(--fg);
border-radius:999px;padding:3px 11px;font-size:12px;cursor:pointer}.chip.on{background:var(--src);color:#fff;border-color:var(--src)}
h2{font-size:15px;border-bottom:1px solid var(--line);padding-bottom:6px;margin:28px 0 12px}
.card{border:1px solid var(--line);border-radius:8px;padding:12px 14px;margin:8px 0;background:var(--card)}
.card h3{margin:0 0 4px;font-size:15px}.badge{display:inline-block;border-radius:5px;padding:1px 7px;font-size:11px;color:#fff;margin-right:5px}
.t-source{background:var(--src)}.t-hub{background:var(--hub)}.t-standalone{background:var(--sa)}.t-member{background:var(--mut)}
.tag{display:inline-block;border:1px solid var(--line);border-radius:5px;padding:0 6px;font-size:11px;color:var(--mut);margin:2px 4px 2px 0}
.meta{color:var(--mut);font-size:12px}.tl{border-left:2px solid var(--line);padding-left:14px}
.ev{margin:0 0 12px}.ev .d{color:var(--mut);font-size:12px}.ev .s{font-size:14px}.hidden{display:none}
.bk{background:#cf222e}.co{background:var(--hub)}a{color:var(--src)}
</style></head><body><div class=wrap>
<h1>🧅 Console da Federação Onion</h1>
<p class=sub>Projeção read-only do SSOT (<code>members.yaml</code> + <code>CHANGELOG</code>) — GERADO, não editar à mão.
Mapa visual: <a href="federation-map.md">federation-map.md</a>.</p>
<div class=filters id=filters></div>
<h2>Membros <span class=meta id=mcount></span></h2><div id=members></div>
<h2>Comunicações (histórico) <span class=meta id=tcount></span></h2><div class=tl id=timeline></div>
</div><script>
const D=__DATA__;
const tierClass=t=>'t-'+(['source','hub','standalone'].includes(t)?t:'member');
let filter=null;
const facets=()=>{const s=new Set();D.members.forEach(m=>{s.add('tier:'+m.tier);if(m.mode)s.add('mode:'+m.mode);(m.specializations||[]).forEach(x=>s.add('spec:'+x))});return[...s].sort()};
function match(m){if(!filter)return true;const[k,v]=filter.split(/:(.*)/);
 if(k==='tier')return m.tier===v;if(k==='mode')return m.mode===v;if(k==='spec')return (m.specializations||[]).includes(v);return true}
function render(){
 const fl=document.getElementById('filters');fl.innerHTML='';
 const all=document.createElement('span');all.className='chip'+(filter?'':' on');all.textContent='todos';all.onclick=()=>{filter=null;render()};fl.appendChild(all);
 facets().forEach(f=>{const c=document.createElement('span');c.className='chip'+(filter===f?' on':'');c.textContent=f;c.onclick=()=>{filter=(filter===f?null:f);render()};fl.appendChild(c)});
 const mv=D.members.filter(match);document.getElementById('mcount').textContent='('+mv.length+'/'+D.members.length+')';
 document.getElementById('members').innerHTML=mv.map(m=>`<div class=card><h3><span class="badge ${tierClass(m.tier)}">${m.tier}</span>${m.id}</h3>
  <div class=meta>${m.name||''}${m.mode?' · '+m.mode:''}${m.parent?' · ↑ '+m.parent:''}${m.pin?' · <code>'+m.pin+'</code>':''}${m.corrects.length?' · pode-corrigir → '+m.corrects.join(', '):''}</div>
  <div>${(m.specializations||[]).map(s=>'<span class=tag>'+s+'</span>').join('')}</div></div>`).join('')||'<p class=meta>(nenhum membro casa o filtro)</p>';
 // timeline: se filtro tier/mode/spec, destaca eventos cujo alvo casa algum membro visível (ou 'todos'/'adotantes')
 const vis=new Set(mv.map(m=>m.id));
 const evVisible=e=>{if(!filter)return true;const a=(e.alvo||'').toLowerCase();if(a.startsWith('todos')||a.startsWith('adotante'))return true;return[...vis].some(id=>a.includes(id))};
 const tv=D.timeline.filter(evVisible);document.getElementById('tcount').textContent='('+tv.length+'/'+D.timeline.length+')';
 document.getElementById('timeline').innerHTML=tv.map(e=>`<div class=ev><div class=d>${e.date}${e.compat?' · <span class="badge '+(e.compat==='BREAKING'?'bk':'co')+'">'+e.compat+'</span>':''}${e.alvo?' · alvo: '+e.alvo:''}</div><div class=s>${e.subject}</div></div>`).join('')||'<p class=meta>(sem comunicações p/ este filtro)</p>';
}
render();
</script></body></html>""".replace("__DATA__", data))
PY
