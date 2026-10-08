#!/usr/bin/env python3
"""Classificador determinístico dos candidatos à provenance (fora do repo, somente leitura) — v3.
Reusa o kg-migrate-v3.py (source_of, NODE_RE, FIELD_RE, scalar) para que o universo seja o MESMO da ferramenta.
v3 = v2 + as 9 curas que a amostra da rodada 1 apontou (ver REPORT.md §4)."""
import importlib.util, json, os, re, sys, collections

REPO = "/home/marcio/onion-evolve"
HERE = "/tmp/prov-triage"
spec = importlib.util.spec_from_file_location("mig", f"{REPO}/.claude/utils/kg/kg-migrate-v3.py")
mig = importlib.util.module_from_spec(spec); spec.loader.exec_module(mig)

# testemunho FORTE: pessoa nomeada decidindo/afirmando, ou sinal de adotante (rodada 1: "sessão"/"adotante" soltos erravam)
TESTEMUNHO = re.compile(r'\b(maestro|selad[oa]|selo\b|formula[çc][ãa]o d|relay|sinal d[oe]|pedido d[oe]|'
                        r'decis[ãa]o d[oe] maestro|aprovou|escolheu|respondeu)', re.I)
MEASURE = re.compile(r'\b(medid|medi[çc]|medi\b|mediu|grep|rodad|executad|wc -l|contad|contagem|reproduz|bancada|selftest|'
                     r'lint|radar|curl|gh |git |leitura|lid[oa]|lendo|abri|conferid|diff|dogfood|sonda|normaliz|censo|'
                     r'mutante|mutation|sandbox|replay|transcript|bateria|rodou|fixture)', re.I)
PR_RE = re.compile(r'(?:PR\s*#|#)(\d{1,4})\b|pull/(\d+)')
SHA_RE = re.compile(r'\b(?=[0-9a-f]*[a-f])(?=[0-9a-f]*[0-9])[0-9a-f]{7,40}\b')   # exige letra E dígito (rodada 1: id de run virava "commit")
GHRUN_RE = re.compile(r'\brun[-_ ]?(\d{9,})\b', re.I)
ABS_RE = re.compile(r'(?<![\w.~-])(/(?:home|etc|var|opt|srv|usr|root|tmp)/[\w.+@-]+(?:/[\w.+@-]*)*)')
TOP_RE = re.compile(r'(?<![\w./-])((?:CLAUDE|README|AGENTS|CHANGELOG)\.md)\b')
WF_RE = re.compile(r'\bwf_[0-9a-f-]{6,}')
URL_RE2 = re.compile(r'https?://\S+|\b[\w-]+(?:\.[\w-]+)*\.(?:com|org|gov|io|ai|dev|net|eu|int)(?:\.br)?(?:/\S*)?', re.I)
FILE_TOKEN = re.compile(r'(?<![\w/.-])([\w.-]+\.(?:sh|md|py|yaml|yml|json|ts|tsx|js|mjs|toml))\b')
POINTER = re.compile(r'^\s*(ver|vide|cf\.?|see|KC\b|F\d|H\d|research\b|relay\b)', re.I)
NO_LOCATOR = re.compile(r'n[ãa]o registrad|sem (url|locator|localizador)|locator ausente', re.I)
PERSONAL_GRAPHS = {"docs/discussions/onion-pessoal-marcio/proto/marcio.kg.yaml"}
DEFINITIONAL_TYPES = {"state"}
STOP = set("para com que uma sem por não nao dos das nos nas mas como mais isso este esta onde quando the and of to in is".split())


def clean_path(s):
    s = s.strip().strip('`').split('#')[0]
    s = re.sub(r':[\w,-]+$', '', s)
    s = re.sub(r'@[0-9a-f]{6,40}$', '', s)
    return s.rstrip('/.,;:')


_exists_cache = {}
def exists(p):
    if p not in _exists_cache:
        _exists_cache[p] = os.path.exists(os.path.join(REPO, p))
    return _exists_cache[p]


RENAMES = {}
for ln in open(f"{HERE}/renames.txt"):
    parts = ln.rstrip("\n").split("\t")
    if len(parts) == 3 and parts[1] not in RENAMES:
        RENAMES[parts[1]] = parts[2]
DELETED = set(open(f"{HERE}/deleted.txt").read().split("\n"))
BASENAME = collections.defaultdict(list)
for ln in open(f"{HERE}/basenames.tsv"):
    b, p = ln.rstrip("\n").split("\t", 1)
    BASENAME[b].append(p)


def renamed_to(p):
    seen, cur = set(), p
    while cur in RENAMES and cur not in seen:
        seen.add(cur); cur = RENAMES[cur]
    if cur != p:
        return ("rename→" + cur) if exists(cur) else ("rename→" + cur + " (também sumiu)")
    if p in DELETED:
        return "apagado no histórico"
    return "nunca existiu no repo (truncado/errado)"


