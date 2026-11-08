#!/usr/bin/env bash
# carga.sh — a exclusão por carga do .env da parte em papel (STAGE0.v6 §3, v7 §4, v8 limites 1 e 2).
#
# Uso: bash carga.sh <pasta do sample.py --dump>   → stdout: <chave>\tCASA|LIMPA, uma por item
#      bash carga.sh --selftest                     → confere CARGA.casos.txt (S casa, N não casa); rc 1 se errar
#
# Motor fixo: /usr/bin/grep por caminho absoluto (no shell do Claude Code `grep` é função que chama ugrep), -E, linha a
# linha, com o padrão lido de CARGA.regex por -f. O --version vai ao stderr e ao arquivo <pasta>/grep-version.txt.
# Não lê .env nenhum: só o texto dos candidatos.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
G=/usr/bin/grep
regex="$here/CARGA.regex"
[ -x "$G" ] || { echo "carga.sh: $G ausente" >&2; exit 2; }
[ -f "$regex" ] || { echo "carga.sh: $regex ausente" >&2; exit 2; }
"$G" --version | head -1 >&2

if [ "${1:-}" = "--selftest" ]; then
  bad=0; n=0
  while IFS= read -r line; do
    want="${line%%|*}"; text="${line#*|}"; n=$((n + 1))
    if printf '%s\n' "$text" | "$G" -E -q -f "$regex"; then got=S; else got=N; fi
    [ "$got" = "$want" ] || { echo "ERRO: esperado $want, deu $got: $text" >&2; bad=$((bad + 1)); }
  done < "$here/CARGA.casos.txt"
  echo "selftest: $((n - bad)) de $n certas"
  [ "$bad" -eq 0 ]
  exit
fi

dir="${1:?pasta do dump}"
"$G" --version | head -1 > "$dir/grep-version.txt"
while IFS=$'\t' read -r h key; do
  rc=0; "$G" -E -q -f "$regex" -- "$dir/$h.txt" || rc=$?
  case "$rc" in
    0) printf '%s\tCASA\n' "$key" ;;
    1) printf '%s\tLIMPA\n' "$key" ;;
    *) echo "carga.sh: grep rc=$rc em $h" >&2; exit 2 ;;
  esac
done < "$dir/keys.tsv"
