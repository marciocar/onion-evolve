"""Entrada do MCPB kg-ssot: roda o servidor MCP de referência do pacote kg-ssot (kg_ssot.kg_mcp) por stdio.

O host do MCPB (Claude Desktop ou outro) instala o pacote kg-ssot pelo uv, a partir do pyproject.toml ao lado, e
chama este arquivo com os valores que o usuário escolheu: --root (o diretório do armazém) e --read-only (true ou
false). O armazém é criado na primeira vez e só grava o que passa no contrato.

O backend é o versionado: cada gravação e cada remoção ficam registradas, e o kg_history as mostra. Uma raiz dentro
de um repositório git (quem versiona a pasta pessoal, por exemplo) não aceita o versionado; ali o armazém usa o git,
com um commit por gravação, num repositório aninhado. Sem git na máquina, o repositório de fora não é visto, e o
armazém é o versionado. Quando a raiz não abre (um arquivo, uma pasta sem permissão), o servidor sobe sem armazém,
só com kg_validate e kg_schema_help, e diz o motivo no stderr, que o host guarda no log.
"""
import argparse
import shutil
import sys

from kg_ssot import kg_mcp, kg_store


def backend_for(root):
    """O backend do armazém em root: versioned, git (raiz dentro de um repo git) ou None (sem armazém)."""
    try:
        kg_store.open_store("versioned", root, init=True)
        return "versioned"
    except kg_store.StoreError as exc:
        if "repo git" in str(exc) and shutil.which("git"):
            return "git"
        print(f"kg-ssot: o armazém em {root} não abriu ({exc}); o servidor sobe só com kg_validate e kg_schema_help",
              file=sys.stderr)
        return None


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--root", required=True, help="o diretório do armazém de grafos")
    ap.add_argument("--read-only", default="false", help="true deixa o servidor sem kg_write nem kg_delete")
    a = ap.parse_args(argv)
    backend = backend_for(a.root)
    args = ["--root", a.root, "--init", "--backend", backend] if backend else []
    if a.read_only.strip().lower() in ("true", "1", "yes", "sim"):
        args.append("--read-only")
    return kg_mcp.main(args)


if __name__ == "__main__":
    sys.exit(main())
