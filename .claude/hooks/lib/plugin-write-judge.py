# plugin-write-judge.py — juiz da escrita de plugin em .claude/skills, carregado DENTRO do tokenizador.
# Nunca roda só: o pretooluse-plugin-write-guard.sh aponta ONION_MOAT_JUDGE para cá, e o lib o executa no próprio
# namespace. Ele carrega o moat-judge.py INTEIRO e troca só o que é do MOAT: a pergunta "este caminho é alvo?", a
# relevância do que não se prova, e as classes emitidas.
#
# ── POR QUE COMPÕE, EM VEZ DE COPIAR (molde medido pelo censo de 2026-11-04) ──────────────────────────
# O defeito dominante de guarda por lista é o VOCABULÁRIO (guard-doctrine, cláusula 3). A tabela verbo → destino do
# moat-judge (redirecionamento, tee, cp, install, rsync, dd, tar, curl -o, sed -i, find -exec, xargs, `bash -c`,
# script lido, função emulada) já apanhou de cinco passadas adversariais. Uma cópia dela envelheceria sozinha;
# composta, um verbo novo no MOAT vale aqui também. O preço é o acoplamento aos nomes internos do moat-judge
# (`_moat_path_match`, `_moat_emit`, `_moat_abspath`, `_moat_script`, `moat_relevant`, `moat_unanalyzable`,
# `moat_command`): renomear um deles quebra esta guarda, e a família plugin_write_guard reprova na hora.
#
# ── O QUE MUDA EM RELAÇÃO AO MOAT ─────────────────────────────────────────────────────────────
#  · alvo: a FORMA do caminho, como escrito E resolvido (`_pw_form`), em vez da lista de ops/moat-targets.tsv (core-only);
#  · remover e ler não é escrever: `rm`, `rmdir`, `unlink`, `find -delete`, `find -exec rm`, `git clean`, `git rm`, a
#    ORIGEM de um mv, cp ou xargs cp, e a referência de `touch -r` passam. Tirar um plugin plantado é a cura que a varredura manda;
#  · pasta inteira: `cp -r`, `mv`, `ln -s`, `rsync` de uma pasta que JÁ TEM `.claude-plugin/` ou `hooks/` para dentro
#    de .claude/skills (S6 da medição: a skill que é link para fora carrega);
#  · outra linguagem: em Python, pela árvore sintática e só no argumento DESTINO; nas outras, pela forma, com o caminho literal;
#  · heredoc: só é código se quem o lê é um interpretador sem script (`python3 - <<E`). Heredoc de documento e `git commit -F -`
#    são texto, inclusive quando citam um heredoc de python dentro deles;
#  · script solto: só se veta a escrita PROVADA no corpo. O que o corpo não deixa provar cala, porque rodar a própria guarda
#    fora do checkout era vetado por uma função que usa `shift`;
#  · relógio, repo alheio, os modos de teste dos wrappers e ssh para outra máquina não são desta guarda.
import ast as _pw_ast
import os as _pw_os

_pw_moat = _pw_os.path.join(_pw_os.path.dirname(_pw_os.path.abspath(_pw_os.environ["ONION_MOAT_JUDGE"])), "moat-judge.py")
exec(compile(open(_pw_moat, encoding="utf-8").read(), _pw_moat, "exec"))

