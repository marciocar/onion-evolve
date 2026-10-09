#!/usr/bin/env python3
"""O gate do adotante (E6, EPIC_6_CORE_GRADUATION): os grafos de um repo contra o contrato, com catraca POR GRAFO.

Mede os .kg.yaml rastreados por git no repo (árvore de trabalho; fora */fixtures/* e docs/materials/*, como no
spike, ou o que --exclude disser) contra o MUST e o SHOULD do contrato vigente, e compara com a linha de base:
  failing — grafo → códigos MUST que ele carrega hoje (a dívida herdada, nomeada por caminho);
  debt    — código SHOULD → quantos grafos o carregam.

Reprova (rc 1): grafo fora de failing que falha no MUST (grafo NOVO inclusive); grafo de failing com código MUST
que não tinha; dívida de um código que sobe ou código de dívida novo; contrato diferente do da base (nome do
schema MUST ou sha256 dos schemas). Consertar um grafo não compensa quebrar outro no MUST: a comparação é por
grafo. A dívida SHOULD é por código (total de grafos): tirar um aviso de A e pôr o mesmo em B empata.
Ganho (grafo que sai de failing, código que some, dívida que cai): passa, com aviso "trave com --update".

Depois da comparação, o detalhe da medição (os mesmos códigos de kg_validate.py, sem mudar o rc):
  MUST   <grafo> (novo|regredido|herdado): <código> · <código>   — um por grafo que reprova no MUST;
  SHOULD <código>: N grafos                                        — a dívida, por código.
Para ver as ocorrências de um grafo: kg_validate.py <grafo> (sem --schema, o mesmo contrato do gate).

--update mostra a comparação antes de gravar; se algo piorou, só grava com --accept-regression "<motivo>", e o
motivo fica na base. rc 2: entrada quebrada (não é repo git, base ilegível, fora do formato ou ausente sem
--update, .kg.yaml ilegível).

Uso:
  kg_gate.py [--repo DIR] [--baseline ARQ] [--exclude GLOB ...] [--no-default-excludes]
             [--update [--accept-regression MOTIVO]]
"""
import argparse
import collections
import datetime
import fnmatch
import hashlib
import json
import pathlib
import subprocess
import sys

sys.dont_write_bytecode = True  # num vendor, rodar o gate não pode sujar o diretório carimbado
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import kg_validate  # noqa: E402

DEFAULT_BASELINE = ".kg-ssot/gate.json"
DEFAULT_EXCLUDE = ("*/fixtures/*", "docs/materials/*")


class Broken(Exception):
    """Entrada quebrada: rc 2."""


def validators():
    load = lambda p: kg_validate.make_validator(json.loads(p.read_text(encoding="utf-8")))
    return load(kg_validate.CONTRACT_MUST), load(kg_validate.CONTRACT_SHOULD)


def measure_texts(items):
    """[(caminho, texto)] → {caminho: {"must": [códigos], "should": [códigos]}}: a medição de um corpus.

    É a mesma lógica que a catraca daqui (kg_ratchet.core_numbers) usa para medir o core por fora.
    """
    must, should = validators()
    return {name: {"must": kg_validate.codes(text, must), "should": kg_validate.warnings(text, must, should)}
            for name, text in items}


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


def contract_identity():
    """O nome do schema MUST e o sha256 dos dois schemas: um patch que muda o contrato sem renomear muda a identidade."""
    digest = hashlib.sha256()
    for p in (kg_validate.CONTRACT_MUST, kg_validate.CONTRACT_SHOULD):
        digest.update(p.read_bytes())
    return kg_validate.CONTRACT_MUST.name, digest.hexdigest()


def numbers(measured):
    failing = {n: r["must"] for n, r in sorted(measured.items()) if r["must"]}
    debt = collections.Counter(c for r in measured.values() for c in set(r["should"]))
    name, digest = contract_identity()
    return {"contract": name, "contract_sha256": digest, "graphs": len(measured), "failing": failing,
            "debt": dict(sorted(debt.items()))}


