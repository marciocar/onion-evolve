#!/usr/bin/env python3
"""Stub da Messages API com roteiro. PLAN_FILE: lista JSON de {name,input}. Derivado de stub2.py da curadoria.
Diferencas: id unico por chamada e redacao do valor do canario no log."""
import http.server, json, os, re, sys
PORT, LOG = int(sys.argv[1]), sys.argv[2]; PLAN = json.load(open(os.environ["PLAN_FILE"])); I = {"n": 0}
def sse(w, ev, d): w.write(f"event: {ev}\ndata: {json.dumps(d)}\n\n".encode()); w.flush()
def red(s): return re.sub(r"CANARIO=\S+", "CANARIO=<redigido>", s)
class H(http.server.BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"
    def log_message(self, *a): pass
    def _j(self, b):
        self.send_response(200); self.send_header("content-length", str(len(b))); self.end_headers(); self.wfile.write(b)
    def do_GET(self): self._j(b'{"data":[]}')
    def do_POST(self):
        raw = self.rfile.read(int(self.headers.get("content-length", 0))); j = {}
        try: j = json.loads(raw)
        except ValueError: pass
        if "count_tokens" in self.path: return self._j(b'{"input_tokens":10}')
        tools = [t.get("name") for t in j.get("tools", [])]
        res = [c for m in j.get("messages", []) if isinstance(m.get("content"), list) for c in m["content"] if c.get("type") == "tool_result"]
        call = bool(tools) and I["n"] < len(PLAN) and "Bash" in tools
        with open(LOG, "a") as f:
            f.write(json.dumps({"path": self.path, "model": j.get("model"), "tools": len(tools), "n": I["n"], "ultimo": red(str(res[-1].get("content")))[:200] if res else None}) + "\n")
        self.send_response(200); self.send_header("content-type", "text/event-stream"); self.send_header("connection", "close"); self.end_headers(); self.close_connection = True
        w = self.wfile
        sse(w, "message_start", {"type": "message_start", "message": {"id": f"msg_{I['n']}", "type": "message", "role": "assistant", "model": j.get("model", "m"), "content": [], "stop_reason": None, "stop_sequence": None, "usage": {"input_tokens": 1, "output_tokens": 1}}})
        if call:
            p = PLAN[I["n"]]; I["n"] += 1
            sse(w, "content_block_start", {"type": "content_block_start", "index": 0, "content_block": {"type": "tool_use", "id": f"toolu_lab{I['n']}", "name": p["name"], "input": {}}})
            sse(w, "content_block_delta", {"type": "content_block_delta", "index": 0, "delta": {"type": "input_json_delta", "partial_json": json.dumps(p["input"])}})
        else:
            sse(w, "content_block_start", {"type": "content_block_start", "index": 0, "content_block": {"type": "text", "text": ""}})
            sse(w, "content_block_delta", {"type": "content_block_delta", "index": 0, "delta": {"type": "text_delta", "text": "fim"}})
        sse(w, "content_block_stop", {"type": "content_block_stop", "index": 0})
        sse(w, "message_delta", {"type": "message_delta", "delta": {"stop_reason": "tool_use" if call else "end_turn", "stop_sequence": None}, "usage": {"output_tokens": 1}})
        sse(w, "message_stop", {"type": "message_stop"})
http.server.ThreadingHTTPServer(("127.0.0.1", PORT), H).serve_forever()
