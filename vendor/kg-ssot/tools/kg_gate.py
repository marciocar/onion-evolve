#!/usr/bin/env python3
"""O gate do adotante: os grafos de um repo contra o contrato, com catraca POR GRAFO.

A ponta externa das external_edges (v4.3) é conferida contra TODOS os .kg.yaml e .kg.json rastreados, inclusive os
excluídos do corpus: alvo inexistente ou apagado reprova quem aponta (integrity.dangling-external). O .kg.json é alvo
desde o v4.7.

Um .kg.json no repo fica fora da medição do gate: a 4.8.0 lê .kg.json no kg_validate, no armazém e no MCP, e o gate
mede só os .kg.yaml.

Mede os .kg.yaml rastreados por git no repo (árvore de trabalho; fora */fixtures/* e docs/materials/*, os
excluídos padrão, ou o que --exclude disser) contra o MUST e o SHOULD do contrato vigente, e compara com a linha de base:
  failing — grafo → códigos MUST que ele carrega hoje (a dívida herdada, nomeada por caminho);
  debt    — código SHOULD → quantos grafos o carregam (granularity graph, o padrão) ou quantas ocorrências, somadas
            em todos os grafos (granularity node). A base guarda a granularidade; --granularity a troca num --update.

Reprova (rc 1): grafo fora de failing que falha no MUST (grafo NOVO inclusive); grafo de failing com código MUST
que não tinha; dívida de um código que sobe ou código de dívida novo. O contrato diferente do da base (nome do
schema MUST ou sha256 dos schemas) é acusado numa linha "· identidade" e não decide o rc desde a 4.16.0: a
comparação já é feita com o contrato de agora, e a regra nova que piora um grafo reprova por ela.
--strict-identity volta a reprovar toda troca de identidade.

A base (desde a 4.16.0) é a pasta .kg-ssot/gate/: contract.json (a identidade), graphs/<meta.id>.json (um registro
por grafo, com os códigos MUST e a contagem SHOULD) e accepted/ (uma regressão aceita por arquivo). Nada agregado é
gravado, e o merge de duas branches que mexem em grafos diferentes não conflita. O .kg-ssot/gate.json de antes é
lido, e o --update o troca pela pasta; --baseline <arquivo>.json segue lendo e gravando o arquivo único.

Rodando de um vendor, o gate confere os dois schemas contra o carimbo (.kg-ssot-version) e reprova o schema editado
ou o carimbo apagado. A base guarda a versão do kit (kit, no contract.json), e medir com um kit mais antigo que o da
base reprova. Consertar um grafo não compensa quebrar outro no MUST: a comparação é por
grafo. A dívida SHOULD é por código: por grafo, tirar um aviso de A e pôr o mesmo em B empata; por nó, consertar três
ocorrências num grafo e criar uma noutro é ganho (por grafo, uma melhora líquida espalhada aparecia
como piora). Trocar a granularidade não é piora: na passada que troca, a dívida é comparada na granularidade da base, e
só uma piora de verdade pede --accept-regression. Ocorrência é por nó ou aresta na maioria dos códigos; os que são do
arquivo inteiro (yaml.unquoted-date, form.range.top.nodes) contam 1 por grafo.
Ganho (grafo que sai de failing, código que some, dívida que cai): passa, com aviso "trave com --update".

Depois da comparação, o detalhe da medição (os mesmos códigos de kg_validate.py, sem mudar o rc):
  MUST   <grafo> (novo|regredido|herdado): <código> · <código>   — um por grafo que reprova no MUST;
  SHOULD <código>: N grafos                                        — a dívida, por código.
Para ver as ocorrências de um grafo: kg_validate.py <grafo> (sem --schema, o mesmo contrato do gate).

--update mostra a comparação antes de gravar; se algo piorou, só grava com --accept-regression "<motivo>", e o
motivo fica na base. rc 2: entrada quebrada (não é repo git, base ilegível, fora do formato ou ausente sem
--update, .kg.yaml ilegível).

Uso:
  kg_gate.py [--repo DIR] [--baseline PASTA|ARQ.json] [--exclude GLOB ...] [--no-default-excludes]
             [--strict-identity] [--update [--accept-regression MOTIVO] [--granularity graph|node]]
"""
import argparse
import collections
import datetime
import fnmatch
import hashlib
import json
import os
import pathlib
import re
import subprocess
import sys

