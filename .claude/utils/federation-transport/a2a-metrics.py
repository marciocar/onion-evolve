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
#                  --mode shadow|auto é OBRIGATÓRIO (o modo em vigor; cada gatilho conta só as linhas do seu modo).
#                  days_covered = DIAS COMPLETOS APÓS O 1º: períodos inteiros de 24 h desde a 1ª linha da regra
#                  vigente, floor((agora - 1ª)/86400). Lacuna registrada (shadow-gap.log) na janela = rc 2; log vazio
#                  = no_data e rc 2; gatilho sem produtor no core (a reversão) sai null com not_instrumented e rc 2.
#                  No modo shadow a janela RECOMEÇA na última passagem de auto para shadow; modo pedido sem linhas
#                  = no_data e rc 2; linha com logged_at no futuro conta em future_logged_at (não é evento; rc 2).
#                  Lacuna tem gap_id e se fecha com shadow-append --resolves-gap <gap_id> (fechada não dá rc 2)
#   draft-append   uma linha do registro de rascunhos (nasce no a2a-rt-mcp.py e no a2a-rt-send.sh)
#   draft-stats    os rascunhos aprovados sem edição e os atos que mandam voltar (o "a2a-draft-stats" do PLAN-E)
#                  Sem lista fechada, chave de corte e teto de taxa no core, trigger_auto_send sai null
#                  (preconditions_missing); o critério do PLAN-D sai em auto_send_criterion_met. Com --since-stage-on,
#                  trigger_back_to_draft sai null com not_instrumented (nenhuma peça grava lista/chave ainda) e rc 2.
#                  `sent` sem o `drafted` dele, ou lacuna em draft-gap.log na janela da amostra = rc 2.
#                  Por tipo de linha: `drafted` que falha vira lacuna (o rascunho nasce); `sent` é estrito ANTES do
#                  envio (o a2a-rt-send.sh pré-checa e recusa) e vira lacuna se falhar DEPOIS (envio com rc 5); os
#                  atos de bloqueio e de chave de corte são estritos (draft-append sem --gap-on-fail)
#
# LACUNA (julgamento da curadoria, ponto f): a linha de sombra que não se grava NÃO barra o aceite nem o archive. O
# shadow-append grava então um marcador em shadow-gap.log (data, ponto, jti, taskId; as mesmas regras de 0600 fora
# do git) e sai 4; o shadow-stats sai 2 em toda janela que contém lacuna. Se nem o marcador se grava, sai 2.
# Um arquivo só, e não três comandos, porque o escritor (line_id, 0600, fora de árvore git, trava) e o parse do
# CloudEvent são os mesmos para todos: três cópias divergiriam.
#
# REGRAS COMUNS (PLAN-E §0): JSON Lines (UTF-8, uma linha por valor, '\n'); hora RFC 3339 sempre em UTC com Z; o
# "dia" é a data UTC; cada linha tem line_id (UUID v4) e a correção é uma linha NOVA com `supersedes`; nunca se
# reescreve uma linha. O corpo do sinal NUNCA vai ao log: só ids, hashes e decisões. O arquivo nasce 0600 num
# diretório 0700, fora do repo em uso (o toplevel do core ou do adotante que roda), e o escritor recusa symlink,
# arquivo de outro dono e arquivo legível por grupo/outros. A guarda de lugar é só o REPO EM USO (core ou adotante):
# RISCO RESIDUAL declarado — HOME versionado por dotfiles (~/.git) pode levar o log a um commit pessoal; a guarda só
# impede que o log fique dentro do repo em uso.
#
# EXIT dos contadores (PLAN-E §0): 0 mediu e nenhum gatilho disparou · 1 mediu e algum gatilho disparou ·
#   2 não pôde medir (arquivo ausente ou ilegível, linha malformada) · 3 uso inválido.
# EXIT dos escritores: 0 linha gravada (ou --check ok) · 2 não gravou (nem a lacuna) · 3 uso inválido ·
#   4 (só shadow-append) a linha falhou e a LACUNA foi registrada em shadow-gap.log.
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
               "rule_version", "rule_decision", "human_decision", "reason", "human_actor", "supersedes", "ids_verified", "from")
