#!/usr/bin/env python3
"""Roda o lote r2 (braço stub) da rodada 2 dos spikes das portas, família por família.

Montado do §5 e do §11 do PRE-REGISTRO-R2.md (a rodada 1 não tinha roteiro de lote em arquivo; isto
está declarado no pré-registro). Ficam de fora as duas células do subagente no Vibe (R2b-S1-V e
R2b-M-V), que esperam a reconferência da Emenda R2-8 (decisão
D_PORT_SPIKES_R2_RODAR_APROVADO_E_PESQUISAR_VIBE_1104).

Regra do §5: cada família roda até ter 3 células válidas (veredito em aggregate.VALID), com no
máximo 6 tentativas. As famílias rodam no máximo 2 em paralelo (outra bancada roda na máquina);
dentro da família, as tentativas são seriais.

Uso: run_batch_r2.py [--batch r2] [--jobs 2] [--only FAMID,...]
"""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
from aggregate import VALID  # noqa: E402

NEED, MAX_ATTEMPTS = 3, 6

# (família, cliente, cenário, hook-mode, SPIKE_PERM)
FAMILIES = [
    # §5a MCP
    ("R2a-S0-Q", "qwen", "mcp", "log_allow", "none"),
    ("R2a-S1-Q", "qwen", "mcp", "deny_target_exit2", "none"),
    ("R2a-M-Q", "qwen", "mcp", "matcher_bash", "none"),
    ("R2a-S0-V", "vibe", "mcp", "log_allow", "none"),
    ("R2a-S1-V", "vibe", "mcp", "deny_target_json", "none"),
    ("R2a-M-V", "vibe", "mcp", "matcher_bash", "none"),
    # §5b subagente (R2b-S1-V e R2b-M-V ficam de fora)
    ("R2b-S0-Q", "qwen", "sub", "log_allow", "none"),
    ("R2b-S1-Q", "qwen", "sub", "deny_target_exit2", "none"),
    ("R2b-M-Q", "qwen", "sub", "matcher_bash", "none"),
    ("R2b-S0-V", "vibe", "sub", "log_allow", "none"),
    # §5c contornos
    ("R2c-tc-S0-Q", "qwen", "tc", "log_allow", "none"),
    ("R2c-tc-S1-Q", "qwen", "tc", "deny_target_exit2", "none"),
    ("R2c-tcd-S0-Q", "qwen", "tcd", "log_allow", "none"),
    ("R2c-tcd-S1-Q", "qwen", "tcd", "deny_target_exit2", "none"),
    ("R2c-tcd-M-Q", "qwen", "tcd", "matcher_bash", "none"),
    ("R2c-ts-S0-V", "vibe", "ts", "log_allow", "none"),
    ("R2c-ts-S1-V", "vibe", "ts", "deny_target_json", "none"),
    ("R2c-ts-M-V", "vibe", "ts", "matcher_bash", "none"),
    ("R2c-proc-S0-V", "vibe", "proc", "log_allow", "none"),
    ("R2c-proc-S1-V", "vibe", "proc", "deny_target_json", "none"),
    ("R2c-proc-M-V", "vibe", "proc", "matcher_bash", "none"),
    # §5d permissões (cenário pc)
    ("R2d-S0-Q", "qwen", "pc", "log_allow", "none"),
    ("R2d-deny-Q", "qwen", "pc", "log_allow", "deny"),
    ("R2d-denytool-Q", "qwen", "pc", "log_allow", "deny_tool"),
    ("R2d-deny+veto-Q", "qwen", "pc", "deny_target_exit2", "deny"),
    ("R2d-allow+veto-Q", "qwen", "pc", "deny_target_exit2", "allow"),
    ("R2d-S0-V", "vibe", "pc", "log_allow", "none"),
    ("R2d-never-V", "vibe", "pc", "log_allow", "deny_never"),
    ("R2d-disabled-V", "vibe", "pc", "log_allow", "deny"),
    ("R2d-disabled-nohook-V", "vibe", "pc", "none", "deny"),
    ("R2d-disabled+veto-V", "vibe", "pc", "deny_target_json", "deny"),
    ("R2d-allow+veto-V", "vibe", "pc", "deny_target_json", "allow"),
    # Emenda R2-1: as rotas que sobram
    ("R2d-deny-ts-V", "vibe", "ts", "log_allow", "deny"),
    ("R2d-deny-proc-V", "vibe", "proc", "log_allow", "deny"),
    ("R2d-denytool-tcd-Q", "qwen", "tcd", "log_allow", "deny_tool"),
]


def cell_dir_name(fam: str, n: int) -> str:
    safe = fam.replace("+", "plus")
    return f"{safe}-r{n}"


def verdict_of(cell: str) -> str:
    p = HERE / "evidence" / cell / "verdict.json"
    try:
        return json.loads(p.read_text())["verdict"]
    except Exception:  # noqa: BLE001
        return "MISSING"


def run_family(row, batch: str) -> dict:
    fam, harness, scenario, mode, perm = row
    valid, attempts, log = 0, 0, []
    while valid < NEED and attempts < MAX_ATTEMPTS:
        attempts += 1
        cell = cell_dir_name(fam, attempts)
        if not (HERE / "evidence" / cell).exists():
            env = dict(os.environ, SPIKE_BATCH=batch, SPIKE_PERM=perm)
            r = subprocess.run(["bash", str(HERE / "run_cell.sh"), harness, cell, scenario, mode],
                               env=env, capture_output=True, text=True, timeout=1500)
            if r.returncode != 0:
                log.append(f"{cell}: run_cell rc={r.returncode} {r.stderr.strip()[-200:]}")
        v = verdict_of(cell)
        log.append(f"{cell}: {v}")
        if v in VALID:
            valid += 1
    return {"family": fam, "attempts": attempts, "valid": valid, "log": log}


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--batch", default="r2")
    ap.add_argument("--jobs", type=int, default=2)
    ap.add_argument("--only", default="")
    a = ap.parse_args()
    rows = [r for r in FAMILIES if not a.only or r[0] in set(a.only.split(","))]
    with ThreadPoolExecutor(max_workers=max(1, min(a.jobs, 2))) as ex:
        for res in ex.map(lambda r: run_family(r, a.batch), rows):
            print(json.dumps(res, ensure_ascii=False), flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
