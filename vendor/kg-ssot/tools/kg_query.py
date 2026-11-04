#!/usr/bin/env python3
"""A consulta e a projeção legível de um corpus de grafos .kg.yaml e .kg.json.

Lê muitos grafos de uma vez e seleciona nós por id, prefixo, tipo, status, plano, camada e texto do label; traz a
vizinhança por tipo de aresta e profundidade, a fila dos abertos (--open) e os nós sem verified_at ou conferidos
antes de uma data (--verified-before). Cada nó sai PROJETADO: as arestas de saída e de entrada com a outra ponta
resolvida de id para label, local ou externa (external_edges), e se a ponta existe no corpus. Paginação por cursor.

Não julga: o veredito é do kg_validate.py, e um grafo que não parseia sai em "unreadable", sem derrubar a consulta.
Ranqueia por atenção desde a 4.36.0 (--sort attention): impact × confidence × fator do status × (1 + grau), a mesma fórmula e o mesmo desempate do radar do framework onde o formato nasceu.
Saída humana, ou JSON no formato kg-ssot.query/1, ou /2 com --due (spec/query.schema.json); as arestas, os grupos e a cadeia em lote têm
os formatos deles (edges.schema.json, groups.schema.json, chains.schema.json).

Uso:
  kg_query.py [--root DIR [--exclude GLOB]... [--no-default-excludes] | ARQ...] [filtros] [--around ID [--depth N] [--edge-type T]...
              [--direction out|in|both]] [--sort corpus|impact|attention] [--limit N] [--cursor C] [--narrative]
              [--fields GLOB]... [--format human|json]
  filtros (todos juntos, em E): --id ID... --id-prefix P --type T --status S --plane P --layer L --file TRECHO
                                --text PALAVRAS [--in-narrative] --open --verified-before AAAA-MM-DD
                                --where CHAVE=VALOR (e CHAVE^=VALOR, começa com; CHAVE*=VALOR, contém; degree.in.TIPO=0)
                                --has CAMPO --missing CAMPO --due [--as-of AAAA-MM-DD]
  contagem: --group-by CAMPO... [--count-distinct CAMPO...] [--min-count N]; arestas como sujeito: --edges
  uma cadeia ou um lote: --chain ID... (até 50); a história: --decision ID; a fila de revisão: --revisit
  --root DIR lê os .kg.yaml e .kg.json rastreados pelo git sob DIR (sem git, todos sob DIR), menos o vendor e os
  fixtures (vendor/*, fixtures/*, */fixtures/*, docs/materials/* e, desde a 4.20.0, toda pasta com o carimbo
  .kg-ssot-version abaixo de DIR); os caminhos saem relativos a DIR, que
  é a raiz contra a qual a ponta externa <caminho>#<id> se resolve.
  --semantic PERGUNTA [--model NOME] [--model-dir DIR] (desde a 4.26, com o extra vector): ordena os nós que passam
  nos filtros pela semelhança com a pergunta; com --text, funde as duas ordens por RRF (k=60). Ver kg_vector.py.
rc: 0 consultou (mesmo sem nenhum nó) · 2 entrada quebrada · 3 o --semantic não roda aqui (o extra vector ou o modelo
ausente): quem chama cai no --text e declara.
"""
import argparse
import collections
import datetime
import fnmatch
import json
import os
import pathlib
import re
import subprocess
import sys
import unicodedata

sys.dont_write_bytecode = True
if __package__:  # no pacote kg_ssot, o vizinho vem pelo pacote, sem mexer no sys.path de quem importa
    from . import kg_i18n, kg_validate
else:  # script ou vendor
    sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
    import kg_i18n  # noqa: E402
    import kg_validate  # noqa: E402
_ = kg_i18n._

SCHEMA_VERSION = "kg-ssot.query/1"
DUE_VERSION = "kg-ssot.query/2"  # desde a 4.43.0, só com --due: o schema é fechado, e o --due acrescenta campos ao nó
MAX_LIMIT = 1000
# o label da OUTRA ponta de uma aresta sai cortado: sem o corte, um nó de label longo citado por milhares de arestas
# (duplicadas, ou externas de outro grafo) multiplica a resposta pelo número de arestas (2 MB de grafo, 7,5 GB de saída)
END_LABEL_MAX = 200
NODE_FIELDS = ("node_type", "status", "plane", "layer", "impact", "confidence", "verified_at")
DEGREE_SIDES = ("in", "out", "total")


class Corpus:
    """Os grafos lidos: os nós por (arquivo, id) na ordem do corpus, e as arestas locais e externas dos dois lados."""

    def __init__(self):
        self.nodes = {}  # (arquivo, id) -> nó (o mapa do documento)
        self.order = []  # as chaves na ordem do corpus: arquivo a arquivo, nó a nó
        self.out = collections.defaultdict(list)  # (arquivo, id) -> [(edge_type, (arquivo, id) | None, ref)]
        self.into = collections.defaultdict(list)
        self.unreadable = []  # [{file, code}]
        self.files = []
        self.root = None  # a raiz do --root, contra a qual os caminhos (file) e a ponta externa se resolvem
        self.meta_ids = {}  # arquivo -> meta.id (o kg_vocab monta o IRI do termo com ele, como o kg_prov_export)
        self.metas = {}  # arquivo -> o meta do grafo (o --group-by meta.<chave>, 4.41.0)
        self.edges = []  # cada aresta: {edge_type, scope, file, from, to}, com as pontas como chave (arquivo, id) (4.42.0)
        self.withs = []  # [(prefixo da URL, pasta local)]: o --with lê o grafo de outro repositório (4.35.0)
        self.external = {}  # URL do grafo lido pelo --with -> {"base": prefixo/ref/, "pinned": bool}
        # o grau da atenção (4.36.0), no escopo do arquivo, como o radar: a aresta conta para as pontas locais do arquivo
        # que a declara, e o evento do trigger (ou on) de uma aresta também conta; a que chega de outro arquivo não
        self.local_degree = collections.Counter()
        # o grau derivado (4.43.0), que não é o da atenção: só as arestas internas, linha por linha, por tipo. Sai de
        # self.edges na hora de ler, para alcançar também o que o --with trouxer depois
        self._degree = {"in": collections.defaultdict(collections.Counter), "out": collections.defaultdict(collections.Counter)}
        self._degree_seen = 0

    def internal_degree(self, key, side, edge_type=None):
        """Quantas arestas internas do grafo do nó tocam o nó, em in, out ou total, de um tipo ou de todos. A linha repetida
        conta de novo; o laço conta em in e em out, e por isso duas vezes em total; a aresta externa não entra."""
        for e in self.edges[self._degree_seen:]:
            if e["scope"] == "internal":
                self._degree["out"][e["from"]][e["edge_type"]] += 1
                self._degree["in"][e["to"]][e["edge_type"]] += 1
        self._degree_seen = len(self.edges)
        counts = [self._degree[s].get(key, {}) for s in (("in", "out") if side == "total" else (side,))]
        return sum(sum(c.values()) if edge_type is None else c.get(edge_type, 0) for c in counts)

    def add(self, name, text):
        if name in self.files:  # o mesmo arquivo dado duas vezes não duplica as arestas
            return
        self.files.append(name)
        _tree, doc, code = kg_validate.parse_v1(kg_validate.as_source(name, text) if not isinstance(text, kg_validate.JsonText)
                                            else text)
        if code or not isinstance(doc, dict):
            self.unreadable.append({"file": name, "code": code or "parse.root-not-mapping"})
            return
        meta = doc.get("meta")
        if isinstance(meta, dict):
            self.metas[name] = meta
        if isinstance(meta, dict) and isinstance(meta.get("id"), str):
            self.meta_ids[name] = meta["id"]
        for n in doc.get("nodes") if isinstance(doc.get("nodes"), list) else []:
            if isinstance(n, dict) and isinstance(n.get("id"), str) and (name, n["id"]) not in self.nodes:
                self.nodes[(name, n["id"])] = n
                self.order.append((name, n["id"]))
        for e in doc.get("edges") if isinstance(doc.get("edges"), list) else []:
            if isinstance(e, dict) and isinstance(e.get("from"), str) and isinstance(e.get("to"), str):
                self._link(e.get("edge_type"), (name, e["from"]), (name, e["to"]), None, None)
                self.edges.append({"edge_type": e.get("edge_type") if isinstance(e.get("edge_type"), str) else None,
                                   "scope": "internal", "file": name,
                                   "from": (name, e["from"]), "to": (name, e["to"])})
                self.local_degree[(name, e["from"])] += 1
                self.local_degree[(name, e["to"])] += 1
                event = e.get("trigger", e.get("on"))
                if isinstance(event, str) and event:
                    self.local_degree[(name, event)] += 1
        for e in doc.get("external_edges") if isinstance(doc.get("external_edges"), list) else []:
            if not isinstance(e, dict):
                continue
            src, dst = self._end(name, e.get("from")), self._end(name, e.get("to"))
            self._link(e.get("edge_type"), src, dst, e.get("from"), e.get("to"))
            self.edges.append({"edge_type": e.get("edge_type") if isinstance(e.get("edge_type"), str) else None,
                               "scope": "external", "file": name, "from": src, "to": dst})
            for end in (src, dst):
                if end[0] == name and end[1] is not None:
                    self.local_degree[end] += 1

    @staticmethod
    def _end(name, ref):
        """A ponta de uma aresta externa: <caminho>#<id> vira (caminho, id); um id local, (arquivo, id); ausente (o grafo
        inteiro como origem), (arquivo, None)."""
        if kg_validate.is_external(ref):
            path, nid = ref.rsplit("#", 1)
            return (path, nid)
        return (name, ref if isinstance(ref, str) else None)

    def _link(self, edge_type, src, dst, src_ref, dst_ref):
        et = edge_type if isinstance(edge_type, str) else None
        if src[1] is not None:  # o grafo inteiro como origem não pendura a aresta em nó nenhum
            self.out[src].append((et, dst, dst_ref))
        if dst[1] is not None:
            self.into[dst].append((et, src, src_ref))


# os mesmos do kg_migrate.py: o vendor e os fixtures (os da suíte e os de qualquer ferramenta) não são o grafo do
# adotante; um --root sem eles leu 411 grafos para 29 reais no primeiro adotante que usou (achado de campo, 4.17.1)
DEFAULT_EXCLUDE = ("vendor/*", "fixtures/*", "*/fixtures/*", "docs/materials/*")
RRF_K = 60  # a constante do RRF (Cormack et al., 2009), a mesma da bancada que mediu o híbrido


def load(root=None, files=(), exclude=(), defaults=True):
    """O corpus de --root (os rastreados pelo git, ou todos sob a pasta) ou dos arquivos dados. exclude: padrões glob
    sobre o caminho relativo (export/*, *.kg.yaml) que ficam de fora, somados aos DEFAULT_EXCLUDE quando defaults.
    Com defaults, fica de fora também toda pasta com o carimbo do vendor (kg_validate.vendor_dirs), onde quer que ela
    esteja. Os arquivos dados um a um nunca são excluídos. ValueError: entrada quebrada."""
    exclude = (DEFAULT_EXCLUDE if defaults else ()) + tuple(exclude)
    corpus = Corpus()
    if root is not None:
        base = pathlib.Path(root)
        if not base.is_dir():
            raise ValueError(_("--root {root} is not a directory").format(root=root))
        corpus.root = str(root)
        out = _git(str(base), "ls-files", "-z", "--", "*.kg.yaml", "*.kg.json")
        if out.returncode == 0:
            names = [n for n in out.stdout.decode("utf-8").split("\0") if n]
        else:
            names = sorted(p.relative_to(base).as_posix() for g in ("*.kg.yaml", "*.kg.json") for p in base.rglob(g)
                           if ".git" not in p.relative_to(base).parts)
        vendors = kg_validate.find_vendor_dirs(base) if defaults else ()
        for name in names:
            if any(fnmatch.fnmatchcase(name, pat) for pat in exclude) or kg_validate.in_vendor(name, vendors):
                continue
            path = base / name
            if not path.is_file():
                continue
            try:
                corpus.add(name, path.read_text(encoding="utf-8"))
            except (OSError, UnicodeDecodeError) as exc:
                corpus.unreadable.append({"file": name, "code": f"io.{type(exc).__name__}"})
    for name in files:
        with open(name, encoding="utf-8") as fh:
            corpus.add(pathlib.PurePath(name).as_posix(), fh.read())
    return corpus


def resolve(corpus, ref, flag="--around"):
    """Um id dado na linha de comando: <caminho>#<id> ou o id sozinho, que tem de ser único no corpus. ValueError."""
    if "#" in ref:
        path, nid = ref.rsplit("#", 1)
        if (path, nid) not in corpus.nodes:
            raise ValueError(_("{flag} {ref}: the node does not exist in the corpus").format(flag=flag, ref=ref))
        return (path, nid)
    hits = [k for k in corpus.order if k[1] == ref]
    if not hits:
        raise ValueError(_("{flag} {ref}: the node does not exist in the corpus").format(flag=flag, ref=ref))
    if len(hits) > 1:
        raise ValueError(_("{flag} {ref}: the id exists in {n} graphs; use <path>#{ref}")
                         .format(flag=flag, ref=ref, n=len(hits)))
    return hits[0]


def neighborhood(corpus, start, depth, edge_types, direction):
    """As chaves alcançadas a partir de start (inclusive) em até depth saltos, pelos tipos e na direção pedidos. Só
    entra nó que existe no corpus; a ponta que falta aparece na projeção, como found: false."""
    seen, frontier = {start}, [start]
    for _hop in range(depth):
        if not frontier:  # nada mais a alcançar: um --depth enorme não gira em vão
            break
        nxt = []
        for key in frontier:
            hops = (corpus.out[key] if direction in ("out", "both") else []) + \
                   (corpus.into[key] if direction in ("in", "both") else [])
            for et, other, _ref in hops:
                if other in seen or other not in corpus.nodes:
                    continue
                if edge_types and et not in edge_types:
                    continue
                seen.add(other)
                nxt.append(other)
        frontier = nxt
    return seen


# A classe de provenance.method, canônica em inglês desde o contrato v4.16; o português é alias aceito
METHOD_CLASS = {"measurement": "measurement", "reading": "reading", "judges": "judges", "derived": "derived",
                "testimony": "testimony", "medição": "measurement", "leitura": "reading", "juízes": "judges",
                "derivado": "derived", "testemunho": "testimony"}
