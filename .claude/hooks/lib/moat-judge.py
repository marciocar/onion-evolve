# moat-judge.py — juiz do MOAT por ALVO, carregado DENTRO do tokenizador de invocation-lines.sh.
# Nunca roda só: o lib o executa (exec) no próprio namespace quando ONION_MOAT_JUDGE aponta para cá,
# e daí ele usa as peças do tokenizador (strip_prefix, git_target, canonical_git, push_dest_ours,
# scoped, heredocs, resolve, ASSIGN, CWD, JCWD, ROOT, UNKNOWN, OUT…). Sem a variável, o lib é o de sempre.
#
# ── POR QUE POR ALVO (decisão D_MOAT_DEPLOY_E_RELOGIO_VIRAM_MECANISMO, selada em 2026-10-12) ──────────
# `rsync`, `systemctl` e `git commit` são legítimos em dezenas de usos que não são deploy. A guarda por
# lista de VERBOS falharia pelo vocabulário ([[guarda-por-lista-falha-pelo-vocabulario]]): ou vetaria
# `systemctl status`, ou deixaria passar `install -m 0644 x /etc/systemd/system/onion-x.service`. A
# assinatura aqui é o OBJETO: a unidade servida, o caminho servido, o repo alheio, o relógio. O verbo só
# decide se o objeto é ESCRITO (status/cat/log/rev-parse passam).
#
# ── AS TRÊS CLASSES (alvos: ops/moat-targets.tsv e docs/evolution/federation/members.yaml) (core-only) ──
#  deploy  · systemctl/service/docker que MUDA uma unidade/container servido; escrita (cp/mv/install/rsync/
#            tee/ln/rm/mkdir/touch/chmod/chown/sed -i/dd/tar -x/unzip/curl -o/redirecionamento) num caminho
#            servido; escrita git (checkout/reset/pull/commit…) numa árvore servida.
#  alheio  · `git push` que muda o ramo de PRODUÇÃO, força ou apaga — num clone que o members.yaml registra
#            (local_path) e que não é este projeto, ou num destino PROVADAMENTE de outro repositório
#            (push_dest_ours, a mesma prova que o merge-gate usa para isentar — aqui ela VETA). Branch de
#            tópico e commit local passam: viram PR no repo alheio, e o PR é o gate de lá.
#  relogio · crontab que instala/edita/remove; at/batch; systemd-run com timer; systemctl que liga um
#            .timer; escrita em /etc/cron*, /var/spool/cron ou num .timer sob systemd/.
#  ato     · (2026-11-05, REGRA 117) a invocação, pela sessão, de um script de ops/ cujo uso É o deploy ou a publicação
#            (linhas `ato script <caminho> <assinatura>` do tsv), com a assinatura do ato nos argumentos (`--apply`,
#            `--push`, `apply`, sem argumento…). O wrapper versionado é fronteira para o ALVO (o que ele escreve por
#            dentro), não para o ATO: deploy, publicação e push de porta são do maestro, que roda pelo `!` no prompt.
#            Ensaio e leitura (`install` sem `--apply`, `--status`, `plan`, `verify`, `--check`) passam.
#  publicacao · (2026-11-05) atos voltados ao público que não passam por script: aprovar ambiente protegido
#            (`POST …/actions/runs/<id>/pending_deployments`, pelo `gh api` ou pelo `curl`), mudar visibilidade,
#            descrição ou tópicos do repo (`gh repo edit`, `PATCH repos/<o>/<r>`, `PUT …/topics`) e empurrar TAG
#            (`refs/tags/…`, `--tags`, `--follow-tags`, nome de tag existente ou criada na própria string). O hook
#            decide a severidade: veto no core, aviso no derivado.
#
# ── A FRONTEIRA (o que segue CONFIANÇA-NO-MODELO) ─────────────────────────────────────────────────────
#  · script VERSIONADO deste projeto (rastreado pelo git) é fronteira: é assim que `bash ops/<wrapper>.sh`
#    passa. Script FORA do projeto, ou não rastreado, é LIDO e julgado (≤ 512 KiB) — o caso de campo de
#    2026-10-13 foi exatamente um script de scratchpad que reiniciava a unidade sem wrapper;
#  · outra linguagem (python/perl/node) só é julgada pela FORMA do texto (alvo + ação no mesmo código; o NOME
#    do motor escritor conta como ação desde a SAC-148). Motor renomeado sem o marcador, e o alvo que chega à
#    string por fora dela (arquivo lido, stdin opaco, `$(…)` calculado), seguem fora — análise estática não fecha
#    indireção arbitrária, e a defesa que resta é a permissão do arquivo (0600 da conta do serviço);
#  · ssh para outra máquina, docker compose, `gh` escrevendo em repo alheio, daemon-reload sem unidade;
#  · os três serviços que servem DIRETO do checkout principal do core (mcp-exec, mcp-kg, mcp-fw) — escrever
#    lá é trabalho normal da casa, e o hook não separa deploy de desenvolvimento nesse caminho.
import fnmatch as _fn

_MOAT_SEP = "\t"
_MOAT_MAX_SCRIPT = 512 * 1024
_MOAT_LINKS = {}          # `ln -s ALVO LINK` visto na própria string: LINK → ALVO (o disco ainda não o tem)
_MOAT_WRITTEN = set()     # todo caminho que a própria string ESCREVE (redirecionamento, cp, tee…), alvo ou não
_MOAT_COPIED = {}         # destino → fonte, de cp/install/mv com UMA fonte: o script copiado se julga pela fonte
_MOAT_CDS = []            # `cd <literal>` vistos, já absolutos: o lib marca o `cd` CONDICIONAL como diretório
                          # DESCONHECIDO (certo para ISENTAR); para VETAR, `cd X && rm y` só roda o rm em X

_MOAT_SYSTEMCTL_ARGOPTS = {"-H", "--host", "-M", "--machine", "-t", "--type", "-p", "--property", "-s", "--signal",
                           "--root", "-n", "--lines", "-o", "--output", "--state", "--kill-whom", "--kill-value",
                           "--job-mode", "--what", "--timestamp", "--message", "--image", "--drop-in", "--when"}
_MOAT_UNIT_MUTATE = {"start", "stop", "restart", "reload", "try-restart", "reload-or-restart", "try-reload-or-restart",
                     "condrestart", "force-reload", "kill", "clean", "freeze", "thaw", "enable", "disable", "reenable",
                     "preset", "mask", "unmask", "link", "revert", "edit", "set-property", "add-wants", "add-requires",
                     "bind", "mount-image", "isolate"}
_MOAT_TIMER_ARM = {"start", "restart", "reload-or-restart", "try-restart", "enable", "reenable", "unmask", "link",
                   "edit", "preset", "add-wants", "add-requires"}
_MOAT_DOCKER_MUTATE = {"restart", "stop", "start", "kill", "rm", "pause", "unpause", "update", "rename"}
_MOAT_GIT_WRITE = {"push", "commit", "merge", "rebase", "reset", "checkout", "switch", "pull", "am", "apply",
                   "cherry-pick", "revert", "stash", "clean", "add", "rm", "mv", "restore", "worktree", "notes",
                   "update-ref", "filter-branch", "filter-repo", "submodule", "symbolic-ref", "replace", "gc",
                   "prune", "init", "clone", "remote", "send-pack", "subtree"}
_MOAT_TIMER_OPTS = ("--on-calendar", "--on-active", "--on-boot", "--on-startup", "--on-unit-active",
                    "--on-unit-inactive", "--on-clock-change", "--on-timezone-change", "--timer-property")
_MOAT_WRITE_ALL = {"tee", "rm", "rmdir", "mkdir", "touch", "truncate", "shred", "unlink", "chmod", "chown", "chgrp",
                   "setfacl", "mv"}
_MOAT_WRITE_DEST = {"cp", "install", "rsync", "scp", "ln"}


def _moat_load():
    tsv = os.environ.get("ONION_MOAT_TARGETS", "")
    units, paths, acts = [], [], {}
    try:
        with open(tsv, encoding="utf-8") as fh:
            for ln in fh:
                if not ln.strip() or ln.lstrip().startswith("#"):
                    continue
                f = ln.rstrip("\n").split("\t")
                if len(f) < 3:
                    continue
                cls, kind, pat = f[0].strip(), f[1].strip(), os.path.expanduser(f[2].strip())
                wrapper = f[3].strip() if len(f) > 3 and f[3].strip() not in ("", "-") else ""
                if kind == "script":                    # classe `ato`: script + assinatura, nunca alvo de escrita
                    if cls == "ato" and wrapper:
                        acts[os.path.normpath(pat)] = set(x.strip() for x in wrapper.split(",") if x.strip())
                    continue
                (units if kind == "unit" else paths).append((cls, pat, wrapper))
    except OSError:
        pass
    members = []
    mpath = os.environ.get("ONION_MOAT_MEMBERS", "")
    try:
        cur = {}
        with open(mpath, encoding="utf-8") as fh:
            for ln in fh:
                m = re.match(r"^\s*-\s+id:\s*['\"]?([^'\"#\s]+)", ln)
                if m:
                    if cur.get("path"):
                        members.append(cur)
                    cur = {"id": m.group(1)}
                    continue
                m = re.match(r"^\s+kind:\s*([A-Za-z_-]+)", ln)
                if m and cur:
                    cur["kind"] = m.group(1)
                m = re.match(r"^\s+local_path:\s*['\"]?([^'\"#\s]+)", ln)
                if m and cur:
                    cur["path"] = os.path.expanduser(m.group(1))
        if cur.get("path"):
            members.append(cur)
    except OSError:
        pass
    members = [x for x in members if x.get("kind") != "source"]
    # o RELÓGIO não depende da máquina: sem o tsv (adotante, 2026-11-05) os caminhos de agendamento do sistema valem
    # assim mesmo. Com o tsv, as linhas `relogio path` dele mandam
    if not any(c == "relogio" for c, _, _ in paths):
        paths += [("relogio", "/etc/cron*", ""), ("relogio", "/var/spool/cron", ""), ("relogio", "/etc/anacrontab", "")]
    return units, paths, members, acts


MOAT_UNITS, MOAT_PATHS, MOAT_MEMBERS, MOAT_ACTS = _moat_load()


# ── ATOS DELEGADOS (2026-11-13, D_DELEGATE_FOREIGN_MERGE_VERIFIED_1113, D_DELEGATE_SITE_DEPLOY_AFTER_VERIFIED_MERGE_1113,
#    D_DELEGATE_VPS_SERVICE_SCRIPTS_1113) ────────────────────────────────────────────────────────────────────────────
# O maestro selou três delegações: o ato que o veto barrava passa a ser da sessão, numa FORMA exata, e as condições que o
# hook não mede (CI verde, resíduo, refutador) moram no próprio script, que recusa quando falta uma. Linhas do tsv:
#   delega  script  <ops/x.sh>  <marcador>  <palavras da assinatura cobertas>  (core-only)
# O marcador é uma flag literal na linha (`--foreign-repo`, `--verified-pr`) ou `@rootcopy=<dir>`: o script invocado
# é a cópia em <dir> (a do sudoers sem senha, D_DELEGATE_VPS_SERVICE_SCRIPTS_1113), byte a byte a deste checkout. Passa
# só quando TODA palavra da assinatura presente está coberta: `slack-persona.sh creds` pela cópia segue vetado.
# A publicação das portas (`publish-door.sh --push`) não tem linha `delega` (D_DOOR_PUBLISH_STAYS_WITH_MAESTRO_1113).
# QUEM É O CORE é uma CONSTANTE (4ª passada do refutador do #1647): o members.yaml é da sessão (Edit, sed, e o commit
# também), e trocar o `remote:` do membro `kind: source` fazia o merge alheio passar como merge do core. O registro só
# se confere contra ela; divergiu, nenhuma forma delegada vale (MOAT_MEMBERS_DIVERGE). (core-only)
_MOAT_CORE_SLUG = "marciocar/onion-evolve"


