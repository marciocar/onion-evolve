#!/usr/bin/env python3
"""Sink OTLP/HTTP-JSON local mínimo — prova barata (Nota 01).
Local-first: escuta em 127.0.0.1, grava o que recebe em ndjson por sinal.
NÃO decodifica conteúdo — só guarda a estrutura que o Claude Code emite (intake)."""
import gzip, json, sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

OUT = sys.argv[1] if len(sys.argv) > 1 else "/tmp/otlp"
SIGNALS = {"/v1/metrics": "metrics", "/v1/logs": "logs", "/v1/traces": "traces"}

class H(BaseHTTPRequestHandler):
    def log_message(self, *a):  # silencia log de acesso
        pass

    def _read_body(self):
        te = (self.headers.get("Transfer-Encoding") or "").lower()
        if "chunked" in te:
            buf = b""
            while True:
                line = self.rfile.readline().strip()
                if not line:
                    continue
                try:
                    size = int(line.split(b";")[0], 16)
                except ValueError:
                    break
                if size == 0:
                    self.rfile.readline()  # trailing CRLF
                    break
                buf += self.rfile.read(size)
                self.rfile.read(2)  # CRLF after chunk
            return buf
        n = int(self.headers.get("Content-Length", 0))
        return self.rfile.read(n)

    def do_POST(self):
        body = self._read_body()
        if self.headers.get("Content-Encoding") == "gzip":
            try:
                body = gzip.decompress(body)
            except Exception:
                pass
        sig = SIGNALS.get(self.path, "other")
        ctype = self.headers.get("Content-Type", "?")
        try:
            obj = json.loads(body.decode("utf-8"))
            with open(f"{OUT}/{sig}.ndjson", "a") as f:
                f.write(json.dumps(obj) + "\n")
        except Exception as e:
            # não é JSON (provável protobuf) — guarda cru p/ inspeção e conta
            with open(f"{OUT}/{sig}.raw", "ab") as f:
                f.write(body)
            with open(f"{OUT}/meta.log", "a") as f:
                f.write(f"{self.path} ctype={ctype} bytes={len(body)} err={e}\n")
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(b"{}")

if __name__ == "__main__":
    import os
    os.makedirs(OUT, exist_ok=True)
    print(f"OTLP sink -> {OUT} (127.0.0.1:4318)", flush=True)
    ThreadingHTTPServer(("127.0.0.1", 4318), H).serve_forever()
