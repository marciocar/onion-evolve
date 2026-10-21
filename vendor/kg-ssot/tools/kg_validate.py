#!/usr/bin/env python3
"""Leitor de referência NEUTRO do .kg.yaml: valida grafos contra um JSON Schema.

Depende só de Python 3, PyYAML e jsonschema, e não depende de nenhum harness de agente. Também é o instrumento
da medição que deu origem ao contrato (o "spike", opções --spike e --json).

Camadas medidas por arquivo:
  1. parse   — YAML válido, um documento só, raiz é mapa;
  2. schema  — o JSON canônico (datas em ISO, chaves em string) cumpre o schema;
  3. integrity — ids únicos, arestas sem ponta órfã e nenhum nó de grau 0 (o que JSON Schema não alcança).

Também é o leitor de referência da suíte spec/conformance/: codes(text, validator) devolve os
códigos MUST estáveis (parse.*, form.*, integrity.*) que tools/kg_conformance.py compara.

Saída humana (o CLI): por arquivo, o veredito e os códigos com o MESMO vocabulário do gate (kg_gate.py) e
da suíte, os de codes() e warnings() (parse.*, form.*, integrity.*, yaml.*), com a contagem de ocorrências:
  REPROVA <arquivo>   MUST  form.required.node.provenance ×33 · yaml.forbidden-key-on ×7
                      SHOULD form.required.node.verified_at ×33
  PASSA   <arquivo>   (SHOULD só avisa, não reprova)
Sem --schema, o contrato é o vigente (CONTRACT_MUST) e os avisos são do SHOULD dele (CONTRACT_SHOULD). Com
--schema S, o SHOULD é --should-schema, ou o vizinho S.should.schema.json quando existe, ou nenhum.

O .kg.json (o mesmo modelo de dados em JSON) é lido pelo parser JSON no perfil do contrato (RFC 8259 e I-JSON): um
arquivo *.json vira JsonText (as_source), e '-' segue --stdin-format yaml|json. No .kg.json, inteiro fora de
±(2^53−1) reprova como form.type; surrogate solto, mais de 128 coleções aninhadas, espaço fora da RFC e BOM que não é o
inicial reprovam como parse.yaml-error. No .kg.yaml, os três primeiros são os avisos yaml.unsafe-integer,
yaml.lone-surrogate e yaml.depth-over-128.

--corpus DIR liga a conferência da ponta externa das external_edges (v4.3) contra os .kg.yaml e .kg.json sob DIR.
--due AAAA-MM-DD troca o veredito pelo relatório de vencimento (v4.8): o nó com reverify_every cujo verified_at
somado à cadência já passou na data, o que tem cadência e não tem carimbo, e o que só tem reverify_on (por evento,
sem data). Vence o que vence na data ou antes. Nunca muda o veredito nem julga o grafo: o rc é 0, ou 2 com entrada
quebrada; um arquivo que não parseia sai no relatório (NÃO LIDO, broken no JSON). Com --format json, o relatório sai no
formato kg-ssot.due/1 (spec/due.schema.json).
--where acrescenta, por arquivo, uma linha por ocorrência com o nó ou a aresta (where()); a saída padrão não muda.
--spike troca a saída humana e o rc pelos do spike (check() e classify(), perfil Yaml12BoolLoader), para
reproduzir a medição do spike. --json OUT grava SEMPRE o formato do spike ({summary, results}),
congelado, para as medições gravadas seguirem reproduzíveis.

rc: 0 todo arquivo passa no MUST (com --spike: em schema + integridade) · 1 algum reprova · 2 entrada
quebrada (schema ou arquivo ilegível, git show que falha).

Uso:
  kg_validate.py [--schema S [--should-schema S2]] [--stdin-format yaml|json] FILE...
  kg_validate.py --schema S --git REPO --rev SHA --list LISTFILE [--json OUT] [--spike]
  kg_validate.py --due AAAA-MM-DD [--format json] FILE...
"""
import argparse
import bisect
import calendar
import collections
import datetime
import functools
import hashlib
import json
import math
import pathlib
import subprocess
import sys

import re

import yaml
from jsonschema import Draft202012Validator, FormatChecker, validators
from jsonschema.exceptions import ValidationError


def _home():
    """A raiz que tem o spec/: ao lado do módulo no pacote instalado (kg_ssot/spec), no pai no repo e no vendor
    (tools/ ao lado de spec/)."""
    here = pathlib.Path(__file__).resolve().parent
    return here if (here / "spec" / "release.json").is_file() else here.parent


_ROOT = _home()
# O contrato VIGENTE, num lugar só: a suíte, o gate e as outras ferramentas leem daqui.
CONTRACT_MUST = _ROOT / "spec" / "kg-contract-v4.schema.json"
CONTRACT_SHOULD = _ROOT / "spec" / "kg-contract-v4.should.schema.json"
# A versão do contrato que este leitor julga. Uma regra que só o leitor vê (o perfil YAML, a quebra de linha) não muda
# os bytes dos schemas sozinha: a higiene cobra que a descrição de um deles declare "No v<versão>", e é isso que
# move o sha256 que o gate guarda como identidade.
CONTRACT_VERSION = "4.8"


class Yaml12BoolLoader(yaml.SafeLoader):
    """SafeLoader com booleanos do YAML 1.2: só true/false.

    O PyYAML segue o YAML 1.1, em que on/off/yes/no viram booleano. O spike mediu o dano: a chave
    `on:` das arestas TRANSITIONS virava True, o evento referenciado parecia órfão e este leitor
    discordava do radar no MESMO arquivo. O perfil de YAML é parte do contrato, não detalhe.
    """


Yaml12BoolLoader.yaml_implicit_resolvers = {
    ch: [(tag, rx) for tag, rx in rs if tag != "tag:yaml.org,2002:bool"]
    for ch, rs in yaml.SafeLoader.yaml_implicit_resolvers.items()
}
Yaml12BoolLoader.add_implicit_resolver(
    "tag:yaml.org,2002:bool", re.compile(r"^(?:true|True|TRUE|false|False|FALSE)$"), list("tTfF"))


def _bool_loader_timestamp(loader, node):
    """O !!timestamp explícito com texto que não é data: o construtor do PyYAML quebrava com AttributeError (match None),
    e o check() saía com traceback. Vira erro de parse; a data válida segue o construtor de sempre."""
    if not yaml.constructor.SafeConstructor.timestamp_regexp.match(loader.construct_scalar(node)):
        raise yaml.constructor.ConstructorError(None, None, "!!timestamp sem data", node.start_mark)
    return yaml.constructor.SafeConstructor.construct_yaml_timestamp(loader, node)


Yaml12BoolLoader.add_constructor("tag:yaml.org,2002:timestamp", _bool_loader_timestamp)


class DuplicateKeyError(yaml.constructor.ConstructorError):
    """Chave repetida num mapa: o YAML 1.2 exige chaves únicas, e o PyYAML ficaria com a última."""


class Yaml12CoreLoader(Yaml12BoolLoader):
    """O perfil YAML do contrato (desde o v1): YAML 1.2 core.

    Além dos booleanos, inteiros e floats seguem o core schema do 1.2 (sem sexagesimal 1:30, sem
    octal 017 nem binário do 1.1), data sem aspas é string, `<<` é chave comum (o 1.2 não tem merge)
    e chave repetida é erro. O Yaml12BoolLoader fica como está: é o
    perfil com que o spike mediu, e a medição tem de continuar reproduzível.
    """

    def construct_mapping(self, node, deep=False):
        """Chaves na forma JSON (true, null, 1.0) e únicas nessa forma.

        Construir com a chave Python perderia dado antes de qualquer checagem: 1 e 1.0 (e True e 1)
        são a mesma chave num dict. Na forma JSON, 1 e 1.0 são distintas e 1 e "1" colidem, que é
        o que um leitor JS vê.
        """
        if not isinstance(node, yaml.MappingNode):
            raise yaml.constructor.ConstructorError(None, None, f"esperava um mapa, achei {node.id}", node.start_mark)
        mapping = {}
        for key_node, value_node in node.value:
            key = self.construct_object(key_node, deep=True)
            if isinstance(key, (dict, list)):
                raise yaml.constructor.ConstructorError(None, None, "chave composta (mapa ou lista)", key_node.start_mark)
            jk = json_key(key)
            if jk in mapping:
                raise DuplicateKeyError(None, None, f"chave repetida: {jk!r}", key_node.start_mark)
            mapping[jk] = self.construct_object(value_node, deep=deep)
        return mapping

    def compose_node(self, parent, index):
        """Duas construções raras que o perfil recusa (decisão de contrato de 2026-10-19, «o mais estrito nos três»): a tag
        ! sem nome (também !<!>), em escalar ou coleção, e o !!timestamp explícito cujo texto não é data na forma
        estrita (STRICT_TIMESTAMP). Só no parser puro: o loader_for manda para cá todo texto em que elas podem estar."""
        event = self.peek_event()
        tag = getattr(event, "tag", None)
        if tag == "!":
            raise yaml.composer.ComposerError(None, None, "tag ! sem nome", event.start_mark)
        if (tag == "tag:yaml.org,2002:timestamp" and isinstance(event, yaml.ScalarEvent)
                and not STRICT_TIMESTAMP.fullmatch(event.value)):
            raise yaml.composer.ComposerError(None, None, f"!!timestamp sem data: {event.value!r}", event.start_mark)
        if (isinstance(event, yaml.ScalarEvent) and event.style in ("'", '"')
                and event.start_mark.line != event.end_mark.line):
            if QUOTED_TAB_INDENT(event):
                raise yaml.composer.ComposerError(None, None, "tab no começo de uma continuação entre aspas", event.start_mark)
            cols = getattr(self, "_block_cols", [])
            if QUOTED_SHORT_INDENT(event, cols[-1] if cols else -1):
                raise yaml.composer.ComposerError(None, None, "continuação entre aspas menos indentada que a coleção dona",
                                                  event.start_mark)
        if isinstance(event, (yaml.MappingStartEvent, yaml.SequenceStartEvent)) and not event.flow_style:
            # a coluna da coleção em bloco que contém o que vem dentro dela (para a indentação da continuação)
            if not hasattr(self, "_block_cols"):
                self._block_cols = []
            # a coluna do bloco vem do end_mark: o start_mark aponta a âncora ou a tag, quando há (achado da revisão)
            end = event.end_mark
            col = end.column
            if isinstance(event, yaml.SequenceStartEvent) and end.buffer[end.pointer:end.pointer + 1] != "-":
                col -= 1
            self._block_cols.append(col)
            try:
                return super().compose_node(parent, index)
            finally:
                self._block_cols.pop()
        return super().compose_node(parent, index)


# O !!timestamp explícito aceito pelo perfil: a interseção do construtor do PyYAML com o do leitor JS, sem tab. Mês e dia
# com 1 ou 2 dígitos, hora com 1 ou 2, minuto e segundo com 2, fração com pelo menos um dígito, fuso Z, ±H, ±HH ou ±HH:MM
# (hora do fuso até 29) e só espaço entre a data e a hora. A data sem tag segue o resolvedor implícito (yaml.unquoted-date).
STRICT_TIMESTAMP = re.compile(
    r"[0-9]{4}-[0-9]{1,2}-[0-9]{1,2}(?:(?:[Tt]| +)[0-9]{1,2}:[0-9]{2}:[0-9]{2}(?:\.[0-9]+)?(?: *(?:Z|[-+][012]?[0-9](?::[0-9]{2})?))?)?")


