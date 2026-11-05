#!/usr/bin/env bash
# =============================================================================
# python-isolated-check.sh — REGRA 115: hooks e o que eles executam rodam python em modo isolado (-I)
#
# O QUE   : toda invocação de python em CÓDIGO no alcance dos hooks usa `-I`. Sem ele o interpretador põe
#           no caminho de importação o diretório de trabalho (`-c`, `-`, `-m`) ou a pasta do script, e
#           obedece a PYTHONPATH, PYTHONHOME e ao site do usuário.
#
# DEFEITO DATADO: 2026-11-04, medido em bancada com módulo sombra no diretório de trabalho: o hook importava de
#           fora da instalação do python. Grafo: docs/evolution/research/guard-hooks-python-isolated-2026-11/.
#
# ALVO    : DERIVADO, não listado. Parte de cada comando de hook do `.claude/settings.json` e de
#           `.claude/hooks/lib/*`, inclusive o texto do comando e script fora de `.claude/`, e segue, pelos TOKENS do shell, o que eles EXECUTAM (`bash x.sh`, `. lib.sh`,
#           `python3 x.py`, `V=…/x.sh` + `bash "$V"`). Caminho citado como dado ou em mensagem não entra.
#           `ONION_PYISO_ROOTS=all` soma os `.githooks` e o que eles executam: é o censo do gate inteiro, medido
#           por `--census`; a regra de lint julga só o alcance dos hooks da sessão (teto abaixo).
#
# ACUSA   : `python3 -c`, `python3 -`, `python3 -m`, `python3 <<`, `python3 x.py`, `python`, `python3.12`,
#           `$PY`/`${PY:-python3}`, com invólucro na frente (`exec`, `timeout N`, `env`), dentro de `$(…)` e
#           de crase; em Python, `[sys.executable, …]` e `["python3", …]`; shebang python sem `-I`.
# CALA    : comentário, texto de mensagem, corpo de heredoc, `command -v python3`, `python3 --version`,
#           padrão de `case`, e `python3 -I`, `-IB`, `-B -I`.
#
# TETO    : léxico de shell, não parser. Não vê: python em variável de nome livre (só PY, PYTHON e afins), em
#           `bash -c '…'` entre aspas simples, em `uv run`/`pipx`, nem script cujo caminho se monta em tempo de
#           execução. Não diz nada sobre QUAL `python3` o PATH resolve, nem sobre a sobrescrita do próprio
#           script: `-I` isola os imports do interpretador, não fixa o executável. O alvo `all` (o gate do
#           pre-commit) segue aberto, com a contagem no grafo.
#
# USO     : python-isolated-check.sh [REPO] [--format text|tsv] [--census] | --selftest
# SAÍDA   : <SEV>\t<classe>\t<arquivo:linha>\t<msg>   classe: python-sem-isolamento (HARD) · vazio = limpo
#           --census: <arquivo>\t<linha>\t<com-I|sem-I>\t<forma>
# RC      : 0 sempre que julgou (as linhas dizem o resto) · 2 = não pôde julgar (≠ aprovação)
# =============================================================================
set -uo pipefail
MODE="check"; FORMAT="text"; REPO=""
while [ $# -gt 0 ]; do
  case "$1" in
    --format) FORMAT="${2:-text}"; shift 2 ;;
    --format=*) FORMAT="${1#--format=}"; shift ;;
    --census) MODE="census"; shift ;;
    --selftest) MODE="selftest"; shift ;;
    -h|--help) sed -n '2,36p' "$0"; exit 0 ;;
    *) REPO="$1"; shift ;;
  esac
done

