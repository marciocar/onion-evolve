#!/usr/bin/env python3
"""O vendor do KG-SSOT por pin (E6, EPIC_6_CORE_GRADUATION): o adotante traz a release por TAG, nunca à mão.

  update --tag T [--dest DIR] [--source REPO] [--force] [--profile P]
      Lê da TAG (git archive, nunca a árvore de trabalho) os arquivos que o spec/release.json DESSA tag lista,
      e substitui DIR inteiro (arquivo que saiu da release some). Grava o carimbo DIR/.kg-ssot-version: tag,
      commit, versão, contrato e o sha256 de cada arquivo. Não commita: quem commita é o adotante.
      DIR só é substituído se não existir, ou se tiver o carimbo E estiver íntegro (check rc 0); um vendor
      editado só é substituído com --force, para a edição local não sumir em silêncio.
      --source é o repo git (caminho ou URL) que tem a tag; o default é o repo deste script, e só vale quando
      ele é a raiz de um clone do KG-SSOT (dentro de um vendor, passe --source).
      --profile P traz só o perfil P do release.json da tag (Q_RELEASE_MINIMAL_GATE_PROFILE): `gate` é o mínimo para
      rodar o gate e o check (contrato, leitor, gate, vendor, requirements, guia e licença), sem a suíte. O carimbo
      registra o perfil, o check confere só o que ele trouxe, e o update seguinte HERDA o perfil do carimbo;
      --profile full volta à release inteira.
  check [--dest DIR]
      Recalcula os sha256 e compara com o carimbo: arquivo editado, faltando ou sobrando (inclusive bytecode em
      __pycache__ e symlink) → rc 1. O contrato não se customiza no adotante; uma mudança necessária volta como
      sinal ao produto. LIMITE: o carimbo atesta a si mesmo; o check pega edição acidental, não quem edita um
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

ROOT = pathlib.Path(__file__).resolve().parent.parent
STAMP = ".kg-ssot-version"
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
            raise Broken(f"a entrada {entry!r} do {RELEASE} não cobre nenhum arquivo")
        files += hit
    return sorted(set(files))


def read_release(text, where):
    try:
        release = json.loads(text)
    except json.JSONDecodeError as exc:
        raise Broken(f"{RELEASE} ilegível em {where}: {exc}") from exc
    if not isinstance(release, dict):
        raise Broken(f"{RELEASE} em {where}: tem de ser um objeto")
    if not isinstance(release.get("files"), list) or not release["files"] \
            or not all(isinstance(e, str) and e for e in release["files"]):
        raise Broken(f"{RELEASE} em {where}: files tem de ser uma lista não vazia de caminhos")
    contract = release.get("contract")
    if not isinstance(contract, dict) or not all(isinstance(contract.get(k), str) for k in ("must", "should")):
        raise Broken(f"{RELEASE} em {where}: contract tem de ter must e should")
    profiles = release.get("profiles", {})
    if not isinstance(profiles, dict) or not all(
            isinstance(k, str) and isinstance(v, list) and v and all(isinstance(e, str) and e for e in v)
            for k, v in profiles.items()):
        raise Broken(f"{RELEASE} em {where}: profiles tem de mapear nome → lista não vazia de caminhos")
    return release


def profile_files(release, full, listed, profile):
    """Os arquivos de um perfil: as entradas dele, que têm de estar dentro da release e levar o release.json e o
    contrato (sem eles o carimbo e o leitor não funcionam)."""
    if profile not in release.get("profiles", {}):
        raise Broken(f"a release {release.get('tag')!r} não tem o perfil {profile!r} "
                     f"(perfis: {', '.join(sorted(release.get('profiles', {}))) or 'nenhum'})")
    files = release_files(listed, release["profiles"][profile])
    outside = sorted(set(files) - set(full))
    if outside:
        raise Broken(f"o perfil {profile!r} leva o que a release não leva: {', '.join(outside[:5])}")
    # sem o release.json e o contrato o carimbo e o leitor não funcionam; sem o próprio vendor, o check e o update não rodam
    need = [RELEASE, *release["contract"].values()] + ([VENDOR] if VENDOR in full else [])
    missing = [f for f in need if f not in files]
    if missing:
        raise Broken(f"o perfil {profile!r} não leva {', '.join(missing)}")
    return files


def read_stamp(dest):
    path = pathlib.Path(dest) / STAMP
    try:
        stamp = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise Broken(f"carimbo {path} ausente ou ilegível: {exc}") from exc
    files = stamp.get("files") if isinstance(stamp, dict) else None
    if not isinstance(files, dict) or not files \
            or not all(isinstance(k, str) and isinstance(v, str) and HEX64.match(v) for k, v in files.items()):
        raise Broken(f"carimbo {path} fora do formato: files tem de mapear caminho → sha256")
    if not all(isinstance(stamp.get(k), str) and stamp[k] for k in ("tag", "commit")) or RELEASE not in files:
        raise Broken(f"carimbo {path} fora do formato: falta tag, commit ou o {RELEASE}")
    return stamp


def default_source():
    """O repo deste script, só quando ele é a raiz de um clone (num vendor, a raiz git é a do adotante)."""
    try:
        top = git(ROOT, "rev-parse", "--show-toplevel").strip()
    except Broken:
        top = ""
    if not top or pathlib.Path(top).resolve() != ROOT:
        raise Broken(f"{ROOT} não é a raiz de um clone do KG-SSOT (é um vendor?): passe --source <caminho ou URL>")
    return str(ROOT)


FULL = "full"


def update(dest, tag, source, force=False, profile=None):
    """profile None herda o perfil do carimbo que já existe (um update não tira o adotante do perfil em silêncio);
    'full' traz a release inteira."""
    dest = pathlib.Path(dest)
    if profile is not None and not profile.strip():
        raise Broken("--profile vazio: diga o perfil, ou full para a release inteira")
    if profile is None and (dest / STAMP).is_file():
        try:
            inherited = json.loads((dest / STAMP).read_text(encoding="utf-8")).get("profile")
        except (OSError, json.JSONDecodeError, AttributeError):
            inherited = None
        if isinstance(inherited, str) and inherited:
            profile = inherited
            print(f"perfil {profile} herdado do carimbo (--profile {FULL} traz a release inteira)")
    if profile == FULL:
        profile = None
    if dest.exists():
        if not (dest / STAMP).is_file():
            raise Broken(f"{dest} existe e não tem o carimbo {STAMP}: não substituo um diretório que não é vendor")
        if not force:
            with io.StringIO() as sink:
                stdout, sys.stdout = sys.stdout, sink
                try:
                    clean = check(dest) == 0
                finally:
                    sys.stdout = stdout
            if not clean:
                raise Broken(f"{dest} diverge do carimbo (rode check): a edição local sumiria; use --force se é isso")
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
            raise Broken(f"--source {source} não é um repositório git") from None
        try:
            git(repo, "rev-parse", "--verify", "--quiet", f"refs/tags/{tag}")
        except Broken:
            raise Broken(f"a tag {tag} não existe em {source}") from None
        commit = git(repo, "rev-parse", f"refs/tags/{tag}^{{commit}}").strip()
        release = read_release(git(repo, "show", f"{commit}:{RELEASE}"), tag)
        if release.get("tag") != tag:
            raise Broken(f"o {RELEASE} da tag {tag} declara a tag {release.get('tag')!r}: release mal rotulada")
        listed = git(repo, "ls-tree", "-r", "--name-only", commit).splitlines()
        files = release_files(listed, release["files"])
        if profile:
            files = profile_files(release, files, listed, profile)
        tar = tarfile.open(fileobj=io.BytesIO(git(repo, "archive", "--format=tar", commit, "--", *files, binary=True)))
        staged = pathlib.Path(tmp) / "staged"
        staged.mkdir()
        hashes = {}
        for member in tar.getmembers():
            if member.isdir() or member.type == tarfile.XGLTYPE:  # o pax global do git archive (o commit)
                continue
            if not member.isfile():
                raise Broken(f"{member.name} na tag não é arquivo regular (symlink?): a release só leva arquivos")
            target = staged / member.name
            if staged.resolve() not in target.resolve().parents:
                raise Broken(f"caminho fora do destino no arquivo da tag: {member.name}")
            data = tar.extractfile(member).read()
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(data)
            hashes[member.name] = sha256(data)
        if set(hashes) != set(files):
            raise Broken(f"a tag trouxe {len(hashes)} arquivos e a release lista {len(files)}: "
                         + ", ".join(sorted(set(files) ^ set(hashes))[:5]))
        stamp = {"product": "kg-ssot", "tag": tag, "commit": commit, "version": release.get("version"),
                 "contract": release["contract"], "vendored_at": datetime.date.today().isoformat(),
                 "files": dict(sorted(hashes.items()))}
        if profile:
            stamp["profile"] = profile
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
    print(f"vendor atualizado: {dest} ← {tag} ({commit[:12]}), {len(hashes)} arquivos"
          + (f", perfil {profile}" if profile else ""))
    return 0


def check(dest):
    dest = pathlib.Path(dest)
    stamp = read_stamp(dest)
    want = stamp["files"]
    got, links = {}, []
    for p in dest.rglob("*"):
        rel = p.relative_to(dest).as_posix()
        if p.is_symlink():
            links.append(rel)
        elif p.is_file() and rel != STAMP:
            got[rel] = sha256(p.read_bytes())
    lines = [f"✗ editado  {f}" for f in sorted(want.keys() & got.keys()) if want[f] != got[f]]
    lines += [f"✗ faltando {f}" for f in sorted(want.keys() - got.keys() - set(links))]
    lines += [f"✗ sobrando {f}" for f in sorted(got.keys() - want.keys())]
    lines += [f"✗ symlink  {f}" for f in sorted(links)]
    if lines:
        print("\n".join(lines))
        print(f"vendor divergente da tag {stamp['tag']}: o contrato não se customiza no adotante — refaça o"
              " update, e se a mudança é necessária, mande-a como sinal ao produto")
        return 1
    print(f"✓ vendor íntegro: {dest} = {stamp['tag']} ({stamp['commit'][:12]}), {len(want)} arquivos")
    return 0


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    up = sub.add_parser("update", help="traz a release da tag para o destino")
    up.add_argument("--tag", required=True)
    up.add_argument("--dest", default=DEFAULT_DEST)
    up.add_argument("--source", help="repo git (caminho ou URL) que tem a tag (default: o clone deste script)")
    up.add_argument("--force", action="store_true", help="substitui um vendor que diverge do carimbo")
    up.add_argument("--profile", help="traz só um perfil da release (ex.: gate, sem a suíte)")
    ck = sub.add_parser("check", help="confere o destino contra o carimbo")
    ck.add_argument("--dest", default=DEFAULT_DEST)
    args = ap.parse_args(argv)
    try:
        if args.cmd == "update":
            return update(args.dest, args.tag, args.source, args.force, args.profile)
        return check(args.dest)
    except (Broken, OSError, tarfile.TarError) as exc:
        print(f"VENDOR QUEBRADO  {exc}")
        return 2


if __name__ == "__main__":
    sys.exit(main())
