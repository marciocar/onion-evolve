#!/usr/bin/env python3
"""O corpo da release no GitHub, montado da seção da versão nos dois CHANGELOGs (release 4.17.1).

Antes, o corpo era a mensagem da tag anotada. Agora sai do CHANGELOG.md (inglês, a fonte) e do CHANGELOG.pt-BR.md (a
tradução), no esqueleto que os projetos de referência sustentam (pesquisa de publicação de 2026-10-21): o resumo e os
links na abertura, o que mudou (as seções do Keep a Changelog, na ordem do arquivo), a instalação por canal com a
versão fixada, a atualização, a verificação de proveniência por comando e o link da comparação; o pt-BR fica num bloco
recolhível no fim. Não inventa texto: o que não está no CHANGELOG não entra.

Uso:
  kg_release_notes.py [--version X.Y.Z] [--root DIR] [--ref REV]   imprime o corpo da release (default: a versão de
                                                                    spec/release.json; os links na tag dela)
  kg_release_notes.py --check [--version X.Y.Z]           rc 1 se a versão não tem seção nos dois CHANGELOGs
rc: 0 · 1 sem a seção (--check) · 2 entrada quebrada.
"""
import argparse
import json
import pathlib
import re
import sys

if __package__:  # no pacote kg_ssot, o vizinho vem pelo pacote, sem mexer no sys.path de quem importa
    from . import kg_i18n
else:  # script ou vendor
    sys.dont_write_bytecode = True  # sem .pyc do kg_i18n no vendor
    sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
    import kg_i18n  # noqa: E402
_ = kg_i18n._

ROOT = pathlib.Path(__file__).resolve().parents[1]
MIRROR = "https://github.com/marciocar/kg-ssot"
REGISTRY_NAME = "io.github.marciocar/kg-ssot"
IMAGE = "ghcr.io/marciocar/kg-ssot"
HEADING = re.compile(r"^## \[(?P<v>[^\]]+)\](?: - (?P<date>\d{4}-\d{2}-\d{2}))?\s*$")
CONTRACT = re.compile(r"[Cc]ontra(?:ct|to) (v4\.\d+)")


class Broken(Exception):
    """Entrada quebrada: rc 2 (rc 1 no --check quando missing_section: falta a seção da versão)."""

    def __init__(self, message, missing_section=False):
        super().__init__(message)
        self.missing_section = missing_section


def section(text, version):
    """(data, corpo) da seção ## [version] de um CHANGELOG, sem o cabeçalho; None se não há. O corpo vai até a próxima
    seção ## ou até as definições de link do fim."""
    lines = text.splitlines()
    for i, line in enumerate(lines):
        m = HEADING.match(line)
        if m and m.group("v") == version:
            body = []
            for nxt in lines[i + 1:]:
                if nxt.startswith("## ") or re.match(r"^\[[^\]]+\]: https?://", nxt):
                    break
                body.append(nxt)
            return m.group("date"), "\n".join(body).strip()
    return None


def split_summary(body):
    """(resumo, resto): o primeiro parágrafo antes da primeira ### é o resumo da versão."""
    head, sep, rest = body.partition("\n### ")
    return head.strip(), (sep.strip() + " " + rest).strip() if sep else ""


