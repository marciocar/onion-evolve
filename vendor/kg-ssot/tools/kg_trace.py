#!/usr/bin/env python3
"""O trace que não resolve (release 4.25): a âncora `trace:` de um nó foi declarada, mas o arquivo existe?

O leitor do contrato não toca o disco (é o que o deixa rodar em qualquer lugar, inclusive no JS), então quem confere a
âncora é esta ferramenta, a partir da raiz do repo, como o kg_criterion.py confere o sha256. Um `trace:` que aponta
para um arquivo movido ou renomeado passa no gate e mente para quem tenta voltar ao "porquê".

O que é julgado (as regras de um resolvedor de adotante, medidas num corpus de milhares de traces; cada corte foi pago
por um falso positivo):
- só o texto do trace até o primeiro `:` (arquivo:linha, arquivo:seção) e o primeiro `#` (comentário, âncora);
- fora de julgamento, e contados à parte, nunca em silêncio:
  - absolute: caminho absoluto ou URL (outra máquina, outra rede);
  - external_root: um prefixo declarado com --external-root (um diretório fora do repo, como a memória da sessão);
  - not_path: o texto que não parece caminho: um caractere fora de [A-Za-z0-9_./-] (comando, prosa), um nome sem
    barra (palavra solta, chave de config), ou o primeiro segmento com ponto e sem começar por ponto (um hostname,
    como support.example.com/...);
- a exceção do nome sem barra: o arquivo rastreado na raiz do repo, com o nome EXATO (`ARCHITECTURE.md`), entra; se o mesmo
  nome existe ao lado do grafo ou no pai dele, é ambíguo e fica de fora;
- `./x` e `x` são o mesmo alvo, mas as regras leem o texto original.
Resolve quando o alvo existe numa de três raízes: a do repo, a pasta do grafo e a pasta pai do grafo (esta só quando o
grafo não está na raiz). Um alvo que sai da raiz (`../irmão/x`) não resolve: no clone do CI ele não existe.

Lê os .kg.yaml e .kg.json que o git rastreia sob a raiz, fora do vendor, de docs/materials/ e das pastas de fixture
(fixture/, fixtures/, __fixtures__/, testdata/, __snapshots__/, em qualquer nível); --exclude soma padrões, e
--no-default-excludes tira os padrões. Um corpus que ancora numa pasta de fora (a memória de uma sessão) fica
vermelho até que ela seja declarada com --external-root. O trace que não é texto sai em not_text, e o nó com id
repetido ou fora de texto, que o gate já reprova no MUST, não é lido aqui.

Uso:
  kg_trace.py check [--root DIR] [--exclude GLOB]... [--no-default-excludes] [--external-root PREFIXO]...
                    [--format human|json]
rc: 0 todo trace julgável resolve · 1 integrity.trace-target-missing, ou grafo ilegível · 2 entrada quebrada · 3 nenhum
grafo lido (desde a 4.27: o corpus vazio não passa por "todo trace resolve" num CI que só olha o rc).
"""
import argparse
import json
import pathlib
import re
import subprocess
import sys
import urllib.parse
import fnmatch

import yaml

sys.dont_write_bytecode = True
if __package__:  # no pacote kg_ssot, o vizinho vem pelo pacote, sem mexer no sys.path de quem importa
    from . import kg_i18n, kg_query, kg_validate
else:  # script ou vendor
    sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
    import kg_i18n  # noqa: E402
    import kg_query  # noqa: E402
    import kg_validate  # noqa: E402
_ = kg_i18n._