def QUOTED_TAB_INDENT(event):
    """O texto entre aspas de várias linhas tem tab no espaço inicial de alguma linha de continuação? O perfil a recusa nos
    dois leitores (decisão de contrato de 2026-10-20, v4.5): o yaml do JS já recusava parte dos casos pela coluna, e a
    regra explícita, mais estrita, é a mesma nos dois. Lê o texto cru do escalar pelas marcas do parser puro, e só
    \r e \n quebram linha, como no leitor JS."""
    buf = getattr(event.start_mark, "buffer", None)
    if not isinstance(buf, str):  # só o parser puro tem o texto nas marcas; sem ele, falha fechado
        raise yaml.composer.ComposerError(None, None, "texto entre aspas sem o texto cru para conferir o tab", event.start_mark)
    raw = buf[event.start_mark.pointer:event.end_mark.pointer]
    return any("\t" in re.match(r"[ \t]*", line).group() for line in re.split(r"\r\n|\r|\n", raw)[1:])


def QUOTED_SHORT_INDENT(event, column):
    """A linha de continuação do texto entre aspas tem indentação menor ou igual à coluna da coleção em bloco que o
    contém (column; -1 na raiz)? A especificação do YAML 1.2 pede a continuação mais indentada que o bloco, o yaml do
    JS a recusa, e o perfil recusa nos dois (decisão de contrato de 2026-10-20, v4.6). Linha só de espaço não conta (é
    linha vazia). Lê o texto cru pelas marcas do parser puro; sem ele, falha fechado."""
    buf = getattr(event.start_mark, "buffer", None)
    if not isinstance(buf, str):
        raise yaml.composer.ComposerError(None, None, "texto entre aspas sem o texto cru para conferir a indentação",
                                          event.start_mark)
    raw = buf[event.start_mark.pointer:event.end_mark.pointer]
    for line in re.split(r"\r\n|\r|\n", raw)[1:]:
        if line.strip(" \t") and len(line) - len(line.lstrip(" ")) <= column:
            return True
    return False


class UnquotedDate(str):
    """Data escrita sem aspas. No YAML 1.2 core ela é string, e é string que o leitor devolve (sem
    quebrar em 2026-02-30); a subclasse só marca que um leitor YAML 1.1 a leria como data."""


Yaml12CoreLoader.yaml_implicit_resolvers = {
    ch: [(tag, rx) for tag, rx in rs
         if tag not in ("tag:yaml.org,2002:int", "tag:yaml.org,2002:float", "tag:yaml.org,2002:merge")]
    for ch, rs in Yaml12BoolLoader.yaml_implicit_resolvers.items()
}
Yaml12CoreLoader.add_implicit_resolver(
    "tag:yaml.org,2002:int", re.compile(r"^(?:[-+]?[0-9]+|0o[0-7]+|0x[0-9a-fA-F]+)$"), list("-+0123456789"))
Yaml12CoreLoader.add_implicit_resolver(
    "tag:yaml.org,2002:float",
    re.compile(r"^(?:[-+]?(?:\.[0-9]+|[0-9]+(?:\.[0-9]*)?)(?:[eE][-+]?[0-9]+)?|[-+]?\.(?:inf|Inf|INF)|\.(?:nan|NaN|NAN))$"),
    list("-+.0123456789"))


def _core_int(loader, node):
    v = loader.construct_scalar(node)
    try:
        return int(v[2:], 8) if v.startswith("0o") else int(v[2:], 16) if v.startswith("0x") else int(v)
    except ValueError:  # !!int explícito num valor que o 1.2 core não lê como inteiro (0b11): é erro de parse, não crash
        raise yaml.constructor.ConstructorError(None, None, f"inteiro inválido no YAML 1.2: {v!r}", node.start_mark)


Yaml12CoreLoader.add_constructor("tag:yaml.org,2002:int", _core_int)
Yaml12CoreLoader.add_constructor("tag:yaml.org,2002:timestamp",
                                 lambda loader, node: UnquotedDate(loader.construct_scalar(node)))


_CPARSER = getattr(getattr(yaml, "cyaml", None), "CParser", None)
if _CPARSER is not None:
    class Yaml12CoreCLoader(_CPARSER, Yaml12CoreLoader):
        """O mesmo perfil YAML 1.2 com o parser em C da libyaml (cerca de 10x mais rápido num grafo grande).

        Só o scanner e o parser mudam: o resolvedor (booleanos, inteiros e floats do 1.2, data como string) e o
        construtor (chave repetida, chave na forma JSON) são os do Yaml12CoreLoader. O teste
        test_parser_em_c_e_igual_ao_puro exige o mesmo resultado nos dois sobre toda a suíte de conformidade."""

        def __init__(self, stream):
            _CPARSER.__init__(self, stream)
            yaml.constructor.SafeConstructor.__init__(self)
            yaml.resolver.Resolver.__init__(self)

    FAST_LOADER = Yaml12CoreCLoader
else:  # sem libyaml, o perfil é o mesmo, só mais lento
    FAST_LOADER = Yaml12CoreLoader


def _ecma_pattern(validator, pattern, instance, schema):
    """pattern com a semântica do ECMA-262, que o JSON Schema adota.

    Em Python, `$` casa também antes de um `\n` final; em ECMA-262 (e num leitor JS), não. Sem isto,
    o id "A\n" passava aqui e reprovava num port JS: divergência medida pela revisão da suíte.
    """
    if not validator.is_type(instance, "string"):
        return
    m = re.search(pattern, instance)
    if m is None or (pattern.endswith("$") and not pattern.endswith("\\$") and m.end() != len(instance)):
        yield ValidationError(f"{instance!r} does not match {pattern!r}")


def make_validator(schema):
    """O validador do leitor de referência: Draft 2020-12 com pattern em semântica ECMA-262.

    propertyNames guarda os nomes de chave que já passaram por subschema: o resultado depende só do nome e do
    subschema, e as chaves se repetem em cada nó (medido em 2026-10-13: 4,5 s de 10 s num grafo de 3.123 nós)."""
    passed = set()

    def property_names(validator, names_schema, instance, schema):
        if not validator.is_type(instance, "object"):
            return
        key = id(names_schema)  # o subschema vive enquanto o validador vive (o schema é dele)
        for name in instance:
            if (key, name) in passed:
                continue
            errors = list(validator.descend(instance=name, schema=names_schema))
            if errors:
                yield from errors
            else:
                passed.add((key, name))
    cls = validators.extend(Draft202012Validator, {"pattern": _ecma_pattern, "propertyNames": property_names})
    return cls(schema, format_checker=FormatChecker(formats=["date"]))


class NonFinite:
    """.nan ou .inf no lugar de um valor: não é número, texto, objeto nem lista para o schema."""
    __slots__ = ("text",)

    def __init__(self, text):
        self.text = text

    def __repr__(self):
        return f"NonFinite({self.text})"


def _contains(value, hit):
    """Algum valor sob `value` (ele incluído) satisfaz hit? Sem recursão: a profundidade do documento não pesa na
    pilha (O2 da medição da opção b)."""
    stack = [value]
    while stack:
        v = stack.pop()
        if hit(v):
            return True
        if isinstance(v, dict):
            stack.extend(v.values())
        elif isinstance(v, list):
            stack.extend(v)
    return False


def _is_non_finite(v):
    return isinstance(v, NonFinite)


MAX_SAFE_INTEGER = 2 ** 53 - 1  # o I-JSON (RFC 7493): acima disto, um double não guarda o inteiro exato


def is_unsafe_integer(v):
    """Número de valor inteiro com módulo acima de 2^53−1, escrito como inteiro ou como float (9007199254740993,
    1e20): o perfil JSON o recusa, porque um leitor JS (double) perde o valor exato. O .nan e o .inf ficam com o
    NonFinite; o bool não é número aqui."""
    if isinstance(v, bool):
        return False
    if isinstance(v, int):
        return abs(v) > MAX_SAFE_INTEGER
    return isinstance(v, float) and math.isfinite(v) and v.is_integer() and abs(v) > MAX_SAFE_INTEGER


NESTED = {"node": ("provenance",)}  # objetos aninhados que o contrato define: o código desce neles


def _scoped_type_codes(doc, hit):
    """form.type.<escopo>.<campo> para cada campo do documento sob o qual algum valor satisfaz hit (um valor fora
    do modelo JSON): o mesmo caminho de códigos do .nan/.inf, também onde o schema não tem tipo (x_, chave
    desconhecida, dentro de lista). Um item de nodes ou edges que é ele mesmo o valor vira o campo item."""
    def contains(v):
        return _contains(v, hit)
    out = set()
    for key, value in doc.items():
        if key in ("nodes", "edges") and isinstance(value, list):
            scope = "node" if key == "nodes" else "edge"
            for item in value:
                if hit(item):
                    out.add(f"form.type.{scope}.item")
                elif isinstance(item, dict):
                    for k, v in item.items():
                        if k in NESTED.get(scope, ()) and isinstance(v, dict):  # objeto que o schema define
                            out |= {f"form.type.{scope}.{k}.{kk}" for kk, vv in v.items() if contains(vv)}
                        elif contains(v):
                            out.add(f"form.type.{scope}.{k}")
        elif key == "meta" and isinstance(value, dict):
            out |= {f"form.type.meta.{k}" for k, v in value.items() if contains(v)}
        elif contains(value):
            out.add(f"form.type.top.{key}")
    return out


def non_finite_codes(doc):
    """form.type para .nan/.inf em QUALQUER posição, também onde o schema não tem tipo (x_, chave
    desconhecida, dentro de lista): o JSON não os representa, e um leitor JS perderia o dado."""
    return _scoped_type_codes(doc, _is_non_finite)


def unsafe_integer_codes(doc):
    """form.type para o inteiro fora de ±(2^53−1) (is_unsafe_integer), com o caminho de non_finite_codes. É MUST no
    .kg.json; no .kg.yaml o mesmo achado é o aviso yaml.unsafe-integer (a rampa do CRITERIA.md do v2)."""
    return _scoped_type_codes(doc, is_unsafe_integer)


def json_key(k):
    """A chave como um leitor JSON/JS a veria: true, null, 1.0, e não True, None."""
    return k if isinstance(k, str) else json.dumps(k) if isinstance(k, (bool, int, float)) or k is None else str(k)


def canonical(value, json_keys=False):
    """YAML -> JSON canônico: datas viram ISO e chaves viram string.

    json_keys=True (contrato v1) usa a forma JSON das chaves e acusa colisão (1 e '1' viram a mesma
    chave): DuplicateKeyError. O default é o do spike, que precisa seguir reproduzível.
    """
    if isinstance(value, dict):
        if not json_keys:
            return {str(k): canonical(v) for k, v in value.items()}
        out = {}
        for k, v in value.items():
            jk = json_key(k)
            if jk in out:
                raise DuplicateKeyError(None, None, f"chave repetida no modelo JSON: {jk!r}", None)
            out[jk] = canonical(v, True)
        return out
    if json_keys and isinstance(value, float) and not math.isfinite(value):
        # .nan e .inf existem no YAML 1.2 core e não no JSON: viram um valor opaco que nenhum tipo do
        # schema aceita (nem objeto), e o campo reprova como form.type (o vão entre o YAML e o JSON).
        return NonFinite(repr(value))
    if isinstance(value, list):
        return [canonical(v, json_keys) for v in value]
    if isinstance(value, (datetime.date, datetime.datetime)):
        return value.isoformat()
    return value


def scope_of(path):
    head = path[0] if path else None
    return {"meta": "meta", "nodes": "node", "edges": "edge"}.get(head, "top")


