#!/usr/bin/env python3
"""O relatório do ritmo (a opção B do perfil de ritual, decidida pelo maestro em 2026-11-17): por dono, o ritual
atrasado, o nunca executado, o só por evento e o que tem falha aberta. Fora do veredito, como o relatório de
vencimento (--due): o contrato v4.25 segue julgando o x_ritual só pela forma.

Duas fontes. O grafo, sempre: o verified_at do ritual (a última execução que passou, com precisão de dia) e os nós
evidence com TRACES_TO para ele (a execução promovida, com x_outcome e x_event.time). E, opcional, o registro de
execuções do executor: CloudEvents 1.0 em JSON Lines (ou um objeto, ou um array), um por execução, com type igual ao
x_ritual.emits e subject igual a <meta.id>#<id do nó>; time é o fim da execução, e as extensões kgssotoutcome (pass,
fail ou error; sem ela, passou) e kgssotstarted (o início) são do kg-ssot. O registro dá a hora: o ritual de hora em
hora só se mede com ele.

O calendário (x_ritual.calendar) só se expande com o python-dateutil, o extra rituals, e só depois de passar na forma
do SHOULD, julgada pelo próprio leitor: o rrulestr do dateutil é tolerante e não é juiz. Sem o extra, o atraso pelo
calendário e a próxima execução não são medidos, e o relatório diz isso, em vez de calar.

Usado por kg_validate.py --rituals e por kg_gate.py --rituals-overdue. Só a biblioteca padrão, mais o dateutil
quando instalado.
"""
import datetime
import json
import os
import pathlib
import re
import sys

if __package__:  # no pacote kg_ssot, o vizinho vem pelo pacote
    from . import kg_i18n
else:  # script ou vendor
    sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
    import kg_i18n  # noqa: E402
_ = kg_i18n._

SCHEMA_VERSION = "kg-ssot.rituals/1"
RUNS_MAX_BYTES = 64 * 1024 * 1024  # o mesmo teto do kg_capture.py cloudevents
OUTCOMES = ("pass", "fail", "error")
FAILED = ("fail", "error")
# o instante RFC 3339 com fuso (o segundo 60 entra pela forma e é trocado por 59 no cálculo)
RFC3339 = re.compile(r"^\d{4}-\d{2}-\d{2}[Tt]\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:[Zz]|[+-]\d{2}:\d{2})$")
DATE = re.compile(r"^\d{4}-\d{2}-\d{2}$")
# a folga do --grace: duração ISO 8601 só com hora, minuto e segundo (PT30M, PT1H, PT90S)
GRACE = re.compile(r"^PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?$")
NEXT_HORIZON_DAYS = 800  # a próxima execução se procura até ~2 anos à frente; além disso sai nula
MISSED_CAP = 1000  # a contagem de ocorrências perdidas para aqui; o relatório diz "1000 ou mais"
STATES = ("failing", "never_run", "late", "event_only", "on_time")


class Broken(Exception):
    """Entrada quebrada do relatório (rc 2): o --runs ilegível, o instante fora da forma."""


def expander():
    """O rrulestr do python-dateutil e a versão dele, ou (None, None) sem o extra."""
    try:
        import dateutil  # noqa: PLC0415
        from dateutil.rrule import rrulestr  # noqa: PLC0415
    except ImportError:
        return None, None
    return rrulestr, getattr(dateutil, "__version__", None)


def tzdata_version():
    """A versão da base tz que a máquina usa, quando se lê: o pacote tzdata do Python, ou o tzdata.zi do sistema."""
    try:
        import tzdata  # noqa: PLC0415
        return getattr(tzdata, "IANA_VERSION", None)
    except ImportError:
        pass
    for base in os.environ.get("PYTHONTZPATH", "").split(os.pathsep) + ["/usr/share/zoneinfo", "/usr/lib/zoneinfo",
                                                                        "/usr/share/lib/zoneinfo", "/etc/zoneinfo"]:
        path = pathlib.Path(base) / "tzdata.zi" if base else None
        try:
            if path is not None and path.is_file():
                with open(path, encoding="utf-8", errors="replace") as fh:
                    first = fh.readline().strip()
                if first.startswith("# version "):
                    return first[len("# version "):]
        except OSError:
            continue
    return None


