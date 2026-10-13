#!/usr/bin/env python3
"""selftest.py — dogfood do onion-kg-writer por HTTP de verdade (consumido pela família mcp_onion_kg_writer).

Sobe o servidor em 127.0.0.1 numa porta EFÊMERA (MCP_PORT=0), com token de teste, raiz de dados em
mktemp (DENTRO de um repo git pai, para provar que o commit nunca sobe até ele) e a maquinaria REAL
do core como gate (ONION_KG_CODE_ROOT = o repo deste arquivo): o radar e o armazém do produto
(vendor/kg-ssot/tools/kg_store.py, GitStore por área). Chama cada tool por JSON-RPC MCP e encerra SÓ
os processos que ele mesmo subiu (pelo handle do Popen, nunca pkill).

Além do armazém real, um CODE ROOT FALSO (radar que sai 0, o kg_store.py REAL copiado e um kg_validate.py
que reexporta o real e troca o judge() por modo, lido de um arquivo vizinho) prova o fail-closed do veredito:
julgamento que quebra, not_judged na gravação, versão desconhecida, veredito incoerente e ponta externa não
conferida viram NÃO JULGADO, e o gate decide por `code`, nunca por `message`.

A guarda de aninhamento é provada por classe (30.000 `[`, `- - -`, `? ?`, indentação crescente, cada uma das
quatro quebras de linha do YAML que não são \\n, tab no começo e bomba de alias), cada caso conferindo que o
processo do servidor segue vivo depois.

Saída: uma linha por caso, `PASS <caso>` ou `FAIL <caso> :: <detalhe>`, e no fim `TOTAL <n>`.
rc 0 só se todos passaram.
Uso: python3 -I -B ops/mcp-onion-kg-writer/selftest.py [--server <server.py>] [--code-root <repo>]
     [--until <caso>]
     (--server aponta uma CÓPIA mutada pelo ops/mutate-and-restore.sh; o gate segue o do repo real;
      --until para depois do caso nomeado, que é o que o mutante precisa morder: metade do custo por mutante)
"""
import hashlib
import json
import os
import re
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
UNTIL = sys.argv[sys.argv.index('--until') + 1] if '--until' in sys.argv else None
TOKEN = 'selftest-writer-token-nao-secreto'
A, B, C, D, E = 'ana@exemplo.com', 'bia@exemplo.com', 'caio@exemplo.com', 'dora@exemplo.com', 'eva@exemplo.com'
RESULTS = []
T0 = time.time()
PROCS = []
GIT = ['git', '-c', 'user.email=selftest@onion', '-c', 'user.name=selftest', '-c', 'commit.gpgsign=false',
       '-c', 'core.hooksPath=' + os.devnull, '-c', 'init.defaultBranch=main']


class _Until(Exception):
    """--until <caso>: o harness para depois de emitir o caso (o mutante só precisa chegar até ele)."""


def case(name, ok, detail=''):
    RESULTS.append((name, bool(ok)))
    print(f'PASS {name}' if ok else f'FAIL {name} :: {str(detail)[:400]}', flush=True)
    if name == UNTIL:
        raise _Until(name)


def area_of(root, email):
    """O mesmo nome de área do servidor (parte local saneada + sha256 curto)."""
    local = re.sub(r'[^a-z0-9]+', '-', email.split('@', 1)[0]).strip('-')[:32] or 'u'
    return os.path.join(root, f'{local}-{hashlib.sha256(email.encode()).hexdigest()[:16]}')


def git_out(repo, *args):
    r = subprocess.run(['git', '-C', repo, *args], capture_output=True, text=True)
    return r.returncode, r.stdout.strip()


def graph(gid, extra_meta='', node_extra='', claim_status='open', refutes=False, external='', narrative=''):
    edge = 'REFUTES' if refutes else 'SUPPORTS'
    prov = ('    verified_at: "2026-10-12"\n    verified_against: "leitura do selftest"\n'
            '    provenance:\n      source: "ops/mcp-onion-kg-writer/selftest.py"\n      locator: "fixture"\n'
            '      method: "leitura: fixture do selftest"\n') if claim_status == 'confirmed' else ''
    return (f'meta:\n  id: {gid}\n  schema_version: "1"\n  layer: audit\n  baseline: "2026-10-12"\n{extra_meta}'
            'nodes:\n'
            '  - id: Q_PERGUNTA\n    node_type: question\n    plane: DEV\n    status: open\n    impact: 3\n'
            f'    confidence: 0.5\n    label: "pergunta da fixture"\n{narrative}'
            f'  - id: C_ALVO\n    node_type: claim\n    plane: DEV\n    status: {claim_status}\n    impact: 3\n'
            f'    confidence: 0.6\n    label: "afirmacao da fixture"\n    trace: "selftest"\n{prov}{node_extra}'
            'edges:\n'
            f'  - from: {"Q_PERGUNTA" if refutes else "C_ALVO"}\n    to: {"C_ALVO" if refutes else "Q_PERGUNTA"}\n'
            f'    edge_type: {edge}\n{external}')


def ext(to, frm='C_ALVO', edge_type='SUPPORTS'):
    return f'external_edges:\n  - from: {frm}\n    to: "{to}"\n    edge_type: {edge_type}\n'


