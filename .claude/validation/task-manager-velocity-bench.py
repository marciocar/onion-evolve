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
import importlib.util
import json
import math
import os
import random
import shutil
import subprocess
import sys
import tempfile
import threading
import time

ROOT = (sys.argv[1] if len(sys.argv) > 1 else
        subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True, text=True).stdout.strip() or os.getcwd())
TM_DIR = os.path.join(ROOT, ".claude/utils/task-manager")
NOW = "2026-11-20T00:00:00-03:00"
NOW_H = 459  # horas de BASE até NOW
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
inverso\tyes\tinverso
errado\tyes\terrado
plano\tyes\tplano
drift\tyes\tdrift
curto\tyes\tcurto
ruido\tyes\truido
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
            "team": {"id": "team-sac", "key": "SAC", "name": "Core Team"}, "project": {"id": "proj-1", "name": "Core"},
            "parent": {"id": f"uuid-{parent}", "identifier": f"SAC-{parent}", "title": "mae"} if parent else None,
            "assignee": None, "labels": {"nodes": []}}


LAMBDA_POINTS = [1, 2, 3, 5, 8, 13] * 2 + [1, 2, 3, 5]
LAMBDA_WORK = [p * r * (1 + k / 100) for k, (p, r) in enumerate(zip(LAMBDA_POINTS, [2, 1.5, 7 / 3, 1.8, 2.25, 25 / 13] * 3))]
LAMBDA_QUEUE = ([60, 50, 40, 30, 20, 10] * 3)[:16]


def conformal_k(n, q):
    return min(math.ceil((n + 1) * q), n)


def expected_hours(points, q):
    totals = sorted(a + points * w / p for a, w, p in zip(LAMBDA_QUEUE, LAMBDA_WORK, LAMBDA_POINTS))
    return totals[conformal_k(len(totals), q) - 1]


def date_after(hours_from_now, now=NOW):
    start = dt.datetime.fromisoformat(now)
    return (start + dt.timedelta(hours=hours_from_now)).date().isoformat()


def drift_population():
    """Fila cresce a cada issue e cada uma fecha antes da próxima nascer: o corte temporal nunca a cobre."""
    return [issue(200 + k, f"drift {k}", created=-90000 + 3000 * k, queue=10 * (k + 1) ** 2, work=2 * p, est=p)
            for k, p in enumerate([1, 2, 3, 5, 8, 13] * 3)]


def lambda_population():
    """Pontos ordenam a duração, fila anticorrelacionada, e cada uma fecha antes da próxima nascer."""
    return [issue(1200 + k, f"lambda {k}", created=NOW_H - 4000 + 240 * k, queue=LAMBDA_QUEUE[k], work=LAMBDA_WORK[k], est=pts) for k, pts in enumerate(LAMBDA_POINTS)]


def partial_drift_population():
    """Estável e depois cada issue pior que todas: a categoria reprova, mas pode sumir na média do time."""
    pts = ([1, 2, 3, 5, 8, 13] * 3)[:16]
    return [issue(300 + k, f"drift {k}", created=-90000 + 3000 * k, queue=10 if k < 12 else 10 * 5 ** (k - 11), work=2 * p, est=p) for k, p in enumerate(pts)]


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
    rows += lambda_population()
    for k, (pts, w) in enumerate(zip([1, 2, 3, 5, 8, 13], [2, 4, 6, 10, 16, 26])):   # curto: sinal bom, nenhuma fechou antes de a outra nascer
        rows.append(issue(1400 + k, f"curto {k}", created=380 + k, queue=1, work=w, est=pts))
    for k, (pts, w) in enumerate(zip([1, 2, 3, 5, 8, 13], [2, 4, 7, 5, 16, 20])):    # ruido: ordena bem por acaso, a permutação não sustenta
        rows.append(issue(1450 + k, f"ruido {k}", created=-3000 + 3 * k, queue=1, work=w, est=pts))
    for name, works, base_h in (("inverso", [80, 60, 40, 30, 10, 5], 100), ("errado", [0.1, 20, 0.5, 40, 3, 90], 110), ("plano", [10, 10.1, 10.2, 10.3, 10.4, 10.5], 120)):
        for k, pts in enumerate([1, 2, 3, 5, 8, 13]):
            rows.append(issue(1000 + base_h + k, f"{name} {k}", created=-2000 - base_h * 20 + 7 * k, queue=1 + k * 0.1, work=works[k], est=pts))
    rows.append(issue(60, "sem regra nenhuma", created=420, queue=1, work=2, est=1))
    rows.append(issue(50, "alpha aberta sem pontos", created=430, state=("Todo", "unstarted")))
    rows.append(issue(51, "alpha em andamento", created=431, queue=1, est=3, state=("In Progress", "started")))
    rows.append(issue(70, "alpha issue de escrita", created=432, state=("Todo", "unstarted"), est=None))
    rows.append(issue(71, "sem pontos", created=433, state=("Todo", "unstarted"), est=None))
    rows.append(issue(80, "lambda aberta nova", created=NOW_H, state=("Todo", "unstarted"), est=8))
    rows.append(issue(81, "lambda iniciada agora", created=NOW_H - 10, queue=8, est=3, state=("In Progress", "started")))
    rows.append(issue(82, "lambda iniciada há um mês", created=NOW_H - 800, queue=80, est=3, state=("In Progress", "started")))
    rows.append(issue(83, "lambda velha na fila", created=NOW_H - 1400, state=("Todo", "unstarted"), est=3))
    rows.append(issue(84, "lambda cancelada", created=430, state=("Canceled", "canceled"), est=3))
    mother = issue(85, "lambda mãe", created=431, state=("Todo", "unstarted"), est=13)
    mother["children"] = {"nodes": [{"identifier": "SAC-86", "state": {"type": "started"}}]}
    rows.append(mother)
    closed_mother = issue(87, "lambda mãe de filhas fechadas", created=NOW_H, state=("Todo", "unstarted"), est=8)
    closed_mother["children"] = {"nodes": [{"identifier": "SAC-88", "state": {"type": "completed"}}]}
    rows.append(closed_mother)
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
        if s["force"] == "hang":
            time.sleep(2.5)
            return None
        if s["force"] == "gone":
            return self._errors("Entity not found: Issue")
        if "issueUpdate" in q:
            row = find(s, v["id"])
            if s["force"] == "update_lies":
                return self._reply({"data": {"issueUpdate": {"success": True, "issue": {**row, **v["in"]}}}})
            if s["force"] != "update_noop":
                row.update(v["in"])
            if s["force"] == "reread_gone":
                s["force"] = "gone"
            return self._reply({"data": {"issueUpdate": {"success": True, "issue": row}}})
        if "issues(" in q:
            rows = s["issues"] if v.get("arch") else [r for r in s["issues"] if not r["archivedAt"]]
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
    def __init__(self, force=None, team=None, rows=None):
        self.force, self.team, self.rows = force, team, rows

    def __enter__(self):
        self.store = seed()
        if self.rows is not None:
            self.store["issues"] = self.rows
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
    env = {k: v for k, v in os.environ.items() if not k.startswith(("LINEAR_", "TM_", "CLICKUP_", "ZOHO_", "JIRA_", "ASANA_", "TASK_MANAGER"))}  # chaves de linear, clickup, zoho, jira e asana fora
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


