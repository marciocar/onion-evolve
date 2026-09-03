#!/usr/bin/env bash
# =============================================================================
# instructions-loaded-census.sh — projeção L1 da poda: por arquivo × load_reason, em N sessões
# Lê .claude/sessions/instructions-loaded.jsonl (escrito pelo hook instructions-loaded-log.sh) e imprime:
#   file<TAB>sessions<TAB>session_start<TAB>path_glob_match<TAB>include<TAB>nested_traversal<TAB>compact<TAB>candidata
# candidata = SO-SESSION-START (arquivo com paths:/doutrina de escopo que só entra por session_start) |
#             NUNCA (arquivo com paths: que nunca casou) | - . A decisão de podar é humana e por comportamento (L2).
# Uso: instructions-loaded-census.sh [--log <jsonl>] [--root <repo>] [--json]
# =============================================================================
set -euo pipefail
root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"; log=""; json=0
while [ $# -gt 0 ]; do case "$1" in --log) shift; log="$1" ;; --root) shift; root="$1" ;; --json) json=1 ;; *) echo "arg desconhecido: $1" >&2; exit 2 ;; esac; shift; done
log="${log:-${root}/.claude/sessions/instructions-loaded.jsonl}"
[ -s "${log}" ] || { echo "sem censo: ${log} ausente ou vazio (o hook InstructionsLoaded ainda não registrou nada — sessão nova após registrar o hook)" >&2; exit 3; }
command -v python3 >/dev/null 2>&1 || { echo "python3 ausente" >&2; exit 3; }
LOG="${log}" ROOT="${root}" JSON="${json}" python3 - <<'PY'
import json, os, glob, collections, sys
log=os.environ["LOG"]; root=os.environ["ROOT"]; asjson=os.environ["JSON"]=="1"
reasons=["session_start","path_glob_match","include","nested_traversal","compact"]
per=collections.defaultdict(lambda: {"sessions":set(), **{r:0 for r in reasons}})
for line in open(log, encoding="utf-8"):
    line=line.strip()
    if not line: continue
    try: d=json.loads(line)
    except Exception: continue
    f=d.get("file",""); r=d.get("load_reason","")
    if not f: continue
    per[f]["sessions"].add(d.get("session",""))
    if r in reasons: per[f][r]+=1
# arquivos com paths: no repo (rules e skills) — os que nunca aparecem no censo são candidatos NUNCA
scoped=set()
for p in glob.glob(os.path.join(root,".claude/rules/*.md"))+glob.glob(os.path.join(root,".claude/skills/*/SKILL.md")):
    try: head=open(p,encoding="utf-8").read(4000)
    except Exception: continue
    if "\npaths:" in head or head.startswith("paths:"): scoped.add(os.path.relpath(p,root))
rows=[]
for f,v in sorted(per.items()):
    cand="-"
    if f in scoped and v["path_glob_match"]==0 and v["session_start"]>0: cand="SO-SESSION-START"
    rows.append((f,len(v["sessions"]),*(v[r] for r in reasons),cand))
for f in sorted(scoped - set(per)):
    rows.append((f,0,0,0,0,0,0,"NUNCA"))
if asjson: print(json.dumps([dict(zip(["file","sessions",*reasons,"candidata"],r)) for r in rows],ensure_ascii=False,indent=1))
else:
    print("file\tsessions\t"+"\t".join(reasons)+"\tcandidata")
    for r in rows: print("\t".join(str(x) for x in r))
PY
