#!/usr/bin/env bash
# slack-persona.sh — a persona do Company Brain no Slack, em modo rascunho: a unit onion-slack-persona (core-only).
#
# POR QUE EXISTE (2026-11-06, degrau 2 do plano docs/onion/graph/comms-stable-2026-11.kg.yaml, nó
# Q_CS_DEGRAU2_SLACK_RASCUNHO_1109; runtime A de D_PERSONA_RUNTIME_2026_11): o código da persona mora no bridge
# (src/slack-persona/, deploy/slack-persona/); este wrapper instala a unit a partir do bridge SERVIDO e guarda os
# segredos como credencial do systemd CIFRADA (systemd-creds encrypt, chave do host, só root lê a origem), como selou o
# maestro em D_MESSAGING_SEGREDOS_VAULTWARDEN_SYSTEMD_1106: a fonte única é o Vaultwarden, e o maestro cola cada token
# numa entrada OCULTA deste script rodado com `!`. O segredo nunca passa por argv, .env, chat nem arquivo em claro: vai
# do terminal (read -s) por pipe para o systemd-creds. Molde: ops/stt-service.sh e ops/chat-runner.sh (recusa root,
# ensaio por padrão, backup, rollback impresso, prova depois).
#
# USO
#   ops/slack-persona.sh creds [--kg-from-mcp-conf] [nome…]   guarda as credenciais (pergunta cada uma, entrada oculta)
#   ops/slack-persona.sh install [--apply]                    ensaio (padrão) ou instalação da unit e da config
#   ops/slack-persona.sh start                                liga (enable --now) e prova a conexão DESTA invocação
#   ops/slack-persona.sh verify                               só leitura: unit, credenciais, config, processo vivo (espera a conexão até 45 s)
#   (a bancada é ops/testing/slack-persona-selftest.sh: falsos no PATH, sem sudo)
#
#   nomes: slack-bot-token (xoxb-…), slack-app-token (xapp-…), anthropic-api-key (sk-ant-…), kg-token.
#   --kg-from-mcp-conf: o kg-token sai do ONION_KG_TOKEN de /etc/onion-vps-mcp-kg-granaai.conf, por pipe dentro do
#   root (ninguém o vê nem o cola). Credencial que já existe só é trocada com confirmação.
#   install sem --apply é ENSAIO: mostra a diferença entre a unit servida e a instalada e o que falta na config.
#   start recusa subir com a config de exemplo (IDs U0000…/C0000…) ou faltando credencial.
#
# EXIT: 0 ok · 1 problema medido ou recusado · 2 não pude medir (sudo, unit, journal) · 3 uso inválido
#
# MODO DE TESTE (só pela bancada ops/testing/slack-persona-selftest.sh): ONION_SLACK_PERSONA_TEST=1 com ONION_SLACK_PERSONA_ROOT (a raiz falsa onde caem
#   /etc, a unit, o credstore, o bridge servido e o backup). Nele nada passa por sudo, e systemctl, systemd-creds,
#   systemd-analyze e journalctl vêm do PATH. Qualquer ONION_SLACK_PERSONA_* sem o modo de teste é uso inválido (rc 3).
set -uo pipefail

NAME=slack-persona
UNIT=onion-slack-persona
CRED_NAMES=(slack-bot-token slack-app-token anthropic-api-key kg-token)

say()  { printf '[%s] %s\n' "${NAME}" "$*"; }
die()  { local rc="$1"; shift; printf '[%s] ERRO: %s\n' "${NAME}" "$*" >&2; exit "${rc}"; }
usage() { sed -n '/^# USO/,/^# EXIT/p' "$0" | sed '$d; s/^# \{0,1\}//' >&2; exit 3; }

TEST="${ONION_SLACK_PERSONA_TEST:-0}"
if [ "${TEST}" != 1 ] && grep -q '^ONION_SLACK_PERSONA_' <<< "$(env)"; then
  die 3 "variável ONION_SLACK_PERSONA_* sem o modo de teste: produção não se redireciona por ambiente"
