#!/usr/bin/env python3
"""As citações entre repositórios (release 4.44.0): quem cita um nó, e o que mudou no que se cita. É consulta, sem alarme.

Lê uma lista DECLARADA de repositórios locais (--repo NOME=PASTA, repetível, ou --repos ARQUIVO), só pelos objetos do
git: a ponta de cada pasta (o HEAD, ou o commit do --at), sem rede e sem tocar a árvore de trabalho. Nenhum nome de
repositório, dono ou apelido mora aqui: um apelido é mais um NOME para a mesma pasta, e --known NOME declara a rede, com
pasta ou sem. Os grafos seguem as regras de arquivo do kg_query, e só os campos de nó são lidos.

  cited-by REPO:ID  quem cita o nó, em que campo e em que forma: a citação explícita, a aresta, a menção pelo id, e quem
                    cita o arquivo inteiro que contém o nó, com a certeza de cada uma
  pins              cada citação a outro repositório da lista, no commit fixado contra a ponta: same, changed (com as
                    classes e o status atual do citado), gone, ambiguous, ou unchecked (com o motivo). --from REPO e
                    --status gone,changed só recortam o que se lista. A mudança nunca altera o rc, e não vai haver opção

As formas lidas: a URL <host>/<dono>/<repo>/(blob|raw|tree|commit)/<commit>[/<caminho>][#id],
[<dono>/]<repo>@<sha>[:<caminho>][#id], <repo>:<caminho>@<sha>[#id], <repo>#<id>@<commit> (o id é procurado nos grafos
daquele commit, e dois nós dão ambiguous, nunca um palpite), e o provenance.source com o locator e o node_sha256. O id ou o
caminho que só aparece na prosa ao lado da citação fica marcado inferred. A citação sem commit é contada em unpinned.

A cobertura é a regra central, porque vazio não prova ausência: toda saída traz scanned e not_scanned, com o motivo. Fora da
lista, nome@sha sem caminho e sem id só conta com dono ou hífen: 53@sha e origin/main@sha são só texto. O nome de fora entra
em not_scanned; com --known, só a lista e os conhecidos contam no rc, e o resto vai a mentioned_undeclared, com a citação
exata em outside_citations; --ignore NOME (aceita glob) o tira. Acha citação errada, não citação que falta; e nada de um
terceiro sem acesso às pastas.

Uso:
  kg_refs.py (cited-by REPO:ID | pins) --repo NOME=PASTA... [--repos ARQUIVO] [--at NOME=COMMIT]... [--known NOME]...
             [--ignore NOME]... [--exclude GLOB]... [--no-default-excludes] [--from REPO] [--status LISTA]
             [--format human|json]
Saída humana, ou JSON no formato kg-ssot.refs/1 (spec/refs.schema.json).
rc: 0 a varredura da lista foi completa, e todo citado foi conferido · 2 erro de uso (sem lista, inclusive) · 3 parcial:
algo da lista ausente ou ilegível, nenhum grafo lido onde era preciso, commit fixado ausente em qualquer forma, conhecido sem
pasta, ou nome citado fora da lista · 4 só em pins, sem nada parcial: alguma citação saiu ambiguous ou unchecked.
"""
import argparse
import collections
import fnmatch
import functools
import json
import pathlib
import posixpath
import re
import sys

sys.dont_write_bytecode = True
if __package__:  # no pacote kg_ssot, o vizinho vem pelo pacote, sem mexer no sys.path de quem importa
    from . import kg_diff, kg_i18n, kg_query, kg_trace, kg_validate
else:  # script ou vendor
    sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
    import kg_diff  # noqa: E402
    import kg_i18n  # noqa: E402
    import kg_query  # noqa: E402
    import kg_trace  # noqa: E402
    import kg_validate  # noqa: E402
_ = kg_i18n._

SCHEMA_VERSION = "kg-ssot.refs/1"
OBJECTS_MISSING = "(git grep)"  # no lugar de um caminho: os objetos do commit faltam, e não se sabe qual grafo escreve o id
# o que olhar primeiro: o que sumiu e o status que mudou; depois, o que não se conferiu; e o resto, sem esconder nada
LOOK_FIRST = (("gone", None), ("changed", "status"), ("unchecked", None), ("ambiguous", None), ("changed", "text"),
              ("changed", "edges"), ("changed", "other"), ("changed", "file"), ("changed", "stamp_only"), ("same", None))
STATUSES = tuple(dict.fromkeys(status for status, _class in LOOK_FIRST))
# o carimbo da verificação no contrato: mudar só isso não muda o que o nó afirma
STAMP_FIELDS = ("verified_at", "verified_against", "verified_scope", "reverify_every", "reverify_on")
# o dono de origin/main é o nome de um remoto do git, não um dono: é um ref, não um repositório
REMOTE_WORDS = ("origin", "upstream")
SHA = kg_query.COMMIT_REF.pattern + r"(?![\w-]|\.\w)"
FRAGMENT = r"(?:#(?P<anchor>[\w.-]+))?"
# a âncora antes do host corta o custo quadrático: sem ela, uma linha longa de a.a.a. recomeça em cada ponto
URL = re.compile(r"(?<![\w.-])" + kg_trace.REF_HOST + r"(?P<owner>[\w.-]+)/(?P<name>[\w.-]+)/(?:-/)?"
                 r"(?:blob|raw|tree|commit)/(?P<commit>[\w.-]+)(?:/(?P<path>[^\s#?\"'<>()\[\],;`«»]*))?" + FRAGMENT)
RAW = re.compile(r"(?<![\w.-])(?:https?://)?raw\.[\w.-]+/(?P<owner>[\w.-]+)/(?P<name>[\w.-]+)/(?:refs/heads/)?"
                 r"(?P<commit>[\w.-]+)/(?P<path>[^\s#?\"'<>()\[\],;`«»]+)" + FRAGMENT)
BARE = re.compile(r"(?<![\w./@:#-])(?:" + kg_trace.REF_HOST + r")?(?:(?P<owner>[\w.-]+)/)?(?P<name>[A-Za-z0-9][\w.-]*)"
                  r"(?:@(?P<commit>" + SHA + r")(?::(?P<path>[\w./+-]+))?|:(?P<path2>[\w.+-]+(?:/[\w.+-]*)*)"
                  r"(?:@(?P<commit2>" + SHA + r"))?)" + FRAGMENT)
