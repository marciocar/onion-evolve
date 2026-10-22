#!/usr/bin/env python3
"""O vendor do KG-SSOT por pin: o adotante traz a release por TAG, nunca à mão.

  update --tag T [--dest DIR] [--source REPO] [--force] [--profile P]
      Lê da TAG (git archive, nunca a árvore de trabalho) os arquivos que o spec/release.json DESSA tag lista,
      e substitui DIR inteiro (arquivo que saiu da release some). Grava o carimbo DIR/.kg-ssot-version: tag,
      commit, versão, contrato e o sha256 de cada arquivo. Da 4.8.1 em diante, grava DIR/.gitattributes com `* -text`: um
      atributo aninhado vence o do repo, e a regra de fim de linha do adotante (`*.json text eol=lf`, autocrlf)
      não reescreve no índice os bytes da release (as fixtures com CRLF de propósito). Não commita: quem
      commita é o adotante.
      DIR só é substituído se não existir, ou se tiver o carimbo E estiver íntegro (check rc 0); um vendor
      editado só é substituído com --force, para a edição local não sumir em silêncio.
      --source é o repo git (caminho ou URL, como o repositório público https://github.com/marciocar/kg-ssot) que
      tem a tag; o default é o repo deste script, e só vale quando
      ele é a raiz de um clone do KG-SSOT (dentro de um vendor, passe --source).
      --profile P traz só o perfil P do release.json da tag: `gate` é o mínimo para
      rodar o gate e o check (contrato, leitor, gate, vendor, requirements, guia e licença), sem a suíte. O carimbo
      registra o perfil, o check confere só o que ele trouxe, e o update seguinte HERDA o perfil do carimbo;
      --profile full volta à release inteira.
  check [--dest DIR] [--index]
      Recalcula os sha256 e compara com o carimbo: arquivo editado, faltando ou sobrando (inclusive bytecode em
      __pycache__ e symlink) → rc 1. Com --index, confere os blobs do índice do git (o carimbo também lido do
      índice) em vez da árvore de trabalho: é o que o commit vai levar, e pega antes do commit uma normalização
      de fim de linha que a árvore de trabalho esconde. O contrato não se customiza no adotante; uma mudança necessária volta ao produto
      como issue no repositório público. LIMITE: o carimbo atesta a si mesmo; o check pega edição acidental, não quem edita um
      arquivo E recalcula o carimbo. Isso o review do PR do adotante pega (o diff do carimbo fica à vista).

rc: 0 ok · 1 vendor divergente do carimbo · 2 entrada quebrada (tag inexistente, release.json ausente ou que
não bate com a tag, entrada da release sem arquivo, membro da tag que não é arquivo regular, carimbo ausente,
ilegível ou fora do formato, DIR sem carimbo ou editado sem --force).
Os scripts do kit não gravam bytecode (sys.dont_write_bytecode): RODAR o gate como script não suja o vendor.
IMPORTAR um módulo do kit a partir de outro processo suja: o Python grava o .pyc do módulo antes de executar o
código dele. Por isso o guia roda tudo com `python3 -I -B`, e quem importa o kit usa -B ou PYTHONDONTWRITEBYTECODE=1.
"""
import sys

sys.dont_write_bytecode = True  # noqa: E402 — o vendor tem de continuar idêntico ao carimbo depois de usado

import argparse
import datetime
import hashlib
import io
import json
import os
import pathlib
import re
import shutil
import subprocess
import tarfile
import tempfile

if __package__:  # no pacote kg_ssot, o vizinho vem pelo pacote, sem mexer no sys.path de quem importa
    from . import kg_i18n
else:  # script ou vendor
    sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
    import kg_i18n  # noqa: E402
_ = kg_i18n._