# As faixas do grau da corrente (4.33.0), fixadas no pré-registro da projeção, antes do código
GRADE_BANDS = ((0.85, "strong"), (0.60, "acceptable"))
GRADE_ORDER = {"weak": 0, "acceptable": 1, "strong": 2}
CHAIN_SCHEMA = "kg-ssot.chain/1"
MAX_CHAIN = 200  # um teto de passos: uma corrente com mais passos que isso é dado quebrado, não transmissão
MAX_PATHS = 1000  # um teto de caminhos: correntes que bifurcam e se reencontram multiplicam os caminhos (o Elenxo mediu
# 262.144 caminhos e 2,3 GB num losango de 18 camadas); além do teto, a projeção sai truncated


# A atenção (4.36.0): o peso do nó no radar, impact × confidence × fator do status × (1 + grau), a mesma fórmula da
# fila de abertos do radar do framework onde o formato nasceu, para os dois concordarem num mesmo grafo. O fator dá
# mais peso ao que mediu que o mundo andou (drifted) e quase nenhum à história (superseded, done, refuted).
STATUS_FACTOR = {"open": 1.0, "confirmed": 1.0, "drifted": 1.3, "unverifiable": 1.0, "refuted": 0.0,
                 "superseded": 0.2, "done": 0.1}


def _num(v):
    return v if isinstance(v, (int, float)) and not isinstance(v, bool) else None


def degree(corpus, key):
    """As arestas que tocam o nó, no escopo do arquivo dele, como o radar: as locais, a ponta local das externas que o
    arquivo declara e o evento de um trigger. A que chega de outro arquivo não conta: a atenção não muda com o --root."""
    return corpus.local_degree.get(key, 0)


def by_attention(keys, att):
    """Os nós pela atenção, maior primeiro; no empate, o id em ordem decrescente, como o desempate do radar
    (@val_num_desc do gawk), para os dois darem a mesma fila num mesmo grafo; depois o arquivo."""
    keys = sorted(keys, key=lambda k: (k[1], k[0]), reverse=True)
    return sorted(keys, key=lambda k: -att[k])


def attention(corpus, key, raw=False):
    """impact × confidence × fator do status × (1 + grau); o campo que falta ou não é número conta zero. Em grafo que passa
    no MUST, é o valor do radar; raw dá o valor sem arredondar, que é o que ordena."""
    node = corpus.nodes[key]
    impact, conf = _num(node.get("impact")), _num(node.get("confidence"))
    factor = STATUS_FACTOR.get(node.get("status"), 0.0)
    if impact is None or conf is None:
        return 0.0
    value = impact * conf * factor * (1 + degree(corpus, key))
    return value if raw else round(value, 6)


def method_class(node):
    """A classe canônica do provenance.method do nó, ou None (sem method, ou classe fora do vocabulário)."""
    prov = node.get("provenance")
    method = prov.get("method") if isinstance(prov, dict) else None
    if not isinstance(method, str) or ": " not in method:
        return None
    return METHOD_CLASS.get(method.split(": ", 1)[0])


def band(conf):
    """A faixa de um confidence; um valor que não é número conta como weak."""
    if not isinstance(conf, (int, float)) or isinstance(conf, bool):
        return "weak"
    for floor, name in GRADE_BANDS:
        if conf >= floor:
            return name
    return "weak"


def with_spec(text):
    """O --with PREFIXO=PASTA, validado: (prefixo, pasta). ValueError: forma quebrada ou pasta que não existe."""
    prefix, sep, folder = text.partition("=")
    prefix = prefix.rstrip("/")
    if not sep or not prefix or not folder:
        raise ValueError(_("--with takes PREFIX=FOLDER, the URL prefix before the commit and the local folder"))
    if not pathlib.Path(folder).is_dir():
        raise ValueError(_("--with {folder} is not a directory").format(folder=folder))
    return prefix, folder


GIT_ENV_DROP = ("GIT_DIR", "GIT_WORK_TREE", "GIT_INDEX_FILE")  # um hook de pre-commit os define para o repo dele


def _git(folder, *args):
    """git -C folder com --end-of-options antes do que vem do grafo: um ref que começa com - nunca vira opção. Sem o
    GIT_DIR, o GIT_WORK_TREE e o GIT_INDEX_FILE herdados, que apontariam o git para outro repositório."""
    env = {k: v for k, v in os.environ.items() if k not in GIT_ENV_DROP}
    return subprocess.run(["git", "-C", folder, *args], capture_output=True, env=env)


def load_external(corpus, url):
    """Lê para o corpus, pelo --with, o grafo de outro repositório que a URL nomeia (<prefixo>/<ref>/<caminho>), só
    para leitura. Quando a pasta é git e o ref da URL existe nela, o grafo é lido naquele ref (pinned), relativo à
    pasta dada, e o arquivo que não está nele fica de fora; quando o ref não existe ali ou a pasta não é git, é lido da
    árvore de trabalho (pinned False). Devolve True quando o grafo está no corpus, False quando um prefixo casou e o
    grafo não se lê (o passo sai quebrado), e None quando nenhum prefixo casa."""
    if url in corpus.external:
        return url in corpus.files
    for prefix, folder in corpus.withs:
        if not url.startswith(prefix + "/"):
            continue
        ref, _sep, rel = url[len(prefix) + 1:].partition("/")
        while rel.startswith("./"):
            rel = rel[2:]
        corpus.external[url] = {"base": f"{prefix}/{ref}/", "pinned": False}
        if not ref or ref.startswith("-") or not rel or rel.startswith("/") or ".." in rel.split("/"):
            return False
        text, pinned = None, False
        try:
            if _git(folder, "cat-file", "-e", "--end-of-options", f"{ref}^{{commit}}").returncode == 0:
                out = _git(folder, "show", "--end-of-options", f"{ref}:./{rel}")
                if out.returncode == 0:
                    text, pinned = out.stdout.decode("utf-8"), True
            elif (pathlib.Path(folder) / rel).is_file():
                text = (pathlib.Path(folder) / rel).read_text(encoding="utf-8")
        except (OSError, UnicodeDecodeError):  # o grafo de lá que não se lê é passo quebrado, não entrada quebrada
            text = None
        corpus.external[url]["pinned"] = pinned
        if text is None:
            return False
        corpus.add(url, text)
        return not any(u["file"] == url for u in corpus.unreadable)
    return None


def _source_ref(corpus, key):
    """O passo pelo fragmento do provenance.source, ou None quando o source não aponta para um grafo. Aponta quando o
    caminho antes do # é vazio, é o do próprio arquivo, termina no meta.id do próprio grafo (a URL de quem publica o
    grafo), é um arquivo do corpus, ou tem a extensão de um grafo. Qualquer outro fragmento (a seção de um README, uma
    URL externa) é a origem, e nunca cai num homônimo local. Devolve ((arquivo, id), ref): a chave pode não existir no
    corpus, e o passo sai quebrado."""
    prov = corpus.nodes[key].get("provenance")
    source = prov.get("source") if isinstance(prov, dict) else None
    if not isinstance(source, str) or "#" not in source:
        return None
    path, frag = source.rsplit("#", 1)
    if not frag:
        return None
    path = path.split("?", 1)[0]  # a query string (?ref=main) não muda o arquivo que a URL nomeia
    here = key[0]
    if here in corpus.external and path.endswith((".kg.yaml", ".kg.json")) and "://" not in path:
        rel = path
        while rel.startswith("./"):
            rel = rel[2:]
        if not rel.startswith("/") and ".." not in rel.split("/"):
            path = corpus.external[here]["base"] + rel  # o caminho do repo de lá, não o daqui
    if corpus.withs and "://" in path:
        loaded = load_external(corpus, path)
        if loaded is not None:  # um prefixo do --with casou: o passo é o de lá, carregado ou quebrado, nunca um homônimo daqui
            return ((path, frag), source)
    last = path.rstrip("/").rsplit("/", 1)[-1]
    for ext in (".kg.yaml", ".kg.json"):
        last = last[: -len(ext)] if last.endswith(ext) else last
    if path in ("", here) or (corpus.meta_ids.get(here) and last == corpus.meta_ids[here]):
        target = (here, frag)
    elif path in corpus.files or path.endswith((".kg.yaml", ".kg.json")):
        target = (path, frag)
    else:
        return None
    return (target, source)  # o nó que cita a si mesmo é um ciclo, não uma origem


def _declared(node):
    """O nó declara de onde veio: tem provenance.source em texto, e não só um # sem nada depois."""
    prov = node.get("provenance") if isinstance(node, dict) else None
    source = prov.get("source") if isinstance(prov, dict) else None
    return isinstance(source, str) and bool(source.strip().strip("#").strip())


def _steps(corpus, key, edge_types):
    """Os passos de um nó para o anterior. O provenance manda quando existe (4.34.0): o fragmento do source é o passo,
    e um source que não nomeia nó de grafo faz do nó a origem. As arestas dos tipos pedidos só valem para o nó sem
    provenance.source, porque um selo TRACES_TO o nó que ele responde, não o de onde veio. Cada passo é (chave, ref):
    a chave pode não existir no corpus (a ponta quebrada)."""
    if _declared(corpus.nodes[key]):
        found = _source_ref(corpus, key)
        return [found] if found else []  # as arestas que o provenance deixa de fora saem em _link (edges_not_followed)
    return [(dst, ref) for et, dst, ref in corpus.out[key] if et in edge_types and dst is not None]


def _link(corpus, key, ref=None, edge_types=None):
    node = corpus.nodes.get(key)
    if node is None:
        return {"file": key[0], "id": key[1], "ref": ref, "found": False, "confidence": None, "method_class": None,
                "label": None}
    conf = node.get("confidence")
    numeric = isinstance(conf, (int, float)) and not isinstance(conf, bool) and 0 <= conf <= 1  # fora de [0, 1] é desconhecido
    ext = corpus.external.get(key[0])
    return {"file": key[0], "id": key[1], "ref": None, "found": True, "confidence": conf if numeric else None,
            **({"pinned": ext["pinned"]} if ext else {}),
            "declared": _declared(node),
            "edges_not_followed": [dst[1] for et, dst, _r in corpus.out[key] if edge_types and et in edge_types
                                   and dst is not None and _declared(node)],
            "method_class": method_class(node), "label": node.get("label") if isinstance(node.get("label"), str) else None}


def _grade(path, status):
    """Os dois eixos de um caminho: o elo mais fraco (sem a origem) e a força da origem, e o grau nos dois modos. Um
    caminho que não é complete (broken, cycle, too_long) sai weak nos dois modos e sem origem. Um elo sem confidence
    numérico conta como o mais fraco, com confidence null, e rebaixa o leniente para weak."""
    complete = status == "complete"
    links = path[:-1] if complete else [p for p in path if p["found"]]
    by_key = {(p["file"], p["id"]): p for p in links}  # o ciclo repete o nó: cada (arquivo, id) entra uma vez
    unknown = [k for k, p in by_key.items() if p["confidence"] is None]
    if unknown:
        at = unknown
        weakest = {"confidence": None}
    else:
        floor = min((p["confidence"] for p in by_key.values()), default=None)
        at = [k for k, p in by_key.items() if p["confidence"] == floor] if by_key else []
        weakest = {"confidence": floor}
    weakest["ids"] = [i for _f, i in at]
    weakest["at"] = [{"file": f, "id": i} for f, i in at]  # o mesmo id pode estar em dois arquivos
    if not complete:
        return {"weakest_link": weakest, "origin": None, "grade": {"strict": "weak", "lenient": "weak"}}
    origin = path[-1]
    if unknown or not origin.get("declared"):  # a origem sem provenance não diz de onde veio: a corrente pode seguir
        lenient = "weak"
    elif links:
        lenient = band(weakest["confidence"])
    else:  # corrente de um nó só: o leniente é a própria origem
        lenient = band(origin["confidence"])
    origin_band = ("weak" if origin["method_class"] in (None, "testimony") or not origin.get("declared")
                   else band(origin["confidence"]))
    strict = min(lenient, origin_band, key=GRADE_ORDER.get)
    return {"weakest_link": weakest,
            "origin": {"id": origin["id"], "file": origin["file"], "method_class": origin["method_class"],
                       "confidence": origin["confidence"], "declared": bool(origin.get("declared"))},
            "grade": {"strict": strict, "lenient": lenient}}


def chain(corpus, ref, edge_types=("TRACES_TO",)):
    """A projeção da cadeia de transmissão a partir de ref (kg-ssot.chain/1): cada caminho até a origem, na ordem das
    arestas, o elo mais fraco e a força da origem em eixos separados, e o grau estrito e leniente pelas faixas de
    GRADE_BANDS. Até MAX_PATHS caminhos (além disso, truncated). ValueError: pedido quebrado."""
    start = resolve(corpus, ref, "--chain")
    edge_types = set(edge_types or ("TRACES_TO",))
    paths = []

    def walk(keys, links):
        if len(paths) > MAX_PATHS:
            return
        if len(keys) - 1 > MAX_CHAIN:
            paths.append({"status": "too_long", "links": links})
            return
        steps = _steps(corpus, keys[-1], edge_types)
        if not steps:
            paths.append({"status": "complete", "links": links})
            return
        for nxt, nref in steps:
            if len(paths) > MAX_PATHS:
                return
            if nxt in keys:
                paths.append({"status": "cycle", "links": links + [_link(corpus, nxt)]})
            elif nxt not in corpus.nodes:
                paths.append({"status": "broken", "links": links + [_link(corpus, nxt, nref)]})
            else:
                walk(keys + [nxt], links + [_link(corpus, nxt, edge_types=edge_types)])

    walk([start], [_link(corpus, start, edge_types=edge_types)])
    truncated = len(paths) > MAX_PATHS  # um caminho além do teto prova que havia mais
    paths = paths[:MAX_PATHS]
    out = [{"status": p["status"], "links": p["links"], **_grade(p["links"], p["status"])} for p in paths]
    bands = {name: floor for floor, name in GRADE_BANDS}
    bands["weak"] = None  # abaixo da menor faixa, sem piso
    return {"schema_version": CHAIN_SCHEMA, "root": corpus.root, "start": {"file": start[0], "id": start[1]},
            "edge_types": sorted(edge_types), "bands": bands, "truncated": truncated, "paths": out}


CHAINS_SCHEMA = "kg-ssot.chains/1"
CHAIN_BATCH_MAX = 50


def chain_request(corpus, refs, edge_types=("TRACES_TO",)):
    """O --chain como foi pedido: um id só (o repetido conta uma vez) dá o kg-ssot.chain/1 de sempre, com a recusa de
    sempre; mais de um dá o kg-ssot.chains/1. ValueError: pedido quebrado, ou o id único que não se resolve."""
    refs = list(dict.fromkeys([refs] if isinstance(refs, str) else refs))
    if len(refs) > CHAIN_BATCH_MAX:
        raise ValueError(_("--chain takes at most {max} ids").format(max=CHAIN_BATCH_MAX))
    return chain(corpus, refs[0], edge_types) if len(refs) == 1 else chains(corpus, refs, edge_types)


