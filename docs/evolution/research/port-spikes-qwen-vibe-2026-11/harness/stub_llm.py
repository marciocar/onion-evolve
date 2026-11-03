#!/usr/bin/env python3
"""Servidor OpenAI-compatível mínimo (só stdlib) para os spikes de veto de hook.

Não é modelo: é um roteiro, roteado pela FORMA da requisição (revisão adversarial):

  com `tools` e SEM mensagem role=tool  -> a chamada fixa do cenário
  com resultado de ferramenta           -> texto final "DONE"
  SEM `tools` (auxiliar: memória, título)-> texto curto "OK"

Chamada fixa por cenário (letras do pré-registro; a|b ficam como alias de c|w):
  c  (alias a) -> ferramenta de shell com `git push origin main`
  w  (alias b) -> ferramenta de shell com `echo x > MARKER.txt`
  w2           -> ferramenta de escrita criando MARKER.txt com conteúdo `x` (sem shell)
  ATENÇÃO: na versão anterior "c" era a escrita sem shell; agora "c" é o push.

O nome da ferramenta e o esquema vêm da lista `tools` da própria requisição (Qwen:
run_shell_command / write_file; Vibe: bash / write_file). A chamada montada é VALIDADA
contra o `parameters` declarado; se não houver ferramenta que sirva ou os argumentos não
validarem, a requisição inteira é gravada com a marca STUB-INVÁLIDO e a resposta é texto
(sem chamada), o que deixa a célula INCONCLUSIVA em vez de medir outra coisa.

SSE no formato do llama-server --jinja: delta inicial com role, delta com `tool_calls`
(nome com arguments "", depois os argumentos), chunk com finish_reason "tool_calls",
chunk de usage se pedido, e `data: [DONE]`.

Cada requisição de chat é gravada inteira em <requests-dir>/NNN-<kind>.json, além da
linha no log JSONL.

Cada pedido grava também o sha256 dos bytes recebidos (request_sha256).

Uso: stub_llm.py --port N --scenario c|w|w2 --log /abs/stub.log --requests-dir /abs/dir
                 [--workdir /abs/work]   (o cenário também pode vir de STUB_SCENARIO)
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import sys
import threading
import time
import uuid
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

MODEL_ID = "spike-stub"
INVALID_MARK = "STUB-INVÁLIDO"

SHELL_COMMANDS = {
    "c": "git push origin main",
    "w": "echo x > MARKER.txt",
}
SCENARIO_ALIASES = {"a": "c", "b": "w", "c": "c", "w": "w", "w2": "w2"}

# Preferência de nome; se nenhum casar, cai na heurística por esquema.
SHELL_TOOL_NAMES = ("run_shell_command", "bash", "shell", "Bash", "execute_command", "run_command")
WRITE_TOOL_NAMES = ("write_file", "Write", "write", "create_file")


class StubState:
    def __init__(self, scenario: str, log_path: str, requests_dir: str, workdir: str | None) -> None:
        self.scenario = scenario
        self.log_path = log_path
        self.requests_dir = requests_dir
        self.workdir = workdir
        self.tool_calls_emitted = 0
        self.seq = 0
        self.lock = threading.Lock()

    def next_seq(self) -> int:
        with self.lock:
            self.seq += 1
            return self.seq

    def log(self, record: dict, seq: int | None = None) -> None:
        seq = seq if seq is not None else self.next_seq()
        record = {"seq": seq, "ts": time.time(), **record}
        with self.lock:
            with open(self.log_path, "a", encoding="utf-8") as fh:
                fh.write(json.dumps(record, ensure_ascii=False) + "\n")

    def save_request(self, seq: int, kind: str, body: dict, decision: dict, sha: str) -> None:
        path = os.path.join(self.requests_dir, f"{seq:03d}-{kind}.json")
        with open(path, "w", encoding="utf-8") as fh:
            json.dump({"seq": seq, "ts": time.time(), "request_sha256": sha,
                       "decision": decision, "request": body},
                      fh, ensure_ascii=False, indent=2)


def _tool_fn(tool: dict) -> dict:
    # Formato OpenAI: {"type":"function","function":{name, parameters}}; tolera o plano.
    return tool.get("function") if isinstance(tool.get("function"), dict) else tool


def _props(fn: dict) -> dict:
    params = fn.get("parameters") or {}
    return params.get("properties") or {}


def _find_tool(tools: list, names: tuple[str, ...], needed_any: tuple[tuple[str, ...], ...]) -> dict | None:
    fns = [_tool_fn(t) for t in tools if isinstance(t, dict)]
    by_name = {f.get("name"): f for f in fns}
    for n in names:
        if n in by_name:
            return by_name[n]
    for f in fns:
        props = _props(f)
        if any(all(k in props for k in group) for group in needed_any):
            return f
    return None


def _default_for(schema: dict):
    # Preenche obrigatórios desconhecidos de forma neutra, pelo tipo declarado.
    t = schema.get("type")
    if isinstance(t, list):
        t = next((x for x in t if x != "null"), "string")
    if schema.get("enum"):
        return schema["enum"][0]
    return {"string": "spike", "boolean": False, "integer": 30, "number": 30,
            "array": [], "object": {}}.get(t, "spike")


def build_arguments(fn: dict, scenario: str, workdir: str | None) -> dict:
    props = _props(fn)
    required = (fn.get("parameters") or {}).get("required") or []
    args: dict = {}
    if scenario in SHELL_COMMANDS:
        args["command"] = SHELL_COMMANDS[scenario]
        if "description" in props:
            args["description"] = "onion spike"
        if "is_background" in props:
            args["is_background"] = False
    else:
        target = os.path.join(workdir, "MARKER.txt") if workdir else "MARKER.txt"
        path_key = next((k for k in ("file_path", "path", "filePath", "filename") if k in props), "file_path")
        content_key = next((k for k in ("content", "contents", "text") if k in props), "content")
        args[path_key] = target
        args[content_key] = "x"
    for key in required:
        if key not in args:
            args[key] = _default_for(props.get(key) or {})
    return args


_JSON_TYPES = {
    "string": lambda v: isinstance(v, str),
    "boolean": lambda v: isinstance(v, bool),
    "integer": lambda v: isinstance(v, int) and not isinstance(v, bool),
    "number": lambda v: isinstance(v, (int, float)) and not isinstance(v, bool),
    "array": lambda v: isinstance(v, list),
    "object": lambda v: isinstance(v, dict),
    "null": lambda v: v is None,
}


def validate_arguments(args: dict, params: dict) -> list[str]:
    """Validação mínima (subconjunto de JSON Schema) do objeto de argumentos de topo:
    required, type, enum, additionalProperties=false. Devolve a lista de erros."""
    errors: list[str] = []
    if not isinstance(params, dict) or params.get("type", "object") != "object":
        return errors if isinstance(params, dict) else ["parameters is not an object schema"]
    props = params.get("properties") or {}
    for key in params.get("required") or []:
        if key not in args:
            errors.append(f"missing required '{key}'")
    if params.get("additionalProperties") is False:
        for key in args:
            if key not in props:
                errors.append(f"unexpected property '{key}'")
    for key, value in args.items():
        schema = props.get(key)
        if not isinstance(schema, dict):
            continue
        t = schema.get("type")
        types = t if isinstance(t, list) else ([t] if t else [])
        if types and not any(_JSON_TYPES.get(x, lambda _v: True)(value) for x in types):
            errors.append(f"'{key}' is not of type {types}")
        if schema.get("enum") and value not in schema["enum"]:
            errors.append(f"'{key}' not in enum")
    return errors


def has_tool_result(messages: list) -> bool:
    return any(isinstance(m, dict) and m.get("role") == "tool" for m in messages or [])


def decide(state: StubState, body: dict) -> dict:
    """Roteia pela forma. Devolve {"kind": tool_call|final|aux|invalid, ...}."""
    tools = body.get("tools") or []
    messages = body.get("messages") or []
    if not tools:
        return {"kind": "aux", "text": "OK", "why": "no tools in request (auxiliary call)"}
    if has_tool_result(messages):
        return {"kind": "final", "text": "DONE", "why": "request carries a tool result"}
    offered = [_tool_fn(t).get("name") for t in tools if isinstance(t, dict)]
    if state.scenario in SHELL_COMMANDS:
        fn = _find_tool(tools, SHELL_TOOL_NAMES, (("command",),))
    else:
        fn = _find_tool(tools, WRITE_TOOL_NAMES, (("file_path", "content"), ("path", "content")))
    if fn is None:
        return {"kind": "invalid", "mark": INVALID_MARK, "text": INVALID_MARK,
                "why": "no tool for the scenario in request.tools", "offered": offered}
    args = build_arguments(fn, state.scenario, state.workdir)
    errors = validate_arguments(args, fn.get("parameters") or {})
    if fn.get("name") not in offered:
        errors.append(f"tool name {fn.get('name')!r} not in request.tools")
    if errors:
        return {"kind": "invalid", "mark": INVALID_MARK, "text": INVALID_MARK,
                "why": "fixed call does not validate against request.tools",
                "tool_name": fn.get("name"), "arguments": args, "errors": errors, "offered": offered}
    state.tool_calls_emitted += 1
    return {
        "kind": "tool_call",
        "tool_name": fn.get("name"),
        "arguments": args,
        "call_id": "call_" + uuid.uuid4().hex[:16],
        "emitted_count": state.tool_calls_emitted,
        "why": "tools present and no tool result",
        "offered": offered,
    }


def completion_object(decision: dict, model: str) -> dict:
    if decision["kind"] == "tool_call":
        message = {
            "role": "assistant",
            "content": None,
            "tool_calls": [{
                "id": decision["call_id"],
                "type": "function",
                "function": {"name": decision["tool_name"],
                             "arguments": json.dumps(decision["arguments"])},
            }],
        }
        finish = "tool_calls"
    else:
        message = {"role": "assistant", "content": decision["text"]}
        finish = "stop"
    return {
        "id": "chatcmpl-" + uuid.uuid4().hex[:12],
        "object": "chat.completion",
        "created": int(time.time()),
        "model": model,
        "choices": [{"index": 0, "message": message, "finish_reason": finish}],
        "usage": {"prompt_tokens": 10, "completion_tokens": 5, "total_tokens": 15},
    }


def stream_chunks(decision: dict, model: str, include_usage: bool) -> list[dict]:
    """Chunks no formato do llama-server --jinja."""
    cid = "chatcmpl-" + uuid.uuid4().hex[:12]
    created = int(time.time())

    def chunk(delta: dict, finish=None) -> dict:
        return {"id": cid, "object": "chat.completion.chunk", "created": created, "model": model,
                "choices": [{"index": 0, "delta": delta, "finish_reason": finish}]}

    out = [chunk({"role": "assistant", "content": None})]
    if decision["kind"] == "tool_call":
        out.append(chunk({"tool_calls": [{
            "index": 0, "id": decision["call_id"], "type": "function",
            "function": {"name": decision["tool_name"], "arguments": ""},
        }]}))
        out.append(chunk({"tool_calls": [{
            "index": 0, "function": {"arguments": json.dumps(decision["arguments"])},
        }]}))
        out.append(chunk({}, "tool_calls"))
    else:
        out.append(chunk({"content": decision["text"]}))
        out.append(chunk({}, "stop"))
    if include_usage:
        out.append({"id": cid, "object": "chat.completion.chunk", "created": created, "model": model,
                    "choices": [], "usage": {"prompt_tokens": 10, "completion_tokens": 5, "total_tokens": 15}})
    return out


def make_handler(state: StubState):
    class Handler(BaseHTTPRequestHandler):
        protocol_version = "HTTP/1.1"

        def log_message(self, fmt, *args):  # silencia o log padrão no stderr
            pass

        def _send_json(self, code: int, obj: dict) -> None:
            data = json.dumps(obj).encode()
            self.send_response(code)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(data)))
            self.end_headers()
            self.wfile.write(data)

        def _read_body(self) -> bytes:
            if self.headers.get("Transfer-Encoding", "").lower() == "chunked":
                buf = b""
                while True:
                    size = int(self.rfile.readline().strip() or b"0", 16)
                    if size == 0:
                        self.rfile.readline()
                        return buf
                    buf += self.rfile.read(size)
                    self.rfile.readline()
            n = int(self.headers.get("Content-Length") or 0)
            return self.rfile.read(n) if n else b""

        def do_GET(self):
            path = self.path.split("?")[0].rstrip("/")
            if path in ("/health", "/v1/health"):
                obj = {"status": "ok"}
            elif path in ("/v1/models", "/models"):
                obj = {"object": "list", "data": [{"id": MODEL_ID, "object": "model",
                                                   "created": 0, "owned_by": "onion-spike"}]}
            else:
                state.log({"method": "GET", "path": self.path, "status": 404})
                return self._send_json(404, {"error": {"message": "not found"}})
            state.log({"method": "GET", "path": self.path, "status": 200})
            self._send_json(200, obj)

        def do_POST(self):
            path = self.path.split("?")[0].rstrip("/")
            raw = self._read_body()
            try:
                body = json.loads(raw or b"{}")
            except json.JSONDecodeError:
                state.log({"method": "POST", "path": self.path, "status": 400, "raw": raw.decode("utf-8", "replace")})
                return self._send_json(400, {"error": {"message": "bad json"}})
            if path not in ("/v1/chat/completions", "/chat/completions"):
                state.log({"method": "POST", "path": self.path, "status": 404, "request": body})
                return self._send_json(404, {"error": {"message": "not found"}})
            seq = state.next_seq()
            sha = hashlib.sha256(raw).hexdigest()
            decision = decide(state, body)
            state.save_request(seq, decision["kind"], body, decision, sha)
            model = body.get("model") or MODEL_ID
            stream = bool(body.get("stream"))
            rec = {"method": "POST", "path": self.path, "status": 200, "stream": stream,
                   "request_sha256": sha, "decision": decision, "request": body}
            if decision["kind"] == "invalid":
                rec["mark"] = INVALID_MARK
            if not stream:
                resp = completion_object(decision, model)
                rec["response"] = resp
                state.log(rec, seq)
                return self._send_json(200, resp)
            include_usage = bool((body.get("stream_options") or {}).get("include_usage"))
            chunks = stream_chunks(decision, model, include_usage)
            rec["response_chunks"] = chunks
            state.log(rec, seq)
            self.send_response(200)
            self.send_header("Content-Type", "text/event-stream")
            self.send_header("Cache-Control", "no-cache")
            self.send_header("Connection", "close")
            self.end_headers()
            for c in chunks:
                self.wfile.write(b"data: " + json.dumps(c).encode() + b"\n\n")
                self.wfile.flush()
            self.wfile.write(b"data: [DONE]\n\n")
            self.wfile.flush()
            self.close_connection = True

    return Handler


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--port", type=int, required=True)
    ap.add_argument("--scenario", default=os.environ.get("STUB_SCENARIO"), choices=sorted(SCENARIO_ALIASES))
    ap.add_argument("--log", required=True)
    ap.add_argument("--requests-dir", required=True)
    ap.add_argument("--workdir", default=None, help="absolute workdir, used for the write-tool path")
    a = ap.parse_args()
    if not a.scenario:
        ap.error("scenario required (--scenario or STUB_SCENARIO)")
    os.makedirs(a.requests_dir, exist_ok=True)
    state = StubState(SCENARIO_ALIASES[a.scenario], a.log, a.requests_dir, a.workdir)
    state.log({"event": "start", "port": a.port, "scenario": a.scenario, "workdir": a.workdir, "pid": os.getpid()})
    srv = ThreadingHTTPServer(("127.0.0.1", a.port), make_handler(state))
    try:
        srv.serve_forever()
    except KeyboardInterrupt:
        pass
    return 0


if __name__ == "__main__":
    sys.exit(main())
