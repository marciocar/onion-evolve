#!/usr/bin/env python3
"""O vocabulário de domínio de um corpus de grafos: os termos do perfil x_term (contrato v4.11, release 4.19.0).

Um termo é um nó com x_term: o preferido (pref) e os sinônimos (labels), cada um com fonte, versão do documento,
carimbo, cadência, escopo e estado. O termo aposentado é o nó com status superseded, e o termo novo aponta para ele
por SUPERSEDES. Quatro comandos:

  terms    lista os termos, com os sinônimos e o vencimento de cada um na data (--as-of, hoje por padrão);
  lookup   resolve um texto para o termo: casa o preferido ou um sinônimo, sem distinguir maiúscula, acento nem
           espaço repetido. O sinônimo com escopo de caso só casa com --case igual; o aposentado casa e sai marcado,
           e o termo aposentado sai com o termo que o substitui;
  lint     confere os códigos da prosa (label e narrative) contra o vocabulário: a notation repetida no corpus, o
           código sem termo e o código ambíguo entre esquemas (desde a 4.23, contrato v4.14), com --pattern, --external
           e a catraca --baseline/--update;
  export   exporta para o SKOS-XL com o iso-thes, em Turtle (--to skos), ou para o Apache Ossie (--to ossie): uma
           camada por termo com o ai_context.synonyms e a proveniência de cada sinônimo em custom_extensions, para
           juntar pelo nome à entidade do modelo semântico.

Não julga: o veredito é do kg_validate.py. O x_term fora da forma do perfil é lido no que dá para ler, e o resto fica
de fora; o SHOULD já avisa. Saída humana, ou JSON no formato kg-ssot.vocab/1 (spec/vocab.schema.json).

Uso:
  kg_vocab.py terms  [--root DIR [--exclude GLOB]... [--no-default-excludes] | ARQ...] [--as-of AAAA-MM-DD] [--format human|json]
  kg_vocab.py lookup TEXTO [--case CASO] [--root DIR | ARQ...] [--as-of AAAA-MM-DD] [--format human|json]
  kg_vocab.py export --to skos|ossie [--base IRI] [--root DIR | ARQ...]
  kg_vocab.py lint   [--root DIR | ARQ...] [--pattern REGEX] [--external ESQUEMA=REGEX]... [--baseline ARQ [--update]]
                     [--format human|json]
rc: 0 · 1 lookup sem nenhum termo, ou lint com achado (novo, com --baseline) ou grafo ilegível · 2 entrada quebrada.
"""
import argparse
import datetime
import json
import pathlib
import re
import sys
import unicodedata
import urllib.parse

sys.dont_write_bytecode = True
if __package__:  # no pacote kg_ssot, o vizinho vem pelo pacote, sem mexer no sys.path de quem importa
    from . import kg_i18n, kg_query, kg_validate
else:  # script ou vendor
    sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
    import kg_i18n  # noqa: E402
    import kg_query  # noqa: E402
    import kg_validate  # noqa: E402
_ = kg_i18n._

SCHEMA_VERSION = "kg-ssot.vocab/1"
DEFAULT_BASE = "urn:kg-ssot:graph:"  # o mesmo do kg_prov_export: o conceito e a entidade PROV do nó têm o mesmo IRI
LABEL_KEYS = ("literal", "kind", "lang", "retired", "source", "locator", "version", "verified_at", "reverify_every")
OSSIE_VENDOR = "KG_SSOT"


def _text(v):
    return v if isinstance(v, str) and v.strip() else None


def _date(v):
    d = kg_validate._as_date(v)
    return d.isoformat() if d else None


fold = kg_query.fold  # a mesma forma de comparar do --text do kg_query
SCHEME = re.compile(r"[a-z0-9][a-z0-9-]*")  # a forma do x_term.scheme no SHOULD (v4.14)
LIVE_OUT = ("superseded", "refuted")
# o código opaco na prosa: uma a três maiúsculas e um a três dígitos (A7, O1, V3, S14, CC6b) ou r e dígitos (r1, r16).
# Não cobre REGRA N, SAC-N nem ids de nó, que têm mecanismo próprio; o --pattern troca a regex.
DEFAULT_CODE = r"(?<![\w-])(?:[A-Z]{1,3}[0-9]{1,3}[a-z]?|r[0-9]{1,3})(?![\w-])"
LINT_BASELINE_VERSION = "kg-ssot.vocab-lint-baseline/1"


