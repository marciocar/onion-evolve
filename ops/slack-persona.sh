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
#   ops/slack-persona.sh verify                               só leitura: unit, credenciais, config, processo vivo
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
[ "$(id -u)" = 0 ] && [ "${TEST}" != 1 ] && die 3 "rode como o operador (o script chama sudo onde precisa), não como root"
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

cmd_install() {
  local apply=0
  case "${1:-}" in "") ;; --apply) apply=1 ;; *) usage ;; esac
  need_sudo
  local src="${SERVED}/${UNIT}.service" dst="${UNIT_DIR}/${UNIT}.service"
  priv test -s "${src}" || die 1 "o bridge servido não tem ${src}: o PR da persona chegou ao bridge? (ops/update-bridge.sh)"
  if priv cmp -s "${src}" "${dst}" 2>/dev/null; then say "unit: igual à servida"; else
    say "unit: difere da servida (ou não está instalada):"; priv diff -u "${dst}" "${src}" 2>/dev/null | head -60 || true
  fi
  local cp; cp="$(config_problem)"; [ -n "${cp}" ] && say "config: ${cp}"
  local ur; ur="$(unreadable_code)"; [ -n "${ur}" ] && say "ATENÇÃO: código sem leitura para outros (o start vai recusar): ${ur}"
  if [ "${apply}" = 0 ]; then say "ENSAIO: nada foi escrito. Instalar: ops/slack-persona.sh install --apply"; return 0; fi
  priv systemd-analyze verify "${src}" >/dev/null 2>&1 || die 1 "systemd-analyze verify reprova a unit servida"
  local ts; ts="$(date -u +%Y%m%dT%H%M%SZ)"
  priv install -d -m 0700 "${BACKUP}"
  if priv test -e "${dst}"; then priv cp -a "${dst}" "${BACKUP}/${UNIT}.service.${ts}"; fi
  priv install -d -m 0755 "${UNIT_DIR}"
  priv install -m 0644 "${src}" "${dst}" || die 2 "não instalei a unit"
  priv install -d -m 0755 "${ETC}"
  if ! priv test -e "${ETC}/config.json"; then
    priv install -m 0644 "${SERVED}/config.example.json" "${ETC}/config.json" || die 2 "não instalei a config de exemplo"
    say "config: instalada a de EXEMPLO em ${ETC}/config.json; troque os IDs U0000…/C0000… pelos reais antes do start"
  fi
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
  local i
  for i in $(seq 1 45); do
    if connected_in_invocation; then say "ligada: conectada ao Slack nesta invocação"; say "ROLLBACK: sudo systemctl disable --now ${UNIT}"; return 0; fi
    priv systemctl is-failed -q "${UNIT}" && break
    sleep 1
  done
  priv journalctl -u "${UNIT}" -n 20 --no-pager -o cat 2>/dev/null | sed 's/^/    /'
  die 1 "não vi a conexão desta invocação em 45 s. ROLLBACK: sudo systemctl disable --now ${UNIT}"
}

cmd_verify() {
  need_sudo
  local bad=0 miss cp
  if priv cmp -s "${SERVED}/${UNIT}.service" "${UNIT_DIR}/${UNIT}.service"; then say "✓ unit instalada = servida"; else say "✗ unit instalada difere da servida (ou falta)"; bad=1; fi
  miss="$(missing_creds | tr '\n' ' ')"
  if [ -z "${miss}" ]; then say "✓ as 4 credenciais cifradas presentes"; else say "✗ faltam credenciais: ${miss}"; bad=1; fi
  cp="$(config_problem)"; if [ -z "${cp}" ]; then say "✓ config sem IDs de exemplo"; else say "✗ config: ${cp}"; bad=1; fi
  if priv systemctl is-active -q "${UNIT}"; then
    if connected_in_invocation; then say "✓ ativa e conectada nesta invocação"; else say "✗ ativa, mas sem a linha de conexão desta invocação"; bad=1; fi
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
