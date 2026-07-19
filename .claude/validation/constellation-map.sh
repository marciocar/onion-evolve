#!/usr/bin/env bash
# =============================================================================
# constellation-map.sh — 🗺️ o MAPA da Constelação de Estudos (Fase 1 do ADR)
#
# Propósito : Visão MACRO das N estrelas (estudos discuss/*) do maestro. Lê SÓ o
#             frontmatter + bloco Tier-0 de cada docs/discussions/*/SEED.md e emite
#             o painel: phase · next_action · COLISÃO de scope_globs · CONVERGÊNCIA
#             de objective_tags · PRESENÇA (farol vivo por worktree). É o catch-up
#             das N frentes — o "Tier-0 dos Tier-0".
#
# INVARIANTES (ADR onion-adr-constellation-operating-model-2026-07, §NÃO-fazer):
#   • READ-ONLY estrito — nunca escreve, nunca pusha, nunca faz checkout.
#   • SÓ-METADADOS — lê APENAS o bloco frontmatter (1º '---' … 2º '---') de cada
#     SEED; o CORPO da discussão NUNCA é lido (fronteira estrutural: awk sai no 2º
#     '---'). É intake de metadados (authorization-layers), não leitura de conteúdo.
#   • SINGLE-MACHINE — lê SEEDs/beacons entre worktrees irmãs na mesma máquina.
#
# Uso : bash .claude/validation/constellation-map.sh [--dir <discussions>] [--json]
#         --dir  <path> : dir das discussões (default: <repo>/docs/discussions)
#         --json        : saída JSON {count, stars[], scope_collisions[], objective_convergences[]}
#
# Saída : exit 0 = scan ok · exit 2 = uso incorreto / dir ausente. Determinístico, sem LLM.
# Molde : federation-status-scan.sh (arg-driven, --json, awk determinístico).
# =============================================================================

set -euo pipefail

JSON=0
DIR=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) JSON=1; shift ;;
    --dir)  DIR="${2:-}"; shift 2 ;;
    *) echo "uso: $0 [--dir <discussions>] [--json]" >&2; exit 2 ;;
  esac
done

if [[ -z "$DIR" ]]; then
  REPO_TOP="$(git rev-parse --show-toplevel 2>/dev/null || true)"
  DIR="${REPO_TOP:-.}/docs/discussions"
fi
if [[ ! -d "$DIR" ]]; then
  echo "erro: discussions dir ausente: $DIR" >&2; exit 2
fi

TTL_MIN="${ONION_BEACON_TTL_MIN:-480}"
NOW="$(date +%s)"
# repo que CONTÉM o dir de discussões — usado só p/ resolver worktree→beacon (presença).
REPO="$(git -C "$DIR" rev-parse --show-toplevel 2>/dev/null || true)"

# ── helpers de parse (só-metadados) ──────────────────────────────────────────
# frontmatter: linhas ENTRE o 1º '---' e o 2º '---'. Sai no 2º → o corpo nunca é lido.
fm_of() {
  awk 'NR==1 && /^---[[:space:]]*$/{f=1; next}
       f && /^---[[:space:]]*$/{exit}
       f{print}' "$1"
}
strip_q() { local s="$1"; s="${s#\"}"; s="${s%\"}"; printf '%s' "$s"; }
# valor escalar (1ª ocorrência; awk-com-exit lê here-string → pipefail-safe, sem head/SIGPIPE)
fm_scalar() { awk -v k="$2" 'index($0,k":")==1{sub("^"k":[[:space:]]*",""); print; exit}' <<<"$1"; }
# só o 1º token após a chave (p/ phase, que tem comentário '# SEED | EXPLORE | …' na linha)
fm_token()  { awk -v k="$2" 'index($0,k":")==1{print $2; exit}' <<<"$1"; }
# array YAML inline ["a","b"] → um item por linha (strip aspas/espaços; [] → vazio)
fm_array() {
  local line; line="$(awk -v k="$2" 'index($0,k":")==1{print; exit}' <<<"$1")"
  [[ -n "$line" ]] || return 0
  printf '%s\n' "$line" | sed -n 's/^[^[]*\[\(.*\)\].*/\1/p' \
    | tr ',' '\n' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//; s/^"//; s/"$//' | sed '/^$/d'
}

