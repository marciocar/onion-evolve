#!/usr/bin/env bash
# dissect-object-check.sh — invoca o checador de forma da dissecação de qualquer objeto (família, Etapa 0, veredito,
# destino). A lógica mora em dissect-object-check.py; este arquivo só fixa a raiz do repo e o python isolado (-I).
#   bash .claude/validation/dissect-object-check.sh <grafo> [--stage plan|final] [--allow-uncommitted]
#        [--expect-verdict V] [--max-level N]                                         rc 0 · 1 achado · 3 não mediu
#   bash .claude/validation/dissect-object-check.sh --context                         projeção para a sessão (peça 3)
# Registro das famílias: .claude/validation/dissect-families.kg.yaml · bancada: run_dissect_object_selftests
# (lint-selftest.sh), que roda .claude/validation/dissect-object-bench.py.
# O .py é o VIZINHO deste arquivo, não o da raiz do repo: chamado de outro repo (o core medindo o estudo de um
# adotante), a raiz sem o .py dava rc 2 do python, fora do contrato 0/1/3 (medido no dogfood de 2026-10-24).
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PY="${HERE}/dissect-object-check.py"
[ -f "${PY}" ] || { echo "dissect-object-check: ${PY} ausente (rc 3)" >&2; exit 3; }
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "dissect-object-check: fora de um repo git (rc 3)" >&2; exit 3; }
cd "${ROOT}" || exit 3
command -v python3 >/dev/null 2>&1 || { echo "dissect-object-check: python3 ausente (rc 3)" >&2; exit 3; }
exec python3 -I "${PY}" "$@"
