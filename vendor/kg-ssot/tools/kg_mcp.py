#!/usr/bin/env python3
"""Servidor MCP de referência do KG-SSOT: o contrato e o armazém para um modelo.

Só biblioteca padrão, mais o leitor (kg_validate.py) e o armazém (kg_store.py). Fala JSON-RPC 2.0 do Model Context
Protocol por stdio (uma mensagem por linha) ou por HTTP (POST de uma mensagem no caminho /mcp, resposta JSON, sem
stream). É um ADAPTADOR: o produto não depende dele, e ele não depende de um
cliente específico.

Ferramentas:
  kg_validate     julga um texto .kg.yaml (ou .kg.json, com format json) e devolve o kg-ssot.verdict/1 (com o armazém
                  como corpus, se há armazém)
  kg_write        grava pelo armazém: só com PASS do contrato (kg_store.write), no formato que o nome diz; devolve o
                  resultado com o veredito
  kg_delete       remove pelo armazém, se nenhum grafo que aponta para o nome reprovar sem ele
  kg_get          lê um grafo (ou uma versão anterior, com ref)
  kg_list         lista os grafos do armazém
  kg_history      as operações de um grafo, da mais nova para a mais antiga
  kg_schema_help  o resumo do contrato vigente: campos, listas permitidas e a correção dos códigos mais comuns

O que fica com quem adota, de propósito: autenticação, TLS, identidade, multiusuário e área por usuário (um processo
ou um root por usuário), cota e timeout. O HTTP escuta em 127.0.0.1 por padrão, recusa Origin que não seja de loopback
e MCP-Protocol-Version desconhecida, e só sai do loopback com --allow-remote. Lote JSON-RPC é recusado.
O autor das gravações é o do servidor (--author), nunca um argumento da ferramenta: o modelo não escolhe quem assina.

Uso:
  kg_mcp.py --root DIR [--backend disk|git|versioned] [--init] [--author "Nome <email>"] [--read-only]
            [--http PORTA [--host 127.0.0.1] [--allow-remote]] [--max-bytes N]
Sem --root, só kg_validate e kg_schema_help ficam disponíveis.
rc: 0 saída normal · 2 entrada quebrada (raiz inválida, opção inválida).
"""
import argparse
import http.server
import json
import pathlib
import sys
import urllib.parse

sys.dont_write_bytecode = True
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import kg_store  # noqa: E402
import kg_validate  # noqa: E402

SERVER_NAME = "kg-ssot"
PROTOCOLS = ("2025-11-25", "2025-06-18", "2025-03-26", "2024-11-05")  # o primeiro é o preferido
MAX_BYTES = 2_000_000

NAME_PROP = {"type": "string", "description": "caminho relativo no armazém, terminado em .kg.yaml ou .kg.json (ex.: "
                                             "grafos/caso.kg.yaml); a extensão diz o formato do texto"}
TEXT_PROP = {"type": "string", "description": "o documento inteiro: YAML num .kg.yaml, JSON num .kg.json"}
FORMAT_PROP = {"enum": ["yaml", "json"], "description": "o formato do texto: yaml (.kg.yaml, o default) ou json (.kg.json, "
                                                        "no perfil JSON do contrato); com name, o default é o da extensão"}