def chains(corpus, refs, edge_types=("TRACES_TO",)):
    """A cadeia em lote (kg-ssot.chains/1, 4.43.0): uma entrada por id, na ordem pedida, com o kg-ssot.chain/1 inteiro e
    o status de cada origem. O id que não se resolve fica na entrada dele, com o motivo, sem derrubar o lote. Cada cadeia
    pode chegar a MAX_PATHS caminhos; o lote para de abrir cadeias quando já gastou esse tanto, e as que sobram saem
    not_run, para 50 ids não multiplicarem por 50 o pior caso de uma."""
    items, spent = [], 0
    for ref in refs:
        item = {"ref": ref, "outcome": "ok", "error": None, "chain": None, "origins": []}
        if spent >= MAX_PATHS:
            item.update(outcome="not_run", error=_("the batch stopped at {n} paths: ask this id in a smaller batch")
                        .format(n=MAX_PATHS))
        else:
            try:
                doc = chain(corpus, ref, edge_types)
            except ValueError as exc:
                item.update(outcome="not_resolved", error=str(exc))
            else:
                spent += len(doc["paths"])
                item.update(chain=doc, origins=_origins(corpus, doc))
        items.append(item)
    return {"schema_version": CHAINS_SCHEMA, "root": corpus.root, "edge_types": sorted(set(edge_types or ("TRACES_TO",))),
            "requested": len(refs), "truncated": any(i["outcome"] == "not_run" for i in items),
            "unreadable": list(corpus.unreadable), "chains": items}


def _origins(corpus, doc):
    """As origens de uma cadeia, cada uma uma vez, com o status do nó, que o kg-ssot.chain/1 não traz."""
    keys = dict.fromkeys((p["origin"]["file"], p["origin"]["id"]) for p in doc["paths"] if p["origin"])
    out = []
    for key in keys:
        status = corpus.nodes[key].get("status") if key in corpus.nodes else None
        out.append({"file": key[0], "id": key[1], "status": status if isinstance(status, str) else None})
    return out


DECISION_SCHEMA = "kg-ssot.decision/1"
REVISIT_SCHEMA = "kg-ssot.revisit/2"  # /2 desde a 4.40.0: o motivo pin-changed amplia o enum
HISTORY = {"refuted", "superseded"}  # a história: o nó fica, mas não é mais a SSOT viva
LEANS_ON = ("TRACES_TO", "DEPENDS_ON")  # a decisão se apoia no nó para onde estas arestas saem; SUPPORTS conta ao contrário


def _real(key):
    """A ponta que é um nó: a aresta de grafo inteiro tem a ponta (arquivo, None), que não é nó."""
    return key is not None and key[1] is not None


def _brief(corpus, key, edge=None):
    node = corpus.nodes.get(key)
    out = {"file": key[0], "id": key[1], "found": node is not None}
    if node is not None:
        out.update(status=node.get("status"), node_type=node.get("node_type"),
                   label=node.get("label") if isinstance(node.get("label"), str) else None)
    if edge:
        out["edge_type"] = edge
    return out


def _leans_on(corpus, key):
    """O que a decisão usa como base: o que a apoia (SUPPORTS que chega nela), o TRACES_TO e o DEPENDS_ON que saem dela,
    e o passo do provenance.source. O SUPPORTS que sai dela diz o que ela apoia, não aquilo em que ela se apoia."""
    seen = {}
    for et, src, _ref in corpus.into.get(key, ()):
        if et == "SUPPORTS" and _real(src) and src != key:
            seen.setdefault(src, "SUPPORTS")
    for et, dst, _ref in corpus.out.get(key, ()):
        if et in LEANS_ON and _real(dst) and dst != key:
            seen.setdefault(dst, et)
    found = _source_ref(corpus, key) if _declared(corpus.nodes[key]) else None
    if found and found[0] != key:
        seen.setdefault(found[0], "provenance.source")
    return seen


def _supersede_line(corpus, key, forward):
    """A linhagem de substituição: forward, quem substituiu o nó (e quem substituiu esse); senão, o que ele substituiu."""
    line, frontier, seen = [], [key], {key}
    while frontier:
        nxt = []
        for k in frontier:
            pairs = corpus.into.get(k, ()) if forward else corpus.out.get(k, ())
            for et, other, _ref in pairs:
                if et == "SUPERSEDES" and _real(other) and other not in seen:
                    seen.add(other)
                    line.append(_brief(corpus, other))
                    nxt.append(other)
        frontier = nxt
    return line


def decision_history(corpus, ref):
    """A história de uma decisão (kg-ssot.decision/1): o que ela substituiu e quem a substituiu, em toda a linhagem; o
    que a refuta; e aquilo em que ela se apoia, com o status de cada um. Nada se perde: a superada e a refutada aparecem
    com o que veio no lugar. ValueError: pedido quebrado."""
    key = resolve(corpus, ref, "--decision")
    node = corpus.nodes[key]
    refuted_by = [_brief(corpus, src) for src in dict.fromkeys(s for et, s, _r in corpus.into.get(key, ())
                                                                if et == "REFUTES" and _real(s))]
    supported_by = [_brief(corpus, src) for src in dict.fromkeys(s for et, s, _r in corpus.into.get(key, ())
                                                                  if et == "SUPPORTS" and _real(s))]
    return {"schema_version": DECISION_SCHEMA, "root": corpus.root, "decision": _brief(corpus, key),
            "is_decision": node.get("node_type") == "decision", "attention": attention(corpus, key),
            "replaced": _supersede_line(corpus, key, forward=False),
            "replaced_by": _supersede_line(corpus, key, forward=True),
            "refuted_by": refuted_by, "supported_by": supported_by,
            "leans_on": [_leaning(corpus, k, et) for k, et in _leans_on(corpus, key).items()]}


def _leaning(corpus, key, edge):
    """O apoio de uma decisão, com o status na ponta do clone quando ele é externo e fixado (4.38.0)."""
    out = _brief(corpus, key, edge)
    if key[0] in corpus.external:
        out["pinned"] = pinned(corpus, key[0])
    head = head_status(corpus, key) if key in corpus.nodes else None
    if head is not None:
        out["head_status"] = head
    return out


def _due(node, as_of):
    """A data em que o nó venceu (verified_at + reverify_every) quando venceu até as_of; senão None."""
    stamp = kg_validate._as_date(node.get("verified_at"))
    every = kg_validate.parse_duration(node.get("reverify_every"))
    if stamp is None or every is None:
        return None
    try:
        when = kg_validate.add_duration(stamp, every)
    except (OverflowError, ValueError):  # os mesmos do due_report: vence depois do ano 9999, não vence na data pedida
        return None
    return when if when <= as_of else None


def _with_of(corpus, url):
    """(pasta, ref, caminho) da URL <prefixo>/<ref>/<caminho> por um --with, ou None."""
    for prefix, folder in corpus.withs:
        if url.startswith(prefix + "/"):
            ref, _sep, rel = url[len(prefix) + 1:].partition("/")
            while rel.startswith("./"):
                rel = rel[2:]
            return folder, ref, rel
    return None


COMMIT_REF = re.compile(r"[0-9a-fA-F]{7,64}")


def ref_fixed(corpus, url):
    """O ref da URL fixa um commit no clone do --with? Exige a forma de commit e que o commit resolvido comece por ele
    (uma branch ou tag, que andam, não fixam; a mesma regra do kg_trace). Não olha o arquivo: um arquivo ausente num
    commit fixado é not_found, não unpinned. Um rev-parse por URL (cache no corpus)."""
    cache = corpus.__dict__.setdefault("_ref_fixed", {})
    if url not in cache:
        where = _with_of(corpus, url)
        ok = False
        if where is not None and COMMIT_REF.fullmatch(where[1]):
            out = _git(where[0], "rev-parse", "--verify", "--quiet", "--end-of-options", f"{where[1]}^{{commit}}")
            ok = out.returncode == 0 and out.stdout.decode("utf-8").strip().lower().startswith(where[1].lower())
        cache[url] = ok
    return cache[url]


def pinned(corpus, url):
    """O grafo externo foi lido num commit de fato fixado? O load_external marca pinned quando o arquivo saiu do ref numa
    pasta git, e o ref_fixed exige que esse ref seja um commit."""
    info = corpus.external.get(url)
    return bool(info and info.get("pinned")) and ref_fixed(corpus, url)


def head_status(corpus, key):
    """O apoio externo lido no commit fixado, olhado na ponta do clone (o HEAD da pasta do --with): None quando ele não é
    externo fixado; senão (status na ponta, ou "missing-file" ou "missing-node"). O commit fixado diz o que se leu; a ponta
    diz se a origem andou desde então (4.38.0)."""
    url, nid = key
    if not pinned(corpus, url):
        return None
    where = _with_of(corpus, url)
    if where is None:
        return None
    folder, _ref, rel = where
    cache = corpus.__dict__.setdefault("_head_docs", {})
    if url not in cache:
        out = _git(folder, "show", "--end-of-options", f"HEAD:./{rel}")
        doc = None
        if out.returncode == 0:
            _tree, parsed, code = kg_validate.parse_v1(kg_validate.as_source(url, out.stdout.decode("utf-8", "replace")))
            doc = parsed if not code and isinstance(parsed, dict) else None
        cache[url] = doc
    doc = cache[url]
    if doc is None:
        return "missing-file"
    node = next((n for n in doc.get("nodes") or [] if isinstance(n, dict) and n.get("id") == nid), None)
    return "missing-node" if node is None else node.get("status")


def _unresolved_reason(corpus, path):
    """Por que um apoio não está no corpus: no_with (URL sem --with que case), not_found (o --with casou e o arquivo ou o
    nó não estão no commit), not_pinned_url (a fonte não é uma URL com commit, como dono/repo@ref:caminho) ou
    outside_corpus (um caminho que o corpus lido não tem). O unpinned (lido sem fixação real) é dado no revisit."""
    if "://" in path:
        return "not_found" if _with_of(corpus, path) else "no_with"
    if "@" in path and ":" in path.split("@", 1)[1]:
        return "not_pinned_url"
    return "outside_corpus"


def revisit(corpus, as_of, where=()):
    """As decisões vivas que pedem revisão (kg-ssot.revisit/2), pela atenção, com o motivo: pin-changed (desde a 4.40.0,
    um apoio, ou o nó que ele cita pelo kg-node a um salto, que não bate mais com a versão fixada: _pin_failures; a
    fixação que não se confere vai para unresolved: _pin_problems; sem raiz, nada se confere), evidence-due (algo em que
    ela se apoia venceu a cadência), review-due (a própria decisão venceu a cadência) e contested (ela recebe REFUTES e
    segue viva). Ficam à parte, nunca em silêncio: on_event (só reverify_on, porque o evento não tem data), unstamped
    (cadência sem verified_at, que nunca vence) e unresolved (um apoio que não está no corpus, e por isso não foi
    julgado). O apoio refutado ou substituído não é motivo: inferido das arestas, deu 1 aviso útil em 10 no corpus do
    core (o critério pedia 7), e a história dele fica no --decision. Desde a 4.38.0, com --with, o apoio de outro
    repositório é lido no commit fixado da URL; só as decisões do corpus local são julgadas (o grafo externo entra só
    como apoio); o não resolvido traz o motivo (_unresolved_reason); e upstream_changed lista, à parte e sem virar
    motivo, a decisão local cujo apoio externo tem outro status (ou sumiu) na ponta do clone."""
    conds = parse_where(where)
    # o kg-ssot.revisit/2 não tem hint: o zero de um tipo com erro de grafia sairia calado, e por isso é recusa
    for field, edge_type in _unknown_degree_types(corpus, [".".join(c[0]) for c in conds]):
        raise ValueError(_("--where {field}: the edge type {type} does not exist in the internal edges of the corpus, and "
                           "--revisit has no way to warn").format(field=field, type=edge_type))
    items, on_event, unstamped, unresolved, upstream = [], [], [], [], []
    pins = _pin_failures(corpus)  # desde a 4.40.0: a versão fixada que mudou (pin-changed)
    problems = _pin_problems(corpus)  # e a fixação que não se confere, que vai para unresolved
    for key in list(corpus.order):
        node = corpus.nodes[key]
        if node.get("node_type") != "decision" or node.get("status") in HISTORY or key[0] in corpus.external:
            continue
        if conds and not where_matches(node, conds, corpus, key):  # desde a 4.39.0: a fila de um dono (--where owner=X)
            continue
        reasons, seen = [], set()

        def add(reason, target, **extra):
            if (reason, target) not in seen:
                seen.add((reason, target))
                reasons.append({"reason": reason, **extra, **_brief(corpus, target)})
        for src in (s for et, s, _r in corpus.into.get(key, ()) if et == "REFUTES" and _real(s) and s != key):
            if corpus.nodes.get(src, {}).get("status") not in HISTORY:
                add("contested", src)
        for dep, how in _leans_on(corpus, key).items():
            dnode = corpus.nodes.get(dep)
            if dnode is None:
                why = dep[0]
                if how == "provenance.source":  # o motivo vem da fonte escrita, não da chave já resolvida
                    src = (node.get("provenance") or {}).get("source")
                    why = src.strip().split("#", 1)[0].split("?", 1)[0] if isinstance(src, str) else dep[0]
                # o ref que não fixa um commit não se julga, nem para dizer que falta; o arquivo ausente num commit
                # fixado é not_found
                if dep[0] in corpus.external and not ref_fixed(corpus, dep[0]):
                    reason = "unpinned"
                else:
                    reason = _unresolved_reason(corpus, why)
                unresolved.append({"decision": key[1], "file": key[0], "target": f"{dep[0]}#{dep[1]}", "edge_type": how,
                                   "reason": reason})
                continue
            if dep[0] in corpus.external and not pinned(corpus, dep[0]):
                # lido sem fixação real (o commit não está no clone, a pasta não é git, ou o ref é branch): não se julga
                unresolved.append({"decision": key[1], "file": key[0], "target": f"{dep[0]}#{dep[1]}", "edge_type": how,
                                   "reason": "unpinned"})
                continue
            head = head_status(corpus, dep)
            if head is not None and head != dnode.get("status"):
                upstream.append({"decision": key[1], "file": key[0], "support": f"{dep[0]}#{dep[1]}",
                                 "pinned_status": dnode.get("status"), "head_status": head})
            if dnode.get("status") in HISTORY or dnode.get("node_type") == "question":
                continue  # o que caiu ou foi respondido é história, e o --decision a mostra
            # 4.40.0: o apoio cuja fixação não bate mais (forma 1, o node_sha256; ou o sha256 do próprio apoio), ou o
            # nó que o apoio cita pelo kg-node, a um salto, cuja fixação não bate (forma 2, o texto do documento mudou)
            chain = [c for c in (dep, _cited(corpus, dep)) if c is not None]
            hit = next((c for c in chain if c in pins), None)  # o que o check acusa vence o que não se confere
            if hit is not None:
                pin = pins[hit]
                add("pin-changed", dep, edge_type=how, changed=f"{hit[0]}#{hit[1]}", pin=pin["pin"],
                    source=pin["source"], recorded=pin["recorded"], current=pin["current"], gone=pin["gone"])
            else:
                bad = next((c for c in chain if c in problems), None)
                if bad is not None:
                    unresolved.append({"decision": key[1], "file": key[0], "target": f"{bad[0]}#{bad[1]}",
                                       "edge_type": how, "reason": problems[bad]})
            when = _due(dnode, as_of)
            if when:
                add("evidence-due", dep, edge_type=how, due_on=when.isoformat())
        when = _due(node, as_of)
        if when:
            add("review-due", key, due_on=when.isoformat())
        elif kg_validate.parse_duration(node.get("reverify_every")) and kg_validate._as_date(node.get("verified_at")) is None:
            unstamped.append(_brief(corpus, key))
        item = {**_brief(corpus, key), "attention": attention(corpus, key), "reasons": reasons}
        if node.get("reverify_on"):
            item["reverify_on"] = node.get("reverify_on")
        if reasons:
            items.append(item)
        elif node.get("reverify_on"):
            on_event.append({**_brief(corpus, key), "reverify_on": node.get("reverify_on")})
    raw = {(it["file"], it["id"]): attention(corpus, (it["file"], it["id"]), raw=True) for it in items}
    pos = {k: i for i, k in enumerate(by_attention(list(raw), raw))}
    items.sort(key=lambda it: pos[(it["file"], it["id"])])
    res = {"schema_version": REVISIT_SCHEMA, "root": corpus.root, "as_of": as_of.isoformat(),
           "decisions": items, "on_event": on_event, "unstamped": unstamped, "unresolved": unresolved,
           "upstream_changed": upstream}
    if where:
        res["where"] = list(where)
    return res


