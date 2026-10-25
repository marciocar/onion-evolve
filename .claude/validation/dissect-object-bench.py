#!/usr/bin/env python3
"""Bancada do checador de forma da dissecação de qualquer objeto (dissect-object-check.py).

Roda pela família run_dissect_object_selftests do lint-selftest.sh. Exercita o checador COMO A SESSÃO O INVOCA: pelo
wrapper .sh, num repo git temporário com o registro, o vendor do kg-ssot e commits de verdade (o item 5 lê o git log).
Três partes:
  1. COBERTURA: todo código que o checador emite (lido do fonte, nunca de uma lista paralela) tem ao menos um caso;
     código sem caso reprova a bancada. Foi o que a 1ª versão do protótipo não tinha: 5 checagens desligadas e a
     bancada verde.
  2. CASOS: cada caso ruim nasce de UMA mutação do grafo bom (ou da ordem dos commits) e exige o código dele; as
     variantes legítimas (plano movido de nome, stage plan antes do commit, família pelo apelido legado) exigem rc 0.
  3. MUTANTE POR CÓDIGO: uma cópia do checador com AQUELE código calado; o caso dele tem de deixar de acusá-lo. Com
     a cobertura do passo 1, desligar qualquer checagem derruba algum caso.
Origem: a bancada do protótipo de um adotante de curadoria (69 casos e 2 de rc 3 medidos; a proposta dizia 60), absorvida em 2026-10-24.
Saída: uma linha `ok   …` por caso verde e, no fim, `FALHA (n):` com uma linha `- …` por caso vermelho; rc 0 ou 1.
"""
import concurrent.futures
import copy
import hashlib
import os
import re
import shutil
import subprocess
import sys
import tempfile

import yaml

SRC = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True, text=True).stdout.strip()
CHECK_PY = ".claude/validation/dissect-object-check.py"
CHECK_SH = ".claude/validation/dissect-object-check.sh"
REGISTRY = ".claude/validation/dissect-families.kg.yaml"
STUDY = "docs/evolution/dissect/fixture-app-2026-10"
GRAPH = STUDY + "/fixture-app-2026-10.kg.yaml"
STAGE0 = STUDY + "/STAGE0.md"
STAGE0_TEXT = "# Etapa 0 — fixture\n\n" + "".join("## %d. elemento %d\n\ntexto.\n\n" % (i, i) for i in range(1, 9))
DYNAMIC = "stage0-criterion-digest"  # o código que vem do kg_criterion (add(5, "stage0-" + …))


def sh(cwd, *cmd):
    return subprocess.run(list(cmd), cwd=cwd, capture_output=True, text=True)


def good_graph(sha):
    return {
        "meta": {"id": "fixture-app-2026-10", "schema_version": "1", "baseline": "2026-10-23", "review_after": "2027-01-21",
                 "x_dissect_tool": "fixture-app", "x_dissect_family": "app", "x_study_destination": "core",
                 "x_who_pays": "ninguém paga hoje; não abre via de bilhetagem", "x_unverified": ["uso em produção"]},
        "external_edges": [{"from": "D_FIXTURE", "to": REGISTRY + "#T_FAMILY_APP", "edge_type": "TRACES_TO"}],
        "nodes": [
            {"id": "S_STAGE0", "node_type": "claim", "plane": "DEV", "status": "open", "impact": 3, "confidence": 0.5,
             "label": "Etapa 0 pré-registrada.", "trace": STAGE0,
             "x_criterion": {"id": "FIXTURE_STAGE0", "version": 1, "registered_at": "2026-10-23T00:00:00+00:00", "sha256": sha, "ref": STAGE0}},
            {"id": "E_N0", "node_type": "evidence", "plane": "DEV", "status": "open", "impact": 2, "confidence": 0.5, "label": "N0.", "x_dissect_level": 0},
            {"id": "E_N2", "node_type": "evidence", "plane": "DEV", "status": "open", "impact": 2, "confidence": 0.5, "label": "N2.",
             "x_dissect_level": 2, "x_dissect_n2_evidence": "artefato-aberto"},
            {"id": "E_PERSIST", "node_type": "evidence", "plane": "DEV", "status": "open", "impact": 1, "confidence": 0.5, "label": "o que o gatilho conta."},
            {"id": "E_OVER", "node_type": "evidence", "plane": "DEV", "status": "open", "impact": 1, "confidence": 0.5, "label": "superação."},
            {"id": "D_FIXTURE", "node_type": "decision", "plane": "DEV", "status": "open", "impact": 3, "confidence": 0.5, "label": "parquear.",
             "trace": STAGE0, "x_dissect_level": 3, "x_dissect_verdict": "parquear", "x_dissect_overcoming": "nenhuma",
             "x_dissect_overcoming_search": [{"where": "corpus", "cmd": "kg_query --text fixture"}, {"where": "web", "source": "https://example.org/busca"}],
             "x_dissect_trigger": {"kg_query": ["--file", "fixture-app", "--status", "superseded"], "min_count": 1}},
        ],
        "edges": [{"from": "E_N0", "to": "D_FIXTURE", "edge_type": "SUPPORTS"}],
    }


