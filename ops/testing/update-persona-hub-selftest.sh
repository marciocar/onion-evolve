#!/usr/bin/env bash
# update-persona-hub-selftest.sh — a bancada do ops/update-persona-hub.sh (core-only). O wrapper roda no MODO DE TESTE
# contra uma raiz falsa em /tmp: repositórios git DE VERDADE (uma origem nua, o bridge servido, o clone de código do
# worker, o repo do hub com a worktree do worker feita por `git worktree add`), e systemctl, journalctl, npm,
# systemd-analyze, sleep e o slack-persona.sh FALSOS. Nada passa por sudo, nada toca /etc nem systemd real.
# O systemctl falso "carrega" a unit instalada no daemon-reload e, no start, escreve no journal da invocação nova a linha
# 'brain hub worker listening' com o BRAIN_HUB_DIR carregado e cria o socket 0660 — então a prova do wrapper mede o
# que a unit gerada de fato diz.
# Uso: bash ops/testing/update-persona-hub-selftest.sh [<wrapper>]   (rc 0 = verde; o argumento serve aos mutantes)
set -uo pipefail
me="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/update-persona-hub.sh}"
t="$(mktemp -d /tmp/update-persona-hub-selftest.XXXXXX)"; trap 'rm -rf "${t}"' EXIT
fails=0; ok=0; OUT="${t}/out"
chk() { if [ "$2" = 0 ]; then ok=$((ok + 1)); echo "  ✓ $1"; else fails=$((fails + 1)); echo "  ✗ $1"; sed 's/^/      /' "${OUT}" 2>/dev/null | tail -6; fi; }
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t GIT_CONFIG_GLOBAL=/dev/null
WORKER_PROD=/home/marcio/worktrees/brain-granaai/hub-worker
MID=UMAESTRO1

# ── os falsos ────────────────────────────────────────────────────────────────────────────────────────────────────
mkdir -p "${t}/bin"
cat > "${t}/bin/systemctl" <<'F'
#!/usr/bin/env bash
SD="${ONION_UPH_ROOT}/sd"; echo "systemctl $*" >> "${ONION_UPH_ROOT}/calls"
newstart() {
  local u="$1"
  [ -e "${SD}/fail-start-${u}" ] && exit 1
  touch "${SD}/${u}.active"; local inv
  # no-bump-<unit>: o start não traz invocação nova (a prova tem de recusar o boot antigo)
  if [ -e "${SD}/no-bump-${u}" ]; then inv="$(cat "${SD}/${u}.inv")"; else inv="inv-$(od -An -N4 -tx4 /dev/urandom | tr -d ' ')"; fi
  echo "${inv}" > "${SD}/${u}.inv"
  date -u -d "@$(( $(date +%s) + 100 ))" '+%a %Y-%m-%d %H:%M:%S UTC' > "${SD}/${u}.start"
  cat "${SD}/nr-after-${u}" 2>/dev/null > "${SD}/${u}.nr" || echo 0 > "${SD}/${u}.nr"
  [ -s "${SD}/${u}.nr" ] || echo 0 > "${SD}/${u}.nr"
  if [ "${u}" = onion-brain-hub ] && [ ! -e "${SD}/no-listen" ]; then
    local hub; hub="$(cat "${SD}/force-hub" 2>/dev/null || sed -n 's/^BRAIN_HUB_DIR=//p' "${SD}/${u}.env")"
    mkdir -p "${SD}/journal"; printf '{"msg":"brain hub worker listening","socket":"/run/onion-brain-hub/hub.sock","hub":"%s"}\n' "${hub}" > "${SD}/journal/${inv}"
    local s="${ONION_UPH_ROOT}/run/onion-brain-hub/hub.sock"; mkdir -p "${s%/*}"
    python3 -I -c 'import os,socket,sys; p=sys.argv[1]; os.path.exists(p) and os.unlink(p); socket.socket(socket.AF_UNIX).bind(p)' "${s}"
    chmod "$(cat "${SD}/sock-mode" 2>/dev/null || echo 660)" "${s}"
  fi
}
case "$1" in
  show)
    if [ "$2" = -p ] && [ "$4" = --value ]; then u="$5"
      case "$3" in
        ExecMainStartTimestamp) cat "${SD}/${u}.start" 2>/dev/null ;;
        InvocationID) cat "${SD}/${u}.inv" 2>/dev/null ;;
        NRestarts) cat "${SD}/${u}.nr" 2>/dev/null || echo 0 ;;
      esac
    elif [ "$2" = -p ] && [ "$3" = Environment ]; then echo "Environment=$(tr '\n' ' ' < "${SD}/$4.env" 2>/dev/null)"; fi ;;
  is-active) u="${!#}"; [ -e "${SD}/${u}.active" ] ;;
  stop) rm -f "${SD}/$2.active" ;;
  start|restart) newstart "$2" ;;
  reset-failed) : ;;
  daemon-reload) [ -e "${SD}/reload-noload" ] && exit 0; sed -n 's/^Environment=//p' "${ONION_UPH_ROOT}/etc/systemd/system/onion-brain-hub.service" > "${SD}/onion-brain-hub.env" ;;
