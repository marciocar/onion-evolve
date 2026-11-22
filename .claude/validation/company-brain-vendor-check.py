#!/usr/bin/env python3
"""company-brain-vendor-check.py — mantém e confere o vendor do motor do Company Brain (vendor/company-brain).

POR QUE EXISTE (2026-11-22). O maestro selou, no grafo do produto Onion Company Brain (D_ENGINE_LIVES_HERE), que o
motor do contexto do Company Brain (esquema de voz e conduta, validador, template e a especificação do construtor)
vive no repo do produto e que o core o vendoriza por TAG, com versão fixada. Vendor sem carimbo é cópia solta: não
se sabe de que tag veio nem se alguém o editou à mão. Este script é o carimbo e a conferência.

POR QUE NÃO O kg_vendor.py (o molde da kg-ssot): ele é da kg-ssot e fixa o produto (carimbo `.kg-ssot-version`,
manifesto de release dentro da tag, perfis, atestação do GitHub). A tag do Company Brain não traz manifesto e o core
leva só um recorte do repo (INCLUDE abaixo). Daqui se reproduz o que é proporcional do molde: o carimbo com tag,
commit e sha256 de cada arquivo; a conferência do vendor contra o carimbo; e a conferência do carimbo contra os blobs
da tag num clone. Não é um vendorizador genérico: o recorte e o nome do carimbo são deste produto.

Uso:
  company-brain-vendor-check.py check  [--dest DIR]                  vendor x carimbo (offline; é o que o CI roda)
  company-brain-vendor-check.py verify --source REPO [--dest DIR]    carimbo x blobs da tag num clone
  company-brain-vendor-check.py update --tag TAG --source REPO [--dest DIR] [--today AAAA-MM-DD]
                                                                     substitui DIR pelo recorte da tag e carimba
Saída: 0 íntegro · 1 divergiu (achado) · 2 não deu para julgar (nunca é verde).
Exercitado por lint-selftest.sh (run_company_brain_vendor_selftests).
"""
import argparse
import datetime as dt
import hashlib
import io
import json
import os
import shutil
import subprocess
import sys
import tarfile

PRODUCT = "company-brain"
STAMP = ".company-brain-version"
DEFAULT_DEST = "vendor/company-brain"
# O recorte que o core leva (o motor): o resto do repo do produto (grafos, sessões, .claude/) fica lá.
INCLUDE = ["README.md", "builder", "spec", "templates", "tests", "tools"]


class Unjudgeable(Exception):
    """Algo impede o julgamento: rc 2."""


def sha256(data):
    return hashlib.sha256(data).hexdigest()


def git(repo, *args):
    proc = subprocess.run(["git", "-C", repo, *args], capture_output=True)
    if proc.returncode != 0:
        raise Unjudgeable(f"git {' '.join(args)} em {repo}: {proc.stderr.decode('utf-8', 'replace').strip()}")
    return proc.stdout


def tree_files(dest):
    """Os arquivos do vendor (caminho relativo -> sha256), sem o carimbo."""
    out = {}
    for base, dirs, files in os.walk(dest):
        dirs.sort()
        for name in sorted(files):
            full = os.path.join(base, name)
            rel = os.path.relpath(full, dest).replace(os.sep, "/")
            if rel == STAMP:
                continue
            if os.path.islink(full):
                out[rel] = "symlink"
                continue
            with open(full, "rb") as fh:
                out[rel] = sha256(fh.read())
    return out


def read_stamp(dest):
    path = os.path.join(dest, STAMP)
    if not os.path.isfile(path):
        raise Unjudgeable(f"sem carimbo {path}")
    try:
        with open(path, encoding="utf-8") as fh:
            stamp = json.load(fh)
    except (OSError, ValueError) as exc:
        raise Unjudgeable(f"carimbo ilegível {path}: {exc}") from exc
    for field in ("product", "tag", "commit", "version", "include", "files"):
        if field not in stamp:
            raise Unjudgeable(f"carimbo sem o campo {field!r}")
    if stamp["product"] != PRODUCT:
        raise Unjudgeable(f"carimbo de outro produto: {stamp['product']!r}")
    if not isinstance(stamp["files"], dict) or not stamp["files"]:
        raise Unjudgeable("carimbo sem arquivos")
    return stamp


def tag_files(source, tag):
    """(commit, {caminho: sha256}) do recorte INCLUDE na tag, lido do git archive do clone."""
    commit = git(source, "rev-parse", "--verify", f"{tag}^{{commit}}").decode().strip()
    raw = git(source, "archive", "--format=tar", commit, "--", *INCLUDE)
    files = {}
    with tarfile.open(fileobj=io.BytesIO(raw)) as tar:
        for member in tar.getmembers():
            if member.isfile():
                files[member.name] = sha256(tar.extractfile(member).read())
            elif member.issym():
                files[member.name] = "symlink"
    return commit, files, raw


