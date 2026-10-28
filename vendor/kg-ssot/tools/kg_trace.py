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
import hashlib
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
# desde a 4.37.0 (contrato v4.17): o locator lido pelo provenance.scheme e o provenance.sha256 contra a fonte
OUT_OF_RANGE = "integrity.trace-locator-out-of-range"
QUOTE_MISSING = "integrity.trace-quote-missing"
SHA_MISMATCH = "integrity.trace-sha256-mismatch"
# os códigos do scheme, e os aliases (as URIs do conformsTo do Web Annotation) para eles, como no schema SHOULD
SCHEME_ALIASES = {
    "http://tools.ietf.org/rfc/rfc6901": "json-pointer", "http://tools.ietf.org/rfc/rfc5147": "text",
    "http://tools.ietf.org/rfc/rfc7111": "csv", "http://tools.ietf.org/rfc/rfc3778": "pdf",
    "http://tools.ietf.org/rfc/rfc8118": "pdf", "http://www.w3.org/TR/media-frags/": "media",
    "http://tools.ietf.org/rfc/rfc3236": "html",
}
READ_SCHEMES = {"json-pointer", "text", "csv", "quote", "kg-node"}  # os que abrem a fonte
FORM_SCHEMES = {"pdf", "media", "html"}  # julgados só pela forma, no schema
TEXT_LOCATOR = re.compile(r"(line|char)=(?:([0-9]+)(?:,([0-9]*))?|,([0-9]+))"
                          r"(?:;length=[0-9]+(?:,[A-Za-z0-9!#$%&'+^_`{}~-]+)?)*")
_POS = r"(?:[1-9][0-9]*|\*)"
CSV_LOCATOR = re.compile(rf"(?:row|col)={_POS}(?:-{_POS})?(?:;{_POS}(?:-{_POS})?)*"
                         rf"|cell={_POS},{_POS}(?:-{_POS},{_POS})?(?:;{_POS},{_POS}(?:-{_POS},{_POS})?)*")
KG_NODE = re.compile(r"[A-Za-z][A-Za-z0-9_]*")
# a forma do json-pointer, a mesma do schema SHOULD: /a/b (RFC 6901) ou o fragmento #/a/b, sem espaço cru
JSON_POINTER = re.compile(r"(?:/(?:[^/~]|~[01])*)*|#(?:/(?:[^/~ \t\n\r]|~[01])*)*")
COMMIT_REF = re.compile(r"[0-9a-fA-F]{7,64}")  # o nome de um commit (SHA-1 ou SHA-256, abreviado ou inteiro)
SHA256 = re.compile(r"[0-9a-f]{64}")
QUOTES = ("\"\"", "''", "“”", "«»", "‘’")
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
    out = kg_query._git(str(root), "ls-files", "-z")
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


def check_locators(corpus, root, root_files, external_roots=(), located=frozenset()):
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
        if key in located:
            continue  # o check_schemes já julgou este ponteiro (4.37.0); o que ele não pôde julgar segue aqui
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


def scheme_of(prov):
    """O código do provenance.scheme (o alias vira o código), ou None sem scheme ou com um valor fora da tabela."""
    value = prov.get("scheme")
    if not isinstance(value, str):
        return None
    value = SCHEME_ALIASES.get(value, value)
    return value if value in READ_SCHEMES | FORM_SCHEMES else None