SCHEMA_VERSION = "kg-ssot.trace/1"
LOCATOR_MISSING = "integrity.trace-locator-missing"
LOCATOR_UNREADABLE = "integrity.trace-locator-unreadable"
INDEX = re.compile(r"0|[1-9][0-9]*")
PROJECTION_SCHEMA = "kg-ssot.projection/1"
PROJECTION_MISSING = "integrity.projection-id-missing"
CITED_ID = re.compile(r"`([A-Z][A-Z0-9]*(?:_[A-Z0-9]+)+)`")
FRONTMATTER = re.compile(r"\A---[ \t]*\r?\n(.*?)\r?\n---[ \t]*(?:\r?\n|\Z)", re.S)
PATH_CHARS = re.compile(r"[A-Za-z0-9_./-]+")
CODE = "integrity.trace-target-missing"
# as pastas de fixture que um adotante usa (Vitest, Go, Jest), além das do kg_query: um grafo inválido de propósito
# ali não é âncora de ninguém (o incidente que pagou a regra: 5 grafos de __fixtures__/ viraram achado no dia 1)
FIXTURE_SEGMENTS = {"fixture", "fixtures", "__fixtures__", "testdata", "__snapshots__"}


def tracked_root_files(root):
    """Os arquivos rastreados na raiz do repo (sem barra no nome), para a exceção do nome exato; sem git, os arquivos
    regulares da raiz."""
    out = subprocess.run(["git", "-C", str(root), "ls-files", "-z"], capture_output=True)
    if out.returncode == 0:
        return {n for n in out.stdout.decode("utf-8", "surrogateescape").split("\0") if n and "/" not in n}
    return {p.name for p in pathlib.Path(root).iterdir() if p.is_file()}


def classify(trace, graph_dir, root, root_files, external_roots=()):
    """(classe, alvo): classe é absolute, external_root, not_path, resolved ou missing; o alvo é o texto julgado."""
    return locate(trace, graph_dir, root, root_files, external_roots)[:2]


def locate(trace, graph_dir, root, root_files, external_roots=()):
    """(classe, alvo, caminho), desde a 4.25.1: o de classify() e, só no resolved, o arquivo que o check viu existir,
    relativo à raiz, com os links seguidos (um link seguido de .. não pode apontar para outro arquivo), e se ele é
    file ou dir."""
    text = trace.strip().strip("\"'").strip()
    if text.startswith("/") or re.match(r"[A-Za-z][A-Za-z0-9+.-]*://", text):
        return "absolute", text, None
    original = re.split(r"[#:]", text, 1)[0].strip().strip("\"'").strip()
    if any(original.startswith(p) for p in external_roots):
        return "external_root", original, None
    if not original or not PATH_CHARS.fullmatch(original):
        return "not_path", original, None
    target = original
    while target.startswith("./"):
        target = target[2:]
    if not target:
        return "not_path", original, None
    gdir = pathlib.PurePosixPath(graph_dir)
    root_file = False
    if "/" not in original:  # nome solto: só o arquivo rastreado da raiz, com o nome exato, e sem homônimo vizinho
        if target in root_files and (root / target).is_file():
            root_file = True
            if str(gdir) != "." and ((root / gdir / target).exists() or (root / gdir.parent / target).exists()):
                root_file = False
        if not root_file:
            return "not_path", original, None
    first = original.split("/", 1)[0]
    if not root_file and not first.startswith(".") and "." in first:
        return "not_path", original, None  # um hostname: support.example.com/...
    base = root.resolve()
    candidates = [root / target, root / gdir / target]
    if str(gdir) != ".":
        candidates.append(root / gdir.parent / target)
    for c in candidates:
        try:
            full = c.resolve()
        except (OSError, RuntimeError):
            continue
        if (full == base or base in full.parents) and full.exists():  # fora da raiz não resolve: o CI não o tem
            return "resolved", target, (full.relative_to(base).as_posix() or ".", "dir" if full.is_dir() else "file")
    return "missing", target, None