def compare(base, now, present=None):
    """(rc, linhas, piorou), por grafo em failing e por código em debt. present: os grafos medidos agora."""
    rc, lines, worse_any = 0, [], False

    def worse(msg):
        nonlocal rc, worse_any
        rc, worse_any = 1, True
        lines.append("✗ PIOROU  " + msg)

    for key in ("contract", "contract_sha256"):
        if base.get(key) != now[key]:
            rc = 1
            lines.append(f"✗ identidade {key}: a base é de {base.get(key)!r}, a medição é de {now[key]!r} — a"
                         " comparação abaixo é contra a base antiga; grave a base nova com --update no mesmo PR")
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
    for code, count in now["debt"].items():
        lines.append(f"  SHOULD {code}: {count} grafo{'s' if count != 1 else ''}")
    return lines


def read_base(path):
    try:
        base = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise Broken(f"linha de base ilegível ({path}): {exc}") from exc
    def strings(v):
        return isinstance(v, list) and all(isinstance(c, str) for c in v)

    ok = (isinstance(base, dict) and isinstance(base.get("contract"), str)
          and isinstance(base.get("failing"), dict) and all(strings(v) for v in base["failing"].values())
          and isinstance(base.get("debt"), dict)
          and all(type(v) is int and v >= 0 for v in base["debt"].values())
          and isinstance(base.get("accepted_regressions", []), list))
    if not ok:
        raise Broken(f"linha de base fora do formato ({path}): contract texto, failing caminho → [códigos],"
                     " debt código → inteiro ≥ 0, accepted_regressions lista")
    return base


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--repo", default=".", help="o repo cujos grafos são medidos (default: .)")
    ap.add_argument("--baseline", help=f"a linha de base (default: <repo>/{DEFAULT_BASELINE})")
    ap.add_argument("--exclude", action="append", default=[], metavar="GLOB",
                    help="glob de caminho fora do corpus, somado aos defaults (" + ", ".join(DEFAULT_EXCLUDE)
                         + "); repetível; fnmatch sobre o caminho relativo, * atravessa /")
    ap.add_argument("--no-default-excludes", action="store_true",
                    help="não aplica os defaults (cuidado: as fixtures do vendor entram no corpus)")
    ap.add_argument("--update", action="store_true", help="grava a linha de base (mostra a comparação antes)")
    ap.add_argument("--accept-regression", metavar="MOTIVO", help="com --update: aceita uma piora, com o motivo na base")
    args = ap.parse_args(argv)
    path = pathlib.Path(args.baseline) if args.baseline else pathlib.Path(args.repo) / DEFAULT_BASELINE
    try:
        measured = measure_texts(corpus(args.repo, (() if args.no_default_excludes else DEFAULT_EXCLUDE)
                                        + tuple(args.exclude)))
        now = numbers(measured)
        if path.is_file():
            base = read_base(path)
        elif args.update:
            base = None
        else:
            raise Broken(f"linha de base ausente ({path}): grave a primeira com --update")
    except (Broken, OSError, ValueError) as exc:
        print(f"GATE QUEBRADO  {exc}")
        return 2
    rc, lines, worse = compare(base, now, set(measured)) if base is not None else (0, [], False)
    print("\n".join(lines + detail(base, now)))
    if not args.update:
        return rc
    if worse and not args.accept_regression:
        print("✗ --update recusado: algo piorou. Corrija, ou aceite com --accept-regression \"<motivo>\" (fica na base)")
        return 1
    new = dict(now)
    new["accepted_regressions"] = list((base or {}).get("accepted_regressions", []))
    if worse:
        new["accepted_regressions"].append({"date": datetime.date.today().isoformat(), "reason": args.accept_regression,
                                            "worse": [l for l in lines if l.startswith("✗ PIOROU")]})
    if not new["accepted_regressions"]:
        del new["accepted_regressions"]
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(new, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"linha de base gravada: {path} ({now['graphs']} grafos, {len(now['failing'])} na dívida herdada)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