def tm(d, fake, *args, extra=None):
    return parse(subprocess.run(["bash", os.path.join(d, "tm.sh"), *args], capture_output=True, text=True, env=env_for(fake, extra=extra), timeout=20, cwd=d))


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

    def run(self, fake, cmd, *args, now=NOW, **kw):
        return parse(self.raw(fake, cmd, "--categories", self.rules, "--now", now, *args, **kw))


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
        return "" if rc == 1 and out is None and "releitura" in err and "estimate=None" in err else f"rc={rc} {out} {err[:120]}"


def c_estimate_lies(d):
    # o retorno da mutação diz que gravou; só a leitura separada mostra que não
    with Fake("update_lies") as f:
        rc, out, err = tm(d, f, "estimate.points", "SAC-70", "5")
        return "" if rc == 1 and out is None and "releitura" in err else f"rc={rc} {out} {err[:120]}"


def c_due_lies(d):
    with Fake("update_lies") as f:
        rc, out, err = tm(d, f, "due_date.set", "SAC-70", "2026-11-30")
        return "" if rc == 1 and out is None and "releitura" in err else f"rc={rc} {out} {err[:120]}"


def c_reread_fails(d):
    with Fake("reread_gone") as f:
        rc, out, err = tm(d, f, "estimate.points", "SAC-70", "5")
        return "" if rc == 1 and out is None and "a releitura falhou" in err and "Traceback" not in err else f"rc={rc} {out} {err[:160]}"


def c_timeout(d):
    with Fake("hang") as f:
        rc, out, err = tm(d, f, "estimate.points_read", "SAC-70", extra={"TM_LINEAR_TIMEOUT": "1"})
        return "" if rc == 1 and out is None and "tempo esgotado" in err and "Traceback" not in err else f"rc={rc} {out} {err[:200]}"


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
        for v in ("abc", "1.5", "٣", "5\n"):
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
        return "" if rc == 1 and "releitura" in err else f"rc={rc} {err[:120]}"


def c_due_bad_date(d):
    with Fake() as f:
        for v in ("2026-02-30", "30/11", "2026-11-30T10:00", "20261130", "٢٠٢٦-١١-٣٠", "2026-11-30\n"):
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
    rows = [issue(1 + k, f"lambda {k}", created=10 * k, queue=1, work=2 * p + k, est=p) for k, p in enumerate([1, 2, 3, 5, 8, 13])]
    with Fake(rows=rows) as f:
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
        rc, out, err = parse(m.raw(f, "report", "--now", NOW))
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


# ── medidor: recortes em população própria ────────────────────────────────
def c_velocity_exact(d):
    h = NOW_H
    rows = [issue(1, "theta feita", created=h - 30, queue=1, work=2, est=3), issue(2, "theta mãe", created=h - 40, queue=1, work=3, est=8),
            issue(3, "theta filha", created=h - 45, queue=1, work=4, est=2, parent=2), issue(4, "[maestro · 12/11] ato", created=h - 50, queue=1, work=1, est=13),
            issue(5, "theta na borda", created=-888 - 3, queue=1, work=2, est=5), issue(6, "theta dentro", created=-864, queue=1, work=2, est=2)]
    rows[4]["completedAt"] = "2026-09-25T15:00:00.000Z"
    with Fake(rows=rows) as f:
        _, out, err = report(d, f)
        v = out["team_velocity"]
        return "" if v["points_completed"] == 7 and v["issues_completed"] == 3 and v["points_per_week"] == 0.875 and v["weeks_with_points"] >= 2 else f"velocidade: {v}"


def c_archived_counted(d):
    with Fake() as f:
        f.store["issues"][0]["archivedAt"] = "2026-11-02T00:00:00.000Z"
        _, out, err = report(d, f)
        return "" if cat(out, "alpha")["completed"] == 6 else f"arquivada sumiu: {cat(out, 'alpha')['completed']}"


def c_batch_chain(d):
    rows = [issue(1 + k, f"zeta {k}", created=100, queue=1, completed_at=110 + k / 3600) for k in range(3)]
    rows += [issue(10 + k, f"iota {k}", created=150, queue=1, completed_at=160 + k / 100) for k in range(3)]
    rows += [issue(5, "theta par", created=200, queue=1, completed_at=210), issue(6, "theta par 2", created=200, queue=1, completed_at=210 + 1 / 3600)]
    rows[1]["completedAt"], rows[2]["completedAt"] = "2026-11-05T14:01:00.000Z", "2026-11-05T14:01:01.000Z"
    rows[0]["completedAt"] = "2026-11-05T14:00:59.000Z"
    rows[3]["completedAt"], rows[4]["completedAt"], rows[5]["completedAt"] = "2026-11-06T14:00:20.000Z", "2026-11-06T14:00:50.000Z", "2026-11-06T14:01:20.000Z"
    with Fake(rows=rows) as f:
        _, out, err = report(d, f)
        if cat(out, "zeta")["excluded"].get("batch_closed") != 3:
            return f"cadeia que cruza o minuto: {cat(out, 'zeta')['excluded']}"
        if cat(out, "iota")["excluded"].get("batch_closed") != 3:
            return f"cadeia de 30 s: {cat(out, 'iota')['excluded']}"
        return "" if "batch_closed" not in cat(out, "theta")["excluded"] else "par virou lote"


