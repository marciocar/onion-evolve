#!/usr/bin/env -S python3 -I
# one_touch.py — o motor da AUTORIZAÇÃO DE UM TOQUE («pode rodar»), nível 1.
#
# ── A DOR (2026-11-18) ───────────────────────────────────────────────────────────────────────────────────────────
# O maestro quer dizer «pode rodar» no prompt da sessão e o ato preparado rodar ali, sem copiar comando para o terminal
# dele. Até aqui o ato do maestro (o merge de PR que toca a própria catraca, ou guarda sem resíduo isolado) só saía
# com --maestro, que o veto do hook do core barra na linha da sessão. Desenho aprovado em 18/11 com a ressalva «Opção
# 1 para começar, mas isso pode virar até 2fa no futuro»: por isso todo ato carrega NÍVEL, e só o 1 é implementado.
#
# ── O FLUXO ──────────────────────────────────────────────────────────────────────────────────────────────────────
#   1. A sessão prepara o ato (o executor só pede depois de TODOS os gates dele, CI verde no head) e grava o PEDIDO
#      canônico (onion.act-request/1, act-request.schema.json ao lado) em <estado>/requests/<session>.json.
#   2. O maestro digita a frase no prompt DAQUELA sessão. O hook UserPromptSubmit (subcomando `hook`) grava a
#      APROVAÇÃO (onion.act-approval/1): o hash do pedido, a evidência (prompt_id, transcript), TTL de 10 min a partir
#      da PALAVRA. Ele não vê o transcript da mensagem atual (medido: o harness grava a entrada DEPOIS do hook), então
#      só confere o texto: a frase é o prompt inteiro, sem moldura de outra sessão ou de sistema.
#   3. O EXECUTOR (subcomandos `verify` e `consume`) recalcula repo, ref e sha no vivo, confere os dois hashes, o TTL,
#      o livro de uso único DELE e, no transcript, que a entrada do prompt_id é de humano: origin.kind=human,
#      promptSource typed|queued, sem isMeta. Mensagem de peer (origin.kind=peer, isMeta) nunca autoriza. A palavra
#      digitada NO MEIO do turno (medido 20/11) chega ao hook com o prompt_id do turno em curso e vira attachment
#      queued_command sem promptId: o executor a acha dentro desse turno (transcript_word) e julga a origem dela.
#
# ── A PALAVRA COM NÚMERO (2026-11-25) ────────────────────────────────────────────────────────────────────────────
# Pedido do maestro: «quando eu digo "pode rodar 1763" ou "merge 1763" ou similar que você tenha certeza do que eu estou
# falando, execute se ok, não fique me travando pedindo para fazer somente se eu escrever a mão "pode rodar" no momento
# certo». A frase que NOMEIA o PR dispensa o pedido prévio: o hook lê o PR no forge (repo do cwd) e grava UMA aprovação
# por número, com o head daquele instante, em approvals/<sessão>.pr-<n>.json. O resto é o fluxo de sempre: o executor
# roda TODOS os gates (CI verde no head, ponta da base, catraca), recusa se o head andou depois da palavra, confere no
# transcript que a frase digitada por humano nomeia aquele PR e grava o uso no livro (um uso por número). A frase tem de
# ser a mensagem inteira (parse_word: lista FECHADA de verbos, só números de PR, «?» final não vale: pergunta não é ordem).
#
# ── HONESTIDADE (o teto, escrito no topo de propósito) ───────────────────────────────────────────────────────────
# Isto é camada de CONFORMIDADE, NÃO fronteira de segurança. No mesmo usuário Unix o agente pode escrever o arquivo de
# aprovação, o livro e até o transcript. O que a camada impede é a sessão se AUTOAUTORIZAR POR ENGANO (ou por mensagem
# de outra sessão). Fronteira exige o nível 2: aprovação numa identidade que o agente não controla (DM assinada pela
# ponte de mensageria da família, ou review no forge por conta humana com os agentes em identidade própria, bot/App), no
# padrão de mercado de step-up (RFC 9470), aprovação desacoplada (CIBA) e NIST 800-63-4 AAL2/AAL3. Não usamos o "ask"
# de hook: há relatos de que ele é auto-aprovado em bypassPermissions, o modo das sessões da casa.
# O corpo da aprovação nunca passa pela campainha (doorbell): por lá, se um dia passar algo, só ponteiro.
#
# Uso:
#   one_touch.py request --act merge --repo R --ref REF --sha SHA [--pr N] --session SID --run CMD [--level 1]
#   one_touch.py hook            < payload UserPromptSubmit (stdout: JSON additionalContext; exit 0 sempre)
#   one_touch.py verify  --act merge --repo R --ref REF --sha SHA [--pr N] --session SID
#        exit 0 viva · 3 viva mas o alvo mudou (o executor consome e recusa) · 1 não há/recusada
#   one_touch.py consume --session SID [--pr N] --outcome TEXTO   (grava o hash no livro do executor; exit 1 se já usada)
#   one_touch.py canon < json    (imprime o hash canônico; para a bancada e para quem adotar o esquema)
# Estado: ${XDG_STATE_HOME:-~/.local/state}/onion/approvals (modo 700). Transcripts: ${CLAUDE_CONFIG_DIR:-~/.claude}.
# Logs no formato dos atos da vps-ops: <estado>/acts/approval-<evento>-<UTC>.log, última linha «✓ RESULTADO» ou
# «✗ RESULTADO»; e <estado>/usage.tsv para medir a experiência (segundos entre o pedido e a palavra).
import fcntl
import hashlib
import json
import os
import re
import secrets
import sys
import time
import unicodedata

