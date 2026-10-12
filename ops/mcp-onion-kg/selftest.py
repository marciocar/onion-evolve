#!/usr/bin/env python3
"""selftest.py — dogfood do onion-kg por HTTP de verdade (consumido pela família mcp_onion_kg).

Sobe o servidor em 127.0.0.1 numa porta EFÊMERA (MCP_PORT=0), com token de teste, contra uma
raiz-fixture em mktemp (um clone com worktree DESTACADO), chama cada tool por JSON-RPC MCP e
encerra SÓ os processos que ele mesmo subiu (pelo handle do Popen, nunca pkill).

Saída: uma linha por caso, `PASS <caso>` ou `FAIL <caso> :: <detalhe>`, e no fim `TOTAL <n>`.
rc 0 só se todos passaram. Uso: python3 -I ops/mcp-onion-kg/selftest.py [--server <server.py>]
"""
import json
import os
import shutil
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.request

HERE = os.path.dirname(os.path.realpath(__file__))
SERVER = os.path.join(HERE, 'server.py')
if '--server' in sys.argv:
    SERVER = os.path.realpath(sys.argv[sys.argv.index('--server') + 1])
SERVER_REPO = os.path.dirname(os.path.dirname(os.path.dirname(SERVER)))
# --mutate ANTIGO NOVO: roda os casos contra uma CÓPIA do servidor com UMA substituição literal,
# numa árvore temporária (nunca muta o arquivo vivo). ANTIGO tem de ocorrer exatamente 1 vez:
# mutante que não aplica sairia "verde" e provaria nada.
MUTATE = None
if '--mutate' in sys.argv:
    _i = sys.argv.index('--mutate')
    MUTATE = (sys.argv[_i + 1], sys.argv[_i + 2])
TOKEN = 'selftest-token-nao-secreto'
RESULTS = []
T0 = time.time()
PROCS = []


def case(name, ok, detail=''):
    RESULTS.append((name, bool(ok)))
    print(f'PASS {name}' if ok else f'FAIL {name} :: {str(detail)[:300]}', flush=True)


def git(cwd, *args):
    r = subprocess.run(['git', '-c', 'user.email=selftest@onion', '-c', 'user.name=selftest',
                        '-c', 'commit.gpgsign=false', *args], cwd=cwd, capture_output=True, text=True)
    if r.returncode != 0:
        raise RuntimeError(f'git {args}: {r.stderr.strip()}')
    return r.stdout.strip()


