#!/usr/bin/env bash
# lib dos vetos PreToolUse — reduz a string do modelo a LINHAS DE INVOCAÇÃO julgáveis.
# Sourced por pretooluse-protect-main.sh e pretooluse-merge-gate.sh; nunca executado só.
#
# ── POR QUE ESTA É A 2ª FORMA DA LIB ───────────────────────────────────────────────────────────
# A 1ª (auditoria D_AUDITAR_GATES_TEXTUAIS, 2026-09-02) normalizava com sed: partia por operador e
# tirava invólucros de uma lista. Em 2026-10-05 o juiz do radar E3 mediu QUINZE formas que ainda
# escapavam dos dois vetos com rc=0 — a pior, o force-push `git push origin +main`, num repo cujo
# host NÃO protege a main (403). O estudo achou mais (heredoc SEM aspas com `$(gh pr merge 1)` no
# corpo EXECUTA o merge; o sed partia texto ENTRE ASPAS no `;`, vetando string literal), e o Elenxo
# da forja achou outras quinze na 1ª versão desta reescrita — quatro delas NOVAS (`#` no meio da
# palavra lido como comentário; `cd` para uma worktree do MESMO remoto isentando o push; `time -p`;
# `$X` sem word-splitting). A lista de formas barradas era menor que a língua do shell: a guarda por
# lista falhando pelo VOCABULÁRIO ([[guarda-por-lista-falha-pelo-vocabulario]]). A 2ª passada do Elenxo
# reprovou de novo, e o achado central não era de vocabulário mas de LUGAR: a lib julgava a partir da raiz
# (`CLAUDE_PROJECT_DIR`) quando o comando roda no `cwd` do JSON — numa worktree de agente, outra branch — e
# isentava "outro projeto" pelo `origin` do diretório em vez do DESTINO do push. A 3ª reprovou a ISENÇÃO
# inteira — o único ramo que faz um veto deixar de vetar: ela isentava por AUSÊNCIA de prova de "nosso"
# (caminho local, remoto com `/`, `cd` não seguido). Agora isenta só com PROVA de estrangeiro.
#
# ── O ESTUDO QUE DECIDIU A FORMA (grafo guard-vetos-por-tokens-2026-10) ─────────────────────────
#  · O Claude Code 2.1.289 analisa comando com tree-sitter e mantém ~145 motivos de RECUSA: o que
#    ele não prova, ele não supõe. Daqui vem a filosofia e o subconjunto do catálogo que importa.
#  · bashlex e tree-sitter-bash NÃO estão instalados aqui nem no CI; um hook que falha fechado sem a
#    dependência travaria a sessão. O `shlex` é da stdlib: o único tokenizador real em todo lugar.
#
# ── O QUE FAZ ──────────────────────────────────────────────────────────────────────────────────
#  0. o comando chega ao Python por DESCRITOR, nunca por argv (argv de 128 KiB+ estoura com E2BIG e o
#     fallback vetaria texto honesto);
#  1. heredoc (opener achado FORA de aspas; delimitador com aspas/`\` = inerte): COM aspas o corpo sai;
#     SEM aspas só as substituições dele sobrevivem; se quem LÊ o heredoc é um SHELL, o corpo é código;
#  2. pré-passadas que respeitam aspas: continuação de linha `\<LF>`; comentário só quando `#` ABRE
#     palavra (no meio, `x#` é texto, como no bash); ANSI-C `$'…'` decodificado; redirecionamento de fd;
#  3. substituições `$(…)`/crase extraídas com scanner que entende aspas e aninhamento;
#  4. shlex parte por `;` `&` `&&` `|` `||` `(` `)` e quebra de linha, e tira as aspas;
#  5. atribuições LITERAIS (`B=main`, `export/declare/local/readonly B=main`, `printf -v B main`) são
#     lembradas; `$X` cujo valor tem espaço é re-partido (word-splitting);
#  6. redirecionamentos, palavras-chave, atribuições e INVÓLUCROS saem (`time -p`, `exec -a x`,
#     `env -S 'cmd'` re-analisado); `sh -c STR` e `bash <<< STR` são re-analisados;
#  7. o diretório inicial é o `cwd` do JSON do hook (ONION_CWD); `cd <literal>` muda o diretório julgado com ESCOPO (`( )`, `$( )`, `sh -c` não vazam) e só quando
#     é INCONDICIONAL e o diretório existe; `pushd`, `cd $X`, `CDPATH=` voltam à raiz (fechado);
#  8. ISENÇÃO só com PROVA de estrangeiro. Push: o destino (`git remote get-url --push`, ou a URL literal)
#     é URL de REDE com slug fora de todos os remotos da raiz; caminho local nunca; `insteadOf` ou remoto
#     por `-c` cancelam; `cd` não seguido = diretório DESCONHECIDO. `gh`: só fora do nosso diretório, e
#     todo repo nomeado (`-R`, `GH_REPO`, URL, `o/r#N`, `repos/o/r`) estrangeiro; API sem slug e GraphQL
#     nunca; `gh` que nomeia o NOSSO repo (`set-default`, `checkout <URL>`) cancela as isenções seguintes;
#  9. `git push` CANÔNICO: `+ref` e `--force*` → `--force`; destino normalizado (`refs/heads/`,
#     `heads/` saem); `HEAD`, `@` e push SEM refspec viram a branch ATUAL — ou o que a CONFIG manda
#     (`remote.<r>.push/mirror`, `push.default=upstream|matching`, também via `-c` e `git config` na
#     string); `--mirror/--all` e `:` → `main`; `send-pack` e `subtree push` são push; `gh` perde
#     `-R/--repo`; `gh api` ganha `--method` efetivo (pflag colado: `-XPUT`, `-fk=v`);
# 10. o que NÃO se prova vira `__ONION_UNANALYZABLE__ merge=M main=N :: <texto>` — o hook decide
#     FECHADO pela forma (merge, ou push que pode tocar a main).
#
# MEDIDO CONTRA O USO REAL (2026-10-05, antes da 2ª passada): os 22.662 comandos Bash únicos de 2.964 transcripts deste repo
# (sessões principais E subagentes), reexecutados contra os hooks antigos e os novos: zero falso
# positivo novo que sobreviva à branch neutra (os vetos novos restantes vêm todos da "branch atual = main"
# no disco de HOJE — corretos hoje), quatro antigos curados. A bancada liga ONION_INVOCATION_STRICT=1 para
# ver bug interno que as camadas absorveriam.
#
# FRONTEIRA DECLARADA (o que continua CONFIANÇA-NO-MODELO, por desenho): script em ARQUIVO
# (`bash x.sh`, `source x`, `curl … | bash`), função/alias definidos FORA da string, variável vinda de
# FORA da string, subprocess de outra linguagem, git/gh chamado por outro programa, `url.*.pushInsteadOf`
# e config global/de sistema. Lista completa no nó C_TETO_FRONTEIRA_DO_QUE_O_HOOK_VE.