def classify(error):
    """Uma chave estável por regra violada, para contar e simular relaxamentos."""
    scope = scope_of(list(error.absolute_path))
    v = error.validator
    if v == "additionalProperties":
        allowed = set(error.schema.get("properties", {}))
        extra = sorted(set(error.instance) - allowed)
        return [f"{scope}.unknown-key:{k}" for k in extra]
    if v == "required":
        field = error.message.split("'")[1]
        suffix = "(PROD)" if "then" in error.schema_path else ""
        return [f"{scope}.missing:{field}{suffix}"]
    field = error.absolute_path[-1] if error.absolute_path else "?"
    if isinstance(field, int):
        field = "item"
    return [f"{scope}.{field}:{v}"]


# fullmatch nos três (EXTERNAL_REF, SLUG, ISO_PREFIX): o $ do Python casa antes de um \n final, e o do ECMA-262, o dos
# patterns do contrato e do leitor JS, não; com match, "a.kg.yaml#ID\n" passava aqui e virava dangling-external.
EXTERNAL_REF = re.compile(r"^(?:[A-Za-z0-9_][A-Za-z0-9_.-]*/)*[A-Za-z0-9_][A-Za-z0-9_.-]*\.kg\.(?:yaml|json)#[A-Za-z][A-Za-z0-9_]*$")


def is_external(ref):
    return isinstance(ref, str) and EXTERNAL_REF.fullmatch(ref) is not None


def item_place(key, index, item):
    """O lugar legível de um item: o nó pelo id (ou pela posição, contando de 1), a aresta pela posição e pelas pontas."""
    if key == "external_edges":
        if isinstance(item, dict):
            return f"aresta externa #{index + 1} ({item.get('from', '(o grafo)')} -> {item.get('to')})"
        return f"aresta externa #{index + 1}"
    if key == "nodes":
        nid = item.get("id") if isinstance(item, dict) else None
        return f"nó {nid}" if isinstance(nid, str) and nid else f"nó #{index + 1}"
    if isinstance(item, dict):
        return f"aresta #{index + 1} ({item.get('from')} -> {item.get('to')})"
    return f"aresta #{index + 1}"


def _located(doc, key):
    """Os mapas sob a chave com o lugar de cada um; a posição conta a lista inteira, como o autor a vê."""
    raw = doc.get(key)
    return [(x, item_place(key, i, x)) for i, x in enumerate(raw) if isinstance(x, dict)] if isinstance(raw, list) else []


def index_texts(items):
    """[(caminho, texto)] → {caminho: {ids}}: o corpus montado de textos já lidos (por exemplo, por git show)."""
    index = {}
    for name, text in items:
        _, doc, _ = parse_v1(text if isinstance(text, JsonText) else as_source(name, text))  # o .kg.json pelo perfil JSON
        nodes = doc.get("nodes") if doc and isinstance(doc.get("nodes"), list) else []
        index[name] = {str(n["id"]) for n in nodes if isinstance(n, dict) and n.get("id") is not None}
    return index


def external_info(text):
    """(usa external_edges?, {caminhos citados}), tirados do documento PARSEADO (o mesmo valor que is_external
    confere): escape YAML, chave entre aspas e continuação de linha não enganam, ao contrário de ler o texto cru
    (achado de revisão em 2026-10-10). O parse é o mesmo, guardado, que o gate já faz para medir."""
    if "external_edges" not in text and "\\" not in text:  # sem nenhuma das duas, nem a chave escapada existe
        return False, set()
    _, doc, err = parse_v1(text)  # o mesmo parse que codes() e warnings() reaproveitam
    if not doc or err or "external_edges" not in doc:
        return False, set()
    edges = doc["external_edges"] if isinstance(doc["external_edges"], list) else []
    return True, {ref.rsplit("#", 1)[0] for e in edges if isinstance(e, dict) for ref in (e.get("from"), e.get("to"))
                  if is_external(ref)}


def external_targets(text):
    """Os caminhos que as external_edges de um texto citam (external_info)."""
    return external_info(text)[1]


def uses_external(text):
    """O documento tem external_edges no topo, inclusive com a chave entre aspas (external_info)?"""
    return external_info(text)[0]


def corpus_index(root, files=None):
    """O corpus para conferir a ponta externa (v4.3): {caminho relativo a root: {ids}}. files: os caminhos a ler (o gate
    passa os grafos rastreados); sem files, os .kg.yaml e .kg.json rastreados se root é repo git, senão todo grafo sob
    root (desde o v4.7, a ponta externa pode ser um .kg.json).
    Arquivo ilegível entra sem ids. root que não é diretório é entrada quebrada (ValueError)."""
    root = pathlib.Path(root)
    if not root.is_dir():
        raise ValueError(f"corpus {root} não é um diretório")
    if files is None:  # num repo git, os rastreados (como o gate); fora dele, todo arquivo regular sob root
        out = subprocess.run(["git", "-C", str(root), "ls-files", "-z", "--", "*.kg.yaml", "*.kg.json"],
                             capture_output=True)
        if out.returncode == 0:
            files = [n for n in out.stdout.decode("utf-8").split("\0") if n]
        else:
            files = sorted(p.relative_to(root).as_posix() for g in ("*.kg.yaml", "*.kg.json") for p in root.rglob(g)
                           if ".git" not in p.relative_to(root).parts)
    names = [n for n in files if (root / n).is_file()]  # FIFO, diretório e apagado ficam fora
    items = []
    for name in names:
        try:
            items.append((name, (root / name).read_text(encoding="utf-8")))
        except (OSError, UnicodeDecodeError):
            items.append((name, ""))
    return index_texts(items)


def integrity_located(doc, refs=("on",), corpus=None):
    """Os códigos de integridade com o lugar de cada ocorrência: lista de (código, lugar). corpus (corpus_index) liga
    a conferência da ponta externa das external_edges; sem ele, só a ponta local é conferida."""
    out = []
    nodes = _located(doc, "nodes")
    # Só ids presentes entram no conjunto: um sentinela como str(None) casaria com um nó de id "None".
    ids = collections.Counter(str(n["id"]) for n, _ in nodes if n.get("id") is not None)
    seen = collections.Counter()
    raw = doc.get("nodes") if isinstance(doc.get("nodes"), list) else []
    for n, place in nodes:
        if n.get("id") is not None:
            seen[str(n["id"])] += 1
            if seen[str(n["id"])] > 1:  # qual das repetições: a posição, contando de 1
                pos = next(i for i, x in enumerate(raw) if x is n) + 1
                out.append(("integrity.duplicate-id", f"{place} (#{pos})"))
    touched = set()
    for e, place in _located(doc, "edges"):
        for end in ("from", "to"):
            ref = e.get(end)
            if ref is None or str(ref) not in ids:
                out.append((f"integrity.dangling-{end}", place))
            else:
                touched.add(str(ref))
        for key in refs:  # o gatilho de TRANSITIONS é referência ao evento
            if key in e:
                if e[key] is None or str(e[key]) not in ids:
                    out.append((f"integrity.dangling-{key}", place))
                else:
                    touched.add(str(e[key]))
    for e, place in _located(doc, "external_edges"):  # v4.3: a ponta local existe; a externa, com o corpus
        for end in ("from", "to"):
            ref = e.get(end)
            if ref is None:
                continue  # from ausente: o grafo inteiro
            if isinstance(ref, str) and "#" in ref:  # externa; a malformada já reprova na forma, e só a bem formada vai ao corpus
                path, nid = ref.rsplit("#", 1)
                if corpus is not None and is_external(ref) and nid not in corpus.get(path, ()):
                    out.append(("integrity.dangling-external", place))
            elif str(ref) in ids:
                touched.add(str(ref))
            else:
                out.append(("integrity.dangling-external-local", place))
    # Nó de grau 0 o radar reprova (achado do próprio spike: o leitor neutro não checava). Nó sem id
    # não pode ser ponta de aresta, então também tem grau 0.
    first = {}
    for n, place in nodes:
        if n.get("id") is not None:
            first.setdefault(str(n["id"]), place)
    out += [("integrity.orphan-node", first[i]) for i in ids if i not in touched]
    out += [("integrity.orphan-node", place) for n, place in nodes if n.get("id") is None]
    return out


def integrity(doc, refs=("on",), corpus=None):
    """refs: as chaves de aresta que também são referência a nó. O spike usa só on (o legado que o
    radar lia); o contrato v1 usa trigger, e on segue como referência para não acusar o evento duas vezes."""
    return [code for code, _ in integrity_located(doc, refs, corpus)]


def check(text, validator):
    if isinstance(text, JsonText):  # o .kg.json: o parse é o do perfil JSON, e o resto segue o formato do spike
        _, doc, code = parse_v1(text)
        if code:
            return {"parse": code, "schema": [], "integrity": []}
        return {"parse": None, "schema": [c for err in validator.iter_errors(doc) for c in classify(err)],
                "integrity": integrity(doc)}
    if _too_deep(text):  # o mesmo teto do parse_v1: parsear isto derruba o processo
        return {"parse": "yaml-error: aninhamento além do teto", "schema": [], "integrity": []}
    try:
        docs = [d for d in yaml.load_all(text, Loader=Yaml12BoolLoader) if d is not None]
        if docs and _expands_beyond(docs, 2 * len(text) + 1000):
            return {"parse": "yaml-error: aliases além do teto", "schema": [], "integrity": []}
    except (yaml.YAMLError, RecursionError, ValueError) as exc:  # ValueError: data sem aspas fora do calendário
        return {"parse": f"yaml-error: {str(exc).splitlines()[0] if str(exc) else type(exc).__name__}",
                "schema": [], "integrity": []}
    if len(docs) != 1 or not isinstance(docs[0], dict):
        return {"parse": f"documents={len(docs)}", "schema": [], "integrity": []}
    doc = canonical(docs[0])
    schema = [c for err in validator.iter_errors(doc) for c in classify(err)]
    return {"parse": None, "schema": schema, "integrity": integrity(doc)}


FORM_TYPE = {"required": "required", "enum": "enum", "type": "type", "pattern": "pattern",
             "minimum": "range", "maximum": "range", "minLength": "range", "maxLength": "range",
             "const": "const", "additionalProperties": "unknown-key", "format": "pattern",
             "minItems": "range"}


def inner_names(path):
    """Os nomes do caminho DENTRO do objeto de escopo (o meta, um nó, uma aresta): campo aninhado
    vira caminho com ponto (provenance.locator). Índices de lista não entram."""
    if path and path[0] == "meta":
        rest = path[1:]
    elif path and path[0] in ("nodes", "edges") and len(path) >= 2 and isinstance(path[1], int):
        rest = path[2:]
    else:
        rest = path
    return [p for p in rest if not isinstance(p, int)]


