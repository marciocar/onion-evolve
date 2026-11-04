#!/usr/bin/env python3
# Stub local da Messages API: devolve UMA chamada de ferramenta de shell e depois encerra o turno.
# Não há modelo: mede a decisão local do harness. Encerra sozinho pelo TTL e só escuta em 127.0.0.1.
# Uso: stub_messages.py <arquivo-da-porta> <log> <ttl-s>   Env: STUB_CMD (comando), STUB_TOOLRE (regex da ferramenta),
#      STUB_INPUT (JSON da entrada), STUB_MARKERS (csv de marcadores contados no corpo da requisição).
import http.server, json, os, re, sys, threading
PF, LOG, TTL = sys.argv[1], sys.argv[2], int(sys.argv[3])
CMD = os.environ.get("STUB_CMD", "true")
MK = [m for m in os.environ.get("STUB_MARKERS", "").split(",") if m]
threading.Timer(TTL, lambda: os._exit(0)).start()
def sse(w, ev, d):
    w.write(f"event: {ev}\ndata: {json.dumps(d)}\n\n".encode()); w.flush()
def pick(tools):
    rx = os.environ.get("STUB_TOOLRE")
    for t in tools:
        n = t.get("name", "")
        if (rx and re.search(rx, n)) or (not rx and (n == "Bash" or n.endswith("shell"))):
            return n
class H(http.server.BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"
    def log_message(self, *a): pass
    def do_GET(self):
        b = b'{"data":[]}'
        self.send_response(200); self.send_header("content-length", str(len(b))); self.end_headers(); self.wfile.write(b)
    def do_POST(self):
        raw = self.rfile.read(int(self.headers.get("content-length", 0)))
        try: j = json.loads(raw)
        except ValueError: j = {}
        results = [c for m in j.get("messages", []) if isinstance(m.get("content"), list) for c in m["content"]
                   if isinstance(c, dict) and c.get("type") == "tool_result"]
        tn = pick(j.get("tools", []))
        with open(LOG, "a") as f:
            f.write(json.dumps({"ntools": len(j.get("tools", [])), "tool": tn,
                                "marks": {m: raw.count(m.encode()) for m in MK},
                                "results": [str(r.get("content"))[:300] for r in results],
                                "err": [r.get("is_error") for r in results]}) + "\n")
        if "count_tokens" in self.path:
            b = b'{"input_tokens":10}'
            self.send_response(200); self.send_header("content-length", str(len(b))); self.end_headers(); self.wfile.write(b); return
        call = bool(tn) and not results
        self.send_response(200); self.send_header("content-type", "text/event-stream"); self.send_header("connection", "close")
        self.end_headers(); self.close_connection = True
        w = self.wfile
        sse(w, "message_start", {"type": "message_start", "message": {"id": "msg_1", "type": "message", "role": "assistant", "model": j.get("model", "m"), "content": [], "stop_reason": None, "stop_sequence": None, "usage": {"input_tokens": 1, "output_tokens": 1}}})
        if call:
            sse(w, "content_block_start", {"type": "content_block_start", "index": 0, "content_block": {"type": "tool_use", "id": "toolu_lab1", "name": tn, "input": {}}})
            sse(w, "content_block_delta", {"type": "content_block_delta", "index": 0, "delta": {"type": "input_json_delta", "partial_json": os.environ.get("STUB_INPUT") or json.dumps({"command": CMD, "description": "lab"})}})
        else:
            sse(w, "content_block_start", {"type": "content_block_start", "index": 0, "content_block": {"type": "text", "text": ""}})
            sse(w, "content_block_delta", {"type": "content_block_delta", "index": 0, "delta": {"type": "text_delta", "text": "fim"}})
        sse(w, "content_block_stop", {"type": "content_block_stop", "index": 0})
        sse(w, "message_delta", {"type": "message_delta", "delta": {"stop_reason": "tool_use" if call else "end_turn", "stop_sequence": None}, "usage": {"output_tokens": 1}})
        sse(w, "message_stop", {"type": "message_stop"})
srv = http.server.ThreadingHTTPServer(("127.0.0.1", 0), H)
open(PF, "w").write(str(srv.server_address[1]))
srv.serve_forever()
