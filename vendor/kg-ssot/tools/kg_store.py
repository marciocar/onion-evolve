#!/usr/bin/env python3
"""O armazém de .kg.yaml e .kg.json que só grava o que o contrato aprova.

Biblioteca primeiro, CLI por cima. Três armazéns com a mesma interface (read, list, write, delete, history):
  DiskStore(root)       a cabeça em disco, sem histórico;
  GitStore(root)        um commit por gravação ou remoção, com o git isolado na raiz (nunca sobe para um repo pai);
  VersionedStore(root)  a cabeça em disco mais um registro de eventos e as versões em `.kg-store/`, sem git.

O gate (o que nenhum dos três pula):
  - write() julga o candidato pelo contrato (kg_validate.judge) com a ponta externa conferida contra o próprio
    armazém, já com o candidato no lugar; e julga de novo cada grafo do armazém que aponta para o nome gravado,
    porque trocar um grafo pode deixar a aresta externa de outro sem ponta;
  - delete() julga os grafos que apontam para o nome removido, contra o armazém sem ele;
  - write_many() grava um conjunto (inclusive remoções) de uma vez, ou nada: o contrato julga o conjunto inteiro com
    todas as mudanças no lugar, e o registro é um só. É o caminho para regenerar grafos que se citam: um a um, o
    rejulgamento de quem aponta barraria o estado intermediário;
  - só grava com PASS em todos. Nada reprovado é escrito;
  - o formato vem do nome: o .kg.json é julgado pelo perfil JSON do contrato (kg_validate.as_source), e o .kg.yaml
    pelo perfil YAML. O corpus da ponta externa tem os dois formatos, como o do gate (corpus_index): desde o v4.7, a
    referência externa (<caminho>.kg.yaml#<id> ou <caminho>.kg.json#<id>) aponta para qualquer um deles;
  - o corpus é o mesmo que o gate do repo (kg_validate.corpus_index) veria: no GitStore, só o RASTREADO (list() e o
    julgamento ignoram o .kg.yaml não rastreado); disco e versionado recusam uma raiz dentro de worktree git, onde os
    dois corpus divergiriam;
  - a cabeça só fica trocada com o registro feito: se o commit ou o evento falha, ela volta ao que era. Gravar o texto
    da última versão registrada é unchanged, sem commit nem evento.

Resultado de write()/delete(): {written, reason, name, sha256, ref, verdict, error, unchanged}. reason é null quando gravou, e
senão "gate" (o contrato reprovou: verdict traz o porquê), "conflict" (expected_sha256 não bate com a cabeça),
"missing" (remover o que não existe) ou "not_judged" (o julgamento falhou ou saiu fora de spec/verdict.schema.json:
nunca vira PASS nem "gate"). expected_sha256 é a trava otimista: o sha256 da cabeça que quem grava leu, ou NEW para
exigir que o nome ainda não exista. Gravar o mesmo texto da cabeça é written com unchanged=true e ref null.

Segurança do caminho: o nome é relativo, termina em .kg.yaml ou .kg.json, cada segmento começa por letra, dígito ou _ (sem `..`
nem oculto). O armazém é copiável entre sistemas: um nome NOVO não pode ter segmento reservado do Windows (CON, NUL,
COM1...) nem que termina em ponto, e nenhuma operação aceita um nome que só difere pela caixa de um que está no armazém
(no Windows e no macOS os dois seriam o mesmo arquivo, e o gate julgaria o nome errado). O nome que já está no armazém
segue funcionando. Raiz, pastas e arquivo não podem ser link:
  - no POSIX, tudo se abre por dir_fd com O_NOFOLLOW, e a troca de uma pasta no meio da operação não desvia nada;
  - no Windows, que não tem dir_fd, cada passo do caminho é conferido por lstat (link simbólico, junção e ponto de
    montagem são recusados; o reparse point que não redireciona o nome, como o arquivo do OneDrive sob demanda, passa),
    o arquivo aberto tem de ser o mesmo que o lstat viu, e o caminho é conferido de novo depois da leitura e, na
    gravação, antes da troca final (o replace). É mais fraco que o POSIX: quem pode escrever dentro da raiz consegue
    trocar uma pasta entre a conferência e o uso. Num sistema de arquivos sem id de arquivo (st_ino 0, como o FAT de
    um pendrive), a comparação do arquivo aberto não prova nada e só a recusa de link sobra. A trava entre processos é
    a do msvcrt.
O que fica com quem adota, de propósito: autenticação, identidade, área por usuário (um root por usuário), tamanho
máximo, número de grafos, timeout e concorrência entre processos onde não há flock nem msvcrt.

CLI (saída JSON no stdout):
  kg_store.py --backend disk|git|versioned --root DIR [--init] list
  kg_store.py ... read NAME [--ref REF]
  kg_store.py ... write NAME [FILE|-] [--message M] [--author "Nome <email>"] [--expected-sha256 S|new]
  kg_store.py ... delete NAME [--message M] [--author A] [--expected-sha256 S]
  kg_store.py ... write-many CONJUNTO.json [--message M] [--author A]
    o conjunto é {"changes": [{"name": N, "file": F} | {"name": N, "text": T} | {"name": N, "delete": true}],
    "expected": {N: S|new}}, com file relativo ao CONJUNTO.json; grava tudo ou nada (write_many)
  kg_store.py ... history NAME
rc: 0 ok · 1 recusado (gate, conflict, missing, nome inexistente) · 2 entrada quebrada ou not_judged.
"""
import argparse
import datetime
import hashlib
import json
import os
import pathlib
import re
import secrets
import shlex
import stat
import subprocess
import sys
import signal
import tempfile
import threading
import time

sys.dont_write_bytecode = True
if __package__:  # no pacote kg_ssot, o vizinho vem pelo pacote, sem mexer no sys.path de quem importa
    from . import kg_validate
else:  # script ou vendor
    sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
    import kg_validate  # noqa: E402

try:
    import fcntl
except ImportError:  # Windows: a trava é a do msvcrt
    fcntl = None
try:
    import msvcrt
except ImportError:  # POSIX
    msvcrt = None

NAME = re.compile(r"^(?:[A-Za-z0-9_][A-Za-z0-9_.-]*/)*[A-Za-z0-9_][A-Za-z0-9_.-]*\.kg\.(?:yaml|json)$")
NEW = "new"
META = ".kg-store"
LOCK = ".kg-store.lock"
AUTHOR = re.compile(r"[^<>\n\r\x00]+ <[^<>\s\x00]+>")  # fullmatch: o $ casaria antes de um \n final
SEGMENT_MAX = 200  # bytes por segmento do nome: sobra espaço no NAME_MAX para o arquivo temporário
def _spec_home():
    """A raiz que tem o spec/, pelo caminho DESTE módulo (como o _home do kg_validate): ao lado no pacote, no pai no
    repo e no vendor. Não depende do kg_validate importado, então um kg_validate falso num teste não a desvia."""
    here = pathlib.Path(__file__).resolve().parent
    return here if (here / "spec" / "release.json").is_file() else here.parent


VERDICT_SCHEMA = _spec_home() / "spec" / "verdict.schema.json"
_NOFOLLOW = getattr(os, "O_NOFOLLOW", 0)
_DIRECTORY = getattr(os, "O_DIRECTORY", 0)
_BINARY = getattr(os, "O_BINARY", 0)  # no Windows, sem ele o os.open abre em modo texto e troca \n por \r\n
_REPARSE = getattr(stat, "FILE_ATTRIBUTE_REPARSE_POINT", 0x400)
_NAME_SURROGATE = 0x20000000  # o bit das tags que redirecionam o nome (symlink, junção, montagem)
# o caminho seguro: "posix" (dir_fd e O_NOFOLLOW), "win" (lstat antes e depois) ou None (o armazém não abre)
_POSIX_FD = hasattr(os, "supports_dir_fd") and os.open in os.supports_dir_fd
PATH_MODE = "posix" if _POSIX_FD else "win" if os.name == "nt" else None
_WIN_RESERVED = re.compile(r"(?i)(?:con|prn|aux|nul|com[0-9]|lpt[0-9])(?:\..*)?")


class StoreError(Exception):
    """Entrada quebrada: nome inválido, symlink no caminho, raiz que não serve, git que falha."""