def c_spearman_small(d):
    rows = [issue(1 + k, f"lambda {k}", created=10 * k, queue=1, work=k + 1, est=k + 1) for k in range(4)]
    with Fake(rows=rows) as f:
        _, out, err = report(d, f)
        r = cat(out, "lambda")["points_vs_hours_spearman"]
        return "" if r is None else f"spearman com n=4: {r}"


def c_negative_queue(d):
    rows = [issue(1, "theta", created=100, queue=-5, work=20, est=2)]
    with Fake(rows=rows) as f:
        _, out, err = report(d, f)
        return "" if cat(out, "theta")["queue_hours"]["n"] == 0 else f"fila negativa: {cat(out, 'theta')['queue_hours']}"


def c_zero_clock(d):
    rows = [issue(1, "theta", created=100, queue=1, work=0, est=2)]
    with Fake(rows=rows) as f:
        _, out, err = report(d, f)
        return "" if cat(out, "theta")["excluded"].get("negative_clock") == 1 else f"{cat(out, 'theta')['excluded']}"


def c_title_forms(d):
    rows = [issue(1, "[core · depois de 09/11] iota", created=100, queue=1, work=2), issue(2, "[core · 29/02] iota", created=110, queue=1, work=2),
            issue(3, "[core · seg 09/11] iota", created=120, queue=1, work=2)]
    with Fake(rows=rows) as f:
        rc, out, err = report(d, f)
        if rc != 0:
            return f"rc={rc} {err[:160]}"
        return "" if cat(out, "iota")["deadline"]["n"] == 1 else f"{cat(out, 'iota')['deadline']}"


def c_timezone(d):
    rows = [issue(1, "theta", created=100, queue=1, work=2, due="2026-11-10")]
    rows[0]["completedAt"] = "2026-11-11T01:30:00.000Z"
    with Fake(rows=rows) as f:
        _, out, err = report(d, f)
        local = out["deadline"]["median_slip_days"]
        _, out, err = report(d, f, "--utc-offset", "0")
        return "" if local == 0 and out["deadline"]["median_slip_days"] == 1 else f"local {local}, utc {out['deadline']['median_slip_days']}"


def c_real_clock(d):
    with Fake() as f, Meter(d) as m:
        rc, out, err = parse(m.raw(f, "report", "--categories", m.rules))
        today = dt.datetime.now(dt.timezone(dt.timedelta(hours=-3))).date().isoformat()
        return "" if rc == 0 and out["generated_for"] == today else f"{out and out['generated_for']} != {today}"


def c_real_time_of_day(d):
    with Fake() as f, Meter(d) as m:
        rc, out, err = parse(m.raw(f, "report", "--categories", m.rules))
        at = dt.datetime.fromisoformat(out["generated_at"])
        skew = abs((dt.datetime.now(dt.timezone.utc) - at).total_seconds())
        return "" if skew < 300 else f"generated_at a {skew:.0f} s do relógio real"


def c_temporal_no_leak(d):
    rows = [issue(1 + k, f"theta {k}", created=1000 * k, queue=0.5, work=0.5) for k in range(4)]
    rows.append(issue(5, "theta longa", created=4000, queue=1, completed_at=9000))
    rows.append(issue(6, "theta depois", created=5000, queue=0.5, work=0.5))
    rows.append(issue(7, "theta final", created=9100, queue=0.5, work=0.5))
    with Fake(rows=rows) as f:
        _, out, err = report(d, f)
        n = out["backtest"]["temporal"]["history_only"]["n"]
        return "" if n == 1 else f"temporal usou quem ainda não tinha fechado: n={n}"


def censored_rows():
    rows = [issue(1 + k, f"alpha {k}", created=10 * k, queue=q, work=1) for k, q in enumerate([9, 19, 29, 39, 49, 59])]
    rows.append(issue(7, "alpha sem início", created=100, completed_at=300))
    rows.append(issue(8, "alpha aberta velha", created=NOW_H - 100, state=("Todo", "unstarted")))
    rows.append(issue(9, "alpha aberta nova", created=NOW_H - 1, state=("Todo", "unstarted")))
    return rows


def c_coverage_with_open(d):
    with Fake(rows=censored_rows()) as f:
        _, out, err = report(d, f)
        got = out["backtest"]["loo"]["history_only"]["with_open"]
        want = {"completed_hit": 5, "completed_miss": 2, "open_overdue": 1, "open_on_time": 1, "coverage_counting_overdue_open": 0.625, "coverage_open_on_time_as_hit": 0.667}
        return "" if got == want else f"{got}"


def c_coverage_temporal_filter(d):
    with Fake(rows=censored_rows()) as f:
        _, out, err = report(d, f)
        got = out["backtest"]["temporal"]["history_only"]["with_open"]
        return "" if got["completed_hit"] + got["completed_miss"] <= 3 else f"temporal julgou {got}"


def c_bias_in_limits(d):
    with Fake(rows=censored_rows()) as f:
        _, out, err = report(d, f)
        text = " ".join(out["limits"])
        return "" if "viés de sobrevivente" in text and "0.625" in text and "0.667" in text else text[-300:]


def c_not_measured_text(d):
    with Fake(rows=six_distinct()) as f, Meter(d) as m:
        p = m.raw(f, "report", "--categories", m.rules, "--now", NOW, "--text")
        return "" if p.returncode == 0 and "temporal/history_only: não medido (n=0, mínimo 10)" in p.stdout else p.stdout[-400:]


def c_bracket_stripped(d):
    rows = [issue(1, "[alpha · 11/11] beta item", created=100, queue=1, work=2), issue(2, "[maestro · 11/11] alpha", created=110)]
    with Fake(rows=rows) as f:
        _, out, err = report(d, f)
        got = {c["category"] for c in out["categories"]}
        return "" if got == {"beta", "maestro-act"} else f"{got}"


