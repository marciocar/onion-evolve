#!/usr/bin/env python3
"""Bancada OFFLINE dos verbos estimate.points, estimate.points_read e due_date.set do Linear e do velocity-meter.py.

Roda pela família run_task_manager_velocity_selftests do lint-selftest.sh. Nenhuma chamada sai da máquina: o Linear é um
GraphQL FALSO em loopback (costura TM_LINEAR_ENDPOINT, só 127.0.0.1), e o medidor passa pelo tm.sh de verdade.
O que esta bancada NÃO prova: que o Linear real se comporta como o falso. A medição ao vivo está no linear.md.

Três partes, no molde das bancadas do task manager: CASOS; CÓPIA LIMPA verde no arranjo dos mutantes; MUTANTES, cada um
revertendo UMA cura na cópia e exigindo que o caso dela reprove.
Saída: `ok   …` por caso verde, `FALHA (n):` no fim com `- …` por vermelho; última linha com as contagens; rc 0 ou 1.
"""
import datetime as dt
import http.server
import json
import os
import shutil
import subprocess
import sys
import tempfile
import threading

ROOT = (sys.argv[1] if len(sys.argv) > 1 else
        subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True, text=True).stdout.strip() or os.getcwd())
TM_DIR = os.path.join(ROOT, ".claude/utils/task-manager")
TODAY = "2026-11-20"
BASE = dt.datetime(2026, 11, 1, tzinfo=dt.timezone.utc)
RULES = """category\tcalibrate\tregex
maestro-act\tno\t^\\[maestro\\b
alpha\tyes\talpha
beta\tyes\tbeta
delta\tyes\tdelta
epsilon\tyes\tepsilon
zeta\tyes\tzeta
eta\tyes\tinvertido
theta\tyes\ttheta
iota\tyes\tiota
kappa\tyes\tkappa
lambda\tyes\tlambda
"""
LEAKY_TITLE = "[core · 09/11] alpha revisão SAC-99 em 2026-10-02"
LEAKY_DESC = """Leva SAC-12 para produção.
Prazo: entregar logo
levou muito trabalho
Feito em 2h30 mais 45 min, em 2026-10-01, até 09/11, ver #1234, commit abc1234f, https://linear.app/x/SAC-1
ciclo de 2026 inteiro, 3 rodadas de CI, 8 de novembro, novembro de 2026, segunda-feira, ontem, duas semanas, 5 pts, às 14:30"""
FORBIDDEN = ["SAC-", "[core", "09/11", "2026", "2h30", "45 min", "#1234", "abc1234f", "linear.app", "novembro", "segunda", "ontem", "duas semanas", "5 pts", "14:30", "Prazo", "levou", "3 rodadas"]


def ts(hours):
    return (BASE + dt.timedelta(hours=hours)).strftime("%Y-%m-%dT%H:%M:%S.000Z")


def issue(n, title, created=None, queue=None, work=None, est=None, due=None, parent=None, desc=None, state=("Done", "completed"), completed_at=None):
    created = n * 3 if created is None else created
    started = None if queue is None else created + queue
    completed = completed_at if completed_at is not None else (None if work is None else started + work)
    return {"id": f"uuid-{n}", "identifier": f"SAC-{n}", "title": title, "description": desc, "url": f"https://app.example/{n}", "priority": 0,
            "priorityLabel": "None", "estimate": est, "createdAt": ts(created), "updatedAt": ts(created),
            "startedAt": None if started is None else ts(started), "completedAt": None if completed is None else ts(completed), "canceledAt": None,
            "dueDate": due, "archivedAt": None, "state": {"id": "s1", "name": state[0], "type": state[1]},
            "team": {"id": "team-sac", "key": "SAC", "name": "Sacola"}, "project": {"id": "proj-1", "name": "Core"},
            "parent": {"id": f"uuid-{parent}", "identifier": f"SAC-{parent}", "title": "mae"} if parent else None,
            "assignee": None, "labels": {"nodes": []}}


def seed():
    rows = []
    for k in range(1, 7):                          # alpha: 2 pontos; fila 10..60 h; trabalho 2..12 h (h/ponto 1..6)
        rows.append(issue(k, f"alpha item {k}", created=3 * k, queue=10 * k, work=2 * k, est=2, desc=LEAKY_DESC if k == 1 else "corpo"))
    rows[0]["title"] = LEAKY_TITLE
    for k in range(1, 6):                          # delta: 1 ponto; trabalho 1..5 h, erro LOO exato 0,5
        rows.append(issue(10 + k, f"delta item {k}", created=144 + 3 * k, queue=1, work=k, est=1))
    for k in range(1, 4):                          # beta: amostra insuficiente
        rows.append(issue(20 + k, f"beta item {k}", created=216 + 3 * k, queue=2, work=2, est=3))
    rows.append(issue(30, "[maestro · 12/11] ato humano"))
    rows.append(issue(31, "theta sem início", created=240, est=2, completed_at=250))
    for n in (32, 33, 34):                         # zeta: fechadas no mesmo minuto, arrumação do quadro
        rows.append(issue(n, f"zeta lote {n}", created=260, queue=1, completed_at=262.1, est=2))
    rows.append(issue(35, "epsilon mãe", created=280, queue=1, work=9, est=8))
    rows.append(issue(36, "epsilon filha", created=282, queue=1, work=8, est=2, parent=35))
    rows.append(issue(37, "relógio invertido", created=300, queue=5, completed_at=302, est=2))
    rows.append(issue(38, "[core · 09/11] iota do título", created=310, queue=1, work=2, est=2))
    rows.append(issue(39, "iota do campo", created=315, queue=1, work=3, est=2, due="2026-11-30"))
    for k, n in enumerate(range(40, 44)):          # kappa: semanas distintas para a velocidade
        rows.append(issue(n, f"kappa {n}", created=-1200 + 168 * k, queue=1, work=1, est=5))
    for k, pts in enumerate([1, 2, 3, 5, 8, 13]):  # lambda: pontos ordenam a duração (spearman 1)
        rows.append(issue(61 + k, f"lambda {k}", created=340 + 3 * k, queue=1, work=pts * 1.5, est=pts))
    rows.append(issue(60, "sem regra nenhuma", created=420, queue=1, work=2, est=1))
    rows.append(issue(50, "alpha aberta sem pontos", created=430, state=("Todo", "unstarted")))
    rows.append(issue(51, "alpha em andamento", created=431, queue=1, est=3, state=("In Progress", "started")))
    rows.append(issue(70, "alpha issue de escrita", created=432, state=("Todo", "unstarted"), est=None))
    rows.append(issue(71, "sem pontos", created=433, state=("Todo", "unstarted"), est=None))
    return {"issues": rows, "log": [], "force": None,
            "team": {"issueEstimationType": "fibonacci", "issueEstimationExtended": True, "issueEstimationAllowZero": False}}