ID_TOKEN = re.compile(r"(?<![\w-])[A-Z][A-Z0-9]*_[A-Z0-9_]{2,}(?![\w-])")
ID_GREP = "[A-Z][A-Z0-9]*_[A-Z0-9_]{2,}"  # a forma do ID_TOKEN no git grep, que só poupa processo: quem decide é o documento
PATH_TOKEN = re.compile(r"(?<![\w./@:-])(?:[\w.+-]+/)+[\w+-][\w.+-]*\.[A-Za-z]\w{0,5}(?![\w/])")
FILE_NAME = re.compile(r"\.[A-Za-z]\w{0,5}$")


def _grep_failed(out):
    """O git grep não leu tudo: rc fora de 0 e 1, ou uma linha error: ou fatal: no stderr (o blob ausente dá error: e segue; a
    árvore ausente, fatal:). O warning: de permissão e o rastro do GIT_TRACE não são falha."""
    return out.returncode not in (0, 1) or any(line.startswith((b"error:", b"fatal:")) for line in out.stderr.splitlines())


class Broken(Exception):
    """Erro de uso: rc 2."""


class Repo:
    """Um repositório da lista: a ponta lida (HEAD, ou o --at), o corpus dela e a leitura de qualquer commit."""

    def __init__(self, folder, at, exclude, defaults):
        self.folder = folder
        self.at = at
        self.reason = None  # por que não se lê; None é o repositório lido
        self.tip = None
        self.corpus = None
        self.tree = {}  # caminho -> objeto, de todo arquivo da ponta
        self.exclude = (kg_query.DEFAULT_EXCLUDE if defaults else ()) + tuple(exclude)
        self.vendors = ()
        self.shallow = False
        self.index = {}  # id -> os arquivos da ponta com ele
        if pathlib.Path(folder).is_dir():
            self._open(defaults)
        else:
            self.reason = "folder_missing"

    def _open(self, defaults):
        top = self.git("rev-parse", "--show-toplevel")
        bare = self.git("rev-parse", "--is-bare-repository")
        root = top.stdout.decode("utf-8", "surrogateescape").rstrip("\n")
        # a subpasta de outro clone não vale: o git subiria até ele
        if not (top.returncode == 0 and pathlib.Path(root).resolve() == pathlib.Path(self.folder).resolve()) \
                and not (bare.returncode == 0 and bare.stdout.strip() == b"true"):
            self.reason = "not_git"
            return
        self.shallow = self.git("rev-parse", "--is-shallow-repository").stdout.strip() == b"true"
        self.tip = self.commit(self.at or "HEAD", exact=False)
        if self.tip is None:
            self.reason = "at_commit_missing" if self.at else "no_commit"
            return
        try:
            self.tree = kg_query.commit_listing(self.folder, self.tip)
        except ValueError:  # a árvore do commit não se lê: é este repositório que fica de fora, não a varredura
            self.reason = "commit_unreadable"
            return
        self.vendors = kg_validate.vendor_dirs(list(self.tree)) if defaults else ()
        self.corpus = kg_query.load_commit(self.folder, self.tree, self.exclude, self.vendors)
        for key in self.corpus.order:
            self.index.setdefault(key[1], []).append(key[0])

    def git(self, *args):
        return kg_query._git(self.folder, *args, offline=True)

    def graphless(self):
        return not self.corpus.files and not self.corpus.unreadable

    @functools.cache
    def commit(self, ref, exact=True):
        """O commit inteiro de ref, ou None. Com exact, ref tem de fixá-lo (kg_query.commit_fixes)."""
        full = kg_query.commit_of(self.folder, ref, offline=True)
        return full if full and (not exact or kg_query.commit_fixes(full, ref)) else None

    def entry(self, rev, path):
        """(tipo, oid) do caminho naquele commit, ou None."""
        out = self.git("ls-tree", "-z", "--end-of-options", rev, "--", path.rstrip("/")).stdout
        fields = out.decode("utf-8", "surrogateescape").split("\t", 1)[0].split()
        return (fields[1], fields[2]) if len(fields) >= 3 else None

    @functools.cache
    def doc(self, path, oid):
        """(documento, código) do grafo no objeto oid, com o parse do kg_diff; só o que se cita se lê, e uma vez."""
        text, code = kg_diff.decode(self.git("show", "--end-of-options", oid).stdout)
        return (None, code) if code else kg_diff.parse(path, text)

    @functools.cache
    def mentions(self, rev, nid):
        """([(caminho, documento)], [caminho ilegível]) dos grafos daquele commit que escrevem o id, pelas regras de arquivo:
        o git grep poupa o parse dos outros, e o mesmo objeto se lê uma vez."""
        out = self.git("grep", "-l", "-z", "-w", "-F", "-e", nid, rev, "--",
                       *(f"*{x}" for x in kg_query.GRAPH_SUFFIXES))
        # com o git grep falho, não dá para saber quem mais escreve o id
        docs, bad = [], [OBJECTS_MISSING] if _grep_failed(out) else []
        for name in filter(None, out.stdout.decode("utf-8", "surrogateescape").split("\0")):
            path = name.split(":", 1)[1]
            if not kg_query.file_kept(path, self.exclude, self.vendors):
                continue
            entry = self.entry(rev, path)
            doc, code = self.doc(path, entry[1]) if entry else (None, "io.missing")
            if code:
                bad.append(path)
            else:
                docs.append((path, doc))
        return docs, bad

    def find(self, rev, nid):
        """([(caminho, documento)], [caminho ilegível]) das ocorrências do id nos grafos daquele commit: quem decide é o
        documento, e o id repetido no mesmo grafo também é ambíguo."""
        docs, bad = self.mentions(rev, nid)
        return [(path, doc) for path, doc in docs for _copy in kg_diff.nodes(doc).get(nid, [])], bad

    def moved(self, oid):
        """O caminho da ponta com o mesmo objeto, ou None: o arquivo renomeado segue igual."""
        return next((path for path, blob in self.tree.items() if blob == oid), None)

    @functools.cache
    def tokens(self, rev):
        """Os ids escritos nos grafos daquele commit, num processo só: mil ids na prosa não viram mil buscas. None: o git grep
        falhou, e não se sabe quais ids estão lá."""
        out = self.git("grep", "-h", "-o", "-E", ID_GREP, rev, "--", *(f"*{x}" for x in kg_query.GRAPH_SUFFIXES))
        return None if _grep_failed(out) else set(out.stdout.decode("utf-8", "surrogateescape").split())

    def _is_ancestor(self, older, newer):
        return self.git("merge-base", "--is-ancestor", older, newer).returncode == 0

    @functools.cache
    def relation(self, full):
        """Como o commit fixado se liga à ponta: on_history, ahead (a ponta está atrás dele: o clone está defasado) ou
        apart (fora do histórico da ponta, como o commit reescrito por rebase)."""
        return "on_history" if self._is_ancestor(full, self.tip) else "ahead" if self._is_ancestor(self.tip, full) else "apart"


