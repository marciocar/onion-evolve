#!/usr/bin/env python3
"""O migrador oficial do KG-SSOT: propõe a provenance que o contrato pede, pelo perfil declarado do adotante.

  kg_migrate.py plan  --profile PERFIL.yaml [--root DIR] [--exclude GLOB] [--no-default-excludes] [--json] [--out PLANILHA.tsv] [grafo.kg.yaml ...]
  kg_migrate.py apply --profile PERFIL.yaml [--root DIR] [--exclude GLOB] [--no-default-excludes] [grafo.kg.yaml ...]

O perfil (spec/kg-migrate-profile.schema.json) declara regras em ordem: a primeira cujo when casa decide a ação do nó
(propor provenance, rebaixar para unverifiable, ou só listar para quem revisa), e o bloco scopes dá verified_scope por
lista de ids. O universo é fixo: nó com status confirmed ou plane PROD, sem provenance, fora o unverifiable. Sem
grafos na linha de comando, a ferramenta lê os .kg.yaml rastreados de --root (default: o diretório atual), fora os
padrões do kg_gate.py (*/fixtures/*, docs/materials/*), o vendor/*, toda pasta com o carimbo .kg-ssot-version e os
globs de --exclude, com a semântica do gate
(* atravessa /); o grafo dessa lista que não parseia vira linha para quem revisa. O nó cujo verified_scope já é o do
perfil sai como same, e o apply não o toca.

O plan NÃO escreve nada: imprime a planilha de propostas (uma linha por nó), as contagens por regra e o que ficou
para quem revisa. Toda provenance proposta é conferida contra o MUST e o SHOULD do contrato vigente antes de virar
proposta; a que reprovaria, ou cujo template resolve para vazio, vai para revisão com o motivo.

O apply grava as propostas do plan, um arquivo por vez: insere por texto (os comentários ficam), relê e confere a
invariância nó a nó (o dict de cada nó igual ao de antes, fora as chaves que a ação autoriza) e linha a linha (o diff
só acrescenta linhas, fora a do status rebaixado), e só grava se o arquivo não ganha código MUST novo. O arquivo que
falha em qualquer conferência fica como estava, e o motivo sai no relatório. Rodar o apply de novo não muda nada.
O nó em estilo flow ({...}) não é tocado: vai para revisão.

rc: 0 o plano saiu ou o apply terminou (arquivos recusados aparecem no relatório) · 1 o apply recusou algum arquivo ·
2 entrada quebrada (perfil fora do schema, regra repetida, regex inválida, grafo dado na linha de comando que não
parseia).
"""
import argparse
import collections
import csv
import fnmatch
import io
import json
import os
import pathlib
import posixpath
import re
import subprocess
import sys

TOOLS = pathlib.Path(__file__).resolve().parent
sys.dont_write_bytecode = True  # sem .pyc em vendor/kg-ssot/tools/__pycache__, que o kg_vendor.py check acusa
sys.path.insert(0, str(TOOLS))
import kg_i18n  # noqa: E402
import kg_validate  # noqa: E402

_ = kg_i18n._

ROOT = TOOLS.parent
PROFILE_SCHEMA = ROOT / "spec" / "kg-migrate-profile.schema.json"
MARKERS = ("trace", "trace_path", "trace_line", "verified_against", "supports", "source_kind")
MARKER_RE = re.compile(r"\{([a-z_|]+)\}")
URL_RE = re.compile(r"^https?://\S+$")
SCOPE_SINCE = (4, 12, 0)  # privado e verified_scope existem desde a kg-ssot-v4.12.0
# Caminho que só existe numa máquina: aceito só com locality host, que é o que o contrato prevê para ele. O til seguido
# de barra e a variável da pasta pessoal vão com uma classe ([/], [O]) para a higiene da release não ler o padrão
# como um caminho.
MACHINE_PATH = re.compile(r"(?:^|[\s(\"'])(?:/(?:home|Users|root|tmp|var|opt|etc|srv|mnt|media|private|Volumes)/"
                          r"|[A-Za-z]:\\|~[/]|\\\\[^\\\s]+\\)|\$H[O]ME\b|\bfile:/", re.IGNORECASE)


class Broken(Exception):
    """Entrada quebrada: rc 2."""


def load_profile(path):
    import jsonschema
    import yaml
    try:
        prof = yaml.safe_load(pathlib.Path(path).read_text(encoding="utf-8"))
    except (OSError, UnicodeDecodeError, yaml.YAMLError) as exc:
        raise Broken(_("unreadable profile: {path}: {exc}").format(path=path, exc=exc))
    schema = json.loads(PROFILE_SCHEMA.read_text(encoding="utf-8"))
    errors = sorted(jsonschema.Draft202012Validator(schema, format_checker=jsonschema.FormatChecker()).iter_errors(prof),
                    key=lambda e: list(e.absolute_path))
    if errors:
        e = errors[0]
        where = "/".join(map(str, e.absolute_path)) or _("root")
        raise Broken(_("profile outside the schema at {where}: {message}").format(where=where, message=e.message))
    ids = [r["id"] for r in prof["rules"]] + [s["id"] for s in prof.get("scopes", [])]
    dup = sorted({i for i in ids if ids.count(i) > 1})
    if dup:
        raise Broken(_("repeated rule id in the profile: {ids}").format(ids=', '.join(dup)))
    scoped = [i for s in prof.get("scopes", []) for i in s["id_in"]]
    twice = sorted({i for i in scoped if scoped.count(i) > 1})
    if twice:
        raise Broken(_("node in two scopes: {ids}").format(ids=', '.join(twice)))
    for r in prof["rules"]:
        p = r["then"].get("provenance")
        for t in ([p["source"], p["locator"], p["method"]["detail"]] if p else []):
            for m in MARKER_RE.finditer(t):
                bad = [x for x in m.group(1).split("|") if x not in MARKERS]
                if bad:
                    raise Broken(_("unknown marker in rule {rule}: {marker}").format(
                        rule=r["id"], marker="{" + m.group(1) + "}"))
    version = tuple(int(x) for x in prof["contract"].removeprefix("kg-ssot-v").split("."))
    uses_new = prof.get("scopes") or any(r["then"].get("provenance", {}).get("locality") == "privado" for r in prof["rules"])
    if uses_new and version < SCOPE_SINCE:
        raise Broken(_("the profile uses locality privado or verified_scope, which exist only since kg-ssot-v4.12.0 "
                       "(the profile declares {contract})").format(contract=prof["contract"]))
    def patterns(w):
        for k in ("trace_matches", "verified_against_matches"):
            if k in w:
                yield w[k]
        for sub in ([w["not"]] if "not" in w else []) + w.get("any_of", []):
            yield from patterns(sub)
    whens = [r["when"] for r in prof["rules"]] + ([prof["applies_to"]] if "applies_to" in prof else [])

    def vacuous(w):
        if not set(w) - {"match_case"}:
            return True
        return any(vacuous(sub) for sub in ([w["not"]] if "not" in w else []) + w.get("any_of", []))
    if any(vacuous(w) for w in whens):
        raise Broken(_("a when in the profile has only match_case and would match every node: say what it matches"))
    for pattern in [x for w in whens for x in patterns(w)]:
        if pattern is not None:
            try:
                re.compile(pattern)
            except re.error as exc:
                raise Broken(_("invalid regular expression in the profile: {pattern}: {exc}").format(
                    pattern=repr(pattern), exc=exc))
    return prof


# ------------------------------------------------------------------ o trace

SCHEME_RE = re.compile(r"^[A-Za-z][A-Za-z0-9+.-]*:")


def trace_parts(trace):
    """(caminho, linha) do trace, pela semântica do perfil: o primeiro segmento antes de ' · ', ';' ou espaço, cortado
    no primeiro ':'; só é caminho se tem / ou . e não começa com um esquema (http:, drive:, ...)."""
    if not isinstance(trace, str) or not trace.strip():
        return None, None
    first = re.split(r"\s+·\s+|;|\s+", trace.strip(), maxsplit=1)[0]
    head = first.split(":", 1)[0]
    if SCHEME_RE.match(first) and ("/" not in head and "." not in head):
        return None, None
    path, _sep, line = first.partition(":")
    path = path.split("#", 1)[0]
    if "/" not in path and "." not in path:
        return None, None
    path = path.replace("\\", "/") if re.match(r"^\.\\", path) else path
    if not path.startswith("/"):
        path = posixpath.normpath(path)
        if path in (".", "..") or path.startswith("../"):
            return None, None
    return path, (line or None)


def glob_match(path, patterns):
    """O dialeto do perfil: ** atravessa zero ou mais pastas, * não atravessa /, ? é um caractere."""
    if path is None:
        return False
    for pat in ([patterns] if isinstance(patterns, str) else patterns):
        rx = re.escape(pat).replace(r"\*\*/", "(?:.*/)?").replace(r"\*\*", ".*").replace(r"\*", "[^/]*").replace(r"\?", "[^/]")
        if re.fullmatch(rx, path):
            return True
    return False