PHRASES = {"pode rodar"}
APPROVAL_TTL_S = 600          # 10 min a partir da palavra
REQUEST_MAX_AGE_S = 1800      # pedido sem palavra em 30 min caduca
HUMAN_PROMPT_SOURCES = {"typed", "queued"}
MIDTURN_SKEW_S = 30           # a mensagem do meio do turno nasce a até 30 s da gravação da aprovação (medido: < 1 s)
FOREIGN_MARKERS = ("<cross-session-message", "<system-reminder", "<task-notification", "<teammate-message")
# A PALAVRA COM NÚMERO: verbos de lista fechada, conectivo opcional («do», «o», «pr»), 1 a WORD_MAX_PRS números
WORD_VERBS = ("pode rodar", "pode mergear", "pode fazer o merge", "pode fazer merge", "merge", "mergeia", "mergear")
WORD_MAX_PRS = 5
WORD_SKEW_S = 60              # a palavra com número cria o pedido no hook: a entrada do transcript nasce perto dele
HOOK_BUDGET_S = 8             # o hook tem 10 s no settings; cada PR custa uma leitura no forge (medido: ~0,5 s)
_NUM = r"#?[1-9][0-9]{0,6}"
# vírgula SÓ com espaço depois (revisão isolada de 2026-11-25, B): «1,763» é um número com milhar, não #1 e #763
_SEP = r"(?: ?, | e | and | \+ | & | )"
_WORD_PR_RE = re.compile(r"(?:%s)(?: (?:do|da|o|no))?(?: pr)? (%s(?:%s(?:pr )?%s)*)"
                         % ("|".join(re.escape(v) for v in WORD_VERBS), _NUM, _SEP, _NUM))
_WORD_LOOSE_RE = re.compile(r"\b(?:%s)\b.*#?[0-9]" % "|".join(re.escape(v) for v in WORD_VERBS))
HEAD_MIN_AGE_S = 120         # o head mais novo que isto o maestro não viu: «o PR acabou de mudar; repita a frase»
# os arquivos que SÃO a catraca (a mesma lista do _ratchet_hits do executor): PR que toca um deles não sai por palavra
# com número, porque ela amarra um head que o maestro não viu; ali segue o pedido com o sha na tela (revisão de 25/11, A)
RATCHET_RE = re.compile(r"docs/evolution/federation/members\.yaml|ops/pr-merge-verified\.sh|ops/moat-targets\.tsv|\.claude/hooks/pretooluse-moat-gate\.sh|\.claude/hooks/lib/moat-judge\.py|\.claude/hooks/lib/invocation-lines\.sh|\.claude/settings(\.local)?\.json")  # (core-only)
ENGINE_ROOT = os.path.realpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", ".."))
# O que a v1 implementa. Ponto de extensão: o canal novo entra aqui com a sua verificação, nunca por fora.
#   nível 2 → "slack-signed": a ponte de mensageria da família entrega a DM assinada; o portão por identidade da ponte
#             verifica e grava a aprovação; o executor confere a assinatura (não implementado).
#   nível 3 → "passkey": WebAuthn/2FA (não implementado).
IMPLEMENTED = {("maestro", "execution", "prompt"): 1}
DECLARED_CHANNELS = {"prompt": 1, "slack-signed": 2, "passkey": 3}
# Política mínima por ato (o nível 2 só entra onde o risco pedir; deploy/firewall/segredo/publicação ficam FORA da v1)
# effect: read (leitura pura NUNCA pede aprovação) · write · external. `plan` (aprovação por lote, N passos, um «pode
# rodar» com escopo e prazo, cada passo conferido pelo hash) está declarado no esquema e fora da v1.
ACT_POLICY = {"merge": {"level": 1, "effect": "external",
                        "approvals_required": [{"role": "maestro", "scope": "execution", "min_level": 1}]}}
OUT_OF_V1 = {"deploy", "firewall", "secret", "publish"}


def state_dir():
    base = os.environ.get("XDG_STATE_HOME") or os.path.join(os.path.expanduser("~"), ".local", "state")
    return os.path.join(base, "onion", "approvals")


def projects_root():
    base = os.environ.get("CLAUDE_CONFIG_DIR") or os.path.join(os.path.expanduser("~"), ".claude")
    return os.path.realpath(os.path.join(base, "projects"))


def utc(ts=None):
    return time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime(ts if ts is not None else time.time()))


def parse_utc(s):
    import calendar
    return calendar.timegm(time.strptime(s, "%Y-%m-%dT%H:%M:%SZ"))


def canonical(obj):
    """JSON com chaves ordenadas, sem espaços, UTF-8 (estilo JCS; o esquema só usa inteiros)."""
    return json.dumps(obj, sort_keys=True, separators=(",", ":"), ensure_ascii=False).encode("utf-8")


def digest(obj):
    body = {k: v for k, v in obj.items() if k != "hash"}
    return hashlib.sha256(canonical(body)).hexdigest()


def script_sha(path):
    """sha256 do CONTEÚDO do executor: o pedido e a conferência amarram o script, não só o nome do ato."""
    try:
        with open(path, "rb") as f:
            return hashlib.sha256(f.read()).hexdigest()
    except OSError:
        return ""


def norm_phrase(s):
    # aparadas as bordas, espaço interno colapsado, sem diferença de caixa, e um ponto ou exclamação final tolerado
    return re.sub(r"\s+", " ", unicodedata.normalize("NFC", s or "")).strip().casefold().rstrip(".!").strip()


def parse_word(text):
    """("bare", ()) para «pode rodar» sozinho; ("pr", (n, …)) para a frase com número(s) sozinha; None no resto
    (moldura de outra sessão ou do sistema, texto a mais, pergunta, mais de WORD_MAX_PRS números)."""
    if any(m in (text or "").casefold() for m in FOREIGN_MARKERS):
        return None
    t = norm_phrase(text)
    if t in PHRASES:
        return ("bare", ())
    m = _WORD_PR_RE.fullmatch(t)
    if not m:
        return None
    nums = []
    for x in re.findall(r"[0-9]+", m.group(1)):
        if int(x) not in nums:
            nums.append(int(x))
    if not nums or len(nums) > WORD_MAX_PRS:
        return None
    return ("pr", tuple(nums))


def slug_norm(url):
    """O mesmo _slug_norm do executor: minúsculas antes, prefixo de host fora, .git e barra final fora."""
    s = (url or "").strip().lower()
    s = re.sub(r"^(git@[^:]+:|ssh://git@[^/]+/|https?://([^@/]+@)?[^/]+/|github\.com/)", "", s)
    s = re.sub(r"\.git$", "", s).rstrip("/")
    return s if re.fullmatch(r"[a-z0-9._-]+/[a-z0-9._-]+", s) else ""