def resolve_pointer(doc, locator):
    """True quando o JSON Pointer em fragmento (#, #/a/0, RFC 6901) resolve em doc: o fragmento perde o
    percent-encoding, cada token troca ~1 por / e ~0 por ~, objeto por chave e lista por índice decimal sem zero à
    esquerda (desde a 4.35.0)."""
    frag = urllib.parse.unquote(locator[1:])
    if frag == "":
        return True
    cur = doc
    for token in frag.split("/")[1:]:
        token = token.replace("~1", "/").replace("~0", "~")
        if isinstance(cur, dict) and token in cur:
            cur = cur[token]
        elif isinstance(cur, list) and INDEX.fullmatch(token) and int(token) < len(cur):
            cur = cur[int(token)]
        else:
            return False
    return True


def locate_source(source, graph_dir, root):
    """(classe, alvo, caminho) do provenance.source como caminho do repo, para o locator: diferente do trace, o nome
    solto com extensão (gone.json) é caminho, porque a fonte não é prosa; absolute para URL ou caminho absoluto;
    not_path para o texto que não parece arquivo (a fala de alguém); outside_root para o que sai da raiz (contado,
    não julgado); resolved ou missing contra a raiz, a pasta do grafo e a pasta pai dele."""
    text = source.strip().strip("\"'").strip()
    if text.startswith("/") or re.match(r"[A-Za-z][A-Za-z0-9+.-]*://", text):
        return "absolute", text, None
    target = re.split(r"[#:]", text, 1)[0].strip()
    while target.startswith("./"):
        target = target[2:]
    if not target or not PATH_CHARS.fullmatch(target) or "." not in target.rsplit("/", 1)[-1]:
        return "not_path", target, None
    base = pathlib.Path(root).resolve()
    gdir = pathlib.PurePosixPath(graph_dir)
    candidates = [root / target, root / gdir / target] + ([root / gdir.parent / target] if str(gdir) != "." else [])
    inside = False
    for c in candidates:
        try:
            full = pathlib.Path(c).resolve()
        except (OSError, RuntimeError):
            continue
        if full != base and base not in full.parents:
            continue
        inside = True
        if full.exists():
            return "resolved", target, (full.relative_to(base).as_posix(), "dir" if full.is_dir() else "file")
    return ("missing" if inside else "outside_root"), target, None


def check_locators(corpus, root, root_files, external_roots=()):
    """O provenance.locator que é JSON Pointer (#/...) contra o .json do repo que o nó nomeia: o do provenance.source
    quando ele é caminho do repo, senão o do trace (desde a 4.35.0). O que não se julga é contado: not_pointer (locator
    que não é ponteiro), absolute (fonte por URL ou caminho absoluto, sem caminho do repo) e no_json_file (o arquivo não
    é um .json do repo que existe)."""
    res = {"judged": 0, "resolved": 0, "missing": [], "unreadable": [],
           "skipped": {"not_pointer": 0, "absolute": 0, "no_json_file": 0, "outside_root": 0}}
    cache = {}
    for key in corpus.order:
        node = corpus.nodes[key]
        prov = node.get("provenance")
        locator = prov.get("locator") if isinstance(prov, dict) else None
        if not isinstance(locator, str) or not locator.strip():
            continue
        locator = locator.strip()
        if not (locator == "#" or locator.startswith("#/")):
            res["skipped"]["not_pointer"] += 1
            continue
        gdir = pathlib.PurePosixPath(key[0]).parent.as_posix()
        path, absolute, gone, outside = None, False, None, False
        for which, anchor in (("source", prov.get("source")), ("trace", node.get("trace"))):
            if not isinstance(anchor, str) or not anchor.strip():
                continue  # o locator é da fonte: o source manda quando é caminho, e o trace só vale sem ele
            if which == "source":
                kind, target, found = locate_source(anchor, gdir, root)
            else:
                kind, target, found = locate(anchor, gdir, root, root_files, external_roots)
            if kind == "absolute":
                absolute = True
                continue
            if kind == "outside_root":
                outside = True
                break
            if kind == "resolved":
                if found[1] == "file" and found[0].lower().endswith(".json"):
                    path = found[0]
                break  # um caminho do repo que existe e não é .json: o locator não é JSON Pointer dele
            if kind == "missing":
                gone = target  # o arquivo da fonte sumiu: o locator não se julga em outro arquivo
                break
        if outside:
            res["skipped"]["outside_root"] += 1
            continue
        if gone is not None:
            res["judged"] += 1
            res["missing"].append({"code": LOCATOR_MISSING, "file": key[0], "id": key[1], "target": gone,
                                   "locator": locator})
            continue
        if path is None:
            res["skipped"]["absolute" if absolute else "no_json_file"] += 1
            continue
        res["judged"] += 1
        if path not in cache:
            try:
                cache[path] = (True, json.loads((pathlib.Path(root) / path).read_text(encoding="utf-8-sig")))
            except (OSError, ValueError, UnicodeDecodeError):
                cache[path] = (False, None)
        ok, doc = cache[path]
        entry = {"file": key[0], "id": key[1], "target": path, "locator": locator}
        if not ok:
            res["unreadable"].append({"code": LOCATOR_UNREADABLE, **entry})
        elif resolve_pointer(doc, locator):
            res["resolved"] += 1
        else:
            res["missing"].append({"code": LOCATOR_MISSING, **entry})
    return res