_PW_FORM_PLUGIN = ".claude/skills/**/.claude-plugin/**"
_PW_FORM_HOOKS = ".claude/skills/**/hooks/**"
# o que a varredura não desce: uma skill pode trazer dependência vendorizada, e o `hooks/` dela não é plugin
_PW_PRUNE = {"node_modules", ".git", ".venv", "venv"}
_PW = {"skip": False, "exempt": set(), "noexec": False, "in_script": 0}
# os motores escritores e os wrappers do MOAT não têm a ver com plugin; vazios, os ramos deles nunca casam
_MOAT_ARG_WRITERS = {}
_MOAT_WRAPPER_COPIES = ()
# o sinal por linha, para o que não se prova (eval, xargs, nome de comando em runtime, script recém-escrito)
_PW_TEXT_SIG = re.compile(r"skills/\S*(?:\.claude-plugin|/hooks)")
_PW_SHELL_WRITE = re.compile(r">|\b(cp|mv|install|tee|ln|mkdir|touch|dd|tar|unzip|rsync|curl|wget)\b")
_MOAT_SIGNAL = _PW_TEXT_SIG
_MOAT_MEMBER_SIGNAL = None
# REPLAY de 2026-11-04 (60.418 comandos Bash únicos dos transcripts): a 1ª redação vetou um `python3 - <<'PY'` honesto que fazia
# `s.replace(old, '… .claude-plugin/marketplace.json')`. Python agora vai pela árvore; aqui ficam as outras linguagens, com o
# caminho literal trazendo `.claude/skills/`, e no argumento DESTINO.
_PW_PATH = r"[^'\"`\n]*\.claude/skills/[^'\"`\n]*(?:\.claude-plugin|/hooks)(?:/[^'\"`\n]*)?"
_PW_QP = r"[a-zA-Z]*['\"`]" + _PW_PATH + r"['\"`]"
_PW_CODE_WRITE = re.compile(
    r"\b(?:writeFile|writeFileSync|appendFile|appendFileSync|mkdirSync)\(\s*" + _PW_QP +
    r"|\b(?:copyFileSync|cpSync|renameSync|symlinkSync)\(\s*[^,()]*,\s*" + _PW_QP +
    r"|\bFile\.write\(\s*" + _PW_QP +
    r"|\bFile\.open\(\s*" + _PW_QP + r"\s*,\s*['\"][wa]" +
    r"|\bopen\([^,()]*,\s*['\"]>+\s*" + _PW_PATH + r"['\"]" +
    r"|\bfile_put_contents\(\s*" + _PW_QP)
_PW_INTERPS = {"python", "python3", "perl", "ruby", "node", "php"}
_PW_PY_DEST = {"os.rename": 1, "os.replace": 1, "os.symlink": 1, "os.link": 1, "os.makedirs": 0, "os.mkdir": 0,
               "shutil.copy": 1, "shutil.copy2": 1, "shutil.copyfile": 1, "shutil.copytree": 1, "shutil.move": 1}
_PW_PATH_WRITE = {"write_text", "write_bytes", "mkdir", "touch", "symlink_to", "hardlink_to"}
# o leitor do heredoc: interpretador só com opções, sem script nem -c/-e (ali o heredoc é dado)
_PW_INTERP_READER = re.compile(r"(?:^|[\s;&|(])(python3?|perl|ruby|node|php)(?:\s+-[A-Za-bd-df-z]*)*\s*(?:\d?<<)")
_PW_RAW_ASSIGN = re.compile(r"(?:^|[\s;&|(])([A-Za-z_][A-Za-z0-9_]*)=(\"[^\"\n]*\"|'[^'\n]*'|[^\s;&|()]*)")
_PW_REBIND = re.compile(r"\b(?:for|select)\s+([A-Za-z_][A-Za-z0-9_]*)\s+in\b|\bread\s+(?:-\S+\s+)*([A-Za-z_][A-Za-z0-9_]*)")
_PW_VAR = re.compile(r"\$\{([A-Za-z_][A-Za-z0-9_]*)\}|\$([A-Za-z_][A-Za-z0-9_]*)")
_PW_PWD_SUBST = re.compile(r"\$\(\s*pwd\s*\)|`\s*pwd\s*`")
_PW_TOP_SUBST = re.compile(r"\$\(\s*git\s+rev-parse\s+--show-toplevel\s*\)|`\s*git\s+rev-parse\s+--show-toplevel\s*`")
_PW_ENV_NAME = re.compile(r"^(?:\.env(?:\..*)?|.*\.env)$")
_pw_seen_raw = [False]
_pw_assign = {}          # NOME → o único valor bruto atribuído na string; com valores distintos, não entra
_pw_ambiguous = set()    # NOME com mais de um valor, ou religado por for/select/read: a última atribuição não prova nada


def _pw_form(p):
    """A forma do caminho. O 1º componente depois de skills/ é o NOME da skill: uma skill chamada `hooks` é honesta, e abaixo
    de node_modules, .git e venv a forma não conta (é o que a varredura também não desce)."""
    parts = str(p).split("/")
    for i in range(len(parts) - 1):
        if parts[i] == ".claude" and parts[i + 1] == "skills":
            for j, c in enumerate(parts[i + 2:]):
                if j >= 1 and c in _PW_PRUNE:
                    return None
                if c == ".claude-plugin":
                    return _PW_FORM_PLUGIN
                if c == "hooks" and j >= 1:
                    return _PW_FORM_HOOKS
    return None