TOOLS = {
    "kg_validate": {
        "description": "Julga um grafo .kg.yaml (ou .kg.json, com format json) pelo contrato KG-SSOT vigente sem "
                       "gravar. Devolve verdict PASS ou FAIL e, por ocorrência, code (estável), place, path, line, "
                       "message e hint (a correção). Corrija pelos hints e julgue de novo antes de gravar.",
        "inputSchema": {"type": "object", "additionalProperties": False, "required": ["text"],
                        "properties": {"text": TEXT_PROP,
                                       "name": dict(NAME_PROP, description="o nome que o grafo teria no armazém "
                                                    "(confere a ponta externa como se estivesse lá)"),
                                       "format": FORMAT_PROP,
                                       "limit": {"type": "integer", "minimum": 1, "maximum": 500,
                                                 "description": "ocorrências devolvidas (default 50)"}}},
        "needs_store": False, "writes": False},
    "kg_write": {
        "description": "Grava um grafo no armazém, só se o contrato aprovar o candidato e os grafos que apontam para "
                       "ele. O formato vem do nome: .kg.yaml é YAML e .kg.json é JSON. written=false traz reason "
                       "(gate, conflict, not_judged) e o veredito. Use expected_sha256 (o sha256 do que você leu, ou "
                       "'new' para um nome novo) para não sobrescrever a mudança de outro.",
        "inputSchema": {"type": "object", "additionalProperties": False, "required": ["name", "text"],
                        "properties": {"name": NAME_PROP, "text": TEXT_PROP,
                                       "message": {"type": "string", "maxLength": 500},
                                       "expected_sha256": {"type": "string", "pattern": "^(new|[0-9a-f]{64})$"}}},
        "needs_store": True, "writes": True},
    "kg_delete": {
        "description": "Remove um grafo do armazém, só se nenhum grafo que aponta para ele reprovar sem ele.",
        "inputSchema": {"type": "object", "additionalProperties": False, "required": ["name"],
                        "properties": {"name": NAME_PROP, "message": {"type": "string", "maxLength": 500},
                                       "expected_sha256": {"type": "string", "pattern": "^[0-9a-f]{64}$"}}},
        "needs_store": True, "writes": True},
    "kg_get": {
        "description": "Lê um grafo do armazém (o texto e o sha256). Com ref, uma versão anterior (veja kg_history).",
        "inputSchema": {"type": "object", "additionalProperties": False, "required": ["name"],
                        "properties": {"name": NAME_PROP, "ref": {"type": ["string", "integer"]}}},
        "needs_store": True, "writes": False},
    "kg_list": {
        "description": "Lista os nomes dos grafos do armazém.",
        "inputSchema": {"type": "object", "additionalProperties": False, "properties": {}},
        "needs_store": True, "writes": False},
    "kg_history": {
        "description": "As operações de um grafo no armazém, da mais nova para a mais antiga (ref, op, autor, data).",
        "inputSchema": {"type": "object", "additionalProperties": False, "required": ["name"],
                        "properties": {"name": NAME_PROP}},
        "needs_store": True, "writes": False},
    "kg_schema_help": {
        "description": "O contrato vigente para escrever um grafo que passa: os schemas MUST e SHOULD inteiros, um "
                       "exemplo mínimo que passa, as regras de integridade e a correção dos códigos mais comuns. "
                       "Chame antes de escrever o primeiro grafo.",
        "inputSchema": {"type": "object", "additionalProperties": False, "properties": {}},
        "needs_store": False, "writes": False},
}




class ToolError(Exception):
    """Erro de uso da ferramenta: vai ao modelo como isError, não derruba o servidor."""


class _RpcError(Exception):
    def __init__(self, code, message):
        super().__init__(message)
        self.code = code


EXAMPLE = kg_validate._ROOT / "spec" / "conformance" / "fixtures" / "latest" / "form" / "minimal" / "valid-minimal.kg.yaml"