def approval_path(sid, pr=None):
    return os.path.join(state_dir(), "approvals", ("%s.pr-%d.json" % (sid, int(pr))) if pr else sid + ".json")


def ensure_dirs():
    root = state_dir()
    for sub in ("", "requests", "approvals", "ledger", "acts"):
        p = os.path.join(root, sub)
        os.makedirs(p, mode=0o700, exist_ok=True)
        os.chmod(p, 0o700)
    return root


def safe_sid(sid):
    if not sid or not re.fullmatch(r"[A-Za-z0-9_-]{8,128}", sid):
        raise ValueError("session id ilegível")
    return sid


def write_atomic(path, obj):
    tmp = "%s.%d.tmp" % (path, os.getpid())
    fd = os.open(tmp, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
    with os.fdopen(fd, "w", encoding="utf-8") as f:
        json.dump(obj, f, ensure_ascii=False, sort_keys=True, indent=1)
    os.replace(tmp, path)


def read_json(path):
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def act_log(event, lines, ok, result):
    """Log no formato dos atos da vps-ops: cabeçalho, linhas, última linha ✓/✗ RESULTADO."""
    try:
        root = ensure_dirs()
        stamp = time.strftime("%Y%m%dT%H%M%SZ", time.gmtime())
        path = os.path.join(root, "acts", "approval-%s-%s.log" % (event, stamp))
        n = 1
        while os.path.exists(path):
            n += 1
            path = os.path.join(root, "acts", "approval-%s-%s-%d.log" % (event, stamp, n))
        with open(path, "w", encoding="utf-8") as f:
            f.write("── ato approval-%s · início %s · log %s\n" % (event, utc(), path))
            for ln in lines:
                f.write(ln + "\n")
            f.write("%s RESULTADO %s\n" % ("✓" if ok else "✗", result))
        os.chmod(path, 0o600)
    except OSError:
        pass


def usage(event, act, level, secs, target, outcome):
    try:
        root = ensure_dirs()
        with open(os.path.join(root, "usage.tsv"), "a", encoding="utf-8") as f:
            f.write("\t".join(str(x) for x in (utc(), event, act, level, secs, target, outcome)) + "\n")
    except OSError:
        pass


def short_target(req):
    t = req.get("target", {})
    pr = ("#%s" % t["pr"]) if t.get("pr") else ""
    return "%s%s @%s" % (t.get("repo", "?"), pr, str(t.get("sha", ""))[:7])


def get_args(argv, names):
    out = {}
    i = 0
    while i < len(argv):
        a = argv[i]
        if a.startswith("--") and a[2:] in names and i + 1 < len(argv):
            out[a[2:]] = argv[i + 1]
            i += 2
        else:
            i += 1
    return out


# ── request ─────────────────────────────────────────────────────────────────────────────────────────────────────
def cmd_request(argv):
    a = get_args(argv, {"act", "repo", "ref", "sha", "pr", "session", "run", "level", "script", "requires-tty"})
    if a.get("requires-tty", "false") != "false":
        print("✗ ato que pede TTY (senha, GPG) nunca é autorizável por palavra: o maestro o roda no terminal dele.")
        return 1
    act = a.get("act", "")
    if act == "plan":
        print("✗ a aprovação por plano (um «pode rodar» para N passos) está declarada no esquema e não implementada na v1: peça o merge sozinho.")
        return 1
    if act in OUT_OF_V1 or act not in ACT_POLICY:
        print("✗ o ato '%s' não está na v1 do «pode rodar» (só merge); deploy, firewall, segredo e publicação seguem do maestro." % act)
        return 1
    pol = ACT_POLICY[act]
    level = int(a.get("level", pol["level"]))
    if level not in (1, 2, 3) or level < pol["level"]:
        print("✗ nível %s inválido para '%s' (mínimo %d)." % (level, act, pol["level"]))
        return 1
    if level > 1:
        print("✗ nível %d declarado e não implementado na v1 (2 = fora da banda pela ponte de mensageria da família; 3 = passkey/2FA)." % level)
        return 1
    try:
        sid = safe_sid(a.get("session", ""))
    except ValueError:
        print("✗ sem o id da sessão (CLAUDE_CODE_SESSION_ID): a palavra só vale na sessão que pediu, e não sei qual é.")
        return 1
    sha, repo, ref = a.get("sha", ""), a.get("repo", "").lower(), a.get("ref", "")
    if not re.fullmatch(r"[0-9a-f]{40}", sha) or not re.fullmatch(r"[a-z0-9._-]+/[a-z0-9._-]+", repo) or not ref.startswith("refs/"):
        print("✗ alvo ilegível (repo '%s', ref '%s', sha '%s'): o pedido precisa de repo + ref completo + sha." % (repo, ref, sha))
        return 1
    target = {"repo": repo, "ref": ref, "sha": sha}
    if a.get("pr"):
        target["pr"] = int(a["pr"])
    req = {
        "schema": "onion.act-request/1", "act": act, "target": target, "level": level, "effect": pol["effect"],
        "approvals_required": pol["approvals_required"],
        "requested_by": {"kind": "claude-session", "id": sid},
        "created_at": utc(), "nonce": secrets.token_hex(16),
        "requires_tty": False,
        "executor": {"name": "merge-verified", "run": a.get("run", ""), "script_sha256": script_sha(a.get("script", "")),
                     "args": [act, repo, ref, sha] + ([a["pr"]] if a.get("pr") else [])},
    }
    if not req["executor"]["script_sha256"]:
        print("✗ não li o script do executor (--script): o hash do pedido cobre o conteúdo dele.")
        return 1
    req["hash"] = digest(req)
    root = ensure_dirs()
    write_atomic(os.path.join(root, "requests", sid + ".json"), req)
    try:  # um pedido novo derruba a aprovação antiga desta sessão (ela era de outro hash)
        os.unlink(os.path.join(root, "approvals", sid + ".json"))
    except FileNotFoundError:
        pass
    act_log("request", ["pedido %s" % req["hash"], "alvo %s %s" % (short_target(req), ref)], True,
            "pedido · act=%s level=%d target=%s" % (act, level, short_target(req)))
    usage("request", act, level, 0, short_target(req), "pending")
    print("⏸ %s %s (%s) — responda: pode rodar" % (act, short_target(req), ref.replace("refs/heads/", "")))
    return 0


# ── hook (UserPromptSubmit) ─────────────────────────────────────────────────────────────────────────────────────
def hook_say(msg):
    print(json.dumps({"hookSpecificOutput": {"hookEventName": "UserPromptSubmit", "additionalContext": msg}}, ensure_ascii=True))


def repo_of(cwd):
    import subprocess
    try:
        r = subprocess.run(["git", "-C", cwd or ".", "remote", "get-url", "origin"], capture_output=True, text=True, timeout=3)
    except (OSError, subprocess.SubprocessError):
        return ""
    return slug_norm(r.stdout) if r.returncode == 0 else ""


def pr_live(slug, n, budget):
    """O PR lido no forge AGORA: (state, merged, head_sha, head_ref) ou levanta LookupError com o porquê."""
    import subprocess
    try:
        r = subprocess.run(["gh", "api", "repos/%s/pulls/%d" % (slug, n), "--jq", "[.state,(.merged|tostring),.head.sha,.head.ref]|@tsv"],
                           capture_output=True, text=True, timeout=max(1.0, min(5.0, budget)))
    except subprocess.TimeoutExpired:
        raise LookupError("o forge não respondeu a tempo")
    except OSError:
        raise LookupError("sem o gh não leio o PR")
    if r.returncode != 0:
        raise LookupError("não li o PR no forge (inexistente ou sem acesso)")
    cols = r.stdout.strip().split("\t")
    if len(cols) != 4:
        raise LookupError("resposta do forge ilegível")
    return cols


def HOOK_HEAD_MIN_AGE():
    return HEAD_MIN_AGE_S


def gh_lines(args, budget, what):
    """Uma leitura no forge pelo gh: as linhas da saída, ou LookupError com o porquê (falha fechada)."""
    import subprocess
    try:
        r = subprocess.run(["gh"] + args, capture_output=True, text=True, timeout=max(1.0, min(5.0, budget)))
    except subprocess.TimeoutExpired:
        raise LookupError("o forge não respondeu a tempo (%s)" % what)
    except OSError:
        raise LookupError("sem o gh não leio %s" % what)
    if r.returncode != 0:
        raise LookupError("não li %s no forge" % what)
    return [x for x in r.stdout.splitlines() if x.strip()]


def head_age_s(slug, sha, budget):
    """Segundos desde o carimbo do SERVIDOR para o head: o created_at mais antigo dos check-suites do sha, que o GitHub
    grava quando o push chega. A committer.date NÃO serve: quem commita a escreve (GIT_COMMITTER_DATE), e um head
    recém-empurrado com data antiga forjada passaria (decisão do core, 2026-11-25). Sem check-suite = o CI ainda não viu
    o head: recusa, coerente com o gate do executor que exige CI verde no head."""
    out = gh_lines(["api", "repos/%s/commits/%s/check-suites" % (slug, sha), "--paginate", "--jq", "[.check_suites[].created_at]|min"], budget, "os check-suites do head")
    stamps = [x.strip() for x in out if x.strip() and x.strip() != "null"]
    if not stamps:
        raise LookupError("o CI ainda não viu este head (@%s); repita quando o CI começar" % sha[:7])
    try:
        return time.time() - min(parse_utc(x[:19] + "Z") for x in stamps)
    except ValueError:
        raise LookupError("data do check-suite do head ilegível no forge")


def hook_numbered(payload, sid, prs, prompt):
    """A PALAVRA COM NÚMERO: sem pedido prévio, uma aprovação por PR, com o head lido no forge na hora da palavra."""
    t0 = time.time()
    pid, tp = str(payload.get("prompt_id", "")), str(payload.get("transcript_path", ""))
    if not pid or not tp:
        hook_say("✗ não registrei (falha fechada): o payload não trouxe prompt_id e transcript_path.")
        return 0
    executor = os.path.join(ENGINE_ROOT, "ops", "pr-merge-verified.sh")   # (core-only) sem ele, nada se registra
    ssha = script_sha(executor)
    if not ssha:
        hook_say("✗ não registrei: este checkout não tem o executor do merge verificado; a palavra com número vale só onde ele existe.")
        return 0
    slug = repo_of(str(payload.get("cwd") or ""))
    if not slug:
        hook_say("✗ não registrei: não li o repo do cwd (o origin). Nada foi autorizado.")
        act_log("grant", ["palavra com número sem repo legível no cwd"], False, "recusado · repo do cwd ilegível")
        return 0
    pol = ACT_POLICY["merge"]
    ensure_dirs()
    done, refused = [], []
    for n in prs:
        left = HOOK_BUDGET_S - (time.time() - t0)
        if left < 1:
            refused.append("#%d: acabou o tempo do hook; diga de novo só este número" % n)
            continue
        try:
            state, merged, sha, ref = pr_live(slug, n, left)
            if state != "open" or merged == "true":
                raise LookupError("o PR está %s" % ("mergeado" if merged == "true" else "fechado"))
            if not re.fullmatch(r"[0-9a-f]{40}", sha) or not re.fullmatch(r"[A-Za-z0-9._/-]+", ref):
                raise LookupError("head ilegível no forge")
            # o nome antigo da renomeação conta (renomear um arquivo da catraca para fora não escapa) e todas as páginas
            # contam (PR com mais de 100 arquivos não esconde um da catraca na 2ª): o mesmo jq do executor
            files = gh_lines(["api", "repos/%s/pulls/%d/files?per_page=100" % (slug, n), "--paginate", "--jq", ".[] | .filename, (.previous_filename // empty)"],
                             HOOK_BUDGET_S - (time.time() - t0), "os arquivos do PR")
            hit = [f for f in files if RATCHET_RE.fullmatch(f.strip())]
            if hit:
                raise LookupError("este PR muda a catraca (%s): peço o pedido com o sha na tela e você responde «pode rodar»" % ", ".join(hit[:3]))
            age = head_age_s(slug, sha, HOOK_BUDGET_S - (time.time() - t0))
            if age < HOOK_HEAD_MIN_AGE():
                raise LookupError("o PR acabou de mudar (head @%s há %ds); repita a frase" % (sha[:7], max(0, int(age))))
        except LookupError as e:
            refused.append("#%d: %s" % (n, e))
            act_log("grant", ["palavra com número", "alvo %s#%d" % (slug, n), "recusa: %s" % e], False, "recusado · %s#%d" % (slug, n))
            continue
        run = "bash %s %d --one-touch" % (executor, n)
        req = {
            "schema": "onion.act-request/1", "act": "merge",
            "target": {"repo": slug, "ref": "refs/heads/" + ref, "sha": sha, "pr": n},
            "level": 1, "effect": pol["effect"], "approvals_required": pol["approvals_required"],
            "requested_by": {"kind": "claude-session", "id": sid},
            "created_at": utc(t0), "nonce": secrets.token_hex(16), "requires_tty": False,
            "executor": {"name": "merge-verified", "run": run, "script_sha256": ssha,
                         "args": ["merge", slug, "refs/heads/" + ref, sha, str(n)]},
        }
        req["hash"] = digest(req)
        appr = {
            "schema": "onion.act-approval/1", "request_hash": req["hash"], "request": req,
            "approvals": [{"role": "maestro", "approver_id": "prompt:" + sid, "channel": "prompt", "level": 1, "at": utc(t0)}],
            "evidence": {"prompt_id": pid, "transcript_path": tp, "phrase": norm_phrase(prompt), "pr": n},
            "expires_at": utc(t0 + APPROVAL_TTL_S), "nonce": secrets.token_hex(16),
        }
        appr["hash"] = digest(appr)
        try:
            write_atomic(approval_path(sid, n), appr)
        except OSError as e:
            refused.append("#%d: não gravei (%s)" % (n, e))
            continue
        done.append((n, sha, run))
        act_log("grant", ["aprovação %s (palavra com número, sem pedido prévio)" % appr["hash"], "canal prompt · prompt_id %s" % pid],
                True, "autorizado · act=merge level=1 wait_s=0 target=%s" % short_target(req))
        usage("grant", "merge", 1, 0, short_target(req), "granted-word-pr")
    parts = []
    if done:
        parts.append("✓ palavra registrada (nível 1, 10 min, uso único por PR, sem pedido prévio) em %s: %s. Vale se o maestro DIGITOU a frase (sugestão aceita não autoriza); o executor roda todos os gates e recusa se o head andou. Rode agora, um por vez: %s"
                     % (slug, ", ".join("#%d @%s" % (n, sha[:7]) for n, sha, _ in done), " ; ".join(r for _, _, r in done)))
    if refused:
        parts.append("✗ não registrei: %s." % "; ".join(refused))
    hook_say(" ".join(parts))
    return 0


def cmd_hook(_argv):
    try:
        payload = json.loads(sys.stdin.read() or "{}")
    except (ValueError, OSError):
        return 0
    prompt = payload.get("prompt")
    if not isinstance(prompt, str):
        return 0
    low = prompt.casefold()
    word = parse_word(prompt)
    numbered = len(norm_phrase(prompt)) <= 80 and bool(_WORD_LOOSE_RE.search(norm_phrase(prompt)))
    mentions = any(p in norm_phrase(prompt) for p in PHRASES) or numbered
    if not mentions:
        return 0                                   # silêncio: custo zero no turno honesto
    sid = payload.get("session_id", "")
    try:
        sid = safe_sid(sid)
    except ValueError:
        return 0
    if word and word[0] == "pr":
        return hook_numbered(payload, sid, word[1], prompt)
    if word is None and numbered:
        if any(m in low for m in FOREIGN_MARKERS):
            hook_say("✗ não registrei: mensagem com moldura de outra sessão ou do sistema nunca autoriza. Só a frase digitada pelo maestro, sozinha.")
            act_log("grant", ["prompt com número e moldura estrangeira"], False, "recusado · moldura de outra sessão/sistema")
        else:
            hook_say("✗ não registrei: a frase com número tem de ser a mensagem inteira, sem mais texto e sem «?» (ex.: «pode rodar 1763», «merge #1763», «pode rodar 1763 e 1765»).")
            act_log("grant", ["frase com número dentro de texto maior"], False, "recusado · a frase com número não é o prompt inteiro")
        return 0
    root = state_dir()
    req_path = os.path.join(root, "requests", sid + ".json")
    if not os.path.isfile(req_path):
        if norm_phrase(prompt) in PHRASES:
            hook_say("«pode rodar» sem ato pendente nesta sessão: nada foi autorizado. A sessão prepara o ato primeiro (o executor pede e mostra a linha «responda: pode rodar»).")
        return 0
    if any(m in low for m in FOREIGN_MARKERS):
        hook_say("✗ não autorizei: mensagem com moldura de outra sessão ou do sistema nunca autoriza. Só a frase digitada pelo maestro, sozinha.")
        act_log("grant", ["prompt com moldura estrangeira"], False, "recusado · moldura de outra sessão/sistema")
        return 0
    if norm_phrase(prompt) not in PHRASES:
        hook_say("✗ não autorizei: «pode rodar» tem de ser a mensagem inteira, sem mais texto. Digite só: pode rodar")
        act_log("grant", ["frase dentro de texto maior"], False, "recusado · a frase não é o prompt inteiro")
        return 0
    try:
        req = read_json(req_path)
        if req.get("hash") != digest(req) or req.get("schema") != "onion.act-request/1":
            raise ValueError("hash do pedido não bate")
        if (req.get("requested_by") or {}).get("id") != sid:
            raise ValueError("o pedido é de outra sessão")
        age = time.time() - parse_utc(req["created_at"])
        if age > REQUEST_MAX_AGE_S or age < -60:
            hook_say("✗ não autorizei: o pedido de %s caducou (30 min sem a palavra). A sessão prepara de novo." % req["created_at"][11:16])
            act_log("grant", ["pedido %s velho (%ds)" % (req.get("hash", "?")[:12], age)], False, "recusado · pedido caducou")
            return 0
        now = time.time()
        appr = {
            "schema": "onion.act-approval/1", "request_hash": req["hash"], "request": req,
            "approvals": [{"role": "maestro", "approver_id": "prompt:" + sid, "channel": "prompt", "level": 1, "at": utc(now)}],
            "evidence": {"prompt_id": str(payload.get("prompt_id", "")), "transcript_path": str(payload.get("transcript_path", "")),
                         "phrase": norm_phrase(prompt)},
            "expires_at": utc(now + APPROVAL_TTL_S), "nonce": secrets.token_hex(16),
        }
        if not appr["evidence"]["prompt_id"] or not appr["evidence"]["transcript_path"]:
            raise ValueError("o payload não trouxe prompt_id e transcript_path")
        appr["hash"] = digest(appr)
        ensure_dirs()
        write_atomic(os.path.join(root, "approvals", sid + ".json"), appr)
    except (OSError, ValueError, KeyError, TypeError) as e:
        hook_say("✗ não autorizei (falha fechada): %s." % e)
        act_log("grant", ["erro: %s" % e], False, "recusado · falha fechada")
        return 0
    wait = int(now - parse_utc(req["created_at"]))
    act_log("grant", ["aprovação %s do pedido %s" % (appr["hash"], req["hash"]), "canal prompt · prompt_id %s" % appr["evidence"]["prompt_id"]],
            True, "autorizado · act=%s level=1 wait_s=%d target=%s" % (req["act"], wait, short_target(req)))
    usage("grant", req["act"], 1, wait, short_target(req), "granted")
    run = (req.get("executor") or {}).get("run", "")
    # o hook não vê a origem (a entrada do transcript nasce depois dele): a promessa é condicional, e diz a condição
    hook_say("✓ palavra registrada (nível 1, 10 min, uso único): %s %s. Vale se o maestro DIGITOU a frase (sugestão aceita não autoriza); o executor confere no transcript. Rode agora: %s" % (req["act"], short_target(req), run))
    return 0


# ── verify / consume (o EXECUTOR) ───────────────────────────────────────────────────────────────────────────────
def numbered_dead(path):
    """'' se a aprovação por número ainda pode valer; senão o porquê (venceu, já foi usada, ilegível)."""
    try:
        appr = read_json(path)
        if time.time() > parse_utc(appr["expires_at"]):
            return "venceu (10 min)"
        with open(ledger_path(), encoding="utf-8") as f:
            if any(line.split("\t", 1)[0] == appr.get("hash") for line in f):
                return "já foi usada"
    except FileNotFoundError:
        return ""
    except (OSError, ValueError, KeyError, TypeError):
        return "está ilegível"
    return ""


def load_live(sid, pr=None):
    """A aprovação viva: a da palavra com número deste PR, se houver; senão a do pedido da sessão."""
    path = approval_path(sid)
    if pr and re.fullmatch(r"[1-9][0-9]{0,6}", str(pr)) and os.path.isfile(approval_path(sid, pr)):
        dead = numbered_dead(approval_path(sid, pr))
        if not dead:
            path = approval_path(sid, pr)
        elif not os.path.isfile(path):
            # (revisão de 25/11, C) a palavra com número vencida ou gasta não sombreia o pedido vivo; sem ele, diz qual
            raise LookupError("a palavra com número para o PR #%s %s: diga de novo «pode rodar %s»" % (pr, dead, pr))
    if not os.path.isfile(path):
        raise LookupError("não há autorização viva desta sessão: prepare o ato e peça «pode rodar» ao maestro")
    appr = read_json(path)
    if appr.get("schema") != "onion.act-approval/1" or appr.get("hash") != digest(appr):
        raise LookupError("o hash da aprovação não bate (arquivo mexido)")
    req = appr.get("request") or {}
    if req.get("hash") != digest(req) or appr.get("request_hash") != req.get("hash"):
        raise LookupError("o hash do pedido não bate com o da aprovação")
    wpr = (appr.get("evidence") or {}).get("pr")
    if wpr is not None and wpr != (req.get("target") or {}).get("pr"):
        raise LookupError("a palavra nomeia o PR #%s e o pedido é de outro" % wpr)
    return appr, req


def ledger_path():
    return os.path.join(state_dir(), "ledger", "merge-executor.tsv")


def ledger_hit(lines, appr, word_id):
    """Uso único AMARRADO À PALAVRA: o livro guarda o hash da aprovação E o id da palavra (o prompt_id, ou prompt_id/uuid
    da mensagem do meio do turno). Uma aprovação regravada para a mesma palavra tem hash novo, mas a palavra já está no
    livro."""
    wid = word_id or "\0"
    # «P/*» é a marca do consume que não leu o transcript: gasta toda palavra do turno P (topo e meio)
    fam = re.split(r"[/#]", wid, 1)[0] + "/*"
    for line in lines:
        cols = line.rstrip("\n").split("\t")
        if cols[0] == appr["hash"] or (len(cols) > 1 and cols[1] in (wid, fam)):
            return True
    return False


def ledger_has(appr, word_id):
    try:
        with open(ledger_path(), encoding="utf-8") as f:
            return ledger_hit(f, appr, word_id)
    except FileNotFoundError:
        return False


def is_word(text, pr=None):
    """A frase sozinha, sem moldura de outra sessão ou de sistema. Com pr: a frase com número que nomeia ESTE PR."""
    w = parse_word(text)
    if pr is None:
        return w == ("bare", ())
    return bool(w) and w[0] == "pr" and int(pr) in w[1]


def entry_ts(e):
    ts = e.get("timestamp", "")
    try:
        return parse_utc(str(ts)[:19] + "Z"), ts
    except ValueError:
        raise LookupError("o prompt da palavra sem horário legível")


def transcript_word(appr, req):
    """Acha a PALAVRA no transcript e devolve (entrada normalizada, id da palavra, horário). Duas formas, medidas:

    - TOPO (sessão parada): entrada type=user com o promptId do payload, a frase no message.content, origin.kind e
      promptSource na própria entrada. O id da palavra é o prompt_id.
    - MEIO DO TURNO (medido em 20/11, prompt_id d82f5d09 e 81ad8498): o hook recebe o prompt_id do TURNO EM CURSO, e a
      mensagem vira type=attachment com attachment.type=queued_command, SEM promptId; a frase em attachment.prompt e a
      origem em attachment.origin (human: commandMode=prompt, humanTurn=true; peer: origin.kind=peer, isMeta). Ela é a
      palavra só se está DENTRO do turno do prompt_id (o último promptId visto antes dela é o do payload) e nasceu a
      MIDTURN_SKEW_S da gravação da aprovação. O id da palavra é prompt_id/uuid da mensagem.
    Escolhe-se, entre as candidatas que trazem a frase, a mais perto da aprovação; a origem se julga DEPOIS, na escolhida.
    LIMITE MEDIDO (revisão de 20/11, M1): nenhuma das 44 mensagens humanas do meio do turno no transcript do core traz
    promptSource, então esta forma NÃO distingue digitado de sugestão aceita. Os 32 aceites de sugestão medidos vieram
    todos com a sessão parada (forma de topo, recusada). Se o harness um dia marcar promptSource aqui, ele é julgado.
    """
    ev = appr.get("evidence") or {}
    pid = str(ev.get("prompt_id") or "")
    wpr = ev.get("pr")
    wsuf = ("#%d" % int(wpr)) if wpr is not None else ""   # um uso POR PR: «pode rodar 1763 e 1765» são duas palavras
    if not pid:
        raise LookupError("a aprovação não traz o prompt_id da palavra")
    try:
        granted = parse_utc(((appr.get("approvals") or [{}])[0]).get("at", ""))
    except (ValueError, TypeError):
        raise LookupError("a aprovação sem horário legível")
    cands = []
    cur = None
    with open(ev["transcript_path"], encoding="utf-8", errors="replace") as f:
        for line in f:
            # filtro barato de linha; a amarra ao turno fica num lugar só, adiante (cur != pid)
            if pid not in line and '"queued_command"' not in line and '"promptId"' not in line:
                continue
            try:
                e = json.loads(line)
            except (ValueError, RecursionError):
                continue
            if not isinstance(e, dict) or e.get("isSidechain"):
                continue
            if e.get("type") == "user" and e.get("promptId"):
                m = e.get("message")
                c = m.get("content") if isinstance(m, dict) else None
                # tool_result herda o promptId do turno e não abre turno: não move a amarra (revisão de 20/11, M4)
                if isinstance(c, list) and c and all(isinstance(x, dict) and x.get("type") == "tool_result" for x in c):
                    continue
                cur = e.get("promptId")
                if cur != pid:
                    continue
                # o MESMO promptId pode ter mais de uma entrada (medido em 18/11: a auto-compactação disparada no envio
                # grava o resumo com o promptId do prompt, ANTES dele). Candidata é a que traz a frase.
                text = c if isinstance(c, str) else "".join(x.get("text", "") for x in (c or []) if isinstance(x, dict) and x.get("type") == "text")
                if is_word(text, wpr):
                    when, ts = entry_ts(e)
                    cands.append((abs(when - granted), when, ts, pid + wsuf, {"origin": e.get("origin"), "promptSource": e.get("promptSource"),
                                                                        "isMeta": e.get("isMeta"), "form": "topo"}))
                continue
            if e.get("type") != "attachment" or cur != pid:
                continue
            a = e.get("attachment")
            if not isinstance(a, dict) or a.get("type") != "queued_command" or not isinstance(a.get("prompt"), str):
                continue
            if not is_word(a["prompt"], wpr):
                continue
            when, ts = entry_ts(e)
            if abs(when - granted) > MIDTURN_SKEW_S:
                continue
            src = str(a.get("source_uuid") or e.get("uuid") or "")
            if not src:
                continue
            ps = a.get("promptSource", e.get("promptSource"))
            human_turn = a.get("humanTurn") is True and a.get("commandMode") == "prompt"
            cands.append((abs(when - granted), when, ts, pid + "/" + src + wsuf, {
                # sem humanTurn=true e commandMode=prompt não há promptSource humano; com eles, o ausente vale queued
                # (a forma medida) e o presente se julga como está (suggestion_accepted recusa)
                "origin": a.get("origin"), "promptSource": (("queued" if ps is None else ps) if human_turn else None),
                "isMeta": e.get("isMeta") or a.get("isMeta"), "form": "meio do turno"}))
    if not cands:
        raise LookupError("a frase do prompt da palavra (prompt_id %s) não está no transcript, nem no topo nem no meio do turno" % pid[:8])
    cands.sort(key=lambda x: x[0])
    _, when, ts, word_id, found = cands[0]
    return found, word_id, when, ts


def transcript_human(appr, req):
    ev = appr.get("evidence") or {}
    sid = req["requested_by"]["id"]
    tp = os.path.realpath(ev.get("transcript_path", ""))
    root = projects_root()
    if not tp.startswith(root + os.sep) or os.path.basename(tp) != sid + ".jsonl":
        raise LookupError("o transcript da aprovação não é o desta sessão em %s" % root)
    found, word_id, when, ts = transcript_word(dict(appr, evidence=dict(ev, transcript_path=tp)), req)
    origin = found.get("origin") or {}
    if not isinstance(origin, dict) or origin.get("kind") != "human" or found.get("promptSource") not in HUMAN_PROMPT_SOURCES or found.get("isMeta"):
        raise LookupError("o prompt da palavra (%s) não é humano digitado (origin.kind=%s, promptSource=%s, isMeta=%s): mensagem de outra sessão ou sugestão aceita nunca autoriza"
                          % (found.get("form"), origin.get("kind") if isinstance(origin, dict) else "?", found.get("promptSource"), bool(found.get("isMeta"))))
    created = parse_utc(req["created_at"])
    # a palavra com número CRIA o pedido no hook (o transcript a grava depois, com o horário do envio): folga de WORD_SKEW_S
    if when + (WORD_SKEW_S if ev.get("pr") is not None else 1) < created:
        raise LookupError("o prompt da palavra é anterior ao pedido")
    # o TTL conta da PALAVRA no transcript, não da gravação da aprovação (regravar a aprovação não renova o prazo)
    if time.time() > when + APPROVAL_TTL_S:
        raise LookupError("a autorização venceu (10 min desde a palavra, %s UTC): peça de novo" % ts[11:16])
    return word_id


def cmd_verify(argv):
    a = get_args(argv, {"act", "repo", "ref", "sha", "pr", "session", "script"})
    try:
        sid = safe_sid(a.get("session", ""))
        appr, req = load_live(sid, a.get("pr"))
        if req.get("requested_by", {}).get("id") != sid:
            raise LookupError("a aprovação é de outra sessão")
        if time.time() > parse_utc(appr["expires_at"]):
            raise LookupError("a autorização venceu (10 min desde %s UTC): peça de novo" % appr["approvals"][0]["at"][11:16])
        for need in req.get("approvals_required", []):
            ok = False
            for got in appr.get("approvals", []):
                key = (got.get("role"), need.get("scope"), got.get("channel"))
                if got.get("role") != need.get("role"):
                    continue
                if key not in IMPLEMENTED:
                    raise LookupError("aprovação de papel '%s', escopo '%s', canal '%s' está declarada e não implementada na v1"
                                      % key)
                if int(got.get("level", 0)) >= int(need.get("min_level", 9)):
                    ok = True
            if not ok:
                raise LookupError("falta a aprovação de '%s' (%s, nível ≥ %s)" % (need.get("role"), need.get("scope"), need.get("min_level")))
        if req.get("level") != 1:
            raise LookupError("nível %s declarado e não implementado na v1" % req.get("level"))
        word_id = transcript_human(appr, req)
        if ledger_has(appr, word_id):
            raise LookupError("esta autorização já foi usada (livro do executor): peça de novo")
        if (req.get("executor") or {}).get("script_sha256") != script_sha(a.get("script", "")) or req.get("requires_tty") is not False:
            raise LookupError("o executor mudou desde o pedido (sha256 do script; rode do MESMO checkout em que pediu): peça de novo")
        t = req["target"]
        if req.get("act") != a.get("act") or t.get("repo") != a.get("repo", "").lower() \
                or (a.get("pr") and str(t.get("pr")) != a.get("pr")):
            raise LookupError("a autorização é de outro ato (%s %s), não deste" % (req.get("act"), short_target(req)))
        if t.get("sha") != a.get("sha") or t.get("ref") != a.get("ref"):
            print("✗ o sha mudou (%s → %s): a autorização foi gasta; peça de novo depois do verde." % (t.get("sha", "")[:7], a.get("sha", "")[:7]))
            return 3
    except (LookupError, ValueError, KeyError, TypeError, OSError) as e:
        print("✗ %s." % e)
        return 1
    numbered = (appr.get("evidence") or {}).get("pr") is not None
    print("✓ autorização viva (nível 1, canal prompt, humano no transcript%s): %s %s, vence %s UTC"
          % (", palavra com número" if numbered else "", req["act"], short_target(req), appr["expires_at"][11:19]))
    # rc 4 = viva e é a palavra com número: o executor não a aceita no PR que muda a catraca (revisão de 25/11, A)
    return 4 if numbered else 0


def cmd_consume(argv):
    a = get_args(argv, {"session", "outcome", "pr"})
    try:
        sid = safe_sid(a.get("session", ""))
        appr, req = load_live(sid, a.get("pr"))
    except (LookupError, ValueError, OSError) as e:
        print("✗ não consumi: %s." % e)
        return 1
    # o id da palavra (prompt_id no topo, prompt_id/uuid no meio do turno); o consume só roda depois do verify ter
    # aceito, e se o transcript não se ler agora (por QUALQUER erro), grava «prompt_id/*», que gasta toda palavra do
    # turno: gastar mais, nunca menos (revisão de 20/11, M2 e M3)
    try:
        word_id = transcript_human(appr, req)
    except Exception:
        word_id = str((appr.get("evidence") or {}).get("prompt_id") or "-") + "/*"
    ensure_dirs()
    outcome = re.sub(r"[\t\n]", " ", a.get("outcome", "used"))[:200]
    with open(ledger_path(), "a+", encoding="utf-8") as f:
        fcntl.flock(f, fcntl.LOCK_EX)
        f.seek(0)
        if ledger_hit(f, appr, word_id):
            print("✗ esta autorização já foi usada (livro do executor): peça de novo.")
            return 1
        f.seek(0, os.SEEK_END)
        f.write("%s\t%s\t%s\t%s\t%s\t%s\n" % (appr["hash"], word_id, utc(), req["act"], short_target(req), outcome))
        f.flush()
        os.fsync(f.fileno())
    try:
        os.chmod(ledger_path(), 0o600)
    except OSError:
        pass
    since = int(time.time() - parse_utc(appr["approvals"][0]["at"]))
    ok = outcome == "used"
    act_log("consume", ["aprovação %s" % appr["hash"], "pedido %s" % req["hash"]], ok,
            "%s · act=%s level=1 since_grant_s=%d target=%s" % ("consumida" if ok else "gasta na recusa: " + outcome, req["act"], since, short_target(req)))
    usage("consume", req["act"], 1, since, short_target(req), outcome)
    print("✓ autorização consumida (uso único gravado no livro do executor).")
    return 0


def cmd_canon(_argv):
    obj = json.loads(sys.stdin.read())
    print(digest(obj))
    return 0


def main(argv):
    cmds = {"request": cmd_request, "hook": cmd_hook, "verify": cmd_verify, "consume": cmd_consume, "canon": cmd_canon}
    if len(argv) < 2 or argv[1] not in cmds:
        print("uso: one_touch.py {request|hook|verify|consume|canon} …", file=sys.stderr)
        return 2
    if argv[1] == "hook":
        try:
            return cmd_hook(argv[2:]) or 0
        except Exception as e:  # o hook nunca derruba o turno; falha fechada = não autoriza
            hook_say("✗ não autorizei (falha fechada do hook): %s" % type(e).__name__)
            return 0
    return cmds[argv[1]](argv[2:])


if __name__ == "__main__":
    sys.exit(main(sys.argv))
