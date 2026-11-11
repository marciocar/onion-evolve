# Juiz do MODO DE ADOTANTE (2026-11-05, REGRA 118) — escrita em REPO ALHEIO pela sessão de um adotante.
#
# Roda DENTRO do tokenizador de lib/invocation-lines.sh, pelo mesmo ponto de extensão do moat-judge.py: o lib
# executa este arquivo no namespace dele quando ONION_MOAT_JUDGE aponta para cá, e chama `moat_command` a cada
# linha de invocação e `moat_unanalyzable` em cada ponto que não se prova. Os nomes são a INTERFACE do lib, não
# o MOAT: este juiz não lê ops/moat-targets.tsv (core-only) e não sabe de deploy nem de relógio. Ele só existe
# no processo do pretooluse-adopter-guard.sh, então o moat-gate e os vetos de merge seguem idênticos.
#
# ── O QUE ACUSA ──────────────────────────────────────────────────────────────────────────────────────────
#  git   · subcomando que ESCREVE (commit, push, merge, reset, rebase, checkout, stash, tag/branch que criam ou
#          apagam, config que grava…) cujo repositório — `-C`, `--git-dir`, `GIT_DIR`, `cd` literal, ou o cwd do
#          JSON — é um repo REGISTRADO que não é este projeto. Leitura (log, show, diff, status, fetch, worktree
#          list, rev-parse…) passa.
#  shell · redirecionamento (`>`, `>>`), tee, cp/mv/install/rsync/ln (destino), rm/touch/mkdir/truncate/chmod,
#          `sed -i`, `dd of=` com caminho dentro de um repo registrado alheio.
#  opaco · o que o lib não prova (eval, nome de comando em variável…) e que cita um repo registrado junto de um
#          verbo de escrita, na mesma linha: fecha.
# "Registrado" = ONION_ADOPTER_REPOS (o hook resolve pela lib adopter-scope.sh). "Este projeto" = o mesmo
# git-common-dir da raiz, o que inclui as worktrees dele. ONION_ADOPTER_ALLOWS isenta caminhos.
#
# ── O QUE NÃO VÊ (teto) ──────────────────────────────────────────────────────────────────────────────────────
#  · script em arquivo (`bash x.sh` não é lido: é a fronteira do lib, e é por ela que o /meta:co-relay entrega
#    no inbox do core sem commit, e que `bash <core>/ops/pr-merge-verified.sh` roda);
#  · código de outra linguagem em ARQUIVO (`python3 x.py`), git/gh chamados por outro programa, caminho só
#    conhecido em runtime, `gh` escrevendo no repo remoto alheio (a fronteira é o clone local);
#  · clone que nenhuma fonte registra.
import os as _ao
import re as _ar

_ADV_SEP = "\t"
_ADV_REPOS = [p for p in _ao.environ.get("ONION_ADOPTER_REPOS", "").split("\n") if p.startswith("/")]
_ADV_ALLOWS = [_ao.path.realpath(p) for p in _ao.environ.get("ONION_ADOPTER_ALLOWS", "").split("\n") if p.startswith("/")]
_ADV_COMMON = {}

# subcomandos do git que escrevem no repositório ou na árvore de trabalho dele (o mesmo vocabulário do
# moat-judge, menos `init`/`clone`, que criam repo novo: o alvo deles é um caminho, julgado como escrita de shell em
# `_adv_git`, junto com `worktree add`, `--work-tree`/GIT_WORK_TREE e o push para caminho local)
_ADV_GIT_WRITE = {"push", "commit", "merge", "rebase", "reset", "checkout", "switch", "pull", "am", "apply",
                  "cherry-pick", "revert", "stash", "clean", "add", "rm", "mv", "restore", "worktree", "notes",
                  "update-ref", "filter-branch", "filter-repo", "submodule", "symbolic-ref", "replace", "gc",
                  "prune", "remote", "send-pack", "subtree", "update-index", "read-tree", "commit-tree",
                  "fast-import", "repack", "maintenance", "bisect", "sparse-checkout", "lfs"}