def _pin_failures(corpus):
    """{chave do nó: falha} dos nós cuja fixação não bate mais (4.40.0): o provenance.node_sha256 que não é o hash do nó
    citado, ou o provenance.sha256 que não é o dos bytes da fonte. É a mesma conferência do kg_trace check, que este
    reusa, para os dois nunca discordarem; cada falha traz o código, a fonte, o hash gravado e o de agora."""
    import kg_trace  # aqui, e não no topo: o kg_trace importa este módulo
    if not corpus.root:
        return {}  # sem raiz (arquivos soltos), não há onde ler as fontes: nada se confere, nada acende
    root = pathlib.Path(corpus.root)
    res, _located = kg_trace.check_schemes(corpus, root, corpus.withs)
    out, files = {}, {}
    for f in res["failures"]:
        key = (f["file"], f["id"])
        prov = corpus.nodes[key]["provenance"]
        # o nó fixado que sumiu do documento: o check dá out-of-range no kg-node, e a versão aprovada não existe mais
        gone = f["code"] == kg_trace.OUT_OF_RANGE and f["scheme"] == "kg-node" and prov.get("node_sha256") is not None
        if f["code"] not in (kg_trace.NODE_SHA_MISMATCH, kg_trace.SHA_MISMATCH) and not gone:
            continue
        gdir = pathlib.PurePosixPath(key[0]).parent.as_posix()
        state, target, data = kg_trace.read_source(prov["source"], gdir, root, corpus.withs, files)
        if f["code"] == kg_trace.SHA_MISMATCH:
            pin, recorded = "sha256", prov.get("sha256")
            current = kg_trace.hashlib.sha256(data).hexdigest() if data is not None else None
        else:
            pin, recorded = "node_sha256", prov.get("node_sha256")
            nid = f["locator"][1:] if f["locator"].startswith("#") else f["locator"]
            current = None
            if data is not None and not gone:
                _t, doc, _c = kg_validate.parse_v1(kg_validate.as_source(target, data.decode("utf-8-sig", "replace")))
                current = kg_validate.node_digest(doc, nid)
        out[key] = {"code": f["code"], "pin": pin, "source": target, "recorded": recorded, "current": current,
                    "gone": gone}
    return out


def _pin_problems(corpus):
    """{chave do nó: motivo} das fixações que não se conferem (4.40.0), para irem a unresolved e nunca sumirem em
    silêncio: pin_malformed (o hash fora da forma de 64 hex minúsculos, ou o node_sha256 sem o esquema kg-node que o
    define) e pin_source_missing (a fonte fixada não existe mais, ou não se lê)."""
    import kg_trace
    if not corpus.root:
        return {}
    root, out, files = pathlib.Path(corpus.root), {}, {}
    for key in corpus.order:
        prov = corpus.nodes[key].get("provenance")
        if not isinstance(prov, dict) or (prov.get("sha256") is None and prov.get("node_sha256") is None):
            continue
        sha, node_sha = prov.get("sha256"), prov.get("node_sha256")
        if any(v is not None and not (isinstance(v, str) and kg_trace.SHA256.fullmatch(v)) for v in (sha, node_sha)) \
                or (node_sha is not None and prov.get("scheme") != "kg-node") or not isinstance(prov.get("source"), str):
            out[key] = "pin_malformed"
            continue
        gdir = pathlib.PurePosixPath(key[0]).parent.as_posix()
        state, _target, _data = kg_trace.read_source(prov["source"], gdir, root, corpus.withs, files)
        if state == "missing":
            out[key] = "pin_source_missing"
        elif state != "ok":  # absolute (URL sem --with), unpinned, outside_root, not_path: o check só conta em skipped
            out[key] = "pin_unchecked"
    return out


def _cited(corpus, key):
    """A chave do nó que o provenance.source de um nó cita pelo esquema kg-node (ARQUIVO#ID), quando o arquivo está no
    corpus; senão None. É o salto do apoio ao documento que ele fixa."""
    prov = corpus.nodes.get(key, {}).get("provenance")
    if not isinstance(prov, dict) or prov.get("scheme") != "kg-node" or not isinstance(prov.get("source"), str):
        return None
    import kg_trace
    if not corpus.root:
        return None
    loc = prov.get("locator").strip() if isinstance(prov.get("locator"), str) else ""
    frag = prov["source"].strip().strip("\"'").strip().partition("#")[2]
    nid = (loc[1:] if loc.startswith("#") else loc) or frag
    gdir = pathlib.PurePosixPath(key[0]).parent.as_posix()
    kind, _target, found = kg_trace.locate_source(prov["source"], gdir, pathlib.Path(corpus.root))
    if not nid or kind != "resolved" or (found[0], nid) not in corpus.nodes:
        return None  # o mesmo caminho que o check resolve: a raiz, a pasta do grafo e a pasta pai dela
    return (found[0], nid)


def _line(b):
    label = (b.get("label") or "")[:90]
    return f"{b['id']}  {b.get('status') or '-'}  {label}" if b.get("found") else f"{b['id']}  {_('(outside the corpus)')}"


def decision_human(res):
    d = res["decision"]
    lines = [_("decision: {line}").format(line=_line(d))]
    if not res["is_decision"]:
        lines.append(_("  (the node is a {kind}, not a decision)").format(kind=d.get("node_type")))
    for key, title in (("replaced", _("  replaced:")), ("replaced_by", _("  replaced by:")),
                       ("refuted_by", _("  refuted by:")), ("supported_by", _("  supported by:")),
                       ("leans_on", _("  rests on:"))):
        if res[key]:
            lines.append(title)
            lines += ["    " + _line(b) + (f"  ({b['edge_type']})" if b.get("edge_type") else "")
                      + (_("  [now {status} at the head of the clone]").format(status=b["head_status"])
                         if b.get("head_status") not in (None, b.get("status")) else "") for b in res[key]]
    return "\n".join(lines)


def revisit_human(res):
    reason = {"pin-changed": _("the version it was pinned to has changed"),
              "evidence-due": _("what it rests on is due for a re-check"),
              "review-due": _("the decision itself is due for review"),
              "contested": _("it is refuted and still live")}
    lines = []
    for d in res["decisions"]:
        lines.append(f"{d['file']}  {d['id']}  " + _("attention {value:g}").format(value=d["attention"]) +
                     f"  {(d.get('label') or '')[:90]}")
        for r in d["reasons"]:
            due = f" ({r['due_on']})" if r.get("due_on") else ""
            lines.append(f"    {reason[r['reason']]}{due}: {r['id']}  {(r.get('label') or '')[:70]}")
            if r["reason"] == "pin-changed" and r.get("gone"):
                lines.append("      " + _("{changed}: the pinned node is no longer in {source}").format(
                    changed=r["changed"], source=r["source"]))
            elif r["reason"] == "pin-changed":
                lines.append("      " + _("{changed}: {pin} {recorded} is now {current}").format(
                    changed=r["changed"], pin=r["pin"], recorded=(r["recorded"] or "-")[:12],
                    current=(r["current"] or _("unreadable"))[:12]))
    lines.append(_("· {n} decision(s) to revisit on {date}; {m} wait for an event (reverify_on)").format(
        n=len(res["decisions"]), date=res["as_of"], m=len(res["on_event"])))
    if res.get("where"):
        lines.append(_("· only the decisions where {where}").format(where=" and ".join(res["where"])))
    if res["unstamped"]:
        lines.append(_("· {n} decision(s) have a cadence but no verified_at, so they never come due: {ids}").format(
            n=len(res["unstamped"]), ids=", ".join(d["id"] for d in res["unstamped"][:10])))
    for u in res.get("upstream_changed", []):
        lines.append(_("· {decision}: what it rests on changed upstream since the pinned commit: {support} was {pinned}, "
                       "now {head}").format(decision=u["decision"], support=u["support"], pinned=u["pinned_status"],
                                            head=u["head_status"]))
    pin_left = [u for u in res["unresolved"] if u.get("reason", "").startswith("pin_")]
    outside = [u for u in res["unresolved"] if u not in pin_left]
    if outside:
        why = collections.Counter(u.get("reason", "outside_corpus") for u in outside)
        lines.append(_("· {n} support(s) are outside the corpus and were not judged ({why}): {ids}").format(
            n=len(outside), why=", ".join(f"{k} {v}" for k, v in sorted(why.items())),
            ids=", ".join(u["target"] for u in outside[:5])))
    if pin_left:  # 4.40.0: o apoio está no corpus, e a fixação dele é que não se confere
        why = collections.Counter(u["reason"] for u in pin_left)
        lines.append(_("· {n} pinned support(s) could not be checked ({why}): {ids}").format(
            n=len(pin_left), why=", ".join(f"{k} {v}" for k, v in sorted(why.items())),
            ids=", ".join(u["target"] for u in pin_left[:5])))
    return "\n".join(lines)


def _word_of(value):
    """O valor do JSON (status, grau) na língua da saída humana; o JSON fica sempre em inglês."""
    return {"complete": _("complete"), "broken": _("broken"), "cycle": _("cycle"), "too_long": _("too long"),
            "strong": _("strong"), "acceptable": _("acceptable"), "weak": _("weak")}.get(value, value)


def chain_human(res):
    lines = []
    for i, p in enumerate(res["paths"], 1):
        status = _word_of(p["status"])
        lines.append(_("chain {n}: {status}").format(n=i, status=status) if len(res["paths"]) > 1 else
                     _("chain: {status}").format(status=status))
        for link in p["links"]:
            conf = "-" if link["confidence"] is None else f"{link['confidence']:g}"
            cls = link["method_class"] or "-"
            miss = "" if link["found"] else "  " + _("(outside the corpus)")
            lines.append("    " + _("{id}  confidence={conf}  method={cls}").format(id=link["id"], conf=conf, cls=cls)
                         + f"{miss}  {(link['label'] or '')[:90]}")
            if link.get("pinned") is False:
                lines.append("      " + _("read from the working tree: the commit in the URL is not in that folder"))
            if link.get("edges_not_followed"):
                lines.append("      " + _("edges not followed, the node declares its provenance: {ids}").format(
                    ids=", ".join(link["edges_not_followed"])))
        w = p["weakest_link"]
        if w["ids"]:
            conf = _("unknown") if w["confidence"] is None else f"{w['confidence']:g}"
            dup = len(set(w["ids"])) < len(w["ids"])  # o mesmo id em dois arquivos: diz o arquivo
            at = [f"{a['file']}#{a['id']}" if dup else a["id"] for a in w["at"]]
            lines.append(_("  weakest link: {conf} at {ids}").format(conf=conf, ids=", ".join(at)))
        if p["origin"]:
            o = p["origin"]
            conf = "-" if o["confidence"] is None else f"{o['confidence']:g}"
            lines.append(_("  origin: {id}, method {cls}, confidence {conf} (a separate axis)").format(
                id=o["id"], cls=o["method_class"] or "-", conf=conf))
            if not o["declared"]:
                lines.append(_("  the origin has no provenance.source: the chain may go on outside what the graph records"))
        lines.append(_("  grade: strict {strict}, lenient {lenient}").format(
            strict=_word_of(p["grade"]["strict"]), lenient=_word_of(p["grade"]["lenient"])))
    if res.get("truncated"):
        lines.append(_("· more than {n} paths: the projection stops there").format(n=MAX_PATHS))
    return "\n".join(lines)


def chains_human(res):
    lines = []
    for item in res["chains"]:
        lines.append(f"== {item['ref']}")
        if item["chain"] is None:
            lines.append("  " + item["error"])
            continue
        lines.append(chain_human(item["chain"]))
        for o in item["origins"]:
            lines.append(_("  status of the origin {id}: {status}").format(id=o["id"], status=o["status"] or "-"))
    for u in res["unreadable"][:5]:
        lines.append(_("UNREADABLE  {file}: {code}").format(file=u["file"], code=u["code"]))
    if len(res["unreadable"]) > 5:
        lines.append(_("UNREADABLE  and {n} more graph(s) (--format json shows the full list)")
                     .format(n=len(res["unreadable"]) - 5))
    done = sum(1 for i in res["chains"] if i["outcome"] == "ok")
    lines.append(_("· {done} of {n} chain(s) projected").format(done=done, n=res["requested"]))
    return "\n".join(lines)


def fold(text):
    """A forma de comparar texto: NFKD sem as marcas de acento, minúsculas pelo casefold, espaço repetido em um.
    «verificação» e «VERIFICACAO» dobram para o mesmo texto (desde a 4.23)."""
    plain = "".join(c for c in unicodedata.normalize("NFKD", text) if not unicodedata.combining(c))
    return " ".join(plain.casefold().split())


