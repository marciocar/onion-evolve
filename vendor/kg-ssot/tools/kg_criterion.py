#!/usr/bin/env python3
"""O critério pré-registrado (contrato v4.12): o sha256 de cada versão contra o texto ou o arquivo, e as citações que o
leitor não confere.

O leitor do contrato não calcula hash nem lê o corpus: entre nós do mesmo grafo ele já avisa o critério desconhecido,
o sha256 citado que não é o da versão e a medição post-hoc. Esta ferramenta faz o resto, a partir da raiz do repo:

  digest   imprime o sha256 de um critério: --text (ou --text-file) ou --ref <caminho>[#<fragmento>];
  check    confere cada x_criterion dos grafos (integrity.criterion-digest quando o sha256 não bate com o texto ou o
           arquivo; integrity.criterion-ref-unreadable quando o ref não se lê) e cada citação <caminho>#<id> de um
           x_measured_under (integrity.criterion-unknown, integrity.criterion-sha-mismatch,
           integrity.measured-post-hoc e integrity.measured-order-unknown, pela mesma regra do leitor). A versão, o
           x_measured_under ou a citação que ele não consegue conferir sai como integrity.criterion-malformed, nunca
           em silêncio (desde a 4.21.1). Fica com o leitor, que a alerta (form.type), só a citação local com sha256
           que não é texto, e a lista criteria vazia (form.range), em que não há citação a perder.

A forma do sha256:
- text: o texto em UTF-8, com CRLF e CR sozinho trocados por LF e sem o espaço (U+0020) no fim de cada linha; o TAB
  fica;
- ref sem fragmento: os bytes do arquivo com CRLF trocado por LF, e mais nada (um TSV guarda colunas vazias com TAB no
  fim da linha);
- ref com fragmento: o item, na forma canônica JCS (RFC 8785), de um .json, .yaml ou .yml. O fragmento é um JSON
  Pointer (RFC 6901, começa com /) ou o id de um item de lista, único no arquivo.

O caminho do ref parte da raiz (--root, ou a pasta atual) e não pode sair dela.

Uso:
  kg_criterion.py digest (--text TEXTO | --text-file ARQ | --ref CAMINHO[#FRAGMENTO]) [--root DIR]
  kg_criterion.py check  [--root DIR] [--exclude GLOB]... [--no-default-excludes] [ARQ...] [--format human|json]
Com os arquivos dados um a um, cada um vale pelo caminho relativo à raiz (--root, ou a pasta atual), como a
citação <caminho>#<id>; a citação de um grafo que não foi dado fica sem conferir (e é contada à parte), e o --exclude
dado vale para eles.

rc: 0 · 1 check com achado ou com grafo ilegível · 2 entrada quebrada.
"""
import argparse
import fnmatch
import hashlib
import json
import math
import pathlib
import re
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

SCHEMA_VERSION = "kg-ssot.criterion/1"
MAX_SAFE = 2 ** 53 - 1
MAX_REF_BYTES = 64 << 20  # um critério é texto; o teto evita ler um arquivo de gigabytes na memória
_TRAILING_SPACE = re.compile(r" +$", re.M)


class CriterionError(ValueError):
    """O critério não se lê: o arquivo, o fragmento ou o valor que o JCS não representa."""


def text_digest(text):
    """O sha256 de um text: UTF-8, LF, sem U+0020 no fim da linha."""
    norm = _TRAILING_SPACE.sub("", text.replace("\r\n", "\n").replace("\r", "\n"))
    return hashlib.sha256(norm.encode("utf-8")).hexdigest()


def es_number(x):
    """O número na forma do Number.prototype.toString do ECMAScript, que o JCS pede (RFC 8785, 3.2.2.3)."""
    if isinstance(x, int):
        if abs(x) > MAX_SAFE:
            raise CriterionError(_("the integer {n} is outside ±(2^53−1): JCS cannot represent it exactly").format(n=x))
        return str(x)
    if not math.isfinite(x):
        raise CriterionError(_("NaN and Infinity have no JCS form"))
    if x == 0:
        return "0"
    sign = "-" if x < 0 else ""
    mant, _e, exp = repr(abs(x)).partition("e")
    whole, _dot, frac = mant.partition(".")
    digits = (whole + frac).lstrip("0")
    n = len(whole) + (int(exp) if exp else 0) - (len(whole + frac) - len((whole + frac).lstrip("0")))
    digits = digits.rstrip("0")
    k = len(digits)
    if k <= n <= 21:
        out = digits + "0" * (n - k)
    elif 0 < n <= 21:
        out = digits[:n] + "." + digits[n:]
    elif -6 < n <= 0:
        out = "0." + "0" * (-n) + digits
    else:
        e = n - 1
        out = digits[0] + ("." + digits[1:] if k > 1 else "") + "e" + ("+" if e > 0 else "-") + str(abs(e))
    return sign + out