def zone(name):
    """O ZoneInfo do nome, ou None quando a máquina não tem a base ou não conhece o nome."""
    try:
        import zoneinfo  # noqa: PLC0415
        return zoneinfo.ZoneInfo(name)
    except Exception:  # noqa: BLE001 - ZoneInfoNotFoundError, ValueError, a base ausente no Windows
        return None


def parse_instant(text):
    """Um instante RFC 3339 com fuso, como datetime ciente; None fora da forma ou impossível no calendário."""
    if not isinstance(text, str) or not RFC3339.fullmatch(text.strip()):
        return None
    stamp = text.strip().upper()
    if stamp[17:19] == "60":
        stamp = stamp[:17] + "59" + stamp[19:]
    try:
        return datetime.datetime.fromisoformat(stamp.replace("Z", "+00:00"))
    except ValueError:
        return None


def parse_when(text):
    """O <quando> do relatório: (o instante, a data AAAA-MM-DD ou None). Uma data vale o fim do dia, no fuso de cada
    ritual; um instante RFC 3339 vale como é."""
    if isinstance(text, str) and DATE.fullmatch(text.strip()):
        try:
            return None, datetime.date.fromisoformat(text.strip())
        except ValueError:
            raise Broken(_("{value}: the date is YYYY-MM-DD").format(value=repr(text))) from None
    moment = parse_instant(text)
    if moment is None:
        raise Broken(_("{value}: give a date YYYY-MM-DD or an RFC 3339 date-time with an offset, such as "
                       "2026-11-17T10:30:00-03:00").format(value=repr(text)))
    return moment, None


def parse_grace(text):
    """A folga do --grace como timedelta: PT30M, PT1H, PT90S."""
    m = GRACE.fullmatch(text.strip()) if isinstance(text, str) else None
    if not m or not any(m.groups()):
        raise Broken(_("--grace {value}: give an ISO 8601 duration with time only, such as PT30M or PT1H")
                     .format(value=repr(text)))
    h, mi, s = (int(g or 0) for g in m.groups())
    try:
        return datetime.timedelta(hours=h, minutes=mi, seconds=s)
    except OverflowError:
        raise Broken(_("--grace {value}: the slack is too large").format(value=repr(text))) from None


def read_runs(path):
    """Os eventos de um registro (objeto, array ou JSON Lines, UTF-8 com ou sem BOM, até 64 MiB). Devolve (eventos,
    ignorados): a linha que não é JSON vai a ignorados com o número dela, em vez de derrubar o relatório inteiro."""
    try:
        size = os.stat(path).st_size
        if size > RUNS_MAX_BYTES:
            raise Broken(_("{path}: {size} bytes, above the 64 MiB cap; split the run log").format(path=path,
                                                                                                    size=size))
        with open(path, "rb") as fh:
            text = fh.read(RUNS_MAX_BYTES + 1).decode("utf-8-sig")
    except (OSError, UnicodeDecodeError) as exc:
        raise Broken(_("{path}: unreadable run log ({error})").format(path=path, error=exc)) from None
    try:
        doc = json.loads(text)
        return (doc if isinstance(doc, list) else [doc]), []
    except ValueError:
        pass
    events, ignored = [], []
    for n, line in enumerate(text.splitlines(), 1):
        if not line.strip():
            continue
        try:
            events.append(json.loads(line))
        except ValueError:
            ignored.append({"file": str(path), "line": n, "reason": "not-json"})
    return events, ignored