def _moat_load_delegations():
    deleg, self_slugs = {}, set()
    try:
        with open(os.environ.get("ONION_MOAT_TARGETS", ""), encoding="utf-8") as fh:
            for ln in fh:
                if not ln.strip() or ln.lstrip().startswith("#"):
                    continue
                f = [x.strip() for x in ln.rstrip("\n").split("\t")]
                if len(f) >= 5 and f[0] == "delega" and f[1] == "script" and f[3] and f[4] not in ("", "-"):
                    deleg.setdefault(os.path.normpath(f[2]), []).append(
                        (f[3], set(x.strip() for x in f[4].split(",") if x.strip())))
    except OSError:
        pass
    # o repo DESTE projeto (o membro `kind: source`): `--repo` com ele não é merge alheio
    try:
        cur = {}
        with open(os.environ.get("ONION_MOAT_MEMBERS", ""), encoding="utf-8") as fh:
            for ln in list(fh) + ["- id: __fim__\n"]:
                if re.match(r"^\s*-\s+id:", ln):
                    if cur.get("kind") == "source" and cur.get("remote"):
                        self_slugs.add(cur["remote"])
                    cur = {}
                    continue
                m = re.match(r"^\s+kind:\s*([A-Za-z_-]+)", ln)
                if m:
                    cur["kind"] = m.group(1)
                m = re.match(r"^\s+remote:\s*['\"]?([^'\"#\s]+)", ln)
                if m:
                    cur["remote"] = _moat_slug(m.group(1))
    except OSError:
        pass
    diverge = bool(self_slugs) and self_slugs != {_moat_slug(_MOAT_CORE_SLUG)}
    return deleg, {_moat_slug(_MOAT_CORE_SLUG)}, diverge


def _moat_slug(v):
    v = re.sub(r"^(git@[^:]+:|ssh://git@[^/]+/|https?://([^@/]+@)?[^/]+/|github\.com/)", "", str(v).strip())
    return re.sub(r"\.git$", "", v).strip("/").lower()


MOAT_DELEG, MOAT_SELF_SLUGS, MOAT_MEMBERS_DIVERGE = _moat_load_delegations()


def _moat_rootcopy(p):
    """-> (rel, "ok"|"stale") se `p` é a cópia de root delegada de um script de ops/, ou None. (core-only)"""
    if not p or not MOAT_DELEG or not ROOT:
        return None
    rp = os.path.realpath(p)
    for rel, forms in MOAT_DELEG.items():
        for marker, _ in forms:
            if not marker.startswith("@rootcopy="):
                continue
            d = os.path.normpath(os.path.expanduser(marker.split("=", 1)[1]))
            if os.path.dirname(rp) == d and os.path.basename(rp) == os.path.basename(rel):
                mine = _moat_act_digest(os.path.join(ROOT, rel))
                return rel, ("ok" if mine and _moat_act_digest(rp) == mine else "stale")
    return None


# Os marcadores de flag se julgam pela GRAMÁTICA do script, não pela presença do token (refutador do #1647, B1/B2): o token
# solto casava em `--foreign-repo=0`, como VALOR de `--motivo`, e dentro de `<<< --foreign-repo` (stdin, não argv), e
# em todos o merge alheio rodava sem o gate. Marcador que o juiz não conhece não delega (fecha).
_PMV_VALUE_FLAGS = {"--repo", "--dispensa", "--motivo", "--assert-ancestor"}
_PMV_NO_DELEG = {"--dispensa", "--ci-inoperante", "--allow-draft", "--maestro"}


def _moat_marker_ok(marker, args):
    if any(DYNAMIC.search(a) for a in args):
        return False                                    # um argumento só conhecido em runtime pode deslocar a gramática
    if marker == "--verified-pr":                       # ops/deploy-site.sh deploy --verified-pr <N>, posição exata (core-only)
        return len(args) == 3 and args[0] == "deploy" and args[1] == "--verified-pr" and args[2].isdigit()
    if marker == "--foreign-repo":                      # ops/pr-merge-verified.sh <N> ... --foreign-repo, a palavra nua (core-only)
        if not args or not args[0].isdigit():
            return False
        seen, k = False, 1
        while k < len(args):
            a = args[k]
            if a in _PMV_NO_DELEG or a.split("=", 1)[0] in _PMV_NO_DELEG:
                return False
            if a in _PMV_VALUE_FLAGS:
                k += 2
                continue
            if a == "--foreign-repo":
                seen = True
            elif a.startswith("--foreign-repo"):
                return False
            k += 1
        return seen
    return False


# (5ª passada do refutador do #1647, item 1 da decisão do maestro de 2026-11-13) A FORMA DELEGADA roda o que foi
# revisado: o script invocado e a cerca (este juiz, o tokenizador, o hook e o tsv) têm de ser byte a byte os de
# origin/main. Um Edit de `verified_gate() { return 0;` ou da constante do core, na árvore e sem PR, não é a forma
# selada. A mesma régua do @rootcopy. TETO: a ref origin/main é da sessão também (update-ref); a fronteira real é outro
# usuário do sistema. (core-only)
_MOAT_MAIN_PINNED = (".claude/hooks/pretooluse-moat-gate.sh", ".claude/hooks/lib/moat-judge.py",
                     ".claude/hooks/lib/invocation-lines.sh", "ops/moat-targets.tsv")  # (core-only)


def _moat_blob(path):
    return _git(["--no-replace-objects", "hash-object", "--", path]) if path and os.path.isfile(path) else ""


# A PONTA DA MAIN se mede no REMOTO, por URL constante (6ª passada do refutador do #1647): a ref origin/main local é da
# sessão (update-ref, fetch de outro lugar, escrita no arquivo da ref). `git ls-remote <URL> refs/heads/main` dá o sha, e
# o objeto tem de existir aqui (`cat-file -e`). Sem rede, ou sem o objeto, a forma delegada não vale (fecha). (core-only)
_MOAT_CORE_URL = "https://github.com/marciocar/onion-evolve"


def _moat_lsremote():
    # isolado da config do git (7ª passada): cwd=/, sem config global nem de sistema, sem GIT_* do ambiente, e só
    # https. Sem isso, um insteadOf no .git/config (escrito por Edit) desviava a URL constante
    _env = {k: v for k, v in os.environ.items() if not k.startswith("GIT_")}
    _env.update(GIT_CONFIG_GLOBAL="/dev/null", GIT_CONFIG_NOSYSTEM="1")
    try:
        return subprocess.run(["git", "-c", "protocol.allow=never", "-c", "protocol.https.allow=always",
                               "ls-remote", _MOAT_CORE_URL, "refs/heads/main"],
                              cwd="/", env=_env, capture_output=True, text=True, timeout=10).stdout.strip()
    except Exception:
        return ""


def _moat_main_sha():
    if "main" not in _OUR:
        sha = ""
        out = _moat_lsremote()
        m = re.match(r"^([0-9a-f]{40})\s+refs/heads/main$", out.split("\n")[0]) if out else None
        if m and ROOT and subprocess.run(["git", "--no-replace-objects", "-C", ROOT, "cat-file", "-e", m.group(1) + "^{commit}"],
                                         capture_output=True).returncode == 0:
            sha = m.group(1)
        _OUR["main"] = sha
    return _OUR["main"]


def _moat_main_blob(rel):
    sha = _moat_main_sha()
    # --no-replace-objects (8ª passada): um `git replace <main> <forjado>` trocava a árvore que a régua lê
    return _git(["--no-replace-objects", "-C", ROOT, "rev-parse", "-q", "--verify", sha + ":" + rel]) if ROOT and sha else ""


def _moat_matches_main(script, rel):
    if not ROOT or not _moat_main_sha():
        return False
    pairs = [(script, rel)] + [(os.path.join(ROOT, r), r) for r in _MOAT_MAIN_PINNED]
    return all(_moat_blob(p) == _moat_main_blob(r) for p, r in pairs)


def _moat_delegated(rel, words, args, rootcopy):
    """True se as palavras da assinatura presentes (`words`) estão todas cobertas por uma forma delegada satisfeita."""
    if MOAT_MEMBERS_DIVERGE:
        return False                                    # o registro diz outro core: nada se delega até ele voltar
    for marker, verbs in MOAT_DELEG.get(rel, []):
        if not words <= verbs:
            continue
        if marker.startswith("@rootcopy="):
            if rootcopy == "ok":
                return _moat_matches_main(_MOAT_CUR.get("script"), rel)
        elif _moat_marker_ok(marker, args):
            return _moat_matches_main(_MOAT_CUR.get("script"), rel)
    return False


def _moat_delegated_hint(rel):
    out = []
    for marker, verbs in MOAT_DELEG.get(rel, []):
        if marker.startswith("@rootcopy="):
            out.append("sudo %s/%s (a cópia de root do sudoers, conferida por sha256), cobrindo %s"
                       % (marker.split("=", 1)[1].rstrip("/"), os.path.basename(rel), ", ".join(sorted(verbs))))
        else:
            out.append("%s com %s, que confere as condições do selo antes de agir" % (rel, marker))
    return ("; DELEGADO à sessão só por: " + " · ".join(out) + " (o script e a cerca byte a byte os de origin/main)") if out else ""


def _moat_emit(cls, target, wrapper, detail):
    clean = lambda s: " ".join(str(s).split())[:300]
    OUT.append("__ONION_MOAT__" + _MOAT_SEP + _MOAT_SEP.join([cls, clean(target), wrapper or "-", clean(detail)]))


def _moat_dir():
    return CWD[-1] or JCWD


def _moat_abspath(w, base=None):
    """Caminho absoluto de uma palavra, ou None se não se prova (dinâmico, diretório desconhecido)."""
    if not w or DYNAMIC.search(w) or w == "-":
        return None
    w = os.path.expanduser(w)
    base = base or _moat_dir()
    if base == UNKNOWN and _MOAT_CDS:
        base = _MOAT_CDS[-1]
    if not os.path.isabs(w):
        if base == UNKNOWN:
            return None
        w = os.path.join(base, w)
    p = os.path.normpath(w)
    for link, target in _MOAT_LINKS.items():           # link criado na própria string
        if p == link or p.startswith(link.rstrip("/") + "/"):
            p = os.path.normpath(target + p[len(link):])
    return p


_moat_base_chdir_target = chdir_target