def _repo_shaped(owner, name, commit):
    """O nome@sha de fora da lista, sem caminho e sem id, tem forma de repositório? Com dono (que não começa por ponto nem é
    um remoto) ou com hífen, sem nome de arquivo ou de commit e sem commit só de dígitos. Com caminho ou id, ele é repositório
    sem precisar disto, em qualquer nome."""
    if commit.isdigit() or FILE_NAME.search(name) or kg_query.COMMIT_REF.fullmatch(name):
        return False
    return owner[0].isalnum() and owner not in REMOTE_WORDS if owner else "-" in name


def _spelled(owner, name, pool):
    """O nome de pool que essa citação escreve, com o dono ou sem ele, ou None."""
    return next((n for n in (f"{owner}/{name}" if owner else name, name) if n in pool), None)


def _url_parts(m):
    return m["owner"], m["name"], m["commit"], m["path"], m["anchor"], "url"


def _ref_parts(m):
    return m["owner"], m["name"], m["commit"], None, m["id"], "repo_id_commit"


def _bare_parts(m):
    commit, path = m["commit"] or m["commit2"], m["path"] or m["path2"]
    if not commit and not (path and ("/" in path or FILE_NAME.search(path))):
        return None
    form = "repo_path_sha" if m["commit2"] else "owner_repo_sha" if m["owner"] else "repo_sha"
    return m["owner"], m["name"], commit, path, m["anchor"], form if commit else "repo_path"


def citations(text, scan, has_locator=False):
    """As citações de um texto, de qualquer repositório: [{repo, name, known, commit, path, id, form, text}]. repo é o nome
    declarado na lista, ou None; known, o conhecido sem pasta. O que já casou numa forma é mascarado, para não casar de novo
    em outra. commit None é a citação sem commit; ela só conta quando o repositório está na lista. has_locator: o texto é o
    source de um locator, que diz o alvo."""
    if "@" not in text and "/" not in text and ":" not in text:
        return []
    out = []

    def add(m, read):
        found = read(m)
        if found is None:
            return m.group(0)
        owner, name, commit, path, anchor, form = found
        declared, known = _spelled(owner, name, scan.names), _spelled(owner, name, scan.known)
        pinned = commit if commit and kg_query.COMMIT_REF.fullmatch(commit) else None
        # o filtro de nome falso, só para quem está fora da lista
        if declared or known or (pinned and (path or anchor or has_locator or _repo_shaped(owner, name, commit))):
            path = (path or "").rstrip(".,;:)") or None
            path = posixpath.normpath(path) if path else None  # ./g.kg.json e sub/../g.kg.json são o g.kg.json
            anchor = (anchor or "").rstrip(".-") or None  # o ponto final da frase não é parte do id
            graph = path is None or path.endswith(kg_query.GRAPH_SUFFIXES)  # num arquivo comum, o # é uma seção, não um nó
            out.append({"repo": declared, "name": f"{owner}/{name}" if owner else name, "known": known, "commit": pinned,
                        "path": path, "id": anchor if anchor and graph else None,
                        "id_source": "anchor" if anchor and graph else None, "form": form, "text": m.group(0)})
        return " " * len(m.group(0))
    masked = text
    for rx, read in ((URL, _url_parts), (RAW, _url_parts), (kg_trace.REF_FORM, _ref_parts), (BARE, _bare_parts)):
        masked = rx.sub(lambda m, read=read: add(m, read), masked)
    return out


def _leaves(value, path=()):
    """(campo, texto) de cada texto sob value: a lista não entra no nome do campo."""
    if isinstance(value, dict):
        for k, v in value.items():
            yield from _leaves(v, path + (str(k),))
    elif isinstance(value, list):
        for v in value:
            yield from _leaves(v, path)
    elif isinstance(value, str):
        yield ".".join(path), value


def _texts(repo):
    """(chave, nó, campo, texto) de todo campo de nó do corpus; o id é a identidade, não uma citação."""
    for key in repo.corpus.order:
        node = repo.corpus.nodes[key]
        for field, text in _leaves({k: v for k, v in node.items() if k != "id"}):
            yield key, node, field, text


