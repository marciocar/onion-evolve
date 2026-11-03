#!/usr/bin/env python3
# =============================================================================
# a2a-metrics.py — os registros e os contadores que a escada do vigia de eventos pede (PLAN-E da curadoria,
# docs/evolution/research/event-watcher-2026-10/PLAN-E.md, critério selado no nó C_EVENT_WATCHER_PLAN_E).
#
# POR QUE EXISTE (2026-11-03): a escada do vigia (degraus 1 a 3) só passa de desejo a gatilho com três medições
# que o core não tinha: a contagem diária da fila (verbo `count` do ops/a2a-queue-live.sh), o log de SOMBRA do
# aceite e o registro dos RASCUNHOS do aviso. Este arquivo guarda as duas últimas e a peça comum às três:
#   ce             o parse do CloudEvent dentro do corpo do sinal (só id, source, type e time; nunca o corpo)
#   shadow-append  uma linha do log de sombra do aceite (nasce no a2a-accept.sh e no archive --force-unaccepted)
#   shadow-stats   a concordância regra × humano e a taxa de reversão          (o "a2a-shadow-stats" do PLAN-E)
#   draft-append   uma linha do registro de rascunhos (nasce no a2a-rt-mcp.py e no a2a-rt-send.sh)
#   draft-stats    os rascunhos aprovados sem edição e os atos que mandam voltar (o "a2a-draft-stats" do PLAN-E)
# Um arquivo só, e não três comandos, porque o escritor (line_id, 0600, fora de árvore git, trava) e o parse do
# CloudEvent são os mesmos para todos: três cópias divergiriam.
#
# REGRAS COMUNS (PLAN-E §0): JSON Lines (UTF-8, uma linha por valor, '\n'); hora RFC 3339 sempre em UTC com Z; o
# "dia" é a data UTC; cada linha tem line_id (UUID v4) e a correção é uma linha NOVA com `supersedes`; nunca se
# reescreve uma linha. O corpo do sinal NUNCA vai ao log: só ids, hashes e decisões. O arquivo nasce 0600 num
# diretório 0700, fora de qualquer árvore git (recusa se um ancestral tem .git), e o escritor recusa symlink,
# arquivo de outro dono e arquivo legível por grupo/outros.
#
# EXIT dos contadores (PLAN-E §0): 0 mediu e nenhum gatilho disparou · 1 mediu e algum gatilho disparou ·
#   2 não pôde medir (arquivo ausente ou ilegível, linha malformada) · 3 uso inválido.
# EXIT dos escritores: 0 linha gravada (ou --check ok) · 2 não gravou · 3 uso inválido.
# Exercitado por lint-selftest.sh (run_a2a_accept_selftests: ce e sombra; run_a2a_rt_selftests: rascunhos).
# =============================================================================
import calendar
import datetime as dt
import fcntl
import json
import os
import re
import stat
import sys
import time

DECISIONS = ("accept", "reject", "hold")
MODES = ("shadow", "auto")
DRAFT_EVENTS = ("drafted", "sent", "discarded", "blocked_out_of_list", "sent_out_of_list",
                "kill_switch_on", "kill_switch_off", "blocked_rate_cap")
SHADOW_KEYS = ("line_id", "logged_at", "mode", "ce_source", "ce_id", "ce_time", "jti", "taskId", "rule_id",
               "rule_version", "rule_decision", "human_decision", "reason", "human_actor", "supersedes")