class Graph:
    def __init__(self, rel, doc):
        self.rel = rel
        self.nodes = doc.get("nodes") if isinstance(doc.get("nodes"), list) else []
        self.by_id = {n["id"]: n for n in self.nodes if isinstance(n, dict) and isinstance(n.get("id"), str)}
        edges = doc.get("edges") if isinstance(doc.get("edges"), list) else []
        self.supports = collections.defaultdict(list)
        for e in edges:
            if isinstance(e, dict) and e.get("edge_type") == "SUPPORTS" and isinstance(e.get("to"), str):
                src = self.by_id.get(e.get("from"))
                if isinstance(src, dict) and src.get("status") != "unverifiable":  # o estado de ANTES da rodada
                    self.supports[e["to"]].append(e["from"])


def in_universe(n):
    return (isinstance(n, dict) and "provenance" not in n and n.get("status") != "unverifiable"
            and (n.get("status") == "confirmed" or n.get("plane") == "PROD"))


class Matcher:
    def __init__(self, prof, root):
        self.prof = prof
        self.root = pathlib.Path(root)
        self.placeholders = [re.compile(p) for p in prof.get("trace_placeholders", [])]

    def in_root(self, path):
        """O caminho do trace dentro da raiz, ou None: absoluto, ~ ou ../ que sai da raiz nunca consulta o disco do host."""
        if path is None or path.startswith(("/", "~", "\\")) or re.match(r"^[A-Za-z]:", path):
            return None
        try:
            root = self.root.resolve()
            p = (root / path).resolve()
            return p if p == root or root in p.parents else None
        except (OSError, ValueError, RuntimeError):  # laço de symlink, nome longo demais, byte nulo
            return None

    def _on_disk(self, path, test):
        inside = self.in_root(path)
        try:
            return inside is not None and test(inside)
        except (OSError, ValueError):
            return False

    def trace_of(self, n):
        t = n.get("trace")
        if not isinstance(t, str) or not t.strip() or any(p.search(t) for p in self.placeholders):
            return None
        return t.strip()

    def when(self, w, n, g, flags=0):
        """flags vem do when de fora: o match_case vale também dentro de not e any_of."""
        trace = self.trace_of(n)
        path, _line = trace_parts(trace)
        if "match_case" in w:
            flags = 0 if w["match_case"] else re.IGNORECASE
        checks = {
            "match_case": lambda v: True,
            "any_of": lambda v: any(self.when(sub, n, g, flags) for sub in v),
            "trace_is_path": lambda v: (path is not None) == v,
            "id_in": lambda v: n.get("id") in v,
            "node_type_in": lambda v: n.get("node_type") in v,
            "status_in": lambda v: n.get("status") in v,
            "plane": lambda v: n.get("plane") == v,
            "trace_empty": lambda v: (trace is None) == v,
            "trace_matches": lambda v: trace is not None and re.search(v, trace, flags) is not None,
            "trace_is_url": lambda v: (trace is not None and URL_RE.match(trace.split()[0]) is not None) == v,
            "trace_is_self": lambda v: (path is not None and path == g.rel) == v,
            "trace_path_exists": lambda v: self._on_disk(path, pathlib.Path.exists) == v,
            "trace_path_is_dir": lambda v: self._on_disk(path, pathlib.Path.is_dir) == v,
            "trace_path_glob": lambda v: glob_match(path, v),
            "verified_against_matches": lambda v: isinstance(n.get("verified_against"), str)
            and re.search(v, n["verified_against"], flags) is not None,
            "has_supports": lambda v: bool(g.supports.get(n.get("id"))) == v,
            "source_kind_in": lambda v: n.get("source_kind") in v,
            "not": lambda v: not self.when(v, n, g, flags),
        }
        return all(checks[k](v) for k, v in w.items())

    def render(self, template, n, g):
        """O template com os marcadores trocados; None se algum marcador resolve para vazio."""
        trace = self.trace_of(n)
        path, line = trace_parts(trace)
        values = {"trace": trace, "trace_path": path, "trace_line": line, "verified_against": n.get("verified_against"),
                  "supports": ", ".join(g.supports.get(n.get("id"), [])) or None, "source_kind": n.get("source_kind")}
        empty = []

        def sub(m):
            for name in m.group(1).split("|"):
                v = values.get(name)
                if isinstance(v, str) and v.strip():
                    return v.strip()
            empty.append(m.group(0))
            return ""
        out = MARKER_RE.sub(sub, template)
        return None if empty or not out.strip() else out


def plan(prof, graphs, root):
    """[(arquivo, id, regra, ação, proposta ou None, motivo para quem revisa ou None)]."""
    m = Matcher(prof, root)
    must = kg_validate.make_validator(json.loads(kg_validate.CONTRACT_MUST.read_text(encoding="utf-8")))
    should = kg_validate.make_validator(json.loads(kg_validate.CONTRACT_SHOULD.read_text(encoding="utf-8")))
    note = prof.get("note")
    scoped = {i: s for s in prof.get("scopes", []) for i in s["id_in"]}
    rows = []
    for g in graphs:
        for n in g.nodes:
            if not isinstance(n, dict) or not isinstance(n.get("id"), str):
                continue
            if n["id"] in scoped:
                s = scoped[n["id"]]
                if not n.get("verified_at"):
                    rows.append((g.rel, n["id"], s["id"], "review", None, "verified_scope sem verified_at: carimbe antes"))
                elif n.get("verified_scope") not in (None, s["verified_scope"]):
                    rows.append((g.rel, n["id"], s["id"], "review", None,
                                 f"o nó já tem verified_scope {n['verified_scope']!r}: troque à mão se for o caso"))
                elif n.get("verified_scope") == s["verified_scope"]:
                    rows.append((g.rel, n["id"], s["id"], "same", None, None))  # já igual: o apply não toca
                else:
                    rows.append((g.rel, n["id"], s["id"], "scope", {"verified_scope": s["verified_scope"]}, None))
            if not in_universe(n) or ("applies_to" in prof and not m.when(prof["applies_to"], n, g)):
                continue
            rule = next((r for r in prof["rules"] if m.when(r["when"], n, g)), None)
            if rule is None:
                rows.append((g.rel, n["id"], "", "review", None, "nenhuma regra do perfil casou"))
                continue
            then = rule["then"]
            review = then.get("review")
            if "status" in then:
                rows.append((g.rel, n["id"], rule["id"], "unverifiable", {"status": "unverifiable"}, review))
                continue
            if "provenance" not in then:
                rows.append((g.rel, n["id"], rule["id"], "review", None, review))
                continue
            p = then["provenance"]
            src, loc, det = (m.render(p["source"], n, g), m.render(p["locator"], n, g), m.render(p["method"]["detail"], n, g))
            if None in (src, loc, det):
                rows.append((g.rel, n["id"], rule["id"], "review", None, "um marcador do template resolveu para vazio"))
                continue
            prov = {"source": src, "locator": loc, "method": f"{p['method']['class']}: {det}" + (f"; {note}" if note else "")}
            if "locality" in p:
                prov["locality"] = p["locality"]
            problem = contract_problem(dict(n, provenance=prov), must, should)
            if problem:
                rows.append((g.rel, n["id"], rule["id"], "review", None, f"a proposta reprovaria no contrato: {problem}"))
                continue
            lit = coherence_lit(n, prov)
            if lit:
                # o aviso diz a verdade sobre o nó (produção apoiada em relato, por exemplo): a proposta segue, e o nó
                # vai para quem revisa com o aviso nomeado; o apply só aceita os avisos novos que o plan anunciou
                why = f"a proposta acende {', '.join(lit)}: o aviso fica no grafo"
                review = f"{review}; {why}" if review else why
            rows.append((g.rel, n["id"], rule["id"], "provenance", {"provenance": prov, "lit": lit}, review))
    return rows


def contract_problem(node, must, should):
    """O primeiro código MUST, ou SHOULD da provenance, que o nó com a proposta teria; None se passa."""
    doc = {"meta": {"schema_version": "1", "id": "kg-migrate-probe"}, "nodes": [node], "edges": []}
    for v, level in ((must, "MUST"), (should, "SHOULD")):
        for err in v.iter_errors(doc):
            for code in kg_validate.form_codes(err):
                if level == "MUST" or ".provenance" in code:
                    return f"{level} {code}"
    prov = node["provenance"]
    if MACHINE_PATH.search(" ".join(str(prov.get(k, "")) for k in ("source", "locator", "method"))) \
            and prov.get("locality") != "host":
        return "caminho de máquina na proposta sem locality host"
    return None


def coherence_lit(node, prov):
    """Os avisos de coerência do leitor que o nó passa a ter com a proposta e não tinha sem ela (no nó isolado)."""
    def probe(n):
        doc = {"meta": {"schema_version": "1", "id": "kg-migrate-probe"}, "nodes": [n], "edges": []}
        return kg_validate.coherence_warnings(doc)
    return sorted(probe(dict(node, provenance=prov)) - probe(node))


# ------------------------------------------------------------------ o apply

def _yaml_str(value):
    """Um texto em YAML de aspas duplas (o escape do JSON é um subconjunto do YAML 1.2)."""
    out = json.dumps(value, ensure_ascii=False)
    return out.replace("\u0085", "\\u0085").replace("\u2028", "\\u2028").replace("\u2029", "\\u2029")