def contract_words():
    """O vocabulário do contrato em maiúsculas (os tipos de aresta e os valores de enum na forma de id), que uma página
    cita entre crases sem ser id de nó."""
    words = set()

    def walk(o):
        if isinstance(o, dict):
            for v in o.values():
                walk(v)
        elif isinstance(o, list):
            for v in o:
                walk(v)
        elif isinstance(o, str) and re.fullmatch(r"[A-Z][A-Z0-9]*(?:_[A-Z0-9]+)+", o):
            words.add(o)
    walk(json.loads(kg_validate.CONTRACT_MUST.read_text(encoding="utf-8")))
    return words


def projection(root, pages, withs=(), exclude=(), defaults=True):
    """O checador de projeção (4.35.0): cada página .md com projection_of no frontmatter, e cada id que ela cita entre
    crases, contra os grafos que ela declara. Os baldes: resolved (num grafo do projection_of), elsewhere (em outro
    grafo do corpus, não declarado: aviso), outside (o projection_of declara uma URL de outro repositório que o --with
    não carregou: não julgado) e missing (integrity.projection-id-missing). Ficam fora, contados: o vocabulário do
    contrato e o projection_ignore da página. ValueError: frontmatter que não se lê ou --root que não é pasta."""
    root = pathlib.Path(root)
    if not root.is_dir():
        raise ValueError(_("--root {root} is not a directory").format(root=root))
    corpus = kg_query.load(str(root), (), exclude, defaults)
    corpus.withs = list(withs)
    every = {}
    for f, i in corpus.order:
        every.setdefault(i, []).append(f)
    if not pages:
        out = subprocess.run(["git", "-C", str(root), "ls-files", "-z", "--", "*.md"], capture_output=True)
        pages = [n for n in out.stdout.decode("utf-8", "surrogateescape").split("\0") if n
                 and not any(fnmatch.fnmatch(n, g) for g in (kg_query.DEFAULT_EXCLUDE if defaults else ()) + tuple(exclude))]
        explicit = False
    else:
        explicit = True
    words = contract_words()
    res = {"pages": 0, "cited": 0, "resolved": 0, "elsewhere": [], "outside": [], "missing": [], "graph_errors": [],
           "unpinned": [], "uncited": [],
           "skipped": {"contract": 0, "ignored": 0, "no_projection": 0}}
    for page in pages:
        try:
            raw = (root / page).read_bytes()
        except OSError:
            if explicit:
                raise ValueError(_("{page}: the page does not read").format(page=page))
            continue  # rastreada e apagada da árvore: na varredura, não é página
        text = raw.decode("utf-8", "replace").lstrip("\ufeff")
        m = FRONTMATTER.match(text)
        if not explicit and (not m or "projection_of" not in m.group(1)):
            continue  # na varredura, só a página que declara projeção: o frontmatter alheio não é julgado
        try:
            meta = yaml.safe_load(m.group(1)) if m else None
        except yaml.YAMLError as exc:
            raise ValueError(_("{page}: the front matter does not read ({error})").format(page=page, error=exc))
        if b"\xef\xbf\xbd" not in raw and "\ufffd" in text:
            raise ValueError(_("{page}: the page is not UTF-8").format(page=page))
        decl = meta.get("projection_of") if isinstance(meta, dict) else None
        if not decl:  # ausente, ou declarado vazio: contado, nunca em silêncio
            if explicit or (isinstance(meta, dict) and "projection_of" in meta):
                res["skipped"]["no_projection"] += 1
            continue
        if isinstance(decl, str):
            decl = [decl]
        ignore = meta.get("projection_ignore") or []
        if not isinstance(decl, list) or not all(isinstance(d, str) for d in decl) or not isinstance(ignore, list):
            raise ValueError(_("{page}: projection_of and projection_ignore are lists of text").format(page=page))
        res["pages"] += 1
        files, unloaded = set(), []
        for d in decl:
            d = d.strip()
            if "://" in d:
                got = kg_query.load_external(corpus, d)
                if got:
                    files.add(d)
                    if not corpus.external[d]["pinned"] and d not in res["unpinned"]:
                        res["unpinned"].append(d)  # lido da árvore: o ref da URL não está na pasta do --with
                elif got is False:  # o --with cobre a URL, e o grafo não se lê: é erro, não "outro repositório"
                    res["graph_errors"].append({"page": page, "graph": d})
                else:
                    unloaded.append(d)
                continue
            rel = d
            while rel.startswith("./"):
                rel = rel[2:]
            if rel in corpus.files and not any(u["file"] == rel for u in corpus.unreadable):
                files.add(rel)
            else:
                res["graph_errors"].append({"page": page, "graph": d})
        known = {i for f, i in corpus.order if f in files}
        body = text[m.end():] if m else text
        found = list(dict.fromkeys(CITED_ID.findall(body)))
        if not found:  # declara projeção e não cita id entre crases: nada foi conferido, e isso não passa calado
            res["uncited"].append(page)
        for cited in found:
            if cited in words:
                res["skipped"]["contract"] += 1
                continue
            if cited in ignore:
                res["skipped"]["ignored"] += 1
                continue
            res["cited"] += 1
            entry = {"page": page, "id": cited}
            if cited in known:
                res["resolved"] += 1
            elif cited in every:
                res["elsewhere"].append({**entry, "graphs": sorted(set(every[cited]))[:5]})
            elif unloaded:
                res["outside"].append({**entry, "declared": unloaded})
            else:
                res["missing"].append({"code": PROJECTION_MISSING, **entry})
    return res