DRAFT_KEYS = ("line_id", "logged_at", "draft_id", "thread", "recipient", "supersedes_draft", "event", "actor")
# critérios do PLAN-D, sem mudar (PLAN-E §2 e §3)
RULE_ON_DAYS, RULE_ON_EVENTS, RULE_ON_AGREEMENT = 14, 50, 0.95
BACK_TO_SHADOW_RATE = 0.15
HOLD_SECONDS = 3 * 86400            # escolha da curadoria: registro na fila há mais de 3 dias sem decisão = undecided
WINDOW_7D = 7 * 86400
AUTO_SEND_SAMPLE, AUTO_SEND_RATE = 30, 0.90
DISCARD_SECONDS = 24 * 3600         # escolha da curadoria: rascunho sem sent e sem substituto em 24 h = descartado
# a regra v1 do aceite é a LINHA DE BASE declarada: aceita todo registro verificado. Não há regra de verdade ainda;
# uma regra nova troca a versão, e a contagem recomeça (PLAN-E §2)
RULE_ID, RULE_VERSION = "accept-rule", "1"

UUID_RE = re.compile(r"[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\Z")
TS_RE = re.compile(r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z\Z")
DAY_RE = re.compile(r"\d{4}-\d{2}-\d{2}\Z")
ID_RE = re.compile(r"[A-Za-z0-9][A-Za-z0-9._-]{0,127}\Z")
RFC3339_RE = re.compile(r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d{1,9})?(Z|[+-]\d{2}:\d{2})\Z")


class UsageError(Exception):
    pass


class MeasureError(Exception):
    pass


# ─────────────────────────────── peças comuns ───────────────────────────────
def new_line_id():
    """UUID v4 de os.urandom (sem o módulo uuid: o a2a-rt-mcp.py importa este arquivo sob o gancho de auditoria)."""
    b = bytearray(os.urandom(16))
    b[6] = (b[6] & 0x0F) | 0x40
    b[8] = (b[8] & 0x3F) | 0x80
    h = b.hex()
    return f"{h[:8]}-{h[8:12]}-{h[12:16]}-{h[16:20]}-{h[20:]}"


def utc_stamp(epoch=None):
    return time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime(time.time() if epoch is None else epoch))


def stamp_epoch(s):
    return calendar.timegm(time.strptime(s, "%Y-%m-%dT%H:%M:%SZ"))


def utc_day(epoch):
    return dt.datetime.fromtimestamp(epoch, dt.timezone.utc).date()


def clean_str(v, limit=256):
    """Valor de id que pode ir ao log: string imprimível, sem controle, até `limit` caracteres. Senão None."""
    if not isinstance(v, str) or not v or len(v) > limit:
        return None
    if any(not c.isprintable() for c in v):
        return None
    return v


def parse_cloudevent(body):
    """O CloudEvent 1.0 dentro do corpo do sinal, se houver: {ce_source, ce_id, ce_type, ce_time} (None quando não há).

    Corpo que não é JSON, ou JSON sem os atributos obrigatórios (specversion "1.0", id, source, type), não é
    CloudEvent: os quatro saem None. O `time` é opcional no CloudEvents e só vale em RFC 3339.
    """
    out = {"ce_source": None, "ce_id": None, "ce_type": None, "ce_time": None}
    if isinstance(body, bytes):
        try:
            body = body.decode("utf-8")
        except UnicodeDecodeError:
            return out
    if not isinstance(body, str) or not body.strip():
        return out
    try:
        ev = json.loads(body)
    except (ValueError, RecursionError):
        return out
    if not isinstance(ev, dict) or ev.get("specversion") != "1.0":
        return out
    src, eid, typ = clean_str(ev.get("source")), clean_str(ev.get("id")), clean_str(ev.get("type"))
    if not (src and eid and typ):
        return out
    out.update(ce_source=src, ce_id=eid, ce_type=typ)
    t = clean_str(ev.get("time"), 64)
    out["ce_time"] = t if t and RFC3339_RE.fullmatch(t) else None
    return out


def state_home():
    x = os.environ.get("XDG_STATE_HOME", "")
    return x if x.startswith("/") else os.path.join(os.path.expanduser("~"), ".local", "state")


def default_shadow_log(receiver):
    if not ID_RE.fullmatch(receiver or ""):
        raise UsageError("--receiver fora da forma [A-Za-z0-9._-] (1º caractere letra ou dígito)")
    return os.path.join(state_home(), "onion", "a2a-metrics", f"accept-shadow.{receiver}.jsonl")