class Scan:
    """A lista declarada: nome -> repositório (dois nomes podem dar na mesma pasta), os conhecidos sem pasta e a cobertura
    que se acumula."""

    def __init__(self, repos, ignore, known):
        self.names = repos
        self.ignore = set(ignore)
        self.network = bool(known)  # o --known declara a rede: só ela conta no rc
        # quem tem pasta na lista já está coberto, com o dono escrito ou não
        self.known = {k for k in known if k not in repos and k.rsplit("/", 1)[-1] not in repos}
        self.repos = list({id(r): r for r in repos.values()}.values())
        self.absent = {}
        self.ignored = collections.Counter()
        self.mentioned = collections.Counter()
        self.outside = []  # com --known, as citações exatas de quem está fora da rede
        self.needed = set()  # quem precisa ter grafo: o alvo do cited-by, e o citado por um nó no pins

    def name_of(self, repo):
        return next(n for n, r in self.names.items() if r is repo)

    def readable(self):
        return [r for r in self.repos if not r.reason]

    def note(self, repo, reason, **extra):
        self.absent.setdefault((repo, reason, extra.get("commit"), extra.get("file")),
                               {"repo": repo, "reason": reason, **extra})

    def _count(self, repo, reason):
        entry = self.absent.setdefault((repo, reason, None, None), {"repo": repo, "reason": reason})
        entry["citations"] = entry.get("citations", 0) + 1

    def undeclared(self, cit, citer, field, locator=None):
        """O nome citado fora da lista. Devolve se ele conta no rc: o conhecido conta; o --ignore tira; com --known, só a
        lista e os conhecidos contam, e o resto é só contado; sem ele, entra em not_scanned."""
        if cit["known"]:
            self._count(cit["known"], "known_no_folder")
            return True
        if any(fnmatch.fnmatchcase(cit["name"], pat) or fnmatch.fnmatchcase(cit["name"].rsplit("/", 1)[-1], pat)
               for pat in self.ignore):
            self.ignored[cit["name"]] += 1
            return False
        if self.network:
            self.mentioned[cit["name"]] += 1
            graph = not cit["path"] or cit["path"].endswith(kg_query.GRAPH_SUFFIXES)
            for nid in [cit["id"]] if cit["id"] else _locator_ids(locator) if graph else []:
                self.outside.append({"citer": citer, "field": field, "repo": cit["name"], "id": nid,
                                     "commit": cit["commit"]})
            return False
        self._count(cit["name"], "cited_not_declared")
        return True

    def coverage(self):
        scanned = []
        for r in self.repos:
            name = self.name_of(r)
            if r.reason:
                self.note(name, r.reason, **({"commit": r.at} if r.at else {}))
                continue
            bad = {u["file"] for u in r.corpus.unreadable}
            # zero grafo só é completo num membro comum sem grafo nenhum: não vale se o filtro os tirou, se o --at leu um
            # estado sem eles, nem em quem precisava deles
            if r.graphless() and (r.at or r in self.needed or any(p.endswith(kg_query.GRAPH_SUFFIXES) for p in r.tree)):
                self.note(name, "no_graphs")
                continue
            scanned.append({"repo": name, "folder": r.folder, "commit": r.tip, "graphs": len(set(r.corpus.files) - bad),
                            "nodes": len(r.corpus.order), "shallow": r.shallow})
            for u in r.corpus.unreadable:
                self.note(name, "unreadable_graph", file=u["file"], code=u["code"])
        for name in sorted(self.known):
            self.note(name, "known_no_folder")
        if not any(s["graphs"] for s in scanned) and not any(r.corpus and r.corpus.unreadable for r in self.repos):
            for s in scanned:  # a varredura inteira sem nada lido não responde nada
                self.note(s["repo"], "no_graphs")
            return []
        return scanned

    def missing_commit(self, cit, repo):
        self.note(cit["repo"], "pinned_commit_missing", commit=cit["commit"],
                  detail="shallow" if repo.shallow else "not_in_clone")

    def result(self, command, body, partial_extra=False):
        """O envelope comum, com o rc: a cobertura vence, e a falta de conferência só decide numa varredura completa."""
        scanned = self.coverage()
        not_scanned = sorted(self.absent.values(),
                             key=lambda e: (e["reason"], e["repo"], str(e.get("commit")), str(e.get("file"))))
        rc = 3 if not_scanned else 4 if partial_extra else 0
        return {"schema_version": SCHEMA_VERSION, "command": command, **body, "scanned": scanned,
                "not_scanned": not_scanned, "ignored": dict(sorted(self.ignored.items())),
                "mentioned_undeclared": dict(sorted(self.mentioned.items())), "outside_citations": self.outside, "rc": rc}


def _edges_of(repo, rev, path, nid):
    """As arestas do nó em todo o repositório naquele commit, sem repetir: (de, para, tipo), com as pontas pelo id, para o nó
    movido não acusar mudança. Toca o nó quem aponta para o arquivo dele: o id local, ou <caminho>#<id> de outro grafo. A outra
    ponta fica só pelo id, e um homônimo em outro arquivo passa por igual."""
    out = set()
    for name, doc in repo.mentions(rev, nid)[0]:
        for k in (k for key in ("edges", "external_edges") for k in kg_diff.edges(doc, key)):
            src, dst = kg_query.Corpus._end(name, k[0]), kg_query.Corpus._end(name, k[1])
            if (path, nid) in (src, dst):
                out.add((src[1], dst[1], k[2]))
    return out


def compare(old_doc, new_doc, nid, edges_changed):
    """{status, classes, fields} do nó no commit fixado contra a ponta, e o status atual dele quando mudou. Os campos vêm do
    field_changes do kg_diff: a mudança só de espaço num texto é mudança de texto, nunca carimbo. Sem classe nenhuma, é same."""
    old, new = kg_diff.nodes(old_doc)[nid][0], kg_diff.nodes(new_doc)[nid][0]
    fields = [f["path"] for f in kg_diff.field_changes(old, new)]
    tops = {f.split(".", 1)[0] for f in fields}
    classes = [c for c, hit in (("status", "status" in tops), ("text", bool(tops & {"label", "narrative"})),
                                ("edges", edges_changed),
                                ("other", bool(tops - {"status", "label", "narrative", *STAMP_FIELDS}))) if hit]
    if not classes and fields:
        classes = ["stamp_only"]
    if not classes:
        return {"status": "same", "classes": [], "fields": fields}
    now = new.get("status")
    return {"status": "changed", "classes": classes, "fields": fields,
            "current_status": now if isinstance(now, str) else None}


def _unread(repo, rev, nid, where):
    """O veredito de quem não dá para comparar, ou None: um grafo que escreve o id não se lê, ou faltam objetos no commit."""
    bad = repo.mentions(rev, nid)[1]
    if not bad:
        return None
    kind = "objects_missing" if OBJECTS_MISSING in bad else "graph_unreadable"
    return {"status": "unchecked", "reason": f"{kind}_{where}", "files": bad}


