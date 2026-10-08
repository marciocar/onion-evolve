#!/usr/bin/env python3
"""Amostra estratificada (classe → subclasse proporcional, >=1 por subclasse) + evidência mecânica por item."""
import json, math, random, re, os, subprocess, collections, sys
sys.argv = ["x"]
exec(open("/tmp/prov-triage/classify.py").read().split("def main")[0])

R = json.load(open(f"{HERE}/rows.json"))
random.seed(20261009)
R1={(r['graph'],r['id']) for r in json.load(open(f'{HERE}/sample-r1.json'))}
R=[r for r in R if (r['graph'],r['id']) not in R1]
STOP = set("para com que uma sem por não nao dos das nos nas mas como mais isso este esta onde quando the and of to in is o a e de do da em no na os as ao um é".split())


def words(label):
    return [w for w in re.findall(r"[\wÀ-ú-]{5,}", label.lower()) if w not in STOP]


def support(path, label, nid):
    full = os.path.join(REPO, path)
    if os.path.isdir(full):
        return "dir"
    try:
        t = open(full, encoding="utf-8", errors="replace").read().lower()
    except Exception as e:
        return "ilegível"
    ws = words(label)[:8]
    hit = sum(1 for w in ws if w in t)
    return f"id={'S' if nid.lower() in t else 'n'} termos={hit}/{len(ws)}"


def url_alive(u):
    u = u.rstrip(".,;)")
    r = subprocess.run(["curl", "-s", "-o", "/dev/null", "-L", "-m", "10", "-A", "Mozilla/5.0", "-w", "%{http_code}", u],
                       capture_output=True, text=True)
    return r.stdout.strip() or "ERR"


def evidence(r):
    ev = {}
    src = r["src"] or ""
    m = re.search(r'https?://[^\s"\'<>),;]+', src)
    if m:
        ev["url"] = url_alive(m.group(0))
    repo, ext = paths_in(src)
    if r["sub"].startswith("relativo") and r.get("fix"):
        repo = [r["fix"]]
    if r["sub"].startswith("url-trace-lida"):
        u = src.strip().split()[0]; pr = re.search(r'/pull/(\d+)', u)
        ev["regra"] = "url-no-va" if u in r["va"] else ("pr-gh" if pr and re.search(r'#' + pr.group(1) + r'\b', r["va"]) else "quote")
    if r.get("fix") and r["cls"] == "C":
        fx = [x.split(" → ")[0] for x in str(r["fix"]).split("; ")]
        for x in fx[:2]:
            if exists(x): ev["fix:" + x] = "existe " + support(x, r_label(r), r["id"])
    for p in repo[:2]:
        ev[p] = ("existe " + support(p, r_label(r), r["id"])) if exists(p) else "AUSENTE"
    if ext:
        ev["externo"] = [(p, os.path.exists(p)) for p in ext[:2]]
    return ev


LABELS = {}
def r_label(r):
    k = (r["graph"], r["id"])
    if k not in LABELS:
        for nid, f, _ in nodes_of(r["graph"]):
            LABELS[(r["graph"], nid)] = mig.scalar(f.get("label", "")) or ""
    return LABELS.get(k, "")


by = collections.defaultdict(lambda: collections.defaultdict(list))
for r in R:
    by[r["cls"]][r["sub"]].append(r)
sample = []
for cls, subs in sorted(by.items()):
    tot = sum(len(v) for v in subs.values())
    n = max(10, math.ceil(0.05 * tot))
    alloc = {s: max(1, round(n * len(v) / tot)) for s, v in subs.items()}
    for s, v in subs.items():
        for r in random.sample(v, min(alloc[s], len(v))):
            r["label"] = r_label(r)
            r["ev"] = evidence(r)
            sample.append(r)
json.dump(sample, open(f"{HERE}/sample-r2.json", "w"), ensure_ascii=False, indent=1)
print(collections.Counter(r["cls"] for r in sample))
