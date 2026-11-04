#!/usr/bin/env python3
# Backend gravador: responde o card em GET e grava sha256 do corpo em POST. Só 127.0.0.1, encerra pelo TTL.
# Uso: agw_backend.py <arquivo-da-porta> <log> <ttl-s> <card.json>
import hashlib, http.server, json, os, sys, threading
PF, LOG, TTL, CARD = sys.argv[1], sys.argv[2], int(sys.argv[3]), open(sys.argv[4], "rb").read()
threading.Timer(TTL, lambda: os._exit(0)).start()
class H(http.server.BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"
    def log_message(self, *a): pass
    def _r(self, b):
        self.send_response(200); self.send_header("content-type", "application/json"); self.send_header("content-length", str(len(b))); self.end_headers(); self.wfile.write(b)
    def do_GET(self): self._r(CARD)
    def do_POST(self):
        raw = self.rfile.read(int(self.headers.get("content-length", 0)))
        open(LOG, "a").write(json.dumps({"path": self.path, "sha256": hashlib.sha256(raw).hexdigest(), "len": len(raw), "auth": self.headers.get("authorization")}) + "\n")
        self._r(b'{"jsonrpc":"2.0","id":1,"result":{"ok":true}}')
srv = http.server.ThreadingHTTPServer(("127.0.0.1", 0), H)
open(PF, "w").write(str(srv.server_address[1])); srv.serve_forever()