class NotFound(StoreError):
    """O nome (ou a versão pedida) não existe no armazém."""


def sha256(text):
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


def check_name(name):
    if not isinstance(name, str) or not NAME.fullmatch(name):
        raise StoreError(f"nome inválido: {name!r} (relativo, termina em .kg.yaml ou .kg.json, sem '..' nem segmento oculto)")
    if any(len(seg.encode("utf-8")) > SEGMENT_MAX for seg in name.split("/")):
        raise StoreError(f"nome inválido: segmento com mais de {SEGMENT_MAX} bytes")
    return name


def check_portable(name):
    """Um nome NOVO tem de existir em todo sistema: nenhum segmento reservado do Windows (CON, NUL, COM1...) nem que
    termina em ponto. O nome que já está no armazém segue lendo, gravando e removendo."""
    if any(seg.endswith(".") or _WIN_RESERVED.fullmatch(seg) for seg in name.split("/")):
        raise StoreError(f"nome inválido: {name!r} (segmento reservado no Windows, como CON ou NUL, ou que termina em ponto)")
    return name


def _is_link(st):
    """Link simbólico, junção ou ponto de montagem: o que redireciona o nome para outro lugar (no Windows, a junção não
    é S_ISLNK). O reparse point que não redireciona (o arquivo do OneDrive sob demanda, a deduplicação) não é link: a
    tag dele não tem o bit de name surrogate. No Windows, o os.lstat devolve a tag de todo name surrogate e ATRAVESSA o
    reparse point que não o é, devolvendo a tag 0 (Modules/posixmodule.c, win32_xstat_slow_impl); o DirEntry traz a
    tag real. Nos dois casos, só o bit de name surrogate faz link. A tag 0 de um sistema de arquivos que não a informa
    é o caso de _redirects."""
    if stat.S_ISLNK(st.st_mode):
        return True
    return bool(getattr(st, "st_file_attributes", 0) & _REPARSE
                and getattr(st, "st_reparse_tag", 0) & _NAME_SURROGATE)


def _redirects(path, st):
    """O passo path (com o lstat st) leva para outro lugar? Link pela tag (_is_link), ou um reparse point sem tag (o
    sistema de arquivos que não informa a tag, como alguns redirecionadores de rede): ali, o lstat e o stat apontarem
    para arquivos diferentes é link."""
    if _is_link(st):
        return True
    if getattr(st, "st_file_attributes", 0) & _REPARSE and not getattr(st, "st_reparse_tag", 0):
        try:
            return not _same(st, os.stat(path))
        except OSError:
            return True
    return False


def _same(a, b):
    return (a.st_dev, a.st_ino) == (b.st_dev, b.st_ino)


def check_author(author):
    if author is not None and (not isinstance(author, str) or not AUTHOR.fullmatch(author)):
        raise StoreError(f"autor inválido: {author!r} (a forma é 'Nome <email>')")
    return author


def check_message(message, default):
    """A mensagem do commit ou do evento: None vira o default; vazia ou com NUL é recusada antes de tocar o disco."""
    if message is None:
        return default
    if not isinstance(message, str) or not message.strip() or "\x00" in message:
        raise StoreError("mensagem inválida: vazia ou com NUL")
    return message


_verdict_validator = None


def _verdict_ok(doc):
    """O documento do julgamento cumpre spec/verdict.schema.json? (o gate não confia nem no próprio leitor)"""
    global _verdict_validator
    if _verdict_validator is None:
        _verdict_validator = kg_validate.make_validator(json.loads(VERDICT_SCHEMA.read_text(encoding="utf-8")))
    return not any(True for _ in _verdict_validator.iter_errors(doc))


def _win_retry(op, tries=6):
    """No Windows, um antivírus ou o indexador segura o arquivo por instantes (PermissionError): tenta de novo."""
    for i in range(tries):
        try:
            return op()
        except PermissionError:
            if os.name != "nt" or i == tries - 1:
                raise
            time.sleep(0.02 * 2 ** i)


def split_command(cmd):
    """O comando do gate como lista de argumentos, sem shell. No POSIX, pelas regras do shlex; no Windows, onde a barra
    invertida é separador de caminho, as aspas duplas agrupam e a barra fica como está."""
    try:
        if os.name != "nt":
            return shlex.split(cmd)
        return [t[1:-1] if len(t) >= 2 and t[0] == t[-1] == '"' else t for t in shlex.split(cmd, posix=False)]
    except ValueError as exc:  # aspas sem fechar
        raise StoreError(f"o comando do gate externo não se lê: {exc}") from exc


_LIVE_GATES = set()  # os gates rodando agora, para um SIGTERM ao processo não deixá-los órfãos
_LIVE_LOCK = threading.RLock()  # reentrante: o tratador do SIGTERM pode interromper a própria thread que o segura
# o estado do encerramento: "stopping" depois do SIGTERM (nenhum gate novo abre), "spawning" enquanto a thread principal
# cria e registra um gate, e "pending" com o sinal que chegou nesse meio, tratado logo depois do registro
_TERM = {"stopping": False, "spawning": False, "pending": None}


def kill_live_gates():
    """Mata os gates externos que estão rodando (o grupo de cada um) e fecha a porta a gates novos. Chamado pelo
    tratador do SIGTERM."""
    with _LIVE_LOCK:
        _TERM["stopping"] = True
        live = list(_LIVE_GATES)
    for p in live:
        CommandGate._kill(p)


def _on_term(signum, frame):
    if _TERM["spawning"]:  # a thread principal está entre criar o gate e registrá-lo: o registro trata o sinal
        _TERM["pending"] = signum
        return
    kill_live_gates()
    raise SystemExit(128 + signum)


def install_term_handler():
    """No processo de vida longa (o kg_mcp, o CLI), um SIGTERM mata os gates antes de sair. Só na thread principal,
    onde o Python aceita tratador de sinal. No Windows, matar o processo à força (TerminateProcess, o que o "Finalizar
    tarefa" faz) não passa por tratador nenhum, e o gate que estiver rodando pode ficar."""
    if hasattr(signal, "SIGTERM") and threading.current_thread() is threading.main_thread():
        signal.signal(signal.SIGTERM, _on_term)


