#!/usr/bin/env bash
# ops/workspace-adopt-sync.sh — atualiza o Onion de um WORKSPACE do /chat do bridge sem a sessão escrever no alvo
# servido (decisão do maestro D_UI_PILOT_WORKSPACE_ATUALIZA_POR_STAGING_E_WRAPPER_1022, 2026-10-22). Core-only.
#
# POR QUÊ: os workspaces do /chat (/var/lib/onion-bridge/workspaces/<id>) são escritos pelo SERVIÇO (onion:onion,
# ops/moat-targets.tsv). O /meta:adopt --update roda da FONTE (o core) contra o alvo, e a sessão não pode escrever
# lá. O caminho é em três tempos, com o motor REAL do adopt no meio (dogfood, nunca cópia direta do core):
#   1. stage <workspace> [<pai-do-staging>]  cópia fiel (com .git, modos e ACLs) para um staging da sessão, menos
#      os .env (nunca lidos nem copiados), mais o manifesto do vivo (caminho, tipo, modo, tamanho, mtime).
#   2. a sessão roda o /meta:adopt --update com o STAGING como alvo (não é alvo servido; o gate MOAT não o vê).
#   3. apply <workspace> <staging>  recusa se o vivo mudou desde o stage; mostra os nomes que mudam; backup
#      timestampado do vivo; devolve como onion:onion, com --delete (o que o update tirou sai) e os .env
#      protegidos; imprime o rollback.
#   verify <workspace>  confere o motor KG e o /meta:decide no vivo e roda o radar de um grafo dele, só leitura.
#
# O QUE RECUSA (rc 2, nada escrito): workspace fora de PREFIX ou não filho direto dele · caminho com symlink em
# qualquer componente · nome que não é o id de workspace · apply sem stage (sem o marcador) · staging de OUTRO
# workspace · vivo que mudou depois do stage · staging com symlink que escapa dele.
#
# Uso:
#   bash ops/workspace-adopt-sync.sh stage  /var/lib/onion-bridge/workspaces/<id> [<pai>]   # imprime o staging
#   bash ops/workspace-adopt-sync.sh apply  /var/lib/onion-bridge/workspaces/<id> <staging>
#   bash ops/workspace-adopt-sync.sh reapply /var/lib/onion-bridge/workspaces/<id> <staging>   # só metadados (dono, modo, ACL)
#   bash ops/workspace-adopt-sync.sh verify /var/lib/onion-bridge/workspaces/<id>
#   bash ops/workspace-adopt-sync.sh --selftest        # sandbox mktemp, sem sudo, nunca toca o real
#   bash ops/workspace-adopt-sync.sh --selftest-mutants  # cada guarda derrubada numa cópia tem de reprovar
set -euo pipefail
shopt -s inherit_errexit

PREFIX="/var/lib/onion-bridge/workspaces"
BACKUP_DIR="/var/backups/onion-workspaces"
OWNER="onion:onion"                     # o selftest esvazia (sandbox sem root)
SUDO_CMD="sudo -n"                      # idem
RUN_AS_SERVICE=(sudo -n -u onion)       # o radar do verify roda como o dono do workspace; o selftest esvazia
ENV_EXCLUDES=(--exclude=/.env --exclude=/.env.*)

die() { echo "workspace-adopt-sync: $*" >&2; exit 2; }
# trilho final (sem marca de mutante): nenhum rsync/tar parte de caminho vazio, relativo ou da raiz. Nasceu de a
# bancada, num contexto testado (`( … ) || rc=$?`, onde o bash desliga o errexit), ter engolido o die do check_target e
# copiado / inteiro para o sandbox (2026-10-22, só leitura, parado a tempo).
need_path() { case "${1:-}" in /?*) [ "${1%/}" != "" ] || { echo "workspace-adopt-sync: caminho inválido «$1»" >&2; exit 2; } ;; *) echo "workspace-adopt-sync: caminho inválido «${1:-}»" >&2; exit 2 ;; esac; }
sudo_do() { if [ -n "$SUDO_CMD" ]; then $SUDO_CMD "$@"; else "$@"; fi; }