def read_source(source, gdir, root, withs, files=None):
    """(estado, alvo, bytes) da fonte que o provenance.source nomeia: ok com os bytes, absolute (URL ou caminho
    absoluto sem --with que case), missing (o arquivo não está no repo, ou não está no commit da URL), outside_root, ou
    not_path. Pelo --with, a URL <prefixo>/<ref>/<caminho> é lida no ref, de uma pasta git, com o mesmo cuidado do
    kg_query (--end-of-options: um ref que começa com - nunca vira opção). O ref que a pasta não tem é missing, e a
    pasta que não é a raiz de um clone git também (uma subpasta comum dentro de outro clone faria o git subir até ele):
    sem o git, o commit da URL não se confere, e ler a árvore julgaria outra versão da fonte em silêncio (o kg_query lê
    a árvore porque navega; aqui se verifica). O ref que não tem forma de commit (main, HEAD, uma tag) é unpinned: ele
    anda com o tempo, e o que se confere é uma fonte fixada."""
    text = source.strip().strip("\"'").strip()
    url = text.split("#", 1)[0].split("?", 1)[0]
    for prefix, folder in withs:
        if not url.startswith(prefix + "/"):
            continue
        ref, _sep, rel = url[len(prefix) + 1:].partition("/")
        while rel.startswith("./"):
            rel = rel[2:]
        if not ref or ref.startswith("-") or not rel or rel.startswith("/") or ".." in rel.split("/"):
            return "missing", url, None
        if not COMMIT_REF.fullmatch(ref):
            return "unpinned", url, None
        try:
            top = kg_query._git(folder, "rev-parse", "--show-toplevel")
            if top.returncode != 0 or pathlib.Path(top.stdout.decode("utf-8").strip()).resolve() != \
                    pathlib.Path(folder).resolve():
                return "missing", url, None
            got = kg_query._git(folder, "rev-parse", "--verify", "--quiet", "--end-of-options", f"{ref}^{{commit}}")
            if got.returncode != 0:
                return "missing", url, None
            if not got.stdout.decode("utf-8").strip().lower().startswith(ref.lower()):
                return "unpinned", url, None  # o ref resolveu para um branch ou tag de nome hexadecimal, que anda
            out = kg_query._git(folder, "show", "--end-of-options", f"{ref}:./{rel}")
            return ("ok", url, out.stdout) if out.returncode == 0 else ("missing", url, None)
        except OSError:
            return "missing", url, None
    kind, target, found = locate_source(text, gdir, root)
    if kind != "resolved":
        return kind, target, None
    if found[1] != "file":
        return "not_path", target, None
    try:
        return "ok", found[0], repo_bytes(root, found[0], files)
    except OSError:
        return "missing", target, None


def repo_bytes(root, path, cache=None):
    """Os bytes de uma fonte do repo, como o git a guarda: quando o arquivo rastreado tem o mesmo id de objeto que o
    índice (git hash-object --path, que aplica o filtro de limpeza, contra o git ls-files -s), ele é lido do blob (git
    show :caminho), e não da árvore de trabalho, porque um checkout com autocrlf (o padrão do git no Windows) troca as
    quebras de linha e o sha256 mudaria de sistema para sistema; é o mesmo conteúdo que o --with lê e que o git show dá
    a quem calcula o hash. O id é comparado, e não o git diff, que respeita os bits assume-unchanged e skip-worktree e
    calaria uma mudança no disco. O arquivo com mudança, ou fora do git, é lido do disco: a mudança é real e aparece no
    hash. cache guarda a leitura por caminho."""
    if cache is not None and path in cache:
        return cache[path]
    rel = "./" + path
    data = None
    staged = kg_query._git(str(root), "ls-files", "-s", "--", rel)
    fields = staged.stdout.decode("utf-8", "replace").split() if staged.returncode == 0 else []
    if len(fields) >= 3 and fields[2] == "0":  # um só estágio: sem conflito de merge
        mine = kg_query._git(str(root), "hash-object", f"--path={path}", "--", rel)
        if mine.returncode == 0 and mine.stdout.decode("utf-8").strip() == fields[1]:
            out = kg_query._git(str(root), "show", "--end-of-options", f":{rel}")
            if out.returncode == 0:
                data = out.stdout
    if data is None:
        data = (pathlib.Path(root) / path).read_bytes()
    if cache is not None:
        cache[path] = data
    return data


def rfc5147_text(text):
    """O texto com cada quebra de linha (CRLF, LF ou CR) como um só caractere, como manda a RFC 5147 §4.1."""
    return text.replace("\r\n", "\n").replace("\r", "\n")