def _scope(v):
    """O escopo legível do sinônimo. Um scope presente e fora da forma (level desconhecido, texto solto, case sem o nome
    do caso) falha fechado: vira um escopo de caso sem caso, que nunca casa nem vai para o SKOS simples e o Ossie. O
    escopo ilegível nunca vale para o domínio inteiro (achado do Elenxo da 4.19.0)."""
    if v is None:
        return None
    if not isinstance(v, dict) or v.get("level") not in ("domain", "case"):
        return {"level": "case"}
    out = {"level": v["level"]}
    for k in ("case", "jurisdiction"):
        if _text(v.get(k)):
            out[k] = v[k]
    return out


def _label(raw, as_of):
    """Um sinônimo legível, ou None: precisa de literal e de kind no enum."""
    if not isinstance(raw, dict) or not _text(raw.get("literal")) or raw.get("kind") not in ("alt", "hidden"):
        return None
    # retired fora de booleano conta como aposentado: na dúvida, o sinônimo não vale (falha fechada)
    lab = {"literal": raw["literal"], "kind": raw["kind"],
           "status": "current" if raw.get("retired", False) is False and raw.get("status", "current") == "current"
           else "retired"}  # o status de antes da troca para retired (a forma do iso-thes) também fecha
    for k in ("lang", "source", "locator", "version", "reverify_every"):
        if _text(raw.get(k)):
            lab[k] = raw[k]
    if _date(raw.get("verified_at")):
        lab["verified_at"] = _date(raw.get("verified_at"))
    scope = _scope(raw.get("scope")) if "scope" in raw else None
    if scope:
        lab["scope"] = scope
    lab["due_on"] = None
    duration = kg_validate.parse_duration(raw.get("reverify_every"))
    if duration and "verified_at" in lab and lab["status"] == "current":
        try:
            lab["due_on"] = kg_validate.add_duration(datetime.date.fromisoformat(lab["verified_at"]), duration).isoformat()
        except (OverflowError, ValueError):
            pass
    lab["due"] = lab["due_on"] is not None and lab["due_on"] <= as_of.isoformat()
    return lab


def terms(corpus, as_of):
    """Os termos do corpus, na ordem do corpus: um por nó com x_term legível (com pref)."""
    out = []
    for key in corpus.order:
        node = corpus.nodes[key]
        term = node.get("x_term")
        if not isinstance(term, dict) or not _text(term.get("pref")):
            continue
        file, nid = key
        declared = isinstance(term.get("scheme"), str) and term["scheme"] != ""  # a mesma regra do leitor
        t = {"file": file, "id": nid, "status": node.get("status") if isinstance(node.get("status"), str) else None,
             "pref": term["pref"],
             # o esquema efetivo (v4.14): o declarado ou, sem ele, o próprio grafo (o meta.id); os dois são o mesmo
             # espaço de nomes (o esquema declarado gb e o grafo de meta.id gb são um esquema só)
             "scheme": term["scheme"] if declared else graph_name(corpus.meta_ids, file), "scheme_declared": declared}
        for k in ("lang", "definition", "notation"):
            if _text(term.get(k)):
                t[k] = term[k]
        labels = term.get("labels") if isinstance(term.get("labels"), list) else []
        t["labels"] = [lab for lab in (_label(r, as_of) for r in labels) if lab]
        # quem substitui: a aresta SUPERSEDES que chega neste nó (local ou externa, com a ponta resolvida)
        t["superseded_by"] = sorted({f"{src[0]}#{src[1]}" if src[1] is not None else src[0]
                                     for et, src, _ref in corpus.into.get(key, []) if et == "SUPERSEDES"})
        out.append(t)
    return out


def lookup(all_terms, text, case=None):
    """Os termos que o texto resolve: [{term, via, literal, retired, scope}]. via é pref, alt, hidden ou notation. A
    notation casa exata (código é código), sozinha ou qualificada pelo esquema (esquema:notation, desde a 4.23)."""
    want = fold(text)
    hits = []
    for t in all_terms:
        notation = t.get("notation")
        if notation is not None and (text == notation or text == f"{t['scheme']}:{notation}"):
            hits.append({"term": t, "via": "notation", "literal": notation, "retired": False, "scope": None})
            continue
        if fold(t["pref"]) == want:
            hits.append({"term": t, "via": "pref", "literal": t["pref"], "retired": False, "scope": None})
        for lab in t["labels"]:
            if fold(lab["literal"]) != want:
                continue
            scope = lab.get("scope")
            if scope and scope["level"] == "case" and (case is None or scope.get("case") != case):
                continue  # o sinônimo de outro caso, de caso nenhum pedido ou de escopo ilegível não vale aqui
            hits.append({"term": t, "via": lab["kind"], "literal": lab["literal"],
                         "retired": lab["status"] == "retired", "scope": scope})
    return hits