DRAFT_KEYS = ("line_id", "logged_at", "draft_id", "thread", "recipient", "supersedes_draft", "event", "actor")
# critérios do PLAN-D, sem mudar (PLAN-E §2 e §3)
RULE_ON_DAYS, RULE_ON_EVENTS, RULE_ON_AGREEMENT = 14, 50, 0.95
BACK_TO_SHADOW_RATE = 0.15
HOLD_SECONDS = 3 * 86400            # escolha da curadoria: registro na fila há mais de 3 dias sem decisão = undecided
WINDOW_7D = 7 * 86400
AUTO_SEND_SAMPLE, AUTO_SEND_RATE = 30, 0.90
DISCARD_SECONDS = 24 * 3600         # escolha da curadoria: rascunho sem sent e sem substituto em 24 h = descartado
# a regra v1 do aceite é a LINHA DE BASE declarada: aceita todo registro verificado. Não há regra de verdade ainda;
# uma regra nova troca o rule_id ou a versão, e a contagem recomeça (PLAN-E §2). Julgamento da curadoria (2026-11-03,
# ponto d): a linha de base NUNCA liga a regra automática: com ela, trigger_rule_on sai false com o motivo
RULE_ID, RULE_VERSION = "baseline-accept-all", "1"
BASELINE_RULE_IDS = ("baseline-accept-all",)
# julgamento da curadoria (ponto e): o envio automático exige lista fechada, chave de corte e teto de taxa NO CORE.
# Enquanto faltarem, trigger_auto_send sai null (nunca true). Quem construir uma das três a tira daqui
AUTO_SEND_PRECONDITIONS_MISSING = ("closed_list", "kill_switch", "rate_cap")
# cura A2 da revisão: gatilho cujo fato NENHUMA peça do core produz sai null, com not_instrumented, e rc 2 quando pedido.
# Quem construir o produtor tira o fato daqui (e o caso da bancada que o afirma passa a valer)
SHADOW_NOT_INSTRUMENTED = ("reversal",)              # a linha humana com supersedes que contraria a regra (modo auto)
DRAFT_NOT_INSTRUMENTED = ("blocked_out_of_list", "sent_out_of_list", "kill_switch_on", "kill_switch_off")

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


def default_gap_log():
    x = os.environ.get("A2A_SHADOW_GAP_LOG", "")
    return x if x else os.path.join(state_home(), "onion", "a2a-metrics", "shadow-gap.log")


def read_gaps(path):
    """→ epochs das lacunas ABERTAS (None = linha ilegível: lacuna de hora desconhecida). Arquivo ausente = nenhuma.

    N6: a lacuna tem gap_id; quando o operador regrava a decisão que faltou (shadow-append --resolves-gap <gap_id>),
    uma linha {"resolves": <gap_id>, "resolved_by": <line_id>} a fecha, e lacuna fechada não dá rc 2."""
    if not os.path.lexists(path):
        return []
    rows = [o for _, o in read_log(path)]
    closed = {o.get("resolves") for o in rows if isinstance(o, dict) and isinstance(o.get("resolved_by"), str)
              and UUID_RE.fullmatch(o["resolved_by"]) and isinstance(o.get("resolves"), str)}
    out = []
    for o in rows:
        if isinstance(o, dict) and "resolves" in o:
            continue                                    # a linha de resolução não é lacuna
        if isinstance(o, dict) and o.get("gap_id") in closed:
            continue
        t = o.get("logged_at") if isinstance(o, dict) else None
        out.append(stamp_epoch(t) if isinstance(t, str) and TS_RE.fullmatch(t) else None)
    return out


def default_draft_log():
    st = os.environ.get("A2A_RT_STATE") or os.path.join(os.path.expanduser("~"), ".local", "state", "onion", "a2a-rt")
    return os.path.join(st, "drafts.jsonl")