def c_large_other_open(d):
    rows = [issue(1, "alpha", created=100, queue=1, work=2)] + [issue(2 + k, f"sem regra {k}", created=120, state=("Todo", "unstarted")) for k in range(3)]
    with Fake(rows=rows) as f:
        _, out, err = report(d, f)
        codes = [w["message"] for w in out["warnings"] if w["code"] == "large_other"]
        return "" if any("abertas" in x for x in codes) and out["open"]["other"] == 3 else f"{codes} {out['open']}"


def c_backtest_per_issue_sum(d):
    # fila e trabalho anticorrelacionados: somar por issue dá total quase constante; somar marginais ordenadas, não
    rows = [issue(1 + k, f"lambda {k}", created=10 * k, queue=q, work=w, est=2) for k, (q, w) in enumerate([(100, 1), (80, 21), (60, 41), (40, 61), (20, 81), (1, 100), (70, 70)])]
    with Fake(rows=rows) as f:
        _, out, err = report(d, f)
        b = out["backtest"]["loo"]["with_points"]["per_category"]["lambda"]
        return "" if b["n"] == 7 and b["covered_by_due"] == 6 and b["inside_band"] == 6 else f"{b}"


def c_survivors_declared(d):
    with Fake() as f:
        _, out, err = report(d, f)
        pop = out["calibration_population"]
        codes = [w["code"] for w in out["warnings"]]
        return "" if pop["without_started_at"] >= 1 and pop["with_work_clock"] < pop["completed"] and "survivors_only" in codes else f"{pop} {codes}"


def c_overlay_declared(d):
    with Fake() as f, Meter(d) as m:
        path = os.path.join(m.tmp, "o.json")
        with open(path, "w", encoding="utf-8") as fh:
            json.dump({"SAC-1200": 1}, fh)
        for category, want_rc in (("lambda", 0), ("beta", 3)):
            rc, out, err = m.run(f, "propose", "--points", "8", "--category", category, "--estimates-overlay", path)
            if rc != want_rc or out.get("estimates_overlay", {}).get("entries") != 1:
                return f"{category}: rc={rc} {out}"
        rc, out, err = m.run(f, "propose", "--points", "8", "--category", "lambda")
        return "" if "estimates_overlay" not in out else "overlay declarado sem overlay"


def six_distinct():
    return [issue(1 + k, f"lambda {k}", created=10 * k, queue=q, work=w, est=2) for k, (q, w) in enumerate([(60, 2), (50, 3), (40, 7), (30, 9), (20, 18), (10, 25)])]


def c_backtest_published(d):
    with Fake(rows=six_distinct()) as f:
        _, out, err = report(d, f)
        loo = out["backtest"]["loo"]["history_only"]["per_category"]["lambda"]
        return "" if loo == {"n": 6, "covered_by_due": 5, "inside_band": 3} else f"{loo}"


# ── medidor: data proposta ───────────────────────────────────────────────────
def propose(d, f, *args, **kw):
    with Meter(d) as m:
        return m.run(f, "propose", *args, **kw)


def c_propose_history(d):
    with Fake() as f:
        rc, out, err = propose(d, f, "--points", "8", "--category", "lambda")
        if rc != 0:
            return f"rc={rc} {out} {err[:160]}"
        p, want = out["proposal"], {k: date_after(expected_hours(8, q)) for k, q in (("low", .25), ("likely", .5), ("due", .8), ("high", .9))}
        if p["due_date"] != want["due"] or p["likely"] != want["likely"] or p["range"]["low"] != want["low"] or p["range"]["high"] != want["high"]:
            return f"{p} esperado {want}"
        h = out["basis"]["hours_from_now"]
        if abs(h["due"] - expected_hours(8, .8)) > 0.01 or abs(h["likely"] - expected_hours(8, .5)) > 0.01:
            return f"horas {h}"
        if any(w["code"] == "points_extrapolation" for w in out["warnings"]):
            return "extrapolação avisada dentro da escala"
        if p["due_percentile"] != 80 or out["basis"]["sample_used"] != 16 or p["range"]["high_is_sample_max"] is not False:
            return f"declaração: {p} {out['basis']['sample_used']}"
    return ""


def c_propose_time_of_day(d):
    late = "2026-11-20T23:00:00-03:00"
    with Fake() as f:
        rc, out, err = propose(d, f, "--points", "8", "--category", "lambda", now=late)
        want = date_after(expected_hours(8, .8), now=late)
        return "" if rc == 0 and out["proposal"]["due_date"] == want else f"rc={rc} {out and out['proposal']} esperado {want}"


def c_propose_started(d):
    with Fake() as f:
        rc, out, err = propose(d, f, "--issue", "SAC-81")
        if rc != 0 or out["basis"]["mode"] != "work_remaining_after_start":
            return f"rc={rc} {out} {err[:160]}"
        if out["basis"]["elapsed_hours"] != 2:
            return f"decorrido: {out['basis']['elapsed_hours']}"
        rem = sorted(3 * w / p - 2 for w, p in zip(LAMBDA_WORK, LAMBDA_POINTS) if 3 * w / p > 2)
        got, want = out["basis"]["hours_from_now"]["due"], rem[conformal_k(len(rem), .8) - 1]
        return "" if abs(got - want) < 0.01 else f"restante {got}, esperado {want}"


def c_propose_new_issue(d):
    with Fake() as f:
        rc, out, err = propose(d, f, "--issue", "SAC-80")
        if rc != 0 or out["basis"]["mode"] != "empirical_queue_plus_work" or out["proposal"]["due_date"] != date_after(expected_hours(8, .8)):
            return f"rc={rc} {out} {err[:160]}"
    return ""


def c_propose_started_old(d):
    with Fake() as f:
        rc, out, err = propose(d, f, "--issue", "SAC-82")
        return "" if rc == 3 and out["status"] == "beyond_history" and out["proposal"] is None else f"rc={rc} {out}"


def c_propose_aged(d):
    with Fake() as f:
        rc, out, err = propose(d, f, "--issue", "SAC-83")
        work = sorted(3 * w / p for w, p in zip(LAMBDA_WORK, LAMBDA_POINTS))[conformal_k(16, .8) - 1]
        if rc != 3 or out["status"] != "beyond_history" or out["proposal"] is not None or "if_started_now" in out:
            return f"rc={rc} {out}"
        return "" if abs(out["work_hours_if_started_now"] - work) < 0.01 else f"horas {out['work_hours_if_started_now']}, esperado {work}"


