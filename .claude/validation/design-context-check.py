#!/usr/bin/env python3
"""design-context-check.py — o checador da vertical de design sobre o grafo do design-context.

Faz as duas checagens que o gate do contrato KG-SSOT (kg_validate --corpus, kg_trace) NÃO faz, medidas no
laboratório do estudo da curadoria (design-setup-2026-10, emenda F, casos 5, 6 e 9):

1. LOCATOR DE TOKEN. Todo nó com `provenance.source` num arquivo .json e `provenance.locator` que começa com
   "#/" tem o JSON Pointer resolvido (RFC 6901, com o percent-encoding do fragmento decodificado, §6) no
   arquivo, a partir da raiz do repo, e o destino tem de ser um TOKEN DTCG (um objeto com "$value"), não um
   grupo. O `trace:` só acusa o arquivo que some (integrity.trace-target-missing); o token que some de dentro
   do JSON, citado só pelo grafo, só esta checagem pega.
2. LIGAÇÃO DO BRIEF. O nó cujo `trace:` aponta o brief (`<design>/brief.md`) precisa de uma `external_edge`
   para um grafo do business-context, OU de um nó `question` aberto com `x_missing_context: business-context`
   ligado a ele, que declara a falta. O gate só pega a ligação QUEBRADA (integrity.dangling-external); a
   AUSENTE é esta regra. E o brief que existe no disco sem nenhum nó que o trace também acusa: sem isso,
   apagar o nó do brief calava a regra (a forma do protótipo da curadoria saía 0 nesse caso).

ISOLADO DE PROPÓSITO: só Python 3 e PyYAML, sem nada do core. A checagem do locator pode migrar para o
kg_trace do kg-ssot (pergunta em aberto com ele); isolado, delegar é trocar a chamada.

Uso: python3 -I -B design-context-check.py --root <raiz> --design-dir <rel> --business-dir <rel>
                                          [--graph <arquivo>] [--format tsv|human] [--strict]
Saída tsv: `<SEV>\t<CÓDIGO>\t<caminho relativo>\t<mensagem>`, uma por achado. SEV é SOFT no 1º ciclo
(os briefs dos adotantes ainda não migraram); --strict a sobe para HARD.
rc: 0 nada a acusar · 1 algum achado · 2 NÃO PUDE JULGAR (grafo ilegível, YAML que não é mapa, `nodes` que
não é lista, nó sem id, PyYAML ausente). rc 2 nunca é verde.
"""
import argparse
import json
import os
import re
import sys
import urllib.parse


class CannotJudge(Exception):
    pass


def norm_trace(t):
    """`arquivo#ancora` e `arquivo:12[-30]` apontam o mesmo arquivo."""
    if not isinstance(t, str):
        return ""
    t = t.strip().split("#", 1)[0]
    t = re.sub(r":\d+(-\d+)?$", "", t)
    return t[2:] if t.startswith("./") else t


def resolve_pointer(doc, fragment):
    pointer = urllib.parse.unquote(fragment[1:])  # RFC 6901 §6: decodifica antes de separar
    cur = doc
    for raw in pointer[1:].split("/"):
        key = raw.replace("~1", "/").replace("~0", "~")
        if isinstance(cur, dict) and key in cur:
            cur = cur[key]
        elif isinstance(cur, list) and key.isdigit() and int(key) < len(cur):
            cur = cur[int(key)]
        else:
            return "ausente"
    return "ok" if isinstance(cur, dict) and "$value" in cur else "grupo"


def inside_root(root, rel):
    if os.path.isabs(rel):
        return False
    full = os.path.realpath(os.path.join(root, rel))
    return full == os.path.realpath(root) or full.startswith(os.path.realpath(root) + os.sep)


def load_graph(path):
    try:
        import yaml
    except ImportError:
        raise CannotJudge("PyYAML ausente")
    try:
        with open(path, encoding="utf-8") as fh:
            graph = yaml.safe_load(fh)
    except (OSError, yaml.YAMLError) as exc:
        raise CannotJudge(f"{path}: {exc.__class__.__name__}: {str(exc).splitlines()[0] if str(exc) else ''}")
    if not isinstance(graph, dict):
        raise CannotJudge(f"{path}: o documento não é um mapa")
    nodes = graph.get("nodes")
    if not isinstance(nodes, list):
        raise CannotJudge(f"{path}: 'nodes' não é uma lista")
    for node in nodes:
        if not isinstance(node, dict) or not isinstance(node.get("id"), str):
            raise CannotJudge(f"{path}: nó sem id")
    return graph