def find(store, ident):
    return next((r for r in store["issues"] if ident in (r["id"], r["identifier"])), None)


class Handler(http.server.BaseHTTPRequestHandler):
    store = None

    def log_message(self, *a):
        pass

    def _reply(self, obj):
        raw = json.dumps(obj).encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(raw)))
        self.end_headers()
        self.wfile.write(raw)

    def _errors(self, msg):
        return self._reply({"data": None, "errors": [{"message": msg}]})

    def do_POST(self):
        req = json.loads(self.rfile.read(int(self.headers.get("Content-Length") or 0)).decode("utf-8"))
        q, v, s = req["query"], req.get("variables") or {}, self.store
        s["log"].append({"query": q, "variables": v})
        if "issueUpdate" in q:
            row = find(s, v["id"])
            if s["force"] != "update_noop":
                row.update(v["in"])
            return self._reply({"data": {"issueUpdate": {"success": True, "issue": row}}})
        if "issues(" in q:
            rows = s["issues"]
            flt = v.get("f") or {}
            if "state" in flt:
                rows = [r for r in rows if r["state"]["type"] in flt["state"]["type"]["in"]]
            if "project" in flt:
                rows = [r for r in rows if r["project"]["id"] == flt["project"]["id"]["eq"]]
            start = int(v["after"]) if v.get("after") else 0
            size = v["n"]
            page = rows[start:start + size]
            if "description" not in q.split("nodes", 1)[1].split("pageInfo", 1)[0]:
                page = [{k: x for k, x in r.items() if k != "description"} for r in page]
            more = start + size < len(rows)
            return self._reply({"data": {"issues": {"nodes": page, "pageInfo": {"hasNextPage": more, "endCursor": str(start + size) if more else None}}}})
        if "projects(" in q:
            known = [{"id": "proj-1", "name": "Core", "state": "x", "url": "u", "teams": {"nodes": []}}]
            return self._reply({"data": {"projects": {"nodes": [p for p in known if p["name"].lower() == str(v.get("n")).lower()]}}})
        if "team(id" in q:
            return self._reply({"data": {"team": s["team"]}})
        if "issue(id" in q:
            row = find(s, v["id"])
            return self._reply({"data": {"issue": row}}) if row else self._errors("Entity not found: Issue")
        return self._errors("consulta desconhecida da bancada")


class Fake:
    def __init__(self, force=None, team=None):
        self.force, self.team = force, team

    def __enter__(self):
        self.store = seed()
        self.store["force"] = self.force
        if self.team:
            self.store["team"].update(self.team)
        handler = type("H", (Handler,), {"store": self.store})
        self.srv = http.server.ThreadingHTTPServer(("127.0.0.1", 0), handler)
        self.port = self.srv.server_address[1]
        threading.Thread(target=self.srv.serve_forever, daemon=True).start()
        return self

    def __exit__(self, *a):
        self.srv.shutdown()
        self.srv.server_close()

    def writes(self):
        return [r for r in self.store["log"] if "issueUpdate" in r["query"]]


def env_for(fake, provider="linear", extra=None):
    env = {k: v for k, v in os.environ.items() if not k.startswith(("LINEAR_", "TM_", "CLICKUP_", "TASK_MANAGER"))}
    env.update({"TASK_MANAGER_PROVIDER": provider, "TM_ENV_FILE": "/nao-existe.env", "LINEAR_API_KEY": "lin_fake_bench", "LC_ALL": "C.UTF-8",
                "TM_LINEAR_ENDPOINT": f"http://127.0.0.1:{fake.port}/graphql"})
    env.update(extra or {})
    return env


def parse(p):
    try:
        out = json.loads(p.stdout) if p.stdout.strip() else None
    except ValueError:
        out = None
    return p.returncode, out, p.stderr.strip()


def tm(d, fake, *args):
    return parse(subprocess.run(["bash", os.path.join(d, "tm.sh"), *args], capture_output=True, text=True, env=env_for(fake), timeout=20, cwd=d))


