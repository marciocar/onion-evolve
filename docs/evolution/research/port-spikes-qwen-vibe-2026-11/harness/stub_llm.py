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

Rodada 2: cenários mcp, sub, ts, proc, tc e tcd, com roteiro em passos (decide_r2).
`stub_llm.py --selftest` confere o roteiro sobre pedidos sintéticos, sem subir servidor.

Uso: stub_llm.py --port N --scenario c|w|w2|mcp|sub|ts|proc|tc|tcd --log /abs/stub.log --requests-dir /abs/dir
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
SCENARIO_ALIASES = {"a": "c", "b": "w", "c": "c", "w": "w", "w2": "w2",
                    # rodada 2 (PRE-REGISTRO-R2.md): roteiro em passos, ver decide_r2
                    "mcp": "mcp", "sub": "sub", "ts": "ts", "proc": "proc", "tc": "tc", "tcd": "tcd", "pc": "pc"}

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
    if state.scenario in R2_SCENARIOS:
        return decide_r2(state, body)
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


# ---------------------------------------------------------------- rodada 2 (PRE-REGISTRO-R2.md §4)
#
# Os cenários da rodada 1 (c, w, w2) seguem pelo caminho acima, byte a byte o mesmo. Os da
# rodada 2 têm ROTEIRO em passos. O passo seguinte sai do CONTEÚDO do pedido, nunca da ordem
# dos pedidos: conta as chamadas de ferramenta do papel assistant já presentes no histórico do
# próprio pedido; se há menos que o roteiro, emite o próximo passo; senão, "DONE".
# O pedido de um SUBAGENTE se reconhece pelo token SUBTASK_TOKEN numa mensagem do papel user
# (é a tarefa que o roteiro de fora entregou a ele); ele segue o roteiro de DENTRO.
#
#   mcp   chama a ferramenta MCP *write_marker (direta, se oferecida; senão tool_search
#         "select:<nome>" e tool_call, quando o cliente a esconde como deferida)
#   sub   fora: Qwen, tool_search "select:agent" + tool_call agent (ou agent direto);
#         Vibe, run_typescript com tools.agents.spawn + wait. Dentro: shell com o push
#   ts    Vibe: run_typescript que chama tools.file_system.bash com o push
#   proc  Vibe: run_typescript que chama tools.process.start com o push e espera o fim
#   tc    Qwen: tool_call {"name": "run_shell_command", ...} com o push (o shell pelo invocador)
#   tcd   Qwen: tool_search "select:monitor" + tool_call monitor com o push (shell por uma
#         ferramenta DEFERIDA, que só o tool_call alcança)
#   pc    (Emenda R2-1, lacuna d) read_file do README.txt e depois o shell com o push: o passo de
#         topo inofensivo prova a carga do hook, e o passo-alvo pode faltar na oferta (REMOVIDA)
# Emenda R2-1 (curadoria 2): no Vibe, mcp/sub/ts/proc começam por um read_file de topo (o hook
# nunca vê o run_typescript; sem esse passo, "hook cego" e "hook não carregou" são indistinguíveis).
# Cada decisão leva "step", "steps", "target" (True no passo que carrega o alvo) e "role"
# (outer|inner).

R2_SCENARIOS = {"mcp", "sub", "ts", "proc", "tc", "tcd", "pc"}
SUBTASK_TOKEN = "ONION-SPIKE-SUBTASK"
# A tarefa NÃO leva o comando do alvo: a chamada de delegação (agent / agents.spawn) não pode
# casar com o target_in, senão o hook deny_target vetaria a própria delegação. O comando sai do
# roteiro de DENTRO (o stub), não do texto.
SUBTASK_TEXT = f"{SUBTASK_TOKEN}: run the spike shell step in the current directory and report its output."
MCP_TOOL_SUFFIX = "write_marker"
PUSH = SHELL_COMMANDS["c"]

# Código do run_typescript (Vibe). As assinaturas citadas no PRE-REGISTRO-R2.md §3.
TS_BASH = ("async function main() {\n"
           f"  return await tools.file_system.bash({{ command: '{PUSH}' }});\n"
           "}")