def diff(want, got):
    """Achados entre o esperado e o achado, um por linha: CODIGO<TAB>caminho<TAB>texto."""
    lines = []
    for path in sorted(set(want) | set(got)):
        if path not in got:
            lines.append(f"CBV-MISSING\t{path}\tno carimbo, ausente")
        elif path not in want:
            lines.append(f"CBV-EXTRA\t{path}\tfora do carimbo")
        elif want[path] != got[path]:
            lines.append(f"CBV-SHA256\t{path}\tsha256 diverge do carimbo")
    return lines


def cmd_check(args):
    stamp = read_stamp(args.dest)
    found = diff(stamp["files"], tree_files(args.dest))
    for line in found:
        print(line)
    if found:
        print(f"company-brain-vendor: {args.dest} diverge do carimbo ({stamp['tag']}): {len(found)} achado(s)", file=sys.stderr)
        return 1
    print(f"company-brain-vendor: {args.dest} íntegro: {len(stamp['files'])} arquivos de {stamp['tag']} ({stamp['commit'][:12]})", file=sys.stderr)
    return 0


def cmd_verify(args):
    stamp = read_stamp(args.dest)
    commit, files, _ = tag_files(args.source, stamp["tag"])
    found = []
    if commit != stamp["commit"]:
        found.append(f"CBV-COMMIT\t{STAMP}\ta tag {stamp['tag']} aponta {commit[:12]} no clone, o carimbo diz {stamp['commit'][:12]}")
    if sorted(stamp["include"]) != sorted(INCLUDE):
        found.append(f"CBV-INCLUDE\t{STAMP}\to recorte do carimbo difere do recorte deste script")
    found += diff(files, stamp["files"])
    for line in found:
        print(line)
    if found:
        print(f"company-brain-vendor: o carimbo diverge da tag {stamp['tag']} no clone: {len(found)} achado(s)", file=sys.stderr)
        return 1
    print(f"company-brain-vendor: o carimbo confere com a tag {stamp['tag']} ({commit[:12]}): {len(files)} arquivos", file=sys.stderr)
    return 0


def cmd_update(args):
    commit, files, raw = tag_files(args.source, args.tag)
    if not files:
        raise Unjudgeable(f"a tag {args.tag} não traz nada do recorte {INCLUDE}")
    if any(v == "symlink" for v in files.values()):
        raise Unjudgeable("a tag traz link simbólico no recorte: o vendor não leva link")
    version = args.tag.rsplit("-v", 1)[-1] if "-v" in args.tag else args.tag
    if os.path.isdir(args.dest):
        shutil.rmtree(args.dest)
    os.makedirs(args.dest)
    with tarfile.open(fileobj=io.BytesIO(raw)) as tar:
        for member in tar.getmembers():
            if not member.isfile():
                continue
            target = os.path.join(args.dest, member.name)
            os.makedirs(os.path.dirname(target), exist_ok=True)
            with open(target, "wb") as fh:
                fh.write(tar.extractfile(member).read())
            if member.mode & 0o111:
                os.chmod(target, 0o755)
    stamp = {
        "product": PRODUCT,
        "tag": args.tag,
        "commit": commit,
        "version": version,
        "include": INCLUDE,
        "vendored_at": args.today or dt.datetime.now(dt.timezone.utc).date().isoformat(),
        "files": dict(sorted(files.items())),
    }
    with open(os.path.join(args.dest, STAMP), "w", encoding="utf-8") as fh:
        json.dump(stamp, fh, indent=2, ensure_ascii=False)
        fh.write("\n")
    print(f"company-brain-vendor: {args.dest} = {args.tag} ({commit[:12]}), {len(files)} arquivos carimbados", file=sys.stderr)
    return cmd_check(args)


def main(argv=None):
    parser = argparse.ArgumentParser(description="vendor do motor do Company Brain: carimbo e conferência")
    sub = parser.add_subparsers(dest="cmd", required=True)
    ck = sub.add_parser("check")
    ck.add_argument("--dest", default=DEFAULT_DEST)
    vf = sub.add_parser("verify")
    vf.add_argument("--dest", default=DEFAULT_DEST)
    vf.add_argument("--source", required=True)
    up = sub.add_parser("update")
    up.add_argument("--dest", default=DEFAULT_DEST)
    up.add_argument("--source", required=True)
    up.add_argument("--tag", required=True)
    up.add_argument("--today")
    args = parser.parse_args(argv)
    try:
        return {"check": cmd_check, "verify": cmd_verify, "update": cmd_update}[args.cmd](args)
    except Unjudgeable as exc:
        print(f"company-brain-vendor: não deu para julgar: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main())