def schema_help():
    """O contrato vigente para um modelo: os dois schemas CRUS (fiéis por construção, nada resumido à mão), um exemplo
    mínimo que passa, a correção dos códigos mais comuns e as regras que o schema não alcança (a integridade)."""
    must = json.loads(pathlib.Path(kg_validate.CONTRACT_MUST).read_text(encoding="utf-8"))
    should = json.loads(pathlib.Path(kg_validate.CONTRACT_SHOULD).read_text(encoding="utf-8"))
    try:
        example = EXAMPLE.read_text(encoding="utf-8")
    except OSError:
        example = None
    return {"contract": kg_validate.contract_info(kg_validate.CONTRACT_MUST, kg_validate.CONTRACT_SHOULD),
            "how_to_read": "must reprova (verdict FAIL); should só avisa. Os dois são JSON Schema 2020-12 sobre o grafo "
                           "lido como JSON (no YAML, datas entre aspas viram texto). O exemplo passa nos dois.",
            "formats": {"yaml": "o .kg.yaml: YAML 1.2 core restrito (chave única, sem .nan nem .inf, datas entre aspas); "
                                "inteiro fora de ±(2^53−1), surrogate solto e mais de 128 níveis só avisam",
                        "json": "o .kg.json: o mesmo modelo em JSON, no perfil do contrato (RFC 8259 e I-JSON). Reprova "
                                "inteiro fora de ±(2^53−1) (form.type), surrogate solto, mais de 128 níveis, NaN, "
                                "comentário, vírgula sobrando, espaço fora da RFC e BOM que não é o inicial "
                                "(parse.yaml-error), e chave repetida (parse.duplicate-key). kg_validate pede "
                                "format: json; kg_write lê pela extensão do nome."},
            "integrity": ["um único documento (YAML, ou um objeto JSON no .kg.json), com a raiz em mapa",
                          "ids de nó únicos; toda aresta liga dois ids que existem; nenhum nó fica sem aresta",
                          "a ponta externa (outro.kg.yaml#ID) tem de existir no armazém",
                          "datas entre aspas (\"2026-10-13\"), nunca soltas"],
            "example": example,
            "hints": dict(sorted(kg_validate.HINTS.items())),
            "hints_scope": "a correção dos códigos mais comuns; para os outros, leia o schema no caminho do code",
            "must": must, "should": should}


_ARG_VALIDATORS = {}


def _check_args(name, args):
    """Os argumentos contra o inputSchema da ferramenta (o mesmo que tools/list anuncia): tipo, obrigatório, extra."""
    v = _ARG_VALIDATORS.get(name)
    if v is None:
        v = _ARG_VALIDATORS[name] = kg_validate.make_validator(TOOLS[name]["inputSchema"])
    errors = sorted(v.iter_errors(args), key=lambda e: list(e.path))
    if errors:
        e = errors[0]
        where = ".".join(str(p) for p in e.path) or "arguments"
        raise ToolError(f"argumento inválido em {where}: {e.message}")