# process.start: command/cwd/env (_process_actions.py:281-305); o esquema do process.output é
# DESCONHECIDO, então o programa só dorme (tools.self.sleep, do prompt de sistema) e devolve o start.
TS_PROC = ("async function main() {\n"
           f"  const p = await tools.process.start({{ command: '{PUSH}' }});\n"
           "  await tools.self.sleep({ seconds: 5 });\n"
           "  return p;\n"
           "}")
# agents.spawn: name, message, config_name (_projection.py:1918-1927); o spawn não espera: o 2º
# passo do roteiro é a ferramenta de topo `wait` (timeout_ms), oferecida no pedido.
TS_SPAWN = ("async function main() {\n"
            f"  return await tools.agents.spawn({{ name: 'spike', message: '{SUBTASK_TEXT}' }});\n"
            "}")
# MCP no Vibe: grupo mcp_<servidor> (_mcp_naming.py:102), exposição programática
# (_host.py:5108): chamado por dentro do run_typescript.
TS_MCP = ("async function main() {{\n"
          "  return await tools.mcp_onionspike.write_marker({{ path: '{marker}', content: 'x' }});\n"
          "}}")


def _assistant_calls(messages: list) -> list[str]:
    out = []
    for m in messages or []:
        if isinstance(m, dict) and m.get("role") == "assistant":
            for tc in m.get("tool_calls") or []:
                fn = (tc or {}).get("function") or {}
                out.append(fn.get("name"))
    return out


def _user_text(messages: list) -> str:
    parts = []
    for m in messages or []:
        if isinstance(m, dict) and m.get("role") == "user":
            c = m.get("content")
            parts.append(c if isinstance(c, str) else json.dumps(c, ensure_ascii=False))
    return "\n".join(parts)


def _all_text(messages: list) -> str:
    return "\n".join(m.get("content") if isinstance(m.get("content"), str) else json.dumps(m.get("content"), ensure_ascii=False)
                     for m in messages or [] if isinstance(m, dict))


def _declared_schema(messages: list, name: str) -> dict | None:
    """O esquema de `name` devolvido pelo tool_search, lido do resultado de ferramenta: o
    primeiro objeto JSON com "name" == name e "parameters" dentro de uma mensagem role=tool."""
    dec = json.JSONDecoder()
    for m in messages or []:
        if not (isinstance(m, dict) and m.get("role") == "tool"):
            continue
        c = m.get("content")
        text = c if isinstance(c, str) else json.dumps(c, ensure_ascii=False)
        i = text.find("{")
        while i != -1:
            try:
                obj, end = dec.raw_decode(text, i)
            except json.JSONDecodeError:
                i = text.find("{", i + 1)
                continue
            if isinstance(obj, dict) and obj.get("name") == name and isinstance(obj.get("parameters"), dict):
                return obj
            i = text.find("{", end)
    return None


def _fill(params: dict, preset: dict) -> dict:
    """Argumentos para um esquema: preset por chave (as chaves de texto livre recebem o texto
    da tarefa), obrigatórios restantes pelo tipo (_default_for)."""
    props = (params or {}).get("properties") or {}
    required = (params or {}).get("required") or []
    args = {k: v for k, v in preset.items() if k in props}
    for key in required:
        if key not in args:
            args[key] = _default_for(props.get(key) or {})
    return args


def _subagent_args(params: dict) -> dict:
    props = (params or {}).get("properties") or {}
    preset = {}
    for k in ("prompt", "task", "instruction", "instructions", "message", "query"):
        if k in props:
            preset[k] = SUBTASK_TEXT
    if "description" in props:
        preset["description"] = "onion spike subtask"
    for k in ("subagent_type", "agent_type", "type"):
        if k in props:
            enum = (props[k] or {}).get("enum")
            preset[k] = "general-purpose" if not enum or "general-purpose" in enum else enum[0]
    for k in ("run_in_background", "background"):
        if k in props:
            preset[k] = False
    return _fill(params, preset)


def _step(name, args, *, target, role) -> dict:
    return {"name": name, "args": args, "target": target, "role": role}