def node(g, nid):
    return next(n for n in g["nodes"] if n["id"] == nid)


def D(g):
    return node(g, "D_FIXTURE")


def no_art(g):
    del node(g, "E_N2")["x_dissect_n2_evidence"]


def flatten_to_1(g):
    for n in g["nodes"]:
        if isinstance(n.get("x_dissect_level"), int) and n["x_dissect_level"] >= 2:
            n["x_dissect_level"] = 1


def uso_observado(trace):
    def m(g):
        node(g, "E_N2")["x_dissect_n2_evidence"] = "uso-observado"
        node(g, "E_N2")["trace"] = trace
    return m


def seq(*fs):
    def m(g):
        for f in fs:
            f(g)
    return m


# (nome, código esperado ou None para rc 0, mutação do grafo, ordem dos commits, args extras)
CASES = [
    ("grafo bom", None, None, "ok", []),
    ("stage plan antes do commit, com --allow-uncommitted", None, lambda g: g.update(nodes=[node(g, "S_STAGE0")]), "plan-uncommitted", ["--stage", "plan", "--allow-uncommitted"]),
    ("plano movido de nome antes do N0 (variante legítima)", None, None, "moved", []),
    ("caminho absoluto do grafo", None, None, "ok", ["@abs"]),
    ("expect-verdict e max-level que batem", None, None, "ok", ["--expect-verdict", "parquear", "--max-level", "3"]),
    ("família pelo apelido legado C, lido do registro (variante legítima)", None, lambda g: (g["meta"].update(x_dissect_family="C"), g["external_edges"][0].update(to=REGISTRY + "#T_FAMILY_ATOR")), "ok", []),
    # item 1
    ("sem x_dissect_tool", "sem-x_dissect_tool", lambda g: g["meta"].pop("x_dissect_tool"), "ok", []),
    ("família fora do registro", "familia-fora-do-registro", lambda g: g["meta"].update(x_dissect_family="brinquedo"), "ok", []),
    ("família proposta (válvula fechada sem PR do registro)", "familia-fora-do-registro", lambda g: g["meta"].update(x_dissect_family="proposta"), "ok", []),
    ("sem aresta para o registro", "aresta-familia-ausente", lambda g: g.update(external_edges=[]), "ok", []),
    ("aresta para outra família", "aresta-familia-discorda", lambda g: g["external_edges"][0].update(to=REGISTRY + "#T_FAMILY_ATOR"), "ok", []),
    # item 2
    ("veredito no S_STAGE0", "veredito-fora-de-decisao", lambda g: (node(g, "S_STAGE0").update(x_dissect_verdict="parquear", x_dissect_overcoming="nenhuma", x_dissect_overcoming_search=D(g)["x_dissect_overcoming_search"], x_dissect_trigger=D(g)["x_dissect_trigger"]), D(g).pop("x_dissect_verdict")), "ok", []),
    ("veredito selado no próprio estudo", "veredito-selado", lambda g: D(g).update(status="done"), "ok", []),
    ("veredito fechado com o selo do destino (variante legítima)", None, lambda g: D(g).update(status="done", x_dissect_sealed_by="onion-evolve:docs/onion/graph/sinais-de-campo-2026-09.kg.yaml#D_FIXTURE_SELADO"), "ok", []),
    ("selo do destino mal formado", "selo-mal-formado", lambda g: D(g).update(status="done", x_dissect_sealed_by="o core selou"), "ok", []),
    ("selo válido com o veredito refutado (só done fecha)", "veredito-selado", lambda g: D(g).update(status="refuted", x_dissect_sealed_by="onion-evolve:docs/onion/graph/sinais-de-campo-2026-09.kg.yaml#D_FIXTURE_SELADO"), "ok", []),
    ("sem veredito", "veredito-ausente", lambda g: D(g).pop("x_dissect_verdict"), "ok", []),
    ("estudo sem veredito (variante legítima do modo estudo)", None, lambda g: (g["meta"].update(x_dissect_mode="study"), D(g).pop("x_dissect_verdict")), "ok", []),
    ("estudo com veredito", "estudo-com-veredito", lambda g: g["meta"].update(x_dissect_mode="study"), "ok", []),
    ("dois vereditos", "veredito-duplicado", lambda g: node(g, "E_OVER").update(x_dissect_verdict="parquear"), "ok", []),
    ("veredito fora da família", "veredito-fora-da-familia", lambda g: D(g).update(x_dissect_verdict="perseguir"), "ok", []),
    ("perseguir sem saída", "perseguir-sem-saida", lambda g: (g["meta"].update(x_dissect_family="ideia"), g["external_edges"][0].update(to=REGISTRY + "#T_FAMILY_IDEIA"), D(g).update(x_dissect_verdict="perseguir")), "ok", []),
    ("escritor trocou o veredito do Elenxo", "veredito-diverge-do-elenxo", None, "ok", ["--expect-verdict", "rejeitar"]),
    ("grafo acima do nível que o Elenxo sustentou", "nivel-acima-do-sustentado", None, "ok", ["--max-level", "2"]),
    # itens 3 e 4
    ("destino fora do enum", "destino-fora-do-enum", lambda g: g["meta"].update(x_study_destination="algum-lugar"), "ok", []),
    ("sem x_who_pays", "sem-x_who_pays", lambda g: g["meta"].pop("x_who_pays"), "ok", []),
    ("sem x_unverified", "sem-x_unverified", lambda g: g["meta"].pop("x_unverified"), "ok", []),
    # item 5
    ("nível em string", "nivel-invalido", lambda g: node(g, "E_N0").update(x_dissect_level="0"), "ok", []),
    ("nível N2 em texto", "nivel-invalido", lambda g: node(g, "E_N2").update(x_dissect_level="N2"), "ok", []),
    ("nível 5", "nivel-invalido", lambda g: node(g, "E_N2").update(x_dissect_level=5), "ok", []),
    ("sem S_STAGE0", "sem-S_STAGE0", lambda g: g.update(nodes=[n for n in g["nodes"] if n["id"] != "S_STAGE0"]), "ok", []),
    ("ref do plano fora do estudo", "stage0-ref-fora-do-estudo", lambda g: node(g, "S_STAGE0")["x_criterion"].update(ref=REGISTRY), "ok", []),
    ("ref do plano ausente", "stage0-ref-ausente", None, "deleted", []),
    ("ref para outro arquivo da pasta do estudo", "stage0-ref-fora-do-estudo", lambda g: node(g, "S_STAGE0")["x_criterion"].update(ref=STUDY + "/README.md"), "ok", []),
    ("plano fora do git e N0 commitado, com a flag", "stage0-depois-do-n0", None, "n0-before-uncommitted-plan", ["--allow-uncommitted"]),
    ("plano sem os 8 elementos", "stage0-sem-8-elementos", None, "short", []),
    ("estudo final sem N0", "sem-n0", lambda g: node(g, "E_N0").pop("x_dissect_level"), "ok", []),
    ("plano não commitado", "stage0-nao-commitado", lambda g: g.update(nodes=[node(g, "S_STAGE0")]), "plan-uncommitted", ["--stage", "plan"]),
    ("sha256 registrado não é o do commit", "stage0-sha-do-commit", lambda g: node(g, "S_STAGE0")["x_criterion"].update(sha256="0" * 64), "ok", []),
    ("plano editado na árvore", "stage0-editado", None, "edited", []),
    ("plano editado muda o sha256 (kg_criterion)", DYNAMIC, None, "edited", []),
    ("plano reescrito e commitado depois do N0", "stage0-reescrito", None, "rewritten", []),
    ("plano apagado e recriado depois do N0", "stage0-reescrito", None, "recreated", []),
    ("plano no mesmo commit do N0", "stage0-mesmo-commit-do-n0", None, "same", []),
    ("plano depois do N0", "stage0-depois-do-n0", None, "after", []),
    ("N0 sob outro nome antes do plano, depois git mv", "stage0-depois-do-n0", None, "renamed-after", []),
    ("N0 em string commitado antes do plano", "stage0-depois-do-n0", lambda g: node(g, "E_N0").update(x_dissect_level="0"), "after", []),
    ("N0 só na árvore", "n0-nao-commitado", None, "n0-uncommitted", []),
    ("N0 no índice, sem commit, com a flag: o caminho de quem confere antes de commitar", None, None, "n0-staged", ["--allow-uncommitted"]),
    # item 6
    ("parquear sem x_dissect_overcoming", "sem-x_dissect_overcoming", lambda g: D(g).pop("x_dissect_overcoming"), "ok", []),
    ("busca mal formada", "busca-mal-formada", lambda g: D(g).update(x_dissect_overcoming_search=[{"where": "lua"}]), "ok", []),
    ("superação nenhuma sem web", "busca-sem-web", lambda g: D(g).update(x_dissect_overcoming_search=[{"where": "corpus", "cmd": "kg_query --text x"}]), "ok", []),
    ("superação aponta id inexistente", "superacao-id-invalido", lambda g: D(g).update(x_dissect_overcoming="E_NAO_EXISTE"), "ok", []),
    ("superação sem locality", "superacao-sem-locality", lambda g: D(g).update(x_dissect_overcoming="E_OVER"), "ok", []),
    # item 7
    ("gatilho mal formado", "gatilho-mal-formado", lambda g: D(g).update(x_dissect_trigger={"kg_query": "--status superseded"}), "ok", []),
    ("gatilho com flag fora da lista", "gatilho-fora-da-lista-branca", lambda g: D(g)["x_dissect_trigger"].update(kg_query=["--verified-before", "2026-10-01", "--status", "superseded"]), "ok", []),
    ("gatilho lendo drifted", "gatilho-fora-da-lista-branca", lambda g: D(g)["x_dissect_trigger"].update(kg_query=["--file", "fixture-app", "--status", "drifted"]), "ok", []),
    ("gatilho sem ler o que persiste", "gatilho-fora-da-lista-branca", lambda g: D(g)["x_dissect_trigger"].update(kg_query=["--file", "fixture-app"]), "ok", []),
    ("gatilho com --id inexistente", "gatilho-selecao-vazia", lambda g: D(g)["x_dissect_trigger"].update(kg_query=["--id", "NAO_EXISTE", "--status", "superseded"]), "ok", []),
    ("gatilho com --id-prefix que nada casa", "gatilho-selecao-vazia", lambda g: D(g)["x_dissect_trigger"].update(kg_query=["--id-prefix", "ZZZ_NUNCA_", "--status", "superseded"]), "ok", []),
    ("gatilho com --edge-type SUPERSEDES sem --around", "gatilho-fora-da-lista-branca", lambda g: D(g)["x_dissect_trigger"].update(kg_query=["--file", "fixture-app", "--edge-type", "SUPERSEDES"]), "ok", []),
    ("gatilho com --edge-type CONSTRAINS", "gatilho-fora-da-lista-branca", lambda g: D(g)["x_dissect_trigger"].update(kg_query=["--around", "E_N0", "--edge-type", "CONSTRAINS"]), "ok", []),
    ("gatilho --around com --depth 0", "gatilho-fora-da-lista-branca", lambda g: D(g)["x_dissect_trigger"].update(kg_query=["--around", GRAPH + "#E_N0", "--edge-type", "SUPERSEDES", "--depth", "0"]), "ok", []),
    ("gatilho --around com --direction out", "gatilho-fora-da-lista-branca", lambda g: D(g)["x_dissect_trigger"].update(kg_query=["--around", GRAPH + "#E_N0", "--edge-type", "SUPERSEDES", "--direction", "out"]), "ok", []),
    ("gatilho --around com SUPERSEDES e CONSTRAINS", "gatilho-fora-da-lista-branca", lambda g: D(g)["x_dissect_trigger"].update(kg_query=["--around", GRAPH + "#E_N0", "--edge-type", "SUPERSEDES", "--edge-type", "CONSTRAINS"]), "ok", []),
    ("gatilho ancorado noutro grafo", "gatilho-ancora-fora-do-estudo", lambda g: D(g)["x_dissect_trigger"].update(kg_query=["--around", REGISTRY + "#T_FAMILY_APP", "--edge-type", "SUPERSEDES"]), "ok", []),
    ("gatilho ancorado em nó inexistente", "gatilho-ancora-fora-do-estudo", lambda g: D(g)["x_dissect_trigger"].update(kg_query=["--around", GRAPH + "#E_NAO_EXISTE", "--edge-type", "SUPERSEDES"]), "ok", []),
    ("gatilho --around com caminho, depth 2 e direção in (variante legítima)", None, lambda g: D(g)["x_dissect_trigger"].update(kg_query=["--around", GRAPH + "#E_N0", "--edge-type", "SUPERSEDES", "--depth", "2", "--direction", "in"], min_count=50), "ok", []),
    ("gatilho --around com SUPERSEDES (variante legítima)", None, lambda g: D(g)["x_dissect_trigger"].update(kg_query=["--around", "E_N0", "--edge-type", "SUPERSEDES"], min_count=50), "ok", []),
    ("gatilho já disparado", "gatilho-ja-disparou", lambda g: node(g, "E_PERSIST").update(status="superseded"), "ok", []),
    ("gatilho disparado num parque já selado", "gatilho-ja-disparou", lambda g: (node(g, "E_PERSIST").update(status="superseded"), D(g).update(status="done", x_dissect_sealed_by="o core selou")), "ok", []),
    ("gatilho disparado depois do selo válido (avisa, rc 0)", "aviso:gatilho-disparou-depois-do-selo", lambda g: (node(g, "E_PERSIST").update(status="superseded"), D(g).update(status="done", x_dissect_sealed_by="onion-evolve:docs/onion/graph/sinais-de-campo-2026-09.kg.yaml#D_FIXTURE_SELADO")), "ok", []),
    # item 8
    ("uso observado com trace fora do estudo", "uso-observado-sem-protocolo", uso_observado(CHECK_SH), "ok", []),
    ("uso observado com PROTOCOL.md não rastreado", "uso-observado-sem-protocolo", uso_observado(STUDY + "/PROTOCOL.md"), "protocol-untracked", []),
    ("uso observado com PROTOCOL.md rastreado (variante legítima)", None, uso_observado(STUDY + "/PROTOCOL.md"), "protocol-tracked", []),
    ("app N2 sem artefato acima do nível 1", "app-acima-do-nivel-1", no_art, "ok", []),
    ("app N2 sem artefato com veredito rejeitar", "app-sem-artefato-veredito", seq(no_art, flatten_to_1, lambda g: D(g).update(x_dissect_verdict="rejeitar")), "ok", []),
]
RC3_CASES = [
    ("grafo ilegível", "rc3-yaml", ["@graph"]),
    ("argumento inválido", "rc3-args", ["@graph", "--stage", "meio"]),
    ("registro sem família viva", "rc3-registry", ["@graph"]),
    ("contexto com registro sem família viva", "rc3-registry", ["--context"]),
]


