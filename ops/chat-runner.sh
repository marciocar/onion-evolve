#!/usr/bin/env bash
# chat-runner.sh — o DEGRAU 2 do isolamento do /chat: o runner do convidado sob UID próprio (core-only).
#
# POR QUE EXISTE (2026-10-16, decisão do maestro D_MAESTRO_DEGRAU2_CONSTRUIR_JA_1016, «Construir já, instalar com
# você»): o agente do /chat de convidado roda no UID da conta do serviço, que lê o .env, o environ do processo e o
# PAT, e grava o data/ (o thread-store de todos e os convites A2A). O degrau 1 (ops/bridge-hardening.sh) fechou a
# ESCRITA no código e na raiz de confiança, e declarou o teto: o segredo e o data/ só fecham com UID distinto
# (E_SYSTEMD_PROTECTPROC_HIDES_OTHER_USERS_ONLY). O bridge não troca de UID (NoNewPrivileges, sem sudo:
# E_OBJECAO_27); a troca é de um LANÇADOR instalado pelo root e ativado por socket, um UID dinâmico por conexão. Este
# wrapper instala esse lançador e as duas units a partir do bridge SERVIDO (deploy/chat-runner/), dá ao grupo do
# runner o acesso aos workspaces e às HOMEs do CLI (ACL), e liga o runner no bridge por drop-in (CHAT_RUNNER_SOCKET).
# Molde: ops/bridge-hardening.sh e ops/update-bridge.sh (trava, recusa root, ensaio por padrão, backup, rollback
# impresso, prova depois).
#
# USO
#   ops/chat-runner.sh install [--apply]   ensaio (padrão) ou instalação do runner
#   ops/chat-runner.sh verify              prova, no instalado e no processo vivo, que o runner vale
#   ops/chat-runner.sh show                imprime o que seria instalado (nada é medido)
#
#   install sem --apply é ENSAIO: lê as fontes do bridge servido (rastreadas e limpas), renderiza as units e o
#   drop-in, mostra a diferença para o instalado e roda as checagens numa unit TRANSITÓRIA (systemd-run --collect)
#   com o sandbox do template renderizado, sob um UID dinâmico. Nada persistente é escrito.
#   verify é só leitura (sem trava): confere o instalado contra o renderizado, o grupo e as ACLs, o sandbox do
#   template INSTALADO numa unit transitória, o aperto de mão real pelo socket (initialize do CLI, sem chamar a API)
#   e a recusa do lançador, e o drop-in carregado no processo vivo do bridge.
#
# O QUE O install --apply FAZ: trava (a do update-bridge, que reinicia a mesma unit) → pré-voo → ensaio → backup
# (ACLs do estado, units e drop-in anteriores) → grupo do runner → HOMEs do CLI e workspace de sonda → ACLs →
# lançador + units → socket ligado → aperto de mão pelo socket → drop-in 40-chat-runner.conf → restart do bridge →
# /health, a linha de boot desta invocação e o verify. Falha imprime o rollback; nunca o executa.
#
# EXIT: 0 ok · 1 problema medido ou recusado · 2 não pude medir (trava, sudo, unit, health) · 3 uso inválido
#
# MODO DE TESTE (bancada): ONION_CHAT_RUNNER_TEST=1 com ONION_CHAT_RUNNER_SVC_HOME (a home de sandbox),
#   ONION_CHAT_RUNNER_STATE, ONION_CHAT_RUNNER_UNIT_DIR, ONION_CHAT_RUNNER_LIBEXEC, ONION_CHAT_RUNNER_BACKUP_DIR,
#   ONION_CHAT_RUNNER_SOCKET e ONION_CHAT_RUNNER_LOCK. Nele nada passa por sudo: systemctl, systemd-run, groupadd,
#   getent, setfacl, getfacl, journalctl e curl vêm do PATH (a bancada põe falsos), e nenhum caminho pode cair sob a
#   home real da conta do serviço, o estado real do bridge ou /etc/systemd. Qualquer ONION_CHAT_RUNNER_* sem o modo
#   de teste é uso inválido (rc 3): produção não se redireciona por ambiente.
set -uo pipefail

UNIT=onion-vps-bridge
SVC_USER=onion
GROUP=onion-chat
PROD_SVC_HOME=/home/onion
PROD_STATE=/var/lib/onion-bridge
PROD_UNIT_DIR=/etc/systemd/system
PROD_LIBEXEC=/usr/local/libexec/onion-chat
PROD_BACKUP_DIR=/var/backups/onion-chat-runner
PROD_SOCKET=/run/onion-chat.sock
PROD_LOCK=/tmp/onion-update-bridge.lock
HEALTH_LOCAL="http://127.0.0.1:8787/health"
DROPIN_NAME=40-chat-runner.conf
SOCKET_UNIT=onion-chat.socket
TEMPLATE_UNIT=onion-chat@.service
PROBE_SLUG=0000000000000000          # o workspace de SONDA do verify (16 hex: a forma que o lançador aceita)
MARKER="# onion-chat-runner: v1"
SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NAME=chat-runner

say()  { printf '[%s] %s\n' "${NAME}" "$*"; }
die()  { local rc="$1"; shift; printf '[%s] ERRO: %s\n' "${NAME}" "$*" >&2; exit "${rc}"; }
usage() { sed -n '/^# USO/,/^# O QUE O install/p' "$0" | sed '$d; s/^# \{0,1\}//' >&2; exit 3; }

case "${1:-}" in -h|--help) sed -n '/^# USO/,/^# MODO DE TESTE/p' "$0" | sed '$d; s/^# \{0,1\}//' >&2; exit 0 ;; '') usage ;; esac

