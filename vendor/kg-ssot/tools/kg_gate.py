#!/usr/bin/env python3
"""O gate do adotante: os grafos de um repo contra o contrato, com catraca POR GRAFO.

A ponta externa das external_edges (v4.3) é conferida contra TODOS os .kg.yaml e .kg.json rastreados, inclusive os
excluídos do corpus: alvo inexistente ou apagado reprova quem aponta (integrity.dangling-external). O .kg.json é alvo
desde o v4.7.

Um .kg.json no repo fica fora da medição do gate: a 4.8.0 lê .kg.json no kg_validate, no armazém e no MCP, e o gate
mede só os .kg.yaml.

Mede os .kg.yaml rastreados por git no repo (árvore de trabalho; fora */fixtures/*, docs/materials/* e o vendor
do KG-SSOT, qualquer pasta com o carimbo .kg-ssot-version: os excluídos padrão; ou o que --exclude disser) contra o MUST e o SHOULD do contrato vigente, e compara com a linha de base:
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
    from . import kg_i18n, kg_validate
else:  # script ou vendor
    sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
    import kg_i18n  # noqa: E402
    import kg_validate  # noqa: E402
_ = kg_i18n._
N_ = kg_i18n.N_  # marca para o catálogo; traduz depois, no _(msgid) do worse()

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


VENDOR_STAMP = kg_validate.VENDOR_STAMP  # o carimbo que o kg_vendor.py grava na raiz do vendor


def corpus(repo, exclude=DEFAULT_EXCLUDE, skip_vendor=True):
    """Os .kg.yaml do adotante. Com skip_vendor (o padrão, que o --no-default-excludes desliga), fica de fora tudo o que
    está numa pasta com o carimbo do vendor do KG-SSOT, onde quer que ela esteja: desde a 4.19.0 a release leva um
    exemplo real (spec/vocab-examples/), que não é grafo do adotante e entraria na base num --update (achado de campo
    do brain na 4.19.0)."""
    out = subprocess.run(["git", "-C", str(repo), "ls-files", "-z"], capture_output=True)
    if out.returncode != 0:
        raise Broken(_("{repo} is not a git repository: {err}").format(
            repo=repo, err=out.stderr.decode("utf-8", "replace").strip()[:200]))
    listed = [n for n in out.stdout.decode("utf-8").split("\0") if n]
    vendors = kg_validate.vendor_dirs(listed)
    names = sorted(n for n in listed if selected(n, exclude) and not (skip_vendor and kg_validate.in_vendor(n, vendors)))
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
        raise Broken(_("{repo} is not a git repository: {err}").format(
            repo=repo, err=out.stderr.decode("utf-8", "replace").strip()[:200]))
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
            return [_("✗ vendor without a stamp: {stamp} is missing (run kg_vendor.py check; the gate has nothing to"
                      " verify the contract against)").format(stamp=stamp)]
        return []
    try:
        files = json.loads(stamp.read_text(encoding="utf-8")).get("files")
    except (OSError, json.JSONDecodeError, AttributeError) as exc:
        raise Broken(_("unreadable vendor stamp ({stamp}): {exc}").format(stamp=stamp, exc=exc)) from exc
    if not isinstance(files, dict):
        raise Broken(_("vendor stamp out of format ({stamp}): files").format(stamp=stamp))
    out = []
    for schema in (kg_validate.CONTRACT_MUST, kg_validate.CONTRACT_SHOULD):
        rel = schema.resolve().relative_to(root).as_posix()
        if files.get(rel) != hashlib.sha256(schema.read_bytes()).hexdigest():
            out.append(_("✗ vendor contract differs from the stamp: {rel} (run kg_vendor.py check; the schema is not"
                         " the one from the stamped release)").format(rel=rel))
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


# A piora fica gravada na base (accepted_regressions[].worse) sempre em pt-BR, a língua de antes da 4.18.0: o conteúdo
# da base é dado, não saída humana, e não pode mudar com a língua de quem roda o --update.
_RECORDED = {
    "{name} fails MUST: {codes}": "{name} falha no MUST: {codes}",
    "{name} gained a MUST code: {codes}": "{name} ganhou código MUST: {codes}",
    "debt.{code}: {want} → {got}": "debt.{code}: {want} → {got}",
    "kit {kit} is older than the baseline's ({base_kit}): a rule only the new release had would stop being measured"
    " (roll the kit back, or accept with --update --accept-regression)":
        "kit {kit} é mais antigo que o da base ({base_kit}): uma regra que só a release nova tinha deixaria de ser"
        " medida (volte o kit, ou aceite com --update --accept-regression)",
}


def compare(base, now, present=None, debt_now=None, strict_identity=False, recorded=None):
    """(rc, linhas, piorou), por grafo em failing e por código em debt. present: os grafos medidos agora. debt_now: a
    dívida de agora medida na granularidade da BASE, para a passada que troca a granularidade comparar maçã com maçã.
    recorded: uma lista que recebe cada piora no texto que a base grava (pt-BR, independente da língua da saída).

    A identidade do contrato (nome do schema MUST e sha256 dos schemas) é composta desde a 4.16.0: ela segue gravada e
    acusada quando muda, mas quem decide o rc é a comparação, feita com o contrato de agora. A troca sem veredito
    trocado passa com aviso, e a regra nova que piora um grafo reprova pela comparação. strict_identity volta ao rc 1
    de antes em toda troca de identidade."""
    rc, lines, worse_any = 0, [], False

    def worse(msgid, **kw):
        nonlocal rc, worse_any
        rc, worse_any = 1, True
        lines.append(_("✗ WORSE  {what}").format(what=_(msgid).format(**kw)))
        if recorded is not None:
            recorded.append("✗ PIOROU  " + _RECORDED[msgid].format(**kw))

    for key in ("contract", "contract_sha256"):
        if base.get(key) != now[key]:
            if strict_identity:
                rc = 1
                lines.append(_("✗ identity {key}: the baseline is from {old}, the measurement is from {new} — the"
                               " comparison below is against the old baseline; write the new baseline with --update in"
                               " the same PR").format(key=key, old=repr(base.get(key)), new=repr(now[key])))
            else:
                lines.append(_("· identity {key}: the baseline is from {old}, the measurement is from {new} — the"
                               " comparison below decides the verdict, measured with the current contract; write the"
                               " new identity with --update whenever you want").format(
                                   key=key, old=repr(base.get(key)), new=repr(now[key])))
    old_kit, new_kit = _vtuple(base.get("kit")), _vtuple(now.get("kit"))
    if old_kit and new_kit and new_kit < old_kit:
        worse(N_("kit {kit} is older than the baseline's ({base_kit}): a rule only the new release had would stop "
                 "being measured (roll the kit back, or accept with --update --accept-regression)"),
              kit=now["kit"], base_kit=base["kit"])
    for old, new, gid in base.get("moved", ()):
        lines.append(_("· {old} → {new}: the baseline record followed meta.id {gid} (git mv); if {new} is a new graph"
                       " with the same meta.id, its inherited debt came from the deleted graph — check it in the PR")
                     .format(old=old, new=new, gid=repr(gid)))
    want_f, got_f = base.get("failing", {}), now["failing"]
    for name in sorted(set(want_f) | set(got_f)):
        want, got = set(want_f.get(name, ())), set(got_f.get(name, ()))
        if name not in want_f:
            worse(N_("{name} fails MUST: {codes}"), name=name, codes=", ".join(sorted(got)))
        elif got - want:
            worse(N_("{name} gained a MUST code: {codes}"), name=name, codes=", ".join(sorted(got - want)))
        elif present is not None and name not in present:
            lines.append(_("· {name} left the corpus (it was in the inherited debt; lock it in with kg_gate.py --update)")
                         .format(name=name))
        elif got < want:
            if got:
                lines.append(_("↑ improved {name}: {codes} gone (lock in the gain: kg_gate.py --update)")
                             .format(name=name, codes=", ".join(sorted(want - got))))
            else:
                lines.append(_("↑ improved {name}: passes MUST (lock in the gain: kg_gate.py --update)").format(name=name))
    want_d, got_d = base.get("debt", {}), now["debt"]
    g_base, g_now = base.get("granularity", "graph"), now.get("granularity", "graph")
    if g_base != g_now:
        if debt_now is None:
            raise ValueError(_("granularity changed without the debt measured at the baseline's granularity"))
        got_d = debt_now  # compara na unidade da base: trocar não é piora, mas a piora que vier junto aparece
        lines.append(_("· debt granularity changed: baseline by {old}, new by {new} — the debt is compared by {old},"
                       " and the new baseline is written by {new}").format(old=g_base, new=g_now))
    for code in sorted(set(want_d) | set(got_d)):
        want, got = want_d.get(code, 0), got_d.get(code, 0)
        if got > want:
            worse(N_("debt.{code}: {want} → {got}"), code=code, want=want, got=got)
        elif got < want:
            lines.append(_("↑ improved debt.{code}: {want} → {got} (lock in the gain: kg_gate.py --update)")
                         .format(code=code, want=want, got=got))
    if isinstance(base.get("graphs"), int) and now["graphs"] < base["graphs"]:
        lines.append(_("· the corpus shrank: {old} → {new} graphs (deleted or excluded; check it in the PR)")
                     .format(old=base["graphs"], new=now["graphs"]))
    held = len(want_f.keys() & got_f.keys())
    lines.append(_("· {graphs} graphs; {passing} pass MUST; {held} in the inherited debt").format(
        graphs=now["graphs"], passing=now["graphs"] - len(got_f), held=held))
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
            kind = _("new")
        elif set(got) - set(want_f.get(name, got)):
            kind = _("regressed")
        else:
            kind = _("inherited")
        lines.append(_("  MUST   {name} ({kind}): {codes}").format(name=name, kind=kind, codes=" · ".join(got)))
    node = now.get("granularity") == "node"
    for code, count in now["debt"].items():
        if node:
            text = _("  SHOULD {code}: {count} occurrence") if count == 1 else _("  SHOULD {code}: {count} occurrences")
        else:
            text = _("  SHOULD {code}: {count} graph") if count == 1 else _("  SHOULD {code}: {count} graphs")
        lines.append(text.format(code=code, count=count))
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
        raise Broken(_("unreadable baseline ({path}): {exc}").format(path=path, exc=exc)) from exc
    ok = (isinstance(base, dict) and isinstance(base.get("contract"), str)
          and isinstance(base.get("failing"), dict) and all(_strings(v) for v in base["failing"].values())
          and isinstance(base.get("debt"), dict)
          and all(type(v) is int and v >= 0 for v in base["debt"].values())
          and isinstance(base.get("accepted_regressions", []), list)
          and all(isinstance(i, dict) for i in base.get("accepted_regressions", []))
          and base.get("granularity", "graph") in GRANULARITIES)
    if not ok:
        raise Broken(_("baseline out of format ({path}): contract text, failing path → [codes], debt code →"
                       " integer ≥ 0, accepted_regressions list, granularity graph or node").format(path=path))
    return base


def _read_json(path):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise Broken(_("unreadable baseline ({path}): {exc}").format(path=path, exc=exc)) from exc


def _record_ok(rec):
    return (isinstance(rec, dict) and isinstance(rec.get("graph"), str) and rec["graph"]
            and (rec.get("id") is None or isinstance(rec["id"], str)) and _strings(rec.get("must"))
            and isinstance(rec.get("should"), dict)
            and all(isinstance(c, str) and type(n) is int and n > 0 for c, n in rec["should"].items()))


def read_dir(path, measured=None):
    head = _read_json(path / "contract.json")
    if not (isinstance(head, dict) and isinstance(head.get("contract"), str)
            and isinstance(head.get("contract_sha256", ""), str) and head.get("granularity", "graph") in GRANULARITIES):
        raise Broken(_("baseline out of format ({path}): contract text, contract_sha256 text, granularity graph or"
                       " node").format(path=path / "contract.json"))
    records = []
    for f in sorted((path / "graphs").glob("*.json")):
        rec = _read_json(f)
        if not _record_ok(rec):
            raise Broken(_("baseline out of format ({path}): graph path, id text or null, must [codes], should code"
                           " → integer > 0").format(path=f))
        rec["_by_id"] = f.name == f"{rec['id']}.json"  # gravado pelo meta.id: o id era único quando a base foi gravada
        records.append(rec)
    accepted = []
    for f in sorted((path / "accepted").glob("*.json")):
        item = _read_json(f)
        if not isinstance(item, dict):
            raise Broken(_("baseline out of format ({path}): an accepted regression is an object").format(path=f))
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
        raise Broken(_("accepted regression out of format: each one is an object"))
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


HELP = """The adopter's gate: a repository's graphs against the contract, with a per-graph ratchet.

