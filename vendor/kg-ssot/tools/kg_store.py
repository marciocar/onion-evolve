#!/usr/bin/env python3
"""O armazém de .kg.yaml e .kg.json que só grava o que o contrato aprova.

Biblioteca primeiro, CLI por cima. Três armazéns com a mesma interface (read, list, write, delete, history):
  DiskStore(root)       a cabeça em disco, sem histórico;
  GitStore(root)        um commit por gravação ou remoção, com o git isolado na raiz (nunca sobe para um repo pai);
                        com serve=ServeRef(ref, signers), só de leitura: a árvore do commit de uma ref (branch que o
                        HEAD contém, ou tag SSH assinada), nunca a árvore de trabalho, relida quando a ref muda;
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
  - o veredito de cada grafo julgado fica num cache do objeto (kg_validate.JudgeCache), pela chave de tudo de que ele
    depende (texto, schemas, língua, limit e se cada ponta externa resolve): quem aponta e não mudou não é julgado de
    novo num processo longo, e o resultado é o mesmo que sem cache;
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
import contextlib
import datetime
import hashlib
import json
import os
import pathlib
import re
import secrets
import shlex
import shutil
import stat
import subprocess
import sys
import signal
import tempfile
import threading
import time

sys.dont_write_bytecode = True
if __package__:  # no pacote kg_ssot, o vizinho vem pelo pacote, sem mexer no sys.path de quem importa
    from . import kg_i18n, kg_validate
else:  # script ou vendor
    sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
    import kg_i18n  # noqa: E402
    import kg_validate  # noqa: E402
_ = kg_i18n._

try:
    import fcntl
except ImportError:  # Windows: a trava é a do msvcrt
    fcntl = None
try:
    import msvcrt
except ImportError:  # POSIX
    msvcrt = None

NAME = re.compile(r"^(?:[A-Za-z0-9_][A-Za-z0-9_.-]*/)*[A-Za-z0-9_][A-Za-z0-9_.-]*\.kg\.(?:yaml|json)$")
# o que o armazém LÊ para julgar a ponta externa (desde o contrato v4.15): a forma do <caminho> do contrato, que aceita
# a pasta com ponto (.github/); o que ele ESCREVE segue o NAME, que não aceita, e .git/ nunca entra
CORPUS_NAME = re.compile(r"^(?:\.?[A-Za-z0-9_][A-Za-z0-9_.-]*/)*\.?[A-Za-z0-9_][A-Za-z0-9_.-]*\.kg\.(?:yaml|json)$")
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


class InsideGitWorktree(StoreError):
    """A raiz do disco ou do versionado mora dentro de uma worktree git: ali vale o GitStore. Classe própria para quem
    escolhe o backend decidir pelo tipo, e não pela frase (que segue a língua do ambiente desde a 4.18.0)."""


def sha256(text):
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


def check_name(name):
    if not isinstance(name, str) or not NAME.fullmatch(name):
        raise StoreError(_("invalid name: {name!r} (relative, ends in .kg.yaml or .kg.json, no '..' or hidden segment)")
                         .format(name=name))
    if any(len(seg.encode("utf-8")) > SEGMENT_MAX for seg in name.split("/")):
        raise StoreError(_("invalid name: a segment has more than {max} bytes").format(max=SEGMENT_MAX))
    return name


def check_portable(name):
    """Um nome NOVO tem de existir em todo sistema: nenhum segmento reservado do Windows (CON, NUL, COM1...) nem que
    termina em ponto. O nome que já está no armazém segue lendo, gravando e removendo."""
    if any(seg.endswith(".") or _WIN_RESERVED.fullmatch(seg) for seg in name.split("/")):
        raise StoreError(_("invalid name: {name!r} (a segment reserved on Windows, such as CON or NUL, or one that ends "
                           "in a period)").format(name=name))
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
        raise StoreError(_("invalid author: {author!r} (the form is 'Name <email>')").format(author=author))
    return author


def check_message(message, default):
    """A mensagem do commit ou do evento: None vira o default; vazia ou com NUL é recusada antes de tocar o disco."""
    if message is None:
        return default
    if not isinstance(message, str) or not message.strip() or "\x00" in message:
        raise StoreError(_("invalid message: empty or contains NUL"))
    return message


_verdict_validator = None


def _verdict_ok(doc):
    """O documento do julgamento cumpre spec/verdict.schema.json? (o gate não confia nem no próprio leitor)"""
    global _verdict_validator
    if _verdict_validator is None:
        _verdict_validator = kg_validate.make_validator(json.loads(VERDICT_SCHEMA.read_text(encoding="utf-8")))
    return not any(True for _err in _verdict_validator.iter_errors(doc))


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
        raise StoreError(_("the external gate command cannot be parsed: {error}").format(error=exc)) from exc


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
            raise StoreError(_("empty external gate: give the command"))
        if not (isinstance(timeout, (int, float)) and 0 < timeout <= self.MAX_TIMEOUT):  # recusa também NaN
            raise StoreError(_("the external gate timeout must be more than 0 and up to {max} seconds")
                             .format(max=self.MAX_TIMEOUT))
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
                return None, _("the external gate output exceeded {max} bytes").format(max=self.MAX_OUTPUT)
            if time.monotonic() >= deadline:
                self._kill(p)
                return None, _("the external gate timed out after {timeout} s").format(timeout=self.timeout)

    def __call__(self, name, text, op):
        fold = str.upper if os.name == "nt" else str  # no Windows, o nome da variável não distingue caixa
        drop = {fold(k) for k in self.drop_env}
        env = {k: v for k, v in os.environ.items() if fold(k) not in drop}
        if kg_i18n.machine_active():  # chamado pelo MCP: o veredito do gate vai ao modelo, e o protocolo é inglês
            env["KG_SSOT_LANG"] = "en"
        env.update(KG_GATE_NAME=name, KG_GATE_OP=op)
        group = ({"creationflags": subprocess.CREATE_NEW_PROCESS_GROUP} if os.name == "nt"
                 else {"start_new_session": True})
        try:
            stdin, stdout = tempfile.TemporaryFile(), tempfile.TemporaryFile()
        except OSError as exc:  # sem diretório temporário: não julgado, sem o caminho dele na mensagem
            return None, _("the external gate did not run (no temporary file: {error})").format(
                error=exc.strerror or type(exc).__name__)
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
                        return None, _("the external gate did not run (the process is shutting down)")
                    if main:
                        _TERM["spawning"] = True
                    try:
                        p = subprocess.Popen(self.argv, stdin=stdin, stdout=stdout, stderr=subprocess.DEVNULL, env=env,
                                             **group)
                    except (OSError, ValueError) as exc:
                        return None, _("the external gate did not run ({kind}: {error})").format(
                            kind=type(exc).__name__, error=getattr(exc, 'strerror', None) or exc)
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
                return None, _("the external gate exited with rc {rc}").format(rc=rc)
            if stdout.seek(0, os.SEEK_END) > self.MAX_OUTPUT:  # o que ele escreveu entre a última conferência e o fim
                return None, _("the external gate output exceeded {max} bytes").format(max=self.MAX_OUTPUT)
            stdout.seek(0)
            raw = stdout.read()
        try:
            doc = json.loads(raw.decode("utf-8"))
        except (UnicodeDecodeError, ValueError):
            return None, _("the external gate did not return a JSON verdict")
        if not _verdict_ok(doc):
            return None, _("the external gate verdict does not conform to spec/verdict.schema.json")
        if not doc["results"]:
            return None, _("the external gate verdict has no result")
        if any(r["verdict"] == "FAIL" for r in doc["results"]) != (rc == 1):
            return None, _("the external gate rc does not match its verdict")
        return doc, None


class DiskStore:
    """A cabeça em disco. history() é vazio: este armazém não guarda versão anterior."""
    backend = "disk"

    def __init__(self, root, schema=None, init=False, gate=None):
        self.gate = gate  # o gate externo (CommandGate ou um chamável (name, text, op) -> (doc, erro)), depois do contrato
        if PATH_MODE not in ("posix", "win"):
            raise StoreError(_("the store requires POSIX (os.open with dir_fd and O_NOFOLLOW) or Windows"))
        self._posix = PATH_MODE == "posix"
        if not str(root).strip():
            raise StoreError(_("empty root: give the store directory"))
        self.root = pathlib.Path(root)
        if init and not os.path.lexists(self.root):
            ancestor = self.root.absolute()
            while not os.path.lexists(ancestor):
                if ancestor.parent == ancestor:  # um drive ou compartilhamento que não existe: nada acima para criar
                    raise StoreError(_("the root {root} is on a drive or share that does not exist").format(root=self.root))
                ancestor = ancestor.parent
            self._check_root(ancestor)  # recusa antes de criar a pasta, não depois
            try:
                self.root.mkdir(parents=True)
            except OSError as exc:
                raise StoreError(_("could not create the root {root}: {error}").format(root=self.root, error=exc)) from exc
        try:
            st = os.lstat(self.root)
        except OSError as exc:
            raise StoreError(_("unreadable root: {error}").format(error=exc)) from exc
        if _is_link(st) or not stat.S_ISDIR(st.st_mode):
            raise StoreError(_("the root {root} must be a directory, not a symlink").format(root=self.root))
        self.root = self.root.resolve()
        self.schema = schema or kg_validate.CONTRACT_MUST
        # o julgamento já feito neste processo: o grafo que aponta para o gravado e não mudou não é julgado de novo
        self._cache = kg_validate.JudgeCache()
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
            raise InsideGitWorktree(_("{path} is inside a git repo: use the GitStore (the gate corpus is the tracked "
                                      "files)")
                             .format(path=path))

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
                    raise NotFound(_("missing folder: {part}").format(part=part))
                except OSError as exc:  # ELOOP/ENOTDIR: symlink ou arquivo no lugar da pasta
                    raise StoreError(_("folder refused (symlink or not a directory): {part}").format(part=part)) from exc
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
                raise NotFound(_("missing folder: {part}").format(part=part))
            except OSError as exc:
                raise StoreError(_("unreadable folder: {path}: {error}").format(path=path, error=exc)) from exc
            if _redirects(path, st) or not stat.S_ISDIR(st.st_mode):
                raise StoreError(_("folder refused (link, junction, or not a directory): {part}").format(part=part or path))
            steps.append((path, st))
        return path, steps

    @staticmethod
    def _win_recheck(steps):
        """O caminho é o mesmo de antes da operação: nenhum passo virou link nem foi trocado por outra pasta."""
        for path, before in steps:
            try:
                st = os.lstat(path)
            except OSError as exc:
                raise StoreError(_("the path changed during the operation: {path}").format(path=path)) from exc
            if _is_link(st) or not _same(st, before):
                raise StoreError(_("the path changed during the operation: {path}").format(path=path))

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
            raise StoreError(_("file refused (link, junction, or not regular): {name}").format(name=path.name))
        fd = os.open(path, flags | _BINARY, mode)
        try:
            opened = os.fstat(fd)
            after = os.lstat(path)
            if (_is_link(after) or not stat.S_ISREG(opened.st_mode) or not _same(opened, after)
                    or (before is not None and not _same(opened, before))):
                raise StoreError(_("file refused (replaced while opening): {name}").format(name=path.name))
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
                raise StoreError(_("file refused: {name}: {error}").format(name=leaf, error=exc)) from exc
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
                raise StoreError(_("file refused (symlink?): {name}").format(name=leaf)) from exc
            with os.fdopen(fd, "rb") as fh:
                if not stat.S_ISREG(os.fstat(fh.fileno()).st_mode):
                    raise StoreError(_("not a regular file: {name}").format(name=leaf))
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
            raise StoreError(_("{name} is not UTF-8").format(name=name)) from exc

    def _write_head(self, name, text):
        try:
            self._write_file(name.split("/"), text.encode("utf-8"))
        except OSError as exc:
            raise StoreError(_("could not write {name}: {error}").format(name=name, error=exc)) from exc

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
                raise StoreError(_("could not remove {name}: {error}").format(name=name, error=exc)) from exc
            self._win_recheck(steps)
            return
        dfd = self._dir(parts)
        try:
            os.unlink(leaf, dir_fd=dfd)
        except OSError as exc:
            raise StoreError(_("could not remove {name}: {error}").format(name=name, error=exc)) from exc
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
                raise StoreError(_("lock refused ({lock}): {error}").format(lock=LOCK, error=exc)) from exc
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
            raise StoreError(_("lock refused (is {lock} a symlink?): {error}").format(lock=LOCK, error=exc)) from exc
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
            raise NotFound(_("{name} does not exist").format(name=name))
        return text

    def check_ref(self, ref):
        """A forma do ref, sem olhar nome nenhum: a recusa sai igual para qualquer grafo. No disco, todo ref é recusado."""
        raise StoreError(_("the {backend} store keeps no earlier version").format(backend=self.backend))

    def _read_ref(self, name, ref):
        self.check_ref(ref)

    def history(self, name):
        check_name(name)
        self._check_case(name)
        return []

    # --- o gate --------------------------------------------------------------------------------------------
    def _corpus_names(self):
        """Os nomes do corpus que julga a ponta externa. No disco e no versionado, os do armazém; o GitStore soma os
        rastreados em pasta com ponto, que o gate do repo (corpus_index) também lê."""
        return self.list()

    def _read_corpus(self, name):
        """O texto de um nome do corpus: pela cabeça quando é um nome do armazém, e direto do arquivo quando só o
        corpus o aceita (pasta com ponto). Symlink no caminho é StoreError, como na cabeça."""
        if NAME.fullmatch(name):
            return self._read_head(name)
        data = self._read_file(name.split("/"))
        if data is None:
            return None
        try:
            return data.decode("utf-8")
        except UnicodeDecodeError as exc:
            raise StoreError(_("{name} is not UTF-8").format(name=name)) from exc

    def _texts(self, skip=None, names=None):
        """[(nome, texto)] do corpus que JULGA (o do gate, com a pasta com ponto no GitStore), cada texto como o leitor
        deve lê-lo (as_source: o .kg.json é JsonText). names: outra lista de nomes (a consulta passa list())."""
        items = []
        for n in (self._corpus_names() if names is None else names):
            if n == skip:
                continue
            try:
                t = self._read_corpus(n)
            except StoreError:  # ilegível (não UTF-8) entra sem ids, como no corpus_index do gate
                t = None
            items.append((n, kg_validate.as_source(n, t if t is not None else "")))
        return items

    def list_texts(self):
        """[(nome, texto)] só dos grafos do armazém (os que list() mostra e read() lê): é o que a consulta do servidor
        MCP projeta, para nunca devolver um grafo que kg_get recusaria."""
        return self._texts(names=self.list())

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
            corpus = kg_validate.index_texts(others + cands, cache=self._cache)
            sources = cands + [(n, t) for n, t in others
                               if {path for path, _ in self._cache.facts(t)[1]} & set(changes)]
            doc = kg_validate.judge(sources, self.schema, corpus=corpus, cache=self._cache)
        except Exception as exc:  # noqa: BLE001 - qualquer falha do julgamento é "não julgado", nunca PASS
            return None, f"{type(exc).__name__}: {exc}"
        if not _verdict_ok(doc):
            return None, _("the judgment does not conform to spec/verdict.schema.json")
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
                return None, _("the external gate raised {kind}: {error}").format(kind=type(exc).__name__, error=exc), False
            if gdoc is not None and _verdict_ok(gdoc) and not gdoc["results"]:
                gdoc, gerr = None, _("verdict has no result")
            if gdoc is None or not _verdict_ok(gdoc):
                gerr = gerr or _("verdict does not conform to spec/verdict.schema.json")
                # a mensagem que já nomeia o gate externo (na língua em uso) vai como está; as outras ganham o prefixo
                return None, gerr if _("external gate") in gerr else _("external gate: {error}").format(error=gerr), False
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
            raise StoreError(_("the graph text must be a str"))
        lock = self._lock()
        try:
            self._precheck()
            self._check_case(name)
            head = self._read_head(name)
            if head is None:
                check_portable(name)
                if max_names is not None and len(self.list()) >= max_names:
                    raise StoreError(_("the store already has {n} graphs, the limit on this server").format(n=max_names))
            visible = self._visible(name, head)
            current = sha256(visible) if visible is not None else None
            if expected_sha256 is not None and expected_sha256 != (current or NEW):
                return self._result(name, False, "conflict", current)
            doc, err, external = self._judge_all(name, text)
            if doc is None:
                return self._result(name, False, "not_judged", current, error=err)
            if any(r["verdict"] == "FAIL" for r in doc["results"]):
                return self._result(name, False, "gate", current, verdict=doc,
                                    error=_("rejected by the external gate") if external else None)
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
                                    error=_("rejected by the external gate") if external else None)
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
            raise StoreError(_("changes must be a non-empty list of (name, text)"))
        if any(not isinstance(c, (list, tuple)) or len(c) != 2 for c in changes):
            raise StoreError(_("each change is a (name, text) pair"))
        changes = [tuple(c) for c in changes]
        names = [n for n, _text in changes]
        if len(set(names)) != len(names):
            raise StoreError(_("the same name appears twice in the set"))
        for n, t in changes:
            check_name(n)
            if t is not None and not isinstance(t, str):
                raise StoreError(_("the text of {name} must be a str (or None to remove)").format(name=n))
        check_author(author)
        message = check_message(message, f"grava {len(changes)} grafos")
        expected = dict(expected or {})
        if set(expected) - set(names):
            raise StoreError(_("expected has a name outside the set"))
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
                raise StoreError(_("the store already has {n} graphs, and the limit on this server is {max}")
                                 .format(n=len(self.list()), max=max_names))
            if out:
                return self._many(changes, out, current, next(r["reason"] for r in out.values()))
            doc, err, external = self._judge_set_all(dict(changes))
            if doc is None:
                return self._many(changes, {n: self._result(n, False, "not_judged", current[n], error=err)
                                            for n in names}, current, "not_judged", error=err)
            if any(r["verdict"] == "FAIL" for r in doc["results"]):
                error = _("rejected by the external gate") if external else None
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
                for n, t, _sha in todo:
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
                    raise StoreError(_("invalid name: {name!r} differs from {other!r} only by case, in the same set "
                                       "(on Windows and macOS they are the same file)").format(name=n, other=owner))

    def _many(self, changes, out, current, reason, ref=None, verdict=None, error=None):
        results = [out.get(n) or self._result(n, False, "skipped", current.get(n)) for n, _text in changes]
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
            raise StoreError(_("invalid name: {name!r} differs from {other!r} only by case (on Windows and macOS they "
                               "are the same file)").format(name=name, other=clash))

    def _visible(self, name, head):
        """A cabeça como o armazém a enxerga (no disco, o próprio arquivo); a trava e o missing usam esta régua."""
        return head

    def _recorded_sha(self, name):
        """O sha256 da última versão registrada (no disco, a própria cabeça)."""
        head = self._read_head(name)
        return sha256(head) if head is not None else None

    def _commit(self, op, name, sha, message, author, text):
        return None


# o nome de uma ref servida, depois de refs/heads/ ou refs/tags/: segmentos de letra, dígito, ponto, traço e _, sem
# começar por ponto ou traço (o git recusaria, e o traço viraria opção), sem .. e sem terminar em .lock ou ponto
REF_SEGMENT = re.compile(r"[A-Za-z0-9_][A-Za-z0-9._-]*")
# a versão semântica (semver.org 2.0.0) que o * de um padrão de tag tem de casar; ASCII: o \d não casa outro dígito
SEMVER = re.compile(r"(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)"
                    r"(?:-((?:0|[1-9]\d*|\d*[A-Za-z-][0-9A-Za-z-]*)(?:\.(?:0|[1-9]\d*|\d*[A-Za-z-][0-9A-Za-z-]*))*))?"
                    r"(?:\+([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?", re.ASCII)
SIGNERS_MAX_BYTES = 1 << 20  # o allowed_signers é escrito pelo operador: 1 MiB sobra para milhares de chaves
SSH_SIGNATURE = b"-----BEGIN SSH SIGNATURE-----"
SERVE_TIMEOUT = 30  # segundos de cada git (e do ssh-keygen que ele chama) no modo servido
# a config que o modo servido fixa na linha de comando, que vence a do repo (.git/config, e o que ela inclui): o
# programa que verifica é o ssh-keygen achado na partida (ServeRef.ssh_keygen), GPG e X.509 nunca rodam, nenhum
# protocolo de transporte vale (nada se busca) e nada da config local executa código
SERVED_CONFIG = ("gpg.format=ssh", "gpg.program=" + os.devnull,
                 "gpg.openpgp.program=" + os.devnull, "gpg.x509.program=" + os.devnull, "gpg.minTrustLevel=fully",
                 "gpg.ssh.revocationFile=" + os.devnull, "log.showSignature=false", "core.pager=cat",
                 "diff.external=", "core.sshCommand=" + os.devnull, "core.alternateRefsCommand=",
                 "core.hooksPath=" + os.devnull, "core.fsmonitor=false", "protocol.allow=never",
                 # cada protocolo pelo nome: protocol.<nome>.allow é mais específica e venceria o protocol.allow
                 "protocol.ext.allow=never", "protocol.fd.allow=never", "protocol.file.allow=never",
                 "protocol.git.allow=never", "protocol.http.allow=never", "protocol.https.allow=never",
                 "protocol.ftp.allow=never", "protocol.ftps.allow=never", "protocol.ssh.allow=never",
                 "protocol.git+ssh.allow=never", "protocol.ssh+git.allow=never", "protocol.rsync.allow=never",
                 "credential.helper=", "core.gitProxy=", "core.askPass=")
# o ambiente que desliga o lazy fetch do clone parcial (git 2.45.1, e as correções 2.39.4, 2.40.2, 2.41.1, 2.42.2,
# 2.43.4 e 2.44.1); a partida prova que o git em uso o respeita (no_lazy_fetch_honored)
NO_LAZY_ENV = {"GIT_NO_LAZY_FETCH": "1"}
GIT_MIN_LAZY = "2.45.1 (or 2.39.4, 2.40.2, 2.41.1, 2.42.2, 2.43.4, 2.44.1)"
_LAZY_PROBE = {}


def no_lazy_fetch_honored(git_bin):
    """(respeita, versão): o git desliga o lazy fetch com NO_LAZY_ENV? A prova, uma vez por processo e por git: um repo
    temporário com um remoto promisor cujo uploadpack deixaria um marcador, e um objeto que falta. Se o git não respeita
    a variável, o comando que roda é o desta prova, inofensivo, numa pasta temporária."""
    if git_bin in _LAZY_PROBE:
        return _LAZY_PROBE[git_bin]
    env = {k: v for k, v in os.environ.items() if not k.startswith("GIT_")}
    env.update({"GIT_CONFIG_NOSYSTEM": "1", "GIT_CONFIG_GLOBAL": os.devnull, "XDG_CONFIG_HOME": "",
                "GIT_TERMINAL_PROMPT": "0"})
    version = "?"
    try:
        out = subprocess.run([git_bin, "--version"], capture_output=True, env=env, timeout=SERVE_TIMEOUT)
        version = out.stdout.decode("utf-8", "replace").strip().removeprefix("git version ") or "?"
        with tempfile.TemporaryDirectory(prefix="kg-lazy-probe-") as tmp:
            repo, marker = os.path.join(tmp, "r"), os.path.join(tmp, "fetched")
            subprocess.run([git_bin, "init", "-q", repo], capture_output=True, env=env, timeout=SERVE_TIMEOUT,
                           check=True)
            for key, value in (("core.repositoryformatversion", "1"), ("extensions.partialClone", "probe"),
                               ("remote.probe.promisor", "true"), ("remote.probe.url", os.path.join(tmp, "nowhere")),
                               ("remote.probe.uploadpack", f"touch '{marker}'; false")):
                subprocess.run([git_bin, "-C", repo, "config", key, value], capture_output=True, env=env,
                               timeout=SERVE_TIMEOUT, check=True)
            subprocess.run([git_bin, "-C", repo, "rev-parse", "-q", "--verify", "12" * 20 + "^{commit}"],
                           capture_output=True, env=dict(env, **NO_LAZY_ENV), timeout=SERVE_TIMEOUT)
            ok = not os.path.exists(marker)
    except (OSError, subprocess.SubprocessError):
        ok = False
    _LAZY_PROBE[git_bin] = (ok, version)
    return ok, version


def trusted_which(name):
    """O caminho absoluto de um programa, achado só nas pastas ABSOLUTAS do PATH (nunca o diretório atual nem uma entrada
    relativa, que seria a pasta do clone quando o git roda nela), ou None."""
    dirs = [d for d in os.environ.get("PATH", "").split(os.pathsep) if d and os.path.isabs(d)]
    found = shutil.which(name, path=os.pathsep.join(dirs)) if dirs else None
    return os.path.abspath(found) if found else None


def _loose_writable(st):
    """O modo deixa o grupo ou os outros gravarem (g+w ou o+w)? No Windows, o modo não diz isso: nunca."""
    return os.name != "nt" and bool(st.st_mode & (stat.S_IWGRP | stat.S_IWOTH))


class TransientError(StoreError):
    """A falha de execução (o git não rodou, morreu por sinal, passou do tempo, o estado não se leu ou gravou): fecha a
    resposta, mas não carimba a ref, e a próxima requisição tenta de novo."""


def semver_key(version):
    """A chave de ordem da precedência do semver 2.0.0: a versão sem pré-lançamento vence a com, os identificadores
    numéricos se comparam como números e vêm antes dos alfanuméricos, e o build (+...) não conta."""
    m = SEMVER.fullmatch(version)
    pre = m.group(4)
    ids = () if pre is None else tuple((0, int(x), "") if x.isdigit() else (1, 0, x) for x in pre.split("."))
    return (int(m.group(1)), int(m.group(2)), int(m.group(3)), pre is None, ids)


def check_signers(path):
    """O caminho absoluto de um allowed_signers do git (o formato de gpg.ssh.allowedSignersFile), conferido: legível,
    até SIGNERS_MAX_BYTES, em UTF-8 (o UTF-16 ganha a dica de salvar em UTF-8) e com ao menos uma linha de
    signatário. StoreError com o motivo, sem o conteúdo do arquivo."""
    path = os.path.abspath(path)
    try:
        with open(path, "rb") as fh:
            data = fh.read(SIGNERS_MAX_BYTES + 1)
    except OSError as exc:
        raise StoreError(_("the signers file {path} cannot be read ({error})").format(
            path=path, error=exc.strerror or type(exc).__name__)) from None
    if len(data) > SIGNERS_MAX_BYTES:
        raise StoreError(_("the signers file {path} is larger than {limit} bytes").format(
            path=path, limit=SIGNERS_MAX_BYTES))
    if data.startswith((b"\xff\xfe", b"\xfe\xff")):
        raise StoreError(_("the signers file {path} is UTF-16: save it as UTF-8").format(path=path))
    try:
        text = data.decode("utf-8")
    except UnicodeDecodeError:
        raise StoreError(_("the signers file {path} is not UTF-8").format(path=path)) from None
    if text.startswith("﻿"):  # o ssh-keygen lê o arquivo como está: o BOM estragaria a primeira linha
        raise StoreError(_("the signers file {path} starts with a BOM: save it as UTF-8 without BOM").format(path=path))
    if not any(line.strip() and not line.lstrip().startswith("#") for line in text.splitlines()):
        raise StoreError(_("the signers file {path} has no signer line").format(path=path))
    return path


def _last_signature_is_ssh(body, kind):
    """A assinatura que o git verifica é SSH? Na tag, o bloco que começa na ÚLTIMA linha -----BEGIN (é a que o git toma
    como assinatura; um marcador SSH na mensagem não conta). No commit, todo cabeçalho gpgsig começa pelo bloco SSH."""
    if kind == "tag":
        starts = [line for line in body.split(b"\n") if line.startswith(b"-----BEGIN ")]
        return bool(starts) and starts[-1].rstrip(b"\r") == SSH_SIGNATURE
    header = body.split(b"\n\n", 1)[0].split(b"\n")
    sigs = [line.split(b" ", 1)[1] if b" " in line else b"" for line in header
            if line.startswith((b"gpgsig ", b"gpgsig-sha256 "))]
    return bool(sigs) and all(sig.rstrip(b"\r") == SSH_SIGNATURE for sig in sigs)


class ServeRef:
    """A ref que um GitStore serve (kg_mcp --serve-ref), já conferida na forma; resolve() a resolve num repo.

    - refs/heads/X, ou X: a árvore do commit da ponta da branch, e só enquanto o HEAD do clone descende dela (git
      merge-base --is-ancestor); com signers, o commit da ponta tem de ter assinatura SSH válida (git verify-commit);
    - refs/tags/N: a árvore exata de N^{commit}, só com signers e uma tag anotada com assinatura SSH válida (git
      verify-tag), cujo cabeçalho tag é o próprio N (a tag assinada de outra versão, copiada para este nome, não passa);
    - refs/tags/P*S: um * só, que casa uma versão semver sem pré-lançamento; vale a maior pela precedência do semver, e
      a tag fora de semver não conta. Só com state (um diretório fora do clone): a maior versão já servida fica gravada
      lá (o piso), e uma versão abaixo dela fecha a leitura, também depois de reiniciar (apagar a tag mais alta no
      remoto, e buscar com prune, faria servir a anterior). A maior que não verifica fecha: nunca se cai para outra.
    A GPG fica fora desta versão: a assinatura que não é SSH é recusada antes de o git a verificar."""

    def __init__(self, ref, signers=None, state=None):
        ref = str(ref)
        self.ref, self.signers = ref, None if signers is None else check_signers(signers)
        if ref.startswith("refs/tags/"):
            self.name = ref[len("refs/tags/"):]
            self.kind = "pattern" if "*" in self.name else "tag"
        elif ref.startswith("refs/heads/") or not ref.startswith("refs/"):
            self.name, self.kind = ref.removeprefix("refs/heads/"), "branch"
        else:
            raise StoreError(_("the served ref is refs/heads/<name>, <name> or refs/tags/<name or pattern>, not "
                               "{ref!r}").format(ref=ref))
        if self.kind == "pattern" and self.name.count("*") != 1:
            raise StoreError(_("the tag pattern {ref!r} has one * only, where the semver version goes").format(ref=ref))
        if self.kind == "branch" and "*" in self.name:
            raise StoreError(_("a branch is served by its exact name, without *: {ref!r}").format(ref=ref))
        segs = self.name.replace("*", "0").split("/")
        if not all(REF_SEGMENT.fullmatch(x) and not x.endswith((".lock", ".")) for x in segs) or ".." in self.name:
            raise StoreError(_("invalid ref name: {ref!r}").format(ref=ref))
        if self.kind != "branch" and self.signers is None:
            raise StoreError(_("a tag is served only with --verify-signers: without it nothing proves who cut it"))
        if self.kind == "pattern" and state is None:
            raise StoreError(_("a tag pattern is served only with --serve-state: without the highest version already "
                               "served, removing a tag would serve an earlier one"))
        if state is not None and self.kind != "pattern":
            raise StoreError(_("--serve-state only applies with a tag pattern"))
        if state is not None and not os.path.isdir(state):
            raise StoreError(_("the serve state {path} is not a directory").format(path=state))
        if state is not None and _loose_writable(os.stat(state)):
            raise StoreError(_("the serve state {path} is writable by the group or by others: chmod go-w").format(
                path=state))
        self.state = None if state is None else os.path.abspath(state)
        # o git e o ssh-keygen por caminho absoluto, achados agora fora da pasta do clone, e fixos daqui em diante
        self.git_bin = trusted_which("git")
        if self.git_bin is None:
            raise StoreError(_("git was not found in the absolute folders of PATH"))
        honored, version = no_lazy_fetch_honored(self.git_bin)
        if not honored:
            raise StoreError(_("git {version} does not honor GIT_NO_LAZY_FETCH, and a partial clone could run a "
                               "command of its configuration: the served mode needs git {minimum}").format(
                version=version, minimum=GIT_MIN_LAZY))
        self.ssh_keygen = None
        if self.signers is not None:
            self.ssh_keygen = trusted_which("ssh-keygen")
            if self.ssh_keygen is None:
                raise StoreError(_("ssh-keygen was not found in the absolute folders of PATH: --verify-signers needs it"))

    def _signature_args(self):
        return ["-c", f"gpg.ssh.allowedSignersFile={self.signers}", "-c", f"gpg.ssh.program={self.ssh_keygen}"]

    def _verify(self, store, kind, sha, label):
        """A assinatura SSH do objeto (tag ou commit) contra o allowed_signers; StoreError quando falta ou não vale."""
        check_signers(self.signers)  # o arquivo que sumiu ou quebrou fecha, com o motivo
        body = store._git("cat-file", kind, sha, check=False).stdout
        if not _last_signature_is_ssh(body, kind):
            raise StoreError(_("{ref} has no SSH signature (GPG is out of this version)").format(ref=label))
        out = store._git(*self._signature_args(), f"verify-{kind}", sha, check=False)
        if out.returncode != 0:
            why = out.stderr.decode("utf-8", "replace").strip().splitlines()
            raise StoreError(_("the signature of {ref} does not verify against the signers file ({error})").format(
                ref=label, error=why[-1] if why else out.returncode))
        return body

    def _tags(self, store):
        """[(nome curto, sha do objeto)] das tags do repo."""
        out = store._git("for-each-ref", "--format=%(refname)%00%(objectname)", "refs/tags/", check=False)
        pairs = []
        for line in out.stdout.decode("utf-8", "replace").splitlines():
            refname, _sep, sha = line.partition("\0")
            pairs.append((refname[len("refs/tags/"):], sha))
        return pairs

    def _pick(self, store):
        """A tag de maior versão semver (sem pré-lançamento) que o padrão casa, ou StoreError (nenhuma casa, ou duas
        empatam). Devolve (nome, sha, versão)."""
        prefix, suffix = self.name.split("*")
        found = []
        for name, sha in self._tags(store):
            if name.startswith(prefix) and name.endswith(suffix) and len(name) >= len(prefix) + len(suffix):
                version = name[len(prefix):len(name) - len(suffix)]
                m = SEMVER.fullmatch(version)
                if m and m.group(4) is None:  # o pré-lançamento não conta (fora desta versão)
                    found.append((semver_key(version), name, sha, version))
        if not found:
            raise StoreError(_("no semver tag matches {ref}").format(ref=self.ref))
        found.sort(reverse=True)
        if len(found) > 1 and found[0][0] == found[1][0]:
            raise StoreError(_("the tags {a} and {b} have the same version: the pattern {ref} does not choose").format(
                a=found[1][1], b=found[0][1], ref=self.ref))
        return found[0][1], found[0][2], found[0][3]

    # --- o piso de versão (o padrão): a maior versão já servida, num arquivo fora do clone ----------------------
    def state_path(self, store):
        key = hashlib.sha256(f"{store.root}\0{self.ref}".encode("utf-8", "surrogateescape")).hexdigest()[:16]
        return os.path.join(self.state, f"serve-floor-{key}.json")

    def floor(self, store):
        """O piso gravado ({version, tag, sha}) desta raiz com este padrão, ou None. O arquivo que não se lê é passageiro
        (tenta de novo); o que se lê fora da forma, ou que o grupo e os outros podem gravar, fecha, com o motivo."""
        path = self.state_path(store)
        try:
            with open(path, "rb") as fh:
                if _loose_writable(os.fstat(fh.fileno())):
                    raise StoreError(_("the serve state {path} is writable by the group or by others: chmod go-w")
                                     .format(path=path))
                data = fh.read(65536)
        except FileNotFoundError:
            return None
        except OSError as exc:
            raise TransientError(_("the serve state {path} cannot be read ({error})").format(
                path=path, error=exc.strerror or type(exc).__name__)) from None
        try:
            doc = json.loads(data.decode("utf-8"))
            ok = (isinstance(doc, dict) and doc.get("schema_version") == 1 and doc.get("ref") == self.ref
                  and isinstance(doc.get("version"), str) and SEMVER.fullmatch(doc["version"])
                  and isinstance(doc.get("tag"), str) and isinstance(doc.get("sha"), str)
                  and re.fullmatch(r"[0-9a-f]{40}|[0-9a-f]{64}", doc["sha"]))
        except (UnicodeDecodeError, ValueError):
            ok = False
        if not ok:
            raise StoreError(_("the serve state {path} is not valid: fix it or remove it to start a new floor").format(
                path=path))
        return doc

    def _check_floor(self, name, sha, version, floor):
        """StoreError quando a versão está abaixo do piso, ou na mesma precedência dele com outra tag ou outro objeto."""
        if floor is None:
            return
        key, top = semver_key(version), semver_key(floor["version"])
        if key < top:
            raise StoreError(_("the highest tag {tag} is below the version already served, {floor}: a higher tag "
                               "was removed (a rollback is never served)").format(tag="refs/tags/" + name,
                                                                                  floor=floor["version"]))
        if key == top and (floor["tag"], floor["sha"]) != (name, sha):
            raise StoreError(_("the tag {tag} has the version already served, {floor}, but not the tag object that was "
                               "served ({served}): a tag was moved or cut again").format(
                tag="refs/tags/" + name, floor=floor["version"], served=floor["tag"]))

    @contextlib.contextmanager
    def _state_lock(self):
        """A trava do diretório de estado entre processos (flock no POSIX, msvcrt no Windows)."""
        try:
            fd = os.open(os.path.join(self.state, ".serve-floor.lock"), os.O_RDWR | os.O_CREAT, 0o600)
        except OSError as exc:
            raise TransientError(_("the serve state {path} cannot be written ({error})").format(
                path=self.state, error=exc.strerror or type(exc).__name__)) from None
        try:
            try:
                if fcntl is not None:
                    fcntl.flock(fd, fcntl.LOCK_EX)
                elif msvcrt is not None:  # no Windows, LK_LOCK desiste depois de 10 tentativas com OSError
                    msvcrt.locking(fd, msvcrt.LK_LOCK, 1)
            except OSError as exc:
                raise TransientError(_("the serve state {path} cannot be locked ({error})").format(
                    path=self.state, error=exc.strerror or type(exc).__name__)) from None
            yield
        finally:
            os.close(fd)

    def record(self, store, name, sha, version):
        """Grava a versão servida como o piso, sob a trava do diretório e relendo o arquivo antes: fica o máximo entre o
        que está lá e a versão nova. A versão abaixo do que outro processo gravou, ou a mesma com outra tag, é recusada.
        A gravação é atômica (arquivo temporário e replace)."""
        path = self.state_path(store)
        with self._state_lock():
            current = self.floor(store)
            self._check_floor(name, sha, version, current)
            if current is not None and semver_key(version) == semver_key(current["version"]):
                return  # o mesmo piso, a mesma tag: nada a gravar
            doc = {"schema_version": 1, "ref": self.ref, "root": str(store.root), "tag": name, "sha": sha,
                   "version": version}
            try:
                fd, tmp = tempfile.mkstemp(dir=self.state, prefix=".serve-floor-")
                try:
                    with os.fdopen(fd, "w", encoding="utf-8") as fh:
                        json.dump(doc, fh)
                        fh.flush()
                        os.fsync(fh.fileno())
                    os.replace(tmp, path)
                except BaseException:
                    with contextlib.suppress(OSError):
                        os.unlink(tmp)
                    raise
            except OSError as exc:
                raise TransientError(_("the serve state {path} cannot be written ({error})").format(
                    path=path, error=exc.strerror or type(exc).__name__)) from None

    def resolve(self, store):
        """O sha do commit cuja árvore se serve, ou StoreError com o motivo (que fecha a leitura ou impede a partida)."""
        store._check_served_shape()
        if self.kind == "branch":
            full = "refs/heads/" + self.name
            found = store._git("rev-parse", "-q", "--verify", f"{full}^{{commit}}", check=False)
            if found.returncode != 0:
                raise StoreError(_("the branch {ref} does not exist").format(ref=full))
            commit = found.stdout.decode().strip()
            head = store._git("rev-parse", "-q", "--verify", "HEAD^{commit}", check=False)
            if head.returncode != 0 or store._git("merge-base", "--is-ancestor", commit, head.stdout.decode().strip(),
                                                  check=False).returncode != 0:
                raise StoreError(_("the HEAD of the clone does not descend from {ref}").format(ref=full))
            if self.signers is not None:
                self._verify(store, "commit", commit, full)
            return commit
        version = None
        if self.kind == "pattern":
            name, sha, version = self._pick(store)
            self._check_floor(name, sha, version, self.floor(store))  # cedo, antes de verificar a assinatura
        else:
            name = self.name
            sha = dict(self._tags(store)).get(name)
            if sha is None:
                raise StoreError(_("the tag {ref} does not exist").format(ref=self.ref))
        full = "refs/tags/" + name
        kind = store._git("cat-file", "-t", sha, check=False).stdout.decode().strip()
        if kind != "tag":
            raise StoreError(_("{ref} is a lightweight tag: only an annotated, signed tag is served").format(ref=full))
        body = self._verify(store, "tag", sha, full)
        header = body.split(b"\n\n", 1)[0].split(b"\n")
        if b"tag " + name.encode("utf-8") not in header:
            raise StoreError(_("the tag object of {ref} was cut under another name").format(ref=full))
        found = store._git("rev-parse", "-q", "--verify", f"{sha}^{{commit}}", check=False)
        if found.returncode != 0:
            raise StoreError(_("{ref} does not point to a commit").format(ref=full))
        if version is not None:
            self.record(store, name, sha, version)
        return found.stdout.decode().strip()


class GitStore(DiskStore):
    """Um commit por gravação ou remoção. O git roda com GIT_DIR e GIT_WORK_TREE na raiz e GIT_CEILING_DIRECTORIES no
    pai dela: nunca sobe para um repo de fora. author vai no --author; o committer é fixo do serviço (committer=)."""
    backend = "git"

    def __init__(self, root, schema=None, init=False, committer=("kg-store", "kg-store@localhost"), gate=None,
                 serve=None):
        super().__init__(root, schema, init, gate)
        self.committer = committer
        # serve (ServeRef): o armazém serve só o conteúdo de uma ref, só de leitura; None é a árvore de trabalho
        self.serve = serve
        git = self.root / ".git"
        if not os.path.lexists(git):
            if not init or serve is not None:
                raise StoreError(_("{root} has no .git (use init=True to create it)").format(root=self.root))
            self._git("init", "-q", setup=True)
        st = os.lstat(git)
        if _is_link(st) or not stat.S_ISDIR(st.st_mode):
            raise StoreError(_("{path} must be a directory, not a symlink or a gitfile").format(path=git))
        if serve is not None:
            # nada se escreve no clone servido (nem o .git/info/exclude): o serviço pode lê-lo sem permissão de escrita.
            # A ref é conferida já na partida, e a falha aqui é a recusa de subir
            # _serve_lock guarda só o estado (curto); _resolve_lock deixa um resolve por vez, com cada git sob tempo
            self._serve_lock, self._resolve_lock = threading.Lock(), threading.Lock()
            self._local = threading.local()  # o retrato fixado numa operação (pinned), por thread
            self._snap, self._blobs, self._closed_reason = None, {}, None
            self._serve_stamp = self._ref_stamp()
            self._snap = self._snapshot(serve.resolve(self))
            return
        exclude = git / "info" / "exclude"  # a trava do armazém não é conteúdo: fica fora do status
        try:
            for p in (git / "info", exclude):
                if os.path.lexists(p) and _is_link(os.lstat(p)):
                    raise StoreError(_("{path} is a symlink").format(path=p))
            current = exclude.read_text(encoding="utf-8") if exclude.is_file() else ""
            if LOCK not in current.split("\n"):
                exclude.parent.mkdir(exist_ok=True)
                exclude.write_text(current + ("" if current.endswith("\n") or not current else "\n") + LOCK + "\n",
                                   encoding="utf-8")
        except OSError as exc:
            raise StoreError(_("could not write to {path}: {error}").format(path=exclude, error=exc)) from exc

    def _check_root(self, path):
        """O GitStore é o armazém que mora num repo: o próprio, na raiz (o __init__ confere o .git)."""

    def _git(self, *args, setup=False, check=True, input=None):
        env = {k: v for k, v in os.environ.items() if not k.startswith("GIT_")}
        env.update({"GIT_CEILING_DIRECTORIES": str(self.root.parent), "GIT_CONFIG_NOSYSTEM": "1",
                    "GIT_CONFIG_GLOBAL": os.devnull, "XDG_CONFIG_HOME": "", "GIT_TERMINAL_PROMPT": "0"})
        if not setup:
            env.update({"GIT_DIR": str(self.root / ".git"), "GIT_WORK_TREE": str(self.root)})
        served = getattr(self, "serve", None) is not None
        if served:  # o objeto substituído (git replace) e o enxerto não trocam o conteúdo depois da verificação
            # e o clone parcial não busca o objeto que falta (o lazy fetch rodaria o uploadpack da config do clone)
            env.update({"GIT_NO_REPLACE_OBJECTS": "1", "GIT_GRAFT_FILE": os.devnull, "GIT_OPTIONAL_LOCKS": "0",
                        "GIT_PROTOCOL_FROM_USER": "0", **NO_LAZY_ENV})
        name, email = self.committer
        env.update({"GIT_COMMITTER_NAME": name, "GIT_COMMITTER_EMAIL": email,
                    "GIT_AUTHOR_NAME": name, "GIT_AUTHOR_EMAIL": email})
        hardening = []  # nada da config do usuário muda o conteúdo gravado nem quem roda
        for kv in ("core.hooksPath=" + os.devnull, "commit.gpgsign=false", "core.autocrlf=false", "core.eol=lf",
                   "core.safecrlf=false", "core.excludesFile=" + os.devnull, "core.attributesFile=" + os.devnull,
                   "core.fsmonitor=false", "core.symlinks=false"):
            hardening += ["-c", kv]
        if served:
            for kv in SERVED_CONFIG:
                hardening += ["-c", kv]
            return self._served_git([self.serve.git_bin, "--no-pager", *hardening, *args], env, check, input)
        try:
            out = subprocess.run(["git", *hardening, *args], cwd=self.root, env=env, capture_output=True, input=input)
        except (OSError, ValueError) as exc:
            raise StoreError(_("git {cmd} did not run: {error}").format(cmd=args[0], error=exc)) from exc
        if check and out.returncode != 0:
            raise StoreError(_("git {cmd} failed: {error}").format(cmd=args[0],
                                                                  error=out.stderr.decode('utf-8', 'replace').strip()))
        return out

    def _served_git(self, argv, env, check, input):
        """O git do modo servido: sob SERVE_TIMEOUT, num grupo de processos próprio (o ssh-keygen que ele chama morre
        junto). Não rodar, morrer por sinal ou passar do tempo é TransientError: nada disso diz algo sobre a ref."""
        cmd = next(a for a in argv[1:] if not a.startswith("-") and "=" not in a)
        group = ({"creationflags": subprocess.CREATE_NEW_PROCESS_GROUP} if os.name == "nt"
                 else {"start_new_session": True})
        try:
            p = subprocess.Popen(argv, cwd=self.root, env=env, stdin=subprocess.PIPE if input is not None else
                                 subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.PIPE, **group)
        except (OSError, ValueError) as exc:
            raise TransientError(_("git {cmd} did not run: {error}").format(cmd=cmd, error=exc)) from exc
        try:
            stdout, stderr = p.communicate(input, timeout=SERVE_TIMEOUT)
        except subprocess.TimeoutExpired:
            CommandGate._kill(p)
            try:  # o que sobrou nos canos, sob tempo também: um neto que segure o cano não trava o servidor
                p.communicate(timeout=SERVE_TIMEOUT)
            except (subprocess.TimeoutExpired, OSError, ValueError):
                pass
            finally:
                for pipe in (p.stdin, p.stdout, p.stderr):
                    if pipe is not None:
                        with contextlib.suppress(OSError):
                            pipe.close()
            raise TransientError(_("git {cmd} did not finish within {seconds} s").format(cmd=cmd,
                                                                                        seconds=SERVE_TIMEOUT)) from None
        if p.returncode < 0:
            raise TransientError(_("git {cmd} was killed by signal {signal}").format(cmd=cmd, signal=-p.returncode))
        out = subprocess.CompletedProcess(argv, p.returncode, stdout, stderr)
        if check and out.returncode != 0:
            raise StoreError(_("git {cmd} failed: {error}").format(cmd=cmd, error=stderr.decode("utf-8", "replace").strip()))
        return out

    # --- a ref servida (serve): a árvore do commit da ref, nunca a árvore de trabalho --------------------------
    def _check_served_shape(self):
        """O repo que se serve não tem enxerto (.git/info/grafts), clone raso (.git/shallow) nem objetos emprestados de
        fora dele (objects/info/alternates): os três trocam o histórico ou o conteúdo por fora da ref assinada."""
        git = self.root / ".git"
        if os.path.lexists(git / "commondir"):
            raise StoreError(_("the clone has .git/commondir (a linked worktree): its objects and refs live elsewhere"))
        for rel in ("HEAD", "config", "packed-refs", "objects", "refs"):
            if os.path.islink(git / rel):
                raise StoreError(_("the clone has a symbolic link in .git ({path}): it is refused").format(path=rel))
        for sub in ("objects", "refs"):
            for dirpath, dirnames, filenames in os.walk(git / sub):
                for entry in dirnames + filenames:
                    if os.path.islink(os.path.join(dirpath, entry)):
                        rel = os.path.relpath(os.path.join(dirpath, entry), git)
                        raise StoreError(_("the clone has a symbolic link in .git ({path}): it is refused").format(
                            path=rel))
        self._check_promisor()
        if os.path.lexists(git / "info" / "grafts"):
            raise StoreError(_("the clone has .git/info/grafts, which rewrites the history outside the signed ref: "
                               "remove it"))
        if os.path.lexists(git / "shallow"):
            raise StoreError(_("the clone is shallow (.git/shallow): the history up to the ref is incomplete, and "
                               "descent and history are not checked; clone it in full"))
        alternates = git / "objects" / "info" / "alternates"
        try:
            lines = alternates.read_text(encoding="utf-8", errors="replace").splitlines()
        except FileNotFoundError:
            lines = []
        except OSError as exc:
            raise TransientError(_("{path} cannot be read ({error})").format(path=alternates,
                                                                             error=exc.strerror or exc)) from None
        base = os.path.realpath(git)
        for line in lines:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            real = os.path.realpath(os.path.join(git / "objects", line))
            if real != base and not real.startswith(base + os.sep):
                raise StoreError(_("the clone borrows objects from outside it (objects/info/alternates): "
                                   "clone it without --shared or --reference"))

    def _check_promisor(self):
        """O clone parcial (extensions.partialClone, ou um remote.*.promisor) é recusado. A consulta é a config que o git
        do modo servido lê (o .git/config, o config.worktree e o que include.path e includeIf incluem), e ela roda a
        cada requisição, não só quando o carimbo muda: um include trocado não muda o carimbo."""
        promisor = self._git("config", "--get-regexp", r"^(extensions\.partialclone|remote\..*\.promisor)$",
                             check=False)
        if promisor.returncode == 0 and promisor.stdout.strip():
            raise StoreError(_("the clone is a partial clone (extensions.partialClone or a promisor remote): a missing "
                               "object would be fetched by a command of its config; clone it in full"))

    def _ref_stamp(self):
        """O carimbo do que decide a ref: HEAD (o conteúdo também), packed-refs, a tabela do reftable, cada ref solta de
        refs/heads e refs/tags e o arquivo de signatários. Só stat e uma leitura curta: nenhum git roda quando nada
        mudou."""
        git = self.root / ".git"
        out = []
        for rel in ("HEAD", "packed-refs", "reftable/tables.list", "config", "info/grafts", "shallow",
                    "objects/info/alternates", "commondir", "config.worktree"):
            try:
                st = os.stat(git / rel)
                out.append((rel, st.st_mtime_ns, st.st_size, st.st_ino))
            except OSError:
                out.append((rel, None))
        try:
            out.append(("HEAD:", (git / "HEAD").read_bytes()[:4096]))
        except OSError:
            out.append(("HEAD:", None))
        for sub in ("refs/heads", "refs/tags", "refs/replace"):
            for dirpath, dirnames, filenames in os.walk(git / sub):
                dirnames.sort()
                for f in sorted(filenames):
                    try:
                        st = os.stat(os.path.join(dirpath, f))
                    except OSError:
                        continue
                    out.append((os.path.join(dirpath, f), st.st_mtime_ns, st.st_size, st.st_ino))
        if self.serve.signers is not None:
            try:
                st = os.stat(self.serve.signers)
                out.append(("signers", st.st_mtime_ns, st.st_size, st.st_ino))
            except OSError:
                out.append(("signers", None))
        return tuple(out)

    def _snapshot(self, commit):
        """(commit, {caminho: sha do blob}) dos arquivos regulares da árvore do commit (sem link nem submódulo)."""
        out = self._git("ls-tree", "-r", "-z", "--full-tree", commit)
        blobs = {}
        for entry in out.stdout.split(b"\0"):
            if not entry:
                continue
            meta, _tab, path = entry.partition(b"\t")
            mode, kind, sha = meta.decode("ascii").split(" ")
            if kind == "blob" and mode in ("100644", "100755"):
                blobs[path.decode("utf-8", "surrogateescape")] = sha
        return commit, blobs

    _UNPINNED = object()

    def served(self):
        """O retrato da ref servida ((commit, blobs)) ou None quando a leitura está fechada. Dentro de pinned(), o retrato
        fixado no começo da operação; fora, o de agora."""
        pinned = getattr(self._local, "snap", self._UNPINNED)
        return self._refresh() if pinned is self._UNPINNED else pinned

    @contextlib.contextmanager
    def pinned(self):
        """Um retrato só para a operação inteira (uma requisição do kg-mcp, uma consulta): nada mistura duas refs, a
        ref é conferida uma vez, e fechar no meio fecha a resposta inteira. Reentrante; sem a ref servida, não faz nada."""
        if self.serve is None or getattr(self._local, "snap", self._UNPINNED) is not self._UNPINNED:
            yield
            return
        self._local.snap = self._refresh()
        try:
            yield
        finally:
            del self._local.snap

    def _refresh(self):
        """A ref é relida quando o carimbo muda; se ela não verifica mais, a leitura fecha (como a política inválida no
        kg-mcp) e reabre quando voltar a verificar. O motivo sai uma vez no stderr, que é do operador. A falha de
        execução (TransientError) fecha sem carimbar: a próxima chamada tenta de novo. A recusa do clone parcial roda a
        cada chamada (um include trocado não muda o carimbo) e fecha só aquela resposta."""
        try:
            with kg_i18n.machine():
                self._check_promisor()
        except StoreError as exc:
            with self._serve_lock:
                if str(exc) != self._closed_reason:
                    self._closed_reason = str(exc)
                    print(f"kg_store: served ref {self.serve.ref} closed in {self.root.name}: {exc}", file=sys.stderr)
            return None
        stamp = self._ref_stamp()
        with self._serve_lock:
            if stamp == self._serve_stamp:
                if self._snap is not None and self._closed_reason is not None:
                    print(f"kg_store: served ref {self.serve.ref} reopened in {self.root.name} at {self._snap[0]}",
                          file=sys.stderr)
                    self._closed_reason = None
                return self._snap
        with self._resolve_lock:  # um resolve por vez; quem chega durante ele espera e lê o resultado
            stamp = self._ref_stamp()
            with self._serve_lock:
                if stamp == self._serve_stamp:
                    return self._snap
                current = self._snap
            try:
                with kg_i18n.machine():
                    commit = self.serve.resolve(self)
                    snap = current if current is not None and current[0] == commit else self._snapshot(commit)
            except StoreError as exc:
                with self._serve_lock:
                    self._snap, self._blobs = None, {}
                    if not isinstance(exc, TransientError):
                        self._serve_stamp = stamp
                    if str(exc) != self._closed_reason:
                        self._closed_reason = str(exc)
                        print(f"kg_store: served ref {self.serve.ref} closed in {self.root.name}: {exc}", file=sys.stderr)
                return None
            with self._serve_lock:
                if current is None or current[0] != commit:
                    self._blobs = {}
                if self._closed_reason is not None:
                    print(f"kg_store: served ref {self.serve.ref} reopened in {self.root.name} at {commit}",
                          file=sys.stderr)
                self._snap, self._closed_reason, self._serve_stamp = snap, None, stamp
            return snap

    def _served_text(self, snap, name):
        """O texto de um nome no retrato, ou None quando ele não está lá. Não UTF-8 é StoreError, como no disco."""
        sha = snap[1].get(name)
        if sha is None:
            return None
        data = self._blobs.get(sha)
        if data is None:
            data = self._blobs[sha] = self._git("cat-file", "blob", sha).stdout
        try:
            return data.decode("utf-8")
        except UnicodeDecodeError as exc:
            raise StoreError(_("{name} is not UTF-8").format(name=name)) from exc

    def _prefetch(self, snap, names):
        """Os blobs que faltam, de uma vez só (git cat-file --batch): o corpus inteiro não custa um git por grafo."""
        want = sorted({snap[1][n] for n in names if n in snap[1]} - set(self._blobs))
        if not want:
            return
        out = self._git("cat-file", "--batch", input=("\n".join(want) + "\n").encode("ascii")).stdout
        pos = 0
        for sha in want:
            nl = out.index(b"\n", pos)
            head = out[pos:nl].split(b" ")
            if len(head) != 3 or head[1] != b"blob":
                raise StoreError(_("git cat-file did not return the blob {sha}").format(sha=sha))
            size = int(head[2])
            self._blobs[sha] = out[nl + 1:nl + 1 + size]
            pos = nl + 1 + size + 1

    def _served_names(self, pattern):
        snap = self.served()
        return [] if snap is None else sorted(n for n in snap[1] if pattern.fullmatch(n))

    def read(self, name, ref=None):
        with self.pinned() if self.serve is not None else contextlib.nullcontext():
            return super().read(name, ref)

    def list_texts(self):
        with self.pinned() if self.serve is not None else contextlib.nullcontext():
            return super().list_texts()

    def _lock(self):
        if self.serve is not None:
            raise StoreError(_("this store serves the ref {ref}: it does not write").format(ref=self.serve.ref))
        return super()._lock()

    def _read_head(self, name):
        if self.serve is None:
            return super()._read_head(name)
        snap = self.served()
        return None if snap is None else self._served_text(snap, check_name(name))

    def _read_corpus(self, name):
        if self.serve is None:
            return super()._read_corpus(name)
        snap = self.served()
        return None if snap is None else self._served_text(snap, name)

    def _texts(self, skip=None, names=None):
        if self.serve is None:
            return super()._texts(skip, names)
        with self.pinned():
            snap = self.served()
            if snap is None:
                return []
            self._prefetch(snap, self._corpus_names() if names is None else names)
            return super()._texts(skip, names)

    def _case_clash(self, name):
        """No retrato, a mesma régua do disco, sobre as pastas e os arquivos da árvore do commit."""
        if self.serve is None:
            return super()._case_clash(name)
        snap = self.served()
        if snap is None:
            return None
        segs = name.split("/")
        for k, seg in enumerate(segs):
            prefix = "/".join(segs[:k])
            entries = {p[len(prefix) + 1 if prefix else 0:].split("/")[0] for p in snap[1]
                       if not prefix or p.startswith(prefix + "/")}
            if seg in entries:
                continue
            other = next((e for e in sorted(entries) if e.casefold() == seg.casefold()), None)
            return None if other is None else "/".join(segs[:k] + [other])
        return None

    def list(self):
        """Os nomes RASTREADOS (o mesmo corpus do gate do repo, que lê git ls-files), regulares e na forma do nome. Com a
        ref servida, os arquivos regulares da árvore do commit dela."""
        if self.serve is not None:
            return self._served_names(NAME)
        out = self._git("ls-files", "-z", "--", "*.kg.yaml", "*.kg.json", check=False)
        if out.returncode != 0:
            return []
        disk = set(self._disk_names())
        return sorted(n for n in out.stdout.decode("utf-8").split("\0") if n and n in disk)

    def _corpus_names(self):
        """Os rastreados, como o gate do repo: os do armazém e, desde o contrato v4.15, os de pasta com ponto (fora
        .git/), que o armazém lê para julgar a ponta externa e nunca escreve."""
        if self.serve is not None:
            return [n for n in self._served_names(CORPUS_NAME) if n.split("/")[0] != ".git"]
        names = set(self.list())
        out = self._git("ls-files", "-z", "--", "*.kg.yaml", "*.kg.json", check=False)
        if out.returncode == 0:
            for n in out.stdout.decode("utf-8").split("\0"):
                # só o que o nome do armazém NÃO aceita (pasta com ponto): o symlink e o rastreado já apagado, que o
                # list() deixa fora, seguem fora
                if n and n not in names and CORPUS_NAME.fullmatch(n) and not NAME.fullmatch(n) and \
                        n.split("/")[0] != ".git":
                    names.add(n)
        return sorted(names)

    def _visible(self, name, head):
        """No GitStore, o que não está rastreado não existe para o armazém (como para list() e para o gate)."""
        if self.serve is not None:  # o _read_head já leu do retrato: o que está nele está rastreado no commit
            return head
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
        names = [n for n, _text, _sha in todo]
        self._git("add", "-f", "-A", "--", *names)
        args = ["commit", "-q", "--no-verify", "-m", message]
        if author:
            args += ["--author", author]
        self._git(*args, "--", *names)
        return self._git("rev-parse", "HEAD").stdout.decode().strip()

    def check_ref(self, ref):
        if not re.fullmatch(r"[0-9a-fA-F]{4,64}", str(ref)):  # fullmatch: o $ aceitaria um \n final
            raise StoreError(_("invalid ref: {ref!r} (a commit sha)").format(ref=ref))

    def _read_ref(self, name, ref):
        self.check_ref(ref)
        if self.serve is not None:
            # só o histórico da ref servida: um commit fora dele (a ponta do clone à frente da tag, um commit sem
            # assinatura) responde como o nome que não existe naquele ref
            snap = self.served()
            if snap is None:  # fechado: nenhum git roda por um ref de fora
                raise NotFound(_("{name} does not exist at {ref}").format(name=name, ref=ref))
            found = self._git("rev-parse", "-q", "--verify", f"{ref}^{{commit}}", check=False)
            commit = found.stdout.decode().strip()
            if found.returncode != 0 or self._git(
                    "merge-base", "--is-ancestor", commit, snap[0], check=False).returncode != 0:
                raise NotFound(_("{name} does not exist at {ref}").format(name=name, ref=ref))
            # só o arquivo regular (blob 100644 ou 100755), como no retrato: nem link simbólico nem submódulo
            entry = self._git("ls-tree", "-z", "--full-tree", commit, "--", name, check=False).stdout.split(b"\0")[0]
            meta, _tab, path = entry.partition(b"\t")
            parts = meta.decode("ascii", "replace").split(" ")
            if path.decode("utf-8", "surrogateescape") != name or len(parts) != 3 or parts[1] != "blob" or \
                    parts[0] not in ("100644", "100755"):
                raise NotFound(_("{name} does not exist at {ref}").format(name=name, ref=ref))
            out = self._git("cat-file", "blob", parts[2], check=False)
            if out.returncode != 0:
                raise NotFound(_("{name} does not exist at {ref}").format(name=name, ref=ref))
            return out.stdout.decode("utf-8")
        out = self._git("show", f"{ref}:{name}", check=False)
        if out.returncode != 0:
            raise NotFound(_("{name} does not exist at {ref}").format(name=name, ref=ref))
        return out.stdout.decode("utf-8")

    def history(self, name):
        if self.serve is not None:
            with self.pinned():
                return self._history(name)
        return self._history(name)

    def _history(self, name):
        check_name(name)
        self._check_case(name)
        tip = []
        if self.serve is not None:  # o histórico até a ref servida, nunca o que veio depois dela no clone
            snap = self.served()
            if snap is None:
                return []
            tip = ["--no-ext-diff", "--no-textconv", "--no-show-signature", snap[0]]
        out = self._git("log", "--format=%H%x1f%an <%ae>%x1f%aI%x1f%s", "--name-status", *tip, "--", name,
                        check=False)
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
            raise StoreError(_("{path} is corrupted: {error}").format(path=f"{META}/events.jsonl", error=exc)) from exc

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
            raise StoreError(_("{name} is not UTF-8").format(name=f"{META}/{rel}")) from exc

    def _commit(self, op, name, sha, message, author, text):
        if sha is not None:
            try:
                self._write_file([META, "blobs", f"{sha}.yaml"], text.encode("utf-8"))
            except OSError as exc:
                raise StoreError(_("could not write the version {sha}: {error}").format(sha=sha, error=exc)) from exc
        seq = len(self._events()) + 1
        event = {"seq": seq, "op": op, "name": name, "sha256": sha, "author": author, "message": message,
                 "ts": datetime.datetime.now(datetime.timezone.utc).isoformat(timespec="seconds")}
        try:
            self._append([META, "events.jsonl"], (json.dumps(event, ensure_ascii=False) + "\n").encode("utf-8"))
        except OSError as exc:
            raise StoreError(_("could not record the event: {error}").format(error=exc)) from exc
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
                    raise StoreError(_("could not write the version {sha}: {error}").format(sha=new, error=exc)) from exc
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
            raise StoreError(_("could not record the events: {error}").format(error=exc)) from exc
        return seq

    def history(self, name):
        check_name(name)
        self._check_case(name)
        return [{"ref": e["seq"], "op": e["op"], "author": e["author"], "ts": e["ts"], "message": e["message"],
                 "sha256": e["sha256"]} for e in reversed(self._events()) if e["name"] == name]

    def check_ref(self, ref):
        try:
            return int(ref)
        except (TypeError, ValueError):
            raise StoreError(_("invalid ref: {ref!r} (the seq of an event)").format(ref=ref)) from None

    def _read_ref(self, name, ref):
        seq = self.check_ref(ref)
        event = next((e for e in self._events() if e["seq"] == seq and e["name"] == name), None)
        if event is None or event["sha256"] is None:
            raise NotFound(_("{name} has no version at event {ref}").format(name=name, ref=ref))
        text = self._meta_read(f"blobs/{event['sha256']}.yaml")
        if text is None:
            raise NotFound(_("the version {sha} is missing from {path}").format(sha=event['sha256'], path=f"{META}/blobs"))
        if sha256(text) != event["sha256"]:
            raise StoreError(_("the version {sha} in {path} does not match the event sha256")
                             .format(sha=event['sha256'], path=f"{META}/blobs"))
        return text


BACKENDS = {"disk": DiskStore, "git": GitStore, "versioned": VersionedStore}

# a descrição do --help, em inglês (a fonte); a tradução vem do catálogo. O docstring do módulo segue em pt-BR
USAGE = """A store of .kg.yaml and .kg.json files that writes only what the contract passes.

