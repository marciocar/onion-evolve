#!/usr/bin/env python3
"""selftest.py — dogfood do onion-kg-writer por HTTP de verdade (consumido pela família mcp_onion_kg_writer).

Sobe o servidor em 127.0.0.1 numa porta EFÊMERA (MCP_PORT=0), com token de teste, raiz de dados em
mktemp (DENTRO de um repo git pai, para provar que o commit nunca sobe até ele) e a maquinaria REAL
do core como gate (ONION_KG_CODE_ROOT = o repo deste arquivo). Chama cada tool por JSON-RPC MCP e
encerra SÓ os processos que ele mesmo subiu (pelo handle do Popen, nunca pkill).

Saída: uma linha por caso, `PASS <caso>` ou `FAIL <caso> :: <detalhe>`, e no fim `TOTAL <n>`.
rc 0 só se todos passaram.
Uso: python3 -I -B ops/mcp-onion-kg-writer/selftest.py [--server <server.py>] [--code-root <repo>]
     (--server aponta uma CÓPIA mutada pelo ops/mutate-and-restore.sh; o gate segue o do repo real)
"""
import json
import os
import shutil
import socket
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
CODE_ROOT = os.path.dirname(os.path.dirname(HERE))
if '--code-root' in sys.argv:
    CODE_ROOT = os.path.realpath(sys.argv[sys.argv.index('--code-root') + 1])
TOKEN = 'selftest-writer-token-nao-secreto'
A, B, C = 'ana@exemplo.com', 'bia@exemplo.com', 'caio@exemplo.com'
RESULTS = []
T0 = time.time()
PROCS = []
GIT = ['git', '-c', 'user.email=selftest@onion', '-c', 'user.name=selftest', '-c', 'commit.gpgsign=false',
       '-c', 'core.hooksPath=' + os.devnull]


def case(name, ok, detail=''):
    RESULTS.append((name, bool(ok)))
    print(f'PASS {name}' if ok else f'FAIL {name} :: {str(detail)[:400]}', flush=True)


def graph(gid, extra_meta='', node_extra='', claim_status='open', refutes=False):
    edge = 'REFUTES' if refutes else 'SUPPORTS'
    prov = ('    verified_at: "2026-10-12"\n    verified_against: "leitura do selftest"\n'
            '    provenance:\n      source: "ops/mcp-onion-kg-writer/selftest.py"\n      locator: "fixture"\n'
            '      method: "leitura: fixture do selftest"\n') if claim_status == 'confirmed' else ''
    return (f'meta:\n  id: {gid}\n  schema_version: "1"\n  layer: audit\n  baseline: "2026-10-12"\n{extra_meta}'
            'nodes:\n'
            '  - id: Q_PERGUNTA\n    node_type: question\n    plane: DEV\n    status: open\n    impact: 3\n'
            '    confidence: 0.5\n    label: "pergunta da fixture"\n'
            f'  - id: C_ALVO\n    node_type: claim\n    plane: DEV\n    status: {claim_status}\n    impact: 3\n'
            f'    confidence: 0.6\n    label: "afirmacao da fixture"\n    trace: "selftest"\n{prov}{node_extra}'
            'edges:\n'
            f'  - from: {"Q_PERGUNTA" if refutes else "C_ALVO"}\n    to: {"C_ALVO" if refutes else "Q_PERGUNTA"}\n'
            f'    edge_type: {edge}\n')