def form_codes(error):
    """Erro do jsonschema -> códigos da suíte de conformidade: form.<tipo>.<escopo>.<campo>.

    <campo> é o nome do campo no objeto de escopo; num objeto aninhado (provenance) é o caminho com
    ponto (provenance.locator).
    """
    path = list(error.absolute_path)
    scope = scope_of(path) if path else "top"
    # no topo, um objeto dentro de uma lista do topo (external_edges) leva o nome da lista no código
    prefix = inner_names(path) if scope != "top" else [p for p in path if not isinstance(p, int)]
    if "propertyNames" in error.schema_path:  # nível SHOULD: o nome da chave
        if error.validator == "pattern":  # nome que não é slug (<<, 1.0, chave com espaço)
            return [f"form.pattern.{scope}.{'.'.join(prefix + ['key'])}"]
        if not SLUG.fullmatch(str(error.instance)):
            return []  # nome não-slug já alerta como form.pattern.<escopo>.key; não repete como unknown-key
        return [f"form.unknown-key.{scope}.{'.'.join(prefix + [str(error.instance)])}"]  # fora da gramática e sem x_
    kind = FORM_TYPE.get(error.validator, error.validator)
    if error.validator == "not" and isinstance(error.validator_value, dict) and "pattern" in error.validator_value:
        kind = "pattern"  # o v4 diz "não pode casar com placeholder" por not+pattern, sem lookahead (portável a RE2)
    if error.validator in ("additionalProperties", "required"):
        # O erro é do OBJETO (o topo, o meta, um nó, uma aresta ou um objeto dentro deles).
        if error.validator == "required":
            return [f"form.{kind}.{scope}.{'.'.join(prefix + [p])}" for p in error.validator_value if p not in error.instance]
        extra = sorted(set(error.instance) - set(error.schema.get("properties", {})))
        return [f"form.{kind}.{scope}.{'.'.join(prefix + [k])}" for k in extra]
    # O erro é de um VALOR. Um item de lista que não é mapa (nodes: [a]) vira o campo `item`.
    scope = scope_of(path) if len(path) >= 2 else "top"
    if path and isinstance(path[-1], int):
        lead = [p for p in path[:-1] if not isinstance(p, int)] if scope == "top" else []
        return [f"form.{kind}.{scope}.{'.'.join(lead + ['item'])}"]
    names = inner_names(path) if scope != "top" else [p for p in path if not isinstance(p, int)]
    return [f"form.{kind}.{scope}.{'.'.join(names) if names else 'root'}"]


# Onde o parser em C (libyaml) e o puro divergem, medido pela revisão de 2026-10-13 em 63 entradas estranhas: tab
# como separador ou no fim da linha, a diretiva %YAML, escape de surrogate, BOM fora do início e aninhamento
# muito profundo. O puro é a referência do perfil; o C é só um atalho, usado quando o texto não tem nenhuma dessas
# construções. O tab fora de aspas, de bloco e de comentário reprova: o puro o recusa, e o contrato ficou com o mais
# estrito (decisão de contrato de 2026-10-19), que o leitor JS segue. Pelo mesmo selo, a tag ! sem nome e o !!timestamp
# explícito são julgados só pelo puro (Yaml12CoreLoader.compose_node): o texto que tem tag ! isolada, !!timestamp, a
# forma longa ...2002:timestamp, uma diretiva %TAG ou uma tag com escape %xx (que o parser decodifica: !<%21> é a
# tag !) cai nele. O : entra no que pode vir antes da tag, por causa da chave JSON no flow ({"a":! b}).
# O escape \u só diverge na faixa dos surrogates (D800 a DFFF): medido em 2026-10-13 nos 65.536 valores, em 6 contextos
# de aspas duplas. O \ufeff de texto extraído de PDF caía no puro e custava ao SGE mais que o dobro do tempo. O \U
# segue arriscado inteiro (é raro, e acima de 10FFFF os dois erram por motivos diferentes).
RISKY = re.compile(r"\t|%YAML|%TAG|!!timestamp|2002:timestamp|\\u[dD][89a-fA-F]|\\U|.\ufeff"
                   r"|(?:^|(?<=[\s\[{,:\ufeff]))!(?:<!>)?(?=[\s,\[\]{}]|$)|!(?:<[^>\s]*|[^\s\[\]{},]*)%[0-9A-Fa-f]{2}", re.S)