class Meter:
    """Roda o medidor num diretório sem git, com o arquivo de regras da bancada."""

    def __init__(self, d):
        self.d = d
        self.tmp = tempfile.mkdtemp(prefix="velocity-bench-")
        self.rules = os.path.join(self.tmp, "rules.tsv")
        with open(self.rules, "w", encoding="utf-8") as fh:
            fh.write(RULES)

    def __enter__(self):
        return self

    def __exit__(self, *a):
        shutil.rmtree(self.tmp, ignore_errors=True)

    def raw(self, fake, *args, provider="linear", extra=None, cwd=None):
        cmd = ["python3", "-I", "-B", os.path.join(self.d, "velocity-meter.py"), *args]
        try:
            return subprocess.run(cmd, capture_output=True, text=True, env=env_for(fake, provider, extra), timeout=30, cwd=cwd or self.tmp)
        except subprocess.TimeoutExpired:
            return subprocess.CompletedProcess(cmd, 124, "", "timeout")

    def run(self, fake, cmd, *args, **kw):
        return parse(self.raw(fake, cmd, "--categories", self.rules, "--today", TODAY, *args, **kw))


def cat(report, name):
    return next(c for c in report["categories"] if c["category"] == name)


# ── verbos ───────────────────────────────────────────────────────────────────
def c_caps(d):
    out = subprocess.run(["python3", "-I", "-B", os.path.join(d, "adapters/linear.py"), "--capabilities"], capture_output=True, text=True).stdout.split()
    missing = {"estimate.points", "estimate.points_read", "due_date.set"} - set(out)
    return f"ausentes: {missing}" if missing else ""


def c_estimate_write(d):
    with Fake() as f:
        rc, out, err = tm(d, f, "estimate.points", "SAC-70", "5")
        if rc != 0 or out["estimate"] != 5 or out["previous"] is not None or out["scale"]["type"] != "fibonacci":
            return f"rc={rc} {out} {err[:120]}"
        w = f.writes()
        if len(w) != 1 or w[0]["variables"]["in"] != {"estimate": 5}:
            return f"mutação errada: {w}"
    return ""


def c_estimate_noop(d):
    with Fake("update_noop") as f:
        rc, out, err = tm(d, f, "estimate.points", "SAC-70", "5")
        return "" if rc == 1 and out is None and "ficou com estimate" in err else f"rc={rc} {out} {err[:120]}"


def c_estimate_out_of_scale(d):
    with Fake() as f:
        rc, _, err = tm(d, f, "estimate.points", "SAC-70", "4")
        if rc != 2 or "fora da escala" not in err:
            return f"rc={rc} {err[:120]}"
        return "foi à mutação" if f.writes() else ""


def c_estimate_extended_off(d):
    with Fake(team={"issueEstimationExtended": False}) as f:
        rc, _, err = tm(d, f, "estimate.points", "SAC-70", "13")
        return "" if rc == 2 and "fora da escala" in err and not f.writes() else f"rc={rc} {err[:120]}"


def c_estimate_extended_on(d):
    with Fake() as f:
        rc, out, err = tm(d, f, "estimate.points", "SAC-70", "21")
        return "" if rc == 0 and out["estimate"] == 21 else f"rc={rc} {err[:120]}"


def c_estimate_not_used(d):
    with Fake(team={"issueEstimationType": "notUsed"}) as f:
        rc, _, err = tm(d, f, "estimate.points", "SAC-70", "5")
        return "" if rc == 2 and "desligada" in err and not f.writes() else f"rc={rc} {err[:120]}"


def c_estimate_clear(d):
    with Fake() as f:
        f.store["issues"][[r["identifier"] for r in f.store["issues"]].index("SAC-70")]["estimate"] = 3
        rc, out, err = tm(d, f, "estimate.points", "SAC-70", "--clear")
        if rc != 0 or out["estimate"] is not None or out["previous"] != 3 or f.writes()[0]["variables"]["in"] != {"estimate": None}:
            return f"rc={rc} {out} {err[:120]}"
    return ""


def c_estimate_bad_value(d):
    with Fake() as f:
        for v in ("abc", "1.5"):
            rc, _, err = tm(d, f, "estimate.points", "SAC-70", v)
            if rc != 2 or "inteiro" not in err:
                return f"{v}: rc={rc} {err[:120]}"
        return "foi à rede" if f.store["log"] else ""


def c_usage(d):
    with Fake() as f:
        for args in (["estimate.points", "SAC-70"], ["estimate.points", "SAC-70", "5", "8"], ["estimate.points", "SAC-70", "--force"],
                     ["due_date.set", "SAC-70"], ["due_date.set", "--clear", "SAC-70"], ["estimate.points", "nao-e-id", "5"]):
            rc, out, err = tm(d, f, *args)
            if rc != 2 or out is not None:
                return f"{args}: rc={rc} {out} {err[:100]}"
        return "erro de uso foi à rede" if f.store["log"] else ""


def c_points_read(d):
    with Fake() as f:
        rc, out, err = tm(d, f, "estimate.points_read", "SAC-1")
        return "" if rc == 0 and out["estimate"] == 2 and out["scale"]["values"][-1] == 21 else f"rc={rc} {out} {err[:120]}"


def c_due_write(d):
    with Fake() as f:
        rc, out, err = tm(d, f, "due_date.set", "SAC-70", "2026-11-30")
        if rc != 0 or out["dueDate"] != "2026-11-30" or f.writes()[0]["variables"]["in"] != {"dueDate": "2026-11-30"}:
            return f"rc={rc} {out} {err[:120]}"
    return ""


def c_due_noop(d):
    with Fake("update_noop") as f:
        rc, _, err = tm(d, f, "due_date.set", "SAC-70", "2026-11-30")
        return "" if rc == 1 and "ficou com dueDate" in err else f"rc={rc} {err[:120]}"


def c_due_bad_date(d):
    with Fake() as f:
        for v in ("2026-02-30", "30/11", "2026-11-30T10:00", "20261130"):
            rc, _, err = tm(d, f, "due_date.set", "SAC-70", v)
            if rc != 2 or "data inválida" not in err:
                return f"{v}: rc={rc} {err[:120]}"
        return "foi à rede" if f.store["log"] else ""