def domain_label(raw):
    """O sinônimo que vale no domínio inteiro: literal em texto, kind alt ou hidden, não aposentado (retired false ou
    ausente, e status current ou ausente) e sem escopo de caso. O escopo ilegível conta como caso: falha fechada, a
    mesma regra do kg_vocab.py (que importa esta)."""
    if not isinstance(raw, dict) or not isinstance(raw.get("literal"), str) or not raw["literal"].strip() or \
            raw.get("kind") not in ("alt", "hidden"):
        return False
    if raw.get("retired", False) is not False or raw.get("status", "current") != "current":
        return False
    scope = raw.get("scope")
    return "scope" not in raw or (isinstance(scope, dict) and scope.get("level") == "domain")


def term_forms(corpus, text):
    """O vocabulário que o --text nomeia (desde a 4.23): os termos vivos (status que não é superseded nem refuted) do
    perfil x_term cujo pref ou sinônimo de domínio atual (domain_label), dobrado, é o texto inteiro dobrado, ou cuja
    notation é o texto exato (código é código: sem dobrar caixa). Devolve [{file, id, pref, forms, notation}], com as
    formas dobradas; vazio quando nenhum casa. O nó do termo casa sempre; os outros nós casam por uma forma dobrada ou
    pela notation exata, sempre como palavra inteira, nunca dentro de outra palavra."""
    want = fold(text)
    out = []
    for key in corpus.order:
        node = corpus.nodes[key]
        term = node.get("x_term")
        if not isinstance(term, dict) or not isinstance(term.get("pref"), str) or \
                node.get("status") in ("superseded", "refuted"):
            continue
        forms = [term["pref"]] + [lab["literal"] for lab in (term.get("labels") if isinstance(term.get("labels"), list)
                                                             else []) if domain_label(lab)]
        folded = [f for f in dict.fromkeys(fold(x) for x in forms) if f]
        notation = term["notation"] if isinstance(term.get("notation"), str) and term["notation"].strip() else None
        if want in folded or (notation is not None and text.strip() == notation):
            out.append({"file": key[0], "id": key[1], "pref": term["pref"], "forms": folded, "notation": notation})
    return out


def _word(form):
    """A forma como palavra inteira: sem letra, dígito ou sublinhado colados antes ou depois."""
    return re.compile(r"(?<!\w)" + re.escape(form) + r"(?!\w)")


def _text(node, key):
    v = node.get(key)
    return v if isinstance(v, str) else ""


WHERE_MAX = 10
WHOLE_NUMBER = re.compile(r"0|[1-9][0-9]*")
NOT_OPERATORS = tuple("^*$!<>~|")  # o que sobra no fim da chave depois do operador é um operador que não existe


def _degree_path(path):
    """O caminho é o grau derivado: degree.in, degree.out ou degree.total, com o tipo de aresta opcional depois."""
    return path[0] == "degree" and len(path) in (2, 3) and path[1] in DEGREE_SIDES and all(path)


def _split_condition(item):
    """(chave, operador, valor) de CHAVE=VALOR, CHAVE^=VALOR (começa com) ou CHAVE*=VALOR (contém), 4.43.0. A chave vai até
    o primeiro =, e o operador é o último caractere dela; depois do =, o valor é literal e fica em NFC. Sobrar ^ * $ ! < > ~
    ou | no fim da chave é um operador que não existe (x_n!=12), e daria 0 em silêncio: ValueError. Nenhuma chave real termina
    assim: em 252.109 chaves nos três corpora, medidos em 2026-11-04, só o << de um caso de conformidade que reprova."""
    key, _sep, value = item.partition("=")
    op = key[-1] if key.endswith(("^", "*")) else ""
    key = key[:-1] if op else key
    if key.endswith(NOT_OPERATORS):
        raise ValueError(_("--where {item}: {char} is not an operator: write KEY=VALUE, KEY^=VALUE or KEY*=VALUE")
                         .format(item=repr(item), char=key[-1]))
    return key, op, unicodedata.normalize("NFC", value)


def _text_hit(value, op, wanted):
    """O valor casa o operador de texto? Só texto casa, como o STARTS WITH e o CONTAINS do Cypher: o null, o número e o
    booleano não, e a comparação distingue maiúsculas, em NFC."""
    if not isinstance(value, str):
        return False
    value = unicodedata.normalize("NFC", value)
    return value.startswith(wanted) if op == "^" else wanted in value


def parse_where(items):
    """As condições do --where (4.39.0): cada condição vira (caminho, operador, valor), com o operador de
    _split_condition. A chave é owner, um campo x_* ou um caminho com ponto num x_* (x_raci.responsible), provenance.<chave>
    ou o grau derivado (degree.in.SUPPORTS, só com = e um inteiro); as condições se somam. ValueError: condição quebrada."""
    items = [items] if isinstance(items, str) else list(items or ())  # um texto solto é uma condição só
    if len(items) > WHERE_MAX:
        raise ValueError(_("--where takes at most {max} conditions").format(max=WHERE_MAX))
    conds = []
    for item in items:
        if not isinstance(item, str) or "=" not in item:
            raise ValueError(_("--where {item}: write KEY=VALUE").format(item=repr(item)))
        key, op, value = _split_condition(item)
        path = tuple(key.split("."))
        if not key or any(not part for part in path):
            raise ValueError(_("--where {item}: the key is empty or has an empty part").format(item=repr(item)))
        if not (path == ("owner",) or path[0].startswith("x_") or (path[0] == "provenance" and len(path) > 1)
                or _degree_path(path)):
            raise ValueError(_("--where {item}: the key is owner, an x_* field (x_raci.responsible), provenance.<key> or "
                               "degree.in, degree.out or degree.total, with an optional edge type").format(item=repr(item)))
        if _degree_path(path) and (op or not WHOLE_NUMBER.fullmatch(value)):
            raise ValueError(_("--where {item}: the degree is a count: use = and a whole number (degree.in.SUPPORTS=0)")
                             .format(item=repr(item)))
        conds.append((path, op, value))
    return conds


def parse_presence(items, flag):
    """Os campos do --has e do --missing (4.43.0), como caminhos. Valem para qualquer campo do nó, menos os que começam em
    degree: o grau é derivado e não está no nó, e nenhum grafo dos três corpora tem esse campo (medido em 2026-11-04).
    ValueError: campo quebrado."""
    items = [items] if isinstance(items, str) else list(items or ())
    if len(items) > WHERE_MAX:
        raise ValueError(_("{flag} takes at most {max} fields").format(flag=flag, max=WHERE_MAX))
    out = []
    for item in dict.fromkeys(items):
        path = tuple(item.split(".")) if isinstance(item, str) else ()
        if not path or any(not part for part in path):
            raise ValueError(_("{flag} {item}: the field is empty or has an empty part").format(flag=flag, item=repr(item)))
        if path[0] == "degree":
            raise ValueError(_("{flag} {item}: the degree is derived, not a field of the node: use --where "
                               "degree.in=0").format(flag=flag, item=repr(item)))
        out.append(path)
    return out


def check_due(due, as_of, sort, semantic):
    """A data do --due, ou None sem ele. ValueError: --as-of sem --due, data quebrada, ou outra ordem pedida junto. É
    daqui que a linha de comando e o servidor MCP tiram a mesma recusa, antes de carregar o que o --semantic pede."""
    if not due:
        if as_of is not None:
            raise ValueError(_("--as-of goes with --revisit or --due"))
        return None
    if sort != "corpus" or semantic is not None:
        raise ValueError(_("--due orders from the most overdue: it does not combine with --sort impact or attention, or "
                           "with --semantic"))
    if as_of is None:
        return datetime.date.today()
    day = kg_validate.iso_date(as_of)
    if day is None:
        raise ValueError(_("--as-of {value}: the date must be YYYY-MM-DD").format(value=repr(as_of)))
    return day


def _scalar_text(value):
    """O texto com que um escalar do nó casa o VALOR do --where: o texto como está, true/false, null ou o número."""
    if isinstance(value, bool):
        return "true" if value else "false"
    if value is None:
        return "null"
    if isinstance(value, str):
        return unicodedata.normalize("NFC", value)  # "sessão" em NFD casa owner=sessão
    if isinstance(value, (int, float)):
        return str(value)
    return None


GROUP_BY_MAX = 5
GROUP_FIELDS = ("file", "node_type", "status", "plane", "layer", "owner", "label", "narrative")
GROUPS_VERSION = "kg-ssot.groups/2"
EDGES_VERSION = "kg-ssot.edges/1"
EDGE_TOP = ("edge_type", "scope", "file")
END_FIELDS = ("id", "file", "found", "node_type", "status", "plane", "layer", "owner")


def _node_path_ok(path):
    """O caminho é um campo de nó que se agrupa: um dos GROUP_FIELDS, um x_*, provenance.<chave> ou o grau derivado."""
    return ((len(path) == 1 and path[0] in GROUP_FIELDS) or path[0].startswith("x_")
            or (path[0] == "provenance" and len(path) > 1) or _degree_path(path))


def _edge_path_ok(path):
    """O caminho é um campo de aresta: edge_type, scope, file, meta.<chave> do grafo que a declara, ou from.<campo> e
    to.<campo>, com o campo da ponta em END_FIELDS, um x_* ou provenance.<chave>."""
    if len(path) == 1:
        return path[0] in EDGE_TOP
    if path[0] == "meta":
        return True
    if path[0] in ("from", "to"):
        rest = path[1:]
        return ((len(rest) == 1 and rest[0] in END_FIELDS) or rest[0].startswith("x_")
                or (rest[0] == "provenance" and len(rest) > 1))
    return False


def parse_group_by(items, flag="--group-by", edges=False):
    """Os campos do --group-by (4.41.0) e do --count-distinct (4.42.0). Nos nós: file, node_type, status, plane, layer,
    owner, label, narrative (o texto inteiro), um x_* (com ponto para a chave aninhada, como no --where),
    provenance.<chave>, meta.<chave> (o meta do grafo do nó) ou o grau derivado (degree.in, degree.out, degree.total, com
    o tipo opcional). Nas arestas (--edges): os de _edge_path_ok. ValueError: campo fora disso."""
    items = [items] if isinstance(items, str) else list(items or ())
    if len(items) > GROUP_BY_MAX:
        raise ValueError(_("{flag} takes at most {max} fields").format(flag=flag, max=GROUP_BY_MAX))
    out = []
    for item in items:
        path = tuple(item.split(".")) if isinstance(item, str) else ()
        ok = bool(path) and not any(not part for part in path) and (
            _edge_path_ok(path) if edges else (_node_path_ok(path) or (path[0] == "meta" and len(path) > 1)))
        if not ok:
            raise ValueError((_("{flag} {item}: the edge field is edge_type, scope, file, meta.<key>, or from.<field> "
                                "and to.<field> (id, file, found, node_type, status, plane, layer, owner, an x_* field "
                                "or provenance.<key>)") if edges else
                              _("{flag} {item}: the field is file, node_type, status, plane, layer, owner, label, "
                                "narrative, an x_* field (x_raci.responsible), provenance.<key>, meta.<key>, or "
                                "degree.in, degree.out or degree.total, with an optional edge type")).format(
                flag=flag, item=repr(item)))
        if item in out:
            raise ValueError(_("{flag} {item}: the field is repeated").format(flag=flag, item=repr(item)))
        out.append(item)
    return out


def _walk(cur, parts):
    for part in parts:
        if not isinstance(cur, dict) or part not in cur:
            return None
        cur = cur[part]
    return cur


def group_value(corpus, key, field):
    """O valor do nó no campo do grupo: o que falta é None; o escalar sai como está (a data, em ISO); a lista ou o mapa,
    como o texto JSON dele, de modo que cada nó cai num grupo só."""
    if field == "file":
        return key[0]
    path = field.split(".")
    if path[0] == "meta":
        return _group_norm(_walk(corpus.metas.get(key[0]), path[1:]))
    if _degree_path(path):
        return corpus.internal_degree(key, path[1], path[2] if len(path) == 3 else None)
    return _group_norm(_walk(corpus.nodes[key], path))


def edge_raw(corpus, edge, field):
    """O valor cru do campo de uma aresta, antes da normalização: a ponta que não existe no corpus tem os campos de nó
    nulos, mas o id e o file dela são os da referência, e found diz se ela existe."""
    path = field.split(".")
    if len(path) == 1:
        return edge[field]
    if path[0] == "meta":
        return _walk(corpus.metas.get(edge["file"]), path[1:])
    end, rest = edge[path[0]], path[1:]
    if rest == ["id"]:
        return end[1]
    if rest == ["file"]:
        return end[0]
    if rest == ["found"]:  # a origem que é o grafo inteiro existe se o grafo existe, como no query/1
        return end[0] in corpus.files if end[1] is None else end in corpus.nodes
    node = corpus.nodes.get(end) if end[1] is not None else None
    return _walk(node, rest) if node is not None else None


def edge_value(corpus, edge, field):
    return _group_norm(edge_raw(corpus, edge, field))


def _group_norm(cur):
    """A forma do valor na chave do grupo (4.41.0): o escalar como está, 1.0 como 1, a data em ISO, a lista ou o mapa
    como o texto JSON dele."""
    cur = _plain(cur)
    if isinstance(cur, float) and cur.is_integer():
        cur = int(cur)  # 1.0 e 1 são o mesmo valor JSON: a chave não depende de qual veio primeiro no corpus
    if isinstance(cur, (datetime.date, datetime.datetime)):
        return cur.isoformat()
    if isinstance(cur, (dict, list)):
        return json.dumps(cur, ensure_ascii=False, sort_keys=True,
                          default=lambda v: v.isoformat() if isinstance(v, (datetime.date, datetime.datetime)) else str(v))
    if cur is None or isinstance(cur, (str, bool, int, float)):
        return unicodedata.normalize("NFC", cur) if isinstance(cur, str) else cur
    return str(cur)


