#!/usr/bin/env python3
"""O diff por id entre duas revisões de grafos .kg.yaml e .kg.json (release 4.17, O3 do roteiro).

Compara dois grafos, ou todos os grafos que mudaram entre duas revisões do git, alinhando os nós pelo id e as arestas
pelo par de pontas e o tipo, como o diff do TerminusDB alinha documentos pelo @id: o nó que só existe de um lado foi
acrescentado ou removido, e o que existe nos dois sai com cada campo que mudou, antes e depois (o que não aparece
ficou igual). As arestas e as arestas externas são conjuntos: acrescentadas e removidas, e as que têm as mesmas
pontas e o mesmo tipo com outro label ou trigger saem como mudadas. O meta sai campo a campo, junto com as outras
chaves da raiz (o contrato não fecha a raiz). Os valores se comparam na forma JSON do contrato (1 e 1.0 e true são
diferentes), e o id repetido no mesmo grafo conta cada cópia.

Não é patch: o diff informa, não se aplica. Uma troca de id é remoção mais acréscimo, porque o id é a identidade do nó,
e um arquivo renomeado também (o git é lido com --no-renames). Uma lista dentro do nó (um x_ com lista, por exemplo) é
comparada inteira, antes e depois. A ordem dos nós no arquivo não conta. Uma revisão do git é lida pelo object store
(git show), sem checkout; sem --to, entra a árvore de trabalho, com os grafos novos ainda não adicionados ao git. O
lado que existe mas não se lê (não é UTF-8, ou não parseia) sai em unreadable, com o código io.* ou parse.*, e conta
como diferença (rc 1). Num argumento ANTES ou DEPOIS, o caminho que existe no disco vence a leitura REV:CAMINHO.

Uso:
  kg_diff.py ANTES DEPOIS [--repo DIR] [--format human|json]
      ANTES e DEPOIS são arquivos, ou REV:CAMINHO lido do git em --repo (default: o diretório atual)
  kg_diff.py --from REV [--to REV] [--repo DIR] [CAMINHO...] [--format human|json]
      todos os .kg.yaml e .kg.json que mudaram entre as revisões (sem --to, a árvore de trabalho), ou só os caminhos
Saída humana, ou JSON no formato kg-ssot.diff/1 (spec/diff.schema.json).
rc: 0 sem diferença · 1 com diferença · 2 entrada quebrada.
"""
import argparse
import collections
import json
import pathlib
import subprocess
import sys

sys.dont_write_bytecode = True
if __package__:  # no pacote kg_ssot, o vizinho vem pelo pacote, sem mexer no sys.path de quem importa
    from . import kg_validate
else:  # script ou vendor
    sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
    import kg_validate  # noqa: E402

SCHEMA_VERSION = "kg-ssot.diff/1"
GRAPH_GLOBS = ("*.kg.yaml", "*.kg.json")
EDGE_KEY = ("from", "to", "edge_type")


class Broken(Exception):
    """Entrada quebrada: rc 2."""


def _rev(rev):
    """Uma revisão que vai ao git: a que começa com '-' seria lida como opção (--output=ARQ grava um arquivo)."""
    if not isinstance(rev, str) or not rev or rev.startswith("-"):
        raise Broken(f"revisão {rev!r} inválida: não pode ser vazia nem começar com '-'")
    return rev


def _decode(raw):
    """(texto, None) do conteúdo em UTF-8, ou (None, "io.not-utf8"): o grafo ilegível sai em unreadable, sem traceback."""
    try:
        return raw.decode("utf-8"), None
    except UnicodeDecodeError:
        return None, "io.not-utf8"


def _jsonable(v):
    """O default do json.dumps: o .nan/.inf do YAML (kg_validate.NonFinite) sai como o texto dele."""
    if isinstance(v, kg_validate.NonFinite):
        return v.text
    raise TypeError(f"{type(v).__name__} não serializa")


def _canon(v):
    """A forma canônica para comparar: 1, 1.0 e true são valores diferentes no grafo, e o == do Python os iguala."""
    return json.dumps(v, sort_keys=True, default=_jsonable, ensure_ascii=False)


