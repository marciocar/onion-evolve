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
#   ops/chat-runner.sh install [--apply] [--egress-fence]   ensaio (padrão) ou instalação do runner
#   ops/chat-runner.sh verify              prova, no instalado e no processo vivo, que o runner vale
#   ops/chat-runner.sh show                imprime o que seria instalado (nada é medido)
#
#   install sem --apply é ENSAIO: lê as fontes do bridge servido (rastreadas e limpas), renderiza as units e o
#   drop-in, mostra a diferença para o instalado e roda as checagens numa unit TRANSITÓRIA (systemd-run --collect)
#   com o sandbox do template renderizado, sob um UID dinâmico. Nada persistente é escrito.
#   --egress-fence (DESLIGADA por padrão; decisão do maestro D_DEGRAU3_SEM_OBJETO_NO_CONVIDADO_1016, opção A) instala
#   também a CERCA DE REDE do runner: o drop-in onion-chat@.service.d/60-egress-fence.conf, renderizado do modelo do
#   bridge servido com os endereços GLOBAIS do próprio host medidos agora (IPAddressDeny do loopback, link-local,
#   faixas privadas e do host, SEM nenhum IPAddressAllow; o DNS vai direto aos resolvedores públicos pelo resolv.conf de
#   upstream ligado no /etc/resolv.conf da instância). Instalada, ela é o ESTADO: o install sem a flag a mantém e o
#   verify a prova; tirá-la é a linha de reversão que o install imprime.
#   verify é só leitura (sem trava): confere o instalado contra o renderizado, o grupo e as ACLs, o sandbox do
#   template INSTALADO numa unit transitória, o aperto de mão real pelo socket (initialize do CLI, sem chamar a API)
#   e a recusa do lançador, e o drop-in carregado no processo vivo do bridge. Com a cerca instalada, prova também a
#   rede: numa unit transitória com o template e a cerca INSTALADOS, na slice do runner, o TCP ao loopback, ao stub do
#   resolvedor e aos endereços do host é barrado ONDE uma perna de controle (o mesmo sandbox sem a cerca) o vê aberto ou
#   recusado, e o DNS e o TLS com a API seguem; o efetivo da instância carrega as mesmas faixas e nenhum IPAddressAllow,
#   nem nas slices-mãe (allow vence deny); e o aperto de mão pelo socket (o CLI sob a cerca) segue respondendo.
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
FENCE_NAME=60-egress-fence.conf      # a cerca de rede (opção A do degrau 3), drop-in do template do runner
# as faixas que a cerca EXIGE (as mesmas do modelo do bridge; a allowlist confere uma a uma) e o único furo
FENCE_REQUIRED="0.0.0.0/8 127.0.0.0/8 ::/128 ::1/128 169.254.0.0/16 fe80::/10 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16 100.64.0.0/10 fc00::/7"
# SEM IPAddressAllow: o filtro do cgroup julga só o ENDEREÇO, nunca a porta, e um furo no stub do resolvedor (127.0.0.53)
# abria todo serviço escutando em 0.0.0.0 (refutador da cerca, achado 1, medido: o proxy reverso e o sshd por ele). O DNS
# sai pelos resolvedores públicos: o resolv.conf de upstream do systemd-resolved no lugar do /etc/resolv.conf
FENCE_RESOLV_SRC=/run/systemd/resolve/resolv.conf
FENCE_RESOLV_BIND="${FENCE_RESOLV_SRC}:/etc/resolv.conf"
NET_PROBE_API=api.anthropic.com      # o que a cerca NÃO pode cortar: o DNS e o TLS com a API
# as slices de onde um IPAddressAllow venceria o deny da instância (allow vence deny no systemd, também herdado)
RUNNER_SLICE='system-onion\x2dchat.slice'
FENCE_SLICES=( "${RUNNER_SLICE}" system.slice -.slice )
# a sonda de REDE da cerca, que roda DENTRO das units transitórias (python3 -I -c). Modos:
#   probe <h:p>...      uma linha "NET <h:p> <estado>" por alvo: aberto | recusado | barrado (timeout ou EPERM) | erro:<tipo>
#   api <host>          "OK|FALHA cerca: ..." para o DNS e o TLS (certificado verificado) com a API
#   --classify-selftest a tabela do classificador conferida com exceções sintéticas (a bancada o exercita de verdade)
NETPY="$(cat <<'NETPY'
import socket, ssl, sys

def classify(exc):
    if exc is None:
        return "aberto"
    if isinstance(exc, ConnectionRefusedError):
        return "recusado"
    if isinstance(exc, (socket.timeout, TimeoutError, PermissionError)):
        return "barrado"
    return "erro:%s" % type(exc).__name__

def tcp(target):
    h, _, p = target.rpartition(":")
    try:
        socket.create_connection((h.strip("[]"), int(p)), timeout=3).close()
        return classify(None)
    except Exception as e:
        return classify(e)

mode = sys.argv[1] if len(sys.argv) > 1 else ""
if mode == "probe":
    for t in sys.argv[2:]:
        print("NET %s %s" % (t, tcp(t)))
elif mode == "api":
    api = sys.argv[2]
    try:
        ip = socket.getaddrinfo(api, 443, proto=socket.IPPROTO_TCP)[0][4][0]
    except Exception as e:
        print("FALHA cerca: o DNS de %s falhou (%s)" % (api, type(e).__name__)); sys.exit(0)
    print("OK cerca: o DNS de %s segue (resolvedores públicos)" % api)
    try:
        s = socket.create_connection((ip, 443), timeout=8)
        t = ssl.create_default_context().wrap_socket(s, server_hostname=api); v = t.version(); t.close()
        print("OK cerca: o TLS com %s segue (%s, certificado verificado)" % (api, v))
    except Exception as e:
        print("FALHA cerca: o TLS com %s falhou (%s)" % (api, type(e).__name__))
elif mode == "--classify-selftest":
    cases = [(None, "aberto"), (ConnectionRefusedError(), "recusado"), (socket.timeout(), "barrado"),
             (TimeoutError(), "barrado"), (PermissionError(), "barrado"), (OSError(110, "x"), "barrado"),
             (OSError(101, "x"), "erro:OSError"), (ValueError(), "erro:ValueError")]
    bad = [(repr(e), w, classify(e)) for e, w in cases if classify(e) != w]
    print("classify-selftest: %d de %d" % (len(cases) - len(bad), len(cases)) + ("" if not bad else " FALHA %s" % bad))
    sys.exit(1 if bad else 0)