def _node_spans(text):
    """{id: (mapa do nó, coluna das chaves, linha depois do último valor, lista de (chave, nó-chave, nó-valor))} pelo
    compose do parser puro. A linha de inserção vem do fim do último VALOR, e não do end_mark do mapa, que num mapa em
    bloco cai na linha seguinte (o defeito que um adotante achou na migração dele)."""
    import yaml
    root = yaml.compose(text, Loader=kg_validate.Yaml12CoreLoader)
    out = {}
    if not isinstance(root, yaml.MappingNode):
        return out
    nodes = next((v for k, v in root.value if getattr(k, "value", None) == "nodes"), None)
    if not isinstance(nodes, yaml.SequenceNode):
        return out
    for item in nodes.value:
        if not isinstance(item, yaml.MappingNode) or not item.value:
            continue
        pairs = [(k.value, k, v) for k, v in item.value if isinstance(k, yaml.ScalarNode)]
        nid = next((v.value for name, _, v in pairs if name == "id" and isinstance(v, yaml.ScalarNode)), None)
        if nid is None:
            continue
        last = item.value[-1][1]
        # desce até a última folha: o end_mark de uma coleção em BLOCO cai no começo da linha seguinte, na coluna da
        # indentação, e não marca o fim do conteúdo (o defeito que engoliu um '- id:' na migração de um adotante)
        while isinstance(last, (yaml.MappingNode, yaml.SequenceNode)) and not last.flow_style and last.value:
            last = last.value[-1][1] if isinstance(last, yaml.MappingNode) else last.value[-1]
        end = last.end_mark
        after = end.line if end.column == 0 else end.line + 1
        out[nid] = (item, item.value[0][0].start_mark.column, after, pairs)
    return out


def edit_text(text, edits):
    """O texto com as edições de um arquivo aplicadas: [(id, ação, valor)], ação em provenance, unverifiable ou scope.
    Devolve (texto novo, recusados [(id, motivo)])."""
    lines = text.splitlines(keepends=True)
    if lines and not lines[-1].endswith(("\n", "\r")):
        lines[-1] += "\n"
    spans = _node_spans(text)
    inserts, replaces, refused = collections.defaultdict(list), {}, []
    for nid, action, value in edits:
        span = spans.get(nid)
        if span is None:
            refused.append((nid, _("node not found in the text")))
            continue
        item, col, after, pairs = span
        if item.flow_style:
            refused.append((nid, _("node in flow style ({...}): edit it by hand")))
            continue
        pad = " " * col
        if action == "provenance":
            block = [f"{pad}provenance:\n"] + [f"{pad}  {k}: {_yaml_str(v)}\n" for k, v in value.items()]
            inserts[after].extend(block)
        elif action == "scope":
            inserts[after].append(f"{pad}verified_scope: {value}\n")
        elif action == "unverifiable":
            st = next((v for name, _, v in pairs if name == "status"), None)
            if st is None or st.start_mark.line != st.end_mark.line:
                refused.append((nid, _("status is not on a single line")))
                continue
            ln = st.start_mark.line
            line = lines[ln]
            replaces[ln] = line[:st.start_mark.column] + "unverifiable" + line[st.end_mark.column:]
    out = []
    for i, line in enumerate(lines + [""]):
        out.extend(inserts.get(i, []))
        if i < len(lines):
            out.append(replaces.get(i, line))
    return "".join(out), refused


def invariance_problem(old_text, new_text, applied):
    """Um motivo, se a releitura não for a de antes mais só o que a ação autoriza; None se bate."""
    _txt, old_doc, c1 = kg_validate.parse_v1(old_text)
    _txt, new_doc, c2 = kg_validate.parse_v1(new_text)
    if c2 is not None and c1 is None:
        return _("the edited text does not parse ({code})").format(code=c2)
    if not isinstance(new_doc, dict) or not isinstance(old_doc, dict):
        return None if c1 else _("the edited text is not a map")
    for key in set(old_doc) | set(new_doc):
        if key != "nodes" and old_doc.get(key) != new_doc.get(key):
            return _("top-level field {key} changed").format(key=key)
    old_nodes, new_nodes = old_doc.get("nodes") or [], new_doc.get("nodes") or []
    if len(old_nodes) != len(new_nodes):
        return _("the number of nodes changed")
    for a, b in zip(old_nodes, new_nodes):
        allowed = applied.get(a.get("id") if isinstance(a, dict) else None, {})
        if not isinstance(a, dict) or not isinstance(b, dict):
            if a != b:
                return _("an item of nodes changed")
            continue
        want = dict(a)
        want.update(allowed)
        if b != want:
            return _("node {id} changed beyond what the action allows").format(id=a.get('id'))
    import difflib
    status_lines = {i for i, l in enumerate(old_text.splitlines()) if re.match(r"\s*status:", l)}
    for tag, i1, i2, _j1, _j2 in difflib.SequenceMatcher(a=old_text.splitlines(), b=new_text.splitlines(), autojunk=False).get_opcodes():
        if tag == "delete" or (tag == "replace" and not set(range(i1, i2)) <= status_lines):
            return _("the text diff removed or replaced a line other than the demoted status line")
    return None


def apply(prof, graphs, root, files):
    """Aplica as propostas do plan, arquivo por arquivo. Devolve [(arquivo, gravado?, [motivos])]."""
    rows = plan(prof, graphs, root)
    by_file = collections.defaultdict(list)
    lit = collections.defaultdict(collections.Counter)
    for f, nid, _rule, action, prop, _why in rows:
        if action == "provenance":
            by_file[f].append((nid, "provenance", prop["provenance"]))
            lit[f].update(prop.get("lit", []))
        elif action == "unverifiable":
            by_file[f].append((nid, "unverifiable", None))
        elif action == "scope":
            by_file[f].append((nid, "scope", prop["verified_scope"]))
    must = kg_validate.make_validator(json.loads(kg_validate.CONTRACT_MUST.read_text(encoding="utf-8")))
    should = kg_validate.make_validator(json.loads(kg_validate.CONTRACT_SHOULD.read_text(encoding="utf-8")))
    paths = {g.rel: pathlib.Path(p) for g, p in zip(graphs, files)}
    report = []
    for rel, edits in sorted(by_file.items()):
        g = next(x for x in graphs if x.rel == rel)
        edits = [e for e in edits if not (e[1] == "scope" and g.by_id.get(e[0], {}).get("verified_scope") == e[2])]
        if not edits:
            continue
        path = paths[rel].resolve()  # um grafo que é symlink é gravado no alvo, e o link fica
        raw = path.read_bytes()
        text = raw.decode("utf-8")
        crlf = "\r\n" in text
        if (crlf and text.count("\n") != text.count("\r\n")) or "\r" in text.replace("\r\n", ""):
            report.append((rel, False, [_("mixed line endings (\\r\\n with \\n or a lone \\r): normalize first")]))
            continue
        old = text.replace("\r\n", "\n") if crlf else text
        new, refused = edit_text(old, edits)
        applied = {}
        for nid, action, value in edits:
            if nid in dict(refused):
                continue
            a = applied.setdefault(nid, {})
            if action == "provenance":
                a["provenance"] = value
            elif action == "unverifiable":
                a["status"] = "unverifiable"
            else:
                a["verified_scope"] = value
        why = [f"{n}: {m}" for n, m in refused]
        problem = invariance_problem(old, new, applied)
        if problem is None:
            before, after = set(kg_validate.codes(old, must)), set(kg_validate.codes(new, must))
            if after - before:
                problem = _("the file would gain a new MUST code: {codes}").format(
                    codes=", ".join(sorted(after - before)))
        if problem is None:
            grown = (kg_validate.warning_counts(new, must, should) - kg_validate.warning_counts(old, must, should)) - lit[rel]
            if grown:
                problem = _("the file would gain a SHOULD warning the plan did not announce: {codes}").format(
                    codes=", ".join(sorted(grown)))
        if problem:
            report.append((rel, False, why + [problem]))
            continue
        if refused and new == old:
            report.append((rel, False, why))
            continue
        if new != old:
            tmp = path.with_name(path.name + ".kg-migrate.tmp")
            tmp.write_bytes((new.replace("\n", "\r\n") if crlf else new).encode("utf-8"))
            try:
                os.chmod(tmp, path.stat().st_mode & 0o7777)
            except OSError:
                pass
            tmp.replace(path)
        report.append((rel, not refused, why))  # gravado com nós recusados conta como recusa no rc
    return report


# --- keys (4.19.0): a chave fora do contrato vira x_<chave> --------------------------------------------------------

# As chaves x_ com perfil canônico no SHOULD (v4.11): renomear para uma delas faz o valor ser julgado pelo perfil, e
# isso é decisão de quem revisa, não do migrador.
PROFILE_KEYS = {"node": {"x_term", "x_mirror", "x_doc_cycle", "x_questionnaire", "x_severity"},
                "edge": {"x_confidence", "x_provisional"}}


def known_keys(must):
    """As chaves que o contrato conhece em cada escopo, lidas do schema MUST (o enum do propertyNames), nunca de uma
    lista no código: a versão do contrato que muda a lista muda o migrador junto."""
    def enum(pn):
        return set(pn["else"]["allOf"][1]["enum"])
    d = must["$defs"]
    return {"top": enum(must["propertyNames"]), "meta": enum(d["meta"]["propertyNames"]),
            "node": enum(d["node"]["propertyNames"]), "edge": enum(d["edge"]["propertyNames"]),
            "external_edge": enum(d["externalEdge"]["propertyNames"])}