def setup(tmp, checker_src):
    for d in (STUDY, ".claude/validation", os.path.dirname(REGISTRY)):
        os.makedirs(os.path.join(tmp, d), exist_ok=True)
    shutil.copy(os.path.join(SRC, REGISTRY), os.path.join(tmp, REGISTRY))
    shutil.copy(os.path.join(SRC, CHECK_SH), os.path.join(tmp, CHECK_SH))
    with open(os.path.join(tmp, CHECK_PY), "w", encoding="utf-8") as fh:
        fh.write(checker_src)
    os.symlink(os.path.join(SRC, "vendor"), os.path.join(tmp, "vendor"))
    for c in (["git", "init", "-q"], ["git", "config", "user.email", "bench@local"], ["git", "config", "user.name", "bench"]):
        sh(tmp, *c)


def write(tmp, rel, text):
    os.makedirs(os.path.dirname(os.path.join(tmp, rel)), exist_ok=True)
    with open(os.path.join(tmp, rel), "w", encoding="utf-8") as fh:
        fh.write(text)


def write_yaml(tmp, rel, data):
    write(tmp, rel, yaml.safe_dump(data, allow_unicode=True, sort_keys=False))


def commit(tmp, msg):
    sh(tmp, "git", "add", "-A")
    sh(tmp, "git", "commit", "-q", "-m", msg)