# ── modo: produção ou teste declarado ──────────────────────────────────────────────────────────────────
TEST=0
if [ "${ONION_CHAT_RUNNER_TEST:-}" = 1 ]; then
  TEST=1
  SVC_HOME="${ONION_CHAT_RUNNER_SVC_HOME:?modo de teste exige ONION_CHAT_RUNNER_SVC_HOME}"
  STATE="${ONION_CHAT_RUNNER_STATE:?modo de teste exige ONION_CHAT_RUNNER_STATE}"
  UNIT_DIR="${ONION_CHAT_RUNNER_UNIT_DIR:?modo de teste exige ONION_CHAT_RUNNER_UNIT_DIR}"
  LIBEXEC="${ONION_CHAT_RUNNER_LIBEXEC:?modo de teste exige ONION_CHAT_RUNNER_LIBEXEC}"
  BACKUP_DIR="${ONION_CHAT_RUNNER_BACKUP_DIR:?modo de teste exige ONION_CHAT_RUNNER_BACKUP_DIR}"
  SOCKET="${ONION_CHAT_RUNNER_SOCKET:?modo de teste exige ONION_CHAT_RUNNER_SOCKET}"
  LOCK="${ONION_CHAT_RUNNER_LOCK:?modo de teste exige ONION_CHAT_RUNNER_LOCK}"
  SVC_USER="$(id -un)"   # a conta do serviço não existe na bancada (CI): quem roda faz o papel dela
  for _p in "${SVC_HOME}" "${STATE}" "${UNIT_DIR}" "${LIBEXEC}" "${BACKUP_DIR}" "${SOCKET}"; do
    _r="$(realpath -m -- "${_p}")"
    case "${_r}/" in "${PROD_SVC_HOME}/"*|"${PROD_STATE}/"*|/etc/systemd/*|/usr/local/*|"${PROD_SOCKET}/") die 3 "modo de teste com caminho de produção: recusado (${_r})" ;; esac
  done
else
  [ -n "${ONION_CHAT_RUNNER_TEST:-}" ] && die 3 "ONION_CHAT_RUNNER_TEST só aceita 1"
  if compgen -e | grep -E '^ONION_CHAT_RUNNER_' >/dev/null; then
    die 3 "variável ONION_CHAT_RUNNER_* sem ONION_CHAT_RUNNER_TEST=1: produção não se redireciona por ambiente"
  fi
  SVC_HOME="${PROD_SVC_HOME}"; STATE="${PROD_STATE}"; UNIT_DIR="${PROD_UNIT_DIR}"; LIBEXEC="${PROD_LIBEXEC}"
  BACKUP_DIR="${PROD_BACKUP_DIR}"; SOCKET="${PROD_SOCKET}"; LOCK="${PROD_LOCK}"
  # o wrapper roda como root por sudo o que ele mesmo renderiza: tem de ser o RASTREADO e limpo de um checkout
  _f="${SELF_DIR}/$(basename "${BASH_SOURCE[0]}")"
  git -C "${SELF_DIR}" ls-files --error-unmatch -- "${_f}" >/dev/null 2>&1 \
    || die 3 "${_f} não é arquivo rastreado de um checkout: rode o wrapper do repositório, não uma cópia"
  git -C "${SELF_DIR}" diff --quiet HEAD -- "${_f}" 2>/dev/null \
    || die 3 "${_f} tem mudança não commitada: rode o wrapper como está no commit"
fi

[ "$(id -u)" -eq 0 ] && die 3 "rodando como root: rode como o operador (o wrapper chama sudo onde precisa)"

priv()   { if [ "${TEST}" = 1 ]; then "$@"; else sudo -n "$@"; fi; }
as_svc() { if [ "${TEST}" = 1 ]; then (cd / && "$@"); else (cd / && sudo -n -u "${SVC_USER}" "$@"); fi; }

# ── argumentos: lista FECHADA ─────────────────────────────────────────────────────────────────────────
SUB="$1"; shift
APPLY=0
case "${SUB}" in install|verify|show) : ;; *) usage ;; esac
while [ $# -gt 0 ]; do
  case "$1" in
    --apply) [ "${SUB}" = install ] || die 3 "--apply só no install"; APPLY=1; shift ;;
    *) die 3 "opção não aceita: $1 (as units, os caminhos e o socket são fixos)" ;;
  esac
done

BRIDGE="${SVC_HOME}/onion-bridge"
SRC_DIR="deploy/chat-runner"
SOURCES=( "${SRC_DIR}/launcher.py" "${SRC_DIR}/onion-chat.socket.in" "${SRC_DIR}/onion-chat@.service.in" src/chat-runner.ts )
CLAUDE_SRC="${BRIDGE}/node_modules/@anthropic-ai/claude-agent-sdk-linux-x64/claude"
WS_ROOT="${STATE}/workspaces"
HOME_ROOT="${STATE}/chat-homes"
DROPIN_DIR="${UNIT_DIR}/${UNIT}.service.d"

# ── trava (só no install: verify e show só leem) ─────────────────────────────────────────────────────
if [ "${SUB}" = install ]; then
  exec 9>"${LOCK}" || die 2 "não abri a trava ${LOCK}"
  flock -n 9 || die 2 "outra execução (este wrapper, o update-bridge ou um wrapper do bridge) segura ${LOCK}; tente de novo"
fi

TMPD="$(mktemp -d)"; trap 'rm -rf -- "${TMPD}"' EXIT

# ── fontes: do bridge SERVIDO, rastreadas e limpas (o que roda como root não pode ser o que o agente escreveu) ──
read_sources() {
  local f
  for f in "${SOURCES[@]}"; do
    [ "$(priv realpath -m -- "${BRIDGE}/${f}")" = "${BRIDGE}/${f}" ] || die 1 "fonte com SYMLINK no caminho: ${BRIDGE}/${f}"
    as_svc test -f "${BRIDGE}/${f}" || die 1 "o bridge servido não tem ${f}: faça o deploy do bridge com o runner (ops/update-bridge.sh) antes"
    as_svc git -C "${BRIDGE}" ls-files --error-unmatch -- "${f}" >/dev/null 2>&1 || die 1 "${f} não é rastreado no bridge servido"
    as_svc git -C "${BRIDGE}" diff --quiet HEAD -- "${f}" 2>/dev/null || die 1 "${f} tem mudança não commitada no bridge servido: recusado"
  done
  # do OBJETO do commit, não da árvore: a checagem acima e a leitura não podem ver arquivos diferentes (refutador,
  # passada 1, achado 3: TOCTOU entre o git e o cat). E o commit todo é de quem controla o clone — por isso o que vai
  # para /etc/systemd passa ainda pela allowlist de diretivas (validate_units) e o degrau 1 é pré-condição
  BRIDGE_SHA="$(as_svc git -C "${BRIDGE}" rev-parse HEAD 2>/dev/null)" || die 2 "não li o HEAD do bridge servido"
  [[ "${BRIDGE_SHA}" =~ ^[0-9a-f]{40}$ ]] || die 2 "HEAD do bridge servido fora da forma"
  as_svc git -C "${BRIDGE}" show "${BRIDGE_SHA}:${SRC_DIR}/launcher.py" > "${TMPD}/launcher.py" || die 2 "não li o launcher.py do bridge servido"
  as_svc git -C "${BRIDGE}" show "${BRIDGE_SHA}:${SRC_DIR}/onion-chat.socket.in" > "${TMPD}/socket.in" || die 2 "não li o onion-chat.socket.in"
  as_svc git -C "${BRIDGE}" show "${BRIDGE_SHA}:${SRC_DIR}/onion-chat@.service.in" > "${TMPD}/service.in" || die 2 "não li o onion-chat@.service.in"
  BRIDGE_HEAD="${BRIDGE_SHA:0:12}"
}

render_one() {   # render_one <modelo> <saída> <de onde veio>
  { printf '%s\n# GERADO por ops/chat-runner.sh (core-only) a partir de %s do bridge servido. Não edite à mão.\n' "${MARKER}" "$3"
    sed -e "s#@SOCKET@#${SOCKET}#g" -e "s#@SVC_USER@#${SVC_USER}#g" -e "s#@GROUP@#${GROUP}#g" -e "s#@STATE@#${STATE}#g" \
        -e "s#@CLAUDE_SRC@#${CLAUDE_SRC}#g" -e "s#@LIBEXEC@#${LIBEXEC}#g" "$1"; } > "$2"
  if grep -nE '@[A-Z_]+@' "$2" >/dev/null; then die 1 "marcador sem valor em $3: $(grep -oE '@[A-Z_]+@' "$2" | sort -u | paste -sd' ' -)"; fi
}

render_dropin() {
  cat <<EOF
# ${DROPIN_DIR}/${DROPIN_NAME}
${MARKER}
# GERADO por ops/chat-runner.sh (core-only). Não edite à mão: rode o wrapper (install, depois verify).
# Degrau 2 do isolamento do /chat: liga o runner do CONVIDADO (o CLI sob um UID dinâmico por sessão, sem a home do
# serviço). A variável vence o .env (medido: process.loadEnvFile não sobrescreve o ambiente da unit). Sem ela, o
# bridge roda o convidado no próprio processo, como antes.
# REVERSÃO: sudo rm ${DROPIN_DIR}/${DROPIN_NAME} && sudo systemctl daemon-reload && sudo systemctl restart ${UNIT}
[Service]
Environment=CHAT_RUNNER_SOCKET=${SOCKET}
Environment=CHAT_HOMES_DIR=${HOME_ROOT}
EOF
}

# validate_units — o que vai para /etc/systemd/system como root sai de um clone que a conta do serviço controla
# (refutador, passada 1, achados 3 e 4: um template com DynamicUser=no, User=root ou um ExecStartPre passava pelo
# ensaio e pelo verify). Allowlist FECHADA de diretivas, com os valores de segurança EXATOS; qualquer outra recusa.
validate_units() {
  local f="$1" kind="$2" out rc=0
  out="$(python3 -I - "${f}" "${kind}" "${SOCKET}" "${SVC_USER}" "${GROUP}" "${STATE}" "${CLAUDE_SRC}" "${LIBEXEC}" <<'PY'
import sys
f, kind, sock, svc, grp, state, claude, libexec = sys.argv[1:]
EXACT = {
  "service": {"Type": "simple", "DynamicUser": "yes", "User": "onion-chat-%i", "SupplementaryGroups": grp,
    "StandardInput": "socket", "StandardOutput": "socket", "StandardError": "journal", "PrivateTmp": "yes",
    "ProtectHome": "yes", "ProtectProc": "invisible", "CapabilityBoundingSet": "", "TemporaryFileSystem": state,
    "BindPaths": state + "/workspaces " + state + "/chat-homes", "KillMode": "control-group",
    "RuntimeDirectory": "onion-chat/%i", "CollectMode": "inactive-or-failed",
    "Environment": "ONION_CHAT_WS_ROOT=%s/workspaces ONION_CHAT_HOME_ROOT=%s/chat-homes ONION_CHAT_CLAUDE=/run/onion-chat-bin/claude" % (state, state),
    "ExecStart": "/usr/bin/python3 -I /run/onion-chat-bin/launcher.py",
    "ExecStopPost": "/usr/bin/python3 -I /run/onion-chat-bin/launcher.py --fixup"},
  "socket": {"ListenStream": sock, "Accept": "yes", "SocketUser": svc, "SocketGroup": svc, "SocketMode": "0600"},
}[kind]
FREE = {"service": {"Description", "SyslogIdentifier", "RuntimeMaxSec", "TimeoutStopSec", "UMask", "PrivateDevices",
                    "ProtectKernelTunables", "ProtectKernelModules", "ProtectKernelLogs", "ProtectControlGroups", "ProtectClock",
                    "ProtectHostname", "RestrictNamespaces", "RestrictRealtime", "LockPersonality", "SystemCallArchitectures",
                    "RestrictAddressFamilies", "MemoryMax", "TasksMax"},
        "socket": {"Description", "MaxConnections", "WantedBy"}}[kind]
BIND_RO = {claude + ":/run/onion-chat-bin/claude", libexec + "/launcher.py:/run/onion-chat-bin/launcher.py"}
SECTIONS = {"service": {"[Unit]", "[Service]"}, "socket": {"[Unit]", "[Socket]", "[Install]"}}[kind]
seen, binds, bad = {}, set(), []
for n, line in enumerate(open(f, encoding="utf-8"), 1):
    line = line.rstrip("\n")
    if not line.strip() or line.lstrip().startswith(("#", ";")):
        continue
    if line.startswith("["):
        if line not in SECTIONS:
            bad.append("seção %s (linha %d)" % (line, n))
        continue
    if line.endswith("\\"):
        bad.append("continuação de linha (linha %d)" % n); continue
    k, eq, v = line.partition("=")
    if not eq or k != k.strip():
        bad.append("linha fora da forma (%d)" % n); continue
    if k == "BindReadOnlyPaths" and kind == "service":
        if v not in BIND_RO:
            bad.append("BindReadOnlyPaths fora do esperado: %s" % v)
        binds.add(v); continue
    if k in seen:
        bad.append("%s repetida" % k); continue
    seen[k] = v
    if k in EXACT:
        if v != EXACT[k]:
            bad.append("%s=%s (exigido: %s)" % (k, v, EXACT[k]))
    elif k not in FREE:
        bad.append("diretiva fora da allowlist: %s" % k)
for k, v in EXACT.items():
    if k not in seen:
        bad.append("falta %s=%s" % (k, v))
if kind == "service" and binds != BIND_RO:
    bad.append("BindReadOnlyPaths incompletos")
print("; ".join(bad)); sys.exit(1 if bad else 0)
PY
)" || rc=$?
  [ "${rc}" = 0 ] || die 1 "o modelo ${kind} do bridge servido sai da allowlist de diretivas: ${out:0:600}"
}

render_all() {
  read_sources
  render_one "${TMPD}/socket.in" "${TMPD}/${SOCKET_UNIT}" "${SRC_DIR}/onion-chat.socket.in"
  render_one "${TMPD}/service.in" "${TMPD}/${TEMPLATE_UNIT}" "${SRC_DIR}/onion-chat@.service.in"
  render_dropin > "${TMPD}/${DROPIN_NAME}"
  validate_units "${TMPD}/${SOCKET_UNIT}" socket
  validate_units "${TMPD}/${TEMPLATE_UNIT}" service
}

render_all
if [ "${SUB}" = show ]; then
  for f in "${SOCKET_UNIT}" "${TEMPLATE_UNIT}" "${DROPIN_NAME}"; do printf -- '──── %s\n' "${f}"; cat "${TMPD}/${f}"; done
  printf -- '──── launcher.py: %s bytes, sha256 %s (bridge servido em %s)\n' "$(wc -c < "${TMPD}/launcher.py")" "$(sha256sum < "${TMPD}/launcher.py" | cut -c1-16)" "${BRIDGE_HEAD}"
  exit 0
fi

# ── o sandbox do template: as propriedades que a unit transitória recebe (ensaio e verify) ─────────────────────
# Só as de SANDBOX e identidade; o que é do socket (StandardInput/Output), do ciclo (ExecStart*, CollectMode,
# RuntimeMaxSec) e o User por instância ficam de fora. Sem o grupo (ensaio antes do --apply), SupplementaryGroups sai
# e as checagens que dependem dele viram AUSENTE.
sandbox_props() {   # sandbox_props <template> <com-grupo 0|1> <launcher-a-ligar>
  local k v line
  while IFS= read -r line; do
    case "${line}" in ''|'#'*|'['*) continue ;; esac
    k="${line%%=*}"; v="${line#*=}"
    case "${k}" in
      DynamicUser|PrivateTmp|PrivateDevices|ProtectHome|ProtectProc|ProtectKernelTunables|ProtectKernelModules|ProtectKernelLogs|\
ProtectControlGroups|ProtectClock|ProtectHostname|RestrictNamespaces|RestrictRealtime|LockPersonality|CapabilityBoundingSet|\
SystemCallArchitectures|RestrictAddressFamilies|UMask|TemporaryFileSystem|Environment|MemoryMax|TasksMax)
        printf '%s\n' "-p" "${k}=${v}" ;;
      BindPaths)
        # no ensaio a raiz das HOMEs ainda não existe (o --apply a cria): sem o '-' o bind dela derrubaria a unit
        local b out=""; for b in ${v}; do if priv test -e "${b#-}"; then out+="${b} "; else out+="-${b#-} "; fi; done
        printf '%s\n' "-p" "BindPaths=${out% }" ;;
      BindReadOnlyPaths)
        # o lançador instalado ainda não existe no ensaio: liga o renderizado no mesmo caminho de dentro
        case "${v}" in *"/launcher.py:/run/onion-chat-bin/launcher.py") printf '%s\n' "-p" "BindReadOnlyPaths=$3:/run/onion-chat-bin/launcher.py" ;;
          *) printf '%s\n' "-p" "${k}=${v}" ;; esac ;;
      SupplementaryGroups) [ "$2" = 1 ] && printf '%s\n' "-p" "${k}=${v}" ;;
    esac
  done < "$1"
}

# check_script → o sh que roda DENTRO da unit transitória, sob o UID dinâmico. Só lê e usa access(2). Cada linha:
# OK|FALHA|AUSENTE <o quê>. $1 = com-grupo (0|1).
check_script() {
  local wg="$1" pid
  pid="$(systemctl show -p MainPID --value "${UNIT}" 2>/dev/null)"
  echo 'n_fail=0; ok() { echo "OK $*"; }; bad() { echo "FALHA $*"; n_fail=$((n_fail+1)); }'
  printf 'svc_uid=%q; home=%q; state=%q; ws=%q; hr=%q; pid=%q; probe=%q; wg=%q\n' \
    "$(id -u "${SVC_USER}" 2>/dev/null || echo x)" "${SVC_HOME}" "${STATE}" "${WS_ROOT}" "${HOME_ROOT}" "${pid}" "${PROBE_SLUG}" "${wg}"
  cat <<'EOS'
u="$(id -u)"
if [ "$u" != "$svc_uid" ] && [ "$u" != 0 ]; then ok "UID próprio ($u), não o da conta do serviço"; else bad "UID da unit é o do serviço ou root ($u)"; fi
# a home da conta do serviço: o .env, o PAT, a chave de deploy, o data/, o código e o clone servido
for p in "$home/onion-bridge/.env" "$home/.git-credentials" "$home/onion-bridge/data" "$home/onion-bridge/src/server.ts" \
         "$home/onion-evolve/docs/evolution/federation/members.yaml" "$home/.ssh"; do
  if [ -r "$p" ] || [ -w "$p" ]; then bad "alcança $p"; else ok "não alcança $p"; fi
done
# ProtectHome medido pela MONTAGEM, não pelo UID (refutador, achado 5: o -r acima passa só pela separação de UID)
hm="$(stat -c %a "$(dirname "$home")" 2>/dev/null)"
if [ "$hm" = 0 ] || ! stat "$home" >/dev/null 2>&1; then ok "a home do serviço some (ProtectHome: $(dirname "$home") modo ${hm:-inacessível})"
else bad "a home do serviço está visível ($(dirname "$home") modo $hm): ProtectHome não pegou"; fi
# o environ do processo do bridge (o segredo que o .env leva para a memória)
if [ -n "$pid" ] && [ "$pid" != 0 ]; then
  if [ -r "/proc/$pid/environ" ]; then bad "lê o environ do bridge (MainPID $pid)"; else ok "não lê o environ do bridge (MainPID $pid)"; fi
else echo "AUSENTE environ do bridge (sem MainPID)"; fi
# o resto do diretório de estado some; voltam só os workspaces e as HOMEs do CLI
# o TemporaryFileSystem medido pelo TIPO da montagem: com a ACL só de travessia no estado, o `ls` falharia vazio e o
# laço daria OK sem medir (refutador, achado 5)
fs="$(findmnt -no FSTYPE -T "$state" 2>/dev/null | head -1)"
if [ "$fs" != tmpfs ]; then bad "o estado do bridge NÃO é tmpfs na unit (montagem: ${fs:-?}): TemporaryFileSystem não pegou"
else
  extra=""; for e in $(ls -A "$state" 2>/dev/null); do case "$e" in workspaces|chat-homes) : ;; *) extra="$extra $e" ;; esac; done
  if [ -n "$extra" ]; then bad "o estado do bridge mostra:$extra"; else ok "o estado do bridge é tmpfs e só mostra workspaces e chat-homes"; fi
fi
for d in "$ws" "$hr"; do
  if [ "$wg" = 0 ]; then echo "AUSENTE travessia de $d (o --apply cria o grupo e as ACLs)"; continue; fi
  if [ -x "$d" ]; then ok "atravessa $d"; else bad "não atravessa $d (grupo/ACL)"; fi
  if ls "$d" >/dev/null 2>&1; then bad "LISTA $d (o vizinho seria achado pelo nome)"; else ok "não lista $d"; fi
done
if [ "$wg" = 1 ]; then
  for d in "$ws/$probe" "$hr/$probe"; do
    if [ -w "$d" ] && [ -x "$d" ]; then ok "grava no workspace de sonda $d"; else bad "não grava em $d"; fi
  done
fi
if [ -x /run/onion-chat-bin/claude ]; then ok "o CLI está ligado fora da home (/run/onion-chat-bin/claude)"; else bad "o CLI não está em /run/onion-chat-bin/claude"; fi
if /usr/bin/python3 -I /run/onion-chat-bin/launcher.py --check-config 2>/dev/null; then ok "o lançador aceita a configuração da unit"; else bad "o lançador recusa a configuração da unit (--check-config)"; fi
echo "n_fail=$n_fail"; [ "$n_fail" = 0 ]
EOS
}

run_sandbox_probe() {   # run_sandbox_probe <template> <com-grupo> <launcher> → imprime as linhas, rc 0 = n_fail 0
  local out rc props=()
  mapfile -t props < <(sandbox_props "$1" "$2" "$3")
  out="$(check_script "$2" | priv systemd-run --quiet --pipe --wait --collect "${props[@]}" /bin/sh -s 2>&1)"; rc=$?
  printf '%s\n' "${out}" | sed 's/^/    /'
  [ "${rc}" = 0 ] && grep -qx 'n_fail=0' <<<"${out}"
}

# o aperto de mão REAL pelo socket, como a conta do serviço: o initialize do SDK (o CLI responde sem chamar a API) e a
# recusa (flag fora da allowlist: zero byte de volta). Nenhuma chave vai no cabeçalho.
handshake() {
  as_svc /usr/bin/python3 -I - "${SOCKET}" "${WS_ROOT}/${PROBE_SLUG}" <<'PY'
import json, socket, sys, time
sock, cwd = sys.argv[1], sys.argv[2]
EXEC = "Bash,Monitor,PowerShell,REPL,Workflow,Task,Agent"
# a política mínima que o lançador exige: as ferramentas que executam E a escrita na config do próprio workspace
cfg = ["%s(/%s/%s)" % (v, cwd, t) for v in ("Edit", "Write", "NotebookEdit")
       for t in (".claude/**", "CLAUDE.md", "CLAUDE.local.md", ".mcp.json", ".git", ".git/**")]
settings = json.dumps({"permissions": {"deny": EXEC.split(",") + cfg}, "disableSkillShellExecution": True, "disableAllHooks": True})
args = ["--output-format", "stream-json", "--verbose", "--input-format", "stream-json", "--permission-prompt-tool", "stdio",
        "--disallowedTools", EXEC, "--tools", "Read", "--setting-sources=project", "--permission-mode", "default",
        "--managed-settings", '{"allowManagedHooksOnly":true}', "--settings", settings]
def conn(header, extra=b"", wait=30):
    s = socket.socket(socket.AF_UNIX); s.settimeout(wait); s.connect(sock)
    buf = b""; t0 = time.monotonic()
    try:
        s.sendall((json.dumps(header) + "\n").encode() + extra)
    except OSError:
        s.close(); return buf, time.monotonic() - t0
    try:
        while time.monotonic() - t0 < wait:
            c = s.recv(65536)
            if not c: break
            buf += c
            if b'"control_response"' in buf and buf.endswith(b"\n"): break
    except socket.timeout:
        pass
    except OSError:
        # a RECUSA do lançador chega como reset (ele fecha com bytes não lidos — medido no dogfood): é fim, não erro
        pass
    s.close(); return buf, time.monotonic() - t0
init = json.dumps({"type": "control_request", "request_id": "chat-runner-verify", "request": {"subtype": "initialize"}}).encode() + b"\n"
buf, dt = conn({"v": 1, "args": args, "cwd": cwd}, init)
okh = b'"control_response"' in buf and b'chat-runner-verify' in buf and b'"error"' not in buf.split(b'chat-runner-verify')[0][-200:]
print(("OK" if okh else "FALHA") + " aperto de mão pelo socket: o CLI respondeu ao initialize em %.1fs (%d bytes)" % (dt, len(buf)))
buf2, dt2 = conn({"v": 1, "args": args + ["--dangerously-skip-permissions"], "cwd": cwd}, wait=10)
okr = buf2 == b"" and dt2 < 9
print(("OK" if okr else "FALHA") + " recusa: flag fora da allowlist fecha a conexão sem um byte (%.1fs, %d bytes)" % (dt2, len(buf2)))
sys.exit(0 if okh and okr else 1)
PY
}

acl_has() {   # acl_has <caminho> <entrada exata do getfacl>
  priv getfacl -p --omit-header -- "$1" 2>/dev/null | grep -qx -- "$2"
}

# ── verify ──────────────────────────────────────────────────────────────────────────────────────────
verify_all() {
  local nf=0 f dst rc pid dp
  vbad() { echo "FALHA $*"; nf=$((nf + 1)); }
  vok()  { echo "OK $*"; }
  for f in "${SOCKET_UNIT}:${UNIT_DIR}/${SOCKET_UNIT}" "${TEMPLATE_UNIT}:${UNIT_DIR}/${TEMPLATE_UNIT}" \
           "launcher.py:${LIBEXEC}/launcher.py" "${DROPIN_NAME}:${DROPIN_DIR}/${DROPIN_NAME}"; do
    dst="${f#*:}"
    if ! priv test -f "${dst}"; then vbad "não instalado: ${dst}"; continue; fi
    if priv cmp -s "${TMPD}/${f%%:*}" "${dst}"; then vok "instalado = renderizado do bridge servido: ${dst}"
    else vbad "instalado DIFERE do renderizado do bridge servido (deploy do bridge sem reinstalar?): ${dst}"; fi
  done
  if getent group "${GROUP}" >/dev/null 2>&1; then vok "grupo ${GROUP} existe"; else vbad "grupo ${GROUP} ausente"; fi
  acl_has "${STATE}" "group:${GROUP}:--x" && vok "o estado é só travessia para o grupo" || vbad "ACL do estado sem group:${GROUP}:--x (${STATE})"
  for d in "${WS_ROOT}" "${HOME_ROOT}"; do
    acl_has "${d}" "group:${GROUP}:--x" && acl_has "${d}" "default:group:${GROUP}:rwx" && acl_has "${d}" "default:user:${SVC_USER}:rwx" \
      && vok "ACL de ${d}: travessia (sem listar) e o padrão para o que nascer dentro" || vbad "ACL de ${d} incompleta"
  done
  if priv test -L "${SOCKET}" || ! priv test -S "${SOCKET}"; then vbad "o socket ${SOCKET} não existe (ou é symlink)"
  elif [ "$(systemctl is-active "${SOCKET_UNIT}" 2>/dev/null)" = active ]; then vok "${SOCKET_UNIT} ativo em ${SOCKET}"
  else vbad "${SOCKET_UNIT} não está ativo"; fi
  echo "-- sandbox do template INSTALADO (unit transitória sob UID dinâmico):"
  if priv test -f "${UNIT_DIR}/${TEMPLATE_UNIT}"; then
    priv cat "${UNIT_DIR}/${TEMPLATE_UNIT}" > "${TMPD}/installed.service"
    run_sandbox_probe "${TMPD}/installed.service" 1 "${LIBEXEC}/launcher.py" || vbad "o sandbox do template instalado reprovou (linhas FALHA acima)"
  else vbad "sem template instalado para medir o sandbox"; fi
  echo "-- pelo socket, como a conta do serviço:"
  handshake | sed 's/^/    /'; rc="${PIPESTATUS[0]}"
  [ "${rc}" = 0 ] || vbad "o aperto de mão ou a recusa pelo socket reprovou"
  pid="$(systemctl show -p MainPID --value "${UNIT}" 2>/dev/null)"
  dp="$(systemctl show -p DropInPaths --value "${UNIT}" 2>/dev/null)"
  case " ${dp} " in *"/${DROPIN_NAME} "*) vok "o ${DROPIN_NAME} está carregado na unit ${UNIT}" ;; *) vbad "o ${DROPIN_NAME} NÃO está carregado na unit ${UNIT}" ;; esac
  if [[ "${pid}" =~ ^[1-9][0-9]*$ ]] && [ "$(priv grep -czx -- "CHAT_RUNNER_SOCKET=${SOCKET}" "/proc/${pid}/environ" 2>/dev/null)" -ge 1 ] 2>/dev/null; then
    vok "o processo vivo do bridge (MainPID ${pid}) tem CHAT_RUNNER_SOCKET=${SOCKET}"
  else vbad "o processo vivo do bridge não tem CHAT_RUNNER_SOCKET=${SOCKET} (MainPID ${pid:-?}; o valor nunca é impresso)"; fi
  echo "n_fail=${nf}"
  [ "${nf}" = 0 ] && say "verify OK — runner instalado, sandbox e aperto de mão provados, ligado no processo vivo"
  [ "${nf}" = 0 ]
}
if [ "${SUB}" = verify ]; then verify_all; exit $?; fi

# ── install: pré-voo ─────────────────────────────────────────────────────────────────────────────────
systemctl cat "${UNIT}" >/dev/null 2>&1 || die 2 "a unit ${UNIT} não existe (ou não li)"
# o degrau 1 é PRÉ-CONDIÇÃO: com ele o clone servido (de onde as fontes vêm) é só-leitura para o agente dentro da unit
case " $(systemctl show -p DropInPaths --value "${UNIT}" 2>/dev/null) " in *"/30-integrity.conf "*) : ;;
  *) die 1 "o degrau 1 (30-integrity.conf) não está carregado em ${UNIT}: instale-o antes (ops/bridge-hardening.sh)" ;; esac
for p in "${STATE}" "${WS_ROOT}"; do
  priv test -d "${p}" || die 1 "premissa mudou: ${p} não existe"
  [ "$(priv realpath -m -- "${p}")" = "${p}" ] || die 1 "${p} tem SYMLINK no caminho: recusado (a ACL e o bind seguiriam o link)"
done
priv test -e "${HOME_ROOT}" && { [ "$(priv realpath -m -- "${HOME_ROOT}")" = "${HOME_ROOT}" ] && priv test -d "${HOME_ROOT}" \
  || die 1 "${HOME_ROOT} existe e não é diretório real: recusado"; }
priv test -x "${CLAUDE_SRC}" || die 1 "o CLI do SDK não está em ${CLAUDE_SRC} (o template o liga por bind)"
command -v setfacl >/dev/null 2>&1 && command -v getfacl >/dev/null 2>&1 || die 2 "setfacl/getfacl ausentes (pacote acl)"
[ -x /usr/bin/python3 ] || die 2 "/usr/bin/python3 ausente (o lançador é python)"
if priv test -e "${SOCKET}" && ! systemctl cat "${SOCKET_UNIT}" >/dev/null 2>&1; then
  die 1 "${SOCKET} já existe e não é do ${SOCKET_UNIT}: recusado"
fi
for f in "${UNIT_DIR}/${SOCKET_UNIT}" "${UNIT_DIR}/${TEMPLATE_UNIT}" "${DROPIN_DIR}/${DROPIN_NAME}"; do
  if priv test -e "${f}"; then
    [ "$(priv realpath -m -- "${f}")" = "${f}" ] || die 1 "${f} é symlink: recusado"
    priv grep -qxF "${MARKER}" "${f}" || say "AVISO: ${f} já existe e NÃO foi gerado por este wrapper (sem o marcador): vai para o backup antes da troca"
  fi
done

# ── diferença para o instalado ───────────────────────────────────────────────────────────────────────
changed=0
for f in "${SOCKET_UNIT}:${UNIT_DIR}/${SOCKET_UNIT}" "${TEMPLATE_UNIT}:${UNIT_DIR}/${TEMPLATE_UNIT}" \
         "launcher.py:${LIBEXEC}/launcher.py" "${DROPIN_NAME}:${DROPIN_DIR}/${DROPIN_NAME}"; do
  dst="${f#*:}"
  if priv test -f "${dst}"; then
    if priv cmp -s "${TMPD}/${f%%:*}" "${dst}"; then say "igual ao instalado: ${dst}"
    else changed=1; say "diferença para ${dst}:"; diff -u <(priv cat "${dst}") "${TMPD}/${f%%:*}" | sed 's/^/    /'; fi
  else
    changed=1; say "NOVO: ${dst}"
  fi
done
group_ok=0; getent group "${GROUP}" >/dev/null 2>&1 && group_ok=1
[ "${group_ok}" = 1 ] || { changed=1; say "grupo a criar no --apply: ${GROUP} (sistema)"; }
priv test -d "${HOME_ROOT}" || { changed=1; say "a criar no --apply: ${HOME_ROOT} (dono ${SVC_USER}, 0750)"; }

if [ "${changed}" = 0 ]; then
  # idêntico no disco não é o mesmo que valendo: o NOOP só com o verify inteiro (o mesmo do bridge-hardening, achado 4)
  if verify_all >/dev/null 2>&1; then
    say "NOOP — units, lançador e drop-in idênticos ao renderizado, grupo e ACLs no lugar, verify do vivo passa. Nada tocado."
    exit 0
  fi
  say "tudo idêntico no disco, mas o verify NÃO passa: segue para reaplicar e reiniciar"
fi

# ── ensaio: unit TRANSITÓRIA com o sandbox do template renderizado ───────────────────────────────────
say "ensaio numa unit transitória (systemd-run --collect, nada persistente) com o sandbox do template renderizado:"
if ! run_sandbox_probe "${TMPD}/${TEMPLATE_UNIT}" "${group_ok}" "${TMPD}/launcher.py"; then
  say "o ENSAIO reprovou: nada foi escrito. Leia as linhas FALHA acima."; exit 1
fi
if [ "${APPLY}" = 0 ]; then
  say "ENSAIO OK: nada foi escrito. Para instalar, repita com --apply (cria o grupo ${GROUP}, ACLs em ${STATE}, as units e o drop-in, e reinicia ${UNIT})."
  say "o --apply exige root (sudo) e é do maestro:  ! bash ops/chat-runner.sh install --apply"
  exit 0
fi

# ── --apply ──────────────────────────────────────────────────────────────────────────────────────────
grep -q '"ok":true' <<<"$(curl -fsS -m 5 "${HEALTH_LOCAL}" 2>/dev/null)" \
  || die 2 "/health já está doente ANTES da instalação — triagem primeiro (não se reinicia serviço doente)"
TS="$(date +%Y%m%d-%H%M%S)"
BK="${BACKUP_DIR}/${TS}"
priv install -d -m 0700 "${BACKUP_DIR}" "${BK}" || die 2 "não criei o diretório de backup ${BK}"
# as ACLs de hoje do estado inteiro: o rollback é setfacl --restore deste arquivo
priv sh -c 'getfacl -R -P -p "$1" > "$2"' _ "${STATE}" "${BK}/acl-state.txt" || die 2 "backup das ACLs falhou: sem rede de segurança não se troca"
for f in "${UNIT_DIR}/${SOCKET_UNIT}" "${UNIT_DIR}/${TEMPLATE_UNIT}" "${LIBEXEC}/launcher.py" "${DROPIN_DIR}/${DROPIN_NAME}"; do
  if priv test -f "${f}"; then priv install -m 0600 "${f}" "${BK}/$(basename "${f}")" || die 2 "backup de ${f} falhou"; fi
done
say "backup em ${BK} (ACLs do estado + o que havia instalado)"
created_group=0; created_home=0; installed_dropin=0

rollback() {
  echo "[${NAME}] ─── ROLLBACK MANUAL (do maestro, fora da sessão: \`!\` no prompt) ───" >&2
  if [ "${installed_dropin}" = 1 ]; then
    cat >&2 <<EOF
  sudo rm -f ${DROPIN_DIR}/${DROPIN_NAME}
  sudo systemctl daemon-reload && sudo systemctl reset-failed ${UNIT} && sudo systemctl restart ${UNIT}
  curl -fsS ${HEALTH_LOCAL}
EOF
  fi
  echo "  sudo systemctl disable --now ${SOCKET_UNIT}" >&2
  local f
  for f in "${SOCKET_UNIT}" "${TEMPLATE_UNIT}"; do
    if [ -f "${BK}/${f}" ]; then echo "  sudo install -m 0644 ${BK}/${f} ${UNIT_DIR}/${f}   # volta o anterior" >&2
    else echo "  sudo rm -f ${UNIT_DIR}/${f}" >&2; fi
  done
  if [ -f "${BK}/launcher.py" ]; then echo "  sudo install -m 0644 ${BK}/launcher.py ${LIBEXEC}/launcher.py" >&2
  else echo "  sudo rm -rf ${LIBEXEC}" >&2; fi
  echo "  sudo systemctl daemon-reload" >&2
  # NÃO `setfacl --restore` (refutador, achado 2, provado: segue um componente trocado e restaura dono e modo fora do
  # estado); tira só as entradas que este wrapper pôs, como a dona, sem seguir symlink (-P). O backup fica como registro.
  echo "  sudo setfacl -x g:${GROUP} -- ${STATE}" >&2
  echo "  sudo -u ${SVC_USER} setfacl -R -P -x g:${GROUP},u:${SVC_USER},d:g:${GROUP},d:u:${SVC_USER} -- ${WS_ROOT} ${HOME_ROOT}   # registro em ${BK}/acl-state.txt" >&2
  [ "${created_home}" = 1 ] && echo "  sudo rm -rf ${HOME_ROOT}   # criado nesta execução (só HOMEs do CLI do runner)" >&2
  [ "${created_group}" = 1 ] && echo "  sudo groupdel ${GROUP}   # criado nesta execução" >&2
  return 0
}
fail_after() { printf '[%s] ERRO: %s\n' "${NAME}" "$1" >&2; rollback; exit 1; }

if [ "${group_ok}" = 0 ]; then
  priv groupadd --system "${GROUP}" || fail_after "groupadd ${GROUP} falhou"
  created_group=1; say "grupo ${GROUP} criado"
fi
if ! priv test -d "${HOME_ROOT}"; then
  as_svc mkdir -m 0750 -- "${HOME_ROOT}" || fail_after "não criei ${HOME_ROOT}"
  created_home=1
fi
# ACLs: o estado e as duas raízes são SÓ travessia para o grupo (não lista: o vizinho só pelo nome); o PADRÃO das
# raízes dá ao grupo e à conta do serviço rwx no que nascer dentro (vence a umask 0027 do bridge e a 0007 do runner);
# o que já existe ganha o mesmo, sem seguir symlink (-P)
# Só o estado em si é do root (o nome dele mora em /var/lib, que a conta do serviço não escreve). As raízes e o que existe
# dentro delas são da CONTA DO SERVIÇO: o setfacl roda como ELA (refutador, passada 1, achado 1, provado: como root, um
# symlink trocado entre o pré-voo e o setfacl punha a ACL padrão num diretório à escolha de quem controla o estado).
# Como a dona, um symlink só a leva aonde ela já escreve. O que os UIDs dinâmicos criaram já nasceu com a ACL padrão
# (só a dona muda a ACL de um arquivo: o -user a restringe ao que é dela)
priv setfacl -m "g:${GROUP}:--x" -- "${STATE}" || fail_after "setfacl em ${STATE} falhou"
for d in "${WS_ROOT}" "${HOME_ROOT}"; do
  as_svc setfacl -m "g:${GROUP}:--x,d:g:${GROUP}:rwx,d:u:${SVC_USER}:rwx,d:m::rwx" -- "${d}" || fail_after "setfacl em ${d} falhou"
  as_svc find "${d}" -mindepth 1 -xdev -user "${SVC_USER}" \( -type f -o -type d \) -exec setfacl -m "g:${GROUP}:rwX,u:${SVC_USER}:rwX" -- {} + \
    || fail_after "ACL do grupo no que já existe em ${d} falhou"
  as_svc find "${d}" -mindepth 1 -xdev -user "${SVC_USER}" -type d -exec setfacl -m "d:g:${GROUP}:rwx,d:u:${SVC_USER}:rwx,d:m::rwx" -- {} + \
    || fail_after "ACL padrão no que já existe em ${d} falhou"
done
say "ACLs aplicadas: ${STATE} (travessia), ${WS_ROOT} e ${HOME_ROOT} (travessia + padrão), e cada workspace/HOME existente"
for d in "${WS_ROOT}/${PROBE_SLUG}" "${HOME_ROOT}/${PROBE_SLUG}"; do
  as_svc mkdir -p -- "${d}" || fail_after "não criei o workspace de sonda ${d}"
done
own=(-o root -g root); [ "${TEST}" = 1 ] && own=()
priv install "${own[@]}" -d -m 0755 "${LIBEXEC}" || fail_after "não criei ${LIBEXEC}"
priv install "${own[@]}" -m 0644 "${TMPD}/launcher.py" "${LIBEXEC}/launcher.py" || fail_after "não instalei o lançador"
priv install "${own[@]}" -m 0644 "${TMPD}/${SOCKET_UNIT}" "${UNIT_DIR}/${SOCKET_UNIT}" || fail_after "não instalei ${SOCKET_UNIT}"
priv install "${own[@]}" -m 0644 "${TMPD}/${TEMPLATE_UNIT}" "${UNIT_DIR}/${TEMPLATE_UNIT}" || fail_after "não instalei ${TEMPLATE_UNIT}"
priv systemctl daemon-reload || fail_after "daemon-reload falhou"
priv systemctl enable "${SOCKET_UNIT}" >/dev/null 2>&1 || fail_after "enable ${SOCKET_UNIT} falhou"
priv systemctl restart "${SOCKET_UNIT}" || fail_after "restart ${SOCKET_UNIT} falhou"
say "lançador e units instalados; ${SOCKET_UNIT} ativo"
# o runner tem de responder ANTES de o bridge passar a usá-lo
handshake | sed 's/^/    /'; [ "${PIPESTATUS[0]}" = 0 ] || fail_after "o aperto de mão pelo socket reprovou: o bridge NÃO foi ligado ao runner"

priv install -d -m 0755 "${DROPIN_DIR}" || fail_after "não criei ${DROPIN_DIR}"
priv install "${own[@]}" -m 0644 "${TMPD}/${DROPIN_NAME}" "${DROPIN_DIR}/${DROPIN_NAME}" || fail_after "não instalei o ${DROPIN_NAME}"
installed_dropin=1
priv systemctl daemon-reload || fail_after "daemon-reload falhou"
OLD_INV="$(systemctl show -p InvocationID --value "${UNIT}" 2>/dev/null)"
priv systemctl restart "${UNIT}" || fail_after "systemctl restart ${UNIT} recusou (journalctl -u ${UNIT})"
up=0
for _ in $(seq 1 15); do
  if grep -q '"ok":true' <<<"$(curl -fsS -m 3 "${HEALTH_LOCAL}" 2>/dev/null)"; then up=1; break; fi
  sleep 2
done
[ "${up}" = 1 ] || fail_after "/health não voltou em ~30s depois do restart"
INV="$(systemctl show -p InvocationID --value "${UNIT}" 2>/dev/null)"
[ -n "${INV}" ] && [ "${INV}" != "${OLD_INV}" ] || fail_after "a invocação não mudou (${INV:-?}): o restart não aconteceu e a prova seria do boot antigo"
BOOT=""
for _ in $(seq 1 10); do
  BOOT="$(priv journalctl "_SYSTEMD_INVOCATION_ID=${INV}" --no-pager 2>/dev/null || true)"
  grep -q "auth: enforce" <<<"${BOOT}" && grep -q "chat-runner: LIGADO" <<<"${BOOT}" && break
  sleep 2
done
grep -q "auth: enforce" <<<"${BOOT}" || fail_after "boot desta invocação sem 'auth: enforce'"
grep -q "chat-runner: LIGADO" <<<"${BOOT}" || fail_after "boot desta invocação sem 'chat-runner: LIGADO' (o bridge servido não tem o runner?)"
grep -q "chat-runner LIGADO sem ANTHROPIC_API_KEY" <<<"${BOOT}" && fail_after "o bridge ligou o runner SEM chave da API: o /chat de convidado falharia"
verify_all || fail_after "o verify reprovou depois do restart"
say "OK — runner instalado e ligado (bridge ${BRIDGE_HEAD}, invocação ${INV:0:8}); o /chat de CONVIDADO roda sob UID próprio"
rollback 2>&1 | sed 's/^/  (se precisar) /'
exit 0