sys.dont_write_bytecode = True  # num vendor, rodar o gate não pode sujar o diretório carimbado
if __package__:  # no pacote kg_ssot, o vizinho vem pelo pacote, sem mexer no sys.path de quem importa
    from . import kg_validate
else:  # script ou vendor
    sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
    import kg_validate  # noqa: E402

DEFAULT_BASELINE = ".kg-ssot/gate"  # a pasta, desde a 4.16.0: um registro por grafo
LEGACY_BASELINE = ".kg-ssot/gate.json"  # o arquivo único de antes da 4.16.0, ainda lido; o --update troca pela pasta
DEFAULT_EXCLUDE = ("*/fixtures/*", "docs/materials/*")


class Broken(Exception):
    """Entrada quebrada: rc 2."""


def validators():
    load = lambda p: kg_validate.make_validator(json.loads(p.read_text(encoding="utf-8")))
    return load(kg_validate.CONTRACT_MUST), load(kg_validate.CONTRACT_SHOULD)


def measure_texts(items, corpus=None):
    """[(caminho, texto)] → {caminho: {"must": [códigos], "should": [códigos]}}: a medição de um corpus.

    É a mesma lógica que o mantenedor usa para medir corpora de terceiros.
    """
    must, should = validators()
    out = {}
    for name, text in items:
        counts = kg_validate.warning_counts(text, must, should, corpus)
        out[name] = {"must": kg_validate.codes(text, must, corpus), "should": sorted(counts), "should_counts": dict(counts),
                     "id": graph_id(text)}
    return out


def graph_id(text):
    """O meta.id do grafo, ou None (parse que falha, meta.id ausente ou fora de texto): é a chave do registro na base."""
    _, doc, err = kg_validate.parse_v1(text)
    meta = doc.get("meta") if isinstance(doc, dict) and not err else None
    gid = meta.get("id") if isinstance(meta, dict) else None
    return gid if isinstance(gid, str) and gid else None


def selected(name, exclude):
    return name.endswith(".kg.yaml") and not any(fnmatch.fnmatchcase(name, g) for g in exclude)


def corpus(repo, exclude=DEFAULT_EXCLUDE):
    out = subprocess.run(["git", "-C", str(repo), "ls-files", "-z"], capture_output=True)
    if out.returncode != 0:
        raise Broken(f"{repo} não é um repositório git: {out.stderr.decode('utf-8', 'replace').strip()[:200]}")
    names = sorted(n for n in out.stdout.decode("utf-8").split("\0") if n and selected(n, exclude))
    items = []
    for n in names:
        path = pathlib.Path(repo) / n
        if path.is_file():  # rastreado mas apagado na árvore de trabalho: saiu do corpus
            items.append((n, path.read_text(encoding="utf-8")))
    return items


def tracked_graphs(repo):
    """Todos os .kg.yaml e .kg.json rastreados, sem os filtros do corpus: é contra eles que a ponta externa é conferida
    (um alvo num grafo excluído do gate continua sendo alvo válido; desde o v4.7, o alvo pode ser um .kg.json)."""
    out = subprocess.run(["git", "-C", str(repo), "ls-files", "-z", "--", "*.kg.yaml", "*.kg.json"], capture_output=True)
    if out.returncode != 0:
        raise Broken(f"{repo} não é um repositório git: {out.stderr.decode('utf-8', 'replace').strip()[:200]}")
    return [n for n in out.stdout.decode("utf-8").split("\0") if n and (pathlib.Path(repo) / n).is_file()]