def build(checker_src, mut, order):
    tmp = tempfile.mkdtemp(prefix="dissect-object-")
    setup(tmp, checker_src)
    text = STAGE0_TEXT if order != "short" else "# Etapa 0 curta\n\n## 1. só um\n"
    g = good_graph(hashlib.sha256(text.encode()).hexdigest())
    if mut:
        mut(g)
    plan = lambda: write(tmp, STAGE0, text)
    graph = lambda: write_yaml(tmp, GRAPH, g)
    if order == "plan-uncommitted":
        plan(); graph()
    elif order == "same":
        plan(); graph(); commit(tmp, "plano e n0 juntos")
    elif order == "after":
        graph(); commit(tmp, "n0 antes"); plan(); commit(tmp, "plano")
    elif order == "renamed-after":
        old = STUDY + "/old-name.kg.yaml"
        write_yaml(tmp, old, g); commit(tmp, "n0 com outro nome"); plan(); commit(tmp, "plano")
        sh(tmp, "git", "mv", old, GRAPH); commit(tmp, "renomeia")
    elif order == "moved":
        write(tmp, STUDY + "/PLAN.md", text); commit(tmp, "plano com outro nome")
        sh(tmp, "git", "mv", STUDY + "/PLAN.md", STAGE0); commit(tmp, "renomeia o plano")
        graph(); commit(tmp, "n0")
    elif order == "n0-uncommitted":
        plan(); commit(tmp, "plano"); graph()
    elif order == "n0-staged":
        plan(); commit(tmp, "plano"); graph(); sh(tmp, "git", "add", "-A")
    elif order == "n0-before-uncommitted-plan":
        graph(); commit(tmp, "n0 antes"); plan()
    elif order in ("protocol-untracked", "protocol-tracked"):
        plan(); commit(tmp, "plano")
        if order == "protocol-tracked":
            write(tmp, STUDY + "/PROTOCOL.md", "# protocolo\n"); commit(tmp, "protocolo")
        graph(); commit(tmp, "n0")
        if order == "protocol-untracked":
            write(tmp, STUDY + "/PROTOCOL.md", "# protocolo\n")
    else:
        plan(); commit(tmp, "plano"); graph(); commit(tmp, "n0")
        if order == "edited":
            write(tmp, STAGE0, text + "emenda por cima\n")
        elif order == "rewritten":
            write(tmp, STAGE0, text + "reescrito\n"); commit(tmp, "reescreve o plano")
        elif order == "recreated":
            sh(tmp, "git", "rm", "-q", STAGE0); commit(tmp, "apaga")
            write(tmp, STAGE0, text); commit(tmp, "recria")
        elif order == "deleted":
            sh(tmp, "git", "rm", "-q", STAGE0); commit(tmp, "apaga")
    return tmp