def start(env_extra, drop=()):
    env = {k: v for k, v in os.environ.items() if not k.startswith('ONION_KG_')}
    env.update({'MCP_HOST': '127.0.0.1', 'MCP_PORT': '0', 'ONION_KG_WRITER_TOKEN': TOKEN,
                'ONION_KG_CODE_ROOT': CODE_ROOT})
    env.update(env_extra)
    for k in drop:
        env.pop(k, None)
    p = subprocess.Popen([sys.executable, '-I', '-B', SERVER], env=env, stdout=subprocess.PIPE,
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


def wait_exit(p, timeout=8):
    try:
        return p.wait(timeout=timeout)
    except subprocess.TimeoutExpired:
        p.terminate()
        p.wait(timeout=5)
        return None


def rpc(port, method, params=None, key=TOKEN, user=None, rid=1):
    body = json.dumps({'jsonrpc': '2.0', 'id': rid, 'method': method, 'params': params or {}}).encode()
    hdr = {'Content-Type': 'application/json'}
    if key is not None:
        hdr['X-Api-Key'] = key
    if user is not None:
        hdr['X-User-Email'] = user
    req = urllib.request.Request(f'http://127.0.0.1:{port}/mcp', data=body, method='POST', headers=hdr)
    try:
        with urllib.request.urlopen(req, timeout=120) as r:
            return r.status, json.loads(r.read())
    except urllib.error.HTTPError as e:
        return e.code, json.loads(e.read() or b'{}')
    except (OSError, ValueError) as e:
        return 0, {'_erro_transporte': str(e)}


def call(port, tool, args=None, user=A):
    code, resp = rpc(port, 'tools/call', {'name': tool, 'arguments': args or {}}, user=user)
    res = resp.get('result', {})
    try:
        payload = json.loads(res['content'][0]['text'])
    except (KeyError, IndexError, ValueError, TypeError):
        payload = {'_raw': resp}
    return bool(res.get('isError')), payload


def stop_all():
    for p in PROCS:
        if p.poll() is None:
            p.terminate()
            try:
                p.wait(timeout=5)
            except subprocess.TimeoutExpired:
                p.kill()
                p.wait(timeout=5)


def main():
    base = tempfile.mkdtemp(prefix='mcp-kg-writer-selftest-')
    try:
        # repo PAI envolvendo a raiz de dados: o commit da área nunca pode cair nele
        subprocess.run([*GIT, 'init', '-q', base], check=True, capture_output=True)
        root = os.path.join(base, 'data')
        os.mkdir(root)
        fora = os.path.join(base, 'fora')
        os.mkdir(fora)

        # (1) boot fail-closed
        p = start({'ONION_KG_WRITER_ROOT': root}, drop=('ONION_KG_WRITER_TOKEN',))
        rc = wait_exit(p)
        err = p.stderr.read()
        case('token-fail-closed', rc not in (0, None) and 'fail-closed' in err, f'rc={rc} err={err}')
        p = start({'ONION_KG_WRITER_ROOT': root, 'ONION_KG_CODE_ROOT': fora})
        rc = wait_exit(p)
        err = p.stderr.read()
        case('code-root-sem-gate-recusa-boot', rc not in (0, None) and 'sem gate' in err, f'rc={rc} err={err}')
        p = start({'ONION_KG_WRITER_ROOT': os.path.join(base, 'nao-existe')})
        rc = wait_exit(p)
        err = p.stderr.read()
        case('data-root-ausente-recusa-boot', rc not in (0, None) and 'ONION_KG_WRITER_ROOT' in err, f'rc={rc} err={err}')

        p = start({'ONION_KG_WRITER_ROOT': root})
        port, line = wait_port(p)
        case('sobe-em-porta-efemera', port is not None, line)
        if port is None:
            return

        # (2) auth
        code, _ = rpc(port, 'tools/list', key=None)
        case('sem-token-401', code == 401, code)
        code, _ = rpc(port, 'tools/list', key='errado')
        case('token-errado-401', code == 401, code)
        code, resp = rpc(port, 'tools/list')
        names = sorted(t['name'] for t in resp.get('result', {}).get('tools', []))
        case('tools-list-5', names == ['kg_my_get', 'kg_my_list', 'kg_schema_help', 'kg_validate', 'kg_write'], names)

        # (3) identidade: sem e-mail, e-mail inválido e placeholder não substituído = recusa, nada gravado
        ok_yaml = graph('demo-ok')
        e1, p1 = call(port, 'kg_write', {'slug': 'demo-ok', 'yaml': ok_yaml}, user=None)
        e2, p2 = call(port, 'kg_write', {'slug': 'demo-ok', 'yaml': ok_yaml}, user='../../fora@exemplo.com')
        e3, p3 = call(port, 'kg_write', {'slug': 'demo-ok', 'yaml': ok_yaml}, user='{{LIBRECHAT_USER_EMAIL}}')
        case('sem-email-recusa', e1 and 'X-User-Email' in p1.get('recusa', '') and os.listdir(root) == [], p1)
        case('email-invalido-recusa', e2 and e3 and 'invalido' in p2.get('recusa', '')
             and 'invalido' in p3.get('recusa', '') and os.listdir(root) == [] and os.listdir(fora) == [], [p2, p3])

        # (4) o exemplo do kg_schema_help passa no gate (a ajuda e o gate não divergem)
        _, ph = call(port, 'kg_schema_help')
        ex = ph.get('data', {}).get('exemplo_minimo_aprovado', '')
        _, pv = call(port, 'kg_validate', {'yaml': ex})
        case('schema-help-exemplo-aprova', pv.get('data', {}).get('veredito') == 'APROVADO', pv.get('data'))
        case('envelope-nao-confiavel', ph.get('untrusted_data') is True and 'DADO' in ph.get('aviso', '')
             and ph.get('usuario') == A, ph.get('aviso'))
        head = subprocess.run(['git', '-C', CODE_ROOT, 'rev-parse', 'HEAD'], capture_output=True, text=True).stdout.strip()
        case('served-commit-do-gate', ph.get('served_commit') == head, f"{ph.get('served_commit')} != {head}")

        # (5) dry-run: valida e NÃO grava
        _, pv = call(port, 'kg_validate', {'yaml': ok_yaml})
        case('validate-nao-grava', pv.get('data', {}).get('veredito') == 'APROVADO'
             and pv['data'].get('gravado') is False and os.listdir(root) == [], pv.get('data'))

        # (6) grafo válido grava e commita com o autor certo (e-mail do header normalizado)
        e, pw = call(port, 'kg_write', {'slug': 'demo-ok', 'yaml': ok_yaml}, user='Ana@Exemplo.com ')
        d = pw.get('data', {})
        area_a = os.path.join(root, d.get('area', '?'))
        f = os.path.join(area_a, 'demo-ok', 'demo-ok.kg.yaml')
        log = subprocess.run(['git', '-C', area_a, 'log', '-1', '--format=%H %ae'], capture_output=True, text=True).stdout.split()
        with open(f, encoding='utf-8') if os.path.isfile(f) else open(os.devnull) as fh:
            gravado = fh.read()
        case('write-valido-grava-e-commita', not e and d.get('gravado') is True and gravado == ok_yaml
             and log == [d.get('commit'), A] and d.get('autor') == A and d.get('caminho') == 'demo-ok/demo-ok.kg.yaml', [d, log])
        parent = subprocess.run(['git', '-C', base, 'log', '--oneline'], capture_output=True, text=True)
        case('commit-nao-cai-no-repo-pai', parent.returncode != 0 and parent.stdout == '', parent.stdout + parent.stderr[:120])
        e, pw2 = call(port, 'kg_write', {'slug': 'demo-ok', 'yaml': ok_yaml})
        d2 = pw2.get('data', {})
        case('reescrita-identica-sem-commit-novo', not e and d2.get('mudou') is False and d2.get('commit') == d.get('commit'), pw2)

        # (7) o radar reprova (contradição REFUTES em confirmed; o contrato sozinho aprovaria) → nada gravado
        bad_r = graph('demo-radar', claim_status='confirmed', refutes=True)
        e, pr = call(port, 'kg_write', {'slug': 'demo-radar', 'yaml': bad_r})
        dr = pr.get('data', {})
        case('radar-reprova-nada-gravado', e and dr.get('gravado') is False and dr.get('veredito') == 'REPROVADO'
             and dr.get('radar', {}).get('passou') is False and dr.get('contrato', {}).get('passou') is True
             and any('CONTRADI' in x for x in dr['radar'].get('falhas', []))
             and not os.path.exists(os.path.join(area_a, 'demo-radar')), dr)

        # (8) o contrato reprova (chave inventada no meta; o radar sozinho aprovaria) → nada gravado
        bad_c = graph('demo-contrato', extra_meta='  inventada: 1\n')
        e, pc = call(port, 'kg_write', {'slug': 'demo-contrato', 'yaml': bad_c})
        dc = pc.get('data', {})
        case('contrato-reprova-nada-gravado', e and dc.get('gravado') is False
             and dc.get('radar', {}).get('passou') is True and dc.get('contrato', {}).get('passou') is False
             and any('form.unknown-key.meta.inventada' in x for x in dc['contrato'].get('falhas', []))
             and not os.path.exists(os.path.join(area_a, 'demo-contrato'))
             and 'kgw-gate-' not in json.dumps(pc), dc)  # o caminho do diretório temporário do gate não vaza

        # (9) reprovado de usuário novo não cria nem a área
        before = sorted(os.listdir(root))
        call(port, 'kg_write', {'slug': 'demo-radar', 'yaml': bad_r}, user=C)
        case('reprovado-nao-cria-area', sorted(os.listdir(root)) == before, os.listdir(root))

        # (10) slug: `..`, `/`, maiúscula, vazio → recusa, nada criado (meta.id = o próprio slug)
        outs = []
        for s in ('..', '../x', 'a/b', 'Demo', '', 'demo_ok', '-x'):
            e, ps = call(port, 'kg_write', {'slug': s, 'yaml': graph(s or 'x')})
            outs.append((s, e, ps.get('recusa', '')[:40]))
        case('slug-invalido-recusa', all(e and 'slug invalido' in r for _, e, r in outs)
             and sorted(os.listdir(area_a)) == ['.git', 'demo-ok'] and os.listdir(fora) == [], outs)

        # (11) meta.id ≠ slug → recusa
        e, pm = call(port, 'kg_write', {'slug': 'outro', 'yaml': ok_yaml})
        case('meta-id-diferente-recusa', e and 'meta.id' in pm.get('recusa', '')
             and not os.path.exists(os.path.join(area_a, 'outro')), pm)

        # (12) A e B: áreas disjuntas — B não lista nem lê o que A gravou
        e, pb = call(port, 'kg_write', {'slug': 'demo-b', 'yaml': graph('demo-b')}, user=B)
        _, la = call(port, 'kg_my_list', user=A)
        _, lb = call(port, 'kg_my_list', user=B)
        eg, gb = call(port, 'kg_my_get', {'slug': 'demo-ok'}, user=B)
        _, ga = call(port, 'kg_my_get', {'slug': 'demo-ok'}, user=A)
        sa = [g['slug'] for g in la.get('data', {}).get('grafos', [])]
        sb_ = [g['slug'] for g in lb.get('data', {}).get('grafos', [])]
        case('isolamento-a-b', not e and sa == ['demo-ok'] and sb_ == ['demo-b'] and eg
             and 'inexistente' in gb.get('recusa', '') and ga.get('data', {}).get('conteudo') == ok_yaml
             and la['data']['area'] != lb['data']['area'], [sa, sb_, gb])

        # (13) symlink plantado na área: dir do slug → outro dir DENTRO da área e → fora; arquivo → fora
        os.symlink(os.path.join(area_a, 'demo-ok'), os.path.join(area_a, 'evil-in'))
        os.mkdir(os.path.join(fora, 'evil-out'))
        os.symlink(os.path.join(fora, 'evil-out'), os.path.join(area_a, 'evil-out'))
        os.mkdir(os.path.join(area_a, 'evil-file'))
        with open(os.path.join(fora, 'segredo.kg.yaml'), 'w') as fh:
            fh.write('SEGREDO-FORA\n')
        os.symlink(os.path.join(fora, 'segredo.kg.yaml'), os.path.join(area_a, 'evil-file', 'evil-file.kg.yaml'))
        r_in = call(port, 'kg_write', {'slug': 'evil-in', 'yaml': graph('evil-in')})
        r_out = call(port, 'kg_write', {'slug': 'evil-out', 'yaml': graph('evil-out')})
        r_file = call(port, 'kg_write', {'slug': 'evil-file', 'yaml': graph('evil-file')})
        g_file = call(port, 'kg_my_get', {'slug': 'evil-file'})
        _, la2 = call(port, 'kg_my_list')
        listed = [g['slug'] for g in la2.get('data', {}).get('grafos', [])]
        case('symlink-plantado-recusa', all(r[0] and 'symlink' in r[1].get('recusa', '') for r in (r_in, r_out, r_file, g_file))
             and not os.path.exists(os.path.join(area_a, 'demo-ok', 'evil-in.kg.yaml'))
             and os.listdir(os.path.join(fora, 'evil-out')) == [] and 'SEGREDO' not in json.dumps(g_file[1])
             and listed == ['demo-ok'], [r_in[1].get('recusa'), r_out[1].get('recusa'), r_file[1].get('recusa'), listed])

        # (14) yaml acima do teto (grafo VÁLIDO com enchimento de comentário) → recusa, nada gravado
        big = graph('demo-big') + ('# enchimento\n' * 50000)
        e, pg = call(port, 'kg_write', {'slug': 'demo-big', 'yaml': big})
        case('yaml-acima-do-teto-recusa', len(big.encode()) > 512 * 1024 and e and 'teto' in pg.get('recusa', '')
             and not os.path.exists(os.path.join(area_a, 'demo-big')), pg.get('recusa'))

        # (15) âncora/alias (vetor de bomba de expansão) → recusa antes de qualquer gate
        ali = graph('demo-alias').replace('    label: "pergunta da fixture"\n',
                                          '    label: &rotulo "pergunta da fixture"\n').replace(
            '    label: "afirmacao da fixture"\n', '    label: *rotulo\n')
        e, pa = call(port, 'kg_write', {'slug': 'demo-alias', 'yaml': ali})
        case('alias-recusado', e and 'alias' in pa.get('recusa', '') and not os.path.exists(os.path.join(area_a, 'demo-alias')), pa)

        # (16) corpo malformado
        s = socket.create_connection(('127.0.0.1', port), timeout=5)
        try:
            s.sendall(f'POST /mcp HTTP/1.1\r\nHost: x\r\nX-Api-Key: {TOKEN}\r\nContent-Length: -1\r\n\r\n'.encode())
            first = s.recv(200).decode(errors='replace')
        except OSError as ex:
            first = f'erro: {ex}'
        finally:
            s.close()
        case('content-length-negativo-400', ' 400 ' in first.split('\r\n')[0], first[:80])

        # (17) teto de grafos por área e timeout do gate (servidores próprios)
        root2 = os.path.join(base, 'data2')
        os.mkdir(root2)
        p2 = start({'ONION_KG_WRITER_ROOT': root2, 'ONION_KG_WRITER_MAX_GRAPHS': '1'})
        port2, line2 = wait_port(p2)
        if port2 is None:
            case('area-cheia-recusa', False, line2)
        else:
            call(port2, 'kg_write', {'slug': 'um', 'yaml': graph('um')})
            e, pf = call(port2, 'kg_write', {'slug': 'dois', 'yaml': graph('dois')})
            case('area-cheia-recusa', e and 'area cheia' in pf.get('recusa', ''), pf)
        root3 = os.path.join(base, 'data3')
        os.mkdir(root3)
        p3 = start({'ONION_KG_WRITER_ROOT': root3, 'ONION_KG_WRITER_GATE_TIMEOUT': '0'})
        port3, line3 = wait_port(p3)
        if port3 is None:
            case('gate-timeout-reprova', False, line3)
        else:
            e, pt = call(port3, 'kg_write', {'slug': 'demo-ok', 'yaml': ok_yaml})
            dt = pt.get('data', {})
            case('gate-timeout-reprova', e and dt.get('gravado') is False and os.listdir(root3) == []
                 and any('timeout' in x for x in dt.get('radar', {}).get('falhas', [])), dt)
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