def chdir_target(c, b):
    """`env -C D`: o juiz de ESCRITA segue a pasta literal mesmo que ela só nasça em runtime, como já segue o `cd`
    (`mkdir -p .claude/skills/y && env -C .claude/skills/y mkdir hooks` grava, e a regra estrita do lib a perdia —
    passada adversarial de SAC-390). Os vetos de merge e force-push não carregam este juiz e ficam com a estrita."""
    t = _moat_base_chdir_target(c, b)
    if t != UNKNOWN or DYNAMIC.search(c):
        return t
    c = os.path.expanduser(c)
    if b == UNKNOWN:
        b = _MOAT_CDS[-1] if _MOAT_CDS else UNKNOWN
    if os.path.isabs(c):
        return os.path.normpath(c)
    return UNKNOWN if b == UNKNOWN else os.path.normpath(os.path.join(b, c))


def _moat_candidates(p):
    """O caminho como escrito e o REAL (symlink já no disco), cada um com seus ancestrais."""
    out = []
    for q in {p, os.path.realpath(p)}:
        c = q
        while True:
            out.append(c)
            parent = os.path.dirname(c)
            if parent == c:
                break
            c = parent
    return out


def _moat_path_match(p, classes=("deploy", "relogio")):
    """-> (classe, padrão, wrapper) do alvo mais ESPECÍFICO que contém o caminho, ou None."""
    if not p:
        return None
    best = None
    cands = _moat_candidates(p)
    for cls, pat, wrapper in MOAT_PATHS:
        if cls not in classes:
            continue
        if any(_fn.fnmatchcase(c, pat) for c in cands):
            if best is None or len(pat) > len(best[1]):
                best = (cls, pat, wrapper)
    # relógio pelo SUFIXO: um .timer sob qualquer systemd/ arma um agendamento
    if "relogio" in classes and any(c.endswith(".timer") and "/systemd/" in c for c in cands[:1] + [os.path.realpath(p)]):
        return ("relogio", p, "")
    return best


def _moat_unit_match(u):
    if not u or DYNAMIC.search(u):
        return None
    name = os.path.basename(u)
    name = re.sub(r"\.service$", "", name)
    if re.search(r"[*?\[]", name):                     # glob na linha de comando: veta se pode cobrir um alvo
        pre = re.split(r"[*?\[]", name, 1)[0]
        for cls, pat, wrapper in MOAT_UNITS:
            ppre = re.split(r"[*?\[]", pat, 1)[0]
            if ppre.startswith(pre) or pre.startswith(ppre):
                return (cls, pat, wrapper)
        return None
    best = None
    for cls, pat, wrapper in MOAT_UNITS:
        if _fn.fnmatchcase(name, pat) and (best is None or len(pat.replace("*", "")) > len(best[1].replace("*", ""))):
            best = (cls, pat, wrapper)
    return best


def _moat_member(p):
    if not p or p == UNKNOWN:
        return None
    for q in {p, os.path.realpath(p)}:
        for m in MOAT_MEMBERS:
            mp = os.path.normpath(m["path"])
            if q == mp or q.startswith(mp.rstrip("/") + "/"):
                return m
    return None


def _moat_positionals(args, argopts=()):
    out, k, ended = [], 0, False
    while k < len(args):
        a = args[k]
        if ended or not a.startswith("-") or a == "-":
            out.append(a)
        elif a == "--":
            ended = True
        elif a in argopts and k + 1 < len(args):
            k += 1
        k += 1
    return out


def _moat_opt_value(args, shorts, longs):
    for k, a in enumerate(args):
        if a in shorts and k + 1 < len(args):
            return args[k + 1]
        for lo in longs:
            if a.startswith(lo + "="):
                return a.split("=", 1)[1]
    return None


def _moat_write_path(p, detail, verb="escrita", creates=True):
    # só o que CRIA conteúdo entra em _MOAT_WRITTEN (o script nascido na própria string); `chmod +x x.sh` e
    # `sed -i` não criam — a 1ª redação os contava e fechava `chmod +x x.sh && bash x.sh` (corpus)
    if p and creates:
        _MOAT_WRITTEN.add(p)
    hit = _moat_path_match(p)
    if hit:
        cls, pat, wrapper = hit
        _moat_emit(cls, p, wrapper, "%s em %s — %s" % (verb, pat, detail))


def _moat_sed_delim_end(s, j, d):
    """Índice depois do delimitador `d` não escapado a partir de `j` (o fim do texto, se não fecha)."""
    while j < len(s):
        if s[j] == "\\":
            j += 2; continue
        if s[j] == d:
            return j + 1
        j += 1
    return len(s)


def _moat_sed_script_writes(s):
    """Os arquivos que um script de sed GRAVA: o comando `w`/`W` e a flag `w` do `s///`. O nome vai até o fim da
    linha, como no GNU sed. SAC-390 (2026-11-11): `sed -n 'w .claude/skills/x/hooks/h'` passava com rc 0. Erra para
    CALAR: o que não se lê não acusa, e o caminho só acusa se tiver a forma guardada."""
    out, i, n = [], 0, len(s)

    def eol(j):
        e = s.find("\n", j)
        return n if e < 0 else e

    def name_at(j):
        while j < n and s[j] in " \t":
            j += 1
        e = eol(j)
        f = s[j:e].strip()
        if f and f not in ("/dev/stdout", "/dev/stderr"):
            out.append(f)
        return e

    def addr(j):
        if j < n and s[j] == "/":
            j = _moat_sed_delim_end(s, j + 1, "/")
        elif j + 1 < n and s[j] == "\\":
            j = _moat_sed_delim_end(s, j + 2, s[j + 1])
        elif j < n and s[j] == "$":
            return j + 1
        else:
            while j < n and (s[j].isdigit() or s[j] in "~+"):
                j += 1
            return j
        while j < n and s[j] in "IM":                     # flags do endereço por regex
            j += 1
        return j

    while i < n:
        if s[i] in " \t\n;{}!":
            i += 1; continue
        if s[i] == "#":
            i = eol(i); continue
        i = addr(i)
        while i < n and s[i] in " \t":
            i += 1
        if i < n and s[i] == ",":
            i += 1
            while i < n and s[i] in " \t":
                i += 1
            i = addr(i)
        while i < n and s[i] in " \t!":
            i += 1
        if i >= n:
            break
        c = s[i]
        if c in "wW":
            i = name_at(i + 1)
        elif c in "s":
            if i + 1 >= n:
                break
            d = s[i + 1]
            i = _moat_sed_delim_end(s, i + 2, d)
            i = _moat_sed_delim_end(s, i, d)
            while i < n and s[i] not in ";\n}":
                if s[i] == "w":
                    i = name_at(i + 1); break
                i += 1
        elif c == "y":
            if i + 1 >= n:
                break
            d = s[i + 1]
            i = _moat_sed_delim_end(s, _moat_sed_delim_end(s, i + 2, d), d)
        elif c in "aic":                                   # texto até o fim da linha, e as linhas que a `\` continua
            e = eol(i)
            while e < n and s[e - 1:e] == "\\":
                e = eol(e + 1)
            i = e
        elif c in "rRe:":                                  # nome de arquivo, comando ou rótulo até o fim da linha
            i = eol(i)
        elif c in "btT":
            j = i + 1
            while j < n and s[j] not in ";\n":
                j += 1
            i = j
        else:
            i += 1
    return out


def _moat_sed_writes(args):
    """Os arquivos que `sed <args>` grava pelo SCRIPT (não pelo `-i`). `--sandbox` recusa o `w`: nada."""
    if "--sandbox" in args:
        return []
    scripts, pos, k, explicit = [], [], 0, False
    while k < len(args):
        a = args[k]
        if a == "--":
            pos += args[k + 1:]; break
        if a in ("-e", "--expression") and k + 1 < len(args):
            scripts.append(args[k + 1]); explicit = True; k += 2; continue
        if a.startswith("--expression="):
            scripts.append(a.split("=", 1)[1]); explicit = True; k += 1; continue
        if a in ("-f", "--file", "-l", "--line-length") and k + 1 < len(args):
            explicit = explicit or a in ("-f", "--file"); k += 2; continue
        if a.startswith("--file="):
            explicit = True; k += 1; continue
        if a.startswith("--"):
            k += 1; continue
        if a.startswith("-") and len(a) > 1:
            body, used = a[1:], 0
            for idx, ch in enumerate(body):
                if ch in "efl":                            # o resto da palavra, ou a palavra seguinte, é o valor
                    val = body[idx + 1:]
                    if not val and k + 1 < len(args):
                        val = args[k + 1]; used = 1
                    if ch == "e":
                        scripts.append(val)
                    explicit = explicit or ch in "ef"
                    break
                if ch == "i":                              # `-i[SUFIXO]`: o resto é o sufixo
                    break
            k += 1 + used; continue
        pos.append(a); k += 1
    if not explicit and pos:
        scripts.append(pos[0])
    return [f for s in scripts for f in _moat_sed_script_writes(s)]


def _moat_redirects(raw_words, detail):
    k = 0
    while k < len(raw_words):
        m = REDIR.match(raw_words[k])
        if m and m.group(2) in (">", ">>", ">|"):
            tgt = m.group(3) or (raw_words[k + 1] if k + 1 < len(raw_words) else "")
            if not tgt.startswith("&"):
                _moat_write_path(_moat_abspath(tgt), detail, "redirecionamento")
        k += 1


# ── relevância para o que NÃO se prova (nome dinâmico, eval, código noutra linguagem, script ilegível) ──
# Dois pares (sinal, ação), julgados NA MESMA LINHA: a 1ª redação casava sinal e ação em qualquer lugar do texto e,
# no corpus (2026-10-13), um script grande que CITAVA o caminho de um clone de porta numa linha e `cp` noutra fechava.
# O membro só pesa junto de `push`: commit local num clone de adotante não é veto (ver _moat_git).
def _moat_signal_re():
    alts = [r"crontab", r"systemd-run", r"\.timer\b", r"/etc/cron", r"/var/spool/cron"]
    for _, pat, _ in MOAT_UNITS:
        alts.append(re.escape(re.split(r"[*?\[]", pat, 1)[0]))
    for _, pat, _ in MOAT_PATHS:
        alts.append(re.escape(re.split(r"[*?\[]", pat, 1)[0]))
    mem = []
    for m in MOAT_MEMBERS:
        mem.append(re.escape(m["path"]))
        mem.append(r"(?<![\w.-])" + re.escape(os.path.basename(m["path"])) + r"(?![\w.-])")
    return re.compile("|".join(a for a in alts if a)), (re.compile("|".join(mem)) if mem else None)


