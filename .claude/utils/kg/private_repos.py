#!/usr/bin/env python3
"""private_repos.py — o repositório privado citado sem o marcador `private-cite:<id>` (contrato v4.22 do kg-ssot).

POR QUE EXISTE (2026-11-12). A kg-ssot 4.51.0 deu ao grafo público o marcador `private-cite:<id>` e ao `kg_gate.py`
o `--private-repos ARQ`, e escreveu a regra no capítulo 5 do manual ("O repositório privado citado sem o marcador")
para outras ferramentas a portarem. O grafo não sabe que um repositório é privado; o dono sabe, e lista os padrões
num arquivo privado. Este módulo é o PORTE dessa regra para as guardas da casa (`private-repo-cite-check.sh` e
`kg-trace.sh`), que julgam um conjunto de grafos escolhido por elas (o tocado, o corpus) e não a catraca inteira.
A bancada confere a paridade com o leitor de referência (`kg_gate.py --private-repos`) no mesmo corpus.

A REGRA, item a item do manual:
1. O arquivo: UTF-8 (BOM aceito), um padrão por linha; as pontas aparadas; a linha vazia e a que começa por `#` ficam
   de fora. Padrão com espaço ou `#` no meio, com caractere Cf do Unicode, arquivo ilegível ou sem padrão = entrada
   quebrada (rc 2), dita pelo NÚMERO da linha, nunca pelo conteúdo.
2. Onde procura: todo valor de texto e toda chave de mapeamento, em qualquer profundidade (meta, nós, arestas, listas).
   O grafo que não parseia (ou que repete chave num mapeamento) é lido como texto, linha a linha, e nunca escapa.
3. Como casa: o padrão como texto literal, sem caixa, depois de decodificar o `%xx` UMA vez e levar a NFC, no texto e
   no padrão. A ponta do padrão que é letra, dígito, `_` ou `-` não encosta em outra dessas no valor.
4. O que imprime: grafo, lugar (id do nó, `meta`, `edge #i`, `#i`) e campo com ponto, e os números das linhas dos
   padrões. NUNCA o padrão nem o valor. A chave, o id de nó ou o caminho do grafo que CONTÉM um padrão (sem fronteira,
   casefold, ou o que a busca acusa) sai mascarado: `<key #i>`, `<node #i>`, `<graph #i>`.
5. O que não lê: o `.kg.json`; e, no modo `--corpus`, as fixtures, `docs/materials/` e o vendor (pasta com o carimbo
   `.kg-ssot-version`), mais o que o `--exclude` tirar.

ALÉM DA REFERÊNCIA (extensão da casa, declarada): o comentário YAML de LINHA INTEIRA de um grafo que parseia também é
lido (`line N (comment)`); a referência não o lê. E o grafo com tag explícita (!!set, !!omap, !!binary…) ou cuja raiz
não é mapeamento vai linha a linha: na referência o !!set escapa.

NÃO COBERTOS (o teto, herdado da referência e dito aqui para quem lê a saída verde): largura cheia; espaço de largura
zero no TEXTO; barra invertida no lugar da barra; o nome quebrado entre as linhas de um bloco dobrado; a dupla
codificação (`%252F` fica `%2F`); os sósias de caractere (o `а` cirílico); o comentário YAML no FIM de uma linha de
grafo que parseia; o `.kg.json`; e a forma que nenhum padrão expressa, porque o padrão não tem espaço: `repo @ sha`,
`repo (HEAD sha)` e o nome nu em prosa (essas a REGRA 121 vê pelo vocabulário dela, sem o arquivo privado).

Uso: private_repos.py --patterns ARQ --root DIR [--format human|tsv] [--corpus [--exclude GLOB]...] [ARQUIVO...]
     (--corpus sem arquivos = o corpus inteiro; com arquivos = só os dados que o corpus mede)
rc : 0 nenhum achado · 1 há campo citando repositório privado sem o marcador · 2 entrada quebrada (nunca verde)
TSV: grafo<TAB>lugar<TAB>campo<TAB>linhas<TAB>PRIVATE-REPO, e uma linha final `-<TAB>RESUMO<TAB>…`.
"""
import argparse
import fnmatch
import pathlib
import re
import subprocess
import sys
import unicodedata
import urllib.parse