def default_draft_log():
    st = os.environ.get("A2A_RT_STATE") or os.path.join(os.path.expanduser("~"), ".local", "state", "onion", "a2a-rt")
    return os.path.join(st, "drafts.jsonl")


def _inside_git_tree(directory):
    p = os.path.realpath(directory)
    while True:
        if os.path.lexists(os.path.join(p, ".git")):
            return p
        up = os.path.dirname(p)
        if up == p:
            return ""
        p = up


def _open_log_for_append(path):
    """Abre o log para acréscimo com as regras do §0. Levanta MeasureError com o motivo; devolve o fd."""
    path = os.path.abspath(path)
    d = os.path.dirname(path)
    if not os.path.isdir(d):
        try:
            os.makedirs(d, mode=0o700, exist_ok=True)
        except OSError as e:
            raise MeasureError(f"não criei o diretório do log {d}: {e.strerror}")
    g = _inside_git_tree(d)
    if g:
        raise MeasureError(f"o log {path} cairia dentro da árvore git {g}: o log mora fora de qualquer árvore git")
    try:
        fd = os.open(path, os.O_WRONLY | os.O_APPEND | os.O_CREAT | os.O_NOFOLLOW, 0o600)
    except OSError as e:
        raise MeasureError(f"não abri o log {path}: {e.strerror}")
    st = os.fstat(fd)
    why = ""
    if not stat.S_ISREG(st.st_mode):
        why = "não é arquivo regular"
    elif st.st_uid != os.geteuid():
        why = "é de outro dono"
    elif st.st_mode & 0o077:
        why = f"tem permissão {oct(st.st_mode & 0o777)} (grupo/outros leem ou escrevem; exige 0600)"
    if why:
        os.close(fd)
        raise MeasureError(f"o log {path} {why}: recusado")
    return fd


def append_line(path, obj):
    line = json.dumps(obj, ensure_ascii=False, separators=(",", ":")) + "\n"
    if line.count("\n") != 1:
        raise MeasureError("a linha montada tem quebra de linha interna: recusada")
    fd = _open_log_for_append(path)
    try:
        fcntl.flock(fd, fcntl.LOCK_EX)
        data = line.encode("utf-8")
        if os.write(fd, data) != len(data):
            raise MeasureError(f"escrita curta no log {path}")
    finally:
        os.close(fd)


def check_log(path):
    os.close(_open_log_for_append(path))


def read_log(path):
    """→ lista de (nº da linha, objeto ou None). Ausente ou ilegível = MeasureError (rc 2)."""
    try:
        fd = os.open(path, os.O_RDONLY | os.O_NOFOLLOW)
    except FileNotFoundError:
        raise MeasureError(f"log ausente: {path} (sem o arquivo não há medida; ausência não é zero)")
    except OSError as e:
        raise MeasureError(f"log ilegível: {path}: {e.strerror}")
    with os.fdopen(fd, "rb") as f:
        raw = f.read()
    out = []
    for n, ln in enumerate(raw.split(b"\n"), 1):
        if not ln.strip():
            continue
        try:
            o = json.loads(ln.decode("utf-8"))
            out.append((n, o if isinstance(o, dict) else None))
        except (UnicodeDecodeError, ValueError, RecursionError):
            out.append((n, None))
    return out


def _actor():
    import getpass
    try:
        return clean_str(getpass.getuser(), 64) or "desconhecido"
    except Exception:
        return "desconhecido"


