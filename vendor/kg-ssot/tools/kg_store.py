#!/usr/bin/env python3
"""O armazém de .kg.yaml que só grava o que o contrato aprova (A_STORAGE_ADAPTER, ÉPICO 11).

Biblioteca primeiro, CLI por cima. Três armazéns com a mesma interface (read, list, write, delete, history):
  DiskStore(root)       a cabeça em disco, sem histórico;
  GitStore(root)        um commit por gravação ou remoção, com o git isolado na raiz (nunca sobe para um repo pai);
  VersionedStore(root)  a cabeça em disco mais um registro de eventos e as versões em `.kg-store/`, sem git.

O gate (o que nenhum dos três pula):
  - write() julga o candidato pelo contrato (kg_validate.judge) com a ponta externa conferida contra o próprio
    armazém, já com o candidato no lugar; e julga de novo cada grafo do armazém que aponta para o nome gravado,
    porque trocar um grafo pode deixar a aresta externa de outro sem ponta;
  - delete() julga os grafos que apontam para o nome removido, contra o armazém sem ele;
  - só grava com PASS em todos. Nada reprovado é escrito;
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

Segurança do caminho: o nome é relativo, termina em .kg.yaml, cada segmento começa por letra, dígito ou _ (sem `..`
nem oculto). Raiz, pastas e arquivo não podem ser symlink: tudo se abre por dir_fd com O_NOFOLLOW (POSIX).
O que fica com quem adota, de propósito: autenticação, identidade, área por usuário (um root por usuário), tamanho
máximo, número de grafos, timeout e concorrência entre processos sem flock.

CLI (saída JSON no stdout):
  kg_store.py --backend disk|git|versioned --root DIR [--init] list
  kg_store.py ... read NAME [--ref REF]
  kg_store.py ... write NAME [FILE|-] [--message M] [--author "Nome <email>"] [--expected-sha256 S|new]
  kg_store.py ... delete NAME [--message M] [--author A] [--expected-sha256 S]
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
import stat
import subprocess
import sys

sys.dont_write_bytecode = True
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import kg_validate  # noqa: E402

try:
    import fcntl
except ImportError:  # sem flock (Windows): a trava entre processos fica com quem adota, como a doc diz
    fcntl = None

NAME = re.compile(r"^(?:[A-Za-z0-9_][A-Za-z0-9_.-]*/)*[A-Za-z0-9_][A-Za-z0-9_.-]*\.kg\.yaml$")
NEW = "new"
META = ".kg-store"
LOCK = ".kg-store.lock"
AUTHOR = re.compile(r"[^<>\n\r\x00]+ <[^<>\s\x00]+>")  # fullmatch: o $ casaria antes de um \n final
SEGMENT_MAX = 200  # bytes por segmento do nome: sobra espaço no NAME_MAX para o arquivo temporário
VERDICT_SCHEMA = pathlib.Path(__file__).resolve().parent.parent / "spec" / "verdict.schema.json"
_NOFOLLOW = getattr(os, "O_NOFOLLOW", 0)
_DIRECTORY = getattr(os, "O_DIRECTORY", 0)


class StoreError(Exception):
    """Entrada quebrada: nome inválido, symlink no caminho, raiz que não serve, git que falha."""


class NotFound(StoreError):
    """O nome (ou a versão pedida) não existe no armazém."""


def sha256(text):
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


def check_name(name):
    if not isinstance(name, str) or not NAME.fullmatch(name):
        raise StoreError(f"nome inválido: {name!r} (relativo, termina em .kg.yaml, sem '..' nem segmento oculto)")
    if any(len(seg.encode("utf-8")) > SEGMENT_MAX for seg in name.split("/")):
        raise StoreError(f"nome inválido: segmento com mais de {SEGMENT_MAX} bytes")
    return name


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


class DiskStore:
    """A cabeça em disco. history() é vazio: este armazém não guarda versão anterior."""
    backend = "disk"

    def __init__(self, root, schema=None, init=False):
        if not hasattr(os, "supports_dir_fd") or os.open not in os.supports_dir_fd:
            raise StoreError("o armazém exige POSIX (os.open com dir_fd e O_NOFOLLOW)")
        self.root = pathlib.Path(root)
        if init and not os.path.lexists(self.root):
            ancestor = self.root.absolute()
            while not os.path.lexists(ancestor):
                ancestor = ancestor.parent
            self._check_root(ancestor)  # recusa antes de criar a pasta, não depois
            self.root.mkdir(parents=True)
        try:
            st = os.lstat(self.root)
        except OSError as exc:
            raise StoreError(f"raiz ilegível: {exc}") from exc
        if stat.S_ISLNK(st.st_mode) or not stat.S_ISDIR(st.st_mode):
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

    # --- caminho seguro: tudo por dir_fd, nada segue symlink -----------------------------------------------
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

    def _read_head(self, name):
        """O texto da cabeça, ou None se o nome não existe. Symlink no caminho é StoreError."""
        *parts, leaf = check_name(name).split("/")
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
                raise StoreError(f"arquivo recusado (symlink?): {name}") from exc
            with os.fdopen(fd, "rb") as fh:
                if not stat.S_ISREG(os.fstat(fh.fileno()).st_mode):
                    raise StoreError(f"não é arquivo regular: {name}")
                data = fh.read()
        finally:
            os.close(dfd)
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
        dfd = self._dir(parts, create=True)
        tmp = f".{leaf[:40]}.{secrets.token_hex(6)}.tmp"
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

    def _remove_head(self, name):
        *parts, leaf = name.split("/")
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
        return fd

    @staticmethod
    def _unlock(fd):
        if fd is not None:
            fcntl.flock(fd, fcntl.LOCK_UN)
            os.close(fd)

    # --- leitura -------------------------------------------------------------------------------------------
    def list(self):
        """Os nomes .kg.yaml do armazém, em ordem. Pasta ou arquivo oculto, symlink e nome fora da forma ficam fora."""
        return self._disk_names()

    def _disk_names(self):
        out = []

        def walk(path, prefix):
            with os.scandir(path) as it:
                for e in it:
                    if e.name.startswith("."):
                        continue
                    rel = prefix + e.name
                    if e.is_dir(follow_symlinks=False):
                        walk(e.path, rel + "/")
                    elif e.is_file(follow_symlinks=False) and NAME.fullmatch(rel):
                        out.append(rel)
        walk(self.root, "")
        return sorted(out)

    def read(self, name, ref=None):
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
        return []

    # --- o gate --------------------------------------------------------------------------------------------
    def _texts(self, skip=None):
        items = []
        for n in self.list():
            if n == skip:
                continue
            try:
                t = self._read_head(n)
            except StoreError:  # ilegível (não UTF-8) entra sem ids, como no corpus_index do gate
                t = None
            items.append((n, t if t is not None else ""))
        return items

    def _judge(self, name, text):
        """(doc, erro): julga o candidato (text None = remoção) e os grafos que apontam para name, contra o armazém
        com o candidato no lugar. doc None com erro = não julgado."""
        try:
            others = self._texts(skip=name)
            corpus = kg_validate.index_texts(others + ([(name, text)] if text is not None else []))
            sources = [(name, text)] if text is not None else []
            sources += [(n, t) for n, t in others if name in kg_validate.external_targets(t)]
            doc = kg_validate.judge(sources, self.schema, corpus=corpus)
        except Exception as exc:  # noqa: BLE001 - qualquer falha do julgamento é "não julgado", nunca PASS
            return None, f"{type(exc).__name__}: {exc}"
        if not _verdict_ok(doc):
            return None, "o julgamento saiu fora de spec/verdict.schema.json"
        return doc, None

    def _result(self, name, written, reason=None, sha=None, ref=None, verdict=None, error=None, unchanged=False):
        return {"written": written, "reason": reason, "name": name, "sha256": sha, "ref": ref,
                "verdict": verdict, "error": error, "unchanged": unchanged}

    def write(self, name, text, message=None, author=None, expected_sha256=None):
        check_name(name)
        check_author(author)
        message = check_message(message, f"grava {name}")
        if not isinstance(text, str):
            raise StoreError("o texto do grafo tem de ser str")
        lock = self._lock()
        try:
            self._precheck()
            head = self._read_head(name)
            visible = self._visible(name, head)
            current = sha256(visible) if visible is not None else None
            if expected_sha256 is not None and expected_sha256 != (current or NEW):
                return self._result(name, False, "conflict", current)
            doc, err = self._judge(name, text)
            if doc is None:
                return self._result(name, False, "not_judged", current, error=err)
            if any(r["verdict"] == "FAIL" for r in doc["results"]):
                return self._result(name, False, "gate", current, verdict=doc)
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
            head = self._read_head(name)
            if self._visible(name, head) is None:
                return self._result(name, False, "missing")
            current = sha256(head)
            if expected_sha256 is not None and expected_sha256 != current:
                return self._result(name, False, "conflict", current)
            doc, err = self._judge(name, None)
            if doc is None:
                return self._result(name, False, "not_judged", current, error=err)
            if any(r["verdict"] == "FAIL" for r in doc["results"]):
                return self._result(name, False, "gate", current, verdict=doc)
            self._remove_head(name)
            try:
                ref = self._commit("delete", name, None, message, author, None)
            except BaseException:
                self._restore(name, head)
                raise
            return self._result(name, True, None, None, ref, doc)
        finally:
            self._unlock(lock)

    def _precheck(self):
        """O registro está legível? Falha aqui, antes de tocar a cabeça."""

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

    def __init__(self, root, schema=None, init=False, committer=("kg-store", "kg-store@localhost")):
        super().__init__(root, schema, init)
        self.committer = committer
        git = self.root / ".git"
        if not os.path.lexists(git):
            if not init:
                raise StoreError(f"{self.root} não tem .git (use init=True para criar)")
            self._git("init", "-q", setup=True)
        st = os.lstat(git)
        if stat.S_ISLNK(st.st_mode) or not stat.S_ISDIR(st.st_mode):
            raise StoreError(f"{git} tem de ser um diretório, não symlink nem gitfile")
        exclude = git / "info" / "exclude"  # a trava do armazém não é conteúdo: fica fora do status
        try:
            for p in (git / "info", exclude):
                if os.path.lexists(p) and stat.S_ISLNK(os.lstat(p).st_mode):
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
        out = self._git("ls-files", "-z", "--", "*.kg.yaml", check=False)
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

    def _read_ref(self, name, ref):
        if not re.match(r"^[0-9a-fA-F]{4,64}$", str(ref)):
            raise StoreError(f"ref inválida: {ref!r} (um sha de commit)")
        out = self._git("show", f"{ref}:{name}", check=False)
        if out.returncode != 0:
            raise NotFound(f"{name} não existe em {ref}")
        return out.stdout.decode("utf-8")

    def history(self, name):
        check_name(name)
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
        parts = [META, *rel.split("/")]
        try:
            dfd = self._dir(parts[:-1])
        except NotFound:
            return None
        try:
            fd = os.open(parts[-1], os.O_RDONLY | _NOFOLLOW, dir_fd=dfd)
        except FileNotFoundError:
            return None
        except OSError as exc:
            raise StoreError(f"{META}/{rel} recusado (symlink?)") from exc
        finally:
            os.close(dfd)
        with os.fdopen(fd, "rb") as fh:
            try:
                return fh.read().decode("utf-8")
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
        dfd = self._dir([META], create=True)
        try:
            fd = os.open("events.jsonl", os.O_WRONLY | os.O_CREAT | os.O_APPEND | _NOFOLLOW, 0o644, dir_fd=dfd)
            with os.fdopen(fd, "a", encoding="utf-8") as fh:
                fh.write(json.dumps(event, ensure_ascii=False) + "\n")
                fh.flush()
                os.fsync(fh.fileno())
        except OSError as exc:
            raise StoreError(f"não deu para registrar o evento: {exc}") from exc
        finally:
            os.close(dfd)
        return seq

    def history(self, name):
        check_name(name)
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


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--backend", choices=sorted(BACKENDS), default="disk")
    ap.add_argument("--root", required=True)
    ap.add_argument("--init", action="store_true", help="cria a raiz (e o repo, no git) se não existe")
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
    p = sub.add_parser("history")
    p.add_argument("name")
    args = ap.parse_args(argv)

    def emit(obj):
        print(json.dumps(obj, ensure_ascii=False, indent=1))
    try:
        store = open_store(args.backend, args.root, init=args.init)
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
