#!/usr/bin/env python3
"""onion-kg — o read(KG) do core como servidor MCP (F6.3; spec = pesquisa F4b).

READ-ONLY por construção: toda tool é leitura do repo (git ls-files, kg-radar.sh, grep,
arquivos) — nenhuma escreve nada. O write(KG) de agente externo é PROPOSTA que o core sela
(I3, um escritor por repo) e NAO passa por aqui.

Molde: o mcp_server.py do assistente-pdi (PoC) — streamable-http em stdlib pura, mesmo
handler JSON-RPC. Diferencas: auth por X-Api-Key (token em pass onion/mcp-kg-token; o
container do LibreChat manda via headers do librechat.yaml) e bind proprio.

Uso: ONION_KG_TOKEN=... python3 ops/mcp-onion-kg/server.py
     (bind 172.23.0.1:3032 — bridge docker do onion-librechat; regra ufw cirurgica)
"""
import hmac
import json
import os
import subprocess
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
HOST = os.environ.get('MCP_HOST', '172.23.0.1')
PORT = int(os.environ.get('MCP_PORT', '3032'))
TOKEN = os.environ.get('ONION_KG_TOKEN', '')
if not TOKEN:
    raise SystemExit('ONION_KG_TOKEN ausente — fail-closed, nao subo sem auth')

MAX_OUT = 60_000  # teto de payload por resposta (contexto de agente, nao dump)


def _run(cmd, timeout=60):
    r = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout, cwd=REPO)
    return (r.stdout or '') + (('\n[stderr]\n' + r.stderr) if r.returncode != 0 and r.stderr else '')


def kg_list(_args):
    out = _run(['git', 'ls-files', '*.kg.yaml'])
    grafos = [l for l in out.splitlines() if '/fixtures/' not in l]
    return {'total': len(grafos), 'grafos': grafos,
            'nota': 'o SSOT vivo do estado; rode kg_radar num deles antes de afirmar estado'}


def kg_radar(args):
    g = args.get('grafo', '')
    if not g or '..' in g or not g.endswith('.kg.yaml'):
        raise ValueError('grafo: caminho relativo de um .kg.yaml do repo (use kg_list)')
    return {'grafo': g, 'radar': _run(['bash', '.claude/validation/kg-radar.sh', g])[:MAX_OUT]}


def kb_search(args):
    termo = args.get('termo', '').strip()
    if not termo or len(termo) < 3:
        raise ValueError('termo: minimo 3 caracteres')
    out = _run(['grep', '-rin', '-m', '3', termo, 'docs/knowledge-base/', '--include=*.md'])
    linhas = out.splitlines()[:80]
    return {'termo': termo, 'ocorrencias': len(linhas), 'resultado': '\n'.join(linhas)[:MAX_OUT],
            'nota': 'cite o ARQUIVO da linha usada; se vazio, diga "o corpus nao cobre" — nunca invente'}


def kb_get(args):
    p = args.get('arquivo', '')
    if not p.startswith('docs/knowledge-base/') or '..' in p or not p.endswith('.md'):
        raise ValueError('arquivo: caminho docs/knowledge-base/**.md (use kb_search para achar)')
    fp = os.path.join(REPO, p)
    if not os.path.isfile(fp):
        raise ValueError(f'nao existe: {p}')
    return {'arquivo': p, 'conteudo': open(fp, encoding='utf-8').read()[:MAX_OUT]}


def diary_index(_args):
    fp = os.path.join(REPO, '.claude/diary/index.md')
    return {'index': open(fp, encoding='utf-8').read()[:MAX_OUT],
            'nota': 'Tier-0 do diario; entradas completas nao sao servidas por esta via'}


def inventory(_args):
    fp = os.path.join(REPO, 'docs/onion/inventory.md')
    return {'inventario': open(fp, encoding='utf-8').read()[:MAX_OUT],
            'nota': 'SSOT gerada do filesystem — os numeros canonicos do framework'}