# ─────────────────────────────── log de sombra ───────────────────────────────
def shadow_line(mode, rule_decision, human_decision, *, ce_source=None, ce_id=None, ce_time=None, jti=None,
                task_id=None, reason=None, supersedes=None, rule_id=RULE_ID, rule_version=RULE_VERSION, actor=None):
    obj = {"line_id": new_line_id(), "logged_at": utc_stamp(), "mode": mode, "ce_source": ce_source, "ce_id": ce_id,
           "ce_time": ce_time, "jti": jti, "taskId": task_id, "rule_id": rule_id, "rule_version": rule_version,
           "rule_decision": rule_decision, "human_decision": human_decision, "reason": reason,
           "human_actor": actor if actor is not None else (_actor() if human_decision is not None else None),
           "supersedes": supersedes}
    why = validate_shadow(obj)
    if why:
        raise UsageError(f"linha de sombra inválida: {why}")
    return obj


def validate_shadow(o):
    if not isinstance(o, dict) or tuple(sorted(o)) != tuple(sorted(SHADOW_KEYS)):
        return "chaves diferentes das do PLAN-E"
    if not isinstance(o["line_id"], str) or not UUID_RE.fullmatch(o["line_id"]):
        return "line_id fora da forma UUID"
    if not isinstance(o["logged_at"], str) or not TS_RE.fullmatch(o["logged_at"]):
        return "logged_at fora de RFC 3339 UTC com Z"
    if o["mode"] not in MODES:
        return "mode fora de shadow|auto"
    for k in ("rule_decision", "human_decision"):
        if o[k] is not None and o[k] not in DECISIONS:
            return f"{k} fora de accept|reject|hold"
    if o["rule_decision"] is None and o["human_decision"] is None:
        return "nem rule_decision nem human_decision"
    if o["mode"] == "shadow" and o["human_decision"] is None:
        return "no modo shadow a linha nasce de uma decisão humana"
    for k in ("ce_source", "ce_id", "ce_time", "jti", "taskId", "reason", "human_actor"):
        if o[k] is not None and clean_str(o[k], 512) is None:
            return f"{k} não é string imprimível"
    if not (isinstance(o["rule_id"], str) and o["rule_id"]) or not (isinstance(o["rule_version"], str) and o["rule_version"]):
        return "rule_id/rule_version ausentes"
    if o["supersedes"] is not None and (not isinstance(o["supersedes"], str) or not UUID_RE.fullmatch(o["supersedes"])):
        return "supersedes fora da forma UUID"
    if not event_key(o):
        return "sem chave de evento (ce_source + ce_id, ou jti)"
    return ""


def event_key(o):
    """Evento = par ce_source + ce_id (CloudEvents: source + id é único), ou o jti quando o corpo não tem CloudEvent."""
    if o.get("ce_source") and o.get("ce_id"):
        return ("ce", o["ce_source"], o["ce_id"])
    if o.get("jti"):
        return ("jti", o["jti"])
    return None


def _kappa(conf, total):
    if total == 0:
        return None
    po = sum(conf[d][d] for d in DECISIONS) / total
    pe = sum((sum(conf[d].values()) / total) * (sum(conf[r][d] for r in DECISIONS) / total) for d in DECISIONS)
    if pe >= 1.0:
        return None
    return round((po - pe) / (1 - pe), 4)


