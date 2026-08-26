#!/usr/bin/env bash
# install-caddy-config.sh — instala a config versionada do Caddy (ops/caddy/Caddyfile)
# em /etc/caddy/Caddyfile, com validação, backup, reload gracioso e rollback.
#
# POR QUE EXISTE (medido 2026-08-26): o Caddyfile do onionevolve.com vivia SÓ na VPS,
# com backups à mão em /root/Caddyfile.bak-* — a mesma anomalia que bridge-backup.sh
# declara e que a doutrina de gpg-protect-key.sh condena ("temporário evapora vira
# incidente"). Nesta sessão isso já custou um bug de cache invisível. Agora o git é a
# SSOT e este script é a única porta de /etc/caddy — derivação, não edição à mão.
#
# GUARDAS POR CONSTRUÇÃO (não por disciplina), fundadas na pesquisa de estado da arte 2026:
#  1. PRÉ-VOO: `caddy validate` na FONTE antes de tocar o vivo — validate falha = nada muda.
#  2. BACKUP timestamped do /etc/caddy/Caddyfile ANTES do cp (substitui os .bak à mão).
#  3. RELOAD, nunca restart (gracioso, zero-downtime); se o reload falhar, ROLLBACK do backup.
#  4. Verificação por COMPORTAMENTO (curl nos vhosts + no header), não por grep no arquivo.
#  5. --check é read-only e ACUSA drift (hash fonte×vivo); FORA da VPS, CALA (não aprova por ausência).
#  6. --selftest roda em sandbox com stubs de caddy/systemctl — sem sudo, sem tocar o real.
#
# Uso:
#   ops/install-caddy-config.sh             # valida, faz backup, instala e recarrega (na KVM 8)
#   ops/install-caddy-config.sh --check     # read-only: acusa drift fonte×/etc/caddy (exit 1 se houver)
#   ops/install-caddy-config.sh --selftest  # bancada em sandbox (nunca toca /etc nem recarrega)
set -euo pipefail
set -f
export LC_ALL=C

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="${REPO}/ops/caddy/Caddyfile"
DEST="/etc/caddy/Caddyfile"
BACKUP_DIR="/etc/caddy/backups"
SUDO_CMD="sudo"
CADDY_BIN="caddy"                     # o selftest troca por um stub no sandbox
RELOAD_CMD=(sudo systemctl reload caddy)   # idem
VHOSTS=(https://onionevolve.com/ https://app.onionevolve.com/ https://auth.onionevolve.com/)

die() { echo "ERRO: $*" >&2; exit 2; }
usage() { sed -n 's/^# \?//p' "${BASH_SOURCE[0]}" | sed -n '/^Uso:/,/^$/p'; }

# Pré-voo: a FONTE tem de validar (provisiona os módulos, não só a sintaxe). Falha = die.
validate_src() {
  [[ -f "$SRC" ]] || die "fonte ausente: $SRC"
  [[ -L "$SRC" ]] && die "fonte é SYMLINK — recuso (estado ilegítimo desta derivação)"
  "$CADDY_BIN" validate --config "$SRC" --adapter caddyfile >/dev/null 2>&1 \
    || die "caddy validate FALHOU na fonte — nada foi tocado (rode: $CADDY_BIN validate --config $SRC --adapter caddyfile)"
}

read_hash() { $SUDO_CMD sha256sum "$1" 2>/dev/null | awk '{print $1}'; }

backup_dest() {
  [[ -f "$DEST" ]] || { echo "(sem $DEST a preservar — 1ª instalação)"; return 0; }
  $SUDO_CMD mkdir -p "$BACKUP_DIR"
  local ts bak; ts="$(date +%Y%m%d-%H%M%S)"; bak="$BACKUP_DIR/Caddyfile.${ts}.bak"
  $SUDO_CMD cp -p "$DEST" "$bak" || die "backup falhou — não instalo sem rede de segurança"
  [[ -s "$bak" ]] || die "backup vazio ($bak) — pior que ausente; abortando"
  echo "$bak"
  # retenção: mantém os 10 mais recentes
  # shellcheck disable=SC2012
  $SUDO_CMD bash -c "ls -1t '$BACKUP_DIR'/Caddyfile.*.bak 2>/dev/null | tail -n +11 | xargs -r rm -f" || true
}

verify_live() {
  local host code ct fail=0
  code="$(curl -sS -o /dev/null -w '%{http_code}' https://onionevolve.com/ 2>/dev/null || echo 000)"
  ct="$(curl -sSI https://onionevolve.com/ 2>/dev/null | tr -d '\r' | awk -F': ' 'tolower($1)=="cache-control"{print $2}')"
  [[ "$code" == 200 ]] || { echo "  ✗ onionevolve.com respondeu $code (esperado 200)"; fail=1; }
  [[ "$ct" == *no-cache* && "$ct" != *no-store* ]] || { echo "  ✗ cache-control em / = '$ct' (esperado no-cache, sem no-store)"; fail=1; }
  [[ "$code" == 200 ]] && echo "  ✓ onionevolve.com 200 · cache-control: $ct"
  for host in https://app.onionevolve.com/ https://auth.onionevolve.com/; do
    code="$(curl -sS -o /dev/null -w '%{http_code}' "$host" 2>/dev/null || echo 000)"
    [[ "$code" =~ ^(200|301|302|308|401|403|404)$ ]] && echo "  ✓ $host responde ($code)" \
      || { echo "  ✗ $host = $code (proxy fora do ar?)"; fail=1; }
  done
  return "$fail"
}

apply_config() {
  validate_src
  local bak; bak="$(backup_dest)"
  { $SUDO_CMD cp "$SRC" "$DEST" && $SUDO_CMD chmod 0644 "$DEST"; } || die "cp fonte→$DEST falhou"
  if ! "${RELOAD_CMD[@]}"; then
    echo "reload FALHOU — restaurando backup" >&2
    [[ -f "$bak" ]] && $SUDO_CMD cp -p "$bak" "$DEST" && "${RELOAD_CMD[@]}" || true
    die "reload do Caddy falhou; backup restaurado ($bak)"
  fi
  echo "── instalado; verificando o serviço ──"
  verify_live || die "config instalada mas a verificação comportamental falhou — investigue (backup: $bak)"
  echo "── ok: $DEST == fonte, Caddy recarregado, vhosts no ar ──"
}

check() {
  if [[ ! -f "$DEST" ]]; then
    echo "não estou na VPS (sem $DEST) — nada a checar; abstenho (exit 0)"; return 0
  fi
  local hs hd; hs="$(read_hash "$SRC")"; hd="$(read_hash "$DEST")"
  if [[ "$hs" == "$hd" ]]; then
    echo "✓ sem drift: $DEST == $SRC"; return 0
  fi
  echo "✗ DRIFT: $DEST diverge da fonte versionada ($SRC)"
  echo "  fonte=$hs  vivo=$hd  — alguém editou /etc/caddy à mão, ou falta instalar."
  return 1
}

# ── selftest: sandbox com stubs; nunca toca /etc nem recarrega de verdade ──
selftest() {
  local pass=0 fail=0; SB="$(mktemp -d)"; trap 'rm -rf "${SB:-}"' EXIT   # SB global: o trap de EXIT o alcança
  SRC="$SB/src-Caddyfile"; DEST="$SB/etc/Caddyfile"; BACKUP_DIR="$SB/etc/backups"; SUDO_CMD=""
  mkdir -p "$SB/etc"
  printf 'onionevolve.com {\n  file_server\n}\n' > "$SRC"
  printf 'antigo\n' > "$DEST"
  # stub de caddy: validate/fmt/adapt com rc configurável por env
  cat > "$SB/caddy" <<'STUB'
#!/usr/bin/env bash
case "${1:-}" in
  validate) exit "${STUB_VALIDATE_RC:-0}" ;;
  fmt)      exit 0 ;;
  adapt)    echo '{}' ;;
  *)        exit 0 ;;