else:
    sys.exit(64)
NETPY
)"
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
APPLY=0; EGRESS=0
case "${SUB}" in install|verify|show) : ;; *) usage ;; esac
while [ $# -gt 0 ]; do
  case "$1" in
    --apply) [ "${SUB}" = install ] || die 3 "--apply só no install"; APPLY=1; shift ;;
    --egress-fence) [ "${SUB}" = install ] || die 3 "--egress-fence só no install (o verify e o show leem o estado instalado)"; EGRESS=1; shift ;;
    *) die 3 "opção não aceita: $1 (as units, os caminhos e o socket são fixos)" ;;
  esac
done

BRIDGE="${SVC_HOME}/onion-bridge"
SRC_DIR="deploy/chat-runner"
SOURCES=( "${SRC_DIR}/launcher.py" "${SRC_DIR}/onion-chat.socket.in" "${SRC_DIR}/onion-chat@.service.in" src/chat-runner.ts )
CLAUDE_SRC="${BRIDGE}/node_modules/@anthropic-ai/claude-agent-sdk-linux-x64/claude"
# o PISO do CLI que o template liga por bind (SAC-156): o CVE-2026-39861 afeta o Claude Code < 2.1.64 (grafo
# chat-agent-isolation-2026-10, nó E_CVE39861_FIXED_IN_2_1_64), e o binário é o do Agent SDK do bridge SERVIDO. Até
# 2026-10-16 o piso valia por acaso de versão (0.3.232 embutia o 2.1.232): um deploy que regredisse o SDK passaria em
# todo o resto do verify. A versão é a que o próprio binário responde, como a conta do serviço, sem a home dela
CLI_FLOOR=2.1.64
WS_ROOT="${STATE}/workspaces"
HOME_ROOT="${STATE}/chat-homes"
DROPIN_DIR="${UNIT_DIR}/${UNIT}.service.d"
FENCE_DIR="${UNIT_DIR}/${TEMPLATE_UNIT}.d"
FENCE_SRC="${SRC_DIR}/onion-chat-egress-fence.conf.in"
# a cerca vale quando pedida OU já instalada (instalada é o estado: o install sem a flag não a tira em silêncio)
FENCE=0; HOST_ADDRS=""
if [ "${EGRESS}" = 1 ] || priv test -e "${FENCE_DIR}/${FENCE_NAME}"; then FENCE=1; fi

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
  if [ "${FENCE}" = 1 ]; then
    [ "$(priv realpath -m -- "${BRIDGE}/${FENCE_SRC}")" = "${BRIDGE}/${FENCE_SRC}" ] || die 1 "fonte com SYMLINK no caminho: ${BRIDGE}/${FENCE_SRC}"
    as_svc git -C "${BRIDGE}" cat-file -e "${BRIDGE_SHA}:${FENCE_SRC}" 2>/dev/null \
      || die 1 "o bridge servido não tem ${FENCE_SRC} (a cerca de rede): faça o deploy do bridge com a cerca (ops/update-bridge.sh) antes"
    as_svc git -C "${BRIDGE}" show "${BRIDGE_SHA}:${FENCE_SRC}" > "${TMPD}/fence.in" || die 2 "não li o ${FENCE_SRC}"
  fi
  BRIDGE_HEAD="${BRIDGE_SHA:0:12}"
}

# host_addrs — os endereços GLOBAIS do próprio host, medidos agora (/32 e /128), fora das faixas que a cerca já nega.
# O tráfego local para o IP público não passa pelo firewall de fora: sem isto, um serviço futuro em 0.0.0.0 protegido
# só por ele ficaria ao alcance do runner (refutador do degrau 3, achado 4, medido)
host_addrs() {
  ip -j addr show scope global 2>/dev/null | python3 -I -c '
import ipaddress, json, sys
req = [ipaddress.ip_network(x) for x in sys.argv[1].split()]
out = set()
for itf in json.load(sys.stdin):
    for a in itf.get("addr_info", []):
        if a.get("scope") != "global" or a.get("family") not in ("inet", "inet6"):
            continue
        ip = ipaddress.ip_address(a["local"])
        if any(ip in n for n in req if n.version == ip.version):
            continue
        out.add(str(ipaddress.ip_network(ip)))
print(" ".join(sorted(out)))' "${FENCE_REQUIRED}"
}

