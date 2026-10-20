#!/usr/bin/env python3
"""Exporta a proveniência de um .kg.yaml para PROV-O em JSON-LD.

  kg_prov_export.py <grafo.kg.yaml> [--base IRI]

Cada nó vira uma prov:Entity, com o rótulo, o tipo e o status. Um nó com `provenance` ganha prov:wasDerivedFrom
para a fonte e uma prov:Derivation qualificada: a atividade carrega o `method`, e o `locator` e a `locality` vão
como propriedades kg:. A fonte é a própria IRI só quando o texto inteiro é uma URL http(s) sem espaço; senão (um
caminho de repo, um comando, duas URLs juntas), vira um nó em branco rotulado com o texto, um por texto distinto no
documento, para que nós com a mesma fonte apontem para a mesma entidade. O carimbo de verificação vai como
kg:verifiedAt (xsd:date quando é uma data), kg:verifiedAgainst e kg:verifiedScope (o alcance, desde o v4.5), e não como prov:generatedAtTime: em PROV, o tempo
de geração marca a existência da entidade, não a conferência dela.

As IRIs dos nós são <base><meta.id>#<id>, com base urn:kg-ssot:graph: por padrão; o vocabulário kg: mora em
urn:kg-ssot:vocab#, fora do espaço dos grafos, para um meta.id não colidir com ele.

As arestas (SUPPORTS, REFUTES, SUPERSEDES…) NÃO são exportadas: derivação em PROV é relação de produção, e não de
suporte evidencial. Exportá-las como wasDerivedFrom diria algo que o grafo não diz.

O exportador lê o grafo com o parse do leitor de referência e não o valida: rode kg_validate.py antes.
Saída: JSON-LD em stdout. rc: 0 ok · 2 entrada quebrada (arquivo ilegível, que não é um documento YAML único, ou
com meta ou nodes fora da forma).
"""
import argparse
import json
import pathlib
import re
import sys
import urllib.parse

sys.dont_write_bytecode = True
HERE = pathlib.Path(__file__).resolve().parent
if __package__:  # no pacote kg_ssot, o vizinho vem pelo pacote, sem mexer no sys.path de quem importa
    from . import kg_validate
else:  # script ou vendor
    sys.path.insert(0, str(HERE))
    import kg_validate  # noqa: E402

CONTEXT = {
    "prov": "http://www.w3.org/ns/prov#",
    "rdfs": "http://www.w3.org/2000/01/rdf-schema#",
    "xsd": "http://www.w3.org/2001/XMLSchema#",
    "kg": "urn:kg-ssot:vocab#",
}
IRI = re.compile(r"https?://[^\s<>\"{}|\\^`]+")
DATE = re.compile(r"\d{4}-\d{2}-\d{2}")


class Broken(Exception):
    """Entrada quebrada: rc 2."""


def export(doc, base):
    meta = doc.get("meta", {})
    nodes = doc.get("nodes", [])
    if not isinstance(meta, dict):
        raise Broken("meta não é um mapeamento")
    if not isinstance(nodes, list):
        raise Broken("nodes não é uma lista")
    prefix = f"{base}{urllib.parse.quote(str(meta.get('id') or 'grafo'))}#"
    sources, out = {}, []

    def source_ref(text):
        if IRI.fullmatch(text):
            return {"@id": text}
        if text not in sources:
            sources[text] = f"_:source{len(sources)}"
            return {"@id": sources[text], "rdfs:label": text}
        return {"@id": sources[text]}

    for node in nodes:
        if not isinstance(node, dict) or "id" not in node:
            continue
        entity = {"@id": prefix + str(node["id"]), "@type": "prov:Entity", "kg:nodeType": node.get("node_type"),
                  "kg:status": node.get("status")}
        if node.get("label") is not None:
            entity["rdfs:label"] = str(node["label"])
        if node.get("verified_at") is not None:
            when = str(node["verified_at"])
            entity["kg:verifiedAt"] = {"@value": when, "@type": "xsd:date"} if DATE.fullmatch(when) else when
        for key, prop in (("verified_against", "kg:verifiedAgainst"), ("verified_scope", "kg:verifiedScope"), ("plane", "kg:plane")):
            if node.get(key) is not None:
                entity[prop] = str(node[key])
        prov = node.get("provenance")
        if isinstance(prov, dict) and prov.get("source"):
            src = source_ref(str(prov["source"]).strip())
            derivation = {"@type": "prov:Derivation", "prov:entity": src}
            if prov.get("method"):
                derivation["prov:hadActivity"] = {"@type": "prov:Activity", "rdfs:label": str(prov["method"])}
            for key in ("locator", "locality"):
                if prov.get(key):
                    derivation[f"kg:{key}"] = str(prov[key])
            entity["prov:wasDerivedFrom"] = {"@id": src["@id"]}
            entity["prov:qualifiedDerivation"] = derivation
        out.append(entity)
    return {"@context": CONTEXT, "@graph": out}


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
    ap.add_argument("graph")
    ap.add_argument("--base", default="urn:kg-ssot:graph:",
                    help="prefixo das IRIs dos nós (default: urn:kg-ssot:graph:)")
    args = ap.parse_args(argv)
    _utf8_stdio()
    try:
        text = pathlib.Path(args.graph).read_text(encoding="utf-8")
    except (OSError, UnicodeDecodeError) as exc:
        print(f"✗ {args.graph}: {exc}", file=sys.stderr)
        return 2
    _, doc, error = kg_validate.parse_v1(text)
    if error:
        print(f"✗ {args.graph}: {error}", file=sys.stderr)
        return 2
    try:
        result = export(doc, args.base)
    except Broken as exc:
        print(f"✗ {args.graph}: {exc}", file=sys.stderr)
        return 2
    print(json.dumps(result, ensure_ascii=False, indent=1))
    return 0


if __name__ == "__main__":
    sys.exit(main())
