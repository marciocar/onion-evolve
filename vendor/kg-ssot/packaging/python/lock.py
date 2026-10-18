#!/usr/bin/env python3
"""Gera requirements-build.txt: as ferramentas de build do pacote PyPI em versão exata, com o sha256 de TODO arquivo
publicado de cada versão, tirado da API JSON do PyPI. Assim o build no CI instala com --require-hashes e roda
python -m build --no-isolation, sem baixar backend sem conferência.

Uso (precisa de rede): python3 -I packaging/python/lock.py > packaging/python/requirements-build.txt
Mudar uma versão é editar PINS e rodar de novo. Com pinos na linha de comando (nome==versão ...), trava só eles:
python3 -I packaging/python/lock.py uv==0.13.1 > packaging/mcpb/requirements-uv.txt
"""
import json
import sys
import urllib.request

# o frontend (build), o backend (hatchling) e as dependências deles, todas fixadas; o colorama o build só pede no
# Windows (marcador sys_platform == "win32"), e sem ele o --require-hashes recusa a instalação lá
PINS = {"build": "1.6.1", "pyproject_hooks": "1.3.3", "packaging": "26.3", "hatchling": "1.32.4",
        "pathspec": "1.1.1", "pluggy": "1.7.0", "trove-classifiers": "2026.9.21.13", "tomlkit": "0.15.2",
        "colorama": "0.4.6"}


def hashes(name, version):
    with urllib.request.urlopen(f"https://pypi.org/pypi/{name}/{version}/json", timeout=30) as r:
        files = json.load(r)["urls"]
    if not files:
        raise SystemExit(f"{name}=={version} sem arquivos publicados")
    return sorted(f["digests"]["sha256"] for f in files)


def main(argv=None):
    argv = sys.argv[1:] if argv is None else argv
    pins = dict(a.split("==", 1) for a in argv) if argv else PINS
    out = (["# Gerado por packaging/python/lock.py a partir da API JSON do PyPI: versão exata e o sha256 de cada arquivo",
            "# publicado. Instale com --require-hashes."] if argv else
           ["# Ferramentas de build do pacote PyPI do KG-SSOT, em versão exata e com o sha256 de cada arquivo publicado",
            "# (gerado por packaging/python/lock.py a partir da API JSON do PyPI). Instale com --require-hashes e rode",
            "# python -m build --no-isolation."])
    for name, version in pins.items():
        lines = [f"{name}=={version} \\"] + [f"    --hash=sha256:{h} \\" for h in hashes(name, version)]
        lines[-1] = lines[-1].rstrip(" \\")
        out += lines
    sys.stdout.write("\n".join(out) + "\n")


if __name__ == "__main__":
    main()
