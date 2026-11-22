#!/usr/bin/env python3
# Bridge SIMULADO do ensaio local. Espelha o onion-bridge na F3 (commit 5c1ba8d, 2026-10-22: src/a2a.ts,
# src/a2a-invites.ts e src/a2a-receivers.ts), não a cópia de 2026-08 (7e736ba), que é anterior à rota por
# receptor. O que espelha:
#   1. guard do convite por membro: o sha256 do bearer casa um convite do arquivo (A2A_INVITES_FILE do bridge,
#      gerado aqui pelo a2a-invite.sh real) que tem de estar de pé, nomear o receptor da rota e o signal.from;
#      senão 401 com o motivo (credencial-ausente, credencial-desconhecida, convite-revogado, convite-vencido,
#      convite-de-outro-receptor, convite-de-outro-membro, remetente-ausente);
#   2. gate do core (a2a-verify.sh) com o receptor da rota; veredito só vale CANÔNICO, um objeto, e verified:true
#      só com exit 0 (readGateVerdict); senão 403;
#   3. eco obrigatório do receptor no veredito (verdictMatchesReceiver); senão 403;
#   4. registro da fila {taskId, receivedAt, from, receiver, signal, verdict, envelope}.
# O que NÃO espelha (declarado): judgeReceiver (a camada 0b do gate cobre o mesmo julgamento), a taxa por membro,
# o teto de corpo do HTTP, o trust-log no data/ do bridge (aqui vai a um arquivo do ensaio) e o processo como
# outra conta do sistema. Só loopback.
# Uso: bridge_sim.py <verify.sh> <trust_repo> <jwks_dir> <trust_log> <pending_dir> <invites.json> <port_file>
import datetime
import hashlib
import hmac
import json
import os
import re
import subprocess
import sys
import uuid
from http.server import BaseHTTPRequestHandler, HTTPServer

VERIFY, REPO, JWKS, TLOG, PENDING, INVITES, PORT_FILE = sys.argv[1:8]
ID_RE = re.compile(r"[A-Za-z0-9][A-Za-z0-9._-]{0,127}\Z")


def guard(bearer, sender, receiver):
    if not bearer:
        return "credencial-ausente"
    h = hashlib.sha256(bearer.encode()).hexdigest()
    try:
        invites = json.load(open(INVITES, encoding="utf-8")).get("invites", [])
    except Exception:
        return "convites-indisponiveis"
    matches = [i for i in invites if hmac.compare_digest(h, str(i.get("token_sha256", "")))]
    if not matches:
        return "credencial-desconhecida"
    if not isinstance(sender, str) or not sender:
        return "remetente-ausente"
    now = datetime.datetime.now(datetime.timezone.utc)
    for inv in matches:
        if inv.get("revoked") is not False:
            return "convite-revogado"
        try:
            exp = datetime.datetime.fromisoformat(str(inv.get("expires_at")).replace("Z", "+00:00"))
        except Exception:
            return "convite-invalido"
        if exp <= now:
            return "convite-vencido"
        if inv.get("receiver") != receiver:
            return "convite-de-outro-receptor"
        if inv.get("member") != sender:
            return "convite-de-outro-membro"
    return None


def read_gate_verdict(code, out):
    text = out.strip()
    try:
        parsed = json.loads(text)
    except Exception:
        return None, "veredito-ilegivel"
    if not isinstance(parsed, dict):
        return None, "veredito-ilegivel"
    if json.dumps(parsed, separators=(",", ":"), ensure_ascii=False) != text:
        return None, "veredito-ambiguo"
    if parsed.get("verified") is True and code != 0:
        return None, "veredito-incoerente"
    if parsed.get("verified") is not True:
        return parsed, "veto"
    return parsed, None


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
        m = re.fullmatch(r"/a2a/([^/]+)", self.path)
        if not m or not ID_RE.fullmatch(m.group(1)):
            return self._send(400, {"error": "rota-invalida"})
        receiver = m.group(1)
        raw = self.rfile.read(int(self.headers.get("Content-Length", "0") or 0))
        try:
            envelope = json.loads(raw)
        except Exception:
            envelope = None
        auth = self.headers.get("Authorization", "")
        bearer = auth[7:].strip() if auth.startswith("Bearer ") else ""
        sender = (envelope or {}).get("signal", {}).get("from") if isinstance(envelope, dict) else None
        why = guard(bearer, sender, receiver)
        if why:
            return self._send(401, {"error": "não autorizado", "reason": why})
        if envelope is None:
            return self._send(400, {"verified": False, "reason": "corpo-json-invalido"})
        env = dict(os.environ, A2A_JWKS_DIR=JWKS, A2A_TRUST_LOG=TLOG)
        res = subprocess.run(["bash", VERIFY, "--receiver", receiver, "--repo", REPO, "--envelope", "-"],
                             input=json.dumps(envelope), capture_output=True, text=True, timeout=15, env=env)
        verdict, why = read_gate_verdict(res.returncode, res.stdout)
        if why:
            v = verdict or {}
            return self._send(403, {"a2a": {"state": "rejected"}, "verified": False,
                                    "reason": v.get("reason") if isinstance(v.get("reason"), str) else why,
                                    "layer_failed": v.get("layer_failed") if isinstance(v.get("layer_failed"), str) else "unknown"})
        if verdict.get("receiver") != receiver:
            return self._send(403, {"a2a": {"state": "rejected"}, "verified": False,
                                    "reason": "veredito-de-outro-receptor", "layer_failed": "receiver"})
        os.makedirs(PENDING, exist_ok=True)
        task_id = str(uuid.uuid4())
        rec = {"taskId": task_id,
               "receivedAt": datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%S.%f")[:-3] + "Z",
               "from": sender, "receiver": receiver,
               "signal": envelope.get("signal"), "verdict": verdict, "envelope": envelope}
        with open(os.path.join(PENDING, f"{task_id}.json"), "w", encoding="utf-8") as f:
            json.dump(rec, f, indent=2)
        return self._send(200, {"kind": "task", "id": task_id, "status": {"state": "input_required"},
                                "verified": True, "gated": True, "committed": False})


srv = HTTPServer(("127.0.0.1", 0), H)
with open(PORT_FILE, "w") as f:
    f.write(str(srv.server_address[1]))
srv.serve_forever()