def _git(repo, *args):
    out = subprocess.run(["git", "-C", str(repo), *args], capture_output=True)
    if out.returncode != 0:
        raise Broken(f"git {' '.join(args)}: {out.stderr.decode('utf-8', 'replace').strip()}")
    return out.stdout


def read_spec(spec, repo):
    """(nome, texto) de um arquivo, ou de REV:CAMINHO no git de repo. Caminho que existe no disco vence o REV:."""
    path = pathlib.Path(spec)
    if path.is_file() or ":" not in spec:
        try:
            return spec, path.read_text(encoding="utf-8")
        except (OSError, UnicodeDecodeError) as exc:
            raise Broken(f"{spec}: {exc}") from None
    rev, name = spec.split(":", 1)
    text, code = _decode(_git(repo, "show", f"{_rev(rev)}:{name}"))
    if code:
        raise Broken(f"{spec}: não é UTF-8")
    return name, text


def _flat(value, prefix=()):
    """{(chave, ...): valor} de um mapa; lista e escalar são folhas, e o mapa vazio aninhado também (na raiz, nada). A
    chave é a tupla, não o texto pontuado: {"a.b": 1} e {"a": {"b": 1}} são caminhos diferentes."""
    if isinstance(value, dict) and not value and not prefix:
        return {}
    if isinstance(value, dict) and value:
        out = {}
        for k, v in value.items():
            out.update(_flat(v, prefix + (str(k),)))
        return out
    return {prefix: value}


IGNORE = ()  # os caminhos que o --ignore tira da comparação (o caminho e o que fica abaixo dele)


def _ignored(path):
    return any(path == p or path.startswith(p + ".") for p in IGNORE)


def field_changes(before, after):
    """[{path, before, after}] dos campos que mudaram, em ordem de caminho; o campo ausente de um lado vale null. O
    caminho ignorado (--ignore) não conta."""
    fb, fa = _flat(before), _flat(after)
    out = []
    for key in sorted(set(fb) | set(fa)):
        path = ".".join(key)
        if _ignored(path):
            continue
        b, a = fb.get(key), fa.get(key)
        if _canon(b) != _canon(a) or (key in fb) != (key in fa):
            out.append({"path": path, "before": b, "after": a})
    return out


def _parse(name, text):
    """O documento no modelo do contrato, ou (None, código parse.*)."""
    _, doc, code = kg_validate.parse_v1(kg_validate.as_source(name, text))
    if code or not isinstance(doc, dict):
        return None, code or "parse.root-not-mapping"
    return doc, None


def _nodes(doc):
    """{id: [nó, ...]}: o id repetido (que o contrato reprova, mas o diff não julga) conta cada ocorrência, na ordem."""
    out = collections.defaultdict(list)
    for n in doc.get("nodes") if isinstance(doc.get("nodes"), list) else []:
        if isinstance(n, dict) and isinstance(n.get("id"), str):
            out[n["id"]].append(n)
    return out


def _edges(doc, key):
    """{(from, to, edge_type): [aresta, ...]}: a mesma chave repetida conta cada vez."""
    out = collections.defaultdict(list)
    for e in doc.get(key) if isinstance(doc.get(key), list) else []:
        if isinstance(e, dict):
            out[tuple(e.get(k) if isinstance(e.get(k), str) else None for k in EDGE_KEY)].append(e)
    return out


def _edge_view(k, e=None):
    v = dict(zip(EDGE_KEY, k))
    for extra in ("label", "trigger"):
        if e is not None and extra in e:
            v[extra] = e[extra]
    return v


