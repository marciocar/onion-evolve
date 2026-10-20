#!/usr/bin/env python3
"""Constrói a imagem OCI do kg-mcp a partir do wheel da release.

Monta um contexto só com o wheel e o tools/requirements.txt (as dependências por hash) e roda o docker build com o
packaging/oci/Dockerfile. É o mesmo caminho no teste, no CI e no workflow do espelho.
Uso: python3 -I packaging/oci/build.py --wheel dist/pypi/kg_ssot-X.Y.Z-py3-none-any.whl --tag kg-ssot:X.Y.Z
Sai 0 com a imagem construída, 2 com a entrada quebrada e o rc do docker quando o build falha.
"""
import argparse
import json
import pathlib
import re
import shutil
import subprocess
import sys
import tempfile

ROOT = pathlib.Path(__file__).resolve().parent.parent.parent
HERE = ROOT / "packaging" / "oci"
WHEEL = re.compile(r"^kg_ssot-(\d+\.\d+\.\d+)-py3-none-any\.whl$")


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--wheel", required=True, type=pathlib.Path, help="o wheel da release (packaging/python/build.py)")
    ap.add_argument("--tag", action="append", required=True, help="a tag da imagem (repetível)")
    args = ap.parse_args(argv)
    m = WHEEL.match(args.wheel.name)
    if not m or not args.wheel.is_file():
        print(f"ENTRADA QUEBRADA  {args.wheel} não é um wheel kg_ssot-X.Y.Z-py3-none-any.whl", file=sys.stderr)
        return 2
    version = m.group(1)
    want = json.loads((ROOT / "spec" / "release.json").read_text(encoding="utf-8"))["version"]
    if version != want:
        print(f"ENTRADA QUEBRADA  o wheel é da {version}, e o spec/release.json é da {want}", file=sys.stderr)
        return 2
    with tempfile.TemporaryDirectory() as ctx:
        shutil.copy(args.wheel, ctx)
        shutil.copy(ROOT / "tools" / "requirements.txt", pathlib.Path(ctx) / "requirements.txt")
        cmd = ["docker", "build", "--pull=false", "-f", str(HERE / "Dockerfile"), "--build-arg", f"VERSION={version}"]
        for tag in args.tag:
            cmd += ["-t", tag]
        return subprocess.run(cmd + [ctx]).returncode


if __name__ == "__main__":
    sys.exit(main())