_MOAT_SIGNAL, _MOAT_MEMBER_SIGNAL = _moat_signal_re()
# o NOME de um script de ato também é relevante para o que não se prova (refutador, 2026-11-05): a cópia criada na
# própria string, `xargs -I{} bash {}`, `find -exec bash {}`, `script -qc`, `tmux new -d` fechavam só por alvo e
# passavam o ato. Pesa junto de algo que EXECUTA ou COPIA o texto, na mesma linha
_MOAT_ACT_NAMES = re.compile("|".join(r"(?<![\w.-])" + re.escape(os.path.basename(r)) for r in MOAT_ACTS)) if MOAT_ACTS else None
# só o que EXECUTA: a 1ª redação contava também cp/tee/cat/sed/git/`>` e fechou 19 comandos honestos do corpus (heredoc
# de python que edita o wrapper, `git show … > /tmp/x` para ler); a cópia criada e executada na mesma linha traz o `bash`
_MOAT_ACT_RUN = re.compile(r"(?<![\w.-])(bash|sh|zsh|dash|ksh|source|exec|xargs|script|tmux|screen)(?![\w.-])|-exec(dir)?\s|(^|[\s;&|(])\./")
_MOAT_ACTION = re.compile(r"\b(systemctl|service|docker|rsync|cp|mv|install|tee|ln|rm|mkdir|touch|chmod|chown|dd|"
                          r"tar|unzip|crontab|systemd-run|at|batch|push|commit|checkout|reset|pull|restart|reload|"
                          r"start|stop|enable|disable)\b|>")
_MOAT_PUSH = re.compile(r"\b(push|send-pack)\b")


def moat_relevant(text):
    t = text if isinstance(text, str) else " ".join(str(x) for x in text)
    if _MOAT_MOTOR.search(t) and _MOAT_SIGNAL.search(t):
        return True
    for ln in t.split("\n"):
        if _MOAT_SIGNAL.search(ln) and _MOAT_ACTION.search(ln):
            return True
        if _MOAT_ACT_NAMES is not None and _MOAT_ACT_NAMES.search(ln) and _MOAT_ACT_RUN.search(ln):
            return True
        if _MOAT_MEMBER_SIGNAL is not None and _MOAT_MEMBER_SIGNAL.search(ln) and _MOAT_PUSH.search(ln):
            return True
    return False


def moat_unanalyzable(seg, why, whole=False):
    t = " ".join(str(x) for x in seg) if isinstance(seg, (list, tuple)) else str(seg)
    # `whole`: o ponto opaco EXECUTA texto (nome de comando ou `eval` só conhecidos em runtime) DENTRO de uma função
    # da string em emulação, e o texto pode ter vindo dos argumentos dela — `for a in "$@"; do bash -c "$a"; done`.
    # A relevância do segmento sozinho (`$a`) nunca o via (SAC-148, medido). Julgam-se então os argumentos das
    # chamadas em curso. A 1ª redação julgava a string INTEIRA e fechou 13 comandos honestos do corpus (heredoc
    # inerte, `$PSQL -c` num script que citava um container servido noutra linha).
    if moat_relevant(t) or (whole and CALLS and moat_relevant("\n".join(CALLS))):
        _moat_emit("inanalisavel", t, "", why)


# ── programas ─────────────────────────────────────────────────────────────────────────────────────────
def _moat_project_dirs():
    if "d" not in _OUR:
        dirs = {os.path.realpath(ROOT)} if ROOT else set()
        for ln in _git(["-C", ROOT, "worktree", "list", "--porcelain"]).split("\n") if ROOT else []:
            if ln.startswith("worktree "):
                dirs.add(os.path.realpath(ln[9:]))
        _OUR["d"] = dirs
    return _OUR["d"]


def _moat_versioned(path):
    """Script rastreado por um checkout DESTE projeto? Só então é fronteira (como `ops/<wrapper>.sh`)."""
    rp = os.path.realpath(path)
    # o checkout MAIS FUNDO que contém o arquivo: as worktrees de agente moram DENTRO do checkout principal
    # (.claude/worktrees/), e perguntar ao principal sobre um arquivo da worktree dá "não rastreado" (medido)
    ds = sorted((d for d in _moat_project_dirs() if rp == d or rp.startswith(d + "/")), key=len, reverse=True)
    if ds:
        return bool(_git(["-C", ds[0], "ls-files", "--full-name", "--error-unmatch", "--", rp]))
    return False


# MOTOR QUE ESCREVE POR ARGUMENTO (2026-10-15): o motor de convites A2A escreve o arquivo que recebe em `--file`,
# e o juiz só via escrita no VERBO (tee, cp, `>`). Medido: `sudo -u <conta> bash <motor> create … --file <arquivo
# servido>` passava com rc 0 — do clone servido (ilegível para o operador, então nem o corpo era julgado) e da
# worktree (versionado = fronteira). O wrapper de produção existiria e o caminho direto continuaria aberto.
# Agora o VALOR de `--file` de um subcomando que escreve é julgado como destino de escrita, VERSIONADO OU NÃO: a
# fronteira do script versionado vale para o que ele faz por dentro, não para o alvo que o comando lhe entrega.
# Reconhecido pelo NOME do arquivo (o clone servido não se lê) OU pelo marcador no corpo (cópia renomeada).
_MOAT_ARG_WRITERS = {"a2a-invite.sh": ({"create", "revoke"}, ("--file", "--invite-out", "--token-out"))}
_MOAT_ARG_WRITER_MARK = "MOAT-ARG-WRITER:"
# os wrappers que escrevem por função (a cópia deles fora do projeto fecha, ver _moat_script) (core-only)
_MOAT_WRAPPER_COPIES = ("a2a-queue-live", "bridge-hardening", "chat-runner", "stt-service")
# o NOME do motor escritor também é AÇÃO para a relevância (SAC-148, 2026-10-15): nas formas que o juiz não segue
# (`python3 -c`, `xargs -I`, função que faz `shift`), a linha que cita o motor e um alvo do MOAT fechava só se
# trouxesse um verbo da lista — e `a2a-invite.sh revoke --file <servido>` não traz nenhum. Medido: rc 0 nas três.
# Só o nome SEGUIDO de um subcomando que escreve: `# a2a-invite.sh` num comentário de um `python3 -c` que só LÊ o
# arquivo fechava (refutador, medido). E o par vale no TEXTO INTEIRO do trecho, não por linha: o `python3 -c`
# multilinha com o motor numa linha e o `revoke` noutra passava (refutador, 2ª passada).
_MOAT_MOTOR = re.compile("|".join(
    r"(?<![\w.-])" + re.escape(n) + r"\b[\s\S]*?\b(" + "|".join(sorted(subs)) + r")\b"
    for n, (subs, _opts) in _MOAT_ARG_WRITERS.items()))


def _moat_arg_writer(p, args, detail):
    # o nome vale pelo caminho E pelo alvo do symlink: `ln -s <motor servido> /tmp/q.sh` (refutador, medido)
    spec = (_MOAT_ARG_WRITERS.get(os.path.basename(p)) or _MOAT_ARG_WRITERS.get(os.path.basename(os.path.realpath(p)))
            or _MOAT_ARG_WRITERS.get(os.path.basename(_MOAT_LINKS.get(p, ""))))   # link criado na própria string
    if spec is None and os.path.isfile(p):
        try:
            with open(p, encoding="utf-8", errors="replace") as fh:
                head = fh.read(8192)
        except OSError:
            head = ""
        m = re.search(re.escape(_MOAT_ARG_WRITER_MARK) + r"[ \t]*([a-z,-]+)[ \t]+(--[a-z-]+(?:,--[a-z-]+)*)", head)
        if m:
            spec = (set(m.group(1).split(",")), tuple(m.group(2).split(",")))
    if spec is None:
        return
    subs, opts = spec
    pos = [a for a in args if not a.startswith("-")]
    if not pos or pos[0] not in subs or "--dry-run" in args:
        return
    # TODA ocorrência: o motor fica com a ÚLTIMA (dict sobrescrito), e julgar só a 1ª deixava
    # `--file /tmp/a.json --file <servido>` passar (refutador, medido)
    for k, a in enumerate(args):
        for o in opts:
            if a == o and k + 1 < len(args):
                v = args[k + 1]
            elif a.startswith(o + "="):
                v = a.split("=", 1)[1]
            else:
                continue
            if DYNAMIC.search(v):
                _moat_emit("inanalisavel", v, "", "%s %s %s só conhecido em runtime — %s" % (os.path.basename(p), pos[0], o, detail))
            else:
                _moat_write_path(_moat_abspath(v), detail, "%s %s %s" % (os.path.basename(p), pos[0], o), creates=False)


def _moat_script_args(p, words):
    """os argumentos que vêm DEPOIS do script na linha (`bash x.sh a b` → [a, b])."""
    for k, w in enumerate(words):
        if w and not w.startswith("-") and _moat_abspath(w) == p:   # o abspath já segue o link da string
            return words[k + 1:]
    if "-s" in words:                                   # `bash -s <args> < motor`: os argumentos vêm depois do -s
        return words[words.index("-s") + 1:]
    return []


# ── ATO (2026-11-05, REGRA 117): o script é um dos de ops/ cujo uso é o deploy ou a publicação ─────────────────────
# Reconhecido de TRÊS jeitos, porque o mesmo ato chega por caminhos diferentes: (1) o caminho relativo a um checkout
# deste projeto (a raiz ou uma worktree: `bash ops/x.sh`, `./x.sh` depois de `cd ops`, o caminho absoluto); (2) o NOME (core-only)
# do arquivo, em qualquer lugar (o clone que o bridge serve tem os mesmos ops/, noutra versão; a cópia em /tmp); (3) o
# CONTEÚDO igual ao de um script da lista (cópia renomeada). A cópia que alguém MUDA e renomeia escapa dos três: o corpo
# dela segue julgado por alvo, como todo script não versionado.
_MOAT_ACT_SHA = {}


def _moat_act_digest(p):
    try:
        if os.path.getsize(p) > _MOAT_MAX_SCRIPT:
            return None
        import hashlib
        with open(p, "rb") as fh:
            return hashlib.sha256(fh.read()).hexdigest()
    except OSError:
        return None


def _moat_act_of(p):
    """-> o caminho relativo (`ops/x.sh`) do ato que o script `p` é, ou None. (core-only)"""
    if not MOAT_ACTS or not p:
        return None
    if re.search(r"[*?\[]", p):
        # glob no caminho (`ops/publish-door.s?`, `secret?.sh`, `[r]`): o shell o expande; se pode casar um ato, é ele (core-only)
        for r in MOAT_ACTS:
            if _fn.fnmatchcase(os.path.basename(r), os.path.basename(p)):
                return r
        return None
    rp = os.path.realpath(p)
    for d in sorted(_moat_project_dirs(), key=len, reverse=True):
        if rp.startswith(d + "/"):
            rel = os.path.normpath(rp[len(d) + 1:])
            if rel in MOAT_ACTS:
                return rel
            break
    names = {os.path.basename(r): r for r in MOAT_ACTS}
    for q in (p, rp):
        if os.path.basename(q) in names:
            return names[os.path.basename(q)]
    if not os.path.isfile(rp):
        return None
    if "d" not in _MOAT_ACT_SHA:
        _MOAT_ACT_SHA["d"] = {}
        for r in MOAT_ACTS:
            h = _moat_act_digest(os.path.join(ROOT, r)) if ROOT else None
            if h:
                _MOAT_ACT_SHA["d"][h] = r
    if not _MOAT_ACT_SHA["d"]:
        return None
    return _MOAT_ACT_SHA["d"].get(_moat_act_digest(rp))