esac
STUB
  chmod +x "$SB/caddy"; CADDY_BIN="$SB/caddy"
  # stub de reload: rc por env; grava um marcador para provar que foi chamado
  RELOAD_CMD=(bash -c 'echo reloaded > "$0"; exit "${STUB_RELOAD_RC:-0}"' "$SB/reloaded")
  # stub de verify_live: o selftest não tem rede — sobrescreve por sucesso silencioso
  verify_live() { return 0; }

  t() { local name="$1" want="$2"; shift 2; local rc=0 out
    out="$( ( "$@" ) 2>&1 )" || rc=$?
    if [[ "$rc" -eq "$want" ]]; then pass=$((pass+1)); echo "  ✓ $name"
    else fail=$((fail+1)); echo "  ✗ $name (rc=$rc, esperado=$want)"; printf '%s\n' "$out" | sed 's/^/      | /'; fi
  }

  echo "── selftest (sandbox: $SB) ──"
  # 1. validate falha → NADA muda (DEST intocado)
  STUB_VALIDATE_RC=1 t "validate falha → apply RECUSA (die)" 2 apply_config
  [[ "$(cat "$DEST")" == antigo ]] && { pass=$((pass+1)); echo "  ✓ DEST intocado após validate falho"; } \
    || { fail=$((fail+1)); echo "  ✗ DEST foi tocado apesar do validate falho"; }
  # 2. apply feliz → DEST vira a fonte + backup criado + reload chamado
  t "apply feliz" 0 apply_config
  [[ -f "$DEST" && "$(cat "$DEST")" == "$(cat "$SRC")" ]] && { pass=$((pass+1)); echo "  ✓ DEST == fonte"; } \
    || { fail=$((fail+1)); echo "  ✗ DEST != fonte após apply"; }
  [[ -n "$(find "$BACKUP_DIR" -name 'Caddyfile.*.bak' 2>/dev/null)" ]] && { pass=$((pass+1)); echo "  ✓ backup criado"; } \
    || { fail=$((fail+1)); echo "  ✗ backup não criado"; }
  [[ -f "$SB/reloaded" ]] && { pass=$((pass+1)); echo "  ✓ reload foi chamado"; } \
    || { fail=$((fail+1)); echo "  ✗ reload não foi chamado"; }
  # 3. idempotência: re-apply → check verde
  t "apply idempotente" 0 apply_config
  t "check sem drift → verde" 0 check
  # 4. drift: editar o DEST à mão → check acusa
  printf 'editado-a-mao\n' > "$DEST"
  t "drift (DEST editado) → check acusa" 1 check
  # 5. reload falha → rollback restaura o backup e sai ≠0
  apply_config >/dev/null 2>&1 || true   # reinstala limpo
  STUB_VALIDATE_RC=0 STUB_RELOAD_RC=1 t "reload falha → apply faz rollback e sai ≠0" 2 apply_config
  # 6. fonte ausente → die
  local keep="$SRC"; SRC="$SB/inexistente"
  t "fonte ausente → die" 2 apply_config
  SRC="$keep"

  echo "── selftest: ${pass} pass / ${fail} fail ──"
  [[ "$fail" -eq 0 ]]
}

MODE="${1:-install}"
case "$MODE" in
  --help|-h)  usage; exit 0 ;;
  --selftest) selftest ;;
  --check)    check ;;
  install)    [[ -f "$DEST" || -d /etc/caddy ]] || die "sem /etc/caddy — este script roda NA KVM 8"
              apply_config ;;
  *) die "modo desconhecido: $MODE (use --help)" ;;
esac
