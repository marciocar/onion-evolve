# house_codes.py — acha as siglas da casa SEM GLOSA num texto do assistente.
#
# Carregado por importlib pelo hook house-code-gloss.sh (lembrete no UserPromptSubmit, rede no Stop);
# não roda sozinho. A lista de siglas NÃO mora aqui: vem de .claude/validation/house-codes.tsv (a
# fonte única da glosa). Aqui mora só o "o que conta como glosa" e o "o que não é prosa".
#
# ── O QUE NÃO É PROSA (nunca acusa) ───────────────────────────────────────────────────────────────
#   · bloco de código (```…```) e código em crase (`…`);
#   · linha de citação (começa com ">"): saída ou fala citada;
#   · URL; e a sigla colada a "/", "." seguido de letra, "-" ou "_" (caminho, arquivo, branch, id composto);
#   · "REGRA N (Título)": o título de regra é glosa de REGRA, não frase do assistente.
#
# ── O QUE CONTA COMO GLOSA (a resposta inteira vale: glosou uma vez, as demais menções passam) ──────
#   · parêntese logo depois da sigla: "I3 (um escritor por repo)";
#   · a sigla dentro de um parêntese que explica algo: "o norte do Onion (NS1)" — o parêntese tem ao
#     menos duas outras palavras, ou vem logo depois de texto;
#   · " — " ou ": " seguido de texto: "I3: o core nunca commita no repo alheio";
#   · o `accept` da linha do glossário casando na MESMA FRASE, com a sigla removida dela.
#
# TETO DECLARADO: o casamento é LÉXICO. Uma glosa errada mas bem formada passa ("r13 (uma coisa)");
# texto entre aspas não é isento; rótulo local de tabela (A1, T2, M3…) não está no glossário e passa
# sempre. Um id de nó só conta se existir num .kg.yaml versionado (git ls-files); fora de um repo
# git, ids de nó não são medidos (calam).
import os
import re
import subprocess

_WORD = r"[A-Za-zÀ-ÿ0-9]"


def load_glossary(path):
    rows = []
    try:
        fh = open(path, encoding="utf-8")
    except Exception:
        return rows
    for line in fh:
        line = line.rstrip("\n")
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        cols = line.split("\t")
        if len(cols) < 5 or cols[0] == "kind":
            continue
        kind, code, opacity, gloss, accept = cols[:5]
        try:
            rx = re.compile(r"(?<![\w/.\-`])(?:%s)(?![\w/\-`]|\.\w)" % code)
            acc = None if accept.strip() in ("", "-") else re.compile(accept, re.I)
        except re.error:
            continue
        rows.append({"kind": kind, "code": code, "opacity": opacity, "gloss": gloss,
                     "rx": rx, "accept": acc})
    return rows


def rule_titles(paths):
    titles = {}
    for src in paths:
        try:
            for line in open(src, encoding="utf-8", errors="replace"):
                m = re.match(r"^# REGRA (\d+) — (.+?)\s*\[(?:HARD|SOFT)[^\]]*\]\s*$", line)
                if m:
                    titles.setdefault(int(m.group(1)), m.group(2).strip())
        except Exception:
            pass
    return titles


_NODE_CACHE = {}


def node_titles(root, ids):
    """{id: título} para os ids que existem num .kg.yaml versionado; ausentes ficam fora."""
    want = [i for i in ids if i not in _NODE_CACHE]
    if want and root:
        try:
            files = subprocess.run(["git", "-C", root, "ls-files", "-z", "*.kg.yaml"],
                                   capture_output=True, timeout=5).stdout.decode("utf-8", "replace")
            files = [f for f in files.split("\0") if f]
        except Exception:
            files = []
        pat = re.compile(r"^\s*-?\s*id:\s*[\"']?(%s)[\"']?\s*$" % "|".join(re.escape(i) for i in want))
        for f in files:
            try:
                lines = open(os.path.join(root, f), encoding="utf-8", errors="replace").read().split("\n")
            except Exception:
                continue
            for k, line in enumerate(lines):
                m = pat.match(line)
                if not m or m.group(1) in _NODE_CACHE:
                    continue
                title = ""
                for nxt in lines[k + 1:k + 12]:
                    t = re.match(r"^\s*(?:title|label|name|claim|statement):\s*[\"']?(.+?)[\"']?\s*$", nxt)
                    if t:
                        title = t.group(1)
                        break
                    if re.match(r"^\s*-\s*id:", nxt):
                        break
                title = title if len(title) <= 100 else title[:97].rstrip() + "…"
                _NODE_CACHE[m.group(1)] = title or "(nó sem título legível)"
        for i in want:
            _NODE_CACHE.setdefault(i, None)
    return {i: _NODE_CACHE.get(i) for i in ids if _NODE_CACHE.get(i) is not None}


