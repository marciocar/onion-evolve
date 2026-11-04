#!/usr/bin/env python3
# Reabre a fonte crua de cada citação «…» do grafo (curl ou API do GitHub, sem modelo no meio) e procura o trecho.
# Compara em texto normalizado: sem tags, sem marcação Markdown, espaços colapsados, minúsculas. SO-MARCACAO: só bate
# sem pontuação e espaços (a marcação da página parte a frase). NAO-LITERAL: o trecho não aparece nem assim.
# Uso: quote_check.py <grafo.kg.yaml> > quote-check.tsv     Requer PyYAML, curl e gh autenticado.
import html, re, subprocess, sys, unicodedata, yaml
d = yaml.safe_load(open(sys.argv[1]))
cache = {}
def run(*a):
    return subprocess.run(a, capture_output=True, timeout=90).stdout.decode("utf8", "ignore")
def fetch(u):
    if u in cache: return cache[u]
    m = re.match(r"https://github\.com/([^/]+/[^/]+)/blob/([^/]+)/(.+)", u)
    r = re.match(r"https://github\.com/([^/]+/[^/]+)/?$", u)
    if m:
        t = run("gh", "api", "-H", "Accept: application/vnd.github.raw", f"repos/{m[1]}/contents/{m[3]}?ref={m[2]}"); how = "gh-raw"
    elif r:
        t = run("gh", "api", "-H", "Accept: application/vnd.github.raw", f"repos/{r[1]}/readme"); how = "gh-readme"
    else:
        t = run("curl", "-sSL", "-m", "30", "-A", "Mozilla/5.0", u); how = "curl"
    cache[u] = (t, how); return cache[u]
def norm(s):
    s = re.sub(r"<(script|style)[^>]*>.*?</\1>", " ", s, flags=re.S)
    s = re.sub(r"<[^>]+>", " ", s); s = html.unescape(s)
    s = unicodedata.normalize("NFKC", s).replace("’", "'").replace("`", "").replace("*", "").replace("\\", "")
    s = re.sub(r"\[([^\]]*)\]\([^)]*\)", r"\1", s)
    return re.sub(r"\s+", " ", s).strip().lower()
print("node\tfetch\tbytes\tresult\tquote")
for n in d["nodes"]:
    va = n.get("verified_against") or ""
    q = re.search(r"«(.+?)»", va)
    if not q: continue
    src = (n.get("provenance") or {}).get("source") or n.get("trace") or ""
    t, how = fetch(src)
    a, b = norm(q[1]), norm(t)
    squash = lambda x: re.sub(r"[^0-9a-zà-ÿ]", "", x)
    res = "LITERAL" if a in b else ("SO-MARCACAO" if squash(a) in squash(b) else "NAO-LITERAL")
    print(n["id"], how, len(t), res, q[1][:90], sep="\t")