esac
F
cat > "${t}/bin/journalctl" <<'F'
#!/usr/bin/env bash
for a in "$@"; do case "${a}" in _SYSTEMD_INVOCATION_ID=*) cat "${ONION_UPH_ROOT}/sd/journal/${a#*=}" 2>/dev/null ;; esac; done; exit 0
F
printf '#!/usr/bin/env bash\necho "npm $*" >> "${ONION_UPH_ROOT}/calls"\n[ ! -e "${ONION_UPH_ROOT}/sd/npm-fail" ]\n' > "${t}/bin/npm"
printf '#!/usr/bin/env bash\necho "systemd-analyze $*" >> "${ONION_UPH_ROOT}/calls"\n[ ! -e "${ONION_UPH_ROOT}/sd/analyze-fail" ]\n' > "${t}/bin/systemd-analyze"
printf '#!/usr/bin/env bash\nexit 0\n' > "${t}/bin/sleep"
cat > "${t}/persona.sh" <<'F'
#!/usr/bin/env bash
SD="${ONION_UPH_ROOT}/sd"; echo "persona $*" >> "${ONION_UPH_ROOT}/calls"
case "$1" in
  start) [ -e "${SD}/persona-start-fail" ] && exit 1; [ -e "${SD}/persona-no-bump" ] || systemctl restart onion-slack-persona >/dev/null ;;
  verify) [ ! -e "${SD}/persona-verify-fail" ] ;;
esac
F
chmod +x "${t}/bin/"* "${t}/persona.sh"
export PATH="${t}/bin:${PATH}"

# ── a origem: c1 → c2 (código) → c3 (lock); e dois ramos ruins a partir de c3 (unit com ExecStartPre, unit sem BRAIN_HUB_DIR) ──
hub_unit() { # <dir do hub na unit> <extra>
  cat <<EOF
[Unit]
Description=Onion brain hub
[Service]
Type=simple
User=marcio
Environment=HOME=/home/marcio
Environment=BRAIN_HUB_DIR=$1
Environment=BRAIN_HUB_SOCKET=/run/onion-brain-hub/hub.sock
#Environment=BRAIN_HUB_MAESTRO_USER_ID=U0000000000
WorkingDirectory=/home/marcio/onion-brain-hub-app
ExecStart=/usr/bin/node /home/marcio/onion-brain-hub-app/node_modules/tsx/dist/cli.mjs src/brain-hub/main.ts
$2
[Install]
WantedBy=multi-user.target
EOF
}
S="${t}/seed"; git init -q -b main "${S}"
mkdir -p "${S}/deploy/brain-hub" "${S}/deploy/slack-persona" "${S}/src"
hub_unit /home/marcio/brain-granaai "" > "${S}/deploy/brain-hub/onion-brain-hub.service"
echo "[Service]" > "${S}/deploy/slack-persona/onion-slack-persona.service"
echo v1 > "${S}/package-lock.json"; echo a > "${S}/src/x.ts"
git -C "${S}" add -A; git -C "${S}" commit -qm c1; C1="$(git -C "${S}" rev-parse HEAD)"
echo b > "${S}/src/x.ts"; git -C "${S}" commit -qam c2; C2="$(git -C "${S}" rev-parse HEAD)"
echo v2 > "${S}/package-lock.json"; git -C "${S}" commit -qam c3; C3="$(git -C "${S}" rev-parse HEAD)"
git -C "${S}" checkout -qb evil-pre
hub_unit /home/marcio/brain-granaai "ExecStartPre=/bin/true" > "${S}/deploy/brain-hub/onion-brain-hub.service"
git -C "${S}" commit -qam evil-pre; C_PRE="$(git -C "${S}" rev-parse HEAD)"
git -C "${S}" checkout -q main; git -C "${S}" checkout -qb evil-nodir
hub_unit /home/marcio/brain-granaai "" | grep -v BRAIN_HUB_DIR > "${S}/deploy/brain-hub/onion-brain-hub.service"
git -C "${S}" commit -qam evil-nodir; C_NODIR="$(git -C "${S}" rev-parse HEAD)"
# variantes da unit a partir de c3, cada uma num ramo: <nome> <sed>
variant() { git -C "${S}" checkout -q main; git -C "${S}" checkout -qb "evil-$1"
  hub_unit /home/marcio/brain-granaai "" | sed -E "$2" > "${S}/deploy/brain-hub/onion-brain-hub.service"
  git -C "${S}" commit -qam "evil-$1"; git -C "${S}" rev-parse HEAD; }