def runs_index(paths):
    """{(type, subject): [(instante, resultado, id)]} dos registros, e o resumo do que foi lido e ignorado. O evento
    sem specversion "1.0", type, subject ou time legível é ignorado e contado, nunca adivinhado."""
    index, summary = {}, {"files": [str(p) for p in paths], "events": 0, "ignored": []}
    for path in paths:
        events, ignored = read_runs(path)
        summary["ignored"].extend(ignored)
        for n, ev in enumerate(events, 1):
            summary["events"] += 1
            where = {"file": str(path), "event": n}
            if not isinstance(ev, dict) or ev.get("specversion") != "1.0":
                summary["ignored"].append({**where, "reason": "not-cloudevents"})
                continue
            moment = parse_instant(ev.get("time"))
            if not isinstance(ev.get("type"), str) or not isinstance(ev.get("subject"), str) or moment is None:
                summary["ignored"].append({**where, "reason": "missing-type-subject-or-time"})
                continue
            outcome = ev.get("kgssotoutcome", "pass")
            if outcome not in OUTCOMES:
                summary["ignored"].append({**where, "reason": "unknown-outcome"})
                continue
            started = parse_instant(ev.get("kgssotstarted"))
            if started is not None and started > moment:
                started = None  # o início depois do fim não se usa
            index.setdefault((ev["type"], ev["subject"]), []).append((moment, outcome, ev.get("id"), started))
    return index, summary


def _end_of_day(day, tz):
    return datetime.datetime.combine(day, datetime.time(23, 59, 59), tzinfo=tz)


def _as_date(value):
    if isinstance(value, datetime.datetime):
        return value.date()
    if isinstance(value, datetime.date):
        return value
    if isinstance(value, str) and DATE.fullmatch(value):
        try:
            return datetime.date.fromisoformat(value)
        except ValueError:
            return None
    return None


def _iso(moment, tz=None):
    if moment is None:
        return None
    return (moment.astimezone(tz) if tz is not None else moment).isoformat()


def _shown(run, tz):
    """O instante de uma execução para o relatório: a data, quando a fonte é o verified_at (precisão de dia); senão
    o instante no fuso do ritual."""
    if run is None:
        return None
    return run[0].astimezone(tz).date().isoformat() if run[3] == "day" else _iso(run[0], tz)


def _dtstart(text, tz):
    """O dtstart da forma básica da RFC 5545 (20261116T080000, ou com Z) como datetime ciente; None fora da forma."""
    if not isinstance(text, str):
        return None
    m = re.fullmatch(r"(\d{4})(\d{2})(\d{2})T(\d{2})(\d{2})(\d{2})(Z?)", text)
    if not m:
        return None
    try:
        parts = [int(g) for g in m.groups()[:6]]
        return datetime.datetime(*parts[:5], min(parts[5], 59),
                                 tzinfo=datetime.timezone.utc if m.group(7) else tz)
    except ValueError:
        return None


def _start_of_day(day, tz):
    return datetime.datetime.combine(day, datetime.time(0), tzinfo=tz)


def _bounded(rule, until):
    """A regra com o UNTIL cortado em until, para a busca de uma regra que nunca ocorre (BYMONTH=2;BYMONTHDAY=30) não
    varrer até o ano 9999. Com COUNT a regra não aceita UNTIL, e fica como está (o limite declarado)."""
    if getattr(rule, "_count", None) is not None:
        return rule
    own = getattr(rule, "_until", None)
    try:
        return rule.replace(until=until if own is None or until < own else own)
    except (ValueError, TypeError, AttributeError):
        return rule


def _expand(calendar, rule, seen, start, now, limit, local, late_by, notes):
    """A expansão do calendário: o atraso desde a última execução que passou (ou desde o dtstart), as ocorrências
    perdidas até o teto e a próxima execução, até o horizonte."""
    # a última execução que passou cobre a ocorrência em que começou (o kgssotstarted), não a em que acabou
    passes = [s for s in seen if s[1] == "pass"]
    if passes:  # a execução que começou por último, entre as que passaram
        origin = max((s[4] or s[0]) for s in passes)
    else:
        origin = start - datetime.timedelta(seconds=1)
    window = _bounded(rule, limit)
    first = window.after(origin)
    if first is not None and first <= limit:
        missed = 0
        for _occurrence in window.xafter(origin, count=MISSED_CAP, inc=False):
            if _occurrence > limit:
                break
            missed += 1
        calendar["late_since"] = _iso(first, local)
        calendar["missed"] = missed
        late_by.append("calendar")
    nxt = _bounded(rule, now + datetime.timedelta(days=NEXT_HORIZON_DAYS)).after(now)
    calendar["next_run"] = _iso(nxt, local)
    if nxt is None:
        # acabou quando o UNTIL já passou, ou o COUNT se esgotou; sem os dois, a próxima está só além do
        # horizonte (ou a regra nunca ocorre), e o relatório não varre até o ano 9999 para saber
        until, count = getattr(rule, "_until", None), getattr(rule, "_count", None)
        if (until is not None and until <= now) or (count is not None and rule.after(now) is None):
            notes.append("calendar-ended")