def c_due_clear(d):
    with Fake() as f:
        rc, out, err = tm(d, f, "due_date.set", "SAC-39", "--clear")
        return "" if rc == 0 and out["dueDate"] is None and out["previous"] == "2026-11-30" else f"rc={rc} {out} {err[:120]}"


def c_read_fields(d):
    with Fake() as f:
        rc, out, err = tm(d, f, "item.read", "SAC-1", "--lean")
        if rc != 0:
            return err[:160]
        q = f.store["log"][0]["query"]
        for k in ("estimate", "startedAt", "completedAt", "dueDate"):
            if k not in q:
                return f"{k} fora do item.read"
    return ""


def c_list_fields(d):
    with Fake() as f:
        rc, out, err = tm(d, f, "item.list", "--state-type", "completed", "--limit", "3")
        if rc != 0:
            return err[:160]
        q = next(r["query"] for r in f.store["log"] if "issues(" in r["query"])
        for k in ("estimate", "startedAt", "completedAt", "dueDate", "parent", "labels"):
            if k not in q:
                return f"{k} fora do item.list"
        if "description" in out["issues"][0]:
            return "description veio sem a flag"
    return ""


def c_list_with_description(d):
    with Fake() as f:
        rc, out, err = tm(d, f, "item.list", "--state-type", "completed", "--limit", "1", "--with-description")
        return "" if rc == 0 and "description" in out["issues"][0] else f"rc={rc} {err[:120]}"


def c_list_project(d):
    with Fake() as f:
        rc, out, err = tm(d, f, "item.list", "--project", "proj-1x", "--limit", "1")
        if rc != 1:
            return f"id inexistente devia falhar: rc={rc}"
        rc, out, err = tm(d, f, "item.list", "--project", "Core", "--limit", "1")
        flt = out["filter"] if out else None
        return "" if rc == 0 and flt == {"project": {"id": {"eq": "proj-1"}}} else f"rc={rc} {flt} {err[:120]}"


# ── medidor: relatório ───────────────────────────────────────────────────────
def report(d, f, *args):
    with Meter(d) as m:
        return m.run(f, "report", *args)


def c_queue_work_separate(d):
    with Fake() as f:
        rc, out, err = report(d, f)
        if rc != 0:
            return err[:200]
        a = cat(out, "alpha")
        if a["queue_hours"]["p50"] != 35.0 or a["work_hours"]["p50"] != 7.0 or a["hours_per_point"]["p50"] != 3.5:
            return f"percentis errados: {a['queue_hours']} {a['work_hours']} {a['hours_per_point']}"
    return ""


def c_exclusions(d):
    with Fake() as f:
        _, out, err = report(d, f)
        for name, reason, count in (("theta", "no_started_at", 1), ("zeta", "batch_closed", 3), ("epsilon", "rollup_parent", 1), ("eta", "negative_clock", 1)):
            c = cat(out, name)
            if c["excluded"].get(reason) != count:
                return f"{name}: {c['excluded']}"
        if cat(out, "epsilon")["with_work_clock"] != 1 or cat(out, "zeta")["with_work_clock"] != 0:
            return "relógio contado onde não devia"
    return ""


def c_sample_warning(d):
    with Fake() as f:
        _, out, err = report(d, f)
        b, a = cat(out, "beta"), cat(out, "alpha")
        if b["sample"] != {"points_and_clock": 3, "level": "insufficient"} or b["warnings"][0]["code"] != "insufficient_sample":
            return f"beta: {b['sample']} {b['warnings']}"
        if a["sample"]["level"] != "small" or a["warnings"][0]["code"] != "small_sample":
            return f"alpha: {a['sample']} {a['warnings']}"
    return ""


def c_loo_error(d):
    with Fake() as f:
        _, out, err = report(d, f)
        e = cat(out, "delta")["estimate_error_loo"]
        return "" if e["n"] == 5 and e["median_abs_pct_error"] == 0.5 else f"erro: {e}"


def c_spearman(d):
    with Fake() as f:
        _, out, err = report(d, f)
        r = cat(out, "lambda")["points_vs_hours_spearman"]
        return "" if r == 1.0 else f"spearman: {r}"


def c_title_deadline(d):
    with Fake() as f:
        _, out, err = report(d, f)
        dl = cat(out, "iota")["deadline"]
        return "" if dl["n"] == 2 and dl["from_field"] == 1 and dl["from_title"] == 1 else f"prazos: {dl}"


def c_window(d):
    with Fake() as f:
        _, out, err = report(d, f, "--window", "2")
        a = cat(out, "alpha")
        return "" if a["hours_per_point"]["n"] == 2 and a["hours_per_point"]["p50"] == 5.5 else f"janela: {a['hours_per_point']}"


def c_overlay(d):
    with Fake() as f, Meter(d) as m:
        path = os.path.join(m.tmp, "o.json")
        with open(path, "w", encoding="utf-8") as fh:
            json.dump({"SAC-40": 13}, fh)
        rc, out, err = m.run(f, "report", "--estimates-overlay", path)
        if rc != 0 or cat(out, "kappa")["points_total"] != 28:
            return f"rc={rc} {cat(out, 'kappa')['points_total'] if out else err[:120]}"
        return "overlay escreveu no provedor" if f.writes() else ""


def c_other_listed(d):
    with Fake() as f:
        _, out, err = report(d, f)
        return "" if "sem regra nenhuma" in out["uncategorized_titles"] else f"{out['uncategorized_titles']}"


