#!/usr/bin/env python3
"""A busca por semelhança do kg_query (release 4.26): o modelo de embedding, o índice e o ordenador do --semantic.

Opcional: precisa do extra vector (pip install "kg-ssot[vector]": onnxruntime, tokenizers e numpy). Sem ele, o kg_query
e o resto do kit rodam como sempre; só o --semantic (rc 3) e este script (rc 2) recusam, com o que instalar. Nada aqui entra
em veredito: o contrato, o gate e o --text não dependem do vetor.

O modelo é um arquivo ONNX com revisão e sha256 fixados (MODELS), baixado do Hugging Face uma vez por fetch ou index e
conferido a cada carga; a consulta nunca vai à rede. O texto de um nó é o label e a narrative, juntos por um espaço;
o vetor é a média dos tokens, normalizada (a mesma conta do fastembed 0.9, conferida nos 403 nós da bancada que mediu
o híbrido: cosseno mínimo 0,9999999).

O índice (index) é um cache em <root>/.kg-ssot/vector/<modelo>/index.npz, com um .gitignore que o deixa fora do git:
um vetor por nó e o sha256 do texto que o gerou, num arquivo só, trocado de uma vez e conferido na carga. O nó editado depois do index não fica com o vetor velho: a consulta o embute
na hora e o conta em embedded_now, e o próximo index só refaz o que mudou.

Uso:
  kg_vector.py fetch [--model NOME] [--model-dir DIR]
  kg_vector.py index --root DIR [--model NOME] [--model-dir DIR] [--exclude GLOB]... [--no-default-excludes]
                     [--format human|json]
  kg_vector.py models
  --model-dir DIR: onde o modelo mora (padrão: $KG_SSOT_MODEL_DIR, ou .cache/kg-ssot/models na pasta pessoal); quem não tem rede põe
  ali os arquivos de MODELS, e a carga confere o sha256 deles.
rc: 0 feito · 2 entrada quebrada, extra ausente, modelo ausente ou que não confere, ou download que falhou.
"""
import argparse
import hashlib
import http.client
import json
import os
import pathlib
import sys
import tempfile
import urllib.request
import zipfile

sys.dont_write_bytecode = True
if __package__:  # no pacote kg_ssot, o vizinho vem pelo pacote, sem mexer no sys.path de quem importa
    from . import kg_i18n, kg_validate
else:  # script ou vendor
    sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
    import kg_i18n  # noqa: E402
    import kg_validate  # noqa: E402
_ = kg_i18n._

INDEX_VERSION = "kg-ssot.vector-index/1"
DEFAULT_MODEL = "paraphrase-multilingual-minilm-l12-v2"
# a revisão e o sha256 de cada arquivo: o que a bancada mediu é exatamente o que se baixa, e um arquivo trocado na
# origem para a carga, em vez de mudar o ranking em silêncio
MODELS = {
    DEFAULT_MODEL: {
        "repo": "Qdrant/paraphrase-multilingual-MiniLM-L12-v2-onnx-Q",
        "revision": "faf4aa4225822f3bc6376869cb1164e8e3feedd0",
        "files": {"model_optimized.onnx": "634d0f66c29dc934c8fa72b8a4fe91dd4d420a22f1d82a241058d4316e659a99",
                  "tokenizer.json": "fa685fc160bbdbab64058d4fc91b60e62d207e8dc60b9af5c002c5ab946ded00"},
        "onnx": "model_optimized.onnx",
        "max_tokens": 128,
        "dim": 384,
        "license": "apache-2.0",
        "about": "multilingual (~50 languages), 128 tokens, ~250 MB; the model the hybrid bench measured",
    },
}
URL = "https://huggingface.co/{repo}/resolve/{revision}/{file}"


class Unavailable(Exception):
    """O vetor não roda aqui: o extra não está instalado, o modelo não está no disco ou não confere."""


def _deps():
    try:
        import numpy
        import onnxruntime
        import tokenizers
    except ImportError as exc:
        raise Unavailable(_("the vector search needs the vector extra ({missing}): pip install \"kg-ssot[vector]\"")
                          .format(missing=exc.name or exc)) from None
    return numpy, onnxruntime, tokenizers


def spec(name):
    if name not in MODELS:
        raise ValueError(_("unknown model {name} (models: {models})").format(name=repr(name),
                                                                           models=", ".join(sorted(MODELS))))
    return MODELS[name]


def model_dir(name, override=None):
    base = override or os.environ.get("KG_SSOT_MODEL_DIR") or pathlib.Path.home() / ".cache" / "kg-ssot" / "models"
    return pathlib.Path(base) / name / spec(name)["revision"]