def contract_identity():
    """O nome do schema MUST e o sha256 dos dois schemas: um patch que muda o contrato sem renomear muda a identidade."""
    digest = hashlib.sha256()
    for p in (kg_validate.CONTRACT_MUST, kg_validate.CONTRACT_SHOULD):
        digest.update(p.read_bytes())
    return kg_validate.CONTRACT_MUST.name, digest.hexdigest()


def kit_version():
    """A versão da release do kit que mede (spec/release.json ao lado do contrato: no repo, no vendor e no pacote), ou
    None quando não há como ler."""
    try:
        version = json.loads((kg_validate.CONTRACT_MUST.parent / "release.json").read_text(encoding="utf-8"))["version"]
        return tuple(int(x) for x in version.split(".")) and version
    except (OSError, ValueError, KeyError, TypeError, AttributeError):
        return None


def _vtuple(v):
    try:
        return tuple(int(x) for x in str(v).split("."))
    except ValueError:
        return None


def stamp_problems():
    """Quando o gate roda de um vendor (a raiz do kit tem o carimbo .kg-ssot-version), o sha256 dos dois schemas tem
    de ser o carimbado. É a defesa da identidade composta: a troca de identidade deixou de reprovar sozinha, e um
    schema do vendor afrouxado à mão não pode passar como contrato novo. Fora de um vendor (o repo do produto, o
    pacote instalado), não há carimbo e não há o que conferir."""
    root = kg_validate.CONTRACT_MUST.resolve().parent.parent
    stamp = root / ".kg-ssot-version"
    if not stamp.is_file():
        if root.parent.name == "vendor":  # um vendor sem o carimbo: apagado, e com ele a conferência
            return [f"✗ vendor sem carimbo: {stamp} ausente (rode kg_vendor.py check; o gate não tem contra o que"
                    " conferir o contrato)"]
        return []
    try:
        files = json.loads(stamp.read_text(encoding="utf-8")).get("files")
    except (OSError, json.JSONDecodeError, AttributeError) as exc:
        raise Broken(f"carimbo do vendor ilegível ({stamp}): {exc}") from exc
    if not isinstance(files, dict):
        raise Broken(f"carimbo do vendor fora do formato ({stamp}): files")
    out = []
    for schema in (kg_validate.CONTRACT_MUST, kg_validate.CONTRACT_SHOULD):
        rel = schema.resolve().relative_to(root).as_posix()
        if files.get(rel) != hashlib.sha256(schema.read_bytes()).hexdigest():
            out.append(f"✗ contrato do vendor diverge do carimbo: {rel} (rode kg_vendor.py check; o schema não é o da"
                       " release carimbada)")
    return out


GRANULARITIES = ("graph", "node")


def numbers(measured, granularity="graph"):
    failing = {n: r["must"] for n, r in sorted(measured.items()) if r["must"]}
    if granularity == "node":
        debt = collections.Counter()
        for r in measured.values():
            debt.update(r.get("should_counts") or {c: 1 for c in r["should"]})
    else:
        debt = collections.Counter(c for r in measured.values() for c in set(r["should"]))
    name, digest = contract_identity()
    out = {"contract": name, "contract_sha256": digest, "graphs": len(measured), "failing": failing,
           "debt": dict(sorted(debt.items()))}
    version = kit_version()
    if version:
        out["kit"] = version
    if granularity != "graph":
        out["granularity"] = granularity
    return out