def c_no_rules(d):
    with Fake() as f, Meter(d) as m:
        rc, out, err = parse(m.raw(f, "report", "--today", TODAY))
        codes = [w["code"] for w in out["warnings"]] if out else []
        return "" if rc == 0 and "no_category_rules" in codes and [c["category"] for c in out["categories"]] == ["other"] else f"rc={rc} {codes} {err[:120]}"


def c_truncated(d):
    with Fake() as f, Meter(d) as m:
        rc, out, err = m.run(f, "report", extra={"TM_VELOCITY_FETCH_LIMIT": "2"})
        return "" if rc == 1 and out is None and "parcial" in err else f"rc={rc} {err[:160]}"


def c_provider_gap(d):
    with Fake() as f, Meter(d) as m:
        rc, out, err = m.run(f, "report", provider="asana")
        return "" if rc == 2 and out is None and "não sustenta" in err else f"rc={rc} {err[:160]}"


def c_bad_categories(d):
    with Fake() as f, Meter(d) as m:
        with open(m.rules, "w", encoding="utf-8") as fh:
            fh.write("x\tyes\t(\n")
        rc, _, err = m.run(f, "report")
        return "" if rc == 2 and "regex inválida" in err else f"rc={rc} {err[:160]}"


# ── medidor: data proposta ───────────────────────────────────────────────────
def propose(d, f, *args):
    with Meter(d) as m:
        return m.run(f, "propose", *args)


def c_propose_history(d):
    with Fake() as f:
        rc, out, err = propose(d, f, "--points", "8", "--category", "alpha")
        if rc != 0:
            return f"rc={rc} {out} {err[:160]}"
        p = out["proposal"]
        if p != {"due_date": "2026-11-22", "range": {"low": "2026-11-21", "high": "2026-11-23"}} or out["basis"]["queue_mode"] != "category_queue_history":
            return f"{p} {out['basis']['queue_mode']}"
    return ""


def c_propose_ahead(d):
    with Fake() as f:
        _, rep, _ = report(d, f)
        rate = rep["team_velocity"]["points_per_active_week"]
        rc, out, err = propose(d, f, "--points", "2", "--category", "alpha", "--queue-points", "20")
        if rc != 0 or out["basis"]["queue_mode"] != "points_ahead_over_velocity":
            return f"rc={rc} {out} {err[:160]}"
        got = out["basis"]["queue_hours"]["p50"]
        want = round(20 / rate["p50"] * 168, 3)
        return "" if abs(got - want) < 0.01 else f"fila {got}, esperado {want}"


def c_propose_started(d):
    with Fake() as f:
        rc, out, err = propose(d, f, "--issue", "SAC-51")
        if rc != 0 or out["basis"]["queue_mode"] != "already_started" or out["basis"]["queue_hours"]["p50"] != 0:
            return f"rc={rc} {out} {err[:160]}"
    return ""


def c_propose_insufficient(d):
    with Fake() as f:
        rc, out, err = propose(d, f, "--points", "3", "--category", "beta")
        if rc != 3 or out["proposal"] is not None or out["status"] != "insufficient_sample":
            return f"rc={rc} {out}"
        rc, out, err = propose(d, f, "--points", "3", "--category", "beta", "--queue-points", "20")  # a fila não pode suprir a calibração
        return "" if rc == 3 and out["proposal"] is None else f"com fila dada: rc={rc} {out}"


def c_propose_not_calibrated(d):
    with Fake() as f:
        rc, out, err = propose(d, f, "--points", "3", "--category", "maestro-act")
        return "" if rc == 3 and "não calibra" in out["reason"] else f"rc={rc} {out}"


def c_propose_no_points(d):
    with Fake() as f:
        rc, out, err = propose(d, f, "--issue", "SAC-71")
        return "" if rc == 3 and "sem pontos" in out["reason"] else f"rc={rc} {out}"


def c_propose_usage(d):
    with Fake() as f:
        rc, _, err = propose(d, f, "--points", "3")
        if rc != 2:
            return f"rc={rc}"
        rc, _, err = propose(d, f, "--issue", "SAC-51", "--points", "3")
        return "" if rc == 2 else f"rc={rc}"


def c_read_only(d):
    with Fake() as f:
        report(d, f)
        propose(d, f, "--points", "8", "--category", "alpha")
        return f"medidor escreveu: {f.writes()}" if f.writes() else ""


# ── amostra cega ─────────────────────────────────────────────────────────────
def sample(d, f, m, *args):
    a, b = os.path.join(m.tmp, "s.json"), os.path.join(m.tmp, "m.json")
    r = m.run(f, "blind-sample", "--out", a, "--map", b, *args)
    return r, a, b


def c_blind_no_leak(d):
    with Fake() as f, Meter(d) as m:
        (rc, out, err), a, b = sample(d, f, m)
        if rc != 0:
            return f"rc={rc} {err[:160]}"
        doc = json.load(open(a, encoding="utf-8"))
        target = [i for i in doc["issues"] if "alpha revisão" in i["title"]]
        if not target:
            return "issue com vazamento ficou fora da amostra"
        text = target[0]["title"] + "\n" + target[0]["description"]
        leaks = [x for x in FORBIDDEN if x in text]
        return f"vazou {leaks}: {text[:200]}" if leaks else ""


def c_blind_shape(d):
    with Fake() as f, Meter(d) as m:
        (rc, out, err), a, b = sample(d, f, m)
        doc = json.load(open(a, encoding="utf-8"))
        keys = {tuple(sorted(i)) for i in doc["issues"]}
        if keys != {("category", "description", "id", "title")}:
            return f"chaves: {keys}"
        raw = open(a, encoding="utf-8").read()
        if "SAC-" in raw or not all(i["id"].startswith("op-") for i in doc["issues"]):
            return "identificador real na amostra"
        mapping = json.load(open(b, encoding="utf-8"))
        return "" if set(mapping) == {i["id"] for i in doc["issues"]} and all(v["identifier"].startswith("SAC-") for v in mapping.values()) else "mapa incoerente"


