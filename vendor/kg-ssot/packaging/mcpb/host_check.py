#!/usr/bin/env python3
"""Roda o MCPB desempacotado como um host o roda (o comando do mcp_config, com uv run) e confere o servidor:
initialize, as 7 ferramentas, kg_write de um grafo válido e recusa de um inválido, kg_history com a gravação, o modo
só leitura sem kg_write nem kg_delete, uma raiz dentro de um repo git (o armazém passa ao git) e uma raiz que não abre
(o servidor sobe só com o julgamento e diz o motivo ao modelo).

Uso: python3 -I packaging/mcpb/host_check.py <bundle desempacotado> <dir com o wheel kg-ssot> <dir de trabalho>
O wheel entra por UV_FIND_LINKS, para testar o pacote desta árvore. rc 0 tudo certo, 1 alguma conferência falhou.
"""
import json
import os
import pathlib
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
VALID = (ROOT / "spec/conformance/fixtures/latest/form/minimal/valid-minimal.kg.yaml").read_text(encoding="utf-8")
INVALID = (ROOT / "spec/conformance/fixtures/latest/form/minimal/bad-node-missing-label.kg.yaml").read_text(encoding="utf-8")


def session(bundle, wheels, root, read_only, calls):
    msgs = [{"jsonrpc": "2.0", "id": 0, "method": "initialize",
             "params": {"protocolVersion": "2025-11-25", "capabilities": {}, "clientInfo": {"name": "ci", "version": "1"}}},
            {"jsonrpc": "2.0", "method": "notifications/initialized"},
            {"jsonrpc": "2.0", "id": 1, "method": "tools/list"}]
    msgs += [{"jsonrpc": "2.0", "id": i, "method": "tools/call", "params": {"name": n, "arguments": a}}
             for i, (n, a) in enumerate(calls, start=2)]
    env = dict(os.environ, UV_FIND_LINKS=str(wheels))
    manifest = json.loads((pathlib.Path(bundle) / "manifest.json").read_text(encoding="utf-8"))
    cfg = manifest["server"]["mcp_config"]
    sub = {"${__dirname}": str(bundle), "${user_config.root}": str(root), "${user_config.read_only}": read_only}
    args = [sub.get(a, a) for a in cfg["args"]]
    p = subprocess.run([cfg["command"], *args], input="\n".join(json.dumps(m) for m in msgs) + "\n",
                       capture_output=True, text=True, encoding="utf-8", errors="replace", env=env,
                       timeout=300)
    out = {d.get("id"): d for d in map(json.loads, p.stdout.splitlines())}
    return out, p


def text(resp):
    return json.loads(resp["result"]["content"][0]["text"])


def main(bundle, wheels, work):
    if hasattr(sys.stdout, "reconfigure"):  # no Windows, a saída em pipe seria cp1252, sem o ✓
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    work = pathlib.Path(work)
    fails = []
    out, p = session(bundle, wheels, work / "store", "false",
                     [("kg_write", {"name": "a.kg.yaml", "text": VALID}),
                      ("kg_write", {"name": "b.kg.yaml", "text": INVALID}),
                      ("kg_history", {"name": "a.kg.yaml"})])
    tools = [t["name"] for t in out.get(1, {}).get("result", {}).get("tools", [])]
    checks = [("7 ferramentas", len(tools) == 7),
              ("grava o válido", text(out[2]).get("written") is True),
              ("recusa o inválido", text(out[3]).get("reason") == "gate"),
              ("kg_history com a gravação", len(text(out[4]).get("history", [])) == 1)]
    out, _ = session(bundle, wheels, work / "store", "true", [])
    ro = [t["name"] for t in out[1]["result"]["tools"]]
    checks.append(("só leitura sem kg_write nem kg_delete", "kg_write" not in ro and "kg_delete" not in ro))
    repo = work / "repo"
    repo.mkdir(parents=True, exist_ok=True)
    subprocess.run(["git", "-C", str(repo), "init", "-q"], check=True)
    out, _ = session(bundle, wheels, repo / "kg", "false", [("kg_write", {"name": "a.kg.yaml", "text": VALID})])
    checks.append(("raiz dentro de repo git grava pelo git", 2 in out and text(out[2]).get("written") is True))
    blocker = work / "arquivo"
    blocker.write_text("não é pasta", encoding="utf-8")
    out, _ = session(bundle, wheels, blocker / "kg", "false", [])
    bare = [t["name"] for t in out.get(1, {}).get("result", {}).get("tools", [])]
    note = out.get(0, {}).get("result", {}).get("instructions", "")
    checks.append(("raiz que não abre: só o julgamento, com o motivo ao modelo",
                   sorted(bare) == ["kg_schema_help", "kg_validate"] and "ARMAZÉM INDISPONÍVEL" in note))
    for name, ok in checks:
        print(("✓ " if ok else "✗ ") + name)
        if not ok:
            fails.append(name)
    if fails:
        print(p.stderr[-800:])
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main(*sys.argv[1:4]))