_scan() {
  local repo="$1" fmt="$2" mode="$3"
  command -v python3 >/dev/null 2>&1 || { echo "python-isolated-check: python3 ausente — não pude julgar" >&2; return 2; }
  python3 -I -B /dev/fd/4 "${repo}" "${fmt}" "${mode}" "${ONION_PYISO_ROOTS:-hooks}" 4<<'PY'
import ast, json, os, re, sys, warnings

warnings.simplefilter("ignore")

repo, fmt, mode, roots_mode = sys.argv[1:5]
PY_WORD = re.compile(r"python(?:[23](?:\.\d+)?)?\Z")
VAR_WORD = re.compile(r"\$\{?(?:PY|PYTHON|PYBIN|PY3|PYTHON3|python|py|python3|py3|pybin)(?::?-[^}]*)?\}?\Z")
SEP_CMD = {"then", "do", "else", "elif", "if", "while", "until", "!", "{", "time"}
WRAP = {"command", "exec", "nohup", "builtin", "nice", "ionice", "setsid", "env", "timeout", "sudo", "xargs", "flock", "stdbuf"}
ASSIGN = re.compile(r"[A-Za-z_][A-Za-z0-9_]*\+?=")
SKIP_LOW = re.compile(r"(?:\.md|\.txt|\.tsv|\.json|\.ya?ml)$")


def tokens(text):
    """Léxico de shell: entrega (kind, valor, linha) e mergulha em $(…) e crase. Pula comentário e heredoc."""
    out = []
    n = len(text)
    i = 0
    line = 1
    pending = []          # heredocs pendentes: (delimitador, tira_tabs, linha)
    bodies = []

    def word_flush(buf, start_line):
        if buf:
            out.append(("w", "".join(buf), start_line))
        buf.clear()

    buf = []
    wl = 1
    stack = []            # '(' de $( e de subshell, '`' de crase; o topo decide o que fecha

    def scan_dq(i, line):
        # dentro de aspas duplas: devolve o valor literal e mergulha nas substituições
        val = []
        i += 1
        while i < n:
            c = text[i]
            if c == "\\" and i + 1 < n:
                val.append(text[i + 1]); line += text[i + 1] == "\n"; i += 2; continue
            if c == '"':
                return i + 1, line, "".join(val)
            if c == "$" and text[i + 1:i + 2] == "(" and text[i + 2:i + 3] != "(":
                j, line2 = sub_scan(i + 2, line)
                val.append("$(…)"); i = j; line = line2; continue
            if c == "`":
                j, line2 = sub_scan(i + 1, line, closer="`")
                val.append("`…`"); i = j; line = line2; continue
            if c == "\n":
                line += 1
            val.append(c); i += 1
        return i, line, "".join(val)

    def sub_scan(i, line, closer=")"):
        # recorta o trecho da substituição respeitando aspas e parênteses; tokeniza recursivamente
        start = i; l0 = line; depth = 1
        while i < n:
            c = text[i]
            if c == "\\":
                line += text[i + 1:i + 2] == "\n"; i += 2; continue
            if c == "'" and closer == ")":
                j = text.find("'", i + 1)
                j = n - 1 if j < 0 else j
                line += text.count("\n", i, j); i = j + 1; continue
            if c == '"' and closer == ")":
                j = i + 1
                while j < n and text[j] != '"':
                    if text[j] == "\\":
                        j += 1
                    elif text[j:j + 2] == "$(":
                        j2, _ = sub_scan(j + 2, line)
                        j = j2; continue
                    j += 1
                line += text.count("\n", i, j); i = j + 1; continue
            if closer == "`" and c == "`":
                break
            if closer == ")":
                if c == "(":
                    depth += 1
                elif c == ")":
                    depth -= 1
                    if depth == 0:
                        break
                elif c == "#" and (i == start or text[i - 1] in " \t\n"):
                    j = text.find("\n", i)
                    i = n if j < 0 else j
                    continue
            if c == "\n":
                line += 1
            i += 1
        out.append(("op", ";", l0))
        sub, sub_bodies = tokens(text[start:i])
        for k, v, l in sub:
            out.append((k, v, l + l0 - 1))
        for tag, b, l in sub_bodies:
            bodies.append((tag, b, l + l0 - 1))
        out.append(("op", ";", line))
        return i + 1, line

    while i < n:
        c = text[i]
        if c == "\\" and i + 1 < n:
            if text[i + 1] == "\n":
                i += 2; line += 1; continue
            if not buf:
                wl = line
            buf.append(text[i + 1]); i += 2; continue
        if c == "'":
            if not buf:
                wl = line
            j = text.find("'", i + 1)
            j = n if j < 0 else j
            buf.append("\0S" + text[i + 1:j])
            line += text.count("\n", i, j); i = j + 1; continue
        if c == '"':
            if not buf:
                wl = line
            i, line, v = scan_dq(i, line)
            buf.append("\0D" + v); continue
        if c == "$" and text[i + 1:i + 2] == "(" and text[i + 2:i + 3] != "(":
            if not buf:
                wl = line
            i, line = sub_scan(i + 2, line)
            buf.append("$(…)"); continue
        if c == "`":
            if not buf:
                wl = line
            i, line = sub_scan(i + 1, line, closer="`")
            buf.append("`…`"); continue
        if c == "#" and not buf:
            j = text.find("\n", i)
            i = n if j < 0 else j
            continue
        if c == "<" and text[i:i + 2] == "<<" and text[i:i + 3] != "<<<":
            word_flush(buf, wl)
            j = i + 2
            strip = False
            if text[j:j + 1] == "-":
                strip = True; j += 1
            while j < n and text[j] in " \t":
                j += 1
            m = re.match(r"""['"]?([A-Za-z_][A-Za-z0-9_]*)['"]?""", text[j:])
            if m:
                pending.append((m.group(1), strip))
                out.append(("hd", m.group(1), line))
                i = j + m.end()
                continue
            i += 2
            continue
        if c == "\n":
            word_flush(buf, wl)
            out.append(("op", "\n", line))
            line += 1
            i += 1
            for delim, strip in pending:
                body = []
                l0 = line
                while i < n:
                    e = text.find("\n", i)
                    e = n if e < 0 else e
                    ln = text[i:e]
                    i = min(e + 1, n)
                    line += 1
                    if (ln.lstrip("\t") if strip else ln) == delim:
                        break
                    body.append(ln)
                bodies.append((delim, "\n".join(body), l0))
            pending = []
            continue
        if c in " \t":
            word_flush(buf, wl)
            i += 1
            continue
        if c in ";&|()":
            word_flush(buf, wl)
            out.append(("op", c, line))
            i += 1
            continue
        if not buf:
            wl = line
        buf.append(c)
        i += 1
    word_flush(buf, wl)
    return out, bodies


def plain(word):
    return word.replace("\0S", "").replace("\0D", "")


def invocations(text):
    """Devolve (linha, forma, isolado) de cada python em posição de comando, e os corpos de código embutido."""
    toks, bodies = tokens(text)
    hits = []
    embedded = []          # (linha, código) de python -c/heredoc: procura sys.executable e lista ["python3"…]
    i = 0
    n = len(toks)
    at_cmd = True
    hd_of = {}
    while i < n:
        k, v, ln = toks[i]
        if k == "op":
            at_cmd = True; i += 1; continue
        if k == "hd":
            i += 1; continue
        w = plain(v)
        if at_cmd:
            if w in SEP_CMD or ASSIGN.match(w):
                i += 1; continue
            if w == "command" and i + 1 < n and plain(toks[i + 1][1]) in ("-v", "-V"):
                at_cmd = False       # `command -v python3` pergunta se existe, não executa
                i += 1
                continue
            if w in WRAP:
                # invólucro: pula opções e, para o timeout, a duração
                i += 1
                while i < n and toks[i][0] == "w":
                    a = plain(toks[i][1])
                    if a.startswith("-") or ASSIGN.match(a) or re.fullmatch(r"[0-9.]+[smhd]?", a):
                        i += 1; continue
                    break
                continue
            base = w.rsplit("/", 1)[-1]
            is_label = i + 1 < n and toks[i + 1][0] == "op" and toks[i + 1][1] in ")("
            if (PY_WORD.match(base) or VAR_WORD.match(w)) and not is_label:
                j = i + 1
                flags = []
                form = "script"
                code = None
                info_only = False
                while j < n and toks[j][0] == "w":
                    a = plain(toks[j][1])
                    if a in ("--version", "-V", "--help", "-h"):
                        info_only = True; break   # só responde a versão: nada se importa do diretório
                    if a == "-":
                        form = "-"; break
                    if a in ("-c", "-m"):
                        form = a
                        if a == "-c" and j + 1 < n and toks[j + 1][0] == "w":
                            code = plain(toks[j + 1][1])
                        break
                    if re.fullmatch(r"-[A-Za-z]+", a):
                        flags.append(a)
                        if a[-1] == "c":
                            form = "-c"
                            if j + 1 < n and toks[j + 1][0] == "w":
                                code = plain(toks[j + 1][1])
                            break
                        j += 1; continue
                    if a in ("-W", "-X"):
                        j += 2; continue
                    break
                else:
                    form = "stdin"
                if j < n and toks[j][0] == "hd":
                    form = "<<"
                    hd_of[toks[j][1]] = ln
                # heredoc adiante na mesma linha (redireção depois dos argumentos)
                k2 = j
                while k2 < n and toks[k2][0] != "op":
                    if toks[k2][0] == "hd":
                        hd_of[toks[k2][1]] = ln
                        if form == "stdin":
                            form = "<<"
                    k2 += 1
                iso = any("I" in f[1:] for f in flags)
                if not info_only:
                    hits.append((ln, f"{w} {form}", iso))
                if code:
                    embedded.append((ln, code))
            at_cmd = False
        i += 1
    for delim, body, l0 in bodies:
        if delim in hd_of or re.search(r"\bPY\b|PYTHON|_PY\b", delim):
            embedded.append((l0, body))
    return hits, embedded


CHILD = [
    (re.compile(r"\bsys\.executable\b"), "sys.executable"),
    (re.compile(r"""[\[(,]\s*['"](?:[\w/.-]*/)?python(?:[23](?:\.\d+)?)?['"]\s*,"""), "lista ['python3', …]"),
]
ISO_NEAR = re.compile(r"""['"]-[A-Za-z]*I[A-Za-z]*['"]""")


def scan_python_code(code, base_line):
    """Filho python lançado por código Python. Comentário e docstring não contam."""
    found = []
    try:
        tree = ast.parse(code)
    except Exception:
        tree = None
    if tree is not None:
        for node in ast.walk(tree):
            if isinstance(node, ast.Call) and node.args:
                a0 = node.args[0]
                if isinstance(a0, (ast.List, ast.Tuple)) and a0.elts:
                    h = a0.elts[0]
                    hs = None
                    if isinstance(h, ast.Attribute) and h.attr == "executable":
                        hs = "sys.executable"
                    elif isinstance(h, ast.Constant) and isinstance(h.value, str) and PY_WORD.match(h.value.rsplit("/", 1)[-1]):
                        hs = h.value
                    if hs:
                        iso = any(isinstance(e, ast.Constant) and isinstance(e.value, str)
                                  and re.fullmatch(r"-[A-Za-z]*I[A-Za-z]*", e.value) for e in a0.elts[1:])
                        found.append((base_line + node.lineno - 1, f"{hs} em lista", iso))
        return found
    # não parseou (fragmento): recorte por linha, sem comentário
    for off, l in enumerate(code.splitlines()):
        s = l.split("#", 1)[0]
        for rx, nm in CHILD:
            if rx.search(s):
                found.append((base_line + off, nm, bool(ISO_NEAR.search(s))))
    return found


def read(path):
    try:
        with open(path, encoding="utf-8", errors="surrogateescape") as fh:
            return fh.read()
    except OSError:
        return None


def is_python_file(path, txt):
    return path.endswith(".py") or txt.startswith("#!") and "python" in txt.split("\n", 1)[0]


def shebang_issue(txt):
    first = txt.split("\n", 1)[0]
    if not first.startswith("#!") or "python" not in first:
        return None
    return None if re.search(r"\s-[A-Za-z]*I[A-Za-z]*(\s|$)", first) else first


def build_index():
    """Índice de executáveis do repo: nome-base → caminhos relativos (só as árvores de maquinaria)."""
    idx = {}
    for top in (".claude/hooks", ".claude/validation", ".claude/utils", "ops", ".githooks"):
        top_abs = os.path.join(repo, top)
        for d, dirs, files in os.walk(top_abs):
            dirs[:] = [x for x in dirs if x not in ("__pycache__", "fixtures", "node_modules")]
            for f in files:
                if f.endswith((".sh", ".py")) or d.endswith(".githooks"):
                    p = os.path.relpath(os.path.join(d, f), repo)
                    idx.setdefault(f, []).append(p)
    return idx


LIST_CALL = re.compile(r"""\[\s*["'](?:bash|sh)["']\s*,\s*[^,\]]*?["']?([A-Za-z0-9_./-]+\.(?:sh|py))["']""")
EXEC = {"bash", "sh", "source", "."}
SCRIPT_TAIL = re.compile(r"[^\s]*\.(?:sh|py)\Z")


def shell_exec_targets(txt):
    """Só o que EXECUTA, pelos TOKENS: texto de mensagem e comentário nunca entram. `V=…/x.sh` + `bash "$V"` conta."""
    toks, bodies = tokens(txt)
    sets = {}
    for k, v, _ in toks:
        if k == "w":
            m = re.match(r"([A-Za-z_][A-Za-z0-9_]*)=(.*)\Z", plain(v), re.S)
            if m and SCRIPT_TAIL.match(m.group(2).rstrip("}")):
                sets[m.group(1)] = m.group(2).rstrip("}")
    out = []
    at_cmd = True
    i = 0
    while i < len(toks):
        k, v, _ = toks[i]
        if k != "w":
            at_cmd = k == "op" or at_cmd
            i += 1
            continue
        w = plain(v)
        if at_cmd and (w in SEP_CMD or ASSIGN.match(w)):
            i += 1
            continue
        if at_cmd and w in WRAP:
            i += 1
            while i < len(toks) and toks[i][0] == "w" and re.match(r"-|[0-9.]+[smhd]?\Z", plain(toks[i][1])):
                i += 1
            continue
        base = w.rsplit("/", 1)[-1]
        # `bash`/`sh` sem aspas valem fora da posição de comando: `onion_regen … bash x.sh`, `timeout N bash x.sh`
        if (at_cmd and (base in EXEC or PY_WORD.match(base))) or w in ("bash", "sh"):
            j = i + 1
            stdin_or_inline = False
            while j < len(toks) and toks[j][0] == "w" and plain(toks[j][1]).startswith("-"):
                a = plain(toks[j][1])
                # `python3 -`, `-c`, `-m`, `bash -c`: o que vem depois é argumento ou código, não o script
                if a == "-" or a in ("-c", "-m") or re.fullmatch(r"-[A-Za-z]*c", a):
                    stdin_or_inline = True
                    break
                j += 1
            if not stdin_or_inline and j < len(toks) and toks[j][0] == "w":
                t = plain(toks[j][1])
                if SCRIPT_TAIL.match(t):
                    out.append(t)
                else:
                    m = re.fullmatch(r"\$\{?([A-Za-z_][A-Za-z0-9_]*)\}?", t)
                    if m and m.group(1) in sets:
                        out.append(sets[m.group(1)])
        elif at_cmd and SCRIPT_TAIL.match(w):
            out.append(w)          # `.claude/x/y.sh args` direto
        at_cmd = False
        i += 1
    for _, body, _ in bodies:
        out += [m.group(1) for m in LIST_CALL.finditer(body)]
    return out


def refs_of(rel, txt, idx):
    out = set()
    here = os.path.dirname(rel)
    if is_python_file(rel, txt):
        cands = [m.group(1) for m in LIST_CALL.finditer(txt)]
    else:
        cands = shell_exec_targets(txt)
    for c in cands:
        c = c.rsplit("}", 1)[-1].rsplit(")", 1)[-1].lstrip("/")
        direct = [os.path.normpath(os.path.join(here, c)), os.path.normpath(c)]
        hit = [p for p in direct if os.path.isfile(os.path.join(repo, p))]
        if hit:
            out.add(hit[0]); continue
        cand = idx.get(c.rsplit("/", 1)[-1]) or []
        if len(cand) == 1:
            out.add(cand[0])
    return out


SETTINGS_ROWS = []


def closure():
    idx = build_index()
    st = os.path.join(repo, ".claude", "settings.json")
    if not os.path.isfile(st):
        print("python-isolated-check: sem .claude/settings.json — não pude julgar", file=sys.stderr)
        sys.exit(2)
    try:
        d = json.load(open(st, encoding="utf-8"))
    except Exception as e:
        print(f"python-isolated-check: settings não parseia: {e}", file=sys.stderr)
        sys.exit(2)
    seeds = set()
    for ev, grps in (d.get("hooks") or {}).items():
        for g in grps or []:
            for h in (g.get("hooks") or []) if isinstance(g, dict) else []:
                c = str(h.get("command") or "") if isinstance(h, dict) else ""
                # o próprio texto do comando é código: `python3 -c` direto no settings.json também conta
                hits, embedded = invocations(c)
                for _, form, iso in hits:
                    SETTINGS_ROWS.append((".claude/settings.json", 0, iso, f"{ev}: {form}"))
                for l0, code in embedded:
                    for _, form, iso in scan_python_code(code, l0):
                        SETTINGS_ROWS.append((".claude/settings.json", 0, iso, f"{ev}: {form}"))
                # o script pode morar fora de .claude: o alvo é o que o comando executa, onde estiver
                for t in shell_exec_targets(c):
                    t = re.sub(r"^(?:\$\{?CLAUDE_PROJECT_DIR\}?/|\./)", "", t)
                    if os.path.isfile(os.path.join(repo, t)):
                        seeds.add(os.path.normpath(t))
    hd = os.path.join(repo, ".claude", "hooks", "lib")
    if os.path.isdir(hd):
        for f in os.listdir(hd):
            if f.endswith((".sh", ".py")):
                seeds.add(os.path.join(".claude", "hooks", "lib", f))
    if roots_mode == "all":
        gh = os.path.join(repo, ".githooks")
        if os.path.isdir(gh):
            for f in os.listdir(gh):
                seeds.add(os.path.join(".githooks", f))
    seen = set()
    todo = sorted(seeds)
    while todo:
        p = todo.pop()
        if p in seen:
            continue
        seen.add(p)
        txt = read(os.path.join(repo, p))
        if txt is None:
            continue
        for r in refs_of(p, txt, idx):
            if r not in seen:
                todo.append(r)
    return sorted(seen)


if not os.path.isdir(repo):
    print("python-isolated-check: repo inexistente", file=sys.stderr); sys.exit(2)

files = closure()
rows = list(SETTINGS_ROWS)
for rel in files:
    txt = read(os.path.join(repo, rel))
    if txt is None:
        continue
    if is_python_file(rel, txt):
        sb = shebang_issue(txt)
        if sb:
            rows.append((rel, 1, False, "shebang " + sb))
        for ln, form, iso in scan_python_code(txt, 1):
            rows.append((rel, ln, iso, form))
        continue
    hits, embedded = invocations(txt)
    for ln, form, iso in hits:
        rows.append((rel, ln, iso, form))
    for l0, code in embedded:
        for ln, form, iso in scan_python_code(code, l0):
            rows.append((rel, ln, iso, form))

rows.sort(key=lambda r: (r[0], r[1]))
if mode == "census":
    print(f"# alvo={roots_mode} arquivos={len(files)}")
    if os.environ.get("ONION_PYISO_LIST"):
        print("\n".join("# " + f for f in files))
    for rel, ln, iso, form in rows:
        print(f"{rel}\t{ln}\t{'com-I' if iso else 'sem-I'}\t{form}")
    sys.exit(0)
for rel, ln, iso, form in rows:
    if iso:
        continue
    msg = f"{form} sem -I: o interpretador importa do diretório de trabalho ou da pasta do script"
    if fmt == "tsv":
        print(f"HARD\tpython-sem-isolamento\t{rel}:{ln}\t{msg}")
    else:
        print(f"HARD [python-sem-isolamento] {rel}:{ln}: {msg}")
PY
}