def shadow_stats(lines, now, queue_rows=None):
    """→ (saída, rc). `lines` = read_log(); `queue_rows` = linhas do `ops/a2a-queue-live.sh list --json` (ou None)."""
    malformed = 0
    valid = []
    for _, o in lines:
        if o is None or validate_shadow(o):
            malformed += 1
        else:
            valid.append(o)
    out = {"rule_version": None, "since": None, "days_covered": 0, "events": 0, "undecided": None, "agree": 0,
           "agreement": None, "mode": None, "decisions_7d": 0, "reversals_7d": 0, "reversal_rate_7d": None,
           "malformed": malformed, "trigger_rule_on": None, "trigger_back_to_shadow": None,
           "confusion": {r: {h: 0 for h in DECISIONS} for r in DECISIONS}, "kappa": None}
    all_keys = {event_key(o) for o in valid}
    if queue_rows is not None:
        und = 0
        for r in queue_rows:
            at = r.get("receivedAt") if isinstance(r, dict) else None
            if not isinstance(at, str) or not re.fullmatch(r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d{1,9})?Z", at):
                continue
            if now - stamp_epoch(at[:19] + "Z") <= HOLD_SECONDS:
                continue
            k = event_key({"ce_source": r.get("ce_source"), "ce_id": r.get("ce_id"), "jti": r.get("jti")})
            if k is None or k not in all_keys:
                und += 1
        out["undecided"] = und
    if not valid:
        return out, (2 if malformed else 0)
    version = valid[-1]["rule_version"]
    cur = [o for o in valid if o["rule_version"] == version]
    out["rule_version"] = version
    out["mode"] = cur[-1]["mode"]
    first = min(stamp_epoch(o["logged_at"]) for o in cur)
    out["since"] = utc_day(first).isoformat()
    out["days_covered"] = (utc_day(now) - utc_day(first)).days
    by_id = {o["line_id"]: o for o in cur}
    superseded = {o["supersedes"] for o in cur if o["supersedes"]}
    events = {}
    for i, o in enumerate(cur):
        events.setdefault(event_key(o), []).append((i, o))

    def effective(o):
        return o["human_decision"] if o["human_decision"] is not None else o["rule_decision"]

    conf = out["confusion"]
    n_events = agree = 0
    for k, ls in events.items():
        roots = [o for _, o in ls if not o["supersedes"] or o["supersedes"] not in by_id]
        rule = next((o["rule_decision"] for o in roots if o["rule_decision"] is not None), None)
        heads = [(stamp_epoch(o["logged_at"]), i, o) for i, o in ls if o["line_id"] not in superseded]
        final = max(heads)[2] if heads else ls[-1][1]
        human = final["human_decision"]
        if human is None or rule is None:
            continue                                    # sem decisão humana (ou sem a da regra): fora do denominador
        n_events += 1
        conf[rule][human] += 1
        if rule == human:
            agree += 1
    out["events"], out["agree"] = n_events, agree
    out["agreement"] = round(agree / n_events, 4) if n_events else None
    out["kappa"] = _kappa(conf, n_events)
    w0 = now - WINDOW_7D
    dec7, rev7 = set(), 0
    for o in cur:
        t = stamp_epoch(o["logged_at"])
        if t < w0 or t > now:
            continue
        tgt = by_id.get(o["supersedes"]) if o["supersedes"] else None
        if tgt is not None:
            if o["human_decision"] is not None and effective(tgt) is not None and o["human_decision"] != effective(tgt):
                rev7 += 1
            continue                                    # linha de reversão/correção não conta como decisão
        d = o["human_decision"] if o["mode"] == "shadow" else o["rule_decision"]
        if d is not None:
            dec7.add(event_key(o))
    out["decisions_7d"], out["reversals_7d"] = len(dec7), rev7
    out["reversal_rate_7d"] = round(rev7 / len(dec7), 4) if dec7 else None
    if out["mode"] == "shadow":
        out["trigger_rule_on"] = bool(out["days_covered"] >= RULE_ON_DAYS and n_events >= RULE_ON_EVENTS
                                      and out["agreement"] is not None and out["agreement"] >= RULE_ON_AGREEMENT)
    else:
        rate = out["reversal_rate_7d"]
        out["trigger_back_to_shadow"] = bool(rate > BACK_TO_SHADOW_RATE) if rate is not None else rev7 > 0
    fired = out["trigger_rule_on"] is True or out["trigger_back_to_shadow"] is True
    return out, (2 if malformed else (1 if fired else 0))


# ─────────────────────────────── registro de rascunhos ───────────────────────────────
def draft_line(event, draft_id=None, thread=None, recipient=None, supersedes_draft=None, actor=None):
    obj = {"line_id": new_line_id(), "logged_at": utc_stamp(), "draft_id": draft_id, "thread": thread,
           "recipient": recipient, "supersedes_draft": supersedes_draft, "event": event,
           "actor": actor if actor is not None else _actor()}
    why = validate_draft(obj)
    if why:
        raise UsageError(f"linha de rascunho inválida: {why}")
    return obj