render_one() {   # render_one <modelo> <saída> <de onde veio>
  { printf '%s\n# GERADO por ops/chat-runner.sh (core-only) a partir de %s do bridge servido. Não edite à mão.\n' "${MARKER}" "$3"
    sed -e "s#@SOCKET@#${SOCKET}#g" -e "s#@SVC_USER@#${SVC_USER}#g" -e "s#@GROUP@#${GROUP}#g" -e "s#@STATE@#${STATE}#g" \
        -e "s#@CLAUDE_SRC@#${CLAUDE_SRC}#g" -e "s#@LIBEXEC@#${LIBEXEC}#g" -e "s#@HOST_ADDRS@#${HOST_ADDRS:-@HOST_ADDRS@}#g" "$1"; } > "$2"
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
  out="$(python3 -I - "${f}" "${kind}" "${SOCKET}" "${SVC_USER}" "${GROUP}" "${STATE}" "${CLAUDE_SRC}" "${LIBEXEC}" \
           "${FENCE_REQUIRED}" "${FENCE_RESOLV_BIND}" "${HOST_ADDRS:-}" <<'PY'
import sys
f, kind, sock, svc, grp, state, claude, libexec, freq, fresolv, fhost = sys.argv[1:]
if kind == "fence":
    # a cerca de rede: só [Service], só IPAddressDeny e o bind do resolv.conf público, e o conjunto EXATO (as faixas
    # exigidas mais os endereços do host medidos agora). Faixa a mais, a menos ou mais larga recusa; IPAddressAllow recusa
    # sempre; valor VAZIO recusa (no systemd, `IPAddressDeny=` vazio ZERA a lista acumulada: refutador, achado 2, medido)
    import ipaddress
    def norm(xs, where):
        out = set()
        for x in xs:
            try:
                out.add(str(ipaddress.ip_network(x, strict=True)))
            except ValueError:
                print("%s fora da forma: %s" % (where, x)); sys.exit(1)
        return out
    bad, deny, binds = [], [], []
    raw = open(f, "rb").read()
    if any((b < 0x20 and b not in (0x0a, 0x09)) or b == 0x7f for b in raw):
        print("byte de controle no modelo da cerca"); sys.exit(1)
    for n, line in enumerate(raw.decode("utf-8").split("\n"), 1):
        if not line.strip() or line.lstrip().startswith(("#", ";")):
            continue
        if line.startswith("["):
            if line != "[Service]":
                bad.append("seção %s (linha %d)" % (line, n))
            continue
        if line.endswith("\\"):
            bad.append("continuação de linha (linha %d)" % n); continue
        k, eq, v = line.partition("=")
        if not eq or k != k.strip():
            bad.append("linha fora da forma (%d)" % n); continue
        if not v.strip():
            bad.append("%s com valor VAZIO (linha %d: no systemd zera a lista acumulada)" % (k, n)); continue
        if k == "IPAddressDeny":
            deny += v.split()
        elif k == "BindReadOnlyPaths":
            binds.append(v)
        else:
            bad.append("diretiva fora da allowlist da cerca: %s" % k)
    want = norm(freq.split(), "faixa exigida") | norm(fhost.split(), "endereço do host")
    got = norm(deny, "IPAddressDeny")
    if got != want:
        bad.append("IPAddressDeny diferente do exigido (faltam: %s; a mais: %s)" % (" ".join(sorted(want - got)) or "-", " ".join(sorted(got - want)) or "-"))
    if binds != [fresolv]:
        bad.append("BindReadOnlyPaths=%s (exigido só: %s)" % (" | ".join(binds) or "-", fresolv))
    print("; ".join(bad)); sys.exit(1 if bad else 0)
EXACT = {
  "service": {"Type": "simple", "DynamicUser": "yes", "User": "onion-chat-%i", "SupplementaryGroups": grp,
    "StandardInput": "socket", "StandardOutput": "socket", "StandardError": "journal", "PrivateTmp": "yes",
    "ProtectHome": "yes", "ProtectProc": "invisible", "CapabilityBoundingSet": "", "TemporaryFileSystem": state,
    "BindPaths": state + "/workspaces " + state + "/chat-homes", "KillMode": "control-group",
    "RuntimeDirectory": "onion-chat/%i", "CollectMode": "inactive-or-failed",
    "Environment": "ONION_CHAT_WS_ROOT=%s/workspaces ONION_CHAT_HOME_ROOT=%s/chat-homes ONION_CHAT_CLAUDE=/run/onion-chat-bin/claude" % (state, state),
    "ExecStart": "/usr/bin/python3 -I /run/onion-chat-bin/launcher.py",
    "ExecStopPost": "/usr/bin/python3 -I /run/onion-chat-bin/launcher.py --fixup",
    "RuntimeMaxSec": "1800", "TimeoutStopSec": "10", "UMask": "0007", "PrivateDevices": "yes",
    "ProtectKernelTunables": "yes", "ProtectKernelModules": "yes", "ProtectKernelLogs": "yes", "ProtectControlGroups": "yes",
    "ProtectClock": "yes", "ProtectHostname": "yes", "RestrictNamespaces": "yes", "RestrictRealtime": "yes",
    "LockPersonality": "yes", "SystemCallArchitectures": "native", "RestrictAddressFamilies": "AF_UNIX AF_INET AF_INET6",
    "MemoryMax": "2G", "TasksMax": "256"},
  "socket": {"ListenStream": sock, "Accept": "yes", "SocketUser": svc, "SocketGroup": svc, "SocketMode": "0600",
             "MaxConnections": "32", "WantedBy": "sockets.target"},
}[kind]
FREE = {"service": {"Description", "SyslogIdentifier"}, "socket": {"Description"}}[kind]
BIND_RO = {claude + ":/run/onion-chat-bin/claude", libexec + "/launcher.py:/run/onion-chat-bin/launcher.py"}
SECTIONS = {"service": {"[Unit]", "[Service]"}, "socket": {"[Unit]", "[Socket]", "[Install]"}}[kind]
seen, binds, bad = {}, set(), []
raw = open(f, "rb").read()
ctl = sorted({b for b in raw if (b < 0x20 and b not in (0x0a, 0x09)) or b == 0x7f})
if ctl:
    print("byte de controle no modelo (o systemd quebra linha em NUL; o parser daqui não): %s" % ",".join("0x%02x" % b for b in ctl))
    sys.exit(1)
for n, line in enumerate(raw.decode("utf-8").split("\n"), 1):
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
  if [ "${FENCE}" = 1 ]; then
    HOST_ADDRS="$(host_addrs)"
    [ -n "${HOST_ADDRS}" ] || die 2 "não medi os endereços globais do host (ip -j addr): a cerca sem eles deixaria o próprio host ao alcance"
    render_one "${TMPD}/fence.in" "${TMPD}/${FENCE_NAME}" "${FENCE_SRC}"
    validate_units "${TMPD}/${FENCE_NAME}" fence
  fi
}

render_all
if [ "${SUB}" = show ]; then
  for f in "${SOCKET_UNIT}" "${TEMPLATE_UNIT}" "${DROPIN_NAME}"; do printf -- '──── %s\n' "${f}"; cat "${TMPD}/${f}"; done
  if [ "${FENCE}" = 1 ]; then printf -- '──── %s (%s)\n' "${FENCE_NAME}" "${FENCE_DIR}"; cat "${TMPD}/${FENCE_NAME}"
  else printf -- '──── %s: DESLIGADA (install --egress-fence a liga)\n' "${FENCE_NAME}"; fi
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
      # a cerca: uma propriedade por endereço (o systemd-run recusa a lista com palavra-chave; medido)
      # vazio passa FIEL (`-p IPAddressDeny=` zera, como na unit): pular o vazio fazia o ensaio medir outra cerca
      IPAddressDeny|IPAddressAllow) local a; if [ -z "${v// /}" ]; then printf '%s\n' "-p" "${k}="; else for a in ${v}; do printf '%s\n' "-p" "${k}=${a}"; done; fi ;;
    esac
  done < "$1"
}