SAFE_DEPTH = 200
MAX_DEPTH = 1000  # coleções abertas de uma vez: acima disto o parser estoura a pilha (segfault medido)
_DEEP_HINT = re.compile(r"(?m)^[ \t]*(?:[-?][ \t]+){2,}|^ {%d,}" % (MAX_DEPTH // 2))
_YAML_BREAK = re.compile("\r\n?|[\x85\u2028\u2029]")  # as outras quebras de linha do YAML, que o ^ da regex não vê


def _too_deep(text):
    """O documento abre mais de MAX_DEPTH coleções de uma vez? Contado no stream de eventos do YAML (iterativo), que
    pega flow ([ {), bloco (- - -), chave complexa (? ?) e indentação, e não conta colchete dentro de escalar. O
    stream só roda quando um indício barato aponta risco: um grafo de verdade fica em 3 ou 4 níveis. Medido na revisão
    do servidor MCP: 30.000 níveis de [ ou de - derrubavam o processo com segfault."""
    if text.count("[") + text.count("{") <= MAX_DEPTH and not _DEEP_HINT.search(_YAML_BREAK.sub("\n", text)):
        return False
    # com os DOIS parsers quando eles podem divergir (um tab, um BOM no meio, um escape de surrogate ou \U, ou a
    # libyaml que erra antes do fim): um recusa cedo e o outro segue até o fundo, e quem compõe depois (yaml_lines)
    # pode ser qualquer um.
    # No caso comum, a libyaml lê tudo sem erro e basta: o puro custaria 3 a 4 vezes mais (medido na revisão).
    fast = getattr(yaml, "CSafeLoader", None)
    loaders = ([fast] if fast is not None else []) + [yaml.SafeLoader]
    for loader in loaders:
        depth, failed = 0, False
        try:
            for ev in yaml.parse(text, Loader=loader):
                if isinstance(ev, (yaml.SequenceStartEvent, yaml.MappingStartEvent)):
                    depth += 1
                    if depth > MAX_DEPTH:
                        return True
                elif isinstance(ev, (yaml.SequenceEndEvent, yaml.MappingEndEvent)):
                    depth -= 1
        except (yaml.YAMLError, UnicodeEncodeError, ValueError):
            failed = True  # o erro de sintaxe é do parse de verdade, que o reporta com o código dele
        if loader is fast and not failed and not RISKY.search(text):
            return False
    return False


def _expands_beyond(value, budget):
    """O documento construído, contando cada alias pelo que ele repete, passa de `budget` valores? Sem recursão e
    parando no teto: a bomba de aliases (&a [*a, *a, ...] aninhada) tem tamanho exponencial e travava o leitor."""
    seen, stack = 0, [value]
    while stack:
        v = stack.pop()
        seen += 1
        if seen > budget:
            return True
        if isinstance(v, dict):
            stack.extend(v.values())
            seen += len(v)
        elif isinstance(v, list):
            stack.extend(v)
    return False


def loader_for(text):
    return Yaml12CoreLoader if FAST_LOADER is Yaml12CoreLoader or RISKY.search(text) else FAST_LOADER


def _depth(value):
    """A profundidade de aninhamento do documento construído, sem recursão (ela mesma estouraria a pilha)."""
    best, stack = 0, [(value, 1)]
    while stack:
        v, d = stack.pop()
        best = max(best, d)
        if best > SAFE_DEPTH:
            return best
        if isinstance(v, dict):
            stack += [(x, d + 1) for x in v.values()]
        elif isinstance(v, list):
            stack += [(x, d + 1) for x in v]
    return best


def parse_error_line(text):
    """A linha (contando de 1) em que o parse falha, pela marca do erro do parser de referência; None sem marca. No
    .kg.json, a linha é a do JSONDecodeError; a chave repetida, a profundidade e o surrogate solto não têm marca."""
    if isinstance(text, JsonText):
        try:
            _load_json(text)
        except json.JSONDecodeError as exc:
            return exc.lineno
        except (ValueError, RecursionError):
            return None
        return None
    if _too_deep(text):  # recusado antes do parser (parse_v1): não há marca, e parsear derruba
        return None
    try:
        list(yaml.load_all(text, Loader=Yaml12CoreLoader))
    except yaml.MarkedYAMLError as exc:
        mark = exc.problem_mark or exc.context_mark
        return mark.line + 1 if mark is not None else None
    except Exception:  # noqa: BLE001 — só a linha interessa aqui; o código já veio do parse_v1
        return None
    return None


def _parse(text, loader):
    try:
        raw = list(yaml.load_all(text, Loader=loader))
    except DuplicateKeyError:
        return None, None, "parse.duplicate-key", None
    except (yaml.YAMLError, UnicodeEncodeError, RecursionError):
        # UnicodeEncodeError: texto com surrogate que o parser em C recusa; RecursionError: aninhamento além da pilha
        return None, None, "parse.yaml-error", None
    if _expands_beyond(raw, 2 * len(text) + 1000):  # antes de canonical(), que percorreria a expansão inteira
        return None, None, "parse.yaml-error", None
    docs = [d for d in raw if d is not None]
    if not docs:
        return None, None, "parse.empty-document", raw  # vazio, só comentário, `---` ou `~`
    if len(raw) != 1:
        return None, None, "parse.not-single-document", raw  # conta os nulos: um `---` a mais é outro documento
    if not isinstance(docs[0], dict):
        return None, None, "parse.root-not-mapping", raw
    try:
        return docs[0], canonical(docs[0], json_keys=True), None, raw
    except DuplicateKeyError:
        return None, None, "parse.duplicate-key", raw
    except RecursionError:  # âncora recursiva (a: &x [*x]): não há documento finito para validar
        return None, None, "parse.yaml-error", raw


PROFILE_DEPTH = 128  # coleções aninhadas que o perfil do modelo admite: MUST no .kg.json, aviso no .kg.yaml
_LONE_SURROGATE = re.compile("[\ud800-\udbff](?![\udc00-\udfff])|(?<![\ud800-\udbff])[\udc00-\udfff]")


def collection_depth(value, limit=PROFILE_DEPTH):
    """Quantas coleções (mapas e listas) o documento construído aninha, a raiz contando 1; para assim que passa de
    limit. Sem recursão: mede antes de canonical() e de non_finite_codes() (O2 da medição da opção b)."""
    best, stack = 0, [(value, 1)]
    while stack:
        v, d = stack.pop()
        if isinstance(v, dict):
            stack += [(x, d + 1) for x in v.values()]
        elif isinstance(v, list):
            stack += [(x, d + 1) for x in v]
        else:
            continue
        best = max(best, d)
        if best > limit:
            return best
    return best


def has_lone_surrogate(value):
    """Alguma chave ou texto do documento tem um surrogate solto (U+D800 a U+DFFF sem o par)? O I-JSON o proíbe, e o
    texto não é Unicode válido. Um par alto+baixo adjacente conta como o caractere que ele forma (o parser JSON já o
    junta; o YAML puro do PyYAML o deixa em dois), como num leitor JS. Sem recursão."""
    stack = [value]
    while stack:
        v = stack.pop()
        if isinstance(v, str):
            if _LONE_SURROGATE.search(v):
                return True
        elif isinstance(v, dict):
            stack.extend(k for k in v if isinstance(k, str))
            stack.extend(v.values())
        elif isinstance(v, list):
            stack.extend(v)
    return False


class JsonText(str):
    """Texto de um .kg.json: o mesmo modelo de dados, lido por um parser JSON e não pelo loader YAML (o JSON é
    quase um subconjunto do YAML 1.2, e o quase é o que diverge: tab, chave longa, NaN, aspas simples)."""


def as_source(name, text):
    """O texto como o leitor deve lê-lo: JsonText para *.json, str para o resto (o YAML, como sempre)."""
    return JsonText(text) if str(name).endswith(".json") else text  # sensível a maiúsculas, como o run.mjs e o NAME do kg_store


def _json_pairs(dups):
    """O object_pairs_hook que anota a chave repetida em `dups` em vez de interromper o parse: a repetição só decide
    depois da sintaxe, da profundidade e do surrogate, na mesma ordem do leitor JS (parseJson)."""
    def pairs(items):
        out = {}
        for k, v in items:
            if k in out:  # o decodificador já resolveu os escapes: "\u0069d" e "id" são a mesma chave
                dups.append(k)
            out[k] = v
        return out
    return pairs


def _json_constant(name):
    raise ValueError(f"{name} não é JSON")  # NaN, Infinity e -Infinity (RFC 8259, seção 6)


def _json_int(digits):
    """O inteiro do JSON: exato até 20 dígitos (2^64 cabe), e daí em diante o float, que já passa de 2^53 ou estoura
    o double (inf, o NonFinite). Assim o int() do Python não recusa o inteiro de 5.000 dígitos (o teto de 4.300) e o
    veredito não depende da forma escrita: 1 seguido de 400 zeros e 1e400 dão o mesmo form.type."""
    return int(digits) if len(digits) <= 21 else float(digits)


_JSON_WS = " \t\n\r"  # o espaço em branco da RFC 8259, e só ele (o str.strip() do Python tira também \x1c e NBSP)


def _json_body(text):
    """O texto sem UM BOM inicial (aceito e descartado); um segundo BOM fica no texto e o json.loads o recusa."""
    return text[1:] if text.startswith("\ufeff") else text


def _load_json(text, dups=None):
    return json.loads(_json_body(text), object_pairs_hook=_json_pairs([] if dups is None else dups),
                      parse_constant=_json_constant, parse_int=_json_int)


def _parse_json(text):
    """O parse de um .kg.json no perfil JSON do contrato, com os mesmos códigos do caminho YAML (o vocabulário não tem
    parse.json-error). Recusa com parse.yaml-error: sintaxe fora da RFC 8259, NaN e Infinity, BOM fora do início,
    surrogate solto (I-JSON) e mais de 128 coleções aninhadas. A profundidade é medida antes de canonical(), e o
    RecursionError do próprio json.loads (um texto de milhares de níveis) também é parse.yaml-error. A ordem é a do
    leitor JS: vazio, sintaxe, profundidade e surrogate, chave repetida, null, raiz."""
    if not _json_body(text).strip(_JSON_WS):
        return None, None, "parse.empty-document"
    dups = []
    try:
        value = _load_json(text, dups)
    except (ValueError, RecursionError):
        return None, None, "parse.yaml-error"
    if collection_depth(value) > PROFILE_DEPTH or has_lone_surrogate(value):
        return None, None, "parse.yaml-error"
    if dups:
        return None, None, "parse.duplicate-key"
    if value is None:
        return None, None, "parse.empty-document"
    if not isinstance(value, dict):
        return None, None, "parse.root-not-mapping"
    return value, canonical(value, json_keys=True), None  # 1e400 vira inf e daí NonFinite, como o .inf do YAML


@functools.lru_cache(maxsize=1024, typed=True)
def parse_v1(text):
    """O parse do contrato v1, um só para codes(), warnings() e external_info(): (documento cru, canônico, código).
    Guardado por texto (lru_cache): o mesmo arquivo é parseado uma vez por processo, e nenhum chamador altera o
    documento devolvido, que é compartilhado. O parser em C entra só como atalho (loader_for); quando o documento
    é fundo demais, refaz com o puro, cujo veredito é o de referência. Um JsonText vai ao parser JSON (_parse_json);
    o cache é typed, para o mesmo texto lido como YAML e como JSON não se misturar."""
    if isinstance(text, JsonText):
        return _parse_json(text)
    if _too_deep(text):
        return None, None, "parse.yaml-error"
    loader = loader_for(text)
    raw_doc, doc, code, raw = _parse(text, loader)
    if loader is not Yaml12CoreLoader and (raw is not None or code == "parse.duplicate-key") and (
            (raw is not None and _depth(raw) > SAFE_DEPTH) or _multiline_quoted(text)):
        raw_doc, doc, code, raw = _parse(text, Yaml12CoreLoader)
    return raw_doc, doc, code


def _multiline_quoted(text):
    """O texto tem algum escalar entre aspas de várias linhas? As regras da continuação entre aspas (o tab e a
    indentação) são conferidas só no parser puro; este teste, feito pelos tokens do scanner em C, manda ao puro só
    o texto que as precisa. Medido em 2026-10-20 no maior grafo do SGE (454 KB): 0,03 s, contra 0,7 s do puro."""
    if "'" not in text and '"' not in text:
        return False
    try:
        for tok in yaml.scan(text, Loader=FAST_LOADER):
            if isinstance(tok, yaml.ScalarToken) and tok.style in ("'", '"') and tok.start_mark.line != tok.end_mark.line:
                return True
    except yaml.YAMLError:
        return True  # o C não leu: o puro decide
    return False


def code_counts(text, validator, corpus=None):
    """Os códigos MUST de codes() com a contagem de ocorrências: Counter código → quantas vezes.

    As chaves são exatamente as de codes(); a contagem é o que a saída humana mostra (33 nós sem
    provenance, 7 arestas com on). Um código de parse conta 1: o arquivo não chega ao schema.
    """
    raw, doc, parse_code = parse_v1(text)
    if parse_code:
        return collections.Counter([parse_code])
    out = collections.Counter(c for err in validator.iter_errors(doc) for c in form_codes(err))
    out.update(non_finite_codes(doc) | (unsafe_integer_codes(doc) if isinstance(text, JsonText) else set()))
    out.update(integrity(doc, refs=("trigger", "on"), corpus=corpus))
    edges = doc.get("edges") if isinstance(doc.get("edges"), list) else []
    with_on = sum(1 for e in edges if isinstance(e, dict) and "on" in e)
    if with_on:
        out["yaml.forbidden-key-on"] += with_on  # o perfil proíbe on (em YAML 1.1 ela vira o booleano True)
    return out


def codes(text, validator, corpus=None):
    """Os códigos MUST que este leitor emite para um arquivo: lista ordenada, sem repetição.

    É a interface da suíte de conformidade (spec/conformance/). Mede as mesmas três camadas de
    check() (parse, schema, integridade), mas com a taxonomia estável da suíte (form_codes) em vez
    das chaves de classify(), e conta documentos nulos no parse.
    """
    return sorted(code_counts(text, validator, corpus))


def _has_unquoted_date(value):
    if isinstance(value, dict):
        return any(_has_unquoted_date(k) or _has_unquoted_date(v) for k, v in value.items())
    if isinstance(value, list):
        return any(_has_unquoted_date(v) for v in value)
    return isinstance(value, UnquotedDate)


SLUG = re.compile(r"^[A-Za-z_][A-Za-z0-9_-]*$")


ISO_PREFIX = re.compile(r"^[0-9]{4}(-[0-9]{2}(-[0-9]{2})?)?$")
TESTIMONY_METHOD = re.compile(r"^testemunho: ")


def coherence_located(doc, corpus=None):
    """Os avisos SHOULD que o schema não exprime, porque cruzam campos ou arestas:

    - integrity.testimony-in-prod: nó PROD cuja base é testemunho (evidence_class: testimony ou method da classe
      testemunho): relato não é artefato vivo, e o plane pede DEV;
    - integrity.verified-before-fact: verified_at anterior a valid_from, comparados na granularidade do mais curto
      (AAAA, AAAA-MM ou AAAA-MM-DD); data que não está nessa forma não é comparada;
    - integrity.untraced-decision: decision viva (não superseded nem refuted) sem origem: nem trace com texto, nem
      provenance, nem aresta TRACES_TO saindo dela.
    - integrity.refutes-unreconciled: nó que recebe REFUTES e segue vivo (nem superseded nem refuted; uma question
      done já está respondida): o grafo afirma e refuta a mesma coisa. É a contradição do radar, como aviso no v4.4.
      Desde o v4.5, com o corpus (corpus_index), conta também a REFUTES que chega de outro grafo pelas external_edges
      (from externo, to local); sem ele, a ponta externa não foi conferida e a aresta não conta.
    Um campo de tipo errado (from ou id em lista ou mapa) já reprova no MUST: aqui ele é ignorado, nunca quebra.
    """
    out = []
    edges = doc.get("edges") if isinstance(doc.get("edges"), list) else []
    # só texto entra no conjunto: um from ou id em lista ou mapa já reprova no MUST, e aqui não pode quebrar o leitor
    traced = {e.get("from") for e in edges
              if isinstance(e, dict) and e.get("edge_type") == "TRACES_TO" and isinstance(e.get("from"), str)}
    refuted = {e.get("to") for e in edges
               if isinstance(e, dict) and e.get("edge_type") == "REFUTES" and isinstance(e.get("to"), str)}
    if corpus is not None:
        ext = doc.get("external_edges") if isinstance(doc.get("external_edges"), list) else []
        refuted |= {e.get("to") for e in ext
                    if isinstance(e, dict) and e.get("edge_type") == "REFUTES" and is_external(e.get("from"))
                    and isinstance(e.get("to"), str) and not is_external(e.get("to"))}
    for n, place in _located(doc, "nodes"):
        prov = n.get("provenance") if isinstance(n.get("provenance"), dict) else {}
        method = prov.get("method")
        if n.get("plane") == "PROD" and (n.get("evidence_class") == "testimony"
                                         or (isinstance(method, str) and TESTIMONY_METHOD.match(method))):
            out.append(("integrity.testimony-in-prod", place))
        vf, va = n.get("valid_from"), n.get("verified_at")
        if isinstance(vf, str) and isinstance(va, str) and ISO_PREFIX.fullmatch(vf) and ISO_PREFIX.fullmatch(va):
            k = min(len(vf), len(va))
            if va[:k] < vf[:k]:
                out.append(("integrity.verified-before-fact", place))
        trace = n.get("trace")
        if (n.get("node_type") == "decision" and n.get("status") not in ("superseded", "refuted")
                and not (isinstance(trace, str) and trace.strip()) and not prov
                and not (isinstance(n.get("id"), str) and n["id"] in traced)):
            out.append(("integrity.untraced-decision", place))
        status = n.get("status")
        if (isinstance(n.get("id"), str) and n["id"] in refuted and status not in ("superseded", "refuted")
                and not (status == "done" and n.get("node_type") == "question")):
            out.append(("integrity.refutes-unreconciled", place))
    return out


def yaml_profile_warnings(text, raw):
    """Os pontos 1 a 3 do perfil JSON no .kg.yaml, como aviso SHOULD (a rampa do CRITERIA.md do v2; no .kg.json eles
    são MUST e reprovam antes daqui): yaml.unsafe-integer (inteiro fora de ±(2^53−1)), yaml.lone-surrogate (surrogate
    solto em chave ou valor) e yaml.depth-over-128 (mais de 128 coleções aninhadas). Um por arquivo, como a data sem
    aspas. O teto de parse do YAML (MAX_DEPTH) continua como está."""
    if isinstance(text, JsonText):
        return []
    out = []
    if _contains(raw, is_unsafe_integer):
        out.append("yaml.unsafe-integer")
    if has_lone_surrogate(raw):
        out.append("yaml.lone-surrogate")
    if collection_depth(raw) > PROFILE_DEPTH:
        out.append("yaml.depth-over-128")
    return out


def coherence_warnings(doc, corpus=None):
    """Os avisos de coherence_located() contados por código (Counter)."""
    return collections.Counter(code for code, _ in coherence_located(doc, corpus))


def warning_counts(text, validator, should_validator, corpus=None):
    """Os códigos SHOULD de warnings() com a contagem de ocorrências (as chaves são as de warnings())."""
    raw, doc, parse_code = parse_v1(text)
    if parse_code:
        return collections.Counter()
    must = {c for err in validator.iter_errors(doc) for c in form_codes(err)}
    should = collections.Counter(c for err in should_validator.iter_errors(doc) for c in form_codes(err))
    out = collections.Counter({c: n for c, n in should.items() if c not in must})
    if _has_unquoted_date(raw):
        out["yaml.unquoted-date"] += 1
    out.update(yaml_profile_warnings(text, raw))
    out.update(coherence_warnings(doc, corpus))
    return out


def schema_place(doc, path):
    """O lugar de um erro do schema a partir do caminho: o nó ou a aresta, o meta, ou o topo."""
    if path and path[0] in ("nodes", "edges", "external_edges") and len(path) >= 2 and isinstance(path[1], int):
        items = doc.get(path[0]) if isinstance(doc.get(path[0]), list) else []
        return item_place(path[0], path[1], items[path[1]] if path[1] < len(items) else None)
    return "meta" if path and path[0] == "meta" else "topo"


def where(text, validator, should_validator=None, corpus=None):
    """Cada ocorrência com o lugar: lista de (nível, código, lugar), nível MUST ou SHOULD.

    Os códigos são exatamente os que code_counts() e warning_counts() contam, ocorrência por ocorrência (o teste
    test_where_tem_os_mesmos_codigos_que_a_contagem guarda isso). O que não tem lugar mais fino sai como 'arquivo':
    o parse, o .nan/.inf e a data sem aspas. Deriva de occurrences(), que acrescenta o caminho no documento."""
    return [(level, code, place) for level, code, place, _ in occurrences(text, validator, should_validator, corpus)]


def warnings(text, validator, should_validator, corpus=None):
    """Os códigos SHOULD: o que o schema SHOULD acusa e o MUST não, mais data sem aspas e os avisos de coerência
    (coherence_warnings).

    Arquivo que já reprova no parse não recebe alerta de forma. Chave desconhecida cujo nome não é
    slug (<<, 1.0) alerta como form.pattern.<escopo>.key, o código que o schema SHOULD emite para ela.
    """
    return sorted(warning_counts(text, validator, should_validator, corpus))


VERDICT_SCHEMA_VERSION = "kg-ssot.verdict/1"
PLACE_NODE = re.compile(r"^nó (?:#(\d+)|(.+?))(?: \(#(\d+)\))?$")  # 'nó A (#3)': a repetição de um id
PLACE_ITEM = re.compile(r"^aresta (externa )?#(\d+)")


def place_path(doc, place):
    """O caminho no documento ['nodes', 7] a partir do lugar legível de where() ('nó X', 'aresta #3 (...)', 'meta')."""
    if place == "meta":
        return ["meta"]
    m = PLACE_ITEM.match(place)
    if m:
        return ["external_edges" if m.group(1) else "edges", int(m.group(2)) - 1]
    m = PLACE_NODE.match(place)
    if m:
        if m.group(3):  # a posição explícita da repetição vence o id, que é ambíguo
            return ["nodes", int(m.group(3)) - 1]
        if m.group(1):
            return ["nodes", int(m.group(1)) - 1]
        nodes = doc.get("nodes") if isinstance(doc.get("nodes"), list) else []
        for i, n in enumerate(nodes):
            if isinstance(n, dict) and str(n.get("id")) == m.group(2):
                return ["nodes", i]
    return []


def path_text(path):
    """['nodes', 7, 'provenance', 'method'] → 'nodes[7].provenance.method' (o índice conta de 0, como no JSON)."""
    out = ""
    for p in path:
        out += f"[{p}]" if isinstance(p, int) else (f".{p}" if out else str(p))
    return out


def yaml_lines(text):
    """A árvore de nós do YAML (compose, sem construir valores), para achar a linha de um caminho; None se não compõe.
    Um JsonText não passa pelo compose (a libyaml só aceita str exato, e o JSON não é lido como YAML): None; a linha
    do .kg.json vem de json_lines."""
    if isinstance(text, JsonText) or _too_deep(text):  # o mesmo teto do parse: compor isto derruba o processo
        return None
    try:
        return yaml.compose(text, Loader=getattr(yaml, "CSafeLoader", yaml.SafeLoader))
    except (yaml.YAMLError, RecursionError, UnicodeEncodeError, ValueError):
        return None


def json_lines(text):
    """{caminho (tupla): linha} de um .kg.json, com a semântica de line_of no YAML: num objeto, a linha da CHAVE; numa
    lista, a do início do item; a raiz, a do início do documento. A linha conta \\n, como o JSONDecodeError (um CR solto,
    sem \\n, não abre linha; pelo CLI o arquivo é lido com quebras universais e o caso não aparece). A chave
    entra decodificada (os escapes resolvidos), como o caminho do schema a vê. None se o texto não varre."""
    s = _json_body(text)
    breaks = [i for i, c in enumerate(s) if c == "\n"]
    n, out = len(s), {}

    def line(i):
        return bisect.bisect_left(breaks, i) + 1

    def skip(i):
        while i < n and s[i] in _JSON_WS:
            i += 1
        return i

    def string_end(i):
        j = i + 1
        while s[j] != '"':
            j += 2 if s[j] == "\\" else 1
        return j + 1

    def value(i, path):  # a profundidade já foi limitada a 128 pelo parse do perfil
        i = skip(i)
        out.setdefault(path, line(i))
        if s[i] in "{[":
            close, idx = ("}", None) if s[i] == "{" else ("]", 0)
            i = skip(i + 1)
            if s[i] == close:
                return i + 1
            while True:
                i = skip(i)
                if idx is None:
                    end = string_end(i)
                    key = json.loads(s[i:end])
                    out[path + (key,)] = line(i)
                    i = skip(end) + 1  # o ':'
                    i = value(i, path + (key,))
                else:
                    i = value(i, path + (idx,))
                    idx += 1
                i = skip(i)
                if s[i] == close:
                    return i + 1
                i += 1  # a vírgula
        if s[i] == '"':
            return string_end(i)
        j = i
        while j < n and s[j] not in ",]}" and s[j] not in _JSON_WS:
            j += 1
        return j

    try:
        value(0, ())
    except (IndexError, ValueError, RecursionError):
        return None
    return out


def line_of(tree, path):
    """A linha (contando de 1) do ponto mais fundo do caminho que existe no documento; None sem árvore. A árvore é a
    do YAML (yaml_lines) ou o mapa de caminho para linha do .kg.json (json_lines)."""
    if isinstance(tree, dict):
        line = tree.get(())
        for k in range(1, len(path) + 1):
            if tuple(path[:k]) not in tree:
                break
            line = tree[tuple(path[:k])]
        return line
    node, line = tree, (tree.start_mark.line + 1 if tree is not None else None)
    for p in path:
        if isinstance(node, yaml.MappingNode):
            pair = next(((k, v) for k, v in node.value if isinstance(k, yaml.ScalarNode) and k.value == str(p)), None)
            if pair is None:
                break
            line, node = pair[0].start_mark.line + 1, pair[1]  # a linha da CHAVE: um alias divide o nó do valor
        elif isinstance(node, yaml.SequenceNode) and isinstance(p, int) and 0 <= p < len(node.value):
            node = node.value[p]
            line = node.start_mark.line + 1
        else:
            break
    return line


MESSAGES = {
    "parse.yaml-error": "O arquivo não é YAML válido.",
    "parse.duplicate-key": "Há uma chave repetida no mesmo mapa.",
    "parse.empty-document": "O arquivo está vazio ou só tem comentário.",
    "parse.not-single-document": "O arquivo tem mais de um documento YAML; deve ter um só.",
    "parse.root-not-mapping": "A raiz do arquivo não é um mapa (meta, nodes, edges).",
    "integrity.duplicate-id": "Dois nós têm o mesmo id.",
    "integrity.orphan-node": "O nó não tem nenhuma aresta: está solto no grafo.",
    "integrity.dangling-external": "A ponta externa aponta para um arquivo ou um id que não existe no corpus.",
    "integrity.dangling-external-local": "A ponta local da aresta externa não existe neste arquivo.",
    "integrity.testimony-in-prod": "O nó está em PROD, mas a única base dele é testemunho.",
    "integrity.verified-before-fact": "A data de verificação (verified_at) é anterior à data do fato (valid_from): "
                                      "ou o fato tem vigência futura, ou as datas estão trocadas.",
    "integrity.untraced-decision": "A decisão não diz de onde veio: falta trace, provenance ou aresta TRACES_TO.",
    "integrity.refutes-unreconciled": "O nó recebe REFUTES e segue valendo: o grafo afirma e refuta a mesma coisa.",
    "yaml.unquoted-date": "Há uma data sem aspas; leitores YAML diferentes a leem de formas diferentes.",
    "yaml.forbidden-key-on": "A aresta usa a chave on, proibida (em YAML 1.1 ela vira o booleano True).",
    "yaml.unsafe-integer": "Há um número inteiro fora de ±(2^53−1); um leitor JS (double) perde o valor exato dele.",
    "yaml.lone-surrogate": "Há um surrogate solto (U+D800 a U+DFFF sem o par) numa chave ou num texto.",
    "yaml.depth-over-128": "O documento aninha mais de 128 coleções (mapas e listas).",
}
# No .kg.json, os códigos de parse são os mesmos do YAML (o vocabulário não tem parse.json-error), e a frase diz o
# formato em que o texto foi lido (O7 da medição da opção b).
JSON_MESSAGES = {
    "parse.yaml-error": "O arquivo não é JSON válido no perfil do .kg.json: sintaxe da RFC 8259 (sem comentário, "
                        "vírgula sobrando, aspas simples, NaN nem Infinity), um BOM só no início, nenhum surrogate "
                        "solto e até 128 coleções aninhadas.",
    "parse.duplicate-key": "Há uma chave repetida no mesmo objeto JSON (comparada depois de resolvidos os escapes).",
    "parse.empty-document": "O arquivo JSON está vazio, só tem espaço em branco ou é null.",
    "parse.root-not-mapping": "A raiz do arquivo JSON não é um objeto (meta, nodes, edges).",
}
HINTS = {
    "yaml.unquoted-date": 'Ponha a data entre aspas, por exemplo verified_at: "2026-10-13".',
    "yaml.forbidden-key-on": "Troque on: por trigger:.",
    "yaml.unsafe-integer": "Escreva o número entre aspas, como texto, ou use um valor dentro de ±9007199254740991.",
    "yaml.lone-surrogate": "Troque o escape solto pelo caractere inteiro (o par alto e baixo) ou remova-o.",
    "yaml.depth-over-128": "Achate a estrutura: um grafo de verdade fica em 3 ou 4 níveis.",
    "integrity.orphan-node": "Todo nó precisa de pelo menos uma aresta. Ligue-o a outro nó em edges (from: o id dele, "
                             "to: o id do outro, edge_type: TRACES_TO, SUPPORTS ou DEPENDS_ON, o que disser a relação), "
                             "ou remova o nó.",
    "integrity.verified-before-fact": "Se o fato tem vigência futura (uma norma lida antes de entrar em vigor), o aviso é "
                                      "esperado e pode ficar na linha de base do gate. Se não, as datas estão trocadas: "
                                      "valid_from é quando o fato passou a valer, e verified_at, quando foi conferido.",
    "integrity.duplicate-id": "Dê um id único a cada nó.",
    "integrity.untraced-decision": "Acrescente trace, provenance ou uma aresta TRACES_TO saindo da decisão.",
    "integrity.refutes-unreconciled": "Se a refutação procede, mude o status do alvo para refuted ou superseded; se não, tire a aresta ou use CONSTRAINS (o dissent que limita sem derrubar).",
    "integrity.testimony-in-prod": "Deixe o nó em DEV, ou apoie-o numa medição ou leitura conferida.",
    "form.required.node.provenance": "Acrescente provenance com source, locator e method; sem fonte recuperável, "
                                     "mude o status para unverifiable.",
    "form.required.node.label": "Acrescente label: a afirmação curta do nó, até 280 caracteres.",
    "form.range.node.label": "Encurte o label até 280 caracteres e leve o resto para narrative.",
    "form.pattern.node.provenance.method": "Use a forma '<classe>: <detalhe>', com classe medição, leitura, juízes, "
                                           "derivado ou testemunho.",
    "form.pattern.node.provenance.source": "Escreva a fonte de verdade (URL, caminho, comando); sem fonte recuperável, "
                                           "tire a provenance e mude o status para unverifiable.",
}
KIND_TEXT = {"required": "Falta o campo obrigatório", "enum": "Valor fora da lista permitida em",
             "type": "Tipo errado em", "pattern": "Valor fora da forma esperada em", "range": "Valor fora do limite em",
             "const": "Valor diferente do exigido em", "unknown-key": "Chave fora da gramática (sem prefixo x_):"}
SCOPE_TEXT = {"node": "no nó", "edge": "na aresta", "meta": "no meta", "top": "no topo"}


def message_of(code, json_text=False):
    """A frase humana em pt-BR de um código: a específica, ou a montada da forma form.<tipo>.<escopo>.<campo>.
    json_text: o texto foi lido como .kg.json, e a frase de parse diz isso (JSON_MESSAGES)."""
    if json_text and code in JSON_MESSAGES:
        return JSON_MESSAGES[code]
    if code in MESSAGES:
        return MESSAGES[code]
    parts = code.split(".")
    if parts[0] == "form" and len(parts) >= 4 and parts[1] in KIND_TEXT:
        field = ".".join(parts[3:])
        return f"{KIND_TEXT[parts[1]]} «{field}» {SCOPE_TEXT.get(parts[2], parts[2])}."
    return f"Violação {code}."


def hint_of(code, place=None):
    """A correção do código; no integrity.orphan-node com o lugar 'nó X', a dica traz o id do nó. Um nó sem id ('nó #2',
    o índice) fica com a dica genérica: não há id para citar."""
    if (code == "integrity.orphan-node" and isinstance(place, str) and place.startswith("nó ")
            and not place.startswith("nó #")):
        nid = place[3:]
        return (f"Todo nó precisa de pelo menos uma aresta. Ligue {nid} a outro nó em edges (from: {nid}, to: o id do "
                "outro, edge_type: TRACES_TO, SUPPORTS ou DEPENDS_ON, o que disser a relação), ou remova o nó.")
    if code in HINTS:
        return HINTS[code]
    if code.startswith("form.unknown-key."):
        return "Renomeie a chave com o prefixo x_ (extensão que os leitores ignoram) ou remova-a."
    return None


def occurrences(text, validator, should_validator=None, corpus=None):
    """As ocorrências de where() com o caminho no documento e a linha do YAML: [(nível, código, lugar, caminho)].

    O caminho vem do erro do schema quando existe (aponta o campo: nodes[7].provenance.method); senão, do lugar
    legível ('nó X' → nodes[i]). Os códigos são exatamente os de where()."""
    raw, doc, parse_code = parse_v1(text)
    if parse_code:
        return [("MUST", parse_code, "arquivo", [])]
    out, must = [], set()
    for err in validator.iter_errors(doc):
        path = list(err.absolute_path)
        for code in form_codes(err):
            out.append(("MUST", code, schema_place(doc, path), path))
            must.add(code)
    typed = non_finite_codes(doc) | (unsafe_integer_codes(doc) if isinstance(text, JsonText) else set())
    out += [("MUST", code, "arquivo", []) for code in sorted(typed)]
    out += [("MUST", code, place, place_path(doc, place))
            for code, place in integrity_located(doc, refs=("trigger", "on"), corpus=corpus)]
    out += [("MUST", "yaml.forbidden-key-on", place, place_path(doc, place) + ["on"])
            for e, place in _located(doc, "edges") if "on" in e]
    if should_validator is not None:
        for err in should_validator.iter_errors(doc):
            path = list(err.absolute_path)
            out += [("SHOULD", code, schema_place(doc, path), path) for code in form_codes(err) if code not in must]
        if _has_unquoted_date(raw):
            out.append(("SHOULD", "yaml.unquoted-date", "arquivo", []))
        out += [("SHOULD", code, "arquivo", []) for code in yaml_profile_warnings(text, raw)]
        out += [("SHOULD", code, place, place_path(doc, place)) for code, place in coherence_located(doc, corpus)]
    return out


def verdict(text, validator, should_validator=None, corpus=None, source=None, limit=50):
    """O veredito estruturado de um grafo (formato kg-ssot.verdict/1, JSON Schema em spec/verdict.schema.json).

    verdict é PASS sem MUST e FAIL com qualquer MUST (um arquivo que não parseia reprova com parse.*, como na suíte).
    summary conta TODAS as ocorrências por nível e código; occurrences traz até `limit`, com truncated e total."""
    occ = occurrences(text, validator, should_validator, corpus)
    tree = (json_lines(text) if isinstance(text, JsonText) else yaml_lines(text)) if occ else None
    parse_line = parse_error_line(text) if occ and occ[0][1].startswith("parse.") else None
    summary = {"MUST": collections.Counter(), "SHOULD": collections.Counter()}
    for level, code, _, _ in occ:
        summary[level][code] += 1
    items = []
    for level, code, place, path in occ[:limit]:
        item = {"level": level, "code": code, "place": place, "path": path_text(path),
                "line": (parse_line if code.startswith("parse.") else line_of(tree, path) if tree is not None and path
                         else None),
                "message": message_of(code, isinstance(text, JsonText))}
        hint = hint_of(code, place)
        if hint:
            item["hint"] = hint
        items.append(item)
    return {"source": source, "verdict": "FAIL" if summary["MUST"] else "PASS",
            "summary": {k: dict(sorted(v.items())) for k, v in summary.items()},
            "occurrences": items, "total": len(occ), "truncated": len(occ) > limit}


def contract_info(must_path, should_path):
    """De onde veio o julgamento: os caminhos do contrato, o sha256 de cada um e a release que o leitor carrega."""
    def sha(p):
        return hashlib.sha256(pathlib.Path(p).read_bytes()).hexdigest() if p else None
    home = _ROOT
    release = None
    try:
        release = json.loads((home / "spec" / "release.json").read_text(encoding="utf-8")).get("tag")
    except (OSError, ValueError):
        pass

    def rel(p):
        if not p:
            return None
        try:
            return pathlib.Path(p).resolve().relative_to(home).as_posix()
        except ValueError:
            return pathlib.Path(p).name
    return {"must": rel(must_path), "should": rel(should_path), "release": release,
            "sha256": {"must": sha(must_path), "should": sha(should_path)}}


@functools.lru_cache(maxsize=8)
def _validator_at(path):
    with open(path, encoding="utf-8") as fh:
        return make_validator(json.load(fh))


def judge(sources, schema=CONTRACT_MUST, should_schema=None, corpus=None, limit=50):
    """O documento kg-ssot.verdict/1 inteiro para [(source, text), ...]: o que o CLI imprime com --format json, como
    biblioteca (o armazém em kg_store.py e quem adota chamam isto em vez de raspar o stdout). corpus é o índice de
    corpus_index()/index_texts(), ou None. Schema ilegível sobe OSError/ValueError: é entrada quebrada de quem chama."""
    should_schema = should_schema or should_for(schema)
    validator = _validator_at(str(schema))
    should_v = _validator_at(str(should_schema)) if should_schema else None
    reports = []
    for name, text in sources:
        r = verdict(text, validator, should_v, corpus, source=name, limit=limit)
        r["external_checked"] = corpus is not None or not uses_external(text)
        reports.append(r)
    return {"schema_version": VERDICT_SCHEMA_VERSION, "contract": contract_info(schema, should_schema),
            "results": reports}


def load_sources(args):
    if args.git:
        names = [l.strip() for l in open(args.list) if l.strip()]
        for name in names:
            text = subprocess.run(["git", "-C", args.git, "show", f"{args.rev}:{name}"],
                                  capture_output=True, text=True, check=True).stdout
            yield name, as_source(name, text)
    else:
        for name in args.files:
            if name == "-":
                stream = getattr(sys.stdin, "buffer", None)  # UTF-8 inválido é UnicodeDecodeError: rc 2
                text = stream.read().decode("utf-8") if stream is not None else sys.stdin.read()
                yield "-", JsonText(text) if args.stdin_format == "json" else text  # o stdin não tem extensão
                continue
            with open(name, encoding="utf-8") as fh:
                yield name, as_source(name, fh.read())


DURATION = re.compile(r"^P(?:([0-9]+)Y)?(?:([0-9]+)M)?(?:([0-9]+)W)?(?:([0-9]+)D)?$")  # o pattern do SHOULD, sem hora
ISO_DATE = re.compile(r"[0-9]{4}-[0-9]{2}-[0-9]{2}")  # só AAAA-MM-DD: o fromisoformat aceitaria também 2026-W43-1


def parse_duration(value):
    """(anos, meses, semanas, dias) de uma duração ISO 8601 só com data (P3M, P1Y2W), ou None fora da forma ou
    zerada (P0D venceria no próprio dia do carimbo, para sempre; o SHOULD também a alerta)."""
    m = DURATION.fullmatch(value) if isinstance(value, str) else None
    if not m or not any(m.groups()):
        return None
    out = tuple(int(g or 0) for g in m.groups())
    return out if any(out) else None


def iso_date(value):
    """A data de um texto AAAA-MM-DD, ou None."""
    try:
        return datetime.date.fromisoformat(value) if isinstance(value, str) and ISO_DATE.fullmatch(value) else None
    except ValueError:
        return None


def add_duration(day, duration):
    """day somado à duração: anos e meses pelo calendário (o dia passa para o último do mês quando não existe, como
    31 de janeiro + P1M = 28 ou 29 de fevereiro), depois semanas e dias."""
    years, months, weeks, days = duration
    total = day.month - 1 + months + 12 * years
    year, month = day.year + total // 12, total % 12 + 1
    if year > datetime.MAXYEAR:
        raise OverflowError("a data passa do ano 9999")
    last = calendar.monthrange(year, month)[1]
    return datetime.date(year, month, min(day.day, last)) + datetime.timedelta(weeks=weeks, days=days)


def _as_date(value):
    if isinstance(value, datetime.datetime):
        return value.date()
    if isinstance(value, datetime.date):
        return value
    return iso_date(value)


def due_report(sources, as_of):
    """O relatório de vencimento (v4.8), fora do veredito: {as_of, due, unstamped, event, broken}. due: o nó com
    reverify_every válido cujo verified_at + a cadência é igual ou anterior a as_of; unstamped: cadência válida sem
    verified_at legível; event: só reverify_on; broken: o arquivo que não parseia. A cadência fora da forma não entra
    (o SHOULD já alerta form.pattern.node.reverify_every)."""
    out = {"as_of": as_of.isoformat(), "due": [], "unstamped": [], "event": [], "broken": []}
    for name, text in sources:
        _, doc, err = parse_v1(text)
        if err or not isinstance(doc, dict):
            out["broken"].append({"file": name, "error": str(err or "a raiz não é um mapa")})
            continue
        nodes = doc.get("nodes") if isinstance(doc.get("nodes"), list) else []
        for n in nodes:
            if not isinstance(n, dict) or n.get("id") is None:
                continue
            nid, every = str(n["id"]), n.get("reverify_every")
            duration = parse_duration(every)
            if duration is None:
                if isinstance(n.get("reverify_on"), str) and n["reverify_on"].strip():
                    out["event"].append({"file": name, "id": nid, "reverify_on": n["reverify_on"]})
                continue
            stamped = _as_date(n.get("verified_at"))
            if stamped is None:
                out["unstamped"].append({"file": name, "id": nid, "reverify_every": every})
                continue
            try:
                due_on = add_duration(stamped, duration)
            except (OverflowError, ValueError):
                continue  # vence depois do ano 9999: não vence na data pedida
            if due_on <= as_of:
                out["due"].append({"file": name, "id": nid, "verified_at": stamped.isoformat(), "reverify_every": every,
                                   "due_on": due_on.isoformat(), "days_late": (as_of - due_on).days,
                                   "reverify_on": n.get("reverify_on") if isinstance(n.get("reverify_on"), str) else None})
    return out


def due_lines(rep):
    lines = []
    for d in rep["due"]:
        lines.append(f"VENCIDO      {d['file']}  {d['id']}: verificado em {d['verified_at']}, a cada {d['reverify_every']},"
                     f" venceu em {d['due_on']}" + (f" ({d['days_late']} dias)" if d["days_late"] else " (hoje)"))
    for d in rep["unstamped"]:
        lines.append(f"SEM CARIMBO  {d['file']}  {d['id']}: cadência {d['reverify_every']} sem verified_at")
    for d in rep["event"]:
        lines.append(f"POR EVENTO   {d['file']}  {d['id']}: {d['reverify_on']}")
    for d in rep["broken"]:
        lines.append(f"NÃO LIDO     {d['file']}: {d['error']}")
    lines.append(f"· em {rep['as_of']}: {len(rep['due'])} vencido(s), {len(rep['unstamped'])} sem carimbo,"
                 f" {len(rep['event'])} por evento; o relatório não muda o veredito")
    return lines


def summarize(results):
    total = len(results)
    parse_ok = [r for r in results if r["parse"] is None]
    schema_ok = [r for r in parse_ok if not r["schema"]]
    full_ok = [r for r in schema_ok if not r["integrity"]]
    occurrences, files_hit, sole = collections.Counter(), collections.Counter(), collections.Counter()
    for r in parse_ok:
        classes = set(r["schema"])
        occurrences.update(r["schema"])
        files_hit.update(classes)
        if len(classes) == 1:
            sole[next(iter(classes))] += 1
    return {
        "files": total,
        "parse_pass": len(parse_ok),
        "schema_pass": len(schema_ok),
        "schema_and_integrity_pass": len(full_ok),
        "classes": [{"class": c, "files": files_hit[c], "occurrences": occurrences[c],
                     "unlocks_if_relaxed_alone": sole[c]}
                    for c, _ in sorted(files_hit.items(), key=lambda kv: (-kv[1], kv[0]))],
        "integrity": collections.Counter(i for r in results for i in r["integrity"]),
    }


def should_for(schema_path):
    """O SHOULD que acompanha um MUST: o vizinho <nome>.should.schema.json, se existe; senão, nenhum."""
    path = pathlib.Path(schema_path)
    if path.resolve() == CONTRACT_MUST.resolve():
        return CONTRACT_SHOULD
    if path.name.endswith(".schema.json") and not path.name.endswith(".should.schema.json"):
        sibling = path.with_name(path.name[:-len(".schema.json")] + ".should.schema.json")
        if sibling.is_file():
            return sibling
    return None


def fmt_counts(counter):
    return " · ".join(f"{c} ×{n}" for c, n in sorted(counter.items()))


def report(name, must, should, json_text=False):
    """As linhas humanas de um arquivo: veredito, códigos MUST e avisos SHOULD com contagem. Num .kg.json que não
    parseia, uma linha a mais diz que o texto foi lido como JSON (o código de parse é o mesmo do YAML)."""
    lines = [f"{'REPROVA' if must else 'PASSA  '} {name}"]
    if must:
        lines.append(f"  MUST   {fmt_counts(must)}")
        parse = [c for c in must if c.startswith("parse.")]
        if json_text and parse:
            lines.append(f"  JSON   {message_of(parse[0], True)}")
    if should:
        lines.append(f"  SHOULD {fmt_counts(should)}")
    return lines


def spike_summary(s):
    lines = [f"arquivos: {s['files']}  parse: {s['parse_pass']}  schema: {s['schema_pass']}  "
             f"schema+integridade: {s['schema_and_integrity_pass']}"]
    for c in s["classes"][:25]:
        lines.append(f"  {c['files']:4d} arq  {c['occurrences']:6d} ocorr  +{c['unlocks_if_relaxed_alone']:<3d} sozinho  {c['class']}")
    for k, v in s["integrity"].items():
        lines.append(f"  integridade {k}: {v}")
    return lines


def _utf8_stdio():
    """A saída que vai para pipe ou arquivo sai em UTF-8 (no Windows, o padrão seria cp1252, que derruba o ✓ e entrega
    a quem consome o JSON outra codificação); no terminal, fica a do console, trocando o caractere que ela não tem."""
    for stream in (sys.stdout, sys.stderr):
        if hasattr(stream, "reconfigure"):
            try:
                tty = stream.isatty()
            except ValueError:
                continue
            if tty:
                stream.reconfigure(errors="replace")
            else:
                stream.reconfigure(encoding="utf-8", errors="replace")


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--schema", default=str(CONTRACT_MUST), help="o MUST (default: o contrato vigente)")
    ap.add_argument("--should-schema", help="o SHOULD dos avisos (default: o que acompanha --schema)")
    ap.add_argument("--git")
    ap.add_argument("--rev")
    ap.add_argument("--list")
    ap.add_argument("--json", help="grava o formato do spike ({summary, results})")
    ap.add_argument("--spike", action="store_true", help="saída humana e rc do spike (check/classify)")
    ap.add_argument("--where", action="store_true", help="lista cada ocorrência com o nó ou a aresta em que ela sai")
    ap.add_argument("--corpus", metavar="DIR", help="raiz do repo: confere a ponta externa das external_edges contra os"
                                                     " .kg.yaml e .kg.json sob DIR (sem ela, só a forma e a ponta"
                                                     " local)")
    ap.add_argument("--due", metavar="AAAA-MM-DD", help="o relatório de vencimento na data (v4.8), no lugar do veredito")
    ap.add_argument("--format", choices=("human", "json"), default="human",
                    help="json: o veredito estruturado kg-ssot.verdict/1 (spec/verdict.schema.json) em stdout")
    ap.add_argument("--limit", type=int, default=50, help="no --format json, ocorrências por arquivo (default 50)")
    ap.add_argument("--stdin-format", choices=("yaml", "json"), default="yaml",
                    help="o formato do grafo lido de '-' (default yaml); um arquivo segue a extensão (.json é JSON)")
    ap.add_argument("files", nargs="*", help="arquivos .kg.yaml ou .kg.json; '-' lê o grafo do stdin")
    args = ap.parse_args(argv)
    _utf8_stdio()
    # no modo json o stdout é só JSON: a mensagem de entrada quebrada (rc 2) vai para o stderr
    say = (lambda msg: print(msg, file=sys.stderr)) if args.format == "json" else print
    if args.format == "json" and (args.spike or args.json or args.where):
        say("ENTRADA QUEBRADA  --format json não se combina com --spike, --json nem --where")
        return 2
    if args.limit < 1:
        say("ENTRADA QUEBRADA  --limit tem de ser 1 ou mais")
        return 2
    if args.where and args.spike:
        say("ENTRADA QUEBRADA  --where não vale com --spike (o spike tem saída própria, congelada)")
        return 2
    if args.due is not None:
        if args.spike or args.json or args.where or args.corpus:
            say("ENTRADA QUEBRADA  --due não se combina com --spike, --json, --where nem --corpus")
            return 2
        as_of = iso_date(args.due)
        if as_of is None:
            say(f"ENTRADA QUEBRADA  --due {args.due!r}: a data é AAAA-MM-DD")
            return 2
        try:
            rep = due_report(list(load_sources(args)), as_of)
        except (OSError, ValueError, UnicodeDecodeError, subprocess.CalledProcessError) as exc:
            say(f"ENTRADA QUEBRADA  {exc}")
            return 2
        if args.format == "json":
            print(json.dumps({"schema_version": "kg-ssot.due/1", **rep}, ensure_ascii=False, indent=1))
        else:
            print("\n".join(due_lines(rep)))
        return 0
    should_path = args.should_schema or should_for(args.schema)
    try:
        with open(args.schema, encoding="utf-8") as fh:
            validator = make_validator(json.load(fh))
        should_v = None
        if should_path:
            with open(should_path, encoding="utf-8") as fh:
                should_v = make_validator(json.load(fh))
        sources = list(load_sources(args))
    except (OSError, ValueError, UnicodeDecodeError, subprocess.CalledProcessError) as exc:
        say(f"ENTRADA QUEBRADA  {exc}")
        return 2
    try:
        corpus = corpus_index(args.corpus) if args.corpus else None
    except ValueError as exc:
        say(f"ENTRADA QUEBRADA  {exc}")
        return 2
    if args.format == "json":
        doc = judge(sources, args.schema, should_path, corpus, args.limit)
        print(json.dumps(doc, ensure_ascii=False, indent=1))
        return 1 if any(r["verdict"] == "FAIL" for r in doc["results"]) else 0
    results, lines, failed, warned, unchecked = [], [], 0, 0, 0
    for name, text in sources:
        r = check(text, validator)
        r["file"] = name
        results.append(r)
        if args.spike:
            continue
        must = code_counts(text, validator, corpus)
        unchecked += corpus is None and uses_external(text)
        should = warning_counts(text, validator, should_v, corpus) if should_v is not None else collections.Counter()
        failed += bool(must)
        warned += bool(should)
        lines += report(name, must, should, isinstance(text, JsonText))
        if args.where:  # a mesma ocorrência repetida (os ramos if/then do schema) vira uma linha com ×n
            found = collections.Counter(where(text, validator, should_v, corpus))
            for (level, code, place), n in sorted(found.items(), key=lambda x: (x[0][0] != "MUST", x[0][1:])):
                lines.append(f"    {level:<6} {code}  {place}" + (f" ×{n}" if n > 1 else ""))
                hint = hint_of(code, place) if level == "MUST" else None  # no MUST, a correção ao lado do lugar
                if hint:
                    lines.append(f"           → {hint}")
    summary = summarize(results)
    if args.json:
        with open(args.json, "w", encoding="utf-8") as fh:
            json.dump({"summary": summary, "results": results}, fh, ensure_ascii=False, indent=1)
    if args.spike:
        print("\n".join(spike_summary(summary)))
        return 0 if summary["schema_and_integrity_pass"] == summary["files"] else 1
    contract = pathlib.Path(args.schema).name + (f" + {pathlib.Path(should_path).name}" if should_path else "")
    lines.append(f"· {len(sources)} arquivos; {len(sources) - failed} passam no MUST; {warned} com aviso SHOULD"
                 f" ({contract})")
    if unchecked:
        lines.append(f"· {unchecked} arquivo(s) com external_edges: a ponta externa NÃO foi conferida (rode com --corpus"
                     " <raiz do repo>)")
    print("\n".join(lines))
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