def _pw_in_skills(p):
    parts = str(p).split("/")
    return any(parts[i] == ".claude" and parts[i + 1] == "skills" for i in range(len(parts) - 1))


def _moat_path_match(p, classes=("deploy", "relogio")):
    if not p or _PW["skip"] or p in _PW["exempt"]:
        return None
    for q in (p, os.path.realpath(p)):
        form = _pw_form(q)
        if form:
            return ("plugin", form, "")
    return None


_pw_base_emit = _moat_emit


def _moat_emit(cls, target, wrapper, detail):
    if cls in ("relogio", "alheio"):
        return
    if cls == "inanalisavel" and re.fullmatch(r"ONION_[A-Z0-9_]+_TEST", str(target)):
        return
    _pw_base_emit("plugin" if cls == "deploy" else cls, target, wrapper, detail)


def moat_relevant(text):
    t = text if isinstance(text, str) else " ".join(str(x) for x in text)
    return any(_PW_TEXT_SIG.search(ln) and _PW_SHELL_WRITE.search(ln) for ln in t.split("\n"))


# ── Python pela árvore: o caminho literal no argumento que recebe a escrita, nunca o texto ─────────────
def _pw_dotted(f):
    if isinstance(f, _pw_ast.Name):
        return f.id
    if isinstance(f, _pw_ast.Attribute):
        b = _pw_dotted(f.value)
        return b + "." + f.attr if b else None
    return None


def _pw_lit(n, names):
    """O valor de uma expressão que só tem literais; None quando ela depende do runtime."""
    if isinstance(n, _pw_ast.Constant):
        return n.value if isinstance(n.value, str) else None
    if isinstance(n, _pw_ast.Name):
        return names.get(n.id)
    if isinstance(n, _pw_ast.JoinedStr):
        vals = [_pw_lit(v, names) for v in n.values]
        return "".join(vals) if all(v is not None for v in vals) else None
    if isinstance(n, _pw_ast.BinOp) and isinstance(n.op, (_pw_ast.Add, _pw_ast.Div)):
        a, b = _pw_lit(n.left, names), _pw_lit(n.right, names)
        if a is None or b is None:
            return None
        return a + b if isinstance(n.op, _pw_ast.Add) else a.rstrip("/") + "/" + b
    if isinstance(n, _pw_ast.Call):
        d = _pw_dotted(n.func) or ""
        vals = [_pw_lit(a, names) for a in n.args]
        if any(v is None for v in vals):
            return None
        if d in ("Path", "PurePath", "pathlib.Path", "pathlib.PurePath", "os.path.join") and vals:
            return "/".join(v.rstrip("/") for v in vals)
        if d in ("Path.home", "pathlib.Path.home") and not vals:
            return "~"
        if d == "os.path.expanduser" and len(vals) == 1:
            return vals[0]
        if d == "os.path.dirname" and len(vals) == 1:
            return os.path.dirname(vals[0])
    return None


def _pw_hits(lit):
    if not lit:
        return False
    p = _moat_abspath(lit) or lit
    return bool(_pw_form(p) or _pw_form(os.path.realpath(p)))


def _pw_python_writes(code):
    try:
        tree = _pw_ast.parse(code)
    except (SyntaxError, ValueError, RecursionError):
        return False
    binds, names = {}, {}
    for n in _pw_ast.walk(tree):
        if isinstance(n, _pw_ast.Assign) and len(n.targets) == 1 and isinstance(n.targets[0], _pw_ast.Name):
            binds.setdefault(n.targets[0].id, []).append(n.value)
    for _ in range(3):
        for k, vals in binds.items():
            if len(vals) == 1:
                v = _pw_lit(vals[0], names)
                if v is not None:
                    names[k] = v
    for n in _pw_ast.walk(tree):
        if not isinstance(n, _pw_ast.Call):
            continue
        d = _pw_dotted(n.func)
        kw = {k.arg: k.value for k in n.keywords if k.arg}
        if d == "open" or d == "io.open" or d == "os.fdopen":
            target = n.args[0] if n.args else kw.get("file")
            mode = n.args[1] if len(n.args) > 1 else kw.get("mode")
            m = _pw_lit(mode, names) if mode is not None else ""
            if m and re.search(r"[wax+]", m) and _pw_hits(_pw_lit(target, names) if target is not None else None):
                return True
        elif d in _PW_PY_DEST:
            i = _PW_PY_DEST[d]
            if len(n.args) > i and _pw_hits(_pw_lit(n.args[i], names)):
                return True
        elif isinstance(n.func, _pw_ast.Attribute):
            recv = _pw_lit(n.func.value, names)
            if recv is None:
                continue
            a = n.func.attr
            if a in _PW_PATH_WRITE and _pw_hits(recv):
                return True
            if a == "open":
                mode = n.args[0] if n.args else kw.get("mode")
                m = _pw_lit(mode, names) if mode is not None else ""
                if m and re.search(r"[wax+]", m) and _pw_hits(recv):
                    return True
            if a in ("rename", "replace") and n.args and _pw_hits(_pw_lit(n.args[0], names)):
                return True
    return False


