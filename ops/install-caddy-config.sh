#!/usr/bin/env bash
# install-caddy-config.sh — instala a config versionada do Caddy (ops/caddy/Caddyfile e os
# vhosts GERIDOS em ops/caddy/conf.d/*.caddy) em /etc/caddy, com validação, backup, reload
# gracioso e rollback.
#
# POR QUE EXISTE (medido 2026-08-26): o Caddyfile do onionevolve.com vivia SÓ na VPS,
# com backups à mão em /root/Caddyfile.bak-* — a mesma anomalia que bridge-backup.sh
# declara e que a doutrina de gpg-protect-key.sh condena ("temporário evapora vira
# incidente"). Nesta sessão isso já custou um bug de cache invisível. Agora o git é a
# SSOT e este script é a única porta de /etc/caddy — derivação, não edição à mão.
#
# CONF.D GERIDO (2026-10-08, vhost gmill): os vhosts de /etc/caddy/conf.d/ nasceram fora do git
# (vault, waha, chat…). A partir daqui, um vhost NOVO nasce versionado em ops/caddy/conf.d/ e é
# instalado por este script. Os que já estão no vivo sem fonte no repo são NÃO GERIDOS: este script
# não os lê para escrever, não os altera e não os remove — só os copia para a validação em estágio.
#   · Marcadores @@NOME@@ no conf.d versionado são resolvidos de /etc/caddy/secrets/<site>.env
#     (root 0600, escrito por ops/caddy-site-secrets.sh). Marcador sem valor, ou valor vazio,
#     RECUSA a instalação: um cookie vazio viraria `*cookie=*` e abriria a API (fail-open).
#   · O arquivo instalado leva na 1ª linha o carimbo MANAGED_MARK. É por ele que o script sabe o
#     que é dele: um vivo carimbado cuja fonte saiu do repo é removido (com backup).
#   · O vivo renderizado fica 0640 root:caddy, porque carrega segredo.
#   · Linhas `# verify: <url> <código>` no conf.d versionado entram na verificação comportamental.
#
# GUARDAS POR CONSTRUÇÃO (não por disciplina), fundadas na pesquisa de estado da arte 2026:
#  1. PRÉ-VOO: `caddy validate` num ESTÁGIO (Caddyfile + conf.d final) antes de tocar o vivo.
#  2. BACKUP timestamped do Caddyfile e de cada conf.d gerido ANTES do cp.
#  3. RELOAD, nunca restart (gracioso, zero-downtime); se o reload falhar, ROLLBACK do backup.
#  4. Verificação por COMPORTAMENTO (curl nos vhosts + no header), não por grep no arquivo.
#  5. --check é read-only e ACUSA drift (Caddyfile e conf.d gerido); FORA da VPS, CALA.
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
CONF_SRC_DIR="${REPO}/ops/caddy/conf.d"
CONF_DEST_DIR="/etc/caddy/conf.d"
SECRETS_DIR="/etc/caddy/secrets"
CONF_OWNER="root:caddy"               # o selftest esvazia (sandbox sem root)
BACKUP_DIR="/etc/caddy/backups"
SUDO_CMD="sudo"
CADDY_BIN="caddy"                     # o selftest troca por um stub no sandbox
RELOAD_CMD=(sudo systemctl reload caddy)   # idem
MANAGED_MARK="# GERIDO por ops/install-caddy-config.sh — fonte versionada:"

die() { echo "ERRO: $*" >&2; exit 2; }
usage() { sed -n 's/^# \?//p' "${BASH_SOURCE[0]}" | sed -n '/^Uso:/,/^$/p'; }