def ritual_entry(name, graph_id, node, evidences, runs, as_of, as_of_day, grace, add_duration, parse_duration,
                 calendar_ok, rrulestr):
    """A entrada de um ritual no relatório. as_of é o instante pedido (None quando o pedido foi uma data, e aí o
    instante é o fim de as_of_day no fuso do ritual).

    Cada execução vista é (instante, resultado, de onde, precisão, início): a precisão é "day" para o que só tem data
    (o verified_at do ritual e o evidence sem x_event.time), lida no fuso do ritual, e "instant" para o que tem hora. O
    início é o kgssotstarted do registro, quando vem: é ele que diz qual ocorrência a execução cobriu."""
    nid = str(node["id"])
    ritual = node.get("x_ritual") if isinstance(node.get("x_ritual"), dict) else {}
    cal = ritual.get("calendar") if isinstance(ritual.get("calendar"), dict) else None
    notes = []
    tz = None
    if cal is not None and isinstance(cal.get("tz"), str):
        tz = zone(cal["tz"])
        if tz is None:
            notes.append("tz-unknown")
    local = tz or datetime.timezone.utc
    now = as_of if as_of is not None else _end_of_day(as_of_day, local)
    today = now.astimezone(local).date()

    def by_day(day, outcome, ref):
        """A execução com precisão de dia: o fim do dia, ou o agora quando o dia é hoje; o dia depois de hoje não
        conta (um carimbo do futuro, numa consulta de data passada)."""
        # o dia depois de hoje não conta, salvo o dia UTC de agora (o executor que carimba pela data UTC já virou o dia)
        if day is None or day > max(today, now.astimezone(datetime.timezone.utc).date()):
            return None
        return (min(_end_of_day(day, local), now), outcome, ref, "day", None)

    seen = []
    stamped = _as_date(node.get("verified_at"))
    stamp = by_day(stamped, "pass", "verified_at")
    if stamp is not None:
        seen.append(stamp)
    for ev_node in evidences:
        event = ev_node.get("x_event") if isinstance(ev_node.get("x_event"), dict) else {}
        outcome = ev_node.get("x_outcome") if ev_node.get("x_outcome") in OUTCOMES else None
        ref = "evidence:" + str(ev_node.get("id"))
        moment = parse_instant(event.get("time"))
        if moment is not None:
            seen.append((moment, outcome, ref, "instant", None))
            continue
        day = _as_date(ev_node.get("verified_at"))
        if day is None:
            notes.append("evidence-without-time")
            continue
        entry = by_day(day, outcome, ref)
        if entry is not None:
            seen.append(entry)
    emits = ritual.get("emits")
    subject = f"{graph_id}#{nid}" if graph_id else None
    if runs is not None and isinstance(emits, str) and subject:
        for moment, outcome, run_id, started in runs.get((emits, subject), []):
            seen.append((moment, outcome, "run:" + str(run_id), "instant", started))
    seen = [s for s in seen if s[0] <= now]  # o que vem depois do instante pedido não conta
    # o carimbo de dia não cobre o que o registro diz com hora: com uma execução que passou com o instante no mesmo dia
    # do carimbo ou depois, no fuso do ritual ou em UTC (o executor que carimba pela data UTC), o verified_at sai da conta,
    # para o fim do dia não esconder a execução perdida
    precise = [s[0] for s in seen if s[3] == "instant" and s[1] == "pass"]
    if precise:
        covered = max(max(m.astimezone(local).date(), m.astimezone(datetime.timezone.utc).date()) for m in precise)
        seen = [s for s in seen if not (s[3] == "day" and s[1] == "pass"
                                        and s[0].astimezone(local).date() <= covered)]
    key = lambda s: s[0]  # noqa: E731
    last_run_t = max(seen, default=None, key=key)
    last_pass_t = max((s for s in seen if s[1] == "pass"), default=None, key=key)
    def instant_for_failure(s):
        """Contra a falha, o que tem precisão de dia vale o começo do dia: a falha das 17h não some por um carimbo do
        mesmo dia, que pode ser de uma execução anterior a ela (a dúvida fica do lado de mostrar a falha)."""
        return _start_of_day(s[0].astimezone(local).date(), local) if s[3] == "day" else s[0]
    last_failure = max((s for s in seen if s[1] in FAILED), default=None, key=instant_for_failure)
    last_pass = last_pass_t[0] if last_pass_t else None
    every = node.get("reverify_every")
    duration = parse_duration(every) if isinstance(every, str) else None
    due_on = days_late = None
    late_by = []
    cadence_late = False
    if duration is not None and last_pass is not None:
        try:
            due_on = add_duration(last_pass.astimezone(local).date(), duration)
        except (OverflowError, ValueError):
            due_on = None
        if due_on is not None and due_on < today:  # atrasado é passar do dia do vencimento, não chegar nele
            cadence_late = True
            days_late = (today - due_on).days
    calendar = {"expanded": False, "late_since": None, "missed": None, "next_run": None}
    if cal is not None:
        start = _dtstart(cal.get("dtstart"), tz) if calendar_ok and "tz-unknown" not in notes else None
        if not calendar_ok or (start is not None and start.tzinfo is None):
            notes.append("calendar-malformed")
        elif rrulestr is None:
            notes.append("calendar-not-expanded")
        elif "tz-unknown" not in notes:
            rule = None
            if start is not None:
                try:
                    rule = rrulestr(cal.get("rrule"), dtstart=start)
                except (ValueError, TypeError, OverflowError):
                    rule = None
            if rule is None:
                notes.append("calendar-not-expanded")
            else:
                calendar["expanded"] = True
                try:
                    limit = now - grace
                except OverflowError:
                    raise Broken(_("--grace {value}: the slack goes past the start of the calendar").format(
                        value=_iso_grace(grace))) from None
            if rule is not None:
                try:
                    _expand(calendar, rule, seen, start, now, limit, local, late_by, notes)
                except OverflowError:  # um dtstart no ano 1 ou um QUANDO no ano 9999: a conta sai do calendário
                    calendar.update({"expanded": False, "late_since": None, "missed": None, "next_run": None})
                    notes.append("calendar-not-expanded")
                    if "calendar" in late_by:
                        late_by.remove("calendar")
    # com o calendário expandido, é ele que diz se o ritual está atrasado; a cadência só decide sem ele (sem o extra,
    # ou com o calendário fora da forma), porque o reverify_every mede dia corrido, e o calendário sabe do fim de semana
    if cadence_late and not calendar["expanded"]:
        late_by.insert(0, "cadence")
    cleared = max((instant_for_failure(s) for s in seen if s[1] == "pass"), default=None)
    if last_failure is not None and (cleared is None or instant_for_failure(last_failure) >= cleared):
        state = "failing"
    elif not seen:
        state = "never_run"
    elif late_by:
        state = "late"
    elif duration is None and cal is None and isinstance(node.get("reverify_on"), str):
        state = "event_only"
    else:
        state = "on_time"
    return {"file": name, "id": nid, "owner": node.get("owner") if isinstance(node.get("owner"), str) else None,
            "state": state, "late_by": late_by, "last_run": _shown(last_run_t, local),
            "last_pass": _shown(last_pass_t, local), "last_failure": _shown(last_failure, local),
            "last_failure_ref": last_failure[2] if last_failure else None,
            "reverify_every": every if isinstance(every, str) else None,
            "reverify_on": node.get("reverify_on") if isinstance(node.get("reverify_on"), str) else None,
            "due_on": due_on.isoformat() if due_on is not None else None, "days_late": days_late,
            "calendar": calendar if cal is not None else None, "notes": sorted(set(notes))}