def _jcs_string(s):
    out = ['"']
    for ch in s:
        o = ord(ch)
        if 0xD800 <= o <= 0xDFFF:
            raise CriterionError(_("a lone surrogate has no JCS form"))
        if ch == '"':
            out.append('\\"')
        elif ch == "\\":
            out.append("\\\\")
        elif o < 0x20:
            out.append({"\b": "\\b", "\t": "\\t", "\n": "\\n", "\f": "\\f", "\r": "\\r"}.get(ch, f"\\u{o:04x}"))
        else:
            out.append(ch)
    out.append('"')
    return "".join(out)


def jcs(value):
    """A forma canônica JCS (RFC 8785) de um valor JSON: chaves em ordem de unidade UTF-16, número do ECMAScript."""
    if value is None:
        return "null"
    if value is True:
        return "true"
    if value is False:
        return "false"
    if isinstance(value, (int, float)):
        return es_number(value)
    if isinstance(value, str):
        return _jcs_string(value)
    if isinstance(value, kg_validate.NonFinite):
        raise CriterionError(_("NaN and Infinity have no JCS form"))
    if isinstance(value, list):
        return "[" + ",".join(jcs(v) for v in value) + "]"
    if isinstance(value, dict):
        if not all(isinstance(k, str) for k in value):
            raise CriterionError(_("a map key that is not text has no JSON form"))
        keys = sorted(value, key=lambda k: k.encode("utf-16-be"))
        return "{" + ",".join(_jcs_string(k) + ":" + jcs(value[k]) for k in keys) + "}"
    raise CriterionError(_("a value of type {type} has no JSON form").format(type=type(value).__name__))


def _no_dups(pairs):
    out = {}
    for k, v in pairs:
        if k in out:
            raise CriterionError(_("the key {key} repeats in the same object").format(key=json.dumps(k, ensure_ascii=False)))
        out[k] = v
    return out


def _reject_constant(name):
    raise CriterionError(_("NaN and Infinity have no JCS form"))


def load_structured(path):
    """O documento de um .json (JSON estrito, sem chave repetida) ou de um .yaml/.yml (o perfil YAML do contrato, raiz
    em mapa)."""
    text = path.read_text(encoding="utf-8")
    if path.suffix == ".json":
        try:
            return json.loads(text, object_pairs_hook=_no_dups, parse_constant=_reject_constant)
        except json.JSONDecodeError as exc:
            raise CriterionError(_("{path}: not valid JSON ({error})").format(path=path.name, error=exc.msg)) from None
    if path.suffix in (".yaml", ".yml"):
        _raw, doc, code = kg_validate.parse_v1(text)
        if code:
            raise CriterionError(_("{path}: not readable in the YAML profile ({code})").format(path=path.name, code=code))
        _text_keys(text, path)
        return doc
    raise CriterionError(_("{path}: a fragment needs a .json, .yaml, or .yml file").format(path=path.name))


def _text_keys(text, path):
    """Toda chave de mapa do YAML é texto (str)? O perfil do contrato lê a chave 1.0 ou null como o texto "1.0" ou
    "null", e um leitor de outra língua leria outro valor: no fragmento, o hash mudaria de leitor para leitor."""
    import yaml
    try:  # o mesmo parser que o parse_v1 usou: o puro recusa texto que o em C aceita
        root = yaml.compose(text, Loader=kg_validate.loader_for(text))
    except yaml.YAMLError:
        try:
            root = yaml.compose(text, Loader=kg_validate.Yaml12CoreLoader)
        except yaml.YAMLError as exc:
            raise CriterionError(_("{path}: not readable in the YAML profile ({code})").format(
                path=path.name, code=type(exc).__name__)) from None
    stack = [root]
    while stack:
        node = stack.pop()
        if isinstance(node, yaml.MappingNode):
            for k, v in node.value:
                # a data sem aspas na chave os dois leitores leem como o mesmo texto (o perfil não tem data)
                if not (isinstance(k, yaml.ScalarNode)
                        and k.tag in ("tag:yaml.org,2002:str", "tag:yaml.org,2002:timestamp")):
                    raise CriterionError(_("{path}: a map key that is not text has no JSON form").format(path=path.name))
                stack.append(v)
        elif isinstance(node, yaml.SequenceNode):
            stack.extend(node.value)