def judge_node(repo, full, cit, want):
    """Um nó citado num commit: o commit primeiro (nele, sem caminho, o id se procura), depois a ponta."""
    path, nid = cit["path"], cit["id"]
    if path:
        entry = repo.entry(full, path)
        if not entry or entry[0] != "blob":
            return {"status": "unchecked", "reason": "path_absent_at_commit"}
        old_doc, code = repo.doc(path, entry[1])
        if code:
            return {"status": "unchecked", "reason": "graph_unreadable_at_commit", "code": code}
        count = len(kg_diff.nodes(old_doc).get(nid, []))
        if count != 1:
            return {"status": "ambiguous", "reason": "many_at_commit"} if count else \
                {"status": "unchecked", "reason": "id_absent_at_commit"}
    else:
        hits = repo.find(full, nid)[0]
        if len(hits) > 1:
            return {"status": "ambiguous", "reason": "many_at_commit", "candidates": sorted({h[0] for h in hits})}
        problem = _unread(repo, full, nid, "at_commit")
        if problem:
            return problem
        if not hits:
            return {"status": "unchecked", "reason": "id_absent_at_commit"}
        path, old_doc = hits[0]
    extra = {"path_at_commit": path}
    if want:
        extra["hash_at_commit"] = "match" if kg_validate.node_digest(old_doc, nid) == want else "mismatch"
        if extra["hash_at_commit"] == "mismatch":
            return {"status": "unchecked", "reason": "hash_mismatch_at_commit", **extra}
    now = path
    entry = repo.entry(repo.tip, path)
    new_doc, code = repo.doc(path, entry[1]) if entry and entry[0] == "blob" else (None, None)
    # sem caminho na citação, ou saiu do caminho: procura na ponta inteira
    if not cit["path"] or new_doc is None or nid not in kg_diff.nodes(new_doc):
        hits = repo.find(repo.tip, nid)[0]
        if len(hits) > 1:
            return {"status": "ambiguous", "reason": "many_at_tip", "candidates": sorted({h[0] for h in hits}), **extra}
        problem = _unread(repo, repo.tip, nid, "at_tip") or (code and {"status": "unchecked", "reason": "graph_unreadable_at_tip"})
        if problem:
            return {**problem, **extra}
        if not hits:
            return {"status": "gone", **extra}
        new_doc, now = hits[0][1], hits[0][0]
        if now != path:
            extra["moved_to"] = now
    elif len(kg_diff.nodes(new_doc)[nid]) > 1:
        return {"status": "ambiguous", "reason": "many_at_tip", **extra}
    if want:
        extra["hash_at_tip"] = "match" if kg_validate.node_digest(new_doc, nid) == want else "mismatch"
    # as arestas vêm do repositório inteiro: quem não se lê em qualquer dos dois commits impede a comparação
    problem = _unread(repo, full, nid, "at_commit") or _unread(repo, repo.tip, nid, "at_tip")
    if problem:
        return {**problem, **extra}
    edges_changed = _edges_of(repo, full, path, nid) != _edges_of(repo, repo.tip, now, nid)
    return {**compare(old_doc, new_doc, nid, edges_changed), **extra}


def judge(repo, cit, want=None):
    """O veredito de uma citação com commit: nunca um same sem prova."""
    if repo.reason:
        return {"status": "unchecked", "reason": "repo_unreadable"}
    full = repo.commit(cit["commit"])
    if full is None:
        return {"status": "unchecked", "reason": "commit_missing"}
    relation = repo.relation(full)
    if relation == "ahead":  # a ponta local é que está atrás: compará-la acusaria na direção errada
        return {"status": "unchecked", "reason": "tip_behind_pin", "relation": relation}
    extra = {"relation": relation}
    if cit["id"] and repo.graphless():  # sem grafo na ponta não há como dizer que o nó sumiu; a citação de arquivo segue
        return {"status": "unchecked", "reason": "no_graphs", **extra}
    if cit["id"]:
        return {**judge_node(repo, full, cit, want), **extra}
    if not cit["path"]:
        return {"status": "unchecked", "reason": "no_target", **extra}
    pinned = repo.entry(full, cit["path"])
    if not pinned:
        return {"status": "unchecked", "reason": "path_absent_at_commit", **extra}
    now = repo.entry(repo.tip, cit["path"])
    if now:
        same = now[1] == pinned[1]
        return {"status": "same" if same else "changed", "classes": [] if same else ["file"], **extra}
    moved = repo.moved(pinned[1])
    if moved:
        return {"status": "same", "classes": [], "moved_to": moved, **extra}
    # fora do histórico e sem grafo nenhum, a ponta pode ser só a branch errada: isso não prova que o arquivo sumiu
    if repo.graphless() and relation != "on_history":
        return {"status": "unchecked", "reason": "no_graphs", **extra}
    return {"status": "gone", **extra}


@functools.cache
def _exists_at(repo, full, path, nid):
    """O id está naquele commit? None: não se sabe, porque a procura sem caminho falhou."""
    if not path:
        return bool(repo.find(full, nid)[0]) or (None if OBJECTS_MISSING in repo.mentions(full, nid)[1] else False)
    entry = repo.entry(full, path)
    doc, code = repo.doc(path, entry[1]) if entry and entry[0] == "blob" else (None, "io.missing")
    return not code and nid in kg_diff.nodes(doc)


def _locator_ids(locator):
    """Os ids que o locator nomeia: ele inteiro, com ou sem #, ou os que estão escritos nele."""
    exact = (locator or "").strip().lstrip("#")
    return [exact] if kg_trace.KG_NODE.fullmatch(exact) else ID_TOKEN.findall(locator or "")


def expand(cit, node_id, text, locator, scan, own):
    """A citação sem id, com o id que está ao lado dela: o locator do provenance.source, ou, marcado inferred, um id no
    mesmo campo que exista no citado naquele commit e não exista em quem cita, onde ele nomearia o nó de lá. Sem caminho nem
    id, um caminho do mesmo campo que exista naquele commit, também inferred: é o único jeito de ver o arquivo que mudou em
    quem cita o commit na frase e o arquivo depois dela."""
    repo = scan.names.get(cit["repo"])
    if cit["id"] or not cit["commit"] or repo is None or repo.reason or \
            (cit["path"] and not cit["path"].endswith(kg_query.GRAPH_SUFFIXES)):
        return [cit]
    full = repo.commit(cit["commit"])
    if full is None:
        return [cit]
    out, seen = [], set()
    for found, tag in ((_locator_ids(locator), "locator"), (ID_TOKEN.findall(text), "inferred")):
        for nid in found:
            known = repo.tokens(full)
            # com a procura falha, o id fica: o veredito diz objects_missing_at_commit, em vez de cair no caminho da prosa
            if nid in seen or nid == node_id or (tag == "inferred" and (nid in own.index or (known is not None
                                                                                          and nid not in known))):
                continue
            seen.add(nid)
            if _exists_at(repo, full, cit["path"], nid) is not False:
                out.append({**cit, "id": nid, "id_source": tag})
    if out or cit["path"]:
        return out or [cit]
    paths = [p for p in dict.fromkeys(PATH_TOKEN.findall(text)) if repo.entry(full, p)]
    return [{**cit, "path": p, "id_source": "inferred"} for p in paths] or [cit]