def c_propose_closed(d):
    with Fake() as f:
        for ident in ("SAC-1", "SAC-84"):
            rc, out, err = propose(d, f, "--issue", ident)
            if rc != 3 or out["status"] != "not_applicable" or out["proposal"] is not None:
                return f"{ident}: rc={rc} {out}"
    return ""


def c_propose_parent(d):
    with Fake() as f:
        rc, out, err = propose(d, f, "--issue", "SAC-85")
        return "" if rc == 3 and out["status"] == "not_applicable" and out["open_children"] == ["SAC-86"] else f"rc={rc} {out}"


def c_propose_mother_closed(d):
    with Fake() as f:
        rc, out, err = propose(d, f, "--issue", "SAC-87")
        return "" if rc == 0 and out["status"] == "proposed" else f"rc={rc} {out}"


def c_extrapolation(d):
    with Fake() as f:
        rc, out, err = propose(d, f, "--points", "21", "--category", "lambda")
        return "" if rc == 0 and any(w["code"] == "points_extrapolation" for w in out["warnings"]) else f"rc={rc} {out and out['warnings']}"


def c_signal_noise(d):
    return signal_refused(d, "ruido", "not_significant")


def c_null_family_error(d):
    # pontos sorteados, independentes da duração: 8 categorias por sorteio, nenhuma calibração real por trás
    spec = importlib.util.spec_from_file_location("vm_bench", os.path.join(d, "velocity-meter.py"))
    vm = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(vm)
    trials, any_pass = 100, 0
    for t in range(trials):
        g = random.Random(t)
        for _ in range(8):
            pairs = [(g.choice([1, 2, 3, 5, 8, 13]), g.lognormvariate(0, 1.2)) for _ in range(9)]
            if vm.points_signal(pairs, vm.leave_one_out_error(pairs), 0.05 / 8, 8)["ok"]:
                any_pass += 1
                break
    return "" if any_pass <= 15 else f"falso positivo familiar {any_pass}/{trials}"


def signal_refused(d, category, reason):
    with Fake() as f:
        rc, out, err = propose(d, f, "--points", "3", "--category", category)
        return "" if rc == 3 and out["status"] == "no_points_signal" and out["signal"]["reason"] == reason else f"rc={rc} {out}"


def c_signal_no_variance(d):
    return signal_refused(d, "alpha", "points_without_variance")


def c_signal_inverse(d):
    return signal_refused(d, "inverso", "points_do_not_order_duration")


def c_signal_error(d):
    return signal_refused(d, "errado", "error_too_large")


def c_signal_baseline(d):
    return signal_refused(d, "plano", "worse_than_ignoring_points")


def c_miscalibrated(d):
    with Fake(rows=drift_population()) as f:
        rc, out, err = propose(d, f, "--points", "3", "--category", "drift")
        return "" if rc == 3 and out["status"] == "miscalibrated" and out["backtest"]["n"] >= 10 else f"rc={rc} {out}"


def c_not_measured(d):
    with Fake() as f:
        rc, out, err = propose(d, f, "--points", "3", "--category", "curto")
        return "" if rc == 3 and out["status"] == "calibration_not_measured" and out["proposal"] is None and out["backtest"]["n"] == 0 else f"rc={rc} {out}"


def c_gate_by_category(d):
    with Fake(rows=partial_drift_population() + lambda_population()) as f:
        _, rep_out, _ = report(d, f)
        team = rep_out["backtest"]["temporal"]["with_points"]["coverage_due"]
        if team is None or team < 0.7:
            return f"fixture: time cobre {team}, devia passar"
        rc, out, err = propose(d, f, "--points", "3", "--category", "drift")
        return "" if rc == 3 and out["status"] == "miscalibrated" else f"rc={rc} {out}"


def c_propose_insufficient(d):
    with Fake() as f:
        rc, out, err = propose(d, f, "--points", "3", "--category", "beta")
        return "" if rc == 3 and out["proposal"] is None and out["status"] == "insufficient_sample" else f"rc={rc} {out}"


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
        propose(d, f, "--points", "8", "--category", "lambda")
        return f"medidor escreveu: {f.writes()}" if f.writes() else ""


# ── amostra cega ─────────────────────────────────────────────────────────────
def sample(d, f, m, *args):
    a, b = os.path.join(m.tmp, "s.json"), os.path.join(m.tmp, "m.json")
    r = m.run(f, "blind-sample", "--out", a, "--map", b, *args)
    return r, a, b


def c_blind_no_leak(d):
    with Fake() as f, Meter(d) as m:
        (rc, out, err), a, b = sample(d, f, m, "--target", "500")
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


def c_blind_order(d):
    with Fake() as f, Meter(d) as m:
        (_, _, _), a, b = sample(d, f, m)
        ids = [i["id"] for i in json.load(open(a, encoding="utf-8"))["issues"]]
        return "" if ids == sorted(ids) else "ordem da amostra não é a do hash"