try:
    import yaml
except ImportError:  # sem PyYAML não há leitura de grafo: entrada quebrada, nunca verde
    print("private-repos: PyYAML ausente — NAO VERIFICADO", file=sys.stderr)
    sys.exit(2)

WORD = "A-Za-z0-9_-"
DEFAULT_EXCLUDE = ("*/fixtures/*", "docs/materials/*")


class Broken(Exception):
    """Entrada quebrada: rc 2."""


def norm(text):
    """O texto como se compara: o %xx decodificado uma vez e a NFC (antes e depois, como a referência)."""
    return unicodedata.normalize("NFC", urllib.parse.unquote(unicodedata.normalize("NFC", text), errors="replace"))


def read_patterns(path):
    """[(linha, padrão normalizado)]; Broken no arquivo ilegível, sem padrão, ou com padrão de espaço, # ou Cf."""
    try:
        text = pathlib.Path(path).read_text(encoding="utf-8-sig")
    except (OSError, UnicodeDecodeError) as exc:
        raise Broken(f"--private-repos {path}: não se lê ({type(exc).__name__})") from None
    out = []
    for n, line in enumerate(text.splitlines(), 1):
        p = line.strip()
        if not p or p.startswith("#"):
            continue
        if "#" in p or any(c.isspace() for c in p):
            raise Broken(f"--private-repos {path}: o padrão da linha {n} tem espaço ou #; o comentário só começa no "
                         "início da linha")
        if any(unicodedata.category(c) == "Cf" for c in p):
            raise Broken(f"--private-repos {path}: o padrão da linha {n} tem caractere de formatação invisível "
                         "(categoria Cf do Unicode)")
        out.append((n, norm(p)))
    if not out:
        raise Broken(f"--private-repos {path}: nenhum padrão — uma lista vazia não confere nada")
    return out


def compile_pattern(p):
    lead = f"(?<![{WORD}])" if re.match(f"[{WORD}]", p[0]) else ""
    tail = f"(?![{WORD}])" if re.match(f"[{WORD}]", p[-1]) else ""
    return re.compile(lead + re.escape(p) + tail, re.I)


class _DupKey(Exception):
    pass


class _Loader(yaml.SafeLoader):
    """Todo escalar como texto (a data e o número também são lidos), e a chave repetida derruba o parse: o valor
    escondido pela 2ª ocorrência não pode escapar, então o grafo passa a ser lido linha a linha."""


def _mapping(loader, node, deep=False):
    seen = set()
    for k, _v in node.value:
        key = loader.construct_object(k, deep=deep)
        try:
            hashable = key if not isinstance(key, (list, dict)) else repr(key)
        except TypeError:
            hashable = repr(key)
        if hashable in seen:
            raise _DupKey()
        seen.add(hashable)
    return loader.construct_mapping(node, deep=deep)


def _scalar(loader, node):
    return loader.construct_scalar(node)


_Loader.add_constructor(yaml.resolver.BaseResolver.DEFAULT_MAPPING_TAG, _mapping)
for _tag in ("bool", "int", "float", "null", "timestamp"):
    _Loader.add_constructor(f"tag:yaml.org,2002:{_tag}", _scalar)


def _has_tag(text):
    """O grafo traz tag explícita (!!set, !!omap, !!pairs, !!binary, tag local)? Então vai linha a linha: o valor sob
    uma tag pode não ser texto que o walk percorre (o conjunto, o par, os bytes), e a leitura linha a linha nunca deixa
    nada de fora (passada adversarial de 2026-11-12, L6: !!set escapava aqui e na referência)."""
    try:
        return any(isinstance(t, yaml.TagToken) for t in yaml.scan(text, Loader=yaml.SafeLoader))
    except yaml.YAMLError:
        return False  # o parse vai falhar e o grafo já cai linha a linha