onion_invocation_lines() {
  local cmd="$1" root
  root="$(cd "${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}" 2>/dev/null && pwd -P)"
  # Python AUSENTE ou morto: só fecha se o texto tem a FORMA do que os vetos guardam — senão todo
  # comando da sessão seria vetado por falta de motor.
  ONION_ROOT="$root" ONION_CWD="${ONION_CWD:-$PWD}" python3 /dev/fd/4 3<<<"$cmd" 4<<'ONION_TOKENIZER_PY' 2>/dev/null \
    || { printf '%s' "$cmd" | grep -qE 'mergePullRequest|(^|[^[:alnum:]_])gh([^[:alnum:]_][^;&|]*)?[^[:alnum:]_](merge|api)([^[:alnum:]_]|$)|(^|[^[:alnum:]_])git([^[:alnum:]_][^;&|]*)?[^[:alnum:]_]push([^[:alnum:]_]|$)' \
         && printf '__ONION_UNANALYZABLE__ merge=1 main=1 :: %s\n' "$(printf '%s' "$cmd" | tr '\n' ' ' | cut -c1-400)"; }
import os, re, shlex, subprocess, sys, codecs

ROOT = os.environ.get("ONION_ROOT", "")
# o diretório ONDE o comando roda (campo `cwd` do JSON do hook). A raiz (`CLAUDE_PROJECT_DIR`) só dá a
# IDENTIDADE do projeto: numa worktree de agente ela está noutra branch (Elenxo, 2ª passada, B2).
JCWD = os.path.realpath(os.environ.get("ONION_CWD") or os.getcwd())
CONFIG_TAINT = [False]           # `git config remote.*/push.*` na própria string: o push seguinte não se prova
SUBST = "__ONION_SUBST__"
PSUBST = "__ONION_PSUBST__"     # `<(…)`/`>(…)` — distinto de `$(…)` (falso positivo de 2026-10-05)
PSUBST_TEXTS = []
OUT = []
ASSIGN = {}                      # atribuições literais vistas na própria string
TAINTED = set()                  # variáveis cujo valor é uma substituição que calcula a branch PADRÃO
SUBST_DEFAULT = "__ONION_SUBST__D"   # marcador da substituição que calcula a branch PADRÃO (que é a main)
UNKNOWN = "__ONION_UNKNOWN_DIR__"    # `cd` que o analisador não segue: diretório DESCONHECIDO, nunca isento
LAST_CFG = [{}]                  # config de `-c` do último git analisado (decide a isenção pelo destino)
GH_SETDEFAULT = [False]          # `gh repo set-default` na string: o repositório do gh deixa de ser o do diretório
DEFAULT_RE = re.compile(r"symbolic-ref|origin/HEAD|defaultBranchRef|default_branch|init\.defaultBranch")
CWD = [None]                     # pilha do diretório julgado; None = a raiz do projeto

KEYWORDS = {"if", "then", "else", "elif", "fi", "do", "done", "while", "until", "!", "{", "}",
            "case", "esac", "coproc"}
SIMPLE_WRAPPERS = {"command", "nohup", "builtin", "setsid", "unbuffer", "chronic", "noglob", "time"}
WRAPPER_ARG_OPTS = {             # invólucro -> opções que CONSOMEM o argumento seguinte
    "sudo": {"-u", "-g", "-h", "-p", "-C", "-D", "-r", "-t", "-T", "-U", "--user", "--group"},
    "doas": {"-u", "-C"},
    "env": {"-u", "-C", "--unset", "--chdir"},
    "exec": {"-a"},
    "nice": {"-n", "--adjustment"},
    "ionice": {"-c", "-n", "-p", "--class", "--classdata"},
    "stdbuf": {"-i", "-o", "-e"},
    "timeout": {"-s", "-k", "--signal", "--kill-after"},
    "runuser": {"-u", "-g", "-G", "--user", "--group", "--supp-group", "-s", "--shell", "-w", "--whitelist-environment"},
}
DECLARERS = {"export", "declare", "local", "readonly", "typeset"}
SHELLS = {"sh", "bash", "zsh", "dash", "ksh"}
# programas que EXECUTAM outro comando recebido como argumento ou como texto: o que vem depois deles
# é código. Achados pelo Elenxo da forja (`watch gh pr merge 1`, `flock l gh …`, `su -c '…'` …).
RUNNERS = {"watch", "flock", "chrt", "taskset", "strace", "ltrace", "systemd-run", "parallel", "su",
           "script", "trap", "perl", "python", "python3", "ruby", "node", "make", "busybox", "fakeroot",
           "unshare", "nsenter", "firejail", "proot", "ssh", "tmux", "screen", "at", "batch", "crontab"}
TEXT_SINKS = {"echo", "printf", "grep", "egrep", "fgrep", "rg", "ugrep", "cat", "less", "head", "tail",
              "sed", "awk", "wc", "sort", "uniq", "cut", "tr", "jq", "yq", "tee", "diff", "comm", "column",
              "fold", "fmt", "nl", "rev", "printenv", "true", "false", ":", "test", "["}
DYNAMIC = re.compile(r"[$`]|" + SUBST + "|" + PSUBST)
REDIR = re.compile(r"^(\d*|&)(>>?|<|>\|)(.*)$")


class Unanalyzable(Exception):
    pass


# ── helpers de repositório ─────────────────────────────────────────────────────────────────────
_GIT_CACHE = {}


def _git(args, cwd=None):
    """git com CACHE: a mesma pergunta se repetia até 22 vezes num `git push` nu (Elenxo, 3ª passada)."""
    if UNKNOWN in args:
        return ""
    key = (tuple(args), cwd)
    if key not in _GIT_CACHE:
        try:
            _GIT_CACHE[key] = subprocess.run(["git"] + args, cwd=cwd, capture_output=True, text=True,
                                             timeout=5).stdout.strip()
        except Exception:
            _GIT_CACHE[key] = ""
    return _GIT_CACHE[key]


def _slug(url):
    u = re.sub(r"\.git/?$", "", url.strip().rstrip("/"))
    m = re.search(r"[:/]([^/:]+/[^/:]+)$", u)
    return (m.group(1) if m else u).lower()


def same_project(path):
    """`path` está no MESMO projeto que a raiz? Mesmo git-common-dir (worktree), ou mesmo remoto
    `origin` (clone). A 1ª versão comparava só o toplevel, e uma worktree `agent-*` desta casa
    contava como "outro repo" — o push dela isentado mexia na MESMA main (Elenxo, 2026-10-05)."""
    if not path or not ROOT:
        return True
    top = _git(["-C", path, "rev-parse", "--show-toplevel"])
    if not top:
        return True                              # não é repo: truque de invólucro, segue vetado
    if os.path.realpath(top) == os.path.realpath(ROOT):
        return True
    cd_a = _git(["-C", path, "rev-parse", "--path-format=absolute", "--git-common-dir"])
    cd_b = _git(["-C", ROOT, "rev-parse", "--path-format=absolute", "--git-common-dir"])
    if cd_a and cd_b and os.path.realpath(cd_a) == os.path.realpath(cd_b):
        return True
    ua = _git(["-C", path, "config", "--get", "remote.origin.url"])
    ub = _git(["-C", ROOT, "config", "--get", "remote.origin.url"])
    if not ua or not ub:
        return True                              # sem os dois remotos não se PROVA que é outro projeto
    for u in (ua,):                              # clone cujo origin é o caminho da raiz (ou do .git dela)
        if not re.match(r"^[a-z]+://|^[^/]+@", u):
            up = os.path.realpath(u if os.path.isabs(u) else os.path.join(top, u))
            if up in (os.path.realpath(ROOT), os.path.realpath(os.path.join(ROOT, ".git"))):
                return True
    return _slug(ua) == _slug(ub)


def current_branch(path):
    if path == UNKNOWN:
        return "__UNKNOWN__"
    return _git(["-C", path or JCWD, "branch", "--show-current"])


_OUR = {}


def our_slug():
    if "s" not in _OUR:
        u = _git(["-C", ROOT, "config", "--get", "remote.origin.url"]) if ROOT else ""
        _OUR["s"] = _slug(u) if u else ""
    return _OUR["s"]


def our_slugs():
    """Slugs de TODOS os remotos da raiz (fetch e push): um alvo é estrangeiro só se não for nenhum deles."""
    if "all" not in _OUR:
        out = _git(["-C", ROOT, "config", "--get-regexp", r"^remote\..*\.(url|pushurl)$"]) if ROOT else ""
        _OUR["all"] = {_slug(l.split(" ", 1)[1]) for l in out.split("\n") if " " in l}
    return _OUR["all"]


def network_url(u):
    return bool(re.match(r"^[a-z][a-z0-9+.-]*://|^[^/\s]+@[^/\s]+:|^[A-Za-z0-9.-]+\.[A-Za-z]+:[^/]", u or ""))


def slug_is_foreign(slug):
    """Estrangeiro só se PROVADO: a raiz tem remotos conhecidos e o slug não é nenhum deles."""
    mine = our_slugs()
    return bool(slug) and bool(mine) and not DYNAMIC.search(slug) and "{" not in slug and slug.lower() not in mine


def url_is_ours(url):
    """A URL de destino é o NOSSO projeto? Isenta SÓ URL de rede com slug provadamente estrangeiro.
    Caminho local NUNCA isenta: a 2ª forma o resolvia no disco e errava duas vezes — remoto com `/` no
    nome lido como caminho, e projeto cujo próprio origin é um bare em disco (Elenxo, 3ª passada)."""
    if not url or DYNAMIC.search(url) or not network_url(url):
        return True
    return not slug_is_foreign(_slug(url))


def push_dest_ours(where, remote, cfg):
    """O push vai para o NOSSO projeto? Decide pelo DESTINO (o que `git remote get-url --push` devolve, ou
    a URL literal), nunca pelo `origin` do diretório. Sem prova de estrangeiro, é nosso (fechado)."""
    if where == UNKNOWN or (remote and DYNAMIC.search(remote)) or cfg.get("__dyn__"):
        return True
    base = where or JCWD
    # reescrita de URL (`insteadOf`) ou remoto definido por `-c`: o destino real não se lê aqui
    if any(k.startswith("url.") or (k.startswith("remote.") and k.endswith((".url", ".pushurl"))) for k in cfg):
        return True
    if _git(["-C", base, "config", "--get-regexp", r"^url\..*insteadof$"]):
        return True
    name = remote
    if not name:
        cur = current_branch(base)
        for key in (("branch.%s.pushRemote" % cur) if cur else None, "remote.pushDefault",
                    ("branch.%s.remote" % cur) if cur else None):
            if key:
                v = _git(["-C", base, "config", "--get", key])
                if v:
                    name = v; break
        name = name or "origin"
    # o NOME primeiro, mesmo com `/` (`git remote add a/b <url>` é válido)
    urls = [u for u in _git(["-C", base, "remote", "get-url", "--push", "--all", name]).split("\n") if u.strip()]
    if not urls:
        if not network_url(name):
            return True                                    # nem remoto nem URL de rede: não se prova
        urls = [name]
    return any(url_is_ours(u) for u in urls)


# ── pré-passadas que respeitam aspas ───────────────────────────────────────────────────────────
def find_heredoc_openers(line):
    """[(delimitador, inerte?)] dos `<<` FORA de aspas (`echo "<<EOF"` não abre nada)."""
    out, i, n, q, stack = [], 0, len(line), None, []
    while i < n:
        c = line[i]
        if q == '"' and line.startswith("$(", i):
            stack.append(q); q = None; i += 2; continue   # `$(` reabre o contexto: `"$(cat <<'EOF'` É heredoc
        if q is None and stack and c == ")":
            q = stack.pop(); i += 1; continue
        if q:
            if c == q:
                q = None
            elif c == "\\" and q == '"':
                i += 1
            i += 1; continue
        if c in "'\"":
            q = c; i += 1; continue
        if c == "\\":
            i += 2; continue
        if c == "#" and (i == 0 or line[i - 1] in " \t;&|()"):
            break
        if line.startswith("$((", i):                # `$((1<<x))` é SHIFT, não heredoc: pula a aritmética
            depth, j = 0, i + 1
            while j < n:
                if line[j] == "(":
                    depth += 1
                elif line[j] == ")":
                    depth -= 1
                    if depth == 0:
                        break
                j += 1
            i = j + 1; continue
        if line.startswith("<<", i) and not line.startswith("<<<", i):
            j = i + 2
            if j < n and line[j] == "-":
                j += 1
            while j < n and line[j] in " \t":
                j += 1
            # delimitador = a sequência MÁXIMA de não-metacaracteres (`E@F`, `END:`, `E+F`); a 1ª reescrita
            # parava no 1º símbolo e o resto do comando virava corpo (Elenxo, 2ª passada, B7)
            m = re.match(r"""((?:[^\s|&;()<>'"\\]|\\.|'[^']*'|"[^"]*")+)""", line[j:])
            if m:
                word = m.group(1)
                inert = any(ch in word for ch in "'\"\\")
                out.append((re.sub(r"""['"\\]""", "", word), inert))
                i = j + len(word); continue
        i += 1
    return out


SHELL_ON_LINE = re.compile(r"(^|[;&|(]|\s)\s*(\S*/)?(ba|z|da|k)?sh(\s|$)")


def body_substitutions(ln):
    """Substituições de UMA linha de corpo expansível. No corpo as aspas são LITERAIS: `it's $(x)`
    executa `x` — o extrator de linha de comando respeitava o apóstrofo e o perdia (Elenxo, B6)."""
    out, i, n = [], 0, len(ln)
    while i < n:
        if ln[i] == "\\":
            i += 2; continue
        if ln.startswith("$(", i) and not ln.startswith("$((", i):
            j = scan_close(ln, i + 2)
            out.append(ln[i + 2:j - 1]); i = j; continue
        if ln[i] == "`":
            j = ln.find("`", i + 1)
            if j < 0:
                raise Unanalyzable("crase sem fechar no corpo")
            out.append(ln[i + 1:j]); i = j + 1; continue
        i += 1
    return out


def heredocs(text):
    """Corpos de heredoc: inerte → some; expansível → só as substituições; lido por SHELL → código."""
    lines, out, i, pend = text.split("\n"), [], 0, []
    swallowed = []
    while i < len(lines):
        ln = lines[i]
        if pend:
            term, inert, is_code = pend[0]
            if ln.lstrip("\t") == term:
                pend.pop(0)
            elif is_code:
                out.append(ln)                       # `bash <<EOF` executa o corpo
            elif not inert:
                out.extend(body_substitutions(ln))
            swallowed.append(ln)
            i += 1
            continue
        out.append(ln)
        for term, inert in find_heredoc_openers(ln):
            # um SHELL como comando na linha do opener (`bash -s -- x <<E`, `bash /dev/stdin <<E`,
            # `cat <<E | bash`) faz do corpo CÓDIGO; a 1ª regex só aceitava `-letras` (Elenxo, B5)
            # o shell só conta FORA de aspas: `--title "compat com bash 5" --body "$(cat <<'EOF'` não é
            # shell lendo o corpo (falso positivo da 3ª passada do Elenxo, M3)
            bare = re.sub(r"'[^']*'|\"(?:[^\"\\]|\\.)*\"", " ", ln)
            bare = re.sub(r"(^|\s)#.*$", " ", bare)       # nem em comentário (`<<'EOF'  # sobre bash`)
            pend.append((term, inert, bool(SHELL_ON_LINE.search(bare))))
        i += 1
    if pend and relevant(swallowed):
        # heredoc sem terminador: o que sumiu como corpo tem a forma do que os vetos guardam — fechado
        OUT.append("__ONION_UNANALYZABLE__ merge=1 main=1 :: heredoc sem terminador engole: " + " ".join(swallowed)[:300])
    return "\n".join(out)


def prepass(text):
    """Continuação de linha, comentário (`#` abrindo palavra), ANSI-C e redirecionamento de fd —
    tudo FORA de aspas simples. O shlex com `commenters="#"` lia `x#; git push -f origin main` como
    comentário e o push sumia da análise (escape NOVO medido pelo Elenxo)."""
    out, i, n, q = [], 0, len(text), None
    while i < n:
        c = text[i]
        if q == "'":
            out.append(c)
            if c == "'":
                q = None
            i += 1; continue
        if c == "\\" and i + 1 == n:
            i += 1; continue                           # barra solta no FIM: o extrator comeu o \n; o bash a ignora
        if c == "\\" and i + 1 < n:
            if text[i + 1] == "\n":
                i += 2; continue                       # continuação de linha: o bash JUNTA (`m\<LF>ain` = `main`)
            out.append(text[i:i + 2]); i += 2; continue
        if q == '"':
            out.append(c)
            if c == '"':
                q = None
            i += 1; continue
        if c == "'":
            q = "'"; out.append(c); i += 1; continue
        if c == '"':
            q = '"'; out.append(c); i += 1; continue
        if text.startswith("$'", i):                  # ANSI-C: decodifica e re-cita
            j, buf = i + 2, []
            while j < n and text[j] != "'":
                if text[j] == "\\" and j + 1 < n:
                    buf.append(text[j:j + 2]); j += 2
                else:
                    buf.append(text[j]); j += 1
            try:
                val = codecs.decode("".join(buf), "unicode_escape")
            except Exception:
                raise Unanalyzable("ANSI-C ilegível")
            out.append(shlex.quote(val)); i = j + 1; continue
        if c == "#" and (i == 0 or text[i - 1] in " \t\n;&|()"):
            j = text.find("\n", i)
            i = n if j < 0 else j
            continue                                    # comentário DE VERDADE
        m = re.match(r"(\d*[<>]&(\d+|-)|&>>?)", text[i:])
        if m and (i == 0 or text[i - 1] in " \t\n;&|()0123456789"):
            out.append(" "); i += len(m.group(0)); continue
        out.append(c); i += 1
    return "".join(out)


def scan_close(text, i):
    """Acha o `)` que fecha um `$(`, respeitando aspas, escape e `$(` aninhado em aspas duplas."""
    depth, n, quote = 1, len(text), None
    while i < n:
        c = text[i]
        if quote == "'":
            if c == "'":
                quote = None
            i += 1; continue
        if c == "\\":
            i += 2; continue
        if quote == '"':
            if c == '"':
                quote = None
            elif text.startswith("$(", i):
                i = scan_close(text, i + 2); continue
            elif c == "`":
                j = text.find("`", i + 1); i = (j + 1) if j >= 0 else n; continue
            i += 1; continue
        if c == "'":
            quote = "'"
        elif c == '"':
            quote = '"'
        elif c == "(":
            depth += 1
        elif c == ")":
            depth -= 1
            if depth == 0:
                return i + 1
        i += 1
    raise Unanalyzable("$( sem fechar")


def extract_substitutions(text):
    inner, out, i, n, quote = [], [], 0, len(text), None
    while i < n:
        c = text[i]
        if quote == "'":
            out.append(c)
            if c == "'":
                quote = None
            i += 1
            continue
        if c == "\\" and i + 1 < n:
            out.append(text[i:i + 2]); i += 2; continue
        if c == "'" and quote is None:
            quote = "'"; out.append(c); i += 1; continue
        if c == '"':
            quote = None if quote == '"' else '"'; out.append(c); i += 1; continue
        if (text.startswith("$(", i) and not text.startswith("$((", i)) or \
                (quote is None and (text.startswith("<(", i) or text.startswith(">(", i))):
            j = scan_close(text, i + 2)
            inner.append(text[i + 2:j - 1])
            # o marcador entra SEM espaços: `pulls/$(echo 12)/merge` continua UMA palavra (com espaços o
            # caminho se partia e o merge escapava — Elenxo); `<(…)` vira palavra própria
            if text[i] == "$":
                out.append(SUBST_DEFAULT if DEFAULT_RE.search(text[i + 2:j - 1]) else SUBST)
            else:
                PSUBST_TEXTS.append(text[i + 2:j - 1]); out.append(" " + PSUBST + " ")
            i = j; continue
        if c == "`":
            j = text.find("`", i + 1)
            if j < 0:
                raise Unanalyzable("crase sem fechar")
            inner.append(text[i + 1:j]); out.append(SUBST_DEFAULT if DEFAULT_RE.search(text[i + 1:j]) else SUBST)
            i = j + 1; continue
        out.append(c); i += 1
    return "".join(out), inner


# ── palavras ───────────────────────────────────────────────────────────────────────────────────
def resolve(word):
    def sub(m):
        name = m.group(1) or m.group(2)
        return ASSIGN.get(name, m.group(0))
    return re.sub(r"\$\{([A-Za-z_][A-Za-z0-9_]*)\}|\$([A-Za-z_][A-Za-z0-9_]*)", sub, word)


def drop_redirects(words):
    out, k = [], 0
    while k < len(words):
        w = words[k]
        if w in ("<<<",) and k + 1 < len(words):
            out.append("<<<"); out.append(words[k + 1]); k += 2; continue
        if w.startswith("<<"):
            k += 1 if w != "<<" and w != "<<-" else 2; continue
        m = REDIR.match(w)
        if m:
            k += 1 if m.group(3) else 2
            continue
        out.append(w); k += 1
    return out


def strip_prefix(words, env):
    """Tira palavras-chave, atribuições e invólucros; `env` recebe as atribuições de prefixo."""
    while words:
        w = words[0]
        if w in KEYWORDS:
            words = words[1:]; continue
        m = re.match(r"^([A-Za-z_][A-Za-z0-9_]*)=(.*)$", w)
        if m:
            env[m.group(1)] = m.group(2); words = words[1:]; continue
        if w.startswith("\\") and len(w) > 1:
            words = [w[1:]] + words[1:]; continue
        base = os.path.basename(w)
        if base in SIMPLE_WRAPPERS:
            words = words[1:]
            while words and words[0].startswith("-"):
                words = words[1:]
            continue
        if base == "env" and len(words) > 1:
            rest = words[1:]
            while rest and (rest[0].startswith("-") or re.match(r"^[A-Za-z_][A-Za-z0-9_]*=", rest[0])):
                opt = rest[0]; rest = rest[1:]
                if opt in ("-S", "--split-string") and rest:
                    return ["__ONION_RESPLIT__", rest[0]] + rest[1:]
                if opt.startswith("--split-string="):
                    return ["__ONION_RESPLIT__", opt.split("=", 1)[1]] + rest
                if opt.startswith("-S") and len(opt) > 2:
                    return ["__ONION_RESPLIT__", opt[2:]] + rest
                if opt in WRAPPER_ARG_OPTS["env"] and rest:
                    rest = rest[1:]
                elif "=" in opt and not opt.startswith("-"):
                    k, v = opt.split("=", 1); env[k] = v
            words = rest; continue
        if base in WRAPPER_ARG_OPTS:
            argopts = WRAPPER_ARG_OPTS[base]; words = words[1:]
            while words and words[0].startswith("-"):
                opt = words[0]; words = words[1:]
                if DYNAMIC.search(opt):
                    raise Unanalyzable("opção de invólucro só conhecida em runtime")
                if opt in argopts and "=" not in opt and words:
                    if DYNAMIC.search(words[0]):
                        raise Unanalyzable("argumento de invólucro só conhecido em runtime")
                    words = words[1:]
            if base == "timeout" and words:
                if DYNAMIC.search(words[0]):
                    raise Unanalyzable("duração do timeout só conhecida em runtime")
                words = words[1:]
            continue
        return words
    return words


def other_project(path):
    return not same_project(path)


def gh_explicit_slugs(words, env):
    """Repositórios que a linha do gh NOMEIA: `-R`/`--repo`, `GH_REPO`, URL do GitHub posicional
    (`gh pr merge https://github.com/o/r/pull/5` escolhe o repo pela URL — Elenxo, 3ª passada),
    `repos/<o>/<r>` na API e o repo posicional de `gh repo <sub>`. `owner/repo` solto NÃO conta fora de
    `gh repo`: `gh pr merge fix/x` é BRANCH, e lê-la como slug estrangeiro isentaria um merge nosso."""
    out, k = [], 1
    while k < len(words):
        w = words[k]
        if w in ("-R", "--repo") and k + 1 < len(words):
            out.append(words[k + 1]); k += 2; continue
        if w.startswith("--repo="):
            out.append(w.split("=", 1)[1])
        m = re.match(r"^(?:https?://)?(?:www\.)?github\.com[/:]([^/\s]+/[^/\s#?]+)", w) or \
            re.match(r"^git@github\.com:([^/\s]+/[^/\s]+)", w)
        if m:
            out.append(m.group(1))
        m = re.match(r"^([A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+)#\d+$", w)   # `gh pr merge owner/repo#5`
        if m:
            out.append(m.group(1))
        m = re.search(r"(?:^|/)repos/([^/]+/[^/?\s]+)", w)
        if m and "api" in words:
            out.append(m.group(1))
        k += 1
    rest = [w for w in words[1:] if not w.startswith("-")]
    if rest[:1] == ["repo"] and len(rest) >= 3 and re.match(r"^[^/\s]+/[^/\s]+$", rest[2]):
        out.append(rest[2])
    v = env.get("GH_REPO", ASSIGN.get("GH_REPO"))
    if v:
        out.append(v)
    return [re.sub(r"\.git$", "", x).lower() for x in out]


def gh_other_project(words, env):
    """O `gh` mira OUTRO projeto? Só com PROVA: todo repo nomeado é estrangeiro; sem repo nomeado, o
    diretório é outro projeto CONHECIDO e não é chamada de API (a API sem `repos/<slug>` não diz o repo:
    `/repositories/<id>/…` escapava). `gh repo set-default` na string e `GH_HOST` cancelam a isenção."""
    if GH_SETDEFAULT[0] or "GH_HOST" in env or "GH_HOST" in ASSIGN:
        return False
    d = CWD[-1] or JCWD
    if d == UNKNOWN or not other_project(d):
        # do NOSSO diretório nada se isenta, nem com slug "estrangeiro": o GitHub REDIRECIONA nome antigo
        # de repo renomeado (`onion-claude` ≡ `onion-evolve` nesta casa), e o hook não vê o alias
        return False
    slugs = gh_explicit_slugs(words, env)
    if slugs:
        return all(slug_is_foreign(x) for x in slugs)
    return "api" not in words


def git_target(words, env):
    """Repositório que o git vai operar. `--git-dir`/`GIT_DIR` DECIDEM (relativos ao `-C`/cwd); `-C` e o
    `cd` dão o cwd; `--work-tree` NÃO muda o repositório (a 1ª versão o tratava como alvo e isentava
    `git --work-tree=../other push -f origin main`, que empurra o NOSSO repo — Elenxo)."""
    cwd, gitdir, i = CWD[-1] or JCWD, None, 1
    while i < len(words):
        w = words[i]
        if w == "-C" and i + 1 < len(words):
            p = words[i + 1]
            cwd = p if os.path.isabs(p) else (UNKNOWN if cwd == UNKNOWN else os.path.join(cwd, p))
            i += 2; continue
        if w == "-c" and i + 1 < len(words):
            i += 2; continue
        m = re.match(r"^--git-dir=(.+)$", w)
        if m:
            gitdir = m.group(1); i += 1; continue
        if re.match(r"^--work-tree=", w):
            i += 1; continue
        break
    v = env.get("GIT_DIR", ASSIGN.get("GIT_DIR"))
    if v and gitdir is None:
        if DYNAMIC.search(v):
            return None
        gitdir = v
    if gitdir:
        if cwd == UNKNOWN and not os.path.isabs(gitdir):
            return UNKNOWN
        g = gitdir if os.path.isabs(gitdir) else os.path.join(cwd, gitdir)
        return re.sub(r"/\.git/?$", "", g)
    return cwd


def brace_expand(word):
    m = re.search(r"\{([^{}]*)\}", word)
    if not m or ("," not in m.group(1) and ".." not in m.group(1)):
        return [word]
    parts = m.group(1).split(",") if "," in m.group(1) else [m.group(1)]
    out = []
    for p in parts:
        out.extend(brace_expand(word[:m.start()] + p + word[m.end():]))
    return out


PUSH_CFG = re.compile(r"^(remote\.[^=]*\.(push|mirror|pushurl|url)|push\.default|branch\.[^=]*\.(merge|remote|pushremote)|"
                      r"url\.[^=]*\.(pushinsteadof|insteadof))(=|$)", re.I)


def push_dsts_without_spec(where, remote, cfg):
    """Destino de um push SEM refspec. O git consulta a config: `remote.<r>.push`/`mirror` e
    `push.default=upstream|matching` podem mandar a branch para a main (Elenxo, 2ª passada, B8)."""
    base = where or JCWD
    name = remote or "origin"
    def get(key):
        return cfg.get(key.lower()) if key.lower() in cfg else _git(["-C", base, "config", "--get", key])
    if get("remote.%s.mirror" % name) in ("true", "1", "yes", "on"):
        return ["main"]
    cur = current_branch(base)
    if cur == "__UNKNOWN__":
        return ["__DYNAMIC__"]
    mode = (get("push.default") or "simple").lower()
    if mode == "matching":
        return ["main"]
    if mode in ("upstream", "tracking") and cur:
        up = get("branch.%s.merge" % cur)
        return [re.sub(r"^refs/heads/", "", up) if up else cur]
    return [cur or "__HEAD__"]


def dst_of(s, force):
    """Destino canônico de UM refspec (sem o `+`)."""
    if re.search(r"\$\{[^}]*[:=?+-][^}]*\}", s):
        # `${B:-main}`: o `:` é da expansão, não do refspec (Elenxo, B4); o valor-padrão literal conta
        if re.search(r"\$\{[^}]*[:]?[-=]\s*(refs/heads/)?main\s*\}", s):
            return "main"
        s = re.sub(r"\$\{[^}]*\}", "$V", s)
    dst = s.split(":", 1)[1] if ":" in s else s
    return dst


def canonical_git(words, where, env=None):
    """-> (linha canônica, remoto, é-push?); a config de `-c` fica em LAST_CFG para a isenção."""
    i, cfg, dyn_cfg = 1, {}, False
    LAST_CFG[0] = cfg
    while i < len(words):
        w = words[i]
        if w == "-c" and i + 1 < len(words):
            kv = words[i + 1]
            if PUSH_CFG.match(kv):
                if DYNAMIC.search(kv):
                    dyn_cfg = True
                k, _, v = kv.partition("=")
                cfg[k.lower()] = v if _ else "true"
            i += 2; continue
        if w == "-C" and i + 1 < len(words):
            i += 2; continue
        if re.match(r"^--(git-dir|work-tree|namespace|exec-path|config-env)=", w) or \
           w in ("--no-pager", "--bare", "-P", "-p", "--paginate", "--no-replace-objects", "--literal-pathspecs"):
            if w.startswith("--config-env="):
                dyn_cfg = True
            i += 1; continue
        break
    rest = words[i:]
    if not rest:
        return None, None, False
    if env and any(k.startswith("GIT_CONFIG") for k in env):
        dyn_cfg = True
    if dyn_cfg:
        cfg["__dyn__"] = "1"
    if rest[0] == "config":
        if any(PUSH_CFG.match(a) for a in rest[1:]) and not any(a in ("--get", "--get-all", "--get-regexp", "-l", "--list") for a in rest[1:]):
            CONFIG_TAINT[0] = True                          # `git config remote.origin.push …` && git push
        return "git " + " ".join(rest), None, False
    if rest[0] == "subtree" and rest[1:2] == ["push"]:
        pos, k = [], 2
        while k < len(rest):
            a = rest[k]
            if a in ("-P", "--prefix", "-m", "--message") and k + 1 < len(rest):
                k += 2; continue
            if not a.startswith("-"):
                pos.append(a)
            k += 1
        rest = ["push"] + pos[:2]
    send_pack = rest[0] == "send-pack"
    if rest[0] != "push" and not send_pack:
        return "git " + " ".join(rest), None, False
    force, flags, pos, j = False, [], [], 1
    while j < len(rest):
        a = rest[j]
        if a == "--":
            pos += rest[j + 1:]; break
        if a.startswith("--"):
            if a.startswith("--force") or a == "--mirror":
                force = True
            if a in ("--mirror", "--all", "--branches"):
                pos.append("__ALL__")
            if a in ("--repo", "--receive-pack", "--exec", "--push-option") and j + 1 < len(rest):
                j += 1
            if not a.startswith("--force"):
                flags.append(a)
        elif a.startswith("-") and len(a) > 1:
            if "f" in a[1:]:
                force = True
            rf = a.replace("f", "")
            if rf not in ("-", ""):
                flags.append(rf)
            if a == "-o" and j + 1 < len(rest):
                j += 1
        else:
            pos.append(a)
        j += 1
    remote, specs = (pos[0], pos[1:]) if pos and pos[0] != "__ALL__" else ("", pos)
    specs = [e for s in specs for e in brace_expand(s)]   # `{main,feat}`, `ma{in,}`: o bash EXPANDE
    dsts = []
    rname = remote or "origin"
    mv = cfg.get(("remote.%s.mirror" % rname).lower()) if ("remote.%s.mirror" % rname).lower() in cfg \
        else (_git(["-C", where or JCWD, "config", "--get", "remote.%s.mirror" % rname]) if "/" not in rname and ":" not in rname else "")
    if (mv or "").lower() in ("true", "1", "yes", "on"):
        force = True; dsts.append("main")                  # remoto-espelho: todo push é `--mirror` (força)
    if not specs:
        # sem refspec o git consulta a CONFIG; refspec explícito a ignora (`git config branch.x.remote o
        # && git push -u origin feat` era vetado — Elenxo, 3ª passada). O `remote.<r>.push` LITERAL é lido.
        key = ("remote.%s.push" % rname).lower()
        pushcfg = cfg[key] if key in cfg else (_git(["-C", where or JCWD, "config", "--get-all", "remote.%s.push" % rname])
                                              if where != UNKNOWN and "/" not in rname and ":" not in rname else "")
        if dyn_cfg or CONFIG_TAINT[0] or DYNAMIC.search(pushcfg or ""):
            dsts.append("main")                            # refspec de config que não se lê aqui
        elif pushcfg:
            specs = [x for x in pushcfg.split("\n") if x.strip()]
        else:
            dsts += push_dsts_without_spec(where, remote, cfg)
    branch = None
    for s in specs:
        if s == "__ALL__" or s == ":":
            dsts.append("main"); continue
        if s.startswith("+"):
            force = True; s = s[1:]
        dst = dst_of(s, force)
        if dst in ("", "HEAD", "@") or (":" not in s and s in ("HEAD", "@")):
            branch = branch or current_branch(where)
            dst = "__DYNAMIC__" if branch == "__UNKNOWN__" else (branch or "__HEAD__")
        dst = re.sub(r"/{2,}", "/", dst)
        dst = re.sub(r"^(refs/heads/|heads/)", "", dst)
        dst = re.sub(r"[~^][0-9]*$|#.*$", "", dst)          # `main^0`, `main~0`, `main#x`
        if dst.lower() == "main":
            dst = "main"
        elif re.search(r"[*?\[]", dst):
            dst = "main"                                   # glob cobre a main (`refs/heads/*`)
        elif DYNAMIC.search(dst):
            if SUBST_DEFAULT in dst or any(re.search(r"\$\{?" + v + r"\b", dst) for v in TAINTED):
                dst = "main"                               # a substituição calcula a branch PADRÃO
            else:
                dst = "__DYNAMIC__"                        # só conhecido em runtime
        dsts.append(dst)
    # destino runtime: fechado com FORCE ou quando a substituição calcula a branch padrão. SEM force e
    # sem essa marca passa — sentar na main não basta: `for br in fix/a; do git push origin "$br"` era
    # o 2º falso positivo de produção (2026-09-01), reaberto pela 1ª reescrita (Elenxo, 2ª passada).
    if "__DYNAMIC__" in dsts and force:
        dsts = ["main" if d == "__DYNAMIC__" else d for d in dsts]
    if "--dry-run" in flags or "-n" in flags:
        return "git push --dry-run (inerte)", remote, True
    return "git push" + (" --force" if force else "") + "".join(" " + f for f in flags) + \
           (" " + remote if remote else "") + "".join(" " + d for d in dsts), remote, True


def canonical_gh(words):
    rest, i = [], 1
    while i < len(words):
        w = words[i]
        if w in ("-R", "--repo") and i + 1 < len(words):
            i += 2; continue
        if w.startswith("--repo="):
            i += 1; continue
        rest.append(w); i += 1
    if rest[:1] == ["api"]:
        # o gh usa pflag: `-XPUT`, `-X=PUT`, `-fk=v`, `-Fk=v`, `--input=f` são a MESMA opção colada.
        # A 1ª reescrita só via a forma separada e emitia `--method GET -XPUT …` (Elenxo, 2ª passada, B3).
        # O ENDPOINT é o 1º posicional; as regras do gate olham SÓ para ele. A 2ª forma emitia todos os
        # argumentos juntos e `-f body='… /merges …'` (texto de um comentário) casava a rota (Elenxo, 3ª, M5).
        method, fields, k, vals, ep = None, False, 1, [], None
        ARG_OPTS = ("-H", "--header", "-q", "--jq", "-t", "--template", "--cache", "-p", "--preview", "--hostname")
        while k < len(rest):
            a = rest[k]
            if a in ("-X", "--method") and k + 1 < len(rest):
                method = rest[k + 1].upper(); k += 2; continue
            m = re.match(r"^(?:-X=?|--method=)(.+)$", a)
            if m:
                method = m.group(1).upper(); k += 1; continue
            if a in ("-f", "-F", "--field", "--raw-field") and k + 1 < len(rest):
                fields = True; vals.append(rest[k + 1]); k += 2; continue
            m = re.match(r"^(?:-[fF]=?|--field=|--raw-field=)(.+)$", a)
            if m:
                fields = True; vals.append(m.group(1)); k += 1; continue
            if a == "--input" or a.startswith("--input="):
                fields = True
                vals.append("__INPUT__")
                k += 1 if "=" in a else 2; continue
            if a in ARG_OPTS and k + 1 < len(rest):
                k += 2; continue
            if not a.startswith("-") and ep is None:
                ep = a
            k += 1
        method = method or ("POST" if fields else "GET")
        if ep is None:
            ep = "__NOEP__"
        else:
            try:
                from urllib.parse import unquote
                ep = unquote(ep)
            except Exception:
                pass
            ep = re.sub(r"/{2,}", "/", ep.split("?", 1)[0]).rstrip("/") or "/"
            if DYNAMIC.search(ep):
                ep = re.sub(r"(" + SUBST + r"D?|\$\{?[A-Za-z_][A-Za-z0-9_]*\}?)", "__DYN__", ep)
            ep = ep.lower()
        line = "gh api --method " + method + " " + ep + ("" if not vals else " " + " ".join(" ".join(v.split()) for v in vals))
        if ep == "graphql":
            q = " ".join(vals)
            if re.search(r"query=@|query=" + SUBST + r"|__INPUT__", q) or DYNAMIC.search(q):
                line += " __GRAPHQL_OPACO__"               # query de arquivo/variável: conteúdo desconhecido
        return line
    if len(rest) >= 2 and rest[0] == "pr":
        sub = rest[1].lower()
        if "--help" in rest or "-h" in rest:
            return "gh --help pr " + sub + " (inerte)"
        if len(sub) >= 1 and "merge".startswith(sub):
            rest = ["pr", "merge"] + rest[2:]          # `gh pr MERGE`, abreviação
    if rest[:2] == ["repo", "sync"]:
        # `gh repo sync <repo-remoto>` atualiza a branch (padrão: a MAIN) do repo no HOST — com `--force`,
        # reset duro. Sem repo posicional só sincroniza o clone LOCAL (Elenxo, 2ª passada, B8).
        dest, br, k = None, None, 2
        while k < len(rest):
            a = rest[k]
            if a in ("-b", "--branch", "-s", "--source") and k + 1 < len(rest):
                if a in ("-b", "--branch"):
                    br = rest[k + 1]
                k += 2; continue
            if a.startswith("--branch="):
                br = a.split("=", 1)[1]
            elif not a.startswith("-") and dest is None:
                dest = a
            k += 1
        if dest is not None:
            b = "main" if (br is None or br == "main" or DYNAMIC.search(br)) else br
            return "gh repo sync --remote " + dest + " --branch " + b + (" --force" if "--force" in rest else "")
    if rest[:2] == ["alias", "set"] and re.search(r"\bmerge\b", " ".join(rest[2:]), re.I):
        OUT.append("__ONION_UNANALYZABLE__ merge=1 main=1 :: alias do gh definido com merge: " + " ".join(rest))
    return "gh " + " ".join(rest)


def touches_main(text, where=None):
    t = text
    if re.search(r"(^|[\s:/+])(refs/heads/|heads/)?main($|[\s:])|--mirror|--all\b|(^|\s)(HEAD|@)($|\s|:)", t):
        return True
    return current_branch(where) == "main"


def emit_unanalyzable(words, where=None, unknown_target=False):
    t = " ".join(str(w) for w in words) if isinstance(words, (list, tuple)) else str(words)
    t = " ".join(t.split())
    is_merge = bool(re.search(r"mergePullRequest|enablePullRequestAutoMerge|\bmerge\b", t))
    is_push = bool(re.search(r"\bpush\b|updateRef|git/refs", t))
    # destino vindo do STDIN (xargs, shell num pipe) é DESCONHECIDO: conta como main (fechado)
    main = unknown_target or (touches_main(t, where) if (is_push or is_merge) else False)
    OUT.append("__ONION_UNANALYZABLE__ merge=%d main=%d :: %s" % (int(is_merge), int(main), t[:400]))


def relevant(words):
    """Texto INTEIRO inanalisável só importa se tem a FORMA do que os vetos guardam."""
    t = " ".join(words) if isinstance(words, (list, tuple)) else str(words)
    return bool(re.search(r"mergePullRequest|enablePullRequestAutoMerge|\bgh\b[^;&|\n]*\b(merge|api)\b|\bgit\b[^;&|\n]*\bpush\b", t))


def relevant_loose(words):
    """Nome dinâmico/IFS: relevante se um argumento É o verbo (token inteiro), ou se a forma gh/git
    aparece COLADA por separador de IFS (`gh${IFS}pr${IFS}merge`). Substring solta vetava
    `$PYTHON tools/merge.py` e `"$f" --merge` (falsos positivos medidos pelo Elenxo)."""
    if relevant_tokens(words):
        return True
    t = re.sub(r"\$\{?IFS\}?|[,:]", " ", " ".join(words))
    return bool(re.search(r"\b(gh|git)\b.*\b(merge|push)\b", t))


def relevant_tokens(words):
    """Nome de comando DESCONHECIDO: relevante se um argumento É o verbo (token inteiro). `merge` como
    pedaço de caminho (`ops/pr-merge-verified.sh`) não conta — falso positivo NOVO medido pelo Elenxo."""
    return any(w in ("merge", "push", "mergePullRequest", "enablePullRequestAutoMerge") for w in words)


# ── análise ────────────────────────────────────────────────────────────────────────────────────
def analyze(text, depth=0):
    if depth > 4:
        raise Unanalyzable("aninhamento além do teto")
    text = prepass(text)
    text, inners = extract_substitutions(text)
    for inn in inners:
        scoped(inn, depth + 1)
    lex = shlex.shlex(text, posix=True, punctuation_chars=";&|()\n")
    lex.whitespace = " \t\r"; lex.whitespace_split = True; lex.commenters = ""
    try:
        tokens = list(lex)
    except ValueError as e:
        raise Unanalyzable(str(e))
    seg, opened, prev_sep, prev_seg, compound = [], 0, ";", None, 0
    for t in tokens + [";"]:
        if t and set(t) <= set(";&|()\n"):
            if seg:
                # `cd` sob if/while/for/case, depois de `&&`/`||`, ou ANTES de `||` é CONDICIONAL
                first = seg[0]
                if first in ("if", "while", "until", "for", "case", "{"):
                    compound += 1
                cond = prev_sep in ("&&", "||") or t.strip("()").strip("\n") == "||" or compound > 0
                command(seg, depth, cond=cond, piped=prev_sep == "|",
                        stdin_from=prev_seg if prev_sep == "|" else None)
                if seg[-1] in ("fi", "done", "esac", "}") or first in ("fi", "done", "esac", "}"):
                    compound = max(0, compound - 1)
            prev_seg = seg or prev_seg
            seg = []
            if t.strip("()"):
                prev_sep = t.strip("()").strip("\n") or ";"
            for ch in t:
                if ch == "(":
                    CWD.append(CWD[-1]); opened += 1
                elif ch == ")" and opened:
                    CWD.pop(); opened -= 1
        else:
            seg.append(t)


def scoped(text, depth):
    """Subshell, substituição e `sh -c` têm escopo PRÓPRIO de diretório."""
    base = len(CWD)
    CWD.append(CWD[-1])
    try:
        analyze(text, depth)
    finally:
        del CWD[base:]                  # restaura o TAMANHO, nunca `pop` às cegas


def literal_stdin(prev):
    """Se o estágio anterior do pipe é `echo`/`printf` LITERAL, o stdin é conhecido: devolve os tokens."""
    if not prev:
        return None
    w = [x for x in prev]
    if not w or os.path.basename(w[0]) not in ("echo", "printf"):
        return None
    args = [x for x in w[1:] if not re.match(r"^-[neE]+$", x)]
    if any(DYNAMIC.search(x) for x in args):
        return None
    try:
        return shlex.split(" ".join(args).replace("\\n", " "))
    except ValueError:
        return None


def command(seg, depth, cond=False, piped=False, stdin_from=None):
    if all(re.match(r"^[A-Za-z_][A-Za-z0-9_]*=", w) for w in seg):
        for w in seg:
            k, v = w.split("=", 1)
            if not DYNAMIC.search(v):
                ASSIGN[k] = v
            else:
                ASSIGN.pop(k, None)
            (TAINTED.add if SUBST_DEFAULT in v else TAINTED.discard)(k)
        return
    raw_words = [resolve(w) for w in seg]
    rw = [w for w in raw_words if not re.match(r"^[A-Za-z_][A-Za-z0-9_]*=", w)]
    if rw and (os.path.basename(rw[0]) in SHELLS or rw[0] in ("source", ".")) and PSUBST in raw_words:
        # shell/source lendo código de `<(…)`: fecha SÓ se o texto de dentro tem a forma do que os vetos
        # guardam. A 1ª versão disparava com QUALQUER `$(…)` como argumento (`bash x.sh "$(y)"`) e
        # vetou 20 comandos honestos na reexecução do corpus completo.
        if any(relevant([t]) for t in PSUBST_TEXTS):
            OUT.append("__ONION_UNANALYZABLE__ merge=1 main=1 :: shell/source lendo substituição de processo: " + " ".join(seg))
        return
    words = drop_redirects(raw_words)
    if words and words[0] in DECLARERS:
        for w in words[1:]:
            m = re.match(r"^([A-Za-z_][A-Za-z0-9_]*)=(.*)$", w)
            if m:
                if DYNAMIC.search(m.group(2)):
                    ASSIGN.pop(m.group(1), None)
                else:
                    ASSIGN[m.group(1)] = m.group(2)
                (TAINTED.add if SUBST_DEFAULT in m.group(2) else TAINTED.discard)(m.group(1))
        return
    if words[:2] == ["printf", "-v"] and len(words) >= 4:
        if DYNAMIC.search(words[3]):
            ASSIGN.pop(words[2], None)
        else:
            ASSIGN[words[2]] = words[3]
        return
    env = {}
    try:
        words = strip_prefix(words, env)
    except Unanalyzable:
        if relevant_tokens(seg) or relevant([" ".join(seg)]):
            emit_unanalyzable(seg, CWD[-1])
        return
    if not words:
        return
    if words[0] == "__ONION_RESPLIT__":                 # `env -S 'cmd'`
        try:
            words = shlex.split(words[1]) + words[2:]
        except ValueError:
            emit_unanalyzable(seg); return
        words = strip_prefix(words, env)
        if not words:
            return
    if " " in words[0] and not DYNAMIC.search(words[0]):
        try:
            words = shlex.split(words[0]) + words[1:]  # `$X` com espaço: word-splitting do bash
        except ValueError:
            emit_unanalyzable(seg); return
    name = words[0]
    if DYNAMIC.search(name) or re.search(r"\{[^}]*(,|\.\.)[^}]*\}", name):
        if name.endswith("/ops/pr-merge-verified.sh"):
            return                                      # o caminho verificado, chamado por $(…)/ops/…
        if relevant_loose(seg):
            emit_unanalyzable(seg, CWD[-1])
        return
    if ("IFS" in env or "IFS" in ASSIGN) and any("$" in w for w in seg) and relevant_loose(words):
        emit_unanalyzable(list(words) + list(seg), CWD[-1])   # IFS alterado: o word-splitting não se modela
        return
    base = os.path.basename(name)
    if base == "function" and len(words) >= 2:
        rest = [w for w in words[2:] if w not in ("{", "}")]
        if rest:
            command(rest, depth)                        # corpo de função definido na própria string
        return
    if base in ("source", ".") or (base in SHELLS and any(a in ("/dev/stdin", "-") or a.startswith(("/dev/fd/", "/proc/self/fd")) for a in words[1:])):
        if any(a in ("/dev/stdin",) or a.startswith(("/dev/fd/", "/proc/")) or SUBST in a for a in words[1:]) or "<<<" in words:
            if relevant_loose(seg) or piped:
                OUT.append("__ONION_UNANALYZABLE__ merge=1 main=1 :: shell/source lendo código de stdin/fd: " + " ".join(seg))
            return
        return                                          # `source arquivo`: fronteira declarada
    if base == "find":
        for k, w in enumerate(words):
            if w in ("-exec", "-execdir", "-ok", "-okdir") and k + 1 < len(words):
                tail = words[k + 1:]
                end = next((m for m, x in enumerate(tail) if x in (";", "+", "\\;")), len(tail))
                command(tail[:end], depth)
        return
    if base in RUNNERS:
        # o que vem depois é COMANDO (watch gh …) ou TEXTO de código (su -c '…', perl -e '…')
        for k, w in enumerate(words[1:], 1):
            wb = os.path.basename(w)
            if wb in ("git", "gh") or wb in SHELLS:
                command(words[k:], depth)
                break
        if any(relevant([w]) for w in words[1:]):
            emit_unanalyzable(seg, CWD[-1])             # código embutido como texto num executor
        return
    if base == "git" and any(re.match(r"^alias\.", w) or w == "alias" for w in words) \
            and re.search(r"\bpush\b|\bmerge\b", " ".join(words)):
        if "config" in words or any(w.startswith("alias.") for w in words):
            OUT.append("__ONION_UNANALYZABLE__ merge=0 main=1 :: alias do git com push/merge: " + " ".join(words))
            return
    if base in ("cd", "pushd", "popd"):
        # só `cd <literal>` INCONDICIONAL para diretório que EXISTE muda o diretório julgado
        arg = words[1] if len(words) > 1 else ""
        if base == "cd" and arg and not cond and not DYNAMIC.search(arg) and arg != "-" \
                and "CDPATH" not in env and "CDPATH" not in ASSIGN:
            arg = os.path.expanduser(arg)
            b = CWD[-1] or JCWD
            if b == UNKNOWN and not os.path.isabs(arg):
                CWD[-1] = UNKNOWN
            else:
                p = os.path.normpath(arg if os.path.isabs(arg) else os.path.join(b, arg))
                CWD[-1] = p if os.path.isdir(p) else UNKNOWN
        else:
            # `cd` que não se segue (condicional, dinâmico, pushd, `cd -`): o diretório é DESCONHECIDO. A
            # 2ª forma caía no cwd do JSON e, se ele fosse outro projeto, isentava (Elenxo, 3ª passada, M2)
            CWD[-1] = UNKNOWN
        return
    if base in SHELLS:
        args = words[1:]
        for k, w in enumerate(args):
            if re.match(r"^-[A-Za-z]*c[A-Za-z]*$", w) and k + 1 < len(args):
                scoped(args[k + 1], depth + 1)
                return
            if w == "<<<" and k + 1 < len(args):
                scoped(args[k + 1], depth + 1)
                return
        if all(a.startswith("-") for a in args) and piped:
            # shell lendo código do STDIN de um pipe. Fonte LITERAL (`echo '…' | bash`) → o texto é código e
            # se analisa; heredoc (`cat <<E | bash`) já virou código no corpo; fonte opaca (`curl … | bash`)
            # é a mesma fronteira do `bash x.sh` — fecha só se o estágio anterior CITA a forma guardada.
            # A 1ª reescrita fechava SEMPRE e vetava `echo ls | sh` (Elenxo, 2ª passada, M2).
            prev = [resolve(x) for x in (stdin_from or [])]
            if prev and os.path.basename(prev[0]) in ("echo", "printf"):
                a = [x for x in prev[1:] if not re.match(r"^-[neE]+$", x)]
                txt = " ".join(a).replace("\\n", "\n")
                if DYNAMIC.search(txt):
                    if relevant_loose(prev):
                        emit_unanalyzable(prev + seg, CWD[-1], unknown_target=True)
                    return
                scoped(txt, depth + 1)
                return
            if prev and (relevant_loose(prev) or relevant([" ".join(prev)])):
                emit_unanalyzable(prev + seg, CWD[-1], unknown_target=True)
            return
        return                                          # `bash x.sh`: script em ARQUIVO, fronteira
    if base == "eval":
        if relevant_tokens(words) or relevant([" ".join(words)]):
            emit_unanalyzable(words, CWD[-1])
        return
    if base == "xargs":
        tail = words[1:]
        XARGS_ARG = {"-I", "-n", "-P", "-d", "-a", "-E", "-L", "-s"}
        while tail and tail[0].startswith("-"):
            opt = tail[0]; tail = tail[1:]
            if opt in XARGS_ARG and tail:
                tail = tail[1:]
        if not tail:
            return
        tb = os.path.basename(tail[0])
        known = literal_stdin(stdin_from)
        rep_str = None
        for k, w in enumerate(words[1:-1], 1):
            if w == "-I":
                rep_str = words[k + 1]
            elif w.startswith("-I") and len(w) > 2:
                rep_str = w[2:]
        def opaque(x):
            return x is None or (rep_str is not None and rep_str in x)
        if known is not None and tb in ("git", "gh"):
            # stdin CONHECIDO (`echo main | xargs git push origin`): monta o comando concreto e julga
            if rep_str is not None:
                for item in known or [""]:
                    command([x.replace(rep_str, item) for x in tail], depth)
            else:
                command(tail + known, depth)
            return
        if tb in ("git", "gh") and (len(tail) < 2 or opaque(tail[1]) or (tb == "gh" and tail[1] == "pr" and (len(tail) < 3 or opaque(tail[2])))):
            emit_unanalyzable(words, CWD[-1], unknown_target=True); return   # o SUBCOMANDO vem do stdin
        if tb == "git" and "push" in tail:
            forced = any(t.startswith("--force") or t == "--mirror" or (t.startswith("-") and not t.startswith("--") and "f" in t) or t.startswith("+") for t in tail)
            if forced or current_branch(CWD[-1]) == "main":
                emit_unanalyzable(words, CWD[-1], unknown_target=True)
            return                                      # push sem force de destinos do stdin, fora da main
        if tb == "gh" and len(tail) >= 2 and tail[1] == "api" and not any("/" in w for w in tail[2:]):
            emit_unanalyzable(words, CWD[-1]); return
        command(tail, depth)
        return
    if base == "git":
        where = git_target(words, env)
        line, remote, is_push = canonical_git(words, where, env)
        if is_push:
            # isenção pelo DESTINO do push, nunca pelo `origin` do diretório (Elenxo, 2ª passada, B1)
            if where is not None and not push_dest_ours(where, remote, LAST_CFG[0]):
                return
        elif where and other_project(where):
            return
        if line:
            OUT.append(line)
    elif base == "gh":
        if ("repo" in words and "set-default" in words) or \
                any(not slug_is_foreign(x) for x in gh_explicit_slugs(words, env)):
            # `gh repo set-default` ou QUALQUER gh que nomeie o nosso repo (`gh pr checkout <URL nossa>`
            # amarra a branch ao nosso PR): o repo dos `gh` seguintes deixa de ser o do diretório
            GH_SETDEFAULT[0] = True
        # só o gh que PODE mexer na main paga a pergunta ao git (`gh pr view` custava 5 chamadas por hook)
        if re.search(r"\b(merge|api|repo|alias)\b", " ".join(words), re.I) and gh_other_project(words, env):
            return                                      # `cd /outro/projeto && gh pr merge N`
        OUT.append(canonical_gh(words))


raw = os.fdopen(3).read()
if raw.endswith("\n"):
    raw = raw[:-1]
try:
    analyze(heredocs(raw))
except Exception as e:
    if os.environ.get("ONION_INVOCATION_STRICT") == "1" and not isinstance(e, Unanalyzable):
        print("__ONION_BUG__ %s: %s" % (type(e).__name__, e))
    # QUALQUER exceção — inclusive bug deste analisador — passa pelo MESMO critério de forma
    OUT[:] = [l for l in OUT if not l.startswith("__ONION_UNANALYZABLE__")] + \
             [l for l in OUT if l.startswith("__ONION_UNANALYZABLE__")]
    if relevant([raw]):
        emit_unanalyzable(raw)
print("\n".join(OUT))
ONION_TOKENIZER_PY
}