_selftest() {
  local tmp total=0 fails=0 out rc self="${BASH_SOURCE[0]}"
  tmp="$(mktemp -d)"; mkdir -p "${tmp}/.claude/hooks/lib" "${tmp}/.claude/validation"
  _w() { printf '#!/usr/bin/env bash\n%s\n' "$2" > "${tmp}/$1"; }
  printf '{"hooks":{"PreToolUse":[{"matcher":"Bash","hooks":[{"type":"command","command":"bash \\"$CLAUDE_PROJECT_DIR/.claude/hooks/alvo.sh\\""}]}]}}\n' > "${tmp}/.claude/settings.json"
  _run() { total=$((total+1)); out="$(LC_ALL=C bash "${self}" "${tmp}" --format tsv 2>&1)"; rc=$?; }
  _ok() { echo "  ✅ $1"; }
  _ko() { echo "  ✗ $1"; fails=$((fails+1)); }
  _acusa() {  # <nome> <corpo do hook>
    _w .claude/hooks/alvo.sh "$2"; _run
    if [ "${rc}" -eq 0 ] && grep -q $'^HARD\tpython-sem-isolamento\t.claude/hooks/alvo.sh:' <<< "${out}"; then _ok "$1"; else _ko "$1"; fi
  }
  _cala() {  # <nome> <corpo do hook>
    _w .claude/hooks/alvo.sh "$2"; _run
    if [ "${rc}" -eq 0 ] && [ -z "${out}" ]; then _ok "$1"; else _ko "$1"; fi
  }
  # ── ACUSA, cada forma como ela aparece nos hooks ──
  _acusa "(a1) -c dentro de \$(…) em pipe" "x=\$(printf '%s' \"\$i\" | python3 -c 'import json')"
  _acusa "(a2) - com heredoc" "python3 - \"\$a\" <<'PY'
import json
PY"
  _acusa "(a3) << direto" "python3 <<'PY'
print(1)
PY"
  _acusa "(a4) -m" "python3 -m json.tool x"
  _acusa "(a5) script em arquivo" "python3 .claude/x.py"
  _acusa "(a6) python sem o 3" "python -c 'print(1)'"
  _acusa "(a7) python3.12" "python3.12 -c 'print(1)'"
  _acusa "(a8) variável conhecida" "\"\${PY:-python3}\" -c 'print(1)'"
  _acusa "(a9) timeout na frente" "timeout 5 python3 -c 'print(1)'"
  _acusa "(a10) atribuição na frente" "A=1 B=2 python3 -c 'print(1)'"
  _acusa "(a11) dentro de aspas duplas com substituição" "x=\"\$(python3 -c 'print(1)')\""
  _acusa "(a12) -B sem -I" "python3 -B -c 'print(1)'"
  _acusa "(a13) sys.executable em heredoc python" "python3 -I - <<'PY'
import subprocess, sys
subprocess.run([sys.executable, '-c', 'pass'])
PY"
  _acusa "(a14) lista com python3 em heredoc python" "python3 -I - <<'PY'
import subprocess
subprocess.run(['python3', 'x.py'])
PY"
  # ── CALA, o caso honesto ──
  _cala "(c1) com -I" "python3 -I -c 'print(1)'"
  _cala "(c2) -I -B e -IB e -B -I" "python3 -I -B -c 'a'; python3 -IB - <<'PY'
a=1
PY
python3 -B -I x.py"
  _cala "(c3) comentário" "# python3 -c 'print(1)'
# antes; python3 -c 'print(1)'
true # depois; python3 -c fim de linha"
  _cala "(c4) texto de mensagem" "echo \"rode python3 -c 'x'\"; printf '%s\n' 'python3 -c x'; echo python3 -c x"
  _cala "(c5) command -v" "command -v python3 >/dev/null || exit 0"
  _cala "(c6) --version" "python3 --version"
  _cala "(c7) corpo de heredoc de dado" "cat <<'EOF'
python3 -c 'print(1)'
EOF"
  _cala "(c8) padrão de case e argumento de grep" "case \"\$x\" in
  python3) echo ok ;;
