# house_codes.py — acha as siglas da casa SEM GLOSA num texto do assistente.
#
# Carregado por importlib pelo hook house-code-gloss.sh (lembrete no UserPromptSubmit, rede no Stop);
# não roda sozinho. A lista de siglas NÃO mora aqui: vem de .claude/validation/house-codes.tsv (a
# fonte única da glosa). Aqui mora só o "o que conta como glosa" e o "o que não é prosa".
#
# ── O QUE NÃO É PROSA (nunca acusa) ───────────────────────────────────────────────────────────────
#   · bloco de código (```…```) e código em crase (`…`) — o conteúdo da crase fica como CONTEXTO
#     ("a rodada r12 do `/meta:cc-update`" está glosada pelo nome do comando), mas nada dentro dela acusa;
#   · linha de citação (começa com ">"): saída ou fala citada; e URL;
#   · caminho, arquivo ou branch: o pedaço sem espaço que contém a sigla tem "/" ou "." seguido de letra,
#     ou palavra minúscula de 3+ letras colada por "-" ou "/" (docs/radar-E3-r13/x.md, chore/radar-e3-r13).
#     "E3/E4" e "E3-E5" NÃO são caminho: as duas siglas contam;
#   · "REGRA N (Título)": o título de regra é glosa de REGRA — e glosa também o "RN" da mesma resposta.
#
# ── QUANDO A SIGLA CONTA (o DOMÍNIO) ────────────────────────────────────────────────────────────────
#   A coluna `domain` do glossário: a sigla só é a da casa se o domínio aparecer no BLOCO. Sem ele, é
#   palavra comum ou rótulo local ("o teste E3 do formulário", "o r1 do relatório") e cala. E rótulo
#   local numerado (N5, N8 ao lado de N1–N3: a letra com número que o glossário não tem) cala a família.
#
# ── O QUE CONTA COMO GLOSA (glosou num bloco, as menções seguintes do bloco passam) ──────────────────
#   · parêntese logo depois da sigla, com 2+ palavras de 3+ letras que não são siglas: "I3 (um escritor
#     por repo)"; "(ok)" ou "(I3, E3)" não glosam;
#   · " — " ou ": " seguido de 2+ palavras de 3+ letras: "I3: o core nunca commita no repo alheio";
#     "r13: 2.1.302" não glosa;
#   · cópula: "I3 é / significa / quer dizer / isto é / ou seja / diz que / =" (vírgula e "que" opcionais)
#     seguida de 3+ palavras;
#   · o `accept` da linha casando PERTO da sigla (8 palavras para cada lado, na mesma frase).
#
# TETO DECLARADO: o casamento é LÉXICO. Uma glosa errada mas bem formada passa ("r13 (uma coisa
# qualquer)"); texto entre aspas não é isento; rótulo local fora do glossário (A1, T2, M3) passa sempre;
# o accept perto da sigla aceita menção de passagem ("atualizei o Claude Code e a r13 mediu"). Um id de
# nó só conta se existir num .kg.yaml versionado (git ls-files); fora de um repo git, ids de nó calam.
import os
import re
import subprocess

_W3 = r"[A-Za-zÀ-ÿ]{3,}"


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
        if len(cols) < 6 or cols[0] == "kind":
            continue
        kind, code, opacity, gloss, accept, domain = cols[:6]
        try:
            rx = re.compile(r"(?<![\w.`$])(?:%s)(?![\w`]|\.\w)" % code)
            acc = None if accept.strip() in ("", "-") else re.compile(accept, re.I)
            dom = None if domain.strip() in ("", "-") else re.compile(domain, re.I)
        except re.error:
            continue
        rows.append({"kind": kind, "code": code, "opacity": opacity, "gloss": gloss,
                     "rx": rx, "accept": acc, "domain": dom})
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
    """(texto, faixas de código em crase, números de REGRA tituladas). O que não é prosa vira espaço."""
    t = re.sub(r"```.*?```", lambda m: " " * len(m.group(0)), text, flags=re.S)
    t = "\n".join(" " * len(ln) if ln.lstrip().startswith(">") else ln for ln in t.split("\n"))
    t = re.sub(r"https?://\S+", lambda m: " " * len(m.group(0)), t)
    titled = set()

    def _rule(m):
        titled.update(int(n) for n in re.findall(r"\d+", m.group(1)))
        return " " * len(m.group(0))
    t = re.sub(r"\bREGRAS? (\d+(?:\s*[/–,-]\s*\d+)*)\s*\([^()]*(?:\([^()]*\)[^()]*)*\)", _rule, t)
    # ênfase markdown em volta da sigla (_I3_, *I3*) não a esconde
    t = re.sub(r"(?<![\w*])[_*]{1,2}(?=[A-Za-z0-9])|(?<=[A-Za-z0-9])[_*]{1,2}(?![\w*])",
               lambda m: " " * len(m.group(0)), t)
    spans = [(m.start(), m.end()) for m in re.finditer(r"`[^`\n]*`", t)]
    return t, spans, titled