def aggregate(items, value, fields, distinct=(), min_count=None):
    """Os grupos dos itens: [{key: {campo: valor}, count}], da contagem maior para a menor e, no empate, pela chave (o
    null antes do texto). value(item, campo) dá o valor normalizado. Com distinct, a contagem é a das combinações
    distintas desses campos no grupo, e a combinação com algum null não conta (o count(DISTINCT) do Cypher ignora o
    null); sem ele, a das linhas, e o grupo null conta (o count(*)). min_count deixa só os grupos a partir dele (o
    HAVING do SPARQL)."""
    # o booleano leva a marca do tipo: no Python True == 1 e os dois têm o mesmo hash, e o Counter fundiria x: true com
    # x: 1, que o --where separa (achado do Elenxo da 4.41.0)
    tag = lambda v: (type(v) is bool, v)  # noqa: E731
    counts, seen = collections.Counter(), collections.defaultdict(set)
    for it in items:
        k = tuple((type(v) is bool, v) for v in (value(it, f) for f in fields))
        if distinct:
            vals = tuple(value(it, f) for f in distinct)
            counts[k] += 0
            if all(v is not None for v in vals):
                seen[k].add(tuple(tag(v) for v in vals))
        else:
            counts[k] += 1
    if distinct:
        counts = collections.Counter({k: len(seen[k]) for k in counts})
    rows = [(k, n) for k, n in counts.items() if min_count is None or n >= min_count]
    order = sorted(rows, key=lambda kv: (-kv[1], [(v is not None, b, str(v), type(v).__name__) for b, v in kv[0]]))
    return [{"key": dict(zip(fields, (v for _b, v in values))), "count": n} for values, n in order]


def group_counts(corpus, hits, fields, distinct=(), min_count=None):
    return aggregate(hits, lambda k, f: group_value(corpus, k, f), fields, distinct, min_count)


def where_matches(node, conds, corpus=None, key=None):
    """O nó casa todas as condições? A chave que falta não casa; um escalar casa por igualdade de texto ou pelo operador,
    e uma lista, quando algum escalar dela casa. O grau derivado se lê do corpus, pela chave do nó."""
    for path, op, value in conds:
        if _degree_path(path):
            if str(corpus.internal_degree(key, path[1], path[2] if len(path) == 3 else None)) != value:
                return False
            continue
        cur = node
        for part in path:
            if not isinstance(cur, dict) or part not in cur:
                return False
            cur = cur[part]
        found = [cur] if not isinstance(cur, list) else cur
        if not any(_text_hit(v, op, value) if op else _scalar_text(v) == value for v in found):
            return False
    return True


def matches(node, key, f):
    if f["ids"] and key[1] not in f["ids"]:
        return False
    if f["id_prefix"] and not key[1].startswith(f["id_prefix"]):
        return False
    for field in ("node_type", "status", "plane", "layer"):
        if f[field] is not None and node.get(field) != f[field]:
            return False
    if f["file"] and f["file"] not in key[0]:
        return False
    if f["text"]:
        raw = _text(node, "label") + ("\n" + _text(node, "narrative") if f["in_narrative"] else "")
        hay = fold(raw)
        if not all(w in hay for w in fold(f["text"]).split()) and key not in f.get("terms", ()) and \
                not any(rx.search(hay) for rx in f.get("forms", ())) and \
                not any(rx.search(raw) for rx in f.get("notations", ())):  # o termo nomeado e as suas formas também
            return False
    if f["verified_before"] is not None:
        day = kg_validate.iso_date(node.get("verified_at")) if isinstance(node.get("verified_at"), str) else None
        if day is not None and day >= f["verified_before"]:
            return False
    if f.get("where") and not where_matches(node, f["where"], f.get("corpus"), key):
        return False
    if any(_walk(node, path) is None for path in f.get("has", ())):  # o que falta e o null são o mesmo: faltam
        return False
    if any(_walk(node, path) is not None for path in f.get("missing", ())):
        return False
    if f.get("due") is not None and _due(node, f["due"]) is None:
        return False
    return True


def _unknown_degree_types(corpus, fields):
    """Os (campo, tipo) de degree.<lado>.<tipo> cujo tipo nenhuma aresta interna do corpus tem."""
    known = {e["edge_type"] for e in corpus.edges if e["scope"] == "internal"}
    out = []
    for field in dict.fromkeys(fields):
        path = field.split(".")
        if _degree_path(path) and len(path) == 3 and path[2] not in known:
            out.append((field, path[2]))
    return out


def _degree_hint(corpus, fields):
    """O aviso do tipo de aresta que nenhuma aresta interna tem: degree.in.TIPO dá 0, e o zero de um erro de grafia não
    pode passar por "não há"."""
    notes = [_("{field}: the edge type {type} does not exist in the internal edges of the corpus, so it counts 0")
            .format(field=field, type=edge_type) for field, edge_type in _unknown_degree_types(corpus, fields)]
    if any(field == "degree" or field.startswith("degree.") for field in fields):  # achado da curadoria: 0 não é "não há"
        notes.append(_("the degree counts only the internal edges of each node's own graph; an edge from another graph "
                       "does not count: see --edges --where scope=external"))
    return notes


def _presence_hint(corpus, flag, paths):
    """O aviso do caminho do --has ou do --missing que nenhum nó do corpus tem com valor: o --has daria 0 e o --missing, o
    corpus inteiro, e o erro de digitação não pode passar por resposta."""
    return [_("{flag} {field}: no node of the corpus has this field with a value; check the spelling")
            .format(flag=flag, field=".".join(path)) for path in paths
            if all(_walk(corpus.nodes[k], path) is None for k in corpus.order)]


def _end_view(corpus, key, ref):
    if key[1] is None:  # a origem ausente de uma aresta externa: o grafo inteiro
        return {"file": key[0], "id": None, "label": None, "external": False, "found": True}
    node = corpus.nodes.get(key)
    label = _text(node, "label") if node else None
    if label is not None and len(label) > END_LABEL_MAX:
        label = label[:END_LABEL_MAX - 1] + "…"
    return {"file": key[0], "id": key[1], "label": label,
            "external": ref is not None and kg_validate.is_external(ref), "found": node is not None}


def _plain(v):
    """O valor como JSON: o .nan/.inf do YAML (kg_validate.NonFinite) sai como o texto dele, sem derrubar a saída."""
    if isinstance(v, kg_validate.NonFinite):
        return v.text
    if isinstance(v, dict):
        return {k: _plain(x) for k, x in v.items()}
    if isinstance(v, list):
        return [_plain(x) for x in v]
    return v


def project(corpus, key, narrative=False, fields=()):
    """O nó como a consulta o entrega: os campos do contrato que interessam a quem lê e as arestas resolvidas. fields:
    padrões glob de chaves do nó (x_*, owner) que saem em extra, com o valor como está no grafo."""
    node = corpus.nodes[key]
    out = {"file": key[0], "id": key[1], "label": _text(node, "label") or None}
    for field in NODE_FIELDS:
        out[field] = node.get(field) if isinstance(node.get(field), (str, int, float)) and \
            not isinstance(node.get(field), bool) else None
    if narrative:
        out["narrative"] = _text(node, "narrative") or None
    if fields:
        out["extra"] = {k: _plain(v) for k, v in node.items() if any(fnmatch.fnmatchcase(k, pat) for pat in fields)}
    out["out"] = [{"edge_type": et, "to": _end_view(corpus, other, ref)} for et, other, ref in corpus.out[key]]
    out["in"] = [{"edge_type": et, "from": _end_view(corpus, other, ref)} for et, other, ref in corpus.into[key]]
    return out


def query(corpus, *, ids=(), id_prefix=None, node_type=None, status=None, plane=None, layer=None, file=None, text=None,
          in_narrative=False, open_only=False, verified_before=None, around=None, depth=1, edge_types=(),
          direction="both", sort="corpus", limit=50, cursor=None, narrative=False, fields=(), max_bytes=None,
          semantic=None, ranker=None, where=(), group_by=(), count_distinct=(), min_count=None, due=False, as_of=None,
          has=(), missing=()):
    """A consulta inteira, no formato kg-ssot.query/1, ou /2 com due. ValueError: pedido quebrado. max_bytes: o teto da página em bytes
    de JSON (o servidor MCP passa o dele); a página corta antes do limit quando o passa, sempre com ao menos um nó, e o
    next_cursor continua de onde ela parou.
    semantic (desde a 4.26): a pergunta que o ranker (kg_vector.Ranker) ordena por semelhança, sobre os nós que passam
    nos outros filtros. Sozinho, a ordem é a do vetor; com text, a lista do texto (na ordem do corpus) e a do vetor se
    fundem por RRF (k=60), com o empate pela posição no vetor. As duas listas são completas, e o limit só pagina.
    due (desde a 4.43.0): só os nós com verified_at + reverify_every vencidos até as_of (o padrão é hoje), do mais atrasado
    para o menos, com due_on e days_late; a conta é a do kg_validate --due. has e missing: os campos que o nó tem de ter
    ou não ter, e o null conta como faltar."""
    if not 1 <= limit <= MAX_LIMIT:
        raise ValueError(_("--limit must be between 1 and {max}").format(max=MAX_LIMIT))
    group_by = parse_group_by(group_by)
    count_distinct, min_count = _check_counting(group_by, count_distinct, min_count, edges=False)
    if group_by and (semantic is not None or cursor is not None):
        raise ValueError(_("--group-by counts every node the filters find: it does not combine with --semantic or "
                           "--cursor"))
    if depth < 0:
        raise ValueError(_("--depth must be 0 or more"))
    if direction not in ("out", "in", "both"):
        raise ValueError(_("--direction must be out, in or both"))
    if sort not in ("corpus", "impact", "attention"):
        raise ValueError(_("--sort must be corpus, impact or attention"))
    offset = 0
    if cursor is not None:
        if not (isinstance(cursor, str) and cursor.isascii() and cursor.isdigit() and len(cursor) <= 9):
            raise ValueError(_("--cursor {cursor} is invalid: use the next_cursor of a previous query").format(cursor=repr(cursor)))
        offset = int(cursor)
    f = {"ids": set(ids), "id_prefix": id_prefix, "node_type": node_type, "status": "open" if open_only else status,
         "plane": plane, "layer": layer, "file": file, "text": text, "in_narrative": in_narrative,
         "verified_before": verified_before, "where": parse_where(where), "corpus": corpus,
         "has": parse_presence(has, "--has"), "missing": parse_presence(missing, "--missing"),
         "due": check_due(due, as_of, sort, semantic)}
    both = [".".join(path) for path in f["has"] if path in f["missing"]]
    if both:
        raise ValueError(_("--has and --missing ask for opposite things about {fields}: no node has and lacks a field")
                         .format(fields=", ".join(both)))
    expanded = term_forms(corpus, text) if text else []
    f["forms"] = [_word(form) for form in dict.fromkeys(form for t in expanded for form in t["forms"])]
    f["notations"] = [_word(n) for n in dict.fromkeys(t["notation"] for t in expanded if t["notation"])]
    f["terms"] = {(t["file"], t["id"]) for t in expanded}
    if open_only and status not in (None, "open"):
        raise ValueError(_("--open and --status ask for different statuses"))
    keys = corpus.order
    if around is not None:
        reach = neighborhood(corpus, resolve(corpus, around), depth, set(edge_types), direction)
        keys = [k for k in keys if k in reach]
    hits = [k for k in keys if matches(corpus.nodes[k], k, f)]
    text_hits, ranks, sem = hits, {}, None
    if semantic is not None:
        if not isinstance(semantic, str) or not semantic.strip():
            raise ValueError(_("--semantic needs the question as text"))
        if sort != "corpus":
            raise ValueError(_("--semantic orders by similarity: it does not combine with --sort impact or attention"))
        if ranker is None:
            raise ValueError(_("--semantic needs the vector ranker (kg_vector.py)"))
        base = [k for k in keys if matches(corpus.nodes[k], k, dict(f, text=None))]  # os outros filtros valem
        vector, used = ranker(corpus, base, semantic)
        vpos = {k: i for i, k in enumerate(vector, 1)}
        if text:
            tpos = {k: i for i, k in enumerate(hits, 1)}
            score = {k: 1.0 / (RRF_K + vpos[k]) + (1.0 / (RRF_K + tpos[k]) if k in tpos else 0.0) for k in vector}
            hits = sorted(vector, key=lambda k: (-score[k], vpos[k]))
            ranks = {k: {"text": tpos.get(k), "vector": vpos[k], "rrf": round(score[k], 9)} for k in hits}
        else:
            hits = vector
            ranks = {k: {"text": None, "vector": vpos[k], "rrf": None} for k in hits}
        sem = {"mode": "hybrid" if text else "semantic", "question": semantic, "k": RRF_K, **used}
        if text:  # o total do híbrido são todos os candidatos; quantos casam o --text sai à parte
            sem["text_matches"] = len(text_hits)
    grouped = group_counts(corpus, hits, group_by, count_distinct, min_count) if group_by else None
    if grouped is not None:
        hits_for_page = hits
        hits = hits[:0]  # os grupos dispensam a página: nada é projetado
    if sort == "impact":
        rank = {k: i for i, k in enumerate(corpus.order)}

        def impact(k):
            v = corpus.nodes[k].get("impact")
            return v if isinstance(v, (int, float)) and not isinstance(v, bool) else float("-inf")
        hits.sort(key=lambda k: (-impact(k), rank[k]))
    elif f["due"] is not None:  # a ordem é estável: na mesma data, a do corpus
        hits.sort(key=lambda k: _due(corpus.nodes[k], f["due"]))
    elif sort == "attention":
        att = {k: attention(corpus, k) for k in hits}
        hits = by_attention(hits, {k: attention(corpus, k, raw=True) for k in hits})
    page, size = [], 0
    for k in hits[offset:offset + limit]:
        node = project(corpus, k, narrative, fields)
        if sort == "attention":
            node["attention"] = att[k]
        if sem is not None:
            node["rank"] = ranks[k]
        if f["due"] is not None:
            when = _due(corpus.nodes[k], f["due"])
            node["due_on"], node["days_late"] = when.isoformat(), (f["due"] - when).days
        size += len(json.dumps(node, ensure_ascii=False))
        if page and max_bytes is not None and size > max_bytes:
            break
        page.append(node)
    end = offset + len(page)
    nxt = end if end < len(hits) else None
    request = {"ids": sorted(f["ids"]), "id_prefix": id_prefix, "node_type": node_type, "status": f["status"],
               "plane": plane, "layer": layer, "file": file, "text": text, "in_narrative": in_narrative,
               "verified_before": verified_before.isoformat() if verified_before else None, "around": around,
               "depth": depth if around is not None else None, "edge_types": sorted(set(edge_types)) if around else [],
               "direction": direction if around is not None else None, "sort": sort, "limit": limit, "cursor": cursor,
               "fields": list(fields)}
    if semantic is not None:
        request["semantic"] = semantic
    if where:
        request["where"] = list(where)
    if f["has"]:
        request["has"] = [".".join(path) for path in f["has"]]
    if f["missing"]:
        request["missing"] = [".".join(path) for path in f["missing"]]
    if f["due"] is not None:
        request["due"], request["as_of"] = True, f["due"].isoformat()
    unreadable = [u for u in corpus.unreadable if not file or file in u["file"]]
    if grouped is not None:
        request["group_by"] = list(group_by)
        if count_distinct:
            request["count_distinct"] = list(count_distinct)
        if min_count is not None:
            request["min_count"] = min_count
        hits = hits_for_page
    res = {"schema_version": DUE_VERSION if f["due"] is not None else SCHEMA_VERSION, "root": corpus.root, "query": request, "graphs": len(corpus.files),
           "unreadable": unreadable, "total": len(hits), "next_cursor": str(nxt) if nxt is not None else None,
           "nodes": page}
    if sem is not None:
        res["semantic"] = sem
    if text:
        res["expanded"] = expanded
        if not text_hits:  # o zero de uma busca por texto não pode passar por "não há"
            only_text = {k: f[k] for k in ("text", "in_narrative", "forms", "notations", "terms")}
            loose = {"ids": set(), "id_prefix": None, "node_type": None, "status": None, "plane": None, "layer": None,
                     "file": None, "verified_before": None, **only_text}
            if any(matches(corpus.nodes[k], k, loose) for k in corpus.order):
                res["hint"] = _("nodes match --text, but not the other filters: the zero comes from them")
            else:
                res["hint"] = (_("no node has every word of --text in its label: try fewer words, --in-narrative, or a "
                                 "term of the vocabulary (kg_vocab.py lookup)") if not in_narrative else
                               _("no node has every word of --text in its label or narrative: try fewer words, or a "
                                 "term of the vocabulary (kg_vocab.py lookup)"))
            if sem is not None:
                res["hint"] += _("; the order comes from --semantic alone")
    notes = _degree_hint(corpus, [".".join(c[0]) for c in f["where"]] + list(group_by) + list(count_distinct))
    notes += _presence_hint(corpus, "--has", f["has"]) + _presence_hint(corpus, "--missing", f["missing"])
    if f["due"] is not None:
        rest = dict(f, due=None)
        never = sum(1 for k in keys if kg_validate.parse_duration(corpus.nodes[k].get("reverify_every"))
                    and kg_validate._as_date(corpus.nodes[k].get("verified_at")) is None and matches(corpus.nodes[k], k, rest))
        if never:
            notes.append(_("{n} node(s) have reverify_every without a readable verified_at, so they never come due: "
                           "kg_validate --due lists them").format(n=never))
    if notes:
        res["hint"] = "; ".join(([res["hint"]] if res.get("hint") else []) + notes)
    if grouped is not None:
        out = {"schema_version": GROUPS_VERSION, "root": res["root"], "query": request, "graphs": res["graphs"],
               "unreadable": unreadable, "subject": "nodes", "counted": _counted(count_distinct),
               "total": res["total"], "groups": grouped}
        if res.get("hint"):
            out["hint"] = res["hint"]
        return out
    return res


