"""kgssot_tools.py — espelho python do resolver da pasta das ferramentas do KG-SSOT (kgssot-tools.sh, ao lado).

A doutrina, a ordem e o porquê estão no cabeçalho do kgssot-tools.sh; aqui só a mesma ordem:
  1. KG_SSOT_TOOLS, se definida e for pasta existente (override explícito);
  2. <raiz>/vendor/kg-ssot/tools (core e adotantes);
  3. <raiz>/tools, só quando <raiz>/spec/release.json declara tag kg-ssot-v* (a raiz É o produto).
Nada casou: None, e o chamador segue no caminho e no rc de hoje.

Uso:  sys.path.insert(0, <.claude/utils/kg>); import kgssot_tools; kgssot_tools.resolve(root) -> (dir|None, kind)
Linha de comando (a bancada mede a paridade com o bash):  python3 -I -B kgssot_tools.py <raiz>
  imprime "<kind>\t<dir>" e sai 0, ou sai 1 sem imprimir.
"""
import os
import re
import sys

_TAG = re.compile(r'"tag"\s*:\s*"kg-ssot-v[0-9]')


def _is_source_root(root):
    try:
        with open(os.path.join(root, "spec", "release.json"), encoding="utf-8", errors="replace") as fh:
            return bool(_TAG.search(fh.read()))
    except OSError:
        return False


def resolve(root="."):
    """(pasta, kind) com kind em env|vendor|source, ou (None, None)."""
    env = os.environ.get("KG_SSOT_TOOLS", "")
    if env and os.path.isdir(env):
        return env.rstrip("/") or "/", "env"
    vendor = os.path.join(root, "vendor", "kg-ssot", "tools")
    if os.path.isdir(vendor):
        return vendor, "vendor"
    tools = os.path.join(root, "tools")
    if os.path.isdir(tools) and _is_source_root(root):
        return tools, "source"
    return None, None


def tool(root, name):
    """o caminho de uma ferramenta: na pasta resolvida, ou no caminho de hoje (vendor) quando nada casou —
    e aí o chamador mede a ausência como sempre mediu (rc 3 / "não medi"), com a mesma mensagem."""
    d, _ = resolve(root)
    return os.path.normpath(os.path.join(d or os.path.join(root, "vendor", "kg-ssot", "tools"), name))


if __name__ == "__main__":
    d, kind = resolve(sys.argv[1] if len(sys.argv) > 1 else ".")
    if not d:
        sys.exit(1)
    print("%s\t%s" % (kind, d))