def check_locators(graph, root, grel, add):
    for node in graph["nodes"]:
        prov = node.get("provenance") if isinstance(node.get("provenance"), dict) else {}
        src, loc = prov.get("source"), prov.get("locator")
        if not (isinstance(src, str) and src.endswith(".json") and isinstance(loc, str) and loc.startswith("#/")):
            continue
        nid = node["id"]
        if not inside_root(root, src):
            add("LOCATOR-FORA-DA-RAIZ", grel, f"{nid}: provenance.source '{src}' sai da raiz do repo")
            continue
        try:
            with open(os.path.join(root, src), encoding="utf-8") as fh:
                doc = json.load(fh)
        except (OSError, ValueError):
            add("LOCATOR-FONTE-ILEGIVEL", grel, f"{nid}: o arquivo de tokens {src} não abre como JSON")
            continue
        verdict = resolve_pointer(doc, loc)
        if verdict == "grupo":
            add("LOCATOR-GRUPO", grel, f"{nid}: {src}{loc} é um grupo, não um token ($value ausente)")
        elif verdict == "ausente":
            add("LOCATOR-AUSENTE", grel, f"{nid}: o token {loc} não existe em {src}")


def check_brief(graph, root, grel, design_dir, business_dir, add):
    brief = f"{design_dir}/brief.md"
    briefs = [n["id"] for n in graph["nodes"] if norm_trace(n.get("trace")) == brief]
    if not briefs:
        if os.path.isfile(os.path.join(root, brief)):
            add("BRIEF-FORA-DO-GRAFO", grel, f"{brief} existe e nenhum nó do grafo o traça (trace: {brief})")
        return
    ext = [e for e in (graph.get("external_edges") or []) if isinstance(e, dict)]
    edges = [e for e in (graph.get("edges") or []) if isinstance(e, dict)]
    missing = {n["id"] for n in graph["nodes"]
               if n.get("node_type") == "question" and n.get("status") == "open"
               and n.get("x_missing_context") == "business-context"}
    prefix = f"{business_dir}/"
    for bid in briefs:
        linked = any(e.get("from") == bid and isinstance(e.get("to"), str)
                     and e["to"].startswith(prefix) and ".kg.yaml#" in e["to"] for e in ext)
        declared = any((e.get("from") in missing and e.get("to") == bid)
                       or (e.get("to") in missing and e.get("from") == bid) for e in edges)
        if not (linked or declared):
            add("BRIEF-SEM-LIGACAO", grel,
                f"{bid}: o brief não tem external_edge para um grafo em {prefix} nem question aberta "
                f"(x_missing_context: business-context) ligada a ele que declare a falta")


def main(argv):
    ap = argparse.ArgumentParser(add_help=True)
    ap.add_argument("--root", required=True)
    ap.add_argument("--design-dir", default="docs/design-context")
    ap.add_argument("--business-dir", default="docs/business-context")
    ap.add_argument("--graph", default="")
    ap.add_argument("--format", choices=("tsv", "human"), default="human")
    ap.add_argument("--strict", action="store_true")
    try:
        args = ap.parse_args(argv)
    except SystemExit:
        return 2
    root = os.path.realpath(args.root)
    if not os.path.isdir(root):
        print(f"design-context-check: raiz inexistente: {args.root} — não pude julgar", file=sys.stderr)
        return 2
    design_dir, business_dir = args.design_dir.strip("/"), args.business_dir.strip("/")
    sev = "HARD" if args.strict else "SOFT"
    found = []

    def add(code, path, msg):
        found.append((sev, code, path, msg))

    grel = args.graph or f"{design_dir}/design-context.kg.yaml"
    gpath = grel if os.path.isabs(grel) else os.path.join(root, grel)
    if not os.path.isfile(gpath):
        if args.graph:
            print(f"design-context-check: grafo inexistente: {grel} — não pude julgar", file=sys.stderr)
            return 2
        if os.path.isfile(os.path.join(root, design_dir, "brief.md")):
            add("SEM-GRAFO", f"{design_dir}/brief.md",
                f"há brief e não há {grel}: o design-context ainda não migrou para grafo (rode /design:setup)")
        # sem brief e sem grafo: nada a julgar (adotante sem design)
    else:
        try:
            graph = load_graph(gpath)
        except CannotJudge as exc:
            print(f"design-context-check: {exc} — não pude julgar", file=sys.stderr)
            return 2
        check_locators(graph, root, grel, add)
        check_brief(graph, root, grel, design_dir, business_dir, add)

    for s, code, path, msg in found:
        if args.format == "tsv":
            print(f"{s}\t{code}\t{path}\t{msg}")
        else:
            print(f"  ✗ {s} [{code}] {path}: {msg}")
    if args.format == "human":
        print(f"design-context-check: {len(found)} achado(s)")
    return 1 if found else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