_ADV_WRITERS_ALL = {"rm", "rmdir", "touch", "mkdir", "truncate", "chmod", "chown", "chgrp", "unlink", "shred", "tee"}
_ADV_WRITERS_DEST = {"cp", "install", "rsync", "scp", "ln"}
_ADV_VERB = _ar.compile(r"(^|[\s;&|(])(git\b[^\n;&|]*\b(" + "|".join(sorted(_ADV_GIT_WRITE | {"tag", "branch", "config"}))
                        + r")\b|(" + "|".join(sorted(_ADV_WRITERS_ALL | _ADV_WRITERS_DEST | {"mv", "sed", "dd"}))
                        + r")\b)"
                        # código noutra linguagem: só a forma de ESCRITA (abrir para ler um arquivo do core passa)
                        + r'|\bopen\s*\([^)]*,\s*\\?[\'"][wax]|\.write(_text|_bytes)?\s*\('
                        + r'|\b(unlink|rmtree|rename|replace|remove|copyfile|copytree|move)\s*\(')
_ADV_CDS = []            # (profundidade da pilha CWD do lib, caminho): subshell `( )`/`$( )` não vaza o `cd` dele.
                         # `cd <literal>` vistos, absolutos: o lib marca o `cd` CONDICIONAL como DESCONHECIDO (certo para
                         # ISENTAR); para VETAR, `cd .. && cd X && git commit` só roda o commit em X (o mesmo do moat-judge)


def _adv_last_cd():
    """O último `cd` visto NO ESCOPO atual (o da subshell fechada não vale mais), ou None."""
    while _ADV_CDS and _ADV_CDS[-1][0] > len(CWD):
        _ADV_CDS.pop()
    return _ADV_CDS[-1][1] if _ADV_CDS else None


def _adv_emit(cls, target, detail):
    clean = lambda s: " ".join(str(s).split())[:300]
    OUT.append("__ONION_ADOPTER__" + _ADV_SEP + _ADV_SEP.join([cls, clean(target), clean(detail)]))


def _adv_common(d):
    """git-common-dir REAL do repositório que contém `d` (ou do ancestral existente mais próximo); "" fora de repo."""
    while d and not _ao.path.isdir(d):
        d = _ao.path.dirname(d)
    if not d:
        return ""
    if d not in _ADV_COMMON:
        c = _git(["-C", d, "rev-parse", "--path-format=absolute", "--git-common-dir"])
        _ADV_COMMON[d] = _ao.path.realpath(c) if c else ""
    return _ADV_COMMON[d]


def _adv_foreign_map():
    if "m" not in _ADV_COMMON:
        own = _adv_common(_ao.path.realpath(ROOT)) if ROOT else ""
        m = {}
        for r in _ADV_REPOS:
            if not _ao.path.isdir(r):
                continue
            c = _adv_common(_ao.path.realpath(r))
            if c and c != own:
                m.setdefault(c, r)
        _ADV_COMMON["m"] = m
    return _ADV_COMMON["m"]


def _adv_signal_repos():
    """Os registrados que CONTAM como citação num texto opaco: sem o próprio projeto (o registro o lista) e sem os allow."""
    if "s" not in _ADV_COMMON:
        fm = _adv_foreign_map()
        _ADV_COMMON["s"] = [r for r in _ADV_REPOS if _ao.path.isdir(r)
                            and not any(_ao.path.realpath(r) == a or _ao.path.realpath(r).startswith(a.rstrip("/") + "/") for a in _ADV_ALLOWS)
                            and _adv_common(_ao.path.realpath(r)) in fm]
    return _ADV_COMMON["s"]