class CommandGate:
    """Um gate externo por comando: roda depois do PASS do contrato, na gravação e na remoção, e o armazém só grava com
    PASS dos dois. É o gancho por onde quem adota liga o próprio gate sem o produto depender dele.

    O comando é uma lista de argumentos (uma string passa por split_command) e nunca roda em shell. O texto candidato
    vai pelo stdin em UTF-8 (vazio na remoção), e o nome e a operação pelo ambiente: KG_GATE_NAME e KG_GATE_OP (write
    ou delete). O resto do ambiente é o do processo, menos as variáveis de drop_env (o kg_mcp tira a do segredo).
    A saída tem de ser um documento kg-ssot.verdict/1 válido pelo spec/verdict.schema.json, com ao menos um resultado,
    rc 0 quando tudo passa e rc 1 quando algo reprova. Qualquer outra coisa (comando que não roda, tempo esgotado,
    saída sem JSON ou maior que MAX_OUTPUT, JSON fora do schema, rc que não bate com o veredito) é "não julgado",
    nunca PASS.

    A saída vai para um arquivo temporário, não para um pipe: um processo neto que herde a saída não segura a espera, e
    no tempo esgotado o grupo de processos inteiro é morto. O gate roda sob a trava da gravação: um gate lento segura
    as outras gravações do mesmo armazém até o --gate-timeout."""
    MAX_OUTPUT = 16 * 1024 * 1024
    MAX_TIMEOUT = 86400  # um dia: acima disso o tempo é engano, e no Windows estoura a espera em milissegundos

    def __init__(self, argv, timeout=60, drop_env=()):
        argv = split_command(argv) if isinstance(argv, str) else list(argv or [])
        if not argv:
            raise StoreError("gate externo vazio: diga o comando")
        if not (isinstance(timeout, (int, float)) and 0 < timeout <= self.MAX_TIMEOUT):  # recusa também NaN
            raise StoreError(f"o tempo do gate externo tem de ser de mais de 0 até {self.MAX_TIMEOUT} segundos")
        self.argv, self.timeout, self.drop_env = argv, timeout, frozenset(drop_env)

    @staticmethod
    def _kill(p):
        """Mata o comando e os processos que ele abriu (o grupo no POSIX, a árvore no Windows)."""
        try:
            if os.name == "nt":  # pelo caminho do sistema, nunca um taskkill achado no diretório atual
                taskkill = os.path.join(os.environ.get("SystemRoot", r"C:\Windows"), "System32", "taskkill.exe")
                subprocess.run([taskkill, "/F", "/T", "/PID", str(p.pid)], capture_output=True, timeout=30)
            else:
                os.killpg(p.pid, 9)
        except (OSError, subprocess.SubprocessError):
            pass
        try:
            p.kill()
            p.wait(timeout=30)
        except (OSError, subprocess.SubprocessError):
            pass

    def _wait(self, p, stdout):
        """Espera o comando até o tempo, conferindo o tamanho da saída enquanto ele roda: (rc, None), ou (None, o
        motivo) com o comando e os processos dele mortos."""
        deadline = time.monotonic() + self.timeout
        while True:
            try:
                return p.wait(timeout=min(0.1, max(0.0, deadline - time.monotonic()))), None
            except subprocess.TimeoutExpired:
                pass
            if os.fstat(stdout.fileno()).st_size > self.MAX_OUTPUT:
                self._kill(p)
                return None, f"a saída do gate externo passou de {self.MAX_OUTPUT} bytes"
            if time.monotonic() >= deadline:
                self._kill(p)
                return None, f"o gate externo passou de {self.timeout} s"

    def __call__(self, name, text, op):
        fold = str.upper if os.name == "nt" else str  # no Windows, o nome da variável não distingue caixa
        drop = {fold(k) for k in self.drop_env}
        env = {k: v for k, v in os.environ.items() if fold(k) not in drop}
        env.update(KG_GATE_NAME=name, KG_GATE_OP=op)
        group = ({"creationflags": subprocess.CREATE_NEW_PROCESS_GROUP} if os.name == "nt"
                 else {"start_new_session": True})
        try:
            stdin, stdout = tempfile.TemporaryFile(), tempfile.TemporaryFile()
        except OSError as exc:  # sem diretório temporário: não julgado, sem o caminho dele na mensagem
            return None, f"o gate externo não rodou (sem arquivo temporário: {exc.strerror or type(exc).__name__})"
        with stdin, stdout:
            stdin.write((text or "").encode("utf-8"))
            stdin.seek(0)
            # um SIGTERM entre criar o processo e registrá-lo não deixa um gate que o tratador não conhece: nas outras
            # threads, a trava segura o tratador; na principal, o sinal fica pendente e é tratado depois do registro.
            # Sem máscara de sinal, que o gate herdaria (e com ela o timeout do coreutils e o kill do operador não o
            # parariam)
            main = threading.current_thread() is threading.main_thread()
            try:
                with _LIVE_LOCK:
                    if _TERM["stopping"]:
                        return None, "o gate externo não rodou (o processo está encerrando)"
                    if main:
                        _TERM["spawning"] = True
                    try:
                        p = subprocess.Popen(self.argv, stdin=stdin, stdout=stdout, stderr=subprocess.DEVNULL, env=env,
                                             **group)
                    except (OSError, ValueError) as exc:
                        return None, (f"o gate externo não rodou ({type(exc).__name__}: "
                                      f"{getattr(exc, 'strerror', None) or exc})")
                    _LIVE_GATES.add(p)
            finally:
                if main:
                    _TERM["spawning"] = False
                    signum, _TERM["pending"] = _TERM["pending"], None
                    if signum is not None:
                        _on_term(signum, None)
            try:
                rc, why = self._wait(p, stdout)
            except BaseException:  # Ctrl+C ou qualquer exceção na espera: o gate não fica órfão
                self._kill(p)
                raise
            finally:
                with _LIVE_LOCK:
                    _LIVE_GATES.discard(p)
            if why:
                return None, why
            if os.name != "nt":  # um neto que o gate deixou de pé (o grupo dele) não sobrevive à gravação
                try:
                    os.killpg(p.pid, 9)
                except OSError:
                    pass
            if rc not in (0, 1):
                return None, f"o gate externo saiu com rc {rc}"
            if stdout.seek(0, os.SEEK_END) > self.MAX_OUTPUT:  # o que ele escreveu entre a última conferência e o fim
                return None, f"a saída do gate externo passou de {self.MAX_OUTPUT} bytes"
            stdout.seek(0)
            raw = stdout.read()
        try:
            doc = json.loads(raw.decode("utf-8"))
        except (UnicodeDecodeError, ValueError):
            return None, "o gate externo não devolveu um veredito JSON"
        if not _verdict_ok(doc):
            return None, "o veredito do gate externo saiu fora de spec/verdict.schema.json"
        if not doc["results"]:
            return None, "o veredito do gate externo veio sem resultado"
        if any(r["verdict"] == "FAIL" for r in doc["results"]) != (rc == 1):
            return None, "o rc do gate externo não bate com o veredito dele"
        return doc, None