def _text_of(prov, key):
    return prov.get(key) if isinstance(prov.get(key), str) else None


def _source_locator(node, field):
    """(locator, node_sha256) de quem está no provenance.source; em outro campo, nada."""
    prov = node.get("provenance")
    if field != "provenance.source" or not isinstance(prov, dict):
        return None, None
    return _text_of(prov, "locator"), _text_of(prov, "node_sha256")


def _pin_row(name, key, node, field, cit, verdict):
    return {"citer": _citer(name, key, node), "field": field, "form": cit["form"], "text": cit["text"][:200],
            "cited": {"repo": cit["repo"] or cit["name"], "commit": cit["commit"], "path": cit["path"], "id": cit["id"],
                      "id_source": cit["id_source"]}, **verdict}


def pins(scan, from_repo=None, statuses=None):
    """kg_refs pins: toda citação com commit a outro repositório da lista; o agrupamento só ordena o olhar, e o --from e o
    --status só recortam o que se lista: a varredura, o resumo e o rc são os de toda a lista. O commit ausente também é
    cobertura, e a cobertura vence: dá rc 3, mesmo sendo unchecked."""
    rows, verdicts, unpinned, own_count = [], {}, collections.Counter(), 0
    for repo in scan.readable():
        name = scan.name_of(repo)
        for key, node, field, text in _texts(repo):
            locator, want = _source_locator(node, field)
            for cit in citations(text, scan, bool(locator)):
                if cit["repo"] is None:
                    # sem pasta, a forma sem caminho não se resolve, e o nó que ela nomeia fica dito
                    counted = scan.undeclared(cit, _citer(name, key, node), field, locator)
                    if counted and cit["form"] == "repo_id_commit" and cit["commit"]:
                        rows.append(_pin_row(name, key, node, field, cit, {"status": "unchecked", "reason": "no_access"}))
                    continue
                if scan.names[cit["repo"]] is repo:
                    own_count += 1
                    continue
                if not cit["commit"]:
                    unpinned[cit["repo"]] += 1
                    continue
                target = scan.names[cit["repo"]]
                for c in expand(cit, key[1], text, locator, scan, repo):
                    if c["form"] != "repo_id_commit" and locator and c["id_source"] == "locator":
                        c = {**c, "form": "source_locator"}
                    ck = (cit["repo"], c["commit"], c["path"], c["id"], want if c["id"] else None)
                    if ck not in verdicts:
                        verdicts[ck] = judge(target, c, want if c["id"] else None)
                    verdict = verdicts[ck]
                    if verdict.get("reason") == "commit_missing":
                        scan.missing_commit(c, target)
                    if verdict.get("reason") == "no_graphs":
                        scan.needed.add(target)
                    rows.append(_pin_row(name, key, node, field, c, verdict))
    rows.sort(key=lambda r: (_rank(r), r["cited"]["repo"], str(r["cited"]["id"]), r["citer"]["file"], r["citer"]["id"]))
    groups = collections.Counter((r["status"], c) for r in rows for c in (r.get("classes") or [None]))
    source = scan.name_of(scan.names[from_repo]) if from_repo else None
    shown = [r for r in rows if (not statuses or r["status"] in statuses) and (not source or r["citer"]["repo"] == source)]
    summary = {"citations": len(rows), "shown": len(shown), "unpinned": dict(sorted(unpinned.items())),
               "own_repo_citations": own_count,
               "groups": [{"status": s, "class": c, "citations": groups[(s, c)]}
                          for s, c in sorted(groups, key=LOOK_FIRST.index)]}
    no_proof = any(r["status"] in ("ambiguous", "unchecked") for r in rows)
    return scan.result("pins", {"filter": {"from": from_repo, "status": statuses or None}, "summary": summary,
                                "citations": shown}, partial_extra=no_proof)


def _rank(row):
    return min(LOOK_FIRST.index((row["status"], c)) for c in row.get("classes") or [None])


def _citer(name, key, node):
    status = node.get("status")
    return {"repo": name, "file": key[0], "id": key[1], "status": status if isinstance(status, str) else None}