def _adv_foreign(p):
    """-> o repo registrado alheio que contém o caminho absoluto `p`, ou None."""
    if not p or p == UNKNOWN or not _ao.path.isabs(p):
        return None
    rp = _ao.path.realpath(p)
    for a in _ADV_ALLOWS:
        if rp == a or rp.startswith(a.rstrip("/") + "/"):
            return None
    fm = _adv_foreign_map()
    if not fm or not fm.get(_adv_common(rp)):
        return None
    d = rp                                            # nomeia o repo PELO CAMINHO (a worktree, o clone), não o 1º registrado
    while d and not _ao.path.isdir(d):
        d = _ao.path.dirname(d)
    return _git(["-C", d, "rev-parse", "--show-toplevel"]) or fm[_adv_common(rp)]


def _adv_home(w):
    """`$HOME/x` e `${HOME}/x` valem `~/x`: o HOME do hook é o da sessão (achado 6 do refutador)."""
    return _ar.sub(r"^(\$HOME|\$\{HOME\})(?=/|$)", "~", w) if isinstance(w, str) else w


_adv_base_chdir_target = chdir_target


def chdir_target(c, b):
    """`env -C X`/`--chdir=X`: o lib segue o diretório como `cd` (SAC-390, 2026-11-11, no lugar da leitura própria do B2,
    que ficou morta quando o lib passou a tirar o invólucro antes). Aqui só o que é do adotante: `$HOME/x` vale `~/x`, e
    o `cd -P`/`pushd` que o lib não segue mas este juiz segue serve de base."""
    if b == UNKNOWN and _adv_last_cd():
        b = _adv_last_cd()
    return _adv_base_chdir_target(_adv_home(c), b)


def _adv_abspath(w):
    w = _adv_home(w)
    if not w or DYNAMIC.search(w) or w == "-":
        return None
    w = _ao.path.expanduser(w)
    if _ao.path.isabs(w):
        return _ao.path.normpath(w)
    base = CWD[-1] or JCWD
    if base == UNKNOWN and _adv_last_cd():
        base = _adv_last_cd()
    if base == UNKNOWN:
        return None
    return _ao.path.normpath(_ao.path.join(base, w))


# os arquivos que ARMAM a guarda: a lista e o carimbo (uma edição no `role:` desarmava os dois vetos — refutador,
# achado 9). O update do Onion escreve o carimbo por `git merge` e pelo write-stamp.sh (script em arquivo): passam
_ADV_SELF_TSV = {_ao.path.realpath(x) for x in _ao.environ.get("ONION_ADOPTER_SELF_TSV", "").split("\n") if x}


def _adv_path(w, how, detail, destroys=False):
    p = _adv_abspath(w)
    rp = _ao.path.realpath(p) if p else ""
    # `destroys` (rm, mv, git rm/mv): apagar ou mover um ANCESTRAL do carimbo também o derruba — `rm -rf .claude` e
    # `mv .claude .claude.off` desarmavam as duas guardas (refutador independente, B3, 2026-11-06)
    if p and (rp in _ADV_SELF_TSV or (destroys and any(x.startswith(rp.rstrip("/") + "/") for x in _ADV_SELF_TSV))):
        _adv_emit("lista", p, "%s em %s — %s" % (how, w, detail))
        return
    r = _adv_foreign(p)
    if r:
        _adv_emit("alheio", r, "%s em %s — %s" % (how, w, detail))


def _adv_positionals(args, argopts=()):
    out, k, dd = [], 0, False
    while k < len(args):
        a = args[k]
        if dd or not a.startswith("-") or a == "-":
            out.append(a)
        elif a == "--":
            dd = True
        elif a in argopts and k + 1 < len(args):
            k += 1
        k += 1
    return out


