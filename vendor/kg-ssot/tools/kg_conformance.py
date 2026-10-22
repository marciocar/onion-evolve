#!/usr/bin/env python3
"""Runner da suíte de conformidade do .kg.yaml e do .kg.json para o leitor de referência (kg_validate.py).

Depende só de Python 3, PyYAML e jsonschema, sem nenhum harness de agente. É o molde que um leitor
em outra linguagem imita: para cada caso, o conjunto de códigos emitidos tem de ser IGUAL ao
esperado, em codes (MUST) e em warnings (SHOULD).

Passos:
  1. auto-teste do metaschema: aceita metaschema-tests/good/ e recusa metaschema-tests/bad/;
  2. cada manifest.json (em fixtures/) valida contra manifest.schema.json, cumpre a regra de pending_on da pasta
     (vazio em latest/, não vazio em proposals/) e aponta só para arquivos que existem;
  3. cada caso roda no leitor e é comparado por conjunto; o caso .kg.json é lido pelo perfil JSON (as_source).

rc: 0 se latest/ passa inteiro · 1 se algum caso de latest/ falha (inclusive o leitor caindo nele)
· 2 se a própria suíte está quebrada: metaschema ou manifesto ilegível ou inválido, pending_on fora
da regra, pasta desconhecida, arquivo ausente, repetido ou fora de todo manifesto, latest/ vazia.
optional/ e proposals/ reportam e nunca mudam o rc.

Uso:
  kg_conformance.py [--suite spec/conformance] [--schema spec/kg-contract-v4.schema.json]
                    [--should-schema spec/kg-contract-v4.should.schema.json] [--json OUT]
                    [--proposals-schema F --proposals-should-schema F]

--proposals-schema e --proposals-should-schema (juntos) medem só proposals/ contra um contrato candidato (ex.: o
rascunho de uma versão futura), e latest/ e optional/ seguem no --schema; sem eles, tudo roda no --schema. Não mudam o rc.
"""
import argparse
import json
import pathlib
import sys

from jsonschema import Draft202012Validator
from jsonschema.exceptions import SchemaError

sys.dont_write_bytecode = True  # num vendor, rodar a suíte não pode sujar o diretório carimbado
if __package__:  # no pacote kg_ssot, o vizinho vem pelo pacote, sem mexer no sys.path de quem importa
    from . import kg_i18n, kg_validate
else:  # script ou vendor: o leitor de referência mora ao lado
    sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
    import kg_i18n  # noqa: E402
    import kg_validate  # noqa: E402
_ = kg_i18n._

FOLDERS = ("latest", "optional", "proposals")


class SuiteBroken(Exception):
    """A própria suíte está quebrada: rc 2, nunca confundido com um leitor que falha (rc 1)."""


def load_json(path):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise SuiteBroken(_("{path}: could not be read as JSON ({kind}: {exc})").format(
            path=path, kind=exc.__class__.__name__, exc=exc)) from exc


def suite_errors(suite, meta_validator):
    """Defeitos da própria suíte. Qualquer um vale rc 2."""
    out = []
    tests = suite / "metaschema-tests"
    found = {"good": 0, "bad": 0}
    for f in sorted(tests.glob("*/*.json")):
        kind = f.parent.name
        if kind not in found:
            out.append(_("metaschema: {file} is outside good/ and bad/").format(file=f.relative_to(suite)))
            continue
        found[kind] += 1
        accepted = not list(meta_validator.iter_errors(load_json(f)))
        if accepted != (kind == "good"):
            msg = _("metaschema: {file} was accepted") if accepted else _("metaschema: {file} was rejected")
            out.append(msg.format(file=f.relative_to(suite)))
    out += [_("metaschema: no tests in metaschema-tests/{kind}/").format(kind=k) for k, n in found.items() if not n]

    cases_root = suite / "fixtures"
    referenced, latest_cases = set(), 0
    for m in sorted(cases_root.glob("*/**/manifest.json")):
        rel = m.relative_to(cases_root)
        folder = rel.parts[0]
        if folder not in FOLDERS:
            out.append(_("{rel}: folder '{folder}' outside {folders}").format(
                rel=rel, folder=folder, folders=", ".join(FOLDERS)))
            continue
        data = load_json(m)
        errs = list(meta_validator.iter_errors(data))
        if errs:
            out += [f"{rel}: {e.message}" for e in errs]
            continue
        if folder == "latest" and data["pending_on"]:
            out.append(_("{rel}: latest/ cannot depend on an open decision ({pending})").format(
                rel=rel, pending=", ".join(data["pending_on"])))
        if folder == "proposals" and not data["pending_on"]:
            out.append(_("{rel}: proposals/ requires a non-empty pending_on").format(rel=rel))
        files = [c["file"] for c in data["cases"]]
        out += [_("{rel}: file repeated in the manifest: {file}").format(rel=rel, file=f)
                for f in sorted({f for f in files if files.count(f) > 1})]
        out += [_("{rel}: missing case file {file}").format(rel=rel, file=f) for f in files if not (m.parent / f).is_file()]
        # um corpus que não existe faria o caso bad-* passar por vacuidade (toda ponta externa sumiria)
        out += [_("{rel}: corpus {corpus} of {file} is not a directory").format(rel=rel, corpus=repr(c["corpus"]),
                                                                               file=c["file"]) for c in data["cases"]
                if "corpus" in c and not (m.parent / c["corpus"]).is_dir()]
        referenced |= {(m.parent / f).resolve() for f in files}
        latest_cases += len(files) if folder == "latest" else 0
    # Um arquivo de caso fora de todo manifesto nunca roda, e ninguém fica sabendo.
    for f in sorted(list(cases_root.rglob("*.yaml")) + list(cases_root.rglob("*.kg.json"))):
        if f.resolve() not in referenced:
            out.append(_("{file}: case file outside every manifest").format(file=f.relative_to(cases_root)))
    if not latest_cases:
        out.append(_("latest/ has no cases: the suite would pass vacuously"))
    return out


