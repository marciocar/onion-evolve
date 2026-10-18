#!/usr/bin/env python3
"""Monta o MCPB kg-ssot (o servidor MCP de referência para Claude Desktop e outros hosts de MCP Bundle).

Uso: python3 -I packaging/mcpb/build.py --outdir DIR [--lock] | --stage-only DIR

O bundle é do tipo uv (manifest 0.4): leva o manifest.json, um pyproject.toml que depende do pacote kg-ssot na mesma
versão da release, a entrada server/main.py, o ícone, a LICENSE e o NOTICE. O host instala o kg-ssot pelo uv na
máquina do usuário, então as dependências nativas (o rpds-py) vêm certas para cada plataforma. A versão vem do
spec/release.json. A CLI do MCPB é a fixada em packaging/mcpb/package-lock.json (npm ci nessa pasta); o build roda
`mcpb validate` e `mcpb pack`.

Com --lock, o bundle leva um uv.lock gerado contra o PyPI real (uv lock), com o hash de cada arquivo de cada
dependência: a instalação no host fica travada. Só funciona depois de o kg-ssot da versão estar no PyPI; o build espera
até --lock-wait segundos pela página do pacote (o índice demora um pouco depois do upload).

rc: 0 ok · 1 a validação, o lock ou o pack falharam · 2 entrada quebrada.
"""
import argparse
import json
import pathlib
import shutil
import subprocess
import sys
import tempfile
import time

ROOT = pathlib.Path(__file__).resolve().parents[2]
HERE = pathlib.Path(__file__).resolve().parent
CLI = HERE / "node_modules" / "@anthropic-ai" / "mcpb" / "dist" / "cli" / "cli.js"  # pelo node: o .bin não roda no Windows


class Broken(Exception):
    pass


def version():
    try:
        v = json.loads((ROOT / "spec" / "release.json").read_text(encoding="utf-8"))["version"]
    except (OSError, ValueError, KeyError) as exc:
        raise Broken(f"spec/release.json sem version: {exc}") from exc
    return v


def stage(dest):
    v = version()
    dest.mkdir(parents=True, exist_ok=True)
    for tpl, out in (("manifest.json.in", "manifest.json"), ("pyproject.toml.in", "pyproject.toml")):
        (dest / out).write_text((HERE / tpl).read_text(encoding="utf-8").replace("@VERSION@", v), encoding="utf-8")
    json.loads((dest / "manifest.json").read_text(encoding="utf-8"))  # o modelo continua JSON depois da troca
    (dest / "server").mkdir()
    shutil.copy2(HERE / "server" / "main.py", dest / "server" / "main.py")
    shutil.copy2(HERE / "icon.png", dest / "icon.png")
    for name in ("LICENSE", "NOTICE"):
        shutil.copy2(ROOT / name, dest / name)
    return v


def freeze(dest):
    """Com o uv.lock no bundle, o host roda uv run --frozen: usa o lock como está e nunca o reescreve na pasta da
    extensão (um uv de outra versão poderia julgá-lo vencido e travar de novo, sem as hashes)."""
    path = dest / "manifest.json"
    m = json.loads(path.read_text(encoding="utf-8"))
    args = m["server"]["mcp_config"]["args"]
    if args[:1] != ["run"]:
        raise Broken("o mcp_config do bundle não começa com uv run")
    if "--frozen" not in args:
        args.insert(1, "--frozen")
    path.write_text(json.dumps(m, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def lock(dest, wait):
    """uv lock no bundle, contra o PyPI real; tenta de novo enquanto o kg-ssot da versão não aparece no índice."""
    deadline = time.monotonic() + wait
    while True:
        # --refresh-package: o índice do PyPI vem com cache de 600 s, e sem isto as novas tentativas releriam a página
        # sem a versão que acabou de sair
        p = subprocess.run(["uv", "lock", "--directory", str(dest), "--refresh-package", "kg-ssot"],
                           capture_output=True, text=True)
        if p.returncode == 0 and (dest / "uv.lock").is_file():
            freeze(dest)
            return True
        if time.monotonic() >= deadline:
            print(f"MCPB FALHOU  uv lock: {(p.stdout + p.stderr).strip()[-400:]}")
            return False
        time.sleep(20)


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--outdir", help="onde gravar o .mcpb; obrigatório sem --stage-only (fora da árvore)")
    ap.add_argument("--stage-only", metavar="DIR", help="só monta o bundle em DIR (vazio ou inexistente)")
    ap.add_argument("--lock", action="store_true", help="gera o uv.lock contra o PyPI real (o kg-ssot já publicado)")
    ap.add_argument("--lock-wait", type=int, default=600, help="segundos de espera pelo kg-ssot no PyPI (default 600)")
    a = ap.parse_args(argv)
    try:
        if a.stage_only:
            dest = pathlib.Path(a.stage_only)
            if dest.exists() and any(dest.iterdir()):
                raise Broken(f"{dest} não está vazio")
            print(f"bundle montado em {dest}: kg-ssot {stage(dest)}")
            return 0
        if not a.outdir:
            raise Broken("diga --outdir (fora da árvore do repo ou do vendor)")
        if not CLI.is_file():
            raise Broken(f"sem a CLI do MCPB em {CLI}: rode npm ci em packaging/mcpb")
        with tempfile.TemporaryDirectory(prefix="kg-ssot-mcpb-") as tmp:
            dest = pathlib.Path(tmp) / "kg-ssot"
            v = stage(dest)
            out = pathlib.Path(a.outdir).resolve()
            out.mkdir(parents=True, exist_ok=True)
            target = out / f"kg-ssot-{v}.mcpb"
            if a.lock and not lock(dest, a.lock_wait):
                return 1
            for cmd in (["node", str(CLI), "validate", str(dest / "manifest.json")], ["node", str(CLI), "pack", str(dest), str(target)]):
                p = subprocess.run(cmd, capture_output=True, text=True)
                if p.returncode:
                    print(f"MCPB FALHOU  {cmd[2]} rc {p.returncode}: {(p.stdout + p.stderr).strip()[-400:]}")
                    return 1
            print(f"kg-ssot {v}: {target}")
            return 0
    except (Broken, OSError, ValueError) as exc:
        print(f"ENTRADA QUEBRADA  {exc}")
        return 2


if __name__ == "__main__":
    sys.exit(main())