def c_blind_mode(d):
    with Fake() as f, Meter(d) as m:
        (_, _, _), a, b = sample(d, f, m)
        modes = {oct(os.stat(x).st_mode & 0o777) for x in (a, b)}
        return "" if modes == {"0o600"} else f"permissões {modes}"


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
    ("e-lie", "retorno da mutação mentindo: a leitura separada acusa", c_estimate_lies),
    ("d-lie", "prazo com retorno mentindo: a leitura separada acusa", c_due_lies),
    ("e-gone", "releitura que falha é rc 1 nomeado", c_reread_fails),
    ("net-to", "timeout de resposta é rc 1 com mensagem", c_timeout),
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
    ("r-vel", "velocidade: janela fechada, sem mãe e sem ato humano", c_velocity_exact),
    ("r-arch", "concluída arquivada entra no histórico", c_archived_counted),
    ("r-batch", "lote por cadeia, par não é lote", c_batch_chain),
    ("r-rho-n", "spearman exige amostra", c_spearman_small),
    ("r-negq", "fila negativa fica fora", c_negative_queue),
    ("r-zero", "relógio de duração zero fica fora", c_zero_clock),
    ("r-title", "'depois de' não é prazo; 29/02 não derruba", c_title_forms),
    ("r-tz", "prazo comparado no fuso local", c_timezone),
    ("r-now", "sem --now vale o relógio real", c_real_clock),
    ("r-brack", "colchete é dono, não trabalho; ato humano lê o cru", c_bracket_stripped),
    ("r-open", "large_other olha as abertas", c_large_other_open),
    ("r-bt", "backtest publicado com a conta certa", c_backtest_published),
    ("r-surv", "report declara que calibra só nas sobreviventes", c_survivors_declared),
    ("p-over", "propose declara o overlay, também na recusa", c_overlay_declared),
    ("r-hold", "backtest soma por issue", c_backtest_per_issue_sum),
    ("p-hist", "data P80 pela soma por issue, faixa declarada", c_propose_history),
    ("p-tod", "a conta parte do instante, não da meia-noite", c_propose_time_of_day),
    ("p-new", "issue nova: fila e trabalho", c_propose_new_issue),
    ("p-started", "iniciada: só o trabalho que resta", c_propose_started),
    ("p-old", "iniciada há mais que a história: rc 3", c_propose_started_old),
    ("p-aged", "velha na fila: rc 3 com data se iniciar agora", c_propose_aged),
    ("p-closed", "concluída e cancelada: rc 3", c_propose_closed),
    ("p-mother", "mãe de filhas abertas: rc 3", c_propose_parent),
    ("s-var", "pontos sem variação: rc 3", c_signal_no_variance),
    ("s-inv", "pontos inversos à duração: rc 3", c_signal_inverse),
    ("s-err", "erro alto: rc 3", c_signal_error),
    ("s-base", "pior que ignorar os pontos: rc 3", c_signal_baseline),
    ("s-drift", "backtest temporal abaixo do piso: rc 3", c_miscalibrated),
    ("s-small", "backtest temporal da categoria não medido: rc 3", c_not_measured),
    ("s-cat", "piso temporal julga a categoria, não o time", c_gate_by_category),
    ("s-noise", "ordem por acaso não passa na permutação", c_signal_noise),
    ("s-fp", "erro familiar sob pontos sorteados", c_null_family_error),
    ("p-mclosed", "mãe de filhas fechadas recebe data", c_propose_mother_closed),
    ("p-extra", "pontos fora do histórico são avisados", c_extrapolation),
    ("r-now2", "sem --now vale o instante, não a meia-noite", c_real_time_of_day),
    ("r-tleak", "corte temporal só usa quem já fechou", c_temporal_no_leak),
    ("r-open-c", "cobertura com as abertas e as sem relógio", c_coverage_with_open),
    ("r-open-t", "cobertura com abertas respeita o corte temporal", c_coverage_temporal_filter),
    ("r-bias", "tamanho do viés no limits", c_bias_in_limits),
    ("r-nm", "n abaixo do mínimo sai 'não medido'", c_not_measured_text),
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
    ("b-order", "ordem da amostra é a do hash", c_blind_order),
    ("b-mode", "amostra e mapa com 0600", c_blind_mode),
    ("b-repo", "recusa escrever dentro de repo git", c_blind_refuses_repo),
    ("b-same", "recusa amostra e mapa no mesmo arquivo", c_blind_same_path),
]

