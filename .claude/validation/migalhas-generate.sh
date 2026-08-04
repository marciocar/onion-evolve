#!/usr/bin/env bash
# =============================================================================
# migalhas-generate.sh — GERADOR determinístico das Migalhas (fonte → 3 projeções).
#
# ADR: docs/analysis/onion-adr-blog-publication-generator-2026-07.md (D2).
# Doutrina: source-vs-derivation.md ("se a fonte muda, edito em UM lugar").
#
# FONTE   : site/historia/migalhas/posts/*.md  (frontmatter + corpo markdown, Astro-shaped)
# PROJETA : site/historia/migalhas/index.html   (região entre <!-- ONION:GEN posts -->)
#           site/historia/migalhas/provas/index.html  (<!-- ONION:GEN provas -->)
#           site/historia/migalhas/feed.xml      (<!-- ONION:GEN items --> + lastBuildDate)
#
# Substitui SÓ entre os marcadores — todo o chrome (head/CSS/@font-face/nav/hero/footer/JS)
# fica intocado. Guardado pela REGRA 34 do lint (drift = HARD). Skip gracioso sem python3
# (mesmo padrão de federation-console.sh). Curadoria público-segura: nunca emite link de
# PR/commit interno — só o metadado objetivo de `prs`.
#
# Uso : migalhas-generate.sh            → reescreve as 3 superfícies in-place
#       migalhas-generate.sh --check    → NÃO escreve; exit 1 se algo mudaria (o drift-guard)
# =============================================================================
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# MIGALHAS_ROOT: override do repo-raiz (usado pelas fixtures do selftest, que rodam
# num mktemp — sem ele o gerador operaria sempre no site REAL, ignorando a fixture).
# GIT_DIR neutralizado: sob hook do git em worktree o GIT_DIR e ABSOLUTO, e com ele
# setado `git -C <subdir> rev-parse --show-toplevel` devolve o SUBDIR, nao a raiz —
# o script passa a procurar tudo no lugar errado e emite vazio (medido 2026-08-04).
ROOT="${MIGALHAS_ROOT:-$(env -u GIT_DIR -u GIT_WORK_TREE git -C "${HERE}" rev-parse --show-toplevel 2>/dev/null || (cd "${HERE}/../.." && pwd))}"
command -v python3 >/dev/null 2>&1 || { echo "migalhas-generate: python3 ausente (skip gracioso)." >&2; exit 3; }

MODE="${1:-write}"

python3 - "${ROOT}" "${MODE}" <<'PYEOF'
import sys, os, re, glob

ROOT, MODE = sys.argv[1], sys.argv[2]
MIG = os.path.join(ROOT, "site/historia/migalhas")
POSTS = os.path.join(MIG, "posts")

LABEL = {"learning":"Aprendizado","innovation":"Inovação","decision":"Decisão",
         "error":"Erro","observation":"Observação","reflection":"Reflexão"}
MES = ["janeiro","fevereiro","março","abril","maio","junho","julho",
       "agosto","setembro","outubro","novembro","dezembro"]
MES_ABBR = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]
DOW = ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"]   # Sakamoto: índice 0 = DOMINGO