def run_cases(suite, validator, should_validator, proposals=None):
    """proposals: (validator, should_validator) só para proposals/; None usa o par de latest/."""
    results = []
    cases_root = suite / "fixtures"
    for m in sorted(cases_root.glob("*/**/manifest.json")):
        data = load_json(m)
        folder = m.relative_to(cases_root).parts[0]
        must_v, should_v = proposals if proposals and folder == "proposals" else (validator, should_validator)
        for case in data["cases"]:
            path = m.parent / case["file"]
            want_codes = sorted(set(case["codes"]))
            want_warn = sorted(set(case.get("warnings", [])))
            row = {
                "folder": folder,
                "case": str(path.relative_to(cases_root)),
                "pending_on": data["pending_on"],
                "expected": {"codes": want_codes, "warnings": want_warn},
            }
            try:
                text = kg_validate.as_source(path.name, path.read_text(encoding="utf-8"))  # .kg.json: o perfil JSON
                corpus = kg_validate.corpus_index(m.parent / case["corpus"]) if "corpus" in case else None
                got_codes = sorted(set(kg_validate.codes(text, must_v, corpus)))
                got_warn = sorted(set(kg_validate.warnings(text, must_v, should_v, corpus)))
            except Exception as exc:  # noqa: BLE001 — o leitor caiu: falha DO CASO, o gate da pasta decide o rc
                row.update({"pass": False, "emitted": None, "error": f"{exc.__class__.__name__}: {exc}"})
            else:
                row.update({"pass": got_codes == want_codes and got_warn == want_warn,
                            "emitted": {"codes": got_codes, "warnings": got_warn}})
            results.append(row)
    return results


def _spec_home():
    """A raiz que tem o spec/, pelo caminho DESTE módulo (como o _home do kg_validate): ao lado no pacote, no pai no
    repo e no vendor. Não depende do kg_validate importado, então um kg_validate falso num teste não a desvia."""
    here = pathlib.Path(__file__).resolve().parent
    return here if (here / "spec" / "release.json").is_file() else here.parent


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


HELP = """Conformance suite runner for .kg.yaml and .kg.json, for the reference reader (kg_validate.py).

It needs only Python 3, PyYAML and jsonschema, with no agent harness. It is the mold a reader in another language
copies: for each case, the set of codes it emits must EQUAL the expected set, in codes (MUST) and in warnings (SHOULD).

Steps:
  1. metaschema self-test: it accepts metaschema-tests/good/ and rejects metaschema-tests/bad/;
  2. each manifest.json (in fixtures/) validates against manifest.schema.json, follows its folder's pending_on rule
     (empty in latest/, non-empty in proposals/) and points only to files that exist;
  3. each case runs in the reader and is compared as a set; a .kg.json case is read by the JSON profile (as_source).

rc: 0 if all of latest/ passes · 1 if a latest/ case fails (including when the reader crashes on it)
· 2 if the suite itself is broken: unreadable or invalid metaschema or manifest, pending_on outside the rule,
unknown folder, a missing or repeated file or one outside every manifest, empty latest/.
optional/ and proposals/ report and never change the rc.

Usage:
  kg_conformance.py [--suite spec/conformance] [--schema spec/kg-contract-v4.schema.json]
                    [--should-schema spec/kg-contract-v4.should.schema.json] [--json OUT]
                    [--proposals-schema F --proposals-should-schema F]

--proposals-schema and --proposals-should-schema (together) measure only proposals/ against a candidate contract
(e.g., the draft of a future version), and latest/ and optional/ stay on --schema; without them, everything runs on
--schema. They do not change the rc.
"""


