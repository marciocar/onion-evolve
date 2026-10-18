#!/usr/bin/env python3
"""Monta o pacote PyPI kg-ssot (wheel e sdist) a partir da superfície da release, sem tocar no layout do repo.

Uso: python3 -I packaging/python/build.py --outdir DIR | --stage-only DIR

Copia para um diretório temporário os módulos do kit (tools/kg_*.py que viajam no pacote), o spec/ que a release leva,
o README do PyPI, a LICENSE e o NOTICE, escreve o pyproject.toml com a versão do spec/release.json e roda
`python -m build --no-isolation`. As ferramentas de build vêm de packaging/python/requirements-build.txt, instaladas
com --require-hashes. No pacote, cada módulo acha o spec/ ao lado de si (kg_ssot/spec), e no repo, no diretório pai.

SOURCE_DATE_EPOCH, quando definido, vai para o build (o hatchling o usa para datar os arquivos do wheel).
rc: 0 ok · 1 o build falhou · 2 entrada quebrada.
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
# os módulos que viajam no pacote: o leitor, a suíte, o gate, o armazém, o servidor MCP e o exportador PROV-O.
# O kg_vendor.py fica de fora: ele serve ao vendor por pin, que é outro canal.
MODULES = ["kg_validate", "kg_conformance", "kg_gate", "kg_store", "kg_mcp", "kg_prov_export"]
# kg-ssot é o servidor MCP (o mesmo kg-mcp): o MCP Registry e os clientes rodam `uvx kg-ssot` pelo nome do pacote
SCRIPTS = {"kg-ssot": "kg_mcp", "kg-validate": "kg_validate", "kg-conformance": "kg_conformance", "kg-gate": "kg_gate",
           "kg-store": "kg_store", "kg-mcp": "kg_mcp", "kg-prov-export": "kg_prov_export"}
MIRROR = "https://github.com/marciocar/kg-ssot"

PYPROJECT = """[build-system]
requires = ["hatchling>=1.27"]
build-backend = "hatchling.build"

[project]
name = "kg-ssot"
version = "{version}"
description = "Contrato formal do grafo de conhecimento verificável (.kg.yaml e .kg.json): leitor de referência, suíte de conformidade, gate por grafo, armazém e servidor MCP."
readme = "README.md"
requires-python = ">=3.11"
license = "Apache-2.0"
license-files = ["LICENSE", "NOTICE"]
authors = [{{ name = "Marcio Carvalho" }}]
keywords = ["knowledge-graph", "provenance", "json-schema", "conformance", "yaml", "json", "mcp", "verifiable", "audit"]
classifiers = [
    "Development Status :: 4 - Beta",
    "Intended Audience :: Developers",
    "Intended Audience :: Information Technology",
    "Natural Language :: Portuguese (Brazilian)",
    "Operating System :: OS Independent",
    "Programming Language :: Python :: 3",
    "Programming Language :: Python :: 3 :: Only",
    "Programming Language :: Python :: 3.11",
    "Programming Language :: Python :: 3.12",
    "Programming Language :: Python :: 3.13",
    "Topic :: Software Development :: Quality Assurance",
    "Topic :: Software Development :: Testing",
    "Topic :: Text Processing :: Markup",
]
dependencies = ["PyYAML>=6.0.2", "jsonschema>=4.23"]

[project.urls]
Homepage = "{mirror}"
Documentation = "{mirror}/tree/main/docs/manual"
Source = "{mirror}"
Issues = "{mirror}/issues"
Releases = "{mirror}/tags"

[project.scripts]
{scripts}

[tool.hatch.build.targets.wheel]
packages = ["src/kg_ssot"]

[tool.hatch.build.targets.sdist]
include = ["src/kg_ssot", "README.md", "LICENSE", "NOTICE", "pyproject.toml"]
"""

INIT = '''"""KG-SSOT: o contrato formal do grafo de conhecimento verificável.