C_USER="$(variant user 's/^User=marcio$/User=root/')"
C_WD="$(variant wd 's|^WorkingDirectory=.*|WorkingDirectory=/tmp|')"
C_EXEC="$(variant exec 's|^ExecStart=.*|ExecStart=/bin/sh -c id|')"
C_SPACE="$(variant space 's|^(ExecStart=.*)$|\1\n ExecStartPre=+/bin/true|')"
C_DUP="$(variant dup 's|^(Environment=HOME=.*)$|\1\nEnvironment="NODE_ENV=production" "BRAIN_HUB_DIR=/home/marcio/brain-granaai"|')"
C_ENV="$(variant env 's|^(Environment=HOME=.*)$|\1\nEnvironment=LD_PRELOAD=/tmp/evil.so|')"
C_TWICE="$(variant twice 's|^(Environment=HOME=.*)$|\1\nEnvironment=BRAIN_HUB_DIR=/home/marcio/brain-granaai|')"
git -C "${S}" checkout -q main
git clone -q --bare "${S}" "${t}/origin.git"

# ── a raiz de um caso: servido em <sha>, clone do worker em c1, repo do hub com a worktree, units instaladas ──
N=0; R=""
fresh() { # <sha servido> [noworker]
  N=$((N + 1)); R="${t}/r${N}"; mkdir -p "${R}/sd" "${R}/etc/systemd/system" "${R}/home/onion" "${R}/home/marcio/worktrees/brain-granaai"
  git clone -q "${t}/origin.git" "${R}/home/onion/onion-bridge"; git -C "${R}/home/onion/onion-bridge" reset -q --hard "$1"
  git clone -q "${t}/origin.git" "${R}/home/marcio/onion-brain-hub-app"; git -C "${R}/home/marcio/onion-brain-hub-app" reset -q --hard "${C1}"
  local H="${R}/home/marcio/brain-granaai"; git init -q -b main "${H}"; echo hub > "${H}/CLAUDE.md"; mkdir -p "${H}/docs"; echo a > "${H}/docs/a.md"; git -C "${H}" add -A; git -C "${H}" commit -qm h1
  echo '{}' > "${H}/.mcp.json"
  if [ "${2:-}" != noworker ]; then git -C "${H}" worktree add -q -b hub-worker "${R}${WORKER_PROD}" main; cp "${H}/.mcp.json" "${R}${WORKER_PROD}/"; fi
  hub_unit /home/marcio/brain-granaai "" | sed "s|^#Environment=BRAIN_HUB_MAESTRO_USER_ID=.*|Environment=BRAIN_HUB_MAESTRO_USER_ID=${MID}|" > "${R}/etc/systemd/system/onion-brain-hub.service"
  cp "${R}/home/onion/onion-bridge/deploy/slack-persona/onion-slack-persona.service" "${R}/etc/systemd/system/"
  ONION_UPH_ROOT="${R}" systemctl daemon-reload
  local u old; old="$(date -u -d "@$(( $(date +%s) - 1000 ))" '+%a %Y-%m-%d %H:%M:%S UTC')"
  for u in onion-brain-hub onion-slack-persona; do touch "${R}/sd/${u}.active"; echo "${u}-0" > "${R}/sd/${u}.inv"; echo 0 > "${R}/sd/${u}.nr"; echo "${old}" > "${R}/sd/${u}.start"; done
  mkdir -p "${R}/sd/journal"; printf '{"msg":"brain hub worker listening","hub":"/home/marcio/brain-granaai"}\n' > "${R}/sd/journal/onion-brain-hub-0"
  : > "${R}/calls"
}
run() { ONION_UPH_TEST=1 ONION_UPH_ROOT="${R}" ONION_UPH_PERSONA_SH="${t}/persona.sh" bash "${me}" "$@" > "${OUT}" 2>&1; }
called() { grep -q -- "$1" "${R}/calls"; }
apphead() { git -C "${R}/home/marcio/onion-brain-hub-app" rev-parse HEAD; }
untouched() { ! called 'systemctl stop' && ! called 'systemctl start' && ! called 'systemctl restart' && ! called daemon-reload && [ "$(apphead)" = "${C1}" ] && grep -q '^Environment=BRAIN_HUB_DIR=/home/marcio/brain-granaai$' "${R}/etc/systemd/system/onion-brain-hub.service"; }