esac
grep -q 'python3 -c' arq; for p in python3 python; do :; done"
  _cala "(c9) heredoc python com sys.executable isolado" "python3 -I - <<'PY'
import subprocess, sys
subprocess.run([sys.executable, '-I', '-c', 'pass'])
PY"
  _cala "(c10) código python que só cita o nome em comentário" "python3 -I - <<'PY'
# subprocess.run([sys.executable])
x = 'python3 -c'
PY"
  # ── ALVO derivado ──
  _w .claude/hooks/alvo.sh "bash \"\$CLAUDE_PROJECT_DIR/.claude/validation/chamado.sh\""
  _w .claude/validation/chamado.sh "python3 -c 'print(1)'"; _run
  if grep -q $'^HARD\tpython-sem-isolamento\t.claude/validation/chamado.sh:' <<< "${out}"; then _ok "(d1) script executado pelo hook entra no alvo"; else _ko "(d1) script executado pelo hook entra no alvo"; fi
  _w .claude/hooks/alvo.sh "s=\"\${d}/../validation/chamado.sh\"; bash \"\$s\""; _run
  if grep -q $'^HARD\tpython-sem-isolamento\t.claude/validation/chamado.sh:' <<< "${out}"; then _ok "(d2) caminho por variável segue"; else _ko "(d2) caminho por variável segue"; fi
  _w .claude/hooks/alvo.sh "echo 'rode: bash .claude/validation/chamado.sh'"; _run
  if [ -z "${out}" ]; then _ok "(d3) script só citado em mensagem fica fora"; else _ko "(d3) script só citado em mensagem fica fora"; fi
  _w .claude/hooks/alvo.sh "true"; _w .claude/hooks/lib/x.sh "python3 -c 'print(1)'"; _run
  if grep -q $'^HARD\tpython-sem-isolamento\t.claude/hooks/lib/x.sh:' <<< "${out}"; then _ok "(d4) lib de hook entra mesmo sem referência"; else _ko "(d4) lib de hook entra mesmo sem referência"; fi
  rm -f "${tmp}/.claude/hooks/lib/x.sh"
  printf 'import sys\n' > "${tmp}/.claude/hooks/lib/s.py"; sed -i '1i #!/usr/bin/env python3' "${tmp}/.claude/hooks/lib/s.py"; _run
  if grep -q $'^HARD\tpython-sem-isolamento\t.claude/hooks/lib/s.py:1' <<< "${out}"; then _ok "(d5) shebang python sem -I acusa"; else _ko "(d5) shebang python sem -I acusa"; fi
  rm -f "${tmp}/.claude/hooks/lib/s.py"
  printf '{"hooks":{"Stop":[{"hooks":[{"type":"command","command":"python3 -c \\"print(1)\\""}]}]}}\n' > "${tmp}/.claude/settings.json"; _run
  if grep -q $'^HARD\tpython-sem-isolamento\t.claude/settings.json:' <<< "${out}"; then _ok "(d6) python no texto do comando acusa"; else _ko "(d6) python no texto do comando acusa"; fi
  printf '{"hooks":{"Stop":[{"hooks":[{"type":"command","command":"python3 -I -c \\"print(1)\\""}]}]}}\n' > "${tmp}/.claude/settings.json"; _run
  if [ -z "${out}" ]; then _ok "(d7) python isolado no texto do comando cala"; else _ko "(d7) python isolado no texto do comando cala"; fi
  mkdir -p "${tmp}/scripts"; _w scripts/fora.sh "python3 -c 'print(1)'"
  printf '{"hooks":{"Stop":[{"hooks":[{"type":"command","command":"bash \\"$CLAUDE_PROJECT_DIR/scripts/fora.sh\\""}]}]}}\n' > "${tmp}/.claude/settings.json"; _run
  if grep -q $'^HARD\tpython-sem-isolamento\tscripts/fora.sh:' <<< "${out}"; then _ok "(d8) hook fora de .claude entra no alvo"; else _ko "(d8) hook fora de .claude entra no alvo"; fi
  # ── NÃO JULGOU ≠ aprovação ──
  printf '{nao json' > "${tmp}/.claude/settings.json"; _run
  if [ "${rc}" -eq 2 ]; then _ok "(e1) settings ilegível sai 2"; else _ko "(e1) settings ilegível sai 2"; fi
  rm -f "${tmp}/.claude/settings.json"; _run
  if [ "${rc}" -eq 2 ]; then _ok "(e2) sem settings sai 2"; else _ko "(e2) sem settings sai 2"; fi
  rm -rf "${tmp}"; echo "  selftest: $((total-fails))/${total} verdes"
  [ "${fails}" -eq 0 ] && return 0 || return 1
}

case "${MODE}" in
  selftest) _selftest ;;
  census) [ -n "${REPO}" ] || REPO="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"; _scan "${REPO}" tsv census ;;
  *) [ -n "${REPO}" ] || REPO="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"; _scan "${REPO}" "${FORMAT}" check ;;
esac