def _expands(doc, budget):
    """Mais de `budget` nós no percurso? A âncora aninhada (&a [*b, *b, ...]) expande em potência a partir de poucos
    bytes e travava o porte por memória (passada adversarial, B1: 300 bytes, 10^7 caminhos, 2 GB em 60 s); a
    referência tem a mesma contenção (_expands_beyond) e manda o grafo inflado para a leitura linha a linha."""
    stack, seen = [doc], 0
    while stack:
        v = stack.pop()
        seen += 1
        if seen > budget:
            return True
        if isinstance(v, dict):
            stack.extend(v.keys())
            stack.extend(v.values())
        elif isinstance(v, list):
            stack.extend(v)
    return False


def parse(text):
    """(documento, ok). Não ok = ler linha a linha: YAML inválido, chave repetida, tag explícita, raiz que não é
    mapeamento ou expansão de âncora acima de 2*len(text)+1000 nós."""
    if _has_tag(text):
        return None, False
    try:
        doc = yaml.load(text, Loader=_Loader)  # noqa: S506 (SafeLoader derivado)
    except (yaml.YAMLError, _DupKey, RecursionError, ValueError, TypeError):
        return None, False
    if not isinstance(doc, dict) or _expands(doc, 2 * len(text) + 1000):
        return None, False
    return doc, True


def walk(doc):
    """(caminho, texto, é_chave) de cada valor de texto e de cada chave, em ordem."""
    stack = [(doc, [], False)]
    while stack:
        value, path, is_key = stack.pop()
        if is_key:
            yield path, value, True
        elif isinstance(value, str):
            yield path, value, False
        elif isinstance(value, dict):
            for k, v in reversed(list(value.items())):
                stack.append((v, path + [str(k)], False))
                stack.append((str(k), path + [str(k)], True))
        elif isinstance(value, list):
            stack.extend((v, path + [i], False) for i, v in reversed(list(enumerate(value))))


def place(doc, path, hits):
    """(lugar, campo), com a máscara do que contém um padrão."""
    if len(path) >= 2 and path[0] in ("nodes", "edges") and isinstance(path[1], int) and isinstance(doc, dict):
        if path[0] == "nodes":
            item = doc["nodes"][path[1]]
            nid = item.get("id") if isinstance(item, dict) else None
            where = (f"<node #{path[1]}>" if isinstance(nid, str) and hits(nid)
                     else nid if isinstance(nid, str) and nid else f"#{path[1]}")
        else:
            where = f"edge #{path[1]}"
        rest = path[2:]
    elif path:
        where, rest = ("<key #0>" if hits(str(path[0])) else str(path[0])), path[1:]
    else:
        where, rest = "root", []
    field = ""
    for i, part in enumerate(rest):
        if isinstance(part, int):
            field += f"[{part}]"
        else:
            seg = f"<key #{i}>" if hits(part) else part
            field += f".{seg}" if field else seg
    return where, field or "(value)"


def check(items, patterns):
    """[(grafo, lugar, campo, [linhas])] de cada valor ou chave que cita um padrão."""
    compiled = [(n, compile_pattern(p)) for n, p in patterns]
    folded = [p.casefold() for _n, p in patterns]

    def lines_of(text):
        t = norm(text)
        return [n for n, rx in compiled if rx.search(t)]

    def masked(text):
        t = norm(text).casefold()
        return any(p in t for p in folded) or bool(lines_of(text))

    hits = []
    for gi, (name, text) in enumerate(items):
        graph = f"<graph #{gi}>" if masked(name) else name
        doc, ok = parse(text)
        if not ok or doc is None:
            values = [(f"line {i}", "(text)", line) for i, line in enumerate(text.splitlines(), 1)]
        else:
            values = []
            for path, value, is_key in walk(doc):
                where, field = place(doc, path, masked)
                if is_key:
                    field = "(key)" if field == "(value)" else field + " (key)"
                values.append((where, field, value))
            # extensão da casa: o comentário de LINHA INTEIRA (a referência não o lê)
            values += [(f"line {i}", "(comment)", line) for i, line in enumerate(text.splitlines(), 1)
                       if line.lstrip().startswith("#")]
        for where, field, value in values:
            found = lines_of(value)
            if found:
                hits.append((graph, where, field, found))
    return hits


