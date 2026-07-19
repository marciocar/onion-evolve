#!/usr/bin/env bash
# session-beacon.sh — FAROL DE SESSÃO: sessões declaram presença/branch num repo.
#
# Motivação (incidente 2026-07-02, colisão W1×W2): uma sessão operando cross-repo (W1)
# fez checkout na working tree de um repo onde OUTRA sessão estava viva (W2) — "um
# escritor por repo" (I3) inclui SESSÕES, não só commits. O farol torna a presença
# detectável: antes de checkout/escrita em repo alheio, `check` revela quem está lá.
#
# Doutrina: o farol é SINAL, não trava (human-gated — o maestro decide; ADR work-models,
# adendo 2026-07-02). Beacons são estado de runtime: NUNCA commitados (ignorados via
# .git/info/exclude, local ao clone — não toca o .gitignore do repo).
#
# Uso:
#   session-beacon.sh up      <repo> <session_id> [hat]     # cria/refresca o farol
#   session-beacon.sh down    <repo> <session_id>           # apaga o farol
#   session-beacon.sh check   <repo> [--ignore <session_id>]# lista faróis; exit 1 se há FRESCO alheio
#   session-beacon.sh sweep   <repo>                        # remove faróis stale
#
# Frescor: refreshed_at dentro de ONION_BEACON_TTL_MIN (default 480 min). Stale é
# listado mas não bloqueia (sessão morta sem cleanup não pode travar o repo para sempre).
set -euo pipefail

CMD="${1:?uso: session-beacon.sh <up|down|check|sweep> <repo> ...}"
REPO="${2:?uso: session-beacon.sh <up|down|check|sweep> <repo> ...}"
TTL_MIN="${ONION_BEACON_TTL_MIN:-480}"
BEACON_DIR="$REPO/.claude/beacons"

ensure_exclude() {
  # ignore local ao clone (não commitável) — não clobba .gitignore de ninguém.
  # Usa o COMMON-dir (não o git-dir por-worktree): em worktree ligada o git lê o exclude do
  # common-dir, então escrever no per-worktree deixaria os beacons visíveis (?? no status).
  local git_dir
  git_dir="$(git -C "$REPO" rev-parse --git-common-dir 2>/dev/null)" \
    || git_dir="$(git -C "$REPO" rev-parse --git-dir 2>/dev/null)" || return 0
  case "$git_dir" in /*) ;; *) git_dir="$REPO/$git_dir" ;; esac
  local excl="$git_dir/info/exclude"
  mkdir -p "$(dirname "$excl")"
  grep -qx '.claude/beacons/' "$excl" 2>/dev/null || echo '.claude/beacons/' >> "$excl"
}

# árvore de trabalho canônica deste beacon (key-by-worktree): o toplevel realpath.
# Fallback gracioso p/ dir não-git. A coluna PRESENÇA do mapa da constelação lê isto.
worktree_of() {
  local wt
  wt="$(git -C "$REPO" rev-parse --show-toplevel 2>/dev/null)" || wt="$REPO"
  realpath "$wt" 2>/dev/null || echo "$wt"
}

now_epoch() { date +%s; }

case "$CMD" in
  up)
    SID="${3:?uso: session-beacon.sh up <repo> <session_id> [hat]}"
    HAT="${4:-}"
    mkdir -p "$BEACON_DIR"; ensure_exclude
    B="$BEACON_DIR/$SID.beacon"
    STARTED="$(awk -F': ' '/^started_at:/{print $2; exit}' "$B" 2>/dev/null || true)"
    [ -n "$STARTED" ] || STARTED="$(now_epoch)"
    # Preservar a intenção declarada (hat) através de refreshes sem-arg: o hook 'refresh'
    # (UserPromptSubmit) chama 'up' SEM hat — não o conhece. Sem isto, cada prompt apagaria
    # o hat declarado de volta para '—'. Espelha a preservação de started_at acima. Um hat
    # explícito (arg não-vazio) sempre vence — declarar de novo re-escreve a intenção.
    if [ -z "$HAT" ]; then
      HAT="$(awk -F': ' '/^hat:/{print $2; exit}' "$B" 2>/dev/null || true)"
      [ "$HAT" = "—" ] && HAT=""
    fi
    {
      echo "session_id: $SID"
      echo "branch: $(git -C "$REPO" branch --show-current 2>/dev/null || echo unknown)"
      echo "worktree: $(worktree_of)"
      echo "hat: ${HAT:-—}"
      echo "host: $(hostname 2>/dev/null || echo unknown)"
      echo "started_at: $STARTED"
      echo "refreshed_at: $(now_epoch)"
    } > "$B"
    ;;
  down)
    SID="${3:?uso: session-beacon.sh down <repo> <session_id>}"
    rm -f "$BEACON_DIR/$SID.beacon"
    ;;
  check)
    IGNORE=""
    [ "${3:-}" = "--ignore" ] && IGNORE="${4:-}"
    FRESH=0
    if [ -d "$BEACON_DIR" ]; then
      NOW="$(now_epoch)"
      for B in "$BEACON_DIR"/*.beacon; do
        [ -f "$B" ] || continue
        SID="$(awk -F': ' '/^session_id:/{print $2; exit}' "$B")"
        [ -n "$IGNORE" ] && [ "$SID" = "$IGNORE" ] && continue
        REF="$(awk -F': ' '/^refreshed_at:/{print $2; exit}' "$B")"
        BR="$(awk -F': ' '/^branch:/{print $2; exit}' "$B")"
        HAT="$(awk -F': ' '/^hat:/{print $2; exit}' "$B")"
        AGE_MIN=$(( (NOW - ${REF:-0}) / 60 ))
        if [ "$AGE_MIN" -le "$TTL_MIN" ]; then
          echo "🕯️ VIVA: $SID branch=$BR hat=$HAT age=${AGE_MIN}min"
          FRESH=$((FRESH + 1))
        else
          echo "(stale) $SID branch=$BR age=${AGE_MIN}min — sweep remove"
        fi
      done
    fi
    # exit 1 = há sessão viva alheia → NÃO opere na working tree sem falar com o maestro
    [ "$FRESH" -eq 0 ] || exit 1
    ;;
  sweep)
    if [ -d "$BEACON_DIR" ]; then
      NOW="$(now_epoch)"
      for B in "$BEACON_DIR"/*.beacon; do
        [ -f "$B" ] || continue
        REF="$(awk -F': ' '/^refreshed_at:/{print $2; exit}' "$B")"
        AGE_MIN=$(( (NOW - ${REF:-0}) / 60 ))
        [ "$AGE_MIN" -le "$TTL_MIN" ] || rm -f "$B"
      done
    fi
    ;;
  *)
    echo "ERROR: subcomando desconhecido '$CMD' (up|down|check|sweep)" >&2
    exit 2
    ;;
esac