def cited_by(scan, target):
    """kg_refs cited-by: quem cita o nó, em todo campo de nó da lista, mais as arestas dos grafos do repositório dele. Quem
    aponta para o mesmo id em outro repositório da lista é contado em elsewhere, sem virar citação; quem só traz, ao lado da
    menção, uma citação de outra coisa segue sendo menção. Citar o arquivo inteiro que contém o nó é contains_file: a
    certeza é menor, e o commit ausente pesa igual."""
    repo_name, _sep, nid = target.partition(":")
    home = scan.names[repo_name]
    scan.needed.add(home)
    word = re.compile(r"(?<![\w-])" + re.escape(nid) + r"(?![\w-])")
    found = home.index.get(nid, [])
    hits, elsewhere = {}, collections.Counter()
    for repo in scan.readable():
        name = scan.name_of(repo)
        for key, node, field, text in _texts(repo):
            locator, _want = _source_locator(node, field)
            cits = citations(text, scan, bool(locator))
            for cit in (c for c in cits if c["repo"] is None):
                scan.undeclared(cit, _citer(name, key, node), field, locator)
            mentioned = bool(word.search(text))
            prov = node.get("provenance") if isinstance(node.get("provenance"), dict) else {}
            if field == "provenance.locator" and mentioned and _text_of(prov, "source"):
                cits = citations(prov["source"], scan, True)
            homes = [c for c in cits if c["repo"] and scan.names[c["repo"]] is home]
            here = [c for c in homes if c["id"] == nid or (c["id"] is None and mentioned)]
            # o locator que nomeia um id de lá cita aquele nó, não o arquivo inteiro; a palavra livre não bloqueia nada
            whole = [] if any(i in home.index for i in _locator_ids(locator)) else \
                [c for c in homes if c["id"] is None and c["path"] in found]
            there = [c for c in cits if c["repo"] and scan.names[c["repo"]] is not home and c["id"] == nid]
            if (not mentioned and not here and not whole) or (key[1] == nid and repo is home):
                continue
            for c in here + whole:
                if c["commit"] and home.reason is None and home.commit(c["commit"]) is None:
                    scan.missing_commit(c, home)
            if here:
                c = next((x for x in here if x["id"] == nid), here[0])
                form, certainty, commit = c["form"], "explicit", c["commit"]
            elif there:
                elsewhere[there[0]["repo"]] += 1
                continue
            elif whole:
                form, certainty, commit = whole[0]["form"], "contains_file", whole[0]["commit"]
            else:
                form, commit = "mention", None
                certainty = "same_repo" if repo is home else "local_homonym" if nid in repo.index else "by_id"
            at = word.search(text)
            start = max(0, at.start() - 60) if at else 0
            hits[(name, key, field, form)] = {"citer": _citer(name, key, node), "field": field, "form": form,
                                              "certainty": certainty, "commit": commit, "text": text[start:start + 160]}
    for path in found:
        for et, src, _ref in home.corpus.into.get((path, nid), ()):
            if kg_query._real(src) and src in home.corpus.nodes and src[1] != nid:
                form = "edge" if src[0] == path else "external_edge"
                hits[(repo_name, src, str(et), form)] = {
                    "citer": _citer(repo_name, src, home.corpus.nodes[src]), "field": str(et), "form": form,
                    "certainty": "explicit", "commit": None, "text": ""}
    rows = sorted(hits.values(), key=lambda h: (h["citer"]["repo"], h["citer"]["file"], h["citer"]["id"], h["field"]))
    citing = {(h["citer"]["repo"], h["citer"]["file"], h["citer"]["id"]) for h in rows}
    summary = {"citations": len(rows), "citing_nodes": len(citing), "elsewhere": dict(sorted(elsewhere.items()))}
    return scan.result("cited-by", {"target": {"repo": repo_name, "id": nid, "found_in": found}, "summary": summary,
                                    "citations": rows})


# o texto humano se traduz na hora (o status do JSON fica em inglês)
STATUS_WORD = {"same": lambda: _("same"), "changed": lambda: _("changed"), "gone": lambda: _("gone"),
               "ambiguous": lambda: _("ambiguous"), "unchecked": lambda: _("unchecked")}


def _tally(counts):
    return ", ".join(f"{k} ({v})" for k, v in counts.items())


def _failed(res):
    """O bloco do que a lista declarou e falhou, no alto: é o que torna a resposta parcial."""
    lines = []
    for e in res["not_scanned"]:
        if e["reason"] != "cited_not_declared":
            what = ", ".join(str(e[k]) for k in ("commit", "file", "citations") if k in e)
            lines.append(_("NOT SCANNED  {repo}: {reason}").format(repo=e["repo"], reason=e["reason"])
                         + (f" ({what})" if what else ""))
    return lines


def _coverage(res):
    """As linhas da cobertura, no fim. Os nomes de fora são uma linha com a contagem; eles estão no JSON."""
    lines = ["· " + _("scanned {repo} at {commit}: {graphs} graph(s), {nodes} node(s)").format(
        repo=s["repo"], commit=s["commit"][:12], graphs=s["graphs"], nodes=s["nodes"]) for s in res["scanned"]]
    outside = {e["repo"]: e["citations"] for e in res["not_scanned"] if e["reason"] == "cited_not_declared"}
    if outside:
        lines.append("· " + _("{names} name(s) cited with a commit and not in the list, in {n} citation(s): --known or "
                              "--ignore says which matter; the names are in the JSON").format(
            names=len(outside), n=sum(outside.values())))
    if res["mentioned_undeclared"]:
        lines.append("· " + _("{names} name(s) outside the list and the --known ones, in {n} citation(s), not "
                              "counted").format(names=len(res["mentioned_undeclared"]),
                                                n=sum(res["mentioned_undeclared"].values())))
    if res["ignored"]:
        lines.append("· " + _("ignored by --ignore: {names}").format(names=_tally(res["ignored"])))
    if res["rc"] == 3:
        lines.append("· " + _("the scan is partial: an empty answer here does not prove there is none"))
    return lines


def _pin_lines(res):
    lines = []
    for r in (r for r in res["citations"] if r["status"] != "same"):
        c = r["cited"]
        what = "/".join(r.get("classes") or []) or r.get("reason") or ""
        now = f" → {r['current_status']}" if r.get("current_status") else ""
        mark = " " + _("(inferred)") if c["id_source"] == "inferred" else ""
        lines.append(f"{STATUS_WORD[r['status']]()} {what}{now}  {c['repo']}:{c['path'] or ''}#{c['id'] or ''}"
                     f"@{c['commit'][:12]}{mark}  ← {r['citer']['repo']}:{r['citer']['id']} [{r['field']}]")
    s = res["summary"]
    if s["shown"] != s["citations"]:
        lines.append("· " + _("listing {shown} of {n}, by --from or --status; the summary and the rc are of the whole list").format(
            shown=s["shown"], n=s["citations"]))
    lines.append("· " + _("{n} citation(s) with a commit; what to look at first:").format(n=s["citations"]))
    for g in s["groups"]:
        lines.append(f"    {g['citations']:>5}  {STATUS_WORD[g['status']]()}" + (f" {g['class']}" if g["class"] else ""))
    if s["unpinned"]:
        lines.append("· " + _("without a commit, not compared: {names}").format(names=_tally(s["unpinned"])))
    return lines


def _cited_lines(res):
    lines = [f"{r['citer']['repo']}:{r['citer']['file']}#{r['citer']['id']}  {r['field']}  {r['form']}  {r['certainty']}"
             for r in res["citations"]]
    t, s = res["target"], res["summary"]
    lines.append("· " + _("{repo}:{id}: {n} citation(s) from {nodes} node(s)").format(
        repo=t["repo"], id=t["id"], n=s["citations"], nodes=s["citing_nodes"]))
    if not t["found_in"]:
        lines.append("· " + _("the node is not in that state of {repo}: use --at for an earlier one").format(
            repo=t["repo"]))
    if s["elsewhere"]:
        lines.append("· " + _("same id, pointing to another repository, not counted: {names}").format(
            names=_tally(s["elsewhere"])))
    return lines