# ── presença (dobra do farol key-by-worktree) ────────────────────────────────
worktree_for_branch() {
  local br="$1"
  [[ -n "$REPO" ]] || return 0
  git -C "$REPO" worktree list --porcelain 2>/dev/null | awk -v br="refs/heads/$1" '
    /^worktree /{wt=substr($0,10)}
    /^branch /{ if ($2==br) { print wt; exit } }'
}
presence_of() {
  local br="$1" wt bf ref age
  [[ -n "$br" ]] || { echo "dark"; return; }
  wt="$(worktree_for_branch "$br")"
  [[ -n "$wt" && -d "$wt/.claude/beacons" ]] || { echo "dark"; return; }
  for bf in "$wt"/.claude/beacons/*.beacon; do
    [[ -f "$bf" ]] || continue
    ref="$(awk -F': ' '/^refreshed_at:/{print $2; exit}' "$bf" 2>/dev/null || true)"
    age=$(( (NOW - ${ref:-0}) / 60 ))
    if [[ "$age" -le "$TTL_MIN" ]]; then echo "live"; return; fi
  done
  echo "dark"
}

# ── scan das estrelas (ordenado por slug → saída estável) ────────────────────
SLUGS=(); BRANCHES=(); PHASES=(); NEXTS=(); PRES=()
declare -a STAR_GLOBS STAR_TAGS
declare -A GLOB_STARS TAG_STARS

idx=0
while IFS= read -r seed; do
  slug="$(basename "$(dirname "$seed")")"
  [[ "$slug" == "_template" ]] && continue
  fm="$(fm_of "$seed")"
  [[ -n "$fm" ]] || continue

  branch="$(strip_q "$(fm_scalar "$fm" branch)")"
  phase="$(fm_token "$fm" phase)"; [[ -n "$phase" ]] || phase="?"
  next="$(strip_q "$(fm_scalar "$fm" next_action)")"
  globs="$(fm_array "$fm" scope_globs)"
  tags="$(fm_array "$fm" objective_tags)"

  SLUGS+=("$slug"); BRANCHES+=("$branch"); PHASES+=("$phase"); NEXTS+=("$next")
  PRES+=("$(presence_of "$branch")")
  STAR_GLOBS[$idx]="$globs"; STAR_TAGS[$idx]="$tags"

  while IFS= read -r g; do [[ -n "$g" ]] && GLOB_STARS[$g]="${GLOB_STARS[$g]:-} $slug"; done <<<"$globs"
  while IFS= read -r t; do [[ -n "$t" ]] && TAG_STARS[$t]="${TAG_STARS[$t]:-} $slug"; done <<<"$tags"
  idx=$((idx+1))
done < <(find "$DIR" -mindepth 2 -maxdepth 2 -name SEED.md 2>/dev/null | sort)

N=${#SLUGS[@]}

# colisões/convergências (chave em ≥2 estrelas), ordenadas
collisions() {  # $1 = nome do assoc via nameref → linhas "chave\tstar, star" p/ chaves em ≥2 estrelas
  local -n MAP="$1"
  local k stars cnt
  # o ':' final garante saída 0 do lado esquerdo do pipe (senão um último [[ ]] falso +
  # pipefail faria a função retornar 1 → set -e abortaria o caller). Ordenado p/ estabilidade.
  { for k in "${!MAP[@]}"; do
      stars="$(printf '%s' "${MAP[$k]}" | tr ' ' '\n' | sed '/^$/d' | sort -u)"
      cnt="$(printf '%s\n' "$stars" | sed '/^$/d' | wc -l | tr -d ' ')"
      [[ "$cnt" -ge 2 ]] && printf '%s\t%s\n' "$k" "$(printf '%s' "$stars" | tr '\n' ',' | sed 's/,$//; s/,/, /g')"
    done; :; } | sort
}

esc() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }
json_arr() { local out="" it; while IFS= read -r it; do [[ -z "$it" ]] && continue; out="${out:+$out,}\"$(esc "$it")\""; done <<<"$1"; printf '[%s]' "$out"; }

if [[ "$JSON" -eq 1 ]]; then
  printf '{"count":%d,"dir":"%s","stars":[' "$N" "$(esc "$DIR")"
  for ((i=0; i<N; i++)); do
    [[ $i -gt 0 ]] && printf ','
    printf '{"slug":"%s","branch":"%s","phase":"%s","presence":"%s","next_action":"%s","scope_globs":%s,"objective_tags":%s}' \
      "$(esc "${SLUGS[$i]}")" "$(esc "${BRANCHES[$i]}")" "$(esc "${PHASES[$i]}")" "$(esc "${PRES[$i]}")" \
      "$(esc "${NEXTS[$i]}")" "$(json_arr "${STAR_GLOBS[$i]}")" "$(json_arr "${STAR_TAGS[$i]}")"
  done
  printf '],"scope_collisions":['
  first=1; while IFS=$'\t' read -r k v; do [[ -z "$k" ]] && continue; [[ $first -eq 0 ]] && printf ','; first=0
    printf '{"glob":"%s","stars":"%s"}' "$(esc "$k")" "$(esc "$v")"; done < <(collisions GLOB_STARS)
  printf '],"objective_convergences":['
  first=1; while IFS=$'\t' read -r k v; do [[ -z "$k" ]] && continue; [[ $first -eq 0 ]] && printf ','; first=0
    printf '{"tag":"%s","stars":"%s"}' "$(esc "$k")" "$(esc "$v")"; done < <(collisions TAG_STARS)
  printf ']}\n'
  exit 0
fi

# ── painel humano ────────────────────────────────────────────────────────────
if [[ "$N" -eq 0 ]]; then
  echo "🗺️  Constelação — nenhuma estrela em $DIR (só o _template?)."
  exit 0
fi
echo "🗺️  Constelação de Estudos — $N estrela(s)  ·  read-only, só-metadados"
echo
printf '   %-3s %-24s %-9s %s\n' "" "ESTRELA" "FASE" "PRÓXIMO PASSO"
for ((i=0; i<N; i++)); do
  mark="·"; [[ "${PRES[$i]}" == "live" ]] && mark="🕯️"
  nx="${NEXTS[$i]}"; [[ "${#nx}" -gt 64 ]] && nx="${nx:0:64}…"
  printf '   %-3s %-24s %-9s %s\n' "$mark" "${SLUGS[$i]}" "${PHASES[$i]}" "$nx"
done

col="$(collisions GLOB_STARS)"
if [[ -n "$col" ]]; then
  echo; echo "⚠️  COLISÃO DE ESCOPO (scope_globs em ≥2 estrelas — um-escritor-por-escopo não é dado pelo isolamento de assunto):"
  while IFS=$'\t' read -r k v; do [[ -n "$k" ]] && printf '   %s → %s\n' "$k" "$v"; done <<<"$col"
fi
conv="$(collisions TAG_STARS)"
if [[ -n "$conv" ]]; then
  echo; echo "🎯 CONVERGÊNCIA DE OBJETIVO (objective_tags em ≥2 estrelas — risco de duas soluções sobre a mesma tese):"
  while IFS=$'\t' read -r k v; do [[ -n "$k" ]] && printf '   %s → %s\n' "$k" "$v"; done <<<"$conv"
fi
echo
echo "🕯️ = farol vivo nesta máquina  ·  · = sem sessão viva  |  reconciliação profunda: 🔬 radar (Fase 2, gated)"