# Fontes geridas: os *.caddy de ops/caddy/conf.d/ (nomes, um por linha).
managed_names() {
  [[ -d "$CONF_SRC_DIR" ]] || return 0
  local f
  set +f
  for f in "$CONF_SRC_DIR"/*.caddy; do [[ -f "$f" ]] && basename "$f"; done
  set -f
}

# Vivos em conf.d (nomes *.caddy). Lidos com sudo: o gerido é 0640.
live_names() {
  set +f
  local f
  for f in "$CONF_DEST_DIR"/*.caddy; do [[ -e "$f" ]] && basename "$f"; done
  set -f
}

is_managed_live() { $SUDO_CMD head -n1 "$1" 2>/dev/null | grep -qF "$MANAGED_MARK"; }

# Renderiza um conf.d gerido para a stdout: carimbo + template com @@NOME@@ resolvidos.
# Recusa (die) marcador sem valor, valor vazio, ou valor com espaço/aspas/quebra de linha.
render() {
  local name="$1" src="$CONF_SRC_DIR/$1" env="$SECRETS_DIR/${1%.caddy}.env" secrets=""
  [[ -f "$src" && ! -L "$src" ]] || die "fonte gerida ausente ou symlink: $src"
  if grep -qE '@@[A-Z0-9_]+@@' "$src"; then
    secrets="$($SUDO_CMD cat "$env" 2>/dev/null)" || die "segredos de $name ausentes em $env (rode ops/caddy-site-secrets.sh)"
  fi
  SECRETS="$secrets" python3 -I - "$src" "$MANAGED_MARK ops/caddy/conf.d/$name" <<'PY' || die "render de $name recusado (veja acima)"
import os, re, sys
src, mark = sys.argv[1], sys.argv[2]
vals = {}
for line in os.environ.get("SECRETS", "").splitlines():
    if not line.strip() or line.startswith("#"):
        continue
    k, sep, v = line.partition("=")
    if not sep:
        sys.exit("linha de segredo sem '=': chave omitida")
    vals[k.strip()] = v
text = open(src, encoding="utf-8").read()
def sub(m):
    k = m.group(1)
    v = vals.get(k)
    if v is None:
        sys.exit(f"marcador @@{k}@@ sem valor")
    if not v or re.search(r'[\s"\'`{}]', v):
        sys.exit(f"valor de @@{k}@@ vazio ou com caractere proibido")
    return v
out = re.sub(r"@@([A-Z0-9_]+)@@", sub, text)
sys.stdout.write(mark + "\n" + out)
PY
}

# Pré-voo: monta um ESTÁGIO com o Caddyfile + conf.d final (não geridos do vivo + geridos
# renderizados) e roda `caddy validate` nele. Falha = die, nada tocado. Imprime o dir do estágio.
stage_and_validate() {
  [[ -f "$SRC" ]] || die "fonte ausente: $SRC"
  [[ -L "$SRC" ]] && die "fonte é SYMLINK — recuso (estado ilegítimo desta derivação)"
  local stage n
  stage="$($SUDO_CMD mktemp -d)" || die "mktemp do estágio falhou"
  $SUDO_CMD chmod 0700 "$stage"
  $SUDO_CMD mkdir -p "$stage/conf.d"
  sed "s#${CONF_DEST_DIR}/#${stage}/conf.d/#g" "$SRC" | $SUDO_CMD tee "$stage/Caddyfile" >/dev/null
  while IFS= read -r n; do
    [[ -n "$n" ]] || continue
    if [[ -f "$CONF_SRC_DIR/$n" ]]; then continue; fi           # gerido: entra renderizado abaixo
    is_managed_live "$CONF_DEST_DIR/$n" && continue              # gerido órfão: vai ser removido
    $SUDO_CMD cp -p "$CONF_DEST_DIR/$n" "$stage/conf.d/$n"       # não gerido: só copia p/ validar
  done < <(live_names)
  while IFS= read -r n; do
    [[ -n "$n" ]] || continue
    # colisão: versionado com o nome de um vivo NÃO gerido → recusa no pré-voo, antes de tocar nada
    if [[ -e "$CONF_DEST_DIR/$n" ]] && ! is_managed_live "$CONF_DEST_DIR/$n"; then
      $SUDO_CMD rm -rf "$stage"
      die "$CONF_DEST_DIR/$n existe e NÃO é gerido — recuso sobrescrever um vhost escrito à mão"
    fi
    local rendered; rendered="$(render "$n")" || { $SUDO_CMD rm -rf "$stage"; exit 2; }
    printf '%s\n' "$rendered" | $SUDO_CMD tee "$stage/conf.d/$n" >/dev/null
  done < <(managed_names)
  if ! $SUDO_CMD "$CADDY_BIN" validate --config "$stage/Caddyfile" --adapter caddyfile >/dev/null 2>&1; then
    $SUDO_CMD rm -rf "$stage"
    die "caddy validate FALHOU no estágio — nada foi tocado (rode: $CADDY_BIN validate --config $SRC --adapter caddyfile)"
  fi
  echo "$stage"
}

# Arquivo ausente → vazio (nunca rc≠0): sob pipefail+set -e, o `got=$(read_hash …)` de um conf.d ainda
# não instalado matava o --check em SILÊNCIO com rc 1 (medido no vivo, 2026-10-08).
read_hash() { { $SUDO_CMD sha256sum "$1" 2>/dev/null || true; } | awk '{print $1}'; }

backup_file() {   # backup_file <arquivo> <prefixo> → imprime o caminho do backup (ou nada)
  local f="$1" pfx="$2" ts bak
  [[ -f "$f" ]] || return 0
  $SUDO_CMD mkdir -p "$BACKUP_DIR"
  ts="$(date +%Y%m%d-%H%M%S)"; bak="$BACKUP_DIR/${pfx}.${ts}.bak"
  $SUDO_CMD cp -p "$f" "$bak" || die "backup de $f falhou — não instalo sem rede de segurança"
  [[ -n "$($SUDO_CMD find "$bak" -size +0c 2>/dev/null)" ]] || die "backup vazio ($bak) — pior que ausente; abortando"
  echo "$bak"
  # retenção: mantém os 10 mais recentes por prefixo
  $SUDO_CMD bash -c "ls -1t '$BACKUP_DIR'/'${pfx}'.*.bak 2>/dev/null | tail -n +11 | xargs -r rm -f" || true
}

verify_live() {
  local host code ct fail=0 n url want
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
  # conf.d gerido: cada `# verify: <url> <código>` é cobrado exatamente.
  while IFS= read -r n; do
    [[ -n "$n" ]] || continue
    while read -r url want; do
      # vhost novo: o certificado ACME sai SEGUNDOS depois do reload (medido 2026-10-08: 000 logo
      # após o reload, 401 com cert válido ~20s depois). Espera até VERIFY_WAIT_S antes de reprovar.
      local waited=0
      while :; do
        code="$(curl -sS -o /dev/null -w '%{http_code}' "$url" 2>/dev/null)" || true
        [[ "$code" == "$want" || "$waited" -ge "${VERIFY_WAIT_S:-90}" ]] && break
        sleep 5; waited=$((waited+5))
      done
      [[ "$code" == "$want" ]] && echo "  ✓ $url = $code ($n)" \
        || { echo "  ✗ $url = $code (esperado $want, $n)"; fail=1; }
    done < <(sed -n 's/^# verify: *\([^ ]*\) \([0-9][0-9][0-9]\) *$/\1 \2/p' "$CONF_SRC_DIR/$n")
  done < <(managed_names)
  return "$fail"
}

apply_config() {
  # `|| exit 2` explícito: dentro de um contexto testado (`f || …`) o `set -e` NÃO dispara, e a
  # falha do pré-voo seguia instalando (pego pela bancada, 2026-10-08).
  local stage; stage="$(stage_and_validate)" || exit 2
  local -a restore=() created=() removed=()
  local bak n
  bak="$(backup_file "$DEST" Caddyfile)"; [[ -n "$bak" ]] && restore+=("$bak|$DEST")
  [[ -z "$bak" ]] && echo "(sem $DEST a preservar — 1ª instalação)"
  $SUDO_CMD mkdir -p "$CONF_DEST_DIR"
  # geridos órfãos (carimbados no vivo, sem fonte no repo): backup + remoção
  while IFS= read -r n; do
    [[ -n "$n" && ! -f "$CONF_SRC_DIR/$n" ]] || continue
    is_managed_live "$CONF_DEST_DIR/$n" || continue
    bak="$(backup_file "$CONF_DEST_DIR/$n" "conf.d-$n")"; restore+=("$bak|$CONF_DEST_DIR/$n")
    $SUDO_CMD rm -f "$CONF_DEST_DIR/$n"; removed+=("$n")
  done < <(live_names)
  { $SUDO_CMD cp "$SRC" "$DEST" && $SUDO_CMD chmod 0644 "$DEST"; } || die "cp fonte→$DEST falhou"
  while IFS= read -r n; do
    [[ -n "$n" ]] || continue
    if [[ -e "$CONF_DEST_DIR/$n" ]]; then
      bak="$(backup_file "$CONF_DEST_DIR/$n" "conf.d-$n")"; restore+=("$bak|$CONF_DEST_DIR/$n")
    else
      created+=("$CONF_DEST_DIR/$n")
    fi
    $SUDO_CMD cp "$stage/conf.d/$n" "$CONF_DEST_DIR/$n.new" || die "cp de conf.d/$n falhou"
    $SUDO_CMD chmod 0640 "$CONF_DEST_DIR/$n.new" || die "chmod de conf.d/$n falhou"
    if [[ -n "$CONF_OWNER" ]]; then $SUDO_CMD chown "$CONF_OWNER" "$CONF_DEST_DIR/$n.new" || die "chown de conf.d/$n falhou"; fi
    $SUDO_CMD mv -f "$CONF_DEST_DIR/$n.new" "$CONF_DEST_DIR/$n" || die "mv de conf.d/$n falhou"
  done < <(managed_names)
  $SUDO_CMD rm -rf "$stage"
  if ! "${RELOAD_CMD[@]}"; then
    echo "reload FALHOU — restaurando backup" >&2
    local r; for r in "${restore[@]}"; do $SUDO_CMD cp -p "${r%%|*}" "${r#*|}" || true; done
    for r in "${created[@]}"; do $SUDO_CMD rm -f "$r" || true; done
    "${RELOAD_CMD[@]}" || true
    die "reload do Caddy falhou; backup restaurado"
  fi
  [[ ${#removed[@]} -gt 0 ]] && echo "── geridos órfãos removidos: ${removed[*]}"
  echo "── instalado; verificando o serviço ──"
  verify_live || die "config instalada mas a verificação comportamental falhou — investigue (backups em $BACKUP_DIR)"
  echo "── ok: $DEST == fonte, conf.d gerido instalado, Caddy recarregado, vhosts no ar ──"
}

check() {
  if [[ ! -f "$DEST" ]]; then
    echo "não estou na VPS (sem $DEST) — nada a checar; abstenho (exit 0)"; return 0
  fi
  local hs hd rc=0 n want got
  hs="$(read_hash "$SRC")"; hd="$(read_hash "$DEST")"
  if [[ "$hs" == "$hd" ]]; then
    echo "✓ sem drift: $DEST == $SRC"
  else
    echo "✗ DRIFT: $DEST diverge da fonte versionada ($SRC)"
    echo "  fonte=$hs  vivo=$hd  — alguém editou /etc/caddy à mão, ou falta instalar."
    rc=1
  fi
  while IFS= read -r n; do
    [[ -n "$n" ]] || continue
    want="$(render "$n")" || die "render de $n falhou no --check"
    want="$(printf '%s\n' "$want" | sha256sum | awk '{print $1}')"   # mesma forma do que o apply grava
    got="$(read_hash "$CONF_DEST_DIR/$n")"
    if [[ -z "$got" ]]; then echo "✗ DRIFT: conf.d/$n versionado e AUSENTE no vivo (falta instalar)"; rc=1
    elif [[ "$want" != "$got" ]]; then echo "✗ DRIFT: conf.d/$n vivo diverge do render da fonte"; rc=1
    else echo "✓ sem drift: conf.d/$n == render da fonte"; fi
  done < <(managed_names)
  while IFS= read -r n; do
    [[ -n "$n" && ! -f "$CONF_SRC_DIR/$n" ]] || continue
    if is_managed_live "$CONF_DEST_DIR/$n"; then echo "✗ DRIFT: conf.d/$n carimbado como gerido, sem fonte no repo (órfão)"; rc=1
    else echo "· conf.d/$n não gerido (fora do repo) — ignorado"; fi
  done < <(live_names)
  return "$rc"
}

# ── selftest: sandbox com stubs; nunca toca /etc nem recarrega de verdade ──
selftest() {
  local pass=0 fail=0; SB="$(mktemp -d)"; trap 'rm -rf "${SB:-}"' EXIT   # SB global: o trap de EXIT o alcança
  SRC="$SB/src-Caddyfile"; DEST="$SB/etc/Caddyfile"; BACKUP_DIR="$SB/etc/backups"; SUDO_CMD=""
  CONF_SRC_DIR="$SB/src-conf.d"; CONF_DEST_DIR="$SB/etc/conf.d"; SECRETS_DIR="$SB/etc/secrets"; CONF_OWNER=""
  mkdir -p "$SB/etc" "$CONF_DEST_DIR" "$SECRETS_DIR"
  printf 'onionevolve.com {\n  file_server\n}\nimport %s/*.caddy\n' "$CONF_DEST_DIR" > "$SRC"
  printf 'antigo\n' > "$DEST"
  # stub de caddy: validate/fmt/adapt com rc configurável por env; o validate guarda o estágio visto
  cat > "$SB/caddy" <<'STUB'
#!/usr/bin/env bash
case "${1:-}" in
  validate) [ -n "${STUB_SEEN:-}" ] && cp "$3" "$STUB_SEEN" 2>/dev/null; exit "${STUB_VALIDATE_RC:-0}" ;;
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

  # ESPELHA O RUNNER (2026-10-08): o `|| rc=$?` antigo punha a função num contexto TESTADO, onde o
  # bash desliga o `set -e` — a bancada rodava com errexit desligado e a produção com ele ligado.
  # Um `got=$(…)` que falhava matava o --check em produção e passava aqui. Agora errexit vale dentro.
  t() { local name="$1" want="$2"; shift 2; local rc out
    set +e; out="$( set -e; "$@" 2>&1 )"; rc=$?; set -e
    if [[ "$rc" -eq "$want" ]]; then pass=$((pass+1)); echo "  ✓ $name"
    else fail=$((fail+1)); echo "  ✗ $name (rc=$rc, esperado=$want)"; printf '%s\n' "$out" | sed 's/^/      | /'; fi
  }
  ok() { if eval "$2"; then pass=$((pass+1)); echo "  ✓ $1"; else fail=$((fail+1)); echo "  ✗ $1"; fi; }

  echo "── selftest (sandbox: $SB) ──"
  # 1. validate falha → NADA muda (DEST intocado)
  STUB_VALIDATE_RC=1 t "validate falha → apply RECUSA (die)" 2 apply_config
  ok "DEST intocado após validate falho" '[[ "$(cat "$DEST")" == antigo ]]'
  # 2. apply feliz → DEST vira a fonte + backup criado + reload chamado
  t "apply feliz" 0 apply_config
  ok "DEST == fonte" '[[ -f "$DEST" && "$(cat "$DEST")" == "$(cat "$SRC")" ]]'
  ok "backup criado" '[[ -n "$(find "$BACKUP_DIR" -name "Caddyfile.*.bak" 2>/dev/null)" ]]'
  ok "reload foi chamado" '[[ -f "$SB/reloaded" ]]'
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

  # ── conf.d gerido (2026-10-08) ──
  apply_config >/dev/null 2>&1 || true
  mkdir -p "$CONF_SRC_DIR"
  printf 'vault {\n  respond "a mao"\n}\n' > "$CONF_DEST_DIR/vault.caddy"           # não gerido, vivo
  printf 'demo.x {\n  basic_auth {\n    u @@DEMO_BASIC_HASH@@\n  }\n  @c header Cookie *k=@@DEMO_COOKIE@@*\n}\n' > "$CONF_SRC_DIR/demo.caddy"
  local vault_hash; vault_hash="$(sha256sum "$CONF_DEST_DIR/vault.caddy" | awk '{print $1}')"
  # 7. segredo ausente → RECUSA, nada instalado
  t "conf.d com marcador e sem segredos → apply RECUSA" 2 apply_config
  ok "conf.d gerido NÃO instalado sem segredo" '[[ ! -e "$CONF_DEST_DIR/demo.caddy" ]]'
  # 8. valor VAZIO (o fail-open do cookie) → RECUSA
  printf 'DEMO_BASIC_HASH=$2a$14$abc\nDEMO_COOKIE=\n' > "$SECRETS_DIR/demo.env"
  t "segredo com valor vazio → apply RECUSA (cookie vazio abriria a API)" 2 apply_config
  ok "conf.d gerido NÃO instalado com valor vazio" '[[ ! -e "$CONF_DEST_DIR/demo.caddy" ]]'
  # 9. feliz: renderiza, carimba, 0640, valida o ESTÁGIO com o render, não toca o não gerido
  printf 'DEMO_BASIC_HASH=$2a$14$abc\nDEMO_COOKIE=cafe1234\n' > "$SECRETS_DIR/demo.env"
  STUB_SEEN="$SB/seen" t "conf.d gerido com segredos → apply feliz" 0 apply_config
  ok "conf.d gerido instalado e renderizado" 'grep -qF "k=cafe1234*" "$CONF_DEST_DIR/demo.caddy" && grep -qF "u \$2a\$14\$abc" "$CONF_DEST_DIR/demo.caddy"'
  ok "conf.d gerido sem marcador residual" '! grep -qE "@@[A-Z0-9_]+@@" "$CONF_DEST_DIR/demo.caddy"'
  ok "conf.d gerido carimbado (1ª linha)" 'head -n1 "$CONF_DEST_DIR/demo.caddy" | grep -qF "$MANAGED_MARK"'
  ok "conf.d gerido em 0640" '[[ "$(stat -c %a "$CONF_DEST_DIR/demo.caddy")" == 640 ]]'
  ok "não gerido intocado (hash igual)" '[[ "$(sha256sum "$CONF_DEST_DIR/vault.caddy" | awk "{print \$1}")" == "$vault_hash" ]]'
  ok "validate viu o ESTÁGIO (import reescrito), não o vivo" '[[ -f "$SB/seen" ]] && ! grep -qF "$CONF_DEST_DIR/" "$SB/seen"'
  t "check: Caddyfile + conf.d gerido sem drift → verde" 0 check
  # 10. drift no conf.d gerido → check acusa
  cp "$CONF_DEST_DIR/demo.caddy" "$SB/demo.keep"; printf '# editado\n' >> "$CONF_DEST_DIR/demo.caddy"
  t "drift no conf.d gerido → check acusa" 1 check
  cp "$SB/demo.keep" "$CONF_DEST_DIR/demo.caddy"
  # 11. não gerido com o mesmo nome de um versionado → RECUSA sobrescrever
  printf 'outro.x {\n}\n' > "$CONF_SRC_DIR/vault.caddy"
  t "versionado colide com não gerido vivo → apply RECUSA" 2 apply_config
  ok "não gerido segue intocado após a colisão" '[[ "$(sha256sum "$CONF_DEST_DIR/vault.caddy" | awk "{print \$1}")" == "$vault_hash" ]]'
  rm -f "$CONF_SRC_DIR/vault.caddy"
  # 12. fonte removida do repo → o vivo carimbado é órfão: check acusa, apply remove (com backup)
  rm -f "$CONF_SRC_DIR/demo.caddy"
  t "gerido órfão → check acusa" 1 check
  t "gerido órfão → apply remove" 0 apply_config
  ok "órfão removido e não gerido preservado" '[[ ! -e "$CONF_DEST_DIR/demo.caddy" && -f "$CONF_DEST_DIR/vault.caddy" ]]'
  ok "backup do órfão criado" '[[ -n "$(find "$BACKUP_DIR" -name "conf.d-demo.caddy.*.bak" 2>/dev/null)" ]]'

  # 13. versionado ainda NÃO instalado → check acusa EM VOZ ALTA (antes morria mudo com rc 1)
  printf 'demo.x {\n  @c header Cookie *k=@@DEMO_COOKIE@@*\n}\n' > "$CONF_SRC_DIR/demo.caddy"
  ok "versionado ausente no vivo → check nomeia o drift" 'set +e; _o="$( set -e; check 2>&1 )"; set -e; [[ "$_o" == *"conf.d/demo.caddy versionado e AUSENTE"* ]]'   # errexit ligado, como no runner; sem `| grep -q` (EPIPE)
  rm -f "$CONF_SRC_DIR/demo.caddy"

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
