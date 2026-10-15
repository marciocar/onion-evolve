#!/usr/bin/env bash
# =============================================================================
# a2a-invite.sh — o convite A2A POR MEMBRO: cria, revoga, lista e confere o arquivo de convites do bridge.
#
# F2 do configurador A2A (SAC-123; plano e decisões no grafo docs/evolution/research/a2a-configurator-2026-10/,
# nós D_CONVITE_POR_MEMBRO_COM_VALIDADE e C_AMARRACAO_DO_CONVITE_ANTES_DO_GATE). Antes, o convite era um
# bearer ANÔNIMO no ambiente do bridge (pool INVITE_TOKENS_A2A): sem dono, sem validade, e cada convite
# novo pedia restart. Agora o bridge lê, a cada POST /a2a, um arquivo (A2A_INVITES_FILE) em que cada
# convite amarra o SHA-256 do token a UM membro e a UM receptor, com validade e revogação:
#   { "version": 1,
#     "invites": [ { "token_sha256": "<64 hex>", "member": "<id>", "receiver": "<id do receptor>",
#                    "expires_at": "<ISO 8601 com hora e fuso>", "revoked": false } ] }
# Este motor julga o arquivo pelas MESMAS regras do bridge (forma, dono, permissão, diretório) e só o
# escreve por temporário no MESMO diretório + rename, em 0600, com trava no diretório.
#
# SEGREDO: o token nasce de /dev/urandom direto no arquivo 0600 do --token-out (O_EXCL, sem seguir
# symlink) e NUNCA passa por stdout, stderr, argv ou log. No arquivo de convites mora só o hash. Com
# --token-stdin o token chega por redirecionamento de arquivo (o caminho do `sudo -u <conta do serviço>`:
# quem abre o arquivo é o shell do operador, e o processo do serviço lê só o descritor).
#
# USO
#   a2a-invite.sh create <member> --days N --file <invites.json> (--token-out <arq> | --token-stdin)
#                 [--receiver <id>] [--invite-out <arq>] [--members <members.yaml>] [--dry-run]
#   a2a-invite.sh revoke <member> --file <invites.json> [--receiver <id>] [--dry-run]
#   a2a-invite.sh list   --file <invites.json> [--member <id>] [--receiver <id>] [--invite <descritor>]
#                 [--owner <uid|nome>] [--json]
#   a2a-invite.sh check  --file <invites.json> [--owner <uid|nome>] [--json]
#   a2a-invite.sh inspect --invite <descritor> --member <id> [--receiver <id>] [--token-file <arq>] [--json]
#
#   list/check saem pelo estado do ARQUIVO (forma, dono, 0600, entradas que nunca autenticam); com
#   --member ou --invite, list acrescenta a "sonda": o motivo que o guard do bridge daria ao bearer
#   daquele membro (ok, convite-revogado, convite-vencido, convite-de-outro-membro…), sem ler token.
#   inspect julga o descritor que viaja com o token (lado do membro): rc 0 só se ele está de pé e, com
#   --token-file, se o sha256 do token bate com o do descritor (calculado no processo, nunca impresso).
#
#   --days        validade em dias (1..365); expires_at sai em UTC, ISO 8601 com hora e "Z"
#   --token-out   arquivo NOVO onde o token nasce (0600; recusa se existe ou se seria versionável)
#   --token-stdin lê o token (≥ 32 caracteres de [A-Za-z0-9._~+/=-]) da entrada, que tem de ser arquivo
#                 ou pipe, nunca terminal
#   --invite-out  descritor sem segredo {member, receiver, expires_at, revoked, token_sha256} que viaja
#                 com o token e alimenta o doctor; default <token-out>.invite.json com --token-out
#   --receiver    default: o membro kind: source do registro (o core); sem registro, obrigatório. Com registro
#                 (F3), o receptor tem de receber (role source ou hub, nunca porta), e convite para um hub
#                 é só para filho dele (parent: <hub>): o gate e a topologia recusariam o resto
#   --members     default <raiz>/docs/evolution/federation/members.yaml; o membro tem de estar nele
#   --owner       list/check: o dono que o bridge exige (default: quem roda). Rode como a conta do
#                 serviço do bridge (sudo -u <conta>): o arquivo é 0600 dela
#   --dry-run     create/revoke: mostra a entrada que mudaria e NÃO escreve nada (nem o token)
#
# EXIT (molde do a2a-doctor.sh): 0 ok · 1 problema medido ou escrita recusada · 2 não pude medir
#   (arquivo ilegível para esta conta, trava ocupada, ferramenta ausente) · 3 uso inválido
# Exercitado por lint-selftest.sh (run_federation_a2a_selftests).
# MOAT-ARG-WRITER: create,revoke --file,--invite-out,--token-out
#   (o veto do MOAT lê esta linha: o valor destas opções nestes subcomandos é julgado como destino de escrita)
# =============================================================================
set -uo pipefail
case "${1:-}" in -h|--help|'') sed -n '/^# USO/,/^# EXIT/p' "$0" | sed 's/^# \{0,1\}//' >&2; [ -n "${1:-}" ] && exit 0; exit 3 ;; esac
command -v python3 >/dev/null 2>&1 || { echo "a2a-invite: ferramenta ausente: python3" >&2; exit 2; }
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(env -u GIT_DIR -u GIT_WORK_TREE git -C "${HERE}" rev-parse --show-toplevel 2>/dev/null || (cd "${HERE}/../../.." && pwd))"
# o programa vai por -c (argv só leva o CÓDIGO e os caminhos): o stdin fica livre para o --token-stdin
read -r -d '' PROG <<'PY' || true
import sys, os, json, re, stat, errno, time, datetime, hashlib, subprocess
try:
    import fcntl