def key_targets(text, known):
    """As chaves fora do contrato e sem x_ no topo, no meta, nos nós, nas arestas e nas external_edges:
    [(escopo, lugar, índice, chave, nó-chave do YAML, chaves irmãs)]. O índice é a posição na lista (None no topo e
    no meta); o lugar é o que a pessoa lê (o id do nó, ou #n)."""
    import yaml
    root = yaml.compose(text, Loader=kg_validate.Yaml12CoreLoader)
    out = []
    if not isinstance(root, yaml.MappingNode):
        return out

    def scan(scope, place, index, m):
        if not isinstance(m, yaml.MappingNode):
            return
        names = {k.value for k, _v in m.value if isinstance(k, yaml.ScalarNode)}
        for k, _v in m.value:
            if isinstance(k, yaml.ScalarNode) and not k.value.startswith("x_") and k.value not in known[scope]:
                out.append((scope, place, index, k.value, k, names))

    scan("top", "topo", None, root)
    for k, v in root.value:
        name = getattr(k, "value", None)
        if name == "meta":
            scan("meta", "meta", None, v)
        elif name in ("nodes", "edges", "external_edges") and isinstance(v, yaml.SequenceNode):
            scope = {"nodes": "node", "edges": "edge", "external_edges": "external_edge"}[name]
            for i, item in enumerate(v.value):
                nid = None
                if scope == "node" and isinstance(item, yaml.MappingNode):
                    nid = next((iv.value for ik, iv in item.value if getattr(ik, "value", None) == "id"
                                and isinstance(iv, yaml.ScalarNode)), None)
                scan(scope, f"nó {nid}" if nid else f"{name} #{i + 1}", i, item)  # #n a partir de 1, como o kg_validate
    return out


def key_plan(text, known):
    """O plano de um arquivo: [(escopo, lugar, índice, chave, nova, ação, motivo, (linha, coluna))], ação rename ou
    review. A coluna é onde o x_ entra no texto."""
    lines = text.splitlines()
    rows = []
    for scope, place, index, key, knode, siblings in key_targets(text, known):
        new = "x_" + key
        start, end = knode.start_mark, knode.end_mark
        why, at = None, None
        if not kg_validate.SLUG.fullmatch(key):
            why = _("the key is not a slug: rename it by hand")
        elif new in siblings:
            why = _("{new} already exists in the same mapping").format(new=new)
        elif new in PROFILE_KEYS.get(scope, ()):
            why = _("{new} is a canonical profile (v4.11): its value would be judged by the profile").format(new=new)
        elif start.line != end.line or start.line >= len(lines):
            why = _("the key spans more than one line")
        else:
            line, col = lines[start.line], start.column
            if knode.style is None and line[col:col + len(key)] == key:
                at = (start.line, col)
            elif knode.style in ("'", '"') and line[col:col + 1] == knode.style and line[col + 1:col + 1 + len(key)] == key:
                at = (start.line, col + 1)
            else:
                why = _("the key is written in a form the migrator does not edit")
        rows.append((scope, place, index, key, new, "review" if why else "rename", why, at))
    return rows


def _renamed(doc, renames):
    """O documento com as renomeações aplicadas no dado: renames = [(escopo, índice, chave, nova)]."""
    import copy
    out = copy.deepcopy(doc)

    def ren(m, key, new):
        if isinstance(m, dict) and key in m:
            m[new] = m.pop(key)
    for scope, index, key, new in renames:
        if scope == "top":
            ren(out, key, new)
        elif scope == "meta":
            ren(out.get("meta"), key, new)
        else:
            lst = out.get({"node": "nodes", "edge": "edges", "external_edge": "external_edges"}[scope])
            if isinstance(lst, list) and index < len(lst):
                ren(lst[index], key, new)
    return out


def keys_apply_text(text, rows):
    """O texto com o x_ inserido em cada chave renomeável, e o motivo se a releitura não for a de antes com só as
    renomeações (o dado e o diff, linha a linha)."""
    lines = text.splitlines(keepends=True)
    todo = [r for r in rows if r[5] == "rename"]
    for r in sorted(todo, key=lambda r: r[7], reverse=True):  # da direita para a esquerda numa mesma linha
        ln, col = r[7]
        lines[ln] = lines[ln][:col] + "x_" + lines[ln][col:]
    new = "".join(lines)
    _t, old_doc, c1 = kg_validate.parse_v1(text)
    _t, new_doc, c2 = kg_validate.parse_v1(new)
    if c2 is not None:
        return new, _("the edited text does not parse ({code})").format(code=c2)
    if new_doc != _renamed(old_doc, [(r[0], r[2], r[3], r[4]) for r in todo]):
        return new, _("the reread document differs from the old one beyond the renamed keys")
    edited = {r[7][0] for r in todo}
    old_lines, new_lines = text.splitlines(), new.splitlines()
    if len(old_lines) != len(new_lines) or any(a != b for i, (a, b) in enumerate(zip(old_lines, new_lines))
                                               if i not in edited):
        return new, _("the text diff touched a line without a renamed key")
    return new, None


def keys_command(args):
    """kg_migrate.py keys: o plano (ou, com --apply, a gravação) da chave fora do contrato renomeada para x_."""
    must_schema = json.loads(kg_validate.CONTRACT_MUST.read_text(encoding="utf-8"))
    must = kg_validate.make_validator(must_schema)
    should = kg_validate.make_validator(json.loads(kg_validate.CONTRACT_SHOULD.read_text(encoding="utf-8")))
    known = known_keys(must_schema)
    files = args.graphs or tracked_graphs(args.root, args.exclude, not args.no_default_excludes)
    graphs, files, broken = load_graphs(files, args.root, lenient=not args.graphs)
    report, all_rows = [], []
    for g, f in zip(graphs, files):
        path = pathlib.Path(f).resolve()
        text = path.read_bytes().decode("utf-8")
        crlf = "\r\n" in text
        if (crlf and text.count("\n") != text.count("\r\n")) or "\r" in text.replace("\r\n", ""):
            report.append((g.rel, False, [_("mixed line endings (\\r\\n with \\n or a lone \\r): normalize first")]))
            continue
        old = text.replace("\r\n", "\n") if crlf else text
        rows = key_plan(old, known)
        all_rows.extend((g.rel,) + r for r in rows)
        if not args.apply or not any(r[5] == "rename" for r in rows):
            continue
        new, problem = keys_apply_text(old, rows)
        if problem is None:
            before, after = set(kg_validate.codes(old, must)), set(kg_validate.codes(new, must))
            if after - before:
                problem = _("the file would gain a new MUST code: {codes}").format(codes=", ".join(sorted(after - before)))
        if problem is None:
            grown = kg_validate.warning_counts(new, must, should) - kg_validate.warning_counts(old, must, should)
            if grown:
                problem = _("the file would gain a SHOULD warning: {codes}").format(codes=", ".join(sorted(grown)))
        if problem:
            report.append((g.rel, False, [problem]))
            continue
        tmp = path.with_name(path.name + ".kg-migrate.tmp")
        tmp.write_bytes((new.replace("\n", "\r\n") if crlf else new).encode("utf-8"))
        try:
            os.chmod(tmp, path.stat().st_mode & 0o7777)
        except OSError:
            pass
        tmp.replace(path)
        report.append((g.rel, True, []))
    if args.json:
        print(json.dumps({"rows": [dict(zip(("file", "scope", "place", "key", "new_key", "action", "review"),
                                            (r[0], r[1], r[2], r[4], r[5], r[6], r[7]))) for r in all_rows],
                          "unreadable": [{"file": rel, "code": code} for rel, code in broken],
                          "applied": [{"file": rel, "written": ok, "reasons": why} for rel, ok, why in report]
                          if args.apply else None}, ensure_ascii=False))
    else:
        for r in all_rows:
            mark = _("RENAME") if r[6] == "rename" else _("REVIEW")
            print(f"{mark:8}  {r[0]}  {r[2]}  {r[4]} → {r[5]}" + (f"  ({r[7]})" if r[7] else ""))
        for rel, code in broken:
            print(_("REVIEW").ljust(8) + "  " + rel + "  " + _("graph that does not parse ({code}): left out").format(code=code))
        for rel, ok, why in report:
            print(f"{(_('WRITTEN') if ok else _('REFUSED')):8}  {rel}" + "".join(f"\n    {w}" for w in why))
        renames = sum(1 for r in all_rows if r[6] == "rename")
        print(_("· {renames} key(s) to rename, {review} for the reviewer, in {files} file(s){written}").format(
            renames=renames, review=len(all_rows) - renames, files=len({r[0] for r in all_rows}),
            written=(_("; {n} file(s) written").format(n=sum(1 for _r, ok, _w in report if ok)) if args.apply
                     else _("; nothing was written (without --apply)"))))
    return 1 if any(not ok for _r, ok, _w in report) else 0


# --- nest (4.21.0): a chave x_ própria para um perfil canônico de nó -----------------------------------------------
NEST_SCHEMA = ROOT / "spec" / "kg-migrate-nest.schema.json"


def _profile_schema(into):
    """O subschema SHOULD do perfil canônico de nó (o properties.nodes.items.properties.<into>)."""
    should = json.loads(kg_validate.CONTRACT_SHOULD.read_text(encoding="utf-8"))
    return should["properties"]["nodes"]["items"]["properties"][into]