# --- lint: o código na prosa e a notation repetida no corpus (desde a 4.23) ----------------------------------------

QUALIFIER = re.compile(r"(?<![\w:/.-])([a-z0-9][a-z0-9-]*):$")  # o esquema colado antes do código, com a borda


def _notations(corpus):
    """Os termos com notation pela regra do leitor (term_located): nó vivo com x_term mapa e notation em texto não
    vazio; o esquema é o x_term.scheme em texto não vazio ou, sem ele, o grafo. [(esquema, notation, chave)]."""
    out = []
    for key in corpus.order:
        node = corpus.nodes[key]
        term = node.get("x_term")
        if not isinstance(term, dict) or node.get("status") in LIVE_OUT:
            continue
        notation, scheme = term.get("notation"), term.get("scheme")
        if not isinstance(notation, str) or not notation:
            continue
        out.append((scheme if isinstance(scheme, str) and scheme else graph_name(corpus.meta_ids, key[0]), notation, key))
    return out


def lint(corpus, all_terms, pattern=DEFAULT_CODE, externals=()):
    """O vocabulário contra a prosa do corpus. Devolve {codes, resolved, external, findings}. Achados:

    - vocab.notation-duplicate: a mesma notation em dois termos vivos do mesmo esquema, no corpus inteiro, pela regra
      do leitor (que só vê o grafo: integrity.term-notation-duplicate); o achado cai em cada termo depois do primeiro;
    - vocab.code-unresolved: um código do label ou do narrative, pela regex, que não é a notation de nenhum termo vivo
      nem casa um esquema externo; o código qualificado esquema:código procura só naquele esquema;
    - vocab.code-ambiguous: o código sem qualificação que é notation em mais de um esquema do próprio grafo, ou, sem
      nenhum do próprio grafo, em mais de um esquema do corpus: quem lê não sabe qual (escreva esquema:código).
    A ordem da resolução: o termo do próprio grafo, depois o esquema externo (externals: [(esquema, regex)], o código que
    casa a regex inteira é de um sistema de fora, como SOC2, CVE e ISO, e resolve sem termo), depois o corpus. O
    qualificador é um slug colado antes do código, com borda (my_sa:T7 e urn:kg:E5 não são qualificados). Um achado por
    nó, campo e código."""
    code_re = re.compile(pattern)
    ext = [(name, re.compile(rx)) for name, rx in externals]
    by_code = {}
    for scheme, notation, key in _notations(corpus):
        by_code.setdefault(notation, {}).setdefault(scheme, []).append(key)
    findings = []
    for code, schemes in sorted(by_code.items()):
        for scheme, keys in sorted(schemes.items()):
            for key in keys[1:]:
                findings.append({"code": "vocab.notation-duplicate", "file": key[0], "id": key[1], "field": "x_term",
                                 "token": f"{scheme}:{code}", "detail": f"{keys[0][0]}#{keys[0][1]}"})
    local = {}
    for scheme, _notation, key in _notations(corpus):
        local.setdefault(key[0], set()).add(scheme)
    n_codes = n_resolved = n_external = 0
    for key in corpus.order:
        node = corpus.nodes[key]
        for field in ("label", "narrative"):
            text = node.get(field)
            if not isinstance(text, str):
                continue
            seen = set()
            for m in code_re.finditer(text):
                token = m.group(0)
                if not token:
                    continue
                qual = QUALIFIER.search(text[:m.start()])
                scheme = qual.group(1) if qual else None
                full = f"{scheme}:{token}" if scheme else token
                if full in seen:
                    continue
                seen.add(full)
                n_codes += 1
                where = set(by_code.get(token, {}))
                if scheme is not None:
                    if scheme in where:
                        n_resolved += 1
                    elif any(name == scheme and rx.fullmatch(token) for name, rx in ext):
                        n_external += 1
                    else:
                        findings.append({"code": "vocab.code-unresolved", "file": key[0], "id": key[1], "field": field,
                                         "token": full, "detail": ""})
                    continue
                own = node.get("x_term")
                if isinstance(own, dict) and own.get("notation") == token:  # o termo cita o próprio código
                    n_resolved += 1
                    continue
                mine = where & local.get(key[0], set())
                if len(mine) == 1:
                    n_resolved += 1
                elif len(mine) > 1:
                    findings.append({"code": "vocab.code-ambiguous", "file": key[0], "id": key[1], "field": field,
                                     "token": token, "detail": ", ".join(sorted(mine))})
                elif any(rx.fullmatch(token) for _name, rx in ext):
                    n_external += 1
                elif len(where) == 1:
                    n_resolved += 1
                elif where:
                    findings.append({"code": "vocab.code-ambiguous", "file": key[0], "id": key[1], "field": field,
                                     "token": token, "detail": ", ".join(sorted(where))})
                else:
                    findings.append({"code": "vocab.code-unresolved", "file": key[0], "id": key[1], "field": field,
                                     "token": token, "detail": ""})
    return {"codes": n_codes, "resolved": n_resolved, "external": n_external, "findings": findings}


