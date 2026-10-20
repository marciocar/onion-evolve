#!/usr/bin/env python3
"""Monta o pacote npm kg-ssot (o leitor JS do contrato) a partir da superfície da release e roda `npm pack`.

Uso: python3 -I packaging/npm/build.py --outdir DIR | --stage-only DIR

Copia para um diretório temporário o núcleo do leitor (tools/runners/ajv/kg.mjs, sem fs nem geração de código), o
lado Node (run.mjs), a entrada do pacote e o comando (packaging/npm/index.mjs e cli.mjs), os schemas do contrato
vigente e do veredito, o README do cadastro, a LICENSE e o NOTICE. Gera o validador MUST pré-compilado (must.mjs, sem
new Function nem eval) com tools/runners/ajv/standalone.mjs e escreve o package.json com a versão do
spec/release.json e as dependências exatas de tools/runners/ajv/package.json. As dependências de build vêm de
tools/runners/ajv/package-lock.json (npm ci nessa pasta). No pacote, o run.mjs acha o spec/ ao lado de si.

rc: 0 ok · 1 o pack falhou · 2 entrada quebrada.
"""
import argparse
import json
import pathlib
import shutil
import subprocess
import sys
import tempfile

ROOT = pathlib.Path(__file__).resolve().parents[2]
HERE = pathlib.Path(__file__).resolve().parent
AJV = ROOT / "tools" / "runners" / "ajv"
MIRROR = "https://github.com/marciocar/kg-ssot"
FILES = ["index.mjs", "index.d.mts", "kg.mjs", "core.d.mts", "must.mjs", "should.mjs", "validator.d.mts", "run.mjs", "node.d.mts", "cli.mjs", "spec/", "README.md",
         "LICENSE", "NOTICE"]


class Broken(Exception):
    pass


def release():
    try:
        rel = json.loads((ROOT / "spec" / "release.json").read_text(encoding="utf-8"))
    except (OSError, ValueError) as exc:
        raise Broken(f"spec/release.json ilegível: {exc}") from exc
    if not rel.get("version") or not rel.get("contract"):
        raise Broken("spec/release.json sem version ou contract")
    return rel


def manifest(version, deps):
    return {
        "name": "kg-ssot",
        "version": version,
        "description": "Leitor JS do contrato do grafo de conhecimento verificável KG-SSOT (.kg.yaml e .kg.json): "
                       "validador pré-compilado, sem eval, para Node e React Native/Expo.",
        "keywords": ["knowledge-graph", "provenance", "json-schema", "conformance", "yaml", "json", "validator",
                     "react-native", "expo", "verifiable"],
        "homepage": MIRROR,
        "repository": {"type": "git", "url": f"git+{MIRROR}.git"},
        "bugs": {"url": f"{MIRROR}/issues"},
        "license": "Apache-2.0",
        "author": "Marcio Carvalho",
        "type": "module",
        "main": "./index.mjs",
        "types": "./index.d.mts",
        "exports": {
            ".": {"types": "./index.d.mts", "default": "./index.mjs"},
            "./core": {"types": "./core.d.mts", "default": "./kg.mjs"},
            "./must": {"types": "./validator.d.mts", "default": "./must.mjs"},
            "./should": {"types": "./validator.d.mts", "default": "./should.mjs"},
            "./node": {"types": "./node.d.mts", "default": "./run.mjs"},
            "./spec/*": "./spec/*",
            "./package.json": "./package.json",
        },
        "bin": {"kg-ssot-validate": "cli.mjs"},
        "files": FILES,
        "sideEffects": False,
        "engines": {"node": ">=22.12"},
        "dependencies": deps,
    }


def stage(dest):
    rel = release()
    version = rel["version"]
    deps = json.loads((AJV / "package.json").read_text(encoding="utf-8"))["dependencies"]
    if not (AJV / "node_modules" / "ajv").is_dir():
        raise Broken(f"{AJV}/node_modules sem o ajv: rode npm ci em tools/runners/ajv")
    dest.mkdir(parents=True, exist_ok=True)
    for name in ("kg.mjs", "run.mjs"):
        shutil.copy2(AJV / name, dest / name)
    for name in ("index.mjs", "index.d.mts", "core.d.mts", "node.d.mts", "validator.d.mts", "cli.mjs", "README.md"):
        shutil.copy2(HERE / name, dest / name)
    (dest / "cli.mjs").chmod(0o755)
    for name in ("LICENSE", "NOTICE"):
        shutil.copy2(ROOT / name, dest / name)
    spec = dest / "spec"
    spec.mkdir()
    for p in ("release.json", "verdict.schema.json", pathlib.Path(rel["contract"]["must"]).name,
              pathlib.Path(rel["contract"]["should"]).name):
        shutil.copy2(ROOT / "spec" / p, spec / p)
    for out, extra in (("must.mjs", []), ("should.mjs", ["--should"])):
        p = subprocess.run(["node", str(AJV / "standalone.mjs"), str(dest / out), *extra], capture_output=True, text=True)
        if p.returncode:
            raise Broken(f"o validador pré-compilado {out} não saiu: {p.stderr.strip()[-300:]}")
    (dest / "package.json").write_text(json.dumps(manifest(version, deps), ensure_ascii=False, indent=2) + "\n",
                                       encoding="utf-8")
    return version


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--outdir", help="onde gravar o tarball; obrigatório sem --stage-only (fora da árvore: no vendor, um dist/ "
                                     "dentro dela faria o kg_vendor.py check reprovar)")
    ap.add_argument("--stage-only", metavar="DIR", help="só monta o pacote em DIR (vazio ou inexistente), sem npm pack")
    a = ap.parse_args(argv)
    try:
        if a.stage_only:
            dest = pathlib.Path(a.stage_only)
            if dest.exists() and any(dest.iterdir()):
                raise Broken(f"{dest} não está vazio")
            print(f"pacote montado em {dest}: kg-ssot {stage(dest)}")
            return 0
        if not a.outdir:
            raise Broken("diga --outdir (fora da árvore do repo ou do vendor)")
        with tempfile.TemporaryDirectory(prefix="kg-ssot-npm-") as tmp:
            dest = pathlib.Path(tmp) / "package"
            version = stage(dest)
            out = pathlib.Path(a.outdir).resolve()
            out.mkdir(parents=True, exist_ok=True)
            p = subprocess.run(["npm", "pack", "--ignore-scripts", "--pack-destination", str(out)], cwd=dest,
                               capture_output=True, text=True)
            if p.returncode:
                print(f"PACK FALHOU  rc {p.returncode}: {p.stderr.strip()[-300:]}")
                return 1
            print(f"kg-ssot {version}: {out / f'kg-ssot-{version}.tgz'}")
            return 0
    except (Broken, OSError) as exc:
        print(f"ENTRADA QUEBRADA  {exc}")
        return 2


if __name__ == "__main__":
    sys.exit(main())
