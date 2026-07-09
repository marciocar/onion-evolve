#!/usr/bin/env bash
# =============================================================================
# compose-settings.sh — compõe um settings.json EFETIVO de N camadas de escopo.
#
# RFC-0005 (herança de escopo), PLANO 2 (configuração): o `settings.json` do Claude Code NÃO herda
# pela árvore de diretórios (é self-contained por diretório) — é o único gap de engenharia real. Este
# helper generaliza o merge 2-camadas do `merge-onion-hooks.sh` para N camadas de escopo:
#     framework → empresa → time → pessoa   (base → mais específico)
#
# Semântica de merge por-chave (never-clobber, type-aware — modelo strategic-merge):
#   - objetos  : recursam (merge profundo)
#   - arrays   : unem + dedup preservando ordem (hooks, permissions.allow/deny)
#   - escalares: last-wins (a camada mais específica sobrepõe — polimorfismo)
#
# Uso:
#   compose-settings.sh <layer1.json> <layer2.json> ... <layerN.json>   → settings.json composto (stdout)
#   compose-settings.sh --provenance <layer1> ... <layerN>              → qual camada contribuiu cada chave top-level
#
# Gracioso: sem jq → exit 3 (como merge-onion-hooks.sh — não corrompe). JSON inválido/ausente → exit 2.
# Determinístico. Exercitado por lint-selftest.sh (run_compose_settings_selftests).
# =============================================================================
set -uo pipefail

PROV=""
[ "${1:-}" = "--provenance" ] && { PROV=1; shift; }
[ "$#" -ge 1 ] || { echo "uso: compose-settings.sh [--provenance] <layer1.json> ... <layerN.json>" >&2; exit 2; }
command -v jq >/dev/null 2>&1 || { echo "compose-settings: jq ausente — não é possível compor (exit 3)." >&2; exit 3; }

for f in "$@"; do
  [ -f "$f" ] || { echo "ERRO: camada ausente: $f" >&2; exit 2; }
  jq empty "$f" 2>/dev/null || { echo "ERRO: JSON inválido: $f" >&2; exit 2; }
done

if [ -n "$PROV" ]; then
  # Proveniência: p/ cada chave top-level, as camadas (basenames, na ordem) que a contêm.
  { for f in "$@"; do b="$(basename "$f")"; jq -r --arg L "$b" 'keys_unsorted[] | "\(.)\t\($L)"' "$f"; done; } \
    | awk -F'\t' '{ if($1 in m) m[$1]=m[$1]", "$2; else { m[$1]=$2; ord[++n]=$1 } }
                   END { for(i=1;i<=n;i++) printf "%s: %s\n", ord[i], m[ord[i]] }'
  exit 0
fi

# Deep-merge type-aware (dedup preserva ordem — arrays de hooks/permissions).
DEEPMERGE='
def dedup: reduce .[] as $x ([]; if any(.[]; . == $x) then . else . + [$x] end);
def deepmerge(a; b):
  if   (a|type)=="object" and (b|type)=="object"
  then reduce (b|keys_unsorted[]) as $k (a; .[$k] = (if (a|has($k)) then deepmerge(a[$k]; b[$k]) else b[$k] end))
  elif (a|type)=="array"  and (b|type)=="array"  then (a + b) | dedup
  else b end;
'

# Fold da base (mais genérica) p/ a mais específica.
first="$1"; shift
acc="$(cat "$first")"
for f in "$@"; do
  acc="$(jq -n "${DEEPMERGE} deepmerge(\$a; \$b)" --argjson a "$acc" --argjson b "$(cat "$f")")" \
    || { echo "ERRO: falha ao compor camada $f" >&2; exit 2; }
done
printf '%s\n' "$acc"