Os módulos são os do kit de adoção (kg_validate, kg_conformance, kg_gate, kg_store, kg_mcp, kg_prov_export), e o
contrato, a suíte e o schema do veredito ficam em kg_ssot/spec. Os comandos kg-validate, kg-conformance, kg-gate,
kg-store, kg-mcp e kg-prov-export são os mesmos scripts do kit. Manual: {mirror}/tree/main/docs/manual
"""
__version__ = "{version}"
'''


class Broken(Exception):
    pass


def release():
    try:
        rel = json.loads((ROOT / "spec" / "release.json").read_text(encoding="utf-8"))
    except (OSError, ValueError) as exc:
        raise Broken(f"spec/release.json ilegível: {exc}") from exc
    if not rel.get("version"):
        raise Broken("spec/release.json sem version")
    return rel


def stage(dest):
    """Monta o projeto em dest e devolve a versão."""
    rel = release()
    version = rel["version"]
    pkg = dest / "src" / "kg_ssot"
    pkg.mkdir(parents=True)
    for m in MODULES:
        shutil.copy2(ROOT / "tools" / f"{m}.py", pkg / f"{m}.py")
    # o spec/ que a release leva (arquivos e diretórios listados), e nada além dele
    spec_entries = [e for e in rel["files"] if e.startswith("spec/")]
    if not spec_entries:
        raise Broken("a release não lista nada em spec/")
    for entry in spec_entries:
        src = ROOT / entry
        target = pkg / entry
        if entry.endswith("/"):
            shutil.copytree(src, target, ignore=shutil.ignore_patterns("__pycache__", "*.pyc"))
        else:
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(src, target)
    (pkg / "__init__.py").write_text(INIT.format(version=version, mirror=MIRROR), encoding="utf-8")
    for name in ("LICENSE", "NOTICE"):
        shutil.copy2(ROOT / name, dest / name)
    shutil.copy2(HERE / "README.md", dest / "README.md")
    scripts = "\n".join(f'{cmd} = "kg_ssot.{mod}:main"' for cmd, mod in SCRIPTS.items())
    (dest / "pyproject.toml").write_text(PYPROJECT.format(version=version, mirror=MIRROR, scripts=scripts),
                                         encoding="utf-8")
    return version


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--outdir", help="onde gravar wheel e sdist; obrigatório sem --stage-only (fora da árvore: no vendor, um "
                                     "dist/ dentro dela faria o kg_vendor.py check reprovar)")
    ap.add_argument("--stage-only", metavar="DIR", help="só monta o projeto em DIR (vazio ou inexistente), sem buildar")
    a = ap.parse_args(argv)
    try:
        if a.stage_only:
            dest = pathlib.Path(a.stage_only)
            if dest.exists() and any(dest.iterdir()):
                raise Broken(f"{dest} não está vazio")
            dest.mkdir(parents=True, exist_ok=True)
            print(f"projeto montado em {dest}: kg-ssot {stage(dest)}")
            return 0
        if not a.outdir:
            raise Broken("diga --outdir (fora da árvore do repo ou do vendor)")
        with tempfile.TemporaryDirectory(prefix="kg-ssot-pypi-") as tmp:
            dest = pathlib.Path(tmp) / "kg-ssot"
            dest.mkdir()
            version = stage(dest)
            out = pathlib.Path(a.outdir).resolve()
            p = subprocess.run([sys.executable, "-m", "build", "--no-isolation", "--sdist", "--wheel",
                                "--outdir", str(out), str(dest)], cwd=tmp)  # fora do repo: o packaging/ daqui não sombreia o do PyPI
            if p.returncode:
                print(f"BUILD FALHOU  rc {p.returncode}")
                return 1
            print(f"kg-ssot {version}: " + ", ".join(sorted(x.name for x in out.glob(f"kg_ssot-{version}*"))))
            return 0
    except (Broken, OSError) as exc:
        print(f"ENTRADA QUEBRADA  {exc}")
        return 2


if __name__ == "__main__":
    sys.exit(main())
