#!/usr/bin/env python3
# Sonda stdio de um servidor MCP, sem modelo. Uma linha JSON por pedido, resposta casada por id.
# Uso: mcp_probe.py <servidor.py> [args do servidor...]   (ambiente do servidor vem do chamador)
import json, subprocess, sys
srv = sys.argv[1:]
META = {"io.modelcontextprotocol/protocolVersion": "2026-07-28",
        "io.modelcontextprotocol/clientCapabilities": {},
        "io.modelcontextprotocol/clientInfo": {"name": "probe", "version": "0"}}
SEQ = [("server/discover", {"_meta": META}), ("tools/list", {"_meta": META}), ("roots/list", {"_meta": META}),
       ("initialize", {"protocolVersion": "2026-07-28", "capabilities": {},
                       "clientInfo": {"name": "probe", "version": "0"}}),
       ("initialize", {"protocolVersion": "2025-11-25", "capabilities": {},
                       "clientInfo": {"name": "probe", "version": "0"}})]
for i, (method, params) in enumerate(SEQ, 1):
    p = subprocess.run([sys.executable, *srv], input=json.dumps({"jsonrpc": "2.0", "id": i, "method": method, "params": params}) + "\n",
                       capture_output=True, text=True, timeout=60)
    line = next((l for l in p.stdout.splitlines() if l.strip()), "")
    try:
        r = json.loads(line)
    except ValueError:
        print(json.dumps({"method": method, "raw": line[:200], "stderr": p.stderr[:200]})); continue
    res = r.get("result") or {}
    print(json.dumps({"method": method, "asked": params.get("protocolVersion"),
                      "error": (r.get("error") or {}).get("code"),
                      "protocolVersion": res.get("protocolVersion"),
                      "supportedVersions": res.get("supportedVersions"),
                      "tools": len(res["tools"]) if "tools" in res else None}, ensure_ascii=False))