def dias(y,m,d):  # dia-da-semana determinístico (Sakamoto; sem relógio — datetime é bloqueado no harness).
    # Verificado contra os oráculos do feed vivo (2026-07-21=Tue, 07-01=Wed).
    t=[0,3,2,5,0,3,5,1,4,6,2,4]; yy=y-(1 if m<3 else 0)
    return DOW[(yy+yy//4-yy//100+yy//400+t[m-1]+d)%7]

def human(iso):  # 2026-07-21 → "21 de julho de 2026"
    y,m,d=map(int,iso.split("-")); return f"{d} de {MES[m-1]} de {y}"
def rfc822(iso):  # 2026-07-21 → "Tue, 21 Jul 2026 00:00:00 GMT"
    y,m,d=map(int,iso.split("-")); return f"{dias(y,m,d)}, {d:02d} {MES_ABBR[m-1]} {y} 00:00:00 GMT"

def xesc(s): return s.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;")

def md_to_html(md):
    """Inverso do extrator: parágrafos (linha em branco) → <p> concatenados; *x*→<em>; `x`→<code>; [t](u)→<a>."""
    out=[]
    for para in re.split(r'\n\s*\n', md.strip()):
        p=para.strip()
        if not p: continue
        p=xesc(p)
        p=re.sub(r'\*(.+?)\*', r'<em>\1</em>', p)
        p=re.sub(r'`(.+?)`', r'<code>\1</code>', p)
        p=re.sub(r'\[(.+?)\]\((.+?)\)', r'<a href="\2">\1</a>', p)
        out.append(f"<p>{p}</p>")
    return "".join(out)

def parse_post(path):
    txt=open(path,encoding="utf-8").read()
    _,fm,body=txt.split("---",2)
    d={}
    for line in fm.strip().splitlines():
        if line.startswith("  - {"): continue
        m=re.match(r'(\w+):\s*(.*)', line)
        if not m: continue
        k,v=m.group(1),m.group(2).strip()
        if k=="prs": continue           # a lista de prs é montada abaixo (nunca guardar como string)
        if v.startswith('"') and v.endswith('"'): v=v[1:-1].replace('\\"','"').replace('\\\\','\\')
        d[k]=v
    # prs lista
    d.setdefault("prs",[])
    for line in fm.strip().splitlines():
        m=re.match(r'\s*-\s*\{label:\s*"([^"]*)",\s*status:\s*"([^"]*)",\s*meta:\s*"([^"]*)"\}', line)
        if m: d["prs"].append({"label":m.group(1),"status":m.group(2),"meta":m.group(3)})
    # corpo: 3 seções
    def sec(name, nxt):
        m=re.search(rf'##\s*{re.escape(name)}\s*\n(.*?)(?=\n##\s|{nxt}\Z)', body, flags=re.S)
        return m.group(1).strip() if m else ""
    d["descobri"]=sec("O que descobri","")
    d["prova"]=sec("A prova","")
    d["levou"]=sec("Onde isso nos levou","")
    return d

posts=[parse_post(p) for p in glob.glob(f"{POSTS}/*.md")]
posts.sort(key=lambda p:(p["date"],p["slug"]), reverse=True)

def render_article(p):
    slug=p["slug"]; lab=LABEL[p["type"]]
    prova=md_to_html(p["prova"])+f'<a class="pr-link" href="/historia/migalhas/provas/#prova-{slug}">ver a prova →</a>'
    return (f'  <article class="post" id="post-{slug}" data-type="{p["type"]}" data-date="{p["date"]}">\n'
            f'    <div class="post-head">\n'
            f'      <span class="p-type {p["type"]} sans">{lab}</span>\n'
            f'      <span class="p-date">{human(p["date"])}</span>\n'
            f'    </div>\n'
            f'    <h2>{xesc(p["title"])}</h2>\n'
            f'    <h3>O que descobri</h3>\n    {md_to_html(p["descobri"])}\n'
            f'    <h3>A prova</h3>\n    {prova}\n'
            f'    <h3>Onde isso nos levou</h3>\n    {md_to_html(p["levou"])}\n'
            f'    <div class="status sans" data-state="revisao" data-review="{p["review_after"]}" data-review-label="{human(p["review_after"])}">\n'
            f'      <span class="dot" aria-hidden="true"></span>\n'
            f'<span class="status-text">Sob revisão — calculando…</span>\n'
            f'    </div>\n  </article>')

def render_pcard(p):
    lab=LABEL[p["type"]]
    prs=""
    if p["prs"]:
        lis="\n".join(f'      <li><span class="pr-n">{xesc(x["label"])}</span> <span class="pr-merged sans">{x["status"]}</span> <span class="pr-meta">{xesc(x["meta"])}</span></li>' for x in p["prs"])
        prs=f'\n    <ul class="pc-prs">\n{lis}\n    </ul>'
    return (f'  <article class="pcard" id="prova-{p["slug"]}">\n'
            f'    <div class="pc-head"><span class="pc-date sans">{human(p["date"])} · {lab}</span></div>\n'
            f'    <h2>{xesc(p["title"])}</h2>\n'
            f'    <p class="pc-desc">{xesc(p["rss"])}</p>{prs}\n'
            f'  </article>')

def render_item(p):
    url=f'https://onionevolve.com/historia/migalhas/#post-{p["slug"]}'
    return (f'  <item>\n    <title>{xesc(p["title"])}</title>\n'
            f'    <link>{url}</link>\n    <guid>{url}</guid>\n'
            f'    <pubDate>{rfc822(p["date"])}</pubDate>\n'
            f'    <description>{xesc(p["rss"])}</description>\n  </item>')

def splice(path, start, end, block, extra=None):
    txt=open(path,encoding="utf-8").read()
    i=txt.index(start); j=txt.index(end)
    i_nl=txt.index("\n",i)+1
    new=txt[:i_nl]+block+"\n"+txt[j:]
    if extra: new=extra(new)
    return txt, new

changed=False
def apply(path, start, end, block, extra=None):
    global changed
    old,new=splice(path,start,end,block,extra)
    if old!=new:
        changed=True
        if MODE!="--check": open(path,"w",encoding="utf-8").write(new)

# migalhas
apply(f"{MIG}/index.html", "<!-- ONION:GEN posts START", "<!-- ONION:GEN posts END",
      "\n\n".join(render_article(p) for p in posts))
# provas
apply(f"{MIG}/provas/index.html", "<!-- ONION:GEN provas START", "<!-- ONION:GEN provas END",
      "\n\n".join(render_pcard(p) for p in posts))
# feed + lastBuildDate (do post mais novo)
newest=posts[0]["date"]
def bump(t): return re.sub(r'<lastBuildDate>[^<]*</lastBuildDate>', f'<lastBuildDate>{rfc822(newest)}</lastBuildDate>', t, count=1)
apply(f"{MIG}/feed.xml", "<!-- ONION:GEN items START", "<!-- ONION:GEN items END",
      "\n\n".join(render_item(p) for p in posts), extra=bump)

if MODE=="--check":
    if changed: print("migalhas: superfícies DIVERGEM da fonte — regenere.", file=sys.stderr); sys.exit(1)
    print("migalhas: superfícies em sincronia com a fonte."); sys.exit(0)
print(f"migalhas: {len(posts)} posts projetados em 3 superfícies.")
PYEOF