def validate_draft(o):
    if not isinstance(o, dict) or tuple(sorted(o)) != tuple(sorted(DRAFT_KEYS)):
        return "chaves diferentes das do PLAN-E"
    if not isinstance(o["line_id"], str) or not UUID_RE.fullmatch(o["line_id"]):
        return "line_id fora da forma UUID"
    if not isinstance(o["logged_at"], str) or not TS_RE.fullmatch(o["logged_at"]):
        return "logged_at fora de RFC 3339 UTC com Z"
    if o["event"] not in DRAFT_EVENTS:
        return "event fora do domínio fechado"
    for k in ("draft_id", "recipient", "supersedes_draft"):
        if o[k] is not None and (not isinstance(o[k], str) or not ID_RE.fullmatch(o[k])):
            return f"{k} fora da forma de id"
    if o["thread"] is not None and (not isinstance(o["thread"], str) or (o["thread"] and not ID_RE.fullmatch(o["thread"]))):
        return "thread fora da forma de id"
    if o["actor"] is not None and clean_str(o["actor"], 64) is None:
        return "actor não é string imprimível"
    if o["event"] in ("drafted", "sent", "discarded") and not o["draft_id"]:
        return f"{o['event']} sem draft_id"
    if o["supersedes_draft"] and (o["event"] != "drafted" or o["supersedes_draft"] == o["draft_id"]):
        return "supersedes_draft só num drafted, e nunca o próprio"
    return ""


def draft_stats(lines, now, last=AUTO_SEND_SAMPLE, since_stage_on=None):
    """→ (saída, rc, descartes a gravar). O descarte de 24 h é calculado aqui, haja ou não linha `discarded`."""
    malformed = 0
    valid = []
    for _, o in lines:
        if o is None or validate_draft(o):
            malformed += 1
        else:
            valid.append(o)
    drafted, sent_at, disc_line, superseded = {}, {}, set(), set()
    for i, o in enumerate(valid):
        ev, did = o["event"], o["draft_id"]
        if ev == "drafted" and did not in drafted:
            drafted[did] = (stamp_epoch(o["logged_at"]), i, o)
            if o["supersedes_draft"]:
                superseded.add(o["supersedes_draft"])
        elif ev == "sent":
            sent_at.setdefault(did, stamp_epoch(o["logged_at"]))
        elif ev == "discarded":
            disc_line.add(did)
    closed, to_write = [], []
    for did, (t0, i, o) in drafted.items():
        if did in superseded:
            status = "edited"
        elif did in sent_at and sent_at[did] <= t0 + DISCARD_SECONDS:
            status = "approved"
        elif did in disc_line or now > t0 + DISCARD_SECONDS:
            status = "discarded"
            if did not in disc_line:
                to_write.append(o)
        else:
            continue                                   # aberto: ainda dentro das 24 h, sem sent e sem substituto
        closed.append((t0, i, status))
    closed.sort()
    sample = [s for _, _, s in closed[-last:]] if last > 0 else []
    tail = 0
    for _, _, s in reversed(closed):
        if s != "approved":
            break
        tail += 1
    appr = sample.count("approved")
    out = {"last": last, "approved_unedited": appr, "edited": sample.count("edited"),
           "discarded": sample.count("discarded"),
           "unedited_rate": round(appr / len(sample), 4) if sample else None,
           "consecutive_unedited_tail": tail, "out_of_list_since_on": None, "kill_switch_acts_since_on": None,
           "trigger_auto_send": None, "trigger_back_to_draft": None,
           "closed": len(sample), "unregistered_sent": len([d for d in sent_at if d not in drafted]),
           "malformed": malformed}
    if last >= AUTO_SEND_SAMPLE:
        out["trigger_auto_send"] = bool(len(sample) >= AUTO_SEND_SAMPLE and (
            tail >= AUTO_SEND_SAMPLE or (out["unedited_rate"] is not None and out["unedited_rate"] >= AUTO_SEND_RATE)))
    if since_stage_on is not None:
        t_on = calendar.timegm(time.strptime(since_stage_on, "%Y-%m-%d"))
        acts = [o for o in valid if stamp_epoch(o["logged_at"]) >= t_on]
        oob = sum(1 for o in acts if o["event"] in ("blocked_out_of_list", "sent_out_of_list"))
        ks = [o for o in acts if o["event"] in ("kill_switch_on", "kill_switch_off")]
        out["out_of_list_since_on"] = oob
        out["kill_switch_acts_since_on"] = len(ks)
        out["trigger_back_to_draft"] = bool(oob > 0 or any(o["event"] == "kill_switch_on" for o in ks))
    fired = out["trigger_auto_send"] is True or out["trigger_back_to_draft"] is True
    return out, (2 if malformed else (1 if fired else 0)), to_write


