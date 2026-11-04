#!/usr/bin/env python3
"""Servidor MCP mínimo (stdio, só stdlib) para a rodada 2 dos spikes (lacuna a).

Expõe UMA ferramenta, `write_marker`, que escreve um arquivo (o MARKER.txt da célula) e
registra cada mensagem JSON-RPC recebida num log JSONL fora da pasta de trabalho. O efeito
(o arquivo) é a verdade de chão do classify.py, como nas ferramentas nativas.

Transporte: JSON-RPC 2.0, uma mensagem por linha no stdin/stdout (transporte stdio do MCP).
Métodos: initialize, notifications/initialized, tools/list, tools/call, ping. Qualquer outro
método com id recebe o erro -32601; notificações desconhecidas são ignoradas.

Uso: mcp_marker_server.py --log /abs/mcp.log
     mcp_marker_server.py --selftest      (conversa consigo mesmo por subprocess; rc 0 se ok)
"""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
import tempfile
import time

SERVER_NAME = "onionspike"
TOOL_NAME = "write_marker"
PROTOCOL_VERSION = "2025-06-18"

TOOL = {
    "name": TOOL_NAME,
    "description": "Write a marker file. Arguments: path (absolute path) and content.",
    "inputSchema": {
        "type": "object",
        "properties": {
            "path": {"type": "string", "description": "Absolute path of the file to write"},
            "content": {"type": "string", "description": "File content"},
        },
        "required": ["path", "content"],
        "additionalProperties": False,
    },
}


def log(path: str | None, rec: dict) -> None:
    if not path:
        return
    with open(path, "a", encoding="utf-8") as fh:
        fh.write(json.dumps({"ts": time.time(), "pid": os.getpid(), **rec}, ensure_ascii=False) + "\n")


def handle(msg: dict, log_path: str | None) -> dict | None:
    method, mid = msg.get("method"), msg.get("id")
    if method == "initialize":
        client_version = (msg.get("params") or {}).get("protocolVersion") or PROTOCOL_VERSION
        return {"jsonrpc": "2.0", "id": mid, "result": {
            "protocolVersion": client_version,
            "capabilities": {"tools": {"listChanged": False}},
            "serverInfo": {"name": SERVER_NAME, "version": "0.1.0"}}}
    if method == "ping":
        return {"jsonrpc": "2.0", "id": mid, "result": {}}
    if method == "tools/list":
        return {"jsonrpc": "2.0", "id": mid, "result": {"tools": [TOOL]}}
    if method == "tools/call":
        params = msg.get("params") or {}
        args = params.get("arguments") or {}
        if params.get("name") != TOOL_NAME:
            return {"jsonrpc": "2.0", "id": mid, "result": {
                "isError": True, "content": [{"type": "text", "text": f"unknown tool {params.get('name')!r}"}]}}
        path, content = args.get("path"), args.get("content")
        if not isinstance(path, str) or not os.path.isabs(path) or not isinstance(content, str):
            return {"jsonrpc": "2.0", "id": mid, "result": {
                "isError": True, "content": [{"type": "text", "text": "path must be absolute and content a string"}]}}
        with open(path, "w", encoding="utf-8") as fh:
            fh.write(content)
        log(log_path, {"event": "wrote", "path": path, "content": content})
        return {"jsonrpc": "2.0", "id": mid, "result": {
            "isError": False, "content": [{"type": "text", "text": f"wrote {path}"}]}}
    if mid is None:
        return None          # notificação (initialized, cancelled...): sem resposta
    return {"jsonrpc": "2.0", "id": mid, "error": {"code": -32601, "message": f"method not found: {method}"}}


def serve(log_path: str | None) -> int:
    log(log_path, {"event": "start", "argv": sys.argv[1:]})
    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue
        try:
            msg = json.loads(line)
        except json.JSONDecodeError:
            log(log_path, {"event": "bad_json", "raw": line[:500]})
            continue
        log(log_path, {"event": "recv", "msg": msg})
        resp = handle(msg, log_path) if isinstance(msg, dict) else None
        if resp is not None:
            sys.stdout.write(json.dumps(resp) + "\n")
            sys.stdout.flush()
    log(log_path, {"event": "eof"})
    return 0


def selftest() -> int:
    """Sobe o servidor por subprocess e confere initialize, tools/list e tools/call."""
    with tempfile.TemporaryDirectory(prefix="onion-mcp-selftest-") as t:
        target, logp = os.path.join(t, "MARKER.txt"), os.path.join(t, "mcp.log")
        msgs = [
            {"jsonrpc": "2.0", "id": 1, "method": "initialize",
             "params": {"protocolVersion": PROTOCOL_VERSION, "capabilities": {}, "clientInfo": {"name": "t", "version": "0"}}},
            {"jsonrpc": "2.0", "method": "notifications/initialized"},
            {"jsonrpc": "2.0", "id": 2, "method": "tools/list"},
            {"jsonrpc": "2.0", "id": 3, "method": "tools/call", "params": {"name": TOOL_NAME, "arguments": {"path": target, "content": "x"}}},
            {"jsonrpc": "2.0", "id": 4, "method": "tools/call", "params": {"name": TOOL_NAME, "arguments": {"path": "rel.txt", "content": "x"}}},
            {"jsonrpc": "2.0", "id": 5, "method": "nope"},
        ]
        r = subprocess.run([sys.executable, "-I", os.path.abspath(__file__), "--log", logp],
                           input="".join(json.dumps(m) + "\n" for m in msgs), capture_output=True, text=True, timeout=20)
        out = [json.loads(l) for l in r.stdout.splitlines() if l.strip()]
        checks = [
            ("rc 0", r.returncode == 0),
            ("5 responses (the notification has none)", len(out) == 5),
            ("initialize echoes protocol", out and out[0]["result"]["protocolVersion"] == PROTOCOL_VERSION),
            ("tools/list has write_marker", len(out) > 1 and out[1]["result"]["tools"][0]["name"] == TOOL_NAME),
            ("tools/call wrote the file", os.path.exists(target) and open(target).read() == "x"),
            ("relative path refused", len(out) > 3 and out[3]["result"]["isError"] is True),
            ("unknown method -32601", len(out) > 4 and out[4]["error"]["code"] == -32601),
            ("log has the write", any(json.loads(l).get("event") == "wrote" for l in open(logp))),
        ]
        fails = 0
        for name, ok in checks:
            fails += 0 if ok else 1
            print(f"{'ok  ' if ok else 'FAIL'}  MCP-SELFTEST {name}")
        return 1 if fails else 0


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--log", default=None)
    ap.add_argument("--selftest", action="store_true")
    a = ap.parse_args()
    return selftest() if a.selftest else serve(a.log)


if __name__ == "__main__":
    sys.exit(main())