# check_target <ws>: imprime o caminho canônico ou morre
check_target() {
  local ws="$1" c pfx real
  case "$ws" in /*) : ;; *) die "caminho relativo recusado: $ws" ;; esac
  ws="${ws%/}"
  c="$ws"
  while [ -n "$c" ] && [ "$c" != "/" ]; do
    sudo_do test -L "$c" && die "symlink no caminho ($c): recusado"   # guard:symlink
    c="${c%/*}"
  done
  sudo_do test -d "$ws" || die "não é diretório: $ws"
  pfx="$(sudo_do realpath -e "$PREFIX")" || die "PREFIX ausente: $PREFIX"
  real="$(sudo_do realpath -e "$ws")"
  [ "$(dirname "$real")" = "$pfx" ] || die "fora de $PREFIX: $ws"   # guard:prefix
  [[ "$(basename "$real")" =~ ^[0-9a-f]{8,64}$ ]] || die "nome não é id de workspace: $(basename "$real")"
  printf '%s\n' "$real"
}

# manifest <ws>: hash do que o vivo É (sem conteúdo de arquivo, sem .git/objects e sem o índice, que o git status reescreve)
manifest() {
  local ws="$1"
  sudo_do find "$ws" \( -path "$ws/.git/objects" -o -path "$ws/.git/index" \) -prune -o -printf '%P\t%y\t%m\t%s\t%T@\n' \
    | LC_ALL=C sort | sha256sum | cut -d' ' -f1
}

cmd_stage() {
  local ws parent st
  ws="$(check_target "$1")" || exit 2; parent="${2:-${TMPDIR:-/tmp}}"
  need_path "$ws"; mkdir -p "$parent"
  st="$(mktemp -d "${parent%/}/wsync-XXXXXX")"
  sudo_do rsync -aAX --numeric-ids "${ENV_EXCLUDES[@]}" "$ws/" "$st/ws/"   # guard:envstage
  [ -n "$OWNER" ] && sudo_do chown -R "$(id -un):$(id -gn)" "$st/ws"
  manifest "$ws" > "$st/manifest"
  printf '%s\n' "$ws" > "$st/target"
  : > "$st/.wsync-stage"
  echo "workspace-adopt-sync: stage ok — $ws → $st/ws (manifesto $(cut -c1-12 "$st/manifest"))" >&2
  printf '%s\n' "$st"
}

cmd_apply() {
  local ws st now ts bk id l
  ws="$(check_target "$1")" || exit 2; st="${2%/}"
  [ -f "$st/.wsync-stage" ] || die "apply sem stage: $st não tem o marcador"   # guard:stagemark
  [ "$(cat "$st/target")" = "$ws" ] || die "o staging é de outro workspace ($(cat "$st/target"))"   # guard:stagetarget
  need_path "$ws"; need_path "$st"
  now="$(manifest "$ws")"
  [ "$now" = "$(cat "$st/manifest")" ] || die "o vivo mudou depois do stage (manifesto $(cut -c1-12 "$st/manifest") → ${now:0:12}): refaça o stage"   # guard:manifest
  while IFS= read -r l; do
    case "$(readlink -m "$l")" in "$st/ws"|"$st/ws/"*) : ;; *) die "symlink no staging escapa dele: ${l#"$st/ws/"}" ;; esac   # guard:stagelink
  done < <(find "$st/ws" -type l)
  echo "── nomes que mudam no vivo (rsync --dry-run) ──"
  sudo_do rsync -aAX --delete --dry-run --itemize-changes "${ENV_EXCLUDES[@]}" "$st/ws/" "$ws/" | grep -v '^\.[dfL] ' | head -n 200 || true
  sync_to_live "$st" "$ws"
  echo "workspace-adopt-sync: apply ok — $ws"
}

# sync_to_live <staging> <ws>: backup com ACL, rsync SEM --chown, e o dono devolvido por find.
# POR QUE SEM --chown (medido no 1º apply real, 2026-10-22): o `--chown=U:G` do rsync é `--usermap=*:U
# --groupmap=*:G`, e o mapa vale também para os grupos NOMEADOS do ACL — o `group:onion-chat` (o grupo do runner do
# convidado, posto pelo ops/chat-runner.sh) virou `group:onion` no workspace inteiro. O staging estava certo.
sync_to_live() {
  local st="$1" ws="$2" ts id bk suid
  need_path "$ws"; need_path "$st"
  ts="$(date -u +%Y%m%d-%H%M%S)"; id="$(basename "$ws")"
  sudo_do mkdir -p "$BACKUP_DIR"
  bk="$BACKUP_DIR/$id-$ts.tar.gz"
  sudo_do tar --acls --xattrs --numeric-owner -C "$(dirname "$ws")" -czpf "$bk" "$id"
  echo "backup: $bk"
  echo "rollback: sudo rm -rf '$ws' && sudo tar --acls --xattrs --numeric-owner -C '$(dirname "$ws")' -xzpf '$bk'"
  sudo_do rsync -aAX --numeric-ids --delete "${ENV_EXCLUDES[@]}" "$st/ws/" "$ws/"   # guard:aclmap
  if [ -n "$OWNER" ]; then
    suid="$(stat -c %u "$st/ws")"
    sudo_do find "$ws" -xdev -uid "$suid" -exec chown -h "$OWNER" {} +
  fi
}

# reapply <ws> <staging>: refaz SÓ os metadados (dono, modo, ACL) a partir do staging, quando o CONTEÚDO do vivo já é
# o do staging — o conserto de um apply que acertou o conteúdo e errou o metadado. Conteúdo diferente recusa.
cmd_reapply() {
  local ws st diffs
  ws="$(check_target "$1")" || exit 2; st="${2%/}"
  [ -f "$st/.wsync-stage" ] || die "reapply sem stage: $st não tem o marcador"
  [ "$(cat "$st/target")" = "$ws" ] || die "o staging é de outro workspace ($(cat "$st/target"))"
  need_path "$ws"; need_path "$st"
  diffs="$(sudo_do rsync -rlc --dry-run --delete --itemize-changes --exclude=/.git/index "${ENV_EXCLUDES[@]}" "$st/ws/" "$ws/" | grep -E '^(\*deleting|[<>ch])' || true)"
  [ -z "$diffs" ] || die "o conteúdo do vivo difere do staging ($(printf '%s\n' "$diffs" | head -n 3 | tr '\n' ' ')): reapply só corrige metadados"   # guard:reapply
  sync_to_live "$st" "$ws"
  echo "workspace-adopt-sync: reapply ok — $ws"
}

cmd_verify() {
  local ws f fail=0 g rc=0
  ws="$(check_target "$1")" || exit 2; need_path "$ws"
  for f in .claude/validation/decide-census.sh .claude/validation/kg-decide-seal.sh .claude/validation/kg-radar.sh \
           .claude/commands/meta/decide.md .claude/.onion-version; do
    if sudo_do test -f "$ws/$f"; then echo "  ✓ $f"; else echo "  ✗ $f ausente"; fail=1; fi
  done
  if sudo_do grep -q '^source_commit:' "$ws/.claude/.onion-version" 2>/dev/null; then
    echo "  ✓ carimbo: $(sudo_do grep -E '^(source_commit|framework|role):' "$ws/.claude/.onion-version" | tr '\n' ' ')"
  else
    echo "  ✗ .onion-version sem source_commit (carimbo antigo)"; fail=1
  fi
  g="$(sudo_do find "$ws" -name '*.kg.yaml' -not -path '*/.git/*' -not -path '*/fixtures/*' -not -path '*/vendor/*' | LC_ALL=C sort | head -n 1)"
  if [ -n "$g" ] && [ "$fail" = 0 ]; then
    if [ "${#RUN_AS_SERVICE[@]}" -gt 0 ]; then
      "${RUN_AS_SERVICE[@]}" bash -c 'cd "$1" && bash .claude/validation/kg-radar.sh "$2" --integrity --schema >/dev/null' _ "$ws" "${g#"$ws/"}" || rc=$?
    else
      (cd "$ws" && bash .claude/validation/kg-radar.sh "${g#"$ws/"}" --integrity --schema >/dev/null) || rc=$?
    fi
    echo "  radar do workspace (${g#"$ws/"}): rc $rc"
  fi
  [ "$fail" = 0 ] || { echo "workspace-adopt-sync: verify REPROVOU"; return 1; }
  echo "workspace-adopt-sync: verify ok"
}

# ── selftest: sandbox, sem sudo, nunca toca o real ──
selftest() {
  local pass=0 fail=0 SB ws st out rc
  SB="$(mktemp -d)"; trap 'rm -rf "${SB:-}"' EXIT
  PREFIX="$SB/workspaces"; BACKUP_DIR="$SB/backups"; OWNER="$(id -un):$(id -gn)"; SUDO_CMD=""; RUN_AS_SERVICE=()
  ok() { echo "  ✓ $1"; pass=$((pass+1)); }
  ko() { echo "  ✗ $1"; fail=$((fail+1)); }
  mkws() { rm -rf "$PREFIX"; mkdir -p "$PREFIX/0123abcd/.claude/commands/meta" "$PREFIX/0123abcd/docs"
           ws="$PREFIX/0123abcd"; echo a > "$ws/CLAUDE.md"; echo SEGREDO > "$ws/.env"; echo x > "$ws/.env.local"
           echo h > "$ws/.claude/.onion-version"; echo velho > "$ws/docs/sai.md"; }
  echo "── selftest (sandbox: $SB) ──"

  mkws; st="$(cmd_stage "$ws" "$SB" 2>/dev/null)"
  if [ -f "$st/ws/CLAUDE.md" ] && [ ! -e "$st/ws/.env" ] && [ ! -e "$st/ws/.env.local" ]; then ok "stage copia o workspace e deixa os .env de fora"; else ko "stage: cópia ou .env"; fi
  echo novo > "$st/ws/.claude/commands/meta/decide.md"; rm "$st/ws/docs/sai.md"
  # grupo NOMEADO no ACL (no vivo, o do runner do convidado): um gid que não é o primário de quem roda
  local xg; xg="$(id -G | tr ' ' '\n' | grep -vx "$(id -g)" | head -n 1)"; [ -n "$xg" ] || xg=987
  setfacl -m "g:${xg}:rwx" "$st/ws/CLAUDE.md"
  if (cmd_apply "$ws" "$st" >/dev/null 2>&1) && [ -f "$ws/.claude/commands/meta/decide.md" ] && [ ! -e "$ws/docs/sai.md" ]; then ok "apply leva o novo e tira o que o update tirou"; else ko "apply feliz"; fi
  if [ "$(cat "$ws/.env")" = SEGREDO ] && [ -f "$ws/.env.local" ]; then ok ".env do vivo sobrevive ao --delete"; else ko ".env apagado ou trocado"; fi
  if ls "$BACKUP_DIR"/0123abcd-*.tar.gz >/dev/null 2>&1; then ok "backup timestampado criado"; else ko "sem backup"; fi
  if grep -qx "group:${xg}:rwx" <<< "$(getfacl -n -p --omit-header "$ws/CLAUDE.md" 2>/dev/null)"; then ok "o grupo nomeado do ACL chega intacto (sem o remapeio do --chown)"; else ko "ACL remapeado no apply"; fi

  # reapply: só metadados — com o conteúdo igual ao staging restaura o ACL; com conteúdo diferente recusa
  setfacl -b "$ws/CLAUDE.md"
  if (cmd_reapply "$ws" "$st" >/dev/null 2>&1) && grep -qx "group:${xg}:rwx" <<< "$(getfacl -n -p --omit-header "$ws/CLAUDE.md")"; then ok "reapply restaura o ACL com o conteúdo igual"; else ko "reapply não restaurou"; fi
  echo outro > "$ws/CLAUDE.md"
  rc=0; (cmd_reapply "$ws" "$st" >/dev/null 2>&1) || rc=$?
  if [ "$rc" = 2 ] && [ "$(cat "$ws/CLAUDE.md")" = outro ]; then ok "reapply com conteúdo diferente → recusa, nada escrito"; else ko "reapply aceitou conteúdo diferente (rc=$rc)"; fi

  mkws; st="$(cmd_stage "$ws" "$SB" 2>/dev/null)"; echo novo > "$st/ws/n.md"; sleep 0.01; echo mudou > "$ws/CLAUDE.md"
  rc=0; (cmd_apply "$ws" "$st" >/dev/null 2>&1) || rc=$?
  if [ "$rc" = 2 ] && [ ! -e "$ws/n.md" ]; then ok "vivo mudado depois do stage → recusa, nada escrito"; else ko "vivo mudado não recusou (rc=$rc)"; fi

  mkws; ln -s "$ws" "$PREFIX/deadbeef"
  rc=0; (cmd_stage "$PREFIX/deadbeef" "$SB" >/dev/null 2>&1) || rc=$?
  [ "$rc" = 2 ] && ok "workspace por symlink → recusa" || ko "symlink aceito (rc=$rc)"
  rm -f "$PREFIX/deadbeef"

  mkdir -p "$SB/fora/0123abcd"; local before after
  before="$(find "$SB" -maxdepth 1 -name 'wsync-*' | wc -l)"
  rc=0; (cmd_stage "$SB/fora/0123abcd" "$SB" >/dev/null 2>&1) || rc=$?
  after="$(find "$SB" -maxdepth 1 -name 'wsync-*' | wc -l)"
  [ "$rc" = 2 ] && ok "fora do prefixo → recusa" || ko "fora do prefixo aceito (rc=$rc)"
  # contexto testado: a recusa do check_target não pode ser engolida e seguir para a cópia
  [ "$before" = "$after" ] && ok "recusa num contexto testado não cria staging" || ko "staging criado depois da recusa"

  mkws; mkdir -p "$SB/falso/ws"; printf '%s\n' "$ws" > "$SB/falso/target"; manifest "$ws" > "$SB/falso/manifest"; echo x > "$SB/falso/ws/n.md"
  rc=0; (cmd_apply "$ws" "$SB/falso" >/dev/null 2>&1) || rc=$?
  if [ "$rc" = 2 ] && [ ! -e "$ws/n.md" ]; then ok "apply sem stage (sem marcador) → recusa"; else ko "apply sem stage aceito (rc=$rc)"; fi

  mkws; st="$(cmd_stage "$ws" "$SB" 2>/dev/null)"; printf '%s\n' "$PREFIX/ffffffff" > "$st/target"
  rc=0; (cmd_apply "$ws" "$st" >/dev/null 2>&1) || rc=$?
  [ "$rc" = 2 ] && ok "staging de outro workspace → recusa" || ko "staging alheio aceito (rc=$rc)"

  mkws; st="$(cmd_stage "$ws" "$SB" 2>/dev/null)"; ln -s /etc "$st/ws/fuga"
  rc=0; (cmd_apply "$ws" "$st" >/dev/null 2>&1) || rc=$?
  if [ "$rc" = 2 ] && [ ! -L "$ws/fuga" ]; then ok "symlink que escapa do staging → recusa"; else ko "symlink de fuga aceito (rc=$rc)"; fi

  mkws; rc=0; out="$(cmd_verify "$ws" 2>&1)" || rc=$?
  [ "$rc" != 0 ] && ok "verify reprova sem o motor KG" || ko "verify passou vazio"
  mkdir -p "$ws/.claude/validation"; for f in decide-census.sh kg-decide-seal.sh; do echo : > "$ws/.claude/validation/$f"; done
  printf 'exit 0\n' > "$ws/.claude/validation/kg-radar.sh"; echo d > "$ws/.claude/commands/meta/decide.md"
  printf 'framework: x\nsource_commit: abc\n' > "$ws/.claude/.onion-version"; echo 'nodes: []' > "$ws/docs/a.kg.yaml"
  rc=0; out="$(cmd_verify "$ws" 2>&1)" || rc=$?
  if [ "$rc" = 0 ] && grep -q 'radar do workspace (docs/a.kg.yaml): rc 0' <<< "$out"; then ok "verify passa com o motor e roda o radar"; else ko "verify completo (rc=$rc)"; fi

  echo "── selftest: ${pass} pass / ${fail} fail ──"
  [ "$fail" = 0 ]
}

# ── mutantes: cada guarda derrubada numa cópia tem de fazer a bancada reprovar ──
mutants() {
  local self tmp g killed=0 total=0
  self="$(realpath "${BASH_SOURCE[0]}")"; tmp="$(mktemp -d)"
  for g in symlink prefix stagemark stagetarget manifest stagelink envstage aclmap reapply; do
    total=$((total+1))
    if [ "$g" = aclmap ]; then
      sed 's/rsync -aAX --numeric-ids --delete "${ENV_EXCLUDES\[@\]}" "\$st\/ws\/" "\$ws\/"   # guard:aclmap/rsync -aAX --delete --chown="$OWNER" "${ENV_EXCLUDES[@]}" "$st\/ws\/" "$ws\/"/' "$self" > "$tmp/m.sh"
    elif [ "$g" = envstage ]; then
      sed 's/"${ENV_EXCLUDES\[@\]}" "\$ws\/" "\$st\/ws\/"   # guard:envstage/"$ws\/" "$st\/ws\/"/' "$self" > "$tmp/m.sh"
    else
      sed "/# guard:${g}\$/s/|| die /|| : /; /# guard:${g}\$/s/&& die /\&\& : /; /# guard:${g}\$/s/) die /) : /" "$self" > "$tmp/m.sh"
    fi
    if cmp -s "$self" "$tmp/m.sh"; then echo "  ✗ mutante $g: não aplicado"; continue; fi
    if bash "$tmp/m.sh" --selftest >/dev/null 2>&1; then echo "  ✗ mutante $g: SOBREVIVEU"; else echo "  ✓ mutante $g: morto"; killed=$((killed+1)); fi
  done
  rm -rf "$tmp"
  echo "mutantes: ${total} · mortos ${killed} · sobreviventes $((total-killed))"
  [ "$killed" = "$total" ]
}

case "${1:-}" in
  stage)  [ $# -ge 2 ] || die "uso: stage <workspace> [<pai>]"; cmd_stage "$2" "${3:-}" ;;
  apply)  [ $# -eq 3 ] || die "uso: apply <workspace> <staging>"; cmd_apply "$2" "$3" ;;
  reapply) [ $# -eq 3 ] || die "uso: reapply <workspace> <staging>"; cmd_reapply "$2" "$3" ;;
  verify) [ $# -eq 2 ] || die "uso: verify <workspace>"; cmd_verify "$2" ;;
  --selftest) selftest ;;
  --selftest-mutants) mutants ;;
  *) sed -n '2,25p' "${BASH_SOURCE[0]}"; exit 2 ;;
esac