def check(corpus, root, external_roots=()):
    """{graphs, judged, resolved, resolved_targets: [...], missing: [...], skipped: {absolute, external_root, not_path,
    not_text}}. O trace que não é texto (lista, mapa, número) entra em not_text: o gate já o reprova (form.type), e
    aqui ele não some. resolved_targets (desde a 4.25.1) diz onde cada trace resolvido mora, para quem monta um índice
    de leitura a partir dele."""
    root = pathlib.Path(root)
    root_files = tracked_root_files(root)
    res = {"graphs": len(corpus.files) - len(corpus.unreadable), "judged": 0, "resolved": 0, "resolved_targets": [],
           "missing": [],
           "skipped": {"absolute": 0, "external_root": 0, "not_path": 0, "not_text": 0}}
    for key in corpus.order:
        node = corpus.nodes[key]
        if "trace" not in node:
            continue
        trace = node["trace"]
        if not isinstance(trace, str):
            res["skipped"]["not_text"] += 1
            continue
        if not trace.strip():
            continue
        kind, target, path = locate(trace, pathlib.PurePosixPath(key[0]).parent.as_posix(), root, root_files,
                                external_roots)
        if kind in res["skipped"]:
            res["skipped"][kind] += 1
            continue
        res["judged"] += 1
        node_type = node.get("node_type") if isinstance(node.get("node_type"), str) else None
        if kind == "resolved":
            res["resolved"] += 1
            res["resolved_targets"].append({"file": key[0], "id": key[1], "node_type": node_type, "target": target,
                                            "path": path[0], "kind": path[1]})
        else:
            res["missing"].append({"code": CODE, "file": key[0], "id": key[1], "node_type": node_type,
                                   "target": target})
    res["locators"] = check_locators(corpus, root, root_files, external_roots)
    return res