class DiskStore:
    """A cabeça em disco. history() é vazio: este armazém não guarda versão anterior."""
    backend = "disk"

    def __init__(self, root, schema=None, init=False, gate=None):
        self.gate = gate  # o gate externo (CommandGate ou um chamável (name, text, op) -> (doc, erro)), depois do contrato
        if PATH_MODE not in ("posix", "win"):
            raise StoreError("o armazém exige POSIX (os.open com dir_fd e O_NOFOLLOW) ou Windows")
        self._posix = PATH_MODE == "posix"
        if not str(root).strip():
            raise StoreError("raiz vazia: diga o diretório do armazém")
        self.root = pathlib.Path(root)
        if init and not os.path.lexists(self.root):
            ancestor = self.root.absolute()
            while not os.path.lexists(ancestor):
                if ancestor.parent == ancestor:  # um drive ou compartilhamento que não existe: nada acima para criar
                    raise StoreError(f"a raiz {self.root} está num drive ou compartilhamento que não existe")
                ancestor = ancestor.parent
            self._check_root(ancestor)  # recusa antes de criar a pasta, não depois
            try:
                self.root.mkdir(parents=True)
            except OSError as exc:
                raise StoreError(f"não deu para criar a raiz {self.root}: {exc}") from exc
        try:
            st = os.lstat(self.root)
        except OSError as exc:
            raise StoreError(f"raiz ilegível: {exc}") from exc
        if _is_link(st) or not stat.S_ISDIR(st.st_mode):
            raise StoreError(f"a raiz {self.root} tem de ser um diretório, não symlink")
        self.root = self.root.resolve()
        self.schema = schema or kg_validate.CONTRACT_MUST
        self._check_root(self.root)

    def _check_root(self, path):
        """Disco e versionado não podem morar dentro de uma worktree git: lá o gate do repo (corpus_index) enxerga só
        o rastreado, e o armazém enxergaria o disco; o corpus dos dois divergiria. Para isso existe o GitStore."""
        try:
            out = subprocess.run(["git", "-C", str(path), "rev-parse", "--is-inside-work-tree"],
                                 capture_output=True, env={k: v for k, v in os.environ.items()
                                                           if not k.startswith("GIT_")})
        except OSError:  # sem git instalado: nenhum gate vê um repo aqui
            return
        if out.returncode == 0 and out.stdout.strip() == b"true":
            raise StoreError(f"{path} está dentro de um repo git: use o GitStore (o corpus do gate é o rastreado)")

    # --- caminho seguro: nada segue symlink (POSIX por dir_fd; Windows por lstat antes e depois) --------------
    def _dir(self, parts, create=False):
        fd = os.open(self.root, os.O_RDONLY | _DIRECTORY | _NOFOLLOW)
        try:
            for part in parts:
                if create:
                    try:
                        os.mkdir(part, 0o755, dir_fd=fd)
                    except FileExistsError:
                        pass
                try:
                    nxt = os.open(part, os.O_RDONLY | _DIRECTORY | _NOFOLLOW, dir_fd=fd)
                except FileNotFoundError:
                    raise NotFound(f"pasta inexistente: {part}")
                except OSError as exc:  # ELOOP/ENOTDIR: symlink ou arquivo no lugar da pasta
                    raise StoreError(f"pasta recusada (symlink ou não-diretório): {part}") from exc
                os.close(fd)
                fd = nxt
            return fd
        except BaseException:
            os.close(fd)
            raise

    def _win_dir(self, parts, create=False):
        """(pasta, passos): a pasta sob a raiz com cada passo conferido por lstat (nenhum link, junção ou reparse
        point), e a identidade de cada passo para _win_recheck conferir de novo antes de a operação terminar."""
        path = self.root
        steps = []
        for part in [None, *parts]:
            if part is not None:
                path = path / part
                if create:
                    try:
                        os.mkdir(path)
                    except FileExistsError:
                        pass
            try:
                st = os.lstat(path)
            except FileNotFoundError:
                raise NotFound(f"pasta inexistente: {part}")
            except OSError as exc:
                raise StoreError(f"pasta ilegível: {path}: {exc}") from exc
            if _redirects(path, st) or not stat.S_ISDIR(st.st_mode):
                raise StoreError(f"pasta recusada (link, junção ou não-diretório): {part or path}")
            steps.append((path, st))
        return path, steps

    @staticmethod
    def _win_recheck(steps):
        """O caminho é o mesmo de antes da operação: nenhum passo virou link nem foi trocado por outra pasta."""
        for path, before in steps:
            try:
                st = os.lstat(path)
            except OSError as exc:
                raise StoreError(f"o caminho mudou durante a operação: {path}") from exc
            if _is_link(st) or not _same(st, before):
                raise StoreError(f"o caminho mudou durante a operação: {path}")

    @staticmethod
    def _win_open(path, flags, mode=0o644, exists=True):
        """Abre path no Windows recusando link: o lstat de antes, e o arquivo aberto tem de ser o que o lstat viu.
        exists=False aceita que o arquivo ainda não exista (criação)."""
        try:
            before = os.lstat(path)
        except FileNotFoundError:
            if exists:
                raise
            before = None
        if before is not None and (_redirects(path, before) or not stat.S_ISREG(before.st_mode)):
            raise StoreError(f"arquivo recusado (link, junção ou não regular): {path.name}")
        fd = os.open(path, flags | _BINARY, mode)
        try:
            opened = os.fstat(fd)
            after = os.lstat(path)
            if (_is_link(after) or not stat.S_ISREG(opened.st_mode) or not _same(opened, after)
                    or (before is not None and not _same(opened, before))):
                raise StoreError(f"arquivo recusado (trocado durante a abertura): {path.name}")
        except BaseException:
            os.close(fd)
            raise
        return fd

    def _read_file(self, parts):
        """Os bytes do arquivo parts (pastas + folha) sob a raiz, ou None se não existe. Link no caminho ou arquivo que
        não é regular é StoreError."""
        *parts, leaf = parts
        if not self._posix:
            try:
                path, steps = self._win_dir(parts)
            except NotFound:
                return None
            try:
                fd = self._win_open(path / leaf, os.O_RDONLY)
            except FileNotFoundError:
                return None
            except OSError as exc:
                raise StoreError(f"arquivo recusado: {leaf}: {exc}") from exc
            with os.fdopen(fd, "rb") as fh:
                data = fh.read()
            self._win_recheck(steps)
            return data
        try:
            dfd = self._dir(parts)
        except NotFound:
            return None
        try:
            try:  # O_NONBLOCK: uma FIFO no lugar do nome não trava o armazém segurando a trava
                fd = os.open(leaf, os.O_RDONLY | _NOFOLLOW | getattr(os, "O_NONBLOCK", 0), dir_fd=dfd)
            except FileNotFoundError:
                return None
            except OSError as exc:
                raise StoreError(f"arquivo recusado (symlink?): {leaf}") from exc
            with os.fdopen(fd, "rb") as fh:
                if not stat.S_ISREG(os.fstat(fh.fileno()).st_mode):
                    raise StoreError(f"não é arquivo regular: {leaf}")
                return fh.read()
        finally:
            os.close(dfd)

    def _read_head(self, name):
        """O texto da cabeça, ou None se o nome não existe. Symlink no caminho é StoreError."""
        data = self._read_file(check_name(name).split("/"))
        if data is None:
            return None
        try:
            return data.decode("utf-8")
        except UnicodeDecodeError as exc:
            raise StoreError(f"{name} não é UTF-8") from exc

    def _write_head(self, name, text):
        try:
            self._write_file(name.split("/"), text.encode("utf-8"))
        except OSError as exc:
            raise StoreError(f"não deu para gravar {name}: {exc}") from exc

    def _write_file(self, parts, data):
        """Grava parts (pastas + folha) sob a raiz por tmp + replace, sem seguir symlink."""
        *parts, leaf = parts
        tmp = f".{leaf[:40]}.{secrets.token_hex(6)}.tmp"
        if not self._posix:
            path, steps = self._win_dir(parts, create=True)
            fd = self._win_open(path / tmp, os.O_WRONLY | os.O_CREAT | os.O_EXCL, exists=False)
            try:
                with os.fdopen(fd, "wb") as fh:
                    fh.write(data)
                    fh.flush()
                    os.fsync(fh.fileno())
                self._win_recheck(steps)
                _win_retry(lambda: os.replace(path / tmp, path / leaf))
            except BaseException:
                try:
                    os.unlink(path / tmp)
                except OSError:
                    pass
                raise
            return
        dfd = self._dir(parts, create=True)
        try:
            fd = os.open(tmp, os.O_WRONLY | os.O_CREAT | os.O_EXCL | _NOFOLLOW, 0o644, dir_fd=dfd)
            try:
                with os.fdopen(fd, "wb") as fh:
                    fh.write(data)
                    fh.flush()
                    os.fsync(fh.fileno())
                os.replace(tmp, leaf, src_dir_fd=dfd, dst_dir_fd=dfd)
            except BaseException:
                try:
                    os.unlink(tmp, dir_fd=dfd)
                except OSError:
                    pass
                raise
        finally:
            os.close(dfd)

    def _append(self, parts, data):
        """Acrescenta data ao fim do arquivo parts (criado se falta), com fsync, sem seguir symlink."""
        *parts, leaf = parts
        if not self._posix:
            path, steps = self._win_dir(parts, create=True)
            fd = self._win_open(path / leaf, os.O_WRONLY | os.O_CREAT | os.O_APPEND, exists=False)
            with os.fdopen(fd, "ab") as fh:
                fh.write(data)
                fh.flush()
                os.fsync(fh.fileno())
            self._win_recheck(steps)
            return
        dfd = self._dir(parts, create=True)
        try:
            fd = os.open(leaf, os.O_WRONLY | os.O_CREAT | os.O_APPEND | _NOFOLLOW, 0o644, dir_fd=dfd)
            with os.fdopen(fd, "ab") as fh:
                fh.write(data)
                fh.flush()
                os.fsync(fh.fileno())
        finally:
            os.close(dfd)

    def _remove_head(self, name):
        *parts, leaf = name.split("/")
        if not self._posix:
            path, steps = self._win_dir(parts)
            try:
                _win_retry(lambda: os.unlink(path / leaf))  # o unlink de um link remove o link, nunca o alvo
            except OSError as exc:
                raise StoreError(f"não deu para remover {name}: {exc}") from exc
            self._win_recheck(steps)
            return
        dfd = self._dir(parts)
        try:
            os.unlink(leaf, dir_fd=dfd)
        except OSError as exc:
            raise StoreError(f"não deu para remover {name}: {exc}") from exc
        finally:
            os.close(dfd)

    def _restore(self, name, previous):
        """Desfaz a troca da cabeça quando o registro (commit ou evento) falhou: a cabeça nunca fica sem histórico."""
        if previous is None:
            if self._read_head(name) is not None:
                self._remove_head(name)
        else:
            self._write_head(name, previous)

    def _lock(self):
        if not self._posix:
            try:
                fd = self._win_open(self.root / LOCK, os.O_RDWR | os.O_CREAT, exists=False)
            except OSError as exc:
                raise StoreError(f"trava recusada ({LOCK}): {exc}") from exc
            if msvcrt is None:  # o caminho do Windows fora do Windows (a bancada): confere o arquivo, sem trava
                return ("none", fd)
            while True:  # LK_NBLCK não espera: a espera é este laço, sem o limite de 10 s do LK_LOCK
                try:
                    os.lseek(fd, 0, os.SEEK_SET)
                    msvcrt.locking(fd, msvcrt.LK_NBLCK, 1)
                    return ("msvcrt", fd)
                except OSError:
                    time.sleep(0.05)
        if fcntl is None:
            return None
        rfd = os.open(self.root, os.O_RDONLY | _DIRECTORY | _NOFOLLOW)
        try:
            fd = os.open(LOCK, os.O_RDWR | os.O_CREAT | _NOFOLLOW, 0o644, dir_fd=rfd)
        except OSError as exc:
            raise StoreError(f"trava recusada ({LOCK} é symlink?): {exc}") from exc
        finally:
            os.close(rfd)
        fcntl.flock(fd, fcntl.LOCK_EX)
        return ("flock", fd)

    @staticmethod
    def _unlock(lock):
        if lock is None:
            return
        kind, fd = lock
        try:
            if kind == "flock":
                fcntl.flock(fd, fcntl.LOCK_UN)
            elif kind == "msvcrt":
                os.lseek(fd, 0, os.SEEK_SET)
                msvcrt.locking(fd, msvcrt.LK_UNLCK, 1)
        finally:
            os.close(fd)

    # --- leitura -------------------------------------------------------------------------------------------
    def list(self):
        """Os nomes .kg.yaml e .kg.json do armazém, em ordem. Pasta ou arquivo oculto, symlink e nome fora da forma ficam fora."""
        return self._disk_names()

    def _disk_names(self):
        out = []

        def walk(path, prefix):
            with os.scandir(path) as it:
                for e in it:
                    if e.name.startswith("."):
                        continue
                    rel = prefix + e.name
                    try:  # no Windows, o DirEntry traz a tag real do reparse point
                        st = e.stat(follow_symlinks=False)
                    except FileNotFoundError:  # removido durante a listagem
                        continue
                    if _is_link(st):  # link e junção ficam fora, como pasta e arquivo oculto
                        continue
                    if stat.S_ISDIR(st.st_mode):
                        walk(e.path, rel + "/")
                    elif stat.S_ISREG(st.st_mode) and NAME.fullmatch(rel):
                        out.append(rel)
        walk(self.root, "")
        return sorted(out)

    def read(self, name, ref=None):
        check_name(name)
        self._check_case(name)
        if ref is not None:
            return self._read_ref(check_name(name), ref)
        text = self._visible(name, self._read_head(name))
        if text is None:
            raise NotFound(f"{name} não existe")
        return text

    def _read_ref(self, name, ref):
        raise StoreError(f"o armazém {self.backend} não guarda versão anterior")

    def history(self, name):
        check_name(name)
        self._check_case(name)
        return []

    # --- o gate --------------------------------------------------------------------------------------------
    def _texts(self, skip=None):
        """[(nome, texto)] do armazém, cada texto como o leitor deve lê-lo (as_source: o .kg.json é JsonText)."""
        items = []
        for n in self.list():
            if n == skip:
                continue
            try:
                t = self._read_head(n)
            except StoreError:  # ilegível (não UTF-8) entra sem ids, como no corpus_index do gate
                t = None
            items.append((n, kg_validate.as_source(n, t if t is not None else "")))
        return items

    @staticmethod
    def corpus_of(items):
        """O corpus da ponta externa a partir de [(nome, texto)]: os .kg.yaml e os .kg.json, como o corpus_index do gate."""
        return kg_validate.index_texts(items)

    def _judge(self, name, text):
        """(doc, erro): julga o candidato (text None = remoção) e os grafos que apontam para name, contra o armazém
        com o candidato no lugar. doc None com erro = não julgado."""
        return self._judge_set({name: text})

    def _judge_set(self, changes):
        """(doc, erro): julga um conjunto de mudanças {nome: texto, ou None para remover} de uma vez, contra o armazém
        com TODAS no lugar: os candidatos e os grafos que ficam e apontam para algum dos nomes. É o que deixa uma
        regeneração trocar dois grafos que se citam sem passar por um estado intermediário sem ponta."""
        try:
            others = [(n, t) for n, t in self._texts() if n not in changes]
            cands = [(n, kg_validate.as_source(n, t)) for n, t in changes.items() if t is not None]
            corpus = self.corpus_of(others + cands)
            sources = cands + [(n, t) for n, t in others if kg_validate.external_targets(t) & set(changes)]
            doc = kg_validate.judge(sources, self.schema, corpus=corpus)
        except Exception as exc:  # noqa: BLE001 - qualquer falha do julgamento é "não julgado", nunca PASS
            return None, f"{type(exc).__name__}: {exc}"
        if not _verdict_ok(doc):
            return None, "o julgamento saiu fora de spec/verdict.schema.json"
        return doc, None

    def _judge_all(self, name, text):
        """(doc, erro, de_fora): o contrato e, se ele aprova, o gate externo. de_fora diz que o FAIL veio do gate
        externo. Uma falha do gate externo, ou um gate que levanta, é "não julgado", nunca PASS."""
        return self._judge_set_all({name: text})

    def _judge_set_all(self, changes):
        """_judge_all para um conjunto: o contrato sobre o conjunto inteiro e, se ele aprova, o gate externo em cada
        mudança, na ordem dada. O primeiro FAIL ou falha do gate decide."""
        # uma mudança só passa por _judge, o ponto que write() e delete() sempre usaram
        doc, err = self._judge(*next(iter(changes.items()))) if len(changes) == 1 else self._judge_set(changes)
        if doc is None or self.gate is None or any(r["verdict"] == "FAIL" for r in doc["results"]):
            return doc, err, False
        for name, text in changes.items():
            try:
                gdoc, gerr = self.gate(name, text, "write" if text is not None else "delete")
            except Exception as exc:  # noqa: BLE001 - o gate de quem adota não derruba o armazém nem vira PASS
                return None, f"o gate externo levantou {type(exc).__name__}: {exc}", False
            if gdoc is not None and _verdict_ok(gdoc) and not gdoc["results"]:
                gdoc, gerr = None, "veredito sem resultado"
            if gdoc is None or not _verdict_ok(gdoc):
                gerr = gerr or "veredito fora de spec/verdict.schema.json"
                return None, gerr if "gate externo" in gerr else f"gate externo: {gerr}", False
            if any(r["verdict"] == "FAIL" for r in gdoc["results"]):
                return gdoc, None, True
        return doc, None, False

    def _result(self, name, written, reason=None, sha=None, ref=None, verdict=None, error=None, unchanged=False):
        return {"written": written, "reason": reason, "name": name, "sha256": sha, "ref": ref,
                "verdict": verdict, "error": error, "unchanged": unchanged}

    def write(self, name, text, message=None, author=None, expected_sha256=None, max_names=None):
        """max_names: um nome NOVO é recusado (StoreError) quando o armazém já tem esse número de grafos. A conta é
        feita sob a trava da gravação, para gravações concorrentes não passarem juntas do limite."""
        check_name(name)
        check_author(author)
        message = check_message(message, f"grava {name}")
        if not isinstance(text, str):
            raise StoreError("o texto do grafo tem de ser str")
        lock = self._lock()
        try:
            self._precheck()
            self._check_case(name)
            head = self._read_head(name)
            if head is None:
                check_portable(name)
                if max_names is not None and len(self.list()) >= max_names:
                    raise StoreError(f"o armazém já tem {max_names} grafos, o limite deste servidor")
            visible = self._visible(name, head)
            current = sha256(visible) if visible is not None else None
            if expected_sha256 is not None and expected_sha256 != (current or NEW):
                return self._result(name, False, "conflict", current)
            doc, err, external = self._judge_all(name, text)
            if doc is None:
                return self._result(name, False, "not_judged", current, error=err)
            if any(r["verdict"] == "FAIL" for r in doc["results"]):
                return self._result(name, False, "gate", current, verdict=doc,
                                    error="reprovado pelo gate externo" if external else None)
            new = sha256(text)
            if new == self._recorded_sha(name):  # o mesmo texto da última versão registrada: sem commit nem evento
                if new != current:
                    self._write_head(name, text)
                return self._result(name, True, None, new, None, doc, unchanged=True)
            self._write_head(name, text)
            try:
                ref = self._commit("write", name, new, message, author, text)
            except BaseException:
                self._restore(name, head)
                raise
            return self._result(name, True, None, new, ref, doc)
        finally:
            self._unlock(lock)

    def delete(self, name, message=None, author=None, expected_sha256=None):
        check_name(name)
        check_author(author)
        message = check_message(message, f"remove {name}")
        lock = self._lock()
        try:
            self._precheck()
            self._check_case(name)
            head = self._read_head(name)
            if self._visible(name, head) is None:
                return self._result(name, False, "missing")
            current = sha256(head)
            if expected_sha256 is not None and expected_sha256 != current:
                return self._result(name, False, "conflict", current)
            doc, err, external = self._judge_all(name, None)
            if doc is None:
                return self._result(name, False, "not_judged", current, error=err)
            if any(r["verdict"] == "FAIL" for r in doc["results"]):
                return self._result(name, False, "gate", current, verdict=doc,
                                    error="reprovado pelo gate externo" if external else None)
            self._remove_head(name)
            try:
                ref = self._commit("delete", name, None, message, author, None)
            except BaseException:
                self._restore(name, head)
                raise
            return self._result(name, True, None, None, ref, doc)
        finally:
            self._unlock(lock)

    def write_many(self, changes, message=None, author=None, expected=None, max_names=None):
        """Grava um conjunto de mudanças de uma vez, ou nenhuma: changes é [(nome, texto)], com texto None para remover.
        O contrato julga o conjunto inteiro contra o armazém com todas as mudanças no lugar (_judge_set), e só grava
        com PASS em tudo. expected é {nome: sha256 da cabeça lida, ou NEW}, a trava otimista por nome. Resultado:
        {written, reason, results: [um por nome, na ordem dada, como o de write()/delete()], ref, verdict, error}.
        reason é o do primeiro nome que barrou, ou null. Em conflict e missing, o nome que barrou leva o motivo e os
        outros saem como skipped; em gate e not_judged, o julgamento é do conjunto, e todos saem com esse motivo. O gate
        externo, se houver, julga cada mudança isolada, como no write(). A mudança que repete a última versão registrada sai com unchanged; o resto entra num registro
        só (um commit no git, um bloco de eventos no versionado). Se o registro falha, todas as cabeças voltam."""
        if not isinstance(changes, (list, tuple)) or not changes:
            raise StoreError("changes tem de ser uma lista não vazia de (nome, texto)")
        if any(not isinstance(c, (list, tuple)) or len(c) != 2 for c in changes):
            raise StoreError("cada mudança é um par (nome, texto)")
        changes = [tuple(c) for c in changes]
        names = [n for n, _ in changes]
        if len(set(names)) != len(names):
            raise StoreError("o mesmo nome aparece duas vezes no conjunto")
        for n, t in changes:
            check_name(n)
            if t is not None and not isinstance(t, str):
                raise StoreError(f"o texto de {n} tem de ser str (ou None para remover)")
        check_author(author)
        message = check_message(message, f"grava {len(changes)} grafos")
        expected = dict(expected or {})
        if set(expected) - set(names):
            raise StoreError("expected cita nome fora do conjunto")
        lock = self._lock()
        try:
            self._precheck()
            self._check_set_case(names)
            heads, current, out = {}, {}, {}
            for n, t in changes:
                self._check_case(n)
                heads[n] = self._read_head(n)
                if heads[n] is None and t is not None:
                    check_portable(n)
                visible = self._visible(n, heads[n])
                current[n] = sha256(visible) if visible is not None else None
                if t is None and visible is None:
                    out[n] = self._result(n, False, "missing")
                elif n in expected and expected[n] != (current[n] or NEW):
                    out[n] = self._result(n, False, "conflict", current[n])
            new_names = [n for n, t in changes if t is not None and current[n] is None]
            if max_names is not None and new_names and len(self.list()) + len(new_names) > max_names:
                raise StoreError(f"o armazém já tem {len(self.list())} grafos, e o limite deste servidor é {max_names}")
            if out:
                return self._many(changes, out, current, next(r["reason"] for r in out.values()))
            doc, err, external = self._judge_set_all(dict(changes))
            if doc is None:
                return self._many(changes, {n: self._result(n, False, "not_judged", current[n], error=err)
                                            for n in names}, current, "not_judged", error=err)
            if any(r["verdict"] == "FAIL" for r in doc["results"]):
                error = "reprovado pelo gate externo" if external else None
                return self._many(changes, {n: self._result(n, False, "gate", current[n], verdict=doc, error=error)
                                            for n in names}, current, "gate", verdict=doc, error=error)
            todo, touched = [], []
            ref = None
            try:
                for n, t in changes:
                    new = sha256(t) if t is not None else None
                    if t is not None and new == self._recorded_sha(n):  # a última versão registrada: sem registro
                        if new != current[n]:
                            touched.append(n)
                            self._write_head(n, t)
                        out[n] = self._result(n, True, None, new, None, doc, unchanged=True)
                    else:
                        todo.append((n, t, new))
                for n, t, _ in todo:
                    touched.append(n)
                    if t is None:
                        self._remove_head(n)
                    else:
                        self._write_head(n, t)
                if todo:
                    ref = self._commit_many(todo, message, author)
            except BaseException:
                for n in reversed(touched):  # desfaz tudo o que tocou, mesmo que um _restore falhe no meio
                    try:
                        self._restore(n, heads[n])
                    except Exception:  # noqa: BLE001 - a exceção que sobe é a original
                        pass
                raise
            for n, t, new in todo:
                out[n] = self._result(n, True, None, new, ref, doc)
            return self._many(changes, out, current, None, ref=ref, verdict=doc)
        finally:
            self._unlock(lock)

    def _check_set_case(self, names):
        """O _check_case olha o disco; dois nomes do conjunto que só diferem pela caixa passariam juntos. Recusa o par,
        menos quando os dois já existem no armazém com a caixa exata (num disco que distingue), como no write()."""
        seen = {}
        for n in names:
            parts = n.split("/")
            for k in range(1, len(parts) + 1):
                prefix = "/".join(parts[:k])
                first, owner = seen.setdefault(prefix.casefold(), (prefix, n))
                if first != prefix and not (self._read_head(n) is not None and self._read_head(owner) is not None):
                    raise StoreError(f"nome inválido: {n!r} só difere de {owner!r} pela caixa, no mesmo conjunto (no "
                                     "Windows e no macOS os dois são o mesmo arquivo)")

    def _many(self, changes, out, current, reason, ref=None, verdict=None, error=None):
        results = [out.get(n) or self._result(n, False, "skipped", current.get(n)) for n, _ in changes]
        return {"written": reason is None, "reason": reason, "results": results, "ref": ref, "verdict": verdict,
                "error": error}

    def _commit_many(self, todo, message, author):
        """O registro de um conjunto [(nome, texto ou None, sha)]. No disco não há registro."""
        return None

    def _precheck(self):
        """O registro está legível? Falha aqui, antes de tocar a cabeça."""

    def _case_clash(self, name):
        """O caminho do armazém que difere de name só pela caixa num segmento (pasta ou arquivo) que não existe com a
        caixa exata, ou None. No Windows e no macOS os dois seriam o mesmo arquivo: ler, gravar ou remover por ele
        mexeria no outro sem o gate saber. Um par que já existe com as duas caixas (num disco que as distingue) segue.
        Olha só as pastas do caminho, não a árvore inteira."""
        path = self.root
        for k, seg in enumerate(name.split("/")):
            try:
                with os.scandir(path) as it:
                    entries = [e.name for e in it]
            except (FileNotFoundError, NotADirectoryError):
                return None
            if seg in entries:
                path = path / seg
                try:  # não desce por um link: o caminho normal o recusa, e o nome de fora da raiz não vaza na mensagem
                    if _redirects(path, os.lstat(path)):
                        return None
                except OSError:
                    return None
                continue
            other = next((e for e in entries if e.casefold() == seg.casefold()), None)
            if other is None:
                return None
            return "/".join(name.split("/")[:k] + [other])
        return None

    def _check_case(self, name):
        clash = self._case_clash(name)
        if clash is not None:
            raise StoreError(f"nome inválido: {name!r} só difere de {clash!r} pela caixa (no Windows e no macOS os dois "
                             "são o mesmo arquivo)")

    def _visible(self, name, head):
        """A cabeça como o armazém a enxerga (no disco, o próprio arquivo); a trava e o missing usam esta régua."""
        return head

    def _recorded_sha(self, name):
        """O sha256 da última versão registrada (no disco, a própria cabeça)."""
        head = self._read_head(name)
        return sha256(head) if head is not None else None

    def _commit(self, op, name, sha, message, author, text):
        return None