def compare(base, now, present=None, debt_now=None, strict_identity=False):
    """(rc, linhas, piorou), por grafo em failing e por código em debt. present: os grafos medidos agora. debt_now: a
    dívida de agora medida na granularidade da BASE, para a passada que troca a granularidade comparar maçã com maçã.

    A identidade do contrato (nome do schema MUST e sha256 dos schemas) é composta desde a 4.16.0: ela segue gravada e
    acusada quando muda, mas quem decide o rc é a comparação, feita com o contrato de agora. A troca sem veredito
    trocado passa com aviso, e a regra nova que piora um grafo reprova pela comparação. strict_identity volta ao rc 1
    de antes em toda troca de identidade."""
    rc, lines, worse_any = 0, [], False

    def worse(msg):
        nonlocal rc, worse_any
        rc, worse_any = 1, True
        lines.append("✗ PIOROU  " + msg)

    for key in ("contract", "contract_sha256"):
        if base.get(key) != now[key]:
            if strict_identity:
                rc = 1
                lines.append(f"✗ identidade {key}: a base é de {base.get(key)!r}, a medição é de {now[key]!r} — a"
                             " comparação abaixo é contra a base antiga; grave a base nova com --update no mesmo PR")
            else:
                lines.append(f"· identidade {key}: a base é de {base.get(key)!r}, a medição é de {now[key]!r} — o"
                             " veredito decide pela comparação abaixo, medida com o contrato de agora; grave a"
                             " identidade nova com --update quando quiser")
    old_kit, new_kit = _vtuple(base.get("kit")), _vtuple(now.get("kit"))
    if old_kit and new_kit and new_kit < old_kit:
        worse(f"kit {now['kit']} é mais antigo que o da base ({base['kit']}): uma regra que só a release nova tinha"
              " deixaria de ser medida (volte o kit, ou aceite com --update --accept-regression)")
    for old, new, gid in base.get("moved", ()):
        lines.append(f"· {old} → {new}: o registro da base seguiu pelo meta.id {gid!r} (git mv); se {new} é um grafo"
                     " novo com o mesmo meta.id, a dívida herdada dele veio do grafo apagado — confira no PR")
    want_f, got_f = base.get("failing", {}), now["failing"]
    for name in sorted(set(want_f) | set(got_f)):
        want, got = set(want_f.get(name, ())), set(got_f.get(name, ()))
        if name not in want_f:
            worse(f"{name} falha no MUST: {', '.join(sorted(got))}")
        elif got - want:
            worse(f"{name} ganhou código MUST: {', '.join(sorted(got - want))}")
        elif present is not None and name not in present:
            lines.append(f"· {name} saiu do corpus (estava na dívida herdada; trave com kg_gate.py --update)")
        elif got < want:
            lines.append(f"↑ melhorou {name}: " + (f"saiu {', '.join(sorted(want - got))}" if got else "passa no MUST")
                         + " (trave o ganho: kg_gate.py --update)")
    want_d, got_d = base.get("debt", {}), now["debt"]
    g_base, g_now = base.get("granularity", "graph"), now.get("granularity", "graph")
    if g_base != g_now:
        if debt_now is None:
            raise ValueError("granularidade trocada sem a dívida medida na granularidade da base")
        got_d = debt_now  # compara na unidade da base: trocar não é piora, mas a piora que vier junto aparece
        lines.append(f"· granularidade da dívida trocada: base por {g_base}, nova por {g_now} — a dívida é comparada por"
                     f" {g_base}, e a base nova é gravada por {g_now}")
    for code in sorted(set(want_d) | set(got_d)):
        want, got = want_d.get(code, 0), got_d.get(code, 0)
        if got > want:
            worse(f"debt.{code}: {want} → {got}")
        elif got < want:
            lines.append(f"↑ melhorou debt.{code}: {want} → {got} (trave o ganho: kg_gate.py --update)")
    if isinstance(base.get("graphs"), int) and now["graphs"] < base["graphs"]:
        lines.append(f"· o corpus encolheu: {base['graphs']} → {now['graphs']} grafos (apagado ou excluído; confira no PR)")
    held = len(want_f.keys() & got_f.keys())
    lines.append(f"· {now['graphs']} grafos; {now['graphs'] - len(got_f)} passam no MUST; {held} na dívida herdada")
    return rc, lines, worse_any


