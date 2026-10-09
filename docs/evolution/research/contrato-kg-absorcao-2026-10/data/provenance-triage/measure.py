#!/usr/bin/env python3
"""Medidas finais sobre rows.json (classificador v3): encaminhamento, classe de method proposta, cruzamentos."""
import json, os, re, collections

HERE = os.environ.get("PROV_HERE", "/tmp/prov-triage")
R = json.load(open(f"{HERE}/rows.json"))
JUIZES = re.compile(r'votos?\s*\d|vota[çc][ãa]o|\bjuiz|ju[ií]zes|elenxo|adversarial|\bwf_|veredito|painel|worker', re.I)
LEITURA = re.compile(r'QUOTE|verbatim|cita[çc][ãa]o|\blid[oa]\b|leitura|gh: PR #|WebFetch|se[çc][ãa]o|p\. \d|l\.\d|:\d+', re.I)
MEDICAO = re.compile(r'grep|curl|medid|medi[çc]|rodad|executad|exit \d|rc=|selftest|bancada|wc -l|contagem|dogfood|sandbox|mutante|ls |git log|jq ', re.I)
TESTE = re.compile(r'maestro|selad|selo\b|relato|sinal d|relay|adotante|screenshot|usu[aá]rio', re.I)
DEMO = re.compile(r'demo|fixture|example|exemplo', re.I)


def method_class(r):
    va = r["va"]
    if r["cls"] == "T" or (TESTE.search(va) and not MEDICAO.search(va)):
        return "testemunho"
    if r["cls"] == "U":
        return "—"
    if r["cls"] == "A2" and r["sub"].startswith(("caminho-trace", "url-trace", "citacao-texto", "url-no-meio", "fora-do-repo")) \
            and not va:
        return "derivado"
    if JUIZES.search(va):
        return "juízes"
    if r["cls"] == "A1" and LEITURA.search(va):
        return "leitura"
    if MEDICAO.search(va):
        return "medição"
    if LEITURA.search(va):
        return "leitura"
    return "derivado"


ROUTE = {"A1": "aceitar", "A2": "aceitar c/ ressalva", "C": "corrigir", "T": "testemunho", "U": "rebaixar", "R": "resíduo"}
# regra do mandato: classe < 90% de concordância na amostra vira R (resíduo) — C, T, U falharam nas 2 rodadas
FAILED = {"C", "T", "U"}
for r in R:
    r["method_class"] = method_class(r)
    r["route_hint"] = ROUTE[r["cls"]]
    r["final"] = "R" if r["cls"] in FAILED else r["cls"]
    r["demo"] = bool(DEMO.search(r["graph"].split("/")[-1]))
json.dump(R, open(f"{HERE}/rows-final.json", "w"), ensure_ascii=False, indent=0)

C = collections.Counter
print("classe v3:", dict(sorted(C(r["cls"] for r in R).items())))
print("final (regra 90%):", dict(sorted(C(r["final"] for r in R).items())))
print("method x final:")
for k, v in sorted(C((r["final"], r["method_class"]) for r in R).items()): print("  ", k, v)
print("status x plane x final:")
t = collections.defaultdict(C)
for r in R: t[(r["status"], r["plane"])][r["final"]] += 1
for k, v in sorted(t.items(), key=lambda x: -sum(x[1].values())): print("  ", k, dict(v))
print("tipo x final:")
t = collections.defaultdict(C)
for r in R: t[r["node_type"]][r["final"]] += 1
for k, v in sorted(t.items(), key=lambda x: -sum(x[1].values())): print("  ", k, sum(v.values()), dict(v))
print("demo graphs:", C(r["graph"] for r in R if r["demo"]))
g = collections.defaultdict(C)
for r in R: g[r["graph"]][r["final"]] += 1
print("grafos:", len(g))
dom = collections.defaultdict(list)
for k, v in g.items():
    d = max(v, key=v.get); dom[d].append((k, sum(v.values()), round(v[d] / sum(v.values()), 2)))
for d, lst in sorted(dom.items()):
    print("DOM", d, len(lst), "grafos,", sum(x[1] for x in lst), "nós")
json.dump({k: dict(v) for k, v in g.items()}, open(f"{HERE}/per-graph.json", "w"), ensure_ascii=False, indent=1)
# resíduo por dica de subclasse
print("R por subclasse-dica:", C((r["cls"], r["sub"].split("+")[0]) for r in R if r["final"] == "R").most_common())
print("R PROD nao-confirmed:", sum(1 for r in R if r["final"] == "R" and r["plane"] == "PROD" and r["status"] != "confirmed"))
print("U v3 por plano/status:", C((r["plane"], r["status"]) for r in R if r["cls"] == "U"))
# o routing por nó (a entrada do kg-migrate-v3 --routing): uma linha por nó, na ordem do corpus
with open(f"{HERE}/routing.tsv", "w", encoding="utf-8") as fh:
    fh.write("graph\tid\tstatus\tplane\tclass\tsubclass\tfinal\tmethod_class\ttool_derives\n")
    for r in R:
        fh.write("\t".join([r["graph"], r["id"], r["status"] or "", r["plane"] or "", r["cls"], r["sub"], r["final"],
                            r["method_class"], r["tool"]]) + "\n")