fi
R=""
if [ "${TEST}" = 1 ]; then
  R="${ONION_SLACK_PERSONA_ROOT:?modo de teste sem ONION_SLACK_PERSONA_ROOT}"
  case "${R}" in /tmp/*|/var/tmp/*) ;; *) die 3 "a raiz de teste tem de estar em /tmp: ${R}" ;; esac
fi
UNIT_DIR="${R}/etc/systemd/system"
ETC="${R}/etc/onion-slack-persona"
CREDSTORE="${R}/etc/credstore.encrypted"
SERVED="${R}/home/onion/onion-bridge/deploy/slack-persona"
BACKUP="${R}/var/backups/onion-slack-persona"
MCP_CONF="${R}/etc/onion-vps-mcp-kg-granaai.conf"
TTY="${ONION_SLACK_PERSONA_TTY:-/dev/tty}"

priv() { if [ "${TEST}" = 1 ]; then "$@"; else sudo -n "$@"; fi; }
SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# ── CÓPIA DE ROOT DELEGADA (D_DELEGATE_VPS_SERVICE_SCRIPTS_1113, selado pelo maestro em 2026-11-13) ─────────────────
# A sessão roda o update do bridge e a persona do Slack por uma regra de sudoers sem senha que aponta CÓPIAS de root
# destes scripts em /usr/local/lib/onion-ops (root:root, 0755), instaladas e conferidas por sha256 contra a origin/main
# pelo ops/delegated-ops.sh (core-only). NOPASSWD no script do repo seria root completo: quem edita o script vira root.
# 0 = rodando como root, a partir da cópia, com o diretório e o arquivo do root e sem escrita de grupo nem de outros.
ONION_DELEGATED_DIR=/usr/local/lib/onion-ops
onion_delegated_root() {
  [ "$(id -u)" = 0 ] && [ "${SELF_DIR}" = "${ONION_DELEGATED_DIR}" ] || return 1
  local _m _p
  for _m in "${SELF_DIR}" "${SELF_DIR}/$(basename "${BASH_SOURCE[0]}")"; do
    [ -L "${_m}" ] && return 1
    [ "$(stat -c '%u' "${_m}" 2>/dev/null)" = 0 ] || return 1
    _p="$(stat -c '%A' "${_m}" 2>/dev/null)"; [ "${_p:5:1}" = - ] && [ "${_p:8:1}" = - ] || return 1
  done
}
# Pela cópia: install, start e verify. O creds (a entrada oculta dos tokens) segue com o maestro, pelo checkout, com `!`.
if [ "$(id -u)" = 0 ] && [ "${TEST}" != 1 ]; then
  onion_delegated_root || die 3 "rode como o operador (o script chama sudo onde precisa), não como root (a exceção é a cópia de root delegada em ${ONION_DELEGATED_DIR})"
  case "${1:-}" in
    install|start|verify) : ;;
    *) die 3 "a cópia de root delegada roda só install, start e verify; '${1:-}' segue com o maestro, pelo checkout, com \`!\` (D_DELEGATE_VPS_SERVICE_SCRIPTS_1113)" ;;
  esac
fi
need_sudo() { [ "${TEST}" = 1 ] || sudo -n true 2>/dev/null || die 2 "sudo sem senha indisponível (rode pelo \`!\` do maestro)"; }

cred_path() { printf '%s/%s.%s' "${CREDSTORE}" "${UNIT}" "$1"; }
cred_prefix() {
  case "$1" in
    slack-bot-token) echo "xoxb-" ;; slack-app-token) echo "xapp-" ;; anthropic-api-key) echo "sk-ant-" ;; kg-token) echo "" ;;
    *) return 1 ;;
  esac
}

# um segredo do terminal para o systemd-creds, sem passar por argv, variável exportada nem arquivo em claro
store_cred() {  # <nome>
  local n="$1" dest pre v
  pre="$(cred_prefix "${n}")" || die 3 "credencial desconhecida: ${n} (válidas: ${CRED_NAMES[*]})"
  dest="$(cred_path "${n}")"
  if priv test -e "${dest}"; then
    local a=""; printf '[%s] %s já existe. Trocar? [s/N] ' "${NAME}" "${n}" >&2; IFS= read -r a < "${TTY}" || a=""
    [ "${a}" = s ] || [ "${a}" = S ] || { say "${n}: mantida"; return 0; }
  fi
  printf '[%s] cole o %s do Vaultwarden (não aparece na tela) e Enter: ' "${NAME}" "${n}" >&2
  IFS= read -rs v < "${TTY}" || v=""; printf '\n' >&2
  v="${v//[$'\r\n\t ']/}"
  if [ -z "${v}" ]; then die 1 "${n}: vazio, nada foi gravado"; fi
  if [ -n "${pre}" ] && [ "${v#"${pre}"}" = "${v}" ]; then v=""; die 1 "${n}: não começa com ${pre} (token trocado de lugar?), nada foi gravado"; fi
  priv install -d -m 0700 "${CREDSTORE}"
  if ! printf '%s' "${v}" | priv systemd-creds encrypt --name="${n}" - "${dest}.new"; then
    v=""; priv rm -f "${dest}.new"; die 2 "${n}: systemd-creds encrypt falhou, nada foi trocado"
  fi
  v=""
  priv chmod 0600 "${dest}.new" && priv mv -f "${dest}.new" "${dest}" || die 2 "${n}: não troquei o arquivo"
  say "${n}: guardada cifrada em ${dest}"
}

store_kg_from_conf() {
  local dest; dest="$(cred_path kg-token)"
  priv test -r "${MCP_CONF}" || die 1 "não há ${MCP_CONF} legível pelo root"
  priv grep -q '^ONION_KG_TOKEN=..' "${MCP_CONF}" || die 1 "${MCP_CONF} sem ONION_KG_TOKEN"
  priv install -d -m 0700 "${CREDSTORE}"
  # o token vai do arquivo do root ao systemd-creds por pipe dentro do root: não passa pelo shell do operador
  if ! priv sh -c 'sed -n "s/^ONION_KG_TOKEN=//p" "$1" | head -1 | tr -d "\r\n\"'"'"'" | systemd-creds encrypt --name=kg-token - "$2"' _ "${MCP_CONF}" "${dest}.new"; then
    priv rm -f "${dest}.new"; die 2 "kg-token: systemd-creds encrypt falhou"
  fi
  priv chmod 0600 "${dest}.new" && priv mv -f "${dest}.new" "${dest}" || die 2 "kg-token: não troquei o arquivo"
  say "kg-token: copiado do ONION_KG_TOKEN do MCP do Brain, cifrado em ${dest}"
}

cmd_creds() {
  need_sudo
  local from_conf=0 names=()
  for a in "$@"; do
    case "${a}" in --kg-from-mcp-conf) from_conf=1 ;; -*) usage ;; *) names+=("${a}") ;; esac
  done
  [ "${#names[@]}" -eq 0 ] && names=("${CRED_NAMES[@]}")
  # a entrada oculta precisa de terminal: sem ele (um `!` sem TTY, um pipe), recusa ANTES de tocar em qualquer coisa
  local needs_tty=0
  for n in "${names[@]}"; do [ "${n}" = kg-token ] && [ "${from_conf}" = 1 ] || needs_tty=1; done
  if [ "${needs_tty}" = 1 ] && ! { : < "${TTY}"; } 2>/dev/null; then
    die 2 "sem terminal para a entrada oculta (${TTY}): rode num terminal SSH/mosh, não por pipe nem por \`!\` sem TTY"
  fi
  for n in "${names[@]}"; do
    if [ "${n}" = kg-token ] && [ "${from_conf}" = 1 ]; then store_kg_from_conf; else store_cred "${n}"; fi
  done
}

missing_creds() { local n; for n in "${CRED_NAMES[@]}"; do priv test -s "$(cred_path "${n}")" || echo "${n}"; done; }
config_problem() {
  priv test -s "${ETC}/config.json" || { echo "sem ${ETC}/config.json"; return; }
  if priv grep -Eq '"[UC]0000' "${ETC}/config.json"; then echo "a config ainda tem os IDs de exemplo (U0000…/C0000…)"; fi
}

# o que o root COPIA do bridge servido (a home da conta do serviço) tem de ser arquivo regular lá dentro: um symlink
# plantado faria o root copiar o alvo dele (o /etc/shadow virando a unit 0644). Vale pelo checkout e pela cópia delegada.
served_regular() {
  local r; r="$(priv realpath -e -- "$1" 2>/dev/null)" || return 1
  case "${r}" in "${SERVED%/deploy/slack-persona}/"*) ;; *) return 1 ;; esac
  priv test -f "${r}" && ! priv test -L "$1"
}

# ── A UNIT QUE O ROOT INSTALA (refutador do #1647, B5, 2026-11-13) ─────────────────────────────────────────────────
# A unit vem do bridge servido, que a conta `onion` escreve (e que o merge na main do bridge muda, puxado pelo
# update-bridge). Copiada verbatim pelo root, `User=root` e um ExecStart qualquer seriam root para quem escreve lá. Então:
#   1. o conteúdo se LÊ COMO O DONO do bridge servido (sudo -u onion), uma vez só: um symlink plantado só alcança o que
#      o onion já lê, e não há janela entre conferir e copiar (o TOCTOU do served_regular com o `install` do root);
#   2. a unit passa por uma ALLOWLIST FECHADA de diretivas: chave fora da lista recusa, e as que decidem quem o processo é
#      e o que ele roda têm valor FIXO (DynamicUser=yes, User, SupplementaryGroups, ExecStart, WorkingDirectory, os binds,
#      as quatro credenciais, capacidades vazias). Nenhuma Exec* além do ExecStart, nenhum prefixo `+`/`!`/`@`;
#   3. o root instala o TEXTO conferido, de um diretório temporário dele, nunca o arquivo do bridge.
# Mudar a unit no bridge numa dessas diretivas exige mudar esta lista no core (PR revisado): é o preço declarado.
as_owner() { if [ "${TEST}" = 1 ]; then "$@"; else sudo -n -u onion -- "$@"; fi; }
unit_allowlist_check() { # stdin = a unit; rc 0 = cabe na allowlist; imprime o motivo da recusa
  python3 -I -c '
import re, sys
FIX = {
  ("Service", "Type"): {"simple"}, ("Service", "DynamicUser"): {"yes"}, ("Service", "User"): {"onion-slack-persona"},
  ("Service", "SupplementaryGroups"): {"onion-brain-hub"},
  ("Service", "StateDirectory"): {"onion-slack-persona"}, ("Service", "StateDirectoryMode"): {"0700"},
  ("Service", "RuntimeDirectory"): {"onion-slack-persona"}, ("Service", "RuntimeDirectoryMode"): {"0755"},
  ("Service", "ConfigurationDirectory"): {"onion-slack-persona"},
  ("Service", "Environment"): {"ONION_SLACK_PERSONA_CONFIG=/etc/onion-slack-persona/config.json", "NODE_ENV=production"},
  ("Service", "LoadCredentialEncrypted"): {"%s:/etc/credstore.encrypted/onion-slack-persona.%s" % (n, n)
      for n in ("slack-bot-token", "slack-app-token", "anthropic-api-key", "kg-token")},
  ("Service", "BindReadOnlyPaths"): {"/home/onion/onion-bridge:/run/onion-slack-persona-app"},
  ("Service", "InaccessiblePaths"): {"-/run/onion-slack-persona-app/.env -/run/onion-slack-persona-app/data -/run/onion-slack-persona-app/workspaces"},
  ("Service", "WorkingDirectory"): {"/run/onion-slack-persona-app"},
  ("Service", "ExecStart"): {"/usr/bin/node /run/onion-slack-persona-app/node_modules/tsx/dist/cli.mjs src/slack-persona/main.ts"},
  ("Service", "Restart"): {"on-failure"}, ("Service", "SuccessExitStatus"): {"143"}, ("Service", "UMask"): {"0077"},
  ("Service", "ProtectProc"): {"invisible"}, ("Service", "ProcSubset"): {"pid"},
  ("Service", "CapabilityBoundingSet"): {""}, ("Service", "AmbientCapabilities"): {""},
  ("Service", "SystemCallArchitectures"): {"native"}, ("Service", "RestrictAddressFamilies"): {"AF_UNIX AF_INET AF_INET6"},
  ("Install", "WantedBy"): {"multi-user.target"},
}
YES = {"PrivateTmp", "PrivateDevices", "ProtectHome", "ProtectKernelTunables", "ProtectKernelModules", "ProtectKernelLogs",
       "ProtectControlGroups", "ProtectClock", "ProtectHostname", "RestrictNamespaces", "RestrictRealtime",
       "RestrictSUIDSGID", "LockPersonality", "NoNewPrivileges"}
for k in YES:
    FIX[("Service", k)] = {"yes"}
FREE = {("Unit", "Description"): r"[ -Z\]-~]{1,200}", ("Unit", "After"): r"[A-Za-z0-9@._ -]+", ("Unit", "Wants"): r"[A-Za-z0-9@._ -]+",
        ("Service", "RestartSec"): r"[0-9]{1,4}", ("Service", "MemoryMax"): r"[0-9]{1,6}[KMG]?", ("Service", "TasksMax"): r"[0-9]{1,5}"}
REQ = {("Service", "DynamicUser"), ("Service", "User"), ("Service", "ExecStart"), ("Service", "WorkingDirectory"),
       ("Service", "CapabilityBoundingSet"), ("Service", "BindReadOnlyPaths")}
sec, seen, bad = None, set(), []
# N3 da re-refutação do #1647: o systemd parte linha também em \r, e um Description com "\r[Service]\rExecStartPre=+…"
# passava aqui como UMA linha e lá virava três (root). Caractere de controle (fora o \n) no texto inteiro recusa ANTES
# do parse, as linhas se partem em \r e \n, e o Description é só imprimível ASCII sem colchete nem barra invertida.
txt = sys.stdin.read()
ctl = sorted(set("%r" % c for c in txt if (ord(c) < 32 and c != "\n") or ord(c) == 127))
if ctl:
    print("caractere de controle na unit: %s" % ", ".join(ctl[:5]))
    sys.exit(1)
for n, ln in enumerate(re.split(r"[\r\n]", txt), 1):
    t = ln.strip()
    if not t or t[0] in "#;":
        continue
    if t.endswith("\\"):
        bad.append("linha %d: continuação de linha" % n); continue
    m = re.fullmatch(r"\[(Unit|Service|Install)\]", t)
    if m:
        sec = m.group(1); continue
    if t.startswith("["):
        bad.append("linha %d: seção fora da allowlist: %s" % (n, t)); continue
    m = re.fullmatch(r"([A-Za-z]+)=(.*)", t)
    if not m or sec is None:
        bad.append("linha %d: não é diretiva de seção conhecida" % n); continue
    k, v = (sec, m.group(1)), m.group(2).strip()
    if k in FIX:
        if v not in FIX[k]:
            bad.append("%s=%s fora do valor fixo" % (k[1], v[:80]))
    elif k in FREE:
        if not re.fullmatch(FREE[k], v):
            bad.append("%s=%s fora da forma" % (k[1], v[:80]))
    else:
        bad.append("diretiva fora da allowlist: [%s] %s" % k)
    seen.add(k)
for k in sorted(REQ - seen):
    bad.append("falta %s" % k[1])
print("; ".join(bad[:6]))
sys.exit(1 if bad else 0)
'
}

cmd_install() {
  local apply=0
  case "${1:-}" in "") ;; --apply) apply=1 ;; *) usage ;; esac
  need_sudo
  local src="${SERVED}/${UNIT}.service" dst="${UNIT_DIR}/${UNIT}.service" unit why
  priv test -s "${src}" || die 1 "o bridge servido não tem ${src}: o PR da persona chegou ao bridge? (ops/update-bridge.sh)"
  served_regular "${src}" || die 1 "${src} não é arquivo regular dentro do bridge servido (symlink?): recusado, o root copiaria o alvo do link"
  unit="$(as_owner cat -- "${src}")" || die 2 "não li ${src} como o dono do bridge servido"
  why="$(unit_allowlist_check <<< "${unit}")" || die 1 "a unit servida sai da allowlist de diretivas (o root não a instala): ${why}"
  if [ "$(priv cat -- "${dst}" 2>/dev/null)" = "${unit}" ]; then say "unit: igual à servida"; else
    say "unit: difere da servida (ou não está instalada):"; diff -u <(priv cat -- "${dst}" 2>/dev/null) <(printf '%s\n' "${unit}") | head -60 || true
  fi
  local cp; cp="$(config_problem)"; [ -n "${cp}" ] && say "config: ${cp}"
  local ur; ur="$(unreadable_code)"; [ -n "${ur}" ] && say "ATENÇÃO: código sem leitura para outros (o start vai recusar): ${ur}"
  if [ "${apply}" = 0 ]; then say "ENSAIO: nada foi escrito. Instalar: ops/slack-persona.sh install --apply"; return 0; fi
  # o texto conferido vai a um diretório temporário do root (0700), e só ele é verificado e instalado
  local tmpd; tmpd="$(priv mktemp -d)" || die 2 "mktemp do root falhou"
  printf '%s\n' "${unit}" | priv tee "${tmpd}/${UNIT}.service" >/dev/null || die 2 "não escrevi a unit conferida"
  priv systemd-analyze verify "${tmpd}/${UNIT}.service" >/dev/null 2>&1 || { priv rm -f -- "${tmpd}/${UNIT}.service"; priv rmdir -- "${tmpd}"; die 1 "systemd-analyze verify reprova a unit servida"; }
  local ts; ts="$(date -u +%Y%m%dT%H%M%SZ)"
  priv install -d -m 0700 "${BACKUP}"
  if priv test -e "${dst}"; then priv cp -a "${dst}" "${BACKUP}/${UNIT}.service.${ts}"; fi
  priv install -d -m 0755 "${UNIT_DIR}"
  priv install -m 0644 "${tmpd}/${UNIT}.service" "${dst}" || die 2 "não instalei a unit"
  priv install -d -m 0755 "${ETC}"
  if ! priv test -e "${ETC}/config.json"; then
    served_regular "${SERVED}/config.example.json" || die 1 "${SERVED}/config.example.json não é arquivo regular dentro do bridge servido (symlink?): recusado"
    local cfg; cfg="$(as_owner cat -- "${SERVED}/config.example.json")" || die 2 "não li a config de exemplo como o dono do bridge servido"
    python3 -I -c 'import json,sys; json.loads(sys.stdin.read())' <<< "${cfg}" 2>/dev/null || die 1 "a config de exemplo servida não é JSON: recusada"
    printf '%s\n' "${cfg}" | priv tee "${tmpd}/config.json" >/dev/null || die 2 "não escrevi a config conferida"
    priv install -m 0644 "${tmpd}/config.json" "${ETC}/config.json" || die 2 "não instalei a config de exemplo"
    priv rm -f -- "${tmpd}/config.json"
    say "config: instalada a de EXEMPLO em ${ETC}/config.json; troque os IDs U0000…/C0000… pelos reais antes do start"
  fi
  priv rm -f -- "${tmpd}/${UNIT}.service"; priv rmdir -- "${tmpd}"
  priv systemctl daemon-reload || die 2 "daemon-reload falhou"
  say "unit instalada (não ligada). Backup: ${BACKUP}/${UNIT}.service.${ts} (se havia). Próximo: ops/slack-persona.sh start"
  say "ROLLBACK: sudo rm ${dst} && sudo systemctl daemon-reload"
}

connected_in_invocation() {
  local inv; inv="$(priv systemctl show -p InvocationID --value "${UNIT}" 2>/dev/null)"
  [ -n "${inv}" ] || return 1
  # capturado e julgado por here-string: o par journalctl e grep -q por pipe sob pipefail pode sair 141 (SIGPIPE) com a linha presente
  local log; log="$(priv journalctl -q -o cat _SYSTEMD_INVOCATION_ID="${inv}" 2>/dev/null)"
  grep -q '"msg":"slack persona connected"' <<< "${log}"
}

# a linha de conexão sai segundos DEPOIS do restart: start e verify esperam por ela até o mesmo teto (o verify logo após
# um restart dava ✗ falso, medido em 2026-11-07). Sai cedo se a unit falhou. rc 0 = viu a conexão desta invocação
CONNECT_WAIT_S=45
wait_connected() {
  local i
  for i in $(seq 1 "${CONNECT_WAIT_S}"); do
    connected_in_invocation && return 0
    priv systemctl is-failed -q "${UNIT}" && return 1
    sleep 1
  done
  return 1
}

# o UID dinâmico lê o código só pelo bit "outros" (a home do onion é 0750 e o bind não muda permissão): o que não for
# o+r sob estes caminhos derruba o processo no boot
unreadable_code() {
  local b="${SERVED%/deploy/slack-persona}"
  priv find "${b}/src/slack-persona" "${b}/node_modules/tsx" "${b}/node_modules/@slack" "${b}/node_modules/@anthropic-ai" \
    "${b}/node_modules/zod" "${b}/package.json" \( -type f ! -perm -o=r \) -o \( -type d ! -perm -o=rx \) 2>/dev/null | head -3
}

preflight_start() {
  local miss cp
  priv test -s "${UNIT_DIR}/${UNIT}.service" || die 1 "unit não instalada (ops/slack-persona.sh install --apply)"
  priv cmp -s "${SERVED}/${UNIT}.service" "${UNIT_DIR}/${UNIT}.service" || die 1 "a unit instalada difere da servida (rode install --apply)"
  miss="$(missing_creds | tr '\n' ' ')"; [ -z "${miss}" ] || die 1 "faltam credenciais: ${miss}(ops/slack-persona.sh creds)"
  cp="$(config_problem)"; [ -z "${cp}" ] || die 1 "config: ${cp}"
  local ur; ur="$(unreadable_code)"; [ -z "${ur}" ] || die 1 "código do bridge servido sem leitura para outros (o UID dinâmico não lê): ${ur}"
}

cmd_start() {
  need_sudo; preflight_start
  priv systemctl enable "${UNIT}" >/dev/null 2>&1 || die 2 "enable falhou"
  priv systemctl restart "${UNIT}" || die 2 "restart falhou (journalctl -u ${UNIT})"
  if wait_connected; then say "ligada: conectada ao Slack nesta invocação"; say "ROLLBACK: sudo systemctl disable --now ${UNIT}"; return 0; fi
  priv journalctl -u "${UNIT}" -n 20 --no-pager -o cat 2>/dev/null | sed 's/^/    /'
  die 1 "não vi a conexão desta invocação em ${CONNECT_WAIT_S} s. ROLLBACK: sudo systemctl disable --now ${UNIT}"
}

cmd_verify() {
  need_sudo
  local bad=0 miss cp
  if priv cmp -s "${SERVED}/${UNIT}.service" "${UNIT_DIR}/${UNIT}.service"; then say "✓ unit instalada = servida"; else say "✗ unit instalada difere da servida (ou falta)"; bad=1; fi
  miss="$(missing_creds | tr '\n' ' ')"
  if [ -z "${miss}" ]; then say "✓ as 4 credenciais cifradas presentes"; else say "✗ faltam credenciais: ${miss}"; bad=1; fi
  cp="$(config_problem)"; if [ -z "${cp}" ]; then say "✓ config sem IDs de exemplo"; else say "✗ config: ${cp}"; bad=1; fi
  if priv systemctl is-active -q "${UNIT}"; then
    if wait_connected; then say "✓ ativa e conectada nesta invocação"; else say "✗ ativa, mas sem a linha de conexão desta invocação em ${CONNECT_WAIT_S} s"; bad=1; fi
    local dyn; dyn="$(priv systemctl show -p DynamicUser --value "${UNIT}" 2>/dev/null)"
    if [ "${dyn}" = yes ]; then say "✓ DynamicUser=yes no processo vivo"; else say "✗ DynamicUser no vivo: '${dyn}'"; bad=1; fi
  else say "· inativa (start ainda não rodou)"; fi
  [ "${bad}" = 0 ] || exit 1
}

case "${1:-}" in
  creds) shift; cmd_creds "$@" ;;
  install) shift; cmd_install "$@" ;;
  start) shift; [ $# = 0 ] || usage; cmd_start ;;
  verify) shift; [ $# = 0 ] || usage; cmd_verify ;;
  *) usage ;;
esac