def detail(base, now):
    """As linhas do que o gate está carregando: cada grafo que reprova no MUST, com os códigos, e a dívida
    SHOULD por código. Não mudam o rc; dizem o que consertar sem rodar o leitor à parte.

    O rótulo do grafo: novo (fora da base), regredido (na base, com código que não tinha) ou herdado.
    Sem base (o primeiro --update), tudo o que reprova entra como herdado.
    """
    want_f = (base or {}).get("failing", {})
    lines = []
    for name, got in now["failing"].items():
        if base is not None and name not in want_f:
            kind = "novo"
        elif set(got) - set(want_f.get(name, got)):
            kind = "regredido"
        else:
            kind = "herdado"
        lines.append(f"  MUST   {name} ({kind}): {' · '.join(got)}")
    one, many = ("ocorrência", "ocorrências") if now.get("granularity") == "node" else ("grafo", "grafos")
    for code, count in now["debt"].items():
        lines.append(f"  SHOULD {code}: {count} {one if count == 1 else many}")
    return lines


def _strings(v):
    return isinstance(v, list) and all(isinstance(c, str) for c in v)


def read_base(path, measured=None):
    """A linha de base no formato de comparação (contract, contract_sha256, failing caminho → códigos, debt código →
    inteiro, graphs, granularity, accepted_regressions), lida da pasta (desde a 4.16.0) ou do arquivo único de antes.
    measured: a medição de agora, para achar pelo meta.id o grafo que mudou de caminho desde a base."""
    path = pathlib.Path(path)
    return read_dir(path, measured) if path.is_dir() else read_file(path)


def read_file(path):
    try:
        base = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise Broken(f"linha de base ilegível ({path}): {exc}") from exc
    ok = (isinstance(base, dict) and isinstance(base.get("contract"), str)
          and isinstance(base.get("failing"), dict) and all(_strings(v) for v in base["failing"].values())
          and isinstance(base.get("debt"), dict)
          and all(type(v) is int and v >= 0 for v in base["debt"].values())
          and isinstance(base.get("accepted_regressions", []), list)
          and all(isinstance(i, dict) for i in base.get("accepted_regressions", []))
          and base.get("granularity", "graph") in GRANULARITIES)
    if not ok:
        raise Broken(f"linha de base fora do formato ({path}): contract texto, failing caminho → [códigos],"
                     " debt código → inteiro ≥ 0, accepted_regressions lista, granularity graph ou node")
    return base


def _read_json(path):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise Broken(f"linha de base ilegível ({path}): {exc}") from exc


def _record_ok(rec):
    return (isinstance(rec, dict) and isinstance(rec.get("graph"), str) and rec["graph"]
            and (rec.get("id") is None or isinstance(rec["id"], str)) and _strings(rec.get("must"))
            and isinstance(rec.get("should"), dict)
            and all(isinstance(c, str) and type(n) is int and n > 0 for c, n in rec["should"].items()))