def r2_script(state: StubState, body: dict) -> tuple[list[dict] | None, str, str | None]:
    """Devolve (passos, role, motivo-se-inválido)."""
    tools = body.get("tools") or []
    messages = body.get("messages") or []
    offered = {_tool_fn(t).get("name"): _tool_fn(t) for t in tools if isinstance(t, dict)}
    sc, wd = state.scenario, state.workdir
    marker = os.path.join(wd, "MARKER.txt") if wd else "MARKER.txt"
    inner = SUBTASK_TOKEN in _user_text(messages)

    def shell_push_step(role):
        fn = _find_tool(tools, SHELL_TOOL_NAMES, (("command",),))
        if fn is None:
            return None
        return _step(fn["name"], build_arguments(fn, "c", wd), target=True, role=role)

    readme = os.path.join(wd, "README.txt") if wd else "README.txt"

    def read_step():
        fn = offered.get("read_file")
        if fn is None:
            return None
        props = (fn.get("parameters") or {}).get("properties") or {}
        key = next((k for k in ("file_path", "path") if k in props), "path")
        return _step("read_file", _fill(fn.get("parameters") or {}, {key: readme}), target=False, role="outer")

    if sc == "pc":
        r = read_step()
        if r is None:
            return None, "outer", "read_file not offered"
        s2 = shell_push_step("outer")
        if s2 is None:
            # o passo-alvo falta na oferta: emite o read_file e só então marca o motivo
            if len(_assistant_calls(messages)) >= 1:
                return None, "outer", "no tool for the scenario in request.tools"
            return [r, _step("__missing__", {}, target=True, role="outer")], "outer", None
        return [r, s2], "outer", None

    if sc == "tc":
        # Emenda R2-2 (kg-ssot F2): o read_file de topo prova a carga e o yolo (permission_mode no
        # stdin do hook) antes do tool_call
        r = read_step()
        if r is None:
            return None, "outer", "read_file not offered (load-proof step)"
        rest, role, bad = _r2_script_core(state, body, offered, sc, wd, marker, inner, shell_push_step)
        return (None, role, bad) if rest is None else ([r] + rest, role, None)

    if sc in ("mcp", "sub", "ts", "proc") and "run_typescript" in offered and not inner:
        r = read_step()
        if r is None:
            return None, "outer", "read_file not offered (Vibe load-proof step)"
        rest, role, bad = _r2_script_core(state, body, offered, sc, wd, marker, inner, shell_push_step)
        return (None, role, bad) if rest is None else ([r] + rest, role, None)

    return _r2_script_core(state, body, offered, sc, wd, marker, inner, shell_push_step)


def _r2_script_core(state, body, offered, sc, wd, marker, inner, shell_push_step):
    tools = body.get("tools") or []
    messages = body.get("messages") or []
    if sc == "sub" and inner:
        s = shell_push_step("inner")
        return ([s], "inner", None) if s else (None, "inner", "subagent request without a shell tool")

    if sc == "mcp":
        direct = next((n for n in offered if n and n.endswith(MCP_TOOL_SUFFIX)), None)
        args = {"path": marker, "content": "x"}
        if direct:
            return [_step(direct, _fill(offered[direct].get("parameters") or {}, args), target=True, role="outer")], "outer", None
        if "run_typescript" in offered:
            # Vibe: a ferramenta MCP é programática, só alcançável por dentro do run_typescript
            return [_step("run_typescript", {"code": TS_MCP.format(marker=marker)}, target=True, role="outer")], "outer", None
        if "tool_call" in offered and "tool_search" in offered:
            import re as _re
            # o nome qualificado leva o servidor (o prompt da célula cita só "write_marker")
            m = _re.search(r"[A-Za-z0-9_.:-]*onionspike[A-Za-z0-9_.:-]*" + MCP_TOOL_SUFFIX + r"\b", _all_text(messages))
            if not m:
                return None, "outer", "MCP tool neither offered nor named in the deferred list"
            name = m.group(0)
            return [_step("tool_search", {"query": f"select:{name}"}, target=False, role="outer"),
                    _step("tool_call", {"name": name, "arguments": args}, target=True, role="outer")], "outer", None
        return None, "outer", "MCP tool not offered"

    if sc == "sub":
        if "agent" in offered:
            return [_step("agent", _subagent_args(offered["agent"].get("parameters") or {}), target=False, role="outer")], "outer", None
        if "tool_call" in offered and "tool_search" in offered:
            decl = _declared_schema(messages, "agent")
            second = (_step("tool_call", {"name": "agent", "arguments": _subagent_args(decl["parameters"])},
                            target=False, role="outer") if decl else None)
            steps = [_step("tool_search", {"query": "select:agent"}, target=False, role="outer")]
            if len(_assistant_calls(messages)) >= 1 and second is None:
                return None, "outer", "tool_search result carries no 'agent' declaration"
            return steps + ([second] if second else [_step("tool_call", {}, target=False, role="outer")]), "outer", None
        if "run_typescript" in offered:
            steps = [_step("run_typescript", {"code": TS_SPAWN}, target=False, role="outer")]
            if "wait" in offered:
                steps.append(_step("wait", _fill(offered["wait"].get("parameters") or {}, {"timeout_ms": 60000}),
                                   target=False, role="outer"))
            return steps, "outer", None
        return None, "outer", "no subagent path offered"

    if sc in ("ts", "proc"):
        if "run_typescript" not in offered:
            return None, "outer", "run_typescript not offered"
        return [_step("run_typescript", {"code": TS_BASH if sc == "ts" else TS_PROC}, target=True, role="outer")], "outer", None

    if sc == "tc":
        if "tool_call" not in offered:
            return None, "outer", "tool_call not offered"
        return [_step("tool_call", {"name": "run_shell_command",
                                    "arguments": {"command": PUSH, "description": "onion spike", "is_background": False}},
                      target=True, role="outer")], "outer", None

    if sc == "tcd":
        if "tool_call" not in offered or "tool_search" not in offered:
            return None, "outer", "tool_call/tool_search not offered"
        decl = _declared_schema(messages, "monitor")
        props = ((decl or {}).get("parameters") or {}).get("properties") or {}
        preset = {"command": PUSH, "description": "onion spike"}
        margs = _fill(decl["parameters"], preset) if decl else {}
        if decl and "command" not in props:
            return None, "outer", "monitor declaration has no 'command' parameter"
        return [_step("tool_search", {"query": "select:monitor"}, target=False, role="outer"),
                _step("tool_call", {"name": "monitor", "arguments": margs}, target=True, role="outer")], "outer", None

    return None, "outer", f"unknown r2 scenario {sc}"