# ─────────────────────────────── CLI ───────────────────────────────
def _opts(argv, spec):
    """spec: {flag: tem_valor}. → dict. Flag fora do spec = UsageError."""
    got, i = {}, 0
    while i < len(argv):
        a = argv[i]
        if a not in spec:
            raise UsageError(f"opção não aceita: {a}")
        if spec[a]:
            if i + 1 >= len(argv):
                raise UsageError(f"{a} exige valor")
            got[a] = argv[i + 1]
            i += 2
        else:
            got[a] = True
            i += 1
    return got


def _now(o):
    v = o.get("--now")
    if v is None:
        return int(time.time())
    if not re.fullmatch(r"\d{1,12}", v):
        raise UsageError("--now exige epoch inteiro")
    return int(v)


def _nullable(v):
    return None if v in (None, "") else v


def _say_stats(kind, out, rc):
    print(f"[a2a-metrics] {kind}: " + " · ".join(f"{k}={json.dumps(v, ensure_ascii=False)}" for k, v in out.items()))
    print({0: "[a2a-metrics] mediu: nenhum gatilho disparou",
           1: "[a2a-metrics] mediu: GATILHO disparou (leve à mesa do maestro)",
           2: "[a2a-metrics] NÃO PÔDE MEDIR por inteiro (linha malformada): nada aqui é verde"}[rc])


