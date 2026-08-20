#!/usr/bin/env python3
"""onion-framework — a 3ª natureza: IDENTIDADE/NAVEGAÇÃO do Framework Onion (F6.6).

O que faz o LibreChat CONHECER o Onion, não só consultar dados dele: as verticais (categorias
de comando), os comandos com o que cada um faz, os agentes especialistas, as skills, e as
cunhagens (Elenxo/Bulbo/SDAAL/porosidade). Lê o filesystem do core DIRETO (frontmatter dos .md),
sem depender de script externo — read-only por construção.

Trinca de MCPs, uma identidade, três eixos: onion-kg (conhecimento) · onion-exec (ação) ·
onion-framework (identidade). Separados por RISCO — não por capricho: read≠exec não colapsa.

Molde: onion-kg/server.py. Roda como marcio. Uso: ONION_FW_TOKEN=... python3 server.py
"""
import hmac
import json
import os
import re
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
HOST = os.environ.get('MCP_HOST', '172.23.0.1')
PORT = int(os.environ.get('MCP_PORT', '3036'))
TOKEN = os.environ.get('ONION_FW_TOKEN', '')
if not TOKEN:
    raise SystemExit('ONION_FW_TOKEN ausente — fail-closed')
MAX_OUT = 60_000
CMD_DIR = os.path.join(REPO, '.claude/commands')
AG_DIR = os.path.join(REPO, '.claude/agents')
SK_DIR = os.path.join(REPO, '.claude/skills')

_KEBAB = re.compile(r'^[a-z0-9][a-z0-9:-]{0,60}$')


def _frontmatter(path):
    """Extrai o bloco --- ... --- e devolve dict raso (só campos de 1 linha)."""
    try:
        t = open(path, encoding='utf-8').read()
    except OSError:
        return {}
    m = re.match(r'^---\n(.*?)\n---', t, re.S)
    if not m:
        return {}
    d = {}
    for line in m.group(1).splitlines():
        mm = re.match(r'^([a-zA-Z_]+):\s*(.+)$', line)
        if mm:
            d[mm.group(1)] = mm.group(2).strip().strip('"\'')
    return d


def list_verticals(_a):
    """As categorias de comando = as verticais/dimensões do framework."""
    cats = []
    for c in sorted(os.listdir(CMD_DIR)):
        d = os.path.join(CMD_DIR, c)
        if not os.path.isdir(d) or c == 'common':
            continue
        n = len([f for f in os.listdir(d) if f.endswith('.md')])
        cats.append({'vertical': c, 'comandos': n})
    return {'verticais': cats, 'total_categorias': len(cats),
            'nota': 'as 3 dimensões PEER da doutrina são produto/engenharia/compliance; as demais são categorias de comando (design é categoria, não 4ª peer)'}


def list_commands(a):
    cat = a.get('categoria', '').strip()
    out = []
    dirs = [os.path.join(CMD_DIR, cat)] if cat else \
        [os.path.join(CMD_DIR, c) for c in os.listdir(CMD_DIR) if os.path.isdir(os.path.join(CMD_DIR, c)) and c != 'common']
    for d in dirs:
        if not os.path.isdir(d):
            raise ValueError(f'categoria inexistente: {cat} (use list_verticals)')
        for f in sorted(os.listdir(d)):
            if not f.endswith('.md') or f == 'README.md':
                continue
            fm = _frontmatter(os.path.join(d, f))
            out.append({'comando': f'/{os.path.basename(d)}:{f[:-3]}',
                        'descricao': (fm.get('description', '') or '')[:200]})
    return {'total': len(out), 'comandos': out}


def describe_command(a):
    ref = a.get('comando', '').strip().lstrip('/')
    if ':' not in ref and '/' not in ref:
        raise ValueError('comando: forma categoria:nome (ex.: engineer:plan)')
    cat, name = re.split('[:/]', ref, 1)
    fp = os.path.join(CMD_DIR, cat, f'{name}.md')
    if not os.path.isfile(fp) or '..' in ref:
        raise ValueError(f'não existe: {ref}')
    return {'comando': f'/{cat}:{name}', 'conteudo': open(fp, encoding='utf-8').read()[:MAX_OUT]}


def list_agents(a):
    cat = a.get('categoria', '').strip()
    out = []
    for root, _, files in os.walk(AG_DIR):
        if cat and os.path.basename(root) != cat:
            continue
        for f in sorted(files):
            if not f.endswith('.md') or f == 'README.md':
                continue
            fm = _frontmatter(os.path.join(root, f))
            if fm.get('name'):
                out.append({'agente': '@' + fm['name'], 'categoria': os.path.basename(root),
                            'descricao': (fm.get('description', '') or '')[:180]})
    return {'total': len(out), 'agentes': out}