def lint_counts(findings):
    """A base da catraca: quantas vezes cada (achado, arquivo, código) aparece; o nó e o campo ficam de fora, para a
    base não quebrar quando um nó muda de id ou o texto passa do label ao narrative."""
    out = {}
    for f in findings:
        k = "\t".join((f["code"], f["file"], f["token"]))
        out[k] = out.get(k, 0) + 1
    return dict(sorted(out.items()))


CODE_FAMILY = ("vocab.code-unresolved", "vocab.code-ambiguous")  # o mesmo código sem nome único, em dois estados


def lint_new(findings, baseline):
    """(novos, reclassificados) contra a base. Novo é o achado de uma chave que a base não tem, ou acima da contagem
    dela (os excedentes, na ordem do corpus). Reclassificado é a ocorrência que a base já tinha no outro estado da
    família do código (sem termo ↔ ambíguo, no mesmo arquivo e com o mesmo código): criar o primeiro termo de um código
    que colide muda o estado do legado, e quem nomeia não paga por ele (achado da bancada do core na 4.23)."""
    left = dict(baseline)
    new, reclassified = [], []
    for f in findings:
        k = "\t".join((f["code"], f["file"], f["token"]))
        if left.get(k, 0) > 0:
            left[k] -= 1
            continue
        if f["code"] in CODE_FAMILY:
            other = CODE_FAMILY[1 - CODE_FAMILY.index(f["code"])]
            ko = "\t".join((other, f["file"], f["token"]))
            if left.get(ko, 0) > 0:
                left[ko] -= 1
                reclassified.append(f)
                continue
        new.append(f)
    return new, reclassified


# --- SKOS-XL + iso-thes, em Turtle ---------------------------------------------------------------------------------

PREFIXES = """@prefix skos: <http://www.w3.org/2004/02/skos/core#> .
@prefix skosxl: <http://www.w3.org/2008/05/skos-xl#> .
@prefix isothes: <http://purl.org/iso25964/skos-thes#> .
@prefix dct: <http://purl.org/dc/terms/> .
@prefix dc: <http://purl.org/dc/elements/1.1/> .
@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .
@prefix kg: <urn:kg-ssot:vocab#> .
"""
LANG_TAG = re.compile(r"[A-Za-z]{2,3}(?:-[A-Za-z0-9]{1,8})*")


def _lit(text, lang=None):
    s = text.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n").replace("\r", "\\r").replace("\t", "\\t")
    return f'"{s}"' + (f"@{lang}" if lang and LANG_TAG.fullmatch(lang) else "")


def graph_name(meta_ids, file):
    """O nome do grafo no IRI e no Ossie: o meta.id; sem ele, o caminho relativo dado, e o nome do arquivo quando o
    caminho é absoluto ou sobe com .. (nunca o caminho da máquina; achado do Elenxo da 4.19.0)."""
    if meta_ids.get(file):
        return meta_ids[file]
    path = pathlib.PurePosixPath(file.replace("\\", "/"))
    if path.is_absolute() or ".." in path.parts or ":" in file:
        return path.name
    return str(path)


def _lang_key(lang):
    """A língua como o RDF a compara: a etiqueta em minúsculas, ou None quando o _lit a descarta por inválida."""
    return lang.lower() if lang and LANG_TAG.fullmatch(lang) else None


def iri(base, graph, nid, suffix=""):
    """<base><meta.id>#<id>, o IRI do kg_prov_export para o mesmo nó; graph é o meta.id (ou, na ponta externa para um
    grafo fora do corpus, o caminho relativo dela). Nunca o caminho do arquivo dado na linha de comando, que pode ser
    o caminho absoluto da máquina."""
    return "<" + base + urllib.parse.quote(graph) + "#" + urllib.parse.quote(nid + suffix, safe="_-") + ">"


def scheme_iri(base, name):
    return "<" + base + "scheme/" + urllib.parse.quote(name, safe="") + ">"