def read_dir(path, measured=None):
    head = _read_json(path / "contract.json")
    if not (isinstance(head, dict) and isinstance(head.get("contract"), str)
            and isinstance(head.get("contract_sha256", ""), str) and head.get("granularity", "graph") in GRANULARITIES):
        raise Broken(f"linha de base fora do formato ({path / 'contract.json'}): contract texto, contract_sha256 texto,"
                     " granularity graph ou node")
    records = []
    for f in sorted((path / "graphs").glob("*.json")):
        rec = _read_json(f)
        if not _record_ok(rec):
            raise Broken(f"linha de base fora do formato ({f}): graph caminho, id texto ou null, must [códigos],"
                         " should código → inteiro > 0")
        rec["_by_id"] = f.name == f"{rec['id']}.json"  # gravado pelo meta.id: o id era único quando a base foi gravada
        records.append(rec)
    accepted = []
    for f in sorted((path / "accepted").glob("*.json")):
        item = _read_json(f)
        if not isinstance(item, dict):
            raise Broken(f"linha de base fora do formato ({f}): a regressão aceita é um objeto")
        accepted.append(item)
    measured = measured or {}
    by_id = _paths_by_id(measured)
    stored = {rec["graph"] for rec in records}
    in_base = collections.Counter(rec["id"] for rec in records if rec["id"])
    granularity = head.get("granularity", "graph")
    failing, debt, moved = {}, collections.Counter(), []
    for rec in records:
        name = rec["graph"]
        # o git mv: o caminho da base sumiu, o registro foi gravado pelo meta.id (único na base), e o mesmo id, único
        # agora, está num caminho que nenhum registro tem. O gate não distingue o git mv de "apaga e cria com o mesmo
        # meta.id": por isso a tradução sai numa linha própria, para quem revisa o PR ver de onde veio a dívida.
        if (measured and name not in measured and rec["_by_id"] and in_base[rec["id"]] == 1 and rec["id"] in by_id
                and by_id[rec["id"]] not in stored):
            name = by_id[rec["id"]]
            moved.append((rec["graph"], name, rec["id"]))
        if rec["must"]:
            failing[name] = sorted(rec["must"])
        debt.update(rec["should"] if granularity == "node" else {c: 1 for c in rec["should"]})
    base = {"contract": head["contract"], "graphs": len(records), "failing": dict(sorted(failing.items())),
            "debt": dict(sorted(debt.items()))}
    if "contract_sha256" in head:
        base["contract_sha256"] = head["contract_sha256"]
    if isinstance(head.get("kit"), str):
        base["kit"] = head["kit"]
    if granularity != "graph":
        base["granularity"] = granularity
    if accepted:
        base["accepted_regressions"] = accepted
    if moved:
        base["moved"] = moved
    return base


def _paths_by_id(measured):
    """meta.id → caminho, só para os ids que aparecem uma vez na medição (id repetido não identifica grafo)."""
    seen = collections.Counter(r.get("id") for r in measured.values() if r.get("id"))
    return {r["id"]: name for name, r in measured.items() if r.get("id") and seen[r["id"]] == 1}


SAFE_NAME = re.compile(r"[A-Za-z0-9][A-Za-z0-9._-]{0,119}")
RESERVED = re.compile(r"(con|prn|aux|nul|com[0-9¹²³]|lpt[0-9¹²³])", re.IGNORECASE)  # dispositivos do Windows


def record_name(name, gid, unique_ids):
    """O nome do arquivo do registro: o meta.id, quando é único na medição sem distinguir maiúsculas (o macOS e o
    Windows não distinguem), cabe num nome de arquivo e não é dispositivo do Windows (assim um git mv não troca o
    registro); senão o hash do caminho. unique_ids: os ids que podem virar nome."""
    if (gid and gid in unique_ids and SAFE_NAME.fullmatch(gid) and not gid.endswith(".")
            and not RESERVED.fullmatch(gid.split(".")[0])):
        return gid + ".json"
    return "path-" + hashlib.sha256(name.encode("utf-8")).hexdigest()[:16] + ".json"


def _nameable_ids(measured):
    """Os ids únicos na medição cuja forma minúscula também é única: Foo e foo não viram Foo.json e foo.json."""
    unique = _paths_by_id(measured)
    lower = collections.Counter(i.lower() for i in unique)
    return {i for i in unique if lower[i.lower()] == 1}


def _write(target, text):
    """Grava por temporário e os.replace: um processo que cai no meio não deixa registro pela metade."""
    tmp = target.with_name(target.name + ".tmp")
    tmp.write_text(text, encoding="utf-8")
    os.replace(tmp, target)


def _dump(value):
    return json.dumps(value, ensure_ascii=False, indent=2, sort_keys=True) + "\n"