def load_nest_map(path):
    """O mapa do nest, validado pelo schema e pelo que o schema não exprime (Broken: entrada quebrada)."""
    try:
        text = pathlib.Path(path).read_text(encoding="utf-8")
    except (OSError, UnicodeDecodeError) as exc:
        raise Broken(_("unreadable map: {file}: {exc}").format(file=path, exc=exc))
    _t, doc, code = kg_validate.parse_v1(kg_validate.as_source(str(path), text))
    if code or not isinstance(doc, dict):
        raise Broken(_("the map does not parse ({code}): {file}").format(code=code or "parse.not-a-map", file=path))
    v = kg_validate.make_validator(json.loads(NEST_SCHEMA.read_text(encoding="utf-8")))
    errors = sorted(v.iter_errors(doc), key=lambda e: list(e.absolute_path))
    if errors:
        e = errors[0]
        raise Broken(_("map outside spec/kg-migrate-nest.schema.json at {path}: {msg}").format(
            path="/".join(map(str, e.absolute_path)) or _("(root)"), msg=e.message))
    seen_into, moved, copied = set(), set(), set()
    for rule in doc["nest"]:
        into = rule["into"]
        if into in seen_into:
            raise Broken(_("two rules build {into}").format(into=into))
        seen_into.add(into)
        prof = _profile_schema(into)
        allowed = set(prof["propertyNames"]["allOf"][1]["anyOf"][0]["enum"])
        for field, src in rule["fields"].items():
            if field not in allowed and not field.startswith("x_"):
                raise Broken(_("{field} is not a field of {into}").format(field=field, into=into))
            if field == "x_raw" and rule.get("raw"):
                raise Broken(_("x_raw is filled by raw: true, not by a field"))
            if "move" in src:
                if src["move"] in moved:
                    raise Broken(_("{key} is moved by two fields").format(key=src["move"]))
                moved.add(src["move"])
                if ("match" in src or "prefixes" in src) and not rule.get("raw"):
                    # a regex e o prefixo cortam texto da chave que sai do nó: sem o x_raw, o texto some
                    raise Broken(_("{into}.{field} moves {key} through match or prefixes, which cut text: the rule "
                                   "needs raw: true to keep the original").format(into=into, field=field, key=src["move"]))
            if "copy" in src:
                copied.add(src["copy"])
            if "match" in src:
                try:
                    rx = ecma_regex(src["match"])
                except ValueError as exc:
                    raise Broken(_("the match of {into}.{field} uses {what}, which ECMA-262 reads otherwise or not at "
                                   "all").format(into=into, field=field, what=exc))
                except re.error as exc:
                    raise Broken(_("invalid regex in {into}.{field}: {exc}").format(into=into, field=field, exc=exc))
                if rx.groups != 1:
                    raise Broken(_("the match of {into}.{field} needs exactly one group").format(into=into, field=field))
    both = sorted(moved & copied)
    if both:
        raise Broken(_("{keys} is moved and copied: a copied key stays in the node, so it cannot also leave it").format(
            keys=", ".join(both)))
    return doc


# O \s do ECMA-262: o espaço Unicode, mesmo sem a flag u (o re.ASCII do Python o deixaria só em ASCII).
_ECMA_SPACE = "\\t\\n\\x0b\\f\\r \\u00a0\\u1680\\u2000-\\u200a\\u2028\\u2029\\u202f\\u205f\\u3000\\ufeff"
_QUANT = re.compile(r"\{([0-9]*)(,?)([0-9]*)\}")


def ecma_to_python(pattern):
    r"""A regex do mapa reescrita para o re do Python com a semântica do ECMA-262 sem a flag u; ValueError diz o que
    não tem o mesmo sentido nos dois. Fora de classe, o . não casa \n, \r, U+2028 nem U+2029, o $ é o fim do texto (\Z)
    e o \s e o \S são o espaço Unicode do ECMA; o \w, o \d e o \b ficam em ASCII pelo re.ASCII. A classe [...] é lida
    como classe (um $ ou um (?P dentro dela é literal). Recusa: \A, \Z, \z, \G, \N, \U, \a, \c, \p, \P, \S dentro de
    classe, (?P, (?<nome>, (?#, (?(, (?>, flag em linha, quantificador possessivo, {,n}, [] e [^]."""
    out, i, n, in_class, quant = [], 0, len(pattern), False, False
    groups, behind = [], False  # a pilha diz se cada ( aberto é um lookbehind; behind: o ) que acabou de fechar era um
    while i < n:
        c = pattern[i]
        if c not in "*+?{":
            behind = False  # só o quantificador logo depois do ) de um lookbehind é recusado
        if c == "\\":
            if i + 1 >= n:
                raise ValueError("\\")
            e = pattern[i + 1]
            if e in "AZzGNUacpP":
                raise ValueError("\\" + e)
            if e == "s":
                out.append(_ECMA_SPACE if in_class else "[" + _ECMA_SPACE + "]")
            elif e == "S":
                if in_class:
                    raise ValueError("\\S inside [...]")
                out.append("[^" + _ECMA_SPACE + "]")
            else:
                out.append(c + e)
            i, quant = i + 2, False
            continue
        if in_class:
            in_class = c != "]"
            out.append(c)
            i += 1
            continue
        if c == "[":
            start = i + 2 if pattern.startswith("^", i + 1) else i + 1
            if pattern.startswith("]", start):
                raise ValueError(pattern[i:start + 1])  # [] e [^] são classe vazia no ECMA e outra coisa no Python
            out.append(pattern[i:start])
            i, in_class, quant = start, True, False
            continue
        if c == "(" and pattern.startswith("(?", i):
            rest = pattern[i + 2:i + 4]
            if not (rest[:1] in (":", "=", "!") or rest in ("<=", "<!")):
                raise ValueError(pattern[i:i + 4])
        if c == "(":
            groups.append(pattern.startswith(("(?<=", "(?<!"), i))
        if c == ")":
            out.append(c)
            i, quant, behind = i + 1, False, groups.pop() if groups else False
            continue
        if c in "*+?" or (c == "{" and _QUANT.match(pattern, i)):
            if behind:  # o ECMA-262 não deixa quantificar um lookbehind; o Python deixa
                raise ValueError(pattern[i - 1:i + 1])
        if c in "*+?":
            if quant and c == "+":
                raise ValueError(pattern[i - 1:i + 1])
            out.append(c)
            i, quant = i + 1, c != "?" or not quant  # o ? depois de quantificador é o preguiçoso, que os dois leem
            continue
        if c == "{":
            m = _QUANT.match(pattern, i)
            if m and (m.group(1) or not m.group(2)) and (m.group(1) or m.group(3)):
                out.append(m.group(0))
                i, quant = m.end(), True
                continue
            if m and m.group(2) and not m.group(1):
                raise ValueError(m.group(0))
        out.append({".": "[^\\n\\r\\u2028\\u2029]", "$": "\\Z"}.get(c, c))
        i, quant, behind = i + 1, False, False  # o { literal é um átomo: o quantificador seguinte vale para ele
    return "".join(out)


def ecma_regex(pattern):
    """A regex do mapa compilada com a semântica do ECMA-262 sem a flag u (ecma_to_python): ValueError no que não tem o
    mesmo sentido nos dois, re.error na regex inválida."""
    return re.compile(ecma_to_python(pattern), re.ASCII)


def _map_value(value, src):
    """(valor, tinha texto além do código, motivo): o valor da fonte depois do match e da tabela; motivo não vazio vai
    para quem revisa. Só o valor exato da tabela (values) não tem texto além do código: o que passou pela regex ou
    entrou por prefixo tem, e é o que o raw guarda (pedido do brain: o "vigente" puro no x_raw é ruído)."""
    out, extra = value, False
    if kg_validate._contains(value, lambda x: isinstance(x, kg_validate.NonFinite)):
        return None, False, _("the value has .nan or .inf, which no profile field takes")
    if "match" in src:
        if not isinstance(out, str):
            return None, False, _("the value is not text, and match needs text")
        if any(ord(ch) > 0xFFFF for ch in out):  # o ECMA-262 sem a flag u conta unidades UTF-16; o Python, caracteres
            return None, False, _("the value has a character beyond U+FFFF, which a regex reads differently in ECMA-262")
        m = ecma_regex(src["match"]).search(out)
        if not m or not m.group(1):  # o grupo que não participa, ou que casa vazio, não dá código
            return None, False, _("the value {value} does not match {rx}").format(value=_yaml_str(out), rx=src["match"])
        out, extra = m.group(1), m.group(1) != value
    if "values" in src or "prefixes" in src:
        if not isinstance(out, str):
            return None, False, _("the value is not text, and the value table needs text")
        if out in src.get("values", {}):
            out = src["values"][out]
        else:
            hits = [p for p in src.get("prefixes", {}) if out.startswith(p)]
            if not hits:
                return None, False, _("the value {value} has no code in the table: map it or edit it by hand").format(
                    value=_yaml_str(out))
            best = max(hits, key=len)
            out, extra = src["prefixes"][best], extra or out != best
    return out, extra, None


