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
import re
import shutil
import socket
import stat
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.request
from datetime import datetime, timedelta, timezone

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
    env = {k: v for k, v in os.environ.items()
           if k not in ('ONION_KG_ROOT', 'ONION_KG_TOKEN', 'ONION_KG_USAGE_DIR')}
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


USAGE_FILE = 'tool-usage.tsv'
REGISTERED = ('kg_list', 'kg_radar', 'kg_node', 'kb_search', 'kb_get', 'diary_index', 'inventory')
USAGE_STRICT_RE = re.compile(r'^(\d{4}-\d{2}-\d{2})\t(' + '|'.join(REGISTERED) + r'|unknown)\t\d+\t\d+$')
S_TOOL = 'SENTINELA-FERRAMENTA-7731'
S_TERM = 'SENTINELATERMO4417'
S_NODE = 'SENTINELA_NO_5521'
S_EMAIL = 'sentinela-pessoa-9093@exemplo.com'


def call_sync(port, tool, args=None, headers=None):
    """tools/call por socket cru, lendo até o EOF. O servidor só fecha a conexão depois de o handler
    terminar, então ao voltar daqui a contagem daquela chamada já foi gravada (sem espera por tempo)."""
    body = json.dumps({'jsonrpc': '2.0', 'id': 1, 'method': 'tools/call',
                       'params': {'name': tool, 'arguments': args or {}}}).encode()
    hdr = {'Host': 'x', 'Content-Type': 'application/json', 'X-Api-Key': TOKEN,
           'Content-Length': str(len(body))}
    hdr.update(headers or {})
    raw = b''
    try:
        s = socket.create_connection(('127.0.0.1', port), timeout=60)
        try:
            s.sendall(('POST /mcp HTTP/1.1\r\n' + ''.join(f'{k}: {v}\r\n' for k, v in hdr.items())
                       + '\r\n').encode() + body)
            while True:
                chunk = s.recv(65536)
                if not chunk:
                    break
                raw += chunk
        finally:
            s.close()
        res = json.loads(raw.split(b'\r\n\r\n', 1)[1]).get('result', {})
        return bool(res.get('isError')), json.loads(res['content'][0]['text'])
    except (OSError, ValueError, KeyError, IndexError) as e:
        return None, {'_erro': str(e), '_raw': raw[:200].decode(errors='replace')}


def usage_read(path):
    """(texto, {ferramenta: [ok, erro]}) lido de forma TOLERANTE: o harness não confia no formato."""
    try:
        with open(path, encoding='utf-8', errors='replace') as fh:
            text = fh.read()
    except OSError as e:
        return f'<<sem arquivo: {e}>>', {}
    rows = {}
    for ln in text.splitlines():
        c = ln.split('\t')
        if len(c) == 4 and c[2].isdigit() and c[3].isdigit():
            r = rows.setdefault(c[1], [0, 0])
            r[0] += int(c[2])
            r[1] += int(c[3])
    return text, rows


def mode_of(path):
    try:
        return stat.S_IMODE(os.stat(path).st_mode)
    except OSError:
        return None


def stop_and_drain(p):
    """SIGTERM no processo que o harness subiu; devolve (rc, resto do stdout)."""
    p.terminate()
    try:
        rc = p.wait(timeout=10)
    except subprocess.TimeoutExpired:
        p.kill()
        rc = p.wait(timeout=5)
    return rc, p.stdout.read()