class GitStore(DiskStore):
    """Um commit por gravação ou remoção. O git roda com GIT_DIR e GIT_WORK_TREE na raiz e GIT_CEILING_DIRECTORIES no
    pai dela: nunca sobe para um repo de fora. author vai no --author; o committer é fixo do serviço (committer=)."""
    backend = "git"

    def __init__(self, root, schema=None, init=False, committer=("kg-store", "kg-store@localhost"), gate=None):
        super().__init__(root, schema, init, gate)
        self.committer = committer
        git = self.root / ".git"
        if not os.path.lexists(git):
            if not init:
                raise StoreError(f"{self.root} não tem .git (use init=True para criar)")
            self._git("init", "-q", setup=True)
        st = os.lstat(git)
        if _is_link(st) or not stat.S_ISDIR(st.st_mode):
            raise StoreError(f"{git} tem de ser um diretório, não symlink nem gitfile")
        exclude = git / "info" / "exclude"  # a trava do armazém não é conteúdo: fica fora do status
        try:
            for p in (git / "info", exclude):
                if os.path.lexists(p) and _is_link(os.lstat(p)):
                    raise StoreError(f"{p} é symlink")
            current = exclude.read_text(encoding="utf-8") if exclude.is_file() else ""
            if LOCK not in current.split("\n"):
                exclude.parent.mkdir(exist_ok=True)
                exclude.write_text(current + ("" if current.endswith("\n") or not current else "\n") + LOCK + "\n",
                                   encoding="utf-8")
        except OSError as exc:
            raise StoreError(f"não deu para escrever {exclude}: {exc}") from exc

    def _check_root(self, path):
        """O GitStore é o armazém que mora num repo: o próprio, na raiz (o __init__ confere o .git)."""

    def _git(self, *args, setup=False, check=True):
        env = {k: v for k, v in os.environ.items() if not k.startswith("GIT_")}
        env.update({"GIT_CEILING_DIRECTORIES": str(self.root.parent), "GIT_CONFIG_NOSYSTEM": "1",
                    "GIT_CONFIG_GLOBAL": os.devnull, "XDG_CONFIG_HOME": "", "GIT_TERMINAL_PROMPT": "0"})
        if not setup:
            env.update({"GIT_DIR": str(self.root / ".git"), "GIT_WORK_TREE": str(self.root)})
        name, email = self.committer
        env.update({"GIT_COMMITTER_NAME": name, "GIT_COMMITTER_EMAIL": email,
                    "GIT_AUTHOR_NAME": name, "GIT_AUTHOR_EMAIL": email})
        hardening = []  # nada da config do usuário muda o conteúdo gravado nem quem roda
        for kv in ("core.hooksPath=" + os.devnull, "commit.gpgsign=false", "core.autocrlf=false", "core.eol=lf",
                   "core.safecrlf=false", "core.excludesFile=" + os.devnull, "core.attributesFile=" + os.devnull,
                   "core.fsmonitor=false", "core.symlinks=false"):
            hardening += ["-c", kv]
        try:
            out = subprocess.run(["git", *hardening, *args], cwd=self.root, env=env, capture_output=True)
        except (OSError, ValueError) as exc:
            raise StoreError(f"git {args[0]} não rodou: {exc}") from exc
        if check and out.returncode != 0:
            raise StoreError(f"git {args[0]} falhou: {out.stderr.decode('utf-8', 'replace').strip()}")
        return out

    def list(self):
        """Os nomes RASTREADOS (o mesmo corpus do gate do repo, que lê git ls-files), regulares e na forma do nome."""
        out = self._git("ls-files", "-z", "--", "*.kg.yaml", "*.kg.json", check=False)
        if out.returncode != 0:
            return []
        disk = set(self._disk_names())
        return sorted(n for n in out.stdout.decode("utf-8").split("\0") if n and n in disk)

    def _visible(self, name, head):
        """No GitStore, o que não está rastreado não existe para o armazém (como para list() e para o gate)."""
        return head if head is not None and name in self.list() else None

    def _unstage(self, name):
        """O índice do nome volta ao HEAD (ou sai do índice, se o HEAD não o tem): nada fica pronto para commit."""
        if self._git("rev-parse", "-q", "--verify", "HEAD", check=False).returncode == 0:
            self._git("reset", "-q", "HEAD", "--", name, check=False)
        else:
            self._git("rm", "-q", "--cached", "--ignore-unmatch", "--", name, check=False)

    def _restore(self, name, previous):
        super()._restore(name, previous)
        self._unstage(name)

    def _recorded_sha(self, name):
        if self._git("diff", "--cached", "--quiet", "--", name, check=False).returncode != 0:
            self._unstage(name)  # índice sujo para o nome (uma falha de fora): sara antes de comparar
        out = self._git("show", f"HEAD:{name}", check=False)
        return hashlib.sha256(out.stdout).hexdigest() if out.returncode == 0 else None

    def _commit(self, op, name, sha, message, author, text):
        self._git("add", "-f", "-A", "--", name)
        args = ["commit", "-q", "--no-verify", "-m", message]
        if author:
            args += ["--author", author]
        self._git(*args, "--", name)
        return self._git("rev-parse", "HEAD").stdout.decode().strip()

    def _commit_many(self, todo, message, author):
        """Um commit só para o conjunto inteiro."""
        names = [n for n, _, _ in todo]
        self._git("add", "-f", "-A", "--", *names)
        args = ["commit", "-q", "--no-verify", "-m", message]
        if author:
            args += ["--author", author]
        self._git(*args, "--", *names)
        return self._git("rev-parse", "HEAD").stdout.decode().strip()

    def _read_ref(self, name, ref):
        if not re.fullmatch(r"[0-9a-fA-F]{4,64}", str(ref)):  # fullmatch: o $ aceitaria um \n final
            raise StoreError(f"ref inválida: {ref!r} (um sha de commit)")
        out = self._git("show", f"{ref}:{name}", check=False)
        if out.returncode != 0:
            raise NotFound(f"{name} não existe em {ref}")
        return out.stdout.decode("utf-8")

    def history(self, name):
        check_name(name)
        self._check_case(name)
        out = self._git("log", "--format=%H%x1f%an <%ae>%x1f%aI%x1f%s", "--name-status", "--", name, check=False)
        if out.returncode != 0:  # repo sem commit ainda
            return []
        events, cur = [], None
        for line in out.stdout.decode("utf-8").splitlines():
            if "\x1f" in line:
                ref, author, ts, subject = line.split("\x1f", 3)
                cur = {"ref": ref, "op": "write", "author": author, "ts": ts, "message": subject}
                events.append(cur)
            elif line.startswith("D\t") and cur is not None:
                cur["op"] = "delete"
        return events