# check_script → o sh que roda DENTRO da unit transitória, sob o UID dinâmico. Só lê e usa access(2). Cada linha:
# OK|FALHA|AUSENTE <o quê>. $1 = com-grupo (0|1).
check_script() {
  local wg="$1" fence="${2:-0}" ctl="${3:-}" pid
  pid="$(systemctl show -p MainPID --value "${UNIT}" 2>/dev/null)"
  echo 'n_fail=0; ok() { echo "OK $*"; }; bad() { echo "FALHA $*"; n_fail=$((n_fail+1)); }'
  printf 'svc_uid=%q; home=%q; state=%q; ws=%q; hr=%q; pid=%q; probe=%q; wg=%q; fence=%q; api=%q; targets=%q; ctl=%q\n' \
    "$(id -u "${SVC_USER}" 2>/dev/null || echo x)" "${SVC_HOME}" "${STATE}" "${WS_ROOT}" "${HOME_ROOT}" "${pid}" "${PROBE_SLUG}" "${wg}" \
    "${fence}" "${NET_PROBE_API}" "$(net_targets)" "${ctl}"
  [ "${fence}" = 1 ] && net_probe_writer
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
# a CERCA DE REDE (opção A do degrau 3). Barrado só prova a cerca onde a perna de CONTROLE (o mesmo sandbox sem ela)
# viu o alvo aberto ou recusado: timeout sozinho seria qualquer descarte (refutador da cerca, achado 4, medido)
if [ "$fence" = 1 ]; then
  netout="$(timeout 90 python3 -I "${TMPDIR:-/tmp}"/onion-netprobe.py probe $targets 2>&1)"
  for t in $targets; do
    fs="$(printf '%s\n' "$netout" | awk -v t="$t" '$1 == "NET" && $2 == t { print $3 }')"
    cs="$(printf '%s\n' "$ctl" | tr ';' '\n' | awk -v t="$t" '$1 == t { print $2 }')"
    case "$fs:$cs" in
      barrado:aberto|barrado:recusado) ok "cerca: TCP para $t barrado (sem a cerca: $cs)" ;;
      barrado:barrado) bad "cerca: $t NÃO PROVA (descartado também sem a cerca)" ;;
      barrado:) bad "cerca: $t sem perna de controle" ;;
      *) bad "cerca: TCP para $t ${fs:-sem resposta} (sem a cerca: ${cs:-?})" ;;
    esac
  done
  apiout="$(timeout 60 python3 -I "${TMPDIR:-/tmp}"/onion-netprobe.py api "$api" 2>&1)"
  printf '%s\n' "$apiout"
  n_fail=$((n_fail + $(printf '%s\n' "$apiout" | grep -c '^FALHA')))
  # `case`, não `printf | grep -q` (a classe pipefail; o sh da unit não tem here-string)
  case "$apiout" in *"OK cerca: o TLS"*) : ;; *) bad "cerca: o TLS com a API não foi provado" ;; esac
else
  echo "AUSENTE cerca de rede (desligada: install --egress-fence a liga)"
fi
echo "n_fail=$n_fail"; [ "$n_fail" = 0 ]
EOS
}

# os alvos da sonda: o loopback (a porta do bridge), o stub do resolvedor numa porta que não é DNS (o 0.0.0.0 do sshd) e
# cada endereço GLOBAL do host (v4 e v6), também na 22
net_targets() {
  local lport a t="127.0.0.1:"
  lport="${HEALTH_LOCAL#http://127.0.0.1:}"; lport="${lport%%/*}"; t+="${lport} 127.0.0.53:22"
  for a in ${HOST_ADDRS}; do a="${a%/*}"; case "${a}" in *:*) t+=" [${a}]:22" ;; *) t+=" ${a}:22" ;; esac; done
  printf '%s' "${t}"
}
net_probe_writer() {   # o script da sonda, escrito DENTRO da unit (o TMPDIR é o dela)
  printf '%s\n' 'cat > "${TMPDIR:-/tmp}/onion-netprobe.py" <<'"'"'ONION_NETPY_EOF'"'"''
  printf '%s\nONION_NETPY_EOF\n' "${NETPY}"
}
# a perna de CONTROLE: o mesmo sandbox do template, na mesma slice, SEM a cerca; devolve "alvo estado;alvo estado;…"
net_control() {   # net_control <template> <com-grupo> <launcher>
  local props=() out
  mapfile -t props < <(sandbox_props "$1" "$2" "$3")
  out="$({ net_probe_writer; printf 'timeout 90 python3 -I "${TMPDIR:-/tmp}"/onion-netprobe.py probe %s\n' "$(net_targets)"; } \
         | priv systemd-run --quiet --pipe --wait --collect --slice="${RUNNER_SLICE}" "${props[@]}" /bin/sh -s 2>&1)"
  awk '$1 == "NET" { printf "%s %s;", $2, $3 }' <<<"${out}"
}

run_sandbox_probe() {   # run_sandbox_probe <template> <com-grupo> <launcher> [<cerca>] → imprime as linhas, rc 0 = n_fail 0
  local out rc props=() fence=0 unitf="$1" ctl=""
  if [ -n "${4:-}" ]; then
    cat "$1" "$4" > "${TMPD}/probe-with-fence.service"; unitf="${TMPD}/probe-with-fence.service"; fence=1
    ctl="$(net_control "$1" "$2" "$3")"
  fi
  mapfile -t props < <(sandbox_props "${unitf}" "$2" "$3")
  out="$(check_script "$2" "${fence}" "${ctl}" | priv systemd-run --quiet --pipe --wait --collect --slice="${RUNNER_SLICE}" "${props[@]}" /bin/sh -s 2>&1)"; rc=$?
  printf '%s\n' "${out}" | sed 's/^/    /'
  [ "${rc}" = 0 ] && grep -qx 'n_fail=0' <<<"${out}"
}