def nest_node(node, rule):
    """(perfil montado, chaves movidas, motivo) de um nó para uma regra; perfil None com motivo vai para quem revisa."""
    into = rule["into"]
    if into in node:
        return None, [], _("the node already has {into}").format(into=into)
    prof = _profile_schema(into)
    required = set(prof.get("required", ()))
    obj, moved, raw = {}, [], {}
    for field, src in rule["fields"].items():
        if "const" in src:
            obj[field] = src["const"]
            continue
        key = src.get("move") or src.get("copy")
        if key not in node:
            if field in required:
                return None, [], _("{key} is missing, and {into}.{field} is required").format(key=key, into=into, field=field)
            continue
        value, changed, why = _map_value(node[key], src)
        if why:
            return None, [], f"{key}: {why}"
        obj[field] = value
        if "move" in src:
            moved.append(key)
            if changed and rule.get("raw"):
                raw[key] = node[key]
    if raw:
        obj["x_raw"] = raw
    missing = sorted(required - set(obj))
    if missing:
        return None, [], _("{into} lacks the required field(s) {fields}").format(into=into, fields=", ".join(missing))
    errs = sorted(kg_validate.make_validator(prof).iter_errors(obj), key=lambda e: list(e.absolute_path))
    if errs:
        e = errs[0]
        return None, [], _("the built {into} does not pass the profile at {path}: {msg}").format(
            into=into, path="/".join(map(str, e.absolute_path)) or into, msg=e.message)
    return obj, moved, None


def flow_nodes(text):
    """Os índices dos nós em estilo de fluxo ({...}), que o nest não edita por texto."""
    import yaml
    root = yaml.compose(text, Loader=kg_validate.Yaml12CoreLoader)
    if not isinstance(root, yaml.MappingNode):
        return set()
    seq = next((v for k, v in root.value if getattr(k, "value", None) == "nodes"), None)
    if not isinstance(seq, yaml.SequenceNode):
        return set()
    return {i for i, m in enumerate(seq.value) if isinstance(m, yaml.MappingNode) and m.flow_style}


def nest_plan(doc, nest_map, flow=frozenset()):
    """[(índice do nó, id, perfil, ação, motivo, chaves movidas, perfil montado)] de um documento. flow: os índices dos
    nós em estilo de fluxo, que vão para quem revisa."""
    rows = []
    nodes = doc.get("nodes") if isinstance(doc.get("nodes"), list) else []
    for i, node in enumerate(nodes):
        if not isinstance(node, dict):
            continue
        for rule in nest_map["nest"]:
            if rule["when"] not in node:
                continue
            obj, moved, why = nest_node(node, rule)
            if node[rule["when"]] is None:  # o marcador vazio não diz que o nó é do perfil
                obj, moved, why = None, [], _("the marker {key} is null").format(key=rule["when"])
            if not why and i in flow:
                obj, moved, why = None, [], _("node {n} is in flow style: edit it by hand").format(n=i + 1)
            rows.append((i, node.get("id"), rule["into"], "review" if why else "nest", why, moved, obj))
    return rows


def _yaml_inline(value):
    """Um valor YAML numa linha só: texto entre aspas duplas, a coleção vazia ([] ou {}), número, booleano ou null."""
    if isinstance(value, str):
        return _yaml_str(value)
    if isinstance(value, list):
        return "[]"
    if isinstance(value, dict):
        return "{}"
    return json.dumps(value)


def _yaml_block(value, indent):
    """As linhas YAML de uma coleção não vazia, em bloco, na indentação dada: mapa e lista aninhados em qualquer
    nível, e a coleção vazia ou o escalar na mesma linha da chave ou do traço."""
    out = []
    items = value.items() if isinstance(value, dict) else ((None, v) for v in value)
    for k, v in items:
        plain = k is not None and kg_validate.SLUG.fullmatch(k) and k.lower() not in ("null", "true", "false")
        head = " " * indent + ((k if plain else _yaml_str(k)) + ":" if k is not None else "-")
        if isinstance(v, (dict, list)) and v:
            sub = _yaml_block(v, indent + 2)
            if k is None and isinstance(v, dict):  # o mapa num item de lista começa na linha do traço
                out.append(head + " " + sub[0].lstrip())
                out.extend(sub[1:])
            else:
                out.append(head)
                out.extend(sub)
        else:
            out.append(head + " " + _yaml_inline(v))
    return out


def _scalar_end(node, lines=None):
    """A última linha (0-based) com conteúdo de um nó YAML composto. Com as linhas do texto, a linha em branco no fim de
    um escalar (o bloco | ou > guarda a quebra seguinte no end_mark) não conta: ela fica no arquivo."""
    import yaml
    if isinstance(node, yaml.ScalarNode):
        m = node.end_mark
        end = m.line - 1 if m.column == 0 and m.line > node.start_mark.line else m.line
        while lines is not None and end > node.start_mark.line and end < len(lines) and not lines[end].strip():
            end -= 1
        return end
    kids = [v for pair in node.value for v in pair] if isinstance(node, yaml.MappingNode) else list(node.value)
    return max([node.start_mark.line] + [_scalar_end(k, lines) for k in kids])


def nest_apply_text(text, doc, rows):
    """(texto novo, motivo): as chaves movidas saem por texto e o perfil entra no lugar da primeira; o motivo diz por
    que o arquivo não pode ser gravado (a releitura difere do documento esperado)."""
    import copy
    import yaml
    todo = [r for r in rows if r[3] == "nest"]
    if not text.endswith("\n"):
        text += "\n"  # o bloco do perfil no fim do arquivo não cola na última linha; o arquivo ganha a quebra final
    root = yaml.compose(text, Loader=kg_validate.Yaml12CoreLoader)
    seq = next((v for k, v in root.value if getattr(k, "value", None) == "nodes"), None)
    lines = text.splitlines(keepends=True)
    edits = []  # (início, fim exclusivo, linhas novas)
    for idx, _nid, into, _a, _w, moved, obj in todo:
        m = seq.value[idx]
        if not isinstance(m, yaml.MappingNode) or m.flow_style:
            return text, _("node {n} is in flow style: edit it by hand").format(n=idx + 1)
        pairs = [(k, v) for k, v in m.value if isinstance(k, yaml.ScalarNode)]
        moving = [(k, v) for k, v in pairs if k.value in moved]
        for k, v in moving:
            if (v.start_mark.line, v.start_mark.column) < (k.end_mark.line, k.end_mark.column):
                return text, _("node {n}: {key} is an alias (*): edit it by hand").format(n=idx + 1, key=k.value)
        spans = sorted((k.start_mark.line, _scalar_end(v, lines) + 1) for k, v in moving)
        if spans:  # o perfil entra no lugar da primeira chave movida, com o que vem antes dela na linha (o "- " do item)
            anchor_line = spans[0][0]
            col = next(k for k, _v in moving if k.start_mark.line == anchor_line).start_mark.column
            lead = lines[anchor_line][:col]
        else:  # nada se move (só const e copy): o perfil entra no fim do nó
            anchor_line, col = _scalar_end(m, lines) + 1, pairs[0][0].start_mark.column
            lead = " " * col
        block = [lead + f"{into}:\n"] + [ln + "\n" for ln in _yaml_block(obj, col + 2)]
        edits += [(s, e, block if s == anchor_line else []) for s, e in spans]
        if not spans:
            edits.append((anchor_line, anchor_line, block))
    edits.sort()
    for (s1, e1, _b1), (s2, _e2, _b2) in zip(edits, edits[1:]):
        if s2 < e1:
            return text, _("two edits overlap in the same lines: edit them by hand")
    for s, e, block in reversed(edits):
        lines[s:e] = block
    new = "".join(lines)
    _t, old_doc, _c = kg_validate.parse_v1(text)
    _t, new_doc, c2 = kg_validate.parse_v1(new)
    if c2 is not None:
        return new, _("the edited text does not parse ({code})").format(code=c2)
    want = copy.deepcopy(old_doc)
    for idx, _nid, into, _a, _w, moved, obj in todo:
        for k in moved:
            want["nodes"][idx].pop(k, None)
        want["nodes"][idx][into] = kg_validate.canonical(obj, json_keys=True)
    if new_doc != want:
        return new, _("the reread document differs from the old one beyond the nested keys")
    return new, None


def _shared_nodes(text):
    """A raiz composta e os nós YAML que aparecem em mais de um lugar dela: o valor com âncora usada por um alias, e o
    próprio alias (o compose devolve o mesmo objeto nos dois)."""
    import yaml
    root = yaml.compose(text, Loader=kg_validate.Yaml12CoreLoader)
    seen, shared, stack = set(), set(), [root]
    while stack:
        node = stack.pop()
        if id(node) in seen:
            shared.add(id(node))
            continue
        seen.add(id(node))
        if isinstance(node, yaml.MappingNode):
            stack.extend(v for pair in node.value for v in pair)
        elif isinstance(node, yaml.SequenceNode):
            stack.extend(node.value)
    return root, shared