def _adv_git(words, env, detail):
    words = [_adv_home(w) if k > 0 and words[k - 1] == "-C" else
             ("--git-dir=" + _adv_home(w[10:]) if w.startswith("--git-dir=") else w) for k, w in enumerate(words)]
    gw = [_ao.path.expanduser(w) if w.startswith("~") and k > 0 and words[k - 1] == "-C" else
          ("--git-dir=" + _ao.path.expanduser(w[10:]) if w.startswith("--git-dir=~") else w)
          for k, w in enumerate(words)]
    i = 1
    while i < len(gw):
        w = gw[i]
        if w in ("-C", "-c") and i + 1 < len(gw):
            i += 2; continue
        if w.startswith("-"):
            i += 1; continue
        break
    sub = gw[i] if i < len(gw) else ""
    rest = gw[i + 1:]
    lists = any(a in ("-l", "--list", "-a", "--all", "-r", "--remotes", "-v", "-vv", "--contains", "--merged",
                      "--no-merged", "--points-at", "--show-current", "--format") or a.startswith("--format=")
                for a in rest)
    # o ALVO que é caminho (achado 7 do refutador): o repo novo do init/clone, a worktree nova, o --work-tree, o push
    # para um caminho local — julgados como escrita de shell, onde quer que o git rode
    pos = _adv_positionals(rest, {"-b", "-B", "--branch", "-o", "--origin", "--depth", "--reference", "-c",
                                  "--config", "--template", "--separate-git-dir", "-u", "--upload-pack"})
    if sub == "init" and pos:
        _adv_path(pos[0], "git init", detail)
    elif sub == "clone" and len(pos) >= 2:
        _adv_path(pos[1], "git clone", detail)
    elif sub == "worktree" and rest[:1] == ["add"] and len(pos) >= 2:
        _adv_path(pos[1], "git worktree add", detail)
    elif sub in ("push", "send-pack") and pos[:1] and (pos[0].startswith(("/", "~", "./", "../", "file://"))):
        _adv_path(pos[0][7:] if pos[0].startswith("file://") else pos[0], "git %s para caminho local" % sub, detail)
    for w in gw[1:i]:
        if w.startswith("--work-tree=") and sub in _ADV_GIT_WRITE:
            _adv_path(w[12:], "git %s com --work-tree" % sub, detail)
    if "GIT_WORK_TREE" in env and sub in _ADV_GIT_WRITE:
        _adv_path(str(env["GIT_WORK_TREE"]), "git %s com GIT_WORK_TREE" % sub, detail)
    # fetch com refspec <a>:<b> escreve a ref <b> no repo onde roda
    fetch_writes = sub == "fetch" and any(":" in a and not a.startswith(("http", "git@", "ssh:", "file:")) for a in pos[1:])
    # leitura que mora em subcomando de escrita (achado 3): notes list/show, lfs ls-files, sparse-checkout list,
    # clean -n, apply --check, tag -n
    if (sub == "notes" and rest[:1] in (["list"], ["show"])) or (sub == "lfs" and rest[:1] in (["ls-files"], ["status"], ["env"])) \
            or (sub == "sparse-checkout" and rest[:1] == ["list"]) or (sub == "clean" and any(a in ("-n", "--dry-run") for a in rest)) \
            or (sub == "apply" and any(a in ("--check", "--stat", "--numstat", "--summary") for a in rest) and "--apply" not in rest) \
            or (sub == "tag" and any(_ar.match(r"^-n\d*$", a) for a in rest)):
        return
    # vocabulário de baixo nível que escreve (L1 do refutador independente): checkout-index, merge-file, pack-refs,
    # rerere, format-patch (grava os .patch no diretório), hash-object -w, reflog expire/delete
    writes = fetch_writes or sub in _ADV_GIT_WRITE or sub in ("checkout-index", "merge-file", "pack-refs", "rerere", "format-patch") \
        or (sub == "hash-object" and "-w" in rest) or (sub == "reflog" and rest[:1] in (["expire"], ["delete"])) \
        or (sub == "tag" and (_adv_positionals(rest) or any(a in ("-d", "--delete") for a in rest)) and not lists) \
        or (sub == "branch" and not lists and (_adv_positionals(rest) or any(a in ("-d", "-D", "-m", "-M", "-f", "-c", "-C") for a in rest))) \
        or (sub == "config" and _adv_positionals(rest)[1:2] != [] and not any(
            a in ("--get", "--get-all", "--get-regexp", "-l", "--list", "--show-origin") for a in rest))
    if not writes:
        return
    if sub == "stash" and rest[:1] in (["list"], ["show"]):
        return
    if sub == "worktree" and rest[:1] == ["list"]:
        return
    if sub == "remote" and (not rest or rest[:1] in (["-v"], ["show"], ["get-url"])):
        return
    if sub == "submodule" and (not rest or rest[:1] == ["status"]):
        return
    if sub == "bisect" and rest[:1] in (["log"], ["view"], ["visualize"]):
        return
    # o carimbo pelo git (B3): `git rm`/`git mv` dele ou do pai, e `git checkout|restore … -- <carimbo>`. O update do
    # Onion escreve por `git merge`, que não nomeia caminho, e segue passando
    if sub in ("rm", "mv"):
        for a in _adv_positionals(rest):
            _adv_path(a, "git %s" % sub, detail, destroys=True)
    elif sub in ("checkout", "restore") and "--" in rest:
        for a in rest[rest.index("--") + 1:]:
            _adv_path(a, "git %s --" % sub, detail)
    where = git_target(gw, env)
    if where == UNKNOWN and _adv_last_cd() and "-C" not in gw:
        where = _adv_last_cd()
    if where is None or where == UNKNOWN:
        if any(r in detail for r in _adv_signal_repos()):
            _adv_emit("inanalisavel", "(repositório só conhecido em runtime)",
                      "git %s cujo repositório não se prova, num comando que cita um repo registrado — %s" % (sub, detail))
        return
    r = _adv_foreign(_ao.path.normpath(where if _ao.path.isabs(where) else _ao.path.join(JCWD, where)))
    if r:
        _adv_emit("alheio", r, "git %s em %s — %s" % (sub, r, detail))