def _moat_act(p, words, src=None, rootcopy=None):
    """emite `ato` se o script é da lista e os argumentos trazem a assinatura (ou não se provam)."""
    _MOAT_CUR["script"] = p
    rel = _moat_act_of(src) if src else None
    rel = rel or _moat_act_of(p)
    if not rel:
        return
    # `bash -n x.sh` só confere a sintaxe e não executa nada: no corpus, 26 dos falsos positivos da 1ª redação
    if words and os.path.basename(words[0]) in SHELLS:
        pre = []
        for w in words[1:]:
            if _moat_abspath(w) == p:
                break
            pre.append(w)
        # vale o ÚLTIMO toggle: `bash -n +n x.sh` executa (refutador, medido: imprimiu EXECUTOU)
        noexec = False
        for k, w in enumerate(pre):
            if re.match(r"^[-+][A-Za-z]*n[A-Za-z]*$", w):
                noexec = w[0] == "-"
            elif w in ("-o", "+o") and k + 1 < len(pre) and pre[k + 1] == "noexec":
                noexec = w == "-o"
        if noexec:
            return
    _moat_act_judge(rel, _moat_argv(_moat_script_args(p, words)), " ".join(words), rootcopy)


# o argv que o SCRIPT recebe: redirecionamento e here-string não são argumento (`x.sh <<< --foreign-repo` entrega a flag
# no stdin, e o juiz a lia como o marcador; refutador do #1647, B1/B2). O argumento vazio FICA: `"" --verified-pr 3`
# é um 1º argumento, e o filtro antigo o apagava.
_MOAT_REDIR_OP = re.compile(r"^(\d*|&)(<<<|<<-?|<>|<&|>&|>>|>\||<|>)$")
_MOAT_REDIR_ATT = re.compile(r"^(\d*|&)(<<<|<<-?|<>|<&|>&|>>|>\||<|>)\S")


def _moat_argv(args):
    out, k = [], 0
    while k < len(args):
        a = args[k]
        if _MOAT_REDIR_OP.match(a):
            k += 2
            continue
        if _MOAT_REDIR_ATT.match(a):
            k += 1
            continue
        out.append(a)
        k += 1
    return out


def _moat_foreign_repo(args):
    """True se algum `--repo X` aponta outro repositório que não este projeto (ou só se conhece em runtime)."""
    for k, a in enumerate(args):
        if a == "--repo":
            v = args[k + 1] if k + 1 < len(args) else ""
        elif a.startswith("--repo="):
            v = a.split("=", 1)[1]
        else:
            continue
        if not v or DYNAMIC.search(v) or _moat_slug(v) not in MOAT_SELF_SLUGS:
            return True
    if any(a == "--repo" or a.startswith("--repo=") for a in args):
        return False
    # sem --repo, o alvo é o que o gh usaria (refutador do #1647, B3): o GH_REPO da linha ou de um export, e senão o
    # repositório do diretório atual. `GH_REPO=x bash pmv.sh 12` e `cd /outro/repo && bash …/pmv.sh 12` são merge alheio.
    env = _MOAT_CUR.get("env") or {}
    for v in (env.get("GH_REPO"), ASSIGN.get("GH_REPO")):
        if v is not None and (not v or DYNAMIC.search(v) or _moat_slug(v) not in MOAT_SELF_SLUGS):
            return True
    cwd = _MOAT_CDS[-1] if _MOAT_CDS else (CWD[-1] if CWD[-1] not in (None, UNKNOWN) else JCWD)
    if cwd and cwd is not UNKNOWN and not DYNAMIC.search(str(cwd)):
        rc = os.path.realpath(str(cwd))
        if not any(rc == d or rc.startswith(d + "/") for d in _moat_project_dirs()):
            return True
    return False


_MOAT_CUR = {}


# ── O ALVO DO GH POR OUTRA PORTA (re-refutação do #1647, N1, 2026-11-13) ─────────────────────────────────────────────
# `git remote add x <outro>; gh repo set-default <outro>; bash ops/pr-merge-verified.sh 12` mergeava no outro repo: o gh (core-only)
# resolve o alvo pelo `remote.<nome>.gh-resolved`, não pelo origin. Pela sessão, mudar os remotes ou o default do gh é
# redirecionar o forge, e fecha: `git remote add|set-url|rename`, `git config` que escreve `remote.*`, e
# `gh repo set-default` (a leitura, `--view`, e o `--unset` passam). O script também recusa remote divergente.
_GIT_GLOBAL_VAL = {"-C", "-c", "--git-dir", "--work-tree", "--namespace", "--exec-path", "--config-env"}
_GIT_CONFIG_READ = {"--get", "--get-all", "--get-regexp", "--get-urlmatch", "-l", "--list", "--name-only", "--show-origin"}


def _moat_forge_redirect(base, args, detail):
    if base == "gh":
        pos = [a for a in args if not a.startswith("-")]
        if pos[:2] == ["repo", "set-default"] and not any(a in ("-v", "--view", "-u", "--unset") for a in args):
            _moat_emit("forja", "gh repo set-default", "-", "mudar o repositório padrão do gh muda o alvo do merge e do forge — %s" % detail)
        return
    if base != "git":
        return
    k = 0
    while k < len(args) and args[k].startswith("-"):
        k += 2 if args[k] in _GIT_GLOBAL_VAL else 1
    rest = args[k:]
    if not rest:
        return
    if rest[0] == "remote":
        sub = [a for a in rest[1:] if not a.startswith("-")]
        if sub and sub[0] in ("add", "set-url", "rename"):
            _moat_emit("forja", "git remote %s" % sub[0], "-", "mudar os remotes muda o alvo do gh e do merge — %s" % detail)
    elif rest[0] == "config":
        # url.<x>.insteadOf e include/includeIf também (3ª passada, F1): reescrevem o origin sem tocar remote.*
        if any(re.match(r"^(remote|url|include|includeif)\.", a, re.I) for a in rest[1:]) \
                and not any(a in _GIT_CONFIG_READ for a in rest[1:]):
            _moat_emit("forja", "git config remote.*/url.*/include*", "-", "escrever remote.*, url.* ou include* muda o alvo do gh e do merge — %s" % detail)


def _moat_act_judge(rel, args, detail, rootcopy=None):
    sig = MOAT_ACTS[rel]
    # as palavras da assinatura que ESTA invocação traz (todas, não só a 1ª: a forma delegada tem de cobrir cada uma)
    words = set()
    if "@any" in sig:
        words.add("@any")
    if not args and "@none" in sig:
        words.add("@none")
    if "@foreign" in sig and _moat_foreign_repo(args):
        words.add("@foreign")
    for a in args:
        # argumento só conhecido em runtime CALA (cláusula 4): no corpus, os 13 casos eram nome de serviço, porta ou
        # registro num laço (`for s in …; do bash x.sh $s verify`), nunca a assinatura. O valor literal na própria string
        # (`M=--apply; bash x.sh $M`) o lib já resolve; o que vem de fora dela é teto declarado
        if DYNAMIC.search(a):
            continue
        w = a.split("=", 1)[0] if a.startswith("--") else a
        if w in sig:
            words.add(w)
    if not words:
        return
    if _moat_delegated(rel, words, args, rootcopy):
        return                                          # a forma delegada: o script confere as condições do selo
    hint = _moat_delegated_hint(rel)
    if rootcopy == "stale":
        hint = "; a cópia de root delegada está AUSENTE ou DIFERE de %s deste checkout (o maestro a reinstala: ops/delegated-ops.sh install)%s" % (rel, hint)  # (core-only)
    if "@any" in words:
        _moat_emit("ato", rel, "@any", "%s roda o ato em qualquer invocação — %s%s" % (rel, detail, hint))
    elif "@none" in words:
        _moat_emit("ato", rel, "@none", "%s sem argumento roda o ato (o modo padrão) — %s%s" % (rel, detail, hint))
    elif "@foreign" in words and len(words) == 1:
        _moat_emit("ato", rel, "@foreign", "%s com --repo de outro repositório é merge alheio — %s%s" % (rel, detail, hint))
    else:
        w = next(_moat_first_sig(args, sig, words))
        _moat_emit("ato", rel, w, "%s %s é o ato — %s%s" % (rel, w, detail, hint))


def _moat_first_sig(args, sig, words):
    for a in args:
        if not DYNAMIC.search(a):
            w = a.split("=", 1)[0] if a.startswith("--") else a
            if w in words and w in sig:
                yield w
    yield sorted(words)[0]


def _moat_script(path, depth, words):
    p = _moat_abspath(path)
    # a cópia de root delegada (sudoers sem senha): byte a byte o wrapper deste checkout, ela é fronteira para o ALVO como
    # o versionado; o ATO dela se julga com a forma `@rootcopy`. A cópia que difere segue o caminho de sempre (corpo
    # julgado, ato pelo nome) e a mensagem diz que ela está defasada
    rc = _moat_rootcopy(p) if p else None
    if rc and rc[1] == "ok":
        _moat_act(p, words, None, "ok")
        return
    if not p:
        # caminho só conhecido em runtime: a fronteira do `bash x.sh`, salvo se o texto cita um script de ato
        # `bash "$R"/ops/x.sh --apply`: o NOME está na palavra, e a assinatura se julga como no caminho literal (core-only)
        named = [r for r in MOAT_ACTS if str(path).endswith("/" + os.path.basename(r))]
        if named:
            k = words.index(path) if path in words else len(words)
            _moat_act_judge(named[0], [a for a in words[k + 1:] if a], " ".join(words))
        # `bash $(echo ops/x.sh)`: a palavra vira o marcador da substituição, e o nome só está no texto do trecho (core-only)
        elif MOAT_ACTS and ((SUBST in str(path) and any(
                re.search(r"(?<![\w.-])" + re.escape(os.path.basename(r)), raw) for r in MOAT_ACTS)) or (
                PSUBST in str(path) and any(os.path.basename(r) in t for r in MOAT_ACTS for t in PSUBST_TEXTS))):
            # `$X/…` cala (cláusula 4: o harness que recebe um comando em texto não é o ato); `$(…)` e `<(…)` que citam
            # um ato, não
            _moat_emit("inanalisavel", str(path), "", "script de ato (deploy/publicação) por caminho só conhecido em runtime")
        return
    _moat_script_body(path, depth, words)
    # o ATO se julga DEPOIS do corpo: o script versionado é fronteira para o ALVO (o que ele escreve por dentro), não
    # para o ATO; e numa cópia não versionada o veto por alvo do corpo, quando há, sai primeiro (é o mais específico)
    _moat_act(p, words, _MOAT_COPIED.get(p) if not os.path.isfile(p) else None, rc[1] if rc else None)