s_usage() {
echo "── uso e modo de teste"
fresh "${C3}"
run; [ $? = 3 ]; chk "sem alvo → rc 3" $?
run hub --force; [ $? = 3 ]; chk "flag desconhecida → rc 3" $?
ONION_UPH_ROOT="${R}" bash "${me}" hub > "${OUT}" 2>&1; [ $? = 3 ]; chk "ONION_UPH_* sem o modo de teste → rc 3" $?

}
s_worker() {
echo "── hub: worktree do worker"
fresh "${C3}" noworker; : > "${R}/calls"
run hub; rc=$?; [ "${rc}" = 1 ] && grep -q 'ATO DE MIGRAÇÃO' "${OUT}" && grep -q "worktree add -b hub-worker ${WORKER_PROD}" "${OUT}" && untouched
chk "ensaio sem a worktree do worker → rc 1, imprime o ato de migração, nada mudou" $?
fresh "${C3}" noworker
run hub --apply; [ $? = 1 ] && untouched; chk "apply sem a worktree do worker → rc 1, o hub não sobe no checkout da sessão" $?
fresh "${C3}" noworker; git clone -q "${R}/home/marcio/brain-granaai" "${R}${WORKER_PROD}"; cp "${R}/home/marcio/brain-granaai/.mcp.json" "${R}${WORKER_PROD}/"
run hub --apply; [ $? = 1 ] && grep -q 'não é o arquivo de uma worktree' "${OUT}" && untouched; chk "worker como clone separado (.git diretório) → recusa" $?
fresh "${C3}" noworker; ln -s "${R}/home/marcio/brain-granaai" "${R}${WORKER_PROD}"
run hub --apply; [ $? = 1 ] && grep -q 'mesmo escritor' "${OUT}" && untouched; chk "worker que aponta para o checkout da sessão → recusa" $?
fresh "${C3}"; rm "${R}${WORKER_PROD}/.mcp.json"
run hub --apply; [ $? = 1 ] && grep -q 'falta .mcp.json na worktree' "${OUT}" && untouched; chk "worktree sem o .mcp.json que a sessão tem → recusa nomeando o arquivo" $?
fresh "${C3}"; echo /tmp/outro/.git > "${R}/home/marcio/brain-granaai/.git/worktrees/hub-worker/gitdir"
run hub --apply; [ $? = 1 ] && grep -q 'não aponta de volta' "${OUT}" && untouched; chk "registro da worktree sem o ponteiro de volta → recusa" $?
fresh "${C3}"; rm "${R}${WORKER_PROD}/docs/a.md"
run hub --apply; [ $? = 1 ] && grep -q 'arquivo rastreado faltando' "${OUT}" && untouched; chk "worktree com arquivo rastreado faltando → recusa" $?
fresh "${C3}"; w="${R}${WORKER_PROD}"; mv "${w}" "${w}.real"; mkdir -p "${w}"; cp "${w}.real/.git" "${w}/.git"; cp "${w}.real/.mcp.json" "${w}/"; echo x > "${w}/CLAUDE.md"
run hub --apply; [ $? = 1 ] && grep -q 'arquivo rastreado faltando: docs/a.md' "${OUT}" && untouched; chk "pasta quase vazia com o .git copiado da worktree → recusa" $?

}
s_apply() {
echo "── hub: ensaio e apply"
fresh "${C3}"
run hub; rc=$?; [ "${rc}" = 0 ] && grep -q '\[ensaio\]' "${OUT}" && grep -q "^      > Environment=BRAIN_HUB_DIR=${WORKER_PROD}" "${OUT}" && untouched
chk "ensaio com a worktree pronta → rc 0, diff da unit com o BRAIN_HUB_DIR novo, nada mudou" $?
fresh "${C3}"; echo "Environment=BRAIN_HUB_MAESTRO_USER_ID=${MID}" >> "${R}/etc/systemd/system/onion-brain-hub.service"
run hub; grep -q 'UM…(9 caracteres)' "${OUT}" && ! grep -q "${MID}" "${OUT}"; chk "o id do maestro que cai no diff da unit sai mascarado" $?
fresh "${C3}"
run hub --apply; rc=$?
[ "${rc}" = 0 ] && grep -q '✓ RESULTADO' "${OUT}"; chk "apply → rc 0 e RESULTADO ✓" $?
[ "$(apphead)" = "${C3}" ]; chk "o clone do worker foi ao sha SERVIDO" $?
grep -qx "Environment=BRAIN_HUB_DIR=${WORKER_PROD}" "${R}/etc/systemd/system/onion-brain-hub.service" && grep -qx "Environment=BRAIN_HUB_MAESTRO_USER_ID=${MID}" "${R}/etc/systemd/system/onion-brain-hub.service" && ! grep -q brain-granaai$ "${R}/etc/systemd/system/onion-brain-hub.service"
chk "a unit instalada aponta a worktree do worker e preserva o id do maestro" $?
b="$(ls "${R}/home/marcio/.local/state/onion-update-persona-hub/"onion-brain-hub.service.* 2>/dev/null | head -1)"
[ -n "${b}" ] && grep -qx 'Environment=BRAIN_HUB_DIR=/home/marcio/brain-granaai' "${b}"; chk "backup da unit anterior no estado, com o BRAIN_HUB_DIR antigo" $?
called 'npm ci --ignore-scripts'; chk "lock mudou (c1 → c3) → npm ci" $?
[ "$(grep -n 'systemctl stop onion-brain-hub' "${R}/calls" | cut -d: -f1)" -lt "$(grep -n 'systemctl start onion-brain-hub' "${R}/calls" | cut -d: -f1)" ] && called 'systemd-analyze verify'
chk "ordem: stop antes do start, e a unit passou pelo systemd-analyze" $?
grep -q 'desfazer: git -C /home/marcio/onion-brain-hub-app reset --hard' "${OUT}"; chk "o desfazer sai impresso com o sha anterior" $?
: > "${R}/calls"; run hub --apply; [ $? = 0 ] && grep -q 'hub: NOOP' "${OUT}" && ! called 'systemctl stop'; chk "rodar de novo → NOOP com o vivo provado, sem religar" $?
rm -f "${R}/run/onion-brain-hub/hub.sock"; run hub --apply; [ $? = 1 ] && grep -q 'NÃO está provado' "${OUT}"; chk "NOOP com o socket sumido → rc 1 (em dia não é provado)" $?
grep -q 'hub --restart' "${OUT}"; chk "o NOOP não provado aponta o --restart" $?
: > "${R}/calls"; run hub --restart; [ $? = 0 ] && called 'systemctl stop onion-brain-hub' && [ -S "${R}/run/onion-brain-hub/hub.sock" ]; chk "--restart em dia religa e prova o boot novo" $?
git -C "${R}/home/marcio/onion-brain-hub-app" reset -q --hard "${C1}"; : > "${R}/calls"
run hub --apply; [ $? = 0 ] && ! grep -q 'hub: NOOP' "${OUT}" && [ "$(apphead)" = "${C3}" ]; chk "código atrás do servido com processo mais novo → NÃO é NOOP, atualiza" $?
fresh "${C2}"; run hub --apply; [ $? = 0 ] && ! called 'npm '; chk "lock igual (c1 → c2) → sem npm ci" $?

}
s_repo() {
echo "── hub: o clone do worker e a unit do repo"
fresh "${C3}"; echo sujo >> "${R}/home/marcio/onion-brain-hub-app/src/x.ts"
run hub --apply; [ $? = 1 ] && grep -q 'mudança rastreada' "${OUT}" && ! called 'systemctl stop'; chk "clone do worker sujo → recusa" $?
fresh "${C3}"; echo z > "${R}/home/marcio/onion-brain-hub-app/src/z.ts"; git -C "${R}/home/marcio/onion-brain-hub-app" add -A; git -C "${R}/home/marcio/onion-brain-hub-app" commit -qm local
run hub --apply; [ $? = 1 ] && grep -q 'divergiu' "${OUT}" && ! called 'systemctl stop'; chk "clone do worker divergido do servido → recusa" $?
fresh "${C_PRE}"; run hub --apply; [ $? = 1 ] && grep -q 'recusada' "${OUT}" && ! called 'systemctl stop'; chk "unit do repo com ExecStartPre → recusa antes de parar" $?
fresh "${C_NODIR}"; run hub --apply; [ $? = 1 ] && grep -q 'BRAIN_HUB_DIR= (esperado 1' "${OUT}" && ! called 'systemctl stop'; chk "unit do repo sem BRAIN_HUB_DIR (cairia no checkout da sessão) → recusa" $?
fresh "${C3}"; touch "${R}/sd/analyze-fail"
run hub --apply; [ $? = 1 ] && grep -q 'systemd-analyze verify reprova' "${OUT}" && untouched
chk "systemd-analyze reprova → recusa ANTES de parar: código e unit intocados" $?
for v in USER WD EXEC SPACE DUP ENV; do
  eval "sha=\${C_${v}}"; fresh "${sha}"
  run hub --apply; [ $? = 1 ] && grep -q 'recusada' "${OUT}" && untouched; chk "unit do repo com desvio ${v} → recusa pela allowlist, nada parado" $?
done
fresh "${C_TWICE}"; run hub --apply; [ $? = 1 ] && grep -q 'linha(s) Environment=BRAIN_HUB_DIR= (esperado 1' "${OUT}" && untouched; chk "BRAIN_HUB_DIR duas vezes (a última venceria) → recusa" $?
fresh "${C3}"; git -C "${R}/home/marcio/onion-brain-hub-app" checkout -qb outra
run hub --apply; [ $? = 1 ] && grep -q 'não está na main' "${OUT}"; chk "clone do worker fora da main → recusa" $?
fresh "${C3}"; echo y > "${R}/home/onion/onion-bridge/src/y.ts"; git -C "${R}/home/onion/onion-bridge" add -A; git -C "${R}/home/onion/onion-bridge" commit -qm so-servido
run hub --apply; [ $? = 1 ] && grep -q 'não está na origin' "${OUT}" && untouched; chk "sha servido que a origin não tem → recusa" $?
fresh "${C3}"; sed -i "s/^Environment=BRAIN_HUB_MAESTRO_USER_ID=.*/Environment=BRAIN_HUB_MAESTRO_USER_ID=bad-id/" "${R}/etc/systemd/system/onion-brain-hub.service"
run hub --apply; [ $? = 1 ] && grep -q 'fora do formato' "${OUT}" && ! called 'systemctl stop'; chk "id do maestro fora do formato na instalada → recusa" $?
fresh "${C3}"; rm "${R}/sd/onion-brain-hub.active"
run hub --apply; [ $? = 1 ] && grep -q 'não está ativo' "${OUT}" && ! called 'systemctl stop' && ! called 'systemctl start'; chk "worker inativo → triagem primeiro, nada tocado" $?

}
s_proof() {
echo "── hub: a prova depois do start"
fresh "${C3}"; touch "${R}/sd/no-listen"
run hub --apply; [ $? = 1 ] && grep -q "NÃO provado: sem a linha 'brain hub worker listening'" "${OUT}" && grep -q 'desfazer:' "${OUT}"; chk "sem a linha 'listening' desta invocação → rc 1 com o desfazer" $?
fresh "${C3}"; echo /home/marcio/brain-granaai > "${R}/sd/force-hub"
run hub --apply; [ $? = 1 ] && grep -q "não declara hub=${WORKER_PROD}" "${OUT}"; chk "worker que declara o checkout da sessão → rc 1" $?
fresh "${C3}"; echo 2 > "${R}/sd/nr-after-onion-brain-hub"
run hub --apply; [ $? = 1 ] && grep -q 'NRestarts=2' "${OUT}"; chk "NRestarts > 0 depois do start → rc 1" $?
fresh "${C3}"; echo 666 > "${R}/sd/sock-mode"
run hub --apply; [ $? = 1 ] && grep -q 'não é 0660' "${OUT}"; chk "socket aberto a outros (0666) → rc 1" $?
fresh "${C3}"; touch "${R}/sd/fail-start-onion-brain-hub"
run hub --apply; [ $? = 1 ] && grep -q 'systemctl start recusou' "${OUT}"; chk "start recusado → rc 1" $?
fresh "${C3}"; touch "${R}/sd/no-bump-onion-brain-hub"
run hub --apply; [ $? = 1 ] && grep -q 'invocação NOVA do worker' "${OUT}"; chk "start sem invocação nova (o boot antigo) → rc 1" $?
fresh "${C3}"; touch "${R}/sd/npm-fail"
run hub --apply; [ $? = 1 ] && grep -q 'DEIXADO PARADO' "${OUT}" && ! systemctl_active onion-brain-hub && ! grep -q 'systemctl start onion-brain-hub' "${R}/calls"
chk "npm ci falha → worker DEIXADO PARADO (nada de religar sobre node_modules pela metade)" $?
grep -q 'desfazer: git -C /home/marcio/onion-brain-hub-app reset --hard [0-9a-f]* && (cd /home/marcio/onion-brain-hub-app && npm ci' "${OUT}"; chk "o desfazer refaz o node_modules NA pasta do clone (cd …), não na pasta de quem cola" $?
fresh "${C3}"; touch "${R}/sd/reload-noload"
run hub --apply; [ $? = 1 ] && grep -q 'a unit carregada não traz BRAIN_HUB_DIR' "${OUT}" && grep -q 'systemctl start onion-brain-hub' "${R}/calls"
chk "unit carregada sem o BRAIN_HUB_DIR novo → rc 1, e o religamento (re-armado depois do npm ci) religa" $?

}
systemctl_active() { [ -e "${R}/sd/$1.active" ]; }
s_lock() {
echo "── trava"
fresh "${C3}"; mkdir -p "${R}/tmp"
( exec 8>"${R}/tmp/onion-update-persona-hub.lock"; flock -n 8; run hub --apply; echo $? > "${t}/lockrc" )
[ "$(cat "${t}/lockrc")" = 2 ] && untouched; chk "outra execução segura a trava → rc 2, nada feito" $?
fresh "${C3}"; mkdir -p "${R}/tmp"
( exec 8>"${R}/tmp/onion-update-bridge.lock"; flock -n 8; run hub --apply; echo $? > "${t}/lockrc" )
[ "$(cat "${t}/lockrc")" = 2 ] && grep -q 'update-bridge' "${OUT}" && untouched; chk "o update-bridge segurando a trava dele → rc 2, nada feito" $?

}
s_persona() {
echo "── persona"
fresh "${C3}"; run persona; [ $? = 0 ] && grep -q 'persona desatualizada' "${OUT}" && ! called 'persona '; chk "ensaio com a persona anterior ao servido → plano, sem chamar o slack-persona.sh" $?
fresh "${C3}"; run persona --apply; [ $? = 0 ] && called 'persona start' && grep -q 'persona: OK' "${OUT}"; chk "apply → slack-persona.sh start e invocação nova" $?
: > "${R}/calls"; run persona --apply; [ $? = 0 ] && called 'persona verify' && ! called 'persona start'; chk "rodar de novo → NOOP pelo verify, sem religar" $?
git -C "${R}/home/onion/onion-bridge" reflog expire --expire=now --all; : > "${R}/calls"
run persona --apply; [ $? = 0 ] && ! called 'persona start'; chk "reflog expirado não faz religar a cada rodada (cai no mtime dos refs)" $?
: > "${R}/calls"; run persona --restart; [ $? = 0 ] && called 'persona start'; chk "--restart religa a persona mesmo em dia" $?
fresh "${C3}"; echo 1 > "${R}/sd/nr-after-onion-slack-persona"; run persona --apply; [ $? = 1 ] && grep -q 'NRestarts=1' "${OUT}"; chk "persona reinicia sozinha depois do start → rc 1" $?
touch "${R}/sd/persona-verify-fail"; run persona --apply; [ $? = 1 ]; chk "NOOP com o verify reprovando → rc 1" $?
fresh "${C3}"; echo '# mexida' >> "${R}/etc/systemd/system/onion-slack-persona.service"
run persona --apply; [ $? = 1 ] && grep -q 'difere da servida' "${OUT}" && ! called 'persona '; chk "unit da persona difere da servida → recusa (é o install do slack-persona.sh)" $?
fresh "${C3}"; rm "${R}/sd/onion-slack-persona.active"
run persona --apply; [ $? = 1 ] && ! called 'persona '; chk "persona inativa → recusa (ligar é o start do slack-persona.sh)" $?
fresh "${C3}"; touch "${R}/sd/persona-start-fail"; run persona --apply; [ $? = 1 ]; chk "slack-persona.sh start falha → rc 1" $?
fresh "${C3}"; touch "${R}/sd/persona-no-bump"; run persona --apply; [ $? = 1 ] && grep -q 'invocação NOVA' "${OUT}"; chk "start sem invocação nova → rc 1" $?
fresh "${C3}"; echo x >> "${R}/home/onion/onion-bridge/src/x.ts"; run persona; [ $? = 1 ] && grep -q 'bridge servido tem mudança' "${OUT}"; chk "bridge servido sujo → recusa" $?
fresh "${C3}"; touch -d "@$(( $(date +%s) + 5000 ))" "${R}/home/onion/onion-bridge/node_modules/.package-lock.json" 2>/dev/null \
  || { mkdir -p "${R}/home/onion/onion-bridge/node_modules"; touch -d "@$(( $(date +%s) + 5000 ))" "${R}/home/onion/onion-bridge/node_modules/.package-lock.json"; }
echo "$(date -u -d "@$(( $(date +%s) + 100 ))" '+%a %Y-%m-%d %H:%M:%S UTC')" > "${R}/sd/onion-slack-persona.start"
run persona; [ $? = 0 ] && grep -q 'persona desatualizada' "${OUT}"; chk "node_modules refeito depois do início → desatualizada" $?

}
s_all() {
echo "── all"
fresh "${C3}"; run all --apply; [ $? = 0 ] && grep -q 'hub: OK' "${OUT}" && grep -q 'persona: OK' "${OUT}"; chk "all --apply → hub e persona" $?
fresh "${C3}" noworker; run all --apply; [ $? = 1 ] && ! called 'persona '; chk "all com o hub recusado → a persona não é tocada" $?

}
# seções: UPH_SECTIONS="worker proof" roda só essas (os mutantes do auto-teste rodam só a seção do caso que derrubam)
for s in ${UPH_SECTIONS:-usage worker apply repo proof lock persona all}; do "s_${s}"; done
echo "selftest: ${ok} ok · ${fails} falha(s)"
[ "${fails}" = 0 ]