class VersionedStore(DiskStore):
    """A cabeça em disco mais `.kg-store/events.jsonl` (um evento por operação, com seq) e `.kg-store/blobs/` (cada
    versão pelo sha256). ref é o seq do evento. Sem git, sem serviço: um diretório que qualquer backup copia."""
    backend = "versioned"

    def _events(self):
        text = self._meta_read("events.jsonl")
        try:
            return [json.loads(line) for line in text.splitlines() if line.strip()] if text else []
        except ValueError as exc:  # registro corrompido: falha alto, nunca grava por cima
            raise StoreError(f"{META}/events.jsonl corrompido: {exc}") from exc

    def _precheck(self):
        self._events()

    def _recorded_sha(self, name):
        last = next((e for e in reversed(self._events()) if e["name"] == name), None)
        return last["sha256"] if last else None

    def _meta_read(self, rel):
        data = self._read_file([META, *rel.split("/")])
        if data is None:
            return None
        try:
            return data.decode("utf-8")
        except UnicodeDecodeError as exc:
            raise StoreError(f"{META}/{rel} não é UTF-8") from exc

    def _commit(self, op, name, sha, message, author, text):
        if sha is not None:
            try:
                self._write_file([META, "blobs", f"{sha}.yaml"], text.encode("utf-8"))
            except OSError as exc:
                raise StoreError(f"não deu para gravar a versão {sha}: {exc}") from exc
        seq = len(self._events()) + 1
        event = {"seq": seq, "op": op, "name": name, "sha256": sha, "author": author, "message": message,
                 "ts": datetime.datetime.now(datetime.timezone.utc).isoformat(timespec="seconds")}
        try:
            self._append([META, "events.jsonl"], (json.dumps(event, ensure_ascii=False) + "\n").encode("utf-8"))
        except OSError as exc:
            raise StoreError(f"não deu para registrar o evento: {exc}") from exc
        return seq

    def _commit_many(self, todo, message, author):
        """As versões primeiro, depois todos os eventos num append só. ref é o seq do último evento do bloco. Um disco
        cheio no meio do append pode truncar a última linha, como no write(): o events.jsonl fica corrompido e o
        armazém recusa tudo até o conserto, sem gravar por cima."""
        for n, t, new in todo:
            if new is not None:
                try:
                    self._write_file([META, "blobs", f"{new}.yaml"], t.encode("utf-8"))
                except OSError as exc:
                    raise StoreError(f"não deu para gravar a versão {new}: {exc}") from exc
        seq = len(self._events())
        ts = datetime.datetime.now(datetime.timezone.utc).isoformat(timespec="seconds")
        lines = []
        for n, t, new in todo:
            seq += 1
            lines.append(json.dumps({"seq": seq, "op": "write" if t is not None else "delete", "name": n, "sha256": new,
                                     "author": author, "message": message, "ts": ts}, ensure_ascii=False) + "\n")
        try:
            self._append([META, "events.jsonl"], "".join(lines).encode("utf-8"))
        except OSError as exc:
            raise StoreError(f"não deu para registrar os eventos: {exc}") from exc
        return seq

    def history(self, name):
        check_name(name)
        self._check_case(name)
        return [{"ref": e["seq"], "op": e["op"], "author": e["author"], "ts": e["ts"], "message": e["message"],
                 "sha256": e["sha256"]} for e in reversed(self._events()) if e["name"] == name]

    def _read_ref(self, name, ref):
        try:
            seq = int(ref)
        except (TypeError, ValueError):
            raise StoreError(f"ref inválida: {ref!r} (o seq de um evento)")
        event = next((e for e in self._events() if e["seq"] == seq and e["name"] == name), None)
        if event is None or event["sha256"] is None:
            raise NotFound(f"{name} não tem versão no evento {ref}")
        text = self._meta_read(f"blobs/{event['sha256']}.yaml")
        if text is None:
            raise NotFound(f"a versão {event['sha256']} sumiu de {META}/blobs")
        if sha256(text) != event["sha256"]:
            raise StoreError(f"a versão {event['sha256']} em {META}/blobs não confere com o sha256 do evento")
        return text