class Server:
    def __init__(self, store=None, author=None, read_only=False, max_bytes=MAX_BYTES):
        self.store, self.author, self.read_only, self.max_bytes = store, author, read_only, max_bytes

    def tools(self):
        return [{"name": n, "description": t["description"], "inputSchema": t["inputSchema"]}
                for n, t in TOOLS.items()
                if (self.store is not None or not t["needs_store"]) and not (self.read_only and t["writes"])]

    # --- JSON-RPC ------------------------------------------------------------------------------------------
    def handle(self, msg):
        """Uma mensagem JSON-RPC decodificada → a resposta (dict) ou None para notificação. Nunca levanta: um erro
        interno vira -32603, para o processo de vida longa seguir atendendo."""
        try:
            return self._handle(msg)
        except Exception as exc:  # noqa: BLE001 - a última rede: o servidor não cai por uma mensagem
            mid = msg.get("id") if isinstance(msg, dict) and _valid_id(msg.get("id")) else None
            return None if isinstance(msg, dict) and "id" not in msg else \
                self._error(mid, -32603, f"erro interno: {type(exc).__name__}")

    def _handle(self, msg):
        if isinstance(msg, list):  # o lote saiu do MCP em 2025-06-18; aqui ele é recusado em qualquer versão
            return self._error(None, -32600, "lote JSON-RPC não é aceito: mande uma mensagem por vez")
        if not isinstance(msg, dict) or msg.get("jsonrpc") != "2.0" or not isinstance(msg.get("method"), str):
            mid = msg.get("id") if isinstance(msg, dict) and _valid_id(msg.get("id")) else None
            return self._error(mid, -32600, "requisição inválida")
        notification = "id" not in msg
        mid, method = msg.get("id"), msg["method"]
        if not notification and not _valid_id(mid):
            return self._error(None, -32600, "id tem de ser string ou inteiro")
        params = msg.get("params", {})
        if not isinstance(params, dict):
            return None if notification else self._error(mid, -32602, "params tem de ser objeto")
        if notification:
            return None  # initialized, cancelled e as outras: nada a responder
        try:
            if method == "initialize":
                asked = params.get("protocolVersion")
                result = {"protocolVersion": asked if asked in PROTOCOLS else PROTOCOLS[0],
                          "capabilities": {"tools": {"listChanged": False}},
                          "serverInfo": {"name": SERVER_NAME, "version": self._release()},
                          "instructions": "Chame kg_schema_help antes do primeiro grafo; julgue com kg_validate e "
                                          "corrija pelos hints; grave com kg_write, que recusa o que reprova."}
            elif method == "ping":
                result = {}
            elif method == "tools/list":
                result = {"tools": self.tools()}
            elif method == "tools/call":
                result = self._call(params)
            else:
                return self._error(mid, -32601, f"método desconhecido: {method}")
        except _RpcError as exc:
            return self._error(mid, exc.code, str(exc))
        return {"jsonrpc": "2.0", "id": mid, "result": result}

    @staticmethod
    def _error(mid, code, message):
        return {"jsonrpc": "2.0", "id": mid, "error": {"code": code, "message": message}}

    @staticmethod
    def _release():
        try:
            return json.loads((kg_validate._ROOT / "spec" / "release.json").read_text(encoding="utf-8")).get("version", "?")
        except (OSError, ValueError):
            return "?"

    def _call(self, params):
        name, args = params.get("name"), params.get("arguments", {})
        if not isinstance(name, str):
            raise _RpcError(-32602, "tools/call sem name")
        if name not in {t["name"] for t in self.tools()}:
            raise _RpcError(-32602, f"ferramenta indisponível: {name}")
        if not isinstance(args, dict):
            raise _RpcError(-32602, "arguments tem de ser objeto")
        try:
            _check_args(name, args)
            payload, is_error = self._run(name, args)
        except ToolError as exc:
            payload, is_error = {"error": str(exc)}, True
        except kg_store.NotFound as exc:
            payload, is_error = {"error": str(exc), "reason": "missing"}, True
        except kg_store.StoreError as exc:
            payload, is_error = {"error": str(exc)}, True
        return {"content": [{"type": "text", "text": json.dumps(payload, ensure_ascii=False)}],
                "structuredContent": payload, "isError": is_error}

    def _text(self, args):
        text = args["text"]
        try:
            size = len(text.encode("utf-8"))
        except UnicodeEncodeError:
            raise ToolError("text tem caractere que não é UTF-8 válido (surrogate solto)")
        if size > self.max_bytes:
            raise ToolError(f"o grafo passa de {self.max_bytes} bytes")
        return text

    @staticmethod
    def _as_format(text, gname, fmt):
        """O texto como o leitor o lê: format json é o .kg.json (JsonText), yaml é o .kg.yaml. Sem format, o default é
        o da extensão do nome, e sem nome é yaml; um format que contradiz a extensão é erro de uso."""
        by_name = "json" if gname.endswith(".kg.json") else "yaml" if gname != "-" else None
        if fmt is not None and by_name is not None and fmt != by_name:
            raise ToolError(f"format {fmt} contradiz o nome {gname}")
        return kg_validate.JsonText(text) if (fmt or by_name or "yaml") == "json" else text

    def _run(self, name, args):
        if name == "kg_schema_help":
            return schema_help(), False
        if name == "kg_validate":
            text = self._text(args)
            gname = args.get("name", "-")
            if gname != "-":
                kg_store.check_name(gname)
            text = self._as_format(text, gname, args.get("format"))
            corpus = None
            if self.store is not None:
                items = self.store._texts(skip=gname)
                corpus = kg_store.DiskStore.corpus_of(items + ([(gname, text)] if gname != "-" else []))
            return kg_validate.judge([(gname, text)], corpus=corpus, limit=args.get("limit", 50)), False
        if name == "kg_write":
            r = self.store.write(args["name"], self._text(args), args.get("message"), self.author,
                                 args.get("expected_sha256"))
            return r, not r["written"]
        if name == "kg_delete":
            r = self.store.delete(args["name"], args.get("message"), self.author, args.get("expected_sha256"))
            return r, not r["written"]
        if name == "kg_get":
            text = self.store.read(args["name"], args.get("ref"))
            return {"name": args["name"], "sha256": kg_store.sha256(text), "text": text}, False
        if name == "kg_list":
            return {"names": self.store.list()}, False
        if name == "kg_history":
            return {"name": args["name"], "history": self.store.history(args["name"])}, False
        raise ToolError(f"ferramenta sem implementação: {name}")