def run(tmp, extra):
    target = GRAPH
    args = []
    if extra[:1] == ["--context"]:
        r = sh(tmp, "bash", CHECK_SH, "--context")
        return r.returncode, r.stdout + r.stderr
    for a in extra:
        if a == "@abs":
            target = os.path.join(tmp, GRAPH)
        elif a == "@graph":
            continue
        else:
            args.append(a)
    r = sh(tmp, "bash", CHECK_SH, target, *args)
    return r.returncode, r.stdout + r.stderr


def codes_in(src):
    """os códigos lidos do fonte. Toda chamada add( tem de render um código: se o regex perder alguma, a bancada
    reprova em vez de calar (a 1ª versão deste leitor perdia todo código com `_` e a cobertura saía verde)."""
    calls = re.findall(r'\badd\((\d), ("[^"]*"[^,]*)', src)
    found = set()
    for i, lit in calls:
        m = re.fullmatch(r'"([A-Za-z0-9_-]+)"', lit.strip())
        if m:
            found.add((int(i), m.group(1)))
        elif lit.strip() == '"stage0-" + str(f.get("code"':
            found.add((5, DYNAMIC))
        else:
            raise SystemExit("bancada: add(%s, %s…) sem código literal — o leitor de cobertura não o enxerga; escreva um add por código" % (i, lit[:40]))
    return found