TOOLS = {
    'kg_list': (kg_list, 'Lista os grafos .kg.yaml do core (o SSOT vivo do estado)', {}),
    'kg_radar': (kg_radar, 'Roda o radar deterministico num grafo: atencao, ESTADO (abertos), reconciliacao, integridade', {'grafo': {'type': 'string', 'description': 'caminho relativo do .kg.yaml'}}),
    'kb_search': (kb_search, 'Busca um termo nas 91 KBs (docs/knowledge-base) — retorna arquivo:linha p/ citar', {'termo': {'type': 'string', 'description': 'termo de busca (>=3 chars)'}}),
    'kb_get': (kb_get, 'Le uma KB inteira pelo caminho (docs/knowledge-base/**.md)', {'arquivo': {'type': 'string', 'description': 'caminho da KB'}}),
    'diary_index': (diary_index, 'O indice Tier-0 do diario de aprendizado do core', {}),
    'inventory': (inventory, 'O inventario canonico (comandos/agentes/skills/KBs) — SSOT gerada', {}),
}
FERRAMENTAS = [
    {'name': n, 'description': d,
     'inputSchema': {'type': 'object', 'properties': props,
                     'required': [k for k in props]}}
    for n, (_, d, props) in TOOLS.items()
]


def executa(nome, args):
    if nome not in TOOLS:
        raise ValueError(f'tool desconhecida: {nome} (disponiveis: {", ".join(TOOLS)})')
    return TOOLS[nome][0](args)


class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *a):  # noqa: N802
        pass

    def _json(self, obj, code=200):
        body = json.dumps(obj, ensure_ascii=False).encode()
        self.send_response(code)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Content-Length', str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _auth_ok(self):
        return hmac.compare_digest(self.headers.get('X-Api-Key', ''), TOKEN)

    def do_GET(self):  # noqa: N802 — health sem auth (sem dado)
        if self.path == '/health':
            return self._json({'status': 'UP', 'tools': len(FERRAMENTAS)})
        return self._json({'error': 'not found'}, 404)

    def do_POST(self):  # noqa: N802
        if not self._auth_ok():
            return self._json({'jsonrpc': '2.0', 'id': None,
                               'error': {'code': -32000, 'message': 'unauthorized'}}, 401)
        try:
            req = json.loads(self.rfile.read(int(self.headers.get('Content-Length', 0)) or 0) or b'{}')
        except json.JSONDecodeError:
            return self._json({'jsonrpc': '2.0', 'id': None,
                               'error': {'code': -32700, 'message': 'parse error'}}, 400)
        rid, metodo, params = req.get('id'), req.get('method', ''), req.get('params', {})
        if rid is None:  # notificação
            self.send_response(202)
            self.send_header('Content-Length', '0')
            self.end_headers()
            return
        if metodo == 'initialize':
            return self._json({'jsonrpc': '2.0', 'id': rid, 'result': {
                'protocolVersion': params.get('protocolVersion', '2025-03-26'),
                'capabilities': {'tools': {}},
                'serverInfo': {'name': 'onion-kg', 'version': '0.1.0',
                               'title': 'Onion KG — read(KG) do core: grafos, radar, KBs, diario, inventario'}}})
        if metodo == 'tools/list':
            return self._json({'jsonrpc': '2.0', 'id': rid, 'result': {'tools': FERRAMENTAS}})
        if metodo == 'tools/call':
            try:
                r = executa(params.get('name', ''), params.get('arguments') or {})
                return self._json({'jsonrpc': '2.0', 'id': rid, 'result': {
                    'content': [{'type': 'text', 'text': json.dumps(r, ensure_ascii=False, indent=1)}],
                    'isError': False}})
            except Exception as e:  # noqa: BLE001 — erro vira resultado MCP legivel
                return self._json({'jsonrpc': '2.0', 'id': rid, 'result': {
                    'content': [{'type': 'text', 'text': f'erro: {e}'}], 'isError': True}})
        if metodo == 'ping':
            return self._json({'jsonrpc': '2.0', 'id': rid, 'result': {}})
        return self._json({'jsonrpc': '2.0', 'id': rid,
                           'error': {'code': -32601, 'message': f'metodo nao suportado: {metodo}'}})


if __name__ == '__main__':
    print(f'onion-kg (MCP) em http://{HOST}:{PORT}/mcp — {len(FERRAMENTAS)} tools read-only')
    ThreadingHTTPServer((HOST, PORT), Handler).serve_forever()
