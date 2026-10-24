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
rc: 0 todo trace julgável resolve · 1 integrity.trace-target-missing, ou grafo ilegível · 2 entrada quebrada.
"""
import argparse
import json
import pathlib
import re
import subprocess
import sys

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
    text = trace.strip().strip("\"'").strip()
    if text.startswith("/") or re.match(r"[A-Za-z][A-Za-z0-9+.-]*://", text):
        return "absolute", text
    original = re.split(r"[#:]", text, 1)[0].strip().strip("\"'").strip()
    if any(original.startswith(p) for p in external_roots):
        return "external_root", original
    if not original or not PATH_CHARS.fullmatch(original):
        return "not_path", original
    target = original
    while target.startswith("./"):
        target = target[2:]
    if not target:
        return "not_path", original
    gdir = pathlib.PurePosixPath(graph_dir)
    root_file = False
    if "/" not in original:  # nome solto: só o arquivo rastreado da raiz, com o nome exato, e sem homônimo vizinho
        if target in root_files and (root / target).is_file():
            root_file = True
            if str(gdir) != "." and ((root / gdir / target).exists() or (root / gdir.parent / target).exists()):
                root_file = False
        if not root_file:
            return "not_path", original
    first = original.split("/", 1)[0]
    if not root_file and not first.startswith(".") and "." in first:
        return "not_path", original  # um hostname: support.example.com/...
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
            return "resolved", target
    return "missing", target


def check(corpus, root, external_roots=()):
    """{graphs, judged, resolved, missing: [...], skipped: {absolute, external_root, not_path, not_text}}. O trace que
    não é texto (lista, mapa, número) entra em not_text: o gate já o reprova (form.type), e aqui ele não some."""
    root = pathlib.Path(root)
    root_files = tracked_root_files(root)
    res = {"graphs": len(corpus.files) - len(corpus.unreadable), "judged": 0, "resolved": 0, "missing": [],
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
        kind, target = classify(trace, pathlib.PurePosixPath(key[0]).parent.as_posix(), root, root_files,
                                external_roots)
        if kind in res["skipped"]:
            res["skipped"][kind] += 1
            continue
        res["judged"] += 1
        if kind == "resolved":
            res["resolved"] += 1
        else:
            res["missing"].append({"code": CODE, "file": key[0], "id": key[1],
                                   "node_type": node.get("node_type") if isinstance(node.get("node_type"), str)
                                   else None, "target": target})
    return res


def main(argv=None):
    ap = argparse.ArgumentParser(description=_("The trace that does not resolve: each node's trace: anchor against "
                                               "the files of the repository."))
    ap.add_argument("command", choices=("check",))
    ap.add_argument("--root", default=".", help=_("the repository root (default: .)"))
    ap.add_argument("--exclude", action="append", default=[], metavar="GLOB",
                    help=_("paths to leave out (repeatable), added to the defaults"))
    ap.add_argument("--no-default-excludes", action="store_true", help=_("also read the vendor and the fixtures"))
    ap.add_argument("--external-root", action="append", default=[], metavar=_("PREFIX"),
                    help=_("a trace prefix that lives outside the repository (repeatable), counted apart"))
    ap.add_argument("--format", default="human", choices=("human", "json"))
    args = ap.parse_args(argv)
    kg_validate._utf8_stdio()
    if not pathlib.Path(args.root).is_dir():
        print(_("BROKEN INPUT  {error}").format(error=_("--root {root} is not a directory").format(root=args.root)),
              file=sys.stderr)
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
        for u in corpus.unreadable:
            print(_("UNREADABLE  {file}  {code}").format(file=u["file"], code=u["code"]))
        s = res["skipped"]
        if not res["graphs"]:  # nenhum grafo lido não é "todo trace resolve"
            print(_("· no graph read: git tracks no .kg.yaml or .kg.json under {root} outside the excludes").format(
                root=args.root))
        print(_("· {judged} trace(s) judged: {resolved} resolve, {missing} missing; not judged (counted): {absolute} "
                "absolute or URL, {external} external root, {not_path} not a path, {not_text} not text").format(
                    judged=res["judged"], resolved=res["resolved"], missing=len(res["missing"]),
                    absolute=s["absolute"], external=s["external_root"], not_path=s["not_path"],
                    not_text=s["not_text"]))
    return 1 if res["missing"] or corpus.unreadable else 0


if __name__ == "__main__":
    sys.exit(main())