def skos(all_terms, base=DEFAULT_BASE, meta_ids=None):
    """O vocabulário em Turtle. O conceito leva o skos:prefLabel e, para o leitor de SKOS simples, o skos:altLabel e
    o skos:hiddenLabel dos sinônimos atuais de domínio; cada rótulo vira um skosxl:Label com a forma literal e a
    proveniência (dc:source, kg:locator, kg:sourceVersion, kg:verifiedAt, kg:reverifyEvery). O sinônimo de caso é
    ligado por kg:caseLabel (kg:scope e kg:case), nunca por skosxl:altLabel, que implicaria um skos:altLabel do
    conceito inteiro; o aposentado, por kg:retiredLabel (isothes:status "retired" e uma skos:historyNote). O sinônimo
    que repete um literal já dito no conceito vai por kg:repeatedLabel (S13 do SKOS). O termo aposentado ganha dct:isReplacedBy.
    Desde a 4.23, cada conceito diz o seu esquema (skos:inScheme), <base>scheme/<nome>, com o nome escapado inteiro (a
    barra também): o declarado e o do grafo (o meta.id) são o mesmo espaço de nomes; cada esquema sai uma vez como
    skos:ConceptScheme."""
    meta_ids = meta_ids or {}
    graph_of = lambda file: graph_name(meta_ids, file)  # noqa: E731
    out = [PREFIXES]
    schemes = {}
    for t in all_terms:
        if "scheme" in t:
            schemes.setdefault(scheme_iri(base, t["scheme"]), t["scheme"])
    for s_iri, name in schemes.items():
        out.append(f"{s_iri} a skos:ConceptScheme ;\n    dct:title {_lit(name)} .\n")
    for t in all_terms:
        g = graph_of(t["file"])
        c = iri(base, g, t["id"])
        lang = t.get("lang")
        lines = [f"{c} a skos:Concept", f"skos:prefLabel {_lit(t['pref'], lang)}",
                 f"skosxl:prefLabel {iri(base, g, t['id'], '-pref')}"]
        if "definition" in t:
            lines.append(f"skos:definition {_lit(t['definition'], lang)}")
        if "notation" in t:
            lines.append(f"skos:notation {_lit(t['notation'])}")
        if "scheme" in t:
            lines.append("skos:inScheme " + scheme_iri(base, t["scheme"]))
        if t["status"] == "superseded":
            lines.append("isothes:status " + _lit("superseded"))
        for ref in t["superseded_by"]:
            file, _sep, nid = ref.rpartition("#")
            lines.append(f"dct:isReplacedBy {iri(base, graph_of(file), nid)}")
        labels = []
        plain_seen = {(t["pref"], _lang_key(lang))}  # S13 do SKOS: pref, alt e hidden disjuntos no mesmo conceito
        for i, lab in enumerate(t["labels"], 1):
            li = iri(base, g, t["id"], f"-label-{i}")
            llang = lab.get("lang") or lang
            scope = lab.get("scope") or {}
            in_case = scope.get("level") == "case"
            repeated = (lab["literal"], _lang_key(llang)) in plain_seen
            if lab["status"] == "current" and not in_case and not repeated:
                plain_seen.add((lab["literal"], _lang_key(llang)))
                lines.append(f"skos:{'altLabel' if lab['kind'] == 'alt' else 'hiddenLabel'} {_lit(lab['literal'], llang)}")
            if lab["status"] == "current" and not in_case and repeated:
                # o literal já dito no conceito: ligado por skosxl, implicaria o mesmo rótulo duas vezes (S13 com S56)
                lines.append(f"kg:repeatedLabel {li}")
            elif lab["status"] == "retired":
                lines.append("skos:historyNote " + _lit(f"retired label: {lab['literal']}"))
                lines.append(f"kg:retiredLabel {li}")
            elif in_case:
                # skosxl:altLabel seguido de skosxl:literalForm implica skos:altLabel do conceito inteiro (S56 do
                # SKOS-XL): o rótulo de caso fica fora dele, ligado por kg:caseLabel
                lines.append(f"kg:caseLabel {li}")
            else:
                lines.append(f"skosxl:{'altLabel' if lab['kind'] == 'alt' else 'hiddenLabel'} {li}")
            props = [f"{li} a skosxl:Label" + (", isothes:SimpleNonPreferredTerm" if lab["kind"] == "alt" else ""),
                     f"skosxl:literalForm {_lit(lab['literal'], llang)}"]
            if "source" in lab:
                props.append(f"dc:source {_lit(lab['source'])}")
            if "locator" in lab:
                props.append(f"kg:locator {_lit(lab['locator'])}")
            if "version" in lab:
                props.append(f"kg:sourceVersion {_lit(lab['version'])}")
            if "verified_at" in lab:
                props.append(f'kg:verifiedAt "{lab["verified_at"]}"^^xsd:date')
            if "reverify_every" in lab:
                props.append(f"kg:reverifyEvery {_lit(lab['reverify_every'])}^^xsd:duration")
            props.append("isothes:status " + _lit(lab["status"]))
            if scope:
                props.append(f"kg:scope {_lit(scope['level'])}")
                if "case" in scope:
                    props.append(f"kg:case {_lit(scope['case'])}")
                if "jurisdiction" in scope:
                    props.append(f"dct:coverage {_lit(scope['jurisdiction'])}")
            labels.append(" ;\n    ".join(props) + " .")
        pref = (f"{iri(base, g, t['id'], '-pref')} a skosxl:Label, isothes:PreferredTerm ;\n"
                f"    skosxl:literalForm {_lit(t['pref'], lang)} .")
        out.append(" ;\n    ".join(lines) + " .\n" + pref + ("\n" + "\n".join(labels) if labels else "") + "\n")
    return "\n".join(out)