def paths_in(text):
    repo, ext = [], []
    for m in ABS_RE.finditer(text):
        p = m.group(1)
        if p.startswith(REPO + "/"):
            repo.append(clean_path(p[len(REPO) + 1:]))
        else:
            ext.append(p)
    for m in mig.PATH_RE.finditer(text):
        repo.append(clean_path(m.group(1)))
    for m in TOP_RE.finditer(text):
        repo.append(m.group(1))
    return list(dict.fromkeys(p for p in repo if p)), ext


def resolve_loose(src, gdir):
    """Token sem prefixo conhecido: (caminho, via) — via 'grafo' (relativo ao dir do grafo: precisa correção) ou 'raiz'."""
    tok = src.strip().split()[0] if src.strip() else ""
    tok = clean_path(tok)
    if not tok or "://" in tok or tok.startswith("/"):
        return None, None
    if gdir and exists(os.path.normpath(os.path.join(gdir, tok))) and not exists(tok):
        return os.path.normpath(os.path.join(gdir, tok)), "grafo"
    if exists(tok) and "/" in tok:
        return tok, "raiz"
    return None, None


def file_tokens(text):
    """Nomes de arquivo sem caminho (ex.: constellation-map.sh) resolvidos por basename ÚNICO no repo."""
    out = []
    for m in FILE_TOKEN.finditer(text):
        hits = BASENAME.get(m.group(1), [])
        if len(hits) == 1:
            out.append(hits[0])
    return list(dict.fromkeys(out))


def label_support(path, label):
    full = os.path.join(REPO, path)
    if os.path.isdir(full):
        return None
    try:
        t = open(full, encoding="utf-8", errors="replace").read().lower()
    except Exception:
        return None
    ws = [w for w in re.findall(r"[\wÀ-ú-]{5,}", label.lower()) if w not in STOP][:8]
    return (sum(1 for w in ws if w in t), len(ws)) if ws else None


def judge_source(src, va, from_va_how, gdir, graph, label, nid):
    if from_va_how == "URL citada no verified_against":
        return "A1", "url-no-va", "URL citada no registro do que foi medido", None
    if re.match(r'^\s*https?://', src):
        u = src.strip().split()[0]
        pr = re.search(r'/pull/(\d+)', u)
        if u in va or (pr and re.search(r'#' + pr.group(1) + r'\b', va)) or re.search(r'QUOTE|verbatim|"[^"]{20,}"', va):
            return "A1", "url-trace-lida", "trace é URL e o registro mostra que foi ela a lida (cita, PR #N via gh, ou quote)", None
        return "A2", "url-trace", "trace é URL: o artefato de que o nó fala, não necessariamente o lido", None
    if NO_LOCATOR.search(src):
        return "R", "sem-localizador-declarado", "a própria fonte declara que o localizador não foi registrado", None
    repo, ext = paths_in(src)
    loose, via = (None, None) if repo else resolve_loose(src, gdir)
    if loose and via == "grafo":
        return "C", "relativo", "caminho relativo ao dir do grafo: o source deve ser o caminho do repo", loose
    if loose:
        repo = [loose]
    if repo:
        missing = [p for p in repo if not exists(p)]
        if missing:
            return "C", "caminho-sumiu", "caminho citado não existe mais", \
                   "; ".join(p + " → " + renamed_to(p) for p in missing[:3])
        if graph in repo:
            others = [x for x in re.findall(r'\b([A-Z][A-Z0-9]*_[A-Za-z0-9_]{3,})\b', va) if x != nid]
            if others:
                return "A1", "censo-no-auditado", "fonte é o grafo do nó auditado (o registro cita o id dele)", None
            return "C", "grafo-proprio", "o nó cita o PRÓPRIO grafo como fonte (circular): reescrever para o dado lido", None
        if from_va_how or any(p in va or os.path.basename(p) in va for p in repo):
            return "A1", "caminho-lido", "arquivo existe e o registro da medição o cita", None
        sup = label_support(repo[0], label)
        if sup and sup[1] >= 4 and sup[0] / sup[1] < 0.3:
            return "C", "suporte-fraco", f"o arquivo existe mas não sustenta o label ({sup[0]}/{sup[1]} termos): fonte provavelmente errada", None
        return "A2", "caminho-trace", "trace existe, mas é o artefato de que o nó fala, não necessariamente o lido", None
    if ext:
        return "A2", "fora-do-repo", "fonte em caminho fora do repo (host/outro repo): a CI não alcança", None
    if WF_RE.search(src):
        return "A2", "run-local", "fonte é journal de run local (wf_*), fora do repo", None
    if POINTER.search(src) or len(src.strip()) < 16:
        if re.match(r'^\s*relay\b', src, re.I):
            return "T", "sinal-adotante", "trace aponta para sinal de adotante (relay)", None
        return "C", "aponta-no", "trace aponta para outro nó/seção/doc, não para uma fonte", None
    if URL_RE2.search(src):
        return "A2", "url-no-meio", "trace cita URL/domínio no meio do texto", None
    return "A2", "citacao-texto", "trace é citação textual (literatura, lei, produto) sem localizador resolvível", None


