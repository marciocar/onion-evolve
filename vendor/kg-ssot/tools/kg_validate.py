#!/usr/bin/env python3
"""Leitor de referência NEUTRO do .kg.yaml: valida grafos contra um JSON Schema.

Depende só de Python 3, PyYAML e jsonschema. Não lê nada do harness (nem do Claude Code)
(D_KG_SSOT_INDEPENDENTE_DE_HARNESS). É o instrumento do spike Q_KG_SCHEMA_FORMAL_SPIKE.

Camadas medidas por arquivo:
  1. parse   — YAML válido, um documento só, raiz é mapa;
  2. schema  — o JSON canônico (datas em ISO, chaves em string) cumpre o schema;
  3. integrity — ids únicos, arestas sem ponta órfã e nenhum nó de grau 0 (o que JSON Schema não alcança).

Também é o leitor de referência da suíte spec/conformance/: codes(text, validator) devolve os
códigos MUST estáveis (parse.*, form.*, integrity.*) que tools/kg_conformance.py compara.

Saída humana (o CLI): por arquivo, o veredito e os códigos com o MESMO vocabulário do gate (kg_gate.py) e
da suíte, os de codes() e warnings() (parse.*, form.*, integrity.*, yaml.*), com a contagem de ocorrências:
  REPROVA <arquivo>   MUST  form.required.node.provenance ×33 · yaml.forbidden-key-on ×7
                      SHOULD form.required.node.provenance.verified_at ×33
  PASSA   <arquivo>   (SHOULD só avisa, não reprova)
Sem --schema, o contrato é o vigente (CONTRACT_MUST) e os avisos são do SHOULD dele (CONTRACT_SHOULD). Com
--schema S, o SHOULD é --should-schema, ou o vizinho S.should.schema.json quando existe, ou nenhum.

--corpus DIR liga a conferência da ponta externa das external_edges (v4.3) contra os .kg.yaml sob DIR.
--where acrescenta, por arquivo, uma linha por ocorrência com o nó ou a aresta (where()); a saída padrão não muda.
--spike troca a saída humana e o rc pelos do spike (check() e classify(), perfil Yaml12BoolLoader), para
reproduzir a medição do spike. --json OUT grava SEMPRE o formato do spike ({summary, results}),
congelado, para as medições gravadas seguirem reproduzíveis.

rc: 0 todo arquivo passa no MUST (com --spike: em schema + integridade) · 1 algum reprova · 2 entrada
quebrada (schema ou arquivo ilegível, git show que falha).

Uso:
  kg_validate.py [--schema S [--should-schema S2]] FILE...
  kg_validate.py --schema S --git REPO --rev SHA --list LISTFILE [--json OUT] [--spike]
"""
import argparse
import collections
import datetime
import json
import math
import pathlib
import subprocess
import sys

import re

import yaml
from jsonschema import Draft202012Validator, FormatChecker, validators
from jsonschema.exceptions import ValidationError


_ROOT = pathlib.Path(__file__).resolve().parent.parent
# O contrato VIGENTE, num lugar só: a suíte, a matriz, a medição do core e a catraca leem daqui.
CONTRACT_MUST = _ROOT / "spec" / "kg-contract-v4.schema.json"
CONTRACT_SHOULD = _ROOT / "spec" / "kg-contract-v4.should.schema.json"


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


class DuplicateKeyError(yaml.constructor.ConstructorError):
    """Chave repetida num mapa: o YAML 1.2 exige chaves únicas, e o PyYAML ficaria com a última."""


