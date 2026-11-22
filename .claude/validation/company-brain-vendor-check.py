#!/usr/bin/env python3
"""company-brain-vendor-check.py — mantém e confere o vendor do motor do Company Brain (vendor/company-brain).

POR QUE EXISTE (2026-11-22). O maestro selou, no grafo do produto Onion Company Brain (D_ENGINE_LIVES_HERE), que o
motor do contexto do Company Brain (esquema de voz e conduta, validador, template e a especificação do construtor)
vive no repo do produto e que o core o vendoriza por TAG, com versão fixada. Vendor sem carimbo é cópia solta: não
se sabe de que tag veio nem se alguém o editou à mão. Este script é o carimbo e a conferência.

POR QUE NÃO O kg_vendor.py (o molde da kg-ssot): ele é da kg-ssot e fixa o produto (carimbo `.kg-ssot-version`,
manifesto de release dentro da tag, perfis, atestação do GitHub). A tag do Company Brain não traz manifesto e o core
leva só um recorte do repo (INCLUDE abaixo). Daqui se reproduz o que é proporcional do molde: o carimbo com tag,
commit, sha256 e modo de cada arquivo; a conferência do vendor contra o carimbo; e a conferência do carimbo contra os blobs
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
import json
import os
import shutil
import subprocess
import sys

PRODUCT = "company-brain"
STAMP = ".company-brain-version"
DEFAULT_DEST = "vendor/company-brain"
# O recorte que o core leva (o motor): o resto do repo do produto (grafos, sessões, .claude/) fica lá.
INCLUDE = ["README.md", "builder", "spec", "templates", "tests", "tools"]
EXEC_MARK = "+x"  # sufixo do sha256 no carimbo quando o arquivo é executável (o modo também é conferido)


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
        for name in [d for d in dirs if os.path.islink(os.path.join(base, d))]:
            rel = os.path.relpath(os.path.join(base, name), dest).replace(os.sep, "/")
            out[rel] = "symlink"  # o os.walk não entra em link de diretório: sem isto ele passaria calado
        for name in sorted(files):
            full = os.path.join(base, name)
            rel = os.path.relpath(full, dest).replace(os.sep, "/")
            if rel == STAMP:
                continue
            if os.path.islink(full):
                out[rel] = "symlink"
                continue
            with open(full, "rb") as fh:
                digest = sha256(fh.read())
            out[rel] = digest + (EXEC_MARK if os.stat(full).st_mode & 0o111 else "")
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
    if not isinstance(stamp, dict):
        raise Unjudgeable("carimbo não é um objeto JSON")
    for field in ("product", "tag", "commit", "version"):
        if not isinstance(stamp.get(field), str) or not stamp[field]:
            raise Unjudgeable(f"carimbo sem o campo texto {field!r}")
    if stamp["product"] != PRODUCT:
        raise Unjudgeable(f"carimbo de outro produto: {stamp['product']!r}")
    if not isinstance(stamp.get("include"), list) or not all(isinstance(x, str) for x in stamp["include"]):
        raise Unjudgeable("carimbo com 'include' que não é lista de textos")
    files = stamp.get("files")
    if not isinstance(files, dict) or not files or not all(isinstance(k, str) and isinstance(v, str) for k, v in files.items()):
        raise Unjudgeable("carimbo sem 'files' como mapa de caminho para sha256")
    return stamp


def tag_files(source, tag):
    """(commit, {caminho: sha256[+x]}, {caminho: bytes}) do recorte INCLUDE na tag, lido dos BLOBS do clone
    (ls-tree + cat-file), não do git archive: o archive aplica export-ignore/export-subst e mentiria igual dos dois lados."""
    commit = git(source, "rev-parse", "--verify", f"{tag}^{{commit}}").decode().strip()
    listing = git(source, "ls-tree", "-r", "-z", "--full-tree", commit, "--", *INCLUDE).decode("utf-8", "replace")
    files, blobs, seen_top = {}, {}, set()
    for entry in filter(None, listing.split("\0")):
        meta, path = entry.split("\t", 1)
        mode, kind, obj = meta.split()
        seen_top.add(path.split("/", 1)[0])
        if kind != "blob" or mode == "120000":
            files[path] = "symlink"
            continue
        data = git(source, "cat-file", "blob", obj)
        blobs[path] = data
        files[path] = sha256(data) + (EXEC_MARK if mode == "100755" else "")
    missing = [x for x in INCLUDE if x not in seen_top]
    if missing:
        raise Unjudgeable(f"a tag {tag} não traz {missing} do recorte")
    return commit, files, blobs


def diff(want, got):
    """Achados entre o esperado e o achado, um por linha: CODIGO<TAB>caminho<TAB>texto."""
    lines = []
    for path in sorted(set(want) | set(got)):
        if path not in got:
            lines.append(f"CBV-MISSING\t{path}\tno carimbo, ausente")
        elif path not in want:
            lines.append(f"CBV-EXTRA\t{path}\tfora do carimbo")
        elif want[path] != got[path]:
            lines.append(f"CBV-SHA256\t{path}\tsha256 ou modo diverge do carimbo")
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
    dest = os.path.realpath(args.dest)
    source = os.path.realpath(args.source)
    if dest == source or source.startswith(dest + os.sep) or dest.startswith(source + os.sep + ".git"):
        raise Unjudgeable("o destino é a fonte, contém a fonte ou fica no .git dela: recuso apagar")
    if os.path.lexists(args.dest):
        if not os.path.isdir(args.dest) or os.path.islink(args.dest):
            raise Unjudgeable(f"{args.dest} existe e não é pasta: recuso apagar")
        if os.listdir(args.dest):
            if os.path.exists(os.path.join(args.dest, ".git")):
                raise Unjudgeable(f"{args.dest} tem .git: recuso apagar")
            read_stamp(args.dest)  # só substitui pasta que já é um vendor deste produto (sem carimbo: rc 2, nada apagado)
    commit, files, blobs = tag_files(args.source, args.tag)
    if any(v == "symlink" for v in files.values()):
        raise Unjudgeable("a tag traz link simbólico ou submódulo no recorte: o vendor não leva isso")
    version = args.tag.rsplit("-v", 1)[-1] if "-v" in args.tag else args.tag
    if os.path.isdir(args.dest):
        shutil.rmtree(args.dest)
    os.makedirs(args.dest)
    for path, data in blobs.items():
        target = os.path.realpath(os.path.join(args.dest, path))
        if not target.startswith(dest + os.sep):
            raise Unjudgeable(f"caminho fora do destino na tag: {path!r}")
        os.makedirs(os.path.dirname(target), exist_ok=True)
        with open(target, "wb") as fh:
            fh.write(data)
        os.chmod(target, 0o755 if files[path].endswith(EXEC_MARK) else 0o644)
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
    except Exception as exc:  # qualquer outra quebra também é «não julgou», nunca rc 1 nem verde
        print(f"company-brain-vendor: não deu para julgar ({type(exc).__name__}): {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main())