def _valid_id(mid):
    return isinstance(mid, str) or (isinstance(mid, int) and not isinstance(mid, bool))


def _wire(obj):
    """JSON em ASCII: um surrogate solto ou um caractere fora da página de código nunca quebra a escrita."""
    return json.dumps(obj, ensure_ascii=True)


def serve_stdio(server, stdin=None, stdout=None):
    """Uma mensagem JSON-RPC por linha, em UTF-8 lido e escrito como bytes (independe do locale). O stderr é só para
    log. Linha grande demais, UTF-8 inválido e JSON inválido viram erro JSON-RPC; o laço nunca cai."""
    stdin = stdin if stdin is not None else sys.stdin.buffer
    stdout = stdout if stdout is not None else sys.stdout.buffer
    limit = server.max_bytes * 6 + 65536  # o texto do grafo dentro de JSON: no pior caso, 6 bytes por caractere
    while True:
        line = stdin.readline(limit + 1)
        if not line:
            break
        if len(line) > limit and not line.endswith(b"\n"):
            while line and not line.endswith(b"\n"):  # descarta o resto da linha gigante
                line = stdin.readline(limit + 1)
            resp = Server._error(None, -32600, "mensagem grande demais")
        else:
            line = line.strip()
            if not line:
                continue
            try:
                msg = json.loads(line.decode("utf-8"))
            except (UnicodeDecodeError, ValueError):
                resp = Server._error(None, -32700, "JSON inválido ou fora de UTF-8")
            else:
                resp = server.handle(msg)
        if resp is not None:
            stdout.write((_wire(resp) + "\n").encode("ascii"))
            stdout.flush()


LOOPBACK = {"localhost", "127.0.0.1", "::1"}


def _local_origin(origin):
    try:
        parts = urllib.parse.urlsplit(origin)
        parts.port  # porta inválida ("localhost:8080.evil.com") levanta ValueError: não é origem local
        return parts.scheme in ("http", "https") and parts.hostname in LOOPBACK and not parts.path.strip("/")
    except ValueError:
        return False


