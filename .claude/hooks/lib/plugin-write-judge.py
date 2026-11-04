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
# (`_moat_path_match`, `_moat_emit`, `_moat_abspath`, `moat_relevant`, `moat_unanalyzable`, `moat_command`): renomear
# um deles quebra esta guarda, e a família plugin_write_guard reprova na hora.
#
# ── O QUE MUDA EM RELAÇÃO AO MOAT ─────────────────────────────────────────────────────────────
#  · alvo: a FORMA do caminho, como escrito E resolvido (`_pw_form`), em vez da lista de ops/moat-targets.tsv (core-only);
#  · remover não é escrever: `rm`, `rmdir`, `unlink`, `find -delete` e a ORIGEM de um `mv` passam, porque tirar um
#    plugin plantado é a cura que a varredura manda fazer;
#  · pasta inteira: `cp -r`, `mv`, `ln -s`, `rsync` de uma pasta que JÁ TEM `.claude-plugin/` ou `hooks/` para dentro
#    de .claude/skills (S6 da medição: a skill que é link para fora carrega);
#  · outra linguagem: só a escrita em que o caminho é literal e o idioma é de escrita (`_PW_CODE_WRITE`), porque o
#    `moat_relevant` por linha acusaria o `open(saida,'w')` de um relatório que só cita o caminho (cláusula 4);
#  · relógio, repo alheio e os modos de teste dos wrappers não são desta guarda: saem no `_moat_emit`.
import os as _pw_os

_pw_moat = _pw_os.path.join(_pw_os.path.dirname(_pw_os.path.abspath(_pw_os.environ["ONION_MOAT_JUDGE"])), "moat-judge.py")
exec(compile(open(_pw_moat, encoding="utf-8").read(), _pw_moat, "exec"))

_PW_FORM_PLUGIN = ".claude/skills/**/.claude-plugin/**"
_PW_FORM_HOOKS = ".claude/skills/**/hooks/**"
_PW = {"removal": False, "exempt": set()}
# os motores escritores e os wrappers do MOAT não têm a ver com plugin; vazios, os ramos deles nunca casam
_MOAT_ARG_WRITERS = {}
_MOAT_WRAPPER_COPIES = ()
# o sinal por linha, para o que não se prova (eval, xargs, nome de comando em runtime, script recém-escrito)
_PW_TEXT_SIG = re.compile(r"skills/\S*(?:\.claude-plugin|/hooks)")
_PW_SHELL_WRITE = re.compile(r">|\b(cp|mv|install|tee|ln|mkdir|touch|dd|tar|unzip|rsync|curl|wget)\b")
_MOAT_SIGNAL = _PW_TEXT_SIG
_MOAT_MEMBER_SIGNAL = None
# REPLAY de 2026-11-04 (60.393 comandos Bash únicos dos transcripts): a 1ª redação vetou um `python3 - <<'PY'` honesto que fazia
# `s.replace(old, '… .claude-plugin/marketplace.json')`. Duas causas e duas curas: o `.claude-plugin` da raiz do repo não é
# plugin em skills (o caminho literal tem de trazer `.claude/skills/`), e `str.replace` não é `os.replace` (o idioma de
# arquivo tem de vir qualificado pelo módulo).
_PW_PATH = r"[^'\"`\n]*\.claude/skills/[^'\"`\n]*(?:\.claude-plugin|/hooks)(?:/[^'\"`\n]*)?"
_PW_QP = r"[a-zA-Z]*['\"`]" + _PW_PATH + r"['\"`]"
_PW_CODE_WRITE = re.compile(
    r"\bopen\(\s*" + _PW_QP + r"\s*,\s*(?:mode\s*=\s*)?[a-zA-Z]*['\"][^'\"]*[wax+]"
    r"|\bPath\(\s*" + _PW_QP + r"\s*\)\s*\.\s*(?:write_text|write_bytes|mkdir|touch)\b"
    r"|\b(?:os\.(?:rename|replace|symlink|link|makedirs|mkdir)|shutil\.(?:copy|copy2|copyfile|copytree|move))\(\s*(?:[^,()]*,\s*)?" + _PW_QP +
    r"|\b(?:fs\.)?(?:writeFile|writeFileSync|appendFile|appendFileSync|mkdirSync|cpSync|copyFileSync)\(\s*(?:[^,()]*,\s*)?" + _PW_QP +
    r"|\bFile\.(?:write|open)\(\s*" + _PW_QP +
    r"|\bopen\([^,()]*,\s*['\"]>+\s*" + _PW_PATH + r"['\"]")
