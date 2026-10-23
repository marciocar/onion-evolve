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
(git show), sem checkout; sem --to, ou com --to WORKTREE, entra a árvore de trabalho, com os grafos novos ainda não
adicionados ao git, e WORKTREE:CAMINHO é o arquivo da árvore de trabalho, a partir da raiz do repo como o REV:CAMINHO e
sem sair dela (pedido de um adotante, para revisar
uma edição antes do commit; uma branch chamada WORKTREE se lê como refs/heads/WORKTREE). O
lado que existe mas não se lê (não é UTF-8, ou não parseia) sai em unreadable, com o código io.* ou parse.*, e conta
como diferença (rc 1). Num argumento ANTES ou DEPOIS, o caminho que existe no disco vence a leitura REV:CAMINHO.

Uso:
  kg_diff.py ANTES DEPOIS [--repo DIR] [--format human|json]
      ANTES e DEPOIS são arquivos, ou REV:CAMINHO lido do git em --repo (default: o diretório atual), ou
      WORKTREE:CAMINHO, o arquivo da árvore de trabalho em --repo
  kg_diff.py --from REV [--to REV|WORKTREE] [--repo DIR] [CAMINHO...] [--format human|json]
      todos os .kg.yaml e .kg.json que mudaram entre as revisões (sem --to ou com WORKTREE, a árvore de trabalho), ou
      só os caminhos