def human(res):
    body = _pin_lines(res) if res["command"] == "pins" else _cited_lines(res)
    return "\n".join(_failed(res) + body + _coverage(res))


def parse_pairs(items, flag):
    pairs = []
    for item in items:
        name, sep, value = item.partition("=")
        if not sep or not name or not value:
            raise Broken(_("{flag} {item}: write NAME=VALUE").format(flag=flag, item=repr(item)))
        pairs.append((name, value))
    return pairs


def read_list(path):
    """As linhas NOME=PASTA do --repos; # comenta, e a pasta relativa parte do arquivo."""
    try:
        lines = pathlib.Path(path).read_text(encoding="utf-8").splitlines()
    except (OSError, UnicodeDecodeError) as exc:
        raise Broken(f"--repos {path}: {exc}") from None
    pairs = parse_pairs([x.strip() for x in lines if x.strip() and not x.lstrip().startswith("#")], "--repos")
    return [(n, str((pathlib.Path(path).parent / p))) for n, p in pairs]


def build(args):
    pairs = parse_pairs(args.repo, "--repo") + (read_list(args.repos) if args.repos else [])
    if not pairs:
        raise Broken(_("declare the repositories with --repo NAME=FOLDER or --repos FILE: the tool does not guess "
                       "them"))
    if len(pairs) != len(set(pairs)) or len({n for n, _f in pairs}) != len(pairs):
        raise Broken(_("each repository name is declared once, for one folder"))
    at = parse_pairs(args.at, "--at")
    if any(n not in dict(pairs) for n, _c in at):
        raise Broken(_("--at names {names}, which is not in the list").format(names=", ".join(n for n, _c in at)))
    if any(c.startswith("-") for _n, c in at):
        raise Broken(_("--at takes a commit, not an option"))
    if any(pat in dict(pairs) for pat in args.ignore):
        raise Broken(_("--ignore names a repository of the list: take it out of the list instead"))
    if set(args.ignore) & set(args.known):
        raise Broken(_("--ignore and --known name the same repository: choose one"))
    at = dict(at)
    folders, names = {}, {}
    for name, folder in pairs:
        key = str(pathlib.Path(folder).resolve())
        if key in folders and at.get(name) and at[name] != folders[key].at:
            raise Broken(_("--at {name}: another name of that folder reads another commit").format(name=name))
        if key not in folders:
            ref = next((at[n] for n, f in pairs if n in at and str(pathlib.Path(f).resolve()) == key), None)
            folders[key] = Repo(folder, ref, args.exclude, not args.no_default_excludes)
        names[name] = folders[key]
    return Scan(names, args.ignore, args.known)


def main(argv=None):
    ap = argparse.ArgumentParser(description=_("Who cites a node across repositories, and what changed in what is cited. "
                                               "A query, not an alarm: it finds a wrong citation, not a missing one."))
    ap.add_argument("command", choices=("cited-by", "pins"))
    ap.add_argument("target", nargs="?", metavar="REPO:ID", help=_("cited-by: the cited node"))
    ap.add_argument("--repo", action="append", default=[], metavar=_("NAME=FOLDER"),
                    help=_("a repository of the declared list (repeatable); one more NAME for the same folder is an alias"))
    ap.add_argument("--repos", metavar=_("FILE"), help=_("the list in a file, one NAME=FOLDER per line"))
    ap.add_argument("--at", action="append", default=[], metavar=_("NAME=COMMIT"),
                    help=_("read that repository at an earlier state, not at HEAD"))
    ap.add_argument("--known", action="append", default=[], metavar=_("NAME"),
                    help=_("a repository of the network with no folder here (repeatable): it gives rc 3, and with it only "
                           "the list and the known ones count in the rc"))
    ap.add_argument("--ignore", action="append", default=[], metavar=_("NAME"),
                    help=_("a name cited with a commit that is not a repository that matters, or a glob ('*' declares "
                           "the list complete)"))
    ap.add_argument("--exclude", action="append", default=[], metavar="GLOB",
                    help=_("paths to leave out (repeatable), added to the defaults"))
    ap.add_argument("--no-default-excludes", action="store_true", help=_("also read the vendor and the fixtures"))
    ap.add_argument("--from", dest="from_repo", metavar=_("NAME"),
                    help=_("pins: list only the citations written in that repository; the scan, the summary and the rc stay "
                           "those of the whole list"))
    ap.add_argument("--status", metavar=_("LIST"),
                    help=_("pins: list only these statuses, as gone,changed; the summary and the rc stay those of the scan"))
    ap.add_argument("--format", default="human", choices=("human", "json"))
    args = ap.parse_intermixed_args(argv)
    kg_validate._utf8_stdio()
    try:
        if args.command == "pins" and args.target:
            raise Broken(_("pins takes no target"))
        if args.command == "cited-by" and not re.fullmatch(r"[^:\s]+:[^:\s]+", args.target or ""):
            raise Broken(_("cited-by takes REPO:ID"))
        if args.command == "cited-by" and (args.from_repo or args.status):
            raise Broken(_("--from and --status belong to pins"))
        statuses = args.status.split(",") if args.status else []
        if args.status is not None and (not statuses or not set(statuses) <= set(STATUSES)):
            raise Broken(_("--status takes a comma-separated list of {names}").format(names=", ".join(STATUSES)))
        scan = build(args)
        if args.command == "cited-by" and args.target.split(":", 1)[0] not in scan.names:
            raise Broken(_("{repo} is not in the declared list").format(repo=args.target.split(":", 1)[0]))
        if args.from_repo and args.from_repo not in scan.names:
            raise Broken(_("{repo} is not in the declared list").format(repo=args.from_repo))
        res = pins(scan, args.from_repo, statuses) if args.command == "pins" else cited_by(scan, args.target)
    except (Broken, OSError, ValueError) as exc:
        print(_("BROKEN INPUT  {error}").format(error=exc), file=sys.stderr)
        return 2
    text = json.dumps(res, ensure_ascii=False, indent=1, default=kg_diff.jsonable) if args.format == "json" else human(res)
    # o surrogate solto (o caminho que não é UTF-8) sai como o escape dele, como no kg_diff
    print(text.encode("utf-8", "backslashreplace").decode("utf-8"))
    return res["rc"]


if __name__ == "__main__":
    sys.exit(main())
