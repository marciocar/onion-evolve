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

Uso:
  kg_validate.py --schema spec/kg-strict.schema.json FILE...
  kg_validate.py --schema S --git REPO --rev SHA --list LISTFILE [--json OUT]
"""
import argparse
import collections
import datetime
import json
import math
import subprocess
import sys

import re

import yaml
from jsonschema import Draft202012Validator, FormatChecker, validators
from jsonschema.exceptions import ValidationError


_ROOT = __import__("pathlib").Path(__file__).resolve().parent.parent
# O contrato VIGENTE, num lugar só: a suíte, a matriz, a medição do core e a catraca leem daqui.
CONTRACT_MUST = _ROOT / "spec" / "kg-contract-v3.schema.json"
CONTRACT_SHOULD = _ROOT / "spec" / "kg-contract-v3.should.schema.json"


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


def _items(doc, key):
    """A lista de mapas sob a chave; escalar, mapa ou nulo no lugar da lista vira lista vazia."""
    raw = doc.get(key)
    return [x for x in raw if isinstance(x, dict)] if isinstance(raw, list) else []


def integrity(doc, refs=("on",)):
    """refs: as chaves de aresta que também são referência a nó. O spike usa só on (o legado que o
    radar lia); o contrato v1 usa trigger, e on segue como referência para não acusar o evento duas vezes."""
    out = []
    nodes = _items(doc, "nodes")
    # Só ids presentes entram no conjunto: um sentinela como str(None) casaria com um nó de id "None".
    ids = collections.Counter(str(n["id"]) for n in nodes if n.get("id") is not None)
    out += ["integrity.duplicate-id"] * sum(c - 1 for c in ids.values() if c > 1)
    touched = set()
    for e in _items(doc, "edges"):
        for end in ("from", "to"):
            ref = e.get(end)
            if ref is None or str(ref) not in ids:
                out.append(f"integrity.dangling-{end}")
            else:
                touched.add(str(ref))
        for key in refs:  # o gatilho de TRANSITIONS é referência ao evento
            if key in e:
                if e[key] is None or str(e[key]) not in ids:
                    out.append(f"integrity.dangling-{key}")
                else:
                    touched.add(str(e[key]))
    # Nó de grau 0 o radar reprova (achado do próprio spike: o leitor neutro não checava). Nó sem id
    # não pode ser ponta de aresta, então também tem grau 0.
    out += ["integrity.orphan-node"] * sum(1 for i in ids if i not in touched)
    out += ["integrity.orphan-node"] * sum(1 for n in nodes if n.get("id") is None)
    return out


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
    prefix = inner_names(path) if scope != "top" else []
    if "propertyNames" in error.schema_path:  # nível SHOULD: o nome da chave
        if error.validator == "pattern":  # nome que não é slug (<<, 1.0, chave com espaço)
            return [f"form.pattern.{scope}.{'.'.join(prefix + ['key'])}"]
        if not SLUG.match(str(error.instance)):
            return []  # nome não-slug já alerta como form.pattern.<escopo>.key; não repete como unknown-key
        return [f"form.unknown-key.{scope}.{'.'.join(prefix + [str(error.instance)])}"]  # fora da gramática e sem x_
    kind = FORM_TYPE.get(error.validator, error.validator)
    if error.validator in ("additionalProperties", "required"):
        # O erro é do OBJETO (o topo, o meta, um nó, uma aresta ou um objeto dentro deles).
        if error.validator == "required":
            return [f"form.{kind}.{scope}.{'.'.join(prefix + [p])}" for p in error.validator_value if p not in error.instance]
        extra = sorted(set(error.instance) - set(error.schema.get("properties", {})))
        return [f"form.{kind}.{scope}.{'.'.join(prefix + [k])}" for k in extra]
    # O erro é de um VALOR. Um item de lista que não é mapa (nodes: [a]) vira o campo `item`.
    scope = scope_of(path) if len(path) >= 2 else "top"
    if path and isinstance(path[-1], int):
        return [f"form.{kind}.{scope}.item"]
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


def codes(text, validator):
    """Os códigos MUST que este leitor emite para um arquivo: lista ordenada, sem repetição.

    É a interface da suíte de conformidade (spec/conformance/). Mede as mesmas três camadas de
    check() (parse, schema, integridade), mas com a taxonomia estável da suíte (form_codes) em vez
    das chaves de classify(), e conta documentos nulos no parse.
    """
    raw, doc, parse_code = parse_v1(text)
    if parse_code:
        return [parse_code]
    out = {c for err in validator.iter_errors(doc) for c in form_codes(err)}
    out |= non_finite_codes(doc)
    out |= set(integrity(doc, refs=("trigger", "on")))
    if any(isinstance(e, dict) and "on" in e for e in (doc.get("edges") if isinstance(doc.get("edges"), list) else [])):
        out.add("yaml.forbidden-key-on")  # o perfil proíbe on (em YAML 1.1 ela vira o booleano True)
    return sorted(out)


def _has_unquoted_date(value):
    if isinstance(value, dict):
        return any(_has_unquoted_date(k) or _has_unquoted_date(v) for k, v in value.items())
    if isinstance(value, list):
        return any(_has_unquoted_date(v) for v in value)
    return isinstance(value, UnquotedDate)


SLUG = re.compile(r"^[A-Za-z_][A-Za-z0-9_-]*$")


def warnings(text, validator, should_validator):
    """Os códigos SHOULD: o que o schema SHOULD acusa e o MUST não, mais data sem aspas.

    Arquivo que já reprova no parse não recebe alerta de forma. Chave desconhecida cujo nome não é
    slug (<<, 1.0) alerta como form.pattern.<escopo>.key, o código que o schema SHOULD emite para ela.
    """
    raw, doc, parse_code = parse_v1(text)
    if parse_code:
        return []
    must = {c for err in validator.iter_errors(doc) for c in form_codes(err)}
    should = {c for err in should_validator.iter_errors(doc) for c in form_codes(err)}
    out = should - must
    if _has_unquoted_date(raw):
        out.add("yaml.unquoted-date")
    return sorted(out)


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


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--schema", required=True)
    ap.add_argument("--git")
    ap.add_argument("--rev")
    ap.add_argument("--list")
    ap.add_argument("--json")
    ap.add_argument("files", nargs="*")
    args = ap.parse_args()
    with open(args.schema, encoding="utf-8") as fh:
        validator = make_validator(json.load(fh))
    results = []
    for name, text in load_sources(args):
        r = check(text, validator)
        r["file"] = name
        results.append(r)
    summary = summarize(results)
    if args.json:
        with open(args.json, "w", encoding="utf-8") as fh:
            json.dump({"summary": summary, "results": results}, fh, ensure_ascii=False, indent=1)
    s = summary
    print(f"arquivos: {s['files']}  parse: {s['parse_pass']}  schema: {s['schema_pass']}  "
          f"schema+integridade: {s['schema_and_integrity_pass']}")
    for c in s["classes"][:25]:
        print(f"  {c['files']:4d} arq  {c['occurrences']:6d} ocorr  +{c['unlocks_if_relaxed_alone']:<3d} sozinho  {c['class']}")
    for k, v in s["integrity"].items():
        print(f"  integridade {k}: {v}")
    return 0 if s["schema_and_integrity_pass"] == s["files"] else 1


if __name__ == "__main__":
    sys.exit(main())
