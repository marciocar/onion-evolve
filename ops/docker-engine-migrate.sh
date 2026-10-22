#!/usr/bin/env bash
# ops/docker-engine-migrate.sh — troca o Docker da VPS do docker.io do Ubuntu pelo docker-ce do repositório oficial
# da Docker, numa versão FIXADA, com inventário antes, backup, prova depois e rollback impresso (decisão do maestro
# D_DOCKER_VPS_MIGRA_PARA_DOCKER_CE_29_9_2_1022, 2026-10-22). Core-only. A EXECUÇÃO do apply é numa janela do maestro.
#
# POR QUÊ: o docker.io 29.1.3 do Ubuntu fica atrás de todas as correções do Engine até a 29.9.2 (2026-10-20): 17106
# no 29.7.0, o lote do BuildKit/92543/92542/53493 no 29.8.2, HTTP/2 do Go no 29.9.0, 95839 no 29.9.1, eMudhra no
# 29.9.2 (https://docs.docker.com/engine/release-notes/29/). O Ubuntu só fez backport do BuildKit 33747/33748.
#
# PROCEDIMENTO OFICIAL (https://docs.docker.com/engine/install/ubuntu/, lido em 2026-10-22): remover os pacotes não
# oficiais (docker.io, docker-compose, docker-compose-v2, docker-doc, docker-buildx, podman-docker, containerd, runc);
# chave em /etc/apt/keyrings/docker.asc; fonte deb822 em /etc/apt/sources.list.d/docker.sources; versão fixa com
# `docker-ce=5:<v>-1~ubuntu.24.04~noble`. Desinstalar NÃO apaga /var/lib/docker (nem /var/lib/containerd). A mesma
# página avisa: porta publicada fura o firewall, e regra de firewall vai no DOCKER-USER por iptables (nft não é
# suportado) — é exatamente a contenção onion-vps-docker-firewall desta VPS, que o verify cobra.
#
# O QUE O INVENTÁRIO MEDIU (2026-10-22) E O WRAPPER RESPEITA:
#   · o image store é o do CONTAINERD (driver-type io.containerd.snapshotter.v1, sem /var/lib/docker/overlay2): as
#     imagens vivem em /var/lib/containerd. O apply troca o containerd do Ubuntu (2.2.1) pelo containerd.io e fixa o
#     mesmo modo no daemon.json (features.containerd-snapshotter), para o Engine novo não cair num store vazio.
#   · o containerd.io 2.4.2 migra o metadado do containerd para a frente; voltar ao 2.2.1 do Ubuntu NÃO é garantido.
#     O rollback de pacotes está impresso, mas a rede de segurança real é o SNAPSHOT da VPS antes da janela.
#   · compose: fica na MESMA versão (plugin 2.40.3 = o docker-compose-v2 2.40.3 de hoje); o salto para o compose 5.x
#     é outra decisão.
#
# Uso:
#   bash ops/docker-engine-migrate.sh plan     # só leitura do sistema: grava o inventário em STATE_DIR/plan-<ts>
#   bash ops/docker-engine-migrate.sh apply    # exige plan com menos de PLAN_MAX_AGE_MIN; troca os pacotes; verify
#   bash ops/docker-engine-migrate.sh verify   # compara o vivo com o último plan
#   bash ops/docker-engine-migrate.sh --selftest            # sandbox com stubs, sem sudo, nunca toca o real
#   bash ops/docker-engine-migrate.sh --selftest-mutants    # cada guarda derrubada numa cópia tem de reprovar
set -euo pipefail
shopt -s inherit_errexit
export LC_ALL=C

# ── versões FIXADAS (o pool noble do download.docker.com tem todas, medido em 2026-10-22) ──
TARGET_ENGINE="5:29.9.2-1~ubuntu.24.04~noble"
TARGET_ENGINE_SEMVER="29.9.2"
TARGET_CONTAINERD="2.4.2-3~ubuntu.24.04~noble"
TARGET_BUILDX="0.38.1-1~ubuntu.24.04~noble"
TARGET_COMPOSE="2.40.3-1~ubuntu.24.04~noble"
DOCKER_GPG_FPR="9DC858229FC7DD38854AE2D88D81803C0EBFCD88"   # chave primária oficial da Docker
DOCKER_GPG_URL="https://download.docker.com/linux/ubuntu/gpg"
UBUNTU_PKGS=(docker.io docker-compose docker-compose-v2 docker-doc docker-buildx podman-docker containerd runc)