def _sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for block in iter(lambda: f.read(1 << 20), b""):
            h.update(block)
    return h.hexdigest()


def check_model(name, override=None):
    """O diretório do modelo, com cada arquivo presente e com o sha256 fixado. Unavailable se falta ou diverge."""
    d, s = model_dir(name, override), spec(name)
    for file, digest in s["files"].items():
        p = d / file
        if not p.is_file():
            raise Unavailable(_("model {name} is not in {dir}: run kg_vector.py fetch (or put its files there)")
                              .format(name=name, dir=d))
        if _sha256(p) != digest:
            raise Unavailable(_("{file} in {dir} does not match the pinned sha256: delete it and run kg_vector.py "
                                "fetch").format(file=file, dir=d))
    return d


def fetch(name, override=None, opener=urllib.request.urlopen):
    """Baixa o que falta do modelo para model_dir, conferindo o sha256 antes de pôr no lugar. Devolve (dir, baixados)."""
    d, s = model_dir(name, override), spec(name)
    d.mkdir(parents=True, exist_ok=True)
    got = []
    for file, digest in s["files"].items():
        p = d / file
        if p.is_file() and _sha256(p) == digest:
            continue
        url = URL.format(repo=s["repo"], revision=s["revision"], file=file)
        fd, tmp = tempfile.mkstemp(dir=d, prefix=f".{file}.")
        try:
            h = hashlib.sha256()
            with os.fdopen(fd, "wb") as out, opener(url, timeout=60) as resp:
                for block in iter(lambda: resp.read(1 << 20), b""):
                    h.update(block)
                    out.write(block)
            if h.hexdigest() != digest:
                raise Unavailable(_("{file} downloaded from {url} does not match the pinned sha256").format(
                    file=file, url=url))
            os.replace(tmp, p)
            got.append(file)
        except (OSError, http.client.HTTPException) as exc:  # o IncompleteRead da resposta cortada não é OSError
            raise Unavailable(_("could not download {url}: {error}").format(url=url, error=exc)) from None
        finally:
            if os.path.exists(tmp):
                os.unlink(tmp)
    return d, got


def node_text(node):
    """O texto que se embute: o label e a narrative, os que são texto, juntos por um espaço."""
    return " ".join(v for v in (node.get("label"), node.get("narrative")) if isinstance(v, str) and v)


def text_sha(text):
    return hashlib.sha256(text.encode("utf-8", "surrogatepass")).hexdigest()


class Embedder:
    """O modelo carregado: embed(textos) dá uma matriz float32 com uma linha normalizada por texto."""

    def __init__(self, name=DEFAULT_MODEL, override=None):
        self.name, s = name, spec(name)
        self.np, ort, tokenizers = _deps()
        d = check_model(name, override)
        self.tok = tokenizers.Tokenizer.from_file(str(d / "tokenizer.json"))
        self.tok.enable_truncation(max_length=s["max_tokens"], direction="right")
        self.tok.no_padding()
        opts = ort.SessionOptions()
        opts.log_severity_level = 3
        self.sess = ort.InferenceSession(str(d / s["onnx"]), opts, providers=["CPUExecutionProvider"])
        self.inputs = {i.name for i in self.sess.get_inputs()}
        self.dim = s["dim"]

    def embed(self, texts):
        np = self.np
        out = np.zeros((len(texts), self.dim), dtype=np.float32)
        for i, t in enumerate(texts):  # um por vez: sem padding, a média é a dos tokens do próprio texto
            e = self.tok.encode(t)
            ids = np.array([e.ids], dtype=np.int64)
            feed = {"input_ids": ids}
            if "attention_mask" in self.inputs:
                feed["attention_mask"] = np.array([e.attention_mask], dtype=np.int64)
            if "token_type_ids" in self.inputs:
                feed["token_type_ids"] = np.zeros_like(ids)
            v = self.sess.run(None, feed)[0][0].astype(np.float64).mean(axis=0)
            norm = np.linalg.norm(v)
            out[i] = (v / norm if norm else v).astype(np.float32)
        return out


def index_dir(root, name):
    return pathlib.Path(root) / ".kg-ssot" / "vector" / name


def _key(key):
    return f"{key[0]}#{key[1]}"


def _numpy():
    try:
        import numpy as np
    except ImportError:
        raise Unavailable(_("the vector search needs the vector extra ({missing}): pip install \"kg-ssot[vector]\"")
                          .format(missing="numpy")) from None
    return np


