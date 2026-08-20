#!/usr/bin/env python3
"""onion-exec — a Camada 1 do Bridge-como-MCP: EXECUÇÃO com ALLOWLIST (F6.5).

Filosofia (decisão do maestro 2026-08-20): tools NOMEADAS E FIXAS, zero prompt arbitrário.
Cada tool é um comando auditável. O write-leg (propose_kg_write) grava numa FILA de propostas
que o core sela — NUNCA no grafo vivo (I3, um escritor por repo; spec F4b).

A Camada 2 (bridge_task, prompt livre) NÃO vive aqui — é atrás de ACL do LibreChat, gated, e
só nasce quando houver consumidor nomeado. Este server é read+exec-contido: seguro por default.

Molde: onion-kg/server.py (stdlib, streamable-http, auth X-Api-Key). Roda como marcio no core.
Uso: ONION_EXEC_TOKEN=... python3 ops/mcp-onion-exec/server.py  (bind 172.23.0.1:3034)
"""
import hmac
import json
import os
import re
import subprocess
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
HOST = os.environ.get('MCP_HOST', '172.23.0.1')
PORT = int(os.environ.get('MCP_PORT', '3034'))
TOKEN = os.environ.get('ONION_EXEC_TOKEN', '')
if not TOKEN:
    raise SystemExit('ONION_EXEC_TOKEN ausente — fail-closed')
MAX_OUT = 60_000
INBOX = os.path.join(REPO, 'docs/evolution/kg-inbox')


def _run(cmd, timeout=300):
    r = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout, cwd=REPO)
    body = (r.stdout or '') + (('\n[stderr]\n' + r.stderr) if r.stderr else '')
    return {'exit_code': r.returncode, 'output': body[:MAX_OUT]}


# ── Camada 1: comandos FIXOS (allowlist), zero argumento livre de shell ──────────
def run_lint(_a):
    return {'comando': 'lint-artifacts.sh', **_run(['bash', '.claude/validation/lint-artifacts.sh'])}


def run_inventory(_a):
    # --markdown NÃO grava; só emite. (o /meta:inventory que grava é sessão do core)
    return {'comando': 'inventory.sh --markdown', **_run(['bash', '.claude/validation/inventory.sh', '--markdown'])}


def kg_freshness(a):
    g = a.get('grafo', '')
    if not g or '..' in g or not g.endswith('.kg.yaml'):
        raise ValueError('grafo: caminho relativo de um .kg.yaml (use o onion-kg/kg_list)')
    # --freshness-tsv: só LÊ e ordena; não escreve
    return {'comando': f'kg-radar --freshness {g}', **_run(['bash', '.claude/validation/kg-radar.sh', g, '--freshness-tsv'])}


_SLUG = re.compile(r'^[a-z0-9][a-z0-9-]{1,48}$')


def propose_kg_write(a):
    """Write-leg da F4b: grava PROPOSTA na fila. NUNCA no grafo vivo. O core sela."""
    slug = a.get('slug', '')
    yaml_body = a.get('kg_yaml', '')
    origem = a.get('origem', 'librechat-agent')
    if not _SLUG.match(slug):
        raise ValueError('slug: kebab-case [a-z0-9-], 2-49 chars')
    if not yaml_body or 'nodes:' not in yaml_body:
        raise ValueError('kg_yaml: corpo .kg.yaml com ao menos nodes:')
    if len(yaml_body) > 200_000:
        raise ValueError('kg_yaml grande demais (>200KB)')
    ts = time.strftime('%Y%m%d-%H%M%S')
    fname = f'{slug}-{ts}.proposal.kg.yaml'
    fpath = os.path.join(INBOX, fname)
    header = (f'# PROPOSTA de escrita no grafo — fila kg-inbox (write-leg F4b).\n'
              f'# origem: {origem} · recebida: {ts} · NÃO É FONTE até o core selar (I3).\n')
    with open(fpath, 'w', encoding='utf-8') as f:
        f.write(header + yaml_body)
    radar = _run(['bash', '.claude/validation/kg-radar.sh', f'docs/evolution/kg-inbox/{fname}'])
    return {'status': 'proposta recebida', 'arquivo': f'docs/evolution/kg-inbox/{fname}',
            'radar_advisory': radar,
            'nota': 'PROPOSTA na fila — o core revisa e sela (radar aqui é advisory, não gate). '
                    'Isto NÃO alterou o grafo vivo: um escritor por repo (I3).'}


TOOLS = {
    'run_lint': (run_lint, 'Roda o lint determinístico do core (lint-artifacts.sh) e devolve o veredito HARD/SOFT', {}),
    'run_inventory': (run_inventory, 'Emite o inventário canônico (comandos/agentes/skills/KBs) do filesystem — NÃO grava', {}),
    'kg_freshness': (kg_freshness, 'Fila de frescor de um grafo (nós por atenção a re-verificar) — leitura, não muta', {'grafo': {'type': 'string', 'description': 'caminho .kg.yaml'}}),
    'propose_kg_write': (propose_kg_write, 'PROPÕE um nó/grafo na fila kg-inbox (o core sela; NUNCA escreve o grafo vivo — I3)', {
        'slug': {'type': 'string', 'description': 'kebab-case identificando a proposta'},
        'kg_yaml': {'type': 'string', 'description': 'corpo .kg.yaml da proposta (com nodes:)'},
        'origem': {'type': 'string', 'description': 'quem propõe (opcional)'}}),
}
FERRAMENTAS = [
    {'name': n, 'description': d,
     'inputSchema': {'type': 'object', 'properties': props, 'required': [k for k, v in props.items()]}}
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
        self.send_response(code)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Content-Length', str(len(b)))
        self.end_headers()
        self.wfile.write(b)

    def _auth(self):
        return hmac.compare_digest(self.headers.get('X-Api-Key', ''), TOKEN)

    def do_GET(self):  # noqa: N802
        if self.path == '/health':
            return self._json({'status': 'UP', 'tools': len(FERRAMENTAS), 'layer': 'exec-allowlist'})
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
                'serverInfo': {'name': 'onion-exec', 'version': '0.1.0',
                               'title': 'Onion Exec — Camada 1 (allowlist): lint, inventory, freshness, propose_kg_write'}}})
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
    print(f'onion-exec (MCP) em http://{HOST}:{PORT}/mcp — {len(FERRAMENTAS)} tools (Camada 1)')
    ThreadingHTTPServer((HOST, PORT), Handler).serve_forever()