STATE_DIR="/var/backups/onion-docker-migrate"
KEYRING="/etc/apt/keyrings/docker.asc"
SOURCES="/etc/apt/sources.list.d/docker.sources"
DAEMON_JSON="/etc/docker/daemon.json"
FW_UNIT="onion-vps-docker-firewall.service"
BRIDGE_HEALTH="http://127.0.0.1:8787/health"
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CADDY_CONF_DIR="${REPO}/ops/caddy/conf.d"
BASE_ROUTES=(https://onionevolve.com/ https://app.onionevolve.com/ https://auth.onionevolve.com/)
PLAN_MAX_AGE_MIN="${PLAN_MAX_AGE_MIN:-120}"
WAIT_DOCKER_S=120
WAIT_CONTAINERS_S=300
SUDO_CMD="sudo -n"                                   # o selftest esvazia

die() { echo "docker-engine-migrate: $*" >&2; exit 2; }
sudo_do() { if [ -n "$SUDO_CMD" ]; then $SUDO_CMD "$@"; else "$@"; fi; }
code_of() { curl -sS -o /dev/null -m 15 -w '%{http_code}' "$1" 2>/dev/null || echo 000; }

# routes: as URLs cuja resposta o verify compara com a do plan (as do instalador do Caddy, mais as # verify: geridas)
routes() {
  printf '%s\n' "${BASE_ROUTES[@]}"
  [ -d "$CADDY_CONF_DIR" ] && sed -n 's/^# verify: *\([^ ]*\) [0-9][0-9][0-9] *$/\1/p' "$CADDY_CONF_DIR"/*.caddy 2>/dev/null
  printf '%s\n' "$BRIDGE_HEALTH"
}

latest_plan() {
  local p
  p="$(sudo_do find "$STATE_DIR" -maxdepth 1 -type d -name 'plan-*' 2>/dev/null | LC_ALL=C sort | tail -n 1)"
  [ -n "$p" ] && [ -f "$p/.complete" ] || return 1
  printf '%s\n' "$p"
}

# ── plan: só LÊ o sistema; escreve apenas o próprio inventário ──
cmd_plan() {
  local ts d n
  ts="$(date -u +%Y%m%d-%H%M%S)"; d="$STATE_DIR/plan-$ts"
  sudo_do mkdir -p "$d"
  put() { sudo_do tee "$d/$1" >/dev/null; }
  # o dpkg-query sai 1 quando algum nome da lista não existe na base (o caso normal aqui): o rc dele não é o dado
  { dpkg-query -W -f='${Package}\t${Version}\t${db:Status-Status}\n' "${UBUNTU_PKGS[@]}" docker-ce docker-ce-cli containerd.io \
    docker-buildx-plugin docker-compose-plugin 2>/dev/null || true; } | awk -F'\t' '$3=="installed"' | put packages.tsv
  sudo_do docker version --format '{{.Client.Version}} {{.Server.Version}}' | put engine.tsv
  sudo_do docker info --format '{{range .DriverStatus}}{{index . 0}}={{index . 1}} {{end}}|{{.CgroupDriver}}|{{.FirewallBackend.Driver}}' | put driver.txt
  sudo_do docker ps -a --format '{{.Names}}' | while read -r n; do
    sudo_do docker inspect "$n" --format '{{.Name}}	{{.State.Status}}	{{.HostConfig.RestartPolicy.Name}}	{{if .State.Health}}{{.State.Health.Status}}{{else}}-{{end}}	{{.Config.Image}}	{{.Image}}	{{index .Config.Labels "com.docker.compose.project"}}	{{index .Config.Labels "com.docker.compose.project.working_dir"}}	{{range .Mounts}}{{if eq .Source "/var/run/docker.sock"}}SOCK{{end}}{{end}}'
  done | sed 's#^/##' | LC_ALL=C sort | put containers.tsv
  sudo_do docker images --digests --format '{{.Repository}}:{{.Tag}}@{{.Digest}} {{.ID}}' | LC_ALL=C sort | put images.txt
  sudo_do docker volume ls -q | LC_ALL=C sort | put volumes.txt
  sudo_do docker network ls --format '{{.Name}} {{.Driver}}' | LC_ALL=C sort | put networks.txt
  { sudo_do cat "$DAEMON_JSON" 2>/dev/null || echo "(ausente)"; } | put daemon.json
  { sudo_do find /etc/systemd/system -maxdepth 2 -path '*docker*' -o -maxdepth 2 -path '*containerd*' 2>/dev/null || true; } | LC_ALL=C sort | put dropins.txt
  sudo_do iptables -S DOCKER-USER | put docker-user.rules
  { systemctl is-enabled "$FW_UNIT" 2>/dev/null || true; } | put fw-unit.txt
  { getent group docker || true; } | put docker-group.txt
  routes | while read -r u; do printf '%s\t%s\n' "$u" "$(code_of "$u")"; done | put routes.tsv
  printf 'engine=%s containerd=%s buildx=%s compose=%s\n' "$TARGET_ENGINE" "$TARGET_CONTAINERD" "$TARGET_BUILDX" "$TARGET_COMPOSE" | put targets.txt
  sudo_do touch "$d/.complete"
  echo "── plan $ts ($d) ──"
  echo "pacotes: $(sudo_do cat "$d/packages.tsv" | awk -F'\t' '{printf "%s=%s ", $1, $2}')"
  echo "engine (cliente/servidor): $(sudo_do cat "$d/engine.tsv")  ·  driver: $(sudo_do cat "$d/driver.txt")"
  echo "containers: $(sudo_do awk 'END{print NR}' "$d/containers.tsv") (rodando $(sudo_do awk -F'\t' '$2=="running"' "$d/containers.tsv" | wc -l); healthy $(sudo_do awk -F'\t' '$4=="healthy"' "$d/containers.tsv" | wc -l)) · projetos compose: $(sudo_do awk -F'\t' '$7!=""{print $7}' "$d/containers.tsv" | LC_ALL=C sort -u | wc -l)"
  echo "rodando sem restart policy (não voltam sozinhos): $(sudo_do awk -F'\t' '$2=="running" && $3!="unless-stopped" && $3!="always"{print $1}' "$d/containers.tsv" | tr '\n' ' ')"
  echo "montam o socket do Docker: $(sudo_do awk -F'\t' '$9=="SOCK"{print $1}' "$d/containers.tsv" | tr '\n' ' ')"
  echo "imagens: $(sudo_do awk 'END{print NR}' "$d/images.txt") · volumes: $(sudo_do awk 'END{print NR}' "$d/volumes.txt") · redes: $(sudo_do awk 'END{print NR}' "$d/networks.txt")"
  echo "daemon.json: $(sudo_do head -c 120 "$d/daemon.json" | tr '\n' ' ') · drop-ins: $(sudo_do awk 'END{print NR}' "$d/dropins.txt")"
  echo "DOCKER-USER: $(sudo_do grep -c '^-A' "$d/docker-user.rules" || true) regra(s) · $FW_UNIT: $(sudo_do cat "$d/fw-unit.txt")"
  echo "rotas medidas: $(sudo_do awk 'END{print NR}' "$d/routes.tsv")"
}

# ── apply: só com plan recente e alvo fixado ──
cmd_apply() {
  local p age tmpk fpr bk ts drv
  p="$(latest_plan)" || die "apply sem plan: rode 'plan' antes"                                   # guard:noplan
  age=$(( ( $(date +%s) - $(sudo_do stat -c %Y "$p/.complete") ) / 60 ))
  [ "$age" -le "$PLAN_MAX_AGE_MIN" ] || die "plan velho (${age} min > ${PLAN_MAX_AGE_MIN}): rode 'plan' de novo"   # guard:planage
  [ "${ENGINE_OVERRIDE:-$TARGET_ENGINE}" = "5:${TARGET_ENGINE_SEMVER}-1~ubuntu.24.04~noble" ] \
    || die "versão alvo não é a fixada (${ENGINE_OVERRIDE:-}): o wrapper só instala ${TARGET_ENGINE}"   # guard:pinned
  [ "$(sudo_do grep -c . "$p/targets.txt")" = 1 ] && sudo_do grep -qF "engine=${TARGET_ENGINE} " "$p/targets.txt" \
    || die "o plan foi feito para outro alvo: rode 'plan' de novo"                                 # guard:plantarget
  ts="$(date -u +%Y%m%d-%H%M%S)"; bk="$STATE_DIR/apply-$ts"
  sudo_do mkdir -p "$bk"
  [ -d /etc/docker ] && sudo_do tar -C / -czpf "$bk/etc-docker.tar.gz" etc/docker
  sudo_do cp -a "$p" "$bk/plan"
  echo "backup: $bk"
  print_rollback "$p"
  tmpk="$(mktemp)"
  curl -fsSL "$DOCKER_GPG_URL" -o "$tmpk"
  fpr="$(gpg --show-keys --with-colons "$tmpk" 2>/dev/null | awk -F: '/^fpr/{print $10; exit}')"
  [ "$fpr" = "$DOCKER_GPG_FPR" ] || { rm -f "$tmpk"; die "chave da Docker com fingerprint inesperado (${fpr:-vazio})"; }   # guard:gpg
  sudo_do install -D -m 0644 "$tmpk" "$KEYRING"; rm -f "$tmpk"
  printf 'Types: deb\nURIs: https://download.docker.com/linux/ubuntu\nSuites: %s\nComponents: stable\nArchitectures: %s\nSigned-By: %s\n' \
    "$(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")" "$(dpkg --print-architecture)" "$KEYRING" \
    | sudo_do tee "$SOURCES" >/dev/null
  sudo_do apt-get update -qq
  local madison; madison="$(apt-cache madison docker-ce 2>/dev/null || true)"
  grep -qF "$TARGET_ENGINE" <<< "$madison" \
    || { sudo_do rm -f "$SOURCES"; die "o repositório não oferece docker-ce ${TARGET_ENGINE}: fonte removida, nada trocado"; }   # guard:available
  # o modo do image store do plan, fixado ANTES de o Engine novo subir (daemon.json só é criado se não existir)
  drv="$(sudo_do cat "$p/driver.txt")"
  if ! sudo_do test -f "$DAEMON_JSON"; then
    case "$drv" in *io.containerd.snapshotter*) echo '{ "features": { "containerd-snapshotter": true } }' ;;
                    *) echo '{ "features": { "containerd-snapshotter": false } }' ;; esac \
      | sudo_do install -D -m 0644 /dev/stdin "$DAEMON_JSON"
  fi
  # uma transação só: instala o oficial e remove o do Ubuntu (o sufixo - do apt remove sem purge; /var/lib fica)
  local rm_pkgs=() x
  for x in "${UBUNTU_PKGS[@]}"; do [ "$(dpkg-query -W -f='${db:Status-Status}' "$x" 2>/dev/null || true)" = installed ] && rm_pkgs+=("${x}-"); done
  sudo_do env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    "docker-ce=${TARGET_ENGINE}" "docker-ce-cli=${TARGET_ENGINE}" "containerd.io=${TARGET_CONTAINERD}" \
    "docker-buildx-plugin=${TARGET_BUILDX}" "docker-compose-plugin=${TARGET_COMPOSE}" "${rm_pkgs[@]}"
  sudo_do apt-mark hold docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin >/dev/null
  start_engine "$p"
}

# start_engine <plan>: sobe o Engine novo. O docker-ce sobe o dockerd com -H fd:// e depende do docker.socket;
# na troca de pacotes o socket do docker.io muda de configuração com a unit rodando, fica sem descritor e bate o
# limite de reinícios ("no sockets found via socket activation", medido no vivo em 2026-10-22). Por isso:
# reset-failed e restart do socket ANTES do serviço.
start_engine() {
  local p="$1"
  sudo_do systemctl daemon-reload
  sudo_do systemctl reset-failed docker.socket docker.service containerd.service 2>/dev/null || true
  sudo_do systemctl enable containerd.service docker.socket docker.service
  sudo_do systemctl restart containerd.service
  sudo_do systemctl restart docker.socket                                                            # guard:socket
  sudo_do systemctl restart docker.service
  local t=0; until sudo_do docker info >/dev/null 2>&1; do t=$((t+5)); [ "$t" -le "$WAIT_DOCKER_S" ] || die "dockerd não respondeu em ${WAIT_DOCKER_S}s (rollback acima)"; sleep 5; done
  sudo_do systemctl restart "$FW_UNIT"
  wait_containers "$p"
  cmd_verify
}

# resume: retoma depois de um apply que instalou os pacotes e não conseguiu subir o Engine. Só roda com o docker-ce
# fixado JÁ instalado (nunca instala nada) e usa o plan mais recente para esperar os containers.
cmd_resume() {
  local p
  p="$(latest_plan)" || die "resume sem plan: rode 'plan' antes"
  [ "$(dpkg-query -W -f='${Version}' docker-ce 2>/dev/null || true)" = "$TARGET_ENGINE" ] \
    || die "resume só retoma o docker-ce ${TARGET_ENGINE} já instalado"                                  # guard:resumepin
  start_engine "$p"
}

# wait_containers <plan>: espera os que estavam rodando voltarem (e healthy, se eram)
wait_containers() {
  local p="$1" t=0 pend
  while :; do
    pend="$(pending "$p")"
    [ -z "$pend" ] && return 0
    t=$((t+10)); [ "$t" -le "$WAIT_CONTAINERS_S" ] || { echo "ainda não voltaram em ${WAIT_CONTAINERS_S}s: $pend" >&2; return 0; }
    sleep 10
  done
}
# pending <plan>: nomes que estavam running (e healthy) e não estão
pending() {
  local p="$1" name st hl now nowh
  while IFS=$'\t' read -r name st _ hl _; do
    [ "$st" = running ] || continue
    now="$(sudo_do docker inspect "$name" --format '{{.State.Status}}' 2>/dev/null || echo ausente)"
    nowh="$(sudo_do docker inspect "$name" --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}-{{end}}' 2>/dev/null || echo -)"
    if [ "$now" != running ]; then printf '%s ' "$name"; continue; fi                     # guard:running
    [ "$hl" = healthy ] && [ "$nowh" != healthy ] && printf '%s ' "$name"                  # guard:healthy
  done < <(sudo_do cat "$p/containers.tsv")
  return 0
}

print_rollback() {
  local p="$1" pk
  pk="$(sudo_do awk -F'\t' '{printf "%s=%s ", $1, $2}' "$p/packages.tsv")"
  echo "rollback de pacotes (o metadado do containerd 2.4 pode não voltar ao 2.2; a rede real é o SNAPSHOT da VPS):"
  echo "  sudo apt-mark unhold docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin"
  echo "  sudo apt-get install -y --allow-downgrades ${pk}docker-ce- docker-ce-cli- containerd.io- docker-buildx-plugin- docker-compose-plugin-"
  echo "  sudo rm -f ${SOURCES} ${KEYRING} && sudo apt-get update && sudo systemctl restart docker ${FW_UNIT}"
}

# ── verify: o vivo contra o último plan ──
cmd_verify() {
  local p fail=0 cv sv pend u was now drv
  p="$(latest_plan)" || die "verify sem plan"
  read -r cv sv < <(sudo_do docker version --format '{{.Client.Version}} {{.Server.Version}}' 2>/dev/null || echo "? ?")
  if [ "$cv" = "$TARGET_ENGINE_SEMVER" ] && [ "$sv" = "$TARGET_ENGINE_SEMVER" ]; then echo "  ✓ Engine $sv (cliente e servidor)"; else echo "  ✗ Engine cliente=$cv servidor=$sv (esperado $TARGET_ENGINE_SEMVER)"; fail=1; fi   # guard:version
  pend="$(pending "$p")"
  if [ -z "$pend" ]; then echo "  ✓ todos os containers que rodavam voltaram (e os healthy seguem healthy)"; else echo "  ✗ não voltaram: $pend"; fail=1; fi   # guard:back
  drv="$(sudo_do docker info --format '{{range .DriverStatus}}{{index . 0}}={{index . 1}} {{end}}' 2>/dev/null || true)"
  if [ "${drv}" = "$(sudo_do cut -d'|' -f1 "$p/driver.txt")" ]; then echo "  ✓ image store igual ao do plan"; else echo "  ✗ image store mudou: «$drv»"; fail=1; fi   # guard:store
  if [ "$(sudo_do iptables -S DOCKER-USER 2>/dev/null)" = "$(sudo_do cat "$p/docker-user.rules")" ] && sudo_do grep -q -- '-j DROP' "$p/docker-user.rules"; then
    echo "  ✓ contenção DOCKER-USER igual à do plan"; else echo "  ✗ DOCKER-USER difere do plan (a contenção de rede pode ter caído)"; fail=1; fi   # guard:fw
  while IFS=$'\t' read -r u was; do
    now="$(code_of "$u")"
    if [ "$now" = "$was" ]; then echo "  ✓ $u = $now"; else echo "  ✗ $u = $now (no plan: $was)"; fail=1; fi   # guard:routes
  done < <(sudo_do cat "$p/routes.tsv")
  [ "$fail" = 0 ] || { echo "docker-engine-migrate: verify REPROVOU"; print_rollback "$p"; return 1; }
  echo "docker-engine-migrate: verify ok"
}

# ── selftest: stubs no PATH, sem sudo, nunca toca o real ──
selftest() {
  local pass=0 fail=0 SB rc out
  SB="$(mktemp -d)"; trap 'rm -rf "${SB:-}"' EXIT
  STATE_DIR="$SB/state"; KEYRING="$SB/keyrings/docker.asc"; SOURCES="$SB/docker.sources"; DAEMON_JSON="$SB/etc-docker/daemon.json"
  SUDO_CMD=""; WAIT_DOCKER_S=0; WAIT_CONTAINERS_S=0; CADDY_CONF_DIR="$SB/caddy"; BASE_ROUTES=(https://x.test/); BRIDGE_HEALTH="http://127.0.0.1:1/health"
  mkdir -p "$SB/bin" "$SB/caddy" "$SB/etc-docker"; export DKSB="$SB" PATH="$SB/bin:$PATH"
  printf '# verify: https://y.test/a 404\n' > "$SB/caddy/s.caddy"
  # estado do "vivo" dos stubs: versão do engine, status/health dos containers, regras e códigos HTTP
  echo 29.1.3 > "$SB/ver"; printf 'web\trunning\thealthy\ndb\trunning\t-\nold\texited\t-\n' > "$SB/ctr"
  printf -- '-N DOCKER-USER\n-A DOCKER-USER -i eth0 -j DROP\n' > "$SB/fw"; echo 200 > "$SB/http"; : > "$SB/calls"
  cat > "$SB/bin/docker" <<'S'
#!/usr/bin/env bash
echo "docker $*" >> "$DKSB/calls"
case "$1" in
  version) v=$(cat "$DKSB/ver"); echo "$v $v" | { [[ "$*" == *'\t'* ]] && tr ' ' '\t' || cat; } ;;
  info) case "$*" in *DriverStatus*CgroupDriver*) echo "driver-type=io.containerd.snapshotter.v1 |systemd|iptables";; *DriverStatus*) echo "${DKDRV:-driver-type=io.containerd.snapshotter.v1 }";; *) echo ok;; esac ;;
  ps) cut -f1 "$DKSB/ctr" ;;
  inspect) n=$2; l=$(awk -F'\t' -v n="$n" '$1==n' "$DKSB/ctr"); [ -n "$l" ] || exit 1
           st=$(cut -f2 <<< "$l"); h=$(cut -f3 <<< "$l")
           case "$*" in *RestartPolicy*) printf '/%s\t%s\tunless-stopped\t%s\timg\tsha256:x\tproj\t/w\t\n' "$n" "$st" "$h";; *Health*) echo "$h";; *) echo "$st";; esac ;;
  images) echo "img:1@sha256:a id1" ;; volume) echo v1 ;; network) echo "bridge bridge" ;;
esac
S
  cat > "$SB/bin/iptables" <<'S'
#!/usr/bin/env bash
cat "$DKSB/fw"
S
  cat > "$SB/bin/curl" <<'S'
#!/usr/bin/env bash
echo "curl $*" >> "$DKSB/calls"
for a in "$@"; do case "$a" in -o) o=1;; *) [ "${o:-}" = 1 ] && { out="$a"; o=; };; esac; done
case "$*" in *download.docker.com*) echo KEY > "$out"; exit 0;; esac
printf '%s' "$(cat "$DKSB/http")"
S
  cat > "$SB/bin/gpg" <<'S'
#!/usr/bin/env bash
echo "fpr:::::::::${DKFPR:-9DC858229FC7DD38854AE2D88D81803C0EBFCD88}:"
S
  for c in apt-get apt-mark systemctl dpkg; do printf '#!/usr/bin/env bash\necho "%s $*" >> "$DKSB/calls"\n[ "$1" = --print-architecture ] && echo amd64\nexit 0\n' "$c" > "$SB/bin/$c"; done
  cat > "$SB/bin/dpkg-query" <<'S'
#!/usr/bin/env bash
# como o real: sai 1 quando algum pacote pedido não existe na base (a lista do plan sempre tem nomes ausentes)
case "$*" in *docker.io*containerd*) printf 'docker.io\t29.1.3-0ubuntu3~24.04.2\tinstalled\ncontainerd\t2.2.1-0ubuntu1\tinstalled\n'; exit 1;; *docker.io*) echo installed;; *containerd) echo installed;; *) echo "dpkg-query: no packages found matching $*" >&2; exit 1;; esac
S
  cat > "$SB/bin/apt-cache" <<'S'
#!/usr/bin/env bash
echo " docker-ce | ${DKMADISON:-5:29.9.2-1~ubuntu.24.04~noble} | https://download.docker.com/linux/ubuntu noble/stable amd64 Packages"
S
  cat > "$SB/bin/getent" <<'S'
#!/usr/bin/env bash
echo "docker:x:999:marcio"
S
  chmod +x "$SB/bin/"*
  ok() { echo "  ✓ $1"; pass=$((pass+1)); }
  ko() { echo "  ✗ $1"; fail=$((fail+1)); }
  echo "── selftest (sandbox: $SB) ──"

  # 1. apply sem plan recusa e não chama o apt
  : > "$SB/calls"; rc=0; (cmd_apply >/dev/null 2>&1) || rc=$?
  if [ "$rc" = 2 ] && ! grep -q '^apt-get' "$SB/calls"; then ok "apply sem plan → recusa, nada instalado"; else ko "apply sem plan (rc=$rc)"; fi

  # 2. plan só lê: nenhuma chamada de apt, systemctl ou mudança no docker
  : > "$SB/calls"; out="$(cmd_plan 2>&1)" || true
  local mut='^(apt-get|apt-mark|dpkg |systemctl (start|stop|restart|reload|enable|disable|mask)|docker (rm|stop|start|restart|pull|run|system|kill|update))'
  if ! grep -q -E "$mut" "$SB/calls"; then ok "plan não muda o sistema (só lê)"; else ko "plan chamou mutação: $(grep -E "$mut" "$SB/calls" | head -2 | tr '\n' ' ')"; fi
  if grep -q 'containers: 3 (rodando 2; healthy 1)' <<< "$out"; then ok "plan inventaria containers, rodando e healthy"; else ko "inventário do plan: $(grep containers: <<< "$out")"; fi

  # 3. versão alvo diferente da fixada recusa
  : > "$SB/calls"; rc=0; (ENGINE_OVERRIDE="5:29.9.3-1~ubuntu.24.04~noble" cmd_apply >/dev/null 2>&1) || rc=$?
  if [ "$rc" = 2 ] && ! grep -q '^apt-get' "$SB/calls"; then ok "versão alvo fora da fixada → recusa"; else ko "versão não fixada aceita (rc=$rc)"; fi

  # 4. plan velho recusa
  local pl; pl="$(latest_plan)"; touch -d '-3 hours' "$pl/.complete"
  rc=0; (cmd_apply >/dev/null 2>&1) || rc=$?
  [ "$rc" = 2 ] && ok "plan velho → recusa" || ko "plan velho aceito (rc=$rc)"
  touch "$pl/.complete"

  # 4b. plan feito para outro alvo recusa
  cp "$pl/targets.txt" "$SB/t.bak"; echo "engine=5:29.8.2-1~ubuntu.24.04~noble containerd=x buildx=x compose=x" > "$pl/targets.txt"
  : > "$SB/calls"; rc=0; (cmd_apply >/dev/null 2>&1) || rc=$?
  if [ "$rc" = 2 ] && ! grep -q '^apt-get' "$SB/calls"; then ok "plan de outro alvo → recusa"; else ko "plan de outro alvo aceito (rc=$rc)"; fi
  cp "$SB/t.bak" "$pl/targets.txt"

  # 5. chave com fingerprint errado recusa antes do apt
  : > "$SB/calls"; rc=0; (DKFPR=DEADBEEF cmd_apply >/dev/null 2>&1) || rc=$?
  if [ "$rc" = 2 ] && ! grep -q '^apt-get' "$SB/calls"; then ok "fingerprint errado da chave → recusa"; else ko "chave errada aceita (rc=$rc)"; fi

  # 6. repositório sem a versão: recusa e remove a fonte
  : > "$SB/calls"; rc=0; (DKMADISON="5:29.9.1-1~ubuntu.24.04~noble" cmd_apply >/dev/null 2>&1) || rc=$?
  if [ "$rc" = 2 ] && [ ! -e "$SOURCES" ] && ! grep -q '^apt-get install' "$SB/calls"; then ok "versão indisponível no repo → recusa e tira a fonte"; else ko "versão indisponível (rc=$rc)"; fi

  # 7. apply feliz: transação única com as versões fixadas e a remoção do Ubuntu; daemon.json fixa o store; verify ok
  echo 29.9.2 > "$SB/ver"; : > "$SB/calls"; rc=0; out="$(cmd_apply 2>&1)" || rc=$?
  if [ "$rc" = 0 ] && grep -q "apt-get install -y --no-install-recommends docker-ce=5:29.9.2-1~ubuntu.24.04~noble .*containerd.io=2.4.2-3.* docker.io- containerd-" "$SB/calls"; then ok "apply instala o fixado e remove o do Ubuntu numa transação"; else ko "apply feliz (rc=$rc): $(grep 'apt-get install' "$SB/calls" | head -1)"; fi
  grep -q '"containerd-snapshotter": true' "$DAEMON_JSON" && ok "daemon.json fixa o image store do plan (containerd)" || ko "daemon.json não fixou o store"
  grep -q '^apt-mark hold docker-ce' "$SB/calls" && ok "pacotes fixados com apt-mark hold" || ko "sem hold"
  grep -q "^systemctl restart onion-vps-docker-firewall.service" "$SB/calls" && ok "a contenção de rede é reaplicada" || ko "contenção não reaplicada"

  # 8. verify reprova: container que estava up não voltou; healthy virou unhealthy; DOCKER-USER sumiu; rota mudou
  printf 'web\trunning\thealthy\ndb\texited\t-\nold\texited\t-\n' > "$SB/ctr"
  rc=0; out="$(cmd_verify 2>&1)" || rc=$?
  if [ "$rc" = 1 ] && grep -q 'não voltaram: db' <<< "$out"; then ok "verify reprova: container que rodava não voltou"; else ko "verify com container caído (rc=$rc)"; fi
  printf 'web\trunning\tunhealthy\ndb\trunning\t-\nold\texited\t-\n' > "$SB/ctr"
  rc=0; out="$(cmd_verify 2>&1)" || rc=$?
  if [ "$rc" = 1 ] && grep -q 'não voltaram: web' <<< "$out"; then ok "verify reprova: healthy virou unhealthy"; else ko "verify com unhealthy (rc=$rc)"; fi
  printf 'web\trunning\thealthy\ndb\trunning\t-\nold\texited\t-\n' > "$SB/ctr"; printf -- '-N DOCKER-USER\n' > "$SB/fw"
  rc=0; out="$(cmd_verify 2>&1)" || rc=$?
  if [ "$rc" = 1 ] && grep -q 'DOCKER-USER difere' <<< "$out"; then ok "verify reprova: a contenção DOCKER-USER caiu"; else ko "verify sem contenção (rc=$rc)"; fi
  printf -- '-N DOCKER-USER\n-A DOCKER-USER -i eth0 -j DROP\n' > "$SB/fw"; echo 502 > "$SB/http"
  rc=0; out="$(cmd_verify 2>&1)" || rc=$?
  if [ "$rc" = 1 ] && grep -q '= 502 (no plan: 200)' <<< "$out"; then ok "verify reprova: rota responde diferente do plan"; else ko "verify com rota mudada (rc=$rc)"; fi
  echo 200 > "$SB/http"; echo 29.1.3 > "$SB/ver"
  rc=0; out="$(cmd_verify 2>&1)" || rc=$?
  if [ "$rc" = 1 ] && grep -q 'Engine cliente=29.1.3' <<< "$out"; then ok "verify reprova: Engine fora da versão fixada"; else ko "verify com versão velha (rc=$rc)"; fi
  echo 29.9.2 > "$SB/ver"; export DKDRV="driver-type=io.containerd.snapshotter.v0 "
  rc=0; out="$(cmd_verify 2>&1)" || rc=$?
  if [ "$rc" = 1 ] && grep -q 'image store mudou' <<< "$out"; then ok "verify reprova: image store diferente do plan"; else ko "verify com store trocado (rc=$rc)"; fi
  unset DKDRV
  rc=0; cmd_verify >/dev/null 2>&1 || rc=$?
  [ "$rc" = 0 ] && ok "verify passa com tudo como no plan" || ko "verify verde (rc=$rc)"

  echo "── selftest: ${pass} pass / ${fail} fail ──"
  [ "$fail" = 0 ]
}

# ── mutantes: cada guarda derrubada numa cópia tem de fazer a bancada reprovar ──
mutants() {
  local self tmp g killed=0 total=0
  self="$(realpath "${BASH_SOURCE[0]}")"; tmp="$(mktemp -d)"
  for g in noplan planage pinned plantarget gpg available running healthy version store fw routes; do
    total=$((total+1))
    case "$g" in
      running|healthy) sed "/# guard:${g}\$/s/printf '%s ' \"\$name\"/:/" "$self" > "$tmp/m.sh" ;;
      version|store|fw|routes) sed "/# guard:${g}\$/s/fail=1/:/" "$self" > "$tmp/m.sh" ;;
      *) sed "/# guard:${g}\$/s/|| die /|| : /; /# guard:${g}\$/s/|| { /|| : \&\& { /" "$self" > "$tmp/m.sh" ;;
    esac
    if cmp -s "$self" "$tmp/m.sh"; then echo "  ✗ mutante $g: não aplicado"; continue; fi
    if bash "$tmp/m.sh" --selftest >/dev/null 2>&1; then echo "  ✗ mutante $g: SOBREVIVEU"; else echo "  ✓ mutante $g: morto"; killed=$((killed+1)); fi
  done
  rm -rf "$tmp"
  echo "mutantes: ${total} · mortos ${killed} · sobreviventes $((total-killed))"
  [ "$killed" = "$total" ]
}

case "${1:-}" in
  plan)   cmd_plan ;;
  apply)  cmd_apply ;;
  verify) cmd_verify ;;
  resume) cmd_resume ;;
  --selftest) selftest ;;
  --selftest-mutants) mutants ;;
  *) sed -n '2,32p' "${BASH_SOURCE[0]}"; exit 2 ;;
esac