def decide_r2(state: StubState, body: dict) -> dict:
    tools = body.get("tools") or []
    messages = body.get("messages") or []
    if not tools:
        return {"kind": "aux", "text": "OK", "why": "no tools in request (auxiliary call)"}
    offered = [_tool_fn(t).get("name") for t in tools if isinstance(t, dict)]
    steps, role, bad = r2_script(state, body)
    done = len(_assistant_calls(messages))
    if steps is not None and done >= len(steps):
        return {"kind": "final", "text": "DONE", "why": f"script done ({done}/{len(steps)} calls in history)", "role": role}
    if steps is None:
        return {"kind": "invalid", "mark": INVALID_MARK, "text": INVALID_MARK, "why": bad, "offered": offered, "role": role}
    st = steps[done]
    if st["name"] not in offered:
        return {"kind": "invalid", "mark": INVALID_MARK, "text": INVALID_MARK, "role": role,
                "why": f"step {done + 1} tool {st['name']!r} not in request.tools", "offered": offered}
    fn = next(_tool_fn(t) for t in tools if isinstance(t, dict) and _tool_fn(t).get("name") == st["name"])
    errors = validate_arguments(st["args"], fn.get("parameters") or {})
    if errors:
        return {"kind": "invalid", "mark": INVALID_MARK, "text": INVALID_MARK, "role": role,
                "why": "fixed call does not validate against request.tools", "tool_name": st["name"],
                "arguments": st["args"], "errors": errors, "offered": offered}
    state.tool_calls_emitted += 1
    return {"kind": "tool_call", "tool_name": st["name"], "arguments": st["args"],
            "call_id": "call_" + uuid.uuid4().hex[:16], "emitted_count": state.tool_calls_emitted,
            "step": done + 1, "steps": len(steps), "target": st["target"], "role": role,
            "why": f"r2 script step {done + 1}/{len(steps)} ({role})", "offered": offered}