ROOT = pathlib.Path(__file__).resolve().parent.parent
STAMP = ".kg-ssot-version"
ATTRS = ".gitattributes"
# os bytes da release são os do carimbo: nenhuma conversão de fim de linha do repo do adotante (eol, autocrlf)
ATTRS_SINCE = (4, 8, 1)  # a release que passou a levar o .gitattributes no vendor
ATTRS_TEXT = "# Gravado pelo kg_vendor.py: os bytes do vendor são os do carimbo, sem conversão de fim de linha.\n* -text\n"
RELEASE = "spec/release.json"
VENDOR = "tools/kg_vendor.py"  # se a release o leva, todo perfil leva: sem ele não há check nem update
DEFAULT_DEST = "vendor/kg-ssot"
HEX64 = re.compile(r"^[0-9a-f]{64}$")

class Broken(Exception):
    """Entrada quebrada: rc 2."""


def git(repo, *args, binary=False):
    # pathspec literal: um nome com *, ? ou [ nunca vira glob que traz arquivo fora da release
    env = dict(os.environ, GIT_LITERAL_PATHSPECS="1")
    out = subprocess.run(["git", "-C", str(repo), *args], capture_output=True, env=env)
    if out.returncode != 0:
        raise Broken(f"git {' '.join(args[:2])}: {out.stderr.decode('utf-8', 'replace').strip()[:200]}")
    return out.stdout if binary else out.stdout.decode("utf-8")


def sha256(data):
    return hashlib.sha256(data).hexdigest()


def release_files(listed, entries):
    """As entradas da release (arquivo, ou diretório terminado em /) → os arquivos que elas cobrem."""
    files = []
    for entry in entries:
        hit = [f for f in listed if (f.startswith(entry) if entry.endswith("/") else f == entry)]
        if not hit:
            raise Broken(_("entry {entry} in {release} covers no file").format(entry=repr(entry), release=RELEASE))
        files += hit
    return sorted(set(files))


def read_release(text, where):
    try:
        release = json.loads(text)
    except json.JSONDecodeError as exc:
        raise Broken(_("{release} unreadable at {where}: {exc}").format(release=RELEASE, where=where, exc=exc)) from exc
    if not isinstance(release, dict):
        raise Broken(_("{release} at {where}: must be an object").format(release=RELEASE, where=where))
    if not isinstance(release.get("files"), list) or not release["files"] \
            or not all(isinstance(e, str) and e for e in release["files"]):
        raise Broken(_("{release} at {where}: files must be a non-empty list of paths").format(release=RELEASE,
                                                                                                 where=where))
    contract = release.get("contract")
    if not isinstance(contract, dict) or not all(isinstance(contract.get(k), str) for k in ("must", "should")):
        raise Broken(_("{release} at {where}: contract must have must and should").format(release=RELEASE, where=where))
    profiles = release.get("profiles", {})
    if not isinstance(profiles, dict) or not all(
            isinstance(k, str) and isinstance(v, list) and v and all(isinstance(e, str) and e for e in v)
            for k, v in profiles.items()):
        raise Broken(_("{release} at {where}: profiles must map name → non-empty list of paths").format(
            release=RELEASE, where=where))
    return release


def profile_files(release, full, listed, profile):
    """Os arquivos de um perfil: as entradas dele, que têm de estar dentro da release e levar o release.json e o
    contrato (sem eles o carimbo e o leitor não funcionam)."""
    if profile not in release.get("profiles", {}):
        names = ", ".join(sorted(release.get("profiles", {})))
        text = (_("release {tag} has no profile {profile} (profiles: {profiles})") if names
                else _("release {tag} has no profile {profile} (no profiles)"))
        raise Broken(text.format(tag=repr(release.get("tag")), profile=repr(profile), profiles=names))
    files = release_files(listed, release["profiles"][profile])
    outside = sorted(set(files) - set(full))
    if outside:
        raise Broken(_("profile {profile} carries what the release does not: {files}").format(
            profile=repr(profile), files=", ".join(outside[:5])))
    # sem o release.json e o contrato o carimbo e o leitor não funcionam; sem o próprio vendor, o check e o update não rodam
    need = [RELEASE, *release["contract"].values()] + ([VENDOR] if VENDOR in full else [])
    missing = [f for f in need if f not in files]
    if missing:
        raise Broken(_("profile {profile} does not carry {files}").format(profile=repr(profile),
                                                                          files=", ".join(missing)))
    return files