FAKE_VALIDATE = r"""
import importlib.util, os
HERE = os.path.dirname(os.path.abspath(__file__))
_spec = importlib.util.spec_from_file_location('kg_validate_real', open(os.path.join(HERE, 'real_path')).read().strip())
real = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(real)
for _k in dir(real):
    if not _k.startswith('__'):
        globals()[_k] = getattr(real, _k)


def judge(sources, schema=None, should_schema=None, corpus=None, limit=50):
    mode = open(os.path.join(HERE, 'mode')).read().strip()
    if mode == 'raise':
        raise RuntimeError('julgamento falso quebrou')
    if mode == 'raise-2nd':  # o 1o julgamento (o do servidor) passa; o da gravacao, dentro do armazem, quebra
        p = os.path.join(HERE, 'count')
        n = int(open(p).read() or 0) if os.path.exists(p) else 0
        open(p, 'w').write(str(n + 1))
        if n >= 1:
            raise RuntimeError('julgamento falso quebrou na gravacao')
    doc = real.judge(sources, schema or real.CONTRACT_MUST, should_schema, corpus, limit)
    r = doc['results'][0]
    if mode == 'versao-2':
        doc['schema_version'] = 'kg-ssot.verdict/2'
    elif mode == 'incoerente':  # PASS com MUST: o armazem so olha FAIL e gravaria
        r['summary']['MUST'] = {'form.required.node.label': 1}
    elif mode == 'externo':
        r['external_checked'] = False
    elif mode == 'message':  # FAIL de verdade cuja frase humana diz o contrario: decide-se por code
        r['verdict'] = 'FAIL'
        r['summary']['MUST'] = {'form.unknown-key.meta.x': 1}
        r['occurrences'] = [{'level': 'MUST', 'code': 'form.unknown-key.meta.x', 'place': 'meta', 'path': 'meta.x',
                             'line': 2, 'message': 'PASS: tudo certo'}]
        r['total'] = 1
    return doc
"""


def fake_code_root(base):
    """Code root falso: radar que aprova tudo, o kg_store.py REAL e um kg_validate.py que troca o judge() por modo; o
    verdict.schema.json REAL com a versão aberta a /1 e /2 (para isolar a conferência explícita da versão)."""
    fr = os.path.join(base, 'code-falso')
    tools = os.path.join(fr, 'vendor', 'kg-ssot', 'tools')
    os.makedirs(os.path.join(fr, '.claude', 'validation'))
    os.makedirs(tools)
    os.makedirs(os.path.join(fr, 'vendor', 'kg-ssot', 'spec'))
    with open(os.path.join(fr, '.claude', 'validation', 'kg-radar.sh'), 'w') as fh:
        fh.write('#!/usr/bin/env bash\nexit 0\n')
    real_tools = os.path.join(CODE_ROOT, 'vendor', 'kg-ssot', 'tools')
    shutil.copy(os.path.join(real_tools, 'kg_store.py'), tools)
    with open(os.path.join(tools, 'kg_validate.py'), 'w') as fh:
        fh.write(FAKE_VALIDATE)
    with open(os.path.join(tools, 'real_path'), 'w') as fh:
        fh.write(os.path.join(real_tools, 'kg_validate.py'))
    with open(os.path.join(CODE_ROOT, 'vendor', 'kg-ssot', 'spec', 'verdict.schema.json'), encoding='utf-8') as fh:
        sch = json.load(fh)
    sch['properties']['schema_version'] = {'enum': ['kg-ssot.verdict/1', 'kg-ssot.verdict/2']}
    with open(os.path.join(fr, 'vendor', 'kg-ssot', 'spec', 'verdict.schema.json'), 'w', encoding='utf-8') as fh:
        json.dump(sch, fh)
    return fr


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


def alive(p, port):
    code, resp = rpc(port, 'ping')
    return p.poll() is None and code == 200 and resp.get('result') == {}


def stop_all():
    for p in PROCS:
        if p.poll() is None:
            p.terminate()
            try:
                p.wait(timeout=5)
            except subprocess.TimeoutExpired:
                p.kill()
                p.wait(timeout=5)


def wipe(path):
    """Remove o que estiver no caminho (symlink, arquivo ou pasta), sem falhar: a limpeza de um caso não pode derrubar
    o harness quando um mutante deixou o estado diferente do esperado."""
    try:
        if os.path.islink(path) or os.path.isfile(path):
            os.remove(path)
        elif os.path.isdir(path):
            shutil.rmtree(path, ignore_errors=True)
    except OSError:
        pass