def _edge_diff(eb, ea):
    added, removed, changed = [], [], []
    for k in sorted(set(eb) | set(ea), key=lambda t: tuple("" if x is None else x for x in t)):
        lb, la = eb.get(k, []), ea.get(k, [])
        for b, a in zip(lb, la):
            fields = field_changes({x: v for x, v in b.items() if x not in EDGE_KEY},
                                   {x: v for x, v in a.items() if x not in EDGE_KEY})
            if fields:
                changed.append({**_edge_view(k), "fields": fields})
        removed += [_edge_view(k, b) for b in lb[len(la):]]
        added += [_edge_view(k, a) for a in la[len(lb):]]
    # a troca de tipo com as mesmas pontas (REFUTES para CONSTRAINS) sai como uma mudança de edge_type, não -1 +1
    for r in list(removed):
        hit = next((a for a in added if (a["from"], a["to"]) == (r["from"], r["to"])), None)
        if hit is not None:
            removed.remove(r)
            added.remove(hit)
            fields = [{"path": "edge_type", "before": r["edge_type"], "after": hit["edge_type"]}]
            fields += field_changes({x: v for x, v in r.items() if x not in EDGE_KEY},
                                    {x: v for x, v in hit.items() if x not in EDGE_KEY})
            changed.append({**_edge_view((hit["from"], hit["to"], hit["edge_type"])), "fields": fields})
    return {"added": added, "removed": removed, "changed": changed}


def _node_view(n):
    return {"id": n["id"], "node_type": n.get("node_type"), "status": n.get("status"),
            "label": n.get("label") if isinstance(n.get("label"), str) else None}


def diff_docs(before, after):
    """O diff de dois documentos já parseados (qualquer um pode ser None: grafo acrescentado ou removido)."""
    before, after = before or {}, after or {}
    nb, na = _nodes(before), _nodes(after)
    added, removed, changed = [], [], []
    for nid in sorted(set(nb) | set(na)):
        lb, la = nb.get(nid, []), na.get(nid, [])
        for b, a in zip(lb, la):
            fields = field_changes(b, a)
            if fields:
                changed.append({"id": nid, "label": a.get("label") if isinstance(a.get("label"), str) else None,
                                "fields": fields})
        removed += [_node_view(b) for b in lb[len(la):]]
        added += [_node_view(a) for a in la[len(lb):]]
    # o meta e as outras chaves da raiz (o contrato não fecha a raiz): meta.title, meta (quando não é mapa), x_algo
    top = ("nodes", "edges", "external_edges")
    return {
        "meta": field_changes({k: v for k, v in before.items() if k not in top},
                              {k: v for k, v in after.items() if k not in top}),
        "nodes": {"added": added, "removed": removed, "changed": changed},
        "edges": _edge_diff(_edges(before, "edges"), _edges(after, "edges")),
        "external_edges": _edge_diff(_edges(before, "external_edges"), _edges(after, "external_edges")),
    }


def _empty(d):
    return not d["meta"] and not any(d[k][x] for k in ("nodes", "edges", "external_edges") for x in d[k])


class Unreadable:
    """O lado que existe mas não se lê (não é UTF-8, ou o arquivo não abre): sai em unreadable com o código io.*."""

    def __init__(self, code):
        self.code = code


def diff_pair(name_b, text_b, name_a, text_a):
    """Um item de graphs: os dois lados, o status e o diff. text None é o lado que não existe; Unreadable, o ilegível."""
    item = {"before": name_b if text_b is not None else None, "after": name_a if text_a is not None else None}
    db = da = None
    codes = {}
    if isinstance(text_b, Unreadable):
        codes["before"] = text_b.code
    elif text_b is not None:
        db, codes["before"] = _parse(name_b, text_b)
    if isinstance(text_a, Unreadable):
        codes["after"] = text_a.code
    elif text_a is not None:
        da, codes["after"] = _parse(name_a, text_a)
    bad = {side: c for side, c in codes.items() if c}
    if bad:
        item.update(status="unreadable", unreadable=bad, diff=None)
        return item
    d = diff_docs(db, da)
    item["status"] = "added" if text_b is None else "removed" if text_a is None else \
        "unchanged" if _empty(d) else "modified"
    item["diff"] = d
    return item