Saída humana, ou JSON no formato kg-ssot.diff/1 (spec/diff.schema.json).
rc: 0 sem diferença · 1 com diferença · 2 entrada quebrada.
"""
import argparse
import collections
import fnmatch
import json
import pathlib
import subprocess
import sys

sys.dont_write_bytecode = True
if __package__:  # no pacote kg_ssot, o vizinho vem pelo pacote, sem mexer no sys.path de quem importa
    from . import kg_i18n, kg_validate
else:  # script ou vendor
    sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
    import kg_i18n  # noqa: E402
    import kg_validate  # noqa: E402
_ = kg_i18n._

SCHEMA_VERSION = "kg-ssot.diff/1"
GRAPH_GLOBS = ("*.kg.yaml", "*.kg.json")
# os do kg_query.py e do kg_migrate.py: numa atualização do vendor, os fixtures da suíte mudam aos centos e afogam o diff
# do grafo do adotante; valem só no --from sem caminhos dados, junto com a pasta carimbada do vendor (desde a 4.20.0)
DEFAULT_EXCLUDE = ("vendor/*", "fixtures/*", "*/fixtures/*", "docs/materials/*")
EDGE_KEY = ("from", "to", "edge_type")
WORKTREE = "WORKTREE"  # a árvore de trabalho, no --to e no REV de REV:CAMINHO


class Broken(Exception):
    """Entrada quebrada: rc 2."""


def _rev(rev):
    """Uma revisão que vai ao git: a que começa com '-' seria lida como opção (--output=ARQ grava um arquivo)."""
    if not isinstance(rev, str) or not rev or rev.startswith("-"):
        raise Broken(_("invalid revision {rev}: it cannot be empty or start with '-'").format(rev=repr(rev)))
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
    raise TypeError(_("{type} is not JSON serializable").format(type=type(v).__name__))


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
    try:
        on_disk = path.is_file()
    except OSError:  # o nome longo demais (ENAMETOOLONG) não é arquivo; o REV:CAMINHO decide
        on_disk = False
    if on_disk or ":" not in spec:
        try:
            return spec, path.read_text(encoding="utf-8")
        except (OSError, UnicodeDecodeError) as exc:
            raise Broken(f"{spec}: {exc}") from None
    rev, name = spec.split(":", 1)
    if rev == WORKTREE:
        # da raiz do repo, como o REV:CAMINHO do git show, e sem sair dela (achado do Elenxo da 4.20.0)
        top = pathlib.Path(_git(repo, "rev-parse", "--show-toplevel").decode("utf-8", "surrogateescape").rstrip("\n"))
        try:
            target = (top / name).resolve()
        except (OSError, RuntimeError) as exc:  # o link em laço (RuntimeError até o 3.12) é entrada quebrada, nunca rc 1
            raise Broken(f"{spec}: {exc}") from None
        if not target.is_relative_to(top.resolve()):
            raise Broken(_("{spec}: the path is outside the repository").format(spec=spec))
        try:
            raw = target.read_bytes()
        except OSError as exc:
            raise Broken(f"{spec}: {exc}") from None
        text, code = _decode(raw)
        if code:
            raise Broken(_("{spec}: not UTF-8").format(spec=spec))
        return name, text
    text, code = _decode(_git(repo, "show", f"{_rev(rev)}:{name}"))
    if code:
        raise Broken(_("{spec}: not UTF-8").format(spec=spec))
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
            out.append({"path": path, "before": b, "after": a, "_side": "b" if key not in fa else "a" if key not in fb else ""})
    # o campo que saiu de um caminho e entrou noutro com o mesmo valor é uma renomeação (x_old → x_new): os dois lados
    # ficam, cada um com o valor do seu caminho (o ausente segue null), ligados por renamed_to e renamed_from. Só pareia
    # o valor que não é trivial e que é o único dos dois lados, para não inventar renomeação
    gone, new = ([f for f in out if f["_side"] == s] for s in ("b", "a"))
    for f in new:
        v = f["after"]
        if v is None or isinstance(v, bool) or v in ("", [], {}):
            continue
        twins = [g for g in gone if _canon(g["before"]) == _canon(v)]
        if len(twins) == 1 and sum(_canon(h["after"]) == _canon(v) for h in new) == 1:
            twins[0]["renamed_to"], f["renamed_from"] = f["path"], twins[0]["path"]
    for f in out:
        del f["_side"]
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
    fields = collections.Counter(f"{f['renamed_from']} → {f['path']}" if "renamed_from" in f else f["path"]
                                 for g in graphs if g["diff"] for n in g["diff"]["nodes"]["changed"] for f in n["fields"]
                                 if "renamed_to" not in f)
    return {**{k: s[k] for k in keys}, "fields": dict(sorted(fields.items(), key=lambda kv: (-kv[1], kv[0])))}


def changed_paths(repo, rev_from, rev_to, paths, exclude=()):
    """Os grafos que mudaram entre as revisões (rev_to None: a árvore de trabalho), com o status do git, menos os que
    casam com exclude (globs sobre o caminho)."""
    args = ["diff", "--name-status", "-z", "--no-renames", "--end-of-options", _rev(rev_from)] + \
        ([_rev(rev_to)] if rev_to else []) + ["--"]
    args += list(paths) if paths else list(GRAPH_GLOBS)
    try:
        raw = _git(repo, *args).decode("utf-8").split("\0")
    except UnicodeDecodeError:
        raise Broken(_("a changed path is not UTF-8")) from None
    out = []
    for status, name in zip(raw[0::2], raw[1::2]):
        if name.endswith((".kg.yaml", ".kg.json")):
            out.append((status[:1], name))
    if not rev_to:  # na árvore de trabalho, o grafo novo ainda não adicionado também mudou (o git diff não o lista)
        spec = list(paths) if paths else list(GRAPH_GLOBS)
        try:
            # --full-name: da raiz do repo, como os caminhos do git diff, mesmo com --repo numa subpasta
            new = _git(repo, "ls-files", "-z", "--full-name", "--others", "--exclude-standard", "--",
                       *spec).decode("utf-8").split("\0")
        except UnicodeDecodeError:
            raise Broken(_("a new path is not UTF-8")) from None
        out += [("A", n) for n in new if n.endswith((".kg.yaml", ".kg.json"))]
    named = {pathlib.PurePosixPath(p).as_posix() for p in paths}
    return [(s, n) for s, n in out if n in named or not any(fnmatch.fnmatchcase(n, pat) for pat in exclude)]


def _show(repo, rev, name):
    text, code = _decode(_git(repo, "show", f"{rev}:{name}"))
    return Unreadable(code) if code else text


def _vendor_dirs_at(repo, rev_from, rev_to):
    """As pastas carimbadas do vendor (kg_validate.vendor_dirs) nos dois lados: na revisão de antes e na de depois, ou na
    árvore de trabalho, com o carimbo ainda não adicionado ao git. Uma atualização do vendor que o muda de pasta tem o
    carimbo num lado só, e os dois contam. Os caminhos saem da raiz do repo, como os do git diff, mesmo com --repo
    numa subpasta (achado do Elenxo da 4.20.0)."""
    names = _git(repo, "ls-tree", "-r", "-z", "--full-tree", "--name-only", "--end-of-options", _rev(rev_from))
    if rev_to:
        names += b"\0" + _git(repo, "ls-tree", "-r", "-z", "--full-tree", "--name-only", "--end-of-options", _rev(rev_to))
    else:
        # sem pathspec (o :/ seria magia, que o GIT_LITERAL_PATHSPECS desliga): a lista inteira, a partir da raiz
        top = _git(repo, "rev-parse", "--show-toplevel").decode("utf-8", "surrogateescape").rstrip("\n")
        names += b"\0" + _git(top, "ls-files", "-z", "--cached", "--others", "--exclude-standard")
    paths = [n for n in names.decode("utf-8", "surrogateescape").split("\0") if n]
    return kg_validate.vendor_dirs(paths)


def diff_revisions(repo, rev_from, rev_to=None, paths=(), exclude=None, skip_vendor=None):
    """exclude None: os DEFAULT_EXCLUDE quando nenhum caminho foi dado; os caminhos dados nunca são excluídos.
    skip_vendor None: como exclude None, fica de fora toda pasta com o carimbo do vendor (kg_validate.vendor_dirs),
    onde quer que ela esteja, quando nenhum caminho foi dado. rev_to None ou WORKTREE: a árvore de trabalho."""
    if rev_from == WORKTREE:
        raise Broken(_("WORKTREE is the working tree: it goes in --to, not in --from"))
    if rev_to == WORKTREE:
        rev_to = None
    if skip_vendor is None:
        skip_vendor = exclude is None and not paths
    if exclude is None:
        exclude = () if paths else DEFAULT_EXCLUDE
    vendors = _vendor_dirs_at(repo, rev_from, rev_to) if skip_vendor else ()
    # os caminhos do git diff saem da raiz do repo: a árvore de trabalho se lê a partir dela, não de --repo; entre duas
    # revisões nada se lê do disco, e o repo bare (sem árvore de trabalho) segue funcionando
    top = None if rev_to else pathlib.Path(
        _git(repo, "rev-parse", "--show-toplevel").decode("utf-8", "surrogateescape").rstrip("\n"))
    graphs = []
    for status, name in changed_paths(repo, rev_from, rev_to, paths, exclude):
        if kg_validate.in_vendor(name, vendors):
            continue
        text_b = None if status == "A" else _show(repo, rev_from, name)
        if status == "D":
            text_a = None
        elif rev_to:
            text_a = _show(repo, rev_to, name)
        else:
            try:
                text_a, code = _decode((top / name).read_bytes())
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


def _field(f, n):
    """Um campo mudado no texto humano: o caminho com o antes e o depois, ou a renomeação com o valor que ficou."""
    if "renamed_from" in f:
        return _("{old} → {new} (renamed): {value}").format(old=f["renamed_from"], new=f["path"],
                                                            value=_short(f["after"], n))
    return f"{f['path']}: {_short(f['before'], n)} → {_short(f['after'], n)}"


# a linha de título de cada grafo, por status: o texto humano se traduz na hora (o status do JSON fica em inglês)
STATUS_LINE = {"modified": lambda: _("{name} (modified)"), "added": lambda: _("{name} (added)"),
               "removed": lambda: _("{name} (removed)"), "unchanged": lambda: _("{name} (unchanged)"),
               "unreadable": lambda: _("{name} (unreadable)")}


def human(res):
    lines = []
    for g in res["graphs"]:
        name = g["after"] or g["before"]
        lines.append(STATUS_LINE[g["status"]]().format(name=name))
        if g["status"] == "unreadable":
            lines += ["  " + _("UNREADABLE  {side}: {code}").format(side=side, code=code)
                      for side, code in g["unreadable"].items()]
            continue
        d = g["diff"]
        for f in (f for f in d["meta"] if "renamed_to" not in f):  # o --ignore vale com o prefixo meta. (meta.date)
            lines.append(f"  ~ {_field(f, 80)}")
        for n in d["nodes"]["added"]:
            lines.append(f"  + {n['id']}  {_short(n['label'], 100)}")
        for n in d["nodes"]["removed"]:
            lines.append(f"  - {n['id']}  {_short(n['label'], 100)}")
        for n in d["nodes"]["changed"]:
            lines.append(f"  ~ {n['id']}  " + "; ".join(_field(f, 40)
                                                       for f in n["fields"] if "renamed_to" not in f))
        for key, word in (("edges", _("edge")), ("external_edges", _("external edge"))):
            for sign, part in (("+", "added"), ("-", "removed"), ("~", "changed")):
                for e in d[key][part]:
                    what = "; ".join(_field(f, 40)
                                     for f in e.get("fields", []) if "renamed_to" not in f)
                    lines.append(f"  {sign} {word} {e['from'] or _('(the graph)')} -{e['edge_type']}-> {e['to']}"
                                 + (f"  ({what})" if what else ""))
    s = res["summary"]
    lines.append("· " + _("{graphs} graph(s): {modified} modified, {added} added, {removed} removed, {unreadable}"
                          " unreadable; nodes +{nodes_added} -{nodes_removed} ~{nodes_changed};"
                          " edges +{edges_added} -{edges_removed} ~{edges_changed}").format(graphs=len(res["graphs"]), **{
        k: s[k] for k in ("modified", "added", "removed", "unreadable", "nodes_added", "nodes_removed", "nodes_changed",
                          "edges_added", "edges_removed", "edges_changed")}))
    if s["fields"]:
        lines.append("· " + _("changed node fields: {fields}").format(
            fields=" · ".join(f"{p}: {n}" for p, n in list(s["fields"].items())[:12])))
    if res["ignored"]:
        lines.append("· " + _("ignored: {paths}").format(paths=", ".join(res["ignored"])))
    return "\n".join(lines)


def main(argv=None):
    ap = argparse.ArgumentParser(description=_("Diff by id between two revisions of .kg.yaml and .kg.json graphs "
                                               "(release 4.17)."))
    ap.add_argument("specs", nargs="*", help=_("BEFORE AFTER (files or REV:PATH), or the paths with --from"))
    ap.add_argument("--repo", default=".", help=_("the git repository of the revisions (default: the current directory)"))
    ap.add_argument("--from", dest="rev_from", help=_("the before revision: compares every graph that changed"))
    ap.add_argument("--to", dest="rev_to", help=_("the after revision (without it, or with WORKTREE, the working tree)"))
    ap.add_argument("--ignore", action="append", default=[], metavar=_("FIELD"),
                    help=_("leaves the field out of the comparison (repeatable): verified_at, provenance.locator,"
                           " meta.x_generated_at"))
    ap.add_argument("--exclude", action="append", default=[], metavar="GLOB",
                    help=_("with --from, paths left out (repeatable), added to the defaults: {defaults}").format(
                        defaults=", ".join(DEFAULT_EXCLUDE)))
    ap.add_argument("--no-default-excludes", action="store_true",
                    help=_("with --from, also compares the vendor and the fixtures"))
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
            res = result(args.rev_from, args.rev_to or WORKTREE,
                         diff_revisions(args.repo, args.rev_from, args.rev_to, args.specs,
                                        None if not (args.exclude or args.no_default_excludes) else
                                        (() if args.no_default_excludes or args.specs else DEFAULT_EXCLUDE)
                                        + tuple(args.exclude),
                                        skip_vendor=not (args.no_default_excludes or args.specs)))
        else:
            if args.rev_to or len(args.specs) != 2:
                raise Broken(_("give BEFORE and AFTER, or --from REV [--to REV] [PATH...]"))
            nb, tb = read_spec(args.specs[0], args.repo)
            na, ta = read_spec(args.specs[1], args.repo)
            res = result(args.specs[0], args.specs[1], [diff_pair(nb, tb, na, ta)])
    except Broken as exc:
        print(_("BROKEN INPUT  {error}").format(error=exc), file=sys.stderr)
        return 2
    text = json.dumps(res, ensure_ascii=False, indent=1, default=_jsonable) if args.format == "json" else human(res)
    # o surrogate solto (\ud800, que o contrato só avisa) não é UTF-8: sai como o escape \ud800, que no JSON é o mesmo valor
    print(text.encode("utf-8", "backslashreplace").decode("utf-8"))
    return 0 if all(g["status"] == "unchanged" for g in res["graphs"]) else 1


if __name__ == "__main__":
    sys.exit(main())