def _pw_code_writes(lang, code):
    if lang.startswith("python"):
        return _pw_python_writes(code)
    return bool(_PW_CODE_WRITE.search(code))


_pw_base_unanalyzable = moat_unanalyzable


def moat_unanalyzable(seg, why, whole=False):
    head = os.path.basename(str(seg[0])) if isinstance(seg, (list, tuple)) and seg else ""
    if head == "ssh":
        return                                          # outra máquina: não é plugin DESTA sessão (ver o teto)
    if "noutra linguagem" in why and head in _PW_INTERPS:
        args = [str(x) for x in seg[1:]]
        for k, a in enumerate(args):
            if re.match(r"^-[A-Za-z]*[ce]$", a) and k + 1 < len(args) and _pw_code_writes(head, args[k + 1]):
                _moat_emit("plugin", args[k + 1], "", "código embutido que escreve no caminho")
        return
    if why.startswith("xargs"):
        # `… | xargs -I{} cp {} /tmp/` e `… | xargs cp -t /tmp`: o stdin é a ORIGEM, e o destino está no texto.
        words = [str(x) for x in seg]
        tail = words[words.index("xargs") + 1:] if "xargs" in words else []
        ph = None
        while tail and tail[0].startswith("-"):
            o = tail.pop(0)
            if o == "-I" and tail:
                ph = tail.pop(0)
            elif o.startswith("-I"):
                ph = o[2:]
            elif o in ("-n", "-P", "-d", "-a", "-E", "-L", "-s") and tail:
                tail.pop(0)
        if tail and os.path.basename(tail[0]) in ("cp", "mv", "ln", "install", "rsync"):
            t = _moat_opt_value(tail[1:], {"-t", "--target-directory"}, ("--target-directory",))
            dest = t or (tail[-1] if ph and ph not in tail[-1] and len(tail) >= 3 else None)
            if dest:
                return                                  # o `cp … destino` o lib já julga como comando próprio
    if _PW["in_script"]:
        return                                          # script solto: só a escrita provada veta (ver o cabeçalho)
    _pw_base_unanalyzable(seg, why, whole)


# ── nome montado de literais da própria string ─────────────────────────────────────────────────
# O lib esquece a atribuição cujo valor tem variável: é dinâmica para ISENTAR. Para VETAR, a conta se faz com os valores
# literais, o ambiente conhecido (HOME, CLAUDE_PROJECT_DIR), o diretório julgado (PWD) e o topo do git. Só caminho de ESCRITA
# passa por aqui: o que a string apenas lê nunca chama o _moat_abspath. Com valores distintos para o mesmo nome (ramo de `if`,
# escrita antes de reatribuir, `for`, função com `local`) a última atribuição não prova: cala, e isso é falso negativo declarado.
def _pw_blank_quoted(t):
    """Tira o texto entre aspas, exceto o valor de uma atribuição: `echo 'OUT=x'` cita, e `OUT="x"` atribui."""
    out, i, n = [], 0, len(t)
    while i < n:
        c = t[i]
        if c in "'\"":
            j = t.find(c, i + 1)
            if j < 0:
                out.append(t[i:]); break
            out.append(t[i:j + 1] if i > 0 and t[i - 1] == "=" else " ")
            i = j + 1
            continue
        out.append(c)
        i += 1
    return "".join(out)


def _pw_load_assign():
    if _pw_seen_raw[0]:
        return
    _pw_seen_raw[0] = True
    text = _pw_blank_quoted(heredocs(raw))
    vals = {}
    for m in _PW_RAW_ASSIGN.finditer(text):
        v = m.group(2)
        vals.setdefault(m.group(1), set()).add(v[1:-1] if v[:1] in ("'", '"') else v)
    for m in _PW_REBIND.finditer(text):
        n = m.group(1) or m.group(2)
        vals.setdefault(n, set()).update({"\0rebind1", "\0rebind2"})
    for k, s in vals.items():
        if len(s) == 1:
            _pw_assign[k] = next(iter(s))
        else:
            _pw_ambiguous.add(k)
    _pw_scan_interp_heredocs()