def summarize(graphs):
    s = collections.Counter()
    for g in graphs:
        s[g["status"]] += 1
        d = g["diff"]
        if not d:
            continue
        for k in ("added", "removed", "changed"):
            s[f"nodes_{k}"] += len(d["nodes"][k])
            s[f"edges_{k}"] += len(d["edges"][k]) + len(d["external_edges"][k])
    keys = ("modified", "added", "removed", "unchanged", "unreadable", "nodes_added", "nodes_removed", "nodes_changed",
            "edges_added", "edges_removed", "edges_changed")
    fields = collections.Counter(f["path"] for g in graphs if g["diff"] for n in g["diff"]["nodes"]["changed"]
                                 for f in n["fields"])
    return {**{k: s[k] for k in keys}, "fields": dict(sorted(fields.items(), key=lambda kv: (-kv[1], kv[0])))}


def changed_paths(repo, rev_from, rev_to, paths):
    """Os grafos que mudaram entre as revisões (rev_to None: a árvore de trabalho), com o status do git."""
    args = ["diff", "--name-status", "-z", "--no-renames", "--end-of-options", _rev(rev_from)] + \
        ([_rev(rev_to)] if rev_to else []) + ["--"]
    args += list(paths) if paths else list(GRAPH_GLOBS)
    try:
        raw = _git(repo, *args).decode("utf-8").split("\0")
    except UnicodeDecodeError:
        raise Broken("um caminho mudado não é UTF-8") from None
    out = []
    for status, name in zip(raw[0::2], raw[1::2]):
        if name.endswith((".kg.yaml", ".kg.json")):
            out.append((status[:1], name))
    if not rev_to:  # na árvore de trabalho, o grafo novo ainda não adicionado também mudou (o git diff não o lista)
        spec = list(paths) if paths else list(GRAPH_GLOBS)
        try:
            new = _git(repo, "ls-files", "-z", "--others", "--exclude-standard", "--", *spec).decode("utf-8").split("\0")
        except UnicodeDecodeError:
            raise Broken("um caminho novo não é UTF-8") from None
        out += [("A", n) for n in new if n.endswith((".kg.yaml", ".kg.json"))]
    return out


def _show(repo, rev, name):
    text, code = _decode(_git(repo, "show", f"{rev}:{name}"))
    return Unreadable(code) if code else text


def diff_revisions(repo, rev_from, rev_to=None, paths=()):
    graphs = []
    for status, name in changed_paths(repo, rev_from, rev_to, paths):
        text_b = None if status == "A" else _show(repo, rev_from, name)
        if status == "D":
            text_a = None
        elif rev_to:
            text_a = _show(repo, rev_to, name)
        else:
            try:
                text_a, code = _decode((pathlib.Path(repo) / name).read_bytes())
                text_a = Unreadable(code) if code else text_a
            except FileNotFoundError:
                text_a = None
            except OSError as exc:
                text_a = Unreadable(f"io.{type(exc).__name__}")
        graphs.append(diff_pair(name, text_b, name, text_a))
    return graphs


def result(before_src, after_src, graphs):
    return {"schema_version": SCHEMA_VERSION, "before": before_src, "after": after_src, "ignored": list(IGNORE),
            "summary": summarize(graphs), "graphs": graphs}


def _short(v, n=80):
    s = "—" if v is None else v if isinstance(v, str) else json.dumps(v, ensure_ascii=False, default=_jsonable)
    s = s.replace("\n", " ")
    return s if len(s) <= n else s[:n - 1] + "…"


STATUS_PT = {"modified": "modificado", "added": "acrescentado", "removed": "removido", "unchanged": "igual",
             "unreadable": "não lido"}


