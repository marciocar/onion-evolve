#!/usr/bin/env python3
"""Compara dois classificadores célula a célula: a medida de que depende a isenção da regra do medidor.

Emenda R2-10 parte F. Vem do cmp275.py do kg-ssot. A isenção (PRE-REGISTRO-R2.md, Emenda R2-1, curadoria 12, e Emenda
R2-10 parte D) exige que a mudança no harness não altere o veredito de nenhuma célula. O reproduce.sh roda este
comparador contra harness/reference/classify_r2_lot.py, a cópia byte a byte do classificador que produziu o lote r2
(cbc067cc0), porque o reproduce tem de funcionar também num git archive, sem histórico.

Uso: cmp_classify.py <classify de referência> <classify novo> <evidence-dir> [--manifest M --skip-lots a,b]

--manifest e --skip-lots tiram as células de lotes que a referência não sabe julgar (coletadas depois dela).
rc 1 se veredito, base ou findings diferirem em alguma célula. Diferença só no resto do dicionário é informativa.
"""

from __future__ import annotations

import argparse
import importlib.util
import json
import sys
from collections import Counter
from pathlib import Path


def load(path: str, name: str):
    spec = importlib.util.spec_from_file_location(name, path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("reference")
    ap.add_argument("new")
    ap.add_argument("evidence")
    ap.add_argument("--manifest")
    ap.add_argument("--skip-lots", default="")
    a = ap.parse_args()
    old, new = load(a.reference, "classify_reference"), load(a.new, "classify_new")
    skip: set[str] = set()
    if a.manifest and a.skip_lots:
        lots = set(a.skip_lots.split(","))
        for line in Path(a.manifest).read_text().splitlines()[1:]:
            parts = line.split("\t")
            if parts[1] in lots:
                skip.add(parts[0])
    cells = sorted(d for d in Path(a.evidence).iterdir()
                   if d.is_dir() and not d.name.startswith("_") and d.name not in skip)
    diffs = full = 0
    verdicts: Counter = Counter()
    for d in cells:
        x, y = old.classify(d), new.classify(d)
        verdicts[y["verdict"]] += 1
        if (x["verdict"], x["basis"], x.get("findings")) != (y["verdict"], y["basis"], y.get("findings")):
            diffs += 1
            print(f"DIFF {d.name}: {x['verdict']} | {str(x['basis'])[:70]} => {y['verdict']} | {str(y['basis'])[:70]}")
        if json.dumps(x, sort_keys=True, default=str) != json.dumps(y, sort_keys=True, default=str):
            full += 1
            print(f"info {d.name}: dict differs in {sorted(k for k in set(x) | set(y) if x.get(k) != y.get(k))}")
    print(f"{'ok  ' if not diffs and cells else 'FAIL'} cmp_classify: {len(cells)} cells, {diffs} verdict diffs, "
          f"{full} full-dict diffs, skipped {len(skip)}; {dict(verdicts)}")
    return 1 if diffs or not cells else 0


if __name__ == "__main__":
    sys.exit(main())