def dry_run(text, doc, rows):
    """As linhas do plano depois de ensaiar a edição de texto: o nó que a edição não sabe fazer vai para quem revisa
    já no plano, e não derruba o arquivo inteiro no --apply.

    Primeiro um filtro de um compose só: a chave movida cujo valor tem âncora usada por um alias, ou é um alias (direto
    ou dentro de uma lista), vai para revisão. Depois, um ensaio da edição combinada; só quando ela falha as linhas são
    divididas ao meio até achar as culpadas, e o resto é ensaiado de novo. Um arquivo bom custa um compose e uma
    edição (o ensaio nó a nó levava o plano do brain de 1 s a 71 s, e a bissecção sem o filtro, com 400 aliases, 146 s)."""
    import yaml

    def review(row, problem):
        return row[:3] + ("review", _("the text edit does not reread the same ({problem}): edit it by hand").format(
            problem=problem), [], None)
    todo = [r for r in rows if r[3] == "nest"]
    if not todo:
        return rows
    culprits = {}
    root, shared = _shared_nodes(text)
    seq = next((v for k, v in root.value if getattr(k, "value", None) == "nodes"), None)
    for r in todo:
        m = seq.value[r[0]]
        for k, v in (m.value if isinstance(m, yaml.MappingNode) else ()):
            if k.value not in r[5]:
                continue
            stack = [k, v]  # a âncora pode estar na própria chave (&a x_issuer: CMN), e não só no valor
            while stack and id(r) not in culprits:
                node = stack.pop()
                if id(node) in shared:
                    culprits[id(r)] = _("{key} has an anchor (&) or an alias (*)").format(key=k.value)
                elif isinstance(node, yaml.MappingNode):
                    stack.extend(x for pair in node.value for x in pair)
                elif isinstance(node, yaml.SequenceNode):
                    stack.extend(node.value)

    def bad(group):
        problem = nest_apply_text(text, doc, group)[1]
        if problem is None:
            return {}
        if len(group) == 1:
            return {id(group[0]): problem}
        half = len(group) // 2
        found = {**bad(group[:half]), **bad(group[half:])}
        return found or {id(r): problem for r in group}  # cada metade passa e o todo não: as linhas juntas vão revisar
    rest = [r for r in todo if id(r) not in culprits]
    if rest:
        culprits.update(bad(rest))
        rest = [r for r in rest if id(r) not in culprits]
        problem = nest_apply_text(text, doc, rest)[1] if rest else None
        if problem is not None:  # o que sobrou não passa junto (uma interação que a bissecção separou): tudo vai revisar
            culprits.update({id(r): problem for r in rest})
    return [review(r, culprits[id(r)]) if id(r) in culprits else r for r in rows]


def nest_command(args):
    """kg_migrate.py nest: o plano (ou, com --apply, a gravação) das chaves x_ levadas a um perfil canônico."""
    nest_map = load_nest_map(args.map)
    must = kg_validate.make_validator(json.loads(kg_validate.CONTRACT_MUST.read_text(encoding="utf-8")))
    should = kg_validate.make_validator(json.loads(kg_validate.CONTRACT_SHOULD.read_text(encoding="utf-8")))
    files = args.graphs or tracked_graphs(args.root, args.exclude, not args.no_default_excludes)
    graphs, files, broken = load_graphs(files, args.root, lenient=not args.graphs)
    report, all_rows = [], []
    for g, f in zip(graphs, files):
        path = pathlib.Path(f).resolve()
        text = path.read_bytes().decode("utf-8")
        crlf = "\r\n" in text
        if (crlf and text.count("\n") != text.count("\r\n")) or "\r" in text.replace("\r\n", ""):
            report.append((g.rel, False, [_("mixed line endings (\\r\\n with \\n or a lone \\r): normalize first")]))
            continue
        old = text.replace("\r\n", "\n") if crlf else text
        _t, doc, _c = kg_validate.parse_v1(old)
        rows = dry_run(old, doc, nest_plan(doc, nest_map, flow_nodes(old)))
        all_rows.extend((g.rel,) + r for r in rows)
        if not args.apply or not any(r[3] == "nest" for r in rows):
            continue
        new, problem = nest_apply_text(old, doc, rows)
        if problem is None:
            before, after = set(kg_validate.codes(old, must)), set(kg_validate.codes(new, must))
            if after - before:
                problem = _("the file would gain a new MUST code: {codes}").format(codes=", ".join(sorted(after - before)))
        if problem is None:
            grown = kg_validate.warning_counts(new, must, should) - kg_validate.warning_counts(old, must, should)
            if grown:
                problem = _("the file would gain a SHOULD warning: {codes}").format(codes=", ".join(sorted(grown)))
        if problem:
            report.append((g.rel, False, [problem]))
            continue
        tmp = path.with_name(path.name + ".kg-migrate.tmp")
        tmp.write_bytes((new.replace("\n", "\r\n") if crlf else new).encode("utf-8"))
        try:
            os.chmod(tmp, path.stat().st_mode & 0o7777)
        except OSError:
            pass
        tmp.replace(path)
        report.append((g.rel, True, []))
    if args.json:
        print(json.dumps({"rows": [{"file": r[0], "id": r[2], "into": r[3], "action": r[4], "review": r[5],
                                    "moved": r[6], "profile": r[7]} for r in all_rows],
                          "unreadable": [{"file": rel, "code": code} for rel, code in broken],
                          "applied": [{"file": rel, "written": ok, "reasons": why} for rel, ok, why in report]
                          if args.apply else None}, ensure_ascii=False))
    else:
        for r in all_rows:
            mark = _("NEST") if r[4] == "nest" else _("REVIEW")
            print(f"{mark:8}  {r[0]}  {r[2]}  → {r[3]}" + (f"  ({r[5]})" if r[5] else ""))
        for rel, code in broken:
            print(_("REVIEW").ljust(8) + "  " + rel + "  " + _("graph that does not parse ({code}): left out").format(code=code))
        for rel, ok, why in report:
            print(f"{(_('WRITTEN') if ok else _('REFUSED')):8}  {rel}" + "".join(f"\n    {w}" for w in why))
        nested = sum(1 for r in all_rows if r[4] == "nest")
        print(_("· {nested} node profile(s) to build, {review} for the reviewer, in {files} file(s){written}").format(
            nested=nested, review=len(all_rows) - nested, files=len({r[0] for r in all_rows}),
            written=(_("; {n} file(s) written").format(n=sum(1 for _r, ok, _w in report if ok)) if args.apply
                     else _("; nothing was written (without --apply)"))))
    return 1 if any(not ok for _r, ok, _w in report) else 0


def load_graphs(files, root, lenient=False):
    """Os grafos lidos. Com lenient (a lista veio do git), o grafo que não parseia volta à parte, para quem revisa."""
    out, broken = [], []
    for f in files:
        p = pathlib.Path(f)
        try:
            text = p.read_text(encoding="utf-8")
        except (OSError, UnicodeDecodeError) as exc:
            if not lenient:
                raise Broken(_("unreadable graph: {file}: {exc}").format(file=f, exc=exc))
            broken.append((os.fsdecode(f), f"ilegível: {type(exc).__name__}"))
            continue
        _txt, doc, code = kg_validate.parse_v1(text)
        try:
            rel = p.resolve().relative_to(pathlib.Path(root).resolve()).as_posix()
        except ValueError:
            rel = p.as_posix()
        if code or not isinstance(doc, dict):
            if not lenient:
                raise Broken(_("graph that does not parse ({code}): {file}").format(code=code, file=f))
            broken.append((rel, code or "parse.not-a-map"))
            continue
        out.append((Graph(rel, doc), f))
    return [g for g, _f in out], [f for _g, f in out], broken


DEFAULT_EXCLUDE = ["vendor/*", "*/fixtures/*", "docs/materials/*"]  # os do kg_gate.py, e o vendor


def tracked_graphs(root, exclude=(), defaults=True):
    """Os .kg.yaml rastreados pelo git, fora os que casam algum glob, com a semântica do kg_gate.py: fnmatch sobre o
    caminho relativo, em que * atravessa /. Os padrões são os do gate (as fixtures são quebradas de propósito) e o
    vendor/*, e, com defaults, toda pasta com o carimbo do vendor (kg_validate.vendor_dirs), onde quer que ela esteja. O
    dialeto do perfil (**/ casa zero pastas) também vale, como antes da 4.13.1."""
    r = subprocess.run(["git", "-C", str(root), "ls-files", "-z", "--", "*.kg.yaml"], capture_output=True)
    if r.returncode != 0:
        raise Broken(_("{root} is not a git repository, and no graph was given").format(root=root))
    globs = (DEFAULT_EXCLUDE if defaults else []) + list(exclude)
    globs = [g[2:] if g.startswith("./") else g for g in globs]
    names = r.stdout.decode("utf-8", "surrogateescape").split("\0")
    vendors = kg_validate.find_vendor_dirs(root) if defaults else ()
    # a união: o fnmatch do gate (* atravessa /) e o dialeto de antes (**/ casa zero pastas), para quem já excluía
    # com ** não ver o apply gravar no que antes ficava de fora
    return [str(pathlib.Path(root) / n) for n in names
            if n and not kg_validate.in_vendor(n, vendors)
            and not any(fnmatch.fnmatchcase(n, g) or glob_match(n, g) for g in globs)]


def broken_input(args, exc):
    """Entrada quebrada (rc 2). No plan --json, o objeto no stdout, que o erro de uso do argparse (rc 2, só no stderr)
    nunca escreve: quem lê a máquina distingue os dois sem casar frase."""
    if args.cmd in ("plan", "keys", "nest") and args.json:
        print(json.dumps({"error": str(exc), "reason": "broken_input"}, ensure_ascii=False))
    else:
        print(_("BROKEN INPUT  {error}").format(error=exc))
    return 2