def prose(text):
    """(texto, faixas de código em crase). O que não é prosa vira espaço; o código em crase FICA no
    texto (ele é contexto: "a rodada r12 do `/meta:cc-update`" está glosada pelo nome do comando), mas
    nenhuma sigla DENTRO dele é acusada — as faixas devolvidas dizem onde ele está."""
    t = re.sub(r"```.*?```", lambda m: " " * len(m.group(0)), text, flags=re.S)
    t = "\n".join(" " * len(ln) if ln.lstrip().startswith(">") else ln for ln in t.split("\n"))
    t = re.sub(r"https?://\S+", lambda m: " " * len(m.group(0)), t)
    t = re.sub(r"\bREGRAS? \d+(?:\s*[/–,-]\s*\d+)*\s*\([^()]*(?:\([^()]*\)[^()]*)*\)",
               lambda m: " " * len(m.group(0)), t)
    spans = [(m.start(), m.end()) for m in re.finditer(r"`[^`\n]*`", t)]
    return t, spans


def _sentence(t, start, end):
    left = max(t.rfind("\n", 0, start), max(t.rfind(s, 0, start) for s in (". ", "! ", "? ", "; ")))
    rights = [p for p in (t.find("\n", end), t.find(". ", end), t.find("! ", end), t.find("? ", end),
                          t.find("; ", end)) if p != -1]
    right = min(rights) if rights else len(t)
    return t[left + 1:start], t[end:right]


def _structural(t, start, end, before, after):
    a = after
    if re.match(r"\s*\(", a):
        return True
    if re.match(r"\**\s*(?:—|–|:)\**\s+\**%s" % _WORD, a):
        return True
    # dentro de um parêntese que explica: "texto (SIGLA)" ou "(texto, SIGLA)"
    op = t.rfind("(", 0, start)
    cl = t.rfind(")", 0, start)
    if op > cl:
        close = t.find(")", end)
        if close != -1:
            inner = (t[op + 1:start] + " " + t[end:close])
            words = re.findall(r"%s{2,}" % _WORD, inner)
            if len(words) >= 2:
                return True
            if re.search(r"%s{3,}\s*$" % _WORD, t[max(0, op - 40):op]):
                return True
    return False


def _local_families(t, glossary):
    """Prefixos de rótulo LOCAL: a resposta usa a mesma letra com número que o glossário não tem
    (N5, N8, N10 ao lado de N1–N3 = achados numerados do próprio texto, não níveis do dissect)."""
    known = set()
    for row in glossary:
        if row["kind"] == "static":
            known.update(re.findall(r"^[A-Z]\d+$", row["code"]))
    fams = set()
    for m in re.finditer(r"(?<![\w/.\-`])([A-Z])(\d{1,3})(?![\w/\-`]|\.\w)", t):
        tok = m.group(0)
        if tok in known:
            continue
        if any(k[0] == m.group(1) for k in known):
            fams.add(m.group(1))
    return fams


def findings(text, glossary, titles=None, root=None, glossed_out=None, already=()):
    """Lista de {token, kind, opacity, gloss} das siglas sem glosa em NENHUMA menção da resposta.
    `already` = siglas glosadas num bloco ANTERIOR do mesmo turno (o maestro já leu a glosa);
    `glossed_out` (set) recebe as siglas que ESTE bloco glosou."""
    t, spans = prose(text)
    fams = _local_families(t, glossary)
    seen = {}       # token -> dict (com glossed=bool acumulado)
    for row in glossary:
        for m in row["rx"].finditer(t):
            if any(a <= m.start() < b for a, b in spans):
                continue
            tok = m.group(0)
            if row["kind"] == "static" and re.match(r"^[A-Z]\d+$", tok) and tok[0] in fams:
                continue
            before, after = _sentence(t, m.start(), m.end())
            ok = _structural(t, m.start(), m.end(), before, after)
            if not ok and row["accept"] is not None:
                ok = bool(row["accept"].search(before + " " + after))
            d = seen.setdefault(tok, {"token": tok, "row": row["code"], "kind": row["kind"], "opacity": row["opacity"],
                                      "gloss": row["gloss"], "glossed": False})
            d["glossed"] = d["glossed"] or ok
    if glossed_out is not None:
        glossed_out.update(k for k, d in seen.items() if d["glossed"])
    out = [d for d in seen.values() if not d["glossed"] and d["token"] not in already]
    res = []
    nodes = [d["token"] for d in out if d["kind"] == "node"]
    ntitles = node_titles(root, nodes) if nodes else {}
    for d in out:
        if d["kind"] == "rule":       # só número de regra que existe; o título vira a glosa sugerida
            n = int(d["token"][1:])
            if not titles or n not in titles:
                continue
            d["gloss"] = "REGRA %d (%s)" % (n, titles[n])
        elif d["kind"] == "node":     # só id que existe num grafo versionado; o título é a glosa
            if d["token"] not in ntitles:
                continue
            d["gloss"] = ntitles[d["token"]]
        res.append(d)
    res.sort(key=lambda d: d["token"])
    return res
