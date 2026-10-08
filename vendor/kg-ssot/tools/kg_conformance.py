#!/usr/bin/env python3
"""Runner da suíte de conformidade do .kg.yaml para o leitor de referência (kg_validate.py).

Depende só de Python 3, PyYAML e jsonschema (D_KG_SSOT_INDEPENDENTE_DE_HARNESS). É o molde que os
outros leitores imitam no E4: para cada caso, o conjunto de códigos emitidos tem de ser IGUAL ao
esperado, em codes (MUST) e em warnings (SHOULD).

Passos:
  1. auto-teste do metaschema: aceita metaschema-tests/good/ e recusa metaschema-tests/bad/;
  2. cada manifest.json (em fixtures/, a convenção que o lint do Onion isenta) valida contra manifest.schema.json, cumpre a regra de pending_on da pasta
     (vazio em latest/, não vazio em proposals/) e aponta só para arquivos que existem;
  3. cada caso roda no leitor e é comparado por conjunto.

rc: 0 se latest/ passa inteiro · 1 se algum caso de latest/ falha (inclusive o leitor caindo nele)
· 2 se a própria suíte está quebrada: metaschema ou manifesto ilegível ou inválido, pending_on fora
da regra, pasta desconhecida, arquivo ausente, repetido ou fora de todo manifesto, latest/ vazia.
optional/ e proposals/ reportam e nunca mudam o rc.

Uso:
  kg_conformance.py [--suite spec/conformance] [--schema spec/kg-contract-v3.schema.json]
                    [--should-schema spec/kg-contract-v3.should.schema.json] [--json OUT]
"""
import argparse
import json
import pathlib
import sys

from jsonschema import Draft202012Validator
from jsonschema.exceptions import SchemaError

sys.dont_write_bytecode = True  # num vendor, rodar a suíte não pode sujar o diretório carimbado
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import kg_validate  # noqa: E402  (o leitor de referência mora ao lado)

FOLDERS = ("latest", "optional", "proposals")


class SuiteBroken(Exception):
    """A própria suíte está quebrada: rc 2, nunca confundido com um leitor que falha (rc 1)."""


def load_json(path):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise SuiteBroken(f"{path}: não deu para ler como JSON ({exc.__class__.__name__}: {exc})") from exc


def suite_errors(suite, meta_validator):
    """Defeitos da própria suíte. Qualquer um vale rc 2."""
    out = []
    tests = suite / "metaschema-tests"
    found = {"good": 0, "bad": 0}
    for f in sorted(tests.glob("*/*.json")):
        kind = f.parent.name
        if kind not in found:
            out.append(f"metaschema: {f.relative_to(suite)} está fora de good/ e bad/")
            continue
        found[kind] += 1
        accepted = not list(meta_validator.iter_errors(load_json(f)))
        if accepted != (kind == "good"):
            out.append(f"metaschema: {f.relative_to(suite)} foi {'aceito' if accepted else 'recusado'}")
    out += [f"metaschema: nenhum teste em metaschema-tests/{k}/" for k, n in found.items() if not n]

    cases_root = suite / "fixtures"
    referenced, latest_cases = set(), 0
    for m in sorted(cases_root.glob("*/**/manifest.json")):
        rel = m.relative_to(cases_root)
        folder = rel.parts[0]
        if folder not in FOLDERS:
            out.append(f"{rel}: pasta '{folder}' fora de {', '.join(FOLDERS)}")
            continue
        data = load_json(m)
        errs = list(meta_validator.iter_errors(data))
        if errs:
            out += [f"{rel}: {e.message}" for e in errs]
            continue
        if folder == "latest" and data["pending_on"]:
            out.append(f"{rel}: latest/ não pode depender de decisão aberta ({', '.join(data['pending_on'])})")
        if folder == "proposals" and not data["pending_on"]:
            out.append(f"{rel}: proposals/ exige pending_on não vazio")
        files = [c["file"] for c in data["cases"]]
        out += [f"{rel}: arquivo repetido no manifesto: {f}" for f in sorted({f for f in files if files.count(f) > 1})]
        out += [f"{rel}: caso sem arquivo {f}" for f in files if not (m.parent / f).is_file()]
        referenced |= {(m.parent / f).resolve() for f in files}
        latest_cases += len(files) if folder == "latest" else 0
    # Um arquivo de caso fora de todo manifesto nunca roda, e ninguém fica sabendo.
    for f in sorted(list(cases_root.rglob("*.yaml"))):
        if f.resolve() not in referenced:
            out.append(f"{f.relative_to(cases_root)}: arquivo de caso fora de todo manifesto")
    if not latest_cases:
        out.append("latest/ sem nenhum caso: a suíte passaria por vacuidade")
    return out