def moat_unanalyzable(seg, why, whole=False):
    if isinstance(seg, (list, tuple)):
        # o comando de nome dinâmico não chega a `moat_command`: o redirecionamento dele se julga aqui, pelo ALVO
        _adv_redirects([str(x) for x in seg], " ".join(str(x) for x in seg))
    t = " ".join(str(x) for x in seg) if isinstance(seg, (list, tuple)) else str(seg)
    home = _ao.path.expanduser("~")
    for ln in t.split("\n"):
        # o caminho como VALOR (`KG_CORE_DIR=/core`, `--with url=/core`) é leitura de configuração, não alvo; só conta a
        # citação que abre palavra (falsos positivos do replay do kg-ssot, 2026-11-05)
        hit = [r for r in _adv_signal_repos()
               if _ar.search(r"(^|[\s;&|(\"'])(" + _ar.escape(r) + "|~/" + _ar.escape(r[len(home) + 1:]) + r")(?![\w.-])", ln)]
        # código embutido noutra linguagem cita o git como LISTA (`['git','-C',core,'commit']`) ou dentro de string
        # (`os.system('git commit')`): sem aspas, vírgulas e colchetes, o verbo do git aparece (B2 do refutador
        # independente: os dois criavam commit no core com rc 0)
        flat = _ar.sub(r"[\"',\[\]]", " ", ln) if "linguagem" in why else ln
        if hit and (_ADV_VERB.search(ln) or _ADV_VERB.search(flat)):
            _adv_emit("inanalisavel", hit[0], "%s, citando um repo registrado junto de um verbo de escrita — %s" % (why, ln.strip()))
            return