def text_in_range(text, locator):
    """O locator text (RFC 5147) cabe no texto? True, False, ou None quando o locator não segue a gramática da norma.
    Posições contadas a partir de 0, como fronteiras, de 0 ao número de linhas (line) ou de caracteres (char, em code
    points), com cada quebra de linha, CRLF, LF ou CR, contada como um caractere; o início não passa do fim. O
    ;length= da norma é aceito e não é conferido (o hash vai no provenance.sha256)."""
    m = TEXT_LOCATOR.fullmatch(locator)
    if not m:
        return None
    norm = rfc5147_text(text)
    if m.group(1) == "line":
        total = norm.count("\n") + (1 if norm and not norm.endswith("\n") else 0)
    else:
        total = len(norm)
    if m.group(2) is None:  # ,N: do começo até N
        start, end = 0, int(m.group(4))
    else:
        start = int(m.group(2))
        if m.group(3) is None:  # N: uma posição só
            end = start
        elif m.group(3) == "":  # N,: de N até o fim
            end = total
        else:
            end = int(m.group(3))
    return 0 <= start <= end <= total


def csv_in_range(text, locator):
    """O locator csv (RFC 7111 §3) existe no CSV? True, False, ou None fora da gramática da norma: uma seleção é só
    row=, só col= ou só cell=, com posições a partir de 1 e * para a última. A coluna de uma célula é conferida contra
    a linha dela, não contra a maior linha do arquivo."""
    import csv as _csv
    import io
    m = CSV_LOCATOR.fullmatch(locator)
    if not m:
        return None
    rows = list(_csv.reader(io.StringIO(text)))
    nrows, ncols = len(rows), max((len(r) for r in rows), default=0)

    def pos(value, last):
        return last if value == "*" else int(value)

    kind, _eq, specs = locator.partition("=")
    for spec in specs.split(";"):
        if kind in ("row", "col"):
            total = nrows if kind == "row" else ncols
            first, _sep, second = spec.partition("-")
            lo, hi = pos(first, total), pos(second, total) if second else pos(first, total)
            if not 1 <= lo <= hi <= total:
                return False
        else:
            first, _sep, second = spec.partition("-")
            r1, c1 = first.split(",")
            r1 = pos(r1, nrows)
            if not 1 <= r1 <= nrows:
                return False
            c1 = pos(c1, len(rows[r1 - 1]))
            if not 1 <= c1 <= len(rows[r1 - 1]):
                return False
            if second:
                r2, c2 = second.split(",")
                r2 = pos(r2, nrows)
                if not r1 <= r2 <= nrows:
                    return False
                c2 = pos(c2, len(rows[r2 - 1]))
                if not c1 <= c2 <= len(rows[r2 - 1]):
                    return False
    return True


def quote_found(text, locator):
    """O texto exato do locator (sem as aspas em volta) aparece na fonte? Os espaços em sequência contam como um só,
    dos dois lados (a citação copiada de um texto quebrado em linhas). None para a citação em branco."""
    exact = locator.strip()
    for pair in QUOTES:
        if len(exact) >= 2 and exact[0] == pair[0] and exact[-1] == pair[1]:
            exact = exact[1:-1]
            break
    if not exact.strip():
        return None
    squash = lambda s: " ".join(s.split())  # noqa: E731
    return exact in text or squash(exact) in squash(text)


def kg_node_found(name, text, locator):
    """O locator kg-node (#ID ou ID) é o id de um nó do grafo lido? None quando o locator não tem a forma de um id."""
    nid = locator.strip()
    nid = nid[1:] if nid.startswith("#") else nid
    if not KG_NODE.fullmatch(nid):
        return None
    _tree, doc, code = kg_validate.parse_v1(kg_validate.as_source(name, text))
    if code or not isinstance(doc, dict) or not isinstance(doc.get("nodes"), list):
        return False
    return any(isinstance(n, dict) and n.get("id") == nid for n in doc["nodes"])


def pointer_found(text, locator):
    """O JSON Pointer (RFC 6901, /a/b ou o fragmento #/a/b) resolve no JSON? None fora da forma do schema (o texto em
    branco, o fragmento com espaço cru); False quando o JSON não se lê, que também é a fonte que não sustenta o
    locator. O locator chega sem strip: uma chave que termina em espaço é outra chave."""
    if not locator or not JSON_POINTER.fullmatch(locator):
        return None
    try:
        doc = json.loads(text)
    except ValueError:
        return False
    if locator.startswith("#"):
        return resolve_pointer(doc, locator)
    return resolve_pointer(doc, "#" + urllib.parse.quote(locator, safe="/~"))


