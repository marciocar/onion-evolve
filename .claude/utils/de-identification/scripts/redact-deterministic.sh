#!/usr/bin/env bash
# =============================================================================
# redact-deterministic.sh — baseline determinístico da abstração de-identification
#
# Propósito : Redigir PII de FORMATO FIXO (e-mail, CPF, CNPJ, telefone BR, cartão,
#             IPv4) por regex — sem LLM, sem rede. É o adapter `regex` da abstração
#             SDAAL de-identification: o "segundo runtime" determinístico. PII
#             CONTEXTUAL (nomes, endereços, juízo de jurisdição) é trabalho do
#             adapter `local-slm` (gated, roda no alvo). Ver ../adapters/regex.md.
#
# Uso       : redact-deterministic.sh --redact  --map <arquivo>   < entrada > saida
#             redact-deterministic.sh --restore --map <arquivo>   < entrada > original
#               --redact  : redige stdin → stdout; grava placeholder<TAB>original no --map
#               --restore : reconstrói o original de stdin usando o --map (round-trip)
#
# Garantias : DETERMINÍSTICO (mesma entrada → mesma saída; placeholders numerados por
#             ordem de aparição; valor repetido → MESMO placeholder). Texto sem PII →
#             no-op idempotente. Coberto por lint-selftest.sh (run_de_identification_selftests).
#
# Dependência: python3 (regex + escaping seguros). Ausente → exit 3 (gracioso no selftest).
# =============================================================================
set -uo pipefail

MODE=""
MAPFILE=""
while [ $# -gt 0 ]; do
  case "$1" in
    --redact)  MODE="redact"; shift ;;
    --restore) MODE="restore"; shift ;;
    --map)     MAPFILE="${2:-}"; shift 2 ;;
    *) echo "uso: redact-deterministic.sh --redact|--restore --map <arquivo>" >&2; exit 2 ;;
  esac
done

if [ -z "${MODE}" ] || [ -z "${MAPFILE}" ]; then
  echo "uso: redact-deterministic.sh --redact|--restore --map <arquivo>" >&2
  exit 2
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 ausente — baseline determinístico requer python3" >&2
  exit 3
fi

# Entrada via arquivo temporário (preserva bytes exatos; o heredoc é o PROGRAMA do
# python, não a entrada — por isso a entrada não pode vir por stdin do python).
INFILE="$(mktemp)"
trap 'rm -f "${INFILE}"' EXIT
cat > "${INFILE}"

MODE="${MODE}" MAPFILE="${MAPFILE}" INFILE="${INFILE}" python3 <<'PY'
import os, re, sys

mode = os.environ["MODE"]
mapfile = os.environ["MAPFILE"]
with open(os.environ["INFILE"], encoding="utf-8") as f:
    text = f.read()

# Ordem importa: alternativas mais específicas primeiro (re escolhe a 1ª que casa
# na posição). E-mail antes de tudo; CNPJ antes de CPF; cartão antes de telefone.
PATTERNS = [
    ("EMAIL",  r"[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}"),
    ("CNPJ",   r"\d{2}\.\d{3}\.\d{3}/\d{4}-\d{2}"),
    ("CPF",    r"\d{3}\.\d{3}\.\d{3}-\d{2}"),
    ("CARD",   r"\d{4}[ -]\d{4}[ -]\d{4}[ -]\d{4}"),
    ("IPV4",   r"\b(?:\d{1,3}\.){3}\d{1,3}\b"),
    ("PHONE",  r"\(?\d{2}\)?[ -]?9?\d{4}-\d{4}"),
]
COMBINED = re.compile("|".join(f"(?P<{name}>{pat})" for name, pat in PATTERNS))

if mode == "redact":
    counters = {}          # TYPE -> próximo índice
    value_to_ph = {}       # valor original -> placeholder (dedupe estável)
    pairs = []             # (placeholder, original) na ordem de criação

    def repl(m):
        value = m.group(0)
        if value in value_to_ph:
            return value_to_ph[value]
        kind = m.lastgroup
        counters[kind] = counters.get(kind, 0) + 1
        ph = f"[[{kind}_{counters[kind]}]]"
        value_to_ph[value] = ph
        pairs.append((ph, value))
        return ph

    redacted = COMBINED.sub(repl, text)
    sys.stdout.write(redacted)
    with open(mapfile, "w", encoding="utf-8") as f:
        for ph, value in pairs:
            # TAB-separado; valores de PII de formato fixo não contêm TAB nem newline
            f.write(f"{ph}\t{value}\n")

elif mode == "restore":
    restored = text
    try:
        with open(mapfile, encoding="utf-8") as f:
            lines = f.read().splitlines()
    except FileNotFoundError:
        sys.stderr.write(f"map não encontrado: {mapfile}\n")
        sys.exit(2)
    # Restaura na ordem inversa de criação (placeholders são tokens únicos; ordem
    # não afeta correção, mas mantém estável).
    for line in reversed(lines):
        if "\t" not in line:
            continue
        ph, value = line.split("\t", 1)
        restored = restored.replace(ph, value)
    sys.stdout.write(restored)
PY