It measures the git-tracked .kg.yaml files (outside */fixtures/*, docs/materials/* and the KG-SSOT vendor, any folder
with the .kg-ssot-version stamp: the default excludes; or what --exclude says) against the MUST and the SHOULD of the current contract, and compares them with the baseline:
  failing - graph → MUST codes it carries today (the inherited debt, named by path);
  debt    - SHOULD code → how many graphs carry it (granularity graph, the default) or how many occurrences
            (granularity node).

It fails (rc 1) when a graph outside failing fails MUST (a new graph included), when a graph in failing gains a MUST
code, or when a debt code rises or appears. A contract identity different from the baseline's is reported on a
"· identity" line and does not decide the rc (--strict-identity makes it fail). A gain passes, with a hint to lock it
in with --update.

The baseline is the .kg-ssot/gate/ folder: contract.json, graphs/<meta.id>.json (one record per graph) and accepted/
(one accepted regression per file). --update shows the comparison before writing; if something got worse, it only
writes with --accept-regression "<reason>", and the reason stays in the baseline. rc 2: broken input (not a git
repository, unreadable or out-of-format baseline, missing baseline without --update, unreadable .kg.yaml).

Usage:
  kg_gate.py [--repo DIR] [--baseline FOLDER|FILE.json] [--exclude GLOB ...] [--no-default-excludes]
             [--strict-identity] [--update [--accept-regression REASON] [--granularity graph|node]]
"""


def main(argv=None):
    ap = argparse.ArgumentParser(description=_(HELP), formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--repo", default=".", help=_("the repository whose graphs are measured (default: .)"))
    ap.add_argument("--baseline", help=_("the baseline (default: the folder <repo>/{folder}; the file <repo>/{legacy},"
                                         " from before 4.16.0, is read and replaced by the folder on --update). A path"
                                         " ending in .json reads and writes the single file").format(
                                             folder=DEFAULT_BASELINE, legacy=LEGACY_BASELINE))
    ap.add_argument("--exclude", action="append", default=[], metavar="GLOB",
                    help=_("path glob left out of the corpus, added to the defaults ({defaults}); repeatable; fnmatch"
                           " on the relative path, * crosses /").format(defaults=", ".join(DEFAULT_EXCLUDE)))
    ap.add_argument("--no-default-excludes", action="store_true",
                    help=_("does not apply the defaults (careful: the vendor's fixtures enter the corpus)"))
    ap.add_argument("--update", action="store_true", help=_("writes the baseline (shows the comparison first)"))
    ap.add_argument("--strict-identity", action="store_true",
                    help=_("fails (rc 1) on every change of contract identity, even without a changed verdict, as"
                           " before 4.16.0"))
    ap.add_argument("--accept-regression", metavar="REASON",
                    help=_("with --update: accepts a regression, with the reason in the baseline"))
    ap.add_argument("--granularity", choices=GRANULARITIES,
                    help=_("with --update: changes the granularity of the SHOULD debt (graph, the default, or node);"
                           " without it, the baseline's applies"))
    args = ap.parse_args(argv)
    _utf8_stdio()
    if args.granularity and not args.update:
        print(_("GATE BROKEN  --granularity only works with --update (the baseline remembers the granularity)"))
        return 2
    if args.baseline:
        path = pathlib.Path(args.baseline)
        read_from, single = path, path.suffix == ".json"
    else:
        path = pathlib.Path(args.repo) / DEFAULT_BASELINE
        legacy = pathlib.Path(args.repo) / LEGACY_BASELINE
        read_from, single = (legacy if not path.exists() and legacy.is_file() else path), False
    try:
        items = corpus(args.repo, (() if args.no_default_excludes else DEFAULT_EXCLUDE) + tuple(args.exclude),
                       skip_vendor=not args.no_default_excludes)
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
            raise Broken(_("missing baseline ({path}): write the first one with --update").format(path=path))
        g_base = (base or {}).get("granularity", "graph")
        now = numbers(measured, args.granularity or g_base)
        debt_now = numbers(measured, g_base)["debt"] if base is not None and args.granularity not in (None, g_base) else None
    except (Broken, OSError, ValueError) as exc:
        print(_("GATE BROKEN  {error}").format(error=exc))
        return 2
    recorded = []  # as pioras no texto que a base grava (pt-BR), independente da língua da saída
    rc, lines, worse = (compare(base, now, set(measured), debt_now, args.strict_identity, recorded) if base is not None
                        else (0, [], False))
    try:
        tampered = stamp_problems()
    except Broken as exc:
        print(_("GATE BROKEN  {error}").format(error=exc))
        return 2
    if tampered:
        rc, worse, lines = 1, True, tampered + lines
        if args.update:  # contrato adulterado não vira base, nem com --accept-regression
            print("\n".join(lines + [_("✗ --update refused: the vendor contract differs from the stamp")]))
            return 1
    print("\n".join(lines + detail(base, now)))
    if not args.update:
        return rc
    if worse and not args.accept_regression:
        print(_("✗ --update refused: something got worse. Fix it, or accept it with --accept-regression \"<reason>\""
                " (it stays in the baseline)"))
        return 1
    accepted = list((base or {}).get("accepted_regressions", []))
    added = ({"date": datetime.date.today().isoformat(), "reason": args.accept_regression,
              "worse": recorded} if worse else None)
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
                raise Broken(_("{path} exists and is not a folder: the 4.16.0 baseline is a folder").format(path=path))
            write_dir(path, measured, now, accepted, added)
            if read_from != path and read_from.is_file():
                read_from.unlink()  # a migração: o arquivo único sai, e a pasta passa a ser a base
                print(_("· baseline migrated: {old} → {new}/ (one record per graph; the verdict does not change)")
                      .format(old=read_from, new=path))
    except (Broken, OSError) as exc:
        print(_("GATE BROKEN  {error}").format(error=exc))
        return 2
    print(_("baseline written: {path} ({graphs} graphs, {held} in the inherited debt)").format(
        path=path, graphs=now["graphs"], held=len(now["failing"])))
    return 0


if __name__ == "__main__":
    sys.exit(main())