def describe_coinage(a):
    """As cunhagens do Onion — busca na KB de identidade/doutrina."""
    termo = a.get('termo', '').strip()
    if len(termo) < 3:
        raise ValueError('termo: a cunhagem (Elenxo, Bulbo, SDAAL, porosidade, KG-SSOT-first...)')
    import subprocess
    r = subprocess.run(['grep', '-rin', '-m', '2', termo,
                        'docs/knowledge-base/concepts/', 'docs/knowledge-base/meta/', '--include=*.md'],
                       capture_output=True, text=True, cwd=REPO, timeout=30)
    return {'termo': termo, 'ocorrencias': r.stdout[:MAX_OUT] or '(não achado no corpus de conceitos/meta)',
            'nota': 'cunhagens são autorais do Onion (declaradas, não literatura); leia a KB citada com o onion-kg/kb_get'}


TOOLS = {
    'list_verticals': (list_verticals, 'Lista as verticais/categorias do framework (produto, engenharia, compliance, design, meta...) e quantos comandos cada uma tem', {}),
    'list_commands': (list_commands, 'Lista comandos (todos, ou de uma categoria) com o que cada um faz', {'categoria': {'type': 'string', 'description': 'opcional: filtrar por vertical'}}),
    'describe_command': (describe_command, 'O conteúdo completo de um comando (categoria:nome, ex. engineer:plan)', {'comando': {'type': 'string', 'description': 'categoria:nome'}}),
    'list_agents': (list_agents, 'Lista os agentes especialistas (todos ou de uma categoria) com sua descrição', {'categoria': {'type': 'string', 'description': 'opcional: filtrar por categoria de agente'}}),
    'describe_coinage': (describe_coinage, 'Explica uma cunhagem do Onion (Elenxo, Bulbo, SDAAL, porosidade epistêmica, KG-SSOT-first) buscando na KB', {'termo': {'type': 'string', 'description': 'a cunhagem'}}),
}
FERRAMENTAS = [
    {'name': n, 'description': d, 'inputSchema': {'type': 'object', 'properties': props,
     'required': [k for k, v in props.items() if 'opcional' not in v.get('description', '')]}}
    for n, (_, d, props) in TOOLS.items()
]


def executa(nome, args):
    if nome not in TOOLS:
        raise ValueError(f'tool desconhecida: {nome}')
    return TOOLS[nome][0](args)


class Handler(BaseHTTPRequestHandler):
    def log_message(self, *a):  # noqa: N802
        pass

    def _json(self, obj, code=200):
        b = json.dumps(obj, ensure_ascii=False).encode()
        self.send_response(code); self.send_header('Content-Type', 'application/json')
        self.send_header('Content-Length', str(len(b))); self.end_headers(); self.wfile.write(b)

    def _auth(self):
        return hmac.compare_digest(self.headers.get('X-Api-Key', ''), TOKEN)

    def do_GET(self):  # noqa: N802
        if self.path == '/health':
            return self._json({'status': 'UP', 'tools': len(FERRAMENTAS), 'eixo': 'identidade'})
        return self._json({'error': 'not found'}, 404)

    def do_POST(self):  # noqa: N802
        if not self._auth():
            return self._json({'jsonrpc': '2.0', 'id': None, 'error': {'code': -32000, 'message': 'unauthorized'}}, 401)
        try:
            req = json.loads(self.rfile.read(int(self.headers.get('Content-Length', 0)) or 0) or b'{}')
        except json.JSONDecodeError:
            return self._json({'jsonrpc': '2.0', 'id': None, 'error': {'code': -32700, 'message': 'parse error'}}, 400)
        rid, metodo, params = req.get('id'), req.get('method', ''), req.get('params', {})
        if rid is None:
            self.send_response(202); self.send_header('Content-Length', '0'); self.end_headers(); return
        if metodo == 'initialize':
            return self._json({'jsonrpc': '2.0', 'id': rid, 'result': {
                'protocolVersion': params.get('protocolVersion', '2025-03-26'),
                'capabilities': {'tools': {}},
                'serverInfo': {'name': 'onion-framework', 'version': '0.1.0',
                               'title': 'Onion Framework — identidade: verticais, comandos, agentes, cunhagens'}}})
        if metodo == 'tools/list':
            return self._json({'jsonrpc': '2.0', 'id': rid, 'result': {'tools': FERRAMENTAS}})
        if metodo == 'tools/call':
            try:
                r = executa(params.get('name', ''), params.get('arguments') or {})
                return self._json({'jsonrpc': '2.0', 'id': rid, 'result': {
                    'content': [{'type': 'text', 'text': json.dumps(r, ensure_ascii=False, indent=1)}], 'isError': False}})
            except Exception as e:  # noqa: BLE001
                return self._json({'jsonrpc': '2.0', 'id': rid, 'result': {
                    'content': [{'type': 'text', 'text': f'erro: {e}'}], 'isError': True}})
        if metodo == 'ping':
            return self._json({'jsonrpc': '2.0', 'id': rid, 'result': {}})
        return self._json({'jsonrpc': '2.0', 'id': rid, 'error': {'code': -32601, 'message': f'metodo: {metodo}'}})


if __name__ == '__main__':
    print(f'onion-framework (MCP) em http://{HOST}:{PORT}/mcp — {len(FERRAMENTAS)} tools (identidade)')
    ThreadingHTTPServer((HOST, PORT), Handler).serve_forever()