def default_draft_gap_log(draft_log):
    """O marcador de lacuna do registro de rascunhos: draft-gap.log ao lado do registro (mesmas regras de escrita)."""
    return os.path.join(os.path.dirname(os.path.abspath(draft_log)), "draft-gap.log")


def append_draft_with_gap(log, line, gap_log=None):
    """Grava a linha; se falhar, grava a LACUNA (draft-gap.log) e devolve a mensagem dela. Sem nem a lacuna, levanta.

    Julgamento da curadoria (2026-11-03, ponto 3): `drafted` nasce mesmo com a linha falhando (lacuna); `sent` que
    falha DEPOIS do envio também vira lacuna (e o envio sai com rc != 0). Os atos de bloqueio e de chave de corte são
    estritos: quem os grava não usa esta função."""
    try:
        append_line(log, line)
        return ""
    except MeasureError as e:
        gap = gap_log or default_draft_gap_log(log)
        append_line(gap, {"logged_at": utc_stamp(), "event": line["event"], "draft_id": line["draft_id"],
                          "why": str(e)[:300]})
        return f"LACUNA: a linha {line['event']} de {line['draft_id']} NÃO foi gravada ({e}); marcador em {gap}"


def _repo_in_use():
    """O toplevel do repo EM USO (o core ou o adotante): A2A_METRICS_REPO_ROOT, que o aceite e o wrapper passam, ou o
    repo que contém este arquivo. Só ele é proibido ao log (cura B5 da revisão da curadoria)."""
    r = os.environ.get("A2A_METRICS_REPO_ROOT", "")
    if r:
        return os.path.realpath(r)
    p = os.path.dirname(os.path.realpath(__file__))
    while True:
        if os.path.lexists(os.path.join(p, ".git")):
            return p
        up = os.path.dirname(p)
        if up == p:
            return ""
        p = up


def _inside_repo_in_use(directory):
    """→ o repo em uso, se `directory` (ou o ancestral existente mais próximo, antes de criar nada) mora dentro dele.

    RISCO RESIDUAL DECLARADO: um HOME versionado por dotfiles (~/.git) não é barrado; nele o log pode acabar num
    commit pessoal. A guarda só impede que o log fique dentro do repo em uso."""
    root = _repo_in_use()
    if not root:
        return ""
    p = os.path.abspath(directory)
    while not os.path.exists(p) and os.path.dirname(p) != p:
        p = os.path.dirname(p)
    p = os.path.realpath(p)
    return root if p == root or p.startswith(root + os.sep) else ""


def _open_log_for_append(path):
    """Abre o log para acréscimo com as regras do §0. Levanta MeasureError com o motivo; devolve o fd."""
    path = os.path.abspath(path)
    d = os.path.dirname(path)
    g = _inside_repo_in_use(d)                     # ANTES de criar diretório: nada nasce dentro do repo em uso
    if g:
        raise MeasureError(f"o log {path} cairia dentro do repo em uso {g}: o log mora fora dele")
    if not os.path.isdir(d):
        try:
            os.makedirs(d, mode=0o700, exist_ok=True)
        except OSError as e:
            raise MeasureError(f"não criei o diretório do log {d}: {e.strerror}")
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
                task_id=None, reason=None, supersedes=None, rule_id=RULE_ID, rule_version=RULE_VERSION, actor=None,
                ids_verified=True, from_=None):
    obj = {"line_id": new_line_id(), "logged_at": utc_stamp(), "mode": mode, "ce_source": ce_source, "ce_id": ce_id,
           "ce_time": ce_time, "jti": jti, "taskId": task_id, "rule_id": rule_id, "rule_version": rule_version,
           "rule_decision": rule_decision, "human_decision": human_decision, "reason": reason,
           "human_actor": actor if actor is not None else (_actor() if human_decision is not None else None),
           "supersedes": supersedes, "ids_verified": ids_verified, "from": from_}
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
    if not isinstance(o["ids_verified"], bool):
        return "ids_verified não é booleano"
    if o["from"] is not None and (not isinstance(o["from"], str) or not ID_RE.fullmatch(o["from"])):
        return "from fora da forma de id"
    if not event_key(o):
        return "sem chave de evento (ce_source + ce_id, ou jti; com ids_verified false, o taskId)"
    return ""