def rituals_report(sources, when, run_paths=(), grace=None, kg=None):
    """O relatório do ritmo: {as_of, expander, tzdata, grace, runs, owners, broken}. sources é [(nome, texto)];
    kg é o módulo kg_validate (parse_v1, a aritmética das durações e o juízo do SHOULD)."""
    if kg is None:
        if __package__:
            from . import kg_validate as kg  # noqa: PLC0415
        else:
            import kg_validate as kg  # noqa: PLC0415
    as_of, as_of_day = parse_when(when)
    grace = grace or datetime.timedelta(0)
    runs, summary = runs_index(run_paths) if run_paths else (None, None)
    rrulestr, version = expander()
    out = {"as_of": when.strip(), "expander": {"name": "python-dateutil", "version": version} if rrulestr else None,
           "tzdata": tzdata_version(), "grace": _iso_grace(grace), "runs": summary, "owners": [], "broken": []}
    should = kg._validator_at(kg.CONTRACT_SHOULD) if hasattr(kg, "_validator_at") else None
    must = kg._validator_at(kg.CONTRACT_MUST) if hasattr(kg, "_validator_at") else None
    entries = []
    for name, text in sources:
        _raw, doc, err = kg.parse_v1(text)
        if err or not isinstance(doc, dict):
            out["broken"].append({"file": name, "error": str(err or kg.ROOT_NOT_MAP)})
            continue
        meta = doc.get("meta") if isinstance(doc.get("meta"), dict) else {}
        graph_id = meta.get("id") if isinstance(meta.get("id"), str) else None
        nodes = doc.get("nodes") if isinstance(doc.get("nodes"), list) else []
        rituals = [(i, n) for i, n in enumerate(nodes)
                   if isinstance(n, dict) and n.get("id") is not None and isinstance(n.get("x_ritual"), dict)]
        if not rituals:
            continue
        bad_calendar = set()
        if should is not None and any(isinstance(n["x_ritual"].get("calendar"), dict) for _, n in rituals):
            for _level, code, _place, path in kg.occurrences(text, must, should):
                if len(path) >= 4 and path[0] == "nodes" and path[2] == "x_ritual" and path[3] == "calendar":
                    bad_calendar.add(path[1])
                elif (code == "form.misplaced.node.x_ritual" and len(path) >= 2 and path[0] == "nodes"):
                    # o perfil fora do lugar: o SHOULD não julga o calendário dele (o aviso da cadência ou de uma chave
                    # desconhecida no perfil, que têm o mesmo caminho, não tiram o calendário da conta)
                    bad_calendar.add(path[1])
        traced = {}
        for e in doc.get("edges") if isinstance(doc.get("edges"), list) else []:
            if isinstance(e, dict) and e.get("edge_type") == "TRACES_TO":
                traced.setdefault(str(e.get("to")), []).append(str(e.get("from")))
        by_id = {str(n.get("id")): n for n in nodes if isinstance(n, dict)}
        for i, n in rituals:
            evidences = [by_id[f] for f in traced.get(str(n["id"]), [])
                         if f in by_id and by_id[f].get("node_type") == "evidence"]
            entries.append(ritual_entry(name, graph_id, n, evidences, runs, as_of, as_of_day, grace,
                                        kg.add_duration, kg.parse_duration, i not in bad_calendar, rrulestr))
    owners = {}
    for entry in entries:
        owners.setdefault(entry["owner"], []).append(entry)
    for owner in sorted(owners, key=lambda o: (o is None, o or "")):
        rows = sorted(owners[owner], key=lambda e: (STATES.index(e["state"]), e["file"], e["id"]))
        out["owners"].append({"owner": owner, "rituals": rows})
    return out