def notes(version, root=ROOT, ref=None):
    """O corpo da release em Markdown. Broken quando falta a seção da versão num dos dois CHANGELOGs. ref: a revisão dos
    links para os arquivos do espelho (default: a tag da versão; main para reescrever uma release anterior aos CHANGELOGs)."""
    texts = {}
    for name in ("CHANGELOG.md", "CHANGELOG.pt-BR.md"):
        path = pathlib.Path(root) / name
        try:
            texts[name] = path.read_text(encoding="utf-8")
        except OSError as exc:
            raise Broken(f"{name}: {exc}") from None
    en, pt = section(texts["CHANGELOG.md"], version), section(texts["CHANGELOG.pt-BR.md"], version)
    if en is None or pt is None:
        missing = [n for n, s in (("CHANGELOG.md", en), ("CHANGELOG.pt-BR.md", pt)) if s is None]
        raise Broken(_("version {version} has no section in {files}").format(version=version, files=", ".join(missing)),
                     missing_section=True)
    date, en_body = en
    pt_body = pt[1]
    en_summary, en_changes = split_summary(en_body)
    pt_summary, pt_changes = split_summary(pt_body)
    contract = CONTRACT.search(en_summary)
    tag = f"kg-ssot-v{version}"
    ref = ref or tag
    previous = re.search(rf"^\[{re.escape(version)}\]: (\S+)$", texts["CHANGELOG.md"], re.M)
    head = f"**KG-SSOT {version}**" + (f" · contract {contract.group(1)}" if contract else "") + (f" · {date}" if date else "")
    out = [head, "", en_summary, "",
           f"[Manual]({MIRROR}/tree/main/docs/manual) · [Adopting guide]({MIRROR}/blob/{ref}/ADOPTING.md) · "
           f"[Changelog]({MIRROR}/blob/{ref}/CHANGELOG.md) · [Português (Brasil)](#português-brasil)", ""]
    if en_changes:
        out += ["## What changed", "", en_changes.replace("\n### ", "\n#### ").replace("### ", "#### ", 1), ""]
    out += ["## Install", "",
            "| Channel | Command |", "|---|---|",
            f"| PyPI | `pip install kg-ssot=={version}` |",
            f"| npm | `npm install kg-ssot@{version}` |",
            f"| Container (GHCR) | `docker pull {IMAGE}:{version}` |",
            f"| Claude Desktop (MCPB) | download `kg-ssot-{version}.mcpb` from the assets below |",
            f"| MCP Registry | `{REGISTRY_NAME}` |",
            f"| Vendor into a repository | `python3 -I -B vendor/kg-ssot/tools/kg_vendor.py update --tag {tag} --source {MIRROR}` |",
            "",
            f"Upgrading from an earlier tag: read the notes for each version in [ADOPTING.md]({MIRROR}/blob/{ref}/ADOPTING.md)"
            " (Portuguese for now).", "",
            "## Verify", "",
            "Every artifact is built and attested by this repository's release workflow:", "",
            "```bash",
            f"gh attestation verify kg-ssot-{version}.mcpb --repo marciocar/kg-ssot",
            f"gh attestation verify oci://{IMAGE}:{version} --repo marciocar/kg-ssot",
            "npm audit signatures   # in a project that installed kg-ssot from npm",
            "```", ""]
    if previous:
        out += [f"**Full changelog:** {previous.group(1)}", ""]
    out += ["## Português (Brasil)", "", "<details>", "<summary>Notas desta versão em português</summary>", "",
            pt_summary, ""]
    if pt_changes:
        out += [pt_changes.replace("\n### ", "\n#### ").replace("### ", "#### ", 1), ""]
    out += ["Instalação, atualização e verificação: os mesmos comandos acima. "
            f"[CHANGELOG em português]({MIRROR}/blob/{ref}/CHANGELOG.pt-BR.md).", "", "</details>", ""]
    return "\n".join(out)


def current_version(root=ROOT):
    try:
        return json.loads((pathlib.Path(root) / "spec/release.json").read_text(encoding="utf-8"))["version"]
    except (OSError, ValueError, KeyError) as exc:
        raise Broken(f"spec/release.json: {exc}") from None


def main(argv=None):
    ap = argparse.ArgumentParser(description=_("Builds the GitHub release body from the version's section in both "
                                                 "CHANGELOGs."))
    ap.add_argument("--version", help=_("X.Y.Z (default: the version in spec/release.json)"))
    ap.add_argument("--root", default=str(ROOT), help=_("the root with the CHANGELOGs and spec/ (default: this kit's root)"))
    ap.add_argument("--check", action="store_true", help=_("only check that the version has a section in both CHANGELOGs"))
    ap.add_argument("--ref", help=_("the revision for the mirror links (default: the version's tag)"))
    args = ap.parse_args(argv)
    try:
        version = args.version or current_version(args.root)
        text = notes(version, args.root, args.ref)
    except Broken as exc:
        print(f"{'✗' if args.check else _('BROKEN INPUT')}  {exc}", file=sys.stderr)
        return 1 if args.check and exc.missing_section else 2
    if args.check:
        print(_("✓ {version}: section in both CHANGELOGs").format(version=version))
        return 0
    print(text)
    return 0


if __name__ == "__main__":
    sys.exit(main())