def main(argv=None):
    root = _spec_home()  # o spec/ do pacote instalado ou o do repo, pelo caminho deste módulo
    ap = argparse.ArgumentParser(description=_(HELP), formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--suite", default=str(root / "spec" / "conformance"))
    ap.add_argument("--schema", default=str(kg_validate.CONTRACT_MUST))
    ap.add_argument("--should-schema", default=str(kg_validate.CONTRACT_SHOULD))
    ap.add_argument("--json")
    ap.add_argument("--proposals-schema", help=_("candidate MUST, only for proposals/"))
    ap.add_argument("--proposals-should-schema", help=_("candidate SHOULD, only for proposals/"))
    args = ap.parse_args(argv)
    _utf8_stdio()
    if bool(args.proposals_schema) != bool(args.proposals_should_schema):
        ap.error(_("--proposals-schema and --proposals-should-schema go together"))
    suite = pathlib.Path(args.suite)
    try:
        meta = load_json(suite / "manifest.schema.json")
        try:
            Draft202012Validator.check_schema(meta)
        except SchemaError as exc:
            raise SuiteBroken(_("manifest.schema.json is not a valid JSON Schema: {message}").format(
                message=exc.message)) from exc
        broken = suite_errors(suite, Draft202012Validator(meta))
        if broken:
            raise SuiteBroken("\n".join(broken))
        schemas = []
        paths = [args.schema, args.should_schema]
        if args.proposals_schema:
            paths += [args.proposals_schema, args.proposals_should_schema]
        for path in paths:
            data = load_json(pathlib.Path(path))
            try:
                Draft202012Validator.check_schema(data)
            except SchemaError as exc:
                raise SuiteBroken(_("{path}: is not a valid JSON Schema: {message}").format(
                    path=path, message=exc.message)) from exc
            schemas.append(kg_validate.make_validator(data))
        validator, should_validator = schemas[:2]
        proposals = tuple(schemas[2:]) or None
    except SuiteBroken as exc:
        for line in str(exc).splitlines():
            print(_("BROKEN SUITE  {line}").format(line=line))
        return 2
    results = run_cases(suite, validator, should_validator, proposals)
    for r in results:
        line = f"{'PASS' if r['pass'] else 'FAIL'}  {r['case']}"
        if not r["pass"]:
            if "error" in r:
                line += "  " + _("expected {expected}  ERROR {error}").format(expected=r["expected"], error=r["error"])
            else:
                line += "  " + _("expected {expected}  emitted {emitted}").format(expected=r["expected"],
                                                                                 emitted=r["emitted"])
        print(line)
    print("—")
    for folder in FOLDERS:
        rows = [r for r in results if r["folder"] == folder]
        if rows:
            ok = sum(r["pass"] for r in rows)
            # o prefixo "<pasta>: N/M" é o mesmo nas duas línguas: o CI e quem lê a saída procuram "latest:"
            if folder == "latest":
                msg = _("{folder}: {ok}/{total} (gates the rc)")
            elif folder == "proposals" and proposals:
                msg = _("{folder}: {ok}/{total} (report only, against {schema})")
            else:
                msg = _("{folder}: {ok}/{total} (report only)")
            print(msg.format(folder=folder, ok=ok, total=len(rows),
                             schema=pathlib.Path(args.proposals_schema or "").name))
    if args.json:
        def shown(path):
            path = pathlib.Path(path).resolve()
            return str(path.relative_to(root)) if path.is_relative_to(root) else path.name
        with open(args.json, "w", encoding="utf-8") as fh:
            json.dump({"reader": "kg_validate.py", "schema": shown(args.schema),
                       "should_schema": shown(args.should_schema),
                       **({"proposals_schema": shown(args.proposals_schema),
                           "proposals_should_schema": shown(args.proposals_should_schema)} if proposals else {}),
                       "results": results},
                      fh, ensure_ascii=False, indent=1)
    return 1 if any(not r["pass"] for r in results if r["folder"] == "latest") else 0


if __name__ == "__main__":
    sys.exit(main())