def _iso_grace(grace):
    seconds = int(grace.total_seconds())
    if not seconds:
        return None
    h, rest = divmod(seconds, 3600)
    m, s = divmod(rest, 60)
    return "PT" + (f"{h}H" if h else "") + (f"{m}M" if m else "") + (f"{s}S" if s else "")


def is_overdue(entry):
    """O ritual passou do prazo: atrasado pela cadência ou pelo calendário, em qualquer estado (o nunca executado com a
    primeira ocorrência já vencida, e o que falhou e deixou ocorrências passarem, inclusive)."""
    return bool(entry["late_by"])


def counts(rep):
    """{estado: n} do relatório inteiro."""
    out = dict.fromkeys(STATES, 0)
    for group in rep["owners"]:
        for entry in group["rituals"]:
            out[entry["state"]] += 1
    return out


def note_text(note):
    """A frase humana de uma nota da entrada (as notas do JSON são o vocabulário estável)."""
    if note == "tz-unknown":
        return _("this machine does not know the time zone, so the calendar was not expanded")
    if note == "calendar-malformed":
        return _("the calendar is out of form (see the SHOULD warning), so it was not expanded")
    if note == "calendar-ended":
        return _("the calendar has no more occurrences (COUNT or UNTIL reached)")
    if note == "calendar-not-expanded":
        return _("the calendar was not expanded: install the rituals extra (python-dateutil)")
    return _("an evidence node that traces to the ritual has no time and no verified_at")