def check_schemes(corpus, root, withs=()):
    """O locator lido pelo provenance.scheme e o provenance.sha256 contra a fonte (desde a 4.37.0, contrato v4.17). A
    fonte é o arquivo do repo que o source nomeia ou, pelo --with, o arquivo da URL no commit fixado. O sha256 confere
    os bytes da fonte. O locator é lido pelos esquemas que abrem a fonte: text, csv, quote, kg-node e json-pointer (este
    numa fonte .json, no repo ou pelo --with, nas duas formas da RFC 6901). O que se declara e não se julga é contado em
    skipped, nunca como ok: form_only (pdf, media e html, julgados só pela forma no schema), absolute, missing_source,
    not_path, outside_root, unpinned (o ref da URL não é um commit), malformed (o locator fora da gramática do esquema,
    o scheme fora da tabela ou o sha256 fora da forma, que o schema SHOULD já alerta), not_json e not_text. Devolve
    também, fora da saída, o conjunto dos nós cujo locator foi julgado aqui (o check_locators não os julga de novo)."""
    keys = ("form_only", "absolute", "missing_source", "not_path", "outside_root", "unpinned", "malformed", "not_json",
            "not_text")
    res = {"judged": 0, "ok": 0, "sha256_checked": 0, "failures": [], "skipped": {k: 0 for k in keys}}
    located = set()
    cache, files = {}, {}
    for key in corpus.order:
        node = corpus.nodes[key]
        prov = node.get("provenance")
        if not isinstance(prov, dict) or not isinstance(prov.get("source"), str):
            continue
        raw_scheme, raw_sha = prov.get("scheme"), prov.get("sha256")
        if raw_scheme is None and raw_sha is None:
            continue
        scheme = scheme_of(prov)
        sha = raw_sha if isinstance(raw_sha, str) and SHA256.fullmatch(raw_sha) else None
        # o que foi declarado e não se julga: o scheme fora da tabela, o hash fora da forma, o esquema só de forma
        unjudged = []
        if raw_scheme is not None and scheme is None:
            unjudged.append("malformed")
        if raw_sha is not None and sha is None:
            unjudged.append("malformed")
        if scheme in FORM_SCHEMES:
            unjudged.append("form_only")
        if scheme not in READ_SCHEMES and sha is None:
            for k in dict.fromkeys(unjudged or ["malformed"]):
                res["skipped"][k] += 1
            continue
        gdir = pathlib.PurePosixPath(key[0]).parent.as_posix()
        ck = (prov["source"], gdir)
        if ck not in cache:
            cache[ck] = read_source(prov["source"], gdir, root, withs, files)
        state, target, data = cache[ck]
        if state != "ok":
            res["skipped"]["missing_source" if state == "missing" else state] += 1
            continue
        raw_locator = prov.get("locator") if isinstance(prov.get("locator"), str) else ""
        locator = raw_locator if scheme == "json-pointer" else raw_locator.strip()
        entry = {"file": key[0], "id": key[1], "target": target, "locator": locator, "scheme": scheme}
        failed = None
        if sha is not None and hashlib.sha256(data).hexdigest() != sha:
            failed = SHA_MISMATCH
        if failed is None and scheme in READ_SCHEMES:
            try:
                text = data.decode("utf-8-sig")
            except UnicodeDecodeError:
                text = None
            if text is None:
                unjudged.append("not_text")
            elif scheme == "json-pointer" and not target.lower().endswith(".json"):
                unjudged.append("not_json")
            else:
                found = {"text": text_in_range, "csv": csv_in_range, "quote": quote_found,
                         "json-pointer": pointer_found}.get(scheme)
                fits = kg_node_found(target, text, locator) if scheme == "kg-node" else found(text, locator)
                if fits is None:
                    unjudged.append("malformed")
                else:
                    located.add(key)
                    if not fits:
                        failed = QUOTE_MISSING if scheme == "quote" else OUT_OF_RANGE
        for k in dict.fromkeys(unjudged):  # um motivo conta uma vez por nó
            res["skipped"][k] += 1
        if sha is None and key not in located and failed is None:
            continue  # nem o hash nem o locator foram julgados: o nó fica só em skipped
        res["judged"] += 1
        res["sha256_checked"] += 1 if sha is not None else 0
        if failed:
            res["failures"].append({"code": failed, **entry})
        else:
            res["ok"] += 1
    return res, located


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
        out = kg_query._git(str(root), "ls-files", "-z", "--", "*.md")
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
                    unloaded.append(d)  # o id que ele teria não é julgado: sem leitura, não há veredito sobre o id
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
                unloaded.append(d)  # idem: o erro do grafo reprova a página, e o id fica sem veredito
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