def write_dir(path, measured, now, accepted, new_accepted=None):
    """Grava a base na pasta: contract.json (a identidade e a granularidade), graphs/<registro>.json (um por grafo,
    com os códigos MUST e a contagem SHOULD dele) e accepted/<hash>.json (uma regressão aceita por arquivo).
    Nada agregado é gravado: a contagem de grafos e a dívida por código saem dos registros na leitura. Assim, duas
    branches que mexem em grafos diferentes mexem em arquivos diferentes, e o merge do git não conflita.

    A ordem protege a base: primeiro as regressões aceitas (o motivo existe antes da piora que ele explica), depois os
    registros e a identidade, cada um por temporário, e só no fim a limpeza dos registros que saíram."""
    items = list(accepted) + ([new_accepted] if new_accepted else [])
    if any(not isinstance(i, dict) for i in items):
        raise Broken("regressão aceita fora do formato: cada uma é um objeto")
    head = {"contract": now["contract"], "contract_sha256": now["contract_sha256"]}
    if now.get("kit"):
        head["kit"] = now["kit"]
    if now.get("granularity", "graph") != "graph":
        head["granularity"] = now["granularity"]
    for f in path.rglob("*.json.tmp"):  # sobra de uma gravação que caiu
        f.unlink()
    names = set()
    if items:
        (path / "accepted").mkdir(parents=True, exist_ok=True)
        for item in items:
            text = _dump(item)
            name = hashlib.sha256(text.encode("utf-8")).hexdigest()[:16] + ".json"
            names.add(name)
            if not (path / "accepted" / name).is_file():
                _write(path / "accepted" / name, text)
    for f in (path / "accepted").glob("*.json"):  # o item já regravado pelo hash: o arquivo de outro nome sai
        if f.name not in names:
            f.unlink()
    nameable = _nameable_ids(measured)
    graphs = path / "graphs"
    graphs.mkdir(parents=True, exist_ok=True)
    plan = {}
    for name, r in sorted(measured.items()):
        file = record_name(name, r.get("id"), nameable)
        if file.lower() in {k.lower() for k in plan}:  # dois caminhos com o mesmo hash curto: vai o hash inteiro
            file = "path-" + hashlib.sha256(name.encode("utf-8")).hexdigest() + ".json"
        plan[file] = _dump({"graph": name, "id": r.get("id"), "must": sorted(r["must"]),
                            "should": dict(sorted((r.get("should_counts") or {c: 1 for c in r["should"]}).items()))})
    keep = {k.lower() for k in plan}
    # a limpeza vem antes da escrita: se o processo cair entre as duas, falta registro (o gate reprova como grafo
    # novo, com barulho), em vez de sobrar um registro de grafo apagado cuja dívida esconderia uma piora
    for f in graphs.glob("*.json"):
        if f.name.lower() not in keep or (f.name not in plan and f.name.lower() in keep):
            f.unlink()  # o grafo saiu, ou o mesmo id com outra caixa (num sistema sem caixa, é o mesmo arquivo)
    for file, text in plan.items():
        target = graphs / file
        if not target.is_file() or target.read_text(encoding="utf-8") != text:
            _write(target, text)
    _write(path / "contract.json", _dump(head))


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
    ap.add_argument("--repo", default=".", help="o repo cujos grafos são medidos (default: .)")
    ap.add_argument("--baseline", help=f"a linha de base (default: a pasta <repo>/{DEFAULT_BASELINE}; o arquivo"
                                        f" <repo>/{LEGACY_BASELINE}, de antes da 4.16.0, é lido e trocado pela pasta no"
                                        " --update). Um caminho terminado em .json lê e grava o arquivo único")
    ap.add_argument("--exclude", action="append", default=[], metavar="GLOB",
                    help="glob de caminho fora do corpus, somado aos defaults (" + ", ".join(DEFAULT_EXCLUDE)
                         + "); repetível; fnmatch sobre o caminho relativo, * atravessa /")
    ap.add_argument("--no-default-excludes", action="store_true",
                    help="não aplica os defaults (cuidado: as fixtures do vendor entram no corpus)")
    ap.add_argument("--update", action="store_true", help="grava a linha de base (mostra a comparação antes)")
    ap.add_argument("--strict-identity", action="store_true",
                    help="reprova (rc 1) toda troca de identidade do contrato, mesmo sem veredito trocado, como antes da"
                         " 4.16.0")
    ap.add_argument("--accept-regression", metavar="MOTIVO", help="com --update: aceita uma piora, com o motivo na base")
    ap.add_argument("--granularity", choices=GRANULARITIES,
                    help="com --update: troca a granularidade da dívida SHOULD (graph, o padrão, ou node); sem ela, vale"
                         " a da base")
    args = ap.parse_args(argv)
    _utf8_stdio()
    if args.granularity and not args.update:
        print("GATE QUEBRADO  --granularity só vale com --update (a base lembra a granularidade)")
        return 2
    if args.baseline:
        path = pathlib.Path(args.baseline)
        read_from, single = path, path.suffix == ".json"
    else:
        path = pathlib.Path(args.repo) / DEFAULT_BASELINE
        legacy = pathlib.Path(args.repo) / LEGACY_BASELINE
        read_from, single = (legacy if not path.exists() and legacy.is_file() else path), False
    try:
        items = corpus(args.repo, (() if args.no_default_excludes else DEFAULT_EXCLUDE) + tuple(args.exclude))
        # o índice só lê os grafos que alguma referência externa cita (rastreados, inclusive fora do corpus do gate):
        # o alvo que não está lá fica fora do índice e reprova como dangling-external, igual a antes
        info = [kg_validate.external_info(t) for _, t in items]  # um parse por texto que pode citar, e só esses
        wanted = set().union(*(targets for _, targets in info)) if info else set()
        index = (kg_validate.corpus_index(args.repo, [n for n in tracked_graphs(args.repo) if n in wanted])
                 if any(uses for uses, _ in info) else None)
        measured = measure_texts(items, index)
        if read_from.is_file() or (read_from.is_dir() and not single):
            base = read_base(read_from, measured)
        elif args.update:
            base = None
        else:
            raise Broken(f"linha de base ausente ({path}): grave a primeira com --update")
        g_base = (base or {}).get("granularity", "graph")
        now = numbers(measured, args.granularity or g_base)
        debt_now = numbers(measured, g_base)["debt"] if base is not None and args.granularity not in (None, g_base) else None
    except (Broken, OSError, ValueError) as exc:
        print(f"GATE QUEBRADO  {exc}")
        return 2
    rc, lines, worse = (compare(base, now, set(measured), debt_now, args.strict_identity) if base is not None
                        else (0, [], False))
    try:
        tampered = stamp_problems()
    except Broken as exc:
        print(f"GATE QUEBRADO  {exc}")
        return 2
    if tampered:
        rc, worse, lines = 1, True, tampered + lines
        if args.update:  # contrato adulterado não vira base, nem com --accept-regression
            print("\n".join(lines + ["✗ --update recusado: o contrato do vendor diverge do carimbo"]))
            return 1
    print("\n".join(lines + detail(base, now)))
    if not args.update:
        return rc
    if worse and not args.accept_regression:
        print("✗ --update recusado: algo piorou. Corrija, ou aceite com --accept-regression \"<motivo>\" (fica na base)")
        return 1
    accepted = list((base or {}).get("accepted_regressions", []))
    added = ({"date": datetime.date.today().isoformat(), "reason": args.accept_regression,
              "worse": [l for l in lines if l.startswith("✗ PIOROU")]} if worse else None)
    try:
        if single:
            new = dict(now)
            new["accepted_regressions"] = accepted + ([added] if added else [])
            if not new["accepted_regressions"]:
                del new["accepted_regressions"]
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(json.dumps(new, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        else:
            if path.exists() and not path.is_dir():
                raise Broken(f"{path} existe e não é uma pasta: a base da 4.16.0 é uma pasta")
            write_dir(path, measured, now, accepted, added)
            if read_from != path and read_from.is_file():
                read_from.unlink()  # a migração: o arquivo único sai, e a pasta passa a ser a base
                print(f"· base migrada: {read_from} → {path}/ (um registro por grafo; o veredito não muda)")
    except (Broken, OSError) as exc:
        print(f"GATE QUEBRADO  {exc}")
        return 2
    print(f"linha de base gravada: {path} ({now['graphs']} grafos, {len(now['failing'])} na dívida herdada)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