def ossie(all_terms, meta_ids=None):
    """A camada do Apache Ossie: um item por termo vivo, com o nome (o preferido), o ai_context.synonyms (os sinônimos
    atuais e de domínio, alt e hidden) e um custom_extensions do KG_SSOT com a proveniência de cada sinônimo (o Ossie
    não tem onde guardá-la). Quem usa junta o item à entidade do modelo semântico (dataset, field ou metric) pelo nome.
    O termo é citado como <meta.id>#<id>; sem meta.id, pelo caminho relativo dado ou pelo nome do arquivo, nunca pelo
    caminho absoluto (graph_name)."""
    meta_ids = meta_ids or {}
    items = []
    for t in all_terms:
        if t["status"] == "superseded":
            continue
        live, seen = [], {t["pref"]}
        for lab in t["labels"]:  # os atuais de domínio, sem repetir o preferido nem outro sinônimo
            if lab["status"] == "current" and (lab.get("scope") or {}).get("level") != "case" and lab["literal"] not in seen:
                seen.add(lab["literal"])
                live.append(lab)
        provenance = [{k: lab[k] for k in ("literal", "kind", "source", "locator", "version", "verified_at",
                                           "reverify_every", "due_on") if lab.get(k) is not None} for lab in live]
        item = {"name": t["pref"], "ai_context": {"synonyms": [lab["literal"] for lab in live]},
                "custom_extensions": [{"vendor_name": OSSIE_VENDOR, "data": json.dumps(
                    {"kg_ssot_term": f"{graph_name(meta_ids, t['file'])}#{t['id']}", "labels": provenance}, ensure_ascii=False,
                    sort_keys=True)}]}
        if "definition" in t:
            item["description"] = t["definition"]
        items.append(item)
    return {"kg_ssot_overlay": "ossie/0.2", "items": items}


# --- saída ---------------------------------------------------------------------------------------------------------

def _label_line(lab, as_of):
    bits = [lab["kind"], f'"{lab["literal"]}"']
    if lab["status"] == "retired":
        bits.append(_("retired"))
    scope = lab.get("scope")
    if scope:
        bits.append(_("case {case}").format(case=scope.get("case", "?")) if scope["level"] == "case" else _("domain"))
    if "source" in lab:
        bits.append(_("source {source}").format(source=lab["source"]) + (f" ({lab['version']})" if "version" in lab else ""))
    if "verified_at" in lab:
        bits.append(_("verified on {date}").format(date=lab["verified_at"]))
    if lab["due_on"]:
        bits.append((_("DUE on {date}") if lab["due"] else _("due on {date}")).format(date=lab["due_on"]))
    return "    " + " · ".join(bits)


def human_terms(all_terms, as_of):
    lines = []
    for t in all_terms:
        head = f"{t['file']}#{t['id']}  {t['pref']}"
        if t["status"] == "superseded":
            head += "  " + _("(superseded by {ids})").format(ids=", ".join(t["superseded_by"]) or "?")
        lines.append(head)
        lines.extend(_label_line(lab, as_of) for lab in t["labels"])
    due = sum(lab["due"] for t in all_terms for lab in t["labels"])
    lines.append(_("· {terms} terms, {labels} labels, {due} due on {as_of}").format(
        terms=len(all_terms), labels=sum(len(t["labels"]) for t in all_terms), due=due, as_of=as_of.isoformat()))
    return "\n".join(lines)