def main(argv):
    if not argv or argv[0] in ("-h", "--help"):
        print(open(__file__, encoding="utf-8").read().split("# ====", 2)[1].split("\n", 1)[1].rsplit("\n#", 1)[0])
        return 0 if argv else 3
    cmd, rest = argv[0], argv[1:]
    if cmd == "ce":
        o = _opts(rest, {"--body-file": True})
        if "--body-file" not in o:
            raise UsageError("ce exige --body-file")
        try:
            raw = open(o["--body-file"], "rb").read()
        except OSError as e:
            raise MeasureError(f"corpo ilegível: {e.strerror}")
        print(json.dumps(parse_cloudevent(raw), ensure_ascii=False))
        return 0
    if cmd == "shadow-append":
        o = _opts(rest, {"--log": True, "--receiver": True, "--check": False, "--mode": True, "--rule-decision": True,
                         "--human-decision": True, "--reason": True, "--jti": True, "--task-id": True,
                         "--ce-source": True, "--ce-id": True, "--ce-time": True, "--supersedes": True})
        log = o.get("--log") or default_shadow_log(o.get("--receiver", ""))
        if o.get("--check"):
            check_log(log)
            print(f"ok: {log}")
            return 0
        line = shadow_line(o.get("--mode", "shadow"), _nullable(o.get("--rule-decision")),
                           _nullable(o.get("--human-decision")), ce_source=_nullable(o.get("--ce-source")),
                           ce_id=_nullable(o.get("--ce-id")), ce_time=_nullable(o.get("--ce-time")),
                           jti=_nullable(o.get("--jti")), task_id=_nullable(o.get("--task-id")),
                           reason=_nullable(o.get("--reason")), supersedes=_nullable(o.get("--supersedes")))
        append_line(log, line)
        print(f"ok: {log} line_id={line['line_id']}")
        return 0
    if cmd == "shadow-stats":
        o = _opts(rest, {"--log": True, "--receiver": True, "--queue-jsonl": True, "--now": True, "--json": False})
        log = o.get("--log") or default_shadow_log(o.get("--receiver", ""))
        rows = None
        if "--queue-jsonl" in o:
            try:
                rows = [json.loads(x) for x in open(o["--queue-jsonl"], encoding="utf-8") if x.strip()]
            except (OSError, ValueError) as e:
                raise MeasureError(f"--queue-jsonl ilegível: {e}")
        out, rc = shadow_stats(read_log(log), _now(o), rows)
        if o.get("--json"):
            print(json.dumps(out, ensure_ascii=False))
        else:
            _say_stats("sombra do aceite", out, rc)
            if out["undecided"] is None:
                print("[a2a-metrics] undecided NÃO medido: passe --queue-jsonl (a saída de ops/a2a-queue-live.sh list --json)")
        return rc
    if cmd == "draft-append":
        o = _opts(rest, {"--log": True, "--check": False, "--event": True, "--draft-id": True, "--thread": True,
                         "--recipient": True, "--supersedes-draft": True})
        log = o.get("--log") or default_draft_log()
        if o.get("--check"):
            check_log(log)
            print(f"ok: {log}")
            return 0
        line = draft_line(o.get("--event", ""), _nullable(o.get("--draft-id")), o.get("--thread"),
                          _nullable(o.get("--recipient")), _nullable(o.get("--supersedes-draft")))
        append_line(log, line)
        print(f"ok: {log} line_id={line['line_id']}")
        return 0
    if cmd == "draft-stats":
        o = _opts(rest, {"--log": True, "--last": True, "--since-stage-on": True, "--now": True, "--no-write": False,
                         "--json": False})
        log = o.get("--log") or default_draft_log()
        last = o.get("--last", str(AUTO_SEND_SAMPLE))
        if not re.fullmatch(r"[1-9]\d{0,5}", last):
            raise UsageError("--last exige inteiro positivo")
        since = o.get("--since-stage-on")
        if since is not None and not DAY_RE.fullmatch(since):
            raise UsageError("--since-stage-on exige AAAA-MM-DD (dia UTC)")
        out, rc, to_write = draft_stats(read_log(log), _now(o), int(last), since)
        if to_write and not o.get("--no-write"):
            # o descarte vira linha (nenhuma peça grava descarte; PLAN-E §3); a contagem acima já o incluiu. Log que
            # recusa a escrita (permissão, dono, árvore git) é log em que não se confia: a saída sai, e o rc é 2
            try:
                for d in to_write:
                    append_line(log, draft_line("discarded", d["draft_id"], d["thread"], d["recipient"], None,
                                                actor="a2a-draft-stats"))
            except MeasureError as e:
                print(f"[a2a-metrics] ERRO: a linha discarded não foi gravada: {e}", file=sys.stderr)
                rc = 2
        if o.get("--json"):
            print(json.dumps(out, ensure_ascii=False))
        else:
            _say_stats("rascunhos do aviso", out, rc)
        return rc
    raise UsageError(f"subcomando desconhecido: {cmd} (ce | shadow-append | shadow-stats | draft-append | draft-stats)")


if __name__ == "__main__":
    try:
        sys.exit(main(sys.argv[1:]))
    except UsageError as e:
        print(f"[a2a-metrics] uso: {e}", file=sys.stderr)
        sys.exit(3)
    except MeasureError as e:
        print(f"[a2a-metrics] ERRO: {e}", file=sys.stderr)
        sys.exit(2)
