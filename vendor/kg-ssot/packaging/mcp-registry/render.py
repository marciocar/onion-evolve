#!/usr/bin/env python3
"""Escreve o server.json do MCP Registry para a release: a versão do spec/release.json e o sha256 do .mcpb anexado
à release do GitHub (o registro não o confere; o cliente confere antes de instalar).

Uso: python3 -I packaging/mcp-registry/render.py <arquivo .mcpb> <saída server.json>
O nome io.github.marciocar/kg-ssot casa com o mcp-name do README do pacote PyPI, que o registro confere.
"""
import hashlib
import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
HERE = pathlib.Path(__file__).resolve().parent


def render(mcpb, out):
    version = json.loads((ROOT / "spec/release.json").read_text(encoding="utf-8"))["version"]
    if pathlib.Path(mcpb).name != f"kg-ssot-{version}.mcpb":
        raise SystemExit(f"o bundle {mcpb} não é o da versão {version}")
    sha = hashlib.sha256(pathlib.Path(mcpb).read_bytes()).hexdigest()
    text = (HERE / "server.json.in").read_text(encoding="utf-8").replace("@VERSION@", version).replace("@MCPB_SHA256@", sha)
    json.loads(text)
    pathlib.Path(out).write_text(text, encoding="utf-8")
    print(f"server.json: kg-ssot {version}, mcpb {sha[:12]}")


if __name__ == "__main__":
    render(*sys.argv[1:3])