_pw_base_heredocs = heredocs


def heredocs(text):
    t = _pw_base_heredocs(text)
    t = _PW_PWD_SUBST.sub("$PWD", t)
    return _PW_TOP_SUBST.sub("$__PW_TOP", t)


_pw_base_resolve = resolve


def resolve(word):
    _pw_load_assign()
    if not _pw_ambiguous:
        return _pw_base_resolve(word)
    held = {k: ASSIGN.pop(k) for k in list(_pw_ambiguous) if k in ASSIGN}
    try:
        return _pw_base_resolve(word)
    finally:
        ASSIGN.update(held)


def _pw_value(name, with_pwd=True):
    if name in _pw_ambiguous:
        return None
    if name in ASSIGN:
        return ASSIGN[name]
    if name in _pw_assign:
        return _pw_assign[name]
    if name in ("HOME", "CLAUDE_PROJECT_DIR"):
        return os.environ.get(name) or None
    if with_pwd and name == "PWD":
        d = _moat_dir()
        if d == UNKNOWN:
            return _MOAT_CDS[-1] if _MOAT_CDS else None
        return d
    if with_pwd and name == "__PW_TOP":
        d = _moat_dir()
        if d == UNKNOWN:
            return None
        return _git(["-C", d, "rev-parse", "--show-toplevel"]).strip() or None
    return None


def _pw_expand(w, with_pwd=True):
    _pw_load_assign()
    for _ in range(4):
        def sub(m):
            v = _pw_value(m.group(1) or m.group(2), with_pwd)
            return m.group(0) if v is None else v
        n = _PW_VAR.sub(sub, w)
        if n == w:
            break
        w = n
    return w


_pw_base_abspath = _moat_abspath


def _moat_abspath(w, base=None):
    if w and "$" in w:
        w = _pw_expand(w)
    return _pw_base_abspath(w, base)


# ── heredoc: o corpo só conta como código se o leitor for interpretador sem script ─────────────────────
def _pw_scan_interp_heredocs():
    lines, i, q = raw.split("\n"), 0, [None, []]
    while i < len(lines):
        ln = lines[i]
        i += 1
        for term, _inert in find_heredoc_openers(ln, q):
            body = []
            while i < len(lines) and lines[i].lstrip("\t") != term:
                body.append(lines[i])
                i += 1
            i += 1
            bare = re.sub(r"'[^']*'|\"(?:[^\"\\]|\\.)*\"", " ", ln)
            m = _PW_INTERP_READER.search(bare)
            if m and _pw_code_writes(m.group(1), "\n".join(body)):
                _moat_emit("plugin", term, "", "heredoc lido por interpretador que escreve no caminho")


_pw_base_script = _moat_script


def _moat_script(path, depth, words):
    if _PW["noexec"] or _PW_ENV_NAME.match(os.path.basename(str(path))):
        return                                          # `bash -n` não executa, e arquivo de segredos o juiz não abre
    _PW["in_script"] += 1
    try:
        _pw_base_script(path, depth, words)
    finally:
        _PW["in_script"] -= 1


def _pw_tree_form(src, excluded=()):
    return any(n not in excluded and os.path.isdir(os.path.join(src, n)) for n in (".claude-plugin", "hooks"))


def _pw_copy_into_skills(base, args, detail):
    """Pasta que JÁ TEM a forma de plugin indo para dentro de .claude/skills. O destino sozinho não tem a forma."""
    pos = _moat_positionals(args, {"-S", "--suffix", "-e", "--rsh", "--exclude", "--include", "--filter", "-f"})
    tdir = _moat_opt_value(args, {"-t", "--target-directory"}, ("--target-directory",))
    if tdir:
        dest, srcs = tdir, pos
    elif len(pos) >= 2:
        dest, srcs = pos[-1], pos[:-1]
    else:
        return
    d = _moat_abspath(dest)
    if not d or not (_pw_in_skills(d) or _pw_in_skills(os.path.realpath(d))):
        return
    ex = set()
    if base == "rsync":
        for k, a in enumerate(args):
            v = a.split("=", 1)[1] if a.startswith("--exclude=") else (args[k + 1] if a == "--exclude" and k + 1 < len(args) else None)
            if v:
                ex.add(v.strip("/"))
    for s in srcs:
        sp = _moat_abspath(s, os.path.dirname(d) if base == "ln" else None)
        if sp and _pw_tree_form(os.path.realpath(sp), ex):
            _moat_emit("plugin", d, "", "%s de uma pasta com a forma de plugin para dentro de .claude/skills — %s" % (base, detail))