def human(res):
    lines = []
    for g in res["graphs"]:
        name = g["after"] or g["before"]
        lines.append(f"{name} ({STATUS_PT[g['status']]})")
        if g["status"] == "unreadable":
            lines += [f"  NÃO LIDO  {side}: {code}" for side, code in g["unreadable"].items()]
            continue
        d = g["diff"]
        for f in d["meta"]:  # o --ignore vale para o meta com o prefixo meta. (meta.date)
            lines.append(f"  ~ {f['path']}: {_short(f['before'])} → {_short(f['after'])}")
        for n in d["nodes"]["added"]:
            lines.append(f"  + {n['id']}  {_short(n['label'], 100)}")
        for n in d["nodes"]["removed"]:
            lines.append(f"  - {n['id']}  {_short(n['label'], 100)}")
        for n in d["nodes"]["changed"]:
            lines.append(f"  ~ {n['id']}  " + "; ".join(f"{f['path']}: {_short(f['before'], 40)} → {_short(f['after'], 40)}"
                                                       for f in n["fields"]))
        for key, word in (("edges", "aresta"), ("external_edges", "aresta externa")):
            for sign, part in (("+", "added"), ("-", "removed"), ("~", "changed")):
                for e in d[key][part]:
                    what = "; ".join(f"{f['path']}: {_short(f['before'], 40)} → {_short(f['after'], 40)}"
                                     for f in e.get("fields", []))
                    lines.append(f"  {sign} {word} {e['from'] or '(o grafo)'} -{e['edge_type']}-> {e['to']}"
                                 + (f"  ({what})" if what else ""))
    s = res["summary"]
    lines.append(f"· {len(res['graphs'])} grafo(s): {s['modified']} modificado(s), {s['added']} acrescentado(s),"
                 f" {s['removed']} removido(s), {s['unreadable']} não lido(s); nós +{s['nodes_added']} -{s['nodes_removed']} ~{s['nodes_changed']};"
                 f" arestas +{s['edges_added']} -{s['edges_removed']} ~{s['edges_changed']}")
    if s["fields"]:
        lines.append("· campos mudados nos nós: " + " · ".join(f"{p}: {n}" for p, n in list(s["fields"].items())[:12]))
    if res["ignored"]:
        lines.append("· ignorados: " + ", ".join(res["ignored"]))
    return "\n".join(lines)


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n", 1)[0])
    ap.add_argument("specs", nargs="*", help="ANTES DEPOIS (arquivos ou REV:CAMINHO), ou os caminhos com --from")
    ap.add_argument("--repo", default=".", help="o repositório git das revisões (default: o diretório atual)")
    ap.add_argument("--from", dest="rev_from", help="a revisão de antes: compara todos os grafos que mudaram")
    ap.add_argument("--to", dest="rev_to", help="a revisão de depois (sem ela, a árvore de trabalho)")
    ap.add_argument("--ignore", action="append", default=[], metavar="CAMPO",
                    help="tira o campo da comparação (repetível): verified_at, provenance.locator, meta.x_gerado_em")
    ap.add_argument("--format", default="human", choices=("human", "json"))
    args = ap.parse_args(argv)
    global IGNORE
    saved, IGNORE = IGNORE, tuple(p.strip() for p in args.ignore if p.strip())
    try:
        return _run(args)
    finally:  # o --ignore vale para esta chamada: quem importa o módulo não herda o de um main() anterior
        IGNORE = saved


def _run(args):
    try:
        if args.rev_from:
            res = result(args.rev_from, args.rev_to or "(árvore de trabalho)",
                         diff_revisions(args.repo, args.rev_from, args.rev_to, args.specs))
        else:
            if args.rev_to or len(args.specs) != 2:
                raise Broken("dê ANTES e DEPOIS, ou --from REV [--to REV] [CAMINHO...]")
            nb, tb = read_spec(args.specs[0], args.repo)
            na, ta = read_spec(args.specs[1], args.repo)
            res = result(args.specs[0], args.specs[1], [diff_pair(nb, tb, na, ta)])
    except Broken as exc:
        print(f"ENTRADA QUEBRADA  {exc}", file=sys.stderr)
        return 2
    text = json.dumps(res, ensure_ascii=False, indent=1, default=_jsonable) if args.format == "json" else human(res)
    # o surrogate solto (\ud800, que o contrato só avisa) não é UTF-8: sai como o escape \ud800, que no JSON é o mesmo valor
    print(text.encode("utf-8", "backslashreplace").decode("utf-8"))
    return 0 if all(g["status"] == "unchanged" for g in res["graphs"]) else 1


if __name__ == "__main__":
    sys.exit(main())