def resolve_pointer(doc, pointer):
    """O valor de um JSON Pointer (RFC 6901) no documento."""
    cur = doc
    for raw in pointer.split("/")[1:]:
        token = raw.replace("~1", "/").replace("~0", "~")
        if isinstance(cur, dict) and token in cur:
            cur = cur[token]
        elif isinstance(cur, list) and re.fullmatch(r"0|[1-9][0-9]*", token) and int(token) < len(cur):
            cur = cur[int(token)]
        else:
            raise CriterionError(_("the pointer {pointer} does not exist in the file").format(pointer=pointer))
    return cur


def find_item(doc, item_id):
    """O item de lista cujo id é item_id, único no documento."""
    hits, stack = [], [doc]
    while stack:
        v = stack.pop()
        if isinstance(v, list):
            hits += [x for x in v if isinstance(x, dict) and x.get("id") == item_id]
            stack += v
        elif isinstance(v, dict):
            stack += list(v.values())
    if not hits:
        raise CriterionError(_("no list item has the id {id}").format(id=item_id))
    if len(hits) > 1:
        raise CriterionError(_("{n} list items have the id {id}").format(n=len(hits), id=item_id))
    return hits[0]


def ref_digest(root, ref):
    """O sha256 de um ref (<caminho> ou <caminho>#<fragmento>) a partir da raiz. CriterionError quando não se lê."""
    path_text, hash_mark, frag = ref.rpartition("#") if "#" in ref else (ref, "", "")  # o último #, como na ponta externa
    base = pathlib.Path(root).resolve()
    try:
        path = (base / path_text).resolve()
    except (OSError, RuntimeError) as exc:
        raise CriterionError(_("{ref}: the path does not resolve ({error})").format(ref=ref, error=exc)) from None
    if not path_text:
        raise CriterionError(_("{ref}: the path is empty").format(ref=ref))
    if path != base and base not in path.parents:
        raise CriterionError(_("{ref}: the path is outside the root").format(ref=ref))
    try:
        if not path.is_file():  # um diretório, um FIFO ou um dispositivo não é critério (o FIFO travava a leitura)
            raise CriterionError(_("{ref}: not a regular file").format(ref=ref))
        if path.stat().st_size > MAX_REF_BYTES:
            raise CriterionError(_("{ref}: the file is larger than {mib} MiB").format(ref=ref, mib=MAX_REF_BYTES >> 20))
        if not hash_mark:
            return hashlib.sha256(path.read_bytes().replace(b"\r\n", b"\n")).hexdigest()
        doc = load_structured(path)
    except (OSError, UnicodeDecodeError) as exc:
        raise CriterionError(_("{ref}: the file does not read ({error})").format(
            ref=ref, error=getattr(exc, "strerror", None) or type(exc).__name__)) from None
    item = resolve_pointer(doc, frag) if frag.startswith("/") or frag == "" else find_item(doc, frag)
    return hashlib.sha256(jcs(item).encode("utf-8")).hexdigest()


def _cut(value, limit=80):
    text = json.dumps(kg_query._plain(value), ensure_ascii=False, default=str)
    return text if len(text) <= limit else text[:limit - 1] + "…"


def _malformed(crit, source):
    """Por que a versão do critério não se confere, ou None quando se confere."""
    if not isinstance(crit, dict):
        return _("x_criterion is not a map")
    if not isinstance(crit.get("sha256"), str):
        return _("sha256 is not text (quote it: a hash of digits alone reads as a number)")
    if len(source) != 1:
        return _("exactly one of ref and text is needed")
    if not isinstance(crit[source[0]], str):
        return _("{key} is not text").format(key=source[0])
    return None


