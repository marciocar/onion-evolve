#!/usr/bin/env bash
# =============================================================================
# kg-backlog-project.sh — projeta docs/backlog.md a partir dos nós `status: open`
#
# Propósito : a VISÃO HUMANA do trabalho aberto do core — a fila de decisão/
#             execução num lugar só. Projeção PURA: reescrita a cada run; item
#             fecha no grafo (status ≠ open) → some daqui sozinho. O grafo é a
#             fonte; este .md deriva (nunca editar à mão).
#
# Escopo    : a CAMADA CANÔNICA (docs/onion/graph/*.kg.yaml) EXCETO grafos opt-OUT
#             (# kg-backlog-archive: on — arquivos de pesquisa), UNIÃO os
#             grafos marcados `# kg-backlog-guard: on` em qualquer lugar (ex.: o
#             F4b em docs/evolution/research/). Exclui fixtures e o arquivo de
#             pesquisa/discussão histórica (docs/discussions, docs/evolution/*
#             não-marcado) — ruído epistêmico, visível só via `kg-radar --open-tsv`.
#             Decisão do maestro (2026-08-23): "nada sem controle" = fila inteira.
#
# Fonte     : `kg-radar --open-tsv` (a atenção já vem calculada, coluna 8 — a
#             régua do radar, não recalculada). Ordena por atenção, SEM corte.
#
# Uso       : bash ${CLAUDE_PLUGIN_ROOT}/validation/kg-backlog-project.sh [--write|--check]
# =============================================================================
set -uo pipefail
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"
RADAR="${CLAUDE_PLUGIN_ROOT}/validation/kg-radar.sh"
OUT="docs/backlog.md"
MODE="${1:---write}"

# escopo: canônico ∪ marcado (dedup, sem fixtures)
mapfile -t GRAPHS < <( {
  git ls-files 'docs/onion/graph/*.kg.yaml'
  git ls-files '*.kg.yaml' | while read -r g; do
    grep -qE '^[[:space:]]*#[[:space:]]*kg-backlog-guard:[[:space:]]*on\b' "$g" 2>/dev/null && echo "$g"
  done
} | grep -v '/fixtures/' | sort -u | while read -r g; do
  # opt-OUT: grafo que se declara ARQUIVO/pesquisa some do backlog (segue no radar --open-tsv).
  # Decisao do maestro 2026-08-23: superficie de controle limpa > completude (federation-research
  # de 2026-06 era 63% do backlog, ruido historico afundando o sinal da fila de decisao).
  grep -qE '^[[:space:]]*#[[:space:]]*kg-backlog-archive:[[:space:]]*on\b' "$g" 2>/dev/null || echo "$g"
done )

TMP="$(mktemp)"; trap 'rm -f "$TMP"' EXIT
n_open=0
for g in "${GRAPHS[@]}"; do
  [ -f "$g" ] || continue
  base="$(basename "$g" .kg.yaml)"
  # mapa id→owner do grafo, UMA passada (owner é raro; ausente → fallback grafo)
  declare -A OWN=()
  while IFS=$'\t' read -r nid now; do OWN["$nid"]="$now"; done < <(
    awk '
      /^[^[:space:]]/ { id="" }                               # top-level (nodes:/edges:/meta:) sai do escopo do no
      /^[[:space:]]*- id:/ { id=$0; sub(/^[[:space:]]*- id:[[:space:]]*/,"",id); sub(/[[:space:]]*$/,"",id); next }
      /^[[:space:]]*owner:/ && id!="" { o=$0; sub(/^[^:]*:[[:space:]]*/,"",o); gsub(/"/,"",o); print id"\t"o; id="" }
    ' "$g" )
  while IFS=$'\t' read -r file id typ plane st imp conf att vat trace c11 label; do
    [ -n "${id:-}" ] || continue
    owner="${OWN[$id]:-$base}"
    printf '%s\t%s\t%s\t%s\t%s\n' "${att:-0}" "$owner" "$id" "$base" "${label:-}" >> "$TMP"
    n_open=$((n_open+1))
  done < <(bash "$RADAR" "$g" --open-tsv 2>/dev/null)
  unset OWN
done

n_graphs="${#GRAPHS[@]}"
n_with_open="$(cut -f4 "$TMP" | sort -u | grep -c . || true)"
n_owners="$(cut -f2 "$TMP" | sort -u | grep -c . || true)"
n_archived="$(git ls-files 'docs/onion/graph/*.kg.yaml' '*.kg.yaml' 2>/dev/null | sort -u | while read -r g; do grep -qE '^[[:space:]]*#[[:space:]]*kg-backlog-archive:[[:space:]]*on\b' "$g" 2>/dev/null && echo x; done | grep -c . || true)"

render() {
  printf '# Backlog vivo — projeção dos grafos ⚙️ GERADO\n\n'
  printf '> Gerado por `${CLAUDE_PLUGIN_ROOT}/validation/kg-backlog-project.sh` a partir dos nós `status: open` da\n'
  printf '> camada canônica (`docs/onion/graph/`, exceto arquivos opt-OUT) + grafos marcados. **Não editar à mão**: feche o\n'
  printf '> item no grafo (status ≠ open, com carimbo) e ele sai daqui. Ordem = atenção (a régua do\n'
  printf '> radar: impact × incerteza × status). Sem corte NO ESCOPO; %s grafo(s) de arquivo (opt-OUT) ficam fora — visíveis via `kg-radar --open-tsv`.\n\n' "$n_archived"
  printf '**%s itens abertos** em %s grafo(s) com aberto (de %s no escopo) · %s grupo(s). A fila de decisão/execução do core; o topo por atenção é o que "custa caro estar errado".\n\n' "$n_open" "$n_with_open" "$n_graphs" "$n_owners"
  if [ "$n_open" -eq 0 ]; then printf '_Nada aberto no escopo._\n'; return; fi
  # grupos ordenados por MAIOR atenção do grupo (empate: ordem estável do sort)
  cut -f2 "$TMP" | sort -u | while read -r grp; do
    maxatt="$(awk -F'\t' -v g="$grp" '$2==g{if($1+0>m)m=$1+0}END{printf "%.2f",m}' "$TMP")"
    printf '%s\t%s\n' "$maxatt" "$grp"
  done | sort -t$'\t' -k1,1nr | while IFS=$'\t' read -r _m grp; do
    cnt="$(awk -F'\t' -v g="$grp" '$2==g' "$TMP" | grep -c . || true)"
    printf '## %s — %s item(ns)\n\n' "$grp" "$cnt"
    printf '| Atenção | Nó | Grafo | O que é |\n|--:|---|---|---|\n'
    awk -F'\t' -v g="$grp" '$2==g' "$TMP" | sort -t$'\t' -k1,1nr | while IFS=$'\t' read -r att own id gr label; do
      lbl="$(printf '%s' "$label" | tr '|' '·' | cut -c1-130)"
      printf '| %.1f | `%s` | %s | %s |\n' "${att:-0}" "$id" "$gr" "$lbl"
    done
    printf '\n'
  done
}

if [ "$MODE" = "--check" ]; then
  if [ "$(cat "$OUT" 2>/dev/null || true)" = "$(render)" ]; then echo "backlog.md: em dia ($n_open abertos)"; else echo "backlog.md: DRIFT (advisory) — rode /meta:backlog"; fi
  exit 0
fi
render > "$OUT"
echo "✓ $OUT gerado: $n_open abertos · $n_with_open grafo(s) com aberto (de $n_graphs no escopo)"