L = "adapters/linear.py"
V = "velocity-meter.py"
MUTANTS = [
    (L, '    if after.get(field) != value:', "    if False:", "e-noop"),
    (L, '        after = _issue(iss["identifier"])\n', '        after = {**iss, field: value}\n', "e-lie"),
    (L, '        after = _issue(iss["identifier"])\n', '        after = _issue_update(iss["id"], {field: value})\n', "d-lie"),
    (L, 'raise TmError(f"{iss[\'identifier\']}: escrita enviada e a releitura falhou ({e}); confira antes de repetir")', 'raise', "e-gone"),
    (L, '    except (TimeoutError, OSError, http.client.HTTPException) as e:', "    except ZeroDivisionError as e:", "net-to"),
    (L, '    if points is not None and points not in scale["values"]:', "    if False:", "e-scale"),
    (L, 'base + (extended if team.get("issueEstimationExtended") else [])', "base + extended", "e-ext-off"),
    (L, '    "fibonacci": ([1, 2, 3, 5, 8], [13, 21]),', '    "fibonacci": ([1, 2, 3, 5, 8], [13]),', "e-ext-on"),
    (L, '    if kind == "notUsed" or kind is None:', "    if False:", "e-off"),
    (L, '_verified_update(iss, "estimate", points)', '_verified_update(iss, "estimate", points or 0)', "e-clear"),
    (L, '    if raw is not None and not re.fullmatch(r"[0-9]+", raw):', "    if False:", "e-bad"),
    (L, '    if raw is not None and not re.fullmatch(r"[0-9]+", raw):', '    if raw is not None and not re.match(r"^\\d+$", raw):', "e-bad"),
    (L, '    if len(args) != 2 or (args[1].startswith("-") and args[1] != "--clear") or args[0].startswith("-"):', "    if len(args) < 1:", "usage"),
    (L, 'return {"issue": iss["identifier"], "estimate": iss.get("estimate"), "scale"', 'return {"issue": iss["identifier"], "estimate": None, "scale"', "p-read"),
    (L, '    if after.get(field) != value:', "    if False:", "d-noop"),
    (L, '        datetime.date.fromisoformat(value)\n', "        pass\n", "d-bad"),
    (L, '        if not re.fullmatch(r"[0-9]{4}-[0-9]{2}-[0-9]{2}", value):\n            raise ValueError\n', "", "d-bad"),
    # sem mutante \\d na data: date.fromisoformat recusa os mesmos valores, e o mutante seria equivalente
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
    (V, 'elif row["completed"] is None or row["completed"] <= started:', "elif False:", "r-excl"),
    (V, 'BATCH_CLOSE_SIZE = 3 ', "BATCH_CLOSE_SIZE = 2 ", "r-batch"),
    (V, 'BATCH_CLOSE_SIZE = 3 ', "BATCH_CLOSE_SIZE = 4 ", "r-excl"),
    (V, 'BATCH_CLOSE_SECONDS = 60 ', "BATCH_CLOSE_SECONDS = 1 ", "r-batch"),
    (V, 'MIN_SAMPLE = 5 ', "MIN_SAMPLE = 3 ", "r-sample"),
    (V, 'SMALL_SAMPLE = 15 ', "SMALL_SAMPLE = 6 ", "r-sample"),
    (V, "others = [h / p for j, (p, h) in enumerate(pairs) if j != k]", "others = [h / p for j, (p, h) in enumerate(pairs)]", "r-loo"),
    (V, "    cov = sum((a - mx) * (b - my) for a, b in zip(x, y))", "    cov = -sum((a - mx) * (b - my) for a, b in zip(x, y))", "r-rho"),
    (V, 'r"^\\s*\\[[^\\]]*·\\s*(?:(?:hoje', 'r"^\\s*\\[XX[^\\]]*·\\s*(?:(?:hoje', "r-dead"),
    (V, '(?:(?:hoje|seg|ter|qua|qui|sex|s[áa]b|dom)\\s+)?(\\d{1,2})', '(?:[^\\]]*\\s+)?(\\d{1,2})', "r-title"),
    (V, '            due = dt.date(year, int(m.group(2)), int(m.group(1)))\n        except ValueError:\n            continue', '            due = dt.date(year, int(m.group(2)), int(m.group(1)))\n        except ZeroDivisionError:\n            continue', "r-title"),
    (V, '    return members, members[:window]', "    return members, members", "r-win"),
    (V, '"points": overlay.get(i["identifier"], i.get("estimate"))', '"points": i.get("estimate")', "r-over"),
    (V, '    others = [r["title"] for r in rows if r["category"] == UNCATEGORIZED]', "    others = []", "r-other"),
    (V, '    if not rules:\n        warnings.append', "    if False:\n        warnings.append", "r-norules"),
    (V, '    if data.get("truncated"):', "    if False:", "r-trunc"),
    (V, '    missing = {"item.list", "estimate.points_read"} - verbs\n    if run.returncode != 0 or missing:', "    missing = set()\n    if False:", "r-gap"),
    (V, '                rules.append((parts[0], parts[1] == "yes", re.compile(parts[2], re.I)))', '                rules.append((parts[0], parts[1] == "yes", re.compile("x", re.I)))', "r-badcat"),
    (V, '        if not start < day <= today:', "        if not start <= day <= today:", "r-vel"),
    (V, '    start = today - dt.timedelta(weeks=VELOCITY_WEEKS)', "    start = today - dt.timedelta(weeks=1)", "r-vel"),
    (V, 'if r["exclusion"] == "rollup_parent" or not r["completed"] or not r["calibrate"]:', 'if not r["completed"] or not r["calibrate"]:', "r-vel"),
    (V, 'if r["exclusion"] == "rollup_parent" or not r["completed"] or not r["calibrate"]:', 'if r["exclusion"] == "rollup_parent" or not r["completed"]:', "r-vel"),
    (V, '"--state-type", state_type, "--include-archived", "--limit"', '"--state-type", state_type, "--limit"', "r-arch"),
    (V, 'if len(pairs) < MIN_SAMPLE:\n        return None', 'if len(pairs) < 2:\n        return None', "r-rho-n"),
    (V, '            if started >= created:\n                row["queue_h"]', '            if True:\n                row["queue_h"]', "r-negq"),
    (V, 'elif row["completed"] is None or row["completed"] <= started:', 'elif row["completed"] is None or row["completed"] < started:', "r-zero"),
    (V, '    return when.astimezone(LOCAL[0]).date()', "    return when.astimezone(dt.timezone.utc).date()", "r-tz"),
    (V, '    LOCAL[0] = dt.timezone(dt.timedelta(hours=args.utc_offset))', "    pass", "r-tz"),
    (V, '    if excluded.get("no_started_at"):\n        warnings.append', "    if False:\n        warnings.append", "r-surv"),
    (V, '    if overlay:\n        result["estimates_overlay"]', '    if False:\n        result["estimates_overlay"]', "p-over"),
    (V, '        return dt.datetime.now(LOCAL[0])', "        return dt.datetime(2000, 1, 1, tzinfo=LOCAL[0])", "r-now"),
    (V, 'if rx.search(stripped if calibrate else raw):', "if rx.search(raw):", "r-brack"),
    (V, 'if rx.search(stripped if calibrate else raw):', "if rx.search(stripped):", "r-brack"),
    (V, '(("concluídas", rows, others), ("abertas", open_rows, open_others))', '(("concluídas", rows, others),)', "r-open"),
    (V, 'others = [x for j, x in enumerate(history) if j != k and (not temporal or x["completed"] < held["created"])]', 'others = [x for j, x in enumerate(history) if (not temporal or x["completed"] < held["created"])]', "r-bt"),
    (V, 'others = [x for j, x in enumerate(history) if j != k and (not temporal or x["completed"] < held["created"])]', 'others = [x for j, x in enumerate(history) if j != k]', "s-drift"),
    (V, 'LOW_QUANTILE, LIKELY_QUANTILE, DUE_QUANTILE, HIGH_QUANTILE = 0.25, 0.5, 0.8, 0.9', 'LOW_QUANTILE, LIKELY_QUANTILE, DUE_QUANTILE, HIGH_QUANTILE = 0.25, 0.5, 0.5, 0.9', "p-hist"),
    (V, 'LOW_QUANTILE, LIKELY_QUANTILE, DUE_QUANTILE, HIGH_QUANTILE = 0.25, 0.5, 0.8, 0.9', 'LOW_QUANTILE, LIKELY_QUANTILE, DUE_QUANTILE, HIGH_QUANTILE = 0.5, 0.5, 0.8, 0.9', "p-hist"),
    (V, '    k = math.ceil((len(v) + 1) * q)', "    k = math.ceil(len(v) * q)", "p-hist"),
    (V, 'return sorted(r["queue_h"] + points * r["work_h"] / r["points"] for r in history)', 'return sorted(a + b for a, b in zip(sorted(r["queue_h"] for r in history), sorted(points * r["work_h"] / r["points"] for r in history)))', "r-hold"),
    (V, 'remaining = sorted(r["queue_h"] - age + points * r["work_h"] / r["points"] for r in history if r["queue_h"] >= age)', 'remaining = sorted(a - age + b for a, b in zip(sorted(r["queue_h"] for r in history), sorted(points * r["work_h"] / r["points"] for r in history)))', "p-hist"),
    (V, 'remaining = sorted(r["queue_h"] - age + points * r["work_h"] / r["points"] for r in history if r["queue_h"] >= age)', 'remaining = sorted(r["queue_h"] - age + points * r["work_h"] / r["points"] for r in history)', "p-aged"),
    (V, '"proposal": {"due_date": date_for(due)', '"proposal": {"due_date": date_for(likely)', "p-hist"),
    (V, '"likely": date_for(likely)', '"likely": date_for(due)', "p-hist"),
    (V, '"high": date_for(high)', '"high": date_for(due + 99)', "p-hist"),
    (V, '    date_for = lambda h: local_date(now + dt.timedelta(hours=h)).isoformat()', '    date_for = lambda h: local_date(now.replace(hour=0, minute=0) + dt.timedelta(hours=h)).isoformat()', "p-tod"),
    (V, 'remaining = sorted(x - elapsed for x in scaled if x > elapsed)', 'remaining = sorted(scaled)', "p-started"),
    (V, 'remaining = sorted(x - elapsed for x in scaled if x > elapsed)', 'remaining = sorted(x - elapsed for x in scaled)', "p-old"),
    (V, 'extra = {"work_hours_if_started_now": round3(work_only)}', 'extra = {"work_hours_if_started_now": round3(work_only + 1)}', "p-aged"),
    (V, 'for r in history], DUE_QUANTILE)[0]\n        extra', 'for r in history], HIGH_QUANTILE)[0]\n        extra', "p-aged"),
    (V, '.get("nodes", []) if (c.get("state") or {}).get("type") not in ("completed", "canceled")]', '.get("nodes", [])]', "p-mclosed"),
    (V, '    if not known[0] <= points <= known[-1]:', "    if False:", "p-extra"),
    (V, '    if not known[0] <= points <= known[-1]:', "    if True:", "p-hist"),
    (V, 'and (not temporal or x["completed"] < held["created"])]', 'and (not temporal or x["created"] < held["created"])]', "r-tleak"),
    (V, 'FAMILY_ALPHA = 0.05 ', "FAMILY_ALPHA = 1.0 ", "s-noise"),
    (V, 'return FAMILY_ALPHA / max(tested, 1), tested', 'return FAMILY_ALPHA, tested', "s-noise"),
    (V, '    if p_value is not None and p_value > alpha:', "    if False:", "s-noise"),
    (V, '    if p_value is not None and p_value > alpha:', "    if False:", "s-fp"),
    (V, '        return dt.datetime.now(LOCAL[0])', "        return dt.datetime.now(LOCAL[0]).replace(hour=0, minute=0, second=0, microsecond=0)", "r-now2"),
    (V, 'late = hours(r["created"], now) > due', "late = False", "r-open-c"),
    (V, 'overdue, on_time = overdue + late, on_time + (not late)', "overdue, on_time = overdue, on_time + (not late)", "r-open-c"),
    (V, 'if r["calibrate"] and r["exclusion"] != "rollup_parent" and r["completed"]:', 'if r["work_h"] is not None:', "r-open-c"),
    (V, 'if x["id"] != row["id"] and (not temporal or x["completed"] < row["created"])]', 'if x["id"] != row["id"]]', "r-open-t"),
    (V, 'if x["id"] != row["id"] and (not temporal or x["completed"] < row["created"])]', 'if (not temporal or x["completed"] < row["created"])]', "r-open-c"),
    (V, '"limits": limits_with_bias(backtests)}\n', '"limits": LIMITS}\n', "r-bias"),
    (V, '            if b["status"] == "not_measured":', "            if False:", "r-nm"),
    (V, '"status": "measured" if n >= BACKTEST_MIN else "not_measured"', '"status": "measured"', "r-nm"),
    (V, 'backtest(rows, window, True, True)["per_category"].get(category, {"n": 0, "covered_by_due": 0, "inside_band": 0})', '(lambda b: {k: b[k] for k in ("n", "covered_by_due", "inside_band")})(backtest(rows, window, True, True))', "s-cat"),
    (V, '    if kind in ("completed", "canceled"):', '    if kind in ("canceled",):', "p-closed"),
    (V, '    if kind in ("completed", "canceled"):', '    if kind in ("completed",):', "p-closed"),
    (V, '    if opened:\n', "    if False:\n", "p-mother"),
    (V, '    if not signal["ok"]:\n        return refusal', '    if False:\n        return refusal', "s-inv"),
    (V, '    elif rho is None:\n', '    elif False:\n', "s-var"),
    (V, 'MIN_SPEARMAN = 0.3 ', "MIN_SPEARMAN = -2 ", "s-inv"),
    (V, 'hits += sum(a * b for a, b in zip(centered, shuffled)) >= observed - 1e-9', 'hits += 0', "s-noise"),
    (V, '    elif err is None or err > MAX_ERROR:', "    elif False:", "s-err"),
    (V, '    elif base is not None and err > base:', "    elif False:", "s-base"),
    (V, '    if check["coverage_due"] < BACKTEST_FLOOR:', "    if False:", "s-drift"),
    (V, '    if check["n"] < BACKTEST_MIN:\n        return refusal', '    if False:\n        return refusal', "s-small"),
    (V, '    if len(history) < MIN_SAMPLE:\n        return refusal', '    if False:\n        return refusal', "p-insuf"),
    (V, '    if len(remaining) < MIN_SAMPLE:', "    if False:", "p-old"),
    (V, '    if not stats["calibrate"]:', "    if False:", "p-nocal"),
    (V, '        if not points:\n            return refusal', "        if False:\n            return refusal", "p-nopts"),
    (V, '    elif points is None or not category:', "    elif False:", "p-usage"),
    (V, '    return {"status": "proposed",\n', '    tm("due_date.set", "SAC-70", date_for(due))\n    return {"status": "proposed",\n', "ro"),
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
    (V, '    entries.sort(key=lambda e: e["id"])  # a ordem', "    pass  # a ordem", "b-order"),
    (V, "os.O_TRUNC, 0o600)", "os.O_TRUNC, 0o644)", "b-mode"),
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