def load_index(root, name):
    """{chave: (sha, vetor)} do índice em disco, ou {} quando não há índice, ele é de outra versão, modelo ou revisão,
    ou não passa na conferência (forma, dimensão, float32 finito, chaves e shas em texto, sem chave repetida). O índice
    é um arquivo só (index.npz), trocado de uma vez: nunca há chaves de uma gravação com vetores de outra."""
    if root is None:
        return {}
    np = _numpy()
    path = index_dir(root, name) / "index.npz"
    try:
        with np.load(path, allow_pickle=False) as z:
            meta = {k: str(z[k][()]) for k in ("schema_version", "model", "revision", "model_sha256")}
            keys, shas, vectors = z["keys"], z["shas"], z["vectors"]
    except (OSError, ValueError, KeyError, TypeError, EOFError, zipfile.BadZipFile):
        return {}
    s = spec(name)
    if meta != {"schema_version": INDEX_VERSION, "model": name, "revision": s["revision"],
                "model_sha256": s["files"][s["onnx"]]}:  # o índice de outro arquivo de modelo não vale
        return {}
    if keys.ndim != 1 or shas.shape != keys.shape or keys.dtype.kind != "U" or shas.dtype.kind != "U" or \
            vectors.ndim != 2 or vectors.shape != (len(keys), s["dim"]) or vectors.dtype != np.float32 or \
            not np.isfinite(vectors).all() or len(set(keys.tolist())) != len(keys) or \
            not all(abs(n - 1) < 1e-3 or n == 0 for n in np.linalg.norm(vectors, axis=1).tolist()) or \
            not all(len(h) == 64 for h in shas.tolist()):
        return {}
    return {k: (h, vectors[i]) for i, (k, h) in enumerate(zip(keys.tolist(), shas.tolist()))}


def build_index(corpus, root, embedder):
    """Grava o índice de todos os nós do corpus, refazendo só o que mudou. {nodes, embedded, reused, removed, dir}."""
    np = embedder.np
    old = load_index(root, embedder.name)
    keys = list(corpus.order)
    texts = [node_text(corpus.nodes[k]) for k in keys]
    shas = [text_sha(t) for t in texts]
    todo = [i for i, k in enumerate(keys) if old.get(_key(k), (None,))[0] != shas[i]]
    fresh = embedder.embed([texts[i] for i in todo]) if todo else np.zeros((0, embedder.dim), dtype=np.float32)
    vectors = np.zeros((len(keys), embedder.dim), dtype=np.float32)
    for i, k in enumerate(keys):
        if _key(k) in old and old[_key(k)][0] == shas[i]:
            vectors[i] = old[_key(k)][1]
    for j, i in enumerate(todo):
        vectors[i] = fresh[j]
    d = index_dir(root, embedder.name)
    d.mkdir(parents=True, exist_ok=True)
    for stale in d.glob(".index.*.npz"):  # o temporário de uma gravação morta (SIGKILL) não fica para sempre
        stale.unlink()
    gi = d.parent / ".gitignore"
    if not gi.exists():  # o cache não é do repo: some do git sem o adotante precisar lembrar
        gi.write_text("*\n", encoding="utf-8")
    fd, tmp = tempfile.mkstemp(dir=d, prefix=".index.", suffix=".npz")
    try:
        with os.fdopen(fd, "wb") as f:  # um arquivo, um replace: a gravação cortada ao meio deixa o índice anterior
            np.savez(f, schema_version=np.array(INDEX_VERSION), model=np.array(embedder.name),
                     revision=np.array(spec(embedder.name)["revision"]),
                     model_sha256=np.array(spec(embedder.name)["files"][spec(embedder.name)["onnx"]]),
                     keys=np.array([_key(k) for k in keys], dtype=str), shas=np.array(shas, dtype=str),
                     vectors=vectors)
        os.replace(tmp, d / "index.npz")
    finally:
        if os.path.exists(tmp):
            os.unlink(tmp)
    keep = {_key(k) for k in keys}
    return {"nodes": len(keys), "embedded": len(todo), "reused": len(keys) - len(todo),
            "removed": len([k for k in old if k not in keep]), "dir": str(d)}


MEMO_MAX = 20000