def run_cases(suite, validator, should_validator):
    results = []
    cases_root = suite / "fixtures"
    for m in sorted(cases_root.glob("*/**/manifest.json")):
        data = load_json(m)
        for case in data["cases"]:
            path = m.parent / case["file"]
            want_codes = sorted(set(case["codes"]))
            want_warn = sorted(set(case.get("warnings", [])))
            row = {
                "folder": m.relative_to(cases_root).parts[0],
                "case": str(path.relative_to(cases_root)),
                "pending_on": data["pending_on"],
                "expected": {"codes": want_codes, "warnings": want_warn},
            }
            try:
                text = path.read_text(encoding="utf-8")
                got_codes = sorted(set(kg_validate.codes(text, validator)))
                got_warn = sorted(set(kg_validate.warnings(text, validator, should_validator)))
            except Exception as exc:  # noqa: BLE001 — o leitor caiu: falha DO CASO, o gate da pasta decide o rc
                row.update({"pass": False, "emitted": None, "error": f"{exc.__class__.__name__}: {exc}"})
            else:
                row.update({"pass": got_codes == want_codes and got_warn == want_warn,
                            "emitted": {"codes": got_codes, "warnings": got_warn}})
            results.append(row)
    return results


def main(argv=None):
    root = pathlib.Path(__file__).resolve().parent.parent
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--suite", default=str(root / "spec" / "conformance"))
    ap.add_argument("--schema", default=str(kg_validate.CONTRACT_MUST))
    ap.add_argument("--should-schema", default=str(kg_validate.CONTRACT_SHOULD))
    ap.add_argument("--json")
    args = ap.parse_args(argv)
    suite = pathlib.Path(args.suite)
    try:
        meta = load_json(suite / "manifest.schema.json")
        try:
            Draft202012Validator.check_schema(meta)
        except SchemaError as exc:
            raise SuiteBroken(f"manifest.schema.json não é JSON Schema válido: {exc.message}") from exc
        broken = suite_errors(suite, Draft202012Validator(meta))
        if broken:
            raise SuiteBroken("\n".join(broken))
        schemas = []
        for path in (args.schema, args.should_schema):
            data = load_json(pathlib.Path(path))
            try:
                Draft202012Validator.check_schema(data)
            except SchemaError as exc:
                raise SuiteBroken(f"{path}: não é JSON Schema válido: {exc.message}") from exc
            schemas.append(kg_validate.make_validator(data))
        validator, should_validator = schemas
    except SuiteBroken as exc:
        for line in str(exc).splitlines():
            print(f"SUÍTE QUEBRADA  {line}")
        return 2
    results = run_cases(suite, validator, should_validator)
    for r in results:
        line = f"{'PASS' if r['pass'] else 'FAIL'}  {r['case']}"
        if not r["pass"]:
            line += f"  esperado {r['expected']}  " + (f"ERRO {r['error']}" if "error" in r else f"emitido {r['emitted']}")
        print(line)
    print("—")
    for folder in FOLDERS:
        rows = [r for r in results if r["folder"] == folder]
        if rows:
            ok = sum(r["pass"] for r in rows)
            gate = "reprova" if folder == "latest" else "só reporta"
            print(f"{folder}: {ok}/{len(rows)} ({gate})")
    if args.json:
        def shown(path):
            path = pathlib.Path(path).resolve()
            return str(path.relative_to(root)) if path.is_relative_to(root) else path.name
        with open(args.json, "w", encoding="utf-8") as fh:
            json.dump({"reader": "kg_validate.py", "schema": shown(args.schema),
                       "should_schema": shown(args.should_schema), "results": results},
                      fh, ensure_ascii=False, indent=1)
    return 1 if any(not r["pass"] for r in results if r["folder"] == "latest") else 0


if __name__ == "__main__":
    sys.exit(main())