def check(corpus, root):
    """Os achados do corpus: [{code, file, id, detail}], quantas versões e citações externas foram conferidas, e quantas
    citações apontam para um grafo fora do que foi lido (com os arquivos dados um a um), que ficam sem conferir.

    Só a versão com exatamente um de ref e text, em texto, e com sha256 em texto é conferida. A outra sai como
    integrity.criterion-malformed, e não em silêncio: um sha256 só de dígitos sem aspas vira número no YAML, e o
    critério sumiria do check com rc 0. O mesmo vale para o x_measured_under que não é mapa ou cujo criteria não é
    lista, para o item de criteria que não é mapa, e para a citação de outro grafo com sha256 que não é texto, mesmo
    quando o grafo citado não foi lido (o sha256 se julga pelo próprio item). A citação local com sha256 que não é
    texto segue do leitor, que a alerta (form.type)."""
    findings, n_criteria, n_external, n_unchecked = [], 0, 0, 0
    for key in corpus.order:
        node = corpus.nodes[key]
        crit = node.get("x_criterion")
        source = [k for k in ("ref", "text") if k in crit] if isinstance(crit, dict) else []
        if "x_criterion" in node:
            why = _malformed(crit, source)
            if why:
                findings.append({"code": "integrity.criterion-malformed", "file": key[0], "id": key[1], "detail": why})
        if isinstance(crit, dict) and isinstance(crit.get("sha256"), str) and len(source) == 1 \
                and isinstance(crit[source[0]], str):
            want, n_criteria = None, n_criteria + 1
            try:
                want = ref_digest(root, crit["ref"]) if source == ["ref"] else text_digest(crit["text"])
            except CriterionError as exc:
                findings.append({"code": "integrity.criterion-ref-unreadable", "file": key[0], "id": key[1],
                                 "detail": str(exc)})
            if want is not None and want != crit["sha256"]:
                findings.append({"code": "integrity.criterion-digest", "file": key[0], "id": key[1],
                                 "detail": _("declared {declared}, computed {computed}").format(
                                     declared=crit["sha256"], computed=want)})
        if "x_measured_under" not in node:
            continue
        under = node["x_measured_under"]
        if not isinstance(under, dict) or not isinstance(under.get("criteria"), list):
            findings.append({"code": "integrity.criterion-malformed", "file": key[0], "id": key[1],
                             "detail": _("x_measured_under is not a map with a criteria list")})
            continue
        for item in under["criteria"]:
            if not isinstance(item, dict):  # uma citação escrita como texto some do check se ninguém a acusa
                findings.append({"code": "integrity.criterion-malformed", "file": key[0], "id": key[1],
                                 "detail": _("an item of criteria is not a map: {item}").format(item=_cut(item))})
                continue
            ref = item.get("criterion")
            if not isinstance(ref, str) or not ref:  # sem o criterion não se sabe nem se a citação é local
                findings.append({"code": "integrity.criterion-malformed", "file": key[0], "id": key[1],
                                 "detail": _("an item of criteria has no criterion in text: {item}").format(
                                     item=_cut(item))})
                continue
            if not kg_validate.is_external(ref):
                continue  # a citação local é do leitor (kg_validate)
            if not isinstance(item.get("sha256"), str):  # antes do n_unchecked: o sha256 se julga pelo próprio item
                findings.append({"code": "integrity.criterion-malformed", "file": key[0], "id": key[1],
                                 "detail": _("{ref}: the cited sha256 is not text").format(ref=ref)})
            target_key = tuple(ref.rsplit("#", 1))
            if corpus.root is None and target_key[0] not in corpus.files:
                n_unchecked += 1  # com os arquivos dados um a um, o grafo citado não foi lido: não há como conferir
                continue
            n_external += 1
            target = corpus.nodes.get(target_key, {}).get("x_criterion")
            if not isinstance(target, dict):
                findings.append({"code": "integrity.criterion-unknown", "file": key[0], "id": key[1], "detail": ref})
                continue
            findings += [{"code": code, "file": key[0], "id": key[1], "detail": ref}
                         for code in kg_validate.citation_codes(under, item, target)]
    return findings, n_criteria, n_external, n_unchecked


