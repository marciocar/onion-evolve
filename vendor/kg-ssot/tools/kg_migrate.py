#!/usr/bin/env python3
"""O migrador oficial do KG-SSOT: propõe a provenance que o contrato pede, pelo perfil declarado do adotante.

  kg_migrate.py plan  --profile PERFIL.yaml [--root DIR] [--exclude GLOB] [--no-default-excludes] [--json] [--out PLANILHA.tsv] [grafo.kg.yaml ...]
  kg_migrate.py apply --profile PERFIL.yaml [--root DIR] [--exclude GLOB] [--no-default-excludes] [grafo.kg.yaml ...]

O perfil (spec/kg-migrate-profile.schema.json) declara regras em ordem: a primeira cujo when casa decide a ação do nó
(propor provenance, rebaixar para unverifiable, ou só listar para quem revisa), e o bloco scopes dá verified_scope por
lista de ids. O universo é fixo: nó com status confirmed ou plane PROD, sem provenance, fora o unverifiable. Sem
grafos na linha de comando, a ferramenta lê os .kg.yaml rastreados de --root (default: o diretório atual), fora os
padrões do kg_gate.py (*/fixtures/*, docs/materials/*), o vendor/* e os globs de --exclude, com a semântica do gate
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
import kg_validate  # noqa: E402

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
        raise Broken(f"perfil ilegível: {path}: {exc}")
    schema = json.loads(PROFILE_SCHEMA.read_text(encoding="utf-8"))
    errors = sorted(jsonschema.Draft202012Validator(schema, format_checker=jsonschema.FormatChecker()).iter_errors(prof),
                    key=lambda e: list(e.absolute_path))
    if errors:
        e = errors[0]
        raise Broken(f"perfil fora do schema em {'/'.join(map(str, e.absolute_path)) or 'raiz'}: {e.message}")
    ids = [r["id"] for r in prof["rules"]] + [s["id"] for s in prof.get("scopes", [])]
    dup = sorted({i for i in ids if ids.count(i) > 1})
    if dup:
        raise Broken(f"id de regra repetido no perfil: {', '.join(dup)}")
    scoped = [i for s in prof.get("scopes", []) for i in s["id_in"]]
    twice = sorted({i for i in scoped if scoped.count(i) > 1})
    if twice:
        raise Broken(f"nó em dois scopes: {', '.join(twice)}")
    for r in prof["rules"]:
        p = r["then"].get("provenance")
        for t in ([p["source"], p["locator"], p["method"]["detail"]] if p else []):
            for m in MARKER_RE.finditer(t):
                bad = [x for x in m.group(1).split("|") if x not in MARKERS]
                if bad:
                    raise Broken(f"marcador desconhecido na regra {r['id']}: {{{m.group(1)}}}")
    version = tuple(int(x) for x in prof["contract"].removeprefix("kg-ssot-v").split("."))
    uses_new = prof.get("scopes") or any(r["then"].get("provenance", {}).get("locality") == "privado" for r in prof["rules"])
    if uses_new and version < SCOPE_SINCE:
        raise Broken(f"o perfil usa locality privado ou verified_scope, que só existem desde a kg-ssot-v4.12.0 "
                     f"(o perfil declara {prof['contract']})")
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
        raise Broken("um when do perfil só tem match_case, e casaria todo nó: diga o que ele casa")
    for pattern in [x for w in whens for x in patterns(w)]:
        if pattern is not None:
            try:
                re.compile(pattern)
            except re.error as exc:
                raise Broken(f"expressão regular inválida no perfil: {pattern!r}: {exc}")
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
    path, _, line = first.partition(":")
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
        path, _ = trace_parts(trace)
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
            refused.append((nid, "o nó não foi achado no texto"))
            continue
        item, col, after, pairs = span
        if item.flow_style:
            refused.append((nid, "nó em estilo flow ({...}): edite à mão"))
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
                refused.append((nid, "status fora da forma de uma linha"))
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
    _, old_doc, c1 = kg_validate.parse_v1(old_text)
    _, new_doc, c2 = kg_validate.parse_v1(new_text)
    if c2 is not None and c1 is None:
        return f"o texto editado não parseia ({c2})"
    if not isinstance(new_doc, dict) or not isinstance(old_doc, dict):
        return None if c1 else "o texto editado não é um mapa"
    for key in set(old_doc) | set(new_doc):
        if key != "nodes" and old_doc.get(key) != new_doc.get(key):
            return f"o campo {key} do topo mudou"
    old_nodes, new_nodes = old_doc.get("nodes") or [], new_doc.get("nodes") or []
    if len(old_nodes) != len(new_nodes):
        return "o número de nós mudou"
    for a, b in zip(old_nodes, new_nodes):
        allowed = applied.get(a.get("id") if isinstance(a, dict) else None, {})
        if not isinstance(a, dict) or not isinstance(b, dict):
            if a != b:
                return "um item de nodes mudou"
            continue
        want = dict(a)
        want.update(allowed)
        if b != want:
            return f"o nó {a.get('id')} mudou além do que a ação autoriza"
    import difflib
    status_lines = {i for i, l in enumerate(old_text.splitlines()) if re.match(r"\s*status:", l)}
    for tag, i1, i2, _, _ in difflib.SequenceMatcher(a=old_text.splitlines(), b=new_text.splitlines(), autojunk=False).get_opcodes():
        if tag == "delete" or (tag == "replace" and not set(range(i1, i2)) <= status_lines):
            return "o diff de texto tirou ou trocou uma linha que não é a do status rebaixado"
    return None


def apply(prof, graphs, root, files):
    """Aplica as propostas do plan, arquivo por arquivo. Devolve [(arquivo, gravado?, [motivos])]."""
    rows = plan(prof, graphs, root)
    by_file = collections.defaultdict(list)
    lit = collections.defaultdict(collections.Counter)
    for f, nid, _, action, prop, _ in rows:
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
            report.append((rel, False, ["quebras de linha misturadas (\\r\\n com \\n ou \\r sozinho): normalize antes"]))
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
                problem = "o arquivo ganharia código MUST novo: " + ", ".join(sorted(after - before))
        if problem is None:
            grown = (kg_validate.warning_counts(new, must, should) - kg_validate.warning_counts(old, must, should)) - lit[rel]
            if grown:
                problem = "o arquivo ganharia aviso SHOULD que o plan não anunciou: " + ", ".join(sorted(grown))
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


def load_graphs(files, root, lenient=False):
    """Os grafos lidos. Com lenient (a lista veio do git), o grafo que não parseia volta à parte, para quem revisa."""
    out, broken = [], []
    for f in files:
        p = pathlib.Path(f)
        try:
            text = p.read_text(encoding="utf-8")
        except (OSError, UnicodeDecodeError) as exc:
            if not lenient:
                raise Broken(f"grafo ilegível: {f}: {exc}")
            broken.append((os.fsdecode(f), f"ilegível: {type(exc).__name__}"))
            continue
        _, doc, code = kg_validate.parse_v1(text)
        try:
            rel = p.resolve().relative_to(pathlib.Path(root).resolve()).as_posix()
        except ValueError:
            rel = p.as_posix()
        if code or not isinstance(doc, dict):
            if not lenient:
                raise Broken(f"grafo que não parseia ({code}): {f}")
            broken.append((rel, code or "parse.not-a-map"))
            continue
        out.append((Graph(rel, doc), f))
    return [g for g, _ in out], [f for _, f in out], broken


DEFAULT_EXCLUDE = ["vendor/*", "*/fixtures/*", "docs/materials/*"]  # os do kg_gate.py, e o vendor


def tracked_graphs(root, exclude=(), defaults=True):
    """Os .kg.yaml rastreados pelo git, fora os que casam algum glob, com a semântica do kg_gate.py: fnmatch sobre o
    caminho relativo, em que * atravessa /. Os padrões são os do gate (as fixtures são quebradas de propósito) e o
    vendor/*. O dialeto do perfil (**/ casa zero pastas) também vale, como antes da 4.13.1."""
    r = subprocess.run(["git", "-C", str(root), "ls-files", "-z", "--", "*.kg.yaml"], capture_output=True)
    if r.returncode != 0:
        raise Broken(f"{root} não é um repositório git, e nenhum grafo foi dado")
    globs = (DEFAULT_EXCLUDE if defaults else []) + list(exclude)
    globs = [g[2:] if g.startswith("./") else g for g in globs]
    names = r.stdout.decode("utf-8", "surrogateescape").split("\0")
    # a união: o fnmatch do gate (* atravessa /) e o dialeto de antes (**/ casa zero pastas), para quem já excluía
    # com ** não ver o apply gravar no que antes ficava de fora
    return [str(pathlib.Path(root) / n) for n in names
            if n and not any(fnmatch.fnmatchcase(n, g) or glob_match(n, g) for g in globs)]


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    p = sub.add_parser("plan", help="propõe sem escrever nada")
    p.add_argument("--profile", required=True)
    p.add_argument("--root", default=".")
    p.add_argument("--json", action="store_true")
    p.add_argument("--out", help="grava a planilha de propostas em TSV")
    p.add_argument("--exclude", action="append", default=[],
                   help="glob a mais para deixar de fora da lista do git (fnmatch: * atravessa /, como no kg_gate.py)")
    p.add_argument("--no-default-excludes", action="store_true",
                   help="não aplica os padrões: " + ", ".join(DEFAULT_EXCLUDE))
    p.add_argument("graphs", nargs="*")
    a = sub.add_parser("apply", help="grava as propostas, com invariância e gate por arquivo")
    a.add_argument("--profile", required=True)
    a.add_argument("--root", default=".")
    a.add_argument("--exclude", action="append", default=[],
                   help="glob a mais para deixar de fora da lista do git (fnmatch: * atravessa /, como no kg_gate.py)")
    a.add_argument("--no-default-excludes", action="store_true",
                   help="não aplica os padrões: " + ", ".join(DEFAULT_EXCLUDE))
    a.add_argument("graphs", nargs="*")
    args = ap.parse_args(argv)
    try:
        prof = load_profile(args.profile)
        files = args.graphs or tracked_graphs(args.root, args.exclude, not args.no_default_excludes)
        graphs, files, broken = load_graphs(files, args.root, lenient=not args.graphs)
    except Broken as exc:
        print(f"ENTRADA QUEBRADA  {exc}")
        return 2
    if args.cmd == "apply":
        report = apply(prof, graphs, args.root, files)
        for rel, code in broken:
            print(f"REVISAR   {rel}\n    grafo que não parseia ({code}): ficou de fora")
        for rel, ok, why in report:
            print(f"{'GRAVADO ' if ok else 'RECUSADO' if not why or not all(': ' in w for w in why) else 'REVISAR '}  {rel}")
            for w in why:
                print(f"    {w}")
        refused = sum(1 for _, ok, _ in report if not ok)
        print(f"· {len(report)} arquivos tocados; {refused} recusados")
        return 1 if refused else 0
    rows = plan(prof, graphs, args.root) + [(rel, None, None, "fora", None, f"grafo que não parseia ({code})")
                                            for rel, code in broken]
    if args.out:
        with open(args.out, "w", encoding="utf-8", newline="") as fh:
            w = csv.writer(fh, delimiter="\t", lineterminator="\n")
            w.writerow(["arquivo", "id", "regra", "ação", "proposta", "revisar", "supports"])
            sup = {(g.rel, i): len(v) for g in graphs for i, v in g.supports.items()}
            for f, i, r, a, prop, why in rows:
                w.writerow([f, i, r, a, json.dumps(prop, ensure_ascii=False) if prop else "", why or "", sup.get((f, i), 0)])
    counts = collections.Counter((r[2] or "(nenhuma)", r[3]) for r in rows)
    review = [r for r in rows if r[5]]
    if args.json:
        print(json.dumps({"rows": [dict(zip(("file", "id", "rule", "action", "proposal", "review"), r)) for r in rows],
                          "counts": {f"{k[0]} → {k[1]}": v for k, v in sorted(counts.items())}}, ensure_ascii=False))
        return 0
    for (rule, action), v in sorted(counts.items()):
        print(f"  {v:5d}  {rule} → {action}")
    same = sum(1 for r in rows if r[3] == "same")
    print(f"· {sum(1 for r in rows if r[1] is not None) - same} linhas de nó no plano; {same} já iguais (same); "
          f"{len(review)} para quem revisa; "
          f"{len(broken)} grafos fora (não parseiam); nada foi escrito (plan)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