def c_blind_eligibility(d):
    with Fake() as f, Meter(d) as m:
        (rc, out, err), a, b = sample(d, f, m)
        mapped = {v["identifier"] for v in json.load(open(b, encoding="utf-8")).values()}
        wrong = mapped & {"SAC-30", "SAC-31", "SAC-32", "SAC-35", "SAC-37"}
        return f"sem relógio/não calibra na amostra: {wrong}" if wrong else ""


def c_blind_stratified(d):
    with Fake() as f, Meter(d) as m:
        (rc, out, err), a, b = sample(d, f, m, "--target", "14")
        bad = {c: n for c, n in out["per_category"].items() if n < min(3, out["population"][c])}
        return f"abaixo do piso: {bad}" if bad or rc != 0 else ""


def c_blind_deterministic(d):
    with Fake() as f, Meter(d) as m:
        (_, _, _), a, b = sample(d, f, m, "--target", "14")
        first = open(a, encoding="utf-8").read()
        (_, _, _), a, b = sample(d, f, m, "--target", "14")
        return "" if first == open(a, encoding="utf-8").read() else "semente não reproduz"


def c_blind_refuses_repo(d):
    with Fake() as f, Meter(d) as m:
        subprocess.run(["git", "init", "-q", m.tmp], check=True)
        rc, _, err = parse(m.raw(f, "blind-sample", "--categories", m.rules, "--out", os.path.join(m.tmp, "a.json"), "--map", "/tmp/velocity-bench-map.json"))
        return "" if rc == 2 and "repositório" in err and not os.path.exists(os.path.join(m.tmp, "a.json")) else f"rc={rc} {err[:160]}"


def c_blind_same_path(d):
    with Fake() as f, Meter(d) as m:
        p = os.path.join(m.tmp, "a.json")
        rc, _, err = m.run(f, "blind-sample", "--out", p, "--map", p)
        return "" if rc == 2 and "diferentes" in err else f"rc={rc} {err[:160]}"


CASES = [
    ("caps", "--capabilities lista os verbos novos", c_caps),
    ("e-write", "estimate.points grava e devolve", c_estimate_write),
    ("e-noop", "provedor que ignora a escrita vira erro", c_estimate_noop),
    ("e-scale", "valor fora da escala não vai à mutação", c_estimate_out_of_scale),
    ("e-ext-off", "13 recusado sem escala estendida", c_estimate_extended_off),
    ("e-ext-on", "21 aceito com escala estendida", c_estimate_extended_on),
    ("e-off", "time com estimativa desligada é erro", c_estimate_not_used),
    ("e-clear", "--clear manda null", c_estimate_clear),
    ("e-bad", "valor não inteiro recusado sem rede", c_estimate_bad_value),
    ("usage", "uso errado sai rc 2 sem rede", c_usage),
    ("p-read", "estimate.points_read devolve pontos e escala", c_points_read),
    ("d-write", "due_date.set grava", c_due_write),
    ("d-noop", "provedor que ignora o prazo vira erro", c_due_noop),
    ("d-bad", "data inválida recusada sem rede", c_due_bad_date),
    ("d-clear", "due_date.set --clear", c_due_clear),
    ("f-read", "item.read traz estimate e carimbos", c_read_fields),
    ("f-list", "item.list traz os campos, sem descrição por padrão", c_list_fields),
    ("f-desc", "--with-description traz a descrição", c_list_with_description),
    ("f-proj", "--project filtra pelo id resolvido", c_list_project),
    ("r-sep", "fila e trabalho saem separados", c_queue_work_separate),
    ("r-excl", "cada exclusão é nomeada e contada", c_exclusions),
    ("r-sample", "amostra declarada e aviso por nível", c_sample_warning),
    ("r-loo", "erro por leave-one-out", c_loo_error),
    ("r-rho", "spearman pontos contra horas", c_spearman),
    ("r-dead", "prazo do campo e do título", c_title_deadline),
    ("r-win", "--window usa as mais recentes", c_window),
    ("r-over", "overlay simula sem escrever", c_overlay),
    ("r-other", "título sem regra é listado", c_other_listed),
    ("r-norules", "sem regras, avisa e não inventa categoria", c_no_rules),
    ("r-trunc", "lista truncada não vira medição", c_truncated),
    ("r-gap", "provider sem verbo é rc 2 nomeado", c_provider_gap),
    ("r-badcat", "regex inválida é rc 2", c_bad_categories),
    ("p-hist", "data com faixa pela fila da categoria", c_propose_history),
    ("p-ahead", "data por pontos à frente sobre velocidade", c_propose_ahead),
    ("p-started", "issue já iniciada não tem fila", c_propose_started),
    ("p-insuf", "amostra insuficiente: rc 3 e sem data", c_propose_insufficient),
    ("p-nocal", "categoria não calibrada: rc 3", c_propose_not_calibrated),
    ("p-nopts", "issue sem pontos: rc 3", c_propose_no_points),
    ("p-usage", "uso errado do propose", c_propose_usage),
    ("ro", "medidor nunca escreve", c_read_only),
    ("b-leak", "amostra sem data, duração, referência", c_blind_no_leak),
    ("b-shape", "só quatro chaves, id opaco, mapa separado", c_blind_shape),
    ("b-elig", "só entra quem tem relógio e calibra", c_blind_eligibility),
    ("b-strat", "piso por categoria", c_blind_stratified),
    ("b-det", "mesma semente, mesma amostra", c_blind_deterministic),
    ("b-repo", "recusa escrever dentro de repo git", c_blind_refuses_repo),
    ("b-same", "recusa amostra e mapa no mesmo arquivo", c_blind_same_path),
]