def commits(repo):
    rc, out = git_out(repo, 'rev-list', '--count', 'HEAD')
    return int(out) if rc == 0 else 0


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
        case('code-root-sem-gate-recusa-boot', rc not in (0, None) and 'sem gate' in err and 'radar ausente' in err,
             f'rc={rc} err={err}')
        semstore = os.path.join(base, 'code-sem-armazem')
        os.makedirs(os.path.join(semstore, '.claude', 'validation'))
        os.makedirs(os.path.join(semstore, 'vendor', 'kg-ssot', 'spec'))
        shutil.copy(os.path.join(CODE_ROOT, '.claude', 'validation', 'kg-radar.sh'),
                    os.path.join(semstore, '.claude', 'validation'))
        shutil.copy(os.path.join(CODE_ROOT, 'vendor', 'kg-ssot', 'spec', 'verdict.schema.json'),
                    os.path.join(semstore, 'vendor', 'kg-ssot', 'spec'))
        p = start({'ONION_KG_WRITER_ROOT': root, 'ONION_KG_CODE_ROOT': semstore})
        rc = wait_exit(p)
        err = p.stderr.read()
        case('armazem-ausente-recusa-boot', rc not in (0, None) and 'kg_store.py ausente' in err, f'rc={rc} err={err}')
        p = start({'ONION_KG_WRITER_ROOT': os.path.join(base, 'nao-existe')})
        rc = wait_exit(p)
        err = p.stderr.read()
        case('data-root-ausente-recusa-boot', rc not in (0, None) and 'ONION_KG_WRITER_ROOT' in err, f'rc={rc} err={err}')

        p = start({'ONION_KG_WRITER_ROOT': root})
        port, line = wait_port(p)
        case('sobe-em-porta-efemera', bool(port), line)  # a porta REAL do bind, nunca o 0 pedido
        if not port:
            return
        srv = p

        # (2) auth
        code, _ = rpc(port, 'tools/list', key=None)
        case('sem-token-401', code == 401, code)
        code, _ = rpc(port, 'tools/list', key='errado')
        case('token-errado-401', code == 401, code)
        code, resp = rpc(port, 'tools/list')
        tl = resp.get('result', {}).get('tools', [])
        names = sorted(t['name'] for t in tl)
        destr = sorted(t['name'] for t in tl if t.get('annotations', {}).get('destructiveHint'))
        case('tools-list-6', names == ['kg_delete', 'kg_my_get', 'kg_my_list', 'kg_schema_help', 'kg_validate', 'kg_write']
             and destr == ['kg_delete'], [names, destr])

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
        case('served-commit-do-gate', ph.get('served_commit') == head and ph.get('store_commit') == head
             and 'aviso_codigo' not in ph, f"{ph.get('served_commit')} / {ph.get('store_commit')} != {head}")

        # (5) dry-run: valida e NÃO grava (nem cria a área)
        _, pv = call(port, 'kg_validate', {'yaml': ok_yaml})
        case('validate-nao-grava', pv.get('data', {}).get('veredito') == 'APROVADO'
             and pv['data'].get('gravado') is False and os.listdir(root) == [], pv.get('data'))

        # (6) grafo válido grava pelo GitStore: um commit, autor = o e-mail do header normalizado, committer = o serviço
        e, pw = call(port, 'kg_write', {'slug': 'demo-ok', 'yaml': ok_yaml}, user='Ana@Exemplo.com ')
        d = pw.get('data', {})
        area_a = os.path.join(root, d.get('area', '?'))
        f = os.path.join(area_a, 'demo-ok', 'demo-ok.kg.yaml')
        _, log = git_out(area_a, 'log', '-1', '--format=%H %ae %ce')
        _, branch = git_out(area_a, 'symbolic-ref', '--short', 'HEAD')
        with open(f, encoding='utf-8') if os.path.isfile(f) else open(os.devnull) as fh:
            gravado = fh.read()
        case('write-valido-grava-e-commita', not e and d.get('gravado') is True and gravado == ok_yaml
             and d.get('unchanged') is False and log.split() == [d.get('commit'), A, 'onion-kg-writer@localhost']
             and d.get('autor') == f'ana <{A}>' and d.get('caminho') == 'demo-ok/demo-ok.kg.yaml'
             and d.get('sha256_atual') == hashlib.sha256(ok_yaml.encode()).hexdigest() and branch == 'main'
             and commits(area_a) == 1, [d, log, branch])
        parent = subprocess.run(['git', '-C', base, 'log', '--oneline'], capture_output=True, text=True)
        case('commit-nao-cai-no-repo-pai', parent.returncode != 0 and parent.stdout == '', parent.stdout + parent.stderr[:120])

        # (c) texto igual ao HEAD: written + unchanged, ref null, sem commit vazio
        e, pw2 = call(port, 'kg_write', {'slug': 'demo-ok', 'yaml': ok_yaml})
        d2 = pw2.get('data', {})
        case('reescrita-identica-unchanged', not e and d2.get('gravado') is True and d2.get('unchanged') is True
             and d2.get('commit') is None and commits(area_a) == 1 and d2.get('area_commit') == d.get('commit'), d2)

        # (7) o radar reprova (contradição REFUTES em confirmed; o contrato sozinho aprovaria) → nada gravado
        bad_r = graph('demo-radar', claim_status='confirmed', refutes=True)
        e, pr = call(port, 'kg_write', {'slug': 'demo-radar', 'yaml': bad_r})
        dr = pr.get('data', {})
        case('radar-reprova-nada-gravado', e and dr.get('gravado') is False and dr.get('veredito') == 'REPROVADO'
             and dr.get('radar', {}).get('passou') is False and dr.get('contrato', {}).get('passou') is True
             and any('CONTRADI' in x for x in dr['radar'].get('falhas', []))
             and not os.path.exists(os.path.join(area_a, 'demo-radar')), dr)

        # (8) o contrato reprova (chave inventada no meta; o radar sozinho aprovaria): o dry-run reprova e nada é gravado
        bad_c = graph('demo-contrato', extra_meta='  inventada: 1\n')
        _, pcv = call(port, 'kg_validate', {'yaml': bad_c})
        e, pc = call(port, 'kg_write', {'slug': 'demo-contrato', 'yaml': bad_c})
        dc, dcv = pc.get('data', {}), pcv.get('data', {})
        occ_c = [o for o in dc.get('contrato', {}).get('ocorrencias', []) if o.get('code') == 'form.unknown-key.meta.inventada']
        case('contrato-reprova-nada-gravado', e and dcv.get('veredito') == 'REPROVADO' and dc.get('gravado') is False
             and dc.get('veredito') == 'REPROVADO'
             and dc.get('radar', {}).get('passou') is True and dc.get('contrato', {}).get('passou') is False
             and dc['contrato'].get('julgado') is True and dc['contrato'].get('codigos_must') == ['form.unknown-key.meta.inventada']
             and len(occ_c) == 1 and occ_c[0].get('level') == 'MUST' and occ_c[0].get('path') == 'meta'
             and isinstance(occ_c[0].get('line'), int) and occ_c[0].get('place') and occ_c[0].get('message')
             and not os.path.exists(os.path.join(area_a, 'demo-contrato'))
             and 'kgw-' not in json.dumps(pc), dc)  # o caminho dos diretórios temporários não vaza

        # (8b) PASS estruturado do contrato real; e a ocorrência que o schema acusa 2x (mesmo code+path) sai uma só
        _, pp = call(port, 'kg_validate', {'yaml': ok_yaml})
        cp_ = pp.get('data', {}).get('contrato', {})
        case('contrato-pass-estruturado', cp_.get('julgado') is True and cp_.get('passou') is True
             and cp_.get('veredito_contrato') == 'PASS' and cp_.get('codigos_must') == [] and cp_.get('ocorrencias') == []
             and cp_.get('total') == 0 and cp_.get('truncado') is False and cp_.get('dependentes') == [], cp_)
        dup = graph('demo-dup').replace('  baseline: "2026-10-12"\n', '  baseline: 2026-1-1\n')
        _, pd = call(port, 'kg_validate', {'yaml': dup})
        od = [o for o in pd.get('data', {}).get('contrato', {}).get('ocorrencias', []) if o.get('code') == 'form.pattern.meta.baseline']
        case('contrato-duplicata-fundida', pd.get('data', {}).get('veredito') == 'REPROVADO' and len(od) == 1
             and od[0].get('vezes') == 2 and od[0].get('path') == 'meta.baseline', pd.get('data', {}).get('contrato'))

        # (9) reprovado de usuário novo (pelo radar e pelo contrato) não cria nem a área
        before = sorted(os.listdir(root))
        call(port, 'kg_write', {'slug': 'demo-radar', 'yaml': bad_r}, user=C)
        call(port, 'kg_write', {'slug': 'demo-contrato', 'yaml': bad_c}, user=C)
        case('reprovado-nao-cria-area', sorted(os.listdir(root)) == before, os.listdir(root))

        # (10) slug: `..`, `/`, maiúscula, vazio → recusa, nada criado (meta.id = o próprio slug)
        outs = []
        for s in ('..', '../x', 'a/b', 'Demo', '', 'demo_ok', '-x'):
            e, ps = call(port, 'kg_write', {'slug': s, 'yaml': graph(s or 'x')})
            outs.append((s, e, ps.get('recusa', '')[:40]))
        case('slug-invalido-recusa', all(e and 'slug invalido' in r for _, e, r in outs)
             and sorted(x for x in os.listdir(area_a) if not x.startswith('.')) == ['demo-ok']
             and os.listdir(fora) == [], outs)

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
             and ga['data'].get('sha256') == hashlib.sha256(ok_yaml.encode()).hexdigest()
             and la['data']['area'] != lb['data']['area'], [sa, sb_, gb])
        area_b = os.path.join(root, lb.get('data', {}).get('area', '?'))

        # (13) symlink plantado: dir do slug → dentro e → fora da área; arquivo → fora; e a própria área → fora
        os.symlink(os.path.join(area_a, 'demo-ok'), os.path.join(area_a, 'evil-in'))
        os.mkdir(os.path.join(fora, 'evil-out'))
        os.symlink(os.path.join(fora, 'evil-out'), os.path.join(area_a, 'evil-out'))
        os.mkdir(os.path.join(area_a, 'evil-file'))
        with open(os.path.join(fora, 'segredo.kg.yaml'), 'w') as fh:
            fh.write('SEGREDO-FORA\n')
        os.symlink(os.path.join(fora, 'segredo.kg.yaml'), os.path.join(area_a, 'evil-file', 'evil-file.kg.yaml'))
        os.mkdir(os.path.join(fora, 'area-e'))
        os.symlink(os.path.join(fora, 'area-e'), area_of(root, E))
        r_in = call(port, 'kg_write', {'slug': 'evil-in', 'yaml': graph('evil-in')})
        r_out = call(port, 'kg_write', {'slug': 'evil-out', 'yaml': graph('evil-out')})
        r_file = call(port, 'kg_write', {'slug': 'evil-file', 'yaml': graph('evil-file')})
        g_file = call(port, 'kg_my_get', {'slug': 'evil-file'})
        r_area = call(port, 'kg_write', {'slug': 'demo-e', 'yaml': graph('demo-e')}, user=E)
        _, la2 = call(port, 'kg_my_list')
        listed = [g['slug'] for g in la2.get('data', {}).get('grafos', [])]
        case('symlink-plantado-recusa', all(r[0] and 'symlink' in r[1].get('recusa', '')
                                            for r in (r_in, r_out, r_file, g_file, r_area))
             and 'symlink na area' in r_area[1].get('recusa', '')
             and not os.path.exists(os.path.join(area_a, 'demo-ok', 'evil-in.kg.yaml'))
             and os.listdir(os.path.join(fora, 'evil-out')) == [] and os.listdir(os.path.join(fora, 'area-e')) == []
             and 'SEGREDO' not in json.dumps(g_file[1]) and listed == ['demo-ok'],
             [r_in[1].get('recusa'), r_out[1].get('recusa'), r_file[1].get('recusa'), r_area[1].get('recusa'), listed])
        for x in ('evil-in', 'evil-out', 'evil-file'):
            wipe(os.path.join(area_a, x))

        # (14) yaml acima do teto (grafo VÁLIDO com enchimento de comentário) → recusa, nada gravado
        big = graph('demo-big') + ('# enchimento\n' * 50000)
        e, pg = call(port, 'kg_write', {'slug': 'demo-big', 'yaml': big})
        case('yaml-acima-do-teto-recusa', len(big.encode()) > 512 * 1024 and e and 'teto' in pg.get('recusa', '')
             and not os.path.exists(os.path.join(area_a, 'demo-big')), pg.get('recusa'))

        # (15) âncora/alias de escalar (sem indício de aninhamento: chega ao compositor) → recusa antes de qualquer gate
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

        # (a) o GitStore enxerga SÓ o rastreado: arquivo plantado sem commit não lista, não lê e não é ponta externa
        os.mkdir(os.path.join(area_a, 'fantasma'))
        with open(os.path.join(area_a, 'fantasma', 'fantasma.kg.yaml'), 'w', encoding='utf-8') as fh:
            fh.write(graph('fantasma'))
        _, lf = call(port, 'kg_my_list')
        ef, gf = call(port, 'kg_my_get', {'slug': 'fantasma'})
        _, vf = call(port, 'kg_validate', {'yaml': graph('demo-aponta-fantasma', external=ext('fantasma/fantasma.kg.yaml#C_ALVO'))})
        cf = vf.get('data', {}).get('contrato', {})
        case('store-so-rastreado', [g['slug'] for g in lf.get('data', {}).get('grafos', [])] == ['demo-ok']
             and ef and 'inexistente' in gf.get('recusa', '')
             and vf.get('data', {}).get('veredito') == 'REPROVADO' and 'integrity.dangling-external' in cf.get('codigos_must', []),
             [lf.get('data'), gf, cf])
        wipe(os.path.join(area_a, 'fantasma'))

        # (b) StoreError = NÃO gravado → recusa nomeada (o .git/info da área de B vira symlink para fora)
        info_b = os.path.join(area_b, '.git', 'info')
        n_b = commits(area_b)
        if os.path.isdir(info_b) and not os.path.islink(info_b):
            shutil.move(info_b, os.path.join(base, 'info-b'))
        os.mkdir(os.path.join(fora, 'info'))
        wipe(info_b)
        os.symlink(os.path.join(fora, 'info'), info_b)
        e, psb = call(port, 'kg_write', {'slug': 'demo-b2', 'yaml': graph('demo-b2')}, user=B)
        rb = psb.get('recusa', '')
        case('store-error-recusa-nomeada', e and 'armazem recusou' in rb and '.git/info' in rb and psb.get('gravado') is False
             and root not in rb and base not in rb and os.path.basename(area_b) not in rb  # o caminho do servidor não vaza
             and commits(area_b) == n_b and not os.path.exists(os.path.join(area_b, 'demo-b2'))
             and os.listdir(os.path.join(fora, 'info')) == [], psb)
        wipe(info_b)
        if os.path.isdir(os.path.join(base, 'info-b')):
            shutil.move(os.path.join(base, 'info-b'), info_b)

        # (e) aresta externa entre grafos da MESMA área: julgada contra a área (aceita), e ponta fora da área reprova
        ext_ok = graph('demo-ext', external=ext('demo-ok/demo-ok.kg.yaml#C_ALVO'))
        e, pe = call(port, 'kg_write', {'slug': 'demo-ext', 'yaml': ext_ok})
        de = pe.get('data', {})
        case('externa-na-area-aprova', not e and de.get('gravado') is True and de.get('veredito') == 'APROVADO'
             and de.get('contrato', {}).get('julgado') is True
             and os.path.isfile(os.path.join(area_a, 'demo-ext', 'demo-ext.kg.yaml')), de)
        e, pn = call(port, 'kg_write', {'slug': 'demo-ext2', 'yaml': graph('demo-ext2', external=ext('demo-ok/demo-ok.kg.yaml#C_NAO_EXISTE'))})
        dn = pn.get('data', {})
        case('externa-no-inexistente-reprova', e and dn.get('gravado') is False and dn.get('veredito') == 'REPROVADO'
             and 'integrity.dangling-external' in dn.get('contrato', {}).get('codigos_must', [])
             and not os.path.exists(os.path.join(area_a, 'demo-ext2')), dn)
        fuga = []
        for to in ('docs/x/y.kg.yaml#C_VELHA',                     # do core: não existe na área
                   'demo-b/demo-b.kg.yaml#C_ALVO',                 # de OUTRO usuário (existe na área de B)
                   '../' + os.path.basename(area_b) + '/demo-b/demo-b.kg.yaml#C_ALVO'):  # subindo de pasta
            e, pf = call(port, 'kg_write', {'slug': 'demo-fuga', 'yaml': graph('demo-fuga', external=ext(to))})
            df = pf.get('data', {})
            fuga.append((to, e, df.get('veredito'), df.get('contrato', {}).get('codigos_must')))
        case('externa-fora-da-area-reprova', all(e and v == 'REPROVADO' and cm for _, e, v, cm in fuga)
             and 'integrity.dangling-external' in fuga[0][3] and 'integrity.dangling-external' in fuga[1][3]
             and not os.path.exists(os.path.join(area_a, 'demo-fuga')), fuga)

        # (e) regravar o apontado tirando o nó-alvo rejulga quem aponta: reprova, com o dependente nomeado
        sem_alvo = graph('demo-ok').replace('C_ALVO', 'C_OUTRO')
        e, pdp = call(port, 'kg_write', {'slug': 'demo-ok', 'yaml': sem_alvo})
        ddp = pdp.get('data', {})
        deps = ddp.get('contrato', {}).get('dependentes', [])
        with open(f, encoding='utf-8') as fh:
            ainda = fh.read()
        case('dependente-rejulgado-na-regravacao', e and ddp.get('gravado') is False and ddp.get('veredito') == 'REPROVADO'
             and [x.get('grafo') for x in deps] == ['demo-ext/demo-ext.kg.yaml']
             and 'integrity.dangling-external' in deps[0].get('codigos_must', []) and ainda == ok_yaml, ddp)

        # delete: bloqueado por dependente; removido com commit de remoção; inexistente e de outro usuário recusados
        n_a = commits(area_a)
        e, pdb = call(port, 'kg_delete', {'slug': 'demo-ok'})
        ddb = pdb.get('data', {})
        case('delete-bloqueado-por-dependente', e and ddb.get('removido') is False and ddb.get('veredito') == 'REPROVADO'
             and [x.get('grafo') for x in ddb.get('contrato', {}).get('dependentes', [])] == ['demo-ext/demo-ext.kg.yaml']
             and os.path.isfile(f) and commits(area_a) == n_a, ddb)
        e, pdl = call(port, 'kg_delete', {'slug': 'demo-ext'})
        ddl = pdl.get('data', {})
        _, st = git_out(area_a, 'log', '-1', '--name-status', '--format=%ae %s')
        case('delete-remove-com-commit', not e and ddl.get('removido') is True and ddl.get('commit')
             and commits(area_a) == n_a + 1 and st.split() == [A, 'kg_delete:', 'demo-ext', 'D', 'demo-ext/demo-ext.kg.yaml']
             and not os.path.exists(os.path.join(area_a, 'demo-ext', 'demo-ext.kg.yaml')), [ddl, st])
        e1, pdi = call(port, 'kg_delete', {'slug': 'nao-existe'})
        e2, pdo = call(port, 'kg_delete', {'slug': 'demo-ok'}, user=B)
        e3, pdn = call(port, 'kg_delete', {'slug': 'demo-ok', 'expected_sha256': 'new'})  # "new" não serve para remover
        case('delete-inexistente-e-de-outro-recusa', e1 and e2 and e3 and 'inexistente' in pdi.get('recusa', '')
             and 'inexistente' in pdo.get('recusa', '') and 'nao serve para remover' in pdn.get('recusa', '')
             and os.path.isfile(f), [pdi, pdo, pdn])

        # trava otimista: expected_sha256 que não bate → CONFLITO, nada gravado; o certo grava
        v2 = graph('demo-ok', node_extra='    narrative: "segunda versao"\n')
        n_a = commits(area_a)
        e, pcf = call(port, 'kg_write', {'slug': 'demo-ok', 'yaml': v2, 'expected_sha256': '0' * 64})
        e_ok, pcok = call(port, 'kg_write', {'slug': 'demo-ok', 'yaml': v2,
                                             'expected_sha256': hashlib.sha256(ok_yaml.encode()).hexdigest()})
        case('conflito-expected-sha256', e and pcf.get('data', {}).get('veredito') == 'CONFLITO'
             and pcf['data'].get('gravado') is False and not e_ok and pcok.get('data', {}).get('gravado') is True
             and commits(area_a) == n_a + 1, [pcf.get('data'), pcok.get('data', {}).get('gravado')])

        # migração: área no layout do writer de antes do GitStore (repo git, branch main, slug/slug.kg.yaml
        # rastreado, committer do serviço, resto de .kgw- não rastreado) abre sem reescrever histórico
        area_d = area_of(root, D)
        os.mkdir(area_d, 0o700)
        subprocess.run([*GIT, 'init', '-q', area_d], check=True, capture_output=True)
        os.mkdir(os.path.join(area_d, 'antigo'))
        with open(os.path.join(area_d, 'antigo', 'antigo.kg.yaml'), 'w', encoding='utf-8') as fh:
            fh.write(graph('antigo'))
        with open(os.path.join(area_d, 'antigo', '.kgw-resto'), 'w') as fh:
            fh.write('resto\n')
        envd = dict(os.environ, GIT_COMMITTER_NAME='onion-kg-writer', GIT_COMMITTER_EMAIL='onion-kg-writer@localhost')
        subprocess.run([*GIT, '-C', area_d, 'add', '--', 'antigo/antigo.kg.yaml'], check=True, capture_output=True)
        subprocess.run([*GIT, '-C', area_d, 'commit', '-q', '--author', f'dora <{D}>', '-m', 'kg_write: antigo'],
                       check=True, capture_output=True, env=envd)
        _, old_head = git_out(area_d, 'rev-parse', 'HEAD')
        _, ld = call(port, 'kg_my_list', user=D)
        _, gd = call(port, 'kg_my_get', {'slug': 'antigo'}, user=D)
        e, wd = call(port, 'kg_write', {'slug': 'novo', 'yaml': graph('novo')}, user=D)
        anc = subprocess.run(['git', '-C', area_d, 'merge-base', '--is-ancestor', old_head, 'HEAD']).returncode
        _, roots = git_out(area_d, 'rev-list', '--max-parents=0', 'HEAD')
        _, br = git_out(area_d, 'symbolic-ref', '--short', 'HEAD')
        case('migracao-area-antiga', [g['slug'] for g in ld.get('data', {}).get('grafos', [])] == ['antigo']
             and gd.get('data', {}).get('conteudo') == graph('antigo') and not e and wd.get('data', {}).get('gravado') is True
             and anc == 0 and roots == old_head and commits(area_d) == 2 and br == 'main', [ld.get('data'), wd.get('data'), roots, old_head])

        # profundidade: cada classe é recusada SEM compor, com o processo vivo depois
        fundo = {
            'profundidade-colchete': 'a: ' + '[' * 30000 + ']' * 30000 + '\n',
            'profundidade-bloco-traco': 'meta:\n  x_deep:\n    ' + '- ' * 30000 + 'x\n',
            'profundidade-bloco-interrogacao': '? ' * 30000 + 'x\n',
            'profundidade-indentacao': 'a:\n' + ''.join(' ' * i + '-\n' for i in range(1000)),
            'profundidade-quebra-cr': 'meta:\r  x_deep:\r    ' + '- ' * 30000 + 'x\r',
            'profundidade-quebra-nel': 'meta:\x85  x_deep:\x85    ' + '- ' * 30000 + 'x\x85',
            'profundidade-quebra-ls': 'meta:\u2028  x_deep:\u2028    ' + '- ' * 30000 + 'x\u2028',
            'profundidade-quebra-ps': 'meta:\u2029  x_deep:\u2029    ' + '- ' * 30000 + 'x\u2029',
            'profundidade-tab-inicial': 'a:\t1\nb: ' + '[' * 30000 + ']' * 30000 + '\n',
        }
        for nm, txt in fundo.items():
            e, pz = call(port, 'kg_write', {'slug': 'demo-fundo', 'yaml': txt})
            case(nm, len(txt.encode()) <= 512 * 1024 and e and 'aninhamento acima do teto' in pz.get('recusa', '')
                 and alive(srv, port) and not os.path.exists(os.path.join(area_a, 'demo-fundo')), pz.get('recusa'))
        bomb = ['a0: &a0 [x, x, x, x, x, x, x, x, x, x]']
        bomb += [f'a{i}: &a{i} [' + ', '.join([f'*a{i - 1}'] * 10) + ']' for i in range(1, 9)]
        bomb = '\n'.join(bomb + ['z: [' + ', '.join(['*a8'] * 10) + ']']) + '\n'
        e, pz = call(port, 'kg_validate', {'yaml': bomb, 'slug': 'demo-bomba'})
        # sem indício de aninhamento (10 colchetes) a bomba chega ao compositor, que recusa na 1a âncora sem expandir
        case('bomba-de-alias-recusada', e and re.search(r'ancora|alias', pz.get('recusa', '')) and alive(srv, port),
             pz.get('recusa'))
        # com indício (um comentário com 20 colchetes), o stream recusa a 1a âncora antes de chegar ao compositor
        e, pz = call(port, 'kg_validate', {'yaml': '# ' + '[' * 20 + '\n' + bomb, 'slug': 'demo-bomba'})
        case('bomba-de-alias-recusada-no-stream', e and 'antes da composicao' in pz.get('recusa', '') and alive(srv, port),
             pz.get('recusa'))
        # inteiro com mais dígitos que o teto do Python (4.300) sobe ValueError, não YAMLError: vira parse, não erro interno
        e, pz = call(port, 'kg_validate', {'yaml': graph('demo-int', extra_meta='  x_n: 1' + '0' * 5000 + '\n'), 'slug': 'demo-int'})
        dz = pz.get('data', {})
        case('inteiro-gigante-nao-derruba', dz.get('veredito') == 'REPROVADO' and 'nao parseia' in dz.get('parse', '')
             and alive(srv, port), pz)
        # polaridade: colchete DENTRO de escalar não é aninhamento (o indício dispara, o stream mede e aprova)
        esc = graph('demo-colchete', narrative='    narrative: "' + '[' * 1001 + '"\n')
        _, pz = call(port, 'kg_validate', {'yaml': esc})
        case('colchete-em-escalar-aprova', pz.get('data', {}).get('veredito') == 'APROVADO' and alive(srv, port), pz)

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
            e1, pu = call(port2, 'kg_write', {'slug': 'um', 'yaml': graph('um', node_extra='    narrative: "v2"\n')})
            case('area-cheia-recusa', e and 'area cheia' in pf.get('recusa', '') and not e1
                 and pu.get('data', {}).get('gravado') is True, [pf, pu.get('data', {}).get('gravado')])
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

        # (18) code root FALSO: o fail-closed do veredito do armazém e a decisão por code
        fr = fake_code_root(base)
        root4 = os.path.join(base, 'data4')
        os.mkdir(root4)
        p4 = start({'ONION_KG_WRITER_ROOT': root4, 'ONION_KG_CODE_ROOT': fr})
        port4, line4 = wait_port(p4)
        tools_f = os.path.join(fr, 'vendor', 'kg-ssot', 'tools')

        def fake(mode, tool='kg_write'):
            with open(os.path.join(tools_f, 'mode'), 'w') as fh:
                fh.write(mode)
            if os.path.exists(os.path.join(tools_f, 'count')):
                os.remove(os.path.join(tools_f, 'count'))
            e, pz = call(port4, tool, {'slug': 'demo-ok', 'yaml': ok_yaml})
            return e, pz.get('data', {}), pz
        nomes = ['contrato-stub-aprova', 'armazem-nao-julga-recusa', 'armazem-not-judged-na-gravacao',
                 'contrato-versao-desconhecida-recusa', 'contrato-incoerente-recusa',
                 'contrato-externo-nao-conferido-recusa', 'contrato-decide-por-code']
        if port4 is None:
            for nm in nomes:
                case(nm, False, line4)
        else:
            def no_files():
                return not any(fn.endswith('.kg.yaml') for _, _, fs in os.walk(root4) for fn in fs)
            # controle de polaridade: o MESMO harness aprova quando o veredito é um PASS válido
            e, dz, _ = fake('pass')
            case('contrato-stub-aprova', not e and dz.get('gravado') is True and dz.get('veredito') == 'APROVADO', dz)
            shutil.rmtree(root4)
            os.mkdir(root4)
            e, dz, _ = fake('raise', 'kg_validate')
            case('armazem-nao-julga-recusa', dz.get('veredito') == 'NAO JULGADO' and dz.get('contrato', {}).get('julgado') is False
                 and 'julgamento falso quebrou' in dz.get('contrato', {}).get('motivo', '') and no_files(), dz)
            e, dz, raw = fake('raise-2nd')
            case('armazem-not-judged-na-gravacao', e and dz.get('gravado') is False and dz.get('veredito') == 'NAO JULGADO'
                 and 'quebrou na gravacao' in dz.get('contrato', {}).get('motivo', '') and no_files(), raw)
            for nm, mode, motivo in (('contrato-versao-desconhecida-recusa', 'versao-2', 'kg-ssot.verdict/2'),
                                     ('contrato-incoerente-recusa', 'incoerente', 'incoerente'),
                                     ('contrato-externo-nao-conferido-recusa', 'externo', 'external_edges')):
                e, dz, _ = fake(mode)
                cz = dz.get('contrato', {})
                case(nm, e and dz.get('gravado') is False and dz.get('veredito') == 'NAO JULGADO'
                     and cz.get('julgado') is False and motivo in cz.get('motivo', '') and no_files(), dz)
            e, dz, _ = fake('message', 'kg_validate')
            cz = dz.get('contrato', {})
            case('contrato-decide-por-code', dz.get('veredito') == 'REPROVADO'
                 and cz.get('julgado') is True and cz.get('codigos_must') == ['form.unknown-key.meta.x']
                 and [o.get('message') for o in cz.get('ocorrencias', [])] == ['PASS: tudo certo'] and no_files(), dz)
    finally:
        stop_all()
        shutil.rmtree(base, ignore_errors=True)
    print(f'TOTAL {len(RESULTS)} ({time.time() - T0:.1f}s)', flush=True)


if __name__ == '__main__':
    try:
        main()
    except _Until:
        pass
    finally:
        stop_all()
    sys.exit(0 if RESULTS and all(ok for _, ok in RESULTS) else 1)