def _moat_script_body(path, depth, words):
    p = _moat_abspath(path)
    if not p:
        return                                          # caminho só conhecido em runtime: a fronteira do `bash x.sh`
    _moat_arg_writer(p, _moat_script_args(p, words), " ".join(words))
    copied = False
    if not os.path.isfile(p) and p in _MOAT_COPIED and os.path.isfile(_MOAT_COPIED[p]):
        p = _MOAT_COPIED[p]                             # `cp a.sh b.sh && bash b.sh`: julga-se a.sh
        copied = True                                   # …pelo CORPO: a cópia pode ser mutada na mesma string
    if not os.path.isfile(p):
        # script criado na PRÓPRIA string (`cat > x.sh <<'E' … E; bash x.sh`): o disco ainda não o tem, e o
        # corpo sumiu da análise como heredoc inerte — julga-se o texto inteiro pela forma. Script que só
        # não existe AINDA (worktree criada na mesma string, caminho de outra sessão) não é isso: a 1ª
        # redação fechava todo `bash x.sh` inexistente e vetou 19 comandos honestos do corpus
        if p in _MOAT_WRITTEN and moat_relevant(raw):
            _moat_emit("inanalisavel", p, "", "script que ainda não existe no disco, com alvo do MOAT no comando")
        return
    if _moat_versioned(p) and not copied:
        return                                          # código versionado do projeto: fronteira declarada
    # (a cópia NÃO herda a fronteira: `cp ops/<wrapper>.sh /tmp/w.sh && sed -i … /tmp/w.sh && bash /tmp/w.sh`
    #  passava, com o backup arrancado — refutador, 2026-10-15)
    try:
        if os.path.getsize(p) > _MOAT_MAX_SCRIPT:
            return
        with open(p, encoding="utf-8", errors="replace") as fh:
            body = fh.read()
    except OSError:
        return                                          # ilegível: não se prova, não se acusa
    if "\x00" in body:
        return
    # script NÃO versionado que chama um motor escritor e cita um alvo do MOAT: a escrita sai por variável,
    # função ou array (`motor create "${args[@]}"`), que o juiz não segue. Medido em 2026-10-15: uma cópia do
    # wrapper de convites fora do projeto, que podia ter o backup e o check arrancados, passava com rc 0
    code = "\n".join(ln for ln in body.split("\n") if not ln.lstrip().startswith("#"))   # comentário não é chamada
    if (any(n in code for n in _MOAT_ARG_WRITERS) and re.search(r"\b(create|revoke)\b", code)
            and _MOAT_SIGNAL.search(code)):
        _moat_emit("inanalisavel", p, "", "script não versionado que chama um motor escritor, com alvo do MOAT no corpo")
        return
    n_out = len(OUT)
    try:
        scoped(heredocs(body), depth + 1)
    except Unanalyzable:
        if moat_relevant(body):
            _moat_emit("inanalisavel", p, "", "script fundo demais para analisar, com alvo do MOAT no corpo")
    # CÓPIA não versionada de um wrapper de ops/ que escreve por função (`as_svc mv "${SRC}" …`), com um alvo do MOAT
    # no corpo, que a análise acima não julgou: o juiz lê a função, não a chamada. Medido em 2026-10-15: a cópia do
    # wrapper da fila A2A fora do projeto passava com rc 0. Reconhecida pelo NOME do wrapper no código, como o motor
    # de convites é reconhecido pelo nome. A 1ª redação fechava toda função que embrulha sudo e vetava diagnóstico
    # só de leitura vendorizado (`_dk(){ docker … || sudo -n docker …; }`), sem fechar array, alias ou `s\udo`:
    # guarda por vocabulário. A classe geral (função, array, alias ou interpretador que escreve) segue como teto
    if not any(o.startswith("__ONION_MOAT__") for o in OUT[n_out:]) \
            and any(n in code for n in _MOAT_WRAPPER_COPIES) and _MOAT_SIGNAL.search(code):
        _moat_emit("inanalisavel", p, "", "cópia não versionada de um wrapper de ops/ que escreve por função, com alvo do MOAT no corpo")


def _moat_systemctl(args, detail):
    pos = _moat_positionals(args, _MOAT_SYSTEMCTL_ARGOPTS)
    if not pos:
        return
    verb, units = pos[0], pos[1:]
    if verb not in _MOAT_UNIT_MUTATE:
        return
    for u in units:
        if DYNAMIC.search(u):
            # unidade que só o runtime conhece, com verbo que MUDA: fechado (a string da sessão não herda
            # variável de chamada anterior — o shell não persiste —, então isto é raro e não se prova)
            _moat_emit("inanalisavel", u, "", "systemctl %s de unidade só conhecida em runtime — %s" % (verb, detail))
            continue
        if u.endswith(".timer") and verb in _MOAT_TIMER_ARM:
            _moat_emit("relogio", u, "", "systemctl %s de timer — %s" % (verb, detail))
            continue
        hit = _moat_unit_match(u)
        if hit:
            _moat_emit(hit[0], u, hit[2], "systemctl %s de unidade servida (%s) — %s" % (verb, hit[1], detail))


def _moat_git(words, env, detail):
    where = git_target(words, env)
    if where == UNKNOWN and _MOAT_CDS and "-C" not in words:
        where = _MOAT_CDS[-1]
    if where is None or where == UNKNOWN:
        return
    i = 1
    while i < len(words):
        w = words[i]
        if w in ("-C", "-c") and i + 1 < len(words):
            i += 2; continue
        if w.startswith("-"):
            i += 1; continue
        break
    sub = words[i] if i < len(words) else ""
    rest = words[i + 1:]
    lists = any(a in ("-l", "--list", "-a", "--all", "-r", "--remotes", "-v", "-vv", "--contains", "--merged",
                      "--no-merged", "--points-at", "--show-current", "--format") or a.startswith("--format=")
                for a in rest)
    # o `lists` acima conta `-a` como listagem (é do `git branch`); no `git tag`, `-a` é ANOTAR
    tag_lists = any(a in ("-l", "--list", "--contains", "--no-contains", "--points-at", "--merged", "--no-merged", "-n")
                    or a.startswith(("--format", "--sort", "-n")) for a in rest)
    if sub not in _MOAT_GIT_WRITE and not (sub == "tag" and _moat_positionals(rest) and not tag_lists) \
            and not (sub == "branch" and not lists and (_moat_positionals(rest) or any(a in ("-d", "-D", "-m", "-M", "-f", "-c", "-C") for a in rest))) \
            and not (sub == "config" and not any(a in ("--get", "--get-all", "--get-regexp", "-l", "--list", "--show-origin") for a in rest)):
        return
    if sub == "stash" and rest[:1] in (["list"], ["show"]):
        return
    if sub == "worktree" and rest[:1] == ["list"]:
        return
    if sub == "remote" and (not rest or rest[:1] in (["-v"], ["show"], ["get-url"])):
        return
    if sub == "submodule" and (not rest or rest[:1] == ["status"]):
        return
    hit = _moat_path_match(os.path.normpath(where), ("deploy",))
    if hit:
        _moat_emit("deploy", where, hit[2], "git %s numa árvore servida (%s) — %s" % (sub, hit[1], detail))
        return
    if sub == "tag" and not tag_lists and not any(a in ("-d", "--delete", "-v", "--verify") for a in rest):
        pos = _moat_positionals(rest, {"-m", "--message", "-F", "--file", "-u", "--local-user", "--cleanup"})
        if pos:
            _MOAT_TAGS.add(pos[0])                      # `git tag v1 && git push origin v1`: o disco ainda não a tem
    pushing = sub in ("push", "send-pack") or (sub == "subtree" and rest[:1] == ["push"])
    if not pushing:
        return
    tag = _moat_tag_push(rest, where)
    if tag:
        _moat_emit("publicacao", tag, "tag", "git push de TAG (%s) — %s" % (tag, detail))
    # O QUE do repo alheio veta é o push que MUDA A LINHA DE PRODUÇÃO DELE: o ramo protegido (a linha canônica do
    # lib já escreve `main` para o ramo de produção RESOLVIDO no diretório — gitflow, HEAD do remoto, push nu
    # sentado nele), force, delete, mirror/all. Branch de tópico passa: vai virar PR no repo alheio, e o PR é o
    # gate dele. Medido no corpus de 35.092 comandos (2026-10-13): a sessão do core empurra branch de PR do
    # /meta:adopt (`onion/adopt`, `chore/onion-update-*`) e do bridge como fluxo normal; vetar isso era vetar o
    # caminho que a casa já usa. Commit/branch/config LOCAIS nem chegam aqui (nada sai da máquina sem push).
    line, remote, is_push = canonical_git(words, where, env)
    if not is_push:
        return
    risky = bool(re.search(r"(\s|:)(refs/heads/)?main(\s|$)|--force|--delete|(^|\s)-d(\s|$)|--mirror|--all\b|--prune",
                           line or "")) or any(a in ("--delete", "-d") or a.startswith("--del") for a in rest)
    what = "git push que muda o ramo de produção, força ou apaga"
    if not same_project(where):
        m = _moat_member(os.path.normpath(where))
        if m:
            if risky:
                _moat_emit("alheio", where, m.get("kind", ""), "%s no clone de %s (kind %s) — %s"
                           % (what, m["id"], m.get("kind", "?"), detail))
            return
    if risky and not push_dest_ours(where, remote, LAST_CFG[0]):
        _moat_emit("alheio", remote or "(destino do push)", "", "%s num destino de OUTRO repositório — %s" % (what, detail))


_MOAT_TAGS = set()        # tags criadas na própria string


def _moat_tag_push(rest, where):
    """-> a tag que o push publica, ou None. Lê os argumentos crus: o canonical_git do lib normaliza a branch."""
    if any(a in ("--tags", "--follow-tags") for a in rest):
        return "--tags" if "--tags" in rest else "--follow-tags"
    pos = _moat_positionals(rest, {"-o", "--push-option", "--repo", "--receive-pack", "--exec"})
    for r in pos[1:]:                                   # o 1º posicional é o remoto
        src = r.lstrip("+").split(":", 1)
        for side in src:
            if side.startswith("refs/tags/") or side.startswith("tags/"):
                return side
        name = src[0]
        if not name or DYNAMIC.search(name):
            continue
        if name in _MOAT_TAGS:
            return name
        if where and where != UNKNOWN and _git(["-C", where, "rev-parse", "-q", "--verify", "refs/tags/" + name]) \
                and not _git(["-C", where, "rev-parse", "-q", "--verify", "refs/heads/" + name]):
            return name
    return None


_MOAT_PUB_REPO_FIELDS = re.compile(r"^(visibility|private|description|topics(\[\])?|names(\[\])?)=")


def _moat_gh(words, detail):
    """aprovação de ambiente, visibilidade/descrição/tópicos do repo: a classe publicacao."""
    if len(words) > 2 and words[1] == "repo" and words[2] == "edit":
        args = words[3:]
        hits = [a.split("=", 1)[0] for a in args
                if a.split("=", 1)[0] in ("--visibility", "--description", "-d", "--add-topic", "--remove-topic")]
        if hits:
            _moat_emit("publicacao", "gh repo edit", "repo", "gh repo edit %s (o que o público vê do repo) — %s"
                       % (" ".join(sorted(set(hits))), detail))
        return
    if len(words) > 2 and words[1] == "release" and words[2] in ("create", "edit", "delete", "upload"):
        _moat_emit("publicacao", "gh release " + words[2], "release", "gh release %s (release pública) — %s" % (words[2], detail))
        return
    if len(words) < 2 or words[1] != "api":
        return
    m = re.match(r"^gh api --method (\S+) (\S+)(.*)$", canonical_gh(words))
    if not m:
        return
    meth, ep, vals = m.group(1), m.group(2).lstrip("/"), m.group(3).split()
    if meth == "POST" and re.search(r"(^|/)actions/runs/[^/]+/pending_deployments$", ep):
        _moat_emit("publicacao", ep, "ambiente", "aprovação de ambiente protegido (POST pending_deployments) — %s" % detail)
    elif meth in ("PATCH", "POST") and re.match(r"^repos/[^/]+/[^/]+$", ep) and any(_MOAT_PUB_REPO_FIELDS.match(v) for v in vals):
        _moat_emit("publicacao", ep, "repo", "PATCH do repo em visibilidade/descrição/tópicos — %s" % detail)
    elif meth == "PUT" and re.match(r"^repos/[^/]+/[^/]+/topics$", ep):
        _moat_emit("publicacao", ep, "repo", "PUT dos tópicos do repo — %s" % detail)
    elif meth in ("POST", "PATCH", "DELETE") and re.match(r"^repos/[^/]+/[^/]+/releases(/.*)?$", ep):
        _moat_emit("publicacao", ep, "release", "%s em releases pela API — %s" % (meth, detail))