L = "adapters/linear.py"
V = "velocity-meter.py"
MUTANTS = [
    (L, '    if updated.get("estimate") != points:', "    if False:", "e-noop"),
    (L, '    if points is not None and points not in scale["values"]:', "    if False:", "e-scale"),
    (L, 'base + (extended if team.get("issueEstimationExtended") else [])', "base + extended", "e-ext-off"),
    (L, '    "fibonacci": ([1, 2, 3, 5, 8], [13, 21]),', '    "fibonacci": ([1, 2, 3, 5, 8], [13]),', "e-ext-on"),
    (L, '    if kind == "notUsed" or kind is None:', "    if False:", "e-off"),
    (L, '_issue_update(iss["id"], {"estimate": points})', '_issue_update(iss["id"], {"estimate": points or 0})', "e-clear"),
    (L, '    if raw is not None and not re.match(r"^\\d+$", raw):', "    if False:", "e-bad"),
    (L, '    if len(args) != 2 or (args[1].startswith("-") and args[1] != "--clear") or args[0].startswith("-"):', "    if len(args) < 1:", "usage"),
    (L, 'return {"issue": iss["identifier"], "estimate": iss.get("estimate"), "scale"', 'return {"issue": iss["identifier"], "estimate": None, "scale"', "p-read"),
    (L, '    if updated.get("dueDate") != due:', "    if False:", "d-noop"),
    (L, '        datetime.date.fromisoformat(value)\n', "        pass\n", "d-bad"),
    (L, '        if not re.match(r"^\\d{4}-\\d{2}-\\d{2}$", value):\n            raise ValueError\n', "", "d-bad"),
    (L, '    due = None if raw is None else _calendar_date(raw)', '    due = "2026-01-01" if raw is None else _calendar_date(raw)', "d-clear"),
    (L, "  estimate startedAt completedAt canceledAt dueDate\n", "\n", "f-read"),
    (L, 'url priority estimate createdAt updatedAt startedAt completedAt canceledAt dueDate archivedAt "', 'url priority createdAt updatedAt archivedAt "', "f-list"),
    (L, 'description_field = "description " if with_description else ""', 'description_field = "description "', "f-list"),
    (L, 'description_field = "description " if with_description else ""', 'description_field = ""', "f-desc"),
    (L, '        flt["project"] = {"id": {"eq": _project(o["project"])["id"]}}', '        flt["project"] = {"id": {"eq": o["project"]}}', "f-proj"),
    (V, '                row["queue_h"] = hours(created, started)', '                row["queue_h"] = hours(created, row["completed"] or started)', "r-sep"),
    (V, '            row["exclusion"] = "rollup_parent"', "            pass", "r-excl"),
    (V, '            row["exclusion"] = "no_started_at"', '            continue', "r-excl"),
    (V, '                row["exclusion"] = "batch_closed"', "                pass", "r-excl"),
    (V, '            elif row["completed"] is None or row["completed"] < started:', "            elif False:", "r-excl"),
    (V, 'BATCH_CLOSE_SIZE = 3 ', "BATCH_CLOSE_SIZE = 4 ", "r-excl"),
    (V, 'MIN_SAMPLE = 5 ', "MIN_SAMPLE = 3 ", "r-sample"),
    (V, 'SMALL_SAMPLE = 15 ', "SMALL_SAMPLE = 6 ", "r-sample"),
    (V, "for j, (p, h) in enumerate(pairs) if j != k]", "for j, (p, h) in enumerate(pairs)]", "r-loo"),
    (V, "    cov = sum((a - mx) * (b - my) for a, b in zip(x, y))", "    cov = -sum((a - mx) * (b - my) for a, b in zip(x, y))", "r-rho"),
    (V, 'TITLE_DUE = re.compile(r"^\\s*\\[[^\\]]*·', 'TITLE_DUE = re.compile(r"^\\s*\\[XX[^\\]]*·', "r-dead"),
    (V, '    recent = members[:window]', "    recent = members", "r-win"),
    (V, '"points": overlay.get(i["identifier"], i.get("estimate"))', '"points": i.get("estimate")', "r-over"),
    (V, '    others = [r["title"] for r in rows if r["category"] == UNCATEGORIZED]', "    others = []", "r-other"),
    (V, '    if not rules:\n        warnings.append', "    if False:\n        warnings.append", "r-norules"),
    (V, '    if data.get("truncated"):', "    if False:", "r-trunc"),
    (V, '    missing = {"item.list", "estimate.points_read"} - verbs\n    if run.returncode != 0 or missing:', "    missing = set()\n    if False:", "r-gap"),
    (V, '                rules.append((parts[0], parts[1] == "yes", re.compile(parts[2], re.I)))', '                rules.append((parts[0], parts[1] == "yes", re.compile("x", re.I)))', "r-badcat"),
    (V, 'return {"status": "proposed", "proposal": {"due_date": date_for("p50")', 'return {"status": "proposed", "proposal": {"due_date": date_for("p25")', "p-hist"),
    (V, "lambda k: (base + dt.timedelta(hours=queue[k] + work[k]))", "lambda k: (base + dt.timedelta(hours=work[k]))", "p-hist"),
    (V, '"high": date_for("p75")', '"high": date_for("p50")', "p-hist"),
    (V, '"p50": ahead / rate["p50"] * 168', '"p50": ahead / rate["p75"] * 168', "p-ahead"),
    (V, '    if issue and issue.get("startedAt"):', "    if False:", "p-started"),
    (V, '    if hpp["n"] < MIN_SAMPLE:', "    if False:", "p-insuf"),
    (V, '    if not stats["calibrate"]:', "    if False:", "p-nocal"),
    (V, '        if not points:\n            return insufficient', "        if False:\n            return insufficient", "p-nopts"),
    (V, '    elif points is None or not category:', "    elif False:", "p-usage"),
    (V, '    return {"status": "proposed", "proposal"', '    tm("due_date.set", "SAC-70", date_for("p50"))\n    return {"status": "proposed", "proposal"', "ro"),
    (V, '        t = re.sub(r"^\\s*\\[[^\\]]*\\]\\s*", "", t)', "        pass", "b-leak"),
    (V, '        t = "\\n".join(line for line in t.splitlines() if not _SCRUB_LINES.search(line))', "        pass", "b-leak"),
    (V, '    (re.compile(r"\\b[A-Z]{2,}-\\d+\\b"), "[ref]"),\n', "", "b-leak"),
    (V, '    (re.compile(r"\\b20\\d{2}\\b"), "[date]"),\n', "", "b-leak"),
    (V, '    (re.compile(r"(?i)\\b\\d+\\s+rodadas?\\b"), "[count]"),\n', "", "b-leak"),
    (V, '    (re.compile(r"\\b\\d{1,2}/\\d{1,2}(?:/\\d{2,4})?\\b"), "[date]"),\n', "", "b-leak"),
    (V, '    (re.compile(r"(?i)\\b(?:hoje|ontem|amanh[aã]|anteontem)\\b"), "[date]"),\n', "", "b-leak"),
    (V, '    (re.compile(rf"(?i)~?\\b\\d+(?:[.,]\\d+)?\\s*(?:{_UNITS})\\b"), "[duration]"),\n', "", "b-leak"),
    (V, '    (re.compile(rf"(?i)\\b(?:{_WORD_NUM})\\s+(?:segundos?|minutos?|horas?|dias?|semanas?|meses|m[eê]s)\\b"), "[duration]"),\n', "", "b-leak"),
    (V, 'opaque = "op-" + hashlib.sha256(f"{seed}:{r[\'raw\'][\'id\']}".encode()).hexdigest()[:10]', 'opaque = r["id"]', "b-shape"),
    (V, 'if r["calibrate"] and r["work_h"] is not None:', 'if r["work_h"] is not None or not r["calibrate"]:', "b-elig"),
    (V, "alloc = {c: min(n, max(3, int(target * n / total))) for c, n in sizes.items()}", "alloc = {c: min(n, int(target * n / total)) for c, n in sizes.items()}", "b-strat"),
    (V, "    rng = random.Random(seed)", "    rng = random.Random()", "b-det"),
    (V, "        if inside_repo(p):", "        if False:", "b-repo"),
    (V, '    if os.path.realpath(out) == os.path.realpath(map_path):', "    if False:", "b-same"),
]