def _adv_raw_scan():
    """Uma vez por comando, no texto CRU: o que o tokenizador parte antes de o juiz ver (B2 do refutador
    independente). `>|` vira `>` e um pipe; `exec 3>arq` some como invólucro. Aproximação por regex: só pesa o
    alvo dentro de repo alheio, então o texto entre aspas que imita a forma é falso positivo raro."""
    if _ADV_COMMON.get("raw") or "raw" not in globals():
        return
    _ADV_COMMON["raw"] = True
    # corpo de heredoc é texto (documentação que cita `>|` não escreve nada): sai antes da varredura
    txt = _ar.sub(r"<<-?\s*(['\"]?)(\w+)\1[^\n]*\n.*?\n[\t]*\2[ \t]*(\n|$)", "\n", raw, flags=_ar.S)
    for m in _ar.finditer(r">\|\s*([^\s;&|<>()]+)|(?:^|[\s;&|(])exec\s+(?:\d*(?:>>?|<>)\s*([^\s;&|<>()]+)\s*)+", txt):
        t = m.group(1) or m.group(2)
        if t:
            _adv_path(t.strip("'\""), "redirecionamento", m.group(0).strip())


# a varredura crua roda ANTES da análise: `exec 3>arq` não chega a `moat_command` (o lib tira o invólucro e o
# redirecionamento, e não sobra comando). O lib chama `analyze` pelo nome global, então o embrulho o alcança
_ADV_ANALYZE = analyze


def analyze(*a, **k):
    _adv_raw_scan()
    return _ADV_ANALYZE(*a, **k)


def moat_command(words, raw_words, base, depth, env, piped, stdin_from):
    detail = " ".join(raw_words)
    _adv_raw_scan()
    _adv_redirects(raw_words, detail)
    args = words[1:]
    # `xargs [-I R] git … <<< <texto>`: com pipe o lib monta o comando; com here-string não (B2)
    if base == "xargs" and "<<<" in words:
        k = words.index("<<<")
        lit, tail = (words[k + 1] if k + 1 < len(words) else ""), words[1:k]
        rep = None
        while tail and tail[0].startswith("-"):
            o = tail.pop(0)
            if o == "-I" and tail:
                rep = tail.pop(0)
            elif o.startswith("-I") and len(o) > 2:
                rep = o[2:]
            elif o in ("-n", "-P", "-d", "-L", "-s", "-E", "-a") and tail:
                tail.pop(0)
        if tail and not DYNAMIC.search(lit):
            for item in lit.split():
                command([x.replace(rep, item) for x in tail] if rep else tail + [item], depth + 1)
        return
    _adv_dispatch(words, base, depth, env, args, detail)


def _adv_redirects(raw_words, detail):
    k = 0
    while k < len(raw_words):                         # redirecionamento de escrita, em qualquer comando
        m = REDIR.match(raw_words[k])
        if m and m.group(2) in (">", ">>", ">|"):
            tgt = m.group(3) or (raw_words[k + 1] if k + 1 < len(raw_words) else "")
            # o lib entrega as palavras SEM as aspas: `grep -E '>>|jsonl'` chega como `>>|jsonl`. Alvo com `|` ou `;`
            # é texto de padrão, não arquivo (falso positivo do replay da curadoria, 2026-11-05)
            if tgt and not tgt.startswith("&") and not _ar.search(r"[|;&<>()]", tgt):
                _adv_path(tgt, "redirecionamento", detail)
        k += 1