except ImportError:
    fcntl = None

NAME = "a2a-invite"
ID_RE = re.compile(r'^[A-Za-z0-9_-][A-Za-z0-9._-]*$')          # a régua do keygen e do gate, sem '.' inicial
HEX64 = re.compile(r'^[0-9a-f]{64}$')
# a MESMA forma do bridge (ISO_DATETIME em a2a-invites.ts), com [0-9] e não \d: em Python o \d casa
# dígitos Unicode, e o \d do JavaScript não.
ISO = re.compile(r'^([0-9]{4})-([0-9]{2})-([0-9]{2})T([0-9]{2}):([0-9]{2})(?::([0-9]{2})(\.[0-9]{1,9})?)?(Z|([+-])([0-9]{2}):([0-9]{2}))$')
TOKEN_RE = re.compile(r'^[A-Za-z0-9._~+/=-]{32,}$')
MIN_TOKEN = 32   # MIN_MEMBER_TOKEN_LEN do bridge

class Stop(Exception):
    def __init__(self, rc, msg): self.rc, self.msg = rc, msg

def stop(rc, msg): raise Stop(rc, msg)

def parse_iso(s):
    """epoch (float) se a validade tem a forma que o bridge aceita; None se não (o bridge: convite-invalido)."""
    if not isinstance(s, str): return None
    m = ISO.fullmatch(s)   # fullmatch: o $ do Python casa antes de um \n final, o do JavaScript não (refutador)
    if not m: return None
    y, mo, d, h, mi = (int(m.group(i)) for i in range(1, 6))
    sec = int(m.group(6) or 0); frac = int(((m.group(7) or '.0')[1:] + '00')[:3]) / 1000.0   # V8 trunca em ms
    # os limites do Date.parse do V8, MEDIDOS (node 22, 2026-10-15): mês 1..12; dia 1..31 com rolagem
    # (02-30 vira 03-02); 24:00 só com minutos, segundos e fração zerados; fuso até 23:59.
    if not (1 <= mo <= 12 and 1 <= d <= 31 and mi <= 59 and sec <= 59): return None
    fdig = (m.group(7) or '.')[1:]
    if h > 24 or (h == 24 and (mi or sec or fdig.strip('0'))): return None   # a fração CRUA, não a truncada em ms (refutador)
    if m.group(8) == 'Z': off = 0
    else:
        oh, om = int(m.group(10)), int(m.group(11))
        if oh > 23 or om > 59: return None
        off = (oh * 60 + om) * (1 if m.group(9) == '+' else -1)
    # dias desde 1970-01-01 pelo calendário gregoriano proléptico (days_from_civil): sem datetime, que
    # não conhece o ano 0 que o Date.parse aceita, e sem `date -d`, que só existe no GNU
    yy = y - (1 if mo <= 2 else 0); era = (yy if yy >= 0 else yy - 399) // 400; yoe = yy - era * 400
    doy = (153 * (mo + (-3 if mo > 2 else 9)) + 2) // 5; doe = yoe * 365 + yoe // 4 - yoe // 100 + doy
    days = era * 146097 + doe - 719468 + (d - 1)
    return days * 86400 + h * 3600 + mi * 60 + sec - off * 60 + frac