def _vendor_dirs(listed):
    """As pastas com o carimbo do vendor. O carimbo na RAIZ não conta (como no kg_validate.vendor_dirs da referência):
    senão o corpus inteiro sairia, verde e calado (passada adversarial, L1)."""
    return {n[: -len(".kg-ssot-version")] for n in listed if n.endswith("/.kg-ssot-version")}


def corpus(root, excludes, given=None):
    """Os .kg.yaml que o corpus mede: rastreados (ou os DADOS, que podem ainda não estar no índice, como o grafo novo
    de um diff), fora das fixtures, de docs/materials/, do --exclude e de toda pasta com o carimbo do vendor."""
    out = subprocess.run(["git", "-C", str(root), "ls-files", "-z"], capture_output=True)
    if out.returncode != 0:
        raise Broken(f"{root} não é repositório git")
    listed = [n for n in out.stdout.decode("utf-8", "surrogateescape").split("\0") if n]
    vendors = _vendor_dirs(listed)
    names = sorted(n for n in (listed if given is None else given)
                   if n.endswith(".kg.yaml") and not any(fnmatch.fnmatch(n, g) for g in excludes)
                   and not any(v == "" or n.startswith(v) for v in vendors))
    return [n for n in names if (pathlib.Path(root) / n).is_file()]


def main(argv=None):
    ap = argparse.ArgumentParser(description="repositório privado citado sem o marcador private-cite:<id>")
    ap.add_argument("--patterns", required=True)
    ap.add_argument("--root", default=".")
    ap.add_argument("--format", choices=("human", "tsv"), default="human")
    ap.add_argument("--corpus", action="store_true")
    ap.add_argument("--exclude", action="append", default=[])
    ap.add_argument("files", nargs="*")
    a = ap.parse_args(argv)
    try:
        patterns = read_patterns(a.patterns)
        root = pathlib.Path(a.root)
        if a.corpus:  # com arquivos dados, o --corpus é o filtro: só o tocado que o corpus mede
            names = corpus(root, DEFAULT_EXCLUDE + tuple(a.exclude), a.files or None)
        else:
            names = [f for f in a.files if f.endswith(".kg.yaml")]
        items = []
        for n in names:
            try:
                items.append((n, (root / n).read_text(encoding="utf-8")))
            except (OSError, UnicodeDecodeError) as exc:  # bytes inválidos: entrada quebrada, como na referência
                raise Broken(f"grafo ilegível: {type(exc).__name__} no item #{len(items)}") from None
    except Broken as exc:
        print(f"private-repos: ENTRADA QUEBRADA — {exc} (NAO VERIFICADO)", file=sys.stderr)
        return 2
    hits = check(items, patterns)

    def cell(x):  # TAB e quebra de linha numa chave ou nome sumiam com o achado no TSV (passada adversarial, B2)
        return " ".join(str(x).replace("\t", " ").splitlines()) or "-"

    for g, w, f, ls in hits:
        g, w, f = cell(g), cell(w), cell(f)
        lines = ", ".join(map(str, ls))
        if a.format == "tsv":
            print(f"{g}\t{w}\t{f}\t{lines}\tPRIVATE-REPO")
        else:
            print(f"✗ repositório privado citado sem o marcador private-cite:: {g}#{w} {f} "
                  f"(padrão na linha {lines} do --private-repos)")
    summary = (f"{len(patterns)} padrão(ões) em {len(items)} grafo(s): {len(hits)} campo(s) citam um repositório "
               "privado sem o marcador")
    if a.format == "tsv":
        print(f"-\tRESUMO\t-\t{summary}\tRESUMO")
    else:
        print(f"· --private-repos: {summary}")
    return 1 if hits else 0


if __name__ == "__main__":
    sys.exit(main())
