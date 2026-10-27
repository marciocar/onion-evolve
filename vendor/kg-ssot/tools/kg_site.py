#!/usr/bin/env python3
"""A fonte do site de documentação, montada da superfície da release, para o Zensical construir (4.31.0).

  kg_site.py --out site-src        monta site-src/ a partir da raiz (o README vira index.md)

O site é uma PROJEÇÃO: as páginas são o README, o ADOPTING, o CHANGELOG e o manual (docs/manual, nas duas línguas),
copiados sem edição de texto. Mudam só duas coisas. O bloco HTML do cabeçalho do README ganha markdown="1", para o
Python-Markdown renderizar o que está dentro dele, como o GitHub renderiza. E os links: o link para outra página do
site fica relativo, e o link para um arquivo que não entra no site (spec/, tools/, LICENSE, o README em pt-BR) vira
link para o arquivo no repositório público, para nenhum link do site cair em 404. O workflow de release do espelho roda este script e o Zensical
(zensical.toml na raiz) e publica no GitHub Pages.

rc: 0 ok · 2 entrada quebrada (página ausente).
"""
import argparse
import pathlib
import re
import shutil
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
REPO = "https://github.com/marciocar/kg-ssot/blob/main/"
PAGES = ["README.md", "ADOPTING.md", "CHANGELOG.md"]
MANUAL = "docs/manual"
# os arquivos que as páginas mostram (a demonstração gravada do README) vão junto, no mesmo caminho
ASSETS = ["docs/demo/kg-ssot-demo.gif"]
# [texto](alvo) e [texto](alvo#âncora); o alvo não tem espaço nem fecha-parêntese
LINK = re.compile(r"(\]\()([^)\s#]+)((?:#[^)\s]*)?\))")


def page_name(rel):
    """O README da raiz é a página inicial do site."""
    return "index.md" if rel == "README.md" else rel


def rewrite(text, rel, kept):
    """Reescreve os links relativos de uma página que está em `rel` (caminho a partir da raiz)."""
    here = pathlib.PurePosixPath(rel).parent

    def fix(m):
        target = m.group(2)
        if re.match(r"[a-z][a-z0-9+.-]*:", target) or target.startswith("/"):
            return m.group(0)  # URL absoluta, mailto: ou caminho absoluto do site: fica como está
        parts = []
        for part in (here / target).parts:
            if part == "..":
                if not parts:
                    return m.group(0)  # sai da raiz: não é arquivo da release, fica como está
                parts.pop()
            elif part != ".":
                parts.append(part)
        resolved = "/".join(parts)
        if resolved in kept:
            up = [".."] * len(pathlib.PurePosixPath(page_name(rel)).parent.parts)
            return m.group(1) + "/".join([*up, page_name(resolved)]) + m.group(3)
        return m.group(1) + REPO + resolved + m.group(3)

    # o GitHub renderiza markdown dentro de um <div> com linha em branco; o Python-Markdown só com markdown="1"
    text = re.sub(r'<div(?![^>]*\bmarkdown=)([^>]*)>', r'<div\1 markdown="1">', text)
    return LINK.sub(fix, text)


def build(root, out):
    """Monta out/ a partir de root. Devolve o número de páginas."""
    root, out = pathlib.Path(root), pathlib.Path(out)
    files = [p for p in PAGES] + sorted(p.relative_to(root).as_posix() for p in (root / MANUAL).rglob("*.md"))
    missing = [f for f in files + ASSETS if not (root / f).is_file()]
    if missing:
        raise FileNotFoundError(", ".join(missing))
    kept = set(files) | set(ASSETS)
    if out.exists():
        shutil.rmtree(out)
    for rel in ASSETS:
        (out / rel).parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(root / rel, out / rel)
    for rel in files:
        dest = out / page_name(rel)
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_text(rewrite((root / rel).read_text(encoding="utf-8"), rel, kept), encoding="utf-8")
    return len(files)


def main(argv=None):
    ap = argparse.ArgumentParser(description="Assemble the documentation site source from the release surface.")
    ap.add_argument("--root", default=str(ROOT), help="the release root (default: this repository)")
    ap.add_argument("--out", required=True, help="the output folder, replaced on each run")
    a = ap.parse_args(argv)
    try:
        n = build(a.root, a.out)
    except FileNotFoundError as exc:
        print(f"BROKEN INPUT  missing page: {exc}", file=sys.stderr)
        return 2
    print(f"{n} pages in {a.out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