Three backends with the same interface: disk (the head on disk, no history), git (one commit per write or delete)
and versioned (the head on disk plus an event log and the versions in .kg-store/, no git). Every write and delete
is judged by the contract, and by the external gate when there is one; nothing that fails is written.

CLI (JSON output on stdout):
  kg_store.py --backend disk|git|versioned --root DIR [--init] list
  kg_store.py ... read NAME [--ref REF]
  kg_store.py ... write NAME [FILE|-] [--message M] [--author "Name <email>"] [--expected-sha256 S|new]
  kg_store.py ... delete NAME [--message M] [--author A] [--expected-sha256 S]
  kg_store.py ... write-many SET.json [--message M] [--author A]
    the set is {"changes": [{"name": N, "file": F} | {"name": N, "text": T} | {"name": N, "delete": true}],
    "expected": {N: S|new}}, with file relative to SET.json; writes all or nothing (write_many)
  kg_store.py ... history NAME
rc: 0 ok · 1 refused (gate, conflict, missing, name that does not exist) · 2 broken input or not_judged."""


def open_store(backend, root, **kw):
    if backend not in BACKENDS:
        raise StoreError(_("unknown backend: {backend!r} ({choices})").format(backend=backend, choices=', '.join(BACKENDS)))
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
        raise StoreError(_("{name} is not JSON: {error}").format(name=path.name, error=exc)) from exc
    if not isinstance(doc, dict) or not isinstance(doc.get("changes"), list):
        raise StoreError(_("{name}: the changes list is missing").format(name=path.name))
    changes = []
    for c in doc["changes"]:
        if not isinstance(c, dict) or not isinstance(c.get("name"), str) or \
                sum(k in c for k in ("file", "text", "delete")) != 1:
            raise StoreError(_("{name}: each change has name and exactly one of file, text, or delete").format(name=path.name))
        if "delete" in c:
            if c["delete"] is not True:
                raise StoreError(_("{name}: delete only accepts true").format(name=path.name))
            changes.append((c["name"], None))
        elif "text" in c:
            changes.append((c["name"], c["text"]))
        else:
            changes.append((c["name"], (path.parent / c["file"]).read_text(encoding="utf-8")))
    expected = doc.get("expected")
    if expected is not None and not isinstance(expected, dict):
        raise StoreError(_("{name}: expected must be an object that maps name → sha256").format(name=path.name))
    return changes, expected


def main(argv=None):
    ap = argparse.ArgumentParser(description=_(USAGE), formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--backend", choices=sorted(BACKENDS), default="disk")
    ap.add_argument("--root", required=True)
    ap.add_argument("--init", action="store_true", help=_("create the root (and the repo, with git) if it does not exist"))
    ap.add_argument("--gate-cmd", help=_("an external gate, after the contract: the command reads the text on stdin and "
                                         "returns a kg-ssot.verdict/1 (see CommandGate)"))
    ap.add_argument("--gate-timeout", type=float, help=_("timeout in seconds for the external gate (default 60)"))
    sub = ap.add_subparsers(dest="cmd", required=True)
    sub.add_parser("list")
    p = sub.add_parser("read")
    p.add_argument("name")
    p.add_argument("--ref")
    for cmd in ("write", "delete"):
        p = sub.add_parser(cmd)
        p.add_argument("name")
        if cmd == "write":
            p.add_argument("file", nargs="?", default="-", help=_("the graph; '-' (default) reads stdin"))
        p.add_argument("--message")
        p.add_argument("--author")
        p.add_argument("--expected-sha256")
    p = sub.add_parser("write-many")
    p.add_argument("file", help=_("the set in JSON (see the usage above)"))
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
            raise StoreError(_("--gate-timeout without --gate-cmd: there is no gate for the timeout"))
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
        print(_("BROKEN INPUT  {error}").format(error=exc), file=sys.stderr)
        return 2
    emit(res)
    return 0 if res["written"] else 2 if res["reason"] == "not_judged" else 1


if __name__ == "__main__":
    sys.exit(main())