def read_stamp(dest):
    path = pathlib.Path(dest) / STAMP
    try:
        stamp = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise Broken(_("stamp {path} missing or unreadable: {exc}").format(path=path, exc=exc)) from exc
    files = stamp.get("files") if isinstance(stamp, dict) else None
    if not isinstance(files, dict) or not files \
            or not all(isinstance(k, str) and isinstance(v, str) and HEX64.match(v) for k, v in files.items()):
        raise Broken(_("stamp {path} malformed: files must map path → sha256").format(path=path))
    if not all(isinstance(stamp.get(k), str) and stamp[k] for k in ("tag", "commit")) or RELEASE not in files:
        raise Broken(_("stamp {path} malformed: missing tag, commit or {release}").format(path=path, release=RELEASE))
    return stamp


def default_source():
    """O repo deste script, só quando ele é a raiz de um clone (num vendor, a raiz git é a do adotante)."""
    try:
        top = git(ROOT, "rev-parse", "--show-toplevel").strip()
    except Broken:
        top = ""
    if not top or pathlib.Path(top).resolve() != ROOT:
        raise Broken(_("{root} is not the root of a KG-SSOT clone (a vendor?): pass --source <path or URL>").format(
            root=ROOT))
    return str(ROOT)


FULL = "full"


def update(dest, tag, source, force=False, profile=None):
    """profile None herda o perfil do carimbo que já existe (um update não tira o adotante do perfil em silêncio);
    'full' traz a release inteira."""
    dest = pathlib.Path(dest)
    if profile is not None and not profile.strip():
        raise Broken(_("empty --profile: name the profile, or full for the whole release"))
    if profile is None and (dest / STAMP).is_file():
        try:
            inherited = json.loads((dest / STAMP).read_text(encoding="utf-8")).get("profile")
        except (OSError, json.JSONDecodeError, AttributeError):
            inherited = None
        if isinstance(inherited, str) and inherited:
            profile = inherited
            print(_("profile {profile} inherited from the stamp (--profile {full} brings the whole release)").format(
                profile=profile, full=FULL))
    if profile == FULL:
        profile = None
    if dest.exists():
        if not (dest / STAMP).is_file():
            raise Broken(_("{dest} exists and has no stamp {stamp}: not replacing a directory that is not a vendor")
                         .format(dest=dest, stamp=STAMP))
        if not force:
            with io.StringIO() as sink:
                stdout, sys.stdout = sys.stdout, sink
                try:
                    clean = check(dest, legacy_ok=True) == 0
                finally:
                    sys.stdout = stdout
            if not clean:
                raise Broken(_("{dest} diverges from the stamp (run check): the local edit would be lost; use --force"
                               " if you mean it").format(dest=dest))
    source = source or default_source()
    dest.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(dir=dest.parent, prefix=".kg-ssot-tmp-") as tmp:
        repo = pathlib.Path(source)
        if not repo.is_dir():  # URL: clone nu, descartável; "--" impede que a URL vire opção do git
            git(tmp, "clone", "--quiet", "--bare", "--", str(source), "src.git")
            repo = pathlib.Path(tmp) / "src.git"
        try:
            git(repo, "rev-parse", "--git-dir")
        except Broken:
            raise Broken(_("--source {source} is not a git repository").format(source=source)) from None
        try:
            git(repo, "rev-parse", "--verify", "--quiet", f"refs/tags/{tag}")
        except Broken:
            raise Broken(_("tag {tag} does not exist in {source}").format(tag=tag, source=source)) from None
        commit = git(repo, "rev-parse", f"refs/tags/{tag}^{{commit}}").strip()
        release = read_release(git(repo, "show", f"{commit}:{RELEASE}"), tag)
        if release.get("tag") != tag:
            raise Broken(_("the {release} of tag {tag} declares tag {declared}: mislabeled release").format(
                release=RELEASE, tag=tag, declared=repr(release.get("tag"))))
        listed = git(repo, "ls-tree", "-r", "--name-only", commit).splitlines()
        files = release_files(listed, release["files"])
        if profile:
            files = profile_files(release, files, listed, profile)
        # o archive vai pelas entradas da release, não arquivo a arquivo: a lista inteira passa do limite da linha de
        # comando do Windows (32.767 caracteres, WinError 206) desde a 4.13.0; o que a entrada cobre e o perfil tira
        # é descartado abaixo
        specs = sorted({e.rstrip("/") for e in release["files"]})
        tar = tarfile.open(fileobj=io.BytesIO(git(repo, "archive", "--format=tar", commit, "--", *specs, binary=True)))
        wanted = set(files)
        staged = pathlib.Path(tmp) / "staged"
        staged.mkdir()
        hashes = {}
        for member in tar.getmembers():
            if member.isdir() or member.type == tarfile.XGLTYPE:  # o pax global do git archive (o commit)
                continue
            target = staged / member.name
            if staged.resolve() not in target.resolve().parents:
                raise Broken(_("path outside the destination in the tag archive: {name}").format(name=member.name))
            if member.name not in wanted:
                continue
            if not member.isfile():
                raise Broken(_("{name} in the tag is not a regular file (symlink?): the release carries only files")
                             .format(name=member.name))
            data = tar.extractfile(member).read()
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(data)
            hashes[member.name] = sha256(data)
        if set(hashes) != set(files):
            raise Broken(_("the tag brought {got} files and the release lists {want}: {diff}").format(
                got=len(hashes), want=len(files), diff=", ".join(sorted(set(files) ^ set(hashes))[:5])))
        stamp = {"product": "kg-ssot", "tag": tag, "commit": commit, "version": release.get("version"),
                 "contract": release["contract"], "vendored_at": datetime.date.today().isoformat(),
                 "files": dict(sorted(hashes.items()))}
        if profile:
            stamp["profile"] = profile
        if _version(release.get("version")) >= ATTRS_SINCE:
            # só nas releases que o conhecem: o kit vendorizado de uma tag anterior acusaria o arquivo como sobrando
            (staged / ATTRS).write_bytes(ATTRS_TEXT.encode("utf-8"))
            stamp["gitattributes"] = sha256(ATTRS_TEXT.encode("utf-8"))
        (staged / STAMP).write_text(json.dumps(stamp, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        # troca por rename no mesmo diretório: o vendor nunca fica pela metade
        old = pathlib.Path(tmp) / "old"
        if dest.exists():
            dest.rename(old)
        try:
            staged.rename(dest)
        except OSError:
            if old.exists():
                old.rename(dest)  # devolve o vendor anterior
            raise
    done = (_("vendor updated: {dest} ← {tag} ({commit}), {n} files, profile {profile}") if profile
            else _("vendor updated: {dest} ← {tag} ({commit}), {n} files"))
    print(done.format(dest=dest, tag=tag, commit=commit[:12], n=len(hashes), profile=profile))
    return 0


def _index_tree(dest):
    """{caminho relativo a DIR: bytes} e a lista de symlinks, lidos do índice do git (o que o commit vai levar)."""
    if not dest.is_dir():
        raise Broken(_("{dest} does not exist").format(dest=dest))
    try:
        prefix = git(dest, "rev-parse", "--show-prefix").strip()
    except Broken as exc:
        raise Broken(_("{dest} is not in a git repo: --index needs the index ({exc})").format(dest=dest, exc=exc)) \
            from exc
    # --full-name: o caminho vem da raiz do repo, e só o prefixo exato de DIR sai (um vendor aninhado dentro do
    # vendor não se confunde com ele); surrogateescape: um nome que não é UTF-8 vira sobrando, não traceback
    out = git(dest, "ls-files", "-z", "--stage", "--full-name", "--", ".", binary=True)
    files, links = {}, []
    for entry in filter(None, out.decode("utf-8", "surrogateescape").split("\0")):
        meta, path = entry.split("\t", 1)
        mode, blob, _stage = meta.split()
        if not path.startswith(prefix):
            raise Broken(_("the index returned {path} outside {prefix}").format(path=repr(path), prefix=repr(prefix)))
        rel = path[len(prefix):]
        if mode == "120000":
            links.append(rel)
        else:
            files[rel] = git(dest, "cat-file", "blob", blob, binary=True)
    return files, links


def _version(text):
    try:
        return tuple(int(x) for x in str(text).split("."))
    except ValueError:
        return ()


def check(dest, index=False, legacy_ok=False):
    """legacy_ok: o update aceita refazer um vendor da 4.8.1 gravado por um kit anterior (sem o .gitattributes)."""
    dest = pathlib.Path(dest)
    if index:
        tree, links = _index_tree(dest)
        if STAMP not in tree:
            raise Broken(_("stamp {path} missing from the index: run git add on the vendor before check --index")
                         .format(path=dest / STAMP))
        with tempfile.TemporaryDirectory() as tmp:
            (pathlib.Path(tmp) / STAMP).write_bytes(tree[STAMP])
            stamp = read_stamp(tmp)
    else:
        stamp = read_stamp(dest)
        tree, links = {}, []
        for p in dest.rglob("*"):
            rel = p.relative_to(dest).as_posix()
            if p.is_symlink():
                links.append(rel)
            elif p.is_file():
                tree[rel] = p.read_bytes()
    want = stamp["files"]
    attrs = tree.pop(ATTRS, None)
    tree.pop(STAMP, None)
    got = {rel: sha256(data) for rel, data in tree.items()}
    lines = []
    if "gitattributes" in stamp:  # carimbo da 4.8.1 em diante: o .gitattributes do vendor é parte dele
        if attrs is None:
            lines.append(_("✗ missing  {path}").format(path=ATTRS))
        elif sha256(attrs) != stamp["gitattributes"]:
            lines.append(_("✗ edited   {path}").format(path=ATTRS))
    else:
        if attrs is not None:
            got[ATTRS] = sha256(attrs)
        if _version(stamp.get("version")) >= ATTRS_SINCE and not legacy_ok:
            # o kit da 4.8.0 trouxe a 4.8.1 sem gravar o .gitattributes: o vendor fica exposto à regra de fim de
            # linha do repo, e o update de novo, já com o kit novo, o grava
            lines.append(_("✗ missing  {path} (the stamp for {version} was written by an earlier kg_vendor: run the"
                           " update again, now with the new kit)").format(path=ATTRS, version=stamp["version"]))
    lines += [_("✗ edited   {path}").format(path=f) for f in sorted(want.keys() & got.keys()) if want[f] != got[f]]
    lines += [_("✗ missing  {path}").format(path=f) for f in sorted(want.keys() - got.keys() - set(links))]
    lines += [_("✗ extra    {path}").format(path=f) for f in sorted(got.keys() - want.keys())]
    lines += [_("✗ symlink  {path}").format(path=f) for f in sorted(links)]
    if lines:
        print("\n".join(lines))
        print(_("vendor diverges from tag {tag}: do not customize the contract in the adopter — redo the update,"
                " and if you need the change, send it to the product as a signal").format(tag=stamp["tag"]))
        return 1
    print(_("✓ vendor intact: {dest} = {tag} ({commit}), {n} files").format(
        dest=dest, tag=stamp["tag"], commit=stamp["commit"][:12], n=len(want)))
    return 0


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


# o texto do --help em inglês (a fonte da tradução); a docstring do módulo é a versão pt-BR dele
DESCRIPTION = """Vendor KG-SSOT by pin: the adopter brings in the release by TAG, never by hand.

  update --tag T [--dest DIR] [--source REPO] [--force] [--profile P]
      Reads from the TAG (git archive, never the working tree) the files that the spec/release.json OF THAT tag
      lists, and replaces DIR entirely (a file that left the release goes away). Writes the vendor stamp
      DIR/.kg-ssot-version: tag, commit, version, contract and the sha256 of each file. From 4.8.1 on, writes
      DIR/.gitattributes with `* -text`: a nested attribute beats the repo's, and the adopter's line-ending rule
      (`*.json text eol=lf`, autocrlf) does not rewrite the release bytes in the index (the fixtures with CRLF on
      purpose). It does not commit: the adopter commits.
      DIR is replaced only if it does not exist, or if it has the stamp AND is intact (check rc 0); an edited
      vendor is replaced only with --force, so the local edit does not vanish silently.
      --source is the git repo (path or URL, such as the public repository https://github.com/marciocar/kg-ssot)
      that has the tag; the default is this script's repo, and it only works when that is the root of a
      KG-SSOT clone (inside a vendor, pass --source).
      --profile P brings only profile P from the tag's release.json: `gate` is the minimum to run the gate and
      the check (contract, reader, gate, vendor, requirements, guide and license), without the suite. The stamp
      records the profile, check verifies only what the profile brought, and the next update INHERITS the
      profile from the stamp; --profile full goes back to the whole release.
  check [--dest DIR] [--index]
      Recomputes the sha256 values and compares them with the stamp: a file edited, missing or extra (including
      bytecode in __pycache__ and symlinks) → rc 1. With --index, verifies the blobs in the git index (the stamp
      is also read from the index) instead of the working tree: that is what the commit will carry, and it
      catches, before the commit, a line-ending normalization that the working tree hides. You do not customize
      the contract in the adopter; a needed change goes back to the product as an issue in the public
      repository. LIMIT: the stamp vouches for itself; check catches an accidental edit, not someone who edits a
      file AND recomputes the stamp. The review of the adopter's PR catches that (the stamp diff is in plain
      view).

rc: 0 ok · 1 vendor diverges from the stamp · 2 broken input (tag does not exist, release.json missing or not
matching the tag, release entry with no file, tag member that is not a regular file, stamp missing, unreadable
or malformed, DIR without a stamp or edited without --force).
The kit's scripts do not write bytecode (sys.dont_write_bytecode): RUNNING the gate as a script does not dirty
the vendor. IMPORTING a kit module from another process does: Python writes the module's .pyc before it runs the
module's code. That is why the guide runs everything with `python3 -I -B`, and whoever imports the kit uses -B or
PYTHONDONTWRITEBYTECODE=1.
"""


def main(argv=None):
    ap = argparse.ArgumentParser(description=_(DESCRIPTION), formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    up = sub.add_parser("update", help=_("brings the release from the tag into the destination"))
    up.add_argument("--tag", required=True)
    up.add_argument("--dest", default=DEFAULT_DEST)
    up.add_argument("--source", help=_("git repo (path or URL) that has the tag (default: this script's clone)"))
    up.add_argument("--force", action="store_true", help=_("replaces a vendor that diverges from the stamp"))
    up.add_argument("--profile", help=_("brings only one profile of the release (e.g. gate, without the suite)"))
    ck = sub.add_parser("check", help=_("verifies the destination against the stamp"))
    ck.add_argument("--dest", default=DEFAULT_DEST)
    ck.add_argument("--index", action="store_true", help=_("verifies the git index blobs, not the working tree"))
    args = ap.parse_args(argv)
    _utf8_stdio()
    try:
        if args.cmd == "update":
            return update(args.dest, args.tag, args.source, args.force, args.profile)
        return check(args.dest, args.index)
    except (Broken, OSError, tarfile.TarError) as exc:
        print(_("BROKEN VENDOR  {error}").format(error=exc))
        return 2


if __name__ == "__main__":
    sys.exit(main())
