#!/usr/bin/env bash
# run_cell.sh <celula> <rep> [runs-dir]: uma repeticao, em conteiner sem rede, com copia descartavel do clone.
set -u -o pipefail
B="$(cd "$(dirname "$0")/.."; pwd)"
IMG="$(cat "$B/image/IMAGE_ID")"
cell=$1; rep=$2; RUNS="${3:-$B/runs}"
W="$RUNS/$cell-$rep"
[ -e "$W" ] && { echo "ja existe: $W" >&2; exit 3; }
mkdir -p "$W/lab" "$W/home/.claude" "$W/tmp"
get() { python3 -I "$B/lab/cells.py" get "$cell" "$1"; }
PROJ="$W/proj"
cp -a "$B/clone" "$PROJ"

pol="$(get policy)"; pdir="$(get pdir)"; skills="$(get skills)"; where="$(get where)"
trust="$(get trust)"; write="$(get write)"; same="$(get same)"; perm1="$(get perm1)"; flag="$(get flag)"

# o aceite de confianca: como a doc descreve para -p, no ~/.claude.json
python3 -I -c "
import json,sys
trust = '$trust' != 'false'
d = {'hasCompletedOnboarding': True, 'projects': {}}
if trust: d['projects']['$PROJ'] = {'hasTrustDialogAccepted': True}
json.dump(d, open('$W/home/.claude.json', 'w'))"

# o plugin no disco antes da sessao
if [ -n "$skills" ]; then
  case "$where" in
    project) D="$PROJ/.claude/skills/x" ;;
    nested)  D="$PROJ/.claude/skills/a/b" ;;
    user)    D="$W/home/.claude/skills/x" ;;
    subdir)  D="$PROJ/sub/.claude/skills/x" ;;
    symlink) D="$W/outside/x" ;;
  esac
  mkdir -p "$(dirname "$D")"; cp -r "$B/mods/$skills" "$D"
  if [ "$where" = symlink ]; then mkdir -p "$PROJ/.claude/skills"; ln -s "$D" "$PROJ/.claude/skills/x"; fi
fi

# montagens: so o que a celula precisa. Nada de ~/.claude da VPS, nem do repo real.
mnt=(-v "$(readlink -f "$(command -v claude)"):/usr/local/bin/claude:ro" -v "$W:$W" -v "$B/mods:$B/mods:ro" -v "$B/lab:$B/lab:ro")
[ -n "$pol" ] && mnt+=(-v "$B/policies/$pol:/etc/claude-code:ro")

session() { # session <n> <perm>; as flags extras vem do array SFLAGS
  local n=$1 perm=$2
  python3 -I "$B/lab/cells.py" plan "$cell" "$PROJ" "$n" > "$W/plan$n.json"
  docker run --rm --network none --user "$(id -u):$(id -g)" --cap-drop ALL --security-opt no-new-privileges \
    --cpus 2 --memory 3g --pids-limit 512 --label onion.lab=mods-managed \
    -e HOME="$W/home" -e USER=lab -e LANG=C.UTF-8 -e TERM=dumb -e TMPDIR="$W/tmp" -e CLAUDE_CODE_TMPDIR="$W/tmp" \
    -e LAB_DIR="$W/lab" -e LAB_ROOT="$B" -e PLAN_FILE="$W/plan$n.json" \
    "${mnt[@]}" -w "$PROJ" "$IMG" bash "$B/lab/in_container.sh" "$W/s$n" "$perm" "${SFLAGS[@]+"${SFLAGS[@]}"}" > "$W/docker$n.out" 2>&1
  echo $? > "$W/docker$n.rc"
}

date -Is > "$W/started"; cat /proc/loadavg > "$W/load-before"
extra=()
[ -n "$pdir" ] && extra+=(--plugin-dir "$B/mods/$pdir")
if [ -n "$flag" ]; then mapfile -t f < <(python3 -I -c "import json,sys; print('\n'.join(json.loads(sys.argv[1])))" "$flag"); extra+=("${f[@]}"); fi

if [ -n "$write" ] && [ "$same" != "true" ]; then
  SFLAGS=(); session 1 "$perm1"
  SFLAGS=(); session 2 bypassPermissions
elif [ -n "$write" ]; then
  SFLAGS=(); session 2 "$perm1"   # escreve e tenta na mesma sessao
else
  SFLAGS=("${extra[@]+"${extra[@]}"}"); session 2 bypassPermissions
fi
date -Is > "$W/ended"

# o que ficou em disco, para desenhar a guarda; a copia do clone sai, para nao encher o disco
( cd "$PROJ" && { find .claude/skills -mindepth 1 \( -path '*/.claude-plugin/*' -o -path '*/hooks/*' \) -print 2>/dev/null; [ -d sub ] && find sub -type f; } ) | sort > "$W/plugin-files.txt"
rm -rf "$PROJ"
echo "$cell-$rep docker=$(cat "$W/docker2.rc") claude=$(cat "$W/s2.rc" 2>/dev/null)"