def main(argv=None):
    ap = argparse.ArgumentParser(description=_((
        "The official KG-SSOT migrator: proposes the provenance the contract asks for, from the adopter's declared profile.\n"
        "\n"
        "  kg_migrate.py plan  --profile PROFILE.yaml [--root DIR] [--exclude GLOB] [--no-default-excludes] [--json] [--out SHEET.tsv] [graph.kg.yaml ...]\n"
        "  kg_migrate.py apply --profile PROFILE.yaml [--root DIR] [--exclude GLOB] [--no-default-excludes] [graph.kg.yaml ...]\n"
        "  kg_migrate.py keys [--apply] [--json] [--root DIR] [--exclude GLOB] [--no-default-excludes] [graph.kg.yaml ...]\n"
        "  kg_migrate.py nest --map MAP.yaml [--apply] [--json] [--root DIR] [--exclude GLOB] [--no-default-excludes] [graph.kg.yaml ...]\n"
        "\n"
        "nest (4.21.0) moves the adopter's own x_ keys into a canonical node profile (x_mirror, x_doc_cycle, x_questionnaire),\n"
        "by text, as the map says (spec/kg-migrate-nest.schema.json): each profile field comes from a constant, from an x_ key\n"
        "that leaves the node, or from a key that stays, through an optional regex and value table. A value with no code in\n"
        "the table, a missing required source, a node that already has the profile, or a profile that fails its SHOULD schema\n"
        "goes to the reviewer; nothing is guessed. With --apply, the same checks as keys hold.\n"
        "\n"
        "keys (4.19.0) renames each key the contract does not know in the top level, meta, nodes, edges and external_edges\n"
        "to x_<key>, the extension prefix, by text (comments stay). The known keys come from the MUST schema itself. A key\n"
        "that is not a slug, that would collide with an existing x_<key>, or that would become a canonical profile (x_severity,\n"
        "x_term...) goes to the reviewer. With --apply, each file is written only if the reread document equals the old one\n"
        "with only the renamed keys, the diff touches only those lines, and the file gains no MUST code or SHOULD warning.\n"
        "\n"
        "The profile (spec/kg-migrate-profile.schema.json) declares rules in order: the first one whose when matches decides the\n"
        "node's action (propose provenance, demote to unverifiable, or only list it for the reviewer), and the scopes block sets\n"
        "verified_scope by a list of ids. The universe is fixed: nodes with status confirmed or plane PROD, without provenance,\n"
        "except unverifiable ones. With no graphs on the command line, the tool reads the tracked .kg.yaml files under --root\n"
        "(default: the current directory), except the kg_gate.py defaults (*/fixtures/*, docs/materials/*), vendor/*, any folder with the .kg-ssot-version stamp and the\n"
        "--exclude globs, with the gate's semantics (* crosses /); a graph in that list that does not parse becomes a row for\n"
        "the reviewer. A node whose verified_scope already matches the profile comes out as same, and apply leaves it alone.\n"
        "\n"
        "plan writes nothing: it prints the proposal sheet (one row per node), the counts per rule and what is left for the\n"
        "reviewer. Every proposed provenance is checked against the MUST and SHOULD of the current contract before it becomes a\n"
        "proposal; one that would fail, or whose template resolves to empty, goes to review with the reason.\n"
        "\n"
        "apply writes the plan's proposals, one file at a time: it inserts by text (comments stay), rereads the file and verifies\n"
        "invariance node by node (each node's dict equals the one before, except the keys the action allows) and line by line\n"
        "(the diff only adds lines, except the line of the demoted status), and writes only if the file gains no new MUST code.\n"
        "A file that fails any check stays as it was, and the reason goes in the report. Running apply again changes nothing.\n"
        "A node in flow style ({...}) is not touched: it goes to review.\n"
        "\n"
        "rc: 0 the plan came out or apply finished (refused files show in the report) · 1 apply refused some file ·\n"
        "2 broken input (profile outside the schema, repeated rule, invalid regex, a graph given on the command line that does\n"
        "not parse).\n")), formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    p = sub.add_parser("plan", help=_("proposes without writing anything"))
    p.add_argument("--profile", required=True)
    p.add_argument("--root", default=".")
    p.add_argument("--json", action="store_true")
    p.add_argument("--out", help=_("writes the proposal sheet as TSV"))
    p.add_argument("--exclude", action="append", default=[],
                   help=_("extra glob to leave out of the git list (fnmatch: * crosses /, as in kg_gate.py)"))
    p.add_argument("--no-default-excludes", action="store_true",
                   help=_("does not apply the defaults: {globs}").format(globs=", ".join(DEFAULT_EXCLUDE)))
    p.add_argument("graphs", nargs="*")
    a = sub.add_parser("apply", help=_("writes the proposals, with invariance and gate per file"))
    a.add_argument("--profile", required=True)
    a.add_argument("--root", default=".")
    a.add_argument("--exclude", action="append", default=[],
                   help=_("extra glob to leave out of the git list (fnmatch: * crosses /, as in kg_gate.py)"))
    a.add_argument("--no-default-excludes", action="store_true",
                   help=_("does not apply the defaults: {globs}").format(globs=", ".join(DEFAULT_EXCLUDE)))
    a.add_argument("graphs", nargs="*")
    k = sub.add_parser("keys", help=_("renames the keys outside the contract to x_<key> (4.19.0)"))
    k.add_argument("--apply", action="store_true", help=_("writes the renames; without it, only the plan"))
    k.add_argument("--root", default=".")
    k.add_argument("--json", action="store_true")
    k.add_argument("--exclude", action="append", default=[],
                   help=_("extra glob to leave out of the git list (fnmatch: * crosses /, as in kg_gate.py)"))
    k.add_argument("--no-default-excludes", action="store_true",
                   help=_("does not apply the defaults: {globs}").format(globs=", ".join(DEFAULT_EXCLUDE)))
    k.add_argument("graphs", nargs="*")
    n = sub.add_parser("nest", help=_("moves the adopter's own x_ keys into a canonical node profile (4.21.0)"))
    n.add_argument("--map", required=True, help=_("the nest map (spec/kg-migrate-nest.schema.json)"))
    n.add_argument("--apply", action="store_true", help=_("writes the profiles; without it, only the plan"))
    n.add_argument("--root", default=".")
    n.add_argument("--json", action="store_true")
    n.add_argument("--exclude", action="append", default=[],
                   help=_("extra glob to leave out of the git list (fnmatch: * crosses /, as in kg_gate.py)"))
    n.add_argument("--no-default-excludes", action="store_true",
                   help=_("does not apply the defaults: {globs}").format(globs=", ".join(DEFAULT_EXCLUDE)))
    n.add_argument("graphs", nargs="*")
    args = ap.parse_args(argv)
    if args.cmd == "nest":
        try:
            return nest_command(args)
        except Broken as exc:
            return broken_input(args, exc)
    if args.cmd == "keys":
        try:
            return keys_command(args)
        except Broken as exc:
            return broken_input(args, exc)
    try:
        prof = load_profile(args.profile)
        files = args.graphs or tracked_graphs(args.root, args.exclude, not args.no_default_excludes)
        graphs, files, broken = load_graphs(files, args.root, lenient=not args.graphs)
    except Broken as exc:
        return broken_input(args, exc)
    if args.cmd == "apply":
        report = apply(prof, graphs, args.root, files)
        for rel, code in broken:
            print(_("REVIEW").ljust(8) + "  " + rel)
            print("    " + _("graph that does not parse ({code}): left out").format(code=code))
        for rel, ok, why in report:
            word = _("WRITTEN") if ok else _("REFUSED") if not why or not all(': ' in w for w in why) else _("REVIEW")
            print(f"{word:8}  {rel}")
            for w in why:
                print(f"    {w}")
        refused = sum(1 for _r, ok, _w in report if not ok)
        print(_("· {files} file(s) touched; {refused} refused").format(files=len(report), refused=refused))
        return 1 if refused else 0
    rows = plan(prof, graphs, args.root) + [(rel, None, None, "fora", None, f"grafo que não parseia ({code})")
                                            for rel, code in broken]
    if args.out:
        try:
            with open(args.out, "w", encoding="utf-8", newline="") as fh:
                w = csv.writer(fh, delimiter="\t", lineterminator="\n")
                w.writerow(["arquivo", "id", "regra", "ação", "proposta", "revisar", "supports"])
                sup = {(g.rel, i): len(v) for g in graphs for i, v in g.supports.items()}
                for f, i, r, a, prop, why in rows:
                    w.writerow([f, i, r, a, json.dumps(prop, ensure_ascii=False) if prop else "", why or "",
                                sup.get((f, i), 0)])
        except OSError as exc:  # o --out num lugar que não se grava é entrada quebrada, não traceback
            return broken_input(args, exc)
    counts = collections.Counter((r[2] or "(nenhuma)", r[3]) for r in rows)
    review = [r for r in rows if r[5]]
    if args.json:
        print(json.dumps({"rows": [dict(zip(("file", "id", "rule", "action", "proposal", "review"), r)) for r in rows],
                          "counts": {f"{k[0]} → {k[1]}": v for k, v in sorted(counts.items())}}, ensure_ascii=False))
        return 0
    for (rule, action), v in sorted(counts.items()):
        # "(nenhuma)" é a chave das contagens no --json (dado); na linha impressa, a pessoa lê a tradução
        print(f"  {v:5d}  {_('(no rule)') if rule == '(nenhuma)' else rule} → {action}")
    same = sum(1 for r in rows if r[3] == "same")
    print(_("· {rows} node row(s) in the plan; {same} already equal (same); {review} for the reviewer; "
            "{broken} graph(s) left out (do not parse); nothing was written (plan)").format(
        rows=sum(1 for r in rows if r[1] is not None) - same, same=same, review=len(review), broken=len(broken)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