def _counted(distinct):
    return "distinct:" + ",".join(distinct) if distinct else "rows"


def _check_counting(group_by, count_distinct, min_count, edges):
    """O --count-distinct e o --min-count (4.42.0) só valem com --group-by; o mínimo é um inteiro a partir de 1."""
    count_distinct = parse_group_by(count_distinct, "--count-distinct", edges)
    if (count_distinct or min_count is not None) and not group_by:
        raise ValueError(_("--count-distinct and --min-count count the groups of --group-by: give it too"))
    if min_count is not None and (isinstance(min_count, bool) or not isinstance(min_count, int) or min_count < 1):
        raise ValueError(_("--min-count must be an integer from 1"))
    return count_distinct, min_count


def parse_edge_where(items):
    """As condições do --where com --edges: (campo, operador, valor), com os campos de aresta de _edge_path_ok e os
    operadores de _split_condition."""
    items = [items] if isinstance(items, str) else list(items or ())
    if len(items) > WHERE_MAX:
        raise ValueError(_("--where takes at most {max} conditions").format(max=WHERE_MAX))
    conds = []
    for item in items:
        if not isinstance(item, str) or "=" not in item:
            raise ValueError(_("--where {item}: write KEY=VALUE").format(item=repr(item)))
        key, op, value = _split_condition(item)
        parse_group_by([key], "--where", edges=True)
        conds.append((key, op, value))
    return conds


def edge_matches(corpus, edge, conds):
    """A aresta casa todas as condições? Como no --where de nós: o escalar casa pelo texto, a lista quando algum item
    casa, e o que falta (null) só casa com o texto null. O operador lê o valor antes do _plain, que daria ao .nan a forma
    de um texto, e o null não casa com ele."""
    for key, op, value in conds:
        raw = edge_raw(corpus, edge, key)
        cur = raw if op else _plain(raw)
        found = cur if isinstance(cur, list) else [cur]
        if not any(_text_hit(v, op, value) if op else _scalar_text(v) == value for v in found):
            return False
    return True


def _edge_end_view(corpus, end):
    node = corpus.nodes.get(end) if end[1] is not None else None
    return {"file": end[0], "id": end[1], "found": node is not None if end[1] is not None else end[0] in corpus.files,
            "node_type": _text(node, "node_type") or None if node else None,
            "status": _text(node, "status") or None if node else None}


def edge_query(corpus, *, where=(), file=None, group_by=(), count_distinct=(), min_count=None, limit=50, cursor=None,
               max_bytes=None):
    """As arestas como sujeito (4.42.0): a lista paginada kg-ssot.edges/1 ou, com group_by, os grupos kg-ssot.groups/2.
    As arestas são as internas (edges) e as externas (external_edges) dos grafos do corpus, na ordem do corpus.
    ValueError: pedido quebrado."""
    if not 1 <= limit <= MAX_LIMIT:
        raise ValueError(_("--limit must be between 1 and {max}").format(max=MAX_LIMIT))
    group_by = parse_group_by(group_by, edges=True)
    count_distinct, min_count = _check_counting(group_by, count_distinct, min_count, edges=True)
    conds = parse_edge_where(where)
    if group_by and cursor is not None:
        raise ValueError(_("--group-by counts every edge the filters find: it does not combine with --cursor"))
    offset = 0
    if cursor is not None:
        if not (isinstance(cursor, str) and cursor.isascii() and cursor.isdigit() and len(cursor) <= 9):
            raise ValueError(_("--cursor {cursor} is invalid: use the next_cursor of a previous query").format(cursor=repr(cursor)))
        offset = int(cursor)
    hits = [e for e in corpus.edges if (not file or file in e["file"]) and edge_matches(corpus, e, conds)]
    request = {"edges": True, "file": file, "where": [f"{k}{op}={v}" for k, op, v in conds], "limit": limit,
               "cursor": cursor}
    unreadable = [u for u in corpus.unreadable if not file or file in u["file"]]
    base = {"root": corpus.root, "query": request, "graphs": len(corpus.files), "unreadable": unreadable}
    if group_by:
        request["group_by"] = list(group_by)
        if count_distinct:
            request["count_distinct"] = list(count_distinct)
        if min_count is not None:
            request["min_count"] = min_count
        groups = aggregate(hits, lambda e, f: edge_value(corpus, e, f), group_by, count_distinct, min_count)
        return {"schema_version": GROUPS_VERSION, **base, "subject": "edges", "counted": _counted(count_distinct),
                "total": len(hits), "groups": groups}
    page, size = [], 0
    for e in hits[offset:offset + limit]:
        view = {"edge_type": e["edge_type"] if isinstance(e["edge_type"], str) else None, "scope": e["scope"],
                "file": e["file"], "from": _edge_end_view(corpus, e["from"]), "to": _edge_end_view(corpus, e["to"])}
        size += len(json.dumps(view, ensure_ascii=False))
        if page and max_bytes is not None and size > max_bytes:
            break
        page.append(view)
    end = offset + len(page)
    return {"schema_version": EDGES_VERSION, **base, "total": len(hits),
            "next_cursor": str(end) if end < len(hits) else None, "edges": page}


def edges_human(res):
    lines = []
    for e in res["edges"]:
        fr, to = e["from"], e["to"]
        src = _("(the whole graph)") if fr["id"] is None else \
            (f"{fr['file']}#{fr['id']}" if fr["file"] != e["file"] else fr["id"])
        dst = f"{to['file']}#{to['id']}" if to["file"] != e["file"] else str(to["id"])
        miss = "" if to["found"] else "  " + _("(outside the corpus)")
        lines.append(f"{e['file']}  {src} -{e['edge_type']}-> {dst}  [{e['scope']}]{miss}")
    for u in res["unreadable"][:5]:
        lines.append(_("UNREADABLE  {file}: {code}").format(file=u["file"], code=u["code"]))
    if res["query"].get("where"):
        lines.append(_("· only the edges where {where}").format(where=" and ".join(res["query"]["where"])))
    shown = len(res["edges"])
    first = int(res["query"]["cursor"] or 0)
    tail = _("; next page: --cursor {cursor}").format(cursor=res["next_cursor"]) if res["next_cursor"] else ""
    lines.append(_("· {total} edge(s) in {graphs} graph(s)").format(total=res["total"], graphs=res["graphs"])
                 + (_(", showing {first} to {last}").format(first=first + 1, last=first + shown) if shown else "")
                 + tail)
    return "\n".join(lines)


def _group_text(v):
    """O valor do grupo na saída humana sem ambiguidade: o que não é texto sai em JSON (true, 1, null), e o texto sai
    como está, salvo quando se confundiria com um deles ou tem quebra de linha, e aí sai entre aspas."""
    if not isinstance(v, str):
        return json.dumps(v, ensure_ascii=False)
    try:
        json.loads(v)  # qualquer JSON, inclusive um texto que já vem entre aspas
        looks = True
    except ValueError:
        looks = False
    if looks or not v or v != v.strip() or "  " in v or any(unicodedata.category(c)[0] == "C" for c in v):
        return json.dumps(v, ensure_ascii=False)
    return v


def _narrowed(request):
    """As linhas que dizem o recorte do --has, do --missing e do --due, para o total não passar pelo do corpus inteiro."""
    lines = []
    if request.get("has"):
        lines.append(_("· only the nodes that have {fields}").format(fields=", ".join(request["has"])))
    if request.get("missing"):
        lines.append(_("· only the nodes that lack {fields}").format(fields=", ".join(request["missing"])))
    if request.get("due"):
        lines.append(_("· only the nodes due by {as_of}, the most overdue first").format(as_of=request["as_of"]))
    return lines


def groups_human(res):
    lines = []
    for g in res["groups"]:
        key = "  ".join(f"{k}={_group_text(v)}" for k, v in g["key"].items())
        lines.append(f"{g['count']:>6}  {key}")
    for u in res["unreadable"][:5]:
        lines.append(_("UNREADABLE  {file}: {code}").format(file=u["file"], code=u["code"]))
    if len(res["unreadable"]) > 5:
        lines.append(_("UNREADABLE  and {n} more graph(s) (--format json shows the full list)")
                     .format(n=len(res["unreadable"]) - 5))
    if res.get("hint"):
        lines.append("· " + res["hint"])
    edges = res.get("subject") == "edges"
    if res["query"].get("where"):
        lines.append((_("· only the edges where {where}") if edges else _("· only the nodes where {where}")).format(
            where=" and ".join(res["query"]["where"])))
    lines.extend(_narrowed(res["query"]))
    if res["counted"] != "rows":
        lines.append(_("· the count is of distinct {fields}").format(fields=", ".join(res["counted"].split(":", 1)[1].split(","))))
    if res["query"].get("min_count") is not None:
        lines.append(_("· only the groups with a count from {n}").format(n=res["query"]["min_count"]))
    lines.append((_("· {total} edge(s) in {graphs} graph(s), in {groups} group(s) by {fields}") if edges else
                  _("· {total} node(s) in {graphs} graph(s), in {groups} group(s) by {fields}")).format(
        total=res["total"], graphs=res["graphs"], groups=len(res["groups"]), fields=", ".join(res["query"]["group_by"])))
    return "\n".join(lines)


def human(res):
    lines = []
    for n in res["nodes"]:
        tag = "/".join(str(n[k]) for k in ("node_type", "status", "plane") if n[k] is not None)
        imp = f" imp={n['impact']}" if n["impact"] is not None else ""
        label = (n["label"] or "").replace("\n", " ")
        r = n.get("rank")
        pos = "" if r is None else (f"  [text={r['text'] if r['text'] is not None else '-'} vector={r['vector']}]"
                                    if res["semantic"]["mode"] == "hybrid" else f"  [vector={r['vector']}]")
        late = "" if "due_on" not in n else "  " + _("[due {due_on}, {days} day(s) late]").format(
            due_on=n["due_on"], days=n["days_late"])
        lines.append(f"{n['file']}  {n['id']}  {tag}{imp}{pos}{late}  {label[:160]}")
        for e in n["out"]:
            t = e["to"]
            where = "" if t["file"] == n["file"] else f"{t['file']}#"
            miss = "" if t["found"] else "  " + _("(outside the corpus)")
            lines.append(f"    → {e['edge_type']} {where}{t['id']}{miss}  {(t['label'] or '')[:100]}")
        for e in n["in"]:
            s = e["from"]
            where = "" if s["file"] == n["file"] else f"{s['file']}#"
            src = _("{file} (the whole graph)").format(file=s["file"]) if s["id"] is None else where + s["id"]
            miss = "" if s["found"] else "  " + _("(outside the corpus)")
            lines.append(f"    ← {e['edge_type']} {src}{miss}  {(s['label'] or '')[:100]}")
    for u in res["unreadable"][:5]:
        lines.append(_("UNREADABLE  {file}: {code}").format(file=u["file"], code=u["code"]))
    if len(res["unreadable"]) > 5:
        lines.append(_("UNREADABLE  and {n} more graph(s) (--format json shows the full list)")
                     .format(n=len(res["unreadable"]) - 5))
    for t in res.get("expanded", []):
        lines.append(_("· --text is the term {pref} ({file}#{id}): it also matched {forms}").format(
            pref=t["pref"], file=t["file"], id=t["id"], forms=", ".join(t["forms"])))
    if res.get("hint"):
        lines.append("· " + res["hint"])
    if res.get("semantic"):
        s = res["semantic"]
        lines.append((_("· order: --text and --semantic fused by RRF (k={k})") if s["mode"] == "hybrid" else
                      _("· order: similarity to --semantic")).format(k=s["k"])
                     + _("; model {model}; {indexed} node(s) from the index, {now} embedded now").format(
                         model=s["model"]["id"], indexed=s["index"]["nodes"], now=s["index"]["embedded_now"]))
    if res["query"].get("where"):
        lines.append(_("· only the nodes where {where}").format(where=" and ".join(res["query"]["where"])))
    lines.extend(_narrowed(res["query"]))
    shown = len(res["nodes"])
    first = int(res["query"]["cursor"] or 0)
    tail = _("; next page: --cursor {cursor}").format(cursor=res["next_cursor"]) if res["next_cursor"] else ""
    lines.append(_("· {total} node(s) in {graphs} graph(s)").format(total=res["total"], graphs=res["graphs"])
                 + (_(", showing {first} to {last}").format(first=first + 1, last=first + shown) if shown else "")
                 + tail)
    return "\n".join(lines)


