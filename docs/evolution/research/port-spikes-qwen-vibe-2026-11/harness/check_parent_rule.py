#!/usr/bin/env python3
"""Confere a lista positiva do PAI (regra do filho, sub do Vibe) contra registros REAIS.

Emenda R2-10 parte D. A regra do filho inteira não fecha numa célula em log_allow, porque a condição
(d) pede o veto do hook. Este conferidor aplica às células de controle só as partes que dependem da
forma do registro do pai: o _parent_effects_ok no store e nos chunks, o pareamento do stdout por id e
estado (A6) e toolName (salvo no par com o filho), e os resultados de ferramenta do pai (N1: alvo, contagem, nome
na lista medida e nome sem repetição). É a prova de que a regra aceita o que o cliente grava de fato, e o
reproduce.sh a roda nas células do arquivo.

O QUE ELE NÃO COBRE, porque só existe numa célula com veto ou no veredito final: a (d) do hook, o efeito vetado e as
mensagens do filho, a (4) sobre o id do stub, as outras sessões e a conjunção do BARRA. Quem cobra isso é a
vibe_child_record e o test_classify.py. Passar aqui não prova BARRA: prova só que a forma do pai não o impede.

Uso: check_parent_rule.py [--classify-dir DIR] <célula>...
--classify-dir aplica o classificador de outra versão (para mostrar que a regra antiga reprova).
rc 0 se todas as células passam; 1 senão.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path


def check(classify, cell: Path) -> list[str]:
    ev = classify.load(cell)
    sessions = (ev.get("store_extract") or {}).get("sessions") or []
    child = [s for s in sessions if str(s.get("session_id")).startswith("child-")]
    parent = [s for s in sessions if not str(s.get("session_id")).startswith("child-")]
    if len(child) != 1 or len(parent) != 1:
        return [f"expected one child and one parent session, got {len(child)} and {len(parent)}"]
    child_sid = child[0]["session_id"]
    problems = []
    store = classify._effect_states(parent[0].get("projection"))
    chunks = classify._effect_states(list(ev.get("vibe_chunks") or []))
    seen = {}
    for where, effects in (("store", store), ("chunks", chunks)):
        ok, why, seen_here = classify._parent_effects_ok(effects, "sub", child_sid, where)
        if not ok:
            problems.append(why)
        if where == "store":
            seen = seen_here
    if seen.get("spawn") != 1:
        problems.append(f"store: expected one spawn, saw {seen}")
    known: dict = {}
    known_tools: dict = {}
    child_effects = classify._effect_states(child[0].get("projection"))
    for src in (chunks, store, child_effects):
        for key, (states, _last, forms) in src.items():
            known.setdefault(key, set()).update(states)
            if src is not child_effects:
                known_tools.setdefault(key, set()).update((f.get("detail") or {}).get("toolName") for f in forms)
    for key, (states, _last, forms) in classify._effect_states(list(ev["items"])).items():
        if key not in known or not states <= known[key]:
            problems.append(f"stdout effect {key} has no counterpart by id and status")
        elif key in known_tools and not {(f.get("detail") or {}).get("toolName") for f in forms} <= known_tools[key]:
            problems.append(f"stdout effect {key} has another toolName than its counterpart")
    results = 0
    names_seen: set = set()
    for item in parent[0].get("messages") or []:
        msg = item.get("message") if isinstance(item, dict) and isinstance(item.get("message"), dict) else item
        if isinstance(msg, dict) and msg.get("role") == "tool":
            results += 1
            if classify.target_in(msg, "sub"):
                problems.append("a parent tool result has the target")
            names = getattr(classify, "PARENT_TOOL_RESULTS", None)
            if names is not None and msg.get("name") not in names:
                problems.append(f"a parent tool result outside the script: {msg.get('name')!r}")
            if names is not None and msg.get("name") in names_seen:
                problems.append(f"a parent tool result repeats the name: {msg.get('name')!r}")
            names_seen.add(msg.get("name"))
    if results > sum(seen.values()):
        problems.append(f"{results} parent tool results for {sum(seen.values())} known steps")
    return problems


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--classify-dir", default=str(Path(__file__).resolve().parent))
    ap.add_argument("cells", nargs="+")
    a = ap.parse_args()
    sys.path.insert(0, a.classify_dir)
    import classify  # noqa: PLC0415

    rc = 0
    for cell in a.cells:
        problems = check(classify, Path(cell))
        rc |= 1 if problems else 0
        print(f"{'ok  ' if not problems else 'FAIL'} parent rule on {Path(cell).name}: {problems or 'store, chunks, stdout, results'}")
    return rc


if __name__ == "__main__":
    sys.exit(main())
