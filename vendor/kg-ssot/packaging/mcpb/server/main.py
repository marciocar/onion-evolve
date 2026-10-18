"""Entrada do MCPB kg-ssot: roda o servidor MCP de referência do pacote kg-ssot (kg_ssot.kg_mcp) por stdio.

O host do MCPB (Claude Desktop ou outro) instala o pacote kg-ssot pelo uv, a partir do pyproject.toml ao lado, e
chama este arquivo com os valores que o usuário escolheu: --root (o diretório do armazém) e --read-only (true ou
false). O armazém é criado na primeira vez e só grava o que passa no contrato. Roda no macOS, no Linux e no Windows.

O backend é o versionado: cada gravação e cada remoção ficam registradas, e o kg_history as mostra. Uma raiz dentro
de um repositório git (quem versiona a pasta pessoal, por exemplo) não aceita o versionado; ali o armazém usa o git,
com um commit por gravação, num repositório aninhado. Sem git na máquina, o repositório de fora não é visto, e o
armazém é o versionado.

Quando a raiz não abre (um arquivo, uma pasta sem permissão, uma variável como ${DOCUMENTS} que o host não expandiu), o
servidor sobe sem armazém, só com kg_validate e kg_schema_help, e diz o motivo ao modelo (nas instruções, na descrição
das duas ferramentas e no kg_schema_help), para ele contar ao usuário; o stderr vai só para o log do host.
"""
import argparse
import shutil
import sys

from kg_ssot import kg_mcp, kg_store


def backend_for(root):
    """O backend do armazém em root: git se a raiz está dentro de um repo git e o git existe; senão versioned (se a
    raiz não abrir, o kg_mcp com --store-optional sobe sem armazém e diz o porquê)."""
    try:
        kg_store.open_store("versioned", root, init=True)
    except kg_store.StoreError as exc:
        if "repo git" in str(exc) and shutil.which("git"):
            return "git"
    except (OSError, ValueError, RuntimeError):  # o kg_mcp abre de novo e diz o motivo ao modelo
        pass
    return "versioned"


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--root", required=True, help="o diretório do armazém de grafos")
    ap.add_argument("--read-only", default="false", help="true deixa o servidor sem kg_write nem kg_delete")
    a = ap.parse_args(argv)
    read_only = a.read_only.strip().lower() in ("true", "1", "yes", "sim")
    if "${" in a.root:  # o host não expandiu a variável: um armazém ali nasceria dentro da pasta da extensão
        reason = (f"o host passou a raiz {a.root!r} com a variável sem expandir; escolha a pasta do armazém nas "
                  "configurações da extensão")
        print(f"kg-ssot: {reason}", file=sys.stderr)
        kg_mcp.serve_stdio(kg_mcp.Server(None, read_only=read_only, store_error=reason))
        return 0
    args = ["--root", a.root, "--init", "--backend", backend_for(a.root), "--store-optional"]
    if read_only:
        args.append("--read-only")
    return kg_mcp.main(args)


if __name__ == "__main__":
    sys.exit(main())