class Yaml12CoreLoader(Yaml12BoolLoader):
    """O perfil do contrato v1 (Q_CONTRACT_CONFORMANCE_LEVELS): YAML 1.2 core.

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
    return int(v[2:], 8) if v.startswith("0o") else int(v[2:], 16) if v.startswith("0x") else int(v)


Yaml12CoreLoader.add_constructor("tag:yaml.org,2002:int", _core_int)
Yaml12CoreLoader.add_constructor("tag:yaml.org,2002:timestamp",
                                 lambda loader, node: UnquotedDate(loader.construct_scalar(node)))


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
    """O validador do leitor de referência: Draft 2020-12 com pattern em semântica ECMA-262."""
    cls = validators.extend(Draft202012Validator, {"pattern": _ecma_pattern})
    return cls(schema, format_checker=FormatChecker(formats=["date"]))


class NonFinite:
    """.nan ou .inf no lugar de um valor: não é número, texto, objeto nem lista para o schema."""
    __slots__ = ("text",)

    def __init__(self, text):
        self.text = text

    def __repr__(self):
        return f"NonFinite({self.text})"


def _contains_non_finite(value):
    if isinstance(value, NonFinite):
        return True
    if isinstance(value, dict):
        return any(_contains_non_finite(v) for v in value.values())
    if isinstance(value, list):
        return any(_contains_non_finite(v) for v in value)
    return False


NESTED = {"node": ("provenance",)}  # objetos aninhados que o contrato define: o código desce neles


def non_finite_codes(doc):
    """form.type para .nan/.inf em QUALQUER posição, também onde o schema não tem tipo (x_, chave
    desconhecida, dentro de lista): o JSON não os representa, e um leitor JS perderia o dado."""
    out = set()
    for key, value in doc.items():
        if key in ("nodes", "edges") and isinstance(value, list):
            scope = "node" if key == "nodes" else "edge"
            for item in value:
                if isinstance(item, NonFinite):
                    out.add(f"form.type.{scope}.item")
                elif isinstance(item, dict):
                    for k, v in item.items():
                        if k in NESTED.get(scope, ()) and isinstance(v, dict):  # objeto que o schema define
                            out |= {f"form.type.{scope}.{k}.{kk}" for kk, vv in v.items() if _contains_non_finite(vv)}
                        elif _contains_non_finite(v):
                            out.add(f"form.type.{scope}.{k}")
        elif key == "meta" and isinstance(value, dict):
            out |= {f"form.type.meta.{k}" for k, v in value.items() if _contains_non_finite(v)}
        elif _contains_non_finite(value):
            out.add(f"form.type.top.{key}")
    return out


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
        # schema aceita (nem objeto), e o campo reprova como form.type (Q_CONTRACT_YAML_JSON_GAP).
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


EXTERNAL_REF = re.compile(r"^(?:[A-Za-z0-9_][A-Za-z0-9_.-]*/)*[A-Za-z0-9_][A-Za-z0-9_.-]*\.kg\.yaml#[A-Za-z][A-Za-z0-9_]*$")


def is_external(ref):
    return isinstance(ref, str) and EXTERNAL_REF.match(ref) is not None


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
    """[(caminho, texto)] → {caminho: {ids}}: o corpus montado de textos já lidos (a catraca lê o core por git show)."""
    index = {}
    for name, text in items:
        _, doc, _ = parse_v1(text)
        nodes = doc.get("nodes") if doc and isinstance(doc.get("nodes"), list) else []
        index[name] = {str(n["id"]) for n in nodes if isinstance(n, dict) and n.get("id") is not None}
    return index


EXTERNAL_TARGET = re.compile(r"(?<![A-Za-z0-9_./-])((?:[A-Za-z0-9_][A-Za-z0-9_.-]*/)*[A-Za-z0-9_][A-Za-z0-9_.-]*\.kg\.yaml)#[A-Za-z]")


def external_targets(text):
    """Os caminhos que as referências externas de um texto citam (barato, por padrão): só eles precisam entrar no
    corpus. Um caminho citado fora de external_edges só custa ler um arquivo a mais; nunca muda o veredito."""
    return set(EXTERNAL_TARGET.findall(text)) if uses_external(text) else set()


def uses_external(text):
    """Barato: o texto tem uma chave external_edges de topo? Só então vale montar o corpus."""
    return re.search(r"(?m)^external_edges\s*:", text) is not None


def corpus_index(root, files=None):
    """O corpus para conferir a ponta externa (v4.3): {caminho relativo a root: {ids}}. files: os caminhos a ler (o gate
    passa os .kg.yaml rastreados); sem files, os .kg.yaml rastreados se root é repo git, senão todo .kg.yaml sob root.
    Arquivo ilegível entra sem ids. root que não é diretório é entrada quebrada (ValueError)."""
    root = pathlib.Path(root)
    if not root.is_dir():
        raise ValueError(f"corpus {root} não é um diretório")
    if files is None:  # num repo git, os rastreados (como o gate); fora dele, todo arquivo regular sob root
        out = subprocess.run(["git", "-C", str(root), "ls-files", "-z", "--", "*.kg.yaml"], capture_output=True)
        if out.returncode == 0:
            files = [n for n in out.stdout.decode("utf-8").split("\0") if n]
        else:
            files = sorted(p.relative_to(root).as_posix() for p in root.rglob("*.kg.yaml")
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
    try:
        docs = [d for d in yaml.load_all(text, Loader=Yaml12BoolLoader) if d is not None]
    except yaml.YAMLError as exc:
        return {"parse": f"yaml-error: {str(exc).splitlines()[0]}", "schema": [], "integrity": []}
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
        if not SLUG.match(str(error.instance)):
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


def parse_v1(text):
    """O parse do contrato v1, um só para codes() e warnings(): (documento cru, canônico, código)."""
    try:
        raw = list(yaml.load_all(text, Loader=Yaml12CoreLoader))
    except DuplicateKeyError:
        return None, None, "parse.duplicate-key"
    except yaml.YAMLError:
        return None, None, "parse.yaml-error"
    docs = [d for d in raw if d is not None]
    if not docs:
        return None, None, "parse.empty-document"  # vazio, só comentário, `---` ou `~`
    if len(raw) != 1:
        return None, None, "parse.not-single-document"  # conta os nulos: um `---` a mais é outro documento
    if not isinstance(docs[0], dict):
        return None, None, "parse.root-not-mapping"
    try:
        return docs[0], canonical(docs[0], json_keys=True), None
    except DuplicateKeyError:
        return None, None, "parse.duplicate-key"
    except RecursionError:  # âncora recursiva (a: &x [*x]): não há documento finito para validar
        return None, None, "parse.yaml-error"


def code_counts(text, validator, corpus=None):
    """Os códigos MUST de codes() com a contagem de ocorrências: Counter código → quantas vezes.

    As chaves são exatamente as de codes(); a contagem é o que a saída humana mostra (33 nós sem
    provenance, 7 arestas com on). Um código de parse conta 1: o arquivo não chega ao schema.
    """
    raw, doc, parse_code = parse_v1(text)
    if parse_code:
        return collections.Counter([parse_code])
    out = collections.Counter(c for err in validator.iter_errors(doc) for c in form_codes(err))
    out.update(non_finite_codes(doc))
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


def coherence_located(doc):
    """Os avisos SHOULD que o schema não exprime, porque cruzam campos ou arestas (Q_RADAR_WARNINGS_WITHOUT_CASES):

    - integrity.testimony-in-prod: nó PROD cuja base é testemunho (evidence_class: testimony ou method da classe
      testemunho): relato não é artefato vivo, e o plane pede DEV;
    - integrity.verified-before-fact: verified_at anterior a valid_from, comparados na granularidade do mais curto
      (AAAA, AAAA-MM ou AAAA-MM-DD); data que não está nessa forma não é comparada;
    - integrity.untraced-decision: decision viva (não superseded nem refuted) sem origem: nem trace com texto, nem
      provenance, nem aresta TRACES_TO saindo dela.
    Um campo de tipo errado (from ou id em lista ou mapa) já reprova no MUST: aqui ele é ignorado, nunca quebra.
    """
    out = []
    edges = doc.get("edges") if isinstance(doc.get("edges"), list) else []
    # só texto entra no conjunto: um from ou id em lista ou mapa já reprova no MUST, e aqui não pode quebrar o leitor
    traced = {e.get("from") for e in edges
              if isinstance(e, dict) and e.get("edge_type") == "TRACES_TO" and isinstance(e.get("from"), str)}
    for n, place in _located(doc, "nodes"):
        prov = n.get("provenance") if isinstance(n.get("provenance"), dict) else {}
        method = prov.get("method")
        if n.get("plane") == "PROD" and (n.get("evidence_class") == "testimony"
                                         or (isinstance(method, str) and TESTIMONY_METHOD.match(method))):
            out.append(("integrity.testimony-in-prod", place))
        vf, va = n.get("valid_from"), n.get("verified_at")
        if isinstance(vf, str) and isinstance(va, str) and ISO_PREFIX.match(vf) and ISO_PREFIX.match(va):
            k = min(len(vf), len(va))
            if va[:k] < vf[:k]:
                out.append(("integrity.verified-before-fact", place))
        trace = n.get("trace")
        if (n.get("node_type") == "decision" and n.get("status") not in ("superseded", "refuted")
                and not (isinstance(trace, str) and trace.strip()) and not prov
                and not (isinstance(n.get("id"), str) and n["id"] in traced)):
            out.append(("integrity.untraced-decision", place))
    return out


def coherence_warnings(doc):
    """Os avisos de coherence_located() contados por código (Counter)."""
    return collections.Counter(code for code, _ in coherence_located(doc))


def warning_counts(text, validator, should_validator):
    """Os códigos SHOULD de warnings() com a contagem de ocorrências (as chaves são as de warnings())."""
    raw, doc, parse_code = parse_v1(text)
    if parse_code:
        return collections.Counter()
    must = {c for err in validator.iter_errors(doc) for c in form_codes(err)}
    should = collections.Counter(c for err in should_validator.iter_errors(doc) for c in form_codes(err))
    out = collections.Counter({c: n for c, n in should.items() if c not in must})
    if _has_unquoted_date(raw):
        out["yaml.unquoted-date"] += 1
    out.update(coherence_warnings(doc))
    return out


def schema_place(doc, path):
    """O lugar de um erro do schema a partir do caminho: o nó ou a aresta, o meta, ou o topo."""
    if path and path[0] in ("nodes", "edges", "external_edges") and len(path) >= 2 and isinstance(path[1], int):
        items = doc.get(path[0]) if isinstance(doc.get(path[0]), list) else []
        return item_place(path[0], path[1], items[path[1]] if path[1] < len(items) else None)
    return "meta" if path and path[0] == "meta" else "topo"


def where(text, validator, should_validator=None, corpus=None):
    """Cada ocorrência com o lugar: lista de (nível, código, lugar), nível MUST ou SHOULD (Q_VALIDATOR_NODE_LOCATIONS).

    Os códigos são exatamente os que code_counts() e warning_counts() contam, ocorrência por ocorrência (o teste
    test_where_tem_os_mesmos_codigos_que_a_contagem guarda isso). O que não tem lugar mais fino sai como 'arquivo':
    o parse, o .nan/.inf e a data sem aspas.
    """
    raw, doc, parse_code = parse_v1(text)
    if parse_code:
        return [("MUST", parse_code, "arquivo")]
    out, must = [], set()
    for err in validator.iter_errors(doc):
        place = schema_place(doc, list(err.absolute_path))
        for code in form_codes(err):
            out.append(("MUST", code, place))
            must.add(code)
    out += [("MUST", code, "arquivo") for code in sorted(non_finite_codes(doc))]
    out += [("MUST", code, place) for code, place in integrity_located(doc, refs=("trigger", "on"), corpus=corpus)]
    out += [("MUST", "yaml.forbidden-key-on", place) for e, place in _located(doc, "edges") if "on" in e]
    if should_validator is not None:
        for err in should_validator.iter_errors(doc):
            place = schema_place(doc, list(err.absolute_path))
            out += [("SHOULD", code, place) for code in form_codes(err) if code not in must]
        if _has_unquoted_date(raw):
            out.append(("SHOULD", "yaml.unquoted-date", "arquivo"))
        out += [("SHOULD", code, place) for code, place in coherence_located(doc)]
    return out


def warnings(text, validator, should_validator):
    """Os códigos SHOULD: o que o schema SHOULD acusa e o MUST não, mais data sem aspas e os avisos de coerência
    (coherence_warnings).

    Arquivo que já reprova no parse não recebe alerta de forma. Chave desconhecida cujo nome não é
    slug (<<, 1.0) alerta como form.pattern.<escopo>.key, o código que o schema SHOULD emite para ela.
    """
    return sorted(warning_counts(text, validator, should_validator))


def load_sources(args):
    if args.git:
        names = [l.strip() for l in open(args.list) if l.strip()]
        for name in names:
            text = subprocess.run(["git", "-C", args.git, "show", f"{args.rev}:{name}"],
                                  capture_output=True, text=True, check=True).stdout
            yield name, text
    else:
        for name in args.files:
            with open(name, encoding="utf-8") as fh:
                yield name, fh.read()


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


def report(name, must, should):
    """As linhas humanas de um arquivo: veredito, códigos MUST e avisos SHOULD com contagem."""
    lines = [f"{'REPROVA' if must else 'PASSA  '} {name}"]
    if must:
        lines.append(f"  MUST   {fmt_counts(must)}")
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
                                                     " .kg.yaml sob DIR (sem ela, só a forma e a ponta local)")
    ap.add_argument("files", nargs="*")
    args = ap.parse_args(argv)
    if args.where and args.spike:
        print("ENTRADA QUEBRADA  --where não vale com --spike (o spike tem saída própria, congelada)")
        return 2
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
        print(f"ENTRADA QUEBRADA  {exc}")
        return 2
    try:
        corpus = corpus_index(args.corpus) if args.corpus else None
    except ValueError as exc:
        print(f"ENTRADA QUEBRADA  {exc}")
        return 2
    results, lines, failed, warned, unchecked = [], [], 0, 0, 0
    for name, text in sources:
        r = check(text, validator)
        r["file"] = name
        results.append(r)
        if args.spike:
            continue
        must = code_counts(text, validator, corpus)
        unchecked += corpus is None and uses_external(text)
        should = warning_counts(text, validator, should_v) if should_v is not None else collections.Counter()
        failed += bool(must)
        warned += bool(should)
        lines += report(name, must, should)
        if args.where:  # a mesma ocorrência repetida (os ramos if/then do schema) vira uma linha com ×n
            found = collections.Counter(where(text, validator, should_v, corpus))
            lines += [f"    {level:<6} {code}  {place}" + (f" ×{n}" if n > 1 else "")
                      for (level, code, place), n in sorted(found.items(), key=lambda x: (x[0][0] != "MUST", x[0][1:]))]
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