def _chunk(t, start, end):
    a = start
    while a > 0 and not t[a - 1].isspace():
        a -= 1
    b = end
    while b < len(t) and not t[b].isspace():
        b += 1
    return t[a:b].strip("()[]{}.,;:!?\"'«»“”")


def _is_path(chunk):
    if re.search(r"\.[A-Za-z]", chunk) or chunk.count("/") >= 2:
        return True
    return bool(re.search(r"[/-][a-z]{3,}|[a-z]{3,}[/-]", chunk))


def _sentence(t, start, end):
    left = max(t.rfind("\n", 0, start), max(t.rfind(s, 0, start) for s in (". ", "! ", "? ", "; ")))
    rights = [p for p in (t.find("\n", end), t.find(". ", end), t.find("! ", end), t.find("? ", end),
                          t.find("; ", end)) if p != -1]
    right = min(rights) if rights else len(t)
    return t[left + 1:start], t[end:right]


def _words(s, codes_rx):
    return [w for w in re.findall(_W3, s) if not codes_rx.fullmatch(w)]


def _structural(t, start, end, after, codes_rx):
    a = after
    m = re.match(r"\**\s*\(([^()]*)\)", a)
    if m and len(_words(m.group(1), codes_rx)) >= 2:
        return True
    m = re.match(r"\**\s*(?:—|–|:)\**\s+(.*)", a)
    if m and len(_words(" ".join(m.group(1).split()[:8]), codes_rx)) >= 2:
        return True
    m = re.match(r"\**\s*(?:=|,?\s*(?:que\s+)?(?:é|são|era|significa|quer dizer|isto é|ou seja|diz que|diz))\s*,?\s+(.*)",
                 a, re.I)
    if m and len(re.findall(_W3, " ".join(m.group(1).split()[:10]))) >= 3:
        return True
    # dentro de um parêntese que explica: "(texto que explica, SIGLA)"
    op = t.rfind("(", 0, start)
    cl = t.rfind(")", 0, start)
    if op > cl:
        close = t.find(")", end)
        if close != -1 and len(_words(t[op + 1:start] + " " + t[end:close], codes_rx)) >= 2:
            return True
    return False


def _near(before, after, n=8):
    return " ".join(before.split()[-n:]) + " " + " ".join(after.split()[:n])


def _local_families(t, glossary):
    """Letras de rótulo LOCAL: a resposta usa a mesma letra com número que o glossário não tem."""
    known = set()
    for row in glossary:
        if row["kind"] == "static":
            known.update(re.findall(r"^[A-Z]\d+$", row["code"]))
    fams = set()
    for m in re.finditer(r"(?<![\w.`])([A-Z])(\d{1,3})(?![\w`]|\.\w)", t):
        if m.group(0) not in known and any(k[0] == m.group(1) for k in known):
            fams.add(m.group(1))
    return fams


def findings(text, glossary, titles=None, root=None, glossed_out=None, already=()):
    """Lista de {token, row, kind, opacity, gloss} das siglas sem glosa em NENHUMA menção do bloco.
    `already` = siglas glosadas num bloco ANTERIOR do mesmo turno (o maestro já leu a glosa);
    `glossed_out` (set) recebe as siglas que ESTE bloco glosou."""
    t, spans, titled = prose(text)
    fams = _local_families(t, glossary)
    codes_rx = re.compile("|".join("(?:%s)" % r["code"] for r in glossary))
    seen = {}
    for row in glossary:
        if row["domain"] is not None and not row["domain"].search(t):
            continue
        for m in row["rx"].finditer(t):
            if any(a <= m.start() < b for a, b in spans):
                continue
            tok = m.group(0)
            if row["kind"] == "static" and re.match(r"^[A-Z]\d+$", tok) and tok[0] in fams:
                continue
            ch = _chunk(t, m.start(), m.end())
            if ch != tok and _is_path(ch):
                continue
            before, after = _sentence(t, m.start(), m.end())
            ok = _structural(t, m.start(), m.end(), after, codes_rx)
            if not ok and row["kind"] == "rule" and int(tok[1:]) in titled:
                ok = True
            if not ok and row["accept"] is not None:
                ok = bool(row["accept"].search(_near(before, after)))
            d = seen.setdefault(tok, {"token": tok, "row": row["code"], "kind": row["kind"],
                                      "opacity": row["opacity"], "gloss": row["gloss"], "glossed": False})
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