def iso_utc(epoch):
    return datetime.datetime.fromtimestamp(int(epoch), datetime.timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')

def reject_constant(c): raise ValueError(c)   # NaN/Infinity: o JSON.parse do bridge recusa

def is_one(v):  # `doc.version !== 1` no JavaScript: true e "1" NÃO valem; 1.0 vale (é o mesmo número)
    return isinstance(v, (int, float)) and not isinstance(v, bool) and v == 1

def parse_doc(text):
    """('ok', doc) | ('error', detalhe) — os detalhes têm os nomes do bridge (parseInvites)."""
    try:
        doc = json.loads(text, parse_constant=reject_constant)
    except RecursionError:
        return 'unmeasured', 'json-aninhado-demais-para-este-leitor'   # o JSON.parse do Node lê: não sei ≠ quebrado
    except ValueError:
        return 'error', 'json-invalido'
    if not isinstance(doc, dict): return 'error', 'raiz-nao-objeto'
    if not is_one(doc.get('version')): return 'error', 'versao-desconhecida'
    if not isinstance(doc.get('invites'), list): return 'error', 'invites-nao-lista'
    return 'ok', doc

def resolve_uid(owner):
    if owner is None or owner == '': return os.geteuid()
    if owner.isdigit(): return int(owner)
    try:
        import pwd
        return pwd.getpwnam(owner).pw_uid
    except Exception:
        stop(3, f"--owner desconhecido: {owner}")

def load(path, uid):
    """Lê como o bridge lê (createInviteStore.load): O_NOFOLLOW|O_NONBLOCK, fstat no descritor, dono,
    permissão do arquivo e do diretório. → dict(state=ok|absent|error|unreadable, detail, doc, st, raw)"""
    try:
        fd = os.open(path, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK)
    except OSError as e:
        if e.errno == errno.ENOENT: return {'state': 'absent', 'detail': 'ausente'}
        if e.errno == errno.ELOOP: return {'state': 'error', 'detail': 'symlink-recusado'}
        if e.errno in (errno.EACCES, errno.EPERM): return {'state': 'unreadable', 'detail': 'sem-permissao-de-leitura'}
        return {'state': 'error', 'detail': 'ilegivel'}
    try:
        st = os.fstat(fd)
        if not stat.S_ISREG(st.st_mode): return {'state': 'error', 'detail': 'nao-regular', 'st': st}
        if st.st_uid != uid: return {'state': 'error', 'detail': 'dono-diferente-do-processo', 'st': st}
        if st.st_mode & 0o022: return {'state': 'error', 'detail': 'gravavel-por-grupo-ou-outros', 'st': st}
        try:
            dst = os.stat(os.path.dirname(os.path.abspath(path)))
        except OSError:
            return {'state': 'error', 'detail': 'diretorio-inseguro', 'st': st}
        if (dst.st_uid != uid and dst.st_uid != 0) or (dst.st_mode & 0o022):
            return {'state': 'error', 'detail': 'diretorio-inseguro', 'st': st}
        chunks = []
        while True:
            b = os.read(fd, 65536)
            if not b: break
            chunks.append(b)
        raw = b''.join(chunks)
    except OSError:
        return {'state': 'error', 'detail': 'ilegivel'}
    finally:
        os.close(fd)
    state, val = parse_doc(raw.decode('utf-8', errors='replace'))   # o readFileSync utf8 do Node troca, não quebra
    if state != 'ok': return {'state': state, 'detail': val, 'st': st, 'raw': raw}
    return {'state': 'ok', 'detail': '', 'doc': val, 'st': st, 'raw': raw}

def entry_hash(e):
    """o hash como o bridge o vê; None = entrada que nunca casa (o bridge a ignora)."""
    if not isinstance(e, dict) or not isinstance(e.get('token_sha256'), str): return None
    h = e['token_sha256'].lower()
    return h if HEX64.fullmatch(h) else None

def own_state(e, now):
    """estado da entrada sozinha, na ORDEM das checagens do decide() do bridge."""
    if entry_hash(e) is None: return 'ignorada', 'sem token_sha256 de 64 hex: nunca autentica'
    if e.get('revoked') is not False:
        return ('revogado', 'revoked: true') if e.get('revoked') is True else ('revogado', 'revoked não é false literal: o bridge o trata como revogado')
    exp = parse_iso(e.get('expires_at'))
    if exp is None: return 'invalido', 'expires_at fora da forma ISO 8601 com hora e fuso'
    if exp <= now: return 'vencido', 'expires_at no passado'
    if not isinstance(e.get('member'), str) or e.get('member') == '': return 'invalido', 'member ausente ou não texto'
    if not isinstance(e.get('receiver'), str) or e.get('receiver') == '': return 'invalido', 'receiver ausente ou não texto'
    return 'ativo', ''

def decide(group, frm, receiver, now):
    """o decide() do bridge para um bearer cujo hash casa com `group`: 'ok' ou o motivo do 401."""
    if not group: return 'credencial-desconhecida'
    if not isinstance(frm, str) or frm == '': return 'remetente-ausente'
    for e in group:
        if e.get('revoked') is not False: return 'convite-revogado'
        exp = parse_iso(e.get('expires_at'))
        if exp is None: return 'convite-invalido'
        if exp <= now: return 'convite-vencido'
        if not isinstance(e.get('member'), str) or e.get('member') == '': return 'convite-invalido'
        if e.get('receiver') != receiver: return 'convite-de-outro-receptor'
        if e.get('member') != frm: return 'convite-de-outro-membro'
    return 'ok'

def groups_of(doc):
    g = {}
    for e in doc['invites']:
        h = entry_hash(e)
        if h is not None: g.setdefault(h, []).append(e)
    return g

def describe(doc, now):
    g = groups_of(doc); out = []; memo = {}
    for e in doc['invites']:
        h = entry_hash(e); st, why = own_state(e, now)
        if h:   # um decide por (grupo, membro, receptor): por entrada era quadrático com hash repetido (refutador)
            k = (h, json.dumps(e.get('member')), json.dumps(e.get('receiver')))
            if k not in memo: memo[k] = decide(g.get(h, []), e.get('member'), e.get('receiver'), now)
            eff = memo[k]
        else: eff = 'nunca-casa'
        if st == 'ativo' and eff != 'ok':
            st, why = 'derrubado', f'hash repetido com outra entrada: o bridge responde {eff}'
        ee = e if isinstance(e, dict) else {}
        out.append({'id': (h or '-')[:12], 'member': ee.get('member'), 'receiver': ee.get('receiver'),
                    'expires_at': ee.get('expires_at'), 'state': st, 'why': why, 'bridge': eff})
    return out

def registry(path):
    """→ (ids:set|None, source:str|None, motivo). None = registro indisponível (não medido)."""
    if not path or not os.path.isfile(path): return None, None, 'registro ausente'
    try:
        import yaml
    except ImportError:
        return None, None, 'PyYAML ausente'
    try:
        ms = (yaml.safe_load(open(path)) or {}).get('members') or []
    except Exception:
        return None, None, 'registro ilegível'
    ids = {m.get('id') for m in ms if isinstance(m, dict)}
    src = [m.get('id') for m in ms if isinstance(m, dict) and m.get('kind') == 'source']
    return ids, (src[0] if src else None), ''

def registry_by_id(path):
    """→ {id: entrada} do registro, ou None quando indisponível (o mesmo julgamento de registry())."""
    try:
        import yaml
        ms = (yaml.safe_load(open(path)) or {}).get('members') or []
    except Exception:
        return None
    return {m.get('id'): m for m in ms if isinstance(m, dict) and isinstance(m.get('id'), str)}

def receiver_problem(bym, member, receiver):
    """F3: o receptor do convite tem de RECEBER (role source|hub, nunca porta), e convite para um hub é só
    para filho dele (parent: <hub>) — é o que o gate do core e a topologia aceitam. None = ok."""
    r = bym.get(receiver)
    if r is None: return f"receptor '{receiver}' não está no registro"
    # o MESMO critério do gate (camada receiver) e do bridge: role source ou hub, nunca porta
    if r.get('role') not in ('source', 'hub') or r.get('kind') == 'door':
        return f"'{receiver}' (role '{r.get('role')}', kind '{r.get('kind')}') não é receptor: só role source ou hub, e nunca porta"
    if r.get('role') == 'hub':
        par = (bym.get(member) or {}).get('parent')
        if par != receiver:
            return f"convite para o hub '{receiver}' é só para filho dele (parent: {receiver}); '{member}' tem parent '{par}'"
    return None

def git_unignored(path):
    """True quando `path` cai numa árvore git sem ser ignorado (um `git add -A` o levaria ao commit)."""
    d = os.path.dirname(os.path.abspath(path))
    try:
        env = {k: v for k, v in os.environ.items() if k not in ('GIT_DIR', 'GIT_WORK_TREE')}
        inside = subprocess.run(['git', '-C', d, 'rev-parse', '--is-inside-work-tree'], env=env,
                                stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode == 0
        if not inside: return False
        return subprocess.run(['git', '-C', d, 'check-ignore', '-q', os.path.abspath(path)], env=env,
                              stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode != 0
    except FileNotFoundError:
        return False

def new_secret_file(path, data):
    """arquivo NOVO, 0600 desde o nascimento, sem seguir symlink e sem sobrescrever (O_EXCL)."""
    try:
        fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW, 0o600)
    except FileExistsError:
        stop(1, f"{path} já existe, recuso sobrescrever")
    except OSError as e:
        stop(2, f"não consegui criar {path}: {e.strerror}")
    try:
        os.fchmod(fd, 0o600)
        os.write(fd, data); os.fsync(fd)
    finally:
        os.close(fd)

class Writer:
    """escrita do arquivo de convites: trava no DIRETÓRIO (sem arquivo extra ao lado do do bridge),
    leitura sob a trava, temporário 0600 no mesmo diretório, conferência de que ninguém trocou o
    arquivo por fora da trava, rename atômico e fsync do diretório."""
    def __init__(self, path):
        self.path = os.path.abspath(path); self.dir = os.path.dirname(self.path); self.uid = os.geteuid()
        if fcntl is None: stop(2, "fcntl ausente: não sei travar o diretório")
        try:
            self.dfd = os.open(self.dir, os.O_RDONLY | getattr(os, 'O_DIRECTORY', 0))
        except OSError as e:
            stop(2 if e.errno in (errno.EACCES, errno.EPERM) else 1, f"diretório do arquivo inacessível ({self.dir}): {e.strerror}")
        for _ in range(50):
            try:
                fcntl.flock(self.dfd, fcntl.LOCK_EX | fcntl.LOCK_NB); break
            except OSError:
                time.sleep(0.1)
        else:
            stop(2, "outro escritor segura a trava do diretório há 5 s; tente de novo")
        dst = os.fstat(self.dfd)
        if self.uid == 0:
            stop(1, "rodando como root: o arquivo nasceria de root e o bridge o recusaria inteiro (dono-diferente-do-processo); rode como a conta do serviço (sudo -u <conta>)")
        if not os.access(self.dir, os.W_OK | os.X_OK):
            stop(2, f"esta conta não escreve no diretório {self.dir}: rode como a conta do serviço do bridge (sudo -u <conta>)")
        if dst.st_mode & 0o022:
            stop(1, f"o diretório {self.dir} é gravável por grupo/outros: o bridge recusaria todo convite (diretorio-inseguro)")
        if dst.st_uid not in (self.uid, 0):
            stop(1, f"o diretório {self.dir} é de outra conta (uid {dst.st_uid}): rode como a conta do serviço do bridge")
        # sob a trava, um temporário deste motor só pode ser de um processo morto (kill -9): varre
        pre = f".{os.path.basename(self.path)}."
        for n in os.listdir(self.dir):
            if n.startswith(pre) and n.endswith('.tmp'):
                try: os.unlink(os.path.join(self.dir, n))
                except OSError: pass
        self.cur = load(self.path, self.uid)
        s = self.cur['state']
        if s == 'unmeasured': stop(2, f"não consigo ler o arquivo de convites ({self.cur['detail']}); nada foi escrito, confira à mão")
        if s == 'unreadable': stop(2, "não consigo ler o arquivo de convites com esta conta: rode como a conta do serviço do bridge (sudo -u <conta>)")
        if s == 'error':
            d = self.cur['detail']
            hint = " (rode como a conta do serviço do bridge: sudo -u <conta>)" if d == 'dono-diferente-do-processo' else ""
            stop(1, f"o arquivo de convites está quebrado ({d}){hint}: hoje o bridge recusa TODO convite de membro (convites-indisponiveis). Rode `a2a-invite.sh check` e conserte à mão antes de escrever")
        if s == 'absent':
            if dst.st_uid != self.uid:
                stop(1, f"o arquivo não existe e o diretório não é desta conta: o arquivo nasceria com dono errado e o bridge o recusaria (dono-diferente-do-processo)")
            self.doc = {'version': 1, 'invites': []}
        else:
            self.doc = self.cur['doc']

    def commit(self, doc):
        text = json.dumps(doc, ensure_ascii=True, indent=2) + "\n"   # ASCII: surrogate sozinha não derruba a escrita (refutador)
        state, _ = parse_doc(text)
        if state != 'ok': stop(1, "o documento novo não passa na forma do bridge; nada foi escrito")
        tmp = os.path.join(self.dir, f".{os.path.basename(self.path)}.{os.getpid()}.{os.urandom(4).hex()}.tmp")
        fd = os.open(tmp, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW, 0o600)
        try:
            try:
                os.fchmod(fd, 0o600)
                os.write(fd, text.encode('utf-8')); os.fsync(fd)
            finally:
                os.close(fd)
            # TOCTOU: um escritor FORA deste motor (editor, script) não respeita a trava; se o arquivo
            # mudou desde a leitura, a escrita dele se perderia em silêncio. Recusa e manda reler.
            # ctime entra porque o utime de `cp -p`/`rsync -t` devolve o mtime, mas não o ctime; e o
            # conteúdo relido entra porque a assinatura de metadado sozinha já perdeu escrita (refutador)
            try:
                now = os.lstat(self.path); now_sig = (now.st_dev, now.st_ino, now.st_size, now.st_mtime_ns, now.st_ctime_ns)
                with open(self.path, 'rb') as fh: now_raw = fh.read()
            except FileNotFoundError:
                now_sig = None; now_raw = None
            st0 = self.cur.get('st'); sig0 = (st0.st_dev, st0.st_ino, st0.st_size, st0.st_mtime_ns, st0.st_ctime_ns) if st0 else None
            if now_sig != sig0 or now_raw != self.cur.get('raw'): stop(2, "o arquivo de convites mudou durante a escrita (escritor fora deste motor); nada foi escrito, rode de novo")
            os.replace(tmp, self.path)
            tmp = None
            try: os.fsync(self.dfd)
            except OSError: pass   # fsync de diretório não existe em todo sistema; o rename já foi
        finally:
            if tmp and os.path.exists(tmp): os.unlink(tmp)

def read_descriptor(inv):
    """o descritor: só arquivo regular, aberto sem bloquear (um FIFO no caminho travava o motor)."""
    try:
        fd = os.open(inv, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK)
    except FileNotFoundError:
        stop(1, f"descritor do convite não encontrado: {inv}")
    except PermissionError:
        stop(2, f"sem permissão de leitura no descritor: {inv}")
    except OSError:
        stop(1, f"descritor do convite ilegível (symlink?): {inv}")
    try:
        if not stat.S_ISREG(os.fstat(fd).st_mode): stop(1, f"o descritor não é arquivo regular: {inv}")
        raw = os.read(fd, 65537)
    finally:
        os.close(fd)
    if len(raw) > 65536: stop(1, "descritor grande demais")
    try:
        return json.loads(raw.decode('utf-8'), parse_constant=reject_constant)
    except (ValueError, RecursionError):
        return None

def show_entry(prefix, e):
    print(prefix + json.dumps(e, ensure_ascii=False, sort_keys=True))

def parse_args(argv):
    sub = argv[0]; rest = argv[1:]; pos = []; opt = {}
    flags = {'--dry-run', '--json', '--token-stdin'}
    vals = {'--days', '--file', '--token-out', '--receiver', '--invite-out', '--members', '--member', '--invite', '--owner', '--token-file'}
    i = 0
    while i < len(rest):
        a = rest[i]
        if a in flags: opt[a] = True; i += 1
        elif a in vals:
            if i + 1 >= len(rest) or rest[i + 1] == '' or rest[i + 1].startswith('--'): stop(3, f"{a} exige valor")
            opt[a] = rest[i + 1]; i += 2
        elif a.startswith('-'): stop(3, f"argumento desconhecido: {a}")
        else: pos.append(a); i += 1
    return sub, pos, opt

def need_id(v, what):
    if not v or not ID_RE.fullmatch(v): stop(3, f"{what} fora de [A-Za-z0-9._-] (sem '.' inicial): {v!r}")
    return v

def cmd_create(pos, opt, root):
    if len(pos) != 1: stop(3, "uso: create <member> --days N --file <invites.json> (--token-out <arq> | --token-stdin)")
    member = need_id(pos[0], "member")
    days = opt.get('--days', '')
    if not re.match(r'^[1-9][0-9]{0,2}$', days) or int(days) > 365: stop(3, f"--days precisa ser inteiro de 1 a 365: {days!r}")
    path = opt.get('--file') or stop(3, "--file é obrigatório")
    tout = opt.get('--token-out'); tin = opt.get('--token-stdin')
    if bool(tout) == bool(tin): stop(3, "passe --token-out <arq> OU --token-stdin (um dos dois)")
    iout = opt.get('--invite-out') or (tout + '.invite.json' if tout else None)
    reg = opt.get('--members') or os.path.join(root, 'docs/evolution/federation/members.yaml')
    ids, src, why = registry(reg)
    receiver = opt.get('--receiver') or src
    if not receiver: stop(3, f"não sei o receptor ({why or 'registro sem membro kind: source'}): passe --receiver")
    need_id(receiver, "receiver")
    if member == receiver: stop(3, "member e receiver são o mesmo id")
    if ids is None:
        print(f"{NAME}: aviso: {why}: o membro '{member}' NÃO foi conferido no registro", file=sys.stderr)
    elif member not in ids:
        stop(1, f"membro '{member}' não está no registro ({reg}): registre-o antes (/meta:federation-member register)")
    else:
        bym = registry_by_id(reg)
        why_r = receiver_problem(bym or {}, member, receiver)
        if why_r: stop(1, why_r)
    for p in (tout, iout):
        if p and (os.path.lexists(p)): stop(1, f"{p} já existe, recuso sobrescrever")
        if p and git_unignored(p): stop(1, f"{p} cairia numa árvore git sem estar no .gitignore: gere fora do repo")
    if tin and sys.stdin.isatty(): stop(3, "--token-stdin exige redirecionamento de arquivo ou pipe, nunca o terminal (o token não se digita)")

    w = Writer(path)
    now = time.time(); exp = iso_utc(now + int(days) * 86400)
    entry = {'token_sha256': '<sha256 do token gerado na execução>' if not tin else None, 'member': member,
             'receiver': receiver, 'expires_at': exp, 'revoked': False}
    if tin:
        raw = sys.stdin.buffer.read(4097)
        if len(raw) > 4096: stop(1, "a entrada do --token-stdin passa de 4 KiB: não é um token")
        try:
            tok = raw.decode('ascii').replace('\r', '').replace('\n', '')   # o a2a-send.sh faz tr -d '\r\n'
        except UnicodeDecodeError:
            stop(1, "o token do --token-stdin não é ASCII")
        if len(tok) < MIN_TOKEN or not TOKEN_RE.fullmatch(tok):
            stop(1, f"o token do --token-stdin tem de ter ≥ {MIN_TOKEN} caracteres de [A-Za-z0-9._~+/=-] (o bridge recusa token curto como convite de membro)")
        entry['token_sha256'] = hashlib.sha256(tok.encode('ascii')).hexdigest(); tok = None
        if entry['token_sha256'] in groups_of(w.doc):
            stop(1, "este token já está no arquivo: um token por convite (repetir o hash amarra o mesmo bearer a duas entradas)")
    if opt.get('--dry-run'):
        print(f"dry-run: {path} ganharia a entrada (nada foi escrito, nenhum token gerado):")
        e = dict(entry);
        if tin: e['token_sha256'] = e['token_sha256'][:12] + '…'
        show_entry("  + ", e)
        if tout: print(f"  token nasceria em {tout} (0600)")
        if iout: print(f"  descritor nasceria em {iout} (0600)")
        return 0
    if tout:
        with open('/dev/urandom', 'rb') as r: rnd = r.read(32)
        tok = rnd.hex(); rnd = None
        entry['token_sha256'] = hashlib.sha256(tok.encode('ascii')).hexdigest()
        new_secret_file(tout, (tok + "\n").encode('ascii')); tok = None
    made = [p for p in (tout,) if p]
    try:
        if iout:
            new_secret_file(iout, (json.dumps({'member': member, 'receiver': receiver, 'expires_at': exp,
                                               'revoked': False, 'token_sha256': entry['token_sha256']}, indent=2) + "\n").encode())
            made.append(iout)
        doc = w.doc; doc['invites'].append(entry)
        w.commit(doc)
    except BaseException:
        for p in made:
            try: os.unlink(p)
            except OSError: pass
        raise
    print(f"convite criado: member={member} receiver={receiver} expires_at={exp} id={entry['token_sha256'][:12]}")
    if tout: print(f"token={tout} (0600; o conteúdo nunca é impresso: entregue o arquivo fora de banda)")
    if iout: print(f"descritor={iout} (sem segredo; vai junto para o doctor do membro)")
    return 0

def cmd_revoke(pos, opt, root):
    if len(pos) != 1: stop(3, "uso: revoke <member> --file <invites.json> [--receiver <id>]")
    member = need_id(pos[0], "member"); rcv = opt.get('--receiver')
    if rcv: need_id(rcv, "receiver")
    path = opt.get('--file') or stop(3, "--file é obrigatório")
    w = Writer(path)
    if w.cur['state'] == 'absent': stop(1, f"o arquivo de convites não existe: nenhum convite de '{member}' a revogar")
    hit = [e for e in w.doc['invites'] if isinstance(e, dict) and e.get('member') == member and (not rcv or e.get('receiver') == rcv)]
    if not hit: stop(1, f"nenhum convite de '{member}'{' para ' + rcv if rcv else ''} no arquivo")
    todo = [e for e in hit if e.get('revoked') is not True]
    if not todo:
        print(f"nada a mudar: os {len(hit)} convite(s) de '{member}' já estão revogados"); return 0
    if opt.get('--dry-run'):
        print(f"dry-run: {len(todo)} entrada(s) de '{member}' passariam a revoked: true (nada foi escrito):")
        for e in todo:
            print(f"  ~ id={(entry_hash(e) or '-')[:12]} receiver={e.get('receiver')} expires_at={e.get('expires_at')} revoked: {json.dumps(e.get('revoked'))} → true")
        return 0
    for e in todo: e['revoked'] = True
    w.commit(w.doc)
    print(f"revogado(s): {len(todo)} convite(s) de '{member}' (vale no próximo POST /a2a, sem restart)")
    return 0

def cmd_list(pos, opt, root, check=False):
    if pos: stop(3, f"argumento a mais: {pos[0]}")
    path = opt.get('--file') or stop(3, "--file é obrigatório")
    uid = resolve_uid(opt.get('--owner'))
    m = opt.get('--member'); rcv = opt.get('--receiver'); inv = opt.get('--invite')
    if m: need_id(m, "member")
    if rcv: need_id(rcv, "receiver")
    cur = load(path, uid); now = time.time()
    res = {'file': path, 'state': cur['state'], 'detail': cur.get('detail', ''), 'entries': [], 'checks': []}
    rc = 0
    def put(i, status, cause, nxt):
        res['checks'].append({'id': i, 'status': status, 'cause': cause, 'next': nxt})
    if cur['state'] == 'unmeasured':
        put('arquivo', 'nao-medido', f"não consegui interpretar o arquivo ({cur['detail']}); o bridge pode estar lendo", 'confira o arquivo à mão')
    elif cur['state'] == 'unreadable':
        put('arquivo', 'nao-medido', 'esta conta não lê o arquivo (é 0600 da conta do serviço)', 'rode como a conta do serviço do bridge: sudo -u <conta>')
    elif cur['state'] == 'absent':
        put('arquivo', 'falha', 'arquivo ausente: o bridge vê ZERO convites de membro (ninguém autentica)', 'crie o primeiro convite: a2a-invite.sh create <member> …')
    elif cur['state'] == 'error':
        put('arquivo', 'falha', f"o bridge recusa o arquivo INTEIRO ({cur['detail']}): nenhum convite de membro autentica (convites-indisponiveis)",
            'conserte o arquivo (dono = conta do serviço, 0600, diretório sem escrita de grupo/outros, JSON version 1)')
    else:
        mode = stat.S_IMODE(cur['st'].st_mode)
        if mode & 0o077: put('permissao', 'falha', f"modo {mode:04o}: o bridge aceita, mas o contrato do arquivo é 0600 (os hashes dos convites não são de mais ninguém)", 'chmod 0600 no arquivo')
        else: put('permissao', 'ok', f"modo {mode:04o}, dono uid {cur['st'].st_uid}, diretório seguro", '—')
        res['entries'] = describe(cur['doc'], now)
        bad = [e for e in res['entries'] if e['state'] in ('ignorada', 'invalido', 'derrubado')]
        if bad:
            put('entradas', 'falha', f"{len(bad)} entrada(s) que nunca autenticam: " + '; '.join(f"{e['id']} {e['state']} ({e['why']})" for e in bad[:5]),
                'revogue e recrie pelo motor; não edite o arquivo à mão')
        else:
            n = len(res['entries']); a = sum(1 for e in res['entries'] if e['state'] == 'ativo')
            put('entradas', 'ok', f"{n} entrada(s), {a} ativa(s), todas na forma do bridge", '—')
        if m or inv:
            # a pergunta do doctor: o bearer DESTE membro passa no guard do bridge para ESTE receptor?
            g = groups_of(cur['doc']); probes = []
            if inv:
                d = read_descriptor(inv)
                if not isinstance(d, dict): stop(1, f"descritor do convite ilegível: {inv}")
                h = d.get('token_sha256', '').lower() if isinstance(d.get('token_sha256'), str) else ''
                if not HEX64.fullmatch(h): stop(1, "descritor sem token_sha256 de 64 hex")
                probes = [(h, decide(g.get(h, []), m or d.get('member'), rcv or d.get('receiver'), now))]
            else:
                for h, grp in g.items():
                    if any(isinstance(e, dict) and e.get('member') == m for e in grp):
                        probes.append((h, decide(grp, m, rcv or next((e.get('receiver') for e in grp), None), now)))
            res['probe'] = [{'id': h[:12], 'bridge': r} for h, r in probes]
            if m and not inv:
                res['entries'] = [e for e in res['entries'] if e['member'] == m]
    # rc SEMPRE (refutador: list sem --member saía 0 com arquivo ilegível); com sonda, nenhum ok = 1
    st = [c['status'] for c in res['checks']]
    rc = 1 if 'falha' in st else (2 if 'nao-medido' in st else 0)
    if rc == 0 and 'probe' in res and not any(p['bridge'] == 'ok' for p in res['probe']): rc = 1
    res['rc'] = rc
    if opt.get('--json'):
        print(json.dumps(res, ensure_ascii=False)); return rc
    print(f"a2a-invite · {path} · estado do arquivo: {cur['state']}{(' (' + res['detail'] + ')') if res['detail'] and cur['state'] != 'ok' else ''}")
    if not check:
        for e in res['entries']:
            print(f"  {e['id']:<12}  {str(e['member']):<20} → {str(e['receiver']):<16} até {str(e['expires_at']):<22} {e['state']}{(' — ' + e['why']) if e['why'] else ''}")
        for p in res.get('probe', []): print(f"  sonda {p['id']}: o bridge responderia {p['bridge']}")
    for c in res['checks']:
        ic = {'ok': '✅', 'falha': '❌'}.get(c['status'], '⚪')
        print(f"{ic} ({c['id']}) {c['cause']}")
        if c['status'] != 'ok': print(f"      → próximo passo: {c['next']}")
    return rc

def cmd_inspect(pos, opt, root):
    """o descritor que viaja com o token (lado do membro): é dele, para este receptor, e está de pé?
    Só lê o descritor (sem segredo). A revogação real só se mede no arquivo do receptor."""
    if pos: stop(3, f"argumento a mais: {pos[0]}")
    inv = opt.get('--invite') or stop(3, "--invite é obrigatório")
    m = need_id(opt.get('--member', ''), "--member"); rcv = opt.get('--receiver')
    if rcv: need_id(rcv, "receiver")
    d = read_descriptor(inv)
    tf = opt.get('--token-file'); tok_bad = None
    if tf and isinstance(d, dict):
        # o descritor só prova algo se o token do membro é o dele: o hash se calcula aqui, no processo,
        # e só a comparação sai (refutador: um token qualquer com um descritor válido dava saudável)
        try:
            with open(tf, 'rb') as fh: traw = fh.read(4097)
            t = traw.decode('ascii').replace('\r', '').replace('\n', '')
        except (OSError, UnicodeDecodeError):
            t = None
        dh = d.get('token_sha256').lower() if isinstance(d.get('token_sha256'), str) else ''
        if t is None: tok_bad = 'o token do canal não é legível como ASCII'
        elif len(t) < MIN_TOKEN or not TOKEN_RE.fullmatch(t): tok_bad = f'o token do canal tem menos de {MIN_TOKEN} caracteres válidos: o bridge não o aceita como convite de membro'
        elif not HEX64.fullmatch(dh): tok_bad = 'o descritor não traz token_sha256 de 64 hex (não foi gerado pelo a2a-invite.sh create)'
        elif hashlib.sha256(t.encode('ascii')).hexdigest() != dh: tok_bad = 'o token do canal NÃO é o deste descritor (o hash não bate): o bridge responderia credencial-desconhecida'
        t = traw = None
    now = time.time(); exp = None
    if not isinstance(d, dict): st, why = 'invalido', 'não é objeto JSON'
    elif tok_bad: st, why = 'token-errado', tok_bad
    elif d.get('member') != m: st, why = 'de-outro-membro', f"o convite é de '{d.get('member') or 'ninguém'}', não de '{m}'"
    elif rcv and d.get('receiver') != rcv: st, why = 'de-outro-receptor', f"o convite é para '{d.get('receiver')}', não para '{rcv}'"
    elif d.get('revoked') is True: st, why = 'revogado', 'convite REVOGADO pelo receptor'
    elif d.get('revoked') is not False: st, why = 'revogado', 'revoked não é false literal: o bridge trata o convite como revogado'
    else:
        exp = parse_iso(d.get('expires_at'))
        if exp is None: st, why = 'invalido', f"expires_at ausente ou fora da forma (ISO 8601 com hora e fuso, a do bridge; veio {json.dumps(d.get('expires_at'))})"
        elif exp <= now: st, why = 'vencido', f"convite VENCIDO em {iso_utc(exp)}"
        else: st, why = 'ativo', f"convite de '{m}' válido até {iso_utc(exp)}"
    res = {'state': st, 'why': why, 'expires_at': iso_utc(exp) if exp is not None else None}
    if opt.get('--json'): print(json.dumps(res, ensure_ascii=False))
    else: print(f"{st}: {why}")
    return 0 if st == 'ativo' else 1

def main():
    root = sys.argv[1]; argv = sys.argv[2:]
    sub, pos, opt = parse_args(argv)
    if sub == 'create': return cmd_create(pos, opt, root)
    if sub == 'revoke': return cmd_revoke(pos, opt, root)
    if sub == 'list': return cmd_list(pos, opt, root)
    if sub == 'check': return cmd_list(pos, opt, root, check=True)
    if sub == 'inspect': return cmd_inspect(pos, opt, root)
    stop(3, f"subcomando desconhecido: {sub} (create|revoke|list|check|inspect)")

import signal
signal.signal(signal.SIGTERM, lambda *_: (_ for _ in ()).throw(Stop(2, "interrompido (SIGTERM); o que estava a meio foi desfeito")))
try:
    sys.exit(main())
except Stop as s:
    print(f"{NAME}: {s.msg}", file=sys.stderr); sys.exit(s.rc)
PY
umask 077
exec python3 -I -c "${PROG}" "${ROOT}" "$@"