def _moat_curl_pub(args, detail):
    """o mesmo pela API REST crua: `curl -X POST https://api.github.com/…/pending_deployments`."""
    urls = [a for a in args if re.search(r"(^|//)(api\.github\.com|[^/\s]+/api/v3)/", a)]
    if not urls:
        return
    meth = _moat_opt_value(args, {"-X", "--request"}, ("--request",))
    meth = (meth or ("POST" if any(a in ("-d", "--data", "--data-raw", "--data-binary", "--json", "-F", "--form")
                                   or a.startswith(("--data", "--json", "-d")) for a in args) else "GET")).upper()
    body = " ".join(args)
    for u in urls:
        path = re.sub(r"^.*?(api\.github\.com|/api/v3)/", "", u).split("?", 1)[0]
        if meth == "POST" and re.search(r"(^|/)actions/runs/[^/]+/pending_deployments$", path):
            _moat_emit("publicacao", path, "ambiente", "aprovação de ambiente protegido pela API REST (curl) — %s" % detail)
        elif meth == "PATCH" and re.match(r"^repos/[^/]+/[^/]+$", path) and re.search(r'"?(visibility|private|description|topics)"?\s*[:=]', body):
            _moat_emit("publicacao", path, "repo", "PATCH do repo em visibilidade/descrição/tópicos (curl) — %s" % detail)
        elif meth == "PUT" and re.match(r"^repos/[^/]+/[^/]+/topics$", path):
            _moat_emit("publicacao", path, "repo", "PUT dos tópicos do repo (curl) — %s" % detail)


def _moat_crontab(args, detail):
    a = [x for x in args]
    k, rest = 0, []
    while k < len(a):
        if a[k] == "-u" and k + 1 < len(a):
            k += 2; continue
        rest.append(a[k]); k += 1
    if rest and all(x in ("-l",) for x in rest):
        return
    _moat_emit("relogio", "crontab", "", "crontab que instala/edita/remove — %s" % detail)