def write(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w', encoding='utf-8') as fh:
        fh.write(text)


GRAPH = '''meta:
  id: selftest-mcp
  schema_version: "1"
  baseline: "2026-10-01"

nodes:
  - id: Q_ABERTA
    node_type: question
    plane: DEV
    status: open
    impact: 3
    confidence: 1.0
    label: "pergunta aberta da fixture"

  - id: C_FIRME
    node_type: claim
    plane: DEV
    status: confirmed
    impact: 4
    confidence: 0.9
    verified_at: "2026-10-02"
    verified_against: "fixture do selftest"
    label: "afirmacao confirmada da fixture"

edges:
  - from: C_FIRME
    to: Q_ABERTA
    edge_type: SUPPORTS
'''


def build_fixture(base):
    clone = os.path.join(base, 'clone')
    write(os.path.join(clone, 'docs/knowledge-base/a.md'), 'linha foo simples\n')
    write(os.path.join(clone, 'docs/knowledge-base/b.md'), 'marca -efoo aqui\nopcao --version literal\n')
    write(os.path.join(clone, 'docs/x.kg.yaml'), GRAPH)
    write(os.path.join(clone, '.claude/diary/index.md'), '# indice da fixture\n')
    write(os.path.join(clone, 'docs/onion/inventory.md'), '# inventario da fixture\n')
    write(os.path.join(base, 'fora/segredo.md'), 'SEGREDO-FORA-DA-RAIZ\n')
    write(os.path.join(base, 'fora/alheio.kg.yaml'), GRAPH)
    os.symlink(os.path.join(base, 'fora/segredo.md'), os.path.join(clone, 'docs/knowledge-base/vaza.md'))
    git(base, 'init', '-q', clone)
    git(clone, 'add', '-A')
    git(clone, 'commit', '-qm', 'fixture')
    wt = os.path.join(base, 'wt')
    git(clone, 'worktree', 'add', '-q', '--detach', wt, 'HEAD')
    return clone, wt


def start(env_extra, drop=()):
    env = {k: v for k, v in os.environ.items() if k not in ('ONION_KG_ROOT', 'ONION_KG_TOKEN')}
    env.update({'MCP_HOST': '127.0.0.1', 'MCP_PORT': '0', 'ONION_KG_TOKEN': TOKEN})
    env.update(env_extra)
    for k in drop:
        env.pop(k, None)
    p = subprocess.Popen([sys.executable, '-I', SERVER], env=env, stdout=subprocess.PIPE,
                         stderr=subprocess.PIPE, text=True)
    PROCS.append(p)
    return p


def wait_port(p, timeout=15):
    t0 = time.time()
    line = ''
    while time.time() - t0 < timeout:
        if p.poll() is not None:
            return None, p.stderr.read()
        line = p.stdout.readline()
        if 'http://127.0.0.1:' in line:
            return int(line.split('http://127.0.0.1:')[1].split('/')[0]), line
    return None, line


def rpc(port, method, params=None, key=TOKEN, rid=1):
    body = json.dumps({'jsonrpc': '2.0', 'id': rid, 'method': method, 'params': params or {}}).encode()
    req = urllib.request.Request(f'http://127.0.0.1:{port}/mcp', data=body, method='POST',
                                 headers={'Content-Type': 'application/json',
                                          **({'X-Api-Key': key} if key is not None else {})})
    try:
        with urllib.request.urlopen(req, timeout=60) as r:
            return r.status, json.loads(r.read())
    except urllib.error.HTTPError as e:
        return e.code, json.loads(e.read() or b'{}')
    except (OSError, ValueError) as e:  # conexão derrubada sem resposta = caso reprova, harness segue
        return 0, {'_erro_transporte': str(e)}


def call(port, tool, args=None):
    code, resp = rpc(port, 'tools/call', {'name': tool, 'arguments': args or {}})
    res = resp.get('result', {})
    try:
        payload = json.loads(res['content'][0]['text'])
    except (KeyError, IndexError, ValueError):
        payload = {'_raw': res}
    return code, bool(res.get('isError')), payload


def wait_exit(p, timeout=8):
    """rc do processo que DEVERIA recusar subir; se ele subiu (não saiu no prazo), mata e devolve None."""
    try:
        return p.wait(timeout=timeout)
    except subprocess.TimeoutExpired:
        p.terminate()
        p.wait(timeout=5)
        return None


def stop_all():
    for p in PROCS:
        if p.poll() is None:
            p.terminate()
            try:
                p.wait(timeout=5)
            except subprocess.TimeoutExpired:
                p.kill()
                p.wait(timeout=5)


def mutant_tree(base):
    """Copia o servidor para <base>/tree (um repo git) com a substituição; o radar vem do repo real."""
    global SERVER, SERVER_REPO
    old, new = MUTATE
    with open(SERVER, encoding='utf-8') as fh:
        src = fh.read()
    if src.count(old) != 1:
        raise SystemExit(f'MUTANTE-NAO-APLICOU: ANTIGO ocorre {src.count(old)}x (precisa 1): {old[:120]}')
    tree = os.path.join(base, 'tree')
    write(os.path.join(tree, 'ops/mcp-onion-kg/server.py'), src.replace(old, new))
    os.makedirs(os.path.join(tree, '.claude'))
    os.symlink(os.path.join(SERVER_REPO, '.claude', 'validation'), os.path.join(tree, '.claude', 'validation'))
    git(base, 'init', '-q', tree)
    git(tree, 'add', '-A')
    git(tree, 'commit', '-qm', 'mutante')
    SERVER = os.path.join(tree, 'ops/mcp-onion-kg/server.py')
    SERVER_REPO = tree


def main():
    base = tempfile.mkdtemp(prefix='mcp-onion-kg-selftest-')
    try:
        if MUTATE:
            mutant_tree(base)
        clone, wt = build_fixture(base)
        head = git(wt, 'rev-parse', 'HEAD')

        # (1) fail-closed do token: sem ONION_KG_TOKEN não sobe
        p = start({'ONION_KG_ROOT': wt}, drop=('ONION_KG_TOKEN',))
        rc = wait_exit(p)
        err = p.stderr.read()
        case('token-fail-closed', rc not in (0, None) and 'fail-closed' in err, f'rc={rc} err={err}')

        # (2) raiz que não é repo git legível: recusa no boot
        naorepo = os.path.join(base, 'fora')
        p = start({'ONION_KG_ROOT': naorepo})
        rc = wait_exit(p)
        err = p.stderr.read()
        case('raiz-invalida-recusa-no-boot', rc not in (0, None) and 'recuso subir' in err, f'rc={rc} err={err}')

        # (2b) subdiretório de um repo não é raiz: o git subiria até o pai e declararia o commit dele
        p = start({'ONION_KG_ROOT': os.path.join(wt, 'docs')})
        rc = wait_exit(p)
        err = p.stderr.read()
        case('raiz-subdiretorio-recusa', rc not in (0, None) and 'topo' in err, f'rc={rc} err={err}')

        # (3) sobe contra o worktree destacado
        p = start({'ONION_KG_ROOT': wt})
        port, line = wait_port(p)
        case('sobe-em-porta-efemera', port is not None, line)
        if port is None:
            return

        code, _ = rpc(port, 'tools/list', key=None)
        case('sem-token-401', code == 401, code)
        code, _ = rpc(port, 'tools/list', key='errado')
        case('token-errado-401', code == 401, code)

        code, resp = rpc(port, 'tools/list')
        names = [t['name'] for t in resp.get('result', {}).get('tools', [])]
        case('tools-list-tem-kg_node', 'kg_node' in names and len(names) == 7, names)

        code, err_, pl = call(port, 'kg_list')
        case('envelope-nao-confiavel', pl.get('untrusted_data') is True and 'DADO' in pl.get('aviso', ''), pl)
        case('frescor-served_commit', pl.get('served_commit') == head, f"{pl.get('served_commit')} != {head}")
        case('frescor-fetched_at-null-sem-fetch', 'fetched_at' in pl and pl['fetched_at'] is None, pl.get('fetched_at'))
        case('raiz-por-env', pl.get('root_source', '').startswith('env')
             and pl.get('data', {}).get('grafos') == ['docs/x.kg.yaml'], pl)

        # (4) injeção de opção no grep: o termo é PADRÃO, nunca flag
        _, e1, pl = call(port, 'kb_search', {'termo': '-efoo'})
        res = pl.get('data', {}).get('resultado', '')
        case('kb_search-termo-com-hifen-e-padrao', not e1 and 'b.md' in res and 'a.md' not in res, res)
        _, e2, pl = call(port, 'kb_search', {'termo': '--version'})
        res = pl.get('data', {}).get('resultado', '')
        case('kb_search-version-nao-vira-flag', not e2 and 'b.md' in res and 'GNU' not in res, res)

        # (5) confinamento na raiz: absoluto e symlink que escapa são recusados
        _, e3, pl = call(port, 'kg_radar', {'grafo': os.path.join(base, 'fora/alheio.kg.yaml')})
        case('kg_radar-absoluto-recusado', e3 and 'served_commit' in pl, pl)
        _, e4, pl = call(port, 'kb_get', {'arquivo': 'docs/knowledge-base/vaza.md'})
        case('kb_get-symlink-para-fora-recusado', e4 and 'SEGREDO' not in json.dumps(pl), pl)
        _, e5, pl = call(port, 'kg_radar', {'grafo': 'docs/x.kg.yaml'})
        case('kg_radar-ok', not e5 and pl.get('data', {}).get('radar_rc') == 0
             and pl.get('served_commit') == head, pl)

        # (6) kg_node pelo parser do radar
        _, e6, pl = call(port, 'kg_node', {'grafo': 'docs/x.kg.yaml', 'id': 'Q_ABERTA'})
        d = pl.get('data', {})
        case('kg_node-existente', not e6 and d.get('status') == 'open'
             and d.get('label') == 'pergunta aberta da fixture'
             and d.get('arestas_entrando') == ['C_FIRME SUPPORTS Q_ABERTA'], pl)
        _, e7, pl = call(port, 'kg_node', {'grafo': 'docs/x.kg.yaml', 'id': 'NAO_EXISTE'})
        case('kg_node-inexistente-erro', e7 and 'inexistente' in pl.get('erro', '')
             and pl.get('served_commit') == head, pl)
        # nó vivo rastreado: as colunas do --freshness-tsv chegam cada uma no campo certo
        _, e9, pl = call(port, 'kg_node', {'grafo': 'docs/x.kg.yaml', 'id': 'C_FIRME'})
        d = pl.get('data', {})
        case('kg_node-vivo-rastreado', not e9 and d.get('node_type') == 'claim' and d.get('plane') == 'DEV'
             and d.get('impact') == '4' and d.get('confidence') == '0.9'
             and d.get('verified_at') == '2026-10-02' and d.get('verified_against') == 'fixture do selftest'
             and d.get('veredito_frescor') == 'OK' and d.get('arestas_saindo') == ['C_FIRME SUPPORTS Q_ABERTA'], d)

        # (6b) o grep do kb_search NÃO segue o symlink que aponta para fora da raiz (-r, não -R)
        _, e10, pl = call(port, 'kb_search', {'termo': 'SEGREDO'})
        case('kb_search-symlink-para-fora-nao-aparece', not e10 and 'SEGREDO-FORA' not in json.dumps(pl)
             and pl.get('data', {}).get('ocorrencias') == 0, pl)

        # (6c) só arquivo VERSIONADO fala pelo served_commit; árvore suja é declarada
        case('arvore-limpa-declarada', pl.get('arvore_limpa') is True, pl.get('arvore_limpa'))
        write(os.path.join(wt, 'docs/nv.kg.yaml'), GRAPH)
        write(os.path.join(wt, 'docs/knowledge-base/nv.md'), 'nao versionado\n')
        try:
            _, e11, pl = call(port, 'kg_radar', {'grafo': 'docs/nv.kg.yaml'})
            case('kg_radar-nao-versionado-recusado', e11 and 'versionado' in pl.get('erro', ''), pl)
            _, e12, pl = call(port, 'kb_get', {'arquivo': 'docs/knowledge-base/nv.md'})
            case('kb_get-nao-versionado-recusado', e12 and 'versionado' in pl.get('erro', ''), pl)
            _, _, pl = call(port, 'kg_list')
            case('arvore-suja-declarada', pl.get('arvore_limpa') is False, pl.get('arvore_limpa'))
        finally:
            os.remove(os.path.join(wt, 'docs/nv.kg.yaml'))
            os.remove(os.path.join(wt, 'docs/knowledge-base/nv.md'))

        # (6d) corpo malformado: Content-Length negativo e params que não é objeto respondem 400 na hora
        import socket
        s = socket.create_connection(('127.0.0.1', port), timeout=5)
        try:
            s.sendall(f'POST /mcp HTTP/1.1\r\nHost: x\r\nX-Api-Key: {TOKEN}\r\n'
                      'Content-Length: -1\r\n\r\n'.encode())
            first = s.recv(200).decode(errors='replace')
        except OSError as e:
            first = f'erro: {e}'
        finally:
            s.close()
        case('content-length-negativo-400', ' 400 ' in first.split('\r\n')[0], first[:80])
        code, resp = rpc(port, 'tools/call', [1])
        case('params-nao-objeto-400', code == 400 and resp.get('error', {}).get('code') == -32602, resp)

        # (7) frescor acompanha o fetch (feito no clone, como no runbook)
        git(clone, 'fetch', '-q', clone)
        _, _, pl = call(port, 'kg_list')
        case('frescor-fetched_at-apos-fetch', isinstance(pl.get('fetched_at'), str)
             and pl['fetched_at'].endswith('Z'), pl.get('fetched_at'))

        # (8) raiz deixa de ser repo legível em runtime: recusa sem dado
        dotgit = os.path.join(wt, '.git')
        os.rename(dotgit, dotgit + '.off')
        try:
            _, e8, pl = call(port, 'kg_list')
            case('raiz-invalida-em-runtime-recusa', e8 and pl.get('served_commit') is None
                 and 'recusa' in pl and 'data' not in pl, pl)
        finally:
            os.rename(dotgit + '.off', dotgit)

        # (9) sem ONION_KG_ROOT: raiz = repo do servidor, declarado
        p2 = start({}, drop=('ONION_KG_ROOT',))
        port2, line2 = wait_port(p2)
        if port2 is None:
            case('raiz-default-declarada', False, line2)
        else:
            _, _, pl = call(port2, 'kg_list')
            rc_head = subprocess.run(['git', '-C', SERVER_REPO, 'rev-parse', 'HEAD'],
                                     capture_output=True, text=True).stdout.strip()
            case('raiz-default-declarada', pl.get('root_source', '').startswith('default')
                 and pl.get('served_commit') == rc_head, pl.get('root_source'))
    finally:
        stop_all()
        shutil.rmtree(base, ignore_errors=True)
    print(f'TOTAL {len(RESULTS)} ({time.time() - T0:.1f}s)', flush=True)


if __name__ == '__main__':
    try:
        main()
    finally:
        stop_all()
    sys.exit(0 if RESULTS and all(ok for _, ok in RESULTS) else 1)