def silence(src, code):
    if code == DYNAMIC:
        out = src.replace('add(5, "stage0-" + ', '(lambda *a: None)(5, "stage0-" + ')
    else:
        out = re.sub(r'\badd\((\d), "%s"' % re.escape(code), r'(lambda *a: None)(\1, "%s"' % code, src)
    assert out != src, "mutante de %s não achou o add" % code
    return out


def one_case(src, item_of, case):
    """um caso e, se ele acusa, o mutante do seu código; devolve (linha ok | None, falha | None). Cada caso tem os
    seus repos temporários, então os casos rodam em paralelo sem se ver."""
    name, code, mut, order, extra = case
    made = []
    try:
        t = build(src, mut, order); made.append(t)
        rc, out = run(t, extra)
        if code is None:
            if rc != 0:
                return None, "%s: esperado rc 0; veio rc %d:\n%s" % (name, rc, out)
            return "ok   %-58s rc 0" % name, None
        if code.startswith("aviso:"):
            # o aviso informa sem reprovar: rc 0 COM a linha; o mutante cala o note() e a linha tem de sumir
            acode = code[len("aviso:"):]
            tag = "aviso item 7 %s:" % acode
            if rc != 0 or tag not in out:
                return None, "%s: esperado rc 0 com '%s'; veio rc %d:\n%s" % (name, tag, rc, out)
            muted = re.sub(r'\bfired\(7, "%s"' % re.escape(acode), r'(lambda *a: None)(7, "%s"' % acode, src)
            assert muted != src, "mutante do aviso %s não achou o fired" % acode
            t2 = build(muted, mut, order); made.append(t2)
            rc_m, out_m = run(t2, extra)
            if tag in out_m:
                return None, "%s: o MUTANTE do aviso %s ainda avisa — o caso não discrimina" % (name, acode)
            return "ok   %-58s %s (mutante calado: rc %d)" % (name, tag, rc_m), None
        tag = "item %d %s:" % (item_of.get(code, 0), code)
        if rc != 1 or tag not in out:
            return None, "%s: esperado rc 1 com '%s'; veio rc %d:\n%s" % (name, tag, rc, out)
        t2 = build(silence(src, code), mut, order); made.append(t2)
        rc_m, out_m = run(t2, extra)
        if tag in out_m:
            return None, "%s: o MUTANTE de %s ainda acusa — o caso não discrimina" % (name, code)
        return "ok   %-58s %s (mutante calado: rc %d)" % (name, tag, rc_m), None
    finally:
        for t in made:
            shutil.rmtree(t, ignore_errors=True)


