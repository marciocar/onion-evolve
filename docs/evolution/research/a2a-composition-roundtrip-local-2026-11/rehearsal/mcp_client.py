#!/usr/bin/env python3
# Cliente MCP stdio mínimo (JSON-RPC 2.0, uma mensagem por linha). Sobe o servidor, faz initialize +
# notifications/initialized e depois cada pedido dado em JSON no argv: [method, params]. Imprime uma linha JSON
# por resposta. Uso: mcp_client.py <server.py> '<json [method, params]>' ...
import json
import subprocess
import sys

server = sys.argv[1]
reqs = [json.loads(a) for a in sys.argv[2:]]
p = subprocess.Popen([sys.executable, "-I", server], stdin=subprocess.PIPE, stdout=subprocess.PIPE, text=True)


def call(i, method, params):
    p.stdin.write(json.dumps({"jsonrpc": "2.0", "id": i, "method": method, "params": params}) + "\n")
    p.stdin.flush()
    return json.loads(p.stdout.readline())


init = call(0, "initialize", {"protocolVersion": "2025-06-18", "capabilities": {},
                               "clientInfo": {"name": "rehearsal-client", "version": "0"}})
print(json.dumps({"initialize": init["result"]["serverInfo"]}, ensure_ascii=False))
p.stdin.write(json.dumps({"jsonrpc": "2.0", "method": "notifications/initialized"}) + "\n")
p.stdin.flush()
for i, (method, params) in enumerate(reqs, start=1):
    print(json.dumps(call(i, method, params), ensure_ascii=False))
p.stdin.close()
p.wait(timeout=10)