def selftest() -> int:
    """Roda decide() sobre pedidos sintéticos de cada cenário e confere o roteiro. Não sobe
    servidor nem cliente."""
    import tempfile
    fails = 0

    def T(name, params):
        return {"type": "function", "function": {"name": name, "parameters": params}}

    obj = lambda props, req: {"type": "object", "properties": props, "required": req}
    S = {"type": "string"}
    QWEN = [T("run_shell_command", obj({"command": S, "description": S, "is_background": {"type": "boolean"}}, ["command"])),
            T("write_file", obj({"file_path": S, "content": S}, ["file_path", "content"])),
            T("tool_call", {"type": "object", "properties": {"name": S, "arguments": {"type": "object"}},
                            "required": ["name", "arguments"], "additionalProperties": False}),
            T("tool_search", obj({"query": S}, ["query"]))]
    VIBE = [T("bash", obj({"command": S}, ["command"])), T("write_file", obj({"path": S, "content": S}, ["path", "content"])),
            T("run_typescript", {"type": "object", "properties": {"code": S}, "required": ["code"], "additionalProperties": False}),
            T("wait", obj({"timeout_ms": {"type": "integer"}}, ["timeout_ms"])),
            T("read_file", obj({"path": S}, ["path"]))]
    QWEN_R = QWEN + [T("read_file", obj({"file_path": S}, ["file_path"]))]
    G = {"role": "user", "content": "go"}
    AGENT_DECL = {"name": "agent", "description": "x",
                  "parameters": obj({"description": S, "prompt": S, "subagent_type": S}, ["description", "prompt"])}
    MONITOR_DECL = {"name": "monitor", "parameters": obj({"command": S, "description": S}, ["command"])}

    def asst(name, args=None):
        return {"role": "assistant", "content": None,
                "tool_calls": [{"id": "x", "type": "function", "function": {"name": name, "arguments": json.dumps(args or {})}}]}

    def tool(content):
        return {"role": "tool", "tool_call_id": "x", "content": content}

    R1 = [G, asst("read_file"), tool("base")]   # o passo de topo já feito
    U = {"role": "user", "content": "Use the MCP tool write_marker. deferred: mcp__onionspike__write_marker, agent, monitor"}
    with tempfile.TemporaryDirectory() as t:
        def st(sc):
            return StubState(sc, os.path.join(t, "log"), t, "/w")
        cases = [
            # (nome, cenário, tools, mensagens, kind esperado, tool esperada, target esperado)
            ("r1 c unchanged", "c", QWEN, [U], "tool_call", "run_shell_command", None),
            ("r1 c after result -> DONE", "c", QWEN, [U, asst("run_shell_command"), tool("ok")], "final", None, None),
            ("mcp direct", "mcp", QWEN + [T("mcp__onionspike__write_marker", obj({"path": S, "content": S}, ["path", "content"]))],
             [U], "tool_call", "mcp__onionspike__write_marker", True),
            ("mcp deferred step1 tool_search", "mcp", QWEN, [U], "tool_call", "tool_search", False),
            ("mcp deferred step2 tool_call", "mcp", QWEN, [U, asst("tool_search"), tool("<functions/>")], "tool_call", "tool_call", True),
            ("mcp deferred done", "mcp", QWEN, [U, asst("tool_search"), tool("."), asst("tool_call"), tool(".")], "final", None, None),
            ("mcp absent -> invalid", "mcp", QWEN[:2], [{"role": "user", "content": "go"}], "invalid", None, None),
            ("vibe mcp step1 is the top-level read_file", "mcp", VIBE, [G], "tool_call", "read_file", False),
            ("mcp vibe via run_typescript", "mcp", VIBE, R1, "tool_call", "run_typescript", True),
            ("vibe without read_file -> invalid", "ts", VIBE[:-1], [G], "invalid", None, None),
            ("pc qwen step1 read_file", "pc", QWEN_R, [U], "tool_call", "read_file", False),
            ("pc qwen step2 shell push", "pc", QWEN_R, [U, asst("read_file"), tool("base")], "tool_call", "run_shell_command", True),
            ("pc vibe step2 bash", "pc", VIBE, R1, "tool_call", "bash", True),
            ("pc shell missing: step1 still read_file", "pc", [t for t in QWEN_R if t["function"]["name"] != "run_shell_command"],
             [U], "tool_call", "read_file", False),
            ("pc shell missing: step2 not offered", "pc", [t for t in QWEN_R if t["function"]["name"] != "run_shell_command"],
             [U, asst("read_file"), tool("base")], "invalid", None, None),
            ("sub qwen step1", "sub", QWEN, [U], "tool_call", "tool_search", False),
            ("sub qwen step2 from declared schema", "sub", QWEN,
             [U, asst("tool_search"), tool("<functions><function>" + json.dumps(AGENT_DECL) + "</function></functions>")],
             "tool_call", "tool_call", False),
            ("sub qwen step2 without declaration -> invalid", "sub", QWEN, [U, asst("tool_search"), tool("nothing")], "invalid", None, None),
            ("sub inner (token in user) -> shell push", "sub", QWEN, [{"role": "user", "content": SUBTASK_TEXT}],
             "tool_call", "run_shell_command", True),
            ("sub inner done", "sub", QWEN, [{"role": "user", "content": SUBTASK_TEXT}, asst("run_shell_command"), tool("ok")],
             "final", None, None),
            ("sub vibe run_typescript spawn", "sub", VIBE, R1, "tool_call", "run_typescript", False),
            ("sub vibe step3 wait", "sub", VIBE, R1 + [asst("run_typescript"), tool("{}")],
             "tool_call", "wait", False),
            ("sub vibe done after wait", "sub", VIBE, R1 + [asst("run_typescript"), tool("{}"),
                                                      asst("wait"), tool("{}")], "final", None, None),
            ("sub vibe inner bash", "sub", VIBE, [{"role": "user", "content": SUBTASK_TEXT}], "tool_call", "bash", True),
            ("ts vibe", "ts", VIBE, R1, "tool_call", "run_typescript", True),
            ("proc vibe", "proc", VIBE, R1, "tool_call", "run_typescript", True),
            ("ts on qwen -> invalid", "ts", QWEN, [U], "invalid", None, None),
            ("tc qwen step1 read_file", "tc", QWEN_R, [U], "tool_call", "read_file", False),
            ("tc qwen", "tc", QWEN_R, [U, asst("read_file"), tool("base")], "tool_call", "tool_call", True),
            ("tc without read_file -> invalid", "tc", QWEN, [U], "invalid", None, None),
            ("tcd qwen step1", "tcd", QWEN, [U], "tool_call", "tool_search", False),
            ("tcd qwen step2", "tcd", QWEN, [U, asst("tool_search"), tool(json.dumps(MONITOR_DECL))], "tool_call", "tool_call", True),
            ("aux without tools", "sub", [], [U], "aux", None, None),
        ]
        for name, sc, tools, msgs, kind, tname, target in cases:
            d = decide(st(sc), {"tools": tools, "messages": msgs})
            ok = d["kind"] == kind and (tname is None or d.get("tool_name") == tname) and (target is None or d.get("target") is target)
            if ok and name == "sub qwen step2 from declared schema":
                a = d["arguments"]
                ok = a.get("name") == "agent" and a["arguments"].get("prompt") == SUBTASK_TEXT
            if ok and name == "tc qwen":
                ok = d["arguments"]["arguments"]["command"] == PUSH
            if ok and name == "pc shell missing: step2 not offered":
                ok = d["why"] == "no tool for the scenario in request.tools"
            if ok and name == "pc qwen step1 read_file":
                ok = d["arguments"] == {"file_path": "/w/README.txt"}
            if ok and name == "mcp vibe via run_typescript":
                ok = "tools.mcp_onionspike.write_marker" in d["arguments"]["code"] and "/w/MARKER.txt" in d["arguments"]["code"]
            if ok and name == "mcp deferred step2 tool_call":
                ok = d["arguments"] == {"name": "mcp__onionspike__write_marker", "arguments": {"path": "/w/MARKER.txt", "content": "x"}}
            fails += 0 if ok else 1
            print(f"{'ok  ' if ok else 'FAIL'}  STUB-SELFTEST {name:48} -> {d['kind']} {d.get('tool_name')} target={d.get('target')}")
    # Emenda R2-1: todo cenário da rodada 2 tem de passar no --scenario da linha de comando
    missing = sorted(R2_SCENARIOS - set(SCENARIO_ALIASES))
    fails += 1 if missing else 0
    print(f"{'ok  ' if not missing else 'FAIL'}  STUB-SELFTEST every R2 scenario accepted by the CLI {missing or ''}")
    print("ALL PASS" if not fails else f"{fails} FAILURE(S)")
    return 1 if fails else 0


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
    if "--selftest" in sys.argv[1:]:
        return selftest()
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