def one_rc3(src, case):
    name, kind, extra = case
    t = build(src, None, "ok")
    try:
        if kind == "rc3-yaml":
            write(t, GRAPH, "meta: [isto não é\n")
        elif kind == "rc3-registry":
            write(t, REGISTRY, "meta:\n  id: dissect-families\nnodes: []\n")
        rc, out = run(t, extra)
        if rc != 3:
            return None, "%s: esperado rc 3 (não mediu); veio rc %d:\n%s" % (name, rc, out)
        return "ok   %-58s rc 3" % name, None
    finally:
        shutil.rmtree(t, ignore_errors=True)


def main():
    src = open(os.path.join(SRC, CHECK_PY), encoding="utf-8").read()
    fails = []
    emitted = codes_in(src)
    covered = {c for _, c, _, _, _ in CASES if c}
    missing = sorted(c for _, c in emitted if c not in covered)
    if missing:
        fails.append("COBERTURA: código(s) que o checador emite sem caso: %s" % missing)
    else:
        print("ok   cobertura: os %d códigos do checador têm caso" % len(emitted))
    item_of = {c: i for i, c in emitted}
    # os casos são subprocessos (git, checador, kg_query): em fila custavam ~90 s, medido em 2026-10-24
    jobs = int(os.environ.get("DISSECT_OBJECT_BENCH_JOBS") or min(8, os.cpu_count() or 1))
    with concurrent.futures.ThreadPoolExecutor(max_workers=max(1, jobs)) as pool:
        results = list(pool.map(lambda c: one_case(src, item_of, c), CASES))
        results += list(pool.map(lambda c: one_rc3(src, c), RC3_CASES))
    for ok, fail in results:
        if ok:
            print(ok)
        if fail:
            fails.append(fail)
    if fails:
        print("\nFALHA (%d):\n- %s" % (len(fails), "\n- ".join(fails)))
        return 1
    print("\ndissect-object-bench: %d caso(s) + %d de rc 3 verdes; cobertura de todos os códigos; cada caso reprova contra o mutante do seu código" % (len(CASES), len(RC3_CASES)))
    return 0

if __name__ == "__main__":
    sys.exit(main())
