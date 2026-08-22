#!/usr/bin/env bash
# =============================================================================
# kg-backlog-project.sh — projeta docs/backlog.md a partir dos nós `status: open`
#
# Propósito : a VISÃO HUMANA do trabalho aberto. Projeção PURA dos grafos que
#             optaram-in (marcador `# kg-backlog-guard: on`) — reescrita a cada
#             run. Item fecha no grafo (status != open) → some daqui sozinho.
#             NÃO é fonte: os grafos são a fonte; este .md deriva.
#             (Graduação da inovação da PoC — o adotante-oráculo — MELHORADA:
#              consome `kg-radar --open-tsv` em vez de regex, e lê `owner:` como
#              campo do nó em vez de derivá-lo do id.)
#
# Uso       : bash .claude/validation/kg-backlog-project.sh [--write|--check]
#               --write (default) : (re)escreve docs/backlog.md
#               --check           : compara o recomputado vs o commitado (advisory)
#
# Escopo    : grafos com `# kg-backlog-guard: on` (mesmo opt-in da guarda REGRA 58
#             — escopo curado por construção; os ~614 abertos históricos ficam de
#             fora até o grafo virar trabalho vivo e optar-in). Fonte de atenção:
#             a coluna 8 do `--open-tsv` (a régua do radar, não recalculada).
# =============================================================================
set -uo pipefail
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"
RADAR=".claude/validation/kg-radar.sh"
OUT="docs/backlog.md"
MODE="${1:---write}"

# grafos que optaram-in
mapfile -t GRAPHS < <(git ls-files '*.kg.yaml' | grep -v '/fixtures/' | while read -r g; do
  grep -qE '^[[:space:]]*#[[:space:]]*kg-backlog-guard:[[:space:]]*on\b' "$g" 2>/dev/null && echo "$g"
done)

TMP="$(mktemp)"; trap 'rm -f "$TMP"' EXIT
n_open=0
for g in "${GRAPHS[@]}"; do
  base="$(basename "$g" .kg.yaml)"
  while IFS=$'\t' read -r file id typ plane st imp conf att vat trace c11 label; do
    [ -n "${id:-}" ] || continue
    # owner: campo do nó (varre o bloco até o próximo `- id:`); fallback = grafo
    owner="$(awk -v want="$id" '
      $0 ~ ("^[[:space:]]*- id:[[:space:]]*" want "[[:space:]]*$") { inblk=1; next }
      inblk && /^[[:space:]]*- id:/ { exit }
      inblk && /^[[:space:]]*owner:/ { sub(/^[^:]*:[[:space:]]*/,""); gsub(/"/,""); print; exit }
    ' "$g")"
    [ -n "$owner" ] || owner="$base"
    # TSV interno: atenção \t owner \t id \t grafo \t label
    printf '%s\t%s\t%s\t%s\t%s\n' "${att:-0}" "$owner" "$id" "$base" "${label:-}" >> "$TMP"
    n_open=$((n_open+1))
  done < <(bash "$RADAR" "$g" --open-tsv 2>/dev/null)
done

n_graphs="${#GRAPHS[@]}"
n_owners="$(cut -f2 "$TMP" 2>/dev/null | sort -u | grep -c . || echo 0)"

# monta o markdown (ordena por atenção desc DENTRO de cada owner; owners por tamanho desc)
render() {
  printf '# Backlog vivo — projeção dos grafos ⚙️ GERADO\n\n'
  printf '> Gerado por `.claude/validation/kg-backlog-project.sh` a partir dos nós `status: open`\n'
  printf '> dos grafos que optaram-in (`# kg-backlog-guard: on`). **Não editar à mão**: feche o item\n'
  printf '> no grafo (status ≠ open) e ele sai daqui. Ordem = atenção (a régua do radar). Sem corte.\n\n'
  printf '**%s itens abertos** em %s grafo(s) · %s owner(s). Fonte exaustiva (todos os grafos): `kg-radar --open-tsv`.\n\n' "$n_open" "$n_graphs" "$n_owners"
  if [ "$n_open" -eq 0 ]; then
    printf '_Nenhum fio aberto nos grafos marcados. (Para incluir um grafo, adicione `# kg-backlog-guard: on` + um `TETO:` no seu `meta:`.)_\n'
    return
  fi
  # owners ordenados por nº de itens desc
  for owner in $(cut -f2 "$TMP" | sort | uniq -c | sort -rn | awk '{$1="";sub(/^ /,"");print}' | tr ' ' '\027'); do
    o="$(printf '%s' "$owner" | tr '\027' ' ')"
    cnt="$(awk -F'\t' -v o="$o" '$2==o' "$TMP" | grep -c .)"
    printf '## %s — %s item(ns)\n\n' "$o" "$cnt"
    printf '| Atenção | Nó | Grafo | O que é |\n|--:|---|---|---|\n'
    awk -F'\t' -v o="$o" '$2==o' "$TMP" | sort -t$'\t' -k1,1nr | while IFS=$'\t' read -r att own id gr label; do
      lbl="$(printf '%s' "$label" | tr '|' '·' | cut -c1-130)"
      printf '| %.1f | `%s` | %s | %s |\n' "${att:-0}" "$id" "$gr" "$lbl"
    done
    printf '\n'
  done
}

if [ "$MODE" = "--check" ]; then
  cur="$(cat "$OUT" 2>/dev/null || true)"
  new="$(render)"
  if [ "$cur" = "$new" ]; then echo "backlog.md: em dia ($n_open abertos)"; exit 0
  else echo "backlog.md: DRIFT (advisory) — rode /meta:backlog para regenerar"; exit 0; fi
fi
render > "$OUT"
echo "✓ $OUT gerado: $n_open abertos · $n_graphs grafo(s) marcado(s) · $n_owners owner(s)"