def make_http_handler(server):
    class Handler(http.server.BaseHTTPRequestHandler):
        server_version = "kg-ssot-mcp"
        timeout = 30  # um Content-Length mentiroso não prende a thread para sempre

        def log_message(self, fmt, *args):  # o log vai ao stderr, sem o corpo das mensagens
            sys.stderr.write("%s %s\n" % (self.address_string(), fmt % args))

        def _send(self, code, body=None):
            data = b"" if body is None else _wire(body).encode("ascii")
            self.send_response(code)
            if body is not None:
                self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(data)))
            self.end_headers()
            self.wfile.write(data)

        def _refuse(self):
            self._send(405, {"error": "use POST /mcp"})

        do_GET = do_PUT = do_DELETE = do_PATCH = _refuse  # sem stream do servidor e sem sessão a encerrar

        def do_POST(self):
            try:
                self._post()
            except Exception as exc:  # noqa: BLE001 - a thread responde 500 e o servidor segue
                try:
                    self._send(500, Server._error(None, -32603, f"erro interno: {type(exc).__name__}"))
                except OSError:
                    pass

        def _post(self):
            if self.path.split("?", 1)[0] != "/mcp":
                return self._send(404, {"error": "o caminho é /mcp"})
            origin = self.headers.get("Origin")
            if origin is not None and not _local_origin(origin):
                return self._send(403, {"error": "Origin não local recusada"})  # DNS rebinding
            version = self.headers.get("MCP-Protocol-Version")
            if version is not None and version not in PROTOCOLS:
                return self._send(400, {"error": f"MCP-Protocol-Version não suportada: {version}"})
            if self.headers.get("Transfer-Encoding"):
                return self._send(411, {"error": "mande Content-Length, sem Transfer-Encoding"})
            try:
                size = int(self.headers.get("Content-Length", ""))
            except ValueError:
                return self._send(411, {"error": "Content-Length ausente ou inválido"})
            if size <= 0:
                return self._send(400, {"error": "corpo vazio"})
            if size > server.max_bytes * 6 + 65536:
                return self._send(413, {"error": "corpo grande demais"})
            try:
                body = self.rfile.read(size)
            except TimeoutError:  # Content-Length maior que o corpo: o cliente parou de mandar
                return self._send(408, {"error": "corpo incompleto no prazo"})
            if len(body) != size:
                return self._send(400, {"error": "corpo menor que o Content-Length"})
            try:
                msg = json.loads(body.decode("utf-8"))
            except (UnicodeDecodeError, ValueError):
                return self._send(400, Server._error(None, -32700, "JSON inválido ou fora de UTF-8"))
            resp = server.handle(msg)
            return self._send(202) if resp is None else self._send(200, resp)
    return Handler


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--root", help="raiz do armazém; sem ela, só kg_validate e kg_schema_help")
    ap.add_argument("--backend", choices=sorted(kg_store.BACKENDS), default="disk")
    ap.add_argument("--init", action="store_true")
    ap.add_argument("--author", help="quem assina as gravações, na forma 'Nome <email>'")
    ap.add_argument("--read-only", action="store_true", help="sem kg_write nem kg_delete")
    ap.add_argument("--http", type=int, metavar="PORTA", help="serve HTTP em vez de stdio")
    ap.add_argument("--host", default="127.0.0.1")
    ap.add_argument("--allow-remote", action="store_true",
                    help="aceita --host fora do loopback (sem auth nem TLS: só atrás de um proxy que faça os dois)")
    ap.add_argument("--max-bytes", type=int, default=MAX_BYTES)
    args = ap.parse_args(argv)
    if args.max_bytes < 1:
        print("ENTRADA QUEBRADA  --max-bytes tem de ser 1 ou mais", file=sys.stderr)
        return 2
    if args.http is not None and args.host not in LOOPBACK and not args.allow_remote:
        print(f"ENTRADA QUEBRADA  --host {args.host} sai do loopback: o servidor não tem auth nem TLS; use "
              "--allow-remote atrás de um proxy que faça os dois", file=sys.stderr)
        return 2
    try:
        store = kg_store.open_store(args.backend, args.root, init=args.init) if args.root else None
        kg_store.check_author(args.author)
    except kg_store.StoreError as exc:
        print(f"ENTRADA QUEBRADA  {exc}", file=sys.stderr)
        return 2
    server = Server(store, args.author, args.read_only, args.max_bytes)
    if args.http is None:
        serve_stdio(server)
        return 0
    httpd = http.server.ThreadingHTTPServer((args.host, args.http), make_http_handler(server))
    print(f"kg-ssot MCP em http://{args.host}:{args.http}/mcp", file=sys.stderr)
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        pass
    return 0


if __name__ == "__main__":
    sys.exit(main())