# o piso do CLI (CLI_FLOOR): imprime UMA linha OK/FALHA; rc 0 = o binário responde uma versão no piso ou acima.
# Comparação numérica por campo (2.1.100 > 2.1.64), nunca lexical; saída sem versão é FALHA, nunca passa calada
cli_floor() {
  local out v fl rc
  # com teto (um binário trocado que trave não prende o verify nem o install) e com o rc lido à parte: sudo que falha
  # e CLI que sai com erro não podem virar "não respondeu uma versão" (refutador da SAC-156, achado 5)
  out="$(as_svc /usr/bin/timeout 30 /usr/bin/env -i PATH=/usr/bin:/bin HOME=/nonexistent DISABLE_AUTOUPDATER=1 "${CLAUDE_SRC}" --version 2>/dev/null)"; rc=$?
  out="${out:0:200}"
  if [ "${rc}" != 0 ]; then
    echo "FALHA o --version do CLI do SDK, como a conta do serviço, saiu com rc ${rc}$([ "${rc}" = 124 ] && echo ' (teto de 30 s)') (${CLAUDE_SRC})"; return 1
  fi
  [[ "${CLI_FLOOR}" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]] || { echo "FALHA CLI_FLOOR fora da forma: ${CLI_FLOOR}"; return 1; }
  fl=$(( 10#${BASH_REMATCH[1]} * 1000000000000 + 10#${BASH_REMATCH[2]} * 1000000 + 10#${BASH_REMATCH[3]} ))
  if [[ "${out}" =~ ^([0-9]{1,6})\.([0-9]{1,6})\.([0-9]{1,6}) ]]; then
    v=$(( 10#${BASH_REMATCH[1]} * 1000000000000 + 10#${BASH_REMATCH[2]} * 1000000 + 10#${BASH_REMATCH[3]} ))
    if [ "${v}" -ge "${fl}" ]; then
      echo "OK o CLI do SDK responde ${BASH_REMATCH[0]}, no piso ${CLI_FLOOR} ou acima (${CLAUDE_SRC})"; return 0
    fi
    echo "FALHA o CLI do SDK responde ${BASH_REMATCH[0]}, ABAIXO do piso ${CLI_FLOOR} (CVE-2026-39861): suba o Agent SDK do bridge"; return 1
  fi
  echo "FALHA o CLI do SDK não respondeu uma versão a --version (${CLAUDE_SRC}): ${out:0:60}"; return 1
}

# o CONTRATO entre o Agent SDK SERVIDO e o lançador INSTALADO (refutador da SAC-156, passada 2): o aperto de mão abaixo
# usa um argv escrito aqui, na forma separada, e não o que o SDK do bridge entrega; um bump do SDK que mudasse uma flag
# faria o lançador recusar todo turno de convidado sem nenhuma linha FALHA. A prova é do bridge servido
# (scripts/sdk-runner-contract-selftest.py: o argv do SDK instalado com a política real passa pelo check_args, o piso do
# CLI, o ambiente e o initialize), rodada como a conta do serviço contra o lançador que o root instalou. Imprime UMA
# linha OK/FALHA; o rodapé do selftest vai junto quando reprova
CONTRACT_SELFTEST=scripts/sdk-runner-contract-selftest.py
sdk_contract() {
  local out rc
  if ! as_svc test -f "${BRIDGE}/${CONTRACT_SELFTEST}"; then
    echo "FALHA o bridge servido não tem ${CONTRACT_SELFTEST} (anterior à SAC-156): faça o deploy do bridge (ops/update-bridge.sh)"; return 1
  fi
  out="$(as_svc /usr/bin/timeout 180 /usr/bin/env -i PATH=/usr/bin:/bin HOME="${SVC_HOME}" LC_ALL=C \
    LAUNCHER_PATH="${LIBEXEC}/launcher.py" /usr/bin/python3 -I "${BRIDGE}/${CONTRACT_SELFTEST}" 2>&1)"; rc=$?
  if [ "${rc}" = 0 ]; then
    echo "OK o argv do SDK servido, com a política do convidado, passa pelo lançador instalado ($(grep -c '^  ✓' <<<"${out}") asserções)"; return 0
  fi
  echo "FALHA o contrato SDK↔lançador instalado reprovou (rc ${rc}$([ "${rc}" = 124 ] && echo ', teto de 180 s')): $(grep -m3 '^  ✗' <<<"${out}" | tr '\n' ' ' | cut -c1-400)"
  return 1
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

# o que o systemd CARREGOU (refutador, passada 2, achados 1 e 7): o parser do wrapper pode divergir do systemd, e drop-ins
# de onion-chat@.service ou do socket mudariam a instância sem passar pela allowlist. Uma instância de sonda NÃO é iniciada:
# `systemctl show` de um nome de instância só carrega o template.
effective_props() {
  local out nf=0 dp
  out="$(systemctl show onion-chat@verify.service -p DynamicUser -p User -p ExecStartPre -p ExecStartPost -p ExecStart -p ProtectHome -p TemporaryFileSystem -p PrivateTmp -p IPAddressDeny -p IPAddressAllow -p BindReadOnlyPaths 2>/dev/null)"
  grep -qx 'DynamicUser=yes' <<<"${out}" || { echo "    FALHA efetivo: DynamicUser não é yes"; nf=$((nf+1)); }
  grep -qx 'User=onion-chat-verify' <<<"${out}" || { echo "    FALHA efetivo: User não é onion-chat-<instância> ($(grep '^User=' <<<"${out}"))"; nf=$((nf+1)); }
  # vazio, o systemctl show nem imprime a linha (medido no dogfood): falha é a linha COM valor
  ! grep -qE '^ExecStart(Pre|Post)=.+' <<<"${out}" || { echo "    FALHA efetivo: há ExecStartPre/ExecStartPost"; nf=$((nf+1)); }
  grep -q '^ExecStart=.*argv\[\]=/usr/bin/python3 -I /run/onion-chat-bin/launcher.py ;' <<<"${out}" || { echo "    FALHA efetivo: ExecStart não é o lançador"; nf=$((nf+1)); }
  grep -qx 'ProtectHome=yes' <<<"${out}" || { echo "    FALHA efetivo: ProtectHome não é yes"; nf=$((nf+1)); }
  # a cerca EFETIVA: com ela, as faixas que o systemd carregou são exatamente as renderizadas (comparadas como conjunto,
  # normalizadas); sem ela, nenhuma (uma faixa vinda de outro lugar mudaria a instância sem passar pela allowlist)
  local fd fa
  fd="$(grep '^IPAddressDeny=' <<<"${out}" | cut -d= -f2-)"; fa="$(grep '^IPAddressAllow=' <<<"${out}" | cut -d= -f2-)"
  # IPAddressAllow nunca: nem na instância nem nas slices-mãe (um allow herdado vence o deny da unit: refutador da cerca,
  # achado 3, medido com uma slice de runtime)
  [ -z "${fa// /}" ] || { echo "    FALHA efetivo: IPAddressAllow=${fa} na instância (vence o deny)"; nf=$((nf+1)); }
  local sl sa
  for sl in "${FENCE_SLICES[@]}"; do
    sa="$(systemctl show -p IPAddressAllow --value "${sl}" 2>/dev/null)"
    [ -z "${sa// /}" ] || { echo "    FALHA efetivo: IPAddressAllow=${sa} na slice ${sl} (herdado, vence o deny da instância)"; nf=$((nf+1)); }
  done
  if [ "${FENCE}" = 1 ]; then
    if python3 -I -c 'import ipaddress,sys; n=lambda x:{str(ipaddress.ip_network(a,strict=False)) for a in x.split()}; sys.exit(0 if n(sys.argv[1])==n(sys.argv[2]) else 1)' \
         "${fd}" "${FENCE_REQUIRED} ${HOST_ADDRS}" 2>/dev/null; then
      echo "    OK efetivo: a cerca de rede carregada na instância (IPAddressDeny com as $(wc -w <<<"${FENCE_REQUIRED} ${HOST_ADDRS}") faixas, sem IPAddressAllow)"
    else echo "    FALHA efetivo: a cerca carregada difere da renderizada (IPAddressDeny=${fd:-vazio})"; nf=$((nf+1)); fi
    grep -q "^BindReadOnlyPaths=.*${FENCE_RESOLV_SRC}:/etc/resolv.conf" <<<"${out}" \
      || { echo "    FALHA efetivo: o resolv.conf público não está ligado na instância (o DNS cairia)"; nf=$((nf+1)); }
  elif [ -n "${fd// /}" ]; then echo "    FALHA efetivo: IPAddressDeny na instância sem a cerca deste wrapper"; nf=$((nf+1)); fi
  for u in onion-chat@verify.service "${SOCKET_UNIT}"; do
    dp="$(systemctl show -p DropInPaths --value "${u}" 2>/dev/null)"
    # na bancada/dogfood o drop-in de ensaio (50-dogfood*) é declarado; em produção só a cerca deste wrapper, se instalada
    [ "${TEST}" = 1 ] && dp="$(tr ' ' '\n' <<<"${dp}" | grep -v '/50-dogfood[^/]*$' | paste -sd' ' -)"
    [ "${FENCE}" = 1 ] && [ "${u}" = onion-chat@verify.service ] && dp="$(tr ' ' '\n' <<<"${dp}" | grep -vxF -- "${FENCE_DIR}/${FENCE_NAME}" | paste -sd' ' -)"
    [ -z "${dp// /}" ] || { echo "    FALHA efetivo: drop-in(s) em ${u}: ${dp}"; nf=$((nf+1)); }
  done
  [ "${nf}" = 0 ] && echo "    OK efetivo: DynamicUser=yes, User=onion-chat-%i, só o ExecStart do lançador, ProtectHome=yes, nenhum drop-in alheio"
  [ "${nf}" = 0 ]
}

# a identidade da instância REAL (refutador, passada 2, achado 6): o aperto de mão só prova que o CLI respondeu. O lançador
# registra o UID de cada sessão e de cada recusa; desde <ts>, os dois têm de existir e não ser o UID do serviço nem 0
runner_identity() {
  local j su uid ok_s=0 ok_r=0
  su="$(id -u "${SVC_USER}" 2>/dev/null)"
  # o journal chega com atraso: até ~5 s pelas duas linhas
  for _ in 1 2 3 4 5 6 7 8 9 10; do
    # o identificador (-t) é forjável por qualquer conta local; a slice (_SYSTEMD_SLICE) é campo CONFIÁVEL, escrito pelo
    # journald (refutador da cerca, achado 6): só conta linha que veio de uma instância do runner
    j="$(priv journalctl -t onion-chat "_SYSTEMD_SLICE=${RUNNER_SLICE}" --since "@$1" --no-pager -o cat 2>/dev/null)"
    grep -q 'chat-runner: sessão uid=' <<<"${j}" && grep -q 'chat-runner: RECUSA uid=' <<<"${j}" && break
    sleep 0.5
  done
  for uid in $(grep -oE 'chat-runner: sessão uid=[0-9]+' <<<"${j}" | grep -oE '[0-9]+$'); do
    [ "${uid}" != 0 ] && [ "${uid}" != "${su}" ] && ok_s=1
  done
  for uid in $(grep -oE 'chat-runner: RECUSA uid=[0-9]+' <<<"${j}" | grep -oE '[0-9]+$'); do
    [ "${uid}" != 0 ] && [ "${uid}" != "${su}" ] && ok_r=1
  done
  [ "${ok_s}" = 1 ] && echo "    OK a sessão do aperto de mão rodou sob UID próprio (journal)" || echo "    FALHA o journal não mostra a sessão sob UID próprio"
  [ "${ok_r}" = 1 ] && echo "    OK a recusa veio do lançador sob UID próprio (journal), não de outro fechamento" || echo "    FALHA o journal não mostra a RECUSA do lançador"
  [ "${ok_s}" = 1 ] && [ "${ok_r}" = 1 ]
}

# nenhum .git de workspace aberto ao grupo (refutador, passada 2, achado 3: o bridge roda git nele como a conta do serviço)
gitdirs_private() {
  local g bad=0
  while IFS= read -r -d '' g; do
    if grep -q "group:${GROUP}:" <<<"$(as_svc getfacl -p --omit-header -- "${g}" 2>/dev/null)"; then echo "    FALHA .git aberto ao grupo: ${g}"; bad=1; fi
  done < <(as_svc find "${WS_ROOT}" -mindepth 2 -maxdepth 2 -name .git -type d -print0 2>/dev/null)
  [ "${bad}" = 0 ] && echo "    OK nenhum .git de workspace aberto ao grupo ${GROUP}"
  [ "${bad}" = 0 ]
}

acl_has() {   # acl_has <caminho> <entrada exata do getfacl>
  grep -qx -- "$2" <<<"$(priv getfacl -p --omit-header -- "$1" 2>/dev/null)"
}

# ── verify ──────────────────────────────────────────────────────────────────────────────────────────
verify_all() {
  local nf=0 f dst rc pid dp
  vbad() { echo "FALHA $*"; nf=$((nf + 1)); }
  vok()  { echo "OK $*"; }
  local files=( "${SOCKET_UNIT}:${UNIT_DIR}/${SOCKET_UNIT}" "${TEMPLATE_UNIT}:${UNIT_DIR}/${TEMPLATE_UNIT}" \
                "launcher.py:${LIBEXEC}/launcher.py" "${DROPIN_NAME}:${DROPIN_DIR}/${DROPIN_NAME}" )
  [ "${FENCE}" = 1 ] && files+=( "${FENCE_NAME}:${FENCE_DIR}/${FENCE_NAME}" )
  for f in "${files[@]}"; do
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
  local floor; if floor="$(cli_floor)"; then vok "${floor#OK }"; else vbad "${floor#FALHA }"; fi
  local contract; if contract="$(sdk_contract)"; then vok "${contract#OK }"; else vbad "${contract#FALHA }"; fi
  echo "-- sandbox do template INSTALADO (unit transitória sob UID dinâmico):"
  if priv test -f "${UNIT_DIR}/${TEMPLATE_UNIT}"; then
    priv cat "${UNIT_DIR}/${TEMPLATE_UNIT}" > "${TMPD}/installed.service"
    local fence_inst=""
    if [ "${FENCE}" = 1 ] && priv test -f "${FENCE_DIR}/${FENCE_NAME}"; then priv cat "${FENCE_DIR}/${FENCE_NAME}" > "${TMPD}/installed-fence.conf"; fence_inst="${TMPD}/installed-fence.conf"; fi
    run_sandbox_probe "${TMPD}/installed.service" 1 "${LIBEXEC}/launcher.py" "${fence_inst}" || vbad "o sandbox do template instalado reprovou (linhas FALHA acima)"
  else vbad "sem template instalado para medir o sandbox"; fi
  effective_props || vbad "as propriedades EFETIVAS das units do runner divergem do exigido (linhas acima)"
  echo "-- pelo socket, como a conta do serviço:"
  local since; since="$(date +%s)"
  handshake | sed 's/^/    /'; rc="${PIPESTATUS[0]}"
  [ "${rc}" = 0 ] || vbad "o aperto de mão ou a recusa pelo socket reprovou"
  runner_identity "${since}" || vbad "o journal não prova a identidade da instância real (linhas acima)"
  gitdirs_private || vbad "um .git de workspace está aberto ao grupo do runner (linhas acima)"
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
CLI_FLOOR_LINE="$(cli_floor)" || die 1 "${CLI_FLOOR_LINE#FALHA }"
if [ "${FENCE}" = 1 ] && [ "${TEST}" = 0 ]; then
  priv test -f "${FENCE_RESOLV_SRC}" || die 1 "${FENCE_RESOLV_SRC} ausente: sem ele a cerca corta o DNS (o stub do resolvedor fica fora)"
fi
command -v setfacl >/dev/null 2>&1 && command -v getfacl >/dev/null 2>&1 || die 2 "setfacl/getfacl ausentes (pacote acl)"
[ -x /usr/bin/python3 ] || die 2 "/usr/bin/python3 ausente (o lançador é python)"
if priv test -e "${SOCKET}" && ! systemctl cat "${SOCKET_UNIT}" >/dev/null 2>&1; then
  die 1 "${SOCKET} já existe e não é do ${SOCKET_UNIT}: recusado"
fi
for f in "${UNIT_DIR}/${SOCKET_UNIT}" "${UNIT_DIR}/${TEMPLATE_UNIT}" "${DROPIN_DIR}/${DROPIN_NAME}" "${FENCE_DIR}/${FENCE_NAME}"; do
  if priv test -e "${f}"; then
    [ "$(priv realpath -m -- "${f}")" = "${f}" ] || die 1 "${f} é symlink: recusado"
    priv grep -qxF "${MARKER}" "${f}" || say "AVISO: ${f} já existe e NÃO foi gerado por este wrapper (sem o marcador): vai para o backup antes da troca"
  fi
done

# ── diferença para o instalado ───────────────────────────────────────────────────────────────────────
changed=0
targets=( "${SOCKET_UNIT}:${UNIT_DIR}/${SOCKET_UNIT}" "${TEMPLATE_UNIT}:${UNIT_DIR}/${TEMPLATE_UNIT}" \
          "launcher.py:${LIBEXEC}/launcher.py" "${DROPIN_NAME}:${DROPIN_DIR}/${DROPIN_NAME}" )
[ "${FENCE}" = 1 ] && targets+=( "${FENCE_NAME}:${FENCE_DIR}/${FENCE_NAME}" )
[ "${FENCE}" = 1 ] && [ "${EGRESS}" = 0 ] && say "a cerca de rede já está instalada: segue no lugar e é provada (para tirá-la, a linha de reversão no fim)"
[ "${FENCE}" = 0 ] && say "cerca de rede DESLIGADA (padrão): o runner segue sem IPAddressDeny; install --egress-fence a liga"
for f in "${targets[@]}"; do
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
fence_r=""; [ "${FENCE}" = 1 ] && fence_r="${TMPD}/${FENCE_NAME}"
if ! run_sandbox_probe "${TMPD}/${TEMPLATE_UNIT}" "${group_ok}" "${TMPD}/launcher.py" "${fence_r}"; then
  say "o ENSAIO reprovou: nada foi escrito. Leia as linhas FALHA acima."; exit 1
fi
if [ "${APPLY}" = 0 ]; then
  say "ENSAIO OK: nada foi escrito. Para instalar, repita com --apply (cria o grupo ${GROUP}, ACLs em ${STATE}, as units e o drop-in, e reinicia ${UNIT})."
  say "o --apply exige root (sudo) e é do maestro:  ! bash ops/chat-runner.sh install --apply$([ "${EGRESS}" = 1 ] && echo ' --egress-fence')"
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
for f in "${UNIT_DIR}/${SOCKET_UNIT}" "${UNIT_DIR}/${TEMPLATE_UNIT}" "${LIBEXEC}/launcher.py" "${DROPIN_DIR}/${DROPIN_NAME}" "${FENCE_DIR}/${FENCE_NAME}"; do
  if priv test -f "${f}"; then priv install -m 0600 "${f}" "${BK}/$(basename "${f}")" || die 2 "backup de ${f} falhou"; fi
done
say "backup em ${BK} (ACLs do estado + o que havia instalado)"
created_group=0; created_home=0; installed_dropin=0; installed_fence=0

rollback() {
  echo "[${NAME}] ─── ROLLBACK MANUAL (do maestro, fora da sessão: \`!\` no prompt) ───" >&2
  if [ "${installed_dropin}" = 1 ]; then
    cat >&2 <<EOF
  sudo rm -f ${DROPIN_DIR}/${DROPIN_NAME}
  sudo systemctl daemon-reload && sudo systemctl reset-failed ${UNIT} && sudo systemctl restart ${UNIT}
  curl -fsS ${HEALTH_LOCAL}
EOF
  fi
  if [ "${installed_fence}" = 1 ] || [ "${FENCE}" = 1 ]; then
    if [ -f "${BK}/${FENCE_NAME}" ]; then echo "  sudo install -m 0644 ${BK}/${FENCE_NAME} ${FENCE_DIR}/${FENCE_NAME}   # volta a cerca anterior" >&2
    else echo "  sudo rm -f ${FENCE_DIR}/${FENCE_NAME} && sudo rmdir --ignore-fail-on-non-empty ${FENCE_DIR}   # tira a cerca de rede" >&2; fi
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
  echo "  # RESÍDUO declarado: arquivos criados pelos UIDs do runner seguem com a ACL do grupo (a dona não muda ACL alheia)" >&2
  echo "  # e a máscara padrão das raízes fica; sem o grupo, as entradas viram GID órfão — inofensivo, mas não some" >&2
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
  # o .git de cada workspace fica FORA (refutador, passada 2, achado 3): o bridge roda git nele como a conta do serviço
  as_svc find "${d}" -mindepth 1 -xdev -name .git -prune -o -user "${SVC_USER}" \( -type f -o -type d \) -exec setfacl -m "g:${GROUP}:rwX,u:${SVC_USER}:rwX" -- {} + \
    || fail_after "ACL do grupo no que já existe em ${d} falhou"
  as_svc find "${d}" -mindepth 1 -xdev -name .git -prune -o -user "${SVC_USER}" -type d -exec setfacl -m "d:g:${GROUP}:rwx,d:u:${SVC_USER}:rwx,d:m::rwx" -- {} + \
    || fail_after "ACL padrão no que já existe em ${d} falhou"
done
while IFS= read -r -d '' g; do
  as_svc setfacl -R -P -b -- "${g}" || fail_after "não tirei as ACLs de ${g}"
done < <(as_svc find "${WS_ROOT}" -mindepth 2 -maxdepth 2 -name .git -type d -print0)
say "ACLs aplicadas: ${STATE} (travessia), ${WS_ROOT} e ${HOME_ROOT} (travessia + padrão), e cada workspace/HOME existente"
for d in "${WS_ROOT}/${PROBE_SLUG}" "${HOME_ROOT}/${PROBE_SLUG}"; do
  as_svc mkdir -p -- "${d}" || fail_after "não criei o workspace de sonda ${d}"
done
own=(-o root -g root); [ "${TEST}" = 1 ] && own=()
priv install "${own[@]}" -d -m 0755 "${LIBEXEC}" || fail_after "não criei ${LIBEXEC}"
priv install "${own[@]}" -m 0644 "${TMPD}/launcher.py" "${LIBEXEC}/launcher.py" || fail_after "não instalei o lançador"
priv install "${own[@]}" -m 0644 "${TMPD}/${SOCKET_UNIT}" "${UNIT_DIR}/${SOCKET_UNIT}" || fail_after "não instalei ${SOCKET_UNIT}"
priv install "${own[@]}" -m 0644 "${TMPD}/${TEMPLATE_UNIT}" "${UNIT_DIR}/${TEMPLATE_UNIT}" || fail_after "não instalei ${TEMPLATE_UNIT}"
# a cerca ANTES do aperto de mão: a instância que responde abaixo já nasce dentro dela
if [ "${FENCE}" = 1 ]; then
  priv install "${own[@]}" -d -m 0755 "${FENCE_DIR}" || fail_after "não criei ${FENCE_DIR}"
  priv install "${own[@]}" -m 0644 "${TMPD}/${FENCE_NAME}" "${FENCE_DIR}/${FENCE_NAME}" || fail_after "não instalei a cerca ${FENCE_NAME}"
  installed_fence=1; say "cerca de rede instalada: ${FENCE_DIR}/${FENCE_NAME}"
fi
priv systemctl daemon-reload || fail_after "daemon-reload falhou"
priv systemctl enable "${SOCKET_UNIT}" >/dev/null 2>&1 || fail_after "enable ${SOCKET_UNIT} falhou"
priv systemctl restart "${SOCKET_UNIT}" || fail_after "restart ${SOCKET_UNIT} falhou"
say "lançador e units instalados; ${SOCKET_UNIT} ativo"
# o runner tem de responder ANTES de o bridge passar a usá-lo
HS_SINCE="$(date +%s)"
handshake | sed 's/^/    /'; [ "${PIPESTATUS[0]}" = 0 ] || fail_after "o aperto de mão pelo socket reprovou: o bridge NÃO foi ligado ao runner"
effective_props || fail_after "as propriedades efetivas das units do runner divergem: o bridge NÃO foi ligado ao runner"
runner_identity "${HS_SINCE}" || fail_after "o journal não prova a identidade da instância: o bridge NÃO foi ligado ao runner"

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
say "OK — runner instalado e ligado (bridge ${BRIDGE_HEAD}, invocação ${INV:0:8}); o /chat de CONVIDADO roda sob UID próprio$([ "${FENCE}" = 1 ] && echo ', dentro da cerca de rede')"
rollback 2>&1 | sed 's/^/  (se precisar) /'
exit 0
