#!/usr/bin/env python3
"""A consulta e a projeção legível de um corpus de grafos .kg.yaml e .kg.json (release 4.17, O3 do roteiro).

Lê muitos grafos de uma vez e seleciona nós por id, prefixo, tipo, status, plano, camada e texto do label; traz a
vizinhança por tipo de aresta e profundidade, a fila dos abertos (--open) e os nós sem verified_at ou conferidos
antes de uma data (--verified-before). Cada nó sai PROJETADO: as arestas de saída e de entrada com a outra ponta
resolvida de id para label, local ou externa (external_edges), e se a ponta existe no corpus. Paginação por cursor.

Não julga: o veredito é do kg_validate.py, e um grafo que não parseia sai em "unreadable", sem derrubar a consulta.
Não ranqueia por atenção: --sort impact ordena pelo impacto declarado, e a fórmula de atenção fica com quem a usa.
Saída humana, ou JSON no formato kg-ssot.query/1 (spec/query.schema.json).

Uso:
  kg_query.py [--root DIR [--exclude GLOB]... | ARQ...] [filtros] [--around ID [--depth N] [--edge-type T]...
              [--direction out|in|both]] [--sort corpus|impact] [--limit N] [--cursor C] [--narrative]
              [--fields GLOB]... [--format human|json]
  filtros (todos juntos, em E): --id ID... --id-prefix P --type T --status S --plane P --layer L --file TRECHO
                                --text PALAVRAS [--in-narrative] --open --verified-before AAAA-MM-DD
  --root DIR lê os .kg.yaml e .kg.json rastreados pelo git sob DIR (sem git, todos sob DIR); os caminhos saem
  relativos a DIR, que é a raiz contra a qual a ponta externa <caminho>#<id> se resolve.
rc: 0 consultou (mesmo sem nenhum nó) · 2 entrada quebrada.
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
    from . import kg_validate
else:  # script ou vendor
    sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
    import kg_validate  # noqa: E402

SCHEMA_VERSION = "kg-ssot.query/1"
MAX_LIMIT = 1000
# o label da OUTRA ponta de uma aresta sai cortado: sem o corte, um nó de label longo citado por milhares de arestas
# (duplicadas, ou externas de outro grafo) multiplica a resposta pelo número de arestas (2 MB de grafo, 7,5 GB de saída)
END_LABEL_MAX = 200
NODE_FIELDS = ("node_type", "status", "plane", "layer", "impact", "confidence", "verified_at")


class Corpus:
    """Os grafos lidos: os nós por (arquivo, id) na ordem do corpus, e as arestas locais e externas dos dois lados."""

    def __init__(self):
        self.nodes = {}  # (arquivo, id) -> nó (o mapa do documento)
        self.order = []  # as chaves na ordem do corpus: arquivo a arquivo, nó a nó
        self.out = collections.defaultdict(list)  # (arquivo, id) -> [(edge_type, (arquivo, id) | None, ref)]
        self.into = collections.defaultdict(list)
        self.unreadable = []  # [{file, code}]
        self.files = []

    def add(self, name, text):
        if name in self.files:  # o mesmo arquivo dado duas vezes não duplica as arestas
            return
        self.files.append(name)
        _, doc, code = kg_validate.parse_v1(kg_validate.as_source(name, text) if not isinstance(text, kg_validate.JsonText)
                                            else text)
        if code or not isinstance(doc, dict):
            self.unreadable.append({"file": name, "code": code or "parse.root-not-mapping"})
            return
        for n in doc.get("nodes") if isinstance(doc.get("nodes"), list) else []:
            if isinstance(n, dict) and isinstance(n.get("id"), str) and (name, n["id"]) not in self.nodes:
                self.nodes[(name, n["id"])] = n
                self.order.append((name, n["id"]))
        for e in doc.get("edges") if isinstance(doc.get("edges"), list) else []:
            if isinstance(e, dict) and isinstance(e.get("from"), str) and isinstance(e.get("to"), str):
                self._link(e.get("edge_type"), (name, e["from"]), (name, e["to"]), None, None)
        for e in doc.get("external_edges") if isinstance(doc.get("external_edges"), list) else []:
            if not isinstance(e, dict):
                continue
            src, dst = self._end(name, e.get("from")), self._end(name, e.get("to"))
            self._link(e.get("edge_type"), src, dst, e.get("from"), e.get("to"))

    @staticmethod
    def _end(name, ref):
        """A ponta de uma aresta externa: <caminho>#<id> vira (caminho, id); um id local, (arquivo, id); ausente (o grafo
        inteiro como origem), (arquivo, None)."""
        if kg_validate.is_external(ref):
            path, nid = ref.rsplit("#", 1)
            return (path, nid)
        return (name, ref if isinstance(ref, str) else None)

    def _link(self, edge_type, src, dst, src_ref, dst_ref):
        et = edge_type if isinstance(edge_type, str) else None
        if src[1] is not None:  # o grafo inteiro como origem não pendura a aresta em nó nenhum
            self.out[src].append((et, dst, dst_ref))
        if dst[1] is not None:
            self.into[dst].append((et, src, src_ref))


def load(root=None, files=(), exclude=()):
    """O corpus de --root (os rastreados pelo git, ou todos sob a pasta) ou dos arquivos dados. exclude: padrões glob
    sobre o caminho relativo (export/*, *.kg.yaml) que ficam de fora. ValueError: entrada quebrada."""
    corpus = Corpus()
    if root is not None:
        base = pathlib.Path(root)
        if not base.is_dir():
            raise ValueError(f"--root {root} não é um diretório")
        out = subprocess.run(["git", "-C", str(base), "ls-files", "-z", "--", "*.kg.yaml", "*.kg.json"], capture_output=True)
        if out.returncode == 0:
            names = [n for n in out.stdout.decode("utf-8").split("\0") if n]
        else:
            names = sorted(p.relative_to(base).as_posix() for g in ("*.kg.yaml", "*.kg.json") for p in base.rglob(g)
                           if ".git" not in p.relative_to(base).parts)
        for name in names:
            if any(fnmatch.fnmatchcase(name, pat) for pat in exclude):
                continue
            path = base / name
            if not path.is_file():
                continue
            try:
                corpus.add(name, path.read_text(encoding="utf-8"))
            except (OSError, UnicodeDecodeError) as exc:
                corpus.unreadable.append({"file": name, "code": f"io.{type(exc).__name__}"})
    for name in files:
        with open(name, encoding="utf-8") as fh:
            corpus.add(pathlib.PurePath(name).as_posix(), fh.read())
    return corpus


def resolve(corpus, ref):
    """Um id dado na linha de comando: <caminho>#<id> ou o id sozinho, que tem de ser único no corpus. ValueError."""
    if "#" in ref:
        path, nid = ref.rsplit("#", 1)
        if (path, nid) not in corpus.nodes:
            raise ValueError(f"--around {ref}: o nó não existe no corpus")
        return (path, nid)
    hits = [k for k in corpus.order if k[1] == ref]
    if not hits:
        raise ValueError(f"--around {ref}: o nó não existe no corpus")
    if len(hits) > 1:
        raise ValueError(f"--around {ref}: o id existe em {len(hits)} grafos; use <caminho>#{ref}")
    return hits[0]


def neighborhood(corpus, start, depth, edge_types, direction):
    """As chaves alcançadas a partir de start (inclusive) em até depth saltos, pelos tipos e na direção pedidos. Só
    entra nó que existe no corpus; a ponta que falta aparece na projeção, como found: false."""
    seen, frontier = {start}, [start]
    for _ in range(depth):
        if not frontier:  # nada mais a alcançar: um --depth enorme não gira em vão
            break
        nxt = []
        for key in frontier:
            hops = (corpus.out[key] if direction in ("out", "both") else []) + \
                   (corpus.into[key] if direction in ("in", "both") else [])
            for et, other, _ in hops:
                if other in seen or other not in corpus.nodes:
                    continue
                if edge_types and et not in edge_types:
                    continue
                seen.add(other)
                nxt.append(other)
        frontier = nxt
    return seen


def _text(node, key):
    v = node.get(key)
    return v if isinstance(v, str) else ""


def matches(node, key, f):
    if f["ids"] and key[1] not in f["ids"]:
        return False
    if f["id_prefix"] and not key[1].startswith(f["id_prefix"]):
        return False
    for field in ("node_type", "status", "plane", "layer"):
        if f[field] is not None and node.get(field) != f[field]:
            return False
    if f["file"] and f["file"] not in key[0]:
        return False
    if f["text"]:
        hay = _text(node, "label") + ("\n" + _text(node, "narrative") if f["in_narrative"] else "")
        hay = hay.casefold()
        if not all(w in hay for w in f["text"].casefold().split()):
            return False
    if f["verified_before"] is not None:
        day = kg_validate.iso_date(node.get("verified_at")) if isinstance(node.get("verified_at"), str) else None
        if day is not None and day >= f["verified_before"]:
            return False
    return True


def _end_view(corpus, key, ref):
    if key[1] is None:  # a origem ausente de uma aresta externa: o grafo inteiro
        return {"file": key[0], "id": None, "label": None, "external": False, "found": True}
    node = corpus.nodes.get(key)
    label = _text(node, "label") if node else None
    if label is not None and len(label) > END_LABEL_MAX:
        label = label[:END_LABEL_MAX - 1] + "…"
    return {"file": key[0], "id": key[1], "label": label,
            "external": ref is not None and kg_validate.is_external(ref), "found": node is not None}


def _plain(v):
    """O valor como JSON: o .nan/.inf do YAML (kg_validate.NonFinite) sai como o texto dele, sem derrubar a saída."""
    if isinstance(v, kg_validate.NonFinite):
        return v.text
    if isinstance(v, dict):
        return {k: _plain(x) for k, x in v.items()}
    if isinstance(v, list):
        return [_plain(x) for x in v]
    return v


def project(corpus, key, narrative=False, fields=()):
    """O nó como a consulta o entrega: os campos do contrato que interessam a quem lê e as arestas resolvidas. fields:
    padrões glob de chaves do nó (x_*, owner) que saem em extra, com o valor como está no grafo."""
    node = corpus.nodes[key]
    out = {"file": key[0], "id": key[1], "label": _text(node, "label") or None}
    for field in NODE_FIELDS:
        out[field] = node.get(field) if isinstance(node.get(field), (str, int, float)) and \
            not isinstance(node.get(field), bool) else None
    if narrative:
        out["narrative"] = _text(node, "narrative") or None
    if fields:
        out["extra"] = {k: _plain(v) for k, v in node.items() if any(fnmatch.fnmatchcase(k, pat) for pat in fields)}
    out["out"] = [{"edge_type": et, "to": _end_view(corpus, other, ref)} for et, other, ref in corpus.out[key]]
    out["in"] = [{"edge_type": et, "from": _end_view(corpus, other, ref)} for et, other, ref in corpus.into[key]]
    return out


def query(corpus, *, ids=(), id_prefix=None, node_type=None, status=None, plane=None, layer=None, file=None, text=None,
          in_narrative=False, open_only=False, verified_before=None, around=None, depth=1, edge_types=(),
          direction="both", sort="corpus", limit=50, cursor=None, narrative=False, fields=(), max_bytes=None):
    """A consulta inteira, no formato kg-ssot.query/1. ValueError: pedido quebrado. max_bytes: o teto da página em bytes
    de JSON (o servidor MCP passa o dele); a página corta antes do limit quando o passa, sempre com ao menos um nó, e o
    next_cursor continua de onde ela parou."""
    if not 1 <= limit <= MAX_LIMIT:
        raise ValueError(f"--limit tem de estar entre 1 e {MAX_LIMIT}")
    if depth < 0:
        raise ValueError("--depth tem de ser 0 ou mais")
    if direction not in ("out", "in", "both"):
        raise ValueError("--direction é out, in ou both")
    if sort not in ("corpus", "impact"):
        raise ValueError("--sort é corpus ou impact")
    offset = 0
    if cursor is not None:
        if not (isinstance(cursor, str) and cursor.isascii() and cursor.isdigit() and len(cursor) <= 9):
            raise ValueError(f"--cursor {cursor!r} inválido: use o next_cursor de uma consulta anterior")
        offset = int(cursor)
    f = {"ids": set(ids), "id_prefix": id_prefix, "node_type": node_type, "status": "open" if open_only else status,
         "plane": plane, "layer": layer, "file": file, "text": text, "in_narrative": in_narrative,
         "verified_before": verified_before}
    if open_only and status not in (None, "open"):
        raise ValueError("--open e --status pedem status diferentes")
    keys = corpus.order
    if around is not None:
        reach = neighborhood(corpus, resolve(corpus, around), depth, set(edge_types), direction)
        keys = [k for k in keys if k in reach]
    hits = [k for k in keys if matches(corpus.nodes[k], k, f)]
    if sort == "impact":
        rank = {k: i for i, k in enumerate(corpus.order)}

        def impact(k):
            v = corpus.nodes[k].get("impact")
            return v if isinstance(v, (int, float)) and not isinstance(v, bool) else float("-inf")
        hits.sort(key=lambda k: (-impact(k), rank[k]))
    page, size = [], 0
    for k in hits[offset:offset + limit]:
        node = project(corpus, k, narrative, fields)
        size += len(json.dumps(node, ensure_ascii=False))
        if page and max_bytes is not None and size > max_bytes:
            break
        page.append(node)
    end = offset + len(page)
    nxt = end if end < len(hits) else None
    request = {"ids": sorted(f["ids"]), "id_prefix": id_prefix, "node_type": node_type, "status": f["status"],
               "plane": plane, "layer": layer, "file": file, "text": text, "in_narrative": in_narrative,
               "verified_before": verified_before.isoformat() if verified_before else None, "around": around,
               "depth": depth if around is not None else None, "edge_types": sorted(set(edge_types)) if around else [],
               "direction": direction if around is not None else None, "sort": sort, "limit": limit, "cursor": cursor,
               "fields": list(fields)}
    unreadable = [u for u in corpus.unreadable if not file or file in u["file"]]
    return {"schema_version": SCHEMA_VERSION, "query": request, "graphs": len(corpus.files),
            "unreadable": unreadable, "total": len(hits), "next_cursor": str(nxt) if nxt is not None else None,
            "nodes": page}


def human(res):
    lines = []
    for n in res["nodes"]:
        tag = "/".join(str(n[k]) for k in ("node_type", "status", "plane") if n[k] is not None)
        imp = f" imp={n['impact']}" if n["impact"] is not None else ""
        label = (n["label"] or "").replace("\n", " ")
        lines.append(f"{n['file']}  {n['id']}  {tag}{imp}  {label[:160]}")
        for e in n["out"]:
            t = e["to"]
            where = "" if t["file"] == n["file"] else f"{t['file']}#"
            miss = "" if t["found"] else "  (fora do corpus)"
            lines.append(f"    → {e['edge_type']} {where}{t['id']}{miss}  {(t['label'] or '')[:100]}")
        for e in n["in"]:
            s = e["from"]
            where = "" if s["file"] == n["file"] else f"{s['file']}#"
            src = f"{s['file']} (o grafo inteiro)" if s["id"] is None else where + s["id"]
            miss = "" if s["found"] else "  (fora do corpus)"
            lines.append(f"    ← {e['edge_type']} {src}{miss}  {(s['label'] or '')[:100]}")
    for u in res["unreadable"][:5]:
        lines.append(f"NÃO LIDO  {u['file']}: {u['code']}")
    if len(res["unreadable"]) > 5:
        lines.append(f"NÃO LIDO  e mais {len(res['unreadable']) - 5} grafo(s) (a lista inteira sai em --format json)")
    shown = len(res["nodes"])
    first = int(res["query"]["cursor"] or 0)
    tail = f"; próxima página: --cursor {res['next_cursor']}" if res["next_cursor"] else ""
    lines.append(f"· {res['total']} nó(s) em {res['graphs']} grafo(s)"
                 + (f", mostrando {first + 1} a {first + shown}" if shown else "") + tail)
    return "\n".join(lines)


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n", 1)[0])
    ap.add_argument("files", nargs="*", help="arquivos .kg.yaml ou .kg.json (ou --root)")
    ap.add_argument("--root", help="a raiz do corpus: os grafos rastreados pelo git sob ela")
    ap.add_argument("--id", action="append", default=[], dest="ids", help="id exato (repetível)")
    ap.add_argument("--id-prefix")
    ap.add_argument("--type", dest="node_type")
    ap.add_argument("--status")
    ap.add_argument("--plane")
    ap.add_argument("--layer")
    ap.add_argument("--file", help="só os grafos cujo caminho contém este trecho")
    ap.add_argument("--text", help="palavras que o label contém, todas, sem distinguir maiúscula")
    ap.add_argument("--in-narrative", action="store_true", help="--text procura também na narrative")
    ap.add_argument("--open", action="store_true", dest="open_only", help="a fila dos abertos (status open)")
    ap.add_argument("--verified-before", metavar="AAAA-MM-DD", help="sem verified_at, ou conferido antes da data")
    ap.add_argument("--around", metavar="ID", help="a vizinhança do nó (<caminho>#<id>, ou o id único no corpus)")
    ap.add_argument("--depth", type=int, default=1)
    ap.add_argument("--edge-type", action="append", default=[], dest="edge_types")
    ap.add_argument("--direction", default="both", choices=("out", "in", "both"))
    ap.add_argument("--sort", default="corpus", choices=("corpus", "impact"))
    ap.add_argument("--limit", type=int, default=50)
    ap.add_argument("--cursor")
    ap.add_argument("--narrative", action="store_true", help="inclui a narrative de cada nó")
    ap.add_argument("--fields", action="append", default=[], metavar="GLOB",
                    help="chaves do nó que saem em extra (repetível): x_*, owner")
    ap.add_argument("--exclude", action="append", default=[], metavar="GLOB",
                    help="com --root, caminhos que ficam de fora (repetível): export/*")
    ap.add_argument("--format", default="human", choices=("human", "json"))
    args = ap.parse_args(argv)

    def broken(msg):
        print(f"ENTRADA QUEBRADA  {msg}", file=sys.stderr)
        return 2
    if bool(args.root) == bool(args.files):
        return broken("dê --root ou os arquivos, um dos dois")
    before = None
    if args.verified_before is not None:
        before = kg_validate.iso_date(args.verified_before)
        if before is None:
            return broken(f"--verified-before {args.verified_before!r}: a data é AAAA-MM-DD")
    try:
        corpus = load(args.root, args.files, args.exclude)
        res = query(corpus, ids=args.ids, id_prefix=args.id_prefix, node_type=args.node_type, status=args.status,
                    plane=args.plane, layer=args.layer, file=args.file, text=args.text, in_narrative=args.in_narrative,
                    open_only=args.open_only, verified_before=before, around=args.around, depth=args.depth,
                    edge_types=args.edge_types, direction=args.direction, sort=args.sort, limit=args.limit,
                    cursor=args.cursor, narrative=args.narrative, fields=args.fields)
    except (OSError, ValueError, UnicodeDecodeError) as exc:
        return broken(exc)
    text = json.dumps(res, ensure_ascii=False, indent=1) if args.format == "json" else human(res)
    # o surrogate solto (\ud800, que o contrato só avisa) não é UTF-8: sai como o escape \ud800, que no JSON é o mesmo valor
    print(text.encode("utf-8", "backslashreplace").decode("utf-8"))
    return 0


if __name__ == "__main__":
    sys.exit(main())
