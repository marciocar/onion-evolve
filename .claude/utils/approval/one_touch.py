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
#      promptSource typed|queued, sem isMeta. Mensagem de peer (origin.kind=peer, isMeta) nunca autoriza.
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
#   one_touch.py consume --session SID --outcome TEXTO   (grava o hash no livro do executor; exit 1 se já usada)
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
FOREIGN_MARKERS = ("<cross-session-message", "<system-reminder", "<task-notification", "<teammate-message")
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


def cmd_hook(_argv):
    try:
        payload = json.loads(sys.stdin.read() or "{}")
    except (ValueError, OSError):
        return 0
    prompt = payload.get("prompt")
    if not isinstance(prompt, str):
        return 0
    low = prompt.casefold()
    mentions = any(p in norm_phrase(prompt) for p in PHRASES)
    if not mentions:
        return 0                                   # silêncio: custo zero no turno honesto
    sid = payload.get("session_id", "")
    try:
        sid = safe_sid(sid)
    except ValueError:
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
def load_live(sid):
    root = state_dir()
    path = os.path.join(root, "approvals", sid + ".json")
    if not os.path.isfile(path):
        raise LookupError("não há autorização viva desta sessão: prepare o ato e peça «pode rodar» ao maestro")
    appr = read_json(path)
    if appr.get("schema") != "onion.act-approval/1" or appr.get("hash") != digest(appr):
        raise LookupError("o hash da aprovação não bate (arquivo mexido)")
    req = appr.get("request") or {}
    if req.get("hash") != digest(req) or appr.get("request_hash") != req.get("hash"):
        raise LookupError("o hash do pedido não bate com o da aprovação")
    return appr, req


def ledger_path():
    return os.path.join(state_dir(), "ledger", "merge-executor.tsv")


def ledger_hit(lines, appr):
    """Uso único AMARRADO À PALAVRA: o livro guarda o hash da aprovação E o prompt_id dela. Uma aprovação regravada para o
    mesmo prompt (o hook rodado de novo com o mesmo payload) tem hash novo, mas o prompt_id já está no livro."""
    pid = (appr.get("evidence") or {}).get("prompt_id") or "\0"
    for line in lines:
        cols = line.rstrip("\n").split("\t")
        if cols[0] == appr["hash"] or (len(cols) > 1 and cols[1] == pid):
            return True
    return False


def ledger_has(appr):
    try:
        with open(ledger_path(), encoding="utf-8") as f:
            return ledger_hit(f, appr)
    except FileNotFoundError:
        return False


def transcript_human(appr, req):
    ev = appr.get("evidence") or {}
    sid = req["requested_by"]["id"]
    tp = os.path.realpath(ev.get("transcript_path", ""))
    root = projects_root()
    if not tp.startswith(root + os.sep) or os.path.basename(tp) != sid + ".jsonl":
        raise LookupError("o transcript da aprovação não é o desta sessão em %s" % root)
    created = parse_utc(req["created_at"])
    # o MESMO promptId pode ter mais de uma entrada (medido na revisão de 18/11: a auto-compactação disparada no envio
    # grava o resumo com o promptId do prompt, ANTES dele). Julga-se a entrada que traz a frase; se nenhuma traz, recusa.
    found = None
    with open(tp, encoding="utf-8", errors="replace") as f:
        for line in f:
            if ev.get("prompt_id", "\0") not in line:
                continue
            try:
                e = json.loads(line)
            except ValueError:
                continue
            if e.get("type") != "user" or e.get("promptId") != ev.get("prompt_id"):
                continue
            c = (e.get("message") or {}).get("content")
            text = c if isinstance(c, str) else "".join(x.get("text", "") for x in (c or []) if isinstance(x, dict) and x.get("type") == "text")
            if norm_phrase(text) in PHRASES and not any(m in text.casefold() for m in FOREIGN_MARKERS):
                found = e
                break
    if found is None:
        raise LookupError("a frase do prompt da palavra (prompt_id %s) não está no transcript" % str(ev.get("prompt_id"))[:8])
    origin = found.get("origin") or {}
    if origin.get("kind") != "human" or found.get("promptSource") not in HUMAN_PROMPT_SOURCES or found.get("isMeta"):
        raise LookupError("o prompt da palavra não é humano digitado (origin.kind=%s, promptSource=%s, isMeta=%s): mensagem de outra sessão ou sugestão aceita nunca autoriza"
                          % (origin.get("kind"), found.get("promptSource"), bool(found.get("isMeta"))))
    ts = found.get("timestamp", "")
    try:
        when = parse_utc(ts[:19] + "Z")
    except ValueError:
        raise LookupError("o prompt da palavra sem horário legível")
    if when + 1 < created:
        raise LookupError("o prompt da palavra é anterior ao pedido")
    # o TTL conta da PALAVRA no transcript, não da gravação da aprovação (regravar a aprovação não renova o prazo)
    if time.time() > when + APPROVAL_TTL_S:
        raise LookupError("a autorização venceu (10 min desde a palavra, %s UTC): peça de novo" % ts[11:16])


def cmd_verify(argv):
    a = get_args(argv, {"act", "repo", "ref", "sha", "pr", "session", "script"})
    try:
        sid = safe_sid(a.get("session", ""))
        appr, req = load_live(sid)
        if req.get("requested_by", {}).get("id") != sid:
            raise LookupError("a aprovação é de outra sessão")
        if ledger_has(appr):
            raise LookupError("esta autorização já foi usada (livro do executor): peça de novo")
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
        transcript_human(appr, req)
        if (req.get("executor") or {}).get("script_sha256") != script_sha(a.get("script", "")) or req.get("requires_tty") is not False:
            raise LookupError("o executor mudou desde o pedido (sha256 do script): peça de novo")
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
    print("✓ autorização viva (nível 1, canal prompt, humano no transcript): %s %s, vence %s UTC" % (req["act"], short_target(req), appr["expires_at"][11:19]))
    return 0


def cmd_consume(argv):
    a = get_args(argv, {"session", "outcome"})
    try:
        sid = safe_sid(a.get("session", ""))
        appr, req = load_live(sid)
    except (LookupError, ValueError, OSError) as e:
        print("✗ não consumi: %s." % e)
        return 1
    ensure_dirs()
    outcome = re.sub(r"[\t\n]", " ", a.get("outcome", "used"))[:200]
    with open(ledger_path(), "a+", encoding="utf-8") as f:
        fcntl.flock(f, fcntl.LOCK_EX)
        f.seek(0)
        if ledger_hit(f, appr):
            print("✗ esta autorização já foi usada (livro do executor): peça de novo.")
            return 1
        f.seek(0, os.SEEK_END)
        f.write("%s\t%s\t%s\t%s\t%s\t%s\n" % (appr["hash"], (appr.get("evidence") or {}).get("prompt_id", "-"), utc(), req["act"], short_target(req), outcome))
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