BACKENDS = {"disk": DiskStore, "git": GitStore, "versioned": VersionedStore}


def open_store(backend, root, **kw):
    if backend not in BACKENDS:
        raise StoreError(f"backend desconhecido: {backend!r} ({', '.join(BACKENDS)})")
    return BACKENDS[backend](root, **kw)


def _utf8_stdio():
    """A saída que vai para pipe ou arquivo sai em UTF-8 (no Windows, o padrão seria cp1252, que derruba o ✓ e entrega
    a quem consome o JSON outra codificação); no terminal, fica a do console, trocando o caractere que ela não tem."""
    for stream in (sys.stdout, sys.stderr):
        if hasattr(stream, "reconfigure"):
            try:
                tty = stream.isatty()
            except ValueError:
                continue
            if tty:
                stream.reconfigure(errors="replace")
            else:
                stream.reconfigure(encoding="utf-8", errors="replace")


def read_set(path):
    """(changes, expected) de um conjunto em JSON para write_many. Um file é lido relativo ao conjunto."""
    path = pathlib.Path(path)
    try:
        doc = json.loads(path.read_text(encoding="utf-8"))
    except ValueError as exc:
        raise StoreError(f"{path.name} não é JSON: {exc}") from exc
    if not isinstance(doc, dict) or not isinstance(doc.get("changes"), list):
        raise StoreError(f"{path.name}: falta a lista changes")
    changes = []
    for c in doc["changes"]:
        if not isinstance(c, dict) or not isinstance(c.get("name"), str) or \
                sum(k in c for k in ("file", "text", "delete")) != 1:
            raise StoreError(f"{path.name}: cada mudança tem name e exatamente um de file, text ou delete")
        if "delete" in c:
            if c["delete"] is not True:
                raise StoreError(f"{path.name}: delete só aceita true")
            changes.append((c["name"], None))
        elif "text" in c:
            changes.append((c["name"], c["text"]))
        else:
            changes.append((c["name"], (path.parent / c["file"]).read_text(encoding="utf-8")))
    expected = doc.get("expected")
    if expected is not None and not isinstance(expected, dict):
        raise StoreError(f"{path.name}: expected é um objeto nome → sha256")
    return changes, expected


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--backend", choices=sorted(BACKENDS), default="disk")
    ap.add_argument("--root", required=True)
    ap.add_argument("--init", action="store_true", help="cria a raiz (e o repo, no git) se não existe")
    ap.add_argument("--gate-cmd", help="um gate externo, depois do contrato: o comando recebe o texto no stdin e devolve "
                                       "um kg-ssot.verdict/1 (veja CommandGate)")
    ap.add_argument("--gate-timeout", type=float, help="segundos para o gate externo (default 60)")
    sub = ap.add_subparsers(dest="cmd", required=True)
    sub.add_parser("list")
    p = sub.add_parser("read")
    p.add_argument("name")
    p.add_argument("--ref")
    for cmd in ("write", "delete"):
        p = sub.add_parser(cmd)
        p.add_argument("name")
        if cmd == "write":
            p.add_argument("file", nargs="?", default="-", help="o grafo; '-' (default) lê o stdin")
        p.add_argument("--message")
        p.add_argument("--author")
        p.add_argument("--expected-sha256")
    p = sub.add_parser("write-many")
    p.add_argument("file", help="o conjunto em JSON (veja o uso acima)")
    p.add_argument("--message")
    p.add_argument("--author")
    p = sub.add_parser("history")
    p.add_argument("name")
    args = ap.parse_args(argv)
    _utf8_stdio()

    def emit(obj):
        print(json.dumps(obj, ensure_ascii=False, indent=1))
    try:
        # --gate-cmd "" (uma variável vazia) é recusado, nunca "sem gate" calado
        if args.gate_timeout is not None and args.gate_cmd is None:
            raise StoreError("--gate-timeout sem --gate-cmd: não há gate para o tempo")
        gate = (CommandGate(args.gate_cmd, 60 if args.gate_timeout is None else args.gate_timeout)
                if args.gate_cmd is not None else None)
        if gate is not None:
            install_term_handler()
        store = open_store(args.backend, args.root, init=args.init, gate=gate)
        if args.cmd == "list":
            emit({"names": store.list()})
            return 0
        if args.cmd == "read":
            text = store.read(args.name, args.ref)
            emit({"name": args.name, "sha256": sha256(text), "text": text})
            return 0
        if args.cmd == "history":
            emit({"name": args.name, "history": store.history(args.name)})
            return 0
        if args.cmd == "write-many":
            res = store.write_many(*read_set(args.file), args.message, args.author)
            emit(res)
            return 0 if res["written"] else 2 if res["reason"] == "not_judged" else 1
        if args.cmd == "write":
            if args.file == "-":
                stream = getattr(sys.stdin, "buffer", None)
                text = stream.read().decode("utf-8") if stream is not None else sys.stdin.read()
            else:
                text = pathlib.Path(args.file).read_text(encoding="utf-8")
            res = store.write(args.name, text, args.message, args.author, args.expected_sha256)
        else:
            res = store.delete(args.name, args.message, args.author, args.expected_sha256)
    except NotFound as exc:
        emit({"error": str(exc)})
        return 1
    except (StoreError, OSError, UnicodeDecodeError) as exc:
        print(f"ENTRADA QUEBRADA  {exc}", file=sys.stderr)
        return 2
    emit(res)
    return 0 if res["written"] else 2 if res["reason"] == "not_judged" else 1


if __name__ == "__main__":
    sys.exit(main())