def lines(rep):
    """As linhas humanas do relatório, por dono."""
    labels = {"failing": _("OPEN FAILURE"), "never_run": _("NEVER RUN"), "late": _("LATE"),
              "event_only": _("BY EVENT"), "on_time": _("ON TIME")}
    w = max(len(v) for v in labels.values())
    out = []
    for group in rep["owners"]:
        out.append(_("owner {owner}").format(owner=group["owner"]) if group["owner"] is not None
                   else _("no owner (add owner: the role that approves a change to the ritual)"))
        for e in group["rituals"]:
            detail = []
            if e["state"] == "failing":
                detail.append(_("failed at {when} ({ref}), no run passed after it").format(
                    when=e["last_failure"], ref=e["last_failure_ref"]))
            if "cadence" in e["late_by"]:
                detail.append(_("every {every}, due on {due_on}, {days} day(s) late").format(
                    every=e["reverify_every"], due_on=e["due_on"], days=e["days_late"]))
            cal = e["calendar"] or {}
            if cal.get("late_since"):
                missed = cal["missed"]
                detail.append(_("calendar: {missed} run(s) missed since {since}").format(
                    missed=f"{missed}+" if missed >= MISSED_CAP else missed, since=cal["late_since"]))
            if e["state"] == "event_only":
                detail.append(_("on the event {event}").format(event=e["reverify_on"]))
            if e["last_pass"] and e["state"] != "never_run":
                detail.append(_("last pass {when}").format(when=e["last_pass"]))
            if cal.get("next_run"):
                detail.append(_("next {when}").format(when=cal["next_run"]))
            for note in e["notes"]:
                detail.append(note_text(note))
            out.append(f"  {labels[e['state']]:<{w}} {e['file']}  {e['id']}" + (": " + "; ".join(detail)
                                                                                 if detail else ""))
    for b in rep["broken"]:
        out.append(_("UNREADABLE {file}: {error}").format(file=b["file"], error=b["error"]))
    c = counts(rep)
    out.append(_("· on {as_of}: {failing} with an open failure, {never} never run, {late} late, {event} by event, "
                 "{ok} on time; the report does not change the verdict").format(
        as_of=rep["as_of"], failing=c["failing"], never=c["never_run"], late=c["late"], event=c["event_only"],
        ok=c["on_time"]))
    if rep["expander"] is None:
        out.append(_("· the calendars were not expanded: without the rituals extra (python-dateutil), lateness is "
                     "measured by the cadence only, per day"))
    if rep["runs"] is None:
        out.append(_("· no run log (--runs): the last run is the verified_at of the graph, with day precision; an "
                     "hourly ritual is only measured with the log"))
    else:
        ignored = len(rep["runs"]["ignored"])
        out.append(_("· run log: {events} event(s) read, {ignored} ignored").format(events=rep["runs"]["events"],
                                                                                     ignored=ignored))
    return out