def human_lookup(text, hits):
    if not hits:
        return _("NOT FOUND  {text}").format(text=text)
    lines = []
    for h in hits:
        t = h["term"]
        via = _("preferred") if h["via"] == "pref" else h["via"]
        line = f"{t['pref']}  ({t['file']}#{t['id']}) ← {via} \"{h['literal']}\""
        if h["retired"]:
            line += "  " + _("RETIRED label")
        if t["status"] == "superseded":
            line += "  " + _("SUPERSEDED term; use {ids}").format(ids=", ".join(t["superseded_by"]) or "?")
        lines.append(line)
    return "\n".join(lines)


def run_lint(corpus, all_terms, args, externals, as_of, broken):
    """O lint com a catraca opcional: sem --baseline, todo achado conta; com ela, só o novo; --update grava a base."""
    res = lint(corpus, all_terms, args.pattern, externals)
    counts = lint_counts(res["findings"])
    new = reclassified = None
    if args.baseline and not args.update:
        try:
            raw = json.loads(pathlib.Path(args.baseline).read_text(encoding="utf-8"))
        except FileNotFoundError:
            raw = {"schema_version": LINT_BASELINE_VERSION, "counts": {}}  # sem base, tudo é novo (falha fechada)
        except (OSError, ValueError, UnicodeDecodeError) as exc:
            return broken(_("--baseline {file}: {error}").format(file=args.baseline, error=exc))
        base = raw.get("counts") if isinstance(raw, dict) and raw.get("schema_version") == LINT_BASELINE_VERSION else None
        if not isinstance(base, dict) or not all(isinstance(v, int) and not isinstance(v, bool) for v in base.values()):
            return broken(_("--baseline {file}: not a {version} file").format(file=args.baseline,
                                                                               version=LINT_BASELINE_VERSION))
        if "pattern" in raw and raw["pattern"] != args.pattern:  # outra regex mede outra coisa: a base não serve
            return broken(_("--baseline {file} was written with another --pattern: run --update with this one")
                          .format(file=args.baseline))
        new, reclassified = lint_new(res["findings"], base)
    if args.update:
        try:
            pathlib.Path(args.baseline).write_text(json.dumps({"schema_version": LINT_BASELINE_VERSION,
                                                               "pattern": args.pattern, "counts": counts},
                                                              ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
        except OSError as exc:
            return broken(exc)
    failing = res["findings"] if new is None else new
    doc = {"schema_version": SCHEMA_VERSION, "as_of": as_of.isoformat(),
           "lint": {"pattern": args.pattern, "externals": [{"scheme": n, "pattern": rx} for n, rx in externals],
                    "baseline": args.baseline, "updated": bool(args.update), **res, "new": new,
                    "reclassified": reclassified},
           "unreadable": corpus.unreadable}
    if args.format == "json":
        out = json.dumps(doc, ensure_ascii=False, indent=1)
    else:
        lines = [f"{f['code']}  {f['file']}#{f['id']}  {f['field']}  {f['token']}" + (f"  ({f['detail']})" if f["detail"] else "")
                 for f in failing]
        lines += [_("UNREADABLE  {file}  {code}").format(file=u["file"], code=u["code"]) for u in corpus.unreadable]
        lines.append(_("· {codes} code(s) in prose: {resolved} resolved, {external} external; {findings} finding(s)")
                     .format(codes=res["codes"], resolved=res["resolved"], external=res["external"],
                             findings=len(res["findings"]))
                     + (_("; {new} new against the baseline").format(new=len(new)) if new is not None else "")
                     + (_(", {n} reclassified (no name yet ↔ ambiguous)").format(n=len(reclassified))
                        if reclassified else "")
                     + (_("; baseline written") if args.update else ""))
        out = "\n".join(lines)
    print(out.encode("utf-8", "backslashreplace").decode("utf-8"))
    if corpus.unreadable:
        return 1  # um grafo ilegível pode guardar o código que ninguém conferiu
    return 0 if args.update or not failing else 1


def main(argv=None):
    ap = argparse.ArgumentParser(description=_("The domain vocabulary of a corpus: the terms of the x_term profile, "
                                               "and the codes in prose checked against them (contract v4.14)."))
    ap.add_argument("command", choices=("terms", "lookup", "export", "lint"))
    ap.add_argument("files", nargs="*", help=_("for lookup, the text first; then .kg.yaml or .kg.json files (or --root)"))
    ap.add_argument("--root", help=_("the corpus root: the graphs git tracks under it"))
    ap.add_argument("--exclude", action="append", default=[], metavar="GLOB",
                    help=_("with --root, paths to leave out (repeatable), added to the defaults"))
    ap.add_argument("--no-default-excludes", action="store_true", help=_("with --root, also read the vendor and the fixtures"))
    ap.add_argument("--as-of", metavar=_("YYYY-MM-DD"), help=_("the date for the due labels (today by default)"))
    ap.add_argument("--case", help=_("lookup: the case whose case-scoped labels count"))
    ap.add_argument("--to", choices=("skos", "ossie"), help=_("export: the target format"))
    ap.add_argument("--base", default=DEFAULT_BASE, help=_("export --to skos: the base of the concept IRIs"))
    ap.add_argument("--pattern", default=DEFAULT_CODE, help=_("lint: the regex of a code in prose"))
    ap.add_argument("--external", action="append", default=[], metavar=_("SCHEME=REGEX"),
                    help=_("lint: codes of an outside system (SOC2, CVE, ISO) that resolve without a term (repeatable)"))
    ap.add_argument("--baseline", metavar=_("FILE"), help=_("lint: fail only on findings that are new or above this base"))
    ap.add_argument("--update", action="store_true", help=_("lint: write the current findings to --baseline"))
    ap.add_argument("--format", default="human", choices=("human", "json"))
    args = ap.parse_intermixed_args(argv)
    kg_validate._utf8_stdio()

    def broken(msg):
        print(_("BROKEN INPUT  {error}").format(error=msg), file=sys.stderr)
        return 2
    files = list(args.files)
    text = None
    if args.command == "lookup":
        if not files:
            return broken(_("lookup needs the text to resolve"))
        text = files.pop(0)
    if bool(args.root) == bool(files):
        return broken(_("give either --root or the files"))
    if args.command == "export" and not args.to:
        return broken(_("export needs --to skos or --to ossie"))
    if args.command != "lint" and (args.baseline or args.update or args.external or args.pattern != DEFAULT_CODE):
        return broken(_("--pattern, --external, --baseline, and --update belong to lint"))
    if args.update and not args.baseline:
        return broken(_("--update needs --baseline"))
    externals = []
    for spec in args.external:
        name, eq, rx = spec.partition("=")
        if not eq or not SCHEME.fullmatch(name) or not rx:
            return broken(_("--external {spec}: write SCHEME=REGEX, with the scheme as a slug").format(spec=repr(spec)))
        externals.append((name, rx))
    try:
        for rx in [args.pattern] + [rx for _n, rx in externals]:
            if re.compile(rx).fullmatch(""):
                return broken(_("the regex {regex} matches the empty text").format(regex=repr(rx)))
    except re.error as exc:
        return broken(_("invalid regex: {error}").format(error=exc))
    as_of = datetime.date.today()
    if args.as_of is not None:
        as_of = kg_validate.iso_date(args.as_of)
        if as_of is None:
            return broken(_("--as-of {value}: the date must be YYYY-MM-DD").format(value=repr(args.as_of)))
    try:
        corpus = kg_query.load(args.root, files, args.exclude, not args.no_default_excludes)
    except (OSError, ValueError, UnicodeDecodeError) as exc:
        return broken(exc)
    all_terms = terms(corpus, as_of)
    rc = 0
    if args.command == "lint":
        return run_lint(corpus, all_terms, args, externals, as_of, broken)
    if args.command == "export":
        out = skos(all_terms, args.base, corpus.meta_ids) if args.to == "skos" else json.dumps(ossie(all_terms, corpus.meta_ids), ensure_ascii=False, indent=1)
    elif args.command == "terms":
        doc = {"schema_version": SCHEMA_VERSION, "as_of": as_of.isoformat(), "terms": all_terms,
               "unreadable": corpus.unreadable}
        out = json.dumps(doc, ensure_ascii=False, indent=1) if args.format == "json" else human_terms(all_terms, as_of)
    else:
        hits = lookup(all_terms, text, args.case)
        rc = 0 if hits else 1
        doc = {"schema_version": SCHEMA_VERSION, "as_of": as_of.isoformat(), "query": text, "case": args.case,
               "matches": [{"via": h["via"], "literal": h["literal"], "retired": h["retired"], "scope": h["scope"],
                            "term": h["term"]} for h in hits], "unreadable": corpus.unreadable}
        out = json.dumps(doc, ensure_ascii=False, indent=1) if args.format == "json" else human_lookup(text, hits)
    print(out.encode("utf-8", "backslashreplace").decode("utf-8"))
    return rc


if __name__ == "__main__":
    sys.exit(main())