def event_key(o):
    """Evento = par ce_source + ce_id (CloudEvents: source + id é único), ou o jti quando o corpo não tem CloudEvent.

    Linha com ids_verified false (a recusa do archive: o registro nunca passou pela reverificação) deduplica pelo
    taskId que o bridge gerou, NUNCA pelos ce_* ou pelo jti, que quem escreve na fila escolhe (curadoria, ponto c).
    """
    if o.get("ids_verified") is False:
        return ("task", o["taskId"]) if o.get("taskId") else None
    if o.get("ce_source") and o.get("ce_id"):
        # escopada pelo REMETENTE (o from assinado): um membro que reusa o source + id de outro não funde as cadeias
        return ("ce", o.get("from"), o["ce_source"], o["ce_id"])
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


def _received_epoch(at):
    """receivedAt em RFC 3339 (Z ou offset) → epoch; ausente ou ilegível → None (cura B2: não some do undecided)."""
    if not isinstance(at, str) or not RFC3339_RE.fullmatch(at):
        return None
    try:
        x = re.sub(r"(\.\d{6})\d+", r"\1", at).replace("Z", "+00:00")
        return int(dt.datetime.fromisoformat(x).timestamp())
    except ValueError:
        return None


def shadow_stats(lines, now, mode, queue_rows=None, gaps=()):
    """→ (saída, rc). `lines` = read_log(); `mode` = o modo em vigor (shadow|auto), dado por quem pergunta e NUNCA
    tirado da última linha (cura A1); `queue_rows` = linhas do `ops/a2a-queue-live.sh list --json` (ou None);
    `gaps` = read_gaps() (lacuna na janela = rc 2: a medida tem buraco)."""
    malformed = future = ahead = 0
    valid = []
    for _, o in lines:
        if o is None or validate_shadow(o):
            malformed += 1
        elif stamp_epoch(o["logged_at"]) > now:
            future += 1                                # N7: linha do futuro (relógio torto) não é evento
            ahead = max(ahead, stamp_epoch(o["logged_at"]) - now)
        else:
            valid.append(o)
    out = {"rule_id": None, "rule_version": None, "since": None, "days_covered": 0, "events": 0, "undecided": None,
           "agree": 0, "agreement": None, "mode": mode, "decisions_7d": 0, "reversals_7d": 0,
           "reversal_rate_7d": None, "malformed": malformed, "trigger_rule_on": None, "trigger_back_to_shadow": None,
           "confusion": {r: {h: 0 for h in DECISIONS} for r in DECISIONS}, "kappa": None,
           "rule_on_criterion_met": None, "trigger_rule_on_reason": None, "back_to_shadow_criterion_met": None,
           "not_instrumented": None, "holds": 0, "no_data": False, "gaps_in_window": 0, "future_logged_at": future,
           "future_max_ahead_s": ahead if future else None}
    cur = []
    if valid:
        version, rule_id = valid[-1]["rule_version"], valid[-1]["rule_id"]
        cur = [o for o in valid if o["rule_version"] == version and o["rule_id"] == rule_id]
        out["rule_version"], out["rule_id"] = version, rule_id
    # B2: só casa decisão da MESMA regra vigente; o taskId (do bridge) casa também
    cur_keys = {event_key(o) for o in cur} | {("task", o["taskId"]) for o in cur if o.get("taskId")}
    if queue_rows is not None:
        und = 0
        for r in queue_rows:
            if not isinstance(r, dict):
                und += 1
                continue
            t = _received_epoch(r.get("receivedAt"))
            if t is not None and now - t <= HOLD_SECONDS:
                continue                               # ainda dentro dos 3 dias: não é hold
            k = event_key({"from": r.get("from"), "ce_source": r.get("ce_source"), "ce_id": r.get("ce_id"),
                           "jti": r.get("jti")})
            if (k is None or k not in cur_keys) and ("task", r.get("taskId")) not in cur_keys:
                und += 1                               # sem receivedAt legível também conta: ausência não é "recente"
        out["undecided"] = und
    scur = [o for o in cur if o["mode"] == mode]          # A1: cada gatilho sobre as linhas do SEU modo
    if mode == "shadow":
        autos = [stamp_epoch(o["logged_at"]) for o in cur if o["mode"] == "auto"]
        if autos:
            # N1 (julgamento da dona): voltar à sombra é a regra ter errado; a janela RECOMEÇA na última passagem de
            # auto para shadow, e a concordância antiga não religa a regra
            scur = [o for o in scur if stamp_epoch(o["logged_at"]) > max(autos)]
    if not scur:
        # log vazio, só malformadas, ou nenhuma linha do modo pedido: SEM DADO, nunca contagem zero (A2, N4)
        out["no_data"] = True
        out["gaps_in_window"] = len(gaps)
        return out, 2
    first = min(stamp_epoch(o["logged_at"]) for o in scur)
    out["since"] = utc_day(first).isoformat()
    # M1: DIAS COMPLETOS APÓS O 1º = períodos inteiros de 24 h desde a 1ª linha (23:59 → 00:01 de 14 dias depois = 13)
    out["days_covered"] = max(0, (now - first) // 86400)
    by_id = {o["line_id"]: o for o in scur}
    superseded = {o["supersedes"] for o in scur if o["supersedes"]}
    events = {}
    for i, o in enumerate(scur):
        events.setdefault(event_key(o), []).append((i, o))

    def effective(o):
        return o["human_decision"] if o["human_decision"] is not None else o["rule_decision"]

    conf = out["confusion"]
    n_events = agree = holds = 0
    for k, ls in events.items():
        roots = [o for _, o in ls if not o["supersedes"] or o["supersedes"] not in by_id]
        rule = next((o["rule_decision"] for o in roots if o["rule_decision"] is not None), None)
        heads = [(stamp_epoch(o["logged_at"]), i, o) for i, o in ls if o["line_id"] not in superseded]
        final = max(heads)[2] if heads else ls[-1][1]       # a decisão humana FINAL da cadeia de supersedes
        human = final["human_decision"]
        if human is None or rule is None:
            continue                                    # sem decisão humana (ou sem a da regra): fora do denominador
        conf[rule][human] += 1
        if "hold" in (rule, human):
            holds += 1                                  # B2: hold não é discordância; fica fora do denominador
            continue
        n_events += 1
        if rule == human:
            agree += 1
    out["events"], out["agree"], out["holds"] = n_events, agree, holds
    out["agreement"] = round(agree / n_events, 4) if n_events else None
    out["kappa"] = _kappa(conf, n_events + holds)
    w0 = now - WINDOW_7D
    dec7, rev7 = set(), 0
    for o in scur:
        t = stamp_epoch(o["logged_at"])
        if t < w0 or t > now:
            continue
        tgt = by_id.get(o["supersedes"]) if o["supersedes"] else None
        if tgt is not None and event_key(tgt) == event_key(o):   # B3: reversão só no MESMO evento
            if o["human_decision"] is not None and effective(tgt) is not None and o["human_decision"] != effective(tgt):
                rev7 += 1
            continue                                    # linha de reversão/correção não conta como decisão
        d = o["human_decision"] if mode == "shadow" else o["rule_decision"]
        if d is not None:
            dec7.add(event_key(o))
    out["decisions_7d"], out["reversals_7d"] = len(dec7), rev7
    out["reversal_rate_7d"] = round(rev7 / len(dec7), 4) if dec7 else None
    not_instr = False
    if mode == "shadow":
        met = bool(out["days_covered"] >= RULE_ON_DAYS and n_events >= RULE_ON_EVENTS
                   and out["agreement"] is not None and out["agreement"] >= RULE_ON_AGREEMENT)
        out["rule_on_criterion_met"] = met
        if out["rule_id"] in BASELINE_RULE_IDS:
            out["trigger_rule_on"] = False
            out["trigger_rule_on_reason"] = (f"a regra {out['rule_id']} é a linha de base (aceita tudo): ela nunca liga "
                                             "a regra automática, por maior que seja a concordância")
        else:
            out["trigger_rule_on"] = met
    else:
        rate = out["reversal_rate_7d"]
        out["back_to_shadow_criterion_met"] = bool(rate > BACK_TO_SHADOW_RATE) if rate is not None else rev7 > 0
        # A2: nenhuma peça do core grava a reversão humana (a linha com supersedes): gatilho sem produtor sai null
        if SHADOW_NOT_INSTRUMENTED:
            out["not_instrumented"] = list(SHADOW_NOT_INSTRUMENTED)
            not_instr = True
        else:
            out["trigger_back_to_shadow"] = out["back_to_shadow_criterion_met"]
    # a janela é a da regra vigente (desde a 1ª linha dela) e a dos 7 dias; lacuna de hora ilegível cai em todas
    w_start = min(first, w0)
    out["gaps_in_window"] = sum(1 for g in gaps if g is None or w_start <= g <= now)
    fired = out["trigger_rule_on"] is True or out["trigger_back_to_shadow"] is True
    return out, (2 if malformed or future or out["gaps_in_window"] or not_instr else (1 if fired else 0))


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


def draft_stats(lines, now, last=AUTO_SEND_SAMPLE, since_stage_on=None, gaps=()):
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
    # a janela da amostra começa no rascunho mais antigo dela; sem amostra, toda lacuna está na janela
    w_start = closed[-last:][0][0] if (last > 0 and closed) else None
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
    out["preconditions_missing"] = list(AUTO_SEND_PRECONDITIONS_MISSING)
    out["auto_send_criterion_met"] = None
    if last >= AUTO_SEND_SAMPLE:
        out["auto_send_criterion_met"] = bool(len(sample) >= AUTO_SEND_SAMPLE and (
            tail >= AUTO_SEND_SAMPLE or (out["unedited_rate"] is not None and out["unedited_rate"] >= AUTO_SEND_RATE)))
        # sem as três salvaguardas no core o envio automático não liga, por melhor que seja a amostra
        out["trigger_auto_send"] = None if out["preconditions_missing"] else out["auto_send_criterion_met"]
    out["back_to_draft_criterion_met"] = None
    out["not_instrumented"] = None
    out["no_data"] = not valid                          # log vazio é SEM DADO, nunca amostra zero (cura A2)
    not_instr = False
    if since_stage_on is not None:
        t_on = calendar.timegm(time.strptime(since_stage_on, "%Y-%m-%d"))
        acts = [o for o in valid if stamp_epoch(o["logged_at"]) >= t_on]
        oob = sum(1 for o in acts if o["event"] in ("blocked_out_of_list", "sent_out_of_list"))
        ks = [o for o in acts if o["event"] in ("kill_switch_on", "kill_switch_off")]
        out["out_of_list_since_on"] = oob
        out["kill_switch_acts_since_on"] = len(ks)
        out["back_to_draft_criterion_met"] = bool(oob > 0 or any(o["event"] == "kill_switch_on" for o in ks))
        # nenhuma peça do core grava esses atos ainda: o gatilho pedido sai null, e a medida não é verde (rc 2)
        if DRAFT_NOT_INSTRUMENTED:
            out["not_instrumented"] = list(DRAFT_NOT_INSTRUMENTED)
            not_instr = True
        else:
            out["trigger_back_to_draft"] = out["back_to_draft_criterion_met"]
    # ponto 3 da curadoria: `sent` sem o `drafted` dele é LACUNA (nunca aprovado sem edição), e o marcador de lacuna
    # (draft-gap.log) na janela também: a medida não é verde (rc 2)
    out["gaps_in_window"] = sum(1 for g in gaps if g is None or w_start is None or w_start <= g <= now)
    gap = out["unregistered_sent"] > 0 or out["gaps_in_window"] > 0
    fired = out["trigger_auto_send"] is True or out["trigger_back_to_draft"] is True
    return out, (2 if malformed or not_instr or out["no_data"] or gap else (1 if fired else 0)), to_write


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


def _valid_day(v):
    if not isinstance(v, str) or not DAY_RE.fullmatch(v):
        return False
    try:
        dt.date.fromisoformat(v)
        return True
    except ValueError:
        return False


def _nullable(v):
    return None if v in (None, "") else v


def _say_stats(kind, out, rc):
    print(f"[a2a-metrics] {kind}: " + " · ".join(f"{k}={json.dumps(v, ensure_ascii=False)}" for k, v in out.items()))
    print({0: "[a2a-metrics] mediu: nenhum gatilho disparou",
           1: "[a2a-metrics] mediu: GATILHO disparou (leve à mesa do maestro)",
           2: "[a2a-metrics] NÃO PÔDE MEDIR por inteiro (linha malformada ou lacuna na janela): nada aqui é verde"}[rc])


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
                         "--ce-source": True, "--ce-id": True, "--ce-time": True, "--supersedes": True,
                         "--ids-unverified": False, "--point": True, "--gap-log": True, "--if-absent": False,
                         "--resolves-gap": True, "--from": True})
        log = o.get("--log") or default_shadow_log(o.get("--receiver", ""))
        if o.get("--check"):
            check_log(log)
            print(f"ok: {log}")
            return 0
        gap_log = o.get("--gap-log") or default_gap_log()
        if o.get("--resolves-gap") and not UUID_RE.fullmatch(o["--resolves-gap"]):
            raise UsageError("--resolves-gap exige o gap_id (UUID) da lacuna")

        def _gap(why, jti, task):
            gap = {"logged_at": utc_stamp(), "gap_id": new_line_id(), "point": o.get("--point", "accept"),
                   "jti": jti, "taskId": task, "why": str(why)[:300]}
            print(f"[a2a-metrics] LACUNA: a linha de sombra NÃO foi gravada ({why})", file=sys.stderr)
            try:
                append_line(gap_log, gap)
            except MeasureError as e2:
                raise MeasureError(f"nem a linha de sombra nem o marcador de lacuna foram gravados: {e2}")
            print(f"[a2a-metrics] LACUNA registrada em {gap_log} (gap_id {gap['gap_id']}): o shadow-stats sai rc 2 "
                  "em toda janela que a contém, até a decisão ser regravada com --resolves-gap", file=sys.stderr)
            return 4
        try:
            # N5: a linha se valida DENTRO do try: linha inválida (sem chave de evento, valor fora da forma) também
            # vira lacuna, nunca um rc 3 sem marcador
            line = shadow_line(o.get("--mode", "shadow"), _nullable(o.get("--rule-decision")),
                               _nullable(o.get("--human-decision")), ce_source=_nullable(o.get("--ce-source")),
                               ce_id=_nullable(o.get("--ce-id")), ce_time=_nullable(o.get("--ce-time")),
                               jti=_nullable(o.get("--jti")), task_id=_nullable(o.get("--task-id")),
                               reason=_nullable(o.get("--reason")), supersedes=_nullable(o.get("--supersedes")),
                               ids_verified=not o.get("--ids-unverified"), from_=_nullable(o.get("--from")))
        except UsageError as e:
            return _gap(e, clean_str(o.get("--jti")), clean_str(o.get("--task-id")))
        if o.get("--if-absent") and os.path.lexists(log):
            # cura B1: o "já aceito" grava a linha só se ela faltar (mesmo evento, mesma decisão, mesma regra)
            try:
                have = any(isinstance(x, dict) and not validate_shadow(x) and event_key(x) == event_key(line)
                           and x["human_decision"] == line["human_decision"] and x["rule_id"] == line["rule_id"]
                           and x["rule_version"] == line["rule_version"] for _, x in read_log(log))
            except MeasureError:
                have = False                            # ilegível: tenta gravar (e a falha vira lacuna)
            if have:
                print(f"ok: {log} (a linha deste evento já existe)")
                return 0
        try:
            append_line(log, line)
        except MeasureError as e:
            return _gap(e, line["jti"], line["taskId"])
        if o.get("--resolves-gap"):
            append_line(gap_log, {"logged_at": utc_stamp(), "resolves": o["--resolves-gap"],
                                  "resolved_by": line["line_id"]})
        print(f"ok: {log} line_id={line['line_id']}")
        return 0
    if cmd == "shadow-stats":
        o = _opts(rest, {"--log": True, "--receiver": True, "--queue-jsonl": True, "--now": True, "--json": False,
                         "--gap-log": True, "--mode": True})
        if o.get("--mode") not in MODES:
            raise UsageError("shadow-stats exige --mode shadow|auto (o modo em vigor; nunca o da última linha)")
        log = o.get("--log") or default_shadow_log(o.get("--receiver", ""))
        rows = None
        if "--queue-jsonl" in o:
            try:
                rows = [json.loads(x) for x in open(o["--queue-jsonl"], encoding="utf-8") if x.strip()]
            except (OSError, ValueError) as e:
                raise MeasureError(f"--queue-jsonl ilegível: {e}")
        out, rc = shadow_stats(read_log(log), _now(o), o["--mode"], rows,
                               read_gaps(o.get("--gap-log") or default_gap_log()))
        if o.get("--json"):
            print(json.dumps(out, ensure_ascii=False))
        else:
            _say_stats("sombra do aceite", out, rc)
            if out["undecided"] is None:
                print("[a2a-metrics] undecided NÃO medido: passe --queue-jsonl (a saída de ops/a2a-queue-live.sh list --json)")
        return rc
    if cmd == "draft-append":
        o = _opts(rest, {"--log": True, "--check": False, "--event": True, "--draft-id": True, "--thread": True,
                         "--recipient": True, "--supersedes-draft": True, "--gap-on-fail": False, "--gap-log": True})
        log = o.get("--log") or default_draft_log()
        if o.get("--check"):
            check_log(log)
            print(f"ok: {log}")
            return 0
        line = draft_line(o.get("--event", ""), _nullable(o.get("--draft-id")), o.get("--thread"),
                          _nullable(o.get("--recipient")), _nullable(o.get("--supersedes-draft")))
        if o.get("--gap-on-fail"):
            if line["event"] not in ("drafted", "sent"):
                raise UsageError("--gap-on-fail só vale para drafted e sent: os atos de bloqueio e de chave são estritos")
            msg = append_draft_with_gap(log, line, o.get("--gap-log"))
            if msg:
                print(f"[a2a-metrics] {msg}", file=sys.stderr)
                return 4
        else:
            append_line(log, line)
        print(f"ok: {log} line_id={line['line_id']}")
        return 0
    if cmd == "draft-stats":
        o = _opts(rest, {"--log": True, "--last": True, "--since-stage-on": True, "--now": True, "--no-write": False,
                         "--json": False, "--gap-log": True})
        log = o.get("--log") or default_draft_log()
        last = o.get("--last", str(AUTO_SEND_SAMPLE))
        if not re.fullmatch(r"[1-9]\d{0,5}", last):
            raise UsageError("--last exige inteiro positivo")
        since = o.get("--since-stage-on")
        if since is not None and not _valid_day(since):
            raise UsageError("--since-stage-on exige AAAA-MM-DD, um dia UTC que exista")
        out, rc, to_write = draft_stats(read_log(log), _now(o), int(last), since,
                                        read_gaps(o.get("--gap-log") or default_draft_gap_log(log)))
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
    except Exception as e:                              # M2: exceção inesperada é "não pude medir", nunca rc 1
        print(f"[a2a-metrics] ERRO inesperado ({type(e).__name__}: {e}): não pude medir", file=sys.stderr)
        sys.exit(2)