class Ranker:
    """O ordenador que o kg_query recebe: rank(corpus, chaves, pergunta) dá as chaves da mais para a menos parecida
    (empate pela ordem do corpus; o nó sem texto vai para o fim, porque o vetor de um texto vazio não diz nada) e o que
    foi usado: {model: {id, revision, sha256}, index: {nodes, embedded_now, from_memory, no_text}}, que somam as chaves.
    O vetor que ele embute fica guardado na memória pelo sha do texto: o servidor MCP, que não tem índice em disco, paga
    cada nó uma vez por processo. A memória tem teto (MEMO_MAX, ou o dobro do corpus da chamada): passando dele, fica só
    o que a chamada usou."""

    def __init__(self, root=None, name=DEFAULT_MODEL, override=None):
        spec(name)  # o modelo desconhecido é pedido quebrado, antes de olhar o extra
        self.root, self.name = root, name
        self.embedder = Embedder(name, override)
        self.index = load_index(root, name)
        self.memo = {}

    def __call__(self, corpus, keys, question):
        np = self.embedder.np
        texts = [node_text(corpus.nodes[k]) for k in keys]
        vectors = np.zeros((len(keys), self.embedder.dim), dtype=np.float32)
        shas = [text_sha(t) for t in texts]
        todo, from_index, from_memory = [], 0, 0
        for i, k in enumerate(keys):
            hit = self.index.get(_key(k))
            if not texts[i]:
                continue
            if hit is not None and hit[0] == shas[i]:
                vectors[i] = hit[1]
                from_index += 1
            elif shas[i] in self.memo:
                vectors[i] = self.memo[shas[i]]
                from_memory += 1
            else:
                todo.append(i)
        if todo:
            fresh = self.embedder.embed([texts[i] for i in todo])
            for j, i in enumerate(todo):
                vectors[i] = fresh[j]
                self.memo[shas[i]] = fresh[j].copy()  # a cópia não segura o lote inteiro vivo
        if len(self.memo) > max(MEMO_MAX, 2 * len(keys)):
            used_now = set(shas)
            self.memo = {h: v for h, v in self.memo.items() if h in used_now}
        q = self.embedder.embed([question])[0]
        sims = vectors @ q if len(keys) else np.zeros(0, dtype=np.float32)
        sims = np.where(np.array([bool(t) for t in texts], dtype=bool), sims, -2.0) if len(keys) else sims
        order = np.argsort(-sims, kind="stable")
        sp = spec(self.name)
        return [keys[i] for i in order], {"model": {"id": self.name, "revision": sp["revision"],
                                                    "sha256": sp["files"][sp["onnx"]]},
                                          "index": {"nodes": from_index, "embedded_now": len(todo),
                                                    "from_memory": from_memory,
                                                    "no_text": sum(1 for t in texts if not t)}}


def main(argv=None):
    ap = argparse.ArgumentParser(description=_("The model and the index of the kg_query --semantic search (release "
                                               "4.26); needs the vector extra."))
    ap.add_argument("command", choices=("fetch", "index", "models"))
    ap.add_argument("--model", default=DEFAULT_MODEL)
    ap.add_argument("--model-dir", help=_("where the model lives (default: $KG_SSOT_MODEL_DIR or .cache/kg-ssot/models in the home folder)"))
    ap.add_argument("--root", help=_("the corpus root (index): the graphs git tracks under it"))
    ap.add_argument("--exclude", action="append", default=[], metavar="GLOB",
                    help=_("with --root, paths to leave out (repeatable), added to the defaults"))
    ap.add_argument("--no-default-excludes", action="store_true", help=_("with --root, also read the vendor and the fixtures"))
    ap.add_argument("--format", default="human", choices=("human", "json"))
    args = ap.parse_args(argv)
    kg_validate._utf8_stdio()

    def broken(msg):
        print(_("BROKEN INPUT  {error}").format(error=msg), file=sys.stderr)
        return 2
    if args.command == "models":
        for name, s in sorted(MODELS.items()):
            print(f"{name}{'  (default)' if name == DEFAULT_MODEL else ''}  {s['repo']}@{s['revision'][:12]}  "
                  f"{s['license']}  {s['about']}")
        return 0
    try:
        spec(args.model)
        if args.command == "fetch":
            d, got = fetch(args.model, args.model_dir)
            print(_("✓ model {name} in {dir} ({n} file(s) downloaded, sha256 checked)").format(
                name=args.model, dir=d, n=len(got)))
            return 0
        if not args.root:
            return broken(_("index needs --root"))
        if __package__:
            from . import kg_query
        else:
            import kg_query
        corpus = kg_query.load(args.root, (), args.exclude, not args.no_default_excludes)
        fetch(args.model, args.model_dir)
        stats = build_index(corpus, args.root, Embedder(args.model, args.model_dir))
    except Unavailable as exc:
        return broken(exc)
    except (OSError, ValueError, UnicodeDecodeError) as exc:
        return broken(exc)
    if args.format == "json":
        print(json.dumps({"model": args.model, **stats, "unreadable": corpus.unreadable}, ensure_ascii=False, indent=1))
    else:
        print(_("✓ index {dir}: {nodes} node(s), {embedded} embedded, {reused} reused, {removed} removed").format(**stats))
        for u in corpus.unreadable:
            print(_("UNREADABLE  {file}  {code}").format(file=u["file"], code=u["code"]))
    return 0


if __name__ == "__main__":
    sys.exit(main())