def main(argv=None):
    ap = argparse.ArgumentParser(description=_("The pre-registered criterion (contract v4.12): the sha256 of each "
                                               "version against its text or file, and the citations of another graph."))
    ap.add_argument("command", choices=("digest", "check"))
    ap.add_argument("files", nargs="*", help=_("check: .kg.yaml or .kg.json files (or --root)"))
    ap.add_argument("--root", help=_("the repository root, where ref paths start; without files, check reads the graphs "
                                     "git tracks under it"))
    ap.add_argument("--exclude", action="append", default=[], metavar="GLOB",
                    help=_("with --root, paths to leave out (repeatable), added to the defaults"))
    ap.add_argument("--no-default-excludes", action="store_true", help=_("with --root, also read the vendor and the fixtures"))
    ap.add_argument("--text", help=_("digest: the text of the criterion"))
    ap.add_argument("--text-file", metavar=_("FILE"), help=_("digest: a UTF-8 file with the text of the criterion"))
    ap.add_argument("--ref", help=_("digest: <path>[#<JSON Pointer or item id>], from the root"))
    ap.add_argument("--format", default="human", choices=("human", "json"))
    args = ap.parse_intermixed_args(argv)
    kg_validate._utf8_stdio()

    def broken(msg):
        print(_("BROKEN INPUT  {error}").format(error=msg), file=sys.stderr)
        return 2
    root = args.root or "."
    if args.command == "digest":
        given = [x for x in (args.text, args.text_file, args.ref) if x is not None]
        if len(given) != 1 or args.files:
            return broken(_("digest takes exactly one of --text, --text-file, and --ref"))
        try:
            if args.ref is not None:
                print(ref_digest(root, args.ref))
            else:
                text = (args.text if args.text is not None  # o BOM do arquivo não é texto do critério
                        else pathlib.Path(args.text_file).read_text(encoding="utf-8").removeprefix("\ufeff"))
                print(text_digest(text))
        except (CriterionError, OSError, UnicodeDecodeError) as exc:
            return broken(exc)
        return 0
    if not args.root and not args.files:
        return broken(_("give --root, the files, or both"))
    if args.root and not pathlib.Path(args.root).is_dir():
        return broken(_("--root {root} is not a directory").format(root=args.root))
    try:
        if args.files:  # só os arquivos dados, cada um com o caminho relativo à raiz, como a citação <caminho>#<id>
            corpus, base = kg_query.Corpus(), pathlib.Path(root).resolve()
            for f in args.files:
                full = pathlib.Path(f).resolve()
                # fora da raiz, o caminho absoluto, que nunca casa com uma citação <caminho>#<id> (relativa): o arquivo
                # de fora não toma o lugar de um de dentro com o mesmo caminho relativo
                rel = full.relative_to(base).as_posix() if base in full.parents else full.as_posix()
                if any(fnmatch.fnmatchcase(rel, pat) for pat in args.exclude):  # só o --exclude dado; o default não
                    continue
                corpus.add(rel, full.read_text(encoding="utf-8"))
        else:
            corpus = kg_query.load(args.root, (), args.exclude, not args.no_default_excludes)
    except (OSError, ValueError, UnicodeDecodeError) as exc:
        return broken(exc)
    findings, n_criteria, n_external, n_unchecked = check(corpus, root)
    if args.format == "json":
        print(json.dumps({"schema_version": SCHEMA_VERSION, "criteria": n_criteria, "external_citations": n_external,
                          "unchecked_citations": n_unchecked, "findings": findings, "unreadable": corpus.unreadable},
                         ensure_ascii=False, indent=1))
    else:
        for f in findings:
            print(f"{f['code']}  {f['file']}#{f['id']}  {f['detail']}  {kg_validate.message_of(f['code'])}")
        for u in corpus.unreadable:
            print(_("UNREADABLE  {file}  {code}").format(file=u["file"], code=u["code"]))
        print(_("· {criteria} criterion version(s) and {external} citation(s) of another graph checked; {n} finding(s)")
              .format(criteria=n_criteria, external=n_external, n=len(findings)))
        if n_unchecked:
            print(_("· {n} citation(s) of a graph that was not given left unchecked: give it too, or use --root")
                  .format(n=n_unchecked))
    return 1 if findings or corpus.unreadable else 0  # um grafo ilegível pode guardar um critério que ninguém conferiu


if __name__ == "__main__":
    sys.exit(main())