def moat_command(words, raw_words, base, depth, env, piped, stdin_from):
    detail = " ".join(raw_words)
    _MOAT_CUR["env"] = env if isinstance(env, dict) else {}
    args = words[1:]
    # o MODO DE TESTE do wrapper de convites roda o motor e o backup que o ambiente nomear, como o operador: pela
    # sessão ele lavaria um script não versionado através do wrapper versionado (refutador, medido). Ele só existe
    # para a bancada, que o liga por dentro de um script versionado — na linha de comando, fecha.
    if any(re.match(r"^(export\s+)?ONION_A2A_LIVE_TEST=", w) for w in list(raw_words) + list(words)) \
            or (isinstance(env, dict) and "ONION_A2A_LIVE_TEST" in env) \
            or "ONION_A2A_LIVE_TEST" in globals().get("ASSIGN", {}):   # `export X=1; …` e `X=1; …` caem no ASSIGN do lib
        _moat_emit("inanalisavel", "ONION_A2A_LIVE_TEST", "", "modo de teste do wrapper de convites fora da bancada — %s" % detail)
    # o MESMO fecho para o wrapper da fila A2A (ops/a2a-queue-live.sh) (core-only), de 2026-10-15: o modo de teste dele roda o
    # backup que o ambiente nomear e move arquivos como o operador — pela sessão, lavaria um script não versionado
    if any(re.match(r"^(export\s+)?ONION_A2A_QUEUE_TEST=", w) for w in list(raw_words) + list(words)) \
            or (isinstance(env, dict) and "ONION_A2A_QUEUE_TEST" in env) \
            or "ONION_A2A_QUEUE_TEST" in globals().get("ASSIGN", {}):
        _moat_emit("inanalisavel", "ONION_A2A_QUEUE_TEST", "", "modo de teste do wrapper da fila A2A fora da bancada — %s" % detail)
    # e para o wrapper do drop-in de integridade do bridge (ops/bridge-hardening.sh) (core-only), de 2026-10-16: o modo de
    # teste dele instala o drop-in e chama systemctl/systemd-run/nsenter do PATH, sem sudo — pela sessão, lavaria falsos
    if any(re.match(r"^(export\s+)?ONION_BRIDGE_HARDENING_TEST=", w) for w in list(raw_words) + list(words)) \
            or (isinstance(env, dict) and "ONION_BRIDGE_HARDENING_TEST" in env) \
            or "ONION_BRIDGE_HARDENING_TEST" in globals().get("ASSIGN", {}):
        _moat_emit("inanalisavel", "ONION_BRIDGE_HARDENING_TEST", "", "modo de teste do wrapper do drop-in de integridade fora da bancada — %s" % detail)
    # e para o wrapper do runner do convidado (ops/chat-runner.sh) (core-only), de 2026-10-16: o modo de teste dele cria
    # grupo, aplica ACL e instala units por systemctl/setfacl/groupadd do PATH, sem sudo — pela sessão, lavaria falsos
    if any(re.match(r"^(export\s+)?ONION_CHAT_RUNNER_TEST=", w) for w in list(raw_words) + list(words)) \
            or (isinstance(env, dict) and "ONION_CHAT_RUNNER_TEST" in env) \
            or "ONION_CHAT_RUNNER_TEST" in globals().get("ASSIGN", {}):
        _moat_emit("inanalisavel", "ONION_CHAT_RUNNER_TEST", "", "modo de teste do wrapper do runner do convidado fora da bancada — %s" % detail)
    # e para o wrapper do STT em lote (ops/stt-service.sh) (core-only), de 2026-10-17: o modo de teste dele instala a unit e
    # chama systemctl/systemd-run/ss/curl do PATH, sem sudo — pela sessão, lavaria falsos
    if any(re.match(r"^(export\s+)?ONION_STT_SERVICE_TEST=", w) for w in list(raw_words) + list(words)) \
            or (isinstance(env, dict) and "ONION_STT_SERVICE_TEST" in env) \
            or "ONION_STT_SERVICE_TEST" in globals().get("ASSIGN", {}):
        _moat_emit("inanalisavel", "ONION_STT_SERVICE_TEST", "", "modo de teste do wrapper do STT em lote fora da bancada — %s" % detail)
    # e para o merge verificado (ops/pr-merge-verified.sh) (core-only), de 2026-11-13: a variável da bancada desliga a recusa
    # do merge alheio pela sessão do core (refutador do #1647) — na linha da sessão, fecha
    if any(re.match(r"^(export\s+)?ONION_PR_MERGE_VERIFIED_TEST=", w) for w in list(raw_words) + list(words)) \
            or (isinstance(env, dict) and "ONION_PR_MERGE_VERIFIED_TEST" in env) \
            or "ONION_PR_MERGE_VERIFIED_TEST" in globals().get("ASSIGN", {}):
        _moat_emit("inanalisavel", "ONION_PR_MERGE_VERIFIED_TEST", "", "modo de bancada do merge verificado fora da bancada — %s" % detail)
    _moat_forge_redirect(base, args, detail)
    if base == "cd" and len(words) > 1 and not DYNAMIC.search(words[1]) and words[1] != "-":
        prev = _MOAT_CDS[-1] if _MOAT_CDS else (CWD[-1] if CWD[-1] not in (None, UNKNOWN) else JCWD)
        _MOAT_CDS.append(os.path.normpath(os.path.join(prev, os.path.expanduser(words[1]))))
    _moat_redirects(raw_words, detail)
    if base == "systemctl":
        _moat_systemctl(args, detail)
    elif base == "service":
        pos = _moat_positionals(args)
        if len(pos) >= 2 and pos[1] in _MOAT_UNIT_MUTATE | {"force-reload"}:
            hit = _moat_unit_match(pos[0])
            if hit:
                _moat_emit(hit[0], pos[0], hit[2], "service %s de unidade servida — %s" % (pos[1], detail))
            elif DYNAMIC.search(pos[0]):
                moat_unanalyzable(words, "unidade só conhecida em runtime")
    elif base == "docker":
        pos = _moat_positionals(args, {"-H", "--host", "--context", "-c", "--config", "-l", "--log-level",
                                       "-t", "--time", "-s", "--signal"})
        if pos[:1] == ["container"]:
            pos = pos[1:]
        if pos and pos[0] in _MOAT_DOCKER_MUTATE:
            for n in pos[1:]:
                hit = _moat_unit_match(n)
                if hit:
                    _moat_emit(hit[0], n, hit[2], "docker %s de container servido — %s" % (pos[0], detail))
    elif base in ("crontab",):
        _moat_crontab(args, detail)
    elif base in ("at", "batch"):
        if base == "batch" or not args or not all(x in ("-l", "-d", "-r", "-c", "-V") or x.isdigit() for x in args):
            _moat_emit("relogio", base, "", "%s agenda execução — %s" % (base, detail))
    elif base == "systemd-run":
        if any(a.startswith(_MOAT_TIMER_OPTS) for a in args):
            _moat_emit("relogio", "systemd-run", "", "systemd-run com timer — %s" % detail)
    elif base == "git":
        # `-C ~/x` e `--git-dir=~/x`: o shell expande o til fora de aspas, e o git_target do lib o leria como relativo
        gw = [os.path.expanduser(w) if w.startswith("~") and k > 0 and words[k - 1] == "-C" else
              ("--git-dir=" + os.path.expanduser(w[10:]) if w.startswith("--git-dir=~") else w) for k, w in enumerate(words)]
        _moat_git(gw, env, detail)
    elif base == "find":
        # `find <raiz> -delete` e `find <raiz> -exec rm|mv|… {}`: a RAIZ é o que se escreve
        roots = []
        for a in args:
            if a.startswith("-") or a in ("!", "(", ")"):
                break
            roots.append(a)
        if any(a in ("-exec", "-execdir", "-ok", "-okdir") and k + 1 < len(args) and os.path.basename(args[k + 1]) in SHELLS | {"source"}
               for k, a in enumerate(args)) and moat_relevant(words):
            moat_unanalyzable(words, "find -exec que roda um shell sobre o que achar")
        writes = "-delete" in args or any(
            a in ("-exec", "-execdir", "-ok", "-okdir") and k + 1 < len(args) and os.path.basename(args[k + 1]) in
            (_MOAT_WRITE_ALL | _MOAT_WRITE_DEST | {"sed", "truncate", "dd"}) for k, a in enumerate(args))
        if writes:
            for r in roots or ["."]:
                _moat_write_path(_moat_abspath(r), detail, "find")
    elif base in _MOAT_WRITE_ALL:
        for p in _moat_positionals(args, {"-m", "--mode", "--reference"} if base in ("mkdir", "chmod") else ()):
            _moat_write_path(_moat_abspath(p), detail, base, creates=base in ("tee", "mv", "touch"))
    elif base in _MOAT_WRITE_DEST:
        argopts = {"-S", "--suffix", "-m", "--mode", "-o", "--owner", "-g", "--group", "-e", "--rsh",
                   "--exclude", "--include", "--filter", "-f", "--chown", "--chmod", "-P", "-i", "-F"}
        pos = _moat_positionals(args, argopts)
        tdir = _moat_opt_value(args, {"-t", "--target-directory"}, ("--target-directory",))
        if base == "install" and any(a == "-d" or a == "--directory" or (a.startswith("-") and not a.startswith("--") and "d" in a) for a in args):
            dests = pos
        else:
            dests = [tdir] if tdir else (pos[-1:] if len(pos) >= 2 or base == "ln" else [])
        srcs = [x for x in pos[:-1]] if not tdir else list(pos)
        if base in ("cp", "install") and len(srcs) == 1 and len(dests) == 1:
            dp, sp = _moat_abspath(dests[0]), _moat_abspath(srcs[0])
            if dp and sp:
                if os.path.isdir(dp):
                    dp = os.path.join(dp, os.path.basename(sp))
                _MOAT_COPIED[dp] = sp
        for p in dests:
            _moat_write_path(_moat_abspath(re.sub(r"^[^/:@]+@[^:]+:", "", p) if base in ("rsync", "scp") and ":" in p else p), detail, base)
        if base == "ln" and len(pos) >= 2 and any(a in ("-s", "-sf", "-sfn", "-sn", "--symbolic") or
                                                  (a.startswith("-") and not a.startswith("--") and "s" in a) for a in args):
            # o link nasce DEPOIS de conferido o destino dele: `ln -s <servido> /tmp/w` é honesto; o que
            # escrever por /tmp/w adiante na mesma string é que é escrita no servido
            lk = _moat_abspath(pos[-1])
            if lk and os.path.isdir(lk):
                lk = os.path.join(lk, os.path.basename(pos[0]))
            tg = _moat_abspath(pos[0], os.path.dirname(lk) if lk else None)
            if lk and tg:
                _MOAT_LINKS[lk] = tg
    elif base == "sed":
        if any(a.startswith("-i") or a.startswith("--in-place") for a in args) or \
                any(a.startswith("-") and not a.startswith("--") and "i" in a[1:] for a in args):
            for p in _moat_positionals(args, {"-e", "-f", "--expression", "--file"}):
                _moat_write_path(_moat_abspath(p), detail, "sed -i", creates=False)
        for p in _moat_sed_writes(args):                 # `w arquivo` no script grava, com ou sem `-i` (SAC-390)
            _moat_write_path(_moat_abspath(p), detail, "sed w")
    elif base == "dd":
        for a in args:
            if a.startswith("of="):
                _moat_write_path(_moat_abspath(a[3:]), detail, "dd")
    elif base == "tar":
        flat = " ".join(args)
        if re.search(r"(^|\s)(-[A-Za-z]*x|--extract|x[A-Za-z]*\b)", flat):
            d = _moat_opt_value(args, {"-C", "--directory"}, ("--directory",))
            _moat_write_path(_moat_abspath(d) if d else _moat_abspath("."), detail, "tar -x")
    elif base == "unzip":
        d = _moat_opt_value(args, {"-d"}, ())
        _moat_write_path(_moat_abspath(d) if d else _moat_abspath("."), detail, "unzip")
    elif base == "gh":
        _moat_gh(words, detail)
    elif base in ("curl", "wget"):
        if base == "curl":
            _moat_curl_pub(args, detail)
        o = _moat_opt_value(args, {"-o", "--output"} if base == "curl" else {"-O", "--output-document"},
                            ("--output",) if base == "curl" else ("--output-document",))
        if o:
            _moat_write_path(_moat_abspath(o), detail, base)
        if base == "wget":
            d = _moat_opt_value(args, {"-P", "--directory-prefix"}, ("--directory-prefix",))
            if d:
                _moat_write_path(_moat_abspath(d), detail, "wget")
    elif base == "eval":
        txt = " ".join(args)
        if DYNAMIC.search(txt):
            moat_unanalyzable(words, "eval de texto só conhecido em runtime", whole=True)
        else:
            try:
                scoped(txt, depth + 1)
            except Unanalyzable:
                moat_unanalyzable(words, "eval inanalisável")
    # script em arquivo: shell com caminho, `source`/`.`, executável por caminho, shell lendo arquivo por `<`
    if base in SHELLS:
        # o here-string é o STDIN: `bash <<< 'código'` não tem script (outro ramo julga o código), mas `bash x.sh <<< y`
        # roda x.sh, e pular o ramo deixava o ato passar sem juízo (refutador do #1647, B1/B2)
        _sa = _moat_argv(args)
        if not any(re.match(r"^-[A-Za-z]*c[A-Za-z]*$", a) for a in args) \
                and ("<<<" not in args or _moat_positionals(_sa, {"-o", "-O", "--rcfile", "--init-file"})):
            # `+n`, `+x`, `+o noexec` são opções do shell (desligam), não o script: sem isto `bash -n +n x.sh` via "+n"
            sa, k = [], 0
            while k < len(_sa):
                if _sa[k] in ("+o", "+O") and k + 1 < len(_sa):
                    k += 2; continue
                if re.match(r"^\+[A-Za-z]+$", _sa[k]):
                    k += 1; continue
                sa.append(_sa[k]); k += 1
            pos = _moat_positionals(sa, {"-o", "-O", "--rcfile", "--init-file"})
            prev = [resolve(x) for x in (stdin_from or [])]
            if pos and "-s" not in args:                    # `bash -s <args> < x.sh`: os posicionais são argumentos
                _moat_script(pos[0], depth, words)
            elif piped and prev and os.path.basename(prev[0]) == "cat":
                for f in _moat_positionals(prev[1:]):         # `cat x.sh | bash`: o shell lê o arquivo
                    _moat_script(f, depth, words)
            elif piped and prev and _MOAT_ACT_NAMES is not None and _MOAT_ACT_NAMES.search(" ".join(str(x) for x in prev)):
                # `git show HEAD:ops/x.sh | bash -s`, `sed '' ops/x.sh | bash`: o shell lê o texto de um ato por outra fonte (core-only)
                _moat_emit("inanalisavel", " ".join(str(x) for x in prev)[:120], "", "shell lendo o texto de um script de ato por pipe — %s" % " ".join(words))
            else:
                for k, w in enumerate(raw_words):
                    m = REDIR.match(w)
                    if m and m.group(2) == "<":
                        src = m.group(3) or (raw_words[k + 1] if k + 1 < len(raw_words) else "")
                        if src:
                            _moat_script(src, depth, words)
    elif base in ("source", ".") and args:
        _moat_script(args[0], depth, words)
    elif "/" in words[0] and base not in ("git", "gh"):
        p = _moat_abspath(words[0])
        if p:
            _moat_arg_writer(p, args, detail)   # antes do isfile: o motor no clone servido não se lê
        if p and os.path.isfile(p):
            try:
                with open(p, "rb") as fh:
                    head = fh.read(128)
            except OSError:
                head = b""
            if head.startswith(b"#!") and re.match(rb"#!\s*\S*/(env\s+)?(ba|z|da|k)?sh\b", head) or p.endswith(".sh"):
                _moat_script(p, depth, words)
        elif p and re.sub(r"[*?\[\]]", "", os.path.basename(p)) and _moat_act_of(p):
            # (um glob só de curinga, `/var/lib/x/*`, não nomeia script nenhum: o veto por alvo é que o julga)
            # o script de ATO executado direto por um caminho que o hook não lê (o clone servido sob a home 0750 da conta
            # do serviço; a cópia de root ainda não instalada): é o ato do mesmo jeito, julgado pelo NOME. Medido em
            # 2026-11-13: `sudo /srv/x/ops/update-bridge.sh` passava com rc 0 (com `bash` na frente, o ato9 já vetava)
            rc = _moat_rootcopy(p)
            _moat_act(p, words, None, rc[1] if rc else None)
    # executores: o que vem depois é comando (watch/flock/nice…) ou código em texto (su -c, python -c)
    if base in RUNNERS and base not in ("crontab", "at", "batch"):
        for k, w in enumerate(args, 1):
            wb = os.path.basename(w)
            if wb in ("systemctl", "service", "docker", "rsync", "cp", "mv", "install", "tee", "ln", "rm",
                      "crontab", "systemd-run", "at", "batch", "dd", "tar", "sed", "eval", "mkdir", "touch",
                      "chmod", "chown", "sudo", "env", "timeout", "nice"):
                command(words[k:], depth + 1)
                break
        if base in ("su", "runuser", "script"):
            v = _moat_opt_value(args, {"-c", "--command"}, ("--command",))
            if v is None:                                # `script -qc '<texto>'`: opção colada (refutador)
                for k, a in enumerate(args):
                    if re.match(r"^-[A-Za-z]*c$", a) and k + 1 < len(args):
                        v = args[k + 1]; break
            if v:
                try:
                    scoped(v, depth + 1)
                except Unanalyzable:
                    moat_unanalyzable(words, "código embutido inanalisável")
        elif base in ("python", "python3", "perl", "ruby", "node"):
            # só código EMBUTIDO (-c/-e) é julgado pela forma; `python3 x.py "<texto que cita systemd>"` é script em
            # arquivo (fronteira) — a 1ª redação vetava o texto dos argumentos (falso positivo do corpus)
            if any(re.match(r"^-[A-Za-z]*[ce]$", a) or a in ("--command", "--eval") for a in args):
                moat_unanalyzable(words, "código embutido noutra linguagem/executor")
        elif base in ("ssh", "tmux", "screen", "parallel", "trap", "make", "busybox"):
            moat_unanalyzable(words, "código embutido noutra linguagem/executor")
    if base == "xargs":
        # o lib só monta o comando concreto para git/gh; aqui, para qualquer programa: com stdin LITERAL
        # (`echo onion-vps-x | xargs systemctl restart`) julga-se o comando montado; sem ele, pela forma
        tail = list(args)
        while tail and tail[0].startswith("-"):
            opt = tail.pop(0)
            if opt in ("-I", "-n", "-P", "-d", "-a", "-E", "-L", "-s") and tail:
                tail.pop(0)
        known = literal_stdin(stdin_from)
        # `-I{}` colado (e `-i`/`--replace`) também é substituição: a 1ª redação só via `-I` solto, e
        # `echo '<cmd>' | xargs -I{} bash -c '{}'` montava `bash -c {} <cmd>` e passava (SAC-148, medido)
        replaces = any(a.startswith(("-I", "-i", "--replace")) for a in args)
        if tail and known is not None and not replaces:
            command(tail + known, depth + 1)
        elif tail and moat_relevant(list(stdin_from or []) + list(words)):
            moat_unanalyzable(list(stdin_from or []) + list(words), "xargs com argumentos do stdin")