def main(argv=None):
    ap = argparse.ArgumentParser(description=_("Query a corpus of .kg.yaml and .kg.json graphs without judging them: list "
                                               "and filter nodes or edges, count them by group, walk the neighborhood, "
                                               "follow transmission chains and decisions, and find what is due."))
    ap.add_argument("files", nargs="*", help=_(".kg.yaml or .kg.json files (or --root)"))
    ap.add_argument("--root", help=_("the corpus root: the graphs git tracks under it"))
    ap.add_argument("--id", action="append", default=[], dest="ids", help=_("exact id (repeatable)"))
    ap.add_argument("--id-prefix")
    ap.add_argument("--type", dest="node_type")
    ap.add_argument("--status")
    ap.add_argument("--plane")
    ap.add_argument("--layer")
    ap.add_argument("--file", help=_("only the graphs whose path contains this text"))
    ap.add_argument("--text", help=_("words the label contains, all of them, case-insensitive"))
    ap.add_argument("--in-narrative", action="store_true", help=_("--text also searches the narrative"))
    ap.add_argument("--open", action="store_true", dest="open_only", help=_("the queue of open nodes (status open)"))
    ap.add_argument("--verified-before", metavar=_("YYYY-MM-DD"), help=_("without verified_at, or verified before the date"))
    ap.add_argument("--around", metavar="ID", help=_("the neighborhood of the node (<path>#<id>, or an id unique in the corpus)"))
    ap.add_argument("--chain", metavar="ID", action="append",
                    help=_("the transmission chain from the node back to its origin: the weakest link and the origin's "
                           "strength, as separate axes, with a strict and a lenient grade; repeatable, up to 50 ids: "
                           "more than one prints kg-ssot.chains/1, one chain per id, with the status of the origin"))
    ap.add_argument("--decision", metavar="ID",
                    help=_("the history of a decision: what it replaced, what replaced it, what refutes it and what it "
                           "rests on, with the status of each"))
    ap.add_argument("--revisit", action="store_true",
                    help=_("the live decisions to revisit, by attention: the version they were pinned to changed, what "
                           "they rest on is due, they are due themselves, or they are contested"))
    ap.add_argument("--due", action="store_true",
                    help=_("the nodes of any type whose verified_at plus reverify_every is due by --as-of (default: "
                           "today), the most overdue first, each with due_on and days_late; the sum is that of "
                           "kg_validate --due, which also reports the profiles (x_term, x_mirror, x_doc_cycle)"))
    ap.add_argument("--as-of", metavar=_("YYYY-MM-DD"), help=_("with --revisit or --due, the date that counts as today"))
    ap.add_argument("--with", action="append", default=[], dest="withs", metavar=_("PREFIX=FOLDER"),
                    help=_("with --chain, --decision or --revisit, read the graph of another repository that a "
                           "provenance.source URL names, at the commit of the URL: the URL prefix before the commit, and "
                           "the local folder of that repository (repeatable)"))
    ap.add_argument("--where", action="append", default=[], metavar=_("KEY=VALUE"),
                    help=_("only the nodes where the key has the value (repeatable, all of them): owner, an x_* field, "
                           "with a dot for a nested key (x_raci.responsible), provenance.<key>, or the degree derived "
                           "from the internal edges of its own graph (degree.in, degree.out, degree.total, "
                           "degree.in.SUPPORTS=0 for no internal edge of a type); KEY^=VALUE starts with and KEY*=VALUE contains, case-sensitive, text only; "
                           "with --revisit, its decisions"))
    ap.add_argument("--has", action="append", default=[], metavar=_("FIELD"),
                    help=_("only the nodes that have the field, any field, with a dot for a nested key (repeatable, up "
                           "to 10); null counts as lacking it, and empty text and 0 count as having it"))
    ap.add_argument("--missing", action="append", default=[], metavar=_("FIELD"),
                    help=_("only the nodes that lack the field, or have it as null (repeatable, up to 10)"))
    ap.add_argument("--group-by", action="append", default=[], metavar=_("FIELD"),
                    help=_("count the nodes the filters find, by the value of the field (repeatable, up to 5): file, "
                           "node_type, status, plane, layer, owner, label, narrative, an x_* field (with a dot for a "
                           "nested key), meta.<key> of the node's graph, provenance.<key>, or the degree (degree.in, "
                           "degree.out, degree.total, with an optional edge type); prints kg-ssot.groups/2, every group, "
                           "without pages"))
    ap.add_argument("--edges", action="store_true",
                    help=_("count and list edges instead of nodes (internal and external): --where and --group-by take "
                           "edge_type, scope, file, meta.<key>, and from.<field> and to.<field> (id, file, found, "
                           "node_type, status, plane, layer, owner, an x_* field or provenance.<key>), also with ^= "
                           "and *=; without --group-by, prints kg-ssot.edges/1"))
    ap.add_argument("--count-distinct", action="append", default=[], metavar=_("FIELD"),
                    help=_("with --group-by, count the distinct values of the field in each group instead of the rows "
                           "(repeatable: the distinct combinations); null does not count"))
    ap.add_argument("--min-count", type=int, metavar="N",
                    help=_("with --group-by, keep only the groups with a count from N"))
    ap.add_argument("--depth", type=int, default=1)
    ap.add_argument("--edge-type", action="append", default=[], dest="edge_types")
    ap.add_argument("--direction", default="both", choices=("out", "in", "both"))
    ap.add_argument("--sort", default="corpus", choices=("corpus", "impact", "attention"))
    ap.add_argument("--limit", type=int, default=50)
    ap.add_argument("--cursor")
    ap.add_argument("--narrative", action="store_true", help=_("include the narrative of each node"))
    ap.add_argument("--fields", action="append", default=[], metavar="GLOB",
                    help=_("node keys to return in extra (repeatable): x_*, owner"))
    ap.add_argument("--exclude", action="append", default=[], metavar="GLOB",
                    help=_("with --root, paths to leave out (repeatable), added to the defaults: ")
                    + ", ".join(DEFAULT_EXCLUDE))
    ap.add_argument("--no-default-excludes", action="store_true", help=_("with --root, also read the vendor and the fixtures"))
    ap.add_argument("--semantic", metavar=_("QUESTION"),
                    help=_("order by similarity to the question (needs the vector extra); with --text, fused by RRF"))
    ap.add_argument("--model", help=_("the --semantic model (kg_vector.py models)"))
    ap.add_argument("--model-dir", help=_("where the --semantic model lives (default: $KG_SSOT_MODEL_DIR or "
                                          ".cache/kg-ssot/models in the home folder)"))
    ap.add_argument("--format", default="human", choices=("human", "json"))
    args = ap.parse_args(argv)
    kg_validate._utf8_stdio()  # no Windows, a saída para arquivo ou pipe seria cp1252 e derrubaria o → do JSON

    def broken(msg):
        print(_("BROKEN INPUT  {error}").format(error=msg), file=sys.stderr)
        return 2
    if args.due and args.files and any(kg_validate.iso_date(f) for f in args.files):  # --due 2026-11-30: a data viraria arquivo
        return broken(_("--due takes no date: give the date with --as-of YYYY-MM-DD"))
    if bool(args.root) == bool(args.files):
        return broken(_("give either --root or the files"))
    before = None
    if args.verified_before is not None:
        before = kg_validate.iso_date(args.verified_before)
        if before is None:
            return broken(_("--verified-before {value}: the date must be YYYY-MM-DD").format(value=repr(args.verified_before)))
    if args.edges:
        node_only = [flag for flag, on in (("--id", args.ids), ("--id-prefix", args.id_prefix), ("--type", args.node_type),
                                           ("--status", args.status), ("--plane", args.plane), ("--layer", args.layer),
                                           ("--text", args.text), ("--in-narrative", args.in_narrative),
                                           ("--open", args.open_only), ("--verified-before", args.verified_before),
                                           ("--around", args.around), ("--chain", args.chain),
                                           ("--decision", args.decision), ("--revisit", args.revisit),
                                           ("--semantic", args.semantic), ("--fields", args.fields),
                                           ("--narrative", args.narrative), ("--sort", args.sort != "corpus"),
                                           ("--has", args.has), ("--missing", args.missing), ("--due", args.due),
                                           ("--as-of", args.as_of),
                                           ("--edge-type", args.edge_types), ("--with", args.withs),
                                           ("--depth", args.depth != 1), ("--direction", args.direction != "both"),
                                           ("--model", args.model), ("--model-dir", args.model_dir))
                     if on not in (None, False, [], "")]
        if node_only:
            return broken(_("--edges counts edges: it does not combine with {flags}; filter the edges with --where "
                            "(edge_type=…, from.status=…)").format(flags=", ".join(node_only)))
        try:
            corpus = load(args.root, args.files, args.exclude, not args.no_default_excludes)
            res = edge_query(corpus, where=args.where, file=args.file, group_by=args.group_by,
                             count_distinct=args.count_distinct, min_count=args.min_count, limit=args.limit,
                             cursor=args.cursor)
        except (OSError, ValueError, UnicodeDecodeError) as exc:
            return broken(exc)
        text = json.dumps(res, ensure_ascii=False, indent=1) if args.format == "json" else \
            (groups_human(res) if args.group_by else edges_human(res))
        print(text.encode("utf-8", "backslashreplace").decode("utf-8"))
        return 0
    if (args.count_distinct or args.min_count is not None) and not args.group_by:
        return broken(_("--count-distinct and --min-count count the groups of --group-by: give it too"))
    if args.group_by and (args.semantic is not None or args.cursor is not None):
        return broken(_("--group-by counts every node the filters find: it does not combine with --semantic or "
                        "--cursor"))
    if (args.due or args.has or args.missing) and (args.decision is not None or args.chain is not None or args.revisit):
        return broken(_("--due, --has and --missing filter the node queries, not --decision, --chain or --revisit"))
    if not args.revisit:  # o --as-of do --revisit é conferido adiante, como sempre
        try:
            check_due(args.due, args.as_of, args.sort, args.semantic)
        except ValueError as exc:
            return broken(exc)
    ranker = None
    if args.semantic is not None:
        if not args.semantic.strip():  # o pedido quebrado é rc 2 antes de olhar o extra
            return broken(_("--semantic needs the question as text"))
        if __package__:
            from . import kg_vector
        else:
            import kg_vector
        try:
            ranker = kg_vector.Ranker(args.root, args.model or kg_vector.DEFAULT_MODEL, args.model_dir)
        except kg_vector.Unavailable as exc:  # rc próprio: quem chama cai no --text e declara, nunca em silêncio
            print(_("VECTOR UNAVAILABLE  {error}").format(error=exc), file=sys.stderr)
            return 3
        except ValueError as exc:
            return broken(exc)
    elif args.model or args.model_dir:
        return broken(_("--model and --model-dir go with --semantic"))
    if args.withs and args.chain is None and args.decision is None and not args.revisit:
        return broken(_("--with goes with --chain, --decision or --revisit"))
    if args.group_by and (args.decision is not None or args.chain is not None or args.revisit):
        return broken(_("--group-by counts the node queries, not --decision, --chain or --revisit"))
    if args.where and (args.decision is not None or args.chain is not None):
        return broken(_("--where filters the node queries and --revisit, not --decision or --chain"))
    if args.decision is not None or args.revisit:
        if args.decision is not None and args.revisit:
            return broken(_("--decision and --revisit are different questions: ask one at a time"))
        if args.around is not None or args.semantic is not None or args.text is not None or args.chain is not None:
            return broken(_("--decision and --revisit do not combine with --around, --text, --semantic or --chain"))
        as_of = datetime.date.today()
        if args.as_of is not None:
            as_of = kg_validate.iso_date(args.as_of)
            if as_of is None:
                return broken(_("--as-of {value}: the date must be YYYY-MM-DD").format(value=repr(args.as_of)))
        try:
            corpus = load(args.root, args.files, args.exclude, not args.no_default_excludes)
            corpus.withs = [with_spec(w) for w in args.withs]
            res = decision_history(corpus, args.decision) if args.decision is not None else \
                revisit(corpus, as_of, args.where)
        except (OSError, ValueError, UnicodeDecodeError) as exc:
            return broken(exc)
        if args.format == "json":
            text = json.dumps(res, ensure_ascii=False, indent=1)
        else:
            text = decision_human(res) if args.decision is not None else revisit_human(res)
        print(text.encode("utf-8", "backslashreplace").decode("utf-8"))
        return 0
    if args.chain is not None:
        if args.around is not None or args.semantic is not None or args.text is not None:
            return broken(_("--chain does not combine with --around, --text or --semantic"))
        try:
            corpus = load(args.root, args.files, args.exclude, not args.no_default_excludes)
            corpus.withs = [with_spec(w) for w in args.withs]
            res = chain_request(corpus, args.chain, args.edge_types)
        except (OSError, ValueError, UnicodeDecodeError) as exc:
            return broken(exc)
        text = json.dumps(res, ensure_ascii=False, indent=1) if args.format == "json" else \
            (chains_human(res) if res["schema_version"] == CHAINS_SCHEMA else chain_human(res))
        print(text.encode("utf-8", "backslashreplace").decode("utf-8"))
        return 0
    try:
        corpus = load(args.root, args.files, args.exclude, not args.no_default_excludes)
        res = query(corpus, ids=args.ids, id_prefix=args.id_prefix, node_type=args.node_type, status=args.status,
                    plane=args.plane, layer=args.layer, file=args.file, text=args.text, in_narrative=args.in_narrative,
                    open_only=args.open_only, verified_before=before, around=args.around, depth=args.depth,
                    edge_types=args.edge_types, direction=args.direction, sort=args.sort, limit=args.limit,
                    cursor=args.cursor, narrative=args.narrative, fields=args.fields, semantic=args.semantic,
                    ranker=ranker, where=args.where, group_by=args.group_by,
                    count_distinct=args.count_distinct, min_count=args.min_count, due=args.due, as_of=args.as_of,
                    has=args.has, missing=args.missing)
    except (OSError, ValueError, UnicodeDecodeError) as exc:
        return broken(exc)
    text = json.dumps(res, ensure_ascii=False, indent=1) if args.format == "json" else \
        (groups_human(res) if args.group_by else human(res))
    # o surrogate solto (\ud800, que o contrato só avisa) não é UTF-8: sai como o escape \ud800, que no JSON é o mesmo valor
    print(text.encode("utf-8", "backslashreplace").decode("utf-8"))
    return 0


if __name__ == "__main__":
    sys.exit(main())