def check(corpus, root, external_roots=(), withs=()):
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
    res["schemes"], located = check_schemes(corpus, root, withs)
    res["locators"] = check_locators(corpus, root, root_files, external_roots, located)
    return res


def main(argv=None):
    ap = argparse.ArgumentParser(description=_("The trace that does not resolve: each node's trace: anchor against "
                                               "the files of the repository."))
    ap.add_argument("command", choices=("check", "projection"))
    ap.add_argument("pages", nargs="*", metavar=_("PAGE.md"),
                    help=_("projection: the pages to check (default: every tracked .md with projection_of)"))
    ap.add_argument("--with", action="append", default=[], dest="withs", metavar=_("PREFIX=FOLDER"),
                    help=_("read a file of another repository that a URL names, in the commit of the URL: the graph of "
                           "projection_of, or the provenance.source of check"))
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
    if args.pages:
        print(_("BROKEN INPUT  {error}").format(error=_("pages go with projection")), file=sys.stderr)
        return 2
    try:
        withs = [kg_query.with_spec(w) for w in args.withs]
    except ValueError as exc:
        print(_("BROKEN INPUT  {error}").format(error=exc), file=sys.stderr)
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
    res = check(corpus, args.root, args.external_root, withs)
    if args.format == "json":
        print(json.dumps({"schema_version": SCHEMA_VERSION, **res, "unreadable": corpus.unreadable},
                         ensure_ascii=False, indent=1))
    else:
        for m in res["missing"]:
            print(f"{CODE}  {m['file']}#{m['id']}  → {m['target']}  {kg_validate.message_of(CODE)}")
        loc = res["locators"]
        for m in loc["missing"] + loc["unreadable"]:
            print(f"{m['code']}  {m['file']}#{m['id']}  → {m['target']}{m['locator']}  {kg_validate.message_of(m['code'])}")
        sch = res["schemes"]
        for m in sch["failures"]:
            print(f"{m['code']}  {m['file']}#{m['id']}  → {m['target']} [{m['scheme'] or 'sha256'}] {m['locator']}  "
                  f"{kg_validate.message_of(m['code'])}")
        for u in corpus.unreadable:
            print(_("UNREADABLE  {file}  {code}").format(file=u["file"], code=u["code"]))
        if sch["judged"] or any(sch["skipped"].values()):
            ss = sch["skipped"]
            print(_("· {judged} source(s) read by scheme or sha256: {ok} ok, {failed} failed ({sha} sha256 checked); "
                    "not judged (counted): {form} form only, {absolute} URL with no --with, {missing} source not found, "
                    "{malformed} malformed scheme, locator or hash, {other} other").format(
                        judged=sch["judged"], ok=sch["ok"], failed=len(sch["failures"]), sha=sch["sha256_checked"],
                        form=ss["form_only"], absolute=ss["absolute"], missing=ss["missing_source"],
                        malformed=ss["malformed"],
                        other=ss["not_path"] + ss["outside_root"] + ss["unpinned"] + ss["not_json"]
                        + ss["not_text"]))
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
    if (res["missing"] or corpus.unreadable or res["locators"]["missing"] or res["locators"]["unreadable"]
            or res["schemes"]["failures"]):
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