def usage_cases(base, wt):
    """Contador de uso: só dia × ferramenta × ok|erro; nada de identidade, argumento ou nome de grafo."""
    os.umask(0o022)  # umask conhecida: o modo 600 tem de vir do servidor, não da umask de quem roda
    all_names = [
        'usage-boot-desligado-sem-env', 'usage-boot-ligado', 'usage-arquivo-modo-600', 'usage-ok-conta-em-ok',
        'usage-erro-conta-em-erro', 'usage-desconhecida-vira-unknown', 'usage-arquivo-sem-argumento',
        'usage-arquivo-sem-nome-de-grafo', 'usage-arquivo-sem-email', 'usage-arquivo-sem-token',
        'usage-arquivo-sem-ip', 'usage-arquivo-so-formato', 'usage-resposta-inalterada',
        'usage-leitura-por-flag', 'usage-linha-de-saida', 'usage-dir-nao-gravavel-desliga',
        'usage-dentro-da-raiz-desliga', 'usage-falha-em-runtime-contada', 'usage-poda-400-dias',
        'usage-concorrencia-nao-perde']
    done = set()

    def ucase(name, ok, detail=''):
        done.add(name)
        case(name, ok, detail)

    try:
        # (u1) sem a env: desligado, declarado no boot, e a chamada responde
        p = start({'ONION_KG_ROOT': wt})
        port, _ = wait_port(p)
        line = p.stdout.readline() if port else ''
        e, pl = call_sync(port, 'kg_list') if port else (None, {})
        ucase('usage-boot-desligado-sem-env', 'DESLIGADO (ONION_KG_USAGE_DIR ausente)' in line and e is False, line)
        baseline = pl

        # (u2) ligado: diretório criado pelo servidor
        udir = os.path.join(base, 'uso', 'dados')
        ufile = os.path.join(udir, USAGE_FILE)
        p = start({'ONION_KG_ROOT': wt, 'ONION_KG_USAGE_DIR': udir})
        port, _ = wait_port(p)
        if port is None:
            return
        line = p.stdout.readline()
        ucase('usage-boot-ligado', f'contador de uso LIGADO em {os.path.realpath(ufile)}' in line
              and 'falhas do contador: 0' in line, line)
        snaps = []

        def do(tool, args=None):
            r = call_sync(port, tool, args, {'X-User-Email': S_EMAIL})
            snaps.append(usage_read(ufile)[0])
            return r

        e_ok, pl_ok = do('kg_list')
        _, rows = usage_read(ufile)
        ucase('usage-ok-conta-em-ok', e_ok is False and rows.get('kg_list') == [1, 0], rows)
        ucase('usage-resposta-inalterada', pl_ok == baseline and 'data' in pl_ok, pl_ok)
        ucase('usage-arquivo-modo-600', mode_of(ufile) == 0o600 and mode_of(udir) == 0o700
              and mode_of(ufile + '.lock') == 0o600
              and sorted(os.listdir(udir)) == [USAGE_FILE, USAGE_FILE + '.lock'],
              f'arquivo={mode_of(ufile)} dir={mode_of(udir)} ls={os.listdir(udir)}')
        e_err, _ = do('kg_node', {'grafo': 'docs/x.kg.yaml', 'id': S_NODE})
        _, rows = usage_read(ufile)
        ucase('usage-erro-conta-em-erro', e_err is True and rows.get('kg_node') == [0, 1], rows)
        e_unk, _ = do(S_TOOL, {'x': 1})
        text, rows = usage_read(ufile)
        ucase('usage-desconhecida-vira-unknown', e_unk is True and rows.get('unknown') == [0, 1]
              and S_TOOL not in text, text)
        do('kb_search', {'termo': S_TERM})
        do('kg_radar', {'grafo': 'docs/x.kg.yaml'})
        do(['nome', 'que', 'nao', 'e', 'texto'])
        seen = '\n'.join(snaps)
        ucase('usage-arquivo-sem-argumento', S_TERM not in seen and S_NODE not in seen and len(snaps) == 6, seen)
        ucase('usage-arquivo-sem-nome-de-grafo', 'x.kg.yaml' not in seen and 'docs/' not in seen, seen)
        ucase('usage-arquivo-sem-email', S_EMAIL not in seen and '@' not in seen, seen)
        ucase('usage-arquivo-sem-token', TOKEN not in seen, seen)
        ucase('usage-arquivo-sem-ip', '127.0.0.1' not in seen, seen)
        now = datetime.now(timezone.utc)
        dias = {(now + timedelta(days=d)).strftime('%Y-%m-%d') for d in (-1, 0)}
        linhas = [ln for s_ in snaps for ln in s_.splitlines()]
        ucase('usage-arquivo-so-formato', linhas and all(
            USAGE_STRICT_RE.match(ln) and ln.split('\t')[0] in dias for ln in linhas), seen)

        # (u3) leitura pela flag: não sobe servidor, não pede token
        env = {k: v for k, v in os.environ.items() if not k.startswith('ONION_KG_')}
        r1 = subprocess.run([sys.executable, '-I', '-B', SERVER, '--usage'], capture_output=True, text=True,
                            env={**env, 'ONION_KG_USAGE_DIR': udir}, timeout=30)
        r2 = subprocess.run([sys.executable, '-I', '-B', SERVER, '--usage', '--days', '2'], capture_output=True,
                            text=True, env={**env, 'ONION_KG_USAGE_DIR': udir}, timeout=30)
        r3 = subprocess.run([sys.executable, '-I', '-B', SERVER, '--usage'], capture_output=True, text=True,
                            env=env, timeout=30)
        ucase('usage-leitura-por-flag', r1.returncode == 0 and 'kg_list\t1\t0\t1\t1\n' in r1.stdout
              and 'kg_node\t0\t1\t1\t1\n' in r1.stdout and 'unknown\t0\t2\t2\t1\n' in r1.stdout
              and 'inventory\t0\t0\t0\t0\n' in r1.stdout and 'TOTAL\t3\t3\t6\t1\n' in r1.stdout
              and r2.returncode == 0 and 'TOTAL\t3\t3\t6\t1\n' in r2.stdout
              and r3.returncode == 1 and 'desligado' in r3.stderr,
              f'rc={r1.returncode},{r2.returncode},{r3.returncode} out={r1.stdout} err={r1.stderr}{r3.stderr}')

        # (u4) linha de saída no SIGTERM, com o status de saída preservado
        rc, rest = stop_and_drain(p)
        ucase('usage-linha-de-saida', rc == -15 and 'onion-kg uso (saida): contador de uso LIGADO' in rest
              and 'falhas do contador: 0' in rest, f'rc={rc} {rest}')

        # (u5) diretório não gravável (o pai é um ARQUIVO: vale também para root): desligado, chamada responde
        p = start({'ONION_KG_ROOT': wt, 'ONION_KG_USAGE_DIR': os.path.join(base, 'fora', 'segredo.md', 'sub')})
        port, _ = wait_port(p)
        line = p.stdout.readline() if port else ''
        e, pl = call_sync(port, 'kg_list') if port else (None, {})
        ucase('usage-dir-nao-gravavel-desliga', 'DESLIGADO (diretorio nao gravavel' in line and e is False
              and pl == baseline, f'{line} {e}')

        # (u6) diretório dentro da raiz servida: desligado, nada é criado lá (a árvore segue limpa)
        inside = os.path.join(wt, 'uso-dentro')
        p = start({'ONION_KG_ROOT': wt, 'ONION_KG_USAGE_DIR': inside})
        port, _ = wait_port(p)
        line = p.stdout.readline() if port else ''
        e, pl = call_sync(port, 'kg_list') if port else (None, {})
        existed = os.path.exists(inside)
        shutil.rmtree(inside, ignore_errors=True)
        ucase('usage-dentro-da-raiz-desliga', 'DESLIGADO (diretorio dentro da raiz servida)' in line
              and not existed and e is False and pl.get('arvore_limpa') is True, f'{line} existia={existed}')

        # (u7) o diretório some em runtime: a chamada responde igual e a falha é contada em memória
        rdir = os.path.join(base, 'uso-runtime')
        p = start({'ONION_KG_ROOT': wt, 'ONION_KG_USAGE_DIR': rdir})
        port, _ = wait_port(p)
        line = p.stdout.readline() if port else ''
        if port and 'LIGADO em' in line:
            os.rename(rdir, rdir + '.off')
            write(rdir, 'um arquivo no lugar do diretorio\n')
            e, pl = call_sync(port, 'kg_list')
            rc, rest = stop_and_drain(p)
            ucase('usage-falha-em-runtime-contada', e is False and pl == baseline
                  and 'falhas do contador: 1' in rest, f'e={e} {rest}')
        else:
            ucase('usage-falha-em-runtime-contada', False, line)

        # (u8) poda: 405 dias semeados (e uma linha fora do formato) viram 400 no boot
        pdir = os.path.join(base, 'uso-poda')
        os.makedirs(pdir, mode=0o700)
        d0 = datetime(2020, 1, 1)
        seed = ''.join(f'{(d0 + timedelta(days=i)).strftime("%Y-%m-%d")}\tkg_list\t1\t0\n' for i in range(405))
        write(os.path.join(pdir, USAGE_FILE), seed + 'linha fora do formato\n')
        p = start({'ONION_KG_ROOT': wt, 'ONION_KG_USAGE_DIR': pdir})
        port, _ = wait_port(p)
        line = p.stdout.readline() if port else ''
        text, rows = usage_read(os.path.join(pdir, USAGE_FILE))
        kept = sorted({ln.split('\t')[0] for ln in text.splitlines()})
        ucase('usage-poda-400-dias', 'LIGADO em' in line and len(kept) == 400 and kept[0] == '2020-01-06'
              and kept[-1] == '2021-02-08' and 'fora do formato' not in text and rows.get('kg_list') == [400, 0],
              f'{line} dias={len(kept)} de {kept[:1]} a {kept[-1:]}')

        # (u9) escritas concorrentes de processos distintos não perdem contagem (trava de arquivo)
        cdir = os.path.join(base, 'uso-concorrente')
        prog = ('import importlib.util, sys\n'
                'spec = importlib.util.spec_from_file_location("srv", sys.argv[1])\n'
                'm = importlib.util.module_from_spec(spec)\n'
                'spec.loader.exec_module(m)\n'
                'm.USAGE.start()\n'
                'for _ in range(25):\n'
                '    m.USAGE.record("kg_list", True)\n'
                'print(m.USAGE.enabled, m.USAGE.failures)\n')
        cenv = {**env, 'ONION_KG_ROOT': wt, 'ONION_KG_USAGE_DIR': cdir}
        procs = [subprocess.Popen([sys.executable, '-I', '-B', '-c', prog, SERVER], env=cenv,
                                  stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True) for _ in range(4)]
        outs = []
        for cp in procs:
            try:
                o, er = cp.communicate(timeout=120)
            except subprocess.TimeoutExpired:
                cp.kill()
                o, er = cp.communicate()
            outs.append((cp.returncode, o.strip(), er.strip()[-200:]))
        _, rows = usage_read(os.path.join(cdir, USAGE_FILE))
        ucase('usage-concorrencia-nao-perde', all(o == (0, 'True 0', '') for o in outs)
              and rows.get('kg_list') == [100, 0], f'{rows} {outs}')
    finally:
        # caso que não chegou a rodar (servidor não subiu, exceção no meio) reprova pelo NOME, não some
        for name in all_names:
            if name not in done:
                case(name, False, 'caso nao executado')


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

        # (10) lista de e-mails (molde do SGE): com ONION_KG_ALLOWED_EMAILS definida, tools/call exige o
        #      X-User-Email na lista; lista vazia nega todos; initialize/tools/list passam; sem a env, só o token.
        def call_u(port_, tool, user):
            hdr = {'Content-Type': 'application/json', 'X-Api-Key': TOKEN}
            if user is not None:
                hdr['X-User-Email'] = user
            body = json.dumps({'jsonrpc': '2.0', 'id': 1, 'method': 'tools/call',
                               'params': {'name': tool, 'arguments': {}}}).encode()
            req = urllib.request.Request(f'http://127.0.0.1:{port_}/mcp', data=body, method='POST', headers=hdr)
            with urllib.request.urlopen(req, timeout=60) as r:
                res = json.loads(r.read()).get('result', {})
            try:
                pl_ = json.loads(res['content'][0]['text'])
            except (KeyError, IndexError, ValueError):
                pl_ = {}
            return bool(res.get('isError')), pl_
        p3 = start({'ONION_KG_ROOT': wt, 'ONION_KG_ALLOWED_EMAILS': 'Ana@Exemplo.com, bia@exemplo.com'})
        port3, line3 = wait_port(p3)
        if port3 is None:
            for c in ('allowlist-email-na-lista-passa', 'allowlist-email-fora-recusa',
                      'allowlist-sem-header-recusa', 'allowlist-tools-list-passa'):
                case(c, False, line3)
        else:
            e_ok, pl_ok = call_u(port3, 'kg_list', 'ana@exemplo.com ')
            case('allowlist-email-na-lista-passa', not e_ok and pl_ok.get('served_commit') == head, pl_ok.get('recusa'))
            e_no, pl_no = call_u(port3, 'kg_list', 'intruso@exemplo.com')
            case('allowlist-email-fora-recusa', e_no and 'data' not in pl_no and 'nao autorizado' in pl_no.get('recusa', ''), pl_no)
            e_nh, pl_nh = call_u(port3, 'kg_list', None)
            case('allowlist-sem-header-recusa', e_nh and 'data' not in pl_nh, pl_nh)
            code_l, resp_l = rpc(port3, 'tools/list')
            case('allowlist-tools-list-passa', code_l == 200 and len(resp_l.get('result', {}).get('tools', [])) > 0, code_l)
        p4 = start({'ONION_KG_ROOT': wt, 'ONION_KG_ALLOWED_EMAILS': ''})
        port4, line4 = wait_port(p4)
        if port4 is None:
            case('allowlist-vazia-nega-todos', False, line4)
        else:
            e_v, pl_v = call_u(port4, 'kg_list', 'ana@exemplo.com')
            case('allowlist-vazia-nega-todos', e_v and 'data' not in pl_v, pl_v)

        # (11) contador de uso por ferramenta
        usage_cases(base, wt)
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