def _adv_dispatch(words, base, depth, env, args, detail):
    if base in ("cd", "pushd", "popd"):
        # `cd $T` (mktemp, variável) e `pushd`/`popd` não se seguem: o diretório volta a DESCONHECIDO e o juiz cala.
        # A 1ª redação os pulava, e o `cd <core>` anterior seguia valendo: `cd <core>; …; cd $T; git init; mkdir x`
        # vetava a escrita no temporário (replay do corpus da curadoria, 2026-11-05)
        # `cd -P X`/`cd -L X` e `pushd X` (literal) seguem o diretório; o lib os marca DESCONHECIDO, e para VETAR o
        # que vem depois só roda em X (refutador independente, B2, 2026-11-06)
        dirs = [w for w in words[1:] if not _ar.match(r"^-[PLe@]+$", w)]
        tgt = _adv_home(dirs[0]) if dirs and base in ("cd", "pushd") else None
        if tgt and not DYNAMIC.search(tgt) and tgt != "-" and not (base == "pushd" and _ar.match(r"^[+-]\d+$", tgt)):
            prev = _adv_last_cd() or (CWD[-1] if CWD[-1] not in (None, UNKNOWN) else JCWD)
            _ADV_CDS.append((len(CWD), UNKNOWN if prev == UNKNOWN and not _ao.path.isabs(_ao.path.expanduser(tgt))
                             else _ao.path.normpath(_ao.path.join(prev, _ao.path.expanduser(tgt)))))
        else:
            _ADV_CDS.append((len(CWD), UNKNOWN))
    if base == "eval":                                # o lib só julga o eval pela forma de merge/push
        txt = " ".join(args)
        if DYNAMIC.search(txt):
            moat_unanalyzable(words, "eval de texto só conhecido em runtime")
        else:
            try:
                scoped(txt, depth + 1)
            except Unanalyzable:
                moat_unanalyzable(words, "eval inanalisável")
        return
    if base in RUNNERS:                               # watch/flock/nice… com um escritor depois; su -c com texto
        for j, w in enumerate(args, 1):
            if _ao.path.basename(w) in _ADV_WRITERS_ALL | _ADV_WRITERS_DEST | {"mv", "sed", "dd", "eval"}:
                command(words[j:], depth + 1)
                break
        if base in ("su", "runuser", "script"):
            for j, w in enumerate(args):
                if w in ("-c", "--command") and j + 1 < len(args):
                    try:
                        scoped(args[j + 1], depth + 1)
                    except Unanalyzable:
                        moat_unanalyzable(words, "código embutido inanalisável")
    if base in ("python", "python3", "perl", "ruby", "node", "php") and any(
            _ar.match(r"^-[A-Za-z]*[ce]$", a) or a in ("--command", "--eval") for a in args):
        moat_unanalyzable(words, "código embutido noutra linguagem")
    elif base in ("ssh", "tmux", "screen", "parallel", "make", "busybox"):
        moat_unanalyzable(words, "código embutido noutro executor")
    if base == "git":
        _adv_git(words, env, detail)
    elif base in _ADV_WRITERS_ALL:
        for a in _adv_positionals(args, {"-m", "--mode", "-s", "--size", "-o", "--owner", "-g", "--group", "--reference"}):
            _adv_path(a, base, detail, destroys=base in ("rm", "rmdir", "unlink", "shred"))
    elif base == "mv":
        for a in _adv_positionals(args, {"-t", "--target-directory", "-S", "--suffix"}):
            _adv_path(a, "mv", detail, destroys=True)
        for j, a in enumerate(args):
            if a in ("-t", "--target-directory") and j + 1 < len(args):
                _adv_path(args[j + 1], "mv", detail)
    elif base in _ADV_WRITERS_DEST:
        pos = _adv_positionals(args, {"-t", "--target-directory", "-m", "--mode", "-o", "-g", "-S", "--suffix", "-e",
                                      "--rsh", "-F", "--exclude", "--include", "--filter"})
        tdir = [args[j + 1] for j, a in enumerate(args) if a in ("-t", "--target-directory") and j + 1 < len(args)]
        tdir += [a.split("=", 1)[1] for a in args if a.startswith("--target-directory=")]
        for a in (tdir or pos[-1:]):
            _adv_path(a.split(":", 1)[-1] if base in ("rsync", "scp") and ":" in a and not a.startswith("/") else a,
                      base, detail)
    elif base == "sed" and any(a == "-i" or a.startswith("-i") or a.startswith("--in-place") for a in args):
        pos = _adv_positionals(args, {"-e", "--expression", "-f", "--file", "-l", "--line-length"})
        script_given = any(a in ("-e", "--expression", "-f", "--file") or a.startswith("--expression=") for a in args)
        for a in (pos if script_given else pos[1:]):
            _adv_path(a, "sed -i", detail)
    elif base == "dd":
        for a in args:
            if a.startswith("of="):
                _adv_path(a[3:], "dd", detail)