def main(argv=None):
    ap = argparse.ArgumentParser(description=_("The trace that does not resolve: each node's trace: anchor against "
                                               "the files of the repository."))
    ap.add_argument("command", choices=("check", "projection"))
    ap.add_argument("pages", nargs="*", metavar=_("PAGE.md"),
                    help=_("projection: the pages to check (default: every tracked .md with projection_of)"))
    ap.add_argument("--with", action="append", default=[], dest="withs", metavar=_("PREFIX=FOLDER"),
                    help=_("projection: read a graph of another repository that projection_of names by URL"))
    ap.add_argument("--root", default=".", help=_("the repository root (default: .)"))
    ap.add_argument("--exclude", action="append", default=[], metavar="GLOB",
                    help=_("paths to leave out (repeatable), added to the defaults"))
    ap.add_argument("--no-default-excludes", action="store_true", help=_("also read the vendor and the fixtures"))
    ap.add_argument("--external-root", action="append", default=[], metavar=_("PREFIX"),
                    help=_("a trace prefix that lives outside the repository (repeatable), counted apart"))
    ap.add_argument("--format", default="human", choices=("human", "json"))
    args = ap.parse_intermixed_args(argv)  # as páginas podem vir depois das opções
    kg_validate._utf8_stdio()
    if not pathlib.Path(args.root).is_dir():
        print(_("BROKEN INPUT  {error}").format(error=_("--root {root} is not a directory").format(root=args.root)),
              file=sys.stderr)
        return 2
    if args.command == "projection":
        return main_projection(args)
    if args.pages or args.withs:
        print(_("BROKEN INPUT  {error}").format(error=_("pages and --with go with projection")), file=sys.stderr)
        return 2
    if any(not p or p.startswith("/") for p in args.external_root):
        print(_("BROKEN INPUT  {error}").format(error=_("--external-root takes a relative prefix")), file=sys.stderr)
        return 2
    try:
        # as pastas de fixture de outros ecossistemas, em qualquer nível, ficam de fora ANTES da leitura: um grafo
        # ilegível de propósito ali não pode virar unreadable nem contar em graphs
        fixtures = [] if args.no_default_excludes else [p for seg in sorted(FIXTURE_SEGMENTS)
                                                        for p in (f"{seg}/*", f"*/{seg}/*")]
        corpus = kg_query.load(args.root, (), list(args.exclude) + fixtures, not args.no_default_excludes)
    except (OSError, ValueError, UnicodeDecodeError) as exc:
        print(_("BROKEN INPUT  {error}").format(error=exc), file=sys.stderr)
        return 2
    res = check(corpus, args.root, args.external_root)
    if args.format == "json":
        print(json.dumps({"schema_version": SCHEMA_VERSION, **res, "unreadable": corpus.unreadable},
                         ensure_ascii=False, indent=1))
    else:
        for m in res["missing"]:
            print(f"{CODE}  {m['file']}#{m['id']}  → {m['target']}  {kg_validate.message_of(CODE)}")
        loc = res["locators"]
        for m in loc["missing"] + loc["unreadable"]:
            print(f"{m['code']}  {m['file']}#{m['id']}  → {m['target']}{m['locator']}  {kg_validate.message_of(m['code'])}")
        for u in corpus.unreadable:
            print(_("UNREADABLE  {file}  {code}").format(file=u["file"], code=u["code"]))
        if loc["judged"] or loc["skipped"]["no_json_file"] or loc["skipped"]["absolute"]:
            ls = loc["skipped"]
            print(_("· {judged} JSON locator(s) judged: {resolved} resolve, {missing} missing, {unreadable} unreadable "
                    "file; not judged (counted): {absolute} URL or absolute source, {nofile} with no JSON file of the "
                    "repository").format(judged=loc["judged"], resolved=loc["resolved"], missing=len(loc["missing"]),
                                         unreadable=len(loc["unreadable"]), absolute=ls["absolute"],
                                         nofile=ls["no_json_file"]))
        s = res["skipped"]
        if not res["graphs"] and not corpus.unreadable:  # nenhum grafo lido não é "todo trace resolve"
            print(_("· no graph read: git tracks no .kg.yaml or .kg.json under {root} outside the excludes").format(
                root=args.root))
        print(_("· {judged} trace(s) judged: {resolved} resolve, {missing} missing; not judged (counted): {absolute} "
                "absolute or URL, {external} external root, {not_path} not a path, {not_text} not text").format(
                    judged=res["judged"], resolved=res["resolved"], missing=len(res["missing"]),
                    absolute=s["absolute"], external=s["external_root"], not_path=s["not_path"],
                    not_text=s["not_text"]))
    if res["missing"] or corpus.unreadable or res["locators"]["missing"] or res["locators"]["unreadable"]:
        return 1
    return 3 if not res["graphs"] else 0  # o corpus vazio tem rc próprio: zero lido não é "tudo resolve"