def _pw_short_flag(args, letter):
    return any(a.startswith("-") and not a.startswith("--") and letter in a[1:] for a in args)


def _pw_cd(base, words):
    """O `cd` que o juiz não acompanha não pode deixar o último `cd` literal valendo: `cd x && ls; cd -; echo > r.md` é fora de x."""
    if base == "popd" or (base in ("cd", "pushd") and (len(words) < 2 or words[1] == "-")):
        del _MOAT_CDS[:]
        return
    if base in ("cd", "pushd") and DYNAMIC.search(words[1]):
        w = _pw_expand(words[1], with_pwd=False)
        if DYNAMIC.search(w):
            del _MOAT_CDS[:]
        else:
            prev = _MOAT_CDS[-1] if _MOAT_CDS else (CWD[-1] if CWD[-1] not in (None, UNKNOWN) else JCWD)
            _MOAT_CDS.append(os.path.normpath(os.path.join(prev, os.path.expanduser(w))))
    elif base == "pushd":
        prev = _MOAT_CDS[-1] if _MOAT_CDS else (CWD[-1] if CWD[-1] not in (None, UNKNOWN) else JCWD)
        _MOAT_CDS.append(os.path.normpath(os.path.join(prev, os.path.expanduser(words[1]))))


_pw_base_command = moat_command


def moat_command(words, raw_words, base, depth, env, piped, stdin_from):
    _pw_load_assign()
    args = words[1:]
    saved = (_PW["skip"], _PW["exempt"], _PW["noexec"])
    skip = base in ("rm", "rmdir", "unlink")
    exempt = set()
    if base == "find":
        # o `-exec cp {} destino` o lib julga como comando próprio. A RAIZ só se escreve com verbo que muda o arquivo no lugar
        verbs = {os.path.basename(args[k + 1]) for k, a in enumerate(args) if a in ("-exec", "-execdir", "-ok", "-okdir") and k + 1 < len(args)}
        skip = not (verbs & {"sed", "chmod", "chown", "touch", "truncate", "tee", "dd"})
    elif base == "git":
        pos = _moat_positionals(args, {"-C", "-c", "--git-dir", "--work-tree"})
        skip = bool(pos) and pos[0] in ("clean", "rm")
    elif base == "mv":
        pos = _moat_positionals(args, {"-S", "--suffix"})
        tdir = _moat_opt_value(args, {"-t", "--target-directory"}, ("--target-directory",))
        exempt = {_moat_abspath(s) for s in (pos if tdir else pos[:-1])}
    elif base == "ln":
        pos = _moat_positionals(args, {"-S", "--suffix", "-t", "--target-directory"})
        if len(pos) == 1:                               # `ln -s ALVO` cria o link no diretório atual
            exempt = {_moat_abspath(pos[0])}
    elif base == "touch":
        for k, a in enumerate(args):
            if a in ("-r", "--reference") and k + 1 < len(args):
                exempt.add(_moat_abspath(args[k + 1]))
    elif base == "tar":
        skip = _pw_short_flag(args, "O") or "--to-stdout" in args
    elif base in ("rsync", "scp"):
        dest = _moat_positionals(args, {"-e", "--rsh", "--exclude", "--include", "--filter", "-f", "-P", "-i", "-F"})[-1:]
        remote = bool(dest) and bool(re.match(r"^[^/:]+:", dest[0]))
        skip = remote or (base == "rsync" and (_pw_short_flag(args, "n") or "--dry-run" in args))
    if base in SHELLS or base in ("source", "."):
        _PW["noexec"] = _pw_short_flag(args, "n") or "--noexec" in args
    _pw_cd(base, words)
    _PW["skip"], _PW["exempt"] = skip, exempt
    if base in ("cp", "mv", "ln", "rsync") and not skip:
        _pw_copy_into_skills(base, args, " ".join(raw_words))
    try:
        _pw_base_command(words, raw_words, base, depth, env, piped, stdin_from)
    finally:
        _PW["skip"], _PW["exempt"], _PW["noexec"] = saved
