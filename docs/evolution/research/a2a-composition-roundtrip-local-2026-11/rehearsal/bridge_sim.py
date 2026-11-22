#!/usr/bin/env python3
# Bridge SIMULADO do ensaio local: espelha o src/a2a.ts do onion-bridge (POST -> a2a-verify.sh -> 403 no veto;
# senão grava o registro da fila {taskId, receivedAt, from, receiver, signal, verdict, envelope}). Só loopback.
# Uso: bridge_sim.py <verify.sh> <trust_repo> <jwks_dir> <trust_log> <pending_dir> <token_file> <port_file>
import datetime
import json
import os
import re
import subprocess
import sys
import uuid
from http.server import BaseHTTPRequestHandler, HTTPServer

VERIFY, REPO, JWKS, TLOG, PENDING, TOKEN_FILE, PORT_FILE = sys.argv[1:8]
TOKEN = open(TOKEN_FILE, encoding="utf-8").read().strip()
ID_RE = re.compile(r"[A-Za-z0-9][A-Za-z0-9._-]{0,127}\Z")


class H(BaseHTTPRequestHandler):
    def log_message(self, *a):
        pass

    def _send(self, code, obj):
        b = json.dumps(obj).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(b)))
        self.end_headers()
        self.wfile.write(b)

    def do_POST(self):
        if self.headers.get("Authorization", "") != f"Bearer {TOKEN}":
            return self._send(401, {"error": "unauthorized"})
        m = re.fullmatch(r"/a2a/([^/]+)", self.path)
        if not m or not ID_RE.fullmatch(m.group(1)):
            return self._send(404, {"error": "no-route"})
        receiver = m.group(1)
        raw = self.rfile.read(int(self.headers.get("Content-Length", "0") or 0))
        try:
            envelope = json.loads(raw)
        except Exception:
            return self._send(400, {"verified": False, "reason": "corpo-json-invalido"})
        env = dict(os.environ, A2A_JWKS_DIR=JWKS, A2A_TRUST_LOG=TLOG)
        res = subprocess.run(["bash", VERIFY, "--receiver", receiver, "--repo", REPO, "--envelope", "-"],
                             input=json.dumps(envelope), capture_output=True, text=True, timeout=15, env=env)
        try:
            verdict = json.loads(res.stdout.strip())
        except Exception:
            verdict = None
        if not verdict or verdict.get("verified") is not True:
            return self._send(403, {"a2a": {"state": "rejected"}, "verified": False,
                                    "reason": (verdict or {}).get("reason", "veto"),
                                    "layer_failed": (verdict or {}).get("layer_failed", "unknown")})
        os.makedirs(PENDING, exist_ok=True)
        task_id = str(uuid.uuid4())
        rec = {"taskId": task_id,
               "receivedAt": datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%S.%f")[:-3] + "Z",
               "from": envelope.get("signal", {}).get("from"), "receiver": receiver,
               "signal": envelope.get("signal"), "verdict": verdict, "envelope": envelope}
        with open(os.path.join(PENDING, f"{task_id}.json"), "w", encoding="utf-8") as f:
            json.dump(rec, f, indent=2)
        return self._send(200, {"kind": "task", "id": task_id, "status": {"state": "input_required"},
                                "verified": True, "gated": True, "committed": False})


srv = HTTPServer(("127.0.0.1", 0), H)
with open(PORT_FILE, "w") as f:
    f.write(str(srv.server_address[1]))
srv.serve_forever()