def copy_tree(dst):
    os.makedirs(os.path.join(dst, "adapters"))
    for n in ("tm.sh", "env-check.sh", "velocity-meter.py"):
        shutil.copy2(os.path.join(TM_DIR, n), os.path.join(dst, n))
    shutil.copy2(os.path.join(TM_DIR, L), os.path.join(dst, L))


def guarded(fn, d):
    """Mutante que derruba o caso conta como reprovação do caso, não como queda da bancada."""
    try:
        return fn(d)
    except Exception as e:  # noqa: BLE001
        return f"exceção {type(e).__name__}: {e}"


def main():
    fails, oks, killed = [], 0, 0
    by_id = {c[0]: c for c in CASES}
    with tempfile.TemporaryDirectory(prefix="tm-velocity-bench-") as tmp:
        for cid, desc, fn in CASES:
            why = guarded(fn, TM_DIR)
            if why:
                fails.append(f"({cid}) {desc}: {why}")
            else:
                oks += 1
                print(f"ok   ({cid}) {desc}")
        cp = os.path.join(tmp, "copy")
        copy_tree(cp)
        targets = sorted({m[3] for m in MUTANTS})
        clean_bad = [f"({c}) {guarded(by_id[c][2], cp)}" for c in targets if guarded(by_id[c][2], cp)]
        if clean_bad:
            fails.append("cópia limpa NÃO ficou verde no arranjo dos mutantes — nenhum mutante conta: " + "; ".join(clean_bad))
        else:
            print(f"ok   cópia limpa verde nos {len(targets)} casos-alvo dos mutantes")
        for rel, old, new, want in MUTANTS:
            path = os.path.join(cp, rel)
            with open(path, encoding="utf-8") as fh:
                src = fh.read()
            if src.count(old) != 1:
                fails.append(f"mutante não aplicou (âncora {src.count(old)}×): {old[:60]!r} → ({want})")
                continue
            with open(path, "w", encoding="utf-8") as fh:
                fh.write(src.replace(old, new))
            why = guarded(by_id[want][2], cp)
            with open(path, "w", encoding="utf-8") as fh:
                fh.write(src)
            if why and not clean_bad:
                killed += 1
                print(f"ok   mutante morde → ({want}) [{' '.join(old.split())[:60]}]: {' '.join(str(why).split())[:100]}")
            elif not clean_bad:
                fails.append(f"mutante NÃO morde: ({want}) segue verde com a cura revertida: {' '.join(old.split())[:70]}")
    if fails:
        print("\nFALHA (%d):\n- %s" % (len(fails), "\n- ".join(fails)))
    print(f"\ntask-manager-velocity-bench: {oks}/{len(CASES)} caso(s) verdes; {killed}/{len(MUTANTS)} mutante(s) mordem; "
          f"cópia limpa {'verde' if not clean_bad else 'VERMELHA'}")
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