def main_projection(args):
    """rc 0 sem missing · 1 com missing, ou com grafo do projection_of que não existe ou não se lê · 2 entrada quebrada."""
    try:
        withs = [kg_query.with_spec(w) for w in args.withs]
        fixtures = [] if args.no_default_excludes else [p for seg in sorted(FIXTURE_SEGMENTS)
                                                        for p in (f"{seg}/*", f"*/{seg}/*")]
        res = projection(args.root, args.pages, withs, list(args.exclude) + fixtures, not args.no_default_excludes)
    except (OSError, ValueError, UnicodeDecodeError) as exc:
        print(_("BROKEN INPUT  {error}").format(error=exc), file=sys.stderr)
        return 2
    if args.format == "json":
        print(json.dumps({"schema_version": PROJECTION_SCHEMA, **res}, ensure_ascii=False, indent=1))
    else:
        for m in res["missing"]:
            print(f"{PROJECTION_MISSING}  {m['page']}  `{m['id']}`  {kg_validate.message_of(PROJECTION_MISSING)}")
        for g in res["graph_errors"]:
            print(_("GRAPH NOT READ  {page}  projection_of: {graph}").format(page=g["page"], graph=g["graph"]))
        for page in res["uncited"]:
            print(_("· {page} declares projection_of but cites no id between backticks: nothing was checked").format(
                page=page))
        for u in res["unpinned"]:
            print(_("· {url} read from the working tree: the commit in the URL is not in that folder").format(url=u))
        for e in res["elsewhere"]:
            print(_("· {page}  `{id}` is in a graph that projection_of does not list: {graphs}").format(
                page=e["page"], id=e["id"], graphs=", ".join(e["graphs"])))
        s = res["skipped"]
        print(_("· {pages} page(s), {cited} id(s) cited: {resolved} resolve, {elsewhere} elsewhere, {outside} in "
                "another repository not read (--with), {missing} missing; not judged (counted): {contract} contract "
                "words, {ignored} in projection_ignore").format(
                    pages=res["pages"], cited=res["cited"], resolved=res["resolved"],
                    elsewhere=len(res["elsewhere"]), outside=len(res["outside"]), missing=len(res["missing"]),
                    contract=s["contract"], ignored=s["ignored"]))
    return 1 if res["missing"] or res["graph_errors"] else 0


if __name__ == "__main__":
    sys.exit(main())