def nodes_of(path):
    text = open(os.path.join(REPO, path), encoding="utf-8").read()
    lines = text.split("\n")
    in_nodes, i, res = False, 0, []
    while i < len(lines):
        ln = lines[i]
        if re.match(r'^nodes:\s*(#.*)?$', ln): in_nodes = True
        elif re.match(r'^[A-Za-z_]', ln): in_nodes = False
        m = mig.NODE_RE.match(ln) if in_nodes else None
        if not m: i += 1; continue
        nid, j = m.group(1), i + 1
        while j < len(lines) and (lines[j].startswith("    ") or not lines[j].strip() or lines[j].lstrip().startswith("#")) \
                and not mig.NODE_RE.match(lines[j]):
            j += 1
        fields = {}
        for b in lines[i + 1:j]:
            fm = mig.FIELD_RE.match(b)
            if fm: fields[fm.group(1)] = fm.group(2)
        res.append((nid, fields, i + 1)); i = j
    return res


def classify(fields, graph, nid):
    status, plane = mig.scalar(fields.get("status", "")), mig.scalar(fields.get("plane", ""))
    if not ((status == "confirmed" or plane == "PROD") and "provenance" not in fields):
        return None
    gdir = os.path.dirname(graph)
    va = mig.scalar(fields.get("verified_against", "")) or ""
    trace = mig.scalar(fields.get("trace", "")) or ""
    label = mig.scalar(fields.get("label", "")) or ""
    src, how = mig.source_of(fields)
    ntype = mig.scalar(fields.get("node_type", "")) or "?"
    d = {"status": status, "plane": plane, "node_type": ntype, "va": va, "trace": trace, "label": label, "src": src,
         "how": how, "tool": "derivavel" if (src and va) else "sem-fonte", "fix": None}
    if src:
        cls, sub, why, fix = judge_source(src, va, None if how == "trace do nó" else how, gdir, graph, label, nid)
        if not va:
            sub += "+sem-va"; why += " — sem verified_against (a ferramenta não deriva: falta o locator)"
            if cls == "A1": cls = "A2"
        d.update(cls=cls, sub=sub, why=why, fix=fix); return d
    # ---- sem fonte derivável pela ferramenta ----
    if graph in PERSONAL_GRAPHS:
        d.update(cls="T", sub="grafo-pessoal", why="grafo pessoal do maestro: o nó é testemunho dele"); return d
    blob = va + " " + label
    url = re.search(r'https?://[^\s"\'<>),;]+', label)
    files = [p for p in file_tokens(blob) if p != graph]
    if url:
        d.update(cls="C", sub="url-no-label", why="a URL da fonte está no label, não no verified_against", fix=url.group(0)); return d
    if files and va:
        d.update(cls="C", sub="arquivo-sem-prefixo", why="o registro cita arquivo do repo sem caminho (resolvido por basename único)",
                 fix="; ".join(files[:3])); return d
    if ntype in DEFINITIONAL_TYPES:
        d.update(cls="U", sub="definicional", why="nó definicional (estado/enum do modelo): não é fato medido"); return d
    if not va:
        d.update(cls="U", sub="vazio", why="sem verified_against nem trace"); return d
    pr, sha, ghrun, wf = PR_RE.search(va), SHA_RE.search(va), GHRUN_RE.search(va), WF_RE.search(va)
    t, meas = TESTEMUNHO.search(va), MEASURE.search(va)
    if wf:
        d.update(cls="A2", sub="run-local-va", why="o registro cita o run wf_* (journal local, fora do repo) como o lido", fix=wf.group(0))
    elif pr or sha:
        d.update(cls="C", sub="pr-commit", why="cita PR/commit resolvível como fonte",
                 fix=("PR #" + (pr.group(1) or pr.group(2))) if pr else ("commit " + sha.group(0)))
    elif ghrun:
        d.update(cls="C", sub="gh-run", why="cita run do GitHub Actions (resolvível por gh run view; log expira em 90 d)", fix="run " + ghrun.group(1))
    elif t:
        d.update(cls="T", sub="testemunho", why="registro de decisão/selo/sinal de pessoa nomeada")
    elif meas:
        d.update(cls="R", sub="medicao-sem-fonte", why="descreve medição de sessão mas não cita o que foi lido")
    else:
        d.update(cls="U", sub="prosa", why="sem fonte recuperável e sem testemunho")
    return d


def main():
    rows = []
    for path in open(f"{HERE}/corpus.txt").read().split():
        try:
            for nid, fields, line in nodes_of(path):
                d = classify(fields, path, nid)
                if d: d.update(graph=path, id=nid, line=line); rows.append(d)
        except Exception as e:
            print("ERRO", path, repr(e), file=sys.stderr)
    json.dump(rows, open(f"{HERE}/rows.json", "w"), ensure_ascii=False, indent=0)
    print("total", len(rows), dict(sorted(collections.Counter(r["cls"] for r in rows).items())))
    print("ferramenta:", dict(collections.Counter(r["tool"] for r in rows)))
    for k, v in sorted(collections.Counter((r["cls"], r["sub"], r["tool"]) for r in rows).items()):
        print(" ", k, v)


if __name__ == "__main__":
    main()