_PW_INTERPS = {"python", "python3", "perl", "ruby", "node", "php"}
_PW_INTERP_HEREDOC = re.compile(r"(?:^|[\s;&|(])(?:python3?|perl|ruby|node|php)\b[^\n|;&]*<<-?[ \t]*(['\"]?)([A-Za-z_][A-Za-z0-9_]*)\1[^\n]*\n")
_PW_RAW_ASSIGN = re.compile(r"(?:^|[\s;&|(])([A-Za-z_][A-Za-z0-9_]*)=(\"[^\"\n]*\"|'[^'\n]*'|[^\s;&|()]*)")
_PW_VAR = re.compile(r"\$\{([A-Za-z_][A-Za-z0-9_]*)\}|\$([A-Za-z_][A-Za-z0-9_]*)")
_pw_seen_raw = [False]
_pw_raw_assign = {}


def _pw_form(p):
    """A forma do caminho. O 1º componente depois de skills/ é o NOME da skill: uma skill chamada `hooks` é honesta."""
    parts = str(p).split("/")
    for i in range(len(parts) - 1):
        if parts[i] == ".claude" and parts[i + 1] == "skills":
            for j, c in enumerate(parts[i + 2:]):
                if c == ".claude-plugin":
                    return _PW_FORM_PLUGIN
                if c == "hooks" and j >= 1:
                    return _PW_FORM_HOOKS
    return None


def _pw_in_skills(p):
    parts = str(p).split("/")
    return any(parts[i] == ".claude" and parts[i + 1] == "skills" for i in range(len(parts) - 1))


def _moat_path_match(p, classes=("deploy", "relogio")):
    if not p or _PW["removal"] or p in _PW["exempt"]:
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


_pw_base_unanalyzable = moat_unanalyzable


def moat_unanalyzable(seg, why, whole=False):
    if "noutra linguagem" in why and isinstance(seg, (list, tuple)) and seg and os.path.basename(str(seg[0])) in _PW_INTERPS:
        t = " ".join(str(x) for x in seg)
        if _PW_CODE_WRITE.search(t):
            _moat_emit("plugin", t, "", "código embutido que escreve no caminho")
        return
    _pw_base_unanalyzable(seg, why, whole)


# `a=.cla; b=ude; f="$a$b/skills/x/.claude-plugin/p"; … > "$f"`: o lib esquece a atribuição cujo valor tem variável
# (ela é dinâmica para ISENTAR). Para VETAR, a conta se faz: o valor vem do texto bruto, os pedaços vêm das atribuições
# literais. Só caminho de ESCRITA passa por aqui: o que a string apenas lê nunca chama o _moat_abspath.
def _pw_expand(w):
    if not _pw_raw_assign:
        for m in _PW_RAW_ASSIGN.finditer(raw):
            v = m.group(2)
            _pw_raw_assign[m.group(1)] = v[1:-1] if v[:1] in ("'", '"') else v
    for _ in range(4):
        n = _PW_VAR.sub(lambda m: ASSIGN.get(m.group(1) or m.group(2), _pw_raw_assign.get(m.group(1) or m.group(2), m.group(0))), w)
        if n == w:
            break
        w = n
    return w


_pw_base_abspath = _moat_abspath


def _moat_abspath(w, base=None):
    if w and "$" in w:
        w = _pw_expand(w)
    return _pw_base_abspath(w, base)


def _pw_scan_interp_heredocs():
    """`python3 - <<'EOF'`: o corpo é código e o tokenizador o trata como inerte. Julgado uma vez, no texto bruto."""
    lines_after = raw
    for m in _PW_INTERP_HEREDOC.finditer(lines_after):
        delim = m.group(2)
        body = lines_after[m.end():].split("\n" + delim + "\n", 1)[0]
        if _PW_CODE_WRITE.search(body):
            _moat_emit("plugin", delim, "", "heredoc lido por interpretador que escreve no caminho")


def _pw_tree_form(src):
    return any(os.path.isdir(os.path.join(src, n)) for n in (".claude-plugin", "hooks"))


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
    for s in srcs:
        sp = _moat_abspath(s, os.path.dirname(d) if base == "ln" else None)
        if sp and _pw_tree_form(os.path.realpath(sp)):
            _moat_emit("plugin", d, "", "%s de uma pasta com a forma de plugin para dentro de .claude/skills — %s" % (base, detail))


_pw_base_command = moat_command


def moat_command(words, raw_words, base, depth, env, piped, stdin_from):
    if not _pw_seen_raw[0]:
        _pw_seen_raw[0] = True
        _pw_scan_interp_heredocs()
    args = words[1:]
    saved = (_PW["removal"], _PW["exempt"])
    _PW["removal"] = base in ("rm", "rmdir", "unlink") or (base == "find" and "-delete" in args)
    _PW["exempt"] = set()
    if base == "mv":
        pos = _moat_positionals(args, {"-S", "--suffix"})
        tdir = _moat_opt_value(args, {"-t", "--target-directory"}, ("--target-directory",))
        _PW["exempt"] = {_moat_abspath(s) for s in (pos if tdir else pos[:-1])}
    if base in ("cp", "mv", "ln", "rsync"):
        _pw_copy_into_skills(base, args, " ".join(raw_words))
    try:
        _pw_base_command(words, raw_words, base, depth, env, piped, stdin_from)
    finally:
        _PW["removal"], _PW["exempt"] = saved
